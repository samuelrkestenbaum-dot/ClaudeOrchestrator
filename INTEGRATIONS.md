# Ecosystem Integrations

How the broader Claude Code ecosystem maps onto the Build OS. The orchestrator
is the **conductor**; these are instruments you bring into the orchestra and add
to the score (`build-os/memory/tool_router.md` → *External tool routing*). Nothing
here is bundled or auto-installed — you install what you want, add a router row,
and the orchestrator routes to it **when connected**, under the usual gates.

> ⚠️ **Verify names before installing.** Many handles below are from notes /
> transcription and may be garbled. Confirm the exact package or GitHub repo
> (and that it's maintained and trustworthy) before installing anything.

## What's actually installed here (verified in-session — 2026-07)

The sections below are the **ecosystem menu** (what you *could* wire in). This
section is the **reality**: what is installed and live in this environment right
now, confirmed via `ListConnectors` / `ListPlugins`. The `tool_router.md` →
*Installed plugins / connectors (live now)* tables carry the authority + gate per
item; this is the index. Keep both honest — re-verify when the environment changes.

- **Connectors (MCP) — live now (13):** Apollo.io · Clay · Docusign · Gmail ·
  Higgsfield · HubSpot · Hugging Face · Netlify · Notion · Otter.ai · Slack ·
  Supabase · Zapier. Plus session/env MCPs: **GitHub**, **Claude Code Remote**.
- **Plugins — enabled now (9):** `design` · `data` · `productivity` ·
  `brand-voice` · `marketing` · `sales` · `small-business` · `legal` ·
  `cowork-plugin-management`.
- **Installed but NOT live (out of scope until enabled):** Stripe & Cloudflare
  Developer Platform (need auth); Google Calendar / Google Drive / Microsoft 365
  (toggled off in-chat).
- **Build accelerators (P-005, host-side completion evidence):** All host-installed
  local tools are **DURABLY CONFIGURED**, **none ACTIVE** until a fresh-session test.
  Host installs (fresh-login-shell PASS): Serena `/Users/samsmac/.local/bin/serena`
  1.6.1; Repomix + ccusage under `/Users/samsmac/.nvm/versions/node/v22.23.1/bin`
  (1.17.0 / 20.0.18). Enabled at host user scope via the `claude plugin` CLI:
  `claude-hud@claude-hud` v0.6.0, `context-mode@context-mode` v1.0.169, and 9 curated
  Trail of Bits plugins. GitHub Actions stay repo-scoped templates (not installed; no
  secrets). Node compatibility is resolved: the host default is Node 22.23.1 and the
  Node-based accelerators run/connect under Node 22. Details/proof in §8.

> The design / marketing / business / brand-voice rows in the sections below were
> written as hypotheticals ("wire this in"). Where a ✅ marks the Wire-in column,
> that capability is now **live via an ACTIVE plugin** — treat it as ACTIVE,
> not aspirational.

## How wiring works

> **Already installed & connected?** Then steps 1–2 are optional. The orchestrator
> **discovers** connected MCP servers, skills, slash commands, and subagents at
> session start (the SessionStart hook prints the inventory) and uses whatever
> fits the task — it is not limited to the rows below. Adding a router row just
> records a preferred default and documents the mapping.

1. **Install** the tool (MCP server in your MCP config, skill via the
   marketplace, plugin, or CLI on PATH) — skip if it's already connected.
2. **Add a router row** in `tool_router.md`: *task type → tool → which agent uses
   it → gate* — optional, sets a preferred default.
3. The orchestrator **detects** it (SessionStart inventory / `mcp__server__*`
   tools / globbing skill+command+agent dirs), **prefers** it when present, and
   **falls back + says so** when not.
4. **Gates always apply:** read-only use (search/scrape/inspect/review) is normal
   budget; anything that **mutates** the outside world (push, deploy, send
   mail/messages, write to a remote DB/SaaS) is a **STOP** for explicit go.

## Priority (suggested)

- **Start here:** Codex reviewer · Playwright MCP · Chrome DevTools MCP ·
  Firecrawl MCP · plain markdown memory (`build-os/`) · `CLAUDE.md`.
- **Add once stable:** RepoMix · a memory/RAG layer (LightRAG / Graphify) ·
  Claude Squad · TDD Guard · curated agent bundles.
- **Later / polish:** design skills, media generation, marketing skills.
- **Cautiously:** giant "everything" bundles, 100s-of-agents repos, random
  agency/automation bundles — adopt piecemeal, not wholesale.

---

## 1. Core workflow

| Tool | What it does | Build OS authority / gate | Wire-in |
|---|---|---|---|
| Superpowers | Structured brainstorm→spec→plan→test→review workflow | build — complements packets | optional; keep one source of truth for the loop |
| GSD ("Get Shit Done") | Keep-moving execution framework | build | optional; the packet loop already drives this |
| Codex / Codex-for-Claude-Code | Independent second-eyes reviewer | build — **reviewer** uses it (read-only) | `codex` on PATH or plugin; router *Second-eyes* row |
| TDD Guard | Blocks skipping tests | build — reinforces **builder** test-first | install; complements Commit-1-green-in-isolation |
| RepoMix | Pack a repo into LLM-readable context | build — orchestrator/builder | `repomix`; read-only |
| Everything / Awesome Claude Code | Big bundles / directories | mixed | cherry-pick; don't adopt wholesale |
| Skill Creator / Anthropic Skills | Build reusable skills | meta | use to author new Build OS skills |

## 2. Memory / context

| Tool | What it does | Build OS authority / gate | Wire-in |
|---|---|---|---|
| `build-os/` markdown memory | current_state / residue / receipts | build — **default, start here** | already in this repo |
| LightRAG | Lightweight retrieval/memory | build — orchestrator context | add after the loop is stable |
| Graphify / Code Graph | Knowledge/codebase graph for retrieval | build — orchestrator context | read-only; add later |
| Claude Mem / Subconscious | Cross-session memory / compression | build | complements `build-os/` memory |
| Obsidian skills | Connect to second-brain notes | build/marketing | read-only unless writing notes (then gate) |

## 3. Browser / web / MCP

| Tool | What it does | Build OS authority / gate | Wire-in |
|---|---|---|---|
| Playwright MCP (`@playwright/mcp`) | Drive a browser: click, test, screenshot | build — **qa** UI smoke (read-only drive) | router *Browser/UI QA* row |
| Chrome DevTools MCP (`chrome-devtools-mcp`) | Inspect/interact with Chrome | build — **qa** | router *Browser/UI QA* row |
| Firecrawl MCP (`firecrawl-mcp-server`) | Scrape sites into context | build — builder/orchestrator (read-only) | router *Site scrape* row |
| Perplexity MCP | Live web research | build (read-only) | router *Web research* row |
| Gmail / Slack / Notion / HubSpot / Supabase MCP | Mail, chat, docs, CRM, DB | **STOP on write ops** — explicit go | read = normal; **write = gate** |
| Hugging Face MCP | Models / datasets / tools | build (read-only) | router row as needed |

## 4. Design / frontend

| Tool | What it does | Build OS authority / gate | Wire-in |
|---|---|---|---|
| UI/UX Pro Max, Taste, Impeccable Design, Emil Kowalski, Web Design Guidelines | Design taste, palettes, motion, audits | **design-ui — frontend only** | ACTIVE — `design` plugin (claude.ai) — builder under design-ui authority |
| Extract Design System / Image-to-Code / Figma-to-Code | Visual → code | design-ui — frontend only | builder under design-ui |
| 21st.dev Magic MCP, Google Stitch | Component/design asset generation | design-ui — frontend only | router design row |

## 5. Media / creative

| Tool | What it does | Build OS authority / gate | Wire-in |
|---|---|---|---|
| Higgsfield, Glif, Remotion | Image / video / motion generation | **marketing-media packets only** | builder under marketing-media |
| Luma / Runway / Pika / Kling / Veo / Sora connectors | Video generation | marketing-media only | gate by packet; watch cost |

## 6. Marketing / business

| Tool | What it does | Build OS authority / gate | Wire-in |
|---|---|---|---|
| Corey Haines marketing skills, Marketing bundle, LinkedIn skill | Copy, SEO, CRO, email, social | **marketing-media packets only** | ACTIVE — `marketing` plugin (claude.ai) — builder under marketing-media |
| Stop Slop / Human Skill | Remove AI-sounding writing | marketing-media | ACTIVE — `brand-voice` plugin (claude.ai) — post-process content |
| Small Business / Sales / Legal plugins | Ops: invoicing, CRM, contracts | **STOP on external actions** | ACTIVE — `small-business`, `sales`, `legal` (claude.ai) — read normal; send/file = gate |

## 7. Agent swarm

| Tool | What it does | Build OS authority / gate | Wire-in |
|---|---|---|---|
| Claude Squad | Run parallel agents/sessions | **agent-swarm — parallelizable work + explicit merge plan only** | orchestrator fan-out; reviewer merges |
| Agency Agents / Rootflow / department rosters | Many specialized agents | agent-swarm — **inspiration, adopt piecemeal** | borrow roles; don't install wholesale |
| Watchdog / PM agent | Overseer to catch bad agent behavior | maps to **reviewer / orchestrator** | already covered by reviewer + gates |

---

## 8. Build accelerators — verified recipes + corrected status (P-002; status corrected P-003)

Verified against live registries + official upstream on 2026-07-24. `ListPlugins`
and `ListSkills` returned **no** claude.ai-marketplace entry for any of these —
upstream (GitHub / npm / PyPI) is the only source. Discover live first, then pick
the smallest correct toolset. **Do not claim an unavailable tool is installed.**

**Status semantics (use these exact labels):** **ACTIVE** = verified in a newly
started normal Claude Code session · **DURABLY CONFIGURED** = committed config can
reconstruct it, not active until restart/approval · **RUNNABLE ON DEMAND** =
verified via npx/uvx in *this ephemeral container*, NOT a persistent install on the
user's Mac or in Claude Desktop · **DOCUMENTED/OPT-IN** = recipe/guidance only, not
installed · **NOT INSTALLED/BLOCKED** = unavailable / ambiguous / withheld.

**Anti-overstatement rule:** never label npx/uvx success in an ephemeral container
"installed" unless *both* persistent host state *and* a fresh-session activation
test are verified. Keep installation · configuration · activation · authentication
· repository rollout as five distinct states.

> **Provisioning status (P-005 — host completion evidence).** All host-installed
> local accelerators = **DURABLY CONFIGURED**; **none ACTIVE** until a newly restarted
> Claude Code session activation test. Host: Serena `/Users/samsmac/.local/bin/serena`
> 1.6.1; Repomix + ccusage under `/Users/samsmac/.nvm/versions/node/v22.23.1/bin`;
> `claude-hud` v0.6.0, `context-mode` v1.0.169, and 9 Trail of Bits plugins installed +
> enabled via the supported `claude plugin` CLI (`claude plugin list` confirms).
> **Node compatibility is resolved:** the host default is **Node 22.23.1**. The committed
> `install-accelerators.sh` covers the remote env; GitHub Actions = repo-scoped
> templates (uninstalled). P-001 claude.ai connectors/plugins stay ACTIVE.

### 8.1 Serena — semantic code navigation/editing (MCP) · DURABLY CONFIGURED
- **Source:** https://github.com/oraios/serena · PyPI `serena-agent` · **v1.6.1**
- **Install (official; upstream warns against marketplace/uvx-guess commands):**
  `uv tool install -p 3.13 serena-agent` → provides `serena`, `serena-agent`, `serena-hooks`.
- **MCP registration:** committed `.mcp.json` (version-pinned, self-bootstrapping,
  reproducible on a fresh container):
  ```json
  { "mcpServers": { "serena": { "command": "uvx",
    "args": ["--from","serena-agent==1.6.1","serena","start-mcp-server",
             "--context","ide-assistant","--project","."] } } }
  ```
- **Status: DURABLY CONFIGURED (proven).** Persistently installed (`uv tool install`,
  `serena` 1.6.1 → `/root/.local/bin/serena`) and reconstructed by the committed
  `.mcp.json` via version-pinned uvx. Context corrected `ide-assistant → claude-code`
  (upstream renamed it; deprecation warning now gone). **Live proof:** a real
  `mcp__serena__list_memories` call succeeded in-session, and the committed command
  boots the server (52 tools, LSP, project recognized). The **only** unrun step is an
  independent fresh-session restart + project-MCP approval — a user action I cannot
  perform non-interactively; until then it is not labelled ACTIVE. Also auto-provisioned
  by `install-accelerators.sh`.
- **Host (user's Mac, P-005):** persistently installed at `/Users/samsmac/.local/bin/serena`
  1.6.1 via `uv tool install`; fresh-login-shell PASS. Still **DURABLY CONFIGURED** —
  ACTIVE pending the fresh Claude Code session restart + MCP approval.
- **Gate:** local language servers, **no API key / OAuth**. Primary for symbol-level
  work in large/unfamiliar repos before broad reads. Edits still go through builder.

### 8.2 Repomix — frozen snapshots / cross-model handoffs (CLI) · DURABLY CONFIGURED
- **Source:** https://github.com/yamadashy/repomix · npm `repomix` · **v1.17.0**
- **Run (no global install):** `npx repomix@latest --config templates/repomix.config.json`
- **Status: DURABLY CONFIGURED.** **Host (Mac, P-005):** installed at
  `/Users/samsmac/.nvm/versions/node/v22.23.1/bin/repomix` 1.17.0, fresh-login-shell
  PASS. Also env-installed (`/opt/node22/bin/repomix`) + auto-provisioned via
  `install-accelerators.sh`. Repomix's Node 22+ engine requirement is satisfied.
  **ACTIVE pending a fresh Claude Code session test** (a fresh login shell is not a
  fresh session; earlier `ACTIVE (env-scoped)` reconciled down).
- **Gate:** **explicit snapshots only, never always-on.** The committed
  `templates/repomix.config.json` keeps Secretlint ON and excludes env/secrets/keys/
  `node_modules`/`dist`/`build`/`.git`. Respects `.gitignore` + `.repomixignore`.
  **Sharing a snapshot with another model/service is an external send → STOP** for
  that step.

### 8.3 ccusage — usage/cost visibility (CLI) · DURABLY CONFIGURED
- **Source:** https://github.com/ryoppippi/ccusage · npm `ccusage` · **v20.0.18**
- **Run:** `npx ccusage@latest` (`daily` | `monthly` | `session` | `blocks`); `--offline` for cached pricing.
- **Status: DURABLY CONFIGURED.** **Host (Mac, P-005):** installed at
  `/Users/samsmac/.nvm/versions/node/v22.23.1/bin/ccusage` 20.0.18, fresh-login-shell
  PASS. Also env-installed + auto-provisioned via `install-accelerators.sh`. **ACTIVE
  pending a fresh Claude Code session test** (earlier `ACTIVE (env-scoped)` reconciled
  down). ccusage runs on the host's Node 22.23.1.
- **Gate:** **visibility-only — never makes build decisions.** Reads local Claude
  Code JSONL; offline-capable; no account/API key.

### 8.4 Claude HUD — operator visibility · DURABLY CONFIGURED (host-enabled)
- **Selected + verified:** `jarrodwatts/claude-hud` (MIT, v0.6.0). **Security PASS** —
  README: "local-only… does not make network requests, scrape credentials, or call
  undocumented Claude APIs"; static egress scan of `dist/` found no outbound calls.
  **Functional test PASS** — piping a sample statusline stdin JSON to `dist/index.js`
  rendered a status line from local data only (cwd/model), no credentials. (The two
  fallbacks `schmoli/claude-dashboard` / `neochoon/agenthud` were not needed since the
  intended tool passed the read-only/local bar.)
- **Status: DURABLY CONFIGURED (host, P-005).** Installed + enabled at user scope on
  the Mac — `claude-hud@claude-hud` v0.6.0 via the supported `claude plugin` CLI
  (marketplace `claude-hud` added); `claude plugin list` confirms enabled. **ACTIVE
  pending a fresh Claude Code session render test (TTY).** Install cmds:
  `claude plugin marketplace add jarrodwatts/claude-hud` → `claude plugin install claude-hud`.
- **Gate:** visibility-only; a statusline **renders only in an interactive TTY**, so it
  cannot be render-verified in this non-interactive env (that's the activation blocker).
  Never set `CLAUDE_HUD_ALLOW_EXTRA_CMD=1` — it enables arbitrary shell exec (off by default).

### 8.5 Trail of Bits security skills · DURABLY CONFIGURED (host-enabled)
- **Source:** https://github.com/trailofbits/skills (official marketplace, 40 plugins)
- **Status: DURABLY CONFIGURED (host, P-005).** 9 curated plugins installed + enabled
  at user scope on the Mac via the supported `claude plugin` CLI (marketplace
  `trailofbits` added): `constant-time-analysis`, `zeroize-audit`,
  `supply-chain-risk-auditor`, `agentic-actions-auditor`, `insecure-defaults`,
  `static-analysis`, `variant-analysis`, `differential-review`, `seatbelt-sandboxer`.
  `claude plugin list` confirms enabled. **ACTIVE pending a fresh-session test.**
  Advisory/read-only; **not vendored** into this repo (CC BY-SA 4.0). Install cmds:
  `claude plugin marketplace add trailofbits/skills` → enable the subset.
- **Curated subset for our categories** (activate per-task, security work only):
  crypto → `constant-time-analysis`, `zeroize-audit`; supply-chain → `supply-chain-risk-auditor`;
  CI/agentic → `agentic-actions-auditor`; creds/privacy → `insecure-defaults`;
  review → `static-analysis`, `variant-analysis`, `differential-review`, `semgrep-rule-creator`;
  isolation → `seatbelt-sandboxer`.
- **Honest gap:** there is **no dedicated auth / MCP / tenant-isolation plugin** —
  those needs are met by the general analysis skills above, not a 1:1 match.
- **Gate:** activate only for relevant security work; **produces advisory evidence,
  not unilateral production changes.** License is **CC BY-SA 4.0** and each item is a
  full plugin with executable code — **not vendored into this repo** (ShareAlike +
  supply-chain caution); install via the interactive marketplace only. (Verified 40
  plugins in the repo; curated subset above.)

### 8.6 Context Mode — in-session context compression (MCP) · DURABLY CONFIGURED (host-enabled; pilot routing)
- **Verified upstream:** `mksglu/context-mode` (npm `context-mode@1.0.169`). MCP server;
  **local-only** ("nothing leaves your machine, no telemetry/account"); redacts
  `authorization/token/password/api_key` before persistence; local SQLite under
  `~/.claude/context-mode/`. `context-mode doctor` → PASS.
- **Benchmark (safe sample = this repo's `build-os/` docs; no secrets):** index 9
  files / 57 sections in **0.188s**; search returned 2 on-topic chunks in **0.120s**;
  result payload 1,225 B vs 37,283 B corpus ≈ **30× context reduction**. Accuracy,
  latency, and token/cost proxy all **PASS**.
- **Status: DURABLY CONFIGURED (host, P-005).** Installed + enabled at user scope on
  the Mac — `context-mode@context-mode` v1.0.169 via the supported `claude plugin` CLI
  (marketplace `context-mode` added); `claude plugin list` confirms enabled. **ACTIVE
  pending a fresh-session test.** Context Mode's Node 22+ engine requirement is satisfied;
  its MCP health check connects under Node 22.
- **Gate (pilot only):** enabled at host user scope, but **routing limited to non-secret
  pilot use** — not wired into any project `.mcp.json`. **Non-secret repos only**;
  **never route env output, credentials, customer data, or sensitive logs through it.**
  Keep broader routing off until you approve enablement.

### 8.7 `anthropics/claude-code-action` — repo-scoped GitHub Action · DOCUMENTED/OPT-IN
- **Source:** https://github.com/anthropics/claude-code-action · ref `@v1.0` (or `@main`)
- **What:** `@claude` PR/issue assistant; **can open PRs; no auto-merge / auto-deploy.**
- **Advisory-first, minimum-permission opt-in** (escalate to write only with explicit go):
  ```yaml
  # .github/workflows/claude.yml — in a TARGET repo, not globally
  permissions:
    contents: read
    pull-requests: read     # bump to write ONLY when you want it to open/update PRs
  # uses: anthropics/claude-code-action@v1.0
  # env: { ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }} }
  ```
- **Gate:** **repo-scoped, not a global plugin.** Requires `ANTHROPIC_API_KEY`
  (a secret → separate explicit approval). Add only to a repo with explicit go;
  human-controlled PRs; never auto-merge.

### 8.8 `anthropics/claude-code-security-review` — repo-scoped GitHub Action · DOCUMENTED/OPT-IN
- **Source:** https://github.com/anthropics/claude-code-security-review · ref `@main`
- **What:** AI security review that **comments advisory findings on PRs only — no
  code changes, no merge.**
- **Minimum-permission opt-in recipe:**
  ```yaml
  # .github/workflows/security-review.yml — in a TARGET repo
  name: Security Review
  on: pull_request
  permissions:
    pull-requests: write   # to post advisory comments
    contents: read
  jobs:
    security:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: anthropics/claude-code-security-review@main
          with:
            claude-api-key: ${{ secrets.CLAUDE_API_KEY }}
  ```
- **Gate:** **repo-scoped, not a global plugin.** Requires `CLAUDE_API_KEY` (secret →
  separate explicit approval). Advisory-only; explicit go per repo; no auto-merge/deploy.

---

## A note on what the Build OS already provides

Several "ecosystem" capabilities are native to this repo, so check before adding
a heavyweight tool: the **packet loop** (plan→build→prove→review→record), the
**reviewer** (overseer / second-eyes), **qa** (test-skipping guard via exact
counts + Commit-1 isolation), **markdown memory** (`build-os/`), and the
**authority gates** (design-ui / marketing-media / agent-swarm / infra-deploy).
Add external tools to *extend* these, not to duplicate them.
