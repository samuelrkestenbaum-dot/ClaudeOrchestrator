# Current State

> The "where are we" snapshot. The orchestrator reads this first every session.
> The archivist advances it when a packet closes. Keep it short and true.

## Project

- **What this repo is:** Build OS control/orchestrator repo — packets, receipts, and memory for builds it directs (product work lands in separate repos).
- **Primary branch / base:** claude/add-build-os
- **Build/test command:** none (docs/config repo)

## Where we are

- **Last closed packet:** P-003-S4 — Phase 1 Repository Auditor — Slice 4: warning-ceiling external detectors LG-010, LG-014 (the warning tier is now proven in code).
- **Now:** none active.
- **Next:** a **FORK decision** — stand up the model layer for the remaining Layer-D+M / Layer-M checks (there are NO remaining pure-D checks, so the deterministic-only detector run is COMPLETE), OR run another non-detector slice (e.g. the scan/eval CLI, or remediation packages). Awaiting orchestrator confirmation and explicit go (see build-os/packets/active_packet.md for the staged candidate skeleton).

## Stable facts (slow-changing)

- LaunchGraph product repo lives at samuelrkestenbaum-dot/LaunchGraph; local checkout at /home/user/LaunchGraph.
- LaunchGraph's founding scope is PRODUCT_SCOPE.md (root commit c7267e8).
- LaunchGraph's first buildable target is the Part II production-readiness layer.
- Phase 1 spec lives at LaunchGraph `specs/phase-1-repository-auditor.md` (commit 5621aa9, branch claude/launchgraph-product-scope-43pgdx).
- Phase 1 decision ceiling is `ready_with_warnings` until Phase 3+.
- LaunchGraph now has the tested S1 proof surface PLUS **eight working deterministic detectors** (branch tip `006cadd`): S1 surface (`src/schema`, `src/checks/registry`, `src/decision/engine`, `src/report/serialize`, `src/eval/harness`) + scan substrate (`src/scan/{collect,redact,scanner}.ts` — SEC-6 traversal, SEC-4 redaction, composed §9 ScannerFn) + detectors `src/checks/lg00{1,2,3,4,8}.ts`, `lg010.ts`, `lg014.ts`, `lg015.ts` (**LG-001/002/003/004/008/010/014/015**) via `detectorKit.ts`, all wired through the §9 harness seam. 143 tests / 17 files; zero runtime deps; build/test commands `npm test` + `npm run typecheck` in the LaunchGraph checkout.
- **The WARNING TIER is now proven in code** (P-003-S4): LG-010/LG-014 are Warning-severity, so a repo-side problem is outcome `fail` + severity `warning` (severity from the registry via `makeFinding`, never hardcoded, never outcome `warning`, never blocker). The engine routes fail+warning to warnings, so a fixture seeding only such a problem yields `ready_with_warnings` (exit 0), NOT `not_ready`. LG-001/002/003/004/008/015 remain the blocker tier; LG-010/014 are the first warning-tier detectors. Still no fixture yields unqualified `ready`.
- **externalVerification obligation is now proven in code** for LG-003 (provider `stripe`), LG-010 (provider `resend`), LG-014 (provider `sentry`), and LG-015 (provider `dns`); LG-008 carries it only on its partial/external branch (provider `supabase`), never on its confirmed-fail branch. The scanner never represents repository evidence as provider-side proof. **Among external checks only LG-012 remains pending — and it needs the model layer.**
- **The deterministic-only detector run is COMPLETE.** 8 of 15 detectors done. The remaining 7 — LG-005/006/009/011/013 (Layer D+M), LG-007 (Layer M), LG-012 (Layer D+M, external) — ALL require the model layer. There are no remaining pure-D checks, so the next detector work forces a model-layer decision.
- **clean-min demonstrates the `ready_with_warnings` ceiling** (flipped in S3): a repo-present-but-unverified external finding yields `ready_with_warnings`, and no fixture yields unqualified `ready`.
- **CEILING INVARIANT (load-bearing):** `hasAppSignal ⊇ scanner.supported` — every supported repo emits an LG-015 finding carrying externalVerification, so decision Rule 7 (`ready`) is unreachable. Any slice that broadens `supported` or narrows LG-015's gate must preserve this superset. P-003-S4 left `detectStack`/`supported` and LG-015's gate untouched.
- Fixtures on branch: inert `fixtures/unsupported/` (S1) + `fixtures/broken-lg-00{1,2,3,4,8}/`, `fixtures/broken-lg-01{0,4,5}/`, and `fixtures/clean-min/` — all `private: true`, no scripts, excluded by vitest/tsconfig.
- **TEST-DATA POLICY in force:** fake provider-key literals in fixtures/tests/receipts/memory must keep short suffixes (<20 contiguous alphanumerics) AND avoid any Sentry-DSN shape, so GitHub secret scanning does not block pushes; never allowlist a secret (established resolving the P-003-S2 push-protection incident, reinforced by S3's redact-test hygiene fix and S4's Sentry-DSN-shape avoidance).
- AT-17 closed; AT-01/02/04 for LG-001/002/004; AT-03/08/15 for LG-003/008/015; AT-10/14 for LG-010/014; AT-20/AT-22 mechanisms unit-proven (hostile-fixture closure deferred); AT-23/25/26 reinforced; AT-16 (golden) and AT-24 eval CLI deferred to later slices.

---
_Updated by the archivist on close of P-003-S4 (2026-07-23)._
