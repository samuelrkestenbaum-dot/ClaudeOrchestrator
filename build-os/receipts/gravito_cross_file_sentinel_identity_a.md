# Receipt — `gravito_cross_file_sentinel_identity_a`

**Cross-file sentinel identity resolution for the governed rotation guard.**

| | |
|---|---|
| packet id | **NONE — THE PACKET WAS NEVER DECLARED.** See §7.1; recorded as `DEFECT-0011` / `OCCURRENCE-0020`, **attributed to the orchestrator** |
| date | 2026-08-04 |
| lane | `substantive` |
| depth | **4 — `mandatory_full_regate`**, announced and legitimate (§2.3). **Not recorded as a defect.** |
| branch base | `74575ee`, verified `git merge-base HEAD 74575ee` → `74575ee` |
| commits | `905b69e`, `0d3a34f` (**2 BUILD**) + `1918fc3` (**1 FIX**) = **3 of 3, inside the typed budget** |
| HEAD at verdict | `1918fc3` |
| qa | **GREEN** |
| reviewer | **fix-then-pass (4 items)** → **PASS-AS-FIXED** |
| second eyes | **NONE — twenty-second consecutive packet** (§7.3) |
| pushed tip | `5d96031`. **Nothing pushed, merged, PR'd, tagged or deployed.** |

---

## 1. THE HEADLINE IS A NEGATIVE RESULT

**The packet did not achieve what it was cut to achieve, and it proved that against its own
interest.**

`build-os/memory/residue.md` **is still unrotatable.** Its `minimum_safe_keep` is **25 of 25**. qa
cleared C2 the tool's own way and then swept **every keep from 1 to 25**:

- keeps **1–24** trip **C1**;
- keep **25** trips **C7** at **431 B**, having archived **nothing**.

**C2 was never the binding constraint.** `(o)` and `(S1)` are declared in `residue.md`'s **own
block 25** and are genuinely live, so the own-file path — not the cross-file one — is what pins the
floor. **The diagnosis that motivated this packet was wrong.** The tool's C7 text now *names* the
dead end and the operator remedies rather than leaving the reader to derive them, which is the only
thing a correct implementation of a wrong diagnosis can usefully deliver.

### 1.1 What it DID achieve

- **Cross-file identity resolution, proven a two-sided win by execution.** C2's **inbound** half
  verified **1 → 6** in a root where the owner protects nothing itself — a root in which own-file
  protection *cannot* be the answer, so the widening is doing real work somewhere even though it is
  not doing it in `residue.md`.
- **`current_state.md` relieved by rotation #3.** Headroom **3,642 → 31,102 B** (size
  **201,158 → 173,075 B** at `0d3a34f`), at `--keep 15`, window `[14, 16]` **executed at both
  bounds**. No ceiling was raised; the remedy was a rotation.
- **`active_packet.md` went from permanently unrotatable to ALLOW** — but see §6.4: that is
  **keep-conditional**.
- **The packet caught its own FAIL-OPEN before shipping.** A live, canonically declared,
  non-consumable object was being **archived at exit 0** under **four** ordinary prose forms of a
  genuinely live rule, one of them a **plain markdown blockquote** — the most conventional way
  anyone writes a standing rule. The base tool refused all four at exit 7.
  **It was caught by a single-model chain, and only because the builder was pushed back on.**

---

## 2. Scope

### 2.1 In

- Resolve a sentinel identity across the **governed memory set**, not within one file
  (`markerNamingsIn`, `inboundProtections`, the cross-file index, and the quoted-marker demotion).
- Drive the behaviour red first, then green, in `tests/build_os_maintenance_tests.sh` §11.
- Execute **rotation #3** under the new resolver, with pre-registration and an append-only archive.
- Record the result **including the negative one**.

### 2.2 Explicitly OUT

