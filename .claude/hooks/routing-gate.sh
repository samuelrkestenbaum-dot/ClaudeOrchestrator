#!/usr/bin/env bash
# Build OS — routing-gate.sh: the LIVE dispatch gate (PACKET-0053-live-enforcement).
#
# WHAT THIS IS. Claude Code PreToolUse hooks receive the pending tool call as
# JSON on stdin and can BLOCK it: exit 2 makes stderr the model-visible refusal.
# That converts routing from file-instruction (PACKET-0050's close-time gate,
# which refuses AFTER the tokens are spent) into pre-execution enforcement for
# everything dispatch-shaped. EXP-0003 measured the gap this closes: both
# condition receipts were REFUSED at close and ZERO degradation notes were
# written mid-flight, because nothing mechanical existed mid-flight.
#
# SUBCOMMANDS (wired in .claude/settings.json):
#   gate    PreToolUse, matcher Task|Agent — the dispatch gate. BLOCKS (exit 2):
#             * when NO open routing receipt exists (open = newest receipt in
#               build-os/packets/routing/ whose executed_mode is '-');
#             * when the open receipt records direct/gravito_light and carries
#               no evidence-bearing escalation record (silent escalation,
#               refused BEFORE execution — routing-check.sh's own escalation
#               semantics, reused not re-invented);
#             * when the receipt is DEGRADED (degradation_note filled);
#             * when task dispatches have reached budget_max_subagents (the
#               live fan-out brake — fires BEFORE close, stamps the degradation
#               via record-degradation.sh, and instructs consolidate-and-
#               continue, never stop-working);
#             * when process-role dispatches (subagent_type builder|qa|
#               reviewer|archivist|build-orchestrator) have reached
#               process_dispatch_allowance (default 4 where the receipt
#               predates the field) — attributed to governance_process,
#               SEPARATE from the task budget. This resolves the PACKET-0050/
#               0051 open calibration question mechanically: a packet's own
#               gate chain does not eat its task budget.
#           On ALLOW it appends the dispatch to the live state and, for Full
#           task dispatches, seeds a stub contribution row into the receipt
#           (close-fill tooling for the marginal-contribution table).
#   count   PreToolUse, matcher * — the tool-event counter. NEVER blocks.
#           Deliberately jq-free (sed only) so its per-call overhead stays
#           trivial; the suite measures and asserts the bound.
#   post    PostToolUse, matcher * — counts a tool_failure ONLY where the
#           tool_response exposes success:false / is_error:true. Where no
#           status is exposed, nothing is guessed — the state-file label
#           admits the bound.
#   status  Human/test convenience: derived counts + elapsed_s for the open
#           receipt. Counts are DERIVED by counting append-only rows, never
#           stored — a stored counter is a second copy that can disagree.
#
# WHEN THIS GOES LIVE. Hooks load at SESSION START: the session that wires this
# file is NOT governed by it; every later session in this project is. Stated in
# build-os/memory/routing_contract_live.md, not implied.
#
# FAIL-OPEN, BY DESIGN. On any internal error (unparseable stdin, unreadable
# store, missing dependency) the gate ALLOWS and logs a FAIL-OPEN row: a gate
# that fails closed on its own bug is a denial of service against the operator.
# ROUTING_GATE_DISABLE=1 is the documented OPERATOR-ONLY escape; it admits the
# call and logs DISABLED-BY-OPERATOR — an escape that leaves no trace is a
# bypass, so the trace is not optional.
#
# WRITES (censused: MUT-0011, control routing.live_gate_ledger_append):
#   append-only build-os/packets/routing/live_gate_log.tsv     (every decision)
#   append-only build-os/packets/routing/live_state/<id>.tsv   (per open receipt)
#   append-only stub contribution rows into the open receipt   (ALLOW, Full task)
# ROUTING_GATE_ROOT overrides the DATA root (fixtures); code always resolves
# beside this file. Reads receipts; never edits a receipt field itself — the
# degradation stamp is build-os/tools/record-degradation.sh's, invoked here.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODE_ROOT="$(cd "$SELF_DIR/../.." && pwd)"
DATA_ROOT="${ROUTING_GATE_ROOT:-${CLAUDE_PROJECT_DIR:-$CODE_ROOT}}"
RDIR="$DATA_ROOT/build-os/packets/routing"
LOGF="$RDIR/live_gate_log.tsv"
SDIR="$RDIR/live_state"
RECDEG="$CODE_ROOT/build-os/tools/record-degradation.sh"
PROCESS_ROLES="builder qa reviewer archivist build-orchestrator"
DEFAULT_PROCESS_ALLOWANCE=7

