# EXP-0005 — post-reveal reading note

**This note does not alter the experiment.** `RESULT.md`, `PREREGISTRATION.md`,
`tasks/TASK-FREEZE.md`, `blinding/`, `baseline/` and every artifact under
`results/` are frozen and untouched. Nothing here is a retrospective
reclassification, and the registered verdict is not softened, replaced or
re-run.

## The registered verdict stands

> **`gravito_system_harmful`**

That is what the preregistered rules returned from the frozen evidence, and it
remains the result of record. The acceptance veto fired unconditionally on
0/12 against 10/12.

## What the verdict does NOT distinguish, and this note does

The causal failure mode was **catastrophic non-action**, not degradation of
completed work.

Gravito produced **zero product mutations** because the clean-start
routing/bootstrap state deadlocked **before any work could begin**. It never
entered a state in which it could attempt the tasks.

That is materially different from a treatment which executes normally and
produces worse-quality or less-efficient outcomes. The registered vocabulary
has no term for the difference, so `gravito_system_harmful` carries both
meanings and a reader will default to the wrong one.

**Therefore:**

- EXP-0005 **establishes** that current Gravito is harmful/unusable **under the
  frozen clean-start condition**;
- EXP-0005 **does not estimate** the efficiency of a successfully bootstrapped
  Gravito system.

The efficiency thesis is **unanswered**, not disproven. The 25.6% total-token
saving and the slightly lower median elapsed are not efficiency wins: both
follow from stopping before doing the work.

## Vocabulary gap

    missing_registered_state: treatment_never_executed

**Semantics.** The treatment was administered as specified and the measurement
remained valid, but the treatment failed to enter an operational state capable
of attempting the requested product outcome.

**Cause is recorded separately from state**, so the state generalises to future
cases where a treatment never acts for a different reason:

    state: treatment_never_executed
    cause: bootstrap_deadlock

**Not retrofitted.** EXP-0005's registered verdict remains
`gravito_system_harmful`. `treatment_never_executed` is a **candidate state for
future experiment vocabularies** and has no standing in this experiment's
frozen record.

## Three representation failures, recorded

1. **Bootstrap.** Gravito cannot start from a clean durable state. The mutation
   gate ships tracked; the routing state that opens it is untracked and was
   classified disposable. Creating the receipt requires the authority the
   receipt grants.
2. **Learning.** Post-Outcome Disposition v0 has **no generic predicate for zero
   accepted output or zero durable product action**, so it failed to identify
   the bootstrap defect prospectively. Its only acceptance rule is gated on
   `regressions > 0`, and a treatment that does nothing breaks nothing.
3. **Measurement language.** The registered outcome vocabulary **could not
   distinguish active harm from catastrophic non-action**.

Failures 2 and 3 are the same class: the measurement and learning layer cannot
*detect* or *name* a treatment that never acted. Failure 1 is the product
defect they both failed to represent.

## No rules were added, and none may cite EXP-0005 as validation

No predicate has been added to Post-Outcome Disposition. Candidate generic
predicates — acceptance collapsing to zero; expected product output absent; all
treatment units terminating without durable work; treatment systematically
unable to cross an authority boundary — are recorded in `POST-OUTCOME.md` §C as
**proposed and deliberately not applied**.

**Any such predicate must be authored prospectively and validated against
experiments or fixtures that did not inspire it.** Using EXP-0005 as validation
evidence for a rule written after EXP-0005 would be fitting the detector to the
answer — the failure `disposition.mjs`'s own header warns about, and the same
shape as EXP-0004's analyst-blinding break.

## Product sequence, recorded — not started

1. Fix clean-start bootstrap: a fresh installation must earn its first mutation
   authority **without already possessing mutation authority**.
2. Fix durability classification: any state required for bootstrap must be
   either durably reconstructable or deterministically initialised.
3. Extend future experimental vocabulary to represent treatment non-execution.
4. Extend Post-Outcome Disposition with generic catastrophic-non-action
   detection.
5. Validate on **fresh clean-clone tasks**.
6. **Do not re-run EXP-0005 or overwrite its result.**

## Out of scope

Broader four-surface substrate readiness is a **separate** matter and remains
**FAIL** — Claude, Manus and surplus-recovery missing. It forms no part of
EXP-0005's verdict and is neither improved nor measured by it.
