#!/usr/bin/env bash
# Atomic per-event guard for hooks registered at both user and project scope.

build_os_hook_once() {
  local event="${1:?event required}" payload identifiers session_id prompt_id key base
  payload="$(cat 2>/dev/null || true)"
  [ -n "$payload" ] || return 0

  identifiers="$(
    printf '%s' "$payload" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
except Exception:
    raise SystemExit(0)
print(data.get("session_id", ""))
print(data.get("prompt_id", ""))
' 2>/dev/null
  )"
  session_id="$(printf '%s\n' "$identifiers" | sed -n '1p')"
  prompt_id="$(printf '%s\n' "$identifiers" | sed -n '2p')"
  [ -n "$session_id" ] || return 0

  key="${event}-${session_id}"
  [ -n "$prompt_id" ] && key="${key}-${prompt_id}"
  key="$(printf '%s' "$key" | tr -cd 'A-Za-z0-9._-')"
  [ -n "$key" ] || return 0

  base="${TMPDIR:-/tmp}/build-os-hook-once"
  mkdir -p "$base"
  mkdir "$base/$key" 2>/dev/null
}
