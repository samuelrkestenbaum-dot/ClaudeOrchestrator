#!/usr/bin/env bash
# Context Compiler — CAPABILITY REPORTER tests.
#
# WHAT THIS PINS. build-os/compiler/capability/report.mjs answers one question a
# capsule cannot answer about itself: "is the index that produced me actually
# informed about this repository, or is it blind?" The first end-to-end
# integration run found this repo is 94% no-parser, which means a small capsule
# here is small-because-UNINFORMED, not small-because-selective. That is the
# exact failure mode AB_PREREGISTRATION outcome 4 names, and AMENDMENT 1 turns
# it into a number. This suite pins:
#
#   1. THE THREE USE STATES — normal | expansion-heavy | bypass — each chosen by
#      a printed derivation, on fabricated indexes whose signal level is known
#      by construction.
#   2. HONESTY IN ARITHMETIC — every share prints as `n/total (pct%)`; a metric
#      with no denominator prints `unavailable` WITH a reason and never 0; an
#      empty index produces neither a crash nor a division-by-zero percentage.
#   3. AMENDMENT 1 APPLIED MECHANICALLY — the eligibility verdict is asserted at
#      the boundary itself (49/100 eligible, 50/100 not), because a threshold
#      rule that is only tested far from its boundary is not tested.
#   4. CONFIDENCE IS DERIVED FROM OBSERVABLES — every admitted item gets exactly
#      one ordinal, and the ordinal follows the admitting rule plus parser plus
#      symbol presence, not a vibe.
#   5. DETERMINISM — same inputs, byte-identical --json report.
#   6. THE HONEST SELF-ASSESSMENT — run for real against a freshly built index
#      of THIS repository, the tool must say bypass / NOT-ELIGIBLE. A capability
#      reporter that flatters its own repository is worthless.
#
# VACUITY GUARDS. The "no bare percentages" check is grep-NEGATIVE, so it would
# pass against empty output; every report captured by it is first asserted
# non-empty. The parser-coverage assertions are paired with a count assertion so
# they cannot pass against a report that printed nothing.
#
# FIXTURES are fabricated SEAM 1 indexes in mktemp. The only real repository
# touched is this one, READ-ONLY, via `build-index.mjs build` into a temp dir.
#
# No network. Deterministic. Exits non-zero if any assertion fails, and prints a
# final "==== RESULT: N passed, M failed ====" line.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RPT="$SRC/build-os/compiler/capability/report.mjs"
IDXR="$SRC/build-os/compiler/index/build-index.mjs"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
eq(){ if [ "$2" = "$3" ]; then ok "$1"; else no "$1 — got [$2] want [$3]"; fi; }
has(){ if grep -qF -- "$3" <<<"$2"; then ok "$1"; else no "$1 — [$3] absent from output"; fi; }
hasnt(){ if grep -qF -- "$3" <<<"$2"; then no "$1 — [$3] present and must not be"; else ok "$1"; fi; }
nonempty(){ if [ -n "$2" ]; then ok "$1"; else no "$1 — output was empty"; fi; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
ALL="$WORK/all_output.txt"
: >"$ALL"

run(){ OUT="$(node "$RPT" "$@" 2>"$WORK/err")"; RC=$?; ERRTXT="$(cat "$WORK/err")"; printf '%s\n' "$OUT" >>"$ALL"; }

# ---------------------------------------------------------------- fixtures --
cat >"$WORK/mk.mjs" <<'MKEOF'
// mk.mjs <out.json> <spec.json> — fabricate a SEAM 1 index from a compact spec.
import fs from 'node:fs';
const [out, specPath] = process.argv.slice(2);
const spec = JSON.parse(fs.readFileSync(specPath, 'utf8'));
const list = [...(spec.files || [])];
for (const g of spec.generate || []) {
  for (let i = 0; i < g.count; i++) {
    list.push({
      path: `${g.prefix}${i}${g.ext}`,
      lang: g.lang || 'unknown',
      kind: g.kind || 'source',
      parser: g.parser || 'none',
      symbols: g.symbols ? [`${g.symprefix || 'sym'}_${i}`] : [],
      tests_covering: g.tests ? [`tests/gen_${i}.test.ts`] : [],
    });
  }
}
const files = {}; const symbols = {};
for (const f of list) {
  const syms = f.symbols || [];
  files[f.path] = {
    blob: 'a'.repeat(40),
    lang: f.lang || 'unknown',
    kind: f.kind || 'source',
    parser: f.parser || 'none',
    partial: true,
    symbols: [...syms].sort(),
    symbol_lines: Object.fromEntries(syms.map((s, i) => [s, i + 1])),
    raw_imports: [],
    imports: f.imports || [],
    imported_by: f.imported_by || [],
    tests_covering: (f.tests_covering || []).slice().sort(),
    last_changed: null,
    error_count: null,
  };
  for (const s of syms) {
    if (!symbols[s]) symbols[s] = { defined_in: f.path, line: 1, referenced_in: [], also_defined_in: [] };
  }
}
const idx = {
  index_version: 1,
  repo_head: 'deadbeefdeadbeefdeadbeefdeadbeefdeadbeef',
  generated_at: null,
  symbols_partial: true,
  tests_covering_heuristic: true,
  errors_measured: false,
  files,
  symbols,
  error_clusters: spec.clusters || [],
};
fs.writeFileSync(out, JSON.stringify(idx, null, 2) + '\n');
MKEOF
mk(){ node "$WORK/mk.mjs" "$1" "$2" || { echo "fixture build failed: $1"; exit 9; }; }

# (a) high-signal TS-ish index: most files parsed, symbols, test links.
cat >"$WORK/spec_a.json" <<'EOF'
{ "files": [
    { "path": "README.md", "lang": "markdown", "kind": "doc", "parser": "none" },
    { "path": "package.json", "lang": "json", "kind": "config", "parser": "none" } ],
  "generate": [
    { "count": 8, "prefix": "src/mod", "ext": ".ts", "lang": "ts", "parser": "js-ts-regex-v0",
      "symbols": true, "symprefix": "mod", "tests": true } ] }
EOF
mk "$WORK/a.json" "$WORK/spec_a.json"

# (b) shell-dominant index, the shape this repository actually has. The single
# parsed file sits under build-os/compiler/ so that build-os/ is NOT itself
# entirely unparsed — which is what makes build-os/tools/ the MAXIMAL blind spot
# and lets the suite pin that only maximal directories are named.
cat >"$WORK/spec_b.json" <<'EOF'
{ "files": [
    { "path": "build-os/compiler/only.js", "lang": "js", "kind": "source", "parser": "js-ts-regex-v0",
      "symbols": ["theOneSymbol"] } ],
  "generate": [
    { "count": 12, "prefix": "build-os/tools/t", "ext": ".sh", "lang": "shell", "parser": "none" },
    { "count": 7,  "prefix": "docs/d",           "ext": ".md", "lang": "markdown", "kind": "doc", "parser": "none" } ] }
EOF
mk "$WORK/b.json" "$WORK/spec_b.json"

# (c) thin signal: parsed, symbols, but zero test linkage.
cat >"$WORK/spec_c.json" <<'EOF'
{ "files": [ { "path": "README.md", "lang": "markdown", "kind": "doc", "parser": "none" } ],
  "generate": [
    { "count": 9, "prefix": "src/thin", "ext": ".ts", "lang": "ts", "parser": "js-ts-regex-v0",
      "symbols": true, "symprefix": "thin", "tests": false } ] }
EOF
mk "$WORK/c.json" "$WORK/spec_c.json"

# (d) empty index.
echo '{ "files": [] }' >"$WORK/spec_d.json"
mk "$WORK/d.json" "$WORK/spec_d.json"

# (g) boundary indexes: 49/100 and 50/100 no_parser.
cat >"$WORK/spec_g49.json" <<'EOF'
{ "generate": [
    { "count": 51, "prefix": "src/p", "ext": ".ts", "lang": "ts", "parser": "js-ts-regex-v0",
      "symbols": true, "symprefix": "p", "tests": true },
    { "count": 49, "prefix": "sh/s", "ext": ".sh", "lang": "shell", "parser": "none" } ] }
EOF
mk "$WORK/g49.json" "$WORK/spec_g49.json"
cat >"$WORK/spec_g50.json" <<'EOF'
{ "generate": [
    { "count": 50, "prefix": "src/p", "ext": ".ts", "lang": "ts", "parser": "js-ts-regex-v0",
      "symbols": true, "symprefix": "p", "tests": true },
    { "count": 50, "prefix": "sh/s", "ext": ".sh", "lang": "shell", "parser": "none" } ] }
EOF
mk "$WORK/g50.json" "$WORK/spec_g50.json"

# (e) an index + capsule for per-item confidence.
cat >"$WORK/spec_e.json" <<'EOF'
{ "files": [
    { "path": "src/core.ts",    "lang": "ts", "parser": "js-ts-regex-v0", "symbols": ["coreFn"],
      "tests_covering": ["tests/core.test.ts"] },
    { "path": "src/helper.ts",  "lang": "ts", "parser": "js-ts-regex-v0", "symbols": ["helpFn"] },
    { "path": "src/empty.ts",   "lang": "ts", "parser": "js-ts-regex-v0", "symbols": [] },
    { "path": "tests/core.test.ts", "lang": "ts", "kind": "test", "parser": "js-ts-regex-v0",
      "symbols": ["testsCore"] },
    { "path": "scripts/run.sh", "lang": "shell", "parser": "none" },
    { "path": "scripts/other.sh", "lang": "shell", "parser": "none" } ] }
EOF
mk "$WORK/e.json" "$WORK/spec_e.json"
cat >"$WORK/capsule_e.json" <<'EOF'
{ "capsule_version": 1, "task_id": "T-1", "compiled_at": null, "index_version": 1,
  "repo_head": "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
  "objective": "fixture", "acceptance": [],
  "relevant_files": [
    { "path": "src/core.ts", "why": "defines seed symbol coreFn", "symbols": ["coreFn"] },
    { "path": "src/empty.ts", "why": "named as a seed file in the task descriptor", "symbols": [] },
    { "path": "tests/core.test.ts", "why": "test covering it (tests_covering of src/core.ts)", "symbols": ["testsCore"] },
    { "path": "src/helper.ts", "why": "direct import of the defining file src/core.ts", "symbols": ["helpFn"] },
    { "path": "scripts/run.sh", "why": "same error cluster as src/core.ts (signature: TS2345)", "symbols": [] },
    { "path": "gone/missing.ts", "why": "named as a seed file in the task descriptor", "symbols": [] } ],
  "dependency_neighborhood": [], "constraints": [], "failed_approaches": [],
  "provenance": { "included_because": {}, "excluded_notable": [] } }
EOF

echo "== 1. CLI contract =="
run --help
eq "--help exits 0" "$RC" "0"
has "--help names the report subcommand" "$OUT" "report"
run
eq "no arguments is refused with exit 2" "$RC" "2"
run report --index "$WORK/does-not-exist.json"
eq "a missing index is refused with exit 2" "$RC" "2"
has "the refusal names the cause" "$ERRTXT" "does-not-exist.json"
run report --index "$WORK/a.json" --frobnicate
eq "an unknown flag is refused with exit 2" "$RC" "2"
run report --index "$WORK/a.json" --capsule "$WORK/nope.json"
eq "a missing capsule is refused with exit 2" "$RC" "2"

echo "== 2. (a) high-signal index => normal + ELIGIBLE =="
run report --index "$WORK/a.json"
eq "high-signal report exits 0" "$RC" "0"
nonempty "high-signal report produced output" "$OUT"
has "state is normal" "$OUT" "RECOMMENDED USE STATE: normal"
has "verdict is ELIGIBLE" "$OUT" "VERDICT: ELIGIBLE"
has "parser coverage counts files with a real extractor" "$OUT" "files with a real extractor: 8/10 (80.0%)"
has "parser coverage is broken out by parser name" "$OUT" "js-ts-regex-v0"
has "no_parser share is reported over the whole index" "$OUT" "no_parser (whole index): 2/10 (20.0%)"
has "symbol coverage is reported" "$OUT" "files with >=1 extracted symbol: 8/10 (80.0%)"
has "test-linkage coverage is reported" "$OUT" "files with >=1 tests_covering entry: 8/10 (80.0%)"
has "the symbols_partial flag is surfaced" "$OUT" "symbols_partial: true"
has "the tests_covering heuristic flag is surfaced" "$OUT" "tests_covering_heuristic: true"
hasnt "a high-signal index is not told to bypass" "$OUT" "RECOMMENDED USE STATE: bypass"

echo "== 3. (b) shell-dominant index => bypass + NOT-ELIGIBLE =="
run report --index "$WORK/b.json"
eq "shell-dominant report exits 0" "$RC" "0"
has "state is bypass" "$OUT" "RECOMMENDED USE STATE: bypass"
has "verdict is NOT-ELIGIBLE" "$OUT" "VERDICT: NOT-ELIGIBLE"
has "the report warns small-because-uninformed" "$OUT" "small-because-uninformed"
has "the report recommends ordinary exploratory execution" "$OUT" "ordinary exploratory execution"
has "no_parser share measured" "$OUT" "no_parser (whole index): 19/20 (95.0%)"
REGIONS="$(sed -n '/NOTABLE UNSUPPORTED REGIONS/,/^== /p' <<<"$OUT")"
has "the blind-spot directory is named by path" "$REGIONS" "build-os/tools"
has "the second blind-spot directory is named by path" "$REGIONS" "docs"
has "the largest blind spot is listed with its file count" "$REGIONS" "12 file(s), none parsed"
hasnt "a directory containing a parsed file is not called a blind spot" "$REGIONS" "build-os/compiler"
has "the bypass derivation shows the fired test" "$OUT" "FIRED"

echo "== 4. (c) thin-signal index => expansion-heavy =="
run report --index "$WORK/c.json"
eq "thin-signal report exits 0" "$RC" "0"
has "state is expansion-heavy" "$OUT" "RECOMMENDED USE STATE: expansion-heavy"
has "thin-signal is still eligible" "$OUT" "VERDICT: ELIGIBLE"
has "expansion budgeting is advised" "$OUT" "expansion"
has "test linkage is zero over ten files" "$OUT" "files with >=1 tests_covering entry: 0/10 (0.0%)"

echo "== 5. (d) empty index => honest unavailable, no crash, no /0 =="
run report --index "$WORK/d.json"
eq "empty-index report exits 0 (no crash)" "$RC" "0"
nonempty "empty-index report produced output" "$OUT"
has "shares print unavailable" "$OUT" "unavailable"
has "the unavailable reason is given" "$OUT" "no denominator"
hasnt "no NaN leaks into the report" "$OUT" "NaN"
hasnt "no Infinity leaks into the report" "$OUT" "Infinity"
hasnt "an empty index does not print a fake 0.0% share" "$OUT" "0/0"
has "an empty index is not claimed to be usable" "$OUT" "RECOMMENDED USE STATE: bypass"
has "an empty index is NOT-ELIGIBLE" "$OUT" "VERDICT: NOT-ELIGIBLE"

echo "== 6. (e) per-item confidence with a capsule =="
run report --index "$WORK/e.json" --capsule "$WORK/capsule_e.json"
eq "capsule report exits 0" "$RC" "0"
CONF="$(sed -n '/CONFIDENCE PER ADMITTED ITEM/,/^== /p' <<<"$OUT")"
ITEMS="$(grep -cE '^  (src|tests|scripts|gone)/' <<<"$CONF")"
eq "every admitted file gets exactly one confidence line" "$ITEMS" "6"
has "seed-symbol + parser + symbols is high" "$CONF" "src/core.ts"
if grep -E '^  src/core\.ts .*\bHIGH\b' <<<"$CONF" >/dev/null; then ok "src/core.ts is HIGH"; else no "src/core.ts is HIGH — got [$(grep -E '^  src/core\.ts' <<<"$CONF")]"; fi
if grep -E '^  scripts/run\.sh .*\bLOW\b' <<<"$CONF" >/dev/null; then ok "error-cluster + no parser is LOW"; else no "error-cluster + no parser is LOW — got [$(grep -E '^  scripts/run\.sh' <<<"$CONF")]"; fi
if grep -E '^  gone/missing\.ts .*\bLOW\b' <<<"$CONF" >/dev/null; then ok "a path absent from the index is LOW"; else no "a path absent from the index is LOW"; fi
if grep -E '^  src/empty\.ts .*\bMEDIUM\b' <<<"$CONF" >/dev/null; then ok "seed file, parsed, no symbols is MEDIUM"; else no "seed file, parsed, no symbols is MEDIUM — got [$(grep -E '^  src/empty\.ts' <<<"$CONF")]"; fi
if grep -E '^  src/helper\.ts .*\bMEDIUM\b' <<<"$CONF" >/dev/null; then ok "neighborhood import with symbols is MEDIUM"; else no "neighborhood import with symbols is MEDIUM"; fi
has "the confidence derivation is stated, not asserted" "$OUT" "derivation"
has "the admitting rule is named per item" "$CONF" "error-cluster"
has "observable facts are printed per item" "$CONF" "parser="
has "confidence carries no invented numeric score" "$OUT" "ordinal"
hasnt "no false-precision confidence score is printed" "$OUT" "confidence score:"
has "the admitted-candidate set drives the amendment number" "$OUT" "admitted-candidate set"
run report --index "$WORK/a.json"
has "without a capsule per-item confidence is unavailable, with a reason" "$OUT" "no capsule was given"

echo "== 7. (f) determinism =="
node "$RPT" report --index "$WORK/e.json" --capsule "$WORK/capsule_e.json" --json >"$WORK/j1.json" 2>/dev/null
node "$RPT" report --index "$WORK/e.json" --capsule "$WORK/capsule_e.json" --json >"$WORK/j2.json" 2>/dev/null
if cmp -s "$WORK/j1.json" "$WORK/j2.json"; then ok "--json is byte-identical across runs"; else no "--json drifted between runs"; fi
if [ -s "$WORK/j1.json" ] && node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$WORK/j1.json"; then
  ok "--json emits parseable, non-empty JSON"
else no "--json did not emit parseable JSON"; fi
JSTATE="$(node -e 'const j=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));process.stdout.write(String(j.recommended_use_state))' "$WORK/j1.json")"
if [ -n "$JSTATE" ]; then ok "--json carries recommended_use_state [$JSTATE]"; else no "--json has no recommended_use_state"; fi
node "$RPT" report --index "$WORK/b.json" >"$WORK/t1.txt" 2>/dev/null
node "$RPT" report --index "$WORK/b.json" >"$WORK/t2.txt" 2>/dev/null
if cmp -s "$WORK/t1.txt" "$WORK/t2.txt"; then ok "text output is byte-identical across runs"; else no "text output drifted between runs"; fi
cat "$WORK/j1.json" >>"$ALL"

echo "== 8. (g) AMENDMENT 1 arithmetic at the boundary =="
run report --index "$WORK/g49.json"
has "49/100 no_parser is ELIGIBLE (just below one half)" "$OUT" "VERDICT: ELIGIBLE"
has "the eligibility line prints the measured number" "$OUT" "49/100 (49.0%)"
has "the eligibility line prints the exact integer test" "$OUT" "2 * 49 = 98"
has "the eligibility line names the amendment" "$OUT" "AMENDMENT 1"
run report --index "$WORK/g50.json"
has "50/100 no_parser is NOT-ELIGIBLE (at one half)" "$OUT" "VERDICT: NOT-ELIGIBLE"
has "the boundary case prints its exact test" "$OUT" "2 * 50 = 100"
has "50/100 at the threshold also yields bypass" "$OUT" "RECOMMENDED USE STATE: bypass"

echo "== 9. (h) no bare percentages anywhere =="
BARE="$(node -e '
const fs=require("fs");
const t=fs.readFileSync(process.argv[1],"utf8");
const stripped=t.replace(/\d+\/\d+ \(\d+\.\d%\)/g,"");
const m=stripped.match(/\d+(\.\d+)?%/g);
process.stdout.write(m?m.join(" | "):"");
' "$ALL")"
CORPUS_REPORTS="$(grep -c 'RECOMMENDED USE STATE' "$ALL")"
if [ "$CORPUS_REPORTS" -ge 5 ]; then ok "the collected report corpus holds $CORPUS_REPORTS real reports"
else no "the collected report corpus holds only $CORPUS_REPORTS reports (grep-negative check would be near-vacuous)"; fi
eq "no bare percentage appears in any report (every share is n/total (pct%))" "$BARE" ""

echo "== 10. honest self-assessment against THIS repository =="
node "$IDXR" build "$SRC" --out "$WORK/self.json" --deterministic 2>/dev/null
if [ -s "$WORK/self.json" ]; then ok "a real index of this repository was built"; else no "could not build a real index of this repository"; fi
STATS="$(node "$IDXR" stats "$WORK/self.json" 2>/dev/null)"
S_NP="$(sed -n 's/^no_parser: \([0-9]*\) (\([0-9.]*%\))$/\1/p' <<<"$STATS")"
S_PCT="$(sed -n 's/^no_parser: \([0-9]*\) (\([0-9.]*%\))$/\2/p' <<<"$STATS")"
S_TOT="$(sed -n 's/^files_indexed: \([0-9]*\)$/\1/p' <<<"$STATS")"
if [ -n "$S_NP" ] && [ -n "$S_TOT" ]; then ok "build-index stats reported no_parser $S_NP of $S_TOT"; else no "could not read no_parser out of build-index stats"; fi
run report --index "$WORK/self.json"
eq "the real report exits 0" "$RC" "0"
has "the reporter derives no_parser exactly as build-index stats does" "$OUT" "no_parser (whole index): $S_NP/$S_TOT ($S_PCT)"
has "this repository is NOT-ELIGIBLE for EXP-0004" "$OUT" "VERDICT: NOT-ELIGIBLE"
has "this repository is told to bypass the compiler" "$OUT" "RECOMMENDED USE STATE: bypass"
has "the real report says a capsule here would be uninformed" "$OUT" "small-because-uninformed"
echo "  MEASURED (this repository): no_parser $S_NP/$S_TOT ($S_PCT)"

echo "== 11. the tool is prepared, not wired =="
CALLERS="$(grep -rlF 'capability/report.mjs' "$SRC/build-os/compiler/compile" "$SRC/build-os/compiler/index" "$SRC/build-os/compiler/runtime" "$SRC/build-os/compiler/verify" 2>/dev/null)"
eq "no existing compiler component calls the capability reporter" "$CALLERS" ""
has "the source states it is prepared but not wired" "$(cat "$RPT")" "NOT WIRED"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
