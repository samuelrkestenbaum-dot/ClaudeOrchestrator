# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Status:** in flight — implemented and committed locally; awaiting qa →
  reviewer → archivist. Nothing pushed.
- **Packet id:** `gravito_speed_benchmark_a`
- **Lane:** `substantive` (builder → qa → reviewer → archivist)
- **Title:** Build the instrument that turns "20x-100x faster" from an argument
  into a measurement

## Goal / "done" criteria

`build-os/metrics/` carries a working, dependency-free measurement instrument —
a recorder, an append-only store seeded from this project's real history with
every row attributed, a report generator, a fixed versioned task corpus, and a
written A/B protocol — pinned by `bash tests/speed_benchmark_tests.sh`.

**The deliverable is the instrument, not a flattering number.** The A/B against
raw Claude Code is specified and explicitly **not run**, because it cannot be run
from this harness: a Claude Code session is not launchable from a bash test, so
*both* arms are unautomatable here. Empty cells carry stated reasons; nothing is
fabricated to fill them.

## In scope

- `build-os/metrics/` (new directory: `record-packet.sh`, `report-speed.sh`,
  `packet_metrics.tsv`, `task_corpus.md`, `COMPARISON_PROTOCOL.md`, `README.md`)
- `tests/speed_benchmark_tests.sh` (one new suite)
- `tests/build_os_tests.sh` — the one `chain_suite` line that wires the new suite
- `build-os/memory/current_state.md`, `build-os/memory/residue.md` (check count
  and the instrument's standing limits)
- `CHANGELOG.md` → `[Unreleased]`
- `build-os/packets/active_packet.md`

## Out of scope (explicit)

- **Running the A/B.** Not possible from here; specified in
  `COMPARISON_PROTOCOL.md` for a human or a driver script to execute later. This
  is the P-B / pilot input.
- **Any telemetry, phone-home, or transmitting collector.** The store is local,
  in-repo and operator-owned, and a test greps the scripts to keep it that way.
- **Building the corpus tasks as executable fixtures.** The corpus is a frozen
  specification; turning `T1`–`T4` into runnable fixtures is a follow-on packet.
- **Automatic round/wall-clock capture.** Those cells are self-reported today.
  Instrumenting them automatically is a follow-on packet.
- **`/home/user/empathiq-website`** — untouched reference deployment at `cb2bb7d`.
- **Pushing, merging, tagging, `git config`.** Local commits only.

## Branch base

- `claude/project-handoff-merge-ramhds` at `68cae7a`; merge-base with
  `origin/claude/add-build-os` = `7ef50e8`. Verified before building.

## Plan (≤2 commits)

1. **Commit 1 (green in isolation):** `tests/speed_benchmark_tests.sh` written
   first (red: 29 passed / 99 failed, exit 1 — the instrument did not exist),
   then the instrument, the seeded store, the docs, the chain wiring, and the
   memory/changelog count move 488 → 616 that turns it green.
2. **Commit 2:** record this packet's own row in the store, measured from
   Commit 1, plus the residue note. The instrument's first real use is measuring
   the commit that introduced it.

---
_Set by the builder for `gravito_speed_benchmark_a`. The archivist clears this on close._
