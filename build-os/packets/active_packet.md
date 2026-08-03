# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## CLOSED — `gravito_current_state_reblock_a` (closed 2026-08-03) — SEE THE LATE DECLARATION BELOW

- **Packet id (CLOSED):** `PACKET-0038-current-state-reblock` — **MINTED, and
  collision-checked BEFORE the mint rather than after.** The live band is
  `PACKET-0001`..`PACKET-0037`, `PACKET-0037` is the highest allocation
  predating this packet, `git log -S'PACKET-0038' --all --oneline` returns **0
  commits** and `grep -rlF 'PACKET-0038' . --exclude-dir=.git` **0 files**.
- **Lane:** `substantive`. **Depth 2** — builder, then qa ‖ reviewer.
- **This commit is the declaration, and it is commit 1**, so that
  `bandwidth.active_packet_singleton` reads **1 in flight** for the whole life
  of this packet: no measurement taken inside a packet ABOUT a memory file may
  be taken against a packet file lying about what is in flight.
  `DEFECT-0011-undeclared-active-packet` sits at `OCCURRENCE-0005` and the
  remedy it names — a LOWER bound on the same cardinality check — does not exist.
- **THIS EDIT IS LINE-COUNT-NEUTRAL ABOVE THE `ANC-0003` SITE ON PURPOSE.**
  `DEFECT-0001-stale-line-reference` fired at this exact site at each of the
  last two declarations: the committed kernel projection embeds
  `build-os/packets/active_packet.md:89#ANC-0003` as a RESOLVED line number and
  `tests/memory_kernel_tests.sh` §18 compares it with `cmp -s`. This
  declaration replaces the previous one **in place, line for line**, so the
  anchor site does not move and no projection needs regenerating.

## Branch base

Branched at `3ec519b` on `claude/project-handoff-merge-ramhds`, verified with
`git merge-base HEAD claude/project-handoff-merge-ramhds` → `3ec519b`, **before
the first edit**. **Nothing is pushed, merged, tagged, PR'd or deployed by this
packet, and no such go has been given.** (Previous base `9c740d7`; see the close.)

## What `gravito_current_state_reblock_a` must make true

`build-os/memory/current_state.md` is in the dead end `residue.md` was just
taken out of, and this time **prospectively**: `wc -c` reports **185204 B**
against the **204800 B** ceiling `rotate-memory.test.mjs` enforces — **19596 B
of headroom** — while `grep -c '^## '` reports **exactly 3** blocks, so
`routeSegments`' `blocks.slice(0, keepN)` retains all 3 at the shipped
`keep=10` and archives **0 blocks / 0 bytes** at **exit 0**.

1. **Failing tests first**, reproducing the live condition, with the RED shown.
2. **Re-block** it so rotation reclaims real space: standing/current truth
   first, active risks next, history newest-first, cut at the file's own era
   markers and never mid-entry.
3. **A protected region rotation cannot reach**, proven by an executed sweep
   over every legal `--keep`, not argued.
4. `--dry-run` only. **Rotation is NOT applied** — a separate operator packet.

**Out of scope:** raising any ceiling, applying rotation, moving standing
content into `standing_gates.md`, and fixing any residue item.

## Status: CLOSED, NOTHING IN FLIGHT — `gravito_measurement_integrity_a` closed 2026-08-03

- **Packet id (CLOSED):** `PACKET-0036-measurement-integrity` — **MINTED, not reused**, and
  collision-checked **before** the mint rather than after: the live band is
  `PACKET-0001`..`PACKET-0035`, `PACKET-0035` is the highest allocation predating
  this packet, `git log -S'PACKET-0036' --all` returns **no commit**, and a
  full-tree grep for the token returns **nothing**. The id was free.
- **Base:** `a2648dc`, verified with `git merge-base` **before the first edit**
  (`git merge-base HEAD claude/project-handoff-merge-ramhds` → `a2648dc`).
- **Lane:** `substantive`. **Depth 2** — builder, then qa ‖ reviewer.
- **Declared before building, in its own commit**, per the standing contract — and
  **this commit exists because the last packet's did not.**

### Why this declaration is commit 1 and not a formality

The previous packet — the largest of the sequence — was built, gated and closed
while this file read `NOTHING IN FLIGHT` and described `PACKET-0029`. The
measurable consequence: **`bandwidth.active_packet_singleton` reported ZERO in
flight while that packet was in flight.** The guard passed, truthfully, on a file
describing the wrong packet.

That is `DEFECT-0011-undeclared-active-packet`, **`OCCURRENCE-0005`** — a
recurrence of a class this repository had **already registered**, and whose
`could_have_been_prevented_by` **already names the remedy**: a *lower* bound on
the same cardinality check, refusing zero declared packets while a build is in
flight. Only the upper bound exists. **The class has now fired twice against a
prevention that was specified and never built.**

So this commit is not bookkeeping. It is the one action that makes the guard's
`0`/`1` reading true of the world for the duration of this packet, and it is
taken first so that no measurement inside this packet is taken against a file
that is lying about what is being measured — which is the packet's whole subject.

canonical packet id: PACKET-0029-citation-anchor-tokens

**THE BARE LINE ABOVE IS NOT A DECLARATION AND MUST NOT BE DELETED.** It is the
**content site** that `ANC-0003` resolves to, and it is written on its own line
precisely so that the closed packet's identity is reachable **by content rather
than by position**. It is the packet's own scheme applied to the packet's own
record. The anchor requires that literal to occur **EXACTLY ONCE** in this file —
zero occurrences resolve as `ANCHOR-UNRESOLVED` and two or more as ambiguous, and
**both are violations that drive `scan-controls.sh check` to exit 2.** It does not
match the declaration pattern the bandwidth ceiling counts, so **it still declares
nothing in flight** — the count of `1` above comes from the `**Packet id:**` line
and from nothing else.

### What declaring this packet COST, measured rather than assumed

**Writing the declaration turned the suite red, and the red was not about the
declaration.** `tests/memory_kernel_tests.sh` §18 runs `memory-kernel.sh reconcile`
against the LIVE committed projection, and the projection embeds `ART-0003` as
`build-os/packets/active_packet.md:15#ANC-0003` — **a resolved line number.**
Adding text above the anchor site moved it 15 → 40, `cmp -s` saw two different
bytes, and the suite reported `PROJECTION-DIVERGED`. Base run: `2095 passed, 1
failed`.

**The identity half was never wrong.** `scan-controls.sh anchors` resolved
`ANC-0003` cleanly at the new position throughout — 12 resolved, 1 superseded, 0
violations — because content resolution is exactly what it was built to do. Only
the **projection** of that resolution was stale, which is the position half doing
what the anchor scheme demoted it for doing.

**The repair is the sanctioned one and not a store edit.** A projection is
generated and never hand-edited; `export-handoff --out` is a pure read that
appended **no event** and touched **no canonical store** (`validate`: 8/4/11/14/25/8/1/1,
**0 violations**; `git status` showed only the projection). `memory_events.tsv` is
untouched. **The one-line delta is the line number and nothing else.**

**This is `DEFECT-0001-stale-line-reference` reappearing inside the mechanism
built to demote line numbers**, and it is recorded here as a finding for residue
rather than fixed: every content-preserving edit above any anchored site is a
red suite until someone regenerates the shadow, so **a byte-exact reconcile of a
position-bearing projection is itself a false-negative generator** — the same
family as `DEFECT-0013`, arriving by a different route. Not in this packet's
scope to fix; **named, not normalised.**

## CLOSED — `gravito_measurement_integrity_a` — NOTHING IN FLIGHT

**Closed 2026-08-03 at `aa0a7b3`. The declaration above is preserved verbatim rather than
deleted**, because this packet exists partly to prove that the declaration was written BEFORE the
build; a record that is erased on close cannot testify to that. What changed at close is the
STATUS and the `**Packet id:**` marker — the bandwidth guard's declaration pattern no longer
matches, so `bandwidth.active_packet_singleton` correctly reads **0 packets in flight against a
ceiling of 1**, which is true of the world again.

- **Verdict: PASS-AS-FIXED.** qa **GREEN**; reviewer `fix-then-pass`, every item fixed in
  `aa0a7b3` and verified by the orchestrator rather than by opening a fourth gate stage.
  **Depth: 3 serial stages.**
- **Receipt:** `build-os/receipts/gravito_measurement_integrity_a.md`
- **Commits:** `0cdb3b7` (declaration) + `53b92d4` (fix, sweep, guard) + `aa0a7b3` (claim
  corrections), base `a2648dc`, re-verified at close — `git merge-base aa0a7b3 a2648dc` returns
  `a2648dc`. **None pushed. None may be amended.**
- **THE FOUR THINGS THE PACKET HAD TO MAKE TRUE WERE ALL MADE TRUE, AND THE RULING WAS GIVEN.**
  (1) The defect is fixed at its site **without disabling `pipefail`** — the consumer drains.
  (2) The class was swept, and the sites that cannot race are recorded **with the measurement
  that says why** rather than deleted from the list. (3) The fix is proven at **4000 iterations
  before and after**, quiet and under load: **15.33% -> 0.0000%** quiet, **42.60% -> 0.0000%**
  under 4-way load, **100% -> 0/2000** on an amplified fixture. (4) The guard is 7 assertions in
  an existing suite and **says plainly what it cannot see** — and every declared blind spot was
  **confirmed real by qa's sneak test**, five idioms walking straight past it.
- **THE RULING: a single green run is again sufficient FOR THIS DEFECT, and the doubled-run
  discipline STAYS IN FORCE.** *What was measured is that one NAMED non-determinism is gone; what
  would license dropping the discipline is that NO UNNAMED one remains, and nothing here measures
  that.* Retiring it is an **operator act** with a stated price: N>=200 consecutive full-suite
  runs at a fixed commit with **zero variation in the per-suite PASS/FAIL VECTOR**, not in the
  total. `(ttttt)`.
- **THE HEADLINE OUTPUT IS NOT THE FIX. It is that the 6.26%-vs-15.70% discrepancy was FIXTURE,
  not load** — a **one-row** store growth doubled the failure rate, 7.53% -> 14.55%, same machine
  and same code. **The rate of a latent non-determinism is a function of a data volume nobody is
  watching**, so a site measured at 0% today can flap tomorrow with no code change and no test
  turning red.
- **THE CEILING HELD.** Census **105** and **zero `+control` lines — NO new control**; declared
  mismatches **22**; gate-on-advise **14**, execute **8**, identical at base and HEAD;
  `rank-candidates.sh` the same blob `5543ea8`; `signal_snapshots.tsv`, `decision_telemetry.tsv`
  and `memory_events.tsv` all **zero diff**; `(ddd)` still queued and `(uuuu)` still open.
- **DEVIATION, RECORDED AND NOT NORMALISED: 3 commits against the `<=2` cap**, the third close in
  a row with this shape. The fix round landed as its own commit rather than amending commits the
  gates had already measured. The receipt's manifest is a **sequential attribution by role, not a
  disjoint partition**, and is **not a precedent for a fan-out**.
- **NOTHING IS STAGED NEXT, AND THAT IS DELIBERATE.** Declaring the next packet is a **routing
  act**, not bookkeeping, and the archivist does not take routing acts. Two candidates are
  **routed and not chosen** in the receipt: making receipts participate in the kernel's
  `contradicts` edges `(wwwww)`, and removing the resolved line number from the byte-compared
  projection `(uuuuu)`.

