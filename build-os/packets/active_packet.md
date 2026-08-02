# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: IN FLIGHT — `PACKET-0029-citation-anchor-tokens`

- **Packet id:** `PACKET-0029-citation-anchor-tokens`

canonical packet id: PACKET-0029-citation-anchor-tokens

**EXACTLY ONE packet id is declared above**, which is what "one in flight" means
to `bandwidth.active_packet_singleton` — it counts `**Packet id:**` declarations
in this file against a ceiling of 1. The bare `canonical packet id:` line beneath
it is not a second declaration: it is the **content site** anchor `ANC-0003`
resolves to, and it is written on its own line precisely so that this packet's
own identity is reachable by content rather than by position.

**Title:** citation anchor tokens — stable semantic anchors, and the demotion of
line numbers from identity to navigation hint.

**Provenance, and it is the whole point of this packet.** The ranking was
**sealed first** (`44b0fab`, over 20 frozen v2 snapshots, rule `s1-v1`), the
**selection was recorded second** (`DECISION-0011-p5b-next-after-p3b`, selector
`operator`, `c2d97f8`), and **execution starts third**. This is the first
prospective decision in this repository with a recorded selection, so the
packet's identity is **frozen evidence**: if what executes is not the candidate
that was ranked, the measurement is void. **The scope below is the sealed
`candidate_write_surface` and nothing beyond it.**

- **Sealed signals:** `residue_items_closed=1`, `residue_ruling_satisfied=0`,
  `census_growth_controls=1`, `sealed_rank=1` (**frontier, NOT dominant** —
  `PACKET-0030` and `PACKET-0031` tie at 2 on the same frontier).
- **Frozen write surface:** `build-os/registry/scan-controls.sh`;
  `build-os/registry/control_registry.txt#registry.evidence_resolution`;
  `tests/control_registry_tests.sh#7`; `build-os/memory/residue.md`.
- **Residue consumed:** `(mm)` and `(nnn)`. **`(ddd)` STAYS QUEUED** — what it
  queues is a durable positional-content-pairing guard, which this packet does
  not build, and the asymmetry is what proved the signal was derived.
- **Ceiling:** declared mismatches **hold at 21**. No new store, no new
  validator tool, no new suite file.
- **One selected rank is not evidence of ranker skill.** It is one observation.

## Branch base

Branched at `c2d97f8` on `claude/project-handoff-merge-ramhds`, re-verified with
`git merge-base` before the first edit. **Nothing is pushed, merged, tagged, PR'd
or deployed, and no such go has been given.**

## CLOSED — `gravito_p5_outcome_counterfactual_telemetry_a`

- **Packet id (CLOSED):** `PACKET-0032-p5-outcome-counterfactual-telemetry` —
  reused, not minted; collision-checked again at close against every
  `PACKET-*` in the tree.
- **Receipt:** `build-os/receipts/gravito_p5_outcome_counterfactual_telemetry_a.md`
- **Commits:** `cda95d2` (declaration) + `44b0fab` (build) + `adef6ad` (fix
  round), base `80ad634`. **None pushed.**
- **Verdict:** **PASS-AS-FIXED.** Reviewer returned `fix-then-pass` on 3
  enumerated items; all 3 fixed and **verified live by the orchestrator** rather
  than by opening a fourth gate stage.
- **Depth: 3 serial stages** — builder; qa ‖ reviewer concurrently; fix round.
  **No stage 4.** 3 commits is **one over the `<=2` cap** and is recorded as a
  deviation, not normalised.
- Suite **1909 → 1963** (+54, all in `tests/mutator_registry_tests.sh` section 14);
  census **99 → 100**; declared mismatches **20 → 21**; out-of-licence **25 → 26**;
  snapshots **72 → 97 by row count**; decisions **10, unchanged**; **zero
  re-authorisations**.
- **`44b0fab` IS THE SEAL'S ANCHOR AND MUST NOT BE AMENDED.** The prospective
  ordering's whole claim is that it was committed before any commit could carry a
  selection.
- **P5 OF THE OPERATOR'S FIVE — AND THE LAST OF THEM. THE SEQUENCE IS COMPLETE.**

## THE ENFORCEMENT AS IT ACTUALLY STANDS — corrected at close

**THIS SECTION IS THE ARCHIVIST FIXING A DEFECT IN THIS FILE.** The in-flight
version described **three** refusals and **never mentioned the fix round**,
because it was written at `cda95d2` — before the build, and two commits before the
reviewer found the hole. **A packet artefact left describing its own pre-build
plan is stale documentation of live enforcement**, which is the same shape as
every other stale-restatement defect this tree tracks. The list below is
**derived from the tool**, not remembered.

**The three the build commit named — the order refusals:**

- `RANKING-AFTER-SELECTION` — `seal-ranking` refuses while the decision already
  carries a SELECTION row.
- `SET-CHANGED-AFTER-SEAL` — `record` refuses a selection over a candidate set the
  sealed ordering never ranked.
- `OUTCOME-BEFORE-SELECTION` — `outcome` refuses while the decision has no
  SELECTION row.

**The partition refusals, which the same build shipped and the summary undersold:**

- `OUTCOME-FIELD-IN-SELECTION`, `SELECTION-FIELD-IN-OUTCOME` — neither write path
  may reach the other's columns.
- `RANKER-FIELD-IN-SELECTION`, `RANKER-FIELD-IN-OUTCOME` — the six ranker-evidence
  fields own **no column** and are refused by **both** paths. **12 / 12 refusals.**
- `ORDERING-SET-MISMATCH`, `OUTCOME-OVERWRITE`, `TIMESTAMP-CONTRADICTS-ORDER`.

