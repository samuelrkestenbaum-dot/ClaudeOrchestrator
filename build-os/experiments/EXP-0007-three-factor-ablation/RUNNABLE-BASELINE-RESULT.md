# The clean normal-runtime baseline — FROZEN, and the fork taken

**48 arms, 2×2 (native/gravito × starved/runnable), T01–T04 × 3 reps, one
harness, one seed, identical grants per condition. 47 admissible, 47/47
accepted. Raw read: `results/runnable-baseline-read.txt` (regenerate with
`study-read.mjs`).**

The fork was precommitted before any arm ran (`runnable-baseline.convergence.json`),
the environment was proven by a six-condition preflight from executed streams,
and stop condition S1 was declared before the result was known. This document
takes the fork; it does not renegotiate it.

## Verdict

**The gap holds materially above 2×. Per the precommitted fork: stop
re-baselining. Redesign the interaction model. LEAN_MANIFEST is the work.**

S1 is now recorded SATISFIED in `build-os/motion/program.json`. Any further
baseline refinement is mechanically refused by the convergence gate unless a
measurement-invalidating defect — proof the test did not measure what it
claimed — is shown. A new plausible causal hypothesis is not grounds.

## The fork metrics (task-paired means, within one harness)

| | gap starved | gap runnable |
|---|---|---|
| **cost USD** | 3.03× | **2.44×** |
| **uncached tokens** | 2.78× | **2.12×** |

Per task, cost: T01 3.60→3.07, T02 4.32→2.58, T03 2.07→2.44, T04 2.12→1.66.

**Separation (gravito.runnable vs native.runnable, three reps each side):**
cost separates on **4/4 tasks** — every gravito rep above every native rep —
p = 1.3e-5 two-sided. Uncached, turns, and text-only turns each separate 3/4.

## Censoring makes these numbers FLOORS

Every censored observation is a gravito-runnable observation:

- T01.corrected.runnable rep2 hit the 1200s ceiling **twice** (original + refill)
  — both with `accepted=true`, meaning the product work was done and what ran
  past the ceiling was everything after. The cell freezes at n=2; a third
  attempt would be selection bias (re-rolling until a fast draw passes).
- Two more gravito-runnable arms finished at 81% and 89% of ceiling.
  Native-runnable's worst was 60%. Native-starved's worst was 32%.

Right-censoring removes only the gravito tail, so the true runnable gap is
**at least** 2.44× / 2.12×.

## Capability starvation was a real amplifier — and not the cause

The operator's hypothesis was half right, and the halves are now separated:

| mechanism (per arm) | gravito starved | gravito runnable | native runnable |
|---|---|---|---|
| exhaustion references | 4.5 | **1.0** | 0.0 |
| bookkeeping + gate round-trips | 8.1 | **4.6** | 0.0 |
| implementation reads | 4.8 | **2.0** | 0.0 |
| text-only turns | 16.3 | **11.5** | 4.8 |
| final reports | 2.6 | **2.4** | 0.7 |
| turns | 47.2 | 37.7 | 23.2 |

A healthy environment cut the control-transaction tax by roughly a third and
nearly eliminated exhaustion litigation. **What remains is the interaction
model itself**: even with verification working, the worker still writes 2.4
final reports to native's 0.7, runs 4.6 control round-trips to native's zero,
and spends 11.5 text-only turns to native's 4.8. That residual keeps Gravito
at 2.44× — not in the 1.2–1.5× neighbourhood the contraction branch required.

Verification behaviour confirms the environment worked: native.runnable 5.3 and
gravito.runnable 6.4 verification calls/arm, compiler output consumed in both.

## Study-quality notes, stated rather than smoothed

- **Native's own spread is now measured for the first time** (12 native-starved
  reps): cost CV 5–24% by task. Every prior ratio in this program divided by a
  single unreplicated native observation; this study's ratios divide by n=3
  task-matched cells in the same harness.
- **Cross-harness caution**: this harness's native-starved cells came out
  cheaper than EXP-0006's native arms (e.g. T03 $0.86 vs $1.07 mean here under
  a different draw). All 2×2 comparisons here are within-harness; no
  cross-harness ratio is quoted.
- **T03's gap widened slightly under runnable** (2.07→2.44) while T04's
  contracted most (2.12→1.66). With n=3 per cell these per-task movements are
  within the spread; only the aggregate direction and the 4/4 separation are
  load-bearing.
- The 1200s ceiling is unchanged, frozen apparatus. Its censoring effect is
  reported above and biases against the conclusion drawn, not toward it.

## What happens next (and what does not)

- **LEAN_MANIFEST**, designed against `build-os/design/TARGET-OPERATING-MODEL.md`:
  every row names the measured worker-control interaction it removes (by Step 2
  class) and the substrate-side mechanism replacing it. Context-only rows fail.
- The decisive follow-up test is **Native vs Current vs Lean** under THIS
  environment and THIS preflight prover — the apparatus is reusable as-is.
- **No more baselines.** S1 is satisfied and the gate refuses them.
