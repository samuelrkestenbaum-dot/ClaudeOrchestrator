# Receipt — `gravito_governed_rotation_a`

- **Packet id:** `PACKET-0039-governed-rotation`
- **Title:** The first governed rotation of `build-os/memory/residue.md`
- **Closed:** 2026-08-03
- **Lane:** `substantive`. **Depth 3** — builder, then qa ‖ reviewer, then one
  bounded fix round.
- **Verdict:** **PASS-AS-FIXED.**
- **Base:** `3ec519b`. **HEAD at close:** `8115ac4`.
- **Commits:** `7bd152e` + `8115ac4` — **two.**

---

## 0. The commit count, because it is a real datum and not a compliment

**This is the first packet in six to land inside the `<=2` commits cap.** The
four preceding closes ran to three commits each and the working contract's cap
was recorded as breached at every one of them — `gravito_current_state_reblock_a`
called itself *"the FIFTH consecutive close with this shape"*. This packet
closes at **two**: `7bd152e` (the rotation) and `8115ac4` (the fix round). The
streak is broken, and it is broken by measurement, not by assertion —
`git rev-list --count 3ec519b..HEAD` returns **2**.

**One instrument disagrees, and the disagreement is itself a finding.**
`build-os/tools/bandwidth-check.sh check` reported
`commits EXCEEDED — 6 commits since the declared base 9c740d7, ceiling 2` while
this packet was in flight. That is not a contradiction of the count above; it is
the tool doing exactly what it says it does. It reads the **first** `## Branch
base` section of `build-os/packets/active_packet.md`, and that section still
named `9c740d7` — the base of the **previous, already-closed** packet. The
declared base was stale, so the advisory counted six commits spanning two
packets. **The instrument that measures the working contract was reading a field
belonging to a closed packet**, which is the same shape as this packet's central
finding, arriving from a different direction. This close repairs the section in
place, line for line, to name `3ec519b`; after the repair the same command
reports `commits OK — 2 commit(s) since the declared base 3ec519b, ceiling 2`.

### The same instrument has a SECOND blind spot, and it is the same class

`bandwidth-check.sh` counts **every** commit since the declared base. It cannot
distinguish a packet's **build** commits from the **archivist's close** commit,
which by house precedent lands on top of them — `9c740d7` and `3ec519b` are both
close commits, and neither was counted against its packet's cap. So **a fully
compliant two-commit packet reads as `3 — EXCEEDED`** the moment its close is
committed, as this one does.

**Both defects are one class:** *an instrument reading a field whose identity it
never establishes.* One read a `## Branch base` belonging to a closed packet; the
other reads a commit range whose membership it never partitions. That is the same
shape as this packet's central finding (§2) — **resolvability is not identity** —
arriving for the third time, now in the tool that scores the working contract.

**THIS IS NOT A RETROACTIVE AMNESTY FOR THE FOUR PRIOR BREACHES.** Those were
**build-commit counts of 3** — three build commits before any close commit — and
they were real breaches, correctly reported. The correction here is narrow: it
concerns **how the close commit is counted**, and nothing else.

**No fix is built.** The governance ceiling forbids adding a validator without an
executed failing fixture, and this is a **reading error, not a safety failure** —
nothing unsafe happens when the advisory over-counts. Recorded in residue
`(jjjjjj)` so the next packet inherits the correction rather than re-deriving it.

**The cap itself is unambiguous and this packet met it.** `CLAUDE.md` states that
*the archivist's close is bookkeeping after the verdict, not a third gate*; the
`<=2` cap governs a packet's build commits. `git rev-list --count 3ec519b..HEAD`
was **2** at the verdict, and the close commit that follows is the seventh local
commit, not a third build commit.

---

## 1. The headline — rotation executed, for the first time in this repository

`build-os/memory/residue.md` had been **over its ceiling and un-rotated**, with
the rotation queued and deferred, across four consecutive packets. This packet
ran it.

| | before (`3ec519b`) | after (`7bd152e`) |
|---|---|---|
| `wc -c build-os/memory/residue.md` | **218,062 B** | **191,805 B** |
| against the 204,800 B ceiling | **13,262 B OVER** | **12,995 B UNDER** |
| `grep -c '^## '` blocks | 29 | 25 |
| `build-os/memory/archive/` | did not exist | created |

