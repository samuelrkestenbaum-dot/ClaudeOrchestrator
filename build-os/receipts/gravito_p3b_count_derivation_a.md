# Receipt — `gravito_p3b_count_derivation_a`

- **Packet id:** `PACKET-0041-count-derivation`
- **Title:** Derived counts — a stated count is bound to a live derivation, and
  the record stores neither the number nor the position
- **Closed:** 2026-08-04
- **Lane:** `substantive`. **Depth 4** — builder, then qa ‖ reviewer
  concurrently, then one fix round, then a re-gate. **The fourth serial stage is
  a contract gap, not an installment and not a mis-cut packet — see §7.2.**
- **Verdict:** **PASS-AS-FIXED.** qa **GREEN**, reviewer **fix-then-pass (6
  enumerated items)**, re-gated after the fix.
- **Base:** `099d7bf`, verified by `git merge-base` before the first edit.
  **HEAD at the verdict:** `f785056`.
- **Commits:** `a714d8a`, `f0e2fba`, `f785056` — **three**, against a cap of two.
  **Sixth consecutive close at three. See §7.1 — it is now structural, and it is
  routed to the operator rather than logged a seventh time.**
- **Second eyes: NONE.** `codex` is not on `PATH`; review was same-model,
  single-provider. **TWENTIETH consecutive packet in that state.**

---

## 1. THE HEADLINE — S1's rank-1 candidate shipped

**`scan-controls.sh counts` binds a stated count to a live derivation.** The
record stores **no number** and **no line number**: the stated value is read out
of live prose at every run, the derived value is computed from the live source at
every run, and the position is a navigation hint computed on the spot.

It caught the real defect on the live tree, not on a fixture:

```
$ bash build-os/registry/scan-controls.sh counts
  COUNT-STALE  DC-0001 — build-os/memory/tool_router.md:368 states "nine" (= 9);
  deriving it from build-os/receipts with "gravito_*.md" gives 19.
exit 2
```

The correction was made **by that derivation**, and the count table was
**byte-identical across the fix** — the record holds no number, so correcting the
prose did not create a second place to be wrong.

**THE CATEGORY CHANGE THAT MATTERS.** The packet's own claim moved from
**declared in a header** to **asserted over the live table and red-driven in both
directions**. qa's `M-NEW` mutant — restore `DC-0003`'s `14` — produces **2
failed**, so the assertion bites rather than describing itself.

**The reviewer's trajectory sentence, in the reviewer's words and not softened:**

> *"still a scheme with a token population, but the scheme is now self-asserting
> rather than self-declaring."*

**Three records over two distinct counts.** It becomes infrastructure when the
population grows past the counts its own author happened to notice, and not
before.

**Ceiling held exactly: 0 / 0 / 0 / 0 / 0.** 0 new tools (extended
`scan-controls.sh`) · 0 new stores (embedded table, same shape and same reason as
`ANCHOR_TABLE` and `EVIDENCE_VACUITY_ALLOW`) · 0 new suite files (§29 of the
existing `tests/control_registry_tests.sh`) · 0 new governance primitives · 0 new
census controls.

**Every governance count DERIVED at this close, not remembered:**

| figure | derivation | base `099d7bf` | HEAD |
|---|---|---|---|
| census | `grep -c '^control: ' control_registry.txt` | **105** | **105** |
| declared mismatches | `grep -c '^authority_mismatch: declared'` (**anchored**) | **22** | **22** |
| the same grep **unanchored** | `grep -c 'authority_mismatch: declared'` | 27 | **27 — and it is WRONG**, which is exactly what `DC-0002` exists to prevent |
| runtime authority | `gate` 81 / `execute` 8 / `advise` 15 / `observe` 1 | identical | identical |
| re-authorisations | `(control, runtime_authority)` pairs diffed base→HEAD | — | **0**, diff empty |
| anchors | `scan-controls.sh anchors` | — | **12 resolved / 1 superseded / 0 violations** |
| derived counts | `scan-controls.sh counts` | — | **3 of 3 agree, 0 violations** |

---

## 2. Scope

**In:**

- The `COUNT-TABLE` inside `build-os/registry/scan-controls.sh` and the `counts`
  subcommand; the counts reconciliation also **gates the `check` path**.
- Two derivation kinds only — `lines` (an ERE that **must** begin `^`) and
  `files` (a name glob). **No line-count kind** (instance 2 made inexpressible)
  and **no shell-command field** (no `eval` surface).
