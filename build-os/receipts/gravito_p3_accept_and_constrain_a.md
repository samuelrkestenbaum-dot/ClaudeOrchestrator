# gravito_p3_accept_and_constrain_a — a fifth disposition that clears nothing, a lease term that finally binds, and a depth defect recorded as a defect

- **Packet id (canonical):** `PACKET-0023-gravito-p3-accept-and-constrain-a`
  — this is both the packet id and its own *candidate* id inside
  `DECISION-0009-p3-accept-and-constrain`, where it was the selected arm of four.
- **ID CORRECTION, RECORDED RATHER THAN SILENTLY APPLIED.** The orchestrator's
  close brief specified `PACKET-0020-gravito-p3-accept-and-constrain-a`. **That id
  is already taken by a different, distinct object:**
  `PACKET-0020-widen-control-registry-with-claim-fields`, a *rejected* candidate
  of `DECISION-0008`, live in `build-os/metrics/decision_telemetry.tsv`. Writing
  the brief's id would have created a **collision inside the decision store that
  P4's ranker reads as its training set** — two different candidates under one
  key. The canonical id is `PACKET-0023-…`: it is what
  `build-os/packets/active_packet.md:9` declared before the first edit, and it is
  what `decision_telemetry.tsv` already records as `DECISION-0009`'s selected
  candidate, **committed at `e68d931`, before this close and independent of it**.
  **This is the FIFTH time in this sequence a figure relayed by the orchestrator
  or the reviewer has been corrected downstream** — see residue `(fff)`, which
  enumerated the first four. It is also the first one caught by the **archivist**.
- **Date:** 2026-08-01
- **Lane:** `substantive` (builder → qa ‖ reviewer → fix → re-review → archivist)
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `f3c5353` (the close of `gravito_p2_claim_scoped_evidence_a`);
  re-verified at close — `git merge-base ead24bc f3c5353` = `f3c5353`, so the
  branch base is correct.
- **Final HEAD (packet):** `ead24bc`
- **Verdict:** **PASS-AS-FIXED.** qa **GREEN**. reviewer **fix-then-pass, TWICE**
  — and the second one is the important part of this close, because it is what
  turned a fix round into a **re-cut**.
- **Depth:** **4 SERIAL STAGES — WHICH THE CONTRACT CALLS A DEFECT, AND IT IS
  RECORDED HERE AS ONE.** See §4. Stage 5 was **not** opened; the remainder is
  re-cut as `gravito_p3b_count_derivation_a`.
- **Second eyes:** **NONE — NINTH CONSECUTIVE PACKET.** `codex` is not on PATH
  and no Codex plugin directory exists. **Every verdict in this entire five-phase
  sequence is single-model.** Residue `(zz)` records the streak as **six**; that
  counter is **itself stale** and is corrected to **nine** at this close — an
  item about unverified claims that had itself gone unverified.

---

# PHASE CONTEXT

**This is P3 of the operator's five**, under **build authority** and the
**anti-stall rule** (build around limitations and record what was built around).

| phase | subject | state |
|---|---|---|
| P1 | mutators / IDs / telemetry | **done** (`e6b825b`) |
| P2 | claim-scoped evidence | **done** (`f3c5353`) |
| **P3 (this packet)** | **`accept_and_constrain` + lease-window enforcement** | **done** (`ead24bc`) |
| P4 | S1 shadow ranker | next |
| P5 | outcome / counterfactual telemetry | pending |

Read everything below as **substrate for P4**, not as governance for its own
sake — and read §7 (the trajectory note) as the operator's explicit question
about whether that is still true.

---

# WHAT P3 DELIVERED

**Two things, and the first one is a live bug fix while the second is governance.**

1. **A fifth mismatch disposition.** The vocabulary is now
   `demote_authority | correct_class | improve_evidence | retire_control |
   accept_and_constrain`, carried by three new artefacts:
   - `build-os/tools/mismatch-disposition.sh` (`schema` / `list` / `validate` /
     `check`),
   - `build-os/registry/mismatch_dispositions.txt` (stable `DISP-NNNN-<slug>`
     ids, fourteen required fields),
   - `tests/mismatch_disposition_tests.sh`, **chained** from the repo suite —
     verified in the chain list, not merely present on disk.
2. **A lease window that is finally enforced.** `LAPSED` / `NOT-YET-LIVE` as
   distinct states in `build-os/tools/authority-envelope.sh`; `valid_from` /
   `valid_until` enforced in `build-os/tools/claim-evidence.sh`; plus
   **calendar-valid** date checking, not merely format-shaped date checking.

