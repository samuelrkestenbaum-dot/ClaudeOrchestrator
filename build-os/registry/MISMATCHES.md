# Controls exercising more authority than their class licenses

Written by reading the controls, not generated. Pinned by
`build-os/registry/scan-controls.sh` and `tests/control_registry_tests.sh`, in
**both** directions: every control carrying `authority_mismatch: declared` in
`control_registry.txt` must appear here with the line that gates (forward), and
every control named in the summary table below must still carry that flag
(reverse). The reverse direction is what stops a mismatch being cleared by
relabelling the class — the registry cannot quietly agree with itself while this
file goes on accusing the control.

**Nothing in this file is a proposal to change anything.** Re-authorising a
control is a governance action and belongs to the operator.

## Three numbers, each with its derivation

1. **11 of 97 classified controls gate on `unvalidated` evidence.** Eleven
   controls can stop the build and nothing has established that any of them
   discriminates — no measurement, no red drive, no field observation. This is
   the sharpest number in the census and the one to read first.
   `awk -F': ' '/^control: /{c=$2} /^runtime_authority: gate/{g=1} /^empirical_status: unvalidated/{u=1} /^$/{if(g&&u)print c; g=0;u=0}' control_registry.txt`
   → `metrics.record.note_minimum`, `adoption.junk_row_thresholds`,
   `adoption.single_commit_attribution`, `maint.tripwire_armed_precondition`,
   `maint.rotate_node_precondition`, `tools.supervise_timeout`,
   `tools.handoff_lock`, `tools.handoff_timeouts`,
   `tools.capability_profile_usage`, `tests.stdin_scan_nonvacuity`,
   `tests.nonvacuity_minimums`. Four of the eleven are Class A — an invariant on
   `unvalidated` evidence is *legal* under the licence table and still means
   nobody has watched it fire.
2. **14 of 22 entries carrying `authority_mismatch: declared` exercise `gate` on
   a class that does not license it.** The bare
   `grep -c '^authority_mismatch: declared' control_registry.txt` yields **22**,
   because that flag now marks BOTH kinds of mismatch (see the table note below);
   the `gate`-exercising subset — the subject of this file — needs the authority
   filter too:
   `awk -F': ' '/^runtime_authority: /{ra=$2} /^authority_mismatch: declared/{if(ra=="gate")n++} END{print n}' control_registry.txt`
   → 14. All 14 are
   Class C heuristics, all 14 can exit non-zero, and none of them was wrong to
   build. The fourteenth arrived by **demotion on review** rather than by
   registration — see §14, which is the only entry in this file whose class was
   argued rather than assigned.
3. **An entry is not a line, and 14 badly understates the instances.**
   `tests.nonvacuity_minimums` is **one entry covering 34 fitted constants in 12
   test files** (§10 lists all 34; the scan that reproduces the membership is in
   `tests/control_registry_tests.sh` §21). Counting decision *sites* rather than
   registry *entries*, the 14 entries below name **56** fitted constants,
   thresholds and prose regexes that can stop this build. The first version of
   this file said "six" for the family and "thirteen heuristics" for the total.
   Both were wrong, in the direction that flatters the census.

The licence table (`README.md` §3): `A -> gate`, `B -> rank`, `C -> advise`,
`D -> observe`, `R -> observe`. A deterministic metric does not automatically
become a gate. **A heuristic does not become a gate by being useful.**

---

## The summary

The table between the markers is machine-read by `scan-controls.sh` section 8.
Removing a row is not a way to clear a mismatch: the forward check then reports
the control as `UNREPORTED`.

<!-- MISMATCH-TABLE:START -->

| control | class | exercises | licensed | the line that gates | sites |
|---|---|---|---|---|---|
| `adoption.lane_size_check` | C | gate | advise | `build-os/metrics/check-adoption.sh:426` | 2 |
| `adoption.junk_row_thresholds` | C | gate | advise | `build-os/metrics/check-adoption.sh:513` | 2 |
| `adoption.lane_override` | C | gate | advise | `build-os/metrics/check-adoption.sh:420` | 2 |
| `adoption.single_commit_attribution` | C | gate | advise | `build-os/metrics/check-adoption.sh:524` | 1 |
| `metrics.record.note_minimum` | C | gate | advise | `build-os/metrics/record-packet.sh:119` | 1 |
| `swarm.disjointness` | C | gate | advise | `build-os/tools/swarm-merge.sh:381` | 1 |
| `swarm.hot_file_reservation` | C | gate | advise | `build-os/tools/swarm-merge.sh:311` | 3 |
| `maint.tripwire_coverage_scan` | C | gate | advise | `build-os/maintenance/real-memory-tripwire.mjs:447` | 1 |
| `tests.stdin_scan_nonvacuity` | C | gate | advise | `tests/build_os_tests.sh:964` | 1 |
| `tests.nonvacuity_minimums` | C | gate | advise | `tests/entitlement_tests.sh:126` (+33 more, §10) | 34 |
| `tools.handoff_timeouts` | C | gate | advise | `build-os/tools/specialist-handoff.sh:151` | 3 |
| `tools.supervise_timeout` | C | gate | advise | `build-os/tools/supervise.sh:49` | 2 |
| `registry.discovery_rule` | C | gate | advise | `build-os/registry/scan-controls.sh:403` | 2 |
| `bandwidth.active_packet_singleton` | C | gate | advise | `build-os/tools/bandwidth-check.sh:136` | 1 |
| `maint.rotation_live_file_replacement` | A | execute | gate | `build-os/maintenance/rotate-memory.mjs:1006` | 1 |
| `swarm.merge_commit_execution` | A | execute | gate | `build-os/tools/swarm-merge.sh:586` | 1 |
| `metrics.record.store_append` | A | execute | gate | `build-os/metrics/record-packet.sh:276` | 1 |
| `identity.stamp_write` | A | execute | gate | `.claude/hooks/build-os-identity.sh:160` | 1 |
| `tools.handoff_lock_lifecycle` | A | execute | gate | `build-os/tools/specialist-handoff.sh:166` | 1 |
| `metrics.decision.store_append` | A | execute | gate | `build-os/metrics/record-decision.sh:479` | 1 |
| `metrics.decision.outcome_update` | A | execute | gate | `build-os/metrics/record-decision.sh:744` | 1 |
| `memory.kernel_store_append` | A | execute | gate | `build-os/tools/memory-kernel.sh:573` | 1 |

<!-- MISMATCH-TABLE:END -->

**THIS TABLE NOW CARRIES TWO DIFFERENT KINDS OF MISMATCH, and blending them
would destroy the only number in it that means anything.** Read the `exercises`
column:

- **14 rows exercise `gate`** on a licence that reaches only `advise`. These are
  the heuristics — fitted constants, thresholds and prose regexes that can stop a
  build. This is the original subject of this file.
- **8 rows exercise `execute`** on a Class A licence that reaches `gate`. These
  are the mutator census's write actions (§17). They are over-authorised for a
  completely different reason: **no class licenses `execute` at all**, so a
  control that performs a durable write is out of licence by construction rather
  than by anybody having stretched a heuristic.

**`sites` is a hand count**, taken from the sections below, of the distinct
fitted constants, thresholds and prose regexes inside each entry — not a grep.
**It totals 56, and that total covers the 14 `gate` rows ONLY.** The `execute`
rows each carry `1` because a write action has exactly one site: the line that
performs it. Adding them to 56 would state that this repository carries a larger
number of fitted constants, which is false — it carries 56, plus one mutation per
`execute` row, and those are not constants at all. The count of `execute` rows is
not restated here: it is the table above, filtered on the `execute` column.

The entry count is now **21**, and it remains a property of how finely this
registry was cut rather than of how much authority the repository carries. The
twenty-first is `metrics.decision.outcome_update`, and it arrived the way the
six before it did: a durable write, classified at the rung the corrected ladder
gives a durable write, on a Class A licence that reaches only `gate`. Registering
it at `advise` to avoid the row would be exactly the understatement residue (nn)
records against `maint.managed_set_replacement`.

There is no Class D and no Class R anywhere in this system, so the second half of
the safety claim — that a learned model may not outrank an invariant — is
currently vacuous here. It is asserted by the suite anyway, so that it stops
being vacuous the day something learned arrives.

## The five dispositions — what may be DONE about a row above

This file has always named four remedies. There are now **five**, and the fifth
is recorded in `build-os/registry/mismatch_dispositions.txt` and validated by
`build-os/tools/mismatch-disposition.sh`:

| disposition | what it does |
|---|---|
| `demote_authority` | lower `runtime_authority` to what the class licenses. The default remedy, and the one every other row is measured against. |
| `correct_class` | the classification was wrong, not the authority. Re-classify — and be ready to say why the thresholds are not a heuristic. |
| `improve_evidence` | the authority is defensible once the evidence supports it. Measure, then re-derive. |
| `retire_control` | the control should not exist. Remove it, and whatever consumes it. |
| `accept_and_constrain` | the mismatch is **CARRIED**, because demotion or removal has been **MEASURED** to be more dangerous than the mismatch. |

**`accept_and_constrain` CLEARS NOTHING.** A disposed control keeps
`authority_mismatch: declared`, keeps its row in the table above, and keeps its
`OUT-OF-LICENCE` finding from `evidence-policy.sh check`. The record states that
a mismatch is being carried, names the constraint that bounds it, and gives it a
review date. It raises no authority: the standing rule is unchanged — **this
machinery is class correction and authority demotion, and it is not a promotion
instrument.**

**It is applied to exactly ONE row, and its neighbour is REFUSED by name.**
`maint.tripwire_coverage_scan` qualifies: its demotion was applied literally and
measured, and the measurement (`COVERAGE-GATE-PREVENTION-DIFFERENTIAL`) found
that the gated arm leaves the tree untouched while the demoted arm **destroys
live memory** — *at the same exit code*, so nothing watching exit codes could
have seen it. `maint.source_scan_mask` does **not** qualify: its
`demotion_requirement` records the demotion as **REACHABLE**, and it carries
`authority_mismatch: none`, so there is no declared mismatch to carry. The
validator refuses it and quotes the census's own words back.

---

## 1. `adoption.lane_size_check` — the clearest case in the repository

**Gates at** `build-os/metrics/check-adoption.sh:426`, counted at `:575`, exits
at `:595`.
**Thresholds** `LANE_TINY_MAX_FILES=13` (`:130`), `LANE_TINY_MAX_CHURN=2213`
(`:131`).

The derivation is written out at `:92-104` and it is honest work: the median of
the four packets in this repository's store that declare a non-waived lane and
name commits git can measure. Files `{7, 8, 18, 32}` -> 13. Churn
`{852, 2005, 2422, 9818}` -> 2213.

**It is a median of n=4 observations of one repository, and it exits 2.** The
script argues its own case well — specificity over sensitivity, a wide empty band
between the two populations, an explicit refusal to auto-follow the store — and
concedes at `:113-121` that half its own calibration set survives being
relabelled `tiny`. All of that is a good argument for keeping the check. None of
it converts a four-point median into an invariant.

The failure mode it creates is not hypothetical: legitimate work sized between
the two populations is refused, and the person refused is holding a number
derived from four packets they did not do. The escape hatch (`LANE-OVERRIDE`)
exists precisely because the threshold is known to be wrong sometimes — which is
itself the tell. Invariants do not ship with override tokens.

## 2. `adoption.junk_row_thresholds`

**Gates at** `build-os/metrics/check-adoption.sh:513`.
**Thresholds** `MIN_MEASURED=4` of 11 cells (`:73`, tested at `:494`),
`MIN_NOTE=40` characters (`:76`, tested at `:508`).

Both are stated as reasoning, not derivation — "roughly one clause of
provenance". No distribution was measured. A row with three filled cells is
`HOLLOW` and counts as a violation; a row with four is recorded. Nothing
establishes that the boundary belongs at four.

The principle underneath — "a row of dashes records that nothing was measured,
which is not the same as recording the packet" — is Class A and correct. The two
integers implementing it are Class C and they are what refuses.

## 3. `adoption.lane_override`

**Gates at** `build-os/metrics/check-adoption.sh:420` (a malformed override is a
violation in its own right).
**Thresholds** `MIN_OVERRIDE_REASON` = `MIN_NOTE` = 40 (`:134`, tested at
`:332`), and "the justification must name the measured file count" (`:336`).

Making a half-written override a violation rather than a silent pass is right.
The proof-of-work idea — you can only write the file count if you looked at the
size — is clever. It is also a regex: a justification that contains that number
for any other reason passes, and one that names the size in words fails. A
39-character justification is refused and a 40-character one is honoured.

## 4. `adoption.single_commit_attribution`

**Gates at** `build-os/metrics/check-adoption.sh:524`.
**The heuristic** at `:519` — a case-insensitive grep for
`file[ -]ownership manifest|ownership manifest|attribution by path`.

The rule being enforced is a real policy. The evidence admitted for it is
whether three specific phrasings appear anywhere in a receipt. A receipt that
mentions the phrase while explaining why it has no manifest passes; a receipt
carrying a perfectly good manifest under a different heading is refused. A prose
grep standing in for a structural fact is a heuristic, and this one exits 2.

