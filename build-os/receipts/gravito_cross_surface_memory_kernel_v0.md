# Receipt — `gravito_cross_surface_memory_kernel_v0`

- **Packet id (canonical):** `PACKET-0035-cross-surface-memory-kernel`
- **Date:** 2026-08-02
- **Lane:** `substantive`. **Depth: 3 serial stages** — builder; qa ‖ reviewer
  concurrently; bounded six-item fix round. **No stage 4.**
- **Base:** `ea069a7` — re-verified at close: `git merge-base 727de75 ea069a7`
  returns `ea069a71f8d1e81ac40613ffa4c919d630d6c233`.
- **HEAD at close:** `727de75`, on `claude/project-handoff-merge-ramhds`.
- **Verdict: PASS-AS-FIXED.** qa returned **GREEN**; the reviewer returned
  `fix-then-pass` on **6 enumerated items**, all 6 fixed in `727de75` and
  verified by the orchestrator rather than by opening a fourth gate stage.
- **Second eyes: NONE, single-model — THIRTEENTH CONSECUTIVE PACKET.** Re-verified
  at this close: `which codex` exits 1 and no plugin directory exists.
- **THIS RECEIPT CITES BY CONTENT, NOT BY POSITION.** No `path:line` token and no
  `path:N-M` range is written anywhere below. Every reference names the object or
  quotes the literal. That discipline is held **by hand**, because receipts and
  memory files are outside the fraction of the corpus the anchor scheme covers.

---

## THE HEADLINE — THE SUCCESS CONDITION WAS EXECUTED, NOT DESIGNED

> **Claude closed work into Gravito memory, and ChatGPT consumed the governed
> project state without Sam copying the transcript.**

The ledger **performed** the loop. Re-derived live from
`build-os/kernel/memory_events.tsv` at this close, printing id, type, actor and
surface:

```
EVT-0023  HandoffCreated    ACT-0002  claude.cowork.session.ramhds
EVT-0024  ContextCompiled   ACT-0003  chatgpt.web.session.strategy-01
EVT-0025  HandoffAccepted   ACT-0003  chatgpt.web.session.strategy-01
```

**The surface changes between EVT-0023 and EVT-0024, and the actor changes with
it.** That single transition is the whole claim: work was closed on the Claude
surface and picked up on the ChatGPT surface through the store, not through a
paste.

**qa established three things about it, and the third is the one a skeptic
needs.** First, all six of the export's §19 questions are answerable from
`build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md` **alone**. Second, a
sweep of the stores found **no transcript text anywhere**. Third — and this is
what makes the first two mean something — **the stores were adapter-written, not
hand-authored**: a 25-row SHA-256 chain in which each digest is a function of its
own fields and its predecessor's, with `recorded_at` monotonic across a
**9-second window**. Hand-authoring a valid 25-link chain inside nine seconds is
not credible.

Verified independently at close: `grep -c '^EVT-'` on the ledger returns **25**;
`memory-kernel validate` exits **0**; `memory-kernel reconcile` reports
**1 projection checked, 0 divergent**; and the export's own header line now reads
`**status:** \`accepted\``.

### And the refusal the packet exists for

```
memory-kernel: REFUSED — PACKAGE-STALE CTX-0001 binds source versions that are no longer
current and was read with --as-current: OBJ-0003@1->now@2. It PARSES, every id in it
RESOLVES, and it describes a state the project has left — resolvability is not identity.
EXIT=2
```

**It is not a wall.** The same package read as history returns exit 0 with
`state: STALE`. The refusal is scoped to the claim being made about the package,
not to the package.

---

## The packet id was DERIVED and COLLISION-CHECKED, not accepted from the brief

**The brief supplied `PACKET-0035-cross-surface-memory-kernel` and told the
archivist to check it anyway.** The check was run, because it has caught a real
defect before: at the P3 close an orchestrator brief supplied an id already held
by a **rejected** candidate, and the P4 and P5 closes both caught the same shape.

**The derivation, run at this close and not restated from the brief:**

1. A tree-wide sweep for `PACKET-0[0-9]{3}[a-zA-Z-]*` over `*.md`, `*.tsv` and
   `*.sh` returns a live band running from `PACKET-0001` to `PACKET-0035`. The
   **highest allocation that predates this packet is `PACKET-0034`**
   (`PACKET-0034-gravito-p4-s1-shadow-ranker-a`).
