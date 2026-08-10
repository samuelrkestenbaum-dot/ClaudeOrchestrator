# The decisive test — Lean closes the gap. FROZEN.

**Native vs Current vs Lean, runnable environment, T01–T04 × 3 reps per
treatment. Treatments proven distinct by administered bytes
(`results/source-identity.json`): current = `241ac45` (byte-identical to the
measured 2.44× baseline's administered CODE), lean = `78bedf1`. Frozen
classifier, frozen acceptance, frozen ceiling, frozen accounting. Raw read:
`results/lean-decisive-read.txt` (regenerate with `decisive-read.mjs`).**

## Verdict — branch 1 of the precommitted fork: ARCHITECTURAL WIN

| metric | native | current | lean | cur/nat | **lean/nat** | lean/cur |
|---|---|---|---|---|---|---|
| cost USD | 1.112 | 2.515 | 1.223 | 2.26× | **1.10×** | 0.49× |
| uncached tokens | 38,463 | 78,783 | 42,256 | 2.05× | **1.10×** | 0.54× |
| turns | 23.2 | 37.7 | 25.3 | 1.63× | **1.09×** | 0.67× |
| text-only turns | 4.8 | 11.7 | **4.5** | 2.46× | 0.95× | 0.39× |
| repeat final reports | 0.67 | 2.38 | **0.58** | 3.56× | 0.87× | 0.25× |
| control round-trips | 0.0 | 4.5 | **0.0** | — | — | 0.00× |
| capability search | 0.00 | 0.13 | **0.00** | — | — | 0× |
| gate diagnosis | 0.00 | 0.29 | **0.00** | — | — | 0× |
| routing bookkeeping (text) | 0.00 | 1.17 | **0.08** | — | — | 0.07× |
| implementation reads | 0.0 | 2.0 | **0.0** | — | — | 0× |
| gravito search | 0.0 | 1.0 | **0.0** | — | — | 0× |

**Acceptance: lean 12/12, native 12/12, current 11/11 (+1 timeout).** Lean had
zero timeouts and its worst ceiling proximity was 64% (current: one kill plus
arms at 76–89%).

**Verification was executed, not skipped:** every lean arm invoked the judged
command and received compiler output in-band (12/12 arms, 3–6 in-band runs
each). The stop-gate change did not let workers claim completion without
checking — they checked, then stopped once.

## Separation (3 lean reps vs 3 current reps, per task)

| metric | separated lean-below-current |
|---|---|
| uncached tokens | **4/4 tasks** (p = 1.3e-5 two-sided) |
| control round-trips | **4/4 tasks** |
| cost | 3/4 (T04 overlaps) |
| turns | 3/4 (T04 overlaps) |
| repeat final reports | 2/4 (already near-zero) |

The one overlap source is `T04.lean.r3` — a single heavy draw ($2.94, 72
turns) in the task with the largest measured variance everywhere. The heavy
tail is shortened, not abolished.

## What this means

The interaction-model diagnosis was correct, and specifically:

- **Gravito itself was not the cost.** The same substrate — authority,
  routing receipts, evidence, continuation, capability exhaustion — is still
  present and still enforcing in every lean arm (receipts minted with runtime
  provenance, gate still refusing unreceipted mutations, stop-gate still
  holding the concession floor). The cost was **the worker administering it**.
- The classes the Target Operating Model said must go to zero went to zero
  **and dragged the residual with them**: text-only turns and repeat final
  reports landed *below* native.
- Lean is 1.10× native on cost and uncached tokens with acceptance intact —
  against 2.26×/2.05× for the identical substrate operated by the worker.

## Cautions, stated before anyone quotes the headline

1. **PROVISIONAL per P-provisional-measurement.** This is a first clean
   measurement, and this program has overturned five of those. It stands
   unquoted-as-final until adversarially validated: an independent re-read of
   the streams, and ideally one replication round at a later date.
2. **n = 3 per cell** against known within-cell CVs of 10–45%. The separation
   tests, not the means, carry the conclusion — and uncached + control
   round-trips separate completely on every task.
3. **Same author built the treatment and ran the test.** The protections are
   structural: the classifier, acceptance, environment, and ceiling were all
   frozen before Lean existed; treatments are pinned commits proven distinct
   by bytes; and the four outcome branches were recorded before any arm ran.
4. T04's heavy tail persists in shortened form; four tasks from one repository
   remain the workload's scope.

## The decision this resolves

D2 → **branch 1: architectural win.** Per the precommitted next action:
proceed to hardening and the broader vision on the lean interaction model.
The lean tree (`78bedf1` lineage) is the substrate going forward; `current`
(`241ac45`) remains on disk as the measured comparator, never to be modified.
