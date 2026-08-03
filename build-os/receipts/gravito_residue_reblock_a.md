# Receipt — `gravito_residue_reblock_a`

- **Packet id (canonical):** `PACKET-0037-residue-reblock`
- **Date:** 2026-08-03
- **Lane:** `substantive`. **Depth: 3 serial stages** — builder; qa ‖ reviewer
  concurrently; one bounded seven-item fix round. **No stage 4.**
- **Base:** `2a3c070`, on `claude/project-handoff-merge-ramhds`.
- **HEAD at close:** `95e2c7b`.
- **Commits (3):**
  - `bbdd85c` — `docs(packet): declare gravito_residue_reblock_a before building`
  - `d888766` — `fix(memory): re-block residue.md so rotation can reclaim, and prove the standing region cannot be reclaimed`
  - `95e2c7b` — `fix round: write down the ordering defect the packet fixed and never recorded, queue the un-run rotation, and increment the counter this repo built and stopped using`
- **Verdict: PASS-AS-FIXED.** qa returned **GREEN**; the reviewer returned
  `fix-then-pass`; all **7** items were fixed in `95e2c7b` and verified by the
  orchestrator rather than by opening a fourth gate stage.
- **Second eyes: NONE, single-model — FIFTEENTH CONSECUTIVE PACKET.**
- **Nothing pushed, merged, tagged, PR'd or deployed.** No such go was given.
- **THIS RECEIPT CITES BY CONTENT, NOT BY POSITION.** No `path:line` and no
  `path:N-M` token appears below, deliberately. The registry scan's own note
  records that live ranges and **four receipts** already cite one file *by line*
  — decaying citations frozen inside records nobody has licence to edit. A packet
  whose subject is a memory file that moves its own line numbers must not add a
  fifth. Every reference below names the object or quotes the literal.

---

## THE HEADLINE — THE PREVENTATIVE TOOL HAD A PRECONDITION THE FAILURE IT PREVENTS VIOLATES

`build-os/memory/residue.md` stood at **142 B of headroom** against a **204,800 B**
ceiling, and `rotate-memory` — the tool that exists to relieve exactly this — could
reclaim **nothing**: the file carried **3** `^## ` blocks, keep-N retains
`min(N,3) = 3`, archives **0**, and the tool **refuses at exit 3 once the file is
already over.** The next close had no green path.

> A relief valve that only opens *before* the pressure arrives is not a relief
> valve.

### The result, every figure re-derived at this close

| quantity | before | after | derivation |
|---|---|---|---|
| `^## ` blocks | 3 | **29** | `grep -c '^## ' build-os/memory/residue.md` |
| archivable @ keep-10 | 0 blocks / **0 B** | 19 blocks / **127,142 B** | `node build-os/maintenance/rotate-memory.mjs --file residue --keep 10` |
| post-rotation retained | 204,658 | **85,931 B** | same dry-run, `live size` field |
| headroom | **142 B** | **118,869 B** | `204800 − 85931` |

Reclaimed headroom, labelled by baseline: **+118,727 B base-relative**
(`118869 − 142`), **+126,636 B live-relative** (`127142 − 506` banner). Both
labels are kept because they answer different questions and silently picking one
is how a reclaim figure becomes unfalsifiable.

---

## THE CENTRAL RULING — the reviewer's reasoning, recorded verbatim, because it is this packet's defence

Re-blocking a file to satisfy a block-count-driven tool is **exactly the shape of
gaming a metric**. The reviewer acquitted it on the strongest available ground:

> **"A builder merely inflating a block count could have inserted 26 headings and
> left the order alone; every count-driven check would still pass, and the file
> would still lose its newest content on rotation. The ordering inversion is the
> actual repair and it is invisible to the gate."**

That is the whole acquittal: the repair the gate **cannot see** is the one that
mattered. Supporting findings, verified rather than assumed:

- Sections are coherent. All **7** `### From <packet>` markers sit alone, one per
  section — **no section spans two eras**. Re-derived at close:
  `grep -c '^### From ' build-os/memory/residue.md` → **7**, identical at base.
- Every heading names both a letter range and a source packet.
- The letter naming is **not post-hoc**: `signal_snapshots.tsv` already addresses
  this file **by letter** in 30+ references of the form `residue.md#ddd`.
- A reader seeking `(kkk)` now scans **29 labelled ranges** instead of grepping
  ~4,300 lines across 3 undifferentiated blocks.

