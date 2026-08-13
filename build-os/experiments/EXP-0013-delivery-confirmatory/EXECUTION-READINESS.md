# EXP-0013 Stage A — EXECUTION READINESS (launch-minus-one)

> **SUPERSEDED (historical document).** The owner-authorized adversarial
> audit REFUTED this verdict — see PRE-SPEND-AUDIT.md and AMENDMENT-V3.md:
> the v2 corpus was structurally void (seed/measured code disjointness),
> the budget gate had no durable spend source, seed distillation was
> unimplemented, the analysis median was direction-biased, and the freeze
> missed additions/permissions. The verification tool of record is now
> freeze3.mjs; this file is kept byte-stable as history except this notice.

## VERDICT: READY_FOR_SPEND_AUTHORIZATION

Every launch-blocking item below is materialized, executable, and proven with
zero spend. The single provider-side unknown (the exact dated model id) is
handled by a preregistered pattern set with a fail-before-second-call abort.
Nothing in this leg ran real inference; the controller's rehearsal stopped at
its mandatory NO_PROVIDER_CALL barrier with a PATH-shadow tripwire untripped.

## 1. Exact corpus (materialized, oracle-validated — corpus/sequences.json)

Source: empathiq-website archived at pinned commit
`2543c873141fa64653a7993d326465d5e0dd1006` (real repo never modified; archive
pattern identical to sealed EXP-0011). Baseline: `npx tsc --noEmit -p
tsconfig.json`, 781 error lines (corpus/baseline-tsc.txt, digest recorded).

Derivation rule stated before any error inspection; one DISCLOSED amendment:
`emotional-geometry-runtime` ranked first post-exclusion but is the
quarantined coherence-field source (pre-existing owner constraint) — excluded
on subsystem identity only, recorded in the corpus artifact, before any error
content was examined.

| Task | File | Baseline errors | Codes |
|---|---|---|---|
| S1.p1 (seed) | server/deployment/deployment-router.ts | 15 | TS2322 TS2339 TS2345 TS2551 TS2554 |
| S1.p2 | server/deployment/deployment-persistence.ts | 14 | TS18047 |
| S1.p3 | server/deployment/cms-content-layer.ts | 12 | TS18047 |
| S2.p1 (seed) | server/agent/mcp/unified-gravito.ts | 11 | TS2305 TS2352 TS2554 TS2740 TS2769 |
| S2.p2 | server/agent/mcp/domains/persistence.ts | 8 | TS2339 TS2345 |
| S2.p3 | server/agent/mcp/unified-tool-bridge.ts | 8 | TS2339 TS2345 |

Disjoint from EXP-0011 ({governance, mcp}; zero file overlap — S2's files are
under server/agent/mcp/, a distinct tree; resemblance disclosed). All six
tasks pass the deterministic oracle: initially failing, hermetic,
codes-match, regression-sensitive, line-shift robust. Commercial-shaped
(drizzle schema drift, null-db guards, missing exports) — no toys.

## 2. Model and invocation config (frozen — harness/model-config.json)

Model `claude-opus-5`, explicit on every call, never "default". Allowed
provider-native id set (preregistered): `claude-opus-5`,
`^claude-opus-5-\d{8}$`; id extracted from call 1's stream; mismatch aborts
before call 2. CLI pinned 2.1.229 (preflight equality, executed in
rehearsal). Full argv frozen; prompt via STDIN only; permission-mode
acceptEdits; allowedTools tsc-only; scrubbed env; no automatic retries.

## 3. Seed semantics and exact call count

ONE neutral renderer-independent seed call per sequence at p1 (no UCDL
treatment, no renderer). Its distilled store is digest-pinned before p2 and
is the SAME store for p2 and p3 in BOTH arms — no arm-dependent accumulation
can contaminate any pair. Planned calls: **10** (2 seeds + 8 measured).
Worst case: **16** (≤1 seed rerun per sequence, ≤2 whole-pair reruns = 4
cells, per the frozen reliability gate). No calibration calls (serial
topology needs none).

