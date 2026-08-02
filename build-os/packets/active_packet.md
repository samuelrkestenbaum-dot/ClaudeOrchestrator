# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: IN FLIGHT — `gravito_measurement_integrity_a`

- **Packet id:** `PACKET-0036-measurement-integrity` — **MINTED, not reused**, and
  collision-checked **before** the mint rather than after: the live band is
  `PACKET-0001`..`PACKET-0035`, `PACKET-0035` is the highest allocation predating
  this packet, `git log -S'PACKET-0036' --all` returns **no commit**, and a
  full-tree grep for the token returns **nothing**. The id was free.
- **Base:** `a2648dc`, verified with `git merge-base` **before the first edit**
  (`git merge-base HEAD claude/project-handoff-merge-ramhds` → `a2648dc`).
- **Lane:** `substantive`. **Depth 2** — builder, then qa ‖ reviewer.
- **Declared before building, in its own commit**, per the standing contract — and
  **this commit exists because the last packet's did not.**

### Why this declaration is commit 1 and not a formality

The previous packet — the largest of the sequence — was built, gated and closed
while this file read `NOTHING IN FLIGHT` and described `PACKET-0029`. The
measurable consequence: **`bandwidth.active_packet_singleton` reported ZERO in
flight while that packet was in flight.** The guard passed, truthfully, on a file
describing the wrong packet.

That is `DEFECT-0011-undeclared-active-packet`, **`OCCURRENCE-0005`** — a
recurrence of a class this repository had **already registered**, and whose
`could_have_been_prevented_by` **already names the remedy**: a *lower* bound on
the same cardinality check, refusing zero declared packets while a build is in
flight. Only the upper bound exists. **The class has now fired twice against a
prevention that was specified and never built.**

So this commit is not bookkeeping. It is the one action that makes the guard's
`0`/`1` reading true of the world for the duration of this packet, and it is
taken first so that no measurement inside this packet is taken against a file
that is lying about what is being measured — which is the packet's whole subject.

canonical packet id: PACKET-0029-citation-anchor-tokens

**THE BARE LINE ABOVE IS NOT A DECLARATION AND MUST NOT BE DELETED.** It is the
**content site** that `ANC-0003` resolves to, and it is written on its own line
precisely so that the closed packet's identity is reachable **by content rather
than by position**. It is the packet's own scheme applied to the packet's own
record. The anchor requires that literal to occur **EXACTLY ONCE** in this file —
zero occurrences resolve as `ANCHOR-UNRESOLVED` and two or more as ambiguous, and
**both are violations that drive `scan-controls.sh check` to exit 2.** It does not
match the declaration pattern the bandwidth ceiling counts, so **it still declares
nothing in flight** — the count of `1` above comes from the `**Packet id:**` line
and from nothing else.

### What declaring this packet COST, measured rather than assumed

**Writing the declaration turned the suite red, and the red was not about the
declaration.** `tests/memory_kernel_tests.sh` §18 runs `memory-kernel.sh reconcile`
against the LIVE committed projection, and the projection embeds `ART-0003` as
`build-os/packets/active_packet.md:15#ANC-0003` — **a resolved line number.**
Adding text above the anchor site moved it 15 → 40, `cmp -s` saw two different
bytes, and the suite reported `PROJECTION-DIVERGED`. Base run: `2095 passed, 1
failed`.

**The identity half was never wrong.** `scan-controls.sh anchors` resolved
`ANC-0003` cleanly at the new position throughout — 12 resolved, 1 superseded, 0
violations — because content resolution is exactly what it was built to do. Only
the **projection** of that resolution was stale, which is the position half doing
what the anchor scheme demoted it for doing.

**The repair is the sanctioned one and not a store edit.** A projection is
generated and never hand-edited; `export-handoff --out` is a pure read that
appended **no event** and touched **no canonical store** (`validate`: 8/4/11/14/25/8/1/1,
**0 violations**; `git status` showed only the projection). `memory_events.tsv` is
untouched. **The one-line delta is the line number and nothing else.**

