# Provider-adapter contract — v0 (LANE-4-adapter-contract)

This is the v0 formalization of `build-os/memory/provider_adapter_contract.md`:
the governance doctrine is host-independent; what a given AI host can SEE,
STOP, and HONESTLY MEASURE is an adapter property. This document names the
**ten lifecycle operations** every adapter is measured against, the invocation
protocol, and the honesty rules. The conformance driver is
`build-os/adapters/conformance.sh`; the executed evidence is
`tests/adapter_contract_tests.sh`.

**Provider-neutral by construction.** Everything here runs without provider
credentials. A provider adapter earns `supported: true` claims only through an
executed successful call — never through documentation, plausibility, or hope.
The **mock adapter is proof of CONTRACT behavior, not of any provider**: it
demonstrates what conformance looks like, and demonstrates nothing about any
network host.

## Invocation protocol (executable adapters)

```
<adapter-cmd> <operation>     # request JSON on stdin, response JSON on stdout
```

Exit codes: `0` = ok, `2` = **refused** (declared-unsupported, missing
authority, or policy block — the response says why), `1` = internal error.
Every response is a JSON object carrying at least `op` and
`status: "ok" | "refused" | "error"`. A refusal is a first-class outcome:
**an adapter MUST refuse what it cannot or may not do, and MUST NOT fake it.**

## Telemetry tiers (the one vocabulary)

`EXACT` (counted by the adapter itself, attempts not completions) —
`ESTIMATE` (a labeled derived proxy, never billing truth) —
`CLOSE-TIME` (reconcilable from provider telemetry after the run) —
`UNAVAILABLE` (not visible on this surface; admitted, never guessed).
**An adapter may never report a tier above what it measures.** No tier
masquerades as a higher one, in declarations or in live responses.

## Capability declaration and the four-state provider honesty

Every adapter ships a declaration conforming to
`build-os/adapters/capability-schema.json`: per lifecycle point —
`supported` (bool), `tier`, `enforcement` (`pre` | `post` | `none`), `notes`.
`verification.state` is `executed` (evidence in this repo's suites) or
`unverified`. An **unverified** adapter MUST publish the four access facts —
`binary_present`, `auth_present`, `host_reachable`, `successful_call` — and
MUST NOT mark any lifecycle point supported. Absent access never blocks the
architecture: an unverified adapter is information, not coverage, and its
declaration still validates.

The schema's **named illegal combinations** (refused by the driver, by name):
`UNSUPPORTED-TIER-CLAIM`, `EXACT-TELEMETRY-WITHOUT-OBSERVATION`,
`UNVERIFIED-SUPPORT`, `PHANTOM-ENFORCEMENT`.

## The ten lifecycle operations

### `task_start`
In: `{task_id, description?, mode?, resume?}`. Out: `{status, task_id, state}`.
MUST persist task state before answering ok; MUST refuse a duplicate start of
a live task; with `resume: true` MUST restore an interrupted task from its
resume state, counts intact. MAY carry provider session identifiers. MUST NOT
report `started` for state it did not write.

### `context_delivery`
In: `{task_id, context: [...]}`. Out: `{status, delivered}`. MUST record what
was actually delivered and refuse for an unknown task. MAY summarize. MUST NOT
claim delivery of context the surface cannot see (a hook-based adapter that
cannot read prompt content declares this point unsupported — as adapter #1
honestly does).

### `authority_grant`
In: `{task_id, authority: {mutation: bool, ...}}`. Out: `{status, authority}`.
MUST persist the envelope before any dependent mutation is admitted. MAY
narrow a requested envelope. MUST NOT grant external mutation
(push/deploy/publish/secrets) — that authority belongs to the operator's
explicit go, never to an adapter.

### `mutation_event`
In: `{task_id, tool, target?}`. Out: `{status, mutation_events}`. With
`enforcement: pre`, MUST refuse a mutation with no admitting authority BEFORE
it executes, with a visible reason. MUST count admitted events at tier EXACT
(attempts, not completions). MUST NOT admit silently: every admission lands in
state attributable at close. Classification heuristics MUST be named as
heuristics (adapter #1's Bash class is evadable by `sh -c` — stated, not
hidden).

### `telemetry_report`
In: `{task_id}`. Out: `{status, degraded, fields: {name: {value, tier}}}`.
MUST label every field with its tier; MUST report unmeasured fields as
`value: null, tier: UNAVAILABLE`; counts MUST derive from recorded state, not
a stored counter. MAY include provider-specific fields. MUST NOT promote a
tier: an ESTIMATE proxy stays labeled ESTIMATE everywhere it appears.

### `receipt_bind`
In: `{task_id, receipt_id}`. Out: `{status, receipt_id}`. MUST bind subsequent
events to the named receipt so activity is attributable at close. MUST refuse
for an unknown task. MUST NOT rebind silently — a rebind is an event in state.

### `completion`
In: `{task_id}`. Out: `{status, state, mutation_events, receipt_id?, degraded}`.
MUST refuse completion of an unknown task, an already-complete task, or an
interrupted task that has not resumed. MUST carry the final EXACT counts and
the degradation fact. MUST NOT conceal that a task degraded or was interrupted.

### `interruption`
In: `{task_id, reason?}`. Out: `{status, resumable, state_file}`. MUST leave a
**resumable state file** preserving the task's counts and bindings — an
interrupted task leaves state, not silence. MUST mark the task interrupted so
completion is refused until resume. MAY be invoked by the host or the operator.
MUST NOT destroy prior events.

### `degradation`
In: `{task_id, reason, evidence?}`. Out: `{status, degraded}`. MUST require a
reason (silent degradation is refused); MUST persist reason and evidence; all
subsequent `telemetry_report` and `completion` responses MUST carry
`degraded: true`. Degrading stops the expensive mode, never the task.

### `capability_declaration`
In: `{}`. Out: the adapter's capability declaration (schema above). Every
adapter MUST implement this operation, and its output MUST match the
declaration file it ships — a live adapter that claims more than its file is
nonconforming. MUST NOT tailor claims per caller.

## Conformance

`conformance.sh <capability.json>` — schema level: structure, vocabularies,
and the named illegal combinations. Add `--exercise <adapter-cmd>` for the
behavioral level: the driver walks all ten operations, proves pre-enforcement
(mutation before authority refused), tier labeling, degradation propagation,
interruption/resume, and that every declared-unsupported operation is refused,
not faked.
