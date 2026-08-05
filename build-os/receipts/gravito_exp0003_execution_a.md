# Receipt — `gravito_exp0003_execution_a`

- **Packet id:** `PACKET-0051-exp0003-routing-frontier`
- **Title:** EXP-0003a — the **routing-frontier experiment, execution half**:
  preregistration first, then the harness, nine runs executed (3 conditions ×
  T3/T4/T5 shapes), sealed immutable run records, condition-level routing
  receipts driven through the PACKET-0050 close-time gate as data, and a
  blinded P/Q/R dataset. The analysis/reveal half is the NEXT packet
  (EXP-0003b).
- **Date closed:** 2026-08-05.
- **Lane:** `substantive`. **Depth: 3 — reason: fix-then-pass (1 enumerated
  item), announced** — build stage; qa ‖ reviewer CONCURRENTLY; one bounded
  fix round. Archivist close after the verdict (bookkeeping, not a gate).
- **Branch:** `claude/project-handoff-merge-ramhds`.
- **Routing:** this packet is the **FIRST LIVE USE of PACKET-0050's CLAUDE.md
  step 7** — its own routing receipt was issued BEFORE building
  (`build-os/packets/routing/routing-PACKET-0051-exp0003-routing-frontier-20260805T190501Z.md`),
  `selected_mode: gravito_full` via the honest value factor
  `high_rework_history` (three consecutive experiment packets required fix
  rounds); budgets attached and binding. Closed at this close — see §7.

## 1. Scope

**In:** the preregistered neutral three-condition protocol
(`build-os/experiments/EXP-0003-routing-frontier/PREREGISTRATION.md`,
committed BEFORE run 1); the EXP-0003 harness (modelUsage-native runner,
deterministic scripted T1/T2 setup, mechanical receipt gate) with same-commit
RULING-4 registration of its refusal-capable scripts; nine runs — conditions
A direct/raw · B gravito_light · C gravito_full-with-enforced-budgets, on
T3-style feature / T4-style regression / T5-style follow-up shapes over the
frozen parcel-billing seed; sealed run records + sha256 manifest; the two
condition close-gate verdicts retained as data; SEAL-TIME evaluator rule text;
the blinded P/Q/R dataset with the condition mapping WITHHELD from the tree by
hash; the one reviewer-required gate-calibration note.

**Explicitly out:** the blinded-evaluation commit, reveal, frontier
conclusion, and any response to the gate verdicts (EXP-0003b — the
evaluator-independence commit boundary is preserved); any edit to `bench/`,
either prior experiment tree, or the frozen PACKET-0050 routing tools (the
experiment RUNS them, never edits them); any softening of a REFUSED verdict;
`residue.md` (frozen).

## 2. Base and commits

- **Base:** `94c5187` — PACKET-0050's close, tree quiet at declaration;
  verified before building.
- `acfa1be` — docs(packet): declare PACKET-0051 **with its own routing
  receipt** — the first live use of step 7; `gravito_full` selected via the
  honest `high_rework_history` factor. 2 files, +59/−0.
- `18f82f6` — feat(exp0003): preregistration + harness + same-commit RULING-4
  registration of the refusal-capable harness scripts — census **118 → 121**,
  NO contract-gap replay (the PACKET-0045/0048 third-commit shape did not
  recur). 10 files, +1460/−4; `tests/exp3_harness_tests.sh` new.
- `cdfe1a3` — data(experiment): sealed run records + condition receipts and
  gate verdicts + blinded P/Q/R dataset + **SEAL-TIME evaluator rule text**
  (closing EXP-0002's audit gap IN ADVANCE — the rule text is committed before
  any evaluation is revealed) + mapping sha256 `8a063552…`. 28 files, +804/−0.
- `9beb73f` — the **one permitted fix commit** (see §6):
  `analysis/GATE_CALIBRATION_NOTE.md`, 1 file, +38/−0.
- **2 build commits + 1 data commit + 1 fix commit — within the contract's
  budget** (the declaration commit is docs-only; the fix commit is the single
  bounded post-gate round).

### Disjoint file-ownership manifest — SINGLE-WRITER, sequential commits, no fan-out