**This is `DEFECT-0001-stale-line-reference` reappearing inside the mechanism
built to demote line numbers**, and it is recorded here as a finding for residue
rather than fixed: every content-preserving edit above any anchored site is a
red suite until someone regenerates the shadow, so **a byte-exact reconcile of a
position-bearing projection is itself a false-negative generator** — the same
family as `DEFECT-0013`, arriving by a different route. Not in this packet's
scope to fix; **named, not normalised.**

## Branch base

Branched at `a2648dc` on `claude/project-handoff-merge-ramhds`, verified with
`git merge-base` before the first edit. **Nothing is pushed, merged, tagged, PR'd
or deployed, and no such go has been given.**

## What this packet must make true

The project's next frontier is **experience** — running
`ranking → selection → execution → outcome → memory → comparison → repeat`
repeatedly. That loop's payload is **comparison**, and comparison requires a
measurement substrate that does not lie.

`DEFECT-0013` is that substrate lying. It is **one-directional** — it cannot
fabricate a success, so every prior green stands — but **it can fabricate a
failure**, and a false "went red" written into an outcome record poisons the store
S1 will eventually train on. Its sharpest form:
`tests/release_metadata_tests.sh` compares a **live** suite total against memory,
so if the race fires there, **the guard that keeps memory honest emits a false
staleness verdict.**

Four things, and only these four:

1. **Fix the defect** at its site, without disabling `pipefail` for a whole file.
2. **Sweep the class** — `producer | … | early-exiting consumer` under `pipefail`
   — across `tests/`, `build-os/` and `.claude/hooks/`. Fix the sites that can
   actually race; **record the ones that cannot, with the measurement that says
   why.** A site is only racy if the producer can emit more than one pipe buffer.
3. **Prove the fix by measurement** — the affected assertion run **≥4000 times**
   before and after, both rates reported. "It passed once" is not evidence in this
   tree; that is the exact epistemic error this packet exists to correct.
4. **Add a guard for the class** in an existing suite, and say plainly what the
   guard **cannot** see.

And then one ruling, either way and not the flattering way: **is a single green
suite run sufficient evidence in this tree again, or does the doubled-run
discipline stand?**

## Ceiling

- Add only the controls strictly required. **Declared mismatches stand at 22**,
  and a cap on that raw total is **not** a governance instrument: `lic_of` tops
  out at `gate` for Class A and **no class licenses `execute`**, so every
  durable-write control must declare a mismatch and no packet can decline.
  **The number that constrains anybody is gate-on-advise: 14, unmoved since base.
  Do not move it.**
- **Do NOT touch `build-os/metrics/rank-candidates.sh`** (blob `5543ea88`),
  `signal_snapshots.tsv`, or `decision_telemetry.tsv`. The live experiment's S1
  report must still digest to
  `e838284e2bba52628647d0c7ddd1ed258a7aab7cc391a5ac99992ad7584eb596` at hand-back,
  with `rank_of_selected: 1` still deriving.
- **Do NOT rewrite any row in `build-os/kernel/memory_events.tsv`.** The last
  packet re-chained `EVT-0024`/`EVT-0025` in place — the exact operation its own
  `EVENT-APPEND-ONLY` guard refuses — and **`validate` returns 0 violations on
  that re-chained history**, so the kernel is blind to it and git is what caught
  it. **Corrections create later events.** Do not rely on `validate` here.
- `(ddd)` stays queued; `(uuuu)` stays open. **Fix no other residue item.**
- An unrelated defect: **record a stable defect-class identity, create residue,
  and CONTINUE.**

## CLOSED — `gravito_cross_surface_memory_kernel_v0`

- **Packet id (CLOSED):** `PACKET-0035-cross-surface-memory-kernel` — **MINTED, not reused**,
  and the mint was **collision-checked at this close rather than accepted from the brief**,
  because that check has caught a real defect before. The derivation: the live band runs
  `PACKET-0001`..`PACKET-0035`; the highest allocation predating this packet is `PACKET-0034`;
  `git log -S'PACKET-0035' --all` returns **exactly one commit**, this packet's own `d2c09c6`;
  and `git grep -l 'PACKET-0035' ea069a7` returns **nothing** — the token did not exist at the
  base. **The id was free and collides with nothing.**
