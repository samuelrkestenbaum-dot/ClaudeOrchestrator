# build-os/maintenance — what this layer is, and the manifest it was ported by

<!-- GRAVITO:MANAGED (this file is written by the Gravito maintenance installer;
     local edits are replaced on re-install) -->

This directory is the **Build OS memory maintenance and safety layer**. It does
two things and claims nothing beyond them:

1. **Rotation.** `rotate-memory.sh` keeps the newest N blocks of each Build OS
   memory file live and moves the tail into an append-only archive, with
   byte-exact conservation checked before anything is written. Memory grows
   monotonically; past the agent's 256 KB Read limit a memory file stops being
   readable at all, and a session then starts blind to its own state.
2. **Containment of its own tests.** The suite here exercises a tool that
   rewrites Build OS memory, so the thing that must be true is not "the tests
   pass" but "the tests cannot quietly rewrite your real memory". That is what
   the sanctioned wrapper and the real-memory tripwire are for.

## The command

    ./build-os/maintenance/run-tests.sh

That one, not a bare `node --test`. Where the repo has a `package.json`, the
installer also adds `npm run test:build-os-memory`, whose body is exactly that
invocation. The wrapper's own header states the single guarantee it buys and
enumerates the four paths it does **not** cover. Read it before relying on it.

    ./build-os/maintenance/rotate-memory.sh            # DRY RUN (the default)
    ./build-os/maintenance/rotate-memory.sh --apply    # actually write

## What is managed, and what is yours

**Gravito-managed** — replaced on every re-install, do not edit in place:

    build-os/maintenance/rotate-memory.mjs
    build-os/maintenance/rotate-memory.sh
    build-os/maintenance/run-tests.sh
    build-os/maintenance/real-memory-tripwire.mjs
    build-os/maintenance/source-scan.mjs
    build-os/maintenance/rotate-memory.test.mjs
    build-os/maintenance/rotate-memory.rootscan.test.mjs
    build-os/maintenance/rootscan-controls.json
    build-os/maintenance/install-maintenance.sh
    build-os/maintenance/templates/standing_gates.md
    build-os/maintenance/PORTING.md
    build-os/maintenance/.gravito-managed      (the authoritative copy of this list)

