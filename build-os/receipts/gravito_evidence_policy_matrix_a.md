# gravito_evidence_policy_matrix_a — give the licence table an evidence axis, and let it only advise

- **Date:** 2026-07-31
- **Lane:** `substantive` (builder → qa ‖ reviewer → fix → re-review → tiny-lane sweep → archivist)
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `6b01173`; verified before building (`git merge-base HEAD 6b01173` = `6b01173`) and re-verified at close.
- **Final HEAD (packet):** `0555717`
- **Verdict:** **pass as fixed** — reviewer `fix-then-pass` twice, qa RED (documentation-only) once, all fix rounds landed and re-verified.

README §3 licensed runtime authority on **class alone**. A control's
`empirical_status` — whether anybody ever established that the check *works* —
licensed nothing and forbade nothing, so a control **measured and found not to
discriminate** could stop a build with no rule objecting. This packet adds the
second axis and composes the two.

## What landed

**README §3a — the evidence axis.** `class × empirical_status → licensed
authority`, composed as **`licensed = MIN(class-licensed, evidence-licensed)`**:
a control may do what *both* axes allow. §3a extends §3; it does not replace it.

| Rule | Cap | Why |
|---|---|---|
| **The sharp rule** — `refuted` | `observe`, **at every class** | Class is a claim about the KIND of thing checked; evidence is a claim about whether the check WORKS. A hard invariant whose test does not detect violations is an *unchecked* invariant, not a well-classified one, so **class cannot rescue it**. `observe` rather than `advise` because showing a signal *known* to be dead to a decision-maker who cannot see that is worse than recording it and letting nothing read it. |
| **The expensive rule** — `unvalidated` | `advise` | Not `rank`: `rank` orders work with **no human in the loop**. An unverified signal silently choosing what happens next differs from one stopping a build only in how loudly it fails. This is the rule that costs, and the count is the finding, not a reason to soften it. |
| `red_driven` | **deliberately uncapped** | See "the limit stated out loud", below. |

**`build-os/tools/evidence-policy.sh`** (new) — `matrix` prints the model,
`check` **derives** the out-of-licence set from the registry. **No control id
appears in its source**; the derivation is not a stored list, and a test asserts
that.

**Three entries registered**, census **75 → 78**:
`evidence.policy_matrix` (C, `advise`, mismatch `none`),
`evidence.derivation_nonvacuity` (A, `gate`), `suite.evidence_policy` (A, `gate`).

**`tests/evidence_policy_tests.sh`** (new, 67 assertions), chained from
`tests/build_os_tests.sh`. §5a — added in the fix round — reconciles README §3a's
evidence **cap** table against the tool's `EVIDENCE_AXIS` in **both** directions.

### The limit of the `red_driven` argument is now stated out loud

`red_driven` is uncapped, and the packet says where that argument runs out: it
holds at **Class C**, and **FAILS at Classes A and B**, which carry no fitted
threshold for the class axis to charge — there it rests on the consequentialist
half alone. This is the sentence the reviewer was asked to scrutinise hardest,
and it is where the packet's own worst defect lived (below).

## The finding — derived, not remembered

**19 of 78 out of licence.** Re-derived by the archivist at close:
`bash build-os/tools/evidence-policy.sh check` → 19 OUT-OF-LICENCE lines,
`class axis binds 6, evidence axis binds 5, both axes bind 8`, **exit 0**.

- **14** the class axis already saw — the existing declared mismatches, reproduced exactly.
- **5 the class axis structurally could not see** — four Class-A gates on
  `unvalidated` carrying `authority_mismatch: none` (`maint.tripwire_armed_precondition`,
  `maint.rotate_node_precondition`, `tools.handoff_lock`,
  `tools.capability_profile_usage`), **because the old one-dimensional table
  genuinely licensed them**, plus `maint.source_scan_mask` advising on `refuted`.
- **1** gating on `refuted` (`maint.tripwire_coverage_scan`) whose existing
  declaration understates it.

## It ships at `advise`, and it is PROVABLY advisory

The matrix is chosen policy, not a definition, and a matrix that gated on
"chosen thresholds may not gate" would be self-refuting. Gating would demote 19
controls automatically with no operator in the loop, and the authority envelope
that would make that legitimate is **step 2 and does not exist yet**.

