#!/usr/bin/env bash
# Build OS — COLD-INSTALL tests for the memory maintenance + safety layer.
#
#   bash tests/build_os_maintenance_tests.sh
#
# Deterministic, offline, temp-dirs-only. Every proof below installs into a
# BLANK git repo created here and never touches this repo, ~/.claude, or any
# real memory. Exits non-zero if any assertion fails.
#
# WHAT IT PROVES, and each one is executed rather than described:
#   1. a fresh install into a blank repo succeeds, and the sanctioned wrapper
#      runs GREEN there
#   2. a second install is idempotent — byte-identical tree
#   3. pre-existing customer content is PRESERVED — CLAUDE.md, standing_gates.md,
#      a memory file, .gitignore and package.json
#   4. oversized synthetic memory rotates with BYTE-EXACT conservation, and the
#      archive + INDEX are correct
#   5. the sanctioned wrapper goes RED when a run mutates the never-rotated
#      standing_gates.md
#   6. a bare `node --test` is UNGUARDED, and no shipped file advertises it
#   7. the uninstall boundary: removing exactly the managed list leaves every
#      customer file byte-identical
#   8/9. THIS repository's live residue.md and its live current_state.md are
#      each rotatable, and neither's standing region is what rotation reclaims
#   10. THE ROTATION SENTINEL: `--keep` below the derived minimum_safe_keep is
#      REFUSED BEFORE MUTATION, protected objects are resolved BY IDENTITY rather
#      than by position, and each of the eight refusal conditions is driven by a
#      fixture that fires it
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if ! command -v node >/dev/null 2>&1; then
  echo "node is required for these tests but was not found on PATH" >&2
  exit 6
fi
if ! command -v git >/dev/null 2>&1; then
  echo "git is required for these tests but was not found on PATH" >&2
  exit 6
fi

# A blank git repo, and nothing else in it.
blank_repo(){
  local d="$WORK/$1"
  mkdir -p "$d"
  git -C "$d" init -q
  echo "$d"
}

# sha256 of every file under $1 except .git, as "relpath  hash" lines, sorted.
tree_hash(){
  ( cd "$1" && find . -path ./.git -prune -o -type f -print0 \
      | LC_ALL=C sort -z \
      | while IFS= read -r -d '' f; do printf '%s %s\n' "${f}" "$(sha256sum < "$f" | cut -d' ' -f1)"; done )
}

echo "== 1. Fresh install into a blank repo; the sanctioned wrapper runs green =="
R1="$(blank_repo repo1)"
INSTALL_LOG="$WORK/install1.log"
( cd "$R1" && "$SRC/init-build-os.sh" ) > "$INSTALL_LOG" 2>&1
if [ $? -eq 0 ]; then ok "init-build-os.sh exits 0 in a blank repo"; else no "init-build-os.sh failed: $(tail -3 "$INSTALL_LOG")"; fi

for f in build-os/maintenance/rotate-memory.sh build-os/maintenance/run-tests.sh \
         build-os/maintenance/rotate-memory.mjs build-os/maintenance/real-memory-tripwire.mjs \
         build-os/maintenance/source-scan.mjs build-os/maintenance/rotate-memory.test.mjs \
         build-os/maintenance/rotate-memory.rootscan.test.mjs \
         build-os/maintenance/rootscan-controls.json build-os/maintenance/PORTING.md \
         build-os/maintenance/templates/standing_gates.md \
         build-os/maintenance/.gravito-managed build-os/memory/standing_gates.md; do
  [ -f "$R1/$f" ] && ok "delivered: $f" || no "missing after install: $f"
done
[ -x "$R1/build-os/maintenance/run-tests.sh" ] && ok "run-tests.sh is executable" || no "run-tests.sh is not executable"
[ -x "$R1/build-os/maintenance/rotate-memory.sh" ] && ok "rotate-memory.sh is executable" || no "rotate-memory.sh is not executable"
grep -qxF '!build-os/memory/archive/' "$R1/.gitignore" && ok ".gitignore un-ignores the archive" || no ".gitignore archive exception missing"
[ ! -f "$R1/package.json" ] && ok "no package.json invented in a non-Node repo" || no "installer created a package.json"

# THE HEADLINE: the layer's own suite, run by its own wrapper, inside the
# installed repo. Nothing about this repo is on the path.
WRAP1="$WORK/wrapper1.log"
( cd "$R1" && ./build-os/maintenance/run-tests.sh ) > "$WRAP1" 2>&1
W1=$?
if [ $W1 -eq 0 ]; then ok "the sanctioned wrapper exits 0 in the installed repo"; else no "wrapper exited $W1 (see $WRAP1): $(grep -m3 -E '^ *not ok' "$WRAP1")"; fi
INSTALLED_PASS="$(grep -m1 '^# pass ' "$WRAP1" | tr -dc '0-9')"
INSTALLED_FAIL="$(grep -m1 '^# fail ' "$WRAP1" | tr -dc '0-9')"
[ "${INSTALLED_FAIL:-1}" = "0" ] && ok "installed suite: ${INSTALLED_PASS:-?} pass / 0 fail" || no "installed suite reports ${INSTALLED_FAIL:-?} failures"
[ "${INSTALLED_PASS:-0}" -ge 100 ] 2>/dev/null && ok "installed suite is not vacuous (>=100 tests)" || no "installed suite ran only ${INSTALLED_PASS:-0} tests"

# ...and a dry-run rotation works on the scaffolded memory, finding real blocks
# STDOUT ONLY. The tool documents that its warnings go to STDERR precisely so
# `--json` stays machine-parseable, and this capture used to merge the two with
# `2>&1` — which parsed only while the tool happened to be silent on stderr.
DRY="$( cd "$R1" && ./build-os/maintenance/rotate-memory.sh --json 2>"$WORK/dry.stderr" )"
if node -e '
const r = JSON.parse(process.argv[1]);
if (r.mode !== "dry-run") { console.error("not a dry run"); process.exit(1); }
if (r.results.length !== 3) { console.error("expected 3 files"); process.exit(1); }
const blind = r.results.filter((x) => x.totalBlocks === 0).map((x) => x.path);
if (blind.length) { console.error("ZERO blocks (silent no-op) in: " + blind.join(", ")); process.exit(1); }
' "$DRY" 2>"$WORK/dry.err"; then
  ok "dry-run parses the scaffolded memory into real blocks (no silent no-op)"
else
  no "dry-run over scaffolded memory: $(cat "$WORK/dry.err")"
fi

# ...and the OTHER installer delivers it too. Both entry points are customer
# paths; wiring only one of them would leave half the customers unprotected.
R1B="$(blank_repo repo1b)"
"$SRC/install-project.sh" "$R1B" > "$WORK/installp.log" 2>&1
IP=$?
[ $IP -eq 0 ] && ok "install-project.sh exits 0 in a blank repo" || no "install-project.sh exited $IP"
[ -x "$R1B/build-os/maintenance/run-tests.sh" ] \
  && ok "install-project.sh delivers the maintenance layer too" \
  || no "install-project.sh did not deliver the maintenance layer"
[ -f "$R1B/build-os/memory/standing_gates.md" ] \
  && ok "install-project.sh seeds the standing-gates file" \
  || no "install-project.sh did not seed standing_gates.md"

echo "== 2. A second install is idempotent (byte-identical tree) =="
tree_hash "$R1" > "$WORK/r1.before"
( cd "$R1" && "$SRC/init-build-os.sh" ) > "$WORK/install2.log" 2>&1
I2=$?
tree_hash "$R1" > "$WORK/r1.after"
[ $I2 -eq 0 ] && ok "second install exits 0" || no "second install exited $I2"
if diff -q "$WORK/r1.before" "$WORK/r1.after" >/dev/null; then
  ok "re-install leaves the tree byte-identical"
else
  no "re-install changed the tree: $(diff "$WORK/r1.before" "$WORK/r1.after" | head -5)"
fi
grep -c '^!build-os/memory/archive/$' "$R1/.gitignore" | grep -qx 1 \
  && ok "the .gitignore exception is added once, not appended twice" \
  || no "the .gitignore exception was duplicated"

echo "== 3. Pre-existing customer content is never clobbered =="
R3="$(blank_repo repo3)"
mkdir -p "$R3/build-os/memory" "$R3/build-os/packets"
printf '# My project\n\nMy own rules. Do not touch.\n' > "$R3/CLAUDE.md"
printf '# MY OWN GATES\n\nHARD STOP — my own gate, written by me.\n' > "$R3/build-os/memory/standing_gates.md"
printf '# Residue\n\n## My own residue block\n\nmine.\n' > "$R3/build-os/memory/residue.md"
printf 'node_modules/\narchive/\n' > "$R3/.gitignore"
printf '{\n  "name": "customer-app",\n  "scripts": {\n    "test": "my-own-runner"\n  }\n}\n' > "$R3/package.json"
# a "conflicting" file: something already sitting exactly where a managed file goes
mkdir -p "$R3/build-os/maintenance"
printf 'CUSTOMER FILE THAT COLLIDES WITH A MANAGED PATH\n' > "$R3/build-os/maintenance/rotate-memory.sh"
for f in CLAUDE.md build-os/memory/standing_gates.md build-os/memory/residue.md .gitignore package.json; do
  sha256sum < "$R3/$f" > "$WORK/pre.$(echo "$f" | tr / _)"
done
( cd "$R3" && "$SRC/init-build-os.sh" ) > "$WORK/install3.log" 2>&1

for f in CLAUDE.md build-os/memory/standing_gates.md build-os/memory/residue.md; do
  if [ "$(sha256sum < "$R3/$f")" = "$(cat "$WORK/pre.$(echo "$f" | tr / _)")" ]; then
    ok "customer file preserved byte-identical: $f"
  else
    no "customer file was MODIFIED: $f"
  fi
done
grep -q 'HARD STOP — my own gate, written by me.' "$R3/build-os/memory/standing_gates.md" \
  && ok "the customer's own gates file survived (template not forced over it)" \
  || no "the customer's gates file was replaced by the template"
grep -qx 'node_modules/' "$R3/.gitignore" && grep -qx 'archive/' "$R3/.gitignore" \
  && ok "customer .gitignore rules kept (append only)" || no "customer .gitignore rules lost"
grep -qxF '!build-os/memory/archive/' "$R3/.gitignore" \
  && ok "...and the archive exception was appended beside them" || no "archive exception not appended"
node -e '
const p = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
if (p.name !== "customer-app") { console.error("name lost"); process.exit(1); }
if (p.scripts.test !== "my-own-runner") { console.error("customer script lost"); process.exit(1); }
if (p.scripts["test:build-os-memory"] !== "./build-os/maintenance/run-tests.sh") {
  console.error("wrapper script not added"); process.exit(1);
}
' "$R3/package.json" 2>"$WORK/pkg.err" \
  && ok "package.json: customer fields kept, test:build-os-memory added" \
  || no "package.json handling: $(cat "$WORK/pkg.err")"
# the colliding MANAGED path is replaced — that is the documented contract, and
# the marker in the delivered file is what says so
grep -q 'GRAVITO:MANAGED' "$R3/build-os/maintenance/rotate-memory.sh" \
  && ok "a file squatting a MANAGED path is replaced, and the replacement is marked" \
  || no "a managed path was not (re)claimed by the installer"

echo "== 4. Oversized synthetic memory rotates with byte-exact conservation =="
R4="$(blank_repo repo4)"
( cd "$R4" && "$SRC/init-build-os.sh" ) > "$WORK/install4.log" 2>&1
# generate the fixture IN THE BLANK REPO — nothing is copied from this repo
node -e '
const fs = require("fs");
const out = ["# Residue\n", "\n> generated fixture preamble.\n", "\n"];
for (let i = 1; i <= 120; i++) {
  out.push(`## BLOCK ${i} — heading ${i}\n`);
  out.push(`body line for block ${i}: ${"x".repeat(1500)}\n\n`);
}
fs.writeFileSync(process.argv[1], out.join(""));
' "$R4/build-os/memory/residue.md"
cp "$R4/build-os/memory/residue.md" "$WORK/residue.orig"
ORIG_BYTES="$(wc -c < "$WORK/residue.orig")"
[ "$ORIG_BYTES" -gt 180000 ] && ok "fixture is oversized (${ORIG_BYTES} B)" || no "fixture is only ${ORIG_BYTES} B"

( cd "$R4" && ./build-os/maintenance/rotate-memory.sh --file residue --keep 10 --apply --json ) \
  > "$WORK/rot4.json" 2>"$WORK/rot4.err"
R=$?
[ $R -eq 0 ] && ok "rotation --apply exits 0" || no "rotation exited $R: $(cat "$WORK/rot4.err")"
[ -f "$R4/build-os/memory/archive/residue.archive.md" ] && ok "archive file created" || no "archive file missing"
[ -f "$R4/build-os/memory/archive/INDEX.md" ] && ok "archive INDEX.md created" || no "INDEX.md missing"

# BYTE-EXACT CONSERVATION, reconstructed INDEPENDENTLY from the bytes on disk:
# (live file minus exactly the banner) ++ (the archived block bytes) === original
node -e '
const fs = require("fs"), path = require("path");
const [orig, root] = process.argv.slice(1);
const L = (p) => fs.readFileSync(p).toString("latin1");
const original = L(orig);
const live = L(path.join(root, "build-os/memory/residue.md"));
const archive = L(path.join(root, "build-os/memory/archive/residue.archive.md"));
const S = "<!-- rotate-memory:archive-pointer:start -->";
const E = "<!-- rotate-memory:archive-pointer:end -->\n\n";
const a = live.indexOf(S);
if (a < 0) throw new Error("the rotated live file carries NO archive-pointer banner");
const b = live.indexOf(E, a) + E.length;
const liveMinusBanner = live.slice(0, a) + live.slice(b);
// the archived body: everything after the batch header block, minus the two
// trailing newlines the writer appends
const hdr = archive.lastIndexOf("## ARCHIVED BATCH ");
const bodyAt = archive.indexOf("\n\n", hdr) + 2;
const archivedBody = archive.slice(bodyAt);
const rebuilt = liveMinusBanner + archivedBody;
if (!rebuilt.startsWith(original)) {
  let i = 0; while (i < original.length && rebuilt[i] === original[i]) i++;
  throw new Error("NOT byte-exact: first divergence at byte " + i);
}
const tail = rebuilt.slice(original.length);
if (!/^\n?$/.test(tail)) throw new Error("unexpected trailing bytes: " + JSON.stringify(tail));
if (live.length >= original.length) throw new Error("the live file did not shrink");
' "$WORK/residue.orig" "$R4" 2>"$WORK/cons.err" \
  && ok "byte-exact conservation: live-minus-banner ++ archive reconstructs the original" \
  || no "conservation: $(cat "$WORK/cons.err")"

node -e '
const r = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8")).results[0];
if (r.totalBlocks !== 120) throw new Error("totalBlocks " + r.totalBlocks + " != 120");
if (r.retainedBlocks !== 10) throw new Error("retainedBlocks " + r.retainedBlocks);
if (r.archivedBlocks !== 110) throw new Error("archivedBlocks " + r.archivedBlocks);
if (r.retainedContentBytes + r.archivedBytes !== r.originalBytes) throw new Error("counts do not balance");
' "$WORK/rot4.json" 2>"$WORK/counts.err" \
  && ok "reported counts balance and match the fixture (120 -> 10 + 110)" \
  || no "reported counts: $(cat "$WORK/counts.err")"

INDEX="$R4/build-os/memory/archive/INDEX.md"
grep -q 'Archived Build OS memory — index' "$INDEX" && ok "INDEX carries its header" || no "INDEX header missing"
IDX_ROWS="$(grep -c '^| `build-os/memory/residue.md:' "$INDEX")"
[ "$IDX_ROWS" = "110" ] && ok "INDEX carries one row per archived block (110)" || no "INDEX has $IDX_ROWS rows, expected 110"
# a row's archive line number really points at that block's heading
node -e '
const fs = require("fs"), path = require("path");
const root = process.argv[1];
const idx = fs.readFileSync(path.join(root, "build-os/memory/archive/INDEX.md"), "utf8");
// keep=10 retains the NEWEST ten (blocks 1..10), so the first ARCHIVED block
// is 11 — asking about block 1 would be asking the index about a block that
// never left the live file
const row = idx.split("\n").find((l) => l.includes("## BLOCK 11 —"));
if (!row) throw new Error("no INDEX row for BLOCK 11");
const at = Number(/residue\.archive\.md:(\d+)/.exec(row)[1]);
const lines = fs.readFileSync(path.join(root, "build-os/memory/archive/residue.archive.md"), "utf8").split("\n");
if (!lines[at - 1].startsWith("## BLOCK 11 —")) {
  throw new Error("INDEX points at line " + at + ", which is " + JSON.stringify(lines[at - 1]));
}
' "$R4" 2>"$WORK/idx.err" \
  && ok "an INDEX row resolves to the right line of the archive file" \
  || no "INDEX resolution: $(cat "$WORK/idx.err")"

echo "== 5. The wrapper goes RED when a run mutates the never-rotated authority =="
R5="$(blank_repo repo5)"
( cd "$R5" && "$SRC/init-build-os.sh" ) > "$WORK/install5.log" 2>&1
GATES5="$R5/build-os/memory/standing_gates.md"
sha256sum < "$GATES5" > "$WORK/gates5.before"
# a properly-armed suite file (so the coverage scan lets the run start) whose
# body damages the one file nothing may write
cat > "$R5/build-os/maintenance/zz-damage-gates.test.mjs" <<'EOF'
import "./real-memory-tripwire.mjs";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
const here = path.dirname(fileURLToPath(import.meta.url));
fs.writeFileSync(
  path.join(here, "..", "..", "build-os/memory/standing_gates.md"),
  "DAMAGED BY A TEST BODY\n"
);
EOF
( cd "$R5" && ./build-os/maintenance/run-tests.sh ) > "$WORK/wrap5.log" 2>&1
W5=$?
[ $W5 -ne 0 ] && ok "the wrapper exits non-zero ($W5) when the gates file is rewritten" \
              || no "the wrapper exited 0 with a damaged standing_gates.md"
grep -q 'REAL BUILD OS MEMORY WAS MUTATED BY THIS TEST RUN' "$WORK/wrap5.log" \
  && ok "...and says so, loudly" || no "no mutation report was printed"
grep -q 'standing_gates.md' "$WORK/wrap5.log" \
  && ok "...naming the never-rotated authority by path" || no "the report does not name the gates file"
[ "$(sha256sum < "$GATES5")" != "$(cat "$WORK/gates5.before")" ] \
  && ok "the damage really happened (detection, not prevention — as documented)" \
  || no "nothing was actually damaged, so this proof is vacuous"
rm -f "$R5/build-os/maintenance/zz-damage-gates.test.mjs"

echo "== 6. A bare \`node --test\` is UNGUARDED, and nothing here advertises it =="
R6="$(blank_repo repo6)"
( cd "$R6" && "$SRC/init-build-os.sh" ) > "$WORK/install6.log" 2>&1
VICTIM6="$R6/build-os/memory/residue.md"
cp "$VICTIM6" "$WORK/residue6.before"
# a file with NO imports at all: nothing can load from it, so on the bare path
# there is no tripwire and no coverage scan
cat > "$R6/build-os/maintenance/zz-noimport.test.mjs" <<'EOF'
const fs = await import("node:fs");
const path = await import("node:path");
const url = await import("node:url");
const here = path.dirname(url.fileURLToPath(import.meta.url));
fs.writeFileSync(path.join(here, "..", "..", "build-os/memory/residue.md"), "DAMAGED\n");
EOF
( cd "$R6" && node --test build-os/maintenance/zz-noimport.test.mjs ) > "$WORK/bare6.log" 2>&1
B6=$?
if [ $B6 -eq 0 ] && [ "$(cat "$VICTIM6")" = "DAMAGED" ]; then
  ok "MEASURED: bare \`node --test\` exits 0 with the tree damaged (unguarded)"
else
  no "the bare-path measurement did not reproduce (exit $B6)"