- **Title:** cross-surface memory kernel v0 — governed project memory that a second surface can
  consume without the transcript.
- **Receipt:** `build-os/receipts/gravito_cross_surface_memory_kernel_v0.md`
- **Commits:** `d2c09c6` (build) + `8ba368a` (residue) + `727de75` (fix round), base `ea069a7`
  (re-verified at close: `git merge-base 727de75 ea069a7` returns `ea069a7`). **None pushed.**
- **Verdict: PASS-AS-FIXED.** qa returned **GREEN**; the reviewer returned `fix-then-pass` on
  **6 enumerated items**, all 6 fixed in `727de75` and **verified by the orchestrator** rather
  than by opening a fourth gate stage.
- **Depth: 3 serial stages** — builder; qa ‖ reviewer concurrently; bounded fix round.
  **No stage 4.**
- **THE SUCCESS CONDITION WAS EXECUTED, NOT DESIGNED: Claude closed work into Gravito memory, and
  ChatGPT consumed the governed project state without Sam copying the transcript.** The ledger
  PERFORMED the loop — `EVT-0023 HandoffCreated` (ACT-0002, `claude.cowork.session.ramhds`) ->
  `EVT-0024 ContextCompiled` (ACT-0003, `chatgpt.web.session.strategy-01`) ->
  `EVT-0025 HandoffAccepted`. **The surface changes between the first and second event and the
  actor changes with it.** qa confirmed all six section-19 questions are answerable from the
  export **alone**, found **no transcript text anywhere** in the stores, and established the
  stores were **adapter-written**: a 25-row SHA-256 chain, each digest a function of its own
  fields and its predecessor's, `recorded_at` monotonic across a **9-second window**.
- **AND THE REFUSAL THE PACKET EXISTS FOR:** `PACKAGE-STALE` refuses a package read
  `--as-current` that binds versions the project has left — *"resolvability is not identity"*,
  EXIT=2 — while the **same package read as history returns exit 0 with `state: STALE`.**
- Suite **1995 -> 2096** (+101, **all** of it the new `tests/memory_kernel_tests.sh`: 87 at the
  build commit, 101 after the fix round); census **101 -> 105**; declared mismatches **21 -> 22**;
  anchors **12 resolved / 1 superseded / 0 violations**; **zero re-authorisations**.
- **DEVIATION, RECORDED AND NOT NORMALISED: 3 commits against the `<=2` cap**, the same shape as
  the previous close. The fix round landed as its own commit rather than amending commits the
  gates had already measured. **The three commits OVERLAP** — build and fix share 10 files,
  residue and fix share 1 — so the receipt's manifest is a **sequential attribution by role, not
  a disjoint partition**. Legitimate for three serial passes by one agent; **not a precedent for
  a fan-out.**
- **DEVIATION, RECORDED AND NOT NORMALISED: THE FIX ROUND REWROTE TWO COMMITTED EVENT ROWS IN
  PLACE.** `EVT-0024` and `EVT-0025`, 2 insertions / 2 deletions, digests **recomputed** — and
  `EVT-0025`'s own fields did not change at all, which is the signature of a re-derived chain.
  **That is precisely the operation this packet's own `EVENT-APPEND-ONLY` guard refuses, and
  whose red-drive is section 3 of its own suite.** A correction event could have carried the
  anchor. Mitigating: v0 store, created here, consumed by nothing outside the packet, prior
  digests recoverable from git. **Not a stage-4 defect.** Residue `(ddddd)`.
- **`DEFECT-0013` OUTRANKS THIS PACKET AND IS NOT ITS FAULT.** The base tree is
  non-deterministic — **6.26% per invocation quiet, 19.97% under load** — via a
  `pipefail`/SIGPIPE race proven by `PIPESTATUS=[0 0 0 141 0]`. **The error is one-directional**,
  so every prior green stands and every prior red on that assertion is suspect. **A single green
  run is no longer sufficient evidence in this tree.** Residue `(ccccc)`.