now(){ date -u +%Y-%m-%dT%H:%M:%SZ; }

# Append one decision row: timestamp, task identity, selected depth, decision, detail.
# Best-effort on purpose: logging must never turn a decision into a crash.
logrow(){ # <task_id> <depth> <decision> <detail>
  # Best-effort log append; when the routing store is unwritable the row goes
  # to STDERR instead, so the trace survives the one vector that silences the
  # file (named in routing_contract_live.md layer 4). Never fails the caller.
  if ! { mkdir -p "$RDIR" 2>/dev/null && \
    printf '%s\t%s\t%s\t%s\t%s\n' "$(now)" "${1:--}" "${2:--}" "${3:--}" "${4:--}" >> "$LOGF"; } 2>/dev/null; then
    printf 'routing-gate UNLOGGED(store unwritable): %s %s %s %s\n' "${1:--}" "${2:--}" "${3:--}" "${4:--}" >&2 || true
  fi
}

# The ONE label block, shared verbatim with record-degradation.sh (the suite
# diffs the two writers' label blocks so they cannot drift apart). EXACT vs
# ESTIMATE is labeled per field — the operator's rule, in the artefact itself.
write_labels(){ # <dest-file> <receipt-basename> — create-once via noclobber
  ( set -C; { \
    printf '# live state for %s — append-only; counts are DERIVED by counting rows, never stored\n' "$2"; \
    printf 'label\ttask_dispatches\tEXACT (hook-counted ALLOW decisions at PreToolUse, in sessions where the gate is loaded; attempts, not completions)\n'; \
    printf 'label\tprocess_dispatches\tEXACT (hook-counted; subagent_type in builder|qa|reviewer|archivist|build-orchestrator; attributed governance_process)\n'; \
    printf 'label\ttool_events\tEXACT (hook-counted PreToolUse events in sessions where the gate is loaded)\n'; \
    printf 'label\ttool_failures\tEXACT only where PostToolUse exposes success:false/is_error; otherwise unavailable — absence of a row is NOT evidence of success\n'; \
    printf 'label\telapsed_s\tEXACT (derived at read time: receipt issued_at vs now; never stored)\n'; \
    printf 'label\ttokens\tunavailable_live (close-time reconciliation via telemetry where headless; not hook-visible in interactive sessions)\n'; \
    printf 'label\tcost_usd\tunavailable_live (close-time reconciliation via telemetry where headless; not hook-visible in interactive sessions)\n'; \
    } > "$1" ) 2>/dev/null || true
}

staterow(){ # <receipt-path> <kind> <detail>
  local sf
  sf="$SDIR/$(basename "$1" .md).tsv"
  mkdir -p "$SDIR" 2>/dev/null || return 1
  [ -f "$sf" ] || write_labels "$sf" "$(basename "$1")"
  printf '%s\t%s\t%s\n' "$(now)" "$2" "$3" >> "$sf"
}

fval(){ # <file> <field>
  awk -v k="$2" 'index($0, k": ")==1 { print substr($0, length(k)+3); exit }' "$1"
}
is_num(){ printf '%s' "$1" | grep -qE '^[0-9]+(\.[0-9]+)?$'; }

# The open receipt: among build-os/packets/routing/*.md with executed_mode '-',
# the newest by the trailing UTC stamp in the file name (route-task.sh's own
# naming), falling back to mtime order for foreign names.
open_receipt(){
  local f best="" bestkey=""
  [ -d "$RDIR" ] || return 1
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ "$(fval "$f" executed_mode)" = "-" ] || continue
    key="$(basename "$f" .md | grep -oE '[0-9]{8}T[0-9]{6}Z$' || true)"
    [ -n "$key" ] || key="0-$(stat -c %Y "$f" 2>/dev/null || echo 0)"
    if [ -z "$best" ] || [ "$key" \> "$bestkey" ]; then best="$f"; bestkey="$key"; fi
  done < <(find "$RDIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
  [ -n "$best" ] && printf '%s' "$best"
}

count_kind(){ # <receipt-path> <kind> — derived, never stored
  local sf
  sf="$SDIR/$(basename "$1" .md).tsv"
  [ -f "$sf" ] || { echo 0; return; }
  awk -F'\t' -v k="$2" '$2==k{n++} END{print n+0}' "$sf"
}