## 5. `metrics.record.note_minimum`

**Gates at** `build-os/metrics/record-packet.sh:119`, refusing the write at
`:262`. **Threshold** `NOTE_MIN=12` (`:51`).

The smallest case in the list, included because it is the same shape and because
excluding the small ones is how a list like this stops being a census. "A row
must carry a note" is Class A. "At least 12 characters" is a number somebody
picked, and it is the comparison that runs.

## 6. `swarm.disjointness`

**Gates at** `build-os/tools/swarm-merge.sh:381`; violations are raised at
`:329`. **The approximation** is `probe()` at `:140` and `overlap()` at `:146`.

The pre-flight pass at `:329` runs before any agent exists, which is the whole
selling point of the tool. It decides whether two globs could ever collide by
instantiating each into **one** canonical probe string (`**` -> `pdir/pfile`,
`*` -> `pseg`, `?` -> `p`) and matching it against the other's regex.

**The error direction is the unsafe one, and an earlier draft of this section had
it backwards.** This was called "a sound-in-one-direction approximation", with
`a*b` vs `a?c` offered as an example of a pair it correctly separates. That
example is real but it is the harmless direction. The approximation's actual
failure is the other one: **it certifies colliding manifests as disjoint.** Two
witnesses, both reproducible by extracting `probe()` and `overlap()` and running
them:

| claim A | claim B | `overlap()` says | a real path matching **both** |
|---|---|---|---|
| `src/*.ts` | `src/foo*` | DISJOINT | `src/foo.ts` |
| `*/x.py` | `app/*` | DISJOINT | `app/x.py` |

`probe("src/*.ts")` is `src/pseg.ts`, which does not match `^src/foo[^/]*$`;
`probe("src/foo*")` is `src/foopseg`, which does not match `^src/[^/]*\.ts$`.
Neither probe is the witness, so the pair is passed. Two agents are then told
their claims are disjoint, and both own `src/foo.ts`.

**The concrete-path backstop does not close this.** `:363` is exact, but it is
guarded by `if [ -n "$REPO" ]` and `REPO` defaults to `""` (`:80`), so it does
not run at all unless `--repo` is given. Even when it does run, it iterates paths
that **already exist** — and the normal fan-out case is agents about to *create*
files. A file neither agent has written yet is uncovered by both passes.

Class stays **C**, and the reason has changed: not "fitted to a sample" but
"unsound in the direction that matters". A reviewer might still argue B —
deterministic, reproducible, fitted to nothing — and B at `gate` is a mismatch
too, so the entry stays in this list either way. The five-class ontology has no
slot for "approximate decision procedure with false negatives", which is what
this is. **Fixing the tool is a separate packet**; this file documents.

## 7. `swarm.hot_file_reservation`

**Gates at** `build-os/tools/swarm-merge.sh:311` (release reason length) and
`:353` (a claim on a reserved path).
**Three heuristics** — the default hot inventory (`:228`), the
verification-suite derivation by filename suffix (`:238`), and the 30-character
minimum plus the no-shared-reasons rule (`:311`, `:315`).

`Gemfile.lock` is hot because it is on a list; an unlisted lockfile is not. The
verify command is parsed for hot paths by matching token extensions, which is a
parse of a shell string by suffix. The reason length is a judgement about what a
considered reason looks like. The policy underneath — the merger owns shared
surfaces — is Class A. Nothing implementing it here is, and all of it refuses a
fan-out before any agent runs.

## 8. `maint.tripwire_coverage_scan` — the control that documents its own defeat

**Gates at** `build-os/maintenance/real-memory-tripwire.mjs:447` — it throws
during module load, which under the preload aborts every suite file in the
directory.
**The heuristic** is `coverageFindings` at `:394`, over `source-scan.mjs`'s mask.

The file's own header calls this "a convenience check, not a boundary", states
that the mask "is a heuristic and is defeatable", records that it has been beaten
three times, and prints the exact one-line source shape that beats it — two
regexes in division position, blanking a span that holds a real import. Its
empirical status in the registry is `red_driven,refuted`, and `refuted` is not
rhetorical: the detection claim was measured **false** for the bare `node --test`
path, and the header was corrected to say so.

A control that publishes its own defeat and then aborts the run on its verdict is
exercising `gate` on a heuristic. It is defensible as fail-closed — an uncovered
file aborting the directory is the safe direction — and the mechanisms it backs
up (the preload and the shell fingerprints) are genuinely Class A. But the
decision to let a self-described convenience check stop a run should be an
operator's, taken once and on the record, rather than a side effect of `throw`
being the easiest thing to write inside a module body.

### The demotion was taken to the operator, and MEASURED. It was refused.

This entry was read — here and on review — as the strongest demotion candidate in
the census: `refuted` caps at `observe` at any class, and a control shown not to
discriminate should not be able to stop a build. The demotion its own
`demotion_requirement` used to prescribe was applied literally and measured, and
the measurement went the other way.

`COVERAGE-GATE-PREVENTION-DIFFERENTIAL`, in
`tests/build_os_maintenance_tests.sh` §6a — two arms, differing only in that
`throw`, against an uncovered suite file that rewrites real memory:

| arm | the scan | exit | the real tree |
|---|---|---|---|
| GATED | throws, as shipped | 1 | **untouched** |
| DEMOTED | prints instead | 1 | **destroyed** |

**The exit code is 1 in both arms.** Nothing watching exit codes — a caller, a CI
job, a reviewer reading a transcript — can see this demotion at all; only the tree
separates them. What the tree says is that this gate is the layer's **only
prevention**. `maint.real_memory_tripwire` and `maint.shell_fingerprint` are
detection after the fact and both declare `rollback_behavior: NONE`.

**Which demotion was measured, stated exactly.** The DEMOTED arm replaces a
`throw` with a `console.error`. On README §2's ladder that is **`gate` →
`advise`** — the output is still produced and still presented — whereas the
evidence cap demands **`observe`**. So the arm measured is not the arm the cap
prescribes. The conclusion survives *a fortiori*: `observe` is strictly weaker
than `advise`, so if advising already lets the tree be destroyed, observing does
too. The distinction is recorded because "the demotion" was otherwise doing
quiet work in that sentence — and because, per §2 of this entry's companion
above, `observe` is not a rung this control could be written onto at all.

Two things follow, and they are separate.

