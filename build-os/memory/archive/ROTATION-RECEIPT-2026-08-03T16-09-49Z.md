# ARCHIVE RECEIPT — rotation batch `2026-08-03T16:09:49Z`

> The first governed rotation ever run in this repository. Written by the packet
> `gravito_governed_rotation_a` and kept **beside the archive it describes**, not
> in `build-os/receipts/`, because it is a record of an ARCHIVE rather than of a
> packet: `build-os/receipts/*.md` is swept against `build-os/metrics/packet_metrics.tsv`
> (a receipt with no row, and a row with no receipt, are both rubric findings),
> and this file has no packet row and must never acquire one. It also has to
> survive uninstall/downgrade with the archive, which `build-os/receipts/` does
> not guarantee and `build-os/memory/archive/` does.

- **Tool:** `build-os/maintenance/rotate-memory.sh` (`rotate-memory.mjs`), unmodified.
- **Invocation:** `node build-os/maintenance/rotate-memory.mjs --file residue --keep 25 --apply`
- **Base commit:** `3ec519b51474763bce0c7276f353a99b91524434` (tree clean at invocation).
- **Ceiling:** `DEFAULT_MAX_BYTES` = `200 * 1024` = **204800 B**, **UNCHANGED**.
  `--max-bytes` was **not** passed and `rotate-memory.mjs:111` was **not** edited.
- **Scope:** `--file residue` **only**. `current_state.md` and `active_packet.md`
  were outside this invocation's blast radius and were not written.

---

## 1. WHY `--keep 25`, AND WHY NOT THE VALUE THIS TREE HAD QUEUED

`residue.md` carried a **PENDING ACTION** naming `--keep 10 --apply`. **That value
was NOT used, because executing it as written turns the suite red.** After a
`--keep 10` rotation `residue.md` would carry exactly **10** `^## ` blocks, and
`tests/build_os_maintenance_tests.sh` §8 then fails three ways:

- §8(a) refuses `RES_BLOCKS -le 10` — at the shipped keep the file can no longer be relieved;
- §8(b) `archivedBlocks` becomes **0** — a reported no-op;
- §8(c) reclaimable bytes become **0**, under the `RES_MIN_RECLAIM=40960` floor.

Recorded as a finding against the queued item; the queued action is **defective as
written**, not merely unexecuted.

**THE CUT IS DERIVED FROM CONTENT, NOT CHOSEN.** The rule applied is
*archive every block older than the oldest still-open item*. The oldest still-open
item is in **`block_25`** — it holds `(S1) THE S1 EVIDENCE-TOKEN DECISION —
OPERATOR DECISION, AND IT BLOCKS STEP 2`, and a flake item marked
`[STILL OPEN AND STILL UNDIAGNOSABLE]`. `block_25` is therefore **retained**, and
the cut falls at `--keep 25`.

Two independently-executed bounds confine the legal window, and `25` sits inside both:

| bound | source | value |
|---|---|---|
| ceiling: largest keep whose retained bytes fit 204800 B | executed sweep; `--keep 27` refuses at `EXIT.CEILING` (3) with 206496 B | `keep <= 26` |
| §8(c): keep=10 on the ROTATED file must still reclaim >= 40960 B | executed | `keep >= 16` |
| **content: oldest still-open item is in block_25** | **executed marker scan over blocks 20..29** | **`keep = 25`** |

---

## 2. WHAT WAS ARCHIVED — ENUMERATED BY STABLE ID

Four blocks, `block_26`..`block_29`, **26762 B**. Every one is a `## History —`
block. Labels are the tool's own segment labels, stable under `segmentFile()`
against the pre-rotation file (blob `1977817f…`).

| stable id | source line (pre) | bytes | item anchors defined | heading |
|---|---|---|---|---|
| `block_26` | 2235 | 7150 | (l) (m) (n) | History — items (l)–(n), from `gravito_evidence_policy_matrix_a` |
| `block_27` | 2316 | 7541 | (a) (b) (c) (d) (e) (f) (g) (h) (i) (j) (k) | History — items (a)–(k), from `gravito_census_gaps_egress_bandwidth_a` |
| `block_28` | 2403 | 7871 | — | History — the speed-benchmark instrument and its carried limits |
| `block_29` | 2491 | 4200 | — | History — the earliest sessions (P-001..P-022) |

