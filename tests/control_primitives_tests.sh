#!/usr/bin/env bash
# Neurocosmology control primitives P-1..P-4 — END-TO-END through the REAL
# entry points (bin/gravito verbs + the PreToolUse hook on disposable repos),
# inspecting receipts and traces, not importing modules. Proves: canonical
# callers per entry point, exactly-once invocation with a correlation id,
# ordered sequence state->H0->reachability->authority->admission->dispatch,
# fail-BEFORE-side-effects at every entry, corrected prediction semantics
# (a success criterion is never yhat), crash/concurrency behavior of the
# persisted chains, and diagnose labels driven by invocation evidence.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
G="$SRC/bin/gravito"
DR="$SRC/build-os/tools/delta-receipt.sh"
WORK="$(mktemp -d /tmp/bos-ctl.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }
R="$WORK/repo"; mkdir -p "$R"; git -C "$R" init -q; git -C "$R" remote add origin https://x/ctl.git
echo base > "$R/app.txt"; git -C "$R" -c user.email=t@t -c user.name=t add -A; git -C "$R" -c user.email=t@t -c user.name=t commit -qm seed
"$G" init "$R" >/dev/null 2>&1
cp "$SRC/templates/gravito.goal.example" "$WORK/goal.txt"
printf 'acceptance_cmd: test -f docs/NOTES.md && grep -qi app "docs/NOTES.md"\n' >> "$WORK/goal.txt"
"$G" goal "$WORK/goal.txt" "$R" >/dev/null

echo "== P-1 entry point 1 (cmd_run): H0 first, Class-A blocks BEFORE effects =="
echo 'not json at all' >> "$R/build-os/memory/spend-ledger.jsonl"
OUT=$("$G" run "$R" --dry-run 2>&1); RC=$?
ok '[ "$RC" != 0 ] && printf "%s" "$OUT" | grep -q "H0_system Class-A"' "corrupt ledger: run REFUSES at H0, naming Class-A"
ok '[ ! -f "$R/build-os/receipts/run.pid" ] && ! ls "$R"/build-os/receipts/run-2*.jsonl >/dev/null 2>&1' "no side effects (no pid, no stream)"
TRC="$R/build-os/receipts/run-trace.jsonl"
ok '[ -f "$TRC" ] && tail -2 "$TRC" | head -1 | grep -q "\"step\":\"h0\"" && tail -1 "$TRC" | grep -q "\"step\":\"refuse\""' \
  "trace: h0 -> refuse, ordered, before any authority step"

echo "== P-1 entry point 2 (tool gate): SAME Class-A contract before authority =="
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s/app.txt"}}' "$R" \
  | env CLAUDE_PROJECT_DIR="$R" bash "$R/.claude/hooks/routing-gate.sh" mutgate >"$WORK/out" 2>"$WORK/err"; HRC=$?
ok '[ "$HRC" = 2 ] && grep -q "H0 HALT" "$WORK/err"' "corrupt ledger blocks Edit at the PreToolUse boundary (exit 2)"
ok 'grep -q "H0 Class-A" "$R/build-os/receipts/refusals.log"' "tool-boundary H0 refusal receipted"
ok '[ "$(cat "$R/app.txt")" = "base" ]' "no side effect at the tool boundary"
rm "$R/build-os/memory/spend-ledger.jsonl"

echo "== P-1: degraded NONCRITICAL narrows, never universally stops =="
echo 99999999 > "$R/build-os/receipts/run.pid"
OUT=$("$G" run "$R" --dry-run 2>&1); RC=$?
ok '[ "$RC" = 0 ] && printf "%s" "$OUT" | grep -q "dry-run: gate open"' "stale pid: run PROCEEDS (narrowed, not blocked)"
ok 'python3 -c "import json;d=json.load(open(\"$R/build-os/receipts/h0-latest.json\"));exit(0 if d[\"agency\"]==\"narrowed\" else 1)"' \
  "H0 receipt: agency=narrowed with the stale pid annotated"
rm -f "$R/build-os/receipts/run.pid"

