# Ecosystem Integrations

How the broader Claude Code ecosystem maps onto the Build OS. The orchestrator
is the **conductor**; these are instruments you bring into the orchestra and add
to the score (`build-os/memory/tool_router.md` → *External tool routing*). Nothing
here is bundled or auto-installed — you install what you want, add a router row,
and the orchestrator routes to it **when connected**, under the usual gates.

> ⚠️ **Verify names before installing.** Many handles below are from notes /
> transcription and may be garbled. Confirm the exact package or GitHub repo
> (and that it's maintained and trustworthy) before installing anything.

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
| UI/UX Pro Max, Taste, Impeccable Design, Emil Kowalski, Web Design Guidelines | Design taste, palettes, motion, audits | **design-ui — frontend only** | builder under design-ui authority |
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
| Corey Haines marketing skills, Marketing bundle, LinkedIn skill | Copy, SEO, CRO, email, social | **marketing-media packets only** | builder under marketing-media |
| Stop Slop / Human Skill | Remove AI-sounding writing | marketing-media | post-process content |
| Small Business / Sales / Legal plugins | Ops: invoicing, CRM, contracts | **STOP on external actions** | read = normal; send/file = gate |

## 7. Agent swarm

| Tool | What it does | Build OS authority / gate | Wire-in |
|---|---|---|---|
| Claude Squad | Run parallel agents/sessions | **agent-swarm — parallelizable work + explicit merge plan only** | orchestrator fan-out; reviewer merges |
| Agency Agents / Rootflow / department rosters | Many specialized agents | agent-swarm — **inspiration, adopt piecemeal** | borrow roles; don't install wholesale |
| Watchdog / PM agent | Overseer to catch bad agent behavior | maps to **reviewer / orchestrator** | already covered by reviewer + gates |

---

## A note on what the Build OS already provides

Several "ecosystem" capabilities are native to this repo, so check before adding
a heavyweight tool: the **packet loop** (plan→build→prove→review→record), the
**reviewer** (overseer / second-eyes), **qa** (test-skipping guard via exact
counts + Commit-1 isolation), **markdown memory** (`build-os/`), and the
**authority gates** (design-ui / marketing-media / agent-swarm / infra-deploy).
Add external tools to *extend* these, not to duplicate them.
