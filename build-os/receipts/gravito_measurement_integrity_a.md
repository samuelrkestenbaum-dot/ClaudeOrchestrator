# Receipt — `gravito_measurement_integrity_a`

- **Packet id (canonical):** `PACKET-0036-measurement-integrity`
- **Date:** 2026-08-03
- **Lane:** `substantive`. **Depth: 3 serial stages** — builder; qa ‖ reviewer
  concurrently; one bounded seven-item fix round. **No stage 4.**
- **Base:** `a2648dc` — re-verified at this close, not accepted from the brief:
  `git merge-base aa0a7b3 a2648dc` returns
  `a2648dc017a413c6b7e2273f80dfc43693a9dc22`.
- **HEAD at close:** `aa0a7b3`, on `claude/project-handoff-merge-ramhds`.
- **Verdict: PASS-AS-FIXED.** qa returned **GREEN**; the reviewer returned
  `fix-then-pass`; every item was fixed in `aa0a7b3` and verified by the
  orchestrator rather than by opening a fourth gate stage.
- **Second eyes: NONE, single-model — FOURTEENTH CONSECUTIVE PACKET.**
- **THIS RECEIPT CITES BY CONTENT, NOT BY POSITION.** No `path:line` token and no
  `path:N-M` range is written anywhere below, deliberately: this is a packet
  about measurement substrates that lie, and a range citation written here is
  swept tree-wide by the registry suite's range check and starts decaying the
  moment any cited file grows. Every reference names the object or quotes the
  literal. The discipline is held **by hand** — receipts sit outside the fraction
  of the corpus the anchor scheme covers.

---

## THE HEADLINE — THE DISCREPANCY WAS FIXTURE, NOT LOAD, AND THE GENERALISATION IS THE PACKET'S MOST IMPORTANT OUTPUT

Two measurements of the same defect disagreed — **6.26% and 15.70%** — and the
reconciliation is not "one of them was wrong" and not "one machine was busier".
qa ran a controlled A/B: same machine, same load, same code, **only the data
store swapped**.

| store | rows | bytes awk emits | bytes past the 64 KiB buffer | false verdicts |
|---|---|---|---|---|
| the store as of `727de75` | 17 | 68,734 | 3,198 | 301 / 4000 = **7.53%** |
| the store as of `a2648dc` / HEAD | 18 | 72,147 | 6,611 | 582 / 4000 = **14.55%** |

**The store grew by ONE ROW and the failure rate doubled.**

> **The rate of a latent non-determinism is a function of a data volume nobody is
> watching.**

That is precisely the blind spot the new guard declares about itself, arriving
from the other direction — and it is the strongest argument in the packet:
**a site measured at 0% today can flap tomorrow with no code change, no new
commit, and no test turning red.** A green measured on a small fixture is not a
statement about the code; it is a statement about the fixture the code was
measured on.

---

## THE PACKET ID WAS COLLISION-CHECKED **BEFORE** THE MINT, AND THE ARCHIVIST RE-CHECKED IT RATHER THAN ACCEPTING THE CLAIM

The builder claimed a pre-mint collision check. **That claim was independently
re-derived at this close**, because this check has caught a bad id at prior
closes and a claim about a check is not the check:

- `git log -S'PACKET-0036' --oneline a2648dc` — **no commit**. The token appears
  nowhere in the base's history.
- `git grep -n 'PACKET-0036' a2648dc` — **no hits**. The token did not exist in
  the base tree.
- `git log -S'PACKET-0036' --all --oneline` — **exactly two commits**, both this
  packet's own (`0cdb3b7` and `53b92d4`). Nothing else has ever held it.
- `git grep -ho 'PACKET-00[0-9][0-9]' HEAD | sort -u` — the live band is
  contiguous `PACKET-0001`..`PACKET-0036`; the highest allocation predating this
  packet is `PACKET-0035`.

**The id was free. It was minted, not reused, and the mint preceded the build.**

---

## Scope

**In:**

1. **Fix `DEFECT-0013`** at its site — a `pipefail`/SIGPIPE race in which a
   producer is killed while an early-exiting consumer is still being read, and
   the 141 becomes the pipeline's status — **without disabling `pipefail`** for a
   file that is load-bearing elsewhere.
2. **Sweep the class**, not just patch the site, across `tests/`, `build-os/` and
   `.claude/hooks/`.
3. **Prove the fix by measurement** at ≥4000 iterations before and after, both
   rates reported. "It passed once" is not evidence in this tree.
4. **Add a guard for the class** in an existing suite, and state plainly what the
   guard **cannot** see.
