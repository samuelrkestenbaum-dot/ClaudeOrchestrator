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
- **Build/test command:** `bash tests/build_os_tests.sh` (186 checks; no network; temp dirs)
  — proportionate-routing + tool-ranking rules, the SessionStart detector (enabledPlugins/
  native vs plugin-cache candidates), installer copy parity, managed-block replacement,
  global convergence (legacy routing supersession preserving unrelated notes, + arbitrary-
  repo user-scope router resolution), plus install-global DURABLY-CONFIGURED reporting, the
  explicit 3-tier router fallback, and the canonical duplicate-MCP rule, plus P-011
  hook-dedupe (no prompt_id), skill-budget audit, honest Serena reconciliation, and
  remote/org-vs-local capability separation, plus P-013 reversible profiles and P-014
  zero-touch specialist handoff (route classification, focused no-op, ECC/zeroize handoff,
  prompt/cwd preservation, recursion guard, child-failure cleanup, timeout, single-Serena,
  dry-run) and unrelated-capability preservation across profile transitions, plus P-015
  global-install tool shipping and P-016 Ferrari hardening (capability registry,
  inline routing, privacy log, atomic lock, surface inventory, enabled-vs-installed audit).

## Where we are

- **Last closed packet:** P-016 — final Ferrari hardening (7 audit fixes):
  1. **Capability registry** replaces the opaque regex — precedence-ordered, per-family
     task rules. Broad ECC (Everything Claude Code) tasks now route `ecc`: Rust
     ownership/unsafe, Go concurrency/debug, PostgreSQL schema/query, autonomous-agent
     harness/evals, architecture + browser specialists (crypto tokens retained). Ordinary
     lightweight tasks stay `focused` (no relaunch).
  2. **Inline routes** — `classify` returns `21st`/`agent-reach`/`claude-watch`/`ui-ux-pro-max`;
     `detect` emits a REQUIRED current-surface directive with NO capability-profile switch and
     NO child; the prompt hook no longer falsely claims a child handled an inline route.
  3. **Zeroize NL coverage** expanded (keys-remain-in-memory, cleared-from-registers/stack);
     zeroize keeps highest precedence.
  4. **Privacy** — the handoff audit log records only timestamp/route/result/exit/event-id
     (never prompt text or cwd), is created/chmodded `0600`, and tightens a pre-existing 0644.
  5. **Concurrency** — a portable `mkdir`-atomic lock wraps profile activation + child +
     restore; configurable wait; fail-closed BUSY (no mutation, no child) on contention; safe
     stale-lock break; released on EXIT/INT/TERM; focused restoration preserved.
  6. **Surface-aware inventory** — router distinguishes Claude Desktop connector verification
     from the local Claude CLI (21st.dev Desktop-verified, absent from `claude mcp list`;
     Agent Reach native skill; UI UX Pro Max v2.11.0; Claude Watch v0.4.1); no cross-surface
     ACTIVE claim; stale "host-reported" language removed.
  7. **skill-budget-audit** now reports installed inventory separately from the startup-enabled
     set (via `enabledPlugins` + `installed_plugins.json` installPath, de-duped) and only
     checks the enabled set against budget — a disabled mega-bundle no longer reads OVER BUDGET.
  `tests/build_os_tests.sh` — 186/186 green (RED 148/38 → GREEN 186/0).
- **Prior:** P-015 — global install ships the specialist handoff tools (installed hook resolves
  + runs the handoff end-to-end). P-014 — zero-touch specialist orchestration.
- **Now:** none active.
- **Next (candidates):** decide Context Mode routing enablement (stays non-secret pilot);
  name a target repo + approve
  a secret for the GH Actions; authorize/enable the deferred connectors.

## Stable facts (slow-changing)

- **Remote / org — claude.ai (2026-07; NOT the local CLI plugin registry):** 9 org plugins
  (`design`, `data`, `productivity`, `brand-voice`, `marketing`, `sales`, `small-business`,
  `legal`, `cowork-plugin-management`); 13 connectors (Apollo.io, Clay, Docusign, Gmail,
  Higgsfield, HubSpot, Hugging Face, Netlify, Notion, Otter.ai, Slack, Supabase, Zapier) +
  2 session MCPs (GitHub, Claude Code Remote). These are org-level (claude.ai app registry),
  distinct from the locally-installed CLI plugins; verify live per surface before routing
  (no-route-to-unverified). See `tool_router.md` → *Remote / org capabilities*.
