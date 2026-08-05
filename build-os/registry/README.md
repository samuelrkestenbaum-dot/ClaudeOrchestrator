# Build OS — control registry

`control_registry.txt` declares, for every consequential control that already
runs in this repository, what kind of evidence it is, how far along it is, what
has actually been observed about it, and **how much authority it exercises
today**. `MISMATCHES.md` lists the controls exercising more authority than their
class licenses. `scan-controls.sh` reconciles both against the tree and refuses
when they disagree.

**This is a census, not a plan.** Nothing here is a proposal to build a new
control, and nothing here re-authorises an existing one. Changing what authority
a control exercises is a governance action and belongs to the operator; the job
of this directory is to make the current state legible enough that the operator
can decide.

---

## 1. Why a stanza file and not a TSV, a table, or JSON

`packet_metrics.tsv` was argued into TSV because its cells are short — a lane, a
date, ten integers — so a tab-separated line stays readable by `cut`, by an
agent and by a human, and diffs cleanly. **This artefact is the opposite shape.**
Each record carries seventeen fields, and eight of them are prose: what a control
observes, what it does on failure, what it would take to promote or demote it. A
seventeen-column TSV of prose is a 600-character line that no one reads and that
`git diff` reports as one changed line whatever moved inside it. A markdown table
is the same object with pipes. JSON is not line-greppable, and its diffs are
noisy in exactly the field-level way this file needs to be quiet.

So the store is **one field per line, one blank line between records**:

```
control: adoption.lane_size_check
class: C
runtime_authority: gate
...
```

That buys the same four properties the TSV was chosen for, at this shape:

- **Greppable without a parser.** `grep '^class: C' control_registry.txt` counts
  the heuristics. `grep -B4 '^runtime_authority: gate'` finds what gates.
  `grep -c '^control: '` is the census size. The number worth reading first is
  **`gate` on `unvalidated` evidence — 11 of 97**: eleven controls can stop the
  build and nothing has established that any of them discriminates. The one-line
  `awk` that derives it is in `control_registry.txt`'s header.
- **Diffable at field granularity.** Changing one control's authority is a
  one-line diff, and a reviewer sees exactly which field moved.
- **Readable by an agent that has no tooling.** It is `key: value` lines. There
  is no schema to fetch, no quoting rule, and no escape sequence.
- **Machine-checkable.** `scan-controls.sh` flattens it in twenty lines of bash
  and refuses anything ragged, so the format cannot rot into free text.

The one cost, stated: a field value may not contain a newline. Long prose lives
on one long line. That was judged cheaper than any quoting rule, because a
quoting rule is the thing that stops an agent being able to read the file
without a parser.

---

## 2. The ontology

### ControlClass

| class | name | what it means |
|---|---|---|
| `R` | research functional | a mathematical object under investigation. Not a production control. |
| `A` | hard invariant | a property that must hold. A violation is a defect, not a preference. |
| `B` | deterministic metric | a number computed reproducibly from observable state. |
| `C` | heuristic policy | a rule, or a threshold, chosen by judgement or fitted to a small sample. |
| `D` | learned model | a control whose behaviour was fitted from data. |

### ImplementationStatus

`specified` → `implemented` → `runtime_observed` → `decision_contributing` →
`load_bearing`.

**A metric is not load-bearing merely because it is implemented.** It is
`load_bearing` only when a live policy consumes it, its result changes behaviour,
and removing it changes outcomes. Every entry claiming `load_bearing` must name
that policy in `consuming_policies`; `scan-controls.sh` refuses one that does
not.

### EmpiricalStatus

Comma-separated; more than one may hold.

| value | what it means |
|---|---|
| `unvalidated` | nothing has established that it discriminates. |
| `red_driven` | it has been shown to fire on a synthetic defect written to trip it. |
| `field_observed` | it has fired on a real defect that nobody planted. |
| `calibrated` | its thresholds were derived from a measured distribution. The sample size belongs in `notes`. |
| `refuted` | it was measured and found not to discriminate. |

`red_driven` is the ordinary state in this repository and it is weaker than it
looks: a check written against a fixture written by the same author, in the same
hour, mostly proves the two agree.

### RuntimeAuthority

`none < observe < advise < rank < gate < execute`

| value | what the control may do |
|---|---|
| `none` | it has no runtime output and no consumer. |
| `observe` | its output may be recorded and **consumed for visibility**. It causes **no operational consequence**. |
| `advise` | its output may influence a human, or a higher-authority control. |
| `rank` | its output may order already-permitted alternatives. |
| `gate` | its output may allow or prohibit. **In this repository, a control that exits non-zero is exercising `gate`, whatever its author called it.** |
| `execute` | its output may **directly cause mutation** — it changes the world rather than permitting a change. |

**The ladder measures CONSEQUENCE, not consumption.** This is a correction, and
the reason it was needed is worth keeping. `none` and `observe` were *both*
formerly defined by **non-consumption** — the one saying nothing consumed the
output, the other saying nothing read it — so the ladder had **no rung meaning
"it is read, but it may cause nothing"**. That is exactly the state
a control must occupy when the evidence axis caps it at `observe` while other
controls still read it, so the cap `refuted → observe` could be *stated as a
finding and never written as a row*: it was foreclosed for **67 of 81**
controls, and **0** sat there. Redefining `observe` by consequence makes the cap
a **legal destination** instead of an unreachable instruction. It moves no cap
and re-authorises nobody.

