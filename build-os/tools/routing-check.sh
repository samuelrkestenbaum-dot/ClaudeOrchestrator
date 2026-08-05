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
  printf 'routing-check: %s selected=%s executed=%s admissions=%s(admission fields, not zeros)\n' \
    "$f" "$sel" "$exe" "$admissions"
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
