# gravito_authority_envelope_a — give the operator an artefact to grant authority in, and a third MIN term

- **Date:** 2026-08-01
- **Lane:** `substantive` (builder → qa ‖ reviewer → fix → re-review → tiny-lane close → archivist)
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `77a0040`; re-verified at close (`git merge-base a7ab841 77a0040` = `77a0040`).
- **Final HEAD (packet):** `a7ab841`
- **Verdict:** **pass as fixed** — reviewer `fix-then-pass` (9 items), re-review `fix-then-pass` (3 one-line items), qa **GREEN** at `4bc240a`. All fix rounds landed and were re-verified.

The evidence-policy packet closed with two things blocked on an instrument that did
not exist: `maint.tripwire_coverage_scan` gating on `refuted`, and the fourteen
declared mismatches. Both are governance actions, and there was no artefact an
operator could *perform* one in. This packet builds that artefact — and then
proves, by mutation, that **it cannot perform either of them**, which is the
finding that matters most.

## What landed

**The store** — `build-os/registry/authority_envelopes.txt`. **0 live grants.**
The worked example lives **entirely inside `#` comments**, deliberately: a store
that shipped with a live example grant would be an artefact asserting that a
grant had been made when none had. §7 and §8 pin the emptiness and pin that zero
grants is the **correct** state — explicitly *not* the registry's vacuity rule,
which would read an empty set as a failure.

**The validator** — `build-os/tools/authority-envelope.sh`, subcommands
`schema` / `check` / `modes`. `modes` is the machine projection the evidence
matrix consumes (§16).

**A THIRD MIN TERM.** Composition becomes

```
L_effective = min(L_class, L_evidence, L_deployment)
DEPLOYMENT_AXIS="shadow:observe human_confirmed:advise bounded_autonomous:rank autonomous:gate"
```

The default for a control with no envelope is `autonomous`, which **adds no cap**
— the only default that leaves a census written before this axis existed exactly
where the operator put it. §4 pins the default at the point it is read.

**Three controls registered**, census **78 → 81**: the envelope tool and its
suite, plus a Class A derivation gate. **Zero `-` lines on any governance field**
across the whole diff — qa proved this, not the builder. The new Class C control
ships at `advise` with `authority_mismatch: none`, consistent with the standing
forward-facing precedent.

**The Class A derivation gate carries a `demotion_requirement` that names a
CONTRACT CHANGE**, not a preference. The reviewer applied the same test that
caught a C-wearing-an-A two packets ago (`bandwidth.active_packet_singleton`).
**This one passed.**

**`tests/authority_envelope_tests.sh`** (new, 91 assertions), chained.
`tests/evidence_policy_tests.sh` extended 67 → 88.

## Scope

**In:** `build-os/registry/authority_envelopes.txt` (new),
`build-os/tools/authority-envelope.sh` (new), `tests/authority_envelope_tests.sh`
(new), the `chain_suite` line in `tests/build_os_tests.sh`,
`build-os/tools/evidence-policy.sh` (third axis),
`tests/evidence_policy_tests.sh` (§18 / §18a / §18b / §5b), three registry
entries + three crosswalk bindings, `build-os/registry/README.md` §3b,
`CROSSWALK.md`, `MISMATCHES.md`, `CHANGELOG.md`.

**Explicitly out — ruled out, not deferred:**

- **Writing any live grant.** The store ships empty on purpose (§7/§8).
- **Resolving the S1 tension.** Both readings recorded, neither adopted, and §17
  fails if one is silently adopted. See below.
- **Adding `untested` as a sixth evidence token.** §18 of the envelope suite
  declares it **pending, declared, and not implemented**. Still the operator's call.
- **Applying promotion/demotion to the fourteen mismatches (step 3).** Not merely
  deferred — **proven impossible with this instrument**. See the second headline.
- `/home/user/empathiq-website` (preserved, untouched, at `cb2bb7d`).

## Commits

- `88052e7` feat(registry): give the operator an artefact to grant authority in, and a third MIN term — 11 files, +1852 / −73
- `a7ab841` docs(changelog): record the authority envelope, the axis guard, and the two things it refuses to decide — 9 files, +290 / −16

**Two commits, at the cap.** `88052e7` is **byte-identical** through every fix
round and **is still an ancestor** of `a7ab841` (`git merge-base --is-ancestor`
→ yes), so qa's Commit-1-green-in-isolation proof survived intact and was never
re-spent. Commit 2 absorbed the fix round, the re-review, and the tiny-lane close
by amendment.

