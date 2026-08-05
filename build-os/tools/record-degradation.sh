#!/usr/bin/env bash
# Build OS — record-degradation.sh: stamp an HONEST Full->Light degradation
# onto an open routing receipt (PACKET-0053-live-enforcement).
#
# WHY. routing-check.sh already PASSES a budget breach that declares its
# degradation and REFUSES a concealed one — but EXP-0003 measured that ZERO
# degradation notes were written live, because writing one was pure protocol.
# This tool is the mechanical writer: the live gate invokes it when the fan-out
# throttle fires, and a model/operator invokes it deliberately when degrading
# by choice. Stop the expensive mode, not the task: a degradation is how a run
# CONTINUES honestly, not how it ends.
#
# WHAT IT WRITES, and nothing else:
#   1. The receipt's `degradation_note: -` line becomes
#        degradation_note: degraded_at=<UTC> downgraded_to=gravito_light reason=<text> preserved_evidence=<ptr|->
#      via a byte-surgical single-line replacement (staged file, verified, then
#      copied over — the receipt is otherwise untouched).
#   2. An append-only DEGRADATION row (with the same reason/pointer) into
#      build-os/packets/routing/live_state/<receipt-id>.tsv, creating the state
#      file with the shared label block if the gate has not created it yet.
#
# WHAT IT REFUSES (exit 2): a missing receipt; a file with no degradation_note
# field (not a routing receipt); an EMPTY reason (a degradation nobody can
# audit is a bypass); a receipt already degraded (one degradation record per
# receipt — a record is never overwritten; a second degradation is a second
# decision and belongs to the operator).
#
# Usage:
#   record-degradation.sh --receipt FILE --reason TEXT [--evidence TEXT]
# Exit: 0 stamped; 2 refused, nothing written.
# Censused: MUT-0012 / control routing.degradation_stamp (runtime execute,
# authority_mismatch declared — no class licenses execute).
set -uo pipefail

refuse(){ printf 'record-degradation: REFUSED — %s\n' "$*" >&2; exit 2; }

RECEIPT=""; REASON=""; EVIDENCE="-"
while [ $# -gt 0 ]; do
  case "$1" in
    --receipt)  [ $# -ge 2 ] || refuse "--receipt needs a value";  RECEIPT="$2"; shift 2 ;;
    --reason)   [ $# -ge 2 ] || refuse "--reason needs a value";   REASON="$2"; shift 2 ;;
    --evidence) [ $# -ge 2 ] || refuse "--evidence needs a value"; EVIDENCE="$2"; shift 2 ;;
    -h|--help)  sed -n '2,33p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done

[ -n "$RECEIPT" ] || refuse "no --receipt. A degradation that names no receipt degrades nothing."
[ -f "$RECEIPT" ] || refuse "no receipt at $RECEIPT"
[ -n "$REASON" ]  || refuse "empty --reason. A degradation nobody can audit is a bypass wearing a label."
grep -q '^degradation_note: ' "$RECEIPT" \
  || refuse "$RECEIPT carries no degradation_note field — it is not a routing receipt this tool may stamp."
grep -q '^degradation_note: -$' "$RECEIPT" \
  || refuse "$RECEIPT is already degraded ($(grep '^degradation_note: ' "$RECEIPT" | head -n1)). One degradation record per receipt; a record is never overwritten — a second degradation is a second decision and is the operator's."

# One line each, tabs/newlines flattened: the note must stay a single
# `field: value` line or the receipt stops parsing everywhere else.
REASON="$(printf '%s' "$REASON" | tr '\t\n' '  ')"
EVIDENCE="$(printf '%s' "$EVIDENCE" | tr '\t\n' '  ')"
STAMP_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
NOTE="degraded_at=$STAMP_AT downgraded_to=gravito_light reason=$REASON preserved_evidence=$EVIDENCE"

TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT
awk -v note="$NOTE" '
  $0 == "degradation_note: -" && !done { print "degradation_note: " note; done=1; next }
  { print }
' "$RECEIPT" > "$TMP" || refuse "staging the stamp failed; the receipt is untouched"
# The stamp is surgical: exactly one line may differ, and the line count holds.
[ "$(wc -l < "$TMP")" = "$(wc -l < "$RECEIPT")" ] || refuse "staged stamp changed the line count; the receipt is untouched"
grep -qF "degradation_note: $NOTE" "$TMP" || refuse "staged stamp did not land; the receipt is untouched"
cp "$TMP" "$RECEIPT" || refuse "writing the stamped receipt back failed"

# The append-only DEGRADATION row beside the counts the gate keeps. The label
# block below is BYTE-IDENTICAL to routing-gate.sh's write_labels — the suite
# diffs the two writers so they cannot drift apart.
SDIR="$(cd "$(dirname "$RECEIPT")" && pwd)/live_state"
SF="$SDIR/$(basename "$RECEIPT" .md).tsv"
mkdir -p "$SDIR"
if [ ! -f "$SF" ]; then
  ( set -C; { \
    printf '# live state for %s — append-only; counts are DERIVED by counting rows, never stored\n' "$(basename "$RECEIPT")"; \
    printf 'label\ttask_dispatches\tEXACT (hook-counted ALLOW decisions at PreToolUse, in sessions where the gate is loaded; attempts, not completions)\n'; \
    printf 'label\tprocess_dispatches\tEXACT (hook-counted; subagent_type in builder|qa|reviewer|archivist|build-orchestrator; attributed governance_process)\n'; \
    printf 'label\ttool_events\tEXACT (hook-counted PreToolUse events in sessions where the gate is loaded)\n'; \
    printf 'label\ttool_failures\tEXACT only where PostToolUse exposes success:false/is_error; otherwise unavailable — absence of a row is NOT evidence of success\n'; \
    printf 'label\telapsed_s\tEXACT (derived at read time: receipt issued_at vs now; never stored)\n'; \
    printf 'label\ttokens\tunavailable_live (close-time reconciliation via telemetry where headless; not hook-visible in interactive sessions)\n'; \
    printf 'label\tcost_usd\tunavailable_live (close-time reconciliation via telemetry where headless; not hook-visible in interactive sessions)\n'; \
    } > "$SF" ) 2>/dev/null || true
fi
printf '%s\tDEGRADATION\tdowngraded_to=gravito_light reason=%s preserved_evidence=%s\n' \
  "$STAMP_AT" "$REASON" "$EVIDENCE" >> "$SF"

printf 'record-degradation: stamped %s\n' "$RECEIPT"
printf 'record-degradation: state row appended to %s\n' "$SF"
exit 0
