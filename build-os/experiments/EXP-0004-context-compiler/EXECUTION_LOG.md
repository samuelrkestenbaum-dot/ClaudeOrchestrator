# EXP-0004 — execution log

Written as the run proceeds, not reconstructed afterwards. It records what the
harness did, what broke, and what was seen before it broke. Nothing here
discloses the sealed X/Y mapping.

## Fixture, stated once

Both arms run as a fresh headless `claude -p` session (`claude-fable-5`) with
identical permissions, identical appended operating instruction, and identical
work tree. The **only** difference between arms is which file is handed over as
the prompt: arm A receives the task definition; arm B receives the rendered
capsule verbatim.

The work tree is a detached clone of `empathiq-website` at the seed, with
`.claude/` and `CLAUDE.md` **sparse-excluded**. That exclusion is load-bearing
and applies to both arms: the natively installed Build OS injects a capability
inventory and a routing reminder at SessionStart and on every prompt, which is
broad context. Left on, it would have made every arm B start with the capsule
**and** an injected payload — `result confounded` on all five pairs, by
AMENDMENT 2's mechanical check, before a single measurement was worth reading.

Baseline is measured **inside each arm at that arm's start**, because criterion
(b) is "strictly below the count at task start". It is never assumed from the
freeze.

## Fixture conditions found during execution — matched, and disclosed anyway

These were discovered while the pairs ran. Each is **identical in both arms**,
so none of them biases the comparison. Each is recorded because an undisclosed
constant is indistinguishable, in the numbers, from an unexplained one.

- **Serena's MCP server and a TypeScript language server launch inside every
  arm session.** They come from user scope, not from the work tree, so the
  sparse-exclusion of `.claude/` does not remove them. Consequence worth naming:
  every arm — including arm B — has a semantic code-navigation tool available,
  which changes what "avoidable exploration" costs. The capsule is therefore
  being compared against a baseline that is *better equipped* than a plain
  file-reading agent, not worse.
- **A fixed CLI system-prompt floor.** A trivial headless probe that made no
  edits still spent ~29,400 cache-creation tokens. That floor is paid by both
  arms and sets the scale against which any compression has to be read.
- **A second model appears in every run.** `modelUsage` shows
  `claude-haiku-4-5` alongside `claude-fable-5` — the CLI's own internal
  small-model use. It is present in both arms and is included in the token
  totals as reported, not subtracted.
