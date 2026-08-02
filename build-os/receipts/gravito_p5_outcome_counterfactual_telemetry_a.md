# Receipt — `gravito_p5_outcome_counterfactual_telemetry_a`

- **Packet id (canonical):** `PACKET-0032-p5-outcome-counterfactual-telemetry`
- **Date:** 2026-08-02
- **Lane:** `substantive`. **Depth: 3 serial stages** — builder; qa ‖ reviewer
  concurrently; fix round. **No stage 4.**
- **Base:** `80ad634` — re-verified at close: `git merge-base adef6ad 80ad634`
  returns `80ad634`.
- **HEAD at close:** `adef6ad`
- **Verdict:** **PASS-AS-FIXED.** Reviewer returned `fix-then-pass` on 3
  enumerated items; all 3 fixed in `adef6ad` and verified live by the
  orchestrator rather than by opening a fourth gate stage.
- **P5 OF THE OPERATOR'S FIVE-PHASE SEQUENCE. THE SEQUENCE IS COMPLETE:**
  P1 ✅ → P2 ✅ → P3 ✅ → P4 ✅ (the executive *mechanism*) → **P5 — the
  transition to PROSPECTIVE ranking.**

---

## The packet id was DERIVED and COLLISION-CHECKED, not accepted from a brief

**The close brief supplied no id, deliberately.** It was derived here and checked
anyway, because this check exists for a reason: at the P3 close an orchestrator
brief supplied `PACKET-0020`, an id already held by a **rejected**
`DECISION-0008` candidate, and using it would have collided two different
candidates under one key **inside the store S1 reads**. The P4 close caught it.

**The derivation.** `build-os/packets/active_packet.md`, written at `cda95d2`
*before the first implementation edit*, declares
`PACKET-0032-p5-outcome-counterfactual-telemetry`. That is **not a fresh
allocation and must not be one**: it is the id `DECISION-0010` already carries
for this work in its own `candidate_ids` column. Minting a new id would have put
**two ids on one candidate** inside the store the shadow ranker trains on, which
is the mirror image of the P3 defect.

**The collision check, run at this close and not inherited.** A tree-wide sweep
of every `PACKET-[0-9]{4}` token finds allocations at `PACKET-0001`..`PACKET-0034`
and the synthetic `PACKET-9001`..`PACKET-9299` fixture range. Within the live
band, `decision_telemetry.tsv` allocates `PACKET-0007`..`PACKET-0033`;
`PACKET-0034` was allocated by `active_packet.md` at the P4 close and belongs to
`gravito_p4_s1_shadow_ranker_a`. **`PACKET-0032` is held by exactly one
candidate — this one** — in `DECISION-0010`, where it is recorded `excluded …
reason=self_amendment`. **Reuse here is identity preserved, not a collision.**

---

## Scope

**IN.**

- `ranking < selection < execution`, **mechanically enforced by refusals** in
  `build-os/metrics/record-decision.sh`, each driven red on its own fixture.
- The **OUTCOME arm** — outcome fields recorded against `DECISION-0010` /
  `PACKET-0027`, with every unmeasurable field left **explicitly absent in a
  named, derived category**.
- The **PROSPECTIVE arm** — an S1 ordering **sealed before any human selects**,
  over the candidate set for `DECISION-0011-p5b-next-after-p3b`.
- The **partition** of `decision_telemetry.tsv`'s columns into a SELECTION set
  and an OUTCOME set, checked against the schema at run time, failing closed.
- One census control + its mutator record + the mismatch that comes with it.

**EXPLICITLY OUT, and held out.**

- **`s1-v2` / any signal-set redesign.** The degeneracy, the lettering-granularity
  margin, the non-independence and the label leakage stay as residue.
- **`build-os/metrics/rank-candidates.sh`.** Deliberately absent from the address
  list and **byte-identical across the whole range** (see the ceiling section).
- **Widening guard 1's protected surface**, or closing its directory-prefix alias.
- **Promotion or dispatch.** S1 stays Class C / `untested` / `observe` / `shadow`;
  nothing consumes its ordering.
