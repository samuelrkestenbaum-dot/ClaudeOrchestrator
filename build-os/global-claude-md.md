## Build OS (global)

This machine runs a native **Build OS** orchestrator, installed at user scope so
it applies to **every** Claude Code session in **every** project. Use the
**build-orchestrator** for architecture/planning, substantive build packets,
ambiguous scope, and gated work. Read-only answers, diagnosis-only work, and
tiny reversible edits use the router's direct/lightweight lanes. The
orchestrator routes; it never implements.

Per-project state lives in that project's `build-os/` directory
(`build-os/memory/`, `build-os/packets/`, `build-os/receipts/`). If the current
repo has no `build-os/`, the orchestrator still routes — it just has no
persistent memory yet. Scaffold one with `init-build-os.sh` (or `/init-build-os`)
when you want continuity in a project.

### Per-task protocol

1. **Classify and announce the LANE** — one line, before anything else:
   `Lane: tiny — one-line comment fix, 1 check, no gates`. The lane fixes the
   gate-set *and* the round budget (table below); the task's weight and authority
   ride along with it. Default to the cheapest lane that can do the job.
2. **Read the router — in this order:** (a) the project's
   `build-os/memory/tool_router.md` if present; else (b) the user-scope
   `~/build-os/memory/tool_router.md`; else (c) the
   **embedded proportionate lanes** below. Pick the matching row from the first
   source that resolves.
3. **Declare a Tool Budget** — the exact tools/agents you will use.
4. **Announce** it on one line: `Tools: [x] — why`.
5. **Budget breach = stop.** Needing a tool or authority outside the declared
   budget is a hard stop for explicit go, not a silent expansion.
6. **Close substantive build packets** with a receipt via the archivist
   (`build-os/receipts/<id>.md`). Read-only, diagnosis-only, and tiny-edit lanes
   require no packet, reviewer, archivist, or receipt unless risk forces
   escalation.

### Proportionate lanes

The lane names map onto the work: `read-only` is a Read-only answer / explanation,
`diagnosis` is triage, `tiny` is a small reversible local edit, `substantive` is a
real build, and `architecture` is routing.

| Lane | Required gates | Round budget |
|---|---|---|
| `read-only` | none — direct evidence-based answer | 1 round |
| `diagnosis` | none — investigate and report; do not implement unless asked | 1 round |
| `tiny` | one builder-lite pass + ONE targeted check; no qa, no reviewer, no archivist, no packet, no receipt | **2 rounds max** |
| `substantive` | builder → qa → reviewer → archivist | as needed |
| `architecture` | build-orchestrator routes first | as needed |

**Escalation costs a stated reason; de-escalation is free.** Down a lane: no
announcement, no permission. Up a lane: announce it before the next action —
`Lane: tiny → substantive — reason: <a defect found | a hidden dependency | a risk discovered>`.
A `tiny` task that has consumed 2 rounds and is not done is **itself a defect**:
stop and re-classify with a reason; do not quietly keep going.

**Every lane keeps external mutation hard-gated.** "No gates" on `tiny` means no
review chain — it never means "no go needed to push".

### Hard gates

- **Design / UI** work is **frontend only**.
- **Marketing / media** work happens **only inside marketing/media packets**.
- **Parallel by default, but legally.** When ≥2 work items are independent, fan
  out rather than sequence. A legal fan-out needs all three: a **disjoint
  file-ownership manifest** (every agent's writable set, non-overlapping), a
  **merge plan** (who merges, and the single verification that runs after), and
  **the merger owning the hot files** (test suites, memory, version/changelog).
  Overlapping work goes to isolated worktrees plus an explicit merge pass.
- **No external mutation without explicit go** — never push, merge, deploy,
  publish, or touch secrets without an explicit go from the user.

### Working contract

- **Verify the branch base** (`git merge-base`) before building.
- **≤2 commits** per packet; **Commit-1 green in isolation**.
- **Full proof + safety grep** before a packet closes (qa reports exact counts).
- **Never merge/push/deploy without go.**
