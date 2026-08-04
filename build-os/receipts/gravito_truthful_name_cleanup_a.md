# Receipt — `gravito_truthful_name_cleanup_a`

- **Packet id:** `PACKET-0044-truthful-name-cleanup`
- **Title:** Rename the overclaiming demotion field to a name its predicate can pay
  for, and build the fixture-C differential that was missing.
- **Date closed:** 2026-08-04
- **Lane:** `substantive`. **Depth 2** — builder, then qa ‖ reviewer CONCURRENTLY.
  **No third stage and no fourth**: the reviewer returned PASS, not
  fix-then-pass, so no fix round opened.
- **Verdict:** **PASS.** qa **GREEN**, reviewer **PASS**. Second eyes **NONE**.
- **Branch base:** `6454220` on `claude/project-handoff-merge-ramhds`, verified
  with `git merge-base HEAD 6454220` → `6454220` **before the first edit**.
  `6454220` **is the pushed tip**.
- **HEAD at close (before this close commit):** `ab5d533`.
- **THIS IS THE LAST GOVERNANCE PACKET.** By the operator's ruling, work returns
  to **Repository Core and live provider execution** after this close.

---

## 1. Scope

**IN — three items, and nothing else.**

- **(A)** Rename the reported field `protected_in_owner` → **`named_by_nonquoted_marker_in_owner`**
  and the local `protectedAtHome` → **`namedByNonquotedMarkerInOwner`** in
  `build-os/maintenance/rotate-memory.mjs`. **Name only. The predicate does not move.**
- **(B)** Build the **fixture-C differential** that the previous packet described
  but did not execute, on **both** sides.
- **(C)** Reconcile the **two surviving** *"which is exactly when the inbound
  protection fires"* overclaims at `tests/build_os_maintenance_tests.sh` and
  `CHANGELOG.md` — the two sites the previous close declared **outside the
  archivist's write boundary** and carried forward.

**EXPLICITLY OUT.**

- **Widening any predicate.** Widening `markerNamingsIn` would widen the demotion
  and **re-open the fail-open that `1918fc3` closed.** Not done, and proved not
  done (§4.1).
- Raising any byte ceiling, including `DEFAULT_MAX_BYTES`.
- Writing `build-os/memory/residue.md` (FROZEN), `standing_gates.md` (which also
  **stays UNREAD**), `rank-candidates.sh`, `decision_telemetry.tsv`,
  `signal_snapshots.tsv`, `residue.archive.md`, or any immutable receipt body.
- Fixing `MISMATCHES.md:81`'s pre-existing drift (§6.3).
- Fixing the two evidence-scope nits at §5.3 and §5.4 — **recorded, not built.**
- Reducing the narration-to-code ratio (§7.2) — real, and out of scope.

---

## 2. Commits

| Commit | Kind | One line |
|---|---|---|
| `61bee02` | **BUILD 1** | declare `PACKET-0044-truthful-name-cleanup` before any implementation edit |
| `ab5d533` | **BUILD 2** | rename `protected_in_owner` → `named_by_nonquoted_marker_in_owner`, and build the fixture-C differential that was missing |

**Budget: 2 BUILD commits, 0 FIX commits — inside the typed budget (≤2 build + ≤1
fix) WITH THE FIX SLOT UNSPENT.** This is the first close in this sequence that
spent nothing on correction. There is **no deviation to log** and none is logged.

**Declaration-first, confirmed by inspection rather than by assertion.** `61bee02`
touches **one file** (`build-os/packets/active_packet.md`), **21 lines for 21** in
the head block and **4 for 4** in the branch-base prose; file length **1887 →
1887**. That neutrality is load-bearing: `build-os/packets/active_packet.md:89#ANC-0003`
is embedded as a **resolved line number** in the committed kernel projection and
`tests/memory_kernel_tests.sh` §18 compares it with `cmp -s`.

**`DEFECT-0011-undeclared-active-packet` DID NOT RECUR.** `active_packet.md`
declared **1** in flight for the packet's whole life, where it declared **0** for
the entirety of the previous packet (`OCCURRENCE-0020`). That is the remedy the
previous close named, executed. **The underlying control gap is still open:**
`bandwidth.active_packet_singleton` still **permits zero**, so this is compliance,
not enforcement.

