# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** none active
- **Packet id:** _<id, e.g. P-001>_
- **Title:** _<short title>_

## Goal / "done" criteria

- _<the single, testable outcome that means this packet is done>_

## In scope

- _<files / surfaces this packet may touch>_

## Out of scope (explicit)

- _<things that look related but are NOT this packet — surface as new packets>_

## Branch base

- _<expected merge-base, e.g. origin/main — orchestrator verifies via git merge-base>_

## Plan (≤2 commits)

1. **Commit 1 (green in isolation):** _<test-first change that passes on its own>_
2. **Commit 2 (optional, same packet):** _<follow-through that keeps suite green>_

---
_Initialized empty. Define/confirm a packet here before delegating to builder._
