# ROTATION RECEIPT — batch `2026-08-03T19:53:21Z`

**THE SECOND GOVERNED ROTATION OF THIS REPOSITORY'S MEMORY, AND THE FIRST ONE A
TOOL GOVERNED RATHER THAN A HUMAN.** Rotation #1 (batch `2026-08-03T16:09:49Z`)
was safe because a person read the open-item markers, found the oldest and
derived `--keep 25` by hand. This one was refused-or-permitted by
`build-os/maintenance/rotate-memory.mjs`'s rotation sentinel, which derived the
floor itself.

**THIS FILE IS IMMUTABLE.** It records one batch, at one commit, with figures
that were true of that batch. Nothing here is to be updated later: a correction
creates a later record, it does not edit an earlier one.

## What was rotated

| | |
|---|---|
| batch id | `2026-08-03T19:53:21Z` |
| packet | `PACKET-0040-rotation-sentinel-guard` (`gravito_rotation_sentinel_guard_a`) |
| file | `build-os/memory/current_state.md` |
| tool | `node build-os/maintenance/rotate-memory.mjs --file current_state --keep 15 --apply --pre-registration build-os/memory/archive/PRE-REGISTRATION-rotation-2.json` |
| exit | 0 |
| archive | `build-os/memory/archive/current_state.archive.md` (created by this batch) |
| index rows added | 5, in `build-os/memory/archive/INDEX.md` under `## Batch 2026-08-03T19:53:21Z` |

## The sentinel's report, verbatim, for the rotation that was permitted

```
requested_keep            15
minimum_safe_keep         3
protected_object_ids      GATE-PIN:**Build/test command:**, GATE-PIN:**Last closed packet:**,
                          PROTECTED-REGION:block_1, BLOCK:3
protected_block_positions 1, 3
blocks_to_archive         5
bytes_to_reclaim          37548
post_rotation_headroom    38195
verdict                   ALLOW   (close budget 18702 B)
```

**`requested_keep` IS 15 AND THE FLOOR IS 3, SO THE SENTINEL WAS NOT THE BINDING
CONSTRAINT HERE — AND SAYING SO IS THE POINT.** The keep was chosen inside a
window three independent bounds leave, all of them pre-registered before the run:

- **floor from the sentinel:** 3.
- **floor from `tests/build_os_maintenance_tests.sh` §9(a)/(b)/(c):** the
  post-rotation file must keep more than 10 blocks and a subsequent `--keep 10`
  must still reclaim >= 40960 B — which needs `keep >= 14`.
- **ceiling from refusal condition 7:** the projected headroom must cover the
  18702 B close budget — which needs `keep <= 17`.

Window `[14, 17]`; **15 taken**, leaving 11835 B of margin over the §9 floor and
19493 B over the close budget. 14 would have reclaimed 9253 B more and left only
2582 B of §9 margin — too thin to survive the next close's block insertion.

## The pre-registration, and why it is the thing rotation #1 lacked

Rotation #1's receipt postdated its apply, so the ordering was builder
attestation and nothing else. This batch's intent is
`build-os/memory/archive/PRE-REGISTRATION-rotation-2.json`, committed in
**commit 1** of this packet; the apply is in **commit 2**. The ordering is
therefore readable from the tree:

```
git log --format='%h %s' -- build-os/memory/archive/PRE-REGISTRATION-rotation-2.json
git log --format='%h %s' -- build-os/memory/archive/current_state.archive.md
```

The record binds the run on **file, keep and the sha256 of the source as it
stood when the registration was written** — `91fa454856bb7612b78ee1da843aa6e72e20851d6bef525ba046adb9f6a02cee`.
A registration taken over different bytes is refused, which is what makes it an
ordering anchor rather than a rubber stamp.

## Byte accounting — derived, never quoted from a brief

```
source                203642 B   sha256 91fa454856bb7612b78ee1da843aa6e72e20851d6bef525ba046adb9f6a02cee
live after            166605 B   = 166094 B retained content + 511 B archive-pointer banner
archived               37548 B   blocks 16..20
reclaimed on disk      37037 B   = 37548 archived - 511 banner
headroom after         38195 B   under the 204800 B ceiling (DEFAULT_MAX_BYTES, NOT raised)
blocks                 20 -> 15
```

