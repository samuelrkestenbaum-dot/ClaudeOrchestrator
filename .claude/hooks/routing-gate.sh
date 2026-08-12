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
# PACKET-0054 EXTENDED THIS FILE (never forked it) into the UNIVERSAL TASK-ENTRY
# boundary: the gate now also fires on MUTATION-CAPABLE tools (Edit, Write,
# NotebookEdit, Bash) via the `mutgate` subcommand, so parent-only work that
# dispatches nothing is governed too. Contract half:
# build-os/memory/routing_contract_live.md; adapter expression:
# build-os/memory/provider_adapter_contract.md (this file is ADAPTER #1).
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
#   mutgate PreToolUse, matcher Edit|Write|NotebookEdit|Bash — the TASK-ENTRY
#           gate (PACKET-0054). A mutation-capable call with NO open routing
#           receipt is BLOCKED with the recovery command (route-task.sh, incl a
#           cheap direct-mode example — tiny work routes too, cheaply). Two
#           classes pass UNGATED, logged: (a) DEADLOCK GUARD — since
#           PACKET-0055 a STRUCTURED ROUTING ACTION: only a command whose
#           extracted tool_input.command field IS exactly one clean routing-
#           tool invocation (no chaining/substitution metacharacters) passes,
#           logged ROUTING-TOOL-PASS with an action fingerprint (tool, sha256,
#           excerpt); everything else falls through TOWARD GATING. (b) READ-
#           ONLY git inspection (status/log/diff/show/rev-parse/ls-files/
#           branch), counted exploratory. Any git command carrying push|commit|
#           merge|rebase|reset|checkout|restore|clean|apply|am|cherry-pick|tag|
#           stash or -f/--force is mutation-capable. The classification is a
#           NAMED HEURISTIC (sh -c evades the mutation class): discipline-for-
#           honest-agents plus audit trail, NOT a sandbox (the sandbox is the
#           platform's permission system). Fire-once REASSESS trip (see count).
#   count   PreToolUse, matcher * — the tool-event counter. NEVER blocks.
#           Deliberately jq-free (sed only) so its per-call overhead stays
#           trivial; the suite measures and asserts the bound. PACKET-0054:
#           each row carries chars= (the ESTIMATE token-proxy input); Read/
#           Grep/Glob additionally append an exploratory_event row (the
#           explore half of the explore/execute split); and the counter ARMS
#           the repetitive-loop trip — consecutive same-tool calls >=
#           ROUTING_REASSESS_SAME_TOOL_MAX (derived default 25) or chars/4 >=
#           ROUTING_REASSESS_PROXY_MULT (default 4) x
#           budget_max_uncached_tokens — which blocks the NEXT mutation-capable
#           call ONCE with a REASSESS refusal; a reassessment record (fresh
#           receipt, or an escalation/degradation entry) resets the trip.
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
# Reassessment-trip thresholds: DERIVED DEFAULTS, operator-tunable via env —
# stated as such in every refusal; neither is a law.
SAME_TOOL_MAX="${ROUTING_REASSESS_SAME_TOOL_MAX:-25}"
PROXY_MULT="${ROUTING_REASSESS_PROXY_MULT:-4}"

now(){ date -u +%Y-%m-%dT%H:%M:%SZ; }

# Append one decision row: timestamp, task identity, selected depth, decision, detail.
# Best-effort on purpose: logging must never turn a decision into a crash.
logrow(){ # <task_id> <depth> <decision> <detail>
  # Best-effort log append; when the routing store is unwritable the row goes
  # to STDERR instead, so the trace survives the one vector that silences the
  # file (named in routing_contract_live.md layer 4). Never fails the caller.
  if ! { mkdir -p "$RDIR" 2>/dev/null && \
    printf '%s\t%s\t%s\t%s\t%s\n' "$(now)" "${1:--}" "${2:--}" "${3:--}" "${4:--}" >> "$LOGF"; } 2>/dev/null; then
    { printf 'routing-gate UNLOGGED(store unwritable): %s %s %s %s\n' "${1:--}" "${2:--}" "${3:--}" "${4:--}" >&9; } 2>/dev/null || printf 'routing-gate UNLOGGED(store unwritable): %s %s %s %s\n' "${1:--}" "${2:--}" "${3:--}" "${4:--}" >&2 || true
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
    printf 'label\texploratory_events\tEXACT (hook-counted Read/Grep/Glob and read-only git inspection — the explore half of the explore/execute split)\n'; \
    printf 'label\tmutation_events\tEXACT (hook-counted ADMITTED mutation-capable calls: Edit/Write/NotebookEdit/Bash outside the routing-tool and read-only-git classes)\n'; \
    printf 'label\ttoken_proxy\tESTIMATE (sum of tool-input chars / 4 — a chars-based proxy; thresholds are derived defaults, operator-tunable; NEVER billing truth and never promoted to a higher tier)\n'; \
    printf 'label\telapsed_s\tEXACT (derived at read time: receipt issued_at vs now; never stored)\n'; \
    printf 'label\ttokens\tunavailable_live in interactive sessions (tier UNAVAILABLE); close-time reconciliation via telemetry where headless (tier CLOSE-TIME); never presented at a higher tier\n'; \
    printf 'label\tcost_usd\tunavailable_live in interactive sessions (tier UNAVAILABLE); close-time reconciliation via telemetry where headless (tier CLOSE-TIME); never presented at a higher tier\n'; \
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
# PACKET-0054: chars= is the ESTIMATE token-proxy input (length of everything
# after "tool_input" in the raw event — a chars proxy, not a parse); Read/Grep/
# Glob get an exploratory_event row beside their tool_event row; and arm_check
# arms the repetitive-loop trip the mutgate enforces.
count_tool(){ # <stdin-json>
  local in="$1" tool rec ti chars
  tool="$(printf '%s' "$in" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  [ -n "$tool" ] || tool="-"
  rec="$(open_receipt)" || rec=""
  [ -n "$rec" ] || return 0   # no open receipt: nothing to count against, no state invented
  ti="${in#*\"tool_input\"}"; chars="${#ti}"
  staterow "$rec" tool_event "tool_name=$tool chars=$chars" || return 1
  case "$tool" in
    Read|Grep|Glob) staterow "$rec" exploratory_event "tool_name=$tool source=read_class" || return 1 ;;
  esac
  arm_check "$rec" || return 1
  return 0
}

