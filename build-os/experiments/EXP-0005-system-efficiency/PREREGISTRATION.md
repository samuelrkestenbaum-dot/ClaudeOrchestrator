# EXP-0005 — PREREGISTRATION (draft, not frozen, not executed)

**Status: DRAFT.** Nothing may execute until this file is frozen and committed.
No task has been selected, no seed pinned, no mapping sealed.

## The question

> Does **Gravito as a system** deliver more accepted durable engineering output
> per unit of model compute than native Claude?

This is deliberately **not** EXP-0004's question. EXP-0004 asked whether one
component — the Context Compiler — beat the standard context path, and it lost
(`context compilation harmful`, frozen, permanent). EXP-0005 asks whether the
substrate as a whole changes the economics.

### What EXP-0004 does and does not license here

EXP-0004's standard-context arm was **not** "Gravito minus the compiler". Both
its arms ran with `.claude/` and `CLAUDE.md` sparse-excluded — no hooks, no
orchestrator, no lanes, no memory, no routing — because the injected Build OS
payload would have confounded every compiled arm by AMENDMENT 2's own check. So
EXP-0004's arm A is close to what EXP-0005 calls **native**, and EXP-0005's
Gravito arm is a condition **no arm in EXP-0004 ever ran**.

Consequence, stated so it cannot be claimed later: EXP-0004 provides **no prior
evidence** about EXP-0005's hypothesis in either direction.

## Primary metric

    UIC = accepted durable product outcomes / 1,000,000 uncached model tokens

An accepted outcome counts **1**. A rejected task counts **0**. There is no
partial credit; a task half-done is a task not done.

### The numerator rule — binding, and the reason it exists

**Gravito receives NO numerator credit for producing:** receipts, memory
records, routing artifacts, governance records, evidence packets, telemetry,
internal summaries, packet files, or any other substrate bookkeeping.

Those artifacts may be valuable. Counting them as "useful output" would make the
metric gameable by producing paperwork, and a metric that rewards paperwork will
get paperwork. **Every model token spent producing them belongs in the
denominator.** The numerator is the externally useful task outcome requested of
*both* arms — nothing else.

### The metric is deliberately hostile to Gravito

Stated plainly in advance, because it will be tempting to describe it otherwise
after the fact: Gravito pays for orchestration, gating and recording in the
denominator and is credited only for the same product outcome the native arm
produces. **A substrate that merely adds process will therefore lose on UIC by
construction.** It can only win by raising acceptance or by cutting exploration
enough to pay for its own overhead. That is the intended test.

## Arms

Both arms hold the **primary worker model constant**. Model-routing economics —
using a cheaper model inside Gravito — is a *later* production-policy benchmark;
allowing it here would manufacture a token advantage that says nothing about the
substrate.

### Arm N — native

A fresh session with the ordinary task statement and the normal repository and
tool access the task requires. **Absent:** Gravito memory, context compiler,
routing guidance, governance injection, receipts, durable task history,
prior-task summaries, agent orchestration.

### Arm G — Gravito

Same primary worker model. The substrate that would actually ship: persistent
repository state, relevant durable memory, context selection, routing decision,
authority/evidence layer, verification policy, receipts, outcome recording.

If Gravito's own router decides a task does not merit compiled context, it uses
standard context. **That is part of the system under test**, not a deviation.

## Frozen before execution

Task ids; repository seed commit; objectives; acceptance criteria; verification
commands; primary model id; every subagent model id; authority policy; the common
timeout ceiling; retry policy; run order; **and the Gravito memory state**, pinned by
commit — durable memory is a treatment component, so an unpinned memory makes
the treatment undefined.

### Task set

At least **10** matched tasks, selected from standing repository work **before
either arm executes**, spanning several defect and work types — not ten variants
of one TypeScript-debt pattern.

**E1–E5 are excluded as the primary benchmark.** They have been observed
repeatedly and may exist in Gravito's durable state, artifacts, logs or
developer knowledge. Reusing them would contaminate the arm that has memory,
in the direction that flatters it.

## Compute accounting

Captured **exact where available**, per arm per task: uncached input tokens,
cached input tokens, output tokens, total tokens, model and provider, model
invocations, subagent invocations, context bytes, expansion bytes, elapsed time,
API-equivalent cost.

**An unavailable field is recorded `-`, never converted to zero.** Primary
denominator: **uncached model tokens**, summed across the primary worker *and
every subagent* in that arm. Total-token economics reported separately.

## Quality and operating metrics

