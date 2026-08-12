# DISCLOSURE — mid-run orchestration intervention (rep 2)

**Stated plainly for the study record, per operator instruction: EXP-0009 had a
mid-run orchestration change. It is disclosed, timed, and bounded here — not
hidden, not blurred.**

## What changed, and when

At 2026-08-11T19:51:50Z, with rep 1 complete (20/20 admissible) and rep 2 at
23/40 total cells (A1 both configs and A2/leanmem admissible; A2/native rep 2
in flight), the orchestration layer was replaced live:

- **Retired:** `run-study.mjs` (chain-on-completion supervisor) and
  `stall-watch.sh` (60s polling liveness monitor).
- **Attached:** `executor.mjs` — a single event-processing state machine that
  consumes each arm's `stream.jsonl` via inotify, maintains per-event state,
  exposes real-time status, applies bounded per-state no-progress timeouts,
  and dispatches the next preregistered cell on completion events.
- The in-flight arm A2/native rep 2 (pid 17951) was **never touched**: the
  executor adopted it read-only mid-verification and took ownership only of
  transitions after it. (The executor was restarted once at 19:52:31Z for a
  status-display fix — a transition-label lookup; the arm was unaffected.)

Earlier orchestration-route changes in the same study, same boundary, also on
record: detached (`nohup`) driver → harness-tracked driver (route-switch-1510),
driver → supervisor (15:36Z), plus container-restart recoveries whose partial
arms are preserved as `*.container-restart-*` / `*.route-correction-*` dirs.

## Why this cannot affect treatment semantics (the isolation proof)

The treatment boundary is INSIDE `run-arm.mjs`, and every arm re-proves it
independently of what launched it:

1. **Same argv:** the executor spawns `run-arm.mjs --seq S --pos P --rep R
   --config C` — byte-identical to the retired driver's invocation.
2. **Administered bytes pinned:** each leanmem arm materializes the treatment
   from commit `a530659` via `git archive` and verifies content markers; each
   native arm verifies substrate absence. Recorded per arm in preflight.
3. **Prompt identity:** built from `sequences.json` alone; sha256 recorded per
   arm (`58b8ad83799f35e5` at A1 across all arms/reps/routes).
4. **Seed identity:** exact seed `2543c873…` restored and verified before every
   position, both arms, regardless of launcher.
5. **Memory / provenance / metrics / adjudication:** all inside `run-arm.mjs`
   and `distill.mjs`, untouched; the provenance gate re-checks every store
   install.
6. The executor holds no write path into the arm tree, the stores, or any run
   record; it decides transition timing only.

## Identity evidence to preserve with the report

- Per-arm `variant.json` (pin, resolved commit, administered sha, prompt sha)
  across all 40 cells — identical fields pre- and post-intervention.
- Preflight blocks in `driver-rep*.log` before and after 19:51Z — same gates,
  same results.
- `results/executor-log.txt` (attachment, adoption, dispatches) and
  `results/study-log.txt` (supervisor era) — the orchestration timeline.

Verdict criterion, stated in advance of the read: the intervention is benign
IF AND ONLY IF the per-arm identity evidence is uniform across the boundary.
If any post-19:51Z cell shows a differing administered hash, prompt sha, seed,
or grant set, that cell is quarantined and the deviation reported.

Operator constraint on this architecture, recorded: **the executor REPLACES
the observer stack — no watcher/controller may be layered on top of it.**
