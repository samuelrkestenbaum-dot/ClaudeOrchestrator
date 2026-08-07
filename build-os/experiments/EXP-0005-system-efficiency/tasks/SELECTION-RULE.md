# Task selection rule — recorded BEFORE any candidate was examined

A rule written after seeing candidates is not a rule; it is a description of
choices already made. This is committed first, and the selection that follows is
mechanical.

## Candidate pool, enumerated at seed `2543c87`

Mechanically counted, no candidate inspected:

| shape | population | query |
|---|---:|---|
| type/interface defects | 754 | `tsc -p tsconfig.app.json`, grouped by TS code |
| test-reliability defects | 230 | `it/test/describe.skip\|todo` blocks |
| suppression defects | 124 | `@ts-ignore` / `@ts-expect-error` / `@ts-nocheck` |
| implementation gaps | 10 | `TODO` / `FIXME` / `HACK` markers |
| behavioural defects | *pending* | failing tests, from a full suite run |
| integration/config defects | *pending* | 6 tsconfigs, 62 npm scripts |

## Shape quota — the anti-monoculture rule

**No more than 3 of the 10 tasks may come from any single shape**, and **no more
than 2 may share a TypeScript error code.** EXP-0004 was five variants of one
pattern and could not distinguish "the compiler helps with type errors" from
"the compiler helps". This quota is the correction.

## Selection, per shape

1. Enumerate the shape's population by its query.
2. **Sort deterministically** — by file path, then line number. No ranking by
   size, difficulty, familiarity, or expected outcome.
3. Walk the sorted list from the top; take the first candidate that passes
   every admission test below.
4. Stop at the shape's quota.

**Sorted order is chosen precisely because it is uninformative.** Any ordering
that reflects a property of the task is an ordering that could be tuned.

## Admission tests — a candidate must pass ALL

- **Pre-existing** — present in standing work at the seed, not authored for the
  benchmark.
- **Independent** — solving it does not mechanically solve another selected
  task. Two errors in the same function fail this.
- **Bounded** — plausibly completable well inside the frozen 5400 s ceiling.
- **Objectively acceptable** — success determinable by a command, not a
  judgement call.
- **Not previously exposed** — see leakage below.

## Leakage check — against the FIXED inventory

Every candidate is checked against the pinned durable state — **132 receipts, 6
memory files, 3 packets** — and must show:

- no receipt recording an identical or equivalent completed task;
- no memory artifact containing the required patch;
- no prior benchmark output exposing the answer;
- no exposure through EXP-0004, PILOT-0001/0002, compiler-v1 development,
  calibration, or this session's debugging.

**The check is deliberately biased toward exclusion.** A grep across 132
receipts produces false positives — a receipt touching a file for unrelated
reasons — and false negatives — a receipt describing a fix without naming the
path. Over-excluding costs a candidate from a large pool. Under-excluding admits
a task that measures **recall rather than capability**, in the direction that
flatters the arm with memory. Every exclusion is recorded with its reason.

**Contamination excludes the TASK. It never purges the MEMORY.** Purging
legitimate repository knowledge to make Gravito look fresh would replace the
system under test with one nobody would ship.

> **Digest reference, corrected.** This rule originally named durable-state
> digest `7de42dd1c5a779a257645a0deecea2d8292b8501f84832e8c21cf65542e76ae6`.
> That value proved **unreproducible** — its combination step was never
> recorded, and sixteen candidate methods failed to recompute it against the
> unchanged tree. The pinned state is now `3311a638…` by the method defined in
> `memory/SEED-PIN.md`.
>
> **No selection criterion changed.** The state being checked against is
> identical: the same 132 receipts, 6 memory files and 3 packets, whose
> per-class digests reproduce exactly. Only the identifier's arithmetic
> changed, from one nobody could verify to one anybody can. The original value
> is left recorded above rather than deleted, so the correction is visible.

## Hard exclusions, no check required

- E1–E5 (EXP-0004's frozen set) and PILOT-0001/0002 T1–T5;
- anything under `build-os/`, `.claude/`, or another governance path — those are
  the substrate itself;
- anything this session has already diagnosed or discussed.

## Acceptance, frozen per task before execution

Each task carries: the objective; a verification command; the expected result;
a regression bound; and the standing prohibition on `any`-casts, suppressions
and fabricated interfaces used to silence rather than fix. **Identical across
both conditions** — the arms differ in context, never in what counts as done.