- **Any write to `build-os/memory/residue.md`** — FROZEN, blob
  `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, **204,369 B / 2,379 lines, 431 B of headroom**,
  unrotatable at every legal keep. **Blob identical at `74575ee`, `905b69e`, `0d3a34f`, `1918fc3`
  and in the worktree at the close.**
- Raising **any** byte ceiling, including `DEFAULT_MAX_BYTES`. **None was raised.**
- `build-os/metrics/rank-candidates.sh`, `decision_telemetry.tsv`, `signal_snapshots.tsv`,
  `residue.archive.md`, and `build-os/memory/standing_gates.md` — the last of which **must stay
  UNREAD**; both no-read claim sites (`rotate-memory.mjs:53`, `rotate-memory.sh:38`) are intact and
  **it was not read at this close**.
- Widening `markerNamingsIn` or any demotion predicate. **Widening would re-open the hole.**

### 2.3 Depth 4 — why it is legitimate

`mandatory_full_regate` requires all five conditions, and all five held:

1. the reviewer's fix list arrived **complete, in one installment**;
2. the packet was **correctly scoped**;
3. the fixes altered the **demotion predicate itself** — load-bearing logic;
4. the contract's own re-review rules therefore **forbid targeted confirmation**;
5. a full concurrent re-gate (qa ‖ reviewer) was required and was run.

It was **announced by name** before the stage opened. **Under that condition depth 4 is not a
defect and is not recorded as one.**

---

## 3. Commits, and the file-ownership manifest

### 3.1 Commits

| sha | kind | subject |
|---|---|---|
| `905b69e` | **BUILD 1** | `feat(sentinel): resolve identity across the governed memory set, not within one file` |
| `0d3a34f` | **BUILD 2** | `rotation #3: relieve current_state.md at --keep 15, under the cross-file resolver` |
| `1918fc3` | **FIX** | `fix round: require the identity be PROTECTED elsewhere, not merely DECLARED there` |

**3 of 3, inside the typed budget (build ≤2, fix ≤1). `1918fc3` IS THE PERMITTED FIX COMMIT AND IS
DELIBERATELY NOT LOGGED AS A DOCTRINE BREACH** — the doctrine installed by the previous packet
forbids exactly that, and logging it would be ritual rather than enforcement.

### 3.2 Disjoint file-ownership manifest — all 11 paths

**SINGLE-WRITER. No fan-out ran**, so no two agents could contend and the merger question does not
arise. The manifest is recorded anyway, because a *missing* manifest broke a prior close.

| path | commits | +/− (per-commit) | sole owner |
|---|---|---|---|
| `CHANGELOG.md` | `905b69e`, `1918fc3` | +74 / −7 | shared |
| `build-os/maintenance/rotate-memory.mjs` | `905b69e`, `1918fc3` | +852 / −135 | shared |
| `build-os/memory/current_state.md` | all three | +28 / −339 | shared |
| `build-os/registry/control_registry.txt` | `905b69e`, `1918fc3` | +8 / −8 | shared |
| `build-os/registry/mutator_registry.txt` | `905b69e`, `1918fc3` | +3 / −3 | shared |
| `tests/build_os_maintenance_tests.sh` | `905b69e`, `1918fc3` | +605 / −16 | shared |
| `build-os/memory/archive/PRE-REGISTRATION-rotation-3.json` | `905b69e` | +14 / −0 | **`905b69e`** |
| `build-os/memory/archive/INDEX.md` | `0d3a34f` | +8 / −0 | **`0d3a34f`** |
| `build-os/memory/archive/ROTATION-RECEIPT-2026-08-04T13-28-50Z.md` | `0d3a34f` | +139 / −0 | **`0d3a34f`** |
| `build-os/memory/archive/current_state.archive.md` | `0d3a34f` | +332 / −0 | **`0d3a34f`** |
| `build-os/memory/archive/ROTATION-RECEIPT-2026-08-04T13-28-50Z-CORRECTION-1.md` | `1918fc3` | +54 / −0 | **`1918fc3`** |

**5 paths solely owned, 6 shared, 11 distinct, 18 path-visits.**

### 3.3 The two numstat conventions disagree, and the gap is fully accounted

- **Per-commit sums** (`record-packet.sh --verify-git`'s convention, `git show --numstat` over the
  three commits): **11 files / 2117 insertions / 508 deletions.**
- **Net union diff** (`git diff --numstat 74575ee 1918fc3`): **11 files / 2020 / 411.**
- **Gap: exactly 97 insertions and 97 deletions**, symmetric, because six paths were touched by more
  than one commit and the union nets the overlap away.

