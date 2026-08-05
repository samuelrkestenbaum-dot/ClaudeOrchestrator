#!/usr/bin/env bash
# Build OS — the LIVE routing gate (PACKET-0053-live-enforcement): the
# PreToolUse dispatch gate, live resource state, fan-out throttling, automatic
# Full->Light degradation, per-layer cost attribution, and marginal-contribution
# accounting.
#
# WHAT CHANGED WITH THIS PACKET, AND WHY THIS SUITE EXISTS. PACKET-0050 made
# routing verdicts binding AT CLOSE: routing-check.sh refuses a contradiction
# after the tokens are already spent. EXP-0003 then measured the gap live —
# both condition receipts were REFUSED at close and ZERO degradation notes were
# written mid-flight, because nothing mechanical existed mid-flight. This
# packet closes the dispatch-shaped half of that gap: Claude Code PreToolUse
# hooks receive the pending tool call as JSON on stdin and can BLOCK it (exit 2,
# stderr becomes the model-visible refusal), so .claude/hooks/routing-gate.sh
# converts routing from file-instruction into pre-execution enforcement for
# everything dispatch-shaped. Token/cost live values remain NOT hook-visible in
# interactive sessions and are labeled exactly that — no checkbox that looks
# enforced and is not.
#
# THE ELEVEN REQUIRED TESTS of the packet brief are numbered in the section
# headers below as REQUIRED TEST 1..11, alongside branch coverage in both
# directions for every gate branch (fail-open, operator escape, both dispatch
# classes, escalated receipts, and the close-time extensions).
#
# SELF-APPLICATION BOUND, stated: hooks load at SESSION START, so the session
# that ships this file is not governed by it — this suite therefore drives the
# hook DIRECTLY with fabricated stdin JSON rather than assuming any live
# session behaviour. Everything here is deterministic, local, model-free;
# fixtures live in mktemp dirs; the live receipt store is read and never
# written.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$SRC/.claude/hooks/routing-gate.sh"
RECDEG="$SRC/build-os/tools/record-degradation.sh"
ROUTE="$SRC/build-os/tools/route-task.sh"
RCHECK="$SRC/build-os/tools/routing-check.sh"
CONTRACT="$SRC/build-os/memory/routing_contract.md"
CONTRACT_LIVE="$SRC/build-os/memory/routing_contract_live.md"
SETTINGS="$SRC/.claude/settings.json"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# One descriptor builder (routing_enforcement_tests.sh's, verbatim) so every
# fixture receipt is issued by the REAL issuer from a descriptor this suite can
# state — a receipt shape the live tool would never emit cannot smuggle a pass.
mkdesc(){
  local files="$1" tests="$2" sessions="$3" prior="$4" handoff="$5" cons="$6" vals="${7:-}"
  local f v
  printf '{'
  printf '"expected_files_changed":%s,"requires_tests":%s,"expected_session_count":%s,' "$files" "$tests" "$sessions"
  printf '"prior_context_required":%s,"handoff_required":%s,"consequence_level":"%s"' "$prior" "$handoff" "$cons"
  for f in irreversible_or_external_mutation high_blast_radius unclear_acceptance_criteria \
           security_or_compliance_consequence parallel_workstreams_benefit high_rework_history \
           nondeterministic_verification; do
    v=false
    case ",$vals," in *",$f,"*) v=true ;; esac
    printf ',"%s":%s' "$f" "$v"
  done
  printf '}'
}
D_DIRECT="$(mkdesc 1 false 1 false false low)"
D_LIGHT="$(mkdesc 2 true 1 true false medium)"
D_FULL="$(mkdesc 4 true 1 true false medium high_blast_radius)"

# mkroot <name> — a fixture DATA root the gate is pointed at via ROUTING_GATE_ROOT.
mkroot(){ mkdir -p "$WORK/$1/build-os/packets/routing"; printf '%s' "$WORK/$1"; }
# issue <root> <task-id> <descriptor> — a REAL receipt; prints the receipt path.
issue(){
  bash "$ROUTE" --task-id "$2" --description "live-gate fixture $2" --descriptor "$3" \
    --out "$1/build-os/packets/routing" >/dev/null 2>&1 || return 1
  find "$1/build-os/packets/routing" -maxdepth 1 -name "routing-$2-*.md" | sed -n '1p'
}
# Hook stdin fabrications — the documented PreToolUse/PostToolUse shapes.
dispatch_json(){ printf '{"session_id":"s1","transcript_path":"/tmp/t","cwd":".","hook_event_name":"PreToolUse","tool_name":"Task","tool_input":{"description":"fixture dispatch","prompt":"do the thing","subagent_type":"%s"}}' "$1"; }
tool_json(){ printf '{"session_id":"s1","transcript_path":"/tmp/t","cwd":".","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"file_path":"/x"}}' "$1"; }
post_json(){ printf '{"session_id":"s1","transcript_path":"/tmp/t","cwd":".","hook_event_name":"PostToolUse","tool_name":"Bash","tool_input":{"command":"x"},"tool_response":%s}' "$1"; }
# rungate <root> <subcmd> <stdin> <outfile> — exit code on stdout.
rungate(){ printf '%s' "$3" | ROUTING_GATE_ROOT="$1" bash "$GATE" "$2" >"$4.out" 2>"$4.err"; echo $?; }
statefile(){ # <root> <receipt-path>
  printf '%s/build-os/packets/routing/live_state/%s.tsv' "$1" "$(basename "$2" .md)"
}

