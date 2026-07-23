# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

## Standing constraints (bind every future slice)

- **TEST-DATA POLICY** (new, P-003-S2, from the GitHub push-protection incident): fake provider-key literals in fixtures/tests must keep SHORT suffixes (<20 contiguous alphanumerics) so GitHub secret scanning does not block pushes. A shortened literal still exercises detectors (e.g. LG-002's `[A-Za-z0-9]{4,}`) and still redacts correctly. Especially applies to LG-003 (`whsec_`) and any Supabase/Resend key fixtures. Resolve push-protection this way — NEVER by allowlisting a secret.
- **DETECTOR-SLICE externalVerification OBLIGATION** (P-003-S1, still binding): every finding on LG-003/010/012/014/015 must carry `externalVerification` (or an unverified classification) — that is what enforces the §7 Phase-1 ceiling; AT-16 is the backstop. Did NOT bind P-003-S2 (LG-001/002/004 are all External = No); binds the next slice the moment LG-003/015 land.

## Deferred (follow-up packets)

- ~~(P-001) Part II of LaunchGraph PRODUCT_SCOPE.md retains conversational provenance from its source ("This feedback is right", two references to "the attachment", heading "My recommendation") → candidate packet: add a one-line provenance note if the owner wants the doc fully standalone; not required.~~ **RESOLVED by P-002** (commit 3a5ad85 — Part II made standalone; residue phrases 0 matches at HEAD).
- ~~(P-001) Likely next packet: LaunchGraph Phase 1 "Repository auditor" per PRODUCT_SCOPE.md section 35 / Part II first milestone (deliberately incomplete reference SaaS + 15 checks).~~ **SUPERSEDED by P-002** — the Phase 1 spec now exists (`specs/phase-1-repository-auditor.md`); implementation tracked below.
- (P-002) Phase 1 implementation must be decomposed into ≤2-commit packets at go time — **IN PROGRESS, being consumed slice by slice**: P-003-S1 (proof surface) closed 2026-07-23; P-003-S2 (first deterministic detectors LG-001/002/004 + composed ScannerFn) closed 2026-07-23; the spec's AT-01..AT-29 remain the program's done criteria, not one packet's. Queued slices: remaining deterministic detectors (LG-003 [needs externalVerification], LG-008, LG-015), then D+M/model-layer detectors, the scan/eval CLI (closes AT-24 + exit codes), remaining fixtures incl. `hostile/` and real `golden/`.
- (P-002) "Later Phase 1 packets" queued behind the auditor core: cost estimation + launch-plan generation; capability graph as versioned asset; recipe selection.
- (P-002) External-side verification of LG-003/010/012/014/015 is owned by Phase 3.
- (P-003-S1) Spec clarification candidate: rule-5 behavior for contradictory non-fail outcomes is unspecified; consider a validator invariant "contradictory ⇒ outcome ∈ {fail, unknown}".
- (P-003-S1) Harness debt: greedy matching is not optimal assignment for overlapping expected entries; `discoverFixtures` silently skips manifest-less dirs — tighten when the eval CLI slice lands.
- (P-003-S1) Cheap test strengthener: rule 5 with a warning-severity finding on a blocker-ceiling check.
- (P-003-S2) **LG-001 SOURCE-PATH SCANNING deferred** — §3 lists "hardcoded in source on production paths" as an LG-001 signal; current impl covers config carriers only (`.env.production*`, `vercel.json`). Source-path scanning was deliberately omitted to avoid the `process.env.X || 'http://localhost'` dev-fallback false-positive idiom (disclosed in the `lg001.ts` docstring, not silently dropped). Revisit when the model layer / report surface lands.
- (P-003-S2) AT-16 real `golden/` fixture + AT-20/AT-22 hostile-fixture closure deferred to later slices. A 3-detector scanner honestly emits unqualified `ready`, which cannot satisfy AT-16's `ready_with_warnings` ceiling; `clean-min/` is a subset-scoped negative fixture proving blocker-FP=0 without overclaiming.

## Known risks / debt

- (P-003-S2, non-blocking hardening from reviewer) LG-001 `URL_KEY_RE` substrings (`base`/`site`/`origin`) can over-match benign env keys — but can only shift pass↔unknown, never manufacture a false blocker.
- (P-003-S2, non-blocking) `vercel.json` evaluation in LG-001 assumes single-line key/value.

## Visibility items (outside Build OS scope)

- **Gravito governance gap** (user-flagged 2026-07-23, explicitly non-blocking, not a Build OS packet): "the live substrate-readiness check still reports Claude, Manus, and surplus_recovery as missing surfaces — remains visible as a distinct Gravito governance gap" (user, 2026-07-23). Recorded for visibility only.

## Open boundaries (awaiting explicit go)

- NO merge to any default branch in either repo (ClaudeOrchestrator, LaunchGraph) and NO pull request — both await explicit go. Feature-branch pushes were explicitly authorized and completed (P-001, P-002, P-003-S1, P-003-S2 — the latter two under standing authorization after qa green + reviewer pass; P-003-S2's push was resolved through GitHub push protection WITHOUT allowlisting a secret, landing as a normal fast-forward). No deploys, no secrets touched/allowlisted, no provider access.

---
_Append-only working notes. Updated by the archivist on close of P-001
(2026-07-23), P-002 (2026-07-23), P-003-S1 (2026-07-23), and P-003-S2 (2026-07-23)._
