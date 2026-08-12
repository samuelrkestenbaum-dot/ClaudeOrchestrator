# EXP-0009 RESULT — does persistent memory beat rediscovery? NO, as delivered.

**D3 fork branch selected mechanically: "gap becomes LESS favorable — memory
causes context drag or stale-state interference → redesign memory delivery
before any further Phase 2 proof."**

Read: `read-study.mjs` (frozen before rep 2 completed) → `results/READ.txt`.
40/40 arms admissible, 40/40 accepted, both reps. Identity across the mid-run
orchestration intervention: UNIFORM (`verify-identity.mjs`, precommitted
criterion; see MID-RUN-INTERVENTION.md).

## The primary judgment (operator amendment 2: position-matched gap)

leanmem/native ratio by position, paired, mean over 2 sequences × 2 reps:

| metric   | P1   | P2   | P3   | P4   | P5   | P1 vs late(P4,P5) |
|----------|------|------|------|------|------|-------------------|
| cost     | 0.89 | 1.14 | 1.04 | 0.93 | 1.14 | 0.89 → 1.04 LESS favorable |
| uncached | 0.93 | 1.32 | 1.18 | 0.98 | 1.17 | 0.93 → 1.07 LESS favorable |
| turns    | 0.85 | 0.98 | 0.92 | 0.94 | 1.00 | 0.85 → 0.97 LESS favorable |

The preregistered signature (native flat, gravito declining with position) did
NOT appear. The treatment advantage was LARGEST at position 1 — where both
arms have an empty memory store — and shrank as memory accumulated.

## Why: the diagnostic decomposition the amendments made possible

- **P1 (no memory, either arm):** leanmem 0.85–0.93 — the lean substrate
  itself is slightly cheaper than native here, consistent with the decisive
  test. This is the whole observed advantage, and memory then eroded it.
- **P2–P4 (inline delivery):** ratio rises above 1; uncached is worst exactly
  at P2 (1.32) where delivery begins — the delivered bytes are charged
  (amendment: memory tokens ride uncached input, charged in full) and do not
  pay for themselves.
- **P5 (pointer mode, stores >4KB):** `memory_reads = 0` in all four P5 arms —
  the pointer was NEVER followed. In fact memory_reads = 0 in ALL 20 leanmem
  arms: push-delivered memory was consumed as context (12/20 arms had inline
  bytes in-stream), but no worker ever chose to read the store.
- **Rediscovery:** leanmem showed fewer outside-task-file reads at EVERY
  position including P1 (0.0–0.5 vs native 0.5–1.5) — a substrate effect, not
  a memory effect, since it is present before any memory exists. Searches: 0
  everywhere, both arms.
- **Stale-memory harm: none.** 0/12 memory-consulted arms failed acceptance.
- **TOM guard: held.** memory_writes_by_worker = 0 in all 20 leanmem arms.
  Three text-classifier flags (2 capability_search, 1 routing_bookkeeping)
  were inspected verbatim and are false positives: each is an ordinary final
  completion report. No memory administration, no gate diagnosis, no
  capability probing occurred.

## Failure localization (the operator's four stages)

- **Delivery: WORKED.** Bytes reached the worker's context at session start
  in 12/20 arms exactly per design; mode switch to pointer at >4KB occurred
  at P5 in both sequences (store sizes: A 5.0KB, B 5.4KB after P4).
- **Retrieval/selection: NOT EXERCISED.** Push design removed retrieval; the
  one retrieval path that existed (pointer at P5) went unused 4/4 times.
- **Memory quality/value: THE FAILURE.** Machine-distilled task reports
  (what was fixed, which idiom) did not make the next task cheaper. These
  tasks are self-contained — the error list names the file and line, and the
  fix idiom is rediscoverable in-file faster than 3–5KB of prior-task prose
  pays back. The absolute curves (secondary) show both arms getting cheaper
  after P1 — task difficulty, absorbed by pairing as designed.

## What this does and does not say

- It does NOT reopen Phase 1: lean economics at P1 replicate (≈0.9× native).
- It does NOT say organizational memory is worthless — it says THIS memory
  (distilled completion reports, push-delivered as context, on self-contained
  fix tasks) is net drag: paid in uncached tokens, unread when optional,
  yielding no measurable reuse value.
- Per the preregistration: no rescue variants of this experiment. The next
  move is a redesign of what is remembered and how it is surfaced (e.g.
  memory that carries codebase-level discoveries a task cannot cheaply
  rediscover, delivered selectively), preregistered as its own experiment.

Program state: D3 attempt 1 recorded; branch-3 action logged. Phase 2 proof 1
is answered for this design. Proof 2 (reusable skills) does not proceed until
memory delivery is redesigned, per the fork's own rule.
