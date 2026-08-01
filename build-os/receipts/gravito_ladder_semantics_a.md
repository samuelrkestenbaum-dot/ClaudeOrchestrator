# gravito_ladder_semantics_a — the ladder is corrected, it re-authorised NOBODY, and its findings about the GUARDS matter more than the feature

- **Date:** 2026-08-01
- **Lane:** `substantive` (builder → qa ‖ reviewer → fix → re-review → tiny-lane close → archivist)
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `2df61ae` (the close of `gravito_mismatch_refuted_a`); re-verified at close —
  `git merge-base d0eff10 2df61ae` = `2df61ae`.
- **Final HEAD (packet):** `d0eff10`
- **Verdict:** **pass as fixed** — reviewer `fix-then-pass` **twice** (11 items, then
  2 findings), qa **GREEN** with 5 findings, **none functional**.
- **Second eyes:** **NONE.** Both verdicts single-model. No Codex in any pass.

---

# THE HEADLINE — THE LADDER GAINED A RUNG AND CHANGED WHAT `observe` MEANS, AND NOT ONE CONTROL MOVED

The operator ruled on the definitional bug the previous packet proved. Two changes:

| authority | corrected meaning |
|---|---|
| `none` | no runtime output or consumer |
| `observe` | output may be **recorded and consumed for visibility**; it causes **no operational consequence** |
| `advise` | output may influence a human or a higher-authority control |
| `rank` | output may order already-permitted alternatives |
| `gate` | output may allow or prohibit |
| `execute` | output may **directly cause mutation** |

**`observe` is redefined by CONSEQUENCE instead of by non-consumption**, and
**`execute` is added as a sixth rung above `gate`**. Ladder:
`none < observe < advise < rank < gate < execute`.

**Why it was needed.** `gravito_mismatch_refuted_a` proved `refuted → observe` was
an **unreachable remedy** — foreclosed for **67 of 81** controls with **0** sitting
there — because `none` **and** `observe` were **both** defined by non-consumption,
leaving the ladder with **no rung meaning "it is read, but may cause nothing."**

**The predicted result held exactly.** `evidence-policy.sh check` reports
**19 of 81, split 6/5/8 — UNMOVED**. The packet changed what `observe` *means*, not
what any control is *licensed to do*. **Zero governance-field diff lines.** **No
class licenses `execute`; 0 of 25 grid cells reach it**, pinned by a test.

---

# THE FINDINGS THAT MATTER MORE THAN THE FEATURE

## 1. THE CITATION GUARD CHECKS RESOLVABILITY, NOT IDENTITY — quantified

qa located the cause at **`build-os/registry/scan-controls.sh:368-392`**. The
evidence-ref loop tests **existence** (`[ ! -f "$REPO/$rf" ]`), **numeric**
(`case "$rl" in ''|*[!0-9]*)`), **in-bounds** (`[ "$rl" -le "$tot" ]`), and
**not-blank** (`vacuous_why`). **It never compares content.**

Measured across the three tools whose refs drifted:

| | count |
|---|---|
| refs that drifted (would cite a **different line**) | **27 of 27** |
| caught by `VACUOUS-REF` | **7** |
| **passed every check while silently wrong** | **20** |

**THE REVIEWER'S COROLLARY, RECORDED BECAUSE IT DISCOUNTS EARLIER CLAIMS:**

> **A content match at a single commit tests RESOLVABILITY; only a CROSS-COMMIT
> comparison tests IDENTITY.**

Several *"zero drift, 287/287 verified"* results earlier in this sequence were
**the former and were reported as the latter**. They are hereby discounted, not
retracted — they were true statements of a weaker property than the one claimed.

**The durable fix is an anchor token or a content hash instead of a line number.**
Not built here.

## 2. A PUSHED COMMIT SHIPPED RED, AND THE CLOSE CHECKLIST IS WHY

qa confirmed that **`2df61ae` — which is PUSHED — ships `./build-os/maintenance/run-tests.sh`
at 143/144**, not 144/144.

**Cause:** the previous archivist close cleared `build-os/packets/active_packet.md`
down to **2** `^## ` blocks, while `rotate-memory.mjs`'s two-pass rotation proof
needs **≥3** (`tests/scaffold_seeding_tests.sh:242`).

**Why nothing caught it: that suite is NOT chained into the 1636, and the
orchestrator's close brief did not ask for it.** **Record this as an ORCHESTRATOR
DEFECT** — a close checklist that omits a live suite is how a red commit reaches a
remote. **Commit 1 of this packet alone repairs it** (2 blocks → 10).

