# EXP-0013 Stage A — PREREGISTRATION (frozen at commit recorded in FREEZE-MANIFEST.json)

Stage A is a HARNESS-QUALIFICATION experiment before it is an outcome
experiment. EXP-0011's lesson governs: LeanRules delivered zero bytes in
10/12 matched cells, so no sample size could have repaired the treatment.
The first duty here is proving both treatments receive EQUIVALENT SELECTED
EVIDENCE through one shared policy and budget, with representation the only
varied factor.

## Design (fixed)

- 4 matched pairs / 8 measured cells. Two fresh, disjoint task sequences
  (S1, S2), two matched pairs per sequence (positions p2, p3 — positions
  where accumulated knowledge exists; p1 has no store by construction and
  is run unmeasured to seed the store).
- Arms: renderer=lean_skills vs renderer=lean_rules. Native/no-context is
  NOT a Stage-A arm.
- Within each pair, identical: model, effort, tools, authority, timeout,
  repository seed, task, acceptance criteria, verification, normalized
  store snapshot (digest-pinned), selector policy (insight-first@1),
  evidence budget, selected evidence-unit IDs and payload digest.
- The experimental factor is representation only: UCDL renderer 'skill'
  (SKILL.md surface) vs 'context' (session-context block). Selection
  precedes rendering by UCDL construction; renderers cannot re-select
  (invariant-tested at the UCDL layer).
- Arm order per pair: coin-flipped, precommitted, balanced 2/2 across the
  4 pairs; mapping sealed (salt out of repo) before any execution.
- No interim outcome read. Analysis only after all admissible cells finish.
- The 38 EXP-0011 cells are EXPLORATORY_DESIGN_EVIDENCE: they informed the
  variance estimate (SD of paired log cost-ratio 0.3125) and this design;
  they are never pooled with EXP-0013 outcomes (treatment and harness
  changed).

## Treatment contract (fixed)

selected = S(E, plan.cognition_requirement, budget, insight-first@1),
computed once per pair; canonical selected IDs + payload digest persist in
the delivery receipt BEFORE rendering. Renderers may change representation
syntax/packaging only. Byte accounting distinguishes evidence_payload_bytes
(must be equal within a pair), renderer_overhead_bytes (may differ), and
total_installed_bytes. Truncation rule: insight atoms first by score,
exhibits into remaining room — identical across renderers by construction;
any truncation-identity divergence is INVALID. Query terms come from the
planner descriptor's objective_terms — the harness never reconstructs task
requirements.

## Pre-spend admissibility (fixed; ANY failure = typed invalidation, no worker call)

Valid planner descriptor (CONTEXT_REQUIRED, non-empty objective_terms,
correlation id) · identity match (repo/goal/task/sequence/position/ids) ·
same store digest, policy version, budget, selected IDs, payload digest in
both arms · non-empty selection AND non-empty rendered output at p>=2 ·
complete hash-chained receipt · unique isolation paths · frozen
prompt/task/authority/acceptance digests · prompt via stdin (never argv) ·
no study-lock conflict · H0 calibration acceptable · freeze manifest
intact. ONE unintended empty treatment reaching model execution voids
Stage A entirely. The harness is never patched mid-study.

## Gates (fixed; mechanical; direction never consulted)

- DELIVERY: zero unintended empty deliveries; selected-evidence identity
  equal within every pair; all receipts complete. Any failure VOIDS Stage A.
- RELIABILITY: <=1 infrastructure-invalid cell of 8; an invalid cell's
  PAIR is rerun once as a whole (both arms, fresh order draw) — max one
  rerun per pair, max 2 reruns total; more = NOT_QUALIFIED. No
  sampling-until-success: reruns are triggered by typed infrastructure
  reasons only, never by outcomes.
- CONCURRENCY: no-spend deterministic calibration first
  (build-os/delivery/calibrate-noload.mjs, <10% bound); if two-lane
  concurrency inflates elapsed >10% vs solo, measured runs go fully serial
  and elapsed demotes to tertiary. Token metrics remain primary
  (load-robust per provider-native usage fields). Calibration is never an
  outcome.
- VARIANCE/CONTINUATION: paired log-ratio SD computed only after
  completion, on label-neutral |log ratio| values. Predeclared: SD <= 0.45
  supports the existing Stage-B powered-n calculation (20 pairs for
  ~18-20% at 80%/alpha .05); SD > 0.45 requires recomputation and
  re-authorization. "Harness qualified" and "effect promising" are
  separate verdicts.

## Effect-continuation ladder (fixed; expansion ALWAYS needs a separate owner spend go)

- |median paired difference| < 10% or inconsistent signs: no automatic
  expansion; report weak practical signal; owner decides.
- 10-20%: expansion justifiable only at the newly fixed powered n derived
  from the label-neutral variance.
- >= 20-25% with consistent signs: proceed only to the preregistered fixed
  confirmatory n. Four pairs are NEVER proof; magnitude-worth-studying is
  not "Gravito won".

## Metrics (fixed)

- PRIMARY: paired log ratio of (output_tokens + uncached input_tokens),
  exact provider-native fields. Acceptance is a mandatory quality gate,
  never traded against tokens: a pair with an unaccepted arm contributes
  NO efficiency statistic — it is reported as a quality result
  (cheap failure vs expensive success is not efficiency).
- SECONDARY: total cost USD with cache categories reported separately;
  elapsed per the concurrency verdict (secondary or tertiary).
- RECORDED, not primary: total tokens, cache read/creation, turns, tool
  calls, retries, context expansions, failed hypotheses, rework,
  regressions. Human interventions are explicitly recorded per cell (an
  intervention log; zero must be recorded as observed-zero, not assumed).
- Missing telemetry = NOT_METERED / NOT_RECORDED, never inferred.

## Isolation and topology (fixed)

One worker lane per sequence; positions serial within a sequence; both
arms of a pair never concurrent (executed back-to-back in the precommitted
order). Per-sequence isolated worktree, baseline cache, tmpdir, results
dir, ledger, prompt namespace (scheduler.mjs isolationManifest). No
unrelated work on measured resources. Provider-side cache warming between
back-to-back arms is a RECORDED limitation: the primary metric is
cache-insensitive by definition, and cache categories are reported.

## Blinding roles (fixed)

Execution controller (knows arms, never compares) / blinded adjudicator
(opaque unit IDs, objectives, acceptance criteria, diffs — no arm labels,
no economics) / comparative analyst (outcomes+economics by opaque unit ID,
no mapping until the one-way reveal). Views generated by
harness/views.mjs; mechanical leak-check enforced; mapping sealed with
salt out of repo; reveal is a separate one-way post-freeze operation.

## Status vocabulary at Stage-A close (fixed)

Stage-A harness: QUALIFIED or NOT_QUALIFIED from the mechanical gates
only. Treatment effectiveness: UNPROVEN. Renderer comparison: UNRUN until
the measured cells execute under a separate spend authorization.

## Unfrozen (declared)

Final task content, sequence corpora selection (per the frozen procedure:
two disjoint subsystems, tsc-error clusters, same eligibility rules as
EXP-0011's corpus builder), and the sealed arm-order draws — all generated
and sealed at spend authorization, before any worker launch.
