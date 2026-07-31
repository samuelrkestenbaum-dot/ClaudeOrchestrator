# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** **none active.**

The last packet, `gravito_census_gaps_egress_bandwidth_a`, is **CLOSED** —
receipt at `build-os/receipts/gravito_census_gaps_egress_bandwidth_a.md`,
commits `86c8f93` + `2a3c9b3` on `claude/project-handoff-merge-ramhds`
(base `321dced`). Verdict **pass as fixed**: qa GREEN at 1418/0, reviewer
`fix-then-pass` twice, both fix rounds landed and re-verified. **Nothing pushed.**

Its findings and its six open follow-ons are in the receipt and in
`build-os/memory/residue.md`; the "where we are" snapshot is in
`build-os/memory/current_state.md`.

## No packet is staged

The next packet is not chosen. `build-os/memory/current_state.md` → *Next
(candidates)* lists the six follow-ons cheapest-first; the orchestrator picks
one and writes it here before any builder runs.

**Do not treat this file as a to-do list.** It holds exactly one packet, or
nothing. A candidate list is not a packet — it has no scope boundary, no branch
base, no commit plan, and nothing a builder is authorised to implement.

## Note on this file's own control

`bandwidth.active_packet_singleton` (Class C, `gate`, `authority_mismatch:
declared`) reads this file to enforce a ceiling of one packet in flight. Two
things a maintainer should know before trusting it:

1. **Its ceiling comes from the prose header above, not from `CLAUDE.md`.**
   "One packet at a time" appears nowhere in the working contract. That is why
   the control was **demoted from Class A to Class C on review** — the ceiling
   rests on a docstring inside the control's own input, which makes it a WIP
   limit somebody chose rather than a definition.
2. **Deleting or untracking this file makes the gate pass trivially.** That
   evasion is disclosed in the registry entry and is **open** — nothing asserts
   this file exists and is tracked (residue item (c)).

---
_Cleared by the archivist on close of `gravito_census_gaps_egress_bandwidth_a`._
