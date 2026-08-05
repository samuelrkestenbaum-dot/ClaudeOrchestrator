# EXP-0002 — Blinded analysis (conditions X and Y; mapping unknown to the evaluator)

Prepared by an independent, blinded evaluator working solely from the supplied TSV and the preregistered mechanical rule. No repository files were read and no commands were run.

---

## (a) Data-integrity checks

**Row identity checks.** For every row, `input + output + cache_creation + cache_read = total_tokens` and `total_tokens − cache_read = tokens_uncached` were verified by hand:

| Row | input+output+cc+cr | total_tokens | Match | total − cache_read | tokens_uncached | Match |
|---|---|---|---|---|---|---|
| T1_X | 591+2,926+18,003+229,955 = 251,475 | 251,475 | ✓ | 21,520 | 21,520 | ✓ |
| T2_X | 578+1,643+16,484+313,122 = 331,827 | 331,827 | ✓ | 18,705 | 18,705 | ✓ |
| T3_X | 582+19,001+43,663+1,197,468 = 1,260,714 | 1,260,714 | ✓ | 63,246 | 63,246 | ✓ |
| T4_X | 572+2,865+25,897+497,127 = 526,461 | 526,461 | ✓ | 29,334 | 29,334 | ✓ |
| T5_X | 576+7,809+27,136+913,622 = 949,143 | 949,143 | ✓ | 35,521 | 35,521 | ✓ |
| T1_Y | 587+2,008+15,571+154,095 = 172,261 | 172,261 | ✓ | 18,166 | 18,166 | ✓ |
| T2_Y | 578+2,274+31,504+334,475 = 368,831 | 368,831 | ✓ | 34,356 | 34,356 | ✓ |
| T3_Y | 790+83,871+239,099+4,620,309 = 4,944,069 | 4,944,069 | ✓ | 323,760 | 323,760 | ✓ |
| T4_Y | 558+1,627+18,708+208,297 = 229,190 | 229,190 | ✓ | 20,893 | 20,893 | ✓ |
| T5_Y | 846+95,877+300,357+7,044,339 = 7,441,419 | 7,441,419 | ✓ | 397,080 | 397,080 | ✓ |

**All 10 rows pass both identities. No failures to flag.**

**usage_block_disagrees rows.** Two rows are flagged: **T3_Y** (parent-loop-only usage_block_total = 68,812 vs complete total 4,944,069) and **T5_Y** (86,642 vs 7,441,419). Per the design facts, the complete session-level totals — which reconcile exactly with provider-reported cost — are authoritative and are used **uniformly for every row** in this analysis; the parent-loop-only figures are noted for transparency only. All other rows' usage_block_total values differ from the complete totals only by small deltas and are marked `no`.

Other integrity notes: `model_used` is identical (`claude-haiku-4-5-20251001+claude-sonnet-5`) on all 10 rows; both T1 rows have `seed_verified=yes`; all 10 rows have `accepted=yes` (5 per condition).

---

## (b) Per-condition summary

### Sequence totals (5 accepted runs each)

| Metric | Condition X | Condition Y | Y ÷ X |
|---|---|---|---|
| Σ total_tokens | 3,319,620 | 13,155,770 | 3.963 |
| Σ tokens_uncached | 168,326 | 794,255 | 4.719 |
| Σ cost (USD) | $2.2485 | $9.1242 | 4.058 |
| Σ wall clock (s) | 451.20 | 1,976.62 | 4.381 |
| Accepted outcomes | 5 | 5 | — |

### Per-accepted-outcome aggregates (primary)

- **X:** 3,319,620 ÷ 5 = **663,924** total tokens per accepted outcome; 168,326 ÷ 5 = **33,665.2** uncached.
- **Y:** 13,155,770 ÷ 5 = **2,631,154** total tokens per accepted outcome; 794,255 ÷ 5 = **158,851.0** uncached.

### Per-task paired table (total_tokens)

| Task | X total | Y total | Fewer tokens | Ratio (more ÷ fewer) |
|---|---|---|---|---|
| T1 | 251,475 | 172,261 | **Y** | 1.460 |
| T2 | 331,827 | 368,831 | **X** | 1.112 |
| T3 | 1,260,714 | 4,944,069 | **X** | 3.922 |
| T4 | 526,461 | 229,190 | **Y** | 2.297 |
| T5 | 949,143 | 7,441,419 | **X** | 7.840 |

X uses fewer total tokens on **3 of 5** tasks (T2, T3, T5); Y uses fewer on **2 of 5** (T1, T4).

---

## (c) Cumulative curves and crossover

Cumulative sums after each task (full curve, as required):

| After | X cum total | Y cum total | X cum uncached | Y cum uncached | X cum cost | Y cum cost |
|---|---|---|---|---|---|---|
| T1 | 251,475 | **172,261** | 21,520 | **18,166** | $0.2214 | **$0.1702** |
| T2 | 583,302 | **541,092** | **40,225** | 52,522 | **$0.4393** | $0.4941 |
| T3 | **1,844,016** | 5,485,161 | **103,471** | 376,282 | **$1.3460** | $4.1205 |
| T4 | **2,370,477** | 5,714,351 | **132,805** | 397,175 | **$1.6940** | $4.3201 |
| T5 | **3,319,620** | 13,155,770 | **168,326** | 794,255 | **$2.2485** | $9.1242 |

