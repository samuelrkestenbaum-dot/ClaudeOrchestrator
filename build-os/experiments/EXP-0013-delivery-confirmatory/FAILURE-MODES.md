# EXP-0013 — observed failure modes, prevention mechanism, typed reason, proof

Every entry names a defect actually observed in this program's history, the
mechanism that prevents or detects it in this harness, its typed
invalidation reason, and how it is proven. "contract" = enforced by frozen
design + admissibility schema and exercised at spend time; "test" =
executable now in tests/exp0013_fixture_tests.sh or an existing suite.

| # | Observed defect | Mechanism | Typed reason | Proof |
|---|---|---|---|---|
| 1 | argument-length/MAX_ARG_STRLEN | prompts pass via stdin file, never argv; admissibility flag prompt_via_stdin | INVALID_PROMPT_VIA_ARGV_FORBIDDEN | test (admit refuses argv flag) |
| 2 | background monitor cannot resume headless worker | no detached monitors: harness-tracked invocation only (EXP-0009 lesson); scheduler owns lifecycle | INVALID (reliability gate) | contract |
| 3 | aborted streaming / incomplete result | result-event required; absent = NOT-METERED + infrastructure-invalid cell | INVALID_MISSING_PROVIDER_RESULT | test (fake-worker --no-result) |
| 4 | timeout/truncated work | fixed timeout ceiling in frozen cell config; terminal_reason recorded | reliability gate | contract |
| 5 | CPU contention | no-spend calibration + one-lane-per-sequence topology; >10% inflation => serial | concurrency gate | test (calibrate-noload; scheduler log validation) |
| 6 | shared test-baseline cache races | per-sequence baseline caches in isolation manifest | INVALID_ISOLATION_PATH_COLLISION | test (manifest uniqueness) |
| 7 | error-diff oracle line shifts | path/line normalization rule carried from EXP-0011 acceptance (documented, reused pattern) | adjudication contract | contract |
| 8 | noisy test selection | acceptance_cmd frozen per task before execution | INVALID_PROMPT_BYTES_CHANGED (frozen digests) | test (digest check) |
| 9 | task-list/context leakage between sessions | per-sequence worktrees + namespace stamps (isolation suite 14/14) | INVALID_WORKTREE_IDENTITY | existing suite + manifest test |
| 10 | mismatched prompt bytes | frozen prompt digest in admissibility | INVALID_PROMPT_BYTES_CHANGED | test |
| 11 | mapping/blinding recoverability | sealed mapping, salt out of repo; opaque unit ids | (blinding) | test (viewLeakCheck) |
| 12 | analyst holds both views | three-role view separation, mechanical leak check | (blinding) | test |
| 13 | zero-byte rules treatment (EXP-0011's core defect) | UCDL invalid-empty + expectEvidence at p>=2, PRE-SPEND | INVALID_UNINTENDED_EMPTY_TREATMENT | test |
| 14 | renderer-specific selection | one selection before rendering; pair-equivalence on selected_ids/payload | INVALID_SELECTED_EVIDENCE_MISMATCH | test |
| 15 | missing provider result | see #3 | INVALID_MISSING_PROVIDER_RESULT | test |
| 16 | duplicate metering | meter-run per-stream dedupe (existing, proven) | (ledger) | existing suite |
| 17 | concurrent ledger writes | meter-run flock (existing, proven) | (ledger) | existing suite |
| 18 | stale/wrong repository identity | admissibility worktree_identity + namespace verdict | INVALID_WORKTREE_IDENTITY | test |
| 19 | post-freeze harness change | FREEZE-MANIFEST verify before every cell | INVALID_HARNESS_CHANGED_AFTER_FREEZE | test (mutate-and-verify) |

Honest coverage note: rows marked "contract" (2, 4, 7) are enforced by the
frozen design and admissibility flow but their live behavior is only fully
exercisable when measured workers run; they are part of the spend-time
admissibility, not silently assumed. Every failure preserves the attempt
under an honest name; reruns follow only the frozen stopping rule.
