# ROUTING RECEIPT — one file per routing decision. The recorded verdict is BINDING
# (build-os/memory/routing_contract.md); routing-check.sh refuses this receipt at
# close if executed_mode exceeds selected_mode with no escalation record, if an
# escalation carries no evidence, or if consumption exceeds a budget undeclared.
task_id: PACKET-0053-live-enforcement
description_sha256: 8442830c3418353b6de16cd5d0af000cdb9a7b521fd21c1e3ace34be88d96ea6
descriptor: {"expected_files_changed":15,"requires_tests":true,"expected_session_count":1,"prior_context_required":true,"handoff_required":false,"consequence_level":"high","irreversible_or_external_mutation":false,"high_blast_radius":true,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":true,"nondeterministic_verification":false}
selected_mode: gravito_full
selector_note: -
issued_at: 2026-08-05T22:25:30Z
# --- budgets: DERIVED DEFAULTS from EXP-0002 sealed records, operator-tunable, not laws.
# --- Derivation: ON-surface light runs measured 172k-369k total tokens / 0 dispatches
# --- (named exceedance: raw T4 at 526,461 - context, not the band); the
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
# --- close-time record (archivist, 2026-08-06, at close of PACKET-0053): executed
# --- mode matches the selected mode — no escalation occurred, so escalation stays
# --- '-'. Consumption fields stay '-' FOR THE DOCTRINAL REASON, not from neglect:
# --- this packet's own serial agent passes and live token/call/cost counters are
# --- transcript-only — nothing in git attests to them, and a transcript figure is
# --- not written into a measured cell. '-' is the admission this gate accepts (an
# --- unknown is not a zero). consumed_process_dispatches (a PACKET-0053 field this
# --- pre-extension receipt did not carry at issue) is written '-' with a SPECIFIC
# --- admission: the hook that counts process dispatches EXACTLY loads at NEXT
# --- session start, so no live_state/ file exists for this packet and the count is
# --- transcript-only — not derivable from any committed record of this session.
consumed_subagents: -
consumed_total_tokens: -
consumed_uncached_tokens: -
consumed_model_calls: -
consumed_wall_clock_s: -
consumed_cost_usd: -
consumed_process_dispatches: -
degradation_note: -
