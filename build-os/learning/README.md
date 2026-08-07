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
