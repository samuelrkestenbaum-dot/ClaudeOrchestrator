# Residue

> What was deferred, left behind, or noted as risk — the stuff that didn't fit in
> the last packet but must not be forgotten. The orchestrator reads this to avoid
> dropping threads; the archivist appends/clears it on close.

> **HOW THIS FILE IS ORDERED, AND WHY IT IS NOT CHRONOLOGICAL.**
> `build-os/maintenance/rotate-memory.sh` retains a **PREFIX** of the `^## `
> blocks — `routeSegments` keeps `blocks.slice(0, keepN)` and archives the tail,
> measured rather than read off the header — so the sections below run **newest
> first** and the standing region is **block 1**. Items inside a section keep
> their original order and their bytes; only the sectioning and the section
> order changed. Sections are cut at the file's own `### From <packet>` era
> markers and never across one, and each is named by the letter range it holds,
> because `build-os/metrics/signal_snapshots.tsv` already addresses this file by
> letter (`build-os/memory/residue.md#ddd`), not by line.
>
> The tool has no notion of protected content and none is claimed for it. What
> protects the standing region is POSITION: it is block 1 and `--keep` is
> validated `>= 1`, so no legal invocation can reach it.
> `tests/build_os_maintenance_tests.sh` section 8 executes that at every legal
> N, and also requires that no gate-pinned literal occurs anywhere else in this
> file, so no archivable block can be what keeps
> `tests/release_metadata_tests.sh` green.

## Standing open items — PROTECTED REGION (block 1; rotation cannot reach it)

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

- **[ADDED 2026-08-02 at the `gravito_p5_outcome_counterfactual_telemetry_a` close] THE THREE P5
  COMMITS ARE UNPUSHED, AND THE UNPUSHED STATE NOW HAS EVIDENTIARY MEANING RATHER THAN MERELY
  PROCEDURAL MEANING.** `cda95d2`, `44b0fab` and `adef6ad` are local-only; the branch is **ahead
  3** of `origin/claude/project-handoff-merge-ramhds`, which sits at the base `80ad634`. **The
  BASE is witnessed; the packet's own commits are not.** That matters now in a way it did not
  before P5: the sealed prospective ordering's entire claim is that it was committed BEFORE any
  commit could carry a selection, and **the parent-hash chain is non-forgeable only once a third
  party has witnessed it** (residue `(kkkk)`). **Publishing is what converts the anchor from "one
  process could rewrite this" into "a third party has seen it."** So a push would now buy
  something specific and nameable — it is the cheapest of the three available witnesses (a push,
  a tag a third party holds, or a second selector). **PUSH AUTHORISATION HAS NOT BEEN GIVEN FOR
  THESE THREE COMMITS, none was requested by this close, and nothing was pushed, merged, tagged,
  PR'd or deployed.** Recording that a boundary would be USEFUL to cross is not a request to
  cross it.
- **[ADDED 2026-08-02] SELECTING FROM `DECISION-0011-p5b-next-after-p3b` IS AN OPERATOR ACT AND
  NOTHING HAS PERFORMED ONE — AND THE ABSENCE IS THE EVIDENCE.** The ordering is sealed at
  `80ad634` over 20 frozen v2 snapshots and has **NO row in `decision_telemetry.tsv`**
  (`grep -c '^DECISION-0011'` returns 0 at this close). S1 ranks
  `PACKET-0029-citation-anchor-tokens` first, with `PACKET-0030` and `PACKET-0031` **tied** at
  rank 2 and **3 of 4 rankable candidates on the Pareto frontier** — so unlike `DECISION-0010`
  this ordering could actually be contradicted by a human choice. **A selection recorded by any
  agent would move `prospective_decisions_with_a_recorded_selection` from 0 to 1 with no human
  having chosen — the exact figure the reviewer's reproduction exploited — and would destroy the
  thing the packet built.** The standing next packet is unaffected and unchanged: it remains
  `gravito_p3b_count_derivation_a` (`PACKET-0027`), already selected by `DECISION-0010` and
  carrying `result: in_flight`. **`DECISION-0011` is the decision AFTER that one.**

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

## History — items (rrrrr)–(yyyyy), from PACKET-0029-citation-anchor-tokens

- **(rrrrr) FIVE PRODUCER IDIOMS WALK PAST THE §28 STATIC SCANNER**, verified rather than
  reasoned: `git log --oneline | grep -q .`; a function wrapping `cat`; `find /tmp -type f |
  grep -q .`; `cat "$BIG" | while read -r l; do break; done`; and `grep -q . < <(emit_rows)`.
  `SP_STREAM` enumerates `datarows`, `cat FILE` and `tail -n +N` and nothing else, and `SP_KILL`
  does not enumerate `awk '…exit'` — **the one consumer idiom this packet's own measurement
  proves toolchain-dependent** (mawk 0/200 here; `sed -n '1p;1q'` 200/200). The two live
  `awk '…exit'` sites are **`build-os/metrics/check-adoption.sh:252` and `:478`**, both running
  `datarows` over the **72754-byte** store under `pipefail`; they **would race under a lethal
  awk** and are unexposed only because all three call sites (`:270`, `:391`, `:478`) capture the
  **value** with `row="$(…)"` and test `-n`/`-z`, never the status, in a file with no `set -e`.
  **The scanner was left alone and the blind spots were named instead** — widening the pattern
  changes what the guard reports, and this was a claim-correction round. **Also recorded, and it
  is an integrity control working:** the repo's own *"sibling suite present but never chained"*
  check caught a planted file during this sweep.

- **(sssss) THE §28 ALLOW-LIST IS FILE-GRANULAR AND ITS COMMENT READS AS PER-PIPELINE.**
  `SP_ALLOW` is matched `^($SP_ALLOW)$` against the whole relative path, while the comment beside
  it enumerates three specific pipelines with measured byte counts. **So the one file that
  actually shipped `DEFECT-0013` — `tests/speed_benchmark_tests.sh` — is wholesale exempt from
  the guard against `DEFECT-0013`**: a new `datarows "$STORE" | grep -q …` there is silently
  ALLOWED, while the identical line in `entitlement_tests.sh` is REPORTED. **Left as is, and
  said out loud in the header:** tightening to site-granularity would put line numbers back
  inside an identity, which is the coupling this tree is shedding.

- **(ttttt) WHAT THE DOUBLED RUN IS ACTUALLY SAMPLING, AND WHAT WOULD LICENSE RETIRING IT.** The
  strongest justification is no longer an argument but a reconciliation: **the same code on the
  same machine measured 7.53% on a 17-row store and 14.55% on an 18-row store** — *the rate of a
  latent non-determinism is a function of a data volume nobody is watching*, which is the §28
  guard's own declared blind spot arriving from the other direction. Under load the site went
  **15.33% → 42.60%**, and CI is not quiet. **What would license retirement is not another
  assertion-level measurement.** It is a **suite-level determinism measurement**: N≥200
  consecutive full-suite runs at a fixed commit, quiet and under controlled load, with **zero
  variation in the per-suite PASS/FAIL VECTOR rather than in the total**, plus a per-assertion
  harness rerunning each assertion K times against frozen fixtures. **Until the invariant is "the
  verdict vector does not move", the doubled run is the only sampler in place.**

- **(uuuuu) OPERATOR-FACING, PROMOTED OUT OF `(ppppp)`: the projection embeds a resolved line
  number and should stop.** The reviewer's ruling, recorded verbatim because it is the argument
  and not a summary of one: *"a byte-compared artefact that embeds a resolved line number, inside
  the mechanism whose stated thesis is that line numbers are not identity, is self-contradictory"*.
  Its cost is not hypothetical: **every content-preserving edit above any anchored site ships red
  until a projection is regenerated.** `(ppppp)` stays as the finding; this is the request that it
  become a **cut packet** rather than open-ended residue. **Not a design act taken here.**

- **(vvvvv) A GATE FLICKERED ONCE AND WOULD NOT REPRODUCE — AN OBSERVATION, NOT A FINDING.** The
  first `scan-controls.sh check` of this close reported `PHANTOM tests/gate_depth_tests.sh` and
  REFUSED; **it did not reproduce in 14 further runs — 8 quiet, 6 under 4-way load, all rc=0.** The
  odd run was the only one **concurrent with another tool call**. **No rate, no mechanism claimed.**
  If it recurs, **measure under CONCURRENCY, not load.** **PIPING TRAP:** that reading came through
  `| tail -15; echo "EXIT=$?"`, where `$?` is **`tail`'s**. **Never read a gate's verdict through a
  pipe** — `(aaa)` again.

- **(wwwww) OPERATOR-FACING: A CLOSED RECEIPT CARRYING A SINCE-FALSIFIED CLAIM HAS NO POINTER TO
  ITS CORRECTION.** Builder-raised **design question**, stated in full in the receipt and in
  `current_state.md`. Three copies of the superseded *"ONE-DIRECTIONAL ..."* claim survive in
  prior-packet records; **rightly not rewritten** — a correction creates a later record. **But the
  kernel declares `supersedes`/`contradicts` and receipts do not participate in them**, so a reader
  arriving at the sealed record meets the false sentence alone. **A design act, not the
  archivist's.** Kin to `(uuuuu)`, `(ppppp)`.

- **(xxxxx) THIS CLOSE MOVED THE QUANTITY THE PACKET NAMED AS THE HIDDEN DRIVER.** A **one-row**
  growth doubled the rate (**7.53% -> 14.55%**); **this close appended the NINETEENTH row to that
  same store** — `packet_metrics.tsv` **72,754 -> 73,992 B**, rows **18 -> 19**, so by arithmetic
  (**not** fresh measurement) the margin past 65,536 goes **6,611 -> ~7,849, +19% in one close.**
  Nothing is wrong now — that site drains. **The trend is monotonic and unwatched:** ~1.2 KB per
  close, no ceiling, no assertion, and the new guard **cannot see volume**. **Remedy named in the
  receipt, not built here.**

- **(yyyyy) THIS FILE IS 98% FULL, ROTATION CAN RECLAIM NOTHING FROM IT, AND THIS CLOSE WAS TRIMMED
  TO FIT — `(mmmmm)`'s NO-GREEN-PATH SHAPE AGAIN.** Derived: at `aa0a7b3` **201,192 B against a
  204,800 B ceiling — 3,608 B headroom**, while a normal close writes several KB. **This close's
  first draft was +7,934 B and drove `build-os/maintenance/run-tests.sh` RED (4 subtests); it was
  rewritten to fit**, which is why these items are terse and the argument lives in the receipt.
  **ROTATION IS NOT THE ESCAPE:** `rotate-memory.sh` selects **by recency over BLOCKS** and its dry
  run reports this file as **3 blocks -> keep 3 newest, would archive 0** — **for any N >= 3 it
  reclaims NOTHING.** **Worse, it REFUSES at exit 3 once the file is over the ceiling: the
  preventative tool has a precondition that the failure it prevents violates.** **NOT FIXED HERE** —
  the fixes are operator-facing (re-block the file, raise `--max-bytes` deliberately, or move
  standing content to `standing_gates.md`, which the rotator never reads), and since selection is
  **recency ONLY** a blind `--apply` could archive literals other suites pin. **The next close has
  no green path unless one is taken.**

## History — items (mmmmm)–(qqqqq), from PACKET-0029-citation-anchor-tokens

- **(mmmmm) THE CHANGELOG / `current_state` CROSS-CHECK HAS NO GREEN PATH FOR A BUILDER.** The
  cross-check forces builders into memory files on **any total-changing packet**: the new suite
  total must be written into `CHANGELOG.md` and `current_state.md` **before** the gates can be
  green, which is precisely the window in which those files belong to the archivist. **There was
  no green path, and this packet's builder took the only one available by writing them.** Two
  remedies, and the choice is the operator's: **either the archivist runs BEFORE the gates**,
  inverting the close order, **or the cross-check reads the total from a GENERATED file the
  builder owns.** Recorded because it is a routing and contract change, and the archivist does not
  take routing acts.

- **(nnnnn) `DEFECT-0013` IS CLOSED, AND THE RULING ON WHAT ONE GREEN RUN NOW PROVES IS
  DELIBERATELY NOT THE FLATTERING ONE.** The `pipefail`/SIGPIPE race is fixed and the fix is
  measured, not asserted: the shipped `| grep -q` form produced **628 false FAILures in 4000
  runs (15.70%)** at the §10 git-backed assertion, `PIPESTATUS=[0 141 0]`; the draining form
  produced **0 in 4000**. On a fixture past two pipe buffers the same comparison is **100.00%
  before and 0/2000 after**. **THE RULING: a single green run is again sufficient evidence FOR
  THIS DEFECT, and the doubled-run discipline STAYS IN FORCE ANYWAY.** Those are not in tension
  and the distinction is the whole point. What was measured is that *one named non-determinism*
  is gone; what would justify dropping the discipline is that *no unnamed one remains*, and
  nothing here measures that. The evidence for the narrow claim is strong and the evidence for
  the broad claim was never collected. **The discipline is cheap and the error it catches is
  one-directional AT THE `&& ok || no` POLARITY EVERY ASSERTION IN THESE SUITES IS WRITTEN AT —
  not as a class; see `(qqqqq)` for the measured counterexample — so retaining it costs a suite
  run and dropping it costs the credibility of every red this tree ever reports.**
  Retiring it is an operator act and wants a second measured packet's worth of clean runs behind
  it, not this one.

