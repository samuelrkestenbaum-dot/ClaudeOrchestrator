# EXP-0003 — Blinded analysis (conditions P, Q, R; mapping unknown to the evaluator)

Evaluator status: blinded. Analysis performed solely from the nine-row TSV supplied in the prompt, under the preregistered neutral rule, exactly as written. No files read, no commands run, no attempt made to identify the conditions.

---

## (a) Per-row integrity

Check 1: `mu_input + mu_output + mu_cache_creation + mu_cache_read = total_tokens`.
Check 2: `total_tokens − mu_cache_read = tokens_uncached`.

| blind_run_id | input+output+cache_creation+cache_read | reported total | Check 1 | total − cache_read | reported uncached | Check 2 |
|---|---|---|---|---|---|---|
| T3_Q | 602+19448+76403+1629405 = 1,725,858 | 1,725,858 | pass | 1,725,858 − 1,629,405 = 96,453 | 96,453 | pass |
| T4_Q | 578+3831+27477+696726 = 728,612 | 728,612 | pass | 728,612 − 696,726 = 31,886 | 31,886 | pass |
| T5_Q | 556+9855+29486+459990 = 499,887 | 499,887 | pass | 499,887 − 459,990 = 39,897 | 39,897 | pass |
| T3_R | 596+21006+64060+1973755 = 2,059,417 | 2,059,417 | pass | 2,059,417 − 1,973,755 = 85,662 | 85,662 | pass |
| T4_R | 582+3190+22722+804910 = 831,404 | 831,404 | pass | 831,404 − 804,910 = 26,494 | 26,494 | pass |
| T5_R | 582+13717+45268+1342785 = 1,402,352 | 1,402,352 | pass | 1,402,352 − 1,342,785 = 59,567 | 59,567 | pass |
| T3_P | 698+61291+206823+2846536 = 3,115,348 | 3,115,348 | pass | 3,115,348 − 2,846,536 = 268,812 | 268,812 | pass |
| T4_P | 560+2893+23711+261204 = 288,368 | 288,368 | pass | 288,368 − 261,204 = 27,164 | 27,164 | pass |
| T5_P | 714+65622+195928+3834226 = 4,096,490 | 4,096,490 | pass | 4,096,490 − 3,834,226 = 262,264 | 262,264 | pass |

All nine rows pass both integrity checks. No failures to flag.

---

## (b) Frontier table

All nine runs are `accepted: yes`, so all three conditions are rankable in every shape (n=1 per cell). Adjacent-rank ratios are (higher rank value) ÷ (lower rank value), to two decimals.

### T3

| Rank | By total_tokens | Value | Ratio vs prev | By tokens_uncached | Value | Ratio vs prev |
|---|---|---|---|---|---|---|
| 1 (winner) | **Q** | 1,725,858 | — | **R** | 85,662 | — |
| 2 | R | 2,059,417 | 1.19 | Q | 96,453 | 1.13 |
| 3 | P | 3,115,348 | 1.51 | P | 268,812 | 2.79 |

Totals winner: **Q**. Uncached winner: **R**. **Winners disagree.**

### T4

| Rank | By total_tokens | Value | Ratio vs prev | By tokens_uncached | Value | Ratio vs prev |
|---|---|---|---|---|---|---|
| 1 (winner) | **P** | 288,368 | — | **R** | 26,494 | — |
| 2 | Q | 728,612 | 2.53 | P | 27,164 | 1.03 |
| 3 | R | 831,404 | 1.14 | Q | 31,886 | 1.17 |

Totals winner: **P**. Uncached winner: **R**. **Winners disagree.**

### T5

| Rank | By total_tokens | Value | Ratio vs prev | By tokens_uncached | Value | Ratio vs prev |
|---|---|---|---|---|---|---|
| 1 (winner) | **Q** | 499,887 | — | **Q** | 39,897 | — |
| 2 | R | 1,402,352 | 2.81 | R | 59,567 | 1.49 |
| 3 | P | 4,096,490 | 2.92 | P | 262,264 | 4.40 |

Totals winner: **Q**. Uncached winner: **Q**. **Winners agree.**

Secondaries per shape (cost_usd / wall_clock_s), ranked low→high:

- **T3** — cost: Q 1.2394855, R 1.2920745, P 2.6657170; wall clock: Q 223.47, R 227.44, P 576.18
- **T4** — cost: P 0.2644662, R 0.4261550, Q 0.4318328; wall clock: P 47.01, R 69.45, Q 70.87
- **T5** — cost: Q 0.4631240, R 0.8806625, P 3.0003593; wall clock: Q 102.07, R 183.34, P 618.64

---

## (c) The rule, walked in order

**Durable accepted outcome.** All nine rows report `accepted: yes`. Every condition is rankable in every shape; no condition is unranked anywhere; every shape has three (≥2) accepted conditions, so all three shapes yield comparisons.

**Step 1 — RESULT CONFOUNDED?**
- `model_used`: all nine rows read `claude-haiku-4-5-20251001+claude-sonnet-5` — identical. Not triggered.
- `post_setup_digest_ok`: 9 of 9 are "yes". Not triggered.
- `cost_reconciliation_agrees`: 9 of 9 are "yes". Not triggered.
- Acceptance failures: zero; no shape has fewer than two rankable conditions. Not triggered.

Not confounded.

**Step 2 — FRONTIER UNSTABLE?** Every shape is rankable and unconfounded. Compare winners:
- T3: totals winner Q (1,725,858 < 2,059,417 < 3,115,348) vs uncached winner R (85,662 < 96,453 < 268,812) — **flip**.
- T4: totals winner P (288,368 < 728,612 < 831,404) vs uncached winner R (26,494 < 27,164 < 31,886) — **flip**.
- T5: totals winner Q (499,887 < 1,402,352 < 4,096,490) vs uncached winner Q (39,897 < 59,567 < 262,264) — agree.

At least one shape (in fact two: T3 and T4) has an uncached winner differing from the totals winner. Step 2 fires; step 3 is not reached.

---

## (d) Label

**frontier unstable — winners flip on uncached**

---

## (e) Neutral secondary observations

Stated plainly, without interpreting causes; n=1 per cell throughout.

- **Cost.** Cost ordering matches the total_tokens ordering in every shape (T3: Q < R < P; T4: P < Q < R; T5: Q < R < P). P is the most expensive condition in T3 (2.67 USD) and T5 (3.00 USD) and the cheapest in T4 (0.26 USD). Cost spread within a shape reaches 6.48× in T5 (P/Q = 3.0003593/0.4631240).
- **Wall clock.** Wall-clock ordering also matches the totals ordering in every shape. P has both the longest runs observed (T3: 576.18 s; T5: 618.64 s) and the shortest (T4: 47.01 s). Q and R are within about 4 s of each other on T3 (223.47 vs 227.44) and about 1.4 s on T4 (70.87 vs 69.45), but differ by 81.27 s on T5 (102.07 vs 183.34).
- **Tool failures.** Q: 0, 5, 0 (T3, T4, T5). R: 2, 5, 5. P: 11, 0, 20. The two highest failure counts in the dataset are both P rows (T3_P: 11; T5_P: 20); P's only zero-failure row is T4_P, which is also its lowest-token row.
- **Parent-call vs tool-event structure.** In all six Q and R rows, and in T4_P, `model_calls_parent = tool_use_events + 1` (e.g. 31/30, 22/21, 16/15, 41/40, 17/16, 23/22, 12/11). In T3_P and T5_P the relationship inverts sharply: 7 parent calls against 114 tool events, and 5 parent calls against 118 tool events. Those same two rows are the two largest rows in the dataset by every volume measure (total tokens, uncached tokens, cost, wall clock, output tokens, cache creation).
- **Cache composition.** cache_read dominates total_tokens in every row (from 90.6% in T4_P to 94.4% in T3_Q/T3_P-range values); the totals-vs-uncached winner flips in T3 and T4 arise because the rankings of cache_read do not track the rankings of the non-cache-read remainder.

---

## (f) Blinding affirmation

I performed this analysis blinded. I do not know, and did not attempt to discover, which experimental conditions the labels P, Q, and R correspond to. I read no files, ran no repository or system commands, and used no context beyond the TSV data and the preregistered rule supplied in the tasking message. The label in (d) was produced mechanically by walking the rule's decision steps in their stated order, and no condition was favored or assigned an expected direction at any point.
