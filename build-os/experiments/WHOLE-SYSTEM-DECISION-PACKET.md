# Whole-system validation — owner decision packet (PROPOSED defaults; nothing chosen)

*Design-only companion to WHOLE-SYSTEM-VALIDATION-DESIGN.md rev 3. Every
default below is PROPOSED; the owner chooses. No repository inspected or
named; no task selected; EXP-0011 untouched.*

## 1. SESOI — practical-effect thresholds

Prerequisite for EVERY row: **quality noninferiority (§2) holds.** A
threshold met with worse accepted quality is not an effect, it is a trade.
Directional evidence = interval excludes zero. Product claim = directional
AND point ≥ SESOI AND §2 passes. Thresholds are set by commercial meaning,
not by what the data is hoped to show:

| Metric | PROPOSED default | Alternatives | Commercial meaning of default |
|---|---|---|---|
| tokens per accepted outcome | **−20%** | −10% (needs replication-scale n), −30% (coarse) | a fifth off the direct model bill — visible on an invoice, survives pricing noise |
| active time per accepted outcome | **−20%** | −15%, −30% | a working day per week of agent time — scheduling-relevant, not rounding error |
| weighted accepted value per unit resource | **+20%** | +10%, +30% | one extra meaningful deliverable per five — noticeable in a sprint review |
| human minutes per accepted outcome | **−33%** | −25%, −50% | the metric buyers actually feel; high variance demands a large threshold to be honest |
| consistency (CV of cost & active time) | **−25%** | −20%, −33% | tail sessions stop dominating planning; below 20% is unresolvable at this n |

## 2. Quality gate (prerequisite to every claim)

- **Noninferiority margin:** arm B's weighted accepted-value rate ≥ arm A's
  − **5 percentage points** (PROPOSED; alternatives 3/10), on both
  unweighted and weighted acceptance, ITT.
- **Hard vetoes — any single occurrence voids all efficiency/speed claims
  for the affected scope, regardless of margins:** (a) a regression shipped
  and accepted then found within the study window and traceable to the arm;
  (b) any security/privacy failure (secret exposure, unauthorized data
  egress); (c) hidden human rescue — any unlogged intervention discovered
  post hoc; (d) any authority violation (push/deploy/scope breach without
  authorization). Vetoes are symmetric: they void the OFFENDING ARM's
  claims, and a veto in arm A does not validate arm B.

## 3. Repository selection rubric (scorecard; no inspection now)

Eligible: 20k–500k LOC; mainstream toolchain with a deterministic build and
a runnable test suite (<15 min); ≥30 plausibly independent task candidates
(issues/defects/small features); ZERO prior Gravito/experiment exposure; no
sensitive/personal data; license permitting the work; recognizable
commercial shape (a product, not a toy). Excluded: monorepos too large to
seed-verify; projects whose tests are flaky above the reliability
qualification's frozen invalid-rate; repos either arm's model plausibly
memorized as a named artifact (popular OSS) unless the task surface is
post-cutoff. Scorecard (0–2 each, ≥10 to qualify): testability ·
determinism · task-surface richness · isolation cleanliness · commercial
relevance · acceptance tractability.

## 4. Task selection and weighting (mechanical, treatment-independent)

Selection: enumerate candidates by a frozen mechanical rule (e.g. all open
defects/features matching a size grammar at the pinned seed), then
stratified random sampling — strata: small-fix / medium-change /
feature-slice, in a **4:5:3 ratio per 12 pairs** (PROPOSED). Weights frozen
per stratum BEFORE any run: 1 / 2 / 4 value points (PROPOSED). Pair
eligibility: both arms receive the identical capsule; a pair enters the
sample only via the sampler, never by anyone's preference. Anti-cherry-pick
rules: the candidate list, sampler seed, strata, and weights are committed
before treatment; substitutions only via a frozen infeasibility rule
(task impossible at the seed — logged, replaced by the sampler's next draw,
both arms identically). Capsule fields: id · statement · context pointers ·
stratum/weight · acceptance script ref · authority bounds · intervention
decision list · frozen at freeze.

## 5. Acceptance (default blend)

(1) **Deterministic behavioral gate first:** capsule's acceptance script
(tests/verification commands) — machine verdict, no discretion. (2)
**Blinded expert review** for what scripts cannot judge (fit, safety,
maintainability): sanitized diffs, shuffled order, rubric-scored. Assessor
records a **forced arm guess + confidence per item**; identification rate
reported. Disagreement (script pass + review fail or vice versa): a second
blinded reviewer scores independently; persistent disagreement resolved by
the frozen rubric's precedence rule (behavioral gate is necessary, review
is sufficient-to-reject on enumerated grounds only) — builders are never
unblinded to resolve anything.

## 6. Human/intervention protocol

Allowed operator actions (uncharged): deliver capsule; approve
authority-gated actions per capsule bounds; answer clarification requests
FROM a frozen FAQ (identical answers both arms). Charged interventions
(logged, metered): any answer outside the FAQ; any hint, correction, or
steer; any manual fix. **Prohibited rescue:** writing/editing product code,
dictating a solution approach, or debugging on the arm's behalf — doing so
voids the task for that arm (recorded as rescue-void, ITT-charged).
**Emergency stop** (safety/authority breach) is always allowed; it voids
the task for the stopped arm and triggers veto review (§2). Metering: the
clock starts when the operator begins reading the arm's request and stops
at the operator's final response; clarifications answered from the FAQ are
charged at zero to BOTH arms symmetrically.

## 7. Overhead and amortization

