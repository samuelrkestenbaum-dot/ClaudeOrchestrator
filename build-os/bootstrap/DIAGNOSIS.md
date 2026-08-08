# Clean-start bootstrap — diagnosis (task #45, step 1)

**Status: diagnosis only. No mechanism chosen, nothing fixed, nothing rerun.**
Halted for an operator re-ruling, because the verified chain contradicts the
causal account in the frozen EXP-0005 record — the account the ruling and this
task's scope were based on. Per instruction the diagnosis came first; it did
not survive contact with reproduction.

## What was verified, step by step, on a fresh clean clone

Restored via `restore-seed.sh` — no live_state, no `.gravito/`, no routing
residue. Then each link of the recorded deadlock was tested directly:

| # | claim in the frozen record | reproduction result |
|---|---|---|
| 1 | mutgate blocks Edit/Write/Bash without an open receipt | **CONFIRMED** — by design, and correct |
| 2 | "creating a receipt requires Bash, **which the gate blocks**" | **REFUTED** — the deadlock guard (PACKET-0055 structured routing action) passes the arms' *exact verbatim* `route-task.sh` command: gate exit 0 |
| 3 | the missing untracked `live_state/` is the key the clean clone lacks | **REFUTED** — `route-task.sh` runs to completion on the clean clone with **no live_state at all**, writes an open receipt, selects a mode |
| 4 | (unrecorded) what actually stopped the arms | **The platform permission layer.** Every `route-task.sh` attempt returned `This command requires approval` — the host's auto-permission classifier refusing an unrecognized repo script, in a headless session with no approver |
| 5 | after a receipt exists, mutation opens | **CONFIRMED** — Edit passes the gate (exit 0) immediately after the receipt is written |

**Gravito's own bootstrap path is intact on a clean clone.** Gate → escape
hatch → receipt → open. Every Gravito-owned link works.

## The corrected causal chain

    fresh clone (headless, auto-permission host)
    → mutgate blocks mutation tools without an open receipt        [Gravito, by design]
    → arm invokes the designed escape: route-task.sh               [correct behaviour]
    → gate ALLOWS it (deadlock guard works)                        [Gravito, correct]
    → HOST refuses to execute the unrecognized script              [platform layer]
    → no approver exists in a headless session
    → no receipt can ever be created
    → Edit/Write/Bash blocked for the whole session
    → zero product mutations

## The asymmetry that decided 0/12 vs 12/12

Platform denials were **symmetric** — native arms were denied *more* often in
absolute terms:

| | Bash calls | platform denials |
|---|---:|---:|
| native (12 arms) | 261 | 102 |
| gravito (12 arms) | 100 | 48 |

Native shrugged the denials off because its work path is `Edit`, which
`acceptEdits` auto-approves. Gravito could not, because **its precondition for
using ANY mutation tool — including Edit — is one specific Bash script
execution.** Native paid the denials as friction; Gravito paid one of them as
total paralysis.

**That is the real product finding:** Gravito's entire capacity to act funnels
through a single host-approval-dependent operation. First authority is earned
by the *most-vetoed* operation class (unrecognized script execution) even when
the work itself needs only the *least-vetoed* one (file edits).

## What this does and does not change about EXP-0005

**Unchanged, fully:** the measured data. 0/12 vs 10/12, all economics, the
blinding, the adjudication, the frozen verdict as the registered rules'
output. Nothing in the frozen record's *numbers* is touched.

**Wrong in the frozen record:** the *cause* section. `RESULT.md` §15,
`EXECUTION-HALT.md`, `READING-NOTE.md`, and human-derived finding **B2**
(durability classification / "lock without key") describe a mechanism that
reproduction refutes: the gate does not block receipt creation, and the absent
live_state was never needed. I wrote that account, the ruling rested on it,
and it is incorrect.

**Genuinely reopened:** the A-vs-B reading. The failure only closes into a
circle on a host that denies unrecognized script execution with no approver
present. That host class is real and important — headless CI, autonomous
agents, conservative enterprise policy — so "Gravito cannot bootstrap there"
remains a true, serious, deterministic finding. But on an interactive
developer machine the human approves `route-task.sh` once and Gravito
proceeds. And the harness's permission mode (`acceptEdits`) was **my
mid-execution choice after `dontAsk` failed — not a registered condition**.
The frozen design froze "authority policy" for the arms but never registered
the host permission mode, and the mode interacts asymmetrically with the
treatment. That is a confound-shaped fact, and the operator — not I — should
rule on whether the verdict's *interpretation* narrows to
"harmful under headless auto-permission hosts" or stays as ruled.

**Finding B1 survives in corrected form.** The bootstrap invariant is real but
its statement changes:

> old: a clean installation must earn first mutation authority without already
> possessing mutation authority *(the circle was inside Gravito)*
>
> **corrected: earning first mutation authority must not require an operation
> of a HIGHER privilege class than the mutations it authorizes** *(the circle
> closes at the host boundary)*

## Mechanism directions — surveyed, NOT chosen

All three operator-listed mechanisms remain viable under the corrected
invariant; their ranking changes. Deterministic initialisation of routing
state alone would **not** have fixed EXP-0005 (state absence was not the
blocker), so it is now the weakest option standing alone.

1. **Hook-mediated receipt creation.** Hooks (`SessionStart`, `PreToolUse`)
   execute outside the tool-permission layer — proven by this very failure,
   since the gate's own refusals ran fine on every host. The mutgate, on
   seeing a *structured routing request* it already knows how to recognise,
   could write the receipt itself instead of requiring a separate Bash
   execution to do it. First authority would then need no host approval at
   all, while normal enforcement stays untouched.
2. **Receipt creation as a non-mutation operation** — reclassify the clean
   `route-task.sh` invocation as ungated *and* pre-approved. But the second
   half is host policy, not Gravito's to grant; unenforceable from inside.
3. **Deterministic empty routing state at install** — good hygiene, does not
   address the operative failure.

Direction 1 satisfies every required property list item and is validatable on
a clean clone in a headless host — the exact condition that failed. It is a
recommendation, not a decision.

## Why this halt, when the instruction was to build

The operator's diagnosis step was explicit: *"Identify precisely which state
must exist at first start and which operations are currently circular."* The
verified answer — **no state was missing and no Gravito-internal operation is
circular** — contradicts the task's premise, the frozen record's cause
narrative, and part of the basis for ruling A. Building a mechanism before
that correction is acknowledged would fix the wrong invariant and leave a
wrong causal account standing in the published record. The frozen artifacts
were not touched; whether a second reading note should correct the causal
description is an operator call.
