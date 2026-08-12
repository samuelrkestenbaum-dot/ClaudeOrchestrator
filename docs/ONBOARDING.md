# ONBOARDING — Gravito on a real repository in five commands

You are a competent engineer. Nothing below asks you to take anything on
trust: every claim names the command that proves it, and the whole golden
path below is EXECUTED VERBATIM by `tests/doc_drift_tests.sh` — if this page
drifts from the product, that suite goes red before you ever read a stale
instruction.

**What this is.** Gravito installs a control layer into a git repository so
that agent work there runs under an owner contract (`gravito.goal`): a stated
goal, authority bounds, budgets, an acceptance check, and a stop that always
works. Enforcement is at tool level and fails closed — a lapsed or
over-budget contract blocks mutations *before* side effects and leaves a
refusal receipt you can read.

**What it is not.** It is not a measured speedup. This product has **no
performance claim you can currently check**, and no such claim is made
anywhere on the golden path. Whole-system validation is a separate,
preregistered program (`build-os/experiments/`); until it reports, treat any
multiplier you hear as contradicting the repo it describes.

**What is NOT enforced (read this before trusting the gate).**
- A bare human shell in the target repo runs no hooks — the gate binds agent
  sessions, not `rm -rf` typed by a person.
- MCP tools are gated default-closed via an allowlist
  (`.claude/hooks/mcp-readonly-allowlist.txt`): undeclared MCP tools are
  treated as mutations. The allowlist itself is the trust boundary.
- Spend is metered for `gravito run` workers only. Your own interactive
  sessions are not metered, and the status surface says so instead of
  inventing numbers.

---

## The golden path

Prerequisites: `git`, `bash`, `python3`, and the `claude` CLI on PATH (the
worker step dispatches one headless Claude session). `$GRAVITO` is this
repository's checkout; `$REPO` is the target repository you want to work on.

```bash
# gravito-golden-path — executed verbatim by tests/doc_drift_tests.sh
# 1. Eligibility, read-only. Refuses non-git dirs and obvious secret files.
$GRAVITO/bin/gravito preflight "$REPO"

# 2. Install: deterministic, idempotent, receipted. Re-running converges.
$GRAVITO/bin/gravito init "$REPO"

# 3. Contract: one file states goal, authority, budgets, acceptance, window.
#    Copy the template, edit it, install it. Invalid contracts refuse here.
$GRAVITO/bin/gravito goal "$GRAVITO/templates/gravito.goal.example" "$REPO"

# 4. Verify the whole install + contract in one page (wiring, goal, ledger).
$GRAVITO/bin/gravito diagnose "$REPO"

# 5. Preview the dispatch gate without spending anything.
$GRAVITO/bin/gravito run "$REPO" --dry-run
```

From here the real loop is three verbs, each safe to run at any time:

- `gravito run "$REPO"` — gate-checks the contract, dispatches ONE worker
  session, meters its spend into the committed ledger, sweeps incidental
  tool residue reversibly. Refuses to dispatch when the window is lapsed,
  not yet open, or the budget is spent — with the owner's next action named.
- `gravito review "$REPO"` — shows the diff and runs the contract's
  `acceptance_cmd` (PASS/FAIL), or shows the human acceptance text.
- `gravito stop "$REPO"` — halts at a safe boundary; state is durable;
  resume is just `run` again.

And three exits, none of which touch your product files:

- `gravito rollback "$REPO"` — restore engine files to the previous manifest.
- `gravito uninstall "$REPO" --force` — remove the engine, KEEP your data.
- `gravito purge "$REPO" --force` — remove ALL Gravito state, including the
  marked `.gitignore` block and `package.json` script the installer added;
  installer-touched files are restored byte-identical (test-proven).

Destructive verbs default to dry-run; `--force` is always explicit.

## What runs before and after your worker (translated, no math)

`gravito run` checks system health first (`gravito health` shows the same
facts any time): a genuinely broken substrate — unreadable repository,
corrupt spend ledger, an installed contract with no enforcer — refuses
before anything happens; lesser problems (a stale worker record, low disk)
are named and narrow what runs, never a vague universal stop. It then
computes which actions are actually available right now and dispatches only
if running is one of them; every attempt leaves an ordered trace receipt.
Optionally, `gravito predict PASS` before a run records your honest
forecast; `gravito review` then records what actually happened next to it —
if you didn't forecast, it says so rather than inventing one. Review also
prints a few program-health numbers; they are informational only and never
gate anything.

## When something looks wrong

`gravito diagnose "$REPO"` is the support surface: namespace verdict,
missing engine files by name, tool-gate wiring (wired/UNWIRED per matcher),
goal window and budget status, ledger, last refusals, residue quarantine.
Attach the written bundle (`build-os/receipts/diagnose-*.txt`) to any bug
report. `gravito status "$REPO"` is the shorter everyday view.

## Where things live in the target repo

`gravito.goal` (the contract) · `build-os/memory/` (project memory + spend
ledger) · `build-os/receipts/` (manifests, run streams, refusals, diagnose
bundles) · `build-os/residue/` (quarantined incidental files, reversible) ·
`.claude/` (engine: hooks, agents, settings). Full data/retention/removal
semantics: `docs/DATA-BOUNDARIES.md`.

## Proof, not vibes

Run the suites yourself from this repository:
`tests/lifecycle_tests.sh` · `tests/goal_enforcement_tests.sh` ·
`tests/cross_repo_isolation_tests.sh` · `tests/doc_drift_tests.sh`.
Each prints exact pass/fail counts and exercises disposable fixtures only.
The deeper orchestrator machinery (lanes, packets, gates) is documented in
`docs/DEMO.md` and `CLAUDE.md` — you do not need any of it to use the
golden path.