**On sizing 29 sections to a headroom target — ruled LEGITIMATE.** A
one-section-per-era cut yields ~10 blocks, and at the shipped `keep=10` that
retains all of them and archives **zero**. The per-era cut does not solve the
problem at all. Exceeding `DEFAULT_KEEP` is therefore a **hard constraint, not a
preference**, and the section count is driven by it.

---

## THE ORCHESTRATOR'S BRIEF WAS WRONG ON THE CRUX — RECORDED PROMINENTLY, BECAUSE FOLLOWING IT WOULD HAVE CAUSED THE EXACT LOSS

The brief asserted that rotation archives the **oldest positional (head)** blocks,
and directed standing content to the **bottom** of the file.

**That is backwards.** `routeSegments` in `rotate-memory.mjs` computes
`blocks.slice(0, keepN)` as the *keep* set: a **PREFIX is retained** and the
**TAIL is archived**. Re-read from source at this close, and the function's own
docstring says it plainly — *"the newest `keepN` blocks (plus the preamble) stay
live, the rest go to the archive."*

> **Had the brief been followed, all three gate-pinned literals would have been
> written to the bottom of the file and archived on the first rotation — the
> exact failure this packet existed to prevent.**

What the builder did with the contradiction is the part worth institutionalising:

- **Demonstrated the correction rather than asserting it** — a 5-block fixture at
  `--keep 2` archives `block_3..block_5`, not `block_1..block_3`.
- **Did not touch the tool.** The tool was correct; the brief was wrong.
- **Reported it in three places** rather than silently routing around it.
- **qa reproduced it on its own independent fixture; the orchestrator confirmed it
  from source. Three readings, not two.**

**The override was correctly evidenced, correctly scoped, and correctly reported.
That is the discipline this tree exists to build**, and it is recorded here as a
positive precedent: a builder handed an authoritative-sounding instruction that
contradicts the source is expected to verify the source, demonstrate the
divergence, and escalate — not to comply.

---

## PROTECTION — PROVEN BY EXECUTION, AND qa COULD NOT DEFEAT IT

Block 1 is `## Standing open items — PROTECTED REGION`, and it holds **all three**
gate-pinned literals. Re-derived at close, **case-insensitively, because the
assertion uses `havei` and a case-sensitive count is the wrong derivation**
(a case-sensitive grep reports `license model` as absent — it is present as
*"License model is an OPEN OWNER DECISION"*):

| literal | whole file | inside block 1 |
|---|---|---|
| `license model` | 1 | **1** |
| `no tags` | 2 | **2** |
| `single-platform` | 1 | **1** |

**Nothing outside block 1 holds them.** Since rotation retains a *prefix*, block 1
survives at every `keep ≥ 1` — the protection is structural, not a special case in
the tool. `selection : RECENCY ONLY — no content is exempt from rotation` still
holds; the region is safe **because of where it sits**, which is why it had to be
the head and not the tail.

**qa's independent sweep**, fresh scratch copy per pass:

- **N = 1..27 rotate** — exit 0, all three literals live, **0** occurrences in the
  archive, block 1 **byte-identical** every time.
- **2 refuse at the ceiling** — exit 3, `cmp` byte-identical, **no `archive/`
  created**.
- **Defeat attempts, all failed:** `--keep 29 --max-bytes 999999999` archives
  nothing; `--keep 0 / -1 / 1.5 / abc / ''` all refuse at **exit 2**.
- **Every archive artefact including `INDEX.md`** scanned across all keeps →
  **0 leaks**.
- Live file **sha256 identical before and after qa's entire run.**

**The pinned set is provably complete at 3:** the assertion in
`tests/release_metadata_tests.sh` that loops
`for term in "license model" "no tags" "single-platform"` is the **only** assertion
in the tree that greps `residue.md` for content. Completeness here is a *derived*
claim, not an inventory someone hoped was exhaustive.

---

## CONSERVATION — NO PARAPHRASE IS POSSIBLE

Line-multiset diff across the migration: **exactly one line removed** — the old
`## Deferred (follow-up packets)` heading — and nothing else. **No retained line
was altered**, which is what makes paraphrase structurally impossible rather than
merely unobserved.

- **Lettered items: 129 at base `2a3c070` and 129 at the migration `d888766` —
  identical.** Derivation: `grep -oE '^\- \*\*\([a-z]+\)' … | wc -l`.
