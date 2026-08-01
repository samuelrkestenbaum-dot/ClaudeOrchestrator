# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: NO PACKET IN FLIGHT

`gravito_mismatch_refuted_a` is **CLOSED** (2026-08-01) — receipt
`build-os/receipts/gravito_mismatch_refuted_a.md`, commits `b25f3f7` + `566443f`,
base `c52915f`, verdict **pass as fixed** (reviewer `fix-then-pass` twice, qa
GREEN).

**Its result, in one line:** it was **authorised to re-authorise two controls and
changed nothing**, because the prescribed demotion of
`maint.tripwire_coverage_scan` was **measured** to destroy live memory at the same
exit code as the gated arm. `evidence-policy.sh check` is **19 of 81, split
6/5/8 — UNMOVED**, which is the correct census for a packet that re-authorised
nothing.

No packet is staged. Three operator decisions block the obvious next cuts — see
`build-os/memory/current_state.md` → *Where we are*, and `residue.md` items
(bb), (cc), (dd).

---

## THIS PACKET DID DECLARE ITSELF BEFORE BUILDING — and git cannot attest it

Recorded because the *previous* packet did not, and the difference matters.

`gravito_authority_envelope_a` was built, gated, fixed, re-reviewed and closed
while this file read **NO PACKET IN FLIGHT** (`residue.md` item **u**). The
reviewer ruled that file must **not** be back-written, and it was not.

`gravito_mismatch_refuted_a` **wrote its declaration here before the builder's
first edit.** But **the reviewer observed that the declaration landed in the same
commit as the build** — `b25f3f7` touches `build-os/packets/active_packet.md`
alongside `scan-controls.sh`'s `OBSERVE-LB` guard and the two test sections — so
**git cannot attest the ordering.** The claim is true; git simply cannot
corroborate it.

**The `≤2-commit` rule and "declare before building" are in genuine tension.**
Attesting the ordering needs **a third commit or a pre-commit hook**, and the
packet is capped at two commits.

**That is an OPERATOR DECISION and this close deliberately does not resolve it.**
Filed as `residue.md` item **(ee)**.

**The underlying gap is still open**: `bandwidth.active_packet_singleton` refuses
**two** declared packets but permits **zero**, so the control passes clean on pure
omission. The floor — *assert a declared packet EXISTS while a packet is in
flight* — is still unbuilt and still on the candidate list
(`residue.md` items **c** / **u**).
