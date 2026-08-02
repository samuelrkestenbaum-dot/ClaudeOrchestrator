# Receipt — `gravito_p5b_citation_anchor_tokens_a`

- **Packet id (canonical):** `PACKET-0029-citation-anchor-tokens`
- **Date:** 2026-08-02
- **Lane:** `substantive`. **Depth: 3 serial stages** — builder; qa ‖ reviewer
  concurrently; fix round. **No stage 4.**
- **Base:** `c2d97f8` — re-verified at close: `git merge-base fbd746d c2d97f8`
  returns `c2d97f8`.
- **HEAD at close:** `fbd746d`, on `claude/project-handoff-merge-ramhds`.
- **Verdict:** **PASS-AS-FIXED.** qa returned **GREEN**; the reviewer returned
  `fix-then-pass` on **7 enumerated items**, all 7 fixed in `fbd746d` and
  verified by the orchestrator rather than by opening a fourth gate stage.
- **THIS RECEIPT CITES BY CONTENT, NOT BY POSITION**, and that is not decoration:
  it is the packet's own thesis applied to its own record. No `path:line` and no
  `path:N-M` range is written anywhere below. Every reference names the object.

---

## THE HEADLINE — THE FIRST COMPLETED PROSPECTIVE EXPERIMENT IN THIS REPOSITORY

```
ranking sealed     44b0fab   (committed BEFORE any selection could exist)
selection recorded c2d97f8   (selector: operator)
execution          df9f740 -> c76b4d0 -> fbd746d
```

`PACKET-0029-citation-anchor-tokens` was ranked **rank 1** by S1 over a candidate
set **nobody had yet chosen from**, was then selected by the operator, and was
then executed. Ranking < selection < execution held in commit order, across three
independently motivated acts.

**THE EXPERIMENT IS INTACT, AND THE ARCHIVIST VERIFIED IT TO THE BYTE AT CLOSE
RATHER THAN RESTATING THE BRIEF.** Re-derived live at `fbd746d`:

| property | verification at close | result |
|---|---|---|
| S1 report digest | `rank-candidates.sh rank --decision-id DECISION-0011-p5b-next-after-p3b` piped to `sha256sum` | `e838284e2bba52628647d0c7ddd1ed258a7aab7cc391a5ac99992ad7584eb596` |
| identical to qa's independently recorded base-run literal | qa recorded `e838284e2bba5262…` | **MATCH** |
| `rank_of_selected` | printed by the same run, exit 0 | **1** |
| ranker blob at seal / selection / build / fix | `git rev-parse <c>:build-os/metrics/rank-candidates.sh` | `5543ea88…` at **all four** |
| ranking digest | printed by the same run | `db96737e713b10d6dbc1e1e05ed8cc9f9add6d0462fb8aa812a45b64f8311f32` |
| guard 1 at close | S1's own output | excludes `PACKET-0033` only; **`PACKET-0029` ranked, not excluded** |

The digest match matters more than it looks. The ranker reads two stores this
packet never wrote, so an identical report across the whole execution is evidence
that **the thing measured was not disturbed by the thing measured**.

**AND THE CLAIM IS STATED AT ITS TRUE WIDTH, WHICH IS NARROW.** One selected rank
is **not** evidence of S1 skill. `rank_of_selected: 1` is a **single observation**,
produced by a selector who had **read the ordering** before choosing. The tool
says so in its own output. The honest claim available after this packet:

> **The first candidate S1 ranked first has now been executed and closed, so the
> ordering has begun to be falsifiable by outcome — and has not yet been
> falsified.**

That is a change of epistemic status, not a result.

---

## The packet id was DERIVED and COLLISION-CHECKED, not accepted from the brief

**The brief supplied `PACKET-0029` and told the archivist to check it anyway.**
The check was run, because it has caught a real defect before: at the P3 close an
orchestrator brief supplied an id already held by a **rejected** candidate, and
the P4 and P5 closes both caught the same shape.

**The derivation.** `build-os/packets/active_packet.md`, written before the first
implementation edit, declares `PACKET-0029-citation-anchor-tokens`. That is **not
a fresh allocation and must not be one**: it is the id `DECISION-0011` already
carries for this candidate in its own `candidate_ids` column, and the id
`DECISION-0010` carried for it before that. Minting a new id would put **two ids
on one candidate inside the store S1 reads** — the mirror of the P3 defect.

