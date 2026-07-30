# gravito_productization_pa_maintenance_upstream_a (P-A) — upstream the memory maintenance + safety layer into the product

- **Date:** 2026-07-30
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `d3d8305` (parent of `c30f77d`; merge-base with `origin/claude/add-build-os` = `7ef50e8`)

Ports the rotation / tripwire / sanctioned-wrapper layer proven in a **reference
deployment** into the product, so a blank customer repo receives the same
load-bearing protections — **without** that deployment's state, and **without**
clobbering anything the customer already has.

## Scope

- **In:** `build-os/maintenance/` (the ported layer + its installer + manifest),
  installer wiring into both customer entry points (`init-build-os.sh`,
  `install-project.sh`), a contract-only `build-os/memory/standing_gates.md`,
  the cold-install suite `tests/build_os_maintenance_tests.sh`, and its chaining
  into `tests/build_os_tests.sh`. Docs follow-through in `README.md` /
  `INSTALL.md`.
- **Out (explicit):** the reference deployment's **standing_gates.md content**
  (its live hard-stop inventory) — the concept ships as a **contract-only
  template**, the content does not ship. Every dated pass-count from that
  deployment is dropped and its surrounding claim reduced to its shape ("the
  suite stayed green — 0 fail, exit 0"), anchored to the reference deployment at
  `cb2bb7d`. Tree-size measurements survive only where the pressure is the
  point, attributed and disclaimed.
- **Out (explicit, flagged not fixed):** the `init-build-os.sh` **seeding leak** —
  it seeds scaffolds from this repo's **live** memory files. This packet adds
  nothing to that leak (its two scaffold additions come from clean templates)
  and does **not** fix it. Flagged `BLOCKED` in `PORTING.md`; follow-on packet.

## What arrives

- `build-os/maintenance/rotate-memory.{mjs,sh}` — byte-exact **recency** rotation
  with an append-only archive + `INDEX`.
- `build-os/maintenance/real-memory-tripwire.mjs`, `source-scan.mjs`,
  `rootscan-controls.json` — the real-memory tripwire and its controls.
- `build-os/maintenance/run-tests.sh` — the **sanctioned wrapper**: `--import`
  preload plus shell fingerprints either side of `node`.
- `build-os/maintenance/rotate-memory.test.mjs`,
  `rotate-memory.rootscan.test.mjs` — the two cross-scanning suites.
- `build-os/maintenance/install-maintenance.sh` — MANAGED files replaced every
  run and marked `GRAVITO:MANAGED`; CUSTOMER files (`standing_gates.md`) seeded
  only if absent; `.gitignore` archive exception appended once;
  `test:build-os-memory` added **only** where a `package.json` already exists.
- `build-os/maintenance/PORTING.md` — the manifest, including what the proof does
  **not** cover.

**File count, verified in this session:** the installer's `MANAGED` array (and
therefore the generated `.gravito-managed` manifest) lists **11** files. Eight of
those are the ported layer proper; the remaining three —
`install-maintenance.sh`, `templates/standing_gates.md`, and `PORTING.md` — were
authored *for* the port rather than ported. Both numbers are correct under their
own definition; the manifest number is **11**.

## The load-bearing adaptation

`FILE_SPECS`' delimiters are coupled to the scaffold's memory format. The
reference `current_state` delimiter finds **0 blocks** in a scaffolded file, and
a delimiter that matches nothing **does not error** — it reports a NO-OP at exit
0, i.e. **a file that silently never rotates**. All three specs now use `^## `,
the coupling is documented at the declaration, and an executed test refuses any
rotating file that parses to zero blocks.

**And that no-op is no longer silent.** One `already rotated (no-op)` line was
printed, byte for byte identically, for three unrelated states: a delimiter that
matched nothing in a file that **has** content (the hazard), an empty or
whitespace-only file, and a file that parsed fine with nothing old enough to
archive. Zero blocks **plus non-whitespace content** now writes a warning to
**stderr** naming the file and the delimiter that matched nothing. The exit code
is deliberately unchanged — an empty scaffold parses to zero blocks legitimately
— and `--json` carries the signal as `originalHasContent`. One executed test
pins both directions; both were red-driven.

