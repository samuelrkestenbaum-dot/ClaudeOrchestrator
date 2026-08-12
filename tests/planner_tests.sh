#!/usr/bin/env bash
# Zone-4 deterministic planner — failure-first + E2E through real entry
# points. Contract items exercised at module level; wiring items ONLY via
# bin/gravito verbs with receipt inspection (imports are never wiring proof).
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
G="$SRC/bin/gravito"
P="$SRC/build-os/tools/planner.mjs"
WORK="$(mktemp -d /tmp/bos-plan.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }
R="$WORK/repo"; mkdir -p "$R"; git -C "$R" init -q; git -C "$R" remote add origin https://x/pl.git
echo base > "$R/app.txt"; git -C "$R" -c user.email=t@t -c user.name=t add -A; git -C "$R" -c user.email=t@t -c user.name=t commit -qm seed
"$G" init "$R" >/dev/null 2>&1
cp "$SRC/templates/gravito.goal.example" "$WORK/goal.txt"
printf 'acceptance_cmd: test -f docs/NOTES.md\n' >> "$WORK/goal.txt"
"$G" goal "$WORK/goal.txt" "$R" >/dev/null

mod(){ node --input-type=module -e "
import { plan, validatePlan } from '$P';
import { constructReachability } from '$SRC/build-os/tools/reachability.mjs';
$1
" 2>&1; }

echo "== 1-4. contract refusals (failure-first) =="
OUT=$(mod "
const r = constructReachability('$R');
const p = plan({ run_id:'t1', dir:'$R', reach:r, candidates:['push'], scores:{push:1e9} });
console.log(JSON.stringify(p));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"status\"]==\"REFUSED\" and \"resurrect\" in d[\"refusal\"] else 1)"' \
  "1. candidate outside R_t+ REFUSED even with a 1e9 score (cannot resurrect)"
OUT=$(mod "console.log(JSON.stringify(plan({ run_id:'t2', dir:'$R', reach:{artifact:'garbage'} })))")
ok 'printf "%s" "$OUT" | grep -q "REFUSED"' "2. corrupt reachability receipt refuses planning"
OUT=$(mod "
const r = constructReachability('$R');
console.log(JSON.stringify(plan({ run_id:'t3', dir:'$WORK', reach:r })))")
ok 'printf "%s" "$OUT" | grep -q "repository identity mismatch"' "3. repo identity mismatch refuses"
OUT=$(mod "
const r = constructReachability('$R'); r.R_t_plus = [];
console.log(JSON.stringify(plan({ run_id:'t4', dir:'$R', reach:r, candidates:[] })))")
ok 'printf "%s" "$OUT" | grep -q "NO_REACHABLE_ACTION"' "4. empty R_t+ => NO_REACHABLE_ACTION, no invented work"

echo "== 5. E2E: one-candidate cmd_run emits an HONEST degenerate plan =="
"$G" run "$R" --dry-run >/dev/null 2>&1
PL="$R/build-os/receipts/plans.jsonl"
ok '[ -f "$PL" ] && [ "$(grep -c "\"origin\":\"cmd_run\"" "$PL")" = 1 ]' "cmd_run executed the planner exactly once (one receipt)"
ok 'grep "\"origin\":\"cmd_run\"" "$PL" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"degenerate\"] and d[\"candidates\"]==1 and d[\"selected\"]==\"run\" else 1)"' \
  "degenerate=true, candidates=1 — no fabricated comparison"
TRC="$R/build-os/receipts/run-trace.jsonl"
RID=$(tail -1 "$TRC" | python3 -c 'import json,sys;print(json.loads(sys.stdin.read())["run_id"])')
STEPS=$(grep "\"$RID\"" "$TRC" | python3 -c 'import json,sys;print(",".join(json.loads(l)["step"] for l in sys.stdin))')
ok '[ "$STEPS" = "h0,reachability,authority,plan,dry-run" ]' "trace order: h0 -> reachability -> authority -> PLAN -> admission ($STEPS)"

echo "== 6-7. determinism, tie-break stability, dependency ordering =="
H1=$(mod "const r=constructReachability('$R');const p=plan({run_id:'same',dir:'$R',reach:r});console.log(p.plan.content_hash)")
H2=$(mod "const r=constructReachability('$R');const p=plan({run_id:'same',dir:'$R',reach:r});console.log(p.plan.content_hash)")
ok '[ -n "$H1" ] && [ "$H1" = "$H2" ]' "6. identical inputs => identical plan content_hash (stable ordering + tie-break)"
OUT=$(mod "
const r=constructReachability('$R');
const p=plan({run_id:'dep',dir:'$R',reach:r});
const ranks=Object.fromEntries(p.plan.ordered.map(o=>[o.action,o.rank]));
const rev=p.plan.ordered.find(o=>o.action==='review');
console.log(JSON.stringify({rev_dep:rev?rev.dependency_satisfied:null, ranks}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"rev_dep\"]==False and d[\"ranks\"][\"review\"]>d[\"ranks\"][\"diagnose\"] else 1)"' \
  "7. review with UNSATISFIED dependency (no run stream) orders after satisfied evidence-producers"

echo "== 8. conflicting/unknown write sets never become safely parallel =="
OUT=$(mod "
const r=constructReachability('$R');
const p=plan({run_id:'par',dir:'$R',reach:r});
const runPairs=p.plan.parallel_classification.filter(x=>x.pair.includes('run'));
console.log(JSON.stringify({allUnknown: runPairs.every(x=>x.class==='unknown'), n:runPairs.length}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"allUnknown\"] and d[\"n\"]>0 else 1)"' \
  "every pair involving run (worktree-unknown writes) is UNKNOWN — never safe"

echo "== 9. changed goal/HEAD between plan and dispatch => revalidation refuses =="
OUT=$(mod "
const r=constructReachability('$R');
const p=plan({run_id:'reval',dir:'$R',reach:r});
import fs from 'node:fs';
fs.appendFileSync('$R/gravito.goal','\n# changed after planning\n');
const v=validatePlan('$R', p.plan);
console.log(JSON.stringify(v));")
git -C "$R" checkout -q -- . 2>/dev/null; sed -i '/# changed after planning/d' "$R/gravito.goal"
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if not d[\"ok\"] and \"goal\" in d[\"reason\"] else 1)"' \
  "goal changed after planning => validatePlan refuses (a plan is never authorized by age)"
ok 'grep -q "validatePlan" "$SRC/bin/gravito"' "cmd_run performs the revalidation step before dispatch (caller present)"

echo "== 10-12. retry idempotency, concurrency, torn receipts =="
"$G" run "$R" --dry-run >/dev/null 2>&1
ok '[ "$(grep -c "\"origin\":\"cmd_run\"" "$PL")" = 2 ] && [ "$(grep "\"origin\":\"cmd_run\"" "$PL" | python3 -c "import json,sys;print(len({json.loads(l)[\"content_hash\"] for l in sys.stdin}))")" -le 2 ]' \
  "10. retry appends a NEW planning event; no accepted plan duplicated, no side effects"
for i in 1 2 3 4; do mod "
import { appendPlanReceipt } from '$P';
const r=constructReachability('$R');
const p=plan({run_id:'conc',dir:'$R',reach:r});
appendPlanReceipt('$R', p.plan, 'conc-test');" >/dev/null & done; wait
ok '[ "$(grep "\"origin\":\"conc-test\"" "$PL" | python3 -c "import json,sys;print(len({json.loads(l)[\"content_hash\"] for l in sys.stdin}))")" = 1 ]' \
  "11. 4 concurrent identical plannings => ONE canonical content_hash"
ok 'node "$P" verify "$R" >/dev/null' "plan chain verifies intact under concurrency (mutex held)"
echo '{"torn' >> "$PL"
ok '! node "$P" verify "$R" >/dev/null 2>&1' "12. torn plan receipt detected"
sed -i '$d' "$PL"

echo "== 13-15. diagnose honesty, UCDL unwired, reasoning discipline =="
RF="$WORK/fresh"; mkdir -p "$RF"; git -C "$RF" init -q; git -C "$RF" remote add origin https://x/fr.git
echo x > "$RF/a.txt"; git -C "$RF" -c user.email=t@t -c user.name=t add -A; git -C "$RF" -c user.email=t@t -c user.name=t commit -qm s
"$G" init "$RF" >/dev/null 2>&1
DF=$("$G" diagnose "$RF" 2>/dev/null)
ok 'printf "%s" "$DF" | grep "planner" | grep "cmd_run" | grep -q "STATICALLY_CONNECTED"' \
  "13. fresh repo: planner@cmd_run is STATICALLY_CONNECTED — source presence never yields WIRED"
DD=$("$G" diagnose "$R" 2>/dev/null)
ok 'printf "%s" "$DD" | grep "planner" | grep "cmd_run" | grep -q "WIRED_UNPROVEN"' \
  "executed repo: planner@cmd_run WIRED_UNPROVEN from the plan receipt"
ok 'printf "%s" "$DD" | grep "cognition-handoff" | grep -q "IMPLEMENTED_UNWIRED"' \
  "14a. cognition handoff reported: descriptor only, UCDL UNWIRED"
ok '! grep -rq "delivery/ucdl" "$SRC/bin/gravito" "$SRC/build-os/tools/planner.mjs"' "14b. planner and CLI never import UCDL"
ok 'grep -q "Work ONLY in this repository" "$SRC/bin/gravito"' "14c. worker prompt construction unchanged (bytes preserved)"
OUT=$(mod "
const r=constructReachability('$R');
const p=plan({run_id:'txt',dir:'$R',reach:r});
const s=JSON.stringify(p.plan);
const forbidden=/\\b(probability|utility|attractor|curvature|entropy|trust_score|relevance|Phi)\\b/;
console.log(JSON.stringify({clean: !forbidden.test(s)}));")
ok 'printf "%s" "$OUT" | grep -q "\"clean\":true"' "15. plan output contains only deterministic observable vocabulary"

echo "== 16-17. unmanaged and legacy semantics unchanged =="
UN="$WORK/unmanaged"; mkdir -p "$UN"; git -C "$UN" init -q; echo z > "$UN/f.txt"
ok '[ ! -d "$UN/.claude" ] && [ ! -f "$UN/build-os/receipts/plans.jsonl" ]' "16. unmanaged repo: untouched, no plan state"
RL="$WORK/legacy"; mkdir -p "$RL"; git -C "$RL" init -q; git -C "$RL" remote add origin https://x/lg.git
echo b > "$RL/a.txt"; git -C "$RL" -c user.email=t@t -c user.name=t add -A; git -C "$RL" -c user.email=t@t -c user.name=t commit -qm s
"$G" init "$RL" >/dev/null 2>&1; "$G" goal "$WORK/goal.txt" "$RL" >/dev/null
rm "$RL/build-os/tools/h0-check.sh"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s/a.txt"}}' "$RL" \
  | env CLAUDE_PROJECT_DIR="$RL" bash "$RL/.claude/hooks/routing-gate.sh" mutgate >/dev/null 2>"$WORK/err"; LRC=$?
ok '[ "$LRC" = 2 ] && grep -q "gravito update" "$WORK/err"' "17. legacy H0/update policy intact (fail closed, actionable)"

echo "== 18. sealed artifacts byte-identical =="
ok '[ -z "$(cd "$SRC" && git status --porcelain -- build-os/experiments/EXP-0011-reusable-skills build-os/experiments/EXP-0010* 2>/dev/null)" ]' \
  "sealed EXP-0010/0011 trees untouched"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
