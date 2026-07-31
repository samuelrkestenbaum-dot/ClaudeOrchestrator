# gravito_census_gaps_egress_bandwidth_a — register the egress scan, and build the first bandwidth ceilings

- **Date:** 2026-07-31
- **Lane:** `substantive` (builder → qa ‖ reviewer → fix → re-review → archivist)
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `321dced`; merge-base with `origin/claude/add-build-os` = `7ef50e8`.
  Verified before building, and re-verified at close.
- **Final HEAD:** `2a3c9b3`
- **Verdict:** **pass as fixed** — qa GREEN, reviewer `fix-then-pass` twice, both
  fix rounds landed and re-verified.

Two census gaps closed in one packet, because the registry is a hot file: adding
a control cascades through `control_registry.txt`,
`neurocosmology_crosswalk.txt`, `CROSSWALK.md`, `README.md`, `MISMATCHES.md` and
`CHANGELOG.md`, all of which carry numbers machine-reconciled across six columns.

## What landed

**`entitlement.egress_scan`** (Class A, `gate`, red_driven) is registered and
bound to `ethical_admissibility` as `instantiates` — which moves that primitive
**off nominal-only for the first time**. It was already a real security invariant
with a planted `curl` positive control, but it lived inside
`tests/entitlement_tests.sh` and was visible to the census only through that
suite's RESULT line, so the registry could see "this scanner is not blind" and
never "nothing performs egress".

**`build-os/tools/bandwidth-check.sh`** — the first controls whose function is
limiting what may be *absorbed* rather than judging what already exists.
`integration_bandwidth` had zero bindings before this packet.

| Dimension | Outcome |
|---|---|
| `packets` | `bandwidth.active_packet_singleton` — **Class C** (demoted on review), `gate`, `authority_mismatch: declared` — the 14th |
| `commits` | `bandwidth.packet_commit_ceiling` — Class C, **`advise`**, no mismatch |
| `write_sets` | **DECLINED out loud** — observable, but no ceiling is declared anywhere; inventing one is anti-pattern §15.1 |
| `depth` | **DECLINED out loud** — rounds are transcript-only; nothing in git attests to a serial stage |

No composite load score: the weights would be unjustifiable and one number hides
which dimension is saturated. Each dimension is enforced separately.

## Final census

- **75 controls / 75 bindings** (71 → 75)
- **64 `gate` / 11 `advise` / 0 `rank` / 0 `observe`**
- **14** declared authority mismatches (13 → 14)
- `evidence_refs` **235 → 257**
- `instantiates` / `proxies` / `nominal`: **27/38/6 → 29/40/6**
- primitives with ≥1 instantiating binding: **6 → 8**; empty primitives **4 → 3**
- class **A 54 / B 3 / C 18**
- fitted-constant sites **55 → 56**

Re-derived by the archivist at close, directly from the registry files:
`class` 54/3/18 = 75, `binding_kind` 29/40/6 = 75, `runtime_authority` 64 gate /
11 advise, `authority_mismatch` 14 declared / 61 none.
`bash build-os/registry/scan-controls.sh check` → **exit 0**.

## Scope

**In:** `build-os/tools/bandwidth-check.sh` (new), `tests/bandwidth_tests.sh`
(new, 41 assertions), the one `chain_suite` line in `tests/build_os_tests.sh`,
§26/§26a/§26b of `tests/control_registry_tests.sh`, §14/§15 of
`tests/neurocosmology_crosswalk_tests.sh`, the four registry entries and four
bindings, the two rewritten primitive records, `CROSSWALK.md`, `README.md`,
`MISMATCHES.md`, `CHANGELOG.md`, `build-os/packets/active_packet.md`.

**Explicitly out — ruled out, not deferred:**

- **A repo-side gate on push / merge / deploy / publish / secrets.** That rule is
  enforced by the operator's permission system, a process boundary *outside* this
  repository. Anything that could bypass it bypasses a repo-side check trivially,
  so a repo-side gate would convert a real external boundary into a checkbox that
  looks enforced and is not. **The strongest rule this system states about itself
  still has zero registered controls, on purpose.**
- A round-budget or depth guard (transcript-only; unobservable from git).
- A ceiling on concurrent write sets (no declared constant to enforce).
- A composite load score.
- Re-authorising anything — no existing control's class or authority changed.

**Deferred to this close:** `current_state.md`'s stale suite count, and the
metrics row.

## Commits

- `86c8f93` feat(registry): register the egress scan, and build the first
  bandwidth ceilings — 10 files, +944 / −75
- `2a3c9b3` docs(changelog): record the two census gaps closed, and demote the
  packets ceiling to Class C on review — 7 files, +298 / −109

