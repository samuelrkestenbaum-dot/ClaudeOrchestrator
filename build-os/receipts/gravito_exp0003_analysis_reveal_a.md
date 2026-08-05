# Receipt — `gravito_exp0003_analysis_reveal_a`

- **Packet id:** `PACKET-0052-exp0003-analysis-reveal`
- **Title:** EXP-0003b — the **routing-frontier experiment, analysis/reveal
  half**: outputs 3–5. The blinded evaluator's report committed VERBATIM before
  the mapping entered the tree, the reveal verified byte-exact against the
  pre-committed hash, the routing frontier translated with NO directional rule
  (none exists), the gate verdicts reported beside it, and the preregistered
  conclusion. **This closes the operator's three-part directive** (publish
  EXP-0002 → routing correction → EXP-0003) — **EXP-0003 is COMPLETE.**
- **Date closed:** 2026-08-05.
- **Lane:** `substantive`. **Depth: 3 — reason: fix-then-pass (4 enumerated
  items), announced** — build stage; qa ‖ reviewer CONCURRENTLY; one bounded
  fix round. Archivist close after the verdict (bookkeeping, not a gate).
- **Branch:** `claude/project-handoff-merge-ramhds`.
- **Routing:** own routing receipt issued BEFORE building
  (`build-os/packets/routing/routing-PACKET-0052-exp0003-analysis-reveal-20260805T210607Z.md`),
  `selected_mode: gravito_full` via the honest value factor
  `high_rework_history` (the EXP-0002 reveal needed two fix rounds; this is the
  same reveal-translation task class); budgets attached and binding. Closed at
  this close — see §7.

## 1. Scope

**In:** EXP-0003 outputs 3–5 —
`analysis/BLINDED_ANALYSIS.md` (the independent evaluator's report, committed
byte-verbatim with only the disclosed `<`-unescaping transport restoration) +
`analysis/BLINDED_ANALYSIS_PROVENANCE.md` (sibling provenance: fresh context,
dataset + sealed rule text only, no repository access, no mapping); the reveal
(`analysis/blind_mapping.txt`, entering the tree ONLY after the analysis
commit and hashing byte-exact to the sha256 pre-committed at seal);
`REVEALED_COMPARISON.md` (the routing frontier with the gate verdicts beside
it per §10.5, using the committed per-run decomposition); `CONCLUSION.md`
drawing exactly one §8 label with translation applying NO directional rule.

**Explicitly out:** any edit to the sealed `runs/` tree,
`blinded_dataset.tsv`, `EVALUATOR_RULE_TEXT.md`, `GATE_CALIBRATION_NOTE.md`,
`PREREGISTRATION.md`, both prior experiment trees, `bench/`, or the frozen
PACKET-0050 routing tools; any softening of a REFUSED gate verdict; acting on
any of the four operator questions (recorded, handed over, not acted on);
`residue.md` (frozen).

## 2. Base and commits

- **Base:** `e276b88` — PACKET-0051's close, tree quiet at declaration;
  verified before building.
- `9d78999` — docs(packet): declare PACKET-0052 with its own routing receipt
  (`gravito_full` via `high_rework_history`). 2 files, +48/−0.
- `1cb31f6` — docs(experiment): the blinded analysis committed VERBATIM +
  sibling provenance — mapping absent from the tree at this commit
  (ancestry-provable). 2 files, +121/−0.
- `f2a2b3a` — data(experiment): the reveal — mapping (`A=Q · B=R · C=P`)
  verified byte-exact against the pre-committed sha256 `8a063552…`;
  `REVEALED_COMPARISON.md`; `CONCLUSION.md`. 3 files, +101/−0.
- `a3b0ba7` — the **one permitted fix commit** (see §6). 2 files, +19/−11.
- **2 build commits + 1 data commit + 1 fix commit — within the contract's
  budget** (the declaration commit is docs-only; the fix commit is the single
  bounded post-gate round).

### Disjoint file-ownership manifest — SINGLE-WRITER, sequential commits, no fan-out

One writer produced the four commits in sequence; qa and the reviewer held no
mutating tools, so disjointness holds trivially — recorded anyway because a
missing manifest has broken closes before (the P2 precedent).

