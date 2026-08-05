# Routing contract — binding mode selection, escalation, circuit breakers

Driven by two executed defects in EXP-0002's sealed records: T5 ran Full
ceremony over its own recorded `gravito_light` verdict (silent escalation);
T3's correctly-selected Full cost 3.9x on a bounded feature (miscalibration).

## The verdict is binding

The mode recorded in a routing receipt (`build-os/tools/route-task.sh`, one
file per decision under `build-os/packets/routing/`) is **binding**, not
advisory. **Silent escalation is prohibited.** Running above the recorded mode
requires a NEW evidence-bearing escalation decision — written into the
receipt's `escalation` and `escalation_evidence` fields, naming what changed —
recorded **before the escalated work begins**. De-escalation is free and needs
no record. Substantive packets require a routing receipt (see CLAUDE.md).

## Full-mode circuit breakers (budget approached)

When any Full-mode budget in the receipt is approached, degrade gracefully, in
order — **never bare termination while a safe productive path remains**:

1. **Stop spawning** new subagents.
2. **Collapse** remaining work into the parent loop.
3. **Preserve state** (commit-safe tree, notes for resumption).
4. **Continue Light** where safe.
5. **Report the degradation** in the receipt's `degradation_note` and
   consumption fields.

A breach that declares its degradation passes the gate; a concealed breach is
refused. Refusal is for CONTRADICTION, not absence: `-` in a consumption field
is an honest admission (an unknown is not a zero) and is never refused.

## The mechanical / protocol split — labeled honestly

**MECHANICAL** (a machine refuses, exit 2): the receipt schema and the
close-time gate `build-os/tools/routing-check.sh` — silent escalation
(executed_mode above selected_mode, no escalation record), evidence-free
escalation, a filled consumption field over budget with no degradation note,
and Full claimed with no budgets. The selector's refusal of partial
descriptors (`build-os/tools/mode-select.mjs`, exit 2) is also mechanical.

**PROTOCOL** (this text; no machine can check it mid-flight): live-session
token/call/cost counters are **not machine-visible** to bash, so the
circuit-breaker sequence above is followed by the agent, not enforced by a
tool while it runs. It is **verified at close**, and only then, by the
receipt's consumption-vs-budget comparison. No checkbox here claims
enforcement it does not have; a session that records false consumption is
caught by nothing in this contract. **Receipt ISSUANCE is itself protocol**:
no machine cross-checks that a substantive packet issued a routing receipt —
`routing-check.sh` gates only receipts that exist, and its empty-sweep
refusal catches only a wholly empty store. A packet that never routes is
invisible to the gate; that gap is open and named here, not silently.
