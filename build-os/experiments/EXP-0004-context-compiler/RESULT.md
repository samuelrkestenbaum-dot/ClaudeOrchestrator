# EXP-0004 — RESULT (revealed, frozen)

Revealed `2026-08-07T09:30:00Z`. Seal intact. Freeze snapshot
`cfad3e743fc12aeee77a35e06bd4e9c1b2b89662e64126a57f415f8327f58c0c` verified over
14 artifacts. Mapping digest `54e2406f…` equals the one committed at `7be2af7`
before any arm executed.

**The reveal is one-way. Nothing in this file may re-enter the frozen
artifacts.**

## Mapping

| label | condition |
|---|---|
| **Arm X** | `compiled_context` — the Context Compiler |
| **Arm Y** | `standard_context` — current execution |

Assignment rule `experiment-salt-parity`: a pure function of the declared salt
and the task list, recomputable by anyone holding the salt. No sample, no clock.

## Registered outcome

> ## `context compilation harmful`

Reached by the **binding acceptance veto**, not by the economic gates:
*"Compression that costs acceptance is a loss, not a trade. A token or time win
cannot buy back a lost acceptance."* No downgrade path applied.

## Acceptance

| condition | accepted | rate |
|---|---|---|
| compiled | **4 / 5** | 0.80 |
| standard | **5 / 5** | 1.00 |

The one rejection is **E2, compiled**, from the blinded adjudicator: it dropped
`name: input.name` from the `PolicyDefinition` handed to `pceUpsertPolicy` and
re-attached it only to the returned object, regressing
`fix-preview.test.ts > … should support domain filtering in dry-run mode`.
Criteria (a)–(c) held — 13 TS2353 errors cleared, 754 → 740, zero new errors.
Criterion (d) failed. One failure is enough to reject.

## Uncached tokens

| task | compiled | standard | compiled vs standard |
|---|---:|---:|---:|
| E1 | 158,829 | 92,686 | −71.4% |
| E2 | 282,770 | 86,351 | **−227.5%** |
| E3 | 82,172 | 66,453 | −23.7% |
| E4 | 150,856 | 370,158 | **+59.2%** |
| E5 | 82,221 | 99,029 | +17.0% |
| **total** | **756,848** | **714,677** | −5.9% |

**Median: standard uses 19.1% fewer uncached tokens.** The 19.1% belongs to
standard context.

## Elapsed

| task | compiled | standard | compiled vs standard |
|---|---:|---:|---:|
| E1 | 949.79 s | 849.35 s | −11.8% |
| E2 | 1123.41 s | 991.04 s | −13.4% |
| E3 | 823.14 s | 1009.04 s | +18.4% |
| E4 | 1033.51 s | 1249.39 s | +17.3% |
| E5 | 438.27 s | 918.84 s | **+52.3%** |
| **total** | **4368.12 s** | **5017.66 s** | +12.9% |

**Median: compiled is 17.3% faster.** Compiled traded token efficiency for
speed — faster and more expensive.

## UIC — accepted outcomes per 1M uncached tokens

| condition | accepted | uncached | **UIC** |
|---|---:|---:|---:|
| compiled | 4 | 0.757 M | **5.29** |
| standard | 5 | 0.715 M | **7.00** |

**Standard delivers 1.32× the accepted output per unit of inference.**

## Gates — both failed, in both directions

| gate | threshold | compiled | standard |
|---|---|---|---|
| uncached-token reduction | ≥25% median | −23.7% | +19.1% — **short** |
| elapsed | ≥25% faster median | +17.3% — **directional band** | −20.9% — directional harm |

## Secondary counters

| | compiled | standard |
|---|---:|---:|
| rework rounds | **29** | 32 |
| verifier dispatches | **39** | 46 |
| human interventions | 0 | 0 |
| regressions | 1 | **0** |

Compiled was better on rework and verification effort. It lost on the one
counter with a veto attached.

## The distribution is the finding