- **Installed but NOT live:** Stripe, Cloudflare Developer Platform (need auth);
  Google Calendar, Google Drive, Microsoft 365 (toggled off in-chat).
- **Source of truth for capabilities:** the live registries — `ListConnectors`,
  `ListPlugins`, `ListSkills` — reconciled into `tool_router.md` (Installed
  plugins / connectors) and `INTEGRATIONS.md`. Re-verify when the env changes.
- **Build accelerators (P-012 live evidence):** Build OS routing, Serena, Repomix,
  ccusage, and Context Mode are ACTIVE. Host — Serena is one user-scope MCP pinned to
  official commit `68884f1`; Repomix 1.17.0 + ccusage 20.0.18
  (`/Users/samsmac/.nvm/versions/node/v22.23.1/bin`). Enabled at host user scope via the
  `claude plugin` CLI (`claude plugin list` confirms): `claude-hud` v0.6.0,
  `context-mode` v1.0.169 (routing limited to non-secret pilot), and 8 focused Trail of
  Bits plugins (`constant-time-analysis`, `supply-chain-risk-auditor`,
  `agentic-actions-auditor`, `insecure-defaults`, `static-analysis`, `variant-analysis`,
  `differential-review`, `seatbelt-sandboxer`). `zeroize-audit` and ECC are disabled;
  the former prevents an unpinned duplicate Serena and the latter removes 363 redundant
  skills. A fresh authenticated prompt completed with no skill-budget warning. Claude HUD remains enabled but its visual
  statusline is not independently claimed. Node compatibility resolved: host default is
  Node 22.23.1; Repomix, ccusage, and Context Mode run/connect under Node 22. GitHub
  Actions = repo-scoped templates (uninstalled; no secrets). Gates in `tool_router.md` +
  `INTEGRATIONS.md` §8. One orchestrator (Build OS) — no competing framework.
- **Status-semantics rule:** never call npx/uvx success in an ephemeral container
  "installed" unless persistent host state **and** a fresh-session activation test
  are both verified. Installation · configuration · activation · authentication ·
  repository rollout are five distinct states.
- **Discovery-first rule:** every build discovers live capabilities, then selects
  the smallest correct toolset; Serena is primary for symbol-level work in large/
  unfamiliar repos before broad file reads.
- **Zero-touch specialist handoff (P-014/P-015/P-016):** `build-os/tools/specialist-handoff.sh`
  + the `prompt-router.sh` hook classify via a maintainable **capability registry** (precedence
  zeroize > ecc > inline > focused). focused → no relaunch; ecc/zeroize → an automatic bounded
  child session under a **portable atomic lock** (fail-closed BUSY on contention, safe stale
  break, released on EXIT/INT/TERM), then focused is always restored (recursion-guarded, timed
  out, single-Serena, honest exit status). The audit log is **privacy-safe** (route/result/
  exit/event-id only; `0600`; never prompt/cwd). `install-global.sh` ships both tool scripts
  into `~/build-os/tools` (P-015). **Inline current-surface routes** (`21st`, `agent-reach`,
  `claude-watch`, `ui-ux-pro-max`) emit a REQUIRED directive with NO profile switch and NO
  child. Surface-aware verification: 21st.dev = Claude **Desktop** connector (absent from local
  `claude mcp list`); Agent Reach = native skill; UI UX Pro Max v2.11.0 + Claude Watch v0.4.1 =
  enabled Claude Code skills/plugins. No cross-surface ACTIVE claim. In THIS Claude Code session
  the 21st.dev MCP disconnected (`mcp__21st__*` unavailable) — consistent with the Desktop-only
  surface note.
- **Gates hold:** external mutation (push/merge/deploy/secret/send/SaaS-write),
  plus DDL / remote-DB writes / payments / flags / canaries / telemetry / OAuth,
  are each a separate STOP for explicit go. Repo-scoped GH Actions never go global.

---
_Updated by the archivist on close._
