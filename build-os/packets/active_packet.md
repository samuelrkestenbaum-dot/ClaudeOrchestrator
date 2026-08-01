# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: NO PACKET IN FLIGHT

`gravito_authority_envelope_a` closed **2026-08-01** — receipt at
`build-os/receipts/gravito_authority_envelope_a.md`, commits `88052e7` +
`a7ab841`, base `77a0040`, verdict **pass as fixed**. Suite **1597 passed / 0
failed**; census **81 controls**; `19 of 81 out of licence`, split 6/5/8 —
**unmoved** by the new axis, which is the correct result for an instrument that
ships with **0 live grants**.

Zero declared packet ids is a **legitimate idle state** —
`bandwidth.active_packet_singleton` enforces *at most one*, not *exactly one*.
No `**Packet id:**` line appears below on purpose.

### THIS FILE WAS NEVER SET FOR THE PACKET THAT JUST CLOSED — and it has NOT been back-written

`gravito_authority_envelope_a` was built, gated, fixed, re-reviewed and closed
while this file read **NO PACKET IN FLIGHT**. The orchestrator dispatched the
builder without ever declaring the packet here. That is a **process defect the
orchestrator owns**, and it is recorded in the receipt and in `residue.md` (u).

**The reviewer ruled: do not back-write this file.** Writing the packet in after
the fact would manufacture an artefact stating that a packet was declared when it
was not — precisely the falsehood that packet's own envelope store avoids by
keeping its worked example inside `#` comments. **So the record stands.** This
paragraph is the true history; the absence above is not an oversight to be
tidied.

**The gap it exposes:** `bandwidth.active_packet_singleton` refuses **two**
declared packets but permits **zero**, so an entire packet — two commits, +2142
lines, three new registered controls — was built with no declared packet and the
control passed clean. This is `residue.md` (c)'s disclosed "delete the file
evades it" hole **in a strictly worse form**: the delete branch needs an
affirmative destructive act, while this one **fires on pure omission**.

## No next packet is staged

Nothing is staged. **The next move is an operator decision, not a build**, and
staging a packet here would imply the decision had been taken.

### THE DECISION THAT NOW BLOCKS THE MOST — step 3 cannot be done with the instrument that was built for it

The plan was: build the authority envelope (step 2), then apply promotion and
demotion rules to the fourteen declared mismatches (step 3). **Step 2 shipped and
step 3 is now proven not to work that way.**

The reviewer wrote a well-formed operator grant of `gate` to
`adoption.lane_size_check` — the most obvious first use — and got:

```
OVER-GRANTED … granted=gate l-class=advise l-effective=advise binding-axis=class
```

with `evidence-policy.sh`'s nineteen finding lines **byte-identical** against an
empty store. **`L_effective = min(...)` means an envelope can only ever LOWER the
result.** It is a ceiling the operator volunteers, never a floor the operator
buys. The tool **refuses to launder a Class-C gate even when the operator signs
off** — correct, and arguably the best property in the packet.

**But all fourteen mismatches exercise MORE authority than their class licenses,
and an envelope only subtracts.** Step 3 needs **a class change or a different
instrument**, and neither is designed.

> **Do not cut a packet that writes envelopes to fix mismatches. It will not
> work, and it has already been proven not to work.**

### Still blocking, carried from the previous close — the S1 decisions

None of these is taken:

1. **`untested` is not one of the five evidence tokens.**
   `evidence.derivation_nonvacuity` (Class A, gate) **refuses the entire
   derivation at exit 2** on an unrecognised token. §18 of
   `tests/authority_envelope_tests.sh` declares `untested` **pending, declared,
   and not implemented**. The operator adds a sixth token with its own cap, or
   S1 arrives carrying `unvalidated`.
2. **Which S1 reading, if either, the ladder adopts.** Both are recorded and
   **neither is adopted**; §17 fails with `reading 2 has been silently adopted —
   shadow now licenses rank, which redefines the ladder`.