**14 item anchors** archived: `(a)`–`(n)`. Nothing else.

---

## 3. EXECUTED PROOF THAT NO STANDING OBJECT WAS INCLUDED

Run against the archive file itself, not against intent.

| predicate | want | got |
|---|---|---|
| archived blocks that are not `## History` | 0 | **0** |
| `STILL OPEN` in archive | 0 | **0** |
| `OPERATOR DECISION` in archive | 0 | **0** |
| `BLOCKS STEP` in archive | 0 | **0** |
| `QUEUED` / `PENDING ACTION` in archive | 0 | **0** |
| `DELIBERATELY UNRESOLVED` / `WIDE OPEN` in archive | 0 | **0** |
| `awaiting explicit go` in archive | 0 | **0** |
| gate-pinned literal `license model` in archive | 0 | **0** |
| gate-pinned literal `no tags` in archive | 0 | **0** |
| gate-pinned literal `single-platform` in archive | 0 | **0** |
| named live-open anchors `(ddd)` / `(uuuu)` in archive | 0 | **0** (and each still live) |
| block 1 (`## Standing open items — PROTECTED REGION`) byte-identical to source | yes | **yes, 13666 B, `cmp -s`** |
| archived anchors `(a)`..`(n)` referenced with open/queued/pending wording on any live standing surface | 0 | **0** |

The "live standing surface" for the last row is `residue.md` blocks 1–3 plus the
whole of `current_state.md`, `standing_gates.md` and `active_packet.md` (282788 B).

**ONE HIT WAS INVESTIGATED RATHER THAN COUNTED CLEAN.** `(S1)` occurs **once** in
the archive, at `residue.archive.md:157`, as the cross-reference
*"See item (S1) below — the first live occupant either rung would have had."*
That is a **reference**, not the object: the definition of `(S1)` is in `block_25`
and is **retained live**. Recorded because the count is not zero and a reader
checking this receipt with `grep` will find it.

---

## 4. BACKLINK PRESERVATION

**No citation anywhere in the tree points into the archived region.** Every
line-pinned citation into `residue.md` was enumerated tree-wide and compared
against the archive boundary (pre-rotation line **2235**):

| citing site | target | zone |
|---|---|---|
| `CHANGELOG.md:119` | `residue.md:582` | retained |
| `build-os/memory/current_state.md:443` | `residue.md:280` | retained |
| `build-os/memory/residue.md:137` | `residue.md:582` | retained |
| `build-os/memory/residue.md:629` | `residue.md:2038-2039` | retained |
| `build-os/memory/residue.md:1358` | `residue.md:947-951` | retained |
| `build-os/memory/residue.md:2070` | `residue.md:280` | retained |
| `build-os/receipts/gravito_authority_envelope_a.md:433` | `residue.md:280` | retained |
| `build-os/receipts/gravito_current_state_reblock_a.md:331` | `residue.md:582` | retained |
| `build-os/receipts/gravito_evidence_policy_matrix_a.md:576` | `residue.md:242` | retained |
| `build-os/receipts/gravito_evidence_policy_matrix_a.md:577` | `residue.md:442` | retained |
| `build-os/receipts/gravito_p3_accept_and_constrain_a.md:565` | `residue.md:631` | retained |

**11 of 11 retained, 0 archived.** For any FUTURE citation into rotated content
the resolution mechanism is `build-os/memory/archive/INDEX.md`, which carries one
row per archived block mapping the original `path:line` to `archive_file:line`:

| original | archive location |
|---|---|
| `build-os/memory/residue.md:2235` | `residue.archive.md:5` |
| `build-os/memory/residue.md:2316` | `residue.archive.md:86` |
| `build-os/memory/residue.md:2403` | `residue.archive.md:173` |
| `build-os/memory/residue.md:2491` | `residue.archive.md:261` |

### Why NOTHING was repointed, stated rather than skipped

