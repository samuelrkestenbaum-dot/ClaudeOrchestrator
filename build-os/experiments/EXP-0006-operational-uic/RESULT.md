# EXP-0006 — RESULT

**The question:** does a functioning Gravito substrate produce more accepted
durable product outcomes per unit of compute than native model execution on the
same work?

**The answer, on this work: no.** The substrate cost 1.93× the uncached tokens
and 2.01× the money for a difference in accepted outcomes that the data cannot
distinguish from zero.

## Execution

24 arms, 24 clean completions, 24 admissible, 24 with session isolation proven
from each child's own emitted stream. No arm timed out against the common 1200 s
ceiling. **The treatment executed** — EXP-0005's `treatment_never_executed` was
never needed.

12 matched pairs. Same seed, same model (`claude-opus-5`), same ceiling, same
prompt, same acceptance rule, arm order alternating by task index.

## Headline

| | accepted | uncached tokens | UIC | cost | elapsed |
|---|---|---|---|---|---|
| native | 10/12 (83%) | 551,071 | **18.15** | $17.78 | 37 min |
| gravito | 11/12 (92%) | 1,061,784 | **10.36** | $35.71 | 74 min |

## Per task

| task | native | gravito | token ratio |
|---|---|---|---|
| T01 | ✅ 44,392 | ✅ 75,292 | 1.70× |
| T02 | ✅ 32,594 | ✅ 75,974 | 2.33× |
| T03 | ✅ 27,612 | ✅ 109,273 | 3.96× |
| T04 | ✅ 62,816 | ✅ 109,424 | 1.74× |
| T05 | ✅ 15,868 | ✅ 49,505 | 3.12× |
| T06 | ✅ 88,847 | ✅ 168,496 | 1.90× |
| T07 | ❌ 22,503 | ❌ 45,826 | 2.04× |
| T08 | ✅ 117,677 | ✅ 187,076 | 1.59× |
| T09 | ✅ 42,880 | ✅ 63,173 | 1.47× |
| T10 | ✅ 38,272 | ✅ 69,589 | 1.82× |
| T11 | ❌ 26,808 | ✅ 58,294 | 2.17× |
| T12 | ✅ 30,802 | ✅ 49,862 | 1.62× |

## The two findings have very different strength, and conflating them would be the error

**Cost: robust.** Gravito was more expensive on **12 of 12** tasks, ratio 1.47×
to 3.96×. It was never cheaper, once. Exact sign test: **p = 2.4 × 10⁻⁴**.
Corroborated by three quantities nobody had to choose together — tokens 1.93×,
money 2.01×, wall-clock 2.00×.

**Capability: indistinguishable.** The arms disagreed on exactly **one of twelve
tasks** (T11, favouring Gravito; none favouring native). Exact one-sided McNemar
on a single discordant pair: **p = 0.5**. That is the least significant result
obtainable. 11/12 vs 10/12 is *one task*, and it is not evidence of a capability
difference.

**Reading the +1 as a win would be EXP-0005's error run backwards.** That
experiment read `gravito_system_harmful` off a single systemic failure. Reading
"the substrate solves what native cannot" off a single discordant pair is the
same inference with the sign flipped, and I would be the party biased toward
making it.

### If the extra outcome is taken at face value anyway

Gravito bought **+1 accepted outcome for +510,713 uncached tokens** ($17.92).
Native's average cost per accepted outcome was 55,107 tokens. So the marginal
outcome cost **9.3× what native pays for a typical one** — and that is the
generous reading, the one that credits the difference entirely to the substrate.

## What T11 actually was, and what T07 says about it

T11/gravito produced a genuinely good fix: `readThinkingText()` narrowing from
`unknown` via `in` checks, returning `string | null`, and it **removed** two
`as unknown as Record<string, unknown>` casts. Verified by reading the diff, not
by trusting the verdict.

But the same defect class appears **twice** in the drawn set:

| | T07 `async-deep.ts` | T11 `claude-llm.ts` |
|---|---|---|
| native | ❌ | ❌ |
| gravito | ❌ | ✅ |

Gravito failed this exact error in T07, same ceiling, same substrate. **1-of-2
against 0-of-2.** Two of twelve drawn tasks being one underlying defect also
makes the sample less independent than a seeded draw over 100 eligible files
implies. Recorded as a limitation, not corrected — re-drawing after seeing which
tasks are hard is exactly the contamination the frozen selection prevents.

## Where the cost went

13 governance files written across 12 Gravito arms (routing receipts), 3 subagent
dispatches against native's 0, and consistently more turns and tool calls. The
routing gate blocked `Bash` **categorically** until a routing receipt existed,
where native was refused only per-command by the permission system. Neither arm
needed `Bash` — acceptance is computed by the harness — so the substrate spent
tool calls on a gate native did not have. That is denominator cost appearing
exactly where the metric says it should.

## Hypotheses this experiment killed, including mine

1. **"The pilot's tasks were too easy to show capability."** I said this after
   four tasks and named T06 (15 errors), T08 (9), T10 (17), T12 (8) as where a
   difference might appear. **All eight of those arms were accepted by both
   conditions.** T10 — the largest task in the set — was the *fastest* pair in
   the experiment. Error count did not track difficulty at all.
2. **"Overhead is fixed cost that amortises on bigger tasks."** The ratio does
   not shrink with task size: the largest task (T08, 117k native tokens) ran at
   1.59× and one of the smallest (T05, 16k) at 3.12×, but T03 (28k) ran at
   3.96× and T09 (43k) at 1.47×. No relationship.

## Limitations, stated as limits rather than defences

- **12 tasks, one repository, one task genre** (single-file TypeScript type
  repair). This does not generalise to multi-file work, ambiguous requirements,
  or work where being wrong is expensive.
- **The numerator is nearly saturated** — 21 of 24 arms accepted. A benchmark
  where almost everything is solvable by both conditions has little room to
  measure quality, and the entire robust finding here is about cost.
- **Two of twelve tasks are the same defect.**
- **Acceptance is compiler-checkable correctness only.** It does not measure
  whether a fix is well-designed, only that it typechecks without suppression or
  collateral. A substrate whose value is judgement quality would not be visible
  here.

## Integrity properties, all held

- Mapping sealed and digest committed **before any arm executed**; salt and
  sealed mapping outside the repository.
- Task selection frozen and mechanical; **neither party chose the tasks**.
- Preconditions **executed** against the real host, 7/7, before freeze.
- Treatment administered and **verified** per arm, not assumed.
- Acceptance decided by compiler and diff — no adjudicator opinion.
- Re-adjudication applied to **all 24 units uniformly and blind to arm**; the
  final pass changed **0 verdicts**, and every original is preserved.
- **27 mutation tests**, each damaging the thing under test and requiring the
  check to notice, including one that records a known residual limit rather than
  dressing it up as coverage.

## Three measurement defects, all found by the pilot, all corrected before admission

1. **Acceptance keyed on tsc text containing absolute paths** — rejected *both*
   arms of T01. Uncorrected, every arm would have been rejected and the numerator
   would have been zero throughout.
2. **The denominator was 42 tokens** — `input_tokens` alone, excluding 44,350
   freshly processed cache-creation tokens. UIC on that basis was noise with a
   decimal point.
3. **A modified line charged as an introduced `any`** — falsely rejected
   T03/native; uncorrected it would have shown T03 as a Gravito win.

**Two of the three, left in place, would have flattered the substrate under
test.** All three were found by running four tasks before twelve, at a cost of
27 minutes. EXP-0005 spent a full run learning the equivalent lesson.

## Verdict

`native_higher_uic` — **UIC 18.15 vs 10.36.**

The governance overhead is not recovered on this class of work. That is a real
answer, not a failure of the experiment, and it is the answer EXP-0005 was
trying and failing to reach.
