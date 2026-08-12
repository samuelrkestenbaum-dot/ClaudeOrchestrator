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
empathiq-website), 10–20 independently selected matched task pairs, plus **at
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