The claim is driven, not asserted: a test runs `check` against the **live**
registry — which violates the matrix — and asserts **both** exit 0 **and a
non-empty finding set**, so the zero is not vacuous silence.

**It re-authorises nothing.** No existing control's `class`,
`runtime_authority`, `authority_mismatch` or `empirical_status` changed.

---

# HEADLINE FOR THE OPERATOR — the S1 collision blocks step 2

**S1 is slated to arrive at `runtimeAuthority: rank` with
`empiricalStatus: untested`. Both halves collide with what shipped here.**

1. **S1 at `rank` on `unvalidated` evidence ships out of licence on day one.**
   Survivable — the matrix only advises. It would appear as a 20th finding.
2. **`untested` is not one of the five evidence tokens.** So
   `evidence.derivation_nonvacuity` (Class A, **`gate`**) would **REFUSE THE
   ENTIRE DERIVATION at exit 2** rather than flag S1 — because an unrecognised
   level must never fall through to permissive, which is exactly how a matrix
   stops discriminating while still printing green.

**Verified empirically by the archivist at close**, not taken on report. A single
`empirical_status: red_driven` was rewritten to `untested` in a throwaway clone
of `0555717`:

```
evidence: UNREADABLE metrics.record.schema_invariant — empirical_status token "untested" has no cap on the evidence axis
evidence-policy: REFUSED — 1 stanza(s) ... could not be classified by this matrix
EXIT=2
```

One unrecognised token takes the whole derivation down. The reviewer reproduced
this independently during review; this is a second, separate reproduction.

**The operator must choose one:**

- **(a) add `untested` as a sixth token** with its own cap on the evidence axis; or
- **(b) have S1 arrive carrying `unvalidated`.**

Adding a token *purely to make a planned control fit* is the failure mode the
registry exists to prevent, so (a) is a governance decision and not a mechanical
one. **Neither is taken here.** This was found by a packet that can only advise,
**before S1 was built** — which is the whole argument for the packet.

---

## Scope

**In:** `build-os/registry/README.md` §3/§3a, `build-os/tools/evidence-policy.sh`
(new), `tests/evidence_policy_tests.sh` (new), the one `chain_suite` line in
`tests/build_os_tests.sh`, three registry entries + three crosswalk bindings,
`build-os/registry/CROSSWALK.md`, `MISMATCHES.md`, `CHANGELOG.md`,
`build-os/packets/active_packet.md`.

**Explicitly out — ruled out, not deferred:**

- **Any change to an existing control's authority** (steps 2 and 3). The matrix
  reports; it demotes nothing. Re-authorising is the operator's call.
- **A sixth evidence token for `untested`** — see the headline. Named, not taken.
- **Gating the matrix.** Argued and rejected on the record, not merely skipped.
- `/home/user/empathiq-website` (preserved, untouched, at `cb2bb7d`).

## Commits

- `105cb75` feat(registry): give the licence table an evidence axis, and let it only advise — 8 files, +1098 / −25
- `0555717` docs(changelog): record the evidence axis, and why it may only advise — 9 files, +320 / −62

**Two commits, at the cap.** Commit 2 was **amended three times** (fix round,
re-review defect, tiny-lane class sweep) rather than appended to. `105cb75`
stayed **byte-identical** through all three, so qa's Commit-1-green-in-isolation
proof survived intact and was never re-spent. Verified at close:
`git merge-base --is-ancestor 105cb75 0555717` → yes.

Per-commit numstat union (the figure `record-packet.sh --verify-git` checks):
**10 files, +1418 / −87**.

## File-ownership manifest (attribution by path)

Recorded because the metrics row names **two** commits.
`build-os/metrics/check-adoption.sh:519` requires it: one commit per packet where
the merge allows it, and where it does not, **the file-ownership manifest is what
keeps per-packet attribution recoverable by path.**

**Owned solely by `105cb75` (commit 1 — the build):**

| Path | +/− |
|---|---|
| `build-os/tools/evidence-policy.sh` *(created)* | +324 / −0 |
| `tests/build_os_tests.sh` | +1 / −0 |

**Owned solely by `0555717` (commit 2 — the record and the fix rounds):**