## RESULT — what was measured, and the ruling

**THE FIX, MEASURED AT THE SITE.** `tests/speed_benchmark_tests.sh` §10, the
git-backed assertion, run against the live store:

| form | iterations | false FAILures | rate |
|---|---|---|---|
| shipped `… \| awk \| grep -q .` | 4000 | **628** | **15.70%** |
| fixed `… \| awk \| any` | 4000 | **0** | **0.0000%** |

and on a fixture amplified past two pipe buffers (217972 bytes), where the effect
saturates: **1000/1000 = 100.00% before, 0/2000 after.** `PIPESTATUS=[0 141 0]`
— element 2, the `awk`, killed by SIGPIPE. `pipefail` **stays on** for the file;
the consumer was made to drain instead.

**THE CLASS SWEEP. EVERY FIGURE BELOW CARRIES THE COMMAND THAT REPRODUCES IT**,
because the first draft of this section stated two that nothing in the tree could
reproduce, which is `DEFECT-0002` committed inside a packet about measurement.

**45** `pipefail`-enabling shell files across `tests/`, `build-os/` and
`.claude/hooks/` —
`grep -rlE '^set -[a-z]*o pipefail' tests build-os .claude/hooks --include='*.sh' | wc -l`.
**That is 45 of the 54 in the whole tree** (same command rooted at `.`, minus
`.git`); the nine outside the scan are named in the §28 header, **four of them
carry `set -euo pipefail`**, and the gap is measured harmless — the same two
patterns over all 54 files yield the **same 3 hits, all allow-listed**.

**258** candidate `producer | early-exiting consumer` pipelines, comment lines
excluded — the 45 files piped through
`xargs grep -hE "\|[^|]*($SP_KILL)" | grep -vE '^[[:space:]]*#' | wc -l` with
`SP_KILL` as written at `tests/build_os_tests.sh`; **257** excluding the one
line carrying the scan-exempt marker, and **70** lines matching `SP_STREAM`.
**The earlier figure of 235 is withdrawn: no derivation reproduces it.**
**Exactly one could race.** The discriminator is the 64 KiB pipe buffer, and it
was **calibrated rather than assumed**: streams under one buffer measured
**0/4000**, streams over it **1.80%–100%**.

| site | producer volume into the killer | measured | disposition |
|---|---|---|---|
| `speed_benchmark_tests.sh` §10 git-backed | **72147 B** — over the buffer | **628/4000** | **FIXED** |
| `speed_benchmark_tests.sh` §10 non-git | 462 B, one write | 0/4000 | converted anyway |
| `speed_benchmark_tests.sh` §10 empty-cell | 519 B out, **72609 B in** | 0/4000 | converted anyway |
| `record-packet.sh` `datarows \| cut \| grep -qxF` | 622 B | 0/4000 | recorded, allow-listed |
| `speed_benchmark_tests.sh` `datarows "$RT" \| head -n1` (×2) | ~200 B fixture | 0/4000 | recorded, allow-listed |
| `sed … FILE \| head -N` diagnostic dumps (**count withdrawn**) | ≤8056 B measured | — | recorded; status discarded, no `set -e` |
| 3 scripts with `set -e` **and** `pipefail` | — | — | **zero** early-exiting pipelines in them |

**THE `sed … \| head -N` COUNT IS WITHDRAWN RATHER THAN RESTATED.** "~40" is not
reproducible: a strict `sed … \| head` scan over the 45 files gives **13**, every
`\| head` line gives **87**, and neither is 40. **The load-bearing half survives
and is derived:** the three scripts that combine `set -e` with `pipefail` are
`build-os/maintenance/install-maintenance.sh`, `build-os/maintenance/rotate-memory.sh`
and `build-os/tools/capability-profile.sh`, and
`grep -hE "\|[^|]*($SP_KILL)" <those three> | grep -vE '^[[:space:]]*#' | wc -l`
returns **0**. So no early-exiting pipeline anywhere in this tree sits under
`set -e`, its status is discarded in statement position, and it cannot become a
verdict. **A number nobody can re-derive is not evidence, and one is not kept
here merely because it was already written down.**

**THE TWO NON-RACY §10 ASSERTIONS WERE CONVERTED ANYWAY, AND NOT FOR TIDINESS.**
The empty-cell assertion is structurally the *worst* of the three — its `awk`
stops after 519 bytes while `datarows` still has 72 KB to push — and it measures
0/4000 only because **mawk's `exit` happens not to kill its producer on this
toolchain**. **THE FIGURES BELOW REPLACE AN EARLIER "5/5", WHICH WAS TRUE OF ONLY
TWO OF THE FIVE CONSUMERS AND WAS DRAWN FROM A SAMPLE (n=5) THAT CANNOT
DISTINGUISH 8% FROM 100%.** Measured over **N=200 trials each**, producer killed:

| consumer | producer killed |
|---|---|
| mawk `exit` | **0/200 = 0.0%** |
| `grep -q .` | 16/200 = **8.0%** |
| `grep -m1 .` | 19/200 = **9.5%** |
| `head -1` | 105/200 = **52.5%** |
| `sed -n '1p;1q'` | 200/200 = **100%** |
| bare `{ read }` | 5/5 |

**The conclusion is unchanged and strengthened by the 0/200**: mawk's `exit` is
uniquely non-lethal, so the safety of that assertion is a fact about which `awk`
is installed and not about its shape. A guarantee that depends on the toolchain
is not a guarantee, and draining removes the dependency.

**THE GUARD — `tests/build_os_tests.sh` §28, 7 assertions.** Two halves, on the
§27 precedent: (a) a **red drive** that builds a fixture past two pipe buffers and
*demonstrates* the `grep -q` form failing on correct data before any green claim
is made, and (b) a **static scanner** over all 45 files with a measured
allow-list. **The scanner's power is not asserted: it caught its own red-drive
line** on first run, which is why that line now carries an exemption marker.

**WHAT THE GUARD CANNOT SEE, stated rather than implied:**
- **Volume — the thing that actually decides.** Whether a producer exceeds 64 KiB
  is a runtime fact about data the scan never reads. **An allow-listed site whose
  data later grows past a buffer becomes racy with nothing turning red.**
- **Producer idioms it does not enumerate** — a function wrapping `cat`, a process
  substitution, a `while read` fed by a big stream.
- **A future `set -euo pipefail` script**, where a discarded 141 becomes fatal.
  Today all three such scripts are clean, and **nothing enforces that.**

## THE RULING ON EVIDENCE — and it is not the flattering one

**A single green suite run is again sufficient evidence FOR THIS DEFECT. THE
DOUBLED-RUN DISCIPLINE STAYS IN FORCE ANYWAY.**

Those are not in tension, and the distinction is the point. What was measured is
that **one named non-determinism is gone**. What would license dropping the
discipline is that **no unnamed one remains** — and nothing here measures that.
The evidence for the narrow claim is strong; the evidence for the broad claim was
never collected, and answering the second question with the first one's data is
precisely the epistemic error this packet exists to correct.

The asymmetry settles it, **with the asymmetry stated correctly**: the error is
one-directional **at the `&& ok || no` polarity every assertion in this suite is
written at** — it is not one-directional as a class, and the counterexample is
measured and recorded in `(qqqqq)`. Retaining the discipline costs one suite run
and dropping it costs the credibility of every red this tree will ever report.
**Retiring it is an operator act** and wants a second measured packet's worth of
clean runs behind it, not this one. Residue `(nnnnn)`, corrected by `(qqqqq)`.

## Branch base

Branched at `a2648dc` on `claude/project-handoff-merge-ramhds`, verified with
`git merge-base` before the first edit. **Nothing is pushed, merged, tagged, PR'd
or deployed, and no such go has been given.**

## What this packet must make true

The project's next frontier is **experience** — running
`ranking → selection → execution → outcome → memory → comparison → repeat`
repeatedly. That loop's payload is **comparison**, and comparison requires a
measurement substrate that does not lie.

`DEFECT-0013` is that substrate lying. **At the `&& ok || no` polarity — which is
how every assertion in the affected suites is written — it cannot fabricate a
success, so every prior green stands** — but **it can fabricate a failure**, and
a false "went red" written into an outcome record poisons the store S1 will
eventually train on. **That scoping is load-bearing and was missing from the
first draft of this packet: at the INVERTED polarity the same race yields a false
PASS. Measured counterexample and its unreachability: `(qqqqq)`.** Its sharpest
form:
`tests/release_metadata_tests.sh` compares a **live** suite total against memory,
so if the race fires there, **the guard that keeps memory honest emits a false
staleness verdict.**

Four things, and only these four:

1. **Fix the defect** at its site, without disabling `pipefail` for a whole file.
2. **Sweep the class** — `producer | … | early-exiting consumer` under `pipefail`
   — across `tests/`, `build-os/` and `.claude/hooks/`. Fix the sites that can
   actually race; **record the ones that cannot, with the measurement that says
   why.** A site is only racy if the producer can emit more than one pipe buffer.
3. **Prove the fix by measurement** — the affected assertion run **≥4000 times**
   before and after, both rates reported. "It passed once" is not evidence in this
   tree; that is the exact epistemic error this packet exists to correct.
4. **Add a guard for the class** in an existing suite, and say plainly what the
   guard **cannot** see.

And then one ruling, either way and not the flattering way: **is a single green
suite run sufficient evidence in this tree again, or does the doubled-run
discipline stand?**

## Ceiling

- Add only the controls strictly required. **Declared mismatches stand at 22**,
  and a cap on that raw total is **not** a governance instrument: `lic_of` tops
  out at `gate` for Class A and **no class licenses `execute`**, so every
  durable-write control must declare a mismatch and no packet can decline.
  **The number that constrains anybody is gate-on-advise: 14, unmoved since base.
  Do not move it.**
- **Do NOT touch `build-os/metrics/rank-candidates.sh`** (blob `5543ea88`),
  `signal_snapshots.tsv`, or `decision_telemetry.tsv`. The live experiment's S1
  report must still digest to
  `e838284e2bba52628647d0c7ddd1ed258a7aab7cc391a5ac99992ad7584eb596` at hand-back,
  with `rank_of_selected: 1` still deriving.
- **Do NOT rewrite any row in `build-os/kernel/memory_events.tsv`.** The last
  packet re-chained `EVT-0024`/`EVT-0025` in place — the exact operation its own
  `EVENT-APPEND-ONLY` guard refuses — and **`validate` returns 0 violations on
  that re-chained history**, so the kernel is blind to it and git is what caught
  it. **Corrections create later events.** Do not rely on `validate` here.
- `(ddd)` stays queued; `(uuuu)` stays open. **Fix no other residue item.**
- An unrelated defect: **record a stable defect-class identity, create residue,
  and CONTINUE.**

## CLOSED — `gravito_cross_surface_memory_kernel_v0`

- **Packet id (CLOSED):** `PACKET-0035-cross-surface-memory-kernel` — **MINTED, not reused**,
  and the mint was **collision-checked at this close rather than accepted from the brief**,
  because that check has caught a real defect before. The derivation: the live band runs
  `PACKET-0001`..`PACKET-0035`; the highest allocation predating this packet is `PACKET-0034`;
  `git log -S'PACKET-0035' --all` returns **exactly one commit**, this packet's own `d2c09c6`;
  and `git grep -l 'PACKET-0035' ea069a7` returns **nothing** — the token did not exist at the
  base. **The id was free and collides with nothing.**
