# Common absolute timeout — FROZEN

Derived per the registered rule, **before task selection**, from admissible
calibration runs only.

## Admissibility

Calibration attempt 2, three Gravito-arm runs. Every one satisfied the full
conjunction — isolated session proven from the child's own stream, valid
terminal state, `terminal_reason: completed`, `is_error: false`, provider result
event observed, elapsed derived from process evidence, no controller leakage.

| run | session id | elapsed s | terminal | isolated | admissible |
|---|---|---:|---|---|---|
| E1 | `5e970721…` | 1070.21 | completed | yes | **yes** |
| E3 | `15a6963b…` | 659.10 | completed | yes | **yes** |
| E5 | `1f51950d…` | 648.63 | completed | yes | **yes** |

Three of three admitted. Attempt 1 remains permanently void and contributes
nothing.

## Distributions

| distribution | n | min | median | max | spread |
|---|---:|---:|---:|---:|---:|
| Gravito (E1, E3, E5) | 3 | 648.6 | 659.1 | 1070.2 | **421.6** |
| native, same three | 3 | 849.4 | 918.8 | 1009.0 | 159.7 |
| native, all five (EXP-0004 arm A) | 5 | 849.4 | 991.0 | **1249.4** | 400.0 |

## The ceiling

    COMMON ABSOLUTE TIMEOUT = 5400 s (90 minutes), both arms

**Derivation.** The rule requires one common ceiling from the *slower or wider*
distribution with generous headroom. Gravito is the **wider** (421.6 s vs
400.0 s); native holds the **slowest single run** (1249.4 s). Taking the slowest
run observed anywhere and multiplying by four gives 4998 s, rounded up to
**5400 s**.

A run must take **four times longer than the slowest thing ever measured** before
it is cut. That is a runaway guard, which is what the rule asks for.

| | headroom |
|---|---|
| over Gravito's max | **5.05×** |
| over native's max | **4.32×** |
| worst observed utilisation | **23.1%** of the ceiling |

**This is not an optimization target.** It exists to stop a hung run, and no arm
is expected to approach it. Truncation rate per arm is reported during EXP-0005
as a first-class outcome.

## What these numbers do NOT establish

Stated because the temptation is obvious and the numbers look inviting.

On the same three workloads the Gravito median (659.1 s) is **lower** than the
native median (918.8 s). **That is not evidence of anything**, and it is not
reported as a system-efficiency finding:

- **n = 3.** Three runs per side is not a distribution.
- **Not a matched comparison.** The native figures come from EXP-0004's arm A —
  a different work tree, a sparse-excluded substrate, different sessions, a
  different machine state, hours apart. Nothing was paired, ordered or blinded.
- **Different purpose.** These runs were measured for *duration only*. No
  acceptance was adjudicated, no tokens were compared, no work product was
  scored. A fast run that produced nothing useful would look identical here.
- **The controller was not perfectly quiet.** Diagnostic shells ran at ~9% CPU
  during parts of the window.
- **Wrong metric entirely.** EXP-0005's question is accepted outcomes per
  uncached token. Elapsed time is not that, and is not a proxy for it.

Calibration observes the system. It does not measure it, and it does not
license a claim in either direction.

## Routing-gate overhead stays

The Gravito arm hit `MUTATION BLOCKED — no OPEN routing receipt exists` and spent
turns obtaining authority before acting. That gate is **not** disabled,
bypassed, pre-opened or tuned. Time spent getting permission belongs to the
system under test, and EXP-0005 charges it to the Gravito arm.

## Status

**Readiness item: common timeout ceiling — CLOSED.** Frozen at 5400 s before any
task was selected. Task selection is now unblocked on this item alone; the
remaining readiness items are untouched.
