#!/usr/bin/env bash
# Build OS — route-task.sh: issues a ROUTING RECEIPT, one file per routing
# decision, under build-os/packets/routing/ (or --out DIR).
#
# WHY THIS EXISTS. EXP-0002's sealed records carry the executed defect this
# tool closes half of: buildos T5 ran Full ceremony (4 subagent dispatches,
# $4.80, 7.4M total tokens) while its own run record read
# `mode_selector_says: gravito_light`. The verdict existed and bound nothing,
# because nothing durable recorded "this is what was selected, these are the
# budgets, and here is where the executed mode must be reconciled". The receipt
# is that record. build-os/tools/routing-check.sh is the close-time gate that
# refuses a receipt whose executed_mode exceeds its selected_mode with no
# escalation record. Contract: build-os/memory/routing_contract.md.
#
# THE BUDGETS ARE DERIVED DEFAULTS, NOT LAWS — operator-tunable, derived from
# EXP-0002's sealed run records and stated with their derivation:
#   * Light-appropriate tasks measured ~170k-370k TOTAL tokens and 0 subagent
#     dispatches (both arms' T1/T2/T4; raw arm throughout).
#   * The two blowouts measured 4.9M (T3) and 7.4M (T5) total tokens, 5 and 4
#     dispatches, $3.63 and $4.80, ~849s and ~1013s wall clock.
#   Full defaults sit between the two bands — generous against the light band,
#   a hard ceiling well under the blowouts:
#     max_subagents 3 (blowouts dispatched 4-5), max_total_tokens 2,000,000
#     (blowouts 4.9M/7.4M), max_uncached_tokens 120,000, max_model_calls 40,
#     max_wall_clock_s 900, max_cost_usd 1.50 (blowouts $3.63/$4.80).
#   Light defaults bound the measured light band with headroom (~370k max
#   observed -> 500k), and direct is half of light again. Every number here is
#   a DERIVED DEFAULT an operator may retune; none is a claim of optimality.
#
# Usage:
#   route-task.sh --task-id ID --description TEXT --descriptor JSON [--out DIR]
#
#   ID          [A-Za-z0-9._-]+ — becomes part of the receipt file name.
#   TEXT        free text; only its sha256 is recorded (the receipt must not
#               become a second copy of the task prompt).
#   JSON        the full 13-field descriptor mode-select.mjs requires.
#
# Output: the receipt path and the selected mode on stdout.
# Exit: 0 with a receipt written; 2 on malformed input, a selector refusal, or
# a pre-existing receipt file (one file per decision — never overwrite).
# Writes EXACTLY ONE file, in the caller-named directory, and nothing else.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"
MODE_SELECT="$SELF_DIR/mode-select.mjs"

refuse(){ printf 'route-task: REFUSED — %s\n' "$*" >&2; exit 2; }

TASK_ID=""; DESCRIPTION=""; DESCRIPTOR=""; OUT_DIR="$REPO/build-os/packets/routing"
while [ $# -gt 0 ]; do
  case "$1" in
    --task-id)     [ $# -ge 2 ] || refuse "--task-id needs a value";     TASK_ID="$2"; shift 2 ;;
    --description) [ $# -ge 2 ] || refuse "--description needs a value"; DESCRIPTION="$2"; shift 2 ;;
    --descriptor)  [ $# -ge 2 ] || refuse "--descriptor needs a value";  DESCRIPTOR="$2"; shift 2 ;;
    --out)         [ $# -ge 2 ] || refuse "--out needs a value";         OUT_DIR="$2"; shift 2 ;;
    -h|--help)     sed -n '2,45p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done

[ -n "$TASK_ID" ]     || refuse "no --task-id. A receipt that identifies no task reconciles nothing."
case "$TASK_ID" in
  *[!A-Za-z0-9._-]*) refuse "task id \"$TASK_ID\" carries characters outside [A-Za-z0-9._-]. The id becomes a file name; a path-shaped id is a write outside the receipt store." ;;
esac
[ -n "$DESCRIPTION" ] || refuse "no --description. The description hash is what binds the receipt to the task that was actually routed."
[ -n "$DESCRIPTOR" ]  || refuse "no --descriptor. A routing decision without its descriptor is a verdict nobody can re-derive."
[ -f "$MODE_SELECT" ] || refuse "no selector at $MODE_SELECT"
command -v node >/dev/null 2>&1 || refuse "node is not available, and the selector is not re-implemented here — two implementations of one rule is how they diverge"

