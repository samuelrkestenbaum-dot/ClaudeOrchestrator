# Current State

> The "where are we" snapshot. The orchestrator reads this first every session.
> The archivist advances it when a packet closes. Keep it short and true.
> **HOW THIS FILE IS ORDERED, AND WHY IT IS NOT CHRONOLOGICAL.**
> `build-os/maintenance/rotate-memory.sh` retains a **PREFIX** of the `^## `
> blocks — `routeSegments` keeps `blocks.slice(0, keepN)` and archives the tail,
> measured rather than read off the header — so the sections below run
> **standing truth first, then active state, then history newest-first**, and
> the standing region is **block 1**. Sections are cut at this file's own era
> markers (one per closed packet, in the order they were written) and never
> across one; no section was split to make the pieces a convenient size.
> Every byte of every entry is preserved; only the sectioning changed.
>
> The tool has no notion of protected content and none is claimed for it. What
> protects the standing region is POSITION: it is block 1 and `--keep` is
> validated `>= 1`, so no legal invocation can reach it.
> `tests/build_os_maintenance_tests.sh` section 9 executes that at every legal
> N, and also requires that neither literal
> `tests/release_metadata_tests.sh` section 5 greps out of this file occurs
> anywhere outside block 1 — both are read with `head -n1`, so an archived
> first occurrence would silently re-point that guard.
<!-- rotate-memory:archive-pointer:start -->
**THIS FILE IS NOT THE WHOLE RECORD.** 2 older blocks (24011 B) were rotated out of it; 15 newest blocks (172704 B) remain here.

- batch: `2026-08-04T21:17:59Z`
- archive: `build-os/memory/archive/current_state.archive.md`
- index: `build-os/memory/archive/INDEX.md`
- rotation is by RECENCY ONLY. Older does not mean less important. No source
  content was deleted; only a prior banner THIS TOOL generated was replaced.
<!-- rotate-memory:archive-pointer:end -->

## Standing truth — PROTECTED REGION (block 1; rotation cannot reach it)

Identity, the current build claim, the last close, and the slow-changing facts
the router depends on. This block is the file's FIRST `^## ` block, so every
legal `--keep` retains it.

### Project


- **What this repo is:** Build OS — a native orchestrator for Claude Code (routing
  matrix + packet loop + markdown memory) that turns a repo into a
  plan → build → prove → review → record system.
- **Primary branch / base:** `claude/add-build-os` (current integration base; no
  `main` present in this environment). Active work branch:
  `claude/project-handoff-merge-ramhds` (tip `c653508` before this close commit). Merge-base with
  `origin/claude/add-build-os` = `7ef50e8`.
  **CORRECTED 2026-07-31 — this line previously claimed the branch was UNPUSHED, and it is not.**
  **CORRECTED AGAIN 2026-08-01 at the `gravito_p2_claim_scoped_evidence_a` close — THE LOCAL-ONLY
  LIST BELOW WAS WRONG, AND IT WAS WRONG IN THE DIRECTION THAT UNDERSTATES WHAT HAS BEEN PUSHED.**
  It named `c52915f`, `2df61ae` and `7daedee` as local-only. **All three were pushed.**
  `refs/remotes/origin/claude/project-handoff-merge-ramhds` is at **`7daedee`**, not `6b01173`, and
  `git reflog show` for that ref records **twelve or more** successive `update by push` entries, the
  four most recent being **`7daedee`, `2df61ae`, `c52915f`, `6b01173`**. Re-derived directly from
  the reflog at this close; no claim is made here about whether any of those pushes carried an
  explicit go.
  **LOCAL-ONLY AS OF 2026-08-01, re-derived at this close with `git branch -r --contains` (no remote
  branch contains any of them): `f27c570`, `a75c25e` (`gravito_p1_mutators_ids_telemetry_a`) and its
  close `e6b825b`; `9474cae`, `c653508` (`gravito_p2_claim_scoped_evidence_a`); plus this close
  commit.** Everything at or below `7daedee` is on the remote.
  **THE PREVIOUSLY-LISTED COMMITS `105cb75`, `0555717`, `77a0040`, `88052e7`, `a7ab841`, `c52915f`,
  `b25f3f7`, `566443f`, `2df61ae`, `576751a`, `d0eff10`, `7daedee` ARE ALL PUSHED**, which makes the
  `2df61ae` ships-red note below **more** important, not less.
  **NOTE, and it is the reason a whole finding exists: `2df61ae` WAS PUSHED AND IT SHIPS RED** —
  `./build-os/maintenance/run-tests.sh` is **143/144** at that commit, because the close that wrote
  it left `active_packet.md` with 2 `^## ` blocks and the rotation proof needs >=3. **`576751a`
  repairs it.** Do not treat the pushed history as green.
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
- **Build/test command:** `bash tests/build_os_tests.sh` (2378 checks; no network; temp dirs)
  — **2378 as of the `PACKET-0045` operator-ruled fix commit (benchmark-integrity correction).**
  The delta is **+64**, in exactly two chained suites, derived by running the FULL suite at the
  base worktree (`a9f44ad`: **2314/0**) and at HEAD and comparing the per-suite CHAINED
  **vector**, twice solo at HEAD after an anchored `pgrep -fa '^bash tests/'` returned empty:
  `tests/speed_benchmark_tests.sh` **169 -> 221** (+52: RULING 2's eight degraded-run drives,
  RULING 3's witness tests, RULING 6's later-record checks) and
  `tests/control_registry_tests.sh` **168 -> 180** (+12: RULING 4's five identity-coverage
  proofs). Every other chained suite is **+0**, including
  `tests/neurocosmology_crosswalk_tests.sh` at 65 — its floors are derived, so the five new
  census bindings moved its counts, not its assertion total.
  `CHANGELOG.md` carries the matching literal `**2378 passed**` (unsplit) under
  `## [Unreleased]`.
  — **THE PREVIOUS FIGURE, KEPT AS THE RECORD IT WAS:** 2314 as of
  `gravito_truthful_name_cleanup_a` (`PACKET-0044`). That delta was **+12**,
  all of it in `tests/build_os_maintenance_tests.sh` **191 -> 203**, and all of it in one
  new section (c4): the fixture-C differential that was missing. It renames the demotion
  predicate's reported field from `protected_in_owner` — which was emitted **false** for
  `(S1)` and `(o)`, both of which ARE protected in their owner — to
  `named_by_nonquoted_marker_in_owner`, which is what the predicate computes. **No predicate
  was widened**; widening would re-open the fail-open the previous packet closed. The break
  is carried by `sentinel_report_schema: 2` and **no alias**. The four known vulnerable
  forms are executed under the PRE-FIX implementation (`0d3a34f`) and **archive at exit 0**,
  and under the shipped one and **refuse at exit 7**. Every other chained suite is **+0**,
  confirmed by comparing the per-suite CHAINED **vector** across two solo runs after an
  anchored `pgrep -fa '^bash tests/'` returned empty (`DEFECT-0013`). `CHANGELOG.md` carries
  the matching literal `**2314 passed**` (unsplit) under `## [Unreleased]`.
  — **THE PREVIOUS FIGURE, KEPT AS THE RECORD IT WAS:** 2302 as of
  `gravito_cross_file_sentinel_identity_a`. That delta was **+37**, all of it
  in `tests/build_os_maintenance_tests.sh` **154 -> 191**, and it arrived in two parts.
  **+28 at the build commits** (section 11, CROSS-FILE IDENTITY RESOLUTION: six red-driven
  fixtures each executed in BOTH directions, plus the stable-id and floor-invariance
  properties and the declared governed identity set). **+9 at the fix commit**, and they are
  the more important nine: the demotion **failed open** — it required an identity to be
  DECLARED elsewhere, never PROTECTED elsewhere, so a quoted live rule left the object
  protected in neither file and a rotation archived it at exit 0. Four ordinary prose forms
  (one a plain markdown blockquote) are now driven as a red drive; the safe shape is proved
  still to demote; the inbound floor is proved to move **1 -> 6**; and every member of the
  five-way identity enum is proved to be EMITTED, not merely declared. Every other chained
  suite is **+0**, confirmed by comparing the per-suite CHAINED **vector** across two solo
  runs after an anchored `pgrep -fa '^bash tests/'` returned empty (`DEFECT-0013`).
  `CHANGELOG.md` still carries that entry's own literal `**2302 passed**` (unsplit), which
  is the record of what THAT packet measured and is not the live total.
  — **THE PREVIOUS FIGURE, KEPT AS THE RECORD IT WAS:** 2265 as of
  `PACKET-0042-process-doctrine-correction`, whose delta was **+37**:
  `tests/gate_depth_tests.sh` **79 -> 113** (the fourth-stage exception
  `mandatory_full_regate` — named, announceable, conjunctive, and not recorded as a
  defect — **+11 at the build commit**, then **+23 at the fix commit** for the
  cross-surface COMMIT-BUDGET guard, section 9) and `tests/bandwidth_tests.sh`
  **41 -> 44** (the commit-ceiling red drive RE-POINTED to the new boundary, both
  sides driven, plus the disclaimer on the cited
  constant). Every other chained suite is **+0**, confirmed by comparing the per-suite
  CHAINED **vector** across two solo runs, not the total alone (`DEFECT-0013`).
  Derived from SOLO full-capture runs after an anchored `pgrep -fa '^bash tests/'` returned
  empty, and reconciled against `CHANGELOG.md`, which carries the matching literal
  `**2265 passed**` (unsplit) under `## [Unreleased]`.
  — **THE GUARD EXISTS BECAUSE THE PACKET'S OWN THESIS FAILED ON THE PACKET.** The
  build commit withdrew `≤2 commits per packet` in `CLAUDE.md` and its global mirror
  and left `README.md:110` — under `## Safety gates (non-negotiable)` — still
  asserting it, and **2242 green assertions were silent**, because nothing guarded the
  commit-budget rule across files. Section 9 compares the RULE, not the prose:
  byte-identity is wrong here because the five governing surfaces state the budget at
  five lengths for five audiences, so each must instead yield the same normalised
  tuple **(build ceiling, fix ceiling) = (2, 1)**, no surface may still ASSERT the
  withdrawn untyped cap (quoting it is legal only beside a withdrawal marker), and the
  nine remaining derived restatements are enumerated by name as a declared register.
  — **THIS PAIR IS ITSELF INSTANCE 4 OF THE DEFECT `PACKET-0041` EXISTS AGAINST**, and it is
  the one instance that packet could NOT mechanise. Two copies of one truth, held in sync
  by a cross-check that only fires under `RELEASE_METADATA_LIVE_SUITE=1`. No static
  derivation reaches it: the number is produced by RUNNING the suite, and the count table
  derives from files, never from processes. Stated here rather than quietly left out of the
  coverage claim.
  — **AND THE FIX ROUND PROVED IT THE HARD WAY.** Item 3 of the reviewer's list added
  assertions, which moved the total **2220 -> 2228**, which required updating **this line,
  the two below it, and `CHANGELOG.md`** — **by hand, in two files.** Fixing the guard for
  instance 4 required PERFORMING instance 4 again. That is the honest measure of what this
  packet did and did not achieve, and it is recorded rather than smoothed over.

- **STANDING OBLIGATION ON EVERY ARCHIVIST CLOSE, FOREVER — `DC-0001` AND THE RECEIPT
  COUNT.** `scan-controls.sh counts` record `DC-0001` binds
  `build-os/memory/tool_router.md:368` to `build-os/receipts/gravito_*.md`. **Writing a
  receipt is what closes a packet, so EVERY close increments the derivation and makes the
  stated figure stale in the same commit.** This is not a one-off handover note for the next
  packet; it recurs at every close for as long as `DC-0001` exists, which is why it is
  recorded HERE and not only in `active_packet.md` — that file is superseded by the next
  packet's declaration, and this obligation outlives it.
  1. **IT REDDENS MORE THAN THE SUBCOMMAND.** `scan-controls.sh counts` exits 2, **and so
     does `scan-controls.sh check`** (the counts block gates the check path), **and
     `tests/control_registry_tests.sh` fails at `:183`** (check is GREEN against the live
     tree) **and again at `:1248`, `:1255` and `:1267`** (the live count table agrees; no
     live record is STALE; the router states what the store derives). A close that does not
     advance the router ships a red tree and a red suite, not a red subcommand.
  2. **THE REMEDY IS ALWAYS THE SAME ONE-LINE PROSE EDIT** to `tool_router.md:368` — set the
     figure to whatever `ls build-os/receipts/gravito_*.md | wc -l` reports, **in the same
     commit as the receipt.**
  3. **AND FROM RECEIPT NUMBER TWENTY-ONE ONWARD IT MUST BE A NUMERAL.** The cardinal table
     in the COUNT-BLOCK **stops at twenty**. `twenty` is readable; **`twenty-one` is
     `COUNT-UNREADABLE` and REFUSES.** So the site is written `**21**`, `**22**`, and so on.
     **THIS IS THE POINT AT WHICH SOMEONE CONCLUDES THE GUARD IS BROKEN AND DELETES
     `DC-0001`.** It is not broken; it is fail-closed on a bounded word table, by design, and
     widening that table is a one-line change to `cnt_num` if anyone prefers words.
  4. **IT HAS NOW BEEN DISCHARGED ONCE, BY EXECUTION AND NOT BY READING.** At the
     `PACKET-0041-count-derivation` close the archivist ran the transition rather than assuming
     it: `counts` exit **0** before the receipt, exit **2** the moment
     `build-os/receipts/gravito_p3b_count_derivation_a.md` made the derivation **twenty**, and
     exit **0** again after `tool_router.md:368` was advanced `nineteen` -> `twenty` **in the same
     commit as the receipt.** The mechanism works; it is not a theory about future closes.
  5. **AND IT HAS NOW FIRED A SECOND TIME, AT EXACTLY THE BOUNDARY POINT 3 PREDICTED.** At the
     `PACKET-0042-process-doctrine-correction` close the derivation moved to **21** and the site was
     written **`**21**`, as a numeral**, because `twenty-one` is `COUNT-UNREADABLE` and refuses.
     `counts` exits **0** after that close. **The prediction in point 3 was not theory; this is the
     close where it fired, and it fired as documented.**
  5. **AND THIS OBLIGATION IS ITSELF SITTING IN A FILE THAT ROTATES — SAY SO RATHER THAN RELY ON
     IT.** `build-os/memory/current_state.md` is in `rotate-memory.mjs`'s `FILE_SPECS`, and has
     already been rotated twice. `build-os/memory/standing_gates.md:1` calls itself the
     never-rotated home of hard stops and states, in its own words, that **a gate written into a
     rotating file and not copied there is a gate with an expiry date** — a rule enforced ONLY for
     lines carrying the literal `HARD STOP`, of which this file has **zero**. What protects this
     obligation today is **POSITION, NOT POLICY**: it sits in block 1, and `--keep` is validated
     `>= 1`, so no legal rotation can reach it. That is a weaker guarantee than the one
     `standing_gates.md` offers. **ATTRIBUTION: THIS IS THE ORCHESTRATOR'S CONSTRAINT, NOT A
     BUILDER DEFECT** — the brief pinned `standing_gates.md` FROZEN, so the builder had no legal
     path to the correct file, put the obligation in the best file it was permitted to write, and
     said so. The remedy — copy it into `standing_gates.md` under a `HARD STOP` line — is an
     **operator act**.

- **STANDING TRAP FOR ANY PACKET THAT EDITS A SUITE FILE — SECTION 21 SCANS `tests/*.sh` AS TEXT,
  INCLUDING COMMENTS.** `tests/control_registry_tests.sh:477-478` greps `-ge N|-gt N` across
  `tests/*.sh` and requires every match to be registered to `tests.nonvacuity_minimums`. **It
  cannot tell an assertion from a comment**, so a comment written to explain WHY a numeric floor
  was deliberately avoided **enrols the comment itself** and turns the check red. It did exactly
  that on the first attempt inside `PACKET-0041`, which is why the rejected form is now described
  in words at `tests/control_registry_tests.sh:1470-1476` instead of being quoted.
  **RECORDED HERE BECAUSE UNTIL THIS CLOSE IT EXISTED ONLY AS A LOCAL COMMENT AT THE SITE THAT HAD
  ALREADY HIT IT, AND IN NO MEMORY FILE** — a trap documented for the one person who no longer
  needs it. Write `-ge 0` / `-ge 1` / `-gt 0` (excluded by rule), assert an EXACT count, or spell
  the membership test as a `case`; and if you must name the rejected form, name it in prose.
  — **The last +11 are the packet's FIX ROUND**, and they exist because two mutants of the
  new guard each killed **ZERO** of 2179 tests: disarming `SENTINEL_GATE_PINS` (observable
  as 18 -> 15 resolved objects on `residue.md` and 4 -> 2 on this file, with the pins going
  3 -> 0 and 2 -> 0), and inverting the declaration index from DEEPEST to SHALLOWEST. Both
  are now killed — 3 and 2 failures respectively. **A guard whose removal breaks nothing is
  not a guard**, and the first of the two was being cited as "verified BY IDENTITY" in a
  rotation receipt while nothing asserted it. The prior figures are preserved below.
  — **2140 as of `PACKET-0038-current-state-reblock`.** The delta was **+19**, all of it
  `tests/build_os_maintenance_tests.sh` §9 — the section that measures whether THIS
  repository's own `current_state.md` can be rotated at all, and whether its standing
  region can be archived. That suite goes **85 -> 104**; every other chained suite is
  **+0**. Derived from a SOLO full-capture run after an anchored `pgrep -fa '^bash tests/'`
  returned empty, and reconciled against `CHANGELOG.md`, which carries the matching
  literal `**2140 passed**` (unsplit) under `## [Unreleased]` ->
  `### In flight (not landed at the released commit)`. **CITED BY HEADING, NOT BY LINE.**
  The prior figures and their provenance are preserved below:
  — **2121 as of `PACKET-0037-residue-reblock`.** The delta was **+18**, all of it
  `tests/build_os_maintenance_tests.sh` §8, the same shape one file earlier: that suite
  went **67 -> 85** and every other chained suite was **+0**.
  — **2103 as of `PACKET-0036-measurement-integrity`.** The delta was **+7**, all of it
  `tests/build_os_tests.sh` §28, the guard for `DEFECT-0013`; every other chained suite is
  **+0**, including `tests/speed_benchmark_tests.sh`, which held at **169** because that
  packet **converted** three assertions rather than adding any.
  **AND THIS IS THE FIRST TOTAL IN SEVERAL PACKETS THAT IS A CONSTANT RATHER THAN A SAMPLE.**
  `DEFECT-0013` is closed: the race that made this number 2095-or-2096 depending on scheduling
  measured **628/4000 (15.70%)** before the fix and **0/4000** after, so a single green run is
  again sufficient evidence for THIS defect. The doubled-run discipline is retained anyway,
  for the reason given in `residue.md` — one repaired non-determinism is not a proof of
  determinism.
  The prior figure and its provenance are preserved below because the reasoning still stands:
- **PREVIOUS (`PACKET-0035`):** 2096 checks
  — measured on a quiet tree at `ea069a7` plus `PACKET-0035-cross-surface-memory-kernel`'s
  build **and its bounded six-item fix round**, from a SOLO full-capture run after an anchored
  `pgrep -fa '^bash tests/'` returned empty. **The delta is +101, ALL of it the new
  `tests/memory_kernel_tests.sh`** (87 at the build commit, 101 after the fix round: +14 for
  the ledger-derived handoff status, the version-bound export body, the laundering attack that
  now refuses at BOTH gates, the scoped `project` read, and the two narrowed claims); every
  other chained suite is +0. **1995 at the previous close**, measured the same way — BUT SEE THE
  FLAKE RECORDED IN `residue.md` `(aaaaa)`: this builder's own base run at `ea069a7`, before
  any edit, returned **1994/1** with the failure in `tests/speed_benchmark_tests.sh`, and the
  cause is a `pipefail`/SIGPIPE race in that suite reproduced at 117 of 4000 iterations. **The
  base total is therefore 1995 on a run where the race does not fire and 1994 on one where it
  does; it is not a property of this packet's changes.** Reconciled against
  `CHANGELOG.md`, which carries the matching literal `**2103 passed**` (unsplit) in the
  release block `## [Unreleased]` -> `### In flight (not landed at the released commit)`.
  **CITED BY HEADING, NOT BY LINE NUMBER, from 2026-08-01 on** — the changelog grows from the
  top, so every line-citation into it decays on every packet, guaranteed rather than
  occasionally. **AND IT DECAYED AGAIN AT THIS CLOSE, EXACTLY AS PREDICTED:** the citation
  was `CHANGELOG.md:24`, then `:28`; `gravito_p2_claim_scoped_evidence_a` prepended 92 lines,
  so the **1689** literal that line pointed at now sits at `:117` and the live **1771**
  literal sits at `:28`. **Both are under the SAME heading**, which is why the heading
  citation above survived the packet and the line citation did not. No line number is
  restated here on purpose. Residue (r). **This pair had gone stale in four consecutive packets** (657 → 1418 → 1485 → 1597),
  each time because the archivist can write this token but **`CHANGELOG.md` is outside its
  write gate**, so the two halves of the check are owned by different lanes and only one of
  them can close the loop. **It has now closed TWICE RUNNING for the same reason and only that
  reason** — at the `gravito_authority_envelope_a` close and again here, both times because the
  **builder** happened to write the live total into the CHANGELOG entry, giving the archivist a
  literal to match. **The structural cause is untouched:** the archivist still cannot write
  `CHANGELOG.md`, so the loop closes by luck of the builder's phrasing, not by design.
  The reason it keeps surviving is worth keeping: **THE GUARD DOES NOT DETECT STALENESS.**
  It detects cross-file *disagreement* — §5 checks that `CHANGELOG.md` contains the literal
  `<count> passed` matching this line — so **two stale files that agree pass it**. Proven
  three times on this same token: at `2a3c9b3` the suite was green at 1418/0 while this line
  claimed 657; at `0555717` green at 1485/0 while this line and CHANGELOG agreed on 1418; at
  `a7ab841` green at **1597/0** while this line and CHANGELOG agreed on **1485**; and at
  `566443f` green at **1617/0** while this line still claimed **1597**; and at `d0eff10` green at
  **1636/0** while this line and CHANGELOG **disagreed** (this line 1617, CHANGELOG already 1636,
  because the builder wrote the live total into the changelog entry) — a **seventh** demonstration
  on the same token, and the first where the two halves were out of step in the *other* direction;
  and at `a75c25e` green at **1689/0** while this line still claimed **1636** and CHANGELOG already
  carried **1689** — an **EIGHTH** demonstration, out of step in the same *other* direction, and for
  the same structural reason. The check
  that actually works is opt-in and **still NOT enabled by the chained suite** —
  `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` compares against a live
  run, and it is the ONLY check that compares memory against a live run. It correctly reported
  `live suite total (1617 passed) contradicts current_state.md's claim (1597)` at the previous
  close, and it is re-run **after** the archivist's writes at every close since. **At this close it
  reports a MATCH at 1636.** **[UPDATED 2026-08-01 at the `gravito_p1_mutators_ids_telemetry_a`
  close: this line now reads 1689, and `RELEASE_METADATA_LIVE_SUITE=1` re-run AFTER the archivist's
  writes reports a MATCH at 1689.]** **[UPDATED AGAIN 2026-08-01 at the
  `gravito_p2_claim_scoped_evidence_a` close: this line now reads 1771, `CHANGELOG.md` carries the
  matching unsplit literal `**1771 passed**`, and `RELEASE_METADATA_LIVE_SUITE=1` re-run AFTER the
  archivist's writes reports a MATCH at 1771. This is the THIRD consecutive close where the pair is
  live rather than stale, and for the THIRD time the reason is that the BUILDER wrote the live total
  into the CHANGELOG entry — the archivist still cannot write `CHANGELOG.md`, so the loop STILL
  closes by luck of the builder's phrasing, not by design.]** Correcting the number does not fix the
  guard; see residue.
  **[DISCHARGED 2026-08-01, after the `gravito_p3_accept_and_constrain_a` close, by the
  orchestrator in the `tiny` lane — the remedy residue (ooo) prescribed, applied exactly.
  THE HISTORY IS KEPT BECAUSE THE FAILURE MODE IS THE POINT.** At the close this line read
  `1771 checks` and was **KNOWN-FALSE**, left in place deliberately because advancing it shipped
  the tree red: `tests/release_metadata_tests.sh` went **42/0 -> 41/1** on *"CHANGELOG does not
  report '1869 passed'"*, and that suite is **CHAINED**, so the repo suite went **1869/0 ->
  1868/1**. The loop had closed three times running only because the BUILDER happened to write the
  live total into `CHANGELOG.md` as the literal `**N passed**`. **THIS packet's builder wrote it as
  an ARROW** — `suite **1771 → 1852**` — which the guard's `grep -qF "$CLAIMED passed"` **cannot
  see**, and the fix round then moved the total **1852 -> 1869**, so even the builder's number was
  stale. `CHANGELOG.md` is **OUTSIDE THE ARCHIVIST'S WRITE GATE**, so the archivist could not close
  this and **did not pretend to** — it annotated instead, which is why the defect survived to be
  fixed rather than being silently carried. **THE SHAPE WORTH REMEMBERING: the false number was
  what kept the normal path GREEN.** `CHANGELOG.md` and `current_state.md` agreed with each other
  and both disagreed with the tree, so the chained cross-check passed; only
  `RELEASE_METADATA_LIVE_SUITE=1`, which actually runs the suite, could see it (**43/1**). Two
  documents agreeing with each other is not evidence — the same defect this repo has now named in
  its citations, its counts, and its evidence axis. Both literals now read **1869**, measured on a
  quiet tree at `5c8d19e`. Residue (ooo) is closed; the DURABLE fix — a guard that derives the
  number instead of comparing two remembered copies — belongs to
  `gravito_p3b_count_derivation_a`.]**
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

### Last close

- **Last closed packet:** `gravito_preintegration_baseline_a`
  (`PACKET-0045-preintegration-baseline`). The full close record — id derivation,
  base, commits, verdict, and what it made true — is the newest history block
  below, preserved verbatim where it was written.
  **THIS LITERAL IS GATE-PINNED AND MUST STAY IN BLOCK 1.**
  `tests/release_metadata_tests.sh` section 5 reads `**Last closed packet:**` and
  `**Build/test command:**` out of this file with `head -n1`, and
  `tests/build_os_maintenance_tests.sh` section 9 refuses if either occurs
  OUTSIDE the standing block. The history entry below therefore carries the
  renamed marker `**Closed <date>:**`, never this one. Renaming, not moving, is
  what keeps the count at exactly one.

### Stable facts (slow-changing)

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

## Where we are — phase state and the ceiling in force

- **AS OF 2026-08-05 (THE LATEST EVENT): THE OPERATOR-RULED FIX ROUND OF `PACKET-0045` IS
  RE-GATED AND CLOSED — qa GREEN, reviewer PASS with ZERO fix items — AND THE BENCHMARK
  MACHINERY IS NOW FROZEN BY OPERATOR RULING.** The rulings block below records what the one
  permitted fix commit (`9f8630c`, on the pushed tip `a9f44ad`) made true; this bullet records
  the re-gate's outcome. **Depth 4 was `mandatory_full_regate`, announced by name and
  satisfied** — the rulings alter logic, derivation, authority and counts, so the contract's
  re-review rules forbade targeted confirmation and a full concurrent qa ‖ reviewer re-gate ran
  instead. **This close is a LATER RECORD, not a reopening:** the original receipt body is
  immutable and untouched; the addendum receipt is
  `build-os/receipts/gravito_preintegration_baseline_fix_a.md`, and a later-record metrics row
  attributes `9f8630c` to the packet while the original row (commits
  `c7433c5,945a140,014afb1,fff967e`) stays byte-identical — the store precedent: a correction
  creates a later record, never edits an earlier one.
- **THE FREEZE IS THE OPERATIVE STATE, AND IT IS THE HEADLINE.** Per operator ruling: no new
  guards, no corpus redesign, no prompt tuning, no new measurement fields without an actual run
  proving necessity, no derived-restatement or scanner-doctrine packet. **The benchmark is an
  instrument to run, not a subsystem to perfect.** The next legitimate benchmark activity is
  RUNNING it, or Repository Core integration events.
- **THE REVIEWER'S TWO NAMED BOUNDS, VERBATIM, DELIBERATELY LEFT INSIDE THE FREEZE.**
  (1) **Weakest remaining link: `BENCH_BASH_TOOL=yes`** — an unverified operator assertion
  producing a degraded run wearing `benchmark_mode: canonical`, discountable only by reading
  the `suite_execution_gate` prose. Named in-band; the freeze rightly leaves it.
  (2) **Nested-unapproved-directory bound:** a refusal-capable executable in a NEW nested
  unapproved directory (e.g. `scripts/x.sh`) is invisible to the scan — detectable only at
  review of the commit creating it; expanding the sweep would breach the freeze. **A bound to
  know, not a defect.** And the trajectory verdict, verbatim: *"a number it produces later can
  be believed without re-auditing the harness provided the record is read, not just the
  number."*
- **PROOF AT THIS CLOSE, RE-DERIVED BY THE ARCHIVIST AFTER ITS OWN EDITS, NOT QUOTED:** full
  solo suite **2378 / 0**; `scan-controls counts` exit **0** with **`DC-0001` stated=25
  derived=25** — this close's new receipt file moved the store **24 → 25** and the router
  numeral (`tool_router.md`, second-eyes row) moved with it **in the same commit**, which is
  what `DC-0001` exists to force. `residue.md` FROZEN and NOT WRITTEN, blob
  `01517ad2c30d447949a98d0b6db9b8d6b538d5a9` re-verified at close. **Second eyes: NONE,
  single-model re-gate** — the streak IS the 25-receipt store; still reachability-blocked
  (key AND network policy — the one still-open operator decision, gating Phase D).
- **Local and unpushed: `9f8630c` + this close commit, and nothing else.** Nothing pushed,
  merged, tagged, PR'd or deployed; no such go given or asked for. **`9f8630c` may not be
  amended** — it is the tree both gates measured.
- **AS OF 2026-08-05 (LATER THE SAME DAY), THE OPERATOR RULED ON `PACKET-0045`'s FOUR OPEN
  DECISIONS, AND THE RULINGS LANDED IN THE PACKET'S ONE CONTRACTUALLY PERMITTED POST-GATE FIX
  COMMIT** on top of `a9f44ad` (the pushed tip; `git merge-base` verified). ONE commit; nothing
  squashed, amended or rebased; the three pre-gate commits stay classified as BUILD commits and
  `014afb1` is NOT retroactively relabelled. A full re-gate follows
  (`Depth: 4 — reason: mandatory_full_regate`). What the commit makes true:
  **(RULING 2)** every `bench/run-corpus.sh` result carries `benchmark_mode:`
  (canonical|degraded — no third state, no absence; **absence is INVALID, not canonical**) and
  `canonical_comparison_eligible:`; the undocumented `FORCE_DEGRADED=1` bypass is REMOVED and the
  one supported degraded interface is `--i-accept-a-degraded-run`, which refuses without an
  explicit `--degraded-reason`, warns, and marks every record and artifact; a degraded row is
  refused at the store door by `record-packet.sh` (the recording path is the real consumer — no
  A/B comparator exists and the store is the only aggregation surface). Eight drives, both
  directions, `tests/speed_benchmark_tests.sh` §18.
  **(RULING 3)** `TOOL_CALLS` has two independent witnesses — `tool_use_events` (structural
  parse: distinct tool_use ids in assistant events = model REQUESTS) and `tool_result_events`
  (executor-emitted user events: distinct answered ids = COMPLETED executions) — plus
  `tool_failures`; unestablishable fields read `unavailable`, never 0; disagreement keeps the
  `DISAGREE` print. Six tests, §19.
  **(RULING 4 — the root-shelf precedent and the 2 bench registrations, both closed.)**
  Coverage follows IDENTITY, not geography: `scan-controls.sh` declares approved executable
  roots (`build-os tests .claude/hooks bench`) and discovers EXECUTABLE top-level `.sh`/`.mjs`
  tools; census **105 -> 110** (bench.run_corpus_gate, bench.seed_determinism, plus the three
  refusal-capable top-level installers under the same identity rule — operator-authorized,
  derived, not restated); surfaces **46 -> 51**; declared mismatches **UNMOVED at 22**;
  `scan-controls check|anchors|counts|surfaces` all exit 0. Five proofs,
  `tests/control_registry_tests.sh` §19b.
  **(RULING 6)** `t1_run1_buildos_preintegration` is NEVER edited; a later record row marks
  `status=historical_preintegration_capture`, `harness_version=945a140`,
  `canonical_comparison_eligible=false` — DERIVED: the original carries no `benchmark_mode`
  field and absence is invalid — with machine-readable `known_limitations=` refs into
  `bench/BASELINE_LIMITS.md`.
- **(RULING 5 — THE CONTRACT GAP, RECORDED PRECISELY AND CHANGING NO DOCTRINE.)** The
  ≤2-build+1-fix rule, tree-quiet, and no-amend can become **jointly unsatisfiable** when a
  build commit trips an existing scanner: a RED tree cannot be handed to the gates and cannot be
  amended, **forcing a third build commit even when the packet is correctly scoped**. The three
  pre-gate commits of `PACKET-0045` (`c7433c5`, `945a140`, `014afb1`) are classified honestly as
  BUILD commits. **File for doctrine review only if it recurs during product execution. No
  doctrine packet is opened, and CLAUDE.md is untouched.**

- **AS OF 2026-08-05, LAST CLOSE `gravito_preintegration_baseline_a`
  (`PACKET-0045-preintegration-baseline`) — VERDICT PASS-AS-FIXED.** qa **GREEN**, reviewer
  **fix-then-pass (4 items)**, reconciled to **6** with qa's two and landed in ONE fix commit.
  Base `7fb7f41` (the PUSHED TIP), HEAD `fff967e`; `c7433c5` + `945a140` + `014afb1` = **3 BUILD**,
  `fff967e` = **1 FIX**. Suite **2314 / 0**. Receipt:
  `build-os/receipts/gravito_preintegration_baseline_a.md`.
- **THE HEADLINE IS A PARTIAL RESULT AND MUST NEVER BE RESTATED AS A WHOLE ONE.** This packet
  delivers a **re-runnable pre-integration baseline for ONE of four corpus tasks**, plus
  **validated-but-dormant apparatus for the other three**. It is **NOT "the pre-integration
  baseline."** One quarter produced numbers; three quarters produced a proof of impossibility.
- **T1 RAN AND IS GENUINELY COMPARABLE TO A FUTURE RUN** — instance byte-pinned at
  `bb52f7b5ebbfc918b005a17a594279557a6249f8a94ba9163dcd70d9462614c2`, acceptance by a **hidden
  oracle frozen before the run**, metrics from the CLI's own result object. Wall **29.87 s**,
  **10** model calls, **$0.2130072**, tokens 14 in / 1544 out / 17,037 cache-create /
  289,864 cache-read. **`time_to_first_correct_change` 20.37 s at 5 s poll resolution, stated as an
  UPPER BOUND, derived by polling a hidden oracle, NEVER self-reported.** Row
  `t1_run1_buildos_preintegration`, evidence `transcript`.
- **T2/T3/T4 ARE IMPOSSIBLE HERE AND PRODUCED NO NUMBERS.** The headless `claude -p` agent is
  **denied `Bash`**; all three corpus clauses require **the agent** to execute the suite. qa
  reproduced the boundary independently (`permission_denials` on `node test/run.js`) and confirmed
  **no honest path preserves the frozen corpus** — a harness running the suite *for* the agent
  changes the task shape, which the corpus forbids. **`T3` IS THE PROTOCOL'S PRE-REGISTERED PRIMARY
  ENDPOINT, AND IT IS PRECISELY THE TASK THAT CANNOT RUN.**
- **THE APPARATUS IS DORMANT, NOT STRANDED.** Oracles were validated against known-good references
  **without needing an agent run**, so T2/T3/T4 acceptance is proven and waiting. The moment a
  Bash-permitted environment exists, **three tasks become runnable against a byte-pinned instance
  set**, with no redesign.
- **FOUR OPERATOR DECISIONS ARE OPEN AND ARE NOT THE ORCHESTRATOR'S TO TAKE** (receipt §7):
  (1) the **root-shelf precedent** — `bench/` is the first refusal-capable script at the repo root,
  outside `SCAN_DIRS`, so *"if a tool trips the scanner, move it outside the scan scope"* now makes
  **scanner coverage shrinkable by geography, detected by nothing in the suite**; the rejected
  alternative (rewriting `exit 2` to evade the regex) is named as **disguise rather than
  architecture**. (2) The **`<=2 build commits` CONTRACT GAP** — see below. (3) **Phase D's
  key-AND-network gate** — see below. (4) **2 bench gate registrations**, correctly declined
  unilaterally under a 0-new-controls ceiling. **LATER RECORD, SAME DAY: (1), (2) and (4) were
  RULED AND EXECUTED in the packet's one permitted fix commit — see the RULINGS block above.
  (3) remains open.**
- **THE 3 BUILD COMMITS ARE A CONTRACT GAP, NOT A BUILDER BREACH — DO NOT LOG IT AS ONE.**
  Tree-quiet forbids handing a RED tree to the gates and amending is forbidden, so **"<=2 build
  commits" and "hand back green" are JOINTLY UNSATISFIABLE whenever a build commit trips a
  scanner.** Same shape as the flat `<=2 commits` rule the operator already withdrew. The RED at
  `945a140` was real: **2312/2**, `scan-controls check` **exit 2**, **48 surfaces vs 46 gate-owned**,
  both bench scripts UNREGISTERED. The relocation was **necessary, not precautionary**.
- **SECOND EYES: THE CONCLUSION HOLDS BUT ITS EVIDENCE CHANGED, AND THE ROUTER WAS UPDATED.**
  `which codex` now exits **0** (`/opt/node22/bin/codex`, `codex-cli 0.146.0`) — the old
  *"exits 1"* claim in `tool_router.md` was **live-FALSE** and is corrected at this close. What
  blocks Codex is no longer absence but **reachability**: `OPENAI_API_KEY` UNSET **and** the agent
  proxy returns **`403` CONNECT / `connect_rejected — policy denial`** for `api.openai.com:443` on
  both HTTPS and websocket transports. **Provisioning the key is NECESSARY BUT NOT SUFFICIENT — the
  network policy must also allow the host. Two changes, not one. This gates Phase D.**
- **THE FIX ROUND'S LOAD-BEARING DEFECT, FOUND INDEPENDENTLY BY BOTH GATES.** A `FORCE_DEGRADED=1`
  run emitted a record **byte-indistinguishable from a legitimate one** — the exact *"number that
  looks good and isn't"* the gate existed to prevent, **manufactured by the gate's own escape
  hatch**. Every run now emits `suite_execution_gate:` on **both** exit paths, proven head-to-head
  on T3 (`enforced` vs `BYPASSED_via_FORCE_DEGRADED — ... These numbers are NOT corpus results.`).
- **THE NEAR-MISS IS WORTH MORE THAN THE NUMBER IT PROTECTED.** The first harness counted dispatches
  by grepping `"Task"`; the tool is named **`Agent`** in CLI 2.1.222, so it reported **0 dispatches
  for a run that made one** — and would have "confirmed" a stale document **by measuring the wrong
  string**. qa reproduced the mechanism on its own stream. **A false zero reads as "no tool use"
  rather than as an error**, which is the worst failure a witness can have.
- **BOTH `COMPARISON_PROTOCOL.md` BLOCKERS ARE FALSE, VERIFIED BY EXECUTION** — `claude -p` works,
  and a headless run **dispatched `build-orchestrator`** (1 `tool_use` named `Agent`, 0 named
  `Task`, `subagent_type: build-orchestrator`).
- **THE RETROSPECTIVE ARM CAN SUPPORT SHAPE CLAIMS AND NEVER A SPEED CLAIM.** 27 rows unmodified:
  rounds median 4 (1-11), files 11.5 (1-32), insertions 1349.5, tests_added 45, defects_gated 7.
  **`wall_min` is present in 1 of 27 rows.** `defects_escaped` is the literal `-` in **27/27, with
  zero literal `0`s** — "nobody kept looking", never "nobody found anything".
- **CAPACITY, DERIVED AT THIS CLOSE AND NOT QUOTED FROM BELOW.** `residue.md` is **FROZEN and was
  NOT WRITTEN**: blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, **204,369 B, headroom 431 B**,
  still UNROTATABLE at floor 25 of 25. **SIZE AND HEADROOM ARE DIFFERENT NUMBERS and were conflated
  twice this session — 431 B is the HEADROOM.** **DERIVE THE SIZE BEFORE YOU WRITE.**

- **AS OF 2026-08-04, LAST CLOSE `gravito_truthful_name_cleanup_a`
  (`PACKET-0044-truthful-name-cleanup`) — DECLARED FIRST IN ITS OWN COMMIT, AND THE FIRST CLOSE OF
  THIS SEQUENCE WITH THE FIX SLOT UNSPENT.** Verdict **PASS**: qa **GREEN**, reviewer **PASS**,
  **no fix round and therefore no fix commit**. Base `6454220` (the PUSHED TIP), HEAD `ab5d533`;
  `61bee02` (declaration) + `ab5d533` (implementation) = **2 BUILD + 0 FIX**, inside the typed
  budget. Suite **2314 / 0**. **`DEFECT-0011` DID NOT RECUR** — `active_packet.md` declared **1**
  in flight for the packet's whole life, which is the remedy the previous close named.
- **THIS WAS THE LAST GOVERNANCE PACKET, BY THE OPERATOR'S RULING.** Work returns to **Repository
  Core and live provider execution**. The standing backlog below is a **RECORD, NOT A QUEUE** —
  nothing on it is scheduled, and cutting the next packet is the operator's act, not the
  orchestrator's default.
- **THE HEADLINE: THE RENAME IS HONEST AND NO PREDICATE WAS WIDENED — PROVEN BY STRIPPING THE
  COMMENTS, NOT ARGUED.** qa removed every comment from `rotate-memory.mjs` at `6454220` and at
  `ab5d533` and diffed the pure code: **the entire delta is 4 lines** — the
  `SENTINEL_REPORT_SCHEMA = 2` export, the local rename, the field rename, the emission.
  `markerNamingsIn`, `markerIsQuoted`, `buildIdentityIndex` and `inboundProtections` have **ZERO**
  code changes. The reviewer confirmed independently by normalised extraction. **The fail-open
  `1918fc3` closed STAYS CLOSED.**
- **`protected_in_owner` -> `named_by_nonquoted_marker_in_owner`; the local `protectedAtHome` ->
  `namedByNonquotedMarkerInOwner`. NO ALIAS.** The backward incompatibility is carried by
  `sentinel_report_schema: 2` (`SENTINEL_REPORT_SCHEMA`), so a consumer pinned to the old key gets
  `undefined` **plus a version numeral that says why**. **Zero code positions** for the old names;
  they survive on **6 comment lines documenting the break**.
- **WHY NO-ALIAS IS RIGHT, AND THE REVIEWER'S REASON IS BETTER THAN THE ONE IN THE BRIEF: THE BREAK
  IS FAIL-CLOSED IN DIRECTION.** The field's `true` licensed the **riskier** action (demotion), so
  an external consumer that branched on truthiness and now reads `undefined` **stops demoting — it
  becomes more conservative, not less**. Relocating the problem would require the opposite polarity.
- **THE TRAJECTORY JUDGEMENT, VERBATIM, BECAUSE IT IS THE SEQUENCE'S CLOSING FINDING.** Asked
  whether this reversed *"safety claims about safety claims faster than enforcement"*, the reviewer
  answered **"Locally reversed — modestly, and in the right currency."** The fix was a rename plus
  the **DELETION** of a claim, not a new mechanism: enforcement surface unchanged, one false label
  gone. The fixture-C differential converted a **described** property into executed assertions on
  roots whose one-fact difference is itself proved by `diff`/`cmp` before measurement —
  **"enforcement added, not claim added, and the first thing in this sequence that raised the
  enforcement side of the ratio rather than the claim side."**
- **AND WHAT IT DID NOT REVERSE, WHICH IS THE THING TO LEAVE BEHIND.** `rotate-memory.mjs` grew
  **56 lines for a rename, roughly 50 of them comment**, and `CHANGELOG.md` grew **54** for the same
  rename. **The narration-to-code ratio is unchanged and was out of scope.**
  **"The sentinel is correct, and the remaining excess is prose, not predicates."**
- **HEADROOM, RE-DERIVED AT THIS CLOSE AND NOT QUOTED FROM BELOW.** This file is **197226 B**
  against the **204800 B** ceiling — **7,574 B of headroom**. **The `31,102 B` figure in the bullet
  below was true at `6454220` and is STALE**: `ab5d533` and this close both wrote here. **DERIVE THE
  SIZE BEFORE YOU WRITE; ROTATION #4 IS NEXT.** `residue.md` is unchanged at **204369 B / 431 B of
  headroom** and is **STILL UNROTATABLE at floor 25 of 25 — DO NOT WRITE IT.**
- **AS OF 2026-08-04, LAST CLOSE `gravito_cross_file_sentinel_identity_a` — NO PACKET ID, BECAUSE
  THE PACKET WAS NEVER DECLARED.** Verdict **PASS-AS-FIXED** (qa GREEN, reviewer fix-then-pass, 4
  items). Nothing is in flight; `active_packet.md` declares **0** packet ids and stages
  `PACKET-0043-derived-restatement-sweep` and `PACKET-0044` **undeclared**. Suite **2302/0**.
  Base `74575ee`, HEAD `1918fc3`; commits `905b69e` + `0d3a34f` (2 BUILD) + `1918fc3` (1 FIX) =
  **3 of 3, inside the typed budget**, and the fix commit is **NOT** a breach.
- **THE UNDECLARED PACKET IS THE PROCESS FINDING, AND IT IS THE ORCHESTRATOR'S.**
  `active_packet.md:7` read `CLOSED — … NOTHING IN FLIGHT` for the whole life of the packet.
  Recorded as `DEFECT-0011-undeclared-active-packet` / `OCCURRENCE-0020`. The builder flagged it and
  **correctly refused to fix it**: the head block is line-count-pinned by `ANC-0003` at `:89`, so a
  builder writing the declaration would have re-fired `DEFECT-0001` at that exact site.
  `bandwidth.active_packet_singleton` still **permits zero** — the lower bound named as the remedy
  at `OCCURRENCE-0005` remains unbuilt, five occurrences later.
- **THIS FILE HAS ROOM AGAIN: 31,102 B OF HEADROOM (173,698 B against the 204,800 B ceiling), UP
  FROM 3,642 B.** Rotation #3 at `--keep 15` did it, under the new cross-file resolver, window
  `[14, 16]` executed at both bounds. `rotate-memory.mjs` governs it, `--keep` is validated `>= 1`
  so block 1 (standing truth) is unreachable by any legal rotation, and **no ceiling has been
  raised by any close.** The remedy was a rotation, not a bigger number — and it worked.
- **`build-os/memory/residue.md` IS STILL UNROTATABLE AND THAT IS THE PACKET'S HEADLINE.** Floor
  **25 of 25**, blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, **204,369 B / 2,379 lines, 431 B
  of headroom**. qa swept **every keep 1–25**: keeps 1–24 trip **C1**, keep 25 trips **C7** at 431 B
  having archived **nothing**. **C2 was never the binding constraint** — `(o)` and `(S1)` are
  declared in `residue.md`'s OWN block 25 and are live. **The diagnosis that motivated the packet
  was wrong, and the packet proved that against its own interest.** DO NOT WRITE THIS FILE.
- **`active_packet.md` is ALLOW, but KEEP-CONDITIONALLY:** floor **32**, so `--keep 15` REFUSES.

- **PHASE CHANGE — RECORD THIS BEFORE THE PACKET LOG. THE GOVERNANCE-ONLY PHASE IS OVER.** The
  operator has ended it and issued **BUILD AUTHORITY** with an **ANTI-STALL RULE**: build around
  the limitations and record what was built around, rather than pausing on them. The operator's
  framing, verbatim, because it is the standard every packet from here is measured against:
  *"the governance substrate is no longer the bottleneck. The bottleneck is now whether Gravito can
  begin making better decisions than today's planning approaches."*
  **THE SEQUENCE IS FIVE PHASES: P1 mutators/IDs/telemetry (DONE) -> P2 claim-scoped evidence
  (DONE) -> P3 `accept_and_constrain` (DONE) -> P4 S1 shadow ranker (**DONE**) -> P5
  outcome/counterfactual telemetry (**DONE**).**
  **[THE FIVE-PHASE SEQUENCE IS COMPLETE, 2026-08-02, at the
  `gravito_p5_outcome_counterfactual_telemetry_a` close.** What it delivered, stated at the level
  the operator asked the question: P4 built the executive MECHANISM, P5 built the APPARATUS FOR
  MEASURING IT. **Neither has demonstrated executive capability, and P5 says so in its own
  residue.** The honest statement of where the sequence lands is the transition from
  **IMPOSSIBLE TO DEMONSTRATE** to **POSSIBLE TO DEMONSTRATE**: there is now a sealed ordering
  that a later human selection can CONTRADICT. Nobody has selected, so nothing is demonstrated
  yet. **P6 IS NOT DEFINED AND IS NOT THE ARCHIVIST'S TO DEFINE.]**
  **P4 CARRIES A DECLARED GOVERNANCE CEILING, AND IT IS THERE BECAUSE OF P3's DENSITY:**
  **`<=1 new census control, no new registry store, no new validator tool, no new suite file`.**
  Ledger at the end of P3: **97 controls, ~20 tools, ~1869 assertions, ZERO executive components.**
  On P3's density a ranker built to the same standard would spend **5 controls and 200 assertions
  before it ranks anything** — and P4 is the first phase whose output is supposed to be a
  **decision**, not a **record of a decision**.
  Read everything below as **substrate for P4**, not as governance for its own sake.
  **[P4 CLOSED 2026-08-01. THE CEILING WAS HELD, WITH ONE PAID-FOR EXCEPTION.** 0 new stores, 0 new
  validator tools, 0 new suite files, 0 new governance primitives; **exactly ONE new file in the
  whole range** — `build-os/metrics/rank-candidates.sh`, which IS the deliverable. The exception is
  **2 census entries where the ceiling said <=1**, forced by a fixture qa reproduced verbatim at
  base: `scan-controls` REFUSES at exit 2 because a refusal-capable `.sh` must own a registry entry
  **at `gate`**, and S1 is Class C composing to `observe`, so it CANNOT own one. Split into
  `ranker.s1_shadow_ordering` (C/untested/`observe`) + `ranker.s1_input_integrity` (A/red_driven/
  `gate`) — the split `envelope.grant_composition`/`envelope.derivation_nonvacuity` already makes.
  **No 21st mismatch: the declared count is still 20.** Residue (sss) records the general shape: the
  anti-shelfware guard makes a `<=1 new control` ceiling **UNREACHABLE FOR ANY NEW REFUSING TOOL**,
  and it will fire again on the next one. **The ledger the ceiling was written against has now
  changed: 99 controls, ~20 tools, 1909 assertions, and ONE executive component.]**
  **[SUPERSEDED 2026-08-02 at the P5 close, and the figure is DERIVED not remembered:
  100 controls (`grep -c '^control: '`), ~20 tools, 1964 assertions, ONE executive component
  and ONE apparatus for measuring it. The old figures are left visible because a ledger that
  silently refreshes cannot show that it went stale.]**
  **[SUPERSEDED AGAIN 2026-08-02 by `PACKET-0029-citation-anchor-tokens`, DERIVED not
  remembered: 101 controls (`grep -c '^control: '`), ~20 tools, 1995 assertions, ONE executive
  component, ONE apparatus for measuring it, and ONE anchor scheme — 13 anchors over the 12
  declared object types, `bash build-os/registry/scan-controls.sh anchors`. The census growth of
  exactly one is the FORECAST `census_growth_controls=1` sealed for this candidate before it was
  selected, not a coincidence and not a licence for a second.]**
  **[SUPERSEDED AGAIN 2026-08-02 by `PACKET-0035-cross-surface-memory-kernel`, DERIVED not
  remembered: 105 controls (`grep -c '^control: '`), ~21 tools, 2096 assertions, ONE executive
  component, ONE apparatus for measuring it, ONE anchor scheme, and — new here — **ONE
  CROSS-SURFACE MEMORY KERNEL**: eight canonical stores, all seven namespace types, an
  append-only digest-chained ledger of 25 events (`grep -c '^EVT-'`) with all 13 event types
  live, and one governed adapter. **The census grew by FOUR, which is the largest single-packet
  growth in this sequence, and the declared mismatch count went 21 -> 22 — breaking the previous
  standing ruling to HOLD AT 21.** That is not a lapse and it is recorded as such in residue
  `(lllll)`: `lic_of` tops out at `gate` and NO class licenses `execute`, so **every
  durable-write control this repository will ever add MUST declare a mismatch.** The number that
  actually constrains anybody — **gate-on-advise — is 14 at base and 14 at HEAD.**]**
  **[SUPERSEDED AGAIN 2026-08-03 by `PACKET-0036-measurement-integrity`, DERIVED not
  remembered at this close: 105 controls (`grep -c '^control: '` — UNCHANGED, **zero `+control`
  lines in the whole range and NO new control**), ~21 tools, **2103 assertions**, ONE executive
  component, ONE apparatus for measuring it, ONE anchor scheme, ONE cross-surface memory kernel
  (still 25 events — none appended, none rewritten), and — new here — **ONE GUARD OVER THE
  MEASUREMENT SUBSTRATE ITSELF**. Declared mismatches hold at **22**; gate-on-advise holds at
  **14**, execute at **8**, identical at base and at HEAD; `evidence_refs` **372 -> 374 by
  derivation**; anchors **12 resolved / 1 superseded / 0 violations**; **zero re-authorisations**.
  **THE +7 IS THE WHOLE DELTA AND ALL OF IT IS THE NEW GUARD** — `tests/speed_benchmark_tests.sh`
  held at **169** because three assertions were CONVERTED rather than added, and no assertion was
  lost. This is the first ledger entry in the sequence whose assertion count is a **constant**
  rather than a sample.]**
  **[SUPERSEDED AGAIN 2026-08-03 by `PACKET-0039-governed-rotation`, AND THE LINE THAT CHANGED IS
  NOT A COUNT — IT IS THAT ROTATION HAS NOW ACTUALLY RUN.** Every governance count is identical at
  base and at HEAD: 105 controls, 22 declared mismatches, gate 14 / execute 8, 18 occurrences,
  anchors 12 resolved / 1 superseded / 0 violations, suite 2140 / 0 with a byte-identical chained
  vector. **THE CEILING IN FORCE IS UNCHANGED AT 204800 B and `DEFAULT_MAX_BYTES` IS STILL
  `200 * 1024` — NO CEILING WAS RAISED TO MAKE THE ROTATION SUCCEED.** What changed is that
  `build-os/memory/archive/` **now exists** and `residue.md` went from 13262 B OVER the ceiling to
  12995 B UNDER it. **THAT RELIEF IS ALREADY MOSTLY SPENT ON BOTH FILES — DERIVE the current sizes
  (residue `(cccccc)`), do not quote one from here, and expect to rotate before writing much.]**
  **[SUPERSEDED AGAIN 2026-08-03 by `PACKET-0040-rotation-sentinel-guard`, AND AGAIN THE LINE THAT
  CHANGED IS NOT A COUNT.** DERIVED at this close, not remembered: **105 controls**
  (`grep -c '^control:'`), **22 declared mismatches** (`grep -c '^authority_mismatch: declared'` —
  ANCHOR THE PATTERN; unanchored returns 27 and is WRONG), **ZERO re-authorisations**, ~21 tools,
  ONE executive component, ONE apparatus for measuring it, ONE anchor scheme, ONE cross-surface
  memory kernel, ONE guard over the measurement substrate, and — new here — **ONE ROTATION
  SENTINEL**. Suite **2140 -> 2190 / 0**, the whole **+50** in one suite file. **THE CEILING IN
  FORCE IS STILL 204800 B AND `DEFAULT_MAX_BYTES` IS STILL `200 * 1024` — NOTHING WAS WEAKENED,
  RAISED, OR RECLASSIFIED TO MAKE ANY OF THIS FIT.** What changed is that **rotation is now a
  GOVERNED RUNTIME CAPABILITY**: the tool derives
  `minimum_safe_keep = max(block position of every protected or still-open object)` ITSELF and
  refuses any `--keep` below it, printing the floor on every run including allowed ones. Derived
  floors on this tree: **25** for `residue.md` — the value a human hand-derived at rotation #1 —
  **30** for `active_packet.md`, **3** for this file. The operator's success condition (*future
  rotations no longer require a human to rediscover the safe keep value*) is **MET**.
  **DERIVE THE SIZES, DO NOT QUOTE THEM FROM HERE — and read the frozen-file ruling below before
  you plan to write anywhere in memory.]**

## Active decisions, open rulings, and the standing backlog

- **Now:** none active. `gravito_ladder_semantics_a` is **closed** (2026-08-01); its two commits
  `576751a` + `d0eff10` and this close commit are **local-only** and stay that way pending explicit
  go. `build-os/packets/active_packet.md` is cleared, reads NO PACKET IN FLIGHT, **and carries 4
  `^## ` blocks** — clearing it to 2 is exactly what made `2df61ae` ship red at 143/144.
  **THE DECLARATION-ORDERING TENSION IS RESOLVED, AND IT NEEDED NEITHER A THIRD COMMIT NOR A HOOK.**
  The previous packet's reviewer noted that a declaration landing in the SAME COMMIT as the build
  leaves git unable to attest the ordering, and that attesting it appeared to need a third commit or
  a pre-commit hook against a hard cap of two. **`gravito_ladder_semantics_a` spent Commit 1 on the
  DECLARATION ALONE** (`576751a`): trivially green in isolation, cap still 2, **and git now
  corroborates the ordering.** Nothing requires the docs to be the second commit. **This is the
  standing pattern from here on.** Residue (ee) is closed by demonstration.
  **The underlying control gap is NOT closed:** `bandwidth.active_packet_singleton` still refuses
  **two** declared packets and permits **zero**, so pure omission passes clean. Residue (c)/(u).
- **DECISION 2 IS CLOSED — the ladder's definitional bug is FIXED**, by
  `gravito_ladder_semantics_a`, at seven semantic sites plus `scan-controls.sh`. **Decision 3 is
  addressed**: `OBSERVE-LB` is off the gating path. **Decision 1 — the missing fifth outcome — is
  now SPELLABLE but still UNTAKEN**: `observe` is a legal destination at last, and whether to move
  any control onto it remains a governance act nobody has performed.
  **THE NEW BLOCKING DECISION IS THE MUTATION CENSUS**, and the reviewer named it the next packet:
  five modules durably mutate and **not one of those write actions is a registered control at any
  authority**; `maint.managed_set_replacement` sits at `advise` while copying files over a user's
  edits with **no rollback**. **Registering them is a RE-AUTHORISATION and therefore the operator's.**
  Also open: **should Class A license `execute`** (today no class does, deliberately), and **should a
  fifth deployment mode for mutation exist** (`README.md` §3b).
- **THE THREE ORIGINAL DECISIONS, kept for the record — all from `gravito_mismatch_refuted_a`:**
  (1) **the missing FIFTH OUTCOME** — demotion onto the rung the `refuted` cap prescribes is
  unspellable for **67 of 81 controls**, so the framework's four outcomes cannot cover the census;
  the reviewer's **accept-and-constrain** proposal needs an operator envelope and is **not adopted**.
  (2) **the ladder's definitional bug** — both bottom rungs are defined by non-consumption, so no
  rung means *"it is read, but may cause nothing"*; the fix is **six prose sites plus `OBSERVE-LB`**,
  **not one line**. (3) **`OBSERVE-LB`'s placement** — correctly reasoned, but it gates (exit 2) on
  behalf of an axis that deliberately only advises (exit 0), which removes the operator's ability to
  apply the demotion **by hand**. **None is taken.**
  **Still standing from `gravito_authority_envelope_a`:** step 3 **cannot be done by writing
  envelopes** — an envelope only lowers `L_effective` and cannot promote. Do not cut a packet that
  writes envelopes to fix mismatches.
  **AND DO NOT EXTRAPOLATE the two refuted closures to the remaining twelve:** 11 of the 19 findings
  are `unvalidated`, where the remedy is **improve the evidence** and that outcome is **wide open**.
- **Next — THE OPERATOR'S FIVE-PHASE SEQUENCE COMES FIRST AND IS NOT A CANDIDATE LIST.** P1 is
  **DONE** (`gravito_p1_mutators_ids_telemetry_a`). The remaining four, in order:
  **P2. CLAIM-SCOPED EVIDENCE.** **AND IT CARRIES A HARD OBLIGATION FROM P1:** it **must keep
     recording REJECTED candidates** in `signal_snapshots.tsv`. Today only `DECISION-0007` has a
     non-degenerate candidate set — `DECISION-0001` selected all three, `DECISION-0002`..`-0006` are
     `|C| = 1` — so **if P2 and P3 record only the selected arm, P4 starts at n = 1.**
  **P3. `accept_and_constrain`** — the reviewer's missing-fifth-outcome proposal, still untaken by
     the operator (see the three decisions above).
  **P4. S1 SHADOW RANKER** — the consumer everything above is substrate for. Its two open
     decisions are still the operator's: the evidence token (`untested` as a sixth, or S1 arrives
     carrying `unvalidated`) and the `runtimeAuthority: observe` recommendation (advice, NOT
     adopted).
  **P5. OUTCOME / COUNTERFACTUAL TELEMETRY.**