**Two commits, at the cap.** Commit 2 was **amended twice** (once for the fix
round, once for the re-review defect) rather than appended to.
`86c8f93` stayed **byte-identical** through both amends, so qa's
Commit-1-green-in-isolation proof survived intact and was never re-spent.
Verified at close: `git merge-base --is-ancestor 86c8f93 2a3c9b3` → yes.

Per-commit numstat union (the figure `record-packet.sh --verify-git` checks):
**12 files, +1242 / −184**. The squashed `git diff 321dced 2a3c9b3` reads
+1226 / −168; the two differ because both commits touch the same registry files.

## File-ownership manifest (attribution by path)

Recorded because the row names **two** commits. `build-os/metrics/check-adoption.sh`
requires it: one commit per packet where the merge allows it, and where it does
not, **the file-ownership manifest is what keeps per-packet attribution
recoverable by path.**

**Owned solely by `86c8f93` (commit 1 — the build):**

| Path | +/− |
|---|---|
| `build-os/tools/bandwidth-check.sh` | +205 / −0 |
| `tests/bandwidth_tests.sh` | +300 / −0 |
| `tests/build_os_tests.sh` | +1 / −0 |
| `tests/control_registry_tests.sh` | +104 / −0 |
| `tests/neurocosmology_crosswalk_tests.sh` | +103 / −0 |

**Owned solely by `2a3c9b3` (commit 2 — the record and the fix rounds):**

| Path | +/− |
|---|---|
| `CHANGELOG.md` | +82 / −0 |
| `build-os/packets/active_packet.md` | +110 / −78 |

**Touched by BOTH commits — attribution here is by commit, not by path:**

| Path | `86c8f93` | `2a3c9b3` |
|---|---|---|
| `build-os/registry/CROSSWALK.md` | +90 / −43 | +7 / −3 |
| `build-os/registry/MISMATCHES.md` | +5 / −5 | +79 / −12 |
| `build-os/registry/README.md` | +3 / −3 | +2 / −2 |
| `build-os/registry/control_registry.txt` | +91 / −10 | +15 / −11 |
| `build-os/registry/neurocosmology_crosswalk.txt` | +42 / −14 | +3 / −3 |

**This set is NOT disjoint, and saying so is the point.** The five registry files
are the packet's hot files: commit 1 registered the controls and commit 2
demoted one of them on review, and a class demotion necessarily rewrites the
same rows commit 1 wrote. **No fan-out was run** — this was a single builder, so
disjointness was never a safety property here; the manifest exists so that a
later reader can attribute any registry line to the commit that wrote it without
re-deriving it from the diff.

## QA proof

**qa: GREEN at `624facf`** — and it did not trust the packet. It **wrote its own
parser** and reconstructed the `321dced` baseline **from a fresh clone**:

- All **twelve** derived quantities matched — 75 controls, 257 `evidence_refs`,
  64 gate / 11 advise, 29/40/6 inst/proxy/nominal, 8 primitives instantiating,
  3 empty, 32 surfaces, 13 mismatches pre-fix.
- **Suite: 1418 passed / 0 failed.** Test delta **+80** reconciled exactly to
  **41 + 14 + 25**.
- **Commit-1 green in isolation: verified at `86c8f93`.**
- All **9 ruling claims drive red on removal**.
- **Safety grep: 12/12 negative controls fired, 0 genuine hits.** No push, merge,
  deploy, publish, tag, PR or secret access.
- The new suite **leaks zero temp dirs** — `/tmp` measured **2475 before, 2475
  after**.
- UI smoke: **N/A** — no UI surface in this packet.

**Re-measured by the archivist at close, on a quiet tree at `2a3c9b3`:**
`bash tests/build_os_tests.sh` → **1418 passed / 0 failed**, exit 0.

## Review

**Verdict: `fix-then-pass` → pass as fixed.** Reviewer returned 7 items at
`624facf`; a second, targeted re-review returned exactly **one** further defect.

### The two gates disagreed on the central question — and the reviewer was right

**qa ruled `bandwidth.active_packet_singleton` Class A. The reviewer ruled it
Class C wearing an A label.** The orchestrator reconciled in the reviewer's
favour; the reviewer independently re-verified that reconciliation at re-review
and confirmed it.

The argument that lost: *the ceiling of one is not a fitted number, it is
`active_packet.md`'s own definition.* The argument that won: **"one packet at a
time" appears nowhere in `CLAUDE.md`** — it is a sentence in the prose header of
the very file the control reads. The ceiling therefore rests on a docstring
inside its own input, which makes it a WIP limit somebody chose. The packet's own
two artefacts had already contradicted each other on exactly this point: the
registry called it a definition while the crosswalk called it a WIP limit in
order to earn `binding_kind: instantiates`. **The crosswalk was right.**

