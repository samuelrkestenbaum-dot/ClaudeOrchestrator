# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** in flight — implemented, **uncommitted**; awaiting qa → reviewer →
  archivist. The orchestrator merges and commits (this packet ran in parallel
  with sibling packets under strict file ownership).
- **Packet id:** `gravito_release_metadata_a`
- **Title:** Give the product a version, a changelog, a license, and current memory

## Goal / "done" criteria

- The repo carries `VERSION` (`0.1.0`), `CHANGELOG.md` (Keep a Changelog), and
  `LICENSE`, and `build-os/memory/` reflects reality rather than the stale
  "216 checks / last closed P-022" snapshot — with the whole thing pinned by
  `bash tests/release_metadata_tests.sh`, which goes **red** if the memory's
  claimed test count goes stale again.

## In scope

- `VERSION`, `CHANGELOG.md`, `LICENSE`
- `build-os/memory/current_state.md`, `build-os/memory/residue.md`
- `build-os/packets/active_packet.md`
- `build-os/receipts/` (new files only)
- `tests/release_metadata_tests.sh` (one new file)

## Out of scope (explicit)

- **Sibling-owned this session:** `.claude/**`, `CLAUDE.md`,
  `build-os/global-claude-md.md`, `build-os/memory/tool_router.md`,
  `build-os/memory/skill_budget.md`, `init-build-os.sh`, `install-*.sh`,
  `connect-project.sh`, `templates/**`, `build-os/maintenance/**`,
  `tests/build_os_tests.sh`, `tests/build_os_maintenance_tests.sh`.
- **Tagging** — the operator's call. No tags were created.
- **Pricing, entitlement keys, terms of service** — not invented; the license
  model is an open owner decision (see `residue.md`).
- **Committing / pushing** — left unstaged for the orchestrator.

## Branch base

- `claude/project-handoff-merge-ramhds` at `641527f`; merge-base with
  `origin/claude/add-build-os` = `7ef50e8`. Verified.

## Plan (≤2 commits)

1. **Commit 1 (green in isolation):** `tests/release_metadata_tests.sh` written
   first (red: 12 passed / 30 failed, exit 1), then `VERSION`, `LICENSE`,
   `CHANGELOG.md` and the `build-os/memory/` + `build-os/receipts/` refresh that
   turn it green. Single logical change; the orchestrator commits.
2. **Commit 2 (optional):** none required.

---
_Set by the builder for `gravito_release_metadata_a`. The archivist clears this on close._