### qa PARTLY REFUTED the sharper hazard, and the correction is kept

The previous record said a zero-block file **"silently never rotates."** Measured:
a zero-block file is **byte-identical after `--apply`, exit 0, nothing fails** —
**but it is NOT silent.** `rotate-memory.mjs` emits an explicit
`WARNING: <path>: the block delimiter /^## / matched NOTHING … NOTHING CAN EVER
ROTATE OUT OF IT` on stderr. That warning exists at base and `rotate-memory.mjs`
was not touched.

**The failure mode is AN IGNORABLE WARNING, NOT SILENCE.** The word "silently" was
corrected in this packet's own prose and is annotated (not rewritten) in
`current_state.md` at this close.

## 3. THE MUTATION CENSUS — surveyed, reported, ACTED ON IN NO WAY

The reviewer called this **the packet's most valuable output**. `MISMATCHES.md` §15.

**The sharp case is NOT at `gate`.** `maint.managed_set_replacement` sits at
**`advise`**:

- declared `output`: *"files copied into an installed repo, replacing prior managed copies"*
- `failure_behavior`: *"none that stops anything"*
- `rollback_behavior`: *"none; a managed file's local edits are lost on install"*

`advise` means *the output may influence a human or a higher-authority control*.
**Copying files over a user's edits is not influence.** On the corrected ladder
that is `execute` — **two rungs up**. It is also `unvalidated`: nobody has watched it.

**FIVE MODULES DURABLY MUTATE, AND NOT ONE OF THOSE WRITE ACTIONS IS A REGISTERED
CONTROL AT ANY AUTHORITY:**

1. `build-os/maintenance/rotate-memory.mjs` — `renameSync` **onto the live memory file**. The most consequential write in the system.
2. `build-os/tools/swarm-merge.sh` — creates a commit behind `--commit`.
3. `build-os/metrics/record-packet.sh` — appends to the live metrics store.
4. `.claude/hooks/build-os-identity.sh` — writes the identity stamp into the repo.
5. `build-os/tools/specialist-handoff.sh` — takes a lock file under `$HOME`.

**The reviewer's ruling on the packet's own defence:**

> *"the controls are checks and the mutations belong to the modules they live in"*
> is **sound as a description of what the registry covers, and convenient as a
> reason not to extend it** — and **the most consequential write in the system has
> no entry.**

**IT RULED THIS SHOULD BE THE NEXT PACKET.**

## 4. FOUR ESCAPE FORMS, ALL THE SAME SHAPE

Every one is **a guard written against one surface form, blind to its siblings.**

1. **Bare `:NNN` citations** with the filename elsewhere in the sentence.
2. **`MISMATCHES.md` §10's table rows** — naming a file with **no line number at all**.
3. **Line-wrapped enumerations** — `none < observe < advise` on one line,
   `< rank < gate)` on the next. **No same-line grep can see it.** This is how a
   **FIFTH** stale ladder survived in `tests/neurocosmology_crosswalk_tests.sh` —
   a file this packet **had already edited** — past the orchestrator's sweep **and**
   the reviewer's first pass.
4. **Markdown table-row mappings** — `| shadow | observe | … |`, where the new guard
   expects `-> observe`. **The new §21 block is therefore STRUCTURALLY VACUOUS over
   `README.md`, the FIRST of its seven listed sites.** Proven, not argued: the row
   was rewritten to carry a consumption clause and **all three blocks missed it**.

## 5. THE PACKET REPRODUCED ITS OWN HEADLINE DEFECT — TWICE

It found a guard checking the **wrong property**, then built §21 to sweep seven
semantic sites — and:

- **§21 greps only ONE of the retired rule's TWO wordings** (README's *"nothing reads
  the result"*; the deployment axis says *"nothing consumes it"*). **That is why the
  stale definition survived in the file that OWNS the axis.**
- **Its successor block covers one of the mapping's TWO syntaxes** (escape form 4).

**Both were found by review, fixed or recorded, and named in the artefact.** The
shape is the lesson: a guard built in a hurry inherits the defect it was built against.

## 6. §16's COMPLETENESS CLAIM WAS WRONG, AND THE WRONG NUMBER IS LEFT VISIBLE ON PURPOSE

§16 said *"four live places … listed so the packet can prove it found them all."*
**It was five.**

The orchestrator **left the undercount in the record rather than silently correcting
it**, for two stated reasons: **a completeness claim that turned out false is the
strongest available argument for the guard §16 was deferring**, and it is **the same
enumeration-plus-assertion defect the packet had just fixed at item 10**.

