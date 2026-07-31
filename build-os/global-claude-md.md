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

### Depth budget — how many stages run in SERIES

<!-- BUILD-OS:DEPTH:START — canonical; keep byte-identical in CLAUDE.md, build-os/global-claude-md.md and .claude/agents/build-orchestrator.md -->
A **round** counts agent passes. **Depth** counts how many of them run in
**series**. Width is cheap and depth is not: twenty independent packets fanned
out cost one packet's wall-clock, but a single packet that walks
builder → qa → reviewer → fix → re-review spends five serial stages — about an
hour — and spends that hour identically whether the machine is otherwise idle or
saturated. Budget depth explicitly, the way the lane table budgets rounds.

| Lane | Depth budget (serial agent stages) |
|---|---|
| `read-only` | **1 serial stage** — the answer itself |
| `diagnosis` | **1 serial stage** — the report; propose a packet, do not build one |
| `tiny` | **1 serial stage** — the builder-lite pass, carrying its ONE targeted check |
| `substantive` | **2 serial stages median** — (1) builder, then (2) qa and reviewer CONCURRENTLY; the archivist's close is bookkeeping after the verdict, not a third gate |
| `architecture` | **1 serial stage** — the routing decision, taken before any build stage |

**The substantive median is 2 because qa and reviewer run concurrently, not in
sequence.** Both are read-only and hold no mutating tool, so neither can disturb
what the other measures; running them one after the other buys nothing and costs
a whole stage. Dispatch them in a single message, as one stage, and reconcile
their two outputs afterwards.

**A third serial stage is the exception, and it is paid for out loud.** A
`fix-then-pass` fix round is stage 3: announce it as
`Depth: 3 — reason: fix-then-pass (<n> enumerated items)` and bound it — the
re-review is targeted at those items only unless the reviewer's named exceptions
fire. **A fourth serial stage is a defect**, not a detail: it means the fix list
arrived in installments, or the packet was mis-cut. Stop, say which, and re-cut
the packet instead of opening stage five.

**Tree-quiet is the precondition for the concurrent stage.** A read-only gate
measuring a tree that a builder is still mutating produces junk — counts that
belong to no commit, a diff that changes underneath the reviewer. Start stage 2
only when **all three** hold:

1. the **builder has handed back** — no builder pass is in flight;
2. **`git status --porcelain`** is empty, or contains only files the packet
   declared it would leave unstaged;
3. **HEAD is stable** (`git rev-parse HEAD` unchanged) and is named to both gates
   as the commit they are measuring.

If any of the three is unmet, the **gates wait** — they never run against a
moving tree, and they never quiet it themselves, because neither of them is
allowed to write. A gate that notices the tree moving mid-run reports a routing
error rather than numbers it cannot stand behind.
<!-- BUILD-OS:DEPTH:END -->

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
