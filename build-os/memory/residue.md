# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

## Deferred (follow-up packets)

- **Fresh-session activation test passed (P-009):** authenticated prompt, Build OS
  startup signal, hook parsing, and MCP health all pass.
- **Serena (resolved, P-012):** `zeroize-audit` is disabled and one user-scope Serena MCP
  is pinned to official commit `68884f1`; fresh MCP connection PASS with no duplicate.
- **Claude HUD** → `claude-hud@claude-hud` v0.6.0 installed + enabled at host user scope;
  security + function PASS. ACTIVE pends fresh-session render test (TTY).
- **Context Mode** → `context-mode@context-mode` v1.0.169 installed + enabled at host
  user scope; benchmark PASS. **Routing limited to non-secret pilot** (not wired into any
  project `.mcp.json`); awaiting go to widen. Non-secret repos only; never route
  secrets/customer-data/logs through it.
- **Trail of Bits** → **ACTIVE**; 8 focused plugins enabled (advisory/read-only);
  `zeroize-audit` disabled to remove its unpinned Serena; **not vendored** (CC BY-SA).
- **GH Action opt-in** → `claude-code-action` / `claude-code-security-review` are
  repo-scoped templates; install into a **named** target repo only with explicit go +
  the required secret (`ANTHROPIC_API_KEY` / `CLAUDE_API_KEY`).
- Carried from P-001: authorize Stripe + Cloudflare, enable Google/Microsoft
  connectors; session-MCP router rows for GitHub + Claude Code Remote.
- **Cross-surface asymmetry (P-019/P-020):** two capabilities are active on the Mac but not
  symmetric on the Claude Cloud surface, which caps cross-surface orchestration below 10/10.
  **Serena** — active user-scope MCP on the Mac (pinned `68884f1`); *installed but not registered*
  on Claude Cloud. **P-020 closed the repo-addressable half:** `install-accelerators.sh` now
  registers the pinned Serena into `~/.claude.json` **add-if-absent** (no duplicate on the Mac; no
  secret; project `.mcp.json` still Serena-free per the single-server rule, P-008). Remaining
  boundary: this only helps if the surface reads `~/.claude.json`; a Cloud task on Anthropic's
  managed connector registry (as 21st.dev) still needs a Cloud-settings action. **Claude Watch** —
  host plugin v0.4.1 enabled; absent from Claude Cloud's live registry; **no repo lever** —
  install/enable it on the Cloud surface (a `claude plugin` / Cloud-UI step). Routing already
  treats both as availability-conditional, so nothing overclaims.
- **Fix-to-closure (P-021):** P-020 proven on the real `~/.claude.json` (byte-identical no-op log +
  live `mcp__serena__list_memories` call). **21st.dev** = Anthropic-managed **account connector**
  (approval-gated; no container/repo lever) — user action is Cloud connector settings; the per-call
  approval is not weakened. **UI UX Pro Max** = user-account skill absent from this container (no
  source to vendor) — user action is a Cloud enable / provide the package. **Claude Watch** = host
  plugin absent in Cloud with no repo lever → shipped a **Cloud-native supervision fallback**
  `build-os/tools/supervise.sh` (bounded polling watch; COMPLETED/TIMEOUT/USAGE; no plugin; pair with
  `send_later` for cross-turn) and updated routing truthfully. So the `claude-watch` ROUTE is fully
  functional even where the plugin is absent; the 21st + UI UX Pro Max capabilities themselves remain
  account/Cloud-side, degrading truthfully to their named fallbacks.
- **Audit-branch reconciliation (P-022):** the remote audit branch
  `claude/post-settings-closure-audit-y59p8t` is now **superseded** by canonical — its behavior was
  fully **subsumed** (P-006 216-check suite; P-016/P-017 conditional-inline + non-fatal-bootstrap
  fallback; P-019 21st-live; P-020 Serena add-if-absent; P-021 UI-UX-Pro-Max-absent / watch
  fallback), so P-022 imported **zero machinery** (no `verify.sh`, no `tool_router` edit, no new
  test) and its colliding "P-001" identity was not imported. The local branch and tracking ref
  were removed first; the managed Cloud Code proxy denied remote ref deletion with HTTP 403.
  The superseded remote branch was then deleted through the authenticated GitHub web UI and
  its absence was verified after a full page refresh. Canonical remained untouched.

- **License model is an OPEN OWNER DECISION (`gravito_release_metadata_a`):** `LICENSE` ships
  proprietary **All Rights Reserved** (Samuel Kestenbaum) as the deliberately most-conservative
  **placeholder**, chosen because it grants nothing by accident and can be loosened later (BSL,
  dual, or open) without clawing back a right already given — loosening is easy, retracting a
  grant is not. **This is not a settled licensing decision.** No pricing, entitlement scheme, or
  terms of service are defined anywhere, and none should be invented without the owner.
- **[CORRECTED 2026-07-31 — THE PREMISE OF THIS ITEM IS NOW FALSE. A TAG EXISTS.]** `v0.1.0` —
  annotated, tagger `Claude <noreply@anthropic.com>`, dated 2026-07-31 02:28:23 +0000, subject
  *"Gravito v0.1.0 — first installable release"*, pointing at `da4ae81`. Found by the archivist at
  close of `gravito_evidence_policy_matrix_a` by reading git rather than this file. **The item below
  is deliberately NOT rewritten**, for two reasons: `tests/release_metadata_tests.sh:322` requires
  the literal `no tags` to appear in this file, so deleting the sentence turns the suite red; and
  `CHANGELOG.md`'s rollback section states the same now-false thing and is **outside the archivist's
  write gate**. So the guard and the CHANGELOG both still encode a false premise, and correcting
  them needs a lane that may write outside `build-os/`. **Whether the tag was created with an
  explicit go is not determinable from here and no claim is made either way.** The *substantive*
  point still stands: **no rollback has been executed end-to-end and measured**, tag or no tag.
- **No tags exist → rollback is UNPROVEN (`gravito_release_metadata_a`):** `VERSION` is `0.1.0`
  and `CHANGELOG.md` documents update = re-run the installer at a newer checkout, rollback =
  check out an earlier tag/commit and re-run. The **update** half is covered (the cold-install
  suite asserts a byte-identical re-install); the **rollback** half is the intended procedure,
  **not a verified one** — no tag exists to roll back *to* by name and no rollback has been
  executed end-to-end and measured. This is P-B territory. Tagging is the **operator's call**
  and was not done. Note the asymmetry that a rollback would not undo: uninstall/downgrade never
  removes `build-os/memory/archive/`, the only copy of anything already rotated out.
- **Proof is single-platform (carried from P-A):** every measurement — both suites, the
  cold-install proof, the maintenance layer — was taken on **one Linux machine's**
  `node`/`git`/`bash`. The `sha256sum` / `shasum` branch exists for macOS but has **not** been
  executed, and no other platform was tested at all. Also stated in
  `build-os/maintenance/PORTING.md` and in `CHANGELOG.md` → *Known limits*.
- **`init-build-os.sh` seeding leak (open, being fixed in parallel):** `init-build-os.sh` seeds a
  new project's scaffolds from **this repo's LIVE memory files**, so a customer's fresh
  `build-os/` can arrive carrying this repo's state. Flagged `BLOCKED` in
  `build-os/maintenance/PORTING.md`. P-A added nothing to the leak (its two scaffold additions
  come from clean templates) and did not fix it. A **sibling packet in this same session** is
  fixing it — at the time this note was written that fix had **not** landed, so treat the leak as
  open until that packet's own receipt says otherwise.
- **THE SPEED CLAIM IS STILL UNMEASURED (`gravito_speed_benchmark_a`):** the instrument now
  exists (`build-os/metrics/`), the number does not. **No A/B against raw Claude Code has been
  run, and none can be run from this harness** — a Claude Code session is not launchable from a
  bash test and agent invocations are not scriptable, so **both** arms are unautomatable here,
  not just the control. "20x-100x" is therefore neither supported nor refuted by anything in this
  repo; the store is silent on it and says so. **Do not quote a multiplier.** The executable
  design is written down in `build-os/metrics/COMPARISON_PROTOCOL.md` (two arms, **9**
  held-constant variables — now including **reasoning effort/thinking budget** and a **fresh
  session per run**, the two confounds that void a result while leaving the model string
  identical; **one pre-registered primary endpoint** = median wall-clock to acceptance on `T3`,
  everything else secondary; a **wall-clock-denominated DNF rule** because a rounds-denominated
  one could never fire on arm A, which delegates to nobody; rounds demoted to an **arm-B-only
  diagnostic**; human operator holds the clock, alternating run order) against the frozen corpus
  in `task_corpus.md` (v1.0.0: `T1` comment fix, `T2` single-file bugfix with a test, `T3`
  multi-file feature, `T4` three-way fan-out). **The recommended execution is the reduced-N plan:
  a floor of 4 tasks × 2 arms × 2 runs = 16 runs, 20 at most** (the two optional extra runs go to
  `T1` and `T2`, the cheapest to repeat), reported as ranges, with the pre-registered rule *"if the
  ranges overlap at all, the honest report is 'no detectable difference at this N'."* 16 is enough
  to **refute** 20x (a 20x effect gives non-overlapping ranges at N=2) and honestly insufficient to
  establish 1.3x, which nobody is selling; the N=5/40-run design is kept as the fuller one but is
  20–30 operator-hours and will not happen. **This is P-B / pilot territory and needs a human, not
  an agent** — an agent measuring its own speedup is not evidence. **And the human is not neutral
  either:** the operator is the product's author and **cannot be blinded** to which arm he is in,
  which the protocol now states as a limit it cannot fix from the inside.
- **What the instrument can prove today (`gravito_speed_benchmark_a`):** that four specific
  packets produced specific git-checkable amounts of change; that one of them (a one-token stdin
  fix, retro-classified `tiny`) burned **6 rounds against a 2-round budget**; that a reference
  deployment's rotation utility took **11 rounds** and was sound at **3**; and that one fan-out
  ran 13.7 min parallel against a 37.9 min serial transcript figure (**2.77x**). Three rows are
  falsifiable against `git show --numstat` and are verified on every suite run. **Sample size is
  4 and the round-budget compliance denominator is 1** — the report prints that denominator next
  to the percentage on purpose.
- **Instrument limits, carried (`gravito_speed_benchmark_a`):** (1) **Rounds, wall-clock, agents
  and both defect columns are self-reported** — nothing counts them automatically, and
  `--verify-git` can only falsify files/insertions/deletions. (2) **`defects_escaped` is empty
  across the whole corpus because no post-close defect audit has ever been run** — empty means
  *unaudited*, never *zero*. (3) **A row can never be corrected**: the store is append-only and
  one-row-per-packet, with no supersede mechanism, so a row must be written at close or not yet
  — which is why this packet has **no row of its own**. (4) **`--verify-git` needs this repo's
  history**; a shallow clone or a history-stripped export reports `UNVERIFIABLE` and exits
  non-zero (found by running the suite in a stripped tree; §11 now names the precondition).
  (5) **The corpus tasks `T1`–`T4` are a frozen specification, not executable fixtures** —
  turning them into runnable fixtures is a follow-on packet, as is automatic round/wall-clock
  capture and a supersede mechanism. (6) **`--verify-git` now exits non-zero on `UNVERIFIABLE`,
  not only on `MISMATCH`** — it previously printed the unverifiable row and still exited 0 as long
  as one other row verified, so a fabricated commit could sit in the store while `$?` said the
  store agreed with git. An unmade check is not a passed check, and a falsifiable artifact is only
  falsifiable if the exit code carries the finding.
- **THE CORPUS MEASURES BUILDING; THE PRODUCT SELLS JUDGMENT (`gravito_speed_benchmark_a`):**
  `task_corpus.md` now records its own blind spot rather than claiming to "span the lane ladder"
  (it does not — **`read-only` and `diagnosis` have no task at all**, and those are the two lanes
  where orchestration overhead is proportionally largest). It also over-samples the best case:
  `T4`, a clean three-way fan-out, is **25% of the corpus with the largest cap** while being a
  small fraction of real work. Three task shapes are **missing and named as gaps, not queued as
  work**: (a) **debugging an unfamiliar codebase** — every task presupposes the defect is already
  located, so nothing measures *finding* it; (b) **read-a-lot / write-a-little** — all four tasks
  are specified by output size, none by input size; (c) **a task whose right answer is "don't
  build it"** — currently unmeasurable, since every "Done when" presupposes a build happened. The
  counterweight to keep: **`T1` is deliberately the task where Build OS loses**, annotated with
  this repo's own worst result (6 rounds for a one-token fix). A corpus with no losing task is a
  demo.