- **`gravito_p3b_count_derivation_a`** (`PACKET-0027`) itself. This packet records
  the OUTCOME slot for the decision that selected it; it does not do the work.

---

## Commits, branch base, and the file-ownership manifest

| Commit | One line |
|---|---|
| `cda95d2` | `docs(packet): declare gravito_p5_outcome_counterfactual_telemetry_a before building` |
| `44b0fab` | `feat(metrics): rank BEFORE the choice — the order is a refusal, not a comment` |
| `adef6ad` | `p5 fix round: shut the seal's second door, refuse a candidate holding two ranks, and narrow the git-anchor claim to what it proves` |

- **Branch base `80ad634`**, re-verified by `git merge-base` at close.
- **3 commits — ONE OVER THE `<=2` CAP.** Same deviation and same reason as P3
  and P4: the fix round landed as its own commit rather than amending commits the
  gates had already measured. **Recorded as a deviation, not normalised.** It is
  downstream of the declare-before-building convention, which is itself an
  unresolved operator question (residue `(ee)`).
- **`44b0fab` IS THE SEAL'S ANCHOR** and must not be amended. The prospective
  ordering's whole evidentiary claim is that the seal was committed before any
  commit could carry a selection; rewriting that commit destroys the claim.

### File-ownership manifest — and it is NOT fully disjoint, which is stated rather than papered over

- **`cda95d2` owns `build-os/packets/active_packet.md` ALONE.** Its intersection
  with **both** other commits is **EMPTY**, verified at close with `comm -12` over
  the sorted path sets (0 paths against `44b0fab`, 0 paths against `adef6ad`).
- **`44b0fab` and `adef6ad` OVERLAP ON ALL 8 PATHS `adef6ad` touched** — the
  fix-round set is a strict subset of the build set (`comm -13` returns nothing).
  The overlapping paths are `CHANGELOG.md`, `build-os/memory/current_state.md`,
  `build-os/memory/residue.md`, `build-os/metrics/record-decision.sh`,
  `build-os/registry/MISMATCHES.md`, `build-os/registry/control_registry.txt`,
  `build-os/registry/mutator_registry.txt`, and `tests/mutator_registry_tests.sh`.
- **For those 8 paths attribution is by ORDER, not by path** — `44b0fab` wrote
  them, `adef6ad` corrected them, recoverable via `git log --follow -p`. **That is
  a WEAKER guarantee than a disjoint manifest and is recorded as such.** Copying a
  clean "intersection empty" sentence would have satisfied the guard's grep and
  been false for 8 paths; residue `(ggg)` rules fix by RECORDING, never by
  widening, and a manifest that lies about disjointness is worse than the missing
  manifest the guard exists to catch.

### Range figures — the guard's convention, derived at close

- **14 distinct paths** across the three commits.
- **Per-commit numstat SUM: +1550 / -141.**
- **NET diff `80ad634`→`adef6ad`: 14 files / +1522 / -113.** The 28-insertion and
  28-deletion gap is churn `44b0fab` added and `adef6ad` then rewrote.
- **The metrics row records the SUM**, per residue `(ggg)`: the guard measures the
  sum precisely so a packet cannot hide churn by reverting it inside its own range.

---

## QA proof — exact counts, all re-derived at this close

