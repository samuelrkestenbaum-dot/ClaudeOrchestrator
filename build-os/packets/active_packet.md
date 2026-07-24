# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** none active (last closed: **P-003-S3** — see build-os/receipts/P-003-S3.md).

---

## Staged candidate — P-003-S4 (NOT yet active)

- **Status:** candidate — awaiting orchestrator confirmation and explicit go.
- **Packet id (proposed):** P-003-S4
- **Title (proposed):** Phase 1 Repository Auditor — Slice 4: next detector slice.

### Suggested scope (orchestrator to confirm)

- **Model-layer decision required first (flag for the orchestrator):** the
  remaining detectors split by layer. LG-005/006/009/011/013 are **Layer D+M**
  and LG-007 is **Layer M** — those need the model layer, which does not yet
  exist. The remaining **pure-Deterministic, externally-bound** checks are
  **LG-010** (unauthenticated email domain — Warning, external) and **LG-014**
  (Sentry unverified in production — Warning, external).
- **Recommended path (keeps the deterministic-only discipline):** implement
  **LG-010 and/or LG-014** next. Both are pure-D and external, so they continue
  exercising the externalVerification obligation (proven for LG-003/LG-015,
  still pending for LG-010/012/014) without opening the model layer. Alternative
  path: stand up the model layer for LG-005/006/007/009/011/013 — a larger,
  distinct decision the orchestrator should scope explicitly rather than fold
  into a detector slice.

### Branch base (proposed)

- `origin/claude/launchgraph-product-scope-43pgdx` @ `47fbb8d` (P-003-S3 tip) —
  re-verify via `git merge-base` at go.

### Plan (≤2 commits at go)

- Detector(s) + detectorKit reuse (registry stays the single source of check
  metadata) as Commit 1 (green in isolation); broken fixture(s) + scanner
  registration + integration/ceiling assertions as Commit 2. Exact shape set at
  go.

### Carry-forward notes (binding on this slice)

- **externalVerification obligation** — LG-010 and LG-014 are external; any
  finding must carry `externalVerification` (or an unverified classification)
  and must NEVER represent repository evidence as provider-side proof.
- **TEST-DATA POLICY** — every key-shaped fake (fixtures/tests/receipts/memory)
  keeps a short suffix (<20 contiguous alphanumerics); never allowlist a secret.
- **CEILING WATCH-ITEM** — preserve `hasAppSignal ⊇ scanner.supported`; do not
  broaden `scanner.supported` or narrow LG-015's gate without keeping the
  superset, or an unqualified-`ready` hole can open. Add the AT-16 regression
  assertion when the real `golden/` fixture lands.

---
_Cleared and staged by the archivist on close of P-003-S3 (2026-07-23). No new
build begins until the orchestrator confirms and the user gives explicit go.
Merge and PR remain hard stops in both repos._