- **At HEAD `95e2c7b` the count is 131**, and the delta is fully accounted: the
  fix round added exactly `(aaaaaa)` and `(bbbbbb)`. The conservation claim is
  scoped to the migration commit; **"129 at HEAD" would be wrong** and is recorded
  here corrected.
- **Era markers: 7**, identical at base and HEAD.
- `(ddd)` and `(uuuu)` are present with identical text — **moved, not
  discharged.** Both remain open by boundary.

---

## THE FORWARD-LOOKING FINDING — THE MOST VALUABLE OUTPUT, AND IT IS OPERATOR-FACING

**`build-os/memory/current_state.md` is in the identical dead end.** Re-derived at
this close, not accepted from the brief:

- `wc -c` → **182,545 B**; `grep -c '^## '` → **exactly 3 blocks**; **22,255 B**
  from the 204,800 B ceiling.
- `node build-os/maintenance/rotate-memory.mjs --file current_state --keep 10`:

```
  blocks            : 3 total -> keep 3 newest, would archive 0
  would archive     : nothing — already rotated (no-op)
  live size         : 182545 B -> 182545 B (ceiling 204800 B) OK
```

**Exit 0.** The same blocker is coming for the second memory file, and the
instrument reports it as **healthy — "already rotated", "OK" — right up until it
is unfixable.** The phrase *"already rotated (no-op)"* is indistinguishable, at
exit 0, from *"cannot ever be rotated"*.

> A monitor that cannot distinguish "nothing to do" from "nothing can be done"
> reports green on its way into the wall.

This is recorded as an **operator-facing item**, staged in `active_packet.md` and
written to `residue.md` — deliberately not buried.

---

## THE SEVEN FIX-ROUND ITEMS

1. **`(aaaaaa)` — the ordering defect, now recorded.** `residue.md` was written
   **oldest-first**; `rotate-memory` assumes **newest-first** and retains a
   prefix. Reproduced independently against the base file: `--keep 2` archives the
   block carrying `### From PACKET-0029` — **the newest era** — while retaining the
   oldest. **Had rotation ever run on the old file, it would have archived the most
   recent residue and kept the oldest.** The reviewer:
   *"the packet's most valuable finding is the one thing it did not write down."*
2. **`(bbbbbb)` — the un-run rotation queued for an operator.** Overage and R7
   headroom are written as **derivation commands, not digits**, because the item
   lives inside the file it measures. (This receipt vindicates that choice — see
   the overage correction below.)
3. **The defect counter is incrementing again.** New class
   `DEFECT-0014-retention-order-assumed-not-verified` plus
   `OCCURRENCE-0015/0016/0017`. Re-derived at close: **14 classes** (`grep -c
   '^defect_class: '`), **17 occurrences** (`grep -c '^occurrence: '`), ids
   contiguous `DEFECT-0001..0014` / `OCCURRENCE-0001..0017` — up from 13 and 14.
   The reviewer: *"this is how a rising rate becomes invisible: the repo built a
   counter and stopped incrementing it."*
4. **A check that cannot fail, fixed** — found **independently by both gates**.
   The construct `[ -d … ] && ok … || ok …` passed on **both** branches,
   contradicting the tree's own written standard in `rotate-memory.mjs`, where a
   third conservation branch was **deleted** rather than left in place with the
   note: *"a guard that cannot fail reads as safety and adds no discriminating
   power."* Now a deterministic three-arm drive with a **reachable `no`**.
5. **130 → 129 lettered items.** Root cause found rather than patched:
   `grep -cE '^\- \*\*\('` also matches non-lettered `- **(S1)`. The correct
   derivation is `grep -oE '^\- \*\*\([a-z]+\)'`. **The builder's own "162 units"
   total only closes at 129.**
6. **RED reproduction corrected, 79 → 80 passed / 5 failed.** `85 = 80 + 5` is
   arithmetically forced.
7. **"no gate reads live size" → "no gate ENFORCES `DEFAULT_MAX_BYTES` on live
   size."** `docs/PILOT.md`'s `PILOT:CHECK id=R7` runs `find … -size +262143c` —
   a **live-size gate, and the customer-facing rubric.** It passes: largest memory
   file **212,567 B** against **262,144 B**, **49,577 B headroom**.
   **The builder's sweep enumerated 10 readers; qa enumerated 11, and the missing
   one was the only live-size reader.** The original claim was **safe by luck, not
   by the sweep meant to establish it** — which is the finding, not the typo.

