# Current State

> The "where are we" snapshot. The orchestrator reads this first every session.
> The archivist advances it when a packet closes. Keep it short and true.

## Project

- **What this repo is:** Build OS — a native orchestrator for Claude Code (routing
  matrix + packet loop + markdown memory) that turns a repo into a
  plan → build → prove → review → record system.
- **Primary branch / base:** `claude/add-build-os` (current integration base; no
  `main` present in this environment). Active work branch:
  `claude/project-handoff-merge-ramhds` (tip `a7ab841`). Merge-base with
  `origin/claude/add-build-os` = `7ef50e8`.
  **CORRECTED 2026-07-31 — this line previously claimed the branch was UNPUSHED, and it is not.**
  `refs/remotes/origin/claude/project-handoff-merge-ramhds` is at **`6b01173`**, and
  `git reflog show` for that ref records five successive `update by push` entries
  (`6b01173`, `321dced`, `e8f34ed`, `785a851`, `d30aeab`). **Local-only as of 2026-08-01:
  `105cb75`, `0555717`, `77a0040` (`gravito_evidence_policy_matrix_a` + its close) and
  `88052e7`, `a7ab841` (`gravito_authority_envelope_a`), plus this close commit.**
  No claim is made here about whether those pushes carried an explicit go; the record is
  corrected to match git and the discrepancy is flagged for the operator.
- **Version:** `0.1.0` (`VERSION`), pre-1.0 — **installable, not yet API-stable**.
  Changelog: `CHANGELOG.md`. License: `LICENSE` — proprietary, All Rights Reserved,
  a deliberately conservative **placeholder**; the license model is still an open
  owner decision. **CORRECTED 2026-07-31: a tag DOES exist.** `v0.1.0` — annotated, tagger
  `Claude <noreply@anthropic.com>`, dated 2026-07-31 02:28:23 +0000, subject *"Gravito v0.1.0
  — first installable release"*, pointing at `da4ae81`. This file previously said no tags
  existed. `CHANGELOG.md`'s rollback section still says "rollback is not yet proven — no tags
  exist" and is **outside the archivist's write gate**; `residue.md` must keep the literal
  `no tags` because `tests/release_metadata_tests.sh:322` requires it, so the residue item is
  annotated rather than rewritten. Whether the tag was created with an explicit go is not
  determinable from here and no claim is made.
- **Build/test command:** `bash tests/build_os_tests.sh` (1597 checks; no network; temp dirs)
  — measured on a quiet tree at `a7ab841`, and reconciled against `CHANGELOG.md`, which
  carries the matching literal `**1597 passed**` at `CHANGELOG.md:32` (present exactly once,
  unsplit). **This pair had gone stale in four consecutive packets** (657 → 1418 → 1485 → 1597),
  each time because the archivist can write this token but **`CHANGELOG.md` is outside its
  write gate**, so the two halves of the check are owned by different lanes and only one of
  them can close the loop. **It closed at the `gravito_authority_envelope_a` close only
  because that packet's builder happened to write the live total into the CHANGELOG entry** —
  the structural cause is untouched.
  The reason it keeps surviving is worth keeping: **THE GUARD DOES NOT DETECT STALENESS.**
  It detects cross-file *disagreement* — §5 checks that `CHANGELOG.md` contains the literal
  `<count> passed` matching this line — so **two stale files that agree pass it**. Proven
  three times on this same token: at `2a3c9b3` the suite was green at 1418/0 while this line
  claimed 657; at `0555717` green at 1485/0 while this line and CHANGELOG agreed on 1418; at
  `a7ab841` green at **1597/0** while this line and CHANGELOG agreed on **1485**. The check
  that actually works is opt-in and **still NOT enabled by the chained suite** —
  `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` compares against a live
  run, and it is the ONLY check that compares memory against a live run. It correctly reported
  `live suite total (1597 passed) contradicts current_state.md's claim (1485)` at close, while
  the chained suite was green. Correcting the number does not fix the guard; see residue.
  It **chains** 16 sibling suites in `tests/` through one `chain_suite` function and folds their
  counts into its own totals. A sibling suite present on disk but not chained is itself a failure,
  so a new suite cannot become discoverable-only. **The per-suite breakdown that used to sit here was
  removed, not updated:** it was a hand-maintained sum that nothing machine-checks, and it had gone
  stale twice. Run the command for the split. The maintenance layer also has its
  own suite, `./build-os/maintenance/run-tests.sh` (144 checks, node --test). Both are offline and
  deterministic. Pinned separately: `bash tests/release_metadata_tests.sh`.
  Cross-platform green: the P-018 200KB capture-bound test now generates its payload **in-child**
  (`MOCK_GEN_BYTES` / `MOCK_STREAM_CHUNKS`) instead of via an env var — the old env delivery
  exceeded Linux `MAX_ARG_STRLEN` (~128KB) and failed only on Linux (P-018.1, tests-only fix).
  — proportionate-routing + tool-ranking rules, the SessionStart detector (enabledPlugins/
  native vs plugin-cache candidates), installer copy parity, managed-block replacement,
  global convergence (legacy routing supersession preserving unrelated notes, + arbitrary-
  repo user-scope router resolution), plus install-global DURABLY-CONFIGURED reporting, the
  explicit 3-tier router fallback, and the canonical duplicate-MCP rule, plus P-011
  hook-dedupe (no prompt_id), skill-budget audit, honest Serena reconciliation, and
  remote/org-vs-local capability separation, plus P-013 reversible profiles and P-014
  zero-touch specialist handoff (route classification, focused no-op, ECC/zeroize handoff,
  prompt/cwd preservation, recursion guard, child-failure cleanup, timeout, single-Serena,
  dry-run) and unrelated-capability preservation across profile transitions, plus P-015
  global-install tool shipping and P-016 Ferrari hardening (capability registry,
  inline routing, privacy log, atomic lock, surface inventory, enabled-vs-installed audit).

