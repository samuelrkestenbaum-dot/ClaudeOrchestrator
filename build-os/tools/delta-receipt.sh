#!/usr/bin/env bash
# Zone 7 — prediction-error evidence. TWO immutable append-only streams:
#
#   predictions.jsonl  — OPTIONAL pre-action predictions: outcome variable,
#                        predicted value, made_at, evidence scale, provenance,
#                        prediction id. A prediction is a FORECAST someone
#                        actually made before the outcome — it is NEVER
#                        manufactured from a goal or acceptance criterion
#                        (a success criterion defines what counts as
#                        acceptable; it is not yhat).
#   deltas.jsonl       — post-run observations (hash-chained). delta is
#                        computed ONLY when a referenced prediction exists,
#                        was made BEFORE the observation, and its outcome
#                        variable matches (commensurable). Otherwise:
#                        prediction_status=NOT_RECORDED|POST_HOC|INCOMPARABLE
#                        and delta=UNDEFINED. Boolean acceptance is recorded
#                        as its own observation, separate from prediction
#                        error. History is never rewritten; a mismatch with
#                        no alternative explanation is refused.
#
# Canonical caller: bin/gravito cmd_review (observe); predictions are made
# by the operator/harness via `predict` BEFORE running.
#
#   delta-receipt.sh predict DIR --var V --value P [--scale S] [--by WHO]
#         -> prints prediction id (pred-...)
#   delta-receipt.sh observe DIR --var V --observed O --evidence E \
#         [--prediction-id ID] [--observed-at RFC3339] [--alternative A] \
#         [--scale S] [--consequence C]
#   delta-receipt.sh verify DIR
set -u
MODE="${1:-}"; D="${2:-}"; shift 2 2>/dev/null || { echo "usage: delta-receipt.sh predict|observe|verify DIR ..."; exit 1; }
D="$(cd "$D" && pwd)" || exit 1
PF="$D/build-os/receipts/predictions.jsonl"
F="$D/build-os/receipts/deltas.jsonl"
jesc(){ printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }
chain_prev(){ [ -s "$1" ] && tail -1 "$1" | python3 -c 'import json,sys,hashlib; print(hashlib.sha256(sys.stdin.read().rstrip("\n").encode()).hexdigest())' 2>/dev/null || echo genesis; }
SCALES="event|arm|task|sequence|experiment|subsystem|program"

case "$MODE" in
predict)
  VAR="" VAL="" SCALE="task" BY="operator"
  while [ $# -gt 0 ]; do case "$1" in
    --var) VAR="$2"; shift 2 ;; --value) VAL="$2"; shift 2 ;;
    --scale) SCALE="$2"; shift 2 ;; --by) BY="$2"; shift 2 ;;
    *) echo "predict: unknown arg $1"; exit 1 ;; esac; done
  [ -n "$VAR" ] && [ -n "$VAL" ] || { echo "predict: --var and --value required"; exit 1; }
  echo "$SCALE" | grep -qE "^($SCALES)$" || { echo "predict: bad scale"; exit 1; }
  mkdir -p "$(dirname "$PF")"
  exec 9>>"$PF.lock"; flock 9
  ID="pred-$(date -u +%Y%m%dT%H%M%SZ)-$$-$RANDOM"
  printf '{"id":"%s","made_at":"%s","outcome_var":%s,"predicted":%s,"evidence_scale":"%s","provenance":%s,"prev_sha":"%s"}\n' \
    "$ID" "$(date -u +%FT%TZ)" "$(jesc "$VAR")" "$(jesc "$VAL")" "$SCALE" "$(jesc "$BY")" "$(chain_prev "$PF")" >> "$PF"
  echo "$ID"
  ;;
