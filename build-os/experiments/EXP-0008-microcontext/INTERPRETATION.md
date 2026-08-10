# What the ~2.4× actually measures — operator ruling, recorded

**No prior result is revised, subtracted from, re-run, or re-adjudicated by this
document.** EXP-0006's headline (18.15 vs 10.36 UIC, 12/12 tasks, p=2.4e-4) and
the frozen corrected baseline (cost 2.43× native, turns 1.55×) stand exactly as
measured. This records what they mean, and what they do not.

## The ruling

> The current ~2.4× cost ratio is a valid measurement of Gravito under the
> administered capability-starved environment. It should not be treated as a
> general estimate of Gravito economics, because the primary verification command
> cannot execute on that host, and Gravito's concession/capability-exhaustion
> behaviour amplifies that environmental restriction.

- **Native is cheaper partly because it gives up sooner** when the verification
  capability is unavailable.
- **Gravito is more expensive partly because it keeps searching** for evidence
  that the capability is genuinely unavailable.
- **Neither behaviour is called better** without a runnable-verification
  comparison.

## The measured basis for the ruling

From `STEP2-TEXT-TURNS.md`, all from stored streams:

- `authority_blocked` is **1.00 turns/arm in NATIVE** — the starvation is not a
  Gravito artifact, it is the host, and it hits both arms.
- 77% of Gravito's 11.83 excess text-only turns/arm is one loop: concession gate
  refuses the stop → capability search → read the gate's own source → bookkeeping
  → re-report. Native writes 1 final report/arm; corrected writes 2.58, with
  11/12 arms writing more than one.
- The loop **substituted drivers** rather than disappearing when the contamination
  was removed — queue-dominant in 23/24 contaminated arms, exhaustion-dominant in
  11/12 uncontaminated arms.

## Confirmed cause of the starvation

The worker is launched `--permission-mode acceptEdits` with **no `--allowedTools`**,
headless. Edits auto-accept; every `Bash` call prompts; no approver exists.

**A worker's own diagnosis was wrong and is not adopted.** `T04.corrected.r2`
concluded the cause was the `node_modules` symlink pointing outside the sandbox.
It is not: preflight gates `node_modules/typescript` as present, and the harness
itself executes `npx tsc --noEmit -p tsconfig.json` from the same directory at
`run-arm.mjs:178`. The compiler is runnable there. Only the permission layer
blocks the worker.

## Status of the T03 observation

`T03.corrected` — the one arm of twelve where the gate did not refuse the stop —
cost 1.28× native (23 turns/$1.10 vs 25 turns/$0.86).

**This is hypothesis-generating only. n=1, one task.** It is not evidence of
normal Gravito cost and is not quoted as such. Its only role is to make the
environment interaction a serious hypothesis worth spending arms on.

## What must not happen next

- Do **not** optimise Gravito against the capability-starved loop before the
  runnable-verification comparison is complete.
- Do **not** draw or implement LEAN_MANIFEST first.
- Do **not** manufacture a corrected ratio by subtracting estimated loop turns
  from the measured baseline.

## The decision rule, fixed before the data

Declared in advance so the result cannot be read to taste:

- **If the gap contracts materially with runnable verification** — capability
  starvation is a major interaction effect, and LEAN_MANIFEST targets the
  remaining normal-runtime overhead rather than the starved-loop behaviour.
- **If Gravito stays around 2×+ despite runnable verification** — the
  interaction-model problem is structural, and the lean redesign proceeds against
  that clean baseline.