2. `git log -S'PACKET-0035' --all` returns **exactly one commit: `d2c09c6`** —
   this packet's own build commit.
3. `git grep -l 'PACKET-0035' ea069a7` returns **nothing**. The token did not
   exist in the tree at the base.

**Conclusion: `PACKET-0035` was free, was minted by the builder in `d2c09c6`, and
collides with nothing.** The candidate id in the brief is confirmed rather than
trusted.

---

## Scope

**IN, and all of it landed:**

- Twelve capabilities across eight canonical stores, covering **all seven
  namespace types**.
- **Actor identity distinct from execution surface** — the property the headline
  rests on.
- A **21-field object envelope**; an **append-only digest-chained ledger** with
  **all 13 event types live**; **15 relationship types** (7 with instances);
  structured handoffs.
- A **deterministic four-tier compiler with no score anywhere** — `sort -r` on
  `updated_at` is **ordering, not ranking**, and the distinction is load-bearing
  in a repository that already has one ranker under governance.
- **Immutable version-bound context packages.**
- A **governed adapter** — 9 writing and 6 reading subcommands, **a receipt per
  write**.
- A **ChatGPT export** that distinguishes
  `observed · reported · inferred · decided · verified · refuted · unknown`.
- **Deterministic projections** and **reconciliation**.

**Concurrency, proved rather than asserted:** `VERSION-STALE` refuses **and stores
nothing** — after four refusals `git status --porcelain build-os/kernel/` showed
**0 files changed**; `--on-conflict record` leaves the winner **byte-identical**.

**Security:** `SECRET-INLINE` refuses raw credentials; namespace isolation refuses
**on write, on edge and on read**. All five refusal codes named in this receipt
(`PACKAGE-STALE`, `PACKAGE-UNANCHORED`, `EXPORT-UNBOUND`, `SECRET-INLINE`,
`VERSION-STALE`) were re-confirmed present in `build-os/tools/memory-kernel.sh`
at this close.

**EXPLICITLY OUT — named, not silently absent:**

- **Attack A (staleness by addition)** — a design answer deferred to v1.
- **`payload_ref`'s prose-vs-reference ambiguity** — not resolved.
- **Body hashing in `parse-projection`** — not added.
- **`DEFECT-0013`** — measured, quantified, registered, **and not fixed**; the
  remedy touches a suite this packet had no licence to edit.
- **Any push, merge, tag, PR or deploy.**

---

## Commits, and the file-ownership manifest

| commit | role | one line |
|---|---|---|
| `d2c09c6` | build | memory kernel v0: Claude closes into governed memory, ChatGPT consumes it without the transcript |
| `8ba368a` | residue | residue: the base suite is not deterministic, and the mismatch report's own count had gone stale |
| `727de75` | fix round | fix round: derive state from the ledger, bind the whole export, and stop claiming a perimeter the hash does not hold |

Base `ea069a7`. **None pushed.**

**DEVIATION, RECORDED AND NOT NORMALISED: 3 commits against the `<=2` cap.** The
same shape as the previous close — the fix round landed as its own commit rather
than amending commits the gates had already measured. `d2c09c6` and `8ba368a`
were not squashed or rewritten.

### The file-ownership manifest — and it is NOT disjoint, which is stated plainly

The obligation is that where a merge forces more than one commit, the receipt
records the manifest **so attribution is recoverable by path**. **The honest
report is that these three commits OVERLAP heavily**, and the manifest below is
therefore a **sequential attribution by role, not a disjoint partition.** Computed
at close with `git show --name-only` per commit and `comm -12` between the sorted
sets:

- **`d2c09c6` ∩ `8ba368a` = ∅.** The build commit and the residue commit share no
  file.
- **`8ba368a` ∩ `727de75` = 1 file** — `build-os/memory/residue.md`.
- **`d2c09c6` ∩ `727de75` = 10 files** — `CHANGELOG.md`,
  `build-os/kernel/README.md`,
  `build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md`,
  `build-os/kernel/memory_events.tsv`, `build-os/memory/current_state.md`,
  `build-os/registry/MISMATCHES.md`, `build-os/registry/control_registry.txt`,
  `build-os/registry/mutator_registry.txt`, `build-os/tools/memory-kernel.sh`,
  `tests/memory_kernel_tests.sh`.

