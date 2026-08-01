# gravito_p4_s1_shadow_ranker_a — the first executive component: a real candidate set in, an immutable explained ordering out, and the first ordering it produced is degenerate

- **Packet id (canonical):** `PACKET-0034-gravito-p4-s1-shadow-ranker-a`
- **ID DERIVED AND COLLISION-CHECKED AT THIS CLOSE, NOT ACCEPTED FROM A BRIEF.**
  The id is taken from `build-os/packets/active_packet.md`, which declared it at
  `9742a10` **before the first implementation edit**, and it was then checked
  against every `PACKET-*` id live in the tree. **`PACKET-0034` is free:**
  `decision_telemetry.tsv` allocates `PACKET-0007`..`PACKET-0033` and nothing
  else, and a tree-wide grep finds `PACKET-0034` in exactly one place — the
  declaration itself. **This check is not ceremony.** At the P3 close the
  orchestrator's brief supplied `PACKET-0020`, which was already held by
  `PACKET-0020-widen-control-registry-with-claim-fields`, a **rejected**
  `DECISION-0008` candidate; writing it would have collided two different
  candidates under one key **inside the store S1 itself now reads**. This close
  brief supplied no id and named the check explicitly; the check was run anyway,
  against the brief as well as against the store.
- **Date:** 2026-08-01
- **Lane:** `substantive` (builder → qa ‖ reviewer → fix round → archivist)
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `ce71122`, re-verified at close — `git merge-base b9896e0 ce71122` =
  `ce71122`, so the branch base is correct.
- **Final HEAD (packet):** `b9896e0`
- **Verdict:** **PASS-AS-FIXED.** qa **GREEN**. reviewer **fix-then-pass**, all
  enumerated items fixed and **orchestrator-verified**.
- **Depth: 3 SERIAL STAGES — builder, then qa ‖ reviewer CONCURRENTLY, then the
  fix round. NO STAGE 4.** P3 reached stage 4 and the contract calls that a
  defect; here the orchestrator **verified the fix round itself** rather than
  opening a fourth gate stage. Recorded as the contract working, not as luck.
- **Second eyes: NONE — TENTH CONSECUTIVE PACKET.** `tool_router.md` was
  corrected at `ce71122` to state plainly that this runtime has never had a
  second-eyes capability, and to **require the reviewer to say
  *"second eyes: NONE, single-model"*** rather than silently omit it. **The
  reviewer complied.** Every verdict in this entire five-phase sequence is
  single-model.

---

# PHASE CONTEXT — THIS IS THE MILESTONE

**P1 ✅ → P2 ✅ → P3 ✅ → P4 (this) → P5 outcome/counterfactual telemetry.**

| phase | subject | state |
|---|---|---|
| P1 | mutators / IDs / telemetry | **done** |
| P2 | claim-scoped evidence | **done** |
| P3 | `accept_and_constrain` + lease enforcement | **done** |
| **P4 (this packet)** | **S1, the shadow ranker — THE FIRST EXECUTIVE COMPONENT** | **done** (`b9896e0`) |
| P5 | outcome / counterfactual telemetry | next |

**The operator's framing, recorded because it is what P4 is measured against:**

> Everything before P4 made Gravito better at **preventing a bad action**. P4 is
> the first component that forms **an explicit, inspectable preference among
> several permissible good actions.**

**Success condition, operator-stated:** *"A real candidate set goes in, and an
immutable explained ordering comes out."* **MET** — see the artifact below, and
see §"WHAT THE GATES PROVED" for the evidence that the candidate set is
genuinely real rather than synthetic.

The ledger changes shape at this close: **99 controls, ~20 tools, 1909
assertions, and ONE executive component** — where every prior close in this
sequence recorded **zero**.

---

# THE ARTIFACT — THE DELIVERABLE, RECORDED VERBATIM

```
decision: DECISION-0010-p4-s1-shadow-ranker   ranking_rule: s1-v1
excluded PACKET-0032-p5-outcome-counterfactual-telemetry  reason=self_amendment
excluded PACKET-0033-observe-advise-boundary-recheckable  reason=self_amendment
rank 1  PACKET-0027-p3b-count-derivation                total=10  pareto=frontier
rank 2  PACKET-0029-citation-anchor-tokens              total=4   dominated
rank 3  PACKET-0030-mutation-census-coverage-gap        total=3   tie=yes
rank 3  PACKET-0031-governance-baseline-completeness    total=3   tie=yes
rank 5  PACKET-0028-positional-content-pairing-guard    total=1   dominated
selected: PACKET-0027   rank_of_selected: 1
ranking_digest: 2fa876c632bf81088793968a5d76501556fe283dc27ff97aad40459218df81c8
```

