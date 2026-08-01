# gravito_mismatch_refuted_a — authorised to re-authorise two controls, it changed NOTHING, because the prescribed demotion was MEASURED to destroy live memory

- **Date:** 2026-08-01
- **Lane:** `substantive` (builder → qa ‖ reviewer → fix → re-review → fix → tiny-lane close → archivist)
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `c52915f` (the close of `gravito_authority_envelope_a`); re-verified at close —
  `git merge-base 566443f c52915f` = `c52915f`.
- **Final HEAD (packet):** `566443f`
- **Verdict:** **pass as fixed** — reviewer `fix-then-pass` **twice** (3 items / 5 sites,
  then 2 items / 3 sites), qa **GREEN**. All fix rounds landed and were re-verified.

---

# THE HEADLINE — THE PACKET WAS AUTHORISED TO DEMOTE AND REFUSED, ON MEASUREMENT

This is the first packet in the sequence permitted to **re-authorise** a control.
The operator's step-3 ruling named `maint.tripwire_coverage_scan` as the first
case. The reviewer had, one packet earlier, called it **"the strongest demotion
candidate in the census"**. The control's own `demotion_requirement` **literally
prescribed its own demotion**: *"collect the findings and print them instead of
throwing."*

**The builder applied that demotion and measured it.** Two arms, differing by
exactly one line, run against an uncovered suite file that rewrites real memory:

| arm | scan | exit | real tree |
|---|---|---|---|
| **GATED** (shipped) | throws | **1** | **untouched** — sha256-identical |
| **DEMOTED** (the prescription) | prints | **1** | `build-os/memory/residue.md` **truncated 1621 B → 8 B, contents replaced with `DAMAGED\n`** |

**THE EXIT CODE IS 1 IN BOTH ARMS.** Every automated check watching exit codes
would have reported the prescribed demotion **harmless**. Only inspecting the
tree reveals that one arm prevents the destruction and the other merely narrates
it after the fact.

That gate is the maintenance layer's **only prevention**. `maint.real_memory_tripwire`
and `maint.shell_fingerprint` are **detection**, and both declare
`rollback_behavior: NONE`. So **retirement is worse than demotion**, and both
outcomes are closed — not deferred, closed, with the measurement attached.

**Result: the packet re-authorised nothing, and that is the correct outcome, not
a failure to act.** `evidence-policy.sh check` still reports **19 of 81, split
6/5/8 — UNMOVED**, which is exactly what a packet that re-authorised nothing must
produce.

---

## What was built

**`COVERAGE-GATE-PREVENTION-DIFFERENTIAL`** — `tests/build_os_maintenance_tests.sh`
§6a (`:338`). The two-arm differential above, red-driven, **clean arm first**.
Its assertion is a conjunction of three facts (`AG != 0 && AD != 0 && trees
differ`), so a suite that stopped noticing the destruction cannot pass by having
both arms merely fail.

**The `OBSERVE-LB` guard** — `build-os/registry/scan-controls.sh:320-321`. It
refuses `implementation_status: load_bearing` at `runtime_authority: observe`
while a consuming policy is named. Its own refusal text carries the reasoning:

> `OBSERVE-LB $id claims load_bearing at authority "observe" while naming a consuming policy … "observe" means it measures and records and NOTHING READS THE RESULT; load_bearing means a live policy consumes it and removing it changes outcomes. This fires where an evidence cap is applied as an instruction: a "refuted" control is capped at observe, but a capped control that still has consumers cannot be lowered onto that rung by editing its row — the cap is a finding about the control, not a spelling for it.`

**Registry prose only.** The two controls' `demotion_requirement` and `notes`
fields were rewritten to carry the measurement and the four closed outcomes.
**Zero governance-field diff lines** across the whole packet — verified at close:
`git diff c52915f 566443f -- control_registry.txt` yields **0** added or removed
lines on `class:`, `runtime_authority:`, `authority_mismatch:`,
`empirical_status:`, `implementation_status:`. Everything else in that file is
`evidence_refs` re-pointing at lines the packet's own inserts moved.

---

## `maint.source_scan_mask` — ALL FOUR OUTCOMES CLOSED, EACH WITH ITS OWN REASON

The second control carries **no declared mismatch** (Class C licenses `advise`),
so the class axis is structurally blind to it. It is one of the **5 findings only
the evidence axis can see**.