| Path | +/− |
|---|---|
| `CHANGELOG.md` | +111 / −0 |
| `build-os/packets/active_packet.md` | +49 / −29 |

**Touched by BOTH commits — attribution here is by commit, not by path:**

| Path | `105cb75` | `0555717` |
|---|---|---|
| `build-os/registry/CROSSWALK.md` | +9 / −9 | +3 / −3 |
| `build-os/registry/MISMATCHES.md` | +4 / −4 | +1 / −1 |
| `build-os/registry/README.md` | +144 / −3 | +58 / −6 |
| `build-os/registry/control_registry.txt` | +63 / −5 | +7 / −7 |
| `build-os/registry/neurocosmology_crosswalk.txt` | +25 / −4 | +1 / −1 |
| `build-os/tools/evidence-policy.sh` | +324 / −0 | +49 / −15 |
| `tests/evidence_policy_tests.sh` | +528 / −0 | +41 / −0 |

**This set is NOT disjoint, and saying so is the point.** Commit 2 carried three
amend rounds into the same registry files and the same tool commit 1 created.
**No fan-out was run** — a single builder, so disjointness was never a safety
property here; the manifest exists so a later reader can attribute any line to
the commit that wrote it without re-deriving it from the diff.

## QA proof

**qa returned RED at `0555717`** — narrow, and **documentation-only**. Every
measured claim verified exactly. qa did not trust the packet's numbers and did
not trust its guards either.

| Check | Result |
|---|---|
| 19-violation set | **reproduced byte-identically**, independently |
| `evidence.derivation_nonvacuity` is a genuine Class A | **confirmed** — all four refusal states drive; the builder's parser red drive reproduces at **78/78 UNREADABLE, exit 2** |
| Re-authorisation | **zero** — confirmed |
| Registry mutated by a run | **no** — byte-identical after `check` |
| `evidence_refs` resolve | **all 272 resolve** (274 after the fix round) |
| Commit-1 green in isolation | **verified at `105cb75`** |
| Safety grep | **no push / merge / deploy / publish / tag / PR / secret access** in the packet diff |
| UI smoke | **N/A** — no UI surface in this packet |

qa added **3 findings the reviewer missed, one blocking.**

### THE TWO GATES FOUND DIFFERENT THINGS — and the difference has a name

**qa's distinct contribution was mutation testing: it did not inspect the guards,
it broke them.**

| Mutation | Suite response |
|---|---|
| Change README §3's **class** row | **RED** |
| Drop an evidence **level** | **RED** |
| Change an evidence **cap** | **stayed 64/0 and 92/0** — green |

That third row measured a **real hole the reviewer had not seen**: §3a's cap
table was a **new, unreconciled duplicate** of the tool's `EVIDENCE_AXIS`. A
README saying `unvalidated → gate` against a tool capping it at `advise` would
have left every assertion green. **It is the same drift surface that produced the
packet's own "53 of 78" defect**, one layer along. Closed by §5a, which
reconciles the cap table in both directions and is red-driven both ways (a cap
changed to another rung fails the diff; a cap changed to a non-rung fails the row
count).

**Keep the method, not just the finding.** Inspection found the arguments;
mutation found the *unguarded* surface. Neither gate would have found the other's.

**Re-measured by the archivist at close, on a quiet tree at `0555717`:**

- `bash tests/build_os_tests.sh` → **1485 passed / 0 failed**, exit 0
- `bash tests/evidence_policy_tests.sh` → **67 passed / 0 failed**
- `bash build-os/registry/scan-controls.sh check` → **exit 0** (78 registered vs 34 refusal-capable surfaces; 66 load_bearing, 14 over-authorised declared, 0 unregistered, 0 phantom, 14 rows reconciled)
- `bash build-os/tools/evidence-policy.sh check` → **exit 0**, 19 findings

## Review

### The central finding: the packet introduced its own wrong number, in the sentence it was asked to scrutinise hardest

**reviewer (stage 2): `fix-then-pass`, 7 items.** The consequentialist half of
the `red_driven` argument cited **"53 of 78"** (README, CHANGELOG) and
**"50 of 75"** (tool header — stale on **BOTH** halves).

