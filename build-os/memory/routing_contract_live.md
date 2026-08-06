# Routing contract — LIVE enforcement half (PACKET-0053, extended by PACKET-0054)

This file extends `routing_contract.md` (which stays authoritative for the
binding-verdict rule, escalation semantics and the circuit-breaker order). It
exists because PACKET-0050's enforcement was **machine-at-close only**: the
gate refused a contradiction after the tokens were spent, and EXP-0003
measured exactly that — both condition receipts REFUSED at close, ZERO
degradation notes written mid-flight. This half is the mid-flight machine.
PACKET-0054 widened it from dispatch-only to **universal task entry** (below),
and expressed the hook surface as a provider adapter —
`provider_adapter_contract.md`, with `.claude/hooks/routing-gate.sh` as
ADAPTER #1 and the telemetry tier vocabulary
(EXACT | ESTIMATE | CLOSE-TIME | UNAVAILABLE) defined there.

## The universal task-entry boundary (PACKET-0054)

**Every substantive task routes at entry — including parent-only work that
never dispatches.** The PreToolUse gate now also fires on the
MUTATION-CAPABLE tools (`Edit|Write|NotebookEdit|Bash`, subcommand `mutgate`):
a mutation-capable call with NO open routing receipt is BLOCKED, and the
refusal carries the recovery command with a cheap direct-mode example — tiny
work routes too, it just routes cheaply. **The FIRST action of any new session
is to issue or confirm a routing receipt** (one command:
`build-os/tools/route-task.sh`; confirming = an open receipt already exists
for the task in flight, e.g. the active packet's, which stays open until the
archivist's close-fill — then the next session re-routes).

- **DEADLOCK GUARD.** A Bash event naming any of the routing tools
  (`route-task.sh`, `mode-select.mjs`, `routing-check.sh`,
  `record-degradation.sh`) passes UNGATED and is logged `ROUTING-TOOL-PASS`.
  Without it, no session could issue the receipt its first gated call
  requires. **Its true breadth is wider than "a command that invokes the
  tool":** the match is a substring test over the ENTIRE raw hook JSON,
  checked BEFORE the git classification — so a compound command
  (`route-task.sh; git push --force`), a comment that merely mentions a
  routing tool, or a tool path appearing in any non-command field (e.g. the
  description) ALL pass ungated, and `ROUTING-TOOL-PASS` mislabels such
  events. This is the SOLE ungated pass in the task-entry boundary, so its
  breadth is stated at full size rather than softened: it grants a hostile
  agent nothing beyond the `sh -c` evasion named below (the not-a-sandbox
  bound holds), but honest audit reads of the log must treat
  `ROUTING-TOOL-PASS` as "the event mentioned a routing tool," not "the
  event only ran one." The match is deliberately NOT narrowed to the command
  field: a guard that could misparse an event and block the receipt-issuing
  command would re-create the deadlock it exists to prevent, and blocking is
  the failure mode this guard must never have.
- **Read-only git inspection** (`status|log|diff|show|rev-parse|ls-files|
  branch` by subcommand) passes ungated, logged `GIT-READONLY-PASS`, counted
  exploratory. Any git command carrying `push|commit|merge|rebase|reset|
  checkout|restore|clean|apply|am|cherry-pick|tag|stash` or `-f/--force` is
  mutation-capable.
- **THE CLASSIFICATION IS A NAMED HEURISTIC, not a sandbox.** It reads the
  raw hook JSON; a hostile command evades it trivially (`sh -c`, `eval`, a
  wrapper script, `git -C` indirection lands conservative-mutation, and e.g.
  `git branch -D` slips the read-only class). The gate is
  discipline-for-honest-agents plus an audit trail; the sandbox is the
  platform's permission system, which this gate does not replace.
- **Exploratory reads stay ungated but counted.** Read/Grep/Glob (and the
  read-only git class) append `exploratory_event` rows when a receipt is
  open, so the record shows the explore/execute split; admitted
  mutation-capable calls append `mutation_event` rows. All activity binds to
  the open receipt's live-state file; at close, `routing-check.sh` REPORTS
  (never refuses) `activity_binding UNBOUND-ACTIVITY` where a closed receipt
  recorded mutation events but every consumption field is `-` with no
  telemetry reconciliation — absence is admission, made visible.
- **Repetitive-loop reassessment, fire-once.** The counter arms a trip when
  consecutive same-tool calls reach `ROUTING_REASSESS_SAME_TOOL_MAX` (derived
  default 25) or the ESTIMATE token proxy (chars/4) reaches
  `ROUTING_REASSESS_PROXY_MULT` (default 4) × `budget_max_uncached_tokens` —
  derived defaults, operator-tunable, never laws. The NEXT mutation-capable
  call is blocked ONCE with a REASSESS refusal (re-route: fresh receipt via
  route-task.sh, or an escalation/degradation record); a reassessment record
  resets the trip, and a fired trip never blocks twice — a reassessment loop
  that blocks forever would be a brick, and the suite proves it is not.

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
   hooks in interactive sessions (state files carry the tier labels — tokens
   `unavailable_live` interactive / close-time reconciliation via telemetry
   where headless; see `provider_adapter_contract.md`); the Bash
   classification is an evadable heuristic (named above), so a dishonest
   session slips the mutation gate; a session that lies into its receipt is
   caught only by STATE-DISAGREE where a state file exists; sessions without
   the hook loaded (see below) are ungated entirely. (PACKET-0053's
   "non-dispatch work is ungated" gap is CLOSED by PACKET-0054's task-entry
   boundary, to the heuristic's stated bound.)

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
  `process_dispatch_allowance` (receipt field, default 7 — DERIVED from the
  doctrine's largest LEGAL chain shape: `mandatory_full_regate` runs builder,
  qa, reviewer, fix-builder, qa, reviewer, archivist = 7; the no-fix chain is
  4 and fix-then-pass is 6), attributed to `governance_process`. This RESOLVES the
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
trace would be a bypass. The trace has ONE named gap: an unwritable
routing store silences the log file — in that case the gate emits the row to
stderr instead (`UNLOGGED(store unwritable)`), so the trace survives as a
model-visible line rather than a file row; a session that both makes the
store unwritable and discards stderr leaves no durable trace, and that
residual vector is named here, in layer 4, not lacquered.