**The digest is byte-identical before and after the fix round** —
orchestrator-verified, and **re-verified live by the archivist at this close**:

```
bash build-os/metrics/rank-candidates.sh rank --decision-id DECISION-0010-p4-s1-shadow-ranker
```

exits **0**, prints the ordering above, prints
`ranking_digest: 2fa876c6…18df81c8`, and — checked by md5 immediately before and
immediately after the run — leaves `decision_telemetry.tsv`,
`signal_snapshots.tsv` **and** `residue.md` **byte-identical**. That is the
dispatch guarantee measured rather than asserted.

**Three properties of the artifact worth naming separately:**

- **Ties are reported, not broken.** `PACKET-0030` and `PACKET-0031` both hold
  rank 3 and the next rank is **5**. A rule that invented a tiebreak would be
  inventing an unregistered constant inside a decision.
- **Excluded candidates stay on the record with their reasons**, and their frozen
  signal values are printed anyway. A refusal that is not visible is not a
  refusal.
- **Every absent signal is named as absent.** Five declared signals are
  `MISSING` for this decision, two are `UNINTERPRETED` (frozen, but their
  direction has never been established, so S1 refuses to guess one), and six are
  `NEVER-COLLECTED`. **Nothing is imputed, defaulted, or dropped.**

---

# WHAT THE GATES PROVED — qa GREEN, EVERYTHING MEASURED, REPO UNMODIFIED

**1. The counts.** Suite **1898 / 0** at `af4ce0c`; **commit-1 green in
isolation at 1869 / 0 in a fresh clone**; the **+29** at the build commit lands
in `tests/mutator_registry_tests.sh` §13 **only** — **all 18 other chained suites
moved +0**.

**2. THE CANDIDATE SET IS GENUINELY REAL, AND THIS IS THE LOAD-BEARING PROOF OF
THE SUCCESS CONDITION.** All 12 lettered anchors resolve in `residue.md`
**by content**, not by letter:

| anchor | what it literally says | candidate |
|---|---|---|
| `(mm)` | *"an ANCHOR TOKEN or a CONTENT HASH instead of a line number"* | `PACKET-0029` |
| `(nn)` | names `maint.managed_set_replacement` — **verbatim** that candidate's write surface | `PACKET-0030` |
| `(yy)` | locates the hole at `tests/mutator_registry_tests.sh` **§11** — **verbatim** that candidate's | `PACKET-0031` |
| `(hhh)`–`(lll)` | map **1:1** onto `PACKET-0027`'s six write-surface tokens | `PACKET-0027` |

A ranker fed a synthetic candidate set proves nothing about ranking. This one was
fed the repository's own open work.

**3. THE STRONGEST RESULT — THE NAMED DEFECT CLASS IS CAUGHT IN CODE, NOT IN
PROSE.** qa appended a **legitimately chained** orphan snapshot naming a
candidate the decision does not declare. `snapshot-verify` **PASSES it at exit
0** — it genuinely parses and chains, so the chain check is not what catches it.
The ranker still refuses at **exit 2**:

> *"snapshot(s) claim decision … but name candidate(s) the decision does not …
> **RESOLVABILITY IS NOT IDENTITY**."*

That is residue `(mm)`'s doctrine — the sequence's most-repeated finding — made
mechanical inside the first executive component.

**4. FREEZING HOLDS IN BOTH DIRECTIONS.** Gutting `residue.md` leaves the digest
**identical** (the signals are frozen, not recomputed against the tree); editing
a frozen value in place trips **`TAMPERED`, exit 2**.

**5. ZERO DISPATCH, BY MEASUREMENT.** Both stores byte-identical across a rank
run; **no policy and no tool in this repository consumes the ordering.**

**6. `rank_of_selected: 1` IS NON-CIRCULAR, AND THE PROOF IS TIMESTAMPS.**

| event | commit | time |
|---|---|---|
| the selection anchor exists | `5c8d19e` | **21:05:58** |
| the ranker is **absent** at base | `ce71122` | **21:41:30** |
| the ranker is created | `af4ce0c` | **22:28:34** |

