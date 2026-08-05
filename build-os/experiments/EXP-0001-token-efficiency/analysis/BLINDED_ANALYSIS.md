# EXP-0001 — Blinded analysis (conditions X and Y; mapping unknown to the evaluator)

> Provenance note (added by the orchestrator at commit time, outside the evaluator's text):
> the report below is the independent evaluator's output, committed verbatim. The evaluator
> was a fresh agent context given ONLY the blinded dataset and the preregistered rule in
> X/Y-neutral form — no repository access, no schedule, no arm names, no mapping. The
> mapping is revealed only in a LATER commit, verified against the sha256 committed in
> `MAPPING_SHA256.txt` before this analysis existed.

Evaluator: independent, blinded. Arms are labeled X and Y only; the evaluator does not know and did not attempt to discover what either condition is. This analysis applies the preregistered mechanical rule exactly as written, to the supplied TSV only.

---

## (a) Data-integrity checks

For every row, two identities were verified:

1. `input + output + cache_creation + cache_read = total_tokens`
2. `total_tokens − cache_read = tokens_uncached`

| blind_run_id | input+output+creation+read | total_tokens | Identity 1 | total − cache_read | tokens_uncached | Identity 2 |
|---|---:|---:|---|---:|---:|---|
| t1_p1_Y | 10+720+38360+148887 = 187977 | 187977 | pass | 39090 | 39090 | pass |
| t1_p1_X | 14+2245+18088+291954 = 312301 | 312301 | pass | 20347 | 20347 | pass |
| t1_p2_X | 14+1699+17570+291881 = 311164 | 311164 | pass | 19283 | 19283 | pass |
| t1_p2_Y | 12+894+10125+216058 = 227089 | 227089 | pass | 11031 | 11031 | pass |
| t1_p3_Y | 8+1291+10441+141670 = 153410 | 153410 | pass | 11740 | 11740 | pass |
| t1_p3_X | 16+2281+18047+337635 = 357979 | 357979 | pass | 20344 | 20344 | pass |
| t1_p4_X | 16+1816+17921+337002 = 356755 | 356755 | pass | 19753 | 19753 | pass |
| t1_p4_Y | 8+1201+10593+141254 = 153056 | 153056 | pass | 11802 | 11802 | pass |
| t1_p5_Y | 8+1120+10783+141700 = 153611 | 153611 | pass | 11911 | 11911 | pass |
| t1_p5_X | 14+1551+17630+293249 = 312444 | 312444 | pass | 19195 | 19195 | pass |

**All 10 rows pass both identities. No failing rows.** Non-blocking observation: row t1_p3_Y carries a censored `ttfcc_s` value ("<=24.51"); ttfcc is not part of the preregistered rule and does not affect any computed metric. All rows report `accepted=yes`, identical `model_used` (`claude-haiku-4-5-20251001+claude-sonnet-5`), and `tree_digest_ok=yes`.

## (b) Per-condition summary (accepted runs; n = 5 per condition, all accepted)

| Metric | Condition X | Condition Y |
|---|---|---|
| n (runs) | 5 | 5 |
| Accepted (rate) | 5 (100.0%) | 5 (100.0%) |
| total_tokens — median (range) | **312444** (311164 – 357979) | **153611** (153056 – 227089) |
| tokens_uncached — median (range) | **19753** (19195 – 20347) | **11802** (11031 – 39090) |
| total_cost_usd — median (range) | 0.2305 (0.2177 – 0.2445) | 0.1252 (0.1246 – 0.2863) |
| wall_clock_s — median (range) | 35.17 (32.52 – 42.02) | 24.25 (20.82 – 29.21) |
| model_calls — median (range) | 10 (10 – 12) | 7 (5 – 7) |
| Aggregate efficiency (Σ total_tokens over all runs ÷ accepted runs) | 1650643 ÷ 5 = **330129** tokens/accepted run | 875143 ÷ 5 = **175029** tokens/accepted run |

Ancillary observation (not part of the decision rule): condition X recorded tool_failures in every run (2–4 per run, 16 total); condition Y recorded zero.

## (c) cache_read_tokens by sequence order

- **Condition X** (seq 2, 3, 6, 7, 10): 291954 → 291881 → 337635 → 337002 → 293249. Non-monotonic: two runs near ~292k, a plateau near ~337k at sequences 6–7, then a return to ~293k at sequence 10. No steady drift across the session; values cluster in two bands.
- **Condition Y** (seq 1, 4, 5, 8, 9): 148887 → 216058 → 141670 → 141254 → 141700. The first run of the entire experiment (seq 1) also carries the dataset's largest cache_creation (38360) and the Y-arm's outlier tokens_uncached (39090), consistent with a cold cache at session start; seq 4 spikes to ~216k; the final three runs are tightly stable at ~141.3k–141.7k.
- In both arms, cache_read is roughly an order of magnitude larger than uncached tokens, and neither arm shows monotonic cache growth with sequence; interleaving of X and Y across the sequence did not produce a visible one-directional cache trend.

## (d) T2–T4 refusal statement

Tasks T2, T3, and T4 each produced an identical deterministic REFUSAL record in BOTH conditions: an environmental precondition (the agent under test cannot execute the project's test suite) makes those tasks impossible in both conditions equally, and no numbers were produced. Those six refusal records remain in the dataset. **T1 is therefore the only task contributing numeric rows**, and every numeric claim below is scoped to T1.

## (e) Preregistered rule, walked in order

**Step 1 — RESULT CONFOUNDED?**

- `model_used` differs across any rows? No — all 10 rows report `claude-haiku-4-5-20251001+claude-sonnet-5`. Not triggered.
- Fewer than 3 accepted runs in either condition? No — X: 5 accepted, Y: 5 accepted. Not triggered.
- total_tokens and tokens_uncached comparisons point in opposite directions? No — Y has the lower total median (153611 < 312444) AND the lower uncached median (11802 < 19753). Same direction. Not triggered.
- Any `tree_digest_ok=no`? No — all 10 rows are `yes`. Not triggered.

Step 1 does not fire. Proceed.

**Step 2 — CAUSAL EFFECT SUPPORTED?**

- Ranges do not overlap? X accepted-run total_tokens range: [311164, 357979]. Y range: [153056, 227089]. Y's maximum (227089) < X's minimum (311164). **No overlap — satisfied.**
- Median difference ≥ 25%? |medX − medY| ÷ max(medX, medY) = |312444 − 153611| ÷ 312444 = 158833 ÷ 312444 = 0.5084 = **50.8% ≥ 25% — satisfied.**
- Uncached comparison agrees in direction? Y uncached median 11802 < X uncached median 19753 (a 40.3% relative difference, same direction as total). **Satisfied.**

All three conditions of Step 2 hold. Steps 3 and 4 are not reached.

## (f) Conclusion

**Label: causal effect supported.** Direction: **condition Y lower** — condition Y's accepted runs consumed fewer total tokens (median 153611 vs 312444, a 50.8% relative reduction), with the uncached-token comparison agreeing in direction (median 11802 vs 19753).

Caveat on scope: this claim rests on N=5 paired runs of a single task class (T1) — T2–T4 contributed no numeric data in either arm — so the supported effect is bounded to task T1 and this task class; it does not license generalization to other task types, workloads, or environments without further runs.

## (g) Blinding affirmation

This analysis was performed blind: the evaluator saw the arms only as labels X and Y, does not know the mapping of those labels to real conditions, made no attempt to infer it, and accessed no repository files, commands, or context beyond the dataset and rule supplied above.
