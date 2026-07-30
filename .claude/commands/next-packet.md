---
description: Route the next build packet via the build-orchestrator (architecture, next steps, tool routing, "keep going").
argument-hint: "[optional focus / packet hint]"
---

Use the **build-orchestrator** subagent now to determine and route the next
build packet.

Have it run its full on-invocation sequence:

0. Declare the **lane** on one line (`read-only` / `diagnosis` / `tiny` /
   `substantive` / `architecture`) with its round budget — e.g.
   `Lane: tiny — one-line comment fix, 1 check, no gates`.
1. Load `build-os/memory/current_state.md`, `build-os/memory/residue.md`, and
   `build-os/packets/active_packet.md`.
2. Run `git status` and verify the branch base with `git merge-base`.
3. Classify the task's authority and apply the `CLAUDE.md` hard gates.
4. Read `build-os/memory/tool_router.md` and pick the matching row.
5. Declare the **Tool Budget**.
6. Announce `Orchestrator: ON — routing from <file|embedded>`.
7. Route **only the declared lane's gates** — the full
   **builder → qa → reviewer → archivist** chain belongs to the `substantive`
   lane; `tiny` gets one builder-lite pass and one check, and no packet. Stop at
   any merge / deploy / secret / push boundary for explicit go, in every lane.
8. If two or more of the next items are independent, **fan them out** instead of
   sequencing — with a disjoint file-ownership manifest, a merge plan naming who
   merges and the single verification that runs after, and the merger owning the
   shared hot files.

Focus / hint (optional): $ARGUMENTS