**Yours, never overwritten** — seeded from a template only when absent:

    build-os/memory/standing_gates.md
    build-os/memory/current_state.md, residue.md, packets/active_packet.md
    build-os/memory/archive/**            (created by --apply; never rewritten)
    .gitignore                            (one appended managed line)
    package.json                          (one added script, only if the file exists)

## Uninstall / rollback boundary

Removing this layer is: **delete every path listed in
`build-os/maintenance/.gravito-managed`** — the list above, which that file
carries verbatim so an uninstall never has to be reconstructed from docs. That
empties `build-os/maintenance/`. Optionally also drop the `test:build-os-memory`
script and the `!build-os/memory/archive/` line. Nothing else is touched.

Explicitly **not** removed, because they are yours: `build-os/memory/**`
(including `standing_gates.md` and anything already rotated into
`build-os/memory/archive/`). Removing the layer does **not** un-rotate memory —
rotation already happened, and the archive is the only copy of what left the live
files. Re-inline an archived block by hand from
`build-os/memory/archive/INDEX.md` before deleting anything, or keep the archive.

This boundary is proven, not asserted, and the proof RUNS:
`tests/build_os_maintenance_tests.sh` installs the layer into a blank repo,
removes exactly the managed list, and asserts the customer files are
byte-identical to what they were before the install. That suite is **chained from
`tests/build_os_tests.sh`**, whose totals include its assertions — so the
uninstall boundary is re-proven by the repo's ordinary test command rather than
by a doc that asks you to remember a second one. The two commands are:

    bash tests/build_os_tests.sh              # the repo suite; chains the above
    ./build-os/maintenance/run-tests.sh       # the layer's own suite

**Full version rollback (restoring a previous release of the layer) is out of
scope.** There is no version stamp and no downgrade path. Roll back with your own
VCS, which is why every file here is meant to be committed.

## What the proof does NOT cover: other platforms

Everything measured for this port was measured on **one machine** — Linux, with
that machine's `node`, `git` and `bash`. No other platform was exercised. The
code handles both `sha256sum` and `shasum` because macOS ships only the latter,
but that branch has not been executed here, and nothing else about a non-Linux
or non-GNU environment (BSD `find`/`sed` behaviour, a different `bash` major
version, path case-sensitivity) has been tested at all. Treat a first run on
another platform as unproven, and run both suites there before relying on it.

---

# SOURCE-TO-PRODUCT MANIFEST

The layer was proven in a **reference deployment** — a private product repo that
used Build OS daily — and ported here. Everything below was measured during the
port; classifications are PORT (verbatim), ADAPT (changed, with the reason),
EXCLUDE (deliberately not shipped), or BLOCKED (cannot ship in this packet).

Reference source: `build-os/maintenance/` @ `cb2bb7d`, 8 files, 388,088 bytes.

## PORT — verbatim, no repo-specific content found

| Artifact | Bytes | Note |
| --- | --- | --- |
| `source-scan.mjs` | 17,164 | Pure text functions, zero imports, zero paths. |
| `rootscan-controls.json` | 9,980 | Dangerous source shapes in a file that cannot execute. Its one path fixture (`/home/user/some-repo`) is synthetic and never resolved. |

## ADAPT — shipped, changed for the reason given

| Artifact | Change | Reason |
| --- | --- | --- |
| `rotate-memory.mjs` — `FILE_SPECS` | `current_state` delimiter `/^> \*\*(LATEST\|PRIOR)/` → `/^## /` | **The one load-bearing adaptation.** These delimiters are coupled to the memory format the scaffold writes. Measured against the product scaffold: the reference delimiters found **0 / 0 / 0** blocks; `^## ` finds **3 / 3 / 5**. A delimiter that matches nothing does not error — it yields a REPORTED NO-OP at exit 0, i.e. a file that never rotates. The coupling is now documented at the declaration and pinned by an executed test ("every rotating file that exists yields blocks under its own delimiter"). |
| `rotate-memory.mjs` — zero-block reporting | NEW `delimiterMatchedNothing` + a stderr warning | Follows directly from the row above. The stdout report printed one byte-identical `already rotated (no-op)` line for three unrelated states: a delimiter that matched nothing in a file that HAS content (the hazard), an empty/whitespace-only file, and a file that parsed fine with nothing old enough to archive. Zero blocks plus non-whitespace content now raises a warning on **stderr** naming the file and the delimiter. The exit code is deliberately unchanged — an empty scaffold parses to zero blocks legitimately, so failing the run would be wrong — and `--json` carries it as `originalHasContent`. Both directions are pinned by one executed test (fires on wrong-delimiter-with-content, silent on an empty file). |
| `rotate-memory.mjs` — `INDEX_HEADER` | dropped a reference-repo file path from the example citation | The example named a file that exists in no customer repo. |
| `rotate-memory.sh` — header | "has grown past the 256 KB Read limit on all three hot files" → a statement of the mechanism plus a dry-run instruction | The claim was false even in the reference repo by the time it shipped, and is unknowable for a customer. |
| `run-tests.sh`, `real-memory-tripwire.mjs`, `rotate-memory.test.mjs`, `rotate-memory.rootscan.test.mjs` | every dated clone pass-count ("106 pass", "132 pass", "122 pass", "6 pass") dropped; each surrounding claim re-anchored to "measured in the reference deployment at `cb2bb7d`" and reduced to its shape — "the whole suite stayed green — 0 fail, exit 0" | The *shape* of each measurement is load-bearing evidence (a mutation that nothing caught, or a green run with a destroyed tree); the *count* is a fact about another repo's suite on a particular day, and "measured at the commit before this one" reads, in a customer repo, as a claim about *their* previous commit. The one count that remains — `0 pass / 3 fail / exit 1` for the wrapper refusing an uncovered file — was **re-measured in this port** on a fresh install into a blank repo, and its `3` is explained where it appears (one failure per suite file in the directory) rather than quoted as a magic number. |
| `run-tests.sh` — discoverability | npm signpost made conditional on a `package.json` existing | This layer installs into any git repo, not only Node projects. |
| `rotate-memory.rootscan.test.mjs` — `PKG_SCRIPTS` | unconditional `readFileSync(package.json)` → `null` when absent, with the fallback pinned instead (wrapper executable + invocation printed in this file) | **A bare repo must still pass.** The unconditional read threw `ENOENT` at module load, taking the whole suite down. A manifest that exists but does not parse is still a failure — otherwise deleting a brace would be the cheapest way to switch the pin off. |
| `rotate-memory.rootscan.test.mjs` — gates arithmetic | required exactly 3 `## SOURCE:` sections and ≥ 20 entry blocks → template mode when the file declares no section; per-section consistency the moment one appears; totals paragraph optional but "both or neither, and both true" | The old numbers were the reference repo's gate inventory. What generalises is that the bookkeeping is never decorative. |
| `rotate-memory.rootscan.test.mjs` — companion disclosure | exact sentence "it says `HARD-STOP` not `HARD STOP`" → the word `companion` (case-insensitive) in the entry block | The sentence was a fact about one entry; the *disclosure* is the rule. |
| `rotate-memory.rootscan.test.mjs`, mirror check | reads the gates file and the rotating files tolerantly; missing gates file is one named failure, a missing rotating file is skipped, zero rotating files is fatal | Unguarded reads crash the suite instead of reporting. |
| `rotate-memory.test.mjs` — real-content keeps | hard-coded `keep1=3, keep2=2` behind `smallest >= 4` → keeps derived from the live block count behind `smallest >= 3` | 4 was a floor only a large tree meets; the product scaffold gives 3/3/5. Three descending counts are what a two-pass (prior-banner) proof actually needs, and that is now the stated reason. |
| `rotate-memory.test.mjs` — header | a paragraph positioning the suite against the reference repo's own test framework, source layout and sibling suites → a statement that this suite is `node:test`-only, dependency-free and confined to this directory | Named another repo's test topology, which tells a customer nothing and leaks that repo's structure. |
| `templates/standing_gates.md` | NEW — the *concept* ported, none of the content | See EXCLUDE below. |

## EXCLUDE — deliberately not shipped

| Artifact | Reason |
| --- | --- |
| `build-os/memory/standing_gates.md` **content** (410 lines) | It is the reference repo's live hard-stop inventory — named production source files, named systems, and the specific approvals that were gated on them. Customer data, in the most concentrated form this layer touches. Shipping it would leak it into every install. **The concept is ported instead:** a contract-only template with the never-rotated rule, the watched-≠-protected rule, the mirror rule, and two gates that belong to Build OS itself so the mirror check is not vacuous on day one. |
| "22 of 24 `HARD STOP` occurrences rotate away" | A measurement of that tree at that commit. Re-anchored where the story is load-bearing (it is the proof that rotation loss is real and silent), attributed to the reference deployment, and explicitly disclaimed for the reader's repo. |
| "900 KB / 830 KB / 705 KB", "114 / 114 / 96 blocks" | Same class: measurements of another repo's memory, quoted as if they described this one. **Handled the same way as the row above, not deleted everywhere:** the sizes survive at exactly two sites — `rotate-memory.mjs`'s "what this tool does not guarantee" header and `rotate-memory.test.mjs`'s containment header — because in both the point is the pressure the layer was built under. Both attribute the number to the reference deployment at `cb2bb7d` and both close by disclaiming it for the reader. The block counts appear nowhere. |
| Any *unattributed* reference-deployment measurement, anywhere in the shipped fileset | The rule the two rows above are instances of. Enforced by sweeping the whole ported fileset for `900 KB`, `830`, `705`, `114 / 114 / 96`, `N pass`, `22 of 24` and `388,088`: every surviving hit is either inside this manifest (which is explicitly *about* the reference deployment), or carries an explicit "in the reference deployment at `cb2bb7d`" plus a disclaimer, or was re-measured in this port and says so. |
| Reference-repo receipts, packet ids, connector inventories, credential values, service names | Never in scope. None entered this port; the safety grep for them is part of the packet's proof. |

## BLOCKED — flagged, not fixed here

**`init-build-os.sh` seeds customer scaffolds from this repo's LIVE memory
files.** `copy_if_absent` copies `build-os/memory/tool_router.md`,
`current_state.md`, `residue.md`, `packets/active_packet.md` and
`receipts/README.md` straight out of the product repo's working tree.
`install-project.sh` copies the same five. Those are not templates: they are this
account's live Build OS state, including a `tool_router.md` that is ~23 KB of
one account's connector inventory. Every customer scaffold therefore arrives
pre-loaded with it.

This packet **does not add to that leak** — the two files it introduces to the
scaffold path (`standing_gates.md`, and the `.gitignore` archive exception) come
from clean templates under `build-os/maintenance/templates/`, and the installer
wiring added here copies from the template, never from live memory.

**Fixing the existing five-file seeding is a follow-on packet.** It needs clean
templates for all five, and a decision about what a scaffolded `tool_router.md`
should contain — which is a product question, not a maintenance-layer one.

## Not in this packet, by instruction

No licensing, pricing, entitlement, telemetry or production integration. No
secrets, flags, canaries, DDL, deploys or recall runs. No customer or production
data.
