# EXP-0012 — parallel experiment infrastructure (#53). BUILD NOW, CALIBRATE AFTER EXP-0011.

**Rule this build honors: EXP-0011's files are mid-study frozen — nothing
here imports from, edits, or invokes that study's runner or executor. This
infrastructure targets FUTURE runners, which must honor `ARM_TREE` /
`ARM_LOCK` environment overrides. Validation (which spawns sessions and
contends for CPU) waits for the post-EXP-0011 window.**

## The dependency insight (from EXP-0011's structure)

Order is load-bearing only WITHIN a treated chain: (sequence, rep, treated
config) — position k+1 needs position k's distillation. Everything else is
independent: native arms entirely, sequences from each other, reps from each
other, treated configs from each other. A 60-arm three-way study is 8
five-arm serial chains + 20 independent arms; run W-wide its wall-clock is
the critical path (~1 chain), not the sum.

## Components

- `worker-pool.mjs` — provisionTree(n): seed-restore into
  `/home/user/exp-arm-w<n>` with per-worker lock `/home/user/.exp-locks/w<n>.lock`;
  runDag(chains, independents, {width, spawn}): a DAG scheduler that assigns
  each ready cell to a free worker, threading `ARM_TREE`/`ARM_LOCK` env to
  the spawned runner. Chains advance only on their own admissible completion
  (same one-retry semantics as the executors); independents fill idle
  workers. Event-driven (child exit), no polling, no timers.
- `probe-arm.mjs` — a minimal calibration arm: native-only, parameterized
  tree/lock via env, same seed/model/grants/ceiling/economics capture as the
  real runners, task = a small fixed cell. Exists so calibration measures the
  ENVIRONMENT (serial vs wide), not any study's treatment.
- `calibrate.mjs` — the gate the operator set: the same probe task run R
  times serial then R times W-wide. PRECOMMITTED equivalence rule (stated
  here, before any data): widths pass if (a) median elapsed differs by <15%,
  (b) median cost differs by <10%, and (c) a rank-sum test (normal
  approximation) does not reject at alpha=0.05 for elapsed. Fail => halve W
  and re-run, or restrict parallelism to studies where speed is not a scored
  dimension. Cache note: concurrent same-prefix sessions may SHARE warmth —
  direction unknown, which is why this is measured, not assumed.

## What adoption looks like

A future study's runner reads `ARM_TREE`/`ARM_LOCK` from env (defaulting to
the shared tree), its executor expresses its plan as chains+independents, and
its preregistration names the calibrated width. Nothing else changes:
pinned administration, per-arm preflights, provenance gates, admissibility,
and the read all work per-tree exactly as they do per-the-shared-tree.
