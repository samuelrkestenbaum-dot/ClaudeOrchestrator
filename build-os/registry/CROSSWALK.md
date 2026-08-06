# Build OS — the Neurocosmology crosswalk

`control_registry.txt` answers *what kind of evidence is this control, and how
much authority does it exercise?* This crosswalk answers the second question
every control should be able to answer: **what universal function does it
instantiate?**

`neurocosmology_crosswalk.txt` binds each of the registered controls to
exactly one of **17** primitives, and records for each primitive what the
bindings *miss*. `tests/neurocosmology_crosswalk_tests.sh` reconciles it against
the census in both directions and refuses drift.

**This is classification only.** It implements no mathematics, creates no
control, and grants no authority. There is no Φ here, no coherence measure, no
goal ecology, no value-of-information term and no learned model — deliberately,
because a conceptual equation must not control production before its quantities
are computable. Every `class` and `runtime_authority` in the crosswalk is a
**copy** of one the registry already recorded, and where the two disagree the
registry is right.

---

## 1. Why a second file, and not a field on each control record

The obvious alternative was an eighteenth field on each registry
record. It was rejected on four grounds, three of which the registry's own
`README.md` §1 already argues.

1. **A census must not be edited by an interpretation.** The registry classifies
   *what runs*. A binding asserts *what universal function a control serves* —
   a far more contestable judgement. Putting a contestable claim inside the
   record invites the failure README §3 already names in another direction: an
   author adjusting a control's registry entry so the crosswalk comes out tidy.
   Kept separate, the crosswalk can be wrong without corrupting the census.
2. **The cardinality does not fit.** The crosswalk's load-bearing field,
   `known_limitations`, is **per primitive** — 17 of them — not per control.
   It has no home in a control record, so a second store was needed regardless;
   the only real question was whether to *also* denormalise a `primitive:` field
   into the census, which buys nothing and costs one record edit per control.
3. **The census schema is pinned.** `tests/control_registry_tests.sh` fixes the
   17 field names exactly. An eighteenth would mean loosening that guard for a
   non-census reason.
4. **Redundancy is what makes drift detectable.** Each binding restates its
   control's `class` and `runtime_authority`. That copy is deliberate — the same
   device as `lanedecl.threshold_pinning` and `gatedepth.sentinel_drift`, and the
   same reasoning the registry suite uses when it duplicates the enums "ON
   PURPOSE". One statement cannot drift; two must agree, and §6 of the suite
   fails them when they do not.

The format is the registry's own: **one field per line, one blank line between
records**, two record shapes (`primitive:` and `control:`). That keeps it
greppable without a parser, diffable at field granularity, and readable by an
agent with no tooling. Counts are **derived, never stored** — the §25 lesson,
where the same total was frozen by hand in three artefacts at three different
values. The one number the artefact *does* assert, `claimed_max_authority`,
exists precisely so that §7 can falsify it.

---

## 2. Coverage

`bound` counts every binding. `inst` counts only `instantiates` — a control that
performs the function. **`inst` is the honest column.** `proxy` observes a
stand-in whose gap is named in the primitive's `known_limitations`; `nom` touches
the concept without performing the function and **is not coverage**.

| primitive | bound | inst | proxy | nom | classes | authorities |
|---|---|---|---|---|---|---|
| reachability | 1 | 0 | 0 | 1 | B | advise |
| meaning_metric | 0 | 0 | 0 | 0 | — | — |
| mass | 1 | 0 | 0 | 1 | A | advise |
| valence | 0 | 0 | 0 | 0 | — | — |
| agency | 17 | 12 | 4 | 1 | A, C | advise, gate, execute |
| energy | 5 | 0 | 5 | 0 | A, C | advise, gate |
| homeostasis | 49 | 1 | 48 | 0 | A | advise, gate |
| integration_bandwidth | 6 | 1 | 5 | 0 | A, C | advise, gate |
| boundary | 18 | 0 | 18 | 0 | A | advise, gate |
| ethical_admissibility | 2 | 1 | 0 | 1 | A | gate |
| epistemic_quality | 59 | 19 | 39 | 1 | A, B, C | advise, gate |
| latent_state | 6 | 4 | 2 | 0 | A, C | advise, gate |
| durability | 2 | 0 | 2 | 0 | A | gate |
| gated_plasticity | 6 | 4 | 2 | 0 | A, B, C | advise, gate |
| collective_coherence | 5 | 4 | 1 | 0 | A, C | gate |
| goal_ecology | 1 | 0 | 1 | 0 | C | observe |
| wisdom | 1 | 0 | 0 | 1 | C | advise |

