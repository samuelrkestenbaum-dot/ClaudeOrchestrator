# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: NO PACKET IN FLIGHT

`gravito_p3_accept_and_constrain_a` was **CLOSED 2026-08-01**. Nothing is in
flight. The next packet is **staged, not started** — it needs an explicit go like
any other.

## Closed — `gravito_p3_accept_and_constrain_a`

- **Packet id:** `PACKET-0023-gravito-p3-accept-and-constrain-a`
- **Receipt:** `build-os/receipts/gravito_p3_accept_and_constrain_a.md`
- **Commits:** `3bd2ab4` (declaration) + `e68d931` (build) + `ead24bc` (fix
  round). Base `f3c5353`, re-verified at close.
- **Verdict:** **PASS-AS-FIXED** — qa GREEN, reviewer fix-then-pass **twice**.
- **Delivered:** a fifth mismatch disposition (`accept_and_constrain`) that
  **clears nothing and raises nothing**, plus **lease-window enforcement** —
  `LAPSED` / `NOT-YET-LIVE`, `valid_from`/`valid_until`, calendar-valid dates.
- **Census 93 → 97; suite 1771 → 1869; findings numerator and finding SET
  byte-identical to base at 25 (6/5/14); ZERO re-authorisations.**
- **Depth: 4 serial stages — a DEFECT under the contract**, recorded as one. It
  was a **mis-cut in mechanism**: P3 mechanised the *citation* half of
  `DEFECT-0003-duplicate-semantic-truth` and left the *counts-in-two-places*
  half to hand. **Stage 5 was not opened**; the remainder is re-cut below.
- **Note the id:** the close brief said `PACKET-0020-…`, which is **already
  taken** by `PACKET-0020-widen-control-registry-with-claim-fields`. The
  canonical id is `PACKET-0023-…`.

## Staged next — `gravito_p3b_count_derivation_a` (NOT STARTED)

**The re-cut the reviewer endorsed. It is the contract's own remedy for a fourth
serial stage — not a deferral of convenience.**

Five items, each with an exact address, all recorded in `build-os/memory/residue.md`
as **(hhh)–(lll)**:

1. **(hhh)** `tests/control_registry_tests.sh:867` — arrow-pair file-selection is
   line-based while extraction is fold-based, so the wrapped pair is dropped
   before folding. `AP_SEEN` reads **2**; the tree has **3**. The assertion at
   `:870` makes a **false coverage claim**. Raising the floor makes it a **fitted
   floor** needing registration to `tests.nonvacuity_minimums` — so this is not a
   one-line fix.
2. **(iii)** `build-os/registry/control_registry.txt:1060` — headline says
   "FAMILY OF 35"; the same field still says 37 / 34 / 34. Re-derive with §21's
   own scan, **not a grep**.
3. **(jjj)** `build-os/registry/neurocosmology_crosswalk.txt:121` — "Seventeen of
   its twenty-two bindings" against a live **20 suites of 25 bindings**.
4. **(kkk)** `build-os/registry/mismatch_dispositions.txt:54` and `:85` — says
   "THE FOUR CONDITIONS" while the tool enforces **five**. **A governance store
   misdescribing its own validator is the failure this registry exists to
   prevent.**
5. **(lll)** `build-os/tools/mismatch-disposition.sh:167` and `:238` — the claim
   that condition (0) removes accidental corpus matches is **false, with a
   reproduction** (`MEASURED`, `PREVENTI`, `UNTOUCHE`, `COVERAGE` all certify at
   exit 0). **Bounded:** it cannot smuggle a non-qualifying control through.

**Declared governance ceiling for this packet:** it is a *correction* packet.
**No new census control, no new registry store, no new validator tool, no new
suite file.**

## Also queued, and NOT consumed

- **(ooo) — BLOCKING, ONE LINE, OUTSIDE THE ARCHIVIST'S GATE.** The live suite
  total is **1869**; `current_state.md` still claims **1771** because advancing it
  ships the tree **red** (`CHANGELOG.md` carries no `1869 passed` literal, and
  `tests/release_metadata_tests.sh` is chained). **Remedy: add `**1869 passed**`
  to the `## [Unreleased]` block of `CHANGELOG.md`, then set the Build/test line
  to 1869.**
- **(ddd) the positional content-pairing guard — STILL QUEUED.** The builder
  verified all 330 refs inline (22 repointed, 0 drifts), but what is queued is a
  **durable guard**, and §27 covers **two-position** citations only. **An inline
  verification performed once is not a guard.**
- **(mmm) make the arrow-pair convention a MECHANISM.** Writing a superseded span
  without its path is a **convention**, and it was violated **twice during this
  packet's own close** by the agent that had just written it down.
- **(nnn)** *"a single-position citation with no duplicate is unpoliced by
  everything currently in the suite."*

## Next phase — P4 S1 shadow ranker, with a ceiling

**P4 is the first phase whose output is a DECISION, not a RECORD of a decision.**

Ledger at the end of P3: **97 controls, ~20 tools, ~1869 assertions, ZERO
executive components.** On P3's density a ranker built to the same standard would
spend **5 controls and 200 assertions before it ranks anything**.

**Carry a declared governance ceiling into the P4 packet:**
**`≤1 new census control, no new registry store, no new validator tool, no new
suite file`.**

**Substrate is ready:** `DECISION-0009` recorded 4 candidates and 16 frozen
snapshots (12 for non-selected arms), and it is the **second consecutive**
decision where selection went **against** the cheap signal. **n=3** non-degenerate
decisions, **two of them human overrides of the cheapest arm with a stated
reason** — that is counterfactual substrate, not imitation data.
