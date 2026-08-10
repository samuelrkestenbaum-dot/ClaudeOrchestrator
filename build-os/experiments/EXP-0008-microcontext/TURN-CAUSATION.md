# Step 1 — what the extra Gravito turns are actually doing

**Frozen before any lean design is drawn. Stored EXP-0006/0007 streams only; no
new compute.**

Classified by **structure** — tool name, requested path, result error flag —
never by result content. Every content-matching classifier in this work
eventually matched the thing it was describing: the gate's own comments, the
process guard, the pgrep pattern, the no-pointer check. 13 assertions prove the
classifier, including one that a result *mentioning* `routing-gate.sh` is still
classified by its path, not its prose.

## Tool calls per arm, by cause

| cause | native | baseline | B (context removed) | C (narration removed) | A (receipt pre-issued) |
|---|---|---|---|---|---|
| gravito_implementation_read | 0.0 | 6.7 | **10.8** | 4.3 | 6.5 |
| authority_gate_roundtrip | 0.0 | 2.8 | 4.3 | 3.2 | 3.3 |
| gravito_search | 0.3 | **0.1** | **11.3** | 1.8 | 3.3 |
| routing_bookkeeping | 0.0 | 2.8 | **9.0** | 1.3 | 1.0 |
| subagent_dispatch | 0.0 | 0.3 | 0.0 | 0.3 | 0.0 |
| verification | 6.8 | 2.8 | 4.5 | 3.2 | 3.5 |
| tool_retry | 2.8 | 2.5 | 3.5 | 2.6 | 2.5 |
| product_work | 18.8 | 15.7 | 19.3 | 16.0 | 25.8 |
| unclassified | 1.0 | 1.9 | 2.0 | 1.9 | 2.0 |
| **total tool calls** | 29.5 | 35.6 | **64.5** | 34.5 | 47.8 |
| **turns** | 30.5 | 47.1 | 49.3 | 46.8 | 60.0 |

## Finding 1 — the substrate's own overhead is 12.3 calls/arm, partly masked

Baseline minus native:

```
+6.7  gravito_implementation_read
+2.8  authority_gate_roundtrip
+2.8  routing_bookkeeping
-3.1  product_work
-3.9  verification
─────
+6.1  net
```

The substrate adds **12.3 calls of pure overhead** and simultaneously *suppresses*
7 calls of real work — baseline runs **less than half** native's verification
(2.8 vs 6.8), because Bash is gated. The net figure of +6.1 understates the
overhead by hiding it behind work the substrate prevented.

## Finding 2 — removing context multiplies search 113×

`gravito_search` goes from **0.1 → 11.3 calls/arm** under variant B, with
implementation reads also rising (6.7 → 10.8) and routing bookkeeping tripling
(2.8 → 9.0). Total tool calls 35.6 → 64.5.

**Subtraction alone is refuted, with a number.** The worker does not proceed
without the information; it goes looking, and looking costs more than carrying.

## Finding 3 — the largest turn tax carries no tool call at all

Baseline runs **+16.6 turns/arm** over native, but only **+6.1 excess tool
calls**. Roughly **10.5 excess turns per arm are pure model output** — reasoning
and protocol narration with no action attached.

That is the single biggest component of the turn tax, and **no variant tried
moved it**. C targeted narration specifically and came closest to baseline
overall, but its turn count barely differs (46.8 vs 47.1).

**Stated limitation:** this figure is obtained by *subtraction*, not by
classification. The classifier sees tool calls; text-only turns are counted but
their composition is unproven. That those turns exist and carry no tool call is
measured. What is in them is not.

## What this constrains about any lean design

| group | calls/arm | implication |
|---|---|---|
| **collapsible mechanically** | 5.6 (gate round-trips + routing bookkeeping) | deterministic; needs no model in the loop |
| **not collapsible by subtraction** | 6.7 (implementation reads) | removing context made it WORSE (10.8) — the worker reads to understand, not to act |
| **untouched by every variant tried** | ~10.5 text-only turns | the largest share, and unaddressed |

A lean build that only removes things attacks the 5.6, worsens the 6.7, and
leaves the 10.5 alone. **The design must give the worker enough certainty that it
does not search** — which is the opposite instinct from "less prompt".