fi
cp "$WORK/residue6.before" "$VICTIM6"
# ...and the same file under the sanctioned wrapper is refused BEFORE it runs
( cd "$R6" && ./build-os/maintenance/run-tests.sh ) > "$WORK/wrap6.log" 2>&1
W6=$?
[ $W6 -ne 0 ] && ok "the wrapper refuses the same file (exit $W6)" || no "the wrapper accepted an uncovered file"
grep -q 'THE REAL-MEMORY TRIPWIRE IS NOT ARMED EVERYWHERE' "$WORK/wrap6.log" \
  && ok "...naming it, before it executes" || no "the coverage scan did not report the file"
cmp -s "$WORK/residue6.before" "$VICTIM6" \
  && ok "...and the tree is untouched on that path" || no "the wrapper path damaged the tree"
rm -f "$R6/build-os/maintenance/zz-noimport.test.mjs"
# the bare path is documented as uncovered, and never advertised as the command
grep -q 'a bare `node --test`, in every form' "$R6/build-os/maintenance/run-tests.sh" \
  && ok "the installed wrapper enumerates the bare path as uncovered" \
  || no "the installed wrapper no longer names the bare path"
BAD="$(grep -rEn '^[ \t]*(\*|#|//)?[ \t]*(Run:[ \t]*)?node[ \t]+--test\b' \
        "$R6/build-os/maintenance/" 2>/dev/null | wc -l)"
[ "$BAD" = "0" ] && ok "no installed file advertises a bare \`node --test\` as an instruction" \
                 || no "$BAD installed line(s) advertise the unguarded command"

echo "== 6a. COVERAGE-GATE-PREVENTION-DIFFERENTIAL — what demoting the coverage scan actually costs =="
# maint.tripwire_coverage_scan is `refuted`, so the evidence axis caps it at
# `observe` and the census reads it as the most obvious demotion candidate in the
# repository. Its own registry entry used to INSTRUCT that demotion: "collect the
# findings and print them instead of throwing".
#
# This is the measurement that was taken before accepting that, and it went the
# other way. Two arms, identical in every respect but the throw:
#
#   ARM GATED   — as shipped: the scan throws.        exit 1, tree UNTOUCHED.
#   ARM DEMOTED — the throw replaced by a print.      exit 1, tree DESTROYED.
#
# THE EXIT CODE IS 1 IN BOTH ARMS. Anything watching exit codes — a caller, a CI
# job, a reviewer reading a transcript — sees a demotion that changed nothing.
# Only the tree tells them apart, and what it says is that this gate is the only
# PREVENTION in the layer: the tripwire hashes and the shell fingerprints are
# both detection after the fact and both declare rollback_behavior: NONE.
RD6="$(blank_repo repo6a)"
( cd "$RD6" && "$SRC/init-build-os.sh" ) > "$WORK/install6a.log" 2>&1
VD="$RD6/build-os/memory/residue.md"
cp "$VD" "$WORK/residue6a.before"
cat > "$RD6/build-os/maintenance/zz-uncovered.test.mjs" <<'EOF'
const fs = await import("node:fs");
const path = await import("node:path");
const url = await import("node:url");
const here = path.dirname(url.fileURLToPath(import.meta.url));
fs.writeFileSync(path.join(here, "..", "..", "build-os/memory/residue.md"), "DAMAGED\n");
EOF

# --- COVERAGE-GATE-PREVENTION-DIFFERENTIAL-ARM-GATED ------------------------
( cd "$RD6" && ./build-os/maintenance/run-tests.sh ) > "$WORK/armgated.log" 2>&1
AG=$?
[ $AG -ne 0 ] && ok "ARM GATED: the wrapper refuses (exit $AG)" \
              || no "ARM GATED: the wrapper accepted an uncovered file"
cmp -s "$WORK/residue6a.before" "$VD" \
  && ok "ARM GATED: the tree is UNTOUCHED — this is PREVENTION, not detection" \
  || no "ARM GATED: the tree was damaged, so the gate prevents nothing"
cp "$WORK/residue6a.before" "$VD"

# --- COVERAGE-GATE-PREVENTION-DIFFERENTIAL-ARM-DEMOTED ----------------------
# The demotion the registry entry used to prescribe, applied literally: the
# throw becomes a print and nothing else changes.
TRIPD="$RD6/build-os/maintenance/real-memory-tripwire.mjs"
perl -0pi -e 's/if \(COVERAGE_FINDINGS\.length > 0\) \{\n  throw new Error\(/if (COVERAGE_FINDINGS.length > 0) {\n  console.error(/' "$TRIPD"
grep -q 'console.error(' "$TRIPD" \
  && ok "ARM DEMOTED: the throw was replaced by a print (the demotion, applied)" \
  || no "ARM DEMOTED: the demotion could not be applied — this differential is vacuous"
( cd "$RD6" && ./build-os/maintenance/run-tests.sh ) > "$WORK/armdemoted.log" 2>&1
AD=$?
[ $AD -ne 0 ] && ok "ARM DEMOTED: the run still exits non-zero ($AD) — the exit code hides the whole difference" \
              || no "ARM DEMOTED: the run exited 0"
cmp -s "$WORK/residue6a.before" "$VD" \
  && no "ARM DEMOTED: the tree survived, so the gate was not what prevented the write — re-derive this finding" \
  || ok "ARM DEMOTED: the tree is DESTROYED — demotion converts prevention into detection"
# The finding, stated as the comparison it rests on: same exit code, different tree.
{ [ $AG -ne 0 ] && [ $AD -ne 0 ] && ! cmp -s "$WORK/residue6a.before" "$VD"; } \
  && ok "DIFFERENTIAL: both arms exit non-zero and only the TREE differs — a demotion no exit-code check can see" \
  || no "DIFFERENTIAL: the two arms did not separate on the tree alone"
rm -f "$RD6/build-os/maintenance/zz-uncovered.test.mjs"

echo "== 7. The uninstall boundary is exact =="
R7="$(blank_repo repo7)"
( cd "$R7" && "$SRC/init-build-os.sh" ) > "$WORK/install7.log" 2>&1
printf '\n## a gate I added myself\n\nHARD STOP — mine.\n' >> "$R7/build-os/memory/standing_gates.md"
( cd "$R7" && ./build-os/maintenance/rotate-memory.sh --file active_packet --keep 2 --apply ) \
  > "$WORK/rot7.log" 2>&1
CUSTOMER7="$WORK/customer7.before"
( cd "$R7" && find build-os/memory build-os/packets -type f -print0 | LC_ALL=C sort -z \
    | while IFS= read -r -d '' f; do printf '%s %s\n' "$f" "$(sha256sum < "$f" | cut -d' ' -f1)"; done ) > "$CUSTOMER7"
[ -s "$CUSTOMER7" ] && ok "customer state snapshot is non-empty" || no "customer snapshot is empty"

MANIFEST="$R7/build-os/maintenance/.gravito-managed"
grep -q 'GRAVITO:MANAGED' "$MANIFEST" && ok "the uninstall manifest declares itself managed" || no "manifest has no marker"
( cd "$R7" && grep -v '^#' build-os/maintenance/.gravito-managed | while read -r rel; do
    [ -n "$rel" ] && rm -f "$rel"
  done )
find "$R7/build-os/maintenance" -type f | grep -q . \
  && no "files remain under build-os/maintenance after removing the manifest list: $(find "$R7/build-os/maintenance" -type f)" \
  || ok "removing exactly the manifest list empties build-os/maintenance/"

( cd "$R7" && find build-os/memory build-os/packets -type f -print0 | LC_ALL=C sort -z \
    | while IFS= read -r -d '' f; do printf '%s %s\n' "$f" "$(sha256sum < "$f" | cut -d' ' -f1)"; done ) > "$WORK/customer7.after"
if diff -q "$CUSTOMER7" "$WORK/customer7.after" >/dev/null; then
  ok "every customer file is byte-identical after uninstall"
else
  no "uninstall touched customer state: $(diff "$CUSTOMER7" "$WORK/customer7.after" | head -5)"
fi
[ -f "$R7/build-os/memory/standing_gates.md" ] && ok "the customer's gates file survives uninstall" || no "uninstall removed the gates file"
[ -d "$R7/build-os/memory/archive" ] && ok "the archive (the only copy of rotated content) survives uninstall" || no "uninstall removed the archive"
grep -q 'Full version rollback' "$SRC/build-os/maintenance/PORTING.md" \
  && ok "PORTING.md states the version-rollback boundary explicitly" || no "PORTING.md does not state the rollback boundary"

# A matching pre-registration record, written BEFORE the apply it authorises.
# Used by the keep-sweeps in sections 8 and 9 and by section 10: since the
# rotation sentinel shipped, an --apply over a file carrying protected objects
# is refused unless one of these binds it (refusal condition 5).
sent_prereg(){ # <path> <file> <keep> <source>
  node -e '
const fs = require("fs"), crypto = require("crypto");
const [out, file, keep, src] = process.argv.slice(1);
fs.writeFileSync(out, JSON.stringify({
  tool: "build-os/maintenance/rotate-memory.sh",
  file, keep: Number(keep),
  sourceSha256: crypto.createHash("sha256").update(fs.readFileSync(src)).digest("hex"),
}, null, 2) + "\n");
' "$1" "$2" "$3" "$4"
}

echo "== 8. THIS repository's live residue.md is rotatable, and its standing region is not =="
# WHY THIS SECTION EXISTS, AND WHY IT IS ABOUT THE LIVE FILE RATHER THAN A FIXTURE.
#
# Sections 1-7 prove the maintenance layer works on synthetic memory. They said
# nothing about whether it can do anything for THIS repository's memory, and the
# answer was no: `build-os/memory/residue.md` reached 204658 B against the
# 204800 B ceiling `rotate-memory.test.mjs` enforces — 142 B of headroom, so the
# next close had no green path — while carrying exactly THREE `^## ` blocks.
# `rotate-memory.mjs`'s `routeSegments` retains `blocks.slice(0, keepN)`, so at
# the shipped `keep=10` it retained all three and archived 0 blocks and 0 bytes.
# The preventative tool had nothing to prevent with, and it REFUSES at exit 3
# (EXIT.CEILING) once the file is already over — a precondition the failure it
# prevents violates. Nothing in the suite could see that, because every rotation
# proof ran on a generated fixture with 120 blocks.
#
# SELECTION IS BY POSITION, AND THE POSITION IT KEEPS IS THE PREFIX. Measured,
# not read: on a 5-block fixture `--keep 2` reports `would archive block_3..
# block_5`. So content that must survive rotation belongs at the HEAD of the
# file, and the header's warning — "a standing gate sitting in the archive
# region is archived like anything else" — is a statement about the TAIL.
#
# WHAT THIS SECTION DOES NOT CLAIM. It does not rotate the live tree; every
# invocation below carries an explicit `--root` into $WORK and the live file is
# only ever READ. It does not claim the archived content is unimportant — the
# archive is append-only, committed, and named by the banner. It claims exactly
# two things: rotation can now reclaim real space from this file, and the
# standing region cannot be what it reclaims.
#
# ON THE COMPARISON OPERATORS. Every threshold below is written as a `-lt`/`-le`
# REFUSAL rather than a `-ge`/`-gt` floor. That is deliberate and is stated so it
# is auditable rather than incidental: `tests.nonvacuity_minimums` groups
# `-ge N`/`-gt N` with N > 1 in tests/*.sh by a SYNTACTIC rule, and its members
# are fitted floors on how much a SCANNER COVERED. These are not that — they are
# substantive thresholds on a measured property of a memory file — so they are
# written in the form that does not enrol them in a family they do not belong to.
RES_LIVE="$SRC/build-os/memory/residue.md"
RES_CEIL=204800                      # rotate-memory.mjs DEFAULT_MAX_BYTES, 200 KB
RES_MIN_RECLAIM=40960                # 40 KB: the floor this packet had to clear
RES_ROOT="$WORK/live-residue"
mkdir -p "$RES_ROOT/build-os/memory"
cp "$RES_LIVE" "$RES_ROOT/build-os/memory/residue.md"
cmp -s "$RES_LIVE" "$RES_ROOT/build-os/memory/residue.md" \
  && ok "the live residue.md is copied byte-identically into a scratch root (the live tree is only READ)" \
  || no "the scratch copy of residue.md is not byte-identical — every measurement below would be about the wrong file"

# (a) THE BLOCK STRUCTURE. Three blocks is the condition under which rotation is
#     a reported no-op at the shipped keep, whatever the file's size.
RES_BLOCKS="$(grep -c '^## ' "$RES_LIVE")"
if [ "${RES_BLOCKS:-0}" -le 10 ]; then
  no "residue.md carries $RES_BLOCKS \`^## \` block(s); at the shipped keep=10 rotation retains min(10,$RES_BLOCKS)=$RES_BLOCKS and archives NOTHING, so the file cannot be relieved by the tool built to relieve it"
else
  ok "residue.md carries $RES_BLOCKS \`^## \` blocks — more than the shipped keep=10, so rotation has a tail to archive"
fi

# (b) WHAT THE SHIPPED KEEP WOULD DO, AND WHY IT IS NO LONGER ALLOWED TO DO IT.
#
#     THIS SUBSECTION CHANGED WHEN THE ROTATION SENTINEL SHIPPED, AND THE CHANGE
#     IS AN INVERSION RATHER THAN AN ADJUSTMENT. It used to assert that a
#     `--keep 10` rotation of this file EXITS 0 and reclaims at least 40960 B.
#     Both were true measurements and the ACTION they measured was unsafe: after
#     the first governed rotation this file carries 25 blocks, and `--keep 10`
#     archives blocks 11..25 — among them block 16 (`(ddd)`, marked "IS NOT
#     CONSUMED AND MUST NOT BE MARKED SO") and block 25 (`(S1)` and the flake
#     marked "[STILL OPEN AND STILL UNDIAGNOSABLE]"). The old assertions were
#     measuring the value of a rotation that would have destroyed the property
#     the section above proves. They are replaced, not deleted: the measurement
#     is still taken, through `--sentinel-report`, which is the mode that reports
#     without refusing.
RES_DRY="$WORK/residue-dry.json"
node "$SRC/build-os/maintenance/rotate-memory.mjs" \
     --root "$RES_ROOT" --file residue --keep 10 --sentinel-report --json \
     > "$RES_DRY" 2>"$WORK/residue-dry.err"
RES_DRY_RC=$?
[ "$RES_DRY_RC" -eq 0 ] \
  && ok "a --keep 10 --sentinel-report over a scratch copy of the live residue.md exits 0 — the tool will always SAY what a rotation would do, even one it refuses to perform" \
  || no "the --keep 10 sentinel report exited $RES_DRY_RC: $(head -c 300 "$WORK/residue-dry.err")"
node -e '
const fs = require("fs");
const r = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).results[0];
const out = [r.totalBlocks, r.retainedBlocks, r.archivedBlocks, r.archivedBytes,
             r.retainedBytes, r.originalBytes, r.withinCeiling ? 1 : 0].join(" ");
fs.writeFileSync(process.argv[2], out + "\n");
' "$RES_DRY" "$WORK/residue-dry.fields" 2>"$WORK/residue-fields.err"
RES_FIELDS_RC=$?
if [ "$RES_FIELDS_RC" -eq 0 ]; then
  read -r RES_TOT RES_KEPT RES_ARCH_N RES_ARCH_B RES_RETB RES_ORIGB RES_OK < "$WORK/residue-dry.fields"
  ok "the dry run reports machine-readable counts ($RES_TOT blocks -> keep $RES_KEPT, archive $RES_ARCH_N)"
else
  RES_TOT=0; RES_KEPT=0; RES_ARCH_N=0; RES_ARCH_B=0; RES_RETB=0; RES_ORIGB=0; RES_OK=0
  no "the dry-run report could not be parsed: $(head -c 300 "$WORK/residue-fields.err")"
fi
if [ "${RES_ARCH_N:-0}" -le 0 ]; then
  no "rotation at the shipped keep=10 would archive $RES_ARCH_N blocks — it is a REPORTED NO-OP, which reads exactly like \"already rotated\""
else
  ok "rotation at the shipped keep=10 would archive $RES_ARCH_N block(s) of residue.md — the tail is still there, which is what makes the refusal below a REAL refusal rather than a description of a no-op"
fi

# (b2) ...AND THE SENTINEL REFUSES IT, BEFORE MUTATION. This is the operator-named
#      fixture, stated here as the fact about THIS FILE; section 10 drives the
#      guard's eight conditions in general.
RES_REFUSE_ROOT="$WORK/residue-refuse"
mkdir -p "$RES_REFUSE_ROOT/build-os/memory"
cp "$RES_LIVE" "$RES_REFUSE_ROOT/build-os/memory/residue.md"
sha256sum < "$RES_REFUSE_ROOT/build-os/memory/residue.md" > "$WORK/residue-refuse.before"
node "$SRC/build-os/maintenance/rotate-memory.mjs" \
     --root "$RES_REFUSE_ROOT" --file residue --keep 10 --apply \
     > "$WORK/residue-refuse.out" 2>"$WORK/residue-refuse.err"
RES_REFUSE_RC=$?
[ "$RES_REFUSE_RC" -eq 7 ] \
  && ok "\`--keep 10 --apply\` over this file is REFUSED at exit 7 — the command that sat queued in this repository's own residue as a pending action cannot be run by accident" \
  || no "\`--keep 10 --apply\` over residue.md exited $RES_REFUSE_RC, not 7"
[ "$(sha256sum < "$RES_REFUSE_ROOT/build-os/memory/residue.md")" = "$(cat "$WORK/residue-refuse.before")" ] \
  && ok "...and the refusal came BEFORE MUTATION — the file is byte-identical and no archive exists" \
  || no "the refused --keep 10 --apply still wrote"

# (c) WHAT ROTATION CAN LEGALLY RECLAIM FROM THIS FILE, WHICH IS THE NUMBER THAT
#     REPLACED THE OLD 40960 B FLOOR.
#
#     The old floor asserted that a keep=10 rotation reclaims >= 40 KB. It does
#     — and it is forbidden, so the number describes an action nobody may take.
#     The number that matters now is what the SAFE keep reclaims, and for this
#     file the honest answer is currently ZERO: `minimum_safe_keep` equals the
#     block count, so the only keep the sentinel permits archives nothing. That
#     is not a defect in the guard; it is the file's true state, and the two
#     things that would change it are both operator acts — close the still-open
#     items, or move them to the head of the file.
RES_MIN_SAFE="$(node -e '
const fs = require("fs");
const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).results[0].sentinel;
process.stdout.write(String(s.minimum_safe_keep));
' "$RES_DRY" 2>/dev/null)"
# RE-DERIVED INDEPENDENTLY IN BASH, so this is a cross-check and not the tool
# agreeing with itself: the deepest block carrying a bracketed STILL-OPEN status
# tag is a lower bound on the floor, whatever else the scan finds.
RES_OPEN_BLK="$(awk '/^## /{n++} /\[STILL OPEN/{print n}' "$RES_LIVE" | sort -n | tail -1)"
if [ -z "$RES_MIN_SAFE" ] || [ -z "$RES_OPEN_BLK" ]; then
  no "residue.md's minimum_safe_keep ('$RES_MIN_SAFE') or its independently-derived open-item block ('$RES_OPEN_BLK') could not be measured"
elif [ "$RES_MIN_SAFE" -lt "$RES_OPEN_BLK" ]; then
  no "the tool derives minimum_safe_keep $RES_MIN_SAFE for residue.md while block $RES_OPEN_BLK still carries a [STILL OPEN marker — the floor is below an open item, so a permitted keep would archive it"
else
  ok "residue.md's derived minimum_safe_keep is $RES_MIN_SAFE, at or below which nothing may rotate, and it is at least the block ($RES_OPEN_BLK) an independent bash scan finds still carrying a [STILL OPEN marker"
fi
RES_RECLAIMABLE=$(( ${RES_TOT:-0} - ${RES_MIN_SAFE:-0} ))
if [ "$RES_RECLAIMABLE" -lt 0 ]; then
  no "residue.md's minimum_safe_keep ($RES_MIN_SAFE) exceeds its block count (${RES_TOT:-0}) — the floor cannot be satisfied by any legal keep at all"
else
  ok "residue.md: $RES_TOT blocks, floor $RES_MIN_SAFE, so exactly $RES_RECLAIMABLE block(s) are legally reclaimable from it by rotation"
