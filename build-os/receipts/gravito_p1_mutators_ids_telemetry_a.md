# gravito_p1_mutators_ids_telemetry_a — `execute` gets its first six occupants, identity stops being a line number, and the packet records the feature vectors of the arms it did NOT take

- **Packet id (stable):** `PACKET-0006-gravito-p1-mutators-ids-telemetry-a`
  — assigned under the ID scheme this packet introduced, and already live in
  `build-os/registry/defect_classes.txt` as the `packet_id` on five occurrence
  records. **Not** to be confused with `PACKET-0015-mutation-census`, which is
  this packet's *candidate* id inside `DECISION-0007-p1-mutators-ids-telemetry`.
  Both are correct and they name different things: one is the packet, the other
  is the arm that was selected out of a four-candidate set.
- **Date:** 2026-08-01
- **Lane:** `substantive` (builder → qa ‖ reviewer → fix → re-review → fix → tiny-lane close → archivist)
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `7daedee` (the close of `gravito_ladder_semantics_a`); re-verified at close —
  `git merge-base a75c25e 7daedee` = `7daedee`, so the branch base is correct.
- **Final HEAD (packet):** `a75c25e`
- **Verdict:** **pass as fixed** — qa **RED** (documentation-only, **zero test failures**),
  reviewer **`fix-then-pass` twice** (11 items, then 6).
- **Second eyes:** **NONE.** Every verdict single-model. `codex` is not on PATH and no
  Codex plugin is installed; `build-os/memory/tool_router.md:368` routes reviewer
  second-eyes to it and the row is **unbacked for the sixth packet running**.

---

# PHASE CONTEXT — RECORD THIS FIRST, IT FRAMES EVERYTHING AFTER

**The governance-only phase is OVER.** The operator has ended it and issued **build
authority** with an **anti-stall rule**: build around the limitations rather than
pausing on them, and record what was built around.

The operator's framing, recorded verbatim because it is the standard every packet
from here is measured against:

> *"the governance substrate is no longer the bottleneck. The bottleneck is now
> whether Gravito can begin making better decisions than today's planning
> approaches."*

**This is P1 of five.** The sequence:

| phase | subject |
|---|---|
| **P1 (this packet)** | **mutators / IDs / telemetry** |
| P2 | claim-scoped evidence |
| P3 | `accept_and_constrain` |
| P4 | S1 shadow ranker |
| P5 | outcome / counterfactual telemetry |

Everything below should be read as *substrate for P4*, not as governance for its
own sake. The single question the receipt exists to answer for a later reader is:
**can P4 be trained on what P1 recorded?** Finding 1 answers it, and the residue
attached to finding 1 says on what condition.

---

# WHAT P1 DELIVERED

1. **The mutator census.** `build-os/registry/mutator_registry.txt` — **every
   durable-write path in the repository**, identified, scoped, and classified on
   **what it actually guarantees** rather than on the check that stands next to it.
   Eight records, `MUT-0001` … `MUT-0008`.
2. **SIX `execute` OCCUPANTS — THE RUNG'S FIRST EVER.**
   `maint.rotation_live_file_replacement`, `swarm.merge_commit_execution`,
   `metrics.record.store_append`, `metrics.decision.store_append`,
   `identity.stamp_write`, `tools.handoff_lock_lifecycle`.
   **Census 81 → 90.** Authority distribution
   **71 `gate` / 13 `advise` / 6 `execute` / 0 `rank` / 0 `observe` / 0 `none`.**
3. **Stable IDs at birth.** `MUT-*`, `CTRL-*`, `DEFECT-*`, `FINDING-*`, `PACKET-*`,
   `DECISION-*`, `EVIDENCE-*`, `OUTCOME-*`, `SIGNAL-SNAPSHOT-*`, `RANKING-*`.
   **Line numbers are navigation hints; they are no longer identity.** IDs are
   **DERIVED, not ledgered** — a central ledger would be a second copy of every id
   with nothing reconciling the two, which is `DEFECT-0003-duplicate-semantic-truth`
   itself.
4. **`build-os/registry/defect_classes.txt`** — **twelve** recurrent defect classes,
   `DEFECT-0001` … `DEFECT-0012`, **mechanically queryable**. Recurrence moves out of
   prose and into a store that answers `query(defect_class_id)`.
5. **`build-os/metrics/record-decision.sh`** + **decision telemetry**
   (`decision_telemetry.tsv`) + **frozen signal snapshots**
   (`signal_snapshots.tsv`).
