#!/usr/bin/env bash
# EXP-0009 STALL WATCHER — observability only. READ-ONLY by construction: it
# never writes into a run dir, never touches the lock, never launches work.
#
# WHY. A live PID is not evidence of progress. The heartbeat that already
# exists — files being written into the current arm's run dir, and the
# verification compiler in the process table — answers "is the worker making
# progress RIGHT NOW" continuously. This script turns that existing evidence
# into an EVENT: it exits (noisily) the moment the invariant
#   running_arm + no_recent_progress + no_known_long_operation
# fires, so the harness wakes the orchestrator AT the stall, not at the next
# clock tick. The hourly watchdog remains as fallback recovery only.
#
# Classification (also available one-shot via --once):
#   PROGRESSING — run-dir activity within the liveness bound, OR a known
#                 long-running operation (tsc verification, seed restore) is
#                 currently executing.
#   STALLED     — no run-dir write for STALL_S seconds AND no known long
#                 operation explains it, while the supervisor still runs.
# Exit codes: 0 study complete · 2 supervisor dead · 3 stalled
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUP_PID="${1:?usage: stall-watch.sh <supervisor-pid> [--once]}"
STALL_S=300          # bound: > tsc (~130s) and > any observed inter-event gap
POLL_S=60
LOG="$HERE/results/liveness-log.txt"
say() { echo "[liveness $(date -u +%H:%M:%S)] $*" | tee -a "$LOG"; }

newest_run_dir() { ls -td "$HERE"/results/runs/*/ 2>/dev/null | head -1; }
last_activity_age() { # seconds since newest write anywhere in the newest run dir
  local d; d="$(newest_run_dir)"; [ -z "$d" ] && { echo 999999; return; }
  local t; t=$(find "$d" -type f -printf '%T@\n' 2>/dev/null | sort -rn | head -1 | cut -d. -f1)
  [ -z "$t" ] && { echo 999999; return; }
  echo $(( $(date +%s) - t ))
}
long_op() { # a known long-running operation that legitimately quiets the run dir
  pgrep -f "tsc --noEmit" >/dev/null 2>&1 && { echo "tsc verification"; return; }
  pgrep -f "restore-seed.sh" >/dev/null 2>&1 && { echo "seed restore"; return; }
  echo ""
}
classify() {
  local age op arm
  age=$(last_activity_age); op=$(long_op); arm=$(basename "$(newest_run_dir)" 2>/dev/null)
  if [ -n "$op" ]; then echo "PROGRESSING arm=$arm last_write=${age}s long_op='$op'"; return 0; fi
  if [ "$age" -le "$STALL_S" ]; then echo "PROGRESSING arm=$arm last_write=${age}s"; return 0; fi
  echo "STALLED arm=$arm last_write=${age}s no long operation explains it"; return 1
}

if [ "${2:-}" = "--once" ]; then classify; exit $?; fi

say "watcher armed: supervisor=$SUP_PID stall_bound=${STALL_S}s poll=${POLL_S}s"
while true; do
  grep -q "STUDY COMPLETE" "$HERE/results/study-log.txt" 2>/dev/null && { say "study complete — watcher retiring"; exit 0; }
  kill -0 "$SUP_PID" 2>/dev/null || { say "SUPERVISOR DEAD (pid $SUP_PID) — waking orchestrator"; exit 2; }
  c=$(classify) || { say "$c — waking orchestrator"; exit 3; }
  sleep "$POLL_S"
done