1. **The refutation is path-scoped and the token cannot say so.** `refuted`
   records that the *detection* claim failed under a bare `node --test`. Under
   the sanctioned command the same scan is measured *prevention*. **Evadability
   is not non-discrimination:** the defect this control exists against was an
   accident — a suite file carrying no tripwire, which destroyed live memory at
   exit 0 — and against that it discriminates exactly. A determined evader beats
   it; a forgetful author does not.
2. **The mismatch stands anyway.** Keeping the gate is not a claim to be in
   licence, and nothing here has been re-authorised, relabelled or excepted. The
   class is still `C`, the evidence is still `red_driven,refuted`, the authority
   is still `gate`, and this row still counts toward the 14. **The finding was
   correct; the remedy it suggested was not.** That distinction is the whole
   point of the census advising rather than gating.

### The same measurement closes the entry the class axis cannot see

`maint.source_scan_mask` — the mask this scan is built on — is `refuted` at
`advise`. It carries **no** declared mismatch and is **not** in the table above,
because Class C licenses `advise` and the class axis is structurally blind to it.
It is one of the five findings only the evidence axis reaches, and all four
resolutions are closed to it:

- **Demote to `observe`?** **This was the closed resolution, and the ladder
  correction has REOPENED it.** The original argument ran: `observe` was defined
  in `README.md` §2 by **non-consumption** — it measures and records, and nothing
  reads the result — while two controls *do* read this one's result (this
  section's scan gates on it, and `rotate-memory.rootscan.test.mjs` counts on
  it), and it is `load_bearing` precisely because they do. On that definition
  demoting it would not have lowered its authority; it would have written a
  falsehood.
  **The radius was never specific to this control.** `OBSERVE-LB` foreclosed
  `observe` for **67 of the 81** registered controls — every entry that is
  `load_bearing` and names a consumer — with **0 of 81 sitting at `observe`**. So
  the evidence axis's `refuted → observe` cap had **no legal spelling for any
  wired-in control**: it could be stated as a finding and never written as a row.
  The cause was definitional. **Both** bottom rungs were defined by
  non-consumption, so the ladder had no rung meaning *"it is read, but may cause
  nothing"* — a gap in the ladder, not a fact about this entry.
  **The operator has since corrected the ladder** (`README.md` §2): `observe` now
  means the output may be recorded and **consumed for visibility** while causing
  **no operational consequence**, and a sixth rung `execute` sits above `gate`
  for output that directly causes mutation. Being consumed is therefore no longer
  a bar to `observe`. `OBSERVE-LB` survives on the **narrower** ground that
  `load_bearing` asserts *removing it changes outcomes*, which IS an operational
  consequence — and it has **moved off the gating path** to
  `scan-controls.sh`'s advisory channel, because an advisory axis whose
  prescribed demotion is blocked by a gate is not advisory.
  **Nothing about this control was changed by that correction**: it is still
  Class `C`, still `refuted`, still at `advise`, and still out of licence on the
  evidence axis. What changed is that the remedy is now *writable* rather than
  merely *prescribable*, and writing it remains the operator's move.
- **Retire it?** That breaks both consumers.
- **Improve the evidence?** Its own `promotion_requirement` forbids it: three
  defeats, and the maintainers stopped writing mask heuristics deliberately.
- **Correct the class?** A defeatable lexer is a heuristic. `C` is right, and the
  evidence cap binds at `observe` whatever the class.

So the finding is real and its prescribed remedy is unreachable. The blocker is
that `runtime_authority` currently means both *what consequence may this output
have* and *does anything read it*, and those come apart exactly here.

**This is not a second demonstration of the `runtime_authority` /
`deployment_mode` split, and it must not be counted as one.** The decisive test:
splitting output semantics out of `runtime_authority` would **not** have fixed
this control. Even with an `outputSemantics` concept in hand, `observe` would
still have been defined by non-consumption, two controls would still read this
one's result, and the mask still could not sit on that rung. The collision was
between `runtime_authority`'s **consumption clause** and
**`implementation_status`** — a redundancy between two fields that **both already
exist** — not a missing third concept. **The remedy was NOT small, and an earlier
draft of this paragraph said it was — wrongly, in the direction that flatters the
fix.** Consumption was asserted in **six** places, not one: README §2's *two*
bottom rungs (both were consumption clauses), README §3b's `shadow` row,
`authority_envelopes.txt`'s header, and both tools' headers. And the decisive
one: **the foreclosure was enforced by code, not by prose.**
`scan-controls.sh`'s `OBSERVE-LB` keys on `[ "$aut" = "observe" ]` and hard-coded
the semantics in its own refusal message, so deleting every line of README prose
would have left it refusing at exit 2 and the demotion still unwritable for all
67. **A remedy its own guard survives is not a remedy.**

**That remedy has since been applied, at SEVEN sites and in the code.** The
ladder was redefined by **consequence** rather than consumption, `execute` was
added above `gate`, and `OBSERVE-LB`'s message and exit behaviour were both
rewritten — it now **reports** on the advisory channel instead of refusing at
exit 2. `tests/evidence_policy_tests.sh` §21 sweeps all **seven** sites **by
content**, so a site left behind fails the suite rather than being discovered
later. **Nothing about this control was changed by any of it.**

**Six was the count this section originally recorded, and seven is the count
that was found.** The seventh is `control_registry.txt` itself, which carried the
retired rule in two live fields of this very entry — the fields an operator reads
*while deciding*. **That the count moved is the finding, not a typo:** a remedy
whose site list is written from prose rather than measured is a remedy that will
be short by however many sites nobody thought of, which is why §21 sweeps by
**content** and names its sites rather than counting them.

**And the sweep was itself short, in exactly the shape it was built to catch.**
§21 originally greped one wording of the retired rule — *"nothing reads the
result"*, the README's — while the deployment axis states the same rule in a
**second** wording. Two sites shipped past it carrying the second wording, in the
two files that **own** that axis. That is the packet's own headline defect
(`VACUOUS-REF` checks *resolvability*, never *identity*) reproduced one level up
inside its own new guard. §21 now also refuses a consumption clause on any line
mapping something **onto** `observe`, which is what catches the second wording.

### A fifth outcome is missing from the framework — recorded, not built

