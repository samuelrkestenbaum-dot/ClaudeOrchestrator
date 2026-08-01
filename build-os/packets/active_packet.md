# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: NONE IN FLIGHT

`gravito_p4_s1_shadow_ranker_a` is **CLOSED**. Nothing is in flight. The packet
staged below is **staged, not started**, and awaits an explicit go like any
other.

## Just closed — `gravito_p4_s1_shadow_ranker_a`

- **Packet id:** `PACKET-0034-gravito-p4-s1-shadow-ranker-a`
  — derived from this file's own declaration at `9742a10` and **collision-checked
  against every `PACKET-*` in the tree before it was written down**.
  `decision_telemetry.tsv` allocates `PACKET-0007`..`PACKET-0033` and nothing
  else. The P3 close is why this check exists.
- **Receipt:** `build-os/receipts/gravito_p4_s1_shadow_ranker_a.md`
- **Commits:** `9742a10` (declaration) + `af4ce0c` (build) + `b9896e0` (fix
  round), base `ce71122`, re-verified with `git merge-base`. **None pushed.**
- **Verdict:** PASS-AS-FIXED. qa GREEN; reviewer fix-then-pass, all items fixed
  and orchestrator-verified. **Depth: 3 serial stages, no stage 4.**
- **Success condition MET:** a real candidate set went in and an immutable
  explained ordering came out —
  `ranking_digest: 2fa876c632bf81088793968a5d76501556fe283dc27ff97aad40459218df81c8`,
  reproduced byte-identically before and after the fix round and again at close.
- **And the honest half:** the first ordering is **degenerate** — the rank-1
  candidate Pareto-dominates every rival under all 125 weight combinations — so
  **the executive exists as a MECHANISM before it exists as a DEMONSTRATED
  CAPABILITY.** Residue `(www)`–`(zzz)`.
- Suite **1869 → 1909**; census **97 → 99**; `observe` gains its **first
  occupant ever**; snapshots **44 → 72**; **zero re-authorisations**.

## Staged next — `gravito_p3b_count_derivation_a` (NOT STARTED)

**This is `PACKET-0027-p3b-count-derivation`, the candidate S1 independently
placed at rank 1 in `DECISION-0010`, and it was selected — by the reviewer, at
the P3 close — BEFORE S1 EXISTED. That ordering is what makes
`rank_of_selected: 1` non-circular; it is not a reason to start the packet.**

Its contents are the five open items `(hhh)`–`(lll)`: the false coverage claim in
the arrow-pair test; the corrected-headline/uncorrected-body count in
`control_registry.txt`; the `homeostasis` binding count in the crosswalk; the
governance store that misdescribes its own validator; and the false
"matches-by-accident" claim with its reproduction.

**The P4 close adds a sixth, live instance of exactly this defect class** — the
signal-snapshot count reported as the store's line count at two consecutive
closes, residue `(aaaa)`. **The durable fix both it and `(ooo)` name is the same
one: a guard that DERIVES a store's cardinality rather than comparing two
remembered copies of it.** Nothing has built it.

## Explicitly NOT staged

- **`s1-v2`.** The signal set's four recorded defects — degeneracy, the
  lettering-granularity margin, the non-independence of two signals, and the
  label leakage in `residue_ruling_satisfied` — are **not** to be fixed in a fix
  round or folded into another packet. The operator's ceiling reasoning applies
  to S1's own shortcomings exactly as it applies to governance defects.
- **Widening guard 1's `PROTECTED_SURFACE`** to the evidence substrate, or
  closing the directory-prefix alias. Both are deliberately open: widening turns
  the predicate into a wall, and treating a directory as covering its contents
  would **move the live `DECISION-0010` ordering the non-circularity proof is
  anchored to**. Residue `(zzz)`.
- **P5 (outcome / counterfactual telemetry).** It is the next phase, not the next
  packet, and it is `PACKET-0032` — a candidate S1 **excluded from its own
  ordering** as `self_amendment`. That exclusion is correct and stands.

## Open boundaries carried forward

- **Nothing is pushed, merged, tagged, PR'd or deployed.** Everything through
  `ce71122` is on the remote; this packet's three commits and its close commit
  are not, and stay that way pending explicit go.
- **Nothing consumes S1's ordering**, and wiring anything to it is an operator
  act. S1 holds `runtime_authority: observe` and its own `promotion_requirement`
  turns on `rank_of_selected` history that does not yet exist at any useful n.
- **Second eyes: still NONE**, ten packets running. Residue `(zz)`.
