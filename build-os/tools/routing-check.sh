#!/usr/bin/env bash
# Build OS — routing-check.sh: the CLOSE-TIME ENFORCEMENT GATE over routing
# receipts. This is the mechanical half of the fix for EXP-0002's enforcement
# defect: buildos T5 executed Full ceremony (4 dispatches, $4.80, 7.4M tokens)
# over its own recorded `mode_selector_says: gravito_light`, and nothing
# refused. This tool is the thing that refuses.
#
# WHAT IT REFUSES (exit 2) — refusal is for CONTRADICTION, never for absence:
#   SILENT-ESCALATION   executed_mode exceeds selected_mode and the escalation
#                       field is '-'. Escalation is legal; silence is not.
#   EVIDENCE-FREE       an escalation record exists and escalation_evidence is
#                       '-'. An escalation nobody can audit is a silent one
#                       wearing a label.
#   BUDGET-BREACH       a FILLED-IN consumption field exceeds its budget and
#                       degradation_note is '-'. The gate polices honesty of
#                       the record: a declared degradation passes.
#   FULL-NO-BUDGETS     a receipt claims gravito_full (selected or executed)
#                       and any budget field is '-' or non-numeric. Full
#                       without budgets is the uncontrolled escalation EXP-0002
#                       measured.
#   MALFORMED           a required field is missing, or a filled consumption
#                       value is not a number. A partially declared receipt is
#                       an undeclared one.
#
# PACKET-0053 EXTENSIONS — by EXTENSION, never a fork: every new field is
# OPTIONAL and an ABSENT field reads as '-', so every receipt issued before
# these fields existed stays valid (absence is an admission, not a defect).
#   BUDGET-BREACH (process)  consumed_process_dispatches exceeds
#                       process_dispatch_allowance with degradation_note '-'.
#                       The gate chain is governance ceremony with its own
#                       allowance, separate from budget_max_subagents.
#   CONTRIBUTION-MISSING  a gravito_full receipt (selected or executed) closed
#                       with consumed_subagents > 0 and ZERO `contribution:`
#                       rows. Contribution accounting is MANDATORY for Full;
#                       an all-'-' row passes as an admission and is REPORTED
#                       as non-contributing — counted, never hidden.
#   STATE-DISAGREE      the live gate's append-only state file
#                       (live_state/<receipt-id>.tsv, EXACT hook counts) and a
#                       FILLED consumption count contradict each other. The
#                       disagreement is REPORTED, never reconciled: no side is
#                       auto-corrected, because auto-correcting either side is
#                       how one record silently rewrites the other.
#   MALFORMED (attr)    an attr_* field outside the seven declared attribution
#                       layers (task_execution, context_retrieval,
#                       subagent_execution, verification, review,
#                       governance_process, experiment_audit), or an unreadable
#                       contribution row.
#
# WHAT IT PASSES: executed_mode at or below selected_mode (de-escalation is
# free); every '-' consumption field (AN UNKNOWN IS NOT A ZERO — '-' is an
# honest admission, reported as such); an escalation WITH evidence; a breach
# WITH its degradation note.
#
# WHY THIS CHAINS THROUGH tests/routing_enforcement_tests.sh AND NOT INSIDE
# scan-controls.sh check: the checks that chain on that path (anchors_check,
# counts_check) are internal functions of scan-controls.sh — it launches no
# external script, and this packet does not make it start. The repo pattern for
# an external refusal-capable tool is a chained suite (bandwidth-check.sh,
# authority-envelope.sh, ...), and the suite sweeps the LIVE store every run.
#
# HONEST BOUND, named rather than implied: this gate reads what the receipt
# RECORDS. Live-session token/call counters are not machine-visible to bash, so
# mid-flight circuit-breaker behaviour is PROTOCOL (routing_contract.md),
# verified here at close only through the consumption-vs-budget comparison. A
# session that lies into its receipt is caught by nothing in this file.
#
# Usage:
#   routing-check.sh check [--receipt FILE | --dir DIR]
# Default: sweep build-os/packets/routing/*.md. A sweep that finds ZERO
# receipts REFUSES — a blinded sweep certifies nothing.
# Exit: 0 all receipts pass; 2 any refusal. Reads only; writes nothing.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"

refuse(){ printf 'routing-check: REFUSED — %s\n' "$*" >&2; exit 2; }

