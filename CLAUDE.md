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
- **≤2 commits** per packet.
- **Commit-1 green in isolation** — the first commit builds and passes its tests
  on its own.
- **Full proof + safety grep** — qa reports exact test counts, the
  Commit-1-isolation result, and a safety grep before a packet closes.
- **Never merge without go** — and never push/deploy/touch secrets without go.
