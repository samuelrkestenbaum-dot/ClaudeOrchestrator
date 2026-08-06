# Unsupported disclosure — what this cannot do

The blunt companion to every other document in this package. Read it before
anything is installed, and before any commitment is made. If any single item
here is a dealbreaker, say so now: it will not be less true in six weeks.

## 0. The evidence position

**All evidence for this product to date is internal.** It was produced by the
people who built it, on their own repositories. Nothing has been independently
checked, no external customer has ever run it, and no controlled economic
result exists. The strongest internal result is a five-task pilot on one real
product repository and a demonstration that a fresh session is governed by the
installed gate. That is a starting point, not proof, and the design-partner
pilot exists precisely to create the first evidence that is not ours.

Anyone who tells you otherwise is selling, not describing.

## 1. It is not a sandbox

The platform's permission system is the security boundary. This is discipline
for honest agents plus an audit trail. It does not contain a malicious agent
and does not claim to.

## 2. The command classification is a named heuristic, and it is evadable

The gate classifies a shell command by reading the tool-call JSON. The
evasions are documented in the contract itself, not discovered later:

- **`sh -c` and `eval`** slip the mutation classification entirely.
- **A wrapper script** that performs a mutation is classified by the wrapper's
  own command text.
- **`git -C <elsewhere>`** lands in the conservative-mutation class rather than
  being understood.
- **`git branch -D`** slips into the read-only git class.
- The routing-tool pass matches by **basename, not canonical path**, so a
  hostile file *named* like a routing tool at a different path passes ungated —
  inside the not-a-sandbox bound above.

Every one of these is a known hole, named in
`build-os/memory/routing_contract_live.md`. They are survivable because the
threat model is an honest agent making a mistake, not an adversary. If your
threat model is an adversary, this is the wrong control.

## 3. The no-parser consequence

Four language groups get regex/line symbol extraction; everything else gets
nothing (see [`SUPPORTED_STACKS.md`](SUPPORTED_STACKS.md)). On the repository
where it was first measured end to end, **390 of 415 files had no parser** and
**4 of 415 had a covering test** by the index's own heuristic.

The consequence is specific: a compiled context capsule can be small for two
indistinguishable reasons — because it was *selective*, or because it was
*ignorant*. A capsule cannot tell those apart about itself. The system's answer
is a capability report that measures index signal quality and is willing to
conclude "do not use a capsule here at all; explore the repository the ordinary
way". Expect that answer for most repositories today.

**No extractor is an AST.** No file this system reads has been parsed. Every
indexed file is flagged `partial`, permanently, and the flag is not decorative.

## 4. Tokens and cost are not visible while work happens

In an interactive session, live token counts and spend are **not** visible to
the gate. What is EXACT: dispatch counts, tool-call counts, and elapsed time —
and only in sessions where the hook actually loaded. What is an ESTIMATE and
labeled as one everywhere: a token proxy computed as tool-input characters
divided by four. It is **never billing truth** and is never promoted.

Real token and cost figures reconcile at close, and only where the surface
reports them at all. Consequences you should plan around:

- **Budget enforcement is partly protocol, not machinery.** The circuit-breaker
  sequence — stop spawning helpers, collapse into the parent loop, preserve
  state, continue lighter, report the degradation — is followed by the agent,
  because no bash hook can see a token counter mid-flight. It is verified at
  close, and only then.
- **A session that records false consumption is caught by nothing.** That gap
  is written into the contract in those words.
- The evidence dashboard therefore shows spend as `CLOSE-TIME` at best, and
  frequently `unavailable` — with the reason
  (`build-os/dashboard/DASHBOARD_CONTRACT.md`).

## 5. Hooks are per-session, and the install session is ungoverned

Hooks load at session start. **The session in which the gate is installed is
not governed by it.** Any change to the hook or its wiring takes effect at the
next session start, not immediately. A session started before the install, and
left running, stays ungoverned for its whole life.

## 6. One verified provider adapter. One.

Claude Code hooks is the only adapter with an executed demonstration. Codex /
OpenAI is recorded **interface-unverified** — the host was unreachable from the
verification environment (403 at the proxy on every attempt) and its hook
surface has deliberately not been guessed. Until a real call succeeds, work on
that host is **outside the boundary**. Any other provider has no adapter at
all.

## 7. The Context Compiler is implemented and performance-unmeasured

The compiler exists: an index, a capsule format, a capability report, an
expansion protocol, an eligibility procedure, a context-mode seam. **Nobody has
measured whether it makes anything faster, cheaper or better.** The A/B
experiment that would answer that is preregistered and has not produced a
result. Several of its components — the capability reporter, the context-mode
seam — **ship inert**: nothing in the runtime calls them, and the test suite
greps the runtime to prove that is still true.

Its own recommendation thresholds are labeled **derived defaults**: "nothing
has measured that they predict outcome quality; they are a starting position to
be revised against evidence, not a finding." Its confidence ordinals are
uncalibrated — no measurement yet shows a HIGH item is more often load-bearing
than a MEDIUM one.

Treat the compiler as an unproven component of the pilot, not as a feature you
are buying.

## 8. What the evidence dashboard cannot tell you

Of twenty-three fields in the dashboard contract, **six are `UNAVAILABLE`, and
four of those six are the outcome fields a buyer actually cares about**:

- **accepted outcomes** — nothing records whether a task's output was accepted;
- **human interventions** — the ledger records the *gate* intervening, which is
  a different event;
- **rework** — nothing distinguishes rework from progress without a human
  judgment;
- **regressions** — no receipt, ledger row or state row stores a test result.

The dashboard renders each of them as `unavailable`, with the reason and with
what would have to exist to fill it. It does not render them as zero. **This
system currently measures its own activity far better than it measures whether
that activity was any good**, and that sentence is in the contract document
too.

## 9. Measurement discipline is manual, and its weakest link is a person

Provider spend is read from the operator's own meter, verbatim, at the edges of
a measured window — never derived from tokens. That is honest, and it is also
manual, coarse, and dependent on someone remembering to do it at the right
moment. A window that crosses a plan reset is confounded and the reading must
be re-baselined. There is no automated meter.

## 10. Known defects and gaps, named rather than discovered later

- **The measured-window recorder does not store the commit count it computes.**
  `build-os/measure/window.sh close` prints the git-derived commit count to the
  terminal and writes the literal text `derived-from-git` into the stored slot.
  Durable *commits* is therefore `UNAVAILABLE` in the dashboard while durable
  *change size* (files, insertions, deletions) is available from the same row.
- **Receipt issuance is protocol, not machinery.** No machine cross-checks that
  a substantive task issued a routing receipt at all; the close-time gate only
  inspects receipts that exist. A task that never routes is invisible to it.
- **An unwritable routing store silences the audit log**, and the gate falls
  back to emitting the row on stderr. A session that both makes the store
  unwritable and discards stderr leaves no durable trace.
- **The gate fails open on its own errors**, by design — a gate that fails
  closed on a bug is a denial of service against you — which means a bug in the
  gate looks like permission.
- **An operator override exists** (`ROUTING_GATE_DISABLE=1`). It is always
  logged, subject to the bullet above.

## 11. What is not included at all

- No IDE integration, no web UI, no dashboard server. The evidence view is a
  command-line renderer that writes one file.
- No multi-repository or organisation-wide view. One repository, one store.
- No user-level attribution. Nothing here identifies a person.
- No integration with your issue tracker, code review tool, or CI beyond
  reading what is in the repository.
- No hosted service, no account, no licence check, no telemetry.