The operator's step-3 ruling offers four outcomes: **demote**, **correct the
class**, **improve the evidence**, **retire**. Both controls in this packet
worked all four and closed all four, which is a legitimate result — but the
pattern behind it is worth naming. **For 67 of 81 controls (83% of the census),
demotion ONTO THE RUNG THE `refuted` CAP PRESCRIBES was unspellable**, because
`OBSERVE-LB` and the ladder's two non-consumption bottom rungs left no `observe`
row a wired-in control could be lowered onto. **The ladder correction removed
that blockage** — `observe` is now defined by consequence, so a control may be
consumed for visibility and sit there — but the fifth-outcome point survives the
fix and is why it is kept: the framework offered four outcomes and one of them
was unavailable to five-sixths of the census for definitional reasons nobody had
noticed. The qualifier matters and an earlier
draft dropped it: `gate` -> `advise` remains perfectly spellable — 15 of 97 sit
at `advise` today — and it is the demotion this packet actually measured.
`maint.tripwire_coverage_scan` closed "demote" because demoting it was measured
to destroy the tree, not because the row was unwritable. A framework whose first outcome is unavailable for five-sixths of its
subjects will keep producing "all four closed" for reasons that have nothing to
do with the control in front of it.

The missing outcome is **accept and constrain**: leave the authority where it
is, keep the finding standing and un-retired, and require an operator envelope
to bound it — an explicit, dated, revocable grant rather than either a silent
pass or an unwritable demotion. **The machinery already exists and is empty:**
`build-os/registry/authority_envelopes.txt` holds 0 live envelopes, and the
deployment axis binds 0 findings as a result. This is recorded as a finding for
the operator. **Nothing here builds it**, and no envelope is written by this
packet.

## 9. `tests.stdin_scan_nonvacuity`

**Gates at** `tests/build_os_tests.sh:964`. **Threshold** `PIN_MIN_SITES=10`
(`:941`, tested at `:963`).

"The scanner must not be blind" is Class A. `10` is the number of hook-invocation
sites that existed the day it was written. Legitimately deleting two of them
fails the suite, and the failure message says the scanner has gone blind when it
has not.

## 10. `tests.nonvacuity_minimums` — the entry that undercounted itself

**This section is the correction.** The first version claimed "one entry covering
the family" and named **six** constants in **two** files. The real membership,
under this registry's own inclusion rule, is **34 constants in 12 files**. A
census that undercounts by 28 in the one entry that exists to say "there are more
of these than you think" is the same failure as the controls it lists, and the
grep that falsifies it is one line.

**The inclusion rule, stated so it can be re-run.** A member is a comparison in
`tests/*.sh` of the form `-ge N` or `-gt N` with **N > 1**, where N is a
*coverage or size floor* — how many things a scanner found, how many blocks a
driver ran, how big a scanned artefact is — and the assertions downstream of it
are meaningless if it fails. `N <= 1` is excluded on purpose: "the scan found at
least one thing" **is** the invariant, and it is Class A. Everything above 1 is a
snapshot of the tree on the day it was written.

```
grep -rnE -- '-ge[[:space:]]+[0-9]+|-gt[[:space:]]+[0-9]+' tests/*.sh \
  | grep -vE -- '-ge[[:space:]]+[01][^0-9]|-gt[[:space:]]+0[^0-9]'
```

37 lines. Three are excluded with reasons (below). **34 remain, and all 34 are
this control.**

| file | lines | the floors |
|---|---|---|
| `tests/pilot_kit_tests.sh` | `:97 :115 :117 :176 :255 :304 :316 :327 :334 :367 :458` | 3 speed mentions, 10 router lane lines, 10 onboarding lane lines, 8 runnable blocks, 8 blocks executed, 20 paths, 5 links, 5 scripts, 6 criteria, 6 executable checks, 6 both-direction pairs |
| `tests/entitlement_tests.sh` | `:126 :136 :345 :481` | 5 stamped roots, 5 licence copies, 12 packet files, 3 quoted licence lines |
| `tests/control_registry_tests.sh` | `:79 :184 :440 :772` | 20 entries, 20 surfaces, 5 declared mismatches, 40 assertions |
| `tests/release_metadata_tests.sh` | `:121 :200 :315` | 200 licence bytes, 3 rollback lines, 2 receipts |
| `tests/speed_benchmark_tests.sh` | `:397 :531 :542` | 4 store rows, 3 git-verified rows, 4 corpus rows |
| `tests/lane_declaration_tests.sh` | `:493 :496` | 12 fixture stores, 15 fixture receipts |
| `tests/metrics_adoption_tests.sh` | `:418 :421` | 10 fixture stores, 15 fixture receipts |
| `tests/build_os_maintenance_tests.sh` | `:88` | 100 tests in the installed suite |
| `tests/lane_enforcement_tests.sh` | `:56` | 5 lane rows on each side |
| `tests/swarm_merge_tests.sh` | `:404` | 12 staged paths |
| `tests/scaffold_seeding_tests.sh` | `:241` | 3 blocks in the smallest rotating file |
| `tests/gate_depth_tests.sh` | `:73` | 4 agent definitions |

**The three exclusions, each with its reason** — an exclusion list nobody can
audit is how a census shrinks quietly:

- `tests/build_os_maintenance_tests.sh:200` (`-gt 180000`) — a property of a
  fixture *this test constructs itself*, so it is deterministic by construction
  and not a floor on a scan of the tree.
- `tests/pilot_kit_tests.sh:340` (`-ge 15`) — a length floor on failure *text*
  inside a falsifiability driver, not a coverage floor.
- `tests/speed_benchmark_tests.sh:429` (`-ge 12`) — `[ "${#nt}" -ge 12 ]` is a
  floor on the LENGTH OF A STRING, identical in kind to the exclusion above it,
  not a floor on how much a scan of the tree covered. The membership rule admits
  coverage and size floors; a minimum note length is neither.

  **This exclusion's stated reason used to be false, and it is worth recording
  why rather than quietly swapping it.** It said the line "mirrors
  `metrics.record.note_minimum`" and that "counting it here would classify one
  line twice". Neither half held. `metrics.record.note_minimum` cites
  `build-os/metrics/record-packet.sh:51` and `:119` — the constant and the
  comparison in the recorder — and **no entry cites
  `tests/speed_benchmark_tests.sh:429` at all**; including it produces zero
  duplicates under §22. The exclusion was right and its justification was
  invented, which is the more dangerous of the two failures: a wrong exclusion
  gets caught by re-running the rule, and a wrong reason is what the rule is
  re-run against. The exclusion stands on the ground above. The membership count
  of 34 is unaffected either way.

### The double classification, and how it was resolved

