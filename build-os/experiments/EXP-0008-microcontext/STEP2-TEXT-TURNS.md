# Step 2 — what the excess text-only turns actually are

**Stored streams only; no new arms.** 214 text-only turns classified (native 18
across 4 arms, corrected 196 across 12), plus a generality check over all 24
EXP-0006 arms. Frozen output: `text-turn-classes.txt`.

## The headline

**The excess is not narration. It is a stop-refusal loop.**

Native writes **one** final report per arm. Corrected Gravito writes **2.58**,
and 11 of 12 arms write more than one. Each repeat costs a 2,500–4,000 character
report plus the search round that precedes it.

| class | native /arm | corrected /arm | EXCESS | share |
|---|---|---|---|---|
| capability_search | 0.00 | 2.33 | **+2.33** | 20% |
| gate_mechanism_diagnosis | 0.00 | 2.17 | **+2.17** | 18% |
| routing_bookkeeping | 0.00 | 2.00 | **+2.00** | 17% |
| final_report | 1.00 | 2.58 | **+1.58** | 13% |
| authority_blocked | 1.00 | 2.08 | +1.08 | 9% |
| gate_challenge_response | 0.00 | 1.08 | +1.08 | 9% |
| verification_planning | 0.25 | 0.83 | +0.58 | 5% |
| product_reasoning | 1.25 | 1.75 | +0.50 | 4% |
| unclassified | 0.00 | 0.42 | +0.42 | 4% |
| **protocol_narration** | 0.00 | **0.08** | **+0.08** | **1%** |
| opening_plan | 1.00 | 1.00 | 0.00 | — |
| **TOTAL** | **4.50** | **16.33** | **+11.83** | |

**77% of the excess (9.16 turns/arm) is one mechanism**: the concession gate
refuses the worker's stop, the worker searches for a capability it does not have,
reads Gravito's own gate source to find out why it is still blocked, files
bookkeeping, and re-reports.

By output volume the concentration is starker: **+7,976 chars/arm, of which
final_report is +5,976 (75%)**. That is the output/turn figure — 622 vs native's
334 — and it is re-summarisation, not verbosity.

## The finding that contradicts the proposed manifest

**`protocol_narration` is 1% of the excess.** Lane/Tools/doctrine declarations —
the thing variant C was built to remove and the thing a "suppress lane/status
narration" row would attack — are **0.08 turns/arm**. They are already almost
free.

This is consistent with EXP-0007, where C (narration removed) came closest to
baseline overall and moved turns by 0.3 (47.1 → 46.8). C did not fail because it
was badly built. It failed because **it attacked 1% of the problem.**

## The mechanism, and the fact that it SUBSTITUTED rather than disappeared

Both contaminated and uncontaminated arms re-report 2–3× where native reports
once. They do it for **different reasons**, and that is why fixing the
contamination did not move the economics.

| group | arms | queue refs/arm | exhaustion refs/arm | dominant driver |
|---|---|---|---|---|
| EXP-0006 native (no substrate) | 12 | 0.08 | 0.00 | neither, 11/12 |
| EXP-0006 gravito (contaminated) | 12 | 7.92 | 2.42 | **queue, 12/12** |
| EXP-0007 baseline (contaminated) | 12 | 8.83 | 2.50 | **queue, 11/12** |
| EXP-0007 corrected (uncontaminated) | 12 | 0.42 | 4.50 | **exhaustion, 11/12** |

Contaminated, the loop was driven by the continuation hook demanding the worker
take up someone else's queue item:

> "The hook wants me to jump to an unrelated queue item. I'm not going to do
> that." … "The hook has now fired four times with an identical message, which
> tells me it isn't evaluating state — it's a loop." … "Unchanged. Waiting on you."

Uncontaminated, the identical loop is driven by the concession gate demanding
documented capability exhaustion:

> "The gate is right that I stopped without searching every surface." … "The
> gate's mechanics are now clear: it needs `for_conclusion`, `verdict`, and a
> `capability` key."

**Removing the foreign queue removed a driver, not the loop.** This is the same
compensatory substitution variant B demonstrated when context was subtracted and
search rose 113×. It is now demonstrated for the contamination fix itself.

