# PILOT-0001 T1 — Diagnosis of the red baseline (NO implementation)

Seed: d5ae200. All evidence measured on pilot branch. Elapsed window
2026-08-06T04:13:41Z → 2026-08-06T04:27:30Z.

## 1. check:app — 782 errors, 168 files, five root-cause classes

Full listing: scratchpad t1_tsc_errors.txt (782 lines, per-file bucket
captured). The debt is STANDING (main is red; check:app is aspirational,
not CI-gating). Classes, largest first:

- **C1 — nullable `db` (108 errors, "'db' is possibly 'null'").** One root
  cause: the shared db handle is typed nullable and call sites dereference
  it bare. Heaviest: governance-dashboard-router (32), dogfooding-router,
  guardian, geometry-admin-router. Mechanical fix pattern (guard/assert at
  module boundary), but WIDE blast radius — a debt packet, not a pilot task.
- **C2 — `unknown` catch/parse variables (~200: TS18046 111 + TS2571 +
  assorted; 'e'/'err'/'error'/'r'/'v'/'state').** Strict-mode hygiene debt.
  Mechanical (narrow at use site). Same verdict: dedicated debt packet.
- **C3 — four-eyes `Result`/`proposal` drift (17, all in
  server/governance/four-eyes-approval.standalone-test.ts: "Property
  'proposal' does not exist on type 'Result'").** The standalone test
  lags the four-eyes API. DIRECTLY relevant to T3 (which touches four-eyes
  audit emission): T3 must not deepen this drift; its tests go in the
  vitest surface, and T3 should reconcile the standalone-test drift ONLY
  if its own change touches the same types (else name it, leave it).
- **C4 — genuine API-drift clusters, each local:** trpc client 'bridge' →
  'bridges' (6), CoverageReportData.coverage (6), surface-scoring missing
  export EmotionalDynamics, training/router interface-vs-class conflict
  (private config + Promise mismatch), workflows/engine arity + generic
  misuse (3), voice-stream-gateway LogDomain union missing member,
  webhooks/router unknown-narrowing (2). Each is a bounded local fix.
- **C5 — STRIPE CLUSTER (3 errors; frozen T5 target):**
  gravito-checkout.ts:6 pins apiVersion "2024-12-18.acacia" vs SDK type
  "2025-12-15.clover"; webhook.ts:428-429 read current_period_start/end
  from Subscription — in the upgraded stripe SDK those moved off the
  Subscription top level (live on items/lines in current API shapes).
  Bounded, testable, isolated from C1/C2 noise. T5 acceptance restated:
  stripe-cluster errors gone; total strictly < 782; zero new errors.

## 2. Vacuous shadow test + timeout-prone real test (T2 target)

operationalization.test.ts:125-127: an EMPTY-BODY test carrying the same
name as the adjacent it.skip'd real test, with a 15s timeout param and an
eslint-disable — reports green, asserts nothing, conceals the skip. Root
cause of "timeout-prone": dispatchRemediationNotification
(remediation-notifications.ts:232) awaits Promise.all(in-app notifyOwner →
DB write, Slack fetch). In test runtime the DB is OFFLINE (vitest setup
logs "Audit trail not available (DB may be offline)"), so the in-app leg
hangs on driver timeout — nondeterministic 15s+ waits. Classification:
TEST-DESIGN defect (live-infra dependency in a unit test) PLUS a concealed-
coverage defect (the shadow). T2 plan: delete the shadow; make the real
test hermetic (mock notifyOwner and the webhook fetch at module boundary,
assert both result legs' shape and error paths); acceptance = un-skipped,
deterministic across 3 consecutive runs, file otherwise green, no vacuous
test remains.

## 3. executeFixLayer dry-run failure (T4 target)

ORDER-DEPENDENT, localized IN-FILE: fails in the full-file run (1 failed |
25 passed) and in the two-file baseline, PASSES when filtered
(-t "dry-run": 3/3 green, 21s). Suspects, in order: (a) earlier tests in
the file mutate module-level state (env save/restore of SLACK_WEBHOOK_URL
at ~:115; fix-strategy registry caches; DB-unavailable persistence caches
accumulating), (b) cumulative slow DB-timeout waits pushing the dry-run
test past its per-test timeout only when the file's earlier tests already
burned the clock. Classification: CODE-OR-TEST pollution defect — real,
pre-existing, reproducible. T4 plan: bisect describe-blocks to pin the
polluter, fix at the source (isolate module state or reset caches in
before/after hooks) WITHOUT weakening the dry-run assertions (dry-run must
still provably not modify files).

## 4. agents.test.ts 3 failures — classification only (no frozen task)

Lead/Content/Outreach structure tests invoke the LIVE LLM path (Anthropic
401 invalid x-api-key → Forge proxy fallback → structures empty/wrong).
TEST-DESIGN defect: unit tests with a live-LLM dependency; product code
not shown defective. Out of the frozen pilot scope; named for a future
hermetic-test packet. The it.skip'd daily-report test (agents.test.ts:208)
is adjacent lost coverage, same future packet.

## Ordered bounded plan for the pilot's remaining tasks

T2 (shadow + hermetic notification test) → T4 (in-file pollution fix) →
T5 (stripe cluster, fresh session, this document is its context) —
with C1/C2 wholesale cleanup and the agents live-LLM tests as NAMED
NON-GOALS of the pilot (debt packets proposed, not built).

## T1 measurements (tier-labeled)

selected_mode gravito_light / executed gravito_light (no escalation) /
routing evidence: receipt routing-PILOT-0001-T1-…041341Z / context
considered: repo-wide tsc surface + 2 test files + 1 source file / context
injected (read into session): t1_tsc_errors.txt buckets, ~120 lines of
test source, ~40 lines remediation-notifications.ts, failure outputs /
parent tool calls: 8 Bash (EXACT by count) / subagents 0 (EXACT) / tool
failures 0 / elapsed 671s EXACT (04:13:41→04:24:52) / provider tokens
UNAVAILABLE live (interactive; per adapter contract) / cost UNAVAILABLE /
human interventions 0 / tests run: 3 vitest invocations, 1 tsc / rework 0 /
BUDGET BREACH, honest: max_elapsed_seconds 600 EXCEEDED (671s) — cause:
three unavoidable test-runtime executions (160s, 23s, 160s) needed to
localize the order-dependence; degradation applied: stayed light, no
subagents, no scope growth; max_tool_calls 25 NOT exceeded (8).

# T2 measurements (appended; tier-labeled)

selected gravito_light / executed gravito_light, no escalation / elapsed
289s EXACT (04:25:42→04:30:31), WITHIN the 600s light budget / parent tool
calls 6 (EXACT): 2 reads, 1 edit, 3 vitest invocations / subagents 0 /
tool failures 0 / tokens+cost UNAVAILABLE live / human interventions 0 /
acceptance MET: hermetic test 28ms in-file + 3/3 deterministic filtered
runs; vacuous shadow deleted; 26 tests, only pre-existing dry-run timeout
remains (T4 target — full-file failure detail now pinned: 30006ms TIMEOUT,
first dry-run invocation only, only after earlier tests have run) /
rework 0 / pilot commit e01c901 (1 file, test-only) / commit amended once
pre-close for a 1-char session-trailer typo, disclosed.