# ---------------------------------------------------------------- gate -------
# Prints a decision protocol on stdout: first line ALLOW or BLOCK, message
# after. The wrapper turns BLOCK into exit 2 + stderr; anything malformed —
# including this function crashing — FAILS OPEN.
gate_decide(){ # <stdin-json>
  local in="$1" sub rec mode esc esc_ev deg bud allow ntask nproc kind
  command -v jq >/dev/null 2>&1 || return 1
  sub="$(printf '%s' "$in" | jq -r '.tool_input.subagent_type // "-"' 2>/dev/null)" || return 1
  [ -n "$sub" ] || sub="-"
  rec="$(open_receipt)" || rec=""
  if [ -z "$rec" ]; then
    logrow "none" "-" "BLOCK-NO-RECEIPT" "subagent_type=$sub"
    printf 'BLOCK\n'
    printf 'routing-gate: DISPATCH BLOCKED — no OPEN routing receipt exists under build-os/packets/routing/ (open = executed_mode "-"). A substantive task cannot execute unrouted: issue a routing receipt first via build-os/tools/route-task.sh --task-id <id> --description <text> --descriptor <13-field-json>, then dispatch again. Continue the task — only this unrouted dispatch is refused, not the work.\n'
    return 0
  fi
  mode="$(fval "$rec" selected_mode)"
  esc="$(fval "$rec" escalation)"; esc_ev="$(fval "$rec" escalation_evidence)"
  deg="$(fval "$rec" degradation_note)"
  local task_id; task_id="$(fval "$rec" task_id)"; [ -n "$task_id" ] || task_id="-"

  # Dispatch class: process roles are governance ceremony, counted against the
  # allowance and attributed governance_process; everything else is task work.
  kind="task"
  local r; for r in $PROCESS_ROLES; do [ "$sub" = "$r" ] && kind="process"; done

  # Effective depth: a filled degradation_note means the receipt has already
  # been downgraded to gravito_light — the degradation is binding. An
  # evidence-bearing escalation record lifts direct/light to full (escalation
  # is legal; silence is not — evidence required, exactly as routing-check.sh).
  local eff="$mode" escalated=0
  if [ -n "$deg" ] && [ "$deg" != "-" ]; then
    eff="gravito_light_degraded"
  elif [ "$mode" != "gravito_full" ] && [ "$esc" != "-" ] && [ -n "$esc" ] && [ "$esc_ev" != "-" ] && [ -n "$esc_ev" ]; then
    eff="gravito_full"; escalated=1
  fi

  case "$eff" in
    gravito_full) : ;;
    gravito_light_degraded)
      logrow "$task_id" "$mode" "BLOCK-DEGRADED" "subagent_type=$sub"
      printf 'BLOCK\n'
      printf 'routing-gate: DISPATCH BLOCKED — receipt %s is DEGRADED to gravito_light (degradation_note is filled), so new dispatch is ceremony above the degraded depth. Consolidate the remaining work into the parent loop, preserve completed subagent outputs, and continue the task in gravito_light. Stop the expensive mode, not the task — do not stop working.\n' "$(basename "$rec")"
      return 0 ;;
    direct|gravito_light)
      logrow "$task_id" "$mode" "BLOCK-MODE-$mode" "subagent_type=$sub"
      printf 'BLOCK\n'
      printf 'routing-gate: DISPATCH BLOCKED — the open routing receipt %s records %s, and subagent dispatch is ceremony above that depth: executing above the recorded mode with no evidence-bearing escalation record is silent escalation (the executed T5 defect), refused here BEFORE execution rather than at close. Either continue the task in the parent loop at %s, or record a new evidence-bearing escalation decision in the receipt (fill escalation AND escalation_evidence, naming what changed) and dispatch again. Continue the task — only the dispatch is refused, not the work.\n' "$(basename "$rec")" "$mode" "$mode"
      return 0 ;;
    *) return 1 ;;  # unreadable mode -> fail open in the wrapper
  esac

  if [ "$kind" = "process" ]; then
    allow="$(fval "$rec" process_dispatch_allowance)"
    is_num "$allow" || allow="$DEFAULT_PROCESS_ALLOWANCE"
    nproc="$(count_kind "$rec" process_dispatch)"
    if [ "$nproc" -ge "$allow" ]; then
      logrow "$task_id" "$mode" "BLOCK-PROCESS-ALLOWANCE" "subagent_type=$sub n=$nproc allowance=$allow"
      printf 'BLOCK\n'
      printf 'routing-gate: DISPATCH BLOCKED — process-role dispatches are at the allowance (%s of %s, receipt %s; this dispatch is subagent_type %s, attributed governance_process). The gate chain is governance ceremony with its own budget, separate from task work. Consolidate remaining gate work into the parent loop, preserve completed outputs, and continue the task. Stop the expensive mode, not the task — do not stop working.\n' "$nproc" "$allow" "$(basename "$rec")" "$sub"
      return 0
    fi
    staterow "$rec" process_dispatch "subagent_type=$sub attributed=governance_process" || return 1
    logrow "$task_id" "$mode" "ALLOW-PROCESS-DISPATCH" "subagent_type=$sub n=$((nproc+1)) allowance=$allow"
    printf 'ALLOW\n'
    return 0
  fi

  # Task dispatch against budget_max_subagents. An escalated receipt carries
  # its pre-escalation budget (0 for direct/light), so the Full derived default
  # (3) governs where the recorded budget is below it — otherwise an escalation
  # would be granted and immediately unusable.
  bud="$(fval "$rec" budget_max_subagents)"
  is_num "$bud" || bud=0
  if [ "$escalated" = "1" ] && [ "$bud" -lt 3 ]; then bud=3; fi
  ntask="$(count_kind "$rec" task_dispatch)"
  if [ "$ntask" -ge "$bud" ]; then
    # THE LIVE BRAKE — before close, not at it. Fire-once degradation: stamp
    # via record-degradation.sh (which also appends the DEGRADATION state row).
    if [ "$deg" = "-" ] && [ -x "$RECDEG" ]; then
      bash "$RECDEG" --receipt "$rec" \
        --reason "fan-out throttle: task dispatches at budget_max_subagents ($ntask of $bud); stopped spawning" \
        --evidence "live state $SDIR/$(basename "$rec" .md).tsv ($ntask completed dispatch rows preserved)" \
        >/dev/null 2>&1 || true
    fi
    logrow "$task_id" "$mode" "BLOCK-FANOUT-BUDGET" "subagent_type=$sub n=$ntask budget=$bud degradation=stamped"
    printf 'BLOCK\n'
    printf 'routing-gate: DISPATCH BLOCKED — task dispatches are at budget_max_subagents (%s of %s, receipt %s). Stop fan-out now: consolidate the remaining work into the parent loop, preserve completed subagent outputs (they are recorded in the live state), and continue the task in gravito_light. The degradation has been recorded on the receipt, so an honest close passes the budget gate. Stop the expensive mode, not the task — do not stop working.\n' "$ntask" "$bud" "$(basename "$rec")"
    return 0
  fi
  staterow "$rec" task_dispatch "subagent_type=$sub attributed=task_execution" || return 1
  # Close-fill tooling for the contribution table: one stub row per admitted
  # Full task dispatch, all '-' (admissions to be filled at close, never zeros).
  printf 'contribution: %s | - | - | changed_implementation=- | changed_conclusion=- | caught_defect=- | duplicated_work=- | tokens=- | cost=- | time=-\n' "$sub" >> "$rec" 2>/dev/null || true
  logrow "$task_id" "$mode" "ALLOW-TASK-DISPATCH" "subagent_type=$sub n=$((ntask+1)) budget=$bud"
  printf 'ALLOW\n'
  return 0
}

