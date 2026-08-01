# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: NO PACKET IN FLIGHT

`gravito_evidence_policy_matrix_a` closed **2026-07-31** — receipt at
`build-os/receipts/gravito_evidence_policy_matrix_a.md`, commits `105cb75` +
`0555717`, base `6b01173`, verdict **pass as fixed**. Suite **1485 passed / 0
failed**; census **78 controls**; `19 of 78 out of licence`, reported at
`advise`, re-authorising nothing.

Zero declared packet ids is a **legitimate idle state** —
`bandwidth.active_packet_singleton` enforces *at most one*, not *exactly one*.
No `**Packet id:**` line appears below on purpose.

## No next packet is staged

Nothing is staged, because **the next move is an operator decision, not a build**.
Staging a packet here would imply the decision had been taken.

### The decision that blocks step 2 — S1's evidence token

S1 is slated to arrive at `runtimeAuthority: rank` with
`empiricalStatus: untested`. Two collisions with what just shipped:

1. **S1 at `rank` on unvalidated evidence ships out of licence on day one.**
   Survivable — the matrix only advises. It would appear as a 20th finding.
2. **`untested` is not one of the five evidence tokens**, so
   `evidence.derivation_nonvacuity` (**Class A, gate**) **refuses the entire
   derivation at exit 2** rather than flagging S1 — an unrecognised level must
   never fall through to permissive. Reproduced independently at close by
   injecting the token: `UNREADABLE … has no cap on the evidence axis` /
   `REFUSED`, **exit 2**.

**The operator chooses one:** add `untested` as a sixth token with its own cap,
**or** have S1 arrive carrying `unvalidated`. Adding a token *purely to make a
planned control fit* is the failure mode the registry exists to prevent, so this
is governance, not mechanics. **Neither move has been taken.**

## Candidates the orchestrator may cut from, once that is answered

Ranked by value per line, from `build-os/memory/residue.md`:

1. **A checker for prose that restates a machine-computed table** — §5a of
   `tests/evidence_policy_tests.sh` is the pattern to follow. Highest value per
   line of the open follow-ons, and the **only** one of these that closes a
   *class* rather than an instance. Every instance so far has been caught by a
   human read after a gate missed it.
2. **Enable the staleness check that actually works** —
   `RELEASE_METADATA_LIVE_SUITE=1` is still opt-in and still not chained. It is
   the check that caught the 1485 token; the chained suite still cannot.
3. **`swarm-merge.sh` disjointness false negatives**; **`entitlement_tests.sh`'s
   decaying 12-file `PACKET_FILES` list**.

**Closed in the close commit, not carried:** the four stale `75` sites
(`CROSSWALK.md:8`, `:25`, `:39`, `neurocosmology_crosswalk.txt:169` — all now
**78**; `control_registry.txt:1464` judged historical and left) and the
`1485 passed` literal in `CHANGELOG.md` plus the `current_state.md` token.

**Blocked on the operator, not schedulable:** re-authorising or demoting any of
the 19 out-of-licence controls, including `maint.tripwire_coverage_scan` (now
flagged by both axes). The matrix reports and exits 0; nothing performs a
governance action.

---
_Cleared by the archivist at close of `gravito_evidence_policy_matrix_a`. The
archivist's close was interrupted by a container restart before it verified
anything; the close was resumed and verified in a separate commit — see the
addendum in `build-os/receipts/gravito_evidence_policy_matrix_a.md`._