echo "== 1. Surfaces exist, are wired, and the contract states when the gate goes LIVE =="
[ -f "$GATE" ] && ok "routing-gate.sh exists" || no "routing-gate.sh missing"
[ -x "$GATE" ] && ok "routing-gate.sh is executable (hook convention)" || no "routing-gate.sh not executable"
[ -f "$RECDEG" ] && ok "record-degradation.sh exists" || no "record-degradation.sh missing"
[ -x "$RECDEG" ] && ok "record-degradation.sh is executable" || no "record-degradation.sh not executable"
[ -f "$CONTRACT_LIVE" ] && ok "routing_contract_live.md exists" || no "routing_contract_live.md missing"
# The wiring: PreToolUse on the dispatch tool, the * counter, and PostToolUse.
if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS" ]; then
  jq -e '.hooks.PreToolUse[] | select(.matcher=="Task|Agent") | .hooks[] | select(.command | contains("routing-gate.sh gate"))' "$SETTINGS" >/dev/null 2>&1 \
    && ok "settings.json wires routing-gate.sh gate as PreToolUse on Task|Agent" \
    || no "no PreToolUse Task|Agent wiring for routing-gate.sh gate"
  jq -e '.hooks.PreToolUse[] | select(.matcher=="*") | .hooks[] | select(.command | contains("routing-gate.sh count"))' "$SETTINGS" >/dev/null 2>&1 \
    && ok "settings.json wires the tool-event counter as PreToolUse on *" \
    || no "no PreToolUse * wiring for routing-gate.sh count"
  jq -e '.hooks.PostToolUse[] | select(.matcher=="*") | .hooks[] | select(.command | contains("routing-gate.sh post"))' "$SETTINGS" >/dev/null 2>&1 \
    && ok "settings.json wires the failure observer as PostToolUse on *" \
    || no "no PostToolUse * wiring for routing-gate.sh post"
  jq -e '.hooks.SessionStart' "$SETTINGS" >/dev/null 2>&1 \
    && ok "the pre-existing SessionStart wiring survived the edit" \
    || no "SessionStart wiring was lost while adding the gate"
else
  no "jq or settings.json unavailable — the wiring cannot be verified"
fi
# The self-application caution, written down where the next session reads it.
grep -q "session start" "$CONTRACT_LIVE" \
  && ok "the live contract states WHEN the gate becomes live (hooks load at session start)" \
  || no "the live contract does not state when the gate goes live"
grep -q "ROUTING_GATE_DISABLE" "$CONTRACT_LIVE" \
  && ok "the operator-only escape is documented by name" \
  || no "ROUTING_GATE_DISABLE is undocumented — an escape nobody can audit"
grep -qi "operator" "$CONTRACT_LIVE" && ok "the escape is labeled operator-only" || no "the escape is not labeled operator-only"
grep -qi "fail.*open\|fails open" "$CONTRACT_LIVE" \
  && ok "the fail-open doctrine is stated (a broken gate must not brick every session)" \
  || no "the fail-open doctrine is unstated"
# The FOUR enforcement layers, named exactly.
for layer in machine-before-execution machine-at-close protocol-during not-yet-enforced; do
  grep -q "$layer" "$CONTRACT_LIVE" \
    && ok "enforcement layer named exactly: $layer" \
    || no "enforcement layer missing: $layer"
done
grep -qi "context minimization" "$CONTRACT_LIVE" \
  && ok "injection-side context minimization is labeled PROTOCOL, not faked as a hook" \
  || no "context minimization is not labeled as protocol"
grep -q "routing_contract_live.md" "$CONTRACT" \
  && ok "routing_contract.md points at the live half (split, not forked)" \
  || no "routing_contract.md carries no pointer to routing_contract_live.md"
CBYTES="$(wc -c < "$CONTRACT" | tr -d ' ')"
[ "${CBYTES:-99999}" -le 4000 ] \
  && ok "routing_contract.md stays within its 4000-byte ceiling after the pointer ($CBYTES B)" \
  || no "routing_contract.md is $CBYTES B, over the ceiling"

echo "== 2. REQUIRED TEST 1 — dispatch without any open receipt is BLOCKED =="
R1="$(mkroot r1)"
RC="$(rungate "$R1" gate "$(dispatch_json general-purpose)" "$WORK/t1")"
[ "$RC" = "2" ] && ok "RED: dispatch with an EMPTY receipt store is BLOCKED (exit 2)" \
               || no "RED FAILED: unrouted dispatch passed (exit $RC)"
grep -qi "route-task.sh" "$WORK/t1.err" \
  && ok "the refusal tells the model to issue a receipt via route-task.sh first" \
  || no "the refusal does not name the receipt issuer"
grep -qi "continue the task" "$WORK/t1.err" \
  && ok "the no-receipt refusal carries continue-the-task language" \
  || no "the no-receipt refusal reads as stop-working"
# A CLOSED receipt (executed_mode filled) is not an open one.
R2="$(mkroot r2)"
REC2="$(issue "$R2" T-CLOSED-01 "$D_FULL")"
sed -i 's/^executed_mode: -$/executed_mode: gravito_full/' "$REC2"
RC="$(rungate "$R2" gate "$(dispatch_json general-purpose)" "$WORK/t1b")"
[ "$RC" = "2" ] && ok "RED: a store holding only CLOSED receipts still blocks dispatch (open = executed_mode '-')" \
               || no "RED FAILED: a closed receipt licensed a dispatch (exit $RC)"
