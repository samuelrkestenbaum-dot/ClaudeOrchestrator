# Gravito — design-partner demo script (ten minutes)

The narration for `build-os/demo/run-demo.sh`. One page per act, three columns
of intent: **what you say**, **what they should notice**, **what you volunteer
before they ask**.

Run it live:

    build-os/demo/run-demo.sh                 # paused, narrated
    build-os/demo/run-demo.sh --auto          # unattended, for a dry run
    build-os/demo/run-demo.sh --workspace ~/demo-ws --resume   # continue a paused demo

The script builds its own fixture repositories under `mktemp`. **It is never
pointed at a customer repository and never at an experiment repository.** Say
that out loud in the first thirty seconds; a design partner who thinks you are
demoing against their code will not hear anything else.

## Before you start (30 seconds, no slides)

> "Everything you are about to see is running live against a throwaway
> repository this script just created. Nothing here is a mock-up, and nothing
> here is a projection. Where a number is not measured, the tool says so —
> that behaviour is the product, not a limitation of the demo."

Ground rules to state up front, because volunteering them is the whole pitch:

- **NOT A SANDBOX.** Gravito disciplines honest work and leaves an audit trail.
  The platform's permission system is the real fence. A hostile process can
  step around the classification; an honest one leaves a record.
- **Hooks load at the NEXT SESSION.** The session that installs the gate is not
  governed by it. Protection starts at the next session in that project.
- **Tokens and spend are NOT VISIBLE LIVE.** No shell can read a live billing
  counter mid-session. Anything unmeasured is printed as UNAVAILABLE, never as
  zero, and never as an estimate wearing an exact label.
- **INTERNAL EVIDENCE ONLY.** Every figure in this demo comes from this
  repository's own records. There is no customer case study, no reference
  logo, and no savings number — because none has been earned yet.
- The Context Compiler is **implemented, inert, and performance-unmeasured**.
  It ships switched off on purpose (step 10).

---

## Step 1 — Installation (45 seconds)

**Say:** "Installing Gravito into a repository is one command. The runtime is
versioned, it checks itself against its own manifest before it copies a byte,
and it will not overwrite a file that already exists with different content."

**They should notice:** the per-file `install` list, then `status` classifying
every file as `current` / `drifted-local` / `upgrade-available`. Drift is
expected and *named*, not treated as corruption. There is an install receipt,
and `rollback` restores the last backup.

**Volunteer:** the customer-facing shell (`gravito`) is not yet part of the
installable runtime manifest — in this demo it runs from the source checkout.
That is outstanding work, not a feature.

## Step 2 — Repository intake (75 seconds)

**Say:** "This is what Gravito does the first time it sees a repository it has
never met. Watch the labels rather than the findings."

**They should notice:**

- every command is `DISCOVERED` (read out of a manifest the repo wrote) or
  `GUESSED` (an ecosystem convention this script supplied). The second
  repository in this step never wrote down how to test itself, and the guess is
  labelled a guess.
- `BASELINE: NOT MEASURED` — the baseline is off by default, so no red/green
  claim is made. The fixture *does* have a genuine failing test, and the script
  runs it by hand a moment later to prove the intake was not bluffing.
- the **Unsupported assumptions** section: what the intake could not determine,
  including the standing limits of its own heuristics.

**Volunteer:** secrets-shaped files are flagged **by name pattern only** — the
contents are never read, never printed, never summarised. Absence of a flag is
not clearance.

## Step 3 — An unrouted change is blocked (90 seconds) — *the money shot*

**Say:** "A worker tries to edit a source file with no routing decision on
record. The gate is a pre-execution hook, so the refusal lands *before* the
tokens are spent, not after."

**They should notice:** exit code 2, the model-visible refusal, and — the part
that matters — **the refusal carries its own recovery command.** We then run
exactly that command and retry the identical edit; it is admitted, and both
events are in the ledger.

**Volunteer, before they ask:** this is NOT A SANDBOX (say it again here, in
context), and the classification is a named heuristic. A `sh -c` wrapper evades
the mutation class. The value is discipline for honest agents plus a durable
audit trail.

## Step 4 — Depth selection (75 seconds)

**Say:** "Depth is chosen mechanically from a thirteen-field descriptor. A
partial descriptor is refused, never guessed — an unknown is not a zero."

**They should notice:** three honest descriptors producing Direct, Light and
Full, then the fourth case, which is the one worth pausing on: a genuinely
complex task — five files — where every value factor is false. The selector
**withholds Full** and prints why on stderr, and the demo shows that reasoning
instead of hiding it.

**Say (this is the line that lands):** "Complexity alone is not evidence that
the expensive depth buys anything. That rule exists because a correctly-complex
task once cost several times what it should have, and the measurement is in
this repository."

**Volunteer:** the budgets attached to each depth are **derived defaults**, not
laws — an operator can retune them, and their derivation is written into the
receipt itself.

## Step 5 — The customer surface (60 seconds)

**Say:** "This is what your team sees. It is read-only and it speaks your
words, not ours."

**They should notice:** Direct / Light / Full instead of internal mode
identifiers, "helper agents" instead of role names, budgets described as
ceilings agreed up front rather than bills. Two cards are shown deliberately:
one task with no live record yet, printing `UNAVAILABLE (not measured — an
unknown is never shown as 0)`, and one that carries the counts the hook
actually took.

