# R0 evidence report (running; per-packet executed evidence)

## P0 — evidence refresh (2026-08-12, post-EXP-0011-termination)
- Authority code lives in build-os/tools/authority-envelope.sh (advisory
  validator) + tests/authority_envelope_tests.sh; install surface =
  install-global.sh / install-project.sh / init-build-os.sh /
  connect-project.sh; memory scopes = project build-os/ + user ~/build-os
  (session-start hook reads both). #40 confirmed: no Repository Core
  worktree exists in this environment — Core-resident work is out of reach.

## PKT-R0-2 (#25) — VERDICT: STALE AS STATED; enforcement exists, proven now
Executed evidence (this session, fresh fixtures in scratchpad):
- authority_envelope_tests.sh: **126 passed, 0 failed**.
- Functional probes (BUILD_OS_NOW=2026-08-12, synthetic store):
  lapsed lease → `envelope: LAPSED … contributes no grant` (NOT
  WITHIN-LICENCE); not-yet lease → NOT-YET-LIVE, no grant; malformed
  `starts: 2026-13-45` → REFUSED, named; malformed clock 2026-99-99 →
  REFUSED, no fallback-to-today; absent registry → REFUSED ("an absent
  census is not a permissive one"); unknown control → UNCOMPOSABLE.
Remaining deltas (moved, not dropped):
- The validator is ADVISORY (exit 0 on REFUSED by declared policy). Fail-
  closed enforcement belongs to the CONSUMER: PKT-R0-4's goal contract
  treats REFUSED/LAPSED/NOT-YET/UNCOMPOSABLE as no-grant and halts.
- Wrong-project leases = namespace scoping → PKT-R0-1.
- Replay of a revoked (deleted) record: mitigated by the store being
  git-tracked per repo; namespace check adds the project dimension.
Task #25 closes as stale-with-deltas; deltas tracked in packets 1 and 4.

## PKT-R0-1 — cross-repo isolation: EXECUTED, 14/14 (commit 090ed5c)
Deterministic namespace stamps (remote-URL/path sha256-16); planted sentinel
in repo A never reached repo B's session output, tree, or temp-HOME user
scope; carried-in foreign store QUARANTINED default-closed, evidence left in
place; un-stamped store ADOPTED with receipt, same id re-derived; re-scaffold
deterministic. Orchestrator repo itself adopted (79964536d91d3a1e).

## PKT-R0-3 — deterministic lifecycle: EXECUTED, 22/22 (commits b0c3031, bab92e4)
init idempotent (manifest hashes converge), preflight refuses non-git,
interruption recovery (half-deleted engine restored), destructive verbs
dry-run by default, uninstall keeps user data, purge removes all Gravito
state and never product files. Defect caught by the suite and fixed: the
installer did not ship goal-check.sh to targets (targets could not gate).
Test-harness fix: hooks consume a stdin payload; tests close stdin as the
runtime does (a bare cat hung an open pipe).

## PKT-R0-4 — gravito.goal: EXECUTED (commit ee30ecd)
Validator: missing field / non-numeric budget / unreal date → INVALID
(exit 1); unreadable clock refused, no fallback. Gate fail-closed: EXPIRED →
HALT exit 2; over-budget ledger → HALT exit 3; each names the owner's next
action. Session-start announces a binding GOAL HALT (lifecycle test 4).
Hard tool-level enforcement is R1 scope and is NOT claimed.

## PKT-R0-5 — status surface: EXECUTED (in lifecycle tests §5)
namespace verdict, goal + live window/budget line, state, workers,
manifests, receipts, exact stop/rollback commands; unmetered values
declared "NOT METERED in R0", never invented.

## PKT-R0-6 — docs/DATA-BOUNDARIES.md (commit bab92e4)
Provider calls are the only egress; telemetry OFF (no sender exists); run
streams contain worker transcripts (secrets caveat named); removal maps to
tested verbs; experimental/intelligence features OFF by default.

## R0 EXIT — the five-step golden path on a DISPOSABLE second repo: PASSED
init (receipt install-manifest-20260812T181607Z) → goal (validated,
installed) → run (gate OPEN; ONE real worker session appended the exact
line; metered 223,992 tokens / $0.3349 / 1 min into spend-ledger.jsonl) →
review (acceptance_cmd PASS) → stop (safe, durable) + rollback (engine
matches previous manifest). THEN the loop closed with REAL data: budget
lowered under metered spend → goal gate HALT → run REFUSED to dispatch;
status showed OVER-BUDGET from the real ledger. Fixture destroyed after.

## Boundaries and honest residuals
#40: no packet required the Mac-local Core worktree — all six scope items'
true home is this repo; nothing was built in the wrong place. Residuals:
GOAL HALT is a binding announcement, not tool-level enforcement (R1);
tokens/interventions beyond gravito-run sessions are unmetered (R1 logger);
observed in the golden run: the worker created .gitignore/.serena in the
target (accelerator onboarding) — benign, noted for R1 doc pass. R1/R2
remain unauthorized.