The split across kinds, and how many primitives hold even one *instantiating*
binding, are **not restated here** — they were, and they went stale the moment
the census grew. Derive them:
`grep -c '^binding_kind: instantiates' neurocosmology_crosswalk.txt` and the
honest-coverage recipe in that file's header. Every cell in this table —
the four counts *and* the `classes` and `authorities` columns — is recomputed
from the artefact by §10 of the suite and fails on drift; nothing in it is
maintained by hand.

**These numbers got worse on review, which is the direction that indicates the
instrument works.** The first draft read 32 / 36 / 3. Eight bindings were then
demoted — five from `instantiates` to `proxies`, three from `proxies` to
`nominal` — not because new evidence arrived, but because in every one of the
eight the *label* disagreed with the entry's own `known_limitations`, which had
already conceded the gap. That is precisely the defect this crosswalk exists to
catch, found inside the crosswalk itself: the optimism sat in the label and
never in the disclosure. The demotions took `boundary`, `durability` and
`energy` to **zero instantiating bindings**, and made `reachability` and
`ethical_admissibility` **nominal-only** alongside `mass` and `wisdom`.

**Two thirds of the crosswalk sits in two primitives.** `epistemic_quality` and
`homeostasis` hold more than half of all bindings between them — read the two
rows above rather than a number restated here. That concentration is the honest result,
not a tidy one, and it says something plain: this system is overwhelmingly built
to *check whether an artefact is sound* and *whether the tests still pass*.

---

## 3. The empty primitives — the finding

Two primitives have **zero** bound controls — the rows reading `0` in the table
above are the authority, not this sentence. A primitive with nothing bound to
it is not a gap in the crosswalk; it is a gap in the product, stated in the
framework's own vocabulary.

- **`meaning_metric`** — nothing represents which futures matter. Acceptance
  criteria exist in quantity, but an acceptance criterion is a *binary predicate
  over an artefact that already exists*, and a meaning metric is a *measure over
  futures*. Every control in the census can say "this is wrong" and none can
  say "this is worth more than that".
- **`valence`** — nothing computes benefit, harm, expected loss or user impact.
  `defects_gated` counts caught harm; a typo and a data-loss bug increment it
  identically.
**`goal_ecology` was the third, and it is the one that moved in this round.** It
was recorded here as empty on the ground that *"no control weighs two objectives
against each other at runtime"*, and `ranker.s1_shadow_ordering` — S1, the
shadow ranker — now does. **It PROXIES, and the shortfall is the point:** it
orders on three objectives (recorded debt discharged, whether a standing ruling
assigns the work, how much census the work grows) and names six more — cost,
energy, recurrence, counterfactual regret, outcome quality, human attention — as
**NEVER-COLLECTED** in its own output rather than defaulting them. The frozen
trades are still frozen: the lane table trades speed against scrutiny, the depth
budget trades wall-clock against serial gates, the skill budget trades
capability against context, each resolved once by a human and written down as a
constant, and a constant is the *result* of a balance, not the act of balancing.
What is new is one control that performs the act, at `observe`, on an admittedly
partial signal set, with **all weights equal by declaration** — so the trade-off
it applies is assumed rather than discovered.
**`integration_bandwidth` was the fourth, and it is the one that moved.** It was
recorded here as empty and *not predicted*: the system had four bandwidth
conventions — one active packet, ≤2 commits, a bounded fix round, a median depth
of 2 serial stages — and **not one was a registered control**. Two of the four
now are, and the other two are **declined out loud rather than left implied**:

- **Built.** `bandwidth.active_packet_singleton` refuses a second declared packet
  (`gate`, Class C, **mismatch declared**). It was registered Class A, on the
  argument that its ceiling is `active_packet.md`'s own definition rather than a
  fitted number, and **demoted on review**: "one packet at a time" is not in
  `CLAUDE.md` at all, only in the prose header of the file the control reads, so
  it is a WIP limit somebody chose. `MISMATCHES.md` §14 carries the argument.
  `bandwidth.packet_commit_ceiling` counts commits against the
  packet's declared base and **advises** (`advise`, Class C — two is a constant
  the working contract chose, and a heuristic does not become a gate by being
  useful).
- **Declined, with the reason recorded.** *Depth* is **transcript-only**: nothing
  in git attests to how many agent passes ran in series, so no ceiling is
  implemented and none is claimed. *Open write sets* are observable from a
  fan-out manifest, but **no ceiling on their number is declared anywhere**, so
  enforcing one would mean inventing a constant.
- **Each dimension is enforced separately.** There is no composite load score.
  Weights nobody can derive would be unjustifiable, and a single number hides
  *which* capacity is saturated — so every ceiling carries its own authority and
  every refusal names its dimension.

### The prediction, tested

The prediction was that the **valuation half** — `meaning_metric`, `mass`,
`valence`, `goal_ecology`, `wisdom` — binds to nothing, because `rank` is empty
and nothing here orders or selects.

**The mechanism was confirmed exactly, and it has now partly given way.**
`runtime_authority: rank` — the tier that exists to order work or select between
options — is still held by **zero** controls. `observe` is no longer empty: S1
holds it, and the ladder is used at four rungs of six rather than three. Derive
the split rather than trusting a number here —
`awk -F': ' '/^runtime_authority: /{print $2}' control_registry.txt | sort | uniq -c` —
because the restated version of this sentence had already gone stale twice.
**The rung that matters for the prediction is `rank`, and it is still empty:**
S1 ORDERS but is licensed only to be watched, and nothing in this repository
reads its ordering.

**The "every one answers yes/no about an artefact that already exists" half of
this finding is no longer true, and the exception is worth naming rather than
smoothing over.** `bandwidth.active_packet_singleton` answers *is there room for
more* — it limits what may be absorbed instead of judging what already landed —
and it is the only entry in the census that does. That does not touch the
valuation claim below: limiting intake is still not ordering, and nothing here
has gained the ability to say that one option is worth more than another.

**Two of the five are empty; two carry a single nominal binding and neither
survives a strict reading; and the fifth — `goal_ecology` — now carries one
PROXY binding, which is the first crack in this half of the prediction.**

- **`mass`** ← `metrics.report.disclosure_ordering`. This is the *only* ordering
  of anything in the census, and it takes `inputs: none`: a fixed section order a
  human chose once, putting the caveat above the numbers. The system orders
  exactly one thing, a page layout, by constant.
- **`wisdom`** ← `hooks.prompt_router`. The only control that *selects* rather
  than judges: it reads prompt text and names a lane. But it classifies by
  keyword, is `unvalidated`, exits 0 on every path, is enforced by nothing, and
  receives **no outcome feedback**, so it cannot be regret-aware in any sense.

- **`goal_ecology`** ← `ranker.s1_shadow_ordering`. Not nominal: it really does
  weigh three objectives against each other and publish the decomposition. But
  it weighs three of seven, its weights are equal by declaration rather than by
  measurement, it receives no outcome feedback either, and it holds `observe` —
  so it can be watched and can change nothing.

So the counter-evidence is real but thin, and it sharpens rather than overturns
the claim: the valuation half is still almost empty of *function*, the two
nominal bindings mark where a function would attach if one were ever built, and
the one binding that is not nominal orders work that nothing is obliged to do in
that order.

---