**Why the overlap is legitimate here and would not be in a fan-out.** The disjoint
manifest exists to keep **concurrent agents** from writing the same file. These
three commits are **strictly sequential passes by one agent**: build, then
residue, then the fix round correcting what the gates found in the build. A fix
round is *by definition* a second write to files the first pass owned. **Every
line is attributable by path and commit through `git log -p --follow`.** The size
of the packet is **23 distinct files**, with **2453 insertions / 60 deletions as
per-commit sums** and **2410 / 17 as the net union against the base** — both
derived at close, and the 43-line difference between them is explained below
rather than left to look like an error.

**What the manifest does NOT license:** it is not a precedent for a fan-out. Two
concurrent agents touching `build-os/tools/memory-kernel.sh` and
`tests/memory_kernel_tests.sh` would still require isolated worktrees and a merge
pass.

### THE OVERLAP IS NOT AN ABSTRACTION — IT IS A 43-LINE DISCREPANCY, AND THE ARCHIVIST HIT IT

**The first metrics row this close wrote was REFUSED by the store's own git
verifier, and that refusal is recorded rather than quietly fixed.** The row
carried the **net union diff** `ea069a7..727de75` — **2410 insertions / 17
deletions** — while `record-packet.sh --verify-git` computes **per-commit sums**
across the named commits and got **2453 / 60**:

```
MISMATCH  gravito_cross_surface_memory_kernel_v0  d2c09c6,8ba368a,727de75
          insertions: row says 2410, git says 2453. deletions: row says 17, git says 60.
```

**THE 43-LINE GAP IS THE OVERLAP ITSELF, MADE ARITHMETIC.** The fix round
re-edited lines the build commit had added, so each such line counts **once as an
insertion and once as a deletion** in the per-commit sum and **cancels** in the
net union. `2453 - 2410 = 43` and `60 - 17 = 43` — **the same 43 on both sides**,
which is the signature of a rewrite rather than of new work. **The store's
verifier therefore measured the overlap this manifest describes in prose**, and
disagreed with the prose's arithmetic before any human noticed.

**Both figures are git-verifiable and neither is wrong; they answer different
questions.** The row carries **2453 / 60** because that is the verifier's
definition; the **net union is 2410 / 17**, and it is written here so nobody
reconciles the two by guessing. `files = 23` is **distinct paths** and is
identical under both definitions, which is exactly why it never disagreed.

**THE WRONG ROW WAS DISCARDED, NOT EDITED — AND THE DISTINCTION IS THIS CLOSE'S
OWN SUBJECT.** The store is append-only, and this close had just finished
documenting a deviation whose entire content is *"a committed row was rewritten in
place."* The uncommitted append was therefore reverted with `git checkout --` and
re-recorded from scratch, so **no incorrect row ever entered the store's history
and no row was edited in place.** What makes this legitimate where Deviation 1 was
not: **that row had never been committed, and no gate had measured it.**

---

## QA PROOF BLOCK — exact counts

| proof | figure | how |
|---|---|---|
| Chained suite | **2096 passed / 0 failed**, exit 0 | `bash tests/build_os_tests.sh` |
| `^  FAIL` lines | **0** | `grep -c '^  FAIL'` over the captured log |
| Chained-failure lines | **none** | `CHAINED: … [1-9] failed` grep, empty |
| Independent repeats at `727de75` | **2 runs by the orchestrator, 2096/0 both times**; plus **6 runs by qa** at `8ba368a` | see `DEFECT-0013` below for why one run is no longer enough |
| Commit-1 green in isolation | **2082 / 0** at `d2c09c6`, in a **fresh clone** | the delta to 2096 is the fix round's +14 |
| Live-suite metadata cross-check | `RELEASE_METADATA_LIVE_SUITE=1` → **MATCH at 2096** | the guard parses the `N checks` literal out of `current_state.md` |
| Maintenance | **144 / 144** and **67 / 0** | `build-os/maintenance/run-tests.sh` |
| Control census | **105 controls, 22 declared mismatches, 0 violations** | `scan-controls.sh check` |
| Census, derived not remembered | **105** | `grep -c '^control: ' build-os/registry/control_registry.txt` |
| Anchors | **12 resolved / 1 superseded / 0 violations** | `scan-controls.sh anchors` |
| Mutators / adoption | `scan-mutators check` and `check-adoption` **exit 0** | |
| Kernel | `memory-kernel validate` **exit 0**; `reconcile` **1 projection, 0 divergent** | re-run at this close |
| Crosswalk | **105** | |
| README refs | **372** | |
| `MUT-0010` | added | |
| **Safety grep — re-authorisations** | **ZERO**, field-anchored | over the registry diff |