**`execute` is a rung, not a licence.** It exists so that a control which
*directly mutates* is distinguishable from one that merely *prohibits*; `gate`
stops a run, `execute` changes state. **No class licenses it** — the table in §3
is unchanged, Class A still reaches `gate` — so adding the rung grants nobody
anything. Whether Class A *should* license `execute`, and which currently
`gate`-registered controls actually perform writes, are **governance questions
recorded for the operator and deliberately not answered here.**

**What the correction COST: the `observe`/`advise` boundary is now INTENT-BASED,
and it used to be mechanically checkable.** Stated here rather than implied away,
because omitting it would be an asymmetry in the direction that flatters the fix
— this file's own phrase, turned on this file. Three rungs carry a test any
reader can run against the tree: `gate` is *"exits non-zero"*, `execute` is
*"performs a durable write"*, `none` is *"names no consuming policy"*. `observe`
used to carry one too — **non-consumption is greppable**, and `OBSERVE-LB` was
built out of exactly that grep. Defining the rung by **consequence** removes it:
nothing in this repository can decide from the source whether a consumer's use of
an output is *visibility* or *influence*, so the line between `observe` and
`advise` now rests on the registering author's assertion. **Three of the six
rungs are separated by assertion rather than by measurement.** That was the right
trade — the checkable boundary is exactly what made the rung unreachable, and a
mechanical test that forbids the only legal destination is worse than a judgement
that permits it — but it is a real loss of enforceability and not a free
redefinition. What remains mechanical is the **surrounding** claim: a control at
`observe` whose removal changes outcomes is still reported, now on the advisory
channel, because *"removing it changes outcomes"* is a consequence claim and the
two cannot both be true.

### nervous_system_role

| value | what the control is, structurally |
|---|---|
| `sensor` | it turns state into a number or a fact. |
| `reflex` | it fires automatically on a condition, without deliberation. |
| `immune` | it detects damage or intrusion, usually after the fact. |
| `memory` | it records state for later. |
| `conscience` | it reports a judgement to an agent that decides. |
| `motor` | it changes the world. |

---

## 3. The licence table, and the one thing that must not happen

A control's class fixes the highest authority it can claim **on its own merits**:

| class | licensed authority |
|---|---|
| `A` hard invariant | `gate` |
| `B` deterministic metric | `rank` |
| `C` heuristic policy | `advise` |
| `D` learned model | `observe` |
| `R` research functional | `observe` |

Two of those lines carry the whole argument:

- **A deterministic metric does not automatically become a gate.** Turning a
  number into a stop is a policy decision. The number's reproducibility is not
  the same as the stop's correctness.
- **A heuristic does not become a gate by being useful.** A threshold fitted to
  four packets of this repository's own history is a heuristic whether or not it
  has caught something. Usefulness is evidence for keeping it; it is not a
  licence.

Exceeding the licence is **not forbidden here**. Several controls in this
repository do exceed it, they are load-bearing, and removing their authority
would make the system worse. What is forbidden is exceeding it *silently*. An
over-authorised control must set `authority_mismatch: declared` and appear in
`MISMATCHES.md` with the line that gates.

**Do not clear a mismatch by changing the class.** Relabelling a heuristic as an
invariant so the registry looks clean is the exact failure this artefact exists
to prevent. Changing the *authority* is a governance action for the operator.
This is **enforced**, not merely stated: `scan-controls.sh` section 8 reads the
summary table in `MISMATCHES.md` back and requires every control named there to
still carry `authority_mismatch: declared`. Until that check existed the rule was
a sentence in a header — relabelling `tools.supervise_timeout` `class: A` cleared
its mismatch at exit 0, silently, while the report went on naming it.

**An entry is not a line.** Entries are cut at different granularities:
`metrics.record.note_minimum` classifies one comparison, and
`tests.nonvacuity_minimums` classifies a family of 34 fitted constants across 12
test files. So "20 of 97 declare a mismatch" is a fact about this file's
granularity, not a count of the heuristics that can stop a build — that number is
**56**, in `MISMATCHES.md`'s summary table. The family's membership is not
trusted: `tests/control_registry_tests.sh` §21 rescans the tree for the shape and
fails if the entry and the tree disagree in either direction, and §22 fails if
any `path:line` is ever claimed by two entries.

### 3a. The second axis: evidence

The table above is **one-dimensional**, and that is a hole rather than a
simplification. It licenses on `class` alone, so a control's `empirical_status`
— whether anybody ever established that the check **works** — licenses nothing
and forbids nothing. Under it, a control that was **measured and found not to
discriminate** may stop a build and no rule here objects. That is not a
hypothetical: the census records `refuted` controls, and one of them gates.

So there is a second axis. It **extends** the table above; it does not replace or
contradict it. The class column is settled and is copied unchanged into
`build-os/tools/evidence-policy.sh`, where
`tests/evidence_policy_tests.sh` §4 reads it back **out of this section** and
fails on any disagreement — the new axis cannot restate the old one differently
and call the difference policy.

| `empirical_status` | licensed authority | why that level |
|---|---|---|
| `calibrated` | `gate` | thresholds derived from a measured distribution. |
| `field_observed` | `gate` | it has fired on a real defect nobody planted. |
| `red_driven` | `gate` | it has been shown to fire on a synthetic defect. |
| `unvalidated` | `advise` | nothing has established that it discriminates. |
| `refuted` | `observe` | it was measured and found **not** to discriminate. |
| `untested` | `observe` | it has **never operated** against a live or representative task. |

