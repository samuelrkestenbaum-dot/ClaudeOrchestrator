#!/usr/bin/env bash
# The stopping gate must REFUSE premature concessions and ALLOW genuine ones.
# A gate that only ever blocks is as useless as one that never does.
set -uo pipefail
cd "$(dirname "$0")/.."
P=0; F=0
ok(){ P=$((P+1)); echo "  ok   $1"; }
no(){ F=$((F+1)); echo "  FAIL $1"; }
t(){ [ "$2" = "$3" ] && ok "$1" || no "$1 (got '$2' want '$3')"; }
g(){ node -e '
Promise.all([import("./build-os/motion/concession-gate.mjs"),import("./build-os/motion/capability-map.mjs")]).then(([m,c])=>{
 const ev=JSON.parse(process.argv[1]); const o=JSON.parse(process.argv[2]||"{}");
 if(ev.__enumerate) ev.other_surface_may_hold_capability=c.enumerateCapability(ev.__enumerate,"claude");
 console.log(m.concessionGate(ev,o).verdict);});' "$1" "${2:-{\}}"; }

FULL='{"proposed_concession":"x","concession_class":"blocked","available_interfaces":["Bash"],"paths_attempted":["a","b"],"attempt_results":["r1","r2"],"workaround_classes_considered":["w"],"why_each_viable_workaround_failed":"reason"'

echo "== the real regression case: the false #49 concession =="
t "prose instead of an enumeration is REFUSED" \
  "$(g "$FULL,\"other_surface_may_hold_capability\":\"I concluded none was reachable\"}")" "continue_search"
t "enumeration finding a holder is REFUSED" \
  "$(g "$FULL,\"__enumerate\":\"operator_lab_write\"}")" "continue_search"

echo "== genuine block must be ALLOWED =="
NOHOLDER='"other_surface_may_hold_capability":{"enumerated":true,"surfaces_with_capability":[]}'
t "complete evidence, no holder anywhere: concession allowed" "$(g "$FULL,$NOHOLDER}")" "concession_allowed"

echo "== incompleteness always blocks =="
for f in proposed_concession available_interfaces paths_attempted workaround_classes_considered; do
  STRIPPED="$(node -e 'const o=JSON.parse(process.argv[1]+",\"other_surface_may_hold_capability\":{\"enumerated\":true,\"surfaces_with_capability\":[]}}");delete o[process.argv[2]];console.log(JSON.stringify(o))' "$FULL" "$f")"
  t "missing '$f' blocks" "$(g "$STRIPPED")" "continue_search"
done
t "an unregistered concession_class blocks" \
  "$(g "$(node -e 'const o=JSON.parse(process.argv[1]+",\"other_surface_may_hold_capability\":{\"enumerated\":true,\"surfaces_with_capability\":[]}}");o.concession_class="just_tired";console.log(JSON.stringify(o))' "$FULL")")" "continue_search"
t "listed paths without results blocks (a plan is not an attempt)" \
  "$(g "$(node -e 'const o=JSON.parse(process.argv[1]+",\"other_surface_may_hold_capability\":{\"enumerated\":true,\"surfaces_with_capability\":[]}}");o.attempt_results=["only-one"];console.log(JSON.stringify(o))' "$FULL")")" "continue_search"

echo "== loop protection: exhaustion must terminate =="
BLOCKING="$FULL,\"__enumerate\":\"operator_lab_write\"}"
t "round 3 of 3 concedes rather than looping forever" "$(g "$BLOCKING" '{"round":3,"maxRounds":3}')" "concession_allowed"
t "a round surfacing no NEW path concedes (search converged)" \
  "$(g "$BLOCKING" '{"round":2,"attemptedSignatures":["a","b"]}')" "concession_allowed"
t "a round WITH a new path keeps searching" \
  "$(g "$BLOCKING" '{"round":2,"attemptedSignatures":["a"]}')" "continue_search"

echo "== live Stop hook, DRAINED queue: the concession check is what decides =="
# The two gates compose in a fixed order — continuation first, concession
# second — so a suite that exercises the concession path against the REAL queue
# measures the continuation refusal instead and proves nothing about
# concessions. These cases therefore run against a project root whose queue
# holds no open work, which is the only state in which the concession check is
# the one that governs the outcome.
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
mkdir -p "$T/build-os/motion"
ln -s "$PWD/build-os/motion/gate-stop.mjs" "$T/build-os/motion/gate-stop.mjs"
echo '{"tasks":[{"id":"49","status":"completed"}]}' > "$T/build-os/motion/queue.json"
printf '%s\n' '{"message":{"role":"assistant","content":[{"type":"text","text":"I cannot do this. It is blocked."}]}}' > "$T/c.jsonl"
printf '{"transcript_path":"%s/c.jsonl"}' "$T" | CLAUDE_PROJECT_DIR="$T" bash .claude/hooks/concession-gate.sh >/dev/null 2>"$T/e"
t "Stop hook refuses a bare concession" "$?" "2"
grep -q "surfaces observed to hold" "$T/e" && ok "the refusal TELLS the worker where the capability lives" || no "refusal carries recovery guidance"
printf '%s\n' '{"message":{"role":"assistant","content":[{"type":"text","text":"Done. 42 tests pass."}]}}' > "$T/o.jsonl"
printf '{"transcript_path":"%s/o.jsonl"}' "$T" | CLAUDE_PROJECT_DIR="$T" bash .claude/hooks/concession-gate.sh >/dev/null 2>&1
t "Stop hook allows a non-conceding turn once the queue is drained" "$?" "0"