---

## THE STAGE-4 HAZARD THE REVIEWER ANTICIPATED — AND HOW IT WAS AVOIDED

Item 4 edits lines **above** the very `evidence_refs` sites this packet had just
repointed. A naive edit would have produced a **fourth `DEFECT-0001` inside the
fix round itself** — the packet re-committing its own defect while fixing it.

**Strategy: strictly line-count-neutral.** A 3-line non-discriminating check
became a 3-line discriminating one; a 1-line over-broad claim became a 1-line
narrower one. **640 lines at `d888766`, 640 after the fix round**; the diff is
**4 insertions / 4 deletions**. Orchestrator-verified: all three cited sites
**byte-identical by content**, and `scan-controls check` reports **0
`VACUOUS-REF`**. **No fourth recurrence.**

One correction the builder made to the brief: the over-broad string sat at a
different line than the brief cited, and was **fixed by content, not by cited
position** — the same discipline, applied to the instruction itself.

**This receipt inherited the identical hazard and applied the identical
strategy** — see "What this close spent", below.

---

## RULING ON THE BLOCKER — RECORDED IN THESE WORDS

**CONVERTED, not cleared.**

From *"142 B of headroom and a tool that can reclaim 0"* to *"over an unenforced
constant, and a tool that can reclaim 127,142 B on one command."*

An unclearable blocker and a one-command-clearable one are **genuinely different
objects** — this is real progress and should be read as such. **But the live file
stays over `DEFAULT_MAX_BYTES` until an operator rotates**, and applying rotation
**relocates live items `(ddd)` and `(uuuu)` into the archive**. That is precisely
why the packet did **not** apply it, and why `(bbbbbb)` queues it for a human
decision instead. **Rotation was not applied; `build-os/memory/archive/` does not
exist.**

### The overage digit, CORRECTED at this close

The closing brief carried **"3,094 B over"**. Re-derived here:

| commit | `wc -c` | overage vs 204,800 |
|---|---|---|
| `2a3c070` (base) | 204,658 | **−142** (headroom) |
| `d888766` (migration) | 207,894 | **+3,094** |
| `95e2c7b` (**HEAD**) | **212,567** | **+7,767** |

**3,094 B is the figure at `d888766`, not at HEAD.** At close the file is
**7,767 B over**. Three figures were already corrected this round for not being
re-derived; **this would have been the fourth.** It is also the sharpest possible
argument for fix-item 2's design choice: the item that reports the overage lives
*inside the file it measures*, so a digit written there is stale the moment it is
written. **Derivation commands, not digits.**

---

## SIDE EFFECT OF THE FIX ROUND ITSELF — RECORDED

The keep sweep moved **28 rotated / 1 refused → 27 rotated / 2 refused**: the fix
round's own two new residue items pushed `--keep 28` retention over the ceiling.
Post-rotation retained rose **81,258 → 85,931 B** (measured fix-round delta:
`212567 − 207894` = **+4,673 B**).

> **The file measures itself, so writing about it changes it.**

This is not a curiosity — it is the structural reason this packet's numbers must
be re-derived at every read, and the reason the overage above moved.

---

## ALSO RECORDED

- **Sweep domain, one clause narrowed.** `--keep` is validated `≥1` and saturates
  at `totalBlocks`, so **1..29 is its whole domain** — but `--max-bytes` is
  equally user-settable, so "the whole domain" was too strong. qa ran the
  uncovered path (`--max-bytes 400000`, N ∈ {20,25,28,29}): rc=0, block 1
  byte-identical, **zero pinned leaks** — because `routeSegments(segments, keepN)`
  takes **no ceiling parameter**. Routing is **provably independent** of
  `--max-bytes`, by signature rather than by sampling.
- **The `-lt`/`-le` refusal style is a real distinction, not a dodge.**
  `tests.nonvacuity_minimums` is a *syntactic* family of fitted floors on scanner
  yield; the §8 thresholds are *substantive* thresholds on a memory file.
  Decisive: **the choice is documented in the file** — a dodge is undisclosed.
  Verified to fail **closed** on unset variables.
