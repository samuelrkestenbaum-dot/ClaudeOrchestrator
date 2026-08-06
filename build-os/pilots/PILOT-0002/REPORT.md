# PILOT-0002 — clean-window report

Internal external-style real-repository pilot, repeat run. Measurement
improved; mechanics deliberately unchanged from PILOT-0001.

## Frozen ancestry (the proof the rules predate the result)

- Freeze commit `24233b8`, PUBLISHED to origin before the window opened.
- Frozen seed: `93f75ea` (empathiq-website).
- Pilot branch `pilot/PILOT-0002-clean-window`, cut from that seed at
  window open. `cb2bb7d` verified NOT an ancestor.
- Before-reading `5d82a09`; baseline states `af5804b`; after-reading
  `50756b0`.

## Measured window

Open `2026-08-06T20:59:21Z` — close `2026-08-06T21:42:15Z`.
Contents: T1-T5, their routing receipts, and nothing else. No reporting,
no correction exchanges, no unrelated work, no pushes.

Measured task time: 672 + 228 + 282 + 236 + 495 = **1,913s (~32 min)**.

## Per task

| Task | Frozen description | Mode sel/exec | Elapsed | Budget | Outcome |
|---|---|---|---|---|---|
| T1 | trpc `bridge`/`bridges` drift, 6 errors | light/light | 672s | 600s — **breached +72s, declared** | accepted |
| T2 | `CoverageReportData.coverage` drift, 6 errors | light/light | 228s | within | accepted |
| T3 | agents hermetic + un-skip daily report | light/light | 282s | within | accepted |
| T4 | `IAutoRetrainingPipeline` extends-conflict | light/light | 236s | within | accepted |
| T5 | voice-stream LogDomain + webhooks narrowing, fresh context | light/light | 495s | within | accepted |

All five routed **Light**. No task earned Full. Escalations: 0. Silent
escalation: 0. Subagents: 1 (T5's fresh-context executor). Human
interventions inside the window: **0**.

## Durable output

Five product commits on the pilot branch, from seed `93f75ea`:
`7cd73cd`, `451224f`, `b97b2fb`, `9a06ba1`, `b6ade3d`.
10 files changed, +319 / -65.

- tsc: **778 -> 754** (24 errors removed), zero new errors at every task,
  verified line-insensitively.
- `server/agents/agents.test.ts`: 3 failed / 1 skipped -> **17/17 passing,
  zero skipped, across three consecutive runs**.
- `server/webhooks/connector.test.ts`: 5/5 before and after (T5).

## Economics — the exact epistemic boundary

Meter BEFORE: all models 1%, Fable 0%. AFTER: all models 1%, Fable 0%.
Direction wording absent on both readings. Displayed movement: **0
percentage points on both meters.**

DEFENSIBLE STATEMENT:
Five accepted tasks and five durable commits, completed in about 32
measured minutes with zero human intervention, WITHOUT moving either
displayed weekly meter off its starting value.

NOT ESTABLISHED, and not to be stated: zero tokens; zero usage; infinite
output per meter point; exact percentage consumption; exact cost savings;
sub-percentage usage as a figure. The display carries whole percentages
and Fable stood at 0% before the window, so pilot-attributable movement
is bounded only as **less than one displayed percentage point on both
meters**.

The registered headline ratio (durable output per displayed point) has a
denominator of zero. It is **undefined**, not infinite, and is reported
as undefined.

MEASUREMENT FINDING: PILOT-0002 improved window isolation enough that the
limiting factor is now **meter granularity rather than contamination**.
Finer economic measurement requires a finer instrument — provider-side
cost telemetry, or a pilot deliberately large enough to move a whole
point. This conclusion is not to be repaired by interpretation.

## Qualitative findings

**T1 — a misleading surface symptom over a structural defect.** The task
read as client-side name drift. The cause was that
`server/governance/bridge-router.ts` exports exactly the namespaces the
client calls and **was never mounted**, while a different module
exporting the SAME SYMBOL NAME was mounted in its place. TypeScript's
nearest-name suggestion (`bridges`) was not the diagnosis; following it
exchanged six errors for six others before the real cause was found.
Mounting the orphaned router then made types flow into a call site that
had silently been `any`, exposing a further real mismatch.
Lesson recorded: Gravito must distinguish symptoms from underlying system
state, and preserve diagnosis rather than patch text.

**T4 — a false interface is worse than an `any`.** `IAutoRetrainingPipeline`
described what the router wished the pipeline were. Under it the code
accessed a **private** field, passed an argument the method does not
take, and **returned success for a config update the pipeline never
performed**. Fixed against real types; the endpoint now returns an honest
unsupported error.
Lesson recorded: artificially precise type declarations can conceal
behavioural falsity. Structural truth outranks type cleanliness.

**T5 — durable memory substituted for conversation.** Executed under
fresh context with no conversational memory. It reported the durable
artifacts sufficient, and specifically that the **commit messages of
T1-T4** settled its design decision before it opened a file. A strong
executed instance of the core thesis; NOT proof of long-run compounding
intelligence.

## Machinery defects exposed (recorded, not smoothed)

1. **T1 budget breach, initially concealed.** 672s against a 600s Light
   budget. The close-time gate REFUSED the close until the breach was
   declared. Evidence that enforcement catches operator behaviour, not
   merely blesses successful runs.
2. **Error-diff acceptance artifact.** The naive sorted-diff acceptance
   check counted 21 line-shifted copies of pre-existing errors as new
   regressions after a fix inserted lines. Corrected in-flight with a
   line-insensitive comparison. PILOT-0002 is NOT revised retroactively;
   the corrected reusable mechanism is post-pilot work.
3. **Frozen descriptions were wrong about three of five tasks.** T1, T4
   and T5's real causes differed from their frozen descriptions. The
   descriptions are deliberately NOT revised — the mismatch is itself
   evidence about how much diagnosis real repository work requires.

## What this pilot does and does not support

SUPPORTS: accepted repository work under governance; fresh-worker
continuity from durable state; refusal behaviour against its own
operator; measured task throughput; bounded meter movement.

DOES NOT ESTABLISH: Context Compiler savings (the compiler was INERT
throughout — this measured native Gravito WITHOUT treatment);
cross-provider superiority; customer ROI; any throughput multiple;
autonomous-company capability.