**Nothing pushed, merged, PR'd, tagged or deployed.** `6454220` is the pushed tip;
`61bee02`, `ab5d533` and this close commit are **local and unpushed**. No
`git config`, no amend, no rebase, no secrets.

---

## 3. Disjoint file-ownership manifest

**8 paths, 8 path-visits — every path solely owned by exactly one commit.**
Single-writer (no fan-out ran; one builder held every path, so no two agents could
contend and the merger question does not arise). Recorded anyway, because a
**missing** manifest broke a prior close.

| Path | Owner | +/− |
|---|---|---|
| `build-os/packets/active_packet.md` | `61bee02` only | +21 / −21 (line-count-neutral above `:89`) |
| `CHANGELOG.md` | `ab5d533` only | +66 / −2 |
| `build-os/maintenance/rotate-memory.mjs` | `ab5d533` only | +63 / −7 |
| `build-os/memory/current_state.md` | `ab5d533` only | +18 / −4 |
| `build-os/registry/README.md` | `ab5d533` only | +1 / −1 |
| `build-os/registry/control_registry.txt` | `ab5d533` only | +5 / −5 |
| `build-os/registry/mutator_registry.txt` | `ab5d533` only | +2 / −2 |
| `tests/build_os_maintenance_tests.sh` | `ab5d533` only | +319 / −22 |

**THE TWO CONVENTIONS AGREE HERE, FOR THE FIRST TIME IN THIS STORE.** Per-commit
`--numstat` sums over `61bee02`+`ab5d533` = **8 / 495 / 64**; net union diff
`6454220..ab5d533` = **8 / 495 / 64**. Identical, because **no path was touched by
both commits**, so there is no overlap for the union to net away. Every prior row
in `packet_metrics.tsv` had to reconcile the two.

**THE ARCHIVIST CLOSE IS A SEPARATE WRITE SET AND IS NOT IN THAT ROW.** It writes
only:

- `build-os/receipts/gravito_truthful_name_cleanup_a.md` (new — this file)
- `build-os/memory/current_state.md`
- `build-os/packets/active_packet.md`
- `build-os/memory/tool_router.md` (**the `DC-0001` numeral only**, 22 → 23)
- `build-os/metrics/packet_metrics.tsv` (one appended row)

**Deliberately NOT written, blobs verified unchanged at this close:**

| Path / object | Blob |
|---|---|
| `build-os/memory/residue.md` | `01517ad2c30d447949a98d0b6db9b8d6b538d5a9` |
| `build-os/memory/standing_gates.md` (**and it stays UNREAD**) | `e889868fb7b29068b7f089b45986d9b56e351a34` |
| `build-os/metrics/rank-candidates.sh` | `5543ea8851cbf0b307a11b400d832d328fe9c48b` |
| `build-os/metrics/decision_telemetry.tsv` | `fd52eb151ad903106fabb9b7f7a7a8df13d6380d` |
| `build-os/metrics/signal_snapshots.tsv` | `7496ead8ee452ab09a507e502a11498ba1960758` |
| `build-os/memory/archive/residue.archive.md` | `f475d53e9a7b282437bc2bb4729de1274d9d7708` |
| `DEFAULT_MAX_BYTES` | unchanged — **no byte ceiling was raised anywhere** |
| every immutable receipt body | untouched — receipts are append-only history |

---

## 4. The headline

### 4.1 The rename is honest, and NO PREDICATE WAS WIDENED — proven by stripping the comments, not argued

qa removed **every comment** from `build-os/maintenance/rotate-memory.mjs` at
`6454220` and at `ab5d533` and diffed the **pure code**. **The entire delta is 4
lines:**

1. the `SENTINEL_REPORT_SCHEMA = 2` export,
2. the local rename (`protectedAtHome` → `namedByNonquotedMarkerInOwner`),
3. the field rename,
4. the emission.

`markerNamingsIn`, `markerIsQuoted`, `buildIdentityIndex` and `inboundProtections`
have **ZERO** code changes. The reviewer confirmed **independently**, by normalised
extraction. **The fail-open that `1918fc3` closed STAYS CLOSED.**

This matters more than the rename: widening `markerNamingsIn` was the obvious way
to make the field's old name true, and it is exactly the change that would have
re-armed four ordinary prose forms — one a plain markdown blockquote — each of
which archived a live, canonically declared, marked-non-consumable object at
**exit 0** under the pre-fix tool.

