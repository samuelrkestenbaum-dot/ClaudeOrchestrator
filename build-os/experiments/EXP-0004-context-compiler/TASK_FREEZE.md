# EXP-0004 — frozen task set, seed and conditions

Frozen BEFORE any arm executes and BEFORE the blinded mapping is sealed.
Ancestry is the proof. Nothing here may change once execution begins.

## Seed and eligibility

- Repository: /home/user/empathiq-website
- **Pinned seed commit: `2543c873141fa64653a7993d326465d5e0dd1006`**
  (post-PILOT-0002; differs from the last product commit `b6ade3d` by
  gitignore entries and one already-generated receipt only — ZERO product
  change, diff is 2 files / +9 lines.)
- Eligibility, measured at that exact commit and recorded before any task
  was looked at: **no_parser 679/3390 (20.0%)**, mechanically below the
  registered 50% threshold (2 x 679 = 1358 < 3390). Reporter verdict and
  mechanical verdict AGREE. Recommended use state: **normal**.
- Supporting signal: 3390 files indexed; 2411/3390 (71.1%) carry >=1
  extracted symbol; 26,423 symbols; 20,095 symbol-table entries.
  Named heuristic bounds carried forward: `symbols_partial: true`
  (referenced_in is a whole-word text match) and
  `tests_covering_heuristic: true` (import-or-basename, not executed
  coverage).

## The five frozen tasks

Selected from the 27-candidate backlog the eligibility procedure emitted,
BEFORE any treatment ran. Disjoint from PILOT-0001's five tasks and
PILOT-0002's T1-T5 (the procedure excluded 10 prior-pilot clusters
mechanically; these five are not among them). None was chosen for being
compiler-friendly: all five are ordinary standing type debt in this
repository, spanning five different defect shapes.

| id | cluster | errors | files | shape |
|---|---|---|---|---|
| E1 | CAND-0009 | 15 | 6 | TS2769 no overload matches this call |
| E2 | CAND-0010 | 13 | 8 | TS2353 object literal has unknown property |
| E3 | CAND-0013 | 8 | 8 | TS2307 cannot find module / missing types |
| E4 | CAND-0016 | 6 | 4 | TS2554 wrong argument count |
| E5 | CAND-0018 | 5 | 4 | TS7006 parameter implicitly any |

Index signal per task (parsed / with-symbols / with-covering-test):
E1 6/6/4 · E2 8/8/6 · E3 8/8/2 · E4 4/4/3 · E5 4/4/2.

## Conditions held identical across arms

model (the session model at execution); repository seed `2543c87`;
task definition; acceptance criteria; retry limit; authority/mode policy;
baseline measurement method; measurement boundaries. The harness ASSERTS
each of these before a pair runs and refuses by name on a mismatch.

## Acceptance, per task, identical in both arms

(a) every error in the cluster resolved; (b) total tsc count strictly
below the count at that task's start; (c) ZERO new errors, measured
LINE-INSENSITIVELY (PILOT-0002 recorded 21 false positives from a naive
sorted diff after a fix inserted lines); (d) any test file covering a
touched surface still passes at its measured baseline; (e) no `any` cast
or fabricated interface used to silence an error — the PILOT-0002 T4
finding, that a false type declaration is worse than an `any`, is binding.

## Treatment — substitution, never addition

Arm A `standard_context`: exactly what execution receives today.
Arm B `compiled_context`: the rendered capsule and NOTHING ELSE at task
start — no broad context, no transcript replay, no duplicate repository
summary. A pair whose arm B starts with both is registered
`result confounded` and EXCLUDED from the aggregate, never repaired and
re-run. Progressive expansions after start are permitted and measured.

## Verdict rules — unchanged, restated for the record

Seven outcomes: `supported` | `compression only` | `acceleration only` |
`inconclusive` | `context compilation harmful` | `small-because-uninformed`
| `result confounded`. Token criterion >=25% median uncached reduction.
Wall-clock bands per Amendment 3.2. `supported` requires all four gates
(acceptance intact, token criterion, >=25% faster median, no material
rise in intervention or rework). Acceptance-quality veto is binding.
Minimum five clean pairs; below it the verdict is `inconclusive` AND must
state pair count, minimum, direction, magnitude and why underpowered.

## Not yet done — the one remaining gate before execution

The blinded X/Y mapping is NOT sealed. It requires an operator-declared
SALT, which is withheld from this repository. Sealing must happen, and
`mapping.sha256` must be committed, BEFORE the first task runs. Sealing
after execution begins makes the commitment worthless.