---

## Rulings to record

### The ladder-spelling sweep STAYS DEFERRED to §16's own packet

The reviewer **upheld all three grounds**:

1. **A different site set** — spelling drift lands where semantics drift does not.
2. **The five-rung string is a PREFIX of the six-rung one**, so it needs an
   enumeration-**continuation** test, not a containment test. A containment test
   passes on the correct string.
3. **Bolting a second guard onto a stage-3 round is how fix lists arrive in
   installments.**

**What was unsound was the deferral's EVIDENCE, not the deferral** — §16's
"four places" was five.

### The `observe`/`advise` boundary is now INTENT-BASED, not mechanically checkable

| rung | mechanical test |
|---|---|
| `none` | "no consuming policies" |
| `observe` | **NONE — it used to have one** |
| `advise` | **NONE** |
| `rank` | **NONE** |
| `gate` | "exits non-zero" |
| `execute` | "performs a durable write" |

**Three of six rungs are now separated by the author's assertion alone.**

**This was the right trade** — the checkable boundary (non-consumption) is exactly
what made the rung unreachable — **and it is recorded as a COST**, in `README.md` §2
and here.

### `execute` is EARNED, not another empty rung

The reviewer's distinction, recorded because it is the answer to "you just added a
second `rank`":

- **`rank` is 0-occupancy because nothing in the system ranks** — the concept has
  **no referent**.
- **`execute` is 0-occupancy because FIVE real, named, durable mutators exist and
  are UNREGISTERED.**

**Occupants demonstrated by survey, not asserted.**

### `autonomous → execute`, with the discarded reading recorded and answered

The reading not taken: *"an operator authorising AUTONOMY did not thereby authorise
MUTATION"* — **real, but misplaced**, because the deployment axis states a **CAP,
not a grant**, and `L_effective = MIN(...)` means **the class axis still withholds
`execute` from every class**. Holding `autonomous` at `gate` would have converted a
documented **non-cap** into a real cap on the whole census and made `execute`
unreachable on that axis for everyone — **the same unreachable-rung defect, one axis
along.** Whether a fifth deployment mode should exist survives as a live question
(`README.md` §3b).

---

## Scope

**In:**

1. Redefine `observe` at all semantic sites, **by content** — six declared, **seven
   found** (the seventh: `control_registry.txt`'s `maint.source_scan_mask`, carrying
   the retired rule in **two live fields**, including the `demotion_requirement` an
   operator reads **while deciding**).
2. Add `execute` as the sixth rung across every `LADDER` string and `rank_of()` mapping.
3. Reassess `OBSERVE-LB` — **moved off the gating path** to a new advisory channel
   that prints and counts but never sets the exit code; re-keyed to **consequence**.
4. Decide and state `autonomous`'s cap → **`execute`**.
5. Tests first, at every changed site (`tests/evidence_policy_tests.sh` §21).
6. `CHANGELOG.md`, cited by release-block heading, never by line number.

**Out — recorded, not acted on:**

- Whether **Class A should license `execute`** — a governance question. Recorded.
- **The mutation census** — reported as a finding (§15). **Re-authorises nothing.**
- Any change to any `class`, `runtime_authority`, `authority_mismatch` or
  `empirical_status`. **Zero such diff lines exist.**
- **The ladder-spelling sweep** — deferred to §16's own packet.

---

## Commits — 2, at the cap

| commit | one-line |
|---|---|
| `576751a` | `docs(packet): declare gravito_ladder_semantics_a before building` |
| `d0eff10` | ``feat(registry): correct the ladder — `observe` by consequence, and `execute` above `gate` `` |

**`576751a` is untouched and is still an ancestor of `d0eff10`** — and **it is the
commit that repairs the base's 143/144**, by promoting the declaration's own headings
from `###` to `##`. **No guard was weakened; `rotate-memory.mjs` was not touched.**

**Commit 1 is deliberately the DECLARATION ALONE.** That resolves residue item (ee) —
the tension between "declare before building" and the `≤2-commit` cap — **without a
third commit and without a pre-commit hook**: it is trivially green in isolation,
keeps the cap at two, and **lets git attest the ordering.** Nothing required the docs
to be the second commit.

**File-ownership manifest** (numstat union of `576751a` + `d0eff10`): **13 files,
1064 insertions, 186 deletions.**

