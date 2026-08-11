# EXP-0009 — Does persistent memory beat rediscovery? PREREGISTRATION

**Phase 2, proof 1 of 5. The first experiment whose unit of measurement is a
CURVE ACROSS TASKS, not a single arm. Frozen before any arm runs.**

## Hypothesis and signature

Organizational memory makes task N cheaper than task 1 because the expensive
discovery (what the canonical fix idiom is, what the underlying types are)
happens once and is reused.

> **Native: roughly flat cost/turns per sequence position — every task starts
> fresh. Gravito-with-memory: declining across positions as knowledge
> accumulates.**

The operator's fairness constraint is binding: Gravito must win **by reusing
task-relevant organizational cognition** — never by extra context, easier
tasks, or a different task order.

## Sequences — derived by rule, not by choice

From the frozen error corpus (`EXP-0006/results/baseline-tsc.txt`, 781 errors):
cluster by **exact error message** (identifiers included), take the two
clusters spanning the most distinct files, and within each take the **top 5
files by in-cluster error count (desc, tie alphabetical)** as positions P1–P5.
The rule was stated before the file lists were looked at; the lists follow
from it mechanically.

**SEQ-A — `TS18047 'db' is possibly 'null'`** (108 errors / 9 files; one
canonical null-handling convention to discover):
P1 `server/emotional-geometry-runtime/alert-analytics.ts` (16) ·
P2 `server/infrastructure/data-retention.ts` (16) ·
P3 `server/deployment/deployment-persistence.ts` (14) ·
P4 `server/emotional-geometry-runtime/geometry-alerting.ts` (14) ·
P5 `server/router-groups/geometry-admin-router.ts` (13)

**SEQ-B — `TS18046 'error' is of type 'unknown'`** (21 errors / 8 files; one
catch-clause narrowing idiom):
P1 `server/governance/control-tower-router.ts` (6) ·
P2 `server/governance/behavioral-correctness-audit.ts` (5) ·
P3 `server/planes/router.ts` (3) ·
P4 `server/copilot/batch-page-updater.ts` (2) ·
P5 `server/governance/model-router.ts` (2)

Position order is identical in both arms; per-position pairing absorbs
task-difficulty differences. The task prompt at each position is the EXP-0006
prompt template targeting only that position's file and its in-cluster errors
— **byte-identical across arms**.

## Arms

- **native** — no substrate, fresh session per task (its natural mode).
- **lean-mem** — the lean substrate (proven architecture) plus the smallest
  possible memory loop, both pinned to one commit recorded per-arm exactly as
  the decisive test did:
  1. **Accrual (machine-authored, mechanical):** after each admissible
     lean-mem arm, the HARNESS distills a memory entry from stored artifacts
     only — task id, file, error code/count, verification status, and a
     truncated excerpt of the worker's own final report (first 900 chars,
     mechanical cut, no editing) — appended to `build-os/memory/task-log.md`
     in a per-sequence memory store. No experimenter-authored content, ever.
  2. **Carry-forward:** before position k+1, the product tree resets to seed
     (both arms, every position) but the lean-mem arm's memory store persists
     and is administered as DATA.
  3. **Delivery (push, not search — B's lesson):** the lean session-start hook
     emits the memory file inline when ≤4KB (a pointer plus count above that).
     This is a small substrate addition; it ships as a new pinned commit and is
     part of the declared treatment.

**Everything else identical to the decisive test:** runnable environment and
grants, model, acceptance adjudicator, 1200s ceiling, accounting, admissibility,
frozen classifiers. No other harness change.

## Fairness guards (each checked mechanically at preflight)

1. Prompts byte-identical across arms at each position.
2. Product tree byte-reset to seed before every position, both arms.
3. The memory store contains ONLY machine-distilled entries from the same
   sequence's own prior lean-mem arms — provenance field on every entry.
4. Memory tokens are charged to lean-mem in full (they ride uncached input).
5. Treatment identity by pinned commit + administered-bytes hash, as before.

## Metrics (operator-fixed)

Per arm: cost, uncached tokens, turns, acceptance; rediscovery behavior
(product-file reads outside the task file + search calls — the frozen
classifiers); **reused-memory events** (structural: Read of the memory store
path, plus session-start memory bytes emitted); **stale/incorrect-memory harm**
(acceptance failures or new-error rejections in arms whose memory was
consulted). Per sequence: the position curves P1→P5 for cost/uncached/turns,
per arm.

## Analysis and the precommitted fork

Primary comparison: **within-arm slope** across positions (P1 vs mean of
P4+P5), and **between-arm per-position pairing**. The signature requires
native's P1→P5 roughly flat AND lean-mem's declining. n: 2 sequences × 5
positions × 2 arms × 2 reps = 40 arms; rep 1 of both sequences runs first and
the fork is applied only when both reps exist (the program has been burned
twice by n=1 curves).

- **Falling lean-mem curve + acceptance held (same or better):** memory
  compounding works → proceed to proof 2 (reusable skills).
- **Flat lean-mem curve:** memory exists but creates no economic value → fix
  retrieval/selection before adding more memory. No rescue variants of this
  experiment.
- **Worse than native curve:** memory causes context drag or stale-state
  interference → redesign memory delivery.
- **Acceptance/quality loss in lean-mem:** the memory-advantage claim FAILS at
  this proof regardless of cost.

A confirming result must also show ≥1 reused-memory event in the arms that got
cheaper — a falling curve with zero memory consultation is a confound, not a
confirmation, and is reported as such.

## What this experiment is not

Not a Lean validation (closed), not a baseline (S1 refuses), not proof 2–5.
#53 parallelization stays deferred unless wall-clock proves prohibitive
(~40 arms ≈ 7–9h serial across two nights is acceptable; beyond that #53 moves
up, per the operator).
