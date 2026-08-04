# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Version `0.1.0` is deliberately pre-1.0: the system is **installable, not yet
API-stable**. File layouts, hook contracts, router row formats, and the
maintenance layer's on-disk shapes may change between minor versions without a
deprecation cycle. Pin a commit if you need stability.

## [Unreleased]

### In flight (not landed at the released commit)

- **A FIELD THAT PROMISED MORE THAN ITS PREDICATE DELIVERS IS RENAMED, NOT
  WIDENED — AND THE BREAK IS VERSIONED RATHER THAN ALIASED.** The sentinel's
  cross-file resolution reported `protected_in_owner`. That name claims the
  identity is protected in the file that owns it; the value only ever answered
  *"the owner carries a non-quoted marker naming it"*, which is strictly
  narrower. Owner-file protection also arrives through the owning-declaration
  path, which the marker scan cannot see — so `(S1)` and `(o)`, both anchored in
  `residue.md`'s own block 25 and both genuinely protected there, were reported
  `false`. The field is now `named_by_nonquoted_marker_in_owner` and the local is
  `namedByNonquotedMarkerInOwner`.

  **THE PREDICATE ITSELF IS UNCHANGED, DELIBERATELY.** Teaching the marker scan
  to see owning-declaration and structural protections would have made the old
  name true and **widened the demotion at the same time**, re-opening the
  fail-open the previous packet closed. The condition stays **sufficient, not
  necessary** — deliberately narrower than all possible owner-file protection —
  and **the gap fails closed**: an object protected at home in a way the
  predicate cannot see keeps its anchor in the quoting file instead of losing it.

  **NO COMPATIBILITY ALIAS.** `protected_in_owner` is removed from the emitted
  record rather than kept pointing at the same value, because an alias carrying
  the misleading name would reproduce the exact defect the rename exists to
  remove. Reports now carry `sentinel_report_schema` (**2**), so a consumer
  pinned to the old key gets `undefined` and a version numeral that says why —
  a loud break instead of a quiet wrong answer.

  **AND THE FIXTURE-C DIFFERENTIAL THAT WAS MISSING IS BUILT AND EXECUTED.** The
  old `*own-file*` check was not a differential at all: both roots yield
  `own-file` because the own-file path runs first and the collector keys on
  `id|kind|block`. Its message is softened to what it establishes, and a new
  section drives the claim on roots that differ from the safe root in **exactly
  one fact**, asserted by diff before anything is measured. Six things are
  demonstrated by execution, none by description: the four known vulnerable forms
  **archive a live, canonically declared, marked-non-consumable object at exit 0
  under the pre-fix implementation (`0d3a34f`, run verbatim)** and **refuse at
  exit 7 under the shipped one**; the genuinely safe demotion still works;
  deleting the owner's one marker line **restores the refusal**; a non-quoted
  marker naming the object in an **unrelated third governed file** really does
  protect it inbound and **still does not qualify**; and the reported field is
  **true in exactly the one root where the predicate holds and false in the other
  three**. The mirror of the earlier `1 -> 6` inbound proof is added too: with a
  byte-identical owner file, a **quoted** sibling marker leaves that file's floor
  at **1** where a bare one moved it to 6.

  **TWO SURVIVING OVERCLAIMS ARE RECONCILED.** *"which is exactly when the
  inbound protection fires"* is withdrawn from this changelog and from the test
  commentary; it was already corrected in the tool. It is false twice over: the
  inbound scan skips `fileName === spec.name`, so it can never protect an object
  in its own file, and the condition is sufficient rather than necessary.

  Suite **2314 passed**, 0 failed (+12 from the base `6454220`, all in
  `tests/build_os_maintenance_tests.sh` **191 → 203**; every other chained suite
  +0, confirmed by comparing the per-suite CHAINED vector across two solo runs).

- **THE ROTATION SENTINEL RESOLVES IDENTITY ACROSS THE GOVERNED MEMORY SET, AND
  THE REFUSAL IT WIDENS IS NOT THE ONE IT WEAKENS.** `SENTINEL-C2` treated every
  sibling-file reference as UNRESOLVED because resolution was single-file scoped
  and said so in terms: an object that lives elsewhere and is merely cited here
  "is indistinguishable, to this scan, from an object that has gone missing.
  Both refuse." C2 is keep-independent, so **no `--keep` cleared it** —
  `build-os/packets/active_packet.md` refused at every legal N while nothing was
  wrong with the record. Resolution is now cross-file over a **declared**
  `GOVERNED_IDENTITY_SET` (the three rotating memory files, plus
  `standing_gates.md` **declared and deliberately NOT read** — the tool's own
  shipped claim that it "never reads, writes or creates" that path is asserted
  verbatim in three places, so admitting it is an operator act, and the boundary
  is printed on every run instead of being crossed quietly).

  **THREE CONSEQUENCES, AND ONLY ONE OF THEM LOWERS ANYTHING.** A citation of a
  sibling-declared object resolves; a sibling's LIVE marker now **protects the
  declaring block in the owning file**, which the single-file scan did not do at
  all; and a structurally QUOTED marker naming only sibling-declared objects no
  longer anchors at the block doing the quoting. A new refusal `SENTINEL-C8`
  arrives with the widening — one stable identity, two governed files claiming
  it, refused rather than tie-broken — because that failure mode could not exist
  before. The declaration form was **tightened**, not widened: a BARE tag
  opening a bold bullet declares, a BACKTICKED tag cites, and the previously
  optional backtick was itself creating a second "canonical" declaration of
  `(ddd)`.

  **THE LIVE-VS-QUOTED TEST IS STRUCTURAL, BECAUSE THE VOCABULARY VERSION WAS
  MEASURED AND FAILED.** `PACKET-0042`'s guard keyed on six withdrawal-marker
  words on one line; probes found a live assertion containing `no longer`
  passing green and a reworded cap invisible entirely. This one reads fence
  state, blockquote depth, matched inline-code and quotation spans, the
  declaration form, and the `## ARCHIVED BATCH` heading the tool itself writes.

  **THAT CLAIM IS ABOUT THE DEMOTION AND NOT ABOUT THE GUARD AS A WHOLE, and the
  first draft of this entry did not say so.** It read "none of it consults a word
  list, and none of it can be defeated by rewording", which is true of the
  live-vs-quoted test and false of the surrounding guard: `SENTINEL_MARKERS` is
  still **seven fixed phrases**, so a marker written in words that are not on
  that list is invisible to the sentinel entirely. That limitation is
  **pre-existing and untouched here**, and it is stated rather than left to be
  inferred from a sentence that overstated its scope.

  **AND THE DEMOTION FAILED OPEN ONCE, IN THIS PACKET, BEFORE THE FIX ROUND.** It
  was first conditioned on every named identity being **declared** in another
  governed file — but a declaration is not a marker, and the inbound half skips
  quoted markers too, so a quoted live rule left the object protected in
  **neither** file. Four ordinary prose forms of a genuinely live rule, one of
  them a plain markdown blockquote, each ran to completion with a valid
  pre-registration and **archived a live, canonically declared,
  marked-non-consumable object at exit 0**; the pre-packet tool refused all four
  at exit 7. The condition is now that the identity be declared in exactly one
  other governed file **and named there by a non-quoted marker**. Both sides read
  one scan, so the two cannot drift. All four forms are driven as a red drive.

  **THAT CONDITION IS NOT *"exactly when the inbound protection fires"*, AND
  THAT WORDING IS WITHDRAWN HERE** — it survived this entry after being
  corrected in the tool, and it is false twice over. `inboundProtections` skips
  `fileName === spec.name`, so it can **never** protect an object in its own
  file; the own-file path does that. And the condition is **sufficient, not
  necessary**: `(S1)` is protected in `residue.md` by a marker naming it while
  the marker scan reports nothing for it, because that scan skips quoted markers
  and the own-file path does not. **The accurate claim: the condition is
  sufficient but deliberately narrower than all possible owner-file protection,
  and the gap fails closed.**

  **AND THE HONEST NEGATIVE RESULT.** `build-os/memory/residue.md` is still
  **not rotatable**, and cross-file resolution neither could nor did change
  that: its `minimum_safe_keep` is 25 of 25 blocks because `(o)` and `(S1)` are
  DECLARED in its own block 25 and are genuinely live. C2 was never the binding
  constraint there. Rotation #3 therefore relieves `current_state.md` instead,
  at `--keep 15` inside a window `[14, 16]` **executed at both bounds**.

  Suite **2302 passed**, 0 failed (+37 from the base `74575ee`, all in
  `tests/build_os_maintenance_tests.sh` **154 → 191** — +28 at the build commits
  and **+9 at the fix commit**; every other chained suite +0, confirmed by
  comparing the per-suite CHAINED vector across two solo runs).

- **TWO PROCESS RULES WITHDRAWN AS BROKEN, AND THE MACHINERY MOVED WITH THEM.**
  The working contract's `≤2 commits per packet` was **unsatisfiable**: any
  packet receiving `fix-then-pass` must produce a third commit, because the
  first two are the tree the gates measured and amending them is forbidden. The
  rule and the fix-round mechanic could not both be satisfied, and the breach
  had been recorded six consecutive times as though it were a lapse of
  discipline. It is replaced by **≤2 build commits plus at most 1 fix commit**,
  with the fix commit defined by what it may NOT do — no new subsystem, no
  expansion of the objective, no unrelated governance, no rewriting of the
  measured build commits, no concealment that correction was required — and
  **explicitly not recorded as a doctrine breach.**

  The depth budget said a fourth serial stage meant installments or a mis-cut
  packet. That left **no legal depth at all** for a fix list arriving complete,
  in one installment, against a correctly scoped packet, whose contents the
  contract's own re-review rules forbid confirming narrowly — so a packet that
  had done everything right was pushed into recording a defect it had not
  committed. A third legitimate cause is added, `mandatory_full_regate`,
  **conjunctive over five stated conditions** and announced by name; depth 4
  remains a defect for incomplete enumeration, installments, avoidable scope
  growth, or a packet that should have been split.

  **THIS IS WHY IT WAS A PACKET AND NOT A TEXT EDIT.** The first attempt was a
  direct edit of the prose and it broke **4 assertions across 3 suites** — the
  doctrine is enforced by machinery, not merely written. `CEILING_COMMITS` moves
  2 → 3 in `build-os/tools/bandwidth-check.sh`, and **the cited constant now
  states what the number does not mean**: this tool counts a RANGE and cannot
  partition it, so 3 is a permitted MAXIMUM and never a licence for three build
  commits — the build/fix split is enforced by the reviewer, not by any number
  this tool can produce. The `bandwidth_tests.sh` red drive was **re-pointed to
  the new boundary rather than deleted**, and both sides of it are now driven (3
  inside, 4 over). The tool edit is **line-count-neutral**, so all ten registry
  citations into it keep their positions — verified by content, not by offset
  arithmetic; the five `suite.bandwidth` citations into the test file that DID
  move were repointed by content.

  **AND THE PACKET'S OWN THESIS CAUGHT IT OUT.** The withdrawal moved the
  contract and its global mirror but left `README.md` — under a heading reading
  "Safety gates (non-negotiable)" — still asserting `≤2 commits per packet`, and
  a green suite of 2242 assertions said nothing, because **nothing guarded the
  commit-budget rule across files at all**. The depth block had a three-way
  mirror; the commit budget had none. The fix round closes that with a
  cross-surface guard in `tests/gate_depth_tests.sh`, and it compares the RULE
  rather than the prose: the five governing surfaces (`CLAUDE.md`,
  `build-os/global-claude-md.md`, `README.md`, `build-os/tools/bandwidth-check.sh`,
  `build-os/registry/control_registry.txt`) must each yield the same normalised
  tuple **(build ceiling, fix ceiling) = (2, 1)** — extracted from whatever
  wording each uses, since they state it at five different lengths for five
  audiences — and none may still ASSERT the withdrawn untyped cap, which may be
  quoted only alongside its withdrawal marker.

  Suite **2265 passed**, 0 failed (+37 from the packet's base: `tests/gate_depth_tests.sh`
  **79 → 113** and `tests/bandwidth_tests.sh` **41 → 44**; every other chained
  suite +0, confirmed by comparing the per-suite CHAINED vector across two solo
  runs). Nine derived restatements of `≤2 commits` — the router, the agent
  definitions, ONBOARDING, the corpus, the crosswalks and the templates — remain
  **surfaced as a follow-up packet and deliberately not touched**; they are
  summaries of the contract, not the contract. They are now **enumerated by name
  inside the guard itself**, so the debt is a declared register that fails when a
  member stops resolving, rather than a sentence in a changelog.

- **COUNT DERIVATION IS NOW MECHANICAL RATHER THAN DISCIPLINARY.** The doctrine
  "DERIVE every count; never restate one" was written in four artefacts and
  enforced by discipline alone, and discipline kept failing.
  `build-os/memory/tool_router.md` — the file that tracks review discipline —
  stated that a second-eyes provider had been absent "at each of the last
  **nine** packets" while the true streak was **nineteen**, understating the gap
  by more than half, and the entire green suite was silent about it.
  `scan-controls.sh counts` closes that: a **COUNT-TABLE** of eight-field
  records, each naming WHERE a count is stated and HOW it is derived, reconciled
  at exit 2 on disagreement, and gating the `check` path as well.

  **THE RECORD STORES NO NUMBER**, which is the design and not a flourish. The
  stated value is read out of the live prose at every run and the derived value
  is computed from the live source at every run, so the table cannot become a
  third stale copy of the truth it polices — the same discipline the anchor
  table applies to positions, where an anchor stores no line number. Resolution
  is **by content**: the stated literal must occur exactly once, and the line
  number is a computed navigation hint. **Two derivation kinds and no third:**
  `lines` (an ERE that **must** be anchored with `^`) and `files` (a name glob).
  There is deliberately **no line-count kind**, so the `wc -l`-for-a-record-count
  error is not discouraged, it is inexpressible; and there is **no shell-command
  field**, so the table is not a code-execution surface. Everything it cannot
  read fails closed — an unreadable stated value, an unresolvable or ambiguous
  site, an unknown kind, and a derivation that produces **zero even when a stated
  zero agrees with it**, because a broken derivation and an empty one are
  indistinguishable from outside.

  **No new tool, no new store, no new suite file, no new census control**: the
  block lives inside `build-os/registry/scan-controls.sh`, beside the anchor
  table it is modelled on, and the tests are §29 of the existing
  `tests/control_registry_tests.sh`. Three live records: the router's
  second-eyes streak (bound to the receipt store), and **both** restatements of
  the declared-mismatch total in `MISMATCHES.md`, four lines apart — duplicate
  semantic truth is not fixed by deleting one copy but by binding every copy to
  the one source. The router's "nine" was corrected to **nineteen** by
  derivation, not by hand.

  **THE REVIEW ROUND FOUND INSTANCE SIX INSIDE THE FIX ITSELF, AND IT IS WORTH
  MORE THAN THE FEATURE.** `DC-0003` shipped with the stated_content
  `**14 of {N} entries carrying` — a persisted, underived count sitting inside
  the store whose headline claim is that it holds none. It was fail-closed
  (raising the `14` yields `COUNT-UNRESOLVED` at exit 2, never a wrong pass) and
  it was still the very defect, one level up, found by review rather than by the
  guard. The `14` was gratuitous; `of {N} entries carrying` names the same unique
  site. The claim is now **asserted over the live table** rather than declared in
  a header: no record persists a digit in its `stated_content` or its `note`,
  driven in both directions — clean on the table as it stands, and biting on the
  table as it shipped.

  Also closed in that round: a malformed ERE was swallowed by `|| true` and
  produced a finding that compared against an **empty** derived value —
  fail-closed and unreadable at once — now refused as `COUNT-SOURCE` with the
  pattern named; and a missing `local`.

  Suite **2228 passed**, 0 failed (+38, all of it
  `tests/control_registry_tests.sh`, which goes **130 → 168**; every other
  chained suite +0). Six stale line-pinned citations into
  `control_registry_tests.sh` were repointed **by content** across two rounds;
  the one anchor covering that file absorbed every one of those moves with no
  edit at all, which is the anchor scheme paying for itself.

  **THE IRONY IS RECORDED RATHER THAN SMOOTHED OVER:** adding those assertions
  moved the total off 2220, and updating it meant hand-editing the same literal
  in `CHANGELOG.md` and `build-os/memory/current_state.md` — **instance 4,
  performed by hand, in order to ship the guard against it.** That pair remains
  the one instance this design cannot reach, because the number is produced by
  running the suite and no static derivation reaches a process.

