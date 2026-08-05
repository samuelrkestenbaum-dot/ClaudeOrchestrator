# EXP-0001 — Preregistered protocol: does Gravito reduce total model tokens per durable accepted outcome?

**Status: PREREGISTERED. Committed before any experimental run. Not revisable after run 1.**

Operator instruction (2026-08-05): design and execute a controlled experiment to
determine whether Gravito materially reduces `total model tokens per durable
accepted outcome`, using the existing frozen task corpus unaltered, with
provider-native telemetry, paired alternating-order runs, sealed records, a
blinded independent evaluator, and a conclusion drawn from a fixed four-option
vocabulary. This document is output 1 of 5 (protocol, immutable run records,
blinded analysis, revealed comparison, conclusion).

## 1. The instrument, run — not modified

Every run uses the frozen harness exactly as committed at HEAD
`0ddf0b6ef7a4d42324ca3dc596afa14e3384901f`:

- seeder `bench/seed-bench-repo.sh` — expected
  `tree_digest_sha256: bb52f7b5ebbfc918b005a17a594279557a6249f8a94ba9163dcd70d9462614c2`
  on every run; a mismatch voids the run (recorded, labeled, excluded from the
  primary metric, retained in the dataset).
- runner `bench/run-corpus.sh` — task text, oracle, poller, telemetry
  extraction all frozen. No task, prompt, acceptance criterion, or fixture is
  altered. No file under `bench/` is edited by this experiment.
- corpus v1.0.0, instance v1.0.0.

The runner itself implements the two arms this experiment needs; nothing is
hand-rolled:

| operator's arm | runner flag | definition (runner's own) |
|---|---|---|
| **A — Gravito OFF** | `--arm raw` | the seeded repo untouched: no CLAUDE.md, no `.claude/`, no lanes, no router, no packets, no receipts, no memory, no context compilation |
| **B — Gravito ON** | `--arm buildos` | the product installed by its own shipped installer (`install-project.sh --no-session-hook`) into the identical seeded tree |

Relation to the frozen `build-os/metrics/COMPARISON_PROTOCOL.md`: that document
is NOT this experiment and is not modified. Its two stated blockers (no
scriptable invocation; no addressable agent dispatch) were executed FALSE on
2026-08-05 (`claude -p` with native telemetry; `Agent` dispatch observed in CLI
2.1.222). Its primary endpoint (wall-clock on T3, human clock-holder) remains
un-run: T3 is IMPOSSIBLE canonically in this environment (below). This
experiment preregisters a different, token-denominated primary on the task that
IS canonically runnable, and does not claim to be the 16-run human-operated A/B.

## 2. Task applicability — stated before run 1

The headless agent is denied the Bash tool (`acceptEdits`; `bypassPermissions`
refused as root — executed findings, frozen in `bench/BASELINE_LIMITS.md`).
Therefore:

- **T1 — APPLICABLE, canonical.** Requires no suite execution by the agent
  (`suite_execution_gate: not_applicable`).
- **T2, T3, T4 — NOT APPLICABLE canonically.** Their corpus clauses require the
  agent to execute the suite. Each produces the runner's REFUSAL record (no
  numbers, `canonical_comparison_eligible: false`), one per task per arm — six
  refusal records, which **remain in the dataset** as the operator's rule
  requires ("failed or refused runs remain in the dataset").
- **No degraded runs are taken.** RULING 2 (frozen) bars degraded records from
  any canonical A/B comparison, so a degraded pair could not serve the primary
  metric; spending tokens to produce inadmissible numbers is refused here, in
  advance.

Consequence, stated plainly: this experiment measures Gravito's token effect on
**one task class** (small, single-file, no-suite-execution correction). Any
conclusion is scoped to that class. This cap is preregistered, not discovered.

## 3. Design

- **5 paired replicates of T1** = 10 runs total (operator: ≥3, prefer 5).
- **Alternating order by pair**: pair 1 A→B, pair 2 B→A, pair 3 A→B,
  pair 4 B→A, pair 5 A→B. Runs are sequential, never concurrent.
