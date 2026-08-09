# EXP-0007 — three-factor ablation of the Gravito tax

**Not a whole-system benchmark.** EXP-0006 already answered "does the substrate
pay for itself" (no: UIC 10.36 vs 18.15). This asks the next question: **which
of the three taxes can be removed without losing the behaviour.**

## What EXP-0006 established, and is not re-litigated here

The overhead decomposes into three factors that multiply:

```
1.40×  more turns                    (370 → 517 over 12 tasks)
1.38×  more uncached tokens per turn
─────
1.93×  total          (1.40 × 1.38 = 1.93)
```

| | total | turns | per turn |
|---|---|---|---|
| uncached | 1.93× | 1.40× | 1.38× |
| cache read | 2.13× | 1.40× | 1.52× |
| output | 1.86× | 1.40× | 1.33× |

**T10 is the load-bearing natural experiment.** Gravito used *fewer* turns than
native (27 vs 29) and still cost 1.82× overall, at 1.95× per turn. Context tax
alone can sink the economics with zero step penalty. Preserved as evidence.

## The one economy that makes this cheap

**The native arm is already measured and frozen.** EXP-0006's native results at
seed `2543c873` are the reference for every configuration here. No configuration
re-runs native. That halves every cell.

## Factors

| | tax | what moves | candidate interventions |
|---|---|---|---|
| **A** | step | turns/task | routing receipts issued mechanically rather than through a worker Bash round-trip; the routing gate not blocking `Bash` categorically (it forced workarounds that cost turns); lane/budget declaration stops being a dialogue act |
| **B** | context | cache-read + uncached per turn | doctrine retrieved narrowly instead of riding every turn; memory fetched on demand rather than injected; hook/context boilerplate removed from the per-turn payload |
| **C** | output | output tokens/turn | lane announcements, tool-budget declarations and protocol narration become silent machine state |

**The factors are not orthogonal, and that is stated rather than assumed.** A
lane declaration costs a turn *and* output; removing it moves A and C together.
This is why every configuration reports all four metrics — a design that
reported one number could not tell an A-improvement from a C-improvement, or
notice that one got worse.

## Configurations

| id | administered | purpose |
|---|---|---|
| `baseline` | full current substrate | reproduces EXP-0006's Gravito arm at this seed; the anchor |
| `A` | step interventions only | isolates turn reduction |
| `B` | context interventions only | isolates per-turn payload |
| `C` | output interventions only | isolates narration |
| `ABC` | all three | the compounded effect, which is the number that matters |
| *(native)* | — | **not re-run**; EXP-0006's frozen native arm is the reference |

5 configurations × 4 tasks (T01–T04, the EXP-0006 pilot set) = **20 arms**.
Screening runs on 4 tasks because the question is per-turn *rates*, which need
far less power than an acceptance difference. Acceptance is still reported and
still gates: **a configuration that reduces cost while losing an accepted
outcome has not won.**

## Reporting — every configuration, every metric, independently

```
turns/task · uncached tokens/turn · cache-read tokens/turn · output tokens/turn
total cost/task · acceptance · regressions · UIC
```

**No aggregate may stand alone.** The failure this guards against is an
intervention that cuts turns 25% while inflating context 20% and reports a
small UIC win. `analyse.mjs --factors` emits the four rates side by side with
the EXP-0006 native reference, so a trade is visible rather than netted.

## Success target (operator-set)

| factor | target vs native |
|---|---|
| turns | ≤ 1.10× |
| context/turn | ≤ 1.10–1.15× |
| output/turn | ≤ 1.10× |
| acceptance | no worse than native |

Compounded: ≈ **1.33×** against today's ≈ 2×. If any factor lands *below* 1.0 —
which context compilation could in principle do, by supplying the right state
instead of the whole repository — parity becomes reachable.

## The architectural principle this tests

**More substrate, less prompt.** Every behaviour Gravito has earned is
preserved — authority, persistence, capability exhaustion, continuation,
objective prioritisation, cross-surface state, evidence, recovery. What changes
is *where* they happen: mechanically in the substrate rather than as turns and
prose in the model's conversational loop.

**A control is never removed because it costs tokens.** It is relocated or
compressed only where the same behaviour is maintained mechanically. Any
configuration that drops a behaviour is a failed configuration, not a cheap one
— and the acceptance criterion plus the preserved-behaviour checklist are what
detect that.

## Stopping rule

No fresh whole-system 12-pair benchmark until a materially leaner substrate
exists. Factor screening first; a full re-run is the confirmation, not the
search.