## The one arm that escaped, and what it cost

`T03.corrected` is the only arm of twelve where the gate did not refuse the stop.
It wrote one report, like native.

| | turns | tools | text-only | cost |
|---|---|---|---|---|
| T03 native | 25 | 24 | 5 | $0.86 |
| **T03.corrected — no refusal** | **23** | **22** | **7** | **$1.10** |
| T03.corrected.r2 — 3 reports | 32 | 29 | 14 | $1.99 |
| T03.corrected.r3 — 3 reports | 43 | 43 | 19 | $3.54 |

**Gravito without the stop-refusal loop cost 1.28× native. With it, 2.3–4.1×.**

n=1, and it is a single task. It is not a result. It is the only direct
observation of the substrate running without the mechanism that dominates the
tax, and it points the same way as everything else here.

## A threat to external validity that must be stated

**`tsc` cannot execute on the arm host.** Every arm — native included — hits a
permission layer that refuses the verification command (`authority_blocked` is
1.00/arm even in native).

Native's response is to say so and stop. Gravito's concession gate refuses that
stop and demands documented exhaustion — which, because the capability is
genuinely absent, can only be satisfied after several rounds of searching and
reading the gate's own source.

So the measured 2.4× gap is substantially **the cost of the capability-exhaustion
gate firing in a host where the capability is genuinely unavailable.** In a host
where the verification command runs, the first report would satisfy the gate and
this loop would likely not fire at all.

This does not make the gap fake — the gate is real, it is load-bearing, and it
behaved as designed. But it does mean **the 2.4× is not a general estimate of
Gravito's cost; it is Gravito's cost under capability starvation**, and any lean
build measured only here will be optimising against an environment-amplified
target. A host where `tsc` runs should be added before the lean treatment is
judged.

## Method, and its limits

- **Two of ten buckets need no content matching at all**: `opening_plan` is the
  arm's first text turn whatever it says, and `final_report` is any turn ≥1500
  chars. Those two carry the headline and cannot be argued with.
- The other eight **do** match content — the failure mode that has bitten this
  work five times. Two things bound the risk: the corpus is the worker's own
  output rather than a file describing the pattern (and workers cannot read
  `build-os/experiments`, which administration withholds), and the **same
  classifier runs over both arms**, so a consistently-wrong rule still yields a
  valid differential.
- **Audited by reading all 130 non-structural corrected labels.** ~5 are wrong
  (~4%): one gate turn landed in `product_reasoning` on the word "schema", one
  product turn landed in `routing_bookkeeping`. All but one stay inside the
  Gravito-caused aggregate, so the `capability_search` / `gate_mechanism_diagnosis`
  split is softer than the Gravito-vs-product boundary.
- **Ambiguity preserved**: no rule matching gives `unclassified` (0.42/arm, 4%),
  never nearest-fit.
- The classifier was revised **once** after that audit — `authority_blocked` was
  missing "The Bash *tool* is gated", gate-source reading deserved its own bucket,
  and short product navigation matched nothing. Both versions and the reason are
  in `text-turn-classes.mjs`.

## What this constrains about LEAN_MANIFEST

Mapping the proposed changes onto measured classes:

| proposed change | measured tax attacked | size | verdict |
|---|---|---|---|
| Accept a first well-evidenced stop | gate_challenge + repeat final_report | **+2.66/arm, 22%** and 75% of excess output | **the largest single lever** |
| Compact derived authority state | gate_mechanism_diagnosis | +2.17/arm, 18% | real — worker reads the gate to learn why it blocks |
| Auto-redeem deterministic routing state | routing_bookkeeping | +2.00/arm, 17% | real, and mechanically collapsible |
| Preserve relevant operational context | capability_search | +2.33/arm, 20% | real — and B proved subtraction makes it worse |
| **Suppress lane/status narration** | **protocol_narration** | **+0.08/arm, 1%** | **drop it — it is already free** |

The first row is not in the proposed table and is the biggest item in the data.
The last row is in the proposed table and is measurably not worth building.
