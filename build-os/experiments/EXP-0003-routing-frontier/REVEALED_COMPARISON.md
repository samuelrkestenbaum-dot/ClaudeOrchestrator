# EXP-0003 — Revealed comparison: the routing frontier

## Ceremony
Mapping (`A=Q direct · B=R gravito_light · C=P gravito_full`) entered the tree in
THIS commit and hashes byte-exact to the sha256 pre-committed at seal
(`8a063552…`). The blinded analysis was committed one commit earlier, mapping
absent (ancestry-provable). Translation applies NO directional rule — none
exists; the label is the evaluator's, unchanged: **`frontier unstable — winners
flip on uncached`**.

## The frontier, translated (n=1 per cell; totals | uncached)

| Shape | direct (A) | light (B) | full+budgets (C) | totals winner | uncached winner |
|---|---|---|---|---|---|
| T3 feature | **1,725,858** \| 96,453 | 2,059,417 \| **85,662** | 3,115,348 \| 268,812 | **direct** | **light** — FLIP |
| T4 regression | 728,612 \| 31,886 | 831,404 \| **26,494** | **288,368** \| 27,164 | **full** | **light** — FLIP |
| T5 follow-up | **499,887** \| **39,897** | 1,402,352 \| 59,567 | 4,096,490 \| 262,264 | **direct** | **direct** — stable |

Cost and wall clock track the totals ordering in every shape (evaluator §e).
Full is the most expensive condition on T3 ($2.67) and T5 ($3.00) and the
cheapest on T4 ($0.26, zero dispatches — it behaved light there); full never
wins an uncached ranking anywhere.

## Reading the instability honestly (n=1; patterns, not conclusions)
- Totals are 90.6–94.4% cache_read in every cell, and the fixed A→B→C order
  means cache warmth favors later conditions (named confound C2). Direct's
  totals wins on T3/T5 run AGAINST that gradient; full's totals losses on
  T3/T5 run against its own warmth advantage.
- On the caching-free lens, **light wins T3 and T4 and is never worse than
  second** — a third consecutive data point (after EXP-0002's T1/T4) for the
  operator's thesis that repository context amortizes on mid-sequence,
  context-bearing work. **Full never wins uncached.**
- T5's stable direct win repeats EXP-0002's T5 pattern: the follow-up task, as
  authored, rewards a small fresh look over both context loading and ceremony.

## The gate verdicts beside the frontier (§10.5, with the calibration note)
Both condition receipts were REFUSED at close — sealed as data. Per the
committed per-run decomposition (`analysis/GATE_CALIBRATION_NOTE.md`): B's
total-token breach is genuine on every individual run and its cost breach on
two of three; C's subagent (4>3 on T3 alone), total, uncached, and cost
breaches are genuine per-run, its wall-clock breach an accumulation artifact.
**Zero silent escalation anywhere** — the binding-verdict half of PACKET-0050
held in live sessions. **Zero degradation notes were written** — the protocol
half of the circuit breaker did not execute; sessions ran through budgets
without declaring it. The mechanical gate caught both, which is the design.

## Boundaries
Nine runs, one per cell, one authored repository, fixed condition order, one
model configuration. "Frontier observed" strength was never available at n=1;
the flips make even the observed orderings unstable between the two token
lenses. Replicates and randomized condition order are the obvious next
operator decisions; neither is started here.
