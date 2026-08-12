# Gravito — Phase 2 evidence brief

*Synthesis of closed, preregistered studies only. Every number below comes
from frozen artifacts in `build-os/experiments/`; nothing here is drawn from
the study currently running (EXP-0011). Written 2026-08-12 while EXP-0011
rep 1 was in flight.*

## The claim being built, in one line

**Gravito turns prior verified experience into compact cognition whose
economic advantage grows as experience accumulates — and the target is work
that is cheaper, faster, and more repeatable, not merely a lower-overhead
substrate.**

## What is proven, in the order it was proven

### 1. The overhead problem was real, and it was ours (Phase 1)

Against matched tasks in a runnable environment, the original substrate cost
**2.44×** native (cost), with the excess mechanically attributed: 77% of
excess text turns traced to a stop-refusal control loop the worker was forced
to participate in. The architectural conclusion — *make the worker stop
participating in the control plane* — was implemented as four preregistered
removals (LEAN), each demonstrated by executing the old behavior from git
before proving its absence.

Decisive three-way test (native / current / lean, pinned commits, byte-hashed
administration): **lean = 1.10× native cost**, all worker-facing control
interactions at zero. Independent audit of frozen streams: CLEAN 7/7, ratios
reproduced to three decimals. Bounded replication: **1.26×**, in band,
mechanism collapse preserved. Phase 1 verdict: *Gravito itself was not the
economic problem; making the worker operate Gravito's control plane was.*

### 2. Memory that is prose does not compound (EXP-0009, a valuable null)

40 arms, 2 sequences × 5 positions × 2 isolated reps, product tree reset to
seed at every position so ONLY memory crosses positions. Machine-distilled
prior-task reports, push-delivered (3–5KB): the position-matched
Gravito/native gap was most favorable at position 1 — with an EMPTY store —
and degraded as memory accumulated (cost 0.89→1.04). Delivery worked; harm
was zero; the memory's VALUE was the failure. Preregistered branch fired:
redesign the unit, not the transport.

### 3. Memory that is verified rules DOES compound (EXP-0010)

Same frozen native comparator, same prompts (sha-verified), same transport
pin — the unit and selection changed and nothing else: mechanically-extracted
repair rules (error-class identity, applicability, the fix idiom as verbatim
diff hunks from the arm's own accepted change), delivered as the smallest
task-relevant subset (≤1.5KB, class-matched). Result, position-matched vs
native: **cost 0.97 → 0.87 and uncached tokens 1.13 → 0.94 as rules
accumulate** — the trend EXP-0009 showed degrading, inverted by changing what
is remembered. 40/40 arms admissible; every improving arm demonstrably
received rules; zero harm; the worker never administered memory (structural
guard, 0 events across both studies).

**This is the core Phase 2 result so far: the compounding advantage is real,
and it required verified, compact, applicable cognition — not context.**

### 4. In flight, not yet evidence (EXP-0011)

Whether a harness-compiled SKILL — rules plus the demonstrated execution
procedure, on the platform's native capability surface — beats rule-memory,
on a higher-discovery-cost corpus, three-way against native and rules, with
speed and consistency preregistered as first-class dimensions (frozen before
any cell completed). The prospective hypothesis on record: *rules encode what
to know; skills encode how to execute reliably* — expected to show as
collapsed latency and variance, especially in the bad tail.

## Why these numbers deserve trust

- **Preregistration with precommitted forks** — every study's possible
  outcomes and next actions written before data; a convergence gate refuses
  runs whose results cannot change a decision, and refuses repeat attempts
  without a stated difference.
- **Pinned treatments** — arms materialize from named commits via `git
  archive`; administered bytes verified per arm; prompt sha recorded per arm
  and uniform across arms/studies sharing a comparator.
- **Isolation by construction** — per-sequence-per-rep memory stores with
  provenance gates that mechanically refuse cross-sequence/rep/position
  leakage; seed-reset product trees; admissibility symmetric across arms.
- **Machine authorship end to end** — distillation is template + the worker's
  own artifacts; an experimenter-authored memory would test the experimenter.
- **Honest defect records** — instrument false positives inspected verbatim
  and preserved (never patched against measured data); interrupted arms kept
  under named partial directories; a mid-run orchestration change disclosed
  with a precommitted benign-iff-uniform criterion, verified UNIFORM across
  all cells by a mechanical checker anyone can re-run.

## The commercial statement under test

Not "13% fewer tokens." The statement is: *by the fifth analogous task,
Gravito is cheaper, faster, takes the same proven path, and almost never
produces the tail outcomes native still produces.* Proofs 1 (memory) is
banked; proof 2 (skills, plus the speed/consistency scorecard) reads out
next; proofs 3–5 (outcome history, cognition compilation, routing) follow the
same discipline.
