# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: IN FLIGHT — `gravito_p5_outcome_counterfactual_telemetry_a`

- **Packet id:** `PACKET-0032-p5-outcome-counterfactual-telemetry` — **not a new
  allocation.** It is the id `DECISION-0010` already carries for this work, and
  it was collision-checked against every `PACKET-*` in the tree before being
  reused: `decision_telemetry.tsv` allocates `PACKET-0007`..`PACKET-0033`,
  `active_packet.md` allocated `PACKET-0034` at the P4 close, and nothing else
  exists. Minting a fresh id here would have put two candidates under one key
  inside the store S1 trains on, which is the P3 close's defect exactly.
- **Base:** `80ad634`, verified with `git merge-base` before the first edit.
- **Lane:** `substantive`. **Depth 2** — builder, then qa ‖ reviewer.
- **Declared before building**, in its own commit, per the standing contract.

## What this packet must make true

```
P4:  decision already made      -> S1 reconstructs a ranking   (retrospective)
P5:  S1 ranks FIRST -> human chooses -> outcome occurs -> comparison possible
```

**`ranking timestamp < selection timestamp < execution timestamp`, MECHANICALLY
ENFORCED.** A comment saying so is not enforcement and a field recording it is
not enforcement. Enforcement is a **refusal, in code, driven red by a fixture
that fails when the order is violated.**

**And the ordering evidence must be honest about itself.** A timestamp that
*parses* is not a timestamp that *proves ordering*; self-reported times written
in one commit by one author prove nothing about sequence. P4's own
non-circularity rests on git commit times across three commits, not on a field
anyone typed. What is constitutive here is the **existence order of a row across
two stores at the instant of each write**; the ISO-8601 strings are
**corroborating only**, checked because a contradiction is always wrong and never
because agreement is proof.

## Two arms, against two different decisions, kept structurally apart

Conflating them would recreate the post-hoc problem under a new name.

- **OUTCOME ARM — `DECISION-0010` / `PACKET-0027-p3b-count-derivation`.** Its
  selection is frozen and permanently retrospective (`5c8d19e`, before S1
  existed). Record the outcome fields against it, and leave every field that is
  not measurable **explicitly missing, in a named category** — never defaulted,
  never imputed, never dropped.
- **PROSPECTIVE ARM — `DECISION-0011-p5b-next-after-p3b`, the decision AFTER
  `p3b`.** Emit and **seal** an S1 ordering over that candidate set **before any
  human selects**, so that when the selection later happens `ranking < selection`
  is provable rather than asserted. This is the arm that converts
  `rank_of_selected` from an observation into evidence.

**S1 CANNOT RANK THIS PACKET AND MUST NOT BE MADE TO.** `DECISION-0010` records,
live, `excluded PACKET-0032-p5-outcome-counterfactual-telemetry
reason=self_amendment`. Guard 1 is working correctly. Weakening it to rank this
packet would be the precise thing guard 1 exists to prevent.

## The separation that must not collapse

> Discovering that the candidate was important is evidence about the CANDIDATE,
> not yet evidence that S1 ranked it for the right reasons.

It must be **impossible to read** "the selected packet turned out well" as "S1
ranked correctly", and that has to be structural rather than editorial. And there
is to be **no automatic interpretation of agreement as correctness**: rank 1
equalling the human's pick is one observation, and the tooling says so.

## Address list — the write surface this packet declares

- `build-os/metrics/record-decision.sh`
- `build-os/metrics/decision_telemetry.tsv`
- `build-os/metrics/signal_snapshots.tsv`
- `tests/mutator_registry_tests.sh#14`
- `build-os/registry/mutator_registry.txt`
- `build-os/registry/control_registry.txt#metrics.decision.outcome_update`
- `build-os/registry/neurocosmology_crosswalk.txt#metrics.decision.outcome_update`
- `build-os/registry/MISMATCHES.md`
- `build-os/registry/CROSSWALK.md`
- `build-os/registry/README.md`
- `build-os/memory/current_state.md`
- `build-os/memory/residue.md`
- `build-os/packets/active_packet.md`
- `CHANGELOG.md`

**`build-os/metrics/rank-candidates.sh` IS NOT ON THIS LIST AND WILL NOT BE
TOUCHED.** The frozen `SIGNAL-SNAPSHOT-0065-p5outcome-surface` says it would be —
that snapshot is **evidence and stays as it is**; a frozen signal is not
corrected by what later happened, and the exclusion it produced stands either
way. It is recorded here that the frozen surface OVERSTATES the actual one, which
is the safe direction for a fail-closed guard to be wrong in.

## The ceiling — in force

- **No new governance primitive** unless a failing fixture proves necessity.
- **No new store.** `decision_telemetry.tsv` and `signal_snapshots.tsv` exist; a
  new one needs an executed fixture showing the substrate cannot hold the data,
  not an argument that a new file would be tidier.
- **No signal-set redesign.** `s1-v2` is not this packet. The degeneracy, the
  lettering-granularity margin, the non-independence and the label leakage stay
  as residue `(xxx)`/`(yyy)`.
- **No promotion.** S1 stays Class C / `untested` / `observe` / `shadow`.
- **No dispatch.**
- **Defects found are recorded as residue and NOT fixed.** If every defect is
  promoted ahead of the work, the work never arrives.

## Just closed — `gravito_p4_s1_shadow_ranker_a`

- **Receipt:** `build-os/receipts/gravito_p4_s1_shadow_ranker_a.md`
- **Commits:** `9742a10` + `af4ce0c` + `b9896e0`, base `ce71122`. **None pushed.**
- **Verdict:** PASS-AS-FIXED. Depth 3, no stage 4.
- Suite **1869 → 1909**; census **97 → 99**; snapshots **44 → 72**; `observe`
  gained its first occupant ever; **zero re-authorisations**.
- **The honest half:** the first ordering is **degenerate** — the rank-1
  candidate Pareto-dominates every rival under all 125 weight combinations — so
  the executive exists as a MECHANISM before it exists as a DEMONSTRATED
  CAPABILITY. Residue `(www)`–`(zzz)`.

## Explicitly NOT in this packet

- **`s1-v2`.** The signal set's four recorded defects are not to be fixed in a fix
  round or folded in here.
- **Widening guard 1's `PROTECTED_SURFACE`** to the evidence substrate, or closing
  the directory-prefix alias. Both deliberately open. Residue `(zzz)`.
- **`gravito_p3b_count_derivation_a`** (`PACKET-0027`). Still staged, still not
  started. This packet records the OUTCOME slot for the decision that selected
  it; it does not do the work.

## Open boundaries carried forward

- **Nothing is pushed, merged, tagged, PR'd or deployed.** Everything through
  `80ad634` is on the remote; this packet's commits are not, and stay that way
  pending explicit go.
- **Nothing consumes S1's ordering**, and wiring anything to it is an operator
  act.
- **Second eyes: still NONE**, eleven packets running. Residue `(zz)`.
