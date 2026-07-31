# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** in flight — implemented and committed locally. qa returned GREEN
  (1418/0); the reviewer returned `fix-then-pass`, and the fix round has been
  applied by amending commit 2. Awaiting the targeted re-review, then the
  archivist. Nothing pushed.
- **Packet id:** `gravito_census_gaps_egress_bandwidth_a`
- **Lane:** `substantive` (builder → qa → reviewer → archivist)
- **Title:** Close the two cheapest gaps the crosswalk found — register the
  egress scan, and build the first `integration_bandwidth` controls

## Goal / "done" criteria

Two census gaps, closed in one packet because the registry is a hot file: a
control addition cascades through `control_registry.txt`,
`neurocosmology_crosswalk.txt`, `CROSSWALK.md`, `README.md`, `MISMATCHES.md` and
`CHANGELOG.md`, all of which carry numbers now machine-reconciled across six
columns.

1. The egress scan inside `tests/entitlement_tests.sh` is registered as
   `entitlement.egress_scan` and bound to `ethical_admissibility`.
2. `integration_bandwidth` — zero bindings before this packet — gets controls for
   the capacity dimensions that are genuinely observable, and an explicit,
   recorded refusal for the ones that are not.
3. Every derived number is recomputed rather than hand-edited;
   `scan-controls.sh check` exits 0 and §10's six-column reconciliation passes.

## In scope

- `build-os/tools/bandwidth-check.sh` (new — the capacity tool)
- `tests/bandwidth_tests.sh` (new suite, 41 assertions)
- `tests/build_os_tests.sh` — the one `chain_suite` line that wires it
- `tests/control_registry_tests.sh` — §26, §26a, §26b (the egress registration,
  the external-boundary ruling, and the containment red drive)
- `tests/neurocosmology_crosswalk_tests.sh` — §14, §15 (what the two moved
  primitives may not claim, and five removal red drives)
- `build-os/registry/control_registry.txt` — four new entries and the
  `evidence_refs` the two wiring lines shifted
- `build-os/registry/neurocosmology_crosswalk.txt` — four bindings, two rewritten
  primitive records
- `build-os/registry/CROSSWALK.md`, `README.md`, `MISMATCHES.md`, `CHANGELOG.md`
- `build-os/packets/active_packet.md`

## Out of scope (explicit)

- **A repo-side gate on push / merge / deploy / publish / secrets.** Ruled out,
  not deferred. That rule is enforced by the operator's permission system, a
  process boundary outside this repository; anything that could bypass it
  bypasses a repo-side check trivially, so a repo-side gate would convert a real
  external boundary into a checkbox that looks enforced and is not.
- **A round-budget or depth guard.** Serial agent stages are transcript-only.
  Nothing in git attests to them, the lane-declaration packet already declined a
  round-budget guard for this reason, and a control claiming a limit it cannot
  observe is worse than an absent control.
- **A ceiling on concurrent write sets.** Observable from a fan-out manifest,
  but no ceiling is declared anywhere in the working contract, so enforcing one
  would mean inventing a constant.
- **A composite load score.** `I = w₁·packets + w₂·commits + …` is the
  anti-pattern §15.1 names: unjustifiable weights, and one number that hides
  which dimension is saturated.
- **Re-authorising anything.** No existing control's class or authority changed.
- **`build-os/memory/*`.** `current_state.md` still states a stale suite count —
  pre-existing, archivist territory, flagged rather than fixed.
- **Recording a metrics row.** The archivist appends it at close.
- **`/home/user/empathiq-website`** — untouched reference deployment at `cb2bb7d`.
- **Pushing, merging, tagging, `git config`.** Local commits only.

## Branch base

- `claude/project-handoff-merge-ramhds` at `321dced`; merge-base with
  `origin/claude/add-build-os` = `7ef50e8`. Verified before building.

## Plan (≤2 commits)

1. **Commit 1 (green in isolation) — `86c8f93`:** the bandwidth suite written
   first (red: 4 passed / 37 failed, the tool absent), then the tool, the four
   registry entries, the four bindings, the two rewritten primitive records, the
   recomputed report, and the two suite extensions. Suite **1418 passed / 0
   failed**; `scan-controls.sh check` exit 0.
2. **Commit 2 (also green):** the `[Unreleased]` changelog entry and this packet
   record. **Amended once, in the fix round**, to carry the reviewer's eight
   items — the class demotion above and the census counts it moves (mismatches
   **13 → 14**, fitted-constant sites **55 → 56**), a corrected
   `known_limitations` for `integration_bandwidth`, and the egress scan's
   previously undisclosed *technique* limit. Commit 1 (`86c8f93`) was left
   byte-identical, so qa's Commit-1-green-in-isolation proof still stands.
   Registering a control and correcting its class on review is honest history,
   and it is why the packet is still two commits.

## The authority argument, since it was asked for

The census reads **64 `gate` / 11 `advise` / 0 `rank` / 0 `observe`** — a ladder
used at two rungs of five, which carries no information. Reaching for `gate` a
third time would have been the reflex. The two dimensions were split into two
entries **because they are different evidentiary classes**, and the class decides
the licence:

- **`packets` gates, and is Class C — demoted on review.** It was built Class A,
  on the argument that the ceiling is not a fitted number but this file's own
  definition, with the counter-argument *recorded rather than answered*. Review
  answered it, against the entry: **"one packet at a time" is nowhere in
  `CLAUDE.md`** — it is a sentence in this file's own prose header, so the
  ceiling rests on a docstring inside the artefact the control reads, which is a
  WIP limit somebody chose. The analogy to `metrics.record.one_row_per_packet`
  was dropped rather than defended: a second metrics row corrupts
  `report-speed.sh`'s totals, whereas nothing consumes this control's exit code,
  so a breach here contradicts prose and corrupts no number. **The authority
  stayed at `gate` and the mismatch is now declared** — the fourteenth — because
  clearing a mismatch by re-authorising is the operator's call, not the
  builder's. `MISMATCHES.md` §14 carries the argument.
- **`commits` is Class C and only advises.** Two is a constant the working
  contract chose; nothing measured it. A heuristic does not become a gate by
  being useful, so it sits at the top of its licence and declares **no**
  mismatch — the honest option, and the one that adds to the thin rung instead
  of the crowded one. Its second weakness is named in the entry: the base is
  **self-declared by the agent the dimension constrains**, so only the
  declaration's *resolvability* is checkable.

## What the guards did to this packet's own work

- `scan-controls.sh` refused the tree twice: once for the new tool (a file that
  can exit non-zero is a control surface) and once for the new suite. Both were
  registered rather than exempted.
- The vacuous-ref check caught four citations on the day they were written — a
  blank line, a lone `else`, and two lines shifted by the `chain_suite` insert.
- Adding a section to `tests/control_registry_tests.sh` shifted its own
  registered `-ge 40` floor, and §21 caught the stale ref in both directions.
- §10's six-column reconciliation refused nine hand-stale cells in
  `CROSSWALK.md` before they could ship.

## The finding, in one paragraph

`integration_bandwidth` is no longer empty, and **two of its four conventions are
declined out loud rather than left implied**: depth is transcript-only and open
write sets have no declared ceiling. `ethical_admissibility` is off nominal-only
for the first time — and the sentence that matters is the one that did *not*
change: the strongest rule this system states about itself still has **zero
registered controls**, because its enforcement is a process boundary outside this
repository and belongs there.

---
_Set by the builder for `gravito_census_gaps_egress_bandwidth_a`. The archivist
clears this on close._