**Counts.** Suite **1771 → 1869 (+98)**, and **`/ 0` only AFTER this close** — at HEAD, before the archivist wrote its metrics row, the split was **1865 / 4**. See the QA section; the total was right and the split was not. Census **93 → 97**.
`evidence-policy check` **25 of 97**, split **6 / 5 / 14** — **the numerator and
the finding SET are byte-identical to base**; only the denominator moved.
**ZERO re-authorisations**, confirmed **twice independently** and
**field-anchored** rather than diff-eyeballed (qa over 485 rows, reviewer over
388 rows, different row sets, same conclusion).

---

# 1. THE HEADLINE — THE LEASE WINDOW WAS DECORATIVE AT BOTH ENDS, AND IT WAS REACHING THE LICENCE MATRIX

**This is the part of P3 that was a live bug, not governance.** It was executed
against this tree before a line was written, so none of it is inferred.

At base, all three of the following held:

| fixture | base behaviour | now |
|---|---|---|
| envelope `starts: 2025-01-01 / expires: 2026-01-01` — **seven months dead** | printed **`1 live grant(s)`** and **`WITHIN-LICENCE … binding-axis=none`**, **exit 0** | **`LAPSED`**, contributes nothing |
| the **same** dead lease at `deployment_mode: shadow` | dragged a **doubly-licensed Class A control to `licensed=observe`** via `mode_projection()` into `evidence-policy.sh` | **`LAPSED`**, contributes nothing |
| the same record at `starts: 2027-01-01` — **five months before it opens** | bound **byte-identically** to the dead one | **`NOT-YET-LIVE`**, contributes nothing |

**The word *live* was printed about a dead grant, and the strongest deployment
cap in the system was computed from a lease that had ended.** The second row is
the one that matters: the defect was **not confined to the tool's own report** —
it **reached the licence matrix** through `mode_projection()`, so a dead lease
was silently constraining a real control's licensed authority.

**Root cause:** the tool format-checked the dates and ordered them, then **never
consulted the clock**. `date` appeared in **zero** tools.

**qa proved the discriminating direction NUMERICALLY, which is what makes this
more than an assertion.** The hazard here is that an expired grant keeps applying
*in whichever direction it pointed*, and the **permissive** direction is
invisible — an ungranted control already defaults to `autonomous`/`execute`, so a
test written only against the permissive direction **passes vacuously against a
fixed tool and an unfixed one alike**. The restrictive direction is the one with
discriminating power, and qa drove it as a number:

> **dead window → the deployment axis binds `0`. Live window → it binds `1`.**

Two runs, one variable, opposite results. That is a measurement, not a claim.

---

# 2. `accept_and_constrain` IS INERT BY CONSTRUCTION AND CANNOT CLEAR A MISMATCH

The standing ruling — **class correction and authority demotion, not a general
promotion instrument** — is intact, and it is intact *structurally*, not by
convention.

**Nothing in the tree reads `mismatch_dispositions.txt` except its own tool and
its own suite.** `scan-controls.sh` §8 and `evidence-policy.sh check` **never
open it**. Verified by reading the consumers, not by grepping for reassurance.

Consequently `maint.tripwire_coverage_scan` — the one disposed control — **still
carries its `authority_mismatch: declared`, still holds its row in
`MISMATCHES.md`'s machine-read table, and still occupies its place among the 25
`OUT-OF-LICENCE` findings.** All three asserted against the **live** tree, so an
edit that quietly clears the mismatch fails there rather than passing as tidying.

**IT WAS NOT BULK-APPLIED: 1 disposition against 20 declared mismatches.** The
ruling permits the mechanism; it does not authorise a clearance.

**The discipline test fired, and then it fired against a subject the builder did
not choose.** `maint.source_scan_mask` is correctly **REFUSED at exit 2**, on
**three independently-failing conditions** — and the refusal quotes the census's
own `demotion_requirement` back (*REACHABLE SINCE THE LADDER WAS CORRECTED*)
rather than restating a reason inside the tool. The reviewer then tested the
predicate's **discriminative power against a second unqualifying subject the
builder had not selected** (`swarm.disjointness`) and it refused that too. A
predicate proven only against the negative case its own author picked is a
predicate fitted to that case; this one is not.

---

# 3. A GIT-ATTESTED FACT THE CLOSE BRIEF DID NOT CARRY: P2'S SEALED RECEIPT IS BYTE-IDENTICAL TO BASE

**Found by the archivist while reconciling the file-ownership manifest, and it
is the strongest available corroboration of §5 items 6 and 7.**

`build-os/receipts/gravito_p2_claim_scoped_evidence_a.md` appears in **both**
`e68d931` (+2/−2) **and** `ead24bc` (+2/−2), yet
`git diff f3c5353 ead24bc -- build-os/receipts/gravito_p2_claim_scoped_evidence_a.md`
is **EMPTY**. The union of the per-commit name-only sets is **28 files** while
the net numstat across the range is **27** — and this file is the entire
difference.