**The collision check, run at this close.** A tree-wide sweep of every
`PACKET-[0-9]{4}[a-z0-9-]*` token finds the live band `PACKET-0001`..`PACKET-0034`
plus the synthetic `PACKET-9001`..`PACKET-9999` fixture range. Within the live
band **every occurrence of `PACKET-0029` resolves to the same slug,
`-citation-anchor-tokens`** — in `decision_telemetry.tsv` (both `DECISION-0010`
and `DECISION-0011` candidate sets), in five `signal_snapshots.tsv` rows, in the
P4 and P5 receipts, in `residue.md`, in `current_state.md`, in the anchor table,
and in the section 28 assertions. **No second candidate holds it. Reuse here is
identity preserved, not a collision.**

**The receipt filename follows the tree's convention, which is the packet's
`gravito_*` slug and not the `PACKET-NNNN` id** — `ANC-0007` is a live
`receipt_id` anchor whose object is the previous packet's `gravito_*` slug, and
`check-adoption.sh` derives the store key from the receipt's `basename`. The
slug `gravito_p5b_citation_anchor_tokens_a` was **declared by the build itself**
in `residue.md`'s section heading, and was collision-checked at close: it occurs
nowhere else in the tree, no receipt file holds it, and no store row holds it.

---

## Scope

- **In.** A citation **anchor** scheme: stable semantic anchors that resolve by
  content, and the demotion of the line number from **identity** to **navigation
  hint**. Ten-field pipe-delimited anchor records declared between `ANCHOR-TABLE`
  markers in `build-os/registry/scan-controls.sh`; an `anchors` command; an
  `anchors_check` reconciliation wired onto the `check` path; one new census
  control, `registry.evidence_resolution`; a new section 28 in
  `tests/control_registry_tests.sh` driving eight identity rules.
- **Out (explicit), and each refusal is load-bearing:**
  - **Migrating the corpus.** 13 anchors against **355** still-positional
    `evidence_refs` is **3.5% coverage**. The builder refused in writing:
    *"converting the census to it would be a re-authorisation of every entry's
    evidence and is not a builder's to take."*
  - **Fixing three pre-existing defects it passed** — see the irony below.
  - **Amending guard 1's contract** — the `(uuuu)` convention. Deliberately open.
  - **A new store, a new validator tool, a new suite file, a 22nd declared
    mismatch.** Ceiling held: 0 new files, 0 new stores, 0 new tools, declared
    mismatches hold at **21**.

---

## Commits

- `df9f740` feat(registry): anchor tokens — a line number is a hint, and it is
  not an identity
- `c76b4d0` docs(memory): record what the anchor scheme closes, and the four
  things it does not
- `fbd746d` fix round: resolve the counts instead of remembering them, and
  replace a false defence with a true one

**3 commits is ONE OVER the `<=2` cap.** Recorded as a deviation and **not
normalised** — the fix round landed as its own commit rather than amending
commits the gates had already measured. `df9f740` and `c76b4d0` were not
squashed, amended or rewritten. Same deviation and same reason as P3, P4 and P5.

### File-ownership manifest — and it is NOT fully disjoint, which is said plainly

Derived at close with `git show --name-only` per commit and `comm -12` per pair.
**10 distinct paths** across the three commits.

| commit | owns | paths |
|---|---|---|
| `df9f740` (build) | `CHANGELOG.md`, `current_state.md`, `active_packet.md`, `CROSSWALK.md`, registry `README.md`, `control_registry.txt`, `neurocosmology_crosswalk.txt`, `scan-controls.sh`, `control_registry_tests.sh` | 9 |
| `c76b4d0` (memory) | `build-os/memory/residue.md` | 1 |
| `fbd746d` (fix) | `CHANGELOG.md`, `residue.md`, `active_packet.md` | 3 |

- `df9f740` ∩ `c76b4d0` = **EMPTY** (`comm -12` returns nothing). Those two are
  genuinely disjoint.
- `df9f740` ∩ `fbd746d` = **`CHANGELOG.md`, `active_packet.md`** (2 paths).
- `c76b4d0` ∩ `fbd746d` = **`build-os/memory/residue.md`** (1 path).

