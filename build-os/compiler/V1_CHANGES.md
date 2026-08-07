# Context Compiler v1 — what EXP-0004 changed

EXP-0004 returned **`context compilation harmful`**. That result is frozen and
permanent. This document is what the product did about it.

The experiment found **two distinct defects**, and the verdict was decided by
only one of them. They are fixed in that order.

## A. Semantic-dependency preservation — the defect that decided the verdict

E2's compiled arm cleared all 13 TS2353 errors and still lost: it dropped
`name: input.name` from the `PolicyDefinition` handed to `pceUpsertPolicy` and
re-attached it only to the returned object, regressing a covering test.

**The v0 capsule was not missing the file.** It admitted 17 tests for E2. It was
missing the *claim*: a path plus a symbol list says "this test exists", not
"this test asserts that a policy keeps its name". Admitting more files would not
have fixed it and would have made defect B worse.

New: `compile/semantic.mjs`, a deterministic evidence layer answering a
different question — *if a fix changes the meaning or placement of a value, who
relies on that meaning?* Five rules, each carrying a file:line anchor:

| rule | what it says |
|---|---|
| `mocked-module` | a test **replaces** this module, so a shape change is invisible to it |
| `asserted-symbol` | an assertion names one of its symbols |
| `asserted-property` | an assertion names a property it writes into an object literal |
| `property-consumer` | a non-test importer reads such a property |
| `importing-test` | a test imports it (weakest — a relationship, not a dependency) |

**The strongest signal was free and v0 ignored it.** E2's error text literally
named the property:

    error TS2353: Object literal may only specify known properties,
    and 'name' does not exist in type 'PolicyDefinition'.

`errorSignals()` extracts the property and type named by TS2353 / TS2339 /
TS2741 / TS2551, and evidence about those properties is **promoted above
everything else** — because deleting the named property is the likeliest wrong
answer to these diagnostics.

Two selection defects were found and fixed while building this:

- **Budget-by-discovery-order.** The first cut capped evidence as it was
  collected, so one 40-assertion test drained the whole budget for its defining
  file and the quiet witness was crowded out. Selection now round-robins across
  *consumers*, so a chatty neighbour cannot silence a quiet one.
- **Line-anchored property extraction.** `PROP_KEY` matched only at line start,
  making every **single-line** object literal invisible —
  `upsert({ name: input.name })` yielded nothing. It passed on this repository
  only because the literals that mattered happened to be multi-line. Caught by
  a synthetic fixture, not by the repo.

Measured on the E2 seed: evidence about `name` — including the asserting test —
now reaches the capsule where before it did not.

**What this does NOT claim.** It surfaces the dependency the worker deleted
blind. It does not prove the worker would heed it, and E1–E5 were **not**
re-run to claim v1 "would have passed" — those outcomes are observed, so
measuring against them would be post-treatment tuning of a frozen experiment.

## B. Disclosure overhead — the economics defect

v0 emitted one ~500-byte paragraph per declined candidate. A capsule declining
134 files spent roughly **67 KB explaining what it had chosen not to send**. A
selective-attention system that pays more to describe its exclusions than to
carry its inclusions has inverted its own purpose.

The prompt now carries a **summary and a handle**: declined count, counts
grouped by ladder rung, the five highest-risk declined candidates, a sha256 of
the complete declined set, and the name of a sidecar `.tsv` artifact holding it
verbatim. **Auditability moved; it was not dropped** — and the test that
guarded it was re-pointed at the new representation rather than deleted, so
"nothing is dropped silently" is still enforced.

Measured, same five task descriptors, same budgets, same seed:

| task | v0 capsule.md | v1 capsule.md | change |
|---|---:|---:|---:|
| E1 | 133,034 | 97,159 | **−27.0%** |
| E2 | 175,288 | 142,471 | **−18.7%** |
| E3 | 76,979 | 53,859 | **−30.0%** |
| E4 | 185,598 | 159,527 | **−14.0%** |
| E5 | 94,533 | 68,978 | **−27.0%** |
| **total** | **665,432** | **521,994** | **−21.6%** |

**21.6% smaller while ADDING semantic evidence.** Output stays byte-identical
across runs.

**Still honest about what remains:** at 54–160 KB these capsules are still
large. The remaining bulk is admitted `relevant_files` symbol lists, not
disclosure. That is the next target, and this pass did not solve it.

## C. Selective compilation — compilation is no longer assumed universal

Across five matched pairs the compiled arm ranged from **3.3× the uncached
tokens** of the standard arm (E2) to **59% fewer** (E4). A mechanism with that
spread is not uniformly wrong; it is **unrouted**.

New: `compile/should-compile.mjs`, a deterministic pre-execution decision
returning `compile` | `standard_context` | `insufficient_evidence`, with
reasons. `insufficient_evidence` is distinct from refusal on purpose: an
unmeasurable capsule is not the same as a bad one.

**Threshold provenance, stated because it is the thing most likely to be got
wrong:** every threshold is derived from a *structural* property of a capsule
and is **NOT fitted to which EXP-0004 tasks happened to win**. Fitting them to
five observed outcomes would predict nothing. Each constant carries the
structural reason it exists, all are v1 defaults, and their predictive value is
**UNMEASURED** — the module says so in its own output.

## D. Regression fixtures

`compile/compiler-v1.test.mjs` — **25 assertions, all synthetic**, covering the
E2 *shape*, a mocked module, a chatty-neighbour crowd-out, large declined sets,
weak parser fidelity, missing-parser boundaries, unmeasured signals, refusal
falling back to standard context, and determinism.

None re-runs EXP-0004's frozen tasks.

## Verification

| suite | result |
|---|---|
| `compiler_capsule_tests.sh` | 133 passed, 0 failed |
| `compiler_index_tests.sh` | 107 passed, 0 failed |
| `compiler_expansion_tests.sh` | 102 passed, 0 failed |
| `compiler_capability_tests.sh` | 81 passed, 0 failed |
| `compiler_verifier_tests.sh` | 147 passed, 0 failed |
| `context_mode_tests.sh` | 177 passed, 0 failed |
| `eligibility_workflow_tests.sh` | 129 passed, 0 failed |
| `exp0004_blinding_tests.sh` | 207 passed, 0 failed |
| `exp0004_harness_tests.sh` | 160 passed, 0 failed |
| `compiler-v1.test.mjs` (new) | 25 passed, 0 failed |

**1,268 assertions, 0 failures.** The EXP-0004 suites are included deliberately:
the frozen experiment's machinery must still pass unchanged, and it does.

Not run: the remaining 33 suites in `tests/`, which exceed a single timeout
window and are unrelated to the compiler. That is a stated gap, not a claim of
a full green.

## What is NOT changed

- No EXP-0004 artifact was altered, regenerated or re-run.
- The compiler remains **INERT**: nothing here wires it into a live routing
  path.
- No learned model. The routing decision is deterministic, as instructed.
