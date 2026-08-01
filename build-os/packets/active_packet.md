# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: NO PACKET IN FLIGHT

`gravito_p1_mutators_ids_telemetry_a` (`PACKET-0006-gravito-p1-mutators-ids-telemetry-a`)
**closed 2026-08-01** — receipt at
`build-os/receipts/gravito_p1_mutators_ids_telemetry_a.md`, commits `f27c570` +
`a75c25e`, base `7daedee` (re-verified: `git merge-base a75c25e 7daedee` = `7daedee`),
plus this close commit. Verdict **pass as fixed** — qa **RED, documentation-only, with
ZERO test failures**; reviewer **`fix-then-pass` twice** (11 items, then 6). All fix
rounds landed and were re-verified: **13 reconciled items in one installment**, then
**7 artefact sites** closed by the orchestrator in the `tiny` lane.

**What it did.** Made every durable-write path in the repository visible to the
authority model, and started collecting structured decision data.
`build-os/registry/mutator_registry.txt` censuses them as `MUT-0001`..`MUT-0008`;
**`execute` got its FIRST SIX OCCUPANTS** — `maint.rotation_live_file_replacement`,
`swarm.merge_commit_execution`, `metrics.record.store_append`,
`metrics.decision.store_append`, `identity.stamp_write`, `tools.handoff_lock_lifecycle`.
**Census 81 → 90**, authority **71 `gate` / 13 `advise` / 6 `execute` / 0 `rank` /
0 `observe` / 0 `none`**, **20 declared mismatches**. Plus stable IDs at birth
(**line numbers are navigation hints, not identity**), `defect_classes.txt` (twelve
queryable classes), `governance_baseline.txt` (all 81 pre-existing controls pinned),
`findings.txt` (`FINDING-0001`/`-0002`/`-0003`, remedies **named and unapplied**),
`record-decision.sh` + decision telemetry + frozen signal snapshots, the new suite
`tests/mutator_registry_tests.sh` and the new scanner `scan-mutators.sh`.

**What it changed about any pre-existing control's licence: NOTHING.** **Zero
governance-field changes.** The six new controls are out of licence **by
construction**, because **no class licenses `execute`** — that is the registry
correctly reporting an undecided question, not a defect in the registrations.

**Final state at `a75c25e`:** suite **1689 passed / 0 failed**;
`./build-os/maintenance/run-tests.sh` **144/144**; `scan-controls.sh check` **exit 0**;
`scan-mutators.sh check` **exit 0**; `evidence-policy.sh check` **25 of 90, split
6/5/14**; tree clean.

## THIS FILE'S SHAPE IS LOAD-BEARING — it must carry ≥3 `^## ` blocks

**Do not clear this file to two headings.** `rotate-memory.mjs`'s `FILE_SPECS` splits
it on `blockDelimiter: /^## /`, and the maintenance layer's two-pass rotation proof
(`tests/scaffold_seeding_tests.sh:242`) needs **≥3 blocks per rotating file**.

**This is not theoretical. It has already shipped red once.** The close of
`gravito_mismatch_refuted_a` left this file with exactly **2** blocks, so
`./build-os/maintenance/run-tests.sh` went **143/144** at `2df61ae` — **a commit that
was pushed.** That suite is **still not chained into the main suite** and nothing else
catches it, so **every close must run it AFTER its own writes.** This close did, and
the block count in this file was verified after writing.

**The sharper hazard, with its wording corrected.** A count of **0** means the
delimiter does not match the file's format at all and **nothing can ever rotate out of
it**. That state is byte-identical after `--apply`, exit **0**, and **nothing fails** —
but it is **NOT silent**: `rotate-memory.mjs` prints
`WARNING: <path>: the block delimiter /^## / matched NOTHING … NOTHING CAN EVER ROTATE
OUT OF IT` on stderr. **The failure mode is an IGNORABLE WARNING, not silence.**

The underlying control gap is still open: `bandwidth.active_packet_singleton` refuses
**two** declared packets but permits **zero**, so a packet that simply omits its
declaration passes clean. Residue **(c)** / **(u)**.

## Next — P2 CLAIM-SCOPED EVIDENCE, staged, NOT declared

**The operator's five-phase sequence supersedes the standing candidate list.**
**P1 mutators/IDs/telemetry is DONE.** The remaining four, in order:
**P2 claim-scoped evidence → P3 `accept_and_constrain` → P4 S1 shadow ranker →
P5 outcome/counterfactual telemetry.**

**P2 CARRIES ONE HARD OBLIGATION INHERITED FROM P1, AND IT IS THE MOST IMPORTANT LINE
IN THIS FILE.** P1 recorded **12 signal snapshots across ALL FOUR candidates of
`DECISION-0007-p1-mutators-ids-telemetry`, including the THREE NOT SELECTED** — which
is what makes it a **counterfactual** substrate rather than an imitation-learning one,
because imitation learning needs only the selected arm. But `DECISION-0007` is the
**only** decision with a non-degenerate candidate set: `DECISION-0001` selected all
three of its candidates, and `DECISION-0002` through `DECISION-0006` are **|C| = 1**.

> **P2 AND P3 MUST KEEP RECORDING REJECTED CANDIDATES OR P4 STARTS AT n = 1.**

Also inherited, and to be swept **before** any new prose is written: the fifth escape
form is the **file header comment**, which reaches no field-scoped sweep, and a sweep
must hit the **SOURCE ARTEFACT** before the **DERIVED DOC** — correcting
`CROSSWALK.md` while leaving `neurocosmology_crosswalk.txt` wrong means the next
regeneration reintroduces the defect. Residue **(tt)** / **(uu)** / **(vv)**.

**Blocked on the operator and NOT schedulable:** applying any `FINDING-*` remedy (each
is a re-authorisation); whether any class should license `execute`; the two S1
decisions (the evidence token, and the `runtimeAuthority: observe` recommendation,
which is **advice and not adopted**). See `build-os/memory/current_state.md` → *Next*
and `build-os/memory/residue.md`.

## Declaring the next packet

Write the declaration **into this file, as its own commit, BEFORE the builder's first
edit to any other file.** Two packets running have now proved that works: Commit 1 is
the declaration **alone** — trivially green in isolation, keeps the ≤2-commit cap, and
**lets git attest the ordering** without a third commit and without a pre-commit hook.
Nothing requires the docs to be the second commit.

Keep the declaration at **≥3** `^## ` blocks from the moment it is written, and verify
the count before committing.
