# Post-pilot eligibility workflow

One bounded procedure that answers one question: **may EXP-0004 run against this
repository, at this commit?** It does not answer it by judgement. It applies
`AB_PREREGISTRATION.md` AMENDMENT 1 mechanically, records the arithmetic, and
either hands back a candidate backlog or stops.

```
assess-repo.sh --repo <path> --out <dir> [--errors <file>]
               [--exclusions <file>] [--deterministic]
               [--indexer <path>] [--reporter <path>]
```

`--out` must be **outside** `--repo` and empty. Both are enforced.

## The seven steps

Each is written to `procedure.tsv` as it runs, and steps 1-5 are embedded in
`eligibility.json`.

| # | step | what it does |
|---|---|---|
| 1 | `pin-commit` | records HEAD and verifies the tree is clean; **refuses (exit 2) if dirty** |
| 2 | `index-commit` | builds the SEAM 1 index of exactly that commit, into `--out` |
| 3 | `capability-report` | runs `capability/report.mjs` over that index, text and `--json` |
| 4 | `record-evidence` | writes `ELIGIBILITY.md` + `eligibility.json` |
| 5 | `apply-rule` | applies AMENDMENT 1 **from the reporter's own verdict**, audited |
| 6 | `stop-if-ineligible` | halts with exit 1 when the precondition fails |
| 7 | `emit-backlog` | candidates, minus every prior-pilot task |

**Why step 1 refuses a dirty tree.** `build-index.mjs` reads *worktree* bytes,
not the blobs of the commit it names. An assessment run over uncommitted changes
would print a sha that does not contain what was measured, and nobody could
re-derive the verdict from it. Refusing is cheaper than an unreproducible number.

**What "mechanically" means in step 5.** This procedure does not re-derive the
amendment's number from the index. The reporter already derives it — deliberately
identically to `build-index.mjs stats` — and the pass/fail is taken from the
reporter's own verdict. What step 5 adds is an *audit*: the reporter's verdict
against the reporter's own published arithmetic, its JSON verdict against its
rendered `VERDICT:` line, and its counts against the indexer's counts. If any
pair disagrees, the procedure **refuses (exit 3)** and names the pair. Two
instruments disagreeing about the one number a preregistered precondition turns
on is a defect in the pair; a verdict selected out of a disagreement is not
evidence, and would be filed as though it were.

## Exit codes

| code | meaning |
|---|---|
| 0 | **ELIGIBLE** — record written, candidate backlog emitted |
| 1 | **NOT-ELIGIBLE** — record written, task selection stops. A legitimate outcome. |
| 2 | refused before any verdict — bad arguments, unusable target, dirty tree |
| 3 | refused because the instruments disagree — a defect; no verdict issued |

Exit 1 is **not** a failure to work around. AMENDMENT 1 exists because a capsule
built from an unparsed index is small-because-*uninformed*, and an A/B run there
would measure a compiler operating nearly blind — registering outcome 4 for a
reason with nothing to do with the compression thesis. The honest responses are:
exclude the repository; or, by explicit operator decision, run it and register
`result confounded`; or **build the signal** — the amendment itself says adding a
shell extractor to the indexer would satisfy the check, and calls that a build
decision rather than an amendment to the rule.

## Read-only toward the target — absolutely, not by convention

A frozen pilot is the reason. A tool that wrote inside a frozen pilot's
repository would put the freeze in question, so:

* every artifact goes to `--out`, and `--out` inside the target is refused;
* every git invocation is a read (`rev-parse`, `status`, and inside the indexer
  `ls-files` and `log`). Nothing is checked out, set aside, discarded or written
  back;
* `GIT_OPTIONAL_LOCKS=0` and `--no-optional-locks` are set so that even git's own
  opportunistic index refresh cannot write inside the target;
* `tests/eligibility_workflow_tests.sh` hashes **every file under a fixture
  target, including `.git`**, before and after a full run and requires
  byte-identity with no additions and no removals — and greps this directory's
  source for mutating git verbs.

If the target must change for this tool to work, the tool is wrong.

## Artifacts, all in `--out`

```
index.json              the SEAM 1 index of the pinned commit
index-stats.txt         build-index.mjs stats — the amendment's named instrument
index-build.log         the indexer's own stderr report
capability-report.txt   the capability reporter, human form
capability-report.json  the capability reporter, machine form
ELIGIBILITY.md          the run record AMENDMENT 1 requires to exist
eligibility.json        the same record, machine form
procedure.tsv           the step log
CANDIDATES.md           the candidate backlog        ] ELIGIBLE only
candidates.json         the same backlog, machine form ]
```

## The backlog is candidates, not a selection

Candidates are error clusters from the index — a unit of work a task could be cut
from, not a task. Choosing and freezing the EXP-0004 task set is a separate,
operator-gated step, and this tool does not take it.

`prior-pilot-exclusions.txt` is an **input file**, not a constant: it lists
PILOT-0001's five tasks and PILOT-0002's five frozen ones, each read out of this
repository (`build-os/pilots/PILOT-0002/FREEZE.md`, and the `task_id` lines of
`build-os/packets/routing/routing-PILOT-0001-*.md`). Point `--exclusions`
elsewhere and the filter changes. Two things about it are stated in the file
itself rather than left to be discovered: cluster signatures are operand-blind
(so path patterns do the work), and the patterns are deliberately broad, because
a false exclusion costs one candidate while a false inclusion contaminates a
pilot that cannot be un-run.

## Where the preregistration was ambiguous

Every one of these is recorded in `ELIGIBILITY.md` under "interpretation
recorded", because an unrecorded reading of a preregistered rule is how a
precondition gets softened later.

1. **"files admitted-as-candidates" vs "measured by `build-index.mjs stats`."**
   The first is capsule-scoped; the second is whole-index. Before task selection
   no capsule exists, so the readings coincide and the report runs without
   `--capsule`. Consequence, stated rather than hidden: this assessment is about
   the **repository**. A per-task capsule can have a worse no_parser share than
   the repository it was drawn from, and AMENDMENT 1 would then have to be
   re-applied to that capsule.
2. **"below 50%"** is read as strict inequality in integer arithmetic (`2n < N`),
   so a repository exactly on one half is not eligible and no rounding decides a
   preregistered precondition.
3. **The empty repository.** The amendment gives no rule for a zero-file index.
   The reporter treats it as NOT-ELIGIBLE ("not computable"); this procedure
   follows, on the ground that an unmeasurable precondition is not a satisfied
   one.
4. **"either excluded or the run is registered `result confounded`"** — a
   disjunction with no rule for choosing. This procedure takes the conservative
   branch (stop, do not select tasks) and leaves the other to an explicit
   operator decision, recording the choice rather than presenting it as forced.

## What a PASS does not mean

It is a statement about the **index**, not a prediction that a capsule compiled
from it will be correct or that EXP-0004 will find a benefit. AMENDMENT 1 is a
precondition, not a hypothesis. The assessment also expires the moment the commit
moves.

## Not wired into any live path

This is operator-invoked. It calls the indexer and the capability reporter as
CLIs and changes neither, so what the compiler emits during EXP-0004 is
unaffected and the stop condition about wiring the compiler into a live routing
path mid-registration stays clear.
