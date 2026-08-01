# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: IN FLIGHT

- **Packet id:** `gravito_mismatch_refuted_a`
- **Lane:** substantive — builder → qa → reviewer → archivist
- **Declared:** 2026-08-01, **before** the builder's first edit (see the process
  note below — this is the fix for the defect the last packet exposed).

## Branch base

Branch `claude/project-handoff-merge-ramhds`, based at `c52915f` — the close of
`gravito_authority_envelope_a`. Verified by `git merge-base` before building:
`merge-base == HEAD == c52915f` at declaration time. **`c52915f` is pushed.**

## Scope — the two REFUTED controls, and nothing else

Step 3 of the operator's sequence, **first and narrowest cut**. `refuted` means
*measured and found not to discriminate* — the only evidence state where the
question is already settled, which is why it goes first.

1. **`maint.tripwire_coverage_scan`** — `red_driven,refuted`, Class C, runtime
   authority `gate`, `authority_mismatch: declared`. MISMATCHES §8, *"the control
   that documents its own defeat"*.
2. **`maint.source_scan_mask`** — `refuted`, Class C, runtime authority `advise`.
   Carries **no** declared mismatch (Class C licenses `advise`), so the class
   axis is structurally blind to it; it is visible only on the evidence axis,
   where `refuted` caps at `observe`.

**Out of scope and not to be touched:** the other 13 declared mismatches, the 4
Class-A-gate-on-`unvalidated` findings, and the `untested` token (the operator
has ruled it a distinct state licensing `observe` only — a **separate packet**).

## The operator's ruling — the frame

Each mismatch resolves to exactly one of four outcomes: **(1)** demote runtime
authority, **(2)** correct the control class with an explicit argument,
**(3)** improve the evidence then reconsider authority, **(4)** retire the
control. For each control, all four are to be worked through in order and each
accepted or rejected **with its reason**. "No change is warranted" is a
legitimate, reportable outcome.

**Not available:** an operator exception that makes a mismatch disappear.
Verbatim: *"A signed exception can permit a bounded action. It should not
redefine what the control is or prove that it works."* The authority envelope is
correctly monotonic — `L_effective = min(...)` narrows authority and cannot raise
it — and **no promotion instrument is to be built**, because one would let
governance paperwork convert a heuristic into an invariant and weak evidence into
proof.

## The one thing this packet is authorised to do that every previous packet was forbidden

**Re-authorisation.** Any class or runtime-authority change here **is** a
re-authorisation, authorised by the operator's step-3 ruling **for these two
control ids only**. Each change records: the outcome chosen, the argument, and
the evidence that licenses it.

## Derived numbers — recompute, hand-edit none

Changing `authority_mismatch` cascades: the declared count (currently **14**),
the MISMATCHES summary table and its numbered sections, the `sites` hand count,
`README`, `CROSSWALK`, the crosswalk artefact, and `evidence-policy.sh`'s finding
set (currently **19 of 81**, split 6/5/8). `scan-controls.sh` §8's reverse check
flags a table row whose control no longer declares a mismatch.

## Commit ceiling

≤2 commits against base `c52915f`; **Commit-1 green in isolation**, test-first.

## Verification required before hand-back

`bash tests/build_os_tests.sh` (from **1597 passed / 0 failed**) ·
`./build-os/maintenance/run-tests.sh` (144 checks) ·
`bash build-os/registry/scan-controls.sh check` exit 0 ·
`bash build-os/tools/evidence-policy.sh check` with the delta from 19/6/5/8
explained · `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh`.

## Hard gates

Local commits only. No push, merge, tag, PR, deploy, secrets, or `git config`.
`build-os/memory/*` is archivist territory. `/home/user/empathiq-website` is not
touched. **No guard is weakened, deleted or exempted to make the suite green** —
if a guard and a value conflict, the value is wrong until proven otherwise.

---

## Why this file was written before the first edit — the defect it closes

`gravito_authority_envelope_a` was built, gated, fixed, re-reviewed and closed
while this file read **NO PACKET IN FLIGHT**. The orchestrator dispatched the
builder without ever declaring the packet here — a **process defect the
orchestrator owns**, recorded in that packet's receipt and in `residue.md` (u).
**The reviewer ruled it must not be back-written**, because that would manufacture
an artefact stating a packet was declared when it was not; that ruling stands and
nothing above claims otherwise about the *previous* packet.

**The gap remains open.** `bandwidth.active_packet_singleton` refuses **two**
declared packets but permits **zero**, so a two-commit, +2142-line packet with
three new registered controls was built with no declared packet and the control
passed clean. That is `residue.md` (c)'s disclosed "delete the file evades it"
hole in a strictly worse form: the delete branch needs an affirmative destructive
act, while this one **fires on pure omission**. A floor — *assert a declared
packet EXISTS while a packet is in flight* — is still unbuilt and still on the
candidate list.

This declaration does not close that gap. It gives the control something true to
observe for the duration of this build, which is the most a builder can do about
it from inside a packet whose scope is two refuted controls.