```
CHANGELOG.md                              165 +
build-os/packets/active_packet.md         (decl. 152 in c1, 13 in c2)
build-os/registry/MISMATCHES.md           243 +-
build-os/registry/README.md               111 +-
build-os/registry/authority_envelopes.txt  31 +-
build-os/registry/control_registry.txt     34 +-
build-os/registry/scan-controls.sh         19 +-
build-os/tools/authority-envelope.sh       52 +-
build-os/tools/evidence-policy.sh          48 +-
tests/authority_envelope_tests.sh          19 +-
tests/control_registry_tests.sh            10 +-
tests/evidence_policy_tests.sh            347 +-
tests/neurocosmology_crosswalk_tests.sh     6 +-
```

---

## QA proof — GREEN, 5 findings, none functional

| check | result |
|---|---|
| `bash tests/build_os_tests.sh` | **1636 passed / 0 failed** (was 1617) |
| `./build-os/maintenance/run-tests.sh` | **144/144** (base `2df61ae` was **143/144**) |
| `bash build-os/registry/scan-controls.sh check` | **exit 0** — 81 controls / 36 surfaces |
| `bash build-os/tools/evidence-policy.sh check` | **19 of 81, split 6/5/8 — UNMOVED**, exit 0 |
| **Commit-1 isolation** | **GREEN in isolation** — `576751a` builds and passes on its own |
| **Safety grep** | run; governance-field diff = **0 lines** on `class:`, `runtime_authority:`, `authority_mismatch:`, `empirical_status:`, `implementation_status:` |
| **UI smoke** | **N/A — this packet has no UI surface.** Registry/tooling only; no frontend file touched. |

**qa's 5 findings were all NON-FUNCTIONAL** — the citation-guard quantification
(finding 1), the pushed-red-commit diagnosis (finding 2), and the partial refutation
of "silently". None blocked.

**Red-drive evidence recorded by the builder and confirmed:** §21's successor block
was driven red first — **it fails on exactly the two offending sites and no others
(120 passed, 1 failed)** and goes green once both are corrected (**121 passed, 0
failed**). The `OBSERVE-LB` move was proven in both halves: it **still fires by name**
**and** the scan **exits 0**, while a genuine violation **still refuses at exit 2** —
so only that one check moved.

---

## Fix rounds