- **ROTATION IS NOW A GOVERNED RUNTIME CAPABILITY RATHER THAN A GOVERNED ACT.**
  The first governed rotation of this repository's memory was safe because a
  human read the open-item markers, found the oldest, and hand-derived
  `--keep 25`. That rule lived in prose and enforced nothing;
  `DEFECT-0014-retention-order-assumed-not-verified` was the standing record of
  the gap. `build-os/maintenance/rotate-memory.mjs` now derives it itself:

      minimum_safe_keep = max( block position of every protected or still-open object )

  and REFUSES any lower `--keep` at a new exit code **7** (`EXIT.SENTINEL`),
  before a byte moves. **N is never auto-raised** — auto-correcting a dangerous
  request is how a guard becomes invisible. **No new tool, no new store, no new
  validator, no new suite file**: the guard lives beside the routing it guards.

  **IT RESOLVES BY IDENTITY, AND THAT IS NOT A DETAIL.** A protection marker is a
  sentence *about* an object, not the object. In this repository's `residue.md`
  the marker `IS NOT CONSUMED AND MUST NOT BE MARKED SO` for `(ddd)` sits in
  **block 15** while `(ddd)` is DECLARED in **block 16**. A scan that trusts
  where the marker sits derives 15, permits `--keep 15`, and archives the object
  it was built to protect — at exit 0. Objects are resolved through the stable id
  families (`DECISION-`, `DEFECT-`, `OCCURRENCE-`, `PACKET-`,
  `SIGNAL-SNAPSHOT-`, `ANC-`, `EV-`, `DISP-`, `MUT-`, and the kernel
  `ACT/ART/CTX/EVT/HOF/NS/OBJ/REL-NNNN` families) plus this tree's letter-tag
  family, and **an identity a marker names that no block declares is a REFUSAL,
  not a skip**.

  **THE RED-DRIVEN FIXTURE WAS ALREADY IN THE TREE.** `--keep 10 --apply` sat
  queued in `residue.md` as a pending action; against today's 25-block file it
  archives blocks 11–25, including block 16 (`(ddd)`) and block 25 (`(S1)` and
  the flake marked `[STILL OPEN AND STILL UNDIAGNOSABLE]`). It now exits 7 and
  writes nothing. **Seven refusal conditions, each driven by a fixture that fires
  it**: keep below the floor; an unresolvable identity; an open object that would
  move to the archive; a block map that disagrees with the file; an `--apply`
  that was not pre-registered; restoration that cannot be proved; and a
  projected headroom that cannot absorb the packet's own close. The close budget
  defaults to **18,702 B** — **derived, not invented**: the largest single-commit
  growth any `FILE_SPECS` file has ever taken here (`current_state.md` at
  `2a3c070`) — and is overridable with `--close-budget`.

  **A SECOND INDEPENDENT INSTRUMENT NOW SEES THE INTERLEAVED CUT.** The
  sentinel's condition 6 re-derives `retained ++ archived === original` without
  consulting routing-reconstruction check (1d), so the mutation test that used
  to assert "with (1d) disabled no other guard fires" is split into the two
  statements that are true: with (1d) disabled the sentinel catches it at exit 7,
  and only with **both** disabled does the cut run to completion at exit 0.

  **TWO CORRECTIONS THE FIX ROUND OWES, BECAUSE THE CLAIM ABOVE WAS FIRST
  WRITTEN TOO WIDE.** (1) A purely POSITIONAL scan over the whole `residue.md`
  also derives a floor of **25**, because the markers at `:2333`/`:2339` sit in
  block 25 themselves — so on THIS tree a positional scan refuses `--keep 10`
  identically and does not archive `(ddd)` at exit 0. The supported claim is the
  narrower one: identity resolution is what makes `(ddd)` resolve to block 16
  rather than 15. The counterfactual was executed by qa, not by the author who
  asserted it — the packet's own defect class, committed inside the guard built
  to prevent it. (2) Rotation #1's conserved payload is **26762 B**, not 26763;
  the larger figure is the archive body region including a trailing newline that
  is not source content.

  **TWO INVARIANTS WERE UNENFORCED AND ARE NOW CLOSED.** Disarming
  `SENTINEL_GATE_PINS` killed **0 of 2179** tests despite being plainly
  observable (resolved objects 18 → 15 on `residue.md`, 4 → 2 on
  `current_state.md`; pins 3 → 0 and 2 → 0) — and a rotation receipt was
  meanwhile claiming those pins were "verified BY IDENTITY". Inverting the
  declaration index from DEEPEST to SHALLOWEST also killed **0**, inert only
  until a marker names a doubly-declared id, which `DEFECT-0013` in
  `active_packet.md` already is. Both mutants now die (3 and 2 failures).

  **KNOWN LIMITATION, STATED WHERE THE RULE IS STATED:** identity resolution is
  SINGLE-FILE SCOPED, so an object living in another memory file or a registry
  and merely CITED here is indistinguishable from a missing one and both refuse.
  That is what produces both live condition-2 hits. A cross-file resolver is a
  spec revision, recorded and NOT built.

  Suite **2190 passed**, 0 failed (+50, all of it
  `tests/build_os_maintenance_tests.sh`, which goes **104 → 154**; every other
  chained suite +0). The installed maintenance suite goes **125 → 145**.
  **No new census control**; 10 stale line-pinned citations into
  `rotate-memory.mjs` and `build_os_maintenance_tests.sh` were repointed **by
  content**, never by offset. The packet used **3 commits against a cap of 2**;
  the breach is recorded plainly in `build-os/packets/active_packet.md` — the
  two earlier commits carry the pre-registration ordering proof and could not be
  squashed or amended without destroying it.

- **`build-os/memory/current_state.md` was re-blocked BEFORE it ran out of
  headroom — the same repair as `residue.md`, taken prospectively.** The file
  measured **185,204 B** against the **204,800 B** ceiling
  `rotate-memory.test.mjs` enforces — **19,596 B of headroom**, derived with
  `wc -c` — while carrying exactly **three** `^## ` blocks, so
  `rotate-memory.mjs`'s `routeSegments` retained `blocks.slice(0, 10)` = all
  three at the shipped keep and archived **0 blocks / 0 bytes** at **exit 0**,
  printing `already rotated (no-op)`.

  **THE DIFFERENCE FROM THE `residue.md` CASE IS THE WHOLE POINT, AND IT IS
  ARITHMETIC RATHER THAN JUDGEMENT.** `residue.md` was found at **142 B** of
  headroom and the migration cost **+3,236 B**, so the repair had to breach the
  ceiling to happen at all, and the file is still over it today. `rotate-memory`
  **REFUSES at exit 3 (`EXIT.CEILING`) once a file is already over**, which is a
  precondition the failure it prevents violates — so the last moment the tool can
  act is strictly *before* the breach. Here the migration cost **+2,984 B**
  (185,204 → **188,188 B**), leaving **16,612 B** still spare and the tool still
  able to act. Doing it now cost nothing that doing it later would have cost.

  **THE STRUCTURE, AND THE HAZARD IT REMOVED.** The old file's LAST block was
  `## Stable facts (slow-changing)` — standing content, sitting in the region
  rotation archives first. The new order is **standing truth (block 1), then
  active state, then history newest-first**, cut at the file's own per-packet era
  markers and never across one. Both literals
  `tests/release_metadata_tests.sh` section 5 greps out of this file are read
  with `head -n1`, i.e. the FIRST occurrence, so an archived first occurrence
  would silently re-point that guard; both now live in block 1 and **nowhere
  else**, which `tests/build_os_maintenance_tests.sh` section 9 asserts.

  **THE PROTECTION IS POSITIONAL AND IS PROVEN BY EXECUTION, NOT ARGUED.**
  `--keep` is validated `>= 1` and `routeSegments(segments, keepN)` takes no other
  input, so the whole routing domain is `1..18`; section 9 rotates a scratch copy
  at **every one of those 18 keeps with `--apply`** and finds **18 rotated, 0
  refused, 0 gate-pinned literals reaching the archive, and block 1 byte-identical
  at all 18**. **NO PATTERN OF PROTECTION WAS ADDED TO THE TOOL** and none is
  claimed for it.

  **ROTATION WAS NOT APPLIED.** `--dry-run` only, exit code captured directly off
  the tool: **18 blocks → keep 10, archive 8**, reclaiming **66,332 B**, live
  **188,188 → 122,367 B**, `conservation : OK (121,856 B live + 66,332 B archived
  = 188,188 B original, byte-exact)`. Applying it is a separate operator packet;
  `build-os/memory/archive/` still does not exist.

  **CONSERVATION WAS PROVED IN THE OTHER DIRECTION TOO** — the original file is
  reconstructed **byte-exact** from the new one by putting the migrated segments
  back into their original order, with a delta that is enumerated rather than
  summarised: three `^## ` headings demoted or renamed (`## Project` and
  `## Stable facts (slow-changing)` demoted to `### `, `## Where we are`
  renamed); **one marker RENAMED IN PLACE — not moved** —
  `**Last closed packet:**` → `**Closed 2026-08-03:**` at `current_state.md:476`,
  its 18-line entry left **byte-identical** where it was written (`cmp` clean,
  base `:243-260` vs HEAD `:477-494`); a **new 4-line stub** in block 1 under a
  new `### Last close` heading, pointing at that entry, so the literal
  `**Last closed packet:**` still occurs **exactly once** in the file; the
  suite-total claim rewritten `2121 → 2140`; and **21 added lines** of
  orientation note.

  **THE EARLIER WORDING SAID "one marker moved into block 1", AND A RENAME PLUS A
  STUB IS NOT A MOVE.** The substance was right — entry whole, literal present
  once — but the mechanism was mis-described, and **the 4 stub lines and their
  `### Last close` heading fall OUTSIDE the "21 added lines" figure**, which
  counts the orientation note alone. The full multiset delta is derived rather
  than restated —
  `diff <(sort <base>) <(sort <head>) | grep '^>' | grep -vc '^> *$'` → **57**
  added non-blank lines and **11** removed — and it partitions exactly:
  **21** orientation note + **18** new `^## ` block headings + **3** `### `
  headings (`Project`, `Stable facts`, `Last close`) + **3** stub continuation
  lines + **11** suite-total-claim lines + **1** renamed marker = **57**.

  Suite **2140 passed**, 0 failed (+19, all of it
  `tests/build_os_maintenance_tests.sh` §9, which goes **85 → 104**; every other
  chained suite +0). Census **held at 105**, declared mismatches **held at 22**,
  gate-on-advise **14**, **no new control**.

  **THE MISMATCH COUNT IS ANCHORED, BECAUSE THE UNANCHORED GREP DISAGREES WITH
  THE TOOL AND THE TOOL IS RIGHT.**
  `grep -c 'authority_mismatch: declared' build-os/registry/control_registry.txt`
  returns **27**; `grep -c '^authority_mismatch: declared'` on the same file
  returns **22**, which is what `scan-controls.sh` reports. The five-line gap is
  **commentary, not entries** — `control_registry.txt:24`, `:1370`, `:1500`,
  `:1551` and `:1886` quote the field inside a header or a `notes:` body, and
  only a line-initial occurrence is a stanza field. **Cite the anchored form.**
  Gate-on-advise derives from splitting those same 22 by `runtime_authority`:
  `awk -F': ' '/^runtime_authority: /{ra=$2} /^authority_mismatch: declared/{n[ra]++} END{for(k in n) print k, n[k]}'`
  → **gate 14, execute 8**, identical at base `9c740d7` and at HEAD.

  Two `evidence_refs` line numbers were
  repointed — `suite.build_os_maintenance` and `OCCURRENCE-0016`, both citing this
  suite's own trailing `RESULT`/exit lines, `:639/:640 → :846/:847` — recorded as
  `OCCURRENCE-0018` of `DEFECT-0001-stale-line-reference`. The four other
  citations into that file (`:88`, `:193`, `:295`, `:414`) were **prevented rather
  than repaired**: the header note was rewritten line-count-neutral —
  **the edit replaced 5 lines with 5 lines, leaving the note region unchanged at
  15 lines, so no line below it moved.** Both figures are measured and an earlier
  wording ("15 lines in, 15 lines out") conflated them: **5** is what the edit
  REPLACED (`diff` over the region: 5 `<`, 5 `>`), **15** is the SIZE of the note
  region on both sides (`sed -n '10,24p' … | wc -l` = 15 at base and at HEAD).
  The consequence is the load-bearing part and it is verified independently:
  lines **25..635 are byte-identical** base-to-HEAD (`cmp` clean), so `:88`,
  `:193`, `:295` and `:414` still name the same content.

  **QUEUED, NOT FIXED — A PRE-EXISTING STALE POINTER THIS MIGRATION MOVED
  FURTHER, AND IT PREDATES THIS PACKET.** `build-os/memory/residue.md:582`
  carries the line-pinned pointer `build-os/memory/current_state.md:286`. It was
  **valid at `2a3c070`** — `:286` then sat inside the cited claim — was
  **already stale at `95e2c7b`**, which is *before* this packet's base `9c740d7`
  (at `95e2c7b` the claim's own anchor line is `:293`, seven lines below the
  pointer), and this migration carried the content further still. **The claim
  itself is conserved:** the anchor `counterexample is unreachable` occurs
  **exactly once** at base and **exactly once** at HEAD
  (`grep -c 'counterexample is unreachable'` → 1 both sides), and the block that
  contains it is byte-identical across the migration —
  `cmp <(git show 2a3c070:…current_state.md | sed -n '282,288p') <(sed -n '557,563p' …)`
  is clean, a constant offset of **+275**, so `2a3c070:286` is **HEAD `:561`**.
  **It is NOT repointed here:** `residue.md` is a declared byte-identical
  boundary for this packet, so touching it is out of scope. Queued with the
  measurement above so the next packet repoints it **by content**, not by
  shifting a digit.

  **THE LONG-TERM DEBT THIS PACKET CREATED IS DUPLICATION, NOT POSITION —
  RECORDED, DELIBERATELY NOT BUILT.** `tests/build_os_maintenance_tests.sh` §9
  is a **structural clone of §8**: §8 spans `:430-637` (**208 lines**) and §9
  spans `:638-847` (**210 lines**), same shape, literals swapped, hand-maintained
  — the cost is **O(files)**, and a third rotating file would pay it a third
  time. **`build-os/packets/active_packet.md` is that third file and has no such
  section at all** (`grep -c '^## '` → **20** blocks, so it is currently fine and
  nothing checks that it stays fine). The pattern does **not** generalise for
  free. The follow-up is a choice, not a defect: either abstract §8/§9 into one
  helper parameterised by *(file, standing-heading prefix, pinned literals)*, or
  accept the duplication deliberately and add coverage for `active_packet.md`.

  **TWO DIFFERENT PRESERVATION MECHANISMS, AND THEY MUST NOT BE CONFLATED.**
  `build-os/maintenance/rotate-memory.mjs:49` states the doctrine
  *"Preservation is a property of LOCATION, not of text"* — and **LOCATION there
  means WHICH FILE**: content that must never rotate belongs in a file absent
  from `FILE_SPECS`, i.e. `standing_gates.md`, which the tool never reads or
  writes. **Pattern (A), used by §8 and §9, protects by POSITION WITHIN a
  rotating file** — the standing region is block 1, retention is a prefix, and
  `--keep` is validated `>= 1`. These are **different mechanisms with different
  failure modes**, and (A) is **not** an application of that header's doctrine:
  the header's mechanism fails only if a path is added to `FILE_SPECS`, while
  (A) fails if anything is ever prepended above block 1, or if a pinned literal
  gains a second occurrence outside it. **Two memory files now depend on (A)**,
  so a future packet must not cite the `rotate-memory.mjs` header as authority
  for positional protection. **In (A)'s favour, and recorded as such:** all three
  of its legs are pinned by *executed* assertions rather than by prose —
  including `case "$CS_HEAD_BLOCK" in "## Standing"*)` at
  `tests/build_os_maintenance_tests.sh:756-757`, which catches exactly the
  future prepend that would silently demote the standing region to block 2.

  **AND THIS ENTRY'S OWN LINE MOVEMENT IS DISCLOSED RATHER THAN LEFT IMPLICIT.**
  Writing the corrections above lengthened `CHANGELOG.md` by **104 lines**
  (1627 → 1731, `wc -l`), which moves every line below them. **No citation was
  newly invalidated by it, and that is measured, not assumed:** the six
  line-pinned citations into this file — `:124`, `:198`, `:223`, `:267` from
  `build-os/memory/residue.md`, and `:32`, `:106`, `:131`, `:133`, `:135` from
  two closed receipts — were **already naming other content at `b41aa5d`**,
  before this edit existed. That is the structural decay `residue.md` item **(r)**
  already registers: *"this will happen to EVERY `CHANGELOG.md` line-citation on
  EVERY future packet, because the changelog grows from the top."* The live
  cross-file guard on this file is **content-addressed, not positional** —
  `tests/release_metadata_tests.sh` §5 greps for the literal `2140 passed`, which
  is present **exactly once and unsplit** — so it is unaffected.

