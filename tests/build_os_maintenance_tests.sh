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
#   3. pre-existing customer content is PRESERVED — a customer CLAUDE.md, a
#      customer standing_gates.md, a customer memory file, a customer .gitignore
#      and a customer package.json
#   4. oversized synthetic memory rotates with BYTE-EXACT conservation, and the
#      archive + INDEX are correct
#   5. the sanctioned wrapper goes RED when a run mutates the never-rotated
#      standing_gates.md
#   6. a bare `node --test` is UNGUARDED, demonstrated by measurement, and no
#      shipped file advertises it
#   7. the uninstall boundary: removing exactly the managed list leaves every
#      customer file byte-identical
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

echo ""
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