- Three live records: `DC-0001` (the second-eyes streak), `DC-0002` and
  `DC-0003` (the two restatements of the declared-mismatch count).
- §29 of `tests/control_registry_tests.sh` — the live binding, nine red drives,
  four executed counterfactuals, and the live-table invariant.
- Registry bookkeeping: three `evidence_refs` repointed **by content**.

**Explicitly out:**

- A `mirror` kind (site A must equal site B, no derivation). **Deliberately not
  built** — no executed fixture in instances 1–3 justifies the kind. §6(a).
- A census entry for the counts block itself — registering it moves the census
  off the 105 this packet was told to hold. Operator's call. §6(b).
- Any write to `build-os/memory/residue.md` (frozen, §5).
- Any push, merge, PR, tag, deploy, secret or `git config`.

---

## 3. Commits, and the file-ownership manifest

**The row names three commits, so the manifest is mandatory. Attribution by
path, including the honest statement of where disjointness does not hold.**

| commit | subject | files | +ins | −del |
|---|---|---|---|---|
| `a714d8a` | `feat(registry): derive stated counts from their source — scan-controls.sh counts` | 6 | 605 | 20 |
| `f0e2fba` | `docs(packet): declare PACKET-0041-count-derivation, with its residue held OUT of a frozen file` | 1 | 115 | 0 |
| `f785056` | `fix round: close instance six inside the fix itself, and assert the claim where it is made` | 6 | 247 | 26 |

**Per-commit sums (the verifier's convention, `git show --numstat` summed over
the named commits): 13 path-visits, 967 insertions, 46 deletions, over 7 distinct
paths.** The net union diff `git diff --numstat 099d7bf f785056` reports **7
files / 941 / 20** — the two conventions **agree on the file count and disagree
on the line counts** by exactly **26**, because five paths were touched by more
than one commit and the union diff nets the overlap away. The row records the
per-commit sums, which is what `record-packet.sh --verify-git` recomputes.

### File-ownership manifest — attribution by path

**Sole ownership (1 of 7 paths):**

| path | owned solely by |
|---|---|
| `build-os/memory/tool_router.md` | `a714d8a` |

**Shared paths, named rather than hidden (6 of 7):**

| path | commits | why more than one |
|---|---|---|
| `CHANGELOG.md` | `a714d8a`, `f785056` | the fix round restates the entry it corrected |
| `build-os/memory/current_state.md` | `a714d8a`, `f785056` | the standing obligation was moved here by fix item 2 |
| `build-os/registry/control_registry.txt` | `a714d8a`, `f785056` | `evidence_refs` repointed in both rounds |
| `build-os/registry/scan-controls.sh` | `a714d8a`, `f785056` | the guard, then the fix to the guard |
| `tests/control_registry_tests.sh` | `a714d8a`, `f785056` | §29 built, then extended: 130 → 168 |
| `build-os/packets/active_packet.md` | `f0e2fba`, `f785056` | the declaration, then the fix-round log |

**`f0e2fba` owns NO path solely** — its one file is shared with the fix round —
and **`f785056` owns no path solely either.** That is the definitional shape of a
declaration commit and a fix commit: neither can fix or declare anything by
touching only new paths. **Attribution stays recoverable by the (path, commit)
pair above**, which is what the manifest is for.

**`build-os/memory/residue.md` appears in NO commit of this packet.**
`git log --oneline 099d7bf..f785056 -- build-os/memory/residue.md` returns
**zero** commits. See §5.

### 3.1 `defects_escaped` is `-`, AND THE ARCHIVIST GOT THIS WRONG FIRST

The row was first written with **`--defects-escaped 2`**, counting §6.1 and §6.2
as escapes because they passed qa **and** the reviewer.

**The suite refused it, and the suite was right.**
`tests/speed_benchmark_tests.sh:319` asserts, against the **live** store, that the
rendered `defects_escaped` total is `-` *"because no post-close defect audit has
ever run here"*. The full run went **2227 / 1** on exactly that assertion.

**The column means a POST-CLOSE AUDIT found the defect** —
`build-os/metrics/README.md` says so in terms: *"no post-close defect audit has
ever been run here, so the honest value is 'unaudited', not 'none escaped'."*
**A close-stage catch is not a post-close escape.** Writing `2` there would have
both misused the column and published a measurement for an audit nobody ran —
the exact `0`-versus-`-` confusion the store exists to prevent, committed by the
agent whose job is to prevent it.