# Arm the reassessment trip when the window since the last boundary row
# (reassess_block / reassess_reset) shows a repetitive parent loop. Arming is
# once per window; the trip itself fires ONCE, at the next mutation-capable
# call (mutgate). Counters are DERIVED by reading rows, never stored.
arm_check(){ # <receipt-path>
  local sf run sum armed trip="" val="" thr="" tier="" bud esc_s deg_s v
  sf="$SDIR/$(basename "$1" .md).tsv"
  [ -f "$sf" ] || return 0
  read -r run sum armed <<EOF
$(awk -F'\t' '
    $2=="reassess_block"||$2=="reassess_reset"{run=0;sum=0;last="";armed=0;next}
    $2=="reassess_armed"{armed=1;next}
    $2=="tool_event"{
      t=""; if(match($3,/tool_name=[^ ]*/)) t=substr($3,RSTART+10,RLENGTH-10);
      if(t!="" && t==last) run++; else {run=1;last=t};
      if(match($3,/chars=[0-9]+/)) sum+=substr($3,RSTART+6,RLENGTH-6)+0 }
    END{print run+0, sum+0, armed+0}' "$sf")
EOF
  [ "$armed" = "1" ] && return 0
  if [ "$run" -ge "$SAME_TOOL_MAX" ] 2>/dev/null; then
    trip="same_tool"; val="$run"; thr="$SAME_TOOL_MAX"; tier="EXACT"
  else
    bud="$(fval "$1" budget_max_uncached_tokens)"
    if is_num "$bud" && [ "$((sum / 4))" -ge "$((PROXY_MULT * bud))" ]; then
      trip="proxy"; val="$((sum / 4))"; thr="$((PROXY_MULT * bud))"; tier="ESTIMATE"
    fi
  fi
  [ -n "$trip" ] || return 0
  esc_s="-"; deg_s="-"
  v="$(fval "$1" escalation_evidence)"; [ -n "$v" ] && [ "$v" != "-" ] && esc_s="set"
  v="$(fval "$1" degradation_note)";    [ -n "$v" ] && [ "$v" != "-" ] && deg_s="set"
  staterow "$1" reassess_armed "trip=$trip value=$val threshold=$thr tier=$tier esc=$esc_s deg=$deg_s" || return 1
  return 0
}

# --------------------------------------------------------------- mutgate -----
# The UNIVERSAL TASK-ENTRY boundary (PACKET-0054): every mutation-capable tool
# call requires an open routing receipt — including parent-only work that never
# dispatches. Classification is a NAMED HEURISTIC (stated in
# routing_contract_live.md): a hostile command evades the mutation class with
# sh -c or a wrapper; this gate is discipline-for-honest-agents plus an audit
# trail, NOT a sandbox — the sandbox is the platform's permission system.
#
# THE STRUCTURED ROUTING ACTION (PACKET-0055). The deadlock-guard exception —
# the SOLE ungated pass in the task-entry boundary — no longer substring-
# matches the raw event (the operator ruled that breadth "a real enforcement
# bypass, not merely a wording issue"). It fires only when the ACTUAL
# tool_input.command field, extracted and trimmed, IS exactly one clean
# routing-tool invocation: an optional interpreter prefix (bash/sh for the .sh
# tools, node for mode-select.mjs), an optional path prefix, exactly one of
# route-task.sh | mode-select.mjs | routing-check.sh | record-degradation.sh,
# then arguments free of every chaining/substitution metacharacter — no ';',
# '&', '|', backtick, '$(', '<', '>', no newline; quotes, braces, brackets,
# colons and commas stay legal, so the refusal's own quoted-JSON --descriptor
# recovery example passes. Everything that merely MENTIONS a routing tool —
# compound commands, comments, sh -c/eval wrappers, substitution, routing-tool
# paths in non-command fields — and every event the extractor cannot read
# falls THROUGH to normal classification: extraction fails TOWARD GATING,
# never toward an ungated pass (the recovery command is clean and always
# extracts, so the fall-through cannot re-create the deadlock). The extraction
# is itself a heuristic over JSON-in-shell, and that failure direction is its
# stated bound.
RT_STRICT='^((bash|sh) +)?([A-Za-z0-9._/-]*/)?(route-task\.sh|routing-check\.sh|record-degradation\.sh)( |$)|^(node +)?([A-Za-z0-9._/-]*/)?mode-select\.mjs( |$)'

extract_command(){ # <raw-json> -> tool_input.command's JSON string content (escape-encoded); rc 1 = absent/unreadable
  local in="$1" rest raw
  case "$in" in *'"command"'*) ;; *) return 1 ;; esac
  # First occurrence of the unescaped key: a decoy INSIDE a JSON string value
  # is necessarily \"-escaped, so its colon-quote shape cannot match below.
  rest="${in#*\"command\"}"
  raw="$(printf '%s' "$rest" | sed -n 's/^[[:space:]]*:[[:space:]]*"\(\([^"\\]\|\\.\)*\)".*/\1/p' | head -n1)"
  [ -n "$raw" ] || return 1
  printf '%s' "$raw"
}

routing_action(){ # <raw-json> -> "<tool>\t<decoded command>" iff the command IS one clean routing invocation; rc 1 otherwise
  local in="$1" raw cmd stripped t BS='\' SENT=$'\x01'
  raw="$(extract_command "$in")" || return 1
  # Only the benign JSON escapes \" \\ \/ may appear: any other escape (\n,
  # \t, \u003b, ...) could conceal a metacharacter from the checks below, so
  # its presence falls through — toward gating.
  stripped="$(printf '%s' "$raw" | sed 's|\\["\\/]||g')"
  case "$stripped" in *"$BS"*) return 1 ;; esac
  # Decode the three benign escapes so the checks and the fingerprint see the
  # command exactly as the shell receives it. Decoding cannot conceal a
  # forbidden character: none of the three decodes to one.
  cmd=${raw//"$BS$BS"/$SENT}
  cmd=${cmd//"$BS"\"/\"}
  cmd=${cmd//"$BS"\//\/}
  cmd=${cmd//$SENT/$BS}
  cmd="${cmd#"${cmd%%[! ]*}"}"; cmd="${cmd%"${cmd##*[! ]}"}"
  [ -n "$cmd" ] || return 1
  case "$cmd" in
    *';'*|*'&'*|*'|'*|*'`'*|*'$('*|*'<'*|*'>'*|*$'\n'*|*$'\t'*|*$'\r'*) return 1 ;;
  esac
  printf '%s' "$cmd" | grep -qE "$RT_STRICT" || return 1
  t="$(printf '%s' "$cmd" | grep -oE 'route-task\.sh|mode-select\.mjs|routing-check\.sh|record-degradation\.sh' | head -n1)"
  printf '%s\t%s' "$t" "$cmd"
}

# Can the receipt store be used at all — listable where it exists, creatable
# where it is not? When NEITHER holds, route-task.sh could never write the
# receipt a block would demand, so mutgate_decide FAILS OPEN instead of
# refusing into a dead end (PACKET-0055; the trace rides the stderr fallback).
store_available(){
  if [ -d "$RDIR" ]; then ls "$RDIR" >/dev/null 2>&1; else mkdir -p "$RDIR" 2>/dev/null; fi
}

# --- BOOTSTRAP CHANNEL (authority_bootstrap_permission_class_mismatch) -------
#
# EXP-0005 measured every Gravito arm producing zero mutations. Reproduction
# refuted the recorded cause: the gate ALLOWS route-task.sh and route-task.sh
# works on a clean clone. What failed was one layer out — the HOST permission
# layer refused the Bash invocation in headless sessions with no approver.
#
# The defect is a PERMISSION-CLASS MISMATCH: earning first authority required
# Bash (frequently approval-gated) even when the authorized work needed only
# Edit/Write (auto-approved). Native paid host denials as friction because its
# work path was Edit; Gravito paid one as total paralysis because Edit itself
# was gated behind that Bash call.
#
# THE INVARIANT: first mutation authority must not depend on an operation class
# whose host permission requirements are stricter than the mutation class it
# authorizes.
#
# THE CHANNEL: a routing request may be expressed by WRITING one file. Writes
# to that exact path — and no other — are ungated, because the path is the
# routing channel, not product mutation. Writing it authorizes NOTHING by
# itself: the request is schema-checked and then routed through the ordinary
# route-task.sh, so the descriptor, the mode selection and every downstream
# budget/escalation/close rule apply unchanged.
REQ_FILE="$RDIR/routing-request.json"

extract_file_path(){ # <raw-json> -> tool_input.file_path; rc 1 = absent
  local in="$1" rest raw
  case "$in" in *'"file_path"'*) ;; *) return 1 ;; esac
  rest="${in#*\"file_path\"}"
  raw="$(printf '%s' "$rest" | sed -n 's/^[[:space:]]*:[[:space:]]*"\(\([^"\\]\|\\.\)*\)".*/\1/p' | head -n1)"
  [ -n "$raw" ] || return 1
  printf '%s' "$raw"
}

is_routing_request_path(){ # <raw-json> -> rc 0 iff the write targets exactly the request file
  local fp; fp="$(extract_file_path "$1")" || return 1
  case "$fp" in
    */build-os/packets/routing/routing-request.json|build-os/packets/routing/routing-request.json) return 0 ;;
    *) return 1 ;;
  esac
}

mut_classify(){ # <raw-json> <tool> -> routing_tool | git_readonly | mutation | other
  local in="$1" tool="$2"
  case "$tool" in
    Edit|Write|NotebookEdit)
      # The routing channel itself is not product mutation. Exactly one path.
      if is_routing_request_path "$in"; then printf 'routing_request'; return 0; fi
      printf 'mutation'; return 0 ;;
    Bash) : ;;
    *) printf 'other'; return 0 ;;
  esac
  # DEADLOCK GUARD, structured (PACKET-0055): exactly-recognized routing
  # invocations only — without an ungated pass here no session could issue the
  # receipt its first gated call requires; anything short of an exact
  # invocation falls through to the git/mutation classes and gates.
  if routing_action "$in" >/dev/null; then printf 'routing_tool'; return 0; fi
  if printf '%s' "$in" | grep -qE '(^|[^A-Za-z0-9_])git([^A-Za-z0-9_]|$)'; then
    # Any git command carrying a mutating subcommand or a force flag is
    # mutation-capable — checked FIRST so `git status && git push` gates.
    if printf '%s' "$in" | grep -qE '(^|[^A-Za-z0-9_-])(push|commit|merge|rebase|reset|checkout|restore|clean|apply|am|cherry-pick|tag|stash)([^A-Za-z0-9_-]|$)|--force(-with-lease)?([^A-Za-z0-9_-]|$)|[[:space:]]-f([[:space:]\"\\]|$)'; then
      printf 'mutation'; return 0
    fi
    # The read-only inspection class, by git subcommand. `git -C dir status`
    # and other indirections fall through to mutation-capable — conservative.
    if printf '%s' "$in" | grep -qE 'git[[:space:]]+(status|log|diff|show|rev-parse|ls-files|branch)([^A-Za-z0-9_-]|$)'; then
      printf 'git_readonly'; return 0
    fi
    printf 'mutation'; return 0
  fi
  printf 'mutation'   # Bash defaults to mutation-capable: the boundary is entry, not tool trivia
}