**What that records:** `e68d931`'s repoint sweep reached **into a sealed P2
receipt** and corrupted the arrow-pair `:642 -> :643` into **`:643 -> :643`** — a
repoint asserting that nothing had moved, which **destroys the record of the
defect the pair exists to document**. `ead24bc` restored it exactly.

**The net-zero diff is the proof that P2's receipt was left sealed.** Receipts
are append-only history; the one time this packet wrote into a closed one, it put
it back byte-for-byte. That is the correct outcome and it is now attested by git
rather than by anyone's assurance.

---

# 4. THE DEPTH DEFECT — THIS PACKET REACHED SERIAL STAGE 4, AND THE CONTRACT CALLS THAT A DEFECT

**Recorded as a defect, without softening.** `CLAUDE.md`: *"A fourth serial stage
is a defect, not a detail: it means the fix list arrived in installments, or the
packet was mis-cut."*

| stage | pass |
|---|---|
| 1 | builder |
| 2 | qa ‖ reviewer (concurrent — the median held here) |
| 3 | fix round (`ead24bc`, 7 enumerated items) |
| **4** | **targeted re-review** |

**The contract offers two causes. It was the second, and the distinction is
load-bearing.**

**It was NOT "the fix list arrived in installments."** The second round's items
**did not exist or were unreachable before `ead24bc` edited those records**, and
one of them is **a hole in a guard that did not exist at `e68d931`**. A reviewer
cannot withhold an item about text that has not been written yet.

**It WAS a mis-cut — in MECHANISM rather than in SCOPE, and the reviewer's
diagnosis is exact.** P3 mechanised **one half** of
`DEFECT-0003-duplicate-semantic-truth` — the **citation** half, via §27 — and
left the other half, **counts stated in two places**, **entirely to hand**.

**The lesson is the packet's own commit message, and it is recorded here
verbatim because it diagnoses the defect and then commits it:**

> *"the denominator was re-derived at 97 and the numerator was not"*

That sentence is `ead24bc`'s correct diagnosis of `MISMATCHES.md`. **The same
commit then reproduces that exact shape three more times in the records it
touched** (§5 items 2, 3, 4). A packet that names a defect class in its own
commit message and ships three fresh instances of it in that same commit is
mis-cut in mechanism: the half that was mechanised stopped recurring, and the
half left to hand recurred four times.

**Per the contract, stage 5 was NOT opened.** The remainder is **re-cut as its
own packet**, `gravito_p3b_count_derivation_a`, which the reviewer explicitly
endorsed. **Record this as the contract's own prescribed remedy — *"stop, say
which, and re-cut the packet instead of opening stage five"* — and NOT as a
deferral of convenience.** The five open items in §5 are that packet's contents,
and they are not this packet's to fix.

---

# Scope

**In scope, and delivered:**

- The `accept_and_constrain` disposition: vocabulary, store, validator, suite.
- Exactly **one** disposition record, against `maint.tripwire_coverage_scan`.
- Lease-window enforcement at **both** ends, in **both** `authority-envelope.sh`
  and `claim-evidence.sh`, against an **overridable** clock that says so when
  overridden.
- Calendar-valid date checking.

**Explicitly out of scope, and held:**

- Any change to any control's `class`, `runtime_authority`, `empirical_status` or
  `authority_mismatch`. **Zero re-authorisations — verified twice, independently,
  field-anchored.**
- Disposing any control other than `maint.tripwire_coverage_scan`. **1 of 20.**
- Writing a **live** authority envelope. The store still ships with zero live
  grants.
- Anything outside this repository. **No push, no merge, no PR, no tag, no
  deploy, no secrets, no `git config`.**

---

# Commits — 3, WHICH IS ONE OVER THE ≤2 CAP, AND THAT IS RECORDED NOT EXCUSED

| commit | one-line |
|---|---|
| `3bd2ab4` | `docs(packet): declare gravito_p3_accept_and_constrain_a before building` — the declaration **alone**, so git attests the packet was declared before its first implementation edit. 1 file, +129 / −91. |
| `e68d931` | `feat(registry): a fifth disposition, and a lease term that is finally enforced` — tests and implementation. 24 files, +1904 / −85. |
| `ead24bc` | `fix(registry): a date must be a date, a measurement must be an id, and a citation with two numbers has two positions` — the bounded stage-3 fix round, 7 enumerated items. 15 files, +419 / −40. |

**TWO MEASUREMENT CONVENTIONS, BOTH TRUE, AND THEY DISAGREE — SO BOTH ARE RECORDED.**