`tests/pilot_kit_tests.sh:97` was cited by **both** this entry (C, `declared`)
and `suite.pilot_kit` (A, `none`) — one line carrying two contradictory
classifications, in the artefact whose entire purpose is unambiguous
classification. `tests/build_os_maintenance_tests.sh:88` and
`tests/lane_enforcement_tests.sh:57` had the same shape, and those two `suite.*`
entries **admitted the fitted constant in their own `notes`** ("carries its own
non-vacuity floor... >= 100 tests") while declaring `authority_mismatch: none`.

The boundary now drawn, and it is a **scope** correction, not a relabel: a
`suite.*` entry classifies exactly one thing — *this suite exits non-zero when
`FAIL` is non-zero*, which is a genuine Class A invariant. The vacuity floors
that happen to live inside the same file are separate controls and belong to this
entry. So `suite.pilot_kit`, `suite.build_os_maintenance` and
`suite.lane_enforcement` now cite their `RESULT`/`[ "$FAIL" -eq 0 ]` lines
instead of a floor, and each carries an explicit cross-reference rather than a
silent absence. Their `authority_mismatch: none` is unchanged — and it is now
**true**, because the C-class thing they were quietly carrying is no longer in
their scope. `tests/control_registry_tests.sh` §22 fails the suite if any
`path:line` is ever claimed by two entries again.

### The self-indictment

`tests/control_registry_tests.sh:774` is `[ "$PASS" -ge 40 ]`, whose failure
branch reaches `[ "$FAIL" -eq 0 ]` and stops the run. **40 is the number of
assertions that existed the day this packet was written** — the packet whose
subject is fitted constants that gate. It went unflagged in the first version.
It is now a registered member of this family, along with `:79` (20 entries),
`:184` (20 surfaces) and `:440` (5 declared mismatches), which are the same shape
in the same file. They are not repaired, for the same reason nothing else here
is: this file records, and re-authorising is the operator's call.

The vacuity principle is Class A and is one of the best things in this
repository. All 34 constants implementing it are Class C, and they are what
compares.

## 11. `tools.handoff_timeouts` — the sharpest failure mode

**Gates at** `build-os/tools/specialist-handoff.sh:151` (lock wait) and `:300`
(child timeout).
**Thresholds** `HANDOFF_TIMEOUT=900` (`:39`), `HANDOFF_LOCK_WAIT=30` (`:42`),
`HANDOFF_LOCK_STALE=1800` (`:43`).

The lock itself (`mkdir`) is exact and correctly Class A. The **staleness**
threshold is not: crossing 1800 seconds lets one process **break another
process's lock** (`:136`, `:141`). A chosen duration is deciding a
mutual-exclusion question, and nothing measured establishes that a handoff
holding a lock for 1801 seconds is dead. This is the mismatch with the worst
consequence in the list — two processes mutating the capability profile at once —
even though it is the least likely to fire.

## 12. `tools.supervise_timeout`

**The threshold test** is `build-os/tools/supervise.sh:46` —
`[ "$waited" -ge "$TIMEOUT" ]`. **Gates at** `:49` — `exit 124`.
**Defaults** `INTERVAL="5"`, `TIMEOUT="900"` (`:21`).

An earlier version of this section cited `:50` as the line that gates. **Line 50
is `fi`.** The registry entry beside it was no better: it cited `:16` (a header
comment), `:47` (an `echo`) and `:50` (that `fi`) — three lines, none of which
compares anything or exits anything. In the file whose one job is to cite the
line that gates, that is the failure it exists to prevent, and it survived
because `scan-controls.sh` checked only that a cited line was **inside** the
file, not that it did anything, and what closed this instance was resolving every
ref in the registry by hand.

**The hand sweep is now a check, and it is half a check.** `scan-controls.sh`
section 6 refuses a ref that lands on a blank line, a comment, a shebang or a
lone closer (`VACUOUS-REF`). Run against this very defect it would have caught
**two of these three refs — the `:16` comment and the `:50` `fi` — and not the
`:47` `echo`**, because an `echo` is a statement and the filter only rejects
non-statements. The question worth answering is "is this line a comparison or an
exit", and that one is genuinely hard; what exists is the cheap half, and the
cheap half is stated as the cheap half. The residue is named in the README's
section 4 rather than implied away.

The control itself is the mildest case in the list: the caller supplies the
budget, the failure is legible, and `SUPERVISE_STATUS: TIMEOUT` is printed beside
the exit code. It is still a chosen number terminating a run non-zero, and the
licence table has no exception for mild. Listed so the census is complete rather
than curated.

## 13. `registry.discovery_rule` — this packet's own guard

**Gates at** `build-os/registry/scan-controls.sh:403` (an unregistered surface is
a violation) and `:454` (`exit 2`).
**The heuristic** is three directories (`:126`) and five refusal patterns
(`:129`).

*(An earlier version of this section cited `:347` as the exit. `:347` was a
`grep -qxF` inside the anchor's completeness loop; section 8 had grown and the
prose citation had not moved with it. It was not in any `evidence_refs`, so no
guard had an opinion about it — which is the gap section 9 of the README now
partly closes for citations that ARE in `evidence_refs`, and does not close for
prose like this.)*

Three directories, two file extensions and five regular expressions are a chosen
approximation of "what is a control", not a definition of one. It misses a
refusal spelled some other way. It misses **every** control added inside an
already-registered file — the largest hole in this packet, and it is open. It is
blind outside `build-os/`, `tests/` and `.claude/hooks/`. Then it exits 2 on its
verdict.

It is fail-closed and the trade looks right. It is also exactly the shape of
thing this registry exists to make visible, so exempting it would have been the
least defensible entry in the file.

## 14. `bandwidth.active_packet_singleton` — the one that was demoted on review

**Gates at** `build-os/tools/bandwidth-check.sh:136` —
`[ "$NPKT" -gt "$CEILING_PACKETS" ]`, which raises the gating flag and exits 2 at
`:203`.
**The threshold** is `CEILING_PACKETS=1` (`:79`).

Every other entry in this file was registered with its mismatch already declared.
This one was **registered Class A, carrying no mismatch, and demoted to Class C
on review.** It is here because the demotion was *argued*, not because somebody
noticed a stale label.

**The argument it was registered on.** The ceiling of one is not a fitted number;
it is the artefact's own *definition*. `active_packet.md` says it holds "the one
packet currently in flight", so two declared ids is a **malformed artefact**
rather than a policy breach — the same shape as two metrics rows for one packet,
and `metrics.record.one_row_per_packet` is Class A for exactly that reason. The
entry recorded the counter-argument — *"one at a time is also a policy somebody
chose"* — and then kept Class A anyway. **An entry that states the case against
itself and does not answer it has not survived the case against itself.**

**Why it failed, in ascending order of cost:**

1. **The "definition" is a docstring inside the file being checked.** "One packet
   at a time" appears **nowhere in `CLAUDE.md`**, where this repository's working
   contract lives. Grep finds it in exactly one place: line 5 of
   `build-os/packets/active_packet.md` — the prose header of the artefact this
   control reads. A ceiling whose authority comes from a sentence inside its own
   input is a chosen threshold one edit away from being a different number.
2. **The analogy does not hold.** A second metrics row silently corrupts
   `report-speed.sh`'s totals: a real computation with a real consumer. This
   control's `consuming_policies` is *its own exit code*, and nothing in the
   repository acts on it. Violating this ceiling contradicts a prose sentence and
   corrupts no number.
3. **The packet's own two artefacts contradicted each other.** The registry
   claimed the ceiling was "not a chosen policy but a definition". The crosswalk,
   in the same commit, earned `binding_kind: instantiates` on the grounds that
   "**a WIP limit** is named verbatim in this primitive's `system_representation`".
   A WIP limit *is* a chosen policy threshold. Both could not stand, and the
   crosswalk's was the one doing load-bearing work.

**The near-miss, recorded because it is why this needed an argument at all.**
§10's inclusion rule excludes `N <= 1` from the fitted-constant family, on the
grounds that "the scan found at least one thing" **is** an invariant.
`CEILING_PACKETS=1` is a `1`, and it is tempting to read the exclusion as
covering it. **It does not** — the rule fails on all three of its own clauses. It
scopes to a comparison **in `tests/*.sh`** (this lives in a tool). It covers a
constant that **floors how much a scanner or driver covered** (this is an *upper
bound on permitted state*). And its excluded case is *"at least one"* (this is
compared `-gt`, in the refusal direction — *at most* one). Same numeral, opposite
direction. **An exclusion rule read by its constant instead of by its clauses
would have certified this entry silently**, which is the failure mode this whole
file exists to catch.

**What did not change, and why that is the point.** The authority stays `gate`.
Moving it to `advise` would have made the mismatch vanish, and that is precisely
the move this registry forbids: **re-authorising a control is the operator's
decision, not a reclassifier's.** So the control goes on refusing a second
declared packet, and this file now says out loud that the number it refuses on is
a heuristic. `binding_kind: instantiates` stands too — a WIP limit is exactly
what `integration_bandwidth` names, and this control *is* one rather than
standing in for one. Six other entries in this census are Class C and
instantiating; the combination is ordinary, and only the class was ever wrong.

---

## 15. THE MUTATION CENSUS — surveyed, reported, and deliberately NOT acted on

The ladder gained a sixth rung, `execute`, meaning *the output may **directly
cause mutation***. That immediately raises a census question: **which of the 81
controls actually perform a write, and are they correctly classed?** All 81 were
surveyed. **Nothing below has been re-authorised** — no `class`,
`runtime_authority`, `authority_mismatch` or `empirical_status` was changed by
the packet that wrote this section, and **moving a control to `execute` is a
re-authorisation that only the operator may make.**

**The headline is not the one the question expects.** Almost no control is
mis-classed as `gate`-when-it-should-be-`execute`, because **the controls are
checks and the mutations belong to the modules the checks live in**. A control
like `swarm.disjointness` outputs a refusal; the `git commit` in the same file is
not its output. The registry's `owning_module` granularity puts many controls in
one mutating file without any of them being the mutation.

**The registry already names the world-changing role.** `nervous_system_role:
motor` — *"it changes the world"* — was carried by exactly **2 of 81** entries
when this section was written. The mutation census (§17) added six more, so it is
now **8 of 97** (against 43 `immune`, 32 `reflex`, 7 `conscience`, 6 `sensor`, 1
`memory`). The two originals are the table below; that this role was almost
unused is the observation the section was making, and the census is what changed
it:

| control | class | authority | role | what it actually does |
|---|---|---|---|---|
| `maint.managed_set_replacement` | A | **`advise`** | `motor` | *"files copied into an installed repo, replacing prior managed copies"* |
| `swarm.post_merge_verification` | A | `gate` | `motor` | runs the verification, and **rolls the git index back** on failure |

**`maint.managed_set_replacement` is the sharpest finding in this survey, and it
is not at `gate` — it is at `advise`.** Its own declared `output` is *files
copied into an installed repo*, its `failure_behavior` is *"none that stops
anything — it prints what it could not do and continues; it never exits
non-zero"*, and its `rollback_behavior` is *"none; a managed file's local edits
are lost on install"*. Under the corrected ladder `advise` means *the output may
influence a human or a higher-authority control*. **Copying files over a user's
edits is not influence.** On the corrected ladder this is `execute` — **two rungs
up** — and it is the one entry in the census where the recorded authority and the
recorded behaviour disagree about the *kind* of thing the control is, rather than
about how far it reaches. It is also `unvalidated`, so nobody has watched it.

**The modules that durably mutate, none of which is registered AS a mutation.**
Verified by reading the write sites and discarding everything that writes only
into a `mktemp` sandbox — which is what excludes every test suite, and also
`real-memory-tripwire.mjs`, which turns out to write nothing at all:

- `build-os/maintenance/rotate-memory.mjs` — `writeFileSync` to a staging path
  then `renameSync` **onto the live memory file**. The most consequential write
  in the system.
- `build-os/tools/swarm-merge.sh` — **creates a commit**, but only behind an
  explicit `--commit` opt-in; the default path stages and verifies and stops.
  Worth noting because `swarm.post_merge_verification`'s `rollback_behavior`
  states *"nothing is committed"*, which is true of the default path and not of
  the tool.
- `build-os/metrics/record-packet.sh` — appends a row to the live metrics store.
- `.claude/hooks/build-os-identity.sh` — writes the identity stamp into the repo.
- `build-os/tools/specialist-handoff.sh` — takes a lock file under `$HOME`.

**The gap this exposes is a coverage gap, not a misclassification.** Five modules
perform durable writes and **not one of those write ACTIONS is a registered
control at any authority** — the registry covers the checks that guard them. That
is precisely the thing `execute` was added to be able to express, and expressing
it means **writing new entries**, which is registration, which is the operator's.

**Two governance questions are recorded here and answered nowhere:**

1. **Should Class A license `execute`?** Today no class does, so `execute` is a
   rung with no licensed occupant. That is deliberate: adding a rung must not
   grant anyone anything.
2. **Should `maint.managed_set_replacement` move from `advise` to `execute`,**
   and should the five mutating actions above be registered in their own right?

Both are re-authorisations. **Neither is performed here.**

---

## 16. THE LADDER'S SPELLING IS NOT SWEPT — recorded as a packet, not built here

`tests/evidence_policy_tests.sh` §21 sweeps the **semantics** of `observe` across
seven named sites, by content, in both of the retired rule's wordings. **It does
not sweep the ladder's SPELLING**, and that omission has a measured cost: adding
`execute` above `gate` left the five-rung enumeration
`none < observe < advise < rank < gate` behind in **five** live places, and every
one of them was found by a human reading the diff rather than by the suite.
**This section originally said four**, and the fifth was found by the re-review
after the correction shipped — in a file this packet had already edited. It
escaped every sweep, mine and the reviewer's, because **the enumeration wraps
across a line break**: `none < observe < advise` on one line, `< rank < gate)` on
the next. No same-line grep can see it; a multiline scan finds it immediately.
The undercount is left visible above rather than silently corrected, because a
completeness claim that was wrong is the evidence for why this guard is needed.

The sharpest of the four was **a passing test whose transcript printed a false
ladder**: `tests/authority_envelope_tests.sh` and `tests/evidence_policy_tests.sh`
each compared the tool's printed ladder against the **six**-rung `$LADDER` — the
assertion was correct — and then reported success with a hard-coded **five**-rung
string. The proof was right and the **evidence it emitted was wrong**, which is
the worst of the four because it is the one a reader would have trusted.

**Why it is a separate packet and not part of the fix that found it:**

- **The site set is different.** The drift landed in `tests/*.sh` `ok` messages, a
  README-declaration probe, and a rank comment — **none** of which are among §21's
  seven semantic sites. Sweeping it means declaring and justifying a second,
  larger site list.
- **The check is a different shape.** §21 asks *"does this line carry a forbidden
  clause?"*. This asks *"does this enumeration STOP at `gate`?"* — and the
  five-rung string is a **prefix of the correct six-rung one**, so a naive grep
  matches the right answer as readily as the wrong one. It needs a
  continuation test, not a containment test.
- **Bolting a second new guard onto a bounded fix round is how fix lists arrive in
  installments**, which is the failure the round budget exists to prevent.

**The five sites were repaired by hand and are listed so the packet can prove it
found them all** — a claim it got wrong once already, which is the point:
`build-os/tools/authority-envelope.sh` (the S1 argument), `README.md` §2's
composition rule, both suites' `ok` messages (now derived from `$LADDER` rather
than typed), `tests/control_registry_tests.sh`'s rank comment, and
`tests/neurocosmology_crosswalk_tests.sh`'s LADDER-order comment — the
line-wrapped one, added last. **A hand repair with no guard behind it is exactly
the state this section exists to record**, and a hand repair that miscounted its
own site list is the sharpest evidence available that the guard is owed.

