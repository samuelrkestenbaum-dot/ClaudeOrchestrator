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

For each task in `task_corpus.md` (corpus version pinned per run):

| measure | arms | notes |
|---|---|---|
| **wall-clock minutes** | both | first keystroke to accepted result, one clock, running the whole time, including review and rework |
| **defects caught before acceptance** / **found after acceptance** | both | |
| **output size** — files, insertions, tests added | both | |
| **rework** — commits or passes that existed only to fix the previous pass | both | |
| **rounds** — delegated agent passes consumed | **arm B only** | a **B-only diagnostic**, not a cross-arm measure — see below |

**Rounds are an arm-B-only diagnostic and must never be compared across arms.**
Arm A is raw Claude Code, which delegates to no sub-agent and therefore consumes
**zero** rounds by construction. A "0 vs 3" table would read as arm A winning on a
dimension arm A does not have. Rounds are worth recording because Build OS's own
round budgets are the thing they audit, but they are an *internal* measure of
arm B and nothing else. Every cross-arm claim in this protocol is denominated in
**wall-clock minutes**, the one unit both arms genuinely have.

Speed alone is not the claim under test. A system that is faster and ships more
escaped defects has not won; that is why the defect columns are in the schema and
why they are currently empty rather than assumed to be zero.

## The pre-registered primary endpoint

**Declared here, before run 1, and not revisable after seeing any data:**

> **Primary endpoint — the median wall-clock minutes to an accepted result on
> `T3`, arm B versus arm A.**

Everything else — rounds, defect counts, output size, rework, and the other three
tasks — is **secondary and exploratory**, and must be reported as such.

The reason is not ceremony. Five outcome families across four tasks is forty-odd
comparisons; at that width something will look good by chance, and whichever
comparison happens to look good is the one that gets written up. Naming the
endpoint in advance is what stops the result being chosen after the fact. `T3` is
the primary because it is the steady-state `substantive` case — where a build
system either earns its overhead or does not. If the primary endpoint shows
nothing, **the honest headline is that it showed nothing**, however good a
secondary looks.

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
8. **Reasoning effort / thinking budget** — the same setting on both arms,
   recorded in the note. This is a **separate knob from the model** and it is the
   easiest confound to introduce without noticing: arm B running hotter than arm A
   produces a real speed and quality difference that has nothing to do with Build
   OS, and constant #3 (same model, same version string) does not catch it because
   the model string is identical. If the setting is not recorded for both arms,
   the result is void.
9. **A fresh session / cold context per run** — every run starts in a new session
   with no conversation history, and the arms are never run back-to-back inside
   one session. Constant #2 holds the *filesystem* constant; this holds the
   *session* constant, which is the larger confound. A model that has just read
   the task in the previous arm is not solving the same problem the second time,
   and no clean tree undoes that.

## Number of runs

### The one to actually run: **16 runs** (20 at most)

| task | runs per arm | runs total |
|---|---|---|
| `T1` | 2, +1 if the ranges nearly touch | 4 (6) |
| `T2` | 2, +1 if the ranges nearly touch | 4 (6) |
| `T3` | 2 | 4 |
| `T4` | 2 | 4 |
| **total** | **8 (10)** | **16 runs, 20 at most** |

The floor is exact: 4 tasks × 2 arms × 2 runs = **16**. The two optional extra
runs go to `T1` and `T2` because they are the cheapest to repeat and because `T1`
is the task this system loses on — the place a third data point is worth most. At
full stretch that is `T1`×3, `T2`×3, `T3`×2, `T4`×2 per arm = **20 runs**. Both
numbers are stated because "≈16" and a table summing to 20 is precisely the kind
of arithmetic this instrument exists to refuse.

Report every task as a **range**, never a point estimate, and decide by this rule,
**pre-registered here before run 1**:

> **If the two arms' ranges overlap at all, the honest report is "no detectable
> difference at this N."** Not a trend, not a directional signal, not "arm B was
> faster on average". No detectable difference.

**Why 16 and not 40.** The 40-run design below is 20–30 operator-hours of a single
human's undivided attention, and a protocol that costs that much does not get
executed — it gets cited as evidence of rigour while never being run, which is
strictly worse than a small honest experiment. 16 runs is a two-day commitment
that someone will actually finish.

**What 16 can and cannot do, stated exactly.** A 20x effect produces
non-overlapping ranges at N=2 without any statistics at all — so **16 runs are
enough to refute "20x"**, which is the claim on the table. They are honestly
**insufficient to establish a 1.3x difference**, and nobody is selling 1.3x. The
asymmetry is the point: this design is powered to kill a big claim, not to
support a small one. If the ranges overlap, the correct conclusion is that the
large multiplier is not there — *not* that a small one might be.

### The fuller design, kept for whoever has the time

- **N = 5 runs per task per arm**, i.e. 4 tasks × 2 arms × 5 = **40 runs**.
- Report the **median** and the **full range**, never the mean alone: wall-clocks
  and round counts alike are heavily skewed by a single pathological run, and this
  project's own history contains two of them (a 6-round one-token fix, an 11-round
  utility that was sound at round 3).
- **N = 5 is still small.** It is chosen to be executable by one person, not to be
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

- **The DNF rule is denominated in wall-clock minutes, because it has to fire on
  both arms.** Any run that exceeds **60 wall-clock minutes** on `T1`/`T2`, or
  **120 wall-clock minutes** on `T3`/`T4`, is stopped and recorded as a **DNF**
  with the minutes consumed. A DNF is data — a system that occasionally fails to
  converge is not fast. Set these caps per corpus version *before* run 1 and hold
  them across both arms.
- **Why not rounds.** The earlier form of this rule stopped a run at "3× the
  corpus cap in rounds", which is unrunnable on arm A: rounds are delegated agent
  passes, arm A delegates to nobody, so arm A consumed zero rounds and could
  **never** DNF no matter how long it floundered. A stopping rule only the
  treatment arm can trigger silently exempts the control from ever failing, which
  biases the comparison in the direction the author would like. Rounds may still
  be recorded as an arm-B diagnostic, but they stop nothing.
- If the two arms cannot be run under the constant-set above, **the run does not
  happen**. A degraded run is not better than no run; it is worse, because it
  produces a number that looks comparable and is not.

## What this protocol still would not prove

Even fully executed at N=5, this design **cannot** establish:

- **An unbiased result, because the operator cannot be blinded.** The human
  holding the clock is the **author of the product under test**, and he knows at
  every moment which arm he is in — the two arms are distinguishable at a glance,
  so no blinding is even possible in principle. This document already says that an
  agent measuring its own speedup is not evidence; the identical sentence applies
  to its author. Every judgement call this design leaves to the operator — when a
  result is "accepted", when a run counts as interrupted, how hard to push on a
  stuck arm — leans the same way, and nothing in the protocol corrects for it. The
  only real mitigations are external: pre-registering the primary endpoint (done
  above), publishing the raw per-run records rather than a summary, and having
  somebody who did not build this run the arms.
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