- **Reclaimed: 26,257 B** (`218,062 - 191,805`, both re-derived by the archivist
  from git blobs, not quoted from the brief).
- **Archived: 26,762 B** — `block_26`..`block_29` by stable id, **every one a
  `## History` block**, carrying item anchors **(a)–(n)** and nothing else.
- **The 505 B difference** between what left and what was reclaimed is the
  archive-pointer banner rotation wrote back into the live file. Conservation is
  byte-exact once that banner is accounted for: nothing was lost, and nothing
  was silently rounded.
- `build-os/memory/archive/residue.archive.md` is **27,031 B** on disk — the
  26,762 B of archived content plus a 269 B archive header.

### Reversible, and proven so by an agent other than the one that performed it

The rotation's reversibility is not a property the builder asserted about its
own work. **The reviewer independently re-executed the restoration** —
banner-recognise, concatenate, compare — and derived
`sha256 1977817fef768becfa8d7e89d333261ac619ad43eebcd03c246ef200fce1c8ca`, which
is **exactly the sha256 of `git show 3ec519b:build-os/memory/residue.md`**. The
archivist re-derived that base-blob hash at close from git and confirms the
match. Restoration was re-executed once more **after** the fix round's edits and
still round-trips byte-exact.

**Therefore the archive file is load-bearing evidence, and this close did not
touch it.** `build-os/memory/archive/residue.archive.md` remains blob
`f475d53e9a7b282437bc2bb4729de1274d9d7708`, verified by `git hash-object` at
hand-back.

### The cut was DERIVED, not chosen

The `--keep` value is the part of a rotation that can quietly destroy something,
so it was not picked. **The rule applied is: _archive every block older than the
oldest still-open item._** Retention is a **prefix** and blocks run newest-first,
so the rule reduces to *set `--keep` to the index of the oldest block still
holding an open item*. The oldest still-open item sat in **block 25** — it holds
`(S1)`, an operator decision that blocks step 2, and a flake item marked still
open — so the cut fell at **`--keep 25`**. `--keep 24` was executed in scratch
and **rejected**, because block 25 carries those items.

The derived value had to land inside a window bounded by two **independently
executed** constraints, neither of them assumed:

1. **Above:** `--keep 27` **refuses** at `EXIT.CEILING`, 206,496 B — retaining 27
   blocks leaves the file still over ceiling, so the tool declines.
2. **Below:** `tests/build_os_maintenance_tests.sh` §8 needs `keep >= 16` for a
   `keep=10` rotation to still clear its 40,960 B reclaim floor.

`--keep 25` sits inside that window. **When the three disagree, that is a
finding and not a tie to be broken silently** — recorded durably as residue item
`(iiiiii)`, because until this packet the rule lived only in one receipt's prose
and the next rotation would have redone the marker scan by hand.

### The value this tree had queued was NOT the value used, and that matters

`residue.md` carried a standing `PENDING ACTION` naming **`--keep 10 --apply`**.
Executed as written it turns §8 red three ways: the file would carry exactly 10
blocks, so 8(a) refuses `RES_BLOCKS -le 10`, 8(b) sees `archivedBlocks 0`, and
8(c) sees 0 reclaimable bytes. **The queued action was defective as written, not
merely un-run.** See §4 below — it was also, by then, a live hazard.

### What the rotation proved by execution rather than assertion

- **Zero** non-`## History` blocks archived.
- **Zero** occurrences in the archive of `STILL OPEN`, `OPERATOR DECISION`,
  `BLOCKS STEP`, `QUEUED`, `PENDING ACTION`, `DELIBERATELY UNRESOLVED`,
  `WIDE OPEN`, or the three gate-pinned literals.
- `(ddd)` and `(uuuu)` still live, and absent from the archive.
- Block 1 **byte-identical** at 13,666 B by `cmp -s`.
- No archived anchor referenced with open wording anywhere on the 282,788 B live
  standing surface.
- The one `(S1)` hit inside the archive is a **cross-reference, not the object**
  — investigated and recorded rather than counted clean. That distinction is the
  difference between a sweep and a proof.

