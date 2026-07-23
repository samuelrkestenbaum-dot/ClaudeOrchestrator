# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

## Deferred (follow-up packets)

- ~~(P-001) Part II of LaunchGraph PRODUCT_SCOPE.md retains conversational provenance from its source ("This feedback is right", two references to "the attachment", heading "My recommendation") → candidate packet: add a one-line provenance note if the owner wants the doc fully standalone; not required.~~ **RESOLVED by P-002** (commit 3a5ad85 — Part II made standalone; residue phrases 0 matches at HEAD).
- ~~(P-001) Likely next packet: LaunchGraph Phase 1 "Repository auditor" per PRODUCT_SCOPE.md section 35 / Part II first milestone (deliberately incomplete reference SaaS + 15 checks).~~ **SUPERSEDED by P-002** — the Phase 1 spec now exists (`specs/phase-1-repository-auditor.md`); implementation tracked below.
- (P-002) Phase 1 implementation must be decomposed into ≤2-commit packets at go time — **IN PROGRESS, being consumed slice by slice**: P-003-S1 (proof surface) closed 2026-07-23; the spec's AT-01..AT-29 remain the program's done criteria, not one packet's. Queued slices: S2+ detectors (deterministic first), CLI (scan/eval, closes AT-24), remaining 17 fixtures, model layer, SEC-4 redaction.
- (P-002) "Later Phase 1 packets" queued behind the auditor core: cost estimation + launch-plan generation; capability graph as versioned asset; recipe selection.
- (P-002) External-side verification of LG-003/010/012/014/015 is owned by Phase 3.
- (P-003-S1) **DETECTOR-SLICE OBLIGATION:** every finding on LG-003/010/012/014/015 must carry `externalVerification` (or unverified classification) — that is what enforces the §7 Phase-1 ceiling; AT-16 is the backstop. Carry this into every detector slice's packet notes.
- (P-003-S1) Spec clarification candidate: rule-5 behavior for contradictory non-fail outcomes is unspecified; consider a validator invariant "contradictory ⇒ outcome ∈ {fail, unknown}".
- (P-003-S1) Harness debt: greedy matching is not optimal assignment for overlapping expected entries; `discoverFixtures` silently skips manifest-less dirs — tighten when the eval CLI slice lands.
- (P-003-S1) Cheap test strengthener: rule 5 with a warning-severity finding on a blocker-ceiling check.

## Known risks / debt

- none beyond the deferred items above

## Visibility items (outside Build OS scope)

- **Gravito governance gap** (user-flagged 2026-07-23, explicitly non-blocking, not a Build OS packet): "the live substrate-readiness check still reports Claude, Manus, and surplus_recovery as missing surfaces — remains visible as a distinct Gravito governance gap" (user, 2026-07-23). Recorded for visibility only.

## Open boundaries (awaiting explicit go)

- NO merge to any default branch in either repo (ClaudeOrchestrator, LaunchGraph) and NO pull request — both await explicit go. Feature-branch pushes were explicitly authorized and completed (P-001, P-002, P-003-S1 — the latter under standing authorization after qa green + reviewer pass); no deploys, no secrets touched, no provider access.

---
_Append-only working notes. Updated by the archivist on close of P-001
(2026-07-23), P-002 (2026-07-23), and P-003-S1 (2026-07-23)._