### 4.2 No alias — and the reviewer's reason is better than the brief's

`protected_in_owner` is **removed** from the emitted record rather than kept
pointing at the same value. An alias carrying the misleading name would reproduce
the exact defect being fixed. The backward incompatibility is carried by
**`sentinel_report_schema: 2`** (exported `SENTINEL_REPORT_SCHEMA`), so a consumer
pinned to the old key gets `undefined` **plus a version numeral that says why** —
a loud break, not a quiet wrong answer.

**Zero code positions** hold the old names. They survive on **6 comment lines
documenting the break** (`rotate-memory.mjs:898`, `:905`, the `:1493 :1498 :1509`
block, and `:1711`), and an assertion counts code-position occurrences (**0**)
separately from comment ones.

**THE REVIEWER'S FINDING ON WHY NO-ALIAS IS RIGHT, WHICH IS THE GOVERNING REASON
AND IS BETTER THAN THE REASONING IN THE BRIEF: the break is FAIL-CLOSED IN
DIRECTION.** The field's `true` licensed the **riskier** action — demotion — so an
external consumer that branched on truthiness and now reads `undefined` **stops
demoting. It becomes more conservative, not less.** Relocating the problem would
require the opposite polarity. The no-alias decision is therefore safe *because of
which way the field points*, not merely because aliases are untidy.

### 4.3 The fixture-C differential, executed on both sides

Section (c4) adds three roots differing from `plain` in **exactly one fact**,
asserted by `diff` **before anything is measured**, and demonstrates six things
**by execution**:

1. the 4 known vulnerable forms **archive `(qqq)` at exit 0** under the pre-fix
   implementation;
2. all 4 **refuse at exit 7** under the shipped tool, with no archive written;
3. the genuinely safe demotion still works (floor 0, 1 quoted reference);
4. **deleting the owner's one marker line restores the refusal** (floor 0 → 5);
5. a non-quoted marker naming `(qqq)` in an **unrelated third governed file** does
   protect it inbound and **still does not qualify** — the predicate reads the
   **canonical owner**, not the governed set;
6. the field is **TRUE in exactly the one root where the predicate holds** and
   FALSE in the three where it does not — including the owner-decl-only root where
   `(qqq)` **IS** protected at home (`owning-declaration@6`), which is the
   **executable** reason the field may not be called `protected_in_owner`.

**Demonstration 1 ran the historical tool VERBATIM.** The
`git show 0d3a34f:build-os/maintenance/rotate-memory.mjs` branch **fired** — not
the `sed` fallback — confirmed by the emitted provenance string
(`the committed 0d3a34f blob, executed verbatim`, `tests/build_os_maintenance_tests.sh:2165`).
The four form strings live in **one shared `ORPH_FORMS` array**
(`tests/build_os_maintenance_tests.sh:1906`) iterated by **both** (c2) and (c4), so
demonstrations 1 and 2 **cannot land on different inputs**. A second hand-copied
list is precisely the shape of overclaim this packet exists to remove.

**Demonstration 5 is not vacuous.** The inbound protection **genuinely fires** —
resolution `cross-file (named in build-os/memory/current_state.md:12)@6`, a real
anchor at residue block 6 — while the field stays `false` and the floor stays 5.
The negative result is measured against a live positive, not against nothing.

---

## 5. The four close conditions

### 5.1 CONDITION 1 — a prior-close record that is now FALSE as a live statement, corrected in the close record

`build-os/memory/current_state.md`, inside the
`## History — gravito_cross_file_sentinel_identity_a` block, states as a **live
outstanding item**:

> *"`tests/build_os_maintenance_tests.sh:1831` and `CHANGELOG.md:69` are OUTSIDE
> the archivist's write boundary and still carry it — carried into `PACKET-0044`."*

**THIS PACKET DISCHARGED BOTH.** `ab5d533` **withdrew** the overclaim *"which is
exactly when the inbound protection fires"* at both sites and replaced it with the
accurate claim: the condition is **sufficient**, **deliberately narrower** than all
possible owner-file protection, and **the gap FAILS CLOSED**. Left as-is, the
memory the next session reads would assert an outstanding item that no longer
exists.

