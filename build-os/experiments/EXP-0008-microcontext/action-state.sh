#!/usr/bin/env bash
# EXP-0008 — ACTION STATE: the derived answer, never the implementation.
#
# THE MEASURED PROBLEM. Across 28 Gravito arms the worker read 31,000–49,000
# characters of Gravito's own implementation per arm, 33–45% of all its read
# volume. Native read ZERO. Half of it was one file: .claude/hooks/routing-gate.sh
# (95,574 chars in EXP-0006, 143,361 in EXP-0007 baseline).
#
# WHY. The gate refuses with a description of a CONDITION — "no open routing
# receipt exists" — and the worker then opens the gate to work out how to satisfy
# it. The refusal names a state; the worker needs an ACTION. It reads 47 KB of
# shell to derive one fact the gate already knows.
#
# WHAT THIS IS. The gate computes the next action itself and emits it. Same
# authority, same enforcement, same refusal — but the worker receives the answer
# instead of the source that produces it.
#
# WHAT THIS IS NOT — and the distinction is the whole experiment. Variant B in
# EXP-0007 replaced doctrine with a POINTER and let the worker fetch what it
# thought it needed. It produced the worst UIC of any configuration, a 1200s
# timeout on a task native solved in 122s, and a worker reading the gate source
# to reconstruct its own operating context. This emits NO paths to go and read,
# NO "see X for details", NO invitation to explore. Every fact needed to proceed
# is present in the payload, and nothing else is.
#
# Budget: ≤100 tokens. If it grows past that it has become documentation again.

set -uo pipefail
SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_GATE="${GRAVITO_REAL_GATE:-$SELF_DIR/routing-gate-real.sh}"
DATA_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
RDIR="$DATA_ROOT/build-os/packets/routing"

# Run the real gate. Its DECISION is authoritative and unchanged — this file
# never decides anything, it only re-expresses what the gate decided.
out="$("$REAL_GATE" "$@" 2>&1)"; rc=$?
[ $rc -eq 0 ] && { [ -n "$out" ] && printf '%s\n' "$out"; exit 0; }

# --- derive the facts the worker would otherwise go and read for -------------
tool="${2:-unknown}"
open_receipt=""
if [ -d "$RDIR" ]; then
  # An OPEN receipt is the newest whose executed_mode is still '-'.
  open_receipt="$(grep -l "executed_mode: -" "$RDIR"/*.md 2>/dev/null | tail -1)"
fi

reason="unknown"
case "$out" in
  *"NO OPEN routing receipt"*|*"no open routing receipt"*) reason="no_open_routing_receipt" ;;
  *"DEGRADED"*|*"degradation_note"*)                       reason="receipt_degraded" ;;
  *"silent escalation"*|*"escalation"*)                    reason="undeclared_escalation" ;;
  *"MUTATION BLOCKED"*)                                    reason="mutation_without_authority" ;;
esac

# The NEXT ACTION, computed here rather than looked up by the worker.
case "$reason" in
  no_open_routing_receipt|mutation_without_authority)
    next="create ${RDIR#$DATA_ROOT/}/routing-<slug>.md containing 'executed_mode: -'" ;;
  receipt_degraded)
    next="clear degradation_note in ${open_receipt#$DATA_ROOT/} or open a new receipt" ;;
  undeclared_escalation)
    next="record the escalation reason in ${open_receipt#$DATA_ROOT/} before retrying" ;;
  *)
    next="re-read the one-line reason above; no further state is required" ;;
esac

# ≤100 tokens, machine-shaped, and terminal: nothing here sends the worker
# anywhere to find out more.
{
  printf 'GRAVITO ACTION STATE\n'
  printf 'action: %s\n' "$tool"
  printf 'allowed: no\n'
  printf 'reason: %s\n' "$reason"
  printf 'next: %s\n' "$next"
  printf 'open_receipt: %s\n' "${open_receipt:+${open_receipt#$DATA_ROOT/}}${open_receipt:-none}"
  printf 'after_next: retry the same action; no other approval is required\n'
} >&2
exit $rc
