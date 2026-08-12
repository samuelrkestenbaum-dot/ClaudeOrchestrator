# TOM addition 2 (operator-dictated during EXP-0009, 2026-08-11) — REQUIRED post-study runtime change

**Event-driven sequencing is not enough. Gravito itself must be an active
event-processing runtime — a kernel advancing process state, not a foreman
watching workers.**

The current shape (supervisor chains on completion; a 60s stall-watcher polls
liveness) removed timers from scheduling but is still OBSERVER architecture:

    work runs → watcher checks periodically → maybe reacts

The target is an active operating loop that continuously owns the next action:

    event arrives → state changes → Gravito decides next transition → action dispatches

One executor/state machine (collapsing supervisor + stall-watcher) that:

- dispatches the current unit of work;
- consumes model/tool/process events AS THEY HAPPEN (subscribe where possible —
  e.g. tail the arm's stream.jsonl as an event source — never 60s polls);
- updates durable state immediately on each event;
- knows the current operation, and the next valid transition, at all times;
- detects no-progress from event flow, recovers or continues;
- dispatches the next action immediately.

It must visibly expose, in real time:

    Current state:        B3/leanmem → verifying
    Current action:       tsc --noEmit
    Last meaningful event: 4.2s ago
    Next transition:      verification_pass → distill memory → launch B4/native
    Blocked on:           nothing

Time's ONE legitimate role: a bounded timeout attached to an active state
("this tool call exceeded its permitted no-progress interval"). Time is never a
scheduler and never the primary source of awareness.

Status: REQUIRED post-EXP-0009 runtime change, per operator — not optional
cleanup. Explicitly NOT built mid-run: touching the orchestration while rep 2
executes would contaminate the study. Build after the D3 read closes.
