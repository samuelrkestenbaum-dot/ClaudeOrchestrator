# Current State

> The "where are we" snapshot. The orchestrator reads this first every session.
> The archivist advances it when a packet closes. Keep it short and true.

## Project

- **What this repo is:** Build OS control/orchestrator repo — packets, receipts, and memory for builds it directs (product work lands in separate repos).
- **Primary branch / base:** claude/add-build-os
- **Build/test command:** none (docs/config repo)

## Where we are

- **Last closed packet:** P-003-S2 — Phase 1 Repository Auditor — Slice 2: first deterministic detector slice (LG-001, LG-002, LG-004) wired through the §9 ScannerFn seam.
- **Now:** none active.
- **Next:** P-003-S3 (next deterministic detector slice) — awaiting orchestrator confirmation and explicit go (see build-os/packets/active_packet.md for the staged candidate).

## Stable facts (slow-changing)

- LaunchGraph product repo lives at samuelrkestenbaum-dot/LaunchGraph; local checkout at /home/user/LaunchGraph.
- LaunchGraph's founding scope is PRODUCT_SCOPE.md (root commit c7267e8).
- LaunchGraph's first buildable target is the Part II production-readiness layer.
- Phase 1 spec lives at LaunchGraph `specs/phase-1-repository-auditor.md` (commit 5621aa9, branch claude/launchgraph-product-scope-43pgdx).
- Phase 1 decision ceiling is `ready_with_warnings` until Phase 3+.
- LaunchGraph now has a tested proof surface PLUS three working deterministic detectors (branch tip ea9d250): S1 surface (`src/schema`, `src/checks/registry`, `src/decision/engine`, `src/report/serialize`, `src/eval/harness`) + S2 scan substrate & detectors (`src/scan/{collect,redact,scanner}.ts` [SEC-6 traversal, SEC-4 redaction, composed ScannerFn], `src/checks/lg00{1,2,4}.ts` [LG-001/002/004] + `detectorKit.ts`) wired through the §9 harness seam. 115 tests / 12 files; zero runtime deps; build/test commands `npm test` + `npm run typecheck` in the LaunchGraph checkout.
- Fixtures on branch: inert `fixtures/unsupported/` (S1) + `fixtures/broken-lg-00{1,2,4}/` and `fixtures/clean-min/` (S2), all `private: true`, no scripts, excluded by vitest/tsconfig; `clean-min` `ready` is documented as SUBSET-SCOPED, not a Phase-1 product verdict.
- **TEST-DATA POLICY now in force:** fake provider-key literals in fixtures/tests must keep short suffixes (<20 contiguous alphanumerics) so GitHub secret scanning does not block pushes (established resolving the P-003-S2 push-protection incident).
- AT-17 closed; AT-01/02/04 exercised for LG-001/002/004; AT-20/AT-22 mechanisms unit-proven (hostile-fixture closure deferred); AT-23/25/26 reinforced; AT-16 (golden) and AT-24 (eval CLI) deferred to later slices.

---
_Updated by the archivist on close of P-003-S2 (2026-07-23)._
