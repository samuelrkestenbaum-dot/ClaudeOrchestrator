# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

## Deferred (follow-up packets)

- ~~(P-001) Part II of LaunchGraph PRODUCT_SCOPE.md retains conversational provenance from its source ("This feedback is right", two references to "the attachment", heading "My recommendation") → candidate packet: add a one-line provenance note if the owner wants the doc fully standalone; not required.~~ **RESOLVED by P-002** (commit 3a5ad85 — Part II made standalone; residue phrases 0 matches at HEAD).
- ~~(P-001) Likely next packet: LaunchGraph Phase 1 "Repository auditor" per PRODUCT_SCOPE.md section 35 / Part II first milestone (deliberately incomplete reference SaaS + 15 checks).~~ **SUPERSEDED by P-002** — the Phase 1 spec now exists (`specs/phase-1-repository-auditor.md`); implementation tracked below.
- (P-002) Phase 1 implementation must be decomposed into ≤2-commit packets at go time — the spec's AT-01..AT-29 are the program's done criteria, not one packet's.
- (P-002) "Later Phase 1 packets" queued behind the auditor core: cost estimation + launch-plan generation; capability graph as versioned asset; recipe selection.
- (P-002) External-side verification of LG-003/010/012/014/015 is owned by Phase 3.

## Known risks / debt

- none

## Open boundaries (awaiting explicit go)

- NO merge to any default branch in either repo (ClaudeOrchestrator, LaunchGraph) and NO pull request — both await explicit go. Feature-branch pushes were explicitly authorized and completed (P-001, P-002); no deploys, no secrets touched.

---
_Append-only working notes. Updated by the archivist on close of P-001
(2026-07-23) and P-002 (2026-07-23)._
