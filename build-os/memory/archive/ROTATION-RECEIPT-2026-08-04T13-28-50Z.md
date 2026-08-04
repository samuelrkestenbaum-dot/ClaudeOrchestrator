# ROTATION RECEIPT — batch `2026-08-04T13:28:50Z`

**THE THIRD GOVERNED ROTATION OF THIS REPOSITORY'S MEMORY, AND THE FIRST ONE
PERFORMED BY A CROSS-FILE RESOLVER.** Rotation #1 was safe because a human read
the open-item markers. Rotation #2 was the first the rotation sentinel governed,
single-file scoped. This one ran under the sentinel with identity resolved across
the **governed memory set**, and the difference is recorded here because it
changed a verdict on another file (see "What the resolver changed", below).

**THIS FILE IS IMMUTABLE.** It records one batch, at one commit, with figures
that were true of that batch. Nothing here is to be updated later: a correction
creates a later record, it does not edit an earlier one.

## What was rotated

| | |
|---|---|
| batch id | `2026-08-04T13:28:50Z` |
| packet | `gravito_cross_file_sentinel_identity_a` |
| file | `build-os/memory/current_state.md` |
| tool | `node build-os/maintenance/rotate-memory.mjs --file current_state --keep 15 --apply --pre-registration build-os/memory/archive/PRE-REGISTRATION-rotation-3.json` |
| exit | 0 |
| archive | `build-os/memory/archive/current_state.archive.md` (second batch appended to it) |
| index rows added | 3, in `build-os/memory/archive/INDEX.md` under `## Batch 2026-08-04T13:28:50Z` |

## The sentinel's report, verbatim, for the rotation that was permitted

```
  blocks            : 18 total -> keep 15 newest, would archive 3
  would archive     : block_16..block_18 (28784 B)
  archive pointer   : 511 B banner
  live size         : 201859 B -> 173075 B (ceiling 204800 B) OK
  prior banner      : 511 B REPLACED in place
  sentinel          : ALLOW — requested_keep 15, minimum_safe_keep 5
  protected objects : 5 at block(s) 1, 3, 5
  projection        : blocks_to_archive 3, bytes_to_reclaim 28784,
                      post_rotation_headroom 31725 B (close budget 18702 B)
  identity set      : residue.md (126 decl), current_state.md (0 decl),
                      active_packet.md (9 decl)
  WITHHELD FROM THE RESOLVER: build-os/memory/standing_gates.md
```

## Capacity, before and after

| | before | after |
|---|---|---|
| `current_state.md` | 201859 B, **2941 B** of headroom | 173075 B, **31725 B** of headroom |
| `residue.md` | 204369 B, **431 B** of headroom | 204369 B, **431 B** — UNCHANGED, and provably so |
| `active_packet.md` | 126695 B, 78105 B | 126695 B, 78105 B — not rotated, needs no relief |

**28784 B reclaimed.** The close budget refusal condition 7 enforces is 18702 B;
the result leaves **13023 B over it**.

## `--keep 15` — the window, EXECUTED AT BOTH BOUNDS

The keep was chosen inside a window three independent bounds leave, and every
bound was measured against the exact bytes this batch rotated rather than quoted
from rotation #2's receipt:

- **floor from the sentinel:** `minimum_safe_keep` **5**.
- **floor from `tests/build_os_maintenance_tests.sh` §9(a)/(b)/(c):** the rotated
  file must keep MORE than 10 blocks and a subsequent `--keep 10` must still
  reclaim >= 40960 B and leave >= 40960 B of headroom. Measured by applying into
  a scratch root: **keep 13 reclaims 37592 B and FAILS**; keep 14 reclaims
  53228 B and passes. So `keep >= 14`.
- **ceiling from refusal condition 7:** the projected headroom must cover the
  18702 B close budget. Measured: **keep 17 leaves 12195 B and REFUSES at
  `SENTINEL-C7`**; keep 16 leaves 21221 B and is allowed. So `keep <= 16`.