CMD="${1:-}"; [ $# -gt 0 ] && shift
[ "$CMD" = "check" ] || refuse "unknown command \"${CMD:-}\" — expected: check [--receipt FILE | --dir DIR]"

RECEIPT_FILE=""; DIR="$REPO/build-os/packets/routing"
while [ $# -gt 0 ]; do
  case "$1" in
    --receipt) [ $# -ge 2 ] || refuse "--receipt needs a value"; RECEIPT_FILE="$2"; shift 2 ;;
    --dir)     [ $# -ge 2 ] || refuse "--dir needs a value";     DIR="$2"; shift 2 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done

MODES="direct gravito_light gravito_full"
mode_rank(){ case "$1" in direct) echo 0 ;; gravito_light) echo 1 ;; gravito_full) echo 2 ;; *) echo -1 ;; esac; }

REQUIRED_FIELDS="task_id description_sha256 descriptor selected_mode selector_note issued_at \
budget_max_subagents budget_max_total_tokens budget_max_uncached_tokens budget_max_model_calls \
budget_max_wall_clock_s budget_max_cost_usd \
executed_mode escalation escalation_evidence \
consumed_subagents consumed_total_tokens consumed_uncached_tokens consumed_model_calls \
consumed_wall_clock_s consumed_cost_usd degradation_note"

BUDGET_PAIRS="subagents total_tokens uncached_tokens model_calls wall_clock_s cost_usd"

VIOL=0
viol(){ VIOL=$((VIOL+1)); printf '  %s\n' "$*"; }

# Numeric = integer or decimal. Budgets and filled consumption must both parse;
# comparison is by awk so 1.50 vs 0.31 is arithmetic, not string luck.
is_num(){ printf '%s' "$1" | grep -qE '^[0-9]+(\.[0-9]+)?$'; }
gt(){ awk -v a="$1" -v b="$2" 'BEGIN{exit !(a+0 > b+0)}'; }

fval(){ # <file> <field> — first value of "field: value", or empty
  awk -v k="$2" 'index($0, k": ")==1 { print substr($0, length(k)+3); exit }' "$1"
}
oval(){ # <file> <field> — OPTIONAL field: absent reads as '-' (PACKET-0053
        # fields are extensions; a receipt issued before they existed is valid
        # and its absence is the same admission a written '-' is)
  local v; v="$(fval "$1" "$2")"; [ -n "$v" ] && printf '%s' "$v" || printf '%s' "-"
}

# The seven attribution layers — the close-fill cost-attribution schema.
ATTR_LAYERS="task_execution context_retrieval subagent_execution verification review governance_process experiment_audit"