5. **Rule, either way, on whether one green suite run is sufficient evidence
   again.**
6. **Declare the packet before building it**, repairing the previous packet's
   `DEFECT-0011` recurrence — `bandwidth` went **0 → 1 packet in flight,
   ceiling 1**.

**Why the packet existed at all, and it is not test hygiene.** The project's next
frontier is **experience**: running
`ranking → selection → execution → outcome → memory → comparison` repeatedly.
That loop's payload is **comparison**, and **a measurement substrate that
manufactures false verdicts poisons the outcome store the executive will train
on.** This packet closed `DEFECT-0013` *before* the loop starts accumulating
outcomes rather than after.

**Out (explicit, and none of it was touched):**

- **The inverted-polarity counterexample site** in
  `tests/build_os_maintenance_tests.sh` — outside this packet's file ownership.
  Recorded, measured, **not fixed**.
- **`build-os/metrics/rank-candidates.sh`**, `signal_snapshots.tsv`,
  `decision_telemetry.tsv` — the live experiment's sealed surface.
- **Any row rewrite in the kernel event ledger.** Corrections create later
  events.
- **All open residue.** `(ddd)` stays queued; `(uuuu)` stays open; nothing else
  was repaired.
- **Widening the guard's kill-pattern list** to enumerate `awk '…exit'` —
  widening a pattern is a behaviour change; a comment naming the two live sites
  was taken instead.
- **Re-granularising the guard's allow-list** from file to site — deliberately
  declined, because site-granularity reintroduces positional coupling.

---

## Commits, and the file-ownership manifest

Three commits against the `≤2` cap. **That is a deviation and it is recorded as
one below**, not normalised.

- **`0cdb3b7`** — *docs(packet): declare `gravito_measurement_integrity_a` before
  building.* 2 files, **+126 / −10**.
- **`53b92d4`** — *fix(tests): a guard may not report FAIL from its own plumbing —
  `DEFECT-0013` closed.* 11 files, **+350 / −13**.
- **`aa0a7b3`** — *fix round: the one-directionality claim was false as a class
  claim, and six figures could not be re-derived.* 7 files, **+292 / −73**.

**FILE-OWNERSHIP MANIFEST — A SEQUENTIAL ATTRIBUTION BY ROLE, NOT A DISJOINT
PARTITION.** Three serial passes by one agent, so the sets overlap by design.
This is legitimate for serial work and is **not a precedent for a fan-out**,
where disjointness is the licence.

| commit | role | writable set (paths, by content not position) |
|---|---|---|
| `0cdb3b7` | declaration | `build-os/packets/active_packet.md`; `build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md` (projection **regenerated**, never hand-edited) |
| `53b92d4` | the fix, the sweep, the guard | `tests/speed_benchmark_tests.sh`, `tests/build_os_tests.sh`, `tests/control_registry_tests.sh`; `build-os/registry/control_registry.txt`, `defect_classes.txt`, `MISMATCHES.md`, `README.md`; `build-os/memory/current_state.md`, `residue.md`; `build-os/packets/active_packet.md`; `CHANGELOG.md` |
| `aa0a7b3` | the fix round — claims and comments only, no behaviour change | `tests/speed_benchmark_tests.sh`, `tests/build_os_tests.sh`; `build-os/registry/control_registry.txt`, `defect_classes.txt`; `build-os/memory/residue.md`; `build-os/packets/active_packet.md`; `CHANGELOG.md` |

**Overlap, stated rather than implied:** `0cdb3b7` and `53b92d4` share **1** path;
`53b92d4` and `aa0a7b3` share **7**.

### THE TWO DIFF CONVENTIONS DISAGREE, AND BOTH ARE RECORDED

`record-packet.sh --verify-git` computes **PER-COMMIT SUMS** — it runs
`git show --numstat` over the named commits and adds the columns, counting a path
once but its churn once per commit. It does **not** compute the net union diff. A
net-diff row was **refused at the last close**, so the definition is written down
here rather than left to be rediscovered:

- **PER-COMMIT SUMS (what the verifier checks, and what the metrics row states):**
  `git show --numstat --format='' 0cdb3b7 53b92d4 aa0a7b3` summed →
  **12 distinct paths, +768, −96**.
- **NET UNION DIFF (a different, also-true number):**
  `git diff --numstat a2648dc aa0a7b3` summed →
  **12 distinct paths, +699, −27**.
- **The gap is 69 lines on both sides**, and it is exactly the overlap: lines the
  fix round rewrote that the build commit had already written. The path count is
  the same 12 under both conventions because no path was created and deleted
  inside the range.

---

## QA PROOF BLOCK — EXACT COUNTS, EVERY ONE DERIVED

