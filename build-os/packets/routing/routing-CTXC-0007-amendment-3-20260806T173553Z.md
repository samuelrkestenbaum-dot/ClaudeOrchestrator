# ROUTING RECEIPT — one file per routing decision. The recorded verdict is BINDING
# (build-os/memory/routing_contract.md); routing-check.sh refuses this receipt at
# close if executed_mode exceeds selected_mode with no escalation record, if an
# escalation carries no evidence, or if consumption exceeds a budget undeclared.
task_id: CTXC-0007-amendment-3
description_sha256: 65d8a15674c7325f536e3468ca78e0047d0901a27d3ff6412459d4232a4a4212
descriptor: {"expected_files_changed":1,"requires_tests":false,"expected_session_count":1,"prior_context_required":true,"handoff_required":false,"consequence_level":"low","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}
selected_mode: gravito_light
selector_note: -
issued_at: 2026-08-06T17:35:53Z
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
consumed_wall_clock_s: -
consumed_cost_usd: -
degradation_note: -
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
