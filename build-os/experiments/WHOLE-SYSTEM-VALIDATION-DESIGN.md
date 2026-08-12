# Whole-system validation — owner-directed proof objective and PROPOSED design

*Recorded mid-EXP-0011 (writing only; that study is untouched and running).
Status: PROPOSED FOR REVIEW. Not frozen, not launched, not pushed. Owner
review happens after EXP-0011's frozen read; execution happens only after the
owner resolves the decisions listed at the end.*

## Primary question (owner's words, the program's post-EXP-0011 objective)

**Does full Gravito produce equivalent-or-better independently accepted
product outcomes faster, with fewer exact model tokens and less human
involvement than native Claude?**

## Arms

- **A — native Claude:** fresh sessions, ordinary repo access. No Gravito
  memory, compiled context, routing, durable task state, or governance
  assistance.
- **B — full Gravito as intended:** persistent state, focused context,
  routing, bounded workers, durable handoffs, verification, authority
  controls.

Held equivalent: model access, repo seed, authority, tools, acceptance
criteria. Cross-arm leakage prevented by construction (below).

## Substrate

One meaningful, untouched product/repository (owner-selected — NOT
empathiq-website, which is the experiment corpus and is contaminated for this
purpose) and 10–20 independently selected matched tasks, plus one end-to-end
milestone with blinded independent acceptance.

## Contamination controls

1. Repo untouched by prior experiments; both arms seed from the same pinned
   commit; separate clones per arm per task; no shared caches of work
   product.
2. Task selection by a process independent of the builder: a frozen
   mechanical rule over the repo's issue/defect surface, or an owner-named
   third party — decided before any task list exists.
3. Arm B's memory/skills accumulate ONLY from its own arms; arm A never sees
   Gravito artifacts; task order interleaved/paired so neither arm
   systematically benefits from later, easier work.
4. Acceptance is blinded: the acceptor receives diffs/outcomes stripped of
   arm identity, in shuffled order, and scores against a rubric frozen before
   data.
5. All Gravito setup/orchestration/verification/recovery overhead is
   metered and charged to arm B; results reported GROSS (overhead included)
   and NET (marginal), both always.

## Telemetry schema (per task, both arms)

accepted/rejected + rubric scores · exact provider-native tokens (input,
output, cache_read, cache_creation) · wall-clock and active time · cost ·
human interventions (count, minutes, transcript) and rescue minutes ·
retries, failed hypotheses, rework · regressions introduced · context
supplied and expanded (bytes) · durable commits/functionality landed ·
fresh-context continuation result (can a cold session continue the work from
durable state alone?) · arm-B overhead ledger (setup/orchestration/
verification/recovery, itemized).

## Primary metrics (owner-fixed)

1. Accepted outcomes per million tokens.
2. Accepted outcomes per active hour.
3. Total milestone elapsed time.
4. Human minutes per accepted outcome.
5. Defect-adjusted acceptance.

Tokens are not joules: any compute/energy translation appears only as a
clearly labeled model with stated assumptions, never as a measurement.

## Stopping rules and reliability (frozen before data, per the roadmap)

Harness reliability qualification precedes the study with a frozen maximum
invalid-run rate and stopping rule; a breach stops the run for harness
repair, and repaired-harness data never silently mixes with pre-repair data.
Preregistered n (10–20 pairs + 1 milestone); no mid-stream design edits; the
mid-run-change rule stands (orthogonal runtime fixes only, with disclosure
and identity proof).

## Sample limitations, stated in advance

Small n (10–20 pairs), one repository, one task family, one model tier, one
operator environment. The evidence can support: a directional whole-system
comparison on THIS repo/task family with exact token/time/human-minute
accounting, and existence proofs (e.g. "full Gravito completed the milestone
with X human minutes and native required Y"). It cannot support: universal
efficiency claims across codebases/domains, energy claims, model-agnostic
claims, or long-horizon compounding beyond the measured positions.

## What existing evidence already proves vs what remains hypothetical

Proven (closed, preregistered): the worker-control tax and its removal
(2.44×→1.10×/1.26× native, audited); prose memory does not compound
(EXP-0009); verified rule memory compounds on cost/uncached at modest
magnitude (EXP-0010); mechanical distillation/provenance/TOM-guard machinery
works; the active-executor runtime and event-driven recovery work.

Hypothetical (untested, exactly what this validation exists to test): that
FULL Gravito — orchestration, routing, durable state, and governance
together, overhead included — beats native on accepted outcomes per token,
per hour, and per human minute, at milestone scale, under blinded
acceptance. Prior whole-system evidence (EXP-0005, old architecture) was
NEGATIVE (gravito_system_harmful, bootstrap deadlock); the lean rebuild
invalidated that architecture but its whole-system successor has never been
measured. This design is the successor's test, and its result is genuinely
open.

## Composition with the staged roadmap

POST-EXP-0011-ROADMAP.md's sequence (calibration gate → staged A/B/C studies
→ reliability qualification) and this whole-system validation both claim the
post-EXP-0011 window. Ordering is an OWNER DECISION (below); the default
proposal is: calibration + reliability qualification first (they are cheap
and gate everything), then whichever of {staged A/B/C, whole-system
validation} the owner sequences first.

## Owner decisions required before this design can freeze

1. **Repository** — which untouched product repo (and its pinned seed).
2. **Task selection authority** — frozen mechanical rule vs named third
   party; and the matched-pair criteria.
3. **Blinded acceptor** — who/what performs independent acceptance, and the
   rubric's author.
4. **"Milestone" definition** — the end-to-end deliverable and its
   acceptance bar.
5. **Human-intervention protocol** — when a human may intervene, how minutes
   are metered, and what counts as a rescue.
6. **Ordering** — whole-system validation vs staged A/B/C studies.
7. **Budget** — duration, token spend ceiling, and parallelism (post-
   calibration) for the run.
