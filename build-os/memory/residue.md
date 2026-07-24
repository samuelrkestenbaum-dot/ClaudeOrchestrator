# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

## Deferred (follow-up packets)

- **Fresh-session activation test passed (P-009):** authenticated prompt, Build OS
  startup signal, hook parsing, and MCP health all pass.
- **Serena** → **ACTIVE**; official commit `68884f1`, host executable + committed
  `.mcp.json`, project approval, and fresh-session MCP connection verified.
- **Claude HUD** → `claude-hud@claude-hud` v0.6.0 installed + enabled at host user scope;
  security + function PASS. ACTIVE pends fresh-session render test (TTY).
- **Context Mode** → `context-mode@context-mode` v1.0.169 installed + enabled at host
  user scope; benchmark PASS. **Routing limited to non-secret pilot** (not wired into any
  project `.mcp.json`); awaiting go to widen. Non-secret repos only; never route
  secrets/customer-data/logs through it.
- **Trail of Bits** → **ACTIVE**; 9 curated plugins verified in a fresh session (advisory/read-only); **not vendored** (CC BY-SA).
- **GH Action opt-in** → `claude-code-action` / `claude-code-security-review` are
  repo-scoped templates; install into a **named** target repo only with explicit go +
  the required secret (`ANTHROPIC_API_KEY` / `CLAUDE_API_KEY`).
- Carried from P-001: authorize Stripe + Cloudflare, enable Google/Microsoft
  connectors; session-MCP router rows for GitHub + Claude Code Remote.

## Known risks / debt

- **Ephemerality → solved via committed bootstrap (P-004):** the remote container is
  ephemeral, so durability = the committed `install-accelerators.sh` (wired into
  SessionStart, idempotent/non-fatal) + `.mcp.json` + `templates/repomix.config.json`.
  Repomix/ccusage are now installed on both the host Mac and the env, but stay **DURABLY
  CONFIGURED** until a fresh Claude Code session test (earlier `ACTIVE (env-scoped)`
  reconciled down — a login shell is not a fresh session). Re-verify at session start
  against the five-state taxonomy.
- **Node compatibility (resolved 2026-07-24):** host default is **Node 22.23.1**.
  Repomix 1.17.0 and ccusage 20.0.18 resolve from the Node 22 bin, and Context Mode
  MCP health connects under Node 22.
- **SessionStart runs background installs (P-004):** the hook launches
  `install-accelerators.sh` detached; first session on a fresh container does network
  installs (fast-skip thereafter). Non-fatal by design — never breaks a session.
- **Version pins are point-in-time (2026-07):** `serena-agent commit 68884f1`,
  `repomix@1.17.0`, `ccusage@20.0.18`, `context-mode@1.0.169`, `claude-hud` v0.6.0.
  Re-pin on upgrade.
- **`enabledPlugins` schema (P-006):** the SessionStart detector parses `enabledPlugins`
  from settings defensively (dict-of-lists, dict-of-bools, or list). If a future Claude
  Code version changes that shape, update the parser + the detector test. Cache entries
  under `~/.claude/plugins/**` are reported as *candidates* only — live verification
  (ListPlugins/ListConnectors/ListSkills or an `mcp__*` call) is required before ACTIVE.
- **Legacy convergence heuristic (P-007):** `install-global.sh` supersedes known legacy
  Build OS/Ruflo routing content (heading/body signatures incl. `stack-capability-map`)
  while preserving unrelated user notes, and syncs the current router to
  `~/build-os/memory/tool_router.md` (overridable via `BUILD_OS_USER_DIR`). Conservative by
  design; extend the signatures + test if a new legacy shape appears on the host.
- **Installation vs configuration vs activation:** `install-global.sh` remains a configuration act; P-010 separately verified a fresh authenticated session.
- **Parallel-work reconciliation (P-007):** the split-brain fix was implemented on the host
  Mac (`Converge global orchestrator routing`) and pushed to this branch; a duplicate
  in-container implementation was discarded in favour of the validated host version, and
  this packet added only the missing Build OS closure (receipt + memory).
- **Config ≠ activation:** installer output intentionally does not claim activation; P-010 supplies the independent activation evidence.
- **Canonical MCP rule (P-008):** one live server per job; prefer a pinned/user-configured
  server over a plugin-bundled copy over an unpinned `@latest`; do not double-launch Serena
  or run Chrome DevTools MCP beside another devtools server for the same task. Encoded in
  `tool_router.md` under *Canonical MCP servers*; extend the named examples as new
  duplicate-prone servers appear.
- Snapshot leakage: Repomix output can embed code — the hardened config excludes
  secrets/env/deps/build, but **sharing a snapshot externally is a STOP**.

## Open boundaries (awaiting explicit go)

- **No secrets touched, no OAuth authorized, no accounts connected.** Stripe /
  Cloudflare still unauthenticated; GH Action API keys not added.
- Build OS, Serena, Repomix, ccusage, Context Mode, and 9 Trail of Bits plugins are **ACTIVE**. Claude HUD is enabled; visual TTY rendering remains unverified.
- Context Mode enabled on host but routing **limited to non-secret pilot** — awaiting go
  to widen.
- Trail of Bits (CC BY-SA) enabled at host user scope, **not vendored** into this repo.
- Production boundaries default-OFF: secrets, OAuth, DDL, remote-DB writes,
  payments, flags, canaries, telemetry, deploys, merges, external sends — each a
  separate explicit approval.
- Feature-branch push only (`claude/orchestrator-tools-list-e0mdaz`); no PR/merge.

---
_Append-only working notes._
