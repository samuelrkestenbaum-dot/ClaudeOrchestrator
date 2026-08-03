# Receipt — `gravito_current_state_reblock_a`

- **Packet id (canonical):** `PACKET-0038-current-state-reblock`
- **Date:** 2026-08-03
- **Lane:** `substantive`. **Depth: 3 serial stages** — (1) builder; (2) qa ‖
  reviewer concurrently; (3) one bounded six-item fix round. **No stage 4.**
- **Base:** `9c740d7`, on `claude/project-handoff-merge-ramhds`, verified with
  `git merge-base` before the first edit and **re-derived at this close**
  (`git merge-base HEAD 9c740d7` → `9c740d735d476011198f9cf32225dc23b251e0b5`).
- **HEAD at close:** `d885657d13d4173d6aab3ffe46fa63deb8bdbf2e`.
- **Commits (3):**
  - `06e9f1c` — `docs(packet): declare gravito_current_state_reblock_a before building`
  - `b41aa5d` — `fix(memory): re-block current_state.md before it runs out of headroom, and prove the standing region cannot be reclaimed`
  - `d885657` — `fix round: disambiguate the line-count figure both gates were right about, and correct the migration delta from a move to a rename-plus-stub`
- **Verdict: PASS-AS-FIXED.** qa returned **GREEN**; the reviewer returned
  `fix-then-pass` with **2** enumerated items; both were closed in the fix round,
  together with **4 further corrections the orchestrator added** — **6 record
  corrections in total**, all prose, **2 files, +110 / −6**.
- **Second eyes: NONE, single-model — SEVENTEENTH CONSECUTIVE PACKET.**
  **Codex note, re-checked live at this close rather than carried over:**
  `build-os/memory/tool_router.md` names Codex (`codex` CLI / Codex-for-Claude-Code
  plugin) as the intended second-eyes provider; `which codex` **exits 1** and no
  plugin directory exists. The reviewer stated the line rather than omitting it.
  **The router's own self-report of the streak still says "nine"** — see residue
  item 5.
- **Nothing pushed, merged, tagged, PR'd or deployed.** No such go was given.
- **No commit was squashed, amended, rebased or rewritten at this close.**

### A NOTE ON HOW THIS RECEIPT CITES

The previous receipt cited **only** by content and carried no `path:line` token
at all. This one relaxes that by a measured amount, under three rules, because
the packet's own subject is what makes them necessary:

1. A **range** `path:N-M` names **two positions in the current tree**, so both
   ends decay together. Every range below is written **without its path**, with
   the file named in the surrounding prose — the form
   `tests/control_registry_tests.sh` §27d sweeps is `path:N-M`, and it has
   already caught the archivist twice.
2. An **arrow-pair** `path:N -> :M` names **the same content at two commits**. It
   is a historical record and is **never** repointed. Its two numbers must
   differ, which §27c enforces.
3. Everything load-bearing is stated **with the command that derives it**. No
   digit appears below without the derivation that produced it.

---

## THE OUTCOME

`build-os/memory/current_state.md` was taken out of the same dead end
`residue.md` was taken out of one packet earlier — and this time
**prospectively**, before the file ran out of headroom rather than after.

| quantity | base `9c740d7` | HEAD `d885657` | derivation |
|---|---|---|---|
| `^## ` blocks | **3** | **18** | `grep -c '^## ' build-os/memory/current_state.md` |
| size | 185,204 B | **188,188 B** | `wc -c` |
| archivable @ shipped `keep=10` | 0 blocks / **0 B** | 8 blocks / **66,332 B** | `node build-os/maintenance/rotate-memory.mjs --file current_state --keep 10` |
| post-rotation retained | 185,204 B (no-op) | **122,367 B** | same dry run, `live size` field |
| headroom under the 204,800 B ceiling | 19,596 B | **16,612 B** live / **82,433 B** after a `keep=10` rotation | `204800 − <size>` |

At base the tool reported `keep 3 newest, would archive 0` and
`nothing — already rotated (no-op)` at **exit 0**. At HEAD it reports
`18 total -> keep 10 newest, would archive 8` and
`block_11..block_18 (66332 B)`, conservation `OK … byte-exact`, still at exit 0.

**Recorded plainly rather than presented as pure gain: the live file got
BIGGER.** 188,188 − 185,204 = **+2,984 B**, so live headroom *fell* by 2,984 B.
What changed is not the size but the **reachability**: 0 B the tool could reclaim
became 66,332 B it can reclaim on one command. Those are different objects, and
saying so is the whole honest claim.