# ---------------------------------------------------------------- count ------
# The always-on observer. Never blocks, never parses with jq (a node/jq spawn
# per tool call is exactly the overhead this path must not carry): one sed pull
# of tool_name, one grep per receipt to find the open one, one append.
count_tool(){ # <stdin-json>
  local in="$1" tool rec
  tool="$(printf '%s' "$in" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  [ -n "$tool" ] || tool="-"
  rec="$(open_receipt)" || rec=""
  [ -n "$rec" ] || return 0   # no open receipt: nothing to count against, no state invented
  staterow "$rec" tool_event "tool_name=$tool" || return 1
  return 0
}

# ---------------------------------------------------------------- post -------
post_tool(){ # <stdin-json>
  local in="$1" rec failed tool
  rec="$(open_receipt)" || rec=""
  [ -n "$rec" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0   # no jq: no guess, label admits the bound
  failed="$(printf '%s' "$in" | jq -r '(.tool_response.success == false) or (.tool_response.is_error == true)' 2>/dev/null)" || return 0
  if [ "$failed" = "true" ]; then
    tool="$(printf '%s' "$in" | jq -r '.tool_name // "-"' 2>/dev/null)" || tool="-"
    staterow "$rec" tool_failure "tool_name=$tool source=PostToolUse.tool_response" || return 1
  fi
  return 0
}

# ---------------------------------------------------------------- status -----
status_report(){
  local rec sf issued elapsed
  rec="$(open_receipt)" || rec=""
  if [ -z "$rec" ]; then printf 'routing-gate: status — no open receipt\n'; return 0; fi
  sf="$SDIR/$(basename "$rec" .md).tsv"
  printf 'routing-gate: status receipt=%s\n' "$(basename "$rec")"
  printf 'selected_mode: %s\n' "$(fval "$rec" selected_mode)"
  printf 'task_dispatches: %s (EXACT, derived from %s)\n' "$(count_kind "$rec" task_dispatch)" "${sf#"$DATA_ROOT/"}"
  printf 'process_dispatches: %s (EXACT, attributed governance_process)\n' "$(count_kind "$rec" process_dispatch)"
  printf 'tool_events: %s (EXACT, sessions where the gate is loaded)\n' "$(count_kind "$rec" tool_event)"
  printf 'tool_failures: %s (EXACT only where PostToolUse exposes status)\n' "$(count_kind "$rec" tool_failure)"
  issued="$(fval "$rec" issued_at)"
  if elapsed="$(( $(date -u +%s) - $(date -ud "$issued" +%s 2>/dev/null || echo 0) ))" 2>/dev/null && [ -n "$issued" ]; then
    printf 'elapsed_s: %s (EXACT, derived at read time: issued_at %s vs now)\n' "$elapsed" "$issued"
  else
    printf 'elapsed_s: - (issued_at unreadable)\n'
  fi
  printf 'tokens: unavailable_live (close-time reconciliation via telemetry where headless)\n'
  printf 'cost_usd: unavailable_live (close-time reconciliation via telemetry where headless)\n'
  return 0
}

# ---------------------------------------------------------------- wrapper ----
CMD="${1:-}"
case "$CMD" in
  gate|count|post|status) ;;
  -h|--help|help) sed -n '2,70p' "${BASH_SOURCE[0]}"; exit 0 ;;
  *) printf 'routing-gate: unknown command "%s" — expected gate|count|post|status\n' "${CMD:-}" >&2; exit 2 ;;