# Every gate decision persists: task identity, selected depth, decision, timestamp.
LOG1="$R1/build-os/packets/routing/live_gate_log.tsv"
[ -f "$LOG1" ] && ok "live_gate_log.tsv is written on a gate decision" || no "no live_gate_log.tsv after a decision"
grep -q "BLOCK-NO-RECEIPT" "$LOG1" 2>/dev/null \
  && ok "the log row names the decision (BLOCK-NO-RECEIPT)" || no "the decision is not in the log"
awk -F'\t' '!/^#/ && NF>=4 {found=1} END{exit !found}' "$LOG1" 2>/dev/null \
  && ok "the log row carries >=4 tab-separated fields (timestamp, task, depth, decision)" \
  || no "the log row does not carry the declared fields"
grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z' "$LOG1" 2>/dev/null \
  && ok "the log row is timestamped (UTC)" || no "no timestamp on the log row"

echo "== 3. REQUIRED TEST 2 — direct receipt + plain tool call: pass, near-zero overhead =="
R3="$(mkroot r3)"
REC3="$(issue "$R3" T-DIRECT-01 "$D_DIRECT")"
grep -q '^selected_mode: direct$' "$REC3" && ok "fixture receipt is genuinely direct-mode" || no "direct fixture selected $(grep '^selected_mode' "$REC3")"
RC="$(rungate "$R3" gate "$(tool_json Read)" "$WORK/t2pre")"   # non-dispatch never reaches the gate matcher live; counted path below
N=25; T0="$(date +%s%N)"
i=0; while [ "$i" -lt "$N" ]; do
  printf '%s' "$(tool_json Read)" | ROUTING_GATE_ROOT="$R3" bash "$GATE" count >/dev/null 2>&1 || no "count path exited non-zero on iteration $i"
  i=$((i+1))
done
T1="$(date +%s%N)"
MEAN_MS=$(( (T1 - T0) / N / 1000000 ))
[ "$MEAN_MS" -le 250 ] \
  && ok "OVERHEAD BOUND: the * counter averages ${MEAN_MS}ms per tool call over $N runs (asserted <= 250ms; trivial beside any model call)" \
  || no "OVERHEAD: the counter averages ${MEAN_MS}ms per call — that is not trivial"
SF3="$(statefile "$R3" "$REC3")"
[ -f "$SF3" ] && ok "the live state file exists for the open receipt" || no "no live state file was created"
NEV="$(awk -F'\t' '$2=="tool_event"' "$SF3" 2>/dev/null | grep -c . || true)"
[ "${NEV:-0}" = "$N" ] \
  && ok "EXACT: $N tool calls produced exactly $N tool_event rows (append-only, derived by counting)" \
  || no "tool_event rows: ${NEV:-0}, expected $N"
# The counter path never blocks — even under a direct receipt.
RC="$(rungate "$R3" count "$(tool_json Bash)" "$WORK/t2c")"
[ "$RC" = "0" ] && ok "the counter path always exits 0 (observation, not ceremony)" || no "the counter path blocked a tool call (exit $RC)"
# ...and with NO open receipt it stays silent and writes no state.
R3b="$(mkroot r3b)"
RC="$(rungate "$R3b" count "$(tool_json Read)" "$WORK/t2d")"
[ "$RC" = "0" ] && ok "the counter with no open receipt passes (nothing to count against)" || no "counter blocked with no receipt (exit $RC)"
find "$R3b/build-os/packets/routing/live_state" -name '*.tsv' 2>/dev/null | grep -q . \
  && no "the counter invented a state file with no open receipt" \
  || ok "no state file is invented when no receipt is open"

echo "== 4. REQUIRED TEST 3 — light receipt + dispatch attempt: BLOCKED as silent escalation =="
R4="$(mkroot r4)"
REC4="$(issue "$R4" T-LIGHT-01 "$D_LIGHT")"
RC="$(rungate "$R4" gate "$(dispatch_json general-purpose)" "$WORK/t3")"
[ "$RC" = "2" ] && ok "RED: dispatch under a gravito_light receipt is BLOCKED (exit 2)" \
               || no "RED FAILED: light-mode dispatch passed (exit $RC)"
grep -qi "silent escalation" "$WORK/t3.err" \
  && ok "the refusal names silent escalation — the T5 defect, refused BEFORE execution" \
  || no "the refusal does not name silent escalation"
grep -qi "continue the task" "$WORK/t3.err" \
  && ok "the mode refusal carries continue-the-task language" || no "the mode refusal reads as stop-working"
grep -q "BLOCK-MODE-gravito_light" "$R4/build-os/packets/routing/live_gate_log.tsv" 2>/dev/null \
  && ok "the decision is logged with the mode it protected" || no "mode block not logged"
# Direct blocks dispatch identically.
R5="$(mkroot r5)"
issue "$R5" T-DIRECT-02 "$D_DIRECT" >/dev/null
RC="$(rungate "$R5" gate "$(dispatch_json general-purpose)" "$WORK/t3b")"
[ "$RC" = "2" ] && ok "RED: dispatch under a direct receipt is BLOCKED too (no ceremony above depth)" \
               || no "RED FAILED: direct-mode dispatch passed (exit $RC)"
