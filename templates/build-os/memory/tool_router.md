# Tool Router

<!-- GRAVITO:TEMPLATE (seeded by the Build OS installer; yours to edit,
     never overwritten once it exists) -->

The routing matrix for **this** repo. The **build-orchestrator** reads this on
every invocation, matches the task to a row, and declares its Tool Budget from
it. If no row matches, it routes from the embedded defaults below and says so.

> **This file starts deliberately empty of tools.** It ships with the routing
> *lanes* every Build OS repo needs and with **no connector rows at all**,
> because which capabilities exist is a fact about your environment, not about
> the installer. Add a row when you connect a tool — see *How to extend*.
> A worked example using fictional tools ships beside the installer at
> `templates/build-os/memory/tool_router.example.md`; it is illustration only and
> is never copied into this file.

> Columns: **Task type** · **Authority** · **Route (agents)** · **Tools** ·
> **Gate / stop**

## Core lanes (shipped — these describe Build OS itself, not your tools)

| Task type | Authority | Route (agents) | Tools | Gate / stop |
|---|---|---|---|---|
| Read-only answer / question | build | build-orchestrator *or direct* (no builder chain) | Read, Grep, Glob | answer only; no edits, no packet, no qa/reviewer/archivist |
| Diagnosis / triage (no edits) | build | qa *or direct* (no builder chain) | Read, Grep, Glob, Bash (read-only) | report findings only; if a fix is needed, propose a packet — don't implement here |
| Tiny reversible local edit | build | builder-lite (single agent, direct) | Read, Grep, Glob, Edit, Write, Bash | in-scope, local, trivially reversible; ≤1 commit; **no qa/reviewer/archivist unless risk**; escalate to the Build row if it grows |
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

## External tool routing (yours to fill in)

**This table is empty on purpose and starts with zero rows.** Nothing is
pre-declared here, because a row naming a capability you do not have is worse
than no row: it sends the orchestrator at something absent and invites a
fallback it never announced.

Add one row per capability **you** have connected, and route to it **only when
it is live in the current surface** — otherwise fall back to native tools and
name the missing capability in the Tool Budget.

| Task type | Preferred external tool(s) | Used by | Gate |
|---|---|---|---|

_No external capabilities recorded yet. Add a row when you connect a tool._

## How to extend

**Add a row when you connect a tool.** One row per task type or per capability:

1. Name the **task type** in the words you would actually use to ask for it.
2. Name the **capability** exactly as it is registered (the MCP server name, the
   plugin id, the CLI binary) — not a friendly nickname. A row that names the
   wrong handle routes to nothing.
3. Say who **uses** it (which agent in the chain).
4. Fill the **Gate / stop** column honestly. Every row that can cross a
   merge / deploy / secret / push boundary must say **STOP** there. If a row's
   gate column is empty, the row is not finished.

Remove a row when the capability goes away. A stale row is a routing bug.

## Embedded defaults (no matching row)

- Route from the requested outcome, using the smallest safe lane:
  - read-only answer / explanation → direct; `Read, Grep, Glob`
  - diagnosis / triage → direct or `qa`; read-only tools; report, do not fix
  - tiny reversible local edit → `builder-lite` + one targeted check
  - substantive feature / bugfix / multi-file build → `builder → qa → reviewer
    → archivist`
  - architecture, ambiguous scope, or gated work → `build-orchestrator`
- Stop before external mutation. Announce
  `Orchestrator: ON — routing from embedded`.

## Proportionate routing (don't over-orchestrate)

Match the route to the task's real weight. The full `builder → qa → reviewer →
archivist` chain is for **build / feature / bugfix** work — it is **not** the
default for everything:

- **Read-only answers / questions** → answer directly (or via build-orchestrator);
  Read/Grep/Glob only; no packet, no builder chain.
- **Diagnosis / triage (no edits)** → investigate and report (qa or direct);
  read-only Bash allowed; if a fix is warranted, *propose a packet* instead of
  implementing inline.
- **Tiny reversible local edit** → a single builder-lite pass; ≤1 commit; skip
  qa/reviewer/archivist **unless** the edit carries real risk.

**Escalate, never silently expand.** The moment a "tiny" edit needs new files,
touches shared/runtime logic, or stops being trivially reversible, stop and
re-route to the full **Build / feature / bugfix** row.

## Tool selection ranking (overlapping tools)

When more than one capability could do the job, pick with this ranking (earlier
wins):

1. **Exact task match** — the tool purpose-built for this exact job.
2. **Project-local instruction** — what this repo's config / router / CLAUDE.md says.
3. **Enabled / live evidence** — verified live via a registry/tool call, not a
   cache entry (see *Availability = live proof* below).
4. **Least privilege** — the read-only / narrowest-scope option that still works.
5. **Lowest orchestration overhead** — fewest agents/steps for the same result.
6. **Freshest verified result** — most recently confirmed working.

Use **one primary capability** per job. Add a second only when it has a
**distinct, necessary** role — not as redundant overlap.

### Availability = live proof, not cache

A plugin / skill / MCP appearing in a **filesystem cache** is a **candidate**,
not proof it is active. Before routing to it or calling it ACTIVE, confirm with a
**live** signal: a registry listing, the enabled-plugins set in settings, or a
real `mcp__<server>__*` tool call. The SessionStart inventory labels cache
entries as *candidates* for exactly this reason.

### One canonical server per job (no duplicate launches)

Run **one** live server per job — never two that do the same thing. When
duplicates exist, prefer a **pinned, user-configured** server over a
plugin-bundled copy, and remove the loser rather than leaving both registered.

### Auto-detect connected capabilities

The SessionStart hook lists the MCP servers, skills, slash commands and
subagents it can see. In-session, MCP tools appear as `mcp__<server>__<tool>`.
The orchestrator routes to a mapped capability **only if it is present**, and
otherwise falls back to native tools and declares the gap.

That inventory can lag or truncate. For the authoritative set, query the
registries directly, and re-verify per surface when the environment changes
rather than trusting a stale list. Never route to a capability not confirmed
live in the current surface.
