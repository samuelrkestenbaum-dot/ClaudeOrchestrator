# Timeout calibration, attempt 1 — VOID

Not a slow run. A harness failure, and it surfaced a confound that would have
invalidated EXP-0005 measurements had it gone unnoticed.

## What was attempted

One Gravito-arm calibration session (`E1` workload, substrate ON: `.claude/`,
`CLAUDE.md` and `build-os/` all present) under a deliberately loose 5400 s
ceiling, measuring **elapsed only**. Workload is already-observed material, so
no EXP-0005 candidate task was burned.

## What happened

| | |
|---|---|
| session window | 11:32:06Z → 11:36:57Z (**~5 min**) |
| result event | **NONE** — the session never finished |
| parent script | died without writing a timing line |
| ceiling reached | **no** — 5400 s was never approached |
| processes at inspection | **none** |

The run was killed externally at ~11:37. It was **not** a timeout, and the
"180 minutes elapsed" reading taken later was wall-clock since launch, not
session duration — the session had already been dead for hours.

## Finding 1 — the calibration session shared THIS session's id

Every hook event in the child's stream carries
`session_id: 5489b495-ae3d-5612-a4e1-61b4b5c6b6e4` — **the id of the parent
session that launched it**. Its tool-result overflow was written under
`/root/.claude/projects/-tmp-…-cal-work/5489b495-…/`.

A measured arm that shares session identity with the orchestrating session is
not isolated. Session-scoped state — task lists, tool-result stores, and
whatever else keys on that id — is shared between measurer and measured. **This
must be fixed before any EXP-0005 arm executes**, and it is a plausible
contributor to the kill.

This is the same class as EXP-0004's task-list leak, which was noticed but
treated as benign because it was symmetric. It is not benign when the leaking
process is the one taking the measurement.

## Finding 2 — the routing gate fired, as designed

    routing-gate: MUTATION BLOCKED — Bash is mutation-capable and NO OPEN
    routing receipt exists under build-os/packets/routing/

That is the Gravito substrate behaving correctly: mutation is gated until a
routing receipt is issued. It is **treatment behaviour, not a defect**, and its
cost in turns and elapsed time is exactly what EXP-0005 exists to measure. It is
recorded here so that a later reading of the Gravito distribution is not
mistaken for the substrate being slow at *thinking* when it is being slow at
*being allowed to act*.

## What is NOT concluded

- **No timing conclusion.** One killed session establishes no distribution.
- **No comparison to native.** The native E1 figure of 849 s is not compared to
  anything here.
- **No product change.** Calibration observes the system; it does not optimise
  it, and nothing about the substrate was altered in response to this run.

## Required before attempt 2

1. **Session isolation** — each calibration and each EXP-0005 arm must run under
   its own session identity, verified from the child's own stream rather than
   assumed.
2. **Process durability** — the runner must survive independently of the
   launching shell, and must record a timing line even when the child dies.
3. **Explicit terminal-state capture** — a session with no result event is
   recorded as `is_error`, never as a completion with unknown duration.

Item 2 of the preregistration's fixture-hardening list already required
deterministic terminal-state validation. Item 1 is **new**, and is added to that
list.