check_receipt(){ # <file> — increments VIOL per finding; prints one status line
  local f="$1" v miss="" sel exe esc esc_ev deg admissions=0 name bud con
  for v in $REQUIRED_FIELDS; do
    [ -n "$(fval "$f" "$v")" ] || miss="$miss $v"
  done
  if [ -n "$miss" ]; then
    viol "MALFORMED    $f is missing required field(s):$miss. A partially declared receipt is an undeclared one."
    return
  fi
  sel="$(fval "$f" selected_mode)"; exe="$(fval "$f" executed_mode)"
  esc="$(fval "$f" escalation)"; esc_ev="$(fval "$f" escalation_evidence)"
  deg="$(fval "$f" degradation_note)"
  case " $MODES " in *" $sel "*) ;; *) viol "MALFORMED    $f declares selected_mode \"$sel\", not one of: $MODES"; return ;; esac
  if [ "$exe" != "-" ]; then
    case " $MODES " in *" $exe "*) ;; *) viol "MALFORMED    $f declares executed_mode \"$exe\", not one of: $MODES or '-'"; return ;; esac
    # THE T5 RULE. The recorded verdict is binding: an executed mode above the
    # selected mode with no escalation record is the defect, mechanically.
    if [ "$(mode_rank "$exe")" -gt "$(mode_rank "$sel")" ] && [ "$esc" = "-" ]; then
      viol "SILENT-ESCALATION $f executed \"$exe\" over selected \"$sel\" with escalation '-'. Escalation requires a new evidence-bearing decision recorded BEFORE the escalated work begins; silence is the executed T5 defect and is refused."
    fi
  fi
  if [ "$esc" != "-" ] && [ "$esc_ev" = "-" ]; then
    viol "EVIDENCE-FREE $f records an escalation and escalation_evidence is '-'. An escalation record must name what changed; without it the record is a silent escalation wearing a label."
  fi
  # Full without budgets — whether Full was selected or reached by escalation.
  if [ "$sel" = "gravito_full" ] || [ "$exe" = "gravito_full" ]; then
    for name in $BUDGET_PAIRS; do
      bud="$(fval "$f" "budget_max_$name")"
      is_num "$bud" || viol "FULL-NO-BUDGETS $f claims gravito_full and budget_max_$name is \"$bud\". Full without budgets is uncontrolled escalation — the economics EXP-0002 measured being destroyed."
    done
  fi
  # Consumption vs budget: '-' is an ADMISSION and passes; a filled value is
  # compared, and a breach must carry its degradation note.
  for name in $BUDGET_PAIRS; do
    con="$(fval "$f" "consumed_$name")"
    if [ "$con" = "-" ]; then
      admissions=$((admissions+1))
      continue
    fi
    if ! is_num "$con"; then
      viol "MALFORMED    $f consumed_$name is \"$con\", neither '-' nor a number. An unreadable measurement is refused, never treated as agreement."
      continue
    fi
    bud="$(fval "$f" "budget_max_$name")"
    if is_num "$bud" && gt "$con" "$bud" && [ "$deg" = "-" ]; then
      viol "BUDGET-BREACH $f consumed_$name $con exceeds budget_max_$name $bud with degradation_note '-'. A breach is survivable; concealing one is not — declare the degradation or the receipt is refused."
    fi
  done

  # ---- PACKET-0053 extensions. Absent fields read '-' (old receipts valid). --
  local allow conp aline aname nrows nnoncontrib sf n_state_task n_state_proc
  # Process-dispatch allowance: the gate chain's own budget, separate from
  # budget_max_subagents (the 0050/0051 calibration question, resolved).
  allow="$(oval "$f" process_dispatch_allowance)"
  conp="$(oval "$f" consumed_process_dispatches)"
  if [ "$conp" = "-" ]; then
    admissions=$((admissions+1))
  elif ! is_num "$conp"; then
    viol "MALFORMED    $f consumed_process_dispatches is \"$conp\", neither '-' nor a number."
  elif is_num "$allow" && gt "$conp" "$allow" && [ "$deg" = "-" ]; then
    viol "BUDGET-BREACH $f consumed_process_dispatches $conp exceeds process_dispatch_allowance $allow with degradation_note '-'. Governance ceremony is budgeted too; declare the degradation or the receipt is refused."
  fi
  # Attribution layers: only the seven declared ones may appear. An invented
  # layer is how attribution stops being comparable across receipts.
  while IFS= read -r aline; do
    [ -n "$aline" ] || continue
    aname="${aline#attr_}"; aname="${aname%%:*}"
    case " $ATTR_LAYERS " in *" $aname "*) ;; *)
      viol "MALFORMED    $f declares attr_$aname, which is not one of the seven attribution layers: $ATTR_LAYERS" ;;
    esac
  done < <(grep -oE '^attr_[a-z_]+:' "$f" 2>/dev/null | sort -u)
  # Contribution rows: MANDATORY for a Full close with dispatches. Format:
  # contribution: agent | question | output_ref | 4 flag=y/n/- fields | tokens= | cost= | time=
  nrows=0; nnoncontrib=0
  while IFS= read -r aline; do
    [ -n "$aline" ] || continue
    nrows=$((nrows+1))
    if ! printf '%s\n' "$aline" | grep -qE '^contribution: [^|]+\| [^|]* \| [^|]* \| changed_implementation=(y|n|-) \| changed_conclusion=(y|n|-) \| caught_defect=(y|n|-) \| duplicated_work=(y|n|-) \| tokens=[^|]* \| cost=[^|]* \| time=[^|]*$'; then
      viol "MALFORMED    $f contribution row is unreadable: \"$aline\". An unreadable measurement is refused, never treated as agreement."
      continue
    fi
    printf '%s\n' "$aline" | grep -qE 'changed_implementation=- \| changed_conclusion=- \| caught_defect=- \| duplicated_work=-' \
      && nnoncontrib=$((nnoncontrib+1))
  done < <(grep -E '^contribution: ' "$f" 2>/dev/null)
  con="$(fval "$f" consumed_subagents)"
  if { [ "$sel" = "gravito_full" ] || [ "$exe" = "gravito_full" ]; } \
     && is_num "$con" && gt "$con" 0 && [ "$nrows" -eq 0 ]; then
    viol "CONTRIBUTION-MISSING $f is a gravito_full receipt closed with consumed_subagents $con and ZERO contribution rows. Contribution accounting is mandatory for Full: every dispatched agent answers what unique question it carried, or admits '-' per field — an admission passes; silence does not."
  fi
  # Close-consistency: the live gate's EXACT counts vs the filled fill. The
  # disagreement is REPORTED, never reconciled — neither record is corrected.
  sf="$(dirname "$f")/live_state/$(basename "$f" .md).tsv"
  if [ -f "$sf" ]; then
    n_state_task="$(awk -F'\t' '$2=="task_dispatch"{n++} END{print n+0}' "$sf")"
    n_state_proc="$(awk -F'\t' '$2=="process_dispatch"{n++} END{print n+0}' "$sf")"
    if is_num "$con" && [ "$con" != "$n_state_task" ]; then
      viol "STATE-DISAGREE $f claims consumed_subagents $con but its live state file counts $n_state_task task dispatch(es) (EXACT, hook-counted). Reported, never reconciled: no side is auto-corrected — find which record is wrong and fix THAT one."
    fi
    if is_num "$conp" && [ "$conp" != "$n_state_proc" ]; then
      viol "STATE-DISAGREE $f claims consumed_process_dispatches $conp but its live state file counts $n_state_proc process dispatch(es) (EXACT, hook-counted). Reported, never reconciled: no side is auto-corrected."
    fi
    if [ "$con" = "-" ] || [ "$conp" = "-" ]; then
      printf '  state_says   %s task=%s process=%s (live state beside an admission — information, not a refusal)\n' "$f" "$n_state_task" "$n_state_proc"
    fi
    # activity_binding (PACKET-0054): a CLOSED receipt whose live state records
    # mutation events while every consumption field is '-' and no telemetry
    # reconciliation exists is REPORTED, never refused — absence is admission,
    # and this line is what makes the unbound activity visible.
    local n_mut all_unbound cb
    n_mut="$(awk -F'\t' '$2=="mutation_event"{n++} END{print n+0}' "$sf")"
    if [ "$exe" != "-" ] && [ "$n_mut" -gt 0 ]; then
      all_unbound=1
      for cb in $BUDGET_PAIRS; do
        [ "$(fval "$f" "consumed_$cb")" = "-" ] || all_unbound=0
      done
      [ "$conp" = "-" ] || all_unbound=0
      if [ "$all_unbound" = "1" ]; then
        printf '  activity_binding %s UNBOUND-ACTIVITY: %s mutation event(s) recorded live while every consumption field is %s and no telemetry reconciliation exists — REPORTED, not refused: absence is admission, and this line is the visibility.\n' \
          "$f" "$n_mut" "'-'"
      fi
    fi
  fi
  printf 'routing-check: %s selected=%s executed=%s admissions=%s(admission fields, not zeros) contributions=%s(%s non-contributing)\n' \
    "$f" "$sel" "$exe" "$admissions" "$nrows" "$nnoncontrib"
}

N=0
if [ -n "$RECEIPT_FILE" ]; then
  [ -f "$RECEIPT_FILE" ] || refuse "no receipt at $RECEIPT_FILE"
  N=1
  check_receipt "$RECEIPT_FILE"
else
  [ -d "$DIR" ] || refuse "no receipt directory at $DIR. An absent store is not an empty one."
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    N=$((N+1))
    check_receipt "$f"
  done < <(find "$DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null | sort)
  [ "$N" -eq 0 ] && refuse "the sweep found 0 receipts under $DIR. A sweep over nothing certifies every escalation at once, so it refuses instead of passing."
fi

printf 'routing-check: %s receipt(s) checked, %s violation(s)\n' "$N" "$VIOL"
[ "$VIOL" -gt 0 ] && { printf 'routing-check: REFUSED — %s violation(s). The recorded verdict is binding; a contradiction between what was selected and what ran is a defect, not a detail.\n' "$VIOL" >&2; exit 2; }
exit 0