**82 minutes** separate the base from the ranker's existence. The telemetry row
is co-committed with the tool, but **the referent is prior and independently
verifiable** — the selection was made, endorsed and staged before anything could
rank it.

**7. THE CEILING WAS HELD, AND ITS ONE EXCEPTION IS PAID FOR WITH A REPRODUCED
FIXTURE.** **0 new stores, 0 new validator tools, 0 new suite files, 0 new
governance primitives.** Exactly **one** new file exists in the whole range —
`build-os/metrics/rank-candidates.sh`, which **is** the deliverable.

The single exception is **2 census entries where the ceiling said ≤1**, and it is
justified by a fixture qa **reproduced verbatim at base**:

> `scan-controls: REFUSED — UNREGISTERED build-os/metrics/rank-candidates.sh can
> terminate a run non-zero and owns NO registry entry at authority gate.`

S1 is Class C and composes to `observe`, so it **cannot** own a `gate` entry.
Resolved by splitting `ranker.s1_shadow_ordering` (C / untested / `observe`) from
`ranker.s1_input_integrity` (A / red_driven / `gate`) — **the same split
`envelope.grant_composition` / `envelope.derivation_nonvacuity` already makes.**
The rejected alternative was registering the ranker itself at `gate`, two rungs
above its licence, **shipping a twenty-first declared mismatch to launder a
refusal path**. **There is no 21st mismatch: the declared count is still 20.**
Recorded as residue `(sss)`: the tree's own anti-shelfware guard makes a
"≤1 new control" ceiling **unreachable for any new refusing tool**, and it will
fire again on the next one.

---

# THE FINDINGS THAT MUST SURVIVE — THE REVIEW'S REAL VALUE

## 1. THE FIRST ORDERING IS DEGENERATE

`PACKET-0027` scores the **maximum on all three ranked signals that were frozen**
and therefore **Pareto-dominates every rival**. The reviewer swept **125 of 125
weight combinations** and **every single-signal drop**; all of them return the
**same sole winner**. **No monotone weighting can dethrone it.**

The consequence, in the reviewer's own words:

> **A result that survives every perturbation is not robust — it is
> uninformative.**

The ordering carries **no information beyond "one candidate dominates"**, and the
10-vs-4 margin is **decorative**. Agreement with the operator on `DECISION-0010`
is therefore *very* weak evidence about `s1-v1`: a rule that ranked at random
would have agreed here too.

## 2. THE MARGIN MEASURES RESIDUE LETTERING GRANULARITY, NOT VALUE

`residue_items_closed` counts residue **letters**. `(hhh)`–`(lll)` are **five
letters for ONE defect class** — the single re-cut item `PACKET-0027` actually
is. Re-letter it as one item and the margin collapses **10-4 → 6-5**. Drop the
ruling signal as well and **`PACKET-0029` wins.**

**A signal whose scale is set by how finely somebody happened to letter a
markdown list is not a measurement.**

## 3. TWO OF THE THREE SIGNALS ARE NOT INDEPENDENT

A **single sentence** in `residue.md` — the one that names the five re-cut items
and the reviewer's standing ruling over them — supplies **both**
`residue_items_closed=5` **and** `residue_ruling_satisfied=1`. Two signals read
off one sentence are one signal counted twice, and `s1-v1` weights them 1 and 1,
so **that one sentence carries two thirds of the ruling candidate's ranked
evidence**. (Cited by content on purpose — a live `path:N-M` range in a receipt
is exactly what §27d caught twice at the P3 close.)

## 4. `residue_ruling_satisfied` IS LABEL LEAKAGE

The recorded `selection_reason` for `DECISION-0010` reads, verbatim, *"the only
candidate a standing ruling names as NEXT rather than as queued."* **That is one
of the three ranked signals.** S1 was partly scoring candidates on the operator's
own stated reason for picking one. **Agreement obtained that way is not
agreement.**

## 5. BUT `residue_items_closed` IS DERIVED, NOT ASSERTED — AND THE ASYMMETRY PROVES IT

Verified. `PACKET-0028` scores **1, not 2**, despite citing two residue letters,
because `(nnn)` says *"AND `(ddd)` STAYS QUEUED… do not mark it consumed."*
**Fitting would not produce that.** The signal reads the residue's own ruling and
declines the count its own candidate would have preferred. This is the finding
that keeps §§1–4 from collapsing into "the whole thing is fitted": one of the
three signals is demonstrably a derivation.