- **Title:** cross-surface memory kernel v0 — governed project memory that a second surface can
  consume without the transcript.
- **Receipt:** `build-os/receipts/gravito_cross_surface_memory_kernel_v0.md`
- **Commits:** `d2c09c6` (build) + `8ba368a` (residue) + `727de75` (fix round), base `ea069a7`
  (re-verified at close: `git merge-base 727de75 ea069a7` returns `ea069a7`). **None pushed.**
- **Verdict: PASS-AS-FIXED.** qa returned **GREEN**; the reviewer returned `fix-then-pass` on
  **6 enumerated items**, all 6 fixed in `727de75` and **verified by the orchestrator** rather
  than by opening a fourth gate stage.
- **Depth: 3 serial stages** — builder; qa ‖ reviewer concurrently; bounded fix round.
  **No stage 4.**
- **THE SUCCESS CONDITION WAS EXECUTED, NOT DESIGNED: Claude closed work into Gravito memory, and
  ChatGPT consumed the governed project state without Sam copying the transcript.** The ledger
  PERFORMED the loop — `EVT-0023 HandoffCreated` (ACT-0002, `claude.cowork.session.ramhds`) ->
  `EVT-0024 ContextCompiled` (ACT-0003, `chatgpt.web.session.strategy-01`) ->
  `EVT-0025 HandoffAccepted`. **The surface changes between the first and second event and the
  actor changes with it.** qa confirmed all six section-19 questions are answerable from the
  export **alone**, found **no transcript text anywhere** in the stores, and established the
  stores were **adapter-written**: a 25-row SHA-256 chain, each digest a function of its own
  fields and its predecessor's, `recorded_at` monotonic across a **9-second window**.
- **AND THE REFUSAL THE PACKET EXISTS FOR:** `PACKAGE-STALE` refuses a package read
  `--as-current` that binds versions the project has left — *"resolvability is not identity"*,
  EXIT=2 — while the **same package read as history returns exit 0 with `state: STALE`.**
- Suite **1995 -> 2096** (+101, **all** of it the new `tests/memory_kernel_tests.sh`: 87 at the
  build commit, 101 after the fix round); census **101 -> 105**; declared mismatches **21 -> 22**;
  anchors **12 resolved / 1 superseded / 0 violations**; **zero re-authorisations**.
- **DEVIATION, RECORDED AND NOT NORMALISED: 3 commits against the `<=2` cap**, the same shape as
  the previous close. The fix round landed as its own commit rather than amending commits the
  gates had already measured. **The three commits OVERLAP** — build and fix share 10 files,
  residue and fix share 1 — so the receipt's manifest is a **sequential attribution by role, not
  a disjoint partition**. Legitimate for three serial passes by one agent; **not a precedent for
  a fan-out.**
- **DEVIATION, RECORDED AND NOT NORMALISED: THE FIX ROUND REWROTE TWO COMMITTED EVENT ROWS IN
  PLACE.** `EVT-0024` and `EVT-0025`, 2 insertions / 2 deletions, digests **recomputed** — and
  `EVT-0025`'s own fields did not change at all, which is the signature of a re-derived chain.
  **That is precisely the operation this packet's own `EVENT-APPEND-ONLY` guard refuses, and
  whose red-drive is section 3 of its own suite.** A correction event could have carried the
  anchor. Mitigating: v0 store, created here, consumed by nothing outside the packet, prior
  digests recoverable from git. **Not a stage-4 defect.** Residue `(ddddd)`.
- **`DEFECT-0013` OUTRANKS THIS PACKET AND IS NOT ITS FAULT.** The base tree is
  non-deterministic — **6.26% per invocation quiet, 19.97% under load** — via a
  `pipefail`/SIGPIPE race proven by `PIPESTATUS=[0 0 0 141 0]`. **The error is one-directional at
  the `&& ok || no` polarity these assertions are written at** — so every prior green stands and
  every prior red on that assertion is suspect — **but not as a class: see `(qqqqq)`.** **A single
  green run is no longer sufficient evidence in this tree.** Residue `(ccccc)`.
- **Second eyes: NONE — THIRTEENTH consecutive packet**, re-verified at close.

## THE DECLARATION THAT WAS NEVER WRITTEN — THIS FILE'S OWN DEFECT, AGAIN

**THIS FILE READ `NOTHING IN FLIGHT` AND DESCRIBED `PACKET-0029` FOR THE ENTIRE LIFE OF THE
LARGEST PACKET IN THIS SEQUENCE.**

Every prior packet in the sequence opened with a `docs(packet): declare ...` commit **before
building**. **The orchestrator dispatched this builder without one.** The id was minted inside
the build commit; **the declaration and the in-flight record were never written here.**

**THE MEASURABLE CONSEQUENCE:** `bandwidth.active_packet_singleton` **reported ZERO in flight
while the largest packet of the sequence was in flight** — the guard passed, truthfully, on a
file that was describing the wrong packet.

**PROVENANCE: ORCHESTRATOR, NOT BUILDER.** It is recorded that way for the same reason the
`residue_items_closed=1` provenance was recorded at the previous close: **a count or a
declaration that arrives by omission and is repaired by overwriting leaves no trace of how it got
in, and the trace is the only part that generalises.**

**AND THIS IS A RECURRENCE OF A CLASS THIS REPOSITORY ALREADY REGISTERED.**
`build-os/registry/defect_classes.txt` carries `DEFECT-0011-undeclared-active-packet` at
`OCCURRENCE-0005`, whose symptom reads *"an entire packet was built while active_packet.md still
read NO PACKET IN FLIGHT, and the singleton guard passed because it refuses two declarations and
permits zero"*, and whose `could_have_been_prevented_by` already names the remedy: **a lower
bound on the same cardinality check, refusing zero declared packets while a build is in flight.**
**The remedy still does not exist, and the class has now fired twice.**

**NO REGISTRY OCCURRENCE ROW WAS WRITTEN AT THIS CLOSE.** Appending one is a registry mutation
that would move counts the gates measure, and the archivist's write scope is the receipt and
memory. **It is named here and carried as residue `(eeeee)` so the next packet records it through
the governed path rather than as bookkeeping.** Do not tidy this section away.

## CLOSED — `gravito_p5b_citation_anchor_tokens_a`

- **Packet id (CLOSED):** `PACKET-0029-citation-anchor-tokens` — **REUSED, not
  minted**, and collision-checked again at this close against every `PACKET-*`
  token in the tree. It is the id `DECISION-0011` already carries for this
  candidate, and `DECISION-0010` before that; minting a fresh one would put two
  ids on one candidate **inside the store S1 reads**.
- **Title:** citation anchor tokens — stable semantic anchors, and the demotion
  of line numbers from identity to navigation hint.
- **Receipt:** `build-os/receipts/gravito_p5b_citation_anchor_tokens_a.md`
- **Commits:** `df9f740` (build) + `c76b4d0` (memory) + `fbd746d` (fix round),
  base `c2d97f8` (re-verified at close: `git merge-base fbd746d c2d97f8` returns
  `c2d97f8`). **None pushed.**
- **Verdict: PASS-AS-FIXED.** qa returned **GREEN**; the reviewer returned
  `fix-then-pass` on **7 enumerated items**, every one a text or record
  correction; all 7 fixed in `fbd746d` and **verified by the orchestrator** rather
  than by opening a fourth gate stage.
- **Depth: 3 serial stages** — builder; qa ‖ reviewer concurrently; fix round.
  **No stage 4.**
- **DEVIATION, RECORDED AND NOT NORMALISED: 3 commits against the `<=2` cap.** The
  fix round landed as its own commit rather than amending commits the gates had
  already measured. `df9f740` and `c76b4d0` were not squashed or rewritten.
- Suite **1964 -> 1995** (+31, **all** of it `tests/control_registry_tests.sh`
  section 28, which went 99 -> 130 standalone; **all 18 other suites +0**);
  census **100 -> 101**; declared mismatches **HELD at 21**; anchors **0 -> 13
  records over 12 declared object types**; **zero re-authorisations**.
- **THE FIRST COMPLETED PROSPECTIVE EXPERIMENT IN THIS REPOSITORY.** Ranking
  sealed `44b0fab`, selection recorded `c2d97f8` (selector: **operator**), then
  execution. Ranked **rank 1** by S1 over a candidate set nobody had chosen from,
  then selected, then executed. **Verified to the byte at close:** the S1 report
  digests to `e838284e2bba5262...`, identical to qa's independently recorded
  base-run literal; `rank_of_selected: 1` still derives; and
  `build-os/metrics/rank-candidates.sh` is the same blob `5543ea88` at the seal,
  the selection and both execution commits.
- **AND ONE SELECTED RANK IS NOT EVIDENCE OF S1 SKILL.** It is one observation, by
  a selector who had read the ordering. The true claim is narrower and worth more:
  **the first candidate S1 ranked first has now been executed and closed, so the
  ordering has begun to be falsifiable by outcome — and has not yet been
  falsified.**

## THE DEFECT THIS FILE ITSELF COMMITTED — PRESERVED, NOT TIDIED AWAY

**FROM ITS FIRST COMMIT THIS FILE DECLARED `residue_items_closed=1`. THE SEALED
VALUE IS 2.**

**It was not a typo and it was not the builder's arithmetic: the orchestrator's
brief stated `1` and this file INHERITED it.** That is
`DEFECT-0002-stale-remembered-count`, committed **in the one artefact that
declares the sealed scope** — the place a number must be **resolved and not
remembered** — and **inside a brief whose own instruction was *"DERIVE every
count; never restate one."*** The defect class demonstrated itself one level up,
inside the packet built to end it.

**THE DERIVATION, WRITTEN DOWN SO THE NEXT READER RESOLVES IT RATHER THAN COPIES
THIS LINE:**

```
awk -F'\t' '$1=="SIGNAL-SNAPSHOT-0078-anchors-items"{print $6" = "$7}' \
  build-os/metrics/signal_snapshots.tsv
```

→ `residue_items_closed = 2`.

**THE WORK MATCHED THE SEALED 2 AND ONLY THE RESTATEMENT WAS WRONG.** Both `(mm)`
and `(nnn)` in `build-os/memory/residue.md` carry their annotations, and the
snapshot's own `evidence_refs` field names exactly those two items and says in the
same breath why `(rrr)` and `(bbbb)` were **not** counted.

**THE PROVENANCE IS RECORDED HERE RATHER THAN THE DIGIT QUIETLY OVERWRITTEN, AND
THE ARCHIVIST PRESERVED THAT CHOICE AT CLOSE.** A count that arrives by
inheritance and is repaired by overwriting leaves **no trace of how it got in**,
and **the trace is the only part of this that generalises.** The fix round
**derived** the value rather than copying the correction, and left the wrong digit
visible. Do not tidy this section away.

**The other sealed signals, resolved from the snapshot store and not remembered:**
`residue_ruling_satisfied=0`; `census_growth_controls=1`; `sealed_rank=1`
(**frontier, NOT dominant** — `PACKET-0030` and `PACKET-0031` tie at 2 on the same
frontier).

## What the packet closed, and the four things it did not