---

## THE CRUX — THE ORCHESTRATOR'S BRIEF WAS WRONG IN THE SAME DIRECTION AS LAST TIME, AND FOLLOWING IT WOULD HAVE ARCHIVED ALL THREE GATE-PINNED LITERALS

Rotation retains a **PREFIX** and archives the **TAIL**: `routeSegments` in
`build-os/maintenance/rotate-memory.mjs` computes `blocks.slice(0, keepN)` as the
*keep* set. Standing content must therefore sit at the **head** of the file.

**My original brief said the inverse** and directed standing content toward the
bottom. Had it been followed, the gate-pinned literals would have been written
into the tail and archived on the first rotation — the exact loss this packet
existed to prevent.

The builder did not comply and did not merely assert the contradiction: it
**demonstrated** the correction on a 5-block fixture (`--keep 2` archives
`block_3..block_5`, not `block_1..block_3`), **did not touch the tool** — the
tool was right, the brief was wrong — and **reported it**. **qa reproduced it
independently.** This is the second consecutive packet where a builder handed an
authoritative-sounding instruction that contradicts the source verified the
source and escalated. **Recorded again as a positive precedent, because a
precedent recorded once is an anecdote.**

Block 1 is now `## Standing truth — PROTECTED REGION (block 1; rotation cannot
reach it)` — derived at close with `grep -m1 '^## '`. Protection is
**structural, not an exemption**: `--keep` is validated `>= 1` and retention is a
prefix, so no legal invocation can reach block 1. The tool's own report still
reads `selection : RECENCY ONLY — no content is exempt from rotation`, and that
remains true; the region is safe **because of where it sits**.

### The two gate-pinned literals, and why they are two and not three

`tests/release_metadata_tests.sh` §5 reads exactly two literals out of this file
— `**Build/test command:**` and `**Last closed packet:**` — both with
`head -n1`, so an archived *first* occurrence would silently re-point the guard.
Re-derived at this close with `grep -nF`:

| literal | occurrences in file | inside block 1 | outside block 1 |
|---|---|---|---|
| `**Build/test command:**` | 1 | **1** | **0** |
| `**Last closed packet:**` | 1 | **1** | **0** |

**Nothing outside block 1 holds either.** qa's sweep over every legal `--keep`:
**18 rotated / 0 refused / 0 leak / 0 drift, 29 files** — block 1 byte-identical
at every keep, zero pinned literals reaching any archive artefact.

**The hazard was reproduced, not assumed.** qa drove the RED at **95 passed / 9
failed** with a gate-pinned literal placed where rotation genuinely reaches it,
and watched it arrive in the archive. A protection claim whose counterexample was
never executed is a hope.

---

## THE 15/15 DISAMBIGUATION — THE REASONING, NOT JUST THE EDIT

This is the most instructive thing in the packet and it is recorded as reasoning
because the edit alone is unreadable without it.

`build-os/registry/defect_classes.txt:369` and the `CHANGELOG.md` entry both said
the header note "was rewritten to be LINE-COUNT-NEUTRAL (**15 lines in, 15 lines
out**)". **The two gates disagreed about that sentence, and both of them were
right**, because the sentence conflated two different quantities that were each
truly measured:

- the edit **replaced 5 lines with 5 lines** — `diff` over the region reports
  **5 `<`** and **5 `>`**;
- the **note region is 15 lines on both sides** — `sed -n '10,24p' <file> | wc -l`
  returns **15 at base `06e9f1c` and 15 at HEAD**.

Both sites now state **both** figures with **both** derivations.

> **Swapping `15` → `5` would have discarded a true fact in order to repair a
> false reading. This was a disambiguation, not a digit swap.**

And the old wording is kept **visible as cited history** rather than overwritten.
That is not a stylistic preference: the entry it lives in, `OCCURRENCE-0018`, is
**a ledger of accuracy failures**. A silent overwrite of an inaccurate sentence
inside the ledger of inaccurate sentences leaves no trace of the very thing the
ledger exists to hold. The correction creates a later record; it does not edit
the earlier one.

