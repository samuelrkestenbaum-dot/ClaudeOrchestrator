# gravito_test_harness_stdin_hang_a — the documented test command no longer hangs on an interactive terminal

- **Date:** 2026-07-30
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `5b956c0` (parent of `641527f`; merge-base with `origin/claude/add-build-os` = `7ef50e8`)

`tests/build_os_tests.sh` — **the exact command the README advertises as the repo
suite command** — blocked forever on an interactive terminal, with no output
explaining why. That is what a customer on a TTY hit.

## The defect

Section 2 ran the SessionStart hook with the **caller's stdin inherited**:

```
OUT="$(HOME=... CLAUDE_PROJECT_DIR=... bash "$HOOK" 2>/dev/null)"
```

Claude Code delivers a JSON payload on stdin and then **closes it**, so the hook
reads stdin to EOF (`hook-once.sh`: `payload="$(cat)"`). With no payload supplied
the test inherited the terminal, **which never reaches EOF**, so the suite
blocked at section 2.

**Diagnosis: hook-correct / test-wrong.** The hook's stdin contract is right and
is **unchanged**. The test was wrong.

## The fix

Feed the hook the realistic SessionStart JSON payload Claude Code actually
sends, matching the convention already used by the dedup tests at the
`DUPE_INPUT` sites. `TMPDIR` is isolated to `$WORK` so the hook-once guard starts
fresh each run and the suite stays deterministic on repeat runs. The payload was
chosen over `< /dev/null` because `/dev/null` exercises the **fail-open branch
that Claude Code never takes**.

## The pin (section 27)

- **(a) Behavioural** — each stdin-reading hook (`session-start-build-os.sh` and
  `prompt-router.sh`, which has the same `PAYLOAD="$(cat ...)"` hang mode) must
  complete while stdin stays **open and idle**: a FIFO with the write end held
  open, under `timeout`. It hardcodes its own payload, so it proves the
  **mechanism** — it cannot fail because of a regression at any particular
  invocation site.
- **(b) Static** — the regression detector. It scans the suite for every hook
  invocation in all three forms used (`"$HOOK"`, `"$PROMPT_HOOK"`, and a literal
  `.claude/hooks/*.sh` path), joining backslash/pipe continuations first because
  several sites carry the payload pipe on a preceding line. **All 10 executable
  sites are covered** (3 SessionStart + 7 UserPromptSubmit). An earlier draft
  grepped only `bash "$HOOK"` and saw **3**. A **minimum-site-count vacuity
  guard** (`PIN_MIN_SITES=10`, verified present in the suite this session) means
  that if a rename makes the pattern stop matching, the pin **fails** instead of
  passing green on zero sites.

## The known limit, stated where a maintainer will read it

On a TTY, a re-broken section-2 call hangs **at section 2** and section 27 is
never reached. Check (b) is the protection and it fires in CI / any non-TTY run.
Section 27 stops the bug being re-introduced; it does **not** rescue a run that
is already blocked.

## Commits

- `641527f` fix(tests): stop the suite hanging on an interactive terminal
  (1 file changed, 115 insertions, 1 deletion — tests only)

## QA proof

Both directions were re-measured **in this session**, under the same
stdin-held-open-and-idle condition (`sleep N |` supplies a pipe that stays open
and never reaches EOF, which is the terminal's behaviour), each bounded by
`timeout`:

- **Before** — the pre-fix tree extracted with `git archive 5b956c0`, run with
  stdin held open under `timeout 45`: **exit 124** (timed out), last output line
  `== 2. SessionStart detector: ... ==`. The hang is reproduced at exactly the
  section named above.
- **After** — the fixed tree at `641527f`, run with stdin held open under
  `timeout 110`: **exit 0**, `==== RESULT: 281 passed, 0 failed ====`, including
  `CHAINED: 61 passed, 0 failed`.
- Suite: `bash tests/build_os_tests.sh` → **281 passed, 0 failed** (exit 0).
- Regression: `./build-os/maintenance/run-tests.sh` → **144 passed, 0 failed**
  (exit 0). Unchanged by this packet.
- Commit-1 isolation: this packet is a **single commit** touching only
  `tests/build_os_tests.sh`. Its green-in-isolation result is the suite result
  above, since the commit *is* the whole packet.
- Safety grep: no push / merge / deploy / publish; no secrets touched. Local
  commit only.
- UI smoke: N/A.

**Red-driven** (as recorded in the commit message; **not re-driven in this
session** — recorded here as unverified from this session's evidence): blinding
the scanner fails on the vacuity guard (0 < 10); stripping the payload pipe from
a `"$PROMPT_HOOK"` site and from a literal-path site each fails naming the exact
line. All bounded; none hung.

**Sweep** (also from the commit message, not re-run here):
`tests/build_os_maintenance_tests.sh`, `build-os/maintenance/run-tests.sh` and
the installers were swept on logically joined lines — no stdin-inheriting hook
invocation. Both maintenance suites already completed under open stdin and are
unchanged.

## Review

- **Verdict: pass.**
- **Codex second-eyes: not available.** Checked and unavailable on **every**
  pass. This verdict — like every reviewer verdict in this work — is
  **single-model** and has **no** independent second-model corroboration.
- Product Trajectory Check: the advertised entry point is the first thing a new
  user runs. A suite that hangs there costs more trust than the feature it was
  proving.

## Residue

- **The limit above is real and accepted:** a future re-break of section 2 is
  caught by check (b) in any non-TTY run, but a TTY user still hangs before
  section 27 executes.
- Stdin-inheriting invocations are pinned in `tests/build_os_tests.sh` only. The
  other suites were swept once and found clean; they are **not** continuously
  pinned.
- **Single-platform proof** — measured on one Linux machine only (carried).
- No push / merge / deploy; no secrets touched.