6. **`build-os/registry/governance_baseline.txt`** — pins `class`, `authority` and
   `mismatch` on **all 81 pre-existing controls**, so a governance move cannot happen
   without the baseline being edited in the same diff.
7. **`build-os/registry/findings.txt`** — `FINDING-0001-managed-set-replacement-understated`,
   `FINDING-0002-hook-once-marker-understated`,
   `FINDING-0003-mutators-emit-no-receipt`. **Remedies named and DELIBERATELY
   UNAPPLIED** — moving a pre-existing control is a re-authorisation and belongs to
   the operator.
8. **New suite** `tests/mutator_registry_tests.sh` and **new scanner**
   `build-os/registry/scan-mutators.sh`, both chained/registered rather than left
   discoverable-only.

---

# THE FINDINGS THAT MATTER

## 1. P1 DELIVERS THE COUNTERFACTUAL SUBSTRATE, NOT IMITATION LEARNING

**This is the finding that decides whether the five-phase sequence can work.**

`build-os/metrics/signal_snapshots.tsv` carries **12 rows across ALL FOUR candidates
of `DECISION-0007-p1-mutators-ids-telemetry` — including the three that were NOT
selected**:

| candidate | selected? | snapshots |
|---|---|---|
| `PACKET-0015-mutation-census` | **selected** | `SIGNAL-SNAPSHOT-0001` … `-0003` |
| `PACKET-0016-citation-identity-anchor` | rejected | `SIGNAL-SNAPSHOT-0004` … `-0006` |
| `PACKET-0017-chain-the-live-suite` | rejected | `SIGNAL-SNAPSHOT-0007` … `-0009` |
| `PACKET-0018-ladder-spelling-sweep` | rejected | `SIGNAL-SNAPSHOT-0010` … `-0012` |

Three signals each (`dependency_unlock_count`, `licence_state`,
`declared_mismatch_proximity`), **digest-chained**, each naming its
`repository_commit` (`7daedee`) and its `derivation_version` (`v1`).

**IMITATION LEARNING NEEDS ONLY THE SELECTED ARM. THIS RECORDS THE FEATURE VECTOR
FOR THE REJECTED ARMS TOO.** That is the difference between a store that can only
learn to reproduce past choices and a store a counterfactual evaluator can actually
be trained against.

**§9 of `tests/mutator_registry_tests.sh` proves the freeze EMPIRICALLY, not by
assertion:** it reads a historical `signal_value`, **materially mutates the live
registry the signal derives from**, re-reads, and asserts **no movement**.

The store's own header states the principle:

> *"A later evaluation must never recompute a historical signal against the current
> tree: that scores a decision nobody took, on information nobody had."*

**And the first twelve rows are recorded UNFLATTERINGLY to the signals themselves:**
the selected candidate scored **0** on `dependency_unlock_count` while a candidate
that scored **1** was **not** selected. The operator's ruling outranked the only
ordering signal that existed, and the store says so — because a store that only ever
agrees with the choice cannot answer whether the signals were worth having.

### RESIDUE THE REVIEWER ATTACHED — READ THIS BEFORE P2

**Today's training set is ONE decision with a non-degenerate candidate set.**
`DECISION-0001-fanout-lanes-scaffold-release` is a **fan-out where all three
candidates were selected**; `DECISION-0002` through `DECISION-0006` are all
**|C| = 1**. Only `DECISION-0007` has genuine rejected arms.

**P2 AND P3 MUST KEEP RECORDING REJECTED CANDIDATES OR P4 STARTS AT n = 1.**

## 2. THE PACKET COMMITTED THE TWO DEFECT CLASSES IT REGISTERED

It registered `DEFECT-0001-stale-line-reference` and
`DEFECT-0008-incomplete-application` **and shipped fresh instances of both** —
ultimately in **twenty sites across two rounds**.

**The sharpest instance:** `agency`'s `claimed_max_authority` was changed to
`execute` on one line while **the very next line still read** *"Five bindings… The
fifth binding"* against a live **11 bindings / 8 instantiating**.
**Corrected and uncorrected, ONE LINE APART.**

## 3. THE SWEEP HIT THE DERIVED DOC AND MISSED THE SOURCE ARTEFACT

Round 1 corrected **five** stale counts in `build-os/registry/CROSSWALK.md` and
**never swept `build-os/registry/neurocosmology_crosswalk.txt`** — **the artefact
`CROSSWALK.md` is DERIVED FROM**, and a file **this packet also edited**. **Seven
more stale sites were there.**