**The sealed-experiment invariants were re-checked and did NOT move:** S1 digest
`e838284e2bba52628647d0c7ddd1ed258a7aab7cc391a5ac99992ad7584eb596`,
`rank_of_selected: 1`, `rank-candidates.sh` blob `5543ea88`.
`build-os/metrics/signal_snapshots.tsv` and `build-os/metrics/decision_telemetry.tsv`
were **untouched** by this packet and by this close.

**UI smoke: NOT APPLICABLE, and that is a finding rather than an omission.** This
packet ships **no frontend surface whatsoever** — it is shell tooling plus TSV
stores plus one generated markdown export. The nearest thing to a rendered
artifact is `HANDOFF-0001-chatgpt-strategy.md`, and the check that stands in for a
smoke test on it is `reconcile`, which returned **0 divergent**.

---

## Reviewer verdict — `fix-then-pass`, 6 items, all 6 fixed

**1. The export misreported handoff state.** It printed the frozen row's
`status: created` while `EVT-0025` recorded `HandoffAccepted`. **Only 1 of 4
status values was ever reachable**, and **the exporter did not read the ledger its
own comment says carries state.** Now derived from the last
`HandoffAccepted`/`HandoffRefused` event — and **the stored row correctly stays
`created`**, because acceptance is an event and not an edit. The export header now
reads `**status:** \`accepted\``, verified live at this close.

**2. The export body was not version-bound.** The body resolved at current while
the binding table resolved at the bound version, producing **one document showing
two versions of one object, under a `STALE` banner, at exit 0.** The reviewer's
sentence is the durable part: *"Resolvability is not identity, reproduced inside
the artifact built to refuse it."* Now rendered at the bound
`(object_id, version)`; an unbound object hits `EXPORT-UNBOUND` rather than
falling back to current.

**3. The tamper-evidence claim was FALSE.** qa laundered a recorded contradiction
past **both** `read-context-package --as-current` **and** `validate`, both exit 0,
because `cp_hash_input()` is unkeyed and self-covering and `ContextCompiled` never
carried the package hash. **A wrong perimeter is worse than an admitted gap — and
this is the identical defect P5 shipped.** Now anchored in the ledger and
cross-checked by **both** paths; both refusal texts were corrected to say what
they actually detect and to name `PACKAGE-UNANCHORED` as the check that catches a
re-signed edit. **The attack was re-run and both gates refuse.**

**4. A namespace read escaped.** `project --object` took no `--actor`, exited 0,
and printed a **sibling-namespace object in full**. It now requires the scoping
triple and refuses without it.

**5. Two false claims narrowed.** The README's *"no file contains a `path:line`
token"* was **false for the generated export** and now says no canonical store
**records** one. Export §8's *"Nothing was omitted"* now says **at compile time**,
with the reason.

**6. Regenerated and reconciled.** The regeneration diff was **exactly the status
line and §8**; `reconcile` reported **0 divergent**.

**CONSEQUENTIAL, AND WORTH RECORDING BECAUSE IT IS THE ANCHOR PACKET'S THESIS
BITING AGAIN:** the item-1..5 edits **decayed five registry line-citations** —
`scan-controls check` went red with **6 `VACUOUS-REF`**. All were re-pointed **by
content**, and the re-authorisation grep over the registry diff is **empty**.

---

## TWO DEVIATIONS THE ORCHESTRATOR FOUND — BOTH RECORDED, NEITHER SMOOTHED

### DEVIATION 1 — the fix round REWROTE TWO COMMITTED EVENT ROWS IN PLACE

`git diff 8ba368a..727de75 -- build-os/kernel/memory_events.tsv` is **2
insertions / 2 deletions**. Verified at close, and it is exactly `EVT-0024` and
`EVT-0025`:

- `EVT-0024`'s reference field changed from `CTX-0001` to
  `CTX-0001@a8676c9d658d696d…`, carrying the package hash — that is fix 3.
- **`EVT-0025`'s own fields did not change at all, and its digest changed anyway**
  (`4659686a…` → `d657ab44…`). That is the signature of a **re-derived chain**:
  the successor's digest moved *because its predecessor's did*.

**THIS IS PRECISELY THE OPERATION THIS PACKET'S OWN `EVENT-APPEND-ONLY` GUARD
REFUSES.** The guard's own refusal text, quoted from
`build-os/tools/memory-kernel.sh`, describes what was done:

> `EVENT-APPEND-ONLY <id> breaks the integrity chain. Its digest does not follow
> from its own fields and the digest of the event before it, so a row has been
> edited, inserted or removed.`

**And the red-drive for it is §3 of this packet's own suite** — *"an event
rewritten in place breaks the digest chain and is refused"*.

**It validates now ONLY because the chain was re-derived — which is structurally
identical to qa's Attack B, the laundering this very fix round was fixing.** The
packet's stated rule is *"events are append-only; corrections create later
events"*, and **a correction event could have carried the anchor.** The builder's
hand-back calls it *"migrated and re-chained"* **without naming it as the thing
the invariant forbids**, and that omission is the part worth keeping on the
record.

**MITIGATION, RECORDED ALONGSIDE RATHER THAN INSTEAD:** the store is **v0**, was
**created inside this packet**, is **consumed by nothing outside it**, and the
rewrite is **visible in git history with the prior digests recoverable** — both
superseded digests are quoted above. **NOT treated as a stage-4 defect. Recorded
as a deviation, and not normalised.** The remedy for v1 is stated, not applied:
an anchor arriving late is a **later event**, never an edit to an earlier one.

### DEVIATION 2 — the packet was NEVER DECLARED, and that is the ORCHESTRATOR'S error

`build-os/packets/active_packet.md` still read `## Status: NOTHING IN FLIGHT` and
described `PACKET-0029` for the entire life of this packet. **Every prior packet
in this sequence opened with a `docs(packet): declare …` commit before building;
the orchestrator dispatched this builder without one.** The id was minted in
`d2c09c6`; **the declaration and the in-flight record were not written.**

**The measurable consequence: `bandwidth.active_packet_singleton` reported ZERO in
flight while the largest packet of the sequence was in flight.**

**PROVENANCE: ORCHESTRATOR, NOT BUILDER** — recorded the same way the
`residue_items_closed=1` defect's provenance was recorded at the last close,
because *how the error got in* is the only part that generalises.

**AND IT IS A RECURRENCE OF A CLASS THIS REPOSITORY ALREADY REGISTERED.**
`build-os/registry/defect_classes.txt` already carries
`DEFECT-0011-undeclared-active-packet` at `OCCURRENCE-0005`, whose symptom line
reads: *"an entire packet was built while active_packet.md still read NO PACKET IN
FLIGHT, and the singleton guard passed because it refuses two declarations and
permits zero."* Its `could_have_been_prevented_by` field already names the
remedy — **a lower bound on the same cardinality check** — and that remedy has
still not been built. **The class has now fired twice.**

**No registry occurrence row is written by this close.** Appending one is a
registry mutation that would change counts the gates measure, and the archivist's
write scope is the receipt and memory. **It is named here and carried as residue
so the next packet can record it through the governed path rather than as
bookkeeping.**

---

## `DEFECT-0013` — CONFIRMED AND QUANTIFIED. IT OUTRANKS THIS PACKET.

**THE BASE TREE IS NON-DETERMINISTIC, AND IT WAS NON-DETERMINISTIC BEFORE THIS
WORK BEGAN.** qa settled what two earlier probes could not:

| measurement | figure |
|---|---|
| per invocation, quiet machine | **6.26%** (501 / 8000) |
| across quiet batches | **3.65% – 7.75%** |
| under load | **19.97%** |
| per standalone suite run | **4.0%** (1 / 25) |

**It fires standalone as readily as chained.** The builder's `169/0` was **one
draw from a ~95%-green distribution**, not evidence of a chained-only condition.

