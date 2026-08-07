# EXP-0005 seed pin and memory pin

Closes readiness items **repository seed pinned** and **memory state pinned**.
They are one document because they are one starting condition: Gravito's durable
state lives in tracked files inside the seed commit, so a pin that fixed the
commit but not the memory — or the reverse — would be describing a tree that
cannot exist.

## The pin

| | |
|---|---|
| repository | `empathiq-website` |
| seed commit | `2543c873141fa64653a7993d326465d5e0dd1006` |
| commit subject | `chore: ignore tooling debris and runtime ledgers so the tree is clean for assessment` |
| commit date | 2026-08-06T21:51:41+00:00 |
| tree hash | `2f5e391f2bcc12c9264d4303a3f0ad709056e672` |
| branch containing it | `pilot/PILOT-0002-clean-window` |
| **durable-state digest** | `3311a638e5f6255c7a095ab6bc91592cc9236283b0ab4ff4fe62eea306f19bfb` |

The tree hash is pinned alongside the commit deliberately. A commit SHA fixes
history; the tree hash fixes *content*, and it is the tree the arms actually run
against.

## A pin is a script, not a number

`harness/restore-seed.sh` performs the restore and then proves the result equals
the registered state, exiting non-zero when it does not. Prose describing a
starting state is a note; a check that refuses is a pin.

    harness/restore-seed.sh <dest>                 # restore + verify an arm tree
    harness/restore-seed.sh --verify-only <dir>    # verify an existing tree

It asserts four things and refuses on any one: HEAD equals the seed, the tree
hash equals the registered tree, the durable-state digest equals the registered
digest, and the working tree is clean. It then asserts the live ledgers are
**absent**, which is the only check that runs in the negative direction.

## Digest method — defined here because it was not defined before

    manifest = for each class, in this fixed order:
                 "<class>\t<file count>\t<sha256 of `git ls-files -s -- <class>`>\n"
    digest   = sha256(manifest)

Classes, in order: `build-os/memory`, `build-os/receipts`, `build-os/packets`,
`.gravito`.

`git ls-files -s` emits mode, blob SHA, stage and path — content **and**
location. Both matter: a moved receipt is a different inheritance from an
unmoved one.

The manifest is built from the per-class digests on purpose, so that
`INVENTORY.md`'s own table is an **auditable input** to the constant rather than
a second, parallel claim about the same tree.

## Supersession — INVENTORY.md's headline digest is not the pin

`INVENTORY.md` records a headline digest of
`7de42dd1c5a779a257645a0deecea2d8292b8501f84832e8c21cf65542e76ae6`. It was
computed ad hoc and **the combination step was never recorded**. Sixteen
candidate methods were tried against the unchanged tree — single and multi-class
`ls-files`, sorted and unsorted, `ls-tree`, concatenated per-class digests in
several encodings, alternative class orders, with and without `.gravito`, with
and without the HEAD sha — and **none reproduced it**.

**The underlying state is not in question.** All four per-class digests and all
four file counts in `INVENTORY.md` reproduce EXACTLY at this seed:

| class | files | digest (16) | reproduces |
|---|---:|---|---|
| `build-os/memory` | 6 | `14ae466f83f74678` | yes |
| `build-os/receipts` | 132 | `73075caf84923219` | yes |
| `build-os/packets` | 3 | `21eb1c55a3cd58f4` | yes |
| `.gravito` | 0 | `e3b0c44298fc1c14` | yes |

So this is a **recording defect in the combination step, not drift in the
state**. A constant nobody can recompute cannot verify anything, so it cannot be
the pin.

The old value is **superseded, not overwritten**: it remains in `INVENTORY.md`
exactly as recorded, and this section is why it was replaced. Deleting it would
have hidden that the first attempt at pinning produced an unusable constant.

## The differential — this pin was shown to bite

A check that passes on the tree it was written against proves nothing. Three
differentials, all run:

| test | result |
|---|---|
| verify with a deliberately wrong expected digest | **REFUSED** |
| drop one of 132 receipts from the digest input | digest changes `73075caf…` → `ca6ec565…` |
| rename one path, same blobs, same count | digest changes `14ae466f…` → `4e69e272…` |

Content-sensitive and location-sensitive, both demonstrated rather than
asserted.

## The live-ledger exemption, and why it is a flag

`--allow-live-ledgers` skips **only** the exclusion check, and exists for
exactly one case: verifying the **source** repository, which legitimately
carries the working machine's own `.gravito/` and routing ledgers. Those are
untracked per-session state, so they are excluded from the snapshot *and* from
the restore — no arm inherits another arm's routing state.

It is a flag rather than a silent skip so that using it on an arm tree is a
visible act in the command line, and the script prints that the tree is
therefore **not verified**.

## What this pin does NOT establish

- It does not establish that the seed is a *good* starting point, only that
  every arm starts from the same one.
- It does not cover untracked state by design; untracked state is destroyed by
  `git clean -fdx` at restore, which is the intent, not a gap.
- It says nothing about which tasks are admissible. Task selection is a separate
  frozen rule (`tasks/SELECTION-RULE.md`) and a separate readiness item.
