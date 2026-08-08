# Catastrophic-non-action predicates — validation (task #46)

Two generic predicates added to `disposition.mjs`, taking it to **v1**:
`total-acceptance-floor` and `spend-without-durable-output`.

## The constraint these were built under

A predicate authored after an outcome and validated on that same outcome has
been **fitted to the answer, not tested**. So:

- **EXP-0005 is excluded from the validation set entirely** — from both halves.
- Every predicate is a general statement over the artifact schema and names no
  experiment, task, component or constant drawn from one.
- The validation set has **two** halves, because either alone is worthless: a
  false-positive guard (must not fire where output exists) and a vacuity guard
  (must fire where it should). A rule that never fires proves nothing by
  staying silent.

**Stated plainly:** these rules were authored by an agent that had already seen
the outcome they are meant to catch. That is the same failure shape
`disposition.mjs`'s own header warns about. The bound below is what limits it;
it does not eliminate it.

## Validation set — 8 cases, EXP-0005 in none of them

### Negative — must NOT fire

| case | source | result |
|---|---|---|
| 5/5 vs 5/5 acceptance | **EXP-0001**, did not inspire these rules | silent |
| 10/10 acceptance both arms | **EXP-0002**, did not inspire these rules | silent |
| poor but OPERATING — 1/6 accepted, full durable output | synthetic | silent |
| below the units floor — 0/3 accepted | synthetic | silent |
| acceptance **not measured** (`null`) | synthetic | silent |

The last two are the ones that matter most. A treatment with a small sample, or
one whose acceptance was never measured, must not be reported as non-action —
**`null` is not zero**, and an underpowered sample is not evidence.

### Positive — must fire, exactly as specified

| case | expected | result |
|---|---|---|
| zero accepted, zero durable, real spend | both predicates | both |
| floor **without** spend | floor only | floor only |
| zero accepted but full durable output | floor only | floor only |

The third is the discriminating case: a treatment that *worked* and had
everything rejected is a quality failure, **not** non-action. Only the
acceptance predicate fires; the spend predicate correctly stays silent.

**8 of 8 pass.**

## Why both predicates are `queue`, never `execute`

This is the design decision the evidence forced, and it runs against what would
have been convenient.

The **first diagnosis of the outcome that inspired these rules was wrong.** It
attributed a total acceptance floor to a missing-state deadlock; reproduction
later showed the routing machinery worked and the real cause sat one layer out,
in a host permission interaction. An `execute`-class finding would have
auto-opened a packet implementing that wrong fix.

So a total acceptance floor identifies **where to look**, not **what is wrong**.
Those are different findings, and a predicate that cannot distinguish them must
not hold execution authority. `authority: operator_decision` for both.

## What this does NOT claim

- It does **not** claim the disposition engine would now have caught EXP-0005
  prospectively. The predicates fire on the *shape*; whether that shape would
  have been recognised without hindsight is untestable from here.
- A retrospective check against EXP-0005 was **deliberately not run as
  validation**. It would confirm only that a rule written to describe an
  outcome describes it.
- Generalisation remains **unproven** until these fire — or correctly stay
  silent — on an experiment that has not yet been run.

## Record of the original miss, preserved

`disposition.mjs` v0 produced 2 findings on EXP-0005, both
`unsupported_hypothesis`, **0 execute-class**, and missed the defect entirely:
its only acceptance rule required `regressions > 0`, and a treatment that does
nothing breaks nothing. That miss is recorded in `RESULT.md` §19 and
`POST-OUTCOME.md`, both frozen and untouched. v1 extends the rule set; it does
not erase the evidence that v0 failed.