---

## 2. THE FINDING THAT MATTERS MOST — the true count of citation breaks is ZERO, and three instruments each reported a different non-zero answer

**This is the most important thing in this receipt.** It is recorded here at
length, and durably in residue as `(hhhhhh)`, under
`DEFECT-0001-stale-line-reference` with the rule name *resolvability is not
identity*.

### What each instrument reported

| reader | method | reported |
|---|---|---|
| **qa** | classified by **semantic identity** | **1** break |
| **reviewer** | verified 2 sites **positionally** | **2** breaks |
| **orchestrator** | swept **mechanically** | **31** breaks |
| **the truth** | content, checked cross-commit against the base blob | **0** |

### Why all three were wrong in the same way

All three conflated **positional shift** with **semantic identity**. The
identity `pre[N] == live[N+10]` is **mechanically true of all 31 retained
sites** — it is a restatement of the fact that ten lines were inserted above
them. It carries **no information whatsoever** about whether a citation ever
named what it claims to name. It is the positional check wearing the clothes of
the semantic one.

**The rule that falls out, and it is the durable part:** *a content match at a
single commit tests **RESOLVABILITY**; only a cross-commit comparison against
what the citing sentence **CLAIMS** tests **IDENTITY**.* `pre[N] == live[N+k]`
is not that comparison.

### The builder falsified the premise and REFUSED TO EXECUTE

Two citations were routed for a `+10` repoint on the strength of that identity.
The builder checked them **by content against the base blob at `3ec519b`
(`sha256 1977817f…`)** and found both were **already semantically stale at base**:
the `:947-951` span cited by `(yyy)` is the tail of `(xxxx)` plus a `## History`
heading, and the `:2038-2039` cited from within `(qqqqq)` is `(hh)`'s
reviewer-withdrawal quote. Both were left alone, per `(eeeeee)` and the standing
rule *a wrong repoint is worse than a stale one*.

**That refusal is the only reason a knowingly false claim did not enter memory.**
Had the builder executed the routed repoint, the tree would now hold two
citations asserted to have been corrected, pointing at content they never named,
with the correction recorded as verified. The instruments would all have gone
green.

### Then the builder derived the fact that explains the whole thing

Of the **11** line-pinned citations into `residue.md` enumerated tree-wide,
**11 were already stale at base and 0 were correct.**

> **The insertions could not break a correct citation, because there were none
> to break. The count of citations this packet broke is ZERO — because the count
> that were correct going in was ZERO.**

### Two aggravations that are not to be softened

1. **It occurred inside the instruments built to measure that very class.** The
   citation-anchor machinery, the `§27a`–`§27d` sweeps, and the anchor table
   exist in this tree *specifically* to catch
   `DEFECT-0001-stale-line-reference`. The defect fired **inside** them. It is
   the same shape `(mm)` recorded, where 20 of 27 references passed every
   positional check while silently wrong.
2. **The orchestrator committed it immediately after articulating the
   distinction and correcting qa for it.** The orchestrator drew the
   positional-vs-semantic distinction, applied it to correct qa's classification,
   and then swept 31 sites mechanically on exactly the identity it had just
   ruled uninformative. **Stating a rule and violating it in the next action is
   worse evidence about the process than never having stated it**, because it
   removes the excuse that the distinction was unavailable.

---

## 3. Verdicts

### qa — **RED on one claim; disposition right, warrant wrong**

qa drove **RED** on the backlinks claim, and this receipt records the split
verdict deliberately rather than flattening it to a colour:

- **The disposition was right.** qa was correct that the backlinks claim as
  written could not be accepted as stated, and correct that nothing should be
  repointed on the evidence offered.
- **The warrant was wrong.** qa classified by semantic identity and reported
  **1** break. The true count is **0**. qa's method was the *closest to correct
  of the three* — it at least asked the right question — and it still returned a
  wrong number.

**Everything else qa measured was GREEN and independently reproduced** (§5).

### reviewer — **`fix-then-pass`, 10 items, all landed in `8115ac4`**

