# The exact X/Y-neutral rule text handed to the blinded evaluator (committed for audit)

qa's finding at the reveal gate: the neutralized rule the evaluator worked from was
not committed, so the neutralization could not be audited against PREREGISTRATION.md
§6. This file closes that gap. The text below is what the evaluator received,
verbatim. Note where it differs from §6: the registered rule gates steps 2 and 4 on
a ≥25% difference IN B'S FAVOR and pre-assigns the B-worse case to rule 3; the
neutral form below is symmetric ("one condition's ... below the other's"), which a
blind evaluator requires — and which is exactly why the TRANSLATION stage must
re-apply the registered directional rule once the mapping is known. It did not on
the first pass; both gates caught it; the corrected label is in CONCLUSION.md.

---

- Durable accepted outcome = accepted:yes (all 10 here).
- Sequence-level primary: per condition, aggregate efficiency = Σ total_tokens across the condition's five runs ÷ its accepted-outcome count. Compute the same with tokens_uncached. Also per-condition totals of cost and wall clock.
- Per-task paired differences: for each of T1..T5, which condition used fewer total_tokens, and the ratio.
- Cumulative analysis: cumulative Σ total_tokens (and uncached, and cost) after T1, T2, T3, T4, T5 for each condition. Identify any crossover: the first task index at which the cumulatively-cheaper condition changes, and the state at T5. Report the full curve, never only the final aggregate.
- Decision, in order:
  1. RESULT CONFOUNDED if: model_used differs across rows; either T1 row has seed_verified=no; accepted counts differ between conditions by ≥2; or the total and uncached sequence-level comparisons point in OPPOSITE directions.
  2. SUSTAINED-WORKLOAD SAVINGS SUPPORTED (direction stated as X or Y) if: one condition's sequence-level total tokens per accepted outcome is ≥25% below the other's AND ≥4 of the 5 per-task differences agree with that direction AND the uncached comparison agrees.
  3. NO SUSTAINED-WORKLOAD SAVINGS DETECTED if the sequence-level difference is <25%.
  4. PROMISING BUT UNDERPOWERED if ≥25% but per-task agreement <4/5.
