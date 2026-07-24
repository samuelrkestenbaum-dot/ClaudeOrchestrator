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

- **Last closed packet:** P-001 — Reconcile Build OS config with installed
  plugins + connectors.
- **Now:** none active.
- **Next (candidates):** authorize/enable the deferred connectors and add them to
  the Installed tables; add first-class router rows for the session MCPs (GitHub,
  Claude Code Remote).

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
- **Gates hold:** external mutation (push/merge/deploy/secret/send/SaaS-write) is
  always a STOP for explicit go.

---
_Updated by the archivist on close._
