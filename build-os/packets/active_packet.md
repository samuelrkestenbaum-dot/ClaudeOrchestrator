# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## CLOSED — NOTHING IN FLIGHT — later record: `PACKET-0045`'s fix round re-gated, closed 2026-08-05

- **Packet id (CLOSED):** `PACKET-0045-preintegration-baseline`. **LATER RECORD:** the
  operator-ruled post-close fix round — ONE permitted fix commit `9f8630c` on the pushed
  tip `a9f44ad` — received a FULL re-gate: **Depth 4 = `mandatory_full_regate`, announced
  and satisfied; qa GREEN, reviewer PASS, ZERO fix items.** Addendum receipt:
  `build-os/receipts/gravito_preintegration_baseline_fix_a.md` — the original receipt
  body is immutable and is NOT edited; a correction creates a later record.
- **THE BENCHMARK MACHINERY IS FROZEN BY OPERATOR RULING.** No new guards, no corpus
  redesign, no prompt tuning, no new measurement fields without an actual run proving
  necessity, no derived-restatement or scanner-doctrine packet. **An instrument to run,
  not a subsystem to perfect.** Next benchmark activity = running it, or Repository Core
  integration events. The reviewer's two named bounds (`BENCH_BASH_TOOL=yes`; the
  nested-unapproved-directory blind spot) are known and left inside the freeze (§6).
- **Suite 2378 / 0** (+64 over `a9f44ad`, derived by execution, vectors identical across
  two solo runs); census **110** (forced, not padded); declared mismatches **22**;
  `DC-0001` **25 = the receipt store**, numeral moved in the same commit as the receipt.
  `residue.md` FROZEN, NOT WRITTEN (blob `01517ad2…` re-verified).
- **NEXT — NOTHING IS STAGED.** Work is at **Repository Core and live provider
  execution**. ONE operator decision remains open: Phase D's key-AND-network-policy
  gate. The backlog in `current_state.md` is a **RECORD, NOT A QUEUE**.

## Branch base

Fix-round base re-verified at this close: `git merge-base 9f8630c a9f44ad` ->
`a9f44ad`, the PUSHED TIP of `claude/project-handoff-merge-ramhds`. `9f8630c` and this
close commit are the ONLY local commits; neither may be amended, and no push/merge/PR/
tag/deploy go has been given or asked for. (Original packet base: `7fb7f41`.)

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

- **Packet id (CLOSED):** `PACKET-0040-rotation-sentinel-guard` — **MINTED, collision-checked BEFORE the
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

- **Packet id (CLOSED):** `PACKET-0040-rotation-sentinel-guard`. **Lane:** `substantive`. **Depth 3** —
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

- **Packet id (CLOSED):** `PACKET-0041-count-derivation` — **MINTED, collision-checked BEFORE the mint.**
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

### CONSEQUENCE THE ARCHIVIST MUST ACT ON — THE CLOSE IS SELF-BLOCKING

Writing `build-os/receipts/gravito_p3b_count_derivation_a.md` makes the receipt store
**twenty**, and `DC-0001` then refuses at exit 2 until `tool_router.md:368` says **twenty**.
Both gates verified the 0 → 2 → 0 transition by execution.

**IT IS NOT ONLY THE SUBCOMMAND.** `scan-controls.sh counts` exits 2, **`scan-controls.sh
check` exits 2** (the counts block gates the check path), and
**`tests/control_registry_tests.sh` fails at `:183`, `:1248`, `:1255` and `:1267`.**
**THE PROSE EDIT MUST BE IN THE SAME COMMIT AS THE RECEIPT OR THE TREE SHIPS RED.**

**That is the mechanism working, not a defect:** the close can no longer leave the
second-eyes streak stale in silence, which is exactly the failure this packet was cut for.
`twenty` is inside the cardinal table, so this close's fix is a one-word prose edit — **but
see residue (h): the NEXT one is not, and the standing form of this obligation is recorded
in `build-os/memory/current_state.md`, which outlives this file.**

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
- **(g)** **RECORDED, DELIBERATELY NOT FIXED — reviewer's explicit instruction.**
  `count_derive`'s `files` arm expands `$3` unquoted, so a whitespace-bearing glob would
  expand as two globs. **No `eval`, no injection path, and no live record does it.** Tighten
  it only if a `mirror` kind or a wider record population lands.
- **(h)** **THE CARDINAL TABLE STOPS AT TWENTY, AND RECEIPT TWENTY-ONE IS WHERE THAT BITES.**
  `twenty` reads; `twenty-one` is `COUNT-UNREADABLE` and refuses, so from then on
  `tool_router.md:368` must carry a NUMERAL. The standing form of this obligation now lives
  in `build-os/memory/current_state.md`, not here, **because this file is superseded by the
  next packet's declaration and the obligation is not.**
- **(i)** **THE FIX ROUND FOUND INSTANCE SIX INSIDE THE FIX.** `DC-0003` shipped with
  `**14 of {N} entries carrying` — a persisted, underived count inside the store that claims
  to hold none. Fail-closed, and still the defect one level up, **found by review and not by
  the guard**. The invariant is now asserted over the LIVE table in both directions. The
  lesson is not "the record was wrong"; it is that **a claim stated in a header is not a
  claim**, which is the same sentence this repository's registry header already carries.

### FIX ROUND — `Depth: 3`, reason: fix-then-pass (6 enumerated items)

qa returned **GREEN** (2220/0 twice, vectors identical, commit-1 green in isolation, 10
mutants with **zero zero-kill**). The reviewer returned **fix-then-pass, 6 items**, applied
in **ONE pass** in a **third commit — the cap of 2 is BREACHED and it is recorded here, not
excused.** The breach is structural: `a714d8a` and `f0e2fba` are the gated tree both gates
measured, and amending or squashing them would destroy the artefact the verdict was about.

1. **`DC-0003` stated_content `**14 of {N}` → `of {N}`** — instance six, removed. Executed:
   the record still resolves uniquely to `MISMATCHES.md:30` with `tok="22"`, and
   `grep -cF ' entries carrying' MISMATCHES.md` is **1**.
2. **The standing close obligation moved into `current_state.md`** — all three points,
   including that it reddens `check` and four suite assertions, that it recurs forever, and
   that receipt twenty-one onward must be a NUMERAL.
3. **The assertion that would have caught item 1**, over the **LIVE** table, executed in
   BOTH directions: clean now, and flagging the `stated_content` on the table as it shipped.
4. **Malformed-ERE fallthrough closed.** `|| true` removed, grep's exit captured directly,
   an unusable pattern refused as `COUNT-SOURCE` **and named**, plus a non-numeric guard on
   `derived`. Red-driven, with the premise (grep exit) measured rather than assumed.
5. **`local pair`** added.
6. **Suite-count restatements updated**, 2220 → **2228**, with the irony recorded in both
   `CHANGELOG.md` and `current_state.md` rather than smoothed over.

**ONE UNENUMERATED EDIT, FLAGGED RATHER THAN SLIPPED IN:** item 1's first draft moved the
`14` into `DC-0003`'s **note**, which is the same defect one field over, and `DC-0002`'s note
already carried a bare `27`. **Both notes are now digit-free and the item-3 predicate covers
the note field as well as `stated_content`.** That is broader than the enumerated ask; it is
named here so the re-review is not surprised by it. The historical figures live in the
COUNT-BLOCK header comment, which is not a record.

- **OPEN BOUNDARY:** all **three** of this packet's commits are **LOCAL AND UNPUSHED**.
  `188472f` is the pushed tip and push was authorised only through it. No push, merge, PR,
  tag, deploy, secret, `git config`, amend or rebase was performed. **NOTHING IS IN FLIGHT**
  once the re-gate reports.

## CLOSED — `gravito_p3b_count_derivation_a` (`PACKET-0041-count-derivation`) — closed 2026-08-04 by the archivist. NOTHING IN FLIGHT.

**Verdict PASS-AS-FIXED.** qa **GREEN**, reviewer **fix-then-pass (6 enumerated items)**,
re-gated. Base `099d7bf`; commits `a714d8a`, `f0e2fba`, `f785056` — **three against a cap of two,
the sixth consecutive close at three, and it is now ROUTED rather than logged again.** Receipt:
`build-os/receipts/gravito_p3b_count_derivation_a.md`. Metrics row appended and `--verify-git`
**VERIFIED**; `check-adoption.sh` exit **0**. Full close record — coverage instance by instance,
the file-ownership manifest, the escapes, the routed items — is in the receipt, which has no byte
ceiling; the durable summary is `build-os/memory/current_state.md`, newest history block.

### THE SINGLETON GATE WAS RED WHEN THIS CLOSE STARTED, AND THIS CLOSE FIXED IT

`build-os/tools/bandwidth-check.sh check` reported **`packets EXCEEDED — 3 packet ids declared,
ceiling 1`** and refused at exit 2. **That was not this packet's doing alone.** Derived from git,
not remembered:

| commit | live `- **Packet id:**` bullets |
|---|---|
| `188472f` (close of `gravito_governed_rotation_a`) | **0** — that archivist RENAMED the marker to `**Packet id (CLOSED):**`, which is the convention |
| `099d7bf` (close of `gravito_rotation_sentinel_guard_a`) | **2** — that close **ADDED** a live marker in its own close record and renamed nothing |
| `f785056` (this packet's fix round) | **3** |

**The convention is a RENAME, not a deletion**, and it is what keeps the count at exactly one
while a packet is in flight and zero when none is. All three markers are now
`**Packet id (CLOSED):**`; **the rename is line-for-line in place, so nothing above `:89` moved and
`ANC-0003` did not need repointing** (`DEFECT-0001-stale-line-reference` did not fire at this
close). The count is **0**, and `bandwidth-check.sh check` no longer refuses on the packets
dimension.

**THIS IS A FOURTH FACE OF `DEFECT-0011-undeclared-active-packet`'s ROOT CAUSE** —
`gate_permits_the_null_case`. The gate refuses two and permits zero, so nothing ever objected to a
close leaving a stale live marker behind; the count only became visible when a *third* accumulated.
Recorded in `OCCURRENCE-0019`.

### RESIDUE — HELD HERE AND IN `current_state.md` BECAUSE `residue.md` IS FROZEN

**This placement is DISPLACEMENT FORCED BY A FROZEN FILE, NOT A CHOICE.**
`build-os/memory/residue.md` has **431 B** of headroom, is provably unrotatable at every legal
`--keep`, and its blob is **`01517ad2c30d447949a98d0b6db9b8d6b538d5a9`** — byte-identical at base,
at HEAD and after this close. **Not one byte was written to it.** Unfreezing it is an operator act.

**Still open after this close, each with its owner:**

1. **INSTANCE SEVEN — word-cardinals persisted in `note` fields.** `DC-0001`'s note carries
   `"nine"` and `nineteen`; `cnt_num` parses cardinals **to twenty as numbers**, so they are
   numbers by the module's own definition. **Section 29d cannot see them: its predicate is
   DIGIT-ONLY, by the reviewer's own round-1 specification** — not a builder omission. Design
   question (a `note` is prose; prose contains cardinals). **Operator/orchestrator.**
2. **INSTANCE 4 is unmechanisable by this design** — the suite total lives in two files and is
   produced by *running* the suite. A `mirror` kind would bind it and was **deliberately not
   built**: no executed fixture in instances 1–3 justifies the kind. **And fixing instance 4's own
   guard required PERFORMING instance 4 by hand** — 2190 -> 2220 -> 2228 restated in two files.
3. **The counts block has no census entry of its own** — a gating control inside an
   already-registered file, `README.md` section 4's hole #1. Registering it moves the census off
   **105**. One-entry follow-up packet. **Operator's call.**
4. **Receipt twenty-one must carry a NUMERAL.** The cardinal table stops at twenty;
   `twenty-one` is `COUNT-UNREADABLE` and **refuses**. **This is where someone concludes the guard
   is broken and deletes `DC-0001`.** It is fail-closed by design.
5. **The standing `DC-0001` obligation lives in a ROTATING file.** `current_state.md` is in
   `rotate-memory.mjs`'s `FILE_SPECS`; `standing_gates.md` protects only lines carrying the literal
   `HARD STOP`, of which `current_state.md` has zero. Protected today by **position, not policy**.
   **The orchestrator's brief pinned `standing_gates.md` frozen, so the builder had no legal path
   to the right file** — this is the orchestrator's constraint, not a builder defect.
6. **The section 21 textual-enrolment hazard** — `tests/control_registry_tests.sh:477-478` scans
   `tests/*.sh` as TEXT including comments, so a comment explaining an avoided numeric floor
   enrols itself. Now recorded in `current_state.md` block 1; previously only in a local comment
   at `tests/control_registry_tests.sh:1470-1476`.
7. **`count_derive`'s `files` arm expands `$3` unquoted** — RECORDED AND DELIBERATELY NOT FIXED on
   the reviewer's explicit instruction. No `eval`, no injection path, no live record does it.
8. **The `<=2 commits` cap** (sixth consecutive breach; structurally unsatisfiable alongside a
   fix-round mechanic) and **the depth-4 contract gap** (a complete fix list whose contents the
   re-review rules forbid closing narrowly). Both are **rulings routed to the operator/orchestrator
   in `current_state.md`**, and the archivist did not decide either.
9. **Twentieth consecutive packet with NO second eyes** (`codex` not on `PATH`).
   `tool_router.md:368` now states **twenty**, by derivation, advanced in this close commit.

### NOT STAGED, AND DELIBERATELY NOT DECLARED

**Nothing is in flight.** The candidates above are candidates, not a queue: (1) the census entry
for the counts block, (2) a `mirror` derivation kind, (3) narrowing or widening the section 29d
predicate past digits, (4) copying the `DC-0001` obligation into `standing_gates.md` under a
`HARD STOP` line, (5) unfreezing `residue.md`. **Items (3), (4) and (5) are operator acts or
design rulings and must not be handed to a builder as a build task.** Cutting the next packet is
the orchestrator's, taken against `build-os/memory/current_state.md`, not inferred from this list.

### OPEN BOUNDARY

**All three packet commits (`a714d8a`, `f0e2fba`, `f785056`) and this close commit are LOCAL AND
UNPUSHED.** `188472f` is the pushed tip and push was authorised **only through `188472f`**. **No
push, merge, PR, tag, deploy, secret, `git config`, amend or rebase** was performed by this close,
and no such go has been given or asked for.

---

# DECLARATION — `gravito_process_doctrine_correction_a` / `PACKET-0042-process-doctrine-correction`

**Declared 2026-08-04.** Lane `substantive`, **depth 2** (builder, then qa ‖ reviewer).
Base and HEAD at declaration: `5d96031`, verified `git merge-base HEAD 5d96031` → `5d96031`
**before the first edit**. Baseline suite **2228 passed / 0 failed**, solo, after an anchored
`pgrep -fa '^bash tests/'` returned empty.

## Why this is a packet and not a text edit

The operator has **withdrawn two process rules as broken** and dictated their replacements. The
orchestrator attempted the withdrawal as a direct text edit and **broke 4 assertions across 3
suites** — `tests/gate_depth_tests.sh` (depth-block drift), `tests/control_registry_tests.sh` (×2),
`tests/bandwidth_tests.sh` (the commit-ceiling red drive inverted). That attempt was reverted. The
warrant for cutting this as a packet is exactly that finding: **this doctrine is enforced by
machinery, not merely written**, so withdrawing it means moving the machinery with it.

## CHANGE 1 — the commit-budget doctrine

**Withdrawn:** `- **≤2 commits** per packet.` (`CLAUDE.md`, `### Working contract`).
**Replaced by:** **≤2 build commits, plus at most 1 fix commit** — the old rule is withdrawn as
**unsatisfiable**, because any packet receiving `fix-then-pass` must produce a third commit (the
first two are the tree the gates measured, and amending them is forbidden). A fix commit is
produced only after the concurrent qa/reviewer stage, carries bounded corrections to defects that
stage found, and may not introduce a new subsystem, expand the objective, add unrelated
governance, rewrite the measured build commits, or conceal that correction was required. A packet
with no fix round stays capped at two. More than one fix commit is a re-cut. **The permitted fix
commit is not recorded as a doctrine breach.**

Machinery moved with it: `CEILING_COMMITS` 2 → 3 in `build-os/tools/bandwidth-check.sh`, its
header model, the `dimensions` prose, the `control_registry.txt` citations and notes for
`bandwidth.packet_commit_ceiling`, and the `tests/bandwidth_tests.sh` red drive. **`CEILING_COMMITS=3`
carries a comment stating plainly that the tool CANNOT distinguish a build commit from a fix
commit** — it counts a range and does not partition it — so 3 is the permitted MAXIMUM, not a
licence for three build commits, and the build/fix distinction is enforced by the reviewer.

## CHANGE 2 — the depth doctrine

The depth block said a fourth serial stage is a defect meaning installments or a mis-cut packet.
A **third legitimate cause** is added: `mandatory_full_regate`, applying only when all five
conditions hold (complete one-installment fix list; correctly scoped packet; fixes altering
logic/derivation/authority/counts or another load-bearing behaviour; the contract's own re-review
rules therefore forbidding targeted confirmation; a full concurrent re-gate required as a result).
Announced as `Depth: 4 — reason: mandatory_full_regate`, depth 4 is **not** a defect and is not
recorded as one. Depth 4 **remains** a defect for incomplete enumeration, fix-list installments,
avoidable scope growth, or a packet that should have been split.

**All three depth mirrors are updated in the same commit and proven byte-identical.**

## Enforcement surfaces in scope

1. `CLAUDE.md` — depth block (`BUILD-OS:DEPTH:START/END`) and `### Working contract`.
2. `build-os/global-claude-md.md` — the same two, as the global mirror of the same contract.
3. `.claude/agents/build-orchestrator.md` — the depth block mirror.
4. `build-os/tools/bandwidth-check.sh` — header model, `CEILING_COMMITS`, `dimensions` prose.
5. `build-os/registry/control_registry.txt` — `bandwidth.packet_commit_ceiling` refs + notes, and
   `bandwidth.active_packet_singleton`'s refs into the same file, repointed **by content**.
6. `tests/bandwidth_tests.sh` — the red drive re-pointed to the new boundary, not deleted.
7. `tests/gate_depth_tests.sh` — new assertions pinning the fourth-stage doctrine.
8. `CHANGELOG.md` + `build-os/memory/current_state.md` — the suite-total literal, if it moves.

## Out of scope (surfaced, NOT built)

`README.md:97,110`, `build-os/memory/tool_router.md:133`, `.claude/agents/builder.md:6,23,71`,
`.claude/agents/build-orchestrator.md:80`, `docs/ONBOARDING.md:67`,
`build-os/metrics/task_corpus.md:65`, `build-os/registry/CROSSWALK.md:147`,
`build-os/registry/neurocosmology_crosswalk.txt:132`, `templates/build-os/**` — nine derived
restatements of `≤2 commits`. They are **summaries of the contract, not the contract**, and
rewriting them is scope growth this packet's ceiling forbids. **Follow-up packet, named here so it
is not lost.**

## Ceiling

0 new tools · 0 new stores · 0 new suite files · 0 new governance primitives · 0 new controls.
`build-os/memory/residue.md` (blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, **431 B headroom**)
is **FROZEN and NOT WRITTEN**. `rank-candidates.sh`, `decision_telemetry.tsv`,
`signal_snapshots.tsv`, `standing_gates.md`, `residue.archive.md`, `build-os/memory/archive/**`
and `build-os/maintenance/rotate-memory.mjs` are untouched.

## Security envelope

**No push, merge, PR, tag, deploy, secrets, `git config`, amend, rebase or history rewrite.**
`5d96031` is the pushed tip and every commit of this packet is new, local and **NOT authorised
for push**. Repo default identity; no inline author.

---

# FIX ROUND — `PACKET-0042`, one fix commit, on top of `820fd14` + `f15356e`

**Depth: 4 — reason: `mandatory_full_regate`**, announced by the orchestrator under the clause
this packet installs. **The fix commit is the PERMITTED third commit** under `CLAUDE.md`'s new
working contract: `≤2 build commits, plus at most 1 fix commit`. **It is not a doctrine breach and
is deliberately NOT recorded as one** — logging it as an exception is the ritual the withdrawal
exists to end. `820fd14` and `f15356e` are untouched: no amend, no rebase, no squash.

## Item 1 — qa's RED: the packet caused a governance self-contradiction

`README.md:110`, under `## Safety gates (non-negotiable)`, still read
`- **≤2 commits per packet**; **Commit-1 green in isolation**.` — the exact rule `CLAUDE.md:135`
withdraws as unsatisfiable. At base `5d96031` `CLAUDE.md` and `README.md` agreed, so **this packet
caused the drift**, and the surviving copy was the operator-facing one marked non-negotiable.
Both lines now read the typed budget. **`README.md:97` moved with it**: the new guard is
content-based, `:97` asserted the same untyped cap, and a guard that passed with `:97` alive would
be a guard tuned to its own answer rather than to the rule. One file, one rule, two lines, both
line-count-neutral.

## Item 2 — the drifted registry record

`build-os/registry/control_registry.txt:1132` (`suite.bandwidth`, `notes:`) still described the
OLD fixture — *"a third commit must exit 0"* — after the diff moved the exit-0 breach to the
**four-commit** case (`tests/bandwidth_tests.sh:181-188`); the three-commit case now asserts only
that the verdict is `OK` (`:175-178`) and asserts no exit code at all. The clause's whole purpose
is showing that a **breach** only advises, so it now names the four-commit breach. The sibling
`consuming_policies` at `:977` was already correct, which is what made this an oversight rather
than a decision.

## Item 3 — the ROOT CAUSE: the guard that would have caught item 1

Item 1 drifted through a **2242-assertion green suite** because **nothing guarded the
commit-budget rule across files**. The depth block has a three-way byte-identity mirror; the
commit budget had nothing at all. That is this packet's own thesis — *doctrine enforced by
machinery, not by writing* — failing on the packet that installs it.

`tests/gate_depth_tests.sh` **section 9** (existing suite file; **0 new suite files**).

**MECHANISM, AND WHY BYTE-IDENTITY WAS THE WRONG TOOL.** The depth block is ONE canonical text
carried verbatim between sentinels, so `diff` is exactly right for it. The commit budget is not
that shape and cannot be forced into it: `CLAUDE.md` needs a paragraph plus a five-item sub-list
because the fix commit is defined by what it may NOT do; `global-claude-md.md` compresses the same
rule to one paragraph; `README.md` gives an operator one line; `bandwidth-check.sh` states it as a
shell constant that must also disclaim what the number does not mean; `control_registry.txt`
states it inside a census note arguing its own class. Byte-identity across those five is
unachievable, and forcing it would mean making five audiences read the contract's wording — the
very thing derived restatements exist to avoid. So the guard compares **the RULE, not the PROSE**:
each surface must yield the same normalised tuple **(build ceiling, fix ceiling) = (2, 1)**,
extracted from whatever words it uses. Two surfaces may disagree about every word and still pass;
they may not disagree about the rule.

**Surface list, derived rather than accepted.** GOVERNING (in the manifest, all five must carry
the typed rule): `CLAUDE.md`, `build-os/global-claude-md.md`, `README.md`,
`build-os/tools/bandwidth-check.sh`, `build-os/registry/control_registry.txt`. DERIVED (out of the
manifest, **enumerated by name inside the test** so the debt is a declared register rather than a
silent hole, and failing if a member stops resolving): `.claude/agents/builder.md`,
`.claude/agents/build-orchestrator.md`, `build-os/memory/tool_router.md`, `docs/ONBOARDING.md`,
`build-os/metrics/task_corpus.md`, `build-os/registry/CROSSWALK.md`,
`build-os/registry/neurocosmology_crosswalk.txt`, `templates/build-os/memory/tool_router.md`,
`templates/build-os/packets/active_packet.md`. **The register has NINE members.** That figure is
`${#BUDGET_DERIVED[@]}` evaluated against the shipped array at the close, not counted by eye, and
the shipped assertion prints `the 9 DERIVED restatements`. `README.md` left the SURFACED list
because it is a governing surface, not a summary; `templates/build-os/**`, written as one glob in
the out-of-scope section above, resolves to the **two** files named here, and those two facts
cancel. **The four prose lines that said EIGHT were wrong and are corrected at the close — see
the close record below and `build-os/receipts/gravito_process_doctrine_correction_a.md` §1.**

**What it asserts.** (a) the manifest is exactly the named set and every member resolves non-empty
— an IDENTITY check, deliberately not a `-ge N` length floor, because a length floor is a fitted
constant belonging to `tests.nonvacuity_minimums` and would still pass a SUBSTITUTED surface;
(b) every surface states a build ceiling and a fix allowance, **as a SET over all its statements,
never `head -1`** — a surface that disagrees with ITSELF fails before any cross-file comparison;
(c) the sets agree across surfaces at 2 and 1; (d) no surface still **asserts** the withdrawn
untyped cap — it may be QUOTED, since a withdrawal that cannot name what it withdrew is
unreadable, but only beside a withdrawal marker on the same line; (e) the two contract surfaces
must **record** the withdrawal, so deleting the old sentence cannot satisfy (d) silently.

**Red-driven in BOTH directions, executed, never asserted.** Against the pre-fix `README.md` blob
`e11d25e295c041e3cc064e63949d40ebfcc5c514` restored from `HEAD`: **108 passed, 5 failed**, the
failure naming `README.md:97` and `:110` by content. Against the fixed file: **113 passed, 0
failed**. Then validated by **mutation, 8 mutations**: the first battery exposed a **ZERO-KILL** —
`head -1` extraction let `README.md`'s second statement move to 3 while the first still read 2 —
and the guard was **hardened to set-extraction** rather than softened; the re-run kills all eight
(self-disagreement, cross-file drift both directions, a dropped fix-allowance, a re-asserted
withdrawn cap, a renamed register member, an emptied manifest surface, a shrunk manifest, a
substituted manifest). **Zero zero-kills after the hardening.**

**The census bit, and it was obeyed rather than dodged.** The first draft's `-ge 5` manifest floor
turned `tests/control_registry_tests.sh` section 21 RED as an unregistered member of
`tests.nonvacuity_minimums`. It was replaced by the identity check above — which is *stronger*, not
a workaround: `-eq 5` would have been a dodge, a named-set equality is a better assertion.

## Counts

Suite **2265 passed, 0 failed** (`tests/gate_depth_tests.sh` **90 -> 113**, +23; every other
chained suite **+0** by per-suite CHAINED VECTOR across two solo runs, `DEFECT-0013`). Packet
total from `5d96031`'s 2228: **+37** — `gate_depth` 79 -> 113, `bandwidth` 41 -> 44.
`CHANGELOG.md` and `build-os/memory/current_state.md` carry the matching `**2265 passed**` /
`2265 checks` literals; `RELEASE_METADATA_LIVE_SUITE=1` green.

## RECORDED, NOT BUILT — follow-ups this fix round deliberately did not touch

1. **`build-os/global-claude-md.md:146` drops `CLAUDE.md`'s "unless an executed reason proves the
   fixes cannot safely be combined."** A NARROWING of the rule in the safe direction — the global
   mirror is stricter than the contract, never looser — so it is recorded and left. Note the new
   guard would NOT catch this: it compares the ceiling tuple, not the escape clause.
2. **The installed user-scope `~/.claude/CLAUDE.md` still carries the withdrawn rule.** Installing
   it is **external mutation and needs an operator go**. NOT TOUCHED.
3. **`.claude/agents/reviewer.md` never mentions the commit budget**, yet the census asserts the
   reviewer enforces the build/fix split — the very split `bandwidth-check.sh` says it cannot
   partition and defers to the reviewer for. The enforcer is not told what it enforces.
4. **Depth-4 legitimacy rests on a self-assessed honour claim with no attestation in git**, and
   `bandwidth-check.sh` declines the depth dimension as transcript-only. `mandatory_full_regate`
   is therefore unfalsifiable from the repository, exactly as `active_packet_singleton`'s base is.
5. **The nine remaining derived restatements** are now a machine-checked register rather than a
   sentence, but they still state the withdrawn rule to their readers. Follow-up packet.

## Ceiling — held

0 new tools · 0 new stores · **0 new suite files** · 0 new governance primitives · 0 new controls.
Census **105**, declared mismatches **22**, re-authorisations **0**.
`build-os/memory/residue.md` **FROZEN and NOT WRITTEN** — blob
`01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, unchanged. `rank-candidates.sh`,
`decision_telemetry.tsv`, `signal_snapshots.tsv`, `standing_gates.md`, `residue.archive.md`,
`build-os/memory/archive/**` and `build-os/maintenance/rotate-memory.mjs` untouched.
**No push, merge, PR, tag, deploy, secrets, `git config`, amend or rebase.** `5d96031` is the
pushed tip.

---

## CLOSE RECORD — `gravito_process_doctrine_correction_a` (`PACKET-0042-process-doctrine-correction`) — closed 2026-08-04 by the archivist. NOTHING IN FLIGHT.

**The full record is `build-os/receipts/gravito_process_doctrine_correction_a.md`, which has no
byte ceiling. This block is the summary. `build-os/memory/residue.md` is FROZEN at 431 B of
headroom, so the residue lives in the receipt and here — DISPLACEMENT FORCED BY A FROZEN FILE, NOT
A CHOICE, and no byte ceiling was raised to avoid it.**

- **Verdict: PASS-AS-FIXED.** qa **GREEN**; reviewer **fix-then-pass, 1 enumerated item**, closed
  in the archivist's close commit rather than in a fourth commit (see below).
- **Lane `substantive`. Depth 3** — builder, then qa ‖ reviewer CONCURRENTLY, then one bounded fix
  round. **No fourth serial stage.**
- **Base `5d96031`** (the PUSHED TIP), verified with `git merge-base HEAD 5d96031` before the first
  edit. **HEAD at the verdict `9a285e6`.**

### THE COMMIT BUDGET, APPLIED TO ITSELF — AND THIS IS THE HEADLINE

`820fd14` + `f15356e` = **2 BUILD commits**; `9a285e6` = **1 FIX commit**. **THREE OF THREE, INSIDE
THE BUDGET.** `bandwidth-check.sh check` reports `commits OK, 3 commit(s) since 5d96031, ceiling 3`.

**`9a285e6` IS THE PERMITTED FIX COMMIT. IT IS NOT A BREACH AND IS NOT LOGGED AS ONE.** The
doctrine this packet installs explicitly forbids recording the permitted fix commit as a deviation;
logging it would be the withdrawn rule creeping back in through the ledger. For six consecutive
closes before this one the record carried a *"three commits against a cap of two"* line. **That line
is absent here, and its absence is the RESULT.** This packet is the **first beneficiary of its own
rule**, and the record says so.

### WHY THE REVIEWER'S ITEM WENT INTO THE CLOSE COMMIT

The orchestrator's ruling, recorded because it is load-bearing: (1) the packet stood at 3 of 3, and
a fourth commit would have been the **first breach of the rule the packet exists to install**;
(2) the doctrine's remedy for a post-fix-round finding is a **re-cut** — disproportionate for a wrong
numeral; (3) all four affected lines are **archivist-lane surfaces this close writes anyway**. It is
a decision about where the bytes land, **not** a claim that the defect was trivial.

### THE ONE FIX — AND THE IRONY, RECORDED PLAINLY

`${#BUDGET_DERIVED[@]}` at `tests/gate_depth_tests.sh:409-419` evaluates to **9**, and the shipped
assertion prints `the 9 DERIVED restatements`. **Four prose lines said EIGHT.** Corrected at this
close: `CHANGELOG.md:71` (`Eight` → `Nine`, and its own enumeration already resolved to nine —
router 1, agent definitions 2, ONBOARDING 1, corpus 1, crosswalks 2, templates 2),
`build-os/memory/current_state.md:104`, this file's `:1647`, and this file's `:1597-1598` (qa's F1 —
it asserted the register had shrunk to eight *immediately after naming nine members*).

**THE PACKET WHOSE THESIS IS `DOCTRINE ENFORCED BY MACHINERY, NOT BY WRITING` SHIPPED A
HAND-CARRIED LITERAL THAT DISAGREED WITH THE MACHINE-CHECKED ARTEFACT IT DESCRIBES.** That is
`PACKET-0041`'s exact defect class, committed by the packet arguing prose cannot hold a number. It
is the packet's most instructive result and it is written up, not smoothed over.

### THE HONEST LIMITS — FOUND BY EXECUTION, NOT BY READING

1. **THE GUARD IS TUNED TO ONE LEXICAL SPELLING, AND THE PACKET DID NOT DECLARE THAT BLIND SPOT.**
   Reviewer probes on a scratch copy: a reworded untyped cap (`"a maximum of 2 commits per packet"`
   on `README.md` **and** `"Hard ceiling of two commits per packet"` on `global-claude-md.md`) →
   **113/0, completely blind**; a **live assertion** on a line containing `no longer` → **113/0,
   FAIL-OPEN**, because `no longer` sits in `WITHDRAWN_RE`; a **paraphrased withdrawal** →
   fail-closed and loud, the correct direction. `UNTYPED_RE` catches exactly the
   `≤2 commits` / `<=2 commits` form that actually drifted — which is why it caught the real defect
   — and nothing else. **ADDED TO THE RECORDED-NOT-BUILT LIST.**
2. **THE COMMENT AT `tests/gate_depth_tests.sh:397` IS FALSE.** It claims two surfaces *"can
   disagree about every word here and still pass"*. Both extractions are **fixed lexical forms**, so
   a surface writing *"no more than 2 build commits"* **fails closed**. Fail-closed is not a defect;
   the prose overselling the abstraction is.
3. **WHAT THE GUARD DOES PROTECT, WITHOUT TRIUMPH:** the ceiling **(2, 1)** cannot silently diverge
   across the five governing surfaces, and the `≤2 commits` form cannot come back **live**. **THE
   REPOSITORY IS NOT PROTECTED AGAINST COMMIT-BUDGET DRIFT** — one guard, five hand-picked surfaces,
   an **existence-only (`-e`)** register over nine restatements it chose not to fix, and a check
   matching one spelling. **A genuine narrowing of the failure surface, not a closure of it.**
4. **LIVE PRODUCT DEBT: `templates/build-os/memory/tool_router.md:28` and
   `templates/build-os/packets/active_packet.md:35` SHIP THE WITHDRAWN RULE TO EVERY NEWLY
   SCAFFOLDED PROJECT.** Declared, deferred, correctly outside this packet's ceiling — **not closed.**
5. **THE ENFORCER IS NOT TOLD WHAT IT ENFORCES.** The census asserts the **reviewer** enforces the
   build/fix split; `bandwidth-check.sh` defers the partition to the reviewer; **`.claude/agents/reviewer.md`
   never mentions the commit budget.** In the reviewer's own words: *"Speaking as that reviewer: I
   was not told the rule I am recorded as enforcing."*
6. **qa's F2 and F3.** `build-os/registry/neurocosmology_crosswalk.txt` is a register member with
   **0** commit-budget statements — over-inclusive but harmless, since the register asserts
   resolvability only. And `current_state.md:96`, `:616`, `:618` carry the untyped-cap string while
   being in **neither** the manifest **nor** the register: historical narrative rather than rule
   assertions, so defensible — but an **UNDECLARED** exclusion, unlike `.claude/agents/*.md`.
7. **THE OUT-OF-BOUND `README.md:97` EDIT WAS CORRECT, PROVEN BY COUNTERFACTUAL.** qa built the tree
   with **only `:110`** fixed: **112 passed, 1 failed, naming `:97`.** Obeying the orchestrator's
   stated bound would have left the suite **RED**; the alternatives were weakening the guard. **The
   builder flagged the overrun rather than hiding it — recorded as the RIGHT BEHAVIOUR.**
8. **THE CENSUS REPLACEMENT IS STRICTLY STRONGER, PROVEN.** MUT-9 (a SUBSTITUTED surface) →
   identity check **KILLED**, `-ge 5` floor **SURVIVED (zero-kill)**. `-eq 5` would have been a
   dodge; this is not one.
9. **THE BUILDER FOUND A ZERO-KILL IN ITS OWN GUARD AND HARDENED IT** — `head -1` → set-extraction,
   so a surface disagreeing with **itself** fails before any cross-file comparison. **Ten mutants,
   all killed, zero zero-kills after the hardening.**
10. **SECOND EYES: NONE.** `codex` not on `PATH`; review was same-model, single-provider.
    **Twenty-first consecutive packet**, DERIVED from `ls build-os/receipts/gravito_*.md | wc -l`
    = **21**, and `build-os/memory/tool_router.md:368` was advanced `twenty` → **`21`** in the same
    commit as this receipt. **The cardinal table in `cnt_num` stops at twenty**, so from receipt
    twenty-one onward the site MUST be a numeral: `twenty-one` is `COUNT-UNREADABLE` and refuses.
    The guard is not broken; it is fail-closed on a bounded word table, by design.

### PROOF CARRIED

Suite **2265 / 0**, twice solo in the foreground after an anchored `pgrep -fa '^bash tests/'`
returned empty, never piped through `tail`, with a **byte-identical per-suite CHAINED vector**
across both runs (`DEFECT-0013`). Per-commit attribution **by execution**: `5d96031` 2228 →
`820fd14` **2228 (+0)** → `f15356e` 2242 (+14: `gate_depth` 79→90, `bandwidth` 41→44) → `9a285e6`
2265 (+23: `gate_depth` 90→113 **only**, all 20 other chained suites +0). **Packet total +37.**
**Commit-1 isolation `820fd14` → 2228/0.** `RELEASE_METADATA_LIVE_SUITE=1` **44/0**.
`tests/memory_kernel_tests.sh` **101/0** with `ANC-0003` at `:89` of this file **byte-unchanged at
all four commits**. Ceiling **0/0/0/0/0** over **11 changed paths, 0 additions of any kind**.
Census **105**, declared mismatches **22** (ANCHORED grep; the unanchored form returns 27 and is
wrong), re-authorisations **0**. **Citations: ZERO live breaks** — one closed receipt's range into
`current_state.md:95-99` meets the break definition and is **correctly left unrepaired**, because
rewriting a closed receipt would be the worse act.

**DISJOINT FILE-OWNERSHIP MANIFEST:** all **11** paths, **SINGLE-WRITER** (no fan-out; one builder
held every path across all three commits, so no two agents could contend and the merger question
does not arise). Per-commit sums **11 files / 653 insertions / 63 deletions**; the net union diff
`5d96031..9a285e6` is **11 / 640 / 50**, and the **13/13 gap is fully accounted**: `CHANGELOG.md`
68/7 vs 61/0 (**7**) and `current_state.md` 27/13 vs 21/7 (**6**). Full per-path table in receipt §4.
**The archivist close is a SEPARATE write set and is not in that manifest** — it writes only
`build-os/receipts/gravito_process_doctrine_correction_a.md`, `build-os/memory/current_state.md`,
this file, `build-os/memory/tool_router.md` (the `DC-0001` site only), `CHANGELOG.md` (the one
numeral only) and `build-os/metrics/packet_metrics.tsv`.

### OPEN BOUNDARIES CARRIED FORWARD

**No push, merge, PR, tag, deploy, secret, `git config`, amend or rebase** was performed by this
packet or this close, and **no such go has been given or asked for.** `5d96031` is the **PUSHED
TIP**; `820fd14`, `f15356e`, `9a285e6` and this close commit are **LOCAL AND UNPUSHED**. Installing
the user-scope `~/.claude/CLAUDE.md`, which still carries the withdrawn rule, is **external mutation
and remains operator-gated**. `bandwidth-check.sh` will report `commits EXCEEDED` after this close
because it counts `<declared base>..HEAD` and the close commit is a fourth commit above `5d96031`;
**that is expected, advisory, and not a breach** — the archivist close is bookkeeping after the
verdict, not a packet commit. The instrument cannot tell the two apart, and that limitation is named
here rather than worked around by editing the declared base.

## STAGED NEXT — the derived-restatement follow-up. NOT DECLARED, NOT IN FLIGHT, NO ID MINTED.

- **Proposed id (NOT MINTED, NOT DECLARED):** `PACKET-0043-derived-restatement-sweep`.
- **The objective, in one line:** retire the **nine** derived restatements of the withdrawn untyped
  cap, **highest value first**, and close the live product debt.
- **ORDERED BY WHO IS HARMED, NOT BY EFFORT.** (1) `templates/build-os/memory/tool_router.md:28`
  and `templates/build-os/packets/active_packet.md:35` — these **ship the withdrawn rule into every
  newly scaffolded project** and are the only two members of the register with a **downstream
  victim**. (2) `.claude/agents/builder.md`, `.claude/agents/build-orchestrator.md`,
  `build-os/memory/tool_router.md`, `docs/ONBOARDING.md` — read by agents at runtime. (3)
  `build-os/metrics/task_corpus.md`, `build-os/registry/CROSSWALK.md`,
  `build-os/registry/neurocosmology_crosswalk.txt` — descriptive; the last of these carries **zero**
  commit-budget statements and should be reconsidered as a register member.
- **CARRY THESE FOUR INTO THE DECLARATION, because they are what this packet learned:** widen or
  re-specify `UNTYPED_RE` (it matches ONE spelling); remove `no longer` from `WITHDRAWN_RE` or
  discriminate better (it makes a live assertion on such a line **fail open**); correct the false
  comment at `tests/gate_depth_tests.sh:397`; and **state the commit budget in
  `.claude/agents/reviewer.md`, the agent the census records as enforcing it.**
- **Explicitly NOT in it:** installing `~/.claude/CLAUDE.md` (external mutation, operator go), and
  any change to `build-os/memory/residue.md` (FROZEN, blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`,
  431 B headroom, unrotatable at every legal keep).

---

## CLOSE RECORD — `gravito_cross_file_sentinel_identity_a` (2026-08-04)

**Appended BELOW `:89` so the `ANC-0003` content site does not move.** The long form is
`build-os/receipts/gravito_cross_file_sentinel_identity_a.md`, which has no byte ceiling.

- **Verdict PASS-AS-FIXED.** qa **GREEN**; reviewer **fix-then-pass (4 items)**, all four
  discharged in the archivist's close commit rather than in a fourth packet commit — a decision
  about **where the bytes land**, not a claim the findings were trivial.
- **Base `74575ee`**, verified `git merge-base HEAD 74575ee` → `74575ee`. HEAD at the verdict
  `1918fc3`. **`5d96031` is the pushed tip**; every commit from `820fd14` up is LOCAL and UNPUSHED.
- **Commits: `905b69e` + `0d3a34f` (2 BUILD) + `1918fc3` (1 FIX) = 3 of 3, inside the typed budget
  (build ≤2, fix ≤1).** `1918fc3` is the **permitted** fix commit and is deliberately **not** logged
  as a breach — the doctrine installed by `PACKET-0042` forbids exactly that.
- **Depth 4 = `mandatory_full_regate`**, announced and legitimate: the reviewer's fix list arrived
  **complete in one installment**, the packet was **correctly scoped**, and the fixes altered the
  **demotion predicate itself** — load-bearing logic the contract's own re-review rules forbid
  closing by targeted confirmation. **Not recorded as a defect.**

### THE HEADLINE IS A NEGATIVE RESULT, AND THE PACKET PROVED IT AGAINST ITS OWN INTEREST

**`build-os/memory/residue.md` IS STILL UNROTATABLE.** Floor **25 of 25**. qa cleared C2 the tool's
own way and then swept **every keep 1–25**: keeps 1–24 trip **C1**, keep 25 trips **C7** at **431 B**
having archived **nothing**. **C2 WAS NEVER THE BINDING CONSTRAINT.** `(o)` and `(S1)` are declared
in `residue.md`'s **own block 25** and are live, so cross-file resolution could not and did not move
that floor. **The diagnosis that motivated this packet was wrong.** The tool's C7 text now names the
dead end and the operator remedies rather than leaving the reader to derive them.

### WHAT IT DID ACHIEVE

- **Cross-file identity resolution, proven a two-sided win.** C2's inbound half verified **1 → 6** in
  a root where the owner protects nothing itself, so own-file protection cannot be the answer.
- **`current_state.md` relieved by rotation #3** — headroom **3,642 → 31,102 B** (size 201,158 →
  173,075 B at `0d3a34f`), at `--keep 15`, window `[14, 16]` executed at **both** bounds.
- **`active_packet.md` went from permanently unrotatable to ALLOW** — but **keep-conditional**:
  floor **32**, so `--keep 15` REFUSES.
- **The packet caught its own FAIL-OPEN before shipping.** A live, canonically declared,
  non-consumable object was being **archived at exit 0** under **four** ordinary prose forms, one of
  them a plain markdown blockquote. Caught by a **single-model chain**, and only because the builder
  was pushed back on.

### STAGED, NOT DECLARED — `PACKET-0044` (deferred by the doctrine's own re-cut remedy)

Collision-checked **before** the mint: `grep -rlF 'PACKET-0044' . --exclude-dir=.git` → **0 files**,
`git log -S'PACKET-0044' --all --oneline` → **0 commits**. A second fix round is a **re-cut** and
stage 5 is closed, so both items below were **recorded, not built**.

1. **`build-os/maintenance/rotate-memory.mjs:1476` — `protected_in_owner` is emitted `false` for
   objects that ARE protected in their owner** (`(S1)` and `(o)`, both anchored in `residue.md`
   block 25). The predicate actually computes *named by a non-quoted marker in the owner*.
   **THE FIX IS TO RENAME the field and the local at `:1464` (`protectedAtHome`) — e.g.
   `marker_named_in_owner`. IT IS NOT TO WIDEN `markerNamingsIn`**, which would widen the demotion
   and re-open the hole. This is the packet's own disease — a name promising more than its predicate
   delivers — and it deserves a gated fix, not bookkeeping.
2. **`tests/build_os_maintenance_tests.sh:1795-1797` — the `*own-file*` check is not a
   differential**, and its `ok()` string claims it is. Both roots yield `own-file` by
   ordering/dedupe. The executable statement belongs in the **`orphan`** root: `residue.md`'s floor
   must stay **1**, not rise to the `(qqq)` declaration block.
3. **Carried in from this close (OUT OF THE ARCHIVIST'S WRITE BOUNDARY):** the "safe iff" overclaim
   survives at **`tests/build_os_maintenance_tests.sh:1831`** and **`CHANGELOG.md:69`**, both
   **outside `build-os/`**. The three in-boundary sites were corrected in the close commit; these
   two were **not**, because the archivist may only write under `build-os/`. See receipt §8.

`PACKET-0043-derived-restatement-sweep` remains **staged and undeclared** from the previous close.

---

## PACKET-0045-preintegration-baseline — CLOSED 2026-08-05 (declaration preserved below)

> **CLOSED PASS-AS-FIXED.** Receipt: `build-os/receipts/gravito_preintegration_baseline_a.md`.
> Base `7fb7f41`, HEAD `fff967e`; `c7433c5` + `945a140` + `014afb1` (3 BUILD) + `fff967e` (1 FIX).
> **The declaration below is preserved VERBATIM as written before dispatch** — it is the evidence
> that this packet was declared first, and rewriting it would destroy exactly that. Read it as
> history. Its `build-os/bench/` paths are superseded by `bench/` (receipt §6.5).
> **NOTE, for the guard's sake:** the declared-id line below reads `**canonical packet id:**`,
> which does NOT match the `**Packet id:**` pattern `bandwidth.active_packet_singleton` counts,
> so that guard read **0 in flight** for this packet's whole declared life. `DEFECT-0011` did NOT
> recur in substance; the guard simply cannot see the difference. Receipt §9 item 10.

- **THIS DECLARATION IS APPENDED BELOW THE `ANC-0003` SITE AT `:89`, AND NOTHING ABOVE `:89` IS
  TOUCHED.** `tests/memory_kernel_tests.sh` §18 embeds
  `build-os/packets/active_packet.md:89#ANC-0003` as a **resolved line number**; a pure append at the
  end of the file is line-count-neutral above the site by construction. `ANC-0003` re-verified
  resolving at `:89` after this edit, literal occurring **exactly once**.

**Declared BEFORE any dispatch.** Dispatching this packet undeclared is what earned
`OCCURRENCE-0020` on the prior attempt; the declaration is therefore build commit 1 and the run
happens only after it exists.

- **canonical packet id:** `PACKET-0045-preintegration-baseline`
- **lane:** `substantive` · **depth:** 2 (builder, then qa ‖ reviewer)
- **base / HEAD:** `7fb7f41` — verified: `git merge-base HEAD origin/claude/project-handoff-merge-ramhds`
  = `7fb7f41` = HEAD = the pushed tip. Base is correct.
- **baseline suite:** **2314 passed, 0 failed**, executed solo/foreground at `7fb7f41` before any edit.

### WHY THIS PACKET EXISTS

The operator is about to integrate Repository Core and authenticate a second provider. The
**single-provider, pre-Repository-Core state is about to disappear permanently.** This packet
captures it while it still exists. The output is **EVIDENCE, NOT PERFORMANCE**: nothing is tuned, no
task is retried for a better number, and no instance is swapped when the first goes badly. **A
flattering baseline is worse than no baseline**, because it manufactures a fake improvement later.

### THE CORRECTION IT IMPLEMENTS

`build-os/metrics/task_corpus.md` (v1.0.0, FROZEN) defines four task **shapes** and no task
**instances**. "A repository with at least one code comment containing a factual error" does not say
*which* comment, so a run against instances chosen today cannot be reproduced in six months — the
comment will have been fixed and the defect will be gone. This packet builds the **frozen instances**
the corpus lacks, then runs them.

**`task_corpus.md` IS NOT EDITED.** It is frozen and its own freezing rule forbids in-place edits.
Instances are *added* that satisfy the existing shapes; the shapes are not changed. Corpus version
stays **1.0.0**. Likewise `COMPARISON_PROTOCOL.md` is not edited; the corrections this packet makes
to its stated blockers are recorded here and in the receipt as **later records**, not as edits.

### IN SCOPE

1. `build-os/bench/seed-bench-repo.sh` — deterministic, byte-identical seed of an intentionally
   ordinary Node project carrying four frozen task instances (`T1`–`T4`), proven by seeding twice
   into different dirs with `diff -r` empty.
2. `build-os/bench/run-corpus.sh` — runs one task, one arm, capturing **machine-derived** metrics
   only via `claude -p --output-format json`; `time_to_first_correct_change` derived by running the
   task's test after each change, never model-self-reported; `human_interventions`, `rework`,
   `defects` recorded **operator-observed or `-`**, never model-asserted. **An unknown is not a zero.**
3. The executed snapshot: one run per task, recorded through `record-packet.sh` with `--note` naming
   corpus version, task id, run number and arm.
4. `build-os/bench/RETROSPECTIVE_ARM.md` — the 27 existing `packet_metrics.tsv` rows summarised as
   the pre-integration retrospective state. **No existing row is modified.**
5. `build-os/bench/BASELINE_LIMITS.md` — exactly what remains impossible and why.

### OUT OF SCOPE / CEILING

**0 new controls, 0 new governance primitives, 0 new suite files.** Scripts under `build-os/bench/`
are measurement infrastructure, not governance. The generated project is **never committed** — it is
seeded to `/tmp` at runtime; only the script is committed.

**DO NOT TOUCH:** `build-os/metrics/task_corpus.md`, `build-os/metrics/COMPARISON_PROTOCOL.md`,
`rank-candidates.sh`, `decision_telemetry.tsv`, `signal_snapshots.tsv`, `standing_gates.md`,
`residue.archive.md`, `DEFAULT_MAX_BYTES`. **`residue.md` is FROZEN** — verified at declaration time
as blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`; **its true size is 204,369 B, not the 431 B the
tasking stated** (`git cat-file -s` and `stat` agree at 204,369). The blob hash is the binding
identity and it matches, so the freeze holds and the file is not written; the byte figure in the
tasking is corrected here rather than propagated.

### WHAT THIS PACKET IS NOT

`COMPARISON_PROTOCOL.md` pre-registers a **16-run two-arm A/B** whose clock is held by a **human
operator, explicitly not an agent**. This packet is **one arm, one run per task — a snapshot, not
the A/B**, and it must never be quoted as the pre-registered experiment. The primary endpoint
(median `T3` wall-clock, arm B vs arm A) is **not** addressed here, because there is no second arm.

## CLOSED — `EXP-0001a-token-efficiency-execution` (declared 2026-08-05; closed 2026-08-05 by the archivist)

- **Packet id (CLOSED):** `PACKET-0046-exp0001-token-efficiency` — minted; `git log -S'PACKET-0046' --all`
  returns no commit and a full-tree grep for the token returned nothing before this edit.
- **Lane:** `substantive`. **Depth 2** — build stage (preregistration + instrument runs), then
  qa ‖ reviewer concurrently. Archivist close after the verdict.
- **Branch base:** at `0ddf0b6` — the pushed tip of `claude/project-handoff-merge-ramhds`,
  verified `git merge-base HEAD origin/claude/project-handoff-merge-ramhds` = HEAD = `0ddf0b6`.
- **Objective:** execute the operator's controlled experiment (2026-08-05): Gravito OFF vs ON on
  the frozen corpus, token-denominated. This packet carries outputs 1–2 of 5: the preregistered
  protocol (`build-os/experiments/EXP-0001-token-efficiency/PREREGISTRATION.md`, committed BEFORE
  run 1) and the sealed immutable run records (10 canonical T1 runs, 5 pairs alternating order,
  plus 6 T2–T4 refusal records) with sha256 manifest and the blinded X/Y dataset whose mapping
  hash is committed while the mapping stays outside the tree. Blinded analysis, reveal, and
  conclusion are the NEXT packet (`EXP-0001b`), so the evaluator's independence is a commit
  boundary, not a promise.
- **Commit plan:** commit 1 = preregistration + this declaration (docs only, green in isolation);
  commit 2 = sealed records + manifest + blinded dataset + mapping sha256. ≤2 build commits;
  fix commit only if the gates demand one.
- **Frozen-during-experiment rule (operator):** no edit to `bench/`, the corpus, oracles, prompts,
  or acceptance criteria; a defect discovered mid-run is recorded, the run labeled, machinery
  untouched. No push without explicit go. `residue.md` stays frozen at blob `01517ad2…`.
- **Out of scope:** any Gravito optimization, any benchmark change, any new control or governance
  primitive, any append to `packet_metrics.tsv` outside the archivist's normal close row. All new
  experiment files are NON-EXECUTABLE data (census must hold at 110).

## CLOSE RECORD — `gravito_exp0001_execution_a` (`PACKET-0046-exp0001-token-efficiency`) — closed 2026-08-05 by the archivist. NOTHING IN FLIGHT.

- **Packet id (CLOSED):** `PACKET-0046-exp0001-token-efficiency`. Receipt:
  `build-os/receipts/gravito_exp0001_execution_a.md`. Renames above were made **in place, one for
  one** (heading and marker), so nothing above `:89` moved and `bandwidth.active_packet_singleton`
  reads **0 in flight** — re-verified at close by running `bandwidth-check.sh check`.
- **Verdict:** qa **GREEN** (suite **2378/0** solo foreground at `d2373e6`, exit 0; commit-1
  isolation at `b3a3b7f` in a detached worktree **2378/0**; census 110, 0 executables under
  `build-os/experiments/`; manifest 47/47 sha256 OK; blinding leak grep 0; `residue.md` blob
  `01517ad2…` unchanged; safety grep clean, 41 files / +1080 / −0). Reviewer **PASS — ZERO fix
  items**. Second eyes: **NONE, single-model** (Codex host unreachable — the known four-state
  blocker). **Depth 2. 2 build commits (`b3a3b7f`, `d2373e6`), NO fix commit.** Base `0ddf0b6`.
- **Blinding at close:** arms X/Y in `analysis/blinded_dataset.tsv`; mapping WITHHELD from the
  tree (scratchpad only), sha256 `0a4b66a1…` committed in `analysis/MAPPING_SHA256.txt` and in
  the sealed manifest. **Reviewer's binding hand-off condition:** the EXP-0001b evaluator receives
  ONLY the blinded dataset + preregistration §5 rule text — NEVER §3's schedule.
- **DC-0001:** the router's second-eyes streak numeral moved **25 → 26** in this close commit,
  derived from the receipt store (`ls build-os/receipts/gravito_*.md | wc -l` = 26).
- **Boundaries:** NOTHING PUSHED — `b3a3b7f`, `d2373e6` and the close commit are local pending
  explicit operator go; none may be amended. No merge, no deploy, no secrets.

### Staged next — NOT DECLARED, NOT IN FLIGHT, NO ID MINTED

**EXP-0001b — blinded evaluation, reveal, conclusion.** Declaring it is a routing act, not the
archivist's. Advisories carried there (receipt §7): execute the reveal promptly — the withheld
mapping and the 10 stream logs exist only in the session scratchpad; and the analysis must
surface the T2–T4 refusals and per-arm acceptance explicitly.

## CLOSED — `EXP-0001b-token-efficiency-analysis` (declared 2026-08-05; closed 2026-08-05 by the archivist)

- **Packet id (CLOSED):** `PACKET-0047-exp0001-analysis-reveal` — minted; `git log -S'PACKET-0047' --all`
  returned 0 commits and a full-tree grep 0 files before this edit.
- **Lane:** `substantive`. **Depth 2** — build stage (blinded analysis committed, then reveal),
  then qa ‖ reviewer concurrently. Archivist close after the verdict.
- **Branch base:** at `92c7276` — PACKET-0046's close commit, tree quiet at declaration.
- **Objective:** outputs 3–5 of the operator's controlled experiment. Commit 1 = this
  declaration + `analysis/BLINDED_ANALYSIS.md`, the independent evaluator's report VERBATIM
  (evaluator saw only the X/Y dataset + the §5 rule in neutral form — never §3's schedule,
  per the reviewer's binding hand-off condition; its blinding affirmation is in the report).
  Commit 2 = the reveal: the withheld mapping file (must hash to the pre-committed
  `0a4b66a1…` in `MAPPING_SHA256.txt`), `REVEALED_COMPARISON.md`, and `CONCLUSION.md`
  drawing exactly one of the four preregistered labels with direction and scope.
- **Ordering is the evidence:** blinded analysis is committed BEFORE the mapping enters the
  tree; ancestry proves the evaluator could not have seen the mapping.
- **Frozen rule unchanged:** no edit to `bench/`, sealed `runs/`, `blinded_dataset.tsv`,
  `PREREGISTRATION.md`, or any frozen surface. `residue.md` stays frozen. No push without go.
- **Out of scope:** any Gravito optimization or response to the result — acting on the
  finding is the operator's decision, not this packet's.

## CLOSE RECORD — `gravito_exp0001_analysis_reveal_a` (`PACKET-0047-exp0001-analysis-reveal`) — closed 2026-08-05 by the archivist. NOTHING IN FLIGHT.

- **Packet id (CLOSED):** `PACKET-0047-exp0001-analysis-reveal`. Receipt:
  `build-os/receipts/gravito_exp0001_analysis_reveal_a.md`. **Lane:** `substantive`.
  **Depth 2** — build stage, then qa ‖ reviewer concurrently. Base `92c7276`.
- **Commits:** `7d56cbc` (blinded analysis VERBATIM + declaration; mapping absent from the
  tree — ls-tree proof) + `698e3c3` (mapping reveal + `REVEALED_COMPARISON.md` +
  `CONCLUSION.md`). **2 build commits, NO fix commit belongs to this packet.**
- **THE RESULT:** blinded evaluator — "causal effect supported, condition Y lower", 50.8%
  median total-token reduction, ranges fully disjoint. Mapping raw=Y / buildos=X,
  byte-exact to the pre-committed sha256 `0a4b66a1…`, verified by qa AND reviewer.
  **Gravito OFF used 50.8% FEWER tokens on T1 (OFF median 153,611 vs ON 312,444) —
  direction OPPOSITE the hypothesis.** Scope: T1-class only, N=5 pairs, one repo, one
  model config; T2–T4 no numeric data; the substantive-work claim untested, not
  contradicted. **EXP-0001 is COMPLETE** — all five outputs in ancestry order
  (`b3a3b7f` → `d2373e6` → `7d56cbc` → `698e3c3`); the experiment stays frozen; acting
  on the finding is the operator's decision.
- **Gates:** qa initially RED 2375/3 — all three failures pre-existed at BASE `92c7276`
  (PACKET-0046's close bookkeeping, written AFTER its gates measured `d2373e6`); this
  packet's commits proved empty diffs on those surfaces. Repaired OUTSIDE this packet by
  tiny-lane `d0a2231` (2 rounds, not a fix commit of this packet, not a doctrine breach);
  after it FULL SUITE **2378/0** solo at `d0a2231`, both affected suites 70/0,
  `check-adoption` exit 0. Reviewer **PASS, ZERO items**; no result-driven mutation —
  frozen surfaces byte-untouched despite the unflattering result. Second eyes NONE
  (Codex 403 CONNECT policy-denied, reproduced live by both gates); `DC-0001` numeral
  moved **26 → 27** in this close commit, derived from the receipt store.
- **Defect class named:** "close bookkeeping written after the gates" — the next
  archivist runs `check-adoption.sh` BEFORE committing a close. This close ran it before
  (exit 0 at `d0a2231`) and after writing its row and receipt (exit 0).
- **Boundaries:** NOTHING PUSHED — `b3a3b7f`, `d2373e6`, `92c7276`, `7d56cbc`,
  `698e3c3`, `d0a2231`, and this close commit all local pending explicit operator go;
  none may be amended. No merge, deploy, or secrets. `residue.md` stays frozen.
  **NOTHING IS IN FLIGHT; nothing is staged** — any follow-up to the finding is the
  operator's routing act, not the archivist's.

## CLOSED — `EXP-0002a-sustained-workload-execution` (declared 2026-08-05; closed 2026-08-05 by the archivist)

- **Packet id (CLOSED):** `PACKET-0048-exp0002-sustained-workload` — minted; `git log -S'PACKET-0048' --all`
  0 commits, full-tree grep 0 files before this edit.
- **Lane:** `substantive`. **Depth 2** — build stage (preregistration + harness + sequence runs),
  then qa ‖ reviewer concurrently; archivist close after the verdict.
- **Branch base:** at `982054a` — the pushed tip (EXP-0001 published; remote = local, 0/0).
- **Objective (operator, 2026-08-05):** Track B of the two-track directive — the sustained-workload
  token-efficiency experiment, Claude alone, Codex not a prerequisite. Five related tasks
  (diagnose → tested fix → multi-file feature → injected regression → fresh-session follow-up)
  on one evolving parcel-billing tree per arm, fresh session per task, byte-identical prompts;
  arm raw vs arm buildos; Bash-capable path proven (`BASH_PROBE_OK_42`, scoped allowlist,
  0 denials — the EXP-0001 invalidity condition resolved). Cumulative curves + crossover point.
  Weekly meter: unobservable here, recorded as such, never estimated.
- **Commit plan:** commit 1 = preregistration + harness + this declaration (BEFORE run 1;
  seed digest 128485c6… pinned in the prereg); commit 2 = sealed run records + manifest +
  blinded dataset + mapping sha256. Analysis/reveal = the NEXT packet, preserving the
  evaluator-independence commit boundary.
- **Frozen:** bench/ and all EXP-0001 artifacts untouched; no mid-run optimization; failed runs
  retained; `residue.md` frozen; no push without go (the EXP-0001 go does not extend here).

## CLOSE RECORD — `gravito_exp0002_execution_a` (`PACKET-0048-exp0002-sustained-workload`) — closed 2026-08-05 by the archivist. NOTHING IN FLIGHT.

- **Packet id (CLOSED):** `PACKET-0048-exp0002-sustained-workload`. Receipt:
  `build-os/receipts/gravito_exp0002_execution_a.md`. **Lane:** `substantive`.
  **Depth 3 — fix-then-pass (1 enumerated item), announced** — build stage; qa ‖ reviewer
  concurrently; one bounded fix round. Base `982054a` — the pushed tip, merge-base
  re-verified at close.
- **Commits:** `9cf0f87` (preregistration + harness, BEFORE run 1 — all 10 run timestamps
  postdate it, qa-verified) + `2d0696a` (RULING-4 registration of the four refusal-capable
  harness surfaces; census 110→114; crosswalk + derived totals same commit) + `916e1ae`
  (sealed records + blinded dataset + mapping sha256 `45734767…`) + `38ee0df` (the ONE
  permitted fix commit). **THREE build commits = the RECORDED CONTRACT-GAP shape** — the
  identity scanner forced the registration mid-packet, same class as PACKET-0045's third
  commit; NOT a builder breach. Commit-1 isolation RED at `9cf0f87` BY that same gap;
  commits 1+2 at `2d0696a` GREEN 2378/0 — qa verified both directions.
- **Executed:** two five-task sequences (T1 diagnose → T2 tested fix → T3 multi-file
  feature → T4 injected regression → T5 context-dependent follow-up) on one evolving
  parcel-billing tree per arm (seed `128485c6…`, suite 19/0), fresh headless session per
  task, byte-identical prompts (`task_prompt_sha256` equal across arms,
  reviewer-verified), arms differing only by `install-project.sh`; Bash-capable path
  (scoped allowlist; non-binding in CLI 2.1.222, disclosed, identical both arms).
  **10/10 durable accepted outcomes by external oracles; model identical across all 10.**
- **Gates:** qa RED 2376/2 — ONE attributed item (sealed buildos T3/T5 stream transcripts
  carried workload-repo citations the tree-wide range-citation sweep bit on); fixed in
  `38ee0df` restoring EXP-0001's sealed form (all ten transcripts scratchpad-resident,
  hash-pinned in the manifest; records/result.json byte-untouched; no sweep modified).
  Re-check: control_registry_tests 180/0, **FULL SUITE 2378/0 exit 0 solo at `38ee0df`**,
  manifest 31/31 OK. Reviewer **PASS, ZERO items** → **PASS-AS-FIXED**; 3 obligations
  routed to the NEXT packet (define the `usage_block_disagrees` criterion; state the
  arm-B seed derivation in the revealed report; run the reveal promptly). Second eyes
  NONE (Codex 403 at proxy, reproduced live by both gates); `DC-0001` numeral moved
  **27 → 28** in this close commit, derived from the receipt store.
- **Recorded for later, harness untouched (freeze rule):** the result-event `usage.*`
  block undercounts dispatch-heavy sessions (buildos T3 dispatched 5 subagents, T5
  dispatched 4); the sealing layer uses the provider `modelUsage` aggregate uniformly
  (reconciles exactly with `total_cost_usd`; qa re-derived all 10 rows), affected rows
  labeled `usage_block_disagrees=yes`. Reviewer's integrity finding: the uncorrected
  block would have FLATTERED arm B (~70x undercount on its T3) — the correction moved
  the data AGAINST the convenient direction, the opposite signature of result-driven
  adjustment.
- **Blinding at close:** dataset X/Y only, zero arm strings (qa grep 0); dispatch counts
  deliberately EXCLUDED (they would de-blind); mapping withheld in scratchpad, sha256
  pre-committed. The blinded analysis ALREADY EXISTS (independent evaluator, completed
  before this close) and is committed by the NEXT packet.
- **Boundaries:** NOTHING PUSHED — `9cf0f87`, `2d0696a`, `916e1ae`, `38ee0df`, and this
  close commit all local pending explicit operator go; none may be amended. No merge,
  deploy, or secrets. `residue.md` stays frozen. **NOTHING IS IN FLIGHT.** Staged next
  but NOT DECLARED (a routing act, not the archivist's): **EXP-0002b** — blinded
  analysis committed verbatim, reveal against the pre-committed hash, conclusion with
  the two mandated reconciliations (EXP-0001's trivial-task overhead; the historical
  weekly-usage drop).

## CLOSED — `EXP-0002b-analysis-reveal` (declared 2026-08-05; closed 2026-08-05 by the archivist)

- **Packet id (CLOSED):** `PACKET-0049-exp0002-analysis-reveal` — minted; 0 commits, 0 files carried the
  token before this edit.
- **Lane:** `substantive`. **Depth 2** — build (analysis commit, then reveal commit), then
  qa ‖ reviewer concurrently; archivist close after the verdict.
- **Branch base:** at `5c04755` — PACKET-0048's close commit, tree quiet at declaration.
- **Objective:** outputs 3–5 of EXP-0002. Commit 1 = this declaration + the evaluator's
  BLINDED_ANALYSIS.md verbatim + its sibling provenance note. Commit 2 = the reveal: the
  withheld mapping (must hash to the pre-committed `45734767…`), REVEALED_COMPARISON.md
  (discharging the reviewer's three obligations: the usage_block_disagrees criterion, the
  arm-B seed derivation, prompt reveal), and CONCLUSION.md carrying the two operator-mandated
  reconciliations (EXP-0001's trivial-task overhead; the historical weekly-usage drop) and
  exactly one label from the preregistered four-option vocabulary.
- **Frozen:** sealed runs/, blinded_dataset.tsv, PREREGISTRATION.md, bench/, EXP-0001 —
  untouched. No push without go. Acting on findings is the operator's decision, not this
  packet's.

## CLOSE RECORD — `gravito_exp0002_analysis_reveal_a` (`PACKET-0049-exp0002-analysis-reveal`) — closed 2026-08-05 by the archivist. NOTHING IN FLIGHT.

- **Packet id (CLOSED):** `PACKET-0049-exp0002-analysis-reveal`. Receipt:
  `build-os/receipts/gravito_exp0002_analysis_reveal_a.md`. **Lane:** `substantive`.
  **Total depth 5, each stage announced** — build; qa ‖ reviewer; fix; **Depth 4 =
  `mandatory_full_regate`** (the fixes altered the load-bearing conclusion — NOT a
  defect); stage 5 = the bounded second fix under the contract's executed-reason
  exception. Base `5c04755`, tree quiet at declaration.
- **Commits:** `23983ba` (blinded analysis VERBATIM + sibling provenance + declaration)
  + `46809e6` (reveal: mapping `raw=X`/`buildos=Y` hash-verified byte-exact against
  `916e1ae`'s pre-commitment `45734767…`; revealed comparison; conclusion) + `ca65b98`
  (fix 1: all 4 first-round items, one installment) + `ce7588c` (fix 2: the two-line
  flipped-percentage correction — the defect was CREATED by fix 1, could not have been
  enumerated before it existed; reviewer's exact prescribed form; qa had independently
  flagged the same wording).
- **THE REGISTERED RESULT:** **`no sustained-workload savings detected`** — OFF used
  **74.8% fewer** total tokens per durable accepted outcome than ON (ON at **3.96×**,
  +296%; 2,631,154 vs 663,924; uncached agreeing 78.8%; 10/10 acceptance both arms;
  crossover against ON at T3 on totals, T2 on uncached/cost). Evaluator's symmetric
  wording preserved verbatim; the translation stage applies the registered directional
  rule (§6 pre-assigned B-worse to rule 3); the mistranslation was caught by BOTH gates
  independently; the neutral rule text committed (`analysis/EVALUATOR_RULE_TEXT.md`).
  **The finding:** overhead is protocol-invocation-dependent, not fixed — ON cheaper on
  T1 (−31.5%) and T4 (−56.5%), 3.9×/7.8× costlier on T3/T5; a router enforcing the
  selector's verdicts prevents ONLY T5 (T3's verdict was `gravito_full`). Router =
  next CANDIDATE, not built. Both mandated reconciliations carried.
- **Gates:** first round on `46809e6` — reviewer fix-then-pass (4 items) + qa RED on
  the same label-rule defect. Full re-gate on `ca65b98` — qa GREEN **2378/0 solo**,
  commit-1 iso 2378/0, label mechanically re-derived, hash byte-exact, frozen surfaces
  intact, all gates 0; reviewer fix-then-pass on the ONE item fix 1 introduced.
  Targeted confirmation after `ce7588c`: 0 remaining occurrences,
  control_registry_tests 180/0, tree clean → **PASS-AS-FIXED**. Second eyes NONE across
  all four gate passes (Codex 403 at proxy each time, attempted and stated). `DC-0001`
  numeral moved **28 → 29** in this close commit, derived from the receipt store.
- **EXP-0002 is COMPLETE with this close:** all five outputs in ancestry order —
  prereg `9cf0f87` → sealed records `916e1ae` → blinded
  analysis `23983ba` → reveal `46809e6` → registered conclusion `ca65b98`/`ce7588c`.
- **Boundaries:** NOTHING PUSHED — `23983ba`, `46809e6`, `ca65b98`, `ce7588c`, and this
  close commit all local pending explicit operator go; none may be amended. No merge,
  deploy, or secrets. `residue.md` stays frozen. **NOTHING IS IN FLIGHT; nothing is
  staged** — the router candidate is a routing decision for the orchestrator, not the
  archivist's to declare.

## CLOSED — `routing-enforcement-and-budgets` (declared 2026-08-05; closed 2026-08-05 by the archivist)

- **Packet id (CLOSED):** `PACKET-0050-routing-enforcement` — minted; 0 commits, 0 files carried the token
  before this edit.
- **Lane:** `substantive`. **Depth 2** — builder, then qa ‖ reviewer concurrently.
- **Branch base:** at `0239737` — the pushed tip (EXP-0002 published; remote = local, 0/0).
- **Objective (operator directive, post-EXP-0002):** the bounded routing-and-budget
  correction. TWO EXECUTED PRODUCT DEFECTS drive it, from EXP-0002's sealed records:
  (1) ENFORCEMENT — buildos T5 executed Full ceremony (4 dispatches, $4.80) despite the
  selector's recorded `gravito_light` verdict; (2) CALIBRATION — T3 was classified `full`
  and the resulting ceremony was economically disproportionate (5 dispatches, 3.9× tokens).
  The finding being productized: "Gravito Light showed evidence of useful context
  amortization, while uncontrolled escalation into Gravito Full destroyed the economics."
- **Scope:** (A) selector verdicts become operationally binding (direct = no workflow
  machinery; light = repository context + bounded checks, no Full ceremony; full = only
  within explicit budgets); escalation above the recorded mode requires a new
  evidence-bearing escalation decision — silent escalation prohibited and refused at close.
  Routing receipts: selected mode, executed mode, escalation + evidence, budgets
  (calls/subagents/tokens/uncached/time/cost), final consumption. (B) hard economic
  circuit breakers for Full with graceful degradation (stop spawning → collapse to parent →
  preserve state → continue Light where safe → report degradation), never bare termination
  while a safe productive path remains. (C) Full-mode recalibration: complexity alone is
  insufficient; Full requires value-over-cost evidence (irreversible/external mutation,
  blast radius, unclear acceptance, security consequence, genuinely parallel workstreams,
  high rework history, non-deterministic verification).
- **Honest-scoping rule:** mechanical enforcement where a check can execute (receipt
  schema + close-time refusal on unrecorded escalation or budget breach), protocol text
  where live-session counters are not machine-visible — each labeled as what it is; no
  checkbox that looks enforced and is not.
- **Out of scope:** EXP-0003 (next packet, after this correction); memory-control packets
  (not authorized); bench/ and both experiment trees (frozen, published); empathiq-website.

## CLOSE RECORD — `gravito_routing_enforcement_a` (`PACKET-0050-routing-enforcement`) — closed 2026-08-05 by the archivist. NOTHING IN FLIGHT.

- **Packet id (CLOSED):** `PACKET-0050-routing-enforcement`. Receipt:
  `build-os/receipts/gravito_routing_enforcement_a.md`. **Lane:** `substantive`.
  **Depth 3, announced** — build; qa ‖ reviewer concurrently; one bounded fix round.
  Base `0239737` (the pushed tip), tree quiet at declaration.
- **Commits:** `ac1581c` (declaration, docs-only) + `c49258e` (build, with same-commit
  RULING-4 registration — census **114 → 118**, NO contract-gap replay; the builder's
  `1fb1cc0`→`c49258e` amend was message-only pre-gate, disclosed and verified) +
  `4443360` (the one permitted fix commit — 2 build + 1 fix, within budget).
- **What it closes, proven by execution at the gates:** DEFECT 1 (T5 silent
  escalation) — the reviewer rebuilt T5's receipt from its sealed descriptor and
  `routing-check.sh` REFUSED it with 5 named violations; DEFECT 2 (T3 calibration) —
  T3's sealed complexity-only descriptor now routes `gravito_light` under the product
  selector while the frozen experiment selector still returns `gravito_full`, proving
  both the recalibration and the non-mutation of the frozen copy.
- **Shipped:** `mode-select.mjs` (7 value factors; complexity alone earns light);
  `route-task.sh` (routing receipts, DERIVED-DEFAULT budgets from the sealed EXP-0002
  bands, raw T4's 526,461 a named exceedance); `routing-check.sh` (close-time gate,
  '-' is admission, refusal is for contradiction; live sweep chained into
  `build_os_tests.sh` §26); `routing_contract.md` (binding-verdict rule + five-step
  circuit breaker as labeled PROTOCOL; THREE named honest bounds, including receipt
  ISSUANCE itself unchecked — a packet that never routes is invisible to the gate);
  CLAUDE.md step 7; `tests/routing_enforcement_tests.sh` (104/0, red-driven).
- **Gates:** qa GREEN — suite **2482/0 solo** (+104, all the new routing suite,
  per-suite deltas from logs), commit-1 iso 2378/0 at the docs-only declaration, the
  exact T5 replay refused with SILENT-ESCALATION named, census 118 reconciled, frozen
  surfaces intact, mirrors byte-identical, amend transparency verified. Reviewer
  fix-then-pass, 2 items, both fixed in `4443360` exactly as prescribed (qa had
  independently flagged the same citation) → **PASS-AS-FIXED**. Second eyes NONE
  (Codex 403 at proxy, attempted and stated by both gates). `DC-0001` numeral moved
  **29 → 30** in this close commit, derived from the receipt store.
- **Live routing receipt closed:** `executed_mode: gravito_full` (matches selected;
  no escalation); consumption fields stay '-' with the doctrinal reason on the
  receipt; post-fill sweep `routing-check.sh check` = 1 receipt, 0 violations, exit 0.
  **Open calibration question, recorded not resolved:** a full-mode packet's own gate
  chain (builder+qa+reviewer+archivist) brushes the `max_subagents: 3` default —
  whether process agents count against task budgets is an EXP-0003-adjacent operator
  question.
- **Boundaries:** NOTHING PUSHED — `ac1581c`, `c49258e`, `4443360`, and this close
  commit all local pending explicit operator go; none may be amended. No merge,
  deploy, or secrets. `residue.md` stays frozen. **NOTHING IS IN FLIGHT.** Staged next
  but NOT DECLARED (a routing act, not the archivist's): **EXP-0003** — three NEUTRAL
  preregistered conditions (direct / gravito_light / gravito_full-with-enforced-budgets)
  on T3/T4/T5-style tasks; output = the routing frontier; the conclusion rule must NOT
  be direction-asymmetric this time (the operator's explicit instruction).

## CLOSED — `EXP-0003a-routing-frontier-execution` (declared 2026-08-05; closed 2026-08-05 by the archivist)

- **Packet id (CLOSED):** `PACKET-0051-exp0003-routing-frontier` — minted; 0 commits/0 files before this edit.
- **Lane:** `substantive`. **Depth 2.** Routing receipt issued BEFORE building (the new step 7,
  first live use): `routing-PACKET-0051-exp0003-routing-frontier-20260805T190501Z.md`,
  selected_mode gravito_full via the honest value factor high_rework_history (three consecutive
  experiment packets required fix rounds); budgets attached and binding.
- **Branch base:** at `94c5187` — PACKET-0050's close, tree quiet.
- **Objective (operator directive §4):** the bounded three-condition experiment. Conditions:
  A direct/raw · B gravito_light (installed surface + binding light receipt) · C gravito_full
  WITH ENFORCED BUDGETS (installed surface + full receipt + circuit-breaker protocol). Task
  shapes: T3-style feature, T4-style regression, T5-style follow-up, on the frozen
  parcel-billing seed with DETERMINISTIC SCRIPTED T1/T2 SETUP identical across conditions.
  NEUTRAL preregistered rule (operator's explicit instruction — no direction asymmetry;
  the EXP-0002 mistranslation class structurally cannot recur): per-shape ranking, output =
  the ROUTING FRONTIER; vocabulary: frontier observed | frontier unstable | result confounded.
  The harness fills receipt consumption fields from its own telemetry, making the close-time
  budget gate MECHANICAL in this experiment — its first exercise on measured numbers; a
  refused receipt is data, retained. Telemetry modelUsage-native (the EXP-0002
  defect-for-later, fixed in the NEW runner, not by editing frozen machinery). EXP-0002
  harness pieces reused by INVOCATION only (seeder/oracles/injector — read-only, disclosed).
- **Commit plan:** commit 1 = preregistration + EXP-0003 harness + this declaration (before
  run 1, same-commit registration of any refusal-capable scripts); commit 2 = sealed records +
  blinded dataset (P/Q/R labels, mapping withheld by hash). Analysis/reveal = next packet.
- **Frozen:** bench/, both prior experiment trees, routing tools (PACKET-0050 shipped surface —
  the experiment RUNS it, never edits it). No push without go.

## CLOSE RECORD — `gravito_exp0003_execution_a` (`PACKET-0051-exp0003-routing-frontier`) — closed 2026-08-05 by the archivist. NOTHING IN FLIGHT.

- **Packet id (CLOSED):** `PACKET-0051-exp0003-routing-frontier`. Receipt:
  `build-os/receipts/gravito_exp0003_execution_a.md`. **Lane:** `substantive`.
  **Depth 3, announced** — build; qa ‖ reviewer concurrently; one bounded fix round
  (`fix-then-pass`, 1 enumerated item). Base `94c5187` (PACKET-0050's close), tree quiet.
- **Commits:** `acfa1be` (declaration + the packet's OWN routing receipt — FIRST LIVE
  USE of PACKET-0050's step 7; gravito_full via the honest high_rework_history factor) +
  `18f82f6` (preregistration + harness + same-commit RULING-4 registration, census
  **118 → 121**) + `cdfe1a3` (sealed records + blinded P/Q/R dataset + SEAL-TIME
  evaluator rule text closing the EXP-0002 audit gap in advance + mapping sha256
  `8a063552…`) + `9beb73f` (the one permitted fix commit).
- **What was executed:** nine runs (3 conditions × T3/T4/T5 shapes), deterministic
  scripted T1/T2 setup digest-pinned and harness-verified on every run, EXP-0002's
  frozen prompts byte-pinned, modelUsage-native telemetry with exact cost
  reconciliation on all nine, 9/9 durable accepted outcomes, identical model string.
- **THE HEADLINE THE ANALYSIS PACKET INHERITS (not this record's verdict to draw):**
  both condition receipts REFUSED by the mechanical budget gate at close — B (light):
  4 budget breaches, ZERO silent escalation, 0 dispatches (the binding-verdict half
  held; budgets did not); C (full): 5 breaches incl. 7 subagents vs 3 and 7.5M tokens
  vs 2M; NO degradation notes written by either condition's sessions — the protocol
  half of the circuit breaker did not execute live. Verdicts sealed as data; per-run
  decomposition in `analysis/GATE_CALIBRATION_NOTE.md`; two operator calibration
  questions (per-task vs per-sequence granularity; band re-derivation).
- **Gates:** qa GREEN — suite **2545/0 solo**, commit-1 iso **2482/0** at `acfa1be`
  and **2545/0** at `18f82f6`, manifest 34/34, all 9 blinded rows re-derived 1:1,
  ordering proven (incl. the two records lacking time_origin_ms, via artifact mtimes),
  frozen surfaces zero-diff, census 121, harness re-driven — digests, refusals, prompt
  pins exact. Reviewer fix-then-pass on ONE item (budget-granularity consideration
  silently unnamed), fixed in `9beb73f` — content matches the reviewer's own
  derivation, neither REFUSED verdict softened, nothing sealed edited →
  **PASS-AS-FIXED**. Second eyes NONE (Codex 403 at proxy, attempted and stated by
  both gates). `DC-0001` numeral moved **30 → 31** in this close commit, derived from
  the receipt store.
- **Live routing receipt closed:** `executed_mode: gravito_full` (matches selected;
  no escalation); consumption fields stay '-' with the transcript-only admission on
  the receipt (the nine experiment runs' measured consumption belongs to the sealed
  condition receipts, not this packet's own). Post-fill sweep `routing-check.sh check`
  = 2 receipts, 0 violations, exit 0.
- **Cosmetic twin (both gates):** `receipt-final.md`/`receipt_final.md` byte-identical
  pairs in both close dirs, both manifested — treated as one receipt by the analysis,
  never deleted (manifest integrity).
- **Boundaries:** NOTHING PUSHED — `acfa1be`, `18f82f6`, `cdfe1a3`, `9beb73f`, and
  this close commit local pending explicit operator go (9 commits ahead of origin
  after this close, derived from git); none may be amended. No merge, deploy, or
  secrets. `residue.md` stays frozen. **NOTHING IS IN FLIGHT.** Blinded evaluation
  ALREADY EXISTS (independent session, dataset + sealed rule text only; label not
  named here — reveal ordering kept clean). Staged next but NOT DECLARED (a routing
  act, not the archivist's): **EXP-0003b — analysis/reveal.**

## CLOSED — `EXP-0003b-analysis-reveal` (declared 2026-08-05; closed 2026-08-05 by the archivist)

- **Packet id (CLOSED):** `PACKET-0052-exp0003-analysis-reveal` — minted; 0 commits/0 files before this edit.
- **Lane:** `substantive`. **Depth 2.** Routing receipt issued before building:
  `routing-PACKET-0052-…-20260805T210607Z.md`, selected gravito_full (value factor
  high_rework_history — the EXP-0002 reveal needed two fix rounds; this is the same
  reveal-translation task class), budgets binding.
- **Branch base:** at `e276b88` — PACKET-0051's close, tree quiet.
- **Objective:** EXP-0003 outputs 3–5. Commit 1 = this declaration + the evaluator's
  BLINDED_ANALYSIS.md verbatim + sibling provenance. Commit 2 = the reveal (mapping must hash
  to the pre-committed `8a063552…`), REVEALED_COMPARISON.md (the routing frontier, gate
  verdicts beside it per §10.5 with the committed calibration note), CONCLUSION.md drawing
  exactly one §8 label with translation applying NO directional rule (none exists).
- **Frozen:** sealed runs/, blinded_dataset.tsv, EVALUATOR_RULE_TEXT.md, GATE_CALIBRATION_NOTE.md,
  PREREGISTRATION.md, both prior experiment trees, bench/, routing tools. No push without go.

## CLOSE RECORD — `gravito_exp0003_analysis_reveal_a` (`PACKET-0052-exp0003-analysis-reveal`) — closed 2026-08-05 by the archivist. NOTHING IN FLIGHT.

- **Packet id (CLOSED):** `PACKET-0052-exp0003-analysis-reveal`. Receipt:
  `build-os/receipts/gravito_exp0003_analysis_reveal_a.md`. **Lane:** `substantive`.
  **Depth 3, announced** — build; qa ‖ reviewer concurrently; one bounded fix round
  (`fix-then-pass`, 4 enumerated items). Base `e276b88` (PACKET-0051's close), tree quiet.
- **Commits:** `9d78999` (declaration + routing receipt, gravito_full via
  high_rework_history) + `1cb31f6` (blinded analysis VERBATIM + sibling provenance,
  mapping absent — ancestry-provable) + `f2a2b3a` (reveal: mapping `A=Q·B=R·C=P`
  byte-exact vs pre-committed `8a063552…`; REVEALED_COMPARISON.md; CONCLUSION.md) +
  `a3b0ba7` (the one permitted fix commit).
- **THE RESULT:** **`frontier unstable — winners flip on uncached`** — the evaluator's
  own label, carried unchanged; NO directional rule exists to translate through.
  Frontier at n=1: **direct** wins T3/T5 totals and T5 outright; **light** wins the
  uncached lens on T3/T4 (third and fourth consecutive amortization data points after
  EXP-0002's T1/T4) and is never worse than second on uncached; **full** wins T4
  totals only and never wins uncached. Totals 90.6–96.8% cache_read in every cell
  (confound C2). Gate verdicts beside the frontier: both condition receipts REFUSED
  (per-run decomposition committed pre-reveal in GATE_CALIBRATION_NOTE.md); ZERO
  silent escalation (the PACKET-0050 binding-verdict rule held live); ZERO degradation
  notes (the breaker's protocol half did not execute unattended). Four operator
  questions handed over — budget granularity; band re-derivation; mid-flight budget
  awareness; the totals-vs-uncached lens. Nothing acted on.
- **Gates:** qa GREEN — suite **2545/0 solo** with the 3-receipt routing sweep clean;
  commit-1 iso green; ordering/hash/ancestry exact; all arithmetic recomputed
  independently and matching; frozen surfaces zero-diff; census 121 — with ONE
  attributed BASE finding: PACKET-0051's close left a bare `**Packet id:**` marker at
  `:2301`, so the bandwidth singleton read 2-in-flight (pre-existing at `e276b88`).
  FIXED AT THIS CLOSE: both markers normalized to `**Packet id (CLOSED):**` in place
  (nothing above `:89` moved); post-fix `bandwidth-check.sh check` = **0 in flight,
  exit 0**. Reviewer fix-then-pass on FOUR prose/number items (the
  repeated-evaluator-claims-without-verification class, incl. the genuine §e/§b
  inconsistency in the sealed evaluator report — stated, sealed file verbatim), all
  four fixed in `a3b0ba7` exactly as enumerated → **PASS-AS-FIXED**. Second eyes NONE
  (Codex 403 at proxy, attempted and stated). `DC-0001` numeral moved **31 → 32** in
  this close commit, derived from the receipt store.
- **Live routing receipt closed:** `executed_mode: gravito_full` (matches selected; no
  escalation); consumption fields stay '-' with the transcript-only admission on the
  receipt. Post-fill sweep `routing-check.sh check` = 3 receipts, 0 violations, exit 0.
- **Boundaries:** NOTHING PUSHED — `9d78999`, `1cb31f6`, `f2a2b3a`, `a3b0ba7`, and
  this close commit local pending explicit operator go (**14 commits ahead of origin
  after this close**, derived from git); none may be amended. No merge, deploy, or
  secrets. `residue.md` stays frozen. **NOTHING IS IN FLIGHT; NOTHING IS STAGED** —
  the operator's three-part directive (publish EXP-0002 → routing correction →
  EXP-0003) is **COMPLETE**; EXP-0003's five outputs stand in ancestry order
  (`18f82f6` → `cdfe1a3` → `1cb31f6` → `f2a2b3a` → `a3b0ba7`). NOTE: after this
  close's append, `current_state.md` is within ~1.7 KB of its 204,800 B ceiling —
  the NEXT close cannot proceed without the operator authorizing the re-block.

## CLOSED — `live-routing-and-economic-enforcement` (declared 2026-08-05; closed 2026-08-06 by the archivist)

- **Packet id (CLOSED):** `PACKET-0053-live-enforcement` — minted; 0 commits/0 files before this edit.
- **Lane:** `substantive`. **Depth 2.** Routing receipt issued before building:
  `routing-PACKET-0053-live-enforcement-20260805T222530Z.md`, gravito_full via honest value
  factors high_blast_radius (the hook touches how every session executes) + high_rework_history.
- **Branch base:** at `89d67df` — the pushed tip (rotation #5 applied; headroom 41,797 B).
- **Objective (operator directive):** turn the post-run routing/budget audit into an
  always-present execution control plane that can intervene WHILE work happens. Seven required
  capabilities: (1) mandatory routing entry — a substantive task cannot execute without routing;
  (2) an automatic routing hook replacing file-only instruction; (3) live resource visibility
  (exact telemetry vs estimates labeled separately); (4) fan-out throttling at budget threshold;
  (5) automatic Full→Light degradation that stops the expensive mode, not the task;
  (6) cost attribution by layer (task/context/subagent/verification/review/governance/audit);
  (7) marginal-contribution tracking per Full agent. Eleven required tests, red-driven.
- **Honest-scoping rule (standing):** mechanical where a check can execute — the .claude/hooks
  layer CAN observe and BLOCK tool calls live (PreToolUse exit-nonzero refuses the call), so
  dispatch counting, receipt-presence gating, and fan-out throttling are genuinely live-
  enforceable; token/cost live values are NOT hook-visible in interactive sessions and are
  labeled estimates-or-close-time wherever that is true. No checkbox that looks enforced and
  is not. Direct stays near-zero overhead — always observing, not always ceremonious.
- **Out of scope:** benchmarks, EXP re-runs, broad governance, memory files beyond the packet's
  own receipts. No push without go.

## CLOSE RECORD — `gravito_live_enforcement_a` (`PACKET-0053-live-enforcement`) — closed 2026-08-06 by the archivist. NOTHING IN FLIGHT.

- **Packet id (CLOSED):** `PACKET-0053-live-enforcement`. Receipt:
  `build-os/receipts/gravito_live_enforcement_a.md`. **Lane:** `substantive`.
  **Depth 3, announced** — build; qa ‖ reviewer concurrently; one bounded fix round
  (`fix-then-pass`, 2 enumerated items). Base `89d67df` (the pushed tip), re-verified at
  close (`git merge-base 61503fa 89d67df` → `89d67df`), tree quiet at `61503fa`.
- **Commits:** `aa0c968` (declaration + gravito_full routing receipt via
  high_blast_radius + high_rework_history) + `dda0dea` (build; same-commit registration,
  census 121→126) + `61503fa` (the one permitted fix commit — amended twice
  pre-measurement, message typo then an 8-citation +5 anchor shift re-pointed by content
  verification, disclosed).
- **WHAT SHIPPED — four labeled enforcement layers.** MACHINE-BEFORE-EXECUTION:
  `.claude/hooks/routing-gate.sh` (PreToolUse Task|Agent) — receipt-presence gate, depth
  enforcement, fan-out throttle AT the budget BEFORE the dispatch executes,
  process-allowance ledger (default **7 = the mandatory_full_regate chain, DERIVED** —
  the 0050/0051 calibration question resolved), auto-stamped degradation via
  `record-degradation.sh` ("Stop the expensive mode, not the task"), every decision
  logged (stderr fallback when the store is unwritable). MACHINE-AT-CLOSE:
  `routing-check.sh` extended, never forked — CONTRIBUTION-MISSING, STATE-DISAGREE
  reported never reconciled, seven attribution layers, old receipts pass as `-`
  admissions. PROTOCOL-DURING: context minimization + token awareness, labeled.
  NOT-YET-ENFORCED, named: live tokens/cost hook-invisible interactively
  (`unavailable_live`, never estimated-as-exact); non-dispatch work ungated beyond
  receipt presence + counting; unhooked sessions ungated; the residual no-trace vector
  (store unwritable AND stderr discarded).
- **Gates:** qa GREEN — suite **2677/0 solo** with per-suite delta arithmetic; commit-1
  iso **2545/0 at `aa0c968`** + **2677/0 at `dda0dea`**; the hook driven through every
  branch with qa's own fabricated stdin — all seven behaviors confirmed incl FAIL-OPEN
  and DISABLED-BY-OPERATOR logging; backward compat proven on real pre-0053 receipts;
  settings wiring valid, prior hooks preserved; overhead re-measured **27 ms/call** vs
  the 250 ms bound; census **126**, mismatches **24**, gate-on-advise unchanged **14**,
  README refs **440 derived**; frozen surfaces intact; hook safety scrutiny clean.
  Reviewer **fix-then-pass on TWO items**, both fixed in `61503fa` (allowance 4→**7**,
  derived from the doctrine's largest legal chain, RT9 driving the 7-dispatch regate
  shape and blocking the 8th; the unwritable-store no-trace vector — stderr fallback +
  the residual vector named in layer 4). Targeted confirmation: gate suite 132/0,
  registry suite 180/0, scan-controls 0, FULL SUITE **2677/0 solo at `61503fa`** →
  **PASS-AS-FIXED**. Second eyes NONE (Codex 403 at proxy, both gates attempted and
  stated). `DC-0001` numeral moved **32 → 33** in this close commit, derived from the
  receipt store.
- **Live routing receipt closed:** `executed_mode: gravito_full` (matches selected; no
  escalation); consumption fields stay `-` with the transcript-only admission;
  `consumed_process_dispatches` stays `-` — NOT derivable: the counting hook loads at
  next session start, so no `live_state/` file exists for this packet. Post-fill sweep
  `routing-check.sh check` = 4 receipts, 0 violations, exit 0.
- **GOES LIVE AT NEXT SESSION START — AND THE FIRST DISPATCH WILL BE BLOCKED, BY
  DESIGN.** With this receipt's `executed_mode` filled, NO routing receipt remains
  open; the next session's FIRST substantive dispatch will be REFUSED until it issues a
  routing receipt via `build-os/tools/route-task.sh`. That is mandatory routing entry
  working, not a malfunction — the refusal message carries the recovery command.
- **Boundaries:** NOTHING PUSHED — `aa0c968`, `dda0dea`, `61503fa`, and this close
  commit local pending explicit operator go (4 commits ahead of origin after this
  close, derived from git); none may be amended. No merge, deploy, or secrets.
  `residue.md` stays frozen (blob `01517ad2…`). **NOTHING IS IN FLIGHT; NOTHING IS
  STAGED** — the operator's directive ends with "complete the bounded build, report the
  evidence, and stop for the next product decision." Staging is a routing act, and the
  archivist takes none.

## IN FLIGHT — `universal-task-entry-governance` (declared 2026-08-06)

- **Packet id (CLOSED):** `PACKET-0054-universal-task-entry` — minted; 0 commits/0 files before this edit.
- **Lane:** `substantive`. **Depth 2.** Routing receipt issued before building:
  `routing-PACKET-0054-…-20260806T002034Z.md`, gravito_full (high_blast_radius +
  high_rework_history — this gate will govern EVERY session's mutation-capable tool use).
- **Branch base:** at `ef36c42` — the pushed tip (PACKET-0053 published under ruling).
- **Objective (operator's product decision — the narrow 7-item correction):** close the gap
  the operator named: "live dispatch governance completed; universal task-entry governance
  still incomplete." (1) An execution-start boundary for EVERY substantive task including
  parent-only work; (2) an active routing record required before any MUTATION-CAPABLE tool
  use (Edit/Write/NotebookEdit/Bash), not only Task|Agent; (3) exploratory reads
  (Read/Grep/Glob and read-only inspection) distinguished from execution — counted, ungated;
  (4) all tool activity and eventual provider telemetry bound to the task record;
  (5) long/repetitive parent-loop detection that forces reassessment (block-with-reroute,
  estimate-tier token proxy honestly labeled ESTIMATE); (6) the hook contract expressed as a
  PROVIDER-ADAPTER contract with the Claude hooks as its first adapter, labeled; (7) live
  token/cost as an adapter capability with honest fallback tiers where exact telemetry is
  absent. DEADLOCK GUARD is a hard requirement: the routing tools themselves (route-task /
  mode-select / routing-check / record-degradation) must pass ungated (logged) or no session
  could ever issue the receipt its first Edit requires.
- **Frozen:** bench/, all EXP trees, metrics store; no push without go; nothing beyond the
  seven items — the real-repository pilot is the NEXT step after this closes, not this packet.

## CLOSE RECORD — `gravito_universal_task_entry_a` (`PACKET-0054-universal-task-entry`) — closed 2026-08-06 by the archivist. NOTHING IN FLIGHT.

- **Packet id (CLOSED):** `PACKET-0054-universal-task-entry`. Receipt:
  `build-os/receipts/gravito_universal_task_entry_a.md`. **Lane:** `substantive`.
  **Depth 3, announced** — build; qa ‖ reviewer concurrently; one bounded fix round
  (`fix-then-pass`, 1 enumerated item), targeted re-review at that item only. Base
  `ef36c42` (the pushed tip), re-verified at close (`git merge-base HEAD
  origin/claude/project-handoff-merge-ramhds` → `ef36c42`), tree quiet at `d30be0c`.
- **Commits:** `725c6a4` (declaration + gravito_full routing receipt via
  high_blast_radius + high_rework_history) + `22f6bb3` (build, 14 files +922/−32;
  same-commit registration, census 126→128) + `d30be0c` (the one permitted fix commit —
  prose-only, 1 file +18/−4, no hook lines shifted, no anchors re-pointed). Per-commit
  numstat sums 16 paths +1022/−36; union `ef36c42..d30be0c` 16 files +1018/−32 —
  reconcile exactly (4 build-commit lines rewritten within-range by the fix).
- **WHAT SHIPPED:** the universal task-entry boundary — mutgate on
  `Edit|Write|NotebookEdit|Bash` (an active routing record before ANY mutation-capable
  tool use, parent-only work included); the DEADLOCK GUARD with its breadth honestly
  stated (substring over the ENTIRE raw hook JSON, `ROUTING-TOOL-PASS`, sole ungated
  pass, deliberately not narrowed — narrowing could block the recovery command itself);
  explore/execute split (reads counted, ungated); fire-once parent-loop reassessment
  (estimate-tier token proxy labeled ESTIMATE, reset gated on
  change-since-arming-snapshot); provider-adapter contract
  (`build-os/memory/provider_adapter_contract.md`, Claude hooks first adapter, Codex row
  interface-unverified); live token/cost as adapter capability with honest fallback tiers.
- **Gates:** qa GREEN — FULL SUITE **2801/0 exit 0 solo** (= 2677 + 124, the new
  `tests/routing_task_entry_tests.sh`); commit-1 iso **2677/0** in a detached worktree at
  `725c6a4`; safety grep clean (the single `rm -rf` hit is the suite's own mktemp cleanup
  trap, `tests/routing_task_entry_tests.sh:841`); census **128**, 0 unregistered/phantom,
  mismatches **24** declared=reported, gate-on-advise **14**, evidence_refs **451** =
  README; backward compat 5 live receipts / 0 violations; overhead mutgate ALLOW ~50 ms,
  BLOCK ~30 ms vs the 250 ms bound; frozen surfaces untouched (`bench/`,
  `build-os/experiments/`, `build-os/metrics/`). Reviewer **fix-then-pass on ONE item**,
  fixed in `d30be0c` (`routing_contract_live.md` understated the deadlock guard's
  breadth — now states full breadth, the mislabel audit-read instruction,
  sole-ungated-pass status, and the non-narrowing rationale); targeted re-review: pass →
  **PASS-AS-FIXED**. The reviewer's optional `mut_classify` reorder DECLINED with stated
  reason (brick: the blocked command would BE the recovery command); reviewer validated
  and withdrew it. NOTABLE: builder's limitation 4 (pre-armed escalation resolves first
  trip) TESTED AND REFUTED by the reviewer — recorded refuted, not open. Residual future
  scope, not a defect: `ROUTING-TOOL-PASS` rows carry no command text; ledger-level
  disambiguation is a future packet. Second eyes NONE (Codex 403 at proxy — stated, not
  pretended). `DC-0001` numeral moved **33 → 34** in this close commit, derived from the
  receipt store.
- **Live routing receipt closed:** `executed_mode: gravito_full` (matches selected; no
  escalation); `consumed_process_dispatches: 5` — TRANSCRIPT-DERIVED, CLOSE-TIME tier,
  never a hook-measured EXACT count (builder 1 + qa 1 + reviewer 1 + targeted re-review
  resume 1 + archivist 1 = 5, within allowance 7; this session's hooks are NOT loaded, so
  no `live_state/` file exists to corroborate or contradict); all other consumption `-`,
  honest admissions.
- **SELF-APPLICATION — TWO NOTES BINDING ON THE NEXT SESSION.** (a) From next session
  start, `live_gate_log.tsv` and `live_state/*.tsv` accrue as UNTRACKED ledgers — future
  packets must declare them packet-expected-unstaged at tree-quiet checks. (b) This close
  leaves NO open routing receipt, so the next session's FIRST mutation-capable call WILL
  BE BLOCKED by the new mutgate until it routes — mandatory task entry working by design;
  recovery is one `build-os/tools/route-task.sh` command.
- **Boundaries:** NOTHING PUSHED — `725c6a4`, `22f6bb3`, `d30be0c`, and this close
  commit local pending explicit operator go (4 ahead of origin after this close); none
  may be amended. No merge, deploy, or secrets. `residue.md` stays frozen (blob
  `01517ad2…`). **NOTHING IS IN FLIGHT; NOTHING IS STAGED** — the real-repository pilot
  is the operator's next product decision, and staging it is a routing act the archivist
  does not take.

## IN FLIGHT — `structured-routing-action` (declared 2026-08-06)

- **Packet id:** `PACKET-0055-structured-routing-action` — minted; 0 commits/0 files before this edit.
- **Lane:** `substantive`. **Depth 2.** Routing receipt issued before building:
  `routing-PACKET-0055-structured-routing-action-20260806T015246Z.md`, selected_mode
  gravito_full, binding.
- **Branch base:** at `e293e75` — PACKET-0054's close, re-verified before this edit
  (`git merge-base HEAD e293e75` → `e293e75`), tree quiet.
- **Objective (operator ruling — the deadlock guard's substring breadth is "a real
  enforcement bypass, not merely a wording issue"; harden BEFORE the real-repository
  pilot):** (1) replace the substring-based routing exception with a STRUCTURED
  ROUTING ACTION — the ungated pass applies only to an exactly-recognized routing
  invocation extracted from the actual `tool_input.command` field, matched whole
  against a strict single-invocation pattern with no chaining/substitution
  metacharacters, extraction failure falling toward GATING, never toward an ungated
  pass; (2) fingerprint every ROUTING-TOOL-PASS record (which tool, sha256 first
  12 hex chars of the exact command, sanitized ≤80-char TSV-safe excerpt) in both
  ledgers; (3) preserve a recovery path that cannot carry unrelated mutations,
  proven end-to-end from the refusal's own text; (4) test the attack shapes
  (compound commands, comments, non-command-field mentions, sh -c/eval quoting,
  command substitution, newline injection, mutation hidden behind a legitimate
  prefix) AND the legitimate invocation set explicitly; (5) prove store-unavailable
  is not a brick. Plus: rewrite the DEADLOCK GUARD bullet in
  `routing_contract_live.md` to the structured action with the NEW honest bounds
  named, and re-point every registry anchor into routing-gate.sh in the same
  commit, content-verified (RULING 4 — burned twice already).
- **Frozen:** bench/, build-os/experiments/, build-os/metrics/ (the close-time
  metrics row is the archivist's, not this packet's), build-os/memory/residue.md
  (blob `01517ad2…`). No push/merge/deploy/secrets without explicit operator go.