- **Fresh everything per run**: new seeded tree from the frozen seeder, new
  headless session (`claude -p` holds no conversation state), no artifact of
  any run visible to any later run. Cross-run provider-side prompt caching
  cannot be disabled from this harness; it is measured instead (§6, confound C2).
- **Model**: CLI default, matching the frozen baseline
  (`claude-sonnet-5+claude-haiku-4-5`, CLI 2.1.222). `model_used` is read from
  provider telemetry per run; if any run's `model_used` differs from any
  other's, the affected pair is labeled `model_mismatch`, excluded from the
  primary metric, and retained in the dataset.
- **Caps**: runner defaults — `--timeout 3600` (a timed-out run is a failed
  run, retained), `--poll 5` (TTFCC resolution 5 s, an upper bound).
- **Command per run** (only TASK/ARM/N/OUTDIR vary):
  `bash bench/run-corpus.sh --task T1 --arm {raw|buildos} --run N --poll 5 --outdir <experiment run dir> --keep`
- The runner's own working-tree artifacts are preserved (`--keep`) long enough
  to seal the record, result JSON, stream log, and diff evidence; bulky trees
  are then deleted, sealed artifacts are not.

## 4. Telemetry — the operator's schema, mapped field by field

Provider-native only. Nothing is estimated from character counts. A field the
provider or harness cannot establish is written `unavailable` (or the harness's
`-`), never 0.

| operator field | source |
|---|---|
| run_id | `exp0001_t1_pN_{A\|B}` (pair N, arm) — assigned before the run |
| corpus_version / task_id / arm | run record (`corpus_version`, `task`, `arm`) |
| model_provider / model_id / model_version | Anthropic; `model_used` from result JSON `modelUsage` keys; CLI version recorded (finer version granularity than the model string: **unavailable**) |
| starting_repository_sha | **unavailable** — the seeded fixture is not a git repository; its identity is `tree_digest_sha256` (recorded, must equal `bb52f7b5…`) |
| ending_repository_sha | **unavailable** — same reason; ending identity = sealed diff artifact sha256 |
| input/output/cache_read/cache_write tokens | result JSON `usage.*` (cache_write = `cache_creation_input_tokens`) |
| total_tokens | derived: input + output + cache_creation + cache_read (components always reported beside it; see §5 for the cache-free variant) |
| model_calls | `num_turns` |
| tool_use_events / tool_result_events / tool_failures | the runner's two independent structural witnesses (DISAGREE reported, never reconciled) |
| wall_clock_seconds | runner's own clock |
| time_to_first_correct_change | oracle-polled upper bound, 5 s resolution |
| human_interventions | `-` per the frozen field discipline; noted: the run is unattended by construction, but "nobody was watching" is recorded as an admission, not a zero |
| rework_rounds | `-` — not decidable from the tree; a model's self-report is excluded |
| tests_run / tests_passed | `final_suite` line (harness-executed, external to the agent) |
| post-close defects | `-` — nobody keeps looking after the run |
| accepted_outcome | hidden-oracle verdict, executed externally (`accepted: yes/no`) |
| durable_receipt_id | path of the sealed, committed run record + its sha256 in the manifest |

## 5. Primary metric and decision rule — fixed before run 1

