# ROUTING RECEIPT — one file per routing decision. The recorded verdict is BINDING
# (build-os/memory/routing_contract.md); routing-check.sh refuses this receipt at
# close if executed_mode exceeds selected_mode with no escalation record, if an
# escalation carries no evidence, or if consumption exceeds a budget undeclared.
task_id: EXP-0003-sequence
description_sha256: 0169331fd830c52dac0151996dd66687297277034a71a2b08a62332e72196974
descriptor: {"expected_files_changed":4,"requires_tests":true,"expected_session_count":3,"prior_context_required":true,"handoff_required":false,"consequence_level":"medium","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"nondeterministic_verification":false,"high_rework_history":false}
selected_mode: gravito_light
selector_note: mode-select: note: gravito_full WITHHELD — complexity trigger fired (multi-session (expected_session_count 3); multi-step (expected_files_changed 4)) but no value factor is true. Complexity alone is not evidence that Full ceremony buys anything worth its cost (EXP-0002 buildos T3: a correctly-complex bounded feature at 3.9x). Selecting gravito_light. To route Full, declare at least one true value factor: irreversible_or_external_mutation, high_blast_radius, unclear_acceptance_criteria, security_or_compliance_consequence, parallel_workstreams_benefit, high_rework_history, nondeterministic_verification.
issued_at: 2026-08-05T19:53:25Z
# --- budgets: DERIVED DEFAULTS from EXP-0002 sealed records, operator-tunable, not laws.
# --- Derivation: ON-surface light runs measured 172k-369k total tokens / 0 dispatches
# --- (named exceedance: raw T4 at 526,461 - context, not the band); the
# --- blowouts measured 4.9M/7.4M tokens, 4-5 dispatches, $3.63/$4.80. See route-task.sh.
budget_max_subagents: 0
budget_max_total_tokens: 500000
budget_max_uncached_tokens: 60000
budget_max_model_calls: 25
budget_max_wall_clock_s: 600
budget_max_cost_usd: 0.75
# --- empty at issue; filled at close. AN UNKNOWN IS NOT A ZERO: "-" is an honest
# --- admission and is never refused; refusal is for CONTRADICTION, not absence.
executed_mode: gravito_light
escalation: -
escalation_evidence: -
consumed_subagents: 0
consumed_total_tokens: 4293173
consumed_uncached_tokens: 171723
consumed_model_calls: 81
consumed_wall_clock_s: 480.23
consumed_cost_usd: 2.598891
degradation_note: -
