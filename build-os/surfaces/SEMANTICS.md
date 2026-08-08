# Surface participation — three layers, three different questions

**The earlier "divergence" was not a contradiction.** Two measurements were
answering different questions while wearing one name. Both are true at once:

> Claude is **repository-active** and **live-Operator-Lab-missing**.

Neither statement is wrong. Stating either without naming its dimension is.

## The three layers, weakest to strongest

| layer | question it answers | current state |
|---|---|---|
| 1 · `repository_surface_activity` | Is the surface leaving organizational memory? | claude **active** · chatgpt **active** · manus **UNTESTED** · surplus_recovery **UNTESTED** |
| 2 · `live_operator_lab_participation` **= `four_surface_readiness`** | Is it connected to the live control plane? | **FAIL** — chatgpt active; claude, manus, surplus_recovery **missing** |
| 3 · `cross_surface_behavioral_continuity` | Does knowledge transfer and change what another surface DOES? | **CONTINUITY_ACTOR_UNDISAMBIGUATED** |

These are different capabilities, and the substrate should know the difference.

## Layer 1 — repository_surface_activity

A **coverage/health signal**, not the readiness gate.

| property | value |
|---|---|
| data source | `build-os/kernel/memory_events.tsv`, committed rows only |
| active means | ≥1 event whose `surface_instance` prefix matches a declared family, in window |
| window / anchor | 7 days, anchored to the **latest ledger event** — never the wall clock, so the verdict is reproducible |
| identity rule | family = first dot-separated token of `surface_instance` |
| zero rows | `untested`, deliberately distinct from `stale` |
| provenance | repository ledger, this repo, at the reported anchor |

## Layer 2 — live_operator_lab_participation = `four_surface_readiness`

**This is the canonical operational readiness gate.** Its strategic purpose was
never "has this model ever left durable evidence somewhere" — it was *are all
intended surfaces currently participating in the live control/learning loop?*

| property | value |
|---|---|
| data source | live Operator Lab store |
| active means | rows written within the lookback window |
| window | **24 hours** |
| identity rule | family = first dot-separated token of `agent_id` |
| declared families | claude · chatgpt · manus · surplus_recovery |
| **current result** | **FAIL** — active: chatgpt · missing: claude, manus, surplus_recovery |
| provenance | operator-run query of the live Operator Lab interface |

**This repository does not compute layer 2.** It has no Lab access, and it will
not re-derive the value from repository data — doing so would recreate the exact
confusion this document resolves.

## Layer 3 — cross_surface_behavioral_continuity

State created by one **real** surface is consumed by another **real** surface
and **materially changes the receiving surface's behaviour**, with attributable
durable write-back.

**This layer is graded, not asserted.** `build-os/surfaces/continuity.mjs`
scores every claim across five links — origination, consumption, behavioural
divergence, durable write-back, onward consumability — and reports the
**weakest**. Two rules do the work, and both exist because a claim is not its
own evidence: a link asserted `PROVEN` with no evidence reference is
**downgraded**, and a divergence claim with **no counterfactual** is downgraded
because "it behaved differently" with no stated alternative is unfalsifiable —
receipt, echo and paraphrase all satisfy it vacuously.

The previous gate took `{ behaviour_changed: true, result_written_back: true }`
and counted the entries, so the strongest state the substrate could report was
settled by whoever typed `true`. That path is gone.

| claim | verdict | weakest link |
|---|---|---|
| `CONT-0001` — HOF-0001, claude compiles, chatgpt accepts | `CONSUMPTION_ONLY` | behavioural divergence **absent** |
| `CONT-0002` — the Operator Lab bridge episode | `CONTINUITY_ACTOR_UNDISAMBIGUATED` | consumption at `REPORTED` |

Current: **`CONTINUITY_ACTOR_UNDISAMBIGUATED`** — stronger than
`CONSUMPTION_ONLY`, and **short of** `BRIDGE_MEDIATED_CONTINUITY`.

**What CONT-0002 does establish.** Claude-originated durable state (a published
`blocked` conclusion) was consumed; the consumer **rejected** it rather than
accepting it, against a stated counterfactual — the default had already
occurred, with `#49` recorded blocked and the registry carrying
`status=violated`; an exhaustive interface search followed and produced live
control-plane rows 36263/36264; and a **third** consumer read the result
mechanically — `capability-map.mjs` records the bridge, `gate-stop.mjs` reads
that map at runtime, so the live Stop gate's refusal text differs *because of*
the Lab result.

**What it does not establish, and why it is not rounded up.** Repository
evidence cannot separate *ChatGPT performed the enumeration* from *the operator
performed it*; the operator's own account is first-person. Naming a
discriminator anyway would be exactly the fudge this subsystem exists to
prevent, so the claim grades one rung lower instead.

**That gap is a fetch, not a mystery.** The Lab records a calling identity on
the rows the enumeration produced. One query for the caller identity on
36263/36264 settles it. This repository has no Lab read path — the *same*
layer-2 access gap already on record — so the discriminator is absent from
**this surface**, not from the **system**, and every unfinished grade carries a
`missing_to_advance` naming precisely that.

## Reporting rule

Never write "Claude is active" or "Claude is missing" unqualified. Always name
the dimension: **repository-active**, **live-Operator-Lab-missing**. Every
readiness result must expose metric name, data source, window/anchor, surface
identity rule, and provenance.

**No single "2 of 4" number is published.** The two dimensions are reported
separately, because collapsing them is what produced the false contradiction.

## What was wrong, recorded

I proposed `four_surface_readiness = repository_activity AND live_participation`.
That was rejected, correctly: conjoining them blurs the architecture again by
making one number depend on two unrelated capabilities. The operational gate is
layer 2 alone; layer 1 is reported beside it as health, not folded into it.

## Still UNTESTED

`manus` and `surplus_recovery` — repository side **UNTESTED** (zero rows), live
side **missing**. No synthetic activation. They stay that way until the actual
surfaces participate.