echo "== P-2 + sequence: reachability is the REAL admission input, traced =="
RID=$(tail -1 "$TRC" | python3 -c 'import json,sys;print(json.loads(sys.stdin.read())["run_id"])')
STEPS=$(grep "\"$RID\"" "$TRC" | python3 -c 'import json,sys;print(",".join(json.loads(l)["step"] for l in sys.stdin))')
ok '[ "$STEPS" = "h0,reachability,authority,plan,dry-run" ]' "one run_id, ordered: h0 -> reachability -> authority -> plan -> admission ($STEPS)"
ok '[ "$(grep "\"$RID\"" "$TRC" | grep -c "\"step\":\"h0\"")" = 1 ]' "exactly ONE h0 step per dispatch attempt (correlation id proof)"
# LAPSED window (its sibling out-of-window state NOT-YET-LIVE is exercised by goal_enforcement_tests)
sed -i 's/^starts: .*/starts: 2026-07-01/; s/^expires: .*/expires: 2026-08-01/' "$R/gravito.goal"
OUT=$(env BUILD_OS_NOW=2026-08-13 "$G" run "$R" --dry-run 2>&1); RC=$?
ok '[ "$RC" != 0 ] && printf "%s" "$OUT" | grep -q "outside R_t+"' "lapsed goal: dispatch refused because run is OUTSIDE R_t+ (admission, not telemetry)"
ok 'tail -1 "$TRC" | grep -q "\"step\":\"refuse\"" && tail -2 "$TRC" | head -1 | grep -q "\"step\":\"authority\""' \
  "trace shows authority verdict then refusal — the gate ran ONCE, inside the construction"
sed -i 's/^starts: .*/starts: 2026-08-01/; s/^expires: .*/expires: 2026-12-31/' "$R/gravito.goal"
node --input-type=module -e "
import { constructReachability, selectAction } from '$SRC/build-os/tools/reachability.mjs';
const r = constructReachability('$R');
const s = selectAction(r, { push: 1e9, 'not-an-action': 1e9, status: 1 });
console.log(JSON.stringify({ ok: s.selected !== 'push' && s.ignored_scores.includes('push') }));
" > "$WORK/res.json" 2>&1
ok '[ "$(python3 -c "import json;print(json.load(open(\"$WORK/res.json\"))[\"ok\"])")" = "True" ]' \
  "a 1e9 score on an unauthorized action is IGNORED (argmax strictly over R_t+)"
HOUT=$("$G" health "$R" 2>/dev/null)
ok 'printf "%s" "$HOUT" | grep -q "unreachable: push"' "health: push explicitly unreachable"
ok 'printf "%s" "$HOUT" | grep -q "planner consumer: ABSENT"' "the absent SCORING consumer stays reported, not faked"

echo "== P-3: predictions are forecasts, never manufactured =="
mkdir -p "$R/docs"; echo "app mention" > "$R/docs/NOTES.md"
"$G" review "$R" >/dev/null 2>&1
L1=$(tail -1 "$R/build-os/receipts/deltas.jsonl")
ok 'printf "%s" "$L1" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"prediction_status\"]==\"NOT_RECORDED\" and d[\"delta\"]==\"UNDEFINED\" and d[\"predicted\"] is None else 1)"' \
  "no prediction made => NOT_RECORDED + delta UNDEFINED; acceptance recorded separately as observation"
"$G" predict PASS "$R" >/dev/null
"$G" review "$R" >/dev/null 2>&1
L2=$(tail -1 "$R/build-os/receipts/deltas.jsonl")
ok 'printf "%s" "$L2" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"prediction_status\"]==\"MATCHED\" and d[\"delta\"]==0 and d[\"predicted\"]==\"PASS\" else 1)"' \
  "real pre-run forecast PASS + observed PASS => MATCHED, delta 0"
PID_BAD=$(bash "$DR" predict "$R" --var tokens_used --value 100000 --scale task)
OUT=$(bash "$DR" observe "$R" --var acceptance --observed PASS --evidence e --prediction-id "$PID_BAD" --scale task --consequence none)
ok 'printf "%s" "$OUT" | grep -q "INCOMPARABLE"' "mismatched outcome variable => INCOMPARABLE, delta UNDEFINED"
PID_PH=$(bash "$DR" predict "$R" --var acceptance --value FAIL --scale task)
OUT=$(bash "$DR" observe "$R" --var acceptance --observed PASS --evidence e --prediction-id "$PID_PH" --observed-at 2020-01-01T00:00:00Z --alternative a --scale task --consequence none)
ok 'printf "%s" "$OUT" | grep -q "POST_HOC"' "prediction made AFTER the observation moment => POST_HOC, not a forecast"
ok '! bash "$DR" observe "$R" --var acceptance --observed PASS --evidence e --prediction-id pred-never-existed --scale task --consequence none >/dev/null 2>&1' \
  "unknown prediction id => REFUSED (a prediction is never invented)"