fi
RES_HEADROOM=$(( RES_CEIL - $(wc -c < "$RES_LIVE") ))
# NOT A FLOOR ON THE HEADROOM. This file is at its safe floor, so its headroom
# cannot be improved by the tool and asserting a minimum would be asserting
# something no action available here can deliver. What IS asserted is that the
# number is derived and reported, and that the file is still under the ceiling —
# past it the tool refuses at EXIT.CEILING and the window closes entirely.
if [ "$RES_HEADROOM" -lt 0 ]; then
  no "residue.md is $(wc -c < "$RES_LIVE") B, already past the $RES_CEIL B ceiling — rotation refuses at EXIT.CEILING from here and $RES_RECLAIMABLE block(s) are reclaimable, so the preventative window is closed"
else
  ok "residue.md is $(wc -c < "$RES_LIVE") B, leaving $RES_HEADROOM B under the $RES_CEIL B ceiling — derived here, never quoted, because this file measures itself"
fi
[ "${RES_OK:-0}" = "1" ] \
  && ok "the tool itself reports the post-rotation size within its own ceiling" \
  || no "the tool reports the post-rotation size OUTSIDE its ceiling — rotation cannot fix this file"

# (d) THE PROTECTED REGION — PROVEN BY EXECUTION, NOT BY THE ORDER THINGS WERE
#     WRITTEN IN. `rotate-memory.mjs` has no notion of protected content and this
#     does not give it one. It proves a POSITIONAL fact: the standing region is
#     the file's FIRST block, retention is a prefix, and `--keep` is validated
#     `>= 1`, so no legal invocation of the tool can archive it. Each of the
#     three literals `tests/release_metadata_tests.sh:322-324` pins is required
#     to live there and NOWHERE ELSE, so no archived block can be what satisfies
#     that suite.
RES_HEAD_BLOCK="$(grep -m1 '^## ' "$RES_LIVE")"
case "$RES_HEAD_BLOCK" in
  "## Standing"*) ok "residue.md's FIRST block is the designated standing region: $RES_HEAD_BLOCK" ;;
  *)              no "residue.md's first block is \"$RES_HEAD_BLOCK\", not a designated \`## Standing\` region — nothing in this file marks what rotation must not reach" ;;
esac
# BLOCK 1 IS EXTRACTED BY ITS OWN DELIMITER, not by a remembered line number:
# from the FIRST `^## ` heading up to but excluding the SECOND. That is also
# what makes the byte comparison below survivable — rotation inserts its
# ~506 B archive-pointer banner into the PREAMBLE, ahead of the first heading,
# so a preamble-inclusive comparison would report a difference on every run that
# actually rotates and would be measuring the banner, not the standing content.
res_block1(){ awk '/^## /{n++} n==1' "$1"; }
res_not_block1(){ awk '/^## /{n++} n!=1' "$1"; }
RES_B1="$WORK/residue-block1.txt"
res_block1 "$RES_LIVE" > "$RES_B1"
RES_OUTSIDE="$WORK/residue-outside-block1.txt"
res_not_block1 "$RES_LIVE" > "$RES_OUTSIDE"
RES_PINNED_IN=0; RES_PINNED_OUT=0
for term in "license model" "no tags" "single-platform"; do
  grep -qiF "$term" "$RES_B1" && RES_PINNED_IN=$((RES_PINNED_IN+1))
  grep -qiF "$term" "$RES_OUTSIDE" && RES_PINNED_OUT=$((RES_PINNED_OUT+1))
done
[ "$RES_PINNED_IN" -eq 3 ] \
  && ok "all three gate-pinned literals (license model / no tags / single-platform) live inside the standing block" \
  || no "only $RES_PINNED_IN of the 3 gate-pinned literals are inside the standing block — the rest sit where rotation can take them"
[ "$RES_PINNED_OUT" -eq 0 ] \
  && ok "none of the three gate-pinned literals occurs OUTSIDE the standing block, so no archivable block is what keeps tests/release_metadata_tests.sh green" \
  || no "$RES_PINNED_OUT of the gate-pinned literals also occur outside the standing block — an archived block could be what satisfies the release-metadata suite"

# EXECUTED, at EVERY legal N: 1..totalBlocks. A fresh scratch copy per pass,
# --apply, then the rotated live file and the archive are both examined.
#
# TWO OUTCOMES ARE LEGITIMATE AND THEY ARE SEPARATED RATHER THAN LUMPED. A keep
# large enough that the RETAINED file would still exceed the 200 KB ceiling is
# refused at EXIT.CEILING (3) — the tool reporting and stopping, never
# auto-reducing N — and such a run writes NOTHING, so it cannot archive
# anything either. Counting a ceiling refusal as a protection failure would be
# reporting the tool's own safety as a defect; counting it as a success without
# checking that it wrote nothing would be worse. Both are checked.
RES_N_ROT=0; RES_N_REFUSED=0; RES_N_SENT=0; RES_N_BAD=0; RES_N_LEAK=0; RES_N_DRIFT=0
RES_N=1
while [ "$RES_N" -le "${RES_TOT:-0}" ]; do
  RES_NR="$WORK/keep-$RES_N"
  mkdir -p "$RES_NR/build-os/memory"
  cp "$RES_LIVE" "$RES_NR/build-os/memory/residue.md"
  # THE SWEEP PRE-REGISTERS EVERY APPLY. Without one, refusal condition 5 would
  # refuse every pass and the whole sweep would collapse into a single fact
  # about pre-registration — a vacuous proof wearing a sweep's clothes.
  sent_prereg "$WORK/keep-$RES_N.prereg.json" residue "$RES_N" "$RES_NR/build-os/memory/residue.md"
  node "$SRC/build-os/maintenance/rotate-memory.mjs" \
       --root "$RES_NR" --file residue --keep "$RES_N" --apply \
       --pre-registration "$WORK/keep-$RES_N.prereg.json" \
       > "$WORK/keep-$RES_N.out" 2>&1
  RES_N_RC=$?
  if [ "$RES_N_RC" -eq 3 ] || [ "$RES_N_RC" -eq 7 ]; then
    # A REFUSAL MUST BE A NO-WRITE, whichever guard raised it: the copy is
    # untouched and no archive was created, so nothing was archived and nothing
    # was lost. The two are counted separately because they mean different
    # things — 3 is the byte ceiling, 7 is the rotation sentinel.
    if [ "$RES_N_RC" -eq 3 ]; then RES_N_REFUSED=$((RES_N_REFUSED+1)); else RES_N_SENT=$((RES_N_SENT+1)); fi
    cmp -s "$RES_LIVE" "$RES_NR/build-os/memory/residue.md" || RES_N_BAD=$((RES_N_BAD+1))
    [ -e "$RES_NR/build-os/memory/archive" ] && RES_N_BAD=$((RES_N_BAD+1))
  elif [ "$RES_N_RC" -ne 0 ]; then
    RES_N_BAD=$((RES_N_BAD+1))
  else
    RES_N_ROT=$((RES_N_ROT+1))
    for term in "license model" "no tags" "single-platform"; do
      grep -qiF "$term" "$RES_NR/build-os/memory/residue.md" || RES_N_BAD=$((RES_N_BAD+1))
      if [ -f "$RES_NR/build-os/memory/archive/residue.archive.md" ]; then
        grep -qiF "$term" "$RES_NR/build-os/memory/archive/residue.archive.md" && RES_N_LEAK=$((RES_N_LEAK+1))
      fi
    done
    # the standing block must survive byte-identically, not merely in substance
    RES_NB1="$WORK/keep-$RES_N.block1"
    res_block1 "$RES_NR/build-os/memory/residue.md" > "$RES_NB1"
    cmp -s "$RES_B1" "$RES_NB1" || RES_N_DRIFT=$((RES_N_DRIFT+1))
  fi
  RES_N=$((RES_N+1))
done
if [ "${RES_TOT:-0}" -le 0 ]; then
  no "the keep-sweep had no block count to sweep over — the proof below is vacuous"
else
  ok "the keep-sweep ran every legal N from 1 to $RES_TOT — the whole domain of the PARAMETER THAT DETERMINES ROUTING (--keep is validated >= 1 and routeSegments(segments, keepN) takes no other input), NOT the tool's whole legal domain: --max-bytes is equally user-settable and is not swept"
fi
[ $(( RES_N_ROT + RES_N_REFUSED + RES_N_SENT )) -eq "${RES_TOT:-0}" ] \
  && ok "every legal keep ended in one of exactly three ways: $RES_N_ROT rotated, $RES_N_REFUSED refused at the byte ceiling (exit 3), $RES_N_SENT refused by the rotation sentinel (exit 7) — and all three write nothing" \
  || no "a legal keep ended some fourth way — $RES_N_ROT rotated + $RES_N_REFUSED ceiling + $RES_N_SENT sentinel != ${RES_TOT:-0} sweeps"
# THE SENTINEL'S SHARE OF THAT SWEEP IS ASSERTED, because a guard that refuses
# nothing over the whole domain of the parameter it guards is indistinguishable
# from one that is switched off.
if [ "$RES_N_SENT" -lt $(( ${RES_MIN_SAFE:-1} - 1 )) ]; then
  no "the sentinel refused only $RES_N_SENT of the $(( ${RES_MIN_SAFE:-1} - 1 )) keeps that sit below the derived floor $RES_MIN_SAFE — at least one unsafe keep was permitted"
else
  # THE TITLE SEPARATES THE TWO POPULATIONS, because they are not the same size
  # and the earlier wording read as though they were. Only $(( RES_MIN_SAFE - 1 ))
  # keeps sit BELOW the floor; the remaining sentinel refusals are keeps at or
  # above it that are refused for a different reason (on this file, C2's
  # unresolvable identity and C7's close budget). Reporting the total as "all N
  # keeps below the floor" overstates the floor's own coverage by exactly the
  # difference.
  ok "the sentinel refused $RES_N_SENT keep(s) of the 1..$RES_TOT domain, which covers all $(( ${RES_MIN_SAFE:-1} - 1 )) keep(s) strictly BELOW its derived floor of $RES_MIN_SAFE plus $(( RES_N_SENT - ${RES_MIN_SAFE:-1} + 1 )) at or above it refused on other conditions"
fi
# THE NEXT THREE ARE VACUOUS ON THIS FILE TODAY, AND THE TITLES SAY SO RATHER
# THAN IMPLYING COVERAGE. `RES_N_ROT` is 0 here: residue.md's floor equals its
# block count, so no keep in the whole domain both passes the sentinel and
# archives anything, and the three counters below can only increment inside a
# branch that never executes. That is a true and useful fact about the file —
# nothing can rotate out of it — but it is NOT evidence that the tool protects
# gate-pinned literals, and a title reading "at all 0 rotating keeps ..." asserts
# the second while measuring the first. Section 9 carries the non-vacuous arm of
# this same proof (its sweep DOES rotate, and asserts separation in both
# directions); section 8 cannot, and says so instead of pretending.
if [ "${RES_N_ROT:-0}" -eq 0 ]; then
  RES_SWEEP_SCOPE="VACUOUS BY CONSTRUCTION — 0 keeps rotated, so this counter could not have incremented; the load-bearing arm of this proof is section 9's sweep"
else
  RES_SWEEP_SCOPE="over the $RES_N_ROT keep(s) that rotated"
fi
[ "$RES_N_BAD" -eq 0 ] \
  && ok "gate-pinned literals survived every rotating keep and every refusal wrote nothing [$RES_SWEEP_SCOPE]" \
  || no "$RES_N_BAD failure(s): a legal --keep archived a gate-pinned literal out of the live file, or a refusal still wrote"
[ "$RES_N_LEAK" -eq 0 ] \
  && ok "no gate-pinned literal reached the archive [$RES_SWEEP_SCOPE]" \
  || no "$RES_N_LEAK gate-pinned literal(s) reached the archive — the standing region is reachable by rotation after all"
[ "$RES_N_DRIFT" -eq 0 ] \
  && ok "block 1 stayed byte-identical to the source [$RES_SWEEP_SCOPE]" \
  || no "$RES_N_DRIFT keep(s) changed the standing block's bytes"

# The live tree was only read. Proven, not asserted.
cmp -s "$RES_LIVE" "$RES_ROOT/build-os/memory/residue.md" \
  && ok "the live residue.md is byte-identical to the copy taken before this section ran" \
  || no "the live residue.md changed during this section — a rotation reached the real tree"
[ -z "$(find "$SRC/build-os/memory/archive" -newer "$RES_ROOT/build-os/memory/residue.md" 2>/dev/null)" ] \
  && ok "nothing under the real build-os/memory/archive is newer than the scratch copy taken at the top of this section, so this section wrote no archive into the real tree (it was BOTH branches of an \`ok\`, and a guard that cannot fail reads as safety and adds no discriminating power)" \
  || no "a path under the real build-os/memory/archive is newer than this section's first write — a rotation reached the real tree"

echo "== 9. THIS repository's live current_state.md is rotatable, and its standing region is not =="
# WHY THIS SECTION EXISTS, AND WHY IT IS THE PROSPECTIVE CASE.
#
# Section 8 is the RETROSPECTIVE arm: `residue.md` had already reached 142 B of
# headroom when anybody looked, so the re-block had to be paid for out of a file
# that was effectively already over. This section is the same condition caught
# BEFORE the ceiling: `build-os/memory/current_state.md` measured 185204 B
# against the 204800 B ceiling — 19596 B of headroom — while carrying exactly
# THREE `^## ` blocks, so `routeSegments`' `blocks.slice(0, keepN)` retained all
# three at the shipped `keep=10` and archived 0 blocks and 0 bytes, at exit 0,
# printing `already rotated (no-op)`. THE INSTRUMENT CALLS THAT FILE HEALTHY
# RIGHT UP UNTIL IT IS UNFIXABLE: past the ceiling the tool REFUSES at exit 3
# (EXIT.CEILING), which is a precondition the failure it prevents violates, so
# the last moment the tool can help is strictly before the breach.
#
# WHAT THIS SECTION DOES NOT CLAIM. It does not rotate the live tree; every
# invocation below carries an explicit `--root` into $WORK and the live file is
# only ever READ. It claims exactly two things: rotation can now reclaim real
# space from this file, and the standing region cannot be what it reclaims.
#
# ON THE COMPARISON OPERATORS — the same reasoning as section 8. Every threshold
# is written as a `-lt`/`-le` REFUSAL rather than a `-ge`/`-gt` floor, so it is
# not enrolled by `tests.nonvacuity_minimums`' SYNTACTIC rule into a family of
# fitted floors on scanner coverage, which these are not.
#
# ON THE PINNED LITERALS, AND WHY THEY ARE MATCHED CASE-SENSITIVELY. Section 8
# matches residue's three literals with `-i` because they are prose phrases.
# These two are markdown markers that `tests/release_metadata_tests.sh` section 5
# greps for verbatim — `**Build/test command:**` (whose line must name
# `tests/build_os_tests.sh` and a check count) and `**Last closed packet:**` —
# and both are read with `head -n1`, i.e. the FIRST occurrence in the file. So a
# rotation that archived the first occurrence would silently re-point that guard
# at whatever came next, or at nothing. They are required to live in block 1 and
# NOWHERE ELSE, which is what makes `head -n1` and "survives every legal keep"
# the same statement.
CS_LIVE="$SRC/build-os/memory/current_state.md"
CS_CEIL=204800                      # rotate-memory.mjs DEFAULT_MAX_BYTES, 200 KB
CS_MIN_RECLAIM=40960                # 40 KB: the same floor section 8 had to clear
CS_ROOT="$WORK/live-current-state"
mkdir -p "$CS_ROOT/build-os/memory"
cp "$CS_LIVE" "$CS_ROOT/build-os/memory/current_state.md"
cmp -s "$CS_LIVE" "$CS_ROOT/build-os/memory/current_state.md" \
  && ok "the live current_state.md is copied byte-identically into a scratch root (the live tree is only READ)" \
  || no "the scratch copy of current_state.md is not byte-identical — every measurement below would be about the wrong file"

# (a) THE BLOCK STRUCTURE.
CS_BLOCKS="$(grep -c '^## ' "$CS_LIVE")"
if [ "${CS_BLOCKS:-0}" -le 10 ]; then
  no "current_state.md carries $CS_BLOCKS \`^## \` block(s); at the shipped keep=10 rotation retains min(10,$CS_BLOCKS)=$CS_BLOCKS and archives NOTHING, so the file cannot be relieved by the tool built to relieve it"
else
  ok "current_state.md carries $CS_BLOCKS \`^## \` blocks — more than the shipped keep=10, so rotation has a tail to archive"
fi

# (b) THE SHIPPED-KEEP ROTATION ACTUALLY ARCHIVES. Dry run, so nothing is
#     written anywhere; the exit code is captured DIRECTLY off the tool and
#     never off the tail of a pipeline.
CS_DRY="$WORK/current-state-dry.json"
node "$SRC/build-os/maintenance/rotate-memory.mjs" \
     --root "$CS_ROOT" --file current_state --keep 10 --json > "$CS_DRY" 2>"$WORK/current-state-dry.err"
CS_DRY_RC=$?
[ "$CS_DRY_RC" -eq 0 ] \
  && ok "a --keep 10 DRY RUN over a scratch copy of the live current_state.md exits 0 (no ceiling refusal)" \
  || no "the --keep 10 dry run exited $CS_DRY_RC: $(head -c 300 "$WORK/current-state-dry.err")"
node -e '
const fs = require("fs");
const r = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).results[0];
const out = [r.totalBlocks, r.retainedBlocks, r.archivedBlocks, r.archivedBytes,
             r.retainedBytes, r.originalBytes, r.withinCeiling ? 1 : 0].join(" ");
fs.writeFileSync(process.argv[2], out + "\n");
' "$CS_DRY" "$WORK/current-state-dry.fields" 2>"$WORK/current-state-fields.err"
CS_FIELDS_RC=$?
if [ "$CS_FIELDS_RC" -eq 0 ]; then
  read -r CS_TOT CS_KEPT CS_ARCH_N CS_ARCH_B CS_RETB CS_ORIGB CS_OK < "$WORK/current-state-dry.fields"
  ok "the dry run reports machine-readable counts ($CS_TOT blocks -> keep $CS_KEPT, archive $CS_ARCH_N)"
else
  CS_TOT=0; CS_KEPT=0; CS_ARCH_N=0; CS_ARCH_B=0; CS_RETB=0; CS_ORIGB=0; CS_OK=0
  no "the dry-run report could not be parsed: $(head -c 300 "$WORK/current-state-fields.err")"
fi
if [ "${CS_ARCH_N:-0}" -le 0 ]; then
  no "rotation at the shipped keep=10 would archive $CS_ARCH_N blocks of current_state.md — it is a REPORTED NO-OP at exit 0, which reads exactly like \"already rotated\""
else
  ok "rotation at the shipped keep=10 would archive $CS_ARCH_N block(s) of current_state.md"
fi

# (c) RECLAIMABLE BYTES, AND THE HEADROOM THEY BUY.
if [ "${CS_ARCH_B:-0}" -lt "$CS_MIN_RECLAIM" ]; then
  no "rotation at keep=10 would reclaim only ${CS_ARCH_B:-0} B from current_state.md (floor $CS_MIN_RECLAIM B) — the file is $CS_ORIGB B and there is nothing the tool can take"
else
  ok "rotation at keep=10 would reclaim $CS_ARCH_B B from current_state.md (>= the $CS_MIN_RECLAIM B floor)"
fi
CS_HEADROOM=$(( CS_CEIL - ${CS_RETB:-CS_CEIL} ))
if [ "$CS_HEADROOM" -lt "$CS_MIN_RECLAIM" ]; then
  no "after a keep=10 rotation current_state.md would still be ${CS_RETB:-?} B, leaving $CS_HEADROOM B under the $CS_CEIL B ceiling — a close writing more than that has no green path"
else
  ok "after a keep=10 rotation current_state.md would be $CS_RETB B, leaving $CS_HEADROOM B of headroom under the $CS_CEIL B ceiling"
fi
[ "${CS_OK:-0}" = "1" ] \
  && ok "the tool itself reports the post-rotation size within its own ceiling" \
  || no "the tool reports the post-rotation size OUTSIDE its ceiling — rotation cannot fix this file"