- **Second eyes: NONE — THIRTEENTH consecutive packet**, re-verified at close.

## THE DECLARATION THAT WAS NEVER WRITTEN — THIS FILE'S OWN DEFECT, AGAIN

**THIS FILE READ `NOTHING IN FLIGHT` AND DESCRIBED `PACKET-0029` FOR THE ENTIRE LIFE OF THE
LARGEST PACKET IN THIS SEQUENCE.**

Every prior packet in the sequence opened with a `docs(packet): declare ...` commit **before
building**. **The orchestrator dispatched this builder without one.** The id was minted inside
the build commit; **the declaration and the in-flight record were never written here.**

**THE MEASURABLE CONSEQUENCE:** `bandwidth.active_packet_singleton` **reported ZERO in flight
while the largest packet of the sequence was in flight** — the guard passed, truthfully, on a
file that was describing the wrong packet.

**PROVENANCE: ORCHESTRATOR, NOT BUILDER.** It is recorded that way for the same reason the
`residue_items_closed=1` provenance was recorded at the previous close: **a count or a
declaration that arrives by omission and is repaired by overwriting leaves no trace of how it got
in, and the trace is the only part that generalises.**

**AND THIS IS A RECURRENCE OF A CLASS THIS REPOSITORY ALREADY REGISTERED.**
`build-os/registry/defect_classes.txt` carries `DEFECT-0011-undeclared-active-packet` at
`OCCURRENCE-0005`, whose symptom reads *"an entire packet was built while active_packet.md still
read NO PACKET IN FLIGHT, and the singleton guard passed because it refuses two declarations and
permits zero"*, and whose `could_have_been_prevented_by` already names the remedy: **a lower
bound on the same cardinality check, refusing zero declared packets while a build is in flight.**
**The remedy still does not exist, and the class has now fired twice.**

**NO REGISTRY OCCURRENCE ROW WAS WRITTEN AT THIS CLOSE.** Appending one is a registry mutation
that would move counts the gates measure, and the archivist's write scope is the receipt and
memory. **It is named here and carried as residue `(eeeee)` so the next packet records it through
the governed path rather than as bookkeeping.** Do not tidy this section away.

## CLOSED — `gravito_p5b_citation_anchor_tokens_a`

- **Packet id (CLOSED):** `PACKET-0029-citation-anchor-tokens` — **REUSED, not
  minted**, and collision-checked again at this close against every `PACKET-*`
  token in the tree. It is the id `DECISION-0011` already carries for this
  candidate, and `DECISION-0010` before that; minting a fresh one would put two
  ids on one candidate **inside the store S1 reads**.
- **Title:** citation anchor tokens — stable semantic anchors, and the demotion
  of line numbers from identity to navigation hint.
- **Receipt:** `build-os/receipts/gravito_p5b_citation_anchor_tokens_a.md`
- **Commits:** `df9f740` (build) + `c76b4d0` (memory) + `fbd746d` (fix round),
  base `c2d97f8` (re-verified at close: `git merge-base fbd746d c2d97f8` returns
  `c2d97f8`). **None pushed.**
- **Verdict: PASS-AS-FIXED.** qa returned **GREEN**; the reviewer returned
  `fix-then-pass` on **7 enumerated items**, every one a text or record
  correction; all 7 fixed in `fbd746d` and **verified by the orchestrator** rather
  than by opening a fourth gate stage.
- **Depth: 3 serial stages** — builder; qa ‖ reviewer concurrently; fix round.
  **No stage 4.**
- **DEVIATION, RECORDED AND NOT NORMALISED: 3 commits against the `<=2` cap.** The
  fix round landed as its own commit rather than amending commits the gates had
  already measured. `df9f740` and `c76b4d0` were not squashed or rewritten.
