# EXP-0008 — the one authorised repair, frozen before execution

**This is the last bounded repair. Declared before the result, per the operator:
"No third chance."**

## Why a repair rather than banking the negative

The first prototype arm read 35,825 chars of Gravito implementation against a
baseline mean of 38,007 — unchanged. But **23,011 of those 35,825 came from
artifacts the treatment itself created or pointed at**:

| source | chars | cause |
|---|---|---|
| `routing-gate-real.sh` | 8,090 | the treatment RENAMED the gate, manufacturing an implementation file the baseline never had |
| `route-task.sh` | 10,806 | `next` named a receipt file without its content — the receipt has ~30 fields — so the worker went looking for the schema |
| `routing_contract.md` | 4,115 | same cause |

Plus an argv defect: the hook is invoked with one argv and passes its payload on
**stdin**, but the shim read `$2`, so every payload said `action: unknown`.

That is not "the result was bad, so change the experiment." The treatment
accidentally produced most of the behaviour it was built to remove.

## What changed, and nothing else

1. **Prepended into the existing gate, not renamed.** No new file appears. A
   treatment that manufactures implementation surface cannot measure its removal.
2. **The complete receipt text is inline.** `path:` plus the exact `content:`
   lines that satisfy the gate. A file the worker must fill in from a schema
   found elsewhere is a pointer wearing an instruction's clothes.
3. **Tool name read from the hook's stdin payload.**
4. Real gate decision, authority behaviour and refusal semantics **unchanged** —
   the shim re-enters the same file under a marker variable and the gate below
   still decides.

Payload: **348 chars, ~87 tokens.**

## Verification, on the EMITTED payload

Seven pre-flight checks, all against what the worker actually receives rather
than the file that produces it — the correction the read classifier needed and
that this guard needed too, having first failed on its own comment:

`no_new_implementation_file` · `wrapper_installed` · `payload_emitted` ·
`no_pointer_in_payload` · `payload_is_self_contained` · `action_resolved` ·
`payload_within_budget`

## Stopping rule — unforgiving, fixed before the run

ALL must hold, or microcontext is **refuted in this form** and this path stops:

- implementation reads **materially fall**;
- turns **do not materially rise**;
- acceptance **holds**;
- **no read substitution** into other Gravito internals;
- total cost **improves**.

Reduced read volume alone is not success. If the worker stops reading the gate
and starts reading something else, the prototype failed.

The confounded first arm is preserved at
`results/runs/T01.microcontext-v1-confounded/`.
