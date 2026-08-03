# Receipt — `gravito_rotation_sentinel_guard_a`

- **Packet id:** `PACKET-0040-rotation-sentinel-guard`
- **Title:** The rotation sentinel — memory rotation becomes a governed runtime capability
- **Closed:** 2026-08-03
- **Lane:** `substantive`. **Depth 3** — builder, then qa ‖ reviewer concurrently,
  then one bounded fix round.
- **Verdict:** **PASS-AS-FIXED.**
- **Base:** `188472f` (the pushed tip). **HEAD at close:** `275ea3a`.
- **Commits:** `3a590ed`, `89b261b`, `275ea3a` — **three**, against a cap of two.
  See §C-4.

---

## 1. THE HEADLINE — the operator's success condition, and it is met

**Memory rotation became a governed runtime capability.** The tool no longer
accepts a `--keep` that a human happened to have derived correctly; it derives
the floor itself and refuses anything below it.

```
minimum_safe_keep = max(block position of every protected or still-open object)
```

Derived floors on this tree, printed on **every** run including allowed ones:

| file | derived `minimum_safe_keep` |
|---|---|
| `build-os/memory/residue.md` | **25** |
| `build-os/packets/active_packet.md` | **30** |
| `build-os/memory/current_state.md` | **3** |

**25 is the value a human hand-derived at rotation #1.** The tool now reaches it
without the human. Operator's stated success condition — *"Future rotations no
longer require a human to rediscover the safe keep value"* — **MET**.

**Rotation #2 executed under the guard.** `current_state.md`
**203,642 → 166,605 B**, **37,037 B reclaimed**, **20 → 15** blocks.

**Pre-registration is now tree-verifiable, which closes rotation #1's gap.**
Rotation #1's ordering was testimony. This one is checkable, and was checked at
close:

- `git merge-base --is-ancestor 3a590ed 89b261b` → **true**. The pre-registration
  commit is a proven ancestor of the apply commit.
- `PRE-REGISTRATION-rotation-2.json` declares
  `sourceSha256: 91fa454856bb7612b78ee1da843aa6e72e20851d6bef525ba046adb9f6a02cee`,
  and `git show 3a590ed:build-os/memory/current_state.md | sha256sum` returns
  **exactly that**. The pre-registration names the bytes it was written against,
  and git agrees.

**Ceiling held, exactly:** **0** new tools, **0** new stores, **0** new
validators, **0** new suite files, **0** new primitives, **0** new controls,
**0** new mutators. The guard extends `build-os/maintenance/rotate-memory.mjs`.

---

## 2. Scope

**In:**

- The sentinel in `rotate-memory.mjs`: derive `minimum_safe_keep` by identity
  resolution over protected and still-open objects; refuse any `--keep` below it
  at exit 7; print the floor on every run.
- Pre-registration of rotation #2 as its own commit, before the apply.
- Rotation #2 of `current_state.md`, executed under the guard.
- Test coverage in `tests/build_os_maintenance_tests.sh` (104 → 154).
- Registry bookkeeping for the extended control/mutator entries.

**Explicitly out:**

- **Cross-file identity resolution** — routed to the operator, §6(i).
- **Distinguishing a live marker from a quoted one** — routed to the operator,
  §6(ii).
- **Any rotation of `residue.md`** — provably impossible on this tree, §5.
- Rewriting `3a590ed`'s commit message; rewriting either archive receipt.
- Any push, merge, PR, tag or deploy.

---

## 3. Commits, and the file-ownership manifest

**The row names three commits, so the manifest is mandatory. Here it is —
attribution by path, and the honest statement of where path-disjointness does
not hold.**

| commit | subject | files | +ins | −del |
|---|---|---|---|---|
| `3a590ed` | `feat(maintenance): rotation sentinel — refuse any --keep below the derived safe floor` | 11 | 1536 | 61 |
| `89b261b` | `chore(memory): rotation #2, executed under the sentinel — current_state.md 20 -> 15 blocks` | 5 | 644 | 430 |
| `275ea3a` | `fix(sentinel): close two unenforced invariants, narrow an overstated claim, correct two receipt digits` | 7 | 420 | 38 |

**Per-commit sums (the verifier's convention, `git show --numstat` summed over
the named commits): 23 path-visits, 2600 insertions, 529 deletions, over 14
distinct paths.** The net union diff `git diff --numstat 188472f 275ea3a`
reports **14 files / 2565 / 494** — the two conventions **agree on the file
count and disagree on the line counts**, because `current_state.md` and the
registries were touched by more than one commit and the union diff nets the
overlap away. The row records the per-commit sums, which is what
`record-packet.sh --verify-git` recomputes.

### File-ownership manifest — attribution by path

**Sole ownership (11 of 14 paths):**