## The cold-install suite RUNS, rather than being pointed at

`tests/build_os_tests.sh` chains `tests/build_os_maintenance_tests.sh` and folds
its counts into its **own totals** — not into a single pass/fail, which would
report the same green if 60 of its 61 assertions stopped running. A second suite
that has to be remembered is a second suite that gets skipped. Measured before
choosing: 11.5 s + 13.0 s alone, 25.0 s chained. Both failure paths of the chain
were red-driven (an injected assertion failure; a suite that dies before its
`RESULT` line).

## Commits

- `c30f77d` feat(build-os): ship the memory maintenance + safety layer (Gravito P-A)
- `5b956c0` docs(build-os): document the maintenance layer in README and INSTALL

## QA proof

Re-run **in this session** at tip `641527f` (which also carries the later
stdin-hang fix, hence 281 rather than the 277 recorded at `5b956c0`):

- Suite: `bash tests/build_os_tests.sh` → **281 passed, 0 failed** (exit 0),
  including `CHAINED: 61 passed, 0 failed`.
- Maintenance layer: `./build-os/maintenance/run-tests.sh` → **144 passed,
  0 failed** (exit 0; 30 suites, 0 skipped, 0 todo).
- Cold install: `tests/build_os_maintenance_tests.sh` → **61 passed, 0 failed**,
  observed via the chain line above.
- As recorded at the packet's own tip (`5b956c0`, from the commit message, not
  re-run here): **277 / 144 / 61**, all 0 fail.
- Commit-1 isolation: **not independently re-verified in this session** — the
  packet's commits are already merged into the branch history and were not
  re-checked out. Recorded as **unverified here**; the original packet asserted
  `c30f77d` green on its own.
- Safety grep: no push / merge / deploy / publish; no secrets touched. Local
  commits only.
- UI smoke: N/A.

The cold-install suite is deterministic and offline (blank temp git repos only).
It proves fresh install + green wrapper, byte-identical re-install, preservation
of a customer `CLAUDE.md` / gates file / memory file / `.gitignore` /
`package.json`, byte-exact conservation over a 186 KB synthetic fixture with a
correct archive + `INDEX`, the wrapper going RED on mutation of the never-rotated
authority, the bare `node --test` path measured as unguarded, and an exact
uninstall boundary.

## Review

- **Verdict: pass**, after **one fix-then-pass round (5 items)**. The two named
  here are the substantive ones: (1) a **runtime warning** for a wrong-delimiter
  file that previously printed a false "already rotated" health message; (2)
  stale reference measurements **re-anchored** (dated pass-counts from the
  reference deployment dropped, the surviving count re-measured in this port on a
  fresh install into a blank repo). (3) the cold-install suite **wired into the
  normal flow** rather than being discoverable-only. The remaining 2 of the 5 are
  recorded in the packet's own review thread and are **not restated here**
  (unverified from this session's evidence).
- **Codex second-eyes: not available.** Checked and unavailable on **every**
  pass. Every reviewer verdict in this work is therefore **single-model** and has
  **no** independent second-model corroboration.
- Product Trajectory Check: moves the product from "orchestrator only" toward
  "orchestrator that protects its own memory in a customer repo".

## Residue

- **`init-build-os.sh` seeding leak** — open, flagged `BLOCKED` in `PORTING.md`;
  a sibling packet in this same session is fixing it. Not fixed here.
- **Single-platform proof** — everything was measured on **one Linux machine's**
  `node`/`git`/`bash`. The `sha256sum` / `shasum` branch exists for macOS but has
  **not** been executed, and no other platform was tested at all. Stated in
  `PORTING.md` and in `CHANGELOG.md` → *Known limits*.
- **Rotation is recency-only** — meaning is not preserved; `standing_gates.md` is
  the never-rotated home. **The wrapper detects rather than prevents.**
- **Uninstall boundary** — removing the layer never removes `build-os/memory/`,
  including the archive, which is the only copy of anything already rotated out.
- No push / merge / deploy; no secrets touched.
