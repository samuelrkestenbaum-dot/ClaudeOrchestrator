# Tool Router

The routing matrix. The **build-orchestrator** reads this on every invocation,
matches the task to a row, and declares its Tool Budget from it. If no row
matches, it routes from embedded defaults and says so.

> Columns: **Task type** · **Authority** · **Route (agents)** · **Tools** ·
> **Gate / stop**

| Task type | Authority | Route (agents) | Tools | Gate / stop |
|---|---|---|---|---|
| Build / feature / bugfix | build | builder → qa → reviewer → archivist | Read, Grep, Glob, Edit, Write, Bash | ≤2 commits; Commit-1 green in isolation; no push/merge |
| Architecture / "what's next" / planning | build | build-orchestrator only (no edits) | Read, Grep, Glob, Bash | route to a packet, don't implement |
| Design / UI | design-ui (frontend only) | builder (frontend scope) → qa (UI smoke) → reviewer → archivist | Read, Grep, Glob, Edit, Write, Bash | frontend files only; no backend/runtime reach-in |
| Marketing / media | marketing-media | builder (marketing/media packet scope) → reviewer → archivist | Read, Grep, Glob, Edit, Write, Bash | only inside marketing/media packets; no product code |
| Agent swarm / parallel work | agent-swarm | build-orchestrator fan-out → per-task builders → reviewer (merge) → archivist | Read, Grep, Glob, Edit, Write, Bash | parallelizable work only; explicit **merge plan** required |
| QA / proof / regression | build | qa | Read, Grep, Glob, Bash | report exact counts; RED blocks close |
| Review / second-eyes | build | reviewer | Read, Grep, Glob, Bash | no edits; verdict only |
| Close / receipt / memory | build | archivist | Read, Write, Bash | touches `build-os/` only |
| Infra / deploy / release | infra-deploy | build-orchestrator (gate) | Read, Grep, Glob, Bash | **STOP** — deploy/merge/secret need explicit go |
| Secrets / credentials | infra-deploy | build-orchestrator (gate) | Read, Bash | **STOP** — never read/write/rotate without explicit go |
| Push / merge to base | infra-deploy | build-orchestrator (gate) | Bash | **STOP** — never push/merge without explicit go |

## Embedded defaults (no matching row)

- Treat the task as **build** authority, route `builder → qa → reviewer →
  archivist`, declare the build toolset, and **stop** before any external
  mutation. Announce `Orchestrator: ON — routing from embedded`.

## How to extend

Add a row per new task type. Keep the **Gate / stop** column honest — every row
that can cross a merge/deploy/secret/push boundary must say **STOP** there.

## External tool routing (use when connected)

Route to these **only when connected** in the current environment; otherwise fall
back to native tools and name the missing capability in the Tool Budget. These
rows are **preferences, not a whitelist** — the orchestrator also uses any *other*
capability already connected in the session (skills, slash commands, subagents,
MCP servers) that fits the task. The SessionStart hook surfaces the live
inventory; default to "it's probably connected — check," not "it's absent."
⚠️ The tool/repo handles below are common names — if you ever *install* something
new, **verify the exact package/repo first**; ecosystem names are easy to mistype.

> **Preference vs. installed.** The table below is a *preference map* and may name
> tools that are **not** installed here. For what is **actually installed and
> live** in this environment, see **Installed plugins (live now)** and
> **Installed connectors (live now)** further down — route to those first, and
> fall back to native tools (saying so) when a preferred tool is absent.

| Task type | Preferred external tool(s) | Used by | Gate |
|---|---|---|---|
| Web research / live docs | Perplexity MCP, native WebSearch/WebFetch | build-orchestrator, builder | read-only — normal budget |
| Site scrape → context | Firecrawl MCP (`firecrawl-mcp-server`) | builder, build-orchestrator | read-only — normal budget |
| Browser / UI QA / screenshots | Playwright MCP (`@playwright/mcp`), Chrome DevTools MCP (`chrome-devtools-mcp`) | qa | read-only drive; no prod actions |
| Second-eyes code review | Codex (`codex` CLI / Codex-for-Claude-Code plugin) | reviewer | read-only — normal budget |
| Repo → LLM context pack | RepoMix (`repomix`) | build-orchestrator, builder | read-only — normal budget |
| Parallel multi-agent work | Claude Squad / parallel sub-agents | build-orchestrator (agent-swarm) | **merge plan required** |
| Send mail / message / SaaS write | Gmail, Slack, Notion, HubSpot, Supabase MCP (write ops) | builder | **STOP** — external mutation, explicit go |
| Design / UI polish | ✅ `design` plugin (installed) — UI/UX, design-system | builder (design-ui) | frontend only |
| Media generation | Higgsfield (installed connector) / Glif / Remotion | builder (marketing-media) | marketing/media packets only |

