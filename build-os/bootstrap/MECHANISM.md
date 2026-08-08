# Clean-start bootstrap — mechanism evaluation (task #45, step 2)

Defect: `authority_bootstrap_permission_class_mismatch`.

**Invariant to enforce:** first mutation authority must not depend on an
operation class whose host permission requirements are stricter than the
mutation class it authorizes.

## Candidates

### A. Deterministic empty routing state at install/reset
Initialise `live_state/` and an empty ledger on a clean clone.

**Rejected.** Reproduction proved state absence was never the blocker —
`route-task.sh` already works with no live state. This fixes nothing that
failed, and shipping it as "the bootstrap fix" would leave the real defect
live. Retained only as unrelated hygiene.

### B. Reclassify `route-task.sh` as ungated and pre-approved
Make the routing invocation exempt from the gate *and* from host approval.

**Rejected — half of it is not ours to grant.** The gate already allows it
(that half exists and works). The failing half is host approval, which is the
host's policy, not Gravito's. A fix that requires the host to whitelist a repo
script is unenforceable from inside and fails on exactly the hosts that
motivated the work.

### C. Hook mints the receipt on any blocked mutation
When mutgate blocks and no receipt exists, write one and allow.

**Rejected — bypasses routing policy.** Any mutation attempt would
self-authorize. It discards the descriptor, the mode selection and the
structured routing request; the gate would become decorative. Fails "no bypass
of routing policy" and "structured routing request".

### D. **Routing request through the permitted channel** — SELECTED
The worker expresses the routing request by **writing a request file** —
`build-os/packets/routing/routing-request.json` — carrying `task_id`,
`description` and the full 13-field descriptor. The mutgate:

1. treats a `Write`/`Edit` to **that exact path only** as ungated (it is the
   routing channel, not product mutation);
2. on the next blocked mutation, if a **valid** request file is present, mints
   the receipt by invoking the ordinary `route-task.sh` **from inside the
   hook** — hooks run outside the tool-permission layer — then allows;
3. consumes the request file, so it authorizes exactly once.

**Why this one.** It changes the *permission class* of earning authority to
match the class being authorized: a worker the host allows to `Write` can earn
`Write` authority. It does not weaken what routing *decides* — the same
descriptor, the same `mode-select`, the same receipt, the same downstream
enforcement. The Bash path remains available and unchanged where the host
permits it.

## Required properties

| property | how D satisfies it |
|---|---|
| no globally open receipt | none shipped; a receipt exists only after a request is made |
| no bypass of routing policy | full 13-field descriptor required; `route-task.sh` and `mode-select` run unchanged |
| deterministic | same request ⇒ same receipt fields; no sampling, no clock-dependent branch |
| structured routing request | schema-validated; a malformed request mints nothing and the block stands |
| narrow authority scope | exactly one path is ungated; every other write stays gated |
| idempotent | request consumed on use; re-running the same request is safe and re-derives the same decision |
| audit evidence | `BOOTSTRAP-RECEIPT-MINTED` row with the request sha256; the receipt records its own provenance |
| normal enforcement immediately after | the minted receipt is an ordinary receipt — budgets, escalation, degradation, close-time check all apply |
| bootstrap cannot yield unrestricted mutation | writing the request grants nothing by itself; the receipt it mints carries the mode the descriptor earns, and nothing more |

## What this does NOT claim

It does not make Gravito host-policy-independent. A host that forbids `Write`
as well blocks everything, and correctly so — at that point the worker has no
authority to do the work either, so no bootstrap is owed. The invariant is
about **relative** privilege class, not immunity.
