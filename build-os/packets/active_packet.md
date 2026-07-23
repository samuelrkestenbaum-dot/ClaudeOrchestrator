# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** none active (last closed: P-003-S2 — see build-os/receipts/P-003-S2.md)

---

## Staged candidate (not active)

- **Status:** candidate — awaiting orchestrator confirmation and explicit go.
- **Packet id:** P-003-S3
- **Title:** Phase 1 Repository Auditor — Slice 3: next deterministic detector slice

### Suggested scope

- Next deterministic detectors wired through the composed `ScannerFn` seam.
  Candidates:
  - **LG-003** — missing production webhook. **MUST carry `externalVerification`**
    (or an unverified classification) on every finding — this is the first slice
    where the externalVerification obligation binds.
  - **LG-008** — preview using production database.
  - **LG-015** — missing / unverified production domain (external).
- Plus `broken-lg-00{3,8}` / `broken-lg-015` fixtures wired through the ScannerFn
  seam (inert data: `private: true`, no scripts, excluded from tooling).

### Out of scope (expected)

- The remaining detectors; the `scan`/`eval` CLI; the model layer; remediation
  packages; `hostile/` and real `golden/` fixtures (AT-16 still deferred).
  Everything in spec §13. Merge or PR. Provider access of any kind.

### Branch base

- origin/claude/launchgraph-product-scope-43pgdx @ `ea9d250` (P-003-S2 tip) —
  to be re-verified via `git merge-base` at go.

### Plan (≤2 commits)

- To be declared at go.

### Notes (carry forward — binding)

- **externalVerification OBLIGATION:** every LG-003/010/012/014/015 finding must
  carry `externalVerification` (or unverified) — enforces the §7 Phase-1 ceiling;
  AT-16 is the backstop. This slice is where it first binds (LG-003, LG-015).
- **TEST-DATA POLICY:** fake provider-key literals (esp. LG-003 `whsec_` and any
  Supabase/Resend keys) must keep SHORT suffixes (<20 contiguous alphanumerics)
  so GitHub secret scanning does not block pushes. Never resolve push-protection
  by allowlisting a secret.
- Registry remains the single source of check metadata; detectors plug into the
  §9 gate via `ScannerFn` injection without rework.

---
_Cleared by the archivist on close of P-003-S2 (2026-07-23). The staged candidate
above is a suggestion for the orchestrator; it is NOT activated. Push of any
future commits, and every merge/PR, remain hard stops awaiting explicit go._