## Where we are

- **Last closed packet:** `gravito_authority_envelope_a` — **the operator has an artefact to grant
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
  new **§2a** of `tests/authority_envelope_tests.sh:208`, reconciling `DEPLOYMENT_AXIS` against
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
  error — it reported a no-op at exit 0, i.e. a file that silently never rotates), and a
  zero-block parse of a file that HAS content now warns on stderr instead of printing the same
  `already rotated (no-op)` line it printed for two benign states. Reviewer verdict **pass**,
  after one **fix-then-pass** round (5 items). Suites at `641527f`: **281 / 144 / 61**, all 0 fail (the 281 is now 488).
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
- **Now:** none active. `gravito_authority_envelope_a` is **closed** (2026-08-01); its two commits
  `88052e7` + `a7ab841` and this close commit are **local-only** and stay that way pending explicit
  go. `build-os/packets/active_packet.md` reads NO PACKET IN FLIGHT and was **deliberately not
  back-written** for the closed packet — see the process defect above.
- **THE OPERATOR DECISION THAT NOW BLOCKS THE MOST:** step 3 was the plan and **step 3 cannot be
  done with the instrument just built.** An envelope only lowers `L_effective`; it cannot promote.
  The fourteen mismatches need **a class change or a different instrument**, and neither is
  designed. Do not cut a packet that writes envelopes to fix mismatches — it will not work, and the
  reviewer already proved it will not work.
- **Next (candidates), cheapest first — all from this close's residue:**
  1. **Stop creating `CHANGELOG.md` line-citations, and re-cite the two live ones by release-block
     heading** (`residue.md:280`, `receipts/gravito_evidence_policy_matrix_a.md:572-573`). The
     changelog grows from the top, so **every** line-citation into it decays on **every** packet —
     guaranteed, not occasional. Residue (r). Cheapest and it closes a whole class of future decay.
  2. **A checker for prose that restates a machine-computed table** — four packets running.
     §2a of `tests/authority_envelope_tests.sh` is now the strongest pattern (it pins an axis's
     OWNER, not just its copy); §5a pins a copy. `MISMATCHES.md` has carried a stale line reference
     in **six consecutive packets** and §10's table names its own decay mode in prose. Residue (m)/(s).
  3. **`authority-envelope.sh`'s `--help` hand-maintained `sed -n '2,196p'` range, duplicated across
     two handlers (`:235`, `:245`)** — when stale it **silently truncates rather than failing**, and
     nothing tests it. It was live and broken until the fix round caught it. Residue (t).
  4. **Enable the staleness check that actually works** — `RELEASE_METADATA_LIVE_SUITE=1` is still
     opt-in and still not chained, and it is the ONLY check that compares memory against a live run.
     It is the sole reason the 1485 → 1597 pair was caught. Residue (n)/(g).
  5. **Assert a declared packet EXISTS while a packet is in flight** —
     `bandwidth.active_packet_singleton` refuses two and permits zero, and an entire packet was just
     built under zero with the control green. **Fires on omission, not on an affirmative act**, which
     makes it strictly worse than the disclosed delete-the-file evasion. Residue (u)/(c).
  6. **`tests/entitlement_tests.sh:296-305`'s hardcoded 12-file `PACKET_FILES` list** — decays
     silently; this packet added two more files it does not cover. Residue (b).
  7. **`swarm-merge.sh` glob-overlap false negatives** (`src/*.ts` vs `src/foo*`). Residue (a).
  8. **Align `tests/evidence_policy_tests.sh:322`'s §5b non-vacuity floor** to §2a's stronger form.
     **NON-BLOCKING — reviewer flagged and explicitly passed; do not treat as open.** §2a covers the
     same axis with the stronger form, so it is not a live hole. Do it when that file is next open.
     Residue (v).
  **Blocked on the operator, not schedulable:** the S1 evidence-token decision (add `untested` as a
  sixth token, or have S1 carry `unvalidated`); the S1 `runtimeAuthority: observe` recommendation
  (reviewer's advice, **not adopted**); demoting `maint.tripwire_coverage_scan` (the envelope now
  EXISTS and CAN express this demotion — what is missing is the authorisation, not the instrument);
  writing the first authority envelope at all.
  Carried, unrelated: decide Context Mode routing enablement (stays non-secret pilot); name a target
  repo + approve a secret for the GH Actions; authorize/enable the deferred connectors.

