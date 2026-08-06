# EXP-0004 harness — context-compiler A/B (v1.0.0)

Two arms, matched pairwise, over tasks that **do not exist yet**. This harness
is the machinery only: **it does not select tasks**. Selection happens after
PILOT-0002 closes and after AMENDMENT 1's eligibility check passes, and the
runner takes whatever set is frozen — refusing the ones it must.

See `../../../compiler/AB_PREREGISTRATION.md` for the question, the conditions,
the metrics, the conclusion vocabulary, the blinding, the stop conditions, and
both amendments. This file is only the machinery.

Everything here is invoked via `node`. **No file in this harness is executable,
by design** — the repository's executable census must not move.

## The pieces

| file | role |
|---|---|
| `run-exp0004.mjs` | the matched-arm runner: registration + prior-pilot exclusion, the eight arm-invariance assertions, the derived arm order, the clean-reset checks, and the AMENDMENT 2 aggregate with its confound ledger. |
| `measure.mjs` | the per-task-per-arm measurement record: seventeen tier-labeled fields, `-` for every unknown. Also the validator the runner uses at aggregate time. |
| `verdict.mjs` | the conclusion vocabulary applied mechanically, with the binding acceptance veto and the preregistration ambiguities named. |
| `prereg-thresholds.mjs` | the ONLY source of thresholds: each constant is paired with the preregistration phrase it comes from, re-parsed at load, and refused on drift. |
| `../../../compiler/AB_PREREGISTRATION.md` | READ-ONLY here. The harness parses it; it never edits it. |

## The sequence

```sh
H=build-os/experiments/EXP-0004-context-compiler/harness

# 0. Eligibility FIRST (AMENDMENT 1). Measured, then recorded, then registered.
node build-os/compiler/index/build-index.mjs stats index.json   # -> no_parser share
#    write eligibility.json: { "no_parser_share_pct": N, "recorded_before_arm_a": true, ... }

# 1. Register the frozen task set. Prior-pilot tasks are refused HERE.
node $H/run-exp0004.mjs register --tasks tasks.json --eligibility eligibility.json \
                                 --out /tmp/exp4/registry.json
node $H/run-exp0004.mjs exclusions          # the ten refused tasks, auditable
node $H/run-exp0004.mjs plan --registry /tmp/exp4/registry.json   # the derived order

# 2. Per task: assert the arms are matched, then run the pair from the pinned seed.
node $H/run-exp0004.mjs run-pair --registry /tmp/exp4/registry.json --pair pair-T1.json \
                                 --repo /tmp/exp4/work --out /tmp/exp4/pairs/T1 \
                                 --reset-between-arms --exec-cmd '<the worker invocation>'

# 3. Per task per arm: a tier-labeled measurement record.
node $H/measure.mjs template --task T1 --arm B --out /tmp/exp4/records/T1.B.json
node $H/measure.mjs validate --record /tmp/exp4/records/T1.B.json

# 4. Aggregate (AMENDMENT 2 runs here), then the verdict.
node $H/run-exp0004.mjs aggregate --registry /tmp/exp4/registry.json \
                                  --records /tmp/exp4/records --out /tmp/exp4/aggregate.json
node $H/verdict.mjs --aggregate /tmp/exp4/aggregate.json
```

## Invariants the harness enforces (refusals, not conventions)

- **Eight fields identical across arms, asserted before every pair**:
  `repository_seed_commit`, `task_definition`, `model_id`,
  `acceptance_criteria`, `max_retries`, `authority_mode_policy`,
  `baseline_measurement`, `measurement_boundaries`. A mismatch **or an
  absence** refuses (exit 2) and names the field. Each is also cross-checked
  against the registry, so a pair cannot agree with itself while disagreeing
  with what was registered.
- **Arm order is derived, never sampled.** Rule `task-index-parity-v1`: even
  task index runs `A,B`, odd runs `B,A` — the counterbalancing the
  preregistration requires, without a random source. The rule id, its
  statement, and its derivation are RECORDED in the registry and in every pair
  record. No RNG and no clock is read anywhere in this harness; two
  registrations of the same input are byte-identical.
- **No arm starts on a moving tree.** HEAD must equal the pinned seed and
  `git status --porcelain` must be empty. A dirty tree refuses and names the
  offending paths. With `--reset-between-arms` the tree is returned to the seed
  between arms and after the pair, recorded as `reset_between_arms: performed`.
- **Ten prior-pilot tasks refused at REGISTRATION** (PILOT-0001 T1–T5,
  PILOT-0002 T1–T5), by name, never silently skipped later. Matching is
  deliberately broad: a false refusal costs one candidate task; a false
  admission contaminates a frozen pilot, which cannot be undone. A pair for an
  unregistered task is also refused, so the gate cannot be bypassed downstream.
- **AMENDMENT 2 is mechanical.** Arm B's starting bytes must equal capsule +
  prefix and the broad-context payload must be absent. A violation — or a check
  that cannot be verified — is recorded `result_confounded`, excluded from the
  aggregate (n drops), and written to `CONFOUNDED_LEDGER.txt`, which makes the
  exclusion permanent: never repaired, never re-run into the aggregate.