The 505 B banner sits at the tail of the preamble, so every retained line moved
**+10**, verified by CONTENT IDENTITY (`sed -n Np` pre vs `sed -n N+10p` post) at
all ten distinct targets, not by assuming the banner's height. The citations were
still **not** repointed, on two separate grounds:

> **[CORRECTED BY THE FIX ROUND — "CONTENT IDENTITY" IS THE WRONG NAME FOR THE
> CHECK IN THE PARAGRAPH ABOVE, AND IT IS THE ONE FALSIFIED CLAIM IN THIS
> RECEIPT.]** Comparing `sed -n Np` pre against `sed -n N+10p` post establishes
> **POSITIONAL SHIFT** — that the bytes formerly at `N` are now at `N+10`. It
> holds **mechanically at every retained site in the file**, so it discriminates
> nothing and cannot support the phrase *content identity*, which a reader will
> take to mean *the citation names what it claims to name*. **The second
> proposition was never tested by that check.** When it was tested — by reading
> what each citing sentence CLAIMS against what the cited lines HOLD at the named
> base commit `3ec519b` — the result was that **all 11 enumerated citations into
> `residue.md` were ALREADY semantically stale at `3ec519b`, and 0 were correct.**
> The two singled out as fresh breaks (`residue.md:947-951` cited by `(yyy)`, and
> `residue.md:2038-2039` cited from within `(qqqqq)`) were **already wrong at the
> base commit** and were correctly left alone; had they been repointed `+10` they
> would have been moved to a differently-wrong place. **THE DISPOSITION IN THE
> TWO BULLETS BELOW IS UNCHANGED AND WAS RIGHT — nothing was repointed, and
> nothing should have been. What was wrong is the WARRANT, and the count of
> citations this rotation broke is ZERO.** Full derivation at residue `(hhhhhh)`;
> class `DEFECT-0001-stale-line-reference`, *resolvability is not identity*.

- **Historical records.** `residue.md:629` sits inside a passage that lists those
  very citations and says *"They were left as written"*, on this tree's own rule
  *a correction creates a later record, it does not edit an earlier one*. The four
  receipt citations are historical by construction, and `tests/control_registry_tests.sh`
  Rule 7 is explicit: **a line number may be a NAVIGATION HINT and may not be the
  IDENTITY**; a stale hint is REPORTED, not refused.
- **Already stale BEFORE this packet — so a `+10` shift would manufacture a
  differently-wrong pointer.** `residue.md:582` does **not** carry the pointer
  `current_state.md:286` that item `(eeeeee)` says it carries (that pointer is at
  `residue.md:138`); `:582` carries prose about `sed`/`head` sampling rates.
  `residue.md:280` does **not** carry a `CHANGELOG.md` citation as
  `current_state.md:443` and `residue.md:2070` assert; it carries `lock_path_safe`
  prose. Both were stale at `3ec519b`, independent of this rotation. Shifting them
  by 10 would move a wrong pointer to a different wrong place, which this tree has
  already paid for once — *a wrong repoint is worse than a stale one*.

`tests/control_registry_tests.sh` §27a sweeps ranges tree-wide for BOUNDS only
(file exists, N < M, M inside the file). Both ranges into `residue.md` remain in
bounds after rotation (`2039` and `951` against a 2244-line file), so no gate is
made red by leaving them, and none is made green by moving them.

---

## 5. EXACT BYTES

| file | before | after | delta | vs 204800 B ceiling |
|---|---:|---:|---:|---|
| `build-os/memory/residue.md` | 218062 | **191805** | **−26257** | UNDER by **12995** (was **OVER by 13262**) |
| `build-os/memory/current_state.md` | 193625 | 193625 | 0 | UNDER by 11175 (untouched) |
| `build-os/packets/active_packet.md` | 47911 | 47911 | 0 | UNDER by 156889 (untouched) |
| `build-os/memory/standing_gates.md` | 4521 | 4521 | 0 | UNDER by 200279 (untouched) |
| `build-os/memory/archive/residue.archive.md` | — | 27031 | +27031 | new |
| `build-os/memory/archive/INDEX.md` | — | 2023 | +2023 | new |

