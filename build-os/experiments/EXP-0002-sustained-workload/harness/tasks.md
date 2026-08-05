# EXP-0002 — frozen task prompts (harness v1.0.0)

FROZEN BEFORE RUN 1. These five prompts are the task text, verbatim, and are
**byte-identical across both arms** — the only difference between arms is the
installed surface, never the words. `run-exp2-task.sh` extracts each prompt
mechanically from the first fenced block of its section (so what is documented
here is, by construction, what is sent). No hints, no "think step by step", no
mention of any oracle, no prompt tuning.

The prompts deliberately name only what a developer would reasonably say:
T1 does not name the file, T2 leans on the artifact T1 left behind, T4 and T5
lean on artifacts already in the tree (`test/regression-t4.js`,
`FOLLOWUP-T5.md`). Continuity across tasks must come from the repository —
every task runs in a FRESH headless session.

## T1 — diagnose

```
One of this project's pricing computations disagrees with its own specification comment for at least one realistic input. Find it, and write DIAGNOSIS.md at the repo root naming the file, the function, the exact line's behaviour, and one concrete input where behaviour and specification disagree. Change no code.
```

## T2 — tested fix

```
DIAGNOSIS.md documents a defect. Write a failing test that reproduces it, confirm it fails for the right reason, fix the defect, and make the full suite green (`node test/run.js`).
```

## T3 — feature

```
Implement SPEC-T3.md exactly, including worked examples and error cases. Full suite green when done.
```

## T4 — regression

```
A test file test/regression-t4.js was just added and fails. Make the whole suite green without weakening or deleting the new test.
```

## T5 — follow-up

```
Complete the task described in FOLLOWUP-T5.md. Full suite green when done.
```