- **`build-os/memory/residue.md` was re-blocked so that rotation can reclaim
  space from it, and so that the part of it which must never rotate cannot.**
  The file had reached **204,658 B** against the **204,800 B** ceiling
  `build-os/maintenance/run-tests.sh` enforces — **142 B of headroom** — while
  carrying exactly **three** `^## ` blocks. `rotate-memory.mjs` retains
  `blocks.slice(0, keepN)`, so at the shipped `keep=10` it retained all three
  and archived **0 blocks / 0 bytes**: the preventative tool had nothing to
  prevent with, and it refuses at exit 3 once the file is already over.

  **THE REPAIR THAT MATTERS IS THE ORDERING, AND IT IS INVISIBLE TO EVERY GATE.**
  `rotate-memory.mjs` retains a **PREFIX** while its report prints `keep N newest`
  and `selection : RECENCY ONLY` — **it asserts a recency semantics it never
  verifies**, because it reads no date and has no way to know a block's age.
  `residue.md` was written **oldest-first**. Composed, that is **latent data
  loss**, and it is reproduced rather than argued: `git show
  bbdd85c:build-os/memory/residue.md` into a scratch root, then `rotate-memory.mjs
  --root <scratch> --file residue --keep 2 --apply` → exit 0, `block_3..block_3
  (90150 B)` archived, and the **newest** era marker ``### From
  `PACKET-0029-citation-anchor-tokens` (2026-08-02)`` lands in the **archive**
  while the **oldest** (2026-07-31) stays live. **Had rotation ever run on the old
  file it would have archived the most recent residue and kept the oldest.** The
  new sections therefore run **newest-first**, and at `--keep 10` on the re-blocked
  file the direction is inverted back: newest era live, oldest era archived. **A
  re-block that inserted 26 headings and left the order alone would pass every
  count-driven check in §8 identically and still lose the newest content on the
  first rotation**, so no gate in this tree can tell the two apart. Registered as
  `DEFECT-0014-retention-order-assumed-not-verified`, `OCCURRENCE-0015`, and
  **still open as a class** — `build-os/memory/current_state.md` is next: 182,545 B
  in exactly **3** `^## ` blocks, for which `--keep 10` reports `would archive :
  nothing — already rotated (no-op)` at exit 0.

  **Nothing was deleted, paraphrased or silenced, and no ceiling was raised.**
  The migration is a pure re-partition: **162 units carried verbatim = 129
  lettered items + 26 `## History` blocks + 7 `### From <packet>` era markers**,
  and the only line removed from the file is the old `## Deferred (follow-up
  packets)` heading, replaced by **29** named sections. Sections are cut at the
  file's own era markers, never across one, and named by the letter range they
  hold — because `build-os/metrics/signal_snapshots.tsv` already addresses this
  file by letter (`build-os/memory/residue.md#ddd`), not by line.
  **CORRECTED FROM "130 lettered items", WHICH WAS OFF BY ONE AND ALSO DID NOT
  CLOSE ITS OWN TOTAL** (at 130 the sum is 163, not 162). `(a)`…`(yyyyy)` is
  26+26+26+26+25 = **129 by construction**, and the file holds exactly that, zero
  missing and zero duplicated. Derivation:
  `grep -oE '^\- \*\*\([a-z]+\)' build-os/memory/residue.md | wc -l` — which
  returns **131** on the file as it now stands, because this packet's fix round
  added the two standing items `(aaaaaa)` and `(bbbbbb)`; the migration figure is
  **129** and is measured at `d888766`. The earlier `130` came from
  `grep -cE '^\- \*\*\('`, which also matches the non-lettered `- **(S1)` item.

  **The protection is positional and it is executed, not argued.** Retention is
  a PREFIX and `--keep` is validated `>= 1`, so block 1 — the standing region,
  holding all three literals `tests/release_metadata_tests.sh:322-324` pins —
  cannot be reached by any legal invocation. `tests/build_os_maintenance_tests.sh`
  §8 sweeps **every legal N from 1 to 29** on scratch copies: **27 rotate** with
  block 1 byte-identical and no pinned literal ever reaching the archive, **2
  refuse at the ceiling writing nothing at all**, and no pinned literal occurs
  anywhere outside block 1, so no archivable block is what keeps the
  release-metadata suite green. **That sweep covers the whole domain of the
  parameter that determines routing, NOT the tool's whole legal domain** —
  `--max-bytes` is equally user-settable and is not swept; raising it converts the
  N=29 ceiling refusal into a rotation the sweep never executed. Harmless, because
  `routeSegments(segments, keepN)` (`rotate-memory.mjs:328`) takes no ceiling
  parameter and so no `--max-bytes` value can change WHICH blocks are archived —
  but the claim as first written was broader than what was measured, and §8 now
  says the narrower thing. **The split was 28/1 at `d888766` and is 27/2 here**
  because the fix round's two residue items pushed the `--keep 28` retention over
  the ceiling; both outcomes are legitimate and §8 separates rather than lumps
  them.

  **FAILING TESTS FIRST, and the RED is reported at its true value: 80 passed /
  5 failed, exit 1** — the five being 3 blocks, keep=10 archiving 0 blocks, 0
  reclaimable bytes against a 40,960 B floor, 142 B of headroom, and no designated
  standing region. **Corrected from "79 passed": 79 is unreachable.** The
  §8-augmented suite is 85 checks
  (`bash tests/build_os_maintenance_tests.sh` → `85 passed, 0 failed`) and every
  check reports exactly once, so 85 = 80 + 5.

  **Measured, at `--keep 10`, from a dry run over a scratch copy, at the tree as
  this packet closes:** 29 blocks -> keep 10, archive 19; **127,142 B
  reclaimable**; post-rotation size **85,931 B**, leaving **118,869 B** of
  headroom under the 204,800 B ceiling. **The headroom GAIN is stated with the
  baseline it is relative to, because the two differ:** **+118,727 B** against the
  **142 B** the base file had, and **+126,636 B** against the current live file's
  **−7,767 B** (126,636 = 127,142 archived − the 506 B archive-pointer banner, and
  it is invariant under anything added to the retained prefix). The 123,400 B
  figure quoted at `d888766` was the base-relative one at that commit; the
  live-relative figure there was 126,636 B. The live file grew
  **204,658 -> 207,894 B** at `d888766` (+3,236: 26 net headings and the ordering
  note) **-> 212,567 B** here (+4,673: the two standing residue items), and is now
  **7,767 B above** `DEFAULT_MAX_BYTES`.
  **Rotation was NOT applied**; that is an operator act — it would relocate the
  still-open items `(ddd)` and `(uuuu)` into the archive — and it is now **queued
  for the operator at `(bbbbbb)`**, which is where the un-run rotation was
  previously queued nowhere. **The blocker was CONVERTED, not cleared:** from
  *142 B of headroom and a tool that can reclaim 0* to *7,767 B over an unenforced
  constant and a tool that can reclaim 127,142 B on one command*.

  **`DEFAULT_MAX_BYTES` is not enforced on the live size — but one gate DOES read
  the live size, and it is the customer-facing one.** `docs/PILOT.md`
  `<!-- PILOT:CHECK id=R7 -->` runs
  `find "$PILOT_REPO/build-os/memory" -type f -size +262143c`, red-driven at
  `tests/pilot_kit_tests.sh:415`. It **passes**: the largest memory file is
  `residue.md` at **212,567 B** against the **262,144 B** Read limit — **49,577 B
  of headroom** (54,250 B at `d888766`). **No blocker was traded**, and the earlier
  flat claim that "no gate reads the live size" was false as written; the true
  statement is that **no gate ENFORCES `DEFAULT_MAX_BYTES` on the live size**.
  R7 is the **11th** reader of this file and the only live-size one, and it was
  missing from the 10-row reader sweep this packet first reported.

  Suite **2121 passed**, 0 failed (+18, all of it §8; every other suite +0; the
  fix round is +0 — it CONVERTED one check rather than adding or removing one).
  Census **held at 105**, declared mismatches **held at 22**. **No new control** —
  one `evidence_refs` line-number correction only, `suite.build_os_maintenance`
  `:431/:432 -> :639/:640`, which is `DEFECT-0001-stale-line-reference` arriving
  again by way of an insertion above a cited line, now recorded as
  `OCCURRENCE-0016` alongside `OCCURRENCE-0017` for the `ANC-0003` content-site
  move `:40 -> :89` that drove `reconcile` to exit 2 — **the third consecutive
  packet to pay that tax, and the first to increment the counter built to count
  it.**

  **A CHECK THAT COULD NOT FAIL WAS CONVERTED, NOT DELETED.** §8's closing
  assertion was `[ -d … ] && ok … || ok …` — an `ok` on **both** branches,
  contributing one non-discriminating check to the 2121 total, and contradicting
  this tree's own standard as stated at `rotate-memory.mjs:309-315`: *"A guard
  that cannot fail reads as safety and adds no discriminating power."* It now
  asserts that **nothing under the real `build-os/memory/archive` is newer than
  the scratch copy taken at the top of the section** — i.e. that no rotation
  reached the real tree *during* §8 — which fails when a file appears there mid-run
  and passes both when the directory is absent and when it holds only older files.
  The conversion is **line-count-neutral by construction**, so that the
  `control_registry.txt` `evidence_refs` at `:639`/`:640` still resolve to the same
  two lines.

- **Claude closed work into governed project memory, and a second AI surface
  consumed that state without anybody copying the transcript.** That sentence is
  the whole packet, and it is an EXECUTED FIXTURE rather than a design: the
  committed `build-os/kernel/` stores were written by the governed adapter, the
  handoff `HOF-0001` was created through it, the ledger recorded every step,
  `CTX-0001` was compiled for the `gravito.chatgpt.strategy` role, and
  `build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md` is what the receiving
  surface reads. A consumer with no access to the Claude session can answer, from
  that file alone, what was completed, what remains open, what evidence supports
  it, what authority applies, and what decision is required next.

  **Eight canonical stores, one writer, and no second editable truth.**
  `namespaces · actors · memory_objects · memory_events · memory_relationships ·
  memory_artifacts · memory_handoffs · memory_context_packages`, all tab-separated,
  all append-only, all written by `build-os/tools/memory-kernel.sh` and by nothing
  else. Everything under `exports/` is a PROJECTION: `reconcile` regenerates each
  one from the stores and refuses any that differs, and a canonical object whose
  payload points into `exports/` is refused outright. **Citations are anchors, not
  line numbers** — the kernel reuses the `PACKET-0029` resolver and **no canonical
  store under `build-os/kernel/` RECORDS a `path:line` token**. The generated
  export does PRINT `path:line#ANCHOR`, and that is the distinction rather than an
  exception: a position the resolver returned at generation time is a navigation
  hint, and a position written into a store is an identity that decays.

  **The invariant the packet exists for:** a context package that PARSES but
  refers to the WRONG VERSIONS is REFUSED. A package binds exact
  `(object_id, version)` pairs; when a source advances, the package becomes
  **STALE, not silently current**, `read-context-package --as-current` exits 2 and
  names the drifted pair, and the export prints `state: STALE` on its face. That is
  `resolvability is not identity` in a twelfth substrate.

  **Namespace isolation refuses by default** — a write, a read or a relationship
  edge that reaches into a sibling project exits 2, and a package records how many
  objects were refused for being outside its closure **without naming them**, so
  the count leaks nothing. **Logical role and execution surface stay separate
  fields**, and a role claiming a surface it does not own is refused. **Truth state
  is not evidence:** `observed`, `verified` and `refuted` require a resolvable
  evidence reference and `decided` requires an authority, so a model-generated
  inference may enter memory and may not enter it as an observation.

  **Concurrency is optimistic and never silent:** every mutation carries an
  expected version, a stale one is a loud refusal that stores nothing, and
  `--on-conflict record` turns the conflict into a typed `finding` object plus its
  event rather than a last write that wins.

  One new suite, **`tests/memory_kernel_tests.sh` — 101 assertions, every section
  red-driven** — chained into the repository suite on an existing line so no
  citation into `tests/build_os_tests.sh` moved. **Four census entries**
  (`memory.kernel_schema`, `memory.context_package_identity`,
  `memory.kernel_store_append`, `suite.memory_kernel`), census **101 -> 105**, and
  **one new mutator record** `MUT-0010-memory-kernel-store-append`. **Declared
  mismatches 21 -> 22**, and the twenty-second was forced by an executed refusal
  rather than argued: the write control at `execute` on a Class A licence drives
  `scan-controls.sh check` to exit 2 with `LAUNDERED` while it carries
  `authority_mismatch: none`. Suite 2096 passed, 0 failed (+101, all of it the
  new suite; every other suite +0). Zero re-authorisations.

- **`gravito_measurement_integrity_a` (`PACKET-0036-measurement-integrity`) — the
  suite stopped reporting its own plumbing as a failure.** `DEFECT-0013`: under
  `pipefail`, `grep -q` exits on its first match, its producer dies of SIGPIPE
  (`PIPESTATUS=[0 141 0]`), and the 141 becomes the pipeline's status — so a
  correct assertion over a correct store printed FAIL. **Measured, not asserted:
  628 false failures in 4000 runs (15.70%) before, 0 in 4000 after**, and on a
  fixture past two pipe buffers 100.00% before and 0/2000 after. The fix drains
  the consumer (`any`) instead of disabling `pipefail`, which stays on.

  **The class was swept, not just the site.** 45 `pipefail`-enabling shell files
  — **45 of the 54 in the tree**, and the nine outside the scan are enumerated in
  the §28 header with the measurement that the gap is currently harmless — and
  **258** candidate `producer | early-exiting consumer` pipelines, comment lines
  excluded, each figure stated with the command that reproduces it. The 64 KiB
  pipe buffer is the discriminator and **exactly one site could actually race**.
  The neighbouring two assertions measured 0/4000 and were converted anyway,
  because their safety was a property of today's file size and of which `awk` is
  installed — measured over **N=200 trials each**: `sed -n '1p;1q'` kills its
  producer 200/200, `head -1` 105/200, `grep -m1 .` 19/200, `grep -q .` 16/200,
  and **mawk's `exit` 0/200**.

  New guard, `tests/build_os_tests.sh` §28 — **7 assertions**, a red drive that
  reproduces the race on an amplified fixture before the green claim is made, and
  a static scanner over the whole tree with a **measured** allow-list. Suite
  **2103 passed**, 0 failed (+7, all of it §28; every other suite +0). Census
  **held at 105**, declared mismatches **held at 22**, gate-on-advise **held at
  14**. Zero re-authorisations. **No new control.**

  **Seven claim defects were corrected in a bounded third commit, and the first
  of them was the packet's own headline sentence.** `DEFECT-0013` had been
  recorded in three places as *"ONE-DIRECTIONAL: it can manufacture a false FAIL
  and can never mask a real one"*. **That is false as a class claim, and it had
  already been relayed to the operator twice.** One-directionality is a property
  of the `&& ok || no` **polarity**, not of the class: inverted, the same 141
  routes to `ok` and the identical race yields a **false PASS masking a real
  failure**. `tests/build_os_maintenance_tests.sh:414` is written that way and
  returned non-zero **2000/2000** at 270890 B, 0/2000 draining — **latent, not
  live** (it needs >64 KiB in a directory the test expects empty) and **invisible
  to the new scanner**, whose producer patterns do not enumerate `find`. The
  greens still stand, but because that counterexample is unreachable rather than
  because the class cannot mask failures. The remaining six were figures and
  scope: the `5/5` consumer-lethality table replaced by N=200 measurements, the
  scanner's 45-of-54 file scope and its four already-present `set -euo pipefail`
  scripts, the file-granular allow-list, the unenumerated `awk '…exit'` idiom
  with its two live sites, and **two figures withdrawn because no derivation in
  the tree reproduces them** (`235` candidate pipelines, `~40` `sed … | head`
  dumps). **No behaviour changed, no assertion was added or removed, and the
  suite total is unmoved.** Every retained figure now carries the command that
  reproduces it. The registry's four line-citations into
  `tests/build_os_tests.sh` were re-pointed after the comment edits moved them.

  **Six defects the reviewer found were fixed in a bounded third commit, and four
  of them were the packet claiming a perimeter it did not hold.** (1) The export
  printed the handoff row's frozen `status`, so an acknowledged handoff — one the
  committed ledger records as `HandoffAccepted` — exported as `created`; the
  status is now DERIVED from the last acceptance event, because the module's own
  comment already said the ledger is what carries state changes. (2) The export's
  BODY resolved through `obj_current_row` while only its binding table resolved at
  the bound version, so a `state: STALE` document could show section 3 at v2 and
  section 9 at v1 **at exit 0** — `resolvability is not identity` reproduced inside
  the artifact built to refuse it; every section now renders at the package's bound
  `(object_id, version)`. (3) **The tamper-evidence claim was false.** The
  package's self-hash is UNKEYED, so a recorded contradiction could be laundered
  away, re-signed, and read past both `validate` and
  `read-context-package --as-current` at exit 0. `ContextCompiled` now carries the
  package `content_hash` into the digest-chained ledger, both gates cross-check it
  (`PACKAGE-UNANCHORED`), and the old refusal text — which overstated what an
  unkeyed self-hash detects — now says what it actually detects. (4) `project`
  took no actor and printed a sibling namespace's object **in full, including its
  payload**, at exit 0; it now carries the same scoping triple every other path
  does. (5) Two false claims corrected: no canonical STORE records a `path:line`
  token — the generated export prints resolved return values, which is the point —
  and the export's "nothing was omitted" is now scoped **AT COMPILE TIME**, which
  is all `pkg_state` can support, since it iterates bound ids and cannot see an
  object recorded after the compile. (6) The export was regenerated and
  `reconcile` returns 0 divergent. **The registry's five line-citations into the
  two kernel files were re-pointed by CONTENT after the edits moved them** —
  census holds at 105, declared mismatches hold at 22, zero re-authorisations.

