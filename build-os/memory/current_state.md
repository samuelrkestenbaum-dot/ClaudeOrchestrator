# Current State

> The "where are we" snapshot. The orchestrator reads this first every session.
> The archivist advances it when a packet closes. Keep it short and true.

## Project

- **What this repo is:** Build OS — a native orchestrator for Claude Code (routing
  matrix + packet loop + markdown memory) that turns a repo into a
  plan → build → prove → review → record system.
- **Primary branch / base:** `claude/add-build-os` (current integration base; no
  `main` present in this environment). Active work branch:
  `claude/orchestrator-tools-list-e0mdaz`.
- **Build/test command:** none formal — shell installers + markdown; no test suite yet.

## Where we are

- **Last closed packet:** P-002 — Build accelerators: install/verify + encode
  routing (Serena, Repomix, ccusage, Trail of Bits, Context Mode, GH Actions).
- **Now:** none active.
- **Next (candidates):** restart to bring Serena MCP live (approve project MCP);
  disambiguate Claude HUD; pilot Context Mode in a non-secret repo w/ benchmark;
  authorize/enable the deferred connectors; session-MCP router rows.

## Stable facts (slow-changing)

- **Installed & live (2026-07):** 9 plugins (`design`, `data`, `productivity`,
  `brand-voice`, `marketing`, `sales`, `small-business`, `legal`,
  `cowork-plugin-management`); 13 connectors (Apollo.io, Clay, Docusign, Gmail,
  Higgsfield, HubSpot, Hugging Face, Netlify, Notion, Otter.ai, Slack, Supabase,
  Zapier) + 2 session MCPs (GitHub, Claude Code Remote).
- **Installed but NOT live:** Stripe, Cloudflare Developer Platform (need auth);
  Google Calendar, Google Drive, Microsoft 365 (toggled off in-chat).
- **Source of truth for capabilities:** the live registries — `ListConnectors`,
  `ListPlugins`, `ListSkills` — reconciled into `tool_router.md` (Installed
  plugins / connectors) and `INTEGRATIONS.md`. Re-verify when the env changes.
- **Build accelerators (P-002, verified 2026-07):** Serena (`serena-agent==1.6.1`,
  MCP via committed `.mcp.json`, **needs restart + approval**); Repomix
  (`repomix@1.17.0`, npx) + ccusage (`ccusage@20.0.18`, npx) runnable; Trail of
  Bits skills / Context Mode / `claude-code-action` / `claude-code-security-review`
  documented opt-in; Claude HUD blocked. Full gates in `tool_router.md` → *Build
  accelerators* and `INTEGRATIONS.md` §8. One orchestrator (Build OS) — no
  competing agent framework added.
- **Discovery-first rule:** every build discovers live capabilities, then selects
  the smallest correct toolset; Serena is primary for symbol-level work in large/
  unfamiliar repos before broad file reads.
- **Gates hold:** external mutation (push/merge/deploy/secret/send/SaaS-write),
  plus DDL / remote-DB writes / payments / flags / canaries / telemetry / OAuth,
  are each a separate STOP for explicit go. Repo-scoped GH Actions never go global.

---
_Updated by the archivist on close._
