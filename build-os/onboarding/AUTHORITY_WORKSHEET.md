# Authority worksheet

Fill this in **before** the first governed session. It is a form, not a policy
document: it records who decides what, in your organisation, in your words.

**The default, which is not negotiable and not configurable away:** every
external mutation — push, merge, deploy, publish, spend, outreach, or touching
secrets — **requires an explicit human go, every time.** The gate cannot and
does not self-authorise an action that leaves the machine. Nothing you write
below can turn that off. What you can decide is *who* gives the go, and what
additional things you want gated on top.

---

## Part 1 — Who approves what

One named human per row. "The team" is not an answer; if it is genuinely
shared, name the two or three people and say how they decide.

| action | who approves | how they are asked | how they respond | escalates to |
|---|---|---|---|---|
| push to a shared branch | | | | |
| merge to the main branch | | | | |
| deploy to staging | | | | |
| deploy to production | | | | |
| database migration | | | | |
| infrastructure change | | | | |
| dependency addition or upgrade | | | | |
| spending money (new service, increased AI spend) | | | | |
| anything customer-facing or outbound | | | | |
| touching a secret or credential | | | | |
| changing this worksheet | | | | |

**If one person holds most of these rows, write that down explicitly here:**

> Concentration note: ______________________________________________

That is not a criticism. It changes what the gate is protecting against, and it
belongs in the record rather than in someone's head.

---

## Part 2 — What you want gated, beyond the default

The gate can require a routing decision before a change is made, and it blocks
unrouted changes with a recovery command. Tell us where you want that to bite
harder than the default.

| area | your instruction | notes |
|---|---|---|
| directories that must **never** be edited by an agent | | |
| directories where a change requires a **named human review** before merge | | |
| file patterns that must never appear in a diff | | |
| commands that must never run | | |
| times of day / days when nothing should run | | |
| repositories in scope | | |
| repositories explicitly **out** of scope | | |

**Honest bound on this section:** the command classification is a **named
heuristic and is evadable** (`sh -c`, `eval`, wrapper scripts — see
[`UNSUPPORTED_DISCLOSURE.md`](UNSUPPORTED_DISCLOSURE.md) §2). Writing "never
run `rm -rf`" here produces discipline and an audit trail, **not a fence**.
Anything that must be mechanically impossible has to be made impossible by your
platform permissions, not by this.

---

## Part 3 — What you want allowed without asking

Friction that buys nothing is friction people route around. Say what should
just happen.

| activity | allowed without asking? | conditions |
|---|---|---|
| reading any file in the repository | | |
| running the test suite | | |
| running the linter / type checker | | |
| local commits on a working branch | | |
| creating a branch | | |
| editing documentation | | |
| editing tests | | |
| editing application source | | |
| installing dev dependencies locally | | |

---

## Part 4 — The three depths

Work is routed to a depth before it runs. Confirm you are content with the
defaults, or change them.

| depth | what it means | default | your call |
|---|---|---|---|
| **Direct** | a small, reversible change made straight away in the main loop | for low-consequence, single-file work | |
| **Light** | one careful pass in the main loop; no helper agents | the default for ordinary work | |
| **Full** | implementation plus independent checking and review; helper agents allowed, capped by an explicit budget | for high-consequence, wide-blast-radius, security- or compliance-touching work | |

- **Escalation costs a stated reason. De-escalation is free.** Running above
  the recorded depth requires a new, evidence-bearing record written *before*
  the escalated work begins.
- **Budgets are ceilings agreed up front, not bills.** When one is approached,
  the system is required to degrade gracefully — stop spawning helpers,
  consolidate into the main loop, preserve state, continue lighter, and record
  the degradation — rather than stop the task.

Anything you want routed at Full regardless of size:

> ______________________________________________________________

---

## Part 5 — Incident handling

1. Who is told, and how, if an agent makes a change nobody asked for?
2. Who is told if the gate blocks something that should have been allowed?
3. What is your rollback procedure for a bad change that reached the main
   branch?
4. Who may use the operator override (`ROUTING_GATE_DISABLE=1`), and under what
   circumstances? *(Its use is always logged, subject to the unwritable-store
   gap named in the disclosure document.)*
5. What is the stop condition — what would make you halt the pilot on the spot?

---

## Part 6 — Signatures

| role | name | date |
|---|---|---|
| approver for external mutations | | |
| technical owner of the repository | | |
| person taking the meter readings | | |
| person judging task acceptance | | |

**The last two are not ceremonial.** Provider spend is read from a meter by a
person, verbatim, at the edges of each measured window
([`BASELINE_CAPTURE.md`](BASELINE_CAPTURE.md)), and **acceptance is not
recorded by any tool** — the dashboard renders it `unavailable` for exactly
that reason. If nobody signs those two rows, the pilot produces activity data
and no outcome data.