- **A line number is now a navigation hint, and it is no longer an identity.**
  Residue `(mm)` had measured the hole and named the remedy in one sentence: the
  citation guard checks **resolvability, not identity**, and "the durable fix is
  an ANCHOR TOKEN or a CONTENT HASH instead of a line number". Across the three
  tools whose references drifted, **20 of 27 pointed at a different line and
  passed every check that existed.** So `build-os/registry/scan-controls.sh`
  gained an anchor scheme: ten fields per record — `anchor_id`, `object_id`,
  `object_type`, `namespace_id`, `semantic_role`, `artifact_ref`,
  `content_or_symbol_ref`, `version`, `created_at`, `supersedes` — resolved **by
  content**, with the line number computed at every resolution and stored
  nowhere. Thirteen anchors instantiate all twelve declared object types.

  **Eight identity rules, each driven red before it was made to pass**: an anchor
  survives insertion above it; two objects cannot claim one anchor; **a stale line
  number is REJECTED when — and only when — it now lands on the anchored site of a
  DIFFERENT ANCHORED object**, which is the one case where a reader follows the
  number, finds something real and believes it; generated projections carry their
  identity and a projection stripped of it is refused; a renamed heading supersedes
  an earlier one **without rewriting it**; **a reference may resolve syntactically
  and still fail identity validation**; historical references still return their
  original object at its original version; and the sealed `DECISION-0011` evidence
  still resolves after this packet moved the very lines it is cited by. **Every
  other stale hint — at 13 anchors, nearly all of them — is reported as
  `HINT-STALE` at exit 0 with the corrected projection printed beside it**, so the
  reader is corrected rather than misled: the position was demoted, not outlawed.

  **The implementation was itself deformed by the absence of the thing it
  builds.** Ten `evidence_refs`, two live ranges and four frozen receipts cite
  `scan-controls.sh` by line number, so the new dispatch had to be packed into
  existing lines rather than inserted above them. That cost is recorded in the
  module rather than tidied away.

  No new store, no new tool, no new suite file; **one census entry** —
  `registry.evidence_resolution`, Class A at `gate`, which is the
  `census_growth_controls=1` **forecast** sealed for this candidate before anyone
  selected it. **Declared mismatches hold at 21.** Suite **1995 passed**, 0
  failed (+31, all of it `tests/control_registry_tests.sh` section 28);
  `scan-controls.sh check` and `scan-mutators.sh check` both exit 0; zero
  re-authorisations. **One selected rank is one observation and is not evidence
  of ranker skill.**

- **The shadow ranker now has to rank BEFORE the choice, and the tooling refuses
  to let it do otherwise.** A ranking formed after a decision is a
  rationalisation, and it is byte-identical to one formed before it — nothing
  about the artefact distinguishes them. So `ranking < selection < execution` is
  three refusals in `build-os/metrics/record-decision.sh`, each driven red on its
  own fixture: a ranking cannot be **sealed** for a decision that already carries
  a selection row; a selection cannot be **recorded** over a candidate set
  different from the sealed one, and cannot carry its own outcome; an outcome
  cannot be **recorded** for a decision nobody has taken.

  **What that enforcement rests on is stated in the code rather than implied
  away.** A timestamp that *parses* is not a timestamp that *proves ordering*.
  What is constitutive is the **existence order of a row across two stores at the
  instant of each write** — the seal lands in the digest-chained snapshot file
  where every later row's digest covers it. The ISO-8601 strings are
  **corroborating only**: a contradiction between them is refused because a
  contradiction is always wrong, and agreement between them is never treated as
  proof. Outside both stores is git, and it anchors **order** and nothing else:
  the seal is committed before any commit can carry its selection, and the
  parent-hash chain makes that order non-forgeable — **but only once a third
  party has witnessed it, and this branch is unpushed**, so the anchor is
  *unwitnessed* rather than proven. It does **not** anchor independent agency:
  committer identity and both commit dates are self-asserted, and the same
  reasoning that refuses a self-reported timestamp refuses those too.

  **A real ordering is sealed over a real candidate set that nobody has chosen
  from yet.** `DECISION-0011-p5b-next-after-p3b`, rule `s1-v1`, over 20 frozen
  signals: one candidate refused as self-amending, then rank 1, a genuine tie at
  rank 2, and a dominated candidate at rank 4. It has **no row** in
  `decision_telemetry.tsv`, deliberately, and that absence is the evidence.
  **Three of four rankable candidates sit on the Pareto frontier** — unlike the
  first ordering, whose single dominator survived 125 of 125 weightings and
  therefore carried no information. Weights would change this one, which is the
  first time that has been true.

  **The outcome record is separable from the selection record by PARTITION, not
  by convention.** Every telemetry column belongs to exactly one of a selection
  set and an outcome set; the partition is checked against the schema at run time
  and fails closed on a column neither set owns. A third declared set —
  `rank_of_selected`, `ranking_agreement`, `ranker_skill` and their siblings —
  **owns no column at all** and is refused by both write paths, because
  discovering that the chosen candidate mattered is evidence about the
  **candidate**, not evidence that anything ranked it for the right reasons.

  **Every missing outcome is named, and the category is derived rather than
  remembered.** Of 19 declared outcome fields on the first decision reported, 3
  carry a value, 4 are `MISSING` (this store holds them for some other decision)
  and 12 are `NEVER-COLLECTED` (nothing here has ever measured them) — counted
  from the store itself. Every recorded value is reported `UNINTERPRETED` and
  every scored total is withheld, because no outcome field in this repository has
  a declared direction and inventing one would put an unregistered constant
  inside every later ordering.

  No new store, no new tool, no new suite file, no new primitive; **one census
  entry**, and with it the twenty-first declared mismatch, because the in-place
  outcome amendment is a mutation surface the census did not carry and the
  existing record says in its own words *"never an edit to an existing one"*.
  Suite **1964 passed**, 0 failed; `scan-controls.sh check` and
  `scan-mutators.sh check` both exit 0; zero re-authorisations.

  **The seal had a second, unguarded door, and review found it.** `seal-ranking`
  refuses to seal once a decision carries a selection — but that refusal reads
  `decision_telemetry.tsv`, while the field it protects lives in
  `signal_snapshots.tsv`, and the generic `snapshot` writer accepted **any**
  `--signal-name` at all. A hand-written `sealed_rank` row for an already-decided
  decision was accepted, **chained cleanly, and left every row verifying** — so
  unlike deleting a row and re-adding it, that route produced *no evidence
  whatsoever* while converting a permanently retrospective decision into a
  "prospective decision with a recorded selection", which is the one number this
  substrate publishes as the only thing that could ever make `rank_of_selected`
  evidence about a ranker. **Two stores, one guarded door.** `snapshot` now
  refuses all six declared ranker-evidence field names and names `seal-ranking`
  as the one door — the check is on the field name, so a seventh added later is
  closed by the same line. `seal-ranking` additionally refuses an ordering that
  gives one candidate two ranks, which previously sealed the first rank while
  printing the contradiction back, leaving the receipt and the chained evidence
  describing different orderings.

  **And the honest half, found by execution rather than argued:** the
  `ranking_digest` published for the first ordering **no longer reproduces**. It
  covers the snapshot store's global chain head, so appending any snapshot for
  any decision moves it — the ordering itself is unchanged, byte for byte, and
  the number that was quoted as durable had a shelf life of one append.

- **The first executive component: a shadow ranker that forms an explicit,
  inspectable preference among several permissible good actions — and refuses to
  rank anything that would promote it.** Everything in this system until now
  prevented a bad action. `build-os/metrics/rank-candidates.sh` takes a real
  recorded decision, reads the digest-chained signals frozen at the moment that
  decision was taken, and emits an ordering with the DECOMPOSITION — what each
  signal contributed to each candidate's position — rather than a total score
  somebody is expected to trust.

  **It writes nothing, anywhere.** No new store: the ordering is immutable *by
  derivation* rather than by storage, a pure function of a chained input and a
  versioned rule, so re-running reproduces the `ranking_digest` and an edited
  historical signal refuses before anything ranks. Two live stores are
  byte-identical before and after a run, and the suite measures that rather than
  asserting it.

  **Guard 1 — no learned policy may optimize the mechanism governing its own
  promotion.** A candidate whose frozen write surface reaches S1's code, its
  registry entry, its own tests or the licence machinery is REFUSED, with the
  reason printed: an excluded candidate that silently disappeared would be
  indistinguishable from one that ranked last. It fails closed — a candidate
  with no frozen write surface is refused as unscreenable, never assumed
  innocent — and it discriminates: on the real candidate set two of seven are
  refused and five are ranked, including one whose write surface touches the
  *same file* as a protected object but a different section of it.

  **Every absence is named and none of them scores.** `MISSING` (declared but
  not frozen for this decision), `UNINTERPRETED` (frozen here, but its direction
  has never been established) and `NEVER-COLLECTED` (cost, energy, recurrence,
  counterfactual regret, outcome quality, human attention). A defaulted signal
  is the `untested`-missing-from-`EVIDENCE_AXIS` defect again.

  **And it can be wrong.** `rank_of_selected` records where the human's actual
  pick landed in S1's ordering; on the first real decision it is **1**, over
  **n = 1**, and one agreement is not evidence of skill. Two census entries, no
  new store, no new tool beyond the ranker itself, and no new suite file: 29
  assertions in `tests/mutator_registry_tests.sh`, plus **11 more from the fix
  round** that drive the whole-set refusal and the four path aliases guard 1 used
  to fail open on. Suite **1909 passed**, 0
  failed; `scan-controls.sh check` and `scan-mutators.sh check` both exit 0;
  zero re-authorisations. `goal_ecology` — recorded in the crosswalk since it was
  written as the primitive nothing could bind to, because *"no control weighs two
  objectives against each other at runtime"* — is no longer empty, and the
  binding only PROXIES: three objectives ordered, six named as never collected.

- **A fifth mismatch disposition, and a lease term that is finally enforced
  against a clock.** `MISMATCHES.md` named four remedies —
  `demote_authority`, `correct_class`, `improve_evidence`, `retire_control` — and
  `maint.source_scan_mask`'s own registry entry records that **all four were
  closed to it**. `accept_and_constrain` is the fifth: the mismatch is **carried**
  because demotion or removal has been **MEASURED** to be more dangerous than the
  mismatch. New store `build-os/registry/mismatch_dispositions.txt` keyed by
  `DISP-NNNN` stable ids, new tool `build-os/tools/mismatch-disposition.sh`, new
  suite `tests/mismatch_disposition_tests.sh`.

  **It clears nothing and raises nothing.** The disposed control keeps
  `authority_mismatch: declared`, keeps its row in the summary table, and keeps
  its `OUT-OF-LICENCE` finding — all three asserted against the **live** tree.
  **It is applied to exactly one control and refuses its neighbour by name:**
  `maint.tripwire_coverage_scan` qualifies on all four conditions;
  `maint.source_scan_mask` is refused, and the refusal quotes the census's own
  `demotion_requirement`, which records that demotion as **REACHABLE**.

  **The lease term was decorative at BOTH ends, and that was executed rather than
  inferred.** An envelope seven months dead reported `1 live grant(s)` and
  `WITHIN-LICENCE … l-deployment=execute`; the same lease under `shadow` dragged
  a control licensed `gate` on both live axes down to `observe` inside
  `evidence-policy.sh check`, naming `axis=deployment`; and the same record moved
  five months into the future bound **byte-identically**. `date` appeared in no
  tool in the repository. **The defect is not "expired grants over-permit"** — it
  is that an expired grant keeps applying **in whichever direction it pointed**,
  and only the restrictive direction is visible, because an ungranted control
  already defaults to `autonomous`/`execute`. Out-of-window records now report
  `LAPSED` or `NOT-YET-LIVE`, contribute no grant, and never reach
  `mode_projection()`. `claim-evidence.sh` enforces `valid_from`/`valid_until` the
  same way — refusing an out-of-term store while **retaining** the assertion in
  the minimum, because dropping a lapsed refutation would RAISE a licence.

  One clock, one owner: `authority-envelope.sh now`, overridable through
  `BUILD_OS_NOW`, refused when malformed, and **announced in the output** whenever
  it is in force. Census **93 → 97**; suite **1869 passed**, 0 failed (+98 from
  1771: +81 in the build, +17 in the fix round); findings numerator
  **unchanged at 25**, split **6/5/14**; **zero re-authorisations**.