- **Suite: `bash tests/build_os_tests.sh` → 2103 passed, 0 failed, exit 0.**
  **Two SOLO full-capture runs by the builder at the committed tree** (plus two
  earlier), and **three by qa** at `53b92d4`. `grep -c '^  FAIL'` = **0**
  throughout, and the **per-suite CHAINED verdict vector was byte-identical
  across runs** — the vector, not merely the total.
- **Delta +7**, all of it the new section 28 of `tests/build_os_tests.sh`.
  `tests/speed_benchmark_tests.sh` **held at 169** — the packet **converted**
  three assertions rather than adding any, and **no assertion was lost**.
- **Commit-1 green in isolation at `0cdb3b7`: 2096 / 0, in a fresh clone.**
- **Live gate: `RELEASE_METADATA_LIVE_SUITE=1` MATCH at 2103.**
- **Maintenance: `bash build-os/maintenance/run-tests.sh` → 144 / 0.**
- **`scan-controls.sh check` → exit 0.** Census **105**
  (`grep -c '^control: ' build-os/registry/control_registry.txt`), **22 declared**
  mismatches, **gate 14 / execute 8**, identical at base and at HEAD.
  **0 `+control` lines in the range — NO NEW CONTROL.**
- **`scan-controls.sh anchors` → 12 resolved / 1 superseded / 0 violations.**
- **`memory-kernel reconcile` → 1 projection checked, 0 divergent.**
- **`evidence_refs` 372 → 374, BY DERIVATION not by memory** — the registry
  README's stated total is recomputed from the registry by the control-registry
  suite and fails if any stated total disagrees.
- **Zero re-authorisations, field-anchored.**

### CLOSE GATES — RE-RUN AFTER THE ARCHIVIST'S WRITES, SEQUENTIALLY, TWICE, NEVER THROUGH `tail`

`pgrep -fa '^bash tests/'` was anchored **empty before every run**, and HEAD held
at `aa0a7b3` throughout. Exit codes were read from the command's own status, never
from a pipeline's.

| gate | pass 1 | pass 2 |
|---|---|---|
| `bash tests/build_os_tests.sh` | **2103 / 0, exit 0** | **2103 / 0, exit 0** |
| `grep -c '^  FAIL'` | **0** | **0** |
| chained suites reporting `[1-9]… failed` | **none** | **none** |
| chained verdict **vector** | — | **byte-identical to pass 1** |
| `build-os/maintenance/run-tests.sh` | **144 / 0, exit 0** | exit 0 |
| `RELEASE_METADATA_LIVE_SUITE=1` release-metadata | **44 / 0, exit 0** | exit 0 |
| `scan-controls check` / `anchors` | exit 0 / exit 0 | exit 0 / exit 0 |
| `memory-kernel validate` / `reconcile` | exit 0 / **1 projection, 0 divergent** | exit 0 / exit 0 |
| `check-adoption` | exit 0 | exit 0 |
| `bandwidth-check check` | exit 0 | exit 0 |
| `record-packet --verify-git` / `--validate` | exit 0 / exit 0 | exit 0 / exit 0 |
| `scan-mutators check` | — | exit 0 |

**THE LIVE CROSS-CHECK MATCHED AT 2103** and it is a three-way match, not a claim:
*"CHANGELOG reports the same suite total (2103 passed) as `current_state.md`"* and
*"live suite total (2103 passed) matches `current_state.md`'s claim (2103)."*
**`CHANGELOG.md` needed no edit** — the builder had already written the unsplit
literal, and this close changed no assertion, so the total did not move.

**`bandwidth` reads `0 packet(s) in flight, ceiling 1` (enforced: gate)** after the
close — the declaration marker was demoted, so the guard's reading is true of the
world again. It also reports **`commits EXCEEDED — 3 since the declared base
a2648dc, ceiling 2`** at **advisory** severity: *reported, not refused*. That is
the deviation recorded above, showing up in the instrument rather than only in
prose.

**ONE GATE WENT RED AT THIS CLOSE AND THE CAUSE WAS THIS CLOSE.** The first
maintenance run returned **exit 1, 4 subtests failed** —
`SIZE CEILING EXCEEDED for build-os/memory/residue.md: measured 209126 B > ceiling
204800 B`. **The archivist's own first-draft residue was +7,934 B against 3,608 B
of headroom.** It was rewritten to **+3,466 B**, and the gate returned **144 / 0**.
**Nothing was silenced and no ceiling was raised.** The underlying condition is
recorded as `(yyyyy)` and is the most actionable item this close produced.