### 3.4 The archivist's close is a SEPARATE write set and is not in the metrics row

`build-os/receipts/gravito_cross_file_sentinel_identity_a.md`,
`build-os/memory/current_state.md`, `build-os/packets/active_packet.md`,
`build-os/memory/tool_router.md` (the `DC-0001` numeral only),
`build-os/registry/defect_classes.txt` (append only),
`build-os/registry/control_registry.txt` (one `evidence_refs` line),
`build-os/maintenance/rotate-memory.mjs` (**comments only, 16 lines in / 16 lines out**), and
`build-os/metrics/packet_metrics.tsv`.

---

## 4. QA proof

| measurement | result |
|---|---|
| suite total | **2302 passed / 0 failed**, **twice solo**, per-suite vectors **byte-identical** |
| delta from base | **+37** from `74575ee` (**2265 → 2302**) |
| attribution by execution | `74575ee → 1918fc3`: all +37 in `tests/build_os_maintenance_tests.sh` (**154 → 191**); **all 19 other suites +0**, root-level **+0** |
| finest attribution | `0d3a34f → 1918fc3` moves **exactly one vector line** — `build_os_maintenance_tests.sh` **182 → 191** |
| section 11 | **37 PASS / 0 FAIL**, counted directly |
| **Commit-1 isolation** | **`905b69e` → 2293 / 0, GREEN** |
| live suite | `RELEASE_METADATA_LIVE_SUITE=1` → **44 / 0**; live total **2302**, matching |
| safety greps / gates | `scan-controls` **×4** and `bandwidth-check` — **all exit 0** |
| census | **105** controls, `grep -c '^control: '` |
| declared mismatches | **22**, `grep -c '^authority_mismatch: declared'` (**anchored**; the unanchored form returns **27** and is wrong) |
| re-authorisations | **0** |
| rotation #3 reconstruction | **byte-exact, md5 `9f312f93…`**; `--keep 15` window executed at **both** bounds |
| archive append-only | verified by `cmp` over the correct **37,829 B** prefix, **zero gap**; the next **280 B** are exactly the batch banner (**37,829 + 280 = 38,109**) |
| UI smoke | **N/A** — no UI surface in this packet |
| protocol | suite run **ALONE, in the foreground**, after an anchored `pgrep -fa '^bash tests/'` returned empty; **never piped through `tail`** |

### 4.1 qa's correction to the refusal-code set

HEAD fires **`C1 C3`** where base fires **`C1 C2 C3`**. **C2 correctly no longer fires** because the
identity now resolves cross-file. That is **the widening working, not a regression**, and it is
recorded here so nobody later reads the shorter set as a loss of coverage.

---

## 5. The four close conditions — discharged in this commit

### 5.1 The "safe iff" overclaim, five sites

Five sites said the demotion condition is *"exactly the condition under which `inboundProtections`
really does protect it there."* **That is false, twice over:**

1. `inboundProtections` **skips `fileName === spec.name`** (`rotate-memory.mjs:1134`), so it can
   **never** protect an object in its *own* file. The **own-file (4a) path** does that.
2. The condition is **sufficient, not necessary.** `(S1)` is protected in `residue.md` by a marker
   naming it while `markedIn` is empty, because `markerNamingsIn` skips quoted markers and (4a)
   does not.

**What is true and executable, and what the corrected sites now say:**

> Demotion **implies** the owner carries a **non-quoted marker naming the identity**, which
> **implies** the identity is **anchored at its declaration block in the owning file**. The
> condition is **deliberately narrower** than "protected at home", and **the gap fails CLOSED.**

**NO PREDICATE WAS WIDENED. Widening would re-open the hole.** The edits are **comments only** and
**line-count-neutral** (16 in / 16 out), so nothing below them moved and no citation into
`rotate-memory.mjs` was disturbed.

| site | status |
|---|---|
| `build-os/maintenance/rotate-memory.mjs:1085-1090` | **corrected** |
| `build-os/maintenance/rotate-memory.mjs:1175-1181` | **corrected** |
| `build-os/maintenance/rotate-memory.mjs:1462-1463` | **corrected** |
| `tests/build_os_maintenance_tests.sh:1831` | **NOT corrected — outside the archivist's write boundary.** See §8. |
| `CHANGELOG.md:69` | **NOT corrected — outside the archivist's write boundary.** See §8. |