# (c2) THE FILE IS STILL UNDER THE CEILING TODAY. This is the PROSPECTIVE half
#      and it is the difference between this section and section 8: the tool
#      refuses at EXIT.CEILING once a file is already over, so a re-block that
#      arrives after the breach arrives after the tool can act. Asserting it here
#      keeps the "we were early" claim falsifiable rather than narrated.
CS_NOW="$(wc -c < "$CS_LIVE")"
if [ "${CS_NOW:-0}" -gt "$CS_CEIL" ]; then
  no "current_state.md is $CS_NOW B, already past the $CS_CEIL B ceiling — rotation refuses at EXIT.CEILING from here, so the preventative window is closed"
else
  ok "current_state.md is $CS_NOW B, still under the $CS_CEIL B ceiling — the re-block landed while the tool could still act"
fi

# (d) THE PROTECTED REGION — PROVEN BY EXECUTION. `rotate-memory.mjs` has no
#     notion of protected content and this does not give it one. It proves a
#     POSITIONAL fact: the standing region is the file's FIRST block, retention
#     is a prefix, and `--keep` is validated `>= 1`, so no legal invocation can
#     archive it.
CS_HEAD_BLOCK="$(grep -m1 '^## ' "$CS_LIVE")"
case "$CS_HEAD_BLOCK" in
  "## Standing"*) ok "current_state.md's FIRST block is the designated standing region: $CS_HEAD_BLOCK" ;;
  *)              no "current_state.md's first block is \"$CS_HEAD_BLOCK\", not a designated \`## Standing\` region — nothing in this file marks what rotation must not reach" ;;
esac
# BLOCK 1 IS EXTRACTED BY ITS OWN DELIMITER, not by a remembered line number:
# from the FIRST `^## ` heading up to but excluding the SECOND. That is also
# what makes the byte comparison below survivable — rotation inserts its
# ~506 B archive-pointer banner into the PREAMBLE, ahead of the first heading.
cs_block1(){ awk '/^## /{n++} n==1' "$1"; }
cs_not_block1(){ awk '/^## /{n++} n!=1' "$1"; }
CS_B1="$WORK/current-state-block1.txt"
cs_block1 "$CS_LIVE" > "$CS_B1"
CS_OUTSIDE="$WORK/current-state-outside-block1.txt"
cs_not_block1 "$CS_LIVE" > "$CS_OUTSIDE"
CS_PINNED_IN=0; CS_PINNED_OUT=0
for term in '**Build/test command:**' '**Last closed packet:**'; do
  grep -qF -- "$term" "$CS_B1" && CS_PINNED_IN=$((CS_PINNED_IN+1))
  grep -qF -- "$term" "$CS_OUTSIDE" && CS_PINNED_OUT=$((CS_PINNED_OUT+1))
done
[ "$CS_PINNED_IN" -eq 2 ] \
  && ok "both gate-pinned literals (**Build/test command:** / **Last closed packet:**) live inside the standing block" \
  || no "only $CS_PINNED_IN of the 2 gate-pinned literals are inside the standing block — the rest sit where rotation can take them"
[ "$CS_PINNED_OUT" -eq 0 ] \
  && ok "neither gate-pinned literal occurs OUTSIDE the standing block, so no archivable block is what keeps tests/release_metadata_tests.sh section 5 green" \
  || no "$CS_PINNED_OUT of the gate-pinned literals also occur outside the standing block — an archived block could be what satisfies the release-metadata guard, and both are read with head -n1"

# EXECUTED, at EVERY legal N: 1..totalBlocks — the whole domain of `--keep`,
# which `parseArgs` validates as an integer >= 1 and which is the only input
# `routeSegments(segments, keepN)` takes besides the segments themselves. A
# fresh scratch copy per pass, --apply, then the rotated live file and the
# archive are both examined. A ceiling refusal (exit 3) is a legitimate outcome
# and is separated from a rotation rather than lumped with it: such a run writes
# NOTHING, so it can archive nothing, and both halves of that are checked.
CS_N_ROT=0; CS_N_REFUSED=0; CS_N_SENT=0; CS_N_BAD=0; CS_N_LEAK=0; CS_N_DRIFT=0
CS_N=1
while [ "$CS_N" -le "${CS_TOT:-0}" ]; do
  CS_NR="$WORK/cs-keep-$CS_N"
  mkdir -p "$CS_NR/build-os/memory"
  cp "$CS_LIVE" "$CS_NR/build-os/memory/current_state.md"
  sent_prereg "$WORK/cs-keep-$CS_N.prereg.json" current_state "$CS_N" "$CS_NR/build-os/memory/current_state.md"
  node "$SRC/build-os/maintenance/rotate-memory.mjs" \
       --root "$CS_NR" --file current_state --keep "$CS_N" --apply \
       --pre-registration "$WORK/cs-keep-$CS_N.prereg.json" \
       > "$WORK/cs-keep-$CS_N.out" 2>&1
  CS_N_RC=$?
  if [ "$CS_N_RC" -eq 3 ] || [ "$CS_N_RC" -eq 7 ]; then
    if [ "$CS_N_RC" -eq 3 ]; then CS_N_REFUSED=$((CS_N_REFUSED+1)); else CS_N_SENT=$((CS_N_SENT+1)); fi
    cmp -s "$CS_LIVE" "$CS_NR/build-os/memory/current_state.md" || CS_N_BAD=$((CS_N_BAD+1))
    [ -e "$CS_NR/build-os/memory/archive" ] && CS_N_BAD=$((CS_N_BAD+1))
  elif [ "$CS_N_RC" -ne 0 ]; then
    CS_N_BAD=$((CS_N_BAD+1))
  else
    CS_N_ROT=$((CS_N_ROT+1))
    for term in '**Build/test command:**' '**Last closed packet:**'; do
      grep -qF -- "$term" "$CS_NR/build-os/memory/current_state.md" || CS_N_BAD=$((CS_N_BAD+1))
      if [ -f "$CS_NR/build-os/memory/archive/current_state.archive.md" ]; then
        grep -qF -- "$term" "$CS_NR/build-os/memory/archive/current_state.archive.md" && CS_N_LEAK=$((CS_N_LEAK+1))
      fi
    done
    CS_NB1="$WORK/cs-keep-$CS_N.block1"
    cs_block1 "$CS_NR/build-os/memory/current_state.md" > "$CS_NB1"
    cmp -s "$CS_B1" "$CS_NB1" || CS_N_DRIFT=$((CS_N_DRIFT+1))
  fi
  CS_N=$((CS_N+1))
done
if [ "${CS_TOT:-0}" -le 0 ]; then
  no "the current_state keep-sweep had no block count to sweep over — the proof below is vacuous"
else
  ok "the current_state keep-sweep ran every legal N from 1 to $CS_TOT — the whole domain of the PARAMETER THAT DETERMINES ROUTING (--keep is validated >= 1 and routeSegments(segments, keepN) takes no other input), NOT the tool's whole legal domain: --max-bytes is equally user-settable and is not swept"
fi
[ $(( CS_N_ROT + CS_N_REFUSED + CS_N_SENT )) -eq "${CS_TOT:-0}" ] \
  && ok "every legal keep over current_state.md ended in one of exactly three ways: $CS_N_ROT rotated, $CS_N_REFUSED refused at the byte ceiling (exit 3), $CS_N_SENT refused by the rotation sentinel (exit 7) — and all three write nothing" \
  || no "a legal keep ended some fourth way — $CS_N_ROT rotated + $CS_N_REFUSED ceiling + $CS_N_SENT sentinel != ${CS_TOT:-0} sweeps"
# BOTH DIRECTIONS, because this file is the one the guard PERMITS: a sweep in
# which the sentinel refused everything would prove nothing about rotation, and
# one in which it refused nothing would prove nothing about the guard.
[ "$CS_N_ROT" -gt 0 ] && [ "$CS_N_SENT" -gt 0 ] \
  && ok "the current_state sweep separates in BOTH directions: $CS_N_SENT keep(s) refused by the sentinel and $CS_N_ROT permitted and executed — the guard is neither off nor total" \
  || no "the current_state sweep did not separate: $CS_N_SENT sentinel refusals and $CS_N_ROT rotations, so either the guard refuses everything or it refuses nothing"
[ "$CS_N_BAD" -eq 0 ] \
  && ok "at all $CS_N_ROT rotating keeps the live current_state.md still carries both gate-pinned literals, and every ceiling refusal wrote nothing at all" \
  || no "$CS_N_BAD failure(s): a legal --keep archived a gate-pinned literal out of the live file, or a refusal still wrote"
[ "$CS_N_LEAK" -eq 0 ] \
  && ok "at all $CS_N_ROT rotating keeps, NO gate-pinned literal of current_state.md ever reaches the archive" \
  || no "$CS_N_LEAK gate-pinned literal(s) reached the archive — the standing region is reachable by rotation after all"
[ "$CS_N_DRIFT" -eq 0 ] \
  && ok "at all $CS_N_ROT rotating keeps, current_state.md's block 1 is byte-identical to the source (the standing region is never rewritten; only the preamble gains a banner)" \
  || no "$CS_N_DRIFT keep(s) changed current_state.md's standing block's bytes"

# The live tree was only read. Proven, not asserted.
cmp -s "$CS_LIVE" "$CS_ROOT/build-os/memory/current_state.md" \
  && ok "the live current_state.md is byte-identical to the copy taken before this section ran" \
  || no "the live current_state.md changed during this section — a rotation reached the real tree"
[ -z "$(find "$SRC/build-os/memory/archive" -newer "$CS_ROOT/build-os/memory/current_state.md" 2>/dev/null)" ] \
  && ok "nothing under the real build-os/memory/archive is newer than the scratch copy taken at the top of this section, so this section wrote no archive into the real tree" \
  || no "a path under the real build-os/memory/archive is newer than this section's first write — a rotation reached the real tree"

echo "== 10. THE ROTATION SENTINEL — a keep below the derived floor is REFUSED BEFORE MUTATION =="
# WHY THIS SECTION EXISTS.
#
# Sections 8 and 9 prove a POSITIONAL fact: retention is a prefix, so block 1
# survives every legal `--keep`. They prove nothing about block 25. The first
# governed rotation of this repository was safe because a HUMAN read the
# open-item markers, found the oldest, and hand-derived `--keep 25`; residue
# `(iiiiii)` wrote that rule down as prose and said, in terms, "NOTHING ENFORCES
# THIS AND NOTHING IS BUILT HERE", and `DEFECT-0014-retention-order-assumed-not-
# verified` is the standing record of the gap. This section is the enforcement.
#
# THE RULE, EXACTLY:
#   minimum_safe_keep = max( block position of every protected or still-open object )
# and any requested `--keep` below it is refused before a byte moves.
#
# IT IS AN IDENTITY CHECK, NOT A POSITIONAL ONE, AND THE DIFFERENCE IS MEASURED
# RATHER THAN ASSERTED. In this repository's live `residue.md` the marker
# `IS NOT CONSUMED AND MUST NOT BE MARKED SO` for `(ddd)` sits in BLOCK 15 while
# `(ddd)` is DECLARED in BLOCK 16. A scan that trusts where the marker sits
# derives 15 and archives the object it was built to protect. That is this
# tree's named recurring defect class — positional shift read as semantic
# identity — and the fixture below pins the guard on the right side of it.
SENT="$SRC/build-os/maintenance/rotate-memory.mjs"
S10="$WORK/sentinel"
mkdir -p "$S10"

# ---------------------------------------------------------------- fixtures --
# EVERY fixture is generated HERE, in $WORK. The two that read this repository's
# own memory take a byte-identical scratch COPY and pass an explicit --root, so
# the live tree is only ever READ.

# (i) UNARMED: ordinary synthetic memory carrying no protected object at all.
sent_unarmed(){
  local root="$1"; mkdir -p "$root/build-os/memory"
  node -e '
const fs = require("fs");
const out = ["# Residue\n", "\n> generated fixture preamble.\n", "\n"];
for (let i = 1; i <= 30; i++) {
  out.push(`## BLOCK ${i} — heading ${i}\n`, `body ${i}: ${"y".repeat(400)}\n\n`);
}
fs.writeFileSync(process.argv[1], out.join(""));
' "$root/build-os/memory/residue.md"
}

# (ii) ARMED: a protected region at block 1, an object DECLARED in block 6 whose
#      protection marker sits in block 5, and a still-open object in block 8.
#      The correct minimum_safe_keep is 8, and a positional reading gives 5.
sent_armed(){
  local root="$1"; mkdir -p "$root/build-os/memory"
  node -e '
const fs = require("fs");
const o = [];
o.push("# Residue\n\n> generated fixture preamble.\n\n");
o.push("## Standing open items — PROTECTED REGION (block 1; rotation cannot reach it)\n\n");
o.push("- **(aaa) A STANDING ITEM.** " + "s".repeat(300) + "\n\n");
for (let i = 2; i <= 4; i++) {
  o.push(`## History — filler ${i}\n\n- **(f${i}) FILLER.** ${"f".repeat(600)}\n\n`);
}
o.push("## History — the block that MENTIONS the protected object\n\n");
o.push("- **(nnn) A CLOSED ITEM THAT CITES ANOTHER.** `(qqq)` IS NOT CONSUMED AND MUST NOT BE MARKED SO.\n");
o.push("  " + "m".repeat(600) + "\n\n");
o.push("## History — the block that DECLARES the protected object\n\n");
o.push("- **(qqq) THE NON-CONSUMABLE OBJECT ITSELF.** " + "q".repeat(600) + "\n\n");
o.push("## History — filler 7\n\n- **(f7) FILLER.** " + "f".repeat(600) + "\n\n");
o.push("## History — the oldest block still holding an open item\n\n");
o.push("- **(zzz) AN UNREPRODUCED FLAKE.** [STILL OPEN AND STILL UNDIAGNOSABLE]\n");
o.push("  " + "z".repeat(600) + "\n\n");
for (let i = 9; i <= 14; i++) {
  o.push(`## History — filler ${i}\n\n- **(g${i}) FILLER.** ${"g".repeat(600)}\n\n`);
}
fs.writeFileSync(process.argv[1], o.join(""));
' "$root/build-os/memory/residue.md"
}

# (iii) UNRESOLVABLE: a protection marker naming an identity DECLARED NOWHERE in
#       the file. The guard cannot prove which block holds that object, so it
#       cannot prove any keep protects it.
sent_unresolvable(){
  local root="$1"; mkdir -p "$root/build-os/memory"
  node -e '
const fs = require("fs");
const o = ["# Residue\n\n> generated fixture preamble.\n\n"];
o.push("## Standing open items — PROTECTED REGION (block 1; rotation cannot reach it)\n\n");
o.push("- **(aaa) A STANDING ITEM.** `DECISION-0099` STAYS OPEN and is declared in no block here.\n\n");
for (let i = 2; i <= 12; i++) {
  o.push(`## History — filler ${i}\n\n- **(h${i}) FILLER.** ${"h".repeat(600)}\n\n`);
}
fs.writeFileSync(process.argv[1], o.join(""));
' "$root/build-os/memory/residue.md"
}

# Read one field out of a --json report's sentinel block.
#
# THE INDIRECT `eval` THAT USED TO BE HERE IS GONE. It read
# `const v = (0, eval)(process.argv[2]);` — test-only, evaluating literal
# expressions written a few lines above it in this same file, so it was never a
# live hazard. It is removed rather than merely declared because removal was
# trivial: every call site wanted either a named field or the block position of
# one id, and `new Function` on a fixed template covers both without an
# arbitrary-expression evaluator. `build-os/maintenance/source-scan.mjs` reports
# exactly this shape in the maintenance tree, and a device this suite would flag
# in shipped source does not earn an exemption for sitting in a test.
sent_field(){ # <json file> <field name>
  node -e '
const fs = require("fs");
const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).results[0].sentinel;
const v = s[process.argv[2]];
process.stdout.write(v === undefined ? "" : Array.isArray(v) ? v.join(",") : String(v));
' "$1" "$2" 2>/dev/null
}

# The block position(s) a single protected identity resolved to. Separate from
# sent_field because it is a LOOKUP, not a field read — and because keeping it
# separate is what let the evaluator above be deleted.
sent_block_of(){ # <json file> <object id>
  node -e '
const fs = require("fs");
const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).results[0].sentinel;
const hits = s.protected_objects.filter((o) => o.id === process.argv[2]);
process.stdout.write(hits.map((o) => o.block_position).join(","));
' "$1" "$2" 2>/dev/null
}

# How many protected objects of a given KIND the scan resolved.
sent_kind_count(){ # <json file> <kind>
  node -e '
const fs = require("fs");
const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).results[0].sentinel;
process.stdout.write(String(s.protected_objects.filter((o) => o.kind === process.argv[2]).length));
' "$1" "$2" 2>/dev/null
}

# --------------------------------------------------- (a) arming is explicit --
U10="$S10/unarmed"; sent_unarmed "$U10"
node "$SENT" --root "$U10" --file residue --keep 10 --apply > "$S10/unarmed.out" 2>"$S10/unarmed.err"
U10RC=$?
[ "$U10RC" -eq 0 ] \
  && ok "SENTINEL: a synthetic memory file carrying NO protected object rotates exactly as before (exit 0)" \
  || no "SENTINEL: an unarmed file was refused (exit $U10RC): $(head -c 300 "$S10/unarmed.err")"
grep -q 'SENTINEL NOT ARMED' "$S10/unarmed.err" \
  && ok "SENTINEL: ...and says NOT ARMED on STDERR rather than passing silently — an unarmed guard that says nothing is the failure this repo has already paid for" \
  || no "SENTINEL: an unarmed run printed no NOT-ARMED warning, so a file with zero resolved protected objects is indistinguishable from a protected one"

# ------------------------------------- (b) THE RED-DRIVEN, OPERATOR-NAMED FIXTURE --
# `--keep 10 --apply` sat QUEUED in this tree's own residue as a pending action.
# Retention is a prefix and the live file carries 25 blocks, so it would have
# archived blocks 11..25 — including block 16 (`(ddd)`) and block 25 (`(S1)` and
# the flake). This is an executed, demonstrated failure, which is what the
# governance ceiling requires before a new refusal may exist.
RED="$S10/red"; mkdir -p "$RED/build-os/memory"
cp "$SRC/build-os/memory/residue.md" "$RED/build-os/memory/residue.md"
cmp -s "$SRC/build-os/memory/residue.md" "$RED/build-os/memory/residue.md" \
  && ok "SENTINEL: the live residue.md is copied byte-identically into a scratch root (the live tree is only READ)" \
  || no "SENTINEL: the scratch copy of residue.md is not byte-identical"
sha256sum < "$RED/build-os/memory/residue.md" > "$S10/red.before"
node "$SENT" --root "$RED" --file residue --keep 10 --apply > "$S10/red.out" 2>"$S10/red.err"
REDRC=$?
[ "$REDRC" -eq 7 ] \
  && ok "SENTINEL: THE RED-DRIVEN FIXTURE — \`--keep 10 --apply\` over this repository's live residue.md REFUSES at exit 7" \
  || no "SENTINEL: \`--keep 10 --apply\` over the live residue.md exited $REDRC, not 7 — the queued command that would archive (ddd), (S1) and the still-open flake is still permitted"
[ "$(sha256sum < "$RED/build-os/memory/residue.md")" = "$(cat "$S10/red.before")" ] \
  && ok "SENTINEL: ...and the refusal happened BEFORE MUTATION — the source file is byte-identical" \
  || no "SENTINEL: the refused run still wrote to the source file"
[ ! -e "$RED/build-os/memory/archive" ] \
  && ok "SENTINEL: ...and no archive was created, so nothing was moved anywhere" \
  || no "SENTINEL: the refused run created an archive"
grep -qE 'requested_keep +10' "$S10/red.err" && grep -qE 'minimum_safe_keep +25' "$S10/red.err" \
  && ok "SENTINEL: ...naming requested_keep 10 against minimum_safe_keep 25, so the operator is told the safe value instead of having to rediscover it" \
  || no "SENTINEL: the refusal does not name both the requested and the minimum safe keep: $(head -c 400 "$S10/red.err")"
grep -qF '(S1)' "$S10/red.err" && grep -qF '(ddd)' "$S10/red.err" \
  && ok "SENTINEL: ...and names the protected identities (ddd) and (S1) that the run would have archived" \
  || no "SENTINEL: the refusal does not name the protected identities: $(head -c 400 "$S10/red.err")"