One writer produced the four commits in sequence; qa and the reviewer held no
mutating tools, so disjointness holds trivially — recorded anyway because a
missing manifest has broken closes before (the P2 precedent).

- `acfa1be` — `build-os/packets/active_packet.md` (append-only declaration);
  `build-os/packets/routing/routing-PACKET-0051-…-20260805T190501Z.md` (new).
- `18f82f6` — `build-os/experiments/EXP-0003-routing-frontier/PREREGISTRATION.md`
  (new); `…/harness/**` (3 files, new); `build-os/registry/control_registry.txt`,
  `neurocosmology_crosswalk.txt`, `CROSSWALK.md`, `README.md` (census 118→121);
  `tests/exp3_harness_tests.sh` (new); `tests/build_os_tests.sh` (chain line).
- `cdfe1a3` — `…/runs/**` (24 sealed files + `MANIFEST.sha256`, new);
  `…/analysis/EVALUATOR_RULE_TEXT.md`, `…/analysis/blinded_dataset.tsv`,
  `…/analysis/MAPPING_SHA256.txt` (new).
- `9beb73f` (fix) — `…/analysis/GATE_CALIBRATION_NOTE.md` (new, +38) only.
- Per-commit numstat sums: **41 distinct paths, +2361/−4**. Net union diff
  `94c5187..9beb73f` = 41 files, +2361/−4 — the two **RECONCILE EXACTLY**
  (zero cross-commit overlap; every path attributable to exactly one commit by
  `git show --numstat`).

## 3. What was executed

Nine runs — 3 conditions (A direct/raw · B gravito_light with the installed
surface and a binding light receipt · C gravito_full WITH ENFORCED BUDGETS,
installed surface + full receipt + circuit-breaker protocol) × 3 task shapes
(T3-style feature, T4-style regression, T5-style follow-up) — on the frozen
parcel-billing seed. **Deterministic scripted T1/T2 setup, digest-pinned and
harness-verified on every run, identical across conditions.** EXP-0002's
frozen prompts **byte-pinned**. Telemetry is **modelUsage-native** (the
EXP-0002 `usage.*` undercount defect fixed in the NEW runner, not by editing
frozen machinery) with **exact cost reconciliation on all nine runs**.
**9/9 durable accepted outcomes by external oracles; model string identical
across all nine runs.** EXP-0002 harness pieces reused by INVOCATION only
(seeder/oracles/injector — read-only, disclosed).

## 4. The headline the ANALYSIS packet inherits — recorded here, not concluded here

**Both condition receipts were REFUSED by the mechanical budget gate at
close** — the gate's first exercise on measured numbers; a refused receipt is
data, retained, never edited to pass:

- **B (gravito_light): REFUSED, 4 budget breaches — ZERO silent escalation**
  (selected=executed=light, 0 dispatches throughout: the binding-verdict half
  HELD; the budgets did not).
- **C (gravito_full): REFUSED, 5 breaches**, including **7 subagents vs 3**
  and **7.5M total tokens vs 2M**.
- **NO degradation notes were written by either condition's sessions — the
  protocol half of the circuit breaker did not execute in live sessions.**
- Both verdicts sealed as data
  (`runs/B_close/gate_result.txt`, `runs/C_close/gate_result.txt`), with the
  per-run decomposition in `analysis/GATE_CALIBRATION_NOTE.md` separating
  accumulation artifacts from genuine per-run breaches, handing the operator
  two calibration questions: (1) per-task vs per-sequence budget granularity;
  (2) band re-derivation from measured sequence data.

Drawing the frontier verdict from this is **EXP-0003b's job, not this
receipt's** — the vocabulary (frontier observed | frontier unstable | result
confounded) is preregistered and neutral.

## 5. QA proof — GREEN

- **FULL SUITE 2545 passed / 0 failed, solo.**
- **Commit-1 isolation:** **2482/0 at `acfa1be`** (docs-only declaration) and
  **2545/0 at `18f82f6`** — green in isolation at both build points.
- **Manifest 34/34 OK.** All **9 blinded rows re-derived 1:1** from the sealed
  records. **Ordering proven** — including the two records lacking
  `time_origin_ms`, via artifact mtimes.