**The load-bearing consequence was re-verified independently of the wording:**
lines `:25`..`:635` of `tests/build_os_maintenance_tests.sh` are byte-identical
base-to-HEAD (`cmp` clean), so the four citations into that file at `:88`,
`:193`, `:295` and `:414` **never moved**, and each was re-checked against what
its citer claims it says.

---

## FIX-ROUND ITEM 2 — NOT "ONE MARKER MOVED": A RENAME IN PLACE PLUS A NEW STUB

The migration record described a **move**. There was no move.

- The original site was **renamed in place** — `**Last closed packet:**` →
  `**Closed 2026-08-03:**`, at `build-os/memory/current_state.md:476` — and its
  **18-line entry is byte-identical** where it was written (`cmp` clean, base
  `:243-260` against HEAD `:477-494`; both spans written **without their path**,
  deliberately, per rule 1 above).
- A **new 4-line stub** was created under a **new `### Last close` heading** in
  block 1, pointing at that entry, so the literal `**Last closed packet:**` still
  occurs **exactly once** in the file — and now inside the protected region.
- **The stub's 4 lines and its heading fall OUTSIDE the "21 added lines"
  figure**, which counts the orientation note alone. That is the actual error:
  the substance was right (entry whole, literal present once) and the *mechanism*
  was mis-described.

**The full delta was then derived rather than restated, and it partitions
exactly.** `diff <(sort <base>) <(sort <head>) | grep '^>' | grep -vc '^> *$'` →
**57** added non-blank lines, **11** removed:

```
57 = 21 orientation note
   + 18 new `^## ` block headings
   +  3 `### ` headings (Project, Stable facts, Last close)
   +  3 stub continuation lines
   + 11 suite-total-claim lines
   +  1 renamed marker
```

A total that does not close is a total nobody checked. This one closes.

---

## FIX-ROUND ITEM 6 — TWO PRESERVATION MECHANISMS, AND THEY MUST NOT BE CONFLATED

`build-os/maintenance/rotate-memory.mjs:49` states the doctrine *"Preservation is
a property of LOCATION, not of text"*. **`LOCATION` there means WHICH FILE**:
content that must never rotate belongs in a file **absent from `FILE_SPECS`**,
which the tool never reads or writes.

**Pattern (A) — the one this packet and its predecessor actually use — protects
by POSITION WITHIN a rotating file.** These are **different mechanisms with
different failure modes**:

| mechanism | protects by | fails if |
|---|---|---|
| the `rotate-memory.mjs:49` doctrine | the file is not in `FILE_SPECS` | a path is added to `FILE_SPECS` |
| **pattern (A)** | standing region is block 1; retention is a prefix; `--keep >= 1` | anything is prepended above block 1, **or** a pinned literal gains a second occurrence outside it |

So **(A) is not an application of that header's doctrine**, and a future packet
must not cite the header as authority for positional protection. **Two memory
files now depend on (A).**

**Recorded in (A)'s favour, because the distinction is not a complaint:** all
three of its legs are pinned by **executed assertions rather than prose** —
including `case "$CS_HEAD_BLOCK" in "## Standing"*)` in
`tests/build_os_maintenance_tests.sh` at `:756`–`:757` (written without its path,
per rule 1), which catches exactly the future prepend that would silently demote
the standing region to block 2.

---

## THE OTHER THREE FIX-ROUND ITEMS

3. **The anchored derivation is named so nobody re-litigates it** — see the
   derivations table below.
4. **The stale pointer is queued with its measurement, and it predates this
   packet** — see residue item 1 below.
5. **The duplication debt is recorded as a choice, not built** — see residue
   item 2 below.

---

## DERIVATIONS — EVERY NUMBER WITH THE COMMAND THAT PRODUCED IT

**The mismatch count is ANCHORED, because the unanchored grep disagrees with the
tool and the tool is right.**

| derivation | value |
|---|---|
| `grep -c 'authority_mismatch: declared' build-os/registry/control_registry.txt` | 27 |
| `grep -c '^authority_mismatch: declared' build-os/registry/control_registry.txt` | **22** |
| `scan-controls.sh check` — over-authorised (declared) | **22** — matches the anchored form exactly |

The five-line gap is **commentary, not entries**: `build-os/registry/control_registry.txt:24`,
`:1370`, `:1500`, `:1551` and `:1886` quote the field inside a header or a
`notes:` body, and **only a line-initial occurrence is a stanza field**. **Cite
the anchored form.** `wc -l` is not a row count and `grep -c '^PREFIX'` is.

Gate-on-advise derives from splitting those same 22 by `runtime_authority`:

```
awk -F': ' '/^runtime_authority: /{ra=$2} /^authority_mismatch: declared/{n[ra]++} END{for(k in n) print k, n[k]}'
  → gate 14, execute 8