# THE IDENTITY CLAIM, MEASURED. `(ddd)`'s marker line and `(ddd)`'s declaration
# are in DIFFERENT blocks in the live file. The guard must report the
# DECLARATION's block. Both positions are re-derived here from the live file
# rather than quoted, so this cannot pass by agreeing with a remembered digit.
DDD_MARK="$(awk '/^## /{n++} /IS NOT CONSUMED AND MUST NOT BE MARKED SO/ && /\(ddd\)/{print n}' \
             "$SRC/build-os/memory/residue.md" | sort -n | tail -1)"
DDD_DECL="$(awk '/^## /{n++} /^- \*\*\(ddd\)/{print n}' "$SRC/build-os/memory/residue.md" | sort -n | tail -1)"
if [ -n "$DDD_MARK" ] && [ -n "$DDD_DECL" ] && [ "$DDD_MARK" != "$DDD_DECL" ]; then
  ok "SENTINEL: the fixture is non-vacuous — (ddd)'s protection marker sits in block $DDD_MARK and (ddd) is DECLARED in block $DDD_DECL, so position and identity give different answers"
else
  no "SENTINEL: (ddd)'s marker block ($DDD_MARK) and declaration block ($DDD_DECL) are not distinct in the live file, so the identity-vs-position proof below would be vacuous"
fi
node "$SENT" --root "$RED" --file residue --keep 10 --sentinel-report --json > "$S10/red.json" 2>"$S10/redjson.err"
REDJRC=$?
[ "$REDJRC" -eq 0 ] \
  && ok "SENTINEL: --sentinel-report is a PURE QUERY — it reports the refusal at exit 0 instead of refusing to say what the safe value is" \
  || no "SENTINEL: --sentinel-report exited $REDJRC: $(head -c 300 "$S10/redjson.err")"
DDD_AT="$(sent_block_of "$S10/red.json" '(ddd)')"
[ "$DDD_AT" = "$DDD_DECL" ] \
  && ok "SENTINEL: (ddd) resolves to block $DDD_AT — its DECLARATION — not to block $DDD_MARK where its marker sits. IDENTITY, not position." \
  || no "SENTINEL: (ddd) resolved to block '$DDD_AT', expected the declaration block $DDD_DECL — the guard is reading position and calling it identity"
[ "$(sent_field "$S10/red.json" minimum_safe_keep)" = "25" ] \
  && ok "SENTINEL: residue.md's derived minimum_safe_keep is 25 — the same value a human hand-derived for rotation #1, now derived by the tool" \
  || no "SENTINEL: residue.md's minimum_safe_keep is $(sent_field "$S10/red.json" minimum_safe_keep), not 25"
cmp -s "$SRC/build-os/memory/residue.md" "$RED/build-os/memory/residue.md" \
  && ok "SENTINEL: --sentinel-report wrote nothing at all" || no "SENTINEL: --sentinel-report mutated the file"

# ------------------------------------------- (c) the seven required fields --
S7=0; S7MISS=""
for f in requested_keep minimum_safe_keep protected_object_ids protected_block_positions \
         blocks_to_archive bytes_to_reclaim post_rotation_headroom; do
  # PRESENT means the key exists and carries a value, not merely that reading it
  # did not throw: `sent_field` prints the empty string for an absent key, and
  # every one of these seven is non-empty on a real report.
  if [ -n "$(sent_field "$S10/red.json" "$f")" ]; then
    S7=$((S7+1))
  else
    S7MISS="$S7MISS $f"
  fi
done
[ "$S7" -eq 7 ] \
  && ok "SENTINEL: all seven required report fields are present for the proposed rotation" \
  || no "SENTINEL: only $S7 of 7 report fields are present; missing:$S7MISS"

# --------------------------- (d) the first seven refusal conditions, each fired --
# C8 arrived with cross-file resolution and is driven in section 11 (fixture D),
# beside the mechanism that creates it. The counter below stays at 7 on purpose:
# it is the count of the conditions THIS subsection drives, not of the tool's.
# Conditions 3, 4 and 6 are DELIBERATELY driven through MUTATED COPIES of the
# tool. They are cross-checks: on the shipped tool condition 1 fires first and
# they are never reached, so the only way to show they discriminate is to break
# the check that shadows them and watch these catch it. That is the same device
# section 6a and the node suite's mutation fixtures use.
SC_BAD=0; SC_FIRED=0

# C1 — requested_keep below minimum_safe_keep
A1="$S10/c1"; sent_armed "$A1"
sha256sum < "$A1/build-os/memory/residue.md" > "$S10/c1.before"
node "$SENT" --root "$A1" --file residue --keep 4 --apply > "$S10/c1.out" 2>"$S10/c1.err"
C1RC=$?
if [ "$C1RC" -eq 7 ] && grep -q 'SENTINEL-C1' "$S10/c1.err" \
   && [ "$(sha256sum < "$A1/build-os/memory/residue.md")" = "$(cat "$S10/c1.before")" ]; then
  SC_FIRED=$((SC_FIRED+1)); ok "SENTINEL C1: --keep 4 under a minimum_safe_keep of 8 REFUSES at exit 7 and writes nothing"
else
  SC_BAD=$((SC_BAD+1)); no "SENTINEL C1 did not fire (exit $C1RC): $(head -c 300 "$S10/c1.err")"
fi
# ...and the floor it enforces is the DECLARATION's block, not the marker's
A1J="$S10/c1.json"
node "$SENT" --root "$A1" --file residue --keep 4 --sentinel-report --json > "$A1J" 2>/dev/null
[ "$(sent_field "$A1J" minimum_safe_keep)" = "8" ] \
  && ok "SENTINEL C1: the fixture's minimum_safe_keep is 8 — the oldest block holding an open item — and not 5, where that object's marker sits" \
  || no "SENTINEL C1: minimum_safe_keep is $(sent_field "$A1J" minimum_safe_keep), expected 8"
[ "$(sent_block_of "$A1J" '(qqq)')" = "6" ] \
  && ok "SENTINEL C1: the non-consumable object (qqq) resolves to block 6, where it is DECLARED, though its marker sits in block 5" \
  || no "SENTINEL C1: (qqq) resolved to block $(sent_block_of "$A1J" '(qqq)'), expected 6"

# C2 — a protected identity that cannot be resolved
A2="$S10/c2"; sent_unresolvable "$A2"
sha256sum < "$A2/build-os/memory/residue.md" > "$S10/c2.before"
node "$SENT" --root "$A2" --file residue --keep 12 --apply > "$S10/c2.out" 2>"$S10/c2.err"
C2RC=$?
if [ "$C2RC" -eq 7 ] && grep -q 'SENTINEL-C2' "$S10/c2.err" && grep -q 'DECISION-0099' "$S10/c2.err" \
   && [ "$(sha256sum < "$A2/build-os/memory/residue.md")" = "$(cat "$S10/c2.before")" ]; then
  SC_FIRED=$((SC_FIRED+1)); ok "SENTINEL C2: an identity a protection marker names but no block DECLARES is a REFUSAL, not a skip — and it is named in the refusal"
else
  SC_BAD=$((SC_BAD+1)); no "SENTINEL C2 did not fire (exit $C2RC): $(head -c 300 "$S10/c2.err")"
fi

# C3 — an open object would move to the archive. Driven through a mutant whose
#      derived floor is forced to 0, so C1 cannot fire and only the independent
#      routing cross-check is left to catch it.
M3="$S10/mutant-c3.mjs"; cp "$SENT" "$M3"
perl -0pi -e 's/const sentinelFloor = derived\.minimumSafeKeep;/const sentinelFloor = 0;/' "$M3"
if grep -q 'const sentinelFloor = 0;' "$M3"; then
  ok "SENTINEL C3: the mutant was built — the derived floor is forced to 0, so condition 1 cannot fire"
else
  no "SENTINEL C3: the mutant could not be built, so this differential is vacuous"
fi
A3="$S10/c3"; sent_armed "$A3"
sha256sum < "$A3/build-os/memory/residue.md" > "$S10/c3.before"
# A MATCHING PRE-REGISTRATION, so C3 is the ONLY condition left standing. Without
# one, C5 fires alongside it and the exit code stops discriminating: only the
# `grep -q SENTINEL-C3` half would be load-bearing, and a fixture whose exit code
# proves nothing is half a fixture. C4, C6 and C7 already isolate this way.
sent_prereg "$S10/c3.json" residue 4 "$A3/build-os/memory/residue.md"
node "$M3" --root "$A3" --file residue --keep 4 --apply \
     --pre-registration "$S10/c3.json" > "$S10/c3.out" 2>"$S10/c3.err"
C3RC=$?
# ISOLATION, ASSERTED RATHER THAN ASSUMED: C3 must be the only code in the
# refusal. If another condition creeps back in, the fixture has stopped being
# about C3 and this says so instead of passing on the grep alone.
C3_CODES="$(grep -oE 'SENTINEL-C[0-9]' "$S10/c3.err" | sort -u | tr '\n' ' ')"
[ "$(echo "$C3_CODES" | tr -d ' ')" = "SENTINEL-C3" ] \
  && ok "SENTINEL C3: the refusal names C3 and NOTHING ELSE — the fixture isolates the condition it is for" \
  || no "SENTINEL C3: the refusal names [$C3_CODES], so the exit code is not evidence about C3 alone"
if [ "$C3RC" -eq 7 ] && grep -q 'SENTINEL-C3' "$S10/c3.err" \
   && [ "$(sha256sum < "$A3/build-os/memory/residue.md")" = "$(cat "$S10/c3.before")" ]; then
  SC_FIRED=$((SC_FIRED+1)); ok "SENTINEL C3: with the floor suppressed, the independent routing check still refuses — an open object landing in the archive is caught by a second instrument"
else
  SC_BAD=$((SC_BAD+1)); no "SENTINEL C3 did not fire (exit $C3RC): $(head -c 300 "$S10/c3.err")"
fi

# C4 — the block map and the live file disagree
M4="$S10/mutant-c4.mjs"; cp "$SENT" "$M4"
perl -0pi -e 's/const crossMap = sentinelBlockMap\(original, spec\);/const crossMap = sentinelBlockMap(original, spec).slice(1);/' "$M4"
if grep -q 'sentinelBlockMap(original, spec).slice(1)' "$M4"; then
  ok "SENTINEL C4: the mutant was built — the independently-derived block map is made to disagree with the file by one block"
else
  no "SENTINEL C4: the mutant could not be built, so this differential is vacuous"
fi
A4="$S10/c4"; sent_armed "$A4"
sha256sum < "$A4/build-os/memory/residue.md" > "$S10/c4.before"
sent_prereg "$S10/c4.json" residue 10 "$A4/build-os/memory/residue.md"
node "$M4" --root "$A4" --file residue --keep 10 --apply \
     --pre-registration "$S10/c4.json" > "$S10/c4.out" 2>"$S10/c4.err"
C4RC=$?
if [ "$C4RC" -eq 7 ] && grep -q 'SENTINEL-C4' "$S10/c4.err" \
   && [ "$(sha256sum < "$A4/build-os/memory/residue.md")" = "$(cat "$S10/c4.before")" ]; then
  SC_FIRED=$((SC_FIRED+1)); ok "SENTINEL C4: a block map that disagrees with the live file REFUSES — the guard never plans against a map it has not re-derived"
else
  SC_BAD=$((SC_BAD+1)); no "SENTINEL C4 did not fire (exit $C4RC): $(head -c 300 "$S10/c4.err")"
fi

# C5 — the apply was not pre-registered
A5="$S10/c5"; sent_armed "$A5"
sha256sum < "$A5/build-os/memory/residue.md" > "$S10/c5.before"
node "$SENT" --root "$A5" --file residue --keep 8 --apply > "$S10/c5.out" 2>"$S10/c5.err"
C5RC=$?
if [ "$C5RC" -eq 7 ] && grep -q 'SENTINEL-C5' "$S10/c5.err" \
   && [ "$(sha256sum < "$A5/build-os/memory/residue.md")" = "$(cat "$S10/c5.before")" ]; then
  SC_FIRED=$((SC_FIRED+1)); ok "SENTINEL C5: an --apply at a SAFE keep still REFUSES when it was never pre-registered — ordering stops being builder testimony"
else
  SC_BAD=$((SC_BAD+1)); no "SENTINEL C5 did not fire (exit $C5RC): $(head -c 300 "$S10/c5.err")"
fi
# ...and a pre-registration that does not MATCH is no better than none
sent_prereg "$S10/c5.wrongkeep.json" residue 9 "$A5/build-os/memory/residue.md"
node "$SENT" --root "$A5" --file residue --keep 8 --apply \
     --pre-registration "$S10/c5.wrongkeep.json" > "$S10/c5b.out" 2>"$S10/c5b.err"
C5BRC=$?
[ "$C5BRC" -eq 7 ] && grep -q 'SENTINEL-C5' "$S10/c5b.err" \
  && ok "SENTINEL C5: a pre-registration naming a DIFFERENT keep is refused — the record must bind the run, not merely exist" \
  || no "SENTINEL C5: a mismatched pre-registration was accepted (exit $C5BRC)"
# ...and one taken against DIFFERENT SOURCE BYTES is refused, which is what makes
#    the record an ordering anchor rather than a rubber stamp
sent_prereg "$S10/c5.stale.json" residue 8 "$A5/build-os/memory/residue.md"
printf '\n## History — a block appended AFTER the registration\n\nlate.\n' >> "$A5/build-os/memory/residue.md"
node "$SENT" --root "$A5" --file residue --keep 8 --apply \
     --pre-registration "$S10/c5.stale.json" > "$S10/c5c.out" 2>"$S10/c5c.err"
C5CRC=$?
[ "$C5CRC" -eq 7 ] && grep -q 'SENTINEL-C5' "$S10/c5c.err" \
  && ok "SENTINEL C5: a pre-registration whose source sha256 no longer matches the file is refused — the registration is bound to the exact bytes it was taken over" \
  || no "SENTINEL C5: a stale pre-registration was accepted (exit $C5CRC)"

# C6 — deterministic restoration cannot be proved
M6="$S10/mutant-c6.mjs"; cp "$SENT" "$M6"
perl -0pi -e 's/const restorationSource = contentText \+ archivedText;/const restorationSource = contentText;/' "$M6"
if grep -q 'const restorationSource = contentText;' "$M6"; then
  ok "SENTINEL C6: the mutant was built — the restoration source is made to drop the archived half"
else
  no "SENTINEL C6: the mutant could not be built, so this differential is vacuous"
fi
A6="$S10/c6"; sent_armed "$A6"
sha256sum < "$A6/build-os/memory/residue.md" > "$S10/c6.before"
sent_prereg "$S10/c6.json" residue 8 "$A6/build-os/memory/residue.md"
node "$M6" --root "$A6" --file residue --keep 8 --apply \
     --pre-registration "$S10/c6.json" > "$S10/c6.out" 2>"$S10/c6.err"
C6RC=$?
if [ "$C6RC" -eq 7 ] && grep -q 'SENTINEL-C6' "$S10/c6.err" \
   && [ "$(sha256sum < "$A6/build-os/memory/residue.md")" = "$(cat "$S10/c6.before")" ]; then
  SC_FIRED=$((SC_FIRED+1)); ok "SENTINEL C6: a rotation whose retained-plus-archived bytes do not reconstruct the source REFUSES — restoration is proved before the move, not after"
else
  SC_BAD=$((SC_BAD+1)); no "SENTINEL C6 did not fire (exit $C6RC): $(head -c 300 "$S10/c6.err")"
fi

# C7 — the projected result cannot absorb the packet's own close
A7="$S10/c7"; sent_armed "$A7"
sha256sum < "$A7/build-os/memory/residue.md" > "$S10/c7.before"
sent_prereg "$S10/c7.json" residue 8 "$A7/build-os/memory/residue.md"
A7SIZE="$(wc -c < "$A7/build-os/memory/residue.md")"
node "$SENT" --root "$A7" --file residue --keep 8 --apply --max-bytes "$A7SIZE" \
     --close-budget "$A7SIZE" --pre-registration "$S10/c7.json" > "$S10/c7.out" 2>"$S10/c7.err"
C7RC=$?
if [ "$C7RC" -eq 7 ] && grep -q 'SENTINEL-C7' "$S10/c7.err" \
   && [ "$(sha256sum < "$A7/build-os/memory/residue.md")" = "$(cat "$S10/c7.before")" ]; then
  SC_FIRED=$((SC_FIRED+1)); ok "SENTINEL C7: a rotation whose projected headroom cannot cover the close budget REFUSES — the file is not allowed to be rotated into a state its own close will breach"
else
  SC_BAD=$((SC_BAD+1)); no "SENTINEL C7 did not fire (exit $C7RC): $(head -c 300 "$S10/c7.err")"
fi
[ "$SC_FIRED" -eq 7 ] && [ "$SC_BAD" -eq 0 ] \
  && ok "SENTINEL: ALL SEVEN refusal conditions are driven by a fixture that fires them, and every one of the seven wrote nothing" \
  || no "SENTINEL: $SC_FIRED of 7 conditions fired and $SC_BAD failed — a refusal condition with no fixture that fires it is a claim, not a guard"

# ---------------- (d2) THE TWO INVARIANTS NOTHING ASSERTED ON — M5 AND M4 --------
# WHY THESE EXIST, AND THEY ARE NOT SPECULATIVE. Two mutants of this tool were
# built and executed against the whole 2179-check suite, and each killed EXACTLY
# ZERO tests:
#
#   M5  `const hasStandingRegion = objects.some(o => o.kind === "protected-region")`
#       -> `const hasStandingRegion = false`, which disarms SENTINEL_GATE_PINS
#       entirely. Observable and unasserted: on this repository's residue.md the
#       resolved-object count falls 22 -> 19 and the gate pins 3 -> 0; on
#       current_state.md 5 -> 3 and 2 -> 0. (The object counts previously read
#       18 -> 15 and 4 -> 2. RE-DERIVED rather than adjusted: both were ALREADY
#       stale at `74575ee`, measured by running this same mutant against that
#       commit's own memory files, so the drift predates the cross-file packet
#       and was not caused by rotation #3. The GATE-PIN figures — the ones the
#       assertions below actually read — were exact then and are exact now.)
#       Sections 8 and 9 grep the pinned
#       LITERALS out of the files directly and never route through the sentinel,
#       so no assertion anywhere noticed. The rotation-#2 receipt meanwhile
#       claims those pins were "verified BY IDENTITY" — an unenforced claim in a
#       receipt is exactly the shape this repository keeps paying for.
#
#   M4  the declaration index preferring the SHALLOWEST declaration instead of
#       the DEEPEST (`declaredAt.get(id).block < at` -> `> at`). Retention is a
#       prefix, so the deepest declaration is the safe anchor and the shallowest
#       strands every later copy. It is inert only because no marker on this tree
#       currently names a doubly-declared id — `DEFECT-0013` already IS declared
#       in two blocks of active_packet.md, so the condition is one marker away.
#
# Both are driven here on generated fixtures, at the level the sentinel reports
# rather than at the level of a literal grep, which is the whole point: an
# assertion that greps the literal cannot tell whether the SENTINEL protected it.
M5="$S10/mutant-m5.mjs"; cp "$SENT" "$M5"
perl -0pi -e 's/const hasStandingRegion = objects\.some\(\(o\) => o\.kind === "protected-region"\);/const hasStandingRegion = false;/' "$M5"
grep -q 'const hasStandingRegion = false;' "$M5" \
  && ok "SENTINEL M5: the mutant was built — SENTINEL_GATE_PINS is disarmed and nothing else changed" \
  || no "SENTINEL M5: the mutant could not be built, so this differential is vacuous"

# The pins are read off THIS repository's live current_state.md, on a scratch
# copy: they are the literals `tests/release_metadata_tests.sh` section 5 reads
# with `head -n1`, so the file that actually has them is the honest fixture.
M5R="$S10/m5-root"; mkdir -p "$M5R/build-os/memory"
cp "$CS_LIVE" "$M5R/build-os/memory/current_state.md"
node "$SENT" --root "$M5R" --file current_state --keep 10 --sentinel-report --json \
     > "$S10/m5.shipped.json" 2>/dev/null