## 6. THE OUT-OF-SAMPLE REPLAY — OBTAINED BY THE REVIEWER, NOT CLAIMED BY THE PACKET

`s1-v1` was hand-evaluated on **frozen v1 data authored before S1 existed**, on
the two decisions where the human went **against** the cheap signal. The scorer
was validated **by first reproducing `DECISION-0010` exactly**
(`P0027=10, P0029=4, P0030=3, P0031=3, P0028=1`) before it was trusted on
anything else.

```
DECISION-0008: selected P0019 -> rank 1 (tied)   DECISION-0009: selected P0023 -> rank 1 (tied)
with plausible guard-1 exclusions:  both become SOLE rank 1
```

**TWO CAVEATS, NEITHER OPTIONAL.**

1. **Those write surfaces are RECONSTRUCTED, NOT FROZEN.** They must **NEVER** be
   entered as snapshots. Doing so would recompute a signal against the current
   tree — **the exact defect S1's own `demotion_requirement` names** — and would
   score decisions nobody took on information nobody had. It is a hand-check
   recorded as prose and that is all it is.
2. **A TIE OUT-OF-SAMPLE, A LANDSLIDE IN-SAMPLE — AN OVERFITTING SIGNATURE,
   RECORDED BESIDE THE POSITIVE RESULT AND NOT UNDER IT.** On the decision S1 was
   built against, the winner scores 10 to the runner-up's 4. On the two it was
   not, the selected candidate merely **ties** for first. *Three agreements out
   of three* is the encouraging reading and it is not the honest one.

## 7. GUARD 1 FAILED OPEN ON SPELLING, AND IT TOOK TWO AGENTS TO SEE IT

qa built **four aliases** of the protected path. **All four reached rank 1** while
only the exact literal was excluded — against a header claiming the guard *"fails
CLOSED"* and is *"deliberately OVER-BROAD in the safe direction."* **A guard that
a rename of the same path defeats is not a guard.**

**Fixed:** `touches()` now **normalises** both sides (`./` segments dropped,
repeated slashes collapsed, `..` resolved lexically, trailing `/` removed, the
`#object` suffix carried through untouched); **wildcards are REFUSED, not
interpreted** (`guard1_uninterpretable_surface` — expanding one would make the
screening a function of the working tree rather than of the frozen snapshot, i.e.
would screen frozen evidence against the current tree); and **`set -f` was
added**.

**The `set -f` line is the reason two agents were needed:** its absence is why
**qa saw `EVADE-D` ranked and the builder saw it excluded — the same tool, run
from different working directories.** All five fixtures are now excluded and
innocent neighbours still rank.

## 8. GUARD 1's REMAINING BLIND SPOT — DISCLOSED, NOT WIDENED

Guard 1 screens reachability to the **promotion machinery**. It does **not**
screen reachability to the **evidence substrate**: `record-decision.sh`,
`signal_snapshots.tsv`, `decision_telemetry.tsv` and `build-os/memory/residue.md`
are all outside `PROTECTED_SURFACE`, even though S1's own
`promotion_requirement` turns on `rank_of_selected` history, which lives in
exactly those files.

**LIVE, NOT HYPOTHETICAL: `PACKET-0029` is ranked 2 in this very ordering, and
its frozen write surface includes `build-os/memory/residue.md` — the file
`residue_items_closed` is derived from.**

**Deliberately not widened.** Nearly every packet here writes `residue.md`, so
protecting it turns guard 1 from a predicate into a **wall** that refuses almost
every candidate, and S1 would then emit no orderings rather than safe ones. The
real remedy is to make the evidence substrate **append-only and tamper-evident**
— which `record-decision.sh` already is for snapshots and `residue.md` is not —
and that is a later packet. Disclosed in the guard 1 header beside
`PROTECTED_SURFACE`, in `ranker.s1_shadow_ordering`'s registry notes, and in
residue `(zzz)`. **Not closed.**

## 9. THE EXIT CONTRACT WAS FALSIFIED AND IS NOW TRUE

When guard 1 excluded **every** candidate, the tool printed an **empty ordering
and exited 0**, against a header saying `Exit: 0 an ordering was produced`. **A
ranking over an empty candidate set is satisfiable by anything** — which is the
exact principle the tool already used to refuse an unknown decision id.

Now: `ordering: NONE — every candidate was refused`, `rank_of_selected:
excluded`, **exit 2**, and **all exclusions and all frozen values still printed**.
**Orchestrator-verified live.**

