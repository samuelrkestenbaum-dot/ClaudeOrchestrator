# R0 evidence report (running; per-packet executed evidence)

## P0 — evidence refresh (2026-08-12, post-EXP-0011-termination)
- Authority code lives in build-os/tools/authority-envelope.sh (advisory
  validator) + tests/authority_envelope_tests.sh; install surface =
  install-global.sh / install-project.sh / init-build-os.sh /
  connect-project.sh; memory scopes = project build-os/ + user ~/build-os
  (session-start hook reads both). #40 confirmed: no Repository Core
  worktree exists in this environment — Core-resident work is out of reach.

## PKT-R0-2 (#25) — VERDICT: STALE AS STATED; enforcement exists, proven now
Executed evidence (this session, fresh fixtures in scratchpad):
- authority_envelope_tests.sh: **126 passed, 0 failed**.
- Functional probes (BUILD_OS_NOW=2026-08-12, synthetic store):
  lapsed lease → `envelope: LAPSED … contributes no grant` (NOT
  WITHIN-LICENCE); not-yet lease → NOT-YET-LIVE, no grant; malformed
  `starts: 2026-13-45` → REFUSED, named; malformed clock 2026-99-99 →
  REFUSED, no fallback-to-today; absent registry → REFUSED ("an absent
  census is not a permissive one"); unknown control → UNCOMPOSABLE.
Remaining deltas (moved, not dropped):
- The validator is ADVISORY (exit 0 on REFUSED by declared policy). Fail-
  closed enforcement belongs to the CONSUMER: PKT-R0-4's goal contract
  treats REFUSED/LAPSED/NOT-YET/UNCOMPOSABLE as no-grant and halts.
- Wrong-project leases = namespace scoping → PKT-R0-1.
- Replay of a revoked (deleted) record: mitigated by the store being
  git-tracked per repo; namespace check adds the project dimension.
Task #25 closes as stale-with-deltas; deltas tracked in packets 1 and 4.

## PKT-R0-1 — cross-repo isolation: EXECUTED, 14/14 (commit 090ed5c)
Deterministic namespace stamps (remote-URL/path sha256-16); planted sentinel
in repo A never reached repo B's session output, tree, or temp-HOME user
scope; carried-in foreign store QUARANTINED default-closed, evidence left in
place; un-stamped store ADOPTED with receipt, same id re-derived; re-scaffold
deterministic. Orchestrator repo itself adopted (79964536d91d3a1e).

## PKT-R0-3 — deterministic lifecycle: EXECUTED, 22/22 (commits b0c3031, bab92e4)
init idempotent (manifest hashes converge), preflight refuses non-git,
interruption recovery (half-deleted engine restored), destructive verbs
dry-run by default, uninstall keeps user data, purge removes all Gravito
state and never product files. Defect caught by the suite and fixed: the
installer did not ship goal-check.sh to targets (targets could not gate).
Test-harness fix: hooks consume a stdin payload; tests close stdin as the
runtime does (a bare cat hung an open pipe).

## PKT-R0-4 — gravito.goal: EXECUTED (commit ee30ecd)
Validator: missing field / non-numeric budget / unreal date → INVALID
(exit 1); unreadable clock refused, no fallback. Gate fail-closed: LAPSED
or NOT-YET-LIVE window → HALT exit 2; over-budget ledger → HALT exit 3;
each names the owner's next
action. Session-start announces a binding GOAL HALT (lifecycle test 4).
Hard tool-level enforcement is R1 scope and is NOT claimed.

## PKT-R0-5 — status surface: EXECUTED (in lifecycle tests §5)
namespace verdict, goal + live window/budget line, state, workers,
manifests, receipts, exact stop/rollback commands; unmetered values
declared "NOT METERED in R0", never invented.

## PKT-R0-6 — docs/DATA-BOUNDARIES.md (commit bab92e4)
Provider calls are the only egress; telemetry OFF (no sender exists); run
streams contain worker transcripts (secrets caveat named); removal maps to
tested verbs; experimental/intelligence features OFF by default.

## R0 EXIT — the five-step golden path on a DISPOSABLE second repo: PASSED
init (receipt install-manifest-20260812T181607Z) → goal (validated,
installed) → run (gate OPEN; ONE real worker session appended the exact
line; metered 223,992 tokens / $0.3349 / 1 min into spend-ledger.jsonl) →
review (acceptance_cmd PASS) → stop (safe, durable) + rollback (engine
matches previous manifest). THEN the loop closed with REAL data: budget
lowered under metered spend → goal gate HALT → run REFUSED to dispatch;
status showed OVER-BUDGET from the real ledger. Fixture destroyed after.

## Boundaries and honest residuals (as of R0 close; see R0.1 below)
#40: no packet required the Mac-local Core worktree — all six scope items'
true home is this repo; nothing was built in the wrong place. Residuals:
GOAL HALT is a binding announcement, not tool-level enforcement (R1);
tokens/interventions beyond gravito-run sessions are unmetered (R1 logger);
observed in the golden run: the worker created .gitignore/.serena in the
target (accelerator onboarding) — benign, noted for R1 doc pass. R1/R2
remain unauthorized. **All three residuals were hardened in R0.1 (below).**

# R0.1 hardening (2026-08-12, owner-authorized) — the three residuals, executed

## R0.1-1 — TOOL-LEVEL goal enforcement: EXECUTED, 25/25
Entry-point inventory refreshed first: real execution enters through
(a) `gravito run` (dispatch gate) and (b) every worker/session tool call,
all of which pass the PreToolUse mutgate in .claude/hooks/routing-gate.sh
(direct, resumed, and nested sessions alike — they share the hook path).
The mutgate now runs goal-check --gate BEFORE any mutating tool executes
(Edit/Write/NotebookEdit/Bash; Read/Grep/Glob never goal-blocked): fail
CLOSED (exit 2, model-visible GOAL HALT), refusal receipt appended to
build-os/receipts/refusals.log (timestamp, tool, status, gate message),
zero side effects (proven by file-hash assertions). A goal installed with
the gate tool missing also fails closed. Emergency stop and status remain
available while blocked. tests/goal_enforcement_tests.sh: **25/25** —
LIVE allows; LAPSED and NOT-YET-LIVE (both out-of-window states) and
over-budget block every mutating tool; fresh repo without a goal is
unaffected. Defect found by the failure-first tests and fixed: the
installer did not ship route-task.sh/mode-select.mjs to targets, so every
target's first mutation fell to the manual recovery path.
**NOT enforced at tool level, stated explicitly:** MCP-hosted mutating
tools (not in the mutgate matcher), a bare human shell (no hook runs),
and experiment harnesses that bypass `gravito run`.

## R0.1-2 — comprehensive metering: EXECUTED
build-os/tools/meter-run.sh parses each run stream's provider result event
into the committed ledger (flock-serialized; per-stream dedupe — same
stream metered twice = ONE entry; 8 concurrent meters = 8 intact lines,
no torn writes — all test-proven). Provenance recorded per entry
("provider-result-event"); token categories preserved; a stream with no
result event is recorded NOT-METERED, never inferred. No parent/child
double count: exactly the dispatched stream is metered, once. The gate
halts on the committed ledger (real-data halt below). `gravito status`
now reports the committed ledger and names the unmetered paths explicitly
(operator interactive sessions, direct claude invocations, experiment
harnesses, MCP-side execution).

## R0.1-3 — target-repo hygiene: EXECUTED
Why files appeared in R0's golden run, by name: `.gitignore` was modified
by Gravito's OWN installer (deliberate, marked GRAVITO:MANAGED block for
archive visibility — product artifact, documented); `.serena` was
incidental worker-tool residue. Now: `gravito run` snapshots the repo
root before dispatch and sweeps NEW unmanaged dot-entries after, moving
them reversibly to build-os/residue/<ts>/ with a receipt — product files
(non-dot, and all pre-existing files) are never touched (test-proven,
sha-asserted). `gravito purge` now strips the GRAVITO:MANAGED .gitignore
block and the installed package.json script, restoring installer-touched
files BYTE-IDENTICAL to pre-init (lifecycle test 8).

