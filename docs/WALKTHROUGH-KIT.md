# R1 independent-operator walkthrough kit

*This kit defines the R1 acceptance evidence BEFORE anyone runs it. The
walkthrough itself requires fresh owner authorization (recruiting the
operator is a person decision) and has NOT been run. Success and failure are
preregistered here so the result cannot be graded on vibes afterwards.*

## Who qualifies as the operator

A competent engineer who has NEVER operated Gravito and receives NO author
assistance during the run. They may read anything in the repository. The
author may be present only to observe and log — answering any question during
the run is an **intervention** and is logged as one (question, timestamp,
what was answered). Interventions do not void the run; concealing them does.

## Setup (author does this BEFORE the operator arrives)

1. A fresh clone of this repository at a recorded commit.
2. A disposable target repository with real content — not a toy: clone any
   small real project the operator does not own, verify it passes
   `gravito preflight`.
3. A prepared `gravito.goal` file for a small, genuinely useful task in that
   repo (edit `templates/gravito.goal.example`; budget ≤ $5 / ≤ 30 min).
4. Screen recording running before the first command.
5. This file printed or open on a second screen — the operator follows the
   SCRIPT section only.

## The script the operator follows

Exactly the golden path in `docs/ONBOARDING.md`, top to bottom:
preflight → init → goal → diagnose → run --dry-run → run → review → stop,
then ONE exit verb of the operator's choice (rollback, uninstall --force, or
purge --force). The operator reads ONBOARDING.md itself — the docs, not the
author, are the interface under test.

## Preregistered success criteria (ALL must hold)

- S1 Completion: the operator reaches `review` with `acceptance: PASS`
  (or a FAIL they can correctly explain from the surfaces alone).
- S2 No author assistance: zero interventions, or every intervention logged
  and each one traceable to a named doc gap (which becomes a defect).
- S3 Time: first command → review verdict in ≤ 60 minutes.
- S4 Comprehension: afterwards, the operator answers four questions
  correctly using only `status`/`diagnose` output: What did it cost? What is
  the goal window? What was blocked, if anything? How do you stop it?
- S5 Clean exit: their chosen exit verb leaves the target repo in the state
  ONBOARDING promises (checked with `git status` + the byte-identity claim
  for purge).

## Preregistered failure criteria (ANY one fails the run)

- F1 A documented command errors or its output contradicts the doc.
- F2 The operator is blocked > 30 minutes on one step. **Stop the run
  there** — the block IS the finding; fix, then a FRESH run with a fresh
  operator step-count.
- F3 An undisclosed intervention.
- F4 The target repo ends in a state the docs did not predict.

## The friction log (operator fills during the run)

| # | Time | Step | What I expected | What happened | Severity (blocked / confused / cosmetic) |
|---|------|------|-----------------|---------------|------------------------------------------|

Every "confused" row is a doc defect. Every "blocked" row is a product
defect. Cosmetic rows are triaged, not dismissed silently.

## Evidence bundle to keep

Recording; friction log; intervention log (even if empty); the target repo's
`build-os/receipts/` (manifests, run stream, refusals, diagnose bundle);
`gravito status` output at exit; the operator's four S4 answers verbatim.
Store under `build-os/experiments/R1-WALKTHROUGH/` — it is program evidence,
handled like all sealed evidence (never rewritten).

## What this run does and does not prove

It proves (or refutes): a non-author can operate the golden path from docs
alone. It does NOT prove: performance, multi-operator use, or anything about
repositories unlike the chosen target. One run is one operator — R1 claims
"another internal operator", not "operators in general".
