# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** none active (last closed: P-003-S4 — see build-os/receipts/P-003-S4.md).

---

## Staged candidate — a FORK decision (awaiting orchestrator confirmation and explicit go)

- **Status:** candidate — awaiting orchestrator confirmation and explicit go. NOT active. The builder must not start until the orchestrator shapes ONE of the branches below and the user gives an explicit go.

- **Context that forces the fork:** the deterministic-only detector run is **COMPLETE** (8 of 15: LG-001/002/003/004/008/010/014/015; blocker tier + warning tier both proven). There are **NO remaining pure-Deterministic checks**. The remaining 7 — LG-005/006/009/011/013 (Layer D+M), LG-007 (Layer M), LG-012 (Layer D+M, external, the last pending externalVerification check) — **all require the model layer.** So detector work cannot continue without a model-layer decision.

### Branch A — Model-layer foundation packet (larger, distinct scope; orchestrator must shape it explicitly)
- Stands up the Layer-D+M / Layer-M substrate so the remaining 7 checks become buildable.
- **Spec §4.2 bounds (binding):** the model receives ONLY deterministic-surfaced excerpts (no repo/tool access, no network); it uses no tools; every conclusion must cite evidence; its findings are classified at best `inferred` and capped at 0.9 confidence; `--offline` disables the model layer entirely (deterministic-only fallback must still produce a valid report).
- This is bigger than a normal ≤2-commit slice — the orchestrator should decompose it before activation.

### Branch B — Another non-detector slice (smaller, unblocks program breadth without the model layer)
- Candidate: the **scan/eval CLI** — closes AT-24, gives real exit codes (0 / not-ready / 3-not-evaluated), wraps the composed ScannerFn + §9 harness.
- Or: **remediation packages**, or remaining fixtures (`hostile/` for AT-20/AT-22, real `golden/` for AT-16 — which would let the ceiling-invariant regression assertion land).

### Common to whichever branch is chosen
- **Branch base:** origin/claude/launchgraph-product-scope-43pgdx @ `006cadd` (P-003-S4 tip) — re-verify via `git merge-base` at go.
- **Carry-forward obligations (binding):**
  - externalVerification obligation — LG-012 is the LAST pending external check (needs the model layer); it must carry `externalVerification` (or an unverified classification) the moment it lands.
  - TEST-DATA POLICY — <20 contiguous alphanumerics for every key-shaped fake, PLUS no Sentry-DSN shapes, on every surface incl. receipts/memory; never allowlist a secret.
  - CEILING WATCH-ITEM — preserve `hasAppSignal ⊇ scanner.supported`; add the regression assertion when `golden/`/AT-16 lands.
  - Registry stays the single source of check metadata.
- **Hard stops:** ≤2 commits per slice; Commit-1 green in isolation; qa full proof + safety grep before close; NO merge / NO PR without explicit go; no deploys, no secrets, no provider access.

---
_Cleared by the archivist on close of P-003-S4 (2026-07-23). The staged candidate is a fork the orchestrator must resolve — it is not an activation._
