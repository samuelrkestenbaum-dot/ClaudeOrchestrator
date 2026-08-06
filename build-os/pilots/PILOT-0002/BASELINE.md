# PILOT-0002 — baseline states, captured at window open

Seed 93f75ea, branch pilot/PILOT-0002-clean-window. Captured AFTER the
before-reading and BEFORE T1, per PILOT-0001's named gap (its acceptance
clauses referenced suite states nobody had recorded).

## tsc (`pnpm run check:app`)

Total: **778 errors** — identical to PILOT-0001's closing count.

Per frozen task, exact target counts:
- T1 trpc drift: **6** `Property 'bridge' does not exist ... Did you mean 'bridges'?`
  (client/src/pages/Transparency.tsx:51,60; admin/OperatorIntegrityConsole.tsx:70,...)
  NOTE: the string "bridge" appears on 24 baseline lines; only these 6 are
  the T1 cluster. Acceptance is against the 6, not the 24.
- T2 coverage drift: **6** `Property 'coverage' does not exist on type 'CoverageReportData'`
  (of 10 lines mentioning CoverageReportData)
- T4 training/router: **2** — TS2430 interface-extends conflict at :7,
  TS2352 unsafe cast at :34
- T5 voice-stream + webhooks: **3** — LogDomain TS2345 at
  voice-stream-gateway.ts:33; TS2571 and TS2339 at webhooks/router.ts:132,133

## Test suites referenced by acceptance clauses

- T3's target file `server/agents/agents.test.ts`: baseline recorded at
  PILOT-0001 T1 as 17 tests, 3 failed, 1 skipped — the 3 failures are
  live-LLM 401 (environment-bound test design), the skip is the
  daily-report test at :208. Re-measured at T3 execution time rather
  than trusted from that record.

Every acceptance clause is strict-decrease plus zero-new, proven by a
sorted diff against this file's captured error list
(scratchpad p2_baseline_tsc.txt, 778 lines).
