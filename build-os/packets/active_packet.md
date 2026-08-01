# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: IN FLIGHT — `gravito_p4_s1_shadow_ranker_a`

- **Packet id:** `PACKET-0034-gravito-p4-s1-shadow-ranker-a`
- **Lane:** `substantive` · **Depth budget:** 2 (builder, then qa ‖ reviewer)
- **P4 of the operator's five-phase sequence.** The first phase whose output is a
  **decision** rather than a record of one.

## Branch base

Built on `claude/project-handoff-merge-ramhds` at `ce71122`, re-verified with
`git merge-base`. Everything through that commit is pushed; nothing in this
packet is authorised to be.

## The success condition

**A real candidate set goes in, and an immutable explained ordering comes out.**
Nothing else in this packet counts as success.

## What is being built

`build-os/metrics/rank-candidates.sh` — **S1**, a shadow ranker.
`controlClass: heuristic_policy` · class C · `empiricalStatus: untested` ·
`runtimeAuthority: observe` · `deploymentMode: shadow` ·
`outputSemantics: ordered_candidates`. The composition is
`MIN(advise, observe, observe) = observe`, and it is registered at exactly that.

Nine required outputs: stable candidate ids · frozen signal snapshots, never
recomputed · every candidate still visible including the last-ranked and the
refused · per-candidate signal values · the **decomposition**, not just a total ·
self-amendment exclusions, printed with reasons · the actual selection ·
`rank_of_selected` · **zero dispatch authority**.

Two guards: **(1)** no learned policy may optimize the mechanism governing its
own promotion — refuse, visibly, and fail closed; **(2)** publish the
decomposition.

## The governance ceiling

**No new store. No new validator tool. No new suite file. No new governance
primitive.** An exception requires a concrete FAILING FIXTURE, executed with
output. One was executed: `scan-controls.sh check` refuses at exit 2 with
`UNREGISTERED build-os/metrics/rank-candidates.sh can terminate a run non-zero
and owns NO registry entry at authority gate`, which forces a **second** census
entry (`ranker.s1_input_integrity`, class A, `gate`). Registering the ranker
itself at `gate` was the alternative and is worse: it would put a Class C control
two rungs above its licence and ship a declared mismatch to launder a refusal
path.

Governance defects found while building are recorded as residue and **not fixed
here**. Stores added: 0. Validator tools added: 0. Suite files added: 0.
Governance primitives added: 0.

## Candidate set

Real, not synthetic: open work drawn from `build-os/memory/residue.md` and the
packet staged at the `gravito_p3_accept_and_constrain_a` close. Recorded as
`DECISION-0010-p4-s1-shadow-ranker` with 28 frozen snapshots.

## Not in this packet

The five items of `gravito_p3b_count_derivation_a` — which is the **selected
candidate** of `DECISION-0010`, still not started, and which S1 independently
placed at rank 1.