observe)
  VAR="" OBS="" EVID="" PID="" OAT="" ALT="" SCALE="task" CONS="none"
  while [ $# -gt 0 ]; do case "$1" in
    --var) VAR="$2"; shift 2 ;; --observed) OBS="$2"; shift 2 ;;
    --evidence) EVID="$2"; shift 2 ;; --prediction-id) PID="$2"; shift 2 ;;
    --observed-at) OAT="$2"; shift 2 ;; --alternative) ALT="$2"; shift 2 ;;
    --scale) SCALE="$2"; shift 2 ;; --consequence) CONS="$2"; shift 2 ;;
    *) echo "observe: unknown arg $1"; exit 1 ;; esac; done
  [ -n "$VAR" ] && [ -n "$OBS" ] || { echo "observe: --var and --observed required"; exit 1; }
  echo "$SCALE" | grep -qE "^($SCALES)$" || { echo "observe: bad scale"; exit 1; }
  case "$CONS" in none|confidence|selection-weight|threshold|routing) ;; *) echo "observe: bad consequence"; exit 1 ;; esac
  OAT="${OAT:-$(date -u +%FT%TZ)}"
  PSTAT="NOT_RECORDED"; PRED="null"; DELTA="\"UNDEFINED\""
  if [ -n "$PID" ]; then
    ROW="$(grep -F "\"id\":\"$PID\"" "$PF" 2>/dev/null | head -1 || true)"
    if [ -z "$ROW" ]; then
      echo "observe: REFUSED — prediction id $PID not found; a prediction is never invented"; exit 1
    fi
    PVAR="$(printf '%s' "$ROW" | python3 -c 'import json,sys;print(json.load(sys.stdin)["outcome_var"])')"
    PVAL="$(printf '%s' "$ROW" | python3 -c 'import json,sys;print(json.load(sys.stdin)["predicted"])')"
    MADE="$(printf '%s' "$ROW" | python3 -c 'import json,sys;print(json.load(sys.stdin)["made_at"])')"
    if [ "$(printf '%s\n%s\n' "$MADE" "$OAT" | sort | head -1)" != "$MADE" ]; then
      PSTAT="POST_HOC"   # made after the observation moment: not a forecast
    elif [ "$PVAR" != "$VAR" ]; then
      PSTAT="INCOMPARABLE"
    else
      PSTAT="MATCHED"; PRED="$(jesc "$PVAL")"
      if [ "$PVAL" = "$OBS" ]; then DELTA="0"
      else
        DELTA="\"MISMATCH\""
        [ -n "$ALT" ] || { echo "observe: REFUSED — a mismatch requires --alternative (an unexplained surprise is not evidence yet)"; exit 1; }
      fi
    fi
  fi
  mkdir -p "$(dirname "$F")"
  exec 8>>"$F.lock"; flock 8
  printf '{"at":"%s","observed_at":"%s","outcome_var":%s,"observed":%s,"prediction_id":%s,"prediction_status":"%s","predicted":%s,"delta":%s,"acceptance_evidence":%s,"alternative_explanation":%s,"evidence_scale":"%s","allowed_consequence":"%s","prev_sha":"%s"}\n' \
    "$(date -u +%FT%TZ)" "$OAT" "$(jesc "$VAR")" "$(jesc "$OBS")" "$( [ -n "$PID" ] && jesc "$PID" || echo null )" "$PSTAT" "$PRED" "$DELTA" "$(jesc "$EVID")" "$(jesc "${ALT:-n/a}")" "$SCALE" "$CONS" "$(chain_prev "$F")" >> "$F"
  echo "delta: observed (prediction_status=$PSTAT, delta=$(echo $DELTA | tr -d '"'))"
  ;;
verify)
  RC=0
  for S in "$PF" "$F"; do
    [ -f "$S" ] || continue
    python3 - "$S" <<'PY' || RC=1
import hashlib, json, sys
prev = "genesis"; n = 0; torn = 0
for raw in open(sys.argv[1]):
    raw = raw.rstrip("\n")
    try: d = json.loads(raw)
    except Exception: torn += 1; continue
    if d.get("prev_sha") != prev:
        print(f"{sys.argv[1].split('/')[-1]}: TAMPER/REORDER at line {n+1}"); sys.exit(1)
    prev = hashlib.sha256(raw.encode()).hexdigest(); n += 1
print(f"{sys.argv[1].split('/')[-1]}: chain intact — {n} receipt(s)" + (f", {torn} torn line(s) detected" if torn else ""))
sys.exit(1 if torn else 0)
PY
  done
  [ -f "$PF" ] || [ -f "$F" ] || echo "delta: no streams (nothing to verify)"
  exit $RC
  ;;
*) echo "usage: delta-receipt.sh predict|observe|verify DIR ..."; exit 1 ;;
esac
