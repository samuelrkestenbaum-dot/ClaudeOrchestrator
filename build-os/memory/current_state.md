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
- **Build/test command:** `bash tests/build_os_tests.sh` (48 checks; no network; temp dirs)
  — proportionate-routing + tool-ranking rules, the SessionStart detector (enabledPlugins/
  native vs plugin-cache candidates), installer copy parity, managed-block replacement,
  global convergence (legacy routing supersession preserving unrelated notes, + arbitrary-
  repo user-scope router resolution), plus install-global DURABLY-CONFIGURED reporting, the
  explicit 3-tier router fallback, and the canonical duplicate-MCP rule.

## Where we are

- **Last closed packet:** P-008 — Audit follow-up: install-global reports DURABLY
  CONFIGURED (never ACTIVE until a fresh authenticated session); global guidance uses an
  explicit project → `~/build-os/memory/tool_router.md` → embedded-lanes fallback; added a
  canonical duplicate-MCP rule (one live server per job; prefer pinned/user-configured over
  plugin-bundled/@latest; no redundant Chrome DevTools / Serena). `tests/build_os_tests.sh`
  — 48/48 green.
- **Now:** none active.
- **Next (candidates):** run the **fresh Claude Code session activation test** (flips the
  host-installed accelerators ACTIVE; approve the Serena project MCP on restart); decide
  Context Mode routing enablement (stays non-secret pilot); name a target repo + approve
  a secret for the GH Actions; authorize/enable the deferred connectors; consider a host
  Node 20→22 upgrade for the Node-22+ tools (repomix, context-mode).

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
- **Build accelerators (P-005, host-side completion evidence — all DURABLY CONFIGURED,
  none ACTIVE yet):** Host (user's Mac), fresh-login-shell PASS — Serena 1.6.1
  (`/Users/samsmac/.local/bin/serena`, uv tool); Repomix 1.17.0 + ccusage 20.0.18
  (`/Users/samsmac/.nvm/versions/node/v20.19.0/bin`). Enabled at host user scope via the
  `claude plugin` CLI (`claude plugin list` confirms): `claude-hud` v0.6.0,
  `context-mode` v1.0.169 (routing limited to non-secret pilot), and 9 curated Trail of
  Bits plugins (`constant-time-analysis`, `zeroize-audit`, `supply-chain-risk-auditor`,
  `agentic-actions-auditor`, `insecure-defaults`, `static-analysis`, `variant-analysis`,
  `differential-review`, `seatbelt-sandboxer`). Serena also has committed `.mcp.json`
  (`claude-code`) + in-session `list_memories` PASS. **ACTIVE for every item pends a newly
  restarted Claude Code session test.** ⚠️ Node compat: Repomix + Context Mode declare
  Node 22+ vs host Node 20.19.0 (exec/doctor checks pass — recorded, not hidden). GitHub
  Actions = repo-scoped templates (uninstalled; no secrets). Gates in `tool_router.md` +
  `INTEGRATIONS.md` §8. One orchestrator (Build OS) — no competing framework.
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
