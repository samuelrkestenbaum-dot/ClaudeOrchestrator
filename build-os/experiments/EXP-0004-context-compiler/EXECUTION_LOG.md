# EXP-0004 — execution log

Written as the run proceeds, not reconstructed afterwards. It records what the
harness did, what broke, and what was seen before it broke. Nothing here
discloses the sealed X/Y mapping.

## Fixture, stated once

Both arms run as a fresh headless `claude -p` session (`claude-fable-5`) with
identical permissions, identical appended operating instruction, and identical
work tree. The **only** difference between arms is which file is handed over as
the prompt: arm A receives the task definition; arm B receives the rendered
capsule verbatim.

The work tree is a detached clone of `empathiq-website` at the seed, with
`.claude/` and `CLAUDE.md` **sparse-excluded**. That exclusion is load-bearing
and applies to both arms: the natively installed Build OS injects a capability
inventory and a routing reminder at SessionStart and on every prompt, which is
broad context. Left on, it would have made every arm B start with the capsule
**and** an injected payload — `result confounded` on all five pairs, by
AMENDMENT 2's mechanical check, before a single measurement was worth reading.

Baseline is measured **inside each arm at that arm's start**, because criterion
(b) is "strictly below the count at task start". It is never assumed from the
freeze.

## Attempt 1 of pair E1 — VOID (harness defect, no treatment delivered to arm B)

### Defect 1 — the prompt was passed as a command-line argument

Arm B died before its session existed:

    /usr/bin/timeout: Argument list too long        (exit 126)

Linux caps a *single* argument at `MAX_ARG_STRLEN` = 131,072 bytes. Three of
the five arm-B capsules exceed it:

| task | arm-B prompt bytes | vs 131,072 |
|---|---:|---|
| E1 | 133,034 | **over** |
| E2 | 175,288 | **over** |
| E3 | 76,979 | ok |
| E4 | 185,598 | **over** |
| E5 | 94,533 | ok |

Left undetected this would have produced three empty arm-B runs out of five,
each of which *looks* like a completed arm: exit code captured, tree clean,
oracle willing to score it. Arm B's record for E1 read "0 files touched, 15
cluster errors remaining" — a treatment that was never administered would have
been scored as a treatment that failed.

**Fix:** the prompt is delivered on **stdin**, in **both** arms, so the
mechanism cannot vary by arm or by prompt size. Verified against the CLI before
re-running.

### Defect 2 — criterion (d) was evaluated with no baseline

The frozen criterion is *"any test covering a touched file still passes at **its
measured baseline**"*. The first oracle measured no baseline: it ran the
covering tests after the arm and failed the criterion if anything failed. On
E1's covering set, **4 tests already fail at the seed**. Every one of them would
have been charged to the arm.

This is the PILOT-0002 false-positive shape in a new disguise — there, a naive
sorted diff reported 21 "new" errors that were line-shifted pre-existing ones.
The lesson transferred to error counting and was not transferred to test
counting.

The selection rule was also far too loose. It matched a test file if the touched
file's **basename** appeared anywhere in it inside quotes or after a slash;
basenames like `index`, `router` and `guardian` are everywhere, so a six-file
change selected **45 test files and 409 seconds** of vitest.

**Fix, both halves:**

- Selection is now: same-directory same-stem sibling, **or** a relative
  `import` / `require` / `vi.mock` specifier that *resolves* to the touched
  path. On the same six-file change that selects **8 files in 25 seconds**, and
  each carries its reason (`sibling of …` / `imports …`).
- The baseline is measured per test, at the seed, in a **pristine clone no arm
  touches**, cached across arms, from vitest's JSON reporter. Criterion (d)
  fails only when a test that **passed at the seed** fails after the arm.
  Tests already failing at the seed are reported separately as
  `failing_at_baseline_too` and charged to nobody.

### What was observed before the fix, disclosed rather than buried

Arm A of attempt 1 ran to completion and its numbers were seen. They are
recorded here so that a re-run cannot be mistaken for a first look:

- 58 turns, ~912 s of API time, `end_turn`, no error
- uncached 104,516 tokens (in 86 + cache-creation 104,430); cache read
  3,721,789; output 35,078
- tsc 754 → 736; cluster 15 → 0; 0 new errors line-insensitively; 6 files
  touched; 0 `any`-casts or suppressions

Its criterion-(d) verdict from attempt 1 is **void, not "fail"** — it was
produced by the defective oracle described above.

### Disposition, and why it is not the "never repaired and re-run" case

AMENDMENT 2 says a pair whose **arm B starts with broad context AND the
capsule** is registered `result confounded` and *"is not silently repaired and
re-run"*. That rule governs a **contaminated treatment**. This is not that: arm
B's session never started, so no treatment was delivered and no arm-B
measurement exists to contaminate. The distinction is named here rather than
assumed.

The whole pair is re-run under the corrected harness, both arms, so the two
arms share one delivery mechanism and one oracle. Attempt 1's artifacts are
kept at `pairs-out/E1-attempt1/` and are **not** admitted to the aggregate.

Nothing was changed in response to what was seen: not the seed, not the task
set, not the capsule budget, not the acceptance criteria, not the arm order.
The two changes are a prompt-delivery mechanism and an oracle that measures the
baseline its own criterion names.
