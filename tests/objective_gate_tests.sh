#!/usr/bin/env bash
# THE VALUE GATE, validated RETROSPECTIVELY against work already done.
#
# The honest test of a prioritisation rule is not that it agrees with itself.
# It is whether, applied to the last four packets, it would have said DEFER to
# the thing that consumed them. So this suite replays the real queue: the anchor
# migration must come out DEFERRED, and the actor-identity proof and the UIC
# benchmark must come out DO_NOW.
#
# A gate that cannot defer genuine, runnable, correct work is not a
# prioritisation gate — it is a rubber stamp with extra steps. Every negative
# case here is real work that really should wait.
set -uo pipefail
cd "$(dirname "$0")/.."
P=0; F=0
ok(){ P=$((P+1)); echo "  ok   $1"; }
no(){ F=$((F+1)); echo "  FAIL $1"; }
t(){ [ "$2" = "$3" ] && ok "$1" || no "$1 (got '$2' want '$3')"; }

g(){ node -e '
import("./build-os/motion/objective.mjs").then(m=>{const r=m.valueGate(JSON.parse(process.argv[1]));
console.log(process.argv[2]==="d"?String(r.do_now):r.disposition);});' "$1" "${2:-x}"; }

echo "== THE RETROSPECTIVE TEST: would it have deferred the last four packets? =="
# The anchor migration. Real debt, correct diagnosis, four packets, one
# regression, one revert — and zero movement on the objective.
ANCHOR='{"id":"anchor-migration","is_debt":true,"runtime_impacting":false,"serves_exit_criteria":[],"cost":"high"}'
t "the anchor migration is NOT do-now" "$(g "$ANCHOR" d)" "false"
t "  it grades OPTIONAL_DEBT — real, and not next" "$(g "$ANCHOR")" "OPTIONAL_DEBT"
CENSUS='{"id":"census-reconciliation","is_debt":true,"runtime_impacting":false,"serves_exit_criteria":[],"cost":"medium"}'
t "the six census mismatches are NOT do-now" "$(g "$CENSUS" d)" "false"
AUDIT='{"id":"more-audit-coverage","is_debt":true,"runtime_impacting":false,"serves_exit_criteria":[],"cost":"medium"}'
t "another assurance detector is NOT do-now" "$(g "$AUDIT" d)" "false"

echo "== and would it have said DO_NOW to what actually matters? =="
t "actor-disambiguated continuity" \
  "$(g '{"id":"actor-identity","blocks_objective":true,"produces_required_evidence":true,"serves_exit_criteria":["EXIT-1"],"cost":"low"}')" "DO_NOW"
t "live self-gate coverage" \
  "$(g '{"id":"self-gating","blocks_objective":true,"serves_exit_criteria":["EXIT-2"],"cost":"medium"}')" "DO_NOW"
t "the fresh UIC benchmark" \
  "$(g '{"id":"uic","blocks_objective":true,"produces_required_evidence":true,"serves_exit_criteria":["EXIT-5"],"cost":"high"}')" "DO_NOW"
# Cost does not veto value: the benchmark is the most expensive item and still first.
t "  high cost does not demote work that blocks the objective" \
  "$(g '{"id":"uic","blocks_objective":true,"serves_exit_criteria":["EXIT-5"],"cost":"high"}' d)" "true"

echo "== a runtime-critical defect outranks everything, criterion or not =="
# An objective cannot be demonstrated on a system that will not run.
t "a runtime-impacting defect is DO_NOW even serving NO criterion" \
  "$(g '{"id":"regression","runtime_impacting":true,"is_debt":true,"serves_exit_criteria":[],"cost":"low"}')" "DO_NOW"

echo "== DEFERRAL IS ABOUT ORDER, NOT VALIDITY =="
# The distinction the substrate lacked: "the debt is real" is an argument for
# recording it, never for doing it ahead of the objective.
REASONS="$(node -e 'import("./build-os/motion/objective.mjs").then(m=>console.log(m.valueGate(JSON.parse(process.argv[1])).reasons.join(" | ")))' "$ANCHOR")"
case "$REASONS" in *"REAL DEBT IS STILL DEFERRABLE"*) ok "the refusal states that genuine debt is still deferrable" ;;
                   *) no "the deferral does not distinguish validity from order" ;; esac

