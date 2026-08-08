# EXP-0005 — RESULT (revealed, frozen)

**Registered outcome: `gravito_system_harmful`.**

Seal verified at reveal: the mapping digest recomputed to
`db9348fbc656edda…`, identical to the digest committed before any arm executed.

## 1. Condition mapping

| label | condition |
|---|---|
| **X** | `native_claude` |
| **Y** | `whole_gravito` |

## 2. The twelve paired outcomes

| task | shape | native | Gravito |
|---|---|---|---|
| T01 | behavioural | rejected | rejected (no work delivered) |
| T02 | behavioural | **accepted** | rejected (no work delivered) |
| T03 | behavioural | **accepted** | rejected (no work delivered) |
| T04 | type defect | **accepted** | rejected (no work delivered) |
| T05 | type defect | **accepted** | rejected (no work delivered) |
| T06 | type defect | **accepted** | rejected (no work delivered) |
| T07 | test reliability | **accepted** | rejected (no work delivered) |
| T08 | test reliability | **accepted** | rejected (no work delivered) |
| T09 | test reliability | rejected | rejected (no work delivered) |
| T10 | suppression | **accepted** | rejected (no work delivered) |
| T11 | suppression | **accepted** | rejected (no work delivered) |
| T12 | suppression | **accepted** | rejected (no work delivered) |

Native's two rejections were judged on merit by the blinded adjudicator: T01
rewrote the planner but the named test still fails; T09 wrote a real test whose
run exits 1 with all 39 tests skipped, so the placeholder never passed.

## 3–14. Registered comparisons

| metric | native | Gravito |
|---|---:|---:|
| accepted outcomes | **10 / 12** | **0 / 12** |
| acceptance rate | 83.33% | 0.00% |
| total uncached tokens | 2,571 | 9,228 |
| total tokens | 20,268,553 | 15,087,424 |
| **UIC** (accepted / 1M uncached) | **3,889.54** | **0.00** |
| uncached tokens per accepted outcome | 257.10 | **UNDEFINED** |
| total tokens per accepted outcome | 2,026,855.30 | **UNDEFINED** |
| median elapsed | 164.54 s | 143.30 s |
| API-equivalent cost | $19.645 | $19.913 |
| cost per accepted outcome | $1.9655 | **UNDEFINED** |
| rework rounds (Σ turns) | 384 | 245 |
| human interventions | 0 | 0 |
| regressions | **UNAVAILABLE** | **UNAVAILABLE** |
| timeouts / truncation | 0 | 0 |
| void or retried units | 0 | 0 |
| governance files changed | 0 | 0 |

**UNDEFINED is not zero and not infinity.** Gravito produced no accepted
outcome, so every per-accepted-outcome ratio for it has a zero denominator and
was refused rather than fabricated.

Gravito spent **3.59× the uncached tokens** of native and **1.35% more cost**,
for zero accepted outcomes. It used 25.6% fewer *total* tokens — the one
defined metric pointing its way, and it points that way because it stopped
early rather than because it worked efficiently.

## 16. Registered verdict

`gravito_system_harmful`. The **acceptance veto** fires on its own — 0/12
against 10/12 — and there is no compute gain to trade against it.

## 17. Threshold table

| reduction in uncached tokens per accepted outcome | status |
|---|---|
| 25% | **UNDEFINED** |
| 50% | **UNDEFINED** |
| 70% | **UNDEFINED** |
| 80% | **UNDEFINED** |
| 90% | **UNDEFINED** |

All five are undefined for the same reason: the ratio requires a Gravito
accepted outcome and there are none. Marking them "NOT MET" would imply the
comparison was made and lost; it could not be made.

## 15. The cause — a bootstrap deadlock

The substrate ships `.claude/hooks/routing-gate.sh mutgate`, a `PreToolUse`
hook blocking `Bash`, `Edit` and `Write` until an open routing receipt exists.
Creating that receipt requires `route-task.sh`, which requires `Bash`, which the
gate blocks. **The arm cannot clear the gate that stops it clearing the gate.**

The gate is **tracked** and ships. The routing `live_state/` that opens it is
**untracked**, was classified by the memory pin as disposable per-session state,
and is removed by `git clean -fdx` during restore. A clean checkout receives the
lock and not the key.

Operator ruling: **genuine treatment behaviour, not `result_confounded`.** Arm G
was specified as the substrate that would actually ship, and nothing in the
frozen design promised a pre-opened receipt. A system that works only because
residue from earlier sessions happens to exist on its development machine does
not bootstrap from its own shipping state.

Not repaired and not re-run: initialising routing state and repeating the same
twelve tasks under this name would convert a real failure into a post-hoc
repaired experiment.

## 18. Limitations

1. **One repository.** "The substrate works" and "the substrate suits this
   codebase" remain inseparable.
2. **Established Gravito memory vs a fresh native worker** — the asymmetry is
   the treatment, but it means this is not two equally informed workers.
3. **No sequential compounding** — a separate hypothesis, unmeasured here.
4. **Four task shapes, not five.** `implementation_gap` was dropped when its
   registered population proved to be mostly detector documentation.
5. **EXP-0004's 27-vs-28 backlog discrepancy** is unresolved and was not
   investigated by altering frozen evidence.
6. **Role separation at run time was discipline, not structure** — though the
   adjudicator and analyst each ran in separate agents holding only their own
   view, and both reported the blind intact.
7. **The flake bound is one-sided** — 1.17% bounds observed failures, not the
   tree.
8. **`regressions` and `subagent_invocations` are UNAVAILABLE on all 24 units.**
   Consequently the "no material increase in regressions" half of gate 2 is
   **unverifiable**, and this is recorded rather than assumed satisfied.
9. **Broader four-surface readiness remains a separate FAIL** and forms no part
   of this verdict.

## 19. Post-Outcome Disposition — first prospective test, and it FAILED to find the defect

The frozen rules were run unmodified against EXP-0005. They generated **two
findings, both `unsupported_hypothesis`, and ZERO execute-class findings**:

| rule | class | disposition |
|---|---|---|
| `sign-flip-across-tasks` | unsupported_hypothesis | queue |
| `no-gate-met-either-direction` | unsupported_hypothesis | observe |

**Neither is the bootstrap defect.** Neither is the durability-classification
defect. The engine did not derive the thing the experiment actually found.

**Why it missed it.** Its only acceptance rule,
`acceptance-shortfall-with-regression`, requires `regressions > 0`. The Gravito
arms did not break anything — they did *nothing* — and `regressions` was
UNAVAILABLE regardless. **The rule set has no predicate for a total acceptance
floor, and none for "a condition produced no output at all."**

Mechanically generated, with **no post-result rule changes**: yes — and that is
precisely why the miss is reportable. Adding a rule now to catch what we already
know would be fitting the detector to the answer, which is the failure
`disposition.mjs`'s own header warns about. The honest reading of its first
prospective generalisation test is that **it did not generalise**.

The two findings a human derives immediately — the bootstrap defect and the
durability-classification defect — are recorded in `POST-OUTCOME.md` as
**human-derived**, explicitly not as engine output.