| Outcome | Status | Reason |
|---|---|---|
| **1. Demote authority** | **CLOSED** | Writes a **falsehood**. README §2 defines `observe` as *"it measures and records. Nothing reads the result."* **Two controls read this one's result** — verified at **import sites AND call sites**. Demoting would not lower authority; it would assert something untrue about consumption. `OBSERVE-LB` now refuses it mechanically. |
| **2. Correct the class** | **CLOSED** | The class is **not wrong**. A defeatable lexer really is a heuristic; Class C is the right label. |
| **3. Improve the evidence** | **CLOSED** | Forbidden by **its own `promotion_requirement`**: *"it must not be promoted; it has been defeated three times and the maintainers stopped writing new mask heuristics deliberately."* |
| **4. Retire** | **CLOSED** | Breaks **both** consumers — `maint.tripwire_coverage_scan` and `rotate-memory.rootscan.test.mjs`. |

**So the finding is REAL and its prescribed remedy is UNREACHABLE.** The control
stays at `advise` and stays out of licence on the evidence axis. Nothing here
re-authorises it.

### The reviewer's correction the builder accepted — and why it matters commercially

The packet initially recorded `source_scan_mask` as **a second demonstration of
the `outputSemantics` split**. The reviewer refused that, with a decisive test:

> **`outputSemantics` would not fix it.** `observe` would still mean "nothing
> reads the result"; two controls would still read this one's; the mask still
> could not sit there. The collision is between **`runtime_authority`'s
> consumption clause** and **`implementation_status`** — a redundancy between
> **two fields that BOTH ALREADY EXIST** — not a missing third concept.

**This matters because the operator committed to `outputSemantics` for S1 on a
different case.** Counting this control as a second data point would have
**inflated confidence behind that design using a case that does not test it.**
The correction is recorded in the registry entry itself, in capitals, so a future
reader cannot re-derive the wrong count.

---

## THE SECOND-ROUND FINDING — the sharpest self-catch in the sequence

The packet had written down, **in two places**, that the `observe`-rung
foreclosure is fixed by *"deleting the consumption clause from README §2's ladder
definitions, a one-line edit."*

**Both halves were false.**

