---
description: Prove and review the active packet — run qa, then reviewer (pass / fix-then-pass / fail).
argument-hint: "[optional packet id]"
---

Review and prove the active build packet before it is closed.

**Substantive lane only.** `tiny`-lane work is proved by its ONE targeted check —
it does not get a qa battery or a review round. Running this on a tiny-lane
change is an escalation and owes a stated reason (a defect found, a hidden
dependency, a risk discovered).

1. Use the **qa** subagent to produce the proof block: full suite + regression
   with **exact counts**, the Commit-1-green-in-isolation check, the safety grep,
   and a UI smoke if the packet touches UI. If qa reports **RED**, stop and route
   back to the orchestrator — do not proceed to close.

2. If qa is **GREEN**, use the **reviewer** subagent to review the diff + tests +
   Codex second-eyes (if available) + the Product Trajectory Check, and emit one
   verdict: **pass / fix-then-pass / fail**. The reviewer makes no edits.

Report both the qa proof block and the reviewer verdict. Do not merge, push, or
deploy — that needs explicit go.

Packet (optional): $ARGUMENTS