All ten enumerated items were closed in the single bounded fix round. **No
fourth serial stage.** The fix round was prose plus a late packet declaration:
`rotate-memory.mjs` was **not** re-run, **no `--apply` was executed**, and
archive bytes are untouched.

### Second eyes — **NONE**

`command -v codex` **exits 1**, re-checked by the archivist at this close. This
is the **EIGHTEENTH consecutive packet** with no second-eyes provider; review
remains **same-model**.

**And the file that tracks review discipline is itself carrying a stale restated
count.** `build-os/memory/tool_router.md:368` — verified by content at this
close — still reads *"checked at each of the last **nine** packets"*. **Both
figures are carried here on purpose: the true streak is eighteen; the router
self-reports nine.** Nothing in this close changes the router; the discrepancy is
recorded, not quietly repaired, because the gap between the two numbers is a
better measurement of the tree's restated-count problem than either number alone.

---

## 4. Hazards this packet found and recorded

### `(bbbbbb)` was a LIVE hazard, not merely a stale note

`(bbbbbb)` still named **`--keep 10 --apply` as THE PENDING ACTION** after the
rotation had already run at `--keep 25`. **Retention is a PREFIX.** With the
file now holding 25 blocks, that command would archive **blocks 11–25** —
carrying away `(ddd)`, block 25's `(S1)`, and the still-open flake: **precisely
the objects this packet proved protected.** A queued command that was merely
wasteful before the rotation became actively destructive after it.

It is now marked **SUPERSEDED AND DEFECTIVE**, with blocks named by index and
items by letter so the hazard is legible without re-deriving it.

