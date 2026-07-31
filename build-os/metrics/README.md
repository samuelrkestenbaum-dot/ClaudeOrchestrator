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
| `check-adoption.sh` | the adoption guard: reconciles `build-os/receipts/*.md` against the store and fails when a packet closed without recording |
| `adoption_boundaries.tsv` | the one dated grandfather boundary per obligation — the guard's entire exemption mechanism |
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

## When a row is written, and by whom

**One row per packet, appended by the archivist at close.** Not by the builder
mid-flight. The reason is arithmetic, not ceremony: the store is append-only and
the recorder refuses a duplicate `packet_id`, so a row written before the figures
are final can never be corrected. At close, and only at close, every column is
knowable at once — both commits exist, the round count is final, and qa has
reported.

This packet (`gravito_speed_benchmark_a`) deliberately has **no row of its own**
in the seeded store for exactly that reason. It had not closed when its own
instrument was committed. Writing a partial row for it — Commit 1's diff with an
empty round count — would have put a number in the store that the store could
never fix, which is the failure mode this whole file argues against.

### And something checks that it happened — `check-adoption.sh`

The obligation above used to be a convention. The recorder refused a bad row and
the report refused an empty store, but **nothing failed when nobody recorded at
all**, and the predictable end state of that gap is a store frozen at its seed
rows while every artifact around it says the system is measured. That is
shelfware, and it is the most likely way this instrument dies.

```bash
build-os/metrics/check-adoption.sh            # 0 = adopted, 2 = refused
build-os/metrics/check-adoption.sh --verbose  # also lists what it skipped, and why
```

It reconciles the arrival log against the store: every `build-os/receipts/<id>.md`
must have a row whose `packet_id` is that receipt's filename stem. Four things
keep it honest, and each one is a failure mode it was built against:

- **It cannot be satisfied by junk.** A row counts as recording the packet only
  if it names a lane and a date, names commits this repository actually
  contains, fills at least 4 of the 11 measurable cells, gives a rounds count
  *or* says in the note why rounds is `-`, and carries a note long enough to
  attribute its numbers. Anything less is reported as **HOLLOW**, which is worse
  than MISSING — a dash-filled row is a missing row wearing evidence.
- **It never taxes the small lanes — but it no longer takes them on trust.**
  `read-only`, `diagnosis` and `tiny` close with no packet and no receipt, so
  they owe no row; a receipt that declares one of those lanes is waived by name.
  A guard that invents work for a one-line fix is a guard that gets switched
  off. What changed is that the *declaration* is now cross-examined against git
  — see **the lane cross-check** below.
- **Historical receipts are exempted by a date, not by a list.**
  `adoption_boundaries.tsv` declares exactly two obligations
  (`row_required_after`, `single_commit_required_after`), each with one date and
  a stated reason. There is deliberately **no per-packet exemption syntax** — an
  exception list that can grow is shelfware with extra steps — and both dates
  are pinned literally by `tests/metrics_adoption_tests.sh`, so moving one costs
  a reviewed edit. A receipt's effective date comes from git (when the file
  entered history) and falls back to its `**Date:**` line, so a brand-new
  receipt fails closed and omitting the date is not a dodge.
- **It refuses instead of passing vacuously.** Zero receipts found, zero rows in
  the store, or zero receipts *in scope* are all refusals. That last one is what
  stops the boundary being used as an off switch: pushing it forward until
  nothing is in scope empties the guard, and a guard that cannot fail must not
  report success.

### The lane cross-check — a declared lane is checkable

The waiver above was, until recently, the largest remaining hole in the whole
enforcement chain. `**Lane:** tiny` is self-asserted, and declaring it waives
**qa, the reviewer, the archivist, the receipt and the metrics row**. Five gates
switched off by one unverified word, with nothing anywhere comparing that word to
the packet's actual size. An agent that learned to declare `tiny` for everything
would get a Build OS with no gates, and nothing would go red.

So every declaration of a gate-waiving lane — on a **receipt** *or* in the
store's **`lane` column** (tiny work legitimately closes with a row and no
receipt) — is measured against git:

| Constant | Value | Derivation |
|---|---|---|
| `LANE_TINY_MAX_FILES` | 13 | **median** `files` over the 4 size-measurable non-waived-lane rows in `packet_metrics.tsv` — {7, 8, 18, 32} |
| `LANE_TINY_MAX_CHURN` | 2213 | **median** `insertions + deletions` over the same 4 rows — {852, 2005, 2422, 9818}, floored from 2213.5 |

A declaration is **LANE-CONTRADICTED** when git says the packet touched at least
`LANE_TINY_MAX_FILES` files **or** churned at least `LANE_TINY_MAX_CHURN` lines.
The two signals fire independently. Commits come from the row's `commits` column
when it has one (already reconciled against git by `--verify-git`), otherwise
from the receipt's `## Commits` section only — preambles quote base and
merge-base shas, and measuring those would fabricate a violation.