- **Candidates (the standing backlog, subordinate to the five phases) — from this and the previous
  closes' residue.**
  -2. **[CLOSED 2026-08-01 by `gravito_p1_mutators_ids_telemetry_a` — kept for the record, DO NOT
     SCHEDULE.] THE MUTATION CENSUS COVERAGE GAP — THE REVIEWER RULED THIS THE NEXT PACKET.**
     `MISMATCHES.md` §15. Five modules durably mutate and **not one of those write ACTIONS is a
     registered control at any authority**: `rotate-memory.mjs` (renames onto the LIVE memory file —
     the most consequential write in the system), `swarm-merge.sh`, `record-packet.sh`, the identity
     hook, `specialist-handoff.sh`. And `maint.managed_set_replacement` sits at **`advise`** with an
     output that *copies files over a user's edits*, *"none that stops anything"* on failure, and
     **no rollback** — on the corrected ladder that is `execute`, **two rungs up**. **Registering
     any of it is a RE-AUTHORISATION and needs the operator.** Residue (nn).
     **WHAT ACTUALLY HAPPENED: the write ACTIONS were registered as SIX new controls at `execute`
     (census 81 -> 90), and `maint.managed_set_replacement` was examined exactly as asked and
     DELIBERATELY NOT MOVED** — it is `FINDING-0001` with the remedy **named and unapplied**,
     because moving a pre-existing control is the operator's act. `FINDING-0002` holds the same
     shape for `hooks.once_dedup`. **Applying either remedy is STILL OPEN and STILL THE OPERATOR'S.**
  -1. **THE CITATION GUARD CHECKS RESOLVABILITY, NOT IDENTITY.** `scan-controls.sh:368-392` tests
     existence, numeric, in-bounds and not-blank, and **never compares content** — **20 of 27
     drifted refs passed every check while silently wrong**. **The durable fix is an anchor token or
     a content hash instead of a line number**, and it also subsumes candidate 0 below. **And note
     the retroactive discount: a content match at a SINGLE COMMIT tests resolvability; only a
     CROSS-COMMIT comparison tests identity** — several earlier *"zero drift, 287/287"* claims were
     the former reported as the latter. Residue (mm).
  0a. **THE CLOSE CHECKLIST OMITTED A LIVE SUITE AND A PUSHED COMMIT SHIPPED RED.**
     `./build-os/maintenance/run-tests.sh` is **still not chained into the suite** (1771 at
     `c653508`; 1689 at `a75c25e`) and no close brief asked
     for it, so `2df61ae` was pushed at **143/144**. Remedy: chain it, or name every live suite in
     the close checklist. **Orchestrator defect.** Residue (oo).
  0b. **THE LADDER'S SPELLING SWEEP** — deferred with all three grounds upheld. It needs an
     enumeration-**CONTINUATION** test, because the five-rung string is a **PREFIX** of the six-rung
     one and a containment test passes on the correct string. `MISMATCHES.md` §16. Residue (rr).
  0. **Land the prose-citation sweep as a real script.** A working sweep exists **only as a
     throwaway** from this packet and nothing re-runs it. Prose citations have **TWO known escape
     forms**: bare `:NNN` refs, and **`MISMATCHES.md` §10's nonvacuity-table row form, which names a
     file with NO line number at all** — the builder's own first sweep pass mis-resolved that table
     and had to be redone. Residue (aa). Cheapest of the citation-class items and it is the only one
     with a proven implementation already written. **UPDATED 2026-08-01: there are now FOUR known
     escape forms, not two** — bare `:NNN`; §10's table rows with no line number at all;
     **line-wrapped enumerations**, which no same-line grep can see and which hid a fifth stale
     ladder in a file the packet had already edited; and **markdown table-row mappings**, which made
     `evidence_policy_tests.sh` §21's new block **structurally vacuous over `README.md`, its own
     first listed site**. Residue (pp). **UPDATED 2026-08-01 by
     `gravito_p1_mutators_ids_telemetry_a`: there are now FIVE, not four — the fifth is the
     FILE HEADER COMMENT, which reaches no field-scoped sweep** (`neurocosmology_crosswalk.txt`'s
     header said *"1 binding out of 22"* against a live 23 and *"12 out of 25"* against a live
     14 of 27). Residue (tt).
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
  **Blocked on the operator, not schedulable:** the **three decisions above** (the missing fifth
  outcome; the ladder's definitional bug and its six-site-plus-`OBSERVE-LB` radius; `OBSERVE-LB`'s
  placement on the gating path); **whether "declare before building" gets a third commit or a
  pre-commit hook**, since the `<=2-commit` rule is in genuine tension with it; the S1
  evidence-token decision (add `untested` as a sixth token, or have S1 carry `unvalidated`); the S1
  `runtimeAuthority: observe` recommendation (reviewer's advice, **not adopted**); writing the first
  authority envelope at all.
  **NO LONGER OPEN — closed on measurement, do not re-open as scheduled work:** demoting
  `maint.tripwire_coverage_scan`. `gravito_mismatch_refuted_a` was **authorised** to do it, **did
  it**, **measured it destroying live memory at the same exit code**, and **refused**. Retirement is
  worse. Both outcomes are closed with the measurement attached.
  Carried, unrelated: decide Context Mode routing enablement (stays non-secret pilot); name a target
  repo + approve a secret for the GH Actions; authorize/enable the deferred connectors.
- **OPEN RULING, AND IT IS NOW STRUCTURAL RATHER THAN INCIDENTAL — THE `<=2 COMMITS` CAP.**
  `PACKET-0041-count-derivation` is the **SIXTH CONSECUTIVE CLOSE AT THREE COMMITS.** The
  reviewer's generalisation is what turns this from an incident into a rule conflict: **any packet
  receiving a `fix-then-pass` verdict MUST produce a third commit**, because the earlier commits
  are the gated tree both gates measured and amending or squashing them destroys the artefact the
  verdict was about. **So `<=2 commits` and a fix-round mechanic cannot both be satisfied.**
  Recording it a sixth time is **ritual replacing a rule**. The decision is the operator's or the
  orchestrator's and is one of exactly two: **(1) re-cut the cap** — e.g. *"<=2 build commits plus
  at most one fix commit"* — **or (2) delete the cap and stop logging it.** **The archivist did
  not decide it and must not.**
- **OPEN RULING — A THIRD CAUSE OF A FOURTH SERIAL STAGE THAT THE CONTRACT DOES NOT ANTICIPATE.**
  The working contract enumerates two causes for depth 4: the fix list arrived **in installments**,
  or the packet was **mis-cut**. `PACKET-0041` was **neither** — the reviewer's six-item list
  arrived **complete, in one round**, and the fixes were **logic and count changes** that the
  contract's own re-review rules **forbid closing by targeted confirmation** (a re-review that only
  re-checks enumerated items cannot certify a change that moves the suite total). **That is a third
  cause: a complete fix list whose contents are of a kind the re-review rules will not let you
  close narrowly.** Recorded as a **contract gap**, not as a defect of the packet or the reviewer,
  and left for the operator/orchestrator.