### 5.2 `control_registry.txt:691` — content-preserving but semantically WRONG

`maint.rotation_zero_block_warning` cited `build-os/maintenance/rotate-memory.mjs:2569`, which lands
on:

```
    throw new RotateError(EXIT.USAGE, `--keep must be an integer >= 1 (got ${opts.keep})`);
```

— argument validation in `parseArgs`, with **nothing to do with** a zero-block warning. The correct
target is **`:2617`**:

```
export function delimiterMatchedNothing(report) {
```

**Repointed by content to `:2617`.** The sibling ref `:2625` was checked and is right (it is inside
the warning text `renderDelimiterWarning` emits) and was left alone.

**THE TWO GATES APPEARED TO DISAGREE AND DID NOT, AND THE DISTINCTION IS THE LESSON:**

- **qa** verified every repoint in the packet was **content-preserving** — old line bytes = new line
  bytes. True.
- **The reviewer** found all five `.mjs` citations moved by exactly **+150** and the `.sh` pair by
  **+208**, faithfully carrying forward a target that was **already wrong at `0d3a34f`**. Also true.

**CONTENT-PRESERVING IS NOT SEMANTICALLY CORRECT.** A mechanical offset preserves whatever it was
pointed at, including a mistake. This is **this session's recurring defect class appearing inside
the repointing method itself** — a procedure that promises more than its predicate delivers.

**Also recorded, deliberately not changed:** `:673`'s `maint.rotation_conservation` cites
`rotate-memory.mjs:2161`, which now lands on the **`EXIT.CEILING` throw** while its former content
sits at **`:2693`**. That is **defensible** — the record is about conservation and ceiling refusals —
but it was **inherited from an offset rather than chosen**, and saying so is the difference between
a citation and a coincidence.

### 5.3 `rotate-memory.mjs:1168-1173` understated its own evidence

It said *"three ordinary prose forms"* and *"the base tool refused all three"*. **Four** were built
and driven, and **qa independently drove four**. It contradicted the commit message, the CHANGELOG
and the test, all of which say four. **Corrected to four.**

**This one UNDERSTATES, which is the safe direction** — a comment claiming less evidence than exists
cannot license anything it should not. It is still wrong and is still fixed.

### 5.4 Commit `1918fc3`'s message — 431 B is the HEADROOM, not the size

The message says *"residue.md untouched at blob 01517ad2, 431 B"*. **The blob is exact.** But
**431 B is the headroom against the 204,800 B ceiling, not the file size** — `residue.md` is
**204,369 B / 2,379 lines**.

**It sits in an immutable commit message. Recorded here as a LATER CORRECTION. History is NOT
rewritten** — no amend, no rebase. The same distinction, made in the same session, is why
`ROTATION-RECEIPT-2026-08-04T13-28-50Z-CORRECTION-1.md` exists rather than an edit to the receipt it
corrects.

---

## 6. Also recorded

### 6.1 The reviewer's summary judgement, verbatim

> *"this codebase is accumulating safety claims about safety claims faster than it is accumulating
> enforcement."*

**Three instances in this packet alone** of a name promising more than its predicate delivers: the
`"safe iff"` label (§5.1), `protected_in_owner` (§9.1), and the `*own-file*` differential that is
not one (§9.2). The `markerNamingsIn` **"one scan, two consumers"** pattern is the **right
antidote** — and it **shipped with a new overclaiming label attached to it.**

### 6.2 The demotion moves no floor on this tree

The reviewer **disabled the demotion entirely** and re-derived every floor: **identical
(25 / 5 / 32)**. It **fires twice** and is **not currently paying for its risk surface**. Bounded
and correct — but a mechanism that changes no outcome while owning a fail-open path is a standing
cost, and the fact belongs on the record rather than in nobody's head.

### 6.3 `HISTORICAL_REFERENCE` is fixture-only

**No governed file carries `## ARCHIVED BATCH`.** The tool writes that marker only into
`*.archive.md`, which is **outside the governed set**. The enum is *"five classes emitted"* **in a
test root**, not on the tree.