node "$M5"   --root "$M5R" --file current_state --keep 10 --sentinel-report --json \
     > "$S10/m5.mutant.json" 2>/dev/null
M5_SHIPPED="$(sent_kind_count "$S10/m5.shipped.json" gate-pin)"
M5_MUTANT="$(sent_kind_count "$S10/m5.mutant.json" gate-pin)"
# DIRECTION 1 — the shipped tool resolves BOTH pins, as protected objects, by kind.
[ "${M5_SHIPPED:-0}" -eq 2 ] \
  && ok "SENTINEL: the sentinel itself resolves both of current_state.md's gate-pinned literals as protected objects (kind gate-pin), so the receipt's \"verified BY IDENTITY\" claim is now enforced by an assertion rather than asserted in prose" \
  || no "SENTINEL: the sentinel resolved ${M5_SHIPPED:-0} gate-pin object(s) in current_state.md, expected 2 — the pins are not protected by the guard at all"
# ...and each resolves to the block that actually holds its FIRST occurrence,
# derived here from the file rather than remembered.
M5_PIN_BLK_OK=0
for t in '**Build/test command:**' '**Last closed packet:**'; do
  EXPECT="$(awk -v t="$t" '/^## /{n++} index($0,t){print n; exit}' "$M5R/build-os/memory/current_state.md")"
  GOT="$(sent_block_of "$S10/m5.shipped.json" "GATE-PIN:$t")"
  [ -n "$EXPECT" ] && [ "$GOT" = "$EXPECT" ] || M5_PIN_BLK_OK=$((M5_PIN_BLK_OK+1))
done
[ "$M5_PIN_BLK_OK" -eq 0 ] \
  && ok "SENTINEL: each gate pin resolves to the block holding its FIRST occurrence — the occurrence a head -n1 reader would find — re-derived from the file, not remembered" \
  || no "SENTINEL: $M5_PIN_BLK_OK gate pin(s) resolved to a block that does not hold their first occurrence"
# DIRECTION 2 — THE KILL. Disarming the pins must be visible.
[ "${M5_MUTANT:-9}" -eq 0 ] && [ "${M5_SHIPPED:-0}" -ne "${M5_MUTANT:-9}" ] \
  && ok "SENTINEL M5 KILLED: disarming SENTINEL_GATE_PINS drops the resolved gate-pin objects from ${M5_SHIPPED} to ${M5_MUTANT}, and this assertion is what now sees it — before this check the same mutant killed 0 of 2179 tests" \
  || no "SENTINEL M5 SURVIVES: shipped resolved ${M5_SHIPPED:-?} gate-pin object(s) and the disarmed mutant ${M5_MUTANT:-?} — the invariant is still unenforced"

M4="$S10/mutant-m4.mjs"; cp "$SENT" "$M4"
perl -0pi -e 's/if \(at >= 1 && \(!declaredAt\.has\(id\) \|\| declaredAt\.get\(id\)\.block < at\)\) \{/if (at >= 1 \&\& (!declaredAt.has(id) || declaredAt.get(id).block > at)) {/' "$M4"
grep -q 'declaredAt.get(id).block > at' "$M4" \
  && ok "SENTINEL M4: the mutant was built — the declaration index prefers the SHALLOWEST declaration instead of the deepest" \
  || no "SENTINEL M4: the mutant could not be built, so this differential is vacuous"

# A fixture carrying a DOUBLY-DECLARED id that a marker names: `(www)` is
# declared in block 3 AND again in block 9, and the marker in block 2 names it.
# Deepest-wins resolves to 9 and the floor is 9; shallowest-wins resolves to 3
# and the floor collapses to 3, stranding the block-9 copy in the archive.
M4R="$S10/m4-root"; mkdir -p "$M4R/build-os/memory"
node -e '
const fs = require("fs");
const o = ["# Residue\n\n> generated fixture preamble.\n\n"];
o.push("## Standing open items — PROTECTED REGION (block 1; rotation cannot reach it)\n\n");
o.push("- **(aaa) A STANDING ITEM.** " + "s".repeat(200) + "\n\n");
o.push("## History — the block that NAMES the doubly-declared object\n\n");
o.push("- **(nnn) CITES ANOTHER OBJECT.** `(www)` IS NOT CONSUMED AND MUST NOT BE MARKED SO.\n");
o.push("  " + "m".repeat(400) + "\n\n");
o.push("## History — the SHALLOW declaration of (www)\n\n");
o.push("- **(www) FIRST DECLARATION.** " + "w".repeat(400) + "\n\n");
for (let i = 4; i <= 8; i++) o.push(`## History — filler ${i}\n\n- **(k${i}) FILLER.** ${"k".repeat(400)}\n\n`);
o.push("## History — the DEEP declaration of (www)\n\n");
o.push("- **(www) SECOND DECLARATION, and the one retention must reach.** " + "W".repeat(400) + "\n\n");
for (let i = 10; i <= 12; i++) o.push(`## History — filler ${i}\n\n- **(j${i}) FILLER.** ${"j".repeat(400)}\n\n`);
fs.writeFileSync(process.argv[1], o.join(""));
' "$M4R/build-os/memory/residue.md"
M4_DECL_N="$(grep -c '^- \*\*(www)' "$M4R/build-os/memory/residue.md")"
[ "$M4_DECL_N" -eq 2 ] \
  && ok "SENTINEL M4: the fixture is non-vacuous — (www) is DECLARED twice, in two different blocks, and a marker names it (the condition DEFECT-0013 already satisfies in active_packet.md)" \
  || no "SENTINEL M4: the fixture declares (www) $M4_DECL_N time(s), so the deepest-vs-shallowest choice cannot be observed"
node "$SENT" --root "$M4R" --file residue --keep 5 --sentinel-report --json > "$S10/m4.shipped.json" 2>/dev/null
node "$M4"   --root "$M4R" --file residue --keep 5 --sentinel-report --json > "$S10/m4.mutant.json" 2>/dev/null
M4_S_BLK="$(sent_block_of "$S10/m4.shipped.json" '(www)')"
M4_M_BLK="$(sent_block_of "$S10/m4.mutant.json" '(www)')"
M4_S_FLOOR="$(sent_field "$S10/m4.shipped.json" minimum_safe_keep)"
M4_M_FLOOR="$(sent_field "$S10/m4.mutant.json" minimum_safe_keep)"
# DIRECTION 1 — the shipped tool takes the DEEPEST declaration.
[ "$M4_S_BLK" = "9" ] && [ "$M4_S_FLOOR" = "9" ] \
  && ok "SENTINEL: a doubly-declared identity resolves to its DEEPEST declaration (block 9, floor 9) — retention is a prefix, so the deepest anchor is the only one that retains every copy" \
  || no "SENTINEL: (www) resolved to block '$M4_S_BLK' with floor '$M4_S_FLOOR', expected 9 and 9"
# DIRECTION 2 — THE KILL.
{ [ "$M4_M_BLK" = "3" ] || [ "$M4_M_FLOOR" != "$M4_S_FLOOR" ]; } \
  && ok "SENTINEL M4 KILLED: preferring the shallowest declaration moves (www) to block '$M4_M_BLK' and the floor to '$M4_M_FLOOR', stranding the deeper copy in the archive — before this check the same mutant killed 0 of 2179 tests" \
  || no "SENTINEL M4 SURVIVES: the mutant resolved (www) to block '$M4_M_BLK' with floor '$M4_M_FLOOR', indistinguishable from the shipped tool"
# ...and the consequence is executed, not merely computed: at the mutant's own
# floor the deep declaration really does leave the live file.
M4A="$S10/m4-apply"; mkdir -p "$M4A/build-os/memory"
cp "$M4R/build-os/memory/residue.md" "$M4A/build-os/memory/residue.md"
sent_prereg "$S10/m4.prereg.json" residue 3 "$M4A/build-os/memory/residue.md"
node "$M4" --root "$M4A" --file residue --keep 3 --apply \
     --pre-registration "$S10/m4.prereg.json" > "$S10/m4.apply.out" 2>"$S10/m4.apply.err"
M4_RC=$?
if [ "$M4_RC" -eq 0 ] && [ -f "$M4A/build-os/memory/archive/residue.archive.md" ] \
   && grep -qF -- '- **(www) SECOND DECLARATION' "$M4A/build-os/memory/archive/residue.archive.md"; then
  ok "SENTINEL M4: the harm is EXECUTED, not argued — under the mutant, --keep 3 exits 0 and (www)'s deeper declaration is found in the archive"
else
  no "SENTINEL M4: the mutant's --keep 3 did not reproduce the harm (exit $M4_RC), so the kill above is not tied to a demonstrated loss"
fi
# ...and the SHIPPED tool refuses that same command.
M4B="$S10/m4-shipped-apply"; mkdir -p "$M4B/build-os/memory"
cp "$M4R/build-os/memory/residue.md" "$M4B/build-os/memory/residue.md"
sent_prereg "$S10/m4b.prereg.json" residue 3 "$M4B/build-os/memory/residue.md"
node "$SENT" --root "$M4B" --file residue --keep 3 --apply \
     --pre-registration "$S10/m4b.prereg.json" > "$S10/m4b.out" 2>"$S10/m4b.err"
M4B_RC=$?
[ "$M4B_RC" -eq 7 ] && [ ! -e "$M4B/build-os/memory/archive" ] \
  && ok "SENTINEL M4: ...and the SHIPPED tool refuses that identical command at exit 7, writing nothing — the differential is the deepest-declaration rule and nothing else" \
  || no "SENTINEL M4: the shipped tool exited $M4B_RC on the command the mutant executed; the two arms do not separate"

# ------------------------------------ (e) THE POSITIVE CONTROL: a governed apply --
# A guard that only ever refuses proves nothing about the rotation it is supposed
# to permit. The same fixture, at a keep the guard allows, with a matching
# pre-registration, must ROTATE — and the protected objects must still be live
# afterwards, checked BY IDENTITY.
A8="$S10/ok"; sent_armed "$A8"
cp "$A8/build-os/memory/residue.md" "$S10/ok.source"
sent_prereg "$S10/ok.json" residue 8 "$A8/build-os/memory/residue.md"
node "$SENT" --root "$A8" --file residue --keep 8 --apply \
     --pre-registration "$S10/ok.json" --json > "$S10/ok.json.out" 2>"$S10/ok.err"
OKRC=$?
[ "$OKRC" -eq 0 ] \
  && ok "SENTINEL: at the derived floor, with a matching pre-registration, the SAME fixture rotates (exit 0) — the guard permits as well as refuses" \
  || no "SENTINEL: the governed apply was refused (exit $OKRC): $(head -c 300 "$S10/ok.err")"
SOK_LIVE=0
for id in '(aaa)' '(qqq)' '(zzz)'; do
  grep -qF -- "- **$id" "$A8/build-os/memory/residue.md" || SOK_LIVE=$((SOK_LIVE+1))
done
[ "$SOK_LIVE" -eq 0 ] \
  && ok "SENTINEL: after the permitted rotation all three protected objects are still LIVE, matched by their DECLARATION not by a substring anywhere in the file" \
  || no "SENTINEL: $SOK_LIVE protected object declaration(s) left the live file"
SOK_LEAK=0
if [ -f "$A8/build-os/memory/archive/residue.archive.md" ]; then
  for id in '(aaa)' '(qqq)' '(zzz)'; do
    grep -qF -- "- **$id" "$A8/build-os/memory/archive/residue.archive.md" && SOK_LEAK=$((SOK_LEAK+1))
  done
fi
[ "$SOK_LEAK" -eq 0 ] \
  && ok "SENTINEL: ...and none of them reached the archive" \
  || no "SENTINEL: $SOK_LEAK protected object declaration(s) reached the archive"
# byte-exact round trip, reconstructed from the two outputs on disk
node -e '
const fs = require("fs"), path = require("path");
const [orig, root] = process.argv.slice(1);
const L = (p) => fs.readFileSync(p).toString("latin1");
const original = L(orig);
const live = L(path.join(root, "build-os/memory/residue.md"));
const archive = L(path.join(root, "build-os/memory/archive/residue.archive.md"));
const S = "<!-- rotate-memory:archive-pointer:start -->";
const E = "<!-- rotate-memory:archive-pointer:end -->\n\n";
const a = live.indexOf(S);
if (a < 0) throw new Error("no banner in the rotated file");
const b = live.indexOf(E, a) + E.length;
const hdr = archive.lastIndexOf("## ARCHIVED BATCH ");
const bodyAt = archive.indexOf("\n\n", hdr) + 2;
const rebuilt = live.slice(0, a) + live.slice(b) + archive.slice(bodyAt);
if (!rebuilt.startsWith(original)) {
  let i = 0; while (i < original.length && rebuilt[i] === original[i]) i++;
  throw new Error("NOT byte-exact: first divergence at byte " + i);
}
' "$S10/ok.source" "$A8" 2>"$S10/ok.cons.err" \
  && ok "SENTINEL: ...and the permitted rotation is still byte-exact — live-minus-banner ++ archive reconstructs the source" \
  || no "SENTINEL: the permitted rotation lost bytes: $(cat "$S10/ok.cons.err")"

# ------------------------------- (f) the live tree was only ever read here --
cmp -s "$SRC/build-os/memory/residue.md" "$RED/build-os/memory/residue.md" \
  && ok "SENTINEL: this repository's live residue.md is byte-identical to the copy taken at the top of this section" \
  || no "SENTINEL: the live residue.md changed during section 10"

echo "== 11. CROSS-FILE IDENTITY RESOLUTION — identity is resolved across the GOVERNED MEMORY SET =="
# WHY THIS SECTION EXISTS.
#
# `SENTINEL-C2` treated EVERY sibling-file reference as UNRESOLVED, because
# resolution was SINGLE-FILE SCOPED and said so: "an object that legitimately
# LIVES ELSEWHERE and is merely CITED here is indistinguishable, to this scan,
# from an object that has gone missing. Both refuse." C2 is keep-independent, so
# no `--keep` clears it. That is why `build-os/packets/active_packet.md` refused
# at every legal keep while nothing was wrong with the record.
#
# THE GOAL IS NOT TO WEAKEN C2. It is to make C2 resolve identity across the
# governed memory set instead of treating a sibling-file reference as
# unresolvable. Five outcomes are distinguished, and each is driven here:
#
#   DECLARATION          a live object declared in a governed memory file
#   LIVE_REFERENCE       a reference to a live object declared elsewhere
#   QUOTED_REFERENCE     a token inside a code span, a quotation, a fence or a
#                        blockquote — structure, never vocabulary
#   HISTORICAL_REFERENCE a token inside an `## ARCHIVED BATCH` block — a copy,
#                        never an owner
#   UNRESOLVED           a marker names an identity no governed file declares
#
# THE MECHANISM IS STRUCTURAL, NOT A WORD LIST, and the reason is executed
# history: `PACKET-0042`'s live-vs-quoted guard keyed on six withdrawal-marker
# words on the same line, and probes found a live assertion on a line containing
# `no longer` passing GREEN (fail-open) while a reworded cap was invisible
# entirely. Nothing below reads vocabulary. It reads fence state, blockquote
# depth, inline-code-span and quotation spans, the declaration FORM, and the
# block heading the tool itself writes.
GOV="$WORK/gov"
mkdir -p "$GOV"

# A GOVERNED MULTI-FILE ROOT. residue.md DECLARES `(qqq)`; active_packet.md only
# CITES it. Every variant below is a one-flag change to this same generator, so
# the differentials are about the flag and nothing else.
#
#   dup        — current_state.md ALSO declares (qqq) canonically (fixture D)
#   missing    — the marker names DECISION-0099, declared nowhere (fixture E)
#   archived   — the second declaration sits in an `## ARCHIVED BATCH` block (F)
#   unquoted   — active_packet's citing marker is written BARE, not quoted (B/2)
#   shifted    — filler LINES are inserted inside existing blocks (property 8)
#   orphan     — residue DECLARES (qqq) and protects it NOWHERE, while
#                active_packet quotes a live rule about it. THE ADVERSARIAL CASE.
#   inbound    — the same unprotected residue, cited by a BARE live marker, so
#                the inbound protection is the only thing that can raise a floor
#
# NOTE ON `plain`: residue carries a NON-QUOTED marker of its own naming
# `(qqq)`. That is not decoration — it is the precondition that makes quoting the
# same rule in another file REDUNDANT, and therefore safe to demote. Without it
# this fixture is the `orphan` case, and demoting there archives a live object.
# The two are kept as separate roots so the difference is executable.
gov_root(){ # <root> <flag>
  local root="$1" flag="${2:-plain}"
  mkdir -p "$root/build-os/memory" "$root/build-os/packets"
  node -e '
const fs = require("fs");
const [resP, csP, apP, flag] = process.argv.slice(1);
const pad = (c, n) => c.repeat(n);

/* ---- residue.md: the OWNER of (qqq) and of (zzz) ---- */
const r = ["# Residue\n\n> generated fixture preamble.\n\n"];
r.push("## Standing open items — PROTECTED REGION (block 1; rotation cannot reach it)\n\n");
r.push("- **(aaa) A STANDING ITEM.** " + pad("s", 200) + "\n\n");
for (let i = 2; i <= 5; i++) {
  r.push(`## History — filler ${i}\n\n- **(f${i}) FILLER.** ${pad("f", 400)}\n\n`);
  if (flag === "shifted") r.push(pad("x", 80) + "\n" + pad("x", 80) + "\n\n");
}
/* (qqq) IS PROTECTED AT HOME in every root EXCEPT the two that exist to show
   what happens when it is not. `orphan` and `inbound` omit this marker. */
const ORPHANED = flag === "orphan" || flag === "inbound";
if (!ORPHANED) {
  r.push("- **(nnn) A CLOSED ITEM THAT CITES ANOTHER.** `(qqq)` IS NOT CONSUMED AND MUST NOT BE MARKED SO.\n\n");
}
r.push("## History — the block that DECLARES (qqq)\n\n");
r.push("- **(qqq) THE NON-CONSUMABLE OBJECT ITSELF.** " + pad("q", 400) + "\n\n");
for (let i = 7; i <= 9; i++) r.push(`## History — filler ${i}\n\n- **(g${i}) FILLER.** ${pad("g", 400)}\n\n`);
if (!ORPHANED) {
  r.push("## History — the oldest block still holding an open item\n\n");
  r.push("- **(zzz) AN UNREPRODUCED FLAKE.** [STILL OPEN AND STILL UNDIAGNOSABLE]\n");
  r.push("  " + pad("z", 400) + "\n\n");
  for (let i = 11; i <= 14; i++) r.push(`## History — filler ${i}\n\n- **(h${i}) FILLER.** ${pad("h", 400)}\n\n`);
}
fs.writeFileSync(resP, r.join(""));

/* ---- current_state.md ---- */
const c = ["# Current state\n\n> generated fixture preamble.\n\n"];
c.push("## Standing truth — PROTECTED REGION\n\n");
c.push("- **Build/test command:** `bash tests/build_os_tests.sh`\n");
c.push("- **Last closed packet:** none\n\n");
if (flag === "dup") {
  c.push("## A SECOND CANONICAL DECLARATION OF THE SAME IDENTITY\n\n");
  c.push("- **(qqq) A RIVAL DECLARATION IN ANOTHER GOVERNED FILE.** " + pad("d", 200) + "\n\n");
} else if (flag === "archived") {
  c.push("## ARCHIVED BATCH 1970-01-01T00:00:00Z — build-os/memory/residue.md — 1 blocks (block_1..block_1)\n\n");
  c.push("- **(qqq) AN ARCHIVED COPY OF THE DECLARATION.** " + pad("a", 200) + "\n\n");
}
for (let i = 2; i <= 6; i++) c.push(`## History — cs filler ${i}\n\n- **(c${i}) FILLER.** ${pad("c", 300)}\n\n`);
fs.writeFileSync(csP, c.join(""));

/* ---- active_packet.md: it CITES (qqq); it declares nothing ---- */
const named = flag === "missing" ? "`DECISION-0099`" : "`(qqq)`";
const a = ["# Active Packet\n\n> generated fixture preamble.\n\n"];
a.push("## ACTIVE — a packet that CITES an object it does not own\n\n");
a.push("- **(p1) THE PACKET ITEM.** " + pad("p", 200) + "\n\n");
for (let i = 2; i <= 4; i++) a.push(`## History — ap filler ${i}\n\n- **(a${i}) FILLER.** ${pad("a", 300)}\n\n`);
a.push("## The block that CITES the sibling-declared object\n\n");
if (flag === "unquoted" || flag === "inbound") {
  /* BARE marker: not in a code span, not in a quotation, not fenced. */
  a.push(`- **(p5) A LIVE ASSERTION.** ${named} IS NOT CONSUMED AND MUST NOT BE MARKED SO.\n`);
} else if (flag === "orphan") {
  /* A PLAIN MARKDOWN BLOCKQUOTE stating a standing rule — the most conventional
     way anyone writes one, and one of the three forms that were measured
     archiving a live object at exit 0 before the demotion was corrected. */
  a.push(`> ${named} IS NOT CONSUMED AND MUST NOT BE MARKED SO — standing, this cycle.\n`);
} else {
  /* QUOTED marker: the marker phrase sits inside a quotation AND a code span. */
  a.push(`- **(p5) A NARRATIVE ABOUT A PAST FIXTURE.** it would have archived ${named}, marked "IS NOT CONSUMED AND MUST NOT BE MARKED SO", at exit 0.\n`);
}
a.push("  " + pad("n", 300) + "\n\n");
for (let i = 6; i <= 8; i++) a.push(`## History — ap filler ${i}\n\n- **(b${i}) FILLER.** ${pad("b", 300)}\n\n`);
fs.writeFileSync(apP, a.join(""));
' "$root/build-os/memory/residue.md" "$root/build-os/memory/current_state.md" \
  "$root/build-os/packets/active_packet.md" "$flag"
}