### Installed plugins (live now — verified in-session, 2026-07)

These claude.ai plugins are **actually installed and enabled** here (confirmed via
`ListPlugins`) — not hypothetical "wire-in later" entries. They bundle
skills/commands the orchestrator should route to **by name**, preferring them over
native tools when the task fits, under the authority + gate shown. Read/analysis
use is normal budget; anything that mutates the outside world (send, file,
publish, write to a remote DB/SaaS) is a **STOP** for explicit go.

| Plugin | Build capability | Authority | Gate / stop |
|---|---|---|---|
| `design` | UI/UX, design-system, visual polish | **design-ui — frontend only** | frontend files only; no backend/runtime reach-in |
| `data` | Spreadsheets, analysis, data shaping/viz | build | read/analyze normal; **STOP** on remote-DB writes |
| `productivity` | Docs, tasks, notes, scheduling workflows | build | read normal; **STOP** on external send/write |
| `brand-voice` | Voice/tone, de-slop AI-sounding copy | marketing-media | marketing/media packets only |
| `marketing` | Copy, SEO, CRO, email, social | marketing-media | marketing/media packets only |
| `sales` | Outreach, CRM workflows, pipeline | build (business) | read normal; **STOP** on send/CRM write |
| `small-business` | Ops: invoicing, CRM, contracts admin | build (business) | read normal; **STOP** on external file/send |
| `legal` | Contracts, review, legal docs | build (business) | read normal; **STOP** on e-sign/file/send |
| `cowork-plugin-management` | Meta: install/enable/manage plugins | meta | plugin-management only; no product code |

### Installed connectors (live now — verified in-session, 2026-07)

MCP connectors **live and usable this session** (confirmed via `ListConnectors`).
Read is normal budget; **write ops are a STOP** for explicit go.

| Connector | Use | Gate / stop |
|---|---|---|
| GitHub *(session MCP)* | Repos, PRs, issues, Actions/CI, code search | push/merge/PR = **STOP** |
| Supabase | Postgres DB, migrations, edge functions | migration/SQL write = **STOP** |
| Netlify | Deploy/manage sites | deploy/update = **STOP** |
| Hugging Face | Models / datasets / spaces | read-only |
| Higgsfield | Image/video/audio/3D/media generation | generate/publish = marketing-media packet + cost |
| Zapier | Bridge to 9,000+ apps | write actions = **STOP** |
| Gmail · Slack · Notion · HubSpot | Mail · chat · docs · CRM | send/write = **STOP** |
| Apollo.io · Clay | Lead gen / enrichment / outreach | send/campaign/write = **STOP** |
| Docusign | E-signature envelopes, agreements | send/create envelope = **STOP** |
| Otter.ai | Meeting transcripts | read-only |
| Claude Code Remote *(session MCP)* | Triggers, PR subscribe, add_repo, sessions | schedule/subscribe = normal; repo/session mutation = judgment |

> **Not live (out of scope until enabled):** Stripe & Cloudflare Developer
> Platform (installed, need auth), Google Calendar / Google Drive / Microsoft 365
> (installed, toggled off in-chat). Don't route to these until they're authorized
> / enabled.

### Build accelerators (verified 2026-07 — see receipt P-002)

**Discovery-first tool selection (do this every build).** (1) *Discover* live
capabilities — `ListConnectors` / `ListPlugins` / `ListSkills`, the SessionStart
inventory, and the tables in this file. (2) Select the **smallest correct
toolset** for the task. (3) In large or unfamiliar repos, prefer **symbol-level**
navigation (Serena) over broad file reads. Never claim an unavailable tool is
installed — if it's not in the live inventory, say so and fall back.

One orchestrator only (Build OS): these accelerators are *instruments*, not
competing agent frameworks. None of them makes build decisions or crosses a
production boundary on its own.

