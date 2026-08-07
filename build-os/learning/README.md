# Post-Outcome Disposition v0

**The gap this closes.** EXP-0004 returned `context compilation harmful`, and
the evidence for three separate corrective actions was sitting in the frozen
artifacts. Nothing happened until a human read the report and said "action it".
The substrate could *remember* the result; it could not *act* on it.

    experiment -> result -> evidence -> [HUMAN NOTICES] -> product change

This module removes the bracketed step, and nothing else.

## What it is

`disposition.mjs` applies general predicates to a frozen outcome and emits
structured findings: class, severity, confidence, implicated component,
evidence, proposed bounded change, required authority, revalidation
requirement, and a disposition.

| class | disposition it tends to earn |
|---|---|
| `measurement_defect` | `execute` — harden the instrument |
| `product_defect` | `execute` — bounded internal fix |
| `optimization_opportunity` | `execute` — bounded internal fix |
| `unsupported_hypothesis` | `queue` or `observe` — never self-executed |

## What it is NOT

It decides nothing irreversible, holds no authority, and executes nothing.
**`execute` means "eligible to become a bounded packet", never "already done".**
Anything wider than `bounded_internal_product_change` is queued for a human. A
policy question is queued by construction: the evidence supports the *question*,
not the answer.

## The historical fixture

Run against **frozen EXP-0004 artifacts**, with the answer withheld from the
rules, it derives:

| finding | class | disposition |
|---|---|---|
| `compiled-context.correctness` — a rejected outcome carrying a regression | `product_defect` | execute |
| `compiled-context.context_packaging` — 113.8× the starting bytes and still more uncached tokens | `optimization_opportunity` | execute |
| `experiment_harness.reliability` — 10 admitted from 14 executions | `measurement_defect` | execute |
| `compiled-context.routing_policy` — sign flips, 287-point spread | `unsupported_hypothesis` | **queue** |
| `experiment.hypothesis` — no gate met either direction | `unsupported_hypothesis` | observe |

The first three are the corrective actions that became Context Compiler v1. The
fourth is the routing hypothesis. **The engine found two the human review did
not enumerate** — harness reliability and the null-result record.

## The limitation, stated rather than discovered later

These rules were authored by an agent that **had already read EXP-0004's
result**. That is the same failure shape as EXP-0004's own analyst-blinding
break: knowing the answer while writing the detector. Two things bound it, and
neither eliminates it:

1. every rule is a general predicate over the artifact **schema** — acceptance
   counts, per-task deltas, byte fields, admitted-vs-attempted — and none names
   an experiment, task, component or constant drawn from EXP-0004 (asserted by
   a test);
2. synthetic fixtures verify each rule fires on its shape and stays silent
   otherwise — a clean outcome generates **zero** findings, a uniform-sign set
   does not fire the routing rule, a full-yield harness does not fire the
   reliability rule.

**A rule set validated only against the experiment that inspired it has not been
shown to generalise.** The real test is EXP-0005: rules written before its
result, fired on its evidence.

## Not done

- Not wired to any authority mechanism — a disposition cannot yet open a packet.
- No adapters for EXP-0001/0002/0003, so cross-experiment generality is
  **unmeasured**.
- No persistence of disposition state across sessions, so "unfinished learning"
  is not yet a thing the substrate can be asked about.

---

# Step 4 — bounded internal mutation authority

Closes `evidence → finding → disposition → bounded corrective action`, without
making the substrate self-modifying in any wider sense.

## What is now AUTONOMOUS

A finding may **open a corrective packet by itself**, and that packet may be
marked `executable`, when **all six** hold:

1. `disposition === "execute"`;
2. `authority === "bounded_internal_product_change"`;
3. `change_kind` is in the auto-executable set;
4. `change_kind` is not in the never-automatic set;
5. the finding's class is **not** `unsupported_hypothesis`;
6. the finding cites at least one piece of evidence.

Conjunctive by design: a missing condition is a refusal, never a default.

**Auto-executable change kinds** — internal, reversible, fixture-verifiable:
`parser_extractor_defect` · `bounded_relevance_rule` ·
`prompt_disclosure_to_artifact` · `harness_defect` · `regression_fixture`

## What remains ADVISORY

`broad_architecture` · `provider_strategy` · `pricing_gtm` ·
`safety_or_evidence_control_removal` · `external_integration` ·
`irreversible_external_mutation` · `hypothesis_only`

Plus every `queue` and `observe` finding. **`queue` and `observe` are never
silently upgraded** — asserted by test.

## The authority boundary, stated plainly

| | may open a packet | may execute it |
|---|---|---|
| defect / optimization, bounded, evidenced | yes | **yes** |
| hypothesis (`queue`) | yes, as *proposed* | no |
| null result (`observe`) | durable finding only | no |
| anything architectural or external | no | no |

Creating a packet is **not** permission to change anything. Opening and
executing are separate gates.

## Frozen evidence is immutable input

A packet may create product code, tests and outcome artifacts. It may **never**
modify the evidence that produced it — experiment results, `RESULT.md`,
execution logs, mapping digests, task freezes, preregistrations, pilot records.
Enforced twice: a packet declaring a frozen path in its boundary is refused at
creation, and a mutation touching one fails at closure.

New evidence can supersede an old belief. It cannot rewrite history.

## Closure is verification, not code

An `execute` packet is **not** closed when code is written. It closes only when
the regression fixture passes, existing tests pass, every mutated path is inside
the declared boundary, no prohibited adjacent change occurred, and the outcome
is recorded. Otherwise the state is **`unresolved_failed`** —
*a failed corrective action is failed learning, not completed learning.*

## Traceability

`traceBackward()` returns the deterministic chain
`mutation → corrective_packet → finding → outcome → evidence`. Every link is a
recorded identifier, so "why did Gravito change this?" is answered from state
rather than reconstructed afterwards by a model.

## Unfinished learning is substrate state

`unfinishedLearning()` answers, deterministically: execute-class findings with
no completed action; queued hypotheses and what each needs; packets that failed
verification; closed packets with no follow-up evidence; observe-only findings.

An empty result means **no record of unfinished learning**, not that none
exists — stated in the artifact itself.

## Demonstrated on the real frozen findings

The five EXP-0004 findings yield **exactly three executable packets** — the
correctness defect, the packaging defect and the harness defect. The routing
hypothesis and the null-result finding are **refused**, by the rules, not by
hand.

## Still NOT organizational

This is a **single-surface** loop. The four-surface readiness gate reads FAIL:
ChatGPT is active; Claude, Manus and surplus-recovery are not writing into the
shared substrate. Until the relevant surfaces reliably write *and consume* the
same outcome and disposition state, this is a learning loop **inside one
surface** — not an organizational one. Tracked as a separate substrate gap, not
folded into EXP-0005.

## Fixtures

`corrective-packet.test.mjs` — **36 assertions**, covering the defect,
optimization and hypothesis paths end to end; every never-automatic kind
refused; frozen-evidence protection at both gates; boundary escape; failed
verification; traceability; and the unfinished-learning query.