# Route a pending request through the ordinary tool. Returns 0 only when a
# receipt was actually minted. Deterministic, idempotent (the request is
# consumed), and audited with the request's sha256.
redeem_routing_request(){
  [ -f "$REQ_FILE" ] || return 1
  command -v node >/dev/null 2>&1 || { logrow "none" "-" "BOOTSTRAP-REQUEST-REFUSED" "reason=node-unavailable"; return 1; }

  local tid desc descr sha rt out
  # Schema check: task_id, description and a descriptor object must all be
  # present. Anything missing is a refusal, never a permissive default.
  if ! node -e '
    const fs=require("fs");
    const j=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
    if(!j.task_id||!j.description||!j.descriptor||typeof j.descriptor!=="object") process.exit(1);
    if(!/^[A-Za-z0-9._-]{1,64}$/.test(j.task_id)) process.exit(1);
  ' "$REQ_FILE" 2>/dev/null; then
    sha="$(sha256sum "$REQ_FILE" 2>/dev/null | cut -c1-12)"
    logrow "none" "-" "BOOTSTRAP-REQUEST-REFUSED" "reason=schema-invalid sha256=${sha:--}"
    rm -f "$REQ_FILE"
    return 1
  fi

  tid="$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).task_id)' "$REQ_FILE" 2>/dev/null)"
  desc="$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).description)' "$REQ_FILE" 2>/dev/null)"
  descr="$(node -e 'console.log(JSON.stringify(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).descriptor))' "$REQ_FILE" 2>/dev/null)"
  sha="$(sha256sum "$REQ_FILE" 2>/dev/null | cut -c1-12)"
  rt="$DATA_ROOT/build-os/tools/route-task.sh"
  [ -x "$rt" ] || [ -f "$rt" ] || { logrow "none" "-" "BOOTSTRAP-REQUEST-REFUSED" "reason=route-task-missing"; return 1; }

  # Consume FIRST, so a failing route cannot be retried in a loop.
  rm -f "$REQ_FILE"
  out="$(bash "$rt" --task-id "$tid" --description "$desc" --descriptor "$descr" 2>&1)" || {
    logrow "none" "-" "BOOTSTRAP-REQUEST-REFUSED" "reason=route-task-failed sha256=${sha:--} detail=$(printf '%s' "$out" | tr -d '\t\r\n' | cut -c1-120)"
    return 1
  }
  logrow "$tid" "-" "BOOTSTRAP-RECEIPT-MINTED" "via=routing-request-channel sha256=${sha:--} task_id=$tid"
  return 0
}