| Accelerator | Route to it when… | State (this env) | Gate / stop |
|---|---|---|---|
| **Serena** — MCP, PyPI `serena-agent==1.6.1` ([oraios/serena](https://github.com/oraios/serena)) | **Primary** for symbol-level exploration / refactoring in large or unfamiliar repos — `find_symbol`, references, semantic edits **before** broad file reads | ✅ CLI installed + `.mcp.json` committed — **needs restart + project-MCP approval** to go live | local LSP only, no API key; edits still flow through builder + ≤2-commit packet discipline |
| **Repomix** — CLI, npm `repomix@1.17.0` ([yamadashy/repomix](https://github.com/yamadashy/repomix)) | **Explicit snapshots / cross-model handoffs only** — never always-on | ✅ runnable: `npx repomix@latest` | run with `templates/repomix.config.json` (Secretlint ON; excludes env/secrets/deps/build). Sharing a snapshot externally = **STOP** for that step |
| **ccusage** — CLI, npm `ccusage@20.0.18` ([ryoppippi/ccusage](https://github.com/ryoppippi/ccusage)) | Usage / cost visibility | ✅ runnable: `npx ccusage@latest` | **visibility-only**; never makes build decisions; reads local JSONL, offline-capable |
| **Claude HUD** — operator visibility | Live session/operator dashboard | ⛔ **blocked — no canonical tool**; 3rd-party TUIs vary, some run API-proxy interceptors (secret-exposure risk) | **do not install without disambiguation + explicit go**; prefer read-only local-JSONL TUIs, never a proxy interceptor; ccusage already covers cost/usage |
| **Trail of Bits skills** — marketplace [`trailofbits/skills`](https://github.com/trailofbits/skills) | Only for **relevant security work**: crypto (`constant-time-analysis`, `zeroize-audit`), supply-chain (`supply-chain-risk-auditor`), CI/agentic (`agentic-actions-auditor`), creds/privacy (`insecure-defaults`), review (`static-analysis`, `variant-analysis`, `differential-review`), isolation (`seatbelt-sandboxer`) | 📋 documented/opt-in — interactive `/plugin` install | activate **per-task only**; produces **advisory evidence, not production changes**; no auth-/MCP-/tenant-isolation-specific plugin — use the general analysis skills |
| **Context Mode** — community MCP (in-session context compression) | Long single sessions — **pilot only** | 📋 documented/opt-in — **not enabled**; exact upstream repo unverified | **non-secret repos only**; never route env / credentials / customer data / logs through it; benchmark accuracy + latency + token/cost before any wider use |
| **claude-code-action** — [`anthropics/claude-code-action@v1.0`](https://github.com/anthropics/claude-code-action) | Repo-scoped GitHub Action: `@claude` PR/issue assistance | 📋 repo-scoped template — **not installed here** | needs `ANTHROPIC_API_KEY` + write perms; **can open PRs, never auto-merges**; add only to a target repo with explicit go; start advisory / minimum perms |
| **claude-code-security-review** — [`anthropics/claude-code-security-review@main`](https://github.com/anthropics/claude-code-security-review) | Repo-scoped GitHub Action: AI security review on PRs | 📋 repo-scoped template — **not installed here** | needs `CLAUDE_API_KEY`; perms `pull-requests: write, contents: read`; **advisory PR comments only** — no code change / merge; explicit go per repo |

> **Repo-scoped ≠ global.** `claude-code-action` and `claude-code-security-review`
> are per-repository GitHub Action templates, **not** global plugins — never add
> them to arbitrary product repos. Minimum-permission, advisory-first install
> recipes live in `INTEGRATIONS.md` §8.

### Skills & slash commands (the `/` menu)

Skills and slash commands are **first-class routing targets**, not just MCP/CLI
tools. The SessionStart inventory lists available skills and commands (user +
project + plugin scope). When one is purpose-built for the task — e.g.
`/deep-research`, `/security-review`, `/code-review`, design or content skills —
the orchestrator **prefers it over native tools** and **names it for the main
session to invoke** (the orchestrator subagent itself holds only Read/Grep/Glob/
Bash, so it routes rather than executing the skill). Gates still apply.

### Auto-detect connected MCPs

The SessionStart hook lists configured MCP servers (read from `.mcp.json`,
`~/.claude.json`, and settings) **plus** available skills, slash commands, and
subagents. In-session, MCP tools appear as `mcp__<server>__<tool>`. The
orchestrator routes a task to a mapped capability **only if it is present**, and
otherwise falls back to native tools and declares the gap. See `INTEGRATIONS.md`
for the full ecosystem map and how to wire more in.

The hook's inventory can lag or truncate — for the authoritative live set, query
the registries directly: **`ListConnectors`** (MCP connectors: `connected` +
`enabledInChat`), **`ListPlugins`** (enabled plugins), and **`ListSkills`**. The
*Installed plugins / connectors (live now)* tables above were reconciled from
those registries; re-verify and update them when the environment changes rather
than trusting a stale list.