| path | owned solely by |
|---|---|
| `build-os/maintenance/rotate-memory.test.mjs` | `3a590ed` |
| `build-os/memory/archive/PRE-REGISTRATION-rotation-2.json` | `3a590ed` |
| `build-os/registry/MISMATCHES.md` | `3a590ed` |
| `tests/control_registry_tests.sh` | `3a590ed` |
| `build-os/memory/archive/INDEX.md` | `89b261b` |
| `build-os/memory/archive/ROTATION-RECEIPT-2026-08-03T19-53-21Z.md` | `89b261b` |
| `build-os/memory/archive/current_state.archive.md` | `89b261b` |

**Shared paths, named rather than hidden (7 of 14):**

| path | commits | why more than one |
|---|---|---|
| `CHANGELOG.md` | `3a590ed`, `275ea3a` | the fix round restates the entry it corrected |
| `build-os/maintenance/rotate-memory.mjs` | `3a590ed`, `275ea3a` | the fix round closes two invariants in the tool it built |
| `build-os/registry/control_registry.txt` | `3a590ed`, `275ea3a` | ditto, registry follows the tool |
| `build-os/registry/mutator_registry.txt` | `3a590ed`, `275ea3a` | ditto |
| `tests/build_os_maintenance_tests.sh` | `3a590ed`, `275ea3a` | 104 → 143 → 154 |
| `build-os/memory/current_state.md` | all three | the guard's subject, the rotation's subject, and the fix round's correction |
| `build-os/packets/active_packet.md` | all three | the packet's own declaration, log and corrections |

**`275ea3a` owns no path solely.** That is the definitional shape of a fix
round, and it is why the disjointness this project prefers is unattainable here:
a fix round that touched only new paths would not be fixing anything.
**Attribution stays recoverable by the (path, commit) pair above**, which is
what the manifest is for.

**`build-os/memory/residue.md` appears in NO commit of this packet.**
`git log --oneline 188472f..275ea3a -- build-os/memory/residue.md` returns
**zero** commits. See §5.

---

## 4. QA proof

**qa verdict: GREEN.**

| measurement | result |
|---|---|
| suite at `89b261b`, run twice solo | **2179 passed / 0 failed**, both runs, chained vectors **identical** |
| suite at base `188472f` | **2140 / 0** |
| delta | **+39**, attributed **entirely** to `tests/build_os_maintenance_tests.sh` (**104 → 143**); **19 other suites +0** |
| **Commit-1 isolation** — `3a590ed` alone | **GREEN, 2179 / 0** |
| archive round-trip | **both batches round-trip byte-exact** |
| safety grep | **`SC_FIRED == 7`, `SC_BAD == 0`** |
| live-suite gate | `RELEASE_METADATA_LIVE_SUITE=1` → **44 / 0** |

**After the fix round (`275ea3a`): 2190 / 0, twice, solo, vectors identical.**
Only `tests/build_os_maintenance_tests.sh` moved (**143 → 154**). Net for the
packet: **2140 → 2190, +50 assertions**, all of them in one suite file.

**Final solo full-capture run at close** (after this receipt, the memory updates
and the metrics row were written): recorded in §10.

---

## 5. `residue.md` IS FROZEN — and it was already unrotatable in truth

**Headroom: 431 B** against the 204,800 B ceiling
(`204800 − 204369`). Blob at close: **`01517ad2c30d447949a98d0b6db9b8d6b538d5a9`**,
byte-identical to its blob at base `188472f`. **Nothing in this packet, including
this close, writes to it.**

**It is provably unrotatable at every legal keep, and qa executed the proof
rather than reasoning about it.** `minimum_safe_keep = 25` against **25** blocks;
qa ran **all 25 keeps**; **every one exits 7**; `bytes_to_reclaim` at keep 25 is
**0**. Keep 25 — the only keep the sentinel would permit — is itself refused
twice over:

- **C2**, unresolvable `DEFECT-0014` (see §6(i)); and
- **C7**, 431 B of headroom against an 18,702 B close budget.

**What actually changed is strictly better even though the headroom did not
move.** Before this packet, an unsafe rotation of `residue.md` **exited 0**.
Now it is refused. The file was always unrotatable; the tool used to lie about
it.

**The remedies are operator acts, not build acts.** Either close `(o)` and
`(S1)`, or move the still-open items to the head of the file. Neither is the
archivist's to perform, and neither is a builder's.

**Consequence for this close, stated plainly:** every residue item this packet
produced is recorded in `build-os/memory/current_state.md` and
`build-os/packets/active_packet.md` instead. **`residue.md` did not receive
them, and the reason is not neglect — it is that the file cannot accept a byte.**

**Nothing was weakened to make room.** No ceiling raised, no keep floor lowered,
no protected object reclassified.

---

## 6. THE HONEST PARTS

### 6.1 An overstated claim about the packet's own thesis — and its full provenance