- `9d78999` — `build-os/packets/active_packet.md` (append-only declaration);
  `build-os/packets/routing/routing-PACKET-0052-…-20260805T210607Z.md` (new).
- `1cb31f6` — `…/analysis/BLINDED_ANALYSIS.md`,
  `…/analysis/BLINDED_ANALYSIS_PROVENANCE.md` (both new).
- `f2a2b3a` — `…/analysis/blind_mapping.txt`, `…/REVEALED_COMPARISON.md`,
  `…/CONCLUSION.md` (all new).
- `a3b0ba7` (fix) — `…/REVEALED_COMPARISON.md`, `…/CONCLUSION.md` only
  (bounded corrections to the two reveal documents; nothing sealed touched).
- Per-commit numstat sums: **7 distinct paths, +289/−11.** Net union diff
  `e276b88..a3b0ba7` = **7 files, +278/−0** — the two **RECONCILE EXACTLY**
  (the 11 removed lines are lines the build commits added and the fix commit
  rewrote within-range; zero paths outside the manifest).

## 3. THE RESULT — the registered label, the evaluator's own, carried unchanged

**`frontier unstable — winners flip on uncached`** — the blinded evaluator's
mechanical label under the preregistered neutral rule; translation applied
**NO directional rule, because none exists** (the operator's explicit
instruction after EXP-0002; the mistranslation class structurally cannot
recur). The frontier at n=1:

- **direct** wins T3/T5 totals and **T5 outright** (the stable cell — both
  lenses agree).
- **light** wins the **uncached lens on T3 and T4** — the **third and fourth
  consecutive amortization DATA POINTS** after EXP-0002's T1/T4 — and is
  **never worse than second on uncached**.
- **full** wins **T4 totals only** and **never wins an uncached ranking
  anywhere**.
- Totals are **90.6–96.8% cache_read in every cell** (named confound C2: fixed
  A→B→C order, cache warmth favors later conditions); the lens choice changes
  the winner on 2 of 3 shapes — itself a finding about how cache accounting
  should enter routing decisions.

**Gate verdicts beside the frontier (§10.5):** both condition receipts
**REFUSED** — sealed as data, per-run decomposition committed PRE-REVEAL in
`analysis/GATE_CALIBRATION_NOTE.md`. **ZERO silent escalation** — the
PACKET-0050 binding-verdict rule held in live sessions. **ZERO degradation
notes** — the protocol half of the circuit breaker did not execute unattended;
the mechanical close-time gate caught both, which is the design.

**Handed to the operator, recorded not acted on — four questions:**
(1) budget granularity, per-task vs per-sequence; (2) band re-derivation from
the measured sequence data; (3) making mid-flight budget awareness real for
live sessions; (4) the totals-vs-uncached lens choice for routing.

## 4. EXP-0003 completeness — all five outputs, in ancestry order

`18f82f6` (preregistration) → `cdfe1a3` (sealed records + gate verdicts +
blinded dataset + mapping hash) → `1cb31f6` (blinded analysis, verbatim,
mapping absent) → `f2a2b3a` (reveal, mapping byte-exact vs `8a063552…`) →
`a3b0ba7` (corrected conclusion). The evaluator-independence commit boundary
held: analysis before mapping, provable from ancestry. The mapping file's
sha256 was re-verified at this close against
`analysis/MAPPING_SHA256.txt` — byte-exact.

## 5. QA proof — GREEN, with ONE attributed base finding

- **FULL SUITE 2545 passed / 0 failed, solo — with the 3-receipt routing
  sweep clean.** **Commit-1 isolation: green** (the docs-only declaration
  `9d78999`).
- **Ordering, hash, and ancestry exact** — the reveal-after-analysis ordering
  proven from ancestry; the mapping hash byte-exact against the seal.
- **All arithmetic recomputed independently and matching** — the nine cells,
  the secondaries, the cache percentages, the frontier rankings.
- **Frozen surfaces zero-diff** (sealed `runs/`, blinded dataset, rule text,
  calibration note, preregistration, both prior experiment trees, `bench/`,
  routing tools). **Census 121 reconciled** (no registry change this packet).