**So the fix round's entire 3-path set is a STRICT SUBSET of the union of the
first two commits.** For those three paths attribution is by **ORDER**, not by
path — `df9f740`/`c76b4d0` wrote them, `fbd746d` corrected them, recoverable via
`git log --follow -p`. That is a **weaker** guarantee than a disjoint manifest and
is stated as such rather than papered over with a copied "intersection empty"
sentence that would satisfy the grep and be false for three paths.

**This was a single builder in series, not a fan-out**, so the disjointness rule
that governs parallel agents was never the binding constraint here; the manifest
is recorded because the row names three commits and attribution must stay
recoverable.

---

## WHAT WAS BUILT — the design inversion

**IDENTITY IN, POSITION OUT.** Resolution is by **content**: the anchor names a
literal that must occur **EXACTLY ONCE** in its artifact.

| occurrences | outcome |
|---|---|
| 0 | `ANCHOR-UNRESOLVED` — a violation |
| 2 or more | ambiguous — **also** a violation |
| exactly 1 | resolved; the line number is **computed** |

**The line number is a return value of `anchor_resolve()`, computed at every
resolution and stored nowhere.** qa proved the negative two ways: **no field holds
a position**, and an **11-field record is refused as `ANCHOR-SCHEMA`** — so no
overflow field can smuggle a position back in. A scheme that merely *declined* to
store positions would be a convention; a scheme that *refuses the field* is a
mechanism.

**The written form is `path:line#ANCHOR-ID`, and the two halves are GRADED
SEPARATELY.** This is the whole point:

| half | meaning | when wrong |
|---|---|---|
| `#ANCHOR-ID` | **IDENTITY** | **REFUSAL** |
| `:line` | **NAVIGATION HINT** | **REPORT**, with the corrected projection printed beside it |

**That distinction is precisely the resolvability/identity split this tree has
failed to make for twelve packets.** Sections 7, 23 and 27 of the suite are every
one of them positional: §7 asks whether a number lands inside a file, §23 asks
whether the line does something, §27 asks whether a citation carrying two numbers
carries two positions. **Not one of them asks whether the line is the same object
the citation was written about**, which is why 20 of 27 drifted references passed
all of them while silently wrong.

**The corpus, derived at close from the live tool:** **13 anchor records**,
**12 live object types**, **12 resolved + 1 superseded**, **0 violations**, exit 0.
`section_anchor` carries the superseded pair `ANC-0010-a` → `ANC-0010-b`; every
one of the twelve types is **claimed by a live anchor**, not merely enumerated.

**`anchors_check` is wired on the `check` path, OUTSIDE the `anchors`
early-exit — and qa proved by MUTATION that it cannot be skipped:** renaming one
anchored literal drove `check` to **exit 2**. A guard that is only reachable
through its own subcommand is a guard nobody runs.

---

## THE EIGHT IDENTITY RULES — all red-driven. Rule 8 is the one that mattered

Rule 8 is **self-referential**, and it is the reason this packet is more than a
twelfth mechanism:

> **The packet moved lines its own sealed evidence cites, and did not invalidate
> the experiment measuring it.**

Test 28h drives `ANC-0012` across a real drift of **924 → 1189** — a drift
**caused by this very commit**, which inserted 270 lines above the anchored
assertion — and asserts both halves: that the **old position no longer carries
the content**, and that **the anchor absorbed the move**. **Executed, not
arranged.** The anchored object is the section 20 non-vacuity assertion, and at
close `scan-controls.sh anchors` resolves `ANC-0012` to its new position with the
record unchanged.

**AND THE DISTINCTION THE PACKET SLIGHTLY CONFLATES, RECORDED BECAUSE IT WILL BE
MISREAD OTHERWISE.** The **scheme property** is real. The **zero-repoint result
into `scan-controls.sh` is MANUAL.** `(qqqq)` says so itself: six net-zero edits,
*"none of them how the code would otherwise be written"* — option arms packed two
and three onto existing lines, a reconciliation body wrapped by converting a blank
line into the opening `if`. **The proof is in the same diff:** the identical
situation in `tests/control_registry_tests.sh` had **no net-zero option available
and cost 3 repoints**. Six hand-made net-zero edits are a **builder** holding a
file still, not a **mechanism** holding it still. **It will not survive the next
packet.**

