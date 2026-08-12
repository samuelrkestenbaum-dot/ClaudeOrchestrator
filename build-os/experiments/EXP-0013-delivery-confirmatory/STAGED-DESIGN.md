# EXP-0013 — delivery-confirmatory study, STAGED (qualification-first)

*Status: PROPOSED. Supersedes the single-shot 40-cell confirmatory plan from
the EXP-0011 postmortem. Nothing here is authorized to spend; each stage
requires its own owner go. The 38 EXP-0011 cells are ANALYZED (design
parameters below) and NEVER POOLED into any confirmatory statistic.*

## What the postmortem audit actually found (design input, evidence-backed)

Replay of the sealed EXP-0011 stores (tests/context_delivery_tests.sh §1)
proved the live LeanRules starvation was NOT cap asymmetry and NOT matching:
8 of 12 distilled rules individually exceed the 1536B budget, so the
skip-not-block selector skipped every match; the harness gate passed on
0 bytes, its message misdescribed empty delivery as "position 1", and
`skipped_oversize` never reached the economics record. Consequence:
**equalizing the two caps — the postmortem's original prescription — would
NOT have produced a clean comparison** (at 1536B both arms starve; the
defect class survives any cap). The architectural fix is the UCDL
(build-os/delivery/): atomic units below the budget floor, one scoring
path, explicit versioned budget policies, complete per-run delivery
receipts, and unintended-empty = invalid BEFORE model spend.

Design parameters carried from the 38 exploratory cells (analyze-not-pool):
SD of paired log cost-ratio 0.3125; infra-error rate 5% (2/40); ~600s and
~$2 per cell; acceptance near-ceiling in treatment arms.

## Stage 0 — treatment integrity, zero spend (BUILT; this commit)

- UCDL library with insight-first@1 and whole-unit@1 policies, context and
  SKILL.md renderers, full receipts, invalid-empty semantics.
- Sealed-evidence replay proving defect and fix on identical frozen inputs.
- Deterministic fixture qualification: byte-identical receipts across runs;
  selection/rendering separation (same selected_ids across surfaces).
- No-spend concurrency calibration (calibrate-noload.mjs): CPU/scheduler
  inflation vs the precommitted <10% bound, refusing under study locks.
  Stated limit: provider-side contention is invisible to it by design.
- Exit: tests/context_delivery_tests.sh green (12/12 at freeze).

## Stage A — 8-cell / 4-matched-pair qualification pilot (REQUIRES OWNER GO)

**Purpose:** qualify the instrument, not answer the question. Direction is
not read at this stage under any outcome.

**Design:** 1 fresh task sequence x 4 positions x 2 arms x 1 rep = 8 cells,
4 position-matched pairs. Arms: LeanRules-via-UCDL vs LeanSkills-via-UCDL —
SAME policy (insight-first@1), SAME cap, different RENDERER only (context
vs SKILL.md), so the unit-of-memory question finally varies one factor.
Arm order within each pair coin-flipped and precommitted before launch.

**Precommitted continuation rules (ALL evaluated mechanically, none about
effect direction):**
1. DELIVERY: every treatment cell at position >=2 has a non-empty delivery
   receipt, or an explicit NO_CONTEXT decision with a recorded reason.
   One unintended empty => halt; the pilot is void; fix and restart fresh.
2. RELIABILITY: infrastructure errors <= 1 of 8 launches (retry allowed,
   attempt preserved). More => harness fails qualification; halt.
3. CONCURRENCY: no-spend calibration passes (<10%) before launch AND the
   pilot's own paired live check (the two sequences' cells interleaved at
   width 2) shows median elapsed inflation < 10% vs the solo cells;
   otherwise Stage B runs serial and elapsed demotes to tertiary.
4. EFFECT-SIZE / VARIANCE: continuation keys on VARIANCE, not direction —
   if observed SD of paired log token-ratio <= 0.45 (1.5x the EXP-0011
   estimate), the Stage B power calculation stands; if larger, Stage B's n
   is recomputed and re-authorized before any expansion.

**Cost/time envelope:** ~8 x $2 = ~$16, ~1.5h at width 2 (serial within
sequence by design — memory accumulates), plus prep/adjudication which
parallelize freely (unmeasured).

## Stage B — powered confirmatory expansion (SEPARATE OWNER GO)

Only reachable through Stage A's rules. Current estimate: 20 matched pairs
(2 sequences x 5 positions x 2 reps, 40 cells, ~$80, ~4h at width 2) powers
detection of an 18-20% token difference at 80%/alpha .05 two-sided; final n
fixed from Stage A variance BEFORE launch. Fixed stopping rule: run all
planned cells; no interim reads; >10% invalid cells voids the study.
Primary metric: paired log-ratio of output+uncached tokens
(cache-insensitive); cost secondary; elapsed per the concurrency verdict.

## Honest limitations

- Stage 0 proves delivery mechanics on sealed stores and fixtures, not that
  delivered context helps: effect questions belong to Stage B alone.
- The no-spend calibration cannot see provider-side contention (rate
  limits, cross-arm prompt-cache warming). Randomized arm order balances
  cache advantage in expectation; the cache-insensitive primary metric
  removes most of the remaining exposure; neither eliminates it.
- Insight atoms are mechanical derivations (exhibit-stripped rules), not
  summaries; whether a stripped insight retains the rule's value is itself
  part of what Stage A/B measure — it is not assumed.
- The 38 EXP-0011 cells stay exploratory forever: harness changed (UCDL),
  so their arms are not the same treatments as EXP-0013's.
- UCDL access_observability is delivery-side only; worker reads and skill
  invocations remain a harness stream-parser concern.

## Migration implications (Phase 1 boundary)

UCDL is standalone: nothing consumes it yet. Sealed EXP-0010/0011/0012 code
is untouched (their defects are preserved evidence). Future wiring —
EXP-0013 harness, and any product use (session-start memory emission,
gravito goal-context) — is EXPLICITLY out of this phase and needs its own
authorization. parseRuleStore() is the migration adapter: existing `## RULE`
stores are readable in place, losslessly (unit count == heading count,
provenance intact — test §8); no store rewrite is ever required or allowed.
