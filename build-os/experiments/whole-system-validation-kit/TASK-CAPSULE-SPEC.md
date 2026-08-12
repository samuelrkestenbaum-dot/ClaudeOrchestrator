# TASK CAPSULE — specification (arm-neutral by construction)
A capsule is the complete, immutable statement of one task. Both arms
receive byte-identical capsules; nothing in a capsule may name, hint at, or
vary by arm. Sealed = sha256 over the canonical serialization recorded in
the preregistration BEFORE any run of that pair.

Required fields
- capsule_id (stable, opaque); created_at; sealed_sha256
- repo + pinned_seed_commit (repo chosen later; field REPO-DEP)
- task_source: sampler draw reference (candidate-list id + sampler seed)
- task_text: the statement given verbatim to the arm
- context_pointers: files/docs the task legitimately names (identical both arms)
- stratum (small-fix|medium-change|feature-slice) + value_weight (PACKET §4)
- acceptance_script_ref + expected verdict semantics (necessary gate)
- review_rubric_ref (sufficient-to-reject grounds; kit acceptance doc)
- authority_bounds: what the arm may do (never push/deploy/secrets)
- allowed_tools; ceilings: wall_minutes __ , token_budget __ (same both arms)
- clarification_handling: FAQ ref; out-of-FAQ = metered intervention (kit operator doc)
- environment_fingerprint: model id, harness commit, container image, env vars hash
- contamination_checks: pre-run assertions (seed clean; no cross-arm artifacts
  present; no Gravito state in arm A clone; store provenance in arm B)
- infeasibility_rule ref (PACKET §4) — substitution only via sampler's next draw
