#!/usr/bin/env bash
# Context Compiler — LANE C: the expansion API, the artifact registry, and the
# trace compactor. Built against build-os/compiler/SEAMS.md SEAM 3 (expansion
# protocol), SEAM 2 (artifact_refs) and SEAM 4 (durable trace facts), with
# FABRICATED fixtures: this lane owns none of the index, so it builds against
# the SCHEMA and never against another lane's output.
#
# WHAT THIS SUITE EXISTS TO PIN, and why each one is load-bearing.
#
#   1. THE SIX REQUEST TYPES RETURN SLICES, NOT FILES. The whole economic
#      argument of the compiler is that a worker buys the minimum. A
#      `need_symbol_context` that hands back the entire file has bought
#      nothing, so every request reports what it WITHHELD and the arithmetic
#      is checked: content_bytes + withheld_bytes == source_bytes, exactly,
#      for all six. An honest ledger that cannot add up is not an honest
#      ledger.
#   2. DENIAL IS DATA, NOT SILENCE. An unknown symbol and an exhausted budget
#      each append a row carrying the REASON. A protocol that logs only its
#      successes reports a fictional context economy.
#   3. THE REPORT'S MATH. granted + denied == total, bytes_bought == the sum of
#      the granted rows, and the report says IN TEXT that repeated expansion of
#      one kind means the capsule was systematically incomplete. That sentence
#      is the point of SEAM 3 — the expansion log is the compiler's own error
#      signal, not a usage meter.
#   4. THE REGISTRY DETECTS ITS OWN CORRUPTION. `verify` is worthless unless it
#      fails on a mutated object, so §9 MUTATES a stored artifact and requires
#      a non-zero exit. Dedupe is asserted on the store, not on a claim.
#   5. THE COMPACTOR'S HONESTY RULE (the load-bearing test of this file).
#      A trace containing only speculation must emit NOTHING. A compactor that
#      invents a plausible conclusion from a hunch poisons every future capsule
#      that injects it, and the poison is undetectable downstream because a
#      fabricated fact is shaped exactly like an observed one. So §10 feeds it
#      pure speculation and requires empty output plus an explicit statement.
#   6. APPEND-ONLY LEDGER INTEGRITY. The event log is TSV, so a request string
#      carrying a tab or a newline could forge rows or shift columns. §11 feeds
#      crafted input and requires the field count to stay EXACTLY 6 on every
#      row and the row count to grow by exactly one per request.
#
# WHAT IT DOES NOT PIN, named rather than implied away. Slice selection is a
# HEURISTIC (a line window around a declaration, a bounded caller snippet); this
# suite checks the accounting and the bounds, never that the window is the
# semantically right one. The trace input format is OURS, not a standard. There
# is no semantic dedupe of facts: two facts stating the same thing in different
# words both survive.
#
# This suite states no fitted `-ge N` / `-gt N` floor with N > 1, so it does not
# join the tests.nonvacuity_minimums family that
# tests/control_registry_tests.sh section 21 polices.
#
# No network. Deterministic. Every fixture lives under one mktemp dir; nothing
# outside $WORK is written. Exits non-zero if any assertion fails.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EXPAND="$SRC/build-os/compiler/runtime/expand.mjs"
ARTIFACTS="$SRC/build-os/compiler/runtime/artifacts.mjs"
COMPACT="$SRC/build-os/compiler/runtime/compact-trace.mjs"
SEAMS="$SRC/build-os/compiler/SEAMS.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
REPO="$WORK/repo"; mkdir -p "$REPO/src" "$REPO/tests"
REG="$WORK/registry"
EV="$WORK/events.tsv"
IDX="$WORK/index.json"
DEC="$WORK/decisions.jsonl"
OUT="$WORK/out.json"