## 10. THE BUILDER FOUND A BUG IN ITS OWN FIRST DRAFT

`local t="$1" p="${t%%#*}"` expands the **outer** `t`, not the new local, which
made `touches()` return true for **everything**. Split across two `local` lines
with the reason written into a comment beside it.

---

# VERDICT ON THE MILESTONE — RECORDED HONESTLY

The reviewer's own words:

> *"Yes, narrowly and honestly. It forms a preference, publishes the
> decomposition, and refuses to rank its own promotion. It is not governance
> wearing a label. **But the first ordering it produced is degenerate, so the
> executive exists as a MECHANISM before it exists as a DEMONSTRATED
> CAPABILITY** — and the packet's own residue says so."*

`rank_of_selected: 1` is **uninformative at n=1**, and **the tool says so in its
own output**: the `note:` line it prints reads *"rank_of_selected is the
measurement that makes S1 falsifiable. Agreement on a single decision is not
evidence of skill; it is one observation, and this tree's own residue records
that n is small enough for that to matter."* **No overclaim anywhere in the
diff.**

---

# Scope

**In scope, and delivered:**

- `build-os/metrics/rank-candidates.sh` — **S1**, `controlClass:
  heuristic_policy`, class C, `empiricalStatus: untested`, `runtimeAuthority:
  observe`, `deploymentMode: shadow`, `outputSemantics: ordered_candidates`.
  Composition `MIN(advise, observe, observe) = observe`, **registered at exactly
  that**.
- The nine required outputs: stable candidate ids · frozen signal snapshots,
  never recomputed · every candidate visible including last-ranked and refused ·
  per-candidate signal values · the **decomposition**, not just a total ·
  self-amendment exclusions printed with reasons · the actual selection ·
  `rank_of_selected` · **zero dispatch authority**.
- Both guards: **(1)** no learned policy may optimize the mechanism governing its
  own promotion — refused visibly, failing closed; **(2)** publish the
  decomposition.
- `DECISION-0010-p4-s1-shadow-ranker` recorded with **7 candidates and 28 frozen
  snapshots**.

**Explicitly out of scope, and held:**

- **Fixing the signal set. `s1-v2` is a later packet.** The operator's ceiling
  reasoning applies to S1's own shortcomings exactly as it applies to governance
  defects, and re-cutting a signal set inside a bounded fix round is the adjacent
  tidying that turns three serial stages into four.
- Widening `PROTECTED_SURFACE` to the evidence substrate (§8), and closing the
  directory-prefix alias (see residue) — **both deliberately left open**, the
  second because treating a directory as covering its contents would make
  `build-os` cover everything **and would move the live `DECISION-0010` ordering
  the non-circularity proof is anchored to**.
- Any re-authorisation. **Zero governance-field changes to any pre-existing
  control**, field-anchored across all 99.
- Consuming the ordering. **No policy reads it. Nothing was dispatched.**
- Anything outside this repository. **No push, no merge, no PR, no tag, no
  deploy, no secrets, no `git config`.**

---

# Commits — 3, WHICH IS ONE OVER THE ≤2 CAP, RECORDED NOT EXCUSED

| commit | one-line | files | +/− |
|---|---|---|---|
| `9742a10` | `docs(packet): declare gravito_p4_s1_shadow_ranker_a before building` — the declaration **alone**, so git attests the packet was declared before its first implementation edit | 1 | +63 / −93 |
| `af4ce0c` | `feat(metrics): S1 — a real candidate set in, an explained ordering out, and a refusal to rank itself` | 11 | +945 / −43 |
| `b9896e0` | `S1 fix round: refuse an empty ordering, close guard 1's spelling holes, disclose its blind spot` — the bounded stage-3 fix round | 6 | +273 / −16 |

**The cap.** The contract says **≤2 commits**. Three shipped, because the stage-3
fix round landed as its **own** commit rather than amending a commit qa and the
reviewer had already measured. **Amending would have destroyed the ability to say
what was reviewed**, so the alternative to the deviation was worse. **Same
deviation as P3, same reason, and it is still a deviation** — the standing
tension between "declare before building" and the ≤2 cap is residue `(ee)` and
remains an operator decision.

**Two measurement conventions, and here they very nearly agree:**

