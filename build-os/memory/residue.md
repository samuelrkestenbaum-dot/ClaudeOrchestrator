# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

## Standing constraints (bind every future slice)

- **TEST-DATA POLICY** (P-003-S2, from the GitHub push-protection incident; reinforced P-003-S3): fake provider-key literals on EVERY surface — fixtures, tests, receipts, memory — must keep SHORT suffixes (<20 contiguous alphanumerics) so GitHub secret scanning does not block pushes. A shortened literal still exercises detectors (e.g. LG-002's `[A-Za-z0-9]{4,}`) and still redacts correctly. Especially applies to LG-003 (webhook-secret prefix) and any Supabase/Resend key fixtures. Resolve push-protection this way — NEVER by allowlisting a secret. (P-003-S3 shortened a pre-existing over-length webhook-secret literal in `tests/scan/redact.test.ts` as a disclosed hygiene fix.)
- **DETECTOR-SLICE externalVerification OBLIGATION** (P-003-S1, still binding): every finding on LG-003/010/012/014/015 must carry `externalVerification` (or an unverified classification) — that is what enforces the §7 Phase-1 ceiling; AT-16 is the backstop. **Now proven in code for LG-003 (`stripe`) and LG-015 (`dns`)** (P-003-S3); LG-008 carries it only on its partial/external branch (`supabase`), never on its confirmed-fail branch. **Still pending for LG-010/012/014** — binds the moment any of them land. The scanner never represents repository evidence as provider-side proof.
- **CEILING INVARIANT — `hasAppSignal ⊇ scanner.supported`** (P-003-S3 watch-item, standing): the Phase-1 `ready_with_warnings` ceiling holds because LG-015's app-signal gate is a strict SUPERSET of the scanner's `supported` predicate, so every supported repo emits an LG-015 finding carrying externalVerification → decision Rule 7 (`ready`) is unreachable; unsupported repos hit Rule 1 (`not_evaluated`). Any future slice that BROADENS `scanner.supported` OR NARROWS LG-015's applicability gate without preserving this superset could open an unqualified-`ready` hole. Add a regression assertion when the `golden/`/AT-16 fixture lands.

## Deferred (follow-up packets)

- ~~(P-001) Part II of LaunchGraph PRODUCT_SCOPE.md retains conversational provenance from its source ("This feedback is right", two references to "the attachment", heading "My recommendation") → candidate packet: add a one-line provenance note if the owner wants the doc fully standalone; not required.~~ **RESOLVED by P-002** (commit 3a5ad85 — Part II made standalone; residue phrases 0 matches at HEAD).
- ~~(P-001) Likely next packet: LaunchGraph Phase 1 "Repository auditor" per PRODUCT_SCOPE.md section 35 / Part II first milestone (deliberately incomplete reference SaaS + 15 checks).~~ **SUPERSEDED by P-002** — the Phase 1 spec now exists (`specs/phase-1-repository-auditor.md`); implementation tracked below.
- (P-002) Phase 1 implementation must be decomposed into ≤2-commit packets at go time — **IN PROGRESS, being consumed slice by slice**: P-003-S1 (proof surface) closed 2026-07-23; P-003-S2 (LG-001/002/004 + composed ScannerFn) closed 2026-07-23; P-003-S3 (LG-003/008/015 + externalVerification passthrough + ceiling flip) closed 2026-07-23; the spec's AT-01..AT-29 remain the program's done criteria, not one packet's. Queued slices: remaining externally-bound pure-D detectors LG-010/LG-014 (keep externalVerification obligation), the D+M / model-layer detectors (LG-005/006/009/011/013 are D+M, LG-007 is M — a model-layer decision the orchestrator must make), the scan/eval CLI (closes AT-24 + exit codes), remaining fixtures incl. `hostile/` and real `golden/`.
- (P-002) "Later Phase 1 packets" queued behind the auditor core: cost estimation + launch-plan generation; capability graph as versioned asset; recipe selection.
- (P-002) External-side verification of LG-003/010/012/014/015 is owned by Phase 3.
- (P-003-S1) Spec clarification candidate: rule-5 behavior for contradictory non-fail outcomes is unspecified; consider a validator invariant "contradictory ⇒ outcome ∈ {fail, unknown}".
- (P-003-S1) Harness debt: greedy matching is not optimal assignment for overlapping expected entries; `discoverFixtures` silently skips manifest-less dirs — tighten when the eval CLI slice lands.
- (P-003-S1) Cheap test strengthener: rule 5 with a warning-severity finding on a blocker-ceiling check.
- (P-003-S2) **LG-001 SOURCE-PATH SCANNING deferred** — §3 lists "hardcoded in source on production paths" as an LG-001 signal; current impl covers config carriers only (`.env.production*`, `vercel.json`). Source-path scanning was deliberately omitted to avoid the `process.env.X || 'http://localhost'` dev-fallback false-positive idiom (disclosed in the `lg001.ts` docstring, not silently dropped). Revisit when the model layer / report surface lands.
- (P-003-S2) AT-16 real `golden/` fixture + AT-20/AT-22 hostile-fixture closure deferred to later slices. `clean-min/` is a subset-scoped negative fixture — as of P-003-S3 it demonstrates the `ready_with_warnings` ceiling (no longer emits unqualified `ready`), but AT-16's real golden repo is still owed.
- (P-003-S3) **LG-008 warning-outcome enhancement** — for the narrow sub-case of a lone CONCRETE remote DB URL committed in an *unscoped* carrier (plain `.env` / a single `vercel.json` entry) with no per-environment separation, consider emitting a warning-outcome repo-side finding rather than folding it into the external `unknown`, so spec §3 LG-008 condition (b) reads as a repo-side smell. Non-blocking.
- (P-003-S3) **LG-003 provider-agnostic webhook presence** — `isWebhookRoute` treats any *webhook* route as present (a non-Stripe webhook route reads as present). Fine for this deterministic slice; refine later without treading on LG-004. Non-blocking.
- (P-003-S3) **SPEC-DISCREPANCY NOTE** — the P-003-S3 go-instructions' challenge-3 premise mis-attributed LG-011's "localhost / preview host" language (§3) to LG-015. §3 LG-015's only fail conditions are "no canonical production URL configured anywhere, or configured values disagree." The builder's presence-not-correctness handling is spec-faithful (a localhost prod URL counts as PRESENT → LG-015 pass/unverified; LG-001 owns the dev-origin blocker). The authoritative spec is unchanged; no action — recorded so future slices do not propagate the confusion.

## Known risks / debt

- (P-003-S2, non-blocking hardening from reviewer) LG-001 `URL_KEY_RE` substrings (`base`/`site`/`origin`) can over-match benign env keys — but can only shift pass↔unknown, never manufacture a false blocker.
- (P-003-S2, non-blocking) `vercel.json` evaluation in LG-001 assumes single-line key/value.

## Visibility items (outside Build OS scope)

- **Gravito governance gap** (user-flagged 2026-07-23, explicitly non-blocking, not a Build OS packet): "the live substrate-readiness check still reports Claude, Manus, and surplus_recovery as missing surfaces — remains visible as a distinct Gravito governance gap" (user, 2026-07-23). Recorded for visibility only; carried forward through P-003-S3.

## Open boundaries (awaiting explicit go)

- NO merge to any default branch in either repo (ClaudeOrchestrator, LaunchGraph) and NO pull request — both await explicit go. Feature-branch pushes were explicitly authorized and completed (P-001, P-002, P-003-S1, P-003-S2, P-003-S3 — the S-slices under standing authorization after qa green + reviewer pass; P-003-S3 pushed as a normal fast-forward `ea9d250..47fbb8d` after a two-repo pre-push scanner-safety grep). No deploys, no secrets touched/allowlisted, no provider access.

---
_Append-only working notes. Updated by the archivist on close of P-001
(2026-07-23), P-002 (2026-07-23), P-003-S1 (2026-07-23), P-003-S2 (2026-07-23),
and P-003-S3 (2026-07-23)._