## 4. Spend ceiling (grounded in measured EXP-0011 costs)

Same model, same task shape, n=40 measured cells: mean $1.87, p90 $3.39, max
$4.28. Per-call worst-case bound $6.00. Planned ≈ **$19**; worst case 16 x
$6 = **$96**; proposed ceiling **$100**. Budget gate proven: the controller
refuses BEFORE any call whose projection crosses the ceiling
(BUDGET_CEILING, tested).

## 5. Topology: SERIAL (default, recommended)

One worker at a time across the whole study (concurrency=1 frozen in
config). The synthetic CPU calibration is not provider-isolation proof and
prior E4 contamination showed load-inflated elapsed — so serial is the
default, elapsed stays secondary, token metrics primary. Wall-clock
estimate: ~10 x 10min median ≈ 100 min planned; hard worst case 16 x 20min
ceiling + per-cell tsc ≈ 6h.

## 6. Controller state machine (harness/controller.mjs — exercised, not asserted)

freeze verify (v1+v2) → study lock (exclusive, typed conflict) → CLI
preflight → H0 gate → isolation manifest + per-sequence archive worktrees →
sealed-order load (commitment verified) → per cell: real planner descriptor
(gravito init/goal → constructReachability → plan → cognition_requirement)
→ real UCDL delivery with pair equivalence → typed admissibility → prompt
digest → budget gate → PROVIDER BARRIER. Rehearsal writes a semantic request
digest per would-be call and stops; measured mode REFUSES without an owner
spend-authorization. Supervised execution closes FAILURE-MODES rows 2 and 4
with observables (see FAILURE-MODES-ADDENDUM.md): single-supervisor spawn →
group SIGKILL at ceiling with terminal_reason → post-cell /proc orphan scan.
Telemetry failures are typed (NOT_METERED / MALFORMED / DUPLICATE / STALE /
MODEL_ID_*), all tested against fixtures.

## 7. Arm-order mapping commitment (sealed NOW)

Balanced 2/2 draw over the 4 measured pairs, drawn with rejection-sampled
crypto randomness, sealed with salts OUTSIDE the repository; repo carries
only the commitment: `corpus/ARM-ORDER-COMMITMENT.json`, commitment
`3f3725a5979e1120a8d075e35ea24a3607512391a8d3eb96e73fa895ae2e1df9`.
Tamper and absence are typed refusals (tested). DISCLOSED: the sealed store
dies with this container; if absent at spend time the controller refuses,
and the only honest recovery is a fresh disclosed draw + fresh commitment
before any launch — never a reconstructed mapping.

## 8. Role separation

Three views (execution controller / blinded adjudicator / comparative
analyst) via frozen views.mjs with the mechanical leak check; blinding salt
sealed alongside the order salt. Reveal remains a one-way post-freeze
operation.

## 9. Analysis (frozen BEFORE outcomes — harness/analysis.mjs)

Pure function of cell records enforcing: delivery gate voids the stage on
one unintended-empty; rerun bookkeeping (max 1/pair, 2 total); reliability
(≤1 infra-invalid of 8); acceptance as mandatory quality gate (unaccepted
arm ⇒ no efficiency statistic); primary = paired log ratio of
output+uncached tokens (cache-insensitive); label-neutral SD vs the 0.45
gate; effect-continuation ladder; elapsed demotion under detected
concurrency; never pools EXP-0011; four pairs never proof. Proven against
all ten preregistered synthetic scenarios (both directions, null, mixed
signs, unaccepted, rerun, void, missing telemetry, high variance, demotion).

## 10. No-call rehearsal evidence (rehearsal-evidence/)

Official run: 56 hash-chained green steps in controller-log.jsonl (freeze v2
verified in-run), 10 semantic request digests (each with explicit model
flag, full argv, stdin byte digest), rehearsal-summary sentinel
`NO_PROVIDER_CALL`, PATH-shadow claude tripwire NEVER executed.

