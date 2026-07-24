#!/usr/bin/env bash
# Build OS — zero-touch specialist orchestration (P-014).
#
# Inspects a build request and, only when a DISABLED specialist profile (ECC or
# zeroization) is required, performs an automatic bounded handoff:
#   (1) preserve the exact original task + working directory,
#   (2) activate ONLY the required profile,
#   (3) launch a fresh non-interactive Claude Code child session with that task,
#   (4) wait for + surface its result and exit status (never silently "succeed"),
#   (5) restore focused mode afterward — even on failure, timeout, or interruption.
#
# Guards: recursion (BUILD_OS_SPECIALIST_HANDOFF env), one profile at a time (ECC and
# zeroize are mutually exclusive by construction), one Serena (capability-profile.sh),
# and a hard timeout. Focused tasks incur NO relaunch.
#
# Subcommands:
#   classify "<prompt>"          -> print route: focused | ecc | zeroize
#   detect   "<prompt>" [cwd]    -> auto: no-op for focused; handoff for ecc/zeroize
#   --dry-run|status "<prompt>"  -> classify + report the plan; NO relaunch, NO switch
#
# Env overrides (tests + host): CLAUDE_BIN (default claude), CAPABILITY_PROFILE_BIN
# (default sibling capability-profile.sh), HANDOFF_TIMEOUT (default 900s), HANDOFF_LOG
# (default ~/.claude/build-os-handoffs.log), CLAUDE_USER_DIR / CLAUDE_CONFIG_PATH (passed
# through to the profile switcher), BUILD_OS_SPECIALIST_HANDOFF (recursion guard).
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
CAPABILITY_PROFILE_BIN="${CAPABILITY_PROFILE_BIN:-$HERE/capability-profile.sh}"
HANDOFF_TIMEOUT="${HANDOFF_TIMEOUT:-900}"
HANDOFF_LOG="${HANDOFF_LOG:-$HOME/.claude/build-os-handoffs.log}"

log_line() {
  mkdir -p "$(dirname "$HANDOFF_LOG")" 2>/dev/null || true
  printf '%s\t%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || echo now)" "$1" >> "$HANDOFF_LOG" 2>/dev/null || true
}

# Deterministic route classification. Precedence zeroize > ecc > focused, so a request
# never selects both specialists. Portable ERE (no GNU-only \b).
classify() {
  local p; p="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
  if printf '%s' "$p" | grep -qE 'zeroiz|scrub.*secret|wipe.*(secret|key).*memor'; then echo zeroize; return 0; fi
  if printf '%s' "$p" | grep -qE '(^|[^a-z])ecc([^a-z]|$)|elliptic[ -]?curve|ecdsa|ed25519|secp256|curve25519|chrome ?devtools'; then echo ecc; return 0; fi
  echo focused
}

# run_with_timeout SECS CMD...  -> 124 on timeout. Portable (timeout / gtimeout / perl).
run_with_timeout() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then timeout "$secs" "$@"; return $?
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout "$secs" "$@"; return $?
  else
    perl -e '
      my $s=shift; my $pid=fork;
      if(!defined $pid){exit 127}
      if($pid==0){ exec @ARGV; exit 127; }
      local $SIG{ALRM}=sub{ kill "TERM",$pid; sleep 1; kill "KILL",$pid; exit 124; };
      alarm $s; waitpid($pid,0); exit($? >> 8);
    ' "$secs" "$@"; return $?
  fi
}

activate_profile() { "$CAPABILITY_PROFILE_BIN" "$1" >/dev/null 2>&1; }
restore_focused()  { activate_profile focused || true; }

# handoff ROUTE PROMPT CWD
handoff() {
  local route="$1" prompt="$2" cwd="${3:-$PWD}" out ec
  # (5) ALWAYS restore focused — even on failure / interruption.
  trap 'restore_focused' EXIT INT TERM
  # (2) activate ONLY the required profile.
  if ! activate_profile "$route"; then
    echo "[specialist-handoff] ERROR: could not activate '$route' profile; staying focused." >&2
    log_line "route=$route ACTIVATE_FAILED cwd=$cwd"
    return 3
  fi
  echo "[specialist-handoff] route=$route — launching a fresh non-interactive Claude child (timeout ${HANDOFF_TIMEOUT}s)."
  # (3)+(4) launch the child with the exact task + bounded context, in the original cwd,
  # with the recursion guard set; capture output + exit status.
  out="$( cd "$cwd" 2>/dev/null && run_with_timeout "$HANDOFF_TIMEOUT" \
          env "BUILD_OS_SPECIALIST_HANDOFF=$route" "$CLAUDE_BIN" -p "$prompt" 2>&1 )"
  ec=$?
  printf '%s\n' "$out"
  # Never silently claim success — always report the child's exit status.
  if [ "$ec" -eq 0 ]; then
    echo "[specialist-handoff] RESULT: OK (route=$route, child exit=0). Focused mode restored."
  elif [ "$ec" -eq 124 ]; then
    echo "[specialist-handoff] RESULT: TIMEOUT after ${HANDOFF_TIMEOUT}s (route=$route). Child killed; focused mode restored. Re-run via /capability-profile $route if still needed." >&2
  else
    echo "[specialist-handoff] RESULT: FAILED (route=$route, child exit=$ec). Focused mode restored. Inspect the output above; re-run via /capability-profile $route if needed." >&2
  fi
  log_line "route=$route exit=$ec cwd=$cwd prompt=$(printf '%s' "$prompt" | cut -c1-120)"
  return "$ec"
}

main() {
  local cmd="${1:-status}"
  case "$cmd" in
    classify) classify "${2:-}"; return 0 ;;
    --dry-run|dry-run|status)
      local route; route="$(classify "${2:-}")"
      if [ "$route" = "focused" ]; then
        echo "[specialist-handoff] dry-run: route=focused — no relaunch; the current session handles it."
      else
        echo "[specialist-handoff] dry-run: route=$route — WOULD hand off to a fresh '$route' child, then restore focused. (no changes made)"
      fi
      return 0 ;;
    detect)
      local prompt="${2:-}" cwd="${3:-$PWD}" route
      # Recursion guard: if we are already inside a specialist child, never hand off again.
      [ -n "${BUILD_OS_SPECIALIST_HANDOFF:-}" ] && return 0
      route="$(classify "$prompt")"
      [ "$route" = "focused" ] && return 0   # focused: no relaunch
      handoff "$route" "$prompt" "$cwd"; return $? ;;
    *)
      echo "Usage: $0 {classify|detect|--dry-run|status} \"<prompt>\" [cwd]" >&2
      return 2 ;;
  esac
}

main "$@"
