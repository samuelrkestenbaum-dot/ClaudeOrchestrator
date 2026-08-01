# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: IN FLIGHT — `gravito_ladder_semantics_a`

- **Lane:** substantive (builder → qa → reviewer → archivist)
- **Branch:** `claude/project-handoff-merge-ramhds`
- **Base:** `2df61ae` (verified by `git merge-base`)
- **Commit budget:** ≤2, Commit-1 green in isolation
- **Declared:** before the builder's first edit to any other file

## Why this packet exists

`gravito_mismatch_refuted_a` proved the authority ladder is **definitionally
broken at the bottom**: `refuted → observe` is an **unreachable remedy**.
`README.md` §2 defines `none` as *"nothing consumes it"* **and** `observe` as
*"it measures and records. Nothing reads the result."* Both bottom rungs are
defined by **non-consumption**, so the ladder has **no rung meaning "it is read,
but it causes nothing"** — exactly the state a refuted-but-wired-in control must
occupy. `observe` is foreclosed for 67 of 81 controls and 0 sit there.

## The operator's ruling — the corrected ladder

| authority | corrected meaning |
|---|---|
| `none` | no runtime output or consumer |
| `observe` | output may be recorded and **consumed for visibility**; it causes **no operational consequence** |
| `advise` | output may influence a human or a higher-authority control |
| `rank` | output may order already-permitted alternatives |
| `gate` | output may allow or prohibit |
| `execute` | output may **directly cause mutation** |

Two changes: **`observe` is redefined by CONSEQUENCE rather than by
CONSUMPTION**, and **`execute` is added as a sixth rung above `gate`**.

## Scope — in

1. Redefine `observe` at **all six semantic sites**, by content:
   `README.md` (`none` row, `observe` row, §3b `shadow` row),
   `build-os/registry/authority_envelopes.txt` header,
   `build-os/tools/authority-envelope.sh` header,
   `build-os/tools/evidence-policy.sh` header.
2. Add `execute` as the sixth rung: every `LADDER` string and `rank_of()`-style
   mapping in `evidence-policy.sh`, `authority-envelope.sh`, `scan-controls.sh`
   and the suites.
3. Reassess `OBSERVE-LB` in `scan-controls.sh`: under the corrected `observe`,
   "load_bearing AND observe" is **no longer contradictory**. Decide and argue
   whether the guard dissolves, narrows, or merely moves off the gating path.
   It **must not** remain a `gate` that blocks the operator from applying a
   remedy the advisory axis recommends.
4. Decide and **state** whether `DEPLOYMENT_AXIS`'s `autonomous` maps to
   `execute` or stays at `gate`.
5. Tests first, at every changed site.
6. `CHANGELOG.md` (cite by release-block heading, never by line number).

## Scope — out (record, do not act)

- **Whether Class A should license `execute`** — a governance question. Record.
- **The mutation census**: which of the 81 controls actually perform a write and
  are registered at `gate` (`rotate-memory.mjs` writes; `swarm-merge.sh`
  merges). **Report as a finding. Re-authorise nothing.**
- Any change to a control's `class`, `runtime_authority`, `authority_mismatch`
  or `empirical_status`.

## Expected result — verify, do not force

Redefining `observe` changes **no cap value** (`refuted` still caps at
`observe`); it changes what `observe` **means**, making it a **legal
destination**. So `evidence-policy.sh check` should stay at **19 of 81, split
6/5/8**. **If the count moves, explain it control by control — do not adjust
anything to make it match.**

## Verification gates

- `bash tests/build_os_tests.sh` — report exact new total (was 1617 / 0)
- `./build-os/maintenance/run-tests.sh` — 144/144
- `bash build-os/registry/scan-controls.sh check` — exit 0
- `bash build-os/tools/evidence-policy.sh check` — count + split, with any delta
  from 19 / 6-5-8 explained
- `RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh`
- All six semantic sites agree **by content**
- Commit-1 green in isolation in a clean clone
- `git status --porcelain` empty

## Hard gates

Local commits only. **NO push, merge, tag, PR, deploy, secrets, `git config`.**
Do not touch `/home/user/empathiq-website`. Do not touch `build-os/memory/*`.
**Do not weaken, delete or exempt any guard to make the suite green** — if a
guard and a value conflict, the value is wrong until proven otherwise.

---

## On the declaration-ordering tension (residue item **ee**)

`gravito_authority_envelope_a` was built and closed while this file read **NO
PACKET IN FLIGHT**. `gravito_mismatch_refuted_a` declared itself first, but the
declaration **landed in the same commit as the build**, so git could not attest
the ordering; the reviewer noted the `≤2-commit` rule and "declare before
building" appeared to be in genuine tension, needing a third commit or a hook.

**This packet resolves that tension without a third commit and without a hook:**
it spends **Commit 1 on this declaration alone** — trivially green in isolation —
and lands the entire build in **Commit 2**. Nothing says the docs must be the
second commit. Ordering is now attested by git.

## This file's SHAPE is load-bearing — it must carry ≥3 `^## ` blocks

Found while declaring this packet, and it was **already red at base `2df61ae`**:
`./build-os/maintenance/run-tests.sh` was **143 passed / 1 failed**, not the
144/144 the packet brief expected.

`rotate-memory.mjs`'s `FILE_SPECS` splits this file on `blockDelimiter: /^## /`,
and the maintenance proof *"real content: all 8 reported byte counts recomputed
from disk, first rotation AND re-rotation"* needs a **two-pass** rotation, so
every rotating file must carry **≥3 blocks**. `current_state.md` and
`residue.md` carry 3. When `gravito_mismatch_refuted_a` closed, it left this
file with exactly **2** `## ` headings — so the suite went red on live content,
not on code.

Note the sharper hazard named in that assertion: **a count of 0 means the
delimiter does not match the file's format at all, and nothing can ever rotate
out of such a file.** A prose-only rewrite of this file could disarm its own
rotation.

**It would not do so *silently* — that word was wrong here and is corrected.**
Measured: a zero-block file is byte-identical after `--apply`, exit is **0**, and
**nothing fails** — but `rotate-memory.mjs` prints `WARNING: <path>: the block
delimiter /^## / matched NOTHING … NOTHING CAN EVER ROTATE OUT OF IT` to stderr.
That warning exists at base and `rotate-memory.mjs` was not touched. The failure
mode is **an ignorable warning**, not silence.

Fixed here by promoting this packet's own section headings from `###` to `##`,
which is a change to **this packet's file only** — no guard was weakened,
deleted or exempted, and `rotate-memory.mjs` was not touched.

The underlying control gap is still open:
`bandwidth.active_packet_singleton` refuses **two** declared packets but permits
**zero**, so a packet that simply omits its declaration passes clean. The floor —
*assert a declared packet EXISTS while a packet is in flight* — remains unbuilt
(`residue.md` items **c** / **u**).
