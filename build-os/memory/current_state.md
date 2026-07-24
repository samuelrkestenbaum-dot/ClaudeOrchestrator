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

- **Last closed packet:** P-003 — Correct P-002 status semantics (no tool was
  permanently activated; ACTIVE count = ZERO).
- **Now:** none active.
- **Next (candidates):** restart to bring Serena MCP live (approve project MCP);
  disambiguate Claude HUD; pilot Context Mode in a non-secret repo w/ benchmark;
  authorize/enable the deferred connectors; session-MCP router rows.

## Stable facts (slow-changing)

- **ACTIVE — claude.ai org-level (2026-07):** 9 plugins (`design`, `data`, `productivity`,
  `brand-voice`, `marketing`, `sales`, `small-business`, `legal`,
  `cowork-plugin-management`); 13 connectors (Apollo.io, Clay, Docusign, Gmail,
  Higgsfield, HubSpot, Hugging Face, Netlify, Notion, Otter.ai, Slack, Supabase,
  Zapier) + 2 session MCPs (GitHub, Claude Code Remote).
- **Installed but NOT live:** Stripe, Cloudflare Developer Platform (need auth);
  Google Calendar, Google Drive, Microsoft 365 (toggled off in-chat).
- **Source of truth for capabilities:** the live registries — `ListConnectors`,
  `ListPlugins`, `ListSkills` — reconciled into `tool_router.md` (Installed
  plugins / connectors) and `INTEGRATIONS.md`. Re-verify when the env changes.
- **Build accelerators (P-002; status corrected P-003) — ZERO permanently ACTIVE:**
  Serena (`serena-agent==1.6.1`) = **DURABLY CONFIGURED** (committed `.mcp.json`
  self-bootstrap; not ACTIVE until a fresh session + project-MCP approval; no
  fresh-session activation test has been run). Repomix (`repomix@1.17.0`) + ccusage
  (`ccusage@20.0.18`) = **RUNNABLE ON DEMAND** (npx only; not persistent/global).
  Trail of Bits skills / Context Mode / `claude-code-action` /
  `claude-code-security-review` = **DOCUMENTED/OPT-IN** (not installed; no secrets).
  Claude HUD = **NOT INSTALLED/BLOCKED**. Status semantics + gates in
  `tool_router.md` → *Build accelerators* and `INTEGRATIONS.md` §8. One orchestrator
  (Build OS) — no competing agent framework added.
- **Status-semantics rule:** never call npx/uvx success in an ephemeral container
  "installed" unless persistent host state **and** a fresh-session activation test
  are both verified. Installation · configuration · activation · authentication ·
  repository rollout are five distinct states.
- **Discovery-first rule:** every build discovers live capabilities, then selects
  the smallest correct toolset; Serena is primary for symbol-level work in large/
  unfamiliar repos before broad file reads.
- **Gates hold:** external mutation (push/merge/deploy/secret/send/SaaS-write),
  plus DDL / remote-DB writes / payments / flags / canaries / telemetry / OAuth,
  are each a separate STOP for explicit go. Repo-scoped GH Actions never go global.

---
_Updated by the archivist on close._