**Durable accepted outcome** := the run's hidden-oracle verdict is `accepted:
yes` AND its full record is sealed and committed. (The oracle executes the
acceptance check against the tree; nothing is self-reported.)

**Primary metric**: per arm, the **median of `total_tokens` over runs that
produced a durable accepted outcome**. Reported beside it, always:

- the full range per arm (never a point estimate alone);
- the same median computed **without** `cache_read_input_tokens`
  (`tokens_uncached = input + output + cache_creation`) — the caching confound
  is separated by computing both, not by hand-waving;
- acceptance rate per arm; aggregate efficiency (all tokens spent in the arm,
  including failed runs, divided by the arm's accepted-outcome count);
- secondary/exploratory: cost USD, wall-clock, TTFCC, model_calls, tool events.

**Decision rule** (the operator's suggested 25% threshold, adopted as a
decision rule, not a statistical law — with N capped at 10 runs on one task,
below the operator's 12–20 sketch; that shortfall is stated here, in advance):

1. **result confounded** — declared first, before any magnitude reading, if
   any of: `model_used` differs across arms after exclusions; accepted-outcome
   count per arm < 3; the total-tokens comparison and the uncached-tokens
   comparison point in OPPOSITE directions; or the seeded tree digest ever
   mismatched.
2. **causal effect supported** — the arms' accepted-run `total_tokens` ranges
   do not overlap AND the median difference is ≥ 25% AND the uncached
   comparison agrees in direction. Direction is reported with the conclusion
   (this rule is symmetric: it can support "Gravito increases tokens").
   Scope statement mandatory: one task class, one repository, one model, N=5
   pairs.
3. **promising but underpowered** — median difference ≥ 25% in either
   direction but the ranges overlap.
4. **no meaningful difference detected** — median difference < 25%.

The prior evidence (an observed weekly usage drop) is treated as prior, not
proof, and does not enter the rule.

## 6. Named confounds, separated in advance

- **C1 — fewer completions**: acceptance rate is reported per arm; the
  per-outcome metric divides only by durable accepted outcomes, and rule 1
  refuses a comparison with < 3 accepted per arm.
- **C2 — caching**: provider-side prompt caching across sequential runs cannot
  be disabled from this harness and is expected to favor whichever arm re-sends
  a stable prefix (Gravito's installed surface is exactly such a prefix). Both
  arms alternate identically; `cache_read` is reported per run in sequence
  order, and the uncached-token comparison is computed alongside the total. If
  the two disagree in direction, rule 1 fires.
- **C3 — worse quality**: acceptance is external (hidden oracle) and identical
  across arms; the oracle's known bound (a different false claim would also
  accept — `bench/BASELINE_LIMITS.md`) applies equally to both arms.
- **C4 — more human intervention**: structurally zero on both arms (unattended
  headless runs); recorded `-` per the field discipline.
- **C5 — order/learning**: no session state carries across runs; order still
  alternates by pair so any residual time-ordered drift (provider load, cache
  warmth) is distributed across arms.

## 7. Blinding

1. After all runs: every run's `run_record.txt`, `result.json`, and diff
   evidence is sealed under `runs/` with a sha256 manifest, and committed.
2. A blinded dataset (`analysis/blinded_dataset.tsv`) is derived: one row per
   run, arms relabeled **X/Y**, every arm-identifying string scrubbed. The
   arm→label mapping lives in a file whose **sha256 is committed with the
   blinded dataset**, while the mapping file itself stays outside the
   repository until reveal.
3. An **independent evaluator session** (a fresh agent context that has not
   seen this conversation, given ONLY the blinded dataset and §5's rule text
   with arms as X/Y) computes the medians, ranges, and rule outcome, and its
   analysis is committed **before** the mapping is revealed.
4. Reveal: the mapping file is committed and must hash to the pre-committed
   sha256; the revealed comparison and the conclusion follow in that commit.

**Blinding limit, stated in advance**: relabeling prevents label-driven bias in
the computation, but an evaluator who knows Gravito installs context could
infer the arm from its token signature (larger cache traffic). The mitigation
is that the evaluator applies a preregistered mechanical rule to numbers —
there is no judgement call left for the inference to lean on. The experiment's
author also cannot be blinded to what he built; the sealed records and the
mechanical rule are the mitigations, the same ones the frozen protocol names.

## 8. Frozen-during-experiment rule

No optimization of Gravito or of the benchmark occurs during the experiment.
Any defect discovered mid-experiment is recorded for later, the affected run is
labeled, and the experiment machinery stays frozen. No prompt, task, oracle,
seeder, or runner edit. No push without explicit operator go.

## 9. Outputs and their order (each later output cites the earlier commit)

1. this preregistration — committed before run 1;
2. immutable sealed run records (`runs/` + manifest) — committed after run 10;
3. blinded analysis (`analysis/BLINDED_ANALYSIS.md`) — committed before reveal;
4. revealed comparison (`REVEALED_COMPARISON.md`, mapping verified by hash);
5. conclusion (`CONCLUSION.md`) — exactly one of: `causal effect supported` |
   `promising but underpowered` | `no meaningful difference detected` |
   `result confounded`, with direction and scope.
