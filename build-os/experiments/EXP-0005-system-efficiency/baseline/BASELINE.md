# Pre-existing regression baseline and behavioural candidate pool — attempt 2

One pass over the suite at the frozen seed, serving both registered purposes:
the behavioural/failing-test candidate pool, and the frozen pre-existing
regression baseline.

**Attempt 1 produced neither** — it stalled with zero test files completed and
no JSON written (`ATTEMPT-1-STALLED.md`). This is not a second run of something
that already produced numbers; it is the first run that produced any.

## Result

| | |
|---|---|
| seed | `2543c87`, verified before and after; HEAD unchanged |
| tree | clean before **and** clean after — the measurement mutated nothing |
| wall clock | **65.8 min** |
| files discovered | **614** |
| **files measured** | **614 — every one** |
| hung / runner_crash / not_reported / not_run | **0 / 0 / 0 / 0** |

| file verdict | count |
|---|---:|
| passed | 466 |
| failed | 142 |
| suite_error (failed to collect) | 6 |

| test verdict | count |
|---|---:|
| passed | 12,512 |
| **failed** | **853** |
| skipped / other | 375 |

**Zero unmeasured files is the number that matters.** Attempt 1's failure mode
was silence — a stall indistinguishable from slowness. Here every file has a
verdict, so nothing is being recorded as a pass because it was never looked at.

## Why sharded, and what that does and does not change

The registered plan was one whole-suite invocation. It hangs in this
environment: 900 s, 394 KB of repeated application-bootstrap logging, zero test
files reported. A single-file probe ran fine in 8.79 s, so the failure is
specific to whole-suite invocation, not to vitest and not to the repository.

Sharding changes **the invocation**. It does not change the scope (all 614
files), the seed, the definition of the baseline, or the rule that one pass
serves both purposes. Chunks run strictly serially — the whole-suite failure is
consistent with contention between concurrent bootstraps, so adding concurrency
here would risk measuring the harness instead of the repository.

## The harness defect this exposed, before it produced any result

The first sharded attempt's timeout **did not work**. A chunk ran 375 s against
a 300 s ceiling and was never killed.

`npx` execs a shell that execs node and then exits, so the real vitest process
is reparented to init. The kill hit a dead pid, and `close` never fired because
surviving workers held the stdio pipes open. The timeout was decorative — on a
sweep whose entire purpose is to bound hangs. It is the same class as
calibration attempt 1's misreading of elapsed time as duration.

Fixed by spawning `node vitest.mjs` directly and detached (one killable process
group), killing the **group** rather than the leader, and resolving on `exit`
rather than `close`. Proved with an 8 s ceiling against the chunk that had
previously survived: it fired at 8.0 s, killed the group, bisected
10 → 5 → 3+2 → 1, and named the isolated file.

The production ceiling of 600 s is then set **from evidence**: that same chunk
completes legitimately in 394.7 s, and the slowest chunk in the real sweep took
433.6 s. The original 300 s was firing on healthy work.

## Determinism re-check — 853 observed, 845 stable

`DEFECT-0013` records this tree as **6.26% non-deterministic**, and a single run
is not proof of a stable failure. A flaky test is unusable for **both**
registered purposes: it cannot anchor a regression baseline (it may "recover"
with no change), and it cannot be an admissible task (acceptance would not be
objectively determinable, which the selection rule requires).

So the 148 failing files were re-measured in a second independent pass at the
same seed. This is **not a second baseline** — it measures the stability of the
first.

| | run 1 | run 2 |
|---|---:|---:|
| failing tests | 853 | 847 |
| wall clock | 65.8 min (614 files) | 38.0 min (148 files) |

| outcome | count |
|---|---:|
| **failed in BOTH runs — stable** | **845** |
| failed only in run 1 (recovered) | 8 |
| failed only in run 2 (new) | 2 |
| **unstable** | **10 — 1.17%** |
| files whose whole verdict flipped `failed → passed` | 2 |

**845 stable failures are the frozen baseline and the behavioural pool.** The
10 unstable tests are excluded from both, and so is every test in the 8 files
that carried one — quarantined at file granularity because
`cognitive-architecture-router.test.ts` flipped in **both directions** (a
different test each way), which is a property of the file, not of one test.

Quarantined: `server/core-systems.test.ts`,
`server/deployment/tests/governance-integration.test.ts`,
`server/governance/cognitive-architecture-router.test.ts`,
`server/governance/fix-preview.test.ts`,
`server/governance/governance-persistence.test.ts`,
`server/mcp/mcp-health-probe.test.ts`,
`server/nervous-system/nervous-system.test.ts`,
`server/reviewer/autopilot.test.ts`.

All 6 `suite_error` files failed to collect in both runs, so those are stable
too.

### This measurement is ONE-SIDED, and the number must not be read as a tree flake rate

Only the **failing** subset was re-run. A test that **passed** in run 1 and
would fail in run 2 is **invisible** to this check. So 1.17% bounds the
instability of the *observed failures*; it does **not** bound the flake rate of
the repository, and it is not a refutation of `DEFECT-0013`'s 6.26%, which was
measured over a different population. Bounding the other direction would take a
second full pass over all 614 files, which has not been run.

## Honesty about the categories

`hung`, `runner_crash`, `not_reported` and `not_run` are not passes and not
failures — they are files the baseline could not measure, and a later run that
measures them is not thereby a regression. All four are **zero** here, which is
why this baseline can be used at all; had any been non-zero, the affected files
would have been excluded from the regression comparison by name rather than
counted.

## Artifacts

| file | what it is |
|---|---|
| `BASELINE.json` | per-file verdicts, per-test names, and every failure's first line |
| `sweep.log` | the run log: chunk timings, and the absence of any timeout or hang |
| `ATTEMPT-1-STALLED.md` | the stalled attempt, preserved rather than replaced |
