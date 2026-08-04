# CORRECTION 1 TO ROTATION RECEIPT — batch `2026-08-04T13:28:50Z`

**A CORRECTION CREATES A LATER RECORD; IT DOES NOT EDIT AN EARLIER ONE.**
`ROTATION-RECEIPT-2026-08-04T13-28-50Z.md` is immutable and its body is left
exactly as written. This file is the later record.

| | |
|---|---|
| corrects | `build-os/memory/archive/ROTATION-RECEIPT-2026-08-04T13-28-50Z.md`, the "Restoration, proved rather than asserted" section |
| raised by | qa and the reviewer, independently, in the fix round of `gravito_cross_file_sentinel_identity_a` |
| severity | a wrong figure inside an artefact presented as proof. The PROPERTY it was offered as evidence for is TRUE; the number was not. |

## What the receipt says, and what is true

The receipt says:

> The archive is append-only and was verified so: the 66894 B file starts with
> the 38109 B it held before, byte for byte.

**The prior size was 37,829 B, not 38,109 B.** The `current_state.archive.md`
blob is `34e4f12b` at both `74575ee` (the packet's base) and `905b69e` (the
commit immediately before the apply), and `git cat-file -s` reports **37829**
for it at both.

**38,109 = 37,829 + 280**, and the 280 B is the `<!-- rotation-batch: … -->`
marker plus the `## ARCHIVED BATCH …` heading **that this rotation itself
wrote**. The figure therefore counted part of the new batch as though it had
been there beforehand. It was arrived at by measuring from the wrong side of the
boundary, not by arithmetic on the right one.

## The property itself is unaffected, and is re-verified here over the right bytes

`cmp` over the correct prefix, executed:

```
git show 905b69e:build-os/memory/archive/current_state.archive.md   -> 37829 B
head -c 37829 build-os/memory/archive/current_state.archive.md      -> 37829 B
cmp <prior> <prefix>                                                -> identical, zero gap
```

The 66,894 B file **does** begin with the exact 37,829 bytes it held before, byte
for byte. Append-only holds. Nothing about the rotation, the restoration proof,
the reclaimed byte count, or the archive's composability changes: the source is
still reproduced byte-for-byte at md5 `9f312f93cd1eca4b057703f94262395f`, and
both archives still round-trip.

## Why this is recorded rather than quietly repaired

The receipt is the artefact a future session reads instead of re-deriving the
rotation. A wrong number inside a document whose whole purpose is to be trusted
is worse than the same number in prose, because nothing downstream will question
it. This tree's own rule is that a correction is a later record; the rule exists
so that the fact a figure WAS wrong stays discoverable, and it is applied to
this receipt exactly as it would be to any other.
