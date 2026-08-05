# EXP-0002 — Conclusion

**`no sustained-workload savings detected`** — with the magnitude and direction
stated as the registered rule requires: at sequence level on this task mix,
**Gravito OFF used 74.8% fewer total tokens per durable accepted outcome than
Gravito ON — equivalently, ON ran at 3.96× (+296%)**
(2,631,154 vs 663,924; uncached agreeing at 78.8%; 10/10
acceptance both arms; ON cumulatively cheaper only through T2, the crossover
against it at T3 on totals and already at T2 on uncached tokens and cost).

Label provenance, stated for the record: the blinded evaluator, working from
the X/Y-neutral symmetrization of the rule (committed for audit at
`analysis/EVALUATOR_RULE_TEXT.md`), mechanically produced step-4 wording
("promising but underpowered, direction X"). The REGISTERED rule
(`PREREGISTRATION.md` §6) is direction-specific — steps 2 and 4 require the
≥25% difference to be **in B's favor**, and §6 pre-assigned this exact outcome:
"The symmetric possibility (B worse, as in EXP-0001) is reported under rule 3
with its magnitude." B was worse. The translation stage applies the registered
rule; both gates caught the mistranslation independently and this document
carries the corrected label. The blinded analysis file is verbatim evidence
and is untouched.

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

The operator's direct / gravito_light / gravito_full routing hypothesis has
measured support of a precise, narrower shape. The selector's recorded verdicts
(T1→direct, T2/T4/T5→gravito_light, T3→gravito_full): a router ENFORCING them
would have prevented **only the T5 blowout** (selector said light; the surface
went full, 4 dispatches, $4.80 vs $0.55). **T3 is different and harder**: the
selector itself said `gravito_full`, the surface complied, and full ceremony on
a bounded feature cost 3.9× — so T3 is evidence about selector calibration
and/or full-mode cost even when correctly selected, and it weakens rather than
supports plain enforcement. What the data supports: routing that keeps the
light path where Gravito won (T1 −31.5%, T4 −56.5%), enforces light where the
selector already says light (T5), and re-examines when full ceremony is worth
its measured 4× on bounded work. Recorded here as the next candidate, not
built: the experiment stays frozen and acting on findings is the operator's
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