**Reclaimed from the live file: 26257 B.** The two numbers differ on purpose and
neither is the other: **26762 B of source content** were routed to the archive,
and the live file gave back **26257 B**, because the 505 B archive-pointer banner
was added back into it. `26762 − 505 = 26257`.

Conservation, as the tool reported and verified by string comparison before
writing: `191300 B live + 26762 B archived = 218062 B original, byte-exact`.
`priorBannerBytes` is **0** (first rotation), so **every byte of the original is
accounted for by exactly one output** and the `byte-exact` claim is not withdrawn.

---

## 6. DETERMINISTIC RESTORATION — AND IT WAS EXECUTED

`original = strip_banner(live) ++ first archivedBytes after the batch header`.

Deterministic because `archivedBytes` (**26762**) is recorded here, so the archived
span is taken by exact length rather than by scanning for a terminator, and the
banner is removed by the SHIPPED tool's own recogniser (`findTrailingBanner` /
`isRenderedBanner`), which REFUSES anything that is not bytes it wrote.

```
node --input-type=module -e '
import fs from "node:fs";
import { findTrailingBanner, segmentFile, FILE_SPECS }
  from "./build-os/maintenance/rotate-memory.mjs";
const ARCHIVED_BYTES = 26762;                       // from section 5 of this receipt
const spec = FILE_SPECS.residue;
const live = fs.readFileSync("build-os/memory/residue.md").toString("latin1");
const arch = fs.readFileSync("build-os/memory/archive/residue.archive.md").toString("latin1");
const segs = segmentFile(live, spec);
const pre  = segs.find(s => s.kind === "preamble");
const at   = findTrailingBanner(pre.text);
if (at === null) throw new Error("REFUSED: preamble tail is not a banner this tool rendered");
const liveContent = segs.map(s => (s === pre ? pre.text.slice(0, at.start) : s.text)).join("");
const hdrEnd = arch.indexOf("\n\n", arch.indexOf("## ARCHIVED BATCH ")) + 2;
const archived = arch.slice(hdrEnd, hdrEnd + ARCHIVED_BYTES);
if (archived.length !== ARCHIVED_BYTES) throw new Error("archive short");
fs.writeFileSync("/tmp/residue.restored.md", Buffer.from(liveContent + archived, "latin1"));
'
```

**EXECUTED TWICE — once against the scratch artefact before the live `--apply`, and
once against the live tree after it.** Both round-trips are byte-exact:

```
restored sha256 : 1977817fef768becfa8d7e89d333261ac619ad43eebcd03c246ef200fce1c8ca
HEAD blob sha256: 1977817fef768becfa8d7e89d333261ac619ad43eebcd03c246ef200fce1c8ca
```

No new tool was added to the tree for this: the procedure is stated here and runs
out of the rotation module's own exports, so the governance ceiling on new tooling
is not touched.

**Artefact hashes at this batch**

```
build-os/memory/residue.md                  5b3687e4f4f89cfa2ce6d2c1e53c6fb1965a78d286d64d41d7065fb5ed553b84
build-os/memory/archive/residue.archive.md  c6e73c6088a5a87aa5c30dede3aa8ed97f3468c483d96295a6ffa9ffd23694ae
build-os/memory/archive/INDEX.md            af88f7edce4499ab10faeb164be819fc44085aedb595c41d42855095641edc5b
```

---

## 7. EVERY `--apply` THIS PACKET RAN, EACH RECORDED BEFORE IT RAN

Four invocations total; **one** of them reached the live tree. A dry-run that is
then applied is counted as two records, not one.

| # | root | command | recorded before? | result |
|---|---|---|---|---|
| 1 | SCRATCH | `--root <scratch>/a24 --file residue --keep 24 --apply` | yes | exit 0; **plan REJECTED** — `block_25` carries still-open items, so keep=24 fails the standing-object gate. Artefact never proposed for the live tree. |
| 2 | SCRATCH | `--root <scratch>/a25 --file residue --keep 25 --apply` | yes | exit 0; 4 blocks / 26762 B; accepted as the plan |
| 3 | **LIVE** | `--file residue --keep 25` (**no `--apply`** — dry run) | yes | exit 0; tree still clean (`git status --porcelain` = 0 lines) |
| 4 | **LIVE** | `--file residue --keep 25 --apply` | yes | exit 0; numbers identical to records 2 and 3 |

