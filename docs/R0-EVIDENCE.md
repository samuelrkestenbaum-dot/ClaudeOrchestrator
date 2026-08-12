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