### THE FIX, MEASURED — AND MEASURED AGAIN UNDER EVERYTHING THROWN AT IT

| form | iterations | conditions | false verdicts | rate |
|---|---|---|---|---|
| shipped, `datarows \| awk \| grep -q .` | 4000 | quiet (qa) | 613 | **15.33%** |
| shipped, same site | 4000 | quiet (builder) | 628 | 15.70% — **within 1σ of qa** |
| **fixed**, `… \| any` | 4000 | quiet | **0** | **0.0000%** |
| **fixed** | 4000 | 4-way CPU load | **0** | **0.0000%** |
| shipped | 4000 | 4-way CPU load | 1704 | **42.60%** |
| amplified fixture, 217,972 B | 2000 | — | 100% before | **0 after** |

**`pipefail` STAYS ON** — the file enables it and **nothing anywhere turns it off**
(`grep -c 'set +o pipefail' tests/speed_benchmark_tests.sh` = **0**). **The
consumer was made to drain instead**:

```sh
any(){ awk 'BEGIN{r=1} {r=0} END{exit r}'; }
```

There is **no `exit` in a main rule**, so it reads to EOF under *any* awk. qa
could not make it exit early with a **33.9 MB** stream, a **64 MB single record
with no newline**, **NUL bytes**, or **invalid UTF-8**. **All three converted
assertions were driven red and still fail correctly** — the conversion did not
buy determinism by making the assertions unable to fail.

### THE FIX CARRIES NO AWK-IMPLEMENTATION DEPENDENCY

At the empty-cell assertion the builder **removed the `exit`** rather than
relying on mawk happening to drain. The guard's allow-list is therefore keyed on
**measured bytes**, not on which awk is installed. **A gawk or busybox image
breaks neither the fix nor the guard.** That distinction is the difference
between a repair and a coincidence.

### SEALED-EXPERIMENT INVARIANTS, RE-DERIVED AT THIS CLOSE

- **S1 report digest** `e838284e2bba52628647d0c7ddd1ed258a7aab7cc391a5ac99992ad7584eb596`
  — **unchanged**, recomputed live at this close by piping the S1 rank report for
  `DECISION-0011-p5b-next-after-p3b` through `sha256sum`.
- **`rank_of_selected: 1` still derives**, exit 0.
- **PRECISION WORTH RECORDING, BECAUSE TWO DIGESTS ARE IN PLAY AND THEY ARE NOT
  THE SAME OBJECT:** the report's own internal `ranking_digest` line reads
  `db96737e713b10d6…`; `e838284e…` is the sha256 of the **whole report**. A
  future reader comparing the wrong one will conclude the seal broke when it did
  not.
- **`rank-candidates.sh` is the same blob `5543ea8` at base and at HEAD**
  (`git rev-parse --short a2648dc:… aa0a7b3:…`).
- **`signal_snapshots.tsv` and `decision_telemetry.tsv`: zero diff** across the
  range.
- **`memory_events.tsv`: the base file is a BYTE-EXACT PREFIX of HEAD's** — no
  rewritten row — and in fact **zero diff**: no event was appended either. The
  prefix check is stated because it is the property that matters and it is
  stronger than "the diff was small".

---

## Reviewer verdict — `fix-then-pass`, and what the fix round actually corrected

The reviewer passed the mechanism and refused the **claims written around it**.
Seven corrections landed in `aa0a7b3` with **no behaviour change, no assertion
added or removed, and the suite total unmoved at 2103**.

### 1. THE CLAIM THAT WAS FALSE — AND IT HAD ALREADY PROPAGATED

Committed in **three live files**:

> *"It is ONE-DIRECTIONAL — it can manufacture a false FAIL and can never mask a
> real one."*

**False as a class claim.** qa measured the counterexample: an assertion in
`tests/build_os_maintenance_tests.sh` with **inverted polarity** —
`find … | grep -q . && no "…" || ok "…"` — where a SIGPIPE 141 routes to **`ok`**.
That is **a false PASS masking a real failure.** At **270,890 B** the construct
returned non-zero **2000 / 2000**; draining, **0 / 2000**.

Corrected verbatim in all three files:

> **ONE-DIRECTIONALITY IS A PROPERTY OF THE `&& ok || no` POLARITY, NOT OF THE
> CLASS: at that polarity the race can only manufacture a false FAIL, but
> INVERTED — `producer | grep -q . && no || ok` — the same 141 routes to `ok` and
> the identical race yields a FALSE PASS that masks a real failure.**