A keep sweep (`--keep 16/20/22/24/26/27`) was also run in scratch as **dry runs
only**, which write nothing; `--keep 27` refused at `EXIT.CEILING` (3) as expected.

**THE "recorded before?" COLUMN IS BUILDER ATTESTATION AND IS NOT
TREE-VERIFIABLE. STATED PLAINLY BECAUSE IT IS THE EXACT SHAPE THE OPERATOR'S
WARNING NAMED.** The instruction this packet ran under was *do not run an
unrecorded `--apply`*. The column above answers `yes` four times, and **no
artefact in this tree predates any of those invocations**, so nothing here can
corroborate it:

- this receipt's own mtime is **`16:13:33`**, which **POSTDATES** the live
  `--apply` at **`16:09:49`** by 3m44s — it is a record written *after* the act,
  not a commitment made *before* it;
- the scratch roots the first two invocations ran in are **gone**, so the
  records that were allegedly written before them cannot be produced;
- there is no pre-registration store, no append-only log and no timestamped
  commit standing between the plan and the execution.

**So a reader has the builder's word and nothing else, and a receipt that
presents an unfalsifiable claim in a table beside falsifiable ones invites them
to be read at the same weight. They must not be.** Sections 3, 5 and 6 are
executed and independently re-derivable from committed bytes; this column is
testimony.

**THE MITIGATION IS REVERSIBILITY, AND IT IS PROVEN RATHER THAN ASSERTED.** What
makes the unverifiable ordering tolerable is that the operation it describes is
**exactly invertible**: section 6's restoration was executed twice and
round-trips to sha256 `1977817f…`, the blob at `3ec519b`, byte-for-byte. An
`--apply` whose full effect can be undone from committed bytes carries a bounded
worst case whatever order it was recorded in. **That is a mitigation, not a
substitute** — it bounds the damage, it does not make the claim checkable.
**THE REAL REMEDY IS PRE-REGISTRATION** — write the intended invocation to a
committed, append-only record *before* running it, so the ordering is a property
of the tree rather than of the narrator. **NOT BUILT HERE** (ceiling: no new
stores) and queued as such.

---

## 8. WHAT THIS ROTATION DOES NOT CLAIM

- It does **not** claim the archived content is unimportant. It is closed
  History, it is preserved byte-exact, and it is restorable by section 6.
- It does **not** give `rotate-memory.mjs` a notion of protected content. The
  standing region survived because it is a **PREFIX** and retention is a prefix —
  a positional fact, re-proved here by execution, not a property the tool
  understands.
- It does **not** dedup anything. `standing_gates.md` clause 4 holds: entries are
  copies, not moves, and deduping a live copy is an operator decision.
- `build-os/memory/standing_gates.md` was **not** added to `FILE_SPECS` and remains
  outside the tool's blast radius, so the LOCATION doctrine at
  `rotate-memory.mjs:49` is intact.
- Archived prose keeps its original intra-file deixis. `residue.archive.md:157`
  still says *"See item (S1) below"* although `(S1)` is now in a different file.
  Those bytes are deliberately **not** edited: editing them would break the
  byte-exact conservation the archive is worth anything for, and would break the
  round-trip in section 6.
  **[CORRECTED — THIS ROTATION DID NOT CREATE THAT BROKEN DEIXIS, IT INHERITED
  IT, AND THE SENTENCE ABOVE TAKES CREDIT IT IS NOT OWED.]** The phrasing
  *"although `(S1)` is now in a different file"* reads as though the archiving
  is what falsified the word *below*. It is not. **The deixis was ALREADY WRONG
  at the base commit `3ec519b`, before anything was archived:** the sentence
  lived at `3ec519b:build-os/memory/residue.md:2387` and said *"See item (S1)
  below"*, while `(S1)` was at `:2194` — **193 lines ABOVE it**, not below.
  Verified by reading both lines at the named commit. So rotation changed the
  deixis from *wrong within one file* to *wrong across two*, which is a
  different defect from the one this bullet describes and a smaller one than it
  claims. The **disposition is unchanged** — the bytes still must not be edited,
  for exactly the conservation reason given — but the **attribution** is
  corrected: this is a pre-existing `DEFECT-0001` instance, inherited, and it is
  the same conflation recorded at residue `(hhhhhh)` — noticing that a reference
  moved is not the same as establishing it was ever right.