```

Identical at base `9c740d7` and at HEAD.

**Census and scans, all re-derived at this close:**

- `scan-controls.sh check` — **exit 0**. **105** registered controls
  (`grep -c '^control: '` → 105), **46** refusal-capable surfaces, **88**
  `load_bearing`, **22** over-authorised (declared), **0** unregistered, **0**
  phantom, **22** report rows reconciled, **0** advisory findings.
- `scan-controls.sh anchors` — **exit 0**, **12 resolved / 1 superseded / 0
  violations** over 13 records in 12 declared object types.
- **ZERO RE-AUTHORISATIONS AND NO NEW CONTROL.** The one registry edit in this
  packet is a **1-insertion / 1-deletion** change in `b41aa5d` — an
  `evidence_refs` repoint on an **existing** control. No authority, class or gate
  field moved, so census 105 / declared 22 / gate-on-advise 14 **cannot** have
  moved. The blob is `ff1de420` at HEAD.

---

## qa PROOF

- **Suite at `b41aa5d`: 2140 passed / 0 failed, TWICE**, chained verdict vectors
  identical.
- **Fix round re-ran it 2140 passed / 0 failed, TWICE, SOLO and FOREGROUND**,
  chained vectors `cmp`-identical across both runs.
- **The total did not move across the fix round** — and that is the point: the
  diff is **prose only**, with **no assertion added, removed or re-fixtured**. A
  moving total would have meant the "record correction" changed behaviour.
- **Re-derived by the archivist at this close, one solo full-capture run at
  `d885657`, redirected to a file and never piped through `tail`:**
  **`==== RESULT: 2140 passed, 0 failed ====`**, **exit 0**,
  `grep -c '^  FAIL'` → **0**, and **no `CHAINED: N passed, 1 failed` line** —
  all 20 chained suites report `, 0 failed`.
- **Commit-1 green in isolation — DERIVED AT THIS CLOSE, because the closing
  brief did not carry it.** A clean clone checked out at `06e9f1c`,
  `git status --porcelain` empty, suite run solo and foreground:
  **`==== RESULT: 2121 passed, 0 failed ====`**, exit 0,
  `grep -c '^  FAIL'` → **0**. **Commit 1 stands on its own.**
- **The +19 is fully attributed and arithmetically forced.** 2140 − 2121 = 19,
  and `tests/build_os_maintenance_tests.sh` goes **85 → 104** chained across the
  same pair (**+19**). **Every other chained suite is +0.**
- **Live-suite gate MATCHES at 2140.** `RELEASE_METADATA_LIVE_SUITE=1` was set
  for the close run: `CHANGELOG.md` carries the literal `**2140 passed**`
  **exactly once and unsplit** (`grep -c` → 1), and
  `build-os/memory/current_state.md`'s `**Build/test command:**` line claims
  **2140 checks**. All three agree.

**Safety grep / do-not-touch set — blob hashes re-derived at close, all
byte-identical to their state before this close:**

| path | blob | status |
|---|---|---|
| `build-os/metrics/rank-candidates.sh` | `5543ea88` | untouched — guard 1's own protected surface |
| `build-os/metrics/signal_snapshots.tsv` | `7496ead8` | untouched — live S1 experiment |
| `build-os/metrics/decision_telemetry.tsv` | `fd52eb15` | untouched — live S1 experiment |
| `build-os/memory/residue.md` | `cb18fb9d` | **declared byte-identical boundary of the packet, and it held** |

**The six ranker fields remain refused via `RANKER-FIELD-VIA-SNAPSHOT`. No other
door was tried.**

**UI smoke: NOT APPLICABLE and stated rather than omitted.** This packet has no
frontend surface — the six paths it touched are two memory/packet records, two
registry stores, one test suite and the changelog. There is nothing to smoke, and
recording "n/a" is not the same as recording nothing.

**Rotation was NOT applied.** `build-os/memory/archive/` **does not exist**
(`ls` exits 2). `DEFAULT_MAX_BYTES` is still `200 * 1024` — **no ceiling was
raised.** Every rotation figure in this receipt comes from a `--dry-run`.

---

## RESIDUE — WHAT LEAVES THIS PACKET OPEN

1. **A STALE LINE-PINNED POINTER, QUEUED AND DELIBERATELY NOT REPAIRED — AND IT
   PREDATES THIS PACKET.** `build-os/memory/residue.md:582` carries the pointer
   `build-os/memory/current_state.md:286`. It was valid at `2a3c070`, was
   **already stale at `95e2c7b`** — which is *before* this packet's base
   `9c740d7` — so **this packet did not cause it**; the migration carried the
   content further. **The claim itself is conserved:** the anchor
   `counterexample is unreachable` occurs **exactly once** at base and **exactly
   once** at HEAD (`grep -c` → 1 both sides), and the containing block is
   byte-identical at a **constant offset of +275**, so the derived current
   location is `build-os/memory/current_state.md:286 -> :561` — an **arrow-pair,
   two commits, never to be repointed**.
   **A CORRECTION TO AN EARLIER HAND-BACK, RECORDED RATHER THAN QUIETLY
   DROPPED:** an earlier statement of this item said `:523`. **The derived value
   is `:561`**, confirmed at this close by reading `:561` and finding the cited
   sentence there. `residue.md` was a declared byte-identical boundary for this
   packet (blob `cb18fb9d`, unchanged), so the pointer is **queued with its
   measurement and NOT repointed here** — the next packet repoints it **by
   content**, not by shifting a digit. *This close obeyed that boundary for the
   pointer and appended new items only; the pointer line was not touched.*
2. **§8/§9 DUPLICATION DEBT — AN OPEN CHOICE, NOT A DEFECT.** In
   `tests/build_os_maintenance_tests.sh`, §8 spans `:430-637` (**208 lines**) and
   §9 spans `:638-847` (**210 lines**) — structural clones, same shape, literals
   swapped, hand-maintained. The cost is **O(files)**. **`build-os/packets/active_packet.md`
   is the third rotating file and has no such section at all** — `grep -c '^## '`
   returned **20** blocks at the packet's HEAD, so it is currently fine and
   **nothing checks that it stays fine**. The follow-up is a choice: either
   parameterise one helper by *(file, standing-heading prefix, pinned literals)*,
   or accept the duplication deliberately and add coverage for the third file.
   **Not built here.**
3. **`CHANGELOG.md` STRUCTURAL DECAY — MEASURED, AND NOTHING NEWLY BROKEN.** The
   file grew **1,627 → 1,731 lines** across the fix round (`wc -l`), and
   **1,567 → 1,731 across the whole packet**, which moves every line below the
   insertions. **No citation was newly invalidated, and that is measured rather
   than assumed:** all nine line-pinned citations into it **already named other
   content at `b41aa5d`**, before the fix round existed. This is exactly the decay
   `residue.md` item **(r)** already registers — *"this will happen to EVERY
   `CHANGELOG.md` line-citation on EVERY future packet, because the changelog
   grows from the top."* The live cross-file guard on this file is
   **content-addressed, not positional**, so it is unaffected.
4. **STILL OPEN AND UNTOUCHED BY BOUNDARY:** `(ddd)` queued, `(uuuu)`,
   `(ppppp)`, and `(bbbbbb)` — **the un-run rotation**, which remains an
   **operator decision**, not a builder decision.
5. **SECOND EYES ABSENT FOR SEVENTEEN CONSECUTIVE PACKETS**, and
   `build-os/memory/tool_router.md:368` **still says "nine"**. Both figures are
   carried forward: the streak *and* the router's stale self-report of the
   streak. The reviewer has now flagged this at three consecutive closes. It is
   **not** fixed here — fixing open residue items is out of this packet's scope
   and out of this close's — and the router that routes is the file carrying the
   stale number.

---

## DEVIATIONS — STATED PLAINLY, NOT RATIONALISED

- **3 COMMITS AGAINST THE `<=2` CAP.** `bandwidth-check.sh check` reports it in
  its own words: `commits EXCEEDED — 3 commits since the declared base 9c740d7,
  ceiling 2 (advisory: advise — reported, not refused)`. **This is the same
  recorded deviation shape as the last three closes — the fifth consecutive
  breach.** No commit was squashed, amended or rewritten to hide it; amending is
  out of bounds at close. **A cap breached five times running is either a cap
  nobody intends to hold or a packet-cutting problem**, and it is logged as
  residue rather than quietly accepted. It is *not* normalised by repetition.
- **NO ROTATION APPLIED.** `build-os/memory/archive/` still does not exist. Both
  memory files remain in the state where relief is one operator command away and
  the command has not been given.
- **NO CEILING RAISED.** `DEFAULT_MAX_BYTES` is unchanged at `200 * 1024`.

---

## WHAT THE REVIEWER FOUND THAT IS **NOT** RECORDED AS A FINDING

One reviewer-surfaced claim is deliberately **excluded** from this receipt, and
the exclusion is itself the record: a proposed third ground for refusing option
**(B)** was **FALSE**, and it **never entered the tree** — 0 hits in the packet's
diff. `build-os/packets/active_packet.md:54` correctly records the (B) refusal as
a **scope boundary** (*"moving standing content into `standing_gates.md`"* sits
under **Out of scope**), **not** as an impossibility claim. Writing a false
ground into a receipt would be a durable error in the one artefact that is
append-only. **No such ground is added here or anywhere.**

---

## FILE-OWNERSHIP MANIFEST — ATTRIBUTION BY PATH ACROSS 3 COMMITS

The packet landed **3 commits against the `<=2` cap**, so attribution cannot rest
on "one commit, one packet". The manifest is what keeps it recoverable by path.
All **6** distinct paths, derived with
`git show --numstat --format='' 06e9f1c b41aa5d d885657`:

| path | owner | commits | +/− |
|---|---|---|---|
| `build-os/packets/active_packet.md` | builder | `06e9f1c` | +44 / −44 |
| `build-os/memory/current_state.md` | builder | `b41aa5d` | +287 / −205 |
| `tests/build_os_maintenance_tests.sh` | builder | `b41aa5d` | +212 / −5 |
| `build-os/registry/control_registry.txt` | builder | `b41aa5d` | +1 / −1 |
| `build-os/registry/defect_classes.txt` | builder | `b41aa5d`, `d885657` | +14 / −2 |
| `CHANGELOG.md` | builder | `b41aa5d`, `d885657` | +169 / −5 |

**Ownership is disjoint and single-writer: one builder held every path.** There
was no fan-out, so no two agents could contend for a file; the merger question
does not arise. The manifest is recorded because the **commit count exceeded the
cap**, not because ownership was shared — and because **a missing manifest broke
an earlier close (P2)**, which is why it is mandatory here.

**Diff figures, both conventions, because they differ:**

| convention | files | insertions | deletions |
|---|---|---|---|
| **verifier** (`record-packet.sh --verify-git`, per-commit sums) | 6 | **727** | **262** |
| net union diff (`git diff 9c740d7 d885657`) | 6 | 721 | 256 |

`record-packet.sh --verify-git` computes **PER-COMMIT SUMS** via `git show
--numstat` over the named commits, **not** the net union diff — a net-diff row was
refused at an earlier close, so the recorded row uses the verifier's definition
and this note states both. **The 6/6 gap is fully accounted:** `d885657` removed
**6** lines that `b41aa5d` had added (`CHANGELOG.md` −5,
`build-os/registry/defect_classes.txt` −1), so the net diff counts each once
while the per-commit sum counts both the add and the delete.

---

## THE STAGE-4 HAZARD THIS CLOSE INHERITED, AND HOW IT WAS AVOIDED

`ANC-0003` resolves to `build-os/packets/active_packet.md:89`, and the committed
kernel projection `build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md`
embeds that **resolved line number**, which `tests/memory_kernel_tests.sh` §18
compares with `cmp -s`. **Any close that adds a line above `:89` turns the suite
red with `PROJECTION-DIVERGED`** — this is `DEFECT-0001-stale-line-reference`
arriving through the mechanism built to demote line numbers, and it has been paid
at each of the last two declarations.

**Strategy, identical to the last close: strictly line-count-neutral above the
anchor.** The status heading and the `**Packet id:**` marker were each replaced
**one line for one line**, and **all** new material was appended **below** the
anchor site. **`ANC-0003` re-verified at `:89` after the edit**, and
`scan-controls.sh anchors` re-run to **12 resolved / 1 superseded / 0
violations**. **No projection regeneration was required, because nothing moved.**
**Third consecutive close to pay attention to this tax; first to pay it at zero
cost twice running.**

---

## OPEN BOUNDARIES — NOTHING EXTERNAL HAPPENED

- **No push, no merge, no PR, no tag, no deploy, no secrets, no `git config`.**
- **No commit amended, squashed, rebased or rewritten.**
- **Rotation NOT applied; no ceiling raised.**
- The three packet commits remain **local and unpushed**, together with this
  close's bookkeeping commit. Any external action **awaits an explicit go**.
- **The live S1 experiment was not written to**: `decision_telemetry.tsv` and
  `signal_snapshots.tsv` are byte-identical, and `rank-candidates.sh` was not
  touched.

---

## WHAT THIS CLOSE ITSELF SPENT, MEASURED — BECAUSE THE FILES MEASURE THEMSELVES

The two memory files this packet is *about* are the two files this close had to
*write to*, so the close's own writes change the packet's own numbers. Residue
`(cccccc)` is the standing discipline for exactly this: **derive, never quote.**
Everything above is at the packet's HEAD `d885657`; this section is the close.

| file | at `d885657` | after this close | derivation |
|---|---|---|---|
| `build-os/memory/current_state.md` | 18 blocks / 188,188 B | **19 blocks / 193,625 B** | `grep -c '^## '`, `wc -c` |
| `build-os/memory/residue.md` | 29 blocks / 213,824 B | **29 blocks / 218,062 B** | same |
| `build-os/packets/active_packet.md` | 20 blocks / 742 lines | **21 blocks** | same |

Post-`keep=10` dry runs after the close, both **exit 0**: `current_state` retains
**119,429 B** (archives 9 blocks / 74,707 B), `residue` retains **91,426 B**
(archives 19 blocks / 127,142 B). Both are far under the 204,800 B ceiling, and
**no file in `build-os/memory/` is at or above the 256 KB `PILOT:CHECK id=R7`
Read limit** — `find … -size +262143c` returns nothing.

**The three new residue items are `(eeeeee)`, `(ffffff)` and `(gggggg)`**, added
inside block 1 (the protected region), so the block count did not move and
nothing was pushed into the archivable tail.

### The close was verified, not assumed

- **Suite re-run once more AFTER every write in this close**, solo and
  foreground, captured to a file and never piped through `tail`:
  **`==== RESULT: 2140 passed, 0 failed ====`**, **exit 0**,
  `grep -c '^  FAIL'` → **0**, no `CHAINED: N passed, 1 failed`.
- **The 20-line chained verdict vector is BYTE-IDENTICAL to the pre-close run at
  `d885657`** — both `sha256 a69575133a461220…`. **This close changed no
  assertion outcome anywhere in the tree.**
- `scan-controls.sh check` **exit 0** — 105 / 46 / 88 / 22 / 0 / 0 unchanged.
  `scan-controls.sh anchors` **exit 0** — 12 resolved / 1 superseded / **0
  violations**; `ANC-0003` still resolves at `build-os/packets/active_packet.md:89`
  and `ANC-0009` still resolves at `build-os/metrics/packet_metrics.tsv:17`.
- `bandwidth-check.sh check` now reports **`packets OK — 0 packet(s) in flight,
  ceiling 1`**: the declaration marker was renamed, so the file tells the truth
  about what is in flight again.
- **The metrics row is git-VERIFIED, not merely written:**
  `record-packet.sh --validate` → **21 rows, 0 invalid**;
  `record-packet.sh --verify-git` → `VERIFIED gravito_current_state_reblock_a
  06e9f1c,b41aa5d,d885657 files=6 insertions=727 deletions=262`, and
  **`verify-git: 20 ok, 0 mismatched, 0 unverifiable`**.

### A hazard this close caught in itself, recorded rather than quietly fixed

The first draft of the new history block **quoted both gate-pinned literals
verbatim** — inside a history block, which is **outside the protected region**.
`tests/build_os_maintenance_tests.sh` §9 refuses exactly that: a pinned literal
occurring outside block 1 means **an archivable block could be what keeps
`tests/release_metadata_tests.sh` §5 green**, and both are read with `head -n1`.
Caught before the suite ran, by re-deriving the invariant rather than trusting
the edit; the history entry now names the two markers **descriptively** and says
why. **Verified after the fix:** each literal occurs **once**, both inside block
1, **zero** occurrences outside.

> **The packet proved the standing region cannot be reached by rotation. The
> close nearly reached into it by hand — which is the failure mode positional
> protection does not cover, and is why §9 checks the literals and not just the
> heading.**