# The LEGAL path up: an evidence-bearing escalation record (routing-check.sh's
# own escalation semantics, reused not re-invented).
REC4b="$REC4"
sed -i 's/^escalation: -$/escalation: escalated gravito_light -> gravito_full/' "$REC4b"
RC="$(rungate "$R4" gate "$(dispatch_json general-purpose)" "$WORK/t3c")"
[ "$RC" = "2" ] && ok "RED: an escalation record with NO evidence still blocks (evidence required)" \
               || no "RED FAILED: evidence-free escalation licensed a dispatch (exit $RC)"
sed -i 's|^escalation_evidence: -$|escalation_evidence: hidden dependency surfaced; new decision recorded before escalated work began|' "$REC4b"
RC="$(rungate "$R4" gate "$(dispatch_json general-purpose)" "$WORK/t3d")"
[ "$RC" = "0" ] && ok "GREEN: the same receipt WITH escalation evidence admits the dispatch (escalation is legal, silence is not)" \
               || no "an evidence-bearing escalation was refused (exit $RC)"

echo "== 5. REQUIRED TEST 4 — full receipt at max_subagents: the LIVE fan-out brake =="
R6="$(mkroot r6)"
REC6="$(issue "$R6" T-FULL-01 "$D_FULL")"
B6="$(awk -F': ' '/^budget_max_subagents: /{print $2}' "$REC6")"
[ "$B6" = "3" ] && ok "fixture full receipt carries budget_max_subagents 3 (the derived default)" || no "unexpected budget: $B6"
i=1; ALLOWED=0
while [ "$i" -le "$B6" ]; do
  RC="$(rungate "$R6" gate "$(dispatch_json general-purpose)" "$WORK/t4-$i")"
  [ "$RC" = "0" ] && ALLOWED=$((ALLOWED+1))
  i=$((i+1))
done
[ "$ALLOWED" = "$B6" ] && ok "GREEN: $B6 task dispatches within budget are admitted" || no "only $ALLOWED of $B6 in-budget dispatches admitted"
RC="$(rungate "$R6" gate "$(dispatch_json general-purpose)" "$WORK/t4-over")"
[ "$RC" = "2" ] && ok "RED: dispatch $((B6+1)) at the budget threshold is BLOCKED — the brake fires BEFORE close, not at it" \
               || no "RED FAILED: over-budget dispatch passed (exit $RC)"
grep -qi "consolidate" "$WORK/t4-over.err" \
  && ok "the block instructs: consolidate remaining work into the parent loop" || no "no consolidate instruction"
grep -qi "preserve" "$WORK/t4-over.err" \
  && ok "the block instructs: preserve completed outputs" || no "no preserve instruction"
grep -qi "gravito_light" "$WORK/t4-over.err" \
  && ok "the block instructs: continue in Light" || no "the block does not name the continue-in-Light path"
SF6="$(statefile "$R6" "$REC6")"
NTD="$(awk -F'\t' '$2=="task_dispatch"' "$SF6" | grep -c . || true)"
[ "${NTD:-0}" = "$B6" ] && ok "EXACT: the state file counts exactly $B6 task_dispatch rows (the blocked one was never admitted)" \
                        || no "task_dispatch rows: ${NTD:-0}, expected $B6"

echo "== 6. REQUIRED TEST 5 — degradation recorded -> routing-check passes the breach-with-note path =="
# 6a. The throttle above ALREADY degraded the receipt automatically (capability 5).
grep -qE '^degradation_note: .+' "$REC6" && ! grep -q '^degradation_note: -$' "$REC6" \
  && ok "the throttle stamped degradation_note automatically (Full->Light, recorded not implied)" \
  || no "the throttle fired without stamping the degradation"
grep -q 'downgraded_to=gravito_light' "$REC6" \
  && ok "the stamp names downgraded_to=gravito_light" || no "no downgraded_to in the stamp"
awk -F'\t' '$2=="DEGRADATION"' "$SF6" | grep -q . \
  && ok "a DEGRADATION record was appended to the live state" || no "no DEGRADATION row in the state file"
# ...and once degraded, the next dispatch is refused at the DEGRADED depth.
RC="$(rungate "$R6" gate "$(dispatch_json general-purpose)" "$WORK/t5deg")"
[ "$RC" = "2" ] && ok "RED: a degraded (now-Light) receipt blocks further dispatch — the degradation is binding" \
               || no "RED FAILED: dispatch after degradation passed (exit $RC)"
# 6b. The deliberate path: the model/operator invokes record-degradation.sh.
R7="$(mkroot r7)"
REC7="$(issue "$R7" T-FULL-02 "$D_FULL")"
bash "$RECDEG" --receipt "$REC7" --reason "budget approached at stage 2; stopped spawning" \
  --evidence "completed outputs at $WORK/evidence" >/dev/null 2>&1; RC=$?
[ "$RC" = "0" ] && ok "record-degradation.sh stamps a receipt deliberately (exit 0)" || no "record-degradation exited $RC"
grep -q 'reason=' "$REC7" && ok "the stamp carries its reason" || no "no reason recorded"
grep -qE 'degraded_at=[0-9]{4}-[0-9]{2}-[0-9]{2}T' "$REC7" && ok "the stamp carries its timestamp" || no "no timestamp in the stamp"
grep -q 'preserved_evidence=' "$REC7" && ok "the stamp carries the preserved-evidence pointer" || no "no evidence pointer in the stamp"
# A second stamp is refused — one degradation record per receipt, no overwrite.
bash "$RECDEG" --receipt "$REC7" --reason "again" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: a second stamp on the same receipt is REFUSED (a record is never overwritten)" \
               || no "RED FAILED: a re-stamp passed (exit $RC)"