`(bbbbbb)` also carried a claim that `residue.md` *"stands ABOVE
DEFAULT_MAX_BYTES"*, which the rotation inverted. Corrected, with both figures
re-derived and pinned to `7bd152e`. **No figure is quoted for "now"** —
`(cccccc)` (the don't-quote-sizes rule) fired again inside this very round.

### The `--apply` ordering is TESTIMONY, not tree-verifiable — and this is not softened

The claim that the rotation receipt was written **before** the live `--apply`
cannot be verified from the tree. The evidence available was mtime: the receipt's
mtime `16:13:33` **postdates** the live apply at `16:09:49` by **3m 44s**, and
**no artefact predates any run**. Pre-registration was not performed; the
ordering rests on the builder's account of it.

- **The mitigation is proven reversibility** (§1) — an unregistered but fully
  reversible operation is recoverable, which is why this is a recorded weakness
  and not a stop.
- **The remedy is pre-registration**: commit the intended `--keep`, the predicted
  byte deltas, and the expected refusals *before* running `--apply`, so the
  prediction is in git ahead of the outcome.
- **The evidence has already decayed, which proves the point.** At close, the
  receipt's mtime is **17:21:44** — overwritten by the fix round's legitimate
  edit. The `16:13:33` reading the reviewer used **no longer exists in the
  filesystem**. `INDEX.md` and `residue.archive.md` still carry
  `16:09:49`, attesting the apply but saying nothing about the ordering.
  **mtime is not durable evidence, and a mitigation resting on it decays without
  anyone touching it.**

### `DEFECT-0011-undeclared-active-packet` — a further occurrence, aggravated by subject matter

`gravito_governed_rotation_a` was **built, committed at `7bd152e`, and gated
while `active_packet.md` declared `NOTHING IN FLIGHT`.**
`bandwidth.active_packet_singleton` therefore reported **zero in flight while
the packet was in flight** — a guard passing truthfully against a file
describing the wrong state.

**The aggravation is the subject matter.** The rule this packet broke is written
verbatim in the very file it declined to edit, at `build-os/packets/active_packet.md:21`
(verified by content at close), by the **immediately preceding packet**, and its
stated reason is: *no measurement taken inside a packet ABOUT a memory file may
be taken against a packet file lying about what is in flight.* This packet is
**about memory files** — it rotated one.

**The builder's reasoning for not declaring was assessed as an excuse, not a
constraint, and that assessment stands.** The reasoning offered was that
declaring would move the `ANC-0003` site at `:89` and turn
`tests/memory_kernel_tests.sh` §18 red. **The line-count-neutral remedy was
already executed twice in that same file** — at `:21` and again at `:716` (both
verified by content at this close, both headed *"THIS EDIT IS LINE-COUNT-NEUTRAL
ABOVE THE `ANC-0003` SITE"*). **A constraint with a known, in-file,
twice-executed workaround is not a constraint.**

The declaration is now present, and **late**: it cannot make the guard's reading
true for the part of the packet already executed, only for the remainder. That
is precisely why the rule requires the declaration to be commit 1.
`ANC-0003` re-verified at `build-os/packets/active_packet.md:89` after the edit
(`scan-controls.sh anchors` → RESOLVED); no projection regeneration required.

**The remedy remains specified and unbuilt.** Only the UPPER bound on
`bandwidth.active_packet_singleton` exists; the `could_have_been_prevented_by`
already names the LOWER bound — refusing zero declared packets while a build is
in flight — and it still does not exist. **Nothing was built for it here** (0 new
validators in the fix round's ceiling), and pretending otherwise would be the
fourth consecutive record of a remedy named and not delivered.

### The close brief carried stale figures, and this is recorded for the same reason

The brief handed to this close stated `residue.md` at **213,824 B / 9,024 B
over**. The actual figures at base were **218,062 B / 13,262 B over**, derived
from the git blob. **A restated count, inside a brief whose own trap list says
DERIVE every count.** Every figure in this receipt is derived; none is quoted
from the brief.

---

## 5. QA proof — exact numbers

All of the following were re-derived by the archivist at close, not copied.

### Suite

- **`bash tests/build_os_tests.sh`, run ALONE and in the foreground**, after
  `pgrep -fa '^bash tests/'` returned empty, captured to a file, **never piped
  through `tail`**.
- **`==== RESULT: 2140 passed, 0 failed ====`**, **exit 0**,
  `grep -c '^  FAIL'` → **0**, and **no** `CHAINED: N passed, 1 failed` line.
- **Run twice during the packet, twice more solo in the fix round, and once more
  by the archivist after every write in this close.**
- **The 20-line chained verdict vector is BYTE-IDENTICAL across runs and
  identical to the pre-rotation baseline** — `sha256 a69575133a461220…`, the same
  vector recorded at the `d885657` close. **The first rotation in this
  repository's history changed no assertion outcome anywhere in the tree.**

### Commit-1 green in isolation

**Independently re-derived by the archivist at close** in a clean clone checked
out at `7bd152e`, not accepted from the brief:
**`==== RESULT: 2140 passed, 0 failed ====`**, exit 0, `grep -c '^  FAIL'` → 0,
no failing `CHAINED` line, 20-line vector `sha256 a69575133a461220…`.

**`tests_added` is therefore 0** (2140 → 2140), and that is the correct outcome:
this packet added no assertion, removed none, and re-fixtured none.

### Safety grep / census

- `build-os/registry/scan-controls.sh check` → **exit 0**:
  **105** registered controls, **46** refusal-capable surfaces, **88**
  load_bearing, **22** over-authorised (declared, anchored
  `grep -c '^authority_mismatch: declared'`; the unanchored form returns 27 and
  the 5 extra are commentary), **0** unregistered, **0** phantom, **0** advisory
  findings.
- `scan-controls.sh anchors` → **exit 0**: **12 resolved / 1 superseded / 0
  violations.** `ANC-0003` resolves at `build-os/packets/active_packet.md:89`;
  `ANC-0009` at `build-os/metrics/packet_metrics.tsv:17`.
- **Zero re-authorisations. No new control.** The single registry edit in
  `7bd152e` is a `1/1` `evidence_refs` repoint on an existing control, moved by
  content (`:136 -> :148`, `:151 -> :163`), each end verified to resolve to the
  same line it cited.
- **Occurrences: 18** (`grep -c '^occurrence: '` on
  `build-os/registry/defect_classes.txt`) — unchanged.

### Governance ceiling — **0 / 0 / 0 / 0**

**0 new registry stores, 0 new validator tools, 0 new suite files, 0 new
controls.** `DEFAULT_MAX_BYTES` unchanged at `200 * 1024` — **no ceiling was
raised to make the rotation succeed.**

### UI smoke

**Not applicable.** This packet is memory/governance only; it ships no frontend
surface and touched none.

---

## 6. Scope

**In scope, and delivered:**

- The first `--apply` rotation of `build-os/memory/residue.md`, at `--keep 25`,
  batch `2026-08-03T16:09:49Z`.
- Creation of `build-os/memory/archive/` with `INDEX.md`, the archive file, and a
  rotation receipt.
- One bounded fix round of 10 reviewer items, plus the late packet declaration.

**Explicitly out of scope, and not done:**

- **No occurrence row minted** in `build-os/registry/defect_classes.txt` — that
  store was outside the fix round's declared file scope and the round's ceiling
  was 0 new stores. **The next free id is `OCCURRENCE-0019`** (derived:
  `grep -c '^occurrence: '` = 18, highest `OCCURRENCE-0018`). **Queued, and
  deliberately not written anywhere as a dangling id.**
- **No guard built** for the `--keep` retention rule. `(iiiiii)` records the rule
  as **prose**; nothing executable enforces it.
- **No repoint** of the two routed citations — refused on evidence (§2).
- **`build-os/memory/current_state.md` was NOT rotated.** It is the next file the
  problem bites.
- **Nothing pushed, merged, tagged, PR'd, or deployed.**

---

## 7. Trajectory — stated honestly

**This is one hand-crafted safe rotation. It is not yet a repeatable
capability.**

- **Nothing executable asserts that the retained prefix contains every still-open
  item.** The rule is recorded in `(iiiiii)` as prose. The scan is still
  **manual**: read the open-item markers, find the oldest, take its block index.
- **`DEFECT-0014-retention-order-assumed-not-verified` remains OPEN**, and it
  names `build-os/memory/current_state.md` as the next file it bites. That file
  is now the largest un-rotated memory surface in the tree.
- The natural home for the guard is `tests/build_os_maintenance_tests.sh` §8, and
  `(ffffff)`'s open choice about §8/§9 duplication **should be settled before it
  is written**, or it becomes a fourth clone.

**What genuinely changed:** rotation went from *never executed, queued with a
defective value* to *executed once, at a derived value, provably reversible*.
That is real, and it is smaller than "rotation works".

---

## 8. Residue and known risks carried forward

- **NEW STANDING RISK — headroom is 2,905 B.** `residue.md` is at **201,895 B**
  against the **204,800 B** ceiling. The packet reclaimed 26,257 B; the fix
  round's annotations put **10,090 B** back, and this close adds more. **The next
  packet writing into `residue.md` should expect to rotate again**, and should
  budget for it up front rather than discovering it at close.
- `build-os/memory/current_state.md` is at **193,625 B** — **11,175 B** of
  headroom, and un-rotated.
- `DEFECT-0014-retention-order-assumed-not-verified` — open.
- `DEFECT-0011-undeclared-active-packet` — lower-bound remedy named, still not
  built. `OCCURRENCE-0019` queued and unminted.
- `DEFECT-0001-stale-line-reference` — fired again, inside its own instruments.
- `(ddd)`, `(uuuu)`, `(ppppp)` open and untouched by boundary. `(eeeeee)`'s stale
  pointer must be repointed **by content**, after re-deriving the position,
  because `current_state.md` moved again at this close.
- **Second eyes: NONE — eighteenth consecutive packet.**
  `build-os/memory/tool_router.md:368` still self-reports **"nine"**.
- The two deliberately-not-repointed spans (`:947-951` and `:2038-2039` within
  `residue.md`) are **stale on purpose**. Both remain in bounds for
  `tests/control_registry_tests.sh` §27a. **Do not let a later mechanical sweep
  "fix" them.**

---

## 9. Open boundaries — awaiting explicit go

- **6 commits are local and unpushed** (`3ec519b`, `d885657`, `b41aa5d`,
  `06e9f1c`, `7bd152e`, `8115ac4` — `git rev-list --count 9c740d7..HEAD` = 6).
  **Push authorization covered only the seventeen commits through `9c740d7`.**
  These six are **outside it.**
- **No push, merge, PR, tag, deploy, release, or secret access has been performed
  or authorized.** No `git config`, no amend, no rebase, no squash, no rewrite.
- **THIS CLOSE IS COMMITTED**, as one commit, matching the two precedents
  (`9c740d7`, `3ec519b`). **The archivist first proposed holding it uncommitted**,
  reasoning that a close commit would make `bandwidth-check.sh` read `3 —
  EXCEEDED` and undo the cap-compliance §0 records. **The orchestrator ruled
  against that, correctly, and the ruling is recorded here rather than quietly
  adopted:** the `<=2` cap governs a packet's **build** commits, the close is
  bookkeeping after the verdict, and **leaving the tree dirty is not a neutral
  choice** — it is five files of unrecorded work, a violation of the tree-quiet
  precondition for any later gate, and total loss if the container is reclaimed.
  **The instrument is wrong; the packet is not.** No number was engineered
  toward, and nothing was amended, rebased, squashed or rewritten.
- All production boundaries remain default-OFF.

---

## 10. Metrics row and the disjoint file-ownership manifest

Recorded in `build-os/metrics/packet_metrics.tsv` as
`gravito_governed_rotation_a`.

**`files`/`insertions`/`deletions` follow the verifier's convention**:
`record-packet.sh --verify-git` computes **per-commit sums** via
`git show --numstat` over the named commits, not the net union diff.

**This packet is the case where the two agree.** Per-commit sums are
**8 distinct paths / 956 insertions / 314 deletions**, and the net union diff
`3ec519b..8115ac4` is **also 8 / 956 / 314**. They agree because **no commit in
this packet removed a line that the other commit had added** — the gap that
opened at the previous close (6/6) has no cause here. Stated because agreement
between the two is worth recording exactly when it happens, so the next divergence
is legible as a divergence.

### Disjoint file-ownership manifest — all 8 paths, SINGLE-WRITER

**No fan-out.** One builder held every path for the whole packet, so no two
agents could contend and the merger question does not arise. The manifest is
recorded anyway, because a **missing** manifest broke the P2 close.

| path | commits | +/- |
|---|---|---|
| `.claude/agents/build-orchestrator.md` | `7bd152e` | +11 / -0 |
| `.claude/hooks/session-start-build-os.sh` | `7bd152e` | +12 / -0 |
| `build-os/memory/archive/INDEX.md` | `7bd152e` | +32 / -0 |
| `build-os/memory/archive/ROTATION-RECEIPT-2026-08-03T16-09-49Z.md` | `7bd152e`, `8115ac4` | +401 / -0 |
| `build-os/memory/archive/residue.archive.md` | `7bd152e` | +311 / -0 |
| `build-os/memory/residue.md` | `7bd152e`, `8115ac4` | +123 / -312 |
| `build-os/packets/active_packet.md` | `8115ac4` | +65 / -1 |
| `build-os/registry/control_registry.txt` | `7bd152e` | +1 / -1 |

**Hot files, and who owned them:** `build-os/memory/residue.md` (the packet's
subject) and `build-os/memory/archive/*` were held by the single builder in
`7bd152e` and annotated by the same writer in `8115ac4`. **This close's own
writes** — receipt, `current_state.md`, `residue.md`, `active_packet.md`,
`packet_metrics.tsv` — are held by the archivist alone, in `build-os/` only, and
**`build-os/memory/archive/residue.archive.md` is explicitly excluded from the
archivist's writable set** because the restoration proof depends on its bytes.

**Cells deliberately left `-`:** `wall_min` and `serial_min` are **unmeasured** —
nobody held a clock, and inventing one is the anti-pattern this store refuses.
`defects_escaped` is `-` because **no post-close audit has run**; `-` means
UNAUDITED and never zero.

---

## 11. Files this close wrote

- `build-os/receipts/gravito_governed_rotation_a.md` (this file, new)
- `build-os/memory/current_state.md` (snapshot advanced, new history block)
- `build-os/memory/residue.md` (one terse item, under a hard byte budget)
- `build-os/packets/active_packet.md` (packet marked closed; branch base
  repaired in place; next staged)
- `build-os/metrics/packet_metrics.tsv` (one appended row)

**Not touched, by boundary:** `build-os/memory/archive/residue.archive.md`,
`build-os/metrics/rank-candidates.sh`, `build-os/metrics/decision_telemetry.tsv`,
`build-os/metrics/signal_snapshots.tsv`, `build-os/memory/standing_gates.md`.

### The metrics row is git-VERIFIED, not merely written

- `record-packet.sh --validate` → **22 rows, 0 invalid.**
- `record-packet.sh --verify-git` →
  `VERIFIED gravito_governed_rotation_a 7bd152e,8115ac4 files=8 insertions=956 deletions=314`,
  and **`verify-git: 21 ok, 0 mismatched, 0 unverifiable`**.
- The row is **appended**, so `ANC-0009` at `build-os/metrics/packet_metrics.tsv:17` does not move.

### `bandwidth-check.sh` after the close

- `packets OK — 0 packet(s) in flight, ceiling 1` — the packet is marked closed and the
  `**Packet id:**` marker renamed to `**Packet id (CLOSED):**`, so the file tells the truth about
  what is in flight.
- `commits OK — 2 commit(s) since the declared base 3ec519b, ceiling 2` — the stale branch-base
  field repaired **in place, four lines for four**, above the `ANC-0003` site.
- `ANC-0003` re-verified resolving at `build-os/packets/active_packet.md:89`; `scan-controls.sh
  anchors` reports **12 resolved / 1 superseded / 0 violations**; **no projection regeneration
  required.**

---

## 12. What this close did to the two memory files, and the state it hands over

**This is the number the next packet needs, and it is not comfortable.**

| file | before this close | after | headroom against 204,800 B |
|---|---|---|---|
| `build-os/memory/residue.md` | 201,895 B | **203,812 B** | **988 B** |
| `build-os/memory/current_state.md` | 193,625 B | **202,494 B** | **2,306 B** |

- **The close stayed inside its residue budget**: net growth **1,917 B** against the stated ~2,500 B
  ceiling on growth. **No rotation was run** — rotation is operator-gated and this was a close, not
  a rotation packet — and **no standing content was trimmed.**
- **`current_state.md` took the detail deliberately**, per the close brief, which is why its history
  block is a summary and this receipt is the long form. Its history block says so in its own first
  paragraph.
- **BOTH FILES ARE NOW WITHIN ~2.5 KB OF THE CEILING.** `residue.md` at **988 B** cannot absorb
  another close. **The next packet that writes into either file must rotate FIRST**, at a `--keep`
  derived by `(iiiiii)`'s rule, and must budget for that in its declaration rather than discovering
  it at close. This is recorded in residue `(jjjjjj)`, in the `current_state.md` ledger entry, and
  as candidate 1 of the staged-next list in `build-os/packets/active_packet.md`.
- **The relief the rotation bought was real and is mostly spent.** 26,257 B reclaimed; the fix
  round put 10,090 B back and this close 1,917 B more. That is not an argument against the
  rotation — it is the measurement that says **one rotation per four packets is not the right
  cadence**, and it is why `DEFECT-0014`'s guard matters more than another hand-run.

### The insertion shift, checked by content rather than swept

Inserting the new history block into `current_state.md` moves every line below it. **Every
line-pinned citation into that file was checked individually, by reading the cited line — not
swept, and nothing was repointed.**

- **Above the insertion point and therefore unmoved:** the pointers at `:110`, `:147`, `:286`,
  `:443` and `:476`. Of these, `:443` **resolves correctly by content** (it is the line that carries
  the `residue.md:280` pointer the rotation receipt attributes to it); `:476` was **already stale
  before this close** — it names a marker that had already moved — and it lives in an append-only
  receipt, so it is left as written.
- **Below the insertion point and therefore moved:** exactly one target, cited by four
  `build-os/metrics/signal_snapshots.tsv` rows. **It is COMMIT-PINNED** — the adjacent column reads
  `build-os/memory/current_state.md@7daedee` — so it is a historical record of a line **at another
  commit**, and repointing it would rewrite the record of a past event. **Not repointed**, and that
  store is hash-chained and outside this close's writable set in any case.

> **The close therefore broke no correct citation into `current_state.md` either — established by
> reading six lines, not by asserting a sweep. That is the method this packet's central finding
> demands, applied to the close itself.**