**THE BUILDER FOUND THE THIRD LIVE COPY ITSELF.** Section 28 of
`tests/build_os_tests.sh` was **not named in the orchestrator's fix brief**. The
builder found it and corrected it, on its own reasoning that correcting two of
three *"would have been `DEFECT-0003` in the same commit."* **Record that: it
declined to create duplicate semantic truth inside the packet fixing a truth
defect.** That is the behaviour a fix round is supposed to produce and it is
rarely visible in a diff.

**THE PROPAGATION, RECORDED HONESTLY BECAUSE THE ORCHESTRATOR IS THE ONE WHO
PROPAGATED IT.** *"Every green stands, the defect can only fake failure"* was
relayed to the operator **twice** on the strength of the false claim.
**The greens do still stand — but for a different reason than the one given.**
They stand because that counterexample is **unreachable**: it needs >64 KiB, about
1,100+ leftover paths, in a directory the test expects to be **empty**. They do
**not** stand because the class cannot mask failures. The site is also **invisible
to the new guard**, its producer being `find`. **Recorded, not fixed** — outside
this packet's ownership.

### 2. "5/5" WAS WRONG, AND THE CORRECTION STRENGTHENS THE CONCLUSION

The consumer-lethality figure held for only two of five consumers and rested on
**n = 5**, which cannot distinguish 8% from 100%. Re-measured at **N = 200**:

| consumer | false verdicts / 200 |
|---|---|
| mawk `exit` | **0 (0.0%)** |
| `grep -q .` | 8.0% |
| `grep -m1 .` | 9.5% |
| `head -1` | 52.5% |
| `sed -n '1p;1q'` | 100% |
| bare `read` | 5/5 (small-n, reported as such) |

**The conclusion is unchanged and *strengthened* by the 0/200:** mawk's `exit` is
uniquely non-lethal, which is exactly why **draining** is the right fix rather
than swapping one early-exiting consumer for another.

### 3. THE SCANNER'S REACH, AND A "FUTURE" BLIND SPOT THAT IS PRESENT TODAY

The scanner scopes **45 of 54** `pipefail`-enabling files. The nine outside its
roots are now enumerated, and **four of them already carry `set -euo pipefail`** —
so the case the packet recorded as a **FUTURE** blind spot **is present TODAY**.
Corrected to *"already present, measured harmless"*: the same patterns run over
all 54 files yield **the same 3 hits, all allow-listed**.

### 4. THE ALLOW-LIST IS FILE-GRANULAR, AND THE FILE THAT SHIPPED THE DEFECT IS WHOLESALE EXEMPT FROM THE GUARD AGAINST IT

The allow-list matches the **whole path**, while its comment read as if it were
per-pipeline. Demonstrated rather than asserted: a **new racy line added to
`tests/speed_benchmark_tests.sh` is ALLOWED**, and the **identical line in
`tests/entitlement_tests.sh` is REPORTED**. **Left file-granular deliberately** —
site-granularity would reintroduce the positional coupling this tree spent a
packet shedding — and **now disclosed in the guard's own blind-spot list** rather
than discovered later.

### 5. THE KILL-LIST DOES NOT ENUMERATE `awk '…exit'`

A comment was chosen over widening the pattern, because widening is a behaviour
change. It names the two live sites in `build-os/metrics/check-adoption.sh`, which
run the store's data rows over a **72,754-byte** store under `pipefail` and
**would race under gawk**. They are unexposed today only because all three call
sites capture the **value** (`row="$(...)"`) and test `-n`/`-z`, with no `set -e`.

### 6. TWO FIGURES WITHDRAWN RATHER THAN RESTATED

- *"235 candidate pipelines"* → **258 derived**. Withdrawn and replaced.
- *"~40 `sed … | head -N` dumps"* → **withdrawn entirely**: 13 strict, 87 for all
  `| head`. **Neither is 40.**
- **The load-bearing half holds and is derived:** **0 killer pipelines in the 3
  scripts carrying `set -e` + `pipefail`.**

Every retained figure now carries the command that reproduces it. That rule is
the packet's, applied to itself.

### 7. `any` IS WIDER THAN `grep -q .`

On blank-only input `any` returns 0 where `grep -q .` returns 1. **Unreachable at
all three call sites**, and now stated **with the reachability argument** rather
than left as an unexamined widening.

---

## THE GUARD — POWER DEMONSTRATED, NOT ASSERTED

Section 28 of `tests/build_os_tests.sh`, **7 assertions**: a red drive that
reproduces the race on an amplified fixture before any green claim is made, plus
a static scanner over the 45 in-scope files with a **measured** allow-list.

**qa independently stripped the `# sigpipe-scan-exempt` marker from the red-drive
line in a clone, and the guard reported its own line** — suite 2101/2, exit 1.
**The exemption is earned, not asserted.**