| convention | files | insertions | deletions |
|---|---|---|---|
| **GUARD's** — distinct paths across the three commits, per-commit numstat **SUM** (what `record-packet.sh --verify-git` and `check-adoption.sh` measure) | **12** | **+1281** | **−152** |
| **NET diff**, base `ce71122` → HEAD `b9896e0` | **12** | **+1265** | **−136** |

`packet_metrics.tsv` records the **guard's** numbers — the guard measures the
**sum** precisely so a packet cannot hide churn by reverting it inside its own
range. The 16-line gap is churn the build commit added and the fix round then
rewrote. **This was P2's failure mode and P3's first-attempt failure mode; the
ruling from residue `(ggg)` is applied again: fix by RECORDING, never by widening
the guard.**

## File-ownership manifest — attribution by path

The `packet_metrics.tsv` row names **three** commits, so attribution must stay
recoverable. **THIS MANIFEST IS NOT FULLY DISJOINT, AND SAYING SO IS THE POINT OF
RECORDING IT** — the same honest statement P3's manifest had to make.

| commit | owns | files | disjoint? |
|---|---|---|---|
| `9742a10` | **`build-os/packets/active_packet.md` — and nothing else** | **1** | **YES — intersection with BOTH other commits is EMPTY** (`comm -12`, verified at this close) |
| `af4ce0c` | the build set | **11** | overlaps `b9896e0` on **6** files |
| `b9896e0` | the fix-round set | **6** | overlaps `af4ce0c` on **6** files — i.e. **every file the fix round touched was already written by the build commit** |

**The 6 overlapping paths, in full:**

```
CHANGELOG.md
build-os/memory/current_state.md
build-os/memory/residue.md
build-os/metrics/rank-candidates.sh
build-os/registry/control_registry.txt
tests/mutator_registry_tests.sh
```

**THE HONEST ATTRIBUTION RULE, since path alone is insufficient here:**

- **The declaration is separable by path.** `9742a10` owns exactly one file and
  no other commit in this packet touches it. `1 + 11 = 12` distinct paths, which
  reconciles exactly to the 12-file net union — **no path in this packet nets to
  zero**, unlike P3.
- **`af4ce0c` vs `b9896e0` is separable by ORDER, not by path.** They are the
  same packet's build and its own bounded fix round, in sequence on one branch,
  so for the 6 shared paths the attribution is *"`af4ce0c` wrote it, `b9896e0`
  corrected it"* — recoverable from `git log --follow -p <path>`. **That is a
  weaker guarantee than path-disjointness and is stated as such**, because the
  temptation to copy a previous packet's *"intersection empty"* sentence to
  satisfy the guard's grep would be **false for 6 of these paths**, and a
  manifest that lies about disjointness is worse than the missing manifest the
  guard was built to catch.

**Why this section exists at all.** P2's close shipped **red** —
`check-adoption.sh` exit 2 `UNATTRIBUTED`, live suite **1769/2** — because a
multi-commit row carried no manifest. That is not repeated here.

---

# QA proof

**qa: GREEN. reviewer: fix-then-pass → PASS-AS-FIXED, all items fixed and
orchestrator-verified.** All close gates re-run by the archivist **AFTER** its own
writes, **SEQUENTIALLY, each alone, each preceded by an anchored
`pgrep -fa '^bash tests/'` returning empty, each redirected to a file and read in
full — never piped through `tail`.**

| gate | result |
|---|---|
| `bash tests/build_os_tests.sh` | **1909 passed / 0 failed**, exit **0**, zero `^  FAIL` lines (solo run, full capture) |
| red-driven proof | **87 / 6** with **only the tool reverted** |
| `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` | **MATCH at 1909** — `CHANGELOG.md` carries the unsplit literal `**1909 passed**` |
| `./build-os/maintenance/run-tests.sh` | **144 / 144** |
| `bash build-os/registry/scan-controls.sh check` | exit **0** — **99** controls vs 44 refusal-capable surfaces, 82 load_bearing, 20 over-authorised (declared), 0 unregistered, 0 phantom, 20 report rows reconciled |
| `bash build-os/registry/scan-mutators.sh check` | exit **0** — 8 mutators, 12 defect classes, 3 findings, 35 stable ids |
| `bash build-os/tools/evidence-policy.sh check` | exit **0** — **25 of 99**, split **6 / 5 / 14** |
| `bash build-os/metrics/rank-candidates.sh rank --decision-id DECISION-0010-…` | exit **0**, digest reproduced, **all three read stores byte-identical before and after** |
| `bash build-os/metrics/check-adoption.sh` | exit **0** — row recorded **and** the manifest above found |
| `git status --porcelain` | **empty** at HEAD before the close; the close's own writes are the only diff |