- **Per-packet attribution is destroyed by one-commit merges (`gravito_speed_benchmark_a`):** the
  seeded fan-out merged three packets into a single commit (`68cae7a`), so its three constituent
  packets are **unattributable from git alone — recoverable if the disjoint file-ownership manifest
  was recorded**, which for that fan-out it was not. The instrument can measure the fan-out but not
  its parts. **One commit per packet is a measurement requirement, not a style preference — with a
  stated fallback:** one commit per packet *where the merge allows it*; otherwise **record the
  disjoint manifest in the receipt** so attribution stays recoverable by path. The fallback is not
  a loophole, it is the reason the rule survives: as an absolute it collides with "Commit-1 green
  in isolation" on fan-out merges, and absolute rules that collide with merge mechanics get quietly
  broken rather than followed. Related:
  git says 47.5 min elapsed between `641527f` and `68cae7a` while the transcript says the fan-out
  itself was 13.7 min. Both are true about different things, and **neither is a "how long the
  packet took" number** — which is why wall-clock is never reconstructed from commit timestamps.
- **No telemetry, by design and by test (`gravito_speed_benchmark_a`):** the metrics store is a
  local, in-repo, operator-owned file. Nothing transmits, phones home, or reports usage, and
  `tests/speed_benchmark_tests.sh` §15 greps the scripts to keep it that way. Adding a collector
  would be a separate packet **and** an explicit gate.
- **Single-model review throughout (P-A + stdin-hang + `gravito_speed_benchmark_a`):** every
  reviewer verdict in this work was produced by **one model**. Codex second-eyes was checked and
  **unavailable on every pass** — including this packet's review and its fix round, so the six
  reviewer items and the qa exit-code finding folded in here also carry **no independent
  second-model corroboration**. That matters more than usual for this packet, whose deliverable is
  an honesty instrument: the artifact that judges whether claims are overstated was itself judged
  by a single model.

### From `gravito_census_gaps_egress_bandwidth_a` (2026-07-31, receipt `build-os/receipts/gravito_census_gaps_egress_bandwidth_a.md`)

- **(a) `swarm-merge.sh`'s disjointness check has FALSE NEGATIVES.** Two globs that overlap on a
  real path are not reported as overlapping — `src/*.ts` and `src/foo*` **both match `src/foo.ts`**
  and the check passes. The backstop at `:363` does not close it: it only covers **pre-existing**
  paths, and only when `--repo` is passed. So a fan-out manifest can be declared disjoint, pass
  validation, and still have two agents owning the same file — which is the one thing the manifest
  exists to prevent. CLAUDE.md's fan-out gate rests on this check.
- **(b) `tests/entitlement_tests.sh:296-305`'s hardcoded 12-file `PACKET_FILES` list decays
  silently as the tree grows.** It is a hand-maintained fileset with no vacuity floor and no
  derivation from the tree, so files added after it was written are simply not scanned and nothing
  reports the gap. **This packet added two shell files it does not cover**, so the list is already
  behind. A scanner that silently covers less of the tree each packet is worse than one that fails.
- **(c) Nothing asserts `active_packet.md` exists and is tracked.** This is
  `bandwidth.active_packet_singleton`'s **own disclosed evasion**: deleting or untracking the file
  makes the singleton gate pass trivially. Disclosed in the entry, not closed.
- **(d) `maint.tripwire_coverage_scan` is registered `refuted` and still gates.** The reviewer
  called it **the strongest demotion candidate in the census** — a control whose empirical status is
  `refuted` should not hold `gate` authority. **BLOCKED on the authority envelope:** clearing it
  means re-authorising a control, which is the operator's decision and not a builder's. Carried
  deliberately, not overlooked.
- **(e) Nothing machine-checks `MISMATCHES.md` §10's file/lines table.** The
  `entitlement.egress_scan` technique-limit disclosure was added, but the table itself is
  hand-maintained. **This is exactly how the `:668` drift survived a green suite:** commit 1's
  104-line insert moved an assertion from `:668` to `:772`, the reference was bumped in three places
  and missed in the table, and `:668` had drifted onto a comment line — so the file contradicted
  itself about the same assertion while every automated check stayed green. Highest value per line
  of the follow-ons here.
- **(f) `current_state.md`'s suite count is PINNED STALE and only half fixable.**
  **[PARTLY SUPERSEDED 2026-07-31 — AND IT RECURRED IMMEDIATELY. See item (m).]** The 657 -> 1418
  half was closed by `gravito_evidence_policy_matrix_a`'s commit 2, which could write `CHANGELOG.md`;
  the token then went stale again at 1418 against a live 1485 within the same packet. Original entry
  preserved below. The live total was **1418**; the guard-bound token still read **657**. Measured,
  both directions:
  writing `1418 checks` turns the suite **RED** (`41 passed, 1 failed`) because
  `tests/release_metadata_tests.sh` §5 requires `CHANGELOG.md` to contain the literal
  `<count> passed` and CHANGELOG line 96 reads `Suite **1338 → 1418** passed` (bolded, so `grep -qF`
  misses). **`CHANGELOG.md` is outside the archivist's write gate**, so the archivist cannot make
  the matching edit. The fix is one literal string in CHANGELOG plus the token here, in a lane that
  may write outside `build-os/`.
- **(g) THE STALENESS GUARD DOES NOT DETECT STALENESS.** Worse than (f) and the reason (f) survived
  three packets. §5 checks cross-file **agreement**, not liveness — **two stale files that agree
  pass**. Proven at `2a3c9b3`: the suite is green at 1418/0 while `current_state.md` claims 657, a
  number **761 checks stale**. The check that actually works exists and is **opt-in and not enabled
  by the chained suite**: `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh`
  correctly reports `live suite total (1418 passed) contradicts current_state.md's claim (657)`.
  A guard that is named for a failure mode it cannot detect by default is a false comfort.
- **(h) THE MECHANICAL GUARDS DID NOT CATCH THIS PACKET'S CENTRAL DEFECT — and no scanner can.**
  `bandwidth.active_packet_singleton` shipped as **Class A** with an argument that did not support
  it, and **passed every automated check clean**, because `scan-controls.sh` reconciles class
  **labels** across files and cannot reconcile the **arguments** behind them. The guard surface is
  now thorough enough to *feel* comprehensive while being blind to the exact failure mode the
  registry exists to prevent: a control overstating its own evidence. **The fix is the reviewer
  stage, not another scanner** — recorded explicitly so a future packet does not respond to this by
  building a label-checker that cannot, in principle, work. The reviewer's ruling, kept because it
  is the commercial argument and not only the honest one: *"a system that demotes its own new
  control's class on review is the demo."*
- **(i) Precedent set, FORWARD-FACING ONLY:** new Class-C controls ship at **`advise`** by default;
  promotion to `gate` is a **separate governance action**. `bandwidth.packet_commit_ceiling` is the
  first control under it. **This does NOT generalise backward to the existing 13 declared
  mismatches** — the reviewer ruled they are **not one population** and must not be swept by a
  single rule. Do not let a future cleanup packet apply this retroactively.
- **(j) `rank` and `observe` remain 0 of 81** (0 of 78 after `gravito_evidence_policy_matrix_a`; 0 of 75 at that close). The authority ladder has
  five rungs and the census uses two (**66 gate / 12 advise**). A 66/12/0/0 distribution carries
  almost no information. Not a defect with a fix attached — a standing observation about whether the
  ladder is real. **Sharper since `gravito_evidence_policy_matrix_a`:** that packet wrote rules
  about `rank` and `observe` that **no control has ever exercised**. **Sharper again since
  `gravito_authority_envelope_a`:** `DEPLOYMENT_AXIS`'s `shadow:observe` and
  `bounded_autonomous:rank` are two MORE caps onto empty rungs. The distribution is now
  **68 gate / 13 advise / 0 rank / 0 observe**. See item (S1) below — the first
  live occupant either rung would have had.
  **SHARPER AGAIN SINCE `gravito_mismatch_refuted_a`, and now with a mechanism:** that packet added a
  **GUARD ON** the `observe` rung (`OBSERVE-LB`) without adding an **occupant** to it — and the guard
  is precisely what makes the rung unreachable for the 67 `load_bearing` controls. **No `observe`,
  `none` or `rank` rows exist at all in the census of 81.** The ladder is not merely unused at three
  rungs; for the largest population it is now **provably unenterable at the bottom two**. See items
  (bb) and (cc).
- **(k) Second-eyes was declared and NOT delivered, on both passes.**
  `build-os/memory/tool_router.md:368` routes reviewer second-eyes to Codex (`codex` CLI /
  Codex-for-Claude-Code plugin). **`codex` is not on PATH and no Codex plugin is installed**, so the
  row went unfulfilled in **both** the review and the re-review. **Record as an unfulfilled declared
  capability, not a pass.** It matters more than usual here: the defect that mattered most was a
  judgement call about the strength of an argument — precisely what a second model is for. Either
  install Codex or stop declaring the row.

### From `gravito_evidence_policy_matrix_a` (2026-07-31, receipt `build-os/receipts/gravito_evidence_policy_matrix_a.md`)

