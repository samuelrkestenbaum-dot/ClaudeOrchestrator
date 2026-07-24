# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

## Deferred (follow-up packets)

- **Serena go-live (only remaining step)** → persistently installed + committed
  `.mcp.json` (`claude-code` context) + a real `list_memories` call already succeeded
  in-session, so it is **DURABLY CONFIGURED (proven)**. To reach ACTIVE, a *newly
  started* Claude Code session must launch + **approve the project MCP** — a user/
  interactive action the remote non-interactive session cannot self-perform.
- **Claude HUD (RESOLVED upstream; interactive install remains)** → `jarrodwatts/claude-hud`
  v0.6.0 selected + security PASS + functional PASS. Enable via interactive `/plugin`;
  statusline renders only in a TTY (can't render-verify here).
- **Context Mode (RESOLVED upstream + benchmarked; enablement decision remains)** →
  `mksglu/context-mode@1.0.169`, local-only, benchmark PASS (≈30× ctx cut, <0.2s).
  Installed for pilot but **routing deliberately disabled**; awaiting your go to wire
  it. Non-secret repos only; never route secrets/customer-data/logs through it.
- **GH Action opt-in** → `claude-code-action` and `claude-code-security-review`
  are repo-scoped templates; install into a target repo only with explicit go +
  the required secret (`ANTHROPIC_API_KEY` / `CLAUDE_API_KEY`).
- **Trail of Bits** → enable only the curated security subset per-task via
  `/plugin marketplace add trailofbits/skills` (interactive).
- Carried from P-001: authorize Stripe + Cloudflare, enable Google/Microsoft
  connectors; session-MCP router rows for GitHub + Claude Code Remote.

## Known risks / debt

- **Ephemerality → solved via committed bootstrap (P-004):** the container is
  ephemeral, so durability = the committed `install-accelerators.sh` (wired into
  SessionStart, idempotent/non-fatal) + `.mcp.json` + `templates/repomix.config.json`,
  **not** any host binary. In THIS env, Repomix/ccusage are ACTIVE (env-scoped);
  the user's own Mac/host still needs the one-line `npm i -g` commands. Re-verify at
  session start against the five-state taxonomy.
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
- Serena MCP proven in-session; independent fresh-session restart + approval is the
  user's step to reach ACTIVE.
- Context Mode installed but routing **disabled** (pilot) — awaiting go to wire it.
- Trail of Bits (CC BY-SA) not vendored; Claude HUD not enabled — both interactive.
- Production boundaries default-OFF: secrets, OAuth, DDL, remote-DB writes,
  payments, flags, canaries, telemetry, deploys, merges, external sends — each a
  separate explicit approval.
- Feature-branch push only (`claude/orchestrator-tools-list-e0mdaz`); no PR/merge.

---
_Append-only working notes._
