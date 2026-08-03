<!-- rotation-batch: 2026-08-03T16:09:49Z | source: build-os/memory/residue.md | blocks: block_26..block_29 (4) | tool: build-os/maintenance/rotate-memory.sh -->

## ARCHIVED BATCH 2026-08-03T16:09:49Z — build-os/memory/residue.md — 4 blocks (block_26..block_29)

## History — items (l)–(n), from gravito_evidence_policy_matrix_a

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

## History — items (a)–(k), from gravito_census_gaps_egress_bandwidth_a

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

## History — the speed-benchmark instrument and its carried limits

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

## History — the earliest sessions (P-001..P-022)

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


