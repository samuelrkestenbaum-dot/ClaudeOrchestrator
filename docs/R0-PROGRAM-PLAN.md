# R0 implementation program — PLAN (prepared during EXP-0011; execution
# begins automatically after the frozen close/read releases the measurement
# lock). Owner authorization recorded: local-only, supersedes stop-at-owner-
# gate for these bounded R0 changes ONLY. R1/R2 unauthorized. No push/PR/
# merge/deploy/secrets/external provisioning/irreversible deletion.

## Execution preamble (first acts after lock release, before any packet)
P0. Refresh evidence: git branch/tree state, open defects (#25, #40, #42,
    #26 status), actual code of authority minimum, hooks, install scripts —
    the usability assessment PROVES NOTHING about code state.
P1. Confirm #40 boundary: if a packet's true home is the Mac-local Core
    worktree, REPORT the exact blocker and build only what belongs here.

## Packets (isolated commits, ordered by dependency)

**PKT-R0-1 — cross-repo isolation (proof + enforcement).**
Deterministic namespace: project identity = (git remote URL hash | init-time
UUID fallback) + account id; applied to memory, receipts, skills, task
state, caches, generated artifacts. Migration: existing un-namespaced state
adopted into the current project's namespace with a receipt; ambiguity =
DEFAULT CLOSED (state quarantined, operator told). Negative leakage tests:
two disposable temp repos, assertions over the mutator ledger + filesystem
that no read/write crosses namespaces. Commit 1: tests (red where honest) +
namespace; commit 2: migration + quarantine path.

**PKT-R0-2 — #25 lease validity (fail closed).**
Authority minimum rejects: expired, absent, malformed, wrong-project,
wrong-authority-class leases — every failure names its reason and the
operator's next action. Tests: boundary times, clock skew (±), replay of a
revoked/rotated lease, wrong-namespace lease from PKT-R0-1's fixtures.

**PKT-R0-3 — deterministic lifecycle.**
`gravito preflight | init | status | update | rollback | uninstall | purge`.
Idempotent (init×2 byte-identical outcome), manifest+receipt per mutation,
--dry-run on every destructive verb, interruption recovery (kill mid-init →
re-run converges), purge removes ONLY Gravito state (never user data;
irreversible deletion only via purge with dry-run first). Fresh-environment
proof: scripted run in a clean temp HOME + disposable repo. Depends:
PKT-R0-1 namespaces.

**PKT-R0-4 — gravito.goal contract.**
Schema: goal, repository identity (namespace), authority + allowed/
prohibited actions, model policy, token/time/cost budgets, acceptance
criteria (command), intervention rules, stop conditions, expiry. Validator
with actionable errors; budget-halt enforcement wired to the ledger (halt =
safe-boundary stop + durable resume state); minimal example file. Depends:
PKT-R0-2 (expiry semantics shared).

**PKT-R0-5 — unified status/receipts surface (CLI text).**
`gravito status`: current goal, state, workers, reason, authority expiry,
tokens/cost/time, interventions, pending approvals, last durable outcome,
errors, and the EXACT stop/rollback commands. Reads ledger+receipts only
(no new state). Test: scripted session; status equals records.

**PKT-R0-6 — data boundaries doc.**
DATA-BOUNDARIES.md: what leaves the machine (provider calls only), local
retention map per namespace, secrets handling, telemetry defaults (off),
removal semantics (= purge). Experimental geometry/math and unvalidated
intelligence features documented as OFF.

## R0 exit criteria (no completion claim without ALL)
Every blocker has EXECUTED evidence (tests run, transcripts kept), and the
five-step golden path init → goal → run → review → stop/rollback passes on
a DISPOSABLE second repository end-to-end. Evidence report + commit list
delivered; then STOP (R1/R2 remain unauthorized).