esac

if [ "$CMD" = "status" ]; then status_report; exit $?; fi

# ALWAYS drain stdin first (the DEFECT-0013 lesson: an undrained producer under
# pipefail is a race) — and never let a read failure become a blocked call.
IN="$(cat 2>/dev/null || true)"

if [ "${ROUTING_GATE_DISABLE:-0}" = "1" ]; then
  # OPERATOR-ONLY escape, refused-by-default posture: it exists, it is
  # documented in routing_contract_live.md, and it ALWAYS leaves a trace.
  logrow "-" "-" "DISABLED-BY-OPERATOR" "cmd=$CMD ROUTING_GATE_DISABLE=1"
  exit 0
fi

case "$CMD" in
  count)
    count_tool "$IN" || logrow "-" "-" "FAIL-OPEN" "cmd=count internal error"
    exit 0 ;;
  post)
    post_tool "$IN" || logrow "-" "-" "FAIL-OPEN" "cmd=post internal error"
    exit 0 ;;
  gate)
    OUT="$(gate_decide "$IN" 2>/dev/null)"; RC=$?
    DECISION="$(printf '%s\n' "$OUT" | sed -n '1p')"
    if [ "$RC" -eq 0 ] && [ "$DECISION" = "ALLOW" ]; then
      exit 0
    elif [ "$RC" -eq 0 ] && [ "$DECISION" = "BLOCK" ]; then
      printf '%s\n' "$OUT" | sed '1d' >&2
      exit 2
    else
      # FAIL OPEN: a broken gate must not brick every session. Logged, because
      # a silent fail-open is an invisible outage of the control plane.
      logrow "-" "-" "FAIL-OPEN" "cmd=gate rc=$RC decision=${DECISION:-none}"
      exit 0
    fi ;;
esac
exit 0