**The composition rule, stated explicitly:**

> **`licensed = MIN(class-licensed, evidence-licensed)`** over the authority
> ladder `none < observe < advise < rank < gate < execute`. A control may do what
> **both** axes allow, and no more.

The minimum, and not an average or a product, because the two are independent
**necessary** conditions: being the right *kind* of thing to gate does not make a
broken check work, and a working check does not make a chosen threshold an
invariant. Either failing is disqualifying on its own, and the minimum is what
that looks like arithmetically. The composed table:

| class \ evidence | `calibrated` | `field_observed` | `red_driven` | `unvalidated` | `refuted` | `untested` |
|---|---|---|---|---|---|---|
| `A` hard invariant | `gate` | `gate` | `gate` | `advise` | `observe` | `observe` |
| `B` deterministic metric | `rank` | `rank` | `rank` | `advise` | `observe` | `observe` |
| `C` heuristic policy | `advise` | `advise` | `advise` | `advise` | `observe` | `observe` |
| `D` learned model | `observe` | `observe` | `observe` | `observe` | `observe` | `observe` |
| `R` research functional | `observe` | `observe` | `observe` | `observe` | `observe` | `observe` |

**A comma-composite `empirical_status` resolves by MINIMUM** — the weakest
component governs. That is conservative in general, and in the one case that
matters it gives the honest answer without needing a timestamp this format does
not carry: **`refuted` dominates a `red_driven` that preceded it**, because a
later refutation *supersedes* an earlier red drive. The opposite reading — "it
red-drove once, so it is fine" — is how a measurement that found nothing gets
outvoted by the measurement that corrected it. So `red_driven,refuted` licenses
exactly what bare `refuted` licenses.

Four of those rows carry the argument:

- **`untested` caps at `observe`, below `unvalidated`.** The two are genuinely
  different and the difference is not a nuance: `unvalidated` has **operated**
  and its outcome evidence is inadequate, while `untested` **has never run**.
  "Nobody checked the result" and "there is no result" are separate claims, and
  the second is weaker, so it caps lower. `observe` and not `none`, because
  `none` means nothing consumes the output at all, whereas a check that runs and
  is read while being allowed to cause nothing is exactly what `observe` was
  redefined to mean. **Adding this token widened the axis and granted nobody
  anything** — no control in the census carries it, the composed table above
  gains a column of `observe`, and the unknown-token refusal is untouched. The
  test of whether it was fitted to a case rather than to the ontology is what it
  does to **S1**, which is slated to arrive carrying it: it makes S1 **more** out
  of licence, not less.
- **`refuted` may not `gate`, regardless of class.** This is the sharp rule, and
  the only one here that resolves a real defect *mechanically* rather than by
  judgement. A control empirically shown not to discriminate cannot license a
  stop, and **class cannot rescue it**, because class is a claim about the KIND
  of thing being checked while evidence is a claim about whether the check WORKS.
  A hard invariant whose test does not detect violations is not a hard invariant
  with good paperwork; it is an unchecked invariant. It caps at `observe` rather
  than `advise` for a further reason: presenting a signal *known* not to
  discriminate to a decision-maker who cannot see that it is dead is worse than
  recording it and letting nothing read it. `observe` keeps the measurement, so a
  later re-validation has history to work from, without letting anything act on
  it.
- **`unvalidated` caps at `advise`.** The expensive rule. `advise` and not
  `rank`, because `rank` lets a control order work or select between options with
  **no human in the loop**: an unverified signal silently choosing what happens
  next differs from an unverified signal stopping a build only in how loudly it
  fails. `advise` is the highest rung that keeps a person between the unverified
  number and the consequence, which is exactly the guarantee "nobody has checked
  this" requires. This is the rule that costs: it puts every gate-on-`unvalidated`
  control out of licence, class A included.
- **`red_driven` is deliberately NOT capped**, even though §2 rightly calls it
  weaker than it looks. A red drive establishes the one property a gate
  structurally needs — **that the check can fire**. What it does not establish is
  the converse, that the check stays quiet when it should. At **Class C** that is
  a question about a *chosen threshold*, which is exactly what the class axis
  exists to charge, so capping here too would charge the same weakness twice.

  **The known limit of that argument, and it is not a small one.** The principled
  half above holds at Class C and **fails at Classes A and B**, which carry *no
  fitted threshold* for the class axis to charge. A red-driven Class-A check that
  only ever detects the one violation shape its own author planted is charged by
  **neither axis**: the class axis has no chosen threshold to object to, and the
  evidence axis takes the red drive at face value. So at A and B this rule rests
  on the consequentialist half below and not on the principled half above — and
  the consequentialist half is doing the load-bearing work precisely where the
  principled half is weakest. The gap is real and is stated rather than implied
  away. It is not a reason to change the rule here: closing it requires evidence
  that a check *stays quiet when it should*, which nothing in this repository
  measures and which this matrix could not verify anyway, since it takes
  `empirical_status` at the author's word.

  **The consequentialist half, derived rather than remembered.** Capping
  `red_driven` at `advise` would put **81 of 97 controls out of licence in a
  single edit — 56 of them newly**, on top of the 25 already named below. A
  matrix that flags nearly everything discriminates nothing. (For scale, and not
  to be confused with it: **71** is the number of controls whose
  `empirical_status` is exactly `red_driven`, and **75** the number whose status
  *contains* it — the second is the figure CROSSWALK.md uses, for a different
  question.)

