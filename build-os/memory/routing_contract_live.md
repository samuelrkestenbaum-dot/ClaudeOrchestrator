# Routing contract — LIVE enforcement half (PACKET-0053)

This file extends `routing_contract.md` (which stays authoritative for the
binding-verdict rule, escalation semantics and the circuit-breaker order). It
exists because PACKET-0050's enforcement was **machine-at-close only**: the
gate refused a contradiction after the tokens were spent, and EXP-0003
measured exactly that — both condition receipts REFUSED at close, ZERO
degradation notes written mid-flight. This half is the mid-flight machine.

## The four enforcement layers — named exactly, no checkbox theater

1. **machine-before-execution** — the dispatch gate
   (`.claude/hooks/routing-gate.sh`, PreToolUse on `Task|Agent`, exit 2 blocks
   the pending call and stderr is the model-visible refusal). Mechanically
   enforced live: receipt presence (no open receipt → no dispatch), depth
   (direct/light receipts block dispatch absent an evidence-bearing escalation
   record), fan-out (`budget_max_subagents` vs the EXACT live task-dispatch
   count), the process allowance (below), and binding degradation. Every
   decision is persisted append-only to
   `build-os/packets/routing/live_gate_log.tsv`.
2. **machine-at-close** — the sweep (`build-os/tools/routing-check.sh`,
   chained into the suite): silent escalation, evidence-free escalation,
   concealed breach, Full-without-budgets, CONTRIBUTION-MISSING,
   STATE-DISAGREE (live-state counts vs the filled close — reported, never
   reconciled).
3. **protocol-during** — followed by the agent, checkable by no machine
   mid-flight: **context minimization per depth** (injection-side; a hook can
   block a dispatch but cannot shrink what a session chooses to read) and
   token awareness between hook events. Labeled protocol because that is what
   it is.
4. **not-yet-enforced** — named open gaps: live tokens/cost are invisible to
   hooks in interactive sessions (state files carry
   `tokens: unavailable_live (close-time reconciliation via telemetry where
   headless)`); non-dispatch work is ungated beyond receipt presence and
   counting; a session that lies into its receipt is caught only by
   STATE-DISAGREE where a state file exists; sessions without the hook loaded
   (see below) are ungated entirely.

## When the gate becomes live

Hooks load at **session start**. The session that wired this gate is NOT
governed by it — including the qa/reviewer subagents gating the packet that
shipped it. Every later session in this project is. A change to the hook or
its wiring likewise takes effect only at the next session start.

## Live resource visibility — EXACT vs ESTIMATE, per field

One state file per open receipt at
`build-os/packets/routing/live_state/<receipt-id>.tsv`, append-only, counts
derived by counting rows (never stored). Every field carries a `label` row
saying whether it is EXACT, and under which bound: dispatch counts and tool
events are EXACT hook counts *in sessions where the gate is loaded*; tool
failures are EXACT only where PostToolUse exposes `success:false`/`is_error`
(absence of a row is NOT evidence of success); elapsed is EXACT, derived at
read time from `issued_at`; tokens/cost are `unavailable_live` — never faked.

## Fan-out throttle, degradation, and the two dispatch ledgers

- **Task dispatches** count against `budget_max_subagents`. At the threshold
  the gate BLOCKS the next dispatch, stamps the receipt via
  `build-os/tools/record-degradation.sh` (reason, timestamp, preserved-evidence
  pointer, `downgraded_to=gravito_light`), and instructs: consolidate into the
  parent loop, preserve completed outputs, continue in Light. **Stop the
  expensive mode, not the task** — no block message says stop working. The
  stamped note is exactly what lets routing-check.sh PASS the honest breach.
- **Process-role dispatches** (`subagent_type` in builder | qa | reviewer |
  archivist | build-orchestrator) count against
  `process_dispatch_allowance` (receipt field, default 4 — the standard
  chain), attributed to `governance_process`. This RESOLVES the
  PACKET-0050/0051 open calibration question: a Full packet's own gate chain
  no longer brushes `max_subagents: 3`, and neither ledger bleeds into the
  other. Both counts appear in the state file and the close fill
  (`consumed_subagents` / `consumed_process_dispatches`).
- An **escalated** direct/light receipt (evidence-bearing record) is governed
  by the Full task-dispatch default (3) where its recorded budget is lower —
  an escalation that could never dispatch would be a grant in name only.

## Cost attribution and marginal contribution (close fill)

Seven attribution layers on every receipt (`attr_task_execution`,
`attr_context_retrieval`, `attr_subagent_execution`, `attr_verification`,
`attr_review`, `attr_governance_process`, `attr_experiment_audit`) — filled
where derivable, `-` as an admission, never a zero nobody measured. One
`contribution:` row per dispatched Full task agent (the gate seeds a stub at
dispatch): unique question, output ref, changed_implementation /
changed_conclusion / caught_defect / duplicated_work as y/n/-, tokens/cost/
time where derivable. A Full close with dispatches and no rows is REFUSED;
an all-`-` row passes and is reported non-contributing. Fields absent on
receipts predating this packet read as `-`: old receipts stay valid.

## Fail-open, and the operator escape

The gate **fails open** on its own errors and logs `FAIL-OPEN`: a gate that
fails closed on a bug is a denial of service against the operator.
`ROUTING_GATE_DISABLE=1` is the **operator-only** escape — refused-by-default
posture: agents do not set it, its use is always logged to
`live_gate_log.tsv` (`DISABLED-BY-OPERATOR`), and an escape that leaves no
trace would be a bypass, which is why the trace is unconditional.
