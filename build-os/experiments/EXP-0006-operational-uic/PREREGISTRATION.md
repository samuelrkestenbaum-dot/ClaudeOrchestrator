# EXP-0006 — operational UIC, on a substrate that can actually run

**Status: FROZEN.** No measured arm executes before the digest below is
recorded. Anything not written here is not part of the design.

## The question

> Does a functioning Gravito substrate produce more **accepted durable product
> outcomes per unit of compute** than native model execution on the same work?

EXP-0005 asked this and could not answer it. Its Gravito arm returned 0/12
accepted and the verdict `gravito_system_harmful`, because the arm never
obtained first mutation authority on that host — the treatment did not execute.
The experiment measured a precondition failure and reported it as a product
verdict. **EXP-0005 stands frozen and is not amended by this.**

## What is different this time

| | EXP-0005 | EXP-0006 |
|---|---|---|
| preconditions | listed in the preregistration | **executed** against the real host, 7/7, before freeze |
| first mutation authority | assumed | **verified by reading a file the child wrote** |
| session isolation | asserted | verified after scrub + explicit `--session-id`; an unknown comparison **fails** |
| task selection | curated | **derived** from a compiler signal, drawn by seeded hash |

## Preconditions — EXECUTED, results in `results/preflight.json`

| id | outcome |
|---|---|
| `worker_cli_present` | claude 2.1.226 |
| `first_mutation_authority` | **PASS** — a child in `acceptEdits` mutated a file; verified by reading the file, not by the worker's report |
| `session_isolation` | **PASS** — child ran under its own id, distinct from the orchestrator's and equal to the id it was launched with |
| `token_accounting` | `input_tokens` and `cache_read_input_tokens` present, so uncached is derivable |
| `substrate_present` | `build-os`, `.claude`, `CLAUDE.md` |
| `substrate_loads` | four load-bearing controllers import without throwing |
| `host_profile_registered` | `unknown_conservative` — Edit allowed, Bash approval_required, no approver |

The isolation check **passed vacuously on its first run** — it compared against
`CLAUDE_SESSION_ID`, which does not exist here, so the comparison was against
`undefined`. It reported PASS while the child had inherited this session's exact
id. Classified `measurement_critical` and repaired before freeze.

## Task population

- **Source:** `empathiq-website` at `2543c873`, working tree clean. Real product
  work, authored independently of every mechanism under test.
- **Signal:** `tsc --noEmit` typecheck errors. Objective, and it yields
  acceptance criteria by construction.
- **Pool:** 175 files carrying at least one error.
- **Exclusions, fixed before any arm ran:** 75 files removed — 71
  `gravito_adjacent` (touching routing, authority, governance or the Gravito
  embed), 4 `test_files` (changing a test to match the code inverts the
  acceptance criterion). Also excluded by rule: generated output, and work
  needing credentials this host lacks.
- **Eligible:** 100 files.
- **Selection:** seeded hash of the file path, seed `EXP-0006`, first 12.
  Ordering by hash rather than by error count keeps difficulty uncorrelated with
  selection. **Neither the operator nor the executor chose the tasks.**

Selected set, error counts 1–17, client and server, seven distinct TS codes —
recorded in `results/task-selection.json`.

## Arms

Both arms use the **same primary worker model**, `claude-opus-5`. No cheaper
model on either side; a model difference would answer a different question.

**Native** — fresh worker, ordinary task statement, the repository and its
normal tools. `build-os/`, `.claude/` and `CLAUDE.md` are removed from the arm
tree, so no Gravito memory, routing, authority selection, context compilation,
continuation, value gate or Gravito verification is present.

**Gravito** — same model, with the current load-bearing substrate: persistent
memory, routing, live authority compatibility selection, mutation enforcement,
capability exhaustion, continuation and value prioritisation, evidence handling
and verification.

## The metric

```
UIC = accepted durable product outcomes / (uncached tokens / 1_000_000)
```

**All Gravito governance, runtime, context and evidence activity is denominator
cost.** A receipt is not an outcome. A routing decision is not an outcome. If
the substrate spends tokens to govern itself, that spend counts against it.

## Acceptance — independently testable, no judgement

A task is **accepted** when both hold:

1. `npx tsc --noEmit` reports **zero errors for that file**, and
2. **no new error appears in any other file.**

Condition 2 is the regression criterion: silencing an error by breaking a
neighbour is not an outcome. `@ts-ignore`, `@ts-expect-error`, `any` casts and
deleting the offending code are **rejections**, checked by diff.

## Telemetry, per arm per task

acceptance · uncached tokens · total tokens · cost · elapsed · interventions ·
retries/rework · regressions · runtime failures · **whether Gravito entered and
remained operational** (the field whose absence made EXP-0005 unreadable).

## Execution parameters

- permission mode `acceptEdits`; host profile `unknown_conservative`
- session isolation: scrubbed env + explicit `--session-id` per arm
- one common ceiling per task, both arms, recorded before execution
- arms run **sequentially**; a contended measurement is not a measurement

## Stopping rules

New issues are classified, not chased:

- `runtime_critical` → fix before continuing measured work
- `measurement_critical` → fix before admitting the affected run
- `noncritical_debt` → **record and continue**

The existence of real debt is not a reason to stop the benchmark. The anchor
migration, the census reconciliation, broader audit coverage and the
unreconciled `self_gate_hygiene` metric are all **DEFERRED** and do not
interrupt measured work.

## Blinding

Three roles kept unjoinable, as in EXP-0005: executor, adjudicator, analyst.
Adjudicator and analyst identifiers derive from **separate salt domains**, so
neither can reconstruct the other's mapping. The salt and the sealed mapping
stay **outside the repository**; only `mapping.sha256` is committed, and it is
committed **before any arm executes**.

## What a result means

- **Gravito arm higher UIC** — the substrate pays for itself on this work.
- **Native higher** — the governance overhead is not recovered here. That is a
  real answer, not a failure of the experiment.
- **Gravito arm fails to operate** — reported as `treatment_never_executed`,
  **not** as a product verdict. That vocabulary exists because EXP-0005 lacked
  it.
