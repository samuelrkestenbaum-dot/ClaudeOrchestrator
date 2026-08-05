# EXP-0001 — Revealed comparison

## The reveal ceremony, verified

- Pre-committed at seal time (commit `d2373e6`, before any analysis existed):
  `analysis/MAPPING_SHA256.txt` = `0a4b66a142ced55bde866cd16283540643f68a2dfd6f3a231ba188b3b9fd08ec`.
- Blinded analysis committed at `7d56cbc` with the mapping still absent from the tree.
- Mapping file entered the tree in THIS commit and hashes to exactly the pre-committed
  value (`sha256sum analysis/blind_mapping.txt` → `0a4b66a1…`, byte-identical).
- Mapping: **`raw = Y` (arm A, Gravito OFF) · `buildos = X` (arm B, Gravito ON)**.

## The blinded verdict, translated

The evaluator — blind, mechanical, rule-bound — concluded **causal effect supported,
condition Y lower**. Under the revealed mapping that reads:

> **On task T1, Gravito OFF consumed 50.8% fewer total model tokens per durable
> accepted outcome than Gravito ON.** The supported causal effect is that installing
> Gravito INCREASED token consumption on this task class — the opposite direction
> from the hypothesis under test.

| Metric (accepted runs, n=5 each) | Gravito ON (X, buildos) | Gravito OFF (Y, raw) |
|---|---|---|
| total_tokens — median (range) | 312,444 (311,164–357,979) | **153,611** (153,056–227,089) |
| tokens_uncached — median (range) | 19,753 (19,195–20,347) | **11,802** (11,031–39,090) |
| total_cost_usd — median | 0.2305 | **0.1252** |
| wall_clock_s — median | 35.17 | **24.25** |
| model_calls — median | 10 | **7** |
| acceptance | 5/5 | 5/5 |
| aggregate tokens per accepted outcome | 330,129 | **175,029** |
| tool_failures (total across runs) | 16 (2–4 every run) | 0 |

Every preregistered confound check passed: identical model string on all 10 runs,
identical seed digest, 5/5 acceptance in both arms (quality is not the difference),
and the cached and uncached comparisons agree in direction — the effect is not a
caching artifact. The ranges are fully disjoint; the worst OFF run (227,089) used
fewer tokens than the best ON run (311,164).

## Mechanism observations — exploratory, NOT preregistered, labeled as such

- The ON arm logged tool failures in every single run (16 total) against zero in the
  OFF arm. The installed Build OS surface instructs protocol behavior whose tool
  attempts this headless environment (Bash denied) refuses; each refusal costs turns
  and tokens on a task too small to amortize any of it.
- The ON arm's larger installed surface shows up exactly where it should: higher
  cache_creation (~18k vs ~10.5k), higher cache_read (~292–338k vs ~141–216k), and
  3 extra median model calls.
- The frozen `COMPARISON_PROTOCOL.md` predicted this loss case in its own run-count
  section: "T1 is the task this system loses on." A governance system carrying
  overhead on a task with nothing to govern was the expected failure mode; this
  experiment measured it at ~2× tokens.

## What this result does NOT say — the boundary is part of the finding

- It says nothing about T2–T4: the multi-step, suite-executing tasks where memory,
  packet context, and receipts could plausibly pay for themselves produced NO numeric
  data in either arm (deterministic environmental refusals, retained in the dataset).
  The task classes where Gravito's value proposition actually lives are exactly the
  ones this environment cannot yet run canonically.
- It does not refute (or confirm) the observed weekly usage drop, which remains prior
  evidence about a different workload — long-horizon, multi-session, memory-reusing
  work, not 30-second single-file fixes.
- It is N=5 pairs, one task class, one repository, one model configuration, one
  headless permission regime.
