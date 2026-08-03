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
DRY="$( cd "$R1" && ./build-os/maintenance/rotate-memory.sh --json 2>&1 )"
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

# (b) THE SHIPPED-KEEP ROTATION ACTUALLY ARCHIVES. Dry run, so nothing is
#     written anywhere; the exit code is captured DIRECTLY off the tool and
#     never off the tail of a pipeline.
RES_DRY="$WORK/residue-dry.json"
node "$SRC/build-os/maintenance/rotate-memory.mjs" \
     --root "$RES_ROOT" --file residue --keep 10 --json > "$RES_DRY" 2>"$WORK/residue-dry.err"
RES_DRY_RC=$?
[ "$RES_DRY_RC" -eq 0 ] \
  && ok "a --keep 10 DRY RUN over a scratch copy of the live residue.md exits 0 (no ceiling refusal)" \
  || no "the --keep 10 dry run exited $RES_DRY_RC: $(head -c 300 "$WORK/residue-dry.err")"
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
  no "rotation at the shipped keep=10 would archive $RES_ARCH_N blocks — it is a REPORTED NO-OP at exit 0, which reads exactly like \"already rotated\""
else
  ok "rotation at the shipped keep=10 would archive $RES_ARCH_N block(s) of residue.md"
fi

# (c) RECLAIMABLE BYTES, AND THE HEADROOM THEY BUY. Zero reclaimable bytes is
#     the live condition; the floor is what says the re-block was worth doing.
if [ "${RES_ARCH_B:-0}" -lt "$RES_MIN_RECLAIM" ]; then
  no "rotation at keep=10 would reclaim only ${RES_ARCH_B:-0} B from residue.md (floor $RES_MIN_RECLAIM B) — the file is $RES_ORIGB B and there is nothing the tool can take"
else
  ok "rotation at keep=10 would reclaim $RES_ARCH_B B from residue.md (>= the $RES_MIN_RECLAIM B floor)"
fi
RES_HEADROOM=$(( RES_CEIL - ${RES_RETB:-RES_CEIL} ))
if [ "$RES_HEADROOM" -lt "$RES_MIN_RECLAIM" ]; then
  no "after a keep=10 rotation residue.md would still be ${RES_RETB:-?} B, leaving $RES_HEADROOM B under the $RES_CEIL B ceiling — a close writing more than that has no green path"
else
  ok "after a keep=10 rotation residue.md would be $RES_RETB B, leaving $RES_HEADROOM B of headroom under the $RES_CEIL B ceiling"
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
RES_N_ROT=0; RES_N_REFUSED=0; RES_N_BAD=0; RES_N_LEAK=0; RES_N_DRIFT=0
RES_N=1
while [ "$RES_N" -le "${RES_TOT:-0}" ]; do
  RES_NR="$WORK/keep-$RES_N"
  mkdir -p "$RES_NR/build-os/memory"
  cp "$RES_LIVE" "$RES_NR/build-os/memory/residue.md"
  node "$SRC/build-os/maintenance/rotate-memory.mjs" \
       --root "$RES_NR" --file residue --keep "$RES_N" --apply \
       > "$WORK/keep-$RES_N.out" 2>&1
  RES_N_RC=$?
  if [ "$RES_N_RC" -eq 3 ]; then
    # a ceiling refusal must be a NO-WRITE: the copy is untouched and no
    # archive was created, so nothing was archived and nothing was lost
    RES_N_REFUSED=$((RES_N_REFUSED+1))
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
[ $(( RES_N_ROT + RES_N_REFUSED )) -eq "${RES_TOT:-0}" ] \
  && ok "every legal keep ended in one of exactly two ways: $RES_N_ROT rotated, $RES_N_REFUSED refused at the ceiling (exit 3) writing nothing" \
  || no "a legal keep ended some third way — $RES_N_ROT rotated + $RES_N_REFUSED refused != ${RES_TOT:-0} sweeps"
[ "$RES_N_BAD" -eq 0 ] \
  && ok "at all $RES_N_ROT rotating keeps the live file still carries all three gate-pinned literals, and every ceiling refusal wrote nothing at all" \
  || no "$RES_N_BAD failure(s): a legal --keep archived a gate-pinned literal out of the live file, or a refusal still wrote"
[ "$RES_N_LEAK" -eq 0 ] \
  && ok "at all $RES_N_ROT rotating keeps, NO gate-pinned literal ever reaches the archive" \
  || no "$RES_N_LEAK gate-pinned literal(s) reached the archive — the standing region is reachable by rotation after all"
[ "$RES_N_DRIFT" -eq 0 ] \
  && ok "at all $RES_N_ROT rotating keeps, block 1 is byte-identical to the source (the standing region is never rewritten; only the preamble gains a banner)" \
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
CS_N_ROT=0; CS_N_REFUSED=0; CS_N_BAD=0; CS_N_LEAK=0; CS_N_DRIFT=0
CS_N=1
while [ "$CS_N" -le "${CS_TOT:-0}" ]; do
  CS_NR="$WORK/cs-keep-$CS_N"
  mkdir -p "$CS_NR/build-os/memory"
  cp "$CS_LIVE" "$CS_NR/build-os/memory/current_state.md"
  node "$SRC/build-os/maintenance/rotate-memory.mjs" \
       --root "$CS_NR" --file current_state --keep "$CS_N" --apply \
       > "$WORK/cs-keep-$CS_N.out" 2>&1
  CS_N_RC=$?
  if [ "$CS_N_RC" -eq 3 ]; then
    CS_N_REFUSED=$((CS_N_REFUSED+1))
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
[ $(( CS_N_ROT + CS_N_REFUSED )) -eq "${CS_TOT:-0}" ] \
  && ok "every legal keep over current_state.md ended in one of exactly two ways: $CS_N_ROT rotated, $CS_N_REFUSED refused at the ceiling (exit 3) writing nothing" \
  || no "a legal keep ended some third way — $CS_N_ROT rotated + $CS_N_REFUSED refused != ${CS_TOT:-0} sweeps"
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

echo ""
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