Per-commit numstat union (the figure `record-packet.sh --verify-git` checks):
**12 files, +2142 / −89**.

## File-ownership manifest (attribution by path)

Recorded because the metrics row names **two** commits.
`build-os/metrics/check-adoption.sh:519` requires it: one commit per packet where
the merge allows it, and where it does not, **the file-ownership manifest is what
keeps per-packet attribution recoverable by path.**

**Owned solely by `88052e7` (commit 1 — the build):**

| Path | +/− |
|---|---|
| `build-os/registry/authority_envelopes.txt` *(created)* | +186 / −0 |
| `build-os/tools/authority-envelope.sh` *(created)* | +408 / −0 |
| `build-os/tools/evidence-policy.sh` | +128 / −25 |
| `tests/build_os_tests.sh` | +1 / −0 |

**Owned solely by `a7ab841` (commit 2 — the record and the fix rounds):**

| Path | +/− |
|---|---|
| `CHANGELOG.md` | +148 / −0 |

**Touched by BOTH commits — attribution here is by commit, not by path:**

| Path | `88052e7` | `a7ab841` |
|---|---|---|
| `build-os/registry/CROSSWALK.md` | +16 / −16 | +2 / −2 |
| `build-os/registry/MISMATCHES.md` | +2 / −2 | +3 / −3 |
| `build-os/registry/README.md` | +153 / −7 | +35 / −0 |
| `build-os/registry/control_registry.txt` | +63 / −9 | +4 / −4 |
| `build-os/registry/neurocosmology_crosswalk.txt` | +28 / −7 | +3 / −3 |
| `tests/authority_envelope_tests.sh` | +688 / −0 | +63 / −0 |
| `tests/evidence_policy_tests.sh` | +179 / −7 | +2 / −2 |

**This set is NOT disjoint, and saying so is the point.** Commit 2 carried the
fix round, the re-review and the tiny-lane close into the same registry files and
the same tools commit 1 created. **No fan-out was run** — a single builder, so
disjointness was never a safety property here; the manifest exists so a later
reader can attribute any line to the commit that wrote it without re-deriving it
from the diff.

Note the shape: `build-os/tools/authority-envelope.sh` appears in **both**
columns, and the `--help` `sed`-range defect (residue item 3) lived in the
commit-1 half and was fixed in the commit-2 half. Without this table that
attribution is unrecoverable.

---

# HEADLINE 1 — the packet's own claim about itself was FALSE, and mutation proved it

`evidence-policy.sh` asserted, in prose:

> *"The suites reconcile the two, so this cannot quietly restate the third axis
> differently."*

**It could.** The reviewer changed **only** `authority-envelope.sh`'s
`DEPLOYMENT_AXIS` from `shadow:observe` to `shadow:none`, left README §3b saying
`observe`, and **both suites stayed green — 86/0 and 88/0.**

**The orchestrator reproduced this independently.**

The diagnosis is exact and is the transferable part: `§5b` of
`tests/evidence_policy_tests.sh` pinned the evidence matrix's **copy** of the
axis. **Nothing pinned the axis's declared OWNER.** A tool can be a faithful
copy of a document and still be the wrong document.

**Closed by new §2a** of `tests/authority_envelope_tests.sh:242` —
*"THE AXIS THIS TOOL OWNS IS A COPY OF README §3b, not a rewrite of it"* —
which reconciles `DEPLOYMENT_AXIS` against README §3b's cap table in **both
directions**, with a non-vacuity floor on **both sides** (`NRD==NMODE &&
NTD==NMODE`).

**The orchestrator re-drove the identical mutation against the new guard:
89 passed / 2 failed.**

**Record how it was fixed, not only that it was:** the fix used **the device
already in the tree** — §5a's parse-the-prose / recompute-the-table / diff-both-ways
pattern from the previous packet — applied one file along. No new invention. This
is the class `residue.md` (m) has been calling the highest-value follow-on for
four packets; §2a is its third instance and the first one applied to an axis's
*owner* rather than its copy.

---

# HEADLINE 2 — AN ENVELOPE CAN ONLY LOWER `L_effective`. IT CANNOT LEGITIMISE A GRANT.

**This is the finding the operator most needs, and it re-scopes step 3.**

