#!/usr/bin/env bash
# gravito.goal — the owner-facing contract validator and gate (PKT-R0-4).
#
# One file states: what to do, under what authority, within what budgets,
# judged how, stoppable when. This tool VALIDATES the schema, and GATES on
# expiry and budgets FAIL-CLOSED: an expired, malformed, or over-budget goal
# exits nonzero with the operator's next action named. It consumes the
# authority-envelope philosophy (half-open [starts, expires); no clock
# fallback) without granting anything itself.
#
#   goal-check.sh <file>            validate schema + window (exit 1 on any error)
#   goal-check.sh --status <file>   one-line budget/expiry status (never fails)
#   goal-check.sh --gate <file>     fail-closed gate: valid + live + within budgets
#
# Budgets compare against build-os/memory/spend-ledger.jsonl next to the goal
# (lines: {"tokens":N,"usd":N,"minutes":N}); absent ledger = zero spend. R0
# meters nothing itself — the ledger is written by wrappers that DO meter;
# the gate simply refuses when recorded spend exceeds contract budget.
set -u
MODE="validate"
case "${1:-}" in --status) MODE=status; shift ;; --gate) MODE=gate; shift ;; esac
F="${1:-}"; [ -n "$F" ] && [ -f "$F" ] || { echo "goal-check: no goal file: ${F:-<missing>}"; exit 1; }
DIR="$(cd "$(dirname "$F")" && pwd)"

get(){ awk -F': ' -v k="$1" '$1==k {sub(/^[^:]*: /,""); print; exit}' "$F"; }
ERR=0; err(){ echo "goal-check: INVALID — $1"; ERR=1; }

valid_date(){ case "$1" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) return 1 ;; esac
  local y="${1%%-*}" r="${1#*-}"; local m="${r%%-*}" d="${r#*-}" dim
  case "$m" in 01|03|05|07|08|10|12) dim=31 ;; 04|06|09|11) dim=30 ;;
    02) dim=28; [ $((y % 4)) -eq 0 ] && { [ $((y % 100)) -ne 0 ] || [ $((y % 400)) -eq 0 ]; } && dim=29 ;;
    *) return 1 ;; esac
  [ "${d#0}" -ge 1 ] && [ "${d#0}" -le "$dim" ]; }

REQ="goal repository authority allowed_actions prohibited_actions model_policy budget_tokens budget_minutes budget_usd acceptance intervention stop_conditions starts expires"
for k in $REQ; do [ -n "$(get "$k")" ] || err "required field missing: $k"; done
for k in budget_tokens budget_minutes; do v="$(get "$k")"; [ -z "$v" ] || case "$v" in ''|*[!0-9]*) err "$k must be a whole number, got '$v'" ;; esac; done
v="$(get budget_usd)"; [ -z "$v" ] || case "$v" in ''|*[!0-9.]*|*.*.*) err "budget_usd must be numeric, got '$v'" ;; esac
ST="$(get starts)"; EX="$(get expires)"
[ -z "$ST" ] || valid_date "$ST" || err "starts '$ST' is not a real YYYY-MM-DD date"
[ -z "$EX" ] || valid_date "$EX" || err "expires '$EX' is not a real YYYY-MM-DD date"
if [ -n "$ST" ] && [ -n "$EX" ] && valid_date "$ST" && valid_date "$EX"; then
  [ "$EX" \> "$ST" ] || err "expires ($EX) does not follow starts ($ST)"
fi
NOW="${BUILD_OS_NOW:-$(date -u +%F)}"
valid_date "$NOW" || { echo "goal-check: REFUSED — clock '$NOW' is not a real date; an unreadable clock never falls back"; exit 1; }

[ "$MODE" = "validate" ] && { [ "$ERR" -eq 0 ] && echo "goal-check: VALID ($F)"; exit "$ERR"; }
[ "$ERR" -ne 0 ] && { [ "$MODE" = "status" ] && { echo "goal: INVALID — run goal-check for details"; exit 0; } || exit 1; }

WINDOW="LIVE"
[ "$NOW" \< "$ST" ] && WINDOW="NOT-YET-LIVE"
{ [ "$EX" \< "$NOW" ] || [ "$EX" = "$NOW" ]; } && WINDOW="EXPIRED"

LEDGER="$DIR/build-os/memory/spend-ledger.jsonl"; [ -f "$LEDGER" ] || LEDGER="$(dirname "$DIR")/build-os/memory/spend-ledger.jsonl"
TOK=0; USD=0; MIN=0
if [ -f "$LEDGER" ]; then
  TOK="$(awk -F'"tokens":' 'NF>1{split($2,a,/[,}]/); s+=a[1]} END{printf "%d", s}' "$LEDGER")"
  MIN="$(awk -F'"minutes":' 'NF>1{split($2,a,/[,}]/); s+=a[1]} END{printf "%d", s}' "$LEDGER")"
  USD="$(awk -F'"usd":' 'NF>1{split($2,a,/[,}]/); s+=a[1]} END{printf "%.2f", s}' "$LEDGER")"
fi
OVER=""
[ "$TOK" -gt "$(get budget_tokens)" ] && OVER="${OVER}tokens($TOK>$(get budget_tokens)) "
[ "$MIN" -gt "$(get budget_minutes)" ] && OVER="${OVER}minutes($MIN>$(get budget_minutes)) "
awk -v u="$USD" -v b="$(get budget_usd)" 'BEGIN{exit !(u>b)}' && OVER="${OVER}usd($USD>$(get budget_usd)) "

if [ "$MODE" = "status" ]; then
  echo "goal window: $WINDOW ($ST → $EX, now $NOW) | spend: ${TOK}tok ${MIN}min \$${USD} of $(get budget_tokens)tok $(get budget_minutes)min \$$(get budget_usd)${OVER:+ | OVER-BUDGET: $OVER}"
  exit 0
fi
# gate — fail closed with the next action named
[ "$WINDOW" = "LIVE" ] || { echo "goal-check: HALT — goal window is $WINDOW. Next action: the owner re-issues gravito.goal with a live [starts, expires) window."; exit 2; }
[ -z "$OVER" ] || { echo "goal-check: HALT — budget exceeded: ${OVER}. Work stops at this safe boundary; state is durable. Next action: the owner raises the budget in gravito.goal or accepts the stop."; exit 3; }
echo "goal-check: GATE OPEN — window LIVE, within budgets (${TOK}tok ${MIN}min \$${USD})"