**IDENTITY IN, POSITION OUT.** Resolution is by **content**: the anchor names a
literal that must occur **exactly once** in its artifact. **The line number is a
return value of `anchor_resolve()`, computed at every resolution and stored
nowhere** — qa proved no field holds a position and that an 11-field record is
refused as `ANCHOR-SCHEMA`, so no overflow field can smuggle one in. The written
form grades its two halves separately: a wrong identity half is a **refusal**, a
stale position half is a **report with the corrected projection printed beside
it**. `anchors_check` is wired on the `check` path **outside** the `anchors`
early-exit, and **qa proved by mutation that it cannot be skipped.**

**NOT CLOSED, AND EACH REFUSAL IS DELIBERATE:**

- **The corpus.** 13 anchors against **355** still-positional `evidence_refs` —
  **3.5% coverage**. `(mm)` was re-headed *"A DOWN PAYMENT IN MECHANISM — NOT
  DISCHARGED, AND NOT MIGRATED"*. The builder refused in writing: *"converting the
  census to it would be a re-authorisation of every entry's evidence and is not a
  builder's to take."*
- **`(uuuu)` — the object-granularity convention that decides whether guard 1
  fires.** It is written down **nowhere**, and it is the difference between rank 1
  standing and the experiment being **VOID**. Deliberately open: amending guard 1's
  contract is the self-amendment guard 1 exists to prevent, and this packet is the
  candidate it screened. **This is the packet's most important governance finding.**
- **Three pre-existing defects** — `DEFECT-0001`, `DEFECT-0003`, `DEFECT-0002` —
  found inside prose this packet edited and **deliberately not fixed**. Correct
  under the ceiling: repairing defects mid-measurement is exactly the failure the
  decision arm tests for. **The irony is on the record: the anchor packet declined
  to fix three stale line references, and moved two of them a further 400 lines out
  of date.** `(vvvv)`.
- **`(ddd)` STAYS QUEUED** — verified at 3 sites. It queues a **cross-commit**
  comparison; everything this packet built resolves against the artifact **at the
  current commit**. **Do not mark it consumed.**

## Staged next — `gravito_p3b_count_derivation_a` (`PACKET-0027`)

**NOT A NEW SELECTION.** `DECISION-0010` selected
`PACKET-0027-p3b-count-derivation` at `5c8d19e`, **before S1 existed**, and that
selection stands. Its telemetry row carries `result: in_flight`. It has been
staged and unstarted since the P3 close, and **this close does not change its
status.**

**Still not started. Still the standing next packet. Declaring it is the
orchestrator's act, and this file declares nothing.**

## `DECISION-0011-p5b-next-after-p3b` — SEALED, SELECTED, EXECUTED, AND NOW CLOSED

**THE ABSENCE THAT WAS THE EVIDENCE HAS BEEN FILLED — BY AN OPERATOR, WHICH IS THE
ONLY WAY IT COULD LEGITIMATELY BE FILLED.** At the P5 close this decision had a
sealed ordering and **no row** in `decision_telemetry.tsv`, and that emptiness was
the proof that no agent had rationalised a choice into it. The operator then chose
`PACKET-0029` at `c2d97f8`, the packet executed, and **the outcome row for this
decision has now been written through the governed path** at this close.

```
excluded PACKET-0033-observe-advise-boundary-recheckable  reason=self_amendment
rank 1  PACKET-0029-citation-anchor-tokens            total=4  pareto=frontier   SELECTED, EXECUTED, CLOSED
rank 2  PACKET-0030-mutation-census-coverage-gap      total=3  tie=yes  frontier
rank 2  PACKET-0031-governance-baseline-completeness  total=3  tie=yes  frontier
rank 4  PACKET-0028-positional-content-pairing-guard  total=1  dominated_by=PACKET-0029
```

**IT IS NOT DEGENERATE — 3 of 4 rankable candidates sit on the Pareto frontier**,
against `DECISION-0010`'s single dominator that 125 of 125 weightings returned.
**Weights would change this ordering.** The candidate set is **mechanically
derivable, not curated**.

**NO RANKER-OWNED FIELD WAS WRITTEN.** `rank_of_selected`, `ranking_agreement`,
`ranker_skill`, `ranking_digest`, `counterfactual_regret` and `sealed_rank` own
**no column**, are **refused by both write paths**, and are **derived by the
ranker on demand** — because an outcome row carrying the ranker's score would let
*"the selected packet turned out well"* be read as *"the ranking was correct"*.

**AN UNKNOWN IS NOT A ZERO.** Every quantitative field written is `unknown` or
`<value>@<provenance>`. Nothing was written as `0@measured` that nobody measured;
`durability_status` is `unknown` because **no post-close audit has run**.

## Explicitly NOT staged, and deliberately open

- **`s1-v2` / any signal-set redesign.** The degeneracy, the
  lettering-granularity margin, the non-independence and the label leakage stay as
  residue `(xxx)` / `(yyy)`.
- **Widening guard 1's `PROTECTED_SURFACE`**, or writing the `(uuuu)` granularity
  convention. **Widening is NOT the remedy** — a predicate that refuses every
  subject discriminates nothing. Residue `(zzz)` / `(uuuu)`.
- **Migrating the `evidence_refs` corpus to anchors.** The mechanism exists; the
  corpus has not moved, and moving it is a re-authorisation.
- **A 22nd declared mismatch.** ~~The standing ruling: **hold at 21.**~~ **THE RULING WAS
  BROKEN AT THIS CLOSE, AND IT WAS WITHDRAWN ON EVIDENCE RATHER THAN QUIETLY EXCEEDED.** The
  count is **22**. The reviewer withdrew its own P5 ruling because `lic_of` in
  `scan-controls.sh` **tops out at rank 4 (`gate`) for Class A and no class returns 5 — no class
  licenses `execute`.** **Therefore every durable-write control this repository will ever add
  MUST declare a mismatch; there is no legal alternative, for anyone, ever**, and holding at 21
  could only have been honoured by refusing to register real durable-write surfaces. **A cap on
  the RAW TOTAL is negotiable by construction and no packet can decline it. The number that
  actually constrains anybody did not move: gate-on-advise — the heuristics that can stop a
  build — is 14 at base and 14 at HEAD.** All growth is in the `execute` bucket. **ROUTED TO THE
  OPERATOR: re-express the ceiling on the gate-on-advise subset.** Residue `(lllll)`.
- **The router's stale second-eyes counter.** It says *"the last nine"*; it is
  **THIRTEEN** as of this close — now stale by four. Nothing pins the literal. The
  remedy is one builder-lite line, and editing the router is a **routing act rather
  than bookkeeping**, so it is named and not applied for the third close running.
  `(zz)`.

## Open boundaries carried forward

- **Nothing is pushed, merged, tagged, PR'd or deployed**, and no such go has been
  given. `df9f740`, `c76b4d0` and `fbd746d` stay local pending explicit go — and so
  do `d2c09c6`, `8ba368a`, `727de75` and this close commit. **None of the four may
  be amended:** the first three are the commits the gates measured.
- **`DEFECT-0013` IS OPEN AND IS ITS OWN PACKET.** Fixing it needs a licence to edit
  `tests/speed_benchmark_tests.sh`, which the memory-kernel packet did not have and
  this close does not have. **Until it is closed, a suite total from this tree is a
  sample and not a constant.**
- **The CHANGELOG / `current_state` cross-check has no green path for a builder** on
  any total-changing packet. Either the archivist runs before the gates, or the
  cross-check reads the total from a generated file the builder owns. **The choice
  is a routing act and is the operator's.** Residue `(mmmmm)`.
- **`c2d97f8` IS THE SELECTION ANCHOR AND `44b0fab` IS THE SEAL ANCHOR. NEITHER
  MAY BE AMENDED**, and neither may the three execution commits. The whole claim of
  the prospective ordering is that the seal was committed **before any commit could
  carry a selection**.
- **THE UNPUSHED STATE CARRIES EVIDENTIARY WEIGHT.** The parent-hash chain is
  non-forgeable **only once a third party has witnessed it**, so publishing is what
  converts the seal's anchor from *"one process could rewrite this"* into *"a third
  party has seen it."* **A push would now buy something specific. It is still an
  operator act and it is not requested here.** Residue `(kkkk)`.
- **Nothing consumes S1's ordering**, and wiring anything to it is an operator act.
- **Selecting the next packet from any decision is an operator act.**
- **Second eyes: NONE — TWELFTH consecutive packet**, and the first whose verdict
  carries experimental weight: a single-model chain produced both the ranking rule
  and the verdict on the first candidate it ranked. Residue `(zz)`.

## Close record — `gravito_residue_reblock_a` (`PACKET-0037-residue-reblock`), 2026-08-03

- **Packet id (CLOSED):** `PACKET-0037-residue-reblock`. Re-checked at close, not
  accepted from the brief: the token appears in **0 files at base `2a3c070`**
  (`git grep -lF 'PACKET-0037' 2a3c070` exits 1), and `git log -S'PACKET-0037'
  --all --oneline` returns **exactly the packet's own three commits**. The mint
  preceded the build and the id was free.
- **Base `2a3c070`; HEAD at close `95e2c7b`.** Commits `bbdd85c` (declaration),
  `d888766` (migration), `95e2c7b` (fix round). **Nothing pushed, merged, tagged,
  PR'd or deployed.**
- **Verdict: PASS-AS-FIXED.** qa GREEN; reviewer `fix-then-pass`, all **7** items
  fixed in `95e2c7b` and orchestrator-verified. No fourth gate stage.
- **Receipt:** `build-os/receipts/gravito_residue_reblock_a.md`.
- **The blocker is CONVERTED, NOT CLEARED.** `residue.md` is still over
  `DEFAULT_MAX_BYTES` and **rotation has NOT been applied**; `(bbbbbb)` queues it
  for an operator. `build-os/memory/archive/` does not exist.

### Staged next — NOT DECLARED, NOT IN FLIGHT

`build-os/memory/current_state.md` is in the **identical dead end** this packet
just repaired for `residue.md`: **182,545 B in exactly 3 `^## ` blocks**, and
`rotate-memory.mjs --file current_state --keep 10` reports `keep 3 newest, would
archive 0` / `nothing — already rotated (no-op)` at **exit 0**. The instrument
reports the file as **healthy right up until it is unfixable**. Re-blocking it is
the obvious next packet; it is deliberately left **undeclared** here so this file
keeps reading **0 in flight** until a builder is actually dispatched.

## Close record — `gravito_current_state_reblock_a` (`PACKET-0038-current-state-reblock`), 2026-08-03

- **Packet id (CLOSED):** `PACKET-0038-current-state-reblock`. Re-checked at close, not accepted
  from the brief: at declaration `git log -S'PACKET-0038' --all --oneline` returned **0 commits**
  and `grep -rlF 'PACKET-0038' . --exclude-dir=.git` **0 files**; at close the token resolves to
  **exactly this packet's own three commits** and to three live records. **The mint preceded the
  build and the id was free.**
- **Base `9c740d7`; HEAD at close `d885657`.** Commits `06e9f1c` (declaration), `b41aa5d`
  (migration), `d885657` (fix round). **Nothing pushed, merged, tagged, PR'd or deployed, and no
  such go was given.** No commit squashed, amended, rebased or rewritten.