# LEAN L2 (LEAN-MANIFEST.md) — THE RECEIPT MINTS ITSELF.
#
# The measured interaction this removes: routing_bookkeeping at 2.0 text-turns
# per arm plus the write-request-and-retry round-trips inside the 4.6-vs-0.0
# control-call gap. Every field of the worker-authored routing request was
# always derivable here — this gate already runs the selector and already mints
# receipts from the request file. The only thing the worker was adding was the
# typing.
#
# THE FLOOR DESCRIPTOR. The auto-derived descriptor deliberately claims the
# MINIMUM on all thirteen fields, so the selector grants its lowest mode
# (direct). That is the manifest's cap-by-construction: a task that outgrows
# the floor trips the existing reassess/escalation machinery unchanged, and any
# mode above the floor still requires an explicit, worker-visible routing act.
# Deriving a "truer" richer descriptor here would be guessing scope on the
# worker's behalf — the one thing a floor never does.
auto_route_first_mutation(){ # <raw-json> <tool> -> rc 0 iff a receipt was minted
  command -v node >/dev/null 2>&1 || { logrow "none" "-" "AUTO-ROUTE-SKIPPED" "reason=node-unavailable"; return 1; }
  local rt tid fp exc desc descr out
  # DATA_ROOT ONLY — no CODE_ROOT fallback, and the reason is a demonstrated
  # defect, not caution: route-task.sh writes its receipt under ITS OWN tree,
  # so minting via the code tree plants a receipt in the ORCHESTRATOR repo when
  # the worker's data tree merely lacks tools. The first run of lean-l2.test.sh
  # did exactly that. A data tree without route-task falls through to the
  # preserved BLOCK; administered arm trees always carry it.
  rt="$DATA_ROOT/build-os/tools/route-task.sh"
  [ -f "$rt" ] || { logrow "none" "-" "AUTO-ROUTE-SKIPPED" "reason=route-task-missing-in-data-tree"; return 1; }
  tid="auto-$(date -u +%Y%m%dT%H%M%SZ 2>/dev/null || printf 'x')-$$"
  fp="$(extract_file_path "$1")" || fp=""
  exc="$(printf '%s' "${fp:-$2}" | tr -d '\t\r\n"' | cut -c1-60)"
  desc="auto-routed at first mutation: $2${exc:+ -> $exc}"
  descr='{"expected_files_changed":1,"requires_tests":false,"expected_session_count":1,"prior_context_required":false,"handoff_required":false,"consequence_level":"low","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}'
  out="$(bash "$rt" --task-id "$tid" --description "$desc" --descriptor "$descr" 2>&1)" || {
    logrow "none" "-" "AUTO-ROUTE-FAILED" "tool=$2 detail=$(printf '%s' "$out" | tr -d '\t\r\n' | cut -c1-120)"
    return 1
  }
  logrow "$tid" "-" "AUTO-RECEIPT-MINTED" "via=lean-l2 authored_by=runtime tool=$2 target=${exc:--}"
  return 0
}

