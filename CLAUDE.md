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

1. **Classify and announce the LANE** — one line, before anything else:
   `Lane: tiny — one-line comment fix, 1 check, no gates`. The lane fixes the
   gate-set *and* the round budget (see below). Default to the cheapest lane that
   can do the job.
2. **Read the router** — `build-os/memory/tool_router.md` — and pick the matching
   row.
3. **Declare a Tool Budget** — the exact tools/agents you will use, and the
   authority it runs under.
4. **Announce** it on one line: `Tools: [x] — why`.
5. **Budget breach = stop.** Needing a tool or authority outside the declared
   budget is a hard stop for explicit go, not a silent expansion.
6. **Close in-lane.** A finished `substantive` packet is closed by the archivist
   writing `build-os/receipts/<id>.md` and updating `build-os/memory/`. The
   `read-only`, `diagnosis`, and `tiny` lanes close with the answer or the edit —
   no packet, no receipt, no qa/reviewer/archivist.

### Lanes

| Lane | Required gates | Round budget |
|---|---|---|
| `read-only` | none — answer directly | 1 round |
| `diagnosis` | none — investigate and report; do not implement | 1 round |
| `tiny` | builder-lite + ONE targeted check; no qa, no reviewer, no archivist, no packet, no receipt | **2 rounds max** |
| `substantive` | builder → qa → reviewer → archivist | as needed |
| `architecture` | orchestrator routes first | as needed |

**Escalation costs a stated reason; de-escalation is free.** Moving down a lane
needs no announcement. Moving up needs one before the next action:
`Lane: tiny → substantive — reason: <a defect found | a hidden dependency | a risk discovered>`.
A `tiny` task that has spent 2 rounds and is not done is **itself a defect** —
stop and re-classify out loud; do not quietly keep going.

**Every lane keeps external mutation hard-gated.** "No gates" on `tiny` means no
review chain — never "no go needed to push".

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
fire.

**A fourth serial stage has exactly one legitimate cause, and it is announced by
name.** `mandatory_full_regate` applies when **all** of these hold: (1) the fix
list arrived **complete, in one installment**; (2) the packet was **correctly
scoped**; (3) the fixes alter **logic, derivation, authority, counts, or another
load-bearing behaviour**; (4) the contract's own re-review rules therefore
**forbid targeted confirmation**; and (5) a full concurrent re-gate
(qa ‖ reviewer) is required as a result. Announce it as
`Depth: 4 — reason: mandatory_full_regate`. Under that condition depth 4 is
**not** a defect and is not recorded as one.

Otherwise a **fourth serial stage is a defect**, not a detail: it was caused by
incomplete enumeration, by fix-list installments, by avoidable scope growth, or
by a packet that should have been split before execution. Stop, say which, and
re-cut the packet instead of opening stage five.

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

- **Design / UI** work is **frontend only** — do not let a UI packet reach into
  backend/runtime logic.
- **Marketing / media** work happens **only inside marketing/media packets** — it
  does not touch product code.
- **Parallel by default, but legally.** When ≥2 work items are independent, fan
  out rather than sequence them. A legal fan-out needs all three: a **disjoint
  file-ownership manifest** (every agent's writable set, non-overlapping), a
  **merge plan** (who merges, and the single verification that runs after), and
  **the merger owning the hot files** (test suites, `build-os/memory/*`,
  version/changelog). Genuinely overlapping work goes to isolated worktrees plus
  a merge pass.
- **No external mutation without explicit go** — never push, merge, deploy,
  publish, or touch secrets without an explicit go from the user.

### Working contract (`substantive` lane)

- **Verify the branch base** (`git merge-base`) before building; flag a wrong
  base before doing anything else.
- **Commit budget: ≤2 build commits, plus at most 1 fix commit.** The former
  `≤2 commits per packet` rule is **withdrawn as unsatisfiable** — any packet
  receiving `fix-then-pass` must produce a third commit, because the first two
  are the tree the gates measured and amending them is forbidden. The rule and
  the fix-round mechanic could not both be satisfied.
  - A **build commit** carries the packet's planned implementation, tests,
    fixtures, or primary documentation.
  - A **fix commit** is produced *only after* the concurrent qa/reviewer stage
    and carries bounded corrections to defects that stage found. It **may not**
    introduce a new subsystem, expand the packet's original objective, add
    unrelated governance, rewrite the measured build commits, or conceal that
    the packet required correction.
  - A packet with **no fix round stays capped at two commits.**
  - More than one fix commit is a **re-cut**, unless an executed reason proves
    the fixes cannot safely be combined.
  - **Do not record the permitted fix commit as a doctrine breach.** Logging it
    as an exception is ritual, not enforcement.
- **Commit-1 green in isolation** — the first commit builds and passes its tests
  on its own.
- **Full proof + safety grep** — qa reports exact test counts, the
  Commit-1-isolation result, and a safety grep before a packet closes.
- **Never merge without go** — and never push/deploy/touch secrets without go.