**There is no composite evidence score, and there will not be one.** The obvious
shape is `q = w1*class + w2*evidence`, one number, one threshold. It is refused
for the two reasons `bandwidth-check.sh` refuses a composite load score one layer
along: the **weights are unjustifiable** — nothing here has measured how being
the wrong class trades off against having no evidence — and worse, **one number
hides which axis is saturated**. An operator told "control quality 0.4" learns
nothing actionable; "class licenses `advise`, evidence licenses `advise`, it
exercises `gate`" names two separate things to fix. So the two axes are printed
**separately on every finding**, and every finding names the axis that binds it.

**The matrix ADVISES. It does not gate**, and that is the load-bearing decision
rather than a soft start. It is registered as `evidence.policy_matrix`, Class C,
`runtime_authority: advise`, `authority_mismatch: none`. Three reasons:

1. It is **chosen policy, not a definition**. Where `unvalidated` caps is a
   judgement — defensible, and still a judgement. A matrix that *gated* on the
   rule "chosen thresholds may not gate" would be self-refuting in exactly the way
   `bandwidth.active_packet_singleton` was found to be.
2. Gating would demote **19 controls immediately and automatically** — the system
   re-authorising itself with no operator in the loop. The authority envelope that
   would make automatic re-authorisation a legitimate act does not exist yet.
3. Precedent, endorsed on review: **new Class-C controls ship at `advise`;
   promotion to `gate` is a separate governance action.**

The one thing the tool *does* refuse (`evidence.derivation_nonvacuity`, Class A,
`gate`) is a derivation it cannot trust: an absent registry, a registry parsing to
zero controls, or a stanza carrying an `empirical_status` token the matrix has no
row for. An unrecognised evidence level must never fall through to permissive.

**The finding, derived and not remembered.** `evidence-policy.sh check` computes
the out-of-licence set from the registry on every run; no control id appears in
its source. On the census as it stands:

```
build-os/tools/evidence-policy.sh matrix   # the two axes and the composed grid
build-os/tools/evidence-policy.sh check    # the out-of-licence list; always exit 0
```

- **25 of 97 controls are out of licence** under the composed matrix.
- **20** of those the class axis already saw — they are exactly the 20 carrying
  `authority_mismatch: declared`, so the new axis reproduces the old finding
  rather than replacing it.
- **5 are visible only to the evidence axis**, and they are the point of the
  exercise: four class-A gates on `unvalidated` evidence
  (`maint.tripwire_armed_precondition`, `maint.rotate_node_precondition`,
  `tools.handoff_lock`, `tools.capability_profile_usage`), each carrying
  `authority_mismatch: none` because the class table licenses them — plus
  `maint.source_scan_mask`, which advises on `refuted` evidence.
- **1 control gates on evidence containing `refuted`** —
  `maint.tripwire_coverage_scan`. It is already declared, but its declaration
  *understates* it: the class axis caps it at `advise`, the evidence axis at
  `observe`.

**This section re-authorises nothing.** Naming what is out of licence is not
demoting it. Every `class`, `runtime_authority`, `authority_mismatch` and
`empirical_status` in the census is exactly what it was before this axis existed.

#### A finding for the operator: step 4 collides with this axis, twice

Step 4 of the roadmap is **S1**, slated to arrive at `runtimeAuthority: rank`
carrying `empiricalStatus: untested`. Both halves of that collide with what this
section just established, and neither collision is resolved here — **naming them
before S1 is designed is the deliverable**, because both are cheap to design
around and expensive to retrofit.

1. **S1 ships out of licence on day one.** `rank` is above `advise`, and the
   expensive rule caps *any* control whose evidence has established nothing at
   `advise` — the whole point being that `rank` orders work with no human in the
   loop. A control arriving at `rank` with no evidence is precisely the case the
   rule was written to catch, so the matrix will name S1 the first time it runs
   against it. That is the rule working, not the rule mis-firing.
2. **`untested` was not one of the evidence tokens — and now it is.**
   **RESOLVED by `gravito_p2_claim_scoped_evidence_a`, and resolved in the
   direction that costs.** Before that packet the ontology carried
   `unvalidated`, `red_driven`, `field_observed`, `calibrated` and `refuted` and
   nothing else, so a stanza carrying `untested` was **unclassifiable** and
   `evidence.derivation_nonvacuity` (Class A, `gate`) refused **the entire
   derivation at exit 2** rather than flagging S1 — deliberately, because an
   unrecognised evidence level must never fall through to permissive.

   The two available moves were *add `untested` as a sixth token with its own
   cap* or *have S1 arrive carrying `unvalidated`*. **The first was taken**,
   because the operator had already ruled the two meaningfully different and
   because the claim-scoped evidence store needed a way to record a claim that
   has never operated — `EV-0003-handoff-lock-stale-reclaim-untested` is one, and
   it is an assertion about a real control that no test in this repository
   exercises. **The token arrived at `observe`, the most conservative cap
   available**, which is what distinguishes adding a level from fitting the rule
   to the case: it makes the sanctioned S1 declaration **more** out of licence,
   not less. S1 at `rank` on `untested` is now out of licence on the evidence
   axis by two rungs rather than one, in addition to collision 1 above.

   **The refusal path is unchanged.** Any *other* unrecognised token still takes
   the whole derivation down at exit 2, and
   `tests/claim_evidence_tests.sh` §4 drives that with a token that is still
   unrecognised in the same run that proves `untested` now resolves — so
   "recognising one token" cannot be confused with "opening a fall-through".

