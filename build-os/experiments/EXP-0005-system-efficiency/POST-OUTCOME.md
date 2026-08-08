# EXP-0005 — post-outcome findings

Two sources, kept apart on purpose.

## A. Engine output — mechanical, unmodified rules

`build-os/learning/disposition.mjs` run against the frozen result:
**2 findings, both `unsupported_hypothesis`, 0 execute-class.**
Neither names the bootstrap defect. See `RESULT.md` §19 for why it missed:
the only acceptance rule is gated on `regressions > 0`, and there is no
predicate for a total acceptance floor or for "produced no output".

No rule was added, edited or re-weighted after seeing the result.

## B. Human-derived findings — NOT engine output

Recorded separately so the engine is never credited with them.

### B1. Bootstrap defect — routing enforcement has no clean-start escape path
Gravito ships a mutation gate (tracked) without the routing state that opens it
(untracked, classified disposable). A clean installation reaches
"you may not mutate until a routing receipt exists", and creating that receipt
requires a mutation-capable command. Circular; unrecoverable from inside.

Class: product_defect · severity: high · confidence: high (12/12 deterministic)

### B2. Durability-classification defect — "disposable" state is load-bearing
`memory/INVENTORY.md` classified `build-os/packets/routing/live_state/`,
`live_gate_log.tsv` and `.gravito/` as per-session state, not durable knowledge.
They are load-bearing for the ability to act at all. The classification was
wrong, and it was invisible while the substrate only ever ran on the machine
that grew the state.

Class: product_defect · severity: high · confidence: high

### The invariant vNext must satisfy
> A clean Gravito installation must be able to earn its first mutation
> authority without already possessing mutation authority.

Candidate mechanisms — engineering choice deferred to design, not fixed here:
initialise a valid empty routing state at install/reset; permit one narrowly
scoped bootstrap operation before enforcement begins; or make receipt creation
a non-mutation operation the gate cannot block.

Validation must be a NEW clean-clone experiment on FRESH tasks. EXP-0005 is
frozen and is not rewritten by any fix.

## C. What the engine should learn — proposed, NOT applied
A rule for a total acceptance floor ("one condition produced zero accepted
outcomes") and one for "zero product output despite non-trivial spend" would
both have fired here. **Neither is being added now.** Adding them after seeing
the result is fitting the detector to the answer. They are candidates for a
future rule-set revision, validated against experiments that did not inspire
them.