- **Frozen surfaces zero-diff** (bench/, both prior experiment trees, the
  PACKET-0050 routing tools). **Census 121 reconciled.**
- **Harness re-driven:** digests, refusals, and prompt pins all exact.
- **Safety grep:** clean over `94c5187..9beb73f` (41 files, +2361/−4) — no
  push, merge, deploy, secret, amend, or rebase; re-verified by the archivist
  at close.
- **UI smoke:** n/a — this packet has no UI surface.

## 6. Reviewer verdict

**Fix-then-pass on ONE item:** the budget-granularity consideration was
silently unnamed — the condition receipts accumulate a three-task sequence
against single-run derived bands, and nothing in the tree said so. **Fixed in
`9beb73f`** (`analysis/GATE_CALIBRATION_NOTE.md`): the per-run decomposition
separating accumulation artifacts from genuine per-run breaches — **content
matches the reviewer's own derivation; NEITHER REFUSED verdict softened;
nothing sealed edited.** Targeted re-review confirmed; no reviewer exception
fired. **Verdict: PASS-AS-FIXED. Depth 3, announced.**

**Second eyes: NONE — single-model review, attempted and stated by BOTH
gates** (Codex host `api.openai.com:443` returns 403 CONNECT policy-denied at
the proxy). The router's `DC-0001` second-eyes streak numeral moves
**30 → 31 in this same close commit**, derived from the receipt store
(`ls build-os/receipts/gravito_*.md | wc -l`), never restated.

## 7. Live routing receipt closed at this close

`executed_mode: gravito_full` — **matches selected; no escalation**
(`escalation` stays `-`). Consumption fields stay `-` with the doctrinal
admission on the receipt: this packet's own serial agent passes and live
token/call/cost counters are **transcript-only** — nothing in git attests to
them, and a transcript figure is not written into a measured cell; `-` is the
admission the gate accepts (an unknown is not a zero). The nine EXPERIMENT
runs' consumption is measured and sealed under `runs/` — it belongs to the
experiment's condition receipts (§4), not to this packet's own receipt.
Post-fill sweep: `routing-check.sh check` — result recorded in the close
report (both receipts in the store checked).

## 8. Cosmetic twin — noted by both gates, deliberately retained

`receipt-final.md` / `receipt_final.md` **byte-identical pairs exist in both
close dirs** (`runs/B_close/`, `runs/C_close/`), and **both are manifested**.
They are treated as ONE receipt by the analysis and are **never deleted** —
removing a manifested file would break manifest integrity on a sealed tree.
Cosmetic, on the record, closed as such.

## 9. Residue — carried, not resolved here

1. **The blinded evaluation ALREADY EXISTS** (independent session, given the
   dataset + sealed rule text only) and is committed by the NEXT packet; its
   label is not named in this receipt to keep the reveal ordering clean. A
   lost session loses it — the reveal must come promptly.
2. The two gate-calibration questions (§4) are the operator's, handed onward
   with the per-run decomposition — not resolved here.
3. The circuit-breaker protocol half's non-execution in live sessions (§4) is
   a finding for EXP-0003b and the operator, recorded, not repaired.
4. The withheld condition mapping exists only outside the tree; its sha256
   `8a063552…` is pre-committed in `analysis/MAPPING_SHA256.txt`.

## 10. Open boundaries

- **NOTHING PUSHED.** `acfa1be`, `18f82f6`, `cdfe1a3`, `9beb73f`, and this
  close commit remain local pending explicit operator go — alongside the four
  earlier unpushed commits (`ac1581c`, `c49258e`, `4443360`, `94c5187`), the
  branch stands **9 commits ahead of origin after this close** (derived from
  `git log origin/claude/project-handoff-merge-ramhds..HEAD` at close).
  **None may be amended.**
- No merge, no deploy, no secrets touched. `residue.md` stays frozen.
- **Staged next but NOT DECLARED** (declaring is a routing act, not the
  archivist's): **EXP-0003b — analysis/reveal**: the blinded evaluation
  committed verbatim, the reveal against the pre-committed hash, the
  preregistered neutral frontier conclusion, and the gate verdicts reported
  beside it with the per-run decomposition.