PID_M=$(bash "$DR" predict "$R" --var acceptance --value FAIL --scale task)
ok '! bash "$DR" observe "$R" --var acceptance --observed PASS --evidence e --prediction-id "$PID_M" --scale task --consequence none >/dev/null 2>&1' \
  "mismatch without --alternative => REFUSED (unexplained surprise is not evidence)"

echo "== P-3: immutability, crash, concurrency =="
ok 'bash "$DR" verify "$R" >/dev/null' "both chains verify intact"
cp "$R/build-os/receipts/deltas.jsonl" "$WORK/bak"
sed -i '1s/acceptance/tampered/' "$R/build-os/receipts/deltas.jsonl"
ok '! bash "$DR" verify "$R" >/dev/null 2>&1' "tampering line 1 breaks the chain: DETECTED"
cp "$WORK/bak" "$R/build-os/receipts/deltas.jsonl"
echo '{"torn' >> "$R/build-os/receipts/deltas.jsonl"
VOUT=$(bash "$DR" verify "$R" 2>&1); VRC=$?
ok '[ "$VRC" != 0 ] && printf "%s" "$VOUT" | grep -q "torn"' "crash-torn tail detected and reported"
sed -i '$d' "$R/build-os/receipts/deltas.jsonl"
for i in 1 2 3 4; do bash "$DR" observe "$R" --var acceptance --observed "c$i" --evidence e --scale event --consequence none >/dev/null & done; wait
ok 'bash "$DR" verify "$R" >/dev/null' "4 concurrent observes: chain still verifies (flock)"

echo "== P-4: diagnostics only; zero-denominator honesty; negative case =="
RVOUT=$("$G" review "$R" 2>/dev/null || true)
ok 'printf "%s" "$RVOUT" | grep -q "P_verified"' "counters surface in the real review path"
ok 'printf "%s" "$RVOUT" | grep -q "diagnostics only"' "labeled diagnostics — they grade nothing"
R2="$WORK/docsonly"; mkdir -p "$R2"; git -C "$R2" init -q
for i in 1 2 3; do echo "thoughts $i" > "$R2/notes$i.md"; git -C "$R2" -c user.email=t@t -c user.name=t add -A; git -C "$R2" -c user.email=t@t -c user.name=t commit -qm "interpretation $i"; done
COUT=$(node "$SRC/build-os/tools/convergence-counters.mjs" "$R2")
ok 'printf "%s" "$COUT" | grep -q "ZERO verified change"' "NEGATIVE CASE: semantic activity without verified change reported as NOT progress"
ok '! grep -Eq "convergence-counters|reachability.mjs" "$SRC/.claude/hooks/routing-gate.sh"' "no gate consumes counters or scores"

echo "== LEGACY POLICY: managed target missing H0 tool FAILS CLOSED until update =="
RL="$WORK/legacy"; mkdir -p "$RL"; git -C "$RL" init -q; git -C "$RL" remote add origin https://x/leg.git
echo base > "$RL/app.txt"; echo "keep me" > "$RL/user-file.txt"
git -C "$RL" -c user.email=t@t -c user.name=t add -A; git -C "$RL" -c user.email=t@t -c user.name=t commit -qm s
"$G" init "$RL" >/dev/null 2>&1
"$G" goal "$WORK/goal.txt" "$RL" >/dev/null
rm "$RL/build-os/tools/h0-check.sh"    # simulate an R1-era target
sha_user="$(sha256sum "$RL/user-file.txt" | cut -d' ' -f1)"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s/app.txt"}}' "$RL" \
  | env CLAUDE_PROJECT_DIR="$RL" bash "$RL/.claude/hooks/routing-gate.sh" mutgate >"$WORK/out" 2>"$WORK/err"; LRC=$?
ok '[ "$LRC" = 2 ] && grep -q "H0 HALT (fail closed)" "$WORK/err" && grep -q "gravito update" "$WORK/err"' \
  "missing H0 component: mutation FAILS CLOSED with actionable UPDATE receipt (exit 2)"
