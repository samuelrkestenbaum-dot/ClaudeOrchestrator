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
  Pinned by `tests/speed_benchmark_tests.sh` (128 checks), whose load-bearing
  assertions are that report totals equal the sum of the *rendered* rows, that
  every seeded row carries an attribution, that a row contradicting git fails,
  and that a report over zero rows refuses loudly instead of printing an empty
  green table.
- All sibling suites are chained into `bash tests/build_os_tests.sh`, which now
  reports **616 passed** and fails if any suite in `tests/` is left unchained.
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