---

## THE FINDING THAT NEARLY VOIDED THE EXPERIMENT — recorded in full

**`(pppp)` originally defended the packet with a FALSE SENTENCE:**

> *"none of the four is anywhere near guard 1's protected set."*

**`build-os/registry/neurocosmology_crosswalk.txt` IS one of the six entries of
`PROTECTED_SURFACE`**, protected as `...#ranker.s1_shadow_ordering` — **and this
packet wrote to it.**

**The counterfactual is knife-edge, because `touches()` matches a BARE PATH
against a protected `path#object`** — `case "$b" in "$a"'#'*) return 0 ;; esac`
returns true when the candidate's token is the bare file and the protected token
names an object inside it:

| how the sealed surface was restated | guard 1 | outcome |
|---|---|---|
| bare `build-os/registry/neurocosmology_crosswalk.txt` | **FIRES** | `PACKET-0029` excluded as `self_amendment` — **no rank 1, EXPERIMENT VOID** |
| object-scoped `...#registry.evidence_resolution` | no hit | **rank 1 stands** |

**The object-granularity reading is correct, and it rests on three things rather
than on an assertion of distance:**

1. **The write is object-scoped.** The crosswalk record this packet added is
   `control: registry.evidence_resolution`, carrying the identical key the sealed
   surface names. It is **not** the `ranker.s1_shadow_ordering` record.
2. **The seal itself already wrote at object granularity** — its own token for
   this candidate is `control_registry.txt#registry.evidence_resolution`. Reading
   the crosswalk write the same way applies **the seal's own convention** rather
   than inventing a lenient one after the fact.
3. **The protected property was NEVER VIOLATED IN FACT.**
   `ranker.s1_shadow_ordering`'s `evidence_refs` point only into
   `build-os/metrics/rank-candidates.sh`, and that file has **ZERO DIFF** across
   the packet — blob `5543ea88…` identical at seal, selection, build and fix,
   re-verified at this close.

**BUT THE CONVENTION THAT DECIDES WHETHER THE EXPERIMENT IS VOID WAS WRITTEN DOWN
NOWHERE.** Not in `rank-candidates.sh`, not in `control_registry.txt`, not in the
suite, not in any memory file. **It had been living in an agent's judgement**, and
`PACKET-0029` sat on the permissive side of it — its rank 1, the only rank S1 has
ever had executed, depends on it.

It is now open item **`(uuuu)`**, and it is **deliberately not closed**: amending
guard 1's contract is exactly the self-amendment guard 1 exists to prevent, and
`PACKET-0029` is the candidate guard 1 screened. **Widening `PROTECTED_SURFACE` is
NOT the remedy** — a predicate that refuses every subject discriminates nothing.
The remedy is to make granularity a **declared, checkable property of the seal**.

> **This is the packet's most important governance finding: a convention that can
> void an experiment must not live only in an agent's judgement.**

Guard 1 already fails closed on **absence** and on a **wildcard**, and was driven
red on four spelling aliases. **Granularity is the one way of being vague about a
surface that has no named refusal** — and it is the one that reads as legitimate
scoping rather than as evasion.

---

## THE SCOPE RULING — recorded because the operator asked for it directly

> **RULING: MECHANICAL CONSEQUENCE, NOT SCOPE GROWTH. THE EXPERIMENT IS NOT
> COMPROMISED.**

Every off-surface write is a **derived value reconciled by a live guard**, forced
by adding **exactly one** census entry:

| artefact | derived value | movement |
|---|---|---|
| registry `README.md` | stated `evidence_refs` total | 345 → 355; live count 355 |
| `neurocosmology_crosswalk.txt` | one binding per registered control | bindings 101 = census 101 |
| `CROSSWALK.md` | derived `epistemic_quality` coverage cell | 32/15 → 33/16; live 33 |
| `CHANGELOG.md` + `current_state.md` | the suite total | or `RELEASE_METADATA_LIVE_SUITE=1` goes red |
| `active_packet.md` | the packet declaration itself | — |

**0 new files, 0 new stores, 0 new tools, 0 new suite files.**

