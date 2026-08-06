#!/usr/bin/env bash
# Build OS — UNIVERSAL TASK-ENTRY governance (PACKET-0054-universal-task-entry):
# the execution-start boundary for EVERY substantive task, including parent-only
# work that dispatches nothing.
#
# WHAT CHANGED WITH THIS PACKET, AND WHY THIS SUITE EXISTS. PACKET-0053 gated
# dispatch (Task|Agent): a session that spawned no subagents executed entirely
# ungated beyond counting. The operator's correction: close the gap "from
# controlling when Claude spawns more agents to controlling every substantive AI
# execution from task entry through completion". So the PreToolUse gate now
# also fires on MUTATION-CAPABLE tools — Edit, Write, NotebookEdit, Bash — and
# refuses them without an open routing receipt; exploratory reads (Read/Grep/
# Glob and read-only git inspection) stay ungated but are COUNTED into the state
# file, so the record shows the explore/execute split; a repetitive parent loop
# trips a fire-once REASSESS block; and the whole hook surface is expressed as a
# PROVIDER-ADAPTER contract with honest telemetry tiers
# (EXACT | ESTIMATE | CLOSE-TIME | UNAVAILABLE).
#
# THE DEADLOCK GUARD IS THE LOAD-BEARING EXCEPTION: a Bash command invoking the
# routing tools themselves (route-task.sh, mode-select.mjs, routing-check.sh,
# record-degradation.sh) passes UNGATED and logged — without it no session could
# ever issue the receipt its first gated call requires.
#
# HONESTY BOUND, stated here as in the contract: the Bash classification is a
# NAMED HEURISTIC over the raw hook JSON. A hostile command evades it trivially
# (sh -c, eval, a wrapper script). The gate is discipline-for-honest-agents plus
# an audit trail, NOT a sandbox — the sandbox is the platform's permission
# system. This suite drives the hook DIRECTLY with fabricated stdin JSON
# (hooks load at session start; the session shipping this file is not governed
# by it). Deterministic, local, model-free; fixtures in mktemp; the live
# receipt store is read and never written.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="$SRC/.claude/hooks/routing-gate.sh"
ROUTE="$SRC/build-os/tools/route-task.sh"
RCHECK="$SRC/build-os/tools/routing-check.sh"
RECDEG="$SRC/build-os/tools/record-degradation.sh"
CONTRACT_LIVE="$SRC/build-os/memory/routing_contract_live.md"
ADAPTER="$SRC/build-os/memory/provider_adapter_contract.md"
SETTINGS="$SRC/.claude/settings.json"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The descriptor builder (routing_enforcement_tests.sh's, verbatim) — fixture
# receipts come from the REAL issuer, so a shape the live tool would never emit
# cannot smuggle a pass.
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
D_FULL="$(mkdesc 4 true 1 true false medium high_blast_radius)"

mkroot(){ mkdir -p "$WORK/$1/build-os/packets/routing"; printf '%s' "$WORK/$1"; }
issue(){ # <root> <task-id> <descriptor>
  bash "$ROUTE" --task-id "$2" --description "task-entry fixture $2" --descriptor "$3" \
    --out "$1/build-os/packets/routing" >/dev/null 2>&1 || return 1
  find "$1/build-os/packets/routing" -maxdepth 1 -name "routing-$2-*.md" | sed -n '1p'
}
# Hook stdin fabrications — the documented PreToolUse shapes per tool.
edit_json(){ printf '{"session_id":"s1","transcript_path":"/tmp/t","cwd":".","hook_event_name":"PreToolUse","tool_name":"Edit","tool_input":{"file_path":"/x/f.txt","old_string":"a","new_string":"b"}}'; }
write_json(){ printf '{"session_id":"s1","transcript_path":"/tmp/t","cwd":".","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/x/f.txt","content":"hello"}}'; }
nb_json(){ printf '{"session_id":"s1","transcript_path":"/tmp/t","cwd":".","hook_event_name":"PreToolUse","tool_name":"NotebookEdit","tool_input":{"notebook_path":"/x/n.ipynb","new_source":"x=1"}}'; }
bash_json(){ # <command>
  printf '{"session_id":"s1","transcript_path":"/tmp/t","cwd":".","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"
}
tool_json(){ # <tool_name> [input-payload]
  printf '{"session_id":"s1","transcript_path":"/tmp/t","cwd":".","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"file_path":"/x","payload":"%s"}}' "$1" "${2:-p}"
}
rungate(){ # <root> <subcmd> <stdin> <outfile-stem> — exit code on stdout
  printf '%s' "$3" | ROUTING_GATE_ROOT="$1" bash "$GATE" "$2" >"$4.out" 2>"$4.err"; echo $?
}
statefile(){ printf '%s/build-os/packets/routing/live_state/%s.tsv' "$1" "$(basename "$2" .md)"; }
logfile(){ printf '%s/build-os/packets/routing/live_gate_log.tsv' "$1"; }

echo "== 1. Surfaces: the mutgate wiring, the adapter contract, the stated heuristic bound =="
if command -v jq >/dev/null 2>&1 && [ -f "$SETTINGS" ]; then
  jq -e '.hooks.PreToolUse[] | select(.matcher=="Edit|Write|NotebookEdit|Bash") | .hooks[] | select(.command | contains("routing-gate.sh mutgate"))' "$SETTINGS" >/dev/null 2>&1 \
    && ok "settings.json wires routing-gate.sh mutgate as PreToolUse on Edit|Write|NotebookEdit|Bash" \
    || no "no PreToolUse Edit|Write|NotebookEdit|Bash wiring for routing-gate.sh mutgate"
  jq -e '.hooks.PreToolUse[] | select(.matcher=="Task|Agent")' "$SETTINGS" >/dev/null 2>&1 \
    && ok "the PACKET-0053 dispatch matcher survived the edit" || no "the Task|Agent matcher was lost"
  jq -e '.hooks.PreToolUse[] | select(.matcher=="*")' "$SETTINGS" >/dev/null 2>&1 \
    && ok "the * counter matcher survived the edit" || no "the * counter matcher was lost"
else
  no "jq or settings.json unavailable — the wiring cannot be verified"
fi
# The provider-adapter contract: interface, tiers, adapter #1, the unverified #2.
[ -f "$ADAPTER" ] && ok "provider_adapter_contract.md exists" || no "provider_adapter_contract.md missing"
if [ -f "$ADAPTER" ]; then
  AB="$(wc -c < "$ADAPTER" | tr -d ' ')"
  [ "${AB:-99999}" -le 4000 ] && ok "adapter contract stays within its 4000-byte ceiling ($AB B)" \
                              || no "adapter contract is $AB B, over the 4000-byte ceiling"
  for verb in "observe" "block" "bind"; do
    grep -qi "$verb" "$ADAPTER" && ok "adapter interface names the verb: $verb" || no "adapter interface missing verb: $verb"
  done
  for tier in EXACT ESTIMATE CLOSE-TIME UNAVAILABLE; do
    grep -q "$tier" "$ADAPTER" && ok "tier vocabulary present: $tier" || no "tier vocabulary missing: $tier"
  done
  grep -q '\.claude/hooks/routing-gate\.sh' "$ADAPTER" \
    && ok "ADAPTER #1 is named by path: .claude/hooks/routing-gate.sh" || no "adapter #1 not named by path"
  grep -qi "Claude Code hooks" "$ADAPTER" && ok "adapter #1 names its host (Claude Code hooks)" || no "adapter #1 host unnamed"
  grep -qi "Codex" "$ADAPTER" && ok "a second-adapter row (Codex) exists" || no "no Codex row"
  grep -qi "interface-unverified" "$ADAPTER" \
    && ok "the Codex row is marked interface-unverified (host unreachable — not guessed)" \
    || no "the Codex row overclaims a hook surface nobody verified"
fi
# The live contract: the boundary, the heuristic honesty, and the first action.
grep -qi "mutation-capable" "$CONTRACT_LIVE" \
  && ok "the live contract states the mutation-capable task-entry boundary" \
  || no "the contract does not state the mutation-capable boundary"
grep -qi "heuristic" "$CONTRACT_LIVE" && grep -qi "sh -c" "$CONTRACT_LIVE" \
  && ok "the Bash classification is stated as a NAMED HEURISTIC a hostile command can evade (sh -c named)" \
  || no "the heuristic bound (sh -c evasion) is unstated"
grep -qi "not a sandbox" "$CONTRACT_LIVE" \
  && ok "the contract says plainly the gate is NOT a sandbox" || no "'not a sandbox' is unstated"
grep -qi "permission system" "$CONTRACT_LIVE" \
  && ok "the contract names the platform's permission system as the actual sandbox" \
  || no "the actual sandbox is unnamed"
grep -qiE "first action" "$CONTRACT_LIVE" && grep -qi "issue or confirm" "$CONTRACT_LIVE" \
  && ok "the contract states the FIRST action of any new session: issue or confirm a routing receipt" \
  || no "the first-action-of-session rule is unstated"
grep -qi "provider_adapter_contract.md" "$CONTRACT_LIVE" \
  && ok "the live contract points at the adapter contract (split, not forked)" \
  || no "no pointer to provider_adapter_contract.md"

echo "== 2. RED — mutation-capable calls with NO open receipt are BLOCKED, with the recovery command =="
RA="$(mkroot ra)"
RC="$(rungate "$RA" mutgate "$(edit_json)" "$WORK/m-edit")"
[ "$RC" = "2" ] && ok "RED: Edit with an empty receipt store is BLOCKED (exit 2)" || no "RED FAILED: unrouted Edit passed (exit $RC)"
RC="$(rungate "$RA" mutgate "$(write_json)" "$WORK/m-write")"
[ "$RC" = "2" ] && ok "RED: Write without a receipt is BLOCKED" || no "RED FAILED: unrouted Write passed (exit $RC)"
RC="$(rungate "$RA" mutgate "$(nb_json)" "$WORK/m-nb")"
[ "$RC" = "2" ] && ok "RED: NotebookEdit without a receipt is BLOCKED" || no "RED FAILED: unrouted NotebookEdit passed (exit $RC)"
RC="$(rungate "$RA" mutgate "$(bash_json 'npm install left-pad')" "$WORK/m-bash")"
[ "$RC" = "2" ] && ok "RED: a generic Bash command without a receipt is BLOCKED (mutation-capable by default)" \
               || no "RED FAILED: unrouted Bash passed (exit $RC)"
# The refusal names the recovery command with a USABLE example, incl direct mode.
grep -q "route-task.sh --task-id" "$WORK/m-edit.err" \
  && ok "the refusal carries a usable route-task.sh invocation" || no "no usable recovery command in the refusal"
grep -qi "direct" "$WORK/m-edit.err" \
  && ok "the refusal carries a cheap direct-mode example — tiny work routes too, it just routes cheaply" \
  || no "no direct-mode example: the refusal makes routing look expensive"
grep -qiE "continue the task|not the work" "$WORK/m-edit.err" \
  && ok "the mutation refusal carries continue-the-task language" || no "the refusal reads as stop-working"
# The example is USABLE: extract the refusal's own descriptor and run it.
EXDESC="$(sed -n "s/.*--descriptor '\({.*}\)'.*/\1/p" "$WORK/m-edit.err" | head -n1)"
if [ -n "$EXDESC" ]; then
  bash "$ROUTE" --task-id refusal-example-check --description "the refusal's own example" \
    --descriptor "$EXDESC" --out "$WORK/exdesc" >"$WORK/exdesc.out" 2>&1; RC=$?
  [ "$RC" = "0" ] && grep -q "selected_mode direct" "$WORK/exdesc.out" \
    && ok "EXECUTED: the refusal's own example descriptor issues a real receipt and selects direct" \
    || no "the refusal's example does not actually work (exit $RC: $(head -n1 "$WORK/exdesc.out" 2>/dev/null))"
else
  no "the refusal carries no extractable --descriptor example"
fi
grep -q "BLOCK-MUTATION-NO-RECEIPT" "$(logfile "$RA")" 2>/dev/null \
  && ok "the block is logged BLOCK-MUTATION-NO-RECEIPT in live_gate_log.tsv" || no "the mutation block left no log row"
# A store holding only CLOSED receipts still blocks (open = executed_mode '-').
RB="$(mkroot rb)"
RECB="$(issue "$RB" T-CLOSED-M "$D_DIRECT")"
sed -i 's/^executed_mode: -$/executed_mode: direct/' "$RECB"
RC="$(rungate "$RB" mutgate "$(edit_json)" "$WORK/m-closed")"
[ "$RC" = "2" ] && ok "RED: a store holding only CLOSED receipts still blocks mutation" \
               || no "RED FAILED: a closed receipt licensed a mutation (exit $RC)"
# ...and ANY open receipt licenses mutation — direct routes cheaply, not never.
RD="$(mkroot rd)"
RECD="$(issue "$RD" T-DIRECT-M "$D_DIRECT")"
RC="$(rungate "$RD" mutgate "$(edit_json)" "$WORK/m-open")"
[ "$RC" = "0" ] && ok "GREEN: Edit under an OPEN direct receipt is ADMITTED (direct-mode work is routed work)" \
               || no "an open direct receipt did not license Edit (exit $RC)"
SFD="$(statefile "$RD" "$RECD")"
awk -F'\t' '$2=="mutation_event"' "$SFD" 2>/dev/null | grep -q . \
  && ok "the admitted Edit is counted as a mutation_event in the state file (item-4 binding)" \
  || no "the admitted mutation left no mutation_event row"

echo "== 3. THE DEADLOCK GUARD — routing tools pass ungated, in BOTH directions =="
# Direction 1: NO receipt open — the bootstrap. Without this, no session could
# ever issue the receipt its first gated call requires.
RG="$(mkroot rg)"
for tool_cmd in \
  "build-os/tools/route-task.sh --task-id x --description y --descriptor z" \
  "node build-os/tools/mode-select.mjs '{}'" \
  "bash build-os/tools/routing-check.sh check" \
  "build-os/tools/record-degradation.sh --receipt r.md --reason because"; do
  RC="$(rungate "$RG" mutgate "$(bash_json "$tool_cmd")" "$WORK/dg")"
  [ "$RC" = "0" ] && ok "DEADLOCK GUARD: routing-tool Bash passes UNGATED with no receipt (${tool_cmd%% *})" \
                  || no "DEADLOCK: the gate blocked its own recovery command (${tool_cmd%% *}, exit $RC)"
done
NPASS="$(grep -c "ROUTING-TOOL-PASS" "$(logfile "$RG")" 2>/dev/null || true)"
[ "${NPASS:-0}" = "4" ] && ok "all 4 routing-tool passes are logged ROUTING-TOOL-PASS (ungated is not untraced)" \
                        || no "ROUTING-TOOL-PASS rows: ${NPASS:-0}, expected 4"
# Direction 2: a receipt IS open — still ungated, logged, and state-bound.
RH="$(mkroot rh)"
RECH="$(issue "$RH" T-DIRECT-DG "$D_DIRECT")"
RC="$(rungate "$RH" mutgate "$(bash_json 'bash build-os/tools/routing-check.sh check')" "$WORK/dg2")"
[ "$RC" = "0" ] && ok "DEADLOCK GUARD: routing-tool Bash passes ungated with a receipt open too" \
               || no "routing-tool Bash blocked under an open receipt (exit $RC)"
grep -q "ROUTING-TOOL-PASS" "$(logfile "$RH")" 2>/dev/null \
  && ok "...and is logged in that direction as well" || no "open-receipt routing-tool pass left no log row"
SFH="$(statefile "$RH" "$RECH")"
awk -F'\t' '$2=="routing_tool_pass"' "$SFH" 2>/dev/null | grep -q . \
  && ok "...and lands in the open receipt's state file (bound to the task record)" \
  || no "the routing-tool pass is not bound into the state file"

echo "== 4. Git classification: read-only inspection passes; mutation-capable git is gated =="
RI="$(mkroot ri)"
for gcmd in "git status" "git log --oneline -5" "git diff HEAD~1" "git show HEAD" \
            "git rev-parse HEAD" "git ls-files" "git branch -l"; do
  RC="$(rungate "$RI" mutgate "$(bash_json "$gcmd")" "$WORK/gro")"
  [ "$RC" = "0" ] && ok "read-only git passes ungated with no receipt: $gcmd" \
                  || no "read-only git was blocked: $gcmd (exit $RC)"
done
grep -q "GIT-READONLY-PASS" "$(logfile "$RI")" 2>/dev/null \
  && ok "read-only git passes are logged GIT-READONLY-PASS" || no "read-only git pass left no log row"
for gcmd in "git push origin main" "git commit -m wip" "git checkout -- ." \
            "git reset --hard HEAD~1" "git rebase main" "git stash" \
            "git status && git push" "git branch --force topic HEAD~1"; do
  RC="$(rungate "$RI" mutgate "$(bash_json "$gcmd")" "$WORK/gmu")"
  [ "$RC" = "2" ] && ok "mutation-capable git is BLOCKED without a receipt: $gcmd" \
                  || no "mutation-capable git passed unrouted: $gcmd (exit $RC)"
done
# With a receipt open, read-only git is counted as an EXPLORATORY event.
RJ="$(mkroot rj)"
RECJ="$(issue "$RJ" T-DIRECT-GIT "$D_DIRECT")"
RC="$(rungate "$RJ" mutgate "$(bash_json 'git status')" "$WORK/gro2")"
[ "$RC" = "0" ] || no "git status blocked under an open receipt (exit $RC)"
SFJ="$(statefile "$RJ" "$RECJ")"
awk -F'\t' '$2=="exploratory_event" && $3 ~ /git_readonly/' "$SFJ" 2>/dev/null | grep -q . \
  && ok "read-only git under an open receipt is counted as exploratory_event (the explore half of the split)" \
  || no "read-only git left no exploratory_event row"
RC="$(rungate "$RJ" mutgate "$(bash_json 'git push origin main')" "$WORK/gmu2")"
[ "$RC" = "0" ] && ok "mutation-capable git under an OPEN receipt is admitted (routed work) and counted" \
               || no "git push under an open receipt was blocked (exit $RC)"
awk -F'\t' '$2=="mutation_event"' "$SFJ" 2>/dev/null | grep -q . \
  && ok "...as a mutation_event row" || no "the admitted git mutation left no mutation_event row"

echo "== 5. Exploratory reads: Read/Grep/Glob stay ungated but are COUNTED when a receipt is open =="
RK="$(mkroot rk)"
RECK="$(issue "$RK" T-DIRECT-EX "$D_DIRECT")"
for t in Read Grep Glob; do
  RC="$(rungate "$RK" count "$(tool_json $t)" "$WORK/ex-$t")"
  [ "$RC" = "0" ] && ok "$t stays UNGATED through the counter (exit 0)" || no "$t was blocked by the counter (exit $RC)"
done
SFK="$(statefile "$RK" "$RECK")"
NEX="$(awk -F'\t' '$2=="exploratory_event"' "$SFK" 2>/dev/null | grep -c . || true)"
[ "${NEX:-0}" = "3" ] && ok "EXACT: 3 read-class calls produced exactly 3 exploratory_event rows" \
                      || no "exploratory_event rows: ${NEX:-0}, expected 3"
NTE="$(awk -F'\t' '$2=="tool_event"' "$SFK" 2>/dev/null | grep -c . || true)"
[ "${NTE:-0}" = "3" ] && ok "...and the 3 tool_event rows still stand beside them (the split is additive, not renamed)" \
                      || no "tool_event rows: ${NTE:-0}, expected 3"
awk -F'\t' '$2=="tool_event" && $3 !~ /chars=[0-9]+/' "$SFK" 2>/dev/null | grep -q . \
  && no "a tool_event row carries no chars= field — the token proxy has nothing to sum" \
  || ok "every tool_event row carries chars= (the ESTIMATE token proxy's input)"
# A non-read tool is counted but NOT exploratory.
RC="$(rungate "$RK" count "$(edit_json)" "$WORK/ex-edit")"
NEX2="$(awk -F'\t' '$2=="exploratory_event"' "$SFK" | grep -c . || true)"
[ "${NEX2:-0}" = "3" ] && ok "an Edit counted by the * counter adds NO exploratory row (the split is honest)" \
                       || no "Edit was miscounted as exploratory (${NEX2:-0} rows)"

echo "== 6. REPETITION TRIP — consecutive same-tool >= 25 blocks the next mutation ONCE =="
RL="$(mkroot rl)"
RECL="$(issue "$RL" T-DIRECT-LOOP "$D_DIRECT")"
SFL="$(statefile "$RL" "$RECL")"
i=0; while [ "$i" -lt 24 ]; do
  printf '%s' "$(tool_json Read p$i)" | ROUTING_GATE_ROOT="$RL" bash "$GATE" count >/dev/null 2>&1
  i=$((i+1))
done
awk -F'\t' '$2=="reassess_armed"' "$SFL" 2>/dev/null | grep -q . \
  && no "the trip armed at 24 consecutive — below the derived-default threshold of 25" \
  || ok "24 consecutive same-tool calls do NOT arm the trip (threshold is 25, a derived default)"
printf '%s' "$(tool_json Read p24)" | ROUTING_GATE_ROOT="$RL" bash "$GATE" count >/dev/null 2>&1
awk -F'\t' '$2=="reassess_armed" && $3 ~ /trip=same_tool/' "$SFL" 2>/dev/null | grep -q . \
  && ok "the 25th consecutive same-tool call ARMS the trip (trip=same_tool recorded in the state file)" \
  || no "25 consecutive same-tool calls did not arm the trip"
RC="$(rungate "$RL" mutgate "$(edit_json)" "$WORK/trip1")"
[ "$RC" = "2" ] && ok "RED: the NEXT mutation-capable call after the trip is BLOCKED with a REASSESS refusal" \
               || no "RED FAILED: the armed trip did not block the next mutation (exit $RC)"
grep -qi "REASSESS" "$WORK/trip1.err" && ok "the refusal is named REASSESS" || no "the refusal is unnamed"
grep -q "route-task.sh" "$WORK/trip1.err" \
  && ok "the REASSESS refusal names the re-route path (route-task.sh / escalation / degradation)" \
  || no "the REASSESS refusal names no recovery"
grep -qiE "operator-tunable|derived default" "$WORK/trip1.err" \
  && ok "the refusal states the thresholds are derived defaults, operator-tunable" \
  || no "the thresholds masquerade as laws"
grep -qiE "continue the task|not the work" "$WORK/trip1.err" \
  && ok "the REASSESS refusal carries continue-the-task language" || no "REASSESS reads as stop-working"
grep -q "BLOCK-REASSESS" "$(logfile "$RL")" 2>/dev/null \
  && ok "the trip block is logged BLOCK-REASSESS" || no "the trip block left no log row"
# FIRE-ONCE: a reassessment loop that blocks forever is a brick. Prove it.
for i in 1 2 3; do
  RC="$(rungate "$RL" mutgate "$(edit_json)" "$WORK/trip-after$i")"
  [ "$RC" = "0" ] && ok "FIRE-ONCE: mutation-capable call $i after the block PASSES (the trip fired once, not forever)" \
                  || no "BRICK: the trip is still blocking call $i after it already fired (exit $RC)"
done
awk -F'\t' '$2=="reassess_block"' "$SFL" | grep -q . \
  && ok "the fired trip is recorded as a reassess_block row (the boundary that resets the counters)" \
  || no "no reassess_block row — the fire-once mechanics are untraceable"
# RESET BY REASSESSMENT: re-arm the trip, then land an escalation record — the
# next mutation passes WITHOUT the one-time block, and the reset is recorded.
i=0; while [ "$i" -lt 25 ]; do
  printf '%s' "$(tool_json Read q$i)" | ROUTING_GATE_ROOT="$RL" bash "$GATE" count >/dev/null 2>&1
  i=$((i+1))
done
[ "$(awk -F'\t' '$2=="reassess_armed"' "$SFL" | grep -c .)" = "2" ] \
  && ok "the loop re-arms after the boundary (a second trip is a second trip)" \
  || no "the trip did not re-arm after 25 more consecutive calls"
sed -i 's/^escalation: -$/escalation: reassessed after loop trip/' "$RECL"
sed -i 's|^escalation_evidence: -$|escalation_evidence: loop examined; mode confirmed with new reasoning recorded here|' "$RECL"
RC="$(rungate "$RL" mutgate "$(edit_json)" "$WORK/trip-reset")"
[ "$RC" = "0" ] && ok "RESET: an armed trip with a reassessment record landed (escalation+evidence) PASSES without blocking" \
               || no "a reassessed trip still blocked (exit $RC) — reassessment does not reset"
awk -F'\t' '$2=="reassess_reset"' "$SFL" | grep -q . \
  && ok "the reset is recorded as a reassess_reset row (visible, not silent)" \
  || no "the reset left no row"

echo "== 7. REPETITION TRIP — the ESTIMATE token proxy, honestly labeled =="
RM="$(mkroot rm)"
RECM="$(issue "$RM" T-DIRECT-PROXY "$D_DIRECT")"
SFM="$(statefile "$RM" "$RECM")"
BUNC="$(awk -F': ' '/^budget_max_uncached_tokens: /{print $2}' "$RECM")"
[ "$BUNC" = "30000" ] && ok "direct receipt carries budget_max_uncached_tokens 30000 (the derived default)" \
                      || no "unexpected uncached budget: $BUNC"
BIGP="$(head -c 250000 /dev/zero | tr '\0' 'a')"
printf '%s' "$(tool_json Read "$BIGP")" | ROUTING_GATE_ROOT="$RM" bash "$GATE" count >/dev/null 2>&1
printf '%s' "$(tool_json Grep "$BIGP")" | ROUTING_GATE_ROOT="$RM" bash "$GATE" count >/dev/null 2>&1
awk -F'\t' '$2=="reassess_armed" && $3 ~ /trip=proxy/' "$SFM" 2>/dev/null | grep -q . \
  && ok "~500K chars of tool input trips the proxy (chars/4 >= 4 x 30000 uncached budget)" \
  || no "the proxy trip did not arm on ~125K estimated tokens against a 30K budget"
awk -F'\t' '$2=="reassess_armed" && $3 ~ /trip=proxy/ && $3 ~ /tier=ESTIMATE/' "$SFM" | grep -q . \
  && ok "the proxy armed row is labeled tier=ESTIMATE — a chars/4 proxy, never billing truth" \
  || no "the proxy value is not labeled ESTIMATE"
awk -F'\t' '$2=="reassess_armed" && $3 ~ /trip=proxy/ && $3 ~ /tier=EXACT/' "$SFM" | grep -q . \
  && no "the proxy tier masquerades as EXACT" \
  || ok "the proxy tier never masquerades as EXACT (no tier promotion)"
RC="$(rungate "$RM" mutgate "$(write_json)" "$WORK/proxy1")"
[ "$RC" = "2" ] && ok "RED: the proxy trip blocks the next mutation-capable call once" \
               || no "RED FAILED: the proxy trip did not block (exit $RC)"
grep -q "ESTIMATE" "$WORK/proxy1.err" \
  && ok "the proxy refusal carries the ESTIMATE label in the model-visible text" \
  || no "the refusal presents the proxy as truth"
RC="$(rungate "$RM" mutgate "$(write_json)" "$WORK/proxy2")"
[ "$RC" = "0" ] && ok "FIRE-ONCE holds for the proxy trip too" || no "proxy trip bricked (exit $RC)"

echo "== 8. Telemetry tiers in the state-file labels — no tier masquerades as a higher one =="
haslabel(){ awk -F'\t' -v f="$2" -v s="$3" '$1=="label" && $2==f && index($3,s)>0 {hit=1} END{exit !hit}' "$1"; }
haslabel "$SFM" exploratory_events "EXACT" \
  && ok "exploratory_events labeled EXACT (hook-counted)" || no "exploratory_events not labeled EXACT"
haslabel "$SFM" mutation_events "EXACT" \
  && ok "mutation_events labeled EXACT (hook-counted)" || no "mutation_events not labeled EXACT"
haslabel "$SFM" token_proxy "ESTIMATE" \
  && ok "token_proxy labeled ESTIMATE" || no "token_proxy not labeled ESTIMATE"
awk -F'\t' '$1=="label" && $2=="token_proxy" && $3 ~ /EXACT/' "$SFM" | grep -q . \
  && no "token_proxy label claims EXACT — an estimate masquerading as measurement" \
  || ok "token_proxy label never claims EXACT"
haslabel "$SFM" tokens "UNAVAILABLE" && haslabel "$SFM" tokens "CLOSE-TIME" \
  && ok "tokens label carries the honest fallback tiers: CLOSE-TIME where headless, UNAVAILABLE interactive" \
  || no "tokens label lacks the CLOSE-TIME/UNAVAILABLE tier vocabulary"
awk -F'\t' '$1=="label" && $2=="tokens" && $3 ~ /EXACT|ESTIMATE/' "$SFM" | grep -q . \
  && no "tokens label claims a tier above CLOSE-TIME/UNAVAILABLE" \
  || ok "tokens never masquerades as EXACT or ESTIMATE"
haslabel "$SFM" cost_usd "UNAVAILABLE" \
  && ok "cost_usd carries the UNAVAILABLE tier" || no "cost_usd lacks its tier"
# Both label writers still agree byte-for-byte after the extension.
RN="$(mkroot rn)"
RECN="$(issue "$RN" T-FULL-TWIN "$D_FULL")"
bash "$RECDEG" --receipt "$RECN" --reason "label-twin fixture" >/dev/null 2>&1
SFN="$(statefile "$RN" "$RECN")"
diff <(grep -E '^label\t' "$SFM") <(grep -E '^label\t' "$SFN") >/dev/null 2>&1 \
  && ok "gate-created and degradation-created state files carry byte-identical EXTENDED label blocks" \
  || no "the two label-block writers diverged over the new tier rows"
# status repeats the tiers and derives the proxy.
ROUTING_GATE_ROOT="$RM" bash "$GATE" status >"$WORK/status.out" 2>&1
grep -qE 'token_proxy: [0-9]+ \(ESTIMATE' "$WORK/status.out" \
  && ok "status derives token_proxy and labels it ESTIMATE inline" || no "status hides or promotes the proxy"
grep -qE 'exploratory_events: [0-9]+' "$WORK/status.out" \
  && ok "status reports the explore/execute split" || no "status omits exploratory_events"

echo "== 9. ACTIVITY BINDING at close — unbound mutation activity is REPORTED, not refused =="
RO="$(mkroot ro)"
RECO="$(issue "$RO" T-DIRECT-BIND "$D_DIRECT")"
RC="$(rungate "$RO" mutgate "$(edit_json)" "$WORK/bind1")"
RC="$(rungate "$RO" mutgate "$(write_json)" "$WORK/bind2")"
sed -i 's/^executed_mode: -$/executed_mode: direct/' "$RECO"
bash "$RCHECK" check --receipt "$RECO" >"$WORK/bind.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "a closed receipt with unbound mutation activity still PASSES (absence is admission)" \
               || no "unbound activity was REFUSED (exit $RC) — the check overreaches"
grep -q "activity_binding" "$WORK/bind.out" \
  && ok "the activity_binding report line appears" || no "no activity_binding line — the unbound activity is invisible"
grep -qi "UNBOUND" "$WORK/bind.out" \
  && ok "...and names the condition: mutation events recorded, consumption all '-', no reconciliation" \
  || no "the report line does not name the unbound condition"
grep -q "2 mutation event" "$WORK/bind.out" \
  && ok "...with the EXACT mutation-event count from the state file" || no "the report omits the exact count"
# Reconciliation (any filled consumption) silences the report.
sed -i 's/^consumed_total_tokens: -$/consumed_total_tokens: 120000/' "$RECO"
bash "$RCHECK" check --receipt "$RECO" >"$WORK/bind2.out" 2>&1; RC=$?
[ "$RC" = "0" ] || no "a reconciled close was refused (exit $RC)"
grep -q "activity_binding" "$WORK/bind2.out" \
  && no "the report line fires even after telemetry reconciliation" \
  || ok "a close with telemetry reconciliation draws NO activity_binding report (the admission was withdrawn)"
# No mutation events -> no report, even fully unbound.
RP="$(mkroot rp)"
RECP="$(issue "$RP" T-DIRECT-NOMUT "$D_DIRECT")"
sed -i 's/^executed_mode: -$/executed_mode: direct/' "$RECP"
mkdir -p "$RP/build-os/packets/routing/live_state"
printf '2026-08-06T00:00:00Z\ttool_event\ttool_name=Read chars=100\n' > "$(statefile "$RP" "$RECP")"
bash "$RCHECK" check --receipt "$RECP" >"$WORK/bind3.out" 2>&1
grep -q "activity_binding" "$WORK/bind3.out" \
  && no "the report accuses a receipt with zero mutation events" \
  || ok "zero mutation events draw no activity_binding report (nothing to bind)"

echo "== 10. THE FULL LEGAL LIFECYCLE — route, work, close-fill, next session re-routes =="
RQ="$(mkroot rq)"
# 1. A fresh session's first mutation is blocked: the boundary is real.
RC="$(rungate "$RQ" mutgate "$(edit_json)" "$WORK/lc1")"
[ "$RC" = "2" ] && ok "LIFECYCLE 1: the session's first mutation-capable call is blocked — route first" \
               || no "LIFECYCLE 1 failed: unrouted mutation passed (exit $RC)"
# 2. The recovery is ONE command, and the gate itself lets it through (guard).
RC="$(rungate "$RQ" mutgate "$(bash_json 'build-os/tools/route-task.sh --task-id lc --description d --descriptor json')" "$WORK/lc2")"
[ "$RC" = "0" ] && ok "LIFECYCLE 2: the recovery command passes the gate ungated (the deadlock guard)" \
               || no "LIFECYCLE 2 failed: the recovery command is blocked (exit $RC)"
RECQ="$(issue "$RQ" T-LIFECYCLE "$D_DIRECT")"
[ -n "$RECQ" ] && ok "LIFECYCLE 2b: the receipt is issued (one command)" || no "no receipt issued"
# 3. Work proceeds under the open receipt: explore free, mutate counted.
RC="$(rungate "$RQ" count "$(tool_json Read)" "$WORK/lc3a")"
RC="$(rungate "$RQ" mutgate "$(edit_json)" "$WORK/lc3b")"
[ "$RC" = "0" ] && ok "LIFECYCLE 3: mutation under the open receipt is admitted and bound" \
               || no "LIFECYCLE 3 failed (exit $RC)"
# 4. Close-fill: the receipt closes; the sweep still passes (with the report).
sed -i 's/^executed_mode: -$/executed_mode: direct/' "$RECQ"
bash "$RCHECK" check --dir "$RQ/build-os/packets/routing" >"$WORK/lc4.out" 2>&1; RC=$?
[ "$RC" = "0" ] && ok "LIFECYCLE 4: the closed receipt passes the close-time sweep" \
               || no "LIFECYCLE 4 failed: the honest close was refused (exit $RC)"
# 5. Next session: no open receipt again — the next mutation re-routes.
RC="$(rungate "$RQ" mutgate "$(edit_json)" "$WORK/lc5")"
[ "$RC" = "2" ] && ok "LIFECYCLE 5: after close-fill the next mutation is blocked again — every task routes at entry" \
               || no "LIFECYCLE 5 failed: a closed store licensed new mutation (exit $RC)"
RECQ2="$(issue "$RQ" T-LIFECYCLE-2 "$D_DIRECT")"
RC="$(rungate "$RQ" mutgate "$(edit_json)" "$WORK/lc6")"
[ "$RC" = "0" ] && ok "LIFECYCLE 6: a fresh receipt re-opens the boundary — the loop is livable, not a brick" \
               || no "LIFECYCLE 6 failed (exit $RC)"

echo "== 11. OVERHEAD — the extended matcher stays cheap on both hot paths =="
RS="$(mkroot rs)"
RECS="$(issue "$RS" T-DIRECT-PERF "$D_DIRECT")"
N=25; T0="$(date +%s%N)"
i=0; while [ "$i" -lt "$N" ]; do
  printf '%s' "$(edit_json)" | ROUTING_GATE_ROOT="$RS" bash "$GATE" mutgate >/dev/null 2>&1
  i=$((i+1))
done
T1="$(date +%s%N)"
ALLOW_MS=$(( (T1 - T0) / N / 1000000 ))
[ "$ALLOW_MS" -le 250 ] \
  && ok "OVERHEAD: mutgate ALLOW path averages ${ALLOW_MS}ms per call over $N runs (asserted <= 250ms)" \
  || no "OVERHEAD: mutgate ALLOW path averages ${ALLOW_MS}ms — not trivial"
RT="$(mkroot rt)"
T0="$(date +%s%N)"
i=0; while [ "$i" -lt "$N" ]; do
  printf '%s' "$(edit_json)" | ROUTING_GATE_ROOT="$RT" bash "$GATE" mutgate >/dev/null 2>&1
  i=$((i+1))
done
T1="$(date +%s%N)"
BLOCK_MS=$(( (T1 - T0) / N / 1000000 ))
[ "$BLOCK_MS" -le 250 ] \
  && ok "OVERHEAD: the no-receipt BLOCK fast path averages ${BLOCK_MS}ms per call (asserted <= 250ms)" \
  || no "OVERHEAD: the no-receipt path averages ${BLOCK_MS}ms — the refusal itself is expensive"

echo "== 12. Fail-open and the operator escape still hold for the new subcommand =="
RU="$(mkroot ru)"
issue "$RU" T-DIRECT-FO "$D_DIRECT" >/dev/null
RC="$(rungate "$RU" mutgate "utter garbage, not json" "$WORK/fo")"
[ "$RC" = "0" ] && ok "mutgate FAILS OPEN on unparseable input (a broken gate must not brick every session)" \
               || no "mutgate failed CLOSED on its own error (exit $RC)"
RC="$(ROUTING_GATE_DISABLE=1; export ROUTING_GATE_DISABLE; rungate "$RA" mutgate "$(edit_json)" "$WORK/fo2")"
[ "$RC" = "0" ] && ok "ROUTING_GATE_DISABLE=1 admits the mutation (operator-only escape)" \
               || no "the documented escape does not cover mutgate (exit $RC)"
grep -q "DISABLED-BY-OPERATOR" "$(logfile "$RA")" 2>/dev/null \
  && ok "the escape is logged — an escape that leaves no trace is a bypass" || no "the escape left no trace"

echo "== 13. Registration: RULING 4, same commit, crosswalk, chaining =="
REG="$SRC/build-os/registry/control_registry.txt"
XW="$SRC/build-os/registry/neurocosmology_crosswalk.txt"
grep -qxF 'control: routing.universal_task_entry_gate' "$REG" \
  && ok "the task-entry gate owns a control registry entry" || no "routing.universal_task_entry_gate is unregistered"
grep -qxF 'control: suite.routing_task_entry' "$REG" \
  && ok "this suite owns a control registry entry" || no "this suite is unregistered"
grep -qxF 'owning_module: tests/routing_task_entry_tests.sh' "$REG" \
  && ok "this suite's entry names it as owning_module" || no "no owning_module row for this suite"
for c in routing.universal_task_entry_gate suite.routing_task_entry; do
  grep -qxF "control: $c" "$XW" && ok "crosswalk binds $c" || no "no crosswalk binding for $c"
done
grep -q 'routing_task_entry_tests.sh' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained into tests/build_os_tests.sh (not discoverable-only)" \
  || no "this suite is not chained — it would run only when remembered"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