**IT IS A PRIOR-CLOSE-RECORD LINE, SO IT IS CORRECTED IN THIS CLOSE RECORD AND THE
PRIOR RECORD IS NOT REWRITTEN.** History is not edited; a later record corrects it.
The correction is written into the new `## History — gravito_truthful_name_cleanup_a`
block in `current_state.md` and into this receipt, and the prior block is left
byte-unchanged.

**The three citations that bullet carries are repointed BY CONTENT, and checked for
SEMANTICS — the distinction this packet exists to enforce:**

| Old citation | New citation | Content at the new site | Semantically right for the citing record? |
|---|---|---|---|
| `tests/build_os_maintenance_tests.sh:1831` | **`:1873`** | `# IT IS NOT "exactly when the inbound protection fires", AND THAT WORDING IS` | **Yes** — the record cited it as *"still carries it"*; the successor site is the **withdrawal of exactly that wording**, which is where a reader chasing that claim must land |
| `CHANGELOG.md:69` | **`:125`** | `**THAT CONDITION IS NOT *"exactly when the inbound protection fires"*, AND` | **Yes** — same shape |
| `rotate-memory.mjs:2617` | **`:2673`** | `export function delimiterMatchedNothing(report) {` | **Yes** — byte-identical to its base content at `6454220:2617` |

### 5.2 CONDITION 2 — a provenance gap in WORDING, not a numeric discrepancy

**qa could not reproduce the builder's per-suite vector digest.** The builder's
commit message states `sha256 c5b6fe58e8dcf9e3...` **without stating the extraction
recipe**. qa tried **six** normalisation variants and got **six different values**.

qa then verified the **substantive** property under **its own stated recipe**, and
that is the number of record:

```
grep -E '^  CHAINED: ' <full-capture>   →  20 lines
sha256                                  →  0d5b87a84bd2fe42380aab80aeee0bb308584df9ed1332f271db3e18aa504ed4
```

**byte-identical across both runs.** The archivist **reproduced qa's digest exactly**
at this close from a fresh solo full-capture run: same recipe, same 20 lines, same
`0d5b87a84bd2fe42…`.

**This is a provenance gap in wording, not a numeric discrepancy.** Nothing about
the suite is in doubt; a digest was published without the function that produced
it, which makes it unverifiable by anyone but its author. **Standing rule from
here: state the recipe beside any digest.**

### 5.3 CONDITION 3 — the schema assertion generalises from n = 1. RECORDED, NOT FIXED.

`tests/build_os_maintenance_tests.sh:2120-2123` reads
`sentinel_report_schema` from **exactly one** report (`b.json`) and then states the
property **universally**:

> *"every sentinel report carries `sentinel_report_schema` 2, so the field rename
> is a VERSIONED break a consumer can branch on"*

**THE CLAIM IS TRUE** — qa verified it across **3 live records spanning ALLOW and
REFUSE**, and it is a **single unconditional assignment** in `evaluateSentinel`, so
there is no path that omits it. **But the assertion does not establish it.**

Recorded as an **evidence-scope nit of exactly the species this sequence exists to
eliminate**: a message quantifying over a population from a sample of one. **No fix
was built**, by instruction and because a fix would have opened a fix round the
verdict did not call for.

### 5.4 CONDITION 4 — a message coupled to assertions it does not itself guard. RECORDED, NOT FIXED.

`XFILE C4 (6, both poles)`'s `ok()` string
(`tests/build_os_maintenance_tests.sh:2098`) names **four** roots — *marker removed
/ owning-declaration only / third file*, plus the positive — while its condition
(`:2097`) tests **two**: `b.json` and `c4-nm.json`.

**Nothing is unproven.** The other two roots are asserted **separately, immediately
above**, each with a real `no` branch (`:2089`/`:2091` for the third-file root, and
the owner-decl-only root in the same run). But the message is **coupled to
assertions it does not itself guard**: delete the assertions above and this one
still passes while still claiming four roots. **Recorded; not fixed.**

---

## 6. Also recorded

### 6.1 The citation trap, demonstrated rather than asserted

Left un-repointed, `control_registry.txt`'s `:2617` would have landed on
`case "--max-bytes":` and `:2625` on the `--keep must be an integer >= 1` throw —
**and BOTH would still have RESOLVED and passed the vacuity check.** The guard
tests existence, numeracy, in-bounds and not-blank; it does not test meaning.