**53 is the count of controls whose evidence is exactly `red_driven`** — a real
number, correctly used elsewhere in the packet, **borrowed to answer a different
question**. Re-derived by the archivist at close: `empirical_status: red_driven`
occurs exactly **53** times in `control_registry.txt`, so the number was real and
the *question* was wrong. That is the harder failure to see, and it landed in the
one sentence the brief singled out.

### Fix round: 10 items, one installment, amended into commit 2

The reviewer's 7 plus qa's 3. Executing it, **the builder self-reported that
inserting the new guard shifted 20 `evidence_refs`**, which `scan-controls.sh`
caught at **exit 2 with 5 VACUOUS-REFs before anything shipped** — the
machine-checked half of the registry working exactly as designed, and worth
recording next to the parts that failed.

### reviewer (re-review, stage 3): `fix-then-pass` again, 4 sites

Commit 1 had moved the census **75 → 78** and updated four sibling counts but
left **five numbers stale in prose restating a machine-computed table**. Worst:
**`CROSSWALK.md:87`** — a summary line **three lines under the table it
summarises**, reading `75 bindings: 29 instantiate, 40 proxy` against a
recomputed `78 / 29 / 43`, **contradicting this packet's own CHANGELOG**.

**Nothing machine-checks prose that restates a machine-computed table**, which is
why all five survived a green 1485/0 suite.

### DEPTH DEFECT — recorded plainly

**This packet ran to FOUR serial stages.** `CLAUDE.md` classifies a fourth serial
stage as a **defect**, not a detail. **Cause: the fix list arrived in
installments.**

**The reviewer identified itself as the source, unprompted** — its stage-2 pass
swept commit 1's *figure* sites but never its *census-count* sites — and then
**refused to pass a known-false artefact in order to protect the depth budget.**

**That was the right call and is recorded as such, not as a failure of the
reviewer.** A gate that waves through a number it knows to be false in order to
come in under budget has converted the budget into the thing the budget exists to
protect. The defect is the *installment*, and it is attributable; the refusal to
paper over it is the gate working.

**The remedy applied was the right one for an installment failure.** The
orchestrator closed the 4 sites in the **`tiny` lane** rather than re-cutting the
packet, and **swept the whole class rather than the named sites only** — because
the failure was "one class of site was never swept", and fixing only the named
instances would guarantee a fifth stage. Amended commit 2 a third time.

### Codex second-eyes: NOT fulfilled, on BOTH passes

`build-os/memory/tool_router.md:368` declares a **Second-eyes code review** row
routing the reviewer to Codex (`codex` CLI / Codex-for-Claude-Code plugin).
**`codex` is not on PATH and no Codex plugin is installed.** The row went
unfulfilled in the **review** and in the **re-review**.

**Both gate verdicts in this packet are single-model. Record this as an
unfulfilled declared capability, not a pass.** The row is **unbacked** — it has
now been declared and undelivered across every packet that has ever invoked it.
Either install Codex or stop declaring the row.

It matters more than usual here for a specific reason: the two gates in this
packet **found different things by using different methods**, which is direct
local evidence that a second independent perspective pays. The declared third
perspective was the one that never ran.

## Final state at `0555717`

Re-derived by the archivist directly from the registry files, not copied from the
packet:

| Quantity | Value |
|---|---|
| Controls | **78** |
| `evidence_refs` | **274** |
| Authorities | **66 `gate` / 12 `advise` / 0 `rank` / 0 `observe`** |
| Declared mismatches | **14** declared / 64 none |
| Class | **A 56 / B 3 / C 19** |
| Crosswalk bindings | **78** — 29 instantiate / 43 proxy / 6 nominal |
| Primitives with ≥1 instantiating binding | **8 of 17** |
| Suite | **1485 passed / 0 failed** |
| `evidence_policy_tests.sh` | **67 / 0** |
| `scan-controls.sh check` | **exit 0** |
| Tree | clean |

## The ladder is still used at two rungs of five

**`rank` and `observe` remain 0 of 78.** The authority ladder has five rungs and
this census uses two (66 gate / 12 advise). A 66/12/0/0 distribution carries
almost no information.