Per arm per task: acceptance; regressions; human interventions; rework rounds;
failed hypotheses where mechanically observable; verifier dispatches; time to
first meaningful edit; elapsed; durable product files changed; context
expansions; retries.

**UIC must never reward lower token use that comes from incomplete or rejected
work.** The numerator is acceptance-gated, which is what enforces this.

## Registered comparisons

1. accepted outcomes per 1M uncached tokens (UIC)
2. relative UIC multiple
3. uncached tokens per accepted outcome
4. total tokens per accepted outcome
5. acceptance rate
6. median elapsed
7. human intervention
8. rework
9. regressions
10. API-equivalent cost per accepted outcome

UIC multiple and token-reduction percentage are **mathematically linked** and
must be reported together: if native produces 8 accepted outcomes on 8M uncached
tokens (UIC 1.0) and Gravito produces 8 on 2M (UIC 4.0), that is a 4× UIC and a
`1 − 2/8 = 75%` reduction per accepted outcome. Reporting one without the other
is not permitted.

## Registered outcomes

`system_efficiency_supported` · `system_efficiency_directional` ·
`quality_gain_without_compute_gain` · `compute_gain_with_quality_shortfall` ·
`no_system_advantage_detected` · `gravito_system_harmful` · `inconclusive` ·
`result_confounded`

### Gates for `system_efficiency_supported` — all five required

1. Gravito acceptance **no worse** than native;
2. no material increase in regressions or human interventions;
3. **≥25%** reduction in uncached tokens per accepted outcome;
4. positive UIC improvement;
5. minimum registered n satisfied.

### Descriptive thresholds — reported, never verdict-bearing

Distance to **50%, 70%, 80% and 90%** reduction in uncached tokens per accepted
outcome is reported descriptively so the gap to the long-run efficiency thesis
is visible. **These do not move the gates.** Changing a gate after seeing a
number invalidates the run.

### Acceptance veto, carried forward from EXP-0004

Compute gain that costs acceptance is not a trade. A shortfall in Gravito
acceptance forces `compute_gain_with_quality_shortfall` or
`gravito_system_harmful`, whatever the token result.

## Blinding — the EXP-0004 failure, fixed structurally

EXP-0004's adjudicator blinding held; its **analyst blinding did not**, because
one agent held both the execution mapping and the blinded views. Three separate
roles, and **no single agent may hold two of them**:

| role | receives | never receives |
|---|---|---|
| **Executor** | everything; knows condition identity because it administers treatment | — |
| **Acceptance adjudicator** | opaque unit ids, objectives, criteria, **product diffs**, tests, acceptance evidence | economics, condition identity, governance artifacts |
| **Comparative analyst** | opaque ids, frozen acceptance outcomes, economic measurements | the executor mapping, raw per-arm artifacts, the execution log |

**Reveal** is a separate deterministic step joining frozen analyses to the
sealed mapping, once.

**This structure is tested before the first task runs**, with a leak-check
asserting that neither blinded view contains condition identity and that the
analyst cannot reach executor state.

### Leakage vector specific to this experiment — and its rule

The Gravito arm **emits receipts, memory updates and routing records**. A diff
containing `build-os/receipts/…` identifies the arm instantly, and the
adjudicator would be unblinded on sight.

**Registered rule:** the adjudicated work product is the **product diff only** —
every path under `build-os/`, `.claude/`, and any receipt, packet or memory file
is stripped before adjudication. The stripped governance diff is measured
separately, **as cost**, and never reaches the adjudicator. A unit whose
adjudicated diff still contains a governance path is `result_confounded`.

## Fixture reliability

EXP-0004 admitted **10 measurements from 14 arm executions**. That is not
normalised away. Hardened before EXP-0005 — generic runner faults only, already
demonstrated:

- **controller/subject session isolation** — see the invariant below;
- stdin prompt delivery (an argument over `MAX_ARG_STRLEN` killed three arms);
- no headless background-monitor dead-end (a `-p` session cannot be woken);
- isolated work trees per concurrent run;
- isolated baseline caches;
- explicit terminal-state validation — an arm ending `is_error: true` is not
  admitted;
- deterministic timeout handling;
- **no concurrent measured runs**, since elapsed time is a registered metric.

**No product redesign under the guise of harness hardening.**

### Structural invariant — controller/subject isolation

EXP-0004 found the orchestrator's task list visible inside both arms and
recorded it as benign **because it was symmetric**. Calibration attempt 1 showed
that reasoning does not extend: the measured child reported the *orchestrating
session's own* `session_id`, so measurer and measured shared session-scoped
state.

