# The exact neutral rule text for the blinded evaluator — committed AT SEAL TIME
# (closing the EXP-0002 audit gap in advance, per PREREGISTRATION.md §9.3).
# The evaluator receives ONLY the blinded dataset and the text below.

---

Conditions are P, Q, R (mapping unknown). Nine rows: three task shapes (T3, T4,
T5), one run per condition per shape. All token columns are session-level
provider aggregates (mu_*), reconciled against provider cost per row
(cost_reconciliation_agrees).

- Durable accepted outcome = accepted:yes.
- PRIMARY, per shape (T3, T4, T5 SEPARATELY): rank the three conditions by
  total_tokens, lowest wins the shape (n=1 per cell: the cell value IS the
  run's total). Compute the uncached ranking (tokens_uncached) beside it for
  every shape, plus cost, wall clock as secondaries.
- A condition not accepted in a shape is unranked there and reported by name;
  a shape with fewer than two accepted conditions yields no comparison there.
- The deliverable is the FRONTIER TABLE: per shape, the full ranking and the
  winner, totals and uncached side by side, with magnitudes (ratios between
  adjacent ranks).
- The rule is NEUTRAL: no condition is favored, no direction pre-assigned.
- Decision, in order:
  1. RESULT CONFOUNDED if: model_used differs across the nine rows; any
     post_setup_digest_ok is not "yes"; any cost_reconciliation_agrees is not
     "yes"; or acceptance failures leave fewer than two rankable conditions in
     two or more shapes.
  2. FRONTIER UNSTABLE — WINNERS FLIP ON UNCACHED if every shape is rankable
     and unconfounded, but in at least one shape the uncached winner differs
     from the totals winner.
  3. FRONTIER OBSERVED if every shape is rankable and totals and uncached
     agree on every shape's winner. Report per shape with magnitudes, at n=1
     strength ("frontier observed", never "supported").
- Required content: (a) per-row integrity (input+output+cache_creation+
  cache_read = total; total − cache_read = uncached; flag failures);
  (b) the frontier table; (c) the rule walked in order with arithmetic;
  (d) exactly one label; (e) neutral secondary observations (cost, wall
  clock, tool failures, parent-call-vs-tool-event structure); (f) a blinding
  affirmation.
