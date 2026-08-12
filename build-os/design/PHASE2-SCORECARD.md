# Phase 2 target and scorecard (operator-dictated during EXP-0011, pre-data)

**Gravito should make work cheaper, faster, and more repeatable as experience
accumulates.** Compactness (proven at proof 1) is one leg; speed and
consistency are the next two proof dimensions.

## Speed — not raw wall-clock

Measured from stored artifacts, per arm: active worker time (`elapsed_s`,
captured at session exit BEFORE harness verification — tsc noise excluded by
construction); turns to solution; tool calls to solution; rediscovery reads;
verification cycles (in-session tsc invocations); accepted-only latency; and
the early-vs-late position split. Signature: **native roughly flat; Gravito
faster with position.**

## Consistency — collapse the variance, especially the bad tail

Per config, whole-run and early(P1–P2)-vs-experienced(P4–P5): acceptance
rate; retries/timeouts (preserved attempt dirs + terminal reasons); variance
(CV) of cost and turns; tail latency (P90 as an order statistic — n=20 per
config, so P95 is the max and is reported as the max, not dressed as a
percentile); unnecessary reads; tool-path variance (distinct compressed
tool sequences and mode share — do repeated situations converge on the same
proven path?); new-error rate (acceptance condition-2 events). Signature:
**Gravito's distribution gets tighter, and the ugly tail (the 4×-cost,
wrong-turn session) disappears.**

## The scorecard (emitted by each study's reader)

| Dimension | Native | Gravito early | Gravito experienced |
|---|---|---|---|
| Cost | baseline | ≈ baseline | ↓ |
| Time to accepted result | baseline | ≈ baseline | ↓ |
| Turns | baseline | ≈ baseline | ↓ |
| Tail latency (P90/max) | high | lower | much lower |
| Variance (CV) | high | lower | lower |
| Retry/failure rate | baseline | ≤ baseline | ↓ |
| Rediscovery | repeated | reduced | minimal |

"Early" = positions 1–2; "experienced" = positions 4–5. Rules are expected to
buy compactness and some speed; SKILLS are where speed + consistency should
show, because a skill encodes how to execute, not only what to know.

The commercial statement being tested: not "13% fewer tokens" but "by the
fifth analogous task, Gravito is cheaper, faster, takes the same proven path,
and almost never produces the tail outcomes native still produces."
