# ClaudeOrchestrator — a native Build OS for Claude Code

A self-contained **orchestration layer** for Claude Code. A `build-orchestrator`
subagent **routes** work to `builder` / `reviewer` / `qa` / `archivist` under
explicit **Tool Budgets**, **safety gates**, and per-project **memory** — so a
Claude Code session plans, builds test-first, proves, reviews, and records work
instead of drifting. It is the *conductor*, not a bundle of tools; it routes to
Claude Code's native tools and to external tools / MCP servers **when connected**
(see [`INTEGRATIONS.md`](INTEGRATIONS.md)).

---

## 🤖 If you are a Claude Code session reading this repo

You were probably told something like *"look at ClaudeOrchestrator and install it
as needed."* **In most cases you do not have to do anything** — see *Automatic
bootstrap* directly below. The manual installers remain available as fallbacks.

### Activation (P-023/P-024) — one command, then automatic

> **Platform boundary, measured — not assumed (P-024).** *Attaching* this repo does **not**
> by itself execute anything. Live tests on a genuinely fresh project showed:
> (a) with ClaudeOrchestrator merely present alongside a fresh project, a new session
> installed **nothing**; (b) `claude -p` (non-interactive CLI) does **not** run SessionStart
> hooks at all — neither project-scope nor user-scope, in an untrusted project. SessionStart
> hooks **do** run on the managed surfaces (web / cloud task / interactive), which is how this
> repo's own hook fires. So: run the one activation command below once per project; after that,
> managed sessions execute the hook and the runtime keeps itself current automatically.

**Activate (one command, from the project):**

```bash
bash /path/to/ClaudeOrchestrator/build-os/tools/project-bootstrap.sh
```

That is the whole setup. The same script is what the **SessionStart hook**
(`.claude/hooks/session-start-build-os.sh`) invokes on every managed session thereafter:

```bash
build-os/tools/project-bootstrap.sh --target <effective project dir>
```

which installs/updates the **complete** runtime into that project — agents, commands,
hooks, `build-os/tools/` (`specialist-handoff.sh`, `capability-profile.sh`,
`supervise.sh`, `skill-budget-audit.sh`), `tool_router.md`, `skill_budget.md`,
`global-claude-md.md`, the managed `CLAUDE.md` block, and the `.claude/settings.json`
SessionStart + UserPromptSubmit wiring. It is:

- **idempotent + cached** — skips entirely when the canonical SHA and every managed
  file hash already match (fast startup);
- **transactional** — stages, backs up, promotes atomically, and **rolls back** to the
  prior installation on any failure;
- **lock-guarded** — a `mkdir`-atomic lock makes concurrent SessionStarts fail closed
  as BUSY rather than corrupt an install;
- **non-destructive** — `current_state.md`, `residue.md`, packets, receipts, product
  files, custom `CLAUDE.md` content, and unrelated settings keys are **never**
  overwritten (only seeded when absent);
- **manifest-backed** — writes `build-os/.install-manifest.json` (canonical source SHA,
  runtime version, timestamp, per-file sha256, agents, tools, preserved files) so any
  session can detect drift;
- **honest** — startup prints `Orchestrator: ON` only when the required runtime is
  actually present, otherwise `Orchestrator: DEGRADED` naming the missing agent/tool.
  File presence is discoverability, **not** proof of callability — verify a live
  agent/tool call before routing.

Run it manually any time: `build-os/tools/project-bootstrap.sh --target DIR`
(`--verify` for a health report, `--force` to reinstall, `--dry-run` to preview).

> **Managed vs preserved — know which is which.** `build-os/memory/tool_router.md` is
> **MANAGED**: it is the canonical routing matrix and is refreshed from ClaudeOrchestrator
> on every bootstrap, so project-local edits to that file are replaced. Put project-specific
> routing in `build-os/memory/current_state.md` / `residue.md` (both **preserved**), or in a
> user-scope `~/build-os/memory/tool_router.md` — the router's documented 3-tier fallback is
> *project → user-scope → embedded lanes*. `current_state.md`, `residue.md`, `packets/`,
> `receipts/`, product files, non-managed `CLAUDE.md` content, and unrelated
> `.claude/settings.json` keys are never overwritten.

### Manual installers (fallbacks)

