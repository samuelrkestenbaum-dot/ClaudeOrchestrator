# EXP-0004 — Context Compiler A/B — PREREGISTRATION

Committed BEFORE the compiler exists. Ancestry is the proof. Registered
because this session's own history (EXP-0002: Gravito ON used 3.96x the
tokens of OFF — an adverse result, published) shows that a plausible
architecture can lose money, and the honest way to find out is to fix the
rule before seeing the data.

## The claim under test (operator's ambition, NOT evidence)

The operator's base-case estimate: 40-65% lower total tokens, 45-70%
lower uncached, 35-65% faster wall-clock, 1.5-3x accepted outcomes per
human hour; central figure "~60% fewer tokens, ~2x faster accepted
delivery". These are HYPOTHESES. Nothing in this repository has measured
them. They are recorded here so the result can be compared against what
was actually predicted, not against a target moved afterward.

## Conditions (both under Gravito; this is not a Gravito on/off test)

- **A — current execution**: the worker receives the task description and
  the repository, as today.
- **B — capsule execution**: the worker receives the compiled capsule and
  may buy more context through the expansion protocol.

Same model, same repo state, same acceptance criteria per task. Task
order counterbalanced. Arms run from identical seeds (`git stash`-clean
tree at the pinned base).

## Task set — MUST NOT overlap PILOT-0002

PILOT-0002's five frozen tasks (trpc bridge cluster, CoverageReportData
drift, agents hermetic tests, training/router interface conflict,
voice-stream/webhooks) are EXCLUDED. Using them would contaminate a
frozen pilot. EXP-0004 draws from a disjoint slice of the 778-error
backlog, chosen and pinned at run time, spanning three shapes the
operator named: simple isolated, ordinary multi-file, complex unfamiliar.

## Metrics (per task, tier-labeled)

total tokens; uncached tokens; cache reads; time to first edit; total
wall-clock; files read; search/grep calls; expansion requests (B only);
failed hypotheses; rework rounds; accepted outcome (y/n); human
interventions; subagents dispatched; verifier triggers fired.

Primary combined metric:
**accepted durable outcomes / (uncached tokens + elapsed + human attention)**

## Registered conclusion vocabulary — SYMMETRIC (the EXP-0002 lesson)

Exactly one, chosen by the rule below, no other wording permitted:

1. `context compilation supported` — B accepted-outcome rate not worse
   than A, AND uncached-token reduction >= 25% median across tasks.
2. `promising but underpowered` — direction favors B on the primary
   metric but the reduction is < 25% or task count too small to separate.
3. `no context-compilation benefit detected` — no median reduction >= 10%,
   or acceptance unchanged with tokens within +/-10%.
4. `context compilation harmful` — B's acceptance rate LOWER than A, or
   uncached tokens HIGHER by >= 10% (the operator's own named failure
   case: a compiler that hides essential context, causing wrong
   hypotheses, repeated expansion, and rework).
5. `result confounded` — a defect in harness, seeding, or arm isolation.

The rule is deliberately symmetric: outcome 4 is as reachable as outcome
1, and acceptance quality can veto a token win. **Compression that costs
acceptance is a loss, not a trade.**

## Blinding

Per-task raw measurements are recorded arm-labeled X/Y with the mapping
withheld and its sha256 committed before analysis; the analysis is
written against the blinded dataset and committed BEFORE the reveal.

## Stop conditions

Halt and record `result confounded` if arms diverge in repo state, if the
capsule leaks into arm A, or if the compiler is wired into any live
routing path during the run (v0 ships inert precisely so this is
detectable).

## AMENDMENT 1 — repository signal is a precondition (recorded before any run)

The first end-to-end integration exposed a confound the original design
missed. Running the merged compiler against THIS repository:

- index: 415 files, 583,282 bytes
- capsule for a JS-seeded task: 6,622 rendered bytes vs 6,589,592 tracked
  repository bytes
- BUT the indexer's own stats: **no_parser 390/415 (94.0%)**, partial
  415/415 (100%), files_with_a_covering_test 4/415 (1.0%)

ClaudeOrchestrator is shell-dominant and v0 extracts symbols only from
JS/TS (plus partial Python/Go/Rust). So on this repo the capsule is small
largely because the index has almost NO structural signal to admit — not
because compilation is efficient. **Small-because-uninformed is the exact
failure mode outcome 4 names.** An A/B run here would measure a compiler
operating nearly blind and could register `context compilation harmful`
for a reason that has nothing to do with the compression thesis.

BINDING AMENDMENT: EXP-0004 may only run on a repository where the index
has measured parser coverage. The precondition is stated as a number, not
a judgement — **no_parser share of files admitted-as-candidates must be
below 50%, measured by `build-index.mjs stats` and RECORDED in the run
record before arm A begins.** A repository failing that check is either
excluded or the run is registered `result confounded` under the existing
stop conditions. Adding a shell extractor to the indexer would also
satisfy it; that is a build decision, not an amendment to this rule.

This amendment is recorded BEFORE any A/B task has been selected or run,
so it cannot function as post-hoc selection of a favourable repository.

## AMENDMENT 2 — arm B must REPLACE broad context, not supplement it

Recorded before any A/B task is selected, closing a gap the original
design left implicit.

Arm B was written as "the worker receives the compiled capsule and may buy
more context through the expansion protocol". That describes what B
RECEIVES but never forbids what B ALSO receives. If the harness delivers
the ordinary broad context AND the capsule, arm B's token usage rises by
construction — the capsule becomes pure overhead, and the experiment would
measure an addition while claiming to test a substitution. A compression
thesis cannot be tested by adding bytes.

BINDING: in arm B the compiled capsule REPLACES the broad-context delivery.
The worker's starting context is the capsule plus the immutable prefix
(SEAM 5) and nothing else; every further byte arrives through a recorded
expansion request (SEAM 3). Arm A is unchanged and receives exactly what
today's execution receives.

MECHANICAL CHECK, run per task before its measurement is admitted: arm B's
initial input must not contain the broad-context payload — verified by
asserting that B's starting bytes equal the rendered capsule plus prefix,
recorded in the run record. A task whose arm B starts with both is
registered `result confounded` under the existing stop conditions and is
excluded from the aggregate; it is not silently repaired and re-run.

COROLLARY, stated so it cannot be discovered late as a surprise: if the
capsule is materially incomplete, arm B pays for the gap twice — once in
expansion requests and once in the rework a wrong early hypothesis causes.
That is not a flaw in the experiment; it is the honest cost of compression
that went too far, and outcome 4 exists to record it.