There is a sharper edge on it now than there was at 75: **this packet wrote rules
about `rank` and `observe` that no control has ever exercised.** The sharp rule
caps `refuted` at `observe` — a rung nothing occupies. The expensive rule forbids
`unvalidated` from reaching `rank` — a rung nothing occupies. Both rules are
sound, and both are currently arguments about empty rungs. The S1 collision above
is the first time either rung would have had a live occupant, which is why the
operator decision cannot be deferred indefinitely.

---

# Residue — what this close found, and what it could not fix

## 1. THE `75` SWEEP WAS INCOMPLETE — the orchestrator's "no stale 75 remains" is FALSE

> **[STATUS, ADDED ON RESUME — CLOSED IN THE CLOSE COMMIT. See the addendum at the
> foot of this receipt.]** The four sites below now read **78**;
> `control_registry.txt:1464` was judged historical and left at 75. The analysis
> below is preserved unchanged because the finding is about the *gates*, not the
> counts.


The tiny-lane sweep reported: *"Swept the whole class: no stale '75' remains in
any registry artefact."* **The archivist re-ran that sweep at close and it does
not hold.** `grep -rn '\b75\b' build-os/registry/` at `0555717` returns **four
sites**:

| Site | Text | Assessment |
|---|---|---|
| **`build-os/registry/CROSSWALK.md:8`** | "binds each of the **75** registered controls to exactly one of **17** primitives" | **STALE. Bolded, present-tense, and it contradicts `CROSSWALK.md:87` in the same file**, which the re-review corrected to 78. The file disagrees with itself about the census, 79 lines apart. |
| `build-os/registry/CROSSWALK.md:25` | "an eighteenth field on each of the 75 registry records" | **STALE** — present-tense claim about the current census. |
| `build-os/registry/CROSSWALK.md:39` | "costs 75 record edits" | **STALE** — same. |
| `build-os/registry/neurocosmology_crosswalk.txt:169` | "`rollback_behavior` is a prose field on every one of the 75 registry entries" | **STALE** — present-tense. |
| `build-os/registry/control_registry.txt:1464` | "an off-by-one … made every one of the 75 live stanzas unclassifiable" | **AMBIGUOUS — needs a human read.** Past-tense narration of the incident. But qa reproduced that parser red drive at **78/78**, so if it narrates *this* packet's incident the number is wrong; if it narrates the pre-packet state it is right. **Do not sweep it mechanically.** |

**This is the SAME defect the re-review caught, in the SAME file, surviving the
sweep that was supposed to close it.** `CROSSWALK.md:87` was fixed; `CROSSWALK.md:8`
— the file's *opening* description of what it is — was not.

**Not fixed by this close, deliberately.** Three reasons: the packet is at its
2-commit cap; registry artefacts are the packet's *deliverable*, not archivist
memory; and an archivist quietly closing a reviewer-class defect inside its own
close is precisely the papering-over the previous receipt's adoption-guard
episode warned about. **It is reported, not absorbed.** It needs a `tiny`-lane
pass that may write `build-os/registry/`.

**The general lesson, stated for the next packet:** the tiny-lane sweep swept
*counts of controls* and missed *counts of records* — the same class boundary
error, one level down, that caused the installment failure it was fixing. A sweep
that is announced as covering "the whole class" should be closed by re-running
the grep, not by asserting it.

## 2. The suite count is PINNED STALE AGAIN — writing the true number turns the suite RED

> **[STATUS, ADDED ON RESUME — BOTH HALVES CLOSED IN THE CLOSE COMMIT.]**
> `CHANGELOG.md` now carries the literal `**1485 passed**` and `current_state.md`
> now reads 1485. The archivist's refusal to write the token alone was **correct**
> — it would have turned the tree red. The write-gate trap it identified is real
> and unfixed; only this instance is closed.


**The live total is 1485. The guard-bound token in `current_state.md` reads
1418.** The token was **left at 1418 on purpose**, and this was measured in both
directions, not assumed.

**Proven at `0555717`** in a throwaway clone: setting the line to
`1485 checks` produces

```
FAIL: CHANGELOG does not report '1485 passed' — it disagrees with current_state.md's claim
==== RESULT: 41 passed, 1 failed ====
```

