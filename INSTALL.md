# Installing Build OS everywhere

The files in `.claude/` and `build-os/` make Build OS active **in this repo
only** (project scope). To make the orchestrator run automatically in **every**
Claude Code session of **every** project — without copying files or prompting
each time — install it at **user scope** (`~/.claude/`), which Claude Code loads
for all projects.

## Scopes (how Claude Code resolves config)

| Scope | Location | Applies to |
|---|---|---|
| Project | `<repo>/.claude/` + `<repo>/CLAUDE.md` | that one repo |
| **User (global)** | `~/.claude/` + `~/.claude/CLAUDE.md` | **every project on the machine** |

Agents (`~/.claude/agents/`), commands (`~/.claude/commands/`), hooks
(`~/.claude/settings.json` → `~/.claude/hooks/`), and memory (`~/.claude/CLAUDE.md`)
at user scope are available in every session automatically.

## 1. Local machine (desktop app / CLI) — the main answer

Run once on the machine where you use Claude Code:

```bash
git clone https://github.com/samuelrkestenbaum-dot/ClaudeOrchestrator.git
cd ClaudeOrchestrator
./install-global.sh
```

That copies the 5 agents, 3 commands, and 2 hooks into `~/.claude/`, **merges**
the two hooks into `~/.claude/settings.json` (without touching your other
settings), and appends the Build OS guidance to `~/.claude/CLAUDE.md` (guarded by
markers). It is **idempotent** — safe to re-run to update.

From then on, **every** Claude Code session on that machine starts with
`Orchestrator: ON` and lists `build-orchestrator` + `builder`/`reviewer`/`qa`/
`archivist` under `/agents`. No per-repo setup, no prompting.

### Give a project persistent memory (optional)

The engine is global; per-project *state* (router, current_state, residue,
packets, receipts) lives in each repo's `build-os/`. To scaffold it in a project:

```bash
cd /path/to/your/other-project
/path/to/ClaudeOrchestrator/init-build-os.sh
```

Without it, the orchestrator still routes — it just has no saved memory yet.

## 2. Claude Code on the web / remote environments

Web sessions run in **ephemeral containers** cloned fresh from a repo and then
discarded, so a one-time `~/.claude/` install does **not** persist. The per-repo
mechanism for setup is a **SessionStart hook committed to the target repo**
(see https://code.claude.com/docs/en/claude-code-on-the-web). Pick one of:

### A. Connect a project (recommended) — `connect-project.sh`

Adds a tiny bootstrap to the target repo so **every** web/remote session on it
auto-installs Build OS (pulled from this GitHub repo) at session start. Only two
small files are committed; the engine itself is **not** vendored, so it stays
centrally updatable.

```bash
# one-time, from a clone of ClaudeOrchestrator:
git clone https://github.com/samuelrkestenbaum-dot/ClaudeOrchestrator.git
cd /path/to/your/target-project
/path/to/ClaudeOrchestrator/connect-project.sh
git add .claude/hooks/session-start.sh .claude/settings.json
git commit -m "Connect Build OS bootstrap" && git push
```

The committed `.claude/hooks/session-start.sh` is gated to `CLAUDE_CODE_REMOTE`,
clones/refreshes this repo into `~/.cache/claude-orchestrator`, runs
`install-project.sh --no-session-hook`, then prints `Orchestrator: ON` + memory.
Once it's on the repo's **default branch**, all future sessions use it.

### B. Vendor the engine into the repo — `install-project.sh`

Copies the full engine + `build-os/` scaffold into the target repo. Commit it and
the orchestrator is present at clone time in every session (web **and** local),
with zero bootstrap and no timing dependency — the most deterministic option.

```bash
cd /path/to/your/target-project
/path/to/ClaudeOrchestrator/install-project.sh
git add .claude build-os CLAUDE.md && git commit -m "Add Build OS" && git push
```

### C. Environment setup script (no repo edits)

If you'd rather not commit anything to the target repo, set the environment's
**setup script** (web UI) to install globally each container start:

```bash
git clone https://github.com/samuelrkestenbaum-dot/ClaudeOrchestrator.git /tmp/build-os \
  && /tmp/build-os/install-global.sh
```

### On demand ("if I ask it to install it")

In any session, just ask Claude to **"install the Build OS"** — it will clone
this repo and run `install-project.sh` in the current project. If a web session
already works *inside this repo*, nothing is needed — the project-scope
`.claude/` is present on clone.

## Updating

Re-run `./install-global.sh` after pulling new changes. The settings merge
de-dupes (won't add the hooks twice) and the CLAUDE.md block is marker-guarded.

## Uninstalling

```bash
rm -f  ~/.claude/agents/{build-orchestrator,builder,reviewer,qa,archivist}.md
rm -f  ~/.claude/commands/{next-packet,review-packet,close-packet}.md
rm -f  ~/.claude/hooks/{session-start-build-os,prompt-router}.sh
# then remove the two Build OS hook entries from ~/.claude/settings.json
# and delete the <!-- BUILD-OS:START --> … <!-- BUILD-OS:END --> block in ~/.claude/CLAUDE.md
```

## Notes

- **Don't double-install.** If a repo has project-scope hooks **and** you've
  installed globally, the SessionStart/UserPromptSubmit reminders may print
  twice. Pick one scope per repo (global for "everywhere", project for "this repo
  only").
- **Noise control.** The global hooks print a routing reminder on every prompt in
  every project. If that's too chatty for unrelated repos, install at project
  scope only where you want it instead of globally.
- **Auto-push is intentionally NOT included.** The orchestrator's safety gate
  *stops* before any push/merge/deploy/secret and waits for your explicit go.
  Making Claude auto-commit/push without prompting would defeat that gate; it is
  a separate, deliberate opt-in (a `Stop` hook), and is not recommended.
