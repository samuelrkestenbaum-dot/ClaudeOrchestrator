# Build OS — fixed task corpus

**Corpus version: 1.0.0** (frozen 2026-07-30)

The point of a *fixed* corpus is that two runs separated by months, or run by two
different people, are comparing the same thing. Without it, every speed statement
is an anecdote about whatever task happened to be in front of someone that day —
which is precisely how this project ended up arguing a multiplier it had never
measured.

**Freezing rule.** Tasks in this corpus are never edited in place. A change to a
task is a new corpus version, and results are only ever compared *within* a
version. If `T3` is made easier and the number goes up, that is not a speedup.

## The tasks

Four tasks, chosen to span the lane ladder rather than to flatter it: one that
should cost almost nothing, one that sits exactly on the `tiny`/`substantive`
boundary where mis-classification is most expensive, one genuinely substantive,
and one that only parallelism can help with.

| id | task | expected lane | round budget |
|---|---|---|---|
| `T1` | Fix a single wrong word in one code comment. No behaviour change, no test change. | `tiny` | **2** (router budget) |
| `T2` | Fix a single-file bug *and* add the regression test that fails before the fix and passes after. One production file, one test file. | `tiny`, escalating to `substantive` only if the fix turns out to need a second file | **2** (router `tiny` budget); **4** corpus cap if escalated |
| `T3` | Add a feature spanning at least three files, with tests, docs, and a memory/changelog update. | `substantive` | **6** corpus cap (the router says "as needed"; the cap exists only to make runs comparable) |
| `T4` | Three independent work items with a disjoint file-ownership manifest, executed in parallel, then merged, with one post-merge verification. | `agent-swarm` | **9** corpus cap (≈3 per agent) |

### `T1` — one-line comment fix

- **Given:** a repository with at least one code comment containing a factual error.
- **Do:** correct that comment. Nothing else.
- **Done when:** the comment is correct and the project's own test command still
  reports the same pass count it did before.
- **Deliberately trivial.** `T1` exists to measure *overhead*, not capability. It
  is the task on which an over-orchestrating system loses most, and the one where
  this repo's own history is worst: a one-token stdin fix consumed 6 rounds
  (recorded in `packet_metrics.tsv` as `gravito_test_harness_stdin_hang_a`).

### `T2` — single-file bugfix with a test

- **Given:** a defect reproducible in exactly one source file.
- **Do:** write the failing test first, confirm it fails for the right reason,
  fix the defect, confirm it passes.
- **Done when:** the new test fails at the pre-fix tree and passes at the post-fix
  tree, and the full suite is green.
- **The boundary is the measurement.** `T2` is the task where classification is
  genuinely arguable. A run that stays in `tiny` and finishes is a de-escalation
  (free). A run that escalates must state a reason. **Record which happened** —
  the classification decision is data, not noise.

### `T3` — multi-file feature

- **Given:** a feature request touching at least three files.
- **Do:** the full `substantive` chain — builder → qa → reviewer → archivist,
  ≤2 commits, Commit-1 green in isolation.
- **Done when:** the suite is green, a receipt exists, and memory is updated.
- **Measures the steady state**, which is where a build system either earns its
  overhead or does not.

### `T4` — three-way independent fan-out

- **Given:** three work items that are genuinely independent.
- **Do:** produce the disjoint file-ownership manifest and the merge plan *before*
  starting, fan out, then merge with a single post-merge verification.
- **Done when:** the merge is clean and the single post-merge verification is
  green.
- **Record both wall-clocks.** The parallel wall-clock is what happened. The
  serial equivalent is what it would have cost sequentially — and it must be
  **measured by actually running the same corpus serially**, not inferred by
  adding up the agents' individual times, which ignores merge cost and
  double-counts nothing an operator would ever have paid.
- **Known weakness in the seeded data:** the one fan-out already in the store has
  a serial figure taken from a session transcript rather than a serial re-run, and
  the per-packet detail was destroyed by merging three packets into one commit.
  A future `T4` run must not repeat either mistake: one commit per packet, and a
  real serial baseline.

## How a run is recorded

One row per task per run, through the recorder, so nothing is typed straight into
the store without validation:

```sh
build-os/metrics/record-packet.sh \
  --packet t1_run3_buildos --lane tiny --rounds 1 --wall-min 2.4 \
  --agents 1 --files 1 --insertions 1 --deletions 1 --tests-added 0 \
  --evidence transcript --note "corpus v1.0.0 task T1, run 3, Build OS arm, operator SK"
```

The `--note` must name the **corpus version**, the **task id**, the **run
number**, and the **arm**. A row that cannot be traced back to a specific run of a
specific task is not comparable to anything and should not have been recorded.
