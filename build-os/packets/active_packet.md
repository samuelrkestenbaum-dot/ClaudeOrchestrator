# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** in flight — implemented and committed locally; awaiting qa →
  reviewer → archivist. Nothing pushed.
- **Packet id:** `gravito_neurocosmology_crosswalk_a`
- **Lane:** `substantive` (builder → qa → reviewer → archivist)
- **Title:** The Neurocosmology-to-runtime translation layer — bind every
  control to the universal function it instantiates

## Goal / "done" criteria

`build-os/registry/neurocosmology_crosswalk.txt` binds each of the **71**
registered controls to exactly one of **17** primitives and records, per
primitive, what the bindings **miss**; `CROSSWALK.md` reports the coverage and
the empty primitives; `bash tests/neurocosmology_crosswalk_tests.sh` pins both
against the census.

**The deliverable is a classification, not an implementation.** No mathematics
was built — no Φ, no coherence measure, no goal ecology, no value-of-information
term, no learned model — and no control was created or authority granted. A
conceptual equation must not control production before its quantities are
computable.

## In scope

- `build-os/registry/neurocosmology_crosswalk.txt` (new — 17 primitive records,
  71 binding records, the registry's own stanza format)
- `build-os/registry/CROSSWALK.md` (new — representation argument, coverage
  table, the empty primitives, the nominal-only primitives)
- `tests/neurocosmology_crosswalk_tests.sh` (one new suite, 40 assertions)
- `tests/build_os_tests.sh` — the one `chain_suite` line that wires it
- `build-os/registry/control_registry.txt` — entry 71
  (`suite.neurocosmology_crosswalk`), forced by `scan-controls.sh`; plus the
  eight `evidence_refs` the wiring line shifted
- `build-os/registry/README.md`, `MISMATCHES.md`, `CHANGELOG.md` — census size
  70 → 71 and ref total 227 → 235
- `build-os/packets/active_packet.md`

## Out of scope (explicit)

- **Implementing any primitive.** Naming `valence` empty is not an argument that
  Gravito should compute valence. The registry makes the current state legible
  so the operator can decide; this adds one axis and stops.
- **Re-authorising anything.** No control's class or authority changed. The
  crosswalk copies both and a test fails on drift.
- **`build-os/memory/*`.** `current_state.md` states a stale suite count (657
  against a live 1338) — pre-existing, not caused here, and archivist territory.
  Flagged rather than fixed, to keep this packet's scope honest.
- **Recording a metrics row.** Per the convention set by
  `gravito_speed_benchmark_a`, the archivist appends the row at close.
- **`/home/user/empathiq-website`** — untouched reference deployment at `cb2bb7d`.
- **Pushing, merging, tagging, `git config`.** Local commits only.

## Branch base

- `claude/project-handoff-merge-ramhds` at `e8f34ed`; merge-base with
  `origin/claude/add-build-os` = `7ef50e8`. Verified before building.

## Plan (≤2 commits)

1. **Commit 1 (green in isolation) — `00e4c8f`:** the test written first (red:
   30 passed / 6 failed, exit 1 — the artefact and its report did not exist),
   then the crosswalk, the report, the chain wiring, and the registry entry that
   `scan-controls.sh` demanded. Suite **1338 passed / 0 failed**
   (1298 → 1338, +40 from the new suite).
2. **Commit 2 (also green):** the `[Unreleased]` changelog entry and this packet
   record.

## What the guards did to this packet's own work

Two fired, and both were obeyed rather than worked around — which is the only
evidence that they bite on their author as well as on a fixture:

- `scan-controls.sh` refused the tree: a new `tests/*.sh` that can exit non-zero
  is a control surface, so it demanded registration. Entry 71 was added, which
  in turn moved the census size and the ref total in four artefacts.
- `tests/control_registry_tests.sh` §21 caught a **fitted 120-character floor**
  inside the new suite — an unregistered heuristic constant that could stop a
  build. It was replaced with a floor **derived per record** (what a primitive
  misses must be told at least as fully as what it intended), so the suite states
  no numeric literal and does not join the `tests.nonvacuity_minimums` family.

Inserting one `chain_suite` line also shifted eight `evidence_refs` into
`tests/build_os_tests.sh` by one. Three went vacuous and were caught; five
landed on real-but-wrong lines and were **not** caught — a live instance of
README §4's line-citation fragility. All eight are corrected.

## The finding, in one paragraph

`runtime_authority: rank` is held by **0 of 71** controls; 61 gate and 10 advise,
and every one answers yes/no about an artefact that already exists. So the
valuation half is empty of function: `meaning_metric`, `valence` and
`goal_ecology` have zero bindings, and `mass` and `wisdom` carry one **nominal**
binding each — the only ordering in the system takes `inputs: none`, and the only
control that selects gets no outcome feedback. **`integration_bandwidth` is empty
and was not predicted:** the entire theory of work-in-flight is prose in
`CLAUDE.md`, not a control. The sharpest result is `ethical_admissibility` — one
provenance check, while the rule *never push, merge, deploy, publish or touch
secrets* has **no registered control at all**.

**Revised on review, downward.** The coverage split was first stated as 32
instantiate / 36 proxy / 3 nominal; it is **27 / 38 / 6**, with only **6 of 17**
primitives holding any instantiating binding. Eight labels were demoted because
each contradicted its own entry's `known_limitations` — the packet's own defect
class, found in the packet. `boundary`, `durability` and `energy` fall to zero
instantiating bindings, and `ethical_admissibility` joins `reachability`, `mass`
and `wisdom` as **nominal-only**, so the provenance check above is not merely
weak coverage but, by this file's rule, **not coverage at all**.

---
_Set by the builder for `gravito_neurocosmology_crosswalk_a`. The archivist clears this on close._