| Measurement | Result |
|---|---|
| Full suite (`bash tests/build_os_tests.sh`, SOLO, full capture) | **1963 passed / 0 failed**, exit 0, zero `^  FAIL` |
| `RELEASE_METADATA_LIVE_SUITE=1` | **1963 / 0** — live-run comparison, MATCH |
| `tests/mutator_registry_tests.sh` | **147 / 0** (136 → 147, **+11**, all in section 14) |
| Suite delta over the packet | **1909 → 1963 (+54)**, all in section 14 (93 → 147; 43 at the build, 11 more at the fix round) |
| Maintenance (`build-os/maintenance/run-tests.sh`) | **144 / 144** |
| `scan-controls.sh check` | exit 0 — 100 controls vs 44 refusal-capable surfaces; 83 load_bearing; 21 over-authorised (declared); **0 unregistered, 0 phantom** |
| `scan-mutators.sh check` | exit 0 — 9 mutators, 12 defect classes, 36 stable ids |
| `evidence-policy.sh check` | **26 of 100 out of licence — class axis 6, evidence axis 5, both axes 15**, reported separately and never blended; deployment axis binds 0 from 0 live envelopes |
| Census controls (`grep -c '^control: '`) | **100** |
| Declared mismatches (`grep -c '^authority_mismatch: declared'`) | **21** |
| Class split | **A 75 / B 3 / C 22** |
| Runtime authority | **gate 77 / advise 15 / execute 7 / observe 1 / rank 0 / none 0** |
| Mutator records | **9** |
| Signal snapshots — **ROW count**, `grep -c '^SIGNAL-SNAPSHOT-'` | **97** |
| Signal snapshots — file LINE count, for contrast | **176** |
| Snapshots bound to `DECISION-0011` | **25** |
| Decision rows | **10** — UNCHANGED; `grep -c '^DECISION-0011'` returns **0** |
| `snapshot-verify` | **97 snapshots verify against the digest chain**, exit 0 |
| New files added in the whole range (`git diff --diff-filter=A`) | **0** |
| Zero re-authorisations | confirmed field-anchored — no `runtime_authority`, `required_authority`, `class`, `empirical_status` or `implementation_status` line removed from any pre-existing control |
| `CHANGELOG.md` | carries the **unsplit literal** `**1963 passed**` — `grep -qF` confirms |

**THE ROW COUNT IS DERIVED, NOT THE LINE COUNT.** `grep -c '^SIGNAL-SNAPSHOT-'`
returns **97** while the file has **176** lines. Residue `(aaaa)` records that
P2's and P3's closes reported the line count as the row count — an overstatement
of nearly 2x in the store whose entire purpose is that a later evaluation can
trust it. **That discipline is live at this close and was applied to every count
in this receipt.**

### Commit-1 isolation

**Commit 1 is `cda95d2`, a declaration-only commit** touching exactly one file,
`build-os/packets/active_packet.md`, with no implementation edit. Its suite state
in isolation is the base suite: **1909 re-measured green at Commit 1**, matching
`80ad634`. Commit-1-green-in-isolation **HOLDS**, trivially and by construction —
the declaration commit cannot break a suite it does not touch.

### Safety grep

- **No push, merge, PR, tag, deploy, or secret access** anywhere in the range.
- **No `git config`** invocation; `.git/config` carries no `email` line and was
  not written.
- Nothing outside this repository was touched; `/home/user/empathiq-website` is
  untouched.
- Read-only tool runs at close (`snapshot-verify`, `outcome-report`,
  `scan-controls`, `scan-mutators`, `evidence-policy`) left
  `decision_telemetry.tsv`, `signal_snapshots.tsv` and `residue.md`
  **byte-identical by md5 across every run** — the dispatch guarantee MEASURED,
  not asserted.

### UI smoke

**N/A — not applicable and not faked.** This packet has no frontend surface; it
writes shell tools, TSV stores, registry text and memory. There is no UI to smoke
and no screenshot is offered in place of one.

---

## ARTIFACT 1 — the sealed prospective ordering, recorded verbatim

`DECISION-0011-p5b-next-after-p3b`, rule `s1-v1`, sealed at `80ad634` over **20
frozen v2 snapshots**:

```
excluded PACKET-0033-observe-advise-boundary-recheckable  reason=self_amendment
rank 1  PACKET-0029-citation-anchor-tokens            total=4  pareto=frontier
rank 2  PACKET-0030-mutation-census-coverage-gap      total=3  tie=yes  frontier
rank 2  PACKET-0031-governance-baseline-completeness  total=3  tie=yes  frontier
rank 4  PACKET-0028-positional-content-pairing-guard  total=1  dominated_by=PACKET-0029
```

**IT HAS NO ROW IN `decision_telemetry.tsv`. NOBODY HAS SELECTED. THE ABSENCE IS
THE EVIDENCE.** `grep -c '^DECISION-0011'` on the telemetry store returns **0** at
this close, while the five `sealed_rank` rows sit in `signal_snapshots.tsv` and
chain. That asymmetry — sealed in the chained store, absent from the selection
store — *is* the artifact.