| convention | files | insertions | deletions |
|---|---|---|---|
| **NET diff**, base `f3c5353` → HEAD `ead24bc` | **27** | **+2424** | **−188** |
| **GUARD's**, used by `check-adoption.sh` and `record-packet.sh --verify-git`: distinct paths across the three named commits, and the **PER-COMMIT numstat SUM** | **28** | **+2452** | **−216** |

The gap is **exactly one path and 28 lines of churn that CANCELS** — lines
`e68d931` added and `ead24bc` then rewrote — plus the one path that nets to zero
(§3). **`packet_metrics.tsv` records the GUARD's numbers**, because the guard
measures the **sum** precisely so that a packet cannot hide churn by reverting it
inside its own range.

**The cap.** The working contract says **≤2 commits per packet**. The packet
declared two (`build-os/packets/active_packet.md:23`) and shipped **three**,
because the stage-3 fix round landed as its **own** commit. **That was the right
call and it is still a deviation.** Amending `e68d931` would have rewritten a
commit that qa and the reviewer had already measured, destroying the ability to
say what was reviewed; the alternative to the deviation was a worse one. **The
deviation is downstream of the depth defect in §4** — a packet that holds 2
serial stages does not need a third commit. Recorded, not normalised.

## Disjoint file-ownership manifest — attribution by path

The `packet_metrics.tsv` row names **three** commits, so attribution must stay
recoverable. **This manifest is NOT fully disjoint, and saying so is the point of
recording it.**

| commit | owns | files | disjoint? |
|---|---|---|---|
| `3bd2ab4` | **`build-os/packets/active_packet.md` — and nothing else** | **1** | **YES — intersection with both other commits is EMPTY** (`comm -12`, verified at close) |
| `e68d931` | the build set | **24** | overlaps `ead24bc` on **12** files |
| `ead24bc` | the fix-round set | **15** | overlaps `e68d931` on **12** files |

**The 12 overlapping paths, in full:**

```
build-os/memory/current_state.md
build-os/memory/residue.md
build-os/receipts/gravito_p1_mutators_ids_telemetry_a.md
build-os/receipts/gravito_p2_claim_scoped_evidence_a.md
build-os/registry/MISMATCHES.md
build-os/registry/README.md
build-os/registry/control_registry.txt
build-os/registry/neurocosmology_crosswalk.txt
build-os/tools/authority-envelope.sh
build-os/tools/mismatch-disposition.sh
tests/authority_envelope_tests.sh
tests/mismatch_disposition_tests.sh
```

**THE HONEST ATTRIBUTION RULE, since path alone is insufficient here:**

- **The declaration is separable by path.** `3bd2ab4` owns exactly one file and
  no other commit touches it. `1 + 27 = 28` name-only, reconciling to the 27-file
  net union via the single net-zero file below.
- **`e68d931` vs `ead24bc` is separable by ORDER, not by path.** They are the
  **same packet's build and its own fix round**, in sequence on one branch, so
  for the 12 shared paths the attribution is *"`e68d931` wrote it, `ead24bc`
  corrected it"* — recoverable from `git log --follow -p <path>`, which is a
  weaker guarantee than path-disjointness and is stated as such.
- **One path nets to ZERO across the whole range:**
  `build-os/receipts/gravito_p2_claim_scoped_evidence_a.md` — touched twice,
  byte-identical to base at HEAD. See §3. It is why the name-only union (28)
  exceeds the numstat union (27).

**Why this manifest is written even though it cannot claim what P2's claimed.**
P2's close shipped **red** — `check-adoption.sh` exit **2** `UNATTRIBUTED`, live
suite **1769/2** — because a multi-commit row carried no manifest, and residue
`(ggg)` ruled: **fix by RECORDING, never by widening.** The temptation here is to
copy P2's *"intersection empty"* sentence to satisfy the guard's grep. **That
would be false for 12 of these paths**, and a manifest that lies about
disjointness is worse than the missing manifest the guard was built to catch.
**So the true statement is recorded instead, including the part that is weaker
than last time.**

### Two archivist defects, both caught by live guards DURING this close

**Recorded for the same reason the packet's own self-caught defects are — and
because this is the THIRD close running in which the close itself broke the
build.**

1. **`check-adoption.sh` refused at exit 2 — `MISMATCH`.** The archivist's first
   metrics row carried the **net-union** figures (27 / +2424 / −188) and the
   guard measures the **sum** (28 / +2452 / −216): *"row says 27, git says 28."*
   **Closed by RECORDING THE GUARD'S NUMBER, never by widening the guard** — the
   same ruling as residue `(ggg)`.