# Read a sentinel field out of a --json report for a NAMED file (the reports
# above all read results[0]; this section plans one file at a time too, but it
# names the file explicitly so a future multi-file run cannot silently re-point
# these assertions at the wrong result.)
gov_report(){ # <root> <file> <keep> <out.json>
  node "$SENT" --root "$1" --file "$2" --keep "$3" --sentinel-report --json > "$4" 2>/dev/null
}
gov_json(){ # <json> <expr-field>
  node -e '
const fs = require("fs");
const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).results[0].sentinel;
const v = s[process.argv[2]];
process.stdout.write(v === undefined ? "" : Array.isArray(v) ? String(v.length) : String(v));
' "$1" "$2" 2>/dev/null
}
# One cross-file resolution rendered as "id@file:block", so the assertion names
# WHERE the declaration was found and not merely that something was found.
gov_cross(){ # <json> <id>
  node -e '
const fs = require("fs");
const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).results[0].sentinel;
const hit = (s.cross_file_resolutions ?? []).filter((c) => c.id === process.argv[2]);
process.stdout.write(hit.map((c) => `${c.id}@${c.declared_in}:${c.declared_block}`).join(","));
' "$1" "$2" 2>/dev/null
}
gov_codes(){ # <stderr file>
  grep -oE 'SENTINEL-C[0-9]' "$1" 2>/dev/null | sort -u | tr '\n' ' ' | sed 's/ $//'
}

# ---- (a) FIXTURE A — a sibling-declared identity RESOLVES, in both directions --
GA="$GOV/a"; gov_root "$GA" plain
# DIRECTION 1 (the RED this section was written for): with the sibling files
# REMOVED from the root, the same file, the same bytes, the same keep must still
# refuse at C2 — because then there really is nowhere the object could live.
GA1="$GOV/a-alone"; mkdir -p "$GA1/build-os/packets"
cp "$GA/build-os/packets/active_packet.md" "$GA1/build-os/packets/active_packet.md"
node "$SENT" --root "$GA1" --file active_packet --keep 8 --apply > "$GOV/a1.out" 2>"$GOV/a1.err"
GA1RC=$?
[ "$GA1RC" -eq 7 ] && grep -q 'SENTINEL-C2' "$GOV/a1.err" \
  && ok "XFILE A: with the sibling governed files ABSENT, a marker naming (qqq) is still UNRESOLVED and still refuses at C2 — cross-file resolution did not weaken the condition, it gave it somewhere to look" \
  || no "XFILE A: the same citation with no sibling files exited $GA1RC without C2 — C2 has been weakened rather than widened: $(gov_codes "$GOV/a1.err")"
# DIRECTION 2: with the governed set present, the identity resolves to the file
# and block that DECLARE it, and C2 does not fire.
gov_report "$GA" active_packet 8 "$GOV/a2.json"
GA_EXPECT_BLK="$(awk '/^## /{n++} /^- \*\*\(qqq\)/{print n; exit}' "$GA/build-os/memory/residue.md")"
[ "$(gov_cross "$GOV/a2.json" '(qqq)')" = "(qqq)@residue:$GA_EXPECT_BLK" ] \
  && ok "XFILE A: (qqq) cited in active_packet.md resolves to its canonical declaration in residue.md block $GA_EXPECT_BLK — re-derived from the fixture, not remembered" \
  || no "XFILE A: (qqq) resolved to '$(gov_cross "$GOV/a2.json" '(qqq)')', expected (qqq)@residue:$GA_EXPECT_BLK"
[ "$(gov_json "$GOV/a2.json" unresolvable_identities)" = "0" ] \
  && ok "XFILE A: ...and active_packet.md now carries ZERO unresolvable identities, so the permanent C2 refusal that no --keep could clear is gone" \
  || no "XFILE A: active_packet.md still reports $(gov_json "$GOV/a2.json" unresolvable_identities) unresolvable identity/identities"

# ---- (b) FIXTURE B — a QUOTED marker does not raise the floor, both directions --
# The two fixtures differ in ONE thing: whether the marker phrase sits inside a
# quotation and a code span. Nothing else moves, so the floor delta is caused by
# the structural fact and by nothing else.
GB="$GOV/b-quoted";   gov_root "$GB" plain
GBU="$GOV/b-unquoted"; gov_root "$GBU" unquoted
gov_report "$GB"  active_packet 8 "$GOV/b.json"
gov_report "$GBU" active_packet 8 "$GOV/bu.json"
GB_FLOOR="$(gov_json "$GOV/b.json" minimum_safe_keep)"
GBU_FLOOR="$(gov_json "$GOV/bu.json" minimum_safe_keep)"
GB_CITE_BLK="$(awk '/^## /{n++} /\(p5\)/{print n; exit}' "$GB/build-os/packets/active_packet.md")"
[ -n "$GB_CITE_BLK" ] && [ "$GBU_FLOOR" = "$GB_CITE_BLK" ] \
  && ok "XFILE B: the BARE marker raises active_packet.md's floor to block $GBU_FLOOR, the block it is written in — the guard still protects a live assertion it cannot attribute elsewhere" \
  || no "XFILE B: the bare marker gave floor '$GBU_FLOOR', expected the citing block '$GB_CITE_BLK' — direction 2 of this differential is dead"
[ -n "$GB_FLOOR" ] && [ "$GB_FLOOR" -lt "$GBU_FLOOR" ] \
  && ok "XFILE B: quoting the SAME marker drops the floor from $GBU_FLOOR to $GB_FLOOR — a block that merely QUOTES \`(qqq)\` and its marker no longer raises the floor solely because it contains the text" \
  || no "XFILE B: the quoted and bare forms both give floor '$GB_FLOOR'/'$GBU_FLOOR' — the quotation is not being read structurally"
[ "$(gov_json "$GOV/b.json" quoted_references)" != "0" ] && [ -n "$(gov_json "$GOV/b.json" quoted_references)" ] \
  && ok "XFILE B: ...and the demotion is REPORTED as a quoted reference rather than silently dropped — $(gov_json "$GOV/b.json" quoted_references) of them" \
  || no "XFILE B: the quoted marker was dropped without being reported; a demotion nobody can see is a hole, not a fix"

# ---- (c) FIXTURE C — the REAL live declaration still raises the floor ----------
# The object is referenced in active_packet.md and DECLARED in residue.md. Two
# things are asserted, and the second is the one cross-file resolution ADDS:
#
#   1. residue.md's own floor is unchanged — the still-open (zzz) it declares
#      itself still sets it. Cross-file resolution lowered a FALSE refusal in
#      another file and did not lower this one below a live declaration.
#   2. A LIVE (unquoted) reference in a SIBLING file now PROTECTS the declaring
#      block in the owning file. Under the single-file scan that reference
#      produced a C2 refusal on the citing file and NO protection at all here,
#      so this is strictly more protection than before, not less.
gov_report "$GB"  residue 14 "$GOV/c.json"
gov_report "$GBU" residue 14 "$GOV/cu.json"
GC_ZZZ="$(awk '/^## /{n++} /^- \*\*\(zzz\)/{print n; exit}' "$GB/build-os/memory/residue.md")"
GC_OK=0
for j in "$GOV/c.json" "$GOV/cu.json"; do
  [ "$(gov_json "$j" minimum_safe_keep)" = "$GC_ZZZ" ] || GC_OK=$((GC_OK+1))
done
[ "$GC_OK" -eq 0 ] \
  && ok "XFILE C: residue.md's floor is $GC_ZZZ in BOTH the quoted and the unquoted root — the block that DECLARES the still-open (zzz). Cross-file resolution never lowers the floor below a live declaration" \
  || no "XFILE C: residue.md's floor is $(gov_json "$GOV/c.json" minimum_safe_keep)/$(gov_json "$GOV/cu.json" minimum_safe_keep), expected $GC_ZZZ in both — a live declaration lost its protection"
# DIRECTION 1 — a LIVE sibling reference propagates protection INBOUND.
[ "$(sent_block_of "$GOV/cu.json" '(qqq)')" = "$GA_EXPECT_BLK" ] \
  && ok "XFILE C: a LIVE marker in active_packet.md naming (qqq) protects block $GA_EXPECT_BLK of residue.md, the file that DECLARES it — protection follows the object across files, which is the whole point of resolving identity rather than position" \
  || no "XFILE C: a live sibling reference put (qqq) at block '$(sent_block_of "$GOV/cu.json" '(qqq)')' in its owning file, expected $GA_EXPECT_BLK"
# DIRECTION 2 — RESTATED, because the first wording asserted the symmetry in
# terms that read as endorsing the unsafe case. The symmetry is real and is kept:
# a quotation contributes NO CROSS-FILE protection, in either direction. What it
# must NOT be read as saying is that the object ends up unprotected — it does not,
# and if it would, the demotion no longer happens at all (see the adversarial
# drive below). So the assertion is now about the PROVENANCE of the protection,
# which is the thing that is actually guaranteed: in the quoted root (qqq) is
# still protected in residue.md, and NOT by anything the quoting file said.
gov_cross_prov(){ # <json> <id> -> the resolution strings that protected <id>
  node -e '
const fs = require("fs");
const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).results[0].sentinel;
process.stdout.write(s.protected_objects.filter((o) => o.id === process.argv[2])
  .map((o) => (String(o.resolution).startsWith("cross-file") ? "cross-file" : "own-file")).sort().join(","));
' "$1" "$2" 2>/dev/null
}
case "$(gov_cross_prov "$GOV/c.json" '(qqq)')" in
  *own-file*) ok "XFILE C: ...and in the QUOTED root (qqq) is STILL PROTECTED in residue.md at block $(sent_block_of "$GOV/c.json" '(qqq)') — from residue.md's own marker. The demotion is symmetric, and what it guarantees is that the quotation added nothing, NOT that the object was left unprotected" ;;
  *)          no "XFILE C: in the quoted root (qqq)'s protection provenance is '$(gov_cross_prov "$GOV/c.json" '(qqq)')' — the object is not protected in its owning file at all" ;;
esac
# The differential is taken on the CITING side, where the two forms are actually
# distinguishable: a protected object resolved to the same id/kind/block from
# two directions is ONE record by construction (`add` dedupes on that key), so
# the owning file cannot show the difference. The classification can.
gov_cross_class(){ # <json> <id>
  node -e '
const fs = require("fs");
const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).results[0].sentinel;
process.stdout.write([...new Set((s.cross_file_resolutions ?? [])
  .filter((c) => c.id === process.argv[2]).map((c) => c.classification))].sort().join(","));
' "$1" "$2" 2>/dev/null
}
[ "$(gov_cross_class "$GOV/b.json" '(qqq)')" = "QUOTED_REFERENCE" ] \
  && [ "$(gov_cross_class "$GOV/bu.json" '(qqq)')" = "LIVE_REFERENCE" ] \
  && ok "XFILE C: ...and the two roots separate on the CLASSIFICATION of the same identity — QUOTED_REFERENCE where the rule is quoted, LIVE_REFERENCE where it is asserted — so the quotation is what the tool is reading and nothing else" \
  || no "XFILE C: classifications are '$(gov_cross_class "$GOV/b.json" '(qqq)')' quoted / '$(gov_cross_class "$GOV/bu.json" '(qqq)')' unquoted, expected QUOTED_REFERENCE / LIVE_REFERENCE"
# ...and the INBOUND-ONLY proof, where own-file protection cannot be the answer,
# is section (c3) below: residue.md's floor moves 1 -> 6 on the sibling alone.

# ---- (c2) THE ADVERSARIAL CASE — a quoted LIVE rule about an object that is
#          protected NOWHERE ELSE must NOT be demoted -------------------------
# THIS IS A RED DRIVE FOR A DEFECT THAT SHIPPED AND WAS EXECUTED. The demotion
# was first conditioned on every named identity being DECLARED in another
# governed file. A declaration is not a marker: `inboundProtections` skips quoted
# markers too, so a quoted live rule protected the object in NEITHER file. Four
# ordinary prose forms of a genuinely live rule were run to completion with a
# valid pre-registration and each ARCHIVED a live, canonically declared,
# marked-non-consumable object at exit 0. The base tool refused all four at
# exit 7.
#
# THE CONDITION IS NOW `demotableElsewhere`: declared in exactly one other
# governed file AND independently protected there by a NON-QUOTED marker — which
# is exactly when the inbound protection fires. Both sides read the same
# `markerNamingsIn` scan, so the two cannot drift apart.
#
# ALL FOUR FORMS ARE DRIVEN, not one representative. The third is a plain
# markdown blockquote, which is how a standing rule is most conventionally
# written and is the form that makes this a real hazard rather than a curiosity.
gov_orphan_root(){ # <root> <citation line>
  local root="$1" cite="$2"
  gov_root "$root" orphan
  CITE="$cite" node -e '
const fs = require("fs");
const p = process.argv[1];
const t = fs.readFileSync(p, "utf8");
const from = "> `(qqq)` IS NOT CONSUMED AND MUST NOT BE MARKED SO — standing, this cycle.";
if (t.indexOf(from) < 0) { process.stderr.write("orphan citation line not found\n"); process.exit(1); }
fs.writeFileSync(p, t.replace(from, process.env.CITE));
' "$root/build-os/packets/active_packet.md"
}
ORPH_BAD=0; ORPH_N=0
ORPH_CITE_BLK=""
while IFS= read -r cite; do
  [ -n "$cite" ] || continue
  ORPH_N=$((ORPH_N+1))
  GO="$GOV/orphan-$ORPH_N"
  gov_orphan_root "$GO" "$cite" || { ORPH_BAD=$((ORPH_BAD+1)); continue; }
  [ -n "$ORPH_CITE_BLK" ] || ORPH_CITE_BLK="$(awk '/^## /{n++} /\(qqq\)/{print n; exit}' "$GO/build-os/packets/active_packet.md")"
  gov_report "$GO" active_packet 8 "$GOV/orphan-$ORPH_N.json"
  OF="$(gov_json "$GOV/orphan-$ORPH_N.json" minimum_safe_keep)"
  # ...and RUN IT TO COMPLETION at a keep below the citing block, with a VALID
  # pre-registration, so nothing but the demotion is left standing between the
  # command and the archive.
  sent_prereg "$GOV/orphan-$ORPH_N.prereg.json" active_packet 1 "$GO/build-os/packets/active_packet.md"
  node "$SENT" --root "$GO" --file active_packet --keep 1 --apply \
       --pre-registration "$GOV/orphan-$ORPH_N.prereg.json" > "$GOV/orphan-$ORPH_N.out" 2>"$GOV/orphan-$ORPH_N.err"
  ORC=$?
  LEAKED=no
  if [ -f "$GO/build-os/memory/archive/active_packet.archive.md" ]; then
    grep -qF -- '(qqq)' "$GO/build-os/memory/archive/active_packet.archive.md" && LEAKED=yes
  fi
  if [ "${OF:-0}" != "${ORPH_CITE_BLK:-x}" ] || [ "$ORC" -ne 7 ] || [ "$LEAKED" = "yes" ]; then
    ORPH_BAD=$((ORPH_BAD+1))
    no "XFILE ADVERSARIAL form $ORPH_N: floor '$OF' (expected $ORPH_CITE_BLK), apply exited $ORC (expected 7), rule reached the archive: $LEAKED -- form: $cite"
  fi
done <<'FORMS'
  The operator ruled that `(qqq)` "IS NOT CONSUMED AND MUST NOT BE MARKED SO" for this cycle.
  Gate on `(qqq)`: `MUST NOT BE ARCHIVED` until cleared.
  > `(qqq)` IS NOT CONSUMED AND MUST NOT BE MARKED SO — standing, this cycle.
  it would have archived `(qqq)`, marked "IS NOT CONSUMED AND MUST NOT BE MARKED SO", at exit 0.
FORMS
[ "$ORPH_N" -eq 4 ] \
  && ok "XFILE ADVERSARIAL: all 4 quoted-live-rule forms were built and driven (a quotation-and-code-span form, a bare-code-span form, a plain markdown BLOCKQUOTE, and a narrative form)" \
  || no "XFILE ADVERSARIAL: only $ORPH_N of 4 forms were driven, so the sweep is not the sweep it claims to be"
[ "$ORPH_BAD" -eq 0 ] \
  && ok "XFILE ADVERSARIAL: every one of the 4 forms keeps the floor at block $ORPH_CITE_BLK, REFUSES the apply at exit 7, and leaves the live rule out of the archive -- an object DECLARED elsewhere but PROTECTED nowhere is never demoted" \
  || no "XFILE ADVERSARIAL: $ORPH_BAD of $ORPH_N form(s) still fail open"
# ...and the SAFE shape is still demoted, so the fix narrowed the demotion rather
# than deleting it. Same quotation, same identity, the one difference being that
# the owning file independently protects the object.
[ "$(gov_json "$GOV/b.json" quoted_references)" != "0" ] && [ "$(gov_json "$GOV/b.json" minimum_safe_keep)" = "0" ] \
  && ok "XFILE ADVERSARIAL: ...while the SAFE shape (same quotation, owner independently protects the object) is still demoted to floor 0 -- the demotion was narrowed, not removed" \
  || no "XFILE ADVERSARIAL: the safe shape stopped demoting (floor $(gov_json "$GOV/b.json" minimum_safe_keep), $(gov_json "$GOV/b.json" quoted_references) quoted ref(s)) -- the fix deleted the feature instead of bounding it"

# ---- (c3) C2'S WIDENING STILL HOLDS — the inbound floor moves 1 -> 6 ----------
# The load-bearing half of cross-file resolution, in its own root so the number
# is unambiguous: residue.md declares (qqq) at block 6 and protects NOTHING
# itself, so ALONE its floor is 1 (the standing-region heading). Add the sibling
# that asserts the rule and the floor must become 6.
GI="$GOV/inbound"; gov_root "$GI" inbound
GI_ALONE="$GOV/inbound-alone"; mkdir -p "$GI_ALONE/build-os/memory"
cp "$GI/build-os/memory/residue.md" "$GI_ALONE/build-os/memory/residue.md"
gov_report "$GI_ALONE" residue 9 "$GOV/i-alone.json"
gov_report "$GI"       residue 9 "$GOV/i-with.json"
GI_DECL="$(awk '/^## /{n++} /^- \*\*\(qqq\)/{print n; exit}' "$GI/build-os/memory/residue.md")"
[ "$(gov_json "$GOV/i-alone.json" minimum_safe_keep)" = "1" ] \
  && ok "XFILE C2-WIDENING: residue.md ALONE derives a floor of 1 — it declares (qqq) and asserts nothing about it, so only its standing region protects anything" \
  || no "XFILE C2-WIDENING: residue.md alone derives floor $(gov_json "$GOV/i-alone.json" minimum_safe_keep), expected 1 — the baseline of this differential is wrong"