The analogy to `metrics.record.one_row_per_packet` was **dropped rather than
defended**: a second metrics row silently corrupts `report-speed.sh`'s totals,
whereas nothing consumes this control's exit code — a breach here contradicts a
prose sentence and corrupts no number.

**The authority was not touched.** It stays `gate`, so the mismatch is now
**declared** — the census's fourteenth — because clearing a mismatch by
re-authorising the control is the operator's decision, not a builder's.

Worth preserving verbatim, because it is the reason the demotion was the
commercially correct call and not merely the honest one:

> "A technical buyer who reads `demotion_requirement` next to `class: A`
> disassembles it in ten minutes... Corrected to C-at-gate with the mismatch
> declared, it is MORE saleable than it is now, not less — a system that demotes
> its own new control's class on review is the demo."

### The mechanical guards did NOT catch the central defect

**The class-A / `instantiates` contradiction passed every automated check
clean.** `scan-controls.sh` reconciles class **labels** across files; it cannot
reconcile the **arguments** behind them. The guard surface is now thorough enough
to *feel* comprehensive while being blind to the exact failure mode the registry
exists to prevent — a control whose stated class overstates its evidence.

**The fix for this is NOT another scanner. It is the reviewer stage.** No
label-reconciler can catch a wrong label that is internally consistent. Recorded
here so a future packet does not respond to this finding by building a scanner
that cannot, in principle, work.

### The fix round found six edits the brief did not enumerate

The fix round carried **8 items** (the reviewer's 7, plus a count-site
correction, plus one folded in from qa). Executing it, the builder found **six
further edits the brief had not enumerated, one of them MANDATORY**:
`CROSSWALK.md:76`, whose six-column table is machine-recomputed — **item 3 alone
would have turned the suite red** had the table not been recomputed with it.

### The re-review defect: a "pre-existing" premise that was false

Re-review returned one defect. `MISMATCHES.md:284` still cited
`tests/control_registry_tests.sh:668`, but **commit 1's 104-line insert had moved
that assertion to `:772`**. The builder had dismissed it as *pre-existing*. The
reviewer **proved that premise false** and the orchestrator confirmed it: at
`321dced`, `:668` **was** `[ "$PASS" -ge 40 ]`; commit 1 bumped the reference in
three places and **missed the table**, and `:668` had drifted onto a comment
line — so the file contradicted itself about the same assertion.

**Nothing machine-checks that table**, which is precisely why a green suite was
not evidence against it. Closed by the orchestrator in the `tiny` lane as a
second amend of commit 2. Re-verified at `2a3c9b3`: no `:668` references remain,
all four sites agree, `scan-controls.sh check` exit 0, suite 1418/0 unmoved, tree
clean, `86c8f93` still an ancestor.

### Codex second-eyes: NOT fulfilled

`build-os/memory/tool_router.md:368` declares a **Second-eyes code review** row
routing the reviewer to Codex (`codex` CLI / Codex-for-Claude-Code plugin).
**`codex` is not on PATH and no Codex plugin is installed**, so that row went
**unfulfilled in BOTH the review and the re-review**.

**Both verdicts in this packet are single-model.** Record this as an
**unfulfilled declared capability, not a pass.** It matters more than usual here:
the artefact under review is a registry whose entire purpose is to stop a control
from overstating its own evidence, and the defect that mattered most was a
judgement call about the strength of an argument — exactly the class of finding a
second model is for.

## The precedent this packet set

**New Class-C controls ship at `advise` by default; promotion to `gate` is a
separate governance action.** `bandwidth.packet_commit_ceiling` is the first
control shipped under it: two-commits is a constant the working contract chose,
nothing measured it, and *a heuristic does not become a gate by being useful*.

**This is forward-facing only.** It does **not** generalise backward to the
existing 13 declared mismatches — the reviewer ruled they are **not one
population** and must not be swept by a single rule.

## The ladder is still used at two rungs of five

`rank` and `observe` remain **0 of 75**. The authority ladder has five rungs and
this census uses two. A distribution of 64/11/0/0 carries almost no information,
and reaching for `gate` a third time would have been the reflex — splitting the
two bandwidth dimensions into separate entries *because they are different
evidentiary classes* is the only reason the thin rung grew at all.

## Residue

Full detail in `build-os/memory/residue.md`; the open follow-ons this packet
leaves:

1. **`swarm-merge.sh` disjointness has FALSE NEGATIVES** — `src/*.ts` and
   `src/foo*` both match `src/foo.ts` and are not reported as overlapping. The
   backstop at `:363` only covers **pre-existing** paths and only when `--repo`
   is passed.
