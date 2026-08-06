# EXP-0004 — the capsule byte budget, fixed BEFORE any arm executes

`TASK_FREEZE.md` fixes the seed, the tasks, the acceptance rules and the
substitution treatment. It does **not** fix the compiler's byte budget, and
the preregistration does not either. The budget is therefore an **unset free
parameter of the treatment**: leaving it null is itself a choice, so it has to
be chosen, derived, and recorded now — while no arm has run and no result
exists to tune toward.

This file is the record. It is committed **before the first arm**, after
`mapping.sha256` (`7be2af7`) and before any task executes.

## The rule (stated first, applied uniformly)

> **Admission stops at the end of priority 4** — the seed-local dependency
> graph. **Priority 5 is excluded.**

The frozen compiler's ladder (`compile-task.mjs`, `PRIORITY`) is:

| rung | rule | scope |
|---|---|---|
| 1 | files named as seeds / defining a seed symbol | task |
| 2 | tests covering a defining file | task |
| 3 | direct importers of a defining file | task |
| 4 | what a defining file imports (neighborhood) | task |
| 5 | **cluster siblings — files failing the same way** | **repository** |

Rungs 1–4 are reachable only by walking outward from the task's own seeds.
Rung 5 is not: it admits every file anywhere in the repository that shares an
error signature with a seed. For E1 that rung alone produced **134 of 187**
candidates — files that are not part of the task and were never claimed to be.
Cutting at the last task-scoped rung is the only cutoff the compiler's own
semantics justify. It is not a size target.

The byte number is **derived**, not chosen. Because the ladder admits a strict
prefix — it stops at the first candidate that does not fit rather than skipping
ahead — the smallest budget that admits every priority-1–4 candidate is exactly
`base_bytes + cost(priority 1..4)`, and the first priority-5 candidate then
necessarily does not fit. Each number below was obtained by bisection over the
**frozen compiler**, with no compiler change.

## The derived budgets

| task | budget (bytes) | base | spent | admitted | dropped | dropped at priority |
|---|---:|---:|---:|---:|---:|---|
| E1 | 79,093 | 35,220 | 43,873 | 53 / 187 | 134 | 5 only |
| E2 | 125,657 | 48,283 | 77,374 | 133 / 260 | 127 | 5 only |
| E3 | 42,354 | 23,388 | 18,966 | 41 / 122 | 81 | 5 only |
| E4 | 148,910 | 53,227 | 95,683 | 193 / 288 | 95 | 5 only |
| E5 | 56,992 | 23,789 | 33,203 | 34 / 124 | 90 | 5 only |

In every task the drop set is priority 5 and **nothing else** — which is the
rule holding, verified rather than asserted.

Admitted-by-rung, for the record:

| task | 1 defining | 2 tests | 3 importers | 4 neighborhood |
|---|---:|---:|---:|---:|
| E1 | 6 | 7 | 11 | 29 |
| E2 | 8 | 17 | 11 | 97 |
| E3 | 8 | 4 | 4 | 25 |
| E4 | 4 | 5 | 7 | 177 |
| E5 | 4 | 3 | 5 | 22 |

## Disclosed: the probe that preceded the rule

Before the rule was written, two budgets were probed on E1 alone: **24,000**
(admitted 0 files — it is below E1's 35,220-byte base cost, so the capsule
could hold no file at all) and **48,000** (admitted 25). Those probes are why
the parameter was recognised as unset; they are disclosed because they
informed that recognition.

The rule fixed above produces **79,093** for E1 — neither probe value, and
larger than both. The rule was not written to reproduce a probe.

## Disclosed: what the budget cannot control

The rendered capsule is **not** dominated by what it admits. Every candidate
the budget declines is disclosed in `excluded_notable` at roughly 500 bytes
per file, because the capsule prefix makes that disclosure binding ("`
excluded_notable` is the capsule's disclosure of what it withheld and why.
Read it."). The consequence, measured:

| task | capsule.md at derived budget | capsule.md unbudgeted | floor at budget≈base |
|---|---:|---:|---:|
| E1 | 132,728 | 138,523 | ~108,092 |
| E2 | 174,982 | 180,268 | — |
| E3 | 76,674 | 81,209 | — |
| E4 | 185,284 | 187,187 | — |
| E5 | 94,228 | 97,318 | — |

Declining a file saves roughly 500 bytes of disclosure against roughly 800–900
bytes of content, so **the budget is a weak size lever and there is a floor set
by the candidate count, not by the budget.** Arm B therefore starts at
77–185 KB (≈19k–46k tokens) whatever budget is chosen.

This is stated here, in advance, because it is the leading candidate
explanation if arm B loses on tokens. If that happens, the registered outcome
(`context compilation harmful`, or a failed token gate) stands as written — it
is not to be explained away. But the limitation that must accompany it is
equally fixed in advance: **the experiment measures this compiler build, whose
exclusion-disclosure rendering is a large fraction of its own output, not the
concept of context compilation.** Recording that boundary after seeing the
result would be worthless; recording it now is the point.

## What is NOT permitted from here

- Changing the budget, the rule, or the compiler after any arm has run.
- Re-deriving a budget per task after observing that task's arm A.
- Treating a large capsule as a reason to substitute or re-scope a task.

The parameter is now fixed for all five pairs.