**IT IS NOT DEGENERATE, AND THAT IS THE FIRST TIME.** **3 of the 4 rankable
candidates sit on the Pareto frontier**, against `DECISION-0010`'s single
dominator that **125 of 125** weightings returned. **Weights would change this
ordering.** No monotone weighting could dethrone `PACKET-0027` in the previous
decision; several could reorder this one.

**qa RE-DERIVED IT FROM THE FROZEN SIGNALS AND IT REPRODUCED EXACTLY** —
1 / 2 / 2 / 4 / excluded. Verified again at this close by reading the five
`sealed_rank` rows straight out of the chained store: `PACKET-0029` → 1,
`PACKET-0030` → 2, `PACKET-0031` → 2, `PACKET-0028` → 4,
`PACKET-0033` → `excluded`, all `s1-v1`.

**THE CANDIDATE SET IS MECHANICALLY DERIVABLE, NOT CURATED.** It is
`DECISION-0010`'s set **minus the winner minus this packet**. The reviewer went
looking for a "chosen to be safe" story and **could not construct one** — the
membership rule leaves no discretion to exercise.

---

## ARTIFACT 2 — the outcome record, recorded verbatim

For `DECISION-0010` / `PACKET-0027`, re-run at close:

```
coverage: 3 recorded, 4 missing, 12 never-collected; declared outcome fields: 19
prospective_decisions_sealed: 1
prospective_decisions_with_a_recorded_selection: 0
ranker_evidence: NONE DERIVABLE FROM THIS REPORT
```

**Every recorded value is UNINTERPRETED** — `started_at`,
`defect_classes_detected`, `result: in_flight` — because **no outcome field in
this repository has a declared direction**, and inventing one would put an
unregistered constant inside every ordering that later read it.

**The categories are DERIVED, and the packet proved it by perturbation:** giving
an *unrelated* decision a `model_calls` value shifted `DECISION-0010`'s own report
from NEVER-COLLECTED **12 → 11** and MISSING **4 → 5**, without touching
`DECISION-0010` at all. The distinction between "nobody has ever measured this"
and "this decision did not measure it" is computed from the store, not remembered.

`ranker_evidence_precondition` states the only thing that could ever make
`rank_of_selected` evidence about S1: *"a `rank_of_selected` is evidence about a
ranker only for a decision whose ordering was SEALED BEFORE its selection. **0**
such decision(s) have since been selected."*

---

## THE HEADLINE DEFECT — the reviewer found a backdoor in the packet's own headline guard

**THE SEAL HAD TWO DOORS AND ONE GUARD.**

`seal-ranking` refused a post-hoc seal correctly. But the **`snapshot` subcommand
was an unguarded second door to the same signal.** The reviewer's **executed**
reproduction wrote a `sealed_rank` row for the already-selected, permanently
retrospective `DECISION-0010`. It **chained cleanly**. `snapshot-verify` reported
**98 snapshots verifying**. And downstream,
`prospective_decisions_with_a_recorded_selection` moved **0 → 1** — the exact
figure this packet publishes as *the only thing that could ever make
`rank_of_selected` evidence about S1*.

**A permanently retrospective decision was converted into a prospective one
through a sanctioned tool path, leaving no trace.** Unlike the *disclosed*
delete-and-re-add route — which breaks a digest and **is** evident — this route
produced **no evidence whatsoever**.

### WHY BOTH GATES WERE RIGHT — record this, it is the lesson

**qa attacked the ordering guard exhaustively and its reasoning was correct.** It
found that only the disclosed delete→seal→re-add route works: direct TSV writes
were **caught** (the guard reads store *state*, not tool provenance), casing
**caught**, reseal **caught**, out-of-band edits **caught**;
`SET-CHANGED-AFTER-SEAL` and `TIMESTAMP-CONTRADICTS-ORDER` both fire.

**But it read `decision_telemetry.tsv` for selection rows, while `sealed_rank`
lives in `signal_snapshots.tsv`. TWO STORES, ONE GUARDED.**