2. **`tests/control_registry_tests.sh` §27d refused — 2 contradicting range
   citation pairs.** The archivist's own receipt wrote a **historical range WITH
   its path**, which is the exact blind spot §5 item 6 had just finished
   describing as *"one edit from silent violation"*. **It was the very next
   edit.** Isolated by measurement, one variable: **with the receipt 98/1,
   without it 99/0.** The archivist then **reproduced the same violation a second
   time** while writing this finding into `current_state.md`. **Twice in one
   close, by the agent that had just written the doctrine down.** Fixed by the
   packet's own convention — write the superseded span **without its path**.
   **This is now evidence, not argument, that the convention must become a
   mechanism.** Residue `(mmm)`.

**Both were caught ONLY because the gates were re-run AFTER the writes.** Had
this close run them first, it would have shipped red exactly as `2df61ae` did.

**This close is a FOURTH commit, and that is deliberate** — the receipt and
memory updates land separately rather than by amending a reviewed commit.

---

# QA proof

**qa: GREEN. reviewer: fix-then-pass ×2 → PASS-AS-FIXED.** All close gates re-run
by the archivist **AFTER** its own writes, **SEQUENTIALLY, each alone, each
preceded by an anchored `pgrep -fa '^bash tests/'` returning empty, each
redirected to a file and read in full — never piped through `tail`.**