**Why the sequencing discipline is not ceremony.** The suite is **not
concurrency-safe**: two overlapping runs return **N−1 / 1** rather than refusing.
Observed twice already (**1688/1**, residue `(aaa)`; and **1770/1**). A concurrent
run produces a number that belongs to **no commit**, and if its output is piped
through `tail` the failing assertion's identity is **lost**. Every gate above was
run alone, from a file.

**Commit-1 isolation.** `9742a10` is the declaration **alone** — one markdown
file, read by no code path — and it was measured **green in isolation at 1869 / 0
in a fresh clone**. It is untouched and still an ancestor of `b9896e0`.

**Zero re-authorisations**, field-anchored across all **99** controls rather than
diff-eyeballed. **Out-of-licence: 25.** **Declared mismatches: 20.** **Census:
99.**

---

# Final state at `b9896e0` (re-derived by the archivist at close)

- **99 controls** (97 → 99, **+2**, the split forced by the fixture in §7 above);
  **77 gate / 15 advise / 6 execute / 0 rank / 1 observe / 0 none**;
  **class A 74 / B 3 / C 22**; **20 declared mismatches**, unchanged in count.
- **`observe` HAS ITS FIRST OCCUPANT.** The rung has been empty since it was
  redefined by consequence at `gravito_ladder_semantics_a`, and residue recorded
  it as *"spellable and still UNTAKEN"*. `ranker.s1_shadow_ordering` takes it —
  **not by re-authorising anything, but by being the first control born there.**
- `evidence-policy.sh check` **25 of 99**, split **6 / 5 / 14**; deployment axis
  binds **0** from **0** live authority envelopes.
- **10 decisions; 72 frozen signal snapshots** (44 → 72, **+28**, all 28 bound to
  `DECISION-0010`); 1 mismatch disposition; 3 claim-scoped assertions; 8 mutator
  records; 12 defect classes; 3 findings.
- Suite **1909 / 0**; maintenance **144 / 144**; tree clean.
- **Exactly one file added in the whole range**, `build-os/metrics/rank-candidates.sh`.

---

# TWO ARCHIVIST FINDINGS AT THIS CLOSE

**Recorded for the same reason the packet's own self-caught defects are.**

## A. THE SIGNAL-SNAPSHOT COUNT HAS BEEN REPORTED AS THE FILE'S LINE COUNT FOR TWO CONSECUTIVE CLOSES, AND IT NEARLY DOUBLED THE FIGURE

Measured at this close, directly:

| commit | `grep -c '^SIGNAL-SNAPSHOT-'` — **actual** | what the close of that packet recorded | total lines in the file |
|---|---|---|---|
| `a75c25e` (P1 close) | **12** | *"12 signal snapshots"* — **CORRECT** | 56 |
| `c653508` (P2 close) | **28** | *"71 snapshot rows"* | 72 |
| `ead24bc` (P3 close) | **44** | *"87 signal snapshots"* | 88 |
| `b9896e0` (this close) | **72** | **72** | 116 |

The file carries **43 comment lines and 1 column header**. **P1's close counted
correctly.** P2's and P3's figures are **(total lines − 1)** — they counted the
store's own explanatory header as snapshot data. **The derivation changed between
P1 and P2 and nothing noticed**, which is the whole shape of the defect: a count
restated by hand from a different derivation each time, with no check that any two
of them agree. At P3 the reported figure was **87 against an actual 44: an
overstatement of very nearly 2×**, in a store whose entire purpose is that a
later evaluation can trust what it says.

**This is `DEFECT-0003-duplicate-semantic-truth` in its counting form** — the
exact half of that defect P3 mechanised for citations and **left to hand for
counts**, which is why `PACKET-0027-p3b-count-derivation` exists and why S1 ranked
it first. **The sealed receipts are NOT rewritten** — receipts are append-only
history. `current_state.md` is corrected at this close and the finding is recorded
as residue.

**Note the direction it points.** `PACKET-0027` is the candidate S1 placed at
rank 1, and this finding is a fresh, independent instance of the defect class that
candidate exists to close — found by an agent that was not ranking anything. It
does **not** rescue §1 (the ordering is still degenerate for the reasons given),
but it is evidence about the candidate rather than about the ranker.

