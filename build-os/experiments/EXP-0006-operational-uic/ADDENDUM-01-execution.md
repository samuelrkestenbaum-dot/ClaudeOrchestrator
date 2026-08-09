# EXP-0006 ADDENDUM 01 — execution parameters and the substrate reading

**PREREGISTRATION.md is unchanged.** This addendum records decisions the frozen
design left to execution time, and one place where executing the design as
written required a reading to be stated out loud. It is written **before any
measured arm runs**, and it does not relax any acceptance rule.

## 1. Execution parameters (the preregistration requires them recorded, not chosen in advance)

| parameter | value | why |
|---|---|---|
| per-task ceiling | **1200 s**, identical for both arms | EXP-0005 used 5400 s for open-ended refactors. These are single-file typecheck repairs of 1–17 errors. A run that has not converged in twenty minutes has not met a harder task, it has met a failure mode — and 5400 s × 24 arms is a nine-hour upper bound spent mostly on stalls. |
| execution shape | **4-task pilot (T01–T04), then the remaining 8** | EXP-0005 burned a full 12-task run discovering that its harness destroyed the diffs it needed. A pilot surfaces harness defects at a third of the cost. It is a staging decision only: the task set, seed, ceiling, acceptance rule and blinding are identical across both stages, and the pilot's arms are admitted to the final analysis rather than discarded. |
| arm order | alternates by task index — odd: native first, even: gravito first | Whichever arm runs first pays for a cold cache. A fixed order would hand one condition that cost on all twelve tasks; alternating cancels it, and the rule is deterministic rather than shuffled. |

These were my calls, not the operator's. They are recorded here as such.

## 2. The substrate reading — stated because it could have been made silently

The preregistration defines the Gravito arm as carrying **"the current
load-bearing substrate"** and names its parts: persistent memory, routing, live
authority compatibility selection, mutation enforcement, capability exhaustion,
continuation and value prioritisation, evidence handling and verification.

The arm tree is `empathiq-website` at seed `2543c873`. That tree carries a
Gravito **embed** — 206 files — and the embed **is not that substrate**:

- no `build-os/motion/` — no continuation controller, no objective/value gate,
  no concession gate, no capability map;
- no `build-os/assumptions/` — no authority selector, no host profiles, no
  assumption registry;
- no `build-os/surfaces/`, no `build-os/audit/`;
- its `.claude/hooks/routing-gate.sh` **predates this session's
  `CODE_ROOT`/`DATA_ROOT` repair**, so it carries a known product regression.

Running the arm against the embed as found would administer an older,
known-defective treatment and then report the result as a verdict on the current
substrate. That is EXP-0005's error one layer up: EXP-0005 measured a
precondition failure and called it a product verdict.

**The reading administered:** Gravito **CODE** comes from the orchestrator;
Gravito **DATA** stays whatever the arm tree already had. This is not a
distinction invented for the experiment — it is the same `CODE_ROOT`/`DATA_ROOT`
split `.claude/hooks/routing-gate.sh` resolves at runtime, and confusing the two
*was* the regression repaired this session.

| class | contents | disposition |
|---|---|---|
| DATA | `build-os/memory`, `receipts`, `packets`, `design`, `graph` | **retained** from the arm tree — another repository's memory is not this repository's persistence |
| WITHHELD | `build-os/experiments`, `build-os/pilots` | **never administered** — they contain this benchmark. An arm that can read the experiment scoring it is not measurable. |
| CODE | every other `build-os/` subdirectory, plus `.claude/` and `CLAUDE.md` | **administered** from the orchestrator at its current HEAD |

Enumerated with a reason per entry in `harness/substrate.mjs`, because an
unstated rule is one that can be widened quietly later.

## 3. Administration is verified, not assumed

`verifyAdministration()` refuses the arm unless: the 13 named load-bearing
controllers are present; the arm tree's own memory was **not** overwritten by
the orchestrator's; and the benchmark directories are absent from the arm tree.
The native arm is refused unless `build-os`, `.claude` and `CLAUDE.md` are all
gone — the embed counts as substrate, so removing only what the orchestrator
would have added would leave a stale Gravito, which is neither condition.

Every one of those checks, and every acceptance rule, is **mutation-tested** in
`harness/harness.test.mjs`: 18 assertions, each damaging the thing under test and
requiring the check to notice. A check that has never demonstrated a failure
tells you it ran, not that it guards.

## 4. What the arm's diff is measured against

The administered condition is **committed** into the arm tree before launch, and
the arm's diff is taken against that commit. EXP-0005 could take a
status-based diff because its only pre-launch mutation was three deletions; here
the Gravito administration touches thousands of files, and attributing those to
the arm would hand it a diff it did not write.

## 5. Baseline

`results/baseline-tsc.txt` — the full compiler output at the seed: **781 errors
across 175 files**. All twelve selected tasks' error counts reconcile exactly
with the frozen `task-selection.json`, so the baseline is the same compiler state
the selection was drawn from. Condition 2 ("no new error elsewhere") is computed
against this file.
