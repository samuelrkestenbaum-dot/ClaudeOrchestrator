# Gravito runtime — versioned, installable

**Why this exists (operator's words):** *"The customer should not manually copy
five scripts and several contracts."* The empathiq pilot proved the copied
install works — five executables byte-identical, three contracts with
installed-copy headers, settings.json hook wiring, a .gitignore stanza. This
directory turns that proven-by-hand pattern into a versioned runtime with an
installer, drift detection, and a reversible lifecycle.

## What ships (MANIFEST.json, currently v0.1.0)

| File | Mode | Installed-copy header |
|---|---|---|
| `.claude/hooks/routing-gate.sh` | executable | no (byte-identical) |
| `build-os/tools/route-task.sh` | executable | no |
| `build-os/tools/mode-select.mjs` | executable | no |
| `build-os/tools/routing-check.sh` | executable | no |
| `build-os/tools/record-degradation.sh` | executable | no |
| `build-os/memory/routing_contract.md` | contract | yes |
| `build-os/memory/routing_contract_live.md` | contract | yes |
| `build-os/memory/provider_adapter_contract.md` | contract | yes |

Plus, carried in the manifest itself: the four `settings.json` hook entries
(gate / mutgate / count / post) merged additively, and the `.gitignore` stanza
(receipts tracked, live ledgers untracked) appended line-by-line if absent.

Every file entry carries a sha256 **computed from this repo's actual files at
release time** — the manifest is evidence, not intention.

## Subcommands (`gravito-runtime.sh`)

- `version` — recompute canonical shas vs MANIFEST; `RUNTIME: CLEAN` or
  `RUNTIME: DIRTY` (exit 2). A dirty canonical also refuses to install or
  upgrade — unversioned content never ships.
- `install <target-repo>` — two-phase: check everything, then act, so a refusal
  copies **nothing**. Refuses if any target file exists with different content
  (no-overwrite guarantee); identical content is idempotent-ok. Contracts get
  an installed-copy header (source commit auto-derived from git, install date,
  explicit no-auto-update statement). Writes
  `build-os/runtime/INSTALLED_VERSION.json` (version, source commit, date,
  per-file sha256 of both the installed file and its canonical source) and a
  migration receipt under `build-os/runtime/receipts/`.
- `status <target-repo>` — honest three-state per file:
  `current` | `drifted-local` (target no longer matches what was installed) |
  `upgrade-available` (canonical source moved since install).
- `upgrade <target-repo> [--force-theirs]` — explicit only. Refuses while any
  file is drifted-local; `--force-theirs` backs the local copy up to
  `build-os/runtime/backup/<timestamp>/` before replacing it. Writes a receipt
  with from/to versions.
- `rollback <target-repo>` — restores every file (including
  INSTALLED_VERSION.json) from the most recent backup dir; receipt.
- `uninstall <target-repo>` — removes ONLY manifest-listed files whose content
  still matches the install record, removes only deep-equal copies of our
  settings hook entries and our exact .gitignore lines. Customer files,
  customer hooks, locally-modified copies, receipts, and backups all stay.
- `regen-manifest --version <v>` — cut a new release manifest from the current
  canonical tree (the release step).

## Proof

`tests/runtime_version_tests.sh` — standalone, fixture-driven (mktemp canonical
+ target repos; a target with pre-existing customer hooks must survive merge
and uninstall). Covers install idempotence, no-overwrite refusal, the drift
three-state, upgrade refusal on local drift, backup + rollback round-trip,
uninstall preservation, and DIRTY detection.

## Known limitations (honest)

- **Single-source, single-target:** one canonical repo, one target per
  invocation; no registry/index of installs, no multi-target orchestration.
- **No package distribution:** installs from a local checkout of this repo —
  no tarball, npm/registry artifact, or remote fetch.
- **Settings merge is additive-only and structural:** dedup is deep-equality
  on our exact entries; a customer who *edits* one of our entries makes it
  customer-owned (uninstall will leave it, by design). Non-hook settings are
  never touched. JSON comment/formatting preservation is not attempted —
  files are rewritten as 2-space-indented JSON.
- **Header detection is first-line based:** a customer file whose first line
  coincidentally starts with the installed-copy marker would be treated as an
  installed contract.
- **Upgrade takes files wholesale** (theirs or refuse) — no three-way merge of
  local contract edits.
- **Rollback restores the latest backup only** — no selection of older backups
  from the CLI (they remain on disk under `backup/`).