- **Two in-flight repairs, both `DEFECT-0001` caused by the packet's own line
  movement:** `ANC-0003`'s content site moved and drove `memory-kernel reconcile`
  to exit 2 `PROJECTION-DIVERGED`, repaired by **regeneration**
  (`export-handoff --out` — qa confirmed it appends **no event** and touches **no
  canonical store**; all **8** kernel stores byte-identical); and the
  `evidence_refs` pair, verified **by content**. **Third consecutive packet paying
  this tax** — now, for the first time, with occurrence rows behind it.
- **Second eyes: NONE — FIFTEENTH consecutive packet.** The `(zz)` streak is
  advanced. **`tool_router.md` still says the absence was "checked at each of the
  last **nine** packets"** — stale by six. The reviewer flagged it again; it is
  **not** fixed here, because fixing open residue items is out of scope for this
  packet and for this close. Carried as residue.
- **Deviation, recorded and NOT normalised: 3 commits against the `≤2` cap — the
  fourth close in a row with this shape.** Neither earlier commit was squashed or
  rewritten (amending is out of bounds at close). A cap breached four consecutive
  times is either a cap nobody intends to hold or a packet-cutting problem; it is
  logged as residue rather than quietly accepted.

---

## FINAL NUMBERS

- **Suite: 2121 passed / 0 failed, exit 0.** **Two SOLO full-capture runs by the
  builder**, chained verdict vector **byte-identical, both sha256
  `a1a370e9ed9fd4ac…`**; plus two runs by qa at `d888766` matching **element for
  element**.
- **Commit-1 green in isolation** at `bbdd85c`: **2103 / 0** in a clean clone;
  maintenance **144/144**.
- **Item 4 converted a check rather than adding one, so the total did not move.**
- **Live gate MATCH at 2121**; `CHANGELOG.md` carries the **unsplit** literal
  `**2121 passed**`.
- **Maintenance: 144 / 0.**
- **`scan-controls check` exit 0** — **105 controls, 88 load_bearing, 22 declared,
  0 unregistered, 0 phantom**.
- **`scan-controls anchors`** — **12 resolved / 1 superseded / 0 violations**;
  `ANC-0003` resolves in `active_packet.md`.
- **`memory-kernel validate` / `reconcile` exit 0, 0 divergent.**
- **Zero re-authorisations** — `control_registry.txt` blob unchanged
  (`84c447ee`), so census 105 / mismatches 22 / gate-on-advise 14 **cannot** have
  moved.
- **`DEFAULT_MAX_BYTES` still `200 * 1024`** — **no ceiling was raised.**
- **Rotation not applied**; `build-os/memory/archive/` does not exist.
- **Do-not-touch set byte-identical**, blob hashes re-derived at close:
  `rank-candidates.sh` **`5543ea88`**, `signal_snapshots.tsv` **`7496ead8`**,
  `decision_telemetry.tsv` **`fd52eb15`**, `memory_events.tsv` **`ca58a514`**,
  `packet_metrics.tsv` **`f9c78630`**.
- **S1 digest `e838284e2bba52628647d0c7ddd1ed258a7aab7cc391a5ac99992ad7584eb596`**,
  `rank_of_selected: 1`.

---

## FILE-OWNERSHIP MANIFEST — ATTRIBUTION BY PATH ACROSS 3 COMMITS

The packet landed **3 commits against the `<=2` cap**, so attribution cannot rest
on "one commit, one packet". The manifest is what keeps it **recoverable by
path**. All **8** distinct paths, derived with
`git show --numstat --format='' bbdd85c d888766 95e2c7b`:

| path | owner | commits |
|---|---|---|
| `build-os/packets/active_packet.md` | builder | `bbdd85c` |
| `build-os/memory/residue.md` | builder | `d888766`, `95e2c7b` |
| `build-os/memory/current_state.md` | builder | `d888766` |
| `tests/build_os_maintenance_tests.sh` | builder | `d888766`, `95e2c7b` |
| `build-os/registry/control_registry.txt` | builder | `d888766` |
| `build-os/registry/defect_classes.txt` | builder | `95e2c7b` |
| `build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md` | builder (regenerated) | `d888766` |
| `CHANGELOG.md` | builder | `d888766`, `95e2c7b` |

**Ownership is disjoint and single-writer: one builder held every path; there was
no fan-out, so no two agents could contend for a file.** The manifest is recorded
because the *commit* count exceeded the cap, not because ownership was shared.

**Diff figures, both conventions, because they differ:**

| convention | files | insertions | deletions |
|---|---|---|---|
| **verifier** (`--verify-git`, per-commit sums) | 8 | **2,721** | **2,143** |
| net union diff (`git diff 2a3c070 95e2c7b`) | 8 | 2,696 | 2,118 |

