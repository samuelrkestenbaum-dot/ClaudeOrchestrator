# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** none active (last closed: **P-004** — see build-os/receipts/P-004.md).

---

## Staged candidate (NOT yet active — awaiting orchestrator shaping + explicit go)

- **Status:** CANDIDATE — awaiting orchestrator shaping and explicit go. **Likely larger than ≤2 commits — the orchestrator MUST decompose it into ≤2-commit packets before activation.**
- **Working id:** (to be assigned — Fork **Branch A**)
- **Title:** Phase 1 Repository Auditor — model-layer foundation (Fork Branch A)

### Goal / "done" criteria

- Stand up the model layer that unblocks the remaining 7 checks. Bounded per spec **§4.2**:
  - The model receives ONLY deterministic-surfaced excerpts — **no tools, no network**.
  - **Every conclusion cites evidence.**
  - Model-sourced findings classified at best `inferred`, **confidence capped at 0.9**.
  - `--offline` disables the model layer, and the deterministic-only fallback must STILL produce a valid report **and now mark model-dependent checks `unknown`** — closing the OWED half of AT-27.
- Unblocks **LG-005/006/009/011/013** (Layer D+M), **LG-007** (Layer M), and **LG-012** (Layer D+M, external — the LAST pending externalVerification check).

### Branch base

- origin/claude/launchgraph-product-scope-43pgdx @ **a4ffbf5** (P-004 tip). Re-verify via `git merge-base` at go.

### Carry-forward obligations (still binding)

- **externalVerification obligation** — binds on LG-012 the moment it lands (provider-side proof owned by Phase 3; the scanner never represents repo evidence as provider-side proof).
- **TEST-DATA POLICY** — <20 contiguous alphanumerics for every key-shaped fake, no Sentry-DSN shapes, every surface incl. receipts/memory; never allowlist a secret.
- **CEILING WATCH-ITEM** — `hasAppSignal ⊇ scanner.supported`; add the AT-16 regression when `golden/` lands; any change to `detectStack`/`supported` or LG-015's gate must preserve the superset.
- **CLI entry-point seam** — the model layer plugs into the existing pure, synchronous `run(argv, io): number` + injected `Io {stdout, stderr, now, cwd, writeFile}` seam (P-004); `--offline` already threads through to disable it.
- Registry stays the single source of check metadata.

### Notes for the orchestrator

- This is the FORK's Branch A. Branch B (the scan/eval CLI) closed as P-004. The deterministic-only detector run is COMPLETE (8 of 15 CLI-wired); the remaining 7 checks ALL require this model layer, so no further detector work can proceed until it is shaped and decomposed.
- Gravito's Express/Vite/Fly recipe is the first named post-golden-path expansion + eval target but is NOT part of Branch A — the golden Next.js path is completed first (recorded in build-os/memory/residue.md).

---
_Cleared on close of P-004 (2026-07-23). No packet active. Merge and PR remain hard stops; feature-branch pushes stay under standing authorization after qa green + reviewer pass. Branch A must be shaped and decomposed before activation._
