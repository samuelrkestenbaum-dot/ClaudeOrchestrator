---
description: Prove and review the active packet — qa and reviewer CONCURRENTLY (one stage), then reconcile into pass / fix-then-pass / fail.
argument-hint: "[optional packet id]"
---

Prove and review the active build packet before it is closed.

**Substantive lane only.** `tiny`-lane work is proved by its ONE targeted check —
it does not get a qa battery or a review round. Running this on a tiny-lane
change is an escalation and owes a stated reason (a defect found, a hidden
dependency, a risk discovered).

**This is ONE serial stage, not two.**
qa and the reviewer run **concurrently by default** — both are read-only and hold
no mutating tool, so neither can disturb what the other measures, and running
them in sequence buys nothing while costing a whole stage. A substantive packet
budgets **2 serial stages median**: the builder, then this.

1. **Check tree-quiet FIRST.** A read-only gate measuring a tree that a builder
   is still mutating produces junk. Do not start until all three hold: the
   builder has handed back and no builder pass is in flight; `git status
   --porcelain` is empty (or contains only what the packet declared it would
   leave unstaged); and `git rev-parse HEAD` is stable. Note that SHA — both
   gates measure it. If the tree is not quiet, **wait**; never ask a gate to
   quiet it, because neither one is allowed to write.

2. **Dispatch qa and reviewer in a SINGLE message**, both pointed at that SHA:
   - **qa** produces the proof block: full suite + regression with **exact
     counts**, the Commit-1-green-in-isolation check, the safety grep, the
     mutation check, and a UI smoke if the packet touches UI.
   - **reviewer** reviews the diff + tests + Codex second-eyes (if available) +
     the Product Trajectory Check, and emits one verdict: **pass /
     fix-then-pass / fail**. It makes no edits, and it does **not** re-derive
     qa's counts — those it cites as owned by qa.

3. **Reconcile the two when they return.** They ran without seeing each other, so
   this step is yours: a reviewer **pass** is conditional on qa landing
   **GREEN**, and a qa **RED** blocks the close whatever the verdict says. On
   RED, stop and route back to the orchestrator — do not close.

4. **On `fix-then-pass`, spend the third stage deliberately.** Announce it —
   `Depth: 3 — reason: fix-then-pass (<n> enumerated items)` — and have the
   builder apply **every enumerated item in one pass**. Then confirm only those
   items; a full re-gate is owed only if the reviewer's named exceptions fired
   (a logic change, a change in test count, an edit outside the enumerated
   items, or a RED qa). A **fourth** serial stage is a defect: re-cut the packet
   instead.

Report the qa proof block, the reviewer verdict, and the reconciliation. Do not
merge, push, or deploy — that needs explicit go.

Packet (optional): $ARGUMENTS