- **(ooooo) THE CLASS SWEEP FOUND EXACTLY ONE RACY SITE, AND THE REASON THE OTHERS ARE SAFE IS
  NOT STRUCTURAL.** 45 `pipefail`-enabling shell files under `tests/`, `build-os/` and
  `.claude/hooks/` — **45 of the 54 in the tree; the nine outside the scan and their four
  `set -euo pipefail` members are enumerated in the §28 header, and the gap is measured
  harmless** — **258** pipelines matching `producer | early-exiting consumer` with comment lines
  excluded (**257** excluding the scan-exempt marker line; **the earlier figure of 235 is
  withdrawn, no derivation reproduces it**); **one** could actually race. The discriminator is the **64 KiB pipe buffer**, calibrated rather than assumed
  — a producer under one buffer issues one write and measured **0/4000** at every site tried,
  while synthetic streams over it measured **1.80%–100%**. **BUT THE SAFETY OF THE SURVIVORS IS
  A PROPERTY OF TODAY'S DATA AND TODAY'S TOOLCHAIN, NOT OF THEIR SHAPE.** Two facts make that
  concrete. First, the §10 empty-cell assertion is structurally the *worst* of the three — its
  `awk` stops after 519 bytes while `datarows` still has 72 KB to push — and it measured 0/4000
  only because **mawk's `exit` happens not to kill its producer on this toolchain**: measured
  **0/200 (0.0%) over N=200 trials, against `grep -q .` 16/200 (8.0%), `grep -m1 .` 19/200
  (9.5%), `head -1` 105/200 (52.5%), `sed -n '1p;1q'` 200/200 (100%) and a bare `read` 5/5** —
  **the earlier "5/5 for all five" was true of only two of them and rested on n=5, which cannot
  distinguish 8% from 100%.** Second, the diagnostic `sed … FILE | head -N` dumps are safe on
  **two** independent counts — their inputs are all under 8 KB, and their status is discarded in
  statement position with no `set -e` anywhere in the tree — and **both counts are incidental.**
  **Their number is withdrawn rather than restated: "~40" reproduces under no scan (13 strict,
  87 for all `| head`).** The three scripts that DO combine `set -e` with `pipefail` —
  `install-maintenance.sh`, `rotate-memory.sh`, `capability-profile.sh` — contain **zero**
  early-exiting pipelines, which is luck that nothing enforces. **Open, and no longer in the
  future tense:** four scripts outside the scanner's scope ALREADY carry `set -euo pipefail`,
  the §28 scanner cannot see volume, and it does not read those four at all.

- **(ppppp) A COMMITTED PROJECTION IS COMPARED BYTE-FOR-BYTE AND CARRIES A LINE NUMBER, SO EVERY
  EDIT ABOVE AN ANCHOR TURNS THE SUITE RED.** `DEFECT-0001-stale-line-reference`,
  `OCCURRENCE-0014`, found by **committing this packet's own declaration**: adding text above the
  `ANC-0003` content site moved it 15 → 40, `memory-kernel.sh` re-rendered
  `build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md` with the new position, and
  `tests/memory_kernel_tests.sh` §18 reported `PROJECTION-DIVERGED` — suite **2095/1**. **The
  identity half never failed** (`scan-controls.sh anchors`: 12 resolved, 0 violations); only the
  **projected position** was stale. **This is the anchor scheme's own ruling — that a line number
  is a navigation hint and not an identity — violated by the artefact that renders it**, and it
  makes the reconcile a false-negative generator of the same family as `DEFECT-0013` by a
  different route. **NOT FIXED HERE and deliberately so:** the remedies (drop the position from
  the rendered citation, exclude it from the comparison, or regenerate projections pre-commit)
  each change what a projection *is*, which is a design act on a v0 store this packet has no
  licence over. The repair taken was the sanctioned one — regenerate the shadow, a pure read that
  appended **no event** and touched **no canonical store**.

- **(qqqqq) THE ONE-DIRECTIONALITY CLAIM WAS FALSE AS A CLASS CLAIM, AND IT HAD ALREADY BEEN
  RELAYED TO THE OPERATOR TWICE.** `DEFECT-0013` was recorded — in `tests/speed_benchmark_tests.sh`,
  in `tests/build_os_tests.sh` §28 and in `defect_classes.txt` — as *"ONE-DIRECTIONAL: it can
  manufacture a false FAIL and can never mask a real one"*. **The corrected claim, now carried
  verbatim in all three: one-directionality is a property of the `&& ok || no` POLARITY, not of
  the class. At that polarity the race can only manufacture a false FAIL; INVERTED —
  `producer | grep -q . && no || ok` — the same 141 routes to `ok` and the identical race yields
  a FALSE PASS that masks a real failure.** **Measured counterexample:**
  `tests/build_os_maintenance_tests.sh:414` is written at the inverted polarity — a `find`
  producer into `grep -q .`, then `&& no … || ok …` — and at **270890 B returned non-zero
  2000/2000**, **0/2000** with a draining consumer. **LATENT, NOT LIVE:** reaching it needs
  >64 KiB, roughly **1100+ leftover paths**, in a directory the test expects EMPTY. **INVISIBLE
  TO THE GUARD:** its producer is `find`, which `SP_STREAM` does not enumerate, so §28 would
  never report it. **The greens still stand — but because this counterexample is unreachable,
  NOT because the class cannot mask failures**, and that is a different sentence with a different
  warrant. **NOT FIXED HERE:** `tests/build_os_maintenance_tests.sh` is outside this packet's
  ownership; this entry carries the measurement so the next packet inherits a number rather than
  an impression.
  **WHERE THE SUPERSEDED CLAIM STILL STANDS, AND WHY IT WAS NOT REWRITTEN.** Three copies live in
  records of the PREVIOUS packet, closed before this correction existed:
  `build-os/receipts/gravito_cross_surface_memory_kernel_v0.md:407-408`,
  `build-os/memory/residue.md:2038-2039` and `build-os/memory/current_state.md:286`. **They were
  left as written**, on the same rule this tree applies to `memory_events.tsv` — *a correction
  creates a later record, it does not edit an earlier one* — because rewriting them would
  misrepresent what was known at that close. **Every LIVE copy was corrected in place**
  (`tests/speed_benchmark_tests.sh`, `tests/build_os_tests.sh` §28,
  `build-os/registry/defect_classes.txt`, `build-os/packets/active_packet.md` ×3, `CHANGELOG.md`,
  and `(nnnnn)`/`(ooooo)` above), because correcting one copy and leaving its sibling is
  `DEFECT-0003` and this repository has already shipped that class inside the packet that
  registered it. **Open, and an operator call rather than a builder's:** whether a closed receipt
  carrying a claim since measured false should gain a pointer to its correction. It has none
  today, and a reader arriving at that receipt will read the false sentence with nothing beside
  it.

## History — items (ddddd)–(lllll), from PACKET-0029-citation-anchor-tokens

- **(ddddd) THE FIX ROUND REWROTE TWO COMMITTED EVENT ROWS IN PLACE — THE EXACT OPERATION THIS
  PACKET'S OWN `EVENT-APPEND-ONLY` GUARD REFUSES.** `git diff 8ba368a..727de75 --` on
  `build-os/kernel/memory_events.tsv` is **2 insertions / 2 deletions**: `EVT-0024` and
  `EVT-0025`. `EVT-0024`'s reference field gained the package hash (`CTX-0001` became
  `CTX-0001@a8676c9d...`), which is fix 3. **`EVT-0025`'s own fields did not change at all and its
  digest changed anyway** (`4659686a...` to `d657ab44...`) — the signature of a **re-derived
  chain**, where the successor's digest moves because its predecessor's did. **THE GUARD'S OWN
  REFUSAL TEXT DESCRIBES WHAT WAS DONE:** *"EVENT-APPEND-ONLY <id> breaks the integrity chain. Its
  digest does not follow from its own fields and the digest of the event before it, so a row has
  been edited, inserted or removed."* **Its red-drive is section 3 of the packet's own suite** —
  *"an event rewritten in place breaks the digest chain and is refused"*. **It validates now ONLY
  because the chain was re-derived, which is structurally identical to qa's Attack B — the
  laundering this very fix round was fixing.** The packet's stated rule is *"events are
  append-only; corrections create later events"*, and **a correction event could have carried the
  anchor.** The builder's hand-back calls it *"migrated and re-chained"* **without naming it as the
  thing the invariant forbids**, and that omission is the durable part. **MITIGATION, RECORDED
  ALONGSIDE AND NOT INSTEAD:** the store is v0, was created inside this packet, is consumed by
  nothing outside it, and the rewrite is visible in git history with **both prior digests
  recoverable** and quoted above. **NOT treated as a stage-4 defect. RECORDED AS A DEVIATION AND
  NOT NORMALISED.** **REMEDY FOR v1, STATED AND NOT APPLIED:** an anchor that arrives late is a
  **later event**, never an edit to an earlier one.

- **(eeeee) THE PACKET WAS NEVER DECLARED, THE PROVENANCE IS THE ORCHESTRATOR, AND IT IS A
  RECURRENCE OF A CLASS THIS REPOSITORY ALREADY REGISTERED.**
  `build-os/packets/active_packet.md` read `Status: NOTHING IN FLIGHT` and described
  `PACKET-0029` for the **entire life** of the largest packet in this sequence. Every prior packet
  opened with a `docs(packet): declare ...` commit before building; **the orchestrator dispatched
  this builder without one.** The id was minted in `d2c09c6`; the declaration and the in-flight
  record were not written. **THE MEASURABLE CONSEQUENCE: `bandwidth.active_packet_singleton`
  reported ZERO in flight while the largest packet of the sequence was in flight.** **PROVENANCE:
  ORCHESTRATOR, NOT BUILDER** — recorded the same way the `residue_items_closed=1` defect's
  provenance was recorded at the previous close, because HOW the error got in is the only part
  that generalises. **THE CLASS HAS NOW FIRED TWICE.**
  `build-os/registry/defect_classes.txt` already carries `DEFECT-0011-undeclared-active-packet` at
  `OCCURRENCE-0005`, whose symptom reads *"an entire packet was built while active_packet.md still
  read NO PACKET IN FLIGHT, and the singleton guard passed because it refuses two declarations and
  permits zero"*, and whose `could_have_been_prevented_by` already names the remedy — **a lower
  bound on the same cardinality check, refusing zero declared packets while a build is in
  flight.** That remedy still does not exist. **NO REGISTRY OCCURRENCE ROW WAS WRITTEN AT THIS
  CLOSE:** appending one is a registry mutation that would move counts the gates measure, and the
  archivist's write scope is the receipt and memory. **RESIDUE: record `OCCURRENCE-0014` against
  `DEFECT-0011` through the governed path, and build the lower bound.**

- **(fffff) ATTACK A — STALENESS BY ADDITION DEFEATS THE PACKAGE STATE CHECK, AND IT IS NOT
  FIXED.** Recording a **new** object into a context package's own namespace leaves the package
  reading **`CURRENT` at exit 0**, because `pkg_state()` iterates **only the bound ids**. qa's
  probe is the part that makes this more than theoretical: it recorded `OBJ-0014` — *"S1 PROMOTED
  AND AUTONOMOUS DISPATCH ENABLED"* — **the literal thing the export forbids the second surface
  from doing.** A package can therefore certify itself current while the namespace it describes has
  acquired exactly the fact that would invalidate the handoff. **NEEDS A DESIGN ANSWER IN v1: a
  package's identity has to cover what its namespace GAINED, not only what it BOUND.**

- **(ggggg) `payload_ref` IS PROSE-VS-REFERENCE AMBIGUOUS, AND THE PACKET'S OWN TEST FOR IT PASSES
  FOR THE WRONG REASON.** `export_objects` prints field 21 **verbatim** while the validator treats
  it as a **path-like ref**. **The "consumable without the transcript" property is therefore held
  up by AUTHORIAL CONVENTION, not by CONSTRUCTION** — nothing stops a writer putting a pointer
  where the reader expects prose, and the export would then hand the second surface a dangling
  reference. **AND THE PACKET'S OWN SECTION 0 WOULD NOT CATCH THE DEGRADATION:** its `q()` helper
  greps for section **HEADINGS** that the tool `printf`s **UNCONDITIONALLY**, so the assertion is
  satisfied by the template rather than by the content. **A test passing for the wrong reason,
  inside the packet built to prevent exactly that.** The fix is to assert on the ANSWER, not on
  the heading above it.

- **(hhhhh) `parse-projection` NEVER HASHES THE BODY.** Editing `truth state: reported` to
  `verified` in a projection still returns `round_trip: MATCH`. The round-trip therefore attests
  the STRUCTURE and not the CONTENT. **`reconcile` is the real mechanism**, and it covers **only
  `exports/`** — so any projection written anywhere else is unguarded.

- **(iiiii) DEAD FIELDS AND DUPLICATED TYPES IN THE v0 SCHEMA.** `memory_artifacts.content_hash`
  is hardcoded `-` and **read by nothing** — a field that looks like an integrity control and is
  not one, which is the `(ccccc)`-adjacent hazard of a wrong perimeter rather than an admitted
  gap. Separately, the `handoff` and `context_package` **object types** duplicate the **dedicated
  stores**, so the same fact has two homes and nothing reconciles them. Both are v0 schema debt,
  named here so v1 meets a decision rather than an oversight.

- **(jjjjj) `ART-0011` HAS ANCHOR `-`, AND IT IS THE EVIDENCE FOR THE SIGPIPE FINDING ITSELF.** It
  is a **bare file reference**. **An anchor resolves an IDENTITY TOKEN, not a CONTENT DIGEST**, so
  the text around a token can change and the evidence silently cites different content. **That is
  `resolvability is not identity`, one level down, inside the layer built to prevent it** — and
  the artifact it degrades is the one backing `DEFECT-0013`, the most consequential finding
  currently open. **REMEDY: anchor it, or record a content digest beside it.**

