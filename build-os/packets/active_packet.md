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

- **Sealed signals — RESOLVED FROM THE SNAPSHOT STORE, NOT REMEMBERED:**
  `residue_items_closed=2`, `residue_ruling_satisfied=0`,
  `census_growth_controls=1`, `sealed_rank=1` (**frontier, NOT dominant** —
  `PACKET-0030` and `PACKET-0031` tie at 2 on the same frontier). The derivation,
  written down so the next reader resolves it rather than copies this line:
  `awk -F'\t' '$1=="SIGNAL-SNAPSHOT-0078-anchors-items"{print $6" = "$7}'
  build-os/metrics/signal_snapshots.tsv` → `residue_items_closed = 2`.
- **AND THAT DIGIT WAS WRONG IN THIS FILE UNTIL THE FIX ROUND, WHICH IS THE VERY
  DEFECT CLASS THIS PACKET EXISTS AGAINST.** From its first commit this file
  declared `residue_items_closed=1`. **It was not a typo and it was not the
  builder's arithmetic: the orchestrator's brief stated `1` and this file
  INHERITED it.** That is `DEFECT-0002-stale-remembered-count`, committed in the
  one artefact that says *"the scope below is the sealed
  `candidate_write_surface` and nothing beyond it"* — the place a number must be
  **resolved and not remembered** — and inside a brief whose own instruction was
  *"DERIVE every count; never restate one."* **THE WORK MATCHED THE SEALED 2 AND
  ONLY THE RESTATEMENT WAS WRONG:** both `(mm)`
  (`build-os/memory/residue.md:645`) and `(nnn)`
  (`build-os/memory/residue.md:1064`) carry their annotations, and the snapshot's
  own `evidence_refs` field names exactly those two items and says in the same
  breath why `#rrr` and `#bbbb` were **not** counted. The provenance is recorded
  here rather than the digit quietly overwritten: a count that arrives by
  inheritance and is repaired by overwriting leaves no trace of how it got in,
  and the trace is the only part of this that generalises.
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

## Fix round — stage 3, bounded to 7 enumerated items

**qa returned GREEN and the reviewer returned `fix-then-pass` on 7 items, every
one of them a TEXT OR RECORD correction.** No code changed, no test changed, and
no measurement was re-run beyond the targeted commands written out below. This
takes the packet to **3 commits, one over the `<=2` cap**, recorded as a
deviation and not normalised. `df9f740` and `c76b4d0` are **not** squashed,
amended or rewritten.

**The outcome numbers, DECOMPOSED rather than asserted — guard 2's rule applied
to this packet's own record.** `rework_count` was going to be reported as **2**,
and that is not defensible against this packet's own disclosures. The components
are published so a reader can recompute the total instead of trusting it:

| component | count | disclosed at |
|---|---|---|
| off-surface artefacts the census entry mechanically forced | 4 | residue `(pppp)` |
| `evidence_ref` repoints | 3 | residue `(qqqq)`, and the two other `control_registry.txt` entries named below |
| net-zero edits made only to avoid moving a line | 6 | residue `(qqqq)` |
| **total** | **13** | |

**The builder's prose was more honest than the builder's count**, which is the
whole finding: the four artefacts, the three repoints and the six net-zero edits
were each written down plainly in `residue.md` and then summed to 2. The
definition of "rework" in `build-os/metrics/COMPARISON_PROTOCOL.md` is
pass-level, not artefact-level, which is exactly why the decomposition is
published here and not only the total — a single number under a contested
definition is the thing this repository keeps catching.

**`fix_rounds` and `review_rounds` are DELIBERATELY UNFROZEN.** They are not
final until this round and the re-review land, and writing `0` now would freeze a
value that is already false. No outcome row is written for `DECISION-0011`:
`build-os/metrics/decision_telemetry.tsv` and
`build-os/metrics/signal_snapshots.tsv` are the live experiment and this round
does not touch either.

**The two gate numbers, each with the exact command beside it, because the labels
were ambiguous:**

- `bash tests/build_os_maintenance_tests.sh` → **67 passed, 0 failed**, exit 0.
- `bash build-os/maintenance/run-tests.sh` → **144 passed, 0 failed** (`# tests
  144`, `# pass 144`, `# fail 0`), exit 0.
  **"maintenance 144/144" names the SECOND harness and never the first.** Both
  are green; the single label covering two harnesses is what is fixed here.

- **Snapshot chain verification — the recorded invocation did not exist.**
  `bash build-os/metrics/rank-candidates.sh snapshot-verify` returns
  `s1: REFUSED — unknown command "snapshot-verify"` at **exit 2**;
  `snapshot-verify` is a **`record-decision.sh`** subcommand. The working command
  is `bash build-os/metrics/record-decision.sh snapshot-verify` → **97 snapshots
  verify** against the digest chain, exit 0.

**Items 2, 3 and 7 landed outside this file** and are recorded where they were
wrong: `(pppp)`'s false guard-1 sentence and the frozen surface's stripped object
scopes in `build-os/memory/residue.md`; rule 3's over-broad receipt-facing
wording in `CHANGELOG.md`.

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
