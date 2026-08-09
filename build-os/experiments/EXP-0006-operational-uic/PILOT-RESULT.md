# EXP-0006 — pilot result (T01–T04)

**Status: 4 of 12 tasks measured. This is not the experiment's result.** It is
the first stage of it, reported because a staged run that hides its first stage
until the end is just a slow run.

## What executed

8 arms, 8 clean completions, 8 admissible, 8 with session isolation proven from
the child's own emitted stream. No arm timed out against the 1200 s ceiling; the
longest was 642 s. **The treatment executed** — the vocabulary
`treatment_never_executed` exists for the EXP-0005 case and was not needed.

## The numbers

| | accepted | uncached tokens | UIC | cost | elapsed |
|---|---|---|---|---|---|
| native | 4/4 | 167,414 | **23.89** | $5.50 | 12 min |
| gravito | 4/4 | 369,963 | **10.81** | $12.02 | 27 min |

Per task, Gravito's uncached-token cost relative to native: **1.70× · 2.33× ·
3.96× · 1.74×**. It was never cheaper, on any task.

| task | native | gravito | ratio |
|---|---|---|---|
| T01 | 44,392 | 75,292 | 1.70× |
| T02 | 32,594 | 75,974 | 2.33× |
| T03 | 27,612 | 109,273 | 3.96× |
| T04 | 62,816 | 109,424 | 1.74× |

Four quantities that were not chosen together agree: tokens 2.21×, cost 2.19×,
wall-clock 2.25×, UIC 2.21×.

## The finding, stated plainly

On this work, **the substrate did not pay for itself.** It reached exactly the
same accepted outcomes as native execution and spent 2.2× the uncached tokens,
2.2× the money and 2.2× the time doing it.

## The limitation that matters most

**The numerator is saturated.** Both arms accepted 4/4, so the comparison could
only measure cost — it had no room to measure capability. A benchmark where
every task is solvable by both conditions cannot detect a quality difference,
and the entire UIC gap here is the denominator.

These were 1–2 error single-file repairs. The eight remaining tasks include
T06 (15 errors), T08 (9), T10 (17) and T12 (8). If the substrate's value is in
harder work — where routing, memory and verification might prevent a wrong
answer rather than merely document a right one — this pilot could not have seen
it, and the remaining tasks are where it would show. **That is a hypothesis, not
a defence.** If the ratio holds at 2.2× across the harder tasks with the
numerator still saturated, the honest reading is that the overhead is not
recovered on this class of work at all.

A weak counter-signal, recorded because it cuts the other way: the ratio is not
monotonic in task size. The largest native cost (T04) had nearly the narrowest
ratio, and the smallest (T03) had the widest. Four points is too few to fit
anything to.

## What the pilot was for, and what it caught

It was staged to surface harness defects cheaply. It found **three
`measurement_critical` defects in its first three arms**, each fixed before any
run was admitted:

1. **Acceptance keyed on tsc text containing absolute paths.** The baseline tree
   and the arm tree sit at different paths, so the same pre-existing error hashed
   differently and five untouched files read as regressions. It rejected **both**
   arms of T01. Uncorrected, every arm in the experiment would have been rejected
   and the numerator would have been zero throughout.
2. **The denominator was 42 tokens.** `input_tokens` alone, with 44,350 freshly
   processed cache-creation tokens excluded. UIC on that basis would have been a
   20% gap manufactured from a nine-token difference — noise with a decimal
   point.
3. **A modified line was charged as an introduced `any`.** A unified diff renders
   a modified line as both a removal and an addition, so an arm that added a
   return-type annotation to a line whose `any` was already there was rejected
   for improving it. This one falsely rejected **T03/native**, and uncorrected it
   would have shown T03 as a 1–0 Gravito win.

Two of the three, left in place, would have flattered the substrate under test.
The third would have destroyed the measurement entirely. All three were found by
running four tasks instead of twelve.

## Integrity properties held

- Mapping sealed and its digest committed **before any arm executed**; salt and
  sealed mapping outside the repository.
- Task selection frozen and mechanical; neither party chose the tasks.
- Acceptance decided by the compiler and the diff — no adjudicator opinion.
- Re-adjudication applied to **all 8 units uniformly and blind to arm**, with
  every original verdict preserved as `acceptance.original.json`.
- Every check mutation-tested: **27 assertions**, including the two that prove
  the path-normalisation fix did not widen the rule, and one that records a known
  residual limit rather than dressing it up as coverage.

## Next

The remaining 8 tasks (T05–T12), same seed, same ceiling, same frozen rules.