- Suite **1964 -> 1995** (+31, **all** of it `tests/control_registry_tests.sh`
  section 28, which went 99 -> 130 standalone; **all 18 other suites +0**);
  census **100 -> 101**; declared mismatches **HELD at 21**; anchors **0 -> 13
  records over 12 declared object types**; **zero re-authorisations**.
- **THE FIRST COMPLETED PROSPECTIVE EXPERIMENT IN THIS REPOSITORY.** Ranking
  sealed `44b0fab`, selection recorded `c2d97f8` (selector: **operator**), then
  execution. Ranked **rank 1** by S1 over a candidate set nobody had chosen from,
  then selected, then executed. **Verified to the byte at close:** the S1 report
  digests to `e838284e2bba5262...`, identical to qa's independently recorded
  base-run literal; `rank_of_selected: 1` still derives; and
  `build-os/metrics/rank-candidates.sh` is the same blob `5543ea88` at the seal,
  the selection and both execution commits.
- **AND ONE SELECTED RANK IS NOT EVIDENCE OF S1 SKILL.** It is one observation, by
  a selector who had read the ordering. The true claim is narrower and worth more:
  **the first candidate S1 ranked first has now been executed and closed, so the
  ordering has begun to be falsifiable by outcome — and has not yet been
  falsified.**

## THE DEFECT THIS FILE ITSELF COMMITTED — PRESERVED, NOT TIDIED AWAY

**FROM ITS FIRST COMMIT THIS FILE DECLARED `residue_items_closed=1`. THE SEALED
VALUE IS 2.**

**It was not a typo and it was not the builder's arithmetic: the orchestrator's
brief stated `1` and this file INHERITED it.** That is
`DEFECT-0002-stale-remembered-count`, committed **in the one artefact that
declares the sealed scope** — the place a number must be **resolved and not
remembered** — and **inside a brief whose own instruction was *"DERIVE every
count; never restate one."*** The defect class demonstrated itself one level up,
inside the packet built to end it.

**THE DERIVATION, WRITTEN DOWN SO THE NEXT READER RESOLVES IT RATHER THAN COPIES
THIS LINE:**

```
awk -F'\t' '$1=="SIGNAL-SNAPSHOT-0078-anchors-items"{print $6" = "$7}' \
  build-os/metrics/signal_snapshots.tsv
```

→ `residue_items_closed = 2`.

**THE WORK MATCHED THE SEALED 2 AND ONLY THE RESTATEMENT WAS WRONG.** Both `(mm)`
and `(nnn)` in `build-os/memory/residue.md` carry their annotations, and the
snapshot's own `evidence_refs` field names exactly those two items and says in the
same breath why `(rrr)` and `(bbbb)` were **not** counted.

**THE PROVENANCE IS RECORDED HERE RATHER THAN THE DIGIT QUIETLY OVERWRITTEN, AND
THE ARCHIVIST PRESERVED THAT CHOICE AT CLOSE.** A count that arrives by
inheritance and is repaired by overwriting leaves **no trace of how it got in**,
and **the trace is the only part of this that generalises.** The fix round
**derived** the value rather than copying the correction, and left the wrong digit
visible. Do not tidy this section away.

**The other sealed signals, resolved from the snapshot store and not remembered:**
`residue_ruling_satisfied=0`; `census_growth_controls=1`; `sealed_rank=1`
(**frontier, NOT dominant** — `PACKET-0030` and `PACKET-0031` tie at 2 on the same
frontier).

## What the packet closed, and the four things it did not

**IDENTITY IN, POSITION OUT.** Resolution is by **content**: the anchor names a
literal that must occur **exactly once** in its artifact. **The line number is a
return value of `anchor_resolve()`, computed at every resolution and stored
nowhere** — qa proved no field holds a position and that an 11-field record is
refused as `ANCHOR-SCHEMA`, so no overflow field can smuggle one in. The written
form grades its two halves separately: a wrong identity half is a **refusal**, a
stale position half is a **report with the corrected projection printed beside
it**. `anchors_check` is wired on the `check` path **outside** the `anchors`
early-exit, and **qa proved by mutation that it cannot be skipped.**

**NOT CLOSED, AND EACH REFUSAL IS DELIBERATE:**