- **An unknown is a `-`, never a zero.** Tier `UNAVAILABLE` carrying a value
  refuses; a `-` claiming a tier above what was measured refuses; an admitted
  task with an unmeasured uncached, elapsed, or acceptance figure refuses the
  whole aggregate, because a median computed over an admission is a
  fabrication.
- **Thresholds come only from the preregistration.** Each is parsed out of
  `AB_PREREGISTRATION.md` and cross-checked against the constant citing it. A
  threshold flag on the command line is refused; a preregistration whose numbers
  moved is refused rather than adopted.

## The verdict rule, in order

`dU` = median % uncached-token reduction (B vs A), `dT` = median % elapsed
reduction, `accA`/`accB` = acceptance rates.

| # | condition | operator label | preregistered outcome |
|---|---|---|---|
| 0 | a harness/seeding/arm-isolation defect is recorded, or nothing was admitted | `result confounded` | `result confounded` |
| 1 | eligibility or capsule signal says the capsule was compact for lack of index signal | `small-because-uninformed` | `result confounded` (AMENDMENT 1's binding clause) |
| 2 | `accB < accA`, or `dU <= -10%` | `context compilation harmful` | `context compilation harmful` |
| 3 | acceptance not worse, `dU >= 25%`, `dT >= 25%` | `supported` | `context compilation supported` |
| 4 | acceptance not worse, `dU >= 25%`, `dT < 25%` | `compression only` | `context compilation supported` |
| 5 | acceptance not worse, `dT >= 25%`, `dU < 25%` | `acceleration only` | `promising but underpowered` / `no benefit detected` |
| 6 | otherwise | `inconclusive` | `promising but underpowered` / `no benefit detected` |

**The acceptance veto is a separate binding gate, run after the table.** If
arm B's acceptance rate is lower than arm A's, the verdict cannot be
`supported`, `compression only`, or `acceleration only` — whatever the token
and time figures say. The preregistration's own sentence, quoted from the file
by the tool: *"Compression that costs acceptance is a loss, not a trade."*

## Preregistration ambiguities — named, not resolved silently

`verdict.mjs` prints all six on every run. They are properties of the
preregistration text, not of the data, and each needs an operator ruling (or a
committed amendment) before results are published:

1. **AMBIGUITY-1** — AMENDMENT 1 calls small-because-uninformed *"the exact
   failure mode outcome 4 names"* (harmful) while its **binding** clause routes
   such a repository to *excluded or `result confounded`*. The tool follows the
   binding clause; the prose gloss points elsewhere.
2. **AMBIGUITY-2** — **no wall-clock threshold is preregistered.** 35–65%
   faster appears only as a hypothesis. `supported` / `compression only` /
   `acceleration only` therefore **borrow** the uncached-token thresholds for
   elapsed time. Disclosed as borrowed; register one before the run.
3. **AMBIGUITY-3** — the preregistration registers **five** outcomes and says
   *"no other wording permitted"*; this harness was asked for **seven** labels,
   three of which are not among the five. Both are reported; the
   `preregistered_verdict` is the publishable one.
4. **AMBIGUITY-4** — *"task count too small to separate"* registers **no
   minimum n**. No n-based rule is applied; `underpowered_by_n` is reported as
   `-`. Choosing a minimum after seeing the data is what preregistration exists
   to prevent.
5. **AMBIGUITY-5** — the primary combined metric sums uncached tokens, elapsed
   seconds, and human attention with no units or weights. Computed literally,
   used for **direction only**, never as a magnitude.
6. **AMBIGUITY-6** — outcomes 2 and 3 overlap (a result can both favour B under
   25% and show no reduction reaching 10%) and the text does not order them.
   The tool tests outcome 3 first and says so.

## What this harness deliberately does NOT do

- **It does not select tasks.** No task set is proposed, ranked, or shortlisted
  here. Task selection after the data exists is the failure preregistration
  prevents, and this harness refuses threshold and selection overrides for the
  same reason.
- **It does not invoke a model.** `--exec-cmd` runs whatever worker invocation
  the operator supplies, per arm, with `EXP0004_ARM`, `EXP0004_TASK`,
  `EXP0004_REPO`, `EXP0004_OUTDIR`, `EXP0004_SEED` in the environment. The
  harness measures nothing by itself: every figure in a record is filled from
  something that was executed, or admitted as `-`.
- **It does not implement blinding.** The preregistration's X/Y arm-label
  blinding and its committed sha256 mapping are not built here; records are
  arm-labeled A/B. Blinding is a separate packet and must exist before analysis.
- **It does not touch the frozen prior experiments** (EXP-0001/0002/0003) or the
  compiler surface it measures.

Tests: `tests/exp0004_harness_tests.sh` — fixtures in `mktemp`, no network, no
model invocation, nothing under `build-os/` written.