## History — `gravito_preintegration_baseline_a` — ONE OF FOUR TASKS, AND AN HONEST IMPOSSIBILITY FOR THE OTHER THREE

- **Closed 2026-08-05:** `PACKET-0045-preintegration-baseline`, verdict **PASS-AS-FIXED**. Receipt
  `build-os/receipts/gravito_preintegration_baseline_a.md`. Lane `substantive`, **depth 3**
  (builder; qa ‖ reviewer; one bounded fix round). Base `7fb7f41`, HEAD `fff967e`.
- **WHAT IT DELIVERED:** byte-pinned task **instances** for a corpus that previously defined only
  task **shapes**; **hidden acceptance oracles frozen before any run**; a harness; a retrospective
  arm over the existing 27 rows; and an explicit record of what could not be measured.
- **WHAT IT COULD NOT DELIVER, AND SAID SO:** T2/T3/T4, **including T3, the pre-registered PRIMARY
  ENDPOINT**. The headless agent is denied `Bash` and all three clauses require the agent itself to
  run the suite. **The apparatus for them is validated and dormant, not stranded.**
- **WHY THE T1 NUMBER IS WORTH KEEPING — the gates, not the harness's own say-so.** Seed
  determinism was **executed**: three seeds into three fresh dirs, the third ~30 min later,
  `diff -r` empty across all pairs, all `bb52f7b5...`; no `$RANDOM`/`$$`/hostname/`date`/network,
  and grepping the seeded tree for hostname, date and absolute path returns nothing.
- **THE ORACLES ARE NON-VACUOUS, AND THE STRONG CASE IS THE ONE THAT COUNTS.** Pristine rejected
  **4/4**, known-good accepted **4/4**. Then qa authored **`gameT2b`** — *a genuine, correct median
  fix with a green 15-passed suite, indistinguishable from a legitimate candidate by every surface
  signal* — and the executed differential **still rejected it**, because the added test passed
  against unfixed source. An oracle that accepts a correct-looking fix which does not demonstrate
  the defect is an oracle that will certify noise; this one does not.
- **THE FIX ROUND (6 items, 1 commit, no test changes, suite held at 2314).** Beyond the
  `suite_execution_gate:` defect: the phantom `--i-accept-a-degraded-run` flag is now named **only
  as never having existed**, with the `--help` `sed` range re-pinned **`2,60` -> `2,65`** because a
  stale range **would have silently truncated the very text being added**; `TOOL_CALLS` gained a
  **structural JSON witness** that prints `DISAGREE` rather than silently preferring one; the
  witness class widened **`[a-z-]` -> `[A-Za-z0-9_-]`** and whitespace-tolerant, **tested 0/0/0
  pre-fix vs 2/1/`build_QA2-orchestrator` post-fix**; and qa's find that the **T1 oracle accepts a
  DIFFERENT false claim** (`returns 10` -> ACCEPT) was surfaced in §5's non-vacuity table **with the
  regex deliberately NOT widened** — a pinned string is right for a frozen instance, the defect was
  visibility.
- **TWO CAVEATS RECORDED WITH THEIR DIRECTION, WHICH IS WHAT MAKES THEM USABLE.**
  `permission_denials` **can undercount** (3 denied blocks yielded 2 entries), but undercounting
  denials makes the environment look **more permissive**, so it **cannot manufacture a false
  IMPOSSIBLE**; and dispatch counters' residual error **inflates**, so **"0 dispatches" cannot be a
  false zero from that mechanism**.
- **THE PATH CORRECTION WENT INTO A FILE, NOT A COMMIT MESSAGE.** `bench/` is at the repo root;
  the `t1_run1_buildos_preintegration` row and the `c7433c5` declaration both name
  `build-os/bench/` and are immutable (append-only store; amending forbidden). The correction lives
  in `bench/BASELINE_LIMITS.md` §5b, **because a commit message is not reachable from
  `packet_metrics.tsv`** — someone re-seeding from that row would follow a dead path and never see
  the explanation.
- **A PROCESS NOTE THE GUARD CANNOT SEE.** `bandwidth.active_packet_singleton` read **0 in flight**
  for this packet's whole declared life, because the declaration reads `**canonical packet id:**`
  and the guard counts `**Packet id:**`. **`DEFECT-0011` did NOT recur in substance** — the packet
  was declared before dispatch, in its own commit (`c7433c5`), as a pure APPEND below `:89` so
  `ANC-0003` never moved. The guard simply supplies no evidence either way; `OCCURRENCE-0005`'s
  lower bound is still unbuilt, six occurrences later.

## History — rotation #4 of this file — MECHANICAL MAINTENANCE, not a governance packet

**Operator-authorized maintenance close, 2026-08-04. No receipt (the `DC-0001` receipt count is
unmoved), no metrics row, no `active_packet.md` change, no residue item, no doctrine.** Prereg
`9c609e6`, tree-verified ancestor of apply `00ef841`; source sha256 `ec22e7e4…` matches the
pre-rotation blob at the prereg commit.

- Keep **15**, window **[15,15]** executed at both bounds: keep 14 fails §9(c) by 260 B; keep 16
  refused by SENTINEL-C7 at 15,950 < 18,702.
- Blocks 16–17 archived; **24,011 B reclaimed**; live 197,226 -> **173,215 B**; headroom
  **31,585 B**, clearing the 18,702 B close budget with 12,883 B margin.
- Append-only proven: the prior 66,894 B archive is an exact prefix of the new 91,186 B archive;
  reconstruction run twice, byte-identical, digest = prereg.
- Suite **2314/0 twice** plus the pre-rotation baseline; CHAINED vector identical under the recipe
  `grep -E '^  CHAINED: '`.
- One stated near-miss: the recovery recipe's first formulation missed the batch's 1-byte trailer;
  corrected by deriving the body from the batch heading — same class as rotation #3's banner
  arithmetic, this time stated rather than latent.
- Both gate-pinned literals verified in block 1 and absent from the archive.

## History — `gravito_truthful_name_cleanup_a` — THE LAST GOVERNANCE PACKET, and the first close with the FIX SLOT UNSPENT

**The long form is `build-os/receipts/gravito_truthful_name_cleanup_a.md`, which has no byte
ceiling. This block is short because this file has less headroom than it looks like it has and
`residue.md` is FROZEN, so the detail lives in the receipt by necessity, not by choice.**

- **Closed 2026-08-04:** `gravito_truthful_name_cleanup_a` (`PACKET-0044-truthful-name-cleanup`).
  Lane `substantive`, **Depth 2** — builder, then qa ‖ reviewer **CONCURRENTLY**; **no third stage
  and no fourth**. Verdict **PASS** (qa GREEN, reviewer PASS). Base `6454220`, HEAD `ab5d533`;
  `61bee02` + `ab5d533` = **2 BUILD commits, 0 FIX commits**. **Second eyes: NONE — TWENTY-THIRD
  consecutive single-model packet**, derived from `ls build-os/receipts/gravito_*.md | wc -l` = 23
  with this receipt; `tool_router.md:368` advanced **22 -> 23** in this close commit because
  `DC-0001` binds that numeral to the receipt store and `scan-controls counts` refuses at exit 2
  the moment they disagree.
- **CONDITION 1 — THE CORRECTION THIS CLOSE OWES THE PRIOR RECORD.** The block below states, as a
  live outstanding item, that *"`tests/build_os_maintenance_tests.sh:1831` and `CHANGELOG.md:69`
  are OUTSIDE the archivist's write boundary and still carry it — carried into `PACKET-0044`"*.
  **THAT SENTENCE IS NOW FALSE AS A LIVE STATEMENT, AND THIS PACKET IS WHY: `ab5d533` DISCHARGED
  BOTH.** The overclaim *"which is exactly when the inbound protection fires"* is **WITHDRAWN at
  both sites** and replaced with the accurate claim — sufficient, **deliberately narrower** than
  all possible owner-file protection, and **the gap FAILS CLOSED**. **The prior block is NOT
  rewritten**: a close record corrects; it does not edit history. **The three citations in it are
  repointed BY CONTENT, and checked for SEMANTICS, here:**
  `tests/build_os_maintenance_tests.sh:1831 -> :1873` and `CHANGELOG.md:69 -> :125` — both now the
  **WITHDRAWAL** rather than the overclaim, which is the semantically correct successor for a
  record that cited them as *still carrying it* — and `rotate-memory.mjs:2617 -> :2673`
  (`export function delimiterMatchedNothing`, byte-identical to its base content).
- **CONDITION 2 — A PROVENANCE GAP IN WORDING, NOT A NUMERIC DISCREPANCY.** qa **could not
  reproduce the builder's per-suite vector digest** (`c5b6fe58e8dcf9e3…`), because the builder
  stated a digest **without stating the extraction recipe**; qa tried six normalisation variants
  and got six different values. qa then verified the **substantive** property under its own stated
  recipe — `grep -E '^  CHAINED: '` over the full capture -> **20 lines**, sha256
  `0d5b87a84bd2fe42…`, **byte-identical across both runs**. **Reproduced again at this close under
  the same recipe, same digest.** **STANDING RULE FROM HERE: state the recipe beside any digest.**