bash "$RECDEG" --receipt "$WORK/absent.md" --reason "x" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: a missing receipt is refused" || no "missing receipt got exit $RC"
bash "$RECDEG" --receipt "$REC7" --reason "" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: an empty reason is refused (a degradation nobody can audit is a bypass)" || no "empty reason got exit $RC"
# 6c. The close-time gate PASSES an honestly-degraded over-budget receipt.
sed -i 's/^executed_mode: -$/executed_mode: gravito_full/' "$REC7"
sed -i 's/^consumed_total_tokens: -$/consumed_total_tokens: 2500000/' "$REC7"
bash "$RCHECK" check --receipt "$REC7" >"$WORK/t5.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "GREEN: routing-check passes the breach WITH its degradation note (honest degradation is survivable)" \
               || { no "an honestly-degraded run was refused (exit $RC)"; sed 's/^/      | /' "$WORK/t5.out"; }

echo "== 7. REQUIRED TEST 6 — the block message continues the task, never stops it =="
grep -q "Stop the expensive mode, not the task" "$WORK/t4-over.err" \
  && ok "the throttle block carries the exact doctrine: 'Stop the expensive mode, not the task'" \
  || no "the doctrine string is missing from the throttle block"
grep -q "do not stop working" "$WORK/t4-over.err" \
  && ok "the throttle block says in so many words: 'do not stop working'" \
  || no "'do not stop working' is missing"
for f in t1 t3 t3b t4-over; do
  grep -qiE "continue the task|do not stop working" "$WORK/$f.err" \
    && ok "block message $f carries continue-the-task language" \
    || no "block message $f could be read as stop-working"
done

echo "== 8. REQUIRED TEST 7 — completed evidence survives degradation =="
NROWS_BEFORE="$(grep -c . "$SF6")"
awk -F'\t' '$2=="task_dispatch"' "$SF6" | grep -c . > "$WORK/before_td.txt"
# The state file after throttling + degradation still carries every pre-degradation row.
[ "$(awk -F'\t' '$2=="task_dispatch"' "$SF6" | grep -c .)" = "$B6" ] \
  && ok "all $B6 pre-degradation task_dispatch rows survive in the state file (completed evidence preserved)" \
  || no "pre-degradation dispatch rows were lost"
awk -F'\t' '$2=="DEGRADATION" && $3 ~ /preserved_evidence=/' "$SF6" | grep -q . \
  && ok "the DEGRADATION row itself carries the preserved-evidence pointer" \
  || no "the DEGRADATION row carries no evidence pointer"
# And record-degradation.sh changes NOTHING in the receipt except its one field.
R8="$(mkroot r8)"
REC8="$(issue "$R8" T-FULL-03 "$D_FULL")"
cp "$REC8" "$WORK/rec8.before"
bash "$RECDEG" --receipt "$REC8" --reason "fixture" --evidence "ptr" >/dev/null 2>&1
DIFFLINES="$(diff "$WORK/rec8.before" "$REC8" | grep -c '^[<>]' || true)"
[ "${DIFFLINES:-9}" = "2" ] \
  && ok "the stamp is surgical: exactly one line changed (old + new = 2 diff lines)" \
  || no "the stamp altered ${DIFFLINES:-?} diff lines, not just degradation_note"

echo "== 9. REQUIRED TEST 8 — EXACT vs ESTIMATE labeled on every state-file field =="
haslabel(){ # <file> <field> <required-substring-of-label>
  awk -F'\t' -v f="$2" -v s="$3" '$1=="label" && $2==f && index($3,s)>0 {hit=1} END{exit !hit}' "$1"
}
haslabel "$SF6" task_dispatches "EXACT" \
  && ok "task_dispatches labeled EXACT" || no "task_dispatches not labeled EXACT"
haslabel "$SF6" process_dispatches "EXACT" \
  && ok "process_dispatches labeled EXACT" || no "process_dispatches not labeled EXACT"
haslabel "$SF6" tool_events "EXACT" \
  && ok "tool_events labeled EXACT" || no "tool_events not labeled EXACT"
haslabel "$SF6" tokens "unavailable_live" \
  && ok "tokens labeled unavailable_live — NOT hook-visible in interactive sessions, not faked" \
  || no "tokens field lacks the unavailable_live admission"
grep -q 'close-time reconciliation' "$SF6" \
  && ok "the tokens label names the close-time reconciliation path (telemetry where headless)" \
  || no "no close-time reconciliation note"
haslabel "$SF6" tool_failures "where PostToolUse" \
  && ok "tool_failures label admits visibility depends on what PostToolUse exposes" \
  || no "tool_failures label overclaims"
haslabel "$SF6" elapsed_s "EXACT" \
  && ok "elapsed_s labeled EXACT (derived at read time from issued_at, never stored)" \
  || no "elapsed_s not labeled"
# Both creators emit the identical label block — two writers, one truth.
R9="$(mkroot r9)"
REC9="$(issue "$R9" T-FULL-04 "$D_FULL")"
bash "$RECDEG" --receipt "$REC9" --reason "label-twin fixture" >/dev/null 2>&1
SF9="$(statefile "$R9" "$REC9")"
diff <(grep -E '^label\t' "$SF6") <(grep -E '^label\t' "$SF9") >/dev/null 2>&1 \
  && ok "gate-created and degradation-created state files carry byte-identical label blocks" \
  || no "the two label-block writers have diverged"
