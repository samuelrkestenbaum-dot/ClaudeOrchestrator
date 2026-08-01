# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: IN FLIGHT — `gravito_p2_claim_scoped_evidence_a`

- **Packet id:** `PACKET-0019-gravito-p2-claim-scoped-evidence-a`
- **Lane:** substantive — builder → qa → reviewer → archivist.
- **Declared:** 2026-08-01.
- **Decision id:** `DECISION-0008-p2-claim-scoped-evidence`, recorded with its
  **rejected candidates and their frozen signal snapshots** — see *The n=1
  obligation* below.

## Branch base

Branch `claude/project-handoff-merge-ramhds`, based at `e6b825b`.
**Verified before the first edit:** `git rev-parse HEAD` = `e6b825b`, and
`git merge-base HEAD e6b825b` = `e6b825b` — HEAD *is* the base, so the base is
an ancestor of HEAD trivially and no rebase is implied.

**≤2 commits.** Commit 1 is **this declaration alone** — trivially green in
isolation, and it lets git attest that the packet was declared before its first
implementation edit without spending a third commit or a pre-commit hook. Commit
2 carries the tests and the implementation.

## What this packet does — ONE evidence token cannot characterise a control

`gravito_mismatch_refuted_a` proved a control can be **refuted with respect to
one claim and supported with respect to another**, and that reasoning from the
bare token nearly caused a demotion **measured** to destroy live memory. The
canonical fixture, and the case that forced this packet:

```
subject: maint.tripwire_coverage_scan
claim A: detects uncovered behavior under bare `node --test`
         -> refuted
claim B: prevents destructive maintenance mutation under sanctioned
         maintenance invocation -> supported
```

**Those must not collapse into one global token.** So:

1. **A claim-scoped evidence store** — `build-os/registry/evidence_assertions.txt`,
   one stanza per assertion, keyed by a stable `EV-NNNN-<slug>` id, carrying
   `subject_id`, `claim_id`, `claim_text`, `status`, `scope`, `substrate`,
   `invocation_path`, `method`, `fixture`, `observed_result`, `interpretation`,
   `limitations`, `created_at`, `created_by`, `reviewed_by`, `valid_from`,
   `valid_until`, `artifact_refs`, `supersedes`. **A subject may carry many
   concurrent assertions.** Seeded with the tripwire A/B pair.
2. **`untested` is ADDED** to the evidence vocabulary — *has never operated
   against a live or representative task* — at the **most conservative cap on
   the ladder that is still a legal destination, `observe`**. This is a schema
   change with a guard consequence: `evidence.derivation_nonvacuity` refuses an
   **unrecognised** `empirical_status` at exit 2, deliberately, and **that guard
   is not weakened**. `untested` stops being unrecognised; every *other*
   unrecognised token still refuses, and the suite red-drives that.
3. **A deterministic compatibility projection** to legacy `empirical_status`,
   which **must not erase a contradictory claim**. Where several claim statuses
   exist it exposes the **composite**, never the status that permits greater
   authority — that selection is the flattering-direction error this repository
   exists to catch.
4. **The authority interaction is one-directional.** Evidence **may lower**
   authority and **may not raise** it. A scoped `supported` claim licenses only
   the consequence and scope it names, so it projects **globally** to
   `unvalidated` and never to `field_observed` — the legacy field carries no
   scope, and a scoped support claim cannot be spelled in it without
   overclaiming.

## Scope, and what is deliberately NOT in it

**In scope (the writable set):** `build-os/registry/evidence_assertions.txt`
(new), `build-os/tools/claim-evidence.sh` (new),
`tests/claim_evidence_tests.sh` (new), and the `untested` schema change where it
lands — `build-os/tools/evidence-policy.sh`,
`build-os/tools/authority-envelope.sh`, `build-os/registry/scan-controls.sh`,
`build-os/registry/scan-mutators.sh`, `build-os/registry/README.md`,
`build-os/registry/control_registry.txt`,
`build-os/registry/neurocosmology_crosswalk.txt`,
`build-os/registry/CROSSWALK.md`, `build-os/registry/MISMATCHES.md`,
`tests/build_os_tests.sh`, `tests/evidence_policy_tests.sh`,
`tests/control_registry_tests.sh`, `tests/authority_envelope_tests.sh`,
`CHANGELOG.md`, and the two telemetry stores under `build-os/metrics/`.