1. **Install into the project the user is currently working in**:
   ```bash
   # from a clone of THIS repo:
   /path/to/ClaudeOrchestrator/install-project.sh /path/to/their/project
   ```
   This vendors the engine (`.claude/agents`, `.claude/commands`, `.claude/hooks`,
   a `CLAUDE.md` section) + a `build-os/` memory scaffold into that project.

2. **Or install for the whole machine** (every project): run
   `/path/to/ClaudeOrchestrator/install-global.sh` (writes `~/.claude/`).

3. **Or set up web auto-install** for a repo: run
   `/path/to/ClaudeOrchestrator/connect-project.sh /path/to/their/project`,
   then commit `.claude/hooks/session-start.sh` + `.claude/settings.json` to that
   repo's **default branch**. Every future web/remote session self-installs.

All installers are **idempotent** and merge (never clobber) existing settings.
After installing, **use the `build-orchestrator` subagent** and follow
[`CLAUDE.md`](CLAUDE.md). **Do not push / merge / deploy / touch secrets without
the user's explicit go** — that is a hard gate of this system.

---

## Quick start (humans)

```bash
git clone https://github.com/samuelrkestenbaum-dot/ClaudeOrchestrator.git
cd ClaudeOrchestrator

./install-global.sh          # this machine, every project  (~/.claude)
# or, inside another repo:
/path/to/ClaudeOrchestrator/install-project.sh    # vendor into that repo
# or, for web auto-install on a repo:
/path/to/ClaudeOrchestrator/connect-project.sh    # commit the result
```

On demand, in any session: just ask Claude to **"install the Build OS."**

This repo is **public**, so the web `connect`/bootstrap and on-demand paths clone
it without credentials — even from a session scoped to a *different* repo —
provided the environment allows `github.com` egress. If egress is blocked, vendor
with `install-project.sh` (zero network). See [`INSTALL.md`](INSTALL.md).
Full matrix of options: [`INSTALL.md`](INSTALL.md).

## The roster

| Agent | Role |
|---|---|
| `build-orchestrator` | **Routes** (never implements): loads memory, verifies branch base, classifies authority, declares a Tool Budget, delegates. |
| `builder` | Implements a confirmed packet **test-first**, ≤2 commits, Commit-1 green in isolation, in-scope only. |
| `qa` | Full suite + regression (**exact counts**), Commit-1-isolation check, safety grep, UI smoke. |
| `reviewer` | Reviews diff + tests + Codex second-eyes + Product Trajectory Check → **pass / fix-then-pass / fail**. No edits. |
| `archivist` | Writes `build-os/receipts/<id>.md` and updates memory. Touches `build-os/` only. |

Commands: `/next-packet` (route), `/review-packet` (qa + reviewer),
`/close-packet` (archivist).

## Safety gates (non-negotiable)

- **No external mutation without explicit go** — never push, merge, deploy,
  publish, or touch secrets unprompted.
- **Verify branch base** (`git merge-base`) before building.
- **≤2 commits per packet**; **Commit-1 green in isolation**.
- **Full proof + safety grep** before a packet closes.
- **Close with a receipt.**

## Extending to the ecosystem

The orchestrator routes to external tools / MCP servers when connected. To wire a
new one: install it, add a row to
[`build-os/memory/tool_router.md`](build-os/memory/tool_router.md) → *External
tool routing* (task type → tool → gate). The full map of the Claude Code
ecosystem (workflow, memory/RAG, browser/MCP, design, media, marketing,
agent-swarm) and how each maps to a Build OS authority/gate is in
[`INTEGRATIONS.md`](INTEGRATIONS.md).

## Layout

```
.claude/agents/        build-orchestrator, builder, reviewer, qa, archivist
.claude/commands/      next-packet, review-packet, close-packet
.claude/hooks/         session-start-build-os.sh, prompt-router.sh
.claude/settings.json  wires the hooks (SessionStart + UserPromptSubmit)
build-os/memory/       tool_router.md, current_state.md, residue.md
build-os/packets/      active_packet.md
build-os/receipts/     one receipt per closed packet
install-global.sh      install to ~/.claude (whole machine)
install-project.sh     vendor into a target repo
connect-project.sh     add the web auto-install bootstrap to a target repo
init-build-os.sh       scaffold build-os/ memory only
templates/             session-start-bootstrap.sh — copied into a target repo as
                       .claude/hooks/session-start.sh by connect-project.sh
CLAUDE.md INSTALL.md INTEGRATIONS.md
```