- **The corpus.** 13 anchors against **355** still-positional `evidence_refs` —
  **3.5% coverage**. `(mm)` was re-headed *"A DOWN PAYMENT IN MECHANISM — NOT
  DISCHARGED, AND NOT MIGRATED"*. The builder refused in writing: *"converting the
  census to it would be a re-authorisation of every entry's evidence and is not a
  builder's to take."*
- **`(uuuu)` — the object-granularity convention that decides whether guard 1
  fires.** It is written down **nowhere**, and it is the difference between rank 1
  standing and the experiment being **VOID**. Deliberately open: amending guard 1's
  contract is the self-amendment guard 1 exists to prevent, and this packet is the
  candidate it screened. **This is the packet's most important governance finding.**
- **Three pre-existing defects** — `DEFECT-0001`, `DEFECT-0003`, `DEFECT-0002` —
  found inside prose this packet edited and **deliberately not fixed**. Correct
  under the ceiling: repairing defects mid-measurement is exactly the failure the
  decision arm tests for. **The irony is on the record: the anchor packet declined
  to fix three stale line references, and moved two of them a further 400 lines out
  of date.** `(vvvv)`.
- **`(ddd)` STAYS QUEUED** — verified at 3 sites. It queues a **cross-commit**
  comparison; everything this packet built resolves against the artifact **at the
  current commit**. **Do not mark it consumed.**

## Staged next — `gravito_p3b_count_derivation_a` (`PACKET-0027`)

**NOT A NEW SELECTION.** `DECISION-0010` selected
`PACKET-0027-p3b-count-derivation` at `5c8d19e`, **before S1 existed**, and that
selection stands. Its telemetry row carries `result: in_flight`. It has been
staged and unstarted since the P3 close, and **this close does not change its
status.**

**Still not started. Still the standing next packet. Declaring it is the
orchestrator's act, and this file declares nothing.**

## `DECISION-0011-p5b-next-after-p3b` — SEALED, SELECTED, EXECUTED, AND NOW CLOSED

**THE ABSENCE THAT WAS THE EVIDENCE HAS BEEN FILLED — BY AN OPERATOR, WHICH IS THE
ONLY WAY IT COULD LEGITIMATELY BE FILLED.** At the P5 close this decision had a
sealed ordering and **no row** in `decision_telemetry.tsv`, and that emptiness was
the proof that no agent had rationalised a choice into it. The operator then chose
`PACKET-0029` at `c2d97f8`, the packet executed, and **the outcome row for this
decision has now been written through the governed path** at this close.

```
excluded PACKET-0033-observe-advise-boundary-recheckable  reason=self_amendment
rank 1  PACKET-0029-citation-anchor-tokens            total=4  pareto=frontier   SELECTED, EXECUTED, CLOSED
rank 2  PACKET-0030-mutation-census-coverage-gap      total=3  tie=yes  frontier
rank 2  PACKET-0031-governance-baseline-completeness  total=3  tie=yes  frontier
rank 4  PACKET-0028-positional-content-pairing-guard  total=1  dominated_by=PACKET-0029
```

**IT IS NOT DEGENERATE — 3 of 4 rankable candidates sit on the Pareto frontier**,
against `DECISION-0010`'s single dominator that 125 of 125 weightings returned.
**Weights would change this ordering.** The candidate set is **mechanically
derivable, not curated**.

**NO RANKER-OWNED FIELD WAS WRITTEN.** `rank_of_selected`, `ranking_agreement`,
`ranker_skill`, `ranking_digest`, `counterfactual_regret` and `sealed_rank` own
**no column**, are **refused by both write paths**, and are **derived by the
ranker on demand** — because an outcome row carrying the ranker's score would let
*"the selected packet turned out well"* be read as *"the ranking was correct"*.

**AN UNKNOWN IS NOT A ZERO.** Every quantitative field written is `unknown` or
`<value>@<provenance>`. Nothing was written as `0@measured` that nobody measured;
`durability_status` is `unknown` because **no post-close audit has run**.

