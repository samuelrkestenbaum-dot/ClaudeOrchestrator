# Gravito durable-state inventory — taken BEFORE any candidate task was examined

Ordering is load-bearing. If the inventory were taken *after* reading candidate
tasks, selection would be informed by what was found in memory, and the leakage
check would be validating against knowledge it had itself shaped. Inventory
first, candidates second, leakage check against a fixed inventory third.

## Repository state at inventory time

| | |
|---|---|
| repository | `empathiq-website` |
| HEAD | `2543c873141fa64653a7993d326465d5e0dd1006` |
| working tree | clean (0 modified paths) |
| **tracked-state digest** | `7de42dd1c5a779a257645a0deecea2d8292b8501f84832e8c21cf65542e76ae6` |

The digest is over `git ls-files -s` for every durable class below — content
hashes plus paths, so any change to any file changes the digest.

## Included state classes

| class | files | digest (16) | what it carries |
|---|---:|---|---|
| `build-os/memory` | 6 | `14ae466f83f74678` | `current_state.md` (853 KB), `residue.md` (792 KB), routers, contracts |
| `build-os/receipts` | 132 | `73075caf84923219` | **completed work, by name** — the highest-risk class |
| `build-os/packets` | 3 | `21eb1c55a3cd58f4` | packet definitions |
| `.gravito` | 0 tracked | `e3b0c442…` (empty) | untracked only |

**132 receipts is the number that matters.** Each records work already completed
in this repository, with its approach. That is exactly the state EXP-0005 is
meant to give the Gravito arm — *and* exactly where a candidate task's solution
could already be sitting.

## Excluded state classes — untracked, will NOT survive a clean reset

- `.gravito/`
- `build-os/packets/routing/live_gate_log.tsv`
- `build-os/packets/routing/live_state/`

These are per-session live ledgers, not durable knowledge. They are excluded
from the snapshot **and** from the restore, so no arm inherits another arm's
routing state. Recorded here so their absence is a decision rather than an
oversight.

## The boundary this inventory exists to police

> **General repository knowledge is TREATMENT. Specific prior-solution knowledge
> is CONTAMINATION.**

Gravito is supposed to know this codebase — a system stripped of that is not the
system anyone would ship, and testing it would answer a question nobody asked.
But if a candidate task's patch is already recorded in a receipt, that task
measures **recall, not capability**.

**When the two collide, the TASK is excluded — the memory is never purged.**
Purging legitimate repository memory to make Gravito look fresh would quietly
replace the system under test with a different one, and would do so in the
direction that makes the benchmark easier to pass.

## What was deliberately NOT done here

Receipt **titles** were read to establish what classes of work exist. Receipt
**bodies** were not, and no candidate task has been examined. Reading solutions
before choosing tasks is the contamination this ordering prevents.

## Restore contract for the run

Every Gravito unit starts from this exact snapshot. Per the registered primary
design, task N's outcome does **not** become memory available to task N+1 —
sequential compounding is a separate hypothesis with its own experiment. Normal
per-run temporary state may exist during execution; the frozen snapshot is
restored before each new Gravito unit, and restoration is verified by digest
rather than assumed.