1. **It is not one site — consumption is asserted in SIX places.** README §2's
   **two bottom rungs** (`none` = "nothing consumes it" and `observe` = "Nothing
   reads the result" — **both** are consumption clauses), README §3b's `shadow`
   row, `authority_envelopes.txt`'s header, and **both tools' headers**.
2. **And decisively: the foreclosure is enforced by CODE, not prose.**
   `scan-controls.sh`'s `OBSERVE-LB` keys on `[ "$aut" = "observe" ]` and
   **hard-codes the semantics in its own refusal message**. Deleting every line
   of README prose leaves it refusing at **exit 2**, and the demotion still
   unwritable for all 67 `load_bearing` controls.

**A future packet could have executed that prescription faithfully and achieved
nothing.** The reviewer's framing, kept because it names the failure this
registry exists to catch:

> `MISMATCHES.md` says it about itself — *"a wrong exclusion gets caught by
> re-running the rule, and a wrong reason is what the rule is re-run against."*
> **Nothing re-runs a reason.**

**A remedy its own guard survives is not a remedy.** That edit is **not made
here** and belongs to its own packet, with its true radius named.

---

## The reviewer withdrew its own prior ruling — record it verbatim

The reviewer had previously reasoned from the `refuted` token. On this packet it
retracted that, on the record:

> *"I reasoned from the token `refuted` rather than the evidence the token points
> at… Reasoning from a label instead of its referent is precisely the failure this
> registry exists to catch."*

**A reviewer correcting itself on the record is the behaviour the system is
supposed to produce**, and it is recorded here as such rather than as a defect.

Two related corrections landed in the registry from the same analysis:

- **The refutation is PATH-SCOPED, and one unqualified token cannot say so.**
  `refuted` records that the **detection** claim failed on the bare `node --test`
  path. On the **sanctioned** path the same scan is measured **prevention**.
  Read unscoped, `refuted` caps it at `observe` and makes it the census's most
  obvious demotion candidate — *a reading the measurement refuses.*
- **EVADABILITY IS NOT NON-DISCRIMINATION.** The defect this control exists
  against was an **accident** — a suite file that carried no tripwire and
  destroyed live memory at exit 0 — and against that it discriminates exactly.

**Keeping the gate is not a claim to be in licence.** The control stays at `gate`
and its mismatch stays **declared**. No exception was written to pretend
otherwise.

---

## QA proof — GREEN

**qa reproduced the central finding FROM SCRATCH rather than running the
builder's test.** That is the strongest single thing in the packet's proof and it
is recorded as method, not as a result:

- **Three independent fresh repos.**
- **qa's own `node:test` fixture**, with **static imports and a real `test()`
  block** — a **stronger shape** than the shipped fixture's top-level
  `await import()`. So the finding is **not an artefact of fixture shape**.
- The two arms were verified by **`diff -r`** to differ by **exactly one line**:
  `throw new Error(` → `console.error(`.
- **Negative control**: with **no** fixture, **exit 0 and the tree untouched** —
  so the refusal is caused by the fixture, **not by a pre-existing failure**.

| Check | Result |
|---|---|
| `evidence_refs` | **287, all content-verified, ZERO drift** |
| Census re-derivation | **re-derived independently from README §3** — same **19 of 81**, same split **6 / 5 / 8** |
| `OBSERVE-LB` | **driven red by name**; **0 of 81 live entries** are able to trip it |
| `source_scan_mask` consumers | **both verified at IMPORT sites AND CALL sites** |
| Commit-1 isolation | **green at `b25f3f7`** |
| Safety grep | **22 patterns, all firing on planted controls** (non-blind, proven) |
| Destruction confinement | **audited AND empirically proven** — real `build-os/memory/*` byte-identical after **three full-suite runs** |
| UI smoke | **N/A** — no UI surface |

### qa caught a trap in its OWN work — and that is why 1592 is not a number from this packet

A **first** Commit-1 isolation run reported **1592**. qa traced it: a **stale
clone directory made `git checkout` fail silently**, so the run measured the wrong
tree. **qa discarded that run and redid it.** Recorded explicitly because the
number is otherwise loose in the transcript:

> **1592 is NOT a number from this packet.** It is the count from a tree that was
> never checked out.

---

## Fix rounds

- **Round 1 — reviewer `fix-then-pass`: 3 items across 5 sites.**
- **Round 2 — reviewer `fix-then-pass`: 2 items across 3 sites**, closed by the
  orchestrator in the **`tiny`** lane.

### DEPTH: FOUR SERIAL STAGES — and the reviewer's own accounting

`CLAUDE.md` classifies a fourth serial stage as a **defect**. This packet ran to
four. The reviewer's accounting, recorded in full because it is more precise than
the rule it is being measured against:

**It was NOT a withheld installment.** Both second-round items concerned text
that **did not exist at stage-2 review**:

- **Item A** was the **item-2 replacement itself** — the text written *by* the
  first fix round.
- **Item B** was a collision the **ALSO-RECORD note created by landing**.

A reviewer cannot enumerate text that a later stage will write.

**But the reviewer named the honest reading anyway:** item 2 was cut as *"replace
a false claim"* when it was really *"replace a false claim **and state the correct
radius**"*. That is **the same incomplete-application shape** as
`gravito_authority_envelope_a` — a fix scoped to the definition without scoping to
its consequences. **Two packets running.**

### Codex second-eyes: NOT fulfilled, on either pass

`build-os/memory/tool_router.md:368` routes reviewer second-eyes to Codex
(`codex` CLI / Codex-for-Claude-Code plugin). **`codex` is not on PATH and no
Codex plugin is installed.** The row went unfulfilled in the **review** and in
**both re-reviews**.

**Both verdicts in this packet are single-model.** The row is **unbacked** —
declared and undelivered on every packet that has ever invoked it. **Either
install Codex or stop declaring the row.**

---

# THREE OPERATOR DECISIONS — the packet's real output

## 1. A FIFTH OUTCOME IS MISSING FROM THE OPERATOR'S FRAMEWORK

The framework offers **demote / correct class / improve evidence / retire**. But
**demotion onto the rung the `refuted` cap prescribes is UNSPELLABLE for 67 of 81
controls (83%)** — every `load_bearing` control — and **0 controls sit at
`observe` today**.

**The reviewer's proposal: ACCEPT AND CONSTRAIN.** Leave the authority where it
is, **keep the finding standing**, and require an **operator envelope**.
`build-os/registry/authority_envelopes.txt` exists with **0 live grants**, which
is exactly what it was built for.

**Not adopted here.** It is an operator decision.

## 2. THE LADDER HAS A DEFINITIONAL BUG, AND FIXING IT IS NOT ONE LINE

- `none` = *"nothing consumes it"*
- `observe` = *"it measures and records. Nothing reads the result"*

**Both bottom rungs are defined by non-consumption.** There is **no rung meaning
"it is read, but may cause nothing"** — which is precisely the state a
refuted-but-wired-in control should occupy.

**The fix touches six prose sites AND `scan-controls.sh`'s `OBSERVE-LB`, which is
the part that actually binds.** Do not cut a one-line packet for this.

## 3. `OBSERVE-LB` MAY BE CORRECTLY REASONED BUT MIS-PLACED IN AUTHORITY

It sits on the **gating** path (`scan-controls.sh`, **exit 2**) while the axis it
defends deliberately only **advises** (`evidence-policy.sh`, **exit 0**).

The advisory axis was designed so that **nothing gets demoted automatically with
no operator in the loop**. This guard removes the operator's ability to apply the
demotion **by hand** as well.

**The reviewer declined to demand a move.** It is a design call, and it is
recorded as open.

---

# DO NOT EXTRAPOLATE FROM THIS PACKET TO THE REMAINING TWELVE

These two controls were selected **precisely because `refuted` made action look
settled**, which makes them **the least representative pair in the census**.

**Of the 19 findings, 11 are `unvalidated`** — *nobody measured*. For those the
remedy is **outcome 3, improve the evidence**, and that outcome is **wide open**.
It was closed here **only** because `source_scan_mask`'s own
`promotion_requirement` explicitly forbade it. That is a property of one control,
not of the class.

---

## Scope

**In:**

- `build-os/registry/control_registry.txt` — `demotion_requirement` + `notes` on
  `maint.tripwire_coverage_scan` and `maint.source_scan_mask`; `evidence_refs`
  re-pointed on three entries whose cited lines this packet's inserts moved.
- `build-os/registry/scan-controls.sh` — the `OBSERVE-LB` guard (+2 lines).
- `build-os/registry/MISMATCHES.md` — the measurement, the four closed outcomes,
  the two-round corrections.
- `tests/build_os_maintenance_tests.sh` — §6a
  `COVERAGE-GATE-PREVENTION-DIFFERENTIAL`.
- `tests/evidence_policy_tests.sh` — the `OBSERVE-LB` and closed-outcome
  assertions.
- `build-os/packets/active_packet.md` — the declaration.
- `CHANGELOG.md`.

**Explicitly out — ruled out, not deferred:**

- **Demoting `maint.tripwire_coverage_scan`** — applied, **measured**, and
  **refused** on the measurement. Not deferred: closed.
- **Retiring it** — worse than demotion; the two detection controls declare
  `rollback_behavior: NONE`.
- **Any change to `maint.source_scan_mask`'s authority or class** — all four
  outcomes closed, each with its own reason.
- **The ladder definitional fix** (six prose sites + `OBSERVE-LB`) — its own
  packet, radius now named.
- **The other 13 declared mismatches, the 4 Class-A-gate-on-`unvalidated`
  findings, and the `untested` token** — out of the declared scope from the start.
- `/home/user/empathiq-website` — untouched, preserved at `cb2bb7d`.

## Commits

- `b25f3f7` feat(registry): measure the two refuted controls' demotions, and refuse both — 6 files, +387 / −147
- `566443f` docs(changelog): record two refuted controls, two refused demotions, one guard — 3 files, +118 / −5

**Two commits, at the cap.** `b25f3f7` is **byte-identical through every fix
round** and **is still an ancestor** of `566443f` (`git merge-base --is-ancestor`
→ yes), so qa's Commit-1-green-in-isolation proof survived intact and was never
re-spent. Commit 2 absorbed both fix rounds and the tiny-lane close by amendment.

Per-commit numstat union (the figure `record-packet.sh --verify-git` checks):
**7 files, +505 / −152**.

### File-ownership manifest (attribution by path)

Recorded because the metrics row names **two** commits
(`build-os/metrics/check-adoption.sh:519`).

**Owned solely by `b25f3f7` (commit 1 — the build):**

| Path | +/− |
|---|---|
| `build-os/packets/active_packet.md` | +238 / −? (net rewrite of the declaration) |
| `build-os/registry/scan-controls.sh` | +2 / −0 |
| `tests/build_os_maintenance_tests.sh` | +60 / −0 |
| `tests/evidence_policy_tests.sh` | +150 / −0 |

**Owned solely by `566443f` (commit 2 — the record and both fix rounds):**

| Path | +/− |
|---|---|
| `CHANGELOG.md` | +49 / −0 |

**Touched by BOTH commits — attribution here is by commit, not by path:**

| Path | `b25f3f7` | `566443f` |
|---|---|---|
| `build-os/registry/MISMATCHES.md` | +70 / −? | +72 / −? |
| `build-os/registry/control_registry.txt` | +14 / −? | +2 / −1 |

**Not disjoint, and saying so is the point.** No fan-out was run — a single
builder — so disjointness was never a safety property here. The manifest exists
so a later reader can attribute any line to the commit that wrote it.

**Note the shape:** the **second-round correction** (the "one-line edit" claim,
falsified twice over) lives in the **commit-2 half** of both
`MISMATCHES.md` and `control_registry.txt`, while the claim it corrects was
written in the **commit-1 half**. Without this table that attribution is
unrecoverable.

---

## Final state at `566443f`

Re-derived by the archivist directly from the registry files, not copied from the
packet:

| Quantity | Value |
|---|---|
| Suite | **1617 passed / 0 failed**, exit 0 |
| `./build-os/maintenance/run-tests.sh` | **144 / 144**, 0 fail |
| `tests/evidence_policy_tests.sh` standalone | **102 / 0** (was 88) |
| `tests/build_os_maintenance_tests.sh` standalone | **67 / 0** (was 61) |
| `scan-controls.sh check` | **exit 0** — 81 controls / 36 surfaces; 67 load_bearing, 14 over-authorised (declared), 0 unregistered, 0 phantom, 14 rows reconciled |
| `evidence-policy.sh check` | **exit 0** — **19 of 81, split 6 / 5 / 8 — UNMOVED** |
| Governance-field diff vs `c52915f` | **ZERO lines** |
| Declared mismatches | **14** declared / 67 none |
| Controls | **81** |
| `load_bearing` | **67** |
| Authorities | **68 `gate` / 13 `advise`** — **no `observe`, `none` or `rank` rows exist at all** |
| Class | **A 58 / B 3 / C 20** |
| `evidence_refs` | **287**, all resolving, zero drift |
| `empirical_status` | 56 `red_driven`, 18 `unvalidated`, 2 `red_driven,field_observed`, 1 each `calibrated`, `calibrated,red_driven`, `field_observed`, `red_driven,refuted`, `refuted` |
| Live authority envelopes | **0** |
| Tree | **clean** |

**The finding did not move, and that is the correct result.** A packet authorised
to re-authorise and which re-authorised nothing must leave the census exactly
where it found it. It did — proven, not assumed.

**The ladder is still used at two rungs of five.** `rank` and `observe` remain
**0 of 81**. This packet added a *guard on* the `observe` rung without adding an
occupant to it.

---

# Residue — what this close found

## 1. Prose citations have TWO known escape forms, and the sweep exists only as a throwaway

The known form is a **bare `:NNN` reference**. The second is
**`MISMATCHES.md` §10's nonvacuity-table row form, which names a file with NO
line number at all.** **The builder's own first sweep pass mis-resolved that
table and had to be redone.** A working sweep was written and **exists only as a
throwaway script** — it is not in the tree and nothing re-runs it. Filed as
residue **(aa)**.

## 2. The `MISMATCHES.md` six-packet stale-ref streak ENDED

qa confirmed the `:960` reference was **corrected in `a7ab841`**, and this packet
**inherits a correct citation**. Residue item **(s)** is updated rather than
re-asserted. The *class* (item **m**) is still unguarded; this instance is closed.

## 3. The flake recurred conceptually and its diagnosability blocker is unchanged

`tests/release_metadata_tests.sh` writes the live log into an `mktemp -d` that is
**cleaned on exit** and reports **only parsed counts**, so **a live cross-check
failure destroys its own evidence.** Cheap fix (echo the `FAIL:` lines from
`$LIVE_LOG` on the failure branch); **still not chased.** Residue **(o)**,
carried.

## 4. The three operator decisions

See above. Filed as residue **(bb)**, **(cc)**, **(dd)**.

## 5. The declare-before-building tension — OPERATOR DECISION, DELIBERATELY NOT RESOLVED

**This packet DID declare itself before building** — unlike the previous one,
which was built entirely under "NO PACKET IN FLIGHT" (residue **(u)**).

**But the reviewer observed that the declaration landed in the SAME COMMIT as the
build** (`b25f3f7` touches `build-os/packets/active_packet.md` alongside the
guard and the tests), **so git cannot attest the ordering.** The claim is true;
git just cannot corroborate it.

**The `≤2-commit` rule and "declare before building" are in genuine tension.**
Attesting the ordering needs **a third commit or a pre-commit hook**. **That is an
operator decision and this close does not resolve it.**

## 6. Carried forward, unchanged

- **The S1 decisions** — the evidence-token choice, the `runtimeAuthority: observe`
  recommendation (advice, not adopted), and which S1 reading the ladder adopts.
- **`swarm-merge.sh` disjointness FALSE NEGATIVES.**
- **`tests/entitlement_tests.sh:296-305`'s hardcoded 12-file `PACKET_FILES` list.**
- **`RELEASE_METADATA_LIVE_SUITE=1` still opt-in and still not chained.**
- **`authority-envelope.sh`'s `--help` hand-maintained `sed` range** (residue **t**).
- **Nothing machine-checks prose that restates a machine-computed table**
  (residue **m**) — five packets running.
- **`CHANGELOG.md` line-citation decay** (residue **r**).
- **Assert a declared packet EXISTS while one is in flight** (residue **c**/**u**)
  — still unbuilt.
- **§5b non-vacuity floor alignment** (residue **v**) — **non-blocking, reviewer
  explicitly passed it. Do not treat as open.**

---

## Open boundaries — nothing done without go

- **Nothing pushed, merged, tagged, PR'd or deployed by this close. Local commit
  only.**
- **No secrets touched. No `git config`.**
- `/home/user/empathiq-website` untouched, preserved at `cb2bb7d`.
- **`b25f3f7` and `566443f` are local-only** and remain so pending explicit go.
- **The three operator decisions above are NOT taken.**
- **Re-authorising or demoting any of the 19 out-of-licence controls remains a
  governance action.** This packet was authorised for two of them and,
  **on measurement, performed neither.**
- **Writing the first authority envelope remains an operator act.** The store
  still holds **0 live grants**.

## Verification performed by this close

Re-measured by the archivist on a quiet tree, after every memory write:

| Check | Result |
|---|---|
| `bash tests/build_os_tests.sh` | **1617 passed / 0 failed**, exit 0 |
| `bash build-os/registry/scan-controls.sh check` | **exit 0** — 81 controls / 36 surfaces |
| `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` | **MATCH** (reported in the close hand-back) |
| `git status --porcelain` | **empty** after the close commit |

**The metrics row's `defects_escaped` is `-`, and that is load-bearing.** The
column means **what a post-close audit finds**, and **no post-close audit has
run**. Everything caught at this packet's gates escaped the **gates**, not the
**packet**. `rounds` and `agents` come from the orchestrator's handoff trail and
are marked **NOT WITNESSED BY THE RECORDER**; `wall_min` and `serial_min` are
`-`, because nobody held a clock.

## Files written by this close — all inside `build-os/`

- `build-os/receipts/gravito_mismatch_refuted_a.md` *(new — this file)*
- `build-os/memory/current_state.md`
- `build-os/memory/residue.md`
- `build-os/packets/active_packet.md`
- `build-os/metrics/packet_metrics.tsv`

**Nothing outside `build-os/` was written by this close.**

## The close is a THIRD commit, and that is deliberate

The packet is at its **2-commit cap** (`b25f3f7`, `566443f`) and **neither was
amended by this close**. This close is a separate archivist commit on top,
matching the convention of prior closes (`c52915f`, `77a0040`, `12dbdc5`).
**Nothing pushed, merged, tagged, PR'd or deployed. No guard was weakened,
deleted or exempted. No control was re-authorised. No file outside `build-os/`
was written.**
