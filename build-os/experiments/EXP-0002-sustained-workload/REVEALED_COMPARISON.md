# EXP-0002 — Revealed comparison

## The reveal ceremony, verified

- Pre-committed at seal time (`916e1ae`): `analysis/MAPPING_SHA256.txt` =
  `457347674380dbe2989cff6c6675e462efe166155ff14727fc3088cc848ad5d9`.
- Blinded analysis committed with the mapping still absent from the tree.
- The mapping file entered the tree in THIS commit and hashes byte-exact to the
  pre-committed value. Mapping: **`raw = X` (Gravito OFF) · `buildos = Y` (Gravito ON)**.

## The blinded verdict, translated

The evaluator concluded **promising but underpowered, direction X** — under the
mapping: **at sequence level, Gravito OFF used 74.8% fewer total tokens per
durable accepted outcome than Gravito ON** (663,924 vs 2,631,154; uncached
agreeing at 78.8%; cost $2.25 vs $9.12; wall clock 451 s vs 1,977 s), with
10/10 acceptance and no confound clause fired — but only 3 of 5 per-task
differences agreed, below the preregistered 4/5 bar. The label is the honest
one: the aggregate is dominated by two tasks.

## The finding inside the heterogeneity — the substantive result

| Task | Gravito OFF | Gravito ON | Cheaper arm | What arm B actually did |
|---|---|---|---|---|
| T1 diagnose | 251,475 | **172,261** | **ON, by 31.5%** | light: 4 parent calls, 0 dispatches |
| T2 tested fix | **331,827** | 368,831 | OFF, by 10.0% | light: 9 parent calls, 0 dispatches |
| T3 feature | **1,260,714** | 4,944,069 | OFF, 3.9× | **FULL protocol: 5 subagent dispatches** (build-orchestrator, builder, qa, reviewer, archivist), $3.63, 849 s |
| T4 regression | 526,461 | **229,190** | **ON, by 56.5%** | light: 9 parent calls, 0 dispatches |
| T5 follow-up | **949,143** | 7,441,419 | OFF, 7.8× | **FULL protocol: 4 dispatches**, $4.80, 1,013 s |

**Gravito's overhead is not fixed — it is protocol-invocation-dependent.**
Where the installed surface stayed in light, direct behavior (T1, T2, T4), arm
B was competitive or clearly cheaper: T4 — the mid-sequence fix, the task where
accumulated repository context should matter most — cost **56% less with
Gravito installed**. Where the surface escalated into the full governed
multi-agent ceremony (T3's feature build, T5's follow-up), cost exploded 4–8×.

**The mode selector's descriptive verdicts, against hindsight** (recorded per
run, routed nothing): T1→direct, T2/T4/T5→gravito_light, T3→gravito_full.
Arm B's actual behavior matched on T1/T2/T4 (and won or tied there), matched
the selector's `full` on T3 (and lost — full ceremony on a bounded feature was
disproportionate), and **overshot on T5** (selector said light; the surface
went full, 4 dispatches, $4.80 against OFF's $0.55). A router that enforced
the selector's own verdicts would have avoided the two blowouts. That is
direct experimental support for the operator's direct/light/full routing
requirement — measured, not argued.

## Cumulative curves and the crossover (from the blinded analysis, unchanged)

Gravito ON was cumulatively cheaper after T1 and T2; the crossover ran the
OTHER way at T3 (the first full-ceremony invocation) and OFF stayed cheaper
through T5. On this task mix the fixed-overhead story inverts: ON wins the
early bounded tasks and loses the moment the ceremony fires.

## Obligations from the reviewer, discharged here

- `usage_block_disagrees` criterion: `yes` where |usage_block_total −
  modelUsage total| / modelUsage total > 2%; the ~550–600-token "no"-row deltas
  are the CLI's per-model input accounting, visible in both columns.
- Arm-B seed derivation: the same deterministic seeder produced both arms'
  trees (digest `128485c6…` verified twice by the reviewer by execution);
  arm B's pristine baseline was diffed against a fresh seed — content-identical
  outside the installed surface, `package.json` differing only by the
  installer's added script line.
- Reveal executed promptly; the mapping hash verified before translation.

## What this does not say

One sequence per arm, five paired points, one synthetic-but-ordinary
repository, one model configuration, headless-only. The weekly-usage meter was
unobservable here and no claim about it is made. Arm order was A-then-B; cache
warmth (named confound C2) cannot explain the result — the uncached comparison
agrees in direction, and arm B's two blowouts are output/dispatch-driven, not
cache-driven.
