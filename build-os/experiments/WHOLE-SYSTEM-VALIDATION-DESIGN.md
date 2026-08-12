# Whole-system validation — owner-directed proof objective and PROPOSED design (rev 2)

*Status: PROPOSED FOR REVIEW. Not frozen, not launched, not pushed. Rev 2
incorporates the owner's 12-point methodological review verbatim in
substance; the change log lives in the commit message and the closing
section. EXP-0011 remains untouched and running.*

## Primary question (owner's words)

**Does full Gravito produce equivalent-or-better independently accepted
product outcomes faster, with fewer exact model tokens and less human
involvement than native Claude?**

## Arms — with a FAIR native baseline (correction 1)

- **A — native Claude, competent-user baseline.** Arm A retains every
  ordinary durable resource and practice a competent user normally has:
  repository docs and CLAUDE.md, plans, full git history, normal session
  continuation (/resume and ordinary conversational continuity), ordinary
  Claude/Claude Code facilities (subagents, skills the user would normally
  have, web/tools as authorized), and any non-Gravito artifacts arm A itself
  naturally creates (notes, plans, scripts committed to its clone). ONLY
  Gravito-specific machinery is excluded: Gravito memory/stores, compiled
  context, routing, durable task state, governance assistance. A crippled
  native (fresh amnesiac sessions, no docs) is explicitly NOT the
  comparator.
- **B — full Gravito as intended:** persistent state, focused/compiled
  context, routing, bounded workers, durable handoffs, verification,
  authority controls, operated per a predefined operating protocol.

Held equivalent: model access, repo seed, authority, tools, acceptance
criteria, the human (same person, protocolized, in both arms). Cross-arm
leakage prevented: separate clones; arm B's Gravito state accumulates only
from arm B; arm A's ordinary artifacts accumulate only in arm A —
**symmetrically: both arms keep their own in-arm durable artifacts**
(correction 2/9); neither sees the other's.

## Estimands, separated (corrections 2 and 4)

1. **Cold-start matched phase:** early task positions, neither arm holding
   accumulated in-arm state beyond the seed. Reported by task position.
2. **Accumulated-state phase:** later positions, each arm carrying its OWN
   ordinary accumulation (A: its notes/plans/history; B: its Gravito state).
   The compounding claim lives here and only here.
3. **Equal-concurrency efficiency:** both arms at the same concurrency and
   model access (post-calibration width for both, or serial for both).
   Extra workers must not masquerade as intrinsic efficiency.
4. **Natural-operation throughput:** each system operated as it is intended
   to be operated (native as a competent user works; Gravito with its
   orchestration), reported as a separate practical-throughput estimand,
   never merged with (3).

## Substrate, magnitude, and replication (corrections 3 and 5)

One meaningful untouched product repository (owner-selected; NOT
empathiq-website), matched task pairs per the rev 3 two-stage design (n1=12
→ n_max=24; the earlier 10–20 range is SUPERSEDED by rev 3 §A), plus **at
least three independently accepted end-to-end milestones** (or an
owner-approved equivalent replication structure). Task weights/rubric value
points are FROZEN BEFORE TREATMENT so a trivial fix and a substantial feature
are not identical numerator units; results report both unweighted acceptance
and weighted accepted value. Single-repo claims are labeled as such;
**general product claims require replication on a second untouched
repository.**

## Operational definitions (correction 6 — frozen before data)

- **Wall time:** first token of the task's first session to acceptance
  verdict. **Active time:** wall time minus intervals where neither model
  nor human is working the task (queue/idle), per telemetry.
- **Failed hypothesis:** an approach abandoned after execution evidence
  contradicted it. **Retry:** re-execution of the same approach after
  environmental failure. **Rework:** post-acceptance-attempt modification of
  already-delivered work.
- **Regression:** independently detected functionality/verification loss
  attributable to the arm's change.
- **Human intervention:** any human input beyond the task statement;
  **rescue:** an intervention without which the arm could not have reached
  acceptance (classified per a frozen decision list); **rescue minutes**
  metered wall-clock on the human.
- **Defect-adjusted acceptance:** accepted outcomes discounted by
  post-acceptance defects found within the study window, per frozen weights.
- **Setup overhead:** one-time arm-B provisioning (installation,
  configuration, compilation). **Ongoing overhead:** per-task
  orchestration/verification/recovery spend. **Amortization horizon:** the
  task count over which setup overhead is spread in NET figures — stated,
  never implicit.