The reviewer named the cause **as its own**: *incomplete enumeration* —
`DEFECT-0007-incomplete-enumeration`, **the same class as its own item-8 miss**.

## 4. A FIFTH ESCAPE FORM: THE FILE HEADER

Site seven was `neurocosmology_crosswalk.txt`'s **header comment** — *"1 binding out
of 22"* against a live **23**, and *"12 out of 25"* against a live **14 of 27**.

**A HEADER COMMENT REACHES NO FIELD-SCOPED SWEEP.** The catalogue of escape forms is
now **five**:

1. bare `:NNN` citations, filename elsewhere in the sentence;
2. table rows naming a file with **no line number at all**;
3. **line-wrapped enumerations** — no same-line grep can see them;
4. **markdown table-row mappings**;
5. **header comments** — new here.

Every one is the same shape: **a guard written against one surface form, blind to its
siblings.**

## 5. TWO NUMBERS WERE WRONG WHEN WRITTEN, NOT MERELY STALE — AND BOTH ERRED IN THE FLATTERING DIRECTION

- **The packet's self-hit tally said 7 shifted / 4 silently wrong.** qa's repo-wide
  census gives **10 shifted / 3 flagged / 7 silently wrong**. **It under-reported its
  own defect.**
- **`defect_classes.txt` recorded only the occurrences the packet CAUGHT, not those it
  ESCAPED** — in a store **whose sole purpose is that `query()` returns a trustworthy
  count**, and whose own `OCCURRENCE-0008` states the principle it was violating:

  > *"a caught instance is evidence about the class exactly as an escaped one is."*

**Both corrected.** The direction of the error is the finding: a self-report that
errs is not noise if it errs consistently toward flattery.

## 6. THE REVIEWER'S OWN FIGURE WAS WRONG AND THE BUILDER REFUSED IT

The reviewer wrote **"64 of 90"** for the `red_driven` counterfactual in
`build-os/registry/README.md`. The builder derived **77 of 90** and — decisively —
**validated the METHOD rather than asserting the number**: run against `7daedee`,
the same composition **regenerates the reviewer's ORIGINAL sentence verbatim**
(*68 of 81, 49 newly, on top of 19*).

The orchestrator independently reproduced **25 / 77 / 52 / 25**.

> **A model that regenerates the prior sentence from the prior artefact is the model
> that produced it.**

**The reviewer confirmed its own error on re-review.** The live text now reads
*77 of 90 … 52 of them newly … on top of the 25*, and keeps **64** and **68** in the
same passage explicitly labelled as answers to **different** questions (`exactly
red_driven` = 64; *contains* `red_driven` = 68, which is the figure `CROSSWALK.md`
uses).

---

## Scope

**In:**

1. **Register the mutators.** The five named in the brief — **confirmed by an
   independent survey, not trusted from the list** — plus the ones the survey added.
   Classified on what each **actually guarantees**, never assumed Class A.
2. **Stable identity at birth** — the smallest ID substrate this repository actually
   requires. **Not** the persistent memory kernel.
3. **Structured defect-class identity** — recurrence out of prose and into a store
   that answers `query(defect_class_id)` mechanically.
4. **Baseline decision telemetry** — **unknowns stay unknown; they never become zero.**
5. **Decision-time signal snapshots** — frozen at decision time.
6. **`governance_baseline.txt`** pinning all 81 pre-existing controls.

**Out — recorded, not acted on:**

- **Moving any pre-existing control.** `maint.managed_set_replacement` was examined
  exactly as asked and **DELIBERATELY NOT MOVED** — it is `FINDING-0001` with the
  remedy **named and unapplied**, because moving a pre-existing control is a
  **re-authorisation that belongs to the operator**.
- `hooks.once_dedup` — `FINDING-0002`, same reasoning.
- **A receipt standard for mutators** — `FINDING-0003`, **no remedy proposed, on
  purpose**: the census was built to make the question askable, not to answer it.
- **Whether any class should license `execute`.** Today **no class does**, so the six
  new registrations are **out of licence BY CONSTRUCTION**. Open, deliberately.
- **The ladder-spelling sweep** — still deferred (`MISMATCHES.md` §16).
- **Zero governance-field changes** to any pre-existing control.

---

## Commits — 2, at the cap

