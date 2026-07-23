# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** none active (last closed: P-003-S1 — see build-os/receipts/P-003-S1.md)

---

## Staged candidate — P-003-S2 (NOT active)

- **Status:** candidate — awaiting orchestrator confirmation and explicit go
- **Packet id:** P-003-S2
- **Title:** Phase 1 Repository Auditor — Slice 2: first detector slice (deterministic detectors against the proof surface)

### Suggested scope

- First deterministic detectors — candidates LG-001, LG-002, LG-004 (pure
  repo-signal checks) — plus broken-fixture(s) for them, wired through the
  `ScannerFn` seam into the §9 harness.

### Branch base

- origin/claude/launchgraph-product-scope-43pgdx @ 263ac7c (P-003-S1 tip);
  verify via `git merge-base` at go.

### Plan

- ≤2 commits, to be declared at go.

### Notes (carry forward)

- **DETECTOR-SLICE OBLIGATION:** every finding on LG-003/010/012/014/015 must
  carry `externalVerification` (or unverified classification) — that enforces
  the §7 Phase-1 ceiling; AT-16 is the backstop. Any detector slice touching
  those checks must honor this.
- Fixtures remain inert data: never a workspace, excluded from
  install/build/test tooling (SEC-1; sec1 test suite guards it).
- No merge, no PR, no provider access without explicit go.

---
_Cleared by the archivist on close of P-003-S1 (2026-07-23). The staged
candidate above activates only on orchestrator confirmation and explicit user
go._