### 3b. The third axis: deployment, and the artefact that grants it

Everything above states, repeatedly, that **re-authorising a control is a
governance action belonging to the operator**. Until now *the operator had no
mechanism to perform one*. There was no artefact anywhere in this repository in
which a human could write "this control may exercise this authority, on this
basis, until this date, and here is where it lands when the lease ends". A rule
that names an act nobody can carry out is not a rule with a gap in it; it is a
rule that has never been available. `build-os/registry/authority_envelopes.txt`
is that artefact, and `build-os/tools/authority-envelope.sh` validates it.

**The store ships empty of grants**, and that is the point rather than an
omission: creating the first grant is a governance act, and a packet that shipped
the mechanism *and used it* would have re-authorised something by writing the
tool that permits re-authorisation. It carries a worked example, entirely inside
comments, because an example a parser can see is a live grant wearing a label.

**An envelope record carries fourteen fields:** `envelope` (the id a revocation
names), `issuer` (a human), `actor`, `control`, `scope`, `granted_authority`,
`evidence_basis`, `deployment_mode`, `starts`, `expires`, `revocation`, `reason`,
`human_confirmation`, `rollback_behavior`. Two of them do the work the other
twelve support. **Leases end** — an authority granted with no `expires` is a
permanent re-authorisation with a date on it. And `deployment_mode` is the axis.

**The lease term is enforced against a clock, and for two packets it was not.**
The tool format-checked `starts` and `expires` and ordered them, then never asked
what day it was — `date` appeared in no tool in this repository. An envelope seven
months dead reported `1 live grant(s)` and `WITHIN-LICENCE … l-deployment=execute`,
computing the strongest deployment cap in the system from a lease that had ended;
the same record moved five months into the *future* produced **byte-identical**
output. The window was decorative at both ends.

**The defect was not "expired grants over-permit".** It is that **an expired grant
keeps applying in whichever direction it pointed**, and only one direction is
visible: a dead `shadow` lease drags a control licensed `gate` on both live axes
down to `observe`, while a dead *permissive* lease is byte-identical in the
matrix's output to no grant at all — because an ungranted control already takes
the default `autonomous`/`execute`. A test written only against the permissive
direction passes against a fixed tool and an unfixed one alike.

A record is **live** iff `starts <= now < expires`. The interval is half-open, so
`expires` is the moment the lease *ends* rather than the last day it covers.
Outside it, a record **contributes no grant** — it is not counted live, not
composed, and not projected into the licence matrix — and it is reported in one
of **two distinct states**, because a lease that ended and a lease that has not
opened are different facts about a grant:

| state | when | what it contributes |
|---|---|---|
| `LAPSED` | `expires` has passed | nothing. The lease ended. |
| `NOT-YET-LIVE` | `starts` has not arrived | nothing. The lease has never opened. |

**One clock, one owner.** `authority-envelope.sh now` is the only place in this
repository that asks what day it is; every other tool that needs a date sources
it, exactly as `claim-evidence.sh` sources its caps from `evidence-policy.sh
matrix`. `BUILD_OS_NOW` pins it so fixtures do not rot, a malformed override
**refuses** rather than falling back to today, and whenever the override is in
force **the output says so** — an override that could silently un-expire a grant
would be worse than no override at all.

#### Why a third axis at all

`class` asks what **kind** of thing is being checked. `empirical_status` asks
whether the check **works**. Neither asks the question an operator must actually
answer before switching something on: **what happens to the output?** A control
whose ranking nothing consumes and a control whose ranking silently reorders the
work queue are *indistinguishable on both existing axes*, and they are not the
same risk. `deployment_mode` separates **permission to rank** from **permission
to choose** from **permission to act**.

| `deployment_mode` | licensed authority | why that level |
|---|---|---|
| `shadow` | `observe` | its output may be watched, and it has **no operational consequence**. |
| `human_confirmed` | `advise` | a person sits between the signal and the consequence. |
| `bounded_autonomous` | `rank` | it acts unattended, inside declared bounds. |
| `autonomous` | `execute` | no additional cap. **The default.** |

> **`L_effective = MIN(L_class, L_evidence, L_deployment)`** over the same ladder
> `none < observe < advise < rank < gate < execute`. A control may do what **all
> three** allow, and no more.

**Why `autonomous` caps at the TOP rung, and why that is not a promotion.** This
mode's cap has only ever been justified by its **position** — *"no additional
cap"* — and never by the token `gate`. When `execute` was added above `gate`,
leaving `autonomous` at `gate` would have converted a documented **non**-cap into
a **real** cap on every one of the controls that predate this axis and therefore
take the default, demoting the whole census in one commit with no operator in the
loop — the self-re-authorisation this axis exists to prevent, run in reverse. It
would also have made `execute` **unreachable on the deployment axis for every
control**, which is precisely the unreachable-rung defect that forced the ladder
correction in the first place. So the cap tracks the top of the ladder.

This grants nobody `execute`, because the composition is a **minimum**: the class
axis still caps Class A at `gate`, so no control can reach `execute` through the
deployment axis alone. The axis that withholds `execute` is **class**, which is
where a licence decision belongs.

**The reading NOT taken, recorded the way §3's S1 collision records both of
its readings.** There is a real argument the other way, and it is not the weak
one:

> **READING B — an operator who authorised AUTONOMY did not thereby authorise
> MUTATION.** `autonomous` is a statement about whether a human sits in the loop.
> `execute` is a statement about whether the world changes. Those are different
> permissions, and a mode whose whole content is *"it acts unattended"* arguably
> should not be the row that carries the ladder's mutation rung. On this reading
> the cap belongs at `gate` and a **fifth** mode should be declared for
> mutation — leaving `autonomous` meaning "unattended, but still may not write".

**It is not adopted, and the reason is structural rather than a preference.** The
deployment axis is a **cap**, not a grant: every row states the *ceiling* a mode
imposes, and `L_effective` is the **minimum** of three terms. So this row does
not say *"an autonomous control may mutate"*; it says *"this axis imposes no
ceiling of its own"* — and the class axis, which is the axis that decides
licences, still withholds `execute` from every class including A. Reading B
answers a question the axis is not asking. Adopting it would also re-introduce
the exact defect the ladder correction removed: a rung reachable on no axis,
foreclosed by a cap that was only ever meant to say *"no cap"*. **Whether a fifth
deployment mode should exist is a live question** — Reading B's substance
survives as that question — and it is recorded here for the operator, not settled
here.

#### An envelope can only LOWER `L_effective` — read this before planning with it

Because the composition is a **minimum**, the deployment term can only pull
`L_effective` **down**. **An envelope can never raise a control above `L_class`
or `L_evidence`.** The default `autonomous` caps at `execute`, which is the top
of the ladder and therefore no cap at all; every other mode is strictly below it.
So
the *only* thing an operator can do to `L_effective` by writing a record is
**reduce** it.

**This is deliberate and it is the best property the artefact has** — the
validator refuses to launder a Class-C control into a `gate` even when the
operator signs the grant. Written out, a grant of `gate` to
`adoption.lane_size_check` (Class C, `calibrated,red_driven`, exercising `gate`)
reports:

```
envelope: OVER-GRANTED … granted=gate l-class=advise l-evidence=gate
          l-deployment=gate l-effective=advise binding-axis=class
```

and `evidence-policy.sh` still reports that control **out of licence**, its
finding byte-identical to the run with no store at all.

**What this means for the step this section opens with.** The paragraph above
says the operator *had no mechanism* to re-authorise a control and that this
artefact is that mechanism. Read carelessly, that invites the conclusion that the
fourteen `authority_mismatch: declared` controls can now be cleared by writing
fourteen envelopes. **They cannot.** The store **records** a grant and
**composes** it; it does not **legitimise** one. Applying the registry's
promotion and demotion rules to those fourteen needs a **class change**, a change
in `empirical_status`, a change to the licence table itself, or an instrument
that does not exist yet — a governance act on the *first two* axes. An envelope
is the artefact in which such an act is **recorded and bounded**, not the
authority that performs it.

Two of those rows carry an argument that is not merely a preference:

- **`human_confirmed` caps below `rank` by the ladder's own definition of
  `rank`** — §3a already fixes `rank` as the rung that lets a control order work
  or select between options *with no human in the loop*. A mode whose entire
  content is "a human confirms" cannot license the rung that means "no human
  confirms". This is a consistency requirement, not a judgement call.
- **`bounded_autonomous` caps below `gate`** because `gate` is the *unbounded*
  stop, and "bounded" is precisely the refusal of it.

#### The default is `autonomous`, and the defence matters more than the value

Every control in the census predates this axis and declares no deployment mode.
**`autonomous` — no additional cap — is the only default that leaves the finding
set exactly where the operator put it.** Any other default would demote the
entire census in a single commit with no operator in the loop, which is precisely
the self-re-authorisation this artefact exists to prevent. A permissive default is
normally the wrong instinct; here the conservative direction is *change nothing*,
not *cap everything*.

That is **proved, not asserted**. `tests/evidence_policy_tests.sh` §18 runs the
matrix against the live envelope store and against an empty one and requires
every finding line to be **byte-identical**, reconciles the per-axis split
against the census's own count of `authority_mismatch: declared`, and requires
that **no live finding is bound by the deployment axis**. §18a drives the other
half red — a fixture control under `shadow` *is* capped, and the control beside
it with no envelope is not — because a regression test that only proved "nothing
changed" would pass equally well against a term that was never wired in.

**The cost of that default, stated rather than implied away:** the axis is
**opt-in** and does nothing at all until an operator writes a record. Nothing
here can *discover* that a control is deployed in shadow; it can only record that
a human declared so.

#### What the envelope machinery is allowed to do

It is registered as `envelope.grant_composition`, **Class C,
`runtime_authority: advise`, `authority_mismatch: none`.** It reports; it does
not gate, and it **grants nothing**. Beyond the two reasons §3a already gives for
the matrix, one is specific to this artefact: **a validator that gated would be
enforcing a governance scheme over zero live grants** — vacuous authority over an
empty set, able to fire only on the operator's own first attempt to use the
mechanism, which is the worst possible moment to refuse.

The one exception mirrors `evidence.derivation_nonvacuity` exactly.
`envelope.derivation_nonvacuity` (Class A, `gate`) refuses a derivation it cannot
trust: an **absent** store, an unparseable one, a record missing a required
field, a duplicate id, a `granted_authority` off the ladder, a malformed or
backwards lease term, a field the schema has no slot for, or **an unknown
`deployment_mode`**. The last is the sharpest, because the deployment term is a
`MIN` term: reading an unknown value as "no cap" would silently license
everything the store exists to bound.

