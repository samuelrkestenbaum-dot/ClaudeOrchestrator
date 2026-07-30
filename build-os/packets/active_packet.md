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
   memory/changelog count move 488 → 616 that turns it green. Re-verified in a
   fresh clone at `f9e09c9`: **616 passed / 0 failed**.
2. **Commit 2 (also green):** the follow-through the Commit-1 isolation run
   earned, plus the review round folded in. Running the suite in a
   **history-stripped** tree turned 7 assertions red for a reason that was not a
   defect, so §11 now names the missing precondition explicitly. Adds a
   **duplicate-`packet_id` guard** (a second row for the same packet would be
   double-counted by every total *and* the report's self-checks would still pass
   — the hardest wrong number to notice), the recording convention, and residue.

   **Fix round folded into this same commit** (reviewer: 6 items; qa: 1), keeping
   the ≤2-commit contract: the report's *finding* is hoisted above §1 so the
   caveat arrives before the two impressive numbers; §5's speedup carries its
   three qualifiers inline (no control arm, transcript-sourced, agent-execution
   only — a structural upper bound); the protocol's DNF rule is re-denominated in
   wall-clock minutes (a rounds-denominated rule could never fire on arm A) with
   rounds demoted to an arm-B-only diagnostic; two held-constants added (reasoning
   effort, fresh session), one pre-registered primary endpoint declared, a
   **16-run reduced-N plan** named as the one to actually run, and the operator's
   unblindable authorship named as a limit; the corpus stops claiming to span the
   lane ladder and records its blind spot; and `--verify-git` now **exits
   non-zero** on a fabricated commit instead of printing `UNVERIFIABLE` and
   exiting 0. Count move **488 → 616 → 657** (speed suite 128 → 169), matching
   `CHANGELOG.md` and `current_state.md`.

   **This packet deliberately records no row of its own.** The store is
   append-only and one-row-per-packet, so a row written before qa and review had
   run could never be corrected. The convention is now written down: the
   archivist appends the row at close, when every column is knowable at once.
   Writing a partial row would have been exactly the fabrication this packet
   exists to refuse.

---
_Set by the builder for `gravito_speed_benchmark_a`. The archivist clears this on close._