**How it was corrected, stated plainly rather than quietly:** the row had been
appended to the working tree and **was never committed**. It was removed from the
uncommitted working copy — verified by `git status --porcelain` reporting the
store byte-identical to `HEAD` again — and re-recorded without the flag. **No
committed row was rewritten, and the append-only property of the store is
intact.** Had the row been committed, the rule stands: a correction would have
been a new row referencing the old one, never an edit.

**Both findings are recorded in prose at §6.1 and §6.2 instead**, where they cost
nothing and claim nothing.

---

## 4. QA proof

**qa verdict: GREEN.**

| measurement | result |
|---|---|
| suite at base `099d7bf` | **2190 passed / 0 failed** |
| suite at `f0e2fba`, run twice solo | **2220 / 0**, both runs, chained vectors **identical** |
| suite after the fix round (`f785056`), solo | **2228 / 0** |
| packet delta | **+38**, attributed **entirely** to `tests/control_registry_tests.sh` (**130 → 168**); **every other chained suite +0**, confirmed by comparing the per-suite CHAINED **vector**, not the total alone (`DEFECT-0013`) |
| **Commit-1 isolation** — `a714d8a` alone | **GREEN** |
| `scan-controls.sh check` | exit **0** |
| `scan-controls.sh anchors` | **12 resolved / 1 superseded / 0 violations** |
| `scan-controls.sh counts` | **3 of 3 agree, 0 violations** |
| safety grep | clean |
| mutation | **10 mutants, ZERO zero-kill after disposition**; `M-NEW` (restore `DC-0003`'s `14`) → **2 failed** |

**Final solo full-capture run at close** (after this receipt, the memory updates,
the occurrence record and the metrics row were written): recorded in §10.

### 4.1 The counterfactual was RUN, not asserted

At `099d7bf`, with the stale `"nine"` standing in the tree: the full suite was
**2190 / 0**, `scan-controls.sh check` exit **0**, `scan-controls.sh anchors`
exit **0**, and **no instrument in the repository read that count at all.** §25 —
the nearest prior art — is bespoke to `evidence_refs` and finds **0** totals in
the same document. That is executed in §29a, not argued.

### 4.2 One zero-kill mutant, disposed of as UNOBSERVABLE BY CONSTRUCTION

Adding `local pair` killed **zero** tests. **That is the correct disposition and
the reasoning is recorded rather than the verdict alone:** `pair` is **read only
inside the loop that assigns it**, and **both call sites are top-level**, so
there is no reachable state in which the variable's scope is observable. It is
not an untested guard — it is a guard with no observable behaviour to test. This
is deliberately distinguished from `PACKET-0040`'s two zero-kill mutants, which
**were** observable and **were** unenforced; conflating the two categories is how
a mutation score becomes decoration.

---

## 5. `residue.md` IS FROZEN — and the residue placement is DISPLACEMENT

**Headroom: 431 B** against the 204,800 B ceiling (`204800 − 204369`). Blob at
close: **`01517ad2c30d447949a98d0b6db9b8d6b538d5a9`**, byte-identical to its blob
at base `099d7bf` and at `188472f`. **Nothing in this packet, including this
close, wrote to it.** It is provably unrotatable at every legal `--keep` — all 25
of 25 blocks exit 7 under the sentinel.

**Consequence, stated as displacement and not as a choice:** every residue item
this packet produced is recorded in `build-os/memory/current_state.md` and
`build-os/packets/active_packet.md` **instead**. The residue file did not receive
them, and the reason is not neglect — it is that the file cannot accept a byte.
**Unfreezing it is an operator act, not a builder's and not an archivist's.**

---

## 6. THE HONEST PARTS

### 6.0 Coverage — 3 of 5 known instances, stated as EXECUTED or NOT TESTED

| # | instance | status |
|---|---|---|
| 1 | the router's stale second-eyes streak | **CAUGHT LIVE**, on the real tree, re-driven in §29a |
| 2 | `wc -l` standing in for a record count | **CAUGHT structurally and on a FIXTURE** (§29c, 7 lines stated over 3 records). The `wc -l` answer is not discouraged, it is **inexpressible** — there is no line-count kind |
| 3 | unanchored vs anchored grep | **CAUGHT structurally and on a FIXTURE** (§29b, 5 vs 3, the same shape as the live 27 vs 22); the unanchored form is refused **at declaration time** by the schema |
| 4 | the suite total in `CHANGELOG.md` + `current_state.md` | **NOT CAUGHT, NOT TESTED** |
| 5 | the `213,824 B` and `residue_items_closed=1` slips | **NOT CAUGHT, NOT TESTED** — transient prose no record binds |

**AND INSTANCE 4 WAS PERFORMED BY HAND INSIDE THE PACKET THAT EXISTS AGAINST
IT.** Fix item 3 added assertions, which moved the total **2190 → 2220 → 2228**,
which required restating that number **by hand, in two files** —
`CHANGELOG.md` and `build-os/memory/current_state.md`. **Fixing the guard
required committing the defect the guard is about.** No static derivation reaches
instance 4: the number is produced by *running* the suite, and the count table
derives from files, never from processes. It stays covered only by
`RELEASE_METADATA_LIVE_SUITE=1`. Recorded at `current_state.md:95-99` by the
builder and carried here deliberately, because it is the honest measure of what
this packet did and did not achieve.

### 6.1 INSTANCE SEVEN — word-cardinals persisted in `note` fields

**`DC-0001`'s note carries `"nine"` and `nineteen`.** The tool's own `cnt_num`
parses lowercase English cardinals **to twenty** as numbers — so those words are
numbers by the module's own definition, sitting in a record whose header says the
record stores no number.

**The §29d predicate cannot see them, and the reason is specified, not
accidental: its predicate is DIGIT-ONLY.** It strips the `{N}` placeholder,
stable-id tokens and ISO dates, then flags a surviving `[0-9]`. A spelled-out
cardinal survives every one of those strips and carries no digit.

**ATTRIBUTION, RECORDED AS THE REVIEWER ATTRIBUTED IT:** this is **the reviewer's
own round-1 list specifying a digit predicate**, not the builder omitting work.
The builder implemented the predicate that was asked for, and implemented it
broader than asked (extending it from `stated_content` to `note`). The gap is in
the specification.

**Not fixed here.** Narrowing it is a real design question — the note field is
prose, and prose legitimately contains cardinals — and the archivist does not get
to answer design questions inside a close. Routed, §7.3.

### 6.2 A SIBLING OF INSTANCE SEVEN, FIXED IN THIS CLOSE COMMIT

`DC-0003`'s note read *"…the SECOND restatement of `DC-0002`'s truth, **four
lines above it** in the same file."*

**The distance was hand-written, underived, and FALSE.** The two sites are
`build-os/registry/MISMATCHES.md:30` and `:32` — **two** lines apart — and traced
back six revisions **they have never been four**. A record in the count table was
storing a wrong stored position, **thirty lines under the sentence declaring
that "an anchor stores no line number, and a count record stores no count."**

**THE DISTANCE IS DROPPED, NOT CORRECTED TO "TWO".** A corrected distance is
still a stored position, and `"two"` would persist another English cardinal —
which is precisely the residual class §6.1 is about. Nothing derives it, so
nothing states it. Behaviour-neutral and count-neutral: `counts` exits 0 and the
live-table digit predicate still reports **0** offending fields. The reasoning is
written into the `COUNT-BLOCK` header comment, where this module's history is
supposed to live — **in a comment, and not in a record.**

**This escaped qa and the reviewer and reached the archivist.** It is named here
and in §6.1 rather than smoothed into the fix list — but see §3.1: the row's
`defects_escaped` cell is deliberately `-`, because that column means a
**post-close audit** found it, and a close-stage catch is not that.

### 6.3 THE §21 TEXTUAL-ENROLMENT HAZARD — recorded in a memory file for the first time

`tests/control_registry_tests.sh:477-478` greps `-ge N|-gt N` **across
`tests/*.sh` as TEXT, including comment text.** So a comment written to explain
*why* a numeric floor was deliberately avoided **enrolled the comment itself**
into the `tests.nonvacuity_minimums` family and turned the check red. It did so
on the first attempt, which is why the rejected form is now described in words
rather than quoted.

**Before this close, that hazard existed ONLY as a local comment at
`tests/control_registry_tests.sh:1470-1476` and in NO memory file.** A trap that
every future packet touching a suite file will hit, documented only at the site
that already hit it, is a trap documented for the one person who does not need
it. It is now in `build-os/memory/current_state.md`.

### 6.4 THE STANDING OBLIGATION SITS IN A ROTATING FILE — and that is the orchestrator's constraint

Fix item 2 moved the permanent `DC-0001` close obligation into
`build-os/memory/current_state.md`. **`current_state.md` is in
`rotate-memory.mjs`'s `FILE_SPECS`** — it rotates, and it has already been
rotated twice.

`build-os/memory/standing_gates.md:1` calls itself the never-rotated home of hard
stops and states, in its own words, that **a gate written into a rotating file
and not copied there is a gate with an expiry date.** That rule is **enforced
only for lines carrying the literal `HARD STOP`**, and `current_state.md`
contains **zero** of those. So the obligation is unprotected by the very
mechanism that names the risk.

**ATTRIBUTION, AND IT IS NOT A BUILDER DEFECT: the orchestrator's brief pinned
`standing_gates.md` FROZEN.** The builder had **no legal path to the correct
file**. It put the obligation in the best file it was permitted to write and said
so. **Recorded as the orchestrator's constraint.** The remedy — copy the
obligation into `standing_gates.md` under a `HARD STOP` line — is an operator
act, §7.3.

**Mitigation actually in force:** the obligation sits in **block 1** of
`current_state.md`, the protected region, and `--keep` is validated `>= 1`, so no
legal rotation can reach it. That is *position*, not *policy*, and it is a weaker
guarantee than the one `standing_gates.md` offers.

### 6.5 `DEFECT-0011-undeclared-active-packet` recurred, and the ledger was undercounting it by three

**`f0e2fba` (the declaration) landed at `22:36:46`, SEVEN MINUTES AFTER
`a714d8a` (the implementation) at `22:29:38`.** The packet was built before it
was declared. `bandwidth.active_packet_singleton` passed throughout, because it
refuses two declarations and permits zero — which is the class exactly.

**AND THE LEDGER ITSELF WAS A STALE STORED COUNT, IN THE PACKET WHOSE THESIS
THAT IS.** `build-os/registry/defect_classes.txt` carried **exactly one**
occurrence of this class — `OCCURRENCE-0005` — while
`build-os/packets/active_packet.md` documents further recurrences at `:758`,
`:847` and `:1202`. **A defect ledger undercounting its own recurrences by
three.**

**`OCCURRENCE-0019` is appended by this close**, and it records the four-deep
recurrence rather than only this packet's instance. The ledger now reports **19
occurrences** where it reported 18.

### 6.6 Six line-pinned citations repointed BY CONTENT — while `ANC-0012` cost nothing

**Three citation sites, repointed twice each across two rounds — six repoint
operations, every one done by grepping the cited content, none by guessing an
offset:**

| site | round 1 | round 2 |
|---|---|---|
| `tests/control_registry_tests.sh:1189` | → `:1444` | → `:1526` |
| `tests/control_registry_tests.sh:1193` | → `:1448` | → `:1530` |
| `tests/control_registry_tests.sh:1194` | → `:1449` | → `:1531` |

**`ANC-0012` covers the SAME FILE and absorbed every one of those moves with ZERO
edits.** That is the anchor argument made by execution rather than by assertion,
inside a packet about the cost of storing positions.

**All still resolve at close, verified by execution:** `ANC-0012` →
`tests/control_registry_tests.sh:1526` **RESOLVED**; `ANC-0009` →
`build-os/metrics/packet_metrics.tsv:17` **RESOLVED**; the `evidence_refs` entry
at `tests/control_registry_tests.sh:1526` resolves under
`scan-controls.sh check` (exit 0, 0 vacuous refs).

### 6.7 Two defects found by the packet's own tests, not by review

An id regex too tight for fixture ids, and **`rc=$?` read back after `if ! cmd`**
— which reports the status of the *negation* and mislabelled a `COUNT-UNANCHORED`
finding as `COUNT-SOURCE`. **The second is the exact trap the brief warns
about, made in the same packet that quotes the warning.** Both were caught
pre-commit and neither shipped.

---

## 7. ROUTED TO THE OPERATOR — recorded, deliberately NOT decided here

### 7.1 THE ≤2-COMMIT CAP IS NOW STRUCTURALLY UNSATISFIABLE — decide it, do not log it again

This is the **SIXTH CONSECUTIVE CLOSE AT THREE COMMITS.**

**The reviewer's generalisation, which is what turns this from an incident into a
rule conflict:** *any* packet receiving a `fix-then-pass` verdict **must** produce
a third commit, because the two earlier commits are the gated tree both gates
measured and amending or squashing them destroys the artefact the verdict was
about. **So `≤2 commits` and a fix-round mechanic cannot both be satisfied.**

**Recording it a sixth time is ritual replacing a rule.** The decision is the
operator's or the orchestrator's, and it is one of two:

1. **Re-cut the cap** — e.g. *"≤2 build commits plus at most one fix commit"* —
   which makes the contract satisfiable and keeps the constraint meaningful; or
2. **Stop logging it**, and delete the cap.

**The archivist does not decide this and has not.** It is recorded once more here
only because a receipt that omitted it would be the seventh silent breach.

### 7.2 DEPTH 4 WAS RULED DELIBERATELY — and it exposes a gap in the contract

The working contract enumerates **two** causes for a fourth serial stage: the fix
list arrived **in installments**, or the packet was **mis-cut**. **THIS WAS
NEITHER.**

- The reviewer's list **arrived complete** — six items, in one message, in one
  round. No installments.
- The fixes were **logic and count changes** — a schema change to a record, a
  new bidirectional assertion, a fallthrough closed, a suite-total restatement —
  and the contract's **own re-review rules forbid closing those by targeted
  confirmation.** A re-review that only re-checks the enumerated items cannot
  certify a change that moves the suite total.

**That is a THIRD cause the contract does not anticipate: a complete fix list
whose contents are of a kind the re-review rules will not let you close
narrowly.** Recorded as a **contract gap**, not as a defect of this packet and
not as a defect of the reviewer.

### 7.3 The unbuilt items

| # | item | why it is not a build task today |
|---|---|---|
| (i) | **A `mirror` derivation kind** — site A must equal site B, no derivation — which is the only shape that reaches instance 4 statically | no executed fixture in instances 1–3 justifies the kind; building it on speculation is the thing this project keeps refusing |
| (ii) | **A census entry for the counts block** | it is a gating control inside an already-registered file — `README.md` §4's known hole #1 — and registering it moves the census off the 105 this packet was told to hold. One-entry follow-up packet |
| (iii) | **Widen §29d past digits, or decide the note field may carry prose cardinals** | §6.1. A design question about what a `note` is for; not an archivist's to answer |
| (iv) | **Copy the `DC-0001` close obligation into `standing_gates.md` under a `HARD STOP` line** | §6.4. `standing_gates.md` is frozen by the orchestrator's brief; unfreezing it is an operator act |
| (v) | **Widen the cardinal table past twenty**, or accept numerals | §8(4). A one-line change to `cnt_num` if anyone prefers words |
| (vi) | **`count_derive`'s `files` arm expands `$3` unquoted** | RECORDED, DELIBERATELY NOT FIXED on the reviewer's explicit instruction. No `eval`, no injection path, no live record does it. Tighten only if a `mirror` kind or a wider record population lands |
| (vii) | **Unfreeze `residue.md`** | §5. Operator act |

---

## 8. Residue and risks carried forward

**`build-os/memory/residue.md` cannot accept a byte (§5), so these live in
`build-os/memory/current_state.md` and `build-os/packets/active_packet.md` —
displacement, stated as such.**

1. **EVERY FUTURE CLOSE OWES `tool_router.md:368` A ONE-LINE EDIT IN THE SAME
   COMMIT AS THE RECEIPT.** Writing a receipt is what closes a packet, so every
   close increments `DC-0001`'s derivation and staleness follows in the same
   commit. It reddens `counts`, **`check`**, and
   `tests/control_registry_tests.sh` at `:183`, `:1248`, `:1255` and `:1267`.
   Standing form in `current_state.md` block 1.
2. **FROM RECEIPT TWENTY-ONE ONWARD THE SITE MUST CARRY A NUMERAL.** The cardinal
   table stops at twenty; `twenty-one` is `COUNT-UNREADABLE` and **refuses**.
   **This is the point at which someone concludes the guard is broken and deletes
   `DC-0001`.** It is not broken; it is fail-closed on a bounded word table.
3. **Instance 4 is unmechanised and unmechanisable by this design** (§6.0), and
   this packet performed it by hand to fix its own guard.
4. **Instance seven is open** (§6.1) — word-cardinals in `note` fields, invisible
   to a digit-only predicate.
5. **The standing obligation lives in a rotating file** (§6.4), protected by
   position rather than by policy.
6. **The §21 textual-enrolment hazard** (§6.3) — now in `current_state.md`, but
   the underlying scan still cannot tell a comment from an assertion.
7. **Sixth consecutive close at 3 commits** (§7.1) — routed, undecided.
8. **Depth-4 contract gap** (§7.2) — routed, undecided.
9. **Twentieth consecutive packet with no second eyes.**
10. Carried forward, untouched: `residue.md` frozen at 431 B; rotation-sentinel
    spec revisions (i) and (ii); `3a590ed`'s permanently false commit message.

---

## 9. Open boundaries — pending an explicit go

- **All three packet commits (`a714d8a`, `f0e2fba`, `f785056`) and this close
  commit are LOCAL AND UNPUSHED.** `188472f` is the pushed tip, and push was
  authorised **only through `188472f`**.
- **No push, no merge, no PR, no tag, no deploy, no secrets, no `git config`, no
  amend, no rebase** was performed by this close, and no such go has been given.
- Carried, unrelated and still open: Context Mode routing enablement; naming a
  target repo and approving a secret for the GH Actions; authorising the deferred
  connectors.

---

## 10. Close verification

- **`build-os/memory/tool_router.md:368` advanced `nineteen` → `twenty` IN THIS
  CLOSE COMMIT**, alongside the receipt that makes the derivation twenty. The
  0 → 2 → 0 transition was executed by the archivist, not assumed:
  `counts` exit **0** before the receipt, exit **2** with the receipt and the
  stale router, exit **0** after the router edit.
- `build-os/registry/scan-controls.sh` — `DC-0003`'s stored line-distance
  dropped (§6.2). `counts` exit **0**; the live-table digit predicate still
  reports **0** offending fields.
- `build-os/registry/defect_classes.txt` — **`OCCURRENCE-0019` appended**
  (§6.5); ledger now **19 occurrences**.
- `build-os/metrics/record-packet.sh` row appended for
  `gravito_p3b_count_derivation_a` — see §3 for the figures and the manifest.
- `build-os/metrics/check-adoption.sh` — **exit 0**. `record-packet.sh
  --verify-git` — **VERIFIED** at 7 files / 967 / 46; `--validate` — **0 invalid**.
- **`build-os/tools/bandwidth-check.sh check` went from RED to GREEN at this
  close, and the red was inherited.** It reported `packets EXCEEDED — 3 packet
  ids declared, ceiling 1` and refused at exit 2. Derived from git: `188472f`
  left **0** live `- **Packet id:**` markers (that archivist **renamed** the
  marker to `**Packet id (CLOSED):**`, which is the convention), `099d7bf` left
  **2** (that close **added** a live marker and renamed nothing), and this
  packet's declaration made **3**. All three are now renamed — **in place, line
  for line, so nothing above `:89` moved and `ANC-0003` needed no repointing**;
  `DEFECT-0001-stale-line-reference` did not fire at this close. The count is
  **0** and the tool exits **0**. This is a fourth face of
  `gate_permits_the_null_case`: the gate refuses two and permits zero, so nothing
  ever objected to a close leaving a stale live marker behind.
- `build-os/tools/memory-kernel.sh reconcile` — **1 projection checked, 0
  divergent.**
- `build-os/registry/scan-mutators.sh check` — exit **0**; **19 occurrences, 4
  classes recur** (was 18 and 3).
- `build-os/registry/scan-controls.sh counts` **after the close commit — exit 0.**
- Final solo full-capture suite run: **`CHAINED: 2228 passed, 0 failed`.**
- `git status --porcelain` empty at hand-back.
- Frozen-artifact proofs at hand-back:
  - `build-os/memory/residue.md` → blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, **unchanged**, **431 B** headroom.
  - `build-os/memory/standing_gates.md` → blob `e889868f`, **unchanged** (frozen by the brief; see §6.4).
  - `build-os/metrics/rank-candidates.sh` (`5543ea88`), `decision_telemetry.tsv` (`fd52eb15`), `signal_snapshots.tsv` (`7496ead8`), `build-os/memory/archive/residue.archive.md` (`f475d53e`) and all of `build-os/memory/archive/` → **untouched**.
