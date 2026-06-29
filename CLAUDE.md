# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Build OS

This repo runs a native **Build OS** orchestrator. Use the **build-orchestrator**
subagent **proactively at session start** and before any build packet
(architecture, next steps, tool routing, or "keep going"). The orchestrator
routes; it never implements. Implementation goes through **builder**, proof
through **qa**, judgment through **reviewer**, and closure through **archivist**.

### Per-task protocol

For every task, in order:

1. **Classify** the task type and its authority.
2. **Read the router** — `build-os/memory/tool_router.md` — and pick the matching
   row.
3. **Declare a Tool Budget** — the exact tools/agents you will use.
4. **Announce** it on one line: `Tools: [x] — why`.
5. **Budget breach = stop.** Needing a tool or authority outside the declared
   budget is a hard stop for explicit go, not a silent expansion.
6. **Close with a receipt.** A finished packet is closed by the archivist writing
   `build-os/receipts/<id>.md` and updating `build-os/memory/`.

### Hard gates

- **Design / UI** work is **frontend only** — do not let a UI packet reach into
  backend/runtime logic.
- **Marketing / media** work happens **only inside marketing/media packets** — it
  does not touch product code.
- **Agent swarm** (parallel subagents) is allowed **only for genuinely
  parallelizable work and only with an explicit merge plan** for recombining the
  results.
- **No external mutation without explicit go** — never push, merge, deploy,
  publish, or touch secrets without an explicit go from the user.

### Working contract

- **Verify the branch base** (`git merge-base`) before building; flag a wrong
  base before doing anything else.
- **≤2 commits** per packet.
- **Commit-1 green in isolation** — the first commit builds and passes its tests
  on its own.
- **Full proof + safety grep** — qa reports exact test counts, the
  Commit-1-isolation result, and a safety grep before a packet closes.
- **Never merge without go** — and never push/deploy/touch secrets without go.