**DECLARED BLIND SPOTS, ALL CONFIRMED REAL BY qa's SNEAK TEST.** Five idioms
walked straight past the scanner:

1. `git log --oneline | grep -q .`
2. a function wrapping `cat`
3. `find /tmp -type f | grep -q .`
4. `cat "$BIG" | while read -r l; do break; done`
5. `grep -q . < <(emit_rows)`

**AND THE REPO CAUGHT qa.** The repository's own *"sibling suite present but never
chained"* control caught qa's planted file. **An independent integrity control
working, observed in the wild** — worth recording, because most of this file is
about controls that did not.

---

## THE EVIDENCE RULING — RECORD IT AS DOCTRINE

> **A single green run is again sufficient FOR THIS DEFECT. The doubled-run
> discipline STAYS IN FORCE.**

The builder's reasoning, which qa endorsed and sharpened, and which is the
durable part:

> **What was measured is that one NAMED non-determinism is gone. What would
> license dropping the discipline is that NO UNNAMED one remains — and nothing
> here measures that.**

Answering the second question with the first question's data is the exact
epistemic error the packet exists to correct.

**qa's criterion for retiring it, recorded so that retirement becomes a decidable
act rather than a mood:** not another assertion-level measurement, but a
**suite-level determinism measurement** — **N ≥ 200 consecutive full-suite runs at
a fixed commit**, quiet and under controlled load, with **ZERO variation in the
per-suite PASS/FAIL *vector*, not in the total** — plus a per-assertion harness
rerunning each assertion K times against frozen fixtures.

**Until the invariant is "the verdict vector does not move", the doubled run is
the only sampler in place. Retiring it is an operator act.**

---

## LINE-MOVEMENT DISCIPLINE — RECORD THE TECHNIQUE, IT IS REUSABLE

Two files needed opposite treatments and got them.

- **`tests/speed_benchmark_tests.sh` was held to a STRICT NET-ZERO LINE DELTA
  across the fix round — 712 lines in, 712 lines out** — so all **nine** inbound
  citations still resolve to the same content. (Across the whole packet it grew
  673 → 712; the *fix round*, the pass that would otherwise have broken the
  citations, moved nothing.)
- **`tests/build_os_tests.sh` genuinely grew** — 978 → 1106 at the fix commit →
  **1161** at HEAD — so its **four** inbound registry citations were re-pointed
  **BY CONTENT**: each new position was found by locating the cited text, not by
  adding the diff's line delta. The arithmetic is recorded in the fix commit
  message; it is deliberately not restated here, because a receipt that copies a
  position is a receipt that goes stale.
- **The registry suite's section 21 re-derives that membership from the tree** and
  passes, so the re-point is checked rather than trusted.
- **`ANC-0003` did not move**, so **no projection regeneration was needed** at the
  fix round. (It *did* move at the declaration commit, 15 → 40, and was repaired
  the sanctioned way — regenerated, never hand-edited.)

---

## AN ORCHESTRATOR ERROR, RECORDED BECAUSE THE CLASS KEEPS PROVING IT IS NOT RETIRED

While auditing this fix round, the orchestrator grepped for the corrected
one-directionality statement **on a single line** and concluded it was **missing
from two of the three files**.

**It was present in all three.** The statement **wraps across comment lines** —
`NOT OF THE` ends one line and `# CLASS` begins the next — and the single-line
pattern could not see it.

That is the **line-wrapped enumeration** escape form: **one of the five this tree
has already catalogued**, walked into **while auditing a packet about false
measurements**, by the agent auditing it. The finding is not that a grep was
imperfect; it is that **a catalogued escape form is still catching the people who
catalogued it**, which is evidence the class is live rather than historical.

---

## AN ARCHIVIST OBSERVATION — RECORDED AT ITS TRUE, SMALL WIDTH

The **first** `scan-controls.sh check` run of this close session reported
`PHANTOM tests/gate_depth_tests.sh`, **1 phantom entry**, and **REFUSED**. Every
subsequent run reported **0 phantom entries and exit 0**.

**It did not reproduce in 14 further attempts** — **8 quiet runs and 6 runs under
4-way CPU load, all `rc=0`, all 0 phantom lines.** The one anomalous run was the
only one executed **concurrently with another tool call**.

**This is recorded as an unreproduced single observation and NOT as a finding.**
No rate is claimed, no mechanism is claimed, and nothing was changed. It is
written down for one reason: this packet's own headline says a latent
non-determinism's rate is a function of conditions nobody is watching, and the
honest response to seeing one flicker is to **write down what was seen and what
could not be reproduced** — not to explain it, and not to delete it. A future
reader who sees the same line has a prior.