ok 'grep -q "UPDATE_REQUIRED" "$RL/build-os/receipts/refusals.log"' "refusal receipt names UPDATE_REQUIRED"
ok '[ "$(cat "$RL/app.txt")" = "base" ]' "no side effect while unprotected"
DL=$("$G" diagnose "$RL" 2>/dev/null)
ok 'printf "%s" "$DL" | grep -q "UPDATE_REQUIRED"' "diagnose reports UPDATE_REQUIRED for the tool-gate entry point"
chmod -x "$RL/build-os/tools" 2>/dev/null || true
"$G" update "$RL" >/dev/null 2>&1 || true
chmod +x "$RL/build-os/tools" 2>/dev/null || true
"$G" update "$RL" >/dev/null
ok '[ -x "$RL/build-os/tools/h0-check.sh" ]' "gravito update restores the H0 component (torn attempt then repair)"
S1=$(python3 -c "import json;print(open('$RL/.claude/settings.json').read())" | sha256sum)
"$G" update "$RL" >/dev/null
S2=$(python3 -c "import json;print(open('$RL/.claude/settings.json').read())" | sha256sum)
ok '[ "$S1" = "$S2" ]' "repeated update is idempotent: settings byte-identical, matchers registered exactly once"
ok '[ "$(python3 -c "
import json
s=json.load(open('\''$RL/.claude/settings.json'\''))
print(sum(1 for g in s['\''hooks'\'']['\''PreToolUse'\''] if g.get('\''matcher'\'')=='\''Edit|Write|NotebookEdit|Bash'\''))")" = 1 ]' \
  "exactly ONE mutgate matcher after repeated updates (no double registration)"
ok '[ "$(sha256sum "$RL/user-file.txt" | cut -d" " -f1)" = "$sha_user" ]' "unrelated target file byte-identical across updates"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s/app.txt"}}' "$RL" \
  | env CLAUDE_PROJECT_DIR="$RL" BUILD_OS_NOW=2026-08-13 bash "$RL/.claude/hooks/routing-gate.sh" mutgate >/dev/null 2>&1; LRC=$?
ok '[ "$LRC" != 2 ]' "after update: mutation allowed again under the LIVE goal (repair proven E2E)"
UNM="$WORK/unmanaged"; mkdir -p "$UNM"; git -C "$UNM" init -q; echo z > "$UNM/f.txt"
ok '[ ! -d "$UNM/.claude" ]' "unmanaged repository untouched — no control claimed over it"

echo "== diagnose: matrix labels from invocation evidence, never source alone =="
DOUT=$("$G" diagnose "$R" 2>/dev/null)
ok 'printf "%s" "$DOUT" | grep "H0_system" | grep "cmd_run" | grep -q "WIRED_UNPROVEN"' "H0@cmd_run WIRED_UNPROVEN (receipt evidence here)"
ok 'printf "%s" "$DOUT" | grep "H0_system" | grep "tool-gate" | grep -q "WIRED_UNPROVEN"' "H0@tool-gate WIRED_UNPROVEN (refusal receipt evidence here)"
ok 'printf "%s" "$DOUT" | grep "reach.admission" | grep -q "WIRED_UNPROVEN"' "admission WIRED_UNPROVEN (run-trace evidence)"
ok 'printf "%s" "$DOUT" | grep "planner" | grep -q "cmd_run"' "planner reported per entry point (split from admission, never one label)"
ok 'printf "%s" "$DOUT" | grep "cognition-handoff" | grep -q "IMPLEMENTED_UNWIRED"' "cognition handoff stays IMPLEMENTED_UNWIRED (descriptor only, UCDL unwired)"
ok 'printf "%s" "$DOUT" | grep -q "uncovered/unsupported boundaries"' "uncovered boundaries named in the matrix output"
ok '! printf "%s" "$DOUT" | grep -E "^  [^ ]" | grep -q "OUTCOME_PROVEN"' "no matrix ROW claims OUTCOME_PROVEN from tests alone (legend may name the status)"
R3="$WORK/fresh"; mkdir -p "$R3"; git -C "$R3" init -q; git -C "$R3" remote add origin https://x/f.git
echo x > "$R3/a.txt"; git -C "$R3" -c user.email=t@t -c user.name=t add -A; git -C "$R3" -c user.email=t@t -c user.name=t commit -qm s
"$G" init "$R3" >/dev/null 2>&1
D3=$("$G" diagnose "$R3" 2>/dev/null)
ok 'printf "%s" "$D3" | grep "H0_system" | grep "cmd_run" | grep -q "STATICALLY_CONNECTED"' \
  "fresh repo: source caller alone yields STATICALLY_CONNECTED, never WIRED_*"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