**DECISIVE FOR THE ARITHMETIC, AND IT IS ARITHMETIC RATHER THAN JUDGEMENT:**
`candidate_write_surface` is declared a `SURFACE_SIGNAL` and is **deliberately
excluded from `SIGNAL_DIRECTION`** — it contributes **ZERO POINTS**. The rank-1
score came entirely from `residue_items_closed`, `residue_ruling_satisfied` and
`census_growth_controls`. **The overrun could not have moved the score**, because
the signal it overran scores nothing. Verified at close in S1's own decomposition:

```
rank 1 PACKET-0029-citation-anchor-tokens total=4 signals=3/3 tie=no pareto=frontier
  residue_items_closed      value=2  higher_is_better  points=3
  residue_ruling_satisfied  value=0  higher_is_better  points=0
  census_growth_controls    value=1  lower_is_better   points=1
```

**Sealed signals honoured, each checked against the snapshot store rather than
the brief:** `residue_items_closed=2` (both `(mm)` and `(nnn)` carry their
annotations); `residue_ruling_satisfied=0`; `census_growth_controls=1` — **one
control, not one-plus-consequences**. The registry diff carries **exactly one
`+control:` line**, `registry.evidence_resolution`, Class **A** / `gate` /
`authority_mismatch: none`, and **zero `-control:` lines**.

**But the direction of the error is the wrong direction, and that is why it is
residue and not a footnote.** Guard 1 screens candidates **by their frozen write
surface**. A surface that **understates** is a surface that could let a candidate
through a screen its real footprint would have failed. Nothing improper happened
here; the property the guard relies on was **not true of this candidate**, and it
was not true in the **unsafe** direction.

---

## THE ORCHESTRATOR'S OWN DEFECT — recorded with provenance, unsoftened

**`active_packet.md` declared `residue_items_closed=1` from its first commit. The
sealed value is 2.**

**It was not a typo and it was not the builder's arithmetic: the orchestrator's
brief stated `1` and the file INHERITED it.**

That is **`DEFECT-0002-stale-remembered-count`**, and it landed:

- **in the artefact that declares the sealed scope** — the one place a number must
  be **resolved, not remembered**, since that file says in the same breath *"the
  scope below is the sealed `candidate_write_surface` and nothing beyond it"*;
- **inside a brief whose own instruction was *"DERIVE every count; never restate
  one."***

**The defect class demonstrated itself one level up, in the packet built to end
it.** That is the sharpest artefact of the entire sequence.

**THE WORK MATCHED THE SEALED 2; ONLY THE RESTATEMENT WAS WRONG.** Both `(mm)` and
`(nnn)` carry their annotations, and the snapshot's own `evidence_refs` field
names exactly those two items and says in the same breath why `(rrr)` and
`(bbbb)` were **not** counted.

**AND THE FIX ROUND DID THE RIGHT THING TWICE.** It **derived** the value from the
snapshot store rather than copying the correction out of the review — the
derivation is written into the file as a runnable `awk` one-liner against
`signal_snapshots.tsv` — and it **kept the wrong digit visible in a provenance
record** rather than silently overwriting it. **That record is preserved by this
close and must not be tidied away.** A count that arrives by inheritance and is
repaired by overwriting leaves no trace of how it got in, **and the trace is the
only part of this that generalises.**

---

## QA proof

All figures below were **re-derived at close on a quiet tree**, sequentially,
after an anchored `pgrep -fa '^bash tests/'` returned empty. **Never through
`tail`** — the suite is not concurrency-safe and output was redirected to files
and then counted.

- **Suite:** `bash tests/build_os_tests.sh` → **1995 passed, 0 failed**, exit 0.
  Zero `^  FAIL` lines; no `CHAINED: … [1-9] failed`. Verified **independently by
  the orchestrator at `fbd746d`**, and by qa at `c76b4d0`.
- **Delta:** **1964 → 1995 (+31)**. `tests/control_registry_tests.sh` standalone
  **99 → 130 (+31)**, all of it the new section 28. **All 18 other chained suites
  are +0.**
- **Commit-1 isolation:** green at `df9f740` — **1995 / 0** in a **fresh clone**.
  The first commit builds and passes on its own.
- **Release cross-check:** `RELEASE_METADATA_LIVE_SUITE=1` → **MATCH at 1995**.
  `CHANGELOG.md` carries the matching **unsplit** literal `**1995 passed**`, and
  `current_state.md` matches it.
