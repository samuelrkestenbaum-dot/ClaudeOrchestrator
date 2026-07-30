# The A/B comparison protocol — specified, and openly **not been run**

This document specifies how a real "Build OS vs raw Claude Code" comparison would
be executed. It is a design, not a result. **No arm of this experiment has been
run, and no number in this repository comes from it.**

Read that sentence before quoting anything from `report-speed.sh`.

## Why it has not been run here

The comparison **cannot** be executed from the test harness in this repository,
and pretending otherwise would be the single worst thing this packet could ship:

- A Claude Code session cannot be launched from a bash test. There is no
  scriptable invocation and no API access in this environment.
- Agent invocations are not addressable from a harness, so the "Build OS on" arm
  cannot be driven programmatically either.
- Therefore **neither arm** can be automated here — not just the baseline.

The rule that follows is absolute: **an arm that was not executed produces no
row.** Not a placeholder, not an interpolation, not a figure derived from timers
or stand-ins. An empty cell that says why it is empty survives a skeptic. A
fabricated one destroys every honest number sitting next to it.

## What the experiment measures

For each task in `task_corpus.md` (corpus version pinned per run), on both arms:

- **rounds** — delegated agent passes consumed
- **wall-clock minutes** — first keystroke to accepted result, one clock, running
  the whole time, including review and rework
- **defects caught before acceptance** and **defects found after acceptance**
- **output size** — files, insertions, tests added
- **rework** — commits or passes that existed only to fix the previous pass

Speed alone is not the claim under test. A system that is faster and ships more
escaped defects has not won; that is why the defect columns are in the schema and
why they are currently empty rather than assumed to be zero.

## The two arms

| arm | description |
|---|---|
| **A — control** | Claude Code with no Build OS: no `CLAUDE.md` Build OS block, no `.claude/agents/*`, no lanes, no router, no packets, no receipts. A clean checkout of the task repo with the Build OS surface removed. |
| **B — treatment** | The same checkout with Build OS installed and the per-task protocol followed: lane declared out loud, tool budget declared, gates run for that lane. |

## What is held constant

Everything in this list is **held constant** across both arms of every run.
A variable that moves between arms is a confound, and one confound is enough to
void the whole result:

1. **The task text**, verbatim from `task_corpus.md`, at a pinned corpus version.
2. **The starting tree** — the same commit SHA, a fresh clone per run, no
   carry-over state between runs.
3. **The model** — same model, same version string, recorded in the note.
4. **The operator** — the same human, who must run arms in alternating order
   (A,B,B,A,...) so learning the task does not systematically favour whichever
   arm goes second.
5. **The acceptance criterion** — defined per task *before* any run, and applied
   by the same checker to both arms. If the criterion is decided after seeing
   output, the experiment is worthless.
6. **The clock** — one wall-clock definition, started and stopped the same way,
   including thinking and review time in both arms.
7. **Interruptions** — a run interrupted by anything external is discarded, not
   adjusted.

## Number of runs

- **N = 5 runs per task per arm**, i.e. 4 tasks × 2 arms × 5 = **40 runs**.
- Report the **median** and the **full range**, never the mean alone: round counts
  are heavily skewed by a single pathological run, and this project's own history
  contains two of them (a 6-round one-token fix, an 11-round utility that was
  sound at round 3).
- **N = 5 is small.** It is chosen to be executable by one person, not to be
  statistically strong. Any result must be reported with its N attached, and a
  difference smaller than the observed within-arm range is not a finding.

## Who runs it

- A **human operator** runs both arms and holds the clock. Not an agent — an
  agent measuring its own speedup is not evidence.
- Optionally a **driver script** may set up trees, record start/stop times, and
  call the recorder. It must never generate an outcome, only observe one.
- Each run is recorded through `record-packet.sh` with
  `--evidence transcript` (observed, not reproducible from the repo) and a note
  naming corpus version, task id, run number, arm, model, and operator.

## Stopping rules

- Any run that exceeds **3× the corpus cap** in rounds is stopped and recorded as
  a **DNF** with the rounds consumed. A DNF is data — a system that occasionally
  fails to converge is not fast.
- If the two arms cannot be run under the constant-set above, **the run does not
  happen**. A degraded run is not better than no run; it is worse, because it
  produces a number that looks comparable and is not.

## What this protocol still would not prove

Even fully executed at N=5, this design **cannot** establish:

- **A general multiplier.** It measures four tasks in one repository with one
  operator and one model. "20x-100x" is a claim about a population this design
  does not sample, and no run count fixes that.
- **Causation from the orchestrator specifically.** Arm B differs from arm A by
  the whole Build OS surface at once. Attributing an effect to lanes rather than
  to, say, the packet discipline would need a further arm that varies one piece.
- **Long-horizon quality.** Escaped defects are counted only for as long as
  someone keeps looking. A one-session window undercounts them in both arms
  equally, which is fair, but it is not a quality measurement.
- **Anything about other repositories, other models, or other operators.**

State these limits alongside any result. A buyer who re-runs this will find them
anyway, and finding them unstated is what turns a measurement into a marketing
claim.
