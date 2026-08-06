# PILOT-0001 — Internal external-style real-repository pilot — FREEZE

Classification (operator's exact label, binding): **Internal external-style
real-repository pilot.** A real product repository separate from Gravito's
governance codebase, internally owned, NOT independent customer evidence.
Never presented otherwise.

Frozen BEFORE task 1. Ancestry of this commit is the proof of freeze-first.

## Repository seed and isolation

- Pilot repo: /home/user/empathiq-website (samuelrkestenbaum-dot/empathiq-website)
- Seed SHA: **d5ae200169f57ce4b96ce70b5efbe8d4702dd7a9** (= origin/main tip)
- Pilot branch: `pilot/PILOT-0001-internal-external-style` at d5ae200, LOCAL ONLY.
- cb2bb7d isolation: `cb2bb7d96d6ffd57257f252e13468aeda442bd95` is the local
  tip of `claude/project-handoff-merge-ramhds` (ahead 1 of its origin ref),
  preserved under ref `preserve/cb2bb7d`. The pilot branch descends from
  d5ae200 and `git merge-base --is-ancestor cb2bb7d` returns FALSE against it.
  cb2bb7d will not be modified, absorbed, rebased, or pushed by the pilot.
  Dev-branch vs main divergence at freeze: dev = main + 10 build-os commits,
  main has zero commits dev lacks — product code identical at seed.
- NOTHING from the pilot is pushed without a scoped operator go. The pilot
  commit chain will be reported for a scoped push decision at completion.

## Control plane

- Gravito always present: every task routes at entry via
  ClaudeOrchestrator's `build-os/tools/route-task.sh` (cross-repo: the pilot
  repo's installed build-os is an older vintage without routing tools —
  receipts live in ClaudeOrchestrator's store, which IS the pilot evidence).
- Depths: thin Direct / Light / Full per the selector; Full ONLY with a
  qualifying value factor and necessity evidence. No forced depth balance;
  no Full invoked merely to create comparison data.
- HONEST BOUND, named at freeze: routing-gate hooks (adapter #1) are wired in
  ClaudeOrchestrator's .claude/, not the pilot repo's; and the orchestrating
  session predates the wiring. Hook ENFORCEMENT is therefore UNAVAILABLE for
  pilot tasks; routing here is protocol + receipts + close-time sweep
  (machine-at-close), exactly the labeled layers. Telemetry tiers per
  provider_adapter_contract.md: wall-clock EXACT; dispatched-subagent
  tokens EXACT per dispatch (harness-reported); parent-loop live tokens
  UNAVAILABLE interactive, CLOSE-TIME where reconcilable; weekly meter
  OPERATOR-PROVIDED ONLY, never derived from tokens.

## Baseline health at seed (measured before freeze)

- `pnpm run check:app` (tsc): **RED, exit 2** — type errors spanning
  server/stripe (API-version pin + Subscription property drift),
  server/surface-intelligence, server/surface-scoring, server/training,
  server/voice-stream-gateway, server/webhooks, server/workflows/engine.
- `npx vitest run server/governance/operationalization.test.ts
  server/agents/agents.test.ts`: **4 failed | 38 passed | 2 skipped** —
  operationalization: `executeFixLayer dry-run` FAILS; agents: 3 structure
  tests FAIL on live-LLM 401 (environment-bound test design). Known defect:
  operationalization.test.ts:125 carries a VACUOUS shadow test (empty body,
  same name as the adjacent it.skip'd real test) that reports green while
  asserting nothing.

## The five frozen tasks (connected, real, no manufactured defects)

- **T1 — Diagnose (target lane: diagnosis).** Diagnose the red baseline:
  classify every check:app type error by subsystem and root cause; diagnose
  the vacuous-shadow/skip pair in operationalization.test.ts (why is the
  real test timeout-prone?); diagnose whether the executeFixLayer dry-run
  failure and the three agents 401 failures are code defects or test-design
  defects. Deliverable: written diagnosis + bounded fix plan with an
  ordered, scoped subset for T2/T4/T5. NO implementation.
  Acceptance: diagnosis names every error with file:line, classifies each,
  and proposes bounded fixes; zero repo mutation. Time target: 30 min.
- **T2 — Bounded tested correction.** Per T1's plan: remove the vacuous
  shadow test and make the real "autonomy rate in notification content"
  test run deterministically (fix the timeout-prone cause — bounded to
  remediation-notifications dispatch path and its test). Acceptance: the
  previously-skipped assertion runs un-skipped and passes deterministically
  (3 consecutive runs), no vacuous test remains, the file's other tests
  stay green, no unrelated changes. Time target: 60 min.
- **T3 — Multi-file product change.** Implement the dedicated
  `four_eyes_state_change` operator-event kind (the recorded TODO at
  server/governance/four-eyes-approval.ts:116): add the kind to the
  operator-integrity kind registry/types, switch emitAudit to it, keep
  backward compatibility for stored `config_persona_set` rows, update every
  consumer/validator that enumerates kinds, with tests. Acceptance: new kind
  flows end-to-end, existing tests green, new tests cover emit + enumerate +
  back-compat read. Time target: 90 min.
- **T4 — Fix a failing test (real, pre-existing).** The baseline-failing
  `executeFixLayer dry-run` test in operationalization.test.ts: fix code or
  test per T1's classification WITHOUT weakening the assertion (a
  dry-run must provably not modify files). Acceptance: test passes, the
  no-modification property is genuinely asserted, file suite green.
  Time target: 60 min.
- **T5 — Fresh-session follow-up (depends on T1–T4 decisions).** In a NEW
  session: using T1's recorded classification, fix the Stripe error cluster
  (gravito-checkout.ts API-version pin + webhook.ts Subscription property
  drift) as a bounded subset of the check:app debt, consistent with any
  conventions T2–T4 established. Acceptance: the Stripe-cluster errors are
  gone from check:app output, error count strictly decreases, no new
  errors introduced, tests touching stripe webhook stay green. The fresh
  session must FIRST route (no open receipt survives task closes) — its
  first act is a routing receipt, proving cross-session task entry.
  Time target: 60 min.

## Per-task measurements (recorded at each close, tier-labeled)

selected mode / executed mode / routing evidence / context considered vs
injected (files+bytes) / parent calls / subagents / tool events + failures /
elapsed EXACT / provider tokens (total, uncached, cache-read) at best
available tier / cost where reported / human interventions / test result /
acceptance result / rework / routing overhead / reassessment-throttle-
degradation events / for any Full: per-agent contribution rows.

## Weekly meter protocol

Operator-provided readings ONLY: BEFORE reading required before T1 begins;
AFTER reading at pilot completion. Recorded as operator-observed, timestamped,
model-specific where visible. No token-derived estimates. Headline metric:
durable accepted product output per percentage point of weekly credit.

## Settings frozen

Model claude-fable-5 (this harness); permissions: no push/merge/deploy/
secrets without explicit scoped operator go; suite commands as named per
task; pilot commits land ONLY on pilot/PILOT-0001-internal-external-style.
No new Gravito architecture during the pilot absent an executed pilot
blocker requiring a minimal correction.

## FREEZE AMENDMENT 1 — model change, disclosed (before task 1, zero tasks run)

The operator switched this session's model to **claude-opus-5** after the
freeze commit and BEFORE T1 began. The frozen settings above named
claude-fable-5. Amending rather than silently editing: the pilot's frozen
model is now **claude-opus-5**, and no measured task ran under the previous
value. This matters because the pilot's headline metric is per-percentage-
point of weekly credit and weekly-meter consumption is model-specific — a
mid-pilot model change would confound it. If the model changes again after
T1 starts, that is a confound to record, not to smooth over.

## OPERATOR-BINDING NOTES FOR THE FINAL REPORT (recorded at freeze time)

1. **Keep the enforcement limitation prominent**: this pilot tests
   cross-repository control through protocol, receipts, and close-time
   reconciliation — NOT full native runtime enforcement. Hooks are not
   active inside the pilot repository.
2. **Never present this as external customer validation.** Exact label:
   Internal external-style real-repository pilot.
3. **Full mode's burden of proof is open**: Full has shown it can consume
   resources; it has NOT shown its extra agents consistently catch what
   Direct or Light would miss. If Full activates in this pilot, its
   contribution rows must answer that question honestly — including a
   negative answer.
4. **Process expansion is a named weakness**: every control must answer
   "did this layer prevent a real failure or improve an outcome enough to
   justify its ongoing cost?" The pilot should report where Gravito's own
   ceremony cost more than it returned.
5. **Product simplicity is now critical**: the customer-facing surface is
   task → selected mode and reason → budget → progress → result → evidence.
   Packet numbers, doctrine chains, census counts, archivist mechanics and
   rotation rules are internal, and the report should say which of the
   pilot's overhead a customer would never see.