| commit | one-line |
|---|---|
| `f27c570` | `docs(packet): declare gravito_p1_mutators_ids_telemetry_a before building` |
| `a75c25e` | ``feat(registry): census every mutator, give it a stable id, and start recording decisions`` |

**`f27c570` is untouched and is still an ancestor of `a75c25e`.** Commit 1 is the
**declaration alone**, as its own commit, before the first edit to any other file —
so **git attests the ordering** without a third commit and without a pre-commit hook.
It is trivially green in isolation and it keeps **6** `^## ` blocks, because clearing
that file to 2 is exactly what shipped `2df61ae` red.

**File-ownership manifest** (numstat union of `f27c570` + `a75c25e`): **18 files,
2918 insertions, 133 deletions.**

```
CHANGELOG.md                                     +82   -0
build-os/metrics/decision_telemetry.tsv          +44   -0
build-os/metrics/record-decision.sh             +378   -0
build-os/metrics/signal_snapshots.tsv            +56   -0
build-os/packets/active_packet.md               +140  -70
build-os/registry/CROSSWALK.md                   +20  -18
build-os/registry/MISMATCHES.md                 +103  -16
build-os/registry/README.md                      +11  -10
build-os/registry/control_registry.txt          +204   -6
build-os/registry/defect_classes.txt            +284   -0
build-os/registry/findings.txt                   +81   -0
build-os/registry/governance_baseline.txt       +115   -0
build-os/registry/mutator_registry.txt          +233   -0
build-os/registry/neurocosmology_crosswalk.txt   +71   -8
build-os/registry/scan-mutators.sh              +411   -0
tests/build_os_tests.sh                           +1   -0
tests/evidence_policy_tests.sh                   +30   -5
tests/mutator_registry_tests.sh                 +654   -0
```

---

## QA proof — RED, documentation-only, ZERO test failures

**qa returned RED on documentation defects alone. Not one test failed.** It proved
the substance **BY EXECUTION**, not by reading:

| check | result |
|---|---|
| `bash tests/build_os_tests.sh` | **1689 passed / 0 failed** (was 1636) |
| `./build-os/maintenance/run-tests.sh` | **144 / 144** |
| `bash build-os/registry/scan-controls.sh check` | **exit 0** |
| `bash build-os/registry/scan-mutators.sh check` | **exit 0** |
| `bash build-os/tools/evidence-policy.sh check` | **25 of 90, split 6/5/14**, exit 0 |
| **Commit-1 isolation** | **GREEN in isolation** — `f27c570` builds and passes on its own |
| **Safety grep** | run; **ZERO governance-field changes** — nothing pre-existing re-authorised |
| **UI smoke** | **N/A — this packet has no UI surface.** Registry / metrics / tooling only; no frontend file touched. |

### The six `execute` registrations were proven BY EXECUTION

- **`swarm-merge.sh --commit` created commit `ff2c8ac`** in a scratch repo — the
  mutator does what its record says it does.
- **`record-packet.sh` grew its store 12 → 13 rows.**
- **`record-decision.sh` appended.**

### Stable identity was proven by MOVING THINGS

- **A 25-line insertion moved `MUT-0002` from line 104 to line 129 and `query`
  output was BYTE-IDENTICAL.** Identity survived the move; that is the whole claim.
- **Duplicate ID injection exits 2.**
- **`query(DEFECT-0001)` returns 3 occurrences.**
- **The baseline drove RED on a flipped authority** — `governance_baseline.txt` is
  live, not decorative.

### Telemetry honesty was measured, not asserted

- **20 fields written `unknown` with ZERO literal `0`s.** An unmeasured quantity
  never became a measurement.
- **Exactly 2 `@derived` values**, both traced **verbatim** to
  `build-os/metrics/packet_metrics.tsv`.
- **117 unknown cells, NOTHING back-filled by inference.**

### The freeze was proven by mutation

- **Appending a 91st control left `signal_snapshots.tsv`'s md5 UNCHANGED.**
- **`build-os/memory/*` byte-identical at start and finish** of the full suite run —
  destruction confinement re-verified.

---

## Fix rounds

| round | source | items |
|---|---|---|
| stage-3 fix | reviewer `fix-then-pass` #1 | **11 items** |
| — | delivered as | **13 reconciled items in ONE installment** |
| re-review | reviewer `fix-then-pass` #2 | **6 items** |
| tiny-lane close | orchestrator | **7 artefact sites** |

**All fix rounds complete and re-verified at `a75c25e`.**

