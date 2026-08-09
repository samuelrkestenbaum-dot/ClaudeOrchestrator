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

## CORRECTION — the gate-refusal figure quoted throughout this work was wrong

An earlier version of this section named the gate-refusal path as the largest
context item: *"17 refusals, 107,278 characters, 23.8% of tool-result volume,
~6.3 KB each."* **That figure was contaminated and is withdrawn.**

It came from a marker regex that matched the gate FILE'S OWN COMMENTS whenever
the worker read `routing-gate.sh` with the Read tool. The largest "refusal" it
counted was 47,787 characters of shell source. The flaw was identified when it
first appeared and the number was still quoted afterwards — in this document, in
the prototype rationale, and in discussion — which is how a known-suspect
measurement ends up load-bearing.

Recomputed by pairing every tool_result with its originating tool_use and
excluding Read results:

| | tool-result volume | gate refusals | Read results |
|---|---|---|---|
| native | 204,243 | **0** | 18 = 125,295 |
| gravito | 451,271 | **15 = 11,704 chars (2.6%), median 645** | 61 = 431,176 |

Gate refusals are **2.6% of volume at a median 645 characters**, not 23.8% at
6.3 KB. Replacing all of them with a 30–100 token ACTION STATE would save ~730
tokens per arm against arms costing ~90,000 — **under 1%**. As a prototype
target it was not worth building.

## What the real target is

Read volume, split by what is being read:

| | read volume | product code | **Gravito substrate** |
|---|---|---|---|
| native | 125,295 | 125,295 (100%) | — |
| gravito | 431,176 | 235,821 (55%) | **195,355 (45%)** |

**The Gravito worker spends 45% of its read volume reading Gravito's own
implementation** — ~49,000 characters per arm, roughly 12,000 tokens. That is
~16× the gate-refusal item, and it is the architectural principle stated as a
measurement: the worker should receive the answer derived from Gravito state,
never the implementation used to derive it.

A second effect is recorded but unexplained: gravito also reads **1.9× more
PRODUCT code** than native for the same tasks (235,821 vs 125,295). Whether the
substrate induces broader exploration, or something else does, is not
established here and should not be assumed.

## Next

Target the substrate-read volume, not the gate's output. And measure it with
**≥3 reps per cell from the start**: this replication is the argument, since n=1
produced a confident wrong answer that cost two full experiment cycles to
unwind — and the metric that pointed at the wrong target was itself never
re-derived after being flagged.