- **(l) THE `75` SWEEP WAS INCOMPLETE — "no stale `75` remains in any registry artefact" was FALSE.**
  **[CLOSED IN THE CLOSE COMMIT. Kept in full, because the finding is about the gates, not the
  counts.]** All four stale sites below now read **78**; `control_registry.txt:1464` was judged
  historical and deliberately left at 75 (resolution at the end of this item).
  The tiny-lane sweep that closed the re-review's 4 sites reported that it had swept the whole class.
  The archivist re-ran the grep at close and it did not hold. `grep -rn '\b75\b' build-os/registry/`
  at `0555717` returned:
  **`CROSSWALK.md:8`** — *"binds each of the **75** registered controls to exactly one of **17**
  primitives"*. **Bolded, present-tense, and it contradicts `CROSSWALK.md:87` in the same file**,
  which the re-review corrected to 78. The file disagrees with itself about the census, 79 lines
  apart, and `:8` is the file's *opening description of what it is*.
  **`CROSSWALK.md:25`** (*"an eighteenth field on each of the 75 registry records"*) and
  **`CROSSWALK.md:39`** (*"costs 75 record edits"*) — both present-tense, both stale.
  **`neurocosmology_crosswalk.txt:169`** (*"a prose field on every one of the 75 registry entries"*)
  — present-tense, stale.
  **`control_registry.txt:1464`** (*"made every one of the 75 live stanzas unclassifiable"*) —
  flagged **AMBIGUOUS** by the archivist, **DO NOT SWEEP MECHANICALLY**. **RESOLVED: LEFT AT 75, and
  it is correct.** It narrates a historical incident — the field-parser off-by-one on
  `evidence-policy.sh`'s *first run*, which necessarily preceded the registration of the three new
  stanzas (the tool had to exist before `evidence.derivation_nonvacuity` could be registered for it),
  so **75 was the live count at the moment narrated**. qa's `78/78` reproduction is a re-drive on the
  *final* tree, not the original incident, and does not date it. The matching sentence in
  `CHANGELOG.md:198` narrates the same incident and is likewise **correct and left**.
  **[REPOINTED 2026-08-01 at the `gravito_p2_claim_scoped_evidence_a` close: was `:106`. Repointed
  BY CONTENT against base `e6b825b`, not by shifting a number — the anchor line is
  `refuted-but-wired-in control belongs. The ladder is now`. Cite the ANCHOR, not the number.]**
  **The archivist deliberately did not fix any of this**, on three grounds: the packet was at its
  2-commit cap, registry artefacts are the packet's *deliverable* rather than archivist memory, and
  an archivist quietly closing a reviewer-class defect inside its own close is the papering-over the
  adoption-guard episode warned about. **That judgement is upheld** — the fixes landed in a
  **separate close commit** on top of the capped pair, not folded into either.
  **THE LESSON, AND IT IS THE VALUABLE PART:** the tiny-lane sweep swept *counts of controls* and
  missed *counts of records* — the same class-boundary error, one level down, as the installment
  failure it was fixing — **because it grepped for hand-written phrases**
  (`"75 controls\|75 bindings\|75 entries\|of 75"`), which matched **none** of the four live sites.
  **Sweep a stale count by the LITERAL NUMBER (`grep -rn '\b75\b'`), classify every hit by hand, and
  close the sweep by re-running the grep — never by asserting it.** These four got past **both review
  gates AND the sweep that claimed the class closed**; they were caught only because the archivist
  re-ran the check at close. They are **not** an escape (nothing reached a reader, and
  `packet_metrics.tsv`'s `defects_escaped` correctly reads `-`), but they are a measured statement
  about what the gates do not see.
- **(m) NOTHING MACHINE-CHECKS PROSE THAT RESTATES A MACHINE-COMPUTED TABLE — three packets running,
  and the highest-value follow-on in this file.** Instances: `MISMATCHES.md` §10's file/lines table
  **twice**; `CROSSWALK.md:87` once (fixed at re-review); `CROSSWALK.md:8`, `:25`, `:39` and
  `neurocosmology_crosswalk.txt:169` (fixed in the close commit — item l). **Every instance so far
  has been fixed by a human read after a gate missed it. The class is still unguarded**; only the
  instances are closed.
  **§5a of `tests/evidence_policy_tests.sh` is the pattern a checker would follow** — it reconciles
  README §3a's cap table against the tool's `EVIDENCE_AXIS` in **both directions** and is red-driven
  both ways (a cap changed to another rung fails the diff; a cap changed to a non-rung fails the row
  count). Same shape closes this class: parse the prose restatement, recompute the table, diff them.
  **The asymmetry is the argument:** qa's mutation test proved the cap table unguarded in seconds,
  while the `CROSSWALK.md` instances consumed a re-review, a tiny-lane sweep, a close **and a
  resumed close** before the last of them landed.
- **(n) THE SUITE COUNT WAS PINNED STALE AGAIN, AND WRITING THE TRUE NUMBER TURNED THE SUITE RED.**
  **[BOTH HALVES CLOSED IN THE CLOSE COMMIT — but the diagnosis below is the point and is kept.]**
  `CHANGELOG.md` now carries the literal `**1485 passed**` and `current_state.md` now reads 1485; the
  close commit could write both because it is not bound by the archivist's `build-os/`-only gate.
  **The structural cause is untouched: the two halves of this check are owned by different lanes.**
  Live total **1485**; the guard-bound token in `current_state.md` read **1418**, left there on
  purpose. Proven at `0555717` in a throwaway clone: setting the line to `1485 checks` yielded
  `FAIL: CHANGELOG does not report '1485 passed'` -> **`41 passed, 1 failed`**.
  `tests/release_metadata_tests.sh:288` runs `grep -qF "<count> passed"` against `CHANGELOG.md`, and
  **the string `1485` did not occur anywhere in the repository** — this packet's CHANGELOG entry
  reported "67 assertions" for the new suite but **never stated the new chained total**, so the
  literal was never created. **`CHANGELOG.md` is outside the archivist's write gate**, which is why
  the archivist could not close it and correctly refused to write a token that would turn the tree
  red. Fix was one literal string in `CHANGELOG.md` plus the token — **now applied**.
  **Third consecutive packet for this pair** (657 -> 1418 -> 1485), and the reason it recurs is
  structural, not sloppiness: **the archivist owns one half of the check and cannot write the other.**
  **And the guard still does not detect staleness:** `current_state.md` at 1418 and CHANGELOG at
  `**1418 passed**` *agreed*, so §5 passed while the truth was 1485. **Two stale files that agree
  pass** — now demonstrated twice on the same token. The check that works,
  `RELEASE_METADATA_LIVE_SUITE=1`, is **still opt-in and still not enabled by the chained suite** —
  and it is the only reason this was caught at all. **Chaining it, or giving the archivist's lane the
  CHANGELOG literal, is the standing follow-on. Neither is done.**
- **(o) AN UNREPRODUCED FLAKE — flagged, NOT diagnosed.** qa's **base clone's first run** reported
  **1398 + 20 = 1418 with no `FAIL:` line captured**. **Five subsequent runs, three of them under
  load, were all 1418 / 0.** **Pre-existing at `6b01173`**; not introduced by this packet.
  Deliberately not chased — one anomaly in six runs is not enough signal to spend a packet on. But a
  suite whose count can move **without a captured failure line** is cheap to dismiss and expensive to
  have dismissed. **If it recurs, the missing `FAIL:` capture is the thread to pull, not the count.**
  **[IT RECURRED, 2026-08-01, at the `gravito_authority_envelope_a` close.]** The archivist's
  `RELEASE_METADATA_LIVE_SUITE=1` run reported `live run of tests/build_os_tests.sh is not green
  (exit 1, 1 failed)` / `live suite total (1596 passed)`, while a **direct** run of the same suite
  on the same quiet tree, seconds apart, reported **1597 passed / 0 failed, exit 0** — and two
  immediately following `RELEASE_METADATA_LIVE_SUITE=1` runs both reported **1597, MATCH, 44/0**.
  **Same shape as the original, one packet later: the count moved by exactly 1 and no `FAIL:`
  line reached the observer.** The reason it did not reach the observer is now KNOWN and is the
  thread to pull: `tests/release_metadata_tests.sh:329-330` writes the nested suite's output to
  `"$WORK/live.log"` inside an `mktemp -d` that is cleaned on exit, and the guard reports only the
  parsed COUNTS (`ACTUAL`, `ACTUAL_FAIL`) — **it never surfaces the failing assertion, so a live
  cross-check failure is structurally undiagnosable from its own output.** That is a cheap fix
  (echo the `FAIL:` lines from `$LIVE_LOG` on the failure branch) and it is the prerequisite for
  ever diagnosing this. **Still not chased** — **1 anomaly in 8 clean-tree runs at this close** (3 further
  nested runs with logs preserved were all 1597/0 with zero `FAIL` lines), 1 in 6 at the last, so
  **2 in 14 across two packets** — but it is now TWO packets running and the diagnosis-blocker is
  identified.
  **[STILL OPEN AND STILL UNDIAGNOSABLE, 2026-08-01, `gravito_mismatch_refuted_a` close.]** Nothing
  about the blocker changed: `tests/release_metadata_tests.sh` still writes the live log into an
  `mktemp -d` that is **cleaned on exit** and still reports **only the parsed counts**, so **a live
  cross-check failure destroys its own evidence.** The cheap fix — echo the `FAIL:` lines from
  `$LIVE_LOG` on the failure branch — is **still not made**, and it remains the prerequisite for
  ever diagnosing this. It is now **three packets** since the flake was first seen.
- **(S1) THE S1 EVIDENCE-TOKEN DECISION — OPERATOR DECISION, AND IT BLOCKS STEP 2.** S1 is slated to
  arrive at `runtimeAuthority: rank` with `empiricalStatus: untested`. **Two collisions.** (1) S1 at
  `rank` on unvalidated evidence **ships out of licence on day one** — survivable, the matrix only
  advises. (2) Worse: **`untested` is not one of the five evidence tokens**, so
  `evidence.derivation_nonvacuity` (**Class A, gate**) **REFUSES THE ENTIRE DERIVATION at exit 2**
  rather than flagging S1 — because an unrecognised level must never fall through to permissive,
  which is exactly how a matrix stops discriminating while still printing green. Confirmed
  empirically by the reviewer, and **reproduced independently by the archivist at close** by
  injecting `untested` into a throwaway clone of `0555717`:
  `evidence: UNREADABLE ... empirical_status token "untested" has no cap on the evidence axis` /
  `evidence-policy: REFUSED`, **exit 2**. **The operator must choose: add `untested` as a sixth
  token with its own cap, or have S1 arrive carrying `unvalidated`.** Adding a token *purely to make
  a planned control fit* is the failure mode the registry exists to prevent, so this is a governance
  decision, not a mechanical one. **Neither move is taken.** Found by a packet that can only advise,
  **before S1 was built**.
- **(p) `maint.tripwire_coverage_scan` — RESOLVED 2026-08-01 BY MEASUREMENT, AND THE RESOLUTION IS
  "NO CHANGE". DO NOT RE-OPEN THIS AS SCHEDULED WORK.** It was flagged twice (class axis: declared
  mismatch; evidence axis's sharp rule: capped at `observe`), the reviewer had called it **the
  strongest demotion candidate in the census**, and its own `demotion_requirement` **literally
  prescribed its own demotion**. `gravito_mismatch_refuted_a` was **authorised** by the operator's
  step-3 ruling to perform it, **applied it**, and **measured both arms** against an uncovered suite
  file that rewrites real memory: **GATED — throws, exit 1, real tree sha256-IDENTICAL; DEMOTED —
  prints, exit 1, `residue.md` TRUNCATED 1621 B -> 8 B and replaced with `DAMAGED`.**
  **THE EXIT CODE IS 1 IN BOTH ARMS**, so nothing watching exit codes can see this demotion at all;
  only inspecting the tree reveals it. That gate is the maintenance layer's **only PREVENTION** —
  `maint.real_memory_tripwire` and `maint.shell_fingerprint` are detection and both declare
  `rollback_behavior: NONE` — so **retirement is strictly worse than demotion**. **Both outcomes are
  CLOSED with the measurement attached** (`COVERAGE-GATE-PREVENTION-DIFFERENTIAL`,
  `tests/build_os_maintenance_tests.sh` §6a). It stays at `gate`, its mismatch stays **declared**,
  and **keeping the gate is not a claim to be in licence**. The refutation is also **PATH-SCOPED** —
  the DETECTION claim failed on the bare `node --test` path; on the sanctioned path the same scan is
  measured PREVENTION — which one unqualified `refuted` token cannot say.
- **(q) SECOND-EYES WAS DECLARED AND NOT DELIVERED — on BOTH passes, again.**
  `build-os/memory/tool_router.md:368` routes reviewer second-eyes to Codex; `codex` is not on PATH
  and no Codex plugin is installed. **Both verdicts in this packet are single-model, and the row is
  now UNBACKED** — declared and undelivered on every packet that has invoked it. It matters
  specifically here: **the two gates found different things by using different methods** (inspection
  vs mutation), which is direct local evidence that an independent third perspective pays. The
  declared third perspective is the one that never ran. **Either install Codex or stop declaring the
  row.**

### From `gravito_authority_envelope_a` (2026-08-01, receipt `build-os/receipts/gravito_authority_envelope_a.md`)

- **(r) A STRUCTURAL CITATION DEFECT — AND IT IS GUARANTEED, NOT OCCASIONAL.** `residue.md:280` (in
  item (l), above) and `build-os/receipts/gravito_evidence_policy_matrix_a.md:572-573` cite
  `CHANGELOG.md:198` and `CHANGELOG.md:223`. **Both were correct when written.**
  `gravito_authority_envelope_a`'s **145-line prepend invalidated them**, verified at close:
  `CHANGELOG.md:198` now sits inside that packet's zero-grants argument and `:223` inside the S1
  tension — neither narrates what its citation claims. **This will happen to EVERY `CHANGELOG.md`
  line-citation on EVERY future packet**, because the changelog grows **from the top**: every landed
  citation into it decays by the size of the next release block. **The decay is structural and
  guaranteed, not occasional drift**, which makes it different in kind from the `MISMATCHES.md`
  class below — that one decays when a file is edited near the cited line; this one decays on every
  packet unconditionally. **Remedy: cite by RELEASE-BLOCK HEADING, and stop creating new
  line-citations into `CHANGELOG.md` at all.** The two live citations above are left as-is here so
  the next packet can fix them by heading in one pass; nothing outside `build-os/` was written by
  the close that found this.
- **(s) [STREAK ENDED 2026-08-01 — THE INSTANCE IS CLOSED, THE CLASS IS NOT.]** qa confirmed at
  `gravito_mismatch_refuted_a` that the `:960` reference **was corrected in `a7ab841`**, and that
  packet **inherits a correct citation**. The six-packet streak is over. **The class (item m) is
  still unguarded** and a working sweep exists only as a throwaway — see item (aa). Original entry
  preserved below.
  **(s) `MISMATCHES.md` HAD CARRIED A STALE LINE REFERENCE IN SIX CONSECUTIVE PACKETS.** §10's table
  **names its own decay mode in prose** and nothing checks it. Six packets is no longer a recurring
  incident — it is a permanent property of the file. Same class as item (m). Most recent instance:
  `MISMATCHES.md:248`'s `:938`, which the builder found only by sweeping the class by number, and
  which sat in the **same sentence** as the `:960` the reviewer had flagged; neither the reviewer
  nor the orchestrator saw it.
- **(t) A SECOND INSTANCE OF THE SAME SPECIES, AND THIS ONE DEGRADES SILENTLY.**
  `build-os/tools/authority-envelope.sh`'s `--help` uses a **hand-maintained `sed` range**,
  `sed -n '2,196p'`, **duplicated across TWO handlers** (`:235` and `:245`). **It was live and
  broken until the fix round caught it.** The property that makes it worse than (s): when the range
  goes stale it **silently truncates the help text rather than failing**. A hand-maintained line
  number that *errors* when stale is a nuisance; one that *quietly returns less* can persist
  indefinitely. **Nothing tests it** — not its length, not its start, not that the two handlers
  agree.
- **(u) AN ENTIRE PACKET WAS BUILT WITH NO DECLARED PACKET, AND THE CONTROL PASSED CLEAN.**
  `gravito_authority_envelope_a` — two commits, +2142 lines, three new registered controls — was
  built with `build-os/packets/active_packet.md` reading **"NO PACKET IN FLIGHT"**. The orchestrator
  dispatched without setting it. **The reviewer ruled: DO NOT back-write the file**, because that
  would manufacture an artefact stating a packet was declared when it was not — precisely the
  falsehood the envelope store avoids by keeping its worked example inside `#` comments. **The file
  was not back-written; the record stands as the true one.**
  **The gap:** `bandwidth.active_packet_singleton` refuses **TWO** declared packets but permits
  **ZERO**. **This is item (c)'s disclosed "delete the file evades it" hole in a STRICTLY WORSE
  FORM:** the delete branch requires an **affirmative destructive act**; this one **fires on pure
  omission** — nobody has to do anything wrong, somebody merely has to not do something.
  Omission-triggered evasions are the ones that happen by accident, repeatedly. **This is the first
  recorded instance, and it happened on the very next packet after (c) was written down.**
  The fix is a floor, not a ceiling: assert a declared packet EXISTS while a packet is in flight.
- **(v) NON-BLOCKING — REVIEWER FLAGGED AND EXPLICITLY PASSED. DO NOT TREAT AS OPEN.**
  `tests/evidence_policy_tests.sh:322` — §5b's non-vacuity floor is `NRD == NTD && NRD != 0`, which
  is **weaker** than §2a's `NRD == NMODE && NTD == NMODE`: §5b's form would pass if both sides
  yielded 2 of 4 rows. **It is not a live hole** — §2a of `tests/authority_envelope_tests.sh` covers
  the same axis in both directions with the mode count as the floor on both sides. **Align §5b
  whenever that file is next open for another reason.** Recorded so a future reader does not
  mistake a passed-with-comment item for an open defect.
- **(w) THE CENTRAL RESULT, RECORDED HERE BECAUSE IT RE-SCOPES FUTURE WORK: AN ENVELOPE CAN ONLY
  LOWER `L_effective`; IT CANNOT LEGITIMISE A GRANT.** The reviewer wrote a well-formed operator
  grant of `gate` to `adoption.lane_size_check` and got `OVER-GRANTED ... granted=gate
  l-class=advise l-effective=advise binding-axis=class`, with `evidence-policy.sh`'s 19 finding
  lines **byte-identical** against an empty store. The behaviour is **correct** — the tool refuses
  to launder a Class-C gate even when the operator signs off. **Consequence: step 3 (applying
  promotion/demotion rules to the fourteen declared mismatches) CANNOT be done by writing
  envelopes.** All fourteen exercise MORE authority than their class licenses, and an envelope only
  subtracts. **Step 3 needs a class change or a different instrument, and neither is designed.**
  **Do not cut a packet that writes envelopes to fix mismatches.**
- **(x) THE SUITE-COUNT PAIR IS CLOSED — 1485 -> 1597, AND AGAIN 1597 -> 1617 — BUT THE STRUCTURE
  THAT BREAKS IT IS UNTOUCHED, AND IT HAS NOW CLOSED TWICE FOR THE SAME LUCKY REASON.**
  **[UPDATED 2026-08-01 at the `gravito_mismatch_refuted_a` close.]** Live total is **1617**; this
  file's and `current_state.md`'s prior claim of **1597** was a **sixth** demonstration that §5
  checks cross-file AGREEMENT and not liveness. It closed again only because **the builder** wrote
  the live total into the CHANGELOG entry (`**1617 passed**`, present exactly once and unsplit),
  giving the archivist a literal to match. **Twice running, the loop has closed by luck of the
  builder's phrasing rather than by design.** Original entry follows. See items (f), (g), (n). It closed at this packet's close only because the
  **builder** happened to write the live total into the CHANGELOG entry (`CHANGELOG.md:124`,
  `**1597 passed**`, present exactly once and unsplit), giving the archivist a literal to match. The
  archivist still cannot write `CHANGELOG.md`. **§5 still cannot detect staleness** — it checks
  cross-file agreement, and `current_state.md` at 1485 agreed with a landed `1485 passed` at
  `CHANGELOG.md:267` while the live total was 1597, which is a **fifth** demonstration on this same
  token. Verified at close in both directions: before the memory write,
  `RELEASE_METADATA_LIVE_SUITE=1` reported `live suite total (1597 passed) contradicts
  current_state.md's claim (1485) — the memory is stale` **while the chained suite was green at
  1597/0**; after, it reports a match. **`RELEASE_METADATA_LIVE_SUITE=1` is the ONLY check in this
  repo that compares memory against a live run, and it is still opt-in and still not chained.**
- **(y) DEPTH DEFECT — FOUR SERIAL STAGES, AND THE CAUSE IS A DIFFERENT ONE FROM LAST PACKET'S.**
  `gravito_evidence_policy_matrix_a`: **incomplete ENUMERATION** (the fix list arrived in
  installments). `gravito_authority_envelope_a`: **incomplete APPLICATION** — the reviewer swept the
  whole class first and enumerated correctly in **one** installment, and stage 4 still happened
  because **two of its nine items did not fully land**: item 7 renamed a section header **without
  the two prose references pointing at it**, and item 6 **over-corrected a false claim into a
  different false claim**. **The two failure modes need different remedies.** Sweep-the-class fixes
  enumeration and was correctly applied here. What is missing from the process is that **a fix round
  must verify each item LANDED, not that each item was addressed** — a rename is not done when the
  definition changes, it is done when nothing still points at the old name. **The reviewer
  self-identified this without being asked, for the second packet running.**
- **(z) SECOND-EYES DECLARED AND NOT DELIVERED — on BOTH passes, for the third packet running.**
  `build-os/memory/tool_router.md:368` routes reviewer second-eyes to Codex; `codex` is not on PATH
  and no Codex plugin is installed. **Both verdicts in `gravito_authority_envelope_a` are
  single-model.** It matters here for a specific reason: the two findings that mattered most were
  both produced by **mutation** — changing one token and watching a green suite stay green — and
  both were produced by the reviewer alone, with qa green. **Either install Codex or stop declaring
  the row.**

### From `gravito_mismatch_refuted_a` (2026-08-01, receipt `build-os/receipts/gravito_mismatch_refuted_a.md`)

- **[SUPERSEDED 2026-08-01 BY ITEM (pp) — THE COUNT IS FOUR, NOT TWO. Left in place because the
  sweep-as-a-throwaway half is still true and unbuilt.]**
- **(aa) PROSE CITATIONS HAVE **TWO** KNOWN ESCAPE FORMS, AND THE ONLY WORKING SWEEP IS A
  THROWAWAY.** The known form is a **bare `:NNN` reference**. The second is **`MISMATCHES.md` §10's
  nonvacuity-table row form, which names a file with NO LINE NUMBER AT ALL** — a citation shape that
  every `:NNN`-shaped sweep is structurally blind to. **The builder's own first sweep pass
  mis-resolved that table and had to be redone.** A sweep that handles both forms **was written and
  works**, and it **exists only as a throwaway script** — it is not in the tree, nothing chains it,
  and nothing re-runs it. This is the cheapest item in the citation class (items m, r, s) because,
  uniquely among them, **the implementation already exists and only needs landing**.
- **(bb) OPERATOR DECISION 1 — A FIFTH OUTCOME IS MISSING FROM THE FRAMEWORK.** The operator's
  step-3 framework offers **demote / correct class / improve evidence / retire**. But **demotion
  onto the rung the `refuted` cap prescribes is UNSPELLABLE for 67 of 81 controls (83%)** — every
  `load_bearing` one — and **0 controls sit at `observe` today**. The reviewer's proposal:
  **ACCEPT AND CONSTRAIN** — leave the authority where it is, **keep the finding standing**, and
  require an **operator envelope**. `build-os/registry/authority_envelopes.txt` exists with **0 live
  grants**, which is exactly what it was built for. **Not adopted. Operator's call.**
- **(cc) OPERATOR DECISION 2 — THE LADDER HAS A DEFINITIONAL BUG, AND FIXING IT IS NOT ONE LINE.**
  `none` = *"nothing consumes it"* and `observe` = *"it measures and records. Nothing reads the
  result"* — **both bottom rungs are defined by non-consumption**, so **no rung means "it is read,
  but may cause nothing"**, which is precisely the state a refuted-but-wired-in control should
  occupy. **The fix touches SIX prose sites AND `scan-controls.sh`'s `OBSERVE-LB`, which is the part
  that actually binds.** The six: README §2's **two** bottom rungs, README §3b's `shadow` row,
  `authority_envelopes.txt`'s header, and both tools' headers. **Deleting every line of README prose
  leaves `OBSERVE-LB` refusing at exit 2 and the demotion still unwritable for all 67.**
  **A remedy its own guard survives is not a remedy.** Do not cut a one-line packet for this.
- **(dd) OPERATOR DECISION 3 — `OBSERVE-LB` MAY BE CORRECTLY REASONED BUT MIS-PLACED IN AUTHORITY.**
  It sits on the **gating** path (`build-os/registry/scan-controls.sh`, **exit 2**) while the axis it
  defends deliberately only **advises** (`build-os/tools/evidence-policy.sh`, **exit 0**). The
  advisory axis was designed so that **nothing gets demoted automatically with no operator in the
  loop**; this guard **removes the operator's ability to apply the demotion BY HAND as well.** The
  **reviewer declined to demand a move** — it is a design call, recorded as open.
- **[RESOLVED 2026-08-01 BY DEMONSTRATION — NO THIRD COMMIT AND NO HOOK WERE NEEDED.]**
  `gravito_ladder_semantics_a` spent **Commit 1 on the declaration ALONE** (`576751a`): trivially
  green in isolation, the `<=2-commit` cap intact, and **git now corroborates the ordering**.
  Nothing ever required the docs to be the SECOND commit. **This is the standing pattern from
  here on.** The item below is left intact as the record of the tension it answers. **The
  underlying control gap is NOT closed** — `bandwidth.active_packet_singleton` still refuses two
  declared packets and permits zero, so pure omission passes clean; see (c)/(u).
- **(ee) "DECLARE BEFORE BUILDING" AND THE `<=2-COMMIT` RULE ARE IN GENUINE TENSION — OPERATOR
  DECISION, DELIBERATELY UNRESOLVED.** `gravito_mismatch_refuted_a` **DID declare itself before
  building**, which is the fix for item (u). **But the reviewer observed that the declaration landed
  in the SAME COMMIT as the build** (`b25f3f7` touches `build-os/packets/active_packet.md` alongside
  the guard and the tests), **so git cannot attest the ordering.** The claim is true; git simply
  cannot corroborate it. **Attesting it needs a third commit or a pre-commit hook**, and the packet
  is capped at two commits. **This close does not resolve it.** Item (u)'s floor — *assert a declared
  packet EXISTS while a packet is in flight* — is still unbuilt.
- **(ff) `maint.source_scan_mask`: ALL FOUR OUTCOMES CLOSED, EACH FOR A DIFFERENT REASON — AND IT IS
  **NOT** A SECOND DATA POINT FOR `outputSemantics`.** Demotion **writes a falsehood** (README §2
  defines `observe` as "nothing reads the result"; **two controls read this one's result** — verified
  at **import AND call sites**), and `OBSERVE-LB` now refuses it mechanically. Retirement **breaks
  both consumers** (`maint.tripwire_coverage_scan` and `rotate-memory.rootscan.test.mjs`). Improving
  the evidence is **forbidden by its own `promotion_requirement`** (defeated three times; the
  maintainers stopped writing mask heuristics deliberately). Its **class is not wrong** — a
  defeatable lexer really is a heuristic. **So the finding is REAL and its prescribed remedy is
  UNREACHABLE.**
  **THE CORRECTION THAT MATTERS COMMERCIALLY:** the packet first recorded this as a **second
  demonstration of the `outputSemantics` split**, and **the reviewer refused it** with a decisive
  test — **`outputSemantics` would not fix it**, because `observe` would still mean "nothing reads
  the result". The collision is between **`runtime_authority`'s consumption clause** and
  **`implementation_status`**: a redundancy between **two fields that BOTH ALREADY EXIST**, not a
  missing third concept. **The operator committed to `outputSemantics` for S1 on a DIFFERENT case;
  counting this as a second data point would inflate confidence behind that design using a case that
  does not test it.**
- **(gg) DO NOT EXTRAPOLATE THE TWO REFUTED CLOSURES TO THE REMAINING TWELVE MISMATCHES.** These two
  controls were selected **precisely because `refuted` made action look settled**, which makes them
  **the least representative pair in the census**. **Of the 19 findings, 11 are `unvalidated`** —
  *nobody measured* — and for those the remedy is **outcome 3, improve the evidence**, which is
  **WIDE OPEN**. It was closed here **only** because `source_scan_mask`'s own
  `promotion_requirement` explicitly forbade it, which is a property of one control, not of a class.
- **(hh) A REVIEWER WITHDREW ITS OWN PRIOR RULING, ON THE RECORD — KEEP THIS VERBATIM.**
  *"I reasoned from the token `refuted` rather than the evidence the token points at… Reasoning from
  a label instead of its referent is precisely the failure this registry exists to catch."*
  **A reviewer correcting itself on the record is the behaviour the system is supposed to produce**,
  and it is filed as such rather than as a defect. Related, and equally worth keeping:
  **EVADABILITY IS NOT NON-DISCRIMINATION** — the defect `maint.tripwire_coverage_scan` exists
  against was an **ACCIDENT** (a suite file carrying no tripwire, destroying live memory at exit 0),
  and against that it discriminates exactly.
- **(ii) A FALSE REMEDY SURVIVED A REVIEW ROUND, AND THE FAILURE MODE HAS A NAME.** The packet
  wrote, in **two** places, that the `observe`-rung foreclosure is fixed by *"deleting the
  consumption clause from README §2's ladder definitions, a one-line edit"*. **Both halves were
  false** (see item cc). **A future packet could have executed that prescription faithfully and
  achieved nothing.** The reviewer's framing is the transferable part and is exactly what
  `MISMATCHES.md` says about itself: *"a wrong exclusion gets caught by re-running the rule, and a
  wrong reason is what the rule is re-run against."* **NOTHING RE-RUNS A REASON.** This is the same
  class as item (m) — prose that restates something machine-enforced — but one level worse: here the
  prose restated a **remedy** rather than a **table**, and no diff-both-ways checker of the (m) shape
  would have caught it.
- **(jj) DEPTH DEFECT — FOUR SERIAL STAGES, AND THE REVIEWER'S OWN ACCOUNTING IS MORE PRECISE THAN
  THE RULE.** **It was NOT a withheld installment:** both second-round items concerned text that
  **did not exist at stage-2 review** — item A was **the item-2 replacement itself**, and item B was
  a collision **the ALSO-RECORD note created by landing**. A reviewer cannot enumerate text a later
  stage will write. **But the reviewer named the honest reading anyway:** item 2 was cut as *"replace
  a false claim"* when it was really *"replace a false claim AND state the correct radius"* — the
  **same INCOMPLETE-APPLICATION shape as `gravito_authority_envelope_a`** (item y), **two packets
  running**. The remedy is unchanged and still not in the process: **a fix round must verify each
  item LANDED, not that each item was addressed** — and, new here, **an item that replaces a false
  claim must state the replacement's radius, or it will be applied at the wrong one.**
- **(kk) qa CAUGHT A TRAP IN ITS OWN WORK, AND THE DISCARDED NUMBER IS RECORDED SO IT DOES NOT LEAK.**
  A **first** Commit-1 isolation run reported **1592**; qa traced it to a **stale clone directory
  that made `git checkout` fail silently**, so the run measured the wrong tree. **qa discarded and
  redid it.** **1592 IS NOT A NUMBER FROM THIS PACKET** — it is the count of a tree that was never
  checked out. Filed because a loose count in a transcript is exactly the kind of thing a later
  reader reconciles against and cannot resolve.
- **(ll) SECOND-EYES DECLARED AND NOT DELIVERED — on the review AND both re-reviews, for the FOURTH
  packet running.** `build-os/memory/tool_router.md:368` routes reviewer second-eyes to Codex;
  `codex` is not on PATH and no Codex plugin is installed. **Both verdicts in
  `gravito_mismatch_refuted_a` are single-model.** It matters specifically here: **the reviewer
  withdrew its own prior ruling** (item hh) and **a false remedy survived a full review round** (item
  ii) — both are exactly what an independent second model is for, and the declared second model is
  the one that never ran. **Either install Codex or stop declaring the row.**

- **(mm) THE CITATION GUARD CHECKS RESOLVABILITY, NOT IDENTITY — QUANTIFIED, AND IT RETROACTIVELY
  DISCOUNTS EARLIER CLAIMS.** qa located the cause at **`build-os/registry/scan-controls.sh:368-392`**
  (**repointed 2026-08-01 from `:362-386` BY CONTENT against base `e6b825b`** — both endpoints
  content-pair at +6: `# --- 6. evidence must resolve ---` and
  `[ "$nref" -ge 1 ] || viol "NO-EVIDENCE ..."`):
  the `evidence_refs` loop tests **existence** (`[ ! -f "$REPO/$rf" ]`), **numeric**
  (`case "$rl" in ''|*[!0-9]*)`), **in-bounds** (`[ "$rl" -le "$tot" ]`) and **not-blank**
  (`vacuous_why`). **IT NEVER COMPARES CONTENT.** Measured across the three tools whose refs drifted:
  **27 of 27 would have cited a DIFFERENT LINE**; `VACUOUS-REF` caught **7**; **20 PASSED EVERY
  CHECK WHILE SILENTLY WRONG.**
  **THE REVIEWER'S COROLLARY, WHICH MUST BE KEPT VERBATIM BECAUSE IT DOWNGRADES PRIOR RESULTS:
  a content match at a SINGLE COMMIT tests RESOLVABILITY; only a CROSS-COMMIT comparison tests
  IDENTITY.** Several *"zero drift, 287/287 verified"* results earlier in this sequence were **the
  former and were reported as the latter** — true statements of a **weaker property** than the one
  claimed. **Discounted, not retracted.** **The durable fix is an ANCHOR TOKEN or a CONTENT HASH
  instead of a line number**, which also subsumes item (aa)'s sweep-as-a-script. Not built.
- **(nn) THE MUTATION-CENSUS COVERAGE GAP — THE REVIEWER CALLED IT THE PACKET'S MOST VALUABLE OUTPUT
  AND RULED IT THE NEXT PACKET.** `build-os/registry/MISMATCHES.md` §15 surveys all 81 controls
  against the new `execute` rung.
  **The sharp case is NOT at `gate`.** `maint.managed_set_replacement` sits at **`advise`** while its
  declared `output` is *"files copied into an installed repo, replacing prior managed copies"*, its
  `failure_behavior` is *"none that stops anything"* and its `rollback_behavior` is *"none; a managed
  file's local edits are lost on install"*. `advise` means *the output may influence a human or a
  higher-authority control*. **Copying files over a user's edits is not influence.** On the corrected
  ladder that is `execute` — **two rungs up** — and it is `unvalidated`, so nobody has watched it.
  **FIVE MODULES DURABLY MUTATE AND NOT ONE OF THOSE WRITE ACTIONS IS A REGISTERED CONTROL AT ANY
  AUTHORITY:** `build-os/maintenance/rotate-memory.mjs` (`renameSync` **onto the live memory file** —
  the most consequential write in the system), `build-os/tools/swarm-merge.sh` (creates a commit
  behind `--commit`), `build-os/metrics/record-packet.sh` (appends to the live store),
  `.claude/hooks/build-os-identity.sh` (writes the identity stamp into the repo),
  `build-os/tools/specialist-handoff.sh` (takes a lock under `$HOME`).
  **THE REVIEWER'S RULING ON THE PACKET'S OWN DEFENCE, KEEP IT VERBATIM:** *"the controls are checks
  and the mutations belong to the modules they live in"* is **sound as a description of what the
  registry covers, and convenient as a reason not to extend it** — and **the most consequential
  write in the system has no entry.**
  **Registering those actions is a RE-AUTHORISATION and is therefore the OPERATOR'S ACT.** Nothing
  in the closing packet performed one; `evidence-policy.sh check` is **19 of 81, 6/5/8 — unmoved**.
- **(oo) A PUSHED COMMIT SHIPPED RED, AND THE CLOSE CHECKLIST IS THE CAUSE — ORCHESTRATOR DEFECT.**
  qa confirmed that **`2df61ae` — which is PUSHED —** ships `./build-os/maintenance/run-tests.sh` at
  **143 passed / 1 failed**. Cause: the archivist close that wrote it cleared
  `build-os/packets/active_packet.md` to **2** `^## ` blocks, while `rotate-memory.mjs`'s two-pass
  rotation proof needs **>=3 blocks per rotating file** (`tests/scaffold_seeding_tests.sh:242`).
  **NOTHING CAUGHT IT BECAUSE THAT SUITE IS NOT CHAINED INTO THE 1636 AND THE ORCHESTRATOR'S CLOSE
  BRIEF DID NOT ASK FOR IT.** **Record it as an orchestrator defect, not an archivist one**: a close
  checklist that omits a live suite is how a red commit reaches a remote. **`576751a` alone repairs
  it** (2 blocks -> 10). **Remedy: chain that suite, or name every live suite in the close checklist.**
  **THE SHARPER HAZARD WAS PARTLY REFUTED, AND THE CORRECTION IS THE POINT.** The record said a
  zero-block file *"silently never rotates"*. Measured: a zero-block file **genuinely never rotates
  and fails nothing** — byte-identical after `--apply`, exit **0** — **but it is NOT SILENT**;
  `rotate-memory.mjs` prints `WARNING: <path>: the block delimiter /^## / matched NOTHING … NOTHING
  CAN EVER ROTATE OUT OF IT` to stderr, and that warning exists at base with the module untouched.
  **The failure mode is AN IGNORABLE WARNING, NOT SILENCE.** Corrected in the closing packet's own
  prose and **annotated in place** in `current_state.md` — annotated rather than rewritten because
  the surrounding entry is a historical packet log with a commit pin. **The receipt and the released
  `CHANGELOG.md` block are frozen records and were deliberately left carrying the wrong word.**
- **(pp) FOUR ESCAPE FORMS FOR THE SAME CLASS OF GUARD, ALL THE SAME SHAPE — supersedes item (aa)'s
  count of two.** Every one is **a guard written against ONE surface form and blind to its
  siblings**:
  1. **Bare `:NNN` citations**, with the filename elsewhere in the sentence.
  2. **`MISMATCHES.md` §10's table rows**, which name a file with **no line number at all**.
  3. **LINE-WRAPPED ENUMERATIONS** — `none < observe < advise` on one line, `< rank < gate)` on the
     next. **No same-line grep can see it; a multiline scan finds it at once.** This is how a
     **FIFTH** stale five-rung ladder survived in `tests/neurocosmology_crosswalk_tests.sh` — **a
     file the packet had already edited** — past the orchestrator's sweep AND the reviewer's first
     pass.
  4. **MARKDOWN TABLE-ROW MAPPINGS** — `| shadow | observe | … |`, where the new guard expects
     `-> observe`. **`tests/evidence_policy_tests.sh` §21's successor block is therefore
     STRUCTURALLY VACUOUS OVER `README.md`, THE FIRST OF ITS SEVEN LISTED SITES.** Proven, not
     argued: that row was rewritten to carry a consumption clause and **all three blocks missed it**.
     **The rule is sound; the implementation covers one syntax of two.** Recorded rather than
     patched, because patching it inside a stage-3 round is how fix lists arrive in installments.
  **AND THE PACKET REPRODUCED ITS OWN HEADLINE DEFECT TWICE.** It found a guard checking the wrong
  property, then built §21 in the same shape one level up: **§21 greps only ONE of the retired rule's
  TWO wordings** — README's *"nothing reads the result"* but not the deployment axis's *"nothing
  consumes it"* — **which is exactly why the stale definition survived in the file that OWNS the
  axis** — and its successor block covers **one of the mapping's two syntaxes**. Both found by
  review, fixed or recorded, and named in the artefact.
- **(qq) THE `observe`/`advise` BOUNDARY IS NOW INTENT-BASED AND NO LONGER MECHANICALLY CHECKABLE —
  RECORDED AS A COST, NOT AS A WIN.** `gate` has a test (*exits non-zero*), `execute` has one
  (*performs a durable write*), `none` has one (*names no consuming policy*). **`observe` USED TO
  have one** — non-consumption is greppable — **and defining the rung by CONSEQUENCE removes it.**
  **Three of six rungs are now separated by the author's assertion alone.** **This was the right
  trade** — the checkable boundary is precisely what made the rung **unreachable for 67 of 81
  controls** — **and the loss is real.** Stated in `build-os/registry/README.md` §2 and in the
  receipt. **Anything that later claims the ladder is machine-verifiable end to end is wrong.**
  Related, and worth keeping separate: **`execute` is EARNED, not another empty rung.** The
  reviewer's distinction — **`rank` is 0-occupancy because nothing in the system ranks, so the
  concept has NO REFERENT; `execute` is 0-occupancy because FIVE REAL, NAMED, DURABLE MUTATORS EXIST
  AND ARE UNREGISTERED.** Occupants demonstrated by survey, not asserted.
- **(rr) THE LADDER'S SPELLING SWEEP STAYS DEFERRED — ALL THREE GROUNDS UPHELD, THE EVIDENCE FOR IT
  WAS NOT.** `MISMATCHES.md` §16. The reviewer upheld: (i) it lands in **a different site set** from
  the semantics sweep; (ii) **the five-rung string is a PREFIX of the six-rung one**, so it needs an
  enumeration-**CONTINUATION** test — **a containment test passes on the correct string**; (iii)
  bolting a second guard onto a stage-3 round is how fix lists arrive in installments.
  **WHAT WAS UNSOUND WAS THE DEFERRAL'S EVIDENCE, NOT THE DEFERRAL.** §16 claimed *"four live places
  … listed so the packet can prove it found them all."* **It was five** — the fifth being the
  line-wrapped one at (pp)(3). **The wrong number is LEFT VISIBLE IN THE RECORD ON PURPOSE**, on the
  orchestrator's call: **a completeness claim that turned out false is the strongest available
  argument for the guard §16 was deferring**, and it is **the same enumeration-plus-assertion defect
  the packet had just fixed at item 10.**
  The sharpest of the found sites is kept here too: **a PASSING TEST WHOSE TRANSCRIPT PRINTED A
  FALSE LADDER.** Both suites compared against the six-rung `$LADDER` — **the assertion was right** —
  and then reported success with a **hard-coded five-rung string**. **The proof was right and the
  evidence it emitted was wrong**, which is the worst kind, because it is the one a reader trusts.
  All five were repaired by hand and the `ok` messages now derive from `$LADDER`.
- **(ss) SECOND-EYES DECLARED AND NOT DELIVERED — FIFTH PACKET RUNNING, AND THIS TIME IT GATES A
  RETROACTIVE CLAIM.** `build-os/memory/tool_router.md:368` routes reviewer second-eyes to Codex;
  `codex` is not on PATH and no Codex plugin is installed. **Every verdict in
  `gravito_ladder_semantics_a` — the review and both re-reviews — is single-model.** It matters
  here specifically: **the reviewer's resolvability-vs-identity corollary retroactively discounts
  earlier "zero drift" results across several packets** (item mm), and a retroactive downgrade of
  prior evidence is exactly what an independent second model exists to check. **Either install
  Codex or stop declaring the row.**
- **[PHASE CONTEXT 2026-08-01 — everything below this line is now subordinate to it.] THE
  GOVERNANCE-ONLY PHASE IS OVER; the operator issued BUILD AUTHORITY with an ANTI-STALL RULE.**
  *"the governance substrate is no longer the bottleneck. The bottleneck is now whether Gravito can
  begin making better decisions than today's planning approaches."* Five phases:
  **P1 mutators/IDs/telemetry (DONE) -> P2 claim-scoped evidence -> P3 `accept_and_constrain` ->
  P4 S1 shadow ranker -> P5 outcome/counterfactual telemetry.** Residue items are still real; they
  are **built around and recorded**, not paused on.
- **(tt) FIVE ESCAPE FORMS NOW, AND THE NEWEST ONE REACHES NO FIELD-SCOPED SWEEP: THE FILE HEADER
  COMMENT.** `gravito_p1_mutators_ids_telemetry_a`'s seventh missed site was
  `build-os/registry/neurocosmology_crosswalk.txt`'s **header comment** — *"1 binding out of 22"*
  against a live **23**, and *"12 out of 25"* against a live **14 of 27**. **A HEADER COMMENT IS NOT
  A FIELD, so a field-scoped sweep cannot reach it.** The full catalogue, all one shape — *a guard
  written against one surface form, blind to its siblings*: (i) bare `:NNN` citations with the
  filename elsewhere in the sentence; (ii) table rows naming a file with **no line number at all**;
  (iii) **line-wrapped enumerations**, which no same-line grep can see; (iv) **markdown table-row
  mappings**; (v) **header comments**. Supersedes the "four escape forms" count at (pp).
- **(uu) THE SWEEP HIT THE DERIVED DOC AND MISSED THE SOURCE ARTEFACT — SWEEP THE SOURCE FIRST.**
  Round 1 corrected **five** stale counts in `build-os/registry/CROSSWALK.md` and **never swept
  `build-os/registry/neurocosmology_crosswalk.txt`, the artefact `CROSSWALK.md` IS DERIVED FROM** —
  a file the same packet had **already edited**. **Seven more stale sites were there.** Correcting
  the OUTPUT and leaving the INPUT wrong means **the next regeneration reintroduces the defect**.
  The reviewer named the cause as its own: `DEFECT-0007-incomplete-enumeration`, **the same class as
  its own item-8 miss**. **Rule for every future sweep: sweep the SOURCE ARTEFACT, then the DERIVED
  DOC, and say which is which.**
- **(vv) n = 1 — THE WARNING P2 AND P3 MUST ACT ON, OR P4 HAS NOTHING TO TRAIN ON.**
  `build-os/metrics/signal_snapshots.tsv` records **12 rows across ALL FOUR candidates of
  `DECISION-0007-p1-mutators-ids-telemetry`, including the THREE NOT SELECTED** — which is what
  makes P1 a **counterfactual** substrate rather than an imitation-learning one, because imitation
  learning needs only the selected arm. **But `DECISION-0007` is the ONLY decision with a
  non-degenerate candidate set.** `DECISION-0001-fanout-lanes-scaffold-release` is a fan-out where
  **all three candidates were selected**; `DECISION-0002` through `DECISION-0006` are **|C| = 1**.
  **P2 AND P3 MUST KEEP RECORDING REJECTED CANDIDATES OR P4 STARTS AT n = 1.**
- **(ww) PRE-EXISTING, AND THE REVIEWER EXPLICITLY RULED IT NOT `gravito_p1_mutators_ids_telemetry_a`'s
  DEBT: the `defects_escaped` row-count claim is wrong in TWO places and the two DISAGREE.**
  `build-os/metrics/packet_metrics.tsv` holds **11 data rows** (**12** once this close appends its
  own), while `build-os/registry/CROSSWALK.md:319-320` says *"all 6 of 6 rows"* and
  `build-os/registry/neurocosmology_crosswalk.txt:169` says *"all 8 of 8 rows"*. **The derived doc
  and its source artefact again** — see (uu). The *substance* of both claims is still true (the
  column has never held anything but `-`); only the cardinality is wrong.
- **(xx) PRE-EXISTING, ALSO RULED NOT THIS PACKET'S DEBT: a LIVE `DEFECT-0001-stale-line-reference`
  INSTANCE THAT PREDATES IT.** `build-os/registry/MISMATCHES.md:516` and `:549-550` cite
  `tests/control_registry_tests.sh` at **`:79 :184 :440 :772`**, where the live assertions are
  **`:81 :186 :442 :774`** — verified at close by reading both sets of lines. **Off by two, in the
  file that documents the class.**
- **(yy) THE GOVERNANCE BASELINE HAS ONE ESCAPE HATCH, AND IT IS A COMPLETENESS HOLE, NOT A
  CONFORMANCE HOLE.** §11 of `tests/mutator_registry_tests.sh` iterates the rows **PRESENT IN**
  `build-os/registry/governance_baseline.txt` — **so deleting a row and then moving that control
  PASSES.** The only cardinality guard is `NBASE > 0` (`tests/mutator_registry_tests.sh:573-575`,
  **repointed 2026-08-01 BY CONTENT AT BOTH ENDS — `:571-573` against base `e6b825b`, then
  `:573-575` against base `f3c5353`; anchor lines are `NBASE="$(grep -vc '^#' "$BASELINE" ...`
  through `[ "${NBASE:-0}" -gt 0 ] && ok`. A RANGE carries TWO positions, and the sweep that
  moved only the first renamed a three-line guard as a two-line one**),
  which **certifies a store of one**. **The guard checks that what is listed conforms; it never
  checks that the list is complete.** Same shape as the vacuity holes elsewhere in this file.
- **(zz) SECOND-EYES DECLARED AND NOT DELIVERED — SIXTH PACKET RUNNING, AND THIS TIME A REVIEWER
  ERROR WAS CAUGHT ONLY BY THE BUILDER.** In `gravito_p1_mutators_ids_telemetry_a` the reviewer
  wrote **"64 of 90"** for the `red_driven` counterfactual; the builder derived **77 of 90** and
  **validated the METHOD** — the same composition run against `7daedee` **regenerates the reviewer's
  ORIGINAL sentence verbatim** (*68 of 81, 49 newly, on top of 19*), and the orchestrator
  independently reproduced **25 / 77 / 52 / 25**. The reviewer confirmed its own error on re-review.
  **A single-model review chain caught this only because the builder pushed back.** `codex` is still
  absent and `build-os/memory/tool_router.md:368` still declares the row. **Either install Codex or
  stop declaring the row.** Extends (ss).
- **(aaa) THE CLOSE ITSELF BROKE TREE-QUIET, AND ONE SUITE RUN WENT RED BECAUSE OF IT.** At the
  `gravito_p1_mutators_ids_telemetry_a` close the archivist launched
  `bash tests/build_os_tests.sh` in the background and then started
  `./build-os/maintenance/run-tests.sh` **and**
  `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` — **which itself runs a full
  live suite** — while it was still running. **Up to three suite runs were in flight at once**, and
  the first reported **1688 passed / 1 failed**. **A single ISOLATED, SEQUENTIAL run is
  `1689 passed / 0 failed`, exit 0**, and the four suites that touch `packet_metrics.tsv` are each
  green standalone (`speed_benchmark` 169/0, `metrics_adoption` 70/0, `neurocosmology_crosswalk`
  65/0, `pilot_kit` 154/0).
  **TWO LESSONS, BOTH THE ARCHIVIST'S.** (i) `CLAUDE.md`'s **tree-quiet precondition applies to the
  CLOSE, not only to stage 2** — these suites write into shared temp space, so concurrent runs
  produce a number that belongs to no commit. **The close checklist must say: run the suites
  SEQUENTIALLY.** (ii) **The failing assertion's identity was LOST** because the run's output was
  piped through `tail -3`. **Never pipe a gate's output through `tail` before reading it.** The
  honest claim on the record is *"a concurrent run went red once and every isolated run is green"* —
  **NOT** *"the failure was proven harmless"*, which nobody can say from here.

### From `gravito_p2_claim_scoped_evidence_a` (2026-08-01, receipt `build-os/receipts/gravito_p2_claim_scoped_evidence_a.md`)

*Labelled (bbb)–(fff) to continue the file's sequence. The receipt refers to these
as this packet's items (a)–(e), in the same order.*

- **(bbb) THE AXIS SWEEP HAS TWO COVERAGE LIMITS — RECORDED, NO FIXTURE, AND THE REVIEWER RULED THEM
  RESIDUE RATHER THAN DEFECTS.** Section 18 now requires every literal `<NAME>_AXIS="..."`
  restatement under `build-os/tools/` to agree token-for-token with `evidence-policy.sh matrix` —
  **the first fix in this sequence that covers the CLASS rather than the PAIR**, sweeping 3
  restatements today with a fourth covered automatically. Two shapes escape it:
  **(i) a SAME-LINE SECOND ASSIGNMENT** — `FOO=1; EVIDENCE_AXIS="bogus"` — because the anchored
  enumerator never sees the second name on a line; **(ii) the APPEND FORM** —
  `EVIDENCE_AXIS+=" bogus"` — where the sweep passes green while the tool composes with the
  appended token. **The ruling turned on there being NO FAILING FIXTURE**: neither form exists in
  the tree today, so the CHANGELOG's wording is **true of the tree it describes**.
  **SHARPENED BY THE ARCHIVIST AT CLOSE, because it strengthens the item rather than softening it:**
  the same-line *shape* **is already present in the tree**, at `build-os/tools/claim-evidence.sh` —
  `CLASS_AXIS=""; EVIDENCE_AXIS=""`. **This is NOT a counter-example to the ruling**: it is an
  *empty initialiser*, immediately overwritten by a value **derived from `evidence-policy.sh
  matrix`**, so no divergent literal exists and nothing is over-granted. But it means the
  enumerator's blind spot is **reachable by a shape the tree already contains**, not merely by a
  hypothetical one. **Whoever closes this should write the fixture from that line.**

- **(ccc) `MISMATCHES.md` §13 CITES THREE WRONG LINES — AND THEY WERE ALREADY WRONG AT BASE, SO THIS
  IS NOT A REGRESSION THE DIFF INTRODUCED.** `MISMATCHES.md:607` / `:608` / `:609` cite
  `build-os/registry/scan-controls.sh` at **`:454`** (claimed: the `exit 2`), **`:126`** (claimed:
  three directories) and **`:129`** (claimed: five refusal patterns). **All three land on prose
  comments.** True targets, verified by content at close:

  | cited | true target | anchor content |
  |---|---|---|
  | `:454` | **`:471`** | `  exit 2` |
  | `:126` | **`:141`** | `SCAN_DIRS="build-os tests .claude/hooks"` |
  | `:129` | **`:144`** | `REFUSAL_PATTERNS=(` |

  **ALREADY WRONG AT BASE BY NINE LINES:** at `e6b825b`, `SCAN_DIRS` sat at `:135` and
  `REFUSAL_PATTERNS` at `:138` against citations of `:126` and `:129`. **The packet moved the true
  targets by six** (135 → 141, 138 → 144, 465 → 471) **UNDER REFERENCES THAT WERE ALREADY STALE**,
  so **no correctness property changed state**. **The reviewer RECORDED rather than DEMANDED**,
  explicitly to avoid a **sixth stage-4 in seven packets** — a deliberate depth-budget trade, not an
  oversight.
  **THE BITTER DETAIL, PRESERVED BECAUSE IT IS THE WHOLE ARGUMENT FOR ANCHORS OVER LINE NUMBERS:**
  `MISMATCHES.md:611` is a **parenthetical documenting the PREVIOUS generation of this exact bug at
  `:347`**. So **`:454` is GENERATION THREE of a defect the file narrates about itself.**
  **Right home:** a `tiny` edit or the next packet, using the exact targets in the table above.

- **(ddd) THE POSITIONAL CONTENT-PAIRING CHECK IS A REAL DISCRIMINATOR AND BELONGS IN ITS OWN
  PACKET.** It would close the class **§23's vacuity guard cannot see**: F2 walked straight past §23
  because `while IFS= read -r id; do` **is non-vacuous** — the guard checks that the loop has a
  body, not that the body compares anything. The check pairs **every `file:line` reference in the
  tree positionally against its base-commit counterpart and compares by CONTENT**; run at this
  close it was **clean over 338 refs** and **caught the one reference the packet's own new
  assertions had displaced**, which a hand sweep had missed.
  **The reviewer agreed it is a NEW GOVERNANCE CONTROL belonging in its own packet — and recorded,
  honestly, that it could produce NO FIXTURE showing P3 blocked without it.** That is the reason it
  is deferred rather than pulled forward: **the case for it is strong and the urgency is
  unevidenced.**

- **(eee) `valid_until` IS STORED AND ENFORCED NOWHERE — AND P3 MUST OWN ITS OWN EXPIRY
  ENFORCEMENT.** Every stanza in `build-os/registry/evidence_assertions.txt` carries `valid_until`
  and **nothing reads it**. **Inert HERE for two specific reasons, and NEITHER SURVIVES P3:**
  (i) nothing consumes assertions yet, and (ii) composition is `MIN`, so a stale assertion cannot
  raise anything. **P3 (`accept_and_constrain`) is the first consumer**, and the moment an assertion
  can license a constrained acceptance, an **expired** assertion silently licensing it is a live
  over-grant of exactly the F1 shape.
  **THE CHEAP VERSION, AND IT SHOULD BE TAKEN:** fold in `authority_envelopes.txt`'s
  **equally-unchecked `expires`** at the same time. **Two unenforced expiry fields, one enforcement
  path, one packet.**

- **(fff) SECOND-EYES DECLARED AND NOT DELIVERED — SEVENTH CONSECUTIVE PACKET.** `codex` is not on
  PATH and no Codex plugin is installed; `tool_router.md` routes reviewer second-eyes to it. Both
  verdicts on this packet were **single-model**. Item **(zz) already says it plainly — *"Either
  install Codex or stop declaring the row"* — and the row is STILL declared and STILL unbacked.**
  **This is now the longest-running unremedied item in the file, and it is a ONE-LINE FIX in either
  direction.** It bites specifically here: **four times in this sequence a builder or qa has
  corrected a figure the orchestrator or the reviewer relayed** (`64 of 90` → `77 of 90`; `7/4` →
  `10/3/7`; "first counterfactual" → **second**; fitted-floor `38` → **37**). **Cross-checking is
  exactly what the unbacked row was for.**

- **(ggg) AN ARCHIVIST DEFECT, CAUGHT BY A LIVE GUARD DURING THE CLOSE — AND THE CLOSE CHECKLIST
  SHOULD NAME `check-adoption.sh`.** At this close the archivist appended a `packet_metrics.tsv`
  row naming **two commits** while the receipt carried **no file-ownership manifest**.
  `build-os/metrics/check-adoption.sh` refused at **exit 2** with `UNATTRIBUTED`, which took
  **`tests/metrics_adoption_tests.sh`** and **`tests/lane_declaration_tests.sh`** red and dropped
  the live suite to **1769 passed / 2 failed**. **Closed by RECORDING THE MANIFEST the guard asks
  for — NOT by widening a boundary**, which the guard's own refusal text explicitly forecloses:
  *"the boundary is dated, pinned by `tests/metrics_adoption_tests.sh`, and emptying the scope makes
  this guard refuse rather than pass."* The two commit sets are genuinely disjoint (1 file + 21
  files, `comm -12` intersection **empty**), so the manifest is a true statement and not a phrase
  added to satisfy a grep.
  **THE LESSON, AND IT IS THE SAME SHAPE AS (aaa):** the close writes into the tree, so **the close
  can break the build**, and it did. **A metrics row naming ≥2 commits obliges a manifest in the
  receipt**, and nothing tells the archivist that until a guard refuses. **The close checklist
  should name `bash build-os/metrics/check-adoption.sh` explicitly**, alongside the full suite,
  `run-tests.sh` and the `RELEASE_METADATA_LIVE_SUITE=1` cross-check — it is the one live guard that
  measures **the archivist's own output** rather than the packet's.
  **It was caught only because the gates were re-run AFTER the writes.** Had the close run them
  before writing, this would have shipped red exactly as `2df61ae` did.

## Known risks / debt

- **Ephemerality → solved via committed bootstrap (P-004):** the remote container is
  ephemeral, so durability = the committed `install-accelerators.sh` (wired into
  SessionStart, idempotent/non-fatal) + `.mcp.json` + `templates/repomix.config.json`.
  Repomix/ccusage are now installed on both the host Mac and the env, but stay **DURABLY
  CONFIGURED** until a fresh Claude Code session test (earlier `ACTIVE (env-scoped)`
  reconciled down — a login shell is not a fresh session). Re-verify at session start
  against the five-state taxonomy.
- **Node compatibility (resolved 2026-07-24):** host default is **Node 22.23.1**.
  Repomix 1.17.0 and ccusage 20.0.18 resolve from the Node 22 bin, and Context Mode
  MCP health connects under Node 22.
- **SessionStart runs background installs (P-004):** the hook launches
  `install-accelerators.sh` detached; first session on a fresh container does network
  installs (fast-skip thereafter). Non-fatal by design — never breaks a session.
- **Version pins are point-in-time (2026-07):** `serena-agent` bootstrap-pinned to commit
  `68884f1` (live host Serena is plugin-bundled/unpinned — deviation), `repomix@1.17.0`,
  `ccusage@20.0.18`, `context-mode@1.0.169`, `claude-hud` v0.6.0. Re-pin on upgrade.
- **Skill budget (resolved, P-012):** ECC's 363-skill mega-bundle is disabled and
  `skillListingBudgetFraction` is 0.18. Fresh authenticated debug loaded 149 directory
  commands, 170 plugin skills, and 35 bundled skills with no truncation warning.
- **Remote/org vs local-verified (P-011):** the 9 claude.ai plugins + 13 connectors are
  **org-level** (claude.ai app registry), NOT in the local `claude plugin` registry; router
  now separates them and applies no-route-to-unverified. Verify live per surface before routing.
- **`enabledPlugins` schema (P-006):** the SessionStart detector parses `enabledPlugins`
  from settings defensively (dict-of-lists, dict-of-bools, or list). If a future Claude
  Code version changes that shape, update the parser + the detector test. Cache entries
  under `~/.claude/plugins/**` are reported as *candidates* only — live verification
  (ListPlugins/ListConnectors/ListSkills or an `mcp__*` call) is required before ACTIVE.
- **Legacy convergence heuristic (P-007):** `install-global.sh` supersedes known legacy
  Build OS/Ruflo routing content (heading/body signatures incl. `stack-capability-map`)
  while preserving unrelated user notes, and syncs the current router to
  `~/build-os/memory/tool_router.md` (overridable via `BUILD_OS_USER_DIR`). Conservative by
  design; extend the signatures + test if a new legacy shape appears on the host.
- **Installation vs configuration vs activation:** `install-global.sh` remains a configuration act; P-010 separately verified a fresh authenticated session.
- **Parallel-work reconciliation (P-007):** the split-brain fix was implemented on the host
  Mac (`Converge global orchestrator routing`) and pushed to this branch; a duplicate
  in-container implementation was discarded in favour of the validated host version, and
  this packet added only the missing Build OS closure (receipt + memory).
- **Config ≠ activation:** installer output intentionally does not claim activation; P-010 supplies the independent activation evidence.
- **Canonical MCP rule (P-008):** one live server per job; prefer a pinned/user-configured
  server over a plugin-bundled copy over an unpinned `@latest`; do not double-launch Serena
  or run Chrome DevTools MCP beside another devtools server for the same task. Encoded in
  `tool_router.md` under *Canonical MCP servers*; extend the named examples as new
  duplicate-prone servers appear.
- **Zero-touch handoff — tested vs live (P-014):** `specialist-handoff.sh` is fully
  regression-tested with a mock `claude` + real `capability-profile.sh` against temp homes
  (classification, focused no-op, ECC/zeroize handoff, prompt/cwd preservation, recursion
  guard, child-failure cleanup, timeout, single-Serena, dry-run). A **live** host handoff
  additionally needs the real authenticated `claude` CLI; the local CLI OAuth is expired, so
  a live child relaunch is a user step. The prompt-hook path resolves the handoff script from
  repo-relative / `$CLAUDE_PROJECT_DIR` / `~/build-os` and is non-fatal if absent.
- **Global install now ships the handoff tools (P-015):** the live-install audit found
  `install-global.sh` created only `~/build-os/memory` and never copied
  `specialist-handoff.sh` / `capability-profile.sh`, so the *globally installed*
  `prompt-router.sh` (whose only global-scope candidate is `~/build-os/tools/specialist-handoff.sh`)
  produced just the routing reminder — no handoff. Fixed: the installer now
  `mkdir -p ~/build-os/tools` and copies the tools dir with exec bits preserved. Test section 16
  installs into temp homes and proves the installed hook resolves + runs the handoff end-to-end.
- **Ferrari hardening (P-016) — 7 audit fixes, all regression-tested (186/0):**
  (1) **Capability registry** — the classifier is now precedence-ordered, per-family task
  rules (not one opaque regex); broad ECC/Everything-Claude-Code families (Rust ownership/unsafe,
  Go concurrency, PostgreSQL schema/query, autonomous-agent harness/evals, architecture, browser)
  route `ecc`; crypto tokens retained; lightweight tasks stay `focused`. Extend by editing one
  `CAP_*` family or adding a family + a line in `classify()`.
  (2) **Inline routes** — `21st`/`agent-reach`/`claude-watch`/`ui-ux-pro-max` emit a REQUIRED
  current-surface directive, never switch profiles, never launch a child; the prompt hook's
  wrapper message is route-accurate (child vs inline).
  (3) **Zeroize NL** — expanded coverage (keys-remain-in-memory, cleared-from-registers/stack);
  still highest precedence.
  (4) **Privacy** — the audit log stores only timestamp/route/result/exit/event-id, is `0600`,
  and tightens a pre-existing 0644; old plaintext prompts are NOT read/migrated (a pre-existing
  0644 leak line is left in place but the mode is tightened — re-verify no legacy log holds
  prompts on the host if that matters).
  (5) **Atomic lock** — `mkdir`-based, `HANDOFF_LOCK` (default `~/.claude/build-os-handoff.lock`),
  `HANDOFF_LOCK_WAIT` (30s), `HANDOFF_LOCK_STALE` (1800s). Stale detection is primarily PID-liveness
  (`kill -0`) + an age fallback; a wrapped-around PID could in theory look alive (single-user host
  risk, bounded by the age cap). Fail-closed BUSY exit 75.
  (6) **Surface inventory** — router separates account-level cloud alias `21st` from Mac-local
  alias `21st-dev`; no cross-surface ACTIVE claim. A fresh cloud Code session successfully
  called `mcp__21st__search` and returned Dashboard Sidebar (id 14941), with Anthropic's
  mandatory web-connector approval prompt.
  (7) **skill-budget-audit** — enabled-aware `--claude-dir` mode reports installed inventory vs
  startup-enabled (via `enabledPlugins` + `installed_plugins.json` installPath, de-duped); only
  the enabled set is budget-checked. `installed_plugins.json` lives at
  `<dir>/plugins/installed_plugins.json`. **Correction (live-host):** the real file stores each
  `plugins[name]` as a **LIST** of install records `[{scope,user,installPath,...}]`, not a single
  dict — the first cut parsed that as 0/0. The parser now accepts list/dict/string schemas via
  `choose_install_path()` (prefers the current user-scope record, then any on-disk installPath,
  then the latest named path; one path per plugin). If a host adds yet another shape, extend that
  helper + the §21 fixture.
- **Post-release adversarial correction (P-017 — host-implemented `ac500c6`, adopted; 198/0):**
  (1) `prompt-router.sh` preserves the real `detect` exit and suppresses parent work only after an
  explicit `COMPLETED`. (2) The child must end with `[BUILD_OS_STATUS: COMPLETED|NEEDS_INPUT|
  BLOCKED|FAILED]`; exit-0-without-a-valid-marker → **UNCONFIRMED (exit 76)**, never OK. (3) Task
  travels on **stdin**, not argv. (4) **Lock safety:** `lock_path_safe` rejects `/`, `.`, `..`,
  `$HOME`, and symlinks; `safe_release_lock` unlinks only the `pid` file then `rmdir`s — no
  recursive deletion. (5) Inline routes are **conditional** INLINE CANDIDATEs (verify live on this
  surface, else built-in/local fallback + state the limit; never claim from install alone).
  (6) The budget report separates enabled **full-body inventory** from startup metadata and marks
  the metadata status **UNKNOWN from files alone** (no false within/over certainty). (7) INT/TERM
  restores focused + releases the lock + exits; the child is killed (verified) and output is
  bounded + visibly truncated.
  **Split-brain note:** the cloud session implemented the same packet in parallel; the validated
  host version (`ac500c6`) was adopted and the parallel cloud commits were discarded (recoverable
  via reflog), per the P-007 precedent. This closure adds the memory the host commit omitted.
  **Residual limitations:** a live authenticated child needs a signed-in `claude` CLI (local OAuth
  expired; proofs use a mock); the terminal-marker contract depends on the child cooperating (a
  non-cooperating child → UNCONFIRMED, the safe default); stale-lock PID-liveness can be fooled by
  PID reuse (bounded by the age cap; single-user host); output is truncated for display after
  capture (host env kills the child promptly, so unbounded accumulation was not observed).
- **Host specialist capabilities (P-014):** 21st.dev verified live in-session (read-only
  `get_usage`); `agent-reach` skill present in-session; Claude Watch + UI UX Pro Max are
  host-reported (installed/uploaded per user) and **not independently verifiable here** — no
  ACTIVE claim. All are preserved across profile transitions and routed in `tool_router.md`
  → *Host specialist capabilities*.
- **Side-branch duplication (P-022):** audit-style side branches can duplicate canonical
  machinery (e.g. a parallel `verify.sh` structural suite + a colliding "P-001" identity) if not
  reconciled promptly; reconcile such branches into canonical **before divergence grows**.
- Snapshot leakage: Repomix output can embed code — the hardened config excludes
  secrets/env/deps/build, but **sharing a snapshot externally is a STOP**.

## Open boundaries (awaiting explicit go)

- **No secrets touched, no OAuth authorized, no accounts connected.** Stripe /
  Cloudflare still unauthenticated; GH Action API keys not added.
- Build OS, pinned Serena, Repomix, ccusage, Context Mode, and 8 focused Trail of Bits
  plugins pass current live checks. Claude HUD enabled; visual TTY render unverified.
- Context Mode enabled on host but routing **limited to non-secret pilot** — awaiting go
  to widen.
- Trail of Bits (CC BY-SA) enabled at host user scope, **not vendored** into this repo.
- Production boundaries default-OFF: secrets, OAuth, DDL, remote-DB writes,
  payments, flags, canaries, telemetry, deploys, merges, external sends — each a
  separate explicit approval.
- **[CORRECTED 2026-07-31] `claude/project-handoff-merge-ramhds` is NOT fully unpushed.** This entry
  previously claimed everything since `641527f` was local-only. Git says otherwise:
  `refs/remotes/origin/claude/project-handoff-merge-ramhds` is at **`6b01173`**, and
  `git reflog show` for that ref records five successive **`update by push`** entries (`6b01173`,
  `321dced`, `e8f34ed`, `785a851`, `d30aeab`) — so `gravito_census_gaps_egress_bandwidth_a`'s two
  commits are already on `origin`. **Only `105cb75` and `0555717`, the two commits of
  `gravito_evidence_policy_matrix_a`, are genuinely local-only**, and they remain so pending
  explicit go. **[EXTENDED 2026-08-01]** Local-only now also includes `77a0040` (that packet's
  close), `88052e7` + `a7ab841` (`gravito_authority_envelope_a`) and its close `c52915f`, and
  `b25f3f7` + `566443f` (`gravito_mismatch_refuted_a`) and its close `2df61ae`, and `576751a` +
  `d0eff10` (`gravito_ladder_semantics_a`) and its close commit. No claim is made about whether those earlier pushes carried a go; the record is
  corrected to match git and the discrepancy is flagged for the operator. **Nothing was pushed,
  merged, tagged, PR'd or deployed by the archivist.**
  **AND A PUSHED COMMIT IS RED.** `2df61ae` — on the local side of that boundary but written by the
  same close chain — ships `./build-os/maintenance/run-tests.sh` at **143/144**. See item (oo).
  **Do not treat pushed history as green just because the 1636 was green.**
- **[RESOLVED 2026-08-01 — "NO CHANGE", ON MEASUREMENT. NOT AN OPEN BOUNDARY ANY MORE.]**
  Re-authorising `maint.tripwire_coverage_scan` **was authorised** by the operator's step-3 ruling
  and `gravito_mismatch_refuted_a` **exercised that authorisation and declined to use it**: the
  prescribed demotion was applied, measured **destroying live memory at the same exit code as the
  gated arm**, and refused; retirement is strictly worse. **The control stays at `gate` with its
  mismatch declared.** See residue item (p). **No envelope was written and the store still holds 0
  live grants.**
- **[UPDATED 2026-08-01] OF THE THREE OPERATOR DECISIONS FROM `gravito_mismatch_refuted_a`, ONE IS
  CLOSED AND ONE IS ADDRESSED.** **Decision 2 — the ladder's definitional bug (item cc) — is FIXED**
  by `gravito_ladder_semantics_a`, at **seven** semantic sites (not six) plus `scan-controls.sh`.
  **Decision 3 — `OBSERVE-LB`'s placement (item dd) — is ADDRESSED**: the check was re-keyed to
  consequence and **moved off the gating path** onto an advisory channel that prints and counts but
  never sets the exit code, while a genuine violation still refuses at exit 2. **Decision 1 — the
  missing fifth outcome (item bb) — is now SPELLABLE and still UNTAKEN**: `observe` is finally a
  legal destination, and moving any control onto it remains a governance act nobody has performed.
- **THE MUTATION CENSUS IS THE NEW BLOCKING OPERATOR DECISION, AND THE REVIEWER RULED IT THE NEXT
  PACKET.** Five modules durably mutate and **not one of those write actions is a registered control
  at any authority**; `maint.managed_set_replacement` sits at `advise` while copying files over a
  user's edits with **no rollback**. **Registering any of it is a RE-AUTHORISATION and is the
  operator's act; nothing has performed one.** Item (nn).
- **Two further questions are OPEN BY DESIGN:** **should Class A license `execute`?** — today **no
  class does**, deliberately, so adding the rung granted nobody anything. And **should a fifth
  DEPLOYMENT mode for mutation exist?** — the discarded reading of `autonomous -> execute` (*"an
  operator authorising autonomy did not thereby authorise mutation"*) is real but misplaced, since
  the axis states a **cap** and `L_effective` is a **minimum**; the question survives in
  `build-os/registry/README.md` §3b.
- **Whether "declare before building" gets a third commit or a pre-commit hook** is an operator
  decision and is **deliberately unresolved** — the `<=2-commit` rule is in genuine tension with it
  (item ee).
- **Writing the FIRST authority envelope is an operator act.** The store ships with **0 live
  grants** and nothing in `gravito_authority_envelope_a` writes to it.
- **The S1 decisions are OPERATOR decisions and none is taken:** (i) add `untested` as a sixth
  evidence token, or have S1 arrive carrying `unvalidated`; (ii) the reviewer's recommendation that
  S1 declare `runtimeAuthority: observe` with a note that its SIGNAL is rank-shaped — **recorded as
  ADVICE and explicitly NOT ADOPTED**; (iii) which of the two S1 readings, if either, the ladder
  adopts — §17 of `tests/authority_envelope_tests.sh` fails if reading 2 is adopted silently.
- **Step 3 needs a class change or a different instrument**, and neither is designed. See residue
  item (w) — an envelope cannot promote, so step 3 cannot be executed by writing envelopes.

- **[ADDED 2026-08-01 by `gravito_p1_mutators_ids_telemetry_a`] APPLYING ANY `FINDING-*` REMEDY IS A
  RE-AUTHORISATION AND IS THE OPERATOR'S ACT; NONE HAS BEEN PERFORMED.**
  `FINDING-0001-managed-set-replacement-understated` (move `maint.managed_set_replacement` from
  `advise` to `execute`, declare the mismatch, add a `MISMATCHES.md` row, and update
  `governance_baseline.txt` **in the same commit**) and
  `FINDING-0002-hook-once-marker-understated` (either move `hooks.once_dedup` to `execute`, or —
  the shape `findings.txt` itself recommends — register the marker write as its own control the way
  `MUT-0001`..`MUT-0006` were) both have **remedies NAMED AND UNAPPLIED**.
  `FINDING-0003-mutators-emit-no-receipt` **proposes no remedy, deliberately**: a receipt standard
  for mutators is a design decision with real cost, and the census was built to make the question
  **askable**, not to answer it.
- **[ADDED 2026-08-01] WHETHER ANY CLASS SHOULD LICENSE `execute` IS OPEN, AND UNTIL IT IS ANSWERED
  EVERY DURABLE WRITE IN THE REPOSITORY IS DECLARED OUT OF LICENCE.** The six new `execute` controls
  are out of licence **BY CONSTRUCTION** — no class reaches that rung — which is **the registry
  correctly reporting an undecided question**, not a defect in the registrations. Of the 20 declared
  mismatches, **14 are fitted heuristics gating on an `advise` licence** and **6 are these durable
  writes**; the two kinds must not be blended into one number.

- **[ADDED 2026-08-01] (aaa) THE CONDITION LETTERS IN `tests/mismatch_disposition_tests.sh:187-222`
  DO NOT MATCH THE TOOL'S OWN.** The suite labels its four RED drives (a)(b)(c)(d); the tool's
  conditions at `build-os/tools/mismatch-disposition.sh` are lettered differently, so test **(b)
  drives tool (c)**, test **(c)** drives tool **(d)**, and test **(d)** drives tool **(b)**.
  **COVERAGE IS COMPLETE — only the letters cross**, which is why this is recorded rather than
  fixed: renaming them inside a bounded fix round is the kind of adjacent tidying that turns a
  three-stage packet into a four-stage one. It is a **readability defect with a real cost**: a
  reviewer checking "is condition (c) driven red?" reads the wrong assertion and gets the right
  answer by accident. Fix with the next packet that touches that suite for its own reasons.
- **[ADDED 2026-08-01] (bbb) `tests/claim_evidence_tests.sh` NUMBERS ITS SECTIONS OUT OF ORDER AND
  PINS ITS CLOCK LATE.** `== 13.` is inserted immediately before `== 11.`, and `export
  BUILD_OS_NOW` is set inside §13 rather than at file top. **Harmless TODAY** — every live
  assertion in §§1-12 carries an `open` term, so no verdict depends on the date — but §§1-12 now
  invoke clock-reading paths **against an unpinned clock**, which is a suite that passes in 2026
  and may not in 2027. The fix is one line moved to the top of the file; it is deferred only
  because it is out of the enumerated scope of the fix round that found it.
- **[ADDED 2026-08-01] (ccc) THE TWO-POSITION CITATION RE-AUDIT FOUND SIX MORE, AND ONE IS STILL
  OPEN.** Auditing every `path:N-M` and `path:N -> :M` in the tree against HEAD by CONTENT — not
  only the four the reviewer enumerated — turned up **five further stale range citations**, all of
  them pointing at `:362-386` of `build-os/registry/scan-controls.sh` for the evidence-resolution
  loop that now lives at **`:368-392`**: two in `current_state.md`, two in
  `gravito_ladder_semantics_a.md`, one in `packet_metrics.tsv`. *(The superseded span is written
  here WITHOUT its path on purpose: §27a sweeps this file, and a `path:N-M` in prose is
  indistinguishable from a live citation.)* `residue.md` had been repointed by content at P2 and the other five had
  not, so **the tree stated the same finding with two different spans**. All five are now repointed
  and the contradiction is checked by `tests/control_registry_tests.sh` §27d.
  **STILL OPEN, AND DELIBERATELY NOT FIXED HERE:** `gravito_mismatch_refuted_a.md:56` cites the
  `OBSERVE-LB` guard at `build-os/registry/scan-controls.sh:320-321`, where `:320` is now a **blank
  line** and `:321` a **section comment** — the guard moved to `:337` when the ladder was corrected.
  **It is NOT the two-position defect class**: BOTH ends are equally stale, so it is the ordinary
  resolvability-not-identity drift already recorded as **(mm)**, and §27 cannot see it because a
  citation with no second opinion in the tree has nothing to contradict. **A single-position
  citation with no duplicate is unpoliced by everything currently in the suite**, which is the real
  residue here: §27d only catches drift that someone else already recorded correctly.

---
_Append-only working notes._
