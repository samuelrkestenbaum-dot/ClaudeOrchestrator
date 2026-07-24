# Current State

> The "where are we" snapshot. The orchestrator reads this first every session.
> The archivist advances it when a packet closes. Keep it short and true.

## Project

- **What this repo is:** Build OS control/orchestrator repo — packets, receipts, and memory for builds it directs (product work lands in separate repos).
- **Primary branch / base:** claude/add-build-os
- **Build/test command:** none (docs/config repo)

## Where we are

- **Last closed packet:** P-004 — Phase 1 Repository Auditor — `launchgraph` scan/eval CLI (Fork Branch B). The proven detector library is now wrapped in a runnable CLI with deterministic exit codes and a JSON + human report surface.
- **Now:** none active.
- **Next:** the **FORK's Branch A** — the **model-layer foundation packet** — awaiting orchestrator shaping + explicit go. It unblocks the remaining 7 checks (LG-005/006/007/009/011/012/013). Likely larger than ≤2 commits, so the orchestrator must decompose it before activation (see build-os/packets/active_packet.md for the staged candidate skeleton).

## Stable facts (slow-changing)

- LaunchGraph product repo lives at samuelrkestenbaum-dot/LaunchGraph; local checkout at /home/user/LaunchGraph.
- LaunchGraph's founding scope is PRODUCT_SCOPE.md (root commit c7267e8).
- LaunchGraph's first buildable target is the Part II production-readiness layer.
- Phase 1 spec lives at LaunchGraph `specs/phase-1-repository-auditor.md` (commit 5621aa9, branch claude/launchgraph-product-scope-43pgdx). NOTE: the spec header still says "not yet implemented" — stale now that implementation is underway; reconcile in a later doc pass (tracked in residue).
- Phase 1 decision ceiling is `ready_with_warnings` until Phase 3+.
- **The `launchgraph` scan/eval CLI now EXISTS** (P-004, branch tip `a4ffbf5`): `run(argv, io): number` — pure, synchronous, returns the exit code; all effects flow through an injected `Io {stdout, stderr, now, cwd, writeFile}`; the bin (`bin/launchgraph.ts`) runs via `tsx` (DEV-only dep). Deterministic exit codes: `ready`/`ready_with_warnings` → 0, `not_ready` → 1, scan/parse error → 2, `not_evaluated` → 3 (unsupported stack → exit 3, closing AT-24 with ZERO findings in the human output). `--json` → `serializeReport` to stdout only, zero files; default → `report.json` + `report.md` + a human banner, writes CONFINED to `--out` (else `<path>/.launchgraph/`). Flags: `scan [path]`, `--json`, `--out`, `--offline`, `--checks`, `--app`; plus `eval` (wraps `runEvaluation`). The `run()`/`Io` seam is the pure entry point the MODEL LAYER will plug into.
- LaunchGraph now has the tested S1 proof surface PLUS **eight working deterministic detectors wired into the runnable CLI** (branch tip `a4ffbf5`): S1 surface (`src/schema`, `src/checks/registry`, `src/decision/engine`, `src/report/serialize`, `src/eval/harness`) + scan substrate (`src/scan/{collect,redact,scanner}.ts`; `scanner.ts` gained an additive behavior-preserving `checks?` option in P-004) + detectors `src/checks/lg00{1,2,3,4,8}.ts`, `lg010.ts`, `lg014.ts`, `lg015.ts` (**LG-001/002/003/004/008/010/014/015**) + CLI (`src/cli/{args,io,run,reportMd,banner}.ts`, `bin/launchgraph.ts`). **181 tests / 20 files** (`npm test`); `npm run eval` → 10/10 decisions correct, 0 blocker FPs. **Zero runtime deps** (tsx is dev-only; all 153 non-root lockfile packages `dev:true`). Build/test commands `npm test` + `npm run typecheck` in the LaunchGraph checkout.
- **The WARNING TIER is proven in code** (P-003-S4): LG-010/LG-014 are Warning-severity, so a repo-side problem is outcome `fail` + severity `warning` (severity from the registry via `makeFinding`, never hardcoded, never outcome `warning`, never blocker). The engine routes fail+warning to warnings, so a fixture seeding only such a problem yields `ready_with_warnings` (exit 0), NOT `not_ready`. LG-001/002/003/004/008/015 remain the blocker tier. Still no fixture yields unqualified `ready`.
- **externalVerification obligation is proven in code** for LG-003 (provider `stripe`), LG-010 (provider `resend`), LG-014 (provider `sentry`), and LG-015 (provider `dns`); LG-008 carries it only on its partial/external branch (provider `supabase`), never on its confirmed-fail branch. The scanner never represents repository evidence as provider-side proof. **Among external checks only LG-012 remains pending — and it needs the model layer.**
- **The deterministic-only detector run is COMPLETE.** 8 of 15 detectors done and now CLI-wired. The remaining 7 — LG-005/006/009/011/013 (Layer D+M), LG-007 (Layer M), LG-012 (Layer D+M, external) — ALL require the model layer (the FORK's Branch A). There are no remaining pure-D checks.
- **clean-min demonstrates the `ready_with_warnings` ceiling** (flipped in S3): a repo-present-but-unverified external finding yields `ready_with_warnings`, and no fixture yields unqualified `ready`.
- **CEILING INVARIANT (load-bearing):** `hasAppSignal ⊇ scanner.supported` — every supported repo emits an LG-015 finding carrying externalVerification, so decision Rule 7 (`ready`) is unreachable. Any slice that broadens `supported` or narrows LG-015's gate must preserve this superset. P-004 left `detectStack`/`supported` and LG-015's gate untouched (the additive `checks?` filter keeps the `stackSupported` short-circuit intact, so `--checks` cannot break AT-24).
- Fixtures on branch: inert `fixtures/unsupported/` (S1) + `fixtures/broken-lg-00{1,2,3,4,8}/`, `fixtures/broken-lg-01{0,4,5}/`, and `fixtures/clean-min/` — all `private: true`, no scripts, excluded by vitest/tsconfig. P-004 added NO fixtures. `eval` currently runs over these 10 present fixtures; §9.3's 15/15-recall and 18/18-decision thresholds remain a program-level gate owed as golden/, hostile/, and the model-layer broken fixtures land.
- **TEST-DATA POLICY in force:** fake provider-key literals in fixtures/tests/receipts/memory must keep short suffixes (<20 contiguous alphanumerics) AND avoid any Sentry-DSN shape, so GitHub secret scanning does not block pushes; never allowlist a secret (established resolving the P-003-S2 push-protection incident, reinforced by S3/S4 and by P-004's scanner-safe CLI outputs — report.md/report.json render only already-redacted evidence).
- AT-17 closed; AT-01/02/04 for LG-001/002/004; AT-03/08/15 for LG-003/008/015; AT-10/14 for LG-010/014; **AT-24 closed (P-004: unsupported → exit 3, zero human-surface findings)**; AT-23/25/26 reinforced (now end-to-end through the CLI); AT-20/AT-22 mechanisms unit-proven (hostile-fixture closure deferred); partial AT-27 (`--offline` deterministic/no network — the "mark M-checks unknown" half is OWED to the model layer); AT-16 (golden) still deferred.

---
_Updated by the archivist on close of P-004 (2026-07-23)._
