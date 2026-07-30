# Build OS — packet speed measurement

The instrument that turns "faster" from an argument into a number, plus an
explicit list of the numbers it still cannot produce.

## What plainly can and cannot be proved today

**What this instrument can prove today:** that specific packets in this
repository's history produced specific, git-checkable amounts of change, in a
specific number of delegated rounds, and that at least one of them consumed three
times its lane's round budget. It can prove one fan-out's parallel wall-clock
against a serial figure taken from a session transcript, and it can prove that a
report over this store never silently drops a row.

**What it cannot prove today:** that Build OS is faster than anything. There is
no baseline arm. No comparison against raw Claude Code has been run, and none can
be run from this harness — a Claude Code session is not launchable from a bash
test here, so **both** arms of the A/B are unautomatable, not just the control.
The 20x-100x figure this project has argued is therefore **unmeasured**: it is
not supported by this store, and it is not refuted by it either. The store is
silent on it, and the report says so in §6 rather than leaving a gap a reader
would fill in charitably.

Everything else on this page is detail underneath those two paragraphs.

## Local, operator-owned, no telemetry

This is a plain file on your disk. Nothing here transmits, phones home, or
reports usage anywhere. `record-packet.sh` and `report-speed.sh` contain no
network calls of any kind, and a test in `tests/speed_benchmark_tests.sh` greps
them to keep it that way. The store is **operator-owned**: it is yours, it lives
in your repository, git is the only thing that ever moves it, and deleting it
costs you history and nothing else.

## The pieces

| file | what it is |
|---|---|
| `packet_metrics.tsv` | the append-only store — 16 tab-separated columns, one row per packet |
| `record-packet.sh` | the recorder: appends one **validated** row; also `--validate` and `--verify-git` |
| `report-speed.sh` | the report generator: renders the store, totals it, and refuses to render an empty one |
| `task_corpus.md` | the fixed, versioned task corpus that makes future runs comparable |
| `COMPARISON_PROTOCOL.md` | how a real A/B would be run — specified, and openly not run |

## The record format

Sixteen tab-separated columns. TSV rather than JSON because a recorder that is
expensive to use does not get used, and an unused recorder produces a store of
zero rows — which is exactly the state this project was in while arguing about
speed. A row can be appended by an agent, typed by a human, read with `cut`, and
diffed by git.

```
packet_id  date  lane  rounds  wall_min  serial_min  agents  files  insertions
deletions  tests_added  defects_gated  defects_escaped  commits  evidence  note
```

A sample record, exactly as it sits in the store (tabs shown as column breaks):

| column | value |
|---|---|
| `packet_id` | `gravito_test_harness_stdin_hang_a` |
| `date` | `2026-07-30` |
| `lane` | `tiny` |
| `rounds` | `6` |
| `wall_min` | `-` |
| `serial_min` | `-` |
| `agents` | `6` |
| `files` | `1` |
| `insertions` | `115` |
| `deletions` | `1` |
| `tests_added` | `4` |
| `defects_gated` | `1` |
| `defects_escaped` | `-` |
| `commits` | `641527f` |
| `evidence` | `mixed` |
| `note` | files/insertions/deletions are git-verifiable at `641527f`; rounds=6 (3 builder + 3 reviewer) is from the session transcript only; … |

### `-` means unmeasured, and never means zero

Every unsupplied field is written `-`. The recorder will not default a number to
`0`, because `0` is a measurement and `-` is an admission. `defects_escaped` is
`-` across almost the whole seeded corpus: no post-close defect audit has ever
been run here, so the honest value is "unaudited", not "none escaped".

### Evidence classes

| class | means |
|---|---|
| `git` | the diff figures and commits are reproducible from this repository |
| `mixed` | some fields git-backed, some not — the note must say which are which |
| `transcript` | observed in the session record; real, but not re-derivable from the repo |
| `estimate` | a judgement. Not a measurement. Says so. |

Every row must carry a note of at least 12 characters. A number nobody can trace
is decoration, not evidence, and the recorder rejects it.

### On `wall_min` — where wall-clock figures come from

Wall-clock is recorded **only** where somebody was actually holding a clock. It
is deliberately *not* reconstructed from commit timestamps: the gap between two
commits contains review, merge, and idle time as well as work, so a
timestamp-derived wall-clock would systematically overstate effort and would look
exactly as authoritative as a real one. Most seeded rows therefore have no
wall-clock, and the throughput table simply omits them rather than inventing a
denominator.

The one fan-out row's `13.7` / `37.9` minutes come from the session transcript
and measure **agent execution only** — not orchestration, qa, review, or merge.
Note the tension the instrument deliberately preserves: git says 47.5 minutes
elapsed between that packet's commit and the one before it. Both figures are true
about different things, and neither is a "how long the packet took" number.

## Using it

```sh
# append one record (validated; refuses anything malformed)
build-os/metrics/record-packet.sh --packet my_packet --lane substantive \
  --rounds 2 --wall-min 18.5 --agents 4 --files 6 --insertions 421 \
  --deletions 12 --tests-added 30 --defects-gated 1 \
  --commits 68cae7a --evidence mixed \
  --note "diff figures git-verifiable at 68cae7a; wall-clock timed by the operator"

# check the store's schema and every row
build-os/metrics/record-packet.sh --validate

# falsify any row that contradicts git
build-os/metrics/record-packet.sh --verify-git

# render the report
build-os/metrics/report-speed.sh
```

## What the instrument refuses to do

These are refusals, not warnings — each exits non-zero:

- **Record a row with no attribution.** No evidence class, no note, no row.
- **Record a `git`/`mixed` row that names no commit.** An uncheckable claim of
  git backing is worse than an honest estimate.
- **Pass a row that contradicts git.** `--verify-git` sums `git show --numstat`
  over the named commits and fails on any disagreement in files, insertions, or
  deletions.
- **Report success having verified nothing.** A verifier that checked zero rows
  exits non-zero; that is how a blinded check would otherwise stay green forever.
- **Render a report from zero rows.** An empty table with a clean exit looks like
  proof. It is refused, loudly, on stderr.
- **Render a report whose totals do not match its rows.** The renderer
  self-checks rows-read against rows-rendered and refuses on any mismatch — a
  report that drops a row is worse than no report, because its totals still look
  right.

## Sample size, and how to read the numbers

The seeded corpus is **4 rows**. That is a sample size, not a dataset. Two of
the four have no wall-clock at all, one has no diff figures at all, and the
round-budget compliance rate currently has a denominator of **1**. The report
prints that denominator next to the percentage on purpose: a compliance rate over
n=1 is an anecdote with a percent sign attached, and it will move by tens of
points on the next packet recorded.

The right way to use this today is as a baseline to accumulate against — every
future packet appends one row — not as evidence for a claim about speed.

## Known weaknesses of the instrument itself

- **Self-reported rounds and agents.** Nothing automatically counts delegated
  passes; those cells are typed in by whoever ran the packet. They are as honest
  as the person recording them, which is why the note field is mandatory.
- **`--verify-git` checks three columns.** Files, insertions, and deletions are
  falsifiable against git. Rounds, wall-clock, agents, and both defect columns are
  not, and nothing in this repository can falsify them.
- **Per-packet attribution can be destroyed by the merge policy.** The seeded
  fan-out merged three packets into one commit, so its three constituent packets
  are permanently unattributable. One commit per packet is a measurement
  requirement, not a style preference.
- **No baseline arm exists.** See `COMPARISON_PROTOCOL.md`.