- **Maintenance — two harnesses, and the label used to cover both.** qa corrected
  this and the exact commands are recorded so it cannot recur:
  - `bash build-os/maintenance/run-tests.sh` → **144 passed, 0 failed**, exit 0.
    **"maintenance 144/144" names THIS harness and never the other.**
  - `bash tests/build_os_maintenance_tests.sh` → **67 passed, 0 failed**, exit 0.
- **Scanners:** `scan-controls check`, `scan-controls anchors`, `scan-mutators`,
  `check-adoption` — **all exit 0**.
- **Snapshot chain — the recorded invocation did not exist, and qa caught it.**
  `rank-candidates.sh snapshot-verify` returns
  `s1: REFUSED — unknown command "snapshot-verify"` at **exit 2**;
  `snapshot-verify` is a **`record-decision.sh`** subcommand. The working command
  is `bash build-os/metrics/record-decision.sh snapshot-verify` → **97 snapshots
  verify** against the digest chain, exit 0. Re-run at this close: **97, exit 0.**
- **Safety grep / census:** **101** controls (`grep -c '^control: '`) — the
  forecast growth of exactly one. **21** declared mismatches (unchanged). **Zero
  re-authorisations**: the registry diff is **6 `+` lines, 0 `-` lines**, field
  anchored. **97** signal snapshots **BY ROW COUNT** (`grep -c '^SIGNAL-SNAPSHOT-'`)
  against **176** file lines — `wc -l` is not the row count, and counting *lines*
  where data has *fields* undercounts a final entry with no trailing newline.
  **11** decision rows. **9** mutator records. **0** live authority envelopes.
- **UI smoke:** **N/A** — no user-facing surface in this packet.

---

## Review

- **Verdict: PASS-AS-FIXED.** qa **GREEN**; reviewer `fix-then-pass` on **7
  enumerated items**, every one of them a **text or record correction**. No code
  changed, no test changed, and no measurement was re-run beyond the targeted
  commands. Items 2, 3 and 7 landed **outside `active_packet.md`** and were
  recorded where they were wrong: `(pppp)`'s false guard-1 sentence and the frozen
  surface's stripped object scopes in `residue.md`; rule 3's over-broad
  receipt-facing wording in `CHANGELOG.md`.
- **Codex second-eyes: NONE — the TWELFTH consecutive packet.** The reviewer
  stated it explicitly, as the router requires. `tool_router.md`'s second-eyes row
  still says *"the last nine"*; it is **twelve**. **Nothing in the suite, no
  scanner and no policy pins that literal**, so it is presentation staleness of
  the same `DEFECT-0002-stale-remembered-count` shape rather than a red gate — and
  it drifted three packets without anyone noticing, which is the point. The
  remedy is one builder-lite line, `nine` → `twelve`; editing the router is a
  **routing act rather than bookkeeping**, so the archivist named it and did not
  apply it. Streak advanced in `(zz)`.
- **Rule 3's real scope, as implemented and now as documented.** `WRONG-OBJECT`
  fires **only** when the wrongly-cited line is the anchored site of *another
  anchored object*. Otherwise the result is `HINT-STALE` **at exit 0**, with the
  corrected projection printed beside it. Safe, and declared in the source.
  `CHANGELOG.md` was narrowed to say what actually ships.
- **Product Trajectory Check (reviewer):** *"a bridgehead rather than a twelfth
  mechanism."* **Held at its true width:** today it **is** a twelfth mechanism, at
  **3.5% coverage** — but it is the **first that can express the failure at all**;
  the eleven positional checks have **no vocabulary for object identity**. The
  distinguishing evidence is not the mechanism, it is the **refusal**: the packet
  declined to migrate the corpus because *"converting the census to it would be a
  re-authorisation of every entry's evidence and is not a builder's to take."*
- **THE BUILDER REFUSED TO CERTIFY ITS OWN DIGEST MATCH, AND THAT IS RECORDED AS A
  CREDIT.** In its own words: *"I do not hold qa's base sha256 literal, so the
  re-review should compare that digest against its own recorded value rather than
  take a match on my word."* **It could have asserted it and been right** — the
  digests do match, as verified above at this close. **An agent distinguishing what
  it VERIFIED from what it BELIEVES is the discipline this entire sequence exists
  to build**, and it appeared here unprompted, in the packet about identity versus
  resolvability.

