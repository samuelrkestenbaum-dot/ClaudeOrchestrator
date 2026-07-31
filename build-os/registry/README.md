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
  **`gate` on `unvalidated` evidence — 11 of 78**: eleven controls can stop the
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

`none < observe < advise < rank < gate`

| value | what the control may do |
|---|---|
| `none` | nothing consumes it. |
| `observe` | it measures and records. Nothing reads the result. |
| `advise` | its output is presented to a decision-maker who may ignore it. |
| `rank` | its output orders work, or selects between options. |
| `gate` | its output can stop the run. **In this repository, a control that exits non-zero is exercising `gate`, whatever its author called it.** |

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
test files. So "14 of 78 declare a mismatch" is a fact about this file's
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

**The composition rule, stated explicitly:**

> **`licensed = MIN(class-licensed, evidence-licensed)`** over the authority
> ladder `none < observe < advise < rank < gate`. A control may do what **both**
> axes allow, and no more.

The minimum, and not an average or a product, because the two are independent
**necessary** conditions: being the right *kind* of thing to gate does not make a
broken check work, and a working check does not make a chosen threshold an
invariant. Either failing is disqualifying on its own, and the minimum is what
that looks like arithmetically. The composed table:

| class \ evidence | `calibrated` | `field_observed` | `red_driven` | `unvalidated` | `refuted` |
|---|---|---|---|---|---|
| `A` hard invariant | `gate` | `gate` | `gate` | `advise` | `observe` |
| `B` deterministic metric | `rank` | `rank` | `rank` | `advise` | `observe` |
| `C` heuristic policy | `advise` | `advise` | `advise` | `advise` | `observe` |
| `D` learned model | `observe` | `observe` | `observe` | `observe` | `observe` |
| `R` research functional | `observe` | `observe` | `observe` | `observe` | `observe` |

**A comma-composite `empirical_status` resolves by MINIMUM** — the weakest
component governs. That is conservative in general, and in the one case that
matters it gives the honest answer without needing a timestamp this format does
not carry: **`refuted` dominates a `red_driven` that preceded it**, because a
later refutation *supersedes* an earlier red drive. The opposite reading — "it
red-drove once, so it is fine" — is how a measurement that found nothing gets
outvoted by the measurement that corrected it. So `red_driven,refuted` licenses
exactly what bare `refuted` licenses.

Three of those rows carry the argument:

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
  the converse, that the check stays quiet when it should, and that is a question
  about a *chosen threshold* — which is the class axis's job. Capping it here
  too would charge the same weakness twice, put 53 of 78 controls out of licence
  in a single edit, and produce a matrix that flags nearly everything and
  therefore discriminates nothing.

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

- **19 of 78 controls are out of licence** under the composed matrix.
- **14** of those the class axis already saw — they are exactly the 14 carrying
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

The registry carries **272** `evidence_refs`. That number is not remembered: the
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
