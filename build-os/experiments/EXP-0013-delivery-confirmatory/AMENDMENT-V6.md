# EXP-0013 AMENDMENT v6 — surgical launch-critical review corrections

An owner-authorized skeptical code review of 607c0bd..4adf8ba (prioritizing
the four newest release-audit/fix commits) confirmed three findings. Fixes
are minimal and disclosed; v1 verifies live; v2–v5 manifests are preserved
byte-identically as history inside FREEZE-MANIFEST-v6.json.

## Findings and fixes

**F1 (launch-blocking for spend, controller.mjs / missing modules): the
measured path had no frozen compiler invocation or entry point — and the
gap was FAIL-OPEN.** `runMeasured` takes `oracleFor` as a parameter and
nothing committed supplied it; a spend-time run would have needed ad-hoc
unfrozen glue (the exact defect class of the v3 "distillation
unimplemented" finding). Worse, `acceptance()` on a null/absent compile
output parses as ZERO errors, i.e. a crashed compiler could read as a
clean, accepted run (reproduced in tests/exp0013_review_tests.sh W2).
Fixed:
- `harness/oracle-runner.mjs`: the real compile runs through the typed
  exec registry (one new strict bash shape), FAILS CLOSED — tsc exit 0
  (clean) and exit 2 (with diagnostics) are the only valid outcomes;
  exit 1/unknown/refusal/timeout/exit-2-without-diagnostics throw a typed
  ORACLE_RUN_FAILED; the seed diff comes from registry-gated git.
- controller: an oracle-runner throw is recorded honestly — seeds take the
  frozen seed-failure path; measured cells become infrastructure-invalid
  under `terminal_reason=oracle_failed` (the analysis reliability gate
  already handles that vocabulary).
- `harness/launch-measured.mjs`: THE frozen measured entry. `run` verifies
  freeze + both sealed commitments, validates the owner authorization,
  acquires the sole provider transport, and drives `runMeasured` with the
  real oracle runner. `print-auth-template` emits the exact authorization
  skeleton with the canonical 10 cells and 6 prompt digests computed from
  frozen bytes — the owner cannot be expected to hand-compute digests, and
  the template is indelibly `spend_authorized:false`.

**F2 (material, escrow-cli.mjs): three secret-entry hazards, all
reproduced failing-first.** (a) stdin EOF let the event loop drain and the
process EXIT 0 as a silent no-op "success"; now every pending prompt
resolves null → typed STDIN_EOF refusal. (b) Ctrl-C during the raw-mode
read could leave the owner's terminal in raw mode; now restored explicitly
on the Ctrl-C path and by a process-exit guard. (c) A live escrow artifact
was silently overwritten and writes were non-atomic; now: overwrite is a
typed refusal, creation writes tmp-then-rename. Policy per review: piped
secrets are REFUSED in real mode (shell-history leak channel); the
explicit env-gated adapter exists for synthetic tests only.

**F3 (material-nonblocking, oracle.mjs — pinned, not changed): out-of-root
aliasing.** A message containing an out-of-root absolute path whose tail
includes a known tree dir (e.g. `/opt/OTHER/server/util`) normalizes to
`<TREE>/server/util`. A masked regression via this alias requires an
identical file, TS code, and message tail — an implausible coincidence
further covered by diff adjudication. Behavior is PINNED by test (W1)
with the bare-path-with-spaces limitation likewise pinned; the residual
risk is documented rather than hidden. No oracle code change (the fix
would require knowing all future roots, which is impossible).

## Review results with no change required

Two-root baseline regeneration (fresh archives, real tsc): 781/781
identities, semantic digests identical to the committed baseline, zero
regressions — no nondeterminism, no environment or compiler drift.
Install-closure determinism: `gravito init` into two disposable targets
yields byte-identical payloads (excluding the declared per-target identity
stamps) — the frozen sources are the effective installed bytes. Scanner
canary detection proven in disposable history. Capability boundary: no new
import paths; launch-measured is the single sanctioned acquirer of the
call site; measured call counter still zero.

## Unchanged

Preregistered design, corpus, commitments, analysis, sealed experiments,
v1 freeze, all prior manifests as history. Measured-run SEMANTICS changed
only by F1's addition of the frozen runner/entry (previously absent, not
different) and the fail-closed oracle path.