---

## Residue

### Opened by this packet

- **`(pppp)`** — the sealed `candidate_write_surface` understated the real one by
  four artefacts, **in the unsafe direction**; its original defence sentence was
  **false** and was replaced.
- **`(qqqq)`** — the anchor scheme's implementation was **deformed by the absence
  of the anchor scheme**: six net-zero edits, and 3 repoints where no net-zero
  option existed. *"The cost of positional identity is not an argument here; it is
  a diff."*
- **`(rrrr)`** — three stale prose citations found, **all pre-existing, none
  fixed**.
- **`(ssss)`** — the anchor table lives inside the module that reads it. Correct at
  13 anchors, obviously wrong at 500; **the crossing point is not measured**.
- **`(tttt)`** — `rank_of_selected: 1` held through the packet, and is still **one
  observation**.
- **`(uuuu)`** — **the object-granularity convention decides whether guard 1 fires,
  and is written down NOWHERE.** Deliberately open; see the governance finding.
- **`(vvvv)`** — **this packet moved a stale reference FURTHER out of date.** The
  section 20 assertion went **919 → 1189**, so `DEFECT-0001`'s cited `:772` is now
  wrong by **417** lines instead of 147, and `DEFECT-0003`'s cited `:774` by
  **415** instead of 145. **Mitigated** — `ANC-0012` anchors precisely that
  assertion, so the migration that repairs them now has a handle that will not
  decay again — **but the anchor packet is what did it, and a future reader must
  know.** A packet whose thesis is that positions decay proved the thesis by
  decaying two positions a further 400 lines each, in the same commit that shipped
  the remedy. Read it as the demonstration, not as an excuse.
- **`(wwww)`** — four smaller things the fix round was told to record and not
  repair, including the manual zero-repoint result and the stale router counter.

### Annotated, not closed

- **`(mm)` was RE-HEADED** to *"A DOWN PAYMENT IN MECHANISM — NOT DISCHARGED, AND
  NOT MIGRATED"*, matching its own body: **13 anchors against 355 still-positional
  `evidence_refs` — 3.5% coverage.** The reviewer's ruling: **a down payment
  labelled a down payment.**
- **`(nnn)`** — annotated, partially discharged.
- **`(ddd)` STAYS QUEUED**, verified at **3 sites**. It queues a **cross-commit**
  comparison; everything this packet built resolves **against the artifact at the
  current commit**. **Do not mark it consumed** — the asymmetry is what proved the
  sealed signal was derived rather than fitted.
- **`(zz)`** — second-eyes streak advanced **ELEVEN → TWELVE**.

### Known risks

- **THE IRONY, AND IT BELONGS IN THE RECEIPT: the anchor packet declined to fix
  three stale line references.** `DEFECT-0001-stale-line-reference`,
  `DEFECT-0003-duplicate-semantic-truth`, and `DEFECT-0002-stale-remembered-count`
  (`CROSSWALK.md`'s prose *"29 bindings, 14 instantiating"* against a derived
  33/16). All three sat **inside the `evidence_refs` prose of entries this packet
  edited**, so fixing them was one keystroke away. **Not fixing them is the correct
  disposition under the ceiling:** the packet is **frozen evidence in a live
  measurement**, and repairing defects mid-measurement is exactly the failure the
  decision arm tests for. A builder who repairs whatever he passes is a builder
  whose scope nobody can reconstruct afterwards.
- **3.5% coverage.** The mechanism exists; the corpus has not moved. The next
  packet inherits both.
- **The zero-repoint property is manual and will not survive the next packet.**
- **The `NPROJ > 0` vacuity floor is the weakest real floor in section 28** — a
  bare positive where every other floor in the section is derived or set-based.
- **A latent unanchored-substring match in the site-collision fallback.** It cannot
  fire at 13 anchors, and its direction is a **spurious refusal rather than a
  missed one** — the right direction to be wrong in.

---

## The outcome record for `DECISION-0011-p5b-next-after-p3b`