**Volunteer:** the default evidence directory still contains an internal word
in its path, so the demo points the shell at a copy of the same evidence under
a customer-worded path. Renaming the store is outstanding work; the demo says
so rather than editing the screenshot.

## Step 6 — The evidence (45 seconds)

**Say:** "Everything the last three minutes claimed is a file you can read
without us."

**They should notice:** the routing receipt (one file per routing decision,
never overwritten), the append-only activity ledger, and the per-task live
record whose counts are *derived by counting rows* rather than stored — a
stored counter is a second copy that can disagree.

**Volunteer:** each count carries its tier — EXACT where a hook counted it,
ESTIMATE for the character-based token proxy, and unavailable-live for tokens
and spend. Tokens are NOT VISIBLE LIVE; the proxy is never promoted to a
billing number.

## Step 7 — Honest degradation (90 seconds) — *the second money shot*

**Say:** "Budgets that only get checked at the end are theatre. Watch a real
breach happen."

**They should notice:** the Full receipt allows three helper agents; the demo
attempts four. The fourth is refused *before* it runs, the brake records the
degradation on the receipt itself, and the instruction is *consolidate and
continue* — stop the expensive mode, not the task.

Then two closes of the same run:

- **concealed** — four helper runs claimed against a budget of three with the
  degradation blank: the close-time gate **REFUSES** it, exit 2.
- **declared** — the three the hook counted, with the degradation left in
  place: it **PASSES**, exit 0.

**Say:** "A breach is survivable. Concealing one is not."

**Volunteer:** the gate reads what the receipt *records*. A session that lies
into its own receipt is caught by nothing in that file — which is exactly why
the live hook counts independently and the close-time gate reports a
disagreement between the two rather than silently reconciling them.

## Step 8 — Fresh-worker continuity (60 seconds)

**Say:** "Here is what a brand new worker receives tomorrow, with NO
CONVERSATION HISTORY: the receipt, the intake report, the ledger rows for that
task, and the commands that re-derive all of it."

**They should notice:** the handoff is a *durable record*, not a transcript.
Decision, budgets, counts, outcome.

**Volunteer:** the claim is deliberately modest. Anything the previous worker
only *thought* is gone. The record carries what was written down and says so.

## Step 9 — The compiler refuses to bluff (60 seconds)

**Say:** "The Context Compiler will tell you when it should not be used."

**They should notice:** the same reporter run against two repositories. The
TS/JS fixture has real extractor coverage and comes back ELIGIBLE. The
shell-heavy fixture has none, and the verdict is NOT-ELIGIBLE with the
recommended state `bypass`: *use ordinary exploration here; a capsule compiled
from this index would be small-because-uninformed, not small-because-selective.*

**Say:** "That refusal is the feature. A tool that always recommends itself is
a tool you cannot use to make a decision."

**Volunteer:** the eligibility test is integer arithmetic against a
preregistered threshold, and the confidence ordinals are an uncalibrated
heuristic — stated in the report's own LIMITATIONS block.

## Step 10 — The compiler's honest status (45 seconds)

**Say:** "Last thing, and it is the thing most vendors skip."

**They should notice** the three words: **IMPLEMENTED, INERT,
PERFORMANCE-UNMEASURED.** The code exists and runs. Nothing in the live routing
path calls it, deliberately. And the performance claim is quoted from a
preregistration that was committed *before* the compiler existed, with the
sentence "Nothing in this repository has measured them" left in.

**Say:** "There is no A/B result yet. The preregistration fixes the conclusion
vocabulary in advance, and it makes 'context compilation harmful' exactly as
reachable as 'context compilation supported'. When the result arrives, you will
see it whichever way it lands — the last experiment run here produced an
adverse result and it was published."

---

## The caveat card (keep it visible; do not wait to be asked)

| Caveat | The honest wording |
|---|---|
| NOT A SANDBOX | Discipline plus audit trail. The permission system is the fence. |
| NEXT SESSION | Hooks load at session start; the installing session is ungoverned. |
| NOT VISIBLE LIVE | Tokens and spend cannot be read mid-session; unmeasured prints UNAVAILABLE. |
| INTERNAL EVIDENCE ONLY | Every figure comes from this repository. No customer evidence exists yet. |
| Compiler | Implemented, inert, performance-unmeasured. No A/B result exists. |
| Heuristics | Intake labels, mutation classification and confidence ordinals are named heuristics, not proofs. |
| Budgets | Derived defaults, operator-tunable, with their derivation recorded. |

## What you must NOT say

- Any savings figure, in tokens, dollars, or hours. None has been measured.
- Any customer name, logo, quote, or "one team saw…" story. There are none.
- Any restatement of the compiler hypothesis as a result. If the numbers come
  up, read them off the screen as a labelled HYPOTHESIS from
  `AB_PREREGISTRATION.md` (that file's base-case estimate is unmeasured), and
  say the next sentence in the file out loud: nothing here has measured them.
- "It prevents X." It *refuses* X at a named boundary, and it records what it
  admitted. Those are different claims.

## If it breaks live

The demo drives real tools, so it can genuinely fail. That is recoverable and
on-message: say what failed, show the artifact under `<workspace>/artifacts/`,
and continue with `--from <n>` or `--resume`. A demo that silently swallows a
failure is the behaviour this product exists to argue against.
