# Current State

> The "where are we" snapshot. The orchestrator reads this first every session.
> The archivist advances it when a packet closes. Keep it short and true.

## Project

- **What this repo is:** Build OS control/orchestrator repo — packets, receipts, and memory for builds it directs (product work lands in separate repos).
- **Primary branch / base:** claude/add-build-os
- **Build/test command:** none (docs/config repo)

## Where we are

- **Last closed packet:** P-003-S3 — Phase 1 Repository Auditor — Slice 3: deterministic detectors LG-003, LG-008, LG-015 (externalVerification obligation first binds).
- **Now:** none active.
- **Next:** P-003-S4 (next deterministic / model-assisted detector slice) — awaiting orchestrator confirmation and explicit go (see build-os/packets/active_packet.md for the staged candidate; includes a model-layer decision to flag).

## Stable facts (slow-changing)

- LaunchGraph product repo lives at samuelrkestenbaum-dot/LaunchGraph; local checkout at /home/user/LaunchGraph.
- LaunchGraph's founding scope is PRODUCT_SCOPE.md (root commit c7267e8).
- LaunchGraph's first buildable target is the Part II production-readiness layer.
- Phase 1 spec lives at LaunchGraph `specs/phase-1-repository-auditor.md` (commit 5621aa9, branch claude/launchgraph-product-scope-43pgdx).
- Phase 1 decision ceiling is `ready_with_warnings` until Phase 3+.
- LaunchGraph now has the tested S1 proof surface PLUS **six working deterministic detectors** (branch tip `47fbb8d`): S1 surface (`src/schema`, `src/checks/registry`, `src/decision/engine`, `src/report/serialize`, `src/eval/harness`) + scan substrate (`src/scan/{collect,redact,scanner}.ts` — SEC-6 traversal, SEC-4 redaction, composed §9 ScannerFn) + detectors `src/checks/lg00{1,2,3,4,8}.ts` + `lg015.ts` (**LG-001/002/003/004/008/015**) via `detectorKit.ts`, all wired through the §9 harness seam. 131 tests / 15 files; zero runtime deps; build/test commands `npm test` + `npm run typecheck` in the LaunchGraph checkout.
- **externalVerification obligation is now proven in code** for LG-003 (provider `stripe`) and LG-015 (provider `dns`); LG-008 carries it only on its partial/external branch (provider `supabase`), never on its confirmed-fail branch. The scanner never represents repository evidence as provider-side proof. Still pending for LG-010/012/014.
- **clean-min now demonstrates the `ready_with_warnings` ceiling** (flipped from the S2 subset-scoped `ready`): a repo-present-but-unverified external finding yields `ready_with_warnings`, and no fixture yields unqualified `ready`.
- **CEILING INVARIANT (load-bearing):** `hasAppSignal ⊇ scanner.supported` — every supported repo emits an LG-015 finding carrying externalVerification, so decision Rule 7 (`ready`) is unreachable. Any slice that broadens `supported` or narrows LG-015's gate must preserve this superset.
- Fixtures on branch: inert `fixtures/unsupported/` (S1) + `fixtures/broken-lg-00{1,2,3,4,8}/`, `fixtures/broken-lg-015/`, and `fixtures/clean-min/` — all `private: true`, no scripts, excluded by vitest/tsconfig.
- **TEST-DATA POLICY in force:** fake provider-key literals in fixtures/tests/receipts/memory must keep short suffixes (<20 contiguous alphanumerics) so GitHub secret scanning does not block pushes; never allowlist a secret (established resolving the P-003-S2 push-protection incident, reinforced by the S3 redact-test hygiene fix).
- AT-17 closed; AT-01/02/04 exercised for LG-001/002/004; AT-03/08/15 exercised for LG-003/008/015; AT-20/AT-22 mechanisms unit-proven (hostile-fixture closure deferred); AT-23/25/26 reinforced; AT-16 (golden) and AT-24 eval CLI deferred to later slices.

---
_Updated by the archivist on close of P-003-S3 (2026-07-23)._
