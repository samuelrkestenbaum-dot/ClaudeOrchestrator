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
| E1 | 79,507 | 35,634 | 43,873 | 53 / 187 | 134 | 5 only |
| E2 | 126,071 | 48,697 | 77,374 | 133 / 260 | 127 | 5 only |
| E3 | 42,767 | 23,801 | 18,966 | 41 / 122 | 81 | 5 only |
| E4 | 149,332 | 53,649 | 95,683 | 193 / 288 | 95 | 5 only |
| E5 | 57,405 | 24,202 | 33,203 | 34 / 124 | 90 | 5 only |

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
| E1 | 133,034 | 138,523 | ~108,092 |
| E2 | 175,288 | 180,268 | — |
| E3 | 76,979 | 81,209 | — |
| E4 | 185,598 | 187,187 | — |
| E5 | 94,533 | 97,318 | — |

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

## Amendment, same day, still before any arm: the numbers moved by 414 bytes

The budgets first derived here were 79,093 / 125,657 / 42,354 / 148,910 /
56,992. They are now 414 bytes higher, each. The cause is recorded rather than
quietly overwritten:

The first derivation ran against **incomplete task descriptors**. Three fields
were missing, and each is a condition the preregistration requires to be
*identical across arms*:

- `task_id` — every capsule rendered as `Task UNNAMED-TASK`;
- `verification` — the capsule rendered "_no verification command was
  supplied — say so rather than inventing one_", so arm B would have had no
  verification command while arm A's prompt named one. That is an
  arm mismatch on a frozen field, not a cosmetic gap;
- `repo_wide_baseline` / `baseline_measured_at` — the capsule read
  "repo-wide: not measured" when it is measured and pinned.

Completing the descriptors grew every capsule's fixed base by exactly 414
bytes, so the rule — base + cost(priority 1..4) — returns a budget 414 higher.
**The admitted set did not change on any task**: same files, same per-rung
counts, same drop set of priority 5 only. That stability is the useful part:
the rule is a property of the ladder, not of the byte number, and completing
the descriptor did not let one extra file in.

## The baseline measurement command, named exactly

Establishing the work tree surfaced a second thing worth pinning. `tsc` reports
**781** errors at the seed under `tsconfig.json` and **754** under
`tsconfig.app.json`; the 27-error difference is entirely `*.test.ts` files,
which `tsconfig.app.json` excludes. The frozen baseline — "754 total at seed",
carried in TASK_FREEZE.md and in all five task descriptors — is the
`tsconfig.app.json` number, the one the repository's own `check:app` and
deploy gate use.

The measurement is therefore fixed, for both arms, as:

    npx cross-env NODE_OPTIONS=--max-old-space-size=4096 tsc --noEmit -p tsconfig.app.json

A work tree built from the seed reproduces the authoritative 754-error list
**exactly** under that command — zero extra, zero missing, after normalising
line/column and the repository path prefix — and the five clusters come back
at their frozen sizes: E1 15/6, E2 13/8, E3 8/8, E4 6/4 (the range form
`Expected N-M arguments`), E5 5/4. Had the other config been used, every task's
"total below the count at task start" criterion would have been measured
against a different denominator than the one the freeze records.

## What is NOT permitted from here

- Changing the budget, the rule, or the compiler after any arm has run.
- Re-deriving a budget per task after observing that task's arm A.
- Treating a large capsule as a reason to substitute or re-scope a task.

The parameter is now fixed for all five pairs.
