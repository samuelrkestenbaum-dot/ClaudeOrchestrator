# Active Packet

<!-- GRAVITO:TEMPLATE (seeded by the Build OS installer; yours to edit,
     never overwritten once it exists) -->

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

**Starting value: NO PACKET IN FLIGHT.** The fields below are an empty form.
Fill them in — and have the orchestrator confirm them — before delegating to the
builder. A builder that starts from an unfilled form is building from guesses.

- **Status:** none active
- **Packet id:** _<id, e.g. `P-NNN`>_
- **Title:** _<short title>_

## Goal / "done" criteria

- _<the single, testable outcome that means this packet is done>_

## In scope

- _<files / surfaces this packet may touch>_

## Out of scope (explicit)

- _<things that look related but are NOT this packet — surface as new packets>_

## Branch base

- _<expected merge-base, e.g. `main` — the orchestrator verifies via
  `git merge-base` before any work starts>_

## Plan (≤2 commits)

1. **Commit 1 (green in isolation):** _<test-first change that passes on its own>_
2. **Commit 2 (optional, same packet):** _<follow-through that keeps suite green>_

---
_Initialized empty. Define and confirm a packet here before delegating to the
builder._
