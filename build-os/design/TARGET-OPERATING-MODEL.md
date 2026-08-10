# Target Operating Model — operator doctrine, recorded 2026-08-10

**Status: the standing design test for LEAN_MANIFEST and every future feature.**
Declared by the operator while the runnable-verification study was in flight —
before its result was known, so this document cannot have been fitted to it.

> **Gravito runs the company around the model. The model runs the task.**

## The four rules

1. **Models solve tasks; Gravito operates the system.**
2. **Gravito derives decisions; workers receive results, not implementation.**
3. **Context is sufficient and selected — not maximal, and not merely minimized.**
4. **Every unit of governance must improve expected outcomes more than it costs
   in model cognition.**

A proposal that makes the worker think MORE about Gravito starts with a
presumption against it.

## Ownership split

| Layer | Gravito owns | Worker sees/does |
|---|---|---|
| Objective | primary goal, priorities, stop conditions | current task + success criteria |
| Memory | history, prior attempts, durable knowledge | only relevant distilled facts |
| Authority | permissions, grants, policy, risk | simple effective authority state |
| Routing | which worker/model/lane/tool | assigned task; maybe selected tools |
| Continuation | whether more work is worth doing | next task, or clean termination |
| Capability | available paths, host constraints, workarounds | actionable available capabilities |
| Evidence | outcomes, verification, provenance | required verification result |
| Economics | cost, budgets, marginal value | ideally nothing |
| Learning | what worked/failed, policy updates | nothing unless task-relevant |
| Program convergence | whether enough evidence exists | nothing |

The worker should not know how those decisions were derived unless that
information is genuinely required to solve the product task.

## The control transaction moves outside the worker

Today: worker acts → gate fires → worker interprets the refusal → worker reads
gate source → worker searches capabilities → worker files bookkeeping → worker
re-reports. Measured at 77% of the excess text-only turns (STEP2-TEXT-TURNS.md).

Target: worker acts → Gravito runtime resolves authority, capability, routing,
bookkeeping, and state → worker receives **ALLOW / DENY + exact actionable
state** → worker continues. The worker does not participate in administering
the control.

Worker-visible turns that must go to zero or near-zero:

- reading `routing-gate.sh` or any gate source to learn why it fired
- opening/closing routing receipts; declaring lanes; discussing budgets
- explaining routine authority; narrating continuation
- proving the same completed task complete repeatedly
- reading another agent's queue
- deciding whether the program has enough evidence

If those behaviours persist, the target operating model has not been reached —
whatever else improved.

## Capability exhaustion is re-priced, not removed

Keep the concept. Change the rule from "prove every route impossible" to
**"search until the expected value of another step falls below its cost."**
The substrate tracks attempts, distinct capability classes tested, information
yield of the last attempt, and task value — and decides CONCEDE itself. The
worker never produces a legal brief proving helplessness.

## Continuation is substrate-side

Worker says "task complete". Gravito checks acceptance, remaining valuable
runnable work, marginal value, and program stop conditions — then returns
`NEXT TASK: ...` or `COMPLETE`. The pattern "don't stop yet, inspect the queue"
disappears.

## Memory is selective, not resident

Database → query planner → result set; never database → dump into the prompt.
The compiler's objective is NOT minimal context — EXP-0007 variant B proved
subtraction causes compensatory search (0.1 → 11.3 searches/arm). The objective:

> **minimize total cognition cost = supplied context + rediscovery/search
> + mistakes + rework**

The compiled package for a task like the benchmark tasks should be roughly
300–800 tokens: OBJECTIVE / RELEVANT STATE / AUTHORITY / CAPABILITIES /
SUCCESS / EXECUTE — however many hundreds of thousands of tokens of
organizational state sit underneath it.

## What is preserved aggressively

Durable cross-session memory; independent evidence-based acceptance (the
compiler result, never the model's confidence); persistent organizational
identity; recovery; capability awareness; continuation; objective
prioritization; outcome learning; cross-model continuity; convergence.

**The change is who pays the cognition cost of operating them.**

## Runtime shape

Five responsibilities, experienced as ONE coherent runtime, not twenty named
governors: (1) State. (2) Authority. (3) Cognition compilation. (4) Execution
control. (5) Learning/convergence. Everything else becomes an implementation
detail of those five.

## Placement note

This file lives in `build-os/design/` deliberately: design records are
retained-DATA, never administered as CODE into measured arm trees. A worker
must not carry doctrine about how little workers should know — that would be a
self-referential contamination of the kind this program has repeatedly caught.