## 4. Where the `bound` count most overstates the function

The distinction that decides whether this crosswalk earns its place. Note that
`nominal` is a **machine-checked term** in this file — a binding that touches
the concept and *is not coverage* — so it is never used below as loose English
for "in name only". Ranked by how badly the `bound` column overstates `inst`:

1. **`homeostasis` — 24 bound, 1 instantiating.** The worst overstatement in the
   table. Nineteen of the twenty-four are *test suites*, and a suite's empirical
   status is `red_driven`: a check written against a fixture written by the same
   author in the same hour mostly proves the two agree. A green suite is evidence
   that **planted** defects are caught, not that the system is healthy. There is
   no runtime health signal here at all, and **nothing observes the system while
   it operates** — every binding is a pre- or post-condition around a run, never
   a state variable during one.
2. **`ethical_admissibility` — 2 bound, 1 instantiating.** It came off
   nominal-only in this packet, and the move is smaller than it looks: the one
   instantiating binding scans **twelve named files**, not the tree, and the
   rule that matters most is still enforced entirely outside the census. See §5;
   still the sharpest finding in the file.
3. **`boundary` — 4 bound, 0 instantiating.** Every boundary in the census is
   *detective*: it hashes before and after and names what changed, so the
   prohibited write lands and is then reported. See §5, which also records the
   counter-argument.
4. **`reachability` — 1 bound, 0 instantiating, and the one binding is
   `nominal`.** An *inventory*, not a graph.
   `hooks.session_capability_report` lists capability names and honestly marks
   the uncertain ones `CANDIDATE` — a list of nouns where the primitive needs a
   structure over verbs. No affected-state graph, no plan DAG, no executable-path
   set exists anywhere in the system.
5. **`energy` — 3 bound, 0 instantiating.** Two of the three treat wall-clock as
   a stand-in for capacity, which cannot distinguish a run that is slow because
   it is thorough from one that is slow because it is stuck. The one real
   accounting, `tools.skill_budget_audit`, **exits 0 when over budget**, so the
   only control that measures capacity cannot act on its own measurement — it
   reports capacity rather than governing it, which is a proxy and not an
   instance.
6. **`durability` — 1 bound, 0 instantiating.** The single binding conserves
   bytes across one *transformation* and touches **none** of the five
   representations the primitive declares. See §5.
7. **Three primitives are `nominal`-only** — `reachability`, `mass` and
   `wisdom`. Their one binding apiece is information about the concept, and by
   this file's own rule it is **not coverage**. Read them as empty.
   `ethical_admissibility` was the fourth until this packet.
8. **`integration_bandwidth` — 6 bound, 1 instantiating,** and the proxy is a
   proxy for the same reason `tools.skill_budget_audit` is: it measures the
   quantity and then exits 0, so the number it produces cannot bind the thing
   that produced it.

By contrast, the primitives whose bindings genuinely do the work are
**`gated_plasticity`** (4 of 6 instantiating), **`collective_coherence`** (4 of
5), and **`latent_state`** (4 of 6).

---

## 5. The `known_limitations` that matter most

**`ethical_admissibility` — the census can now see its egress scan, and is still
blind to its own hardest rule.** Both halves matter and the second is the larger.

*What changed.* The egress scan — the check that keeps *local only, no telemetry*
falsifiable rather than asserted — used to live **inside** `suite.entitlement`
and own no entry of its own, so the census's only view of it was that suite's
`RESULT` line plus its own vacuity floor: the registry could see *this scanner is
not blind* and could never see *nothing performs egress*. It is now
`entitlement.egress_scan`, Class A, `gate`, `red_driven` on the strength of a
planted-`curl` positive control and a prose negative control that run on every
pass. It **instantiates** the primitive rather than proxying it, because unlike
every binding under `boundary` the prohibited *act* never occurs — only the code
that would perform it, and that code cannot land while the suite is chained. That
closes README §4's known hole #1, *"a new control added inside an
already-registered file"*, **for the one instance that motivated the
disclosure** — the hole itself is structural and remains open.