- **Evidence stopped being a property of a control and became an assertion about
  a named claim in a named scope — because one control was measured both refuted
  and supported, and one token could not say both.**
  `maint.tripwire_coverage_scan` is **refuted** for its detection claim under
  bare `node --test` and **supported** for its prevention claim under the
  sanctioned maintenance invocation. Reasoning from the bare token — *"it is
  refuted, so demote it"* — nearly produced the demotion the
  COVERAGE-GATE-PREVENTION-DIFFERENTIAL measured to **destroy live memory**. New
  store `build-os/registry/evidence_assertions.txt`, keyed by `EV-NNNN` stable
  ids, carrying nineteen required fields per assertion; new tool
  `build-os/tools/claim-evidence.sh`; new suite `tests/claim_evidence_tests.sh`.
  Suite **1771 passed**, 0 failed (+82: 77 in the new suite, 5 in the
  authority-envelope suite where §18 was retargeted); maintenance suite
  **144/144**; `scan-controls.sh check` and `scan-mutators.sh check` both exit 0.
  - **The evidence axis had a second, diverged copy, and §18 could not see it.**
    `authority-envelope.sh` restates `EVIDENCE_AXIS` literally instead of
    sourcing it, and this change updated `evidence-policy.sh` and the prose but
    not that copy. The consequence was live, not theoretical: `axis_cap` returns
    the empty string for a missing token, `rank_of ""` is -1, and the
    `[ "$tr" -ge 0 ]` guard drops the strictest token straight out of the
    minimum — so a `gate` grant on a control carrying `untested,red_driven`
    reported **WITHIN-LICENCE** when `l-evidence` is `observe`, over-reaching by
    three rungs inside the tool whose job is catching over-grants. Latent only
    because 0 envelopes are live and 0 controls carry `untested`. §18's two new
    assertions grep the **tool under test**, and are written for the **class**:
    every literal `<NAME>_AXIS="…"` restatement under `build-os/tools/` must
    agree token-for-token with `evidence-policy.sh matrix`. Red-driven by
    reverting the one-token fix — **94 passed / 2 failed**, restored to
    **96 / 0**. This was the third instance of one unchecked-duplicate defect,
    and the first fix for it that is not pair-shaped.
  - **`untested` was added to the evidence vocabulary, at `observe`, and the
    guard it interacts with was not weakened.** It means the claim **has never
    operated** against a live or representative task — strictly weaker than
    `unvalidated`, which has operated and lacks adequate outcome evidence. It
    caps at `observe`, the lowest rung that is still a legal destination.
    `evidence.derivation_nonvacuity` still exits 2 on any token nothing has
    capped; what changed is that `untested` stopped being one of them. **Both
    halves are proven in the same run** — §4 of the new suite drives a
    still-unrecognised token to exit 2 in the same pass that shows `untested`
    resolving — so "recognising one token" cannot be read as "opening a
    fall-through". The cap was chosen in the direction that **costs**: the
    sanctioned S1 declaration (`heuristic_policy` / `untested` / `rank` /
    `shadow`) is now **more** out of licence, not less. The class × evidence grid
    goes **25 cells → 30**, and **0 of the 30** license `execute`, unchanged.
  - **The legacy projection exposes the composite and never selects.** Where a
    subject carries several claim statuses, `claim-evidence.sh project` emits
    **all** of them, sorted and deduplicated, so the output cannot depend on
    stanza order and **a refutation cannot be dropped**. Selecting whichever
    status permits greater authority is the flattering-direction error this
    repository exists to catch, and in this case it is the demotion that was
    measured to destroy live memory.
  - **`supported` projects globally to `unvalidated`, and the loss is the
    point.** A support claim is scope-bound; the legacy `empirical_status` field
    carries **no scope**, so writing `field_observed` would assert globally what
    was measured locally. **The cost is stated rather than hidden:** a genuinely
    well-evidenced control reads no better through the projection than an
    unmeasured one. The projection is a compatibility shim, lossy in the one
    direction that cannot flatter, and the scoped claim is legible only in the
    assertion store.
  - **Evidence may lower authority and may not raise it, and that is driven red
    rather than asserted.** `L_effective = MIN(L_class, L_registry_evidence,
    L_assertion_evidence)`. §8 of the new suite fabricates a Class-A control the
    census records `refuted` and hands it a `red_driven` assertion that licenses
    `gate` on its own — and requires the effective licence to come out
    `observe`, checked as an inequality over the ladder rather than as a matched
    string. Without that, an assertion store is a laundering channel for
    authority.
  - **Census 90 → 93; the out-of-licence numerator did not move.**
    `evidence-policy.sh check` reports **25 of 93**, split **6/5/14** — the same
    25 findings against a larger denominator. The three new controls
    (`evidence.assertion_schema` A/`gate`, `evidence.claim_projection`
    C/`advise`, `suite.claim_evidence` A/`gate`) are each **in licence**, so the
    entire delta is the denominator. **Nothing pre-existing was re-authorised:**
    `maint.tripwire_coverage_scan` keeps `class: C`,
    `empirical_status: red_driven,refuted`, `runtime_authority: gate` and
    `authority_mismatch: declared`, and the new suite asserts all four.
  - **Every stale citation was repointed by recomputing content against the
    base, never by shifting numbers.** Growing four tool headers moved 41
    `evidence_refs` across six files; each was resolved by locating its base-commit
    line content in the current file and failing loudly on ambiguity, because
    `scan-controls.sh` checks that a ref *resolves* and never that it names the
    **same line**. The prose sweep hit the **source artefact**
    (`neurocosmology_crosswalk.txt`) as well as the doc derived from it
    (`CROSSWALK.md`), and every count written was re-derived from the artefact
    rather than copied from the brief.
  - **The known limitation, recorded rather than implied away.** Every field of
    an assertion is taken **at the author's word**, exactly as
    `empirical_status` already is. Nothing re-runs a `fixture`, checks that an
    `observed_result` was ever observed, or enforces a `valid_until` that has
    passed — that field is recorded so a later packet can enforce it, and calling
    it enforced today would be the overclaim the store exists to prevent.

- **Every known repository mutator is now visible to the authority model, and
  `execute` has its first six occupants — earned against the rung's own test, not
  created to populate it.** Until now every control sitting on a mutating module
  classified the *check* and not the *write*: six controls guard
  `record-packet.sh` and each one refuses **before** the append;
  `tools.handoff_lock` classifies a fail-closed acquisition, not the lock;
  `maint.rotation_conservation` classifies a property of a *plan*, not the rename
  that applies it. The write actions themselves were registered at **no authority
  at all**. Suite **1689 passed**, 0 failed (+53, all in the new
  `tests/mutator_registry_tests.sh`); maintenance suite **144/144**;
  `scan-controls.sh check` and the new `scan-mutators.sh check` both exit 0.
  - **The brief named five mutators and said not to trust the list. The survey
    found seven, and rejected four candidates.** Added: `hook-once.sh`'s marker
    `mkdir` and `install-maintenance.sh`'s `cp` into a customer tree. Rejected
    after inspection: `scan-controls.sh` and `authority-envelope.sh` (append only
    to an `mktemp` path their own `trap` removes), `check-adoption.sh` and
    `bandwidth-check.sh` (`git cat-file -e` / `rev-parse`, which read). The
    negative result is recorded because a census that lists only what it found
    cannot be audited for what it missed.
  - **The evidence-policy denominator moved, and the numerator did not move for
    anybody who was already there.** `evidence-policy.sh check` now reports
    **25 of 90** out of licence, split **6/5/14**, against 19 of 81 split 6/5/8.
    The class axis binds the same 6 and the evidence axis the same 5; the entire
    delta is **+6 in "both axes bind"**, which is the six new `execute` entries.
    **No class licenses `execute`** — 0 of the 25 grid cells reach it — so a
    control that performs a durable write is out of licence *by construction*
    rather than by anybody stretching a heuristic, and each declares
    `authority_mismatch: declared` with a row in `MISMATCHES.md` §17.
  - **`maint.managed_set_replacement` was examined, as asked, and deliberately
    NOT moved.** It sits at `advise` while declaring its output as *"files copied
    into an installed repo, replacing prior managed copies"*, its failure as
    *"none that stops anything"* and its rollback as *"none"*. On the corrected
    ladder that is `execute`. **It is a pre-existing control, and moving one is a
    re-authorisation that belongs to the operator** — so it is recorded as
    `FINDING-0001` with the remedy named and unapplied, and `hooks.once_dedup` as
    `FINDING-0002`.
  - **The restraint is mechanical, not promised.**
    `build-os/registry/governance_baseline.txt` pins the class, runtime authority
    and mismatch flag of all **81** controls that existed at the base commit;
    `scan-mutators.sh` and the suite fail if any of them moves without that file
    being edited in the same diff. Each finding is also checked against its own
    subject, so applying a remedy without updating the finding — or deleting the
    finding to retire the accusation — fails too.
  - **Stable identity at birth, and line numbers demoted to navigation hints.**
    32 ids across four namespaces (`MUT`, `DEFECT`, `OCCURRENCE`, `FINDING`),
    derived rather than ledgered — a central ledger would be a second copy of
    every id with nothing reconciling the two, which is `DEFECT-0003` itself.
    Tests pin that the id set is byte-identical after every record moves, that a
    duplicate is refused, and that `project` **refuses** a store keyed on a
    `path:line` rather than rendering it as a tidy table.
  - **Defect recurrence is out of prose and countable.** Twelve classes seeded,
    nine occurrences migrated, and `query(DEFECT-0001-stale-line-reference)`
    returns **three**. Every count is a **lower bound** — migration is partial by
    design, so this store can prove a defect recurs and can never prove one did
    not. `residue.md` (aa)–(ss) stays prose; the migration path is written down.
  - **Decision telemetry that keeps unknowns unknown.** Every quantitative field
    is `unknown` or `<value>@measured|derived|reported`; a bare number is
    **refused**, and omission yields `unknown` — never 0. `0@measured` remains
    legal and distinct. Seven decisions recorded, and **nothing was back-filled by
    inference**: the only derived values are one packet's wall and serial minutes,
    copied from `packet_metrics.tsv`, which is the only historical row carrying
    them. The report withholds a sum entirely for a column with nothing known.
  - **Signals frozen at decision time.** Twelve snapshots over four candidates and
    the three currently derivable signals, digest-chained so a retroactive edit
    breaks the chain — **tamper-evident, not tamper-proof**, and the difference is
    stated in the tool rather than implied. The record is deliberately unflattering
    to the signals: the selected candidate scored **0** on `dependency_unlock_count`
    while an unselected one scored 1, because the operator's ruling outranked the
    only ordering signal that existed.
  - **The packet hit `DEFECT-0001` on itself, and the guard did not catch it.**
    Adding one `chain_suite` line shifted **ten** citations into
    `tests/build_os_tests.sh` — eight in `control_registry.txt` and two in
    `MISMATCHES.md`; `scan-controls.sh` flagged only the three that
    landed on a lone closer or a comment, because **it checks that a ref resolves,
    never that it names the same content**. The other **seven** were silently
    wrong, including one markdown table row and one prose citation in
    `MISMATCHES.md`. All ten were repointed
    by recomputing content against the base commit — never by shifting numbers —
    and re-verified by content afterwards. **The first count published here was
    itself wrong**, and wrong in the direction that under-reported the packet's
    own self-inflicted defect: it said seven shifted and four silently wrong.

