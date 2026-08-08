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
| 3 · `cross_surface_behavioral_continuity` | Does knowledge transfer and change what another surface DOES? | **CONSUMPTION_ONLY** |

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

Current: **CONSUMPTION_ONLY**. `HOF-0001` (created by claude, accepted by
chatgpt) proves receipt. Receipt is not behaviour change. Acknowledgment,
paraphrase and echo are all equally insufficient.

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