- **Specificity over sensitivity, deliberately.** The thresholds are the
  **median** of the substantive distribution, not its minimum. A `tiny`
  mis-declared over 8 files / 2005 lines passes; half the calibration set
  survives being relabelled. False positives are what get a check like this
  deleted, and a deleted check is worse than none because the belief it is
  running outlives it.
- **`substantive`, `architecture` and `agent-swarm` have no upper bound.** Size
  is only evidence against a lane that waives gates.
- **No commit, no finding.** Read-only answers and diagnoses leave no diff.
- **The escape hatch is recorded, never silent.** A mechanical rename across 40
  files is genuinely tiny in judgment; record it with a `LANE-OVERRIDE:` line in
  the receipt or the row's note, naming the **measured file count**. Boilerplate
  and one-word overrides are rejected as `LANE-OVERRIDE-BAD`. Honoured ones
  print `LANE-OVERRIDDEN` on every run and are enumerable with
  `grep -rn LANE-OVERRIDE build-os/`.
- **It refuses rather than passing unmoored.** Zero non-waived, size-measurable
  rows means the thresholds have no calibration basis here, and that is a
  refusal. The scan also prints the store's *currently* recomputed medians beside
  the enforced ones so drift is visible — but never auto-follows them, because a
  self-tuning threshold is attacker-controlled: record a few large packets and
  the `tiny` ceiling rises to meet them.

**What it cannot catch:** a wrong number honestly recorded. It checks that a
closing packet recorded something meaningful and that the commits are real — not
that the round count is true. It also only walks receipt → row, so a row with no
receipt (the reference corpus rows are exactly this) is not flagged, and a
receipt whose filename does not match its `packet_id` reads as missing.

**And what the lane cross-check specifically cannot catch — round budgets.**
`gravito_test_harness_stdin_hang_a` is recorded `lane=tiny rounds=6` against a
2-round budget, this system's worst compliance record. Its size is 1 file / 116
changed lines, which is genuinely tiny, so the cross-check passes it and should.
That failure was a **budget** breach, not a mis-declaration — a different defect
needing a different guard. **No round-budget guard exists**: rounds are
transcript-only and nothing git-observable attests to them.

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
- **Record a second row for a packet already in the store.** Every total would
  double-count it, and the report's own self-checks would still pass, because a
  double-counted row is internally consistent. That is the hardest class of wrong
  number to notice, so it is refused at the door.
- **Record a `git`/`mixed` row that names no commit.** An uncheckable claim of
  git backing is worse than an honest estimate.
- **Pass a row that contradicts git.** `--verify-git` sums `git show --numstat`
  over the named commits and fails on any disagreement in files, insertions, or
  deletions.
- **Report success having verified nothing.** A verifier that checked zero rows
  exits non-zero; that is how a blinded check would otherwise stay green forever.
- **Pass a store containing a commit this repository does not have.**
  `--verify-git` exits non-zero on any `UNVERIFIABLE` row, not only on a
  `MISMATCH`. It used to print `UNVERIFIABLE <packet> <sha>` and still exit 0 as
  long as some *other* row verified — so a fabricated commit could sit in the
  store while `$?` reported agreement with git. A skeptic checks the exit code;
  an unverifiable row is an **unmade check**, not a passed one. (On a shallow
  clone or a history-stripped export this is the correct answer too: fetch the
  history and re-run.)
- **Render a report from zero rows.** An empty table with a clean exit looks like
  proof. It is refused, loudly, on stderr.
- **Total an unmeasured column to `0`.** If no row measured a column, its total
  prints `-`. Summing an empty set to `0` would publish a clean record nobody
  ever audited — it has the same shape as a real zero-defect result and none of
  the evidence. `defects_escaped` in the seeded report is exactly this case.
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
  are **unattributable from git alone — recoverable only if the disjoint
  file-ownership manifest was recorded**, which for that fan-out it was not.
  One commit per packet is a measurement requirement, not a style preference —
  **with a stated fallback**: one commit per packet *where the merge allows it*;
  otherwise record the disjoint manifest in the receipt so attribution stays
  recoverable **by path**. The fallback exists because the absolute rule collides
  with "Commit-1 green in isolation" on a fan-out merge, and an absolute rule that
  collides with merge mechanics is one that gets quietly broken instead of
  followed.
- **A row can never be corrected.** Append-only plus one-row-per-packet means a
  figure that was not final when the row was written is never recorded at all.
  There is no supersede mechanism, and adding one is a follow-on packet. The
  mitigation today is the convention above: write the row at close, or not yet.
- **`--verify-git` needs this repository's history, and says so.** The seeded
  rows are falsified against commits `641527f`, `c30f77d`, `5b956c0` and
  `68cae7a`. A shallow clone, or an export re-initialised as a fresh repository,
  does not contain them — every git-backed row then reports `UNVERIFIABLE` and
  the verifier exits non-zero rather than passing on an empty check. This was
  found by running the suite in a history-stripped tree, and
  `tests/speed_benchmark_tests.sh` §11 now names the missing precondition
  explicitly so the failure is not mistaken for a broken verifier.
- **No baseline arm exists.** See `COMPARISON_PROTOCOL.md`.
