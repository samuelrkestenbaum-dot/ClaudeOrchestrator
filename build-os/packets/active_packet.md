# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: NO PACKET IN FLIGHT

`gravito_ladder_semantics_a` **closed 2026-08-01** — receipt at
`build-os/receipts/gravito_ladder_semantics_a.md`, commits `576751a` + `d0eff10`,
base `2df61ae`, plus this close commit. Verdict **pass as fixed** (qa GREEN with 5
non-functional findings; reviewer `fix-then-pass` twice). All fix rounds landed and
were re-verified.

**What it did:** corrected the authority ladder on the operator's ruling. `observe`
is redefined by **consequence** — *"may be recorded and consumed for visibility;
causes no operational consequence"* — instead of by non-consumption, and **`execute`**
is added as a sixth rung above `gate`. The ladder is now
`none < observe < advise < rank < gate < execute`.

**What it changed about any control's licence: NOTHING.** `evidence-policy.sh check`
is **19 of 81, split 6/5/8 — UNMOVED**. Zero governance-field diff lines. No class
licenses `execute`; **0 of 25 grid cells reach it**. The packet changed what `observe`
*means*, not what anything is licensed to do — which is exactly the predicted result,
because the previous packet had proved `refuted → observe` was an **unreachable
remedy** (foreclosed for 67 of 81, 0 sitting there) purely for definitional reasons.

## THIS FILE'S SHAPE IS LOAD-BEARING — it must carry ≥3 `^## ` blocks

**Do not clear this file to two headings.** `rotate-memory.mjs`'s `FILE_SPECS` splits
it on `blockDelimiter: /^## /`, and the maintenance layer's two-pass rotation proof
(`tests/scaffold_seeding_tests.sh:242`) needs **≥3 blocks per rotating file**.

**This is not theoretical. It has already shipped red once.** The close of
`gravito_mismatch_refuted_a` left this file with exactly **2** blocks, so
`./build-os/maintenance/run-tests.sh` went **143/144** at `2df61ae` — **a commit that
was pushed.** That suite is **not chained into the 1636** and the orchestrator's close
brief did not ask for it, so nothing caught it. `576751a` repaired it (2 blocks → 10).

**The sharper hazard, with its wording corrected.** A count of **0** means the
delimiter does not match the file's format at all and **nothing can ever rotate out of
it**. That state is byte-identical after `--apply`, exit **0**, and **nothing fails** —
but it is **NOT silent**: `rotate-memory.mjs` prints
`WARNING: <path>: the block delimiter /^## / matched NOTHING … NOTHING CAN EVER ROTATE
OUT OF IT` on stderr. **The failure mode is an IGNORABLE WARNING, not silence.**

The underlying control gap is still open: `bandwidth.active_packet_singleton` refuses
**two** declared packets but permits **zero**, so a packet that simply omits its
declaration passes clean. Residue **(c)** / **(u)**.

## Next packet — staged, NOT declared

**The reviewer ruled the next packet should be the MUTATION CENSUS coverage gap**
(`build-os/registry/MISMATCHES.md` §15). Five modules durably mutate and **not one of
those write actions is a registered control at any authority** —
`rotate-memory.mjs` (renames onto the live memory file — the most consequential write
in the system), `swarm-merge.sh`, `record-packet.sh`, `.claude/hooks/build-os-identity.sh`,
`specialist-handoff.sh`. The sharp case is **not** at `gate`:
`maint.managed_set_replacement` sits at **`advise`** while its declared output is
*"files copied into an installed repo, replacing prior managed copies"*, its failure
behaviour is *"none that stops anything"* and its rollback is *"none; a managed file's
local edits are lost on install"*.

**Registering those actions is a RE-AUTHORISATION and therefore the operator's act.**
Nothing here declares it. See `build-os/memory/current_state.md` → *Next (candidates)*
for the full ordered list, including the citation guard's **resolvability-vs-identity**
fix (anchor token or content hash, not a line number) and the ladder-**spelling** sweep
deferred to §16.

## Declaring the next packet

Write the declaration **into this file, as its own commit, BEFORE the builder's first
edit to any other file.** `gravito_ladder_semantics_a` proved that works: Commit 1 was
the declaration **alone** — trivially green in isolation, keeps the ≤2-commit cap, and
**lets git attest the ordering** without a third commit and without a pre-commit hook.
Nothing requires the docs to be the second commit.
