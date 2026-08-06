# PILOT-0002 — Clean-window repeat pilot — FREEZE (prepared BEFORE the window)

Classification: Internal external-style real-repository pilot, repeat run.
PURPOSE (operator's ruling): improve ONLY the measurement — same pilot
mechanics as PILOT-0001, no new architecture, no manufactured work. The
question: how much useful, accepted, governed product work per point of
real weekly usage, measured with a CLEAN window.

## Clean-window protocol (binding)

1. Operator's meter reading arrives (post-reset, ~4:00 PM ET Aug 6) —
   recorded verbatim, committed, THEN T1 starts immediately.
2. Five tasks run back-to-back with NO report-writing, NO side
   conversation, NO correction exchanges inside the window. Per-task
   bookkeeping is limited to receipt issue/close-fill and the pilot
   commits themselves; the measurement log is written AFTER the window.
3. Immediately after T5's final commit: request the after-reading in ONE
   short message (the only inside-window operator message permitted).
4. Report only after the second reading arrives.

## Execution mechanics — unchanged from PILOT-0001 by design

Same repo (empathiq-website), same pilot branch lineage (new branch
pilot/PILOT-0002-clean-window from the current pilot/install tip 93f75ea),
cross-repo routing from ClaudeOrchestrator (receipts = evidence), depths
selector-chosen on honest descriptors, no forced balance, Full only if a
value factor earns it. Hook enforcement inside the pilot repo exists now
(installed at 93f75ea) but THIS orchestrating session predates the wiring
and remains protocol-governed — same honest bound as PILOT-0001, restated.
Model claude-fable-5. No push without explicit scoped go. cb2bb7d
untouched, as always.

## The five frozen tasks (real, from PILOT-0001's T1 classification of
## the 778 remaining baseline errors and known test-design defects)

- **T1 — trpc client drift cluster.** Fix the 6 "Property 'bridge' does
  not exist... Did you mean 'bridges'?" errors (client-side trpc namespace
  drift). Acceptance: those 6 gone, total strictly < 778, zero new errors
  (sorted-diff proof), touched client pages still typecheck.
- **T2 — CoverageReportData drift.** Fix the 6 "Property 'coverage' does
  not exist on type 'CoverageReportData'" errors. Acceptance: same
  strict-decrease + zero-new pattern; any test touching the coverage
  surface stays at its measured baseline.
- **T3 — agents hermetic tests.** Fix the test-design defect from
  PILOT-0001's T1 classification: the 3 agents structure tests that fail
  on live-LLM 401 become hermetic (mock the LLM boundary), and the
  it.skip'd daily-report test (agents.test.ts:208) is un-skipped and made
  deterministic. Acceptance: agents.test.ts fully green 3 consecutive
  runs, no live-network dependency remains in it, assertions not weakened.
- **T4 — training/router interface conflict.** Fix the real drift:
  IAutoRetrainingPipeline incorrectly extends AutoRetrainingPipeline
  (private config + Promise-shape mismatch, 2 errors + the TS2352 cast).
  Acceptance: those errors gone, strict decrease, zero new, no any-casts.
- **T5 — fresh-context follow-up (depends on T1–T4).** A fresh-context
  agent, durable artifacts only (this FREEZE + the PILOT-0002 measurement
  notes + PILOT-0001 T1_DIAGNOSIS), fixes the voice-stream-gateway
  LogDomain error and the webhooks/router unknown-narrowing pair (3
  errors total) consistently with whatever conventions T1–T4 established.
  Acceptance: strict decrease, zero new, routes FIRST, reports whether
  the durable context sufficed. Per PILOT-0001's named gap: this freeze
  RECORDS baseline suite states the acceptance clauses reference —
  captured at window open in a BASELINE.md alongside this file.

## Measurements — identical schema to PILOT-0001, tier-labeled

selected/executed mode, routing evidence, context injected, parent calls,
subagents (tokens EXACT where harness-reported), tool events/failures,
elapsed EXACT, tokens/cost tier-labeled (parent UNAVAILABLE live), human
interventions, test/acceptance results, rework, governor events, budget
breaches with notes. Headline: durable accepted output per percentage
point of weekly meter movement (operator-read, verbatim, both ends).

## Settings frozen

Model claude-fable-5; permissions unchanged; time targets 30/60/60/45/45
min; the window contains ONLY task execution and receipts.