- **Execution is strictly sequential.** More than half of each measured window
  is *local* CPU (E1's arm A: 402 s of API time inside an 849 s window) on a
  4-core machine. Running pairs concurrently would have made elapsed time a
  function of scheduler contention, and elapsed time is a registered metric.

## Attempt 1 of pair E1 — VOID (harness defect, no treatment delivered to arm B)

### Defect 1 — the prompt was passed as a command-line argument

Arm B died before its session existed:

    /usr/bin/timeout: Argument list too long        (exit 126)

Linux caps a *single* argument at `MAX_ARG_STRLEN` = 131,072 bytes. Three of
the five arm-B capsules exceed it:

| task | arm-B prompt bytes | vs 131,072 |
|---|---:|---|
| E1 | 133,034 | **over** |
| E2 | 175,288 | **over** |
| E3 | 76,979 | ok |
| E4 | 185,598 | **over** |
| E5 | 94,533 | ok |

Left undetected this would have produced three empty arm-B runs out of five,
each of which *looks* like a completed arm: exit code captured, tree clean,
oracle willing to score it. Arm B's record for E1 read "0 files touched, 15
cluster errors remaining" — a treatment that was never administered would have
been scored as a treatment that failed.

**Fix:** the prompt is delivered on **stdin**, in **both** arms, so the
mechanism cannot vary by arm or by prompt size. Verified against the CLI before
re-running.

### Defect 2 — criterion (d) was evaluated with no baseline

The frozen criterion is *"any test covering a touched file still passes at **its
measured baseline**"*. The first oracle measured no baseline: it ran the
covering tests after the arm and failed the criterion if anything failed. On
E1's covering set, **4 tests already fail at the seed**. Every one of them would
have been charged to the arm.

This is the PILOT-0002 false-positive shape in a new disguise — there, a naive
sorted diff reported 21 "new" errors that were line-shifted pre-existing ones.
The lesson transferred to error counting and was not transferred to test
counting.

The selection rule was also far too loose. It matched a test file if the touched
file's **basename** appeared anywhere in it inside quotes or after a slash;
basenames like `index`, `router` and `guardian` are everywhere, so a six-file
change selected **45 test files and 409 seconds** of vitest.

**Fix, both halves:**

- Selection is now: same-directory same-stem sibling, **or** a relative
  `import` / `require` / `vi.mock` specifier that *resolves* to the touched
  path. On the same six-file change that selects **8 files in 25 seconds**, and
  each carries its reason (`sibling of …` / `imports …`).
- The baseline is measured per test, at the seed, in a **pristine clone no arm
  touches**, cached across arms, from vitest's JSON reporter. Criterion (d)
  fails only when a test that **passed at the seed** fails after the arm.
  Tests already failing at the seed are reported separately as
  `failing_at_baseline_too` and charged to nobody.

### What was observed before the fix, disclosed rather than buried

Arm A of attempt 1 ran to completion and its numbers were seen. They are
recorded here so that a re-run cannot be mistaken for a first look:

- 58 turns, ~912 s of API time, `end_turn`, no error
- uncached 104,516 tokens (in 86 + cache-creation 104,430); cache read
  3,721,789; output 35,078
- tsc 754 → 736; cluster 15 → 0; 0 new errors line-insensitively; 6 files
  touched; 0 `any`-casts or suppressions

Its criterion-(d) verdict from attempt 1 is **void, not "fail"** — it was
produced by the defective oracle described above.

### Disposition, and why it is not the "never repaired and re-run" case

AMENDMENT 2 says a pair whose **arm B starts with broad context AND the
capsule** is registered `result confounded` and *"is not silently repaired and
re-run"*. That rule governs a **contaminated treatment**. This is not that: arm
B's session never started, so no treatment was delivered and no arm-B
measurement exists to contaminate. The distinction is named here rather than
assumed.

The whole pair is re-run under the corrected harness, both arms, so the two
arms share one delivery mechanism and one oracle. Attempt 1's artifacts are
kept at `pairs-out/E1-attempt1/` and are **not** admitted to the aggregate.

Nothing was changed in response to what was seen: not the seed, not the task
set, not the capsule budget, not the acceptance criteria, not the arm order.
The two changes are a prompt-delivery mechanism and an oracle that measures the
baseline its own criterion names.

## Attempt 1 of pairs E4 and E5 — VOID (concurrency, on operator instruction)

E1, E2 and E3 ran strictly sequentially and each of their four arms had the
machine to itself. The operator then directed that the two remaining pairs be
run concurrently to finish sooner, having been told in advance that this would
contaminate elapsed time — a registered metric — on those pairs. E5 was launched
on a second work tree, with its own baseline clone and its own test-baseline
cache so the two oracles could not race.

### What actually overlapped — measured, not assumed

Windows are first-to-last stream timestamp, UTC.

| arm | window | contention |
|---|---|---|
| E1.A | 23:20:31 – 23:34:26 | alone |
| E1.B | 23:39:35 – 23:55:06 | alone |
| E2.B | 00:02:44 – 00:21:14 | alone |
| E2.A | 00:31:30 – 00:47:48 | alone |
| E3.A | 00:52:45 – 01:09:23 | alone |
| E3.B | 01:13:35 – 01:27:09 | alone |
| E4.B | 01:31:00 – 01:52:13 | alone (E5 launched 01:53:18, after this closed) |
| E5.A | 01:55:39 – 01:58:37 | against E4's post-arm-B `tsc`/vitest |
| E4.A | 01:58:47 – 02:28:39 | against all of E5.B **and TIMED OUT** |
| E5.B | 02:02:46 – 02:11:24 | entirely inside E4.A's window |

The prediction made when the concurrency was authorised was wrong in its
specifics: E4.A and E5.A were expected to collide and did not — they missed
each other by **ten seconds**. What collided was E5.B, wholly inside E4.A.

### The two failures were worse than degraded timing

- **E4.A was truncated, not slowed.** `terminal_reason: aborted_tools`,
  `is_error: true`, killed at the 1800 s ceiling after 73 turns and 23 edits
  across 11 files. A truncated arm has no comparable token count and no
  comparable work product; the loss is not confined to the clock.
- **E5.A never performed the task.** Nine turns, zero files changed. It put a
  `tsc` in the background, registered a `Monitor`, stated it would continue when
  notified, and the session ended — because a headless `-p` run has nothing that
  can wake it. Its 195 s and its small token count describe a no-op. Reported as
  efficiency they would be a lie.

Neither failure is a property of the context condition. One is CPU contention
the experiment introduced; the other is a limitation of the execution fixture
that could have struck either arm and happened to strike this one.

### Disposition — both pairs re-run WHOLE, uncontended

Same precedent as E1 attempt 1, and the same reasoning: the contamination is
environmental and fixture-borne, not treatment-borne. Both arms of each pair are
re-run so no arm is replaced in isolation. **Nothing is changed** — same
timeout, same prompts, same budgets, same oracle, same arm order. If E4.A
reaches the ceiling again with the machine to itself, that is a legitimate
result and it stays in.

Disclosed, because it is the fact that makes the re-run defensible rather than
self-serving: **both discarded attempts favoured the compiled condition** — in
E4 the compiled arm completed while the other timed out, and in E5 the compiled
arm succeeded while the other did nothing. Re-running therefore runs *against* a
flattering result, not toward one. Attempt 1's artifacts are kept at
`pairs-out/E4-attempt1/` and `pairs-out/E5-attempt1/` and are not admitted to
the aggregate.

### The re-run vindicated the diagnosis

Uncontended, **E4.A completed in 1249 s over 91 turns** — comfortably inside the
same 1800 s ceiling it had hit before. The timeout was contention, not the task.
E5.A likewise ran normally (34 turns, 540 s, cluster resolved) instead of parking
on a background monitor. Nothing about either arm was changed to achieve that.

### One more fixture leak, found here

The arm sessions could see **this session's task list** — E5.A said so in its
own words, that the task list "belongs to a different workstream and isn't
relevant". It is identical in both arms, so it does not bias the comparison, and
AMENDMENT 2's mechanical check still passes because that check is on prompt
bytes. It is still context that has no business inside an arm whose registered
treatment is "the capsule and nothing else", and it is recorded as a known
imperfection of the substitution rather than left to be discovered later.

## Attempt 2 of pair E5 — VOID, and a STOPPING RULE committed before attempt 3

E5's arm B terminated `aborted_streaming` with `is_error: true`, cut mid-`Bash`
at 436 s — nowhere near the 1800 s ceiling, no stderr, an infrastructure stream
abort.

Its **work product is complete**: the cluster is fully resolved, no new errors,
no regressions, no suppressions, all five acceptance criteria pass. What is not
complete is its **economics**. The session was cut while verifying, so its
elapsed time and token totals are **lower bounds, not measurements** — and it
was the faster side of that pair. Admitting a lower-bounded winner biases the
comparison in precisely the direction that flatters it.

The rule applied is the one already applied to E4.A, and it is applied without
reference to which condition it helps:

> **An arm that ends with `is_error: true` did not complete its measured window,
> and its economics are not admissible.**

### The stopping rule, committed BEFORE attempt 3 runs

Three attempts at one pair is the point where "re-run the infrastructure
failure" starts to look like "run until the number is usable". So the stop is
fixed in advance, in writing, before the attempt:

> **E5 gets exactly one more whole-pair attempt.** If attempt 3 also ends with
> an `is_error: true` arm, E5 is EXCLUDED. The aggregate then runs on four
> pairs, takes the AMENDMENT 3.5 minimum-n penalty, and the verdict is whatever
> the registered rules return on four — including `inconclusive`. No fourth
> attempt, whatever the reason, and no relaxation of the rule above to rescue
> a pair.

Every attempt is retained (`pairs-out/E5-attempt1/`, `E5-attempt2/`) and none
is silently dropped. The escalating disclosure is itself part of the result:
three attempts at one pair is a fact about this fixture's reliability, and it
belongs in the limitations, not in a footnote.

## Attempt 3 of pair E5 — CLEAN. The stopping rule was not needed.

Both arms `completed`, `is_error: false`, on an otherwise idle machine. The
cluster is resolved on both sides, no new errors, no regressions, no
suppressions. E5 is admitted, and the pre-committed stopping rule expired
unused rather than being quietly relaxed.

**The set is five clean pairs.** Ten arms, every one `terminal_reason:
completed` and `is_error: false`, every one measured with the machine to
itself.

## What the run cost in attempts, stated plainly

| pair | attempts | why the earlier ones were void |
|---|---:|---|
| E1 | 2 | arm B never started — prompt exceeded `MAX_ARG_STRLEN` |
| E2 | 1 | — |
| E3 | 1 | — |
| E4 | 2 | arm A timed out under CPU contention introduced by concurrency |
| E5 | 3 | (1) contention + a background-monitor park that did no work; (2) `aborted_streaming` mid-tool-use |

Fourteen arm executions produced ten admitted measurements. That ratio is a
property of THIS FIXTURE, not of the thesis, and it belongs in the limitations:
a harness that loses four arms in fourteen to argument limits, CPU contention,
a headless-mode monitor dead-end and a stream abort is not yet an instrument
anyone should run unattended.

Every discarded attempt is retained under `pairs-out/*-attempt*/`. None was
dropped silently, and the one directional fact that could have made a re-run
self-serving — that both E4/E5 attempt-1 failures favoured the compiled
condition — is recorded above rather than omitted.