# status derives elapsed from issued_at vs now, and repeats the token admission.
ROUTING_GATE_ROOT="$R6" bash "$GATE" status >"$WORK/status.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "routing-gate status reads the live state (exit 0)" || no "status exited $RC"
grep -qE 'elapsed_s: [0-9]+' "$WORK/status.out" \
  && ok "status derives elapsed_s (receipt issued_at vs now)" || no "status derives no elapsed time"
grep -q 'unavailable_live' "$WORK/status.out" \
  && ok "status repeats the tokens admission rather than inventing a number" || no "status invents token visibility"

echo "== 10. REQUIRED TEST 9 — task vs process dispatch counts reconcile over a fabricated stream =="
R10="$(mkroot r10)"
REC10="$(issue "$R10" T-FULL-05 "$D_FULL")"
A10="$(awk -F': ' '/^process_dispatch_allowance: /{print $2}' "$REC10")"
[ "$A10" = "7" ] \
  && ok "the receipt carries process_dispatch_allowance: 7 — the doctrine's largest legal chain (mandatory_full_regate: builder,qa,reviewer,fix-builder,qa,reviewer,archivist), SEPARATE from budget_max_subagents" \
  || no "process_dispatch_allowance is '$A10', not the default 7"
for t in builder qa; do
  RC="$(rungate "$R10" gate "$(dispatch_json $t)" "$WORK/t9-$t)")"
  [ "$RC" = "0" ] && ok "process-role dispatch ($t) admitted against the allowance, not the task budget" \
                  || no "process dispatch $t blocked (exit $RC)"
done
for i in 1 2; do
  RC="$(rungate "$R10" gate "$(dispatch_json general-purpose)" "$WORK/t9-task$i")"
  [ "$RC" = "0" ] || no "task dispatch $i blocked unexpectedly (exit $RC)"
done
for t in reviewer builder qa reviewer2 archivist; do
  role="${t%2}"
  RC="$(rungate "$R10" gate "$(dispatch_json $role)" "$WORK/t9-$t)")"
  [ "$RC" = "0" ] || no "process dispatch $t blocked (exit $RC) — the full mandatory_full_regate chain must fit the allowance"
done
SF10="$(statefile "$R10" "$REC10")"
NT="$(awk -F'\t' '$2=="task_dispatch"' "$SF10" | grep -c . || true)"
NP="$(awk -F'\t' '$2=="process_dispatch"' "$SF10" | grep -c . || true)"
[ "${NT:-0}" = "2" ] && ok "EXACT: 2 task dispatches counted as task work (against budget_max_subagents)" || no "task count ${NT:-0}, expected 2"
[ "${NP:-0}" = "7" ] && ok "EXACT: 7 process-role dispatches counted separately (attributed governance_process) — the mandatory_full_regate shape fits" || no "process count ${NP:-0}, expected 7"
awk -F'\t' '$2=="process_dispatch" && $3 !~ /governance_process/' "$SF10" | grep -q . \
  && no "a process_dispatch row lacks its governance_process attribution" \
  || ok "every process_dispatch row is attributed to governance_process"
# The EIGHTH process dispatch is at the allowance: blocked, attributed, continue-language.
RC="$(rungate "$R10" gate "$(dispatch_json build-orchestrator)" "$WORK/t9-over")"
[ "$RC" = "2" ] && ok "RED: process dispatch 8 at allowance 7 is BLOCKED (governance ceremony is budgeted too, above the largest legal chain)" \
               || no "RED FAILED: process dispatch over allowance passed (exit $RC)"
grep -qi "governance_process" "$WORK/t9-over.err" \
  && ok "the process block names its attribution layer (governance_process)" || no "process block unattributed"
grep -qi "do not stop working" "$WORK/t9-over.err" \
  && ok "the process block also continues the task" || no "process block reads as stop-working"
# ...and task dispatches were NOT consumed by process traffic: task 3 still fits.
RC="$(rungate "$R10" gate "$(dispatch_json general-purpose)" "$WORK/t9-task3")"
[ "$RC" = "0" ] && ok "task dispatch 3 still admitted — process traffic did not eat the task budget" \
               || no "the two ledgers bled into each other (exit $RC)"

echo "== 11. REQUIRED TEST 10 — contribution accounting is MANDATORY for Full =="
R11="$(mkroot r11)"
REC11="$(issue "$R11" T-FULL-06 "$D_FULL")"
sed -i 's/^executed_mode: -$/executed_mode: gravito_full/' "$REC11"
sed -i 's/^consumed_subagents: -$/consumed_subagents: 2/' "$REC11"
sed -i '/^contribution: /d' "$REC11"
bash "$RCHECK" check --receipt "$REC11" >"$WORK/t10.out" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: a Full receipt closed with dispatches>0 and NO contribution rows is REFUSED" \
               || no "RED FAILED: contribution-free Full close passed (exit $RC)"
grep -qi "CONTRIBUTION-MISSING" "$WORK/t10.out" \
  && ok "the refusal is named CONTRIBUTION-MISSING" || no "the refusal is unnamed"