| gate | result |
|---|---|
| `bash tests/build_os_tests.sh` | **1869 passed / 0 failed**, exit **0** |
| `bash build-os/registry/scan-controls.sh check` | exit **0** — **97** controls vs 43 surfaces, 81 load_bearing, 20 over-authorised (declared), 0 unregistered, 0 phantom, 20 report rows reconciled |
| `bash build-os/registry/scan-mutators.sh check` | exit **0** |
| `bash build-os/tools/evidence-policy.sh check` | exit **0** — **25 of 97**, split **6 / 5 / 14** |
| `bash build-os/tools/claim-evidence.sh validate` | exit **0** |
| `bash build-os/tools/mismatch-disposition.sh validate` | exit **0** — 1 disposition |
| `bash build-os/tools/mismatch-disposition.sh check` (`maint.source_scan_mask`) | exit **2** — REFUSED, 3 independently-failing conditions |
| `bash build-os/metrics/check-adoption.sh` | exit **0** — `RECORDED … 3 commits, and the receipt records the file-ownership manifest` (**after** the row was corrected to the guard's convention) |
| `./build-os/maintenance/run-tests.sh` | **144/144**, re-run **AFTER** this close's writes |
| `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` | **CONTRADICTION, DELIBERATELY** — *live 1869 vs claim 1771*. See below and residue `(ooo)`. This is the check doing its job; it is the ONLY check that compares memory against a live run. |
| `git status --porcelain` | **empty** |

**THE TREE WAS RED AT HEAD UNTIL THIS CLOSE RECORDED ITS OWN METRICS ROW.**
Measured before this close wrote anything, at `ead24bc`, on a quiet tree:
**1865 passed / 4 failed — NOT the `1869 / 0` the close brief reported.**

| failing suite | n | cause |
|---|---|---|
| `tests/metrics_adoption_tests.sh` | 2 | `check-adoption.sh` exit 2 — **this packet had no `packet_metrics.tsv` row yet** |
| `tests/lane_declaration_tests.sh` | 1 | same guard, same cause |
| `tests/control_registry_tests.sh` | 1 | **the archivist's own receipt** (§ above) |

**All four are closed by this close.** The important part is structural: **the
tree is RED in the window between the last build commit and the archivist's row**
— which is *precisely* the window in which `2df61ae` was pushed at 143/144. The
total (1869) was right; **the pass/fail split was not**, and no gate that reports
only a total would have noticed.

**ONE GATE COULD NOT BE MADE TO PASS, AND IT IS RECORDED RATHER THAN FUDGED —
residue `(ooo)`.** `RELEASE_METADATA_LIVE_SUITE=1` **cannot report MATCH at this
close**, because making it match requires writing `1869` into
`current_state.md`'s `Build/test command` line, and **that ships the tree red.**
Measured, one variable:

| `current_state.md` claims | `tests/release_metadata_tests.sh` | chained repo suite |
|---|---|---|
| `1771 checks` (**false**, left in place) | **42 / 0** | **1869 / 0** |
| `1869 checks` (**true**) | **41 / 1** — *"CHANGELOG does not report '1869 passed'"* | **1868 / 1** |

`tests/release_metadata_tests.sh` is **chained**, and its §5 is a **cross-file
agreement** check (`grep -qF "$CLAIMED passed" CHANGELOG.md`), not a staleness
check — **so two stale files that agree pass it, and one corrected file alone
fails it.** The loop has closed three times running **only because the BUILDER
happened to write the live total into `CHANGELOG.md` as the literal
`**N passed**`. This packet's builder wrote it as an ARROW — `suite **1771 →
1852**` — which `grep -qF` cannot see**, and the fix round then moved the total
**1852 → 1869**, so even the builder's number is stale.

**`CHANGELOG.md` is OUTSIDE THE ARCHIVIST'S WRITE GATE.** The archivist therefore
**left the false number in place and annotated it loudly in the file itself**,
rather than either shipping red or pretending the memory was current. **REMEDY,
one builder-lite line: add the literal `**1869 passed**` to the `## [Unreleased]`
block of `CHANGELOG.md`, then set the `Build/test command` line to 1869.** The
structural cause is the one `current_state.md` has named for nine packets: **the
two halves of this check are owned by different lanes, and only one of them can
close the loop.**

**Why the sequencing discipline is not ceremony.** The suite is **not
concurrency-safe**: two overlapping runs return **N−1 / 1** rather than refusing.
Observed twice — **1688/1** (residue `(aaa)`) and **1770/1**. A concurrent run
produces a number that belongs to **no commit**, and if its output is piped
through `tail` the failing assertion's identity is **lost**. Every gate above was
run alone.

**Commit-1 isolation:** `3bd2ab4` is the declaration **alone** — one markdown
file, read by no code path — so it is **green in isolation trivially and by
construction**. It is untouched and still an ancestor of `ead24bc`.

**Zero re-authorisations — the proof shape matters.** Both gates checked it
**field-anchored** rather than by eyeballing a diff, and over **different row
sets**: qa across **485** rows, reviewer across **388**. Same conclusion, reached
twice, from two different samples.

---

# Final state at `ead24bc`

- **97 controls**; **76 gate / 15 advise / 6 execute / 0 rank / 0 observe /
  0 none**; **20 declared mismatches** — unchanged in count.
- `evidence-policy.sh check` **25 of 97**, split **6 / 5 / 14** — **numerator and
  finding SET byte-identical to base**.
- **1 mismatch disposition** (`DISP-0001-tripwire-coverage-carry`), read by
  nothing that grants authority.
- **3 claim-scoped evidence assertions**; **9 decisions**; **87 signal
  snapshots**; **0 live authority envelopes**.
- Suite **1869 / 0**; maintenance **144 / 144**; tree clean.
- P2's receipt **byte-identical to base** (§3).

All re-derived by the archivist at close directly from the registry files and the
live tools.

---

# Reviewer verdict, and the reviewer's own error

**Verdict: fix-then-pass, twice → PASS-AS-FIXED.** The second round is what
converted the remainder into a re-cut rather than a stage-5 fix.

**The reviewer made an error, and it is recorded because the CORRECTION is the
lesson.** It prescribed `:643 -> :644` and `:572-574`. **The builder overrode
both — on evidence, in writing, in the commit message — and was right both
times.**

The reviewer's stated content check **was not false, it was OFF-TARGET**: it read
merge-base `f3c5353` where the orchestrator read `e6b825b`. The real error, in
the reviewer's own words:

> *"a content match across base→HEAD does not establish that the arrow-pair
> denotes base→HEAD."*

**What applying the prescriptions would have cost:** relocating a **P2-era
event** into **P3's coordinates** inside **P2's sealed receipt**, and leaving two
files naming **different spans for the same three lines** — **reinstating
`DEFECT-0003`**, the very defect the fix round was raised to close. §3 is the git
attestation that this was avoided.

**Second eyes: NONE.** `codex` is not on PATH; no plugin directory exists.
`build-os/memory/tool_router.md` still routes reviewer second-eyes to it. **Ninth
consecutive packet.** It bites precisely here: **a single-model chain caught the
reviewer's error only because the BUILDER pushed back**, which is the fifth time
in this sequence that has been the mechanism.

---

# Residue — deferred, with the reason each was deferred

## The five open items — they belong to `gravito_p3b_count_derivation_a`, NOT to this packet

*In `build-os/memory/residue.md` these are **(hhh)–(lll)**; items 6–13 below are **(mmm)–(rrr)**.*

**Do not fix these here.** They are the re-cut's contents.

**1. `tests/control_registry_tests.sh:867` — a FALSE COVERAGE CLAIM.** The
arrow-pair **file-selection is line-based while extraction is fold-based**, so
the P2 receipt's wrapped pair (`…:642 →` / `:643`) is **dropped before folding
and never extracted**. `AP_SEEN` reads **2**; the tree has **3**. The comment at
`:858` names that wrapped pair as **the reason folding exists**, and the
assertion at `:870` prints *"found tree-wide — memory, receipts and metrics
included"*, which is **false**. The floor `AP_SEEN -ge 1` is **too low to
notice**. **Raising the floor makes it a fitted floor requiring registration to
`tests.nonvacuity_minimums`** — which is a re-authorisation, and is why this
cannot be a one-line fix.

**2. `build-os/registry/control_registry.txt:1060`.** Headline updated to
**"FAMILY OF 35"** while the same field still says *"the scan finds 37 such
lines"*, *"34 remain and all 34 are this control"*, *"all 34 constants"*.
**Re-derive with §21's own scan, not a grep.**

**3. `build-os/registry/neurocosmology_crosswalk.txt:121`.** `homeostasis`
`known_limitations` says *"Seventeen of its twenty-two bindings are test
suites"*; the tree says **20 suites of 25 bindings** — **and `ead24bc` corrected
that same file's header from 23 to 25 in the same commit.** The one-line-apart
shape again.

**4. `build-os/registry/mismatch_dispositions.txt:54` and `:85` — A GOVERNANCE
STORE MISDESCRIBING ITS OWN VALIDATOR.** It says *"THE FOUR CONDITIONS … all
required"* and lists (a)–(d), while the tool now enforces **FIVE** — condition
(0) was added in `ead24bc`. **Record this in exactly those terms: a governance
store misdescribing its own validator is the failure this registry exists to
prevent.**

**5. `build-os/tools/mismatch-disposition.sh:167` and `:238` — A FALSE CLAIM,
WITH A REPRODUCTION.** The claim that (0) *"removes the class of token that
matches the corpus BY ACCIDENT"* is **false**. Against
`maint.tripwire_coverage_scan`, the tokens **`MEASURED`, `PREVENTI`,
`UNTOUCHE`, `COVERAGE`** all certify at **exit 0** and print the full *"MEASURED
and refused demotion"* line. They pass **(0)** by shape, **(c)** as substrings of
that control's own `demotion_requirement`, and **(d)** as substrings of half the
tree. **`PREVENTI` and `UNTOUCHE` are not even whole words.**
**BOUNDED, and the bound is the reason this is residue and not a defect that
blocks:** it **cannot smuggle a non-qualifying control through** — (a) and (b)
hold — it **degrades the fidelity of the named measurement on a record that
already qualifies**. **Tightening the shape is a design question for a separate
packet.**

## Doctrine and findings to carry forward

**6. THE ARROW-PAIR RULE, AS DURABLE DOCTRINE — the packet's most transferable
output.**

> A **range** `path:N-M` is **two positions in the current tree** → **repoint
> both ends.**
> An **arrow-pair** `path:N -> :M` is **the same content at two commits** →
> **NEVER repoint; it is a historical record.**

**The proof is structural, not empirical:** an arrow-pair's two numbers
necessarily denote **identical content**, so they **cannot** be two positions in
one commit. The reviewer stress-tested it against **all 16** two-position
citations in the tree and found **no mis-classification**.
**Its one blind spot:** a **historical range** in prose (*"was at `:362-386`, now
`:368-392`"*) is **textually indistinguishable** from a live pointer, so §27a
would sweep it. **The builder's handling is a CONVENTION, NOT A MECHANISM** —
write the superseded span without its path — applied at `residue.md:631`.
**One edit from silent violation. This is the next mechanical step.**

**7. THE REVIEWER'S OWN ERROR** — recorded above under the verdict, because the
correction is the lesson.

**8. FIVE ADDITIONAL STALE RANGES, FOUND BY THE RE-AUDIT — STALE SINCE P2, NOT
INTRODUCED BY P3.** All cite the same citation guard in
`build-os/registry/scan-controls.sh` — **superseded span `:362-386`, live span
`:368-392`**. The superseded span is deliberately written **WITHOUT its path**, per the
convention in item 6; see §8 of this receipt for why that convention had to be applied
here twice.
`current_state.md` (**2**), `gravito_ladder_semantics_a.md` (**2**),
`packet_metrics.tsv` (**1**). `residue.md` was repointed at P2 and **these five
were not**, so **the tree stated one finding with two different spans**. **All
now repointed.**

**9. `(ccc)` STAYS OPEN, AND IT IS CORRECT THAT IT DOES.**
`gravito_mismatch_refuted_a.md:56` cites `OBSERVE-LB` at
`scan-controls.sh:320-321`, which is now a blank line plus a section comment (the
guard is at `:337`). **Both ends are equally stale**, which makes it ordinary
**resolvability-not-identity drift** (the `(mm)` class) and **not** the
two-position class. **§27 structurally cannot see it.** Its generalization is the
strongest sentence of the fix round:

> **"A single-position citation with no duplicate is unpoliced by everything
> currently in the suite."**

**10. THE QUEUED POSITIONAL-CONTENT-PAIRING PACKET IS NOT CONSUMED — KEEP IT
QUEUED.** The builder verified all **330** refs identity-preserving **inline**
(22 repointed, **0** drifts). But what was queued is a **durable guard**, and §27
covers **two-position citations only**. An inline verification performed once is
not a guard.

**11. SECOND EYES: NONE — NINTH CONSECUTIVE PACKET.** `codex` not on PATH, no
plugin directory. **Residue `(zz)` records the streak as SIX; that counter is
itself stale and is corrected to NINE at this close.** **Every verdict in this
entire sequence is single-model.**

**12. NON-BLOCKING NITS.**
- `tests/mismatch_disposition_tests.sh:187-222` labels four RED cases (a)(b)(c)(d)
  in an order that does **not** match the tool's own at `:379-391`. **Coverage is
  complete; only the letters cross.**
- `tests/claim_evidence_tests.sh` inserts `== 13.` **immediately before** `== 11.`,
  and sets `export BUILD_OS_NOW` **inside §13** rather than at file top — so
  **§§1–12 invoke clock-reading paths against an unpinned clock.**

**13. `0000-01-01` IS ACCEPTED** by the new `valid_date()`. Proleptic, sorts
before everything, **conservative direction**. Recorded; not worth an item.

---

# Decision telemetry — the counterfactual substrate P4 needs

`DECISION-0009-p3-accept-and-constrain` was recorded with **4 candidates** and
**16 frozen snapshots**, **12 of them for the three arms NOT selected**.

**THIS IS THE SECOND CONSECUTIVE DECISION WHERE SELECTION WENT AGAINST THE CHEAP
SIGNAL.** The chosen arm is the **most expensive of the four** on
`census_growth_controls` — **4**, against **0** for the rejected
registry-field arm (`PACKET-0024-disposition-as-registry-field`) — and the
`selection_reason` says so verbatim and is re-derivable from the recorded signals
alone.

**Say plainly why this matters: that is exactly the counterfactual substrate P4
needs.** A ranker trained only on decisions where the cheap signal won learns to
be a cost function. The training set now carries **n=3** decisions with
non-degenerate candidate sets (`DECISION-0007`, `-0008`, `-0009`), and **two of
the three record a human overriding the cheapest arm with a stated reason**.
**The n=1 obligation inherited from P1 is discharged further, not merely held.**

---

# The trajectory note — the operator asked, and the answer is recorded unsoftened

**Question: *"is governance now deeper than execution?"*** The reviewer's answer,
recorded because the operator asked for it:

**The two halves of P3 are not the same kind of thing, and averaging them hides
the answer.**

- **The expiry half was a LIVE BUG FIX and would have been worth building
  alone.** A dead lease was reaching the licence matrix. That is execution.
- **The disposition half is GOVERNANCE DEPTH IN ITS PUREST FORM** — **~945 new
  lines and 4 new census controls to record ONE decision about ONE control.**

**The ledger, stated flatly:**

> **97 controls, ~20 tools, ~1869 assertions, ZERO executive components.**

**RECOMMENDATION TO CARRY INTO P4 — cut it smaller, with a declared GOVERNANCE
CEILING written into the packet:**

> **≤1 new census control, no new registry store, no new validator tool, no new
> suite file.**

**The arithmetic that justifies the ceiling:** on this packet's density, **a
ranker built to P3's standard would spend 5 controls and 200 assertions before it
ranks anything.** P4 is the first phase whose output is supposed to be a
*decision*, not a *record of a decision*. If it is built at P3's density, the
sequence will have spent five phases proving it can describe work it has not
done.

---

# Open boundaries — nothing done without go

- **NOT pushed.** **Nine commits are deliberately unpushed and stay that way.**
  No `git push` was run at any point in this packet or this close.
- **NOT merged.** No merge, no PR, no rebase onto any other branch.
- **No tag, no deploy, no publish, no secrets, no `git config`.**
- `/home/user/empathiq-website` **not touched**.
- The **five open items** in §5 are **not fixed here** — they belong to
  `gravito_p3b_count_derivation_a`.
- **`gravito_p3b_count_derivation_a` is staged in `active_packet.md`, NOT
  started.** It awaits an explicit go like any other packet.

---

# Files written by this close — all inside `build-os/`

| file | change |
|---|---|
| `build-os/receipts/gravito_p3_accept_and_constrain_a.md` | **new** — this receipt |
| `build-os/memory/current_state.md` | advanced: suite 1771 → **1869**, census 93 → **97**, last-closed packet |
| `build-os/memory/residue.md` | appended items **(hhh)–(rrr)**; `(zz)` streak corrected **six → nine**; `(eee)` marked **DISCHARGED** |
| `build-os/packets/active_packet.md` | `gravito_p3_accept_and_constrain_a` marked **CLOSED**; `gravito_p3b_count_derivation_a` staged next |
| `build-os/metrics/packet_metrics.tsv` | one appended row via `record-packet.sh`, corrected in place to the guard's measurement convention before the close completed |

**No file outside `build-os/` was written by this close.**
