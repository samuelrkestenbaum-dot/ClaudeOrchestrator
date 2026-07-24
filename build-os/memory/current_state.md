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
- **Build/test command:** `bash tests/build_os_tests.sh` (121 checks; no network; temp dirs)
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
  global-install tool shipping (installed hook resolves + runs the handoff end-to-end).

## Where we are

- **Last closed packet:** P-015 — global install ships the specialist handoff tools. A
  live-install audit found `install-global.sh` created only `~/build-os/memory` and never
  copied `specialist-handoff.sh` / `capability-profile.sh` into `~/build-os/tools`, so the
  globally installed `prompt-router.sh` (which resolves `~/build-os/tools/specialist-handoff.sh`)
  produced only the routing reminder and no handoff. Fixed: the installer now creates
  `~/build-os/tools` and copies the tool scripts with exec bits preserved; a regression test
  installs into temp `CLAUDE_USER_DIR` + `BUILD_OS_USER_DIR` and proves the installed hook
  resolves + runs the handoff end-to-end (ECC child launched via the copied tools; focused
  restored). `tests/build_os_tests.sh` — 121/121 green.
- **Prior:** P-014 — zero-touch specialist orchestration: the prompt-entry hook auto-detects
  focused vs ECC vs zeroize and, only when a disabled specialist is needed, hands off to a
  fresh non-interactive Claude child (preserving the exact task + cwd), surfaces its exit
  status, and always restores focused — recursion-guarded, timed out, single-Serena, never a
  silent success. Unrelated host capabilities (21st.dev live, Agent Reach skill, Claude Watch +
  UI UX Pro Max host-reported) preserved + routed.
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
- **Zero-touch specialist handoff (P-014/P-015):** `build-os/tools/specialist-handoff.sh` + the
  `prompt-router.sh` hook auto-route focused (no relaunch) vs ECC vs zeroize; a disabled
  specialist triggers an automatic bounded child session, then focused is always restored
  (recursion-guarded, timed out, single-Serena, honest exit status). **`install-global.sh` now
  ships both `specialist-handoff.sh` and `capability-profile.sh` into `~/build-os/tools`** (P-015)
  so the globally installed hook can resolve + run the handoff — regression-tested end-to-end.
  Host capabilities are preserved across profiles + routed: 21st.dev (✅ verified live via
  read-only `get_usage`), Agent Reach (`agent-reach` skill present in-session), Claude Watch +
  UI UX Pro Max (host-reported; not independently verifiable here — no ACTIVE claim).
- **Gates hold:** external mutation (push/merge/deploy/secret/send/SaaS-write),
  plus DDL / remote-DB writes / payments / flags / canaries / telemetry / OAuth,
  are each a separate STOP for explicit go. Repo-scoped GH Actions never go global.

---
_Updated by the archivist on close._
