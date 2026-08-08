# Readiness-source divergence — two authorities, one claimed state

**Neither measurement is currently canonical, and the newer one was NOT
preferred.**

| authority | Claude | ChatGPT | Manus | surplus_recovery |
|---|---|---|---|---|
| repository kernel ledger (this repo) | **active** — 22 events, 10 types | active — 2 events | untested — 0 | untested — 0 |
| live Operator Lab `check_substrate_readiness` | **missing** | active | missing | missing |

They disagree about Claude, and that disagreement is the defect: *a claim about
system state must not depend on which measurement surface you ask.*

## What I could establish, and what I could not

**Fully specified — the repository side**, because it is implemented here:

| question | answer |
|---|---|
| data source | `build-os/kernel/memory_events.tsv`, committed rows only |
| what qualifies as active | ≥1 event whose `surface_instance` prefix matches a declared family, inside the window |
| window | 7 days, anchored to the **latest ledger event**, never the wall clock — so the verdict is reproducible |
| identity normalisation | family = first dot-segment of `surface_instance` (`claude.cowork.session.ramhds` → `claude`) |
| zero rows | `untested`, deliberately distinct from `stale` (wrote once, not lately) |

**NOT established — the Operator Lab side.** I could not query it. There is no
local specification of `check_substrate_readiness` anywhere in this repository,
and the only candidate MCP server requires an OAuth flow that a non-interactive
session cannot perform. **So I cannot state its data source, its activity
criterion, its window, or its normalisation** — and I will not infer them from
its output.

## Diagnostic questions — status

| # | question | status |
|---|---|---|
| 1 | data source of each | repository side ANSWERED; Operator Lab **UNRESOLVED** |
| 2 | what qualifies as active | repository side ANSWERED; Operator Lab **UNRESOLVED** |
| 3 | do the windows differ | **UNRESOLVED** — the repository window is anchored to ledger data; a live gate anchored to wall clock would already disagree, since the newest ledger event is 2026-08-02 |
| 4 | identity normalisation | repository side ANSWERED; **UNRESOLVED** whether the Lab keys on `surface_family`, `provider`, `actor_id`, or a session id |
| 5 | are Claude ledger events reaching the Lab store | **UNRESOLVED — and the leading hypothesis** |
| 6 | repository memory vs live calls | **LIKELY THE ROOT CAUSE** — see below |
| 7 | semantically different, mislabelled as one | **LIKELY YES** |

## Leading hypothesis, stated as a hypothesis

The two systems probably measure genuinely different things:

- the ledger records **durable authorship** — who has committed state into the
  repository substrate, ever, within a data-anchored window;
- the Operator Lab plausibly records **live participation** — who has called
  into the Lab recently, by wall clock.

Claude writes into the repository through git. If Claude never calls the
Operator Lab API, it would be simultaneously **the most active repository
author** and **absent from live participation** — both readings true, neither
wrong, and the label `four_surface_readiness` wrong for both.

**This is a hypothesis. It is not confirmed, and I did not confirm it by
preferring my own result.**

## Action taken now

The repository gate is **renamed to what it actually measures**:
`repository_surface_activity`. Its output carries `NOT_CANONICAL_READINESS`
pointing here. Calling it `four_surface_readiness` while a second authority
disagreed was the mislabelling this document exists to stop.

## Proposed canonical definition — for operator ratification, not adopted unilaterally

    repository_surface_activity      — declared families authoring durable state
                                       in the committed ledger (implemented here)
    live_operator_lab_participation  — declared families calling the live Lab
                                       within its window (NOT implemented here;
                                       specification unknown to me)

    four_surface_readiness = PASS  iff  BOTH are PASS for all four families

Requiring both is the conservative choice: a surface that authors durable state
but never participates live is not organizationally present, and one that
participates live but authors nothing leaves no durable trace. Provenance —
which authority produced each half, over which window, from which source — must
travel with any verdict quoted as readiness.

## What is needed to resolve this

One of:

1. the Operator Lab's readiness specification (data source, activity criterion,
   window, identity key); or
2. a session with Lab access so the query can be run beside the ledger query on
   the same anchor; or
3. an operator-run query of both, reported together.

Until then `four_surface_readiness` has **no canonical value**, and this
repository does not publish one.
