# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** defined — awaiting explicit go (do not implement). No packet is active (last closed: P-002 — see build-os/receipts/P-002.md).
- **Packet id:** P-003
- **Title:** Phase 1 Repository Auditor — implementation start

## Goal / "done" criteria

- First implementation slice per LaunchGraph `specs/phase-1-repository-auditor.md`; the exact slice is to be confirmed by the orchestrator at go time, with the AT coverage (from AT-01..AT-29) it satisfies named explicitly.

## In scope

- LaunchGraph repo, per spec §1 boundaries.

## Out of scope (explicit)

- Everything in spec §13 (deferred functionality).
- Merge or PR.
- Provider access of any kind.

## Branch base

- origin/claude/launchgraph-product-scope-43pgdx @ 5621aa9 — orchestrator verifies via `git merge-base` before building.

## Plan (≤2 commits)

- To be declared at go (≤2 commits, Commit-1 green in isolation).

---
_Staged by the archivist on close of P-002 (2026-07-23). This is a candidate
definition only — do not implement until the orchestrator confirms explicit go
and declares the commit plan._
