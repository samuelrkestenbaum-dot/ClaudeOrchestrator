# Gate-calibration note for the analysis packet (reviewer-required; written BEFORE the reveal)

The condition receipts' budget bands are PACKET-0050 DERIVED DEFAULTS, computed
from SINGLE-RUN EXP-0002 measurements — while this experiment's one receipt per
condition ACCUMULATES a three-task sequence (`expected_session_count: 3`). When
§10.5 reports the gate verdicts beside the frontier, the analysis MUST decompose
per run, from the sealed records, to separate accumulation artifacts from
genuine per-run breaches. The decomposition, derived at this note's writing:

- **B (gravito_light), REFUSED on 4 budget lines:**
  - `consumed_uncached_tokens` 171,723 vs 60,000 — per-run 85,662 / 26,494 /
    59,567: T3 alone exceeds the band; the sum inflates it further. MIXED.
  - `consumed_model_calls` 81 vs 25 — per-run 41 / 17 / 23: T3 alone exceeds;
    others within. MIXED.
  - `consumed_total_tokens` 4,293,173 vs 500,000 — per-run 2.06M / 0.83M /
    1.40M: EVERY run exceeds the band individually. GENUINE per-run breach.
  - `consumed_cost_usd` 2.60 vs 0.75 — per-run 1.29 / 0.43 / 0.88: two of
    three runs exceed individually. LARGELY GENUINE.
- **C (gravito_full), REFUSED on 5 budget lines:**
  - `consumed_subagents` 7 vs 3 — per-run 4 / 0 / 3: T3's 4 exceeds the cap on
    its own. GENUINE (marginal), plus accumulation.
  - `consumed_total_tokens` 7,500,206 vs 2,000,000 — per-run 3.12M / 0.29M /
    4.10M: two runs exceed individually. GENUINE.
  - `consumed_wall_clock_s` 1,241.83 vs 900 — per-run 576 / 47 / 619: no
    single run exceeds; ACCUMULATION ARTIFACT.
  - `consumed_uncached_tokens` 558,240 vs 120,000 — per-run 268,812 / 27,164 /
    262,264: two runs exceed individually. GENUINE.
  - `consumed_cost_usd` 5.93 vs 1.50 — per-run 2.67 / 0.26 / 3.00: two runs
    exceed individually. GENUINE.

Neither REFUSED verdict is softened by this note: the gate ruled correctly on
the receipts as filled, no degradation notes were written by either condition's
sessions, and the absence of degradation notes is itself a finding about the
protocol half of the circuit breaker. The calibration questions this hands the
operator: (1) per-task vs per-sequence budget granularity in receipts that span
sequences; (2) whether the PACKET-0050 single-run bands need per-mode
re-derivation now that measured light/full sequence data exists. No sealed
record, gate result, receipt, or the preregistration is edited by this note.
