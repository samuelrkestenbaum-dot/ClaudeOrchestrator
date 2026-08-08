# Clean-start bootstrap — validation (task #45, step 3)

Mechanism **D**, the routing-request channel. Validated on fresh clean clones
restored by `restore-seed.sh` — no `live_state/`, no `.gravito/`, no residue.

## Root cause (corrected, from reproduction)

`authority_bootstrap_permission_class_mismatch`. Gravito's own routing
machinery was never broken: the gate allows `route-task.sh` and `route-task.sh`
works on a clean clone. The failure was that **earning first authority required
`Bash`** — frequently approval-gated — **while the authorized work needed only
`Edit`**, which the host auto-approves. One host denial therefore became total
paralysis rather than friction.

## Mechanism

A routing request may be made by **writing one file**,
`build-os/packets/routing/routing-request.json`, carrying `task_id`,
`description` and the 13-field descriptor. Writes to that exact path are
ungated. On the next blocked mutation the gate validates the request and routes
it through the ordinary `route-task.sh` **from inside the hook**, which executes
outside the tool-permission layer, then consumes the request.

**Invariant enforced:** first mutation authority no longer depends on an
operation class with stricter host permission requirements than the mutation
class it authorizes.

## Clean-clone proof

| # | test | result |
|---|---|---|
| 1 | no prior `live_state` / `.gravito` residue | confirmed absent |
| 2 | mutation **before** authority | **REFUSED** (exit 2) |
| 3 | write to the request path, no shell | **allowed** (exit 0) |
| 4 | writing the request mints nothing by itself | 0 new receipts |
| 5 | next mutation redeems the request | **allowed**, receipt minted, request consumed |
| 6 | fresh clone ships **no** open authority | first mutation refused |

## Adversarial tests

| # | attack | result |
|---|---|---|
| A1 | malformed request | **refused**, no receipt, block stands, logged `schema-invalid` |
| A2 | `task_id` injection (`../../etc/x; rm -rf /`) | **refused**, no receipt |
| A3 | replay for renewed authority | request **consumed**; cannot be re-redeemed |
| A4 | channel narrowness — `.bak`, sibling path, memory file, product file, all with no authority | **all gated**; only the exact path passes |
| A5 | close-time enforcement after a bootstrap-minted receipt | `routing-check` runs normally, 2 receipts checked, 0 violations |

## Live end-to-end, headless host — the condition that produced 0/12

**Edit-only task** (fresh, not from EXP-0005 and not used to design the fix):
add a JSDoc block to `vitest.config.ts`.

- Before the fix: agent blocked, zero mutations — *"refuses every
  mutation-capable tool including `Edit`"*.
- After the fix: **task completed.** 5 turns, receipt minted via the channel,
  `vitest.config.ts` changed (+12/−1). The agent also corrected the task
  description's parameter count, which is engagement rather than compliance.

**Bash-requiring task:** create `scripts/print-version.sh`, `chmod +x`, run it.

- The file **was created** — bootstrap succeeded and the write path worked.
- `chmod` and the run were **denied by the host** (2 denials).

That second result is the mechanism behaving correctly, not a shortfall.
Gravito no longer converts a host restriction on `Bash` into total paralysis;
the worker proceeds exactly as far as host policy allows and no further.
**Gravito must not grant more authority than the host itself permits** — the
invariant is about relative privilege class, never immunity.

## A defect the first live test exposed

The mechanism worked but the agent did not use it: the refusal message still
advertised only the `Bash` recovery. **A bootstrap path nobody is told about is
not a bootstrap path.** The refusal now leads with the no-shell recovery and
presents the shell form as the equivalent alternative. The Edit-only task
succeeded only after this change.

## Remaining bootstrap limitations

1. **No real interactive-host arm.** This session has no interactive approver,
   so only the headless case was exercised live. Pre-approving the command in
   settings would simulate host policy, not reproduce it, and is not reported
   as a second environment.
2. **`node` is required** to validate a request. Where it is absent the gate
   logs `node-unavailable` and the block stands — a refusal, not a bypass.
3. **The `Bash` work path is unchanged.** A host denying `Bash` still denies
   `Bash`-shaped work, correctly.
4. **`empathiq-website` carries an identical unpatched copy** of the gate. It
   is a separate repository and was not modified; it will receive the fix when
   Gravito is next installed there.
5. **This validates bootstrap only.** It is not an efficiency claim, and it
   does not reopen EXP-0005, which stays frozen.

## Regression — the gate's existing behaviour is unchanged

| suite | result |
|---|---|
| `routing_task_entry_tests` | 124 passed, 0 failed |
| `routing_structured_action_tests` | 74 passed, 0 failed |
| `routing_live_gate_tests` | 132 passed, 0 failed |
| `routing_enforcement_tests` | 104 passed, 0 failed |
| `gate_depth_tests` | 113 passed, 0 failed |

**547 assertions, 0 failures.** The deadlock guard, the task-entry boundary,
the live gate and the depth budget all behave exactly as before; the channel is
additive.