Itemized separately: **one-time** (install, configuration, initial
compilation of context/skills) vs **recurring** (per-task orchestration,
verification, recovery, state maintenance). PROPOSED primary horizon: **the
study's own accepted-outcome count** (setup spread over exactly the work it
served — nothing hides in a hypothetical future). Sensitivity horizons: 50
and 250 accepted outcomes (a quarter and a year of steady product use),
labeled models. GROSS always reported beside NET; an advantage that exists
only at the 250-outcome horizon is reported as exactly that.

## 8. Environmental exclusions (smallest symmetric frozen list)

Only: (a) container/host reclamation mid-task; (b) provider outage or hard
rate-limit rejection (not slowness); (c) repo-external infrastructure
failure (registry down). Each requires contemporaneous evidence, applies
identically to both arms, and forces a task RE-RUN (never silent excision).
Everything else — timeouts, crashes, malformed output, model refusals,
capability gaps — is ITT and stays charged. Hardening per RED-TEAM-AUDIT
H2 / DESIGN rev 4 §T4: machine-generated evidence, blind adjudication, max
one re-run per arm-task from a fresh clone, per-arm exclusion counts with a
2:1 asymmetry flag.

## 9. Ordering (PROPOSED recommendation, with the tradeoff)

**Recommendation: whole-system validation FIRST, staged A/B/C second.**
Tradeoff: A/B/C-first yields cleaner mechanism attribution and a better
whole-system design later, but delays the owner's actual product question by
weeks and risks optimizing components of a system whose end-to-end value is
unproven (the only prior whole-system result was negative, on the old
architecture). Whole-system-first risks running Gravito with an unoptimized
skill layer — accepted, because EXP-0010/0011 already fix the memory design
well enough to test the product claim, and a positive product result makes
the mechanism studies decision-relevant rather than academic. Sequence:
calibration + reliability qualification → whole-system stage 1 → milestones
→ (expansion / A-B-C / replication per results and owner).

## 10. Budget/time envelope (formulas + scenarios, not precision)

Let T = mean minutes per arm-run (EXP-0011 observing ≈ 10–19 min/arm on
smaller tasks; whole-repo tasks plausibly T ≈ 20–60), C = mean model cost
per arm-run (EXP-scale ≈ $1–2; larger tasks plausibly $2–8).

- **Stage 1 (12 pairs = 24 arm-runs):** tokens/cost ≈ 24·C ($50–200);
  machine time ≈ 24·T (8–24 h serial); operator time ≈ 12·(capsule+
  intervention+acceptance ≈ 15–30 min) ≈ 3–6 h; calendar 2–4 days serial.
- **Expansion (+12 pairs):** the same again.
- **Three milestones (6 large runs):** ≈ 6·(3–6×T) machine; acceptance is
  the operator cost driver (blinded review ≈ 1–2 h each); calendar 3–6 days.
- **Second-operator audit (4 pairs = 8 arm-runs):** ≈ 8·C + second
  operator's 2–4 h.
- **Parallelism after calibration passes:** independent PAIRS may run wide
  (they share no state); the two arms of one pair stay serialized per the
  washout; milestones serial. Equal-concurrency estimand runs both arms at
  the calibrated width. Nothing runs wide before the gate passes.

## 11. One-page owner choice table

| # | Decision | PROPOSED default | Alternatives | Consequence | Needed before |
|---|---|---|---|---|---|
| 1 | SESOI set | §1 bold column | §1 alternatives | claim thresholds | freeze |
| 2 | noninferiority margin | −5 pp | −3 / −10 | quality gate strictness | freeze |
| 3 | repository (+2nd for replication) | — (rubric §3) | — | everything downstream | qualification |
| 4 | strata ratio & weights | 4:5:3 · 1/2/4 | owner variants | value weighting | freeze |
| 5 | acceptance rubric author + reviewers | — | — | blinding integrity | freeze |
| 6 | operator + FAQ + rescue list | — | — | §6 protocol | qualification |
| 7 | amortization horizons | study-n + 50 + 250 | owner variants | NET meaning | read (analysis) |
| 8 | exclusion list | §8 three items | owner edits | ITT boundary | freeze |
| 9 | ordering | whole-system first | A/B/C first | weeks of delay vs attribution | after EXP-0011 read |
| 10 | n₁/n_max/blocks | 12/24/4 | 8/16 · 16/32 | power vs cost | freeze |
| 11 | budget ceiling | — ($ and days) | — | expansion feasibility | execution |
| 12 | milestone definitions (≥3) | — | — | corroboration scope | freeze |

## 12. Go/no-go readiness checklist

Ready now (design-level): estimands · power design · claim gates · quality
vetoes · ITT boundary · task/capsule machinery spec · acceptance flow ·
operator protocol · budget formulas. **Impossible to finalize before
EXP-0011 closes:** the calibration verdict (its guard refuses while the
study lock is live) and any harness runs including qualification.
**Impossible before repository choice:** acceptance script tooling ·
concrete task candidate enumeration · capsule contents · milestone
definitions · realistic T and C constants · the sampler's candidate list.
Go = all §11 rows resolved + calibration passed + qualification passed
within its frozen invalid-rate. No-go/hold = any veto-class ambiguity in
the protocol, or qualification breaching its rate.

## Unresolved risks (carried, not hidden)

Single operator (audited, not solved) · single repo until replication ·
n≤24 resolves only moderate-to-large effects · repo memorization risk
(mitigated by rubric, not eliminated) · assessor deblinding via style
(measured via guesses, not prevented) · T/C constants unknown until the
repo exists, so the budget envelope is a scenario range, not a quote.