## R0.1 vocabulary regression fixed
authority_envelope_tests 23c (window vocabulary swept as a class) caught
goal-check.sh naming NOT-YET-LIVE without LAPSED: its out-of-window state
was renamed EXPIRED→LAPSED to match the envelope/claim-evidence/registry
class. Suites after: authority_envelope 126/0.

## CORRECTION (found and fixed in R1, disclosed here where the claim lives)
R0.1-1 above says real execution passes the PreToolUse mutgate in every
session. That was TRUE of this source repository and of the hook's behavior,
but FALSE of installed TARGETS: the installer SHIPPED the hook scripts and
never REGISTERED the PreToolUse matchers in the target's settings.json, so a
real session in a target repo never consulted the goal gate at tool level.
The R0.1 behavior tests invoked the hook directly and therefore could not
see this. Found by R1's failure-first wiring probe (a fresh target showed
zero PreToolUse entries); fixed in R1-P2 (installer registers gate/mutgate/
mcpgate/count/post); pinned by tests/goal_enforcement_tests.sh §5b, and
`gravito diagnose` now reports wired/UNWIRED per matcher so this class of
defect is operator-visible, not archaeology.

## R0.1 EXIT — golden path re-run on a fresh DISPOSABLE repo: PASSED
Before-manifest (sha256 of every pre-existing file) taken pre-init. Then:
init → goal (LIVE 2026-08-12→2026-08-26) → run: gate OPEN, ONE real
worker delivered docs/NOTES.md; metered **465,097 tokens / $0.286 /
1 min** — ledger equals the stream's provider result event EXACTLY;
review acceptance_cmd PASS; residue sweep isolated `.serena` reversibly
with receipt. Blocked-before-side-effects, at BOTH entry points (run
dispatch AND PreToolUse), each with a refusal receipt and app.txt
byte-unchanged: LAPSED (now=2026-09-01), NOT-YET-LIVE (now=2026-08-01),
synthetic over-budget, and a REAL over-budget halt (budget lowered to
400,000 under the 465,097 committed ledger). stop/status stayed available
while blocked. Then rollback (engine matches previous manifest) →
uninstall --force → purge --force: **all four pre-existing files
byte-identical** (sha256sum -c OK, including .gitignore), the only
remaining non-original file being the worker's product docs/NOTES.md.
Fixture destroyed after. Suite totals at close: goal_enforcement 25/25,
lifecycle 28/28, cross_repo_isolation 14/14, authority_envelope 126/0.