### 6.4 "Still ALLOW" for `active_packet.md` is KEEP-CONDITIONAL

Floor **32**. `--keep 15` **REFUSES**. "ALLOW" without the keep is a claim the tool does not make.

### 6.5 The orchestrator was wrong about the M5 counts, and said so

The orchestrator asserted the M5 counts went **stale after rotation #3**. **Both gates measured them
identical at `74575ee`, `0d3a34f` and `1918fc3`** — `22 → 19` pins `3 → 0`; `5 → 3` pins `2 → 0` —
and `residue.md` is **byte-identical across the whole range** (blob `01517ad2…` at all four
commits), so it **cannot** have drifted.

**They were already stale at base.** Provenance: two independent gate measurements plus a blob
identity that makes the alternative impossible.

**One honest gap in this record:** no on-tree store carries the label `M5`; it is the gates'
shorthand for this session. That is recorded as-is rather than resolved into a citation the
archivist would have had to invent.

### 6.6 Three limitations the packet recorded rather than buried

1. **`build-os/registry/MISMATCHES.md:81`** cites `rotate-memory.mjs:1006`. At base `74575ee` that
   line was a bare ` */`. **Already stale at base** — verified by
   `git show 74575ee:build-os/maintenance/rotate-memory.mjs | sed -n '1006p'`.
2. **The shallow-anchor fallback.**
3. **C8 is not gated on `armed`.**

Plus: the CHANGELOG **narrows** *"cannot be defeated by rewording"* from the **guard** to the
**demotion**. `SENTINEL_MARKERS` is still **seven fixed phrases**, and the entry now says so.

---

## 7. Process findings

### 7.1 `DEFECT-0011` — THE PACKET WAS NEVER DECLARED. IT IS THE ORCHESTRATOR'S.

`build-os/packets/active_packet.md:7` read `## CLOSED — … NOTHING IN FLIGHT` for the **entire life
of the packet**, at all three commits. The orchestrator **dispatched without declaring**.

**Recorded as `OCCURRENCE-0020` against `DEFECT-0011-undeclared-active-packet`, attributed to the
ORCHESTRATOR** — declaration is the orchestrator's commit, not the builder's.

**The builder flagged it and correctly REFUSED to fix it**, and the refusal was right on the merits:
the head block is **line-count-pinned by `ANC-0003` at `:89`**, whose resolved line number is
embedded in the committed kernel projection and compared with `cmp -s` by
`tests/memory_kernel_tests.sh` §18. A builder writing the declaration mid-packet would have
**re-fired `DEFECT-0001-stale-line-reference`** at the exact site that class has fired at for
**three consecutive declarations**.

**THE COUPLING IS THE REAL FINDING:** the site where a packet *must* be declared is the same site a
resolved line number is *pinned to*, so **every declaration trades one defect class against the
other.** This packet resolved that trade by declining to declare — which is a defect, but a
*recorded* one rather than a red suite.

`bandwidth.active_packet_singleton` passed throughout, because **it refuses two declarations and
permits zero.** The lower bound named as the remedy at `OCCURRENCE-0005` remains **unbuilt, five
occurrences later.**

The archivist's close replaces that head block **21 lines for 21 lines** and verifies `ANC-0003`
still resolves at **`:89`**.

### 7.2 The commit budget is NOT a deviation

`905b69e` + `0d3a34f` = **2 BUILD**; `1918fc3` = **1 FIX**. **3 of 3 under the typed budget.** The
fix commit introduced no new subsystem, expanded no objective, added no unrelated governance,
rewrote no measured commit, and concealed nothing. **It is not logged as a breach.**

### 7.3 Second eyes: NONE — twenty-second consecutive packet

Derived, not remembered: `ls build-os/receipts/gravito_*.md | wc -l` = **22** with this receipt.
`DC-0001` binds that figure to `build-os/memory/tool_router.md:368`, so the numeral was advanced
**21 → 22 in this same commit**; otherwise `scan-controls counts` and `check` go to **exit 2**.

**This is the tenth-plus consecutive packet routing to an absent tool, and it is not a bookkeeping
line this time.** This packet's central defect was a **fail-open that archived a live object at exit
0**. It was caught by a **single-model chain**, and only because **the builder was pushed back on**.
The review discipline that found it is not a mechanism; it is a person insisting.