- **GROSS:** all arm-B overhead included, setup unamortized. **NET:**
  ongoing overhead included, setup amortized over the stated horizon. Both
  always reported; no third variant.

## Intention-to-treat (correction 7)

Primary analysis is **ITT**: timeouts, crashes, malformed outputs, failures,
and unavailable capabilities stay charged to their assigned arm. A frozen
environmental-exclusion rule (container reclaim, provider outage — listed
before data) is the only escape, applied symmetrically. Per-protocol is
reported as secondary only. (Deliberate divergence from prior studies'
symmetric-admissibility convention, which answered a mechanism question;
ITT answers the product question.)

## Blinding (correction 8)

Acceptance proceeds: (1) behavioral/automated acceptance first (tests,
verification commands, rubric-scripted checks); then (2) sanitized code
review — commit metadata, comments, filenames/artifacts, and stylistic
signals stripped where feasible. Residual arm-identification risk is
DISCLOSED, and the assessor records an arm guess per item so identification
rate is measured rather than assumed. Where sanitization would remove scored
qualities (e.g. documentation), the rubric names the tradeoff explicitly.

## Fresh-context continuation, symmetric (correction 9)

Both arms are tested for continuation by a cold session under equal
authority and ordinary facilities: arm A continues from its own durable repo
artifacts (docs, plans, history it created); arm B from its Gravito state.
Native is never forced to depend on conversation memory to simulate a
handicap.

## Non-determinism controls (correction 11)

Paired randomized task order; position blocking; frozen retry policy;
replication (reps per pair and ≥3 milestones) sized to distinguish a one-off
from a stable effect. Provider-side variance is a recorded limitation, not
an excuse.

## Telemetry schema

Per task, both arms: accepted/rejected + rubric scores and weights · exact
provider-native tokens (input, output, cache_read, cache_creation) ·
wall-clock and active time · cost · human interventions and rescue minutes ·
retries, failed hypotheses, rework · regressions · context supplied and
expanded (bytes) · durable commits/functionality · continuation result ·
arm-B overhead ledger (setup vs ongoing, itemized). Tokens are not joules:
any compute/energy translation is a clearly labeled model, never a
measurement.

## Primary metrics (owner-fixed) and claim gates (correction 12)

Metrics: accepted outcomes per million tokens · accepted outcomes per active
hour · total milestone elapsed time · human minutes per accepted outcome ·
defect-adjusted acceptance — each reported with uncertainty (bootstrap
effect distributions over pairs; interval estimates, never point ratios
alone; at n=10–20 the honest product is directional effects with intervals,
not significance theater).

Predefined claim gates — the MINIMUM evidence before the words may be used:

- **"faster":** median active-time advantage in BOTH cold-start and
  accumulated phases under equal concurrency, interval excluding zero, and
  milestone elapsed advantage in ≥2 of ≥3 milestones.
- **"more token-efficient":** accepted-outcomes-per-million-tokens advantage
  GROSS and NET, ITT, interval excluding zero.
- **"more consistent":** tighter dispersion (CV and tail) on cost AND active
  time, ITT, both phases.
- **"less human-dependent":** fewer human minutes per accepted outcome with
  zero uncompensated rescues, ITT.
- **Any combined product claim:** all four above on one repo, PLUS
  replication of the claimed direction on a second untouched repository.

## Sequence (recommended, per review)

1. Reliability/telemetry qualification (frozen invalid-run rate + stopping
   rule). 2. Cold-start comparison. 3. Accumulated-state comparison.
4. Equal-concurrency efficiency. 5. Natural-operation throughput. 6. ≥3
blinded milestones. 7. Replication on a second repository before any general
product claim.

## What existing evidence proves — narrowed (correction 10)

Prior results are proven ONLY within their registered conditions: the
empathiq-website corpus, these task families (tsc error repair), this model
tier, this environment, the registered positions. Within that scope: the
worker-control tax and its removal (2.44×→1.10×/1.26×); prose memory
non-compounding (EXP-0009); rule-memory compounding on cost/uncached at
modest magnitude (EXP-0010); the distillation/provenance/TOM-guard machinery;
the event-driven runtime. NONE of this generalizes beyond measured scope,
and none of it is whole-system evidence. The only prior whole-system
measurement (EXP-0005, old architecture) was negative; the lean successor is
untested at system level. This validation's outcome is genuinely open.

## Owner decisions required before freeze