---

## 9. FULL SUITE, BEFORE AND AFTER

**THIS SECTION WAS ABSENT FROM THE RECEIPT ENTIRELY AND IS ADDED BY THE FIX
ROUND.** A rotation receipt that documents conservation, restoration and
backlinks but never states whether the tree still passes its own tests is
missing the one number a reader checks first. There is no numbered
"requirements" list anywhere in this tree to append to — so it is recorded here
as a section, and the gap is named rather than quietly filled.

| tree | run | passed | failed |
|---|---|---:|---:|
| `3ec519b` (pre-rotation baseline) | 1 | **2140** | **0** |
| `7bd152e` (rotation commit) | 1 | **2140** | **0** |
| `7bd152e` (rotation commit) | 2 | **2140** | **0** |
| this fix-round commit | 1 | **2140** | **0** |
| this fix-round commit | 2 | **2140** | **0** |

**The per-suite VECTOR — not merely the total — is identical across every run
above.** That is the check that matters here and it is required by
`DEFECT-0013-pipefail-sigpipe-false-negative`: two runs can agree on a total
while disagreeing on which suite produced it, and a total-only comparison cannot
tell those apart. Each run was taken **solo and in the foreground**, after
confirming no test process was already live (`pgrep -fa '^bash tests/'` empty),
because a concurrently-running suite is exactly the condition that manufactures
the false counts that class describes.

**Rotation moved 26762 B of closed History out of a memory file and changed no
count in either direction.** That is the expected result and it is the point:
the archived content was not load-bearing for any gate. Two literals *are*
gate-pinned in `residue.md` (`no tags` via `tests/release_metadata_tests.sh:322`,
plus the standing-region literals swept by
`tests/build_os_maintenance_tests.sh` §8) and section 3 proves each stayed live.

---

## 10. THE CONTEXT-COMPILER WORK THIS PACKET ALSO DID

Rotation creates a **silent** failure mode for every reader of these files: an
over-size memory file fails to Read and the reader *knows* it is blind, whereas
a rotated file reads fine and is merely SHORTER than the history it summarises.
Three surfaces were changed so a session is told, and one was assessed and left
alone.

| surface | change |
|---|---|
| `.claude/agents/build-orchestrator.md` | +11 lines in the memory-reading step: if `build-os/memory/archive/` exists the live files are NOT the whole record; read the archive-pointer banner; resolve citations into rotated content through `INDEX.md`; do not conclude an item is absent from the record because it is absent from the live file, and do not re-derive a count from a live memory file without saying it is post-rotation. |
| `.claude/hooks/session-start-build-os.sh` | +12 lines emitting a ROTATED-MEMORY line at session start. **Gated on `build-os/memory/archive/` existing**, so a repo that has never rotated emits byte-identical output to before and no un-rotated install changes shape. |
| `build-os/registry/control_registry.txt:803` | `evidence_refs` bumped `:136;:151` → `:148;:163` — **+12**, the exact height of the block inserted above them in the owning module. A genuine fresh break, correctly repaired in the same commit that caused it. |

**`build-os/tools/memory-kernel.sh:753` `compile-context` WAS ASSESSED AND IS
UNAFFECTED.** It was the obvious candidate — it has "context" and "compile" in
its name and it assembles packages for a second surface — but it **compiles from
the kernel's own object stores, not from the markdown memory files**, so
rotating `residue.md` cannot change what it emits or make any package it has
already emitted less true. `do_compile_context` reads rows by id out of the
kernel stores and never opens `build-os/memory/*.md`. **Recorded because "assessed
and unaffected" and "not considered" are different states and a reader cannot
tell them apart from silence.**