**CONSERVATION, PROVED FROM THE BYTES ON DISK AND NOT FROM THESE NUMBERS.**
`live-minus-banner ++ archived-body` reproduces the 203642 B source byte-exact;
both sides hash to `91fa4548...`. `priorBannerBytes` was 0 — this file had never
been rotated, so no generated banner was replaced and the byte-exact claim holds
without qualification.

## Rotation #1's payload is untouched, and both batches round-trip

- `build-os/memory/archive/residue.archive.md` is at blob
  `f475d53e9a7b282437bc2bb4729de1274d9d7708` — **the same blob as before this
  batch**, and `git diff HEAD` over that path is empty.
- **HOW THE TWO BATCHES COMPOSE:** they do not overlap at all. Each source file
  gets its OWN archive file (`<name>.archive.md`), so batch 2 created
  `current_state.archive.md` and never opened `residue.archive.md`. The one file
  both batches write is `INDEX.md`, and every write there goes through
  `writeVerified`'s append-only precondition — the existing bytes must survive as
  a prefix or the write is refused. Batch 1's 15 rows are still rows 1..15 under
  `## Batch 2026-08-03T16:09:49Z`; batch 2 added a new `## Batch` section with 5.
- **BATCH 1 STILL ROUND-TRIPS:** its 26763 B archived payload is recoverable
  byte-exact from `residue.md` as it stood at base `3ec519b`, whose sha256 is
  `1977817fef768becfa8d7e89d333261ac619ad43eebcd03c246ef200fce1c8ca` — the same
  figure rotation #1's receipt recorded.
- **BATCH 2 ROUND-TRIPS**, as shown above.

## Protected objects verified live AFTER the rotation, BY IDENTITY

Not by "the file still contains the string somewhere" — by locating each object
and confirming which block now holds it, and confirming the archive holds none
of them.

| object | block after | in archive |
|---|---|---|
| `PROTECTED-REGION:block_1` (`## Standing truth — PROTECTED REGION`) | 1 | 0 occurrences |
| `GATE-PIN:**Build/test command:**` (2 occurrences) | both in block 1 | 0 |
| `GATE-PIN:**Last closed packet:**` (2 occurrences) | both in block 1 | 0 |
| `BLOCK:3` (`## Active decisions, open rulings, and the standing backlog`, anchoring the `STILL OPEN` marker) | 3 | 0 |

Re-run over the ROTATED file the sentinel derives the same floor — 3, of 15
blocks, verdict ALLOW — so the file is still governed and still rotatable.

## What was archived

Blocks 16..20, the five oldest history sections:

```
## History — `gravito_mismatch_refuted_a`
## History — `gravito_authority_envelope_a`
## History — `gravito_evidence_policy_matrix_a`
## History — `gravito_census_gaps_egress_bandwidth_a` through `gravito_productization_pa_maintenance_upstream_a`
## History — the earliest sessions, P-022 back to P-015
```

## THE FILE THAT WAS NOT ROTATED, AND THE GUARD IS THE REASON

`build-os/memory/residue.md` was **431 B** from the ceiling and is still 431 B
from it. The sentinel derives `minimum_safe_keep = 25` against a file carrying
exactly **25** blocks, so **no legal keep reclaims a single byte from it**:

- **block 25** holds `(o)`, the flake marked `[STILL OPEN AND STILL
  UNDIAGNOSABLE]`, and `(S1)`, an unresolved operator decision;
- **block 16** holds `(ddd)`, marked *"IS NOT CONSUMED AND MUST NOT BE MARKED
  SO"*;
- and `DEFECT-0014` is named as `STAYS OPEN` at `residue.md` line 310 while no
  block in that file DECLARES it — an **unresolvable identity**, which is a
  refusal and not a skip.

`--keep 10 --apply` over that file — the command that sat QUEUED in the file's
own `(bbbbbb)` as a pending action — now exits **7** and writes nothing.

**THIS WAS NOT WORKED AROUND AND THE GUARD WAS NOT WEAKENED TO MAKE A ROTATION
FIT.** The two things that would move that file are both operator acts: close
`(o)`/`(S1)`, or move the still-open items to the head so the tail becomes
archivable. Until one of them happens, **residue.md cannot absorb another
close** and whatever would have gone there must go somewhere else.