E1 and E2 are bad, E3 mixed, E4 and E5 promising. E2 cost compiled 3.3× the
tokens; E4 saved it 59%. **Five pairs cannot separate that bimodality from
noise**, and the medians are carrying far more weight than five points can
support. The mechanism is not uniformly wrong — it is unrouted. When to compile
looks like a more important open question than how to compile.

## Two distinct defects, not one

1. **Economics.** Capsules ran 77–185 KB, the majority of it
   `excluded_notable` text explaining what was *not* included. That was
   recorded as the leading suspect **before any arm ran**
   (`BUDGET_PARAMETER.md`), and it is the right suspect.
2. **Quality.** E2's rejection was not verbosity. The capsule failed to
   preserve a semantic dependency, and the worker broke a behaviour it could
   not see. Smaller attention would not have fixed that; **better** attention
   would.

The verdict was decided by (2). The token story never got to matter, because
the acceptance veto fires first.

## Limitation — the analyst blinding failed

Disclosed at `c89b759`, **before** the reveal.

The **adjudicator blinding held**: an independent agent saw only opaque unit
ids, work-product diffs, task criteria, and acceptance evidence with every
economic field stripped. Its 9-accepted / 1-rejected verdict was written into
the records unchanged.

The **analyst blinding did not**. The blinding README warns that anyone holding
both views can join them and that neither blinded role should hold both — and
one agent held both. The adjudication rejected exactly one unit, and the
execution layer already knew which arm carried the single measured test
regression; that alone identifies the mapping. The sealed file was never opened
by this run's operator, but *"did not read it"* is weaker than *"could not
know"*, and only the weaker claim is true.

Bounded, not erased: the calculations, gates and anonymous label are mechanical,
acceptance came from the blind adjudicator, and `calculations` refuses outright
if the adjudication and the records disagree. **Fix for any future run: the
comparative analyst must be a separate agent that sees the analyst view and
nothing else.**

## Limitation — fixture reliability, 10 admitted arms from 14 executions

| pair | attempts | why the earlier ones were void |
|---|---:|---|
| E1 | 2 | arm B never started — prompt exceeded `MAX_ARG_STRLEN` |
| E2 | 1 | — |
| E3 | 1 | — |
| E4 | 2 | arm A truncated at the 1800 s ceiling under CPU contention |
| E5 | 3 | (1) contention + a background-monitor park that did no work; (2) `aborted_streaming` mid-tool-use |

Rule applied throughout, chosen without reference to which condition it helped:
*an arm ending `is_error: true` did not complete its measured window.* A
stopping rule was committed before E5's third attempt and expired unused. All
discarded attempts retained under `pairs-out/*-attempt*/`.

## Limitation — what the standard arm actually was

**Neither arm ran inside the Gravito operating environment.** `.claude/` and
`CLAUDE.md` were sparse-excluded from the work tree for *both* arms, because the
natively installed Build OS injects a capability inventory and routing reminder
at SessionStart and on every prompt — which would have made every arm B start
with the capsule *plus* an injected payload, and `result confounded` on all five
pairs by AMENDMENT 2's own check.

So `standard_context` here is **not** "Gravito minus the compiler". It is a bare
headless session given a well-specified task statement. Both arms did carry
user-scope Serena MCP and a TypeScript language server, so both had semantic
code navigation available.

This scopes the claim precisely: EXP-0004 says **a 77–185 KB compiled capsule
lost to a 1.2 KB task statement**, on this repository, on five type-error
clusters, at n=5. It says nothing about the Gravito operating model as a whole,
which was absent from both arms.

## What this result does NOT establish

- It does not test Gravito-as-a-system against native Claude. Both arms were
  ungoverned.
- It does not generalise past five type-error-cluster tasks in one repository.
- It does not separate the two defects: one regressed test decided the verdict,
  so the economics were never adjudicated on their own terms.
- At n=5 with this variance, it does not establish the sign of the token effect
  with any confidence — only that no direction reached the registered 25% gate.