**THE MECHANISM IS PROVEN, NOT INFERRED.** `PIPESTATUS=[0 0 0 141 0]` — `awk` is
element 4 and dies of **SIGPIPE**, `grep -q` exits 0, and `set -uo pipefail`
promotes 141. The `awk` in the failing pipeline of `tests/speed_benchmark_tests.sh`
emits **68,734 bytes**, past the **64 KiB** pipe buffer, so it *must* issue
multiple writes and **can** be killed mid-stream. The two sibling pipelines in the
same section emit **462 bytes in a single write** and measured **0 / 2000**.
**The orchestrator's simplified fixture produced too little output to race** —
which is exactly why it returned 0/2000 and could not confirm.

**A bare `rc=$?` RESETS `PIPESTATUS`**, which is why both earlier probes were
ambiguous. That is a reusable lesson about measuring shell pipelines, not a
detail of this bug.

**THE ERROR IS ONE-DIRECTIONAL.** It can manufacture a **false FAIL** and can
**never mask a real one**. Therefore: **every prior green in this tree stands, and
every prior red on that one assertion is suspect.**

**A SINGLE GREEN RUN IS NO LONGER SUFFICIENT EVIDENCE IN THIS TREE.** That is the
operational consequence and it changes how every future packet closes. The
orchestrator ran the suite **twice** at `727de75` — **2096/0 both times**, zero
`^  FAIL` lines, and **no `no seeded row` line in either**.

**NOT CAUSED BY THIS PACKET:** `tests/speed_benchmark_tests.sh` is **absent from
the `ea069a7..727de75` diff** entirely.

**THE SHARPEST CONSEQUENCE, AND THE REASON THIS OUTRANKS THE PACKET.** The
live-suite cross-check in `tests/release_metadata_tests.sh` compares a **live**
suite total against the figure remembered in `current_state.md`. **If the race
fires during that comparison, the guard that keeps memory honest emits a false
staleness verdict** — the instrument reports the memory as stale when the memory
is correct. A guard that cries wolf is a guard that gets disabled.

---

## FINDINGS RECORDED, NOT FIXED

- **Attack A — staleness by ADDITION.** Recording a *new* object into the
  package's own namespace leaves the package reading **`CURRENT` at exit 0**,
  because `pkg_state()` iterates **only the bound ids**. qa's probe used
  `OBJ-0014` — *"S1 PROMOTED AND AUTONOMOUS DISPATCH ENABLED"*, **the literal
  thing the export forbids the second surface from doing.** Needs a design answer
  in v1: a package's identity has to cover what its namespace *gained*, not only
  what it *bound*.
- **`payload_ref` is prose-vs-reference ambiguous.** `export_objects` prints field
  21 verbatim while the validator treats it as a path-like ref. **The
  "consumable without the transcript" property is therefore held up by authorial
  convention, not by construction.** Worse: the packet's own §0 would not catch
  the degradation, because its `q()` helper greps for section **headings** that
  the tool `printf`s **unconditionally**. **A test passing for the wrong reason,
  inside the packet built to prevent exactly that.**
- **`parse-projection` never hashes the body.** Editing `truth state: reported` to
  `verified` still returns `round_trip: MATCH`. `reconcile` is the real mechanism,
  and it covers **only `exports/`**.
- **Dead fields.** `memory_artifacts.content_hash` is hardcoded `-` and read by
  nothing.
- **Duplication.** The `handoff` and `context_package` **object types** duplicate
  the dedicated stores.
- **`ART-0011` has anchor `-`** — a bare file reference. **And it is the evidence
  for the SIGPIPE finding itself.** An anchor resolves an **identity token**, not
  a **content digest**, so the text around a token can change and the evidence
  silently cites different content. **`resolvability is not identity`, one level
  down, inside the layer built to prevent it.**
- **The export never names the tool, subcommand or actor id** required to satisfy
  its own acceptance criteria — a document that tells a second surface what to do
  and not how to do it.
- **`HOF-0001`'s acceptance criteria say *"at version 1"*** while §7 names
  `OBJ-0010`, **already at v1** — so deciding it produces **v2** and the criteria
  can never be met as written.
- **Second eyes: NONE — THIRTEENTH consecutive packet.** Re-verified at close.
  The `(zz)` streak is advanced in `residue.md` at this close rather than left to
  go stale, which is the failure that item is about. **The Second-eyes row in
  `build-os/memory/tool_router.md` still says the counter was checked at each of
  the last "nine" packets.** It is **thirteen**. **The literal is NOT edited
  here**: the standing ruling from the previous close is that editing the router
  is a **routing act rather than bookkeeping**. Named, not applied.

