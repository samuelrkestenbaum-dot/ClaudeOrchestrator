# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** none active
- **Packet id:** —
- **Title:** —

## Last closed

- **P-023 — Project-agnostic bootstrap.** Closed 2026-07-26. Receipt:
  `build-os/receipts/P-023.md`. Commit `b908453` (base `0f831fd`,
  `origin/claude/add-build-os`). Suite 223/19 (RED) → **245/0** (GREEN); test section 26
  (+29 checks); Commit-1 green in isolation at 245/0 in a detached worktree; safety grep
  clean. Reviewer **FIX-THEN-PASS** (4 defects, all fixed); Codex second-eyes unavailable
  on this surface → single-reviewer pass.

## Next (candidates — not yet declared)

- Commit the P-023 `README.md` documentation change (uncommitted in the working tree).
- Decide Context Mode routing enablement (stays a non-secret pilot).
- Name a target repo + approve a secret for the GH Actions templates.
- Authorize / enable the deferred connectors.

## Goal / "done" criteria

- _<filled when the orchestrator declares the next packet>_

## In scope

- _<declared on open>_

## Out of scope (explicit)

- _<declared on open>_

## Branch base

- _<expected merge-base, e.g. origin/main — orchestrator verifies via git merge-base>_

## Plan (≤2 commits)

1. **Commit 1 (green in isolation):** _<test-first change that passes on its own>_
2. **Commit 2 (optional, same packet):** _<follow-through that keeps suite green>_

---
_Confirmed by orchestrator. Builder implements exactly this scope._