# R0.1 §1 / R1-P2 — THE GOAL GATE, FAIL CLOSED, shared by every mutating
# entry: the file-tool mutgate below and the MCP mutation gate (mcpgate).
# An installed gravito.goal that is lapsed/not-yet/over-budget BLOCKS with an
# actionable refusal receipt, BEFORE any side effect. A missing goal file
# changes nothing (existing semantics). Returns 0 = proceed; on a halt it
# prints the caller-protocol "BLOCK\n<message>" itself and returns 1.
goal_gate_or_block(){ # <tool-name>
  local _gtool="${1:-unknown}" _gc _gout _gstat _h0 _h0out
  # H0_system Class-A contract — evaluated ONCE per mutation, BEFORE authority
  # (canonical sequence: state -> H0 -> ... -> authority). Same named facts as
  # the full surface (h0-check.sh --gate); fail closed with a receipt. This is
  # the tool-boundary member of the H0 entry-point inventory; cmd_run carries
  # the full-surface member. A corrupt ledger MUST block here too: goal-check's
  # sums silently skip bad lines, so a corrupt ledger undercounts spend.
  # LEGACY POLICY (versioned, chosen 2026-08-12): this hook running proves the
  # target is Gravito-managed (only registered matchers invoke it). For a
  # managed target, a MISSING or UNREADABLE H0 component is itself a Class-A
  # enforcement-integrity failure — absence of the enforcer is never evidence
  # of protection. Supported mutations FAIL CLOSED with an actionable receipt
  # until `gravito update` restores the component; reads stay available
  # (Read/Grep/Glob and allowlisted MCP reads never reach this path).
  # Pre-R1 targets with NO registered matchers never invoke this hook at all:
  # they are UNPROTECTED by wiring absence — named in diagnose, not claimable.
  _h0="$DATA_ROOT/build-os/tools/h0-check.sh"
  [ -x "$_h0" ] || _h0="$(dirname "${BASH_SOURCE[0]}")/../../build-os/tools/h0-check.sh"
  if [ ! -x "$_h0" ]; then
    mkdir -p "$DATA_ROOT/build-os/receipts"
    printf '%s tool=%s BLOCKED H0-enforcement-component-missing (UPDATE_REQUIRED)\n' "$(date -u +%FT%TZ)" "$_gtool" >> "$DATA_ROOT/build-os/receipts/refusals.log"
    printf 'BLOCK\nH0 HALT (fail closed): this Gravito-managed target is missing its H0 enforcement component (build-os/tools/h0-check.sh). A missing enforcer is a Class-A integrity failure, not a pass. Next action: run gravito update on this repository. Reads remain available.\n'
    return 1
  fi
  if ! _h0out="$(bash "$_h0" --gate "$DATA_ROOT" 2>&1)"; then
    mkdir -p "$DATA_ROOT/build-os/receipts"
    printf '%s tool=%s BLOCKED %s\n' "$(date -u +%FT%TZ)" "$_gtool" "$_h0out" >> "$DATA_ROOT/build-os/receipts/refusals.log"
    printf 'BLOCK\nH0 HALT (fail closed, before authority): %s\nThis mutation was refused BEFORE any side effect. Receipt: build-os/receipts/refusals.log.\n' "$_h0out"
    return 1
  fi
  [ -f "$DATA_ROOT/gravito.goal" ] || return 0
  _gc="$DATA_ROOT/build-os/tools/goal-check.sh"
  [ -x "$_gc" ] || _gc="$(dirname "${BASH_SOURCE[0]}")/../../build-os/tools/goal-check.sh"
  if [ -x "$_gc" ]; then
    if ! _gout="$(bash "$_gc" --gate "$DATA_ROOT/gravito.goal" 2>&1)"; then
      mkdir -p "$DATA_ROOT/build-os/receipts"
      _gstat="$(bash "$_gc" --status "$DATA_ROOT/gravito.goal" 2>/dev/null || true)"
      printf '%s tool=%s BLOCKED %s | %s\n' "$(date -u +%FT%TZ)" "$_gtool" "$_gstat" "$_gout" >> "$DATA_ROOT/build-os/receipts/refusals.log"
      printf 'BLOCK\nGOAL HALT (tool-level, fail closed): %s\nThis mutation was refused BEFORE any side effect. Receipt: build-os/receipts/refusals.log. Reads, gravito status, and gravito stop remain available.\n' "$_gout"
      return 1
    fi
  else
    # Fail CLOSED on a missing gate when a goal exists: an unenforceable
    # contract must not silently become no contract.
    mkdir -p "$DATA_ROOT/build-os/receipts"
    printf '%s tool=%s BLOCKED gate-tool-missing\n' "$(date -u +%FT%TZ)" "$_gtool" >> "$DATA_ROOT/build-os/receipts/refusals.log"
    printf 'BLOCK\nGOAL HALT (fail closed): gravito.goal is installed but goal-check.sh is missing — run gravito update to restore the engine.\n'
    return 1
  fi
  return 0
}