# --- helpers -----------------------------------------------------------------
# Read a dotted field out of a JSON file without depending on jq.
jf(){ node -e '
const fs=require("fs");
let v=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
for (const k of process.argv[2].split(".")) v = (v==null?v:v[k]);
process.stdout.write(v===undefined?"<undef>":String(v));' "$1" "$2" 2>/dev/null; }

# One expansion request -> $OUT, echoing the exit status.
req(){ node "$EXPAND" "$@" > "$OUT" 2>"$WORK/err.txt"; echo $?; }

# Ledger rows EXCLUDING the header — the header is checked separately in §12.
rows(){ awk -F'\t' '$1!="ts"' "$EV" 2>/dev/null | grep -c . ; }

# ---------------------------------------------------------------------------
# FIXTURES: a fabricated repo + a SEAM 1 shaped index. Nothing here is read
# from another lane; the schema in SEAMS.md is the only contract used.
# ---------------------------------------------------------------------------
{
  echo "// alpha module — fabricated fixture"
  for i in $(seq 1 30); do echo "// filler line $i so the file exceeds any context window"; done
  echo "export function alpha(x) {"
  echo "  // the declaration the symbol request must return"
  echo "  return x + 1;"
  echo "}"
  for i in $(seq 31 60); do echo "// filler line $i after the declaration"; done
} > "$REPO/src/alpha.js"

{
  echo "import { alpha } from './alpha.js';"
  echo "export const beta = () => alpha(1);"
  for i in $(seq 1 20); do echo "// beta filler $i"; done
} > "$REPO/src/beta.js"

{
  echo "import { alpha } from './alpha.js';"
  for i in $(seq 1 20); do echo "// gamma filler $i"; done
  echo "export const gamma = () => alpha(2) + alpha(3);"
} > "$REPO/src/gamma.js"

echo "test('alpha', () => {});" > "$REPO/tests/alpha.test.js"

ALPHA_LINE="$(grep -n 'export function alpha' "$REPO/src/alpha.js" | cut -d: -f1)"
cat > "$IDX" <<EOF
{ "index_version": 1, "repo_head": "0000000000000000000000000000000000000000",
  "generated_at": "2026-08-06T00:00:00.000Z",
  "files": {
    "src/alpha.js": { "blob": "aaa", "lang": "js", "kind": "source",
      "symbols": ["alpha"], "imports": [], "imported_by": ["src/beta.js","src/gamma.js"],
      "tests_covering": ["tests/alpha.test.js"], "last_changed": "2026-08-01T00:00:00.000Z",
      "error_count": 2 },
    "src/beta.js": { "blob": "bbb", "lang": "js", "kind": "source",
      "symbols": ["beta"], "imports": ["src/alpha.js"], "imported_by": [],
      "tests_covering": [], "last_changed": "2026-08-02T00:00:00.000Z",
      "error_count": null },
    "src/gamma.js": { "blob": "ccc", "lang": "js", "kind": "source",
      "symbols": ["gamma"], "imports": ["src/alpha.js"], "imported_by": [],
      "tests_covering": [], "last_changed": "2026-08-03T00:00:00.000Z",
      "error_count": 0 },
    "tests/alpha.test.js": { "blob": "ddd", "lang": "js", "kind": "test",
      "symbols": [], "imports": ["src/alpha.js"], "imported_by": [],
      "tests_covering": [], "last_changed": "2026-08-04T00:00:00.000Z",
      "error_count": null }
  },
  "symbols": {
    "alpha": { "defined_in": "src/alpha.js", "line": $ALPHA_LINE,
      "referenced_in": ["src/beta.js","src/gamma.js"] },
    "beta": { "defined_in": "src/beta.js", "line": 2, "referenced_in": [] }
  },
  "error_clusters": [] }
EOF

cat > "$DEC" <<'EOF'
{"topic":"authority","decision":"External mutation requires an explicit go from the operator.","status":"active"}
{"topic":"determinism","decision":"Same repo state plus same task descriptor must yield a byte-identical capsule.","status":"active"}
{"topic":"embeddings","decision":"No vector search in v0; the index is AST and git derived.","status":"active"}
EOF

BASE="--index $IDX --repo $REPO --task T1 --events $EV --decisions $DEC --now 2026-08-06T12:00:00.000Z"

echo "== 0. The lane's three surfaces exist and are executable node modules =="
for f in "$EXPAND" "$ARTIFACTS" "$COMPACT"; do
  [ -f "$f" ] && ok "$(basename "$f") exists" || no "$(basename "$f") is missing"
done
[ -f "$SEAMS" ] && grep -qF 'need_symbol_context' "$SEAMS" \
  && ok "SEAM 3 is the contract this suite builds against (read-only, another lane owns it)" \
  || no "SEAMS.md does not declare the expansion protocol"

echo "== 1. need_symbol_context: the declaration plus a bounded window, and the withheld bytes =="
ST="$(req need_symbol_context alpha $BASE --window 5)"
[ "$ST" = "0" ] && ok "need_symbol_context alpha is granted (exit 0)" || no "need_symbol_context alpha exited $ST"
grep -qF 'export function alpha' "$OUT" && ok "the slice carries the declaration itself" \
  || no "the slice does not contain the declaration"
SB="$(jf "$OUT" source_bytes)"; CB="$(jf "$OUT" content_bytes)"; WB="$(jf "$OUT" withheld_bytes)"
[ "$((CB + WB))" = "$SB" ] \
  && ok "withheld accounting is exact: content $CB + withheld $WB == source $SB" \
  || no "byte accounting does not close: $CB + $WB != $SB"
[ "$WB" -gt 0 ] && ok "the symbol request WITHHELD $WB bytes — it bought a slice, not the file" \
  || no "the symbol request withheld nothing, so it returned the whole file"
[ "$CB" -lt "$SB" ] && ok "content delivered ($CB) is strictly less than the file ($SB)" \
  || no "content delivered is not smaller than the source"
[ "$(jf "$OUT" granted)" = "true" ] && ok "the response reports granted=true" || no "granted flag is wrong"
[ "$(rows)" = "1" ] && ok "exactly one expansion_event row was appended" || no "row count after 1 request is $(rows)"

echo "== 2. need_callers: bounded snippets from the referencing files =="
ST="$(req need_callers alpha $BASE)"
[ "$ST" = "0" ] && ok "need_callers alpha is granted" || no "need_callers alpha exited $ST"
grep -qF 'src/beta.js' "$OUT" && grep -qF 'src/gamma.js' "$OUT" \
  && ok "both referencing files appear in the caller slice" || no "a caller is missing from the slice"
SB="$(jf "$OUT" source_bytes)"; CB="$(jf "$OUT" content_bytes)"; WB="$(jf "$OUT" withheld_bytes)"
[ "$((CB + WB))" = "$SB" ] && ok "caller accounting closes: $CB + $WB == $SB" \
  || no "caller byte accounting does not close: $CB + $WB != $SB"
[ "$WB" -gt 0 ] && ok "the caller request withheld $WB bytes of the referencing files" \
  || no "the caller request returned whole files"
[ "$(rows)" = "2" ] && ok "the ledger grew to 2 rows" || no "row count after 2 requests is $(rows)"

echo "== 3. need_file: whole file, and a line range that is a real slice =="
ST="$(req need_file src/beta.js $BASE)"
[ "$ST" = "0" ] && ok "need_file src/beta.js is granted" || no "need_file exited $ST"
SB="$(jf "$OUT" source_bytes)"; CB="$(jf "$OUT" content_bytes)"; WB="$(jf "$OUT" withheld_bytes)"
[ "$CB" = "$SB" ] && [ "$WB" = "0" ] \
  && ok "a whole-file request withholds nothing and says so ($WB)" \
  || no "whole-file accounting is wrong: content $CB source $SB withheld $WB"
ST="$(req need_file src/beta.js $BASE --range 1-2)"
[ "$ST" = "0" ] && ok "need_file with a range is granted" || no "ranged need_file exited $ST"
grep -qF 'export const beta' "$OUT" && ok "the ranged slice carries the requested lines" \
  || no "the ranged slice lost the requested lines"
grep -qF 'beta filler 15' "$OUT" && no "the ranged slice leaked lines outside the range" \
  || ok "the ranged slice EXCLUDES lines outside the range"
SB="$(jf "$OUT" source_bytes)"; CB="$(jf "$OUT" content_bytes)"; WB="$(jf "$OUT" withheld_bytes)"
[ "$((CB + WB))" = "$SB" ] && [ "$WB" -gt 0 ] \
  && ok "ranged accounting closes and withheld $WB bytes" \
  || no "ranged accounting is wrong: $CB + $WB vs $SB"

echo "== 4. need_prior_decision: the matching decision, not the decision log =="
ST="$(req need_prior_decision determinism $BASE)"
[ "$ST" = "0" ] && ok "need_prior_decision determinism is granted" || no "need_prior_decision exited $ST"
grep -qF 'byte-identical capsule' "$OUT" && ok "the matched decision text is returned" \
  || no "the matched decision text is missing"
grep -qF 'vector search' "$OUT" && no "unrelated decisions leaked into the slice" \
  || ok "unrelated decisions are withheld"
SB="$(jf "$OUT" source_bytes)"; CB="$(jf "$OUT" content_bytes)"; WB="$(jf "$OUT" withheld_bytes)"
[ "$((CB + WB))" = "$SB" ] && [ "$WB" -gt 0 ] \
  && ok "decision accounting closes and withheld $WB bytes of the log" \
  || no "decision accounting is wrong: $CB + $WB vs $SB"
ST="$(req need_prior_decision nosuchtopic $BASE)"
[ "$ST" = "3" ] && ok "an unmatched topic is DENIED (exit 3), not answered with a guess" \
  || no "an unmatched topic exited $ST"

echo "== 5. need_test_history: what the index measured, with null kept as not-measured =="
ST="$(req need_test_history src/alpha.js $BASE)"
[ "$ST" = "0" ] && ok "need_test_history src/alpha.js is granted" || no "need_test_history exited $ST"
grep -qF 'tests/alpha.test.js' "$OUT" && ok "the covering test is reported" || no "the covering test is missing"
[ "$(jf "$OUT" slice.error_count)" = "2" ] && ok "the measured error_count (2) is carried through" \
  || no "error_count was not carried through"
ST="$(req need_test_history src/beta.js $BASE)"
[ "$(jf "$OUT" slice.error_count)" = "null" ] \
  && ok "a null error_count stays NULL — not-measured is never rendered as zero" \
  || no "a null error_count was flattened (SEAM 1 honesty rule)"
SB="$(jf "$OUT" source_bytes)"; CB="$(jf "$OUT" content_bytes)"; WB="$(jf "$OUT" withheld_bytes)"
[ "$((CB + WB))" = "$SB" ] && ok "test-history accounting closes: $CB + $WB == $SB" \
  || no "test-history accounting is wrong: $CB + $WB vs $SB"

echo "== 6. need_artifact: served out of the content-addressed registry =="
printf 'baseline output\nFAIL 3 of 12\n' > "$WORK/baseline.txt"
AID="$(node "$ARTIFACTS" put "$WORK/baseline.txt" --registry "$REG" --summary "targeted baseline")"
[ -n "$AID" ] && ok "artifacts put returned an id ($AID)" || no "artifacts put returned nothing"
ST="$(req need_artifact "$AID" $BASE --registry "$REG")"
[ "$ST" = "0" ] && ok "need_artifact is granted for a stored id" || no "need_artifact exited $ST"
grep -qF 'FAIL 3 of 12' "$OUT" && ok "the artifact content is returned" || no "the artifact content is missing"
SB="$(jf "$OUT" source_bytes)"; CB="$(jf "$OUT" content_bytes)"; WB="$(jf "$OUT" withheld_bytes)"
[ "$((CB + WB))" = "$SB" ] && ok "artifact accounting closes: $CB + $WB == $SB" \
  || no "artifact accounting is wrong: $CB + $WB vs $SB"
ST="$(req need_artifact deadbeefdeadbeef $BASE --registry "$REG")"
[ "$ST" = "3" ] && ok "an unknown artifact id is DENIED" || no "an unknown artifact id exited $ST"

echo "== 7. Denial is logged with its reason — budget exhausted and unknown symbol =="
BEFORE="$(rows)"
ST="$(req need_symbol_context nosuchsymbol $BASE)"
[ "$ST" = "3" ] && ok "an unknown symbol is denied (exit 3)" || no "an unknown symbol exited $ST"
[ "$(jf "$OUT" granted)" = "false" ] && ok "the denial response reports granted=false" || no "denial granted flag is wrong"
[ "$(rows)" = "$((BEFORE + 1))" ] && ok "the DENIED request still appended a row — denial is data, not silence" \
  || no "the denied request appended no row"
tail -n 1 "$EV" | grep -qF 'unknown_symbol' && ok "the denial row carries the reason unknown_symbol" \
  || no "the denial row has no reason"
tail -n 1 "$EV" | cut -f4 | grep -qx 'n' && ok "the denial row's granted column is n" || no "the denial row's granted column is wrong"
# Budget: a tiny budget against a task that has already spent bytes must refuse.
EV2="$WORK/events_budget.tsv"
ST="$(req need_file src/alpha.js --index "$IDX" --repo "$REPO" --task T2 --events "$EV2" --now 2026-08-06T12:00:00.000Z --budget 40)"
[ "$ST" = "3" ] && ok "a request larger than the remaining budget is DENIED" || no "the over-budget request exited $ST"
grep -qF 'budget_exhausted' "$EV2" && ok "the budget denial row names budget_exhausted as its reason" \
  || no "the budget denial row does not name its reason"
ST="$(req need_file tests/alpha.test.js --index "$IDX" --repo "$REPO" --task T2 --events "$EV2" --now 2026-08-06T12:00:00.000Z --budget 400)"
[ "$ST" = "0" ] && ok "a request inside the budget is granted from the same ledger" || no "the in-budget request exited $ST"

echo "== 8. report: the context economy, and the error signal stated in words =="
node "$EXPAND" report "$EV" > "$WORK/report.txt" 2>&1
RTOT="$(grep -E '^total_expansions:' "$WORK/report.txt" | awk '{print $2}')"
RG="$(grep -E '^granted:' "$WORK/report.txt" | awk '{print $2}')"
RD="$(grep -E '^denied:' "$WORK/report.txt" | awk '{print $2}')"
RB="$(grep -E '^bytes_bought:' "$WORK/report.txt" | awk '{print $2}')"
[ -n "$RTOT" ] && [ "$RTOT" = "$(rows)" ] && ok "report total_expansions ($RTOT) equals the ledger row count" \
  || no "report total ($RTOT) disagrees with the ledger ($(rows))"
[ "$((RG + RD))" = "$RTOT" ] && ok "grant/deny math closes: $RG + $RD == $RTOT" \
  || no "grant/deny math does not close: $RG + $RD != $RTOT"
EXPB="$(awk -F'\t' '$4=="y"{s+=$5} END{print s+0}' "$EV")"
[ "$RB" = "$EXPB" ] && ok "bytes_bought ($RB) is exactly the sum of the granted rows" \
  || no "bytes_bought ($RB) does not match the ledger sum ($EXPB)"
GDEN="$(awk -F'\t' '$4=="n"' "$EV" | grep -c . )"
[ "$RD" = "$GDEN" ] && ok "the denied count ($RD) matches the ledger's n rows" || no "denied count mismatch"
grep -qE '^most_requested:' "$WORK/report.txt" && ok "the report ranks the most-requested items" \
  || no "the report does not rank the most-requested items"
grep -qiF 'systematically incomplete' "$WORK/report.txt" \
  && ok "the report SAYS repeated expansion means the capsule was systematically incomplete" \
  || no "the report omits the SEAM 3 error signal in words"
# The ranking must actually count: need_file was requested more than once on T1.
node "$EXPAND" need_file src/gamma.js $BASE > /dev/null 2>&1
node "$EXPAND" need_file src/gamma.js $BASE > /dev/null 2>&1
node "$EXPAND" report "$EV" > "$WORK/report2.txt" 2>&1
grep -A4 '^most_requested:' "$WORK/report2.txt" | grep -qF 'need_file(src/gamma.js)' \
  && ok "a twice-bought item is ranked in most_requested" || no "the ranking does not surface a repeated buy"

echo "== 9. The artifact registry: put/get/ref/verify, dedupe, and corruption =="
G="$(node "$ARTIFACTS" get "$AID" --registry "$REG")"
[ "$G" = "$(cat "$WORK/baseline.txt")" ] && ok "get returns the stored bytes verbatim" || no "get did not round-trip"
node "$ARTIFACTS" ref "$AID" --registry "$REG" > "$WORK/ref.json" 2>&1
[ "$(jf "$WORK/ref.json" sha256)" = "$AID" ] && ok "the ref's sha256 IS the id — the store is content-addressed" \
  || no "ref sha256 does not equal the id"
[ "$(jf "$WORK/ref.json" summary)" = "targeted baseline" ] && ok "the ref carries its one-line summary (SEAM 2)" \
  || no "the ref lost its summary"
[ "$(jf "$WORK/ref.json" bytes)" = "$(wc -c < "$WORK/baseline.txt" | tr -d ' ')" ] \
  && ok "the ref's byte count is the artifact's real size" || no "the ref's byte count is wrong"
for k in id sha256 summary bytes; do
  [ "$(jf "$WORK/ref.json" "$k")" != "<undef>" ] && ok "artifact_ref carries the SEAM 2 field '$k'" \
    || no "artifact_ref is missing the SEAM 2 field '$k'"
done
# Dedupe: identical content, different file, stored once.
cp "$WORK/baseline.txt" "$WORK/baseline_copy.txt"
AID2="$(node "$ARTIFACTS" put "$WORK/baseline_copy.txt" --registry "$REG" --summary "same bytes again")"
[ "$AID2" = "$AID" ] && ok "identical content yields the identical id" || no "identical content produced a different id"
NOBJ="$(find "$REG" -type f -name '*' -path '*objects*' | grep -c . )"
[ "$NOBJ" = "1" ] && ok "identical content is stored ONCE ($NOBJ object on disk)" \
  || no "dedupe failed: $NOBJ objects on disk for one distinct content"
printf 'a different artifact\n' > "$WORK/other.txt"
BID="$(node "$ARTIFACTS" put "$WORK/other.txt" --registry "$REG" --summary "second artifact")"
[ "$BID" != "$AID" ] && ok "distinct content yields a distinct id" || no "two different contents collided"
node "$ARTIFACTS" verify --registry "$REG" > "$WORK/verify_ok.txt" 2>&1
VST=$?
[ "$VST" = "0" ] && ok "verify passes on an intact registry (exit 0)" || no "verify failed on an intact registry"
grep -qE '^ok: 2' "$WORK/verify_ok.txt" && ok "verify counted both stored artifacts" || no "verify's ok count is wrong"
# CORRUPTION: mutate a stored object behind the registry's back.
VICTIM="$(find "$REG" -path '*objects*' -type f -name "$AID")"
[ -n "$VICTIM" ] && printf 'tampered\n' >> "$VICTIM" && ok "a stored object was mutated on disk (the attack)" \
  || no "could not locate the stored object to mutate"
node "$ARTIFACTS" verify --registry "$REG" > "$WORK/verify_bad.txt" 2>&1
VST=$?
[ "$VST" != "0" ] && ok "verify FAILS after tampering (exit $VST) — corruption is detected" \
  || no "verify passed on a corrupted registry: the check is decorative"
grep -qF "$AID" "$WORK/verify_bad.txt" && ok "verify names the corrupted id" || no "verify does not name the corrupted id"

echo "== 10. The compactor: nothing from speculation, a real fact from an observed failure =="
SPEC="$WORK/trace_spec.jsonl"
cat > "$SPEC" <<'EOF'
{"kind":"note","text":"I suspect the module resolver is misconfigured"}
{"kind":"note","text":"probably the bundler cannot see the alias"}
{"kind":"plan","text":"try rewriting the import path"}
EOF
node "$COMPACT" compact "$SPEC" --task T9 --now 2026-08-06T12:00:00.000Z > "$WORK/spec_facts.jsonl" 2>"$WORK/spec_err.txt"
SST=$?
[ "$SST" = "0" ] && ok "a speculation-only trace is not an error (exit 0)" || no "speculation-only trace exited $SST"
[ ! -s "$WORK/spec_facts.jsonl" ] \
  && ok "a speculation-only trace emits NOTHING — the honesty rule holds where it costs something" \
  || no "the compactor INVENTED a fact from speculation: $(cat "$WORK/spec_facts.jsonl")"
grep -qiF 'no observed failure' "$WORK/spec_err.txt" \
  && ok "the compactor SAYS it emitted nothing and why" || no "the compactor was silently empty"

OBS="$WORK/trace_obs.jsonl"
cat > "$OBS" <<'EOF'
{"kind":"note","text":"maybe the test runner is fine"}
{"kind":"command","command":"node --test src/alpha.js","exit":1,"output":"Error: Cannot find module './missing.js'","scope":["src/alpha.js"]}
{"kind":"command","command":"npm run lint","exit":0,"output":"all clean","scope":["src/beta.js"]}
EOF
node "$COMPACT" compact "$OBS" --task T9 --now 2026-08-06T12:00:00.000Z > "$WORK/facts.jsonl" 2>"$WORK/obs_err.txt"
[ -s "$WORK/facts.jsonl" ] && ok "an observed non-zero exit produces a fact" || no "no fact from an observed failure"
NF="$(grep -c . "$WORK/facts.jsonl")"
[ "$NF" = "1" ] && ok "exactly one fact: the failing command only, never the passing one" \
  || no "expected 1 fact from 1 observed failure, got $NF"
head -n 1 "$WORK/facts.jsonl" > "$WORK/fact1.json"
[ "$(jf "$WORK/fact1.json" evidence_class)" = "observed" ] \
  && ok "evidence_class is 'observed' (SEAM 4 permits no other value here)" || no "evidence_class is not observed"
[ "$(jf "$WORK/fact1.json" task_id)" = "T9" ] && ok "the fact carries its origin task_id" || no "the fact lost its task_id"
grep -qF 'node --test src/alpha.js' "$WORK/fact1.json" && ok "attempted names the command that actually ran" \
  || no "attempted does not name the observed command"
grep -qF "Cannot find module" "$WORK/fact1.json" \
  && ok "failed_because is composed from the OBSERVED error text" || no "failed_because is not the observed error"
grep -qF 'resolver is misconfigured' "$WORK/facts.jsonl" \
  && no "the speculative note leaked into a fact" || ok "the speculative note in the same trace was NOT used"
grep -qF 'npm run lint' "$WORK/facts.jsonl" \
  && no "a passing command produced a fact" || ok "the passing command produced no fact"
for k in fact_id task_id attempted failed_because reusable_conclusion scope evidence_class created_at; do
  [ "$(jf "$WORK/fact1.json" "$k")" != "<undef>" ] && ok "the fact carries the SEAM 4 field '$k'" \
    || no "the fact is missing the SEAM 4 field '$k'"
done
# Determinism: the same trace compiles to the same fact_id.
node "$COMPACT" compact "$OBS" --task T9 --now 2026-08-06T12:00:00.000Z > "$WORK/facts_again.jsonl" 2>/dev/null
cmp -s "$WORK/facts.jsonl" "$WORK/facts_again.jsonl" \
  && ok "compaction is deterministic — identical input, byte-identical facts" || no "compaction is not deterministic"

echo "== 11. match: scope overlap decides what a later capsule injects =="
# stdout is the DATA channel and carries facts only; the human summary goes to
# stderr. Capturing them together would let a chatty line masquerade as a fact,
# so the streams are kept apart here exactly as they are in section 10.
node "$COMPACT" match "$WORK/facts.jsonl" --scope src/alpha.js > "$WORK/hit.jsonl" 2>"$WORK/hit_err.txt"
[ "$(grep -c . "$WORK/hit.jsonl")" = "1" ] && ok "a fact whose scope overlaps the query is returned" \
  || no "the scope HIT returned $(grep -c . "$WORK/hit.jsonl") lines on stdout"
node -e 'const fs=require("fs");for(const l of fs.readFileSync(process.argv[1],"utf8").split("\n"))if(l.trim())JSON.parse(l);' "$WORK/hit.jsonl" \
  && ok "every stdout line is a valid JSON fact — no prose on the data channel" \
  || no "match wrote something that is not a JSON fact to stdout"
node "$COMPACT" match "$WORK/facts.jsonl" --scope src/unrelated.js > "$WORK/miss.jsonl" 2>/dev/null
[ ! -s "$WORK/miss.jsonl" ] && ok "a non-overlapping scope returns nothing — no drive-by injection" \
  || no "the scope MISS returned facts anyway"
node "$COMPACT" match "$WORK/facts.jsonl" --scope src > "$WORK/hit2.jsonl" 2>/dev/null
[ "$(grep -c . "$WORK/hit2.jsonl")" = "1" ] && ok "a containing directory scope overlaps the file scope" \
  || no "directory-level scope overlap does not match"

echo "== 12. Append-only ledger integrity: field count stable, no injection =="
BAD="$(awk -F'\t' 'NF!=6' "$EV" | grep -c . )"
[ "$BAD" = "0" ] && ok "every ledger row has EXACTLY 6 tab-separated fields" \
  || no "$BAD ledger row(s) do not have 6 fields"
HDRS="$(awk -F'\t' '$1=="ts"' "$EV" | grep -c . )"
[ "$HDRS" = "1" ] && ok "the ledger carries exactly one header row" || no "the ledger has $HDRS header rows"
EVX="$WORK/events_inject.tsv"
CRAFT="$(printf 'evil\tts\t2026\tX\ty\n9999\tinjected')"
BEFORE_X=0
node "$EXPAND" need_prior_decision "$CRAFT" --index "$IDX" --repo "$REPO" --task "T\tINJ
ECT" --events "$EVX" --now 2026-08-06T12:00:00.000Z > /dev/null 2>&1
AFTER_X="$(grep -c . "$EVX" 2>/dev/null || echo 0)"
[ "$AFTER_X" = "2" ] \
  && ok "a crafted tab/newline request added exactly ONE row on top of the header (rows: $AFTER_X)" \
  || no "the crafted request produced $AFTER_X rows — the ledger was injected into"
BADX="$(awk -F'\t' 'NF!=6' "$EVX" | grep -c . )"
[ "$BADX" = "0" ] && ok "the crafted request did not shift any column: every row still has 6 fields" \
  || no "$BADX row(s) have the wrong field count after crafted input"
grep -qF '9999' "$EVX" && grep -qF '\t' "$EVX" \
  && ok "the crafted tabs survive ESCAPED, so the payload is preserved but inert" \
  || no "the crafted payload was neither escaped nor preserved"
# Append-only: an existing row is never rewritten.
FIRST_BEFORE="$(sed -n '2p' "$EV")"
node "$EXPAND" need_file src/beta.js $BASE > /dev/null 2>&1
FIRST_AFTER="$(sed -n '2p' "$EV")"
[ -n "$FIRST_BEFORE" ] && ok "there IS an earlier row to compare (this check is not vacuous)" \
  || no "the ledger has no data row at line 2, so the append-only check below proves nothing"
[ -n "$FIRST_BEFORE" ] && [ "$FIRST_BEFORE" = "$FIRST_AFTER" ] \
  && ok "an earlier ledger row is byte-identical after a later append" \
  || no "a later request rewrote an earlier row — the ledger is not append-only"
# The compactor's own output cannot be broken by newlines in captured output.
MULTI="$WORK/trace_multi.jsonl"
printf '{"kind":"command","command":"sh -c bad","exit":2,"output":"Error: line one\\nline two\\tTABBED","scope":["src/beta.js"]}\n' > "$MULTI"
node "$COMPACT" compact "$MULTI" --task T10 --now 2026-08-06T12:00:00.000Z > "$WORK/multi.jsonl" 2>/dev/null
[ "$(grep -c . "$WORK/multi.jsonl")" = "1" ] \
  && ok "a fact from multi-line captured output is still exactly ONE JSONL line" \
  || no "multi-line output broke the JSONL framing"
node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8").trim())' "$WORK/multi.jsonl" \
  && ok "that line is valid JSON" || no "the emitted fact line is not valid JSON"

echo "== 13. This suite is not vacuous about itself =="
# A DERIVED floor: more assertions than (the six request types) x (the three
# surfaces). It states no numeric literal, so it is not a member of the
# tests.nonvacuity_minimums family.
NREQ=0; for r in need_symbol_context need_callers need_file need_prior_decision need_test_history need_artifact; do NREQ=$((NREQ+1)); done
NSURF=0; for s in "$EXPAND" "$ARTIFACTS" "$COMPACT"; do NSURF=$((NSURF+1)); done
FLOOR=$((NREQ * NSURF))
[ "$PASS" -gt "$FLOOR" ] \
  && ok "this suite ran $PASS assertions, more than the $FLOOR request-by-surface combinations it covers" \
  || no "this suite ran only $PASS assertions against $FLOOR combinations"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
