# EXP-0005 — post-reveal correction note (second note)

**Later reproduction falsified the causal account published in the first
reading note and in `RESULT.md` §15.** This note records that correction.

Nothing frozen is touched. `RESULT.md`, `PREREGISTRATION.md`,
`tasks/TASK-FREEZE.md`, `blinding/`, `baseline/`, `results/EXECUTION-HALT.md`
and `READING-NOTE.md` are unchanged. **The earlier note is not rewritten or
deleted — it stands as historical evidence of what was believed at the time,
not as current truth.**

## The registered verdict is unchanged

> **`gravito_system_harmful`**

That is what the preregistered rules returned from the frozen data, and it
remains the result of record. It is **not** changed to `result_confounded`,
because that is not what the frozen calculation produced.

Three things are now distinguished:

| | status |
|---|---|
| registered verdict | **unchanged** — `gravito_system_harmful` |
| post-reveal causal interpretation | **corrected** — by this note |
| efficiency thesis | **unanswered** |

## What reproduction falsified

Both claims underpinning the published bootstrap-deadlock explanation are
refuted by fresh-clone reproduction (`build-os/bootstrap/DIAGNOSIS.md`):

1. **Receipt creation does not require already-open mutation authority.**
   PACKET-0055's deadlock guard successfully permits the exact routing command
   the arms issued, verbatim, on a clean clone — gate exit 0.
2. **Missing `live_state/` does not prevent routing bootstrap.**
   `route-task.sh` creates an open receipt on a clean clone with no
   pre-existing live state at all, and `Edit` passes the gate immediately
   afterwards.

**Gravito's own routing machinery was not broken the way the record said it
was.**

## What actually happened

3. **The platform permission layer denied the required `route-task.sh` Bash
   command** in the measured headless sessions — `This command requires
   approval` — and a headless session has no approver.
4. **Native Claude was also denied many Bash operations** — 102 of 261 calls,
   against Gravito's 48 of 100. The denials were symmetric, and native was
   denied *more* in absolute terms.
5. **Native could continue through auto-approved `Edit`.** Its work path did
   not depend on the denied class.
6. **Gravito's architecture made one denied Bash operation a total mutation
   precondition** — including for `Edit`, which the host would have allowed.
7. **Therefore the host permission policy interacted asymmetrically with
   treatment.** Native paid denials as friction; Gravito paid one as paralysis.

Host permission mode was **not a registered experimental condition**. It was
chosen mid-execution by the harness after `dontAsk` proved to deny writes.

## The corrected interpretation, as ruled

> **EXP-0005 validly measured `gravito_system_harmful` under the frozen
> execution environment, but the whole-system efficiency comparison is
> confounded by an unregistered host-permission interaction that prevented
> Gravito from entering its mutation path.**

EXP-0005 demonstrates harmful behaviour under the particular
headless/auto-permission environment used. It does **not** establish that a
normally approved interactive Gravito session would have produced 0/12, and it
does not estimate the efficiency of a normally operational substrate.

The operator's earlier ruling — that this was a genuine clean-start bootstrap
failure rather than a confound — **was based on an incorrect diagnosis, which I
supplied.** The ruling is corrected here rather than quietly superseded.

## The product defect is renamed

| | |
|---|---|
| **superseded** | `missing_live_state_bootstrap_deadlock` |
| **current** | `authority_bootstrap_permission_class_mismatch` |

Human-derived finding **B2** in `POST-OUTCOME.md` (durability classification /
"disposable state is load-bearing") is **contradicted by reproduction**: the
absent live state was never the blocker, and initialising it would not have
fixed EXP-0005. B1 survives in corrected form.

**Corrected invariant:**

> First mutation authority must not depend on an operation class whose host
> permission requirements are stricter than the mutation class it authorizes.

Concretely: a worker allowed to perform `Edit`/`Write` under the host policy
must have a Gravito-native path to earn the routing authority for `Edit`/`Write`
without first requiring a separately approval-gated `Bash` command.

## Consequence for future benchmarking

Any later efficiency comparison must use **fresh tasks** and must **explicitly
register the host permission mode as part of the treatment environment**.
EXP-0005 is not rerun.

## Unchanged elsewhere

The `treatment_never_executed` vocabulary candidate remains useful, with its
causal example updated: catastrophic non-action can arise from a
product/host interaction, not only from an internal bootstrap deadlock. No
disposition rule is fitted to EXP-0005. Four-surface readiness remains a
separate gap and still **FAIL**.