**Depth: this packet ran past the 2-stage median.** The second fix round is the
honest reading of finding 3 — the round-1 sweep hit the derived doc and missed the
source artefact, so the same class returned. **Recorded as a defect of enumeration,
not of budget.**

**Second eyes: NOT DELIVERED, for the SIXTH packet running.** `codex` is absent;
`tool_router.md:368` declares the row anyway. It matters here specifically because
**finding 6 is a reviewer error that only the builder caught** — a second model is
precisely the instrument for that, and it was not available.

---

## Final state at `a75c25e`

| measure | value |
|---|---|
| Suite `tests/build_os_tests.sh` | **1689 passed / 0 failed** |
| `./build-os/maintenance/run-tests.sh` | **144 / 144** |
| `scan-controls.sh check` | **exit 0** |
| `scan-mutators.sh check` | **exit 0** |
| `evidence-policy.sh check` | **25 of 90, split 6/5/14** |
| Census | **90 controls** (was 81) |
| Authority | **71 `gate` / 13 `advise` / 6 `execute` / 0 `rank` / 0 `observe` / 0 `none`** |
| Declared mismatches | **20** |
| Class | A **67** / B **3** / C **20** |
| `implementation_status` | 76 `load_bearing` / 9 `implemented` / 5 `decision_contributing` |
| Mutator records | **8** (`MUT-0001` … `MUT-0008`) |
| Defect classes | **12** (`DEFECT-0001` … `DEFECT-0012`) |
| Findings | **3** (`FINDING-0001` … `FINDING-0003`), all remedies **unapplied** |
| Decisions recorded | **7** (`DECISION-0001` … `DECISION-0007`) |
| Signal snapshots | **12**, digest-chained, across **4** candidates of `DECISION-0007` |
| Live authority envelopes | **0** |
| Tree | **clean** |

### The 20 declared mismatches split into two kinds, and the split is the point

- **14** exercise `gate` on an `advise` licence — **fitted heuristics**, the
  pre-existing population.
- **6** exercise `execute` on a Class A licence that reaches only `gate` — the
  **durable writes**, out of licence **BY CONSTRUCTION**, because **no class licenses
  `execute`**. Their mismatch is not a defect in the registration; it is the registry
  correctly reporting that the operator has not yet decided whether anything may
  mutate under licence.

**ZERO governance-field changes. Nothing pre-existing was re-authorised.**
All figures re-derived by the archivist at close directly from
`build-os/registry/control_registry.txt` and the live tools.

---

# Residue — what this close hands forward

## 1. FIVE ESCAPE FORMS, and the newest one reaches no field-scoped sweep

Bare `:NNN`; table rows with no line number; line-wrapped enumerations; markdown
table-row mappings; **header comments**. Residue **(tt)**.

## 2. The derived-doc-vs-source-artefact miss

A sweep that corrects `CROSSWALK.md` and not `neurocosmology_crosswalk.txt` corrects
the **output** and leaves the **input** wrong, so the next regeneration reintroduces
it. **Sweep the source artefact, then the derived doc.** Residue **(uu)**.

## 3. n = 1 — THE WARNING FOR P2 AND P3

Only `DECISION-0007` has a non-degenerate candidate set.
**Keep recording rejected candidates or P4 starts at n = 1.** Residue **(vv)**.

## 4. Two PRE-EXISTING items the reviewer explicitly ruled NOT this packet's debt

- **(a)** `build-os/metrics/packet_metrics.tsv` holds **11** data rows (**12** after
  this close appends its own), while `CROSSWALK.md:319-320` says *"all 6 of 6"* and
  `neurocosmology_crosswalk.txt:169` says *"all 8 of 8"*. **Both wrong, and they
  disagree with each other** — the derived doc and its source artefact, again.
  Residue **(ww)**.
- **(b)** `MISMATCHES.md:484` and `:549-550` cite `tests/control_registry_tests.sh`
  at **`:79 :184 :440 :772`** where the live assertions are **`:81 :186 :442 :774`**
  — a **live `DEFECT-0001-stale-line-reference` instance that PREDATES this packet**,
  verified at close. Residue **(xx)**.

## 5. The baseline's one escape hatch

**§11 of `tests/mutator_registry_tests.sh` iterates rows PRESENT IN
`governance_baseline.txt`** — so **deleting a row and then moving that control
passes**. The only cardinality guard is `NBASE > 0`
(`tests/mutator_registry_tests.sh:573-575`), which certifies a store of one.
**The guard checks conformance of what is listed, never that the list is complete.**
Residue **(yy)**.