- **Verdict: PASS-AS-FIXED.** qa GREEN; reviewer `fix-then-pass` with **2** items, both closed in
  a bounded fix round together with **4 orchestrator-added corrections** — **6 record corrections,
  prose only, 2 files, +110/-6**. **No fourth gate stage.**
- **Receipt:** `build-os/receipts/gravito_current_state_reblock_a.md`.
- **What it made true:** `build-os/memory/current_state.md` went **3 -> 18** `^## ` blocks, so
  `rotate-memory --file current_state --keep 10` went from `would archive 0` /
  `nothing — already rotated (no-op)` to **8 blocks / 66332 B** archivable at exit 0. **The live
  file GREW** (185204 -> 188188 B); what changed is reachability, not size.
- **Proof:** suite **2140 passed / 0 failed** (twice at `b41aa5d`, twice solo in the fix round,
  once more by the archivist at `d885657`); **Commit-1 green in isolation at `06e9f1c`: 2121
  passed / 0 failed** in a clean clone; **+19** is `tests/build_os_maintenance_tests.sh` going
  **85 -> 104**, every other chained suite **+0**. Census **105**, declared mismatches **22**
  (anchored), gate **14** / execute **8**, **zero re-authorisations, no new control**.
  `scan-controls.sh check` and `anchors` both exit 0.
- **Deviations, recorded and NOT normalised:** **3 commits against the `<=2` cap** — the fifth
  consecutive breach. **Rotation NOT applied**; `build-os/memory/archive/` does not exist; **no
  ceiling raised.** **Second eyes NONE — seventeenth consecutive packet.**

### THIS EDIT IS LINE-COUNT-NEUTRAL ABOVE THE `ANC-0003` SITE, AGAIN AND ON PURPOSE

The committed kernel projection `build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md` embeds
`build-os/packets/active_packet.md:89#ANC-0003` as a **resolved line number**, and
`tests/memory_kernel_tests.sh` section 18 compares it with `cmp -s`. **Any close that adds a line
above `:89` turns the suite red with `PROJECTION-DIVERGED`.** So the close changed exactly two
lines **in place, one for one** — the status heading and the `**Packet id:**` marker, the latter
renamed to `**Packet id (CLOSED):**` so `bandwidth.active_packet_singleton` correctly reads **0
packets in flight against a ceiling of 1** — and **appended everything else BELOW the anchor**.
`ANC-0003` re-verified at `:89` after the edit; **no projection regeneration was required.**

### Staged next — NOT DECLARED, NOT IN FLIGHT

Two candidates are on the table and **neither is declared here**, so this file keeps reading **0
in flight** until a builder is actually dispatched:

1. **The un-run rotation, residue `(bbbbbb)` — an OPERATOR decision, not a builder's.** Both
   memory files are now one command from real relief and the command has not been given.
   Applying it relocates still-open items into an archive, which is why no packet has applied it.
2. **The `(ffffff)` choice on section 8 / section 9 duplication.** Either parameterise one helper
   by *(file, standing-heading prefix, pinned literals)*, or accept the duplication deliberately
   and cover **this file** — which is the third rotating file and has **no protection section at
   all**. Nothing currently checks that it stays fine.

## DECLARED LATE, NOW CLOSED — `gravito_governed_rotation_a` — CLOSED 2026-08-03

- **Packet id (CLOSED):** `PACKET-0039-governed-rotation` — **MINTED, and collision-checked at the mint.**
  The live band is `PACKET-0001`..`PACKET-0038` (`PACKET-9201`/`9202`/`9203`/`9299`/`9999` are
  test fixtures in `tests/mutator_registry_tests.sh` and two receipts, not allocations);
  `PACKET-0038` is the highest allocation predating this packet;
  `git log -S'PACKET-0039' --all --oneline` returns **0 commits** and
  `grep -rlF 'PACKET-0039' . --exclude-dir=.git` **0 files**.
- **Lane:** `substantive`. **Scope:** the first governed rotation of `build-os/memory/residue.md`
  (`--keep 25`, batch `2026-08-03T16:09:49Z`) plus this bounded fix round.
- **Base:** `3ec519b`, verified with `git merge-base` before the first edit. **Nothing is pushed,
  merged, tagged, PR'd or deployed by this packet, and no such go has been given.**
- **THIS DECLARATION IS APPENDED BELOW THE `ANC-0003` SITE, AND THE ONE EDIT ABOVE IT IS
  LINE-COUNT-NEUTRAL.** Exactly one line above `:89` changed — the `## CLOSED` heading, rewritten
  **in place, one for one**, to drop the now-false words `NOTHING IN FLIGHT`. Everything else is
  appended here. `ANC-0003` re-verified at `:89` after the edit; **no projection regeneration was
  required.** This is the technique this file already used twice, at its own account of it.

### `DEFECT-0011-undeclared-active-packet` — A FURTHER OCCURRENCE, AND THIS FILE STATED THE RULE

**THE BREACH.** `gravito_governed_rotation_a` was built, committed at `7bd152e`, and gated
**while this file declared `NOTHING IN FLIGHT`**. `bandwidth.active_packet_singleton` therefore
reported **ZERO in flight while the packet was in flight** — the guard passing truthfully against
a file describing the wrong state. The declaration above is the repair, and it is **late**: it
cannot make the guard's reading true for the part of the packet already executed, only for the
remainder. **That is precisely why the rule requires the declaration to be commit 1.**

**THE RULE THIS PACKET BROKE IS WRITTEN VERBATIM IN THIS FILE, AT `:15-20`, BY THE PREVIOUS
PACKET:**

> - **This commit is the declaration, and it is commit 1**, so that
>   `bandwidth.active_packet_singleton` reads **1 in flight** for the whole life
>   of this packet: no measurement taken inside a packet ABOUT a memory file may
>   be taken against a packet file lying about what is in flight.
>   `DEFECT-0011-undeclared-active-packet` sits at `OCCURRENCE-0005` and the
>   remedy it names — a LOWER bound on the same cardinality check — does not exist.

**THE AGGRAVATION IS THE SUBJECT MATTER.** That rule does not merely exist somewhere in the tree;
it is stated **in this file**, by the **immediately preceding packet**, and its stated reason is
*no measurement taken inside a packet ABOUT a memory file may be taken against a packet file lying
about what is in flight*. `gravito_governed_rotation_a` is a packet **about memory files** — it
rotated one — so it is the exact case the sentence names, and every measurement it took was taken
against a file lying about what was in flight.

**THE CLASS HAS NOW FIRED AGAINST A PREVENTION THAT WAS SPECIFIED AND NEVER BUILT.** Only the
UPPER bound on `bandwidth.active_packet_singleton` exists; the `could_have_been_prevented_by`
already names the LOWER bound — refusing zero declared packets while a build is in flight — and it
still does not exist. **Nothing is built for it here** (this fix round's ceiling is 0 new
validators), and pretending otherwise would be the fourth consecutive record of a remedy named and
not delivered.

**AN EARLIER ROUND OF THIS PACKET DECLINED TO DECLARE, REASONING THAT DECLARING WOULD MOVE THE
`ANC-0003` SITE AT `:89` AND TURN `tests/memory_kernel_tests.sh` §18 RED. THAT WAS AN EXCUSE, NOT A
CONSTRAINT, AND IT IS RECORDED AS SUCH.** The remedy was already executed **twice in this very
file** — at `:21` and again at `:716`, both headed *"THIS EDIT IS LINE-COUNT-NEUTRAL ABOVE THE
`ANC-0003` SITE ON PURPOSE"* — and `:725` records `ANC-0003` re-verified at `:89` afterwards. The
technique was documented, proven, and sitting in the file the packet was declining to edit. **A
constraint with a known, in-file, twice-executed workaround is not a constraint.**

**NO OCCURRENCE ROW IS MINTED IN `build-os/registry/defect_classes.txt`.** That store is outside
this fix round's declared file scope and the round's ceiling is 0 new stores. The next free id is
**`OCCURRENCE-0019`** (derived: `grep -c '^occurrence: '` = **18**, highest `OCCURRENCE-0018`).
**QUEUED for the archivist, and deliberately not written here as a dangling id.**

Also open and untouched by boundary: `(ddd)`, `(uuuu)`, `(ppppp)`, `(eeeeee)`'s stale pointer —
which the next packet must repoint **by content**, after re-deriving the position, because
`current_state.md` moved again at this close.

## CLOSED — `gravito_governed_rotation_a` — closed 2026-08-03 by the archivist. NOTHING IN FLIGHT.

- **Packet id (CLOSED):** `PACKET-0039-governed-rotation`. **Re-derived at close, not accepted from
  the brief:** at declaration `git log -S'PACKET-0039' --all --oneline` returned **0 commits** and
  `grep -rlF 'PACKET-0039' . --exclude-dir=.git` **0 files**; at close the token resolves to this
  packet's own records. **The mint preceded the build and the id was free.**
- **Base `3ec519b`; HEAD at close `8115ac4`. Commits `7bd152e` (the rotation) + `8115ac4` (the fix
  round) — TWO, INSIDE THE `<=2` CAP, FOR THE FIRST TIME IN SIX CLOSES.** The four preceding closes
  each ran to three and each recorded the breach. `git rev-list --count 3ec519b..HEAD` = **2**.
  **Recorded as a measurement, not as a compliment.** No commit squashed, amended, rebased or
  rewritten. **Nothing pushed, merged, tagged, PR'd or deployed, and no such go was given.**
- **Verdict: PASS-AS-FIXED.** qa **RED on one claim** (backlinks) — **disposition right, warrant
  wrong** — and GREEN on everything else, independently reproduced; reviewer `fix-then-pass` with
  **10** items, all landed in `8115ac4`; **no stage 4.** **Second eyes: NONE — eighteenth
  consecutive packet** (`command -v codex` exits 1).
- **Receipt:** `build-os/receipts/gravito_governed_rotation_a.md`.
- **What it made true:** the **first governed rotation in this repository's history**.
  `build-os/memory/residue.md` **218062 -> 191805 B** — from **13262 B OVER** the **204800 B**
  ceiling to **12995 B UNDER** it; `build-os/memory/archive/` **created**; `block_26`..`block_29`
  archived (**26762 B**, all `## History`, anchors (a)-(n)); **26257 B reclaimed**, the 505 B
  difference being the archive-pointer banner. **Reversible, and proven so by an agent other than
  the one that performed it** — the reviewer re-derived the restoration to `sha256 1977817f...`,
  which is the base blob at `3ec519b`. **The cut was DERIVED, not chosen**: *archive every block
  older than the oldest still-open item* → `--keep 25`, bounded by two executed constraints
  (`--keep 27` refuses at `EXIT.CEILING`; section 8 needs `keep >= 16`). Recorded as `(iiiiii)`.
- **The finding that outranks the rotation:** **the true count of citation breaks this packet caused
  is ZERO**, and three instruments each reported a different non-zero answer (qa 1 by semantics,
  reviewer 2 positionally, orchestrator 31 mechanically). **The builder falsified the premise and
  refused to execute the routed repoint** — the only reason a knowingly false claim did not enter
  memory. `DEFECT-0001-stale-line-reference` / *resolvability is not identity*, at residue
  `(hhhhhh)`.