**THE PIPING TRAP THAT NEARLY MISREAD IT, WORTH ONE SENTENCE:** the first
observation was taken through `… | tail -15; echo "EXIT=$?"`, which reports the
exit status of **`tail`, not of the scanner** — the same "the shell told you about
the wrong process" family this whole packet is about. The true exit code was
obtained by capturing the command's own status. **Do not read a gate's verdict
through a pipe.**

---

## AND THIS CLOSE MOVED THE VERY QUANTITY THE HEADLINE IDENTIFIES — DERIVED, AND WORTH ONE SECTION

The headline says a **one-row** growth in a store doubled a false-verdict rate.
**Recording this packet appended the NINETEENTH row to that same store.**

Measured at this close rather than assumed:

- `wc -c < build-os/metrics/packet_metrics.tsv` → **72,754 → 73,992 bytes, +1,238**.
- data rows → **18 → 19**.
- By **arithmetic on qa's emitted-stream figure — arithmetic, not a fresh
  measurement, and labelled as such** — the margin past the 64 KiB buffer moves
  from **6,611 to about 7,849**, up roughly **19% in a single close**.

**Nothing is wrong now.** The site that raced drains; the two `check-adoption.sh`
sites capture the value rather than the pipeline status; mawk's `exit` measured
**0/200** at killing its producer.

**The point is that the trend is monotonic and nothing watches it.** Every close
adds a row. The quantity that decided a 7.53%-vs-14.55% difference is **the byte
margin past a pipe buffer**; it grows about 1.2 KB per close, with no ceiling and
no assertion; and **the new guard explicitly cannot see volume.** A site under the
buffer today crosses it on a commit that changes no code.

**Named, not built** — building it is a packet, not a close: an assertion that
**prints the emitted-stream size of the store's data rows and its margin against
65,536**. A printed number a reader can watch move, *not* a threshold that
refuses — a guard that goes red on an ordinary close gets disabled by the end of
the week. `(xxxxx)`.

---

## DEVIATIONS — RECORDED, NOT NORMALISED

- **3 commits against the `≤2` cap.** The same shape as the previous two closes:
  the fix round landed as its **own commit** rather than amending commits the
  gates had already measured. Amending was the wrong trade — the gates measured
  `53b92d4`, and rewriting it would have invalidated the proof to satisfy a
  counting rule. **The manifest above is the mitigation**, and it is a
  **sequential attribution by role, not a disjoint partition**.

---

## FINDINGS RECORDED, NOT FIXED

- **The inverted-polarity false-PASS site** in
  `tests/build_os_maintenance_tests.sh` — measured 2000/2000 at 270,890 B,
  0/2000 draining. **Latent, not live**, and **invisible to the new guard**
  because its producer is `find`. Outside this packet's ownership. `(qqqqq)`.
- **Five producer idioms walk past the static scanner**, verified by qa's sneak
  test rather than reasoned about. `(rrrrr)`.
- **The allow-list is file-granular**, so the file that shipped the defect is
  wholesale exempt from the guard against it. Deliberate; now disclosed.
  `(sssss)`.
- **What the doubled run is actually sampling, and what would license retiring
  it.** `(ttttt)`.
- **`(ppppp)` promoted to operator-facing as `(uuuuu)`.**
- **Pre-existing, out of scope, untouched:** the control registry's prose names
  one line of `tests/speed_benchmark_tests.sh` as a section-21 exclusion while
  the executable list in `tests/control_registry_tests.sh` names a different one.
  **No test reads the prose copy**, which is why it drifted.

---

## ROUTED TO THE OPERATOR — RECORDED, NOT ACTED ON

### 1. A CLOSED RECEIPT CARRYING A SINCE-FALSIFIED CLAIM HAS NO POINTER TO ITS CORRECTION

**The builder raised this and it is a good question, so it is recorded as a
design question rather than left as open-ended residue.**

Three copies of the **superseded** one-directionality claim survive in
**prior-packet records** — in the cross-surface-memory-kernel receipt, in
`residue.md`, and in `current_state.md`. The builder **did not rewrite them**, on
the correct rule that **a correction creates a later record; it does not edit an
earlier one.** That rule is right and this close upholds it: **no prior receipt
was touched.**

**But the consequence is real.** A reader arriving at that closed receipt **reads
the false sentence with nothing beside it.** The memory kernel already has
`supersedes` and `contradicts` relationship types — **and receipts do not
participate in them.**