---

## 17. THE MUTATION CENSUS — acted on for the SIX, and still not for the TWO

§15 surveyed the mutation coverage gap and deliberately did not act on it. This
section records what changed, and — more importantly — what did **not**.

**Six write actions are now registered, at `execute`.** They were previously
registered at **no authority at all**: every control sitting on those modules
classified a *check* and not a *write*. Six controls sit on `record-packet.sh`
and each one classifies a refusal that runs **before** the append.
`tools.handoff_lock` classifies a fail-closed acquisition, not the lock.
`maint.rotation_conservation` classifies a property of a *plan*, not the rename
that applies it.

**Why they are in this file at all.** `execute` is a rung, not a licence. **No
class licenses it** — README §3's table is untouched and **0 of its 30 cells**
reach the rung — so a control that performs a durable write exceeds its licence
*by construction*. That is what these six rows record. **It is not a grant.**
Nothing was re-authorised to make them legal, and nothing here proposes that
Class A should reach `execute`; that question is the operator's, and these rows
exist to make it askable with a list attached.

**How to read the `the line that gates` column for these six.** It does not name
a line that gates, because none of them gates. It names **the line that
mutates** — the rename, the commit, the append, the stamp write, the lock
release. The column header is kept as it is rather than split, because
`scan-controls.sh` §8 and `control_registry_tests.sh` §19 both parse this table
and neither should be rewritten to accommodate prose.

