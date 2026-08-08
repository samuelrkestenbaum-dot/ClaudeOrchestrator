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

echo "== live Stop hook =="
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
printf '%s\n' '{"message":{"role":"assistant","content":[{"type":"text","text":"I cannot do this. It is blocked."}]}}' > "$T/c.jsonl"
printf '{"transcript_path":"%s/c.jsonl"}' "$T" | CLAUDE_PROJECT_DIR="$PWD" bash .claude/hooks/concession-gate.sh >/dev/null 2>"$T/e"
t "Stop hook refuses a bare concession" "$?" "2"
grep -q "surfaces observed to hold" "$T/e" && ok "the refusal TELLS the worker where the capability lives" || no "refusal carries recovery guidance"
printf '%s\n' '{"message":{"role":"assistant","content":[{"type":"text","text":"Done. 42 tests pass."}]}}' > "$T/o.jsonl"
printf '{"transcript_path":"%s/o.jsonl"}' "$T" | CLAUDE_PROJECT_DIR="$PWD" bash .claude/hooks/concession-gate.sh >/dev/null 2>&1
t "Stop hook allows a non-conceding turn" "$?" "0"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