> **The question for the operator: should receipts become first-class kernel
> objects that can be pointed at by a `contradicts` edge, so that a falsified
> claim in a sealed record is reachable from its correction without the record
> being rewritten?**

That is a design act on the kernel, and it is **not the archivist's to take**.

### 2. `(uuuuu)` — THE PROJECTION EMBEDS A RESOLVED LINE NUMBER AND SHOULD STOP

The memory kernel's export embeds a **resolved line number** inside a
**byte-compared** artefact, so **every content-preserving edit above any anchored
site ships red until a projection is regenerated.** The reviewer's ruling,
verbatim because it is the argument and not a summary of one:

> *"a byte-compared artefact that embeds a resolved line number, inside the
> mechanism whose stated thesis is that line numbers are not identity, is
> self-contradictory."*

**This packet paid that tax on its very first commit** — declaring the packet
moved `ANC-0003` from 15 to 40 and turned the suite red, with the identity half
never wrong (12 resolved / 1 superseded / 0 violations throughout) and only the
**projection** of that resolution stale. **The tax compounds as anchor coverage
grows past 3.5%.** The request is that this become a **cut packet**.

### 3. SECOND EYES — FOURTEENTH CONSECUTIVE PACKET

`codex` is absent; every verdict in this sequence is single-model. **The router's
second-eyes row still says the absence was checked at "the last nine packets".**
It is now **fourteen** — stale by five. **Nothing in the suite pins the literal**,
which is exactly why it has drifted five packets without turning anything red.
**Editing the router is a routing act, not bookkeeping**, so it is named here and
**not applied**. `(zz)`.

---

## Residue

Appended by the builder during the packet as **`(qqqqq)`** through **`(uuuuu)`**.
This close appends **`(vvvvv)`**, **`(wwwww)`**, **`(xxxxx)`** and **`(yyyyy)`**, and advances
the **`(zz)`** streak **THIRTEEN → FOURTEEN**.

**THE RESIDUE ITEMS ARE TERSE AND THAT IS ITSELF `(yyyyy)`.** `residue.md` sits **3,608 B
under a 204,800 B ceiling** at `aa0a7b3`; this close's first draft was **+7,934 B** and drove
`build-os/maintenance/run-tests.sh` **RED on 4 subtests**. It was rewritten to **+3,466 B**,
leaving **142 B of headroom**, and the full argument was moved here — a receipt has no
ceiling. **`rotate-memory.sh` is not the escape:** it selects **by recency over BLOCKS**, its
dry run reports this file as **3 blocks → keep 3 newest, would archive 0**, so for any
N ≥ 3 it reclaims **nothing** — and it **REFUSES at exit 3 once the file is already over the
ceiling**, so *the preventative tool has a precondition that the failure it prevents
violates.* **The next close has no green path unless an operator re-blocks the file, raises
`--max-bytes` deliberately, or moves standing content to `standing_gates.md`** — which the
rotator never reads. **A blind `--apply` is not safe:** selection is recency-only and this
file carries literals other suites pin.

**Everything already open in `residue.md` stays open. This close fixed nothing
and was not asked to.** `(ddd)` stays queued. `(uuuu)` stays open.

---

## Open boundaries carried forward

- **NOTHING IS PUSHED, MERGED, TAGGED, PR'd OR DEPLOYED**, and no such go has been
  given. `0cdb3b7`, `53b92d4`, `aa0a7b3` — and this close commit — stay **local**,
  pending an explicit go from the operator.
- **`0cdb3b7`, `53b92d4` and `aa0a7b3` MUST NOT BE AMENDED.** They are the commits
  the gates measured, and `0cdb3b7` is the commit the Commit-1-isolation result is
  a statement about.
- **`build-os/metrics/rank-candidates.sh`, `signal_snapshots.tsv` and
  `decision_telemetry.tsv` were not touched** by this packet or by this close, and
  `c2d97f8` remains the selection anchor of the still-intact prospective
  experiment.
- **No row in the kernel event ledger was rewritten, and none was appended**, by
  the packet or by this close.
- **Declaring the next packet is a routing act** and is not the archivist's to
  take. `active_packet.md` stages nothing at this close.
- **Fixing the inverted-polarity site is its own packet** and needs a licence to
  edit `tests/build_os_maintenance_tests.sh`, which this packet did not have.
- **Retiring the doubled-run discipline is an operator act**, and qa's criterion
  above is what it costs.
- **Making receipts participate in the kernel's `supersedes`/`contradicts` edges
  is a design act on the kernel**, routed above and not taken.
- **Editing the second-eyes row in `tool_router.md` is a routing act.** The stale
  "nine" is named here and left in place.
