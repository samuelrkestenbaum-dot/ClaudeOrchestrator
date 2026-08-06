#!/usr/bin/env bash
# Build OS — shell_surface_tests.sh: the CUSTOMER-FACING CONTROL SURFACE
# (build-os/shell/gravito).
#
# WHAT THIS PROVES. A user can see: task / selected depth / why / authority /
# budgets / live activity / throttle-degradation events / result / evidence /
# cost categories — WITHOUT reading internal governance documentation and
# WITHOUT internal vocabulary leaking into the default human output. The
# machine seam (--json) stays valid JSON. Honesty holds: an unknown is
# UNAVAILABLE, never a 0 nobody measured.
#
# FIXTURES. The REAL receipts in this repo's build-os/packets/routing/ are the
# primary rendering fixtures (14 closed receipts at the time of writing, all
# statuses derived not asserted-by-name where counts could drift); synthetic
# receipts + a synthetic ledger + synthetic live state live in mktemp for the
# edge cases (open status, unknown values, throttle events, every ledger
# decision code). Standalone, deterministic, model-free; the real store is
# read and never written.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRAV="$SRC/build-os/shell/gravito"
REAL_STORE="$SRC/build-os/packets/routing"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  ok  %s\n' "$1"; }
no(){ FAIL=$((FAIL+1)); printf '  NO  %s\n' "$1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

[ -f "$GRAV" ] || { no "build-os/shell/gravito does not exist"; echo "==== RESULT: $PASS passed, $FAIL failed ===="; exit 1; }
command -v node >/dev/null 2>&1 || { no "node is required for the --json validity checks"; echo "==== RESULT: $PASS passed, $FAIL failed ===="; exit 1; }

# The internal vocabulary that must NOT leak into default human output.
# Case-sensitive on purpose: a user's own task id may legitimately be
# "PACKET-0053-..." (their name for their task); the INTERNAL vocabulary is
# the lowercase doctrine form. grep -w keeps "packets/" (a path) legal while
# refusing the bare word.
BANNED_WORDS="packet census archivist"
BANNED_FIXED="gravito_full gravito_light mandatory_full_regate DC-0001"
leak_scan(){ # <file> -> prints first offending token, rc 0 if a leak found
  local w
  for w in $BANNED_WORDS; do
    if grep -qw "$w" "$1"; then printf '%s' "$w"; return 0; fi
  done
  for w in $BANNED_FIXED; do
    if grep -qF "$w" "$1"; then printf '%s' "$w"; return 0; fi
  done
  return 1
}

json_ok(){ # <file> -> rc 0 iff valid JSON
  node -e 'const fs=require("fs");JSON.parse(fs.readFileSync(process.argv[1],"utf8"))' "$1" >/dev/null 2>&1
}

echo "== 1. Real receipts render: gravito tasks =="
bash "$GRAV" tasks > "$WORK/tasks.out" 2>"$WORK/tasks.err"; RC=$?
[ "$RC" = "0" ] && ok "gravito tasks exits 0 against the real store" \
                || { no "gravito tasks failed (exit $RC)"; sed 's/^/      | /' "$WORK/tasks.err"; }
N_REAL="$(find "$REAL_STORE" -maxdepth 1 -name '*.md' | grep -c . || true)"
for f in "$REAL_STORE"/*.md; do
  id="$(awk -F': ' '$1=="task_id"{print $2; exit}' "$f")"
  grep -qF "$id" "$WORK/tasks.out" && ok "lists real task $id" || no "real task $id is missing from gravito tasks"
done
# Status is DERIVED per receipt, not hardcoded: executed_mode '-' = open.
DERIVED_CLOSED=0
for f in "$REAL_STORE"/*.md; do
  em="$(awk -F': ' '$1=="executed_mode"{print $2; exit}' "$f")"
  [ -n "$em" ] && [ "$em" != "-" ] && DERIVED_CLOSED=$((DERIVED_CLOSED+1))
done
SHOWN_CLOSED="$(grep -cw closed "$WORK/tasks.out" || true)"
[ "$SHOWN_CLOSED" = "$DERIVED_CLOSED" ] \
  && ok "closed count matches the store ($DERIVED_CLOSED closed receipts)" \
  || no "closed count mismatch: store says $DERIVED_CLOSED, surface shows $SHOWN_CLOSED"
if LEAK="$(leak_scan "$WORK/tasks.out")"; then no "internal vocabulary leaked into gravito tasks: '$LEAK'"; else ok "no internal vocabulary in gravito tasks default output"; fi

echo "== 2. Real receipts render: gravito task <id> — every real receipt, leak-free =="
for f in "$REAL_STORE"/*.md; do
  id="$(awk -F': ' '$1=="task_id"{print $2; exit}' "$f")"
  bash "$GRAV" task "$id" > "$WORK/card.out" 2>"$WORK/card.err"; RC=$?
  if [ "$RC" != "0" ]; then
    no "gravito task $id failed (exit $RC)"; sed 's/^/      | /' "$WORK/card.err"; continue
  fi
  if LEAK="$(leak_scan "$WORK/card.out")"; then
    no "internal vocabulary leaked in card for $id: '$LEAK'"
  else
    ok "card renders leak-free: $id"
  fi
done

echo "== 3. Known content on a real card (the honest-breach receipt) =="
bash "$GRAV" task GRAVITO-NATIVE-INSTALL-empathiq-v0 > "$WORK/inst.out" 2>&1
grep -qw Full "$WORK/inst.out" && ok "depth rendered in customer words (Full)" || no "no customer-word depth on the card"
grep -q '2900' "$WORK/inst.out" && ok "the real 2900s time consumption is on the card" || no "2900s consumption missing"
grep -q 'UNAVAILABLE' "$WORK/inst.out" && ok "unknown cost fields carry the honest UNAVAILABLE label" || no "no UNAVAILABLE label where cost is unknown"
grep -qi 'budget' "$WORK/inst.out" && ok "the budget overrun note is surfaced" || no "the overrun note is not surfaced"
# This receipt EXECUTED Full: its note is a budget admission, not a downgrade.
grep -qi 'throttled' "$WORK/inst.out" \
  && no "a budget note without a depth drop was misdescribed as a throttle" \
  || ok "a budget note without a depth drop is NOT described as a throttle"

echo "== 4. --json is valid JSON (the web-shell API seam) =="
bash "$GRAV" tasks --json > "$WORK/tasks.json" 2>&1; RC=$?
[ "$RC" = "0" ] && json_ok "$WORK/tasks.json" && ok "gravito tasks --json parses as JSON" || no "gravito tasks --json is not valid JSON"
node -e '
  const fs=require("fs");
  const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
  if(!Array.isArray(j)) process.exit(1);
  if(j.length!==Number(process.argv[2])) process.exit(1);
  for(const t of j){ if(!t.id||!t.status||!t.mode) process.exit(1); }
' "$WORK/tasks.json" "$N_REAL" \
  && ok "tasks --json is an array of $N_REAL objects with id/status/mode" \
  || no "tasks --json shape wrong (expected $N_REAL rows with id/status/mode)"
bash "$GRAV" task GRAVITO-NATIVE-INSTALL-empathiq-v0 --json > "$WORK/card.json" 2>&1; RC=$?
[ "$RC" = "0" ] && json_ok "$WORK/card.json" && ok "gravito task --json parses as JSON" || no "gravito task --json is not valid JSON"
node -e '
  const fs=require("fs");
  const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
  if(j.id!=="GRAVITO-NATIVE-INSTALL-empathiq-v0") process.exit(1);
  if(j.status!=="closed") process.exit(1);
  if(j.costs.spend_usd!==null) process.exit(1);      // unknown is null, NEVER 0
  if(j.costs.time_s!==2900) process.exit(1);          // known stays exact
' "$WORK/card.json" \
  && ok "card --json: id/status correct; unknown spend is null (not 0); known time exact" \
  || no "card --json shape/honesty wrong"

echo "== 5. Synthetic store: open/closed status, honesty, throttle events =="
SSTORE="$WORK/store"
mkdir -p "$SSTORE/live_state"
cat > "$SSTORE/routing-SYN-OPEN-alpha-20260806T110000Z.md" <<'EOF'
task_id: SYN-OPEN-alpha
description_sha256: 0000000000000000000000000000000000000000000000000000000000000000
descriptor: {"expected_files_changed":3,"requires_tests":true,"expected_session_count":1,"prior_context_required":false,"handoff_required":false,"consequence_level":"high","irreversible_or_external_mutation":false,"high_blast_radius":true,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}
selected_mode: gravito_full
selector_note: -
issued_at: 2026-08-06T11:00:00Z
budget_max_subagents: 3
budget_max_total_tokens: 2000000
budget_max_uncached_tokens: 120000
budget_max_model_calls: 40
budget_max_wall_clock_s: 900
budget_max_cost_usd: 1.50
process_dispatch_allowance: 7
executed_mode: -
escalation: -
escalation_evidence: -
consumed_subagents: -
consumed_total_tokens: -
consumed_uncached_tokens: -
consumed_model_calls: -
consumed_wall_clock_s: -
consumed_cost_usd: -
degradation_note: -
EOF
cat > "$SSTORE/routing-SYN-CLOSED-beta-20260806T100000Z.md" <<'EOF'
task_id: SYN-CLOSED-beta
description_sha256: 1111111111111111111111111111111111111111111111111111111111111111
descriptor: {"expected_files_changed":1,"requires_tests":false,"expected_session_count":1,"prior_context_required":false,"handoff_required":false,"consequence_level":"low","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}
selected_mode: gravito_light
selector_note: -
issued_at: 2026-08-06T10:00:00Z
budget_max_subagents: 0
budget_max_total_tokens: 500000
budget_max_uncached_tokens: 60000
budget_max_model_calls: 25
budget_max_wall_clock_s: 600
budget_max_cost_usd: 0.75
executed_mode: gravito_light
escalation: -
escalation_evidence: -
consumed_subagents: 0
consumed_total_tokens: -
consumed_uncached_tokens: -
consumed_model_calls: -
consumed_wall_clock_s: 100
consumed_cost_usd: -
degradation_note: -
EOF
cat > "$SSTORE/routing-SYN-DEG-gamma-20260806T090000Z.md" <<'EOF'
task_id: SYN-DEG-gamma
description_sha256: 2222222222222222222222222222222222222222222222222222222222222222
descriptor: {"expected_files_changed":9,"requires_tests":true,"expected_session_count":1,"prior_context_required":true,"handoff_required":false,"consequence_level":"medium","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":true,"nondeterministic_verification":false}
selected_mode: gravito_full
selector_note: -
issued_at: 2026-08-06T09:00:00Z
budget_max_subagents: 3
budget_max_total_tokens: 2000000
budget_max_uncached_tokens: 120000
budget_max_model_calls: 40
budget_max_wall_clock_s: 900
budget_max_cost_usd: 1.50
process_dispatch_allowance: 7
executed_mode: gravito_light
escalation: -
escalation_evidence: -
consumed_subagents: 3
consumed_total_tokens: -
consumed_uncached_tokens: -
consumed_model_calls: -
consumed_wall_clock_s: 700
consumed_cost_usd: -
degradation_note: fan-out throttle inside the packet: task dispatches hit the gravito_full cap; qa and reviewer outputs preserved per mandatory_full_regate rules; archivist census pending, see DC-0001
EOF
# Live state for the OPEN task: labels then rows, the gate's exact 3-field shape.
SF="$SSTORE/live_state/routing-SYN-OPEN-alpha-20260806T110000Z.tsv"
{
  printf '# live state for routing-SYN-OPEN-alpha-20260806T110000Z.md — append-only\n'
  printf 'label\ttask_dispatches\tEXACT (hook-counted)\n'
  printf '2026-08-06T11:01:00Z\ttool_event\ttool_name=Read chars=400\n'
  printf '2026-08-06T11:01:00Z\texploratory_event\ttool_name=Read source=read_class\n'
  printf '2026-08-06T11:02:00Z\ttool_event\ttool_name=Edit chars=800\n'
  printf '2026-08-06T11:02:00Z\tmutation_event\ttool_name=Edit class=mutation\n'
  printf '2026-08-06T11:03:00Z\ttool_event\ttool_name=Bash chars=200\n'
  printf '2026-08-06T11:03:30Z\ttask_dispatch\tsubagent_type=general attributed=task_execution\n'
  printf '2026-08-06T11:04:00Z\tprocess_dispatch\tsubagent_type=builder attributed=governance_process\n'
  printf '2026-08-06T11:05:00Z\tDEGRADATION\tdowngraded_to=gravito_light reason=fan-out throttle: task dispatches at budget preserved_evidence=live state rows\n'
  printf '2026-08-06T11:06:00Z\treassess_block\ttrip=same_tool value=25 threshold=25 tier=EXACT fired=once\n'
} > "$SF"
# Synthetic ledger covering every decision code the surface must translate.
cat > "$SSTORE/live_gate_log.tsv" <<'EOF'
2026-08-06T11:01:00Z	none	-	BLOCK-MUTATION-NO-RECEIPT	tool=Write
2026-08-06T11:01:30Z	none	-	ROUTING-TOOL-PASS	tool=Bash ungated=deadlock-guard routing_tool=route-task.sh sha256=abc cmd=route-task.sh
2026-08-06T11:02:00Z	SYN-OPEN-alpha	gravito_full	GIT-READONLY-PASS	tool=Bash class=exploratory
2026-08-06T11:02:30Z	SYN-OPEN-alpha	gravito_full	ALLOW-MUTATION	tool=Edit
2026-08-06T11:03:00Z	SYN-OPEN-alpha	gravito_full	ALLOW-TASK-DISPATCH	subagent_type=general n=1 budget=3
2026-08-06T11:03:30Z	SYN-OPEN-alpha	gravito_full	BLOCK-FANOUT-BUDGET	subagent_type=general n=3 budget=3 degradation=stamped
2026-08-06T11:04:00Z	SYN-OPEN-alpha	gravito_full	BLOCK-REASSESS	tool=Bash trip=same_tool
2026-08-06T11:04:30Z	-	-	FAIL-OPEN	cmd=mutgate rc=1 decision=none
2026-08-06T11:05:00Z	-	-	DISABLED-BY-OPERATOR	cmd=mutgate ROUTING_GATE_DISABLE=1
EOF

bash "$GRAV" tasks --dir "$SSTORE" > "$WORK/syn_tasks.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "gravito tasks renders the synthetic store" || no "synthetic store failed (exit $RC)"
grep -E 'SYN-OPEN-alpha' "$WORK/syn_tasks.out" | grep -qw open  && ok "an unclosed receipt shows status open"  || no "open status wrong for SYN-OPEN-alpha"
grep -E 'SYN-CLOSED-beta' "$WORK/syn_tasks.out" | grep -qw closed && ok "a closed receipt shows status closed" || no "closed status wrong for SYN-CLOSED-beta"

bash "$GRAV" task SYN-CLOSED-beta --dir "$SSTORE" > "$WORK/syn_closed.out" 2>&1
grep -E 'tokens' "$WORK/syn_closed.out" | grep -q 'UNAVAILABLE' \
  && ok "unknown token consumption reads UNAVAILABLE" || no "unknown tokens not labeled UNAVAILABLE"
grep -E '(tokens|spend).*(: *0$|: *0 )' "$WORK/syn_closed.out" \
  && no "an unknown was rendered as 0 — dishonest" || ok "no unknown is rendered as 0"
grep -q 'UNAVAILABLE' "$WORK/syn_closed.out" && ok "activity with no live record is UNAVAILABLE, not invented" || no "missing live record not labeled UNAVAILABLE"

bash "$GRAV" task SYN-OPEN-alpha --dir "$SSTORE" > "$WORK/syn_open.out" 2>&1
grep -qw open "$WORK/syn_open.out" && ok "the card shows open for an in-flight task" || no "card status wrong for open task"
grep -q 'tool actions: 3' "$WORK/syn_open.out" && ok "live activity: 3 tool actions counted from state rows" || no "tool action count wrong"
grep -q '1 exploratory' "$WORK/syn_open.out" && ok "explore half of the split rendered" || no "exploratory count missing"
grep -q '1 governed change' "$WORK/syn_open.out" && ok "execute half of the split rendered" || no "mutation count missing"
grep -qi 'throttle' "$WORK/syn_open.out" && ok "the throttle event is surfaced" || no "throttle event missing"
grep -qi 'reassess' "$WORK/syn_open.out" && ok "the reassessment pause is surfaced" || no "reassessment event missing"
if LEAK="$(leak_scan "$WORK/syn_open.out")"; then no "internal vocabulary leaked on the open card: '$LEAK'"; else ok "open card (with throttle rows) is leak-free"; fi
grep -qi 'in progress' "$WORK/syn_open.out" && ok "an open task's result reads in progress" || no "open task result not honest"

echo "== 6. Degradation note is TRANSLATED, not quoted raw =="
bash "$GRAV" task SYN-DEG-gamma --dir "$SSTORE" > "$WORK/syn_deg.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "degraded receipt renders" || no "degraded receipt failed (exit $RC)"
if LEAK="$(leak_scan "$WORK/syn_deg.out")"; then
  no "internal vocabulary leaked from the degradation note: '$LEAK'"
else
  ok "degradation note carries no internal vocabulary after translation"
fi
grep -q 'Full mode' "$WORK/syn_deg.out" && ok "gravito_full translated to 'Full mode' in the note" || no "mode name not translated in the note"
grep -qw Light "$WORK/syn_deg.out" && ok "the throttled-to depth is stated in customer words" || no "throttled depth not stated"
# This receipt DID drop Full -> Light: the card must say so.
grep -qi 'throttled' "$WORK/syn_deg.out" && ok "an actual depth drop IS described as a throttle" || no "actual throttle not described"

echo "== 7. Activity ledger: translations present, raw codes absent =="
bash "$GRAV" activity --dir "$SSTORE" > "$WORK/act.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "gravito activity exits 0" || no "gravito activity failed (exit $RC)"
grep -q 'blocked an unrouted change (recovery offered)' "$WORK/act.out" \
  && ok "BLOCK-MUTATION-NO-RECEIPT translated" || no "unrouted-change translation missing"
grep -q 'routing action' "$WORK/act.out" && ok "ROUTING-TOOL-PASS translated" || no "routing-action translation missing"
grep -q 'read-only inspection' "$WORK/act.out" && ok "GIT-READONLY-PASS translated" || no "read-only-inspection translation missing"
grep -q 'governed change admitted' "$WORK/act.out" && ok "ALLOW-MUTATION translated" || no "governed-change translation missing"
grep -q 'gate error — failed open (never blocks on its own bugs)' "$WORK/act.out" \
  && ok "FAIL-OPEN translated" || no "fail-open translation missing"
grep -q 'operator override' "$WORK/act.out" && ok "DISABLED-BY-OPERATOR translated" || no "operator-override translation missing"
for code in BLOCK-MUTATION-NO-RECEIPT ROUTING-TOOL-PASS GIT-READONLY-PASS ALLOW-MUTATION FAIL-OPEN DISABLED-BY-OPERATOR BLOCK-FANOUT-BUDGET BLOCK-REASSESS ALLOW-TASK-DISPATCH; do
  grep -qF "$code" "$WORK/act.out" && no "raw decision code $code leaked into default output" || ok "raw code $code absent from default output"
done
if LEAK="$(leak_scan "$WORK/act.out")"; then no "internal vocabulary leaked into activity: '$LEAK'"; else ok "activity default output is leak-free"; fi
N_TAIL="$(bash "$GRAV" activity --dir "$SSTORE" --tail 2 | grep -c '^20' || true)"
[ "$N_TAIL" = "2" ] && ok "--tail 2 yields exactly 2 event rows" || no "--tail 2 yielded $N_TAIL rows"
EMPTY="$WORK/emptystore"; mkdir -p "$EMPTY"
bash "$GRAV" activity --dir "$EMPTY" > "$WORK/act_none.out" 2>&1; RC=$?
[ "$RC" = "0" ] && grep -q 'UNAVAILABLE' "$WORK/act_none.out" \
  && ok "a missing ledger is UNAVAILABLE (honest), exit 0" || no "missing ledger not handled honestly (exit $RC)"

echo "== 8. First-run path: gravito explain =="
bash "$GRAV" explain > "$WORK/explain.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "gravito explain exits 0" || no "gravito explain failed (exit $RC)"
LINES="$(grep -c '' "$WORK/explain.out" || true)"
[ "$LINES" -le 40 ] && ok "explain stays digestible ($LINES lines, <= 40)" || no "explain is $LINES lines — not a first-run path"
grep -q 'route-task.sh' "$WORK/explain.out" && ok "the ONE recovery command is named" || no "recovery command missing"
grep -q -- '--descriptor' "$WORK/explain.out" && ok "the recovery example is copyable (carries --descriptor)" || no "no copyable recovery example"
grep -qi 'not a sandbox' "$WORK/explain.out" && ok "honest bound: not a sandbox" || no "sandbox bound missing"
grep -qi 'next session' "$WORK/explain.out" && ok "honest bound: protection starts next session" || no "next-session bound missing"
grep -qi 'token' "$WORK/explain.out" && grep -qi 'not visible\|UNAVAILABLE' "$WORK/explain.out" \
  && ok "honest bound: live tokens not visible / UNAVAILABLE" || no "token-visibility bound missing"
if LEAK="$(leak_scan "$WORK/explain.out")"; then no "internal vocabulary leaked into explain: '$LEAK'"; else ok "explain is leak-free"; fi

echo "== 9. Errors are usable =="
bash "$GRAV" task NO-SUCH-TASK --dir "$SSTORE" > "$WORK/miss.out" 2>&1; RC=$?
[ "$RC" != "0" ] && grep -q 'gravito tasks' "$WORK/miss.out" \
  && ok "unknown task id: nonzero exit + points at gravito tasks" || no "unknown task id not handled usably (exit $RC)"
bash "$GRAV" frobnicate > "$WORK/bad.out" 2>&1; RC=$?
[ "$RC" != "0" ] && ok "unknown subcommand refused (exit $RC)" || no "unknown subcommand accepted"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