- **Proof:** suite **2140 passed / 0 failed** — twice in the packet, twice solo in the fix round,
  once more by the archivist after every write in this close; **20-line chained verdict vector
  byte-identical to the pre-rotation baseline**. **Commit-1 green in isolation at `7bd152e`:
  2140 / 0**, re-derived in a clean clone. Census **105**, declared **22**, gate **14** / execute
  **8**, occurrences **18**, **zero re-authorisations, no new control**; `scan-controls.sh check`
  and `anchors` both exit 0; ceiling **0 / 0 / 0 / 0**.
- **Deviations and open items, recorded and NOT normalised:** the `--apply` **ordering is testimony,
  not tree-verifiable** (mitigation is proven reversibility; remedy is pre-registration).
  `DEFECT-0011-undeclared-active-packet` fired again and the packet was declared **late**;
  `OCCURRENCE-0019` derived and **queued, not minted**.
  `DEFECT-0014-retention-order-assumed-not-verified` **stays open** and names
  `build-os/memory/current_state.md` as the next file it bites.

### THE BRANCH BASE SECTION ABOVE WAS STALE, AND AN INSTRUMENT WAS READING IT

`build-os/tools/bandwidth-check.sh` derives its commit count from the **FIRST** `## Branch base`
section of this file. That section still named `9c740d7` — the base of the **previous, already
closed** packet — so `bandwidth-check.sh check` reported `commits EXCEEDED — 6 commits since the
declared base 9c740d7` for a packet whose real count against its real base is **2**. **The
instrument that measures the working contract was reading a field belonging to a closed packet.**
**That section sits ABOVE the `ANC-0003` site, so the repair had to be line-count-neutral, and it
is: four lines of prose replaced by four, in place, naming `3ec519b`.** After the repair the same
command reports `commits OK — 2 commit(s) since the declared base 3ec519b`.

**NOTHING FORCES THAT SECTION TO BE REWRITTEN AT A DECLARATION, SO IT WILL GO STALE AGAIN.** No
guard is added here (this close builds nothing). Recorded in residue `(jjjjjj)` so the next
declaration inherits the hazard rather than rediscovering it.

### THIS CLOSE'S EDITS ARE LINE-COUNT-NEUTRAL ABOVE THE `ANC-0003` SITE, AS ALWAYS

`build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md` embeds
`build-os/packets/active_packet.md:89#ANC-0003` as a **resolved line number**, and
`tests/memory_kernel_tests.sh` section 18 compares it with `cmp -s`. This close changed **four lines
in place, one for one**, above `:89` (the branch-base prose), renamed the `**Packet id:**` marker to
`**Packet id (CLOSED):**` and the section heading **below** `:89`, and **appended everything else at
the end of the file**. `ANC-0003` re-verified resolving at `build-os/packets/active_packet.md:89`
after the edits, by `scan-controls.sh anchors`; **no projection regeneration was required.**

## Staged next after the 2026-08-03 rotation close — NOT DECLARED, NOT IN FLIGHT

**Nothing is declared here, so this file reads 0 packets in flight against a ceiling of 1.** The
candidates, in the order the evidence puts them:

1. **ROTATE BEFORE WRITING. This is now the first act of whichever packet comes next.** Both memory
   files sit within ~2.5 KB of the 204800 B ceiling at this close — `residue.md` after taking this
   close's terse entry, `current_state.md` after taking its detail. **DERIVE both sizes; do not
   quote a figure from anywhere.** The rule for the cut already exists as prose in residue
   `(iiiiii)`. **A packet that writes into either file without rotating first will breach the
   ceiling it was handed.**
2. **Build the retention guard that `DEFECT-0014` names.** Nothing executable asserts that the
   retained prefix contains every still-open item; the scan is MANUAL. Natural home is
   `tests/build_os_maintenance_tests.sh` section 8 — but `(ffffff)`'s open choice about the
   section 8 / section 9 duplication **should be settled first**, or the guard becomes a fourth
   clone.
3. **Pre-registration for `--apply`.** Commit the intended `--keep`, the predicted byte deltas and
   the expected refusals **before** running it, so ordering stops being testimony.
4. **The LOWER bound on `bandwidth.active_packet_singleton`** — refuse zero declared packets while a
   build is in flight. Named by `DEFECT-0011`'s `could_have_been_prevented_by` at four consecutive
   closes now, and still not built. **Mint `OCCURRENCE-0019` when it is.**
5. **`(eeeeee)`'s stale pointer** — repoint **by content**, after re-deriving the position, because
   `current_state.md` moved again at this close. **Do not sweep it mechanically**; that is the
   defect this packet just recorded.

Also open and untouched by boundary: `(ddd)`, `(uuuu)`, `(ppppp)`. Still NONE: second eyes, now
**eighteen** consecutive packets, while `build-os/memory/tool_router.md:368` self-reports **"nine"**.

## DECLARED AND IN FLIGHT — `gravito_rotation_sentinel_guard_a`

- **Packet id:** `PACKET-0040-rotation-sentinel-guard` — **MINTED, collision-checked BEFORE the
  mint.** The live band is `PACKET-0001`..`PACKET-0039`; `git log -S'PACKET-0040' --all --oneline`
  returns **0** commits and `grep -rlF 'PACKET-0040' . --exclude-dir=.git` **0** files.
- **Lane:** `substantive`. **Depth 2** — builder, then qa ‖ reviewer.
- **THIS DECLARATION IS APPENDED AT THE TAIL, NOT WRITTEN AT THE HEAD, AND THAT IS DELIBERATE.**
  `build-os/packets/active_packet.md:89` is the content site `ANC-0003` resolves to and
  `tests/memory_kernel_tests.sh` §18 compares the committed projection with `cmp -s`. An append
  moves no line at or above 89. The COST is stated rather than hidden: the FIRST `## Branch base`
  section in this file still belongs to a CLOSED packet, so `bandwidth-check.sh`'s `commits`
  dimension keeps reading a closed packet's base — residue `(jjjjjj)`'s instrument defect, unfixed
  here because it is out of this packet's declared scope and the dimension is `advise`, not a gate.
- **This packet is NOT recorded in `build-os/memory/residue.md`, ON PURPOSE.** That file has
  **431 B** of headroom against the 204800 B ceiling at base `188472f` (derive it:
  `echo $(( 204800 - $(wc -c < build-os/memory/residue.md) ))`). It cannot absorb a declaration,
  and — as this packet's own guard then proves — it cannot be rotated to make room either.

## Branch base — `gravito_rotation_sentinel_guard_a`

Branched at `188472f` on `claude/project-handoff-merge-ramhds`, verified with
`git merge-base HEAD 188472f` → `188472f`, **before the first edit**, with
`git status --porcelain` empty and `origin/claude/project-handoff-merge-ramhds` at the same commit.
**Nothing is pushed, merged, tagged, PR'd or deployed by this packet, and no such go has been
given.** The two commits this packet is permitted are BOTH local.

## What `gravito_rotation_sentinel_guard_a` must make true

**THE SUCCESS CONDITION, operator-stated:** *future rotations no longer require a human to
rediscover the safe keep value.* Rotation #1 was safe because a human hand-derived `--keep 25`;
this packet converts that act into a runtime capability.

1. **A ROTATION SENTINEL, inside `build-os/maintenance/rotate-memory.mjs`** — not a new tool.
   It derives `minimum_safe_keep = max( block position of every protected or still-open object )`
   and REFUSES any requested `--keep` below it, BEFORE any mutation.
2. **Identity, not literal matching.** Objects are resolved through stable identity families
   (`DECISION-`, `DEFECT-`, `OCCURRENCE-`, `PACKET-`, `SIGNAL-SNAPSHOT-`, `ANC-`, `EV-`, `DISP-`,
   `MUT-`, and the kernel `ACT/ART/CTX/EVT/HOF/NS/OBJ/REL-NNNN` families) plus this tree's own
   letter-tag family `(a)`..`(zzzzzz)`/`(S1)`. **An identity a protection marker names and the
   scan cannot resolve is a REFUSAL, not a skip.**
3. **Seven report fields for every proposed rotation:** `requested_keep`, `minimum_safe_keep`,
   `protected_object_ids`, `protected_block_positions`, `blocks_to_archive`, `bytes_to_reclaim`,
   `post_rotation_headroom`.
4. **Seven refusal conditions**, each driven by an executed fixture.
5. **THE RED-DRIVEN FIXTURE, operator-named:** `--keep 10 --apply` over this repository's live
   `residue.md` must REFUSE. It sat queued in the tree and would have archived blocks 11–25,
   among them block 16 (`(ddd)`, marked *"IS NOT CONSUMED AND MUST NOT BE MARKED SO"*) and
   block 25 (`(S1)` and the flake marked `[STILL OPEN AND STILL UNDIAGNOSABLE]`).
6. **Rotation #2 executed under the guard**, pre-registered BEFORE the apply and anchored in the
   tree so the ordering is checkable from git rather than from builder testimony — the one thing
   rotation #1 could not attest.

## Ceiling — `gravito_rotation_sentinel_guard_a`

**The operator authorised this guard and nothing else.** 0 new tools, 0 new stores, 0 new
validators, 0 new suite files, 0 new governance primitives, 0 new census controls.
`DEFAULT_MAX_BYTES` is **NOT** raised. Rotation #1's archived bytes are **NOT** rewritten.
Out of bounds: `build-os/metrics/rank-candidates.sh`, `decision_telemetry.tsv`,
`signal_snapshots.tsv`, `build-os/memory/standing_gates.md`.

## PRE-REGISTRATION OF ROTATION #2 — WRITTEN AND COMMITTED BEFORE THE APPLY

**THIS SECTION IS THE THING ROTATION #1 DID NOT HAVE.** Rotation #1's ordering was builder
attestation only: the receipt's mtime postdated the apply, so nothing in the tree could show the
intent predated the mutation. This record lands in **commit 1**; the apply lands in **commit 2**.
`git log --format=%H -- build-os/packets/active_packet.md` and
`git log --format=%H -- build-os/memory/current_state.md` therefore order the two from the tree.

The machine-readable copy the guard itself reads is
`build-os/memory/archive/PRE-REGISTRATION-rotation-2.json`, committed in the same commit as this
section. `--apply` over a file carrying protected objects REFUSES unless that record is present
and matches the run on every field, including the **sha256 of the source file as it stood when
the registration was written**.

- **Target:** `build-os/memory/current_state.md` — and it is the ONLY target.
- **`build-os/memory/residue.md` IS NOT ROTATED, AND THE GUARD IS WHY.** Its
  `minimum_safe_keep` is **25** and it carries exactly **25** blocks, so the only keep the
  sentinel permits archives **nothing**. The file is already at its safe floor; rotation #1 put
  it there. This is reported, not worked around: the guard is not weakened to make a rotation fit.
- **`requested_keep`: 15.** It is chosen inside the window three independent bounds leave, and
  the window is stated so the choice is auditable rather than incidental:
  - **floor from the sentinel:** `minimum_safe_keep` = **3**;
  - **floor from `tests/build_os_maintenance_tests.sh` §9(a)/(b)/(c):** the post-rotation file
    must keep **more than 10** blocks and a subsequent `--keep 10` must still reclaim
    **>= 40960 B**, which needs `requested_keep >= 14`;
  - **ceiling from refusal condition 7:** `post_rotation_headroom` must cover the close budget
    (**18702 B**, derived below), which needs `requested_keep <= 17`.
  - **The window is [14, 17]. 15 is taken**, leaving 11835 B of margin over the §9 reclaim floor
    and 20112 B over the close budget. 14 would reclaim 9253 B more and leave only 2582 B of
    §9 margin — too thin to survive the next close's block insertion.
