# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

## Deferred (follow-up packets)

- **Serena go-live** → next session must **restart + approve the project MCP**
  (`.mcp.json`) before Serena tools appear. Fresh containers also need
  `serena` deps fetched by uvx on first launch (network).
- **Claude HUD disambiguation** → no canonical tool; pick a read-only local-JSONL
  TUI (never a proxy interceptor) and get explicit go before install.
- **Context Mode pilot** → verify the exact upstream repo, then pilot in a
  non-secret repo only; benchmark accuracy/latency/token-cost before wider use.
- **GH Action opt-in** → `claude-code-action` and `claude-code-security-review`
  are repo-scoped templates; install into a target repo only with explicit go +
  the required secret (`ANTHROPIC_API_KEY` / `CLAUDE_API_KEY`).
- **Trail of Bits** → enable only the curated security subset per-task via
  `/plugin marketplace add trailofbits/skills` (interactive).
- Carried from P-001: authorize Stripe + Cloudflare, enable Google/Microsoft
  connectors; session-MCP router rows for GitHub + Claude Code Remote.

## Known risks / debt

- **Ephemerality:** CLI installs (Serena via `uv tool`, repomix/ccusage via npx)
  live only in the current container. Durable state = the committed `.mcp.json`,
  `templates/repomix.config.json`, and the routing docs — not the installed
  binaries. Re-verify tool availability at session start.
- **Version pins are point-in-time (2026-07):** `serena-agent==1.6.1`,
  `repomix@1.17.0`, `ccusage@20.0.18`. Re-pin on upgrade.
- Snapshot leakage: Repomix output can embed code — the hardened config excludes
  secrets/env/deps/build, but **sharing a snapshot externally is a STOP**.

## Open boundaries (awaiting explicit go)

- **No secrets touched, no OAuth authorized, no accounts connected.** Stripe /
  Cloudflare still unauthenticated; GH Action API keys not added.
- Serena MCP inert until user restart + approval.
- Production boundaries default-OFF: secrets, OAuth, DDL, remote-DB writes,
  payments, flags, canaries, telemetry, deploys, merges, external sends — each a
  separate explicit approval.
- Feature-branch push only (`claude/orchestrator-tools-list-e0mdaz`); no PR/merge.

---
_Append-only working notes._