echo "== continuation controller: task completion is NOT a stop condition =="
c(){ node -e '
import("./build-os/motion/continuation.mjs").then(m=>{const d=m.continuationDecision(JSON.parse(process.argv[1]));
console.log(process.argv[2]==="next"?String(d.next_task):(process.argv[2]==="term"?String(d.terminal_condition):d.decision));});' "$1" "${2:-dec}"; }
Q='{"published_tips":["8bc4739"],"tasks":[{"id":"49","status":"completed"},{"id":"50","status":"pending","depends_on":["49"]},{"id":"51","status":"pending","depends_on":["50"]}]}'

t "THE REGRESSION: finished task + committed + stop fires => CONTINUE" "$(c "$Q")" "continue"
t "and it selects #50, not #51" "$(c "$Q" next)" "50"
t "#51 stays queued behind #50" "$(c '{"tasks":[{"id":"50","status":"pending"},{"id":"51","status":"pending","depends_on":["50"]}]}' next)" "50"
t "an unpushed commit alone does NOT stop work" \
  "$(c '{"published_tips":[],"tasks":[{"id":"49","status":"completed"},{"id":"50","status":"pending","depends_on":["49"]}]}')" "continue"
t "but a task REQUIRING publication waits for it" \
  "$(c '{"published_tips":[],"tasks":[{"id":"50","status":"pending","requires_publication_of":["abc123"]}]}')" "continue"

echo "== genuine terminal conditions must ALLOW the stop =="
t "explicit operator stop" "$(c '{"operator_stop":true,"tasks":[{"id":"50","status":"pending"}]}')" "stop"
t "  reason recorded" "$(c '{"operator_stop":true,"tasks":[{"id":"50","status":"pending"}]}' term)" "explicit_operator_stop"
t "empty queue" "$(c '{"tasks":[{"id":"49","status":"completed"}]}')" "stop"
t "safety/authority forbids" "$(c '{"safety_stop":true,"tasks":[{"id":"50","status":"pending"}]}')" "stop"
t "environment terminating" "$(c '{"environment_terminating":true,"tasks":[{"id":"50","status":"pending"}]}')" "stop"
t "all remaining genuinely blocked WITH exhaustion evidence" \
  "$(c '{"tasks":[{"id":"50","status":"pending","blocked_evidence":{"verdict":"concession_allowed"}}]}')" "stop"
t "  but blocked WITHOUT exhaustion evidence keeps going" \
  "$(c '{"tasks":[{"id":"50","status":"pending","depends_on":["99"]}]}')" "continue"

echo "== loop protection =="
t "the same task selected twice with no state change is escalated past" \
  "$(c '{"tasks":[{"id":"50","status":"pending"},{"id":"51","status":"pending"}],"transition_log":[{"next_task":"50","state_changed":false},{"next_task":"50","state_changed":false}]}' next)" "51"

echo "== live Stop hook consults continuation, not only concessions =="
T2=$(mktemp -d)
printf '%s\n' '{"message":{"role":"assistant","content":[{"type":"text","text":"Done. 59 tests pass. Nothing is running."}]}}' > "$T2/n.jsonl"
printf '{"transcript_path":"%s/n.jsonl"}' "$T2" | CLAUDE_PROJECT_DIR="$PWD" bash .claude/hooks/concession-gate.sh >/dev/null 2>"$T2/e"
t "a NON-conceding completion turn is refused while work remains" "$?" "2"
grep -q "NEXT RUNNABLE TASK" "$T2/e" && ok "the refusal NAMES the next task" || no "refusal names the next task"

# THE ORDERING IS PART OF THE CONTRACT, so it is asserted rather than assumed.
# A conceding turn taken while work remains must be refused for the
# CONTINUATION reason: telling such a worker only "record exhaustion evidence"
# would let it satisfy the concession gate and stop with the queue still full.
printf '%s\n' '{"message":{"role":"assistant","content":[{"type":"text","text":"I am blocked and cannot proceed."}]}}' > "$T2/b.jsonl"
printf '{"transcript_path":"%s/b.jsonl"}' "$T2" | CLAUDE_PROJECT_DIR="$PWD" bash .claude/hooks/concession-gate.sh >/dev/null 2>"$T2/e2"
grep -q "NEXT RUNNABLE TASK" "$T2/e2" && ok "continuation OUTRANKS the concession check while work remains" || no "continuation outranks the concession check"
rm -rf "$T2"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