**Out of scope, and each is a refusal rather than an omission:**

- **Re-authorising anything pre-existing.** `governance_baseline.txt` pins all
  81 pre-P1 controls and will refuse it. `maint.tripwire_coverage_scan` keeps
  `class: C`, `runtime_authority: gate`, `authority_mismatch: declared` and
  `empirical_status: red_driven,refuted` **unchanged**. The new store is
  **additive and advisory**: it is read by nothing that grants authority.
- **Applying any `FINDING-*` remedy** — each is a re-authorisation.
- **Deciding whether any class should license `execute`** — 0 grid cells reach
  it before this packet and 0 after it; widening the evidence axis adds a
  column, never a grant.
- **Any external mutation.** Local commits only: no push, no merge, no tag, no
  PR, no deploy, no secrets, no `git config`.
- **`/home/user/empathiq-website`** (`cb2bb7d`) and **`build-os/memory/*`** are
  untouched.

## The known limitation, stated rather than implied away

The **legacy `empirical_status` field carries no scope**, and nothing this
packet does can give it one without changing a closed field list that
`scan-controls.sh` refuses to widen. So the projection is **lossy by
construction in exactly one direction**: it can carry a refutation out of a
scoped claim into the global field, and it **cannot** carry a support claim out.
That asymmetry is deliberate — it is the only direction that cannot flatter —
and the suite asserts it rather than leaving it to prose. **The claim-scoped
store, not the projection, is where a scoped support claim is legible.**

## The n=1 obligation inherited from P1

P1 recorded **12 signal snapshots across all four candidates of
`DECISION-0007`, including the three not selected** — which is what makes the
telemetry a **counterfactual** substrate rather than an imitation-learning one.
`DECISION-0007` is still the **only** decision with a non-degenerate candidate
set. So this packet records `DECISION-0008-p2-claim-scoped-evidence` with its
**rejected candidates and a frozen signal snapshot for each**, or P4 starts at
n = 1.

## Verification, run SEQUENTIALLY and read in full

P1's close violated tree-quiet by running three suites at once and produced a
spurious count whose failing assertion was then lost to a `tail`. **Each gate
runs to completion, alone, and its full output is read — no gate is piped
through `tail` before it is read.**

- `bash tests/build_os_tests.sh` — the exact new total (**1689 / 0** at base).
- `./build-os/maintenance/run-tests.sh` — **144/144**.
- `bash build-os/registry/scan-controls.sh check` — exit 0.
- `bash build-os/registry/scan-mutators.sh check` — exit 0.
- `bash build-os/tools/evidence-policy.sh check` — count and split, **with the
  delta from 25 of 90 / 6-5-14 explained**.
- If the suite total moves, `CHANGELOG.md` carries the new literal
  `<count> passed`, **unsplit by markdown**.
- `git status --porcelain` empty; HEAD reported.

## THIS FILE'S SHAPE IS LOAD-BEARING — it must carry ≥3 `^## ` blocks

**Do not reduce this file to two headings.** `rotate-memory.mjs`'s `FILE_SPECS`
splits it on `blockDelimiter: /^## /`, and the maintenance layer's two-pass
rotation proof (`tests/scaffold_seeding_tests.sh`, the two-pass rotation
section) needs **≥3 blocks per rotating file**.

**This has already shipped red once.** The close of `gravito_mismatch_refuted_a`
left this file with exactly **2** blocks, so `./build-os/maintenance/run-tests.sh`
went **143/144** at `2df61ae` — a commit that was pushed. That suite is **still
not chained into the main suite** and nothing else catches it, so **every close
must run it AFTER its own writes.**

The sharper hazard: a count of **0** means the delimiter does not match the
file's format at all and **nothing can ever rotate out of it**. That state is
byte-identical after `--apply`, exits **0**, and fails nothing — but it is **not
silent**: `rotate-memory.mjs` prints
`WARNING: <path>: the block delimiter /^## / matched NOTHING … NOTHING CAN EVER
ROTATE OUT OF IT` on stderr. **The failure mode is an ignorable warning, not
silence.**

The underlying control gap is still open: `bandwidth.active_packet_singleton`
refuses **two** declared packets but permits **zero**, so a packet that simply
omits its declaration passes clean. Residue **(c)** / **(u)**.
