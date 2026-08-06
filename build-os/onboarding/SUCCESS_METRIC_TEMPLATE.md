# Success-metric template

**Agreed and signed BEFORE the pilot starts.** A success criterion chosen after
the results are in is not a criterion; it is a description. This form mirrors
the success metrics in `build-os/partner/DESIGN_PARTNER_PACKAGE.md` §6 and
turns them into numbers you commit to in advance.

Fill in the **target** column before day one. Leave **measured** and **verdict**
empty until the pilot closes.

---

## 0. Scope and period

| | |
|---|---|
| repositories in scope | |
| period (start → end) | |
| baseline period captured | (dates; see `BASELINE_CAPTURE.md`) |
| task mix in scope | |
| who judges acceptance | |
| who reads the meter | |
| AI host used, and whether **all** in-scope work ran on it | |

**That last row matters more than it looks.** Only Claude Code hooks is a
verified adapter. Work done on any other host is ungoverned and unrecorded, and
if some of the pilot's work runs there, the receipts describe a different
population than the one the targets refer to. Write down the estimated share.

---

## 1. The seven metrics

| # | metric | baseline | target | measured | verdict |
|---|---|---|---|---|---|
| 1 | **accepted-task rate** — accepted ÷ attempted | | | | |
| 2 | **durable commits** — commits still standing at the end of the period | | | | |
| 3 | **human-intervention count** — times a person had to stop or steer a run | | | | |
| 4 | **rework rate** — tasks re-done after being called finished | | | | |
| 5 | **provider spend per accepted task** — meter delta ÷ accepted count | | | | |
| 6 | **audit completeness** — receipts per mutation | | | | |
| 7 | **your team's own acceptance judgment** — in their words | | | | |

**Metric 7 is not a tiebreaker; it is a first-class metric.** If the numbers
improve and your engineers say it was worse to work with, that is a result and
it goes in the report as one.

---

## 2. How each metric will be obtained — agreed in advance

| # | source | tier |
|---|---|---|
| 1 | operator judgment recorded per task; **no tool records this** | manual |
| 2 | git, via the measured-window recorder — **but see the note below** | close-time |
| 3 | operator note per task; **no tool records this** | manual |
| 4 | operator judgment against a prior task id; **no tool records this** | manual |
| 5 | verbatim meter readings at window edges ÷ operator-judged acceptance | manual |
| 6 | routing receipts vs governed changes, from the routing store | exact |
| 7 | written statement from your team | manual |

**Five of seven are manual.** That is not a process failure to be tidied up
later; it is the honest state of the instrumentation today. The evidence
dashboard renders acceptance, interventions, rework and regressions as
`unavailable` with the reason, because nothing in the system records them
(`build-os/dashboard/DASHBOARD_CONTRACT.md`). **If nobody does the manual
recording, those five metrics simply will not exist at the end.**

**Note on metric 2:** the window recorder stores files/insertions/deletions but
writes the literal text `derived-from-git` into the commit-count slot. Capture
the commit count from the terminal at close, or count it from git yourself.

---

## 3. Stop conditions — agreed in advance

The pilot halts immediately if any of these occur:

| stop condition | agreed? |
|---|---|
| an unapproved external mutation happens (push / merge / deploy / spend) | |
| a change reaches the main branch that nobody can account for | |
| the gate blocks legitimate work in a way that cannot be worked around | |
| provider spend exceeds ______ in a single window | |
| your team asks to stop, for any reason or none | |
| a data-handling concern arises | |
| _(your addition)_ | |

**"Your team asks to stop" needs no justification and carries no penalty.**

---

## 4. What will be reported at the end

A written evidence report containing, at minimum:

- every metric above with its measured value, or an explicit statement that it
  was not measured and why;
- the two verbatim meter readings per window, and whether any window was
  confounded by a plan reset;
- every task attempted, with its depth, its result, and its receipt;
- **everything unflattering** — the tasks that failed, the blocks that were
  wrong, the fields that stayed unavailable, the places where the tooling was
  blind;
- an explicit statement of what the pilot did **not** establish.

**Confounded windows are recorded as confounded and excluded from the
aggregate. They are never repaired into looking clean.**

---

## 5. What this pilot cannot establish, agreed in advance

Write these down now so nobody is disappointed by them later:

- **It is not a controlled experiment.** One repository, one team, one period,
  no control arm. It cannot separate the effect of this tooling from the effect
  of the attention the pilot itself brings.
- **It cannot establish a cost-per-outcome figure reliably**, because spend is
  close-time at best and acceptance is a human judgment. A ratio of an estimate
  to a judgment is not a measurement.
- **It says nothing about any other repository**, including your others.
- **It does not evaluate the Context Compiler**, which is implemented and
  performance-unmeasured, and several of whose components ship inert.

---

## 6. Signatures

| role | name | date |
|---|---|---|
| your technical owner | | |
| your acceptance judge | | |
| your meter reader | | |
| your approver for external mutations | | |
| us | | |

**Signed before the pilot begins.** A copy of this form, filled in with targets
and unsigned in the measured/verdict columns, goes into the repository at the
start so that the criteria are in version control and cannot drift.