## Explicitly NOT staged, and deliberately open

- **`s1-v2` / any signal-set redesign.** The degeneracy, the
  lettering-granularity margin, the non-independence and the label leakage stay as
  residue `(xxx)` / `(yyy)`.
- **Widening guard 1's `PROTECTED_SURFACE`**, or writing the `(uuuu)` granularity
  convention. **Widening is NOT the remedy** — a predicate that refuses every
  subject discriminates nothing. Residue `(zzz)` / `(uuuu)`.
- **Migrating the `evidence_refs` corpus to anchors.** The mechanism exists; the
  corpus has not moved, and moving it is a re-authorisation.
- **A 22nd declared mismatch.** ~~The standing ruling: **hold at 21.**~~ **THE RULING WAS
  BROKEN AT THIS CLOSE, AND IT WAS WITHDRAWN ON EVIDENCE RATHER THAN QUIETLY EXCEEDED.** The
  count is **22**. The reviewer withdrew its own P5 ruling because `lic_of` in
  `scan-controls.sh` **tops out at rank 4 (`gate`) for Class A and no class returns 5 — no class
  licenses `execute`.** **Therefore every durable-write control this repository will ever add
  MUST declare a mismatch; there is no legal alternative, for anyone, ever**, and holding at 21
  could only have been honoured by refusing to register real durable-write surfaces. **A cap on
  the RAW TOTAL is negotiable by construction and no packet can decline it. The number that
  actually constrains anybody did not move: gate-on-advise — the heuristics that can stop a
  build — is 14 at base and 14 at HEAD.** All growth is in the `execute` bucket. **ROUTED TO THE
  OPERATOR: re-express the ceiling on the gate-on-advise subset.** Residue `(lllll)`.
- **The router's stale second-eyes counter.** It says *"the last nine"*; it is
  **THIRTEEN** as of this close — now stale by four. Nothing pins the literal. The
  remedy is one builder-lite line, and editing the router is a **routing act rather
  than bookkeeping**, so it is named and not applied for the third close running.
  `(zz)`.

## Open boundaries carried forward

- **Nothing is pushed, merged, tagged, PR'd or deployed**, and no such go has been
  given. `df9f740`, `c76b4d0` and `fbd746d` stay local pending explicit go — and so
  do `d2c09c6`, `8ba368a`, `727de75` and this close commit. **None of the four may
  be amended:** the first three are the commits the gates measured.
- **`DEFECT-0013` IS OPEN AND IS ITS OWN PACKET.** Fixing it needs a licence to edit
  `tests/speed_benchmark_tests.sh`, which the memory-kernel packet did not have and
  this close does not have. **Until it is closed, a suite total from this tree is a
  sample and not a constant.**
- **The CHANGELOG / `current_state` cross-check has no green path for a builder** on
  any total-changing packet. Either the archivist runs before the gates, or the
  cross-check reads the total from a generated file the builder owns. **The choice
  is a routing act and is the operator's.** Residue `(mmmmm)`.
- **`c2d97f8` IS THE SELECTION ANCHOR AND `44b0fab` IS THE SEAL ANCHOR. NEITHER
  MAY BE AMENDED**, and neither may the three execution commits. The whole claim of
  the prospective ordering is that the seal was committed **before any commit could
  carry a selection**.
- **THE UNPUSHED STATE CARRIES EVIDENTIARY WEIGHT.** The parent-hash chain is
  non-forgeable **only once a third party has witnessed it**, so publishing is what
  converts the seal's anchor from *"one process could rewrite this"* into *"a third
  party has seen it."* **A push would now buy something specific. It is still an
  operator act and it is not requested here.** Residue `(kkkk)`.
- **Nothing consumes S1's ordering**, and wiring anything to it is an operator act.
- **Selecting the next packet from any decision is an operator act.**
- **Second eyes: NONE — TWELFTH consecutive packet**, and the first whose verdict
  carries experimental weight: a single-model chain produced both the ranking rule
  and the verdict on the first candidate it ranked. Residue `(zz)`.