printf 'contribution: general-purpose | - | - | changed_implementation=- | changed_conclusion=- | caught_defect=- | duplicated_work=- | tokens=- | cost=- | time=-\n' >> "$REC11"
printf 'contribution: general-purpose | - | - | changed_implementation=- | changed_conclusion=- | caught_defect=- | duplicated_work=- | tokens=- | cost=- | time=-\n' >> "$REC11"
bash "$RCHECK" check --receipt "$REC11" >"$WORK/t10b.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "GREEN: all-'-' contribution rows PASS as admissions (an unknown is not a zero)" \
               || { no "all-'-' rows were refused (exit $RC)"; sed 's/^/      | /' "$WORK/t10b.out"; }
grep -qi "non-contributing" "$WORK/t10b.out" \
  && ok "...and the pass REPORTS them as non-contributing (counted, not hidden)" \
  || no "non-contributing rows pass silently"
# A malformed contribution row is refused, not skipped.
printf 'contribution: broken-row-with-no-fields\n' >> "$REC11"
bash "$RCHECK" check --receipt "$REC11" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: a malformed contribution row is REFUSED (an unreadable measurement is not agreement)" \
               || no "RED FAILED: malformed contribution row passed (exit $RC)"
sed -i '/^contribution: broken-row-with-no-fields$/d' "$REC11"
# The dispatch gate seeded stub rows at dispatch time (close-fill tooling).
grep -c '^contribution: ' "$REC10" | grep -qx "3" \
  && ok "the gate appended one stub contribution row per admitted Full task dispatch (3 rows for 3 dispatches)" \
  || no "stub rows: $(grep -c '^contribution: ' "$REC10"), expected 3 (one per task dispatch)"
grep -c '^contribution: ' "$REC6" | grep -qx "$B6" \
  && ok "throttled receipt carries exactly $B6 stub rows — the blocked dispatch seeded nothing" \
  || no "stub-row count disagrees with admitted dispatches"

echo "== 12. REQUIRED TEST 11 — receipt and live state must AGREE at close =="
R12="$(mkroot r12)"
REC12="$(issue "$R12" T-FULL-07 "$D_FULL")"
SD12="$R12/build-os/packets/routing/live_state"; mkdir -p "$SD12"
SF12="$SD12/$(basename "$REC12" .md).tsv"
{ printf '# fabricated state for the close-consistency drive\n'
  printf '2026-08-05T22:00:00Z\ttask_dispatch\tsubagent_type=general-purpose\n'
  printf '2026-08-05T22:01:00Z\ttask_dispatch\tsubagent_type=general-purpose\n'
  printf '2026-08-05T22:02:00Z\tprocess_dispatch\tsubagent_type=qa attributed=governance_process\n'
} > "$SF12"
sed -i 's/^executed_mode: -$/executed_mode: gravito_full/' "$REC12"
sed -i 's/^consumed_subagents: -$/consumed_subagents: 2/' "$REC12"
sed -i 's/^consumed_process_dispatches: -$/consumed_process_dispatches: 1/' "$REC12"
printf 'contribution: general-purpose | seeded | out.md | changed_implementation=y | changed_conclusion=n | caught_defect=n | duplicated_work=n | tokens=- | cost=- | time=-\n' >> "$REC12"
bash "$RCHECK" check --receipt "$REC12" >"$WORK/t11.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "GREEN: filled consumption that MATCHES the state-file counts passes" \
               || { no "matching counts were refused (exit $RC)"; sed 's/^/      | /' "$WORK/t11.out"; }
sed -i 's/^consumed_subagents: 2$/consumed_subagents: 5/' "$REC12"
bash "$RCHECK" check --receipt "$REC12" >"$WORK/t11b.out" 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: a receipt claiming 5 dispatches over a state file counting 2 is REFUSED" \
               || no "RED FAILED: state/receipt disagreement passed (exit $RC)"
grep -qi "STATE-DISAGREE" "$WORK/t11b.out" \
  && ok "the disagreement is named STATE-DISAGREE" || no "the disagreement is unnamed"
grep -qi "never reconciled" "$WORK/t11b.out" \
  && ok "the report says plainly it is REPORTED, never reconciled — no side is auto-corrected" \
  || no "the check does not disclaim reconciliation"
sed -i 's/^consumed_subagents: 5$/consumed_subagents: -/' "$REC12"
sed -i 's/^consumed_process_dispatches: 1$/consumed_process_dispatches: -/' "$REC12"
bash "$RCHECK" check --receipt "$REC12" >"$WORK/t11c.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "GREEN: '-' consumption beside a state file passes — absence is an admission, never refused" \
               || no "an admission beside a state file was refused (exit $RC)"

echo "== 13. Fail-open, and the operator escape that leaves a trace =="
R13="$(mkroot r13)"
issue "$R13" T-FULL-08 "$D_FULL" >/dev/null
RC="$(rungate "$R13" gate "this is not json at all" "$WORK/t13")"
[ "$RC" = "0" ] && ok "GREEN: the gate FAILS OPEN on unparseable input (a broken gate must not brick every session)" \
               || no "the gate failed CLOSED on its own error (exit $RC) — denial of service against the operator"
grep -q "FAIL-OPEN" "$R13/build-os/packets/routing/live_gate_log.tsv" 2>/dev/null \
  && ok "the fail-open event is LOGGED (a silent fail-open is an invisible outage)" \
  || no "fail-open left no trace"
RC="$(ROUTING_GATE_DISABLE=1; export ROUTING_GATE_DISABLE; rungate "$R4" gate "$(dispatch_json general-purpose)" "$WORK/t13b")"
[ "$RC" = "0" ] && ok "ROUTING_GATE_DISABLE=1 admits the dispatch (operator-only escape)" \
               || no "the documented escape does not work (exit $RC)"