The **invariant** was *"a ranking cannot be sealed after a selection."* The
**implementation** was *"a selection row cannot precede a seal IN THIS FILE."*
**Those two sentences read identically right up until somebody writes to the other
file.** That gap is not a gap in either gate's diligence — it is a gap between an
invariant stated over a system and an implementation scoped to one artefact, and
it took an agent holding a *different* attack surface to see it.

### FIXED, and GENERALISED

`RANKER-FIELD-VIA-SNAPSHOT` is keyed on the tool's own `RANKER_FIELDS` constant,
so **all six** ranker-evidence fields are refused through `snapshot`, and **a
seventh declared later is closed by the same line.**

**Orchestrator-verified live**, all six exit 2 with the stores **byte-identical
after every attempt** (`cmp -s`): `sealed_rank`, `rank_of_selected`,
`ranking_agreement`, `ranker_skill`, `ranking_digest`, `counterfactual_regret`.

**And it is not over-broad**, which was verified in the same pass:
`candidate_write_surface` still writes through `snapshot`, and `seal-ranking`
still writes `sealed_rank` through the shared append primitive. **The refusal sits
on the CLI door, not on the chaining rule.**

### THE PERIMETER STATEMENT WAS WRONG, NOT MERELY INCOMPLETE

The header claimed the design was *"tamper-EVIDENT against the realistic case."*
**That was false about this path**, and the distinction matters: delete-and-re-add
breaks the chain and **is** evident; this route left the chain verifying and
produced no evidence at all. **It now states that the perimeter is the TOOL, not
the files** — every remaining route either breaks the chain or bypasses the tool,
and neither is quiet.

---

## THE OTHER TWO FIXES

- **`CANDIDATE-RANKED-TWICE`.** An ordering ranking one candidate twice
  (`1:A;2:A`) was **accepted**: only `rank=1` entered the digest chain while the
  printed `sealed_ordering:` echoed the contradictory input back. **The receipt
  and the chained evidence described different orderings.** An ordering is a
  function from candidates to positions; this one was not. Now refused **during
  the parse, before any append** — the store directory is empty afterwards, so
  nothing half-sealed ever enters the chain.
- **The git anchor, narrowed** — residue `(kkkk)`, plus five artefact sites
  softened. See the ruling below.

---

## THE GIT ANCHOR RULING — recorded precisely, because it corrects four packets' worth of prose

**GIT ANCHORS *ORDER*, NOT *INDEPENDENT AGENCY* — AND TODAY NOT EVEN ORDER
AGAINST A REWRITE.**

- **Committer identity is SELF-ASSERTED.** Verified at this close: `cda95d2` and
  `44b0fab` are the **only 2 commits authored `builder@local`** in the whole
  history; `.git/config` carries **no `email` line at all**, so the author field
  was supplied per-commit by whoever ran it. **That is exactly the shape of a
  self-reported timestamp** — which this packet rightly refused to treat as
  constitutive — **so the same reasoning refuses `%ae`.** The fix commit
  `adef6ad` correctly used the repository's default identity.
- **Commit dates are equally self-asserted** (`GIT_AUTHOR_DATE`,
  `GIT_COMMITTER_DATE`).
- **The parent-hash chain IS non-forgeable — but only once a third party has
  witnessed it, and this branch's packet commits are UNPUSHED.** Nothing external
  has seen `44b0fab`. **The anchor is UNWITNESSED, not worthless.** Precisely:
  `origin/claude/project-handoff-merge-ramhds` is at the base `80ad634`, which
  **is** witnessed; the branch is **ahead 3**, and those 3 are not.
- **P4's non-circularity never rested on git identity at all.** It rested on the
  selection being made by a **different agent, in a different packet, three
  commits before S1 existed**. **P5 has nothing comparable and cannot until
  somebody actually selects from `DECISION-0011`.**
- **THE BUILDER REPLACED THE ELAPSED-TIME FIGURE WITH THE STRUCTURAL COMMIT
  COUNT, AND THE REASONING IS THE PACKET AT ITS BEST:** the elapsed-time reading
  uses **the same self-asserted dates the item had just refused**, so it
  corroborates and cannot establish. The **commit count is structural**; the
  minutes are not. A packet that refuses a self-reported timestamp as constitutive
  and then quotes a self-reported duration as proof has contradicted itself inside
  one artefact — and this one caught that in its own prose.

