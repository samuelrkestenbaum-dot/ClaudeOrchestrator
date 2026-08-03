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