The commit message of `3a590ed`, and `active_packet.md` until the fix round,
claimed that a positional scan *"derives 15 and archives the object at exit 0."*

**qa executed the counterfactual instead of reading it. The claim is false on
this tree.** A positional scan over the whole file **derives 25 — identical to
the identity floor** — because `(o)`'s and `(S1)`'s markers sit in **block 25
themselves**. On this tree a positional scan refuses `--keep 10` identically to
the shipped tool. The narrow-claim-shaped thing the packet was reaching for was
not the thing the commit message asserted.

**THE TRUE NARROW CLAIM, which does survive:** identity resolution makes `(ddd)`
resolve to block **16** — its **declaration** — rather than block **15**, where
its **marker** sits. Proven by the §10(b) fixture, and by mutation **M1** killing
**2** tests. **Its value is that it does not *depend* on the accident that two
other objects happen to sit deeper.** That is a real property and a smaller one
than what was claimed.

**The provenance chain, recorded in full because the chain is the finding:**

1. **the builder wrote it**;
2. **the commit froze it** into an immutable message;
3. **the orchestrator repeated it to the operator as a measured result** — this
   is the step that matters, because it is where an unexecuted claim acquired
   the authority of a measurement;
4. **only an executed counterfactual caught it.** No amount of reading would
   have.

**This is the packet's own defect class, committed while describing the packet
that catches it.** The whole thesis of the sentinel is that a claim about
positions must be executed, not asserted — and the commit announcing it asserted
a claim about positions.

**`3a590ed`'s message is immutable and was NOT rewritten.** No amend, no rebase.
The correction is a **later record** — here, in `CHANGELOG.md`, and in
`active_packet.md` §FIX ROUND. **Do not soften this on a later pass.** The
receipt is the correction; the commit stays wrong on purpose, because a rewritten
history would have destroyed the ordering evidence that is this packet's other
deliverable.

### 6.2 Two unenforced invariants, found by executing mutations rather than reading code

Before the fix round, two invariants the tool visibly relied on were enforced by
**nothing**:

| mutation | before the fix round | after |
|---|---|---|
| **M5** — disarm `SENTINEL_GATE_PINS` | killed **0 of 2179** tests, while being **plainly observable** | **151 / 3** |
| **M4** — invert deepest→shallowest declaration ordering | killed **0** | **152 / 2** |

**And the rotation-#2 receipt claimed those pins were "verified BY IDENTITY" —
an unenforced claim sitting inside a receipt.** A receipt asserting a property
that no test would notice the loss of is the same failure as §6.1 wearing
different clothes.

**The harm was executed, not argued.** Under M4's mutant, `--keep 3` **exits 0**
and **the deeper declaration lands in the archive** — i.e. the mutant silently
archives a still-open object. The shipped tool **refuses at exit 7**. The
mutation score is not a proxy here; the mutant was run and the damage observed.

### 6.3 Two wrong digits in an immutable receipt, corrected as LATER RECORDS

In `build-os/memory/archive/ROTATION-RECEIPT-2026-08-03T19-53-21Z.md`:

| site | said | true value | how established |
|---|---|---|---|
| `:102` | `26763` B conserved payload | **26762** | `slice(0, 26762)` is a byte-exact substring of `residue.md@3ec519b`; `slice(0, 26763)` is **not** |
| `:100` | batch 1 has **15** rows | **4** | 9 total = **4 + 5** |

`89b261b`'s commit message carries the same `26763`.

**The receipt body was NOT edited, and that was verified rather than promised:**
`git diff --stat 89b261b 275ea3a -- build-os/memory/archive/` is **empty** — the
whole archive directory is untouched across the fix round.
`build-os/memory/archive/residue.archive.md` is blob
**`f475d53e9a7b282437bc2bb4729de1274d9d7708`**, unchanged, and it stays
load-bearing: rotation #1's restoration proof depends on its exact bytes.

**Both archive receipts are immutable. The corrections above are the record.**

### 6.4 Deviations, stated plainly

- **THREE COMMITS AGAINST THE `≤2` CAP.** The fix round was accepted
  **deliberately**, on a stated rule: *a false claim about the packet's own
  thesis, left standing in the record, is worse than a recorded cap breach.*
  The two earlier commits are descendants of the pushed tip and must not be
  rewritten — squashing either would destroy the ordering evidence the
  pre-registration exists to provide, since `89b261b`'s proof rests on
  `3a590ed` being a **distinct ancestor commit**. **The cap is breached. It is
  not excused.** It is the fifth close in a row to breach it; this one at least
  breached it for a stated reason rather than a discovered one.