(Bold = cumulatively cheaper condition at that point.)

**Crossover statement.** On the primary metric (cumulative total_tokens), Y is cumulatively cheaper after T1 and T2; the cumulatively-cheaper condition **changes at T3** — the first and only crossover — and X remains cumulatively cheaper through T5. On the uncached and cost curves the crossover occurs earlier, **at T2**, and X likewise remains cheaper through T5. State at T5: X is cumulatively cheaper on all three measures.

---

## (d) The preregistered rule, step by step

**Step 1 — Confound check.**
- `model_used` identical across all 10 rows → no confound.
- T1_X and T1_Y both `seed_verified=yes` → no confound.
- Accepted counts 5 vs 5, difference 0 (< 2) → no confound.
- Direction agreement: total-token comparison favors X (3,319,620 < 13,155,770); uncached comparison also favors X (168,326 < 794,255) → same direction, no confound.
- **RESULT CONFOUNDED does not apply.**

**Step 2 — Sustained-workload savings test.**
- Sequence-level total tokens per accepted outcome: X = 663,924; Y = 2,631,154. Difference = 2,631,154 − 663,924 = 1,967,230; as a fraction of the higher condition: 1,967,230 ÷ 2,631,154 = **74.8%**. This is ≥ 25% → threshold condition met, direction X.
- Uncached agreement: (794,255 − 168,326) ÷ 794,255 = 625,929 ÷ 794,255 = **78.8%** in the same direction (X lower) → uncached comparison agrees.
- Per-task agreement: tasks favoring X = T2, T3, T5 = **3 of 5**. Requirement is ≥ 4 of 5. **3/5 < 4/5 → this condition FAILS.**
- **SUSTAINED-WORKLOAD SAVINGS SUPPORTED does not apply.**

**Step 3 — <25% test.** The sequence-level difference is 74.8%, which is not < 25%. **NO SUSTAINED-WORKLOAD SAVINGS DETECTED does not apply.**

**Step 4 — ≥25% but per-task agreement < 4/5.** Difference is 74.8% (≥ 25%), agreement is 3/5 (< 4). **This step applies.**

---

## (e) Decision

**Label: PROMISING BUT UNDERPOWERED** — direction **X** (condition X used 74.8% fewer total tokens per accepted outcome than condition Y, with the uncached comparison agreeing at 78.8%, but only 3 of 5 per-task paired differences favored X, below the preregistered 4-of-5 agreement bar).

**Caveat (required):** N = one sequence per condition (5 paired task points) on a single synthetic repository. This sample cannot distinguish a systematic condition effect from task-level or run-level variance, and the aggregate difference is dominated by two tasks (T3, T5).

---

## (f) Notable secondary observations (neutral)

- **Wall clock:** X totaled 451.20 s vs Y's 1,976.62 s (ratio 4.381). Y's T3 (849.03 s) and T5 (1,012.98 s) alone account for 1,862.01 s, 94.2% of Y's total.
- **Cost:** X $2.2485 vs Y $9.1242 (ratio 4.058). Cost tracks the token pattern closely, as expected given cost reconciles with the usage aggregates.
- **Tool failures:** X recorded 10 failures across the sequence (0, 0, 2, 3, 5 for T1–T5); Y recorded 47 (0, 0, 24, 0, 23). Y's failures are concentrated in T3 and T5, the same two tasks driving its token and wall-clock totals.
- **Per-task heterogeneity — plainly stated:** the tasks do not all favor the same condition. Y was cheaper on T1 (172,261 vs 251,475; ratio 1.460) and T4 (229,190 vs 526,461; ratio 2.297). X was cheaper on T2 (1.112×), T3 (3.922×), and T5 (7.840×). Y's advantage appears on the two tasks it completed fastest (32.11 s, 42.07 s), while its two long tasks show token ratios of roughly 4× and 8× against it.
- **Activity profile:** on Y's T3 and T5, `model_calls_parent` = 1 while tool events number 111 and 104, and these are the two rows where the parent-loop-only usage block (68,812; 86,642) diverges sharply from the complete session totals (4,944,069; 7,441,419) — consistent with substantial activity occurring outside the parent loop on those rows. X's rows show parent model calls (8–33) approximately tracking tool events (7–32). This is a structural difference in how the sessions executed; no interpretation of its cause is offered here.
- **ttfcc:** values are 10 s-resolution upper bounds; T2_Y is a censored bound (≤ 40.43 s). Both conditions share an identical T4 bound (10.33 s). No condition-level ttfcc claim is warranted at this resolution.

---

## (g) Blinding affirmation

I performed this analysis blind. I do not know what conditions X and Y are, I made no attempt to discover, infer, or guess their identities or mapping, and I read no files and ran no commands beyond processing the TSV provided in the task. All arithmetic above derives solely from that table, and the decision label was assigned strictly by the preregistered mechanical rule, applied symmetrically to X and Y.