# R1 (2026-08-12, owner-authorized, local-only) — executed evidence

## R1-P2 — MCP mutation gate + the wiring defect: EXECUTED
The correction block above is this packet's headline: targets now REGISTER
all five tool-gate matchers at install (goal_enforcement §5b). New `mcpgate`
mode: every `mcp__*` tool call is gated DEFAULT CLOSED — a tool is exempt
only if it matches `.claude/hooks/mcp-readonly-allowlist.txt` (narrow,
engine-shipped: GitHub get/list/search/issue_read/pull_request_read only);
everything else, including read-sounding undeclared names, passes the same
fail-closed goal gate as Edit/Write/Bash, with refusal receipts naming the
exact tool (§5c: unknown write blocked; undeclared "fetch_data" blocked;
allowlisted read passes even lapsed; LIVE goal allows; no goal unaffected).
Still true: the wrapper fails OPEN on internal hook errors (control-plane
availability choice, unchanged from R0.1) and a bare human shell runs no
hooks at all.

## R1-P3 — gravito diagnose: EXECUTED
One support bundle: namespace verdict, missing engine files BY NAME,
tool-gate wiring reported wired/UNWIRED per matcher, goal window/budget,
ledger, refusals tail, receipts, residue, workers; written to
build-os/receipts/diagnose-*.txt. Broken-fixture tests prove it names the
actual fault (lifecycle §9). Defect found by the doc-drift suite and fixed:
diagnose crashed under pipefail when a receipts glob matched nothing —
partial bundles now impossible (exit-0 asserted on healthy repos).

## R1-P1 — front door + drift protection: EXECUTED
ONBOARDING.md rewritten golden-path-first (CLI verbs; the honest
NOT-enforced list on page one; no performance claims). README carries the
five-command golden path; DEMO.md routes newcomers to it and is re-scoped
as internals. tests/doc_drift_tests.sh (10/10) EXECUTES the ONBOARDING
golden-path block verbatim on a disposable repo, checks the outputs the doc
promises, refuses phantom `gravito` verbs across all three docs, and
existence-checks every source-repo path ONBOARDING names.

## R1-P4 — walkthrough kit: WRITTEN (run NOT authorized, NOT run)
docs/WALKTHROUGH-KIT.md preregisters the non-author walkthrough: operator
qualification, setup, script, success criteria S1–S5, failure criteria
F1–F4 (30-minute block rule = stop, fix, fresh run), friction/intervention
logs, evidence bundle location, and the explicit non-claims. Recruiting the
operator and running it require fresh owner authorization.

## R1 residuals, stated plainly
A bare human shell in a target runs no hooks (structural). The MCP
allowlist gates by TOOL NAME, not by inspecting what a server actually
does — a mutating tool misdeclared into the allowlist would pass; the
allowlist is the trust boundary and stays narrow by policy. Hook wrapper
fails open on internal errors (logged). Operator interactive sessions
remain unmetered. Existing targets installed before R1 need `gravito
update` to gain registration; until then diagnose shows UNWIRED. The
non-author walkthrough — R1's acceptance evidence — has not run.