> **Symmetric leakage between two treatment arms may preserve a matched
> comparison. Leakage between the measurement controller and a measured subject
> destroys measurement independence.** The first is a shared constant; the
> second is the instrument reading itself.

Binding consequences:

- every measured arm runs under its own session identity, with session-scoped
  environment (`CLAUDE_CODE_SESSION_ID`, `CLAUDE_CODE_CHILD_SESSION`,
  `CLAUDE_PID`) scrubbed and a fresh id assigned;
- isolation is **proven from the child's own emitted stream**, never inferred
  from having spawned a process — *a new process is not a new session*;
- a run that completes cleanly but cannot prove isolation is **inadmissible**;
- both identities are recorded in the run evidence, and neither reaches a
  blinded role.

### Routing-gate overhead is treatment, not harness

Calibration attempt 1's Gravito arm hit
`MUTATION BLOCKED — no OPEN routing receipt exists`. That is the substrate
working as designed. It is **not** disabled, bypassed, pre-opened or optimised
for measurement. Time spent obtaining authority before acting belongs to the
system under test, and EXP-0005 charges it to the Gravito arm.

### Timeout — ONE common ceiling, and why it is not per-arm

Gravito's multi-stage flow plausibly runs longer in wall-clock than a single
native pass. An earlier draft of this section proposed a **per-arm** timeout set
as a fixed multiple of each arm's own median, on the theory that equal relative
headroom is what "symmetric opportunity" means when architectures differ.

**That was wrong and is corrected here.** EXP-0005 is a whole-system
comparison. If Gravito needs more elapsed time *because it has more internal
stages*, that extra time is **part of the treatment being measured**. Granting
it proportionally more wall-clock would normalise away a real system-level
disadvantage — compensating for the effect instead of measuring it, and doing so
in the direction that flatters the substrate.

**Registered rule:**

1. Record the native and Gravito completion distributions **independently**,
   from a pilot measured under a deliberately loose ceiling so the measurement
   is not clipped by the parameter it is choosing.
2. Derive **ONE common absolute timeout ceiling** from the **slower or wider** of
   the two observed distributions.
3. Set it with headroom generous enough that an ordinary successful task should
   almost never reach it.
4. Treat the ceiling as a **runaway / catastrophic-stop guard, never an
   optimization target**. It exists to stop a hung run, not to discipline a slow
   one.
5. **Freeze the common rule before task selection**, so it cannot be chosen
   after seeing candidate-task behaviour.
6. Report each architecture's calibrated **median, max, spread and headroom**
   relative to the common ceiling.
7. During the run, report **timeout / truncation rate per arm as a first-class
   outcome**, not as a footnote. A truncated arm is recorded `is_error` and is
   not admitted.

**If the Gravito distribution is materially slower or wider than native, that is
preserved as evidence — not compensated for through a different allowance.**

## Adversarial review of this design

Run against this draft before freezing, per instruction.

**Leakage — three found.**
1. *Governance artifacts in the adjudicated diff* — would unblind on sight.
   Fixed by the strip rule above.
2. *Elapsed time as an arm tell* — a multi-stage arm looks different in the
   timing column. The analyst sees economics by construction and this cannot be
   removed without removing the metric; recorded as a residual limitation.
3. *Subagent invocation counts* — a non-zero subagent count identifies the
   Gravito arm. Mitigation: the analyst receives it, the **adjudicator does
   not**. Residual, and stated.

**Numerator gaming — two found.**
1. *Counting governance artifacts as output* — closed by the binding numerator
   rule.
2. *Splitting one task into several "accepted outcomes"* — closed by fixing the
   task set and its ids before execution; the numerator counts registered
   tasks, not artifacts produced.

**Asymmetric treatment — three found.**
1. *Model routing* — closed by holding the primary worker model constant.
2. *Timeout* — see above; per-arm calibration plus reported truncation rate.
3. *Memory contamination* — closed by fresh tasks plus a pinned memory commit.
   **Residual:** Gravito's memory legitimately contains general repository
   knowledge, and separating "the substrate works" from "the substrate happens
   to remember this repository" is **not possible in a single-repository
   experiment**. Stated as a limitation of EXP-0005 by construction, and the
   reason a second repository is the natural follow-on.

## Readiness — what is NOT done

- [ ] task set selected and frozen (**0 of ≥10**)
- [ ] repository seed pinned
- [ ] memory state pinned
- [ ] common timeout ceiling calibrated and frozen (pre-task-selection)
- [ ] three-role blinding harness built and leak-tested
- [ ] governance-strip rule implemented and tested
- [ ] mapping sealed, digest committed
- [ ] this preregistration frozen

**Nothing executes until every box is ticked.**
