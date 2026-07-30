# STANDING GATES — the never-rotated home of this repo's hard stops

<!-- GRAVITO:TEMPLATE (seeded by the Gravito maintenance installer; yours to edit,
     never overwritten once it exists) -->

## CONTRACT (read this before touching anything in this file)

1. **THIS FILE IS NEVER ROTATED.** It is the authoritative home of standing hard
   stops and standing decisions. Preservation in Build OS is a property of
   **location**, not of text: `build-os/maintenance/rotate-memory.mjs` rotates by
   **recency only** and makes no guarantee about which content survives by
   meaning. A hard stop sitting in a rotating file's archive region is archived
   exactly like any other older content.
2. **THE ROTATION TOOL MUST NEVER INCLUDE THIS FILE IN ITS ROTATION SET.** The
   set is `FILE_SPECS` in `build-os/maintenance/rotate-memory.mjs`, and that list
   is the tool's entire blast radius. `standing_gates.md` is absent from it, so
   the tool never reads, writes or creates this path. That absence is pinned by a
   test in `build-os/maintenance/rotate-memory.rootscan.test.mjs`; if a future
   change adds this file to `FILE_SPECS`, that test fails. Do not remove the pin.
3. **IT IS WATCHED, WHICH IS NOT THE SAME AS PROTECTED.** Being outside the
   rotation tool's blast radius is protection from THAT TOOL and from nothing
   else. This path is therefore also in the tripwire's `REAL_MEMORY_FILES` and in
   `run-tests.sh`'s `WATCHED`, so a test run that moves one byte of it cannot
   report success. Nothing here prevents a write; detection is the whole claim.
4. **ENTRIES ARE COPIES, NOT MOVES.** An excerpt below is copied byte-verbatim
   out of a rotating file; copying it here modifies no rotating file. The
   duplication is deliberate and accepted. Whether to dedup the live copy is an
   operator decision, never an automatic one.
5. **NOTHING HERE IS SATISFIED, RETIRED, OR SUPERSEDED BY BEING WRITTEN DOWN
   HERE.** These are records of gates, not clearances. Every hard stop below is
   in whatever state its own source says it is in. This file grants no authority
   to cross any of them.
6. **THIS FILE MUST STAY READABLE IN ONE PASS.** Its whole purpose is to be the
   file an agent *can* read when the rotating files are too large to read. Keep
   it well under the 256 KB read limit. If it approaches that, split it by kind —
   do not truncate it.

## THE MIRROR RULE

Every line in a **rotating** file (`build-os/memory/current_state.md`,
`build-os/memory/residue.md`, `build-os/packets/active_packet.md`) that **states**
a hard stop must also appear in this file, verbatim modulo leading whitespace.
That direction is the one that matters: rotation deletes by recency, so a gate
written into a rotating file and not copied here is a gate with an expiry date.

`rotate-memory.rootscan.test.mjs` enforces the mirror and reports any gap by
`file:line`. A line that only NAMES the token inside a `code span` is not a gate
statement and is not mirrored — that is how a note *about* this file avoids
having to be copied *into* it.

## HOW TO ADD A GATE

Append an entry block under the source file it came from. The format below is
what the consistency check parses when sections exist; until you add your first
one, this file carries no `## SOURCE:` section and the check asserts only that
this contract is intact.

    ## SOURCE: `<rotating file path>` — N `HARD STOP` line(s), M entry block(s)

    ### RES-01 — <one-line summary>

    ```
    <the line, copied byte-verbatim from the source file>
    ```

    - **why it must not rotate:** <one line>

(Indented above so this example is prose, not a live section: the consistency
check parses `## SOURCE:` headers at column 0, with real integers in place of
`N` and `M`, and would otherwise count this illustration as a section of your
file.)

## STANDING GATES CARRIED BY THIS REPO

Two gates ship with Build OS itself. They are stated here, not merely cited, so
this file is a real mirror on day one rather than an empty promise.

### BOS-01 — external mutation

HARD STOP — never push, merge, deploy, publish, or touch secrets without an
explicit go from the user.

### BOS-02 — packet boundary

HARD STOP — the builder implements exactly the confirmed packet and nothing
else; work outside the packet's scope is surfaced as a follow-up packet, never
built opportunistically.

<!-- Add your repo's own gates below. Nothing above this line is customer
     content; nothing below it is ever touched by the installer. -->