## B. THE CLOSE BRIEF'S ONE CITATION WAS OFF, AND IT IS RECORDED RATHER THAN COPIED

The brief attributed the *"uninformative at n=1"* sentence to line **412** of
`rank-candidates.sh`. At HEAD, line 412 is inside the **Pareto domination loop**;
the sentence is emitted by the tool's `note:` line, **115 lines further down** in
a 544-line file. **The quotation is true and the pointer is not.** It is recorded
here **by content**, never by number — which is residue `(mm)`'s whole ruling, and
the reason `PACKET-0029` (anchor tokens instead of line numbers) is ranked 2 in
the ordering above.

**This is the sixth time in this sequence a figure relayed by an orchestrator or a
reviewer has been corrected downstream, and the second one caught by the
archivist.**

---

# Residue — what is deferred, and why

**Recorded by the builder during the packet:**

- **`(www)`** — corrected in the fix round: *"cannot be replayed"* was true of the
  **tool** and false of the **rule**, and the original wording overstated the
  closure. Carries the out-of-sample replay and both its caveats.
- **`(xxx)`** — the degeneracy, the 125/125 weight sweep, and the
  lettering-granularity artefact.
- **`(yyy)`** — signal non-independence **and** the label leakage.
- **`(zzz)`** — guard 1's evidence-substrate blind spot, **plus** the
  directory-prefix alias left deliberately open.

**Added by the archivist at this close:** the snapshot-count derivation defect
(§A above) and the brief's mis-pointed citation (§B above).

**DO NOT FIX THE SIGNAL SET HERE. `s1-v2` IS A LATER PACKET.** The operator's
ceiling reasoning applies to S1's own shortcomings as much as to governance
defects. Nothing in §§1–4 of the findings is repaired by this close, and none of
it should be repaired by a fix round.

**Standing items untouched by this packet and still open:** `(ee)` the
declare-before-building vs ≤2-commit tension; `(mm)` resolvability-not-identity
for single-position citations; `(nn)` the mutation-census coverage gap;
`(ooo)`/`(vvv)` the `current_state.md` ↔ `CHANGELOG.md` structural deadlock — **it
closed again this packet only because the BUILDER wrote both halves in one
commit**, which is the fifth packet to route around it by hand; `(sss)` the
ceiling/anti-shelfware interaction; `(zz)` the second-eyes streak, **now ten**.

---

# Open boundaries — nothing done without go

- **NOT pushed. Three commits — `9742a10`, `af4ce0c`, `b9896e0` — plus this
  close's commit are deliberately unpushed and stay that way.** Everything
  through `ce71122` is already on the remote; nothing in this packet is. No
  `git push` was run at any point in this packet or this close.
- **NOT merged.** No merge, no PR, no rebase onto any other branch.
- **No tag, no deploy, no publish, no secrets, no `git config`.**
- `/home/user/empathiq-website` **not touched**.
- **Nothing consumes the ordering, and wiring anything to it is an operator
  act.** S1 holds `runtime_authority: observe`; promoting it above that is a
  governance action nobody has performed, and its own `promotion_requirement`
  turns on `rank_of_selected` history that does not yet exist at any useful n.
- **`PACKET-0027-p3b-count-derivation` — the selected candidate, ranked 1 — is
  still NOT STARTED.** It awaits an explicit go like any other packet, and §A
  above is one more open instance of the defect class it would close.
- **The open residue items are NOT fixed by this close**, by instruction and by
  the ceiling reasoning.

---

# Files written by this close — all inside `build-os/`

| file | change |
|---|---|
| `build-os/receipts/gravito_p4_s1_shadow_ranker_a.md` | **new** — this receipt |
| `build-os/memory/current_state.md` | advanced: last-closed packet, census 97 → **99**, snapshot count **corrected 87 → 72-actual with its derivation**, suite total confirmed at **1909** |
| `build-os/memory/residue.md` | appended the archivist's two close findings; `(zz)` streak advanced **nine → ten** |
| `build-os/packets/active_packet.md` | `gravito_p4_s1_shadow_ranker_a` marked **CLOSED**; `gravito_p3b_count_derivation_a` staged next as the ranked-1 selected candidate |
| `build-os/metrics/packet_metrics.tsv` | one appended row via `record-packet.sh`, carrying the guard's measurement convention, **written together with the manifest above** |

**No file outside `build-os/` was written by this close.**
