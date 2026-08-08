# Registered outcome vocabulary — for FUTURE experiments

**This registry does not apply retroactively.** Every completed experiment
keeps the vocabulary frozen into its own preregistration. In particular
EXP-0005's registered verdict remains `gravito_system_harmful`; nothing here
reclassifies it.

## States

| state | meaning |
|---|---|
| `system_efficiency_supported` | all registered gates met |
| `system_efficiency_directional` | favourable, gates not all met |
| `quality_gain_without_compute_gain` | acceptance up, economics not |
| `compute_gain_with_quality_shortfall` | economics up, acceptance down — the veto case |
| `no_system_advantage_detected` | null result |
| `<treatment>_system_harmful` | the treatment is worse on the registered terms |
| `inconclusive` | evidence insufficient to choose |
| `result_confounded` | an unregistered factor makes the comparison unreadable |
| **`treatment_never_executed`** | **new — see below** |

## `treatment_never_executed`

> The treatment was administered as specified and the measurement remained
> valid, but the treatment **failed to enter an operational state capable of
> attempting the requested product outcome**.

**Why it exists.** The vocabulary could not distinguish *active harm* from
*catastrophic non-action*. Both collapsed into "harmful", and a reader seeing
that label infers a treatment that executed and did poorly. Those are different
failures with different fixes, and per-accepted-outcome economics are
**UNDEFINED** under non-action rather than merely poor.

**State is recorded separately from cause**, so the state generalises:

    state: treatment_never_executed
    cause: <the specific reason it never entered operation>

**Known causes are not limited to internal defects.** The first observed
instance arose from a **product/host interaction** — the treatment's
authority-bootstrap path required an operation class the host declined, so it
never reached the work. It was *not* an internal deadlock, although it was
first misdiagnosed as one. Candidate causes therefore include at least:

- `authority_bootstrap_permission_class_mismatch` — earning authority requires
  a stricter permission class than the work itself;
- `bootstrap_deadlock` — an internal circular precondition;
- `environment_precondition_absent` — a required external dependency missing;
- `harness_defect` — the measurement apparatus prevented execution.

**Relationship to `result_confounded`.** They are not alternatives.
`treatment_never_executed` describes what the treatment *did*;
`result_confounded` describes whether the *comparison* can be read. An
experiment can be both — non-action caused by an unregistered environmental
factor is both a valid observation of the treatment and an unreadable
efficiency comparison.

## Registration requirement this creates

Any experiment that could plausibly return `treatment_never_executed` must
**register the host permission mode, and any other environmental authority
policy, as part of the treatment environment** — not leave it to a harness
choice made during execution.

## Detection

`build-os/learning/disposition.mjs` v1 carries two generic predicates for this
shape: `total-acceptance-floor` and `spend-without-durable-output`. Both are
`queue`, never `execute` — see `build-os/learning/NON-ACTION-VALIDATION.md` for
why, and for the validation set that excludes the experiment which inspired
them.
