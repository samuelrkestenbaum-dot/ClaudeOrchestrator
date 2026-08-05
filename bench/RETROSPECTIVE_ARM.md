# The pre-integration retrospective arm — frozen 2026-08-05

**This is free evidence that needed no new run.** `build-os/metrics/packet_metrics.tsv`
already held **27 rows** describing real packets built in this repository before
Repository Core was integrated and before a second provider was authenticated.
That is the honest pre-integration picture, and it is frozen here because the
state it describes is about to stop existing.

**No existing row was modified to produce this summary.** It is a read of the
store as it stood at commit `c7433c5`, plus one row appended afterwards for this
packet's own `T1` run (`t1_run1_buildos_preintegration`), which is **excluded
from every figure below** — the retrospective arm is the 27 pre-existing rows and
nothing else.

- **Window:** 2026-07-30 to 2026-08-04 (six days).
- **Store:** `build-os/metrics/packet_metrics.tsv`, 27 data rows.
- **Verification:** `record-packet.sh --validate` reports 28 rows, 0 invalid
  (27 retrospective + this packet's `T1` row).

## What the 27 rows actually contain

| measure | rows with data | median | range |
|---|---|---|---|
| `rounds` | 22 / 27 | **4** | 1 – 11 |
| `wall_min` | **1 / 27** | 13.7 | 13.7 – 13.7 |
| `serial_min` | **1 / 27** | 37.9 | 37.9 – 37.9 |
| `agents` | 21 / 27 | **5** | 1 – 6 |
| `files` | 26 / 27 | **11.5** | 1 – 32 |
| `insertions` | 26 / 27 | **1349.5** | 115 – 9817 |
| `deletions` | 26 / 27 | **114.5** | 0 – 2143 |
| `tests_added` | 26 / 27 | **45** | 0 – 207 |
| `defects_gated` | 25 / 27 | **7** | 0 – 17 |
| `defects_escaped` | **0 / 27** | — | **never measured** |

Lane distribution: `substantive` 25, `tiny` 1, `agent-swarm` 1.
Evidence class: `mixed` 26, `transcript` 1. Commits named in 26 / 27 rows.

## The finding that matters most, stated first

**Wall-clock is present in exactly ONE of 27 rows.**

`COMPARISON_PROTOCOL.md` denominates *every* cross-arm claim in wall-clock
minutes — it is, in that document's own words, "the one unit both arms genuinely
have". This arm has that unit for **1 packet in 27**.

The consequence is unavoidable and should not be softened: **the retrospective
arm cannot be compared to any future arm on the protocol's own primary endpoint.**
It is rich in output-size data (`files`, `insertions`, `tests_added` are present
in 26 / 27) and almost empty of the single measure the experiment is denominated
in. A post-integration comparison against these 27 rows can honestly compare
output size and round counts; it **cannot** produce a speed claim, because there
is no before-figure to compare a speed to.

That is not a defect in this summary. It is the pre-integration state, recorded
accurately, and it is exactly the sort of thing that becomes invisible once the
state is gone.

## `defects_escaped` is empty in all 27 rows, and that is correct

Not one row asserts zero escaped defects. The recorder's own rule is the reason —
"0 is a measurement and `-` is an admission" — and escaped defects were never
tracked, because escaped defects are counted only for as long as somebody keeps
looking, and nobody was looking after these packets closed.

**Do not let this column be read as a quality result.** A future summary that
fills it with zeros would manufacture a perfect-quality baseline out of an
absence of observation, and would make any later regression look like a new
problem rather than a newly-noticed one.

## Round budgets were exceeded routinely

Six of the 22 rows carrying a round count are above the corpus's `substantive`
cap of 6:

| packet | lane | rounds |
|---|---|---|
| `reference_memory_rotation_utility` | substantive | **11** |
| `gravito_evidence_policy_matrix_a` | substantive | 8 |
| `gravito_census_gaps_egress_bandwidth_a` | substantive | 7 |
| `gravito_authority_envelope_a` | substantive | 7 |
| `gravito_mismatch_refuted_a` | substantive | 7 |
| `gravito_ladder_semantics_a` | substantive | 7 |

And the single `tiny` row, `gravito_test_harness_stdin_hang_a`, consumed **6
rounds against a 2-round budget** for a one-token stdin fix. `task_corpus.md`
already names that packet as this repository's worst measured result and keeps
`T1` in the corpus specifically because it is the shape the system loses on. The
retrospective arm confirms it was not an isolated event: **the median packet took
4 rounds, and roughly a quarter of the measured ones blew their cap.**

## The one fan-out, and why its speedup figure is weak

`gravito_fanout_lanes_scaffold_release_a` is the only `agent-swarm` row and the
only row with both wall-clock figures: **13.7 min parallel against 37.9 min
serial**, 3 rounds, `agent-swarm` lane.

`task_corpus.md` already flags this row's weakness and it is repeated here rather
than quietly inherited: the serial figure came **from a session transcript, not
from a serial re-run**, and the per-packet detail was destroyed by merging three
packets into one commit. **A 2.8x figure derived from an unmeasured
counterfactual is not a measurement**, and it should not be quoted as one. It is
the only speed number in the entire pre-integration store, and it is the weakest
kind.

## What this arm is, and what it is not

- It **is** a genuine record of 27 real packets, with commits named in 26 of them,
  built under Build OS before Repository Core.
- It is **not** an arm of the pre-registered A/B. There is no control arm here at
  all: every one of the 27 packets was built with Build OS on. Nothing in this
  file supports a statement of the form "Build OS was faster than not using it".
- It is **not** a random sample of engineering work. It is what this repository
  happened to build in six days, which is heavily weighted toward governance and
  measurement infrastructure.
