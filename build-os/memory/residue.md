# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

## Deferred (follow-up packets)

- **Fresh-session activation test (single remaining gate for the host tools)** → all
  host-installed accelerators are **DURABLY CONFIGURED**; a *newly restarted* Claude Code
  session must run for them to count as **ACTIVE**. On that restart: approve the Serena
  project MCP; confirm `claude plugin list` still shows claude-hud / context-mode / the
  9 Trail of Bits plugins enabled; confirm the HUD statusline renders (TTY). Do not mark
  anything ACTIVE until this passes.
- **Serena** → host `/Users/samsmac/.local/bin/serena` 1.6.1 + committed `.mcp.json`
  (`claude-code`) + in-session `list_memories` PASS. ACTIVE pends restart + MCP approval.
- **Claude HUD** → `claude-hud@claude-hud` v0.6.0 installed + enabled at host user scope;
  security + function PASS. ACTIVE pends fresh-session render test (TTY).
- **Context Mode** → `context-mode@context-mode` v1.0.169 installed + enabled at host
  user scope; benchmark PASS. **Routing limited to non-secret pilot** (not wired into any
  project `.mcp.json`); awaiting go to widen. Non-secret repos only; never route
  secrets/customer-data/logs through it.
- **Trail of Bits** → 9 curated plugins installed + enabled at host user scope
  (advisory/read-only); **not vendored** (CC BY-SA). ACTIVE pends fresh-session test.
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
- **Node compatibility (P-005):** Repomix and Context Mode declare **Node 22+**, but the
  host default is **Node 20.19.0**. Executable/`doctor` checks pass today, but this is an
  unsupported-engine mismatch — recorded, not hidden. Fix by upgrading the host to Node 22+
  (or pinning an nvm alias) before relying on them long-term.
- **SessionStart runs background installs (P-004):** the hook launches
  `install-accelerators.sh` detached; first session on a fresh container does network
  installs (fast-skip thereafter). Non-fatal by design — never breaks a session.
- **Version pins are point-in-time (2026-07):** `serena-agent==1.6.1`,
  `repomix@1.17.0`, `ccusage@20.0.18`, `context-mode@1.0.169`, `claude-hud` v0.6.0.
  Re-pin on upgrade.
- Snapshot leakage: Repomix output can embed code — the hardened config excludes
  secrets/env/deps/build, but **sharing a snapshot externally is a STOP**.

## Open boundaries (awaiting explicit go)

- **No secrets touched, no OAuth authorized, no accounts connected.** Stripe /
  Cloudflare still unauthenticated; GH Action API keys not added.
- Host tools installed + enabled (Serena, Repomix, ccusage, claude-hud, context-mode,
  9 Trail of Bits plugins), but **none ACTIVE** until the fresh-session activation test.
- Context Mode enabled on host but routing **limited to non-secret pilot** — awaiting go
  to widen.
- Trail of Bits (CC BY-SA) enabled at host user scope, **not vendored** into this repo.
- Production boundaries default-OFF: secrets, OAuth, DDL, remote-DB writes,
  payments, flags, canaries, telemetry, deploys, merges, external sends — each a
  separate explicit approval.
- Feature-branch push only (`claude/orchestrator-tools-list-e0mdaz`); no PR/merge.

---
_Append-only working notes._