Written **through the governed path**, `record-decision.sh outcome`. **No
ranker-owned field was written** — `rank_of_selected`, `ranking_agreement`,
`ranker_skill`, `ranking_digest`, `counterfactual_regret` and `sealed_rank` own
**no column**, are **refused by both write paths**, and are **derived by the
ranker on demand**. An outcome row carrying the ranker's score would let *"the
selected packet turned out well"* be read as *"the ranking was correct"* — two
different claims that no amount of prose keeps apart once they share a row.

**AN UNKNOWN IS NOT A ZERO.** Every quantitative field is `unknown` or
`<value>@<provenance>`. A **bare number is refused**; **omission yields `unknown`,
never 0**. Nothing was written as `0@measured` that nobody measured.

| field | written | why |
|---|---|---|
| `result` | `shipped` | the packet landed and closed |
| `durability_status` | `unknown` | **no post-close audit has run** |
| `fix_rounds` | `1@measured` | stage 3, now complete |
| `review_rounds` | `1@measured` | qa ‖ reviewer, one concurrent stage |
| `defect_classes_introduced` | `unknown` | none observed, but **nobody audited for them**, and "none observed" is not "zero" |
| `defect_classes_detected` | the three named ids | `DEFECT-0001`, `DEFECT-0002`, `DEFECT-0003` — **all pre-existing** |
| `rework_count` | `13@derived` | published as a **decomposition**, below |
| `rollback_count` | `unknown` | nothing was rolled back and nothing counted it |
| `wall_minutes` | `65@reported` | ~1h05m for the **single builder pass**; **reported, not instrumented**, and it does **not** cover the fix round, the gates or this close |
| everything else | `unknown` | nobody measured it |

**`rework_count` is published as a decomposition rather than asserted**, because
`COMPARISON_PROTOCOL.md`'s definition of rework is **pass-level** while every one
of these is **artefact-level**:

| component | count | disclosed at |
|---|---|---|
| off-surface artefacts the census entry mechanically forced | 4 | `(pppp)` |
| `evidence_ref` repoints | 3 | `(qqqq)` |
| net-zero edits made only to avoid moving a line | 6 | `(qqqq)` |
| **total** | **13** | |

**The builder's prose was more honest than the builder's count** — the four
artefacts, three repoints and six net-zero edits were each written down plainly
and then summed to **2**. The components are published so a reader can
**recompute** the total instead of trusting it. A single number under a contested
definition is the thing this repository keeps catching.

**Two qualitative outcomes, recorded here rather than as a fabricated number:**

- **Identity protections realized: YES in mechanism, NO in corpus.** 13 anchors,
  eight red-driven rules, a guard that cannot be skipped — against 355 still
  positional `evidence_refs`.
- **Later line movement changed NO historical anchor.** `ANC-0010-a` still carries
  the **pre-rename** section 7 heading at **version 1**, superseded by `ANC-0010-b`
  rather than overwritten by it. History was recorded, not edited.

---

## Open boundaries (awaiting explicit go)

- **NOTHING IS PUSHED, MERGED, TAGGED, PR'd OR DEPLOYED**, and no such go has been
  given. The base `c2d97f8` sits on a branch whose tip is now local-only ahead of
  it; `df9f740`, `c76b4d0` and `fbd746d` **stay local**.
- **`c2d97f8` IS THE SELECTION ANCHOR AND `44b0fab` IS THE SEAL ANCHOR. NEITHER
  MAY BE AMENDED**, and neither may `df9f740`, `c76b4d0` or `fbd746d`. The whole
  claim of the prospective ordering is that the seal was committed **before any
  commit could carry a selection**; rewriting either end destroys it.
- **AND THE UNPUSHED STATE CARRIES EVIDENTIARY WEIGHT.** The parent-hash chain is
  non-forgeable **only once a third party has witnessed it**. Publishing is what
  would convert the seal's anchor from *"one process could rewrite this"* into
  *"a third party has seen it"* — **a push would now buy something specific, and
  it is still an operator act and is not requested here.** `(kkkk)`.
- **Nothing consumes S1's ordering.** Wiring anything to it is an operator act.
- **Selecting the next packet from any decision is an operator act.** Recording a
  selection here would move
  `prospective_decisions_with_a_recorded_selection` with **no human having
  chosen**.
- **`build-os/metrics/rank-candidates.sh` (blob `5543ea88…`) and
  `signal_snapshots.tsv` were not touched by this close**, and the archivist wrote
  nothing outside `build-os/`.
