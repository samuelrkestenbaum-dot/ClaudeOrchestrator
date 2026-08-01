# gravito_p2_claim_scoped_evidence_a — one control, many claims, many verdicts; and an over-grant found *inside the over-grant detector*

- **Packet id (stable):** `PACKET-0019-gravito-p2-claim-scoped-evidence-a`
  — this is both the packet id and its own *candidate* id inside
  `DECISION-0008-p2-claim-scoped-evidence`, where it was the selected arm of four.
- **Date:** 2026-08-01
- **Lane:** `substantive` (builder → qa ‖ reviewer → archivist)
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `e6b825b` (the close of `gravito_p1_mutators_ids_telemetry_a`);
  re-verified at close — `git merge-base c653508 e6b825b` = `e6b825b`, so the
  branch base is correct.
- **Final HEAD (packet):** `c653508`
- **Verdict:** **PASS.** reviewer **PASS** — no fix list, no fix round.
  qa **RED, resolved** before close.
- **Depth:** **2 serial stages** — builder, then qa and reviewer concurrently.
  **No stage 3.** This is the first packet in this sequence to hold the
  `substantive` median; the previous four each ran to four serial stages.
- **Second eyes:** **NONE.** Every verdict single-model. `codex` is not on PATH
  and no Codex plugin is installed; `build-os/memory/tool_router.md` routes
  reviewer second-eyes to it and the row is **unbacked for the seventh packet
  running**. See residue `(zz)`: *"Either install Codex or stop declaring the row."*

---

# PHASE CONTEXT

**This is P2 of the operator's five**, under **build authority** and the
**anti-stall rule** (build around limitations and record what was built around).

| phase | subject | state |
|---|---|---|
| P1 | mutators / IDs / telemetry | **done** (`e6b825b`) |
| **P2 (this packet)** | **claim-scoped evidence** | **done** (`c653508`) |
| P3 | `accept_and_constrain` | next |
| P4 | S1 shadow ranker | pending |
| P5 | outcome / counterfactual telemetry | pending |

Read everything below as **substrate for P4**, not as governance for its own sake.

---

# WHAT P2 DELIVERED

**One control may now carry many claims with many verdicts.**

1. **A claim-scoped evidence store** — `build-os/registry/evidence_assertions.txt`,
   one stanza per assertion, keyed by a stable `EV-NNNN-<slug>` id, nineteen
   required fields, **a subject may carry many concurrent assertions**.
2. **A validator** — `build-os/tools/claim-evidence.sh`
   (`schema` / `validate` / `list` / `project`).
3. **A new suite** — `tests/claim_evidence_tests.sh`, **77 assertions**, chained
   from the repo suite (verified in the chain list, not merely present on disk).
4. **`untested` added to the evidence axis at `observe`** — *has never operated
   against a live or representative task*, strictly weaker than `unvalidated`,
   capped at the most conservative legal destination on the ladder. The
   unrecognised-token guard (`evidence.derivation_nonvacuity`, Class A, gate) is
   **not weakened**: `untested` stops being unrecognised, and every *other*
   unrecognised token still takes the derivation to **exit 2**. Both halves are
   driven in the **same run**, so "recognising one token" cannot be read as
   "opening a fall-through".
5. **A deterministic composite projection** to legacy `empirical_status` — sorted,
   deduplicated, order-independent; it **exposes the composite and never selects**,
   so a refutation cannot be dropped. `supported` projects **globally** to
   `unvalidated`, never to `field_observed`, because the legacy field carries no
   scope and a scoped support claim cannot be spelled in it without overclaiming.

**Movement.** Census **90 → 93**. Suite **1689 → 1771** (+82). Findings
**numerator unchanged at 25**; only the denominator moved — **25 of 93**, split
**6 / 5 / 14**, identical to the 25 of 90 at base. **Zero re-authorisations.**
Grid **25 cells → 30**; **0 of 30 license `execute`**, unchanged.

## The canonical fixture works, and it is FAITHFUL rather than plausible-looking

`maint.tripwire_coverage_scan` now carries two live assertions **simultaneously**,
verified at close against the shipped store:

| id | claim | status | scope |
|---|---|---|---|
| `EV-0001-tripwire-coverage-detection-bare-node` | `CLAIM-0001-coverage-detection` | **`refuted`** | the bare `node --test` path — one file, no preload, no wrapper |
| `EV-0002-tripwire-coverage-prevention-sanctioned` | `CLAIM-0002-destructive-mutation-prevention` | **`supported`** | the sanctioned maintenance invocation ONLY — `run-tests.sh` under the tripwire preload |

A third, `EV-0003-handoff-lock-stale-reclaim-untested`, carries the first
`untested` status (`tools.handoff_lock_lifecycle`, stale-lock reclaim under
contention). `claim-evidence.sh validate` exits **0** on all three: *"every
subject resolves, every scope is named, every status is capped, and no two LIVE
assertions share a (subject, claim)."*

**qa independently verified the underlying measurement rather than trusting the
stanza:** `residue.md` is **1621 B**, `DAMAGED\n` is **8 B**, and the gated arm
uses **`cmp -s` byte identity — stronger than the sha256 the earlier packet
claimed**. This is the case that nearly caused a demotion *measured* to destroy
live memory. It is now **representable** instead of collapsed into one misleading
token.

**And the registry entry did not move.** Verified at close directly from
`control_registry.txt`: `maint.tripwire_coverage_scan` keeps `class: C`,
`empirical_status: red_driven,refuted`, `runtime_authority: gate`,
`authority_mismatch: declared` — **unchanged**. The new store is **additive and
advisory: it is read by nothing that grants authority.**

---

# 1. F1 — A LIVE OVER-GRANT INSIDE THE OVER-GRANT DETECTOR

**This is the strongest thing in the packet, and it is a defect the packet
created and then caught.**

`EVIDENCE_AXIS` had **two literal copies**. The packet updated one
(`evidence-policy.sh`) and the prose describing it, and **left the second copy at
five tokens** in `authority-envelope.sh` — *while that same file's own header
already said six.* **At base both copies agreed; the packet created the
divergence.**

It was **demonstrated against the shipped tool**, not argued:

- `axis_cap` returns **empty** for `untested`;
- `rank_of("")` = **−1**;
- the `[ "$tr" -ge 0 ]` guard therefore **silently drops the strictest token out
  of the minimum**;
- so a `gate` grant on `untested,red_driven` reads **`WITHIN-LICENCE`** when the
  correct cap is **`observe`** — **over-reaching by three rungs, inside the tool
  that exists to catch over-grants.**

**Latent only** because 0 authority envelopes are live and 0 controls carry
`untested`. Section 18 was blind to it because **every assertion in it grepped
`evidence-policy.sh` and none grepped the tool under test.**

The reviewer's words, kept verbatim because they name the method and not just the
bug:

> *"the strongest thing in the diff… found by pointing an assertion at the tool
> under test instead of at the tool it cites."*

**Verified fixed at close.** Both literal copies are byte-identical at six tokens:

```
EVIDENCE_AXIS="untested:observe unvalidated:advise red_driven:gate field_observed:gate calibrated:gate refuted:observe"
```

---

# 2. THE FIX COVERS THE CLASS, NOT THE PAIR — A FIRST

This was the **third** instance of the unchecked-duplicate defect:

1. the evidence cap table vs README §3a;
2. the deployment axis's declared owner vs its copy;
3. **the evidence axis in the envelope tool** (this packet).

Each earlier fix reconciled **one pair** and left the next pair to be found by
hand. **This is the first fix that is not pair-shaped.** Section 18 now requires
**every literal `<NAME>_AXIS="…"` restatement under `build-os/tools/`** to agree
token-for-token with `evidence-policy.sh matrix`. It sweeps **3** restatements
today, and **a fourth added later is covered with nobody remembering.**

Red-driven by reverting the one-token fix: **94 passed / 2 failed**, restored to
**96 / 0**.

## The reviewer found two coverage limits and ruled them RESIDUE, not defects

The ruling turned on there being **no failing fixture** — neither form exists in
the tree today, so the CHANGELOG's wording is **true of the tree it describes**:

- **Same-line second assignment** — `FOO=1; EVIDENCE_AXIS="bogus"`. The anchored
  enumerator never sees the second name.
- **Append form** — `EVIDENCE_AXIS+=" bogus"`. The sweep passes green while the
  tool composes with the appended token.

**A precise note the archivist adds at close, because it sharpens the residue
rather than softening it:** the same-line shape *does* occur structurally in the
tree, at `claim-evidence.sh` (`CLASS_AXIS=""; EVIDENCE_AXIS=""`). It is **not a
counter-example to the reviewer's ruling** — it is an *empty initialiser*
immediately overwritten by a value derived from `evidence-policy.sh matrix`, so
no divergent literal exists and nothing is over-granted. But it means the
enumerator's blind spot is **already reachable by a shape the tree contains**,
not merely by a hypothetical one. Residue **(bbb)** (this receipt's item (a)).

---

# 3. A GUARD CAUGHT THE BUILDER'S OWN WORK AND WAS OBEYED, NOT SILENCED

Section 18's first non-vacuity check was `[ "$AXSEEN" -ge 3 ]`. **§21 flagged it
as an unregistered fitted floor**, pushing the `-ge N` family **37 → 38**.

Registering a floor is a **re-authorisation** and out of this packet's scope. So
the builder **replaced the count with a named anchor** rather than registering the
floor or deleting the guard.

The reviewer confirmed the replacement is **genuinely stronger, not merely
compliant**:

> *"`-ge 3` is satisfiable by three copies of anything, while the named anchor
> cannot be satisfied by arithmetic and fails closed if the glob breaks."*

**Verified live at close** (`tests/control_registry_tests.sh` §21):

```
PASS: the family scan matched 37 floor(s) in tests/ (not vacuous)
PASS: every fitted non-vacuity floor in the tree (34 of 37 scanned, 3 excluded with reasons) is registered to tests.nonvacuity_minimums
PASS: tests.nonvacuity_minimums cites no floor that the scan cannot find (34 refs)
```

Family back at **37**; §10's **34** undisturbed; **no floor registered.**

---

# 4. THE ORCHESTRATOR'S COUNT WAS WRONG AGAIN — THE FOURTH TIME THIS SEQUENCE

The orchestrator reported the fitted-floor family at **38**. The repo's own rule
**excludes `N ≤ 1` deliberately** — *"the scan found at least one thing"* is a
Class A invariant, not a fitted threshold — and §21 reports **34 of 37 scanned,
3 excluded**. **The builder was right and the orchestrator was wrong.**
Re-derived independently by the archivist at close: **37 / 34 / 3**, as printed
above.

**Record this pattern, because it is now a pattern and not an incident: four
times in this sequence a builder derived and corrected a figure the orchestrator
relayed.**

| # | packet | relayed | correct | corrected by |
|---|---|---|---|---|
| 1 | `gravito_p1_mutators_ids_telemetry_a` | reviewer's `64 of 90` | `77 of 90` | builder |
| 2 | `gravito_p1_mutators_ids_telemetry_a` | self-tally `7 shifted / 4 wrong` | `10 / 3 / 7` | qa |
| 3 | this packet | `DECISION-0008` is the *first* counterfactual | it is the **second** | qa |
| 4 | this packet | fitted-floor family `38` | **37** (34 scanned, 3 excluded) | builder |

---

# 5. TWO COUNTERFACTUAL DATA POINTS, NOT ONE

**qa corrected the orchestrator:** `DECISION-0008` is the **second** recorded
decision where a signal disagreed with the human choice, **not the first**.

- **`DECISION-0007` already recorded one** — the selected candidate scored **0**
  on `dependency_unlock_count` while `PACKET-0016` scored **1** (snapshots 0001
  vs 0004).
- **`DECISION-0008`** — `census_growth_controls` is **3** for the selected arm
  and **0** for all three rejected arms. The selected arm is **uniquely worst on
  the only cost-ranking signal**, and `selection_reason` says so verbatim —
  **re-derivable from the recorded signals alone.**

Re-derived by the archivist at close from `signal_snapshots.tsv`:

| candidate | `census_growth_controls` | selected |
|---|---|---|
| `PACKET-0019-gravito-p2-claim-scoped-evidence-a` | **3** | **yes** |
| `PACKET-0020-widen-control-registry-with-claim-fields` | 0 | no |
| `PACKET-0021-fold-assertions-into-evidence-policy` | 0 | no |
| `PACKET-0022-untested-token-only` | 0 | no |

**16 frozen snapshots** for `DECISION-0008` — 4 candidates × 4 signals — **twelve
of them for arms that were NOT selected.** The store now holds **8 decisions** and
**71 snapshot rows**. **The n = 1 obligation inherited from P1 is discharged:
there are now two decisions with a non-degenerate candidate set.**

**No artefact claims "first"** — verified **absent tree-wide** by the archivist at
close across `.md`, `.txt`, `.tsv` and `.sh`.

---

# 6. THE ANTI-LAUNDERING PROPERTY SURVIVED SEVEN ATTACKS

**qa could not defeat it.** The sharpest case: `refuted` in the registry **plus** a
`red_driven` assertion → `effective = observe`. **A refutation cannot be
outvoted.**

It is **structurally unraisable**, not merely untested: composition uses only
`-lt`, so `L_effective = MIN(L_class, L_registry_evidence, L_assertion_evidence)`
can only ever lower. Section 8 fabricates a Class-A control the census records
`refuted`, hands it a `red_driven` assertion licensing `gate` alone, and requires
`observe` — **checked as an inequality over the ladder, not as a matched string.**

**The freeze was verified by mutation, not by reading:** adding a control to the
source `census_growth_controls` derives from left **all 12 non-selected snapshot
values unmoved**.

---

# Scope

**In scope (the writable set):** `build-os/registry/evidence_assertions.txt` (new),
`build-os/tools/claim-evidence.sh` (new), `tests/claim_evidence_tests.sh` (new),
and the `untested` schema change where it lands —
`build-os/tools/evidence-policy.sh`, `build-os/tools/authority-envelope.sh`,
`build-os/registry/scan-controls.sh`, `build-os/registry/scan-mutators.sh`,
`build-os/registry/README.md`, `build-os/registry/control_registry.txt`,
`build-os/registry/neurocosmology_crosswalk.txt`,
`build-os/registry/CROSSWALK.md`, `build-os/registry/MISMATCHES.md`,
`build-os/registry/mutator_registry.txt`, `tests/build_os_tests.sh`,
`tests/evidence_policy_tests.sh`, `tests/control_registry_tests.sh`,
`tests/authority_envelope_tests.sh`, `tests/mutator_registry_tests.sh`,
`CHANGELOG.md`, and the two telemetry stores under `build-os/metrics/`.

**Out of scope — each a refusal rather than an omission:**

- **Re-authorising anything pre-existing.** `governance_baseline.txt` pins all 81
  pre-P1 controls and would refuse it. **Zero governance-field deletions in the
  diff.**
- **Applying any `FINDING-*` remedy** — each is a re-authorisation.
- **Deciding whether any class should license `execute`** — 0 grid cells reach it
  before and after; widening the evidence axis **adds a column, never a grant**.
- **Enforcing `valid_until`** — stored, enforced nowhere. Residue **(eee)** (this receipt's item (d)).
- **Any external mutation.** Local commits only.
- **`/home/user/empathiq-website`** (`cb2bb7d`) — untouched.
- **`build-os/memory/*`** — untouched *by the packet*; written only by this close.

---

# Commits — 2, at the cap

| commit | one-line |
|---|---|
| `9474cae` | `docs(packet): declare gravito_p2_claim_scoped_evidence_a before building` — the declaration **alone**, so git attests the packet was declared before its first implementation edit without spending a third commit. 1 file, +154 / −95. |
| `c653508` | `feat(registry): claim-scoped evidence — one control, many claims, many verdicts` — tests and implementation. 21 files, +1727 / −139. |

**Union across both commits: 22 files, +1881 / −234** (`git diff --numstat
e6b825b c653508`).

**`9474cae` is untouched and still an ancestor of `c653508`.** `20df098` is still
a live object in the repository.

## Disjoint file-ownership manifest — attribution by path

The row in `packet_metrics.tsv` names **two** commits, so attribution must stay
recoverable **by path**. The two writable sets are **disjoint — verified at close,
intersection empty**:

| commit | owns | files |
|---|---|---|
| `9474cae` | **`build-os/packets/active_packet.md` — and nothing else** | **1** |
| `c653508` | everything below, and **not** `active_packet.md` | **21** |

`c653508`'s set, in full:

```
CHANGELOG.md
build-os/metrics/decision_telemetry.tsv
build-os/metrics/signal_snapshots.tsv
build-os/registry/CROSSWALK.md
build-os/registry/MISMATCHES.md
build-os/registry/README.md
build-os/registry/control_registry.txt
build-os/registry/evidence_assertions.txt
build-os/registry/mutator_registry.txt
build-os/registry/neurocosmology_crosswalk.txt
build-os/registry/scan-controls.sh
build-os/registry/scan-mutators.sh
build-os/tools/authority-envelope.sh
build-os/tools/claim-evidence.sh
build-os/tools/evidence-policy.sh
tests/authority_envelope_tests.sh
tests/build_os_tests.sh
tests/claim_evidence_tests.sh
tests/control_registry_tests.sh
tests/evidence_policy_tests.sh
tests/mutator_registry_tests.sh
```

**1 + 21 = 22**, which reconciles exactly with the numstat union above. Verified
with `comm -12` over both sorted name-only sets: **empty**. No file is written by
both commits, so **every changed line attributes to exactly one commit by path
alone.**

**This section was added during the close, and it was added because a guard
refused — the honest version is worth recording.** The archivist's first
`packet_metrics.tsv` row named two commits while this receipt carried no
manifest, and `check-adoption.sh` refused at **exit 2** with `UNATTRIBUTED`,
taking `tests/metrics_adoption_tests.sh` and `tests/lane_declaration_tests.sh`
red and the live suite to **1769 passed / 2 failed**. **The gap was closed by
recording the manifest the guard asks for — not by widening a boundary**, which
the guard's own refusal text explicitly forecloses: *"the boundary is dated,
pinned by `tests/metrics_adoption_tests.sh`, and emptying the scope makes this
guard refuse rather than pass."* **This is an ARCHIVIST defect, caught by a live
guard during the close, and it belongs in the record for the same reason the
packet's own self-caught defects do.**

**This close is a THIRD commit, and that is deliberate** — the packet is at its
2-commit cap, so the receipt and memory updates land separately rather than by
amending a reviewed commit.

---

# QA proof

**qa: RED → resolved. reviewer: PASS.** All five close gates re-run by the
archivist, **sequentially, each alone, each read in full — never piped through
`tail` before being read.**

| gate | result |
|---|---|
| `bash tests/build_os_tests.sh` | **1771 passed / 0 failed**, exit **0** |
| `bash build-os/registry/scan-controls.sh check` | exit **0** — 93 controls vs 41 surfaces, 79 load_bearing, 20 over-authorised (declared), 0 unregistered, 0 phantom |
| `bash build-os/registry/scan-mutators.sh check` | exit **0** — 8 mutators, 12 defect classes, 12 occurrences, 3 findings, 35 stable ids |
| `bash build-os/tools/evidence-policy.sh check` | exit **0** — **25 of 93**, split **6 / 5 / 14** |
| `bash build-os/tools/claim-evidence.sh validate` | exit **0** — 3 assertions valid, schema `claim-scoped-evidence-v1` |
| `./build-os/maintenance/run-tests.sh` | **144/144**, re-run **AFTER** this close's writes |
| `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` | **MATCH at 1771**, re-run **AFTER** this close's writes |
| `git status --porcelain` | **empty** |

**The suite capture was read in full: 268 lines, zero `FAIL` lines, all 18
chained sibling suites at `0 failed`.** `tests/claim_evidence_tests.sh` chains at
**77 passed / 0 failed** — the new suite is chained, not discoverable-only, and
the suite asserts that property for every sibling.

**Commit-1 isolation:** `9474cae` is a **declaration-only** commit touching one
file under `build-os/packets/`. It is **green in isolation trivially** — it
changes no code, no test and no registry artefact. This is the packet's stated
design: the declaration alone buys git's attestation of ordering without a third
commit or a pre-commit hook.

**Safety grep:** clean. **Zero governance-field deletions** in the diff — verified
against `governance_baseline.txt`, which pins class / authority / mismatch on all
81 pre-P1 controls and would have driven RED on any flip.

**Stale-reference sweep — the method matters more than the number.** 42
`evidence_refs` went stale when four tool headers grew. **Every one was repointed
by locating its base-commit line CONTENT in the current file, never by shifting a
number.** One was still missed by hand (`tests/mutator_registry_tests.sh:642 →
:643`, which a `while` statement let past the §23 vacuity guard), so the
repointing is now **verified mechanically**: every `file:line` reference in the
tree is **paired positionally against its base-commit counterpart and compared by
CONTENT**. **0 stale pathed refs tree-wide**, confirmed by independent
cross-commit content pairing over **338 refs** — and that sweep caught the
reference the packet's own new assertions had displaced.

**DEFECT-0009, self-caught in a file this packet authored.**
`claim-evidence.sh --help` printed six lines of shell as documentation
(`sed -n '2,120p'` over a 114-line header). Bounded to `'2,114p'` — verified at
close at both invocation sites.

---

# Final state at `c653508`

- **Suite:** **1771 passed / 0 failed** (was 1689; **+82**).
- **Maintenance:** `./build-os/maintenance/run-tests.sh` **144/144**.
- **Census:** **93 controls**, **20 declared mismatches**.
- **Authority:** **73 `gate` / 14 `advise` / 6 `execute` / 0 `rank` / 0 `observe` /
  0 `none`** — re-derived by the archivist directly from `control_registry.txt`.
- **Evidence policy:** **25 of 93**, split **6 / 5 / 14** — **same numerator as
  25 of 90 at base; only the denominator moved.**
- **Grid:** 30 cells, **0 license `execute`** — unchanged.
- **Claim-scoped store:** **3 assertions**, 1 `refuted` / 1 `supported` /
  1 `untested`, 2 of them on the same subject.
- **Telemetry:** **8 decisions**, **71 signal-snapshot rows**, 16 of them new.
- **Authority envelopes:** **0 live grants.**
- **`EVIDENCE_AXIS`:** both literal copies **byte-identical at six tokens**.
- **Stale pathed refs:** **0 tree-wide**, over 338 refs, cross-commit content-paired.
- **Tree clean;** `git status --porcelain` empty.

---

# Residue — deferred, with the reason each was deferred

Full text appended to `build-os/memory/residue.md` under
*From `gravito_p2_claim_scoped_evidence_a`*, where they are labelled **(bbb)-(fff)** to
continue that file's sequence. The mapping is stated on each heading below.

## (a) = residue `(bbb)` — the axis sweep's two coverage limits: recorded, no fixture, NOT defects

**Same-line second assignment** (`FOO=1; EVIDENCE_AXIS="bogus"`) and the **append
form** (`EVIDENCE_AXIS+=" bogus"`). Neither exists in the tree today, so the
CHANGELOG's wording is true of it, and **the reviewer ruled them residue because
no failing fixture exists.** Sharpened at close: the same-line *shape* is already
reachable — `claim-evidence.sh` contains `CLASS_AXIS=""; EVIDENCE_AXIS=""` — but
as an empty initialiser overwritten from `evidence-policy.sh matrix`, so no
divergent literal and no over-grant.

## (b) = residue `(ccc)` — `MISMATCHES.md` §13's three citations: ALREADY WRONG AT BASE, not a regression

`MISMATCHES.md:607` / `:608` / `:609` cite `scan-controls.sh` **`:454`** (the
`exit 2`), **`:126`** (three directories) and **`:129`** (five refusal patterns).
**True targets are now `:471`, `:141`, `:144`** — verified by content at close:

| cited | what is actually there | true target | content |
|---|---|---|---|
| `:454` | a prose comment | **`:471`** | `  exit 2` |
| `:126` | a prose comment | **`:141`** | `SCAN_DIRS="build-os tests .claude/hooks"` |
| `:129` | a prose comment | **`:144`** | `REFUSAL_PATTERNS=(` |

**These were ALREADY WRONG AT BASE by nine lines** — at `e6b825b` `SCAN_DIRS` was
at `:135` and `REFUSAL_PATTERNS` at `:138` against citations of `:126` and `:129`.
**The packet moved their true targets by six** (135 → 141, 138 → 144, 465 → 471)
**under references that were already stale, so no correctness property changed
state and this is not a regression the diff introduced.** The reviewer **recorded
rather than demanded**, explicitly to avoid a sixth stage-4 in seven packets.

**The bitter detail, preserved because it is the whole argument for an anchor
token over a line number:** `MISMATCHES.md:611` is a **parenthetical documenting
the PREVIOUS generation of this exact bug at `:347`** — so **`:454` is generation
three of a defect the file narrates about itself.** Right home: a `tiny` edit or
the next packet, with the exact targets above.

## (c) = residue `(ddd)` — the positional content-pairing check belongs in its own packet

A **real discriminator** that would close the class §23's vacuity guard **cannot
see** — F2 walked past §23 because `while IFS= read -r id; do` is non-vacuous.
**The reviewer agreed it is a new governance control belonging in its own
packet**, and — recorded honestly — **could produce no fixture showing P3 blocked
without it.**

## (d) = residue `(eee)` — `valid_until` is stored and enforced NOWHERE; **P3 must own this**

Inert **here** for two specific reasons: nothing consumes assertions, and
composition is `MIN`. **Neither reason survives P3.** **P3 must own its own expiry
enforcement**, and folding in `authority_envelopes.txt`'s **equally-unchecked
`expires`** at the same time is **the cheap version**.

## (e) = residue `(fff)` — second-eyes unbacked, SEVENTH consecutive packet

Residue `(zz)` already says: *"Either install Codex or stop declaring the row."*
**It is still declared and still unbacked.**

---

# Open boundaries — nothing done without go

- **No push.** The branch was **not** pushed by this close.
  `origin/claude/project-handoff-merge-ramhds` is at **`7daedee`**, and
  `git branch -r --contains` confirms **no remote branch contains `c653508` or the
  close commit**.
  **A MEMORY CORRECTION MADE AT THIS CLOSE, because the archivist found it while
  verifying this very boundary:** `current_state.md` claimed the remote ref was at
  **`6b01173`** and listed `c52915f`, `2df61ae` and `7daedee` among the *local-only*
  commits. **All three were in fact pushed** — the reflog for that ref records
  `7daedee`, `2df61ae`, `c52915f`, `6b01173` as successive `update by push` entries.
  **The memory understated what had been pushed**, which matters because `2df61ae`
  **ships red** at `143/144`. Corrected in `current_state.md` at this close, and
  re-derived rather than adjusted: the true local-only set is `f27c570`, `a75c25e`,
  `e6b825b`, `9474cae`, `c653508`, plus this close commit. **No claim is made about
  whether any past push carried an explicit go.**
- **No merge.** Nothing merged into `claude/add-build-os` or anywhere else.
- **No tag, no PR, no deploy, no release, no secrets, no `git config`.**
- **`/home/user/empathiq-website` (`cb2bb7d`) untouched.**
- **Nothing pre-existing re-authorised.** The 20 declared mismatches, the 3
  standing `FINDING-*` records and every remedy they name are **unapplied and
  still open to the operator.**

---

# Files written by this close — all inside `build-os/`

- `build-os/receipts/gravito_p2_claim_scoped_evidence_a.md` (this file, new)
- `build-os/memory/current_state.md` (advanced; 1689 → 1771; ten drifted refs repointed by content)
- `build-os/memory/residue.md` (items (a)–(e) appended; drifted refs repointed by content)
- `build-os/packets/active_packet.md` (packet marked **closed**; P3 staged; **≥3 `^## ` blocks** verified after writing)
- `build-os/metrics/packet_metrics.tsv` (one row appended; `defects_escaped` = `-`)

**No file outside `build-os/` was touched by this close.** The ten drifted
references live in `build-os/memory/*` and were repointed **by content against the
base**, never by shifting numbers.
