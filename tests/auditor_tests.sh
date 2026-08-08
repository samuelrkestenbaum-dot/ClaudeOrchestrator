#!/usr/bin/env bash
# AUDITING THE AUDITORS. This suite has an awkward property worth stating: it
# is itself a check, and everything it says about checks applies to it. So it
# is written to fail — each state is reached by construction, and the shelf-life
# case really does modify a guarded file rather than asserting that it would.
set -uo pipefail
cd "$(dirname "$0")/.."
P=0; F=0
ok(){ P=$((P+1)); echo "  ok   $1"; }
no(){ F=$((F+1)); echo "  FAIL $1"; }
t(){ [ "$2" = "$3" ] && ok "$1" || no "$1 (got '$2' want '$3')"; }

g(){ node -e '
import("./build-os/audit/check-registry.mjs").then(m=>{const r=m.gradeCheck(JSON.parse(process.argv[1]));
console.log(process.argv[2]==="t"?String(r.trustworthy):(process.argv[2]==="w"?String(r.warnings.length):r.confidence));});' "$1" "${2:-c}"; }

BASE='"id":"x","guards":"g","source_read":"s","authoritative_source":"s","assertion_kind":"invariant","failure_proof":"m","proof_taken_at":"A","source_fingerprint_now":"A","owner_suite":"o","drift_risk":"d"'

echo "== every confidence state must be REACHABLE, or the ladder is decorative =="
t "PROVEN"       "$(g "{$BASE,\"source_is_authoritative\":true,\"failure_demonstrated\":true}")"  "PROVEN"
t "UNPROVEN"     "$(g "{$BASE,\"source_is_authoritative\":true,\"failure_demonstrated\":false}")" "UNPROVEN"
t "VACUOUS"      "$(g "{$BASE,\"source_is_authoritative\":true,\"failure_demonstrated\":false,\"mutation_applied\":true}")" "VACUOUS"
t "DISCONNECTED" "$(g "{$BASE,\"source_is_authoritative\":false,\"failure_demonstrated\":true}")" "DISCONNECTED"
t "STALE_PROOF"  "$(g "{\"id\":\"x\",\"guards\":\"g\",\"source_read\":\"s\",\"authoritative_source\":\"s\",\"assertion_kind\":\"invariant\",\"failure_proof\":\"m\",\"owner_suite\":\"o\",\"drift_risk\":\"d\",\"source_is_authoritative\":true,\"failure_demonstrated\":true,\"proof_taken_at\":\"A\",\"source_fingerprint_now\":\"B\"}")" "STALE_PROOF"

echo "== only PROVEN is trustworthy =="
for s in UNPROVEN VACUOUS DISCONNECTED; do :; done
t "PROVEN is trustworthy" "$(g "{$BASE,\"source_is_authoritative\":true,\"failure_demonstrated\":true}" t)" "true"
t "STALE_PROOF is NOT trustworthy" "$(g "{\"id\":\"x\",\"guards\":\"g\",\"source_read\":\"s\",\"authoritative_source\":\"s\",\"assertion_kind\":\"invariant\",\"failure_proof\":\"m\",\"owner_suite\":\"o\",\"drift_risk\":\"d\",\"source_is_authoritative\":true,\"failure_demonstrated\":true,\"proof_taken_at\":\"A\",\"source_fingerprint_now\":\"B\"}" t)" "false"
t "UNPROVEN is NOT trustworthy" "$(g "{$BASE,\"source_is_authoritative\":true,\"failure_demonstrated\":false}" t)" "false"
# VACUOUS ranks BELOW UNPROVEN deliberately: an untested check might work, one
# proven incapable of failing spends reviewer trust and returns none.
t "VACUOUS ranks below UNPROVEN" "$(node -e 'import("./build-os/audit/check-registry.mjs").then(m=>console.log(String(m.CONFIDENCE.indexOf("VACUOUS")<m.CONFIDENCE.indexOf("UNPROVEN"))))')" "true"

echo "== a snapshot assertion is flagged EVEN WHEN PROVEN =="
# Three tests in this repo asserted a count and passed until the count changed.
SNAP="{\"id\":\"x\",\"guards\":\"g\",\"source_read\":\"s\",\"authoritative_source\":\"s\",\"assertion_kind\":\"snapshot\",\"failure_proof\":\"m\",\"proof_taken_at\":\"A\",\"source_fingerprint_now\":\"A\",\"owner_suite\":\"o\",\"drift_risk\":\"d\",\"source_is_authoritative\":true,\"failure_demonstrated\":true}"
t "still grades PROVEN" "$(g "$SNAP")" "PROVEN"
t "  but carries a warning anyway" "$(g "$SNAP" w)" "1"

echo "== unrecorded fields downgrade nothing silently — they WARN =="
t "a check missing fields is warned about" "$(g '{"id":"x","source_is_authoritative":true,"failure_demonstrated":true,"proof_taken_at":"A","source_fingerprint_now":"A"}' w)" "1"

echo "== THE SHELF LIFE: a moved source really does expire the proof =="
# This is the whole premise, so it is exercised against a REAL file rather than
# a synthetic fingerprint pair.
r(){ node -e '
Promise.all([import("./build-os/audit/check-registry.mjs"),import("./build-os/audit/checks.mjs")]).then(([a,c])=>{
const r=a.auditChecks(c.resolvedChecks());
const g=r.grades.find(x=>x.id===process.argv[1]);
console.log(process.argv[2]==="n"?String(r.trustworthy):g.confidence);});' "$1" "${2:-c}"; }
t "the continuity rule is PROVEN at the pinned fingerprint" "$(r continuity.evidence-ref-required)" "PROVEN"
BEFORE="$(r x n)"
cp build-os/surfaces/continuity.mjs /tmp/claude-0/-home-user/5489b495-ae3d-5612-a4e1-61b4b5c6b6e4/scratchpad/shelf.bak
printf '\n// shelf-life probe\n' >> build-os/surfaces/continuity.mjs
t "  editing the guarded source expires it to STALE_PROOF" "$(r continuity.evidence-ref-required)" "STALE_PROOF"
AFTER="$(r x n)"
cp /tmp/claude-0/-home-user/5489b495-ae3d-5612-a4e1-61b4b5c6b6e4/scratchpad/shelf.bak build-os/surfaces/continuity.mjs
t "  and reverting restores it" "$(r continuity.evidence-ref-required)" "PROVEN"
[ "$AFTER" -lt "$BEFORE" ] && ok "  the trustworthy count DROPS when a source moves ($BEFORE -> $AFTER)" \
  || no "trustworthy count drops when a source moves (got $BEFORE -> $AFTER)"

echo "== the real registry, reported honestly =="
t "the audit does not claim every check is trustworthy" \
  "$(node -e 'Promise.all([import("./build-os/audit/check-registry.mjs"),import("./build-os/audit/checks.mjs")]).then(([a,c])=>{const r=a.auditChecks(c.resolvedChecks());console.log(String(r.trustworthy<r.checks))})')" "true"
t "  and each untrustworthy check is named, not just counted" \
  "$(node -e 'Promise.all([import("./build-os/audit/check-registry.mjs"),import("./build-os/audit/checks.mjs")]).then(([a,c])=>{const r=a.auditChecks(c.resolvedChecks());console.log(String(r.not_trustworthy.length===r.checks-r.trustworthy&&r.not_trustworthy.every(x=>x.id&&x.why)))})')" "true"
t "  the coverage caveat is carried, since unregistered checks are invisible" \
  "$(node -e 'Promise.all([import("./build-os/audit/check-registry.mjs"),import("./build-os/audit/checks.mjs")]).then(([a,c])=>{const r=a.auditChecks(c.resolvedChecks());console.log(String(/never told about/.test(r.coverage_caveat)))})')" "true"

echo "== an empty registry must not read as success =="
t "zero checks is zero trustworthy, not a pass" \
  "$(node -e 'import("./build-os/audit/check-registry.mjs").then(m=>{const r=m.auditChecks([]);console.log(String(r.trustworthy))})')" "0"

echo "== FULL-SUITE STATUS: a truncated run has no total =="
# The rule this encodes: "most of the suite ran" may not quietly become "the
# suite passes". It is the check auditor's discipline one level up -- there, a
# check that never demonstrated a failure is UNPROVEN however often it passed.
ss(){ node -e '
import("./build-os/audit/suite-status.mjs").then(m=>{const r=m.suiteStatus(JSON.parse(process.argv[1]));
console.log(process.argv[2]==="p"?String(r.passed):(process.argv[2]==="g"?String(r.green):(process.argv[2]==="c"?r.ceiling_verdict.split(" ")[0]:r.status)));});' "$1" "${2:-s}"; }
CUT='{"suite":"x","completed":false,"exit_code":124,"ceiling_s":280,"passed":4473}'
t "a timed-out run is TRUNCATED, never green" "$(ss "$CUT")" "TRUNCATED"
t "  and it is not green" "$(ss "$CUT" g)" "false"
# THE SUBSTITUTION BEING FORBIDDEN: a partial count must not survive as a total.
t "  a truncated run reports NO pass count, even when one was offered" "$(ss "$CUT" p)" "null"
t "  and the ceiling verdict is withheld until a full run is measured" "$(ss "$CUT" c)" "UNKNOWN"
t "a completed run with failures is FAILING, not green"   "$(ss '{"suite":"x","completed":true,"passed":4473,"failed":75,"wall_clock_s":536,"ceiling_s":280,"runs_completed":1}')" "FAILING"
t "  a completed clean run is GREEN"   "$(ss '{"suite":"x","completed":true,"passed":10,"failed":0,"wall_clock_s":5,"ceiling_s":280,"runs_completed":1}')" "GREEN"
t "  a RESULT line with no recorded completed run is UNPROVEN"   "$(ss '{"suite":"x","completed":true,"passed":10,"failed":0,"runs_completed":0}')" "UNPROVEN"
t "  an over-ceiling completed run marks the ceiling OBSOLETE"   "$(ss '{"suite":"x","completed":true,"passed":10,"failed":0,"wall_clock_s":536,"ceiling_s":280,"runs_completed":1}' c)" "OBSOLETE"
t "one completed run is not a determinism claim"   "$(node -e 'import("./build-os/audit/suite-status.mjs").then(m=>console.log(String(/SINGLE RUN/.test(m.suiteStatus({completed:true,passed:1,failed:0,runs_completed:1}).determinism))))')" "true"

echo "== the recorded run is represented honestly =="
t "build_os_tests.sh is on record as FAILING, not green"   "$(node -e 'Promise.all([import("./build-os/audit/suite-status.mjs"),import("node:fs")]).then(([m,fs])=>{
const j=JSON.parse(fs.readFileSync("build-os/audit/suite-runs.json","utf8"));
console.log(m.suiteStatus(j.runs.find(r=>r.suite==="tests/build_os_tests.sh")).status)})')" "FAILING"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