- **ONE attributed base finding, pre-existing at base:** PACKET-0051's close
  (`e276b88`) left a bare `**Packet id:**` marker at
  `active_packet.md:2301` instead of the `**Packet id (CLOSED):**`
  convention, so `bandwidth-check.sh`'s packet singleton read **2 in flight**.
  Attributed to the base, not this packet's commits; **fixed at this close**
  — the marker renamed one-for-one in place (nothing above `:89` moved),
  alongside this packet's own close rename. **Post-fix:
  `bandwidth-check.sh check` reads 0 packet(s) in flight, exit 0.**
- **Safety grep:** clean over `e276b88..a3b0ba7` (7 files, +278/−0) — no
  push, merge, deploy, secret, amend, or rebase; re-verified by the archivist
  at close.
- **UI smoke:** n/a — this packet has no UI surface.

## 6. Reviewer verdict

**Fix-then-pass on FOUR prose/number items** — the
repeated-evaluator-claims-without-verification class, including a **genuine
internal §e/§b inconsistency in the sealed evaluator report**:

1. **T4 secondaries corrected, with the evaluator discrepancy stated** — the
   sealed report's §e asserts T4 "P < Q < R" while its own §b secondaries
   table correctly lists P, R, Q; the sealed file stays verbatim and the
   corrected fact (direct/light swap on cost and wall clock) is stated in the
   reveal.
2. **Cache range corrected to 90.6–96.8%.**
3. **Data-point counting corrected** — light's amortization is the third AND
   fourth consecutive data points (T3 and T4 here, after EXP-0002's T1/T4);
   EXP-0001 contributes none.
4. **One-surface bounding** — EXP-0001's ~2× claim bounded to the one full
   surface it actually measured.

**All four fixed in `a3b0ba7` exactly as enumerated**; targeted re-review
confirmed; no reviewer exception fired; neither sealed artefact edited; the
label unchanged. **Verdict: PASS-AS-FIXED. Depth 3, announced.**

**Second eyes: NONE — single-model review, attempted and stated on all gate
passes** (Codex host `api.openai.com:443` returns 403 CONNECT policy-denied at
the proxy). The router's `DC-0001` second-eyes streak numeral moves
**31 → 32 in this same close commit**, derived from the receipt store
(`ls build-os/receipts/gravito_*.md | wc -l`), never restated.

## 7. Live routing receipt closed at this close

`executed_mode: gravito_full` — **matches selected; no escalation**
(`escalation` stays `-`). Consumption fields stay `-` with the transcript-only
admission on the receipt: this packet's own serial agent passes and live
token/call/cost counters are transcript-only — nothing in git attests to
them, and a transcript figure is not written into a measured cell; `-` is the
admission the gate accepts (an unknown is not a zero). Post-fill sweep:
`routing-check.sh check` = **3 receipts checked, 0 violations, exit 0.**

## 8. Residue — carried, not resolved here

1. **The four operator questions (§3)** — budget granularity, band
   re-derivation, mid-flight budget awareness, the totals-vs-uncached lens —
   handed over with the per-run decomposition; nothing acted on.
2. **Replicates and randomized condition order** are the obvious next operator
   decisions if frontier stability is worth buying; the n=1 flips say the
   current orderings are not decision-grade. Neither is started here.
3. **`current_state.md` is nearly full:** after this close's bounded append it
   stands within ~1.7 KB of the 204,800 B rotation ceiling — **the NEXT close
   cannot append a close record without the operator authorizing the
   re-block** (the `gravito_current_state_reblock_a` procedure, an operator
   gate, not an archivist act).
4. The circuit-breaker protocol half's live non-execution remains an operator
   finding, recorded in the conclusion, not repaired.

## 9. Open boundaries

- **NOTHING PUSHED.** `9d78999`, `1cb31f6`, `f2a2b3a`, `a3b0ba7`, and this
  close commit remain local pending explicit operator go — the branch stands
  **14 commits ahead of origin after this close** (derived from
  `git rev-list --count origin/claude/project-handoff-merge-ramhds..HEAD` at
  close: 13 before the close commit, +1). **None may be amended.**
- No merge, no deploy, no secrets touched. `residue.md` stays frozen.
- **Nothing staged next.** The operator's three-part directive (publish
  EXP-0002 → routing correction → EXP-0003) is **complete**; the next move —
  calibration, replication, productization, or push — is the operator's
  decision, and declaring any packet for it is a routing act, not the
  archivist's.