---

## 8. Open boundaries

- **No push, merge, PR, tag, deploy, secret access, `git config`, amend or rebase.** `5d96031` is
  the pushed tip; **7 commits above it are local**, and this close makes 8. **Merging and pushing
  remain pending an explicit go from the operator.**
- **TWO CORRECTION SITES LEFT UNMADE, AND THIS IS A DECLARED BOUNDARY, NOT AN OVERSIGHT.**
  `tests/build_os_maintenance_tests.sh:1831` and `CHANGELOG.md:69` still carry the §5.1 overclaim.
  Both are **outside `build-os/`**, and the archivist writes **only** under `build-os/`. Expanding
  that budget silently is exactly the breach the per-task protocol forbids. **The exact replacement
  text is in §5.1; the two sites are carried into `PACKET-0044` as item 3.**
- `build-os/memory/standing_gates.md` was **not read** at this close, and both no-read claim sites
  (`rotate-memory.mjs:53`, `rotate-memory.sh:38`) are intact.

---

## 9. Residue — deferred to `PACKET-0044`, RECORDED AND NOT BUILT

The doctrine's remedy for a second fix round is a **re-cut**, and stage 5 is closed. Both items
below are real defects and are **deliberately not fixed here**.

`PACKET-0044` was **collision-checked before the mint**:
`grep -rlF 'PACKET-0044' . --exclude-dir=.git` → **0 files**;
`git log -S'PACKET-0044' --all --oneline` → **0 commits**.

### 9.1 `rotate-memory.mjs:1476` — `protected_in_owner` is emitted `false` for objects that ARE protected in their owner

`(S1)` and `(o)` are both anchored in `residue.md` block 25 and both report `protected_in_owner:
false`. The predicate actually computes *named by a **non-quoted marker** in the owner*.

**THE FIX IS TO RENAME THE FIELD, AND THE LOCAL AT `:1464` (`protectedAtHome`) — e.g.
`marker_named_in_owner`. IT IS NOT TO WIDEN `markerNamingsIn`,** which would widen the demotion and
**re-open the hole**.

This is **the packet's own disease** — a name promising more than its predicate delivers — and it
deserves a **gated fix, not bookkeeping**.

### 9.2 `tests/build_os_maintenance_tests.sh:1795-1797` — the `*own-file*` check is not a differential

Its `ok()` string claims it is. **Both roots yield `own-file`** by ordering and dedupe, so the check
passes for a reason unrelated to what it asserts. **The executable statement belongs in the
`orphan` root:** `residue.md`'s floor must **stay 1**, not rise to the `(qqq)` declaration block.

### 9.3 Carried in from this close

The two out-of-boundary correction sites from §8.

### 9.4 Known risks left standing

- The `bandwidth.active_packet_singleton` **lower bound** is still unbuilt (§7.1) — the class will
  fire again.
- The **declaration / `ANC-0003` coupling** (§7.1) makes every future declaration a
  `DEFECT-0001` hazard until the projection stops embedding a resolved line number.
- The **demotion pays a risk surface for zero floor movement** on this tree (§6.2).
- **`SENTINEL_MARKERS` is seven fixed phrases.** The guard *can* be defeated by rewording; only the
  **demotion** cannot.

`PACKET-0043-derived-restatement-sweep` remains **staged and undeclared** from the previous close.

---

## 10. Close state

| | |
|---|---|
| `build-os/memory/residue.md` | **NOT WRITTEN.** Blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, **204,369 B / 2,379 lines**, **431 B headroom**, floor 25 of 25 |
| `build-os/memory/current_state.md` | advanced; see the hand-back for the post-commit size and headroom |
| `build-os/packets/active_packet.md` | closed packet cleared, **`ANC-0003` still at `:89`**, **0** declared packet ids, `PACKET-0043` and `PACKET-0044` staged undeclared |
| byte ceilings | **none raised anywhere**, including `DEFAULT_MAX_BYTES` |
| metrics | one row appended to `build-os/metrics/packet_metrics.tsv` with the §3.2 manifest |