---

## ROUTE TO THE OPERATOR — recorded, NOT acted on

### The mismatch ceiling should be re-expressed on the gate-on-advise subset

**The reviewer WITHDREW ITS OWN P5 RULING on evidence, and the evidence is
structural.** `lic_of` in `build-os/registry/scan-controls.sh` tops out at **rank 4
(`gate`)** for Class A, and **no class returns 5 — no class licenses `execute`.**

**Therefore every durable-write control this repository will ever add MUST declare
a mismatch. There is no legal alternative, for anyone, ever.** A cap on the **raw
total of 22** is negotiable by construction and **no packet can decline it**;
holding the line at 21 would have meant refusing to register real durable-write
surfaces, which is worse than declaring them.

**THE NUMBER THAT MATTERS DID NOT MOVE.** **Gate-on-advise** — the original
subject of `MISMATCHES.md`, the heuristics that **can stop a build** — is **14 at
base and 14 at HEAD.** All of the growth is in the `execute` bucket. **The ceiling
should be re-expressed on the gate-on-advise subset**, where it constrains
something an operator can actually choose.

### The CHANGELOG / `current_state` cross-check has no green path for a builder

The cross-check forces builders into memory files on **any total-changing
packet** — the builder must write the new suite total into `CHANGELOG.md` and
`current_state.md` **before** the gates can be green, which is precisely the
window in which those files belong to the archivist. **There was no green path.**
Two remedies, and the choice is the operator's:

1. **The archivist runs before the gates** — inverting the close order, or
2. **the cross-check reads the total from a generated file the builder owns.**

Recorded because it is a **routing/contract change**, and the archivist does not
take routing acts.

---

## Residue

Appended to `build-os/memory/residue.md` at this close as items **(ccccc)**
through **(mmmmm)**, and the **(zz)** streak counter advanced **TWELVE → THIRTEEN**:

- **(ccccc)** `DEFECT-0013` quantified — supersedes the builder's 2.9% sample.
- **(ddddd)** Deviation 1 — the in-place event rewrite.
- **(eeeee)** Deviation 2 — the undeclared packet, and the `DEFECT-0011`
  recurrence with no registry occurrence row yet written.
- **(fffff)** Attack A — staleness by addition.
- **(ggggg)** `payload_ref` ambiguity, and the §0 test that passes for the wrong
  reason.
- **(hhhhh)** `parse-projection` does not hash the body.
- **(iiiii)** Dead fields and duplicated object types.
- **(jjjjj)** `ART-0011`'s bare anchor.
- **(kkkkk)** The export's missing tool/subcommand/actor, and `HOF-0001`'s
  unsatisfiable criteria.
- **(lllll)** The mismatch ceiling re-expression, and the withdrawn P5 ruling.
- **(mmmmm)** The CHANGELOG / `current_state` cross-check with no green path.

**Everything already open in `residue.md` stays open. This close fixed nothing and
was not asked to.**

---

## Open boundaries carried forward

- **NOTHING IS PUSHED, MERGED, TAGGED, PR'd OR DEPLOYED**, and no such go has been
  given. `d2c09c6`, `8ba368a` and `727de75` — and this close commit — stay
  **local**, pending an explicit go from the operator.
- **`c2d97f8`, `d2c09c6`, `8ba368a` and `727de75` MUST NOT BE AMENDED.** `c2d97f8`
  is the selection anchor of the still-intact prospective experiment; the other
  three are the commits the gates measured.
- **`build-os/metrics/rank-candidates.sh`, `signal_snapshots.tsv` and
  `decision_telemetry.tsv` were not touched** by this packet or this close.
- **Declaring the next packet is a routing act** and is not the archivist's to
  take. `active_packet.md` declares nothing at this close.
- **Fixing `DEFECT-0013` is its own packet** and needs a licence to edit
  `tests/speed_benchmark_tests.sh`, which this packet did not have.
- **Re-expressing the mismatch ceiling on the gate-on-advise subset is an operator
  decision**, not a bookkeeping edit.
- **Editing the Second-eyes row in `tool_router.md` is a routing act.** The stale
  "nine" is named here and left in place.