## 6. Carried forward, unchanged

- **`FINDING-0001` / `-0002` / `-0003` remedies are NAMED AND UNAPPLIED.** Applying
  any of them is the **operator's** act.
- **Whether any class should license `execute`** — open, deliberately. Until it is
  answered, every durable write in the repository is declared out of licence.
- **The citation guard still checks resolvability, not identity** (residue mm).
- **The ladder-spelling sweep** stays deferred (residue rr).
- **Second eyes unbacked** — six packets running (residue ss).

---

## Open boundaries — nothing done without go

- **NOTHING WAS PUSHED, MERGED, TAGGED, PR'd, DEPLOYED OR PUBLISHED by this close.**
  No secret was touched. **No `git config` was run.**
- **`f27c570`, `a75c25e` and this close commit are LOCAL-ONLY** and stay that way
  pending explicit go, joining the local-only run from `105cb75` onward.
- `/home/user/empathiq-website` was **not touched** (left at `cb2bb7d`).
- **Applying any `FINDING-*` remedy is a re-authorisation and is the operator's.**
- **Whether any class licenses `execute`** — open.

---

## Verification performed by this close

Re-run by the archivist **after** its own writes, on a quiet tree:

| check | result |
|---|---|
| `bash tests/build_os_tests.sh` | **1689 passed / 0 failed**, exit 0 |
| `bash build-os/registry/scan-controls.sh check` | **exit 0** |
| `bash build-os/registry/scan-mutators.sh check` | **exit 0** |
| `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` | **MATCH** — *"live suite total (1689 passed) matches current_state.md's claim (1689)"*, 44 passed / 0 failed |
| `git status --porcelain` | **empty** (after the close commit) |
| `./build-os/maintenance/run-tests.sh` | **144/144 — verified AFTER the writes**, because its absence from an earlier close checklist is how a pushed commit shipped red |
| `record-packet.sh --validate` | **12 rows, 0 invalid** |
| `build-os/packets/active_packet.md` `^## ` block count | **4** — verified after writing, ≥3 as required |

### ONE TRANSIENT RED, CAUSED BY THE ARCHIVIST, AND RECORDED RATHER THAN DISCARDED

The **first** post-write suite run reported **1688 passed / 1 failed**. **The cause was
the archivist's own process error, not the tree:** that run was launched in the
background and then `./build-os/maintenance/run-tests.sh` **and**
`RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` — which itself
executes a **full live suite** — were started **while it was still running**. **Up to
three suite runs were in flight at once, sharing the same repository and temp-dir
space.**

That is a direct violation of `CLAUDE.md`'s **tree-quiet** precondition, applied to
the close instead of to stage 2: **a measurement taken against a moving tree is junk,
and the number it produces belongs to no commit.**

**Resolution: a single ISOLATED, SEQUENTIAL run with nothing else in flight —
`1689 passed / 0 failed`, exit 0.** Two further runs during triage were also clean,
and the four suites that touch `packet_metrics.tsv` were each run standalone and
green (`speed_benchmark` 169/0, `metrics_adoption` 70/0,
`neurocosmology_crosswalk` 65/0, `pilot_kit` 154/0).

**The failing assertion's identity was NOT captured** — the first run's output was
piped through `tail -3` and the `FAIL` line was discarded before it could be read.
**That is a second archivist error and it is stated rather than glossed:** the honest
claim available here is *"a concurrent run went red once and every isolated run is
green"*, **not** *"the failure was proven harmless"*. **Recorded as residue (aaa).**

## Files written by this close — all inside `build-os/`

- `build-os/receipts/gravito_p1_mutators_ids_telemetry_a.md` (this file — new; **no
  past receipt rewritten**)
- `build-os/memory/current_state.md`
- `build-os/memory/residue.md`
- `build-os/packets/active_packet.md` (cleared, **and left with ≥3 `^## ` blocks**,
  count verified after writing — clearing it to 2 is exactly what made `2df61ae`
  ship red)
- `build-os/metrics/packet_metrics.tsv` (one appended row; **`defects_escaped` = `-`**,
  which means **UNAUDITED and never zero**)

## The close is a THIRD commit, and that is deliberate

The packet's own ≤2-commit budget is spent on `f27c570` + `a75c25e`. The close is
**bookkeeping after the verdict, not a third gate**, and it lands separately so the
packet's diff stays exactly what the gates measured.