- **The authority ladder was measuring the wrong property, and it has been
  corrected: `observe` is now defined by CONSEQUENCE rather than by consumption,
  and a sixth rung `execute` sits above `gate`.** The previous packet proved
  `refuted → observe` was an **unreachable remedy** — foreclosed for **67 of 81**
  controls with **0** sitting there. The cause was definitional: `none` and
  `observe` were **both** defined by non-consumption, so the ladder had **no rung
  meaning "it is read, but it may cause nothing"**, which is exactly where a
  refuted-but-wired-in control belongs. The ladder is now
  `none < observe < advise < rank < gate < execute`, where `observe` means the
  output may be recorded and **consumed for visibility** while causing **no
  operational consequence**, and `execute` means the output may **directly cause
  mutation**. Suite **1636 passed**, 0 failed (+19, all in the evidence-policy
  suite). `evidence-policy.sh check` still reports **19 of 81** out of licence,
  split **6/5/8 — unmoved**, `scan-controls.sh check` still exits 0, and the
  maintenance suite is 144/144.
  - **A redefinition that re-authorised nobody, which is the whole point.** No
    `class`, `runtime_authority`, `authority_mismatch` or `empirical_status`
    changed. The cap `refuted → observe` did not move; what moved is that it is
    now a **legal destination** rather than an instruction that could be
    prescribed and never written. **No class licenses `execute`** — Class A still
    reaches `gate` — so the new rung has no licensed occupant, and a test asserts
    that **no cell** of the 25-cell class/evidence grid reaches it.
  - **The remedy had to land in SEVEN places, not one.** The previous packet
    recorded that consumption was asserted in **six** sites and that *a remedy
    touching only the README is not a remedy*, because the foreclosure was
    enforced by **code**. All six were rewritten — `README.md` §2's two bottom
    rungs and §3b's `shadow` row, `authority_envelopes.txt`'s header, and the
    headers of `authority-envelope.sh` and `evidence-policy.sh` — plus
    `scan-controls.sh`'s hard-coded refusal text. A **seventh** was found during
    the build: `control_registry.txt` carried the retired rule in two live fields
    of `maint.source_scan_mask`, including a `demotion_requirement` telling the
    operator that *"demotion becomes available only when nothing consumes it"* —
    the field read **while deciding**. `tests/evidence_policy_tests.sh` §21 now
    sweeps all seven **by content**, and the rule is absolute: the retired clause
    may not appear even inside a quotation, because no grep can tell a quotation
    from a definition. Three of this packet's own edits tripped that rule and
    were rewritten rather than exempted.
  - **The new guard reproduced this packet's own headline defect, and that is
    the finding worth keeping.** The headline was that `VACUOUS-REF` checks
    **resolvability, never identity** — it confirms a citation lands *somewhere*
    and never that it lands on the *right* thing. §21 was then built in the same
    shape one level up: it greped **one** wording of the retired rule (the
    README's, *"nothing reads the result"*) while the retired rule has **two** —
    the deployment axis states it as *"nothing consumes it"*. **Two sites shipped
    past the sweep carrying the second wording**, and they were the two files
    that **own** the deployment axis: `authority-envelope.sh`'s `shadow` row and
    `control_registry.txt`'s `envelope.grant_composition` notes. §21 now also
    refuses a consumption clause on **any line that maps something onto
    `observe`** — scoped to the mapping lines because *"nothing consumes it"*,
    unlike the README's wording, is **also** the correct phrasing of the third
    axis's motivation and cannot be banned outright. Driven red first: the new
    assertion fails on exactly those two sites and no others
    (`120 passed, 1 failed`), and goes green once both are corrected
    (`121 passed, 0 failed`).
  - **The ladder's SPELLING is still unswept — recorded as its own packet**
    (`MISMATCHES.md` §16). Adding a sixth rung left the five-rung enumeration
    behind in **four** live places, all found by reading the diff rather than by
    the suite. The sharpest was **a passing test whose transcript printed a false
    ladder**: both suites compared against the six-rung `$LADDER` — the assertion
    was right — and then reported success with a hard-coded five-rung string. All
    four were repaired by hand and the `ok` messages now derive from `$LADDER`
    instead of restating it. **The guard is deliberately not bolted on here:** the
    drift lands in a different site set (`tests/*.sh`, not the seven semantic
    sites) and needs a different check — the five-rung string is a **prefix** of
    the correct six-rung one, so it needs a continuation test, not a containment
    test.
  - **What the correction COST, stated in the direction that does not flatter
    it.** The `observe`/`advise` boundary is now **intent-based and no longer
    mechanically checkable**. `gate` has a test (*exits non-zero*), `execute` has
    one (*performs a durable write*), `none` has one (*names no consuming
    policy*). `observe` **used to** have one — non-consumption is greppable, and
    `OBSERVE-LB` was built out of that grep — and defining the rung by consequence
    removes it, because nothing in the tree can decide whether a consumer's use of
    an output is *visibility* or *influence*. **Three of six rungs are now
    separated by the registering author's assertion alone.** That was the right
    trade — the checkable boundary is exactly what made the rung unreachable —
    but it is a real loss of enforceability, recorded in `README.md` §2.
  - **The reading NOT taken on `autonomous → execute`, recorded the way §3's S1
    collision records both of its readings.** *An operator who authorised
    **autonomy** did not thereby authorise **mutation**;* those are different
    permissions, and on that reading the cap belongs at `gate` with a **fifth**
    deployment mode declared for mutation. **Not adopted, structurally:** the
    deployment axis states a **ceiling**, not a grant, and `L_effective` is a
    **minimum** — so the row says *"this axis imposes no cap"*, not *"an
    autonomous control may mutate"*, and the **class** axis still withholds
    `execute` from every class. Adopting it would also re-create the defect just
    removed: a rung reachable on no axis. **Whether a fifth deployment mode should
    exist survives as a live question** and is recorded in `README.md` §3b.
  - **`OBSERVE-LB` moved off the gating path, because the axis it enforces is
    advisory.** The guard refused `load_bearing` at `observe` at **exit 2**, so
    the evidence axis could *recommend* a demotion and this scanner would then
    *forbid* the operator from applying it. Under the corrected ladder its
    premise dissolves outright — being consumed at `observe` is now legal — but a
    **narrower** tension survives and is about consequence: `load_bearing`
    asserts that *removing it changes outcomes*. So the check was kept, re-keyed
    to consequence, and moved to a new **advisory channel** in `scan-controls.sh`
    that prints and counts but never sets the exit code. The red drive now proves
    **both** halves: the finding still fires **by name**, and the scan exits 0 —
    while a genuine violation still refuses at exit 2, so only this one check
    moved.
  - **`autonomous` now caps at `execute`, and staying at `gate` would have been
    the silent demotion.** That mode's cap was only ever justified by
    **position** — *"no additional cap"* — never by the token `gate`. Holding it
    at `gate` once `execute` existed would have turned a documented **non**-cap
    into a real cap on every control that predates the axis, and would have made
    `execute` unreachable on that axis for everyone — reproducing the exact
    unreachable-rung defect being fixed. It grants nobody `execute`, because the
    composition is a **minimum** and the class axis still caps Class A at `gate`.
    The test that pinned this was itself the hazard: it read
    `= "$(rank_of gate)"`, which after the change would have *demanded* the
    default demote the census; it now asserts against the **top of the ladder**,
    derived.
  - **The mutation census — surveyed, reported, acted on in no way** (`MISMATCHES.md`
    §15). A rung meaning "directly causes mutation" invites the question of which
    controls already mutate. Almost none is mis-classed at `gate`, because **the
    controls are checks and the mutations belong to the modules they live in**.
    The registry's own `motor` role — *"it changes the world"* — is carried by
    **2 of 81** entries, and the sharp one is **not** at `gate`: 
    `maint.managed_set_replacement` sits at **`advise`** while its declared output
    is *"files copied into an installed repo, replacing prior managed copies"*,
    its failure behaviour is *"none that stops anything"* and its rollback is
    *"none; a managed file's local edits are lost on install"*. Five modules
    durably mutate — `rotate-memory.mjs` renames onto the live memory file,
    `swarm-merge.sh` commits behind `--commit`, `record-packet.sh` appends to the
    store, the identity hook writes its stamp, `specialist-handoff.sh` takes a
    lock — and **not one of those write actions is a registered control at any
    authority**. That is a coverage gap, and closing it means writing new
    entries, which is registration, which is the operator's. **Whether Class A
    should license `execute`** and **whether that control should move** are
    recorded and answered nowhere.
  - **27 `evidence_refs` silently drifted, and the guard caught 7.** Inserting
    lines into the three tools moved every `path:line` citation below the
    insertion. `VACUOUS-REF` flagged only the **7** that happened to land on a
    blank or comment line; the other **20** landed on live code and cited the
    **wrong** line while passing every check. All 27 were repointed by
    **recomputing against base content**, not by shifting numbers, and every ref
    now cites byte-identical content to before. This is the hazard `MISMATCHES.md`
    already names — a citation guard that checks *resolvability* cannot check
    *identity*.
  - **`active_packet.md`'s SHAPE is load-bearing, and base was already red.**
    `./build-os/maintenance/run-tests.sh` was **143/144** at the base commit, not
    the expected 144/144: `rotate-memory.mjs` splits that file on `^## ` and the
    two-pass rotation proof needs **≥3 blocks**, while the previous close left it
    with **2**. Repaired by giving this packet's declaration real sections. The
    sharper hazard is recorded where the assertion states it — **a count of 0
    means the delimiter never matches and nothing can ever rotate out of the
    file** — so a prose-only rewrite of that file could disarm its own rotation.
    **It does not do so *silently*, and the earlier wording here saying it did
    was wrong.** Measured: a zero-block file is byte-identical after `--apply`,
    the exit code is **0**, and **no test fails** — but `rotate-memory.mjs`
    prints `WARNING: <path>: the block delimiter /^## / matched NOTHING …
    NOTHING CAN EVER ROTATE OUT OF IT` to stderr. That warning is present at the
    base commit too and `rotate-memory.mjs` was **not touched** by this packet.
    So the failure mode is precisely **an ignorable warning** — loud enough to
    read, attached to no exit code and no assertion — which is a real hazard and
    a different one from silence.
  - **Declaration-before-build is now attested by git, with no third commit.**
    The previous close recorded a genuine tension: the packet must be declared
    before the first edit, but with the declaration in the same commit as the
    build git cannot corroborate the ordering, and the cap is two commits. It
    needs neither a third commit nor a hook — **Commit 1 was spent on the
    declaration alone**. Nothing required the docs to be the second commit.
    `bandwidth.active_packet_singleton` still refuses **two** declared packets
    and permits **zero**, so the floor remains unbuilt.

- **The two `refuted` controls were taken to the four outcomes, and both came
  back "no change" — one of them because demoting it was MEASURED to destroy
  live memory.** `refuted` is the only evidence state where the question looks
  settled: measured, and found not to discriminate. It caps at `observe` at any
  class, so the two controls carrying it read as the census's most obvious
  demotions. Both readings were wrong, for different reasons, and the packet
  changed **no class, no authority and no `empirical_status`**. Suite
  **1617 passed**, 0 failed (+14 in the evidence-policy suite, +6 in the
  maintenance suite). `evidence-policy.sh` still reports **19 of 81** out of
  licence, split **6/5/8** — unmoved, which is the correct result for a packet
  that re-authorised nothing.
  - **`maint.tripwire_coverage_scan`: the demotion was applied and measured, and
    it cost the layer its only prevention.** `COVERAGE-GATE-PREVENTION-DIFFERENTIAL`
    (`tests/build_os_maintenance_tests.sh` §6a) runs two arms against an uncovered
    suite file that rewrites real memory, differing only in that `throw`: gated →
    **exit 1, tree untouched**; demoted to a print → **exit 1, tree destroyed**.
    **The exit code is 1 in both arms**, so nothing watching exit codes can see
    the difference at all — only the tree can. The entry's own
    `demotion_requirement` had *prescribed* that demotion; it now records what it
    was measured to cost. The gate stands and **the mismatch stands with it**:
    keeping a gate is not a claim to be in licence.
  - **Evadability is not non-discrimination.** The refutation is *path-scoped* and
    one unqualified token cannot say so: `refuted` records that the **detection**
    claim failed under a bare `node --test`; under the sanctioned command the same
    scan is measured **prevention**. The defect it exists against was an accident
    — a suite file with no tripwire, destroying live memory at exit 0 — and
    against that it discriminates exactly.
  - **`maint.source_scan_mask`: the finding is real and its remedy is
    unreachable.** It is one of the five findings only the evidence axis can see
    (Class C licenses `advise`, so it carries no declared mismatch). But `observe`
    is defined as *"it measures and records. Nothing reads the result"* — and two
    controls read its result, which is why it is `load_bearing`. Demoting it would
    not lower its authority, it would write a falsehood; retiring it breaks both
    consumers; its own `promotion_requirement` forbids improving the evidence; and
    a defeatable lexer really is a heuristic. All four outcomes closed.
  - **New guard: `OBSERVE-LB`.** `scan-controls.sh` now refuses any entry claiming
    `load_bearing` at `observe` while naming a consuming policy, because those
    cannot both be true. It exists so an evidence cap cannot be applied as an
    instruction — the cap is a finding about a control, not a spelling for it.
    Red-driven in `tests/evidence_policy_tests.sh` §20b, clean arm first.
    **Its radius is the whole census, not one control:** it forecloses `observe`
    for **67 of 81** controls — every `load_bearing` entry naming a consumer —
    and **0 of 81 sit at `observe` today**, so the evidence axis's
    `refuted → observe` cap has **no legal spelling for any wired-in control**.
    README §2 compounds this by defining **both** bottom rungs by
    non-consumption (`none` = "nothing consumes it", `observe` = "nothing reads
    the result"), leaving no rung for *"it is read, but may cause nothing."*
    Whether the guard is correctly placed is the operator's design call; it is
    recorded here, not moved.
- **The operator finally has an artefact to grant authority in — and the licence
  table gets a third `MIN` term.** `MISMATCHES.md` has said, fourteen times, that
  re-authorising a control is a governance action belonging to the operator.
  **The operator had no mechanism to perform one.** No artefact in this
  repository let a human write *"this control may exercise this authority, on
  this basis, until this date, and here is where it lands when the lease ends"*.
  A rule naming an act nobody can carry out is not a rule with a gap in it; it is
  a rule that has never been available.
  `build-os/registry/authority_envelopes.txt` is that artefact — fourteen
  required fields, one per line, blank line between records, the census's own
  shape. **Leases end:** an authority granted with no `expires` is a permanent
  re-authorisation with a date on it. Census **78 → 81** entries, `evidence_refs`
  **274 → 287**, authorities **66 → 68 `gate`** and **12 → 13 `advise`**.
  `CROSSWALK.md`'s six machine-reconciled columns were recomputed, not edited:
  **81 bindings**, `agency` **4 → 5**, `epistemic_quality` **24 → 25**,
  `homeostasis` **21 → 22**. Suite **1597 passed**, 0 failed
  (+91 `tests/authority_envelope_tests.sh`, +21 in the evidence-policy suite).
  - **It ships empty of grants, and that is the point.** Creating the first grant
    is a governance act; a packet that shipped the mechanism *and used it* would
    have re-authorised something by writing the tool that permits
    re-authorisation. The worked example lives **entirely inside comments**,
    because an example a parser can see is a live grant wearing a label. Zero
    uncommented records, checked.
  - **The third axis, and why two were not enough.** `class` asks what *kind* of
    thing is checked; `empirical_status` asks whether the check *works*. Neither
    asks the question an operator must answer before switching anything on:
    **what happens to the output?** A control whose ranking nothing consumes and
    one that silently reorders the work queue are *indistinguishable on both
    existing axes*, and they are not the same risk. `deployment_mode` separates
    permission to **rank** from permission to **choose** from permission to
    **act**:
    `shadow → observe` (produces output, nothing consumes it);
    `human_confirmed → advise`; `bounded_autonomous → rank`;
    `autonomous → gate`. Composition becomes
    **`L_effective = MIN(L_class, L_evidence, L_deployment)`**.
  - **An envelope can only *lower* `L_effective` — and that is the best property
    here.** Because the composition is a minimum, **an envelope can never raise a
    control above `L_class` or `L_evidence`**; `autonomous` caps at `gate`, the
    top of the ladder, and every other mode is strictly below it. The validator
    refuses to launder a Class-C control into a `gate` *even when the operator
    signs the grant*: granting `gate` to `adoption.lane_size_check` reports
    `OVER-GRANTED … binding-axis=class`, and the matrix still calls that control
    out of licence, byte-identically. **So the fourteen
    `authority_mismatch: declared` controls cannot be cleared by writing fourteen
    envelopes** — the store *records and composes* a grant, it does not
    *legitimise* one. Clearing them needs a class change, a change in
    `empirical_status`, a change to the licence table, or an instrument that does
    not exist yet. Stated at all three sites that describe the axis, because §3b
    opens by saying the operator had no mechanism and this is it — which reads,
    wrongly, as a licence to promote.
  - **The axis's *owner* is pinned, not just its copy.** `evidence-policy.sh`'s
    restatement of `DEPLOYMENT_AXIS` was reconciled against README §3b (§5b of
    the evidence-policy suite), but `authority-envelope.sh` — the file that
    *defines* the axis — was pinned by nothing: changing `shadow:observe` to
    `shadow:none` there, leaving README saying `observe`, left both suites fully
    green. §2a of the authority-envelope suite now reconciles the owner against
    README §3b and against the consuming copy, and is **driven red** by exactly
    that mutation (**89 passed / 2 failed**, restored to **91 / 0**). Same
    unchecked-duplicate defect as §3a's cap column, one file along.
  - **Two of those caps are consistency requirements, not preferences.**
    `human_confirmed` may not reach `rank` **by the ladder's own definition of
    `rank`** — the rung that orders work or selects between options *with no
    human in the loop* — so a mode whose entire content is "a human confirms"
    cannot license the rung that means "no human confirms". And
    `bounded_autonomous` may not reach `gate`, because `gate` is the *unbounded*
    stop and "bounded" is the refusal of exactly that.
  - **The default is `autonomous`, and the defence matters more than the value.**
    Every control in the census predates this axis. **No additional cap is the
    only default that leaves the finding set where the operator put it**; any
    other demotes the entire census in a single commit with no operator in the
    loop — precisely the self-re-authorisation this machinery exists to prevent.
    A permissive default is normally the wrong instinct; here the conservative
    direction is *change nothing*, not *cap everything*. The cost, stated: the
    axis is **opt-in** and inert until an operator writes a record, and nothing
    here can *discover* a deployment mode.
  - **The safety property is proved, not asserted.** §18 of the evidence-policy
    suite runs the matrix against the live envelope store and against an empty
    one and requires every finding line to be **byte-identical**; reconciles the
    split against the census's own count of `authority_mismatch: declared`
    rather than a typed constant; and requires that **no live finding is bound by
    the deployment axis**. **19 out of licence, 14 + 5, the same control ids,
    unchanged.** §18a drives the other half red — a fixture under `shadow` *is*
    capped and the control beside it with no envelope is not — because a test
    that only proved "nothing changed" would pass equally well against a term
    that was never wired in.
  - **The authority decision: `envelope.grant_composition` ships Class C at
    `advise`, `authority_mismatch: none`.** A validator that *gated* would be
    enforcing a governance scheme over **zero live grants** — vacuous authority
    over an empty set, able to fire only on the operator's own first attempt to
    use the mechanism, which is the worst possible moment to refuse. And new
    Class-C controls ship at `advise`, with promotion a separate governance
    action — the precedent this packet is literally about.
  - **The one exception mirrors `evidence.derivation_nonvacuity`.**
    `envelope.derivation_nonvacuity` (Class A, `gate`) refuses an absent or
    unparseable store, a missing required field, a duplicate id, a backwards
    lease term, a field the schema has no slot for, or **an unknown
    `deployment_mode`** — the sharpest, because the deployment term is a `MIN`
    term and reading an unknown value as "no cap" would silently license
    everything the store exists to bound. Ten refusal states driven red, plus
    five unknown modes including the operator's own prose spellings
    `human-confirmed` and `bounded autonomous`, each refusing with the accepted
    spellings named so the fix is readable from the refusal. **The refusal
    propagates**: `evidence-policy.sh` quotes it and refuses in turn rather than
    composing a term it could not read.
  - **Zero grants is the correct state, not the shelfware state** — the one place
    the census's vacuity rule is deliberately *not* copied. An empty control
    registry is an unclassified system wearing a registry; an empty *envelope*
    store means **nothing has been re-authorised**. So zero reports and exits 0,
    while an **absent** store still refuses: absent is not empty, and reading a
    missing file as "no grants" gives the permissive answer to a question that
    was never asked.
  - **Recorded, and deliberately not resolved: the S1 collision.** The sanctioned
    launch declaration `heuristic_policy` / `untested` / `rank` / `shadow`
    **cannot be produced by `min()`** — Class C licenses `advise` and `rank` is
    strictly above it. *Reading 1:* S1 ships carrying `authority_mismatch:
    declared`, the fifteenth, consistent with the fourteen already reported.
    *Reading 2:* `shadow` means the ranking has no consequence, so
    `runtime_authority` is measuring the wrong property and the ladder
    **conflates signal strength with whether anything consumes the signal**.
    **Both recorded, neither adopted** — adopting reading 2 would *redefine the
    ladder*, which is a governance change and not a build decision. The suite
    enforces the non-adoption: `shadow` must still cap below `rank`, so a silent
    adoption fails rather than passing as a refactor.
  - **`untested` is declared pending and is not implemented.** The operator ruled
    `untested` (has not yet produced live outputs) and `unvalidated` (has
    operated, lacks outcome evidence) meaningfully different. That distinction is
    **not built**: `untested` is absent from the evidence axis, has no cap row,
    and a control carrying it is still **refused at exit 2** — driven red, not
    claimed. Adding a token so a planned control fits is the failure the registry
    exists to prevent, so the sixth token is the single decision the next packet
    must take.
  - **Nothing is re-authorised.** No existing control's `class`,
    `runtime_authority`, `authority_mismatch` or `empirical_status` changes, and
    **no grant exists for any control**. Pre-existing stale numbers were found
    and corrected on the way — the registry's stated `274` `evidence_refs`, and
    `homeostasis`'s binding counts, which were restated in prose in four separate
    places (`CROSSWALK.md`'s ranked list, twice; the crosswalk's `binding_quality`
    note; and `meaning_metric`'s `known_limitations`) and were stale in all four.
    **The two are not alike, and the difference is the whole lesson.** The
    `evidence_refs` total **is** machine-pinned — `tests/control_registry_tests.sh`
    §25 derives every stated ref total from the live count and red-drives itself —
    which is why that one could not stay wrong. The `homeostasis` counts are
    hand-written prose that no test reconciles against the table it restates,
    which is exactly why they went stale in four places at once. `CROSSWALK.md`'s own
    bound/inst table *is* recomputed and did not drift; the §4 prose beside it
    did. A checker for prose that restates a machine-computed table is the
    highest-value open follow-on, and it is not built here.

- **The licence table gets a second axis: `class x empirical_status -> licensed
  authority`.** README §3's table licensed on **class alone**, so a control's
  `empirical_status` — whether anybody ever established that the check *works* —
  licensed nothing and forbade nothing. Under it a control **measured and found
  not to discriminate** could stop a build with no rule objecting. §3a adds the
  evidence axis and composes the two by **`licensed = MIN(class-licensed,
  evidence-licensed)`**: a control may do what *both* allow. Census **75 → 78**
  entries, `evidence_refs` **257 → 274**, authorities **64 → 66 `gate`** and
  **11 → 12 `advise`**. `CROSSWALK.md`'s six machine-reconciled columns were
  recomputed, not edited: **78 bindings**, `epistemic_quality` **22 → 24** and
  `homeostasis` **20 → 21**. Suite 1418 → **1485 passed**, 0 failed
  (+67 `tests/evidence_policy_tests.sh`).
  - **The sharp rule: `refuted` may not `gate`, at any class**, and caps at
    `observe`. It is the one rule here that resolves a real defect
    *mechanically* rather than by judgement. **Class cannot rescue it** — class
    is a claim about the KIND of thing checked, evidence a claim about whether
    the check WORKS, and a hard invariant whose test does not detect violations
    is an *unchecked* invariant, not a well-classified one. `observe` rather than
    `advise` because presenting a signal *known* to be dead to a decision-maker
    who cannot see that is worse than recording it and letting nothing read it.
  - **The expensive rule: `unvalidated` caps at `advise`.** Not `rank`, because
    `rank` orders work with **no human in the loop** — an unverified signal
    silently choosing what happens next differs from one stopping a build only in
    how loudly it fails. This is the rule that costs, and the count is the
    finding, not a reason to soften it.
  - **`red_driven` is deliberately NOT capped.** A red drive establishes the one
    property a gate structurally needs — *that the check can fire*. Its real
    weakness, silence when it should not be silent, is at **Class C** a question
    about a chosen threshold, which is the **class** axis's job, so capping here
    too would charge the same weakness twice. **The known limit, stated rather
    than implied away: that argument fails at Classes A and B**, which carry no
    fitted threshold for the class axis to charge — a red-driven Class-A check
    that only detects the shape its author planted is charged by *neither* axis,
    so at A and B the rule rests on the consequentialist half alone, which is
    where the principled half is weakest. The consequentialist half, derived:
    capping `red_driven` at `advise` would put **66 of 78** controls out of
    licence in one edit, **47 of them newly** — a matrix that flags nearly
    everything discriminates nothing. (**53** is a different number: the count of
    controls whose `empirical_status` is exactly `red_driven`, which is what
    `CROSSWALK.md` uses it for.)
  - **A finding for the operator: step 4 (S1) collides with this axis, twice.**
    S1 is slated to arrive at `runtimeAuthority: rank` with
    `empiricalStatus: untested`. At `rank` on evidence that establishes nothing it
    **ships out of licence on day one** under the expensive rule; and `untested`
    is **not one of the five evidence tokens**, so
    `evidence.derivation_nonvacuity` would **refuse the whole derivation at exit
    2** rather than flag S1 — an unrecognised level must never fall through to
    permissive. Both are named here and **neither is resolved**: choosing between
    "add `untested` as a sixth token" and "S1 arrives carrying `unvalidated`" is a
    governance action for the operator, and adding a token to make a planned
    control fit is exactly the move this axis exists to make visible.
  - **Comma-composites resolve by MINIMUM, so `refuted` dominates.** A later
    refutation *supersedes* an earlier red drive, and the minimum encodes that
    without needing a timestamp the format does not carry. `red_driven,refuted`
    licenses exactly what bare `refuted` does.
  - **THE FINDING — 19 of 78 out of licence, derived on every run and stored
    nowhere.** No control id appears in the tool's source; a hand-maintained list
    decays the way `PACKET_FILES` and MISMATCHES.md §10's table did. **14** are
    the class axis's existing declared mismatches, reproduced exactly. **5 are
    visible only to the evidence axis**, and they are the point: four **class-A
    gates on `unvalidated` evidence** — `maint.tripwire_armed_precondition`,
    `maint.rotate_node_precondition`, `tools.handoff_lock`,
    `tools.capability_profile_usage` — each carrying `authority_mismatch: none`
    *because the class table licenses them*, plus `maint.source_scan_mask`, which
    advises on `refuted` evidence. **One control gates on `refuted` evidence**,
    `maint.tripwire_coverage_scan`; it is already declared, but the declaration
    **understates** it — class caps it at `advise`, evidence at `observe`.
  - **NO composite score, and there will not be one.** Blending the axes would
    need weights nobody here can derive and would hide **which axis is
    saturated**. Both are printed on every finding, with the axis that binds it
    named — the same refusal `bandwidth-check.sh` makes one layer along.
  - **THE AUTHORITY DECISION, AND IT IS THE LOAD-BEARING ONE: the matrix ships
    at `advise` and MUST NOT gate.** `evidence.policy_matrix` is Class C,
    `advise`, `authority_mismatch: none`. It is **chosen policy, not a
    definition** — a matrix that *gated* on the rule "chosen thresholds may not
    gate" would be self-refuting exactly as `bandwidth.active_packet_singleton`
    was found to be. Gating would demote **19 controls immediately and
    automatically**, the system re-authorising itself with no operator in the
    loop, and the authority envelope that would make that legitimate **does not
    exist yet**. And it follows the precedent the reviewer endorsed: new Class-C
    controls ship at `advise`; promotion is a separate governance action.
  - **NOTHING WAS RE-AUTHORISED.** No existing control's `class`,
    `runtime_authority`, `authority_mismatch` or `empirical_status` changed.
    Naming what is out of licence is not demoting it.
  - **The one thing it refuses** is a derivation it cannot trust
    (`evidence.derivation_nonvacuity`, Class A, `gate`): an absent registry, a
    registry parsing to zero controls, or a stanza carrying an evidence token the
    matrix has no row for — because an unrecognised level must never fall through
    to permissive. It earned its keep on its first run: an off-by-one in the
    field parser made all 75 live stanzas unclassifiable, and it refused rather
    than reporting a clean licence for the entire census.
  - **A field-order oddity, checked and dismissed.** An earlier `awk` pass
    suggested one stanza carried `empirical_status` without a preceding
    `runtime_authority`. All **78** stanzas share one identical 17-field order,
    in which `empirical_status` precedes `runtime_authority` **everywhere**. Not
    a malformed entry; an artefact of the scan.
  - **`tests/evidence_policy_tests.sh` — 67 assertions, chained.** It drives the
    claims that would otherwise be the author's word: `check` exits 0 on a
    violating registry **and on the live one, which violates the matrix**; the
    sharp rule is driven across **all five classes**; the class axis is read back
    **out of README §3** and the evidence axis's levels out of `scan-controls.sh`'s
    `EMP_STATUSES` *and* the tokens occurring live, so neither axis can be
    invented; and the registry is byte-identical after a run.
  - **§5a, added on review: the evidence axis's CAPS are reconciled too.** The
    first version reconciled the class table and the evidence *levels* but left
    README §3a's **cap column** an unchecked duplicate of the tool's
    `EVIDENCE_AXIS` — a README saying `unvalidated -> gate` against a tool capping
    it at `advise` left the whole suite green. That is the same drift surface that
    put a stale count in three files at once, so it is now diffed in both
    directions and red-driven both ways: a cap changed to another rung fails the
    diff, a cap changed to a non-rung fails the row count.

- **Two census gaps closed: the egress scan is registered, and
  `integration_bandwidth` gets its first controls.** The crosswalk found both.
  Census **71 → 75** entries, `evidence_refs` **235 → 257**, authorities
  **61 → 64 `gate`** and **10 → 11 `advise`** (`rank` and `observe` remain
  **0 of 75** — the ladder is still used at two rungs of five). All six
  machine-reconciled columns of `CROSSWALK.md` were recomputed, not edited:
  75 bindings, **29 instantiate / 40 proxy / 6 nominal**, and **8 of 17**
  primitives now hold at least one instantiating binding.
  - **`entitlement.egress_scan` — Class A, `gate`, `red_driven`.** A real
    security invariant was already running inside `tests/entitlement_tests.sh`:
    it greps the entitlement packet's twelve files for network calls, carries a
    **planted `curl` positive control** and a **prose negative control**, and
    floors its own coverage. It owned no entry. The census's only view of it was
    the suite's `RESULT` line plus its vacuity floor — so the registry could see
    *this scanner is not blind* and could never see *nothing performs egress*.
    That is README §4's known hole #1, *"a new control added inside an
    already-registered file"*, **closed for the instance that motivated the
    disclosure**; the hole itself is structural and stays open.
  - **`ethical_admissibility` comes off nominal-only for the first time.** The
    egress scan **instantiates** rather than proxies: unlike every binding under
    `boundary`, the prohibited *act* never occurs — only the code that would
    perform it, and that code cannot land while the suite is chained.
  - **THE RULING, AND IT IS NOT A CAVEAT.** This control **does not enforce the
    external boundary**. *Never push, merge, deploy, publish or touch secrets*
    is enforced by the operator's **permission system**, a process boundary
    outside this repository — and that is the right place for it, because
    anything that could bypass the permission system bypasses a repo-side check
    trivially, so a repo-side gate would convert a real external boundary into a
    checkbox that looks enforced and is not. The scan reads a fileset. Both
    artefacts say so, and two suites assert that they still say so.
  - **`build-os/tools/bandwidth-check.sh` — the first controls that limit what
    may be ABSORBED rather than judge what already exists.** Every other entry
    in the census answers yes/no about an artefact already written, which is why
    `rank` is held by nobody. **Each capacity dimension is enforced separately;
    there is no composite load score** — the weights would be unjustifiable and
    one number hides *which* dimension is saturated, so every ceiling carries
    its own authority and every refusal names its dimension.
    - **`packets`** — `bandwidth.active_packet_singleton`, **Class C at `gate`,
      mismatch declared** — and it is the fourteenth entry in `MISMATCHES.md`
      because it was **argued down, not registered there**. It went in as Class A
      on the claim that its ceiling is `active_packet.md`'s own *definition*
      ("the one packet currently in flight") rather than a fitted number. Review
      rejected that: **"one packet at a time" is nowhere in `CLAUDE.md`** — it
      exists only in the prose header of the very file the control reads, which
      makes it a WIP limit somebody chose, and the packet's own crosswalk record
      had already called it one in order to earn its binding. The tempting escape
      — that §10 excludes `N <= 1` from the fitted-constant family — **does not
      apply**: that rule covers coverage *floors* in `tests/*.sh`, and this is an
      upper bound on permitted state inside a tool, compared in the refusal
      direction. Same numeral, opposite direction. **The authority was left at
      `gate`**, because clearing a mismatch by re-authorising the control is the
      operator's decision and not a reclassifier's. `MISMATCHES.md` §14 carries
      the full argument. Zero is a legitimate idle state; an absent artefact
      reports `UNOBSERVABLE` and does **not** refuse, which also means deleting
      the file evades it — recorded, not closed.
    - **`commits`** — `bandwidth.packet_commit_ceiling`, Class C, **`advise`**,
      and deliberately not a gate. Two commits per packet is a constant the
      working contract chose; nothing measured it, and **a heuristic does not
      become a gate by being useful**. It reports the breach and exits 0. The
      base is self-declared by the agent it constrains, so only its
      *resolvability* is checkable — anything else reports `UNOBSERVABLE`
      rather than a count against a guessed base.
    - **`write_sets` — DECLINED.** Observable from a fan-out manifest, but **no
      ceiling on concurrent write sets is declared anywhere**, and enforcing one
      would mean inventing a constant.
    - **`depth` — DECLINED.** Rounds and serial agent stages are
      **transcript-only**; nothing in git attests to them. **A control that
      claims a limit it cannot observe is worse than an absent control**, so the
      dimension is printed as declined, with its reason, on every run.
  - **Red-driven throughout.** Two packets in flight refuses naming the
    dimension; three commits reports `EXCEEDED` and still exits 0, so the
    `advise` claim is executed rather than asserted; four fixtures prove
    `UNOBSERVABLE` is reported rather than faked; each new binding removed trips
    the anti-omission guard; the egress control deregistered from the census
    trips both the binding-count and the ghost check. The ceiling constant is
    read back from the line the census cites, so tool and registry cannot drift.
  - **No fitted `-ge N` was added.** Every new floor is derived from the artefact
    it measures, so `tests.nonvacuity_minimums` is unchanged at 34 members and
    §21's tree scan still reconciles.
  - Suite 1338 → **1418 passed**, 0 failed (+41 `tests/bandwidth_tests.sh`,
    +25 crosswalk, +14 registry). `scan-controls.sh check` exits 0.

- **A Neurocosmology crosswalk: what each control is FOR.** The registry says
  what kind of evidence a control is and how much authority it exercises; it
  could not say what universal function the control instantiates.
  `build-os/registry/neurocosmology_crosswalk.txt` binds each of the **71**
  registered controls to exactly one of **17** primitives — reachability,
  meaning metric, mass, valence, agency, energy, homeostasis, integration
  bandwidth, boundary, ethical admissibility, epistemic quality, latent state,
  durability, gated plasticity, collective coherence, goal ecology, wisdom — and
  records, per primitive, what the bindings **miss**. It is a **separate stanza
  file, not an 18th field** on each control record: a census must not be edited
  by an interpretation, the load-bearing `known_limitations` field is
  per-primitive rather than per-control, and keeping each binding's class and
  authority as a **deliberate copy** is what makes a one-sided edit detectable.
  - **No mathematics was implemented.** No Φ, no coherence measure, no goal
    ecology, no value-of-information term, no learned model; no control created
    and no authority granted. A conceptual equation must not control production
    before its quantities are computable. A test asserts the artefact is inert
    data and owns no control.
  - **The finding is which slots are EMPTY.** `runtime_authority: rank` — the
    tier that exists to order work or select between options — is held by
    **0 of 71** controls; 61 gate, 10 advise, and every one answers yes/no about
    an artefact that already exists. So **`meaning_metric`, `valence`,
    `goal_ecology` and `integration_bandwidth` have zero bound controls**, and
    `mass` and `wisdom` carry one **nominal** binding each: the only ordering in
    the system takes `inputs: none`, and the only control that selects gets no
    outcome feedback. `integration_bandwidth` is the one nobody predicted — the
    whole theory of work-in-flight (one packet, ≤2 commits, a bounded fix round)
    is prose in `CLAUDE.md` and not a registered control.
  - **The coverage is deliberately not flattered.** Of 71 bindings only **27
    instantiate**; 38 are proxies and 6 are nominal, nominal is recorded as
    information rather than as coverage, and **only 6 of the 17 primitives hold
    even one instantiating binding**. `homeostasis` holds 19 bindings and
    exactly **one** instantiates, because 14 are `red_driven` test suites and a
    green suite is evidence that *planted* defects are caught.
    `epistemic_quality` holds 22 and its entry says plainly that the count
    overstates the contact: 46 of 71 controls are `red_driven`, 3 are
    `field_observed`, one is `refuted`.
  - **The count got worse on review, and that is the working direction.** The
    first draft read 32 / 36 / 3. Review demoted **eight** bindings — five from
    `instantiates` to `proxies`, three from `proxies` to `nominal` — in every
    case because the label disagreed with the entry's own `known_limitations`,
    which had already conceded the gap. That is the exact defect the crosswalk
    exists to catch, found inside the crosswalk. It takes `boundary`,
    `durability` and `energy` to **zero instantiating bindings** and makes
    `reachability` and `ethical_admissibility` **nominal-only** alongside `mass`
    and `wisdom` — four primitives whose entire coverage is, by this file's own
    rule, not coverage.
  - **Sharpest result:** `ethical_admissibility` has one binding, a provenance
    check. The strongest rule this system states about itself — never push,
    merge, deploy, publish or touch secrets without explicit go — has **no
    registered control**. The one real security invariant, the egress scan,
    lives inside `suite.entitlement` and is not separately registered, which is
    the registry README's known hole #1 stated in this framework's vocabulary.
  - Pinned by `tests/neurocosmology_crosswalk_tests.sh` (**40** assertions, 10
    red drives) with membership **derived from the census in both directions**,
    so a control added to the registry and never bound fails. **Every cell** of
    the coverage table — `bound`, `inst`, `proxy`, `nom`, `classes` and
    `authorities` — is recomputed from the artefact, after review found that
    reconciling only the first two left a row free to claim `authorities: rank`,
    a tier **0 of 71** controls hold, and still pass. Three existing guards
    fired on this packet's own work and were obeyed rather than worked around:
    `scan-controls.sh` demanded the new suite be registered (entry 71), and §21
    caught a fitted 120-character floor inside it and then a fitted `-ge 2` in
    the new reconciliation's own red drive — both now derived, not fitted.

- **A control registry, with the actual instances.** `build-os/registry/`
  classifies all **71** consequential controls that already run in this
  repository: evidentiary class (`R` research / `A` hard invariant / `B`
  deterministic metric / `C` heuristic policy / `D` learned model), separately
  declared implementation status, empirical status, the runtime authority each
  one **actually exercises** (`none < observe < advise < rank < gate`), its
  nervous-system role, the policy that consumes it, and a `path:line` citation
  of the code that gates. The store is one field per line — greppable, diffable
  at field granularity, readable by an agent with no parser — for the same
  reason `packet_metrics.tsv` is a TSV, at a shape where a 17-column TSV would
  not be readable.
  - **The finding, in `build-os/registry/MISMATCHES.md`.** Three numbers, each
    with the one-line derivation beside it: **11 of the 71 gate on `unvalidated`
    evidence** — eleven controls can stop the build and nothing has established
    that any of them discriminates, which is the sharpest of the three;
    **13 of the 71 exercise `gate` on a class that does not license it**; and,
    because an entry is not a line, **55 distinct fitted constants, thresholds
    and prose regexes** across those 13 entries. The lane size check refuses work
    on the median of a four-packet sample; the real-memory tripwire's coverage
    scan calls itself "a convenience check, not a boundary", prints the one-line
    source shape that beats it, and then throws; three chosen durations decide
    whether one process may break another's lock; **34** "not vacuous" minimums,
    in 12 test suites, are the counts that existed the day they were written —
    including the one gating this packet's own suite. Every one is listed with
    the line that gates. **They are recorded, not repaired** — re-authorising a
    control is a governance action for the operator, not a builder's edit.
  - **The rule against laundering is now a check, not a sentence.** "Do not clear
    a mismatch by changing the class" was stated in three headers and enforced
    nowhere: relabelling `tools.supervise_timeout` `class: A` with
    `authority_mismatch: none` left `scan-controls.sh check` at exit 0, silently,
    while `MISMATCHES.md` went on naming it. Section 8 closes it by reading the
    report's summary table back as an **anchor** — every control named there must
    still be `declared`, and every declared control must appear there — so
    clearing a mismatch costs an edit to the accusation, in prose, where a
    reviewer reads it. Red-driven in both directions, plus the blinded-table
    case.
  - `scan-controls.sh` reconciles the registry against a non-cooperative scan of
    the tree: every file that can terminate a run non-zero must own a `gate`
    entry, and every `gate` entry must own such a file, so a gating control added
    in a new file with no registration fails. Its largest hole — a control added
    inside an already-registered file — is named rather than implied away. The
    registry classifies its own scanner and its own suite, and lists the
    scanner's discovery rule as over-authorised.
  - **No mathematical system was built.** No potential functional, coherence
    measure, goal ecology, value-of-information calculation, completion
    probability, causal attribution, learned risk model, adaptive threshold or
    manifold state. The registry is the census that would have to precede any of
    that; it is not a down payment on it.
  - **The family entry is reconciled against the tree, not against itself.**
    `tests.nonvacuity_minimums` groups a dozen suites' vacuity floors into one
    record, and its first version cited 5 lines and claimed 6 constants where
    there were 34 — a census undercounting itself by 28, in the entry whose
    subject is undercounted heuristics. `tests/control_registry_tests.sh` §21 now
    executes the membership rule instead of trusting it: rescan `tests/*.sh`,
    subtract three exclusions that must each be justified in `MISMATCHES.md`, and
    fail if the result differs from the entry's `evidence_refs` in either
    direction. §22 fails if any `path:line` is claimed by two entries — which is
    how `tests/pilot_kit_tests.sh:97` came to be classified both `C`/declared and
    `A`/none at the same time.
  - **A citation must land on something — the hand sweep, converted into a
    check.** The registry carries 233 `evidence_refs` and, until now, nothing
    machine-checked that one pointed at anything meaningful: they were verified
    to be *inside* the file and nothing else. So a citation could satisfy
    "cites evidence" **vacuously** — two entries cited `#!/usr/bin/env bash`,
    one cited `/**`, one cited a header comment, and one was off by one onto the
    comment above the line it meant. Each verification round found more of them
    by hand and cast a wider net than the last, which is what a hand sweep over
    two hundred citations does. `scan-controls.sh` now refuses a ref resolving
    to a **blank line, a comment-only line, a shebang, or a lone closer**
    (`fi`, `done`, `esac`, `else`, `}`, `)`, `{`, `]`, `;;`) as `VACUOUS-REF`,
    red-driven in both directions: a ref repointed at a comment fails, and a ref
    at a constant's **definition** still passes, because a threshold control is
    often best cited at the line that defines its number. **What it does not
    catch is stated rather than glossed:** any statement that is not a decision
    — an `echo`, an assignment, a bare call — passes. Against the defect that
    motivated it, it catches two of the three bad `tools.supervise_timeout` refs
    and not the `echo`. The exemption route, `EVIDENCE_VACUITY_ALLOW`, is
    greppable and printed by `scan-controls.sh patterns`, and is empty.
  - **Three artefacts stated the ref total and all three were wrong** — 218, 184
    and 184 against a live 224 — because each was a hand count frozen at a
    different moment. The two prose copies now state no total; the README states
    one and §25 recomputes it from the registry and fails on disagreement.
  - **Two anchor defects.** A control's row pasted **twice** into
    `MISMATCHES.md`'s summary table passed at exit 0 and raised the reconciled
    count, because the count counted rows rather than distinct ids; duplicates
    are now refused and the count is distinct. And the report's own justification
    for excluding one line from the non-vacuity family was **false** — it claimed
    a double classification that does not exist — so it is restated on the ground
    that actually holds (a string-length floor, not a coverage floor). The
    membership count of 34 is unchanged.
  - **A fifth thing the reconciliation does not cover, now named.** An entry can
    shed authority without relabelling its class, by **narrowing its
    `evidence_refs`** until the line that gates is outside its declared scope.
    That is the same edit as a legitimate re-scoping — it is what corrected the
    `suite.*` entries here — and only the `-ge N` family is policed against the
    tree. Recorded in the README and in `scan-controls.sh`'s header beside the
    other four.
  - Pinned by `tests/control_registry_tests.sh` (78 assertions), chained from
    `tests/build_os_tests.sh`. Twenty-two red drives, including `load_bearing`
    with no consuming policy, Class `D` at `gate`, an unregistered control
    planted in the tree, a blinded scan, a mismatch cleared by relabelling, a
    report accusing an unclassified control, an id certifying itself reported off
    a longer id's row, a duplicated anchor row, and a citation repointed at a
    comment.
- **`init-build-os.sh` seeding leak.** `init-build-os.sh` seeds a new project's
  scaffolds from **this repository's live memory files**, so a customer's fresh
  `build-os/` can arrive carrying this repo's state. The defect is documented in
  `build-os/maintenance/PORTING.md` (flagged `BLOCKED`); the maintenance layer
  released in `0.1.0` did not add to the leak — its two scaffold additions come
  from clean templates — and did not fix it. A fix is being built in a sibling
  packet in the same session as this release and is **not** part of `0.1.0`.
- Release metadata itself (this file, `VERSION`, `LICENSE`) and the refreshed
  `build-os/memory/` snapshot.
- **Enforced lanes and parallel-by-default.** Proportionality stops being
  advisory prose: five lanes each carry a required gate-set and a numeric round
  budget (`tiny` = builder-lite + one check, no qa/reviewer/archivist, 2 rounds
  max), escalation costs a stated reason while de-escalation is free, and a
  fan-out is legal only with a disjoint file-ownership manifest, a merge plan,
  and the merger owning the hot files. External mutation stays hard-gated in
  every lane. Pinned by `tests/lane_enforcement_tests.sh`, which fails on drift
  between the router and the orchestrator, not merely on absence.
- **Customer scaffolds seed from `templates/`, not from live memory.** All three
  seeding paths (`init-build-os.sh`, `install-project.sh`, and the user-scope
  router in `install-global.sh`) now copy clean templates; the seeded router goes
  from 23,404 B of one account's connector inventory to 8,372 B of structure with
  zero connector rows. A shipped `tool_router.example.md` carries the teaching
  value using fictional tools. Pinned by `tests/scaffold_seeding_tests.sh`,
  including a canary that plants a fake connector in live memory and asserts it
  never reaches a customer scaffold.
- **A packet speed measurement instrument** (`build-os/metrics/`). The project has
  argued a "20x-100x faster" multiplier with **zero instrumentation**; this adds
  the instrument and, deliberately, not the number. A dependency-free recorder
  (`record-packet.sh`) appends one validated row per packet to an append-only
  16-column TSV store; a report generator (`report-speed.sh`) renders rounds per
  lane, throughput per wall-clock minute, fan-out speedup, and round-budget
  compliance *with its denominator printed beside it*. The store is seeded with
  four rows from this project's real history, each attributed, and three of them
  are checkable against `git show --numstat` — `--verify-git` fails any row whose
  file/insertion/deletion figures contradict git. A fixed, versioned task corpus
  (`task_corpus.md`) and a written A/B protocol (`COMPARISON_PROTOCOL.md`) make
  future runs comparable rather than anecdotal.
  **The A/B has not been run, and cannot be run from this harness** — a Claude
  Code session is not launchable from a bash test, so *both* arms are
  unautomatable here. The baseline column is therefore empty with a stated
  reason, and the 20x-100x claim remains **unmeasured** rather than illustrated.
  Local, in-repo, operator-owned: **no telemetry, nothing is transmitted.**
  Pinned by `tests/speed_benchmark_tests.sh` (169 checks), whose load-bearing
  assertions are that report totals equal the sum of the *rendered* rows, that
  every seeded row carries an attribution, that a row contradicting git fails,
  that a row naming a commit this repository does not contain makes `--verify-git`
  **exit non-zero** rather than merely print `UNVERIFIABLE`, that the report's
  "this shows no comparison" finding is rendered **above** the first table rather
  than four screens below it, and that a report over zero rows refuses loudly
  instead of printing an empty green table.
- All sibling suites are chained into `bash tests/build_os_tests.sh`, which now
  reports **657 passed** and fails if any suite in `tests/` is left unchained.
  That guard was verified in the direction that matters: adding
  `tests/speed_benchmark_tests.sh` to `tests/` turned the parent suite **red**
  (487 passed, 1 failed) until it was explicitly wired. The guard *forces*
  wiring; it does not perform it, so a new suite cannot become
  discoverable-only.

## [0.1.0] - 2026-07-30

First versioned release. Sourced from the commits in `d3d8305..641527f`; every
entry below corresponds to a landed commit, and no capability is claimed that
those commits do not contain.

### Added

- **Memory maintenance + safety layer** (`c30f77d`). Ports the
  rotation/tripwire/sanctioned-wrapper layer from a reference deployment into
  the product so a blank repo receives the same protections, without that
  deployment's state:
  - `build-os/maintenance/rotate-memory.*` — byte-exact recency rotation with an
    append-only archive and an `INDEX`.
  - `build-os/maintenance/real-memory-tripwire.mjs` — the real-memory tripwire.
  - `build-os/maintenance/run-tests.sh` — the sanctioned test wrapper
    (`--import` preload plus shell fingerprints either side of `node`).
  - `build-os/maintenance/PORTING.md` — the porting manifest, including what the
    proof does **not** cover.
  - `build-os/memory/standing_gates.md` — shipped as a **contract-only**
    template; the reference deployment's live hard-stop inventory was
    deliberately **not** ported.
  - `GRAVITO:MANAGED` ownership markers plus a `.gravito-managed` manifest, so
    re-installs replace managed files and never clobber customer files.
  - Installer wiring into both customer entry points (`init-build-os.sh`,
    `install-project.sh`); an `npm` signpost is added only where a
    `package.json` already exists.
  - `tests/build_os_maintenance_tests.sh` — a 61-assertion cold-install suite
    (blank temp git repos, offline), **chained into** `tests/build_os_tests.sh`
    with its counts folded into the totals rather than collapsed to one
    pass/fail.
- **Release metadata.** `VERSION`, this `CHANGELOG.md`, and a `LICENSE`.

### Changed

- Rotation delimiters are now `^## ` across all three `FILE_SPECS`, matching the
  scaffold's memory format. The reference delimiter matched **zero** blocks in a
  scaffolded file, and a delimiter that matches nothing does not error — it
  reported a no-op at exit 0, i.e. a file that silently never rotates.
- A zero-block parse of a file that **has** content now writes a warning to
  stderr naming the file and the delimiter that matched nothing. Previously one
  `already rotated (no-op)` line was printed byte-identically for three
  unrelated states, including that hazard. The exit code is deliberately
  unchanged, because an empty scaffold parses to zero blocks legitimately;
  `--json` carries the signal as `originalHasContent`.
- Documentation for the layer in `README.md` and `INSTALL.md` (`5b956c0`),
  including the two boundaries a reader must know before relying on it:
  rotation is by **recency only** (meaning is not preserved; `standing_gates.md`
  is the never-rotated home), and the test wrapper **detects** rather than
  prevents. `INSTALL.md` states the uninstall boundary: removing the layer never
  removes `build-os/memory/`, including the archive, which is the only copy of
  anything already rotated out.

### Fixed

- **The documented test command no longer hangs on an interactive terminal**
  (`641527f`). `tests/build_os_tests.sh` section 2 invoked the SessionStart hook
  with the caller's stdin inherited. Claude Code delivers a JSON payload on
  stdin and then closes it, so the hook reads stdin to EOF; with no payload
  supplied the test inherited the terminal, which never reaches EOF, and
  `bash tests/build_os_tests.sh` — the exact command the README advertises —
  blocked forever with no output explaining why. The hook contract was correct
  and is unchanged; the test was wrong. Fixed by feeding the realistic payload,
  plus a stdin pin (section 27) covering all 10 hook-invocation sites with a
  minimum-site-count vacuity floor. Before: exit 124 (timeout). After: exit 0.

### Proof

Re-run at the released commit `641527f`, offline, temp dirs only:

- `bash tests/build_os_tests.sh` → **281 passed**, 0 failed (exit 0), which
  includes the chained cold-install suite at 61 passed, 0 failed.
- `./build-os/maintenance/run-tests.sh` → **144 passed**, 0 failed (exit 0).

### Known limits

- **Proof is single-platform.** Everything was measured on one Linux machine's
  `node`/`git`/`bash`. The `sha256sum` / `shasum` branch exists for macOS but
  has not been executed, and no other platform was tested at all.
- **Reviewer coverage was single-model.** Every reviewer verdict in this work
  was produced by one model; Codex second-eyes was checked and unavailable on
  every pass.

### Licensing note

The **license model is an open owner decision**, not a settled one. `LICENSE`
ships a deliberately conservative placeholder — proprietary, All Rights
Reserved — because it grants nothing by accident and can be loosened later
(to BSL, a dual license, or an open license) without clawing back a right that
was already given. Loosening is easy; retracting a grant is not. No pricing,
entitlement scheme, or terms of service are defined anywhere in this release.

## Update and rollback

The honest boundary, stated plainly rather than implied:

- **Update.** Fetch a newer checkout of this repository and re-run the installer
  for your project (`./init-build-os.sh` or `./install-project.sh`). Re-running
  is safe: managed files are replaced and marked, customer files
  (`standing_gates.md`, your `CLAUDE.md`, your memory files, your `.gitignore`,
  your `package.json`) are preserved. This path is covered by the cold-install
  suite, which asserts a byte-identical re-install.
- **Rollback.** Check out an earlier tag or commit of this repository and re-run
  the installer the same way.
- **What is not proven.** A full tested version rollback is **not yet proven**.
  No tags exist in this repository yet, so there is no released artifact to roll
  back *to* by name, and no rollback has ever been executed end-to-end and
  measured. Treat the rollback path above as the intended procedure, not as a
  verified one.
- **What a rollback would not undo.** Uninstalling or downgrading the
  maintenance layer never removes `build-os/memory/`, including
  `build-os/memory/archive/` — which is the only copy of anything already
  rotated out of a memory file. Content that rotation has archived is not
  restored to its original file by going back to an earlier version.

Tagging releases is the operator's call and has not been done here.