1. Repository (and second repository for replication) + pinned seeds.
2. Task selection authority and matched-pair criteria; task weight rubric.
3. Blinded acceptor identity; rubric author; behavioral-acceptance tooling.
4. Milestone definitions (≥3) and acceptance bars.
5. The human: who operates both arms; intervention protocol; rescue
   decision list.
6. Amortization horizon for NET figures.
7. Environmental-exclusion rule contents (the ITT escape list).
8. Ordering vs the staged A/B/C studies; budget (duration, token ceiling,
   post-calibration concurrency).

---

# Rev 3 — power/sample design and operator-learning design (resolving the two flagged concerns; PROPOSED)

## A. Power and sample: a two-stage maximum-sample design

**Stage 1 (fixed):** n₁ = **12 pairs**, run in full regardless of interim
appearance. Why 12: a paired design detecting a standardized within-pair
effect of ~0.9 SD at two-sided α=0.05 with ~80% power needs ~10 pairs
(( (1.96+0.84)/0.9 )² ≈ 9.7); 12 adds margin and matches the scale one
serial block can complete in 2–4 days. Its limit: only large effects are
resolvable; a 0.5 SD effect at n=12 will usually be directional-only.

**Blinded precision assessment (the ONLY expansion trigger):** after stage 1
an analyst script computes the within-pair difference SD for each primary
metric under **random sign-scrambling** — signs of the pair differences are
randomized before the script sees them, so the SD (which is
sign-invariant) is computed without any exposure to arm labels or effect
direction. If the projected 95% CI half-width at the current n exceeds the
owner-chosen SESOI for a primary metric, pairs are added in **blocks of 4**
up to **n_max = 24**. Expansion is precision-driven only; there is NO
optional stopping or expansion based on favorable results, and the rule is
frozen before stage 1. n_max = 24's limit: ~0.6 SD resolvable; one repo, one
task family regardless of n.

**Estimation, not significance hunting:** the product is effect estimates
with 95% paired-bootstrap intervals. "Significant" appears nowhere; claims
are phrased by interval position.

**Smallest effects of practical interest (SESOI) — owner-selectable, with
consequences (defaults PROPOSED, not chosen):**

| Metric | Options | Consequence at n₁=12 / n_max=24 |
|---|---|---|
| tokens per accepted outcome | 10% / **20%** / 30% | 10% likely inconclusive even at 24 (needs replication block); 20% typically needs expansion; 30% often resolvable at 12 |
| active time per accepted outcome | 15% / **20%** / 30% | as above; timing variance is high |
| weighted accepted value per resource | 10% / **20%** / 30% | weighting adds variance; 10% unrealistic at this scale |
| human minutes per accepted outcome | 25% / **33%** / 50% | highly dispersed; small thresholds not resolvable here |
| consistency (CV reduction) | 20% / **25%** / 33% | dispersion-of-dispersion needs the larger n; often directional-only at 12 |

**Claim ladder (frozen):** *directional* claim = 95% interval excludes zero.
*Practical-magnitude* claim = interval excludes zero AND point estimate ≥
SESOI (stronger optional standard, available to the owner: interval lower
bound ≥ SESOI). *Inconclusive* = interval spans zero at n_max — recorded as
inconclusive at this scale, no rescue, no re-litigation; the next legal step
is a preregistered replication block, not more of the same sample.

**Phase allocation — the staged gate (no tiny cells):** the study answers
the PRODUCT question first: all pairs run as a natural work sequence, each
arm accumulating its own ordinary state, and the primary metrics are
computed over ALL pairs — the estimand is "the system as actually operated
over a body of work." Cold-start vs accumulated-state decomposition is
SECONDARY and descriptive at this n (early-position vs late-position split,
reported with intervals but not gated). Mechanism decomposition becomes its
own powered comparison only in the optional stronger configuration or a
dedicated follow-up — 6/6 cells pretending to power both phases in one
economical study is exactly what this design refuses to do.

**Milestones:** n=3 milestones are **corroborating product evidence**: an
existence proof at end-to-end scale under blinded acceptance. 3/3 in one
direction is a sign-test p=0.125 — stated plainly, no precision pretended.
Milestones can CORROBORATE or UNDERMINE the paired result; they cannot
independently establish consistency.

## B. Operator-learning design (single operator, strongest affordable)

The treatment is the SYSTEM (arm A vs arm B). The human operator is
infrastructure, held constant and protocolized — never part of the
treatment. Design:

- **Frozen task capsules:** task statement, context pointers, and the
  behavioral acceptance script sealed per task before any run; the operator
  relays the capsule and may act only within the frozen intervention
  decision list. Everything else the operator says or does is an
  intervention, logged and metered.
- **Paired randomized counterbalanced order:** within each pair, arm order
  randomized under the constraint that AB/BA counts balance per block of 4.
- **Washout:** ≥4h (PROPOSED) or an unrelated distractor task between the
  two arms of the same pair — meaningful because the operator carries
  solution knowledge from the first arm's run; washout reduces recall
  advantage but cannot remove it, which is why order is counterbalanced and
  analyzed.
- **No cross-arm work-product visibility:** separate clones, separate
  terminals/sessions; the operator never opens arm X's diff while running
  arm Y.
- **Order/period analysis:** first-run-vs-second-run within pairs reported;
  a material period effect is a finding about the design, disclosed, not
  absorbed.
- **Second-operator audit (low-cost, PROPOSED default 4 pairs):** a randomly
  selected blinded subset re-run end-to-end by a second operator with the
  same capsules. What it CAN validate: that the protocol is executable by
  someone else; that effect DIRECTION on those pairs is not
  operator-specific; that intervention rates are comparable. What it CANNOT
  validate: effect magnitude generalization, operator×system interaction at
  scale, or anything about pairs outside the subset.
- **Retained limitation, prominent:** this remains a single-operator study
  with an audit, not a multi-operator study. The limitation is carried into
  every claim statement; it is mitigated, not solved.

## C. Recommended configurations

**Minimum credible (PROPOSED):** qualification run → stage 1 (12 pairs,
natural sequence, ITT, blinded acceptance) → blinded precision assessment →
expansion only if triggered (≤24) → 3 milestones → report. Buys: the product
answer on one repo with interval-grade evidence at moderate SESOI, milestone
corroboration, prominently-scoped limitations.

**Stronger (optional):** adds the second-repo replication block (stage-1
scale) → unlocks general product claims per the claim gates; adds the
4-pair second-operator audit → operator-generalization spot-check; adds a
dedicated powered cold-start block ONLY if the mechanism question is worth
its own budget after the product answer lands.

## D. Cost/evidence ladder (each block's marginal purchase)

| Block | Approx cost (arm-runs) | What it buys | What it cannot buy |
|---|---|---|---|
| 1. Qualification | ~4–6 | frozen invalid-run rate holds; telemetry proven | nothing about the product question |
| 2. Stage 1 (12 pairs) | 24 | directional answer + intervals; large effects resolved | practical-magnitude claims at small SESOI |
| 3. Expansion (→24 pairs) | +24 | interval width ×~0.7; moderate SESOI resolvable | generalization beyond repo/task family |
| 4. Three milestones | +6 large | end-to-end existence proof, blinded; corroboration | consistency inference (n=3, sign-test p=0.125) |
| 5. Second-repo replication | +24 | general product claims (per claim gates) | domain-universal claims |
| 6. Second-operator audit (4 pairs) | +8 | protocol executability; direction not operator-specific | magnitude generalization across operators |

## E. Owner decision table (defaults PROPOSED, not chosen)

| Decision | PROPOSED default | Alternatives |
|---|---|---|
| n₁ / n_max / block | 12 / 24 / 4 | 8/16/4 (cheaper, weaker); 16/32/4 (stronger, slower) |
| SESOI per metric | bolded column in table A | owner-selected per metric |
| Practical-claim standard | point ≥ SESOI + interval excludes 0 | lower bound ≥ SESOI (stronger) |
| Washout | ≥4h or distractor task | ≥24h (slower, stronger) |
| Audit subset | 4 pairs | 0 (weaker) / 8 (costlier) |
| Milestones | 3 | 3 is the floor per rev 2 |
| Phase decomposition | descriptive at this scale | dedicated powered block later |
| Sequence | qualification → stage 1 → precision gate → (expansion) → milestones → (replication) → (audit) | reorder replication earlier if generalization outranks precision |

## F. Execution-readiness

Apart from owner choices, three genuine gaps remain, all buildable
post-EXP-0011 and none affecting the design's logic: (1) the behavioral
acceptance tooling is repo-dependent and cannot be specified until the
repository is chosen; (2) a small human-minutes metering tool (intervention
logger) must be built and included in the qualification run; (3) the task
capsule format needs a one-page spec at freeze. With those three plus the
owner decisions, the design is execution-ready. The single-operator
limitation and one-repo scope remain material and are carried prominently
into every claim the study can emit.
