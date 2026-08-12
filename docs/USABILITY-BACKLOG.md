# Usability backlog — R0/R1/R2 (bounded; item = consequence · severity · evidence · smallest build · dep · acceptance test)
Companion to USABILITY-READINESS.md (definitions there; no duplication).

## R0 — "owner can use a second internal repo" (ordered)
1. **Cross-repo isolation test suite** · leakage would poison both repos'
   memory and any future evidence · HIGH · two-dummy-repo suite green ·
   assertions over hooks+ledger, per-repo namespace check · no dep ·
   TEST: zero cross-reads/writes recorded by the mutator ledger.
2. **#25 lease expiry** · expired authority reads as licensed → unsafe
   action window · HIGH · targeted test · expiry check in the authority
   minimum · no dep · TEST: expired lease refuses with named reason.
3. **`gravito init` deterministic install + preflight** · misinstall or
   hostile-repo damage · HIGH · double-run idempotency + refusal transcript
   · wrapper over install-project/init-build-os + read-only preflight ·
   #40 (Core push from Mac) for full contents · TEST: init×2 identical;
   ineligible repo refused; uninstall zero-residue.
4. **`gravito goal` single config contract (+ budget halt)** · owner cannot
   set goal/authority/budget/model/acceptance without expert · HIGH ·
   scripted session · one file + plain-language confirm + ceiling
   enforcement · #25 · TEST: ceiling halts work with resume state.
5. **`gravito status` unified surface** · owner blind to activity/spend/
   interventions · HIGH · status==ledger check · one-page reader over
   ledger+receipts (executor-status pattern) · no dep · TEST: scripted
   session, status matches records.
6. **#42 undeclared-packet guard** · silent contract violations under daily
   use · MED-HIGH · regression test · guard reads declarations vs activity
   · no dep · TEST: undeclared packet detected.
7. **stop/rollback verbs** · no safe halt/undo for a non-expert · MED-HIGH
   · crash/rollback transcript on dummy repo · stop=safe-boundary halt +
   resume state; rollback=revert Gravito-authored commits + archive state ·
   items 3–5 · TEST: mid-task stop→resume completes; rollback leaves
   non-Gravito work untouched.
8. **DATA-BOUNDARIES.md + purge** · privacy/retention undefined for a new
   repo · MED · doc + purge script transcript · 1 page + script · no dep ·
   TEST: purge leaves no state; doc reviewed by owner.

## R1 — "another internal operator" (ordered)
1. Non-author walkthrough of the golden path (the acceptance evidence FOR
   R1) — scripted, recorded, no author assistance.
2. Doc accuracy pass: ONBOARDING/DEMO/PILOT vs post-LEAN behavior.
3. `gravito diagnose` support bundle (identity line, versions, last
   receipts, health).
4. #26 concurrency-safe suite + packet ownership/locking.
5. Product-path crash-resume test (executor-grade recovery on packets).
6. #17/#18 staleness guard made real (stale references surfaced to the
   operator, four escape forms covered).

## R2 — "bounded paid external pilot" (ordered; owner-gated)
1. License model decision (#3) → entitlement hardening pass.
2. Whole-system validation evidence gate for ANY performance statement
   (see ../build-os/experiments/ packet; claims OFF until then).
3. External data-boundary review + secrets scan in CI (run-capable env).
4. Pilot scope/pricing/support terms (owner) + PILOT.md refresh.
5. Second-repo replication of the golden-path walkthrough at the pilot
   site's shape (size/toolchain per eligibility scorecard).

Out of scope at every level: experimental geometry/math, intelligence
claims, whole-system performance claims — separately proven, separately
activated.