**AND THE TWO THE FIX ROUND ADDED, WHICH THIS FILE OMITTED ENTIRELY:**

- **`RANKER-FIELD-VIA-SNAPSHOT` — the headline defect.** `seal-ranking`'s guard
  reads `decision_telemetry.tsv`, but the field it protects (`sealed_rank`) lives
  in `signal_snapshots.tsv`, and the generic `snapshot` writer accepted **any**
  `--signal-name`. **TWO STORES, ONE GUARDED.** The reviewer's executed
  reproduction wrote a `sealed_rank` row for the already-selected
  `DECISION-0010`; it **chained cleanly**, `snapshot-verify` reported 98 rows
  verifying, and `prospective_decisions_with_a_recorded_selection` moved **0 → 1**
  — **leaving no trace at all**, unlike the disclosed delete-and-re-add route
  which breaks a digest and *is* evident. The refusal is keyed on the tool's own
  `RANKER_FIELDS` constant, so **a seventh ranker field declared later is closed
  by the same line**.
- **`CANDIDATE-RANKED-TWICE`.** An ordering giving one candidate two ranks was
  accepted: only `rank=1` entered the digest chain while the printed
  `sealed_ordering:` echoed the contradiction back, so **the receipt and the
  chained evidence described different orderings**. Refused during the parse,
  before any append.

**The perimeter statement was WRONG, not merely incomplete, and was corrected:
the perimeter is the TOOL, not the files.**

## Staged next — `gravito_p3b_count_derivation_a` (`PACKET-0027`)

**NOT A NEW SELECTION.** `DECISION-0010` selected
`PACKET-0027-p3b-count-derivation` at `5c8d19e`, **before S1 existed**, and that
selection stands. Its telemetry row carries `result: in_flight`. It has been
staged and unstarted since the P3 close, and this close does not change its
status — it records the outcome slot for the decision that selected it, and does
not do the work.

**Still not started. Still the standing next packet. Declaring it is the
orchestrator's act.**

## Sealed but NOT selected — `DECISION-0011-p5b-next-after-p3b`

**THE DECISION AFTER `p3b`. NOBODY HAS SELECTED, AND THE ABSENCE IS THE
EVIDENCE.** Sealed at `80ad634`, rule `s1-v1`, over 20 frozen v2 snapshots, with
**no row in `decision_telemetry.tsv`** — `grep -c '^DECISION-0011'` returns **0**.

```
excluded PACKET-0033-observe-advise-boundary-recheckable  reason=self_amendment
rank 1  PACKET-0029-citation-anchor-tokens            total=4  pareto=frontier
rank 2  PACKET-0030-mutation-census-coverage-gap      total=3  tie=yes  frontier
rank 2  PACKET-0031-governance-baseline-completeness  total=3  tie=yes  frontier
rank 4  PACKET-0028-positional-content-pairing-guard  total=1  dominated_by=PACKET-0029
```

**IT IS NOT DEGENERATE — 3 of 4 rankable candidates sit on the Pareto frontier**,
against `DECISION-0010`'s single dominator that 125 of 125 weightings returned.
**Weights would change this ordering; that is the first time it has been true.**
The candidate set is **mechanically derivable, not curated**: `DECISION-0010`'s
set minus the winner minus this packet.

**SELECTING FROM IT IS AN OPERATOR ACT AND NOTHING HERE PERFORMS ONE.** A
selection recorded by any agent moves
`prospective_decisions_with_a_recorded_selection` from 0 to 1 with **no human
having chosen** — the exact figure the reviewer's reproduction exploited — and
**destroys the thing the packet built.** The ordering exists precisely so a later
human choice can contradict it.

**And what it delivers is bounded, per residue `(hhhh)`:** *"a decision that CAN
falsify S1, not a decision that has."* Non-degeneracy is **one observation, not a
result** — the 20 evidence snapshots were hand-assigned by the same builder in the
same commit.

## Explicitly NOT staged, and deliberately open

- **`s1-v2` / any signal-set redesign.** The degeneracy, the
  lettering-granularity margin, the non-independence and the label leakage stay as
  residue `(xxx)` / `(yyy)`.
- **Widening guard 1's `PROTECTED_SURFACE`** to the evidence substrate, or closing
  the directory-prefix alias. Both deliberately open. Residue `(zzz)`.
- **Fixing `(cccc)`'s digest claim.** `build-os/metrics/rank-candidates.sh` is
  **guard 1's own protected surface**; editing it inside a packet that seals a
  ranking is precisely the self-amendment guard 1 exists to prevent.
- **A 22nd declared mismatch.** The reviewer's ruling on the 20 → 21 exception:
  principled, but **"the last one waved through on this reasoning." P6 should hold
  at 21.**
- **P6 itself.** It is not defined, and it is not the archivist's to define.

## Open boundaries carried forward

- **Nothing is pushed, merged, tagged, PR'd or deployed.** The base `80ad634` is
  on `origin`; the branch is **ahead 3** and those three commits stay local
  pending explicit go.
- **AND THE UNPUSHED STATE NOW CARRIES EVIDENTIARY WEIGHT, WHICH IT DID NOT
  BEFORE.** The parent-hash chain is non-forgeable **only once a third party has
  witnessed it** — so publishing is what converts the seal's anchor from *"one
  process could rewrite this"* into *"a third party has seen it."* A push would
  now buy something specific. **It is still an operator act and it is not
  requested here.** Residue `(kkkk)`.
- **Nothing consumes S1's ordering**, and wiring anything to it is an operator act.
- **Second eyes: still NONE**, **eleven** packets running — the whole five-phase
  sequence is single-model. Residue `(zz)`. The router's own counter still says
  *nine*; the remedy is one builder-lite line and the archivist did not apply it.