- **Predicted, and to be checked against the tool's own report rather than restated from it:**
  `blocks_to_archive` = **5** (blocks 16..20), `bytes_to_reclaim` = **37548 B**,
  live size **203028 B -> 165986 B** (165480 B retained content + 506 B banner),
  `post_rotation_headroom` = **38814 B**.
- **Expected refusals, pre-registered so they cannot be discovered and then narrated as intended:**
  `--keep 2` REFUSES (below `minimum_safe_keep` 3); `--keep 18` REFUSES (condition 7, headroom
  15398 B < 18702 B); `--keep 15 --apply` with no pre-registration REFUSES (condition 5).
- **THE CLOSE BUDGET IS DERIVED, NOT INVENTED: 18702 B.** It is the largest single-commit growth
  any file in `FILE_SPECS` has ever taken in this repository — `build-os/memory/current_state.md`
  at `2a3c070` (`181818 - 163116`). Re-derive it, do not trust this digit:
  `git log --format=%H -- <path>` then differencing `git cat-file -s` across each pair. Measured
  over all history at base `188472f`: `current_state.md` 62 commits / max **+18702**,
  `residue.md` 61 commits / max **+13763**, `active_packet.md` 39 commits / max **+8257**.
  It is overridable with `--close-budget N`.

## THE RESIDUE FINDING, RECORDED HERE BECAUSE RESIDUE CANNOT HOLD IT

`build-os/memory/residue.md` has **431 B** of headroom and the guard proves it has **no rotation
path to more**: its `minimum_safe_keep` is 25 of 25 blocks, because block 25 holds `(o)` (the
flake, `[STILL OPEN AND STILL UNDIAGNOSABLE]`) and `(S1)` (an unresolved operator decision), and
block 16 holds `(ddd)`. **The next writer of that file cannot rotate its way out.** The two
things that WOULD move it are both operator acts, and neither is taken here: close `(o)`/`(S1)`,
or move the still-open items to the head of the file so the tail becomes archivable.

**AND THE IDENTITY MECHANISM IS WHAT MAKES THAT NUMBER RIGHT, MEASURED IN THIS TREE:** the
`IS NOT CONSUMED AND MUST NOT BE MARKED SO` marker for `(ddd)` occurs at `residue.md` line 1648,
which is inside **block 15** — while `(ddd)` is DECLARED at line 1711, inside **block 16**. A
positional marker scan derives 15 and archives the object it was built to protect. Only identity
resolution derives 16. That is this tree's named recurring defect class — *positional shift
mistaken for semantic identity* — and the guard exists precisely to not commit it.

## ROTATION #2 — EXECUTED, batch `2026-08-03T19:53:21Z`

**Receipt:** `build-os/memory/archive/ROTATION-RECEIPT-2026-08-03T19-53-21Z.md`. The figures live
there; what is recorded here is the reconciliation against the PRE-REGISTRATION above, because a
prediction nobody checks afterwards is a narration.

| pre-registered | measured | verdict |
|---|---|---|
| `blocks_to_archive` 5 | **5** (blocks 16..20) | exact |
| `bytes_to_reclaim` 37548 B | **37548 B** | exact |
| `minimum_safe_keep` 3 | **3** | exact |
| `post_rotation_headroom` 38814 B | **38195 B** | **619 B LOW, and the cause is named** |
| live size 203028 -> 165986 B | **203642 -> 166605 B** | same 619 B |

**THE 619 B ARE ACCOUNTED FOR, NOT ROUNDED AWAY:** the prediction was taken at base `188472f`;
commit 1 then added **614 B** to block 1 of `current_state.md` (the suite-total claim moving
2140 -> 2179), and the rendered banner came out **511 B** rather than the 506 B the prediction
assumed, because its interpolated decimals are wider. 614 + 5 = 619. The prediction was made
against a file the packet itself then changed — which is `(cccccc)`'s standing rule about this
tree's memory files happening once more, inside the packet that predicted it.

**The three pre-registered EXPECTED REFUSALS all fired, on a scratch copy, before the apply:**
`--keep 2` at `SENTINEL-C1` (below the floor of 3) and `SENTINEL-C3`; `--keep 18` at
`SENTINEL-C7` (14779 B of projected headroom against the 18702 B close budget — the predicted
figure was 15398 B, the same 619 B); `--keep 15 --apply` with no `--pre-registration` at
`SENTINEL-C5`. Every one wrote nothing and left the copy byte-identical.

**`build-os/memory/residue.md` WAS NOT ROTATED, AND THAT IS THE GUARD WORKING RATHER THAN
FAILING.** `minimum_safe_keep` 25 against 25 blocks. It stays at **431 B** of headroom. The next
writer of that file has no rotation path to more, and the remedy is an operator act — see the
receipt.

## FIX ROUND — CORRECTIONS, WRITTEN AS LATER RECORDS

**NOTHING BELOW EDITS AN EARLIER RECORD.** Two commit messages (`3a590ed`, `89b261b`) and one
immutable receipt carry figures and a claim that are wrong. They are corrected HERE, by a later
record, because a commit message cannot be rewritten without rewriting history and a receipt that
declares itself immutable is worth nothing if its author edits it when it becomes inconvenient.

### C-1. THE OVERSTATED CLAIM — this packet's own thesis, overstated, and it is this packet's own defect class

**WHAT WAS CLAIMED**, in the "THE RESIDUE FINDING" section above and, in the same words, in
`3a590ed`'s commit message:

> a positional marker scan derives 15 and archives the object it was built to protect

**WHAT IS TRUE, MEASURED BY EXECUTING THE COUNTERFACTUAL THAT WAS NEVER EXECUTED.** A purely
positional scan — every marker anchored at its own block, nothing resolved by identity — over the
whole of `build-os/memory/residue.md` derives a floor of **25**, not 15. The markers at
`residue.md:2333` (`[STILL OPEN AND STILL UNDIAGNOSABLE]`, `(o)`) and `:2339` (`OPERATOR DECISION`,
`(S1)`) sit in **block 25 themselves**, so the positional maximum is 25 whatever happens to
`(ddd)`. **On this tree a positional scan would refuse `--keep 10` identically, and would NOT
archive `(ddd)` at exit 0.** Re-derive it; do not take this paragraph's word for it either.

**THE TRUE, NARROWER CLAIM, WHICH IS THE ONE THE EVIDENCE SUPPORTS:** identity resolution is what
makes **`(ddd)` resolve to block 16 — its declaration — rather than block 15, where its marker
sits**. That is a fact about one object's resolved position, it is proven by the discriminating
fixture in `tests/build_os_maintenance_tests.sh` §10(b) (which re-derives both blocks from the live
file rather than quoting them) and by mutation M1 killing 2 tests, and it is **not** the claim that
identity resolution is what saves `(ddd)` from the archive on this particular tree. It is not.
What saves `(ddd)` here is that two other objects sit deeper. The mechanism's value is that it does
not DEPEND on that accident — on a tree whose deepest marker sat above the deepest declaration,
positional and identity would diverge and only identity would be right. That is a statement about
robustness, not about a harm demonstrated here.

