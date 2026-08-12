# TOM addition (operator-dictated during EXP-0009, 2026-08-11) — for the post-run commit

**Events drive work. Continuous execution state drives liveness. Timers do neither.**

Required invariants:

- `dependency_complete + authorized + runnable => launch immediately`
- `running + heartbeat/progress => continue`
- `running + no_progress + no_known_long_operation => diagnose/recover immediately`

There must be no hourly watchdog, no scheduled check-in, no fallback timer, no
wake-up whose purpose is to discover whether work is alive, and no clock-driven
authorization or continuation. A live PID is not evidence of progress; the
heartbeat is the work's own execution state (stream/file writes, active
tool/compiler processes, lock ownership, elapsed-vs-ceiling).

How this was learned, in order, all during EXP-0009:

1. Rep 2's start depended on a scheduled check-in → the supervisor
   (run-study.mjs) was built so completion events chain arms and reps with no
   clock involvement. ("Timers shouldn't drive work.")
2. 22 minutes of operator-visible silence while an arm was healthy → the
   continuous stall-watcher (stall-watch.sh) was built to classify
   PROGRESSING/STALLED from live execution evidence and to wake the
   orchestrator AT a stall, not at the next tick. ("Timers shouldn't be how
   stalls are discovered.")
3. The remaining hourly watchdog — kept as "fallback recovery only" — was
   recognized as the same defect in residue: part of the system's awareness
   still hung on a clock tick. The operator ordered it removed entirely; the
   armed trigger was cancelled mid-run. Container-restart recovery is also
   event-driven: the harness notifies the orchestrator when tracked background
   work dies, which is the wake signal for the preserve → verify-dead →
   clear-lock → exact-arm relaunch procedure.

This note is doctrine payload for build-os/design/TARGET-OPERATING-MODEL.md at
the post-study commit; it is recorded here because the study was mid-flight and
under a no-mid-run-commits instruction when the principle was dictated.