`record-packet.sh --verify-git` computes **PER-COMMIT SUMS** via `git show
--numstat` over the named commits, **not** the net union diff — a net-diff row was
refused at an earlier close, so the recorded row uses the verifier's definition
and the note states both. **The 25/25 gap is fully accounted:** `95e2c7b` removed
25 lines that `d888766` had added (`CHANGELOG.md` −21,
`tests/build_os_maintenance_tests.sh` −4), so the net diff counts each once while
the per-commit sum counts both the add and the delete. Row **VERIFIED** against
git at this close: `files=8 insertions=2721 deletions=2143`, `verify-git: 19 ok,
0 mismatched, 0 unverifiable`.

### ONE PATH IN THIS MANIFEST NEEDS A PRECISE CLAIM — `control_registry.txt`

The close brief stated the registry blob was **"unchanged (`84c447ee`)"**, and a
reader would take that as *untouched by the packet*. **It was touched.** Derived
here: the blob is **`f154f52c` at base `2a3c070`** and **`84c447ee` at HEAD**,
changed in `d888766` by **exactly one line** —

```
-evidence_refs: …:295; …:431; …:432
+evidence_refs: …:295; …:639; …:640
```

— the `DEFECT-0001` repoint, on an **existing** control. **`84c447ee` is
"unchanged *since* `d888766`", not "unchanged across the packet."** The
*conclusion* the brief drew still holds, and now on stated grounds rather than a
false premise: the edit moved an `evidence_refs` line only, touching **no
authority, class, or gate field**, so **census 105 / declared mismatches 22 /
gate-on-advise 14 cannot have moved** — and `grep -c '^control: '` returns **105**
at this close. **Zero re-authorisations** is correct; *zero registry edits* would
not have been.

---

## RESIDUE — WHAT LEAVES THIS PACKET OPEN

1. **`(bbbbbb)` — the rotation is queued and NOT run.** `residue.md` remains over
   `DEFAULT_MAX_BYTES`. Relief is one operator command; the cost is that `(ddd)`
   and `(uuuu)` relocate into the archive. **Operator decision, not a builder
   decision.**
2. **`current_state.md` is in the identical dead end** — 182,545 B, 3 blocks,
   rotation a no-op at exit 0. **The next packet, and it is a countdown, not a
   backlog item.**
3. **`(ddd)` stays queued and `(uuuu)` stays open** — untouched here by boundary.
4. **`tool_router.md`'s second-eyes count says "nine"; the true streak is 15.**
   A stale self-report inside the router that routes.
5. **The `≤2` commit cap has been breached four closes running.**
6. **`DEFECT-0001` (stale line reference) has now been paid three consecutive
   packets.** Occurrence rows exist; the structural fix does not.

---

## OPEN BOUNDARIES — NOTHING EXTERNAL HAPPENED

- **No push, no merge, no PR, no tag, no deploy, no secrets, no `git config`.**
- **No commit amended or rewritten.**
- **Rotation NOT applied.** No ceiling raised.
- The branch `claude/project-handoff-merge-ramhds` sits at `95e2c7b` plus this
  close's bookkeeping commit, **awaiting an explicit go** for anything external.

---

## WHAT THIS CLOSE SPENT, AND THE HAZARD IT INHERITED

`current_state.md` is **22,255 B from its ceiling and rotation cannot relieve it**,
so this close's own writes were budgeted rather than free. Spend is stated with
the receipt's own figures in the memory-file update itself.

**The stage-4 hazard applied to this close too.** `ANC-0003` resolves to a content
site in `active_packet.md`, and the close must edit that file *above* it. The
same line-count-neutral strategy was used: the status heading and the packet-id
line were each replaced **one line for one line**, and **all** new material was
appended **below** the anchor site. **File length unchanged by the edit
(659 → 659 lines); `ANC-0003` re-verified at the same line after both the edit and
the append.** No projection regeneration was required, because nothing moved.

**Independently re-checked at this close, not accepted from the brief:**
`PACKET-0037` appears in **0 files at base `2a3c070`**, and `git log -S'PACKET-0037'
--all` returns **exactly this packet's own three commits**. The band is contiguous
through `PACKET-0037`. **The id was free; the mint preceded the build.** This
check has caught a bad id at four prior closes; it did not need to here.