---

## What else the gates established

### The partition is the strongest thing in the packet

**8 selection + 19 outcome = 27 = every column**, set-equal — verified **by
construction and by driving it**. `assert_partition` **fails closed in all three
directions**: an unowned column, a double-owned column, and a ranker field
promoted to a column. **Six ranker fields own no column**, and there are **12 / 12
refusals across both write paths**.

**`sealed_rank` is reported `UNINTERPRETED` live and derived, not hardcoded** —
**a ranker cannot score a candidate on the rank it gave it.**

### Categories are DERIVED, proven by perturbation

An *unrelated* decision gaining a `model_calls` value moved `DECISION-0010`'s own
report NEVER-COLLECTED **12 → 11** and MISSING **4 → 5** without touching it.
**`wc -l` appears nowhere in `record-decision.sh`.** The `(aaaa)` discipline is
live in code, not only in prose — the snapshot store is **97 rows but 176 lines**.

### Section 14 is red-driven, proven by mutation

Deleting the `RANKING-AFTER-SELECTION` refusal drives the suite to **135 / 1**
with *"RED FAILED: the order is documentation, not enforcement"*. Removing
**either** `OUTCOME-BEFORE-SELECTION` guard **alone** keeps it green — **defence
in depth, not a coverage gap**, and the difference between those two readings is
exactly what a mutation drive exists to settle.

### The ceiling held STRUCTURALLY, not rhetorically

- `git diff --diff-filter=A` over the whole range returns **no new files at all**.
- The residue diff has **0 removed lines** — purely additive.
- **`build-os/metrics/rank-candidates.sh` is an IDENTICAL BLOB** —
  `5543ea8851cbf0b307a11b400d832d328fe9c48b` at base, at `44b0fab`, and at HEAD.
  Verified by `git rev-parse` at all three points at this close.
- **No signal-set redesign, no promotion, no dispatch.**

### The 20 → 21 mismatch exception was PRINCIPLED — and verified, not trusted

The reviewer checked it rather than accepting it: `MUT-0006`'s base `write_scope`
really did say *"never an edit to an existing one"*, and it is preserved as a
**byte-exact prefix** rather than rewritten. `outcome` is genuinely the **first
amending write in the census**. Section 8 closes in **both** directions, and a
third route — reclassifying `class: A` → `B` — is caught by `RELABELLED`.

**THE REVIEWER'S RULING, CARRIED FORWARD UNSOFTENED: principled, but "the last one
waved through on this reasoning." P6 should hold at 21.**

### The `(cccc)` digest disposition is UPHELD

`ranking_digest` covers the snapshot store's **global** chain head, so
`DECISION-0010`'s digest moved from `2fa876c6…` to `a509eed7…` — while the
**entire S1 report differs by exactly 2 lines** (`snapshot_chain_head`,
`ranking_digest`). Every rank, tie, Pareto status and `rank_of_selected: 1` is
**byte-identical**.

**The ordering is immutable; the digest was never an identifier of it.** The
operator's condition is met **by the ordering** and was **over-claimed by the
digest** — a **claim defect, not an ordering defect.**

**Not fixing it here is correct for a reason stronger than scope:**
`rank-candidates.sh` is **guard 1's own protected surface**, and editing it in the
packet that seals a ranking is **precisely the self-amendment guard 1 exists to
prevent.** The P4 receipt is an **identical blob** at base and HEAD
(`1bcb8bf36c68fd643dc8b1f4ab297fc78a9a259f`) — **not rewritten.** Receipts are
append-only history.

---

## THE HONEST VERDICT — recorded unsoftened

> **"P5 builds the apparatus for measuring executive capability and does not yet
> demonstrate it. It cannot — the demonstration requires a human to select from
> `DECISION-0011` and the work to complete, neither of which has happened. What
> P5 legitimately delivers is the transition from *impossible to demonstrate* to
> *possible to demonstrate*, plus a first ordering that can actually be wrong."**
> — the reviewer