echo "== the ordering puts objective work first, debt last =="
o(){ node -e '
import("./build-os/motion/objective.mjs").then(m=>{const r=m.prioritise(JSON.parse(process.argv[1]));
// Sorted: the CLAIM is "both are deferred", not "in this order". Among equal
// dispositions the gate orders by cost — cheaper debt first — which is
// meaningful for scheduling but not for this assertion.
console.log(process.argv[2]==="d"?r.deferred.slice().sort().join(","):r.do_now.slice().sort().join(","));});' "$1" "${2:-n}"; }
Q="[$ANCHOR,{\"id\":\"uic\",\"blocks_objective\":true,\"serves_exit_criteria\":[\"EXIT-5\"],\"cost\":\"high\"},$CENSUS]"
t "do-now holds only the objective work" "$(o "$Q")" "uic"
t "  and both debt items are deferred" "$(o "$Q" d)" "anchor-migration,census-reconciliation"
t "  ordered cheaper-debt-first among equals, which is scheduling not validity" \
  "$(node -e 'import("./build-os/motion/objective.mjs").then(m=>console.log(m.prioritise(JSON.parse(process.argv[1])).deferred.join(",")))' "$Q")" "census-reconciliation,anchor-migration"

echo "== a queue of ONLY debt is reported, not silently worked =="
# The failure mode being closed: the controller finds SOMETHING runnable and
# proceeds, so a queue containing nothing valuable still looks like progress.
ALLDEBT="[$ANCHOR,$CENSUS]"
t "no do-now candidate when the queue is all debt" "$(o "$ALLDEBT")" ""
t "  and every item is named as deferred" "$(o "$ALLDEBT" d)" "anchor-migration,census-reconciliation"

echo "== the objective is DECLARED, not derived by the worker =="
# A worker that infers its own objective can rationalise any task into it,
# which is the failure being corrected.
node -e 'import("./build-os/motion/objective.mjs").then(m=>{
  const o=m.PRIMARY_OBJECTIVE;
  if(o.declared_by!=="operator") process.exit(1);
  if(!o.exit_criteria.length) process.exit(1);
  if(!o.non_criteria.length) process.exit(1);})' \
  && ok "the objective names its declarer, its exit criteria, and what it explicitly EXCLUDES" \
  || no "the objective is underspecified"
node -e 'import("./build-os/motion/objective.mjs").then(m=>{
  const n=m.PRIMARY_OBJECTIVE.non_criteria.join(" ");
  process.exit(/census|citation|detector/.test(n)?0:1)})' \
  && ok "  and the non-criteria name the exact work this session over-invested in" \
  || no "the non-criteria do not name the deferred work"

echo "== the gate is LOAD-BEARING: continuation selects by value =="
c(){ node -e '
import("./build-os/motion/continuation.mjs").then(m=>{const d=m.continuationDecision(JSON.parse(process.argv[1]));
console.log(process.argv[2]==="v"?(d.value_ordering?d.value_ordering.do_now.join(","):"-"):String(d.next_task));});' "$1" "${2:-n}"; }
# Debt first in queue order, objective work second. Queue order would pick debt.
ST='{"tasks":[{"id":"anchor-migration","status":"pending","is_debt":true,"serves_exit_criteria":[],"cost":"high"},{"id":"uic","status":"pending","blocks_objective":true,"serves_exit_criteria":["EXIT-5"],"cost":"high"}]}'
t "continuation picks the OBJECTIVE task, not the first runnable one" "$(c "$ST")" "uic"
t "  and reports the value ordering it used" "$(c "$ST" v)" "uic"
# With no valuable work, it still continues — deferral orders, it does not halt.
t "a queue of only debt still CONTINUES (deferral orders work, it does not stop it)" \
  "$(node -e 'import("./build-os/motion/continuation.mjs").then(m=>console.log(m.continuationDecision(JSON.parse(process.argv[1])).decision))' '{"tasks":[{"id":"anchor-migration","status":"pending","is_debt":true,"serves_exit_criteria":[],"cost":"high"}]}')" "continue"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
