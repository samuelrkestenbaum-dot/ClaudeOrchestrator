# ROUTING RECEIPT — one file per routing decision. The recorded verdict is BINDING
# (build-os/memory/routing_contract.md); routing-check.sh refuses this receipt at
# close if executed_mode exceeds selected_mode with no escalation record, if an
# escalation carries no evidence, or if consumption exceeds a budget undeclared.
task_id: PILOT-0001-T1-diagnose-red-baseline
description_sha256: d892a0bde49a5701403264fb15319cce18b18fb2cc4d07a106ba46aab35229cc
descriptor: {"expected_files_changed":1,"requires_tests":false,"expected_session_count":1,"prior_context_required":true,"handoff_required":true,"consequence_level":"low","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}
selected_mode: gravito_light
selector_note: mode-select: note: gravito_full WITHHELD — complexity trigger fired (handoff required) but no value factor is true. Complexity alone is not evidence that Full ceremony buys anything worth its cost (EXP-0002 buildos T3: a correctly-complex bounded feature at 3.9x). Selecting gravito_light. To route Full, declare at least one true value factor: irreversible_or_external_mutation, high_blast_radius, unclear_acceptance_criteria, security_or_compliance_consequence, parallel_workstreams_benefit, high_rework_history, nondeterministic_verification.
issued_at: 2026-08-06T04:13:41Z
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
# --- process allowance (PACKET-0053): the packet's OWN gate chain is governance
# --- ceremony, counted SEPARATELY from task work by the live gate and attributed
# --- to governance_process (the 0050/0051 calibration question, resolved). Default
# --- 7 = the LARGEST LEGAL chain in the doctrine: mandatory_full_regate runs
# --- builder, qa, reviewer, fix-builder, qa, reviewer, archivist. (No-fix chain
# --- is 4; fix-then-pass is 6.) Process dispatches never eat budget_max_subagents.
process_dispatch_allowance: 7
# --- empty at issue; filled at close. AN UNKNOWN IS NOT A ZERO: "-" is an honest
# --- admission and is never refused; refusal is for CONTRADICTION, not absence.
executed_mode: gravito_light
escalation: -
escalation_evidence: -
consumed_subagents: 0
consumed_total_tokens: -
consumed_uncached_tokens: -
consumed_model_calls: -
consumed_wall_clock_s: 671
consumed_cost_usd: -
degradation_note: elapsed 671s exceeded light budget 600s — cause: three test-runtime executions (160s+23s+160s) required to localize order-dependent failure; degradation held: no subagents, no scope growth, stayed light; tool calls 8 of 25; tokens unavailable_live (interactive)
# --- close-fill EXTENSIONS (PACKET-0053). consumed_subagents above counts TASK
# --- dispatches (vs budget_max_subagents); consumed_process_dispatches counts the
# --- gate chain (vs process_dispatch_allowance). The attr_* layers attribute
# --- consumption where derivable at close — tokens or cost with provenance, or
# --- "-" as an admission, NEVER a zero nobody measured. Receipts predating these
# --- fields stay valid: routing-check.sh reads an absent field as "-".
consumed_process_dispatches: -
attr_task_execution: -
attr_context_retrieval: -
attr_subagent_execution: -
attr_verification: -
attr_review: -
attr_governance_process: -
attr_experiment_audit: -
# --- contribution rows (PACKET-0053): marginal-contribution accounting, MANDATORY
# --- for a Full close with dispatches>0 (routing-check.sh refuses otherwise). The
# --- live gate seeds one stub row per admitted Full task dispatch; fill at close:
# --- contribution: <subagent_type> | <unique_question> | <output_ref> | changed_implementation=y/n/- | changed_conclusion=y/n/- | caught_defect=y/n/- | duplicated_work=y/n/- | tokens=<v|-> | cost=<v|-> | time=<v|->
# --- An all-"-" row passes as an admission and is REPORTED as non-contributing.
