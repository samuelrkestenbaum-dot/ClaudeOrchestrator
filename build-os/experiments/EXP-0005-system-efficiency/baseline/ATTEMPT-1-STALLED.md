# Full-suite baseline, attempt 1 — STALLED

The single full-suite run was to serve two registered purposes at once: the
behavioural/failing-test candidate pool, and the frozen pre-existing regression
baseline. It delivered **neither**.

## What happened

| | |
|---|---|
| seed | `2543c87`, verified, tree clean |
| command | `vitest run --reporter=json --outputFile=… --reporter=default` |
| vitest | 3.2.4, node 22.22.2 |
| started | 2026-08-07T19:33:47Z |
| classified | 2026-08-07T19:58:50Z — **STALLED**, 900 s without output growth |
| **test files completed** | **0** |
| tests run | 0 |
| `vitest.json` | never written |

The 394 KB of captured output is **entirely application bootstrap logging** —
`integrated nervous system initialized (stub mode — subsystems pending)`
repeated — with no test file ever reported. The suite hung during
collection/setup, **before a single test executed**.

## Diagnosis: whole-suite invocation, not vitest and not the repository

A bounded single-file probe run immediately afterwards:

    server/governance/four-eyes-audit-kind.test.ts
    Test Files  1 passed (1)
    Tests       4 passed (4)
    Duration    8.79s

So vitest works, the toolchain works, and the repository's tests run. What does
not work is invoking the **whole suite at once** in this environment — module
side effects at collection time appear to block before any test starts.

## Why the watcher mattered

The run was **alive, idle and silent** — no CPU, no output growth. Without stall
detection this would have sat indefinitely and its elapsed time could later have
been misread as duration, which is exactly the mistake made once already in
calibration attempt 1. The bound classified it instead of waiting on it. Neither
bound killed the suite; they only labelled it.

## Consequences, stated rather than worked around

1. **No behavioural/failing-test candidate pool** from this source. Zero tests
   ran, so there are zero observed behavioural failures to draw tasks from.
2. **No frozen regression baseline** from this source. There is nothing to
   compare later task runs against.
3. The registered plan of *one run serving both purposes* did not survive
   contact with the fixture.

## What must NOT happen next

- **Do not silently substitute a static-only task set** (type errors, skips,
  suppressions, TODOs) and present it as the intended shape mix. The behavioural
  and failing-test shapes would be absent, and the benchmark would be narrower
  than described while appearing complete.
- **Do not regenerate a "cleaner" baseline later**, after task selection. The
  registered rule forbids it, and the reason is unchanged: a baseline chosen
  after seeing tasks can be chosen to suit them.
- **Do not fix the repository's suite bootstrap to make the benchmark run.**
  That would be a product change made to serve measurement, on a repository
  whose behaviour is the thing under test.

## Options, for an explicit decision

**A — per-file sharded baseline.** Run each test file separately with a per-file
timeout, aggregating into one baseline artifact. The probe shows this works.
Cost: ~500+ files at seconds-to-minutes each; hours of setup, and files that
hang individually get recorded as infrastructure failures rather than blocking
the rest. Yields both a genuine behavioural pool and a real regression baseline.

**B — narrower behavioural source.** Accept the static shapes plus whatever
behavioural signal is obtainable cheaply, and state plainly in the
preregistration that the task mix is thinner than the ten-shape target and why.

**C — bounded sample.** Shard a deterministic subset (e.g. every file under
`server/governance/`), and register the subset boundary as part of the baseline
definition rather than pretending it is the whole suite.

A is the strongest and the most expensive. C is the honest middle. B is the
weakest and should only be chosen deliberately, not by default.

**Readiness is unchanged at 3/8.** A stalled baseline closes nothing.