The reviewer wrote a **well-formed operator grant** of `gate` to
`adoption.lane_size_check` — the most obvious possible first use of the new
instrument — and got:

```
OVER-GRANTED … granted=gate l-class=advise l-effective=advise binding-axis=class
```

and `evidence-policy.sh`'s nineteen finding lines came back **byte-identical**
with the over-grant present versus an empty store.

**The behaviour is correct, and it is arguably the best property in the packet.**
`L_effective = min(...)` means a new term can only ever *lower* the result. An
envelope is a **ceiling the operator volunteers**, never a floor the operator
buys. The tool **refuses to launder a Class-C gate even when the operator signs
off** — which is exactly what you want from an authority instrument, and exactly
what an authority instrument is usually asked to do instead.

**But the consequence is structural and must not be lost:**

> **Step 3 — applying promotion/demotion rules to the fourteen declared
> mismatches — CANNOT be done by writing envelopes.** Every one of the fourteen
> is a control exercising *more* authority than its class licenses. An envelope
> can only take authority away. Fixing a mismatch upward requires **a class
> change or a different instrument**; fixing it downward is a demotion the
> envelope *can* express but that no one has authorised.

The packet that was built to unblock step 3 has instead **proven that step 3
needs something else.** That is a real result and it is cheaper to have learned
here than after fourteen envelopes were written.

---

## The S1 tension: BOTH readings recorded, NEITHER adopted

S1 is slated to arrive at `heuristic_policy` / `untested` / `rank` / `shadow`.
That declaration **cannot be produced by `min()`**.

- **Reading 1:** S1 ships carrying `authority_mismatch: declared` — the
  fifteenth, consistent with the fourteen already reported.
- **Reading 2:** `shadow` means the ranking has no consequence, so
  `runtime_authority` is measuring the wrong property, and the ladder
  **conflates signal strength with whether anything consumes the signal**.

**Both recorded, neither adopted**, and the non-adoption is **enforced**:
`tests/authority_envelope_tests.sh:659` (§17) fails with

```
reading 2 has been silently adopted — shadow now licenses rank, which redefines the ladder
```

### The reviewer's own advice — LABELLED AS ADVICE, AND NOT ADOPTED

> **The S1 collision is not a deployment-axis problem at all.** `heuristic_policy`
> is **Class C**, so `L_class = advise`, and `rank > advise` — **the minimum is
> capped BEFORE the deployment term is ever consulted.** `shadow`'s cap could be
> `gate` and S1 would *still* be out of licence. The deployment axis is
> irrelevant to this particular collision.
>
> The reviewer therefore recommends S1 declare **`runtimeAuthority: observe`**
> with a note that its **signal** is rank-shaped — keeping the two concepts
> cleanly separated: `runtime_authority` = *the permitted consequence*,
> `deployment_mode` = *whether anything consumes it*.

**This is the operator's call and NOTHING HAS ADOPTED IT.** It is recorded here
because it is the sharpest analysis of the collision anyone has produced, not
because it has any standing.

---

## QA proof — GREEN at `4bc240a`

qa re-derived everything with **its own buffered stanza parser**, refusing to
reuse the tool it was measuring.

| Check | Result |
|---|---|
| Finding set vs base | **byte-identical** — 19 ids, **zero delta**; the `deployment-mode=autonomous` suffix uniform across all 19 |
| Split | **6 class / 5 evidence / 8 both** |
| The 14 | **equals the `authority_mismatch: declared` set exactly** — symmetric difference empty **in both directions** |
| New controls | **3**, with **0 `-` lines on any governance field** |
| Store | **0 live grants** |
| `untested` | still **refused at exit 2 with ZERO summary lines** |
| §17 non-adoption | **fires** |
| Refusal states | **all 9 exit 2 and propagate** |
| `evidence_refs` | **287, all resolve** |
| Commit-1 isolation | **green at `88052e7`** |
| Safety grep | **1966 added lines, all 18 patterns proven NON-BLIND on a poison fixture** |
| UI smoke | **N/A** — no UI surface |

The safety grep is worth calling out: qa did not merely run 18 patterns and
report zero hits. It **built a poison fixture and proved each of the 18 patterns
could fire**, because a grep that matches nothing and a grep that *can* match
nothing produce identical output.

### QA PROVED THE THIRD AXIS IS LIVE, NOT DECORATIVE — the orchestrator could not settle this

This was the open question the orchestrator brought to the gates and could not
answer. qa answered it four ways:

| Drive | Result |
|---|---|
| Valid grant present | `modes` emits `metrics.record.schema_invariant→human_confirmed` |
| Validator **deleted** | `evidence-policy.sh` exits 2 with a **named** refusal |
| Validator **`chmod -x`** | exits 2, named refusal |
| Validator **stubbed** | exits 2, named refusal |
| A `shadow` grant | census moves **19 → 20** with `licensed=observe axis=deployment` |

The last row is the one that matters: the axis **changes the finding set** when
exercised. It is not a column that always prints the default.

**qa also distinguished §18 from §18a, which the builder had conflated.**
`evidence_policy_tests.sh` §18 ("the third MIN term changes nothing on the live
census") **compares two empty stores** — it proves *invariance* and cannot prove
*non-inertness*. **§18a** ("a fixture under `shadow` is capped, driven red") is
the section that actually discriminates. A suite can contain a section that looks
like the proof of a property and is structurally incapable of being that proof.

## Review

**reviewer: `fix-then-pass`, 9 items** — **two of them proven by MUTATION rather
than argued** (Headlines 1 and 2 above). The reviewer did not report that a claim
was unsupported; it broke the claim and showed the suite staying green.

### Fix round: 9 items, ONE installment

The builder executed the list **by number** and, sweeping the class rather than
the named sites, **found 4 MORE stale sites this packet had created** — including
`MISMATCHES.md:248`'s `:938` sitting in **the same sentence** as the `:960` the
reviewer had flagged. **Neither the reviewer nor the orchestrator saw it.**

That is the sweep-the-class discipline from the last packet's lesson working
exactly as intended, one packet later.

### reviewer (re-review): `fix-then-pass`, 3 one-line items

Closed by the orchestrator in the `tiny` lane at `a7ab841`.

### DEPTH DEFECT — four serial stages, and the cause is DIFFERENT from last packet's

`CLAUDE.md` classifies a fourth serial stage as a **defect**. This packet ran to
four. **The cause is not the same as last packet's, and the difference is the
whole point of recording it.**

| Packet | Stage-4 cause |
|---|---|
| `gravito_evidence_policy_matrix_a` | **incomplete ENUMERATION** — the fix list arrived in installments; the reviewer's stage-2 pass never swept one class of site |
| **this packet** | **incomplete APPLICATION** — the reviewer swept the whole class first, enumerated correctly in one installment, and **two of its nine items did not fully land** |

The two that did not land:

- **Item 7** renamed a section header **without the two prose references pointing
  at it** — a rename applied to the definition and not to its callers.
- **Item 6** over-corrected a false claim **into a different false claim**.

**Name the failure mode explicitly: INCOMPLETE APPLICATION, NOT INCOMPLETE
ENUMERATION.** They need different remedies. The remedy for incomplete
enumeration is *sweep the class*; that was applied here and it worked — the
enumeration was complete. The remedy for incomplete application is different and
is not yet in the process: **a fix round must verify each item landed, not that
each item was addressed.** A rename is not done when the definition changes; it
is done when nothing still points at the old name.

**The reviewer self-identified this without being asked**, for the second packet
running. That is worth recording as the gate working, not as the gate failing.

### Codex second-eyes: NOT fulfilled, on BOTH passes — again

`build-os/memory/tool_router.md:368` routes reviewer second-eyes to Codex
(`codex` CLI / Codex-for-Claude-Code plugin). **`codex` is not on PATH and no
Codex plugin is installed.** The row went unfulfilled in the **review** and in
the **re-review**.

**Both verdicts in this packet are single-model.** The row is **unbacked** — now
declared and undelivered on every packet that has ever invoked it. Either install
Codex or stop declaring the row.

---

# A PROCESS DEFECT THE ORCHESTRATOR OWNS

**This entire packet was built with `build-os/packets/active_packet.md` reading
"NO PACKET IN FLIGHT".** The orchestrator dispatched the builder without ever
setting it.

**The reviewer ruled: DO NOT back-write the file.** Back-writing it would
manufacture an artefact stating that a packet was declared when it was not —
**precisely the falsehood the envelope store avoids by keeping its worked example
inside `#` comments.** A record that is corrected after the fact to say a thing
happened is worse than a record that says the thing did not happen.

**So the record stands: no packet was ever declared for this packet.**
`active_packet.md` was not back-written and still reads NO PACKET IN FLIGHT.

**The irony, stated plainly, because it is a real gap:**

> `bandwidth.active_packet_singleton` refuses **TWO** declared packets but permits
> **ZERO**. So an entire packet — two commits, 2142 insertions, three new
> registered controls — was built with no declared packet, **and the control
> passed clean.**

**This is the disclosed "delete the file evades it" hole in a strictly worse
form.** `residue.md` (c) records that deleting or untracking `active_packet.md`
makes the singleton gate pass trivially. That evasion **requires an affirmative
destructive act**. This one **fires on pure omission** — nobody has to do
anything wrong; somebody merely has to not do something. Omission-triggered
evasions are the ones that happen by accident, repeatedly, and this is the first
recorded instance.

Filed as `residue.md` (u).

---

## Final state at `a7ab841`

Re-derived by the archivist directly from the registry files, not copied from the
packet:

| Quantity | Value |
|---|---|
| Controls | **81** |
| `evidence_refs` | **287**, all resolving |
| Authorities | **68 `gate` / 13 `advise` / 0 `rank` / 0 `observe`** |
| Declared mismatches | **14** declared / 67 none |
| Class | **A 58 / B 3 / C 20** |
| Crosswalk bindings | **81** — 29 instantiate / 46 proxy / 6 nominal |
| `homeostasis` | **22** (17 suites) |
| `epistemic_quality` | **25** |
| Primitives with ≥1 instantiating binding | **8 of 17** |
| Live authority envelopes | **0** |
| Suite | **1597 passed / 0 failed** |
| `authority_envelope_tests.sh` | **91 / 0** |
| `evidence_policy_tests.sh` | **88 / 0** |
| `scan-controls.sh check` | **exit 0** — 81 controls / 36 surfaces |
| `evidence-policy.sh check` | **exit 0** — **19 of 81**, split **6 / 5 / 8** — unmoved |
| Tree | clean |

**The finding did not move.** 19 of 81, same split, same ids. Adding a whole new
axis to a licence model and having the census not budge is the correct outcome
for an instrument that ships with zero grants — and it was *proven* rather than
assumed, byte-for-byte against the base.

## The ladder is still used at two rungs of five

**`rank` and `observe` remain 0 of 81.** 68 gate / 13 advise carries almost no
information. This packet, like the last, wrote rules about rungs no control has
ever occupied — `shadow:observe` and `bounded_autonomous:rank` are both caps onto
empty rungs. S1 remains the first candidate occupant of either.

---

# Residue — what this close found

## 1. A STRUCTURAL CITATION DEFECT — and it is GUARANTEED, not occasional

`residue.md:280` and
`build-os/receipts/gravito_evidence_policy_matrix_a.md:572-573` cite
`CHANGELOG.md:106` and `CHANGELOG.md:131`. **Both were correct when written.**
This packet's **145-line prepend** invalidated them. Verified at close:
`CHANGELOG.md:106` now sits inside this packet's zero-grants argument, and `:131`
inside the S1 tension — neither narrates what its citation claims.

**This will happen to EVERY `CHANGELOG.md` line-citation on EVERY future packet.**
The changelog grows **from the top**, so every landed citation into it decays by a
fixed amount on every release. The decay is **structural and guaranteed**, not
occasional drift.

**Remedy: cite by release-block heading, and stop creating new line-citations into
`CHANGELOG.md` at all.** Filed as `residue.md` (r).

## 2. `MISMATCHES.md` has carried a stale line reference in SIX CONSECUTIVE PACKETS

§10's table **names its own decay mode in prose** and nothing checks it. Six
packets is no longer a recurring incident; it is a permanent property of the
file. Filed as `residue.md` (s).

## 3. A SECOND INSTANCE OF THE SAME SPECIES — and this one degrades SILENTLY

`build-os/tools/authority-envelope.sh`'s `--help` uses a **hand-maintained `sed`
range**, `sed -n '2,196p'`, **duplicated across TWO handlers** (`:235` and
`:245`). **It was live and broken until the fix round caught it.**

The property that makes it worse than the `MISMATCHES.md` case: when the range
goes stale it **silently truncates the help text rather than failing**. A
hand-maintained line number that *errors* when stale is a nuisance; one that
*quietly returns less* is a defect that can persist indefinitely. **Nothing tests
it.** Filed as `residue.md` (t).

## 4. The zero-declared-packet gap

See the process defect above. Filed as `residue.md` (u).

## 5. NON-BLOCKING — reviewer flagged and EXPLICITLY PASSED. Do not treat as open.

`tests/evidence_policy_tests.sh:322` — §5b's non-vacuity floor is
`NRD == NTD && NRD != 0`, which is **weaker** than §2a's
`NRD == NMODE && NTD == NMODE`. §5b's form would pass if both sides yielded 2 of
4 rows.

**It is not a live hole**: §2a covers the same axis with the stronger form, in
both directions, with the mode count as the floor. **Align §5b whenever that file
is next open for another reason.** Filed as `residue.md` (v), marked non-blocking.

## 6. Carried forward, unchanged

- **The S1 evidence-token decision** — `untested` is still not one of the five
  tokens; §18 declares it *pending, declared, not implemented*. Operator's call.
- **`maint.tripwire_coverage_scan` is `refuted` and still gates** — flagged by two
  axes. **No longer "blocked on the authority envelope": the envelope now EXISTS
  and an envelope CAN express this demotion.** What is missing is not the
  instrument but the authorisation. Operator's call.
- **`swarm-merge.sh` disjointness FALSE NEGATIVES** (`src/*.ts` and `src/foo*`
  both match `src/foo.ts`). CLAUDE.md's fan-out gate rests on this check.
- **`tests/entitlement_tests.sh:296-305`'s hardcoded 12-file `PACKET_FILES` list**
  decays silently; this packet added two more files it does not cover.
- **`RELEASE_METADATA_LIVE_SUITE=1` is still opt-in and still not chained** — see
  the note below on why this close could finally close the count pair.
- **Nothing machine-checks prose that restates a machine-computed table** —
  four packets running. §2a is the third instance closed; the class is still open.

## The suite-count pair — CLOSED AT LAST, and the mechanism is worth keeping

`current_state.md` claimed **1485** at `:33` and `:93`; live is **1597**. This
close is the **first opportunity in four packets** to close that pair from the
archivist's lane, because **the CHANGELOG half was already correct**:
`CHANGELOG.md:32` carries the literal `**1597 passed**`, verified present
**exactly once and unsplit**.

The reason this recurred for three packets is structural and is unchanged: the
two halves of §5's check are owned by different lanes, and the archivist can
write only one of them. **It closed this time only because the builder happened
to write the live total into the CHANGELOG entry** — not because the structure
improved.

**And §5 still cannot detect staleness.** It checks cross-file *agreement*; two
stale files that agree pass. That is exactly how this pair survived four packets.
**Verified at close, both directions:**

- *Before* the memory write: `RELEASE_METADATA_LIVE_SUITE=1` reported
  `FAIL: live suite total (1597 passed) contradicts current_state.md's claim (1485) — the memory is stale`
  → `43 passed, 1 failed`, **while the chained suite was green at 1597/0** — a
  fifth demonstration that the chained guard is blind here.
- *After*: **MATCH**, reported below.

## 7. THE FLAKE FROM `residue.md` (o) RECURRED AT THIS CLOSE — and the reason it cannot be diagnosed is now known

The previous receipt flagged an unreproduced anomaly and said: *"If it recurs,
the missing `FAIL:` capture is the thread to pull, not the count."* **It
recurred.**

At this close, `RELEASE_METADATA_LIVE_SUITE=1` reported

```
FAIL: live run of tests/build_os_tests.sh is not green (exit 1, 1 failed)
FAIL: live suite total (1596 passed) contradicts current_state.md's claim (1597)
```

while a **direct** run of the same suite on the same quiet tree, seconds apart,
returned **1597 passed / 0 failed, exit 0** — and two immediately following
`RELEASE_METADATA_LIVE_SUITE=1` runs both returned **1597, MATCH, 44 / 0**.
**Same shape as the original: the count moved by exactly 1 and no `FAIL:` line
reached the observer.**

**The blocker is now identified, and it is structural.**
`tests/release_metadata_tests.sh:329-330` writes the nested suite's output to
`"$WORK/live.log"` inside an `mktemp -d` that is cleaned on exit, and the guard
reports only the **parsed counts** (`ACTUAL`, `ACTUAL_FAIL`). **It never surfaces
the failing assertion.** A live cross-check failure is therefore
*undiagnosable from its own output* — which is precisely why this anomaly has now
survived two packets.

**Cheap fix, and it is the prerequisite for ever diagnosing this:** echo the
`FAIL:` lines from `$LIVE_LOG` on the failure branch. **Still not chased** — **one
anomaly in eight clean-tree runs here** (a further three nested runs with logs
deliberately preserved were all **1597 / 0 with zero `FAIL` lines**), one in six
last time, so **two in fourteen across two packets** — but it is now two packets
running, and this close converted "unreproduced flake" into "flake plus a named
reason we cannot see it."

Filed as an update to `residue.md` (o).

## Open boundaries — nothing done without go

- **Nothing pushed, merged, tagged, PR'd or deployed by this close.** Local commit only.
- **No secrets touched. No `git config`.**
- `/home/user/empathiq-website` untouched, preserved at `cb2bb7d`.
- **`88052e7` and `a7ab841` are local-only** and remain so pending explicit go.
  (The branch's earlier history is already on `origin` at `6b01173` — see
  `residue.md`'s corrected open-boundaries entry.)
- **The S1 token decision and the S1 `runtimeAuthority` recommendation are
  OPERATOR decisions** and are deliberately not taken.
- **Writing the first authority envelope is an operator act.** The store ships
  empty and nothing in this packet writes to it.
- **Re-authorising or demoting any of the 19 out-of-licence controls is a
  governance action.** The matrix reports and exits 0. Nothing here performs one —
  and, per Headline 2, **nothing here CAN perform a promotion at all.**
- **Step 3 needs a class change or a different instrument**, and neither is
  designed. That is a scoping decision for the operator before the next packet is
  cut.

## Verification performed by this close

All four re-measured by the archivist on a quiet tree, after every memory write:

| Check | Result |
|---|---|
| `bash tests/build_os_tests.sh` | **1597 passed / 0 failed**, exit 0, zero `FAIL` lines |
| `bash build-os/registry/scan-controls.sh check` | **exit 0** — 81 controls / 36 surfaces; 67 load_bearing, 14 over-authorised (declared), 0 unregistered, 0 phantom, 14 rows reconciled |
| `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` | **MATCH** — `live suite total (1597 passed) matches current_state.md's claim (1597)`, **44 passed / 0 failed** (see residue item 7 for the one anomalous run) |
| `git status --porcelain` | **empty** after the close commit; before it, only the five `build-os/` paths this close wrote |

Also re-run at close: `record-packet.sh --validate` → **9 rows, 0 invalid**;
`record-packet.sh --verify-git` → **8 ok, 0 mismatched, 0 unverifiable**, with
this packet's row `VERIFIED  88052e7,a7ab841  files=12 insertions=2142
deletions=89`; `check-adoption.sh` → **exit 0**, 5 in scope, 5 recorded, 0
missing, 0 hollow.

**The metrics row's `defects_escaped` is `-`, and that is load-bearing.** The
column means *what a post-close audit finds*, and **no post-close audit has
run**. Everything caught at this packet's gates escaped the **gates**, not the
**packet** — writing a number there turns `speed_benchmark_tests.sh` red, as the
previous packet proved by doing exactly that. `rounds=7` and `agents=5` come from
the orchestrator's handoff trail and are marked **NOT WITNESSED BY THE RECORDER**
in the row's own note; `wall_min` and `serial_min` are `-`, because nobody held a
clock.

## Files written by this close — all inside `build-os/`

- `build-os/receipts/gravito_authority_envelope_a.md` *(new — this file)*
- `build-os/memory/current_state.md`
- `build-os/memory/residue.md`
- `build-os/packets/active_packet.md`
- `build-os/metrics/packet_metrics.tsv`

**Nothing outside `build-os/` was written.** Two fixes this close identified
require a lane that may write outside the archivist's gate and were **reported,
not absorbed**: the `CHANGELOG.md` line-citation policy (residue item 1) and the
`--help` `sed`-range guard (residue item 3).

---

## The close is a THIRD commit, and that is deliberate

The packet is at its **2-commit cap** (`88052e7`, `a7ab841`) and **neither was
amended by this close**. This close is a separate archivist commit on top,
matching the convention of prior closes (`77a0040 Close
gravito_evidence_policy_matrix_a: receipt + memory`; `12dbdc5 Close
gravito_census_gaps_egress_bandwidth_a: receipt + memory`). **Nothing pushed,
merged, tagged, PR'd or deployed. No guard was weakened, deleted or exempted. No
control was re-authorised. No file outside `build-os/` was written.**