## Stable facts (slow-changing)

- **Remote / org — claude.ai (2026-07; NOT the local CLI plugin registry):** 9 org plugins
  (`design`, `data`, `productivity`, `brand-voice`, `marketing`, `sales`, `small-business`,
  `legal`, `cowork-plugin-management`); 13 connectors (Apollo.io, Clay, Docusign, Gmail,
  Higgsfield, HubSpot, Hugging Face, Netlify, Notion, Otter.ai, Slack, Supabase, Zapier) +
  2 session MCPs (GitHub, Claude Code Remote). These are org-level (claude.ai app registry),
  distinct from the locally-installed CLI plugins; verify live per surface before routing
  (no-route-to-unverified). See `tool_router.md` → *Remote / org capabilities*.
- **Installed but NOT live:** Stripe, Cloudflare Developer Platform (need auth);
  Google Calendar, Google Drive, Microsoft 365 (toggled off in-chat).
- **Source of truth for capabilities:** the live registries — `ListConnectors`,
  `ListPlugins`, `ListSkills` — reconciled into `tool_router.md` (Installed
  plugins / connectors) and `INTEGRATIONS.md`. Re-verify when the env changes.
- **Build accelerators (P-012 live evidence):** Build OS routing, Serena, Repomix,
  ccusage, and Context Mode are ACTIVE. Host — Serena is one user-scope MCP pinned to
  official commit `68884f1`; Repomix 1.17.0 + ccusage 20.0.18
  (`/Users/samsmac/.nvm/versions/node/v22.23.1/bin`). Enabled at host user scope via the
  `claude plugin` CLI (`claude plugin list` confirms): `claude-hud` v0.6.0,
  `context-mode` v1.0.169 (routing limited to non-secret pilot), and 8 focused Trail of
  Bits plugins (`constant-time-analysis`, `supply-chain-risk-auditor`,
  `agentic-actions-auditor`, `insecure-defaults`, `static-analysis`, `variant-analysis`,
  `differential-review`, `seatbelt-sandboxer`). `zeroize-audit` and ECC are disabled;
  the former prevents an unpinned duplicate Serena and the latter removes 363 redundant
  skills. A fresh authenticated prompt completed with no skill-budget warning. Claude HUD remains enabled but its visual
  statusline is not independently claimed. Node compatibility resolved: host default is
  Node 22.23.1; Repomix, ccusage, and Context Mode run/connect under Node 22. GitHub
  Actions = repo-scoped templates (uninstalled; no secrets). Gates in `tool_router.md` +
  `INTEGRATIONS.md` §8. One orchestrator (Build OS) — no competing framework.
- **Status-semantics rule:** never call npx/uvx success in an ephemeral container
  "installed" unless persistent host state **and** a fresh-session activation test
  are both verified. Installation · configuration · activation · authentication ·
  repository rollout are five distinct states.
- **Discovery-first rule:** every build discovers live capabilities, then selects
  the smallest correct toolset; Serena is primary for symbol-level work in large/
  unfamiliar repos before broad file reads.
- **Zero-touch specialist handoff (P-014→P-017):** `build-os/tools/specialist-handoff.sh` + the
  `prompt-router.sh` hook classify via a maintainable **capability registry** (precedence
  zeroize > ecc > inline > focused). focused → no relaunch; ecc/zeroize → an automatic bounded
  child under a **safe atomic lock** (path-validated `lock_path_safe`, non-recursive
  unlink+`rmdir`, fail-closed BUSY, safe stale break; released + focused restored on
  EXIT/INT/TERM, child killed). The task travels on **stdin** (never argv) and the child must end
  with a terminal marker `[BUILD_OS_STATUS: COMPLETED|NEEDS_INPUT|BLOCKED|FAILED]`; the hook
  suppresses parent work **only** on explicit COMPLETED — exit-0-without-marker is UNCONFIRMED
  (exit 76), and the parent is told to continue/obtain input otherwise. Output is bounded +
  visibly truncated. The audit log is **privacy-safe** (route/result/exit/event-id; `0600`; never
  prompt/cwd). `install-global.sh` ships both tool scripts into `~/build-os/tools` (P-015).
  **Inline routes** (`21st`, `agent-reach`, `claude-watch`, `ui-ux-pro-max`) emit a **conditional**
  INLINE CANDIDATE (verify live on this surface, else built-in/local fallback + state the limit —
  never claim use from install alone); no profile switch, no child. Surface-aware: 21st.dev is
  verified live as cloud alias `21st` and Mac-local alias `21st-dev`; Anthropic's cloud
  web-connector layer still requires per-call user approval and does not honor project
  permission allowlists for this gate. Agent Reach = native skill;
  UI UX Pro Max v2.11.0 + Claude Watch v0.4.1 = enabled Claude Code skills/plugins. No
  cross-surface ACTIVE claim.
- **Gates hold:** external mutation (push/merge/deploy/secret/send/SaaS-write),
  plus DDL / remote-DB writes / payments / flags / canaries / telemetry / OAuth,
  are each a separate STOP for explicit go. Repo-scoped GH Actions never go global.

---
_Updated by the archivist on close._