**Zero grants is the correct state, not the shelfware state** — and this is the
one place §4's vacuity reasoning is deliberately *not* copied. `scan-controls.sh`
refuses a registry declaring zero controls because an empty census is an
unclassified system wearing a registry. An empty *envelope* store means the
opposite and better thing: **nothing has been re-authorised.** So zero records
reports and exits 0, while an **absent** store still refuses — absent is not
empty, and reading a missing file as "no grants" gives the permissive answer to a
question that was never asked.

#### The open question this section records and does not answer

The sanctioned S1 launch declaration is `controlClass: heuristic_policy` /
`empiricalStatus: untested` / `runtimeAuthority: rank` / `deploymentMode:
shadow`. **As literally specified, `min()` cannot produce `rank` for it.**
`heuristic_policy` is Class C, §3 licenses Class C at `advise`, and `rank` is
strictly above `advise` on the ladder, so the minimum can never exceed `advise`
whatever the other two terms say. Two readings, and they claim different things:

1. **S1 ships carrying `authority_mismatch: declared`** — the fifteenth. Honest,
   mechanical, and exactly consistent with the fourteen already reported in
   `MISMATCHES.md`. Nothing new is required of the ladder.
2. **`shadow` means the ranking has no consequence**, so `runtime_authority` is
   measuring the wrong property for a shadow-mode control, and the ladder
   **conflates signal strength with whether anything consumes the signal**. A
   control that ranks into a void is not exercising `rank` in the sense the
   ladder means.

**Both are recorded. Neither is adopted.** Reading 2 is architecturally
interesting and may well be right — but adopting it would **redefine the
ladder**, which is a governance change and not a build decision, so `shadow`
still caps at `observe` here and S1 as declared would still be out of licence.
This is the same treatment §3a gave the collision it found: record it, do not
quietly fix it. **The operator decides.**

**And `untested` remains pending.** The operator has ruled that `untested` (has
not yet produced live outputs against real tasks) and `unvalidated` (has
operated, but lacks sufficient outcome evidence) are meaningfully different.
**That distinction is not implemented.** The evidence axis in §3a still carries
exactly five tokens, `untested` has no cap row, and a control declaring it is
still refused at exit 2 rather than falling through to permissive — proved, not
asserted, by `tests/authority_envelope_tests.sh` §18. Adding a token so that a
planned control fits is the failure this registry exists to prevent, so the sixth
token is the single decision the next packet must take.

**This section re-authorises nothing.** No `class`, `runtime_authority`,
`authority_mismatch` or `empirical_status` changes, and **no grant exists for any
control.**

### 3c. The five dispositions: what may be DONE about a mismatch

The licence table says when a control is out of licence. It has never said what
an operator may do about it, and `MISMATCHES.md` named four remedies in prose:
`demote_authority`, `correct_class`, `improve_evidence`, `retire_control`.
`maint.source_scan_mask`'s own registry entry records that **all four were closed
to it**, each for a separate reason — so a control whose every prescribed remedy
is unreachable had nowhere to be recorded except as a mismatch nobody was doing
anything about, which reads exactly like a mismatch nobody had got to yet.

There is now a fifth, recorded in `build-os/registry/mismatch_dispositions.txt`
and validated by `build-os/tools/mismatch-disposition.sh`:

| disposition | what it means |
|---|---|
| `demote_authority` | lower `runtime_authority` to what the class licenses. The default remedy. |
| `correct_class` | the classification was wrong, not the authority. |
| `improve_evidence` | measure, then re-derive. |
| `retire_control` | the control should not exist. |
| `accept_and_constrain` | the mismatch is **carried**, because demotion or removal has been **measured** to be more dangerous than the mismatch. |

**`accept_and_constrain` clears nothing and raises nothing.** A disposed control
keeps `authority_mismatch: declared`, keeps its row in the summary table, and
keeps its `OUT-OF-LICENCE` finding. The standing rule is unchanged: **this
machinery is class correction and authority demotion, and it is not a promotion
instrument.** A disposition makes a finding *legible*; an exception would make it
*go away*.

**It applies to exactly one control, and its neighbour is refused by name.** The
predicate carries four conditions, all required and each independently falsifiable:
(a) the census records `authority_mismatch: declared` for the subject; (b) the
subject holds a row in the machine-read summary table; (c) the named
`demotion_measurement` appears verbatim in the subject's own
`demotion_requirement`; (d) that token exists as an artefact elsewhere in the
tree — without (d), (c) is two documents agreeing with each other.
`maint.tripwire_coverage_scan` passes all four.
`maint.source_scan_mask` fails (a) and (c), and the refusal quotes the census's
own words back: its demotion is **REACHABLE**.

Every disposition carries a `review_by`. Past it the record is reported
`REVIEW-DUE` and is **not** dropped — unlike an authority envelope, where an
ended lease must stop granting. The asymmetry is the same rule read twice: an
expired thing keeps applying in whichever direction it pointed, so each artefact
is corrected in the direction that costs. Dropping a lapsed *grant* removes
authority nobody renewed; dropping a lapsed *disposition* would hide a mismatch
that is still being carried.

---

## 4. Reconciliation, and what it does not cover

```
build-os/registry/scan-controls.sh surfaces   # what the independent scan finds
build-os/registry/scan-controls.sh patterns   # the discovery rule, in full
build-os/registry/scan-controls.sh check      # reconcile; exit 2 on a violation
```