**THIS IS THE PACKET'S OWN DEFECT CLASS, COMMITTED INSIDE THE GUARD BUILT TO PREVENT IT.** The
class is *a counterfactual asserted as a measured result* — the same shape as three instruments
reporting 1 / 2 / 31 citation breaks when the true count was 0. The guard's own source comment is
honest about exactly this distinction for the REJECTED `awaiting explicit go` marker ("WHAT IT
COSTS, STATED RATHER THAN GLOSSED: nothing measurable on this tree"). The claim corrected here was
not held to that standard, in the same file, in the same packet.

**PROVENANCE, RECORDED RATHER THAN QUIETLY NARROWED:** the builder wrote it; it went into
`3a590ed`'s commit message, where it is now immutable; and **the orchestrator repeated it to the
operator**. Three surfaces carried an unexecuted counterfactual as a measured result before a gate
executed it. The gate that caught it was qa, running the counterfactual rather than reading the
claim — which is the only thing that would have caught it at any of the three earlier points.

### C-2. TWO WRONG DIGITS IN AN IMMUTABLE RECEIPT

`build-os/memory/archive/ROTATION-RECEIPT-2026-08-03T19-53-21Z.md` is **not edited**. Its body
stands as written; these are its corrections.

- **`:102` "its 26763 B archived payload".** The conserved payload is **26762 B**. 26763 B is the
  length of the archive BODY REGION, which includes one trailing newline the archive writer appends
  and which is not part of the source. Derived: `bodyRegion.slice(0, 26762)` is a byte-exact
  substring of `residue.md` at `3ec519b`; `slice(0, 26763)` is not. Rotation #1's own receipt
  records **26762** in six places, including its executable restore recipe
  (`const ARCHIVED_BYTES = 26762;`). **`89b261b`'s commit message carries the same wrong digit.**
  Nothing about the round-trip proof changes — the payload still reconstructs byte-exact — only the
  figure quoted for it.
- **`:100` "Batch 1's 15 rows are still rows 1..15".** Batch 1 has **4 rows**, one per archived
  block (`block_26..block_29`, and the archive's own batch header says `(4)`). `INDEX.md` holds
  **9** rows total: 4 + 5. The append-only property the sentence was about is true and was proved
  byte-exactly; only the count was invented.

### C-3. TWO SPEC REVISIONS, RECORDED AND NOT BUILT

Both are out of this packet's ceiling and each needs its own cut and an operator decision. They are
written down so the next rotation inherits a decision to make rather than a surprise.

1. **CROSS-FILE IDENTITY RESOLUTION for refusal condition 2.** The scan is single-file scoped, so
   an object that lives in another memory file or a registry and is only CITED here is
   indistinguishable from one that has gone missing, and both refuse. That assumption produces
   **both** live C2 hits: `DEFECT-0014` (class record in `build-os/registry/defect_classes.txt`,
   cited in `residue.md`) and `(S1)` (declared in `residue.md`, cited in `active_packet.md`).
   Widening "resolve" to span files changes what the rule MEANS, which makes it a spec revision.
   The limitation is now stated where the rule is stated, in `rotate-memory.mjs`.
2. **DISTINGUISHING A LIVE MARKER FROM A QUOTED ONE.** A sentence quoting `[STILL OPEN ...]` to
   describe an object arms the scan exactly as the object's own status tag does. This is why
   `active_packet.md` became unrotatable the moment this packet's declaration cited `(S1)` and
   `(ddd)`. Also a spec revision.

### C-4. THE COMMIT CAP WAS BREACHED, AND IT IS RECORDED PLAINLY

The working contract allows **<=2 commits per packet**. This packet has **3**: `3a590ed` (guard +
tests + pre-registration), `89b261b` (rotation #2), and this fix round. **The third exists because
the reviewer returned a bounded `fix-then-pass` list and the two earlier commits are the pushed
tip's descendants that must not be rewritten** — squashing or amending either would destroy the
very ordering evidence the pre-registration exists to provide, and `89b261b`'s ordering proof rests
on `3a590ed` being a distinct ancestor commit. **The cap is breached; it is not excused.** It is
the fifth close running to breach it (residue `(dddddd)` records four), and this one at least has a
stated cause rather than a discovered one.


## CLOSED — `gravito_rotation_sentinel_guard_a` — closed 2026-08-03 by the archivist. NOTHING IN FLIGHT.

**APPENDED AT THE TAIL, NOT WRITTEN AT THE HEAD, for the reason this packet's own declaration
gives above: line 89 is the content site `ANC-0003` resolves to and the kernel suite compares the
committed projection with `cmp -s`. An append moves no line at or above 89.**

- **Packet id:** `PACKET-0040-rotation-sentinel-guard`. **Lane:** `substantive`. **Depth 3** —
  builder, then qa and reviewer CONCURRENTLY, then one bounded fix round. The declaration above
  said Depth 2; **the third stage was spent and is recorded rather than back-dated.**
- **Base `188472f`** (the pushed tip), verified by `git merge-base` before the first edit.
  **HEAD at close `275ea3a`.** **Commits: `3a590ed`, `89b261b`, `275ea3a` — THREE, against a cap
  of two; see C-4 above, which recorded the breach while the packet was still in flight.**
- **Verdict: PASS-AS-FIXED.** qa **GREEN** (2179/0 twice at `89b261b`, vectors identical; base
  `188472f` 2140/0; commit-1 `3a590ed` **green in isolation at 2179/0**; both archive batches
  round-trip byte-exact; `SC_FIRED==7`, `SC_BAD==0`; live-suite gate 44/0). Reviewer
  `fix-then-pass`, **4** items, all landed, plus qa's F1-F5. Fix round: **2190/0 twice solo,
  vectors identical**, the whole +50 for the packet in one suite file (104 -> 143 -> 154).
  **Second eyes: NONE — `codex` not on PATH, review was same-model. Nineteenth consecutive packet.**
- **THE SUCCESS CONDITION IS MET.** Rotation is a governed runtime capability: the tool derives
  `minimum_safe_keep` itself (25 / 30 / 3) and refuses any `--keep` below it, printing the floor on
  every run. Rotation #2 executed under it: `current_state.md` 203642 -> 166605 B, 37037 B
  reclaimed, 20 -> 15 blocks. Pre-registration is **tree-verifiable** — `3a590ed` is a proven
  ancestor of `89b261b` and the declared `sourceSha256 91fa4548...` matches the file at `3a590ed`
  exactly. Ceiling held: **0 new tools / stores / validators / suite files / primitives / controls
  / mutators.**
- **THE FULL CLOSE RECORD is `build-os/receipts/gravito_rotation_sentinel_guard_a.md`** — the
  provenance chain on the overstated positional-scan claim, the M4/M5 mutation results, the
  file-ownership manifest for the three commits, the two corrected receipt digits, and the two spec
  revisions routed to the operator. The summary is the newest history block in
  `build-os/memory/current_state.md`. **Neither of them is in `build-os/memory/residue.md`, which
  is frozen at 431 B and provably unrotatable at every legal keep.**
- **NOTHING IS STAGED NEXT.** The two spec revisions are the operator's to cut, and neither is
  declared here. **NOTHING IS IN FLIGHT.**
- **OPEN BOUNDARY:** all three commits and the close commit are **LOCAL AND UNPUSHED**. `188472f`
  is the pushed tip and push was authorised only through it. No push, merge, PR, tag, deploy,
  secret, `git config`, amend or rebase was performed, and no such go has been given.

## DECLARED AND BUILT — `gravito_p3b_count_derivation_a` (`PACKET-0041-count-derivation`), 2026-08-03

- **Packet id:** `PACKET-0041-count-derivation` — **MINTED, collision-checked BEFORE the mint.**
  The live band is `PACKET-0001`..`PACKET-0040`; at the base commit `099d7bf`,
  `git grep -lF 'PACKET-0041' 099d7bf` returns **0 files** and the only commit in
  `git log -S'PACKET-0041' --all` is this packet's own `a714d8a`. **Re-derived after commit 1,
  not accepted from the brief.**
- **Lane:** `substantive`. **Depth 2** — builder, then qa ‖ reviewer.
- **THIS DECLARATION IS APPENDED BELOW LINE 89 ON PURPOSE.** `ANC-0003` resolves at
  `build-os/packets/active_packet.md:89`, and `build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md:64`
  embeds that resolved line number in a projection `tests/memory_kernel_tests.sh` §18 compares
  with `cmp -s`. Appending moves nothing above the anchor site, so no projection needs
  regenerating and `DEFECT-0001-stale-line-reference` does not fire here. **This is the
  declaration arriving LATE — after commit 1, not before it — which is
  `DEFECT-0011-undeclared-active-packet` recurring, and it is recorded rather than excused.**
- **Branch base:** `099d7bf` on `claude/project-handoff-merge-ramhds`, verified with
  `git merge-base HEAD 188472f` → `188472f` **before the first edit**; `188472f` is the pushed
  tip and the four commits above it, plus both of this packet's, are **LOCAL AND UNPUSHED**.
  **Nothing was pushed, merged, tagged, PR'd, deployed, and no secret or `git config` was
  touched. No such go was given and none was asked for.**

### What it had to make true, and what it does

**Make count derivation MECHANICAL rather than DISCIPLINARY.** `scan-controls.sh counts` —
a COUNT-TABLE inside `build-os/registry/scan-controls.sh`, modelled line for line on the
ANCHOR-TABLE beside it. Eight fields; **the record stores no number**; the stated value is
read out of live prose and the derived value computed from the live source at every run.
Resolution is **by content**, so the reported line is a computed hint that is stored nowhere.
Two derivation kinds, `lines` (ERE that **must** begin `^`) and `files` (a name glob), and
deliberately **no line-count kind and no shell-command field**. Gates the `check` path too.

### The red fixture, EXECUTED on the live tree before the fix

    $ bash build-os/registry/scan-controls.sh counts
      COUNT-STALE  DC-0001 — build-os/memory/tool_router.md:368 states "nine" (= 9);
      deriving it from build-os/receipts with "gravito_*.md" gives 19.
    exit 2

The correction to **nineteen** was made **by that derivation**, not by hand, and the count
table was **byte-identical** across the fix — the record stores no number, so correcting the
prose did not create a second place to be wrong.

**THE COUNTERFACTUAL WAS RUN, NOT ASSERTED.** At `099d7bf`, with the stale "nine" in the
tree: the full suite was **2190 passed / 0 failed**, `scan-controls.sh check` exit **0**,
`scan-controls.sh anchors` exit **0**, and **no instrument in the repository read that count
at all**. §25 — the nearest prior art — is bespoke to `evidence_refs` and finds **0** totals
in the same document; that is executed in §29a, not argued.

### Coverage, each instance stated as EXECUTED or NOT TESTED

1. **Router's stale streak — CAUGHT, executed** on the live tree and re-driven in §29a.
2. **`wc -l` for a record count — CAUGHT, executed on a FIXTURE** (§29c: 7 lines stated over
   3 records). Not executed against `signal_snapshots.tsv`, which is do-not-touch. The
   structural claim is that no line-count kind exists, so the error is inexpressible.
3. **Unanchored vs anchored grep — CAUGHT, executed on a FIXTURE** (§29b, 5 vs 3, the same
   shape as the live 27 vs 22), and the unanchored form is refused by the schema at
   declaration time rather than caught after the fact.
4. **Suite total in `CHANGELOG.md` + `current_state.md` — NOT CAUGHT, and NOT TESTED.** No
   static derivation reaches it: the number is produced by RUNNING the suite. It stays with
   `RELEASE_METADATA_LIVE_SUITE=1`. **This packet updated that very pair — 2190 → 2220 — by
   hand, in two places, which is the defect it exists against, surviving inside its own close.**
5. **The `213,824 B` and `residue_items_closed=1` slips — NOT CAUGHT, and NOT TESTED.** Both
   were numbers in transient prose that no record binds. Nothing here discovers an
   unregistered restatement, and that limit is written into the block's own header.

### Ceiling compliance — 0 / 0 / 0 / 0

**0 new tools** (extended `scan-controls.sh`) · **0 new stores** (embedded table, same shape
and same reason as `ANCHOR_TABLE` and `EVIDENCE_VACUITY_ALLOW`) · **0 new suite files** (§29
of the existing `tests/control_registry_tests.sh`) · **0 new governance primitives** and **0
new census controls** — census holds at **105**, `DEFAULT_MAX_BYTES` untouched, declared
mismatches **22** anchored, re-authorisations **0**.

### CONSEQUENCE THE ARCHIVIST MUST ACT ON, STATED BEFORE IT BITES

Writing `build-os/receipts/gravito_p3b_count_derivation_a.md` makes the receipt store
**twenty**, and `DC-0001` will then refuse at exit 2 until `tool_router.md` says **twenty**.
**That is the mechanism working, not a defect:** the close can no longer leave the
second-eyes streak stale in silence, which is exactly the failure this packet was cut for.
`twenty` is inside the cardinal table, so the fix is a one-word prose edit.

### RESIDUE — HELD HERE BECAUSE `residue.md` IS FROZEN

**This placement is DISPLACEMENT FORCED BY A FROZEN FILE, NOT A CHOICE.**
`build-os/memory/residue.md` has **431 B** of headroom and is provably unrotatable at every
legal `--keep` — all 25 of 25 blocks exit 7 under the sentinel — so unfreezing it is an
**operator act and not a builder's**. Not one byte was written to it; its blob is unchanged.

- **(a)** Instance 4 is **unmechanised and unmechanisable by this design**: two copies of the
  suite total, reconciled only under an opt-in env var. A `mirror` kind — site A must equal
  site B, with no derivation at all — would bind it, and was **deliberately not built**
  because no executed fixture in instances 1–3 justifies the kind.
- **(b)** The counts block is a **gating control living inside an already-registered file**,
  which is `README.md` section 4's known hole number one. It has **no census entry of its
  own**, because registering it moves the census off the 105 this packet was told to hold.
  **The operator's call**, and a one-entry follow-up packet.
- **(c)** Three line-pinned citations into `tests/control_registry_tests.sh` (`:1189` →
  `:1444`, `:1193` → `:1448`, `:1194` → `:1449`) had to be repointed by content because this
  packet inserted above them. **`ANC-0012`, which covers the SAME file, absorbed the identical
  move with no edit at all.** Line-pinned citations keep costing; anchors keep not costing.
- **(d)** The cardinal table **stops at twenty**. A stated count above twenty must be a
  numeral. Fail-closed, and cheap to widen — but it is a fitted bound and is named as one.
- **(e)** Two real defects in this packet's own code were found **by its own tests, not by
  review**: an id regex too tight for fixture ids, and `rc=$?` read back after `if ! cmd`,
  which reports the status of the negation and mislabelled a `COUNT-UNANCHORED` finding as
  `COUNT-SOURCE`. The second is the exact trap the brief warns about, made in the same packet
  that quotes the warning.
- **(f)** Carried forward, untouched by this packet: `residue.md` frozen at 431 B, spec
  revisions (i) and (ii) on the rotation sentinel, `3a590ed`'s permanently false commit
  message, and the five-consecutive-closes-at-3-commits cap question.

- **OPEN BOUNDARY:** both of this packet's commits are **LOCAL AND UNPUSHED**. `188472f` is
  the pushed tip and push was authorised only through it. **NOTHING IS IN FLIGHT** once qa
  and the reviewer report.