## 11. Freeze (v2, preserving v1)

FREEZE-MANIFEST-v2.json — 13 artifacts including the byte-identical v1
manifest, corpus, oracle, telemetry, model config, seal-orders, controller,
analysis, addendum, and the readiness suite.
v2 digest: `2299f379af8dc6a0eac1460e7dee58fee855b06f240de2cc494479780df347d8`
(v1 digest `1291c0ae8befdfb4c8aa0711e12f539928662d6a8262822ea834b899b7c326df`,
unchanged). Tamper on any artifact is a typed refusal naming the file
(tested on a disposable copy).

## 12. Defect found and fixed during this leg (disclosed)

`tests/exp0013_fixture_tests.sh` section 7 ran `freeze.mjs create` IN PLACE,
silently rewriting the committed v1 manifest's source commit whenever the
suite ran at a different HEAD, and touch-restoring frozen fixture.mjs bytes.
Detected when v2 verification caught the v1 manifest drift mid-battery. The
section now runs create/verify/tamper on a disposable copy and asserts the
real tree's frozen files are unmodified. The sealed v1 manifest was restored
byte-identical from git before v2 was rechecked. (The fixture TEST file is
not itself a v1-frozen artifact; the fix does not touch any frozen bytes.)

## 13. Suites (all green after the fix, freeze intact afterwards)

exp0013_fixture 22/22 · exp0013_readiness 32/32 · planner 25/25 ·
control_primitives 47/47 · neurocosmology_invariant 21/21 ·
context_delivery 12/12 · goal_enforcement 34/34 · lifecycle 35/35 ·
doc_drift 10/10 · cross_repo_isolation 14/14 · authority_envelope 126/0 —
**378 checks, 0 failures**, FREEZE v1+v2 verify after the full battery.

## 14. Statuses (unchanged, conservative)

UCDL fixture wiring: wired-unproven (disposable scope only). Treatment
effectiveness: UNPROVEN. Renderer comparison: UNRUN. Stage-A harness:
qualification mechanisms proven no-spend; QUALIFIED/NOT_QUALIFIED is decided
only by the mechanical gates after measured cells run.

## 15. What spend authorization does NOT cover

Stage B (separate go), any parallel real workers, any production UCDL
wiring, any push/PR/merge/deploy, coherence-field activation, outcome
reveal (separate one-way step after analysis freeze conditions are met).

## 16. Exact spend-authorization wording needed from the owner

> Explicit owner spend authorization for EXP-0013 Stage A: run the measured
> Stage-A study exactly as frozen under FREEZE-MANIFEST-v2.json (digest
> 2299f379af8dc6a0eac1460e7dee58fee855b06f240de2cc494479780df347d8) and
> arm-order commitment 3f3725a5...ae2e1df9: model claude-opus-5 (allowed
> provider ids: claude-opus-5, claude-opus-5-YYYYMMDD pattern;
> fail-before-second-call on mismatch), 10 planned provider calls (2
> unmeasured seeds + 8 measured cells), a hard maximum of 16 calls under the
> frozen rerun rules, SERIAL topology, per-cell wall-clock ceiling 1200s,
> and a hard spend ceiling of $100 USD enforced by the pre-call budget gate.
> Stop immediately on: any unintended-empty delivery (stage void), a second
> infrastructure-invalid cell, rerun-budget exhaustion, model-id mismatch,
> freeze or commitment verification failure, or ceiling projection breach.
> No interim outcome reads; analysis only after all admissible cells finish;
> reveal remains a separate one-way step. This authorization covers no push,
> no PR, no merge, no deploy, no production change, no Stage B.

If the sealed order store has been lost to container reclaim by the time
this authorization arrives, the controller will refuse; a fresh disclosed
draw + fresh commitment (same procedure, new hash) must be generated and
this wording re-issued with the new commitment before launch.