**THE TWO THAT WERE NOT ACTED ON, and this is the load-bearing half of the
section.** The survey found two further modules meeting the same mechanical test
for `execute`, and **both are left exactly where they are**:

| control | at | behaviour requires | why not moved |
|---|---|---|---|
| `maint.managed_set_replacement` | `advise` | `execute` | **FINDING-0001** — it is a PRE-EXISTING control |
| `hooks.once_dedup` | `advise` | `execute` | **FINDING-0002** — same, and the better remedy is a new control, not a move |

**Registering a NEW control is authorised build work; moving an EXISTING one is a
re-authorisation and belongs to the operator.** §15 said exactly this and it is
still true. `maint.managed_set_replacement` remains the sharpest entry in the
whole census — it declares its own output as *"files copied into an installed
repo, replacing prior managed copies"*, its failure behaviour as *"none that
stops anything"*, and its rollback as *"none"* — and it is **still at `advise`**,
because moving it would be indistinguishable, in the diff, from the census
quietly granting itself the right to relabel the things it censuses.

That restraint is **mechanically enforced, not merely promised**.
`build-os/registry/governance_baseline.txt` pins the class, runtime authority and
mismatch flag of all **81** controls that existed at `7daedee`; both
`scan-mutators.sh check` and `tests/mutator_registry_tests.sh` §11 fail if any of
them moves without that file being edited in the same diff. And each finding is
checked against its own subject, so a remedy applied without updating the finding
— or a finding deleted to make the accusation go away — fails too.

## What this list is not

It is **not** a defect list. Thirteen of these fourteen `gate` entries cover controls
that have caught something or plausibly would; several are the best-argued code in the
repository, and `check-adoption.sh` in particular reasons about its own
thresholds more carefully than most production systems ever do.

The claim is narrower, and it is the whole point of the registry: **fifty-six
fitted constants, thresholds and prose regexes can stop a build here, grouped
into fourteen `gate` registry entries, and until this file existed, nothing anywhere
said so.** A reader of `check-adoption.sh` learns that its thresholds are a
median of four packets only by reading a hundred lines of comment. A reader of
`supervise.sh` learns nothing at all. Whether that authority should stand is a
question for the operator; whether it was ever *decided* is a question this file
now answers with "no".

**And the things this file got wrong about itself.** Its first version said six
constants where there were thirty-four, called `probe()` sound in the direction
it is actually unsound, and cited a `fi` as the line that gates. A later version
excluded a line from the family for a reason that was not true (§10), and cited
a `grep` as the point where the discovery rule exits 2 (§13). All of them were
found by reading the artefact against the tree rather than against its own
claims, and each was found by a wider hand sweep than the last — which is the
signature of a defect that needs a check, not another sweep. The lesson is the
one `scan-controls.sh`'s header states: a document that reconciles only against
its own claims reconciles against nothing. The counter-measure is in this
round's `VACUOUS-REF` check, and its limits are stated where it is defined.
