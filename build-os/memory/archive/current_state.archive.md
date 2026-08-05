<!-- rotation-batch: 2026-08-03T19:53:21Z | source: build-os/memory/current_state.md | blocks: block_16..block_20 (5) | tool: build-os/maintenance/rotate-memory.sh -->

## ARCHIVED BATCH 2026-08-03T19:53:21Z — build-os/memory/current_state.md — 5 blocks (block_16..block_20)

## History — `gravito_mismatch_refuted_a`

- **Prior:** `gravito_mismatch_refuted_a` — **it was AUTHORISED to re-authorise two
  controls and it changed NOTHING, because the prescribed demotion was MEASURED to destroy live
  memory** (receipt `build-os/receipts/gravito_mismatch_refuted_a.md`, commits `b25f3f7` +
  `566443f`, base `c52915f`).
  `maint.tripwire_coverage_scan` carried a `demotion_requirement` that **literally prescribed its
  own demotion**; the reviewer had called it *"the strongest demotion candidate in the census"* and
  the operator's step-3 ruling named it first. The builder **applied the demotion and measured both
  arms** against an uncovered suite file that rewrites real memory:
  **GATED (shipped) — scan throws, exit 1, real tree UNTOUCHED (sha256-identical). DEMOTED — scan
  prints, exit 1, `residue.md` TRUNCATED 1621 B -> 8 B, contents replaced with `DAMAGED`.**
  **THE EXIT CODE IS 1 IN BOTH ARMS**, so every automated check watching exit codes would have
  reported the demotion harmless; only inspecting the tree reveals it. That gate is the maintenance
  layer's **only PREVENTION** — `maint.real_memory_tripwire` and `maint.shell_fingerprint` are
  detection and both declare `rollback_behavior: NONE` — so **retirement is worse than demotion and
  both outcomes are CLOSED**, not deferred.
  **Built:** `COVERAGE-GATE-PREVENTION-DIFFERENTIAL` (`tests/build_os_maintenance_tests.sh` §6a) and
  the **`OBSERVE-LB`** guard in `scan-controls.sh`, which refuses `load_bearing` at `observe` with a
  named consumer. Red-driven, clean arm first.
  **`maint.source_scan_mask`: ALL FOUR OUTCOMES CLOSED, each for a different reason.** Demotion
  writes a **falsehood** (README §2 defines `observe` as "nothing reads the result"; **two controls
  read this one's** — verified at import AND call sites); retirement breaks both consumers;
  improving the evidence is **forbidden by its own `promotion_requirement`**; and its class is not
  wrong, because a defeatable lexer really is a heuristic.
  **THE REVIEWER'S CORRECTION THE BUILDER ACCEPTED:** `source_scan_mask` is **NOT** a second
  demonstration of the `outputSemantics` split. Decisive test: **`outputSemantics` would not fix
  it** — `observe` would still mean "nothing reads the result". The collision is between
  `runtime_authority`'s **consumption clause** and `implementation_status`, a redundancy between two
  fields that **BOTH ALREADY EXIST**. **This matters because the operator committed to
  `outputSemantics` for S1 on a different case; counting this as a second data point would inflate
  confidence behind that design using a case that does not test it.**
  **THE SECOND-ROUND FINDING — the sharpest self-catch in the sequence.** The packet had written,
  in TWO places, that the `observe`-rung foreclosure is fixed by *"deleting the consumption clause
  from README §2's ladder definitions, a one-line edit"*. **Both halves were false.** Consumption is
  asserted in **SIX** places (README §2's **two** bottom rungs — `none` "nothing consumes it" and
  `observe` "Nothing reads the result" are **both** consumption clauses — README §3b's `shadow` row,
  `authority_envelopes.txt`'s header, and both tools' headers). And decisively: **the foreclosure is
  enforced by CODE, not prose** — `scan-controls.sh`'s `OBSERVE-LB` keys on `[ "$aut" = "observe" ]`
  and hard-codes the semantics in its own refusal message, so deleting every line of README prose
  leaves it refusing at exit 2 and the demotion still unwritable for all 67. **A future packet could
  have executed that prescription faithfully and achieved nothing.** The reviewer's framing: this is
  the failure `MISMATCHES.md` names about itself — *"a wrong exclusion gets caught by re-running the
  rule, and a wrong reason is what the rule is re-run against."* **Nothing re-runs a reason.**
  **THE REVIEWER WITHDREW ITS OWN PRIOR RULING**, naming the error precisely and on the record:
  *"I reasoned from the token `refuted` rather than the evidence the token points at… Reasoning from
  a label instead of its referent is precisely the failure this registry exists to catch."*
  **A reviewer correcting itself on the record is the behaviour the system is supposed to produce.**
  Two corrections landed with it: the refutation is **PATH-SCOPED** (the DETECTION claim failed on
  the bare `node --test` path; on the sanctioned path the same scan is measured PREVENTION), and
  **EVADABILITY IS NOT NON-DISCRIMINATION** (the defect it exists against was an ACCIDENT, and
  against that it discriminates exactly). **Keeping the gate is not a claim to be in licence:** it
  stays at `gate`, its mismatch stays **declared**, and no exception was written.
  **qa GREEN, and it REPRODUCED THE CENTRAL FINDING FROM SCRATCH rather than running the builder's
  test:** three independent fresh repos, its own `node:test` fixture with **static imports and a
  real `test()` block** — a **stronger** shape than the shipped fixture's top-level
  `await import()` — arms verified by `diff -r` to differ by **exactly one line**
  (`throw new Error(` -> `console.error(`), plus a **negative control** with no fixture (exit 0,
  tree untouched). So the refusal is caused by the fixture, not a pre-existing failure, and the
  finding is **not an artefact of fixture shape**. Also: **287/287 `evidence_refs` content-verified
  with ZERO drift**; the census **re-derived independently from README §3** giving the same 19 of 81
  at 6/5/8; **`OBSERVE-LB` driven red by name with 0 of 81 live entries able to trip it**; both
  `source_scan_mask` consumers verified at **import AND call sites**; **Commit-1 green in
  isolation**; a safety grep with **22 patterns all firing on planted controls**; and destruction
  confinement **audited and empirically proven** (real `build-os/memory/*` byte-identical after
  three full-suite runs). **qa also caught a trap in its own work** — a first isolation run reported
  **1592** because a stale clone directory made `git checkout` fail silently; it discarded and redid
  it. **1592 is NOT a number from this packet.**
  **Verdict pass as fixed: reviewer `fix-then-pass` TWICE** — 3 items / 5 sites, then 2 items /
  3 sites closed by the orchestrator in the `tiny` lane.
  **DEPTH: FOUR SERIAL STAGES.** Reviewer's own accounting: **not a withheld installment** — both
  second-round items concerned text that **did not exist at stage-2 review** (item A was the item-2
  replacement itself; item B was a collision the ALSO-RECORD note created by landing). But it named
  the honest reading: **item 2 was cut as "replace a false claim" when it was really "replace a
  false claim AND state the correct radius"** — the same **incomplete-application** shape as the
  previous packet, two packets running.
  **Census UNMOVED, which is the correct result for a packet that re-authorised nothing:**
  **81 controls, 67 `load_bearing`, 14 declared mismatches, 0 at `observe`, distribution
  68 `gate` / 13 `advise` — no `observe`, `none` or `rank` rows exist at all; class A58 / B3 / C20;
  `evidence_refs` 287, all resolving.** Suite **1617 passed / 0 failed** (independently verified by
  the orchestrator); `./build-os/maintenance/run-tests.sh` **144/144**;
  `tests/evidence_policy_tests.sh` **102/0** (was 88); `tests/build_os_maintenance_tests.sh`
  **67/0** (was 61); `scan-controls.sh check` **exit 0**;
  `evidence-policy.sh check` **19 of 81, split 6/5/8 — UNMOVED**; **ZERO governance-field diff
  lines** vs `c52915f`; tree clean.
  **THREE OPERATOR DECISIONS — the packet's real output.** (1) **A FIFTH OUTCOME IS MISSING from the
  operator's framework**: it offers demote / correct class / improve evidence / retire, but demotion
  **onto the rung the `refuted` cap prescribes is unspellable for 67 of 81 controls (83%)**, and 0
  sit at `observe` today. Reviewer's proposal: **accept and constrain** — leave the authority, keep
  the finding standing, require an operator envelope; `authority_envelopes.txt` exists with 0 live
  grants, which is exactly what it was built for. (2) **THE LADDER HAS A DEFINITIONAL BUG, and
  fixing it is NOT one line**: `none` = "nothing consumes it" and `observe` = "it measures and
  records. Nothing reads the result" — **both bottom rungs defined by non-consumption**, leaving no
  rung meaning *"it is read, but may cause nothing"*, which is precisely the state a
  refuted-but-wired-in control should occupy. The fix touches **six prose sites AND
  `scan-controls.sh`'s `OBSERVE-LB`**, which is the part that actually binds. (3) **`OBSERVE-LB` MAY
  BE CORRECTLY REASONED BUT MIS-PLACED IN AUTHORITY**: it sits on the **gating** path
  (`scan-controls.sh`, exit 2) while the axis it defends deliberately only **advises**
  (`evidence-policy.sh`, exit 0). The advisory axis was designed so nothing gets demoted
  automatically with no operator in the loop — **this guard removes the operator's ability to apply
  the demotion by hand as well.** The reviewer **declined to demand a move**; it is a design call.
  **DO NOT EXTRAPOLATE from this packet to the remaining twelve mismatches.** These two were
  selected **because** `refuted` made action look settled, which makes them **the least
  representative pair in the census**. **Of the 19 findings, 11 are `unvalidated`** — nobody
  measured — and for those the remedy is **outcome 3, improve the evidence**, which is **wide open**.
  It was closed here only because `source_scan_mask`'s own `promotion_requirement` explicitly
  forbade it.
  **Both verdicts single-model** — **no Codex in either review or either re-review**;
  `tool_router.md:368` routes to it and nothing is installed. **The row is unbacked.**

## History — `gravito_authority_envelope_a`

- **Prior:** `gravito_authority_envelope_a` — **the operator has an artefact to grant
  authority in, and the licence model has a third MIN term** (receipt
  `build-os/receipts/gravito_authority_envelope_a.md`, commits `88052e7` + `a7ab841`, base
  `77a0040`). A **store** (`build-os/registry/authority_envelopes.txt`, **0 live grants**, worked
  example kept entirely inside `#` comments so the artefact never asserts a grant nobody made), a
  **validator** (`build-os/tools/authority-envelope.sh` — `schema` / `check` / `modes`), and a third
  term: **`L_effective = min(L_class, L_evidence, L_deployment)`** with
  `DEPLOYMENT_AXIS="shadow:observe human_confirmed:advise bounded_autonomous:rank autonomous:gate"`.
  Default for an unenveloped control is `autonomous`, which **adds no cap** — the only default that
  leaves a census written before this axis existed where the operator put it.
  **THE HEADLINE FOR STEP 3: AN ENVELOPE CAN ONLY LOWER `L_effective`. IT CANNOT LEGITIMISE A
  GRANT.** The reviewer wrote a well-formed operator grant of `gate` to `adoption.lane_size_check`
  — the most obvious first use — and got `OVER-GRANTED ... granted=gate l-class=advise
  l-effective=advise binding-axis=class`, with `evidence-policy.sh`'s 19 finding lines
  **byte-identical** against an empty store. The behaviour is **correct and is arguably the best
  property in the packet** — the tool refuses to launder a Class-C gate even when the operator
  signs off. **But it means step 3 (applying promotion/demotion rules to the fourteen mismatches)
  CANNOT BE DONE BY WRITING ENVELOPES.** Every one of the fourteen exercises MORE authority than
  its class licenses, and an envelope can only take authority away. **Step 3 needs a class change
  or a different instrument, and neither is designed.**
  **THE PACKET'S OWN CLAIM ABOUT ITSELF WAS FALSE, AND MUTATION PROVED IT.** `evidence-policy.sh`
  asserted *"The suites reconcile the two, so this cannot quietly restate the third axis
  differently."* The reviewer changed ONLY `authority-envelope.sh`'s `DEPLOYMENT_AXIS` from
  `shadow:observe` to `shadow:none`, left README §3b saying `observe`, and **both suites stayed
  green at 86/0 and 88/0**; the orchestrator reproduced it independently. Only the axis's **copy**
  was pinned (by §5b of the evidence suite); the **declared OWNER** was pinned by nothing. Closed by
  new **§2a** of `tests/authority_envelope_tests.sh:247`, reconciling `DEPLOYMENT_AXIS` against
  README §3b in both directions with a non-vacuity floor on both sides; the orchestrator re-drove
  the identical mutation against it: **89 passed / 2 failed**. **The fix used the device already in
  the tree — §5a's parse-prose / recompute-table / diff-both-ways pattern — not a new invention.**
  **The third axis is LIVE, not decorative, and qa proved it** (the orchestrator could not settle
  it): with a valid grant `modes` emits `metrics.record.schema_invariant->human_confirmed`; deleting,
  `chmod -x`-ing, or stubbing the validator each drive `evidence-policy.sh` to **exit 2 with a named
  refusal**; a `shadow` grant moves the census **19 -> 20** with `licensed=observe axis=deployment`.
  qa also distinguished **§18** (compares two EMPTY stores, so it proves invariance only) from
  **§18a** (a `shadow` fixture, driven red) — **§18a is the section that discriminates**.
  **THE S1 TENSION: BOTH READINGS RECORDED, NEITHER ADOPTED**, enforced by §17, which fails with
  `reading 2 has been silently adopted — shadow now licenses rank, which redefines the ladder`.
  **The reviewer's advice, recorded AS ADVICE AND NOT ADOPTED:** the S1 collision is not a
  deployment-axis problem at all — `heuristic_policy` is Class C so `L_class = advise` and
  `rank > advise`, so **the minimum is capped BEFORE the deployment term is consulted**; `shadow`'s
  cap could be `gate` and S1 would still be out of licence. Reviewer recommends S1 declare
  `runtimeAuthority: observe` with a note that its SIGNAL is rank-shaped, keeping
  `runtime_authority` = permitted consequence and `deployment_mode` = whether anything consumes it.
  **This is the operator's call and nothing has adopted it.**
  **Census: 81 controls / 81 bindings; 68 gate / 13 advise / 0 rank / 0 observe; 14 declared
  mismatches; `evidence_refs` 274 -> 287 (all resolving); inst/proxy/nominal 29/46/6; class
  A58 / B3 / C20; homeostasis 22 (17 suites); epistemic_quality 25; primitives with >=1
  instantiating binding 8 of 17; live authority envelopes 0.** Suite **1597 passed, 0 failed**;
  `authority_envelope_tests.sh` 91/0; `evidence_policy_tests.sh` 88/0; `scan-controls.sh check`
  exit 0 (81 controls / 36 surfaces); `evidence-policy.sh check` exit 0, **19 of 81, split 6/5/8 —
  UNMOVED**. All re-derived by the archivist at close directly from the registry files.
  qa **GREEN** at `4bc240a`, re-deriving everything with its own buffered stanza parser: finding set
  byte-identical to base, the 14 equalling the `authority_mismatch: declared` set with symmetric
  difference empty both ways, 3 new controls with **0 `-` lines on any governance field**, all 9
  refusal states exiting 2 and propagating, Commit-1 green in isolation, and a safety grep over
  **1966 added lines with all 18 patterns proven NON-BLIND on a poison fixture**.
  Verdict **pass as fixed**: reviewer `fix-then-pass` (9 items, two proven by MUTATION rather than
  argued), re-review `fix-then-pass` (3 one-line items, closed by the orchestrator in the `tiny`
  lane). **The builder's by-number sweep of the 9 found 4 MORE stale sites this packet had created**,
  including `MISMATCHES.md:248`'s `:938` in the SAME SENTENCE as the `:960` the reviewer flagged —
  which neither the reviewer nor the orchestrator saw.
  **DEPTH DEFECT: four serial stages, and the cause is DIFFERENT from last packet's.** Last packet:
  **incomplete ENUMERATION** (installments). This packet: the reviewer swept the whole class first
  and enumerated correctly in ONE installment, and still hit stage 4 because **two of its nine items
  did not fully land** — item 7 renamed a section header without the two prose references pointing at
  it, and item 6 over-corrected a false claim into a different false claim. **Name it: INCOMPLETE
  APPLICATION, NOT INCOMPLETE ENUMERATION.** They need different remedies: sweep-the-class fixes
  enumeration and was correctly applied here; what is missing is that **a fix round must verify each
  item LANDED, not that each item was addressed.**
  **A PROCESS DEFECT THE ORCHESTRATOR OWNS: this entire packet was built with
  `build-os/packets/active_packet.md` reading "NO PACKET IN FLIGHT"** — the orchestrator dispatched
  without setting it. **The reviewer ruled DO NOT back-write the file**, because that would
  manufacture an artefact saying a packet was declared when it was not — the same falsehood the
  envelope store avoids by keeping its example in comments. **The file was not back-written and the
  record stands.** The irony, plainly: `bandwidth.active_packet_singleton` **refuses TWO declared
  packets but permits ZERO**, so a whole packet was built with no declared packet and the control
  passed clean. **This is the disclosed "delete the file evades it" hole in a strictly worse form —
  the delete branch needs an affirmative destructive act; this one fires on pure omission.**
  See residue (u).
  **Both verdicts single-model** — no Codex second-eyes in the review OR the re-review;
  `tool_router.md:368` routes to it and nothing is installed. **The row is unbacked.**

## History — `gravito_evidence_policy_matrix_a`

- **Prior:** `gravito_evidence_policy_matrix_a` — **the licence table has a second
  axis** (receipt `build-os/receipts/gravito_evidence_policy_matrix_a.md`, commits `105cb75` +
  `0555717`, base `6b01173`). README §3 licensed authority on **class alone**, so a control
  measured and found **not to discriminate** could stop a build with no rule objecting. §3a adds
  `class x empirical_status -> licensed authority`, composed as
  **`licensed = MIN(class-licensed, evidence-licensed)`**.
  **The sharp rule:** `refuted` caps at `observe` **at every class** — class is a claim about the
  KIND of thing checked, evidence about whether the check WORKS, so class cannot rescue it.
  **The expensive rule:** `unvalidated` caps at `advise`, not `rank`, because `rank` orders work
  with **no human in the loop**. `red_driven` is deliberately uncapped, **with the limit of that
  argument now stated out loud**: it holds at Class C and **FAILS at Classes A and B**, which carry
  no fitted threshold for the class axis to charge.
  **The finding: 19 of 78 out of licence** — 14 the class axis already saw, **5 it structurally
  could not** (four Class-A gates on `unvalidated` carrying `authority_mismatch: none`, because the
  old one-dimensional table genuinely licensed them, plus `maint.source_scan_mask` advising on
  `refuted`), and 1 gating on `refuted` whose declaration understates it.
  **It ships at `advise` and is provably advisory** — a test drives the live registry, which
  violates it, asserting both exit 0 AND a non-empty finding set, so the zero is not vacuous
  silence. **It re-authorises nothing.**
  **Census: 78 controls / 78 bindings; 66 gate / 12 advise / 0 rank / 0 observe; 14 declared
  mismatches; `evidence_refs` 257 -> 274; inst/proxy/nominal 29/43/6; primitives with >=1
  instantiating binding 8 of 17; class A56 / B3 / C19.** Suite **1485 passed, 0 failed**;
  `evidence_policy_tests.sh` 67/0; `scan-controls.sh check` exit 0. All re-derived by the archivist
  at close directly from the registry files.
  **`rank` and `observe` are still 0 of 78** — and this packet wrote rules about both rungs that
  **no control has ever exercised**. The S1 collision below is the first time either would have a
  live occupant.
  Verdict **pass as fixed**: reviewer `fix-then-pass` twice, qa **RED** once (narrow,
  documentation-only; every measured claim verified exactly, and it added 3 findings the reviewer
  missed, one blocking).
  **THE TWO GATES FOUND DIFFERENT THINGS, BY DIFFERENT METHODS.** qa's contribution was **mutation
  testing** — it did not inspect the guards, it broke them. Changing README §3's class row -> RED;
  dropping an evidence level -> RED; **changing an evidence cap -> the suite stayed GREEN.** That
  measured a real hole inspection had not seen: §3a's cap table was an unreconciled duplicate of the
  tool's `EVIDENCE_AXIS`. Closed by §5a. **Keep the method, not just the finding.**
  **The packet's own central defect was a real number answering the wrong question:** the
  consequentialist half of the `red_driven` argument cited **"53 of 78"** — 53 is the count of
  controls whose evidence is exactly `red_driven`, correct elsewhere, borrowed here — and the tool
  header was stale on **both** halves at "50 of 75".
  **DEPTH DEFECT: this packet ran to FOUR serial stages**, which `CLAUDE.md` classifies as a defect.
  **Cause: the fix list arrived in installments.** The **reviewer identified itself as the source
  unprompted** — its stage-2 pass swept commit 1's figure sites but never its census-count sites —
  and refused to pass a known-false artefact to protect the budget. **That was the right call and is
  recorded as such.** The orchestrator closed the 4 remaining sites in the `tiny` lane and swept the
  class rather than the named sites, which is the correct remedy for an installment failure.
  **Both verdicts were single-model** — `codex` is absent, so the declared second-eyes row at
  `tool_router.md:368` went unfulfilled on **both** the review and the re-review. **The row is
  unbacked.**
  **BLOCKING THE OPERATOR — the S1 collision:** S1 is slated to arrive at `runtimeAuthority: rank`
  with `empiricalStatus: untested`. Two collisions. S1 at `rank` on unvalidated evidence ships out
  of licence on day one (survivable — the matrix only advises). Worse, **`untested` is not one of
  the five evidence tokens, so `evidence.derivation_nonvacuity` (Class A, gate) REFUSES THE ENTIRE
  DERIVATION at exit 2** rather than flagging S1, because an unrecognised level must never fall
  through to permissive. Reproduced independently by the archivist at close by injecting `untested`:
  `UNREADABLE ... has no cap on the evidence axis` / `REFUSED`, **exit 2**. **The operator must
  choose: add `untested` as a sixth token, or have S1 arrive carrying `unvalidated`.** Found by a
  packet that can only advise, **before S1 was built**.
  **FOUND AT CLOSE, AND CLOSED IN THE CLOSE COMMIT:** the tiny-lane sweep reported "no stale `75`
  remains in any registry artefact" and **that was false** — `CROSSWALK.md:8` (bolded, present-tense)
  still said 75 and contradicted `CROSSWALK.md:87` in the same file, plus `:25`, `:39` and
  `neurocosmology_crosswalk.txt:169`. All four are now **78**. The sweep that found them was by the
  **number** (`grep -rn '\b75\b'`), not by hand-written phrases; the sweep that missed them grepped
  for `"75 controls\|75 bindings\|75 entries\|of 75"` and matched none of the four. **That is the
  lesson: sweep a stale count by the literal, and close the sweep by re-running the grep.**
  **`control_registry.txt:1464` was deliberately LEFT at 75** — it narrates a historical incident
  (the field-parser off-by-one on `evidence-policy.sh`'s first run) that happened before the three
  new stanzas were appended, so 75 was the live count at the time. Correct as history; not a stale
  census claim. See residue (l).

## History — `gravito_census_gaps_egress_bandwidth_a` through `gravito_productization_pa_maintenance_upstream_a`

- **Prior:** `gravito_census_gaps_egress_bandwidth_a` — the two cheapest census gaps the crosswalk
  found are closed (receipt `build-os/receipts/gravito_census_gaps_egress_bandwidth_a.md`, commits
  `86c8f93` + `2a3c9b3`, base `321dced`). `entitlement.egress_scan` (Class A, gate, red_driven)
  registered and bound to `ethical_admissibility`, taking that primitive **off nominal-only for the
  first time**; `build-os/tools/bandwidth-check.sh` gave `integration_bandwidth` its first bindings
  (`bandwidth.active_packet_singleton`, **Class C after demotion on review**, gate, mismatch declared
  — the 14th; and `bandwidth.packet_commit_ceiling`, Class C, **advise**). Two capacity dimensions
  were **declined out loud**: `write_sets` and `depth`. Census 71 -> 75 at that close.
  **The two gates disagreed on the central question** — qa ruled the singleton control Class A, the
  reviewer ruled it Class C wearing an A label, and the reviewer won. **The mechanical guards did
  not catch it:** `scan-controls.sh` reconciles class *labels* and cannot reconcile the *arguments*
  behind them. **The fix for that is the reviewer stage, not another scanner.**
  **Precedent set, forward-facing only:** new Class-C controls ship at `advise` by default;
  promotion to `gate` is a separate governance action. It does **not** generalise backward to the
  existing 13.
- **Prior, and NOT RECEIPTED in this file:** several packets landed between the stdin-hang close and
  this one and were never folded into this snapshot — `gravito_fanout_lanes_scaffold_release_a`
  (`68cae7a`), `gravito_metrics_adoption_guard_a` (`9633928`), `gravito_pilot_kit_a` (`cb8e072`),
  plus the lane-declaration (`d30aeab`), swarm-merge (`785a851`), control-registry (`ce5ca66` +
  `e8f34ed`) and crosswalk (`be9de88` + `321dced`) packets. Only the first three have receipts of
  any kind; the registry packets have **none**. Treat the "Prior" entries below as a record that
  stops at `641527f`.
- **Prior:** `gravito_test_harness_stdin_hang_a` — the documented test command no
  longer hangs on an interactive terminal (receipt
  `build-os/receipts/gravito_test_harness_stdin_hang_a.md`, commit `641527f`).
  `tests/build_os_tests.sh` §2 invoked the SessionStart hook with the **caller's stdin
  inherited**; the hook reads stdin to EOF (`payload="$(cat)"`), so on a TTY the suite blocked
  forever with no output — on the exact command the README advertises. Diagnosis was
  **hook-correct / test-wrong**: the hook contract is right and is unchanged. Fixed by feeding
  the realistic SessionStart JSON payload, plus a stdin pin (§27) that is behavioural (a FIFO
  held open under `timeout`) **and** static (a scanner covering all **10** hook-invocation sites
  — 3 SessionStart + 7 UserPromptSubmit — with a minimum-site-count **vacuity floor**, because an
  earlier draft grepped only `bash "$HOOK"` and saw 3). **Before: exit 124. After: exit 0,
  281 passed / 0 failed at `641527f`** (657 now that four further sibling suites are chained).** Known limit, stated in-file: on a TTY a re-broken §2 call hangs before
  §27 is reached; check (b) is the protection and fires in CI / any non-TTY run.
- **Prior:** `gravito_productization_pa_maintenance_upstream_a` (**P-A**) — the memory
  maintenance + safety layer is upstreamed into the product (receipt
  `build-os/receipts/gravito_productization_pa_maintenance_upstream_a.md`, commits `c30f77d`
  + `5b956c0`). Ports rotation / tripwire / the sanctioned test wrapper (8 files) from a
  reference deployment into `build-os/maintenance/`, with installer wiring into **both**
  customer entry points, a `PORTING.md` manifest, a **contract-only** `standing_gates.md`
  template (the reference deployment's live hard-stop inventory was deliberately NOT ported),
  `GRAVITO:MANAGED` ownership markers + a `.gravito-managed` manifest, and a **61-test
  cold-install suite chained into the documented command** rather than left discoverable-only.
  Load-bearing adaptation: all three `FILE_SPECS` delimiters are now `^## ` (the reference
  delimiter found **zero** blocks in a scaffolded file, and a delimiter matching nothing does not
  error — it reported a no-op at exit 0, i.e. a file that silently never rotates
  **[ANNOTATED 2026-08-01 by `gravito_ladder_semantics_a`: the word "silently" IS WRONG and this
  entry is left otherwise intact because it is a historical packet log pinned to a commit. qa
  MEASURED it: a zero-block file is byte-identical after `--apply`, exit is 0, and nothing fails —
  but `rotate-memory.mjs` prints `WARNING: <path>: the block delimiter /^## / matched NOTHING …
  NOTHING CAN EVER ROTATE OUT OF IT` to stderr. The failure mode is AN IGNORABLE WARNING, NOT
  SILENCE. Corrected HERE and only here, on the reviewer's ruling: this file is what agents read to
  FORM beliefs, so an uncorrected known-falsehood here gets re-propagated — which is this packet's
  entire thesis. The receipt and the released `CHANGELOG.md` block are frozen records and are left
  alone.]**), and a
  zero-block parse of a file that HAS content now warns on stderr instead of printing the same
  `already rotated (no-op)` line it printed for two benign states. Reviewer verdict **pass**,
  after one **fix-then-pass** round (5 items). Suites at `641527f`: **281 / 144 / 61**, all 0 fail (the 281 is now 488).

## History — the earliest sessions, P-022 back to P-015

- **Prior:** P-022 — reconciliation of the post-settings-closure-audit branch
  (`claude/post-settings-closure-audit-y59p8t`) into canonical (receipt
  `build-os/receipts/P-022.md`). **Documentation-only; no behavior change; suite stays 216/216.**
  The audit branch (two commits self-labeled "P-001": `571bf05`, `e3d8b6e`) is **reconciled /
  superseded** — its behavior was already **subsumed** by P-006 (216-check suite), P-016/P-017
  (conditional inline-candidate + non-fatal-bootstrap fallback), P-019 (21st live in Cloud),
  P-020 (Serena add-if-absent), and P-021 (UI UX Pro Max absent / watch fallback), so **zero
  machinery was imported** (no `verify.sh`, no `tool_router` edit, no new test). The audit's
  "P-001" identity **collides** with canonical's existing P-001 and was **not** imported; the
  audit's proposed **Sourcegraph** directory-connector is unverified/not-connected this session
  and was **deliberately excluded** (no-route-to-unverified). Suite **216/216**.
- **Prior:** P-021 — fix-to-closure (receipt `build-os/receipts/P-021.md`). **P-020
  proven on the real `~/.claude.json`**: `register-serena` logged *already present — left untouched*,
  byte-identical no-op, one Serena, and a **live `mcp__serena__list_memories` returned `{}`
  (callable)**. **21st.dev** diagnosed as an **Anthropic-managed account connector** (not in
  `~/.claude.json`; approval-gated) — no container lever; user action = Cloud connector settings.
  **UI UX Pro Max** is a user-account skill absent from this container — user action = Cloud enable /
  provide package. **Claude Watch** has no repo lever, so shipped a **Cloud-native supervision
  fallback**: `build-os/tools/supervise.sh` (bounded polling watch → COMPLETED/TIMEOUT/USAGE; no
  plugin) + a truthful router/inline update naming it (still availability-conditional). Suite
  **216/216**.
- **Prior:** P-020 — the SessionStart bootstrap (`install-accelerators.sh`) now
  **registers the pinned Serena MCP add-if-absent**. It previously installed the Serena binary but
  never wrote the `mcpServers` entry ("installed but not registered"); it now adds the canonical
  pinned server to `~/.claude.json` **only if no `serena` entry exists** — closing the config-side
  Serena gap on a surface that lacks it, while leaving the Mac's user-scope server byte-untouched
  (single-server rule, P-008). No secret; project `.mcp.json` stays Serena-free. Suite **208/208**.
  **Honest boundary:** this closes the gap only if the surface resolves MCPs from `~/.claude.json`;
  a Claude Cloud task using Anthropic's managed connector registry (as 21st.dev does) still needs a
  Cloud-settings action. **Claude Watch** (host plugin) has no repo lever — Cloud enable is a user
  step.
- **Prior:** P-019 — cross-surface truth (receipt `build-os/receipts/P-019.md`).
  21st.dev is **verified live in Claude Cloud**: a fresh cloud Code session called
  `mcp__21st__search` and returned "Dashboard Sidebar" by `arunjdass` (id 14941) — connected AND
  callable — but Anthropic's web-connector layer **approval-gates every call** (project settings do
  not bypass it), and the API key was never placed in the plaintext cloud env. Mac-local `21st-dev`
  stays the zero-touch lane. **Two cross-surface asymmetries remain open (user/cloud-controlled,
  not repo-fixable):** Serena is active user-scope on the Mac but *installed-not-registered* on the
  Claude Cloud surface (registering it there is the user step; the repo must not add it to project
  `.mcp.json` per the single-server rule); Claude Watch v0.4.1 is host-enabled but **absent from
  Claude Cloud's live registry**. Routing already treats both as availability-conditional, so no
  false claim is made. Suite **202/202** green.
- **Prior:** P-018 (terminal-marker integrity: only a single valid final-line marker is
  COMPLETED; bounded capture via a 0700 temp dir + streaming limiter; signal reaping) and **P-018.1**
  (Linux portability of the 200KB capture-bound test — payload now generated in-child, not via an
  env var that exceeded Linux `MAX_ARG_STRLEN`). Suite 198 → 200 → **202**.
- **Prior:** P-017 — post-release adversarial correction (7 runtime defects;
  host-implemented on the Mac as `ac500c6`, adopted here; suite 198/0):
  1. **Failure propagation** — `prompt-router.sh` preserves the real `detect` exit and only
     an explicit `COMPLETED` suppresses parent work; otherwise it says the handoff was not
     confirmed complete and the focused parent must continue / obtain input.
  2. **Semantic completion** — the child must end with a terminal marker
     `[BUILD_OS_STATUS: COMPLETED|NEEDS_INPUT|BLOCKED|FAILED]`; exit 0 alone is not "done" —
     missing/malformed status is **UNCONFIRMED** (exit 76), never OK.
  3. **Prompt privacy** — the task travels over **stdin**, never argv (so it can't leak via `ps`).
  4. **Lock safety** — no recursive deletion: `lock_path_safe` rejects `/`, `.`, `..`, `$HOME`
     and symlinks; `safe_release_lock` unlinks only the `pid` file then `rmdir`s.
  5. **Inline availability is conditional** — routes emit an INLINE CANDIDATE (verify the tool
     is connected/callable on this surface; else use a built-in/local fallback and state the
     limitation) — never "REQUIRED use X" and never claim availability from install alone.
  6. **Budget accuracy** — the audit separates enabled **full-body inventory** from startup
     metadata and reports the metadata status as **UNKNOWN from files alone** (full SKILL.md
     bodies are inventory, not measured startup metadata) — no false within/over certainty.
  7. **Signals + bounded output** — INT/TERM restores focused, releases the lock, and exits;
     the child is killed (verified) and captured output is bounded + visibly truncated.
  `tests/build_os_tests.sh` — 198/198 green. (A parallel cloud implementation was discarded in
  favour of the validated host version, per the P-007 split-brain precedent; this packet adds
  the missing Build OS memory closure.)
- **Prior:** P-016 — final Ferrari hardening (7 audit fixes):
  1. **Capability registry** replaces the opaque regex — precedence-ordered, per-family
     task rules. Broad ECC (Everything Claude Code) tasks now route `ecc`: Rust
     ownership/unsafe, Go concurrency/debug, PostgreSQL schema/query, autonomous-agent
     harness/evals, architecture + browser specialists (crypto tokens retained). Ordinary
     lightweight tasks stay `focused` (no relaunch).
  2. **Inline routes** — `classify` returns `21st`/`agent-reach`/`claude-watch`/`ui-ux-pro-max`;
     `detect` emits a REQUIRED current-surface directive with NO capability-profile switch and
     NO child; the prompt hook no longer falsely claims a child handled an inline route.
  3. **Zeroize NL coverage** expanded (keys-remain-in-memory, cleared-from-registers/stack);
     zeroize keeps highest precedence.
  4. **Privacy** — the handoff audit log records only timestamp/route/result/exit/event-id
     (never prompt text or cwd), is created/chmodded `0600`, and tightens a pre-existing 0644.
  5. **Concurrency** — a portable `mkdir`-atomic lock wraps profile activation + child +
     restore; configurable wait; fail-closed BUSY (no mutation, no child) on contention; safe
     stale-lock break; released on EXIT/INT/TERM; focused restoration preserved.
  6. **Surface-aware inventory** — router distinguishes Claude Desktop connector verification
     from the local Claude CLI (21st.dev Desktop-verified, absent from `claude mcp list`;
     Agent Reach native skill; UI UX Pro Max v2.11.0; Claude Watch v0.4.1); no cross-surface
     ACTIVE claim; stale "host-reported" language removed.
  7. **skill-budget-audit** now reports installed inventory separately from the startup-enabled
     set (via `enabledPlugins` + `installed_plugins.json` installPath, de-duped) and only
     checks the enabled set against budget — a disabled mega-bundle no longer reads OVER BUDGET.
     **Correction:** the real `installed_plugins.json` stores each plugin as a **LIST** of
     install records; the parser now handles list/dict/string schemas (prefers the user-scope
     record) so the host audit is nonzero — was falsely 0/0.
  `tests/build_os_tests.sh` — 189/189 green (RED 148/38 → GREEN 186/0; +3 list-schema checks → 189/0).
- **Prior:** P-015 — global install ships the specialist handoff tools (installed hook resolves
  + runs the handoff end-to-end). P-014 — zero-touch specialist orchestration.

---
_Updated by the archivist on close._

<!-- rotation-batch: 2026-08-04T13:28:50Z | source: build-os/memory/current_state.md | blocks: block_16..block_18 (3) | tool: build-os/maintenance/rotate-memory.sh -->

## ARCHIVED BATCH 2026-08-04T13:28:50Z — build-os/memory/current_state.md — 3 blocks (block_16..block_18)

## History — `gravito_p2_claim_scoped_evidence_a`

- **Prior:** `gravito_p2_claim_scoped_evidence_a`
  (`PACKET-0019-gravito-p2-claim-scoped-evidence-a`) — **ONE CONTROL MAY NOW CARRY MANY CLAIMS
  WITH MANY VERDICTS, and the packet found a LIVE OVER-GRANT INSIDE THE OVER-GRANT DETECTOR**
  (receipt `build-os/receipts/gravito_p2_claim_scoped_evidence_a.md`, commits `9474cae` +
  `c653508`, base `e6b825b`, re-verified `git merge-base c653508 e6b825b` = `e6b825b`).
  **P2 of the operator's five.**
  **DELIVERED.** A **claim-scoped evidence store** (`build-os/registry/evidence_assertions.txt`,
  one stanza per assertion, stable `EV-NNNN-<slug>` ids, nineteen required fields, **a subject may
  carry many concurrent assertions**), a validator (`build-os/tools/claim-evidence.sh` —
  `schema`/`validate`/`list`/`project`), and a new suite `tests/claim_evidence_tests.sh`
  (**77 assertions**, chained — not discoverable-only). **`untested` ADDED to the evidence axis at
  `observe`** (*has never operated against a live or representative task*, strictly weaker than
  `unvalidated`) **WITHOUT WEAKENING THE GUARD** — every OTHER unrecognised token still takes
  `evidence.derivation_nonvacuity` to **exit 2**, and both halves are driven in the SAME run so
  "recognising one token" cannot be read as "opening a fall-through".
  **Census 90 -> 93; suite 1689 -> 1771 (+82); FINDINGS NUMERATOR UNCHANGED AT 25 — only the
  denominator moved (25 of 93, split 6/5/14, identical to 25 of 90 at base); ZERO
  RE-AUTHORISATIONS.** Grid 25 cells -> 30; **0 of 30 license `execute`, unchanged.**
  **THE CANONICAL FIXTURE WORKS AND IT IS FAITHFUL, NOT PLAUSIBLE-LOOKING.**
  `maint.tripwire_coverage_scan` now carries `refuted` (claim A: detects uncovered behaviour under
  bare `node --test`) AND `supported` (claim B: prevents destructive mutation under the sanctioned
  invocation) **SIMULTANEOUSLY**. qa **independently verified the underlying measurement** rather
  than trusting the stanza: `residue.md` is **1621 B**, `DAMAGED\n` is **8 B**, and the gated arm
  uses **`cmp -s` byte identity — STRONGER than the sha256 the earlier packet claimed**. This is
  the case that nearly caused a demotion **measured to destroy live memory**, now **representable**
  instead of collapsed into one misleading token. **And the registry entry did not move:**
  `class: C`, `empirical_status: red_driven,refuted`, `runtime_authority: gate`,
  `authority_mismatch: declared` — unchanged. The store is **additive and advisory: read by
  nothing that grants authority.**
  **(1) F1 — A LIVE OVER-GRANT INSIDE THE OVER-GRANT DETECTOR.** The packet updated ONE copy of
  `EVIDENCE_AXIS` and the prose describing it, and left a SECOND copy at five tokens in
  `authority-envelope.sh` — **while that file's own header said six**. **AT BASE BOTH AGREED; THE
  PACKET CREATED THE DIVERGENCE.** Demonstrated against the shipped tool, not argued: `axis_cap`
  returns **empty** for `untested`, `rank_of("")` = **-1**, and the `[ "$tr" -ge 0 ]` guard
  **silently drops the strictest token out of the minimum**, so a `gate` grant reads
  **`WITHIN-LICENCE`** when the correct cap is **`observe`** — **OVER-REACHING BY THREE RUNGS,
  INSIDE THE TOOL THAT EXISTS TO CATCH OVER-GRANTS.** Latent only because 0 envelopes are live and
  0 controls carry `untested`. Section 18 was blind because **every assertion in it grepped
  `evidence-policy.sh` and none grepped the tool under test.** The reviewer: *"the strongest thing
  in the diff... found by pointing an assertion at the tool under test instead of at the tool it
  cites."* **Both literal copies verified byte-identical at six tokens at close.**
  **(2) THE FIX COVERS THE CLASS, NOT THE PAIR — A FIRST.** This was the **THIRD** instance of the
  unchecked-duplicate defect (evidence cap table vs README; deployment axis owner vs copy; now the
  evidence axis in the envelope tool), and **the first fix that is not pair-shaped**: every literal
  `<NAME>_AXIS="..."` restatement under `build-os/tools/` must now agree **token-for-token** with
  `evidence-policy.sh matrix`. It sweeps **3** restatements; **a fourth added later is covered with
  nobody remembering.** Red-driven by reverting the one-token fix: **94 passed / 2 failed**,
  restored to **96 / 0**. **THE REVIEWER FOUND TWO COVERAGE LIMITS AND RULED THEM RESIDUE, NOT
  DEFECTS** (no failing fixture exists): a **same-line second assignment**
  (`FOO=1; EVIDENCE_AXIS="bogus"` — the anchored enumerator never sees the second name) and the
  **append form** (`EVIDENCE_AXIS+=" bogus"` — the sweep passes green while the tool composes with
  the appended token). Neither exists in the tree today, so the CHANGELOG's wording is true of it.
  Residue (bbb).
  **(3) A GUARD CAUGHT THE BUILDER'S OWN WORK AND WAS OBEYED, NOT SILENCED.** Section 18's first
  non-vacuity check was `[ "$AXSEEN" -ge 3 ]`; **§21 flagged it as an unregistered fitted floor**,
  pushing the family **37 -> 38**. Registering a floor is a **re-authorisation and out of scope**,
  so it replaced the count with a **NAMED ANCHOR**. The reviewer confirmed the replacement is
  genuinely **stronger**, not merely compliant: *"`-ge 3` is satisfiable by three copies of
  anything, while the named anchor cannot be satisfied by arithmetic and fails closed if the glob
  breaks."* **Family verified back at 37; §10's 34 undisturbed; NO FLOOR REGISTERED.**
  **(4) THE ORCHESTRATOR'S COUNT WAS WRONG AGAIN — FOURTH TIME THIS SEQUENCE.** It reported the
  fitted-floor family at **38**; the repo's rule **excludes `N <= 1` deliberately** (*"the scan
  found at least one thing" is a Class A invariant*), and §21 reports **34 of 37 scanned, 3
  excluded**. **THE BUILDER WAS RIGHT.** Re-derived by the archivist at close: 37 / 34 / 3.
  **RECORD THIS AS A PATTERN, NOT AN INCIDENT: four times in this sequence a BUILDER (or qa)
  derived and corrected a figure the ORCHESTRATOR relayed** — the reviewer's `64 of 90` vs the
  builder's `77 of 90`; the self-tally `7/4` vs qa's `10/3/7`; "first counterfactual" vs qa's
  **second**; and `38` vs `37` here.
  **(5) TWO COUNTERFACTUAL DATA POINTS, NOT ONE.** qa corrected the orchestrator: `DECISION-0008`
  is the **SECOND** recorded decision where a signal disagreed with the human choice, **not the
  first**. `DECISION-0007` already records one — the selected candidate scored **0** on
  `dependency_unlock_count` while `PACKET-0016` scored **1** (snapshots 0001 vs 0004). For
  `DECISION-0008`, `census_growth_controls` is **3** for the selected arm and **0** for all three
  rejected arms — **uniquely worst on the only cost-ranking signal** — and `selection_reason` says
  so **verbatim**, **re-derivable from the recorded signals alone**. **16 frozen snapshots, TWELVE
  of them for arms NOT selected.** Store now at **8 decisions / 71 snapshot rows**. **THE n = 1
  OBLIGATION INHERITED FROM P1 IS DISCHARGED — there are now TWO decisions with a non-degenerate
  candidate set.** **NO ARTEFACT CLAIMS "first"** — verified **absent tree-wide** at close.
  **(6) THE ANTI-LAUNDERING PROPERTY SURVIVED SEVEN ATTACKS.** qa **could not defeat it**. Sharpest
  case: `refuted` in the registry + a `red_driven` assertion -> `effective = observe`; **A
  REFUTATION CANNOT BE OUTVOTED.** It is **STRUCTURALLY UNRAISABLE**, not merely untested —
  composition uses only `-lt`, so `L_effective = MIN(L_class, L_registry_evidence,
  L_assertion_evidence)` can only lower. §8 fabricates a Class-A control the census records
  `refuted`, hands it a `red_driven` assertion licensing `gate` alone, and requires `observe` —
  **checked as an INEQUALITY over the ladder, not a matched string.** **Freeze verified BY
  MUTATION:** adding a control to the source `census_growth_controls` derives from left **all 12
  non-selected snapshot values unmoved**.
  **THE STALE-REFERENCE SWEEP — THE METHOD MATTERS MORE THAN THE NUMBER.** 42 `evidence_refs` went
  stale when four tool headers grew; **every one was repointed by locating its base-commit line
  CONTENT in the current file, NEVER by shifting a number.** One was still missed by hand
  (`tests/mutator_registry_tests.sh:642 -> :643`, which a `while` statement let past the §23
  vacuity guard), so the repointing is now **verified MECHANICALLY**: every `file:line` reference in
  the tree is **paired positionally against its base-commit counterpart and compared by CONTENT**.
  **0 stale pathed refs tree-wide over 338 refs** — and that sweep **caught the reference the
  packet's own new assertions had displaced**. Residue (ddd) proposes it as its own governance
  control.
  **DEFECT-0009, SELF-CAUGHT IN A FILE THIS PACKET AUTHORED:** `claim-evidence.sh --help` printed
  six lines of shell as documentation (`sed -n '2,120p'` over a 114-line header). Bounded to
  `'2,114p'`.
  **VERDICT TRAIL: reviewer PASS — NO FIX LIST, NO FIX ROUND. qa RED, RESOLVED.**
  **DEPTH: 2 SERIAL STAGES — builder, then qa and reviewer CONCURRENTLY. NO STAGE 3.** This is the
  **first packet in this sequence to hold the `substantive` median**; the previous four each ran to
  **four** serial stages.
  **FINAL STATE AT `c653508`: 2 commits (`9474cae` untouched and still an ancestor; `20df098` still
  a live object). Suite 1771 passed / 0 failed; `./build-os/maintenance/run-tests.sh` 144/144;
  `scan-controls.sh check` exit 0; `scan-mutators.sh check` exit 0; `evidence-policy.sh check`
  25 of 93, split 6/5/14; `claim-evidence.sh validate` exit 0 (3 assertions);
  93 controls, 20 declared mismatches, 73 gate / 14 advise / 6 execute / 0 rank / 0 observe /
  0 none; 3 claim-scoped assertions (1 refuted / 1 supported / 1 untested, two of them on the SAME
  subject); 8 decisions; **28** signal snapshots (**CORRECTED 2026-08-01 at the P4 close — this
  line said 71, the same line-count-not-row-count error; `grep -c '^SIGNAL-SNAPSHOT-'` at `c653508`
  returns 28**); 0 live authority envelopes; both `EVIDENCE_AXIS`
  copies byte-identical at six tokens; 0 stale pathed refs tree-wide; tree clean.** All re-derived
  by the archivist at close directly from `control_registry.txt` and the live tools.
  **Both verdicts single-model — NO CODEX IN ANY PASS, for the SEVENTH packet running.**
  `tool_router.md` routes reviewer second-eyes to it and nothing is installed. Residue (zz) already
  says *"Either install Codex or stop declaring the row."* **It is still declared and still
  unbacked.**

## History — `gravito_p1_mutators_ids_telemetry_a`

- **Prior:** `gravito_p1_mutators_ids_telemetry_a`
  (`PACKET-0006-gravito-p1-mutators-ids-telemetry-a`) — **`execute` got its FIRST SIX OCCUPANTS,
  identity stopped being a line number, and the packet recorded the feature vectors of the arms it
  did NOT take** (receipt `build-os/receipts/gravito_p1_mutators_ids_telemetry_a.md`, commits
  `f27c570` + `a75c25e`, base `7daedee`, re-verified `git merge-base a75c25e 7daedee` = `7daedee`).
  **DELIVERED.** The **mutator census** (`build-os/registry/mutator_registry.txt`) — every
  durable-write path in the repository, identified, scoped, and classified on **what it actually
  guarantees** rather than on the check standing next to it, as `MUT-0001`..`MUT-0008`.
  **SIX `execute` OCCUPANTS, THE RUNG'S FIRST EVER:** `maint.rotation_live_file_replacement`,
  `swarm.merge_commit_execution`, `metrics.record.store_append`, `metrics.decision.store_append`,
  `identity.stamp_write`, `tools.handoff_lock_lifecycle`. **Census 81 -> 90**; authority
  **71 `gate` / 13 `advise` / 6 `execute` / 0 `rank` / 0 `observe` / 0 `none`.**
  **STABLE IDS AT BIRTH** — `MUT-*`, `CTRL-*`, `DEFECT-*`, `FINDING-*`, `PACKET-*`, `DECISION-*`,
  `EVIDENCE-*`, `OUTCOME-*`, `SIGNAL-SNAPSHOT-*`, `RANKING-*`. **LINE NUMBERS ARE NAVIGATION HINTS;
  THEY ARE NO LONGER IDENTITY.** IDs are **DERIVED, not ledgered** — a central ledger would be a
  second copy of every id with nothing reconciling the two, which is `DEFECT-0003` itself.
  Plus **`defect_classes.txt`** (twelve recurrent classes, `DEFECT-0001`..`DEFECT-0012`,
  mechanically queryable), **`record-decision.sh` + decision telemetry + frozen signal snapshots**,
  **`governance_baseline.txt`** (pins class/authority/mismatch on all 81 pre-existing controls),
  **`findings.txt`** (`FINDING-0001`/`-0002`/`-0003`, remedies **named and UNAPPLIED**), the new
  suite `tests/mutator_registry_tests.sh` and the new scanner `scan-mutators.sh`.
  **(1) P1 DELIVERS THE COUNTERFACTUAL SUBSTRATE, NOT IMITATION LEARNING — THE FINDING THAT DECIDES
  WHETHER THE SEQUENCE CAN WORK.** `build-os/metrics/signal_snapshots.tsv` carries **12 rows across
  ALL FOUR candidates of `DECISION-0007-p1-mutators-ids-telemetry` — INCLUDING THE THREE NOT
  SELECTED** (`PACKET-0015-mutation-census` selected; `PACKET-0016-citation-identity-anchor`,
  `PACKET-0017-chain-the-live-suite`, `PACKET-0018-ladder-spelling-sweep` rejected) — three signals
  each, **digest-chained**, each naming its `repository_commit` and `derivation_version`. **§9 of
  `tests/mutator_registry_tests.sh` PROVES THE FREEZE EMPIRICALLY:** it reads a historical
  `signal_value`, **materially mutates the live registry the signal derives from**, re-reads, and
  asserts **no movement**. **IMITATION LEARNING NEEDS ONLY THE SELECTED ARM; THIS RECORDS THE
  FEATURE VECTOR FOR THE REJECTED ARMS TOO.** The store's header states the principle: *"A later
  evaluation must never recompute a historical signal against the current tree: that scores a
  decision nobody took, on information nobody had."* And the rows are recorded **unflatteringly to
  the signals**: the selected candidate scored **0** on `dependency_unlock_count` while a candidate
  that scored **1** was not selected. **THE RESIDUE THE REVIEWER ATTACHED, AND P2 MUST ACT ON IT:
  today's training set is ONE decision with a non-degenerate candidate set.** `DECISION-0001` is a
  fan-out where all three were selected; `DECISION-0002`..`-0006` are **|C| = 1**. **P2 AND P3 MUST
  KEEP RECORDING REJECTED CANDIDATES OR P4 STARTS AT n = 1.**
  **(2) THE PACKET COMMITTED THE TWO DEFECT CLASSES IT REGISTERED.** It registered
  `DEFECT-0001-stale-line-reference` and `DEFECT-0008-incomplete-application` and shipped fresh
  instances of both — ultimately in **TWENTY sites across two rounds**. The sharpest: `agency`'s
  `claimed_max_authority` was changed to `execute` on one line while **the next line still read**
  *"Five bindings… The fifth binding"* against a live **11 bindings / 8 instantiating**.
  **Corrected and uncorrected, ONE LINE APART.**
  **(3) THE SWEEP HIT THE DERIVED DOC AND MISSED THE SOURCE ARTEFACT.** Round 1 corrected five stale
  counts in `CROSSWALK.md` and **never swept `neurocosmology_crosswalk.txt` — the artefact
  `CROSSWALK.md` IS DERIVED FROM**, which this packet also edited. **Seven more sites were stale
  there.** The reviewer named the cause **as its own**: *incomplete enumeration*, the same class as
  its item-8 miss.
  **(4) A FIFTH ESCAPE FORM: THE FILE HEADER.** Site seven was `neurocosmology_crosswalk.txt`'s
  **header comment** — *"1 binding out of 22"* (live **23**), *"12 out of 25"* (live **14 of 27**).
  **A HEADER COMMENT REACHES NO FIELD-SCOPED SWEEP.** The catalogue is now: bare `:NNN`; table rows
  naming a file with no line number; line-wrapped enumerations; markdown table-row mappings;
  **header comments**.
  **(5) TWO NUMBERS WERE WRONG WHEN WRITTEN, NOT MERELY STALE — AND BOTH ERRED IN THE FLATTERING
  DIRECTION.** The packet's self-hit tally said **7 shifted / 4 silently wrong**; qa's repo-wide
  census gives **10 shifted / 3 flagged / 7 silently wrong** — **it under-reported its own defect**.
  And `defect_classes.txt` recorded only the occurrences the packet **CAUGHT**, not those it
  **ESCAPED** — in a store whose sole purpose is that `query()` returns a trustworthy count, and
  whose own `OCCURRENCE-0008` states the principle it was violating: *"a caught instance is evidence
  about the class exactly as an escaped one is."* **Both corrected.**
  **(6) THE REVIEWER'S OWN FIGURE WAS WRONG AND THE BUILDER REFUSED IT.** The reviewer wrote
  **"64 of 90"** for the `red_driven` counterfactual; the builder derived **77 of 90** and
  **validated the METHOD rather than asserting it** — run against `7daedee`, the same composition
  **regenerates the reviewer's ORIGINAL sentence verbatim** (*68 of 81, 49 newly, on top of 19*).
  The orchestrator independently reproduced **25 / 77 / 52 / 25**. **A MODEL THAT REGENERATES THE
  PRIOR SENTENCE FROM THE PRIOR ARTEFACT IS THE MODEL THAT PRODUCED IT.** The reviewer **confirmed
  its own error on re-review**; `README.md` now keeps **64** (exactly `red_driven`) and **68**
  (*contains* it) in the same passage, explicitly labelled as answers to different questions.
  **VERDICT TRAIL: qa RED — documentation-only, ZERO TEST FAILURES; reviewer `fix-then-pass` TWICE**
  (11 items, then 6). **Fix rounds: 13 reconciled items in ONE installment, then 7 artefact sites
  closed by the orchestrator in the `tiny` lane.**
  **qa PROVED THE SIX `execute` REGISTRATIONS BY EXECUTION, NOT BY READING:** `swarm-merge.sh
  --commit` created commit `ff2c8ac` in a scratch repo; `record-packet.sh` grew its store **12 -> 13
  rows**; `record-decision.sh` appended. **Stable ids survived a 25-line insertion** — `MUT-0002`
  moved **104 -> 129** and `query` output was **BYTE-IDENTICAL**. **Duplicate ID injection exits 2.**
  **`query(DEFECT-0001)` returns 3 occurrences.** **The baseline drove RED on a flipped authority.**
  Telemetry wrote **20 fields `unknown` with ZERO literal 0s**; exactly **2 `@derived`** values,
  both traced **verbatim** to `packet_metrics.tsv`; **117 unknown cells, NOTHING back-filled**.
  **Appending a 91st control left `signal_snapshots.tsv`'s md5 UNCHANGED.** `build-os/memory/*`
  **byte-identical start and finish**.
  **FINAL STATE AT `a75c25e`: 2 commits (`f27c570` untouched and still an ancestor). Suite
  1689 passed / 0 failed; `./build-os/maintenance/run-tests.sh` 144/144; `scan-controls.sh check`
  exit 0; `scan-mutators.sh check` exit 0; `evidence-policy.sh check` 25 of 90, split 6/5/14;
  90 controls, 20 declared mismatches, 71 gate / 13 advise / 6 execute / 0 rank / 0 observe / 0
  none; class A67 / B3 / C20; implementation_status 76 load_bearing / 9 implemented /
  5 decision_contributing; 8 mutator records; 12 defect classes; 3 findings; 7 decisions;
  12 signal snapshots; 0 live authority envelopes; tree clean.** All re-derived by the archivist at
  close directly from `control_registry.txt` and the live tools.
  **THE 20 DECLARED MISMATCHES SPLIT INTO TWO KINDS AND THE SPLIT IS THE POINT: 14 exercise `gate`
  on an `advise` licence (fitted heuristics, the pre-existing population); 6 exercise `execute` on a
  Class A licence that reaches only `gate` (the durable writes) — OUT OF LICENCE BY CONSTRUCTION,
  because NO CLASS LICENSES `execute`.** Their mismatch is not a defect in the registration; it is
  the registry correctly reporting that **the operator has not decided whether anything may mutate
  under licence**. **ZERO governance-field changes — nothing pre-existing was re-authorised.**
  **Both verdicts single-model — NO CODEX IN ANY PASS, for the SIXTH packet running.**
  `tool_router.md:368` routes to it and nothing is installed. It matters here specifically:
  **finding 6 is a REVIEWER error that only the BUILDER caught.**

## History — `gravito_ladder_semantics_a`

- **Prior:** `gravito_ladder_semantics_a` — **the ladder gained a rung, `observe`
  changed meaning, and NOT ONE CONTROL MOVED** (receipt
  `build-os/receipts/gravito_ladder_semantics_a.md`, commits `576751a` + `d0eff10`, base `2df61ae`).
  On the operator's ruling: **`observe` is redefined by CONSEQUENCE** — *"output may be recorded and
  consumed for visibility; it causes no operational consequence"* — instead of by non-consumption,
  and **`execute` is added as a sixth rung above `gate`** (*"output may directly cause mutation"*).
  **The ladder is now `none < observe < advise < rank < gate < execute`.**
  **THE RESULT HELD EXACTLY AS PREDICTED: 19 of 81, split 6/5/8, UNMOVED.** The packet changed what
  `observe` **means**, not what any control is **licensed to do**. **ZERO governance-field diff
  lines.** **No class licenses `execute`; a test pins that 0 of the 25 grid cells reach it.**
  **SEVEN SEMANTIC SITES, NOT SIX** — the seventh was found while building: `control_registry.txt`
  carried the retired rule in **two live fields** of `maint.source_scan_mask`, including the
  `demotion_requirement` an operator reads **WHILE DECIDING**.
  **`OBSERVE-LB` MOVED OFF THE GATING PATH** — re-keyed to consequence and moved to a new advisory
  channel that prints and counts but never sets the exit code; a genuine violation still refuses at
  exit 2, so only that one check moved. **`autonomous` NOW CAPS AT `execute`** (the axis states a
  CEILING, not a grant, and `L_effective` is a MINIMUM, so it grants nobody anything).
  **THE FINDINGS MATTER MORE THAN THE FEATURE — five of them.**
  **(1) THE CITATION GUARD CHECKS RESOLVABILITY, NOT IDENTITY, and it is quantified.** qa located the
  cause at `scan-controls.sh:368-392`: it tests **existence, numeric, in-bounds, not-blank** and
  **NEVER COMPARES CONTENT**. Of the 27 refs that drifted in the three tools, **27 of 27 would have
  cited a different line**; `VACUOUS-REF` caught **7**; **20 PASSED EVERY CHECK WHILE SILENTLY
  WRONG**. **THE REVIEWER'S COROLLARY, RECORDED BECAUSE IT DISCOUNTS EARLIER CLAIMS: a content match
  at a SINGLE COMMIT tests RESOLVABILITY; only a CROSS-COMMIT comparison tests IDENTITY.** Several
  *"zero drift, 287/287 verified"* results earlier in this sequence were **the former, reported as
  the latter** — true statements of a weaker property than the one claimed. The durable fix is an
  **anchor token or content hash**, not a line number.
  **(2) A PUSHED COMMIT SHIPPED RED, AND THE CLOSE CHECKLIST IS WHY.** qa confirmed `2df61ae` —
  **pushed** — ships `./build-os/maintenance/run-tests.sh` at **143/144**. Cause: the previous
  archivist close cleared `active_packet.md` to **2** `^## ` blocks while the rotation proof needs
  **>=3** (`tests/scaffold_seeding_tests.sh:242`). **That suite is NOT chained into the 1636 and the
  orchestrator's close brief did not ask for it — an ORCHESTRATOR DEFECT, recorded as such.**
  Commit 1 of this packet alone repairs it (2 blocks -> 10). **qa PARTLY REFUTED the sharper
  hazard:** a zero-block file genuinely never rotates and fails nothing (byte-identical after
  `--apply`, exit 0) — **but it is NOT silent**; `rotate-memory.mjs` emits an explicit
  `WARNING: … the block delimiter /^## / matched NOTHING`. **The failure mode is AN IGNORABLE
  WARNING, NOT SILENCE.**
  **(3) THE MUTATION CENSUS — surveyed, reported, ACTED ON IN NO WAY, and the reviewer called it the
  packet's most valuable output.** The sharp case is **NOT at `gate`**:
  `maint.managed_set_replacement` sits at **`advise`** while its declared output is *"files copied
  into an installed repo, replacing prior managed copies"*, failure behaviour *"none that stops
  anything"*, rollback *"none; a managed file's local edits are lost on install"*. **FIVE MODULES
  DURABLY MUTATE — `rotate-memory.mjs` (renames onto the LIVE memory file), `swarm-merge.sh`,
  `record-packet.sh`, the identity hook, `specialist-handoff.sh` — AND NOT ONE OF THOSE WRITE
  ACTIONS IS A REGISTERED CONTROL AT ANY AUTHORITY.** The reviewer's ruling on the packet's own
  defence: *"the controls are checks and the mutations belong to the modules they live in"* is
  **sound as a description of what the registry covers and convenient as a reason not to extend
  it**, and **the most consequential write in the system has no entry**. **IT RULED THIS SHOULD BE
  THE NEXT PACKET.**
  **(4) FOUR ESCAPE FORMS, ALL THE SAME SHAPE** — a guard written against one surface form, blind to
  its siblings: (i) bare `:NNN` citations with the filename elsewhere in the sentence; (ii)
  `MISMATCHES.md` §10's table rows, naming a file with **no line number**; (iii) **line-wrapped
  enumerations** — `none < observe < advise` on one line, `< rank < gate)` on the next, which is how
  a **FIFTH** stale ladder survived in a file this packet had **already edited**, past the
  orchestrator's sweep and the reviewer's first pass; (iv) **markdown table-row mappings** —
  `| shadow | observe | … |` where the new guard expects `-> observe`, so **the new block is
  STRUCTURALLY VACUOUS over `README.md`, the FIRST of its seven listed sites**, proven by rewriting
  that row to carry a consumption clause and watching all three blocks miss it.
  **(5) THE PACKET REPRODUCED ITS OWN HEADLINE DEFECT TWICE.** It found a guard checking the wrong
  property, built §21 to sweep seven semantic sites — and **§21 greps only ONE of the retired rule's
  TWO wordings** (which is why the stale definition survived in the file that OWNS the axis), and
  **its successor block covers one of the mapping's TWO syntaxes**. Both were found by review, fixed
  or recorded, and named in the artefact.
  **§16's COMPLETENESS CLAIM WAS WRONG AND THE WRONG NUMBER IS LEFT VISIBLE ON PURPOSE.** It said
  *"four live places … listed so the packet can prove it found them all."* **It was five.** The
  undercount stays in the record rather than being silently corrected: **a completeness claim that
  turned out false is the strongest available argument for the guard §16 was deferring**, and it is
  the same enumeration-plus-assertion defect the packet had just fixed at item 10.
  **RULINGS TO CARRY.** **The ladder-SPELLING sweep stays DEFERRED** to §16's own packet; the
  reviewer upheld all three grounds (a different site set; the five-rung string is a **PREFIX** of
  the six-rung one, so it needs an enumeration-**CONTINUATION** test, not a containment test;
  bolting a second guard onto a stage-3 round is how fix lists arrive in installments). **What was
  unsound was the deferral's EVIDENCE, not the deferral.**
  **THE `observe`/`advise` BOUNDARY IS NOW INTENT-BASED, NOT MECHANICALLY CHECKABLE.** `gate` has a
  test (*exits non-zero*), `execute` has one (*performs a durable write*), `none` has one (*no
  consuming policies*). **`observe` USED TO have one and no longer does.** **Three of six rungs are
  now separated by the author's assertion alone.** **This was the right trade** — the checkable
  boundary is exactly what made the rung unreachable — **and it is recorded as a COST.**
  **`execute` IS EARNED, NOT ANOTHER EMPTY RUNG.** The reviewer's distinction: **`rank` is
  0-occupancy because nothing in the system ranks — the concept has NO REFERENT. `execute` is
  0-occupancy because FIVE REAL, NAMED, DURABLE MUTATORS EXIST AND ARE UNREGISTERED.** Occupants
  demonstrated by survey.
  **`autonomous -> execute`, with the discarded reading recorded AND answered:** *"an operator
  authorising AUTONOMY did not thereby authorise MUTATION"* — **real but misplaced**, because the
  deployment axis states a **CAP, not a grant**, and MIN means the class axis still withholds
  `execute`. Whether a fifth deployment mode should exist survives as a live question.
  **Census UNMOVED — the correct result for a packet that re-authorised nothing: 81 controls,
  14 declared mismatches, 68 `gate` / 13 `advise` and 0 at `none`, `observe`, `rank` or `execute`;
  class A58 / B3 / C20; `implementation_status` 67 `load_bearing` / 9 `implemented` /
  5 `decision_contributing`; `evidence_refs` 287, all resolving; 0 live authority envelopes.**
  Suite **1636 passed / 0 failed** (was 1617); `./build-os/maintenance/run-tests.sh` **144/144**
  (base was **143/144**); `scan-controls.sh check` **exit 0**; `evidence-policy.sh check`
  **19 of 81, split 6/5/8 — UNMOVED**; tree clean. All re-derived by the archivist at close directly
  from the registry files.
  **Verdict pass as fixed: qa GREEN with 5 findings, NONE FUNCTIONAL; reviewer `fix-then-pass`
  TWICE** (11 items, then 2 findings). **Fix rounds: 13 items in ONE INSTALLMENT** — the builder's
  by-number sweep found 2 beyond the reviewer's 11 — **then 3 prose sites closed by the orchestrator
  in the `tiny` lane.**
  **Both verdicts single-model — NO CODEX IN ANY PASS**, for the **fifth** packet running.
  `tool_router.md:368` routes to it and nothing is installed. **The row is unbacked**, and it matters
  here specifically: the reviewer's resolvability-vs-identity corollary **retroactively discounts
  earlier claims**, which is exactly what an independent second model is for.


<!-- rotation-batch: 2026-08-04T21:17:59Z | source: build-os/memory/current_state.md | blocks: block_16..block_17 (2) | tool: build-os/maintenance/rotate-memory.sh -->

## ARCHIVED BATCH 2026-08-04T21:17:59Z — build-os/memory/current_state.md — 2 blocks (block_16..block_17)

## History — `gravito_p4_s1_shadow_ranker_a`

- **Earlier:** `gravito_p4_s1_shadow_ranker_a`
  (`PACKET-0034-gravito-p4-s1-shadow-ranker-a`) — **THE FIRST EXECUTIVE COMPONENT: A REAL CANDIDATE
  SET IN, AN IMMUTABLE EXPLAINED ORDERING OUT — AND THE FIRST ORDERING IT PRODUCED IS DEGENERATE**
  (receipt `build-os/receipts/gravito_p4_s1_shadow_ranker_a.md`, commits `9742a10` + `af4ce0c` +
  `b9896e0`, base `ce71122`, re-verified `git merge-base b9896e0 ce71122` = `ce71122`).
  **P4 OF THE OPERATOR'S FIVE — THE MILESTONE.** Everything before P4 made Gravito better at
  **preventing a bad action**; P4 is the first component that forms **an explicit, inspectable
  preference among several permissible good actions.** The operator's success condition — *"a real
  candidate set goes in, and an immutable explained ordering comes out"* — is **MET**.
  **THE ID WAS DERIVED AND COLLISION-CHECKED, NOT ACCEPTED FROM A BRIEF.** `PACKET-0034` was taken
  from `active_packet.md` (declared at `9742a10`, before the first implementation edit) and checked
  against every `PACKET-*` in the tree: `decision_telemetry.tsv` allocates `PACKET-0007`..`-0033`
  and nothing else. The P3 close is why this check exists — that brief supplied `PACKET-0020`, an id
  already held by a **rejected** `DECISION-0008` candidate, which would have collided two candidates
  under one key **inside the store S1 now reads**.
  **DELIVERED.** `build-os/metrics/rank-candidates.sh` — **S1**, `heuristic_policy`, class C,
  `untested`, `deployment_mode: shadow`, `output_semantics: ordered_candidates`, composition
  `MIN(advise, observe, observe) = observe` and **registered at exactly that**. Nine required
  outputs: stable candidate ids; frozen snapshots never recomputed; every candidate visible
  including the last-ranked and the refused; per-candidate values; **the DECOMPOSITION, not just a
  total**; self-amendment exclusions printed WITH reasons; the actual selection; `rank_of_selected`;
  **zero dispatch authority**.
  **THE ARTIFACT.** `DECISION-0010-p4-s1-shadow-ranker`, rule `s1-v1`: `PACKET-0032` and
  `PACKET-0033` **excluded** `reason=self_amendment`; rank 1 `PACKET-0027` total 10 (Pareto
  frontier), rank 2 `PACKET-0029` total 4, **rank 3 TIE** `PACKET-0030` and `PACKET-0031` total 3
  each, rank 5 `PACKET-0028` total 1; `selected: PACKET-0027`, `rank_of_selected: 1`;
  `ranking_digest: 2fa876c632bf81088793968a5d76501556fe283dc27ff97aad40459218df81c8`
  **AT `b9896e0`, AND THAT DIGEST NO LONGER REPRODUCES — see below; the ORDERING above does,
  byte for byte.** The digest was byte-identical before and after the fix round, and the
  archivist re-ran the tool at close: exit 0, same digest, and `decision_telemetry.tsv`,
  `signal_snapshots.tsv` AND `residue.md` all **byte-identical by md5 across the run** — the
  dispatch guarantee MEASURED, not asserted.
  **CORRECTED 2026-08-02 AT THE `gravito_p5_outcome_counterfactual_telemetry_a` BUILD, BY
  MEASUREMENT: `ranking_digest` IS A FUNCTION OF THE WHOLE SNAPSHOT STORE, NOT OF THIS
  DECISION.** The emitted body carries `snapshot_chain_head`, which is the digest of the LAST
  row in `signal_snapshots.tsv` — so **appending any snapshot anywhere, for any decision,
  changes every previously published `ranking_digest`.** P5 appended 25 rows, all bound to
  `DECISION-0011`, and `DECISION-0010`'s digest moved to
  `a509eed7ffb50552bcd0778e56a9a3f3cb2408a4fc6f83b3a7f340d27dc0b036` while
  `snapshots_bound_to_this_decision` stayed at **28** and **every rank, total, tie, Pareto
  status, exclusion and `rank_of_selected: 1` is unchanged**. The substantive claim survives;
  the digest was quoted here as a durable reproducible fact and had a shelf life of one
  snapshot append. **The sealed receipt is NOT rewritten — receipts are append-only history —
  and it should be read as recording what the tool produced AT `b9896e0`.** Residue `(cccc)`.
  **Ties are reported, not broken. Excluded candidates stay on the record with reasons. Every absent
  signal is NAMED absent** (5 MISSING, 2 UNINTERPRETED, 6 NEVER-COLLECTED; nothing imputed).
  **Census 97 -> 99; suite 1869 -> 1909 (+40, ALL of it in `tests/mutator_registry_tests.sh`);
  snapshots 44 -> 72 (+28, all bound to this one decision); decisions 9 -> 10; ZERO
  RE-AUTHORISATIONS**, field-anchored across all 99 controls. **`observe` HAS ITS FIRST OCCUPANT
  EVER** — `ranker.s1_shadow_ordering` — not by re-authorising anything but by being the first
  control born there; the rung has been empty since `gravito_ladder_semantics_a` redefined it.
  **THE CANDIDATE SET IS GENUINELY REAL, PROVEN BY CONTENT.** All 12 lettered anchors resolve in
  `residue.md` by CONTENT: `(mm)` literally reads *"an ANCHOR TOKEN or a CONTENT HASH instead of a
  line number"* -> `PACKET-0029`; `(nn)` names `maint.managed_set_replacement`, verbatim
  `PACKET-0030`'s write surface; `(yy)` locates the hole at `tests/mutator_registry_tests.sh` **11**,
  verbatim `PACKET-0031`'s; `(hhh)`-`(lll)` map **1:1** onto `PACKET-0027`'s six write-surface
  tokens. A ranker fed a synthetic set proves nothing; this one was fed the repo's own open work.
  **THE STRONGEST QA RESULT — THE NAMED DEFECT CLASS IS CAUGHT IN CODE.** qa appended a
  **legitimately chained** orphan snapshot naming an undeclared candidate. `snapshot-verify` **PASSES
  it at exit 0** — it really does parse and chain — and the ranker still refuses at exit 2:
  *"snapshot(s) claim decision ... but name candidate(s) the decision does not ... **RESOLVABILITY
  IS NOT IDENTITY**."* That is residue `(mm)`'s doctrine made mechanical inside the executive.
  **FREEZING HOLDS BOTH DIRECTIONS:** gutting `residue.md` leaves the digest identical; editing a
  frozen value in place trips `TAMPERED`, exit 2.
  **`rank_of_selected: 1` IS NON-CIRCULAR, PROVEN BY TIMESTAMPS:** selection anchor at `5c8d19e`
  **21:05:58**; ranker ABSENT at base `ce71122` **21:41:30**; created `af4ce0c` **22:28:34** — **82
  minutes later**. The telemetry row is co-committed with the tool; **the referent is prior and
  independently verifiable.**
  **[CORRECTED 2026-08-02 AT THE P5 CLOSE — THE HEADING ABOVE OVERSTATES ITS EVIDENCE, AND THIS
  FILE HELD BOTH READINGS AT ONCE.** The P5 block above states that commit dates are
  SELF-ASSERTED (`GIT_AUTHOR_DATE`, `GIT_COMMITTER_DATE`) and that the same reasoning which
  refuses a self-reported timestamp refuses them; this paragraph, written a packet earlier, still
  said the elapsed minutes PROVE it. **Two contradictory readings of one piece of evidence inside
  one memory file is the defect this file exists to prevent**, so it is annotated rather than
  deleted — the history of the claim is the point. **WHAT ACTUALLY CARRIES THE CLAIM IS
  STRUCTURAL, NOT TEMPORAL:** the selection was made by a **DIFFERENT AGENT, IN A DIFFERENT
  PACKET, THREE COMMITS BEFORE S1 EXISTED** (`5c8d19e` then `158b5ad` then `ce71122` then
  `9742a10`) — event ordering across independently-motivated work. **The commit COUNT is
  structural; the minutes CORROBORATE and cannot establish.** The builder made exactly this
  substitution during the fix round, and the reasoning is the packet at its best: a packet that
  refuses a self-reported timestamp as constitutive and then quotes a self-reported DURATION as
  proof has contradicted itself inside one artefact. **THE TWO ELAPSED FIGURES IN THE TREE ARE
  BOTH CORRECT AND MEASURE DIFFERENT PAIRS**, reconciled here so a later reader does not read them
  as a contradiction: **79 minutes** is `5c8d19e` to the P4 declaration `9742a10` (the structural
  three-commit gap residue `(kkkk)` cites) and **82 minutes** is `5c8d19e` to the ranker's
  creation `af4ce0c`. Neither is constitutive. Residue `(kkkk)`.]**
  **THE REVIEW'S REAL VALUE IS NEGATIVE AND IT IS RECORDED UNSOFTENED.**
  **(1) THE FIRST ORDERING IS DEGENERATE.** `PACKET-0027` scores the MAXIMUM on all three frozen
  signals and **Pareto-dominates every rival**; the reviewer swept **125 of 125 weight combinations**
  and **every single-signal drop** and all return the same sole winner. **No monotone weighting can
  dethrone it**, so the ordering carries **no information beyond "one candidate dominates"** and the
  10-vs-4 margin is decorative. The reviewer's words: ***a result that survives every perturbation is
  not robust — it is uninformative.***
  **(2) THE MARGIN MEASURES RESIDUE LETTERING GRANULARITY, NOT VALUE.** `(hhh)`-`(lll)` are FIVE
  letters for ONE defect class; re-letter as one item and the margin collapses **10-4 -> 6-5**, and
  dropping the ruling signal as well makes **`PACKET-0029` WIN**.
  **(3) TWO OF THE THREE SIGNALS ARE NOT INDEPENDENT** — a **single sentence** in `residue.md`
  supplies both `residue_items_closed=5` and `residue_ruling_satisfied=1`, two projections of one
  editorial act, weighted 1 and 1.
  **(4) `residue_ruling_satisfied` IS LABEL LEAKAGE** — the recorded `selection_reason` is verbatim
  *"the only candidate a standing ruling names as NEXT rather than as queued"*, so the signal is a
  restatement of the answer. **Agreement obtained that way is not agreement.**
  **(5) BUT `residue_items_closed` IS DERIVED, NOT ASSERTED, AND THE ASYMMETRY PROVES IT:**
  `PACKET-0028` scores **1, not 2**, despite citing two letters, because `(nnn)` says *"AND `(ddd)`
  STAYS QUEUED... do not mark it consumed."* **Fitting would not produce that.**
  **(6) THE OUT-OF-SAMPLE REPLAY, OBTAINED BY THE REVIEWER AND NOT CLAIMED BY THE PACKET.** `s1-v1`
  hand-evaluated on frozen v1 data authored **before S1 existed**, on the two decisions where the
  human went AGAINST the cheap signal, with the scorer validated by first reproducing
  `DECISION-0010` exactly: `DECISION-0008` selected `P0019` -> **rank 1 (tied)**; `DECISION-0009`
  selected `P0023` -> **rank 1 (tied)**; with plausible guard-1 exclusions both become **sole rank
  1**. **TWO CAVEATS, NEITHER OPTIONAL:** those write surfaces are **RECONSTRUCTED, NOT FROZEN** and
  **must NEVER be entered as snapshots** (that is exactly the "recomputed against the current tree"
  defect S1's own `demotion_requirement` names); and **a TIE out-of-sample against a LANDSLIDE
  in-sample is an OVERFITTING SIGNATURE**, recorded BESIDE the positive result rather than under it.
  **(7) GUARD 1 FAILED OPEN ON SPELLING, AND IT TOOK TWO AGENTS TO SEE IT.** qa built four aliases of
  the protected path; **all four reached rank 1** while only the exact literal was excluded — against
  a header claiming the guard *"fails CLOSED"* and is *"deliberately OVER-BROAD in the safe
  direction"*. Fixed: `touches()` now NORMALISES (`./`, `//`, `..`, trailing `/`), wildcards are
  **REFUSED not interpreted** (`guard1_uninterpretable_surface` — expanding one would screen frozen
  evidence against the CURRENT tree), and **`set -f` was added; its absence is why qa saw `EVADE-D`
  RANKED and the builder saw it EXCLUDED — the same tool, different working directory.** All five
  fixtures now excluded; innocent neighbours still rank.
  **(8) GUARD 1's REMAINING BLIND SPOT, DISCLOSED NOT WIDENED.** It screens reachability to the
  PROMOTION MACHINERY but not to the EVIDENCE SUBSTRATE — `record-decision.sh`,
  `signal_snapshots.tsv`, `decision_telemetry.tsv`, `residue.md`. **LIVE, NOT HYPOTHETICAL:
  `PACKET-0029` is ranked 2 in this very ordering and writes `residue.md`, the file
  `residue_items_closed` is DERIVED FROM.** Not widened on purpose: nearly every packet writes
  `residue.md`, so protecting it turns the predicate into a wall. Residue `(zzz)`.
  **(9) THE EXIT CONTRACT WAS FALSIFIED AND IS NOW TRUE.** When guard 1 excluded every candidate the
  tool printed an EMPTY ordering and **exited 0**, against its own header. Now: `ordering: NONE —
  every candidate was refused`, `rank_of_selected: excluded`, **exit 2**, all exclusions still
  printed. Orchestrator-verified live.
  **(10) THE BUILDER FOUND A BUG IN ITS OWN FIRST DRAFT** — `local t="$1" p="${t%%#*}"` expands the
  OUTER `t`, making `touches()` true for everything. Split across two `local` lines with the reason
  in a comment.
  **THE VERDICT ON THE MILESTONE, IN THE REVIEWER'S OWN WORDS:** *"Yes, narrowly and honestly. It
  forms a preference, publishes the decomposition, and refuses to rank its own promotion. It is not
  governance wearing a label. **But the first ordering it produced is degenerate, so the executive
  exists as a MECHANISM before it exists as a DEMONSTRATED CAPABILITY** — and the packet's own
  residue says so."* `rank_of_selected: 1` is **uninformative at n=1** and the tool's own `note:`
  output says so. **No overclaim anywhere in the diff.**
  **DO NOT FIX THE SIGNAL SET. `s1-v2` IS A LATER PACKET** — the operator's ceiling reasoning applies
  to S1's own shortcomings exactly as it applies to governance defects.
  **DEPTH: 3 SERIAL STAGES — builder, then qa ‖ reviewer CONCURRENTLY, then the fix round. NO STAGE
  4.** P3 hit stage 4 and the contract calls that a defect; here **the orchestrator verified the fix
  round itself rather than opening another gate stage.**
  **3 COMMITS — ONE OVER THE <=2 CAP**, same deviation and same reason as P3: the fix round landed as
  its own commit rather than amending a commit the gates had already measured. Recorded, not
  normalised. **The manifest is NOT fully disjoint and says so:** `9742a10` owns
  `active_packet.md` ALONE (intersection with both others EMPTY, `comm -12` verified), while
  `af4ce0c` and `b9896e0` **overlap on all 6 files the fix round touched** — separable by ORDER, not
  by path. Guard convention **12 files / +1281 / -152**; net diff **12 / +1265 / -136**; the row
  records the GUARD's numbers, per residue `(ggg)`: **fix by RECORDING, never by widening.**
  **AN ARCHIVIST FINDING AT THIS CLOSE — THE SNAPSHOT COUNT HAS BEEN THE FILE'S LINE COUNT FOR TWO
  CLOSES.** P1's close recorded **12** and was CORRECT; P2's recorded **71** against an actual **28**;
  P3's recorded **87** against an actual **44** — **an overstatement of very nearly 2x**, in the store
  whose entire purpose is that a later evaluation can trust it. The store carries 43 comment lines
  plus a column header, and both wrong figures are `(total lines - 1)`. **The derivation changed
  between P1 and P2 and nothing noticed.** This is `DEFECT-0003-duplicate-semantic-truth` in its
  COUNTING form — the exact half P3 mechanised for citations and left to hand for counts, which is
  why `PACKET-0027-p3b-count-derivation` exists and why S1 ranked it first. **The sealed receipts are
  NOT rewritten**; both figures are corrected IN PLACE above with the correction visible.
  **FINAL STATE AT `b9896e0`: 99 controls; 77 gate / 15 advise / 6 execute / 0 rank / 1 observe /
  0 none; class A74 / B3 / C22; 20 declared mismatches; `evidence-policy.sh check` 25 of 99 split
  6/5/14; 10 decisions; 72 signal snapshots; 1 mismatch disposition; 3 claim-scoped assertions;
  8 mutator records; 0 live authority envelopes; suite 1909/0; maintenance 144/144;
  `scan-controls`/`scan-mutators` exit 0; exactly ONE file added in the whole range; tree clean.**
  All re-derived by the archivist at close from the registry files and the live tools.
  **SECOND EYES: NONE — TENTH CONSECUTIVE PACKET.** `tool_router.md` was corrected at `ce71122` to
  state plainly that this runtime has never had the capability and to REQUIRE the reviewer to say
  *"second eyes: NONE, single-model"* rather than silently omit it. **The reviewer complied.** Every
  verdict in this entire sequence is single-model.

## History — `gravito_p3_accept_and_constrain_a`

- **Prior:** `gravito_p3_accept_and_constrain_a`
  (`PACKET-0023-gravito-p3-accept-and-constrain-a`) — **A FIFTH DISPOSITION THAT CLEARS NOTHING,
  AND A LEASE WINDOW THAT WAS DECORATIVE AT BOTH ENDS AND WAS REACHING THE LICENCE MATRIX**
  (receipt `build-os/receipts/gravito_p3_accept_and_constrain_a.md`, commits `3bd2ab4` + `e68d931`
  + `ead24bc`, base `f3c5353`, re-verified `git merge-base ead24bc f3c5353` = `f3c5353`).
  **P3 of the operator's five.**
  **NOTE THE ID.** The close brief said `PACKET-0020-…`; that id is **already taken** by
  `PACKET-0020-widen-control-registry-with-claim-fields`, a rejected `DECISION-0008` candidate live
  in `decision_telemetry.tsv`. The canonical id is **`PACKET-0023-…`**, which `active_packet.md`
  declared and which `DECISION-0009` already records as its selected candidate. Using the brief's id
  would have **collided two different candidates under one key inside the store P4 trains on.**
  **FIFTH orchestrator/reviewer figure corrected downstream in this sequence; first one caught by
  the archivist.**
  **DELIVERED.** (1) A fifth mismatch disposition —
  `demote_authority | correct_class | improve_evidence | retire_control | accept_and_constrain` —
  via `build-os/tools/mismatch-disposition.sh`, `build-os/registry/mismatch_dispositions.txt`
  (`DISP-NNNN` stable ids, fourteen required fields) and `tests/mismatch_disposition_tests.sh`
  (chained, not discoverable-only). (2) **A lease window that is finally enforced**: `LAPSED` /
  `NOT-YET-LIVE` in `authority-envelope.sh`, `valid_from`/`valid_until` in `claim-evidence.sh`, plus
  **calendar-valid** date checking.
  **Census 93 -> 97; suite 1771 -> 1869 (+98); FINDINGS NUMERATOR AND FINDING SET BYTE-IDENTICAL TO
  BASE at 25, split 6/5/14 — only the denominator moved (25 of 97); ZERO RE-AUTHORISATIONS**,
  confirmed **twice independently and field-anchored** over **different row sets** (qa 485 rows,
  reviewer 388 rows, same conclusion).
  **THE HEADLINE — THE EXPIRY HALF WAS A LIVE BUG, NOT GOVERNANCE.** At base, an envelope **seven
  months dead** printed **`1 live grant(s)`** and `WITHIN-LICENCE … binding-axis=none`, **exit 0**;
  the **same** dead lease at `deployment_mode: shadow` **dragged a doubly-licensed Class A control
  to `licensed=observe`** via `mode_projection()` **into `evidence-policy.sh`**; and the same record
  **five months before it opened** bound **byte-identically**. **The window was decorative at BOTH
  ends and it REACHED THE LICENCE MATRIX** — not confined to the tool's own report. Root cause: the
  tool format-checked and ordered the dates and **never consulted the clock**; `date` appeared in
  **zero** tools. **qa proved the discriminating direction NUMERICALLY: dead window -> the
  deployment axis binds 0; live window -> it binds 1.** That matters because the **permissive**
  direction is untestable — an ungranted control already defaults to `autonomous`/`execute`, so a
  test written only that way **passes against a fixed tool and an unfixed one alike**.
  **`accept_and_constrain` IS INERT BY CONSTRUCTION.** **Nothing in the tree reads
  `mismatch_dispositions.txt` except its own tool and its own suite** — `scan-controls.sh` §8 and
  `evidence-policy.sh check` **never open it**. `maint.tripwire_coverage_scan` still carries its
  mismatch, its table row, and its place among the **25** findings. **NOT BULK-APPLIED: 1
  disposition against 20 declared mismatches.** `maint.source_scan_mask` is correctly **REFUSED at
  exit 2** on **three independently-failing conditions**, and the reviewer proved the predicate
  **discriminative against a SECOND unqualifying subject the builder did not choose**
  (`swarm.disjointness`) — a predicate tested only against its author's own negative case is fitted
  to it; this one is not.
  **DEPTH DEFECT: 4 SERIAL STAGES, RECORDED AS A DEFECT.** builder -> qa ‖ reviewer -> fix round ->
  targeted re-review. **NOT "the fix list arrived in installments"** — the second round's items did
  not exist or were unreachable before `ead24bc` edited those records, and one is a hole in a guard
  that did not exist at `e68d931`. **It WAS a mis-cut, in MECHANISM rather than scope:** P3
  mechanised **one half** of `DEFECT-0003-duplicate-semantic-truth` — the **citation** half, via
  §27 — and left the other half, **counts stated in two places**, **entirely to hand**. The commit
  message correctly diagnoses *"the denominator was re-derived at 97 and the numerator was not"* and
  **then reproduces that exact shape three more times in the records it touched.** **Stage 5 was NOT
  opened**; the remainder is **re-cut as `gravito_p3b_count_derivation_a`**, which the reviewer
  explicitly endorsed — **the contract's own remedy, not a deferral of convenience.**
  **DECISION-0009 recorded 4 candidates and 16 frozen snapshots (12 for non-selected arms), and it
  is the SECOND CONSECUTIVE decision where selection went AGAINST the cheap signal** — the chosen
  arm is the **most expensive** on `census_growth_controls` (**4** vs **0** for the rejected
  registry-field arm). **That is precisely the counterfactual substrate P4 needs:** a ranker trained
  only on decisions where the cheap arm won learns to be a cost function. **n=3** non-degenerate
  decisions now, **two of them human overrides of the cheapest arm with a stated reason.**
  **P2's SEALED RECEIPT IS BYTE-IDENTICAL TO BASE, AND GIT ATTESTS IT.**
  `gravito_p2_claim_scoped_evidence_a.md` appears in **both** `e68d931` and `ead24bc`, yet the net
  diff against `f3c5353` is **EMPTY**. `e68d931`'s repoint sweep reached into a sealed receipt and
  corrupted the arrow-pair `:642 -> :643` into `:643 -> :643` — **a repoint asserting nothing had
  moved, which destroys the record of the defect the pair exists to document** — and `ead24bc`
  restored it exactly.
  **FINAL STATE AT `ead24bc`: 3 commits (ONE OVER THE <=2 CAP — the stage-3 fix round landed as its
  own commit rather than amending a reviewed one; the right call and still a deviation, and it is
  downstream of the depth defect). 97 controls; 76 gate / 15 advise / 6 execute / 0 rank / 0 observe
  / 0 none; 20 declared mismatches; `evidence-policy.sh check` 25 of 97 split 6/5/14;
  1 mismatch disposition; 3 claim-scoped assertions; 9 decisions; **44** signal snapshots
  (**CORRECTED 2026-08-01 at the P4 close — this line said 87, which was the FILE'S LINE COUNT minus
  one, counting the store's 43 header comment lines as data. `grep -c '^SIGNAL-SNAPSHOT-'` at
  `ead24bc` returns 44. See finding A of `build-os/receipts/gravito_p4_s1_shadow_ranker_a.md`**);
  0 live
  authority envelopes; `./build-os/maintenance/run-tests.sh` 144/144; tree clean.** All re-derived
  by the archivist at close from the registry files and the live tools.
  **THE SUITE WAS RED AT HEAD UNTIL THIS CLOSE RECORDED ITS OWN METRICS ROW — 1865/4, NOT 1869/0.**
  Three of the four failures were `check-adoption.sh` refusing at exit 2 (`metrics_adoption` 2,
  `lane_declaration` 1) because **this packet had no `packet_metrics.tsv` row yet**; the fourth was
  **the archivist's own receipt** violating the arrow-pair convention (see below). **All four are
  closed by this close.** **The close writes into the tree, so the close can break the build — third
  packet running.**
  **THE ARCHIVIST COMMITTED THE EXACT DEFECT THE PACKET'S OWN DOCTRINE PREDICTED, ONE EDIT LATER.**
  The receipt wrote a **historical** range **with its path** (the superseded span `:362-386` written WITH its path, alongside
  the live `:368-392`), which §27d correctly read as **2 contradicting range citation pairs**.
  Isolated by measurement, one variable: **with the receipt 98/1, without it 99/0.** Fixed by the
  packet's own convention — **write the superseded span WITHOUT its path**. Residue (mmm) is exactly
  this: **the convention is not a mechanism, and it is one edit from silent violation.**
  **Both verdicts single-model — NO CODEX IN ANY PASS, for the NINTH packet running**, and the
  reviewer's own two prescriptions (`:643 -> :644`, `:572-574`) were **overridden by the builder on
  evidence, in writing, and the builder was right both times.** Residue (zz)'s streak counter said
  **six** and was **itself stale**; corrected to **nine**.


<!-- rotation-batch: 2026-08-05T22:01:24Z | source: build-os/memory/current_state.md | blocks: block_16..block_24 (9) | tool: build-os/maintenance/rotate-memory.sh -->

## ARCHIVED BATCH 2026-08-05T22:01:24Z — build-os/memory/current_state.md — 9 blocks (block_16..block_24)

## History — `gravito_p5b_citation_anchor_tokens_a`

- **Closed before that:** `gravito_p5b_citation_anchor_tokens_a`
  (`PACKET-0029-citation-anchor-tokens` — **REUSED, not minted:** it is the id `DECISION-0011`
  already carries for this candidate in its own `candidate_ids` column, and the id `DECISION-0010`
  carried before that. Collision-checked at close against every `PACKET-*` token in the tree:
  within the live band `PACKET-0001`..`PACKET-0034`, **every occurrence of `PACKET-0029` resolves
  to the same slug** and no second candidate holds it. **Reuse is identity preserved, not a
  collision.**) **CLOSED 2026-08-02. VERDICT: PASS-AS-FIXED** — qa returned GREEN, the reviewer
  returned `fix-then-pass` on **7 enumerated items**, and all 7 were fixed and verified by the
  orchestrator rather than by opening a fourth gate stage.
  Receipt `build-os/receipts/gravito_p5b_citation_anchor_tokens_a.md`.
  Base `c2d97f8` (re-verified at close: `git merge-base fbd746d c2d97f8` = `c2d97f8`), commits
  `df9f740` (build) + `c76b4d0` (memory) + `fbd746d` (fix round). **None pushed.**
  **THIS IS THE FIRST COMPLETED PROSPECTIVE EXPERIMENT IN THIS REPOSITORY, AND THE ORDERING OF
  THE THREE ACTS IS THE RESULT:** the ranking was **sealed** at `44b0fab` before any selection
  could exist, the **selection** was recorded at `c2d97f8` by the **operator**, and **execution**
  followed. `PACKET-0029` was ranked **rank 1** by S1 over a candidate set nobody had yet chosen
  from, then selected, then executed.
  **THE EXPERIMENT IS INTACT AND WAS VERIFIED TO THE BYTE AT THIS CLOSE, NOT RESTATED:** the S1
  report at HEAD digests to sha256 `e838284e2bba5262...`, **identical to qa's independently
  recorded base-run literal**; `rank_of_selected: 1` still derives at exit 0; and
  `build-os/metrics/rank-candidates.sh` is the **same blob `5543ea88`** at the seal, at the
  selection and at both execution commits.
  **AND THE CLAIM IS RECORDED AT ITS TRUE WIDTH: ONE SELECTED RANK IS NOT EVIDENCE OF S1 SKILL.**
  It is a single observation, by a selector who had read the ordering. The narrower true claim is
  worth more: **the first candidate S1 ranked first has now been executed and closed, so the
  ordering has begun to be falsifiable by outcome — and has not yet been falsified.**
  **WHAT SHIPPED — IDENTITY IN, POSITION OUT.** Resolution is by CONTENT: the literal must occur
  EXACTLY ONCE in its artifact (0 -> `ANCHOR-UNRESOLVED`, 2+ -> ambiguous, both violations), and
  **the line number is a return value of `anchor_resolve()`, computed at every resolution and
  stored nowhere.** qa proved no field holds a position and that an 11-field record is refused as
  `ANCHOR-SCHEMA`, so no overflow field can smuggle one in. The written form `path:line#ANCHOR-ID`
  grades its two halves SEPARATELY — a wrong `#` half is a **refusal**, a stale `:` half is a
  **report with the corrected projection printed beside it**. **That is precisely the
  resolvability/identity split this tree had failed to make for twelve packets.**
  **13 anchor records, 12 live object types** (`section_anchor` carries a superseded pair), all
  twelve **claimed by a live anchor** rather than merely enumerated; 12 resolved, 1 superseded,
  0 violations. `anchors_check` is wired on the `check` path OUTSIDE the `anchors` early-exit and
  **qa proved by MUTATION that it cannot be skipped** — renaming one anchored literal drove
  `check` to exit 2.
  **RULE 8 IS THE ONE THAT MATTERED, AND IT IS SELF-REFERENTIAL:** the packet moved lines its own
  sealed evidence cites and did not invalidate the experiment measuring it. Test 28h drives
  `ANC-0012` across a real drift of **924 -> 1189 caused by this very commit**, asserting the old
  position no longer carries the content and the anchor absorbed it. **Executed, not arranged.**
  **BUT THE DISTINCTION THE PACKET CONFLATES IS RECORDED HERE: the scheme property is real; the
  ZERO-REPOINT RESULT into `scan-controls.sh` is MANUAL.** Six net-zero edits, *"none of them how
  the code would otherwise be written"*, and the proof is in the same diff — the identical
  situation in `tests/control_registry_tests.sh` had no net-zero option and cost 3 repoints.
  **It will not survive the next packet.**
  **THE FINDING THAT NEARLY VOIDED THE EXPERIMENT.** `(pppp)` originally defended the packet with
  a FALSE sentence — *"none of the four is anywhere near guard 1's protected set"*.
  `build-os/registry/neurocosmology_crosswalk.txt` **IS one of the six entries of
  `PROTECTED_SURFACE`**, protected as `...#ranker.s1_shadow_ordering`, **and this packet wrote to
  it** — and `touches()` matches a BARE PATH against a protected `path#object`. Had the sealed
  surface said the bare path, guard 1 would have **FIRED**, `PACKET-0029` would have been excluded
  as `self_amendment`, **there would have been no rank 1 and the experiment would be VOID.** It
  said `#registry.evidence_resolution`, guard 1 did not hit, and rank 1 stands. The
  object-granularity reading is correct — the seal itself wrote `control_registry.txt` at object
  granularity and the crosswalk record carries the identical key — and the protected property was
  **never violated in fact**: `ranker.s1_shadow_ordering`'s `evidence_refs` point only into
  `rank-candidates.sh`, which has **zero diff**. **BUT THE CONVENTION DECIDING WHETHER THE
  EXPERIMENT IS VOID WAS WRITTEN DOWN NOWHERE.** It is open item `(uuuu)`, deliberately NOT
  closed: amending guard 1's contract is the self-amendment guard 1 exists to prevent. **That is
  this packet's most important governance finding — a convention that can void an experiment must
  not live only in an agent's judgement.**
  **THE SCOPE RULING, RECORDED BECAUSE THE OPERATOR ASKED FOR IT DIRECTLY: MECHANICAL
  CONSEQUENCE, NOT SCOPE GROWTH; THE EXPERIMENT IS NOT COMPROMISED.** Every off-surface write is a
  DERIVED value reconciled by a live guard, forced by adding exactly one census entry: registry
  `README.md` (evidence_refs 345 -> 355, live 355), `neurocosmology_crosswalk.txt` (bindings 101 =
  census 101), `CROSSWALK.md` (coverage 32/15 -> 33/16, live 33), `CHANGELOG.md` and this file
  (the suite total), `active_packet.md` (the declaration). **0 new files, 0 stores, 0 tools, 0
  suite files.** **DECISIVE FOR THE ARITHMETIC:** `candidate_write_surface` is declared a
  `SURFACE_SIGNAL` and is **deliberately excluded from `SIGNAL_DIRECTION`** — it contributes
  **ZERO POINTS**. The rank-1 score came from `residue_items_closed`, `residue_ruling_satisfied`
  and `census_growth_controls`, so **the overrun could not have moved the score.** Sealed signals
  honoured: `residue_items_closed=2` (both `(mm)` and `(nnn)` annotated),
  `residue_ruling_satisfied=0`, `census_growth_controls=1` — **one control, not
  one-plus-consequences**: exactly one `+control:` line, `registry.evidence_resolution`, Class A /
  `gate` / `authority_mismatch: none`.
  **AND THE ORCHESTRATOR'S OWN DEFECT, RECORDED WITH PROVENANCE AND NOT SOFTENED.**
  `active_packet.md` declared `residue_items_closed=1` from its first commit; **the sealed value
  is 2.** It was not a typo and not the builder's arithmetic — **the orchestrator's brief stated
  `1` and the file INHERITED it.** That is `DEFECT-0002-stale-remembered-count`, committed **in
  the artefact that declares the sealed scope** — the one place a number must be resolved rather
  than remembered — **and inside a brief whose own instruction was "DERIVE every count; never
  restate one."** **The defect class demonstrated itself one level up, inside the packet built to
  end it.** The fix round DERIVED the value rather than copying the correction, and **kept the
  wrong digit visible in a provenance record in `active_packet.md`** rather than silently
  correcting it. **That provenance record is preserved by this close and must not be tidied
  away** — a count repaired by overwriting leaves no trace of how it got in, and the trace is the
  only part that generalises.
  **THE IRONY BELONGS IN THE RECORD: THE ANCHOR PACKET DECLINED TO FIX THREE STALE LINE
  REFERENCES.** `DEFECT-0001`, `DEFECT-0003` and `DEFECT-0002` (`CROSSWALK.md` prose *"29
  bindings, 14 instantiating"* against a derived 33/16) were all found, all pre-existing, all
  inside `evidence_refs` prose of entries this packet edited — and all deliberately left.
  **Correct disposition under the ceiling:** the packet is frozen evidence in a live measurement,
  and repairing defects mid-measurement is exactly the failure the decision arm tests for.
  **AND THIS PACKET MOVED ONE OF THEM FURTHER OUT OF DATE.** Section 20's assertion went
  919 -> 1189, so `DEFECT-0001`'s cited `:772` is now wrong by **417** lines instead of 147 and
  `DEFECT-0003`'s cited `:774` by **415** instead of 145. Mitigated — `ANC-0012` anchors precisely
  that assertion — **but the anchor packet caused it.** `(vvvv)`.
  **`(mm)` WAS RE-HEADED** to *"A DOWN PAYMENT IN MECHANISM — NOT DISCHARGED, AND NOT MIGRATED"*,
  matching its own body: **13 anchors against 355 still-positional `evidence_refs` — 3.5%
  coverage.** The reviewer's ruling: a down payment labelled a down payment. **`(ddd)` STAYS
  QUEUED**, verified at 3 sites — it queues a **cross-commit** comparison and everything here
  resolves against the artifact at the current commit; **do not mark it consumed.**
  **TRAJECTORY (reviewer): *"a bridgehead rather than a twelfth mechanism."*** Held at true width:
  today it IS a twelfth mechanism at 3.5% coverage — but the **first that can express the failure
  at all**, since the eleven positional checks have no vocabulary for object identity. The
  distinguishing evidence is the **refusal**: *"converting the census to it would be a
  re-authorisation of every entry's evidence and is not a builder's to take."*
  **qa's TWO LABEL CORRECTIONS, now written with exact commands:** "maintenance 144/144" names
  `bash build-os/maintenance/run-tests.sh`; `bash tests/build_os_maintenance_tests.sh` is **67/0**.
  And `snapshot-verify` is a **`record-decision.sh`** subcommand —
  `rank-candidates.sh snapshot-verify` exits 2 `unknown command`.
  **THE BUILDER REFUSED TO CERTIFY ITS OWN DIGEST MATCH:** *"I do not hold qa's base sha256
  literal, so the re-review should compare that digest against its own recorded value rather than
  take a match on my word."* **It could have asserted it and been right.** An agent distinguishing
  what it VERIFIED from what it BELIEVES is the discipline this sequence exists to build.
  **SECOND EYES: NONE — TWELFTH CONSECUTIVE PACKET.** The reviewer stated it, as the router
  requires. `build-os/memory/tool_router.md`'s second-eyes row still says *"the last nine"*; it is
  **twelve**. Nothing in the suite pins that literal, so it is presentation staleness of the same
  `DEFECT-0002` shape rather than a red gate; the remedy is one builder-lite line and editing the
  router is a **routing act rather than bookkeeping**, so it is named and not applied. `(zz)`.
  **DEVIATION, RECORDED AND NOT NORMALISED: 3 commits against the `<=2` cap**, flagged in
  `active_packet.md` rather than squashed. The fix round landed as its own commit rather than
  amending commits the gates had already measured.
  **FINAL STATE AT `fbd746d`, ALL RE-DERIVED BY THE ARCHIVIST AT CLOSE FROM THE REGISTRY FILES AND
  THE LIVE TOOLS: 101 controls; 78 gate / 15 advise / 7 execute / 1 observe; class A76 / B3 / C22;
  21 declared mismatches (HELD); 13 anchor records over 12 declared object types, 12 resolved and
  1 superseded, 0 violations; 11 decisions; 97 signal snapshots BY ROW COUNT (176 file lines — the
  row count is `grep -c '^SIGNAL-SNAPSHOT-'`, never `wc -l`); 25 of those bound to `DECISION-0011`;
  9 mutator records; 0 live authority envelopes; suite 1995/0 exit 0 with zero `^  FAIL` and no
  chained failures; maintenance 144/144 and 67/0; `scan-controls check` / `scan-controls anchors` /
  `scan-mutators` / `check-adoption` all exit 0; `snapshot-verify` 97 verifying at exit 0; ZERO
  files added in the whole range; ZERO re-authorisations (6 `+` lines, 0 `-` lines, field-anchored);
  tree clean.**
  **OPEN, AND NOT THE ARCHIVIST'S TO CLOSE: nothing is pushed, merged, tagged, PR'd or deployed.**
  `c2d97f8` is the **selection anchor** and `44b0fab` is the **seal anchor**; **neither may be
  amended**, and neither may `df9f740`, `c76b4d0` or `fbd746d`.

## History — `gravito_p5_outcome_counterfactual_telemetry_a`

- **Previously closed:** `gravito_p5_outcome_counterfactual_telemetry_a`
  (`PACKET-0032-p5-outcome-counterfactual-telemetry` — REUSED, not minted: it is the id
  `DECISION-0010` already carries for this work, collision-checked against every `PACKET-*` in
  the tree, because a fresh id would put two candidates under one key inside the store S1 reads).
  **CLOSED 2026-08-02. VERDICT: PASS-AS-FIXED** — the reviewer returned `fix-then-pass` on 3
  enumerated items and all 3 were fixed and verified live by the orchestrator.
  Receipt `build-os/receipts/gravito_p5_outcome_counterfactual_telemetry_a.md`.
  Base `80ad634` (re-verified at close: `git merge-base adef6ad 80ad634` = `80ad634`), commits
  `cda95d2` (declaration) + `44b0fab` (build) + `adef6ad` (fix round). **None pushed.**
  **`44b0fab` IS THE SEAL'S ANCHOR AND MUST NOT BE AMENDED** — the ordering's entire
  before-the-selection claim is that it was committed before any commit could carry a selection.
  **P5 OF THE OPERATOR'S FIVE — AND THE LAST OF THEM.**
  **THE POINT OF P5, AND IT IS NOT ANOTHER SUPPORTING PACKET.** P4 built the executive
  MECHANISM and its capability is UNDEMONSTRATED. P5 makes the transition from *decision already
  made -> S1 reconstructs a ranking* to *S1 ranks FIRST -> human chooses -> outcome occurs*.
  **THE HARD REQUIREMENT, MECHANICALLY ENFORCED: `ranking < selection < execution`.** Five
  refusals in `record-decision.sh`, each driven red on its own fixture:
  `seal-ranking` REFUSES while the decision already carries a SELECTION row
  (`RANKING-AFTER-SELECTION`); `record` REFUSES a selection whose candidate set differs from the
  sealed one (`SET-CHANGED-AFTER-SEAL`) and REFUSES to carry an outcome at all
  (`OUTCOME-FIELD-IN-SELECTION`); `outcome` REFUSES while the decision has NO selection row
  (`OUTCOME-BEFORE-SELECTION`).
  **AND THE SEAL HAD A SECOND, UNGUARDED DOOR — FOUND BY THE REVIEWER, CLOSED IN THE FIX ROUND.**
  `seal-ranking`'s guard reads `decision_telemetry.tsv`, but the field it protects lives in
  `signal_snapshots.tsv`, and the generic `snapshot` writer accepted **any** `--signal-name`.
  A hand-written `sealed_rank` row for a decision that already carried a selection was accepted,
  **chained cleanly, and left `snapshot-verify` reporting every row as verifying** — so unlike the
  disclosed delete-and-re-add route it produced **no evidence at all**, while moving
  `prospective_decisions_with_a_recorded_selection` from 0 to 1 on the live stores. TWO STORES,
  ONE GUARDED DOOR. `snapshot` now REFUSES every one of the six declared ranker-evidence field
  names (`RANKER-FIELD-VIA-SNAPSHOT`) and names `seal-ranking` as the one door; the check is on
  the FIELD NAME, so a seventh ranker field added later is closed by the same line. `seal-ranking`
  also REFUSES an ordering that gives one candidate two ranks (`CANDIDATE-RANKED-TWICE`), which
  previously sealed only the first rank while printing the contradiction back — receipt and chained
  evidence disagreeing about the same ordering.
  **WHAT THE EVIDENCE ESTABLISHES AND WHAT IT DOES NOT — stated in the code, not implied away.**
  CONSTITUTIVE: the EXISTENCE ORDER of a row across two stores at the instant of each write, with
  the seal landing in the digest-chained snapshot file where every later row covers it.
  CORROBORATING and worth much less: the ISO-8601 strings, compared only because a contradiction
  is always wrong, never because agreement is proof. OUTSIDE BOTH IS GIT, AND IT ANCHORS **ORDER**
  AND NOTHING ELSE: the seal is committed before any commit can carry its selection, and the
  parent-hash chain makes that order non-forgeable — **but only once a third party has witnessed
  it, and this branch is unpushed**, so the anchor is UNWITNESSED rather than proven. **It anchors
  order, NOT INDEPENDENT AGENCY:** committer identity and both commit dates are self-asserted, and
  the same reasoning that refuses a self-reported timestamp refuses them. P4's non-circularity never
  rested on git identity — it rested on a selection made by a DIFFERENT AGENT in a DIFFERENT PACKET
  before the ranker existed, and **P5 has nothing comparable until somebody actually selects from
  `DECISION-0011`.** Residue `(kkkk)`. **A timestamp that
  PARSES is not a timestamp that PROVES ORDERING**, which is this tree's named recurring trap one
  level up.
  **THE SEALED PROSPECTIVE ORDERING — `DECISION-0011-p5b-next-after-p3b`, rule `s1-v1`, sealed at
  `80ad634` over 20 frozen v2 snapshots, and THE DECISION HAS NO ROW IN `decision_telemetry.tsv`
  BECAUSE NOBODY HAS SELECTED YET:** `PACKET-0033` **excluded** `reason=self_amendment`; rank 1
  `PACKET-0029` total 4, **rank 2 TIE** `PACKET-0030` and `PACKET-0031` total 3 each, rank 4
  `PACKET-0028` total 1 (`dominated_by=PACKET-0029`). **IT IS NOT DEGENERATE — THREE candidates
  sit on the Pareto frontier**, against DECISION-0010's single dominator that 125 of 125
  weightings returned. The weights would actually matter here, which is the first time that has
  been true.
  **THE OUTCOME ARM — `DECISION-0010` / `PACKET-0027`:** `result: in_flight` recorded; **3 of 19
  declared outcome fields carry a value, 4 are MISSING, 12 are NEVER-COLLECTED**, each category
  DERIVED from the store rather than remembered, and **every recorded value is UNINTERPRETED**
  because no outcome field in this repository has a declared direction and inventing one would
  put an unregistered constant inside every later ordering.
  **THE SEPARATION IS A PARTITION, NOT A CONVENTION.** Every telemetry column belongs to exactly
  one of the SELECTION set (8) and the OUTCOME set (19); the partition is checked against the
  schema at run time and fails closed on an unowned or double-owned column; a third set —
  `rank_of_selected`, `ranking_agreement`, `ranker_skill`, `ranking_digest`,
  `counterfactual_regret`, `sealed_rank` — OWNS NO COLUMN and is refused by both write paths.
  `outcome-report` publishes `prospective_decisions_with_a_recorded_selection: 0` — **DERIVED** —
  and states that that number, not any prose, is the only thing that could ever make
  `rank_of_selected` evidence about S1.
  **CEILING: 0 new stores, 0 new validator tools, 0 new suite files, 0 new primitives. ONE
  DECLARED EXCEPTION — one census control** (`metrics.decision.outcome_update`, 99 -> 100) and
  with it the **21st declared mismatch**, which P4 avoided and this packet could not: the outcome
  amendment is an in-place row rewrite, MUT-0006 declares in its own `write_scope` "never an edit
  to an existing one", and leaving that sentence standing would have been a knowingly-false census
  entry. The justification is executed, not argued: `scan-controls.sh` refused it as `LAUNDERED`
  and `UNREPORTED` until the mismatch was declared and reported.
  **Suite 1909 -> 1963 (+54, ALL in `tests/mutator_registry_tests.sh` section 14, 93 -> 147 — 43
  at the build, 11 more in the fix round);
  census 99 -> 100; declared mismatches 20 -> 21; out-of-licence 25 -> 26; snapshots 72 -> 97
  (+25, all bound to DECISION-0011); decisions 10 (UNCHANGED — the prospective decision
  deliberately has no row); ZERO RE-AUTHORISATIONS** (no `runtime_authority`, `required_authority`,
  `class`, `empirical_status` or `implementation_status` line was removed from any existing
  control; the only additions belong to the new entry).
  **THE HEADLINE DEFECT, AND IT WAS IN THIS PACKET'S OWN HEADLINE GUARD.** `seal-ranking` refused
  a post-hoc seal correctly, and the `snapshot` subcommand was A SECOND, UNGUARDED DOOR TO THE
  SAME SIGNAL. The reviewer's EXECUTED reproduction wrote a `sealed_rank` row for the
  already-selected `DECISION-0010`; it CHAINED CLEANLY, `snapshot-verify` reported 98 snapshots
  verifying, and `prospective_decisions_with_a_recorded_selection` moved **0 -> 1** — the exact
  figure this packet publishes as the ONLY thing that could ever make `rank_of_selected` evidence
  about S1. **A permanently retrospective decision converted into a prospective one through a
  sanctioned tool path, leaving NO TRACE.**
  **WHY BOTH GATES WERE RIGHT, AND THIS IS THE LESSON WORTH KEEPING.** qa attacked the ordering
  guard exhaustively and its reasoning was CORRECT: direct TSV writes CAUGHT (the guard reads
  store STATE, not tool provenance), casing CAUGHT, reseal CAUGHT, out-of-band edits CAUGHT,
  `SET-CHANGED-AFTER-SEAL` and `TIMESTAMP-CONTRADICTS-ORDER` both fire, and only the DISCLOSED
  delete-then-re-add route works. But it read `decision_telemetry.tsv` for selection rows while
  `sealed_rank` lives in `signal_snapshots.tsv`. **TWO STORES, ONE GUARDED.** The INVARIANT was
  *"a ranking cannot be sealed after a selection"*; the IMPLEMENTATION was *"a selection row
  cannot precede a seal IN THIS FILE."* **Those read identically until somebody writes to the
  other file.**
  **FIXED AND GENERALISED:** `RANKER-FIELD-VIA-SNAPSHOT` is keyed on the tool's own
  `RANKER_FIELDS` constant, so all SIX ranker fields are refused through `snapshot` and **a
  seventh declared later is closed by the same line**. Orchestrator-verified live — `sealed_rank`,
  `rank_of_selected`, `ranking_agreement`, `ranker_skill`, `ranking_digest`,
  `counterfactual_regret` all exit 2 with the stores byte-identical after every attempt
  (`cmp -s`). **Not over-broad:** `candidate_write_surface` still writes through `snapshot` and
  `seal-ranking` still writes `sealed_rank` through the shared primitive. **The refusal sits on
  the CLI door, not on the chaining rule.**
  **THE PERIMETER STATEMENT WAS WRONG, NOT MERELY INCOMPLETE, AND WAS CORRECTED.** The header
  said *"tamper-EVIDENT against the realistic case"*. Delete-and-re-add breaks the chain and IS
  evident; this route left the chain verifying and produced NO evidence at all. It now states
  that **the perimeter is the TOOL, not the files.**
  **AND `CANDIDATE-RANKED-TWICE`:** an ordering giving one candidate two ranks was ACCEPTED —
  only `rank=1` entered the digest chain while the printed `sealed_ordering:` echoed the
  contradiction back, so **the receipt and the chained evidence described different orderings.**
  Now refused during the PARSE, before any append; the store directory is empty afterwards, so
  nothing half-sealed enters the chain.
  **THE PARTITION IS THE STRONGEST THING IN THE PACKET. 8 selection + 19 outcome = 27 = EVERY
  COLUMN**, set-equal, verified by construction AND by driving it: `assert_partition` fails
  closed in **all three** directions (unowned column, double-owned column, ranker field promoted
  to a column). Six ranker fields own no column; **12/12 refusals across both paths**.
  `sealed_rank` is reported `UNINTERPRETED` **live and derived, not hardcoded** — **a ranker
  cannot score a candidate on the rank it gave it.**
  **CATEGORIES ARE DERIVED, PROVEN BY PERTURBATION:** giving an UNRELATED decision a `model_calls`
  value shifted `DECISION-0010`'s own report NEVER-COLLECTED **12 -> 11** and MISSING **4 -> 5**
  without touching it. **`wc -l` appears nowhere in `record-decision.sh`** — the `(aaaa)`
  discipline is live in code, and the snapshot store is **97 ROWS but 176 LINES**.
  **SECTION 14 IS RED-DRIVEN, PROVEN BY MUTATION:** deleting the `RANKING-AFTER-SELECTION`
  refusal drives the suite to **135/1**, *"RED FAILED: the order is documentation, not
  enforcement"*. Removing EITHER `OUTCOME-BEFORE-SELECTION` guard alone keeps it green —
  **defence in depth, not a coverage gap.**
  **THE CEILING HELD STRUCTURALLY, NOT RHETORICALLY:** `git diff --diff-filter=A` returns **no
  new files at all**; the residue diff has **0 removed lines**, purely additive; and
  `build-os/metrics/rank-candidates.sh` is an **IDENTICAL BLOB** `5543ea88...` at base, at
  `44b0fab` and at HEAD, re-verified by `git rev-parse` at close. No signal-set redesign, no
  promotion, no dispatch.
  **THE 20 -> 21 MISMATCH EXCEPTION WAS PRINCIPLED, AND THE REVIEWER VERIFIED IT RATHER THAN
  TRUSTING IT:** `MUT-0006`'s base `write_scope` really did say *"never an edit to an existing
  one"* and is preserved as a **byte-exact prefix** rather than rewritten; `outcome` is genuinely
  the first amending write in the census; section 8 closes in BOTH directions and a third route
  (reclassifying `class: A` -> `B`) is caught by `RELABELLED`. **THE REVIEWER'S RULING CARRIES
  FORWARD UNSOFTENED: principled, but "the last one waved through on this reasoning." P6 SHOULD
  HOLD AT 21.**
  **THE `(cccc)` DIGEST DISPOSITION IS UPHELD.** `ranking_digest` covers the snapshot store's
  GLOBAL chain head, so `DECISION-0010`'s moved `2fa876c6...` -> `a509eed7...` while the ENTIRE
  S1 report differs by **exactly 2 lines** (`snapshot_chain_head`, `ranking_digest`) — every
  rank, tie, Pareto status and `rank_of_selected: 1` byte-identical. **The ordering is immutable;
  the digest was never an identifier of it.** A **claim defect, not an ordering defect**. Not
  fixing it here is correct for a reason STRONGER than scope: `rank-candidates.sh` is **guard 1's
  own protected surface**, and editing it in the packet that seals a ranking is precisely the
  self-amendment guard 1 exists to prevent. The P4 receipt is an **identical blob**
  `1bcb8bf3...` at base and HEAD — **not rewritten**.
  **THE HONEST VERDICT, IN THE REVIEWER'S OWN WORDS AND UNSOFTENED:** *"P5 builds the apparatus
  for measuring executive capability and does not yet demonstrate it. It cannot — the
  demonstration requires a human to select from `DECISION-0011` and the work to complete, neither
  of which has happened. What P5 legitimately delivers is the transition from IMPOSSIBLE TO
  DEMONSTRATE to POSSIBLE TO DEMONSTRATE, plus a first ordering that can actually be wrong."*
  And residue `(hhhh)`, written UNPROMPTED by the builder: *"What P5 delivers is a decision that
  CAN falsify S1, not a decision that has."* **Non-degeneracy is NOT A RESULT** — the 20 evidence
  snapshots were hand-assigned by the same builder in the same commit. **Falsifiable, not
  falsified.**
  **THE OUTCOME ARM IS THINNER THAN THE COMMIT MESSAGE SUGGESTS, AND THE PACKET SAYS SO:** its
  actual new outcome data is **ONE field** (`result` `unknown` -> `in_flight`); the other two
  recorded values pre-existed. Residue `(ffff)` names the counter-temptation explicitly — writing
  `rollback_count: 0@measured` for unexecuted work **would have looked like a clean run** and
  would have been a fabrication. It was not written.
  **TWO FALSE-PASSES THE BUILDER CAUGHT IN ITS OWN RED DRIVE**, recorded because the CLASS matters
  more than the instances: the ranker-field loop was passing because
  `SIGNAL-SNAPSHOT-9281-rank_of_selected` failed the snapshot-id pattern on its SHAPE rather than
  being refused on its field NAME, and a "named in the refusal" check was matching the SUCCESS
  output. **A red drive that passes for the wrong reason is a fresh instance of
  resolvability-vs-identity** — this tree's named recurring trap, appearing inside the test
  written to catch it.
  **DEPTH: 3 SERIAL STAGES — builder, then qa || reviewer CONCURRENTLY, then the fix round. NO
  STAGE 4**: the orchestrator verified the fix round itself (all six ranker fields refused live,
  blob identity, store immutability, commit identity) rather than opening another gate stage.
  **3 COMMITS — ONE OVER THE <=2 CAP**, same deviation and same reason as P3 and P4, recorded and
  not normalised. **The file-ownership manifest is NOT fully disjoint and says so:** `cda95d2`
  owns `active_packet.md` ALONE (intersection with both others EMPTY, `comm -12` verified at
  close), while `44b0fab` and `adef6ad` **overlap on all 8 paths the fix round touched** — a
  strict subset, separable by ORDER and not by path. Guard convention **14 files / +1550 / -141**;
  net diff **14 / +1522 / -113**; the row records the GUARD's numbers per residue `(ggg)`.
  **FINAL STATE AT `adef6ad`, ALL RE-DERIVED BY THE ARCHIVIST AT CLOSE FROM THE REGISTRY FILES
  AND THE LIVE TOOLS: 100 controls; 77 gate / 15 advise / 7 execute / 1 observe / 0 rank / 0
  none; class A75 / B3 / C22; 21 declared mismatches; `evidence-policy.sh check` 26 of 100 split
  6/5/15; 10 decisions (UNCHANGED); 97 signal snapshots BY ROW COUNT (176 lines — the row count
  is `grep -c '^SIGNAL-SNAPSHOT-'`, never `wc -l`); 25 of those bound to `DECISION-0011`; 9
  mutator records; 0 live authority envelopes; suite 1964/0; maintenance 144/144;
  `scan-controls`/`scan-mutators` exit 0; `snapshot-verify` 97 verifying at exit 0; ZERO files
  added in the whole range; tree clean.**
  **SECOND EYES: NONE — ELEVENTH CONSECUTIVE PACKET.** The router requires the reviewer to state
  it rather than silently omit it, and **the reviewer complied**. **EVERY VERDICT IN THE ENTIRE
  FIVE-PHASE SEQUENCE IS SINGLE-MODEL.**
  **OPEN, AND NOT THE ARCHIVIST'S TO CLOSE: SELECTING FROM `DECISION-0011` IS AN OPERATOR ACT.**
  Recording a selection here would move
  `prospective_decisions_with_a_recorded_selection` from 0 to 1 with no human having chosen —
  **the exact figure the reviewer's reproduction exploited** — and would destroy the thing the
  packet built.


## 2026-08-05 — `gravito_exp0001_execution_a` (`PACKET-0046-exp0001-token-efficiency`) CLOSED

- **EXP-0001a executed and sealed** — the execution half of the operator's controlled
  experiment (Gravito OFF vs ON, total model tokens per durable accepted outcome).
  Preregistration committed BEFORE run 1 (`b3a3b7f` — ancestry is the ordering proof);
  sealed records + manifest + blinded dataset at `d2373e6`. Base `0ddf0b6`. 2 build
  commits, NO fix commit, depth 2.
- **The data:** 10 canonical T1 runs by the FROZEN `bench/run-corpus.sh` (zero edits to
  `bench/`), 5 pairs alternating order, all 10 accepted=yes, models and tree_digest
  identical across all 10; 6 T2–T4 refusal records retained.
- **Gates:** qa GREEN — 2378/0 at `d2373e6`, commit-1 isolation 2378/0, census 110 / 0
  executables, manifest 47/47, blinding leak grep 0, `residue.md` blob `01517ad2…`
  unchanged, safety grep clean (41 files / +1080 / −0). Reviewer PASS, ZERO items.
  Second eyes NONE — single-model; DC-0001 numeral moved **25 → 26**, derived from the
  store.
- **Blinding:** arms X/Y; mapping WITHHELD (scratchpad only), sha256 `0a4b66a1…`
  committed. **Hand-off condition:** EXP-0001b's evaluator gets ONLY the blinded dataset
  + preregistration §5 rule text, NEVER §3's schedule.
- **Where we are:** NOTHING IN FLIGHT. Staged next (NOT declared): EXP-0001b — blinded
  evaluation, reveal, conclusion. Reveal must come promptly: the mapping and stream logs
  live only in the session scratchpad. NOTHING PUSHED — `b3a3b7f`, `d2373e6`, close
  commit local pending explicit go.

## 2026-08-05 — `gravito_exp0001_analysis_reveal_a` (`PACKET-0047-exp0001-analysis-reveal`) CLOSED — EXP-0001 COMPLETE

- **EXP-0001b executed:** blinded analysis committed VERBATIM at `7d56cbc` (mapping
  absent from the tree — ls-tree proof), reveal + conclusion at `698e3c3`. Base
  `92c7276`. 2 build commits, NO fix commit, depth 2.
- **THE RESULT:** blinded evaluator (X/Y dataset + rule only) — "causal
  effect supported, condition Y lower": 50.8% median total-token reduction, ranges
  fully disjoint (Y max 227,089 < X min 311,164), 5/5 acceptance both arms, no
  confound fired. Mapping raw=Y / buildos=X, byte-exact to the pre-committed sha256
  `0a4b66a1…`, verified by qa AND reviewer. **Gravito OFF used 50.8% FEWER tokens on
  T1 (OFF median 153,611 vs ON 312,444) — the supported effect is Gravito INCREASING
  tokens, direction OPPOSITE the hypothesis.** Scope: T1-class only, N=5 pairs, one
  repo, one model config; T2–T4 no numeric data; the substantive-work claim untested,
  not contradicted. **EXP-0001 COMPLETE** — all five outputs in ancestry order
  (`b3a3b7f` → `d2373e6` → `7d56cbc` → `698e3c3`); experiment frozen; acting on the
  finding is the OPERATOR'S.
- **Gates:** qa initially RED 2375/3 — all three failures pre-existed at BASE
  `92c7276` (PACKET-0046's close bookkeeping, written AFTER its gates measured
  `d2373e6`); repaired OUTSIDE this packet by tiny-lane `d0a2231`; after it FULL SUITE
  **2378/0** solo, affected suites 70/0, check-adoption exit 0. Reviewer **PASS, ZERO
  items**. Second eyes NONE; `DC-0001` numeral **26 → 27**, derived. Defect class
  named: **"close bookkeeping written after the gates"** — the next archivist runs
  `check-adoption.sh` BEFORE committing a close.
- **Where we are:** NOTHING IN FLIGHT, nothing staged. NOTHING PUSHED — `b3a3b7f`,
  `d2373e6`, `92c7276`, `7d56cbc`, `698e3c3`, `d0a2231`, close commit all local
  pending explicit go; none may be amended. `residue.md` stays frozen.

## 2026-08-05 — `gravito_exp0002_execution_a` (`PACKET-0048-exp0002-sustained-workload`) CLOSED — EXP-0002a SEALED

- **Executed:** two five-task sequences (T1→T5) on one evolving parcel-billing tree per
  arm (seed `128485c6…`, suite 19/0), fresh headless session per task, byte-identical
  prompts, arms differ only by `install-project.sh`; Bash-capable path (allowlist
  non-binding in CLI 2.1.222, disclosed, identical both arms). **10/10 accepted by
  external oracles; model identical across all 10.** Base `982054a`. Commits `9cf0f87`
  (prereg BEFORE run 1) + `2d0696a` (RULING-4: four harness surfaces, census 110→114) +
  `916e1ae` (sealed records, blinded X/Y dataset, mapping sha256 `45734767…`) + `38ee0df`
  (the ONE fix commit). 3 build commits = the recorded contract-gap shape (scanner-forced
  registration), not a breach. Depth 3, announced.
- **Gates:** qa RED 2376/2, ONE attributed item (buildos T3/T5 transcripts carried
  workload-repo citations the range-citation sweep bit on) → `38ee0df` restored
  EXP-0001's sealed form (transcripts scratchpad-resident, hash-pinned; records
  byte-untouched; no sweep modified); re-check FULL SUITE **2378/0** solo, manifest
  31/31. Reviewer PASS 0 items → **PASS-AS-FIXED**; DC-0001 **27 → 28**. Second eyes
  NONE (Codex 403, both gates).
- **Recorded, harness frozen:** result-event `usage.*` undercounts dispatch-heavy
  sessions; sealing uses the provider `modelUsage` aggregate uniformly (reconciles with
  `total_cost_usd`); rows labeled `usage_block_disagrees=yes`. Uncorrected, arm B was
  FLATTERED (~70x on T3) — the correction moved AGAINST the convenient direction.
- **Where we are:** NOTHING IN FLIGHT. Blinded analysis ALREADY EXISTS (independent
  evaluator, pre-close); EXP-0002b (NOT declared) commits it verbatim, reveals against
  the hash, concludes with the two mandated reconciliations. Reveal promptly;
  mapping/transcripts are scratchpad-only. NOTHING PUSHED; no commit may be amended.

## 2026-08-05 — `gravito_exp0002_analysis_reveal_a` (`PACKET-0049`) CLOSED — EXP-0002 COMPLETE

- **REGISTERED RESULT: `no sustained-workload savings detected`** — OFF used **74.8%
  fewer** total tokens per durable accepted outcome than ON (ON **3.96×**, +296%;
  2,631,154 vs 663,924; uncached 78.8% agreeing; 10/10 accepted both arms; crossover
  against ON at T3 totals, T2 uncached/cost). Evaluator wording verbatim;
  translation applies the registered rule (§6→rule 3); neutral rule text committed
  (`analysis/EVALUATOR_RULE_TEXT.md`). **Finding:** overhead is invocation-dependent —
  ON cheaper on T1 (−31.5%)/T4 (−56.5%), 3.9×/7.8× costlier on T3/T5; a router enforcing
  the selector prevents ONLY T5 (T3's verdict was `gravito_full`). **Router = next
  CANDIDATE, not built.** Both mandated reconciliations carried; weekly drop
  prior evidence.
- **Commits:** `23983ba`+`46809e6` (build) +`ca65b98`+`ce7588c` (fixes). Depth 5:
  gates fix-then-pass 4 items + qa RED (same label defect); Depth 4
  mandatory_full_regate ran — qa GREEN 2378/0 solo; second fix under the
  executed-reason exception (defect minted BY fix 1); PASS-AS-FIXED. Second eyes
  NONE ×4 (Codex 403). DC-0001 **28→29**.
- **Where we are:** NOTHING IN FLIGHT, nothing staged. All five outputs in ancestry:
  `9cf0f87`→`916e1ae`→`23983ba`→`46809e6`→`ca65b98`/`ce7588c`. NOTHING PUSHED — those
  four + close commit local pending explicit go; none amendable. `residue.md` frozen.

## 2026-08-05 — `gravito_routing_enforcement_a` (`PACKET-0050`) CLOSED — verdicts BINDING

- **Post-EXP-0002 routing correction shipped:** binding selector (`mode-select.mjs`,
  complexity alone earns light); receipts with derived budgets (`route-task.sh`);
  close gate `routing-check.sh` — exact T5 replay REFUSED, SILENT-ESCALATION named;
  T3's sealed descriptor now routes light, frozen selector still full.
  `routing_contract.md`: THREE honest bounds (counters not bash-visible; false
  consumption uncaught; receipt ISSUANCE unchecked). Sweep in suite §26.
- **Commits:** `ac1581c`+`c49258e` (census 114→118 same-commit) +`4443360` (fix).
  Depth 3. qa GREEN **2482/0** solo (+104); commit-1 iso 2378/0; reviewer
  fix-then-pass 2 items → **PASS-AS-FIXED**. Second eyes NONE. DC-0001 **29→30**.
  Routing receipt closed: executed=selected=full, sweep 0.
- **Open (recorded):** the gate chain brushes `max_subagents: 3` — EXP-0003-adjacent.
  Staged NOT declared: EXP-0003, three neutral conditions, rule NOT asymmetric.
- **Where we are:** NOTHING IN FLIGHT; NOTHING PUSHED — three + close commit local
  pending explicit go; none amendable. `residue.md` frozen.

## 2026-08-05 — `gravito_exp0003_execution_a` (`PACKET-0051`) CLOSED

- Nine runs (A direct · B light · C full-enforced × T3/T4/T5), T1/T2 digest-pinned,
  prompts byte-pinned, modelUsage-native telemetry, costs exact, 9/9 accepted, model
  identical. HEADLINE FOR EXP-0003b (not drawn here): BOTH condition receipts
  REFUSED by the budget gate — B 4 breaches, 0 silent escalation, 0 dispatches; C 5
  (7 subagents vs 3, 7.5M vs 2M tokens); NO degradation notes — the breaker's
  protocol half did not run live. See `GATE_CALIBRATION_NOTE.md`.
- **Commits:** `acfa1be`+`18f82f6` (census 118→121)+`cdfe1a3` (seal; mapping sha256
  8a063552)+`9beb73f` (fix). Depth 3. qa 2545/0 solo; iso 2482/0, 2545/0; manifest
  34/34; 9 rows re-derived. Fix-then-pass 1 item → PASS-AS-FIXED. Second eyes NONE.
  DC-0001 30→31. Step-7 receipt (FIRST LIVE USE) closed full=full; sweep 0.
- **Where we are:** NOTHING IN FLIGHT. Blinded evaluation EXISTS; EXP-0003b (NOT
  declared) commits it; reveal promptly. NOTHING PUSHED — 9 ahead of origin
  incl. close; none amendable. `residue.md` frozen.

## 2026-08-05 — `gravito_exp0003_analysis_reveal_a` (`PACKET-0052`) CLOSED — EXP-0003 COMPLETE

- **RESULT: `frontier unstable — winners flip on uncached`** — evaluator's own label;
  no directional rule. n=1: direct wins T3/T5 totals + T5 outright; light wins
  uncached T3/T4 (3rd+4th amortization points, after EXP-0002 T1/T4), never worse
  than 2nd uncached; full wins T4 totals only, never uncached. Totals 90.6–96.8%
  cache_read (C2). Both receipts REFUSED; 0 silent escalation; 0 degradation notes.
  4 operator questions handed over; none acted on.
- **Commits:** `9d78999`+`1cb31f6`+`f2a2b3a`+`a3b0ba7` (fix). Depth 3. qa 2545/0;
  fix-then-pass 4 items → PASS-AS-FIXED. Base marker defect `:2301` fixed;
  singleton 0 in flight. DC-0001 31→32. Receipt full=full; sweep 3/0 exit 0.
- **Where we are:** directive COMPLETE; NOTHING IN FLIGHT/STAGED/PUSHED — 14 ahead.
  `residue.md` frozen. THIS FILE ~1.7 KB from ceiling: NEXT close needs
  operator-authorized re-block.

