# Gravito Repository Core — usability readiness (writing-only assessment)

*Question: what is still required before the owner can point Gravito at a
different real repository and use it safely and productively without being
the system's expert operator? Evidence basis: this repository's artifacts
and this program's recorded sessions ONLY. Nothing was run for this
assessment; no prior test result is re-claimed as current. Where repository
evidence is insufficient, the entry says UNKNOWN with the exact verification
required. Cross-references: docs/ONBOARDING.md, docs/DEMO.md, docs/PILOT.md,
docs/ENTITLEMENT.md, install-global.sh / install-project.sh /
init-build-os.sh / connect-project.sh, .claude/hooks/*, build-os/tools/*.*

## Honest classification ladder (today)

| Level | Verdict | Evidence / gap |
|---|---|---|
| Code-built | **YES (broad)** | routing/receipts/gates, publish gate, identity line, memory + rotation, entitlement path, hooks, motion controllers, install scripts exist in-tree |
| Test-proven | **PARTIAL, AS-OF-RECORD** | suite green at recorded commits (e.g. 2314/0 at a9f44ad); gates mutation-tested at their build dates. NOT re-verified now (no runs allowed); #31 records 6.26% base-tree nondeterminism — single greens are not proof |
| Operator-usable with expert assistance | **YES** | this program is the evidence: months of daily operation — BY an expert operator (me), with the owner supervising |
| Packaged/installable | **UNKNOWN** | install-global/install-project/init-build-os exist; no recorded end-to-end fresh-machine install; **#40: Repository Core's own worktree is Mac-local and unreachable from here** — verification: push from the Mac, then a scripted fresh-container install with transcript |
| Safe for a 2nd internal repo | **NO** | isolation unproven (below), safety defects open (#25, #42) |
| External pilot | **NO** | requires R1 + whole-system validation + license decision (#3) |
| Customer-proven | **NO** | no external usage evidence exists |

## Journey audit (gap → consequence · severity · evidence needed · smallest safe build · dependency · acceptance test)

1. **Preflight/eligibility.** No product-grade preflight ("is this repo safe
   for Gravito?"). Consequence: silent misinstall on hostile repos. HIGH.
   Evidence: none exists. Build: `gravito preflight` = read-only checks
   (git sanity, size, toolchain, secrets patterns, existing build-os/).
   Dep: none. Test: refuses a synthetic ineligible repo, passes an eligible.
2. **Deterministic install/config.** Scripts exist; determinism and
   idempotency UNVERIFIED end-to-end; Core worktree unreachable (#40).
   HIGH. Evidence: scripted install transcript on fresh container ×2 with
   identical result hashes. Build: single `gravito init` wrapping
   install-project + init-build-os with a printed receipt. Dep: #40 push.
   Test: double-install idempotent; uninstall leaves zero residue.
3. **Cross-repo/account isolation.** User-scope `~/build-os` is shared by
   design; per-project stores exist; NO test proves memory/receipts/skills
   never leak across repositories or accounts. **R0-BLOCKER, HIGH.**
   Evidence: an isolation test suite (two dummy repos, assert zero
   cross-reads/writes via the registered-mutator ledger). Build: isolation
   test + a per-repo namespace assertion in hooks. Dep: none. Test: the
   suite itself, run on two fresh dummy repos.
4. **First-run bootstrap UX.** No progress/error surface for first
   index/scaffold; failures are shell traces. MED. Build: receipts +
   plain-language error mapping in init. Test: induced failure yields an
   actionable message, not a stack.
5. **Goal/authority/budget/model-policy/acceptance setup.** Expert-only
   today (scattered across router, authority files, envelopes; #25: expired
   leases read WITHIN-LICENCE — safety defect). **R0-BLOCKER, HIGH.**
   Build: one owner-facing `gravito.goal` file (goal, authority bounds,
   budget ceilings, model policy, acceptance command) + #25 expiry fix.
   Dep: #25. Test: expired lease refuses; budget ceiling halts work.
6. **Daily workflow (plan/execute/review/resume/stop).** Exists as expert
   practice (orchestrator prompts, packets), not as commands. MED-HIGH.
   Build: five verbs mapping to existing machinery (golden path below).
   Test: scripted walkthrough by a non-author operator (R1 evidence).
7. **Visible status/spend/interventions.** Experiment executors have a live
   status surface; the PRODUCT does not (receipts require expert reading;
   no unified token/time/intervention view). HIGH. Build: `gravito status`
   reading ledger+receipts into one page (pattern proven in
   executor-status.txt). Test: status matches ledger on a scripted session.
8. **Failure recovery/crash-resume/idempotency.** Event-driven recovery is
   PROVEN in the experiment runtime (executor adoption/resume across 5+
   container restarts); product-path resume (packets mid-task) is
   UNVERIFIED; #42 (undeclared-packet blindness) and #26 (suite not
   concurrency-safe) are open. HIGH. Evidence: crash-resume test on a dummy
   repo. Dep: #42 fix. Test: kill mid-task → resume completes with no
   duplicate side effects.
9. **Update/migrate/rollback/uninstall/data removal.** install scripts
   exist; migration/rollback/uninstall UNKNOWN (no recorded exercise;
   rotation ran once, hand-crafted per #34; #35 residue unrotatable
   pending owner act). MED-HIGH. Evidence: scripted
   update→rollback→uninstall transcript with zero-residue check.
10. **Secrets/privacy/telemetry/retention.** Strong norms exist in practice
    (publish gate, salt kept out of repo, scrubbedEnv in harnesses); no
    written product data-boundary doc (what leaves the machine: provider
    calls only; what is retained where; how to purge). MED. Build: 1-page
    DATA-BOUNDARIES.md + purge command spec. Test: purge leaves no PII/
    state; doc review.
11. **Multi-operator concurrency/ownership.** Single-operator by design
    today; #26 collisions recorded; ownership model undefined. R1 concern,
    LOW for R0 (declare single-operator explicitly). Build (R1): lock+
    ownership fields on packets.
12. **Docs/examples/demo/support diagnostics.** ONBOARDING/DEMO/PILOT/
    sample-project exist (pilot kit #6); they predate the LEAN rebuild and
    the worker-contract CLAUDE.md — accuracy UNKNOWN. MED. Evidence: a
    doc-vs-behavior pass after R0 lands; a `gravito diagnose` bundle
    (identity line + versions + last receipts) for support.

## The golden path (≤5 operator-facing steps) — target contract, R0

1. `gravito init` — preflight + deterministic install + receipt.
2. `gravito goal <file>` — one file: goal, authority, budget, model policy,
   acceptance command; confirmed back in plain language.
3. `gravito run` — plan→execute with live status (status surface, §7).
4. `gravito review` — receipts, spend, interventions, diffs; accept/reject.
5. `gravito stop` / `gravito rollback` — stop halts at the next safe
   boundary and writes durable resume state (resume = `run`); rollback
   reverts Gravito-authored commits only and archives its state; neither
   ever touches non-Gravito work or pushes anything.

Experimental geometry/math, intelligence claims, and whole-system
performance claims are OUTSIDE this gate and default OFF until separately
proven and activated (whole-system validation program).

## Releases

- **R0 — owner uses a 2nd internal repo:** blockers list below; plus
  golden-path verbs over existing machinery; single-operator declared.
- **R1 — repeatable internal use by another operator:** R0 + non-author
  walkthrough evidence, doc accuracy pass, diagnose bundle, ownership/
  locking (#26 fix), crash-resume test on product path.
- **R2 — bounded paid external pilot:** R1 + license decision (#3) +
  entitlement hardening (#25 done in R0), data-boundary doc verified,
  support/diagnostics path exercised, whole-system validation evidence for
  any performance statement, pricing/support terms (owner).

## Build now vs wait

Immediately after EXP-0011 (no validation dependency): isolation test
suite (§3), #25 expiry fix, #42 singleton guard fix, `gravito init/goal/
status` wrappers, preflight, DATA-BOUNDARIES.md, uninstall/purge script.
Wait for whole-system validation: any efficiency/speed/consistency claim
surfaced to users; defaults-ON for advanced orchestration. Wait for
customer evidence: R2 pricing, support SLAs, external-pilot scope.

## What could NOT be classified from repository evidence (UNKNOWN list)

Fresh-machine install determinism · migration/rollback/uninstall behavior ·
doc accuracy post-LEAN · product-path crash-resume · Core worktree contents
(#40 — unreachable until pushed from the Mac). Each carries its exact
verification in the journey table. No proof was manufactured from the
existence of scripts, docs, or commits.