`tests/release_metadata_tests.sh:288` runs `grep -qF "$CLAIMED passed"` against
`CHANGELOG.md`, and **the string `1485` does not occur anywhere in the
repository** (`grep -rn 1485 --include=*.md --include=*.sh .` → no hits). This
packet's own CHANGELOG entry reports "67 assertions" for the new suite but
**never states the new chained total**, so the literal was never created.

**`CHANGELOG.md` is outside the archivist's write gate**, so the matching edit is
not mine to make. **Writing the true number here would break the build, so it was
not written**, and the line now states the live total loudly next to the
guard-bound token.

**This is the third consecutive packet in which this pair has gone stale**, and it
is now a *recurring* trap rather than an incident: 657 → 1418 (fixed by this
packet's commit 2, which could write CHANGELOG) → 1485 (stale again immediately).
**The fix is one literal string in `CHANGELOG.md` plus the token here, in a lane
that may write outside `build-os/`.**

### And the guard still does not detect staleness

`current_state.md` at 1418 and `CHANGELOG.md` at `**1418 passed**` **agree**, so
§5 passes — while the true total is 1485. **Two stale files that agree pass.**
The check that actually works remains **opt-in and still not enabled by the
chained suite**: `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh`.
A guard named for a failure mode it cannot detect by default is a false comfort,
and it has now been demonstrated twice on the same token.

## 3. Two memory claims about EXTERNAL state are false — found at close

Neither is this packet's doing; both are recorded because the archivist re-read
git rather than the memory file, and this is the section where accuracy matters
most.

- **`current_state.md` says "No tags exist in this repo yet." A tag exists.**
  `v0.1.0` — annotated, tagger `Claude <noreply@anthropic.com>`, dated
  **2026-07-31 02:28:23 +0000**, subject *"Gravito v0.1.0 — first installable
  release"*, pointing at `da4ae81`. **Corrected in `current_state.md` by this
  close.** It could **not** be corrected in `CHANGELOG.md`, whose rollback
  section states "rollback is not yet proven — no tags exist" and is **outside
  the archivist's write gate**; and it must **not** be removed from `residue.md`,
  because `tests/release_metadata_tests.sh:322` requires the literal `no tags` to
  appear there — so the residue item is **annotated with the correction rather
  than rewritten**, keeping the suite green while making the record true.
  **Whether that tag was created with an explicit go is not something the
  archivist can determine, and no claim is made either way.**

- **`residue.md` says the branch is UNPUSHED. It has been pushed, repeatedly.**
  `refs/remotes/origin/claude/project-handoff-merge-ramhds` is at **`6b01173`**,
  and `git reflog show` for that ref records five successive `update by push`
  entries (`6b01173`, `321dced`, `e8f34ed`, `785a851`, `d30aeab`). **Only this
  packet's two commits — `105cb75` and `0555717` — are genuinely local-only.**
  Corrected in memory. Again, no claim is made here about whether those pushes
  were authorised; the record is corrected to match git, and the discrepancy is
  flagged for the operator.

## 4. Nothing machine-checks prose that restates a machine-computed table

**Three packets running now**, and it is the highest-value follow-on in the file:

- `MISMATCHES.md` §10's file/lines table — **twice**
- `CROSSWALK.md:87` — once (fixed), and `CROSSWALK.md:8` — **still open** (item 1)

**§5a is the pattern a checker would follow.** It reconciles README §3a's cap
table against the tool's `EVIDENCE_AXIS` in both directions and is red-driven
both ways. The same shape — parse the prose restatement, recompute the table,
diff them — closes this class. Note the asymmetry that makes it worth building:
qa's mutation test proved the cap table was unguarded in *seconds*, while the
`CROSSWALK.md` instances have now consumed a re-review, a tiny-lane sweep, and
this close, and one is **still open**.

## 5. An UNREPRODUCED flake — flagged, not diagnosed

qa's **base clone's first run** reported **1398 + 20 = 1418** with **no `FAIL:`
line captured**. **Five subsequent runs — three of them under load — were all
1418 / 0.** Pre-existing at `6b01173`; not introduced by this packet.

**Flagged, not diagnosed, and deliberately not chased.** One unreproduced
anomaly in six runs is not enough signal to spend a packet on, but a suite whose
count can move without a captured failure line is exactly the kind of thing that
is cheap to dismiss and expensive to have dismissed. If it recurs, the missing
`FAIL:` capture is the thread to pull, not the count.

## 6. The S1 evidence-token decision

See the headline. **`untested` is not one of the five tokens; a Class-A gate
refuses the whole derivation at exit 2 on an unrecognised token.** The operator
chooses: add a sixth token, or have S1 arrive carrying `unvalidated`. **This
blocks step 2.**

## 7. Carried forward, unchanged

- **`swarm-merge.sh` disjointness has FALSE NEGATIVES** (`src/*.ts` and `src/foo*` both match `src/foo.ts`). CLAUDE.md's fan-out gate rests on this check.
- **`tests/entitlement_tests.sh:296-305`'s hardcoded 12-file `PACKET_FILES` list decays silently**; this packet added two more files it does not cover.
- **Nothing asserts `active_packet.md` exists and is tracked** — the singleton gate's own disclosed evasion.
- **`maint.tripwire_coverage_scan` is `refuted` and still gates.** The evidence axis now says so *twice* — by class-axis mismatch and by the sharp rule, which caps it at `observe`. **Still BLOCKED on the authority envelope; still the operator's call.**
- **New Class-C controls ship at `advise` by default** (precedent from the prior packet). **Forward-facing only** — it does not generalise backward to the existing 13.

## Open boundaries — nothing done without go

- **Nothing pushed, merged, tagged, deployed or PR'd by this close.** Local commits only.
- No secrets touched. No `git config`.
- `/home/user/empathiq-website` untouched, preserved at `cb2bb7d`.
- **`105cb75` and `0555717` are local-only** and remain so pending explicit go. (The branch's *earlier* history is already on `origin` at `6b01173` — see residue item 3.)
- **The S1 token decision (add `untested`, or make S1 carry `unvalidated`) is an OPERATOR decision** and is deliberately not taken.
- **Re-authorising or demoting any of the 19 out-of-licence controls is a governance action.** The matrix reports and exits 0. Nothing here performs one.
- **The `CROSSWALK.md:8` stale-count fix (residue item 1) and the CHANGELOG `1485 passed` literal (residue item 2) both need a lane that may write outside the archivist's gate.** Reported, not absorbed. **[Both landed in the close commit — see the addendum below.]**

---

# ADDENDUM — the close was INTERRUPTED, and this is what the resumed close changed

**This section was written after the fact and is marked as such.** Everything
above it is the archivist's own record, preserved. The archivist wrote its four
files, and **the container restarted before it ran a single verification**. Its
writes sat uncommitted and unchecked. Two things follow, and both are recorded
rather than tidied away:

## A. The tree was RED, and the archivist's own metrics row was the cause

`bash tests/build_os_tests.sh` returned **1484 passed / 1 failed**:

```
FAIL: the live seeded report claims a defects-escaped total of "4"
      — no packet in the corpus was ever audited for escapes
```

The archivist had written **`defects_escaped=4`** in column 13 of
`build-os/metrics/packet_metrics.tsv`, reasoning that its close-time re-run of the
stale-`75` grep found four sites that got past both gates.

**The guard is right and the value was wrong — on semantics, not arithmetic.**
`tests/speed_benchmark_tests.sh:293-295` defines that column as *what a post-close
audit finds*. The four sites were found **at close, before the packet closed, and
are fixed in this very close commit**. They escaped the **gates**; they never
escaped the **packet**, and nothing reached a reader. **The column now reads `-`,
and the guard was not touched.**

**The finding itself is preserved, in the row's note and in `residue.md` item (l)**
— four stale sites got past *both review gates AND the orchestrator's tiny-lane
sweep that reported the class closed*, and were caught only because the archivist
re-ran the check at close. That is a real, valuable observation about the gates.
It is simply not an escape.

## B. The `75` sweep — swept by the number this time, and every hit classified

The orchestrator's sweep had grepped for hand-written phrases
(`"75 controls\|75 bindings\|75 entries\|of 75"`), which matched **none** of the
four live sites — hence the false "class clear". Re-swept with
**`grep -rn '\b75\b'`** across `build-os/registry/*.{md,txt}`,
`build-os/memory/*.md`, `CHANGELOG.md`, `README.md`, `build-os/tools/*.sh`, and
**every hit classified by hand**:

**Fixed — present-tense claims about the live census:**

| Site | Was | Now | Why |
|---|---|---|---|
| `CROSSWALK.md:8` | "binds each of the **75** registered controls" | **78** | Present tense, describes the artefact as it is. Contradicted `:87`'s corrected "78 bindings" in the same file. |
| `CROSSWALK.md:25` | "an eighteenth field on each of the 75 registry records" | **78** | Judged a live count, **not** a frozen deliberation — decided on evidence: `git show be9de88` has it at **71**, and `86c8f93` moved it to 75 **in step with `:8` and `:39`**. All three have always been maintained as the live census. |
| `CROSSWALK.md:39` | "costs 75 record edits" | **78** | Same evidence, same conclusion — it states today's cost of a rejected alternative. |
| `neurocosmology_crosswalk.txt:169` | "a prose field on every one of the 75 registry entries" | **78** | Present tense. |
| `neurocosmology_crosswalk.txt:169` | "`defects_escaped` … reads `-` in all **6 of 6** rows" | **8 of 8** | Re-derived, not trusted: `packet_metrics.tsv` holds **8** data rows (6 at `be9de88` when the line was written, 7 after `12dbdc5`, 8 with this packet's). All 8 read `-`. |

**Left alone — genuine historical record:**

| Site | Why it is correct |
|---|---|
| `control_registry.txt:1464` — "an off-by-one in the field parser made every one of the 75 live stanzas unclassifiable" | Narrates `evidence-policy.sh`'s **first run**, which necessarily preceded registering the three new stanzas — the tool had to exist before `evidence.derivation_nonvacuity` could be registered *for* it. **75 was the live count at the moment narrated.** qa's `78/78` re-drive is a reproduction on the *final* tree and does not date the incident. |
| `CHANGELOG.md:106` — "field parser made all 75 live stanzas unclassifiable" | Same incident, landed release block. |
| `CHANGELOG.md:131 / :133 / :135` — census `71 → 75`, `0 of 75`, `75 bindings, 29/40/6` | The **previous** release block. A landed changelog entry records the state at its release; rewriting it would falsify the history. |
| `current_state.md:110` — tool header "stale on both halves at `50 of 75`" | Quotes the historical defect verbatim. |
| `current_state.md:147` — "Census 71 -> 75 at that close" | States the prior packet's transition. |
| `residue.md:242` — "0 of 78 (was 0 of 75 at that close)" | Explicitly dated. |
| `residue.md:442`, `build-os/tools/specialist-handoff.sh:219-220` — "BUSY exit 75" | A **process exit code**, not a census. Unrelated to the class. |

The remaining hits are `residue.md` items (l)/(m), `current_state.md`'s close
note, `active_packet.md`'s carried list and this receipt — i.e. **the record of
the sweep itself**, quoting the strings it fixed. Those must contain `75`.

## C. What the resumed close verified that the archivist never could

All of the archivist's recorded census figures were re-derived from the live
registry and **every one matched**: 78 controls, `evidence_refs` **274**,
**66 `gate` / 12 `advise` / 0 `rank` / 0 `observe`**, **14** declared mismatches,
class **A 56 / B 3 / C 19**, **78** bindings (**29** instantiate / **43** proxy /
**6** nominal), **8 of 17** primitives with an instantiating binding. Nothing in
its prose or its judgements was rewritten.

Column 12 `defects_gated=14` reconciles (reviewer 7 + qa 3 + reviewer 4 at
re-review). Columns 4 (`rounds=8`) and 7 (`agents=6`) remain flagged in the note as
**NOT WITNESSED BY THE RECORDER**; `wall_min`/`serial_min` remain `-`.

## D. The close is a THIRD commit, and that is deliberate

The packet is at its **2-commit cap** (`105cb75`, `0555717`) and **neither was
amended**. This close is a separate archivist-style commit on top, matching the
convention of prior closes (`12dbdc5 Close gravito_census_gaps_egress_bandwidth_a:
receipt + memory`). **Nothing pushed, merged, tagged, PR'd or deployed. No guard
was weakened, deleted or exempted. No control was re-authorised.**