grep -q "DISABLED-BY-OPERATOR" "$R4/build-os/packets/routing/live_gate_log.tsv" 2>/dev/null \
  && ok "the escape is LOGGED in live_gate_log.tsv — an escape that leaves no trace is a bypass" \
  || no "the escape left no trace"

echo "== 14. PostToolUse: failures counted where visible, admitted where not =="
R14="$(mkroot r14)"
REC14="$(issue "$R14" T-FULL-09 "$D_FULL")"
RC="$(rungate "$R14" post "$(post_json '{"success":false,"error":"boom"}')" "$WORK/t14a")"
[ "$RC" = "0" ] && ok "the post observer never blocks (exit 0)" || no "post observer blocked (exit $RC)"
SF14="$(statefile "$R14" "$REC14")"
awk -F'\t' '$2=="tool_failure"' "$SF14" 2>/dev/null | grep -q . \
  && ok "EXACT: a tool_response carrying success:false is counted as a tool_failure" \
  || no "a visible failure was not counted"
RC="$(rungate "$R14" post "$(post_json '{"success":true}')" "$WORK/t14b")"
NF14="$(awk -F'\t' '$2=="tool_failure"' "$SF14" | grep -c . || true)"
[ "${NF14:-0}" = "1" ] && ok "a success:true response adds NO failure row" || no "a success was miscounted as failure (${NF14:-0} rows)"
RC="$(rungate "$R14" post "$(post_json '{"stdout":"no status field here"}')" "$WORK/t14c")"
NF14="$(awk -F'\t' '$2=="tool_failure"' "$SF14" | grep -c . || true)"
[ "${NF14:-0}" = "1" ] \
  && ok "a response exposing NO error status adds no row — unavailable is admitted in the label, never guessed" \
  || no "an invisible status was guessed (${NF14:-0} rows)"

echo "== 15. Close-fill schema: extended by EXTENSION — old receipts stay valid =="
R15="$(mkroot r15)"
REC15="$(issue "$R15" T-FULL-10 "$D_FULL")"
for f in consumed_process_dispatches attr_task_execution attr_context_retrieval attr_subagent_execution \
         attr_verification attr_review attr_governance_process attr_experiment_audit; do
  grep -q "^$f: -$" "$REC15" && ok "receipt carries $f, '-' at issue" || no "receipt missing $f"
done
grep -q '^# --- contribution' "$REC15" \
  && ok "the receipt documents the contribution-row schema beside the fields it fills" \
  || no "no contribution schema in the receipt"
# An OLD-schema receipt (every new field stripped) still passes: absent = admission.
OLD15="$WORK/old-schema.md"
grep -vE '^(process_dispatch_allowance|consumed_process_dispatches|attr_[a-z_]+): |^# --- (process|contribution|attribution)' "$REC15" > "$OLD15"
bash "$RCHECK" check --receipt "$OLD15" >"$WORK/t15.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "GREEN: a PACKET-0050-era receipt with NO new fields still passes (absent = '-' admission, old receipts stay valid)" \
               || { no "an old-schema receipt was refused (exit $RC)"; sed 's/^/      | /' "$WORK/t15.out"; }
# An unknown attribution layer is refused — the seven layers are the schema.
cp "$REC15" "$WORK/badattr.md"
printf 'attr_marketing_flair: 12345\n' >> "$WORK/badattr.md"
bash "$RCHECK" check --receipt "$WORK/badattr.md" >/dev/null 2>&1; RC=$?
[ "$RC" = "2" ] && ok "RED: an undeclared attribution layer (attr_marketing_flair) is REFUSED" \
               || no "RED FAILED: an invented attribution layer passed (exit $RC)"

echo "== 16. Registration: RULING 4, same commit, crosswalk, census =="
REG="$SRC/build-os/registry/control_registry.txt"
XW="$SRC/build-os/registry/neurocosmology_crosswalk.txt"
MUTREG="$SRC/build-os/registry/mutator_registry.txt"
grep -qxF 'owning_module: .claude/hooks/routing-gate.sh' "$REG" \
  && ok "routing-gate.sh owns a control registry entry" || no "routing-gate.sh is unregistered"
grep -qxF 'owning_module: build-os/tools/record-degradation.sh' "$REG" \
  && ok "record-degradation.sh owns a control registry entry" || no "record-degradation.sh is unregistered"
grep -qxF 'owning_module: tests/routing_live_gate_tests.sh' "$REG" \
  && ok "this suite owns a control registry entry" || no "this suite is unregistered"
grep -qxF 'actor_or_tool: .claude/hooks/routing-gate.sh' "$MUTREG" \
  && ok "routing-gate.sh's durable writes are censused in the mutator registry" \
  || no "routing-gate.sh writes durable state and is not in the mutator census"
grep -qxF 'actor_or_tool: build-os/tools/record-degradation.sh' "$MUTREG" \
  && ok "record-degradation.sh's receipt stamp is censused in the mutator registry" \
  || no "record-degradation.sh mutates receipts and is not in the mutator census"
for c in routing.live_dispatch_gate routing.live_gate_ledger_append routing.degradation_stamp suite.routing_live_gate; do
  grep -qxF "control: $c" "$XW" && ok "crosswalk binds $c" || no "no crosswalk binding for $c"
done
grep -q 'routing_live_gate_tests.sh' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained into tests/build_os_tests.sh (not discoverable-only)" \
  || no "this suite is not chained — it would run only when remembered"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