# R1-P2 — MCP MUTATION GATE, DEFAULT CLOSED. Every mcp__* tool call reaches
# this mode via its own PreToolUse matcher. Classification is the closed part:
# a tool is read-only ONLY if it matches a line in the narrowly declared
# allowlist (engine-shipped; target may not widen it silently — the DATA_ROOT
# copy is only consulted if the engine copy is absent). Everything else —
# including read-SOUNDING names nobody declared — is treated as a MUTATION and
# passes the same fail-closed goal gate as Edit/Write/Bash. No goal installed
# = no goal gate, identical to the file-tool contract.
mcp_readonly(){ # <tool-name> -> 0 iff allowlisted read-only
  local _t="$1" _f _line
  for _f in "$(dirname "${BASH_SOURCE[0]}")/mcp-readonly-allowlist.txt" \
            "$DATA_ROOT/.claude/hooks/mcp-readonly-allowlist.txt"; do
    [ -f "$_f" ] || continue
    while IFS= read -r _line; do
      case "$_line" in ''|\#*) continue ;; esac
      # shellcheck disable=SC2254 — glob patterns are the allowlist format
      case "$_t" in $_line) return 0 ;; esac
    done < "$_f"
    return 1   # first allowlist found is authoritative
  done
  return 1     # no allowlist anywhere = nothing is read-only
}

mcpgate_decide(){ # <stdin-json> — protocol on stdout: ALLOW or BLOCK + message
  local _tool
  _tool="$(printf '%s' "${1:-}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  case "$_tool" in mcp__*) : ;; *) printf 'ALLOW\n'; return 0 ;; esac
  if mcp_readonly "$_tool"; then printf 'ALLOW\n'; return 0; fi
  goal_gate_or_block "$_tool" || return 0   # BLOCK already printed
  printf 'ALLOW\n'; return 0
}