3. **The reviewer's recommendation — ADVICE, NOT ADOPTED.** The S1 collision is
   not a deployment-axis problem at all: `heuristic_policy` is Class C, so
   `L_class = advise` and `rank > advise`, and **the minimum is capped before the
   deployment term is consulted** — `shadow`'s cap could be `gate` and S1 would
   still be out of licence. The reviewer recommends S1 declare
   `runtimeAuthority: observe` with a note that its **signal** is rank-shaped,
   keeping `runtime_authority` = permitted consequence and `deployment_mode` =
   whether anything consumes it. **This is the operator's call and nothing has
   adopted it.**

## Candidates the orchestrator may cut from

Ranked by value per line, from `build-os/memory/residue.md`:

1. **Stop creating `CHANGELOG.md` line-citations, and re-cite the two live ones
   by release-block heading** (`residue.md:280`,
   `receipts/gravito_evidence_policy_matrix_a.md:572-573`). Residue **(r)**.
   Cheapest item here and the only one that closes a **guaranteed** decay rather
   than an occasional one: the changelog grows from the top, so every line
   citation into it is invalidated by every future packet. Needs a lane that may
   write `build-os/receipts/` and `build-os/memory/` only — no file outside
   `build-os/` is involved.
2. **A checker for prose that restates a machine-computed table** — four packets
   running, residue **(m)/(s)**. **§2a of `tests/authority_envelope_tests.sh` is
   now the strongest pattern to copy**: it pins an axis's declared **OWNER**, not
   just its copy, in both directions with a non-vacuity floor on both sides.
   `MISMATCHES.md` has carried a stale line reference in **six consecutive
   packets** and §10's table names its own decay mode in prose.
3. **`authority-envelope.sh`'s `--help` `sed -n '2,196p'` range**, duplicated
   across two handlers (`:235`, `:245`). Residue **(t)**. When stale it
   **silently truncates instead of failing**, and nothing tests it — the worst
   shape a hand-maintained line number can have.
4. **Chain `RELEASE_METADATA_LIVE_SUITE=1`** — residue **(x)/(g)/(n)**. It is the
   **only** check in the repo that compares memory against a live run, it is
   still opt-in, and it is the sole reason the 1485 → 1597 pair was caught.
5. **Assert a declared packet EXISTS while a packet is in flight** — residue
   **(u)/(c)**. A floor, not a ceiling.
6. **`tests/entitlement_tests.sh:296-305`'s hardcoded 12-file `PACKET_FILES`
   list** — residue **(b)**; two more files behind after this packet.
7. **`swarm-merge.sh` glob-overlap false negatives** (`src/*.ts` vs `src/foo*`) —
   residue **(a)**. CLAUDE.md's fan-out gate rests on this check.
8. **Align `tests/evidence_policy_tests.sh:322`'s §5b non-vacuity floor** to
   §2a's stronger form — residue **(v)**. **NON-BLOCKING: the reviewer flagged it
   and explicitly passed it.** §2a covers the same axis with the stronger form,
   so it is not a live hole. Do it when that file is next open for another
   reason; **do not cut a packet for it.**

**Closed at the last close, not carried:** the `1485 → 1597` suite-count pair
(`current_state.md` now reads 1597 and `CHANGELOG.md:32` already carried the
matching literal; `RELEASE_METADATA_LIVE_SUITE=1` verified as a MATCH at close).

**Blocked on the operator, not schedulable:** writing the first authority
envelope; re-authorising or demoting any of the 19 out-of-licence controls,
including `maint.tripwire_coverage_scan` — **no longer blocked on the
instrument**, which now exists and *can* express that demotion, but blocked on
the **authorisation**, which is not a builder's to give.

## A process note for the next dispatch

**Set this file before dispatching the builder.** The last packet proves the
control will not catch you: it refuses two declared packets and permits zero.

---
_Cleared by the archivist at close of `gravito_authority_envelope_a` (2026-08-01).
The packet itself was never declared here and has deliberately **not** been
back-written — see the status section above and `residue.md` (u)._
