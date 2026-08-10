# EXP-0008 — INVALID AS A TEST of microcontext; the implementation is disqualified

> **CORRECTION, made after the operator challenged the verdict.** This document
> originally concluded `REFUTED`. That was wrong, and wrong in the exact way the
> document itself diagnoses: it drew a conclusion from **n=1** on a metric shown
> **in the same document** to have a **240× within-cell range**. A single arm
> reading 100,585 cannot distinguish "the treatment made it worse" from "this is
> what this metric does." The verdict is withdrawn.
>
> **What stands, because it needs no statistics:** the shim enlarged
> `routing-gate.sh` from 45,049 to 47,846 bytes — verifiable with `wc -c`. A
> treatment meant to make a file unnecessary made it larger. The
> **implementation** is disqualified on inspection. The **hypothesis** remains
> untested.

**Two findings. The second matters more than the first.**

## 1. The implementation is disqualified — but this is not a refutation

Against the stopping rule frozen before execution — reads materially fall, turns
not materially rise, acceptance holds, no read substitution, cost improves —
**implementation reads ROSE**:

| | implementation chars read |
|---|---|
| baseline T01, three reps | 392 · 197 · 0 |
| microcontext v2 (repaired) | **100,585** |
| microcontext v1 (confounded) | 35,825 |

Not marginal, and outside any plausible spread for that cell.

**The cause is the design, not luck.** The shim prepends into
`routing-gate.sh`, taking it from 45,049 to 47,846 bytes. The worker still read
the gate, and read **more of it** — 50,794 chars in one read. A treatment
intended to stop the worker reading a file made that file larger.

Both versions failed for the same underlying reason wearing different clothes:

- **v1** RENAMED the gate, creating `routing-gate-real.sh` — a new
  implementation file — which the worker read for 8,090 chars;
- **v2** ENLARGED the gate it was trying to make unnecessary.

The worker reads the gate because it wants to know how the gate works, and no
amount of derived state at the refusal point changed that. The ACTION STATE was
delivered — 8 payloads in v1, and v2's payload passed all seven emission checks
— and the worker read the implementation anyway.

**Per the operator's rule, no third attempt at THIS implementation.** But the
hypothesis — that a worker given tiny derived answers stops reading the
substrate — has not been tested by this experiment, because the experiment could
not have measured it.

## 2. The target was a mean over a heavy tail, and I froze it without its spread

Baseline implementation reads, per arm, same configuration:

| task | rep1 | rep2 | rep3 | mean |
|---|---|---|---|---|
| T01 | 392 | 197 | 0 | 196 |
| T02 | 17,246 | 111,178 | 12,937 | 47,120 |
| T03 | 25,109 | 392 | 94,098 | 39,866 |
| T04 | 160,435 | 17,049 | 17,049 | 64,844 |

**Pooled mean 38,007. Median 17,049. T03's within-cell range is 240×.**

The headline that justified this experiment — *"45% of read volume, ~49,000
chars per arm"* — is a mean over a distribution where the median arm reads
17,049 and a single arm read 160,435. It is not wrong, but it is not a stable
quantity to design against, and **3 reps could not have evaluated any prototype
against it.**

I froze that mean across 12 arms and never examined its distribution. EXP-0007's
replication had just established exactly this lesson for the token metric — a
28% CV made a 34% screening "win" meaningless — and I applied it there and not
here, one experiment later, to the metric I then built an experiment around.

## What survives

- **The architectural argument is untouched, and so is the hypothesis.** A worker should not have
  to read the substrate's implementation to operate under it. That remains a
  reasonable design principle; what fails is the claim that this measurement
  supports a specific intervention, and that this intervention delivers.
- **The mechanism question is now sharper, not answered.** The worker reads the
  gate even when handed the derived answer at the moment of refusal. Whether it
  reads to *understand* rather than to *act* — in which case no
  point-of-refusal payload will help — is untested and is the question a next
  design would have to face.

## What must change before any further optimisation of this kind

**Establish the spread before freezing a target.** A mean without its
distribution is not a measurement, it is a summary — and three of the last four
targets offered in this work came from first-pass aggregates that did not
survive examination: the gate-refusal figure (contaminated classifier), variant
C's screening win (n=1 against a 28% CV), and this one (mean over a 240% -- 240×
-- within-cell range). Each was caught, and each was caught only after it had
already shaped a decision.


## The test that would actually settle it

Not implementation-read volume — that metric is unusable at feasible rep counts.
**Turns, total cost and acceptance**, whose within-cell CV is ~24-39% rather
than 240×, and which are what anyone actually cares about.

The question, stated so it cannot be softened afterwards:

> Can a lean substrate — authority, memory, continuation and routing all
> mechanical; no protocol narration; the worker receiving derived answers rather
> than implementation — bring **turns and total cost close to native** without
> losing acceptance?

Current gap to beat: **1.40× turns, 1.52× context/turn, 1.33× output/turn**
(EXP-0006, 12 tasks). If a genuinely lean build still costs dramatically more
than native at equal acceptance, the interaction model is not the problem and
the thesis is. That test has not been run.