And residue `(hhhh)`, **written unprompted by the builder**:

> **"What P5 delivers is a decision that CAN falsify S1, not a decision that has."**

**Non-degeneracy is NOT a result.** The 20 evidence snapshots were hand-assigned
by the same builder in the same commit. The ordering is **falsifiable, not
falsified.**

**The outcome arm is thinner than the commit message suggests, and the packet says
so.** Its actual new outcome data is **one field** — `result` moving `unknown` →
`in_flight`; the other two recorded values pre-existed. Residue `(ffff)` names the
counter-temptation explicitly: writing `rollback_count: 0@measured` for work that
has not executed **would have looked like a clean run** and would have been a
fabrication. It was not written.

**Second eyes: NONE — ELEVENTH CONSECUTIVE PACKET.** The router requires the
reviewer to state it rather than silently omit it, and **the reviewer complied**.
**Every verdict in the entire five-phase sequence is single-model.**

---

## Residue

**Opened by this packet (recorded in `build-os/memory/residue.md`):**

- **`(kkkk)`** — the git anchor is narrower than four artefacts claimed; the
  remedy is **a witness** (a push, a tag a third party holds, or a second
  selector), and every one of those is an operator act.
- **`(llll)`** — `OTMP` has no `trap`. **Hygiene, not integrity:** the original is
  untouched until the `mv`, so the worst case is a stray temp file, never a lost
  or half-written record.
- **`(mmmm)`** — `DECISION-9402-proof` and `DECISION-9402` are **distinct
  identities**; nothing resolves ids by number prefix. **A stable-id allocation
  concern, NOT an ordering bypass** — neither id can reach the other's rows, so no
  seal is written after a selection and no counter moves.
- **`(nnnn)`** — `CHANGELOG.md`'s previous-release entry still says the
  `ranking_digest` reproduces. **Left standing deliberately** as append-only
  history, with the correction published above it in the same file.
- **`(oooo)`** — opened at this close; see the archivist findings below.

**Carried, unchanged, and deliberately not fixed here:** `(xxx)` degeneracy,
`(yyy)` signal non-independence, `(zzz)` guard 1's evidence-substrate blind spot,
`(cccc)` the digest claim, `(dddd)` the `result` enum, `(eeee)` no outcome field
has a declared direction, `(ffff)` the thin outcome arm, `(gggg)` "unlocked work"
has no column, `(hhhh)` falsifiable-not-falsified, `(aaa)`–`(ccc)`, `(sss)`,
`(zz)`.

**Two false-passes the builder caught during its OWN red drive — recorded because
the class matters more than the instances.** The ranker-field loop was passing
because `SIGNAL-SNAPSHOT-9281-rank_of_selected` failed the snapshot-id pattern on
its **shape** rather than being refused on its field name; and a "named in the
refusal" check was matching the **success** output. **A red drive that passes for
the wrong reason is a fresh instance of resolvability-vs-identity** — the tree's
named recurring trap — appearing this time inside the test that was supposed to
catch it.

**Follow-up packets, sealed but NOT selected.** `DECISION-0011` ranks
`PACKET-0029-citation-anchor-tokens` first, with `PACKET-0030` and `PACKET-0031`
tied at rank 2. **No selection has been made and this receipt does not make one.**
The standing next packet remains `gravito_p3b_count_derivation_a`
(`PACKET-0027`), which `DECISION-0010` already selected and which carries
`result: in_flight`.

---

## Archivist findings at this close

**1. `(oooo)` — A COUNT IN `(kkkk)` WENT STALE ONE COMMIT AFTER IT WAS WRITTEN,
AND IT IS THE TREE'S OWN NAMED DEFECT CLASS.** `(kkkk)` states that `cda95d2` and
`44b0fab` are the only two of **"the repository's 102 commits"** authored
`builder@local`. That denominator was correct at `44b0fab` and became **103** the
moment `adef6ad` — the commit that carries `(kkkk)` — landed. **The numerator is
unaffected and the item's argument is untouched**; what moved is a restated total,
which is `DEFECT-0003-duplicate-semantic-truth` in its counting form. It was found
**only because this close derived the number instead of quoting it**. Recorded as
residue `(oooo)`, **not silently corrected in `(kkkk)`** — residue items are the
record of what was known when, and this one is now annotated rather than rewritten.

