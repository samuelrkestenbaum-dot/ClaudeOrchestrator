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

| Task type | Preferred external tool(s) | Used by | Gate |
|---|---|---|---|
| Web research / live docs | Perplexity MCP, native WebSearch/WebFetch | build-orchestrator, builder | read-only — normal budget |
| Site scrape → context | Firecrawl MCP (`firecrawl-mcp-server`) | builder, build-orchestrator | read-only — normal budget |
| Browser / UI QA / screenshots | Playwright MCP (`@playwright/mcp`), Chrome DevTools MCP (`chrome-devtools-mcp`) | qa | read-only drive; no prod actions |
| Second-eyes code review | Codex (`codex` CLI / Codex-for-Claude-Code plugin) | reviewer | read-only — normal budget |
| Repo → LLM context pack | RepoMix (`repomix`) | build-orchestrator, builder | read-only — normal budget |
| Parallel multi-agent work | Claude Squad / parallel sub-agents | build-orchestrator (agent-swarm) | **merge plan required** |
| Send mail / message / SaaS write | Gmail, Slack, Notion, HubSpot, Supabase MCP (write ops) | builder | **STOP** — external mutation, explicit go |
| Design / UI polish | design skills (UI/UX, Taste, design-system) | builder (design-ui) | frontend only |
| Media generation | Higgsfield / Glif / Remotion | builder (marketing-media) | marketing/media packets only |

### Auto-detect connected MCPs

The SessionStart hook lists configured MCP servers (read from `.mcp.json`,
`~/.claude.json`, and settings). In-session, MCP tools appear as
`mcp__<server>__<tool>`. The orchestrator routes a task to a mapped MCP **only if
that server is present**, and otherwise falls back to native tools and declares
the gap. See `INTEGRATIONS.md` for the full ecosystem map and how to wire more in.
