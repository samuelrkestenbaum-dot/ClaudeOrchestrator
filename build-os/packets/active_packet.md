# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: NO PACKET IN FLIGHT

`gravito_p2_claim_scoped_evidence_a` is **CLOSED**.

- **Packet id:** `PACKET-0019-gravito-p2-claim-scoped-evidence-a`
- **Closed:** 2026-08-01
- **Receipt:** `build-os/receipts/gravito_p2_claim_scoped_evidence_a.md`
- **Commits:** `9474cae` (declaration alone) + `c653508` (tests + implementation),
  base `e6b825b` — re-verified at close, `git merge-base c653508 e6b825b` =
  `e6b825b`. **At the 2-commit cap**, so the close is a separate third commit.
- **Verdict:** **PASS** — reviewer **PASS** with no fix list and no fix round;
  qa **RED, resolved**. **Depth: 2 serial stages**, the `substantive` median, and
  the first packet in this sequence to hold it.
- **Delivered:** one control may now carry **many claims with many verdicts** —
  `evidence_assertions.txt`, `claim-evidence.sh`, `tests/claim_evidence_tests.sh`
  (77 assertions), and `untested` on the evidence axis at `observe`. Census
  **90 → 93**; suite **1689 → 1771**; findings numerator **unchanged at 25**;
  **zero re-authorisations**.
- **The finding that outlived the feature — F1:** a **live over-grant inside the
  over-grant detector**. A second `EVIDENCE_AXIS` copy left at five tokens made a
  `gate` grant read `WITHIN-LICENCE` against a correct cap of `observe` —
  over-reaching by three rungs. **Fixed, and the fix covers the CLASS rather than
  the pair** — the first such fix in this sequence.
- **Nothing was pushed, merged, tagged or deployed.** The branch is local-only
  past `6b01173`.

## Next up (staged, NOT declared — the orchestrator declares it)

**P3 — `accept_and_constrain`.** The third of the operator's five phases, and the
one the previous four packets have each pointed at:

- **Why it exists:** the operator's framework offers demote / correct class /
  improve evidence / retire, and **demotion onto the rung the `refuted` cap
  prescribes is unspellable for the large majority of the census**. `accept and
  constrain` — leave the authority, keep the finding standing, require an
  operator envelope — is the missing fifth outcome.
- **`authority_envelopes.txt` exists with 0 live grants**, which is exactly what
  it was built for.
- **The known hard constraint, carried from `gravito_authority_envelope_a`:** an
  envelope can **only lower** `L_effective`; **it cannot legitimise a grant**. So
  P3 **cannot** be done by writing envelopes against the 20 declared mismatches —
  every one of them exercises **more** authority than its class licenses. **P3
  needs a class change or a different instrument, and neither is designed yet.**
  This is the first thing P3 must settle, out loud, before it builds anything.
- **P3 MUST own expiry enforcement** — residue **(eee)**. `valid_until` is stored
  and enforced nowhere; it is inert today only because nothing consumes
  assertions and composition is `MIN`, and **P3 is the first consumer**. Folding
  in `authority_envelopes.txt`'s equally-unchecked `expires` at the same time is
  the cheap version.
- **P3 MUST keep recording rejected candidates with frozen signal snapshots.**
  The n = 1 warning is now discharged to **n = 2** (`DECISION-0007` and
  `DECISION-0008`); P4 trains on this and nothing else.

**Also available, and cheaper — two `tiny`-lane candidates that need no packet:**

1. **Residue (ccc)** — repoint `MISMATCHES.md:607/:608/:609` from
   `scan-controls.sh` `:454`/`:126`/`:129` to **`:471`/`:141`/`:144`**. Exact
   targets and their anchor content are in the residue entry. Already wrong at
   base, so this is not a regression — but `MISMATCHES.md:611` documents the
   *previous* generation of the same bug, making this **generation three**.
2. **Install Codex, or delete the second-eyes row** — residue **(fff)** / **(zz)**.
   **Seventh consecutive unbacked packet.** A one-line fix in either direction.

## THIS FILE'S SHAPE IS LOAD-BEARING — it must carry ≥3 `^## ` blocks

**Do not reduce this file to two headings.** `rotate-memory.mjs`'s `FILE_SPECS`
splits it on `blockDelimiter: /^## /`, and the maintenance layer's two-pass
rotation proof (`tests/scaffold_seeding_tests.sh`, the two-pass rotation section)
needs **≥3 blocks per rotating file**.

**This has already shipped red once.** The close of `gravito_mismatch_refuted_a`
left this file with exactly **2** blocks, so `./build-os/maintenance/run-tests.sh`
went **143/144** at `2df61ae` — **a commit that was pushed**. That suite is
**still not chained into the main suite** and nothing else catches it, so **every
close must run it AFTER its own writes.** This close did: **144/144**, and the
block count was **verified after writing**, not before.

The sharper hazard: a count of **0** means the delimiter does not match the file's
format at all and **nothing can ever rotate out of it**. That state is
byte-identical after `--apply`, exits **0**, and fails nothing — but it is **not
silent**: `rotate-memory.mjs` prints
`WARNING: <path>: the block delimiter /^## / matched NOTHING … NOTHING CAN EVER
ROTATE OUT OF IT` on stderr. **The failure mode is an ignorable warning, not
silence.**

The underlying control gap is still open: `bandwidth.active_packet_singleton`
refuses **two** declared packets but permits **zero**, so a packet that simply
omits its declaration passes clean. Residue **(c)** / **(u)**. Note that this
file currently sits in exactly that permitted-zero state **legitimately** — the
packet is closed and the next is not yet declared — which is precisely why the
control cannot tell the two situations apart.
