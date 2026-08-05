# ROUTING RECEIPT — one file per routing decision. The recorded verdict is BINDING
# (build-os/memory/routing_contract.md); routing-check.sh refuses this receipt at
# close if executed_mode exceeds selected_mode with no escalation record, if an
# escalation carries no evidence, or if consumption exceeds a budget undeclared.
task_id: PACKET-0050-routing-enforcement
description_sha256: ac004cad77b07f802f364ee504974567a859f959243f863af789018a3d81d430
descriptor: {"expected_files_changed":12,"requires_tests":true,"expected_session_count":1,"prior_context_required":true,"handoff_required":false,"consequence_level":"high","irreversible_or_external_mutation":false,"high_blast_radius":true,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}
selected_mode: gravito_full
selector_note: -
issued_at: 2026-08-05T17:46:46Z
# --- budgets: DERIVED DEFAULTS from EXP-0002 sealed records, operator-tunable, not laws.
# --- Derivation: light tasks measured 170k-370k total tokens / 0 dispatches; the
# --- blowouts measured 4.9M/7.4M tokens, 4-5 dispatches, $3.63/$4.80. See route-task.sh.
budget_max_subagents: 3
budget_max_total_tokens: 2000000
budget_max_uncached_tokens: 120000
budget_max_model_calls: 40
budget_max_wall_clock_s: 900
budget_max_cost_usd: 1.50
# --- empty at issue; filled at close. AN UNKNOWN IS NOT A ZERO: "-" is an honest
# --- admission and is never refused; refusal is for CONTRADICTION, not absence.
executed_mode: gravito_full
escalation: -
escalation_evidence: -
# --- close-time record (archivist, 2026-08-05, at close of PACKET-0050): executed
# --- mode matches the selected mode — no escalation occurred, so escalation stays
# --- '-'. Consumption fields stay '-' FOR THE DOCTRINAL REASON, not from neglect:
# --- serial agent passes and live token/call/cost counters are transcript-only —
# --- nothing in git attests to them, and a transcript figure is not written into
# --- a measured cell. '-' is the admission this gate accepts (an unknown is not a
# --- zero). Open calibration question, recorded not resolved: a full-mode packet's
# --- own gate chain (builder+qa+reviewer+archivist) brushes the max_subagents 3
# --- default — whether process agents count against task budgets is an
# --- EXP-0003-adjacent operator question.
consumed_subagents: -
consumed_total_tokens: -
consumed_uncached_tokens: -
consumed_model_calls: -
consumed_wall_clock_s: -
consumed_cost_usd: -
degradation_note: -