The drift was created by **this packet's own +56 lines** in `rotate-memory.mjs` and
**repaired before shipping**. All five targets verified **byte-identical to their
base content AND semantically correct for the record citing them**:

| Control | Old → New | Content |
|---|---|---|
| `maint.rotation_conservation` | `:2161 → :2217` | the `EXIT.CEILING` throw named in its own `failure_behavior` |
| `maint.rotation_live_file_replacement` | `:2349 → :2405` | staging write |
| `maint.rotation_live_file_replacement` | `:2373 → :2429` | atomic rename |
| `maint.rotation_zero_block_warning` | `:2617 → :2673` | `delimiterMatchedNothing` |
| `maint.rotation_zero_block_warning` | `:2625 → :2681` | its warning text |

plus `mutator_registry.txt`'s MUT rotation refs and the `:2373`/`:2349` numerals in
its notes prose, and `suite.build_os_maintenance` `:2137/:2138 → :2434/:2435`.

`evidence_ref` total **374 → 376 DERIVED** with the registry's own recipe
(`build-os/registry/README.md`, recomputed by `tests/control_registry_tests.sh`
§25, which fails if any stated total disagrees). **The delta is exactly the two new
fitted floors `:2121` / `:2146`**, both **REGISTERED** to
`tests.nonvacuity_minimums` rather than excluded.

### 6.2 `residue.md` stays frozen, and nothing in the new prose implies otherwise

The reviewer grepped **every added line**. Every residue mention is either the
`(S1)`/`(o)` **owning-declaration** shape used to justify the rename, or a
**fixture path**. The CHANGELOG's *"HONEST NEGATIVE RESULT — still not rotatable,
floor 25 of 25"* paragraph **survives unmodified**.

Blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9` at `6454220`, `61bee02`, `ab5d533`
and this close. `residue.md` is **204369 B with 431 B of headroom** and remains
**UNROTATABLE at floor 25 of 25**.

### 6.3 `MISMATCHES.md:81 → rotate-memory.mjs:1006` drifted further — PRE-EXISTING

Base content at `6454220:1006`: `declaredAt.set(id, { block: at, line: i + 1 });`
HEAD content at `ab5d533:1006`: `archived[i] = blockNo >= 1 && blockArchived;`

**Pre-existing.** Already recorded in `current_state.md` as **stale at base
`74575ee`**. Noted here so it is **not re-discovered as new**. **Not fixed under
this close**, by instruction.

### 6.4 Second eyes — NONE, and the streak is DERIVED

**23rd consecutive single-model packet.** Derived, not remembered:
`ls build-os/receipts/gravito_*.md | wc -l` = **23** with this receipt.
`build-os/memory/tool_router.md:368` advanced **22 → 23 in this same close
commit**, because `DC-0001` binds that numeral to the receipt store and
`scan-controls counts` refuses at **exit 2** the moment they disagree. `counts`
verified **exit 0** before committing.

Codex remains absent from every surface measured: `which codex` exits 1 and no
plugin directory exists. **No second-eyes note exists for this packet because no
second provider was available**, not because one was skipped.

---

## 7. The trajectory judgement — the sequence's closing finding

### 7.1 What it reversed, verbatim

Asked whether this packet reversed the trend the previous reviewer named — *"this
codebase is accumulating safety claims about safety claims faster than it is
accumulating enforcement"* — the reviewer answered:

> **"Locally reversed — modestly, and in the right currency."**

The fix was a **rename plus the DELETION of a claim**, not a new mechanism:
enforcement surface unchanged, one false label gone. The fixture-C differential
converted a **described** property into **executed assertions** on roots whose
one-fact difference is itself proved by `diff`/`cmp` **before** measurement —

> **"enforcement added, not claim added, and the first thing in this sequence that
> raised the enforcement side of the ratio rather than the claim side."**

### 7.2 What it did NOT reverse — the thing to leave behind

**`rotate-memory.mjs` grew 56 lines for a rename, roughly 50 of them comment, and
`CHANGELOG.md` grew 54 for the same rename.** The narration-to-code ratio is
**unchanged**, and reducing it was **out of scope**.

> **"The sentinel is correct, and the remaining excess is prose, not predicates."**

---

## 8. QA proof

| Item | Result |
|---|---|
| Full suite, solo foreground, run 1 | **2314 passed, 0 failed** |
| Full suite, solo foreground, run 2 | **2314 passed, 0 failed** |
| Anchored `pgrep -fa '^bash tests/'` before each run | empty |
| Exit codes | captured directly; **never piped through `tail`** |
| Per-suite CHAINED vector across runs | **byte-identical** — 20 lines, sha256 `0d5b87a84bd2fe42…` under `grep -E '^  CHAINED: '` (`DEFECT-0013`) |
| Attribution by execution vs base `6454220` (**2302/0**) | `tests/build_os_maintenance_tests.sh` **191 → 203 (+12)**; **all 19 other chained suites +0** |
| **Commit-1 isolation `61bee02`** | **2302 / 0 — GREEN** |
| `RELEASE_METADATA_LIVE_SUITE=1` | **44 / 0**; live total **2314** matching `CHANGELOG.md` (one unsplit `**2314 passed**`) and `current_state.md` |
| `scan-controls.sh check` | **exit 0** |
| `scan-controls.sh counts` | **exit 0** (`DC-0001` 23/23 after this close) |
| `scan-controls.sh anchors` | **exit 0** — `ANC-0003` **RESOLVED** at `build-os/packets/active_packet.md:89` |
| `scan-controls.sh surfaces` | **exit 0** |
| `bandwidth-check.sh` | **exit 0** — 1 packet in flight during the packet; 0 after this close |
| Safety grep — census | **105** (`grep -c '^control: '`) |
| Safety grep — declared mismatches | **22** (`grep -c '^authority_mismatch: declared'` — **anchor the pattern**; unanchored returns **27** and is **wrong**) |
| Re-authorisations | **0** |
| UI smoke | **N/A** — no UI surface in this packet; no frontend path was touched |

---

## 9. Residue

**Deferred, recorded, deliberately not built:**

- **(§5.3)** `tests/build_os_maintenance_tests.sh:2120-2123` states a universal
  schema property from **n = 1**. Claim true, assertion insufficient. Cheap to fix
  (loop the 5 emitted reports the section already writes) whenever that file is
  next open.
- **(§5.4)** `XFILE C4 (6, both poles)`'s `ok()` string names four roots against a
  two-root condition. Cosmetic in effect, structural in kind.
- **(§6.3)** `MISMATCHES.md:81 → rotate-memory.mjs:1006` — stale since base
  `74575ee`, drifted further. Belongs to the citation-anchor class, not to this
  packet.
- **(§7.2)** The **narration-to-code ratio**. `rotate-memory.mjs` and `CHANGELOG.md`
  each spent ~55 lines on a rename. Nothing enforces a ratio and nothing here
  proposes one.

**Known risks carried forward:**

- **`bandwidth.active_packet_singleton` still permits ZERO declared packets.**
  This packet complied by hand; the guard would not have caught omission.
  `OCCURRENCE-0005`'s named remedy remains **unbuilt**, now six occurrences later.
- **`current_state.md` headroom is 7574 B** (197226 B against the 204800 B
  ceiling), down from 31102 B at `6454220`. **ROTATION #4 IS THE NEXT THING THIS
  FILE NEEDS.** Derive the size before writing; do not quote one from memory.
- **`residue.md` is unrotatable at floor 25 of 25** and has **431 B** of headroom.
  It is frozen and must not be written.
- **The citation guard still tests resolvability, not identity.** §6.1 is a
  demonstration of the hole, not a closure of it.

---

## 10. Open boundaries — pending explicit go

- **NO PUSH. NO MERGE. NO PR. NO TAG. NO DEPLOY.** `6454220` is the pushed tip;
  `61bee02`, `ab5d533` and this close commit are **local and unpushed**.
- **No secrets touched, no `git config`, no amend, no rebase.**
- **Nothing is staged in `active_packet.md`.** Per the operator's ruling this was
  the **last governance packet**; work returns to **Repository Core and live
  provider execution**. The standing backlog in `current_state.md` is a **record,
  not a queue** — cutting the next packet is the operator's act.

---

*Written by the archivist at the close of `PACKET-0044-truthful-name-cleanup`.
Receipts are append-only history; this file corrects earlier records by later
record, and rewrites none of them.*