Window `[14, 16]`; **15 taken**, the middle, as rotation #2 took the middle of
its own. It leaves 13023 B of margin over the close budget and a subsequent
`--keep 10` reclaim of 61603 B, which is 20643 B over the §9 floor.

## The pre-registration, and why the ordering is checkable from the tree

`build-os/memory/archive/PRE-REGISTRATION-rotation-3.json` was written and
committed in **commit 1** (`905b69e`); the apply is in **commit 2**. The record
binds `{ file: current_state, keep: 15, sourceSha256:
59ab80776e319fe01d374108079a50ad00e300d0dbc872393dba70e0c7cccd11 }` — the exact
201859 bytes it was taken over — so it could not have authorised a rotation of
any other bytes, and `git log` is what proves it preceded the apply.

## Restoration, proved rather than asserted

Reconstructed from the two outputs ON DISK, after the write:

```
live (173075 B) - new banner (511 B) + prior banner (511 B) + archived body (28784 B)
  = 201859 B, md5 9f312f93cd1eca4b057703f94262395f  == the source's md5
```

The archive is append-only and was verified so: the 66894 B file starts with the
38109 B it held before, byte for byte. The only bytes reproduced by neither
output are the **511 B prior banner**, replaced in its own anchored slot, and the
tool's report says so on its own line rather than claiming byte-exactness.

## Archive composability — BOTH batches, BOTH files

| archive | blob | batches | each batch's declared block count vs re-segmented |
|---|---|---|---|
| `residue.archive.md` | `f475d53e` — **unchanged by this batch** | 1 | `2026-08-03T16:09:49Z`: declares 4, re-segments to 4 |
| `current_state.archive.md` | now 2 batches | 2 | `2026-08-03T19:53:21Z`: 5 / 5 · `2026-08-04T13:28:50Z`: 3 / 3 |

## The protected region was never reachable

`current_state.md`'s block 1 is **29536 B and byte-identical** across the
rotation. Both gate-pinned literals (`**Build/test command:**`,
`**Last closed packet:**`) are still in the live file and **neither appears
anywhere in the archive** — checked in both directions, not just the live one.

## WHAT THE RESOLVER CHANGED, AND WHAT IT HONESTLY DID NOT

Measured on the live tree at `905b69e`, with `--sentinel-report`:

- **`active_packet.md`: REFUSE → ALLOW.** It carried 4 unresolvable identities
  (`(S1)` twice, `(o)` twice) and refused at `SENTINEL-C1` + `C2` + `C3`. It now
  carries **zero**, with 6 cross-file resolutions into `residue.md` blocks 16 and
  25 and 6 quoted references demoted, and it is ALLOW at `--keep 32`. It was not
  rotated here: it has 78105 B of headroom and needs no relief.
- **`current_state.md`: unchanged.** Floor 5 before and after; no unresolvable
  identity either way. The resolver did not move this file's protection.
- **`residue.md`: STILL NOT ROTATABLE, and this is the honest result rather
  than a failure.** Its `minimum_safe_keep` is **25 of 25 blocks**, because `(o)`
  and `(S1)` are DECLARED in block 25 **of that file** and are genuinely live.
  `SENTINEL-C2` was never the binding constraint on its rotatability: with C2
  fully cleared, `--keep 25` still archives nothing and `SENTINEL-C7` refuses,
  while every keep below 25 trips `SENTINEL-C1`. The tool's own C7 text names
  the dead end — "ROTATION CANNOT RELIEVE THIS FILE AT ALL". The two things that
  would move it are both operator acts: close `(o)`/`(S1)`, or move the
  still-open items to the head of the file so the tail becomes archivable.
  `residue.md` still holds **431 B** of headroom and was not written by this
  packet.
- **`DEFECT-0014` is still `SENTINEL-C2`-unresolvable in `residue.md`, and the
  reason is now precise instead of ambient.** It is not declared in ANY governed
  memory file; its record is `defect_class: DEFECT-0014-...` in
  `build-os/registry/defect_classes.txt`, which is outside the governed identity
  set on purpose. Admitting a registry file to that set widens what "resolve"
  means again — a further spec revision, and an operator decision. It is recorded
  here and not taken.