- **CONDITION 3 — AN EVIDENCE-SCOPE NIT OF EXACTLY THE SPECIES THIS SEQUENCE EXISTS TO ELIMINATE,
  RECORDED AND DELIBERATELY NOT FIXED.** `tests/build_os_maintenance_tests.sh:2120-2123` checks
  **one** report (`b.json`) and then states the property **universally** (*"every sentinel report
  carries `sentinel_report_schema`"*). **The claim is TRUE** — qa verified it across 3 live records
  spanning ALLOW and REFUSE, and it is a single unconditional assignment in `evaluateSentinel` —
  **but the assertion does not establish it.** Generalising from n=1 is the shape.
- **CONDITION 4 — A MESSAGE COUPLED TO ASSERTIONS IT DOES NOT ITSELF GUARD. RECORDED, NOT FIXED.**
  `XFILE C4 (6, both poles)`'s `ok()` string names **four** roots while its condition tests **two**
  (`b.json`, `c4-nm.json`). **Nothing is unproven** — the other two roots are separately asserted
  with real `no` branches immediately above — but the string outruns its own guard.
- **THE CITATION TRAP, DEMONSTRATED RATHER THAN ASSERTED.** Left un-repointed, `:2617` would have
  landed on `case "--max-bytes":` and `:2625` on the `--keep must be an integer >= 1` throw — **and
  BOTH would still have RESOLVED and passed the vacuity check.** The drift was created by this
  packet's own **+56 lines** and repaired before shipping. All five targets verified
  **byte-identical to their base content AND semantically correct for the record citing them**.
  `evidence_ref` total **374 -> 376 DERIVED** with the registry's own recipe; the delta is exactly
  the two new fitted floors `:2121` / `:2146`, both **registered** to `tests.nonvacuity_minimums`
  rather than excluded.
- **THE DEMONSTRATIONS ARE EXECUTED, NOT DESCRIBED.** Demonstration 1 ran the **historical tool
  verbatim** — the `git show 0d3a34f:…` branch fired, **not** the sed fallback, confirmed by the
  emitted provenance string. The four form strings live in **one shared `ORPH_FORMS` array**
  (`tests/build_os_maintenance_tests.sh:1906`) iterated by both (c2) and (c4), so demonstrations 1
  and 2 **cannot land on different inputs**. Demonstration 5 is **not vacuous**: the inbound
  protection genuinely fires — resolution
  `cross-file (named in build-os/memory/current_state.md:12)@6`, a real anchor at residue block 6 —
  while the field stays `false` and the floor stays 5.
- **PRE-EXISTING AND NOT TO BE RE-DISCOVERED AS NEW: `MISMATCHES.md:81 -> rotate-memory.mjs:1006`
  DRIFTED FURTHER.** Base content `declaredAt.set(...)`, HEAD content `archived[i] = …`. Already
  recorded as **stale at base `74575ee`**; **not fixed under this close, by instruction.**
- **`residue.md` STAYS FROZEN AND NOTHING IN THE NEW PROSE IMPLIES OTHERWISE.** The reviewer
  grepped every added line: every residue mention is either the `(S1)`/`(o)` **owning-declaration**
  shape used to justify the rename, or a **fixture path**. The CHANGELOG's *"HONEST NEGATIVE
  RESULT — still not rotatable, floor 25 of 25"* paragraph survives **unmodified**. Blob
  `01517ad2c30d447949a98d0b6db9b8d6b538d5a9` at `6454220`, `61bee02`, `ab5d533` and this close.
- **PROOF.** Suite **2314 / 0**, **twice solo** in the foreground after an anchored
  `pgrep -fa '^bash tests/'` returned empty, exit codes captured directly and **never piped through
  `tail`**; per-suite CHAINED vector **byte-identical across runs** (`DEFECT-0013`). Attribution
  **by execution** against base `6454220` (2302/0): `tests/build_os_maintenance_tests.sh`
  **191 -> 203 (+12)**, **all 19 other chained suites +0**. **Commit-1 isolation `61bee02` ->
  2302/0.** `RELEASE_METADATA_LIVE_SUITE=1` **44/0**, live total **2314** matching `CHANGELOG.md`
  (one unsplit literal) and this file. `scan-controls check/counts/anchors/surfaces` all **exit 0**;
  `ANC-0003` RESOLVED at `build-os/packets/active_packet.md:89`. `bandwidth-check` **exit 0**.
  Census **105** (`grep -c '^control: '`), declared mismatches **22**
  (`grep -c '^authority_mismatch: declared'` — ANCHOR THE PATTERN; unanchored returns 27 and is
  **wrong**), re-authorisations **0**. Declaration-first confirmed by inspection: `61bee02` touches
  **one file**, **21 lines for 21** in the head block and **4 for 4** in the branch-base prose, file
  length **1887 -> 1887**.
- **GIT FACTS THAT AGREE, FOR ONCE.** Per-commit `--numstat` sums over `61bee02`+`ab5d533` are
  **8 distinct paths / 495 insertions / 64 deletions**, and the **net union diff
  `6454220..ab5d533` is IDENTICAL** — 8 / 495 / 64 — because **no path was touched by both
  commits** (8 path-visits over 8 paths). This is the first row in `packet_metrics.tsv` where the
  two conventions do not have to be reconciled.
- **NOTHING PUSHED, MERGED, PR'D, TAGGED OR DEPLOYED.** `6454220` is the pushed tip; `61bee02`,
  `ab5d533` and this close commit are **local and unpushed**. No `git config`, no amend, no rebase,
  no secrets. **No byte ceiling was raised anywhere, including `DEFAULT_MAX_BYTES`.**

## History — `gravito_cross_file_sentinel_identity_a` — THE LAST CLOSE, and an HONEST NEGATIVE RESULT

**The long form is `build-os/receipts/gravito_cross_file_sentinel_identity_a.md`, which has no byte
ceiling. `residue.md` is FROZEN at 431 B of headroom, so the residue items are in the receipt and in
`active_packet.md` rather than in `residue.md`. THAT PLACEMENT IS DISPLACEMENT FORCED BY A FROZEN
FILE, NOT A CHOICE.**

- **Closed 2026-08-04:** `gravito_cross_file_sentinel_identity_a`. **NO PACKET ID — never declared.**
  Lane `substantive`. **Depth 4 = `mandatory_full_regate`**, announced and legitimate: the fix list
  arrived **complete in one installment**, the packet was **correctly scoped**, and the fixes altered
  the **demotion predicate** — load-bearing logic the re-review rules forbid closing narrowly.
  **Not a defect.** Verdict **PASS-AS-FIXED**: qa **GREEN**, reviewer **fix-then-pass (4 items)**,
  all four discharged in the archivist's close commit. Base `74575ee`; HEAD at the verdict `1918fc3`.
- **THE HEADLINE IS NEGATIVE AND THE PACKET PROVED IT AGAINST ITS OWN INTEREST.** `residue.md` is
  **still unrotatable**: floor **25 of 25**, every keep **1–25** swept — keeps 1–24 trip **C1**, keep
  25 trips **C7** at **431 B having archived nothing**. **C2 WAS NEVER THE BINDING CONSTRAINT.**
  `(o)` and `(S1)` are declared in `residue.md`'s **own block 25** and are live, so cross-file
  resolution could not move that floor. **The diagnosis that motivated the packet was wrong.** The
  tool's C7 text now names the dead end and the operator remedies instead of leaving them to be
  derived.
- **WHAT IT DID ACHIEVE.** Cross-file identity resolution, a **two-sided win proven by execution**:
  C2's inbound half verified **1 → 6** in a root where the owner protects nothing itself, so
  own-file protection cannot be the answer. **`current_state.md` relieved by rotation #3** — headroom
  **3,642 → 31,102 B**, at `--keep 15`, window `[14, 16]` executed at **both** bounds.
  **`active_packet.md` went from permanently unrotatable to ALLOW** — keep-conditionally: floor
  **32**, so `--keep 15` REFUSES.
- **AND IT CAUGHT ITS OWN FAIL-OPEN BEFORE SHIPPING.** The demotion was first conditioned on the
  identity being merely **DECLARED** elsewhere. A declaration is not a marker, and
  `inboundProtections` skips quoted markers too, so a quoted live rule protected the object in
  **NEITHER** file: **four** ordinary prose forms — one a plain markdown blockquote — each dropped a
  floor 5 → 0 and **archived a live, canonically declared, marked-non-consumable object at exit 0**.
  The base tool refused all four at exit 7. **Caught by a SINGLE-MODEL chain, and only because the
  builder was pushed back on.**
- **THE REVIEWER'S SUMMARY JUDGEMENT, VERBATIM, BECAUSE IT IS THE MOST USEFUL THING PRODUCED THIS
  SESSION:** *"this codebase is accumulating safety claims about safety claims faster than it is
  accumulating enforcement."* **Three instances in this packet alone** of a name promising more than
  its predicate delivers. The `markerNamingsIn` **"one scan, two consumers"** pattern is the right
  antidote — and it **shipped with a new overclaiming label attached** ("safe iff").
- **THE FOUR CLOSE CONDITIONS, DISCHARGED IN THE CLOSE COMMIT.** (1) The **"safe iff" overclaim** is
  false twice over — `inboundProtections` skips `fileName === spec.name` so it can NEVER protect an
  object in its own file, and the condition is **sufficient, not necessary** ((S1) is protected in
  `residue.md` by a marker naming it while `markedIn` is empty). Corrected at the **three sites
  inside `build-os/`**; **`tests/build_os_maintenance_tests.sh:1831` and `CHANGELOG.md:69` are
  OUTSIDE the archivist's write boundary and still carry it** — carried into `PACKET-0044`.
  **No predicate was widened; widening would re-open the hole.** (2) `control_registry.txt:691`
  cited `rotate-memory.mjs:2569` (`--keep must be an integer >= 1`) for
  `maint.rotation_zero_block_warning` — **content-preserving but semantically WRONG**; repointed
  **by content** to **`:2617`** (`export function delimiterMatchedNothing`). (3)
  `rotate-memory.mjs:1168-1173` said **three** forms where **four** were built and driven —
  corrected; it **understated**, which is the safe direction. (4) `1918fc3`'s message says
  *"residue.md untouched at blob 01517ad2, 431 B"* — the blob is exact, but **431 B is the HEADROOM,
  not the size**: the file is **204,369 B / 2,379 lines**. **Immutable commit message — recorded as
  a later correction, history NOT rewritten.**
- **THE TWO GATES APPEARED TO DISAGREE ON THE REPOINTING AND DID NOT.** qa verified every repoint was
  **content-preserving** (old line bytes = new line bytes); the reviewer found all five `.mjs`
  citations moved by exactly **+150** and the `.sh` pair by **+208**, faithfully carrying forward a
  target that was **already wrong at `0d3a34f`**. **Both true. CONTENT-PRESERVING IS NOT SEMANTICALLY
  CORRECT** — this session's recurring defect class appearing **inside the repointing method itself**.
  `:673`'s `:2161` now lands on the `EXIT.CEILING` throw while its former content sits at `:2693`:
  defensible, but **inherited from an offset rather than chosen**, and recorded as such.
- **THE DEMOTION MOVES NO FLOOR ON THIS TREE.** The reviewer **disabled it entirely** and re-derived
  every floor: **identical (25 / 5 / 32)**. It fires twice and is **not currently paying for its risk
  surface**. Bounded and correct — but the fact is on the record.
- **THREE LIMITATIONS RECORDED RATHER THAN BURIED.** `MISMATCHES.md:81` cites
  `rotate-memory.mjs:1006`, which at base `74575ee` was a bare ` */` — **already stale at base**; the
  **shallow-anchor fallback**; and **C8 not gated on `armed`**. Plus the CHANGELOG's narrowing of
  *"cannot be defeated by rewording"* from the **guard** to the **demotion**: `SENTINEL_MARKERS` is
  still **seven fixed phrases**, and the entry now says so.
- **`HISTORICAL_REFERENCE` IS FIXTURE-ONLY.** No governed file carries `## ARCHIVED BATCH`; the tool
  writes it only into `*.archive.md`, outside the governed set. The enum is *"five classes emitted"*
  **in a test root**, not on the tree.
- **REFUSAL-CODE SET, qa's CORRECTION:** HEAD fires **`C1 C3`** where base fires **`C1 C2 C3`**. C2
  correctly no longer fires because the identity **resolves cross-file** — the widening working, not
  a regression.
- **THE ORCHESTRATOR WAS WRONG ABOUT THE M5 COUNTS, AND SAID SO.** It asserted they went stale after
  rotation #3. Both gates measured them **identical at `74575ee`, `0d3a34f` and `1918fc3`**
  (22→19 pins 3→0; 5→3 pins 2→0), and `residue.md` is **byte-identical across the whole range**
  (blob `01517ad2…` at all four commits), so it **cannot** have drifted. **They were already stale at
  base.** No on-tree store carries the label `M5`; it is the gates' shorthand, and that is recorded
  rather than resolved into a citation the archivist would have had to invent.
- **PROOF.** Suite **2302/0**, twice solo, per-suite vectors **byte-identical**. Attribution by
  execution: `0d3a34f → 1918fc3` moves **exactly one vector line** (`build_os_maintenance_tests.sh`
  **182 → 191**); `74575ee → 1918fc3` is **+37**, all of it in that suite (**154 → 191**), all 19
  others **+0**, root-level **+0**. Section 11 counted directly = **37 PASS / 0 FAIL**. **Commit-1
  isolation `905b69e` → 2293/0.** `RELEASE_METADATA_LIVE_SUITE=1` **44/0**, live total **2302**
  matching. `scan-controls` ×4 and `bandwidth-check` all **exit 0**. Census **105**, declared
  mismatches **22** (anchored; the unanchored grep returns 27 and is wrong), re-authorisations **0**.
  Rotation #3 reconstruction **byte-exact at md5 `9f312f93…`**; `--keep 15` window executed at both
  bounds. Archive append-only verified by `cmp` over the correct **37,829 B** prefix, **zero gap**;
  the next **280 B** are exactly the batch banner (**37,829 + 280 = 38,109**).
- **`build-os/memory/residue.md` NOT WRITTEN** — FROZEN, blob
  `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, identical at `74575ee`, `905b69e`, `0d3a34f`, `1918fc3`
  and the close. **No byte ceiling was raised anywhere.**
- **Second eyes NONE — TWENTY-SECOND consecutive packet**, derived (`ls build-os/receipts/gravito_*.md
  | wc -l` = 22 with this receipt); `tool_router.md:368` advanced **21 → 22** in the close commit,
  because `DC-0001` binds that numeral to the receipt store and `scan-controls counts` refuses at
  exit 2 the moment they disagree. **A packet whose central defect was a FAIL-OPEN was gated by one
  model.**
- **NOTHING PUSHED, MERGED, PR'D, TAGGED OR DEPLOYED.** `5d96031` is the pushed tip; the three packet
  commits and the close commit are **local and unpushed**.

## History — `gravito_process_doctrine_correction_a` — the first packet to land INSIDE the budget it installed

**The long form is `build-os/receipts/gravito_process_doctrine_correction_a.md`, which has no byte
ceiling. This file has 10 KB of it and `residue.md` has 431 B, which is why this block is short and
why the residue items are in the receipt and in `active_packet.md` rather than in `residue.md`.
THAT PLACEMENT IS DISPLACEMENT FORCED BY A FROZEN FILE, NOT A CHOICE.**

- **Closed 2026-08-04:** `gravito_process_doctrine_correction_a`
  (`PACKET-0042-process-doctrine-correction`). **Lane `substantive`. Depth 3** — builder, then
  qa ‖ reviewer CONCURRENTLY, then one bounded fix round; **no fourth serial stage**. Verdict
  **PASS-AS-FIXED** — qa **GREEN**, reviewer **fix-then-pass (1 item)**, closed in the archivist's
  commit. Base `5d96031` (the pushed tip); HEAD at the verdict `9a285e6`.
- **THE COMMIT BUDGET, APPLIED TO ITSELF — AND THIS IS THE HEADLINE.** `820fd14` + `f15356e` = **2
  BUILD commits**, `9a285e6` = **1 FIX commit**: **3 of 3, INSIDE the budget.** `bandwidth-check.sh`
  reports `commits OK, 3 since 5d96031, ceiling 3`. **`9a285e6` IS THE PERMITTED FIX COMMIT AND IS
  NOT LOGGED AS A BREACH** — the doctrine this packet installs forbids exactly that. For six
  consecutive closes the record carried a *"three against a cap of two"* line; **its absence here is
  the RESULT, not an omission.** The packet is the first beneficiary of its own rule.
- **WHAT IT MADE TRUE.** `≤2 commits per packet` is **withdrawn as unsatisfiable** (a
  `fix-then-pass` verdict must produce a third commit, and amending the measured commits is
  forbidden) and replaced by the typed **(build ≤2, fix ≤1)**. The depth doctrine gains
  `mandatory_full_regate` as the one named, conjunctive, announceable cause of a legitimate fourth
  serial stage. `tests/gate_depth_tests.sh` §9 now compares the **RULE, not the prose**: five
  governing surfaces must each yield the tuple **(2, 1)** from whatever words they use, no surface
  may still ASSERT the withdrawn cap (quoting it is legal only beside a withdrawal marker), and the
  **nine** derived restatements are a register enumerated **by name inside the test**.
- **THE IRONY, RECORDED BECAUSE IT IS THE MOST INSTRUCTIVE RESULT.** The packet whose thesis is
  *doctrine enforced by machinery, not by writing* shipped **four prose lines saying EIGHT** against
  a shipped array of **NINE** (`${#BUDGET_DERIVED[@]}` = 9, derived at the close, not copied) —
  `PACKET-0041`'s exact defect class. Corrected at the close in `CHANGELOG.md:71`, this file's
  `:104`, and `active_packet.md:1647` and `:1597-1598`.
- **THE HONEST LIMIT, AND IT IS THE PART TO CARRY FORWARD.** `UNTYPED_RE` matches **ONE lexical
  spelling**. Executed reviewer probes: a **reworded** untyped cap on two governing surfaces →
  **113/0, completely blind**; a **live assertion** on a line containing `no longer` → **113/0,
  FAIL-OPEN**, because `no longer` is a withdrawal marker. **THE REPOSITORY IS NOT PROTECTED AGAINST
  COMMIT-BUDGET DRIFT** — one guard, five hand-picked surfaces, an existence-only register over nine
  restatements it did not fix, one spelling. **A genuine narrowing of the failure surface, not a
  closure of it.** The comment at `tests/gate_depth_tests.sh:397` claiming two surfaces *"can
  disagree about every word"* is **false** and oversells the abstraction.
- **LIVE PRODUCT DEBT, OPEN.** `templates/build-os/memory/tool_router.md:28` and
  `templates/build-os/packets/active_packet.md:35` **ship the withdrawn rule to every newly
  scaffolded project.** Staged as the head of the follow-up packet in `active_packet.md`.
- **THE ENFORCER IS NOT TOLD WHAT IT ENFORCES.** The census records the **reviewer** as enforcing
  the build/fix split, `bandwidth-check.sh` defers the partition to it, and
  **`.claude/agents/reviewer.md` never mentions the commit budget.** In the reviewer's words:
  *"I was not told the rule I am recorded as enforcing."*
- **PROOF.** Suite **2265/0**, twice solo, CHAINED vector byte-identical; **+37** (`gate_depth`
  79→113, `bandwidth` 41→44, every other suite **+0**). **Commit-1 isolation `820fd14` → 2228/0.**
  `RELEASE_METADATA_LIVE_SUITE=1` 44/0; `memory_kernel_tests.sh` 101/0 with `ANC-0003` at
  `active_packet.md:89` byte-unchanged at all four commits. Ceiling **0/0/0/0/0** over 11 paths.
  Census **105**, declared mismatches **22** (anchored), re-authorisations **0**. Citations: **zero
  live breaks**. Metrics row appended, `--verify-git` VERIFIED at 11 files / 653 insertions / 63
  deletions (per-commit sums; net union diff 11/640/50, the 13/13 gap fully accounted).
- **`build-os/memory/residue.md` NOT WRITTEN** — FROZEN, blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`,
  unchanged at this close. **No byte ceiling was raised.**
- **Second eyes NONE, TWENTY-FIRST consecutive packet** — derived, and `tool_router.md:368` advanced
  `twenty` → **`21`** in the close commit, the first numeral (see the standing obligation, point 5).
- **NOTHING PUSHED, MERGED, PR'D, TAGGED OR DEPLOYED.** `5d96031` is the pushed tip; the three
  packet commits and the close commit are **local and unpushed**.

## History — `gravito_p3b_count_derivation_a` — the first DERIVED count

**Everything below is the summary. The long form — coverage instance by instance, the
file-ownership manifest, the escapes, the two items routed to the operator undecided, and the
contract gap — is `build-os/receipts/gravito_p3b_count_derivation_a.md`, which has no byte
ceiling. This file has one, and the residue file next door has 431 B; that is why this block is
short and why the residue items are HERE rather than in `residue.md`. THAT PLACEMENT IS
DISPLACEMENT FORCED BY A FROZEN FILE, NOT A CHOICE.**

- **Closed 2026-08-04:** `gravito_p3b_count_derivation_a` (`PACKET-0041-count-derivation`).
  **Lane `substantive`. Depth 4.** Verdict **PASS-AS-FIXED** — qa **GREEN**, reviewer
  **fix-then-pass (6 enumerated items)**, re-gated. Base `099d7bf`; commits `a714d8a`, `f0e2fba`,
  `f785056` — **three, against a cap of two.** Metrics row appended and `--verify-git` VERIFIED at
  7 files / 967 insertions / 46 deletions (per-commit sums); `check-adoption.sh` exit **0**.
- **WHAT IT MADE TRUE.** `scan-controls.sh counts` binds a stated count to a live derivation. The
  record stores **no number and no line number**: the stated value is read out of live prose at
  every run, the derived value computed from the live source at every run, the position computed
  as a hint and stored nowhere. Two kinds only — `lines` (ERE that must begin `^`) and `files` (a
  name glob); **no line-count kind** and **no shell-command field**. It gates the `check` path too.
- **IT CAUGHT THE REAL DEFECT ON THE LIVE TREE, NOT ON A FIXTURE.** `tool_router.md:368` said
  **"nine"** against a derived **nineteen**; `counts` refused at exit 2 and the correction was made
  **by the derivation**, with the count table **byte-identical** across the fix.
- **THE CATEGORY CHANGE:** the packet's own claim moved from **declared in a header** to
  **asserted over the live table and red-driven in both directions.** qa's `M-NEW` mutant —
  restore `DC-0003`'s `14` — produces **2 failed**, so the assertion bites.
  **The reviewer's trajectory sentence, unsoftened:** *"still a scheme with a token population, but
  the scheme is now self-asserting rather than self-declaring."* Three records over two distinct
  counts. **It becomes infrastructure when the population grows past the counts its own author
  happened to notice**, and not before.
- **COVERAGE IS 3 OF 5 KNOWN INSTANCES, STATED HONESTLY.** (1) the router's stale streak — **CAUGHT
  LIVE**; (2) `wc -l` for a record count and (3) unanchored-vs-anchored grep — **caught
  structurally and on fixtures**, the `wc -l` answer being *inexpressible* rather than discouraged;
  **(4) the suite-total pair and (5) the transient-prose slips — NOT CAUGHT AND NOT TESTED.**
  **AND FIXING INSTANCE 4's GUARD REQUIRED PERFORMING INSTANCE 4 BY HAND** — 2190 -> 2220 -> 2228
  restated by hand in two files. Recorded above at the `Build/test command` bullet and carried
  here deliberately.
- **DERIVED AT THIS CLOSE, NOT REMEMBERED:** census **105** at base and HEAD; declared mismatches
  **22 anchored** (the unanchored grep gives **27** and is **wrong** — that is what `DC-0002`
  exists for); `gate` 81 / `execute` 8 / `advise` 15 / `observe` 1, identical at both ends;
  **re-authorisations 0**, by diffing every `(control, runtime_authority)` pair base-to-HEAD;
  anchors **12 resolved / 1 superseded / 0 violations**; derived counts **3 of 3 agree**.
- **TWO DEFECTS ESCAPED qa AND THE REVIEWER AND WERE CAUGHT AT THE CLOSE.** **(a) INSTANCE SEVEN,
  STILL OPEN:** word-cardinals persisted in `note` fields — `DC-0001`'s note carries `"nine"` and
  `nineteen`, and the tool's own `cnt_num` parses cardinals **to twenty as numbers**, so those
  words are numbers by the module's own definition. **The section 29d predicate cannot see them
  because its predicate is DIGIT-ONLY** — and that is **the reviewer's own round-1 list specifying
  a digit predicate, not the builder omitting work.** The builder implemented it broader than
  asked, extending it from `stated_content` to `note`. The gap is in the specification.
  **(b) FIXED IN THE CLOSE COMMIT:** `DC-0003`'s note stored a hand-written, underived line
  distance — *"four lines above it"* — which was also **FALSE and had never been true**: the sites
  are `MISMATCHES.md:30` and `:32`, **two** apart, traced back six revisions. **The distance was
  DROPPED, not corrected to "two"** — a corrected distance is still a stored position and `"two"`
  would persist another cardinal, which is the residual class (a) is about. The reasoning went
  into the `COUNT-BLOCK` header comment, where this module's history belongs: **in a comment, and
  not in a record.**
- **`DEFECT-0011-undeclared-active-packet` RECURRED, AND ITS LEDGER WAS UNDERCOUNTING BY THREE.**
  `f0e2fba` (declaration) landed at 22:36:46, **seven minutes after** `a714d8a` (implementation) at
  22:29:38; `bandwidth.active_packet_singleton` passed throughout because it refuses two
  declarations and permits zero. **And `build-os/registry/defect_classes.txt` carried exactly ONE
  occurrence of the class (`OCCURRENCE-0005`) while `build-os/packets/active_packet.md` documents
  further ones at `:758`, `:847` and `:1202` — a defect ledger undercounting its own recurrences by
  three, inside the packet whose thesis that is.** `OCCURRENCE-0019` is appended by this close; the
  ledger now reports **19 occurrences** and **4 classes recur**. The undercount is corrected as a
  LATER RECORD; `OCCURRENCE-0005` was not rewritten.
- **THE ANCHOR ARGUMENT, MADE BY EXECUTION.** Three line-pinned citations into
  `tests/control_registry_tests.sh` were repointed **by content** twice each — six repoint
  operations across two rounds (`:1189 -> :1444 -> :1526` and its two siblings) — while
  **`ANC-0012`, which covers the SAME FILE, absorbed every one of those moves with ZERO edits.**
  All resolve at close: `ANC-0012` at `:1526`, `ANC-0009` at `packet_metrics.tsv:17`, and the
  `evidence_refs` entry at `:1526` under `scan-controls.sh check` exit 0.
- **ONE ZERO-KILL MUTANT, DISPOSED OF AS UNOBSERVABLE BY CONSTRUCTION AND NOT AS UNTESTED.**
  `local pair` killed zero tests because `pair` is read **only inside the loop that assigns it**
  and **both call sites are top-level** — there is no reachable state in which its scope is
  observable. Deliberately distinguished from `PACKET-0040`'s two zero-kill mutants, which WERE
  observable and WERE unenforced; conflating the two categories is how a mutation score becomes
  decoration.
- **SECOND EYES: NONE.** `codex` not on `PATH`; review was same-model, single-provider.
  **TWENTIETH consecutive packet.** `tool_router.md:368` now states **twenty**, by derivation.
- **AND THE CLOSE ITSELF WAS CAUGHT BY A LIVE-TREE ASSERTION — RECORD IT, IT IS THE SAME LESSON.**
  The archivist first wrote the metrics row with `defects_escaped=2`, counting the two close-stage
  catches above as escapes. The suite refused at **2227 / 1**:
  `tests/speed_benchmark_tests.sh:319` asserts against the **LIVE store** that the rendered
  `defects_escaped` total is `-`, because **that column means a POST-CLOSE AUDIT found the defect**
  and no such audit has ever run here (`build-os/metrics/README.md`, in terms). **A close-stage
  catch is not a post-close escape**, and writing `2` there would have published a measurement for
  an audit nobody ran — the exact `0`-versus-`-` confusion the store exists to prevent, committed
  by the agent whose job is preventing it. The row had **not been committed**; it was removed from
  the uncommitted working copy (verified by `git status --porcelain` reporting the store
  byte-identical to `HEAD`) and re-recorded with the flag omitted. **No committed row was
  rewritten.** Had it been committed, the rule stands: a correction is a NEW row referencing the
  old one, never an edit.
- **RESIDUE, HELD HERE BECAUSE `residue.md` IS FROZEN AT 431 B AND UNROTATABLE AT EVERY LEGAL
  KEEP:** (a) instance 4 is unmechanisable by this design — a `mirror` kind would bind it and was
  deliberately NOT built, because no executed fixture justifies the kind; (b) the counts block is a
  gating control inside an already-registered file (`README.md` section 4's hole #1) with no census
  entry of its own — registering it moves the census off 105, so it is a one-entry follow-up packet
  and the operator's call; (c) instance seven is open; (d) the cardinal table stops at twenty and
  **receipt twenty-one must be a numeral**; (e) `count_derive`'s `files` arm expands `$3` unquoted —
  RECORDED AND DELIBERATELY NOT FIXED on the reviewer's explicit instruction; no `eval`, no
  injection path, no live record does it; (f) two defects were found by the packet's own tests
  rather than by review — an id regex too tight for fixture ids, and `rc=$?` read back after
  `if ! cmd`, which reports the status of the **negation**, **the exact trap the brief warns about,
  made in the same packet that quotes the warning**; (g) carried untouched: `residue.md` frozen,
  the rotation-sentinel spec revisions (i) and (ii), and `3a590ed`'s permanently false commit
  message.

## History — `gravito_rotation_sentinel_guard_a` — the last close, and the first GOVERNED rotation

**Everything below is the summary. The long form — the full provenance chain on the overstated
claim, the mutation results, the file-ownership manifest, and the two spec revisions routed to the
operator — is `build-os/receipts/gravito_rotation_sentinel_guard_a.md`, which has no byte ceiling.
This file has one, and the residue file next door has 431 B; that is why this block is short and
why the residue items are HERE.**

- **Closed 2026-08-03:** `gravito_rotation_sentinel_guard_a`
  (`PACKET-0040-rotation-sentinel-guard` — MINTED, collision-checked before the mint). Base
  `188472f` (the pushed tip); HEAD `275ea3a`; commits `3a590ed` + `89b261b` + `275ea3a`.
  **Verdict PASS-AS-FIXED** — qa **GREEN**; reviewer `fix-then-pass`, **4** items, all landed,
  plus qa's F1-F5; no stage 4. **Depth 3.**
- **THE DELIVERABLE: ROTATION IS NOW GOVERNED AT RUNTIME.** The tool derives the safe floor itself
  and refuses below it — 25 / 30 / 3 for residue, active_packet and this file — and prints it on
  every run, including the ones it allows. **Ceiling held exactly: 0 new tools, 0 new stores,
  0 new validators, 0 new suite files, 0 new primitives, 0 new controls, 0 new mutators.** The
  guard extends `build-os/maintenance/rotate-memory.mjs`.
- **ROTATION #2 EXECUTED UNDER THE GUARD:** this file **203642 -> 166605 B**, **37037 B
  reclaimed**, **20 -> 15** blocks.
  **AND THE PRE-REGISTRATION IS TREE-VERIFIABLE, WHICH CLOSES ROTATION #1's OPEN GAP** — rotation
  #1's ordering was testimony. Checked at this close: `3a590ed` **is a proven ancestor** of
  `89b261b`, and the pre-registration's declared `sourceSha256 91fa4548...` is **exactly**
  `sha256sum` of this file at `3a590ed`. The pre-registration names the bytes it was written
  against and git agrees.
- **`residue.md` IS FROZEN AND PROVABLY UNROTATABLE — DO NOT PLAN A WRITE TO IT.** **431 B**
  headroom; `minimum_safe_keep = 25` against **25** blocks; qa **executed all 25 keeps** and
  **every one exits 7**, with `bytes_to_reclaim` at keep 25 equal to **0**. Keep 25 is itself
  refused twice — C2 (unresolvable `DEFECT-0014`) and C7 (431 B against an 18702 B close budget).
  **IT WAS ALREADY UNROTATABLE IN TRUTH; WHAT CHANGED IS THAT THE UNSAFE ROTATION WHICH PREVIOUSLY
  EXITED 0 IS NOW REFUSED.** Strictly better even though the headroom did not move. **The remedies
  are OPERATOR ACTS, not build acts:** close `(o)` and `(S1)`, or move the still-open items to the
  head of the file. Until one of them happens, **no packet can record residue in the residue
  file** — a governance defect in its own right, and the reason the items below are in this file.
- **THE PACKET COMMITTED ITS OWN DEFECT CLASS WHILE DESCRIBING THE PACKET THAT CATCHES IT, AND THE
  COMMIT MESSAGE IS PERMANENTLY WRONG.** `3a590ed`'s message — and this repo's packet file until
  the fix round — claimed a positional scan *"derives 15 and archives the object at exit 0."* qa
  **executed the counterfactual**: a positional scan over the whole file **derives 25, IDENTICAL to
  the identity floor**, because two of the objects' markers sit in block 25 themselves; it refuses
  `--keep 10` identically. **THE TRUE, NARROWER CLAIM:** identity resolution makes `(ddd)` resolve
  to block **16** (its declaration) rather than **15** (where its marker sits), proven by a fixture
  and by mutation M1 killing 2 tests — its value is that it does not DEPEND on the accident that
  two other objects sit deeper. **The provenance chain is the finding:** builder wrote it -> the
  commit froze it -> **the orchestrator repeated it to the operator as a measured result** -> only
  an executed counterfactual caught it. **`3a590ed`'s message was NOT rewritten** (no amend, no
  rebase — rewriting it would destroy the ordering evidence above). The correction is a LATER
  RECORD. **Anyone reading git log alone will read the wrong claim. Do not soften this.**
- **TWO INVARIANTS WERE ENFORCED BY NOTHING, AND ONLY EXECUTED MUTATIONS FOUND THEM.** Before the
  fix round, disarming the sentinel's gate pins killed **0 of 2179** tests while being plainly
  observable — **and the rotation-#2 receipt claimed those pins were "verified BY IDENTITY", an
  unenforced claim sitting inside a receipt.** Inverting the deepest-to-shallowest declaration
  ordering also killed **0**. Both now killed: **M5 -> 151/3**, **M4 -> 152/2**, with the harm
  EXECUTED rather than argued — under M4's mutant `--keep 3` exits 0 and the deeper declaration
  lands in the archive; the shipped tool refuses at exit 7.
- **TWO WRONG DIGITS IN AN IMMUTABLE RECEIPT, CORRECTED AS LATER RECORDS, BODY NOT EDITED.** The
  rotation-#1 archive receipt said `26763` B conserved payload; the true figure is **26762**
  (`slice(0,26762)` is a byte-exact substring of residue at `3ec519b`; `slice(0,26763)` is not).
  It said batch 1 has 15 rows; it has **4** (9 total = 4+5). `89b261b`'s message carries the same
  26763. **Verified rather than promised:** the whole archive directory is byte-untouched across
  the fix round, and `residue.archive.md` is still blob `f475d53e`.
- **DEVIATIONS, STATED PLAINLY.** **(a) THREE COMMITS AGAINST THE `<=2` CAP — THE FIFTH CLOSE
  RUNNING.** Accepted deliberately on a stated rule: a false claim about the packet's own thesis
  left standing in the record is worse than a recorded cap breach; and the two earlier commits are
  descendants of the pushed tip whose ordering evidence squashing would destroy. **Breached, not
  excused.** **(b) SECOND EYES: NONE** — `codex` is not on PATH; review was same-model. **This is
  the NINETEENTH consecutive packet in that state, and `build-os/memory/tool_router.md` still says
  "nine"** — the router is stale by ten packets, unrepaired here as out of scope. **(c) 10 stale
  line-pinned citations repointed BY CONTENT**; the suite hit 2187/3 mid-round from the builder's
  OWN line shifts, caught and repaired by grepping each cited line's base text rather than guessing
  an offset — a recurring operating cost for any packet that edits its own citation targets.
  **(d) an indirect `eval` was introduced and then REMOVED**, reason recorded in-source; it did not
  ship.
- **ROUTED TO THE OPERATOR, RECORDED AND DELIBERATELY NOT BUILT — two spec revisions, each needing
  its own cut.** **(i) CROSS-FILE IDENTITY RESOLUTION:** the guard resolves identity within a
  single file, but memory files legitimately cite each other. `DEFECT-0014` and `(S1)` are declared
  in siblings, so C2 fires unresolvable and is **KEEP-INDEPENDENT — no `--keep` clears it**. The
  spec demanded C2 be a refusal, so this is a spec question, **not a builder error**.
  **(ii) DISTINGUISHING A LIVE MARKER FROM A QUOTED ONE:** a sentence quoting a status tag arms the
  scan exactly as the tag does, which is part of why `active_packet.md` floors at 30. **Stated
  honestly so nobody over-reads it: the reviewer judged floor 30 CORRECT on other grounds (a
  block-30 anchor), so fixing (ii) alone would NOT unfreeze that file.**
- **RESIDUE CARRIED FORWARD, HELD HERE BECAUSE THE RESIDUE FILE CANNOT ACCEPT A BYTE:** (1) the
  residue file is frozen at 431 B and unrotatable at every legal keep — operator remedy only;
  (2) spec revision (i), unbuilt; (3) spec revision (ii), unbuilt and NOT sufficient on its own;
  (4) the router's "nine" where the truth is nineteen; (5) five consecutive closes at 3 commits
  against a cap of 2 — the cap is either wrong or unenforced, and ruling that is the operator's;
  (6) `3a590ed`'s permanently false commit message, corrected only in later records;
  (7) line-pinned citations are expensive in packets that edit their own citation targets.
- **OPEN BOUNDARIES:** all three commits **and this close commit are LOCAL AND UNPUSHED**.
  `188472f` is the pushed tip and push was authorised **only through `188472f`**. No push, merge,
  PR, tag, deploy, secret, `git config`, amend or rebase was performed, and no such go was given.

## History — `gravito_governed_rotation_a` — the last close, and the first rotation

**Everything below is the summary. The long form — full derivations, the manifest, the three-way
instrument failure in detail — is `build-os/receipts/gravito_governed_rotation_a.md`, which has no
byte ceiling. This file does, and it is nearly out; that is why this block is short.**

- **Closed 2026-08-03:** `gravito_governed_rotation_a` (`PACKET-0039-governed-rotation` — MINTED,
  not reused, collision-checked before the mint and re-derived at close). Base `3ec519b`; HEAD
  `8115ac4`; commits `7bd152e` + `8115ac4`. **Verdict PASS-AS-FIXED** — qa **RED on one claim**
  (backlinks), **disposition right, warrant wrong**, GREEN on everything else; reviewer
  `fix-then-pass`, **10** items, all landed in `8115ac4`; no stage 4.
- **TWO COMMITS, AGAINST THE `<=2` CAP — THE FIRST TIME IN SIX CLOSES.** The four preceding closes
  each ran to three; the last called itself *the fifth consecutive close with this shape*.
  `git rev-list --count 3ec519b..HEAD` = **2**. **A measurement, not a compliment.**
  **ONE INSTRUMENT DISAGREED, AND THAT IS ITSELF A FINDING:** `bandwidth-check.sh check` reported
  `commits EXCEEDED — 6 commits since the declared base 9c740d7`, because it reads the FIRST
  `## Branch base` section of `build-os/packets/active_packet.md` and that section still named the
  **previous, already-closed** packet's base. **The instrument that measures the working contract
  was reading a field belonging to a closed packet.** Repaired in place here; it now reports
  `commits OK — 2 commit(s) since the declared base 3ec519b`. **AND A SECOND BLIND SPOT IN THE SAME
  TOOL, RULED AT THIS CLOSE:** it cannot tell a packet BUILD commit from the archivist CLOSE commit,
  so a compliant 2-commit packet reads **3, EXCEEDED** once its close is committed — as this one is.
  **NOT an amnesty for the four prior breaches**, which were build-commit counts of 3 and were real.
  **No fix built:** a reading error, not a safety failure. Same class as the branch-base defect
  above, and as `(hhhhhh)`: an instrument reading a field whose identity it never establishes.
- **ROTATION EXECUTED, FOR THE FIRST TIME IN THIS REPOSITORY'S HISTORY.** `residue.md`
  **218062 -> 191805 B** at `7bd152e`: from **13262 B OVER** the **204800 B** ceiling to
  **12995 B UNDER**; **29 -> 25** `^## ` blocks; `build-os/memory/archive/` **created**. **Archived
  `block_26`..`block_29` by stable id — 26762 B, every one a `## History` block, anchors (a)-(n) and
  nothing else.** Reclaimed **26257 B**; the **505 B** difference is the archive-pointer banner, so
  conservation is byte-exact once the banner is accounted for. **REVERSIBLE, AND PROVEN SO BY AN
  AGENT OTHER THAN THE ONE THAT PERFORMED IT:** the reviewer re-executed the restoration
  independently to `sha256 1977817f...`, exactly `git show 3ec519b:build-os/memory/residue.md |
  sha256sum`. `build-os/memory/archive/residue.archive.md` is blob `f475d53e` and **is load-bearing
  evidence — the restoration proof depends on its bytes, so it is excluded from every later
  writable set.**
- **THE CUT WAS DERIVED, NOT CHOSEN.** *Archive every block older than the oldest still-open item*;
  retention is a **PREFIX** and blocks run newest-first, so `--keep` = the index of the oldest block
  still holding an open item — **block 25** (`(S1)`, plus a flake still open), hence **`--keep 25`**;
  `--keep 24` was executed in scratch and **rejected**. Bounded by two **executed** constraints:
  `--keep 27` **refuses** at `EXIT.CEILING` (206496 B); `tests/build_os_maintenance_tests.sh`
  section 8 needs `keep >= 16`. Recorded as `(iiiiii)`. **THE QUEUED VALUE WAS NOT THE VALUE USED:**
  `--keep 10 --apply` was **defective as written** and, at 25 blocks, **actively destructive** — a
  prefix retention would archive blocks 11-25, taking `(ddd)`, `(S1)` and the still-open flake, the
  exact objects the packet proved protected. Now SUPERSEDED AND DEFECTIVE.
- **THE FINDING THAT MATTERS MOST — THE TRUE COUNT OF CITATION BREAKS THIS PACKET CAUSED IS ZERO,
  AND THREE INSTRUMENTS EACH REPORTED A DIFFERENT NON-ZERO ANSWER.** qa classified by **semantic
  identity** → **1**; the reviewer verified two sites **positionally** → **2**; the orchestrator
  swept **mechanically** → **31**. All three conflated **positional shift** with **semantic
  identity**: `pre[N] == live[N+10]` is mechanically true of **all 31** retained sites and says
  nothing about whether a citation ever named what it claims. **THE BUILDER FALSIFIED THE PREMISE
  AND REFUSED TO EXECUTE THE ROUTED REPOINT, WHICH IS THE ONLY REASON A KNOWINGLY FALSE CLAIM DID
  NOT ENTER MEMORY.** Both routed sites were **already semantically stale at `3ec519b`** when checked
  by content. Then the fact that explains it: **of the 11 line-pinned citations into `residue.md`,
  11 were already stale at base and 0 were correct — the insertions could not break a correct
  citation because there were none to break.** Stable identity:
  `DEFECT-0001-stale-line-reference` / *resolvability is not identity*, at `(hhhhhh)`. **THE RULE:**
  *a content match at a single commit tests RESOLVABILITY; only a cross-commit comparison against
  what the citing sentence CLAIMS tests IDENTITY.* **TWO AGGRAVATIONS, NOT SOFTENED:** it occurred
  **inside the instruments built to measure that very class**, and **the orchestrator committed it
  immediately after articulating the distinction and correcting qa for it** — stating a rule and
  violating it in the next action removes the excuse that the distinction was unavailable.
- **THE `--apply` ORDERING IS TESTIMONY, NOT TREE-VERIFIABLE, AND IS NOT SOFTENED.** The receipt's
  mtime `16:13:33` **postdated** the apply at `16:09:49` by 3m44s; **no artefact predates any run.**
  **Mitigation: proven reversibility. Remedy: pre-registration.** **THE EVIDENCE HAS ALREADY
  DECAYED:** that mtime now reads `17:21:44`, overwritten by the fix round's legitimate edit —
  **mtime is not durable evidence.**
- **`DEFECT-0011-undeclared-active-packet` — A FURTHER OCCURRENCE, AGGRAVATED BY SUBJECT MATTER.**
  Built, committed and gated while `active_packet.md` declared nothing in flight, so
  `bandwidth.active_packet_singleton` read zero in flight while a packet **about a memory file** was
  in flight. **The builder's reasoning — that declaring would move the `ANC-0003` site and turn
  `tests/memory_kernel_tests.sh` section 18 red — was assessed as AN EXCUSE, NOT A CONSTRAINT:** the
  line-count-neutral remedy was already executed **twice in that same file**, `ANC-0003` re-verified
  at `build-os/packets/active_packet.md:89` after each. Declared now, and **late**; the LOWER-bound
  remedy stays specified and unbuilt, `OCCURRENCE-0019` derived and **queued not minted**.
- **PROOF.** Suite **2140 passed / 0 failed** — twice in the packet, twice solo in the fix round,
  once more after every write in this close: exit 0, `grep -c '^  FAIL'` = 0, no failing `CHAINED`
  line. **The 20-line chained verdict vector is byte-identical across runs and identical to the
  pre-rotation baseline (`sha256 a69575133a461220...`) — the first rotation in this repository's
  history changed no assertion outcome anywhere in the tree.** **Commit-1 green in isolation at
  `7bd152e`, re-derived in a clean clone rather than taken from the brief: 2140 / 0**, same vector,
  so **`tests_added` is 0 and that is correct**. Census **105** / 46 / 88 / 0 / 0, declared
  mismatches **22** (anchored), gate **14** / execute **8**, occurrences **18**, **zero
  re-authorisations, no new control**; `scan-controls.sh check` and `anchors` both **exit 0**;
  ceiling held at **0 / 0 / 0 / 0**. **UI smoke: not applicable.**
- **TRAJECTORY, HONESTLY: ONE HAND-CRAFTED SAFE ROTATION, NOT YET A REPEATABLE CAPABILITY.**
  **Nothing executable asserts that the retained prefix contains every still-open item** —
  `(iiiiii)` is **prose**, and the scan is still MANUAL.
  **`DEFECT-0014-retention-order-assumed-not-verified` remains OPEN and names THIS FILE as the next
  one it bites.** **Second eyes NONE — EIGHTEENTH consecutive packet**, while
  `build-os/memory/tool_router.md:368` still self-reports the streak as **"nine"**; both figures
  carried on purpose. **The close brief itself carried stale figures** (213824 B / 9024 over,
  against an actual 218062 / 13262) — a restated count inside a brief whose own trap list says
  DERIVE every count.

## History — `gravito_current_state_reblock_a` — the last close

- **Closed 2026-08-03:** `gravito_current_state_reblock_a`
  (`PACKET-0038-current-state-reblock` — **MINTED, not reused**; collision-checked BEFORE the mint
  and **RE-DERIVED AT CLOSE by the archivist**, because that check has caught a bad id at four
  prior closes: at the packet's declaration `git log -S'PACKET-0038' --all --oneline` returned
  **0 commits** and `grep -rlF 'PACKET-0038' . --exclude-dir=.git` **0 files**; at this close the
  token resolves to **exactly this packet's own three commits** and to three live records — this
  file, `build-os/packets/active_packet.md` and `build-os/registry/defect_classes.txt`.
  **The id was free and the mint preceded the build.**)
  Base `9c740d7`; HEAD `d885657`; commits `06e9f1c` + `b41aa5d` + `d885657`.
  **Verdict PASS-AS-FIXED** — qa GREEN, reviewer `fix-then-pass` with **2** items, both closed in
  a bounded fix round together with **4 orchestrator-added corrections** (**6 total, prose only,
  2 files, +110/-6**), no stage 4.
  **Receipt:** `build-os/receipts/gravito_current_state_reblock_a.md`.
  **WHAT IT MADE TRUE:** this file went **3 -> 18** `^## ` blocks (`grep -c '^## '`), so
  `rotate-memory --file current_state --keep 10` went from `would archive 0` /
  `nothing — already rotated (no-op)` to **8 blocks / 66332 B** archivable, post-rotation retained
  **122367 B** against the **204800 B** ceiling. **THE LIVE FILE GOT BIGGER, NOT SMALLER**
  (185204 -> 188188 B, **+2984**, `wc -c`), so live headroom FELL by 2984 B; what changed is
  REACHABILITY, not size, and the two are different objects. **Sizes here are DERIVED, never
  quoted** — residue `(cccccc)` records why.
  **THE CRUX THE BRIEF GOT BACKWARDS — FOR THE SECOND PACKET RUNNING:** rotation retains a
  **PREFIX** (`blocks.slice(0, keepN)`) and archives the **TAIL**, so standing content must sit at
  the HEAD. The brief said the inverse; **had it been followed, all three gate-pinned literals
  would have been archived on the first rotation.** The builder DEMONSTRATED the correction on a
  5-block fixture, did not touch the tool, and reported it; **qa reproduced it independently** and
  drove the hazard RED at **95 passed / 9 failed** with a gate-pinned literal genuinely reaching
  the archive. Block 1 is now `## Standing truth — PROTECTED REGION` and holds **both** pinned
  literals that `tests/release_metadata_tests.sh` section 5 greps out of this file (the
  build/test-command marker and the last-closed-packet marker — **named descriptively HERE ON
  PURPOSE, because section 9 refuses if either LITERAL occurs outside the standing block, and
  a history entry quoting them would BE that second occurrence**) with **nothing outside block
  1 holding either**; the sweep over every legal `--keep` reports **18 rotated / 0 refused /
  0 leak / 0 drift, 29 files**.
  **THE FIX ROUND'S CENTRAL LESSON, BECAUSE IT IS REUSABLE:** two gates disagreed about
  "LINE-COUNT-NEUTRAL (15 lines in, 15 lines out)" **and both were right** — the edit replaced
  **5 lines with 5**, and the note REGION stayed **15 lines**. One sentence conflated two truly
  measured quantities. The fix states BOTH with their derivations and keeps the old wording
  visible as cited history: `OCCURRENCE-0018` is a **ledger of accuracy failures**, and a silent
  overwrite would leave no trace. **Swapping 15 -> 5 would have discarded a true fact to repair a
  false reading.**
  **PROOF:** suite **2140 passed / 0 failed**, twice at `b41aa5d` and twice solo in the fix round,
  chained vectors identical; re-derived once by the archivist at `d885657` — 2140/0, exit 0,
  `grep -c '^  FAIL'` = 0, no `CHAINED: N passed, 1 failed`. **Commit-1 green in isolation at
  `06e9f1c`: 2121 passed / 0 failed** in a clean clone, derived at close because the brief did not
  carry it; the **+19** is `tests/build_os_maintenance_tests.sh` going **85 -> 104**, every other
  chained suite **+0**. Census **105**, 46 surfaces, 88 load_bearing, 0 unregistered, 0 phantom,
  declared mismatches **22** (anchored `grep -c '^authority_mismatch: declared'`; the unanchored
  form returns 27 and the 5 extra are commentary), gate **14** / execute **8**, **zero
  re-authorisations and no new control**. `scan-controls.sh check` and `anchors` both exit 0
  (12 resolved / 1 superseded / 0 violations).
  **DEVIATIONS, NOT NORMALISED:** **3 commits against the `<=2` cap** — the same shape as the last
  three closes and the fifth consecutive breach, reported by `bandwidth-check.sh check` as
  `commits EXCEEDED ... ceiling 2 (advisory)`. **Rotation NOT applied**, `build-os/memory/archive/`
  still does not exist, **no ceiling raised** (`DEFAULT_MAX_BYTES` still `200 * 1024`).
  **Second eyes NONE — SEVENTEENTH consecutive packet**; `which codex` exits 1 and
  `build-os/memory/tool_router.md` still self-reports the streak as **"nine"**.

## History — `gravito_residue_reblock_a` — the last close

- **Closed 2026-08-03:** `gravito_residue_reblock_a`
  (`PACKET-0037-residue-reblock` — **MINTED, not reused**; collision-checked BEFORE the mint and
  **RE-DERIVED AT CLOSE by the archivist**, because that check has caught a bad id at four prior
  closes: `git grep -lF 'PACKET-0037' 2a3c070` exits **1** (0 files at base) and
  `git log -S'PACKET-0037' --all --oneline` returns **exactly this packet's own three commits**.
  **The id was free.**) Base `2a3c070`; HEAD `95e2c7b`; commits `bbdd85c` + `d888766` + `95e2c7b`.
  **Verdict PASS-AS-FIXED** — qa GREEN, reviewer `fix-then-pass`, all **7** items fixed and
  orchestrator-verified, no stage 4. **Receipt:** `build-os/receipts/gravito_residue_reblock_a.md`.
  **WHAT IT MADE TRUE:** `residue.md` went **3 -> 29** `^## ` blocks, so `rotate-memory` went from
  reclaiming **0 blocks / 0 B** to **19 blocks / 127142 B** at the shipped `keep=10`
  (post-rotation retained **85931 B** at the packet's HEAD). **THE BLOCKER IS CONVERTED, NOT
  CLEARED:** the live file is still above `DEFAULT_MAX_BYTES` and **rotation was NOT applied**
  (`build-os/memory/archive/` does not exist), because applying it relocates still-open items
  `(ddd)` and `(uuuu)` into an archive — an operator act. Residue `(bbbbbb)` queues it.
  **THE CRUX THE BRIEF GOT BACKWARDS, AND IT IS THE REASON THE PACKET MATTERED:** rotation retains
  a **PREFIX** (`blocks.slice(0, keepN)`) and archives the **TAIL**. The brief said the opposite
  and directed standing content to the bottom; **had it been followed, all three gate-pinned
  literals would have been archived on the first rotation** — the exact failure the packet
  existed to prevent. The builder DEMONSTRATED the correction on a fixture, did not touch the
  tool, and reported it; qa reproduced it independently and the orchestrator confirmed it from
  source. **Three readings, not two.** The protected region is block 1 and holds all three
  literals (`license model`, `no tags`, `single-platform`) with **nothing outside it holding
  them**, so it survives at every `keep >= 1` structurally rather than by exemption.
  **THE NEXT FILE IS NAMED, AND IT IS THIS ONE:** `build-os/memory/current_state.md` is in the
  identical dead end — **3 `^## ` blocks**, and `rotate-memory --file current_state --keep 10`
  reports `would archive 0` / `nothing — already rotated (no-op)` at **exit 0**. **The instrument
  reports this file as healthy right up until it is unfixable.** Re-blocking it is the staged next
  packet. **Sizes here are DERIVED, never quoted** (`wc -c`) — residue `(cccccc)` records why: the
  overage digit went stale inside a single packet.

## History — `gravito_measurement_integrity_a`

- **Previously closed:** `gravito_measurement_integrity_a`
  (`PACKET-0036-measurement-integrity` — **MINTED, not reused**, and the mint was
  **collision-checked BEFORE the mint by the builder and RE-DERIVED AT CLOSE by the archivist
  rather than accepted from the brief**, because that check has caught a bad id at three prior
  closes: `git log -S'PACKET-0036' --oneline a2648dc` returns **no commit**;
  `git grep -n 'PACKET-0036' a2648dc` returns **nothing**, so the token did not exist in the base
  tree; `git log -S'PACKET-0036' --all --oneline` returns **exactly two commits**, both this
  packet's own; and `git grep -ho 'PACKET-00[0-9][0-9]' HEAD | sort -u` shows a contiguous live
  band `PACKET-0001`..`PACKET-0036` whose highest prior allocation is `PACKET-0035`. **The id was
  free.**)
  **WHY IT EXISTED, AND IT IS NOT TEST HYGIENE:** the project's next frontier is **experience** —
  running `ranking -> selection -> execution -> outcome -> memory -> comparison` repeatedly. That
  loop's payload is **comparison**, and **a measurement substrate that manufactures false verdicts
  poisons the outcome store the executive will train on.** `DEFECT-0013` was closed **before** the
  loop starts accumulating outcomes. It also **repaired the previous packet's `DEFECT-0011`
  recurrence by declaring first**: `bandwidth` went **0 -> 1 packet in flight, ceiling 1**.
  **THE HEADLINE, AND IT IS THE PACKET'S MOST IMPORTANT OUTPUT: THE 6.26%-vs-15.70% DISCREPANCY
  WAS FIXTURE, NOT LOAD, AND NOT A DISAGREEMENT ABOUT WHAT WAS MEASURED.** qa's controlled A/B —
  same machine, same load, same code, **only the data store swapped** — measured a **17-row store**
  at 68,734 bytes emitted (3,198 past the 64 KiB buffer) failing **301/4000 = 7.53%**, and the
  **18-row store** at 72,147 bytes (6,611 past the buffer) failing **582/4000 = 14.55%**.
  **THE STORE GREW BY ONE ROW AND THE FAILURE RATE DOUBLED.** Generalisation, recorded because it
  is the strongest argument in the packet: **the rate of a latent non-determinism is a function of
  a data volume nobody is watching** — precisely the new guard's own declared blind spot. **A site
  measured at 0% today can flap tomorrow with no code change and no test turning red.**
  **THE FIX HELD UNDER EVERYTHING THROWN AT IT.** Shipped form 613/4000 = **15.33%** (qa) and
  628/4000 = 15.70% (builder, within 1 sigma); shipped under 4-way CPU load **1704/4000 =
  42.60%**; **fixed form 0/4000 quiet AND 0/4000 under 4-way load**; on an amplified 217,972-byte
  fixture, **100% before and 0/2000 after**. `pipefail` **stays on** and nothing turns it off
  (`grep -c 'set +o pipefail'` on that suite = **0**) — **the consumer was made to drain**:
  `any(){ awk 'BEGIN{r=1} {r=0} END{exit r}'; }`, with **no `exit` in a main rule**, so it reads to
  EOF under *any* awk. qa could not make it exit early with a 33.9 MB stream, a 64 MB single record
  with no newline, NUL bytes, or invalid UTF-8. **All three converted assertions were driven red
  and still fail correctly.**
  **AND THE FIX CARRIES NO AWK-IMPLEMENTATION DEPENDENCY** — at the empty-cell assertion the
  builder **removed the `exit`** rather than relying on mawk draining, so the guard's allow-list is
  keyed on **measured bytes** and not on which awk is installed. **A gawk or busybox image breaks
  neither.**
  **THE CLAIM THAT WAS FALSE, AND IT HAD ALREADY PROPAGATED.** Committed in **three live files**:
  *"It is ONE-DIRECTIONAL — it can manufacture a false FAIL and can never mask a real one."*
  **False as a class claim.** qa's counterexample is an assertion in
  `tests/build_os_maintenance_tests.sh` with **inverted polarity** —
  `find ... | grep -q . && no "..." || ok "..."` — where a SIGPIPE 141 routes to **`ok`**: **a
  false PASS masking a real failure.** At 270,890 bytes it returned non-zero **2000/2000**;
  draining, **0/2000**. Corrected verbatim in all three: **one-directionality is a property of the
  `&& ok || no` POLARITY, not of the class.** **THE BUILDER FOUND THE THIRD LIVE COPY ITSELF** —
  section 28 of `tests/build_os_tests.sh`, which the orchestrator's fix brief did not name —
  declining to correct two of three because that *"would have been `DEFECT-0003` in the same
  commit."*
  **THE PROPAGATION IS RECORDED HONESTLY BECAUSE THE ORCHESTRATOR PROPAGATED IT:** *"every green
  stands, the defect can only fake failure"* was relayed to the operator **twice** on the strength
  of the false claim. **The greens DO stand — but because that counterexample is unreachable
  (>64 KiB, ~1100+ leftover paths, in a directory the test expects EMPTY), not because the class
  cannot mask failures.** The site is also **invisible to the new guard**, its producer being
  `find`. **Recorded, not fixed** — outside this packet's ownership. `(qqqqq)`.
  **OTHER CORRECTED CLAIMS, ALL RE-MEASURED RATHER THAN RESTATED.** *"5/5"* was wrong and rested on
  n=5, which cannot distinguish 8% from 100%; at **N=200**: mawk `exit` **0/200**, `grep -q .`
  8.0%, `grep -m1 .` 9.5%, `head -1` 52.5%, `sed -n '1p;1q'` 100%. **The conclusion is unchanged
  and STRENGTHENED by the 0/200** — mawk's `exit` is uniquely non-lethal, so draining is right.
  The scanner scopes **45 of 54** `pipefail`-enabling files; of the nine outside its roots **four
  already carry `set -euo pipefail`**, so the case declared a FUTURE blind spot **is present
  TODAY** — corrected to *"already present, measured harmless"* (same 3 hits over all 54, all
  allow-listed). The allow-list is **FILE-granular**, so **the one file that shipped the defect is
  wholesale exempt from the guard against it** — demonstrated (a new racy line there is ALLOWED,
  the identical line in `tests/entitlement_tests.sh` is REPORTED), **left file-granular
  deliberately** because site-granularity reintroduces positional coupling, and now disclosed in
  the blind-spot list. **Two figures were WITHDRAWN rather than restated:** *"235 candidates"* ->
  258 derived, and *"~40 `sed ... | head -N`"* withdrawn entirely (13 strict / 87 all-`| head`,
  neither is 40); the load-bearing half holds and is derived — **0 killer pipelines in the 3
  scripts carrying `set -e` + `pipefail`.**
  **THE GUARD: 7 assertions, POWER DEMONSTRATED RATHER THAN ASSERTED.** qa independently stripped
  the exemption marker from the red-drive line in a clone and **the guard reported its own line**
  (suite 2101/2, exit 1) — the exemption is earned. **Its declared blind spots were all confirmed
  REAL by qa's sneak test**, five idioms walking straight past: `git log --oneline | grep -q .`; a
  function wrapping `cat`; `find /tmp -type f | grep -q .`;
  `cat "$BIG" | while read -r l; do break; done`; `grep -q . < <(emit_rows)`. **AND THE REPO CAUGHT
  qa** — its own *"sibling suite present but never chained"* control caught the planted file, an
  independent integrity control working in the wild.
  **THE EVIDENCE RULING, AND IT IS DOCTRINE: A SINGLE GREEN RUN IS AGAIN SUFFICIENT FOR THIS
  DEFECT, AND THE DOUBLED-RUN DISCIPLINE STAYS IN FORCE.** *What was measured is that one NAMED
  non-determinism is gone; what would license dropping the discipline is that NO UNNAMED one
  remains, and nothing here measures that.* **qa's criterion for retiring it** is not another
  assertion-level measurement but a **suite-level determinism measurement**: N>=200 consecutive
  full-suite runs at a fixed commit, quiet and under controlled load, with **zero variation in the
  per-suite PASS/FAIL VECTOR rather than in the total**, plus a per-assertion harness rerunning
  each assertion K times against frozen fixtures. **Until the invariant is "the verdict vector does
  not move", the doubled run is the only sampler in place. Retiring it is an operator act.**
  `(ttttt)`.
  **LINE-MOVEMENT DISCIPLINE, RECORDED AS A REUSABLE TECHNIQUE.**
  `tests/speed_benchmark_tests.sh` was held to a **strict net-zero line delta across the fix
  round** (712 in, 712 out) so all **nine** inbound citations still resolve to the same content.
  `tests/build_os_tests.sh` genuinely grew (978 -> 1106 -> 1161), so its **four** inbound registry
  citations were re-pointed **BY CONTENT**, and the registry suite's section 21 **re-derives that
  membership from the tree** and passes. **`ANC-0003` did not move at the fix round**, so no
  projection regeneration was needed there — it moved 15 -> 40 at the DECLARATION commit and was
  repaired the sanctioned way, **regenerated and never hand-edited**.
  **AN ORCHESTRATOR ERROR, RECORDED BECAUSE THE CLASS KEEPS PROVING IT IS NOT RETIRED.** While
  auditing the fix round the orchestrator grepped for the corrected statement **on a single line**
  and concluded it was missing from two of three files. **It was present in all three** — the
  statement **wraps across comment lines** (`NOT OF THE` / `# CLASS`) and the single-line pattern
  could not see it. That is the **line-wrapped enumeration** escape form, one of the five this tree
  already catalogued, **walked into while auditing a packet about false measurements**.
  **Verdict: PASS-AS-FIXED.** qa **GREEN**; the reviewer returned `fix-then-pass`, and every item
  was fixed in `aa0a7b3` and verified by the orchestrator rather than by opening a fourth gate
  stage. **Depth: 3 serial stages.**
  **Receipt:** `build-os/receipts/gravito_measurement_integrity_a.md`
  **Commits:** `0cdb3b7` (declaration) + `53b92d4` (fix, sweep, guard) + `aa0a7b3` (claim
  corrections), base `a2648dc` (re-verified at close: `git merge-base aa0a7b3 a2648dc` returns
  `a2648dc`). **None pushed.**
  **DEVIATION, RECORDED AND NOT NORMALISED: 3 commits against the `<=2` cap** — the third close in
  a row with this shape. The fix round landed as its own commit rather than amending commits the
  gates had already measured, which was the right trade: amending `53b92d4` would have invalidated
  the proof to satisfy a counting rule. The receipt's manifest is a **sequential attribution by
  role, not a disjoint partition** (`0cdb3b7`/`53b92d4` share 1 path, `53b92d4`/`aa0a7b3` share 7)
  and is **not a precedent for a fan-out**.
  **THE TWO DIFF CONVENTIONS DISAGREE AND BOTH ARE RECORDED, because a net-diff row was REFUSED at
  the last close:** `record-packet.sh --verify-git` computes **PER-COMMIT SUMS**, so the metrics
  row states **12 distinct paths / +768 / -96**
  (`git show --numstat --format='' 0cdb3b7 53b92d4 aa0a7b3`), while the **NET UNION DIFF**
  `git diff --numstat a2648dc aa0a7b3` is **12 / +699 / -27**. **The 69-line gap on both sides is
  exactly the overlap** — lines the fix round rewrote that the build commit had already written.
  **FINAL STATE AT `aa0a7b3`, ALL RE-DERIVED BY THE ARCHIVIST AT CLOSE:** suite **2103/0 exit 0**
  with `grep -c '^  FAIL'` = **0** and the **per-suite CHAINED verdict vector byte-identical across
  runs** — two SOLO full-capture runs by the builder at the committed tree plus three by qa;
  **Commit-1 green in isolation at `0cdb3b7`, 2096/0 in a fresh clone**; live gate
  `RELEASE_METADATA_LIVE_SUITE=1` **MATCH at 2103**; maintenance **144/0**; `scan-controls check`
  exit 0 with census **105**, **22** declared, **gate 14 / execute 8**, identical at base and HEAD,
  **0 `+control` lines and NO new control**; `scan-controls anchors` **12 resolved / 1 superseded /
  0 violations**; `memory-kernel reconcile` **1 projection, 0 divergent**; `evidence_refs`
  **372 -> 374 by derivation**; **zero re-authorisations, field-anchored.**
  **THE SEALED EXPERIMENT IS UNDISTURBED AND WAS RE-DERIVED, NOT RESTATED:** the S1 report digests
  to `e838284e2bba52628647d0c7ddd1ed258a7aab7cc391a5ac99992ad7584eb596` recomputed live at this
  close, `rank_of_selected: 1` still derives at exit 0, and `rank-candidates.sh` is the **same blob
  `5543ea8` at base and at HEAD**. **PRECISION, BECAUSE TWO DIGESTS ARE IN PLAY:** the report's own
  internal `ranking_digest` line reads `db96737e713b10d6...`; `e838284e...` is the sha256 of the
  **whole report**. A reader comparing the wrong one will conclude the seal broke when it did not.
  `signal_snapshots.tsv` and `decision_telemetry.tsv` have **zero diff**; `memory_events.tsv` has
  **zero diff** and the base file is a **byte-exact prefix** of HEAD's — **no rewritten row and no
  appended event**, by the packet or by this close.
  **AN ARCHIVIST OBSERVATION, RECORDED AT ITS TRUE SMALL WIDTH AND NOT AS A FINDING:** the **first**
  `scan-controls.sh check` of this close session reported `PHANTOM tests/gate_depth_tests.sh`, 1
  phantom entry, and REFUSED; **it did not reproduce in 14 further attempts — 8 quiet and 6 under
  4-way CPU load, all rc=0, all 0 phantom lines.** No rate is claimed and no mechanism is claimed.
  It is written down because this packet's own headline says a latent non-determinism's rate is a
  function of conditions nobody is watching, and the honest response to seeing one flicker is to
  record what was seen **and** what could not be reproduced. `(vvvvv)`.
  **AND THE PIPING TRAP THAT NEARLY MISREAD IT:** that first observation was taken through
  `... | tail -15; echo "EXIT=$?"`, which reports the exit status of **`tail`, not of the
  scanner** — the same "the shell told you about the wrong process" family this entire packet is
  about. **Do not read a gate's verdict through a pipe.**
  **AND THIS CLOSE MOVED THE VERY QUANTITY THE HEADLINE IDENTIFIES AS THE HIDDEN DRIVER.**
  Recording this packet appended the **nineteenth** row to `build-os/metrics/packet_metrics.tsv`:
  measured, **72,754 -> 73,992 bytes (+1,238)**, data rows **18 -> 19**. By arithmetic on qa's
  emitted-stream figure — arithmetic, **not** a fresh measurement — the margin past the 64 KiB
  buffer moves **6,611 -> about 7,849, up ~19% in one close**. Nothing is wrong now: the racing
  site drains and mawk's `exit` measured 0/200. **The point is the trend is monotonic and nothing
  watches it** — every close adds ~1.2 KB, there is no ceiling and no assertion, and **the new
  guard explicitly cannot see volume**. `(xxxxx)`.
  **AND THE CLOSE ITSELF HIT A CEILING, WHICH IS THE MOST ACTIONABLE THING ON THIS PAGE.**
  `residue.md` sits **3,608 B under a 204,800 B ceiling** at `aa0a7b3`; this close's first draft
  was **+7,934 B** and drove `build-os/maintenance/run-tests.sh` **RED on 4 subtests**. It was
  rewritten to **+3,466 B**, leaving **142 B of headroom**, and the argument was moved into the
  receipt. **`rotate-memory.sh` is NOT the escape:** it selects **by recency over BLOCKS** and its
  dry run reports that file as **3 blocks -> keep 3 newest, would archive 0**, so for any N >= 3 it
  reclaims **nothing** — and it **REFUSES at exit 3 once the file is already over the ceiling**, so
  **the preventative tool has a precondition that the failure it prevents violates.** **THE NEXT
  CLOSE HAS NO GREEN PATH** unless an operator re-blocks the file, raises `--max-bytes`
  deliberately, or moves standing content to `standing_gates.md`, which the rotator never reads.
  **A blind `--apply` is NOT safe** — selection is recency-only and that file carries literals other
  suites pin. `(yyyyy)`.
  **SECOND EYES: NONE — FOURTEENTH CONSECUTIVE PACKET.** The router's second-eyes row still says
  the absence was checked at *"the last nine packets"*; it is now **fourteen**, stale by five.
  **Nothing in the suite pins the literal**, which is why it drifts. Editing the router is a
  **routing act rather than bookkeeping**, so it is named and not applied. `(zz)`.
  **ROUTED TO THE OPERATOR, RECORDED AND NOT ACTED ON.** (1) **A closed receipt carrying a
  since-falsified claim has no pointer to its correction.** Three copies of the superseded
  one-directionality claim survive in **prior-packet records** — the cross-surface-memory-kernel
  receipt, `residue.md` and this file — and the builder correctly **did not rewrite them**, on the
  rule that a correction creates a later record rather than editing an earlier one. **This close
  upholds that rule and touched no prior receipt.** But a reader arriving there **reads the false
  sentence with nothing beside it**, and the memory kernel already has `supersedes` and
  `contradicts` relationship types **that receipts do not participate in**. Should receipts become
  first-class kernel objects reachable by a `contradicts` edge? **A design act on the kernel, not
  the archivist's to take.** `(wwwww)`. (2) **`(uuuuu)`** — the projection embeds a **resolved line
  number** inside a **byte-compared** artefact, so **every content-preserving edit above any
  anchored site ships red until a projection is regenerated**; the reviewer: *"a byte-compared
  artefact that embeds a resolved line number, inside the mechanism whose stated thesis is that
  line numbers are not identity, is self-contradictory."* **This packet paid that tax on its very
  first commit.** The tax compounds as anchor coverage grows past 3.5%.
  **PRE-EXISTING, OUT OF SCOPE, NOT ACTED ON:** the control registry's prose names one line of
  `tests/speed_benchmark_tests.sh` as a section-21 exclusion while the executable list in
  `tests/control_registry_tests.sh` names a different one. **No test reads the prose copy**, which
  is why it drifted.
  **OPEN, AND NOT THE ARCHIVIST'S TO CLOSE: nothing is pushed, merged, tagged, PR'd or deployed.**
  `0cdb3b7`, `53b92d4`, `aa0a7b3` and this close commit stay **local**, and **none of the three may
  be amended** — they are the commits the gates measured. `c2d97f8` remains the selection anchor
  of the still-intact prospective experiment.

## History — `gravito_cross_surface_memory_kernel_v0`

- **Previously closed:** `gravito_cross_surface_memory_kernel_v0`
  (`PACKET-0035-cross-surface-memory-kernel` — **MINTED, not reused**, and the mint was
  **collision-checked at close rather than accepted from the brief**: the live band runs
  `PACKET-0001`..`PACKET-0035`, the highest allocation predating this packet is `PACKET-0034`,
  `git log -S'PACKET-0035' --all` returns **exactly one commit** — this packet's own `d2c09c6` —
  and `git grep -l 'PACKET-0035' ea069a7` returns **nothing**. The token did not exist at the
  base.)
  **THE HEADLINE, AND IT WAS EXECUTED RATHER THAN DESIGNED: Claude closed work into Gravito
  memory, and ChatGPT consumed the governed project state without Sam copying the transcript.**
  The ledger PERFORMED the loop — `EVT-0023 HandoffCreated` (ACT-0002, surface
  `claude.cowork.session.ramhds`) -> `EVT-0024 ContextCompiled` (ACT-0003, surface
  `chatgpt.web.session.strategy-01`) -> `EVT-0025 HandoffAccepted`. **The surface changes between
  the first and second event and the actor changes with it**; that single transition is the whole
  claim. qa confirmed all six of the export's section-19 questions are answerable from
  `build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md` **ALONE**, swept the stores and found
  **no transcript text anywhere**, and — the part a skeptic needs — established the stores were
  **adapter-written rather than hand-authored**: a 25-row SHA-256 chain in which each digest is a
  function of its own fields and its predecessor's, `recorded_at` monotonic across a **9-second
  window**. Hand-authoring a valid 25-link chain inside nine seconds is not credible.
  **AND THE REFUSAL THE PACKET EXISTS FOR:** `PACKAGE-STALE` refuses a context package read
  `--as-current` when it binds source versions the project has left — *"It PARSES, every id in it
  RESOLVES, and it describes a state the project has left — resolvability is not identity"*,
  EXIT=2. **It is not a wall:** the same package read as history returns exit 0 with
  `state: STALE`. The refusal is scoped to the CLAIM, not to the package.
  **Verdict: PASS-AS-FIXED.** qa **GREEN**; the reviewer returned `fix-then-pass` on **6
  enumerated items**, all 6 fixed in `727de75` and verified by the orchestrator rather than by
  opening a fourth gate stage. **Depth: 3 serial stages.**
  **Receipt:** `build-os/receipts/gravito_cross_surface_memory_kernel_v0.md`
  **Commits:** `d2c09c6` (build) + `8ba368a` (residue) + `727de75` (fix round), base `ea069a7`
  (re-verified at close: `git merge-base 727de75 ea069a7` returns `ea069a7`). **None pushed.**
  **DEVIATION 1, RECORDED AND NOT NORMALISED — THE FIX ROUND REWROTE TWO COMMITTED EVENT ROWS IN
  PLACE.** The diff on `build-os/kernel/memory_events.tsv` across the residue and fix commits is
  **2 insertions / 2 deletions**: `EVT-0024` gained the package hash, and **`EVT-0025`'s own
  fields did not change at all while its digest changed anyway** — the signature of a **re-derived
  chain**. **That is precisely the operation this packet's own `EVENT-APPEND-ONLY` guard refuses,
  and whose red-drive is section 3 of its own suite**; it validates now only because the chain was
  re-derived, which is structurally identical to qa's Attack B, the laundering the round was
  fixing. Mitigating and recorded alongside rather than instead: the store is v0, created in this
  packet, consumed by nothing outside it, and both prior digests are recoverable from git.
  **Not a stage-4 defect. A deviation.** Residue `(ddddd)`.
  **DEVIATION 2 — THE PACKET WAS NEVER DECLARED, AND THE PROVENANCE IS THE ORCHESTRATOR, NOT THE
  BUILDER.** `active_packet.md` read `NOTHING IN FLIGHT` and described `PACKET-0029` for the
  entire life of the largest packet in the sequence, so
  **`bandwidth.active_packet_singleton` reported ZERO in flight while it was in flight.** The id
  was minted; the declaration and the in-flight record were not. **It is a RECURRENCE of the
  already-registered `DEFECT-0011-undeclared-active-packet` (`OCCURRENCE-0005`), whose own
  `could_have_been_prevented_by` names the unbuilt remedy — a lower bound on the same cardinality
  check.** Residue `(eeeee)`.
  **DEVIATION 3: 3 commits against the `<=2` cap**, the same shape as the previous close — the fix
  round landed as its own commit rather than amending commits the gates had already measured.
  **THE THREE COMMITS OVERLAP AND THE MANIFEST SAYS SO:** the build and fix commits share **10
  files**, the residue and fix commits share **1**; the manifest in the receipt is a **sequential
  attribution by role, not a disjoint partition**, which is legitimate for three serial passes by
  one agent and is **not a precedent for a fan-out**.
  **SECOND EYES: NONE — THIRTEENTH CONSECUTIVE PACKET**, re-verified at close (`which codex` exits
  1, no plugin directory). The router's second-eyes row still says *"the last nine"*; it is
  **thirteen**, now stale by four. Nothing pins the literal; editing the router is a **routing act
  rather than bookkeeping**, so it is named and not applied. `(zz)`.
  **`DEFECT-0013` IS THE FINDING THAT OUTRANKS THIS PACKET, AND IT IS NOT THIS PACKET'S FAULT.**
  The base tree is **non-deterministic and was so before this work began**:
  **6.26% per invocation on a quiet machine (501/8000)**, 3.65-7.75% across quiet batches,
  **19.97% under load**, 4.0% per standalone suite run. **Mechanism proven, not inferred:**
  `PIPESTATUS=[0 0 0 141 0]` — `awk` dies of SIGPIPE after emitting **68,734 bytes** past the
  64 KiB pipe buffer, `grep -q` exits 0, and `set -uo pipefail` promotes 141; the sibling
  pipelines emit **462 bytes in one write** and measured **0/2000**. **The error is
  ONE-DIRECTIONAL** — it can manufacture a false FAIL and never mask a real one, **so every prior
  green in this tree stands and every prior red on that one assertion is suspect.** **A SINGLE
  GREEN RUN IS NO LONGER SUFFICIENT EVIDENCE IN THIS TREE**, which is why the orchestrator ran the
  suite TWICE at `727de75`. **Sharpest consequence: the live-suite cross-check in
  `tests/release_metadata_tests.sh` compares a LIVE total against memory, so if the race fires
  there, the guard that keeps memory honest emits a FALSE STALENESS VERDICT.** Residue `(ccccc)`.
  **FINAL STATE AT `727de75`, ALL RE-DERIVED BY THE ARCHIVIST AT CLOSE FROM THE REGISTRY FILES AND
  THE LIVE TOOLS: 105 controls (`grep -c '^control: '`, a row count and never `wc -l`); 22
  declared mismatches, 0 violations; 12 anchors resolved / 1 superseded / 0 violations over 13
  records in 12 declared object types; 25 kernel events (`grep -c '^EVT-'`); crosswalk 105; README
  refs 372; `MUT-0010` added; suite 2096/0 exit 0 with zero `^  FAIL` and no chained failures,
  across TWO independent orchestrator runs plus six qa runs; Commit-1 green in isolation at
  `d2c09c6` in a fresh clone at 2082/0; `RELEASE_METADATA_LIVE_SUITE=1` MATCH at 2096; maintenance
  144/144 and 67/0; `scan-controls check` / `scan-controls anchors` / `scan-mutators check` /
  `check-adoption` / `memory-kernel validate` / `memory-kernel reconcile` all exit 0, reconcile
  reporting 1 projection and 0 divergent; ZERO re-authorisations, field-anchored.**
  **THE SEALED EXPERIMENT IS UNDISTURBED:** S1 digest `e838284e...`, `rank_of_selected: 1`,
  `rank-candidates.sh` blob `5543ea88` — all unchanged; `signal_snapshots.tsv` and
  `decision_telemetry.tsv` untouched by the packet and by this close.
  **OPEN, AND NOT THE ARCHIVIST'S TO CLOSE: nothing is pushed, merged, tagged, PR'd or deployed.**
  `d2c09c6`, `8ba368a`, `727de75` and this close commit stay **local**. `c2d97f8` remains the
  **selection anchor** and **may not be amended**, and neither may the three execution commits.

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
