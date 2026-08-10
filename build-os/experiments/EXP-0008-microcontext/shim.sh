# EXP-0008 ACTION STATE shim — PREPENDED INTO routing-gate.sh, not a new file.
#
# REPAIR 1 of 1. The first prototype was confounded by its own construction:
#   * it RENAMED the gate, creating routing-gate-real.sh — an implementation file
#     the baseline never had — and the worker read 8,090 chars of it;
#   * its `next` named a receipt file without its CONTENT, so the worker went to
#     route-task.sh (10,806 chars) and routing_contract.md (4,115) to find the
#     schema. A file the worker must fill in from somewhere else is a pointer.
#   * it read the tool name from $2, but the hook is invoked with one argv and
#     passes its payload on STDIN, so every payload said `action: unknown`.
# Together those were 23,011 of 35,825 measured implementation chars.
#
# This version introduces NO new file, points at NO implementation, and carries
# the complete text the worker needs. It re-enters the SAME file under a marker
# variable, so the real gate below still decides — authority is untouched.

if [ "${GRAVITO_ACTION_STATE_INNER:-}" != "1" ]; then
  _payload="$(cat)"
  _tool="$(printf '%s' "$_payload" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
  [ -n "$_tool" ] || _tool="unknown"
  _out="$(printf '%s' "$_payload" | GRAVITO_ACTION_STATE_INNER=1 bash "$0" "$@" 2>&1)"; _rc=$?
  if [ $_rc -eq 0 ]; then [ -n "$_out" ] && printf '%s\n' "$_out"; exit 0; fi

  _root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
  _open="$(grep -l 'executed_mode: -' "$_root"/build-os/packets/routing/*.md 2>/dev/null | tail -1)"
  case "$_out" in
    *"NO OPEN routing receipt"*|*"MUTATION BLOCKED"*) _reason="no_open_routing_receipt" ;;
    *"escalation"*)                                   _reason="undeclared_escalation" ;;
    *"DEGRADED"*|*"degradation_note"*)                _reason="receipt_degraded" ;;
    *)                                                _reason="refused" ;;
  esac

  {
    printf 'GRAVITO ACTION STATE\n'
    printf 'action: %s\n' "$_tool"
    printf 'allowed: no\n'
    printf 'reason: %s\n' "$_reason"
    if [ "$_reason" = "no_open_routing_receipt" ]; then
      # THE COMPLETE TEXT. Not a filename to fill in from a schema found
      # elsewhere — the exact bytes that satisfy the gate, inline.
      printf 'next: write this file, exactly, then retry:\n'
      printf 'path: build-os/packets/routing/routing-task.md\n'
      printf 'content:\n'
      printf '  task_id: task\n'
      printf '  selected_mode: direct\n'
      printf '  executed_mode: -\n'
    else
      printf 'next: %s\n' "$(printf '%s' "$_out" | head -1 | cut -c1-160)"
    fi
    printf 'open_receipt: %s\n' "${_open:-none}"
    printf 'after_next: retry the same action. Nothing else is required and no other file governs this.\n'
  } >&2
  exit $_rc
fi
