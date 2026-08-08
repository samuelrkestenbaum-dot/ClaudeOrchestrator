# EXP-0005 — execution complete, adjudication HALTED pending an operator ruling

All 24 arms ran. All 24 are `completed`, isolation-proven, fully captured. No
arm timed out, none was void, none required a rerun.

**Then the outcome column showed a systematic split that is not a treatment
effect I am willing to report without a ruling.**

| condition | arms | product files changed |
|---|---:|---:|
| native | 12 | **12 of 12 changed files** |
| gravito | 12 | **0 of 12 changed files** |

0/12 against 12/12 is not a subtle effect. It has a single, precisely
identified cause.

## The cause

The Gravito substrate ships a `PreToolUse` hook,
`.claude/hooks/routing-gate.sh mutgate`, which **blocks every mutation-capable
tool — `Bash`, `Edit`, `Write` — until an open routing receipt exists** under
`build-os/packets/routing/`.

Three arms said so unprompted, in their own words:

> "this repo has a `PreToolUse` routing hook … that blocks *all*
> mutation-capable tools … until an open routing receipt exists"

> "I have the full diagnosis, but every mutation path is blocked and I can't
> clear it myself."

> "The only open receipt in `build-os/packets/routing/` is
> `routing-native-proof-1-…`"

The deadlock is complete: issuing a routing receipt requires
`build-os/tools/route-task.sh`, which requires `Bash`, which the gate blocks.
**The arm cannot clear the gate that stops it clearing the gate.**

## Why the restored tree lacks the state that would open the gate

| fact | status |
|---|---|
| `.claude/hooks/routing-gate.sh` | **tracked** in the seed — it ships |
| `build-os/packets/routing/live_state/` | **untracked** — excluded by the pin |
| `build-os/packets/routing/live_gate_log.tsv` | **untracked** — excluded by the pin |
| `.gravito/` | **untracked** — excluded by the pin |

Both untracked paths exist on the working machine. `memory/INVENTORY.md`
classified them as "per-session live ledgers, not durable knowledge" and
excluded them from the snapshot **and** the restore, so that "no arm inherits
another arm's routing state". `restore-seed.sh` enforces that with
`git clean -fdx`.

So the Gravito arm receives the gate (tracked) and none of the state that opens
it (excluded). That combination was created by the restore procedure.

## The two readings, which give OPPOSITE verdicts

**(A) Genuine treatment behaviour — a real and severe product defect.**
Anyone cloning this repository fresh gets exactly this state: hooks present, no
live routing state, mutation deadlocked. On that reading Gravito **cannot
bootstrap on a clean checkout**, the measurement is valid, and the registered
outcome is `gravito_system_harmful` with an unusually precise cause. The
operator's standing rule applies: *"If a genuine treatment behavior causes poor
performance while the measurement remains valid, keep the result."*

**(B) Experimental artifact — `result_confounded`.**
The preregistration defines Arm G as "the substrate that would actually ship …
persistent repository state". In normal operation `live_state/` exists and the
gate opens. The restore removed state that is present in real use, so what was
measured is a configuration Gravito never actually runs in. On that reading the
Gravito arm never received the registered treatment.

## What this exposes regardless of the ruling

**The pinned definition of "durable memory" was incomplete.** `INVENTORY.md`
classified the routing ledgers as disposable per-session state. This run shows
they are **load-bearing for mutation**: without them the substrate cannot act at
all. That is a defect in the memory pin, not only in the experiment — and it was
invisible until the substrate was restored somewhere other than the machine that
grew it.

## What I have NOT done, deliberately

- **Nothing was repaired mid-run**, and no arm was re-run.
- **No treatment behaviour was modified** — the gate was not disabled, no
  receipt was pre-opened, no governance stage was removed.
- **The reveal has NOT been performed.** Adjudicating and then revealing a
  possibly-confounded arm would spend the one-way reveal on an experiment whose
  validity is the open question.
- **No verdict is claimed** in either direction.

All 24 arms' artifacts — diffs, verification output, economics, streams, run
records — are preserved exactly as produced.

## The ruling required

Reading (A) yields a headline result of `gravito_system_harmful`. Reading (B)
yields `result_confounded` and a re-run with the live routing state restored.
Choosing wrongly in either direction produces the most consequential possible
error, so this is an operator judgement about what "the substrate that would
actually ship" means, not one I should make.