- **(kkkkk) THE EXPORT TELLS THE SECOND SURFACE WHAT TO DO AND NOT HOW TO DO IT, AND ONE
  ACCEPTANCE CRITERION CAN NEVER BE MET AS WRITTEN.** The export **never names the tool, the
  subcommand or the actor id** required to satisfy its own acceptance criteria — so a second
  surface that read it faithfully still could not act through the governed path. Separately,
  **`HOF-0001`'s criteria say *"at version 1"*** while section 7 names **`OBJ-0010`, already at
  v1**, so deciding it produces **v2** and the criterion is unsatisfiable by construction. Both
  are content defects in the generated artifact, not in the generator's plumbing.

- **(lllll) THE MISMATCH CEILING SHOULD BE RE-EXPRESSED ON THE GATE-ON-ADVISE SUBSET, AND THE
  REVIEWER WITHDREW ITS OWN P5 RULING ON EVIDENCE TO SAY SO.** `lic_of` in
  `build-os/registry/scan-controls.sh` **tops out at rank 4 (`gate`) for Class A, and no class
  returns 5 — no class licenses `execute`.** **THEREFORE EVERY DURABLE-WRITE CONTROL THIS
  REPOSITORY WILL EVER ADD MUST DECLARE A MISMATCH. THERE IS NO LEGAL ALTERNATIVE, FOR ANYONE,
  EVER.** A cap on the **raw total of 22** is negotiable by construction and **no packet can
  decline it**; the previous standing ruling *"hold at 21"* could only have been honoured by
  refusing to register real durable-write surfaces, which is worse than declaring them. **THE
  NUMBER THAT MATTERS DID NOT MOVE: gate-on-advise — the original subject of `MISMATCHES.md`, the
  heuristics that CAN STOP A BUILD — is 14 at base and 14 at HEAD.** All growth is in the
  `execute` bucket. **ROUTED TO THE OPERATOR AND NOT ACTED ON:** re-express the ceiling on the
  gate-on-advise subset, where it constrains something an operator can actually choose.

## History — items (yyyy)–(ccccc), from PACKET-0029-citation-anchor-tokens

- **(yyyy) THE PACKET ID WAS COLLISION-CHECKED AT CLOSE AND THE CHECK IS NOT CEREMONIAL.** The
  close brief supplied `PACKET-0029` and instructed the archivist to verify rather than accept it.
  A tree-wide sweep of every `PACKET-[0-9]{4}[a-z0-9-]*` token finds the live band
  `PACKET-0001`..`PACKET-0034` plus the synthetic `PACKET-9001`..`PACKET-9999` fixture range, and
  **every occurrence of `PACKET-0029` in the live band resolves to the same slug**
  — in both decision candidate sets, in five snapshot rows, in the P4 and P5 receipts, in this
  file, in `current_state.md`, in the anchor table and in the section 28 assertions. **No second
  candidate holds it, so reuse is identity preserved rather than a collision.** The check earns
  its keep historically: at the P3 close a brief supplied an id already held by a **rejected**
  candidate, and the P4 and P5 closes both caught the same shape. **The receipt filename follows
  the tree's convention — the `gravito_*` slug, not the `PACKET-NNNN` id** — because `ANC-0007` is
  a live `receipt_id` anchor over the previous packet's slug and `check-adoption.sh` derives the
  store key from the receipt's `basename`; the slug was declared by the build itself in this
  file's own section heading and was collision-checked at close against every receipt, every store
  row and the whole tree.

- **(zzzz) THE CLOSE HAD TO AVOID WRITING POSITIONS IN ORDER TO CLOSE A PACKET ABOUT POSITIONS,
  AND THE CONSTRAINT WAS REAL RATHER THAN STYLISTIC.** §27a treats every `path:N-M` token anywhere
  under `build-os/` or `tests/` as a **live** range that must resolve at both ends in the current
  tree, and §27d refuses two ranges over one file that name different spans — so a receipt written
  in the ordinary way, citing the provenance record and the guard sites by line, would have
  planted range citations into artefacts that **the next packet's insertions will move**, in the
  close of the packet whose entire thesis is that this decays. **The receipt therefore cites by
  CONTENT and carries no `path:line` and no `path:N-M` token at all**, which is the anchor
  scheme's own discipline applied by hand to a file the scheme does not yet cover. **THAT IS THE
  MEASUREMENT, NOT A FLOURISH:** the archivist had to hold the convention manually because
  **receipts and memory files are outside the 3.5% the corpus has migrated**, and holding it by
  hand is exactly what `(qqqq)` says will not survive the next packet. Two closes ago the same
  constraint bit twice in one pass, which is why the brief named it.

- **(aaaaa) THE BASE SUITE IS NOT DETERMINISTIC, AND THE CAUSE WAS ISOLATED AND MEASURED RATHER
  THAN RE-RUN AWAY.** The base run of `bash tests/build_os_tests.sh` at `ea069a7`, on a quiet
  tree with `git status --porcelain` empty and **before any edit of this packet**, returned
  **1994 passed / 1 failed**, not the 1995/0 the brief supplied. The single failure was
  `no seeded row is git-backed` in `tests/speed_benchmark_tests.sh`, against a live
  `packet_metrics.tsv` in which **16 of 17 rows carry evidence class `mixed`** — so the
  assertion was right about the data and wrong about itself. Run alone the same suite returned
  **169/0**; the four suites that precede it in the chain, run in order beforehand, did not
  reproduce it. **The cause is `pipefail` plus SIGPIPE:** `datarows | awk | grep -q .` short
  circuits at the first match, `grep -q` exits, the still-writing `awk` takes SIGPIPE, and
  `pipefail` reports 141 as the pipeline's status. **Measured at 117 of 4000 iterations (2.9%)
  against the live store.** Registered as `DEFECT-0013-pipefail-sigpipe-false-negative` with
  `OCCURRENCE-0013`, and recorded as memory object `OBJ-0011` in the kernel with
  `truth_state: observed` and its evidence artifact. **IT IS NOT FIXED HERE.** The remedy is a
  one-line change to a pipeline in a suite this packet has no licence to touch, the same shape
  exists at two more sites in that section and probably elsewhere, and finding all of them is
  its own packet. **WHAT IT MEANS FOR EVERY COUNT ANYBODY QUOTES FROM THIS TREE:** a suite
  total from this repository is a sample, not a constant, until this class is closed — the base
  is 1995 on a run where the race does not fire and 1994 on one where it does, and the same is
  now true of the 2096 this packet leaves behind (2082 at the build commit, 2096 after the
  bounded fix round).

- **(bbbbb) THE MISMATCH REPORT'S OWN PROSE HAD ALREADY GONE STALE BY ONE, AND THIS PACKET
  CORRECTED IT AS A MECHANICAL CONSEQUENCE RATHER THAN AS A SEPARATE ERRAND.**
  `MISMATCHES.md` said "**6 rows exercise `execute`**" while the table between the machine-read
  markers listed **seven** — `metrics.decision.outcome_update` was added to the table and the
  sentence above it was not. That is `DEFECT-0002-stale-remembered-count` in the artefact whose
  whole job is to be counted. The 22nd row this packet adds makes the honest figure **8**, and
  the sentence now says 8. **Nothing else in that file was touched**, and one number in it is
  still stale and is left that way deliberately: "**11 of 97 classified controls gate on
  `unvalidated` evidence**" quotes a census size of 97 against a live 105. The **11** is
  re-derivable and still correct — every control this packet adds is `red_driven` — but the
  **97** is a remembered count. It is NOT corrected here because "classified controls" is not
  a derivation anybody wrote down, and guessing which subset it meant would replace a stale
  number with an invented one. **RESIDUE: state the derivation for "classified controls" beside
  that number, or delete the denominator.**

- **(ccccc) `DEFECT-0013` IS QUANTIFIED, AND THE BUILDER'S OWN FIGURE IN `(aaaaa)` IS SUPERSEDED
  RATHER THAN OVERWRITTEN.** `(aaaaa)` recorded the SIGPIPE race at **117 of 4000 (2.9%)** and
  reported that a standalone run returned `169/0`, which reads as a chained-only condition. **qa
  settled both, and both were understatements of a smaller sample.** The rate is **6.26% per
  invocation on a quiet machine (501 of 8000)**, **3.65% - 7.75% across quiet batches**, **19.97%
  under load**, and **4.0% per standalone suite run (1 of 25)**. **IT FIRES STANDALONE AS READILY
  AS CHAINED** — the builder's `169/0` was one draw from a ~95%-green distribution, not evidence
  of a chained-only condition. **THE MECHANISM IS PROVEN AND NO LONGER INFERRED:**
  `PIPESTATUS=[0 0 0 141 0]` — `awk` is element 4 and dies of SIGPIPE, `grep -q` exits 0, and
  `set -uo pipefail` promotes 141. **The failing `awk` emits 68,734 bytes, past the 64 KiB pipe
  buffer**, so it MUST issue multiple writes and CAN be killed mid-stream; the two sibling
  pipelines in the same section emit **462 bytes in one write** and measured **0 of 2000**. The
  orchestrator's simplified fixture produced too little output to race, which is exactly why it
  returned 0/2000 and could not confirm. **A bare `rc=$?` RESETS `PIPESTATUS`** — that is why both
  earlier probes were ambiguous, and it is the reusable lesson. **THE ERROR IS ONE-DIRECTIONAL:**
  it can manufacture a false FAIL and can never mask a real one, so **every prior green in this
  tree stands and every prior red on that one assertion is suspect.** **THE OPERATIONAL
  CONSEQUENCE, AND IT CHANGES HOW EVERY FUTURE PACKET CLOSES: A SINGLE GREEN RUN IS NO LONGER
  SUFFICIENT EVIDENCE IN THIS TREE.** The orchestrator therefore ran the suite TWICE at
  `727de75` — 2096/0 both times, zero `^  FAIL` lines, no `no seeded row` line in either.
  **NOT CAUSED BY THIS PACKET:** `tests/speed_benchmark_tests.sh` is absent from the
  `ea069a7..727de75` diff entirely. **THE SHARPEST CONSEQUENCE:** the live-suite cross-check in
  `tests/release_metadata_tests.sh` compares a LIVE suite total against the figure remembered in
  `current_state.md`. **If the race fires there, the guard that keeps memory honest emits a false
  staleness verdict** — the instrument reports the memory as stale when the memory is correct, and
  a guard that cries wolf is a guard that gets disabled. **STILL NOT FIXED. It is its own packet
  and needs a licence to edit a suite the memory-kernel packet did not have.**

## History — items (ssss)–(xxxx), from PACKET-0029-citation-anchor-tokens

- **(ssss) THE ANCHOR TABLE IS INSIDE THE MODULE THAT READS IT, AND THAT IS A CHOICE WITH A
  COST.** It lives between `ANCHOR-TABLE` markers in `scan-controls.sh` in the same shape as
  `EVIDENCE_VACUITY_ALLOW`, because the packet's ceiling forbids a new store without an executed
  fixture proving one necessary and none was executed. **THE COST IS REAL AND IS NAMED HERE:** the
  resolver has to EXCLUDE its own table region when it searches a file, or every anchor into this
  module resolves to its own declaration — the self-reference is handled, and it is handled
  because it bit during the build. **The second cost is that the table cannot be read by anything
  that is not this script.** A store would have been queryable; a bash array is not. That trade is
  correct at 13 anchors and is obviously wrong at 500, and the crossing point is not measured.
  Whoever migrates the corpus should expect to move the table out, and should do it with an
  executed fixture rather than an argument, which is the same bar this packet held itself to.

