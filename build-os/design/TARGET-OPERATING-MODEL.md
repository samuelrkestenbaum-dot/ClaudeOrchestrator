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

## The manifest acceptance rule

Every proposed LEAN_MANIFEST change must identify **which measured
worker-control interaction it removes** (by Step 2 class: gate_mechanism_diagnosis,
capability_search, routing_bookkeeping, repeat final_report, gate_challenge_response,
authority_blocked round-trips) **and what substrate-side mechanism replaces that
interaction**. A row that only says "reduce context", "simplify prompt", or
"make the gate shorter" fails the TOM test and does not ship.

The post-Lean compliance check is the existing frozen instrument — no new
measurement framework: did gate_mechanism_diagnosis collapse, did
capability_search collapse, did routing_bookkeeping collapse, did repeat
final_report collapse, did acceptance remain intact, did total cost improve.

## The full model — seven layers (operator, recorded at phase close)

What the closed phase proved is **Layer 1**. The destination is larger:

> Models are replaceable workers. Gravito owns the company/repository's durable
> cognition, state, authority, evidence, learning, coordination, and improvement
> loop — while workers receive only the smallest sufficient task state and
> largely never think about Gravito itself.

| Layer | Target | Status |
|---|---|---|
| 1. Control plane | authority, evidence, continuation, recovery, routing substrate-side | **PROVEN** — 2.26× → 1.10–1.26× native with controls intact, replicated |
| 2. Cognition compiler | each worker gets only task-relevant objective/state/history/constraints | next |
| 3. Organizational memory | facts, attempts, outcomes, learned procedures persist beyond any model/session | next |
| 4. Workforce orchestration | Claude/GPT/Manus interchangeable, selected by capability/economics | plumbing incomplete (Operator Lab sees ChatGPT only) |
| 5. Program operating system | goals, priorities, dependencies, convergence owned by Gravito | partial (program.json, convergence gate) |
| 6. Learning / self-improvement | outcomes improve memory, skills, routing, compilation, bounded harness pieces — by evidence, never uncontrolled self-editing | future |
| 7. Business outcomes | optimize completed useful work per dollar/time/human attention | the measure of everything above |

## The roadmap — five phases

1. **Control without tax — DONE.** D1 → D2 → independent audit → D2v.
2. **Compounding advantage** — does organizational cognition make sustained
   work outperform native? Proof order fixed by the operator: (1) persistent
   memory beats rediscovery; (2) a procedure learned on task 1 makes tasks 2–10
   cheaper/better; (3) outcome history reduces retries and rework; (4) compiled
   smallest-sufficient state without triggering search; (5) routing to
   cheaper/specialized workers with outcomes maintained. The signature to look
   for: **native stays flat per task; Gravito's curve falls as experience
   accumulates.**
3. **Replaceable workforce** — any model plugs into the same substrate.
4. **Organizational OS** — objectives, dependencies, evidence, resources,
   multi-agent work over long periods.
5. **Self-improving company substrate** — execute → measure outcome → learn →
   update substrate → next worker starts smarter, under bounded evidence and
   authority, without the base model changing.

The end-state worker experience: a request arrives; Gravito compiles 50,000
organizational facts into the right 20; the worker executes; Gravito governs,
verifies, records, learns, and decides what comes next. The worker never knows
how much sits underneath.

## Placement note

This file lives in `build-os/design/` deliberately: design records are
retained-DATA, never administered as CODE into measured arm trees. A worker
must not carry doctrine about how little workers should know — that would be a
self-referential contamination of the kind this program has repeatedly caught.

## Runtime doctrine (added at EXP-0009 close, operator-dictated)

**Events drive work. Continuous execution state drives liveness. Timers do
neither.** Invariants: `dependency_complete + authorized + runnable => launch
immediately`; `running + heartbeat/progress => continue`; `running +
no_progress + no_known_long_operation => diagnose/recover immediately`. No
scheduled watchdogs, no fallback timers, no wake-up whose purpose is to
discover whether work is alive. Time's one legitimate role is a bounded
no-progress timeout attached to an active state.

**Event-driven sequencing is not enough — Gravito itself is an active
event-processing runtime.** Not a foreman watching workers but a kernel
advancing process state: event arrives → state changes → next transition
decided → action dispatched. It subscribes to execution events (never
periodic polls), exposes real-time state (current state / current action /
last-event age / next transition / blocked-on), and replaces observer stacks
rather than layering on them. Reference implementation:
`build-os/experiments/EXP-0009-memory-compounding/executor.mjs` (attached
live mid-study under the recorded isolation proof — see
MID-RUN-INTERVENTION.md there; retired predecessors: run-study.mjs,
stall-watch.sh, and the scheduled-watchdog Routines, all cancelled).

Learned defect boundary, recorded honestly: an event cannot cross a dead
container while the session is idle — restart notifications arrive only on
next session activity. Closing that residual window (push notification on
milestone/failure, or running work outside the reclaimable container) is
#53's territory.

## Continuation doctrine (#55, operator four-branch rule)

A stop is valid on exactly four grounds, assessed mechanically
(`build-os/motion/continuation.mjs`): an EXPLICIT operator stop (automation
never counts); a genuine blocker after exhaustion across ≥2 route classes; a
material unresolved ambiguity — which is SURFACED by name, never silently
parked as a hold; or the absence of any specified+authorized+runnable+
unblocked+positive-value task. Otherwise the verdict is CONTINUE and a stop
is invalid. Timers detect failure, events drive work, and idleness requires
one of these four reasons.