2. **`tests/entitlement_tests.sh:296-305`'s hardcoded 12-file `PACKET_FILES`
   list decays silently** as the tree grows. **This packet added two shell files
   it does not cover.**
3. **Nothing asserts `active_packet.md` exists and is tracked** — which is the
   singleton gate's own disclosed evasion.
4. **`maint.tripwire_coverage_scan` is registered `refuted` and still gates.**
   The reviewer called it the strongest demotion candidate in the census.
   **BLOCKED on the authority envelope** — re-authorising is the operator's call.
5. **Nothing machine-checks `MISMATCHES.md` §10's file/lines table.** That is
   exactly how the `:668` drift survived a green suite. The
   `entitlement.egress_scan` technique-limit disclosure was added, but the table
   itself remains hand-maintained.
6. **`current_state.md`'s suite count could not be fully corrected by this
   close — see below.** It is recorded, not silently dropped.

## The stale suite count: partially BLOCKED, and why

The orchestrator handed this to the archivist as a fix. **It is only half
fixable from inside the archivist's gate**, and the reason is itself a finding.

`tests/release_metadata_tests.sh` §5 reads the one
`**Build/test command:**` line in `current_state.md`, extracts the first
`[0-9]+ checks`, and then requires that **`CHANGELOG.md` contain the literal
string `<count> passed`** (`grep -qF`). Measured, not assumed:

- Setting the line to the true `1418 checks` turns the suite **RED** —
  `41 passed, 1 failed`, *"CHANGELOG does not report '1418 passed'"*. CHANGELOG
  line 96 reads `Suite **1338 → 1418** passed`, so the literal `1418 passed`
  does not occur.
- **`CHANGELOG.md` is outside the archivist's write gate**, so the matching edit
  is not mine to make.

So the number is left at `657` **on that one guard-bound token only**, and the
line now states the live total loudly next to it. The full fix is a one-line
CHANGELOG edit in a follow-on packet.

**The second finding is worse than the first.** The staleness guard **does not
detect staleness by default** — it detects **cross-file disagreement**. Two stale
files that agree pass. Proven both directions at `2a3c9b3`:

- default run: suite **1418 / 0 green** while `current_state.md` claims **657** —
  a number **761 checks stale**, and the guard named "staleness guard" is silent.
- `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh` →
  `FAIL: live suite total (1418 passed) contradicts current_state.md's claim
  (657) — the memory is stale`. **The check that works exists and is off by
  default**, and is not enabled by the chained suite.

## Open boundaries (nothing done without go)

- **Nothing pushed, merged, tagged, deployed or PR'd.** Local commits only.
- No secrets touched. No `git config`.
- `/home/user/empathiq-website` untouched, preserved read-only at `cb2bb7d`.
- The branch is **unpushed** and remains so pending explicit go.
- Re-authorising `maint.tripwire_coverage_scan` (residue #4) is an **operator
  decision** and is deliberately not taken.

## A note on this close's own measurement hygiene

The archivist's first full-suite run returned **1417 / 1** and was **discarded as
contaminated**: it was launched in the same parallel block as a probe that edited
`current_state.md`, so the chained staleness guard read the file mid-edit. That
is the tree-quiet violation `CLAUDE.md` names, committed by the agent whose job
is recording measurements. The reported **1418 / 0** is a clean re-run against a
quiet tree at `2a3c9b3` with `git status --porcelain` empty. Recorded rather than
quietly re-run, because a discarded measurement that goes unmentioned is the same
failure the metrics store exists to prevent.

**The repo's own guards then caught this close.** The first complete draft of
this receipt turned the suite **RED at 1416 / 2** — `tests/metrics_adoption_tests.sh`
and `tests/lane_declaration_tests.sh` both run `check-adoption.sh` against the
live repo, and it refused with `UNATTRIBUTED`: the metrics row named two commits
and the receipt carried **no file-ownership manifest**. The guard named the
defect, named the remedy, and explicitly warned against closing the gap by
widening its dated boundary. The manifest above is the fix, written rather than
waived. Two things are worth keeping from that: the adoption guard's value was
demonstrated **against the archivist**, which is the role most able to paper over
its own gaps; and it is a counter-example to this packet's own central finding —
here the mechanical guard *did* catch the defect, because "does a receipt contain
a manifest" is a structural question, unlike "is this control's class argument
sound", which is not.

Final state after the fix: `bash tests/build_os_tests.sh` → **1418 passed / 0
failed**, `check-adoption.sh` → exit 0, `record-packet.sh --verify-git` →
`6 ok, 0 mismatched, 0 unverifiable`.
