# EXP-0002 — Conclusion

**`promising but underpowered`** — direction: at sequence level on this task
mix, **Gravito OFF used 74.8% fewer total tokens per durable accepted outcome**
(uncached agreeing at 78.8%), but per-task agreement was 3/5 against the
preregistered 4/5 bar, and the aggregate is dominated by the two tasks where
the installed surface invoked the full multi-agent protocol. The label comes
from the preregistered four-option vocabulary, assigned by a blinded
independent evaluator applying the mechanical rule, revealed only after the
analysis was committed.

## Reconciliation 1 — with EXP-0001's trivial-task overhead (mandated)

EXP-0001 measured full-Gravito ~2× overhead on one trivial task. EXP-0002
refines that finding rather than merely repeating it: **the overhead is not a
fixed tax — it is the cost of the full governed ceremony, paid only when the
protocol escalates.** Where arm B stayed light (T1, T2, T4), Gravito was
competitive to strongly cheaper — including **56% cheaper on T4**, the
mid-sequence fix where accumulated repository context matters most, which is
the first controlled evidence FOR the memory hypothesis. Where the ceremony
fired (T3: five subagent gates on a bounded feature; T5: four on a follow-up
the mode selector itself scored `gravito_light`), cost exploded 4–8×. Both
experiments point at the same product requirement: **routing, not removal.**

## Reconciliation 2 — with the historical weekly-usage drop (mandated)

Still not directly explained: the meter is unobservable from this environment,
and the operator's real overnight workloads are longer-horizon and
interactively orchestrated — the ceremony amortized over large packets, not
five small tasks. What EXP-0002 adds is mechanism-level plausibility in both
directions: repository-owned context measurably cut per-task tokens on the
light tasks, and unrouted full-ceremony escalation measurably multiplied them.
The drop remains prior evidence; the controlled test of it needs either the
meter (operator-side capture around future runs) or a workload shaped like the
real one.

## The productizable finding

The operator's direct / gravito_light / gravito_full routing hypothesis now has
measured support: the descriptive mode selector's own verdicts, recorded before
any outcome, would have avoided both blowouts (T3 disproportion, T5 overshoot)
while keeping the tasks Gravito won. A router that enforces those verdicts —
promotion being an operator act, per the selector's registry entry — is the
smallest change this data supports. It is recorded here as the next candidate,
not built: the experiment stays frozen and acting on findings is the operator's
decision.

## Defects recorded for later (freeze rule honored; harness untouched)

1. The CLI result-event `usage.*` block undercounts dispatch-heavy sessions
   (~70× on arm B's T3); the complete `modelUsage` aggregate reconciles with
   cost and was used uniformly. A future harness revision should read
   `modelUsage` natively.
2. The sealed-transcript/citation-sweep collision (fixed in-packet by
   restoring EXP-0001's sealed form; the sweep itself untouched).

## Scope

N = one sequence per arm on one synthetic-but-ordinary repository, one model
configuration, headless, arm order A-then-B with the uncached comparison ruling
out cache warmth as the driver. This is the first controlled measurement of the
sustained hypothesis, not its final word — exactly what the preregistration
said it would be.