*What did not change, and must not be read as having changed.* The strongest rule
this system states about itself — *no external mutation without explicit go:
never push, merge, deploy, publish or touch secrets* — still has **zero
registered controls**, and this control is not one of them. It scans a
twelve-file fileset for egress patterns; that is all it does. The rule is
enforced by the operator's **permission system**, a process boundary outside this
repository, and that is the right place for it: anything that could bypass the
permission system bypasses a repo-side check trivially, so a repo-side gate would
convert a real external boundary into a checkbox that looks enforced and is not.
**This primitive's strongest enforcement lives outside the census, and the census
remains blind to it.** The scan's own scope is the second limit: twelve named
files from one packet, so egress introduced anywhere else in the tree is
invisible to it.

**`epistemic_quality` — 29 bindings, 14 instantiating, and the count overstates
the contact.**
Roughly three quarters of the census is `red_driven` and only **3** entries are `field_observed`. The
bindings divide sharply. A small group compares a claim against something the
claimant did not write — `metrics.record.verify_git` against git numstat,
`adoption.lane_size_check` against measured churn, `registry.discovery_rule`
against the tree — and these genuinely instantiate the primitive. The larger
group checks **shape**, **occupancy**, **length** or **vacuity**:
`adoption.boundary_manifest` validates that a manifest is well-formed and not
that the boundary it declares is true, `metrics.record.note_minimum` passes
twelve repeated characters,
`adoption.junk_row_thresholds` scores a row of plausible fabrications as full,
and seven separate "the scan found nothing" refusals prove only that a check was
not blind — necessary for evidence, never sufficient. One binding,
`maint.tripwire_coverage_scan`, is registered `refuted`: measured, and found not
to discriminate. Reading this primitive's binding count as dense epistemic coverage would be exactly
the overclaim this registry exists to prevent.

**`boundary` — every boundary here is detective, not preventive, so 0 of 16
instantiate.** The tripwire and the shell fingerprint both work by hashing
before and after and naming what changed, so the prohibited write **happens**
and is then reported. That is worth having — `maint.real_memory_tripwire` is
`field_observed` against a real suite that destroyed live memory at exit 0 — but
a boundary that constrained reachable futures would refuse the write. **The
counter-argument is real and is kept rather than discarded:** both are `gate`,
so the offending change cannot *land*, and the boundary is genuinely enforced —
at **commit** granularity, not at **write** granularity. That is why they
`proxy` the primitive rather than failing to touch it, and it also sizes the
gap exactly: whatever happens between the write and the commit is outside the
reach of every boundary control in the census.

**`durability` — the instrument exists and is empty, and 0 of 2 instantiate.**
Two bindings, and the elder of them measures conservation across a single *transformation*, not
across *time*. It touches **none** of the five representations the primitive
declares — not D₁/D₇/D₃₀/D₉₀ retention, not rollback, not rework, not escaped
regressions.
`packet_metrics.tsv` carries a `defects_escaped` column and it reads `-` in
**all 6 of 6 rows**: the system built a place to record escaped regressions and
has never recorded one. Nothing computes D₁/D₇/D₃₀/D₉₀, nothing measures rework,
and `rollback_behavior` is a prose field on every entry that no control ever
executes or verifies.

**`collective_coherence` — coherence is enforced as non-collision.** All five
bindings reason over *file paths*. Two agents editing disjoint files can hold
contradictory beliefs, implement incompatible designs, or duplicate each other's
work entirely, and every one of these controls passes them without comment.

---

## 6. What this crosswalk is deliberately NOT

It is not a plan, not a roadmap, and not a proposal to build the empty
primitives. Naming `valence` as empty is **not** an argument that Gravito should
compute valence; it is a statement that if anyone claims Gravito operationalizes
valence today, the census contradicts them. The registry exists to make the
current state legible enough for the operator to decide what is worth building.
This file extends that legibility by one axis and stops there.

Pinned by `tests/neurocosmology_crosswalk_tests.sh`.
