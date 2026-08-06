# FABRICATED FIXTURE — not a measurement. See fixtures/README.md.
# Shape copied from a real routing receipt so the renderer is exercised against
# the real field names; every VALUE below is invented.
task_id: DEMO-0001-refund-rounding-fix
description_sha256: 0000000000000000000000000000000000000000000000000000000000000001
descriptor: {"expected_files_changed":5,"requires_tests":true,"expected_session_count":1,"prior_context_required":true,"handoff_required":false,"consequence_level":"medium","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":true,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}
selected_mode: gravito_full
selector_note: -
issued_at: 2026-08-01T09:00:00Z
budget_max_subagents: 3
budget_max_total_tokens: 2000000
budget_max_uncached_tokens: 120000
budget_max_model_calls: 40
budget_max_wall_clock_s: 900
budget_max_cost_usd: 1.50
process_dispatch_allowance: 7
executed_mode: gravito_full
escalation: -
escalation_evidence: -
consumed_subagents: 2
consumed_total_tokens: 412000
consumed_uncached_tokens: 61000
consumed_model_calls: 28
consumed_wall_clock_s: 694
consumed_cost_usd: 0.91
degradation_note: -
consumed_process_dispatches: 4
attr_task_execution: 210000
attr_context_retrieval: 64000
attr_subagent_execution: 84000
attr_verification: 31000
attr_review: 18000
attr_governance_process: 5000
attr_experiment_audit: -
contribution: verification-1 | did the rounding change miss a currency path | output ref demo-a | changed_implementation=y | changed_conclusion=n | caught_defect=y | duplicated_work=n | tokens=84385 | cost=- | time=319s
contribution: review-1 | is the refund ledger still reconcilable after the change | output ref demo-b | changed_implementation=n | changed_conclusion=n | caught_defect=n | duplicated_work=y | tokens=41120 | cost=- | time=155s
# --- THE DELIBERATE BAIT. No real receipt has these fields and no tool writes
# --- them. They exist so the suite can prove the renderer refuses to promote an
# --- UNAVAILABLE field just because an input file volunteered a value.
accepted: yes
human_interventions: 3
regressions: 0
