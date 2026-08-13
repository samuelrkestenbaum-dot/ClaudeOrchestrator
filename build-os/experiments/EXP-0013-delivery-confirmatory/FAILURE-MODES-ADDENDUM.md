# EXP-0013 FAILURE-MODES — execution-readiness ADDENDUM

FAILURE-MODES.md is frozen in FREEZE-MANIFEST v1 and stays byte-identical.
This addendum upgrades its three "contract"-only rows (2, 4, 7) to rows with
EXECUTABLE observables, per the owner's execution-readiness authorization.
Nothing here weakens a v1 mechanism; each row gains a proof that runs today
with zero spend.

| # | Observed defect | New executable mechanism | Observable | Proof |
|---|---|---|---|---|
| 2 | background monitor cannot resume headless worker | controller.mjs is the ONLY launcher: one process supervises spawn→timeout→reap synchronously; no detached monitor exists to lose a worker. After every cell, `detectOrphans(marker)` scans /proc for any process still carrying the cell's environment marker | orphan scan result logged per cell (`orphans_<cell>` step); non-empty scan FAILS the cell | test (fake worker leaves a marked child; detectOrphans finds it; clean run reports clean) |
| 4 | timeout/truncated work | `supervise()` owns a wall-clock timer: SIGKILL to the worker's whole process GROUP at the frozen ceiling; `terminal_reason="timeout"` recorded in the cell record; cell becomes infrastructure-invalid under the reliability gate | terminal_reason field in every cell record; the killed group is verified dead | test (fake slow worker + 1s ceiling → terminal_reason=timeout, process group gone) |
| 7 | error-diff oracle line shifts | oracle.mjs compares error IDENTITY MULTISETS — (file, code, normalized message) with multiplicity — line/column numbers are NEVER consulted in acceptance | `comparison` field in every acceptance record names the rule; regressions list identities, not lines | test (uniform +7 line shift of the whole baseline → zero false regressions; synthetic new identity → detected) |

Remaining honestly-not-executable-before-spend items: none of rows 2/4/7 —
their mechanisms now run in the no-spend suite. Live-provider behaviors that
cannot be observed before spend (true provider result-event contents, real
cache warming) remain covered by the spend-time admissibility flow and are
labeled NOT_OBSERVABLE where they appear in receipts.