The scan calls a file a **control surface** if it can terminate a run non-zero.
Every surface must own at least one `gate` entry, and every `gate` entry must own
a surface. It is syntactic and needs no cooperation from the author, so a gating
control added in a new file is discovered whether or not anyone remembered.

Then, in the other direction, the report is read back as an **anchor**: every id
in `MISMATCHES.md`'s summary table must still be `declared`, and every declared
control must appear in that table. The report is hand-written on purpose —
clearing a mismatch costs an edit to the accusation, in prose, where a reviewer
reads it.

Five things it does not cover, named in `scan-controls.sh`'s own header as well:

1. **A new control added inside an already-registered file.** The scan is
   file-granular and the registry is control-granular. This is the largest hole
   and it is open.
2. **A refusal spelled in a way the pattern list does not match.** The list is
   printed by `scan-controls.sh patterns`.
3. **Advisory controls.** A file that only ever exits 0 is never discovered, so
   `observe`/`advise` entries are registered on the author's initiative and
   nothing reconciles them.
4. **Whether a cited line is a DECISION — half-covered, and only half.** See
   section 4a; this is the one that moved.
5. **An entry that sheds authority by NARROWING its `evidence_refs`.** The rule
   "do not clear a mismatch by changing the class" is enforced (section 3). The
   same result is available by a quieter route: leave the class alone and drop
   the citation that exceeded the licence, so the entry's declared scope no
   longer contains the line that gates. That is not hypothetical and it is not
   even always wrong — it is exactly the technique this packet used on
   `suite.pilot_kit`, `suite.build_os_maintenance` and `suite.lane_enforcement`,
   legitimately, to move a fitted constant out of a Class A entry and into the
   Class C family where it belonged. Legitimate and illegitimate narrowings are
   the same edit. Only one family is policed against the tree — the `-ge N`
   floors, by `tests/control_registry_tests.sh` §21, which fails if the entry
   and the tree disagree in either direction. For every other entry, the set of
   lines it claims is the author's word, nothing compares it against what it
   claimed yesterday, and a narrowing costs one deletion in a `;`-separated
   list. Closing this needs a per-entry scope rule of the kind §21 has, written
   once per family; it is not written.

### 4a. What "does the cited line do anything" now means, exactly

`evidence_refs` used to be checked only for landing *inside* the file. That is
how `tools.supervise_timeout` cited a header comment, an `echo` and a `fi` for a
full packet, and how two entries cited `#!/usr/bin/env bash` — the `nref >= 1`
guard passing on a line that is not code, which is the guard failing rather than
passing. Each round of resolving the citations by hand found more and cast a
wider net than the last. `scan-controls.sh` section 6 now refuses these, as
`VACUOUS-REF`:

**Caught:** a blank line; a comment-only line (`#` for shell, `//` `/*` `*` for
`.mjs`); a shebang; a lone closer — `fi`, `done`, `esac`, `else`, `}`, `)`, `{`,
`]`, `;;`. The exact patterns are printed by `scan-controls.sh patterns` under
`vacuous-ref:`.

**Not caught:** any line that is a statement but not a decision. An `echo`, an
assignment, a bare function call and a `return` all pass. Measured against the
defect that motivated the check: of the three bad `supervise_timeout` refs it
catches **two — the comment and the `fi` — and not the `echo`**. The check worth
having is "is this line a comparison or an exit", and that one is hard; this is
the cheap half and it is not being sold as the whole thing. Prose citations —
`MISMATCHES.md` naming a line in running text — are not `evidence_refs` and are
not covered at all; §13 of that file carried a stale one for two rounds.

**Declarations pass on purpose.** A threshold control is often best cited at the
line that *defines* its chosen constant — `supervise.sh:21`, `TIMEOUT="900"`, is
the entire subject of that entry — and a filter that rejected declarations would
push authors to cite a less honest line to appease it. If a ref ever genuinely
has to point at a line the filter rejects, it goes in `EVIDENCE_VACUITY_ALLOW`
in `scan-controls.sh`, with its reason beside it, where `grep` finds it;
`scan-controls.sh patterns` prints the list and its size, so an allowance
quietly growing is visible without reading the file. **It is empty today.**

The registry carries **406** `evidence_refs`. That number is not remembered: the
same total was previously written down in three artefacts as 218, 184 and 184
against a live 224, because each was a hand count frozen at a different moment.
`tests/control_registry_tests.sh` §25 recomputes it from the registry and fails
if any stated total disagrees, so the two other artefacts now state no total at
all and this one cannot go stale quietly.

Pinned by `tests/control_registry_tests.sh`.

---

## 5. What this registry is deliberately NOT

It contains no reachable-future potential, no collective coherence measure, no
goal ecology, no value-of-information calculation, no completion or failure
probability, no causal attribution, no learned risk model, no adaptive threshold
and no manifold state. Every entry classifies a control **that already runs in
this repository today**. The registry is the prerequisite for deciding whether
any of that is worth building; it is not a down payment on it.

`CROSSWALK.md` and `neurocosmology_crosswalk.txt` add **one axis and no
mathematics**: they bind each registered control to the universal function it
instantiates, and record what each binding misses. That file uses the words this
section disclaims — *collective coherence*, *goal ecology* — as **labels for
slots**, and its main result is which slots are **empty**. It computes none of
them, creates no control, and grants no authority; every class and authority it
names is a copy of one already recorded here.