# The verdict comes from the ONE selector, never re-derived here. Its stderr
# (the withheld-Full note) is captured into the receipt: a downgrade that is
# printed once and scrolls away is a downgrade nobody audits.
NOTE_FILE="$(mktemp)"; trap 'rm -f "$NOTE_FILE"' EXIT
if ! SELECTED="$(node "$MODE_SELECT" "$DESCRIPTOR" 2>"$NOTE_FILE")"; then
  sed 's/^/route-task: /' "$NOTE_FILE" >&2
  refuse "the selector refused the descriptor (above). A receipt is never issued on a guessed mode."
fi
SELECTED="$(printf '%s' "$SELECTED" | tr -d '[:space:]')"
case "$SELECTED" in direct|gravito_light|gravito_full) ;; *) refuse "the selector returned \"$SELECTED\", which is not a mode this tool issues receipts for" ;; esac
SELECTOR_NOTE="$(tr '\n' ' ' < "$NOTE_FILE" | sed 's/[[:space:]]*$//')"
[ -n "$SELECTOR_NOTE" ] || SELECTOR_NOTE="-"

# Per-mode budgets — DERIVED DEFAULTS (derivation in the header), not laws.
case "$SELECTED" in
  gravito_full)
    B_SUB=3;  B_TOT=2000000; B_UNC=120000; B_CALLS=40; B_WALL=900; B_COST="1.50" ;;
  gravito_light)
    B_SUB=0;  B_TOT=500000;  B_UNC=60000;  B_CALLS=25; B_WALL=600; B_COST="0.75" ;;
  direct)
    B_SUB=0;  B_TOT=250000;  B_UNC=30000;  B_CALLS=12; B_WALL=300; B_COST="0.40" ;;
esac

DESC_SHA="$(printf '%s' "$DESCRIPTION" | sha256sum | awk '{print $1}')"
ISSUED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"

mkdir -p -- "$OUT_DIR" 2>/dev/null || refuse "cannot create receipt directory $OUT_DIR"
RECEIPT="$OUT_DIR/routing-$TASK_ID-$STAMP.md"
[ -e "$RECEIPT" ] && refuse "a receipt already exists at $RECEIPT. One file per routing decision; a receipt is never overwritten — a second decision about the same task is a second receipt."

DESCRIPTOR_ONELINE="$(printf '%s' "$DESCRIPTOR" | tr '\n' ' ')"

{
  printf '# ROUTING RECEIPT — one file per routing decision. The recorded verdict is BINDING\n'
  printf '# (build-os/memory/routing_contract.md); routing-check.sh refuses this receipt at\n'
  printf '# close if executed_mode exceeds selected_mode with no escalation record, if an\n'
  printf '# escalation carries no evidence, or if consumption exceeds a budget undeclared.\n'
  printf 'task_id: %s\n' "$TASK_ID"
  printf 'description_sha256: %s\n' "$DESC_SHA"
  printf 'descriptor: %s\n' "$DESCRIPTOR_ONELINE"
  printf 'selected_mode: %s\n' "$SELECTED"
  printf 'selector_note: %s\n' "$SELECTOR_NOTE"
  printf 'issued_at: %s\n' "$ISSUED_AT"
  printf '# --- budgets: DERIVED DEFAULTS from EXP-0002 sealed records, operator-tunable, not laws.\n'
  printf '# --- Derivation: light tasks measured 170k-370k total tokens / 0 dispatches; the\n'
  printf '# --- blowouts measured 4.9M/7.4M tokens, 4-5 dispatches, $3.63/$4.80. See route-task.sh.\n'
  printf 'budget_max_subagents: %s\n' "$B_SUB"
  printf 'budget_max_total_tokens: %s\n' "$B_TOT"
  printf 'budget_max_uncached_tokens: %s\n' "$B_UNC"
  printf 'budget_max_model_calls: %s\n' "$B_CALLS"
  printf 'budget_max_wall_clock_s: %s\n' "$B_WALL"
  printf 'budget_max_cost_usd: %s\n' "$B_COST"
  printf '# --- empty at issue; filled at close. AN UNKNOWN IS NOT A ZERO: "-" is an honest\n'
  printf '# --- admission and is never refused; refusal is for CONTRADICTION, not absence.\n'
  printf 'executed_mode: -\n'
  printf 'escalation: -\n'
  printf 'escalation_evidence: -\n'
  printf 'consumed_subagents: -\n'
  printf 'consumed_total_tokens: -\n'
  printf 'consumed_uncached_tokens: -\n'
  printf 'consumed_model_calls: -\n'
  printf 'consumed_wall_clock_s: -\n'
  printf 'consumed_cost_usd: -\n'
  printf 'degradation_note: -\n'
} > "$RECEIPT"

printf 'route-task: receipt %s\n' "$RECEIPT"
printf 'route-task: selected_mode %s\n' "$SELECTED"
exit 0