| round | source | items |
|---|---|---|
| stage-3 fix | reviewer `fix-then-pass` #1 | **11 items** |
| — | delivered as | **13 items in ONE installment** (the builder's by-number sweep found 2 more) |
| re-review | reviewer `fix-then-pass` #2 | **2 findings** |
| tiny-lane close | orchestrator | **3 prose sites** |

**All fix rounds complete and re-verified.** The stage-3 fix arrived in **one
installment**, not in pieces — which is the remedy the previous two packets'
depth defects called for.

**Second eyes: NOT DELIVERED, for the FIFTH packet running.**
`build-os/memory/tool_router.md:368` routes reviewer second-eyes to Codex; `codex` is
not on PATH and no Codex plugin is installed. **Every verdict in this packet is
single-model.** It matters here specifically: **the reviewer's resolvability-vs-identity
corollary retroactively discounts earlier claims**, and that is exactly the kind of
judgement an independent second model exists to check.

---

## Final state at `d0eff10`

| measure | value |
|---|---|
| Suite `tests/build_os_tests.sh` | **1636 passed / 0 failed** |
| `./build-os/maintenance/run-tests.sh` | **144 / 144** |
| `scan-controls.sh check` | **exit 0** |
| `evidence-policy.sh check` | **19 of 81, split 6/5/8** |
| Census | **81 controls, 14 declared mismatches** |
| Distribution | 68 `gate` / 13 `advise` / **0 `none`, 0 `observe`, 0 `rank`, 0 `execute`** |
| Class | A **58** / B **3** / C **20** |
| `implementation_status` | 67 `load_bearing` / 9 `implemented` / 5 `decision_contributing` |
| `evidence_refs` | **287**, all resolving |
| Live authority envelopes | **0** |
| Ladder | `none < observe < advise < rank < gate < execute` |
| Tree | **clean** |

All figures re-derived by the archivist at close directly from
`build-os/registry/control_registry.txt` and the live tools.

---

# Residue — what this close hands forward

## 1. The citation guard's resolvability-vs-identity gap — and the retroactive discount

`scan-controls.sh:368-392` tests four properties and **never content**. 27 of 27
drifted refs would have cited a different line; **20 passed every check while
silently wrong**. **Earlier "zero drift, 287/287 verified" results tested
resolvability and were reported as identity.** The durable fix is an **anchor token
or content hash**, not a line number. Residue **(mm)**.

## 2. The mutation-census coverage gap — REVIEWER SAYS THIS IS THE NEXT PACKET

Five named durable mutators, none registered as a mutation at any authority; and
`maint.managed_set_replacement` sits at `advise` with an `output` that copies files
over a user's edits and **no rollback**. Registering them is **the operator's act**.
Residue **(nn)**.

## 3. The close-checklist gap that let a PUSHED commit ship red

`./build-os/maintenance/run-tests.sh` is **not chained into the 1636**, and the
orchestrator's close brief **did not ask for it** — so `2df61ae` shipped and was
pushed at 143/144. **Orchestrator defect.** The remedy is a close checklist that
names every live suite, or chaining that suite. Residue **(oo)**.

## 4. Four escape forms, all one shape

Bare `:NNN`; table rows with no line number; **line-wrapped enumerations**; **markdown
table-row mappings**. **The new §21 block is structurally vacuous over `README.md`,
its own first listed site.** Residue **(pp)**.

## 5. The `observe`/`advise` boundary is now INTENT-BASED — a recorded COST

Three of six rungs are separated by the author's assertion alone. Right trade,
real loss. Residue **(qq)**.

## 6. The ladder-spelling sweep — DEFERRED, ALL THREE GROUNDS UPHELD

Needs an enumeration-**continuation** test because the five-rung string is a
**prefix** of the six-rung one. `MISMATCHES.md` §16. Residue **(rr)**.

## 7. Carried forward, unchanged

- **The three operator decisions from `gravito_mismatch_refuted_a`:** decision (2),
  **the ladder's definitional bug, is now CLOSED by this packet.** Decisions (1) —
  the **missing fifth outcome** — and (3) — **`OBSERVE-LB`'s placement** — are
  **addressed**: `OBSERVE-LB` is off the gating path, and `observe` is now a legal
  destination, which is what the fifth outcome needed. **Neither is thereby
  "taken" by the operator**; what changed is that the remedy is now spellable.
- **Step 3 still cannot be done by writing envelopes** — an envelope only lowers
  `L_effective`. Residue (w).
- **DO NOT EXTRAPOLATE the two refuted closures to the remaining twelve mismatches** —
  11 of the 19 findings are `unvalidated`. Residue (gg).
- The **S1** evidence-token and `runtimeAuthority` decisions — **operator's, untaken**.
- **Second eyes unbacked** — five packets running. Residue (k)/(q)/(z)/(ll).

---

## Open boundaries — nothing done without go

- **NOTHING WAS PUSHED, MERGED, TAGGED, PR'd, DEPLOYED OR PUBLISHED by this close.**
  No secret was touched. No `git config` was run.
- **`576751a`, `d0eff10` and this close commit are LOCAL-ONLY** and stay that way
  pending explicit go, joining the local-only run from `105cb75` onward.
- `/home/user/empathiq-website` was **not touched** (verified clean at `cb2bb7d`).
- **The mutation-census registrations are re-authorisations and are the operator's** —
  none was performed.
- **Whether Class A should license `execute`** — open, deliberately.
- **Whether a fifth deployment mode for mutation should exist** — open (`README.md` §3b).

---

## Verification performed by this close

Re-run by the archivist **after** its own writes, on a quiet tree:

| check | result |
|---|---|
| `bash tests/build_os_tests.sh` | see the close report |
| `bash build-os/registry/scan-controls.sh check` | exit 0 |
| `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` | **MATCH** against the live suite total |
| `git status --porcelain` | empty |
| `./build-os/maintenance/run-tests.sh` | **144/144** — **verified AFTER the writes, because its absence from the previous close checklist is finding 2** |

## Files written by this close — all inside `build-os/`

- `build-os/receipts/gravito_ladder_semantics_a.md` (this file — new; no past receipt rewritten)
- `build-os/memory/current_state.md`
- `build-os/memory/residue.md`
- `build-os/packets/active_packet.md` (cleared, **and left with ≥3 `^## ` blocks** — clearing it to 2 is exactly what made `2df61ae` ship red)
- `build-os/metrics/packet_metrics.tsv` (one appended row; `defects_escaped` = `-`)

## The close is a THIRD commit, and that is deliberate

The packet's own ≤2-commit budget is spent on `576751a` + `d0eff10`. The close is
**bookkeeping after the verdict, not a third gate**, and it lands separately so that
the packet's diff stays exactly what the gates measured.