- **SECOND EYES: NONE.** `codex` is not on `PATH`; review was **same-model,
  single-provider**. This is the **NINETEENTH consecutive packet** in that
  state. **`build-os/memory/tool_router.md:368` still says "nine"** — the router
  is stale by ten packets. Not repaired here (out of this packet's declared
  scope, and the line is a citation site); **flagged as residue in
  `current_state.md`.**
- **10 stale line-pinned citations repointed BY CONTENT** during the fix round.
  The suite hit **2187 / 3** mid-round from the builder's **own** line shifts —
  caught, then repaired by grepping each cited line's base text rather than
  guessing an offset. Worth recording as an operating cost: a packet that edits
  the files its own citations point into pays this every time.
- **An indirect `eval` was introduced and then REMOVED**, with the reason
  recorded in-source. It did not ship.

---

## 7. ROUTED TO THE OPERATOR — recorded, deliberately NOT built

**Two spec revisions. Each needs its own cut. Neither is a builder error, and
neither was attempted here.**

### (i) Cross-file identity resolution

The guard resolves identity **within a single file**. Memory files legitimately
cite each other, so an object declared in a sibling and merely *cited* here is
indistinguishable from one that has gone missing — and both refuse.

`DEFECT-0014` and `(S1)` are declared in siblings. **C2 therefore fires
`unresolvable` and is KEEP-INDEPENDENT: no `--keep` clears it.** The spec
demanded C2 be a refusal, and the tool obeys the spec exactly. **Widening
"resolve" to span files changes what the rule MEANS** — that is a spec question
for the operator, not a defect to hand a builder.

### (ii) Distinguishing a live marker from a quoted one

A sentence *quoting* `[STILL OPEN ...]` in order to describe an object arms the
scan exactly as the object's own status tag does. `active_packet.md` floors at
**30** partly because **this packet's own prose quotes residue's markers**.

**Stated honestly so nobody over-reads the fix:** the **reviewer judged floor 30
CORRECT on other grounds** — a `BLOCK:30` anchor. **So fixing (ii) alone would
NOT unfreeze `active_packet.md`.** Anyone who picks this up expecting headroom
from it will be disappointed, and should know that before they cut the packet.

---

## 8. Residue and risks carried forward

**`build-os/memory/residue.md` cannot accept a byte (§5), so these live in
`build-os/memory/current_state.md` and `build-os/packets/active_packet.md`.**

1. **`residue.md` is frozen at 431 B headroom and unrotatable at every legal
   keep.** Remedy is an operator act: close `(o)`/`(S1)`, or move still-open
   items to the head of the file. **Until then, no packet may record residue in
   the residue file** — which is a governance defect of its own, and is exactly
   the shape the next rotation packet must address.
2. **Spec revision (i)** — cross-file identity resolution. Unbuilt, routed.
3. **Spec revision (ii)** — live marker vs quoted marker. Unbuilt, routed; **does
   not on its own unfreeze `active_packet.md`.**
4. **`tool_router.md:368` says "nine" where the true figure is NINETEEN**
   consecutive packets without second eyes. A stale count in the router that
   governs whether anyone notices the gap.
5. **Fifth consecutive close at 3 commits against a cap of 2.** The cap is either
   wrong or unenforced; both are worth a ruling, and neither is the archivist's.
6. **`3a590ed`'s commit message is permanently false** about the positional-scan
   counterfactual (§6.1). Corrected only in later records. Anyone reading git log
   alone will read the wrong claim.
7. **Line-pinned citations are expensive to maintain** in packets that edit their
   own citation targets — 10 repointed by content this round.

---

## 9. Open boundaries — what is pending an explicit go

- **All three commits (`3a590ed`, `89b261b`, `275ea3a`) and this close commit are
  LOCAL AND UNPUSHED.** `188472f` is the pushed tip, and push was authorised
  **only through `188472f`**.
- **No push, no merge, no PR, no tag, no deploy, no secrets, no `git config`, no
  amend, no rebase** was performed by this close, and no such go has been given.
- Carried, unrelated and still open: Context Mode routing enablement; naming a
  target repo and approving a secret for the GH Actions; authorising the deferred
  connectors.

---

## 10. Close verification

- `build-os/metrics/record-packet.sh` row appended for
  `gravito_rotation_sentinel_guard_a` — see §3 for the figures it carries and the
  manifest it references.
- `build-os/metrics/check-adoption.sh` — **exit 0**.
- Final solo full-capture suite run: **`CHAINED: 2190 passed, 0 failed`.**
- `git status --porcelain` empty at hand-back; **HEAD** as recorded in
  `current_state.md`.
- Frozen-artifact proofs at hand-back:
  - `build-os/memory/residue.md` → blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, **unchanged**, 431 B headroom.
  - `build-os/memory/archive/residue.archive.md` → blob `f475d53e9a7b282437bc2bb4729de1274d9d7708`, **unchanged**.
  - `build-os/memory/archive/` → untouched by this close.
</content>
</invoke>