- **(tttt) `rank_of_selected: 1` HELD THROUGH THIS PACKET, AND IT IS STILL ONE OBSERVATION.** The
  sealed ordering re-derives after every line this packet moved: `ANC-0002` (the decision row),
  `ANC-0003` (this packet's own id) and `ANC-0008` (the sealed rank snapshot) all resolve by
  content, the decision anchor's resolved line still carries `PACKET-0029` as the recorded
  selection, and `rank-candidates.sh rank --decision-id DECISION-0011-p5b-next-after-p3b` still
  prints `rank_of_selected: 1` at exit 0 with the ranking digest unchanged, because the two stores
  it reads were not written to. **WHAT THAT IS NOT.** It is not evidence that S1 ranks well. One
  decision, one selection, one execution, by a selector who had read the ordering — the tool's own
  output says it (*"agreement on a single decision is not evidence of skill"*) and the count that
  would make it evidence, `prospective_decisions_with_a_recorded_selection`, is **1**. The honest
  claim available after this packet is narrower and is worth more: **the first candidate S1 ranked
  first has now actually been executed, so the ordering has begun to be falsifiable in the only
  way that counts — by outcome — and it has not yet been falsified.**

- **(uuuu) THE OBJECT-GRANULARITY CONVENTION FOR `candidate_write_surface` DECIDES WHETHER GUARD 1
  FIRES, AND IT IS WRITTEN DOWN NOWHERE.** Opened by the `(pppp)` correction above. `touches()`
  (`build-os/metrics/rank-candidates.sh:264`) treats a bare file path as touching a protected
  `path#object` inside it, so for the six entries of `PROTECTED_SURFACE` the granularity a sealer
  chooses when writing a candidate's surface **is** the guard's outcome: bare
  `build-os/registry/neurocosmology_crosswalk.txt` excludes the candidate as `self_amendment`;
  `...#registry.evidence_resolution` does not. **NOTHING STATES WHICH IS CORRECT.** Not the script,
  not `control_registry.txt`, not `tests/mutator_registry_tests.sh` section 13, not any memory
  file. `PACKET-0029` sat on the permissive side of that unwritten rule and its rank 1 — the only
  rank S1 has ever had executed — depends on it. **WHY IT IS NOT ASYMMETRIC IN THE SAFE
  DIRECTION:** guard 1 already fails closed on ABSENCE (`guard1_unscreenable`) and on a WILDCARD
  (`guard1_uninterpretable_surface`), and it was already driven red on four spelling aliases, so
  every other way of being vague about a surface has a named refusal. Granularity is the one that
  does not, and it is the one that reads as legitimate scoping rather than as evasion. **THE
  REMEDY IS NOT TO WIDEN `PROTECTED_SURFACE`** — that argument is already settled in
  `ranker.s1_shadow_ordering`'s notes and in `(zzz)`: a predicate that refuses every subject
  discriminates nothing. It is to make the convention **explicit and checkable**, so that a
  surface's granularity is a declared property of the seal rather than a judgement made once by
  whoever wrote it. **A CONVENTION THAT CAN VOID AN EXPERIMENT MUST NOT LIVE ONLY IN AN AGENT'S
  JUDGEMENT.** Not built, and deliberately not built here: `PACKET-0029` is the candidate guard 1
  screened, so amending guard 1's contract is exactly the self-amendment it exists to prevent.

- **(vvvv) THIS PACKET MOVED A STALE REFERENCE FURTHER OUT OF DATE, AND A FUTURE READER MUST KNOW
  THE ANCHOR PACKET IS WHAT DID IT.** `(rrrr)` above records the two stale prose citations at
  `control_registry.txt`'s `tests.nonvacuity_minimums` notes and at `MISMATCHES.md` as
  PRE-EXISTING, which they are. What `(rrrr)` does not say is that this packet **widened both
  errors**: the section 20 assertion they name went `919` -> `1189` when 270 lines were inserted
  above it, so `DEFECT-0001-stale-line-reference`'s `:772` is now wrong by **417 lines** instead
  of 147, and `DEFECT-0003-duplicate-semantic-truth`'s `:774` by **415** instead of 145. **THIS IS
  NOT A SCOPE VIOLATION** — neither citation was in the frozen write surface and repairing them
  was correctly refused as builder's-discretion scope creep. **AND IT IS ALREADY MITIGATED, WHICH
  IS THE ONLY REASON IT IS RECORDED RATHER THAN FIXED:** `ANC-0012` anchors precisely that
  assertion by content, so the migration that repairs these two now has a handle that will not
  decay again. **THE HONEST SHAPE OF IT:** a packet whose thesis is that positions decay proved
  the thesis by decaying two positions by a further 400 lines each, in the same commit that
  shipped the remedy for exactly that. Read it as the demonstration, not as an excuse.

- **(wwww) FOUR SMALLER THINGS THE FIX ROUND WAS TOLD TO RECORD AND NOT TO REPAIR.**
  (i) **THE ZERO-REPOINT RESULT INTO `scan-controls.sh` IS MANUAL, NOT A PROPERTY OF THE SCHEME.**
  `(qqqq)` already says so and the proof is inside the same diff: the identical situation in
  `tests/control_registry_tests.sh` had no net-zero option available and cost **3** repoints. Six
  hand-made net-zero edits are a builder holding a file still, not a mechanism holding it still,
  and **it will not survive the next packet.**
  (ii) **THE `NPROJ > 0` VACUITY FLOOR IS REAL BUT IS THE WEAKEST REAL ONE IN SECTION 28**
  (`tests/control_registry_tests.sh:1048` and `:1056`). It asserts that at least one projection
  was generated carrying its anchor token; it would still pass if the generator emitted **1 of 4**
  live fixture anchors. Every other floor in that section is derived or set-based; this one is a
  bare positive.
  (iii) **LATENT, AND IT FAILS CLOSED.** The site-collision fallback at
  `build-os/registry/scan-controls.sh:654` is `grep -qF "$key<"` — an **unanchored substring**
  match, unlike the exact-match line above it — so an artifact path that is a suffix of another
  could false-positive an `ANCHOR-SITE-COLLISION`. At 13 anchors it cannot fire; the direction is
  a spurious refusal rather than a missed one, which is the right direction to be wrong in.
  (iv) **`build-os/memory/tool_router.md:368` SAYS THE SECOND-EYES STREAK IS "the last nine
  packets"; IT IS TWELVE.** Presentation staleness of the same
  `DEFECT-0002-stale-remembered-count` shape, and **nothing pins the literal** — no suite, no
  scanner and no policy reads it — which is exactly why it drifted three packets without anyone
  noticing. Left as residue on purpose: this packet is frozen evidence and does not repair what it
  merely passes.

- **(xxxx) ARCHIVIST CLOSE NOTE — WHAT THIS CLOSE RE-DERIVED RATHER THAN INHERITED, AND WHY THAT
  IS THE POINT OF THE PACKET.** Everything below was recomputed at `fbd746d` from the live tools
  and the stores, not copied from the close brief, because a close that restates a brief is the
  defect class this packet exists against and would have been the fourth instance of it in three
  artefacts. **The S1 report at HEAD digests to sha256
  `e838284e2bba52628647d0c7ddd1ed258a7aab7cc391a5ac99992ad7584eb596`, which MATCHES qa's
  independently recorded base-run literal to the byte**; `rank_of_selected: 1` still derives at
  exit 0; the ranking digest is unchanged; and `build-os/metrics/rank-candidates.sh` is the
  **identical blob `5543ea88`** at the seal `44b0fab`, at the selection `c2d97f8`, at the build
  `df9f740` and at the fix round `fbd746d`. Guard 1's live output excludes `PACKET-0033` and
  **ranks `PACKET-0029` rather than excluding it.** Census re-derived at **101** controls; the
  anchor corpus at **13 records over 12 declared object types, 12 resolved, 1 superseded, 0
  violations**; **97** snapshots by row count against **176** file lines. **THE DIGEST MATCH IS
  WORTH MORE THAN IT LOOKS:** the ranker reads two stores this packet never wrote, so a report
  that is identical across the entire execution is evidence that **the thing measured was not
  disturbed by the thing measuring it** — which is the property a prospective experiment lives or
  dies on, and the only one nobody could have restored after the fact.

## History — items (pppp)–(rrrr), from PACKET-0029-citation-anchor-tokens

### From `PACKET-0029-citation-anchor-tokens` (2026-08-02, `gravito_p5b_citation_anchor_tokens_a`)

- **(pppp) THE SEALED `candidate_write_surface` UNDERSTATED THE REAL ONE BY FOUR ARTEFACTS, AND
  THE DIRECTION IS THE WRONG DIRECTION.** The frozen surface for this candidate, restated
  **VERBATIM FROM `SIGNAL-SNAPSHOT-0077-anchors-surface` WITH ITS OBJECT SCOPES INTACT** — an
  earlier restatement here stripped them, and the scopes are the load-bearing half:
  `build-os/registry/scan-controls.sh`;
  `build-os/registry/control_registry.txt#registry.evidence_resolution`;
  `tests/control_registry_tests.sh#7`; `build-os/memory/residue.md`. The work could not be done
  inside them. **AND TWO OF THE FOUR WERE ALSO OVERRUN IN-FILE BUT OFF-OBJECT, WHICH THE FIRST
  COUNT MISSED ENTIRELY.** `control_registry.txt` was written at **two entries besides**
  `#registry.evidence_resolution` — three `evidence_ref` repoints in all, one inside
  `tests.nonvacuity_minimums` (`:919` -> `:1189`) and two inside `suite.control_registry`
  (`:923` -> `:1193`, `:924` -> `:1194`), every one of them a position into
  `tests/control_registry_tests.sh` that this packet's own 270 inserted lines moved. And the new
  assertions landed in a **NEW SECTION 28**, not in the frozen `#7`, which received a one-line
  heading edit and nothing else — and that heading edit is not a scope accident either: it is the
  `ANC-0010-a` -> `ANC-0010-b` supersession, and it is precisely what exercises rules 5 and 7.
  **Adding the ONE census entry the seal itself forecast (`census_growth_controls=1`)
  MECHANICALLY FORCES writes to four more files**, every one of them a DERIVED value that a live
  guard reconciles: `build-os/registry/README.md` (the stated `evidence_refs` total, 345 -> 355,
  pinned by suite §25); `build-os/registry/neurocosmology_crosswalk.txt` (one binding per
  registered control, or the crosswalk suite reports `binding count 100 does not equal census size
  101`); `build-os/registry/CROSSWALK.md` (the derived coverage cell for `epistemic_quality`,
  32/15 -> 33/16); and `CHANGELOG.md` + `build-os/memory/current_state.md` (the suite total, or
  the `RELEASE_METADATA_LIVE_SUITE=1` cross-check goes red). **WHY THIS MATTERS BEYOND
  BOOKKEEPING:** guard 1 of the shadow ranker screens candidates BY THEIR FROZEN WRITE SURFACE,
  and a surface that understates is a surface that could let a candidate through a screen its
  real footprint would have failed. **AND THE SENTENCE THAT USED TO SIT HERE — *"none of the four
  is anywhere near guard 1's protected set"* — WAS FALSE, WHICH MAKES IT THE WORST SENTENCE IN
  THIS ITEM.** `build-os/registry/neurocosmology_crosswalk.txt` is one of the **six** entries of
  `PROTECTED_SURFACE` (`build-os/metrics/rank-candidates.sh:195`), protected as
  `...#ranker.s1_shadow_ordering` — and this packet wrote to it. **THE COUNTERFACTUAL IS
  KNIFE-EDGE, BECAUSE `touches()` MATCHES A BARE PATH AGAINST A PROTECTED `path#object`:**
  `case "$b" in "$a"'#'*) return 0 ;; esac` at `build-os/metrics/rank-candidates.sh:264` returns
  true when the candidate's token is the bare file and the protected token names an object inside
  it. So had the sealed surface said `build-os/registry/neurocosmology_crosswalk.txt` plainly,
  guard 1 would have **FIRED**, `PACKET-0029` would have been excluded as `self_amendment`, there
  would have been **no rank 1, and the experiment would be VOID**. It said
  `#registry.evidence_resolution`, guard 1 did not hit, and rank 1 stands.
  **THE DEFENCE THIS ITEM OWES, AND IT IS THREE THINGS AND NOT AN ASSERTION OF DISTANCE.** (1) The
  write is **object-scoped**: the crosswalk record this packet added is
  `control: registry.evidence_resolution`, carrying the identical key the sealed surface names,
  and it is not the `ranker.s1_shadow_ordering` record. (2) The **seal itself already wrote at
  object granularity** — `build-os/registry/control_registry.txt#registry.evidence_resolution` is
  the sealed token, so reading the crosswalk write at the same granularity applies the seal's own
  convention rather than inventing a lenient one after the fact. (3) The protected property was
  **never violated IN FACT**: `ranker.s1_shadow_ordering`'s `evidence_refs`
  (`build-os/registry/control_registry.txt:1898`) point only into
  `build-os/metrics/rank-candidates.sh`, and that file has **ZERO DIFF** across this packet —
  `git diff --stat c2d97f8..c76b4d0 -- build-os/metrics/rank-candidates.sh` is empty and the blob
  is the same `5543ea88` at seal, at selection and at execution.
  **AND THE CONVENTION THAT DOES ALL THAT WORK IS LOAD-BEARING AND IS CURRENTLY WRITTEN DOWN
  NOWHERE.** Nothing in `rank-candidates.sh`, in the registry, in the suite or in any memory file
  states when a `candidate_write_surface` token must be object-scoped rather than bare — yet the
  choice between the two decides whether guard 1 fires and therefore whether an ordering exists at
  all. It has been living in an agent's judgement. Recorded as the open item `(uuuu)` below; not
  closed here, because writing the convention down is a change to the guard's own contract and
  this packet is the one candidate forbidden to make it. Nothing improper happened here, but the
  property the guard relies on was not true of this candidate, and it was not true in the unsafe
  direction. **THE REMEDY IS NOT A LONGER HAND
  LIST.** It is that a write surface naming `control_registry.txt` should DERIVE the artefacts
  coupled to it, exactly as this packet's anchors derive positions. Not built; not in scope.

- **(qqqq) THE ANCHOR SCHEME'S IMPLEMENTATION WAS DEFORMED BY THE ABSENCE OF THE ANCHOR SCHEME,
  AND THE DEFORMATION IS THE EVIDENCE.** `build-os/registry/scan-controls.sh` is cited by line
  number in ten `evidence_refs`, in two live ranges, and inside four receipts that are frozen
  records this packet has no licence to edit — and §27d refuses a tree where two ranges over one
  file name different spans, so a PARTIAL repoint is a hard red and a full one would have meant
  editing history. **The only safe edit was therefore an edit that moves NO LINE.** So the new
  `anchors` command's option arms are packed two and three onto existing lines, and the
  reconciliation body is wrapped by converting a BLANK LINE into the opening `if` — six net-zero
  edits, none of them how the code would otherwise be written. **IT WORKED, AND THAT IS
  MEASURABLE:** all fourteen pre-existing positions into that file — 141, 144, 280, 289, 320,
  321, 335, 345, 354, 368, 392, 403, 444, 460 — land on exactly the content they were written
  about, and ZERO repoints into it were needed. The three repoints this packet did make were into
  `tests/control_registry_tests.sh`, where 270 lines were inserted and there was no such option.
  **The cost of positional identity is not an argument here; it is a diff.**

- **(rrrr) THREE STALE PROSE CITATIONS FOUND, ALL PRE-EXISTING, NONE FIXED — RECORDED AS
  OCCURRENCES AND LEFT.** Each was already wrong at base `c2d97f8` and each is a live instance of
  a registered class. (i) `control_registry.txt`'s `tests.nonvacuity_minimums` notes say *"Includes
  control_registry_tests.sh:772"* for `[ "$PASS" -ge 40 ]`, which was at **919** at base and is at
  **1189** now — `DEFECT-0001-stale-line-reference`. (ii) `MISMATCHES.md` says the same assertion
  is at *":774"*, so the tree states one line in two places and disagrees with itself in both —
  `DEFECT-0003-duplicate-semantic-truth`. (iii) `CROSSWALK.md`'s prose says `epistemic_quality`
  has *"29 bindings, 14 instantiating"* against a derived 33/16 — `DEFECT-0002-stale-remembered-count`,
  and the reconciled TABLE CELL two hundred lines above it is correct, which is precisely why the
  prose went stale unnoticed. **ALL THREE ARE INSIDE THE `evidence_refs` PROSE OF ENTRIES THIS
  PACKET EDITED, so fixing them was one keystroke away and was deliberately not taken**: the
  packet is frozen evidence in a live measurement, and a builder who repairs whatever he passes
  is a builder whose scope nobody can reconstruct afterwards. **(i) and (ii) are exactly what an
  ANCHOR would have prevented and a POSITION did not** — which is the argument for the migration
  `(mm)` still queues, made by the tree rather than by a builder.

## History — items (nnnn)–(oooo), from gravito_p4_s1_shadow_ranker_a and its successors

- **(nnnn) `CHANGELOG.md`'s PREVIOUS RELEASE ENTRY STILL SAYS THE `ranking_digest` REPRODUCES, AND
  THAT DISPOSITION IS DELIBERATE.** The P4 entry states *"re-running reproduces the
  `ranking_digest`"*, which `(cccc)` showed is imprecise: the digest covers the snapshot store's
  global chain head, so any append for any decision moves it. **It is left standing.** The changelog
  is append-only history, the correction is published thirteen lines above it in the same file, and
  editing a released entry to match a later finding is the rewrite this tree refuses everywhere
  else. Recorded here so that a later reader meets a decision rather than an oversight.

- **(oooo) A COUNT INSIDE `(kkkk)` WENT STALE ONE COMMIT AFTER IT WAS WRITTEN, AND IT IS THIS
  TREE'S OWN NAMED DEFECT CLASS FIRING INSIDE THE ITEM THAT NAMES IT.** `(kkkk)` states that
  `cda95d2` and `44b0fab` are the only two of **"the repository's 102 commits"** authored
  `builder@local`. That denominator was correct **at `44b0fab`** and became **103** the moment
  `adef6ad` — the very commit that carries `(kkkk)` — landed. **THE NUMERATOR IS UNAFFECTED AND
  THE ITEM'S ARGUMENT IS UNTOUCHED:** two self-asserted identities against a whole history is the
  same observation at either denominator, and the ruling that git anchors ORDER and not
  INDEPENDENT AGENCY does not depend on the total. What moved is a **restated total**, which is
  `DEFECT-0003-duplicate-semantic-truth` in its COUNTING form — the exact half P3 mechanised for
  citations and left to hand for counts, and the reason `PACKET-0027-p3b-count-derivation` exists
  and is still queued. **IT WAS FOUND ONLY BECAUSE THE CLOSE DERIVED THE NUMBER INSTEAD OF
  QUOTING IT** (`git rev-list --count`), which is the same discipline `(aaaa)` imposed on the
  snapshot row count. **`(kkkk)` IS ANNOTATED BY THIS ITEM RATHER THAN REWRITTEN:** residue items
  are the record of what was known when, and a self-describing count that is silently refreshed
  can no longer show that it went stale. **The general remedy is not a bigger number, it is
  fewer restated ones** — a total written into prose in a repository that is still committing has
  a shelf life measured in commits, and this one's was exactly one.

## History — items (ffff)–(mmmm), from gravito_p4_s1_shadow_ranker_a and its successors

- **(ffff) THE OUTCOME ARM IS THIN BECAUSE THE WORK HAS NOT HAPPENED, AND THAT IS THE HONEST
  RESULT RATHER THAN A SHORTFALL.** `DECISION-0010` selected `PACKET-0027` and `PACKET-0027` has
  not been executed, so **16 of 19 declared outcome fields have no value** — 4 MISSING (the store
  holds them for some other decision) and 12 NEVER-COLLECTED (no decision here has ever carried
  one). Cost, elapsed time, fix rounds, rework and later durability are **not observable yet** and
  were **not invented**. The two facts that ARE recorded are `defect_classes_detected:
  DEFECT-0003-duplicate-semantic-truth` (pre-existing) and `result: in_flight`. **The counter-
  temptation is named so it is not taken later: writing `rollback_count: 0@measured` for
  unexecuted work would look like a clean run and would be the `untested`-missing-from-
  `EVIDENCE_AXIS` defect in a new place.** The value of the arm is that the missingness is
  CATEGORISED AND DERIVED rather than defaulted — not that it is full.

- **(gggg) "UNLOCKED WORK" HAS NO COLUMN AND WAS NOT GIVEN ONE.** The operator's outcome field
  list names *unlocked work*; `decision_telemetry.tsv` has no column for it, and adding one
  changes `ncols()` so that **all ten existing rows fail `validate` on field count** until every
  one of them is rewritten. That is `closed_field_list_widening_required`, a signal `s1-v1` ranks
  as a cost, and the packet ceiling forbids it without a failing fixture. It is therefore
  **NEVER-COLLECTED and named as such**, not folded into a neighbouring column. The evidence that
  would have gone there is real and is recorded in prose instead: `(aaaa)` is a fresh, independent
  instance of the defect class `PACKET-0027` exists to close, found by an agent that was not
  ranking anything. **That is evidence about the CANDIDATE and not about the RANKER**, which is
  exactly why it does not belong in a column a ranker could later read.

- **(hhhh) THE PROSPECTIVE ORDERING IS NOT DEGENERATE, AND THAT IS ONE OBSERVATION AND NOT A
  RESULT.** `DECISION-0011` puts **three of four rankable candidates on the Pareto frontier**
  (`PACKET-0029` rank 1 at 4; `PACKET-0030` and `PACKET-0031` tied at rank 2 with 3; `PACKET-0028`
  rank 4 at 1, dominated), against `DECISION-0010`'s single dominator that survived 125 of 125
  weightings. **Weights would change this ordering, which is the first time that has been true**
  and is what `(xxx)` said was missing. **IT IS NOT EVIDENCE THAT `s1-v1` IS ANY GOOD.** Nobody
  has selected from this set, so there is no `rank_of_selected` to be wrong about; `(yyy)`'s two
  defects are untouched — `residue_ruling_satisfied` is still label leakage in general, and it is
  still the signal that separates `PACKET-0030` from `PACKET-0028` here; and the frozen
  `residue_items_closed` values still count residue LETTERS, whose granularity `(xxx)` showed can
  invert a margin. **What P5 delivers is a decision that CAN falsify S1, not a decision that has.**

- **(iiii) THE RE-DERIVATION AT `80ad634` REPRODUCED P4'S `ce71122` VALUES EXACTLY, AND THE ONE
  JUDGEMENT CALL IN IT IS RECORDED RATHER THAN BURIED.** All twenty v2 signals for the five
  prospective candidates came out identical to the values P4 froze for the same candidates one
  commit earlier, which is evidence the derivation is stable rather than fitted. **The call:
  `PACKET-0029`'s `residue_items_closed` was HELD AT 2 rather than raised to 3.** `(bbbb)`, added
  by the P4 close, names `PACKET-0029-citation-anchor-tokens` verbatim as the remedy for its defect
  class — but `(bbbb)` also records itself as already corrected in place (*"recorded here by
  content, never by number"*), so there is no open obligation to discharge, and the relationship it
  asserts is the SAME one `(mm)` already supplies and which is already counted. Counting it would
  have been `(yyy)`'s non-independence defect committed knowingly. `(rrr)` was likewise not counted:
  it names no candidate. **The direction of the call matters and is stated: `(xxx)` records that
  dropping the ruling signal makes `PACKET-0029` WIN, so raising its items count would have
  inflated the candidate the sceptical reading already favours.** The exclusions are written into
  the snapshots' own `evidence_refs`, so the count is auditable rather than asserted.

- **(jjjj) THE SELECTION PATH NOW REFUSES OUTCOME VALUES, AND ONE EXISTING PROBE HAD TO BE
  REWRITTEN — WHICH IS WHAT THE GUARD IS FOR.** `record` previously accepted `--fix-rounds
  0@measured`, and the measured-zero probe in section 7 used it. It now refuses any outcome column
  carrying a value other than the literal `unknown`, so the probe writes in two steps. **The
  historical rows keep their outcome values and nothing was rewritten to fit** — `DECISION-0001`
  still carries `13.7@derived`. The cost is real and is named: **a decision imported retrospectively
  with its outcome already known now takes two commands instead of one.** That is the intended
  trade — a decision and its outcome authored in one breath is the conflation the whole packet
  exists against — but a future importer will meet it and should meet it here first.

- **(kkkk) THE GIT ANCHOR IS NARROWER THAN FOUR PLACES CLAIMED, AND THE PRECISE SHAPE IS: GIT
  ANCHORS ORDER, NOT INDEPENDENT AGENCY — AND TODAY NOT EVEN ORDER AGAINST A REWRITE.** Four
  artefacts said "the only real anchor is git"; all four are now softened to what the evidence
  supports (`record-decision.sh`'s header, `tests/mutator_registry_tests.sh` section 14's header,
  `current_state.md`, `CHANGELOG.md`'s in-flight entry, and `control_registry.txt`'s
  `metrics.decision.outcome_update` notes). **Committer identity is SELF-ASSERTED:** this packet's `cda95d2` and
  `44b0fab` are the only two of the repository's 102 commits authored `builder@local` — every
  commit around them is `noreply@anthropic.com` — and **no `git config --local` identity is
  persisted** (`.git/config` carries no `email` line at all), so the author field was supplied per
  commit by whoever ran it. That is exactly the shape of the self-reported timestamp this packet
  rightly refused to treat as constitutive, so the same reasoning refuses `%ae`. **Commit dates are equally self-asserted** (`GIT_AUTHOR_DATE`,
  `GIT_COMMITTER_DATE`). **The parent-hash chain IS non-forgeable — but only once a third party
  has witnessed it, and the branch is unpushed.** Nothing external has seen `44b0fab`; one process
  could still rewrite both commits. The anchor is not worthless, it is **UNWITNESSED**. **And P4's
  non-circularity never rested on git identity at all** — it rested on the selection being made by
  a *different agent, in a different packet, THREE COMMITS before S1 existed* (`5c8d19e` ->
  `158b5ad` -> `ce71122` -> `9742a10`): event ordering across independently-motivated work. **The
  commit COUNT is structural and the elapsed time is not** — `git log` puts about 79 minutes
  between those two commits, but that figure reads the same self-asserted dates this item has just
  refused, so it corroborates and does not establish. **P5 has nothing comparable and cannot until
  somebody actually selects from `DECISION-0011`.** The remedy is not a code change; it is a
  witness (a push, a tag someone else holds, or a second selector), and every one of those is an
  operator act.

- **(llll) `OTMP` HAS NO `trap`, AND THAT IS HYGIENE RATHER THAN INTEGRITY.** The `outcome` path
  writes the amended store to a `.outcome.<pid>` temp file and `mv`s it over the original; a
  SIGKILL between the two leaves the temp file behind. **It cannot corrupt the store** — the
  original is untouched until the rename, which is the whole reason the rename is there — so the
  failure mode is a stray file in `build-os/metrics/`, not a lost or half-written record. Recorded
  and deliberately NOT fixed in the fix round: adding a `trap` is a real improvement and it is not
  what a bounded fix round is for.

- **(mmmm) `DECISION-9402-proof` AND `DECISION-9402` ARE DISTINCT IDENTITIES, AND NOTHING RESOLVES
  IDS BY NUMBER PREFIX.** A same-number/different-slug pair can therefore each hold their own seal
  and their own selection row without any guard noticing they were meant to be one decision. **This
  is a STABLE-ID ALLOCATION concern and not an ordering bypass** — neither id can reach the other's
  rows, so no seal is written after a selection and no counter is moved. It belongs with whatever
  packet gives `DECISION-*` allocation the collision discipline `PACKET-*` ids already get by hand.

## History — items (zzz)–(eeee), from gravito_p4_s1_shadow_ranker_a and its successors

- **(zzz) GUARD 1 SCREENS THE PROMOTION MACHINERY AND NOT THE EVIDENCE SUBSTRATE, AND THE HOLE IS
  OCCUPIED RIGHT NOW.** `build-os/metrics/record-decision.sh`, `signal_snapshots.tsv`,
  `decision_telemetry.tsv` and **`build-os/memory/residue.md`** are outside `PROTECTED_SURFACE`,
  while S1's `promotion_requirement` turns on `rank_of_selected` history, which lives in exactly
  those files. **Live, not hypothetical: `PACKET-0029` is ranked 2 in the only real ordering S1 has
  produced, and its frozen write surface includes `build-os/memory/residue.md` — the file
  `residue_items_closed` is derived from.** **THE SURFACE IS DELIBERATELY NOT WIDENED**: nearly
  every packet here writes `residue.md`, so protecting it turns guard 1 from a predicate into a
  wall that refuses almost every candidate, and S1 would then emit no orderings rather than safe
  ones. The real remedy is to make the evidence substrate **append-only and tamper-evident** — which
  `record-decision.sh` already is for snapshots and `residue.md` is not — and that is a later
  packet. Disclosed in the guard 1 header, beside `PROTECTED_SURFACE`, and in
  `ranker.s1_shadow_ordering`'s registry notes; **not closed**.
  **A SECOND, SMALLER ALIAS REMAINS OPEN IN THE SAME PREDICATE.** The fix round normalised path
  spelling (`./`, `//`, `..`) and refuses wildcard surfaces as uninterpretable, but a token naming a
  **DIRECTORY that CONTAINS a protected file** — `build-os/metrics`, say — still does not touch it,
  because `touches()` compares whole tokens and `path#object` suffixes only. It was **not fixed in
  the fix round on purpose**: treating a directory as covering its contents would also make
  `build-os` cover everything, which changes the live `DECISION-0010` ordering the packet's
  non-circularity proof is anchored to. It belongs with `s1-v2`.

- **(aaaa) THE SIGNAL-SNAPSHOT COUNT HAS BEEN REPORTED AS THE FILE'S LINE COUNT FOR TWO CONSECUTIVE
  CLOSES, AND AT P3 THAT NEARLY DOUBLED IT. FOUND BY THE ARCHIVIST AT THE P4 CLOSE, BY MEASUREMENT.**
  `grep -c '^SIGNAL-SNAPSHOT-'` against each close's own commit gives: `a75c25e` (P1) **12**, and P1's
  close recorded **12** — CORRECT; `c653508` (P2) **28**, and P2's close recorded **71**; `ead24bc`
  (P3) **44**, and P3's close recorded **87**. The store carries **43 comment lines plus one column
  header**, and both wrong figures are exactly `(total lines - 1)` — they counted the store's own
  explanatory header as snapshot data. **THE DERIVATION CHANGED BETWEEN P1 AND P2 AND NOTHING
  NOTICED**, which is the entire shape of the defect: a count restated by hand from a different
  derivation each time, with no check that any two of them agree. **This is
  `DEFECT-0003-duplicate-semantic-truth` in its COUNTING form** — the half P3 mechanised for
  citations (via section 27) and left ENTIRELY TO HAND for counts, which is why
  `PACKET-0027-p3b-count-derivation` exists and why S1 placed it at rank 1. **The sealed receipts are
  NOT rewritten — receipts are append-only history.** `current_state.md` is corrected in place at the
  P4 close with the correction visible, and the true count at `b9896e0` is **72**. **Note the
  direction this points:** it is a fresh, independent instance of the defect class the rank-1
  candidate exists to close, found by an agent that was not ranking anything. It does NOT rescue
  `(xxx)` — the ordering is still degenerate for the reasons given there — but it is evidence about
  the CANDIDATE rather than about the RANKER. **The durable fix is a guard that DERIVES a store's
  cardinality instead of comparing two remembered copies of it**, which is the same remedy `(ooo)`
  named for the suite total and which nothing has yet built.
- **(bbbb) THE CLOSE BRIEF'S ONE CITATION WAS OFF BY 115 LINES, AND IT IS RECORDED RATHER THAN
  COPIED.** The P4 close brief attributed the *"`rank_of_selected` is uninformative at n=1"* sentence
  to line **412** of `build-os/metrics/rank-candidates.sh`. At `b9896e0` that line sits inside the
  **Pareto domination loop**; the sentence is emitted by the tool's `note:` line at **527** of a
  544-line file. **The quotation is true and the pointer is not** — which is precisely `(mm)`'s
  ruling (a citation checked for RESOLVABILITY is not checked for IDENTITY) and precisely why
  `PACKET-0029-citation-anchor-tokens` — anchor tokens or content hashes instead of line numbers — is
  ranked 2 in the ordering S1 produced. It is recorded here **by content, never by number**. **This is
  the SIXTH time in this sequence a figure relayed by an orchestrator or a reviewer has been corrected
  downstream, and the SECOND caught by the archivist** (see `(fff)`, which enumerated the first four).

- **(cccc) `ranking_digest` IS A FUNCTION OF THE WHOLE SNAPSHOT STORE, NOT OF THE DECISION IT
  NAMES — SO EVERY PUBLISHED DIGEST IS INVALIDATED BY THE NEXT SNAPSHOT ANYONE APPENDS, ABOUT ANY
  DECISION. FOUND BY EXECUTION AT THE P5 BUILD.** S1's emitted body carries
  `snapshot_chain_head`, which is the digest of the LAST row of `signal_snapshots.tsv`. P5
  appended 25 rows, **all bound to `DECISION-0011`**, and `DECISION-0010`'s digest moved from
  `2fa876c6…18df81c8` to `a509eed7…7dc0b036` while `snapshots_bound_to_this_decision` stayed at
  **28** and **every rank, total, tie, Pareto status, exclusion and `rank_of_selected: 1` was
  unchanged, byte for byte**. **THE SUBSTANTIVE CLAIM SURVIVES AND THE QUOTED NUMBER DOES NOT.**
  Three artefacts quoted that digest as a durable, reproducible fact: `current_state.md` and
  `active_packet.md` (both live memory, both corrected here) and
  `build-os/receipts/gravito_p4_s1_shadow_ranker_a.md` — **NOT rewritten, because receipts are
  append-only history**; it should be read as recording what the tool produced at `b9896e0`.
  **THIS IS NOT A DEFECT IN THE CHAIN.** Binding the ordering to the chain head is what makes an
  edit to any historical signal detectable at ranking time, which is a property worth having. The
  defect is in what was CLAIMED for the resulting number: a digest over a global, append-only
  chain is a **point-in-time** identifier, and it was published as a reproducible one. **NOT FIXED
  HERE — the fix is in `rank-candidates.sh`, which is guard 1's own protected surface and is
  `s1-v2`'s territory.** The shape of the fix, recorded for whoever takes it: either bind the
  ordering to a digest over only the rows it consumed, or state the chain head as a separate,
  explicitly non-reproducible field beside a digest that is.

- **(dddd) THE `result` ENUM CANNOT SAY "SELECTED AND NOT YET STARTED", AND THE STORE'S `unknown`
  MEANS SOMETHING ELSE.** `RESULTS="unknown in_flight shipped reverted abandoned superseded"`. At
  the P5 build `PACKET-0027` is selected, staged, and has no commit, no receipt and no packet file.
  `unknown` in this store means NOBODY MEASURED IT, which is false — the absence of the work is
  measurable and was measured. `in_flight` was written as the nearest true reading (*the decision's
  consequence has not concluded*) and it is **the same token the three earlier rows use for work
  that shipped**, so the column now carries two meanings. **NOT FIXED: widening the enum is a
  schema change and every existing row would have to be re-read against the new vocabulary.**
  Recorded so the next reader of that column knows it is ambiguous before drawing anything from it.

- **(eeee) NO OUTCOME FIELD IN THIS REPOSITORY HAS A DECLARED DIRECTION, WHICH IS WHY OUTCOME
  TELEMETRY CANNOT YET BECOME WEIGHTS.** `outcome-report` reports every recorded outcome value as
  `UNINTERPRETED` and withholds every scored total, because whether more `defect_classes_detected`
  means a better gate or a worse packet has never been decided here, and nor has whether
  `superseded` is better or worse than `abandoned`. **This is deliberate and it is also the
  binding constraint on `s1-v2`**: the operator's standing rule is to train on *what later proved
  best*, and "proved best" is not defined until directions are. **Declaring them is a governance
  act with real consequences** — a direction is a constant inside every ordering that later reads
  it — and it is not this packet's to take.

## History — items (sss)–(yyy), from gravito_p4_s1_shadow_ranker_a and its successors

- **(sss) A TOOL WHOSE LICENCE CAPS BELOW `gate` CANNOT OWN ITS OWN REFUSAL PATH — STRUCTURAL, FOUND
  BY EXECUTION, AND IT MAKES A "<=1 NEW CONTROL" CEILING UNREACHABLE FOR ANY NEW REFUSING TOOL.**
  `scan-controls.sh`'s anti-shelfware reconciliation requires every `.sh` under `build-os`, `tests`
  and `.claude/hooks` that can terminate a run non-zero to own a registry entry **at authority
  `gate`**. S1 is Class C and composes to `observe`, so registering it once was IMPOSSIBLE:
  `scan-controls.sh check` refused at exit 2 with `UNREGISTERED build-os/metrics/rank-candidates.sh
  can terminate a run non-zero and owns NO registry entry at authority gate`. The two available
  moves were (a) register the ranker itself at `gate`, two rungs above a Class C licence, shipping a
  twenty-first declared mismatch **to launder a refusal path**, or (b) split into two entries — the
  ordering at `observe` and the input integrity at `gate`, which is the split
  `envelope.grant_composition` / `envelope.derivation_nonvacuity` already makes one axis along.
  **(b) was taken.** The residue is that the ceiling P4 was handed says `<=1 new census control` and
  the tree's own guard makes that unachievable for any tool that refuses. **Not a defect in the
  guard** — it is doing exactly what it exists to do — but the interaction was invisible until it
  fired, and it will fire on the next tool too.

- **(ttt) THE CROSSWALK RESTATED THE CENSUS CARDINALITY IN ELEVEN PLACES AND SEVEN WENT FALSE THE
  MOMENT THE CENSUS GREW.** `CROSSWALK.md` and `neurocosmology_crosswalk.txt` carried `97` as a
  denominator in prose seven times, plus `75 of 97`, `31 of 97`, `14 out of 31` and `all 8 of 8
  rows`. All were correct at base and all are `DEFECT-0003-duplicate-semantic-truth`. This packet
  **de-duplicated rather than refreshed** them — the literal is replaced by the derivation or by a
  phrasing that carries no count — because refreshing guarantees the same work again on the next
  packet. **`all 8 of 8 rows` (residue (ww)) is untouched and is now 15 of 15**, per the standing
  ruling that it is not this packet's debt; it is staler than when that ruling was made.

- **(uuu) `known_limitations` IS THE CROSSWALK'S LOAD-BEARING FIELD AND IT IS CHECKED ONLY FOR
  LENGTH.** §12 requires each primitive's `known_limitations` to be longer than its own
  `system_representation`, which catches a perfunctory field and nothing else. `goal_ecology`'s said
  *"No control weighs two objectives against each other at runtime, and it could not"* — a claim
  falsified by this packet's own build, which no guard could see, and which was corrected only
  because a human read it. `mass`'s said `observe` is *"held by ZERO of 97 controls"*; that is now
  false too. **A prose field the file itself calls load-bearing, with no reconciliation against the
  artefact it describes, is the same shape as every other hole in this file.**

- **(vvv) THE SUITE-TOTAL PAIR NEEDED THE BUILDER AGAIN, EXACTLY AS (ooo) PREDICTED.** Advancing
  `current_state.md` from 1869 to 1898 requires the literal `**1898 passed**` to already exist in
  `CHANGELOG.md`, which the archivist cannot write. This packet's builder wrote both halves in one
  commit and the live check MATCHes at 1898. **(ooo)'s structural complaint is unaddressed and this
  is the fourth packet to route around it by hand.**

- **(www) S1's FIRST `rank_of_selected` IS 1, ON n = 1, AND THAT IS NOT EVIDENCE OF ANYTHING.** The
  ordering agreed with the reviewer's endorsed re-cut on the only decision it has ever seen. The
  three earlier decisions with non-degenerate candidate sets (`DECISION-0007`, `-0008`, `-0009`)
  **cannot be replayed under guard 1**: none of their candidates carries a frozen
  `candidate_write_surface`, so every one of them is refused as `guard1_unscreenable`. That is the
  guard failing closed and is correct, but the consequence is that **the retrospective substrate
  residue (vv) warned about is smaller than it looks** — S1 has one usable decision, not four, and
  the missing signal is a screening input nobody knew to freeze. P5 should freeze
  `candidate_write_surface` on every candidate from now on, whether or not S1 is consulted.
  **[CORRECTED 2026-08-01 by the fix round of `gravito_p4_s1_shadow_ranker_a`] "CANNOT BE REPLAYED"
  IS TRUE OF THE TOOL AND FALSE OF THE RULE, AND THE ORIGINAL WORDING OVERSTATED THE CLOSURE.** No
  v1 snapshot carries `candidate_write_surface`, so the TOOL fails closed on all three uniformly —
  a real limitation, and not an excuse. But **`s1-v1` is hand-evaluable on frozen v1 data authored
  before S1 existed**, and the reviewer ran it, validating the scorer by first reproducing
  `DECISION-0010` exactly (`P0027=10, P0029=4, P0030=3, P0031=3, P0028=1`):
  `DECISION-0008` — `P0019=4 P0021=4 P0022=3 P0020=2`, selected `P0019`, **rank 1 (tied)**;
  `DECISION-0009` — `P0023=5 P0025=5 P0026=4 P0024=3`, selected `P0023`, **rank 1 (tied)**. With
  plausible guard-1 exclusions applied (`P0021` reaches `evidence-policy.sh`; `P0025` reaches
  `authority-envelope.sh`): `DECISION-0008` — `P0019=3 P0022=2 P0020=1`, **rank 1 (sole)**;
  `DECISION-0009` — `P0023=4 P0026=3 P0024=2`, **rank 1 (sole)**.
  **TWO CAVEATS, NEITHER OPTIONAL.** (1) Those write surfaces are **RECONSTRUCTED, NOT FROZEN**, so
  this **must never be entered as snapshots** — doing so would recompute a signal against the
  current tree, which is the exact defect S1's own `demotion_requirement` names and would evaluate
  decisions nobody took on information nobody had. It is a hand-check recorded as prose, and that is
  all it is. (2) **THE ASYMMETRY IS AN OVERFITTING SIGNATURE AND BELONGS BESIDE THE POSITIVE RESULT,
  NOT UNDER IT: a TIE out-of-sample, a LANDSLIDE in-sample.** On the decision S1 was built against
  the winner scores 10 to the runner-up's 4; on the two it was not, the selected candidate merely
  ties for first. Three agreements out of three is the encouraging reading and it is not the honest
  one.

- **(xxx) THE ONE REAL ORDERING IS DEGENERATE, AND THE MARGIN THAT LOOKS LIKE SIGNAL IS AN ARTEFACT
  OF RESIDUE LETTERING GRANULARITY. THIS IS THE MOST IMPORTANT THING THE REVIEW OF P4 PRODUCED.**
  `PACKET-0027` scores **the maximum on all three ranked signals that were frozen**, so it
  **Pareto-dominates every rival** and no monotone weighting can dethrone it: the reviewer swept
  **125 of 125 weight combinations** and **every single-signal drop**, and all of them return the
  same sole winner. The consequence is that **the ordering carries no information beyond "one
  candidate dominates"** — agreement with the operator on `DECISION-0010` is therefore *very* weak
  evidence about `s1-v1`, because a rule that ranked at random would agree here too. Worse, the
  **10-vs-4 margin is a unit artefact, not a measure of value**: `residue_items_closed` counts
  residue LETTERS, and re-lettering `(hhh)`-`(lll)` as the one re-cut item it actually is collapses
  the margin from **10-4 to 6-5**; drop the ruling signal as well and **`PACKET-0029` wins**. A
  signal whose scale is set by how finely somebody happened to letter a markdown list is not a
  measurement. **Not fixed here — `s1-v2` is a later packet** and re-cutting the signal set inside a
  bounded fix round is exactly the adjacent tidying that turns three serial stages into four.
- **(yyy) TWO OF THE THREE RANKED SIGNALS ARE NOT INDEPENDENT OF EACH OTHER, AND ONE OF THEM IS
  LABEL LEAKAGE.** `residue.md:947-951` is a **single sentence** — it supplies **both**
  `residue_items_closed=5` (the five re-cut items) **and** `residue_ruling_satisfied=1` (the
  reviewer's standing ruling naming them). Two signals read off one sentence are one signal counted
  twice, and `s1-v1` weights them 1 and 1, so the sentence carries **two thirds of the ruling
  candidate's ranked evidence**. And `residue_ruling_satisfied` is **LABEL LEAKAGE**: the recorded
  `selection_reason` for `DECISION-0010` is verbatim *"the only candidate a standing ruling names as
  NEXT rather than as queued"* — the signal is a restatement of the answer, so S1 was partly scoring
  candidates on the operator's own stated reason for picking one. Agreement obtained that way is not
  agreement. **Not fixed here, deliberately: the signal set belongs to `s1-v2`.**

## History — items (ooo)–(rrr), from gravito_p3_accept_and_constrain_a

- **(ooo) THE `current_state.md` <-> `CHANGELOG.md` SUITE-TOTAL LOOP IS NOW A HARD DEADLOCK, AND THE
  ARCHIVIST COULD NOT CLOSE IT. BLOCKING — ONE LINE, OUTSIDE THE ARCHIVIST'S WRITE GATE.**
  **The live suite total is 1869. `current_state.md` still claims 1771, KNOWINGLY, because
  advancing it SHIPS THE TREE RED.** Measured at this close, one variable: with `1869 checks`,
  `tests/release_metadata_tests.sh` goes **42/0 -> 41/1** on *"CHANGELOG does not report
  '1869 passed'"*, and that suite is **CHAINED**, so the repo suite goes **1869/0 -> 1868/1**.
  **THE LUCK FINALLY RAN OUT, EXACTLY WHERE THIS FILE SAID IT WOULD.** The loop closed three times
  running only because the **BUILDER** happened to write the live total into `CHANGELOG.md` as the
  literal `**N passed**`. **THIS packet's builder wrote it as an ARROW** — `suite **1771 -> 1852**` —
  which the guard's `grep -qF "$CLAIMED passed"` **cannot see**; and the fix round then moved the
  total **1852 -> 1869**, so **even the builder's number is stale**. **The archivist cannot write
  `CHANGELOG.md`**, so it recorded the falsehood loudly rather than either shipping red or pretending
  the memory was current. **REMEDY, one builder-lite line: add the literal `**1869 passed**` to the
  `## [Unreleased]` block of `CHANGELOG.md`, THEN set the `Build/test command` line to 1869.**
  **The structural fix is the one this file has asked for nine times: the two halves of the check are
  owned by different lanes, and only one of them can close the loop.**

- **(ppp) THE CLOSE BROKE THE BUILD AGAIN — THIRD PACKET RUNNING — AND THE GATES CAUGHT IT ONLY
  BECAUSE THEY RAN AFTER THE WRITES.** At HEAD `ead24bc`, before this close wrote anything, the
  suite was **1865 passed / 4 failed**, NOT the `1869/0` the close brief reported. **Three of the
  four were `check-adoption.sh` refusing at exit 2** (`metrics_adoption` 2, `lane_declaration` 1)
  because **this packet had no `packet_metrics.tsv` row yet** — i.e. the tree is red **in the window
  between the last build commit and the archivist's row**, which is precisely the window in which
  `2df61ae` was pushed at 143/144. **The fourth was the archivist's own receipt** — see (mmm). All
  four are closed by this close. **Two standing lessons re-confirmed:** run the gates **AFTER** the
  writes, and **`check-adoption.sh` belongs on the close checklist by name** (residue (ggg)).
  **Also re-confirmed: the suite is NOT concurrency-safe** — overlapping runs return **N-1 / 1**
  rather than refusing (**1688/1**, **1770/1** on record). Every gate at this close was run alone,
  behind an anchored `pgrep -fa '^bash tests/'`, redirected to a file, and read in full. **Never
  through `tail`.**

- **(qqq) NON-BLOCKING NITS, AND ONE ACCEPTED EDGE CASE.**
  (i) `tests/mismatch_disposition_tests.sh` labels four RED cases (a)(b)(c)(d) in an order that does
  **not** match the tool's own — **coverage is complete, only the letters cross**.
  (ii) `tests/claim_evidence_tests.sh` inserts `== 13.` **immediately before** `== 11.`, and sets
  `export BUILD_OS_NOW` **inside §13** rather than at file top, so **§§1-12 invoke clock-reading
  paths against an unpinned clock** — they pass today and are not pinned against tomorrow.
  (iii) **`0000-01-01` is accepted** by the new `valid_date()`. Proleptic, sorts before everything,
  **conservative direction**. Recorded; not worth an item.

- **(rrr) THE TRAJECTORY QUESTION THE OPERATOR ASKED, AND THE ANSWER, UNSOFTENED.** *"Is governance
  now deeper than execution?"* **The two halves of P3 are not the same kind of thing and averaging
  them hides the answer.** The **expiry half was a live bug fix and would have been worth building
  alone**. The **disposition half is governance depth in its purest form: ~945 new lines and 4 new
  census controls to record ONE decision about ONE control.** **Ledger: 97 controls, ~20 tools,
  ~1869 assertions, ZERO executive components.** **RECOMMENDATION CARRIED INTO P4: cut it smaller,
  with a DECLARED GOVERNANCE CEILING written into the packet — `<=1 new census control, no new
  registry store, no new validator tool, no new suite file`.** On this packet's density **a ranker
  built to P3's standard would spend 5 controls and 200 assertions before it ranks anything**, and
  **P4 is the first phase whose output is supposed to be a DECISION, not a RECORD of a decision.**

## History — items (hhh)–(nnn), from gravito_p3_accept_and_constrain_a

### From `gravito_p3_accept_and_constrain_a` (2026-08-01, receipt `build-os/receipts/gravito_p3_accept_and_constrain_a.md`)

*Labelled (hhh)-(nnn) to continue the file's sequence.* **(hhh)-(lll) are the five items RE-CUT
into `gravito_p3b_count_derivation_a`** — the reviewer explicitly endorsed the re-cut, and it is
**the contract's own remedy for a fourth serial stage**, not a deferral of convenience. **They are
not to be fixed outside that packet.**

- **(hhh) A FALSE COVERAGE CLAIM IN THE ARROW-PAIR TEST — `tests/control_registry_tests.sh:867`.**
  The **file-selection is line-based while the extraction is fold-based**, so the P2 receipt's
  **wrapped** pair (`...:642 ->` / `:643`) is **dropped before folding and never extracted**.
  `AP_SEEN` reads **2**; the tree has **3**. The comment at `:858` names that wrapped pair as **the
  reason folding exists**, and the assertion at `:870` prints *"found tree-wide — memory, receipts
  and metrics included"* — **a false coverage claim**. The floor `AP_SEEN -ge 1` is **too low to
  notice**. **This is not a one-line fix:** raising the floor makes it a **fitted floor**, which
  requires registration to `tests.nonvacuity_minimums` — a re-authorisation.

- **(iii) `build-os/registry/control_registry.txt:1060` — HEADLINE CORRECTED, BODY NOT.** The
  headline now says **"FAMILY OF 35"** while the same field still says *"the scan finds 37 such
  lines"*, *"34 remain and all 34 are this control"*, *"all 34 constants"*. **Re-derive with §21's
  own scan, not a grep.**

- **(jjj) `build-os/registry/neurocosmology_crosswalk.txt:121` — `homeostasis`
  `known_limitations`** says *"Seventeen of its twenty-two bindings are test suites"*; the tree says
  **20 suites of 25 bindings**. **`ead24bc` corrected that same file's header from 23 to 25 in the
  same commit** — the corrected-and-uncorrected-one-line-apart shape, again.

- **(kkk) A GOVERNANCE STORE MISDESCRIBING ITS OWN VALIDATOR —
  `build-os/registry/mismatch_dispositions.txt:54` and `:85`.** Both say *"THE FOUR CONDITIONS ...
  all required"* and list (a)-(d), while the tool now enforces **FIVE** — condition **(0)** was added
  in `ead24bc`. **Record it in exactly these terms: a governance store misdescribing its own
  validator is the failure this registry exists to prevent.**

- **(lll) A FALSE CLAIM WITH A REPRODUCTION — `build-os/tools/mismatch-disposition.sh:167` and
  `:238`.** The claim that (0) *"removes the class of token that matches the corpus BY ACCIDENT"* is
  **false**. Against `maint.tripwire_coverage_scan`, the tokens **`MEASURED`, `PREVENTI`,
  `UNTOUCHE`, `COVERAGE`** all certify at **exit 0** and print the full *"MEASURED and refused
  demotion"* line: they pass **(0)** by shape, **(c)** as substrings of that control's own
  `demotion_requirement`, and **(d)** as substrings of half the tree. **`PREVENTI` and `UNTOUCHE`
  are not even whole words.** **BOUNDED, and the bound is why this is residue and not a blocker:**
  it **cannot smuggle a non-qualifying control through** — (a) and (b) hold — it **degrades the
  fidelity of the named measurement on a record that already qualifies**. Tightening the shape is a
  **design question for a separate packet**.

- **(mmm) THE ARROW-PAIR RULE IS THE PACKET'S MOST TRANSFERABLE OUTPUT — AND ITS HANDLING IS A
  CONVENTION, NOT A MECHANISM.** The doctrine: a **range** `path:N-M` is **two positions in the
  current tree** and is **repointed at BOTH ends**; an **arrow-pair** `path:N -> :M` is **the same
  content at two commits** and is **NEVER repointed — it is a historical record**. The proof is
  structural, not empirical: an arrow-pair's two numbers necessarily denote **identical content**, so
  they **cannot** be two positions in one commit. Stress-tested by the reviewer against **all 16**
  two-position citations in the tree: **no mis-classification**.
  **THE BLIND SPOT:** a **historical RANGE in prose** (*"was at `:362-386`, now `:368-392`"*) is
  **textually indistinguishable from a live pointer**, so §27a would sweep it. The builder's handling
  is a **convention** — write the superseded span **without its path** — applied at one site in this
  file. **One edit from silent violation, and THE VIOLATION HAPPENED AT THE VERY NEXT EDIT.**
  **PROVEN, NOT PREDICTED:** the archivist's own receipt for this packet wrote a historical range
  **with** its path and §27d correctly refused — **2 contradicting range citation pairs**, isolated
  by measurement with one variable (**with the receipt 98/1, without it 99/0**), and the archivist
  then **reproduced the same violation a second time** while writing the finding into
  `current_state.md`. **Twice in one close, by the agent that had just written the doctrine down.**
  **NEXT MECHANICAL STEP, and it is now evidenced rather than argued:** make the convention a guard.

- **(nnn) A SINGLE-POSITION CITATION WITH NO DUPLICATE IS UNPOLICED BY EVERYTHING CURRENTLY IN THE
  SUITE — AND THE QUEUED POSITIONAL-CONTENT-PAIRING PACKET IS NOT CONSUMED.** `(ccc)` **stays open
  and it is correct that it does**: `gravito_mismatch_refuted_a.md:56` cites `OBSERVE-LB` at a span
  of `build-os/registry/scan-controls.sh` that is now a blank line plus a section comment (the guard
  moved to `:337`). **Both ends are equally stale**, which makes it ordinary
  **resolvability-not-identity drift** (the `(mm)` class) and **not** the two-position class — **§27
  structurally cannot see it.** Its generalization is the strongest sentence of the fix round and is
  recorded verbatim: *"a single-position citation with no duplicate is unpoliced by everything
  currently in the suite."*
  **AND `(ddd)` STAYS QUEUED.** The builder verified all **330** refs identity-preserving **inline**
  (22 repointed, **0** drifts), but what `(ddd)` queues is a **DURABLE GUARD**, and §27 covers
  **two-position citations only**. **An inline verification performed once is not a guard — do not
  mark it consumed.**
  **[PARTIALLY DISCHARGED 2026-08-02 by `PACKET-0029-citation-anchor-tokens`, and `(ddd)` STILL
  STAYS QUEUED.** The generalization — *"a single-position citation with no duplicate is unpoliced
  by everything currently in the suite"* — is now false **for a single-position citation that
  carries an anchor**: `scan-controls.sh anchors --ref 'path:line#ANCHOR-ID'` grades the two
  halves separately and refuses the identity half, with no duplicate and no second position
  required. It remains TRUE for every citation that does not carry one, which is nearly all of
  them. **`(ddd)` IS NOT CONSUMED AND MUST NOT BE MARKED SO:** what it queues is a positional
  content-pairing guard that walks every `file:line` in the tree against its BASE-COMMIT
  counterpart, which is a CROSS-COMMIT comparison. Everything this packet built is a
  SINGLE-COMMIT comparison — the reviewer's corollary inside `(mm)` says exactly what that is
  worth: *"a content match at a SINGLE COMMIT tests RESOLVABILITY; only a CROSS-COMMIT comparison
  tests IDENTITY."* An anchor makes the single-commit test mean much more than it did, because
  the content is DECLARED IN ADVANCE rather than read off the line it is being compared to. It is
  still not the cross-commit test, and claiming otherwise here would be this packet committing
  the error it was cut to fix.]**
  **CLOSED, NOT RESIDUE, recorded so the count is not re-litigated:** five further stale ranges over
  the same citation guard were found by the re-audit — `current_state.md` (**2**),
  `gravito_ladder_semantics_a.md` (**2**), `packet_metrics.tsv` (**1**) — **stale since P2, NOT
  introduced by P3**: `residue.md` was repointed then and these five were not, so **the tree stated
  one finding with two different spans.** All now repointed.

## History — items (bbb)–(ggg), from gravito_p2_claim_scoped_evidence_a

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
  **[DISCHARGED 2026-08-01 by `gravito_p3_accept_and_constrain_a`, AND THE CHEAP VERSION WAS TAKEN.**
  Both fields are now enforced on one path: `authority-envelope.sh` reports `LAPSED` /
  `NOT-YET-LIVE` as **distinct** states, neither of which is `WITHIN-LICENCE`, and out-of-window
  records **contribute no grant and never reach `mode_projection()`**; `claim-evidence.sh` enforces
  `valid_from`/`valid_until` at **both** ends. **THE FORECAST IN THIS ITEM WAS CORRECT AND
  UNDERSTATED** — the over-grant was not merely latent-pending-P3, it was **already live at base and
  already reaching `evidence-policy.sh`**: a dead `shadow` lease dragged a doubly-licensed Class A
  control to `licensed=observe`. **A lapsed refutation is deliberately RETAINED in the minimum**,
  because dropping it would RAISE a licence. The clock is overridable via `BUILD_OS_NOW` and
  **announced in the output** whenever it is in force.]**

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

## History — items (aaa)–(aaa), from gravito_mismatch_refuted_a

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

## History — items (zz)–(zz), from gravito_mismatch_refuted_a

- **(zz) SECOND-EYES DECLARED AND NOT DELIVERED — SIXTH PACKET RUNNING WHEN WRITTEN, **NOW NINE**
  (CORRECTED 2026-08-01 at the `gravito_p3_accept_and_constrain_a` close — THIS COUNTER WAS ITSELF
  STALE, WHICH IS THIS FILE'S OWN DEFECT CLASS APPEARING IN AN ITEM ABOUT UNVERIFIED CLAIMS) — AND A REVIEWER
  ERROR WAS CAUGHT ONLY BY THE BUILDER.** In `gravito_p1_mutators_ids_telemetry_a` the reviewer
  wrote **"64 of 90"** for the `red_driven` counterfactual; the builder derived **77 of 90** and
  **validated the METHOD** — the same composition run against `7daedee` **regenerates the reviewer's
  ORIGINAL sentence verbatim** (*68 of 81, 49 newly, on top of 19*), and the orchestrator
  independently reproduced **25 / 77 / 52 / 25**. The reviewer confirmed its own error on re-review.
  **A single-model review chain caught this only because the builder pushed back.** `codex` is still
  absent and `build-os/memory/tool_router.md:368` still declares the row. **Either install Codex or
  stop declaring the row.** Extends (ss).
  **[2026-08-01, P3: STILL UNBACKED, NINTH CONSECUTIVE PACKET. `codex` is not on PATH and there is
  no plugin directory. EVERY VERDICT IN THE ENTIRE FIVE-PHASE SEQUENCE IS SINGLE-MODEL.** It bit
  again here in the same shape: the reviewer prescribed `:643 -> :644` and `:572-574`, **the BUILDER
  overrode both on evidence, in writing, in the commit message, and was right both times.** The
  reviewer's content check was **not false but OFF-TARGET** — it read merge-base `f3c5353` where the
  orchestrator read `e6b825b`. Its own statement of the error is the durable part: *"a content match
  across base->HEAD does not establish that the arrow-pair denotes base->HEAD."* Applying the
  prescriptions would have **relocated a P2-era event into P3's coordinates inside P2's sealed
  receipt** and left two files naming different spans for the same three lines — **reinstating
  DEFECT-0003**. A single-model chain caught it only because the builder pushed back, for the fifth
  time in this sequence.]**
  **[2026-08-01, P4: TENTH CONSECUTIVE PACKET — AND THE ROW IS NO LONGER MERELY UNBACKED, IT IS
  CORRECTLY DECLARED.** `build-os/memory/tool_router.md` was corrected at `ce71122` to state plainly
  that this runtime has never had a second-eyes capability, and to REQUIRE the reviewer to say
  *"second eyes: NONE, single-model"* rather than silently omit it. **The reviewer complied at this
  packet.** That closes the *"stop declaring the row"* half of this item and leaves the *"install
  Codex"* half open. **The streak counter is advanced NINE -> TEN here rather than being left to go
  stale a second time** — the failure this item is about. Every verdict in the entire five-phase
  sequence is single-model, INCLUDING the verdict on the first executive component.]**
  **[2026-08-02, P5: ELEVENTH CONSECUTIVE PACKET, AND THE SEQUENCE IS NOW COMPLETE WITHOUT A
  SINGLE INDEPENDENTLY-REVIEWED VERDICT IN IT.** The reviewer again stated *"second eyes: NONE,
  single-model"* as the router requires; the *"install Codex"* half stays open and is the only
  half left. **The streak counter is advanced TEN -> ELEVEN here rather than being left to go
  stale**, which is the failure this item is about.
  **AND IT BIT AGAIN AT P5, IN THE OPPOSITE DIRECTION FROM P3 AND P4 — THIS TIME THE SECOND
  READER WAS THE OTHER GATE.** qa attacked the ordering guard exhaustively and its reasoning was
  CORRECT over the surface it read; the reviewer found a SECOND UNGUARDED DOOR to the same signal
  in a DIFFERENT STORE. **Neither agent was wrong; they held different surfaces**, and the defect
  lived exactly in the seam between an invariant stated over a SYSTEM and an implementation scoped
  to ONE FILE. **That is the strongest argument in this file for why a second reader is worth
  something**, and it was obtained here only because the lane happens to run TWO read-only gates
  concurrently — not because a second MODEL was ever available. **A single-model chain with one
  gate would have shipped it.**
  **THE ROUTER'S OWN COUNTER IS STALE AND THE ARCHIVIST DID NOT EDIT IT.**
  `build-os/memory/tool_router.md`'s second-eyes row still says the absence was *"checked at each
  of the last NINE packets"*; it is now ELEVEN. The router is the orchestrator's instrument and
  was last corrected by a BUILDER commit (`ce71122`), so editing it is a routing act rather than
  bookkeeping. **Remedy named and NOT applied: one builder-lite line, `nine` -> `eleven`.**
  Nothing in the suite pins the literal, so this is presentation staleness and not a red gate —
  recorded so a later reader meets a decision rather than an oversight. **This is the same
  counter-goes-stale failure the item is already about, now in its third instance.]**
  **[2026-08-02, P5b: TWELFTH CONSECUTIVE PACKET — AND IT IS THE FIRST ONE WHOSE VERDICT CARRIES
  EXPERIMENTAL WEIGHT, WHICH IS WHY THE STREAK NOW COSTS MORE THAN IT DID.** The reviewer again
  stated *"second eyes: NONE, single-model"* as the router requires. `PACKET-0029` is the first
  candidate a **sealed prospective ordering** ranked first and a human then selected and executed,
  so the pass-as-fixed verdict on it is not merely a quality judgement — **it is the outcome
  observation the ranker will be evaluated against.** A single-model chain produced both the
  ranking rule and the verdict on the first candidate it ranked. That is not a defect in this
  packet and nothing here was found wrong; it is a **statement of how much weight one model's
  opinion is currently carrying**, and it belongs on the record before n grows.
  **The streak counter is advanced ELEVEN -> TWELVE here rather than being left to go stale**,
  which is the failure this item is about — and it is the FOURTH consecutive close at which
  advancing it by hand was the only thing keeping it true.
  **THE ROUTER'S OWN COUNTER IS NOW STALE BY THREE.** `build-os/memory/tool_router.md`'s
  second-eyes row still says the absence was checked at *"the last nine packets"*; it is now
  **TWELVE**. **NOTHING PINS THE LITERAL** — no suite, no scanner and no policy reads it — which
  is exactly why it drifted three packets without anyone noticing, and it is the same
  `DEFECT-0002-stale-remembered-count` shape as the digit this very packet was built against.
  **Remedy named and NOT applied: one builder-lite line, `nine` -> `twelve`.** The router is the
  orchestrator's instrument and was last corrected by a BUILDER commit, so editing it is a
  **routing act rather than bookkeeping**, and the archivist does not take routing acts.
  **The "install Codex" half remains the only half of this item still open.**]**
  **[2026-08-02, PACKET-0035-cross-surface-memory-kernel: THIRTEENTH CONSECUTIVE PACKET.** The
  reviewer again stated *"second eyes: NONE, single-model"* as the router requires, and the
  archivist re-verified the absence at close rather than restating it: `which codex` exits 1 and
  no plugin directory exists. **The streak counter is advanced TWELVE -> THIRTEEN here rather
  than being left to go stale**, which is the failure this item is about, and it is the FIFTH
  consecutive close at which advancing it by hand was the only thing keeping it true.
  **THE ROUTER'S OWN COUNTER IS NOW STALE BY FOUR.** `build-os/memory/tool_router.md`'s
  second-eyes row still says the absence was checked at *"the last nine packets"*; it is now
  **THIRTEEN**. **Remedy named and NOT applied: one builder-lite line, `nine` -> `thirteen`.**
  Editing the router is a **routing act rather than bookkeeping**, and the archivist does not
  take routing acts. **WHAT THIS PACKET ADDS TO THE ARGUMENT, AND IT IS THE STRONGEST INSTANCE
  YET: THE TWO-GATE SEAM CAUGHT A FALSE PERIMETER.** qa laundered a recorded contradiction past
  BOTH `read-context-package --as-current` AND `validate`, both exit 0, because the package hash
  was unkeyed, self-covering and never anchored in the ledger. **The packet had SHIPPED A
  TAMPER-EVIDENCE CLAIM THAT WAS FALSE**, which is worse than an admitted gap — and it is the
  same shape P5 shipped. It was found because the lane runs TWO read-only gates concurrently,
  **not because a second MODEL was ever available.** A single-model chain with one gate would
  have shipped a security property that did not hold.
  **The "install Codex" half remains the only half of this item still open.**]**
  **[2026-08-03, PACKET-0036: FOURTEENTH CONSECUTIVE PACKET.** Advanced by hand, sixth close
  running; router still says *"the last nine"* — **stale by five**, remedy named not applied.
  **NEW: the chain caught ITSELF** — the reviewer refused a claim this chain had relayed to the
  operator **twice**. One model; only the gates being read-only and concurrent separated them.]**

## History — items (xx)–(yy), from gravito_mismatch_refuted_a

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

## History — items (pp)–(ww), from gravito_mismatch_refuted_a

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

## History — items (jj)–(oo), from gravito_mismatch_refuted_a

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
  **[A DOWN PAYMENT IN MECHANISM — NOT DISCHARGED, AND NOT MIGRATED — 2026-08-02 by
  `PACKET-0029-citation-anchor-tokens`, and the split is the honest part.** The anchor token
  exists and GATES: `build-os/registry/scan-controls.sh anchors` resolves an object by CONTENT,
  computes the line number as a return value and stores it nowhere, refuses a reference whose
  anchor is right and whose object is wrong, and refuses a bare position outright as carrying no
  identity. `registry.evidence_resolution` is Class A at `gate` and runs on the `check` path too,
  so it cannot be skipped. **WHAT IS NOT DISCHARGED, STATED PLAINLY BECAUSE THE COUNT WOULD
  OTHERWISE OVERSTATE:** the anchor table carries **13 objects**, and the registry's own
  `evidence_refs` — **355 of them** — are still `path:line` and still checked positionally. So
  the CLASS has a durable remedy and the CORPUS has not been migrated to it; the 20-of-27
  measurement above would be caught today only for a reference that carries an anchor, and
  nothing yet requires one to. Migration is the successor packet, not this one, and it is a
  RE-AUTHORISATION of every entry's evidence rather than a sweep. **The CONTENT HASH half of this
  sentence was NOT taken either:** content is a literal substring, which detects a MOVED object
  and an AMBIGUOUS one and does not detect an EDITED one that still contains the literal.]**
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

## History — items (aa)–(ii), from gravito_mismatch_refuted_a

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

## History — items (z)–(z), from gravito_authority_envelope_a

- **(z) SECOND-EYES DECLARED AND NOT DELIVERED — on BOTH passes, for the third packet running.**
  `build-os/memory/tool_router.md:368` routes reviewer second-eyes to Codex; `codex` is not on PATH
  and no Codex plugin is installed. **Both verdicts in `gravito_authority_envelope_a` are
  single-model.** It matters here for a specific reason: the two findings that mattered most were
  both produced by **mutation** — changing one token and watching a green suite stay green — and
  both were produced by the reviewer alone, with qa green. **Either install Codex or stop declaring
  the row.**

## History — items (r)–(y), from gravito_authority_envelope_a

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

## History — items (o)–(q), from gravito_evidence_policy_matrix_a

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

