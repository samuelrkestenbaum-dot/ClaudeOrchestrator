# ClaudeOrchestrator — a native Build OS for Claude Code

A self-contained **orchestration layer** for Claude Code. A `build-orchestrator`
subagent **routes** work to `builder` / `reviewer` / `qa` / `archivist` under
explicit **Tool Budgets**, **safety gates**, and per-project **memory** — so a
Claude Code session plans, builds test-first, proves, reviews, and records work
instead of drifting. It is the *conductor*, not a bundle of tools; it routes to
Claude Code's native tools and to external tools / MCP servers **when connected**
(see [`INTEGRATIONS.md`](INTEGRATIONS.md)).

> ### ⚖️ Proprietary — this is **not open source**
>
> ClaudeOrchestrator is © 2026 Samuel Kestenbaum, **All Rights Reserved**, and it
> is **access-gated**: access to this repository is *granted*, never assumed.
> Paid access to the repository **is** the entitlement — there is no licence key,
> no activation, and no phone-home.
>
> Being able to see, clone, or fork a repository **is not a licence**; the
> licence says so in as many words. You may use, install, or run this software
> **only** under a separate written agreement signed by the Owner.
>
> Read [`LICENSE`](LICENSE) first, then
> [`docs/ENTITLEMENT.md`](docs/ENTITLEMENT.md) — what access grants, what happens
> at team scale, how to verify an installed copy is genuine, and what is
> deliberately **not** enforced in code.

---

## 🤖 If you are a Claude Code session reading this repo

You were probably told something like *"look at ClaudeOrchestrator and install it
as needed."* Do this:

1. **Install into the project the user is currently working in** (most common):
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

The web `connect`/bootstrap and on-demand paths clone this repo at session start,
so they need the session's environment to (a) hold a credential that can read it
and (b) allow `github.com` egress. **Under the access-gated posture the repo is
private, so a credential is required** — a session scoped to a *different* repo
will not be able to clone it. If access or egress is unavailable, vendor with
`install-project.sh` (zero network) from a clone you already have.
Full matrix of options: [`INSTALL.md`](INSTALL.md).

Whatever this repository's visibility happens to be at any moment, **visibility
is not a licence** — see [`docs/ENTITLEMENT.md`](docs/ENTITLEMENT.md).

Every install stamps the copy it produces (`build-os-identity` +
`BUILD-OS-LICENSE` in each installed root), so a session states its version,
commit and licence on one line at start-up, and a copy that has drifted from its
own stamp says so instead of quietly claiming a version it no longer is:

```bash
bash <root>/.claude/hooks/build-os-identity.sh verify <root>   # 0 = OK, 1 = DRIFT, 2 = unstamped
```

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

## Memory maintenance (`build-os/maintenance/`)

Build OS memory only grows: every closed packet appends. Past the agent's 256 KB
Read limit a memory file stops being readable at all, and a session starts blind
to its own state. The maintenance layer keeps the newest N blocks live and moves
the tail into an append-only archive, with byte-exact conservation verified
before anything is written.

```bash
./build-os/maintenance/rotate-memory.sh            # DRY RUN (the default)
./build-os/maintenance/rotate-memory.sh --apply    # actually write
./build-os/maintenance/run-tests.sh                # the sanctioned test command
```

It is delivered by `install-project.sh` and `init-build-os.sh`. Read
[`build-os/maintenance/PORTING.md`](build-os/maintenance/PORTING.md) for the
managed-vs-yours file split, the uninstall boundary, and the port manifest.

Two things are worth knowing before you rely on it:

- **Rotation is by RECENCY ONLY.** It makes no guarantee about which content
  survives *by meaning*. Anything that must never rotate belongs in
  `build-os/memory/standing_gates.md`, which is absent from the tool's
  `FILE_SPECS` and is therefore never read, written or created by it.
- **The test wrapper detects; it does not prevent.** `run-tests.sh` preloads a
  real-memory tripwire and fingerprints your real memory either side of the run,
  so a run that moved it cannot report success. Its header states the one
  guarantee that buys and enumerates the four paths it does not cover.

## Tests

```bash
bash tests/build_os_tests.sh              # the repo suite
./build-os/maintenance/run-tests.sh       # the maintenance layer's own suite
```

The first one also **runs** `tests/build_os_maintenance_tests.sh` — the
cold-install proof for the maintenance layer, which installs it into a blank
repo and checks the uninstall boundary — and folds its assertions into its own
totals. It is chained rather than merely referenced here, because a second suite
you have to remember is a second suite that gets skipped. Both commands are
offline, deterministic, and confined to temp dirs.

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
.claude/hooks/         session-start-build-os.sh, prompt-router.sh, hook-once.sh,
                       build-os-identity.sh (stamps/verifies an installed copy)
.claude/settings.json  wires the hooks (SessionStart + UserPromptSubmit)
build-os/memory/       tool_router.md, current_state.md, residue.md,
                       standing_gates.md (never rotated), archive/ (rotated tail)
build-os/packets/      active_packet.md
build-os/receipts/     one receipt per closed packet
build-os/maintenance/  memory rotation + the real-memory tripwire + the
                       sanctioned test wrapper (see PORTING.md)
docs/ENTITLEMENT.md    what access grants, what LICENSE leaves ambiguous, and
                       what is NOT enforced technically
install-global.sh      install to ~/.claude (whole machine)
install-project.sh     vendor into a target repo
connect-project.sh     add the web auto-install bootstrap to a target repo
init-build-os.sh       scaffold build-os/ memory only
templates/             everything a customer repo is seeded FROM, never this
                       repo's live state: build-os/ scaffold templates (memory,
                       packets, receipts) plus tool_router.example.md, and
                       session-start-bootstrap.sh — copied into a target repo as
                       .claude/hooks/session-start.sh by connect-project.sh
CLAUDE.md INSTALL.md INTEGRATIONS.md
```