**2. THE P4 BLOCK IN `current_state.md` STILL CARRIED THE CLAIM `(kkkk)` REFUTES,
AND ONE FILE HELD BOTH READINGS.** The fix round softened five artefacts, but
`current_state.md`'s *P4* block still read *"`rank_of_selected: 1` IS
NON-CIRCULAR, **PROVEN BY TIMESTAMPS** … 82 minutes later."* The same file's P5
block, eleven screens above, states that commit dates are self-asserted and
corroborate rather than establish. **Two contradictory readings of the same
evidence inside one memory file is the defect that memory file exists to
prevent.** **Annotated in place with a dated correction, not deleted** — the
history of the claim is the point — and the structural reading (different agent,
different packet, three commits earlier) is restored as the load-bearing one. The
two elapsed figures in the tree are also reconciled here so a later reader does
not read them as a contradiction: **79 minutes** is the selection anchor `5c8d19e`
to the P4 declaration `9742a10` (the structural 3-commit gap `(kkkk)` cites), and
**82 minutes** is `5c8d19e` to the ranker's creation `af4ce0c`. Different pairs,
both self-asserted, **neither constitutive**.

**3. THE ROUTER'S SECOND-EYES COUNTER IS STALE AND THE ARCHIVIST DID NOT EDIT
IT.** `build-os/memory/tool_router.md`'s second-eyes row says the absence of a
second provider was *"checked at each of the last **nine** packets."* **It is now
eleven.** The router is the orchestrator's instrument and was last corrected by a
**builder** commit (`ce71122`); editing it is a routing act, not bookkeeping.
**Remedy named, not applied: one builder-lite line changing `nine` to `eleven`.**
Nothing in the suite pins the literal, so this is presentation staleness, not a
red gate. Recorded so it is met as a decision rather than an oversight.

**4. NO KNOWINGLY-FALSE NUMBER WAS SHIPPED AND NO MATCH WAS FAKED.** The
`current_state.md` / `CHANGELOG.md` suite-total pair is **live at this close**:
this file reads **1963**, `CHANGELOG.md` carries the unsplit literal
`**1963 passed**`, and `RELEASE_METADATA_LIVE_SUITE=1` re-run **after** the
archivist's writes reports a **MATCH at 1963**. **The structural cause recorded at
P3 is untouched:** `CHANGELOG.md` remains outside the archivist's write gate, so
the loop still closes by luck of the builder's phrasing rather than by design.

---

## Open boundaries — everything below awaits explicit go

- **NOTHING PUSHED, MERGED, PR'd, TAGGED OR DEPLOYED.** `cda95d2`, `44b0fab` and
  `adef6ad` are **local-only**; the branch is **ahead 3** of
  `origin/claude/project-handoff-merge-ramhds`, which sits at the base `80ad634`.
  **Push authorisation has not been given for these three commits.**
- **AND THE UNPUSHED STATE NOW HAS EVIDENTIARY MEANING, WHICH IT DID NOT BEFORE.**
  Publishing is what converts the seal's anchor from *"one process could rewrite
  this"* into *"a third party has seen it."* Until then the ordering's
  before-the-selection claim rests on stores this repository controls. **That is a
  reason a push would now buy something specific — and it is still an operator
  act, and it is not requested here.**
- **SELECTING FROM `DECISION-0011` IS AN OPERATOR ACT AND NOTHING HERE PERFORMS
  ONE.** The sealed ordering exists precisely so that a later selection is
  comparable to it. **A selection recorded by the archivist would destroy the
  thing the packet built** — `prospective_decisions_with_a_recorded_selection`
  would move 0 → 1 with no human having chosen, which is the exact figure the
  reviewer's reproduction exploited.
- **Nothing consumes S1's ordering**, and wiring anything to it is an operator act.
- **No secrets touched, no OAuth authorised, no accounts connected, no
  `git config` written.**
- All standing boundaries from prior receipts carry forward unchanged.