mutgate_decide(){ # <stdin-json> — protocol on stdout: ALLOW or BLOCK + message
  # R0.1 §1 — goal gate FIRST, so no side effect can precede it. Applies in
  # every session that passes PreToolUse (direct, resumed, nested subagents).
  # The routing logic below deliberately fails OPEN on receipt problems; the
  # goal gate is the opposite by owner instruction. Reads are never gated
  # (emergency stop and status stay available).
  local _gtool
  _gtool="$(printf '%s' "${1:-}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  case "$_gtool" in Read|Grep|Glob) : ;; *)
    goal_gate_or_block "$_gtool" || return 0   # BLOCK already printed
  esac
  local in="$1" tool cls rec tid="none" mode="-" v act rtool rcmd sha exc
  tool="$(printf '%s' "$in" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
  [ -n "$tool" ] || return 1   # unreadable event -> fail open in the wrapper
  cls="$(mut_classify "$in" "$tool")"
  rec="$(open_receipt)" || rec=""
  if [ -n "$rec" ]; then tid="$(fval "$rec" task_id)"; mode="$(fval "$rec" selected_mode)"; [ -n "$tid" ] || tid="-"; fi
  case "$cls" in
    routing_tool)
      # THE ACTION FINGERPRINT (PACKET-0055): the pass row records WHICH tool
      # matched, the first 12 hex chars of the exact command's sha256, and a
      # sanitized <=80-char excerpt (tabs/newlines stripped — the ledgers are
      # TSV). Only exact invocations reach this label at all, so the ledger
      # alone now distinguishes "ran route-task.sh" from anything else.
      act="$(routing_action "$in")" || act=$'-\t-'
      rtool="${act%%$'\t'*}"; rcmd="${act#*$'\t'}"
      sha="-"
      if command -v sha256sum >/dev/null 2>&1; then
        sha="$(printf '%s' "$rcmd" | sha256sum 2>/dev/null | cut -c1-12)"; [ -n "$sha" ] || sha="-"
      fi
      exc="$(printf '%s' "$rcmd" | tr -d '\t\r\n' | cut -c1-80)"
      logrow "$tid" "$mode" "ROUTING-TOOL-PASS" "tool=$tool ungated=deadlock-guard routing_tool=$rtool sha256=$sha cmd=$exc"
      [ -n "$rec" ] && { staterow "$rec" routing_tool_pass "tool_name=$tool routing_tool=$rtool sha256=$sha cmd=$exc" || true; }
      printf 'ALLOW\n'; return 0 ;;
    git_readonly)
      logrow "$tid" "$mode" "GIT-READONLY-PASS" "tool=$tool class=exploratory heuristic=git-subcommand"
      [ -n "$rec" ] && { staterow "$rec" exploratory_event "tool_name=$tool source=git_readonly" || true; }
      printf 'ALLOW\n'; return 0 ;;
    routing_request)
      # Writing the request authorizes NOTHING. It is allowed because the path
      # is the routing channel, and it is logged so the ledger shows the
      # request separately from the receipt it may later mint.
      logrow "$tid" "$mode" "ROUTING-REQUEST-WRITE" "tool=$tool ungated=bootstrap-channel path=routing-request.json"
      printf 'ALLOW\n'; return 0 ;;
    other)
      printf 'ALLOW\n'; return 0 ;;
  esac
  if [ -z "$rec" ]; then
    # BOOTSTRAP REDEMPTION. A pending, schema-valid request is routed through
    # the ordinary route-task.sh — from inside the hook, which executes outside
    # the tool-permission layer. That is the whole fix: the worker earned
    # authority using the SAME permission class as the work it authorizes.
    # A malformed request mints nothing and the block below stands.
    if redeem_routing_request; then
      rec="$(open_receipt)" || rec=""
      if [ -n "$rec" ]; then
        tid="$(fval "$rec" task_id)"; mode="$(fval "$rec" selected_mode)"
        printf 'ALLOW\n'; return 0
      fi
    fi
  fi
  if [ -z "$rec" ]; then
    if ! store_available; then
      # STORE-UNAVAILABLE IS NOT A BRICK (PACKET-0055): with the store neither
      # readable nor creatable, route-task.sh could never write the receipt a
      # block would demand — a refusal here is a dead end whose own recovery
      # command cannot succeed. FAIL OPEN instead, traced: the row itself
      # rides the stderr fallback (UNLOGGED(store unwritable)) whenever the
      # log file shares the store's fate — the layer-4 mechanics of 0053.
      logrow "none" "-" "FAIL-OPEN-STORE-UNAVAILABLE" "tool=$tool store unreadable and uncreatable: recovery cannot succeed, so blocking would be a dead end"
      printf 'ALLOW\n'
      return 0
    fi
    # LEAN L2: with the store available and no pending request, the runtime
    # performs the deterministic administration itself instead of refusing and
    # dictating the schema. The BLOCK below survives as the fallback for hosts
    # where route-task itself cannot run — the worker-visible refusal is now
    # the exception path, not the default first-mutation experience.
    if auto_route_first_mutation "$in" "$tool"; then
      rec="$(open_receipt)" || rec=""
      if [ -n "$rec" ]; then
        tid="$(fval "$rec" task_id)"; mode="$(fval "$rec" selected_mode)"
        printf 'ALLOW\n'; return 0
      fi
    fi
    logrow "none" "-" "BLOCK-MUTATION-NO-RECEIPT" "tool=$tool"
    printf 'BLOCK\n'
    # L3 message contract: every BLOCK states what the runtime already did,
    # ABOVE whichever recovery text follows (selector-generated or fallback).
    printf 'What the runtime already did: attempted to mint the routing receipt automatically and could not on this data tree (see AUTO-ROUTE rows in the ledger), so this refusal is the exception path, not the default.\n'
    # THE REFUSAL IS GENERATED BY THE SELECTOR, not hand-authored here. One
    # ruleset decides both what self-audit calls incompatible and what the
    # worker is told to do, so the advertised recovery cannot drift away from
    # the path that actually works on this host. A static message that says
    # "run this Bash command" while the host denies Bash is how EXP-0005
    # produced 0/12.
    # CODE_ROOT, not DATA_ROOT. The recovery generator is CODE that ships with
    # this gate, not per-repo DATA. Resolving it under the data root meant that
    # whenever the two differ -- which is the entire purpose of
    # ROUTING_GATE_ROOT / CLAUDE_PROJECT_DIR -- the selector silently could not
    # be found, and the gate fell through to the fallback that advertises the
    # shell route unconditionally. That is precisely the behaviour the selector
    # was made load-bearing to prevent, reappearing in the one configuration
    # nobody ran. The same call already resolves --gate under CODE_ROOT.
    _rec="$CODE_ROOT/build-os/assumptions/gate-recovery.mjs"
    if command -v node >/dev/null 2>&1 && [ -f "$_rec" ] \
       && node "$_rec" --tool "$tool" --gate "$CODE_ROOT/.claude/hooks/routing-gate.sh" 2>/dev/null; then
      logrow "$tid" "-" "RECOVERY-SELECTED" "tool=$tool host=${GRAVITO_HOST_PROFILE:-unknown_conservative} source=selector"
    else
      # Fail toward DISCOVERABILITY: with no selector, advertise every route
      # rather than none, lowest privilege first. A worker told nothing cannot
      # proceed; a worker told too much merely spends one extra call.
      printf 'routing-gate: MUTATION BLOCKED — %s is mutation-capable and NO OPEN routing receipt exists under build-os/packets/routing/.\n' "$tool"
      printf 'SELECTOR UNAVAILABLE — every known recovery is listed, lowest privilege first:\n'
      printf 'RECOVERY A — no shell required. WRITE build-os/packets/routing/routing-request.json with {"task_id":"<id>","description":"<one line>","descriptor":{...13 fields...}}, then retry.\n'
      printf 'RECOVERY B — via shell: build-os/tools/route-task.sh --task-id <id> --description "<one line>" --descriptor <13-field-json>\n'
      printf 'Continue the task — only this unrouted call is refused, not the work.\n'
      logrow "$tid" "-" "RECOVERY-FALLBACK" "tool=$tool reason=selector-unavailable"
    fi
    return 0
  fi
  # The fire-once REASSESS trip: armed by the counter, enforced here, reset by
  # a reassessment record (fresh receipt = fresh state file; or an escalation/
  # degradation entry landing after the arming snapshot).
  local sf armed esc_s deg_s snap_esc snap_deg
  sf="$SDIR/$(basename "$rec" .md).tsv"
  armed=""
  if [ -f "$sf" ]; then
    armed="$(awk -F'\t' '$2=="reassess_block"||$2=="reassess_reset"{a=""} $2=="reassess_armed"{a=$3} END{print a}' "$sf")"
  fi
  if [ -n "$armed" ]; then
    esc_s="-"; deg_s="-"
    v="$(fval "$rec" escalation_evidence)"; [ -n "$v" ] && [ "$v" != "-" ] && esc_s="set"
    v="$(fval "$rec" degradation_note)";    [ -n "$v" ] && [ "$v" != "-" ] && deg_s="set"
    snap_esc="$(printf '%s' "$armed" | sed -n 's/.*esc=\([^ ]*\).*/\1/p')"; [ -n "$snap_esc" ] || snap_esc="-"
    snap_deg="$(printf '%s' "$armed" | sed -n 's/.*deg=\([^ ]*\).*/\1/p')"; [ -n "$snap_deg" ] || snap_deg="-"
    if [ "$esc_s" != "$snap_esc" ] || [ "$deg_s" != "$snap_deg" ]; then
      staterow "$rec" reassess_reset "reason=reassessment-record-landed esc=$esc_s deg=$deg_s (armed snapshot esc=$snap_esc deg=$snap_deg)" || true
      logrow "$tid" "$mode" "REASSESS-RESET" "tool=$tool $armed"
      # fall through to ALLOW — the trip is reset, the counters restart
    else
      staterow "$rec" reassess_block "$armed fired=once" || true
      logrow "$tid" "$mode" "BLOCK-REASSESS" "tool=$tool $armed"
      printf 'BLOCK\n'
      printf 'routing-gate: MUTATION BLOCKED ONCE — REASSESS. A repetitive parent loop tripped on receipt %s (%s). Where the trip is the token proxy, its value is tier ESTIMATE — chars/4, never billing truth. The thresholds are derived defaults, operator-tunable (ROUTING_REASSESS_SAME_TOOL_MAX, ROUTING_REASSESS_PROXY_MULT). Re-route before continuing: confirm the mode via build-os/tools/route-task.sh (a fresh receipt), or record an evidence-bearing escalation on the receipt, or degrade honestly via build-os/tools/record-degradation.sh. This trip fires exactly once — the next mutation-capable call passes, and a reassessment record resets the trip. Continue the task — only this one call is refused, not the work.\n' "$(basename "$rec")" "$armed"
      return 0
    fi
  fi
  staterow "$rec" mutation_event "tool_name=$tool class=mutation" || return 1
  logrow "$tid" "$mode" "ALLOW-MUTATION" "tool=$tool"
  printf 'ALLOW\n'
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
  printf 'exploratory_events: %s (EXACT — the explore half of the explore/execute split)\n' "$(count_kind "$rec" exploratory_event)"
  printf 'mutation_events: %s (EXACT — admitted mutation-capable calls)\n' "$(count_kind "$rec" mutation_event)"
  if [ -f "$sf" ]; then
    printf 'token_proxy: %s (ESTIMATE — sum of tool-input chars / 4; never billing truth)\n' \
      "$(awk -F'\t' '$2=="tool_event" && match($3,/chars=[0-9]+/){s+=substr($3,RSTART+6,RLENGTH-6)+0} END{print int(s/4)}' "$sf")"
  else
    printf 'token_proxy: 0 (ESTIMATE — no state rows yet)\n'
  fi
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
  gate|mutgate|mcpgate|count|post|status) ;;
  -h|--help|help) sed -n '2,70p' "${BASH_SOURCE[0]}"; exit 0 ;;
  *) printf 'routing-gate: unknown command "%s" — expected gate|mutgate|mcpgate|count|post|status\n' "${CMD:-}" >&2; exit 2 ;;
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
  gate|mutgate|mcpgate)
    # Keep the hook's REAL stderr reachable on fd 9: the decide functions run
    # with stderr silenced (incidental tool noise must not pollute a refusal),
    # but logrow's unwritable-store fallback line must still escape — a trace
    # that dies inside the capture is no trace (PACKET-0055).
    exec 9>&2
    if [ "$CMD" = "gate" ]; then
      OUT="$(gate_decide "$IN" 2>/dev/null)"; RC=$?
    elif [ "$CMD" = "mcpgate" ]; then
      OUT="$(mcpgate_decide "$IN" 2>/dev/null)"; RC=$?
    else
      OUT="$(mutgate_decide "$IN" 2>/dev/null)"; RC=$?
    fi
    DECISION="$(printf '%s\n' "$OUT" | sed -n '1p')"
    if [ "$RC" -eq 0 ] && [ "$DECISION" = "ALLOW" ]; then
      exit 0
    elif [ "$RC" -eq 0 ] && [ "$DECISION" = "BLOCK" ]; then
      printf '%s\n' "$OUT" | sed '1d' >&2
      exit 2
    else
      # FAIL OPEN: a broken gate must not brick every session. Logged, because
      # a silent fail-open is an invisible outage of the control plane.
      logrow "-" "-" "FAIL-OPEN" "cmd=$CMD rc=$RC decision=${DECISION:-none}"
      exit 0
    fi ;;
esac
exit 0