[ "$(gov_json "$GOV/i-with.json" minimum_safe_keep)" = "$GI_DECL" ] \
  && ok "XFILE C2-WIDENING: adding the sibling that ASSERTS the rule moves residue.md's floor 1 -> $GI_DECL, the block that DECLARES (qqq) — this is the protection the single-file scan gave to neither file" \
  || no "XFILE C2-WIDENING: with the sibling present residue.md's floor is $(gov_json "$GOV/i-with.json" minimum_safe_keep), expected $GI_DECL"

# ---- (d) FIXTURE D — two canonical declarations REFUSE -------------------------
GD="$GOV/d"; gov_root "$GD" dup
sha256sum < "$GD/build-os/packets/active_packet.md" > "$GOV/d.before"
node "$SENT" --root "$GD" --file active_packet --keep 8 --apply > "$GOV/d.out" 2>"$GOV/d.err"
GDRC=$?
if [ "$GDRC" -eq 7 ] && grep -q 'SENTINEL-C8' "$GOV/d.err" \
   && [ "$(sha256sum < "$GD/build-os/packets/active_packet.md")" = "$(cat "$GOV/d.before")" ]; then
  ok "XFILE D: an identity with TWO canonical declarations in two governed files REFUSES at C8, before mutation — ambiguous ownership is not resolved by picking one"
else
  no "XFILE D: a doubly-owned identity exited $GDRC with codes [$(gov_codes "$GOV/d.err")] — ambiguity was resolved silently"
fi
grep -qF '(qqq)' "$GOV/d.err" && grep -qF 'current_state' "$GOV/d.err" && grep -qF 'residue' "$GOV/d.err" \
  && ok "XFILE D: ...and the refusal names the identity and BOTH files that claim it, so the operator can act without re-deriving the conflict" \
  || no "XFILE D: the C8 refusal does not name the identity and both claimants: $(head -c 300 "$GOV/d.err")"

# ---- (e) FIXTURE E — a missing declaration still REFUSES ----------------------
GE="$GOV/e"; gov_root "$GE" missing
sha256sum < "$GE/build-os/packets/active_packet.md" > "$GOV/e.before"
node "$SENT" --root "$GE" --file active_packet --keep 8 --apply > "$GOV/e.out" 2>"$GOV/e.err"
GERC=$?
if [ "$GERC" -eq 7 ] && grep -q 'SENTINEL-C2' "$GOV/e.err" && grep -q 'DECISION-0099' "$GOV/e.err" \
   && [ "$(sha256sum < "$GE/build-os/packets/active_packet.md")" = "$(cat "$GOV/e.before")" ]; then
  ok "XFILE E: a governed live reference whose declaration is absent from EVERY governed file still refuses at C2 and is named — the widened search did not turn a refusal into a skip"
else
  no "XFILE E: a missing declaration exited $GERC with codes [$(gov_codes "$GOV/e.err")]"
fi

# ---- (f) FIXTURE F — an ARCHIVED copy never takes canonical ownership ---------
GF="$GOV/f"; gov_root "$GF" archived
gov_report "$GF" active_packet 8 "$GOV/f.json"
GF_ARCH_N="$(grep -c '^## ARCHIVED BATCH ' "$GF/build-os/memory/current_state.md")"
[ "${GF_ARCH_N:-0}" -eq 1 ] \
  && ok "XFILE F: the fixture is non-vacuous — current_state.md carries an \`## ARCHIVED BATCH\` block holding a byte-plausible copy of (qqq)'s declaration" \
  || no "XFILE F: the fixture has $GF_ARCH_N archived batch block(s), so nothing below is about an archived copy"
[ "$(gov_cross "$GOV/f.json" '(qqq)')" = "(qqq)@residue:$GA_EXPECT_BLK" ] \
  && ok "XFILE F: (qqq) still resolves to residue.md block $GA_EXPECT_BLK — the archived copy did NOT take canonical ownership, and did NOT make the identity ambiguous either" \
  || no "XFILE F: (qqq) resolved to '$(gov_cross "$GOV/f.json" '(qqq)')' — an archived copy is competing for ownership"
node "$SENT" --root "$GF" --file active_packet --keep 8 --sentinel-report > "$GOV/f.txt" 2>&1
grep -q 'SENTINEL-C8' "$GOV/f.txt" \
  && no "XFILE F: the archived copy raised the duplicate-ownership refusal — a historical copy is being counted as a declaration" \
  || ok "XFILE F: ...and C8 does not fire on it, which is the difference between a COPY and a rival OWNER"

# ---- (f2) EVERY MEMBER OF THE FIVE-WAY ENUM IS ACTUALLY EMITTED --------------
# A spec that claims five classes while the code emits three is a spec nobody can
# rely on, and it is exactly the shape this file keeps deleting elsewhere: a
# declaration that reads as coverage. `DECLARATION` and `HISTORICAL_REFERENCE`
# were defined and assigned NOWHERE. Both are now emitted; this check is what
# stops either from going inert again.
#
# HISTORICAL_REFERENCE IS DESCRIPTIVE, NOT A SECOND DEMOTION. A marker inside an
# `## ARCHIVED BATCH` block is LABELLED and still anchors exactly as before —
# adding a second predicate that can lower a floor is the thing the fix round
# exists to avoid. The DECLARATION half of the same rule is enforced rather than
# labelled: `declarationsIn` refuses to index an archived declaration at all.
GOV_ENUM="$(RM_MJS="$SENT" node -e '
import("file://" + process.env.RM_MJS).then((m) => {
  process.stdout.write(Object.keys(m.IDENTITY_CLASS).sort().join(","));
}).catch(() => process.stdout.write(""));
' 2>/dev/null)"
# every class observed across the roots this section already built
gov_classes_seen(){
  node -e '
const fs = require("fs");
const seen = new Set();
for (const f of process.argv.slice(1)) {
  let s; try { s = JSON.parse(fs.readFileSync(f, "utf8")).results[0].sentinel; } catch { continue; }
  for (const k of ["cross_file_resolutions", "quoted_references", "historical_references",
                   "unresolvable_identities"]) {
    for (const r of s[k] ?? []) if (r.classification) seen.add(r.classification);
  }
  for (const o of s.protected_objects ?? []) if (o.classification) seen.add(o.classification);
}
process.stdout.write([...seen].sort().join(","));
' "$@" 2>/dev/null
}
# FIXTURE F's root is the one that carries an archived block; report it as text
# too so the human-readable rendering of the class is exercised, not only --json.
gov_report "$GF" current_state 6 "$GOV/f-cs.json"
gov_report "$GE" active_packet 8 "$GOV/e.json"
GOV_SEEN="$(gov_classes_seen "$GOV/a2.json" "$GOV/b.json" "$GOV/bu.json" "$GOV/c.json" "$GOV/cu.json" \
                             "$GOV/e.json" "$GOV/f.json" "$GOV/f-cs.json" "$GOV/i-with.json")"
[ -n "$GOV_ENUM" ] && [ "$GOV_ENUM" = "$GOV_SEEN" ] \
  && ok "XFILE ENUM: every one of the ${GOV_ENUM} classes the tool DECLARES is also EMITTED by it, observed across nine executed reports — the spec claims exactly what the code produces" \
  || no "XFILE ENUM: the tool declares [$GOV_ENUM] but only emits [$GOV_SEEN] — a class that is never assigned is a spec claim with no code behind it"
node "$SENT" --root "$GF" --file current_state --keep 6 --sentinel-report > "$GOV/f-cs.txt" 2>&1
grep -q 'HISTORICAL_REFERENCE' "$GOV/f-cs.txt" \
  && ok "XFILE ENUM: ...and the archived copy is named as a HISTORICAL_REFERENCE in the human report, so a reader sees the copy was CLASSIFIED rather than merely absent" \
  || no "XFILE ENUM: the human report never names HISTORICAL_REFERENCE for a file carrying an archived batch block"
GF_CS_FLOOR="$(gov_json "$GOV/f-cs.json" minimum_safe_keep)"
[ -n "$GF_CS_FLOOR" ] && [ "$GF_CS_FLOOR" -ge 1 ] \
  && ok "XFILE ENUM: ...and labelling it changed no floor — current_state.md's floor is $GF_CS_FLOOR, still set by its standing region, because HISTORICAL_REFERENCE never demotes" \
  || no "XFILE ENUM: labelling the archived block moved the floor to '$GF_CS_FLOOR' — the label acquired an effect it must not have"

# ---- (g) PROPERTY 7 — STABLE IDS, NOT LINE NUMBERS, DETERMINE IDENTITY --------
# The declaration is moved to a different LINE inside the same block. Identity
# resolution must not move with it.
GG="$GOV/g"; gov_root "$GG" plain
perl -0pi -e 's/(## History — the block that DECLARES \(qqq\)\n\n)/$1<!-- an inserted line that moves every line number below it -->\n<!-- and a second one -->\n\n/' \
  "$GG/build-os/memory/residue.md"
GG_MOVED="$(awk '/^- \*\*\(qqq\)/{print FNR; exit}' "$GG/build-os/memory/residue.md")"
GG_ORIG="$(awk '/^- \*\*\(qqq\)/{print FNR; exit}' "$GA/build-os/memory/residue.md")"
[ -n "$GG_MOVED" ] && [ "$GG_MOVED" != "$GG_ORIG" ] \
  && ok "XFILE 7: the fixture is non-vacuous — (qqq)'s declaration moved from line $GG_ORIG to line $GG_MOVED inside the same block" \
  || no "XFILE 7: the declaration did not move ($GG_ORIG -> $GG_MOVED), so the line-independence claim below is vacuous"
gov_report "$GG" active_packet 8 "$GOV/g.json"
[ "$(gov_cross "$GOV/g.json" '(qqq)')" = "(qqq)@residue:$GA_EXPECT_BLK" ] \
  && ok "XFILE 7: (qqq) still resolves to residue block $GA_EXPECT_BLK after its declaration moved by $(( GG_MOVED - GG_ORIG )) line(s) — the STABLE ID determines identity, never the line" \
  || no "XFILE 7: moving the declaration by lines changed the resolution to '$(gov_cross "$GOV/g.json" '(qqq)')'"

# ---- (h) PROPERTY 8 — THE FLOOR IS INVARIANT UNDER UNRELATED LINE MOVEMENT ----
GH="$GOV/h"; gov_root "$GH" shifted
gov_report "$GH" residue 14 "$GOV/h.json"
GH_BYTES="$(wc -c < "$GH/build-os/memory/residue.md")"
GA_BYTES="$(wc -c < "$GA/build-os/memory/residue.md")"
[ "$GH_BYTES" -ne "$GA_BYTES" ] \
  && ok "XFILE 8: the fixture is non-vacuous — unrelated filler lines moved residue.md from $GA_BYTES B to $GH_BYTES B without adding or removing a block" \
  || no "XFILE 8: the shifted fixture is byte-identical to the plain one, so the invariance claim below is vacuous"
[ "$(grep -c '^## ' "$GH/build-os/memory/residue.md")" = "$(grep -c '^## ' "$GA/build-os/memory/residue.md")" ] \
  && ok "XFILE 8: ...and the block COUNT is unchanged, so the two roots are comparable" \
  || no "XFILE 8: the filler changed the block count; the comparison below would be measuring a re-block"
[ "$(gov_json "$GOV/h.json" minimum_safe_keep)" = "$(gov_json "$GOV/c.json" minimum_safe_keep)" ] \
  && ok "XFILE 8: residue.md's safe floor is $(gov_json "$GOV/h.json" minimum_safe_keep) in BOTH roots — the floor is invariant under line movement that does not move an object between blocks" \
  || no "XFILE 8: the floor moved from $(gov_json "$GOV/c.json" minimum_safe_keep) to $(gov_json "$GOV/h.json" minimum_safe_keep) on filler lines alone"

# ---- (i) THE GOVERNED IDENTITY SET IS DECLARED, AND ITS ONE WITHHELD MEMBER ----
# `standing_gates.md` is in the SET and is NOT READ, and the reason is a pinned
# contract rather than an oversight: `build-os/maintenance/rotate-memory.test.mjs`
# asserts the exact phrase "never reads, writes or creates" in the tool, in the
# wrapper and in `--help` output. Reading it would falsify a customer-visible
# claim while every one of those assertions stayed green — the precise shape this
# tree keeps paying for. So the boundary is DECLARED in the tool and reported,
# not taken silently.
# THE PATH GOES THROUGH THE ENVIRONMENT, NOT THROUGH `argv`, and that is not
# style. `rotate-memory.mjs` ends with a `process.argv[1]`-based main-module
# guard, so passing its own path as the first argument of `node -e` makes the
# import RUN THE CLI and exit — the read would then report the tool's stdout
# instead of the tool's exports, and the assertion would be measuring the wrong
# thing while looking like it worked.
GOV_SET="$(RM_MJS="$SENT" node -e '
import("file://" + process.env.RM_MJS).then((m) => {
  process.stdout.write(m.GOVERNED_IDENTITY_SET.map((g) => `${g.path}:${g.read ? "read" : "withheld"}`).join(" "));
}).catch(() => process.stdout.write(""));
' 2>/dev/null)"
[ "$GOV_SET" = "build-os/memory/residue.md:read build-os/memory/current_state.md:read build-os/packets/active_packet.md:read build-os/memory/standing_gates.md:withheld" ] \
  && ok "XFILE SET: the governed identity set is declared in the tool as exactly the four memory files, with standing_gates.md marked WITHHELD — the resolver's read scope is auditable from the source, not from a builder's word" \
  || no "XFILE SET: the declared governed identity set is [$GOV_SET]"
node "$SENT" --root "$GA" --file active_packet --keep 8 --sentinel-report > "$GOV/set.txt" 2>&1
grep -q 'standing_gates.md' "$GOV/set.txt" \
  && ok "XFILE SET: ...and the withheld member is named in the report, so a reader of a resolution can see what was NOT consulted" \
  || no "XFILE SET: the report never names the withheld member; an unread governed file that nobody is told about is a silent scope hole"
grep -qF 'never reads, writes or creates' "$SENT" \
  && ok "XFILE SET: ...and the tool's own pinned no-read claim about standing_gates.md is still TRUE of the shipped resolver, which is why it may still be written" \
  || no "XFILE SET: the pinned no-read claim has been removed from the tool"

# ---- (j) PROPERTY 10 — this repository's live residue.md, honestly ------------
# Rotatable, or refused with the reason named. Both are legitimate outcomes and
# the assertion refuses to prefer one: what it forbids is silence.
GJ="$GOV/live-residue"; mkdir -p "$GJ/build-os/memory" "$GJ/build-os/packets"
cp "$SRC/build-os/memory/residue.md"        "$GJ/build-os/memory/residue.md"
cp "$SRC/build-os/memory/current_state.md"  "$GJ/build-os/memory/current_state.md"
cp "$SRC/build-os/packets/active_packet.md" "$GJ/build-os/packets/active_packet.md"
GJ_TOT="$(grep -c '^## ' "$GJ/build-os/memory/residue.md")"
gov_report "$GJ" residue "$GJ_TOT" "$GOV/j.json"
GJ_FLOOR="$(gov_json "$GOV/j.json" minimum_safe_keep)"
GJ_VERDICT="$(gov_json "$GOV/j.json" verdict)"
if [ "$GJ_FLOOR" = "$GJ_TOT" ]; then
  ok "XFILE 10: with the WHOLE governed set present, residue.md's floor is $GJ_FLOOR of $GJ_TOT blocks — it is NOT rotatable, and cross-file resolution did not and could not change that: the floor is set by objects DECLARED in its own last block. Verdict $GJ_VERDICT, reported rather than worked around"
elif [ -n "$GJ_FLOOR" ] && [ "$GJ_FLOOR" -lt "$GJ_TOT" ]; then
  ok "XFILE 10: with the whole governed set present, residue.md's floor is $GJ_FLOOR of $GJ_TOT blocks, so $(( GJ_TOT - GJ_FLOOR )) block(s) became legally reclaimable. Verdict $GJ_VERDICT"
else
  no "XFILE 10: residue.md's floor could not be derived against the full governed set (floor '$GJ_FLOOR', blocks '$GJ_TOT')"
fi
# ...and the live tree was only read.
cmp -s "$SRC/build-os/memory/residue.md" "$GJ/build-os/memory/residue.md" \
  && cmp -s "$SRC/build-os/memory/current_state.md" "$GJ/build-os/memory/current_state.md" \
  && cmp -s "$SRC/build-os/packets/active_packet.md" "$GJ/build-os/packets/active_packet.md" \
  && ok "XFILE: all three live governed files are byte-identical to the copies taken at the top of section 11 — this section only READ the real tree" \
  || no "XFILE: a live governed file changed during section 11"

# ---- (k) PROPERTIES 11 + 12 — no protected object leaks, restoration is exact --
# The positive control, run against a MULTI-FILE governed root so the cross-file
# resolver is live for it. A guard that only refuses proves nothing about the
# rotation it is meant to permit.
GK="$GOV/k"; gov_root "$GK" plain
cp "$GK/build-os/packets/active_packet.md" "$GOV/k.source"
GK_FLOOR="$(gov_json "$GOV/b.json" minimum_safe_keep)"
[ -n "$GK_FLOOR" ] && [ "$GK_FLOOR" -ge 1 ] || GK_FLOOR=1
sent_prereg "$GOV/k.prereg.json" active_packet "$GK_FLOOR" "$GK/build-os/packets/active_packet.md"
node "$SENT" --root "$GK" --file active_packet --keep "$GK_FLOOR" --apply \
     --pre-registration "$GOV/k.prereg.json" > "$GOV/k.out" 2>"$GOV/k.err"
GKRC=$?
[ "$GKRC" -eq 0 ] \
  && ok "XFILE 11: at the cross-file-derived floor $GK_FLOOR, with a matching pre-registration, active_packet.md ROTATES (exit 0) — the file that could NEVER rotate under the single-file scan now can" \
  || no "XFILE 11: the governed apply was refused (exit $GKRC): $(head -c 400 "$GOV/k.err")"
GK_LEAK=0
if [ -f "$GK/build-os/memory/archive/active_packet.archive.md" ]; then
  grep -qF -- '- **(p1)' "$GK/build-os/memory/archive/active_packet.archive.md" && GK_LEAK=$((GK_LEAK+1))
fi
grep -qF -- '- **(p1)' "$GK/build-os/packets/active_packet.md" || GK_LEAK=$((GK_LEAK+1))
[ "$GK_LEAK" -eq 0 ] \
  && ok "XFILE 11: ...and no protected object leaked into the archive — the retained prefix still carries every one of them, matched by DECLARATION" \
  || no "XFILE 11: $GK_LEAK protected-object leak(s) across the cut"
node -e '
const fs = require("fs"), path = require("path");
const [orig, root] = process.argv.slice(1);
const L = (p) => fs.readFileSync(p).toString("latin1");
const original = L(orig);
const live = L(path.join(root, "build-os/packets/active_packet.md"));
const archive = L(path.join(root, "build-os/memory/archive/active_packet.archive.md"));
const S = "<!-- rotate-memory:archive-pointer:start -->";
const E = "<!-- rotate-memory:archive-pointer:end -->\n\n";
const a = live.indexOf(S);
if (a < 0) throw new Error("no banner in the rotated file");
const b = live.indexOf(E, a) + E.length;
const hdr = archive.lastIndexOf("## ARCHIVED BATCH ");
const bodyAt = archive.indexOf("\n\n", hdr) + 2;
const rebuilt = live.slice(0, a) + live.slice(b) + archive.slice(bodyAt);
if (!rebuilt.startsWith(original)) {
  let i = 0; while (i < original.length && rebuilt[i] === original[i]) i++;
  throw new Error("NOT byte-exact: first divergence at byte " + i);
}
' "$GOV/k.source" "$GK" 2>"$GOV/k.cons.err" \
  && ok "XFILE 12: ...and restoration is still BYTE-EXACT — live-minus-banner ++ archive reconstructs the source of the cross-file-permitted rotation" \
  || no "XFILE 12: the cross-file-permitted rotation lost bytes: $(cat "$GOV/k.cons.err")"

echo ""
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
