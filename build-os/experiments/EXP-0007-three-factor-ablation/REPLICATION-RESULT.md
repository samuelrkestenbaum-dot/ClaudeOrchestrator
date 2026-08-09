# EXP-0007 replication — C does not reliably win

**24 measurements: 4 tasks × 2 configurations × 3 reps. All admissible. Acceptance 12/12 and 12/12.**

One question was asked: *is C actually better than baseline, or was the
screening edge variance?* The answer is variance.

## Paired result

| C ÷ baseline (mean of 3 reps) | turns | uncached | cost |
|---|---|---|---|
| T01 | 0.94× | 1.11× | 0.98× |
| T02 | 1.02× | 0.96× | 1.01× |
| T03 | 1.02× | 1.15× | 1.14× |
| T04 | 0.99× | 0.84× | 0.74× |
| **mean** | **0.99×** | **1.02×** | **0.97×** |
| **tasks favouring C** | **2/4** | **2/4** | **2/4** |

Two of four on every metric is a coin flip.

## The noise floor, measured rather than assumed

Coefficient of variation on uncached tokens, within a single cell — same
configuration, same task, same seed, same ceiling:

| cell | n | CV | range |
|---|---|---|---|
| T01/baseline | 3 | 29% | 70,638 – 139,581 |
| T01/C | 3 | 27% | 76,975 – 150,767 |
| T02/baseline | 3 | 24% | 59,589 – 104,515 |
| T02/C | 3 | 29% | 55,589 – 106,469 |
| T03/baseline | 3 | 23% | 53,154 – 93,688 |
| T03/C | 3 | 31% | 59,168 – 120,423 |
| T04/baseline | 3 | 39% | 96,526 – 212,955 |
| T04/C | 3 | 6% | 104,592 – 120,347 |

**Seven of eight cells sit between 23% and 39%.** With n=3 the standard error of
a cell mean is roughly 16%, so the observed 1–3% differences are about 0.2 SE.
They are not small effects; they are no effect.

## What this retires

The screening reported C at **34% cheaper, UIC 12.82 vs 9.14**, the only
configuration dominating baseline on all three factors. That number came from
**one arm per cell against a ~28% CV**. It could not have shown anything else,
and it did not survive contact with two more reps.

This is the concrete cost of single-arm screening, and it is worth stating
plainly rather than filing away: five configurations were ranked, a Pareto
winner was named, and a mechanism was puzzled over — all on measurements whose
spread was larger than every difference between them.

## Verdict, against the criterion fixed BEFORE the data

The criterion was: same direction on ≥3 of 4 tasks, and mean delta larger than
the within-cell spread. **C fails both halves.**

`C_DOES_NOT_RELIABLY_WIN` → per the operator's decision tree, the A/B/C family
is **exhausted and closed**. No further tweaking of prompt removal.

## What survived from the whole ablation

Only one durable finding, and it came from the screening's largest effect rather
than its smallest:

**B is refuted, and the mechanism is understood.** Pointer-based retrieval —
telling the worker where the doctrine lives instead of carrying it — produced
the worst UIC of any configuration, one 1200s timeout on a task native solved in
122s, and a worker that read 47KB of gate source to reconstruct what it should
be doing. Removing context does not remove the need for it; it converts cheap
resident context into expensive, badly-targeted retrieval.

**That refutes pointers, not microcontext.** The distinction is the whole of the
next design: a pointer invites the worker to fetch whatever it thinks it needs;
microcontext pushes a derived answer and never lets the worker near the
implementation. Only the first has been tested.

## Next

The gate-refusal path, which is the largest measured context item in the system:
**17 refusals, 107,278 characters, 23.8% of the Gravito arm's entire
tool-result volume, ~6.3 KB each.** Replacing that with a 30–100 token derived
ACTION STATE is a ~60× reduction on one known item.

**And it must be measured with ≥3 reps per cell from the start.** This
replication is the argument for that: n=1 produced a confident, wrong answer,
and cost two full experiment cycles to unwind.
