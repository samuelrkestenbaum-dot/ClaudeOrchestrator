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
