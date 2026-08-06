#!/usr/bin/env bash
# Context Compiler — SEAM 1 repository index tests (LANE A).
#
# WHAT THIS PINS. build-os/compiler/index/build-index.mjs turns a git working
# tree into the SEAM 1 `index.json` the compiler consumes, and it pins the four
# properties that make that index worth consuming:
#
#   1. SHAPE — the exact SEAM 1 schema, including the honesty fields. `null`
#      means not-measured; a file whose language has no parser gets `symbols: []`
#      AND `partial: true`, never a silent empty.
#   2. DETERMINISM — same repo state, byte-identical index. Asserted by running
#      the indexer twice with --deterministic and byte-comparing. This is a hard
#      requirement, not a nicety: a capsule compiler on top of a wobbling index
#      cannot be cached or reproduced.
#   3. INCREMENTAL REUSE THAT ACTUALLY REUSES — proved by poisoning the prior
#      index with a sentinel symbol and asserting the sentinel SURVIVES into the
#      next build for an unchanged blob. A reuse counter alone can lie; a
#      sentinel that survives cannot.
#   4. NO FAKED EDGES — `imported_by` is asserted to contain only real index
#      keys, globally. A bare module specifier ('express', 'os') stays verbatim
#      in `imports` and is never invented into a reverse edge.
#
# VACUITY. Several assertions here would pass against an empty index, an empty
# edge set, or an extractor that had gone blind. Each is paired with a guard
# that asserts the collection is non-empty first.
#
# FIXTURES ARE FABRICATED mktemp git repos. This suite never reads, writes, or
# indexes the pilot environment or this repository.
#
# No network. Deterministic. Temp dirs only. Exits non-zero if any assertion
# fails, and prints a final "==== RESULT: N passed, M failed ====" line.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IDXR="$SRC/build-os/compiler/index/build-index.mjs"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
eq(){ # eq <label> <got> <want>
  if [ "$2" = "$3" ]; then ok "$1"; else no "$1 — got [$2] want [$3]"; fi
}
has(){ # has <label> <haystack> <needle>
  if grep -qF -- "$3" <<<"$2"; then ok "$1"; else no "$1 — [$3] absent from output"; fi
}

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# q <index.json> <js-expression over `i`> — read one value out of an index.
q(){ node -e '
const i = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
const v = eval(process.argv[2]);
process.stdout.write(v === undefined ? "undefined" : (v === null ? "null" : (typeof v === "object" ? JSON.stringify(v) : String(v))));
' "$1" "$2" 2>/dev/null; }

RC=0; OUT=""; ERRTXT=""
run(){ # run <args...> — capture stdout, stderr and rc separately
  OUT="$(node "$IDXR" "$@" 2>"$WORK/stderr.txt")"; RC=$?
  ERRTXT="$(cat "$WORK/stderr.txt")"
  return 0
}

mkrepo(){ # mkrepo <dir>
  mkdir -p "$1"
  git -C "$1" init -q 2>/dev/null || git -C "$1" init -q
  git -C "$1" config user.email "fixture@example.invalid"
  git -C "$1" config user.name "Fixture"
  git -C "$1" config commit.gpgsign false
}
commitall(){ git -C "$1" add -A && git -C "$1" commit -q -m "${2:-fixture}"; }

if [ ! -f "$IDXR" ]; then
  echo "  FAIL: indexer missing at $IDXR"
  echo
  echo "==== RESULT: 0 passed, 1 failed ===="
  exit 1
fi

# ---------------------------------------------------------------------------
# FIXTURE 1 — a TS/JS repo with imports, tests, a generated dir, config, doc.
# ---------------------------------------------------------------------------
R1="$WORK/ts-repo"; mkrepo "$R1"
mkdir -p "$R1/src" "$R1/tests" "$R1/dist"

cat > "$R1/src/util.ts" <<'EOF'
// utilities
export interface Options { deep: boolean }
export type Mode = 'a' | 'b';
export function slugify(input: string): string {
  return input.trim().toLowerCase();
}
export const VERSION = '1.0.0';
class Helper {}
export { Helper };
EOF

cat > "$R1/src/index.ts" <<'EOF'
import { slugify, VERSION } from './util';
import express from 'express';

export function main(): string {
  return slugify(VERSION) + express.name;
}
EOF

# legacy.js is the extractor's honesty fixture:
#   - line 2 holds a regex literal containing an apostrophe. A scanner that does
#     not know regex literals will open a string there and swallow the rest of
#     the file, losing the require() on line 3.
#   - lines 4-5 hold commented-out imports that must NEVER be extracted.
cat > "$R1/src/legacy.js" <<'EOF'
/* legacy helpers */
const apostropheRe = /it's/;
const path = require('path');
// import { ghost } from './ghost';
/* import { phantom } from './phantom'; */
function oldHelper() {
  return path.sep + apostropheRe.source;
}
module.exports = { oldHelper };
EOF

cat > "$R1/tests/util.test.ts" <<'EOF'
import { slugify } from '../src/util';
describe('slugify', () => {
  it('trims', () => { slugify(' A '); });
});
EOF

# No import — this one can only be linked to src/index.ts by basename.
cat > "$R1/tests/index.spec.ts" <<'EOF'
describe('main', () => {
  it('runs', () => {});
});
EOF

printf 'export const BUNDLE=1;\n' > "$R1/dist/bundle.min.js"
printf '{"name":"fixture1","version":"1.0.0"}\n' > "$R1/package.json"
printf '# fixture1\n\nDocs.\n' > "$R1/README.md"
commitall "$R1" "ts fixture"

echo "== 1. build produces a SEAM 1 shaped index =="
run build "$R1" --out "$WORK/i1.json" --deterministic
eq "build exits 0" "$RC" "0"
I1="$WORK/i1.json"
if [ -s "$I1" ]; then ok "index file written and non-empty"; else no "index file missing or empty"; fi
eq "index_version is an int" "$(q "$I1" 'typeof i.index_version')" "number"
eq "repo_head is the fixture HEAD" "$(q "$I1" 'i.repo_head')" "$(git -C "$R1" rev-parse HEAD)"
eq "files is an object" "$(q "$I1" 'typeof i.files')" "object"
eq "symbols is an object" "$(q "$I1" 'typeof i.symbols')" "object"
eq "error_clusters is an array" "$(q "$I1" 'Array.isArray(i.error_clusters)')" "true"
eq "8 tracked files indexed" "$(q "$I1" 'Object.keys(i.files).length')" "8"
eq "every file carries the SEAM 1 keys" \
  "$(q "$I1" 'Object.values(i.files).every(f=>["blob","lang","kind","symbols","imports","imported_by","tests_covering","last_changed","error_count"].every(k=>k in f))')" "true"
eq "blob shas are 40-hex git blob ids" \
  "$(q "$I1" 'Object.values(i.files).every(f=>/^[0-9a-f]{40}$/.test(f.blob))')" "true"
eq "blob sha matches git hash-object for src/util.ts" \
  "$(q "$I1" 'i.files["src/util.ts"].blob')" "$(git -C "$R1" hash-object src/util.ts)"

echo "== 2. honesty fields: partial, symbols_partial, errors_measured =="
eq "top-level symbols_partial is flagged true" "$(q "$I1" 'i.symbols_partial')" "true"
eq "top-level tests_covering_heuristic is flagged true" "$(q "$I1" 'i.tests_covering_heuristic')" "true"
eq "errors_measured is false with no --errors" "$(q "$I1" 'i.errors_measured')" "false"
eq "error_clusters empty with no --errors" "$(q "$I1" 'i.error_clusters.length')" "0"
eq "error_count is null (not 0) when errors were not measured" \
  "$(q "$I1" 'Object.values(i.files).every(f=>f.error_count===null)')" "true"
eq "every file is flagged partial in v0 (regex extraction, not AST)" \
  "$(q "$I1" 'Object.values(i.files).every(f=>f.partial===true)')" "true"
eq "the JS/TS extractor names itself" "$(q "$I1" 'i.files["src/util.ts"].parser')" "js-ts-regex-v0"

echo "== 3. kind classification =="
eq "src/util.ts is source"           "$(q "$I1" 'i.files["src/util.ts"].kind')"          "source"
eq "tests/util.test.ts is test"      "$(q "$I1" 'i.files["tests/util.test.ts"].kind')"   "test"
eq "tests/index.spec.ts is test"     "$(q "$I1" 'i.files["tests/index.spec.ts"].kind')"  "test"
eq "dist/bundle.min.js is generated" "$(q "$I1" 'i.files["dist/bundle.min.js"].kind')"   "generated"
eq "package.json is config"          "$(q "$I1" 'i.files["package.json"].kind')"         "config"
eq "README.md is doc"                "$(q "$I1" 'i.files["README.md"].kind')"            "doc"
eq "lang for .ts is typescript"      "$(q "$I1" 'i.files["src/util.ts"].lang')"          "typescript"
eq "lang for .js is javascript"      "$(q "$I1" 'i.files["src/legacy.js"].lang')"        "javascript"

echo "== 4. symbol extraction (declared + exported) =="
eq "src/util.ts symbols" "$(q "$I1" 'i.files["src/util.ts"].symbols')" \
  '["Helper","Mode","Options","VERSION","slugify"]'
eq "src/index.ts symbols" "$(q "$I1" 'i.files["src/index.ts"].symbols')" '["main"]'
eq "src/legacy.js symbols" "$(q "$I1" 'i.files["src/legacy.js"].symbols')" \
  '["apostropheRe","oldHelper","path"]'
eq "symbols table locates slugify" "$(q "$I1" 'i.symbols["slugify"].defined_in')" "src/util.ts"
eq "symbols table records the declaration line" "$(q "$I1" 'i.symbols["slugify"].line')" "4"

echo "== 5. referenced_in is a whole-word text heuristic, and says so =="
eq "slugify referenced_in is non-empty (vacuity guard)" \
  "$(q "$I1" 'i.symbols["slugify"].referenced_in.length > 0')" "true"
eq "slugify referenced_in lists every file whose text contains the word" \
  "$(q "$I1" 'i.symbols["slugify"].referenced_in')" \
  '["src/index.ts","src/util.ts","tests/util.test.ts"]'
eq "referenced_in entries are all real index keys" \
  "$(q "$I1" 'Object.values(i.symbols).every(s=>s.referenced_in.every(p=>p in i.files))')" "true"

echo "== 6. imports resolve; unresolved specifiers stay verbatim and never fake edges =="
eq "relative import resolved to a repo path, bare specifier kept verbatim" \
  "$(q "$I1" 'i.files["src/index.ts"].imports')" '["express","src/util.ts"]'
eq "commented-out imports are NOT extracted, require() IS" \
  "$(q "$I1" 'i.files["src/legacy.js"].imports')" '["path"]'
eq "imported_by is non-empty somewhere (vacuity guard)" \
  "$(q "$I1" 'Object.values(i.files).reduce((n,f)=>n+f.imported_by.length,0) > 0')" "true"
eq "src/util.ts imported_by" "$(q "$I1" 'i.files["src/util.ts"].imported_by')" \
  '["src/index.ts","tests/util.test.ts"]'
eq "NO imported_by entry is an unresolved specifier (global)" \
  "$(q "$I1" 'Object.values(i.files).flatMap(f=>f.imported_by).filter(p=>!(p in i.files)).join(",")')" ""
eq "the bare specifier express never became a file entry" \
  "$(q "$I1" '"express" in i.files')" "false"

echo "== 7. tests_covering — both the import path and the basename path =="
eq "covered by import" "$(q "$I1" 'i.files["src/util.ts"].tests_covering')" '["tests/util.test.ts"]'
eq "covered by basename only (no import exists)" \
  "$(q "$I1" 'i.files["src/index.ts"].tests_covering')" '["tests/index.spec.ts"]'
eq "test files are not reported as covering themselves" \
  "$(q "$I1" 'Object.entries(i.files).filter(([p,f])=>f.kind==="test").every(([p,f])=>f.tests_covering.length===0)')" "true"
eq "tests_covering entries are all real index keys" \
  "$(q "$I1" 'Object.values(i.files).every(f=>f.tests_covering.every(p=>p in i.files))')" "true"

echo "== 8. last_changed comes from git, generated_at is the only time field =="
eq "last_changed is an ISO timestamp" \
  "$(q "$I1" '/^\d{4}-\d{2}-\d{2}T/.test(i.files["src/util.ts"].last_changed)')" "true"
eq "--deterministic zeroes generated_at" "$(q "$I1" 'i.generated_at')" "null"
run build "$R1" --out "$WORK/i1_stamped.json"
eq "without --deterministic, generated_at is a real ISO string" \
  "$(q "$WORK/i1_stamped.json" 'typeof i.generated_at')" "string"

echo "== 9. DETERMINISM — same repo state, byte-identical index =="
run build "$R1" --out "$WORK/i1_again.json" --deterministic
if cmp -s "$I1" "$WORK/i1_again.json"; then ok "two --deterministic runs are byte-identical"
else no "two --deterministic runs DIFFER"; diff "$I1" "$WORK/i1_again.json" | head -5 | sed 's/^/      | /'; fi
if cmp -s "$I1" "$WORK/i1_stamped.json"; then
  no "the stamped run equals the deterministic run — generated_at is not being written at all"
else ok "the stamped run differs only because generated_at is present (guard)"; fi

echo "== 10. incremental reuse by blob sha — and it ACTUALLY reuses =="
run build "$R1" --out "$WORK/i1_full.json" --deterministic
has "a full build reports 0 reused" "$ERRTXT" "reused 0, reparsed 8"
run build "$R1" --out "$WORK/i1_inc.json" --since "$I1" --deterministic
has "an unchanged --since build reports 8 reused, 0 reparsed" "$ERRTXT" "reused 8, reparsed 0"
if cmp -s "$I1" "$WORK/i1_inc.json"; then ok "incremental output is byte-identical to the full build"
else no "incremental output DIFFERS from the full build"; diff "$I1" "$WORK/i1_inc.json" | head -5 | sed 's/^/      | /'; fi

# Sentinel proof: poison the prior index for an UNCHANGED blob. If the file is
# genuinely reused the poison survives; if it is silently re-parsed it vanishes.
node -e '
const fs=require("fs"); const i=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
i.files["src/util.ts"].symbols.push("ZZZ_REUSE_SENTINEL");
fs.writeFileSync(process.argv[2], JSON.stringify(i));
' "$I1" "$WORK/i1_poison.json"
run build "$R1" --out "$WORK/i1_from_poison.json" --since "$WORK/i1_poison.json" --deterministic
eq "an unchanged blob is COPIED, not re-parsed (sentinel survives)" \
  "$(q "$WORK/i1_from_poison.json" 'i.files["src/util.ts"].symbols.includes("ZZZ_REUSE_SENTINEL")')" "true"

# Change exactly one file; only that file may be re-parsed.
cat >> "$R1/src/index.ts" <<'EOF'
export function added(): number { return 1; }
EOF
commitall "$R1" "touch one file"
run build "$R1" --out "$WORK/i1_touched.json" --since "$I1" --deterministic
has "touching one file re-parses exactly one file" "$ERRTXT" "reused 7, reparsed 1"
eq "the re-parsed file shows its new symbol" \
  "$(q "$WORK/i1_touched.json" 'i.files["src/index.ts"].symbols')" '["added","main"]'
OLDBLOB="$(q "$I1" 'i.files["src/index.ts"].blob')"
NEWBLOB="$(q "$WORK/i1_touched.json" 'i.files["src/index.ts"].blob')"
if [ -n "$OLDBLOB" ] && [ "$OLDBLOB" != "$NEWBLOB" ]; then
  ok "the changed file's blob sha moved (the reuse key is the blob, not the path)"
else
  no "the changed file's blob sha did not move — reuse would be keyed on nothing"
fi
UNBLOB="$(q "$WORK/i1_touched.json" 'i.files["src/util.ts"].blob')"
eq "the untouched file's blob sha did not move" "$UNBLOB" "$(q "$I1" 'i.files["src/util.ts"].blob')"

echo "== 11. error clustering from a tsc-style list =="
cat > "$WORK/errors.txt" <<'EOF'
src/util.ts(3,10): error TS2304: Cannot find name 'foo'.
src/index.ts(2,5): error TS2304: Cannot find name 'bar'.
src/index.ts(4,1): error TS2345: Argument of type 'string' is not assignable to parameter of type 'number'.
EOF
run build "$R1" --out "$WORK/i1_err.json" --errors "$WORK/errors.txt" --deterministic
eq "errors_measured flips to true" "$(q "$WORK/i1_err.json" 'i.errors_measured')" "true"
eq "two distinct signatures clustered" "$(q "$WORK/i1_err.json" 'i.error_clusters.length')" "2"
eq "the largest cluster is first" "$(q "$WORK/i1_err.json" 'i.error_clusters[0].count')" "2"
has "the signature is normalized, not the raw message" \
  "$(q "$WORK/i1_err.json" 'i.error_clusters[0].signature')" "TS2304"
eq "quoted identifiers are normalized out of the signature" \
  "$(q "$WORK/i1_err.json" 'i.error_clusters[0].signature.includes("foo") || i.error_clusters[0].signature.includes("bar")')" "false"
eq "cluster files are sorted repo paths" "$(q "$WORK/i1_err.json" 'i.error_clusters[0].files')" \
  '["src/index.ts","src/util.ts"]'
eq "per-file error_count for a file with two errors" \
  "$(q "$WORK/i1_err.json" 'i.files["src/index.ts"].error_count')" "2"
eq "per-file error_count is 0 (measured, none found) not null" \
  "$(q "$WORK/i1_err.json" 'i.files["src/legacy.js"].error_count')" "0"

echo "== 12. FIXTURE 2 — mixed python/go, best-effort and honest about it =="
R2="$WORK/mixed-repo"; mkrepo "$R2"
mkdir -p "$R2/app" "$R2/tests" "$R2/srv"
cat > "$R2/app/main.py" <<'EOF'
import os
from app.helpers import helper


def run():
    return helper(os.name)


class Runner:
    def start(self):
        return run()
EOF
cat > "$R2/app/helpers.py" <<'EOF'
def helper(x):
    return x
EOF
cat > "$R2/tests/test_main.py" <<'EOF'
from app.main import run


def test_run():
    assert run() is not None
EOF
cat > "$R2/srv/server.go" <<'EOF'
package main

import (
	"fmt"
	"net/http"
)

type Config struct {
	Addr string
}

func Serve(c Config) error {
	fmt.Println(c.Addr)
	return http.ListenAndServe(c.Addr, nil)
}
EOF
cat > "$R2/srv/server_test.go" <<'EOF'
package main

import "testing"

func TestServe(t *testing.T) {
	_ = Serve(Config{Addr: ":0"})
}
EOF
commitall "$R2" "mixed fixture"

run build "$R2" --out "$WORK/i2.json" --deterministic
I2="$WORK/i2.json"
eq "build exits 0 on the mixed repo" "$RC" "0"
eq "5 files indexed" "$(q "$I2" 'Object.keys(i.files).length')" "5"
eq "python lang" "$(q "$I2" 'i.files["app/main.py"].lang')" "python"
eq "go lang"     "$(q "$I2" 'i.files["srv/server.go"].lang')" "go"
eq "python def/class extracted best-effort" "$(q "$I2" 'i.files["app/main.py"].symbols')" \
  '["Runner","run","start"]'
eq "go func/type extracted best-effort" "$(q "$I2" 'i.files["srv/server.go"].symbols')" \
  '["Config","Serve"]'
eq "python file is flagged partial" "$(q "$I2" 'i.files["app/main.py"].partial')" "true"
eq "go file is flagged partial" "$(q "$I2" 'i.files["srv/server.go"].partial')" "true"
eq "python imports kept verbatim" "$(q "$I2" 'i.files["app/main.py"].imports')" '["app.helpers","os"]'
eq "go imports kept verbatim" "$(q "$I2" 'i.files["srv/server.go"].imports')" '["fmt","net/http"]'
eq "unresolved python imports produce NO reverse edge" \
  "$(q "$I2" 'i.files["app/main.py"].imported_by')" '[]'
eq "python test kind" "$(q "$I2" 'i.files["tests/test_main.py"].kind')" "test"
eq "go test kind"     "$(q "$I2" 'i.files["srv/server_test.go"].kind')" "test"
eq "tests_covering by test_ prefix" "$(q "$I2" 'i.files["app/main.py"].tests_covering')" \
  '["tests/test_main.py"]'
eq "tests_covering by _test suffix" "$(q "$I2" 'i.files["srv/server.go"].tests_covering')" \
  '["srv/server_test.go"]'

echo "== 13. FIXTURE 3 — an empty repo does not crash or invent data =="
R3="$WORK/empty-repo"; mkrepo "$R3"
run build "$R3" --out "$WORK/i3.json" --deterministic
eq "empty repo build exits 0" "$RC" "0"
eq "no files" "$(q "$WORK/i3.json" 'Object.keys(i.files).length')" "0"
eq "no symbols" "$(q "$WORK/i3.json" 'Object.keys(i.symbols).length')" "0"
eq "repo_head is null (not-measured), not a fake sha" "$(q "$WORK/i3.json" 'i.repo_head')" "null"
run stats "$WORK/i3.json"
eq "stats on an empty index exits 0" "$RC" "0"
has "stats reports zero files" "$OUT" "files_indexed: 0"
if grep -qE 'NaN|Infinity|undefined' <<<"$OUT"; then no "stats prints NaN/Infinity/undefined on an empty index"
else ok "stats prints no NaN/Infinity/undefined on an empty index"; fi

echo "== 14. FIXTURE 4 — a language with no parser gets [] AND partial: true =="
R4="$WORK/noparser-repo"; mkrepo "$R4"
mkdir -p "$R4/weird"
printf '       IDENTIFICATION DIVISION.\n       PROGRAM-ID. LEGACY.\n' > "$R4/weird/thing.cbl"
printf 'just some notes\n' > "$R4/notes.txt"
commitall "$R4" "noparser fixture"
run build "$R4" --out "$WORK/i4.json" --deterministic
eq "no-parser repo build exits 0" "$RC" "0"
eq "unparsed language yields empty symbols" "$(q "$WORK/i4.json" 'i.files["weird/thing.cbl"].symbols')" '[]'
eq "unparsed language is flagged partial (never a silent empty)" \
  "$(q "$WORK/i4.json" 'i.files["weird/thing.cbl"].partial')" "true"
eq "unparsed language names its parser as none" \
  "$(q "$WORK/i4.json" 'i.files["weird/thing.cbl"].parser')" "none"
eq "lang id falls back to the extension rather than claiming a known language" \
  "$(q "$WORK/i4.json" 'i.files["weird/thing.cbl"].lang')" "cbl"

echo "== 15. stats — coverage is REPORTED, never implied =="
run stats "$I1"
eq "stats exits 0" "$RC" "0"
has "files indexed"        "$OUT" "files_indexed: 8"
has "partial percentage"   "$OUT" "partial: 8 (100.0%)"
has "unresolved imports"   "$OUT" "unresolved_imports: 2"
has "languages seen"       "$OUT" "typescript=4"
has "languages seen (js)"  "$OUT" "javascript=2"
has "errors measured flag" "$OUT" "errors_measured: false"
WS="$(q "$I1" 'Object.values(i.files).filter(f=>f.symbols.length>0).length')"
has "with_symbols matches the index it describes" "$OUT" "with_symbols: $WS"
ST="$(q "$I1" 'Object.keys(i.symbols).length')"
has "symbols table size matches the index" "$OUT" "symbols_table: $ST"
run stats "$WORK/i1_err.json"
has "stats reports measured errors when they were measured" "$OUT" "errors_measured: true"

echo "== 16. refusals =="
run build "$WORK" --out "$WORK/nope.json"
eq "a non-git directory is refused with exit 2" "$RC" "2"
has "the refusal names the cause" "$ERRTXT" "not a git repository"
run build "$R1" --out "$WORK/nope.json" --frobnicate
eq "an unknown flag is refused with exit 2" "$RC" "2"
run stats "$WORK/does-not-exist.json"
eq "stats on a missing index is refused with exit 2" "$RC" "2"
run
eq "no subcommand is refused with exit 2" "$RC" "2"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
