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

1. **11 of 75 classified controls gate on `unvalidated` evidence.** Eleven
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
2. **14 of 75 entries exercise `gate` on a class that does not license it.**
   `grep -c '^authority_mismatch: declared' control_registry.txt`. All 14 are
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
| `tests.stdin_scan_nonvacuity` | C | gate | advise | `tests/build_os_tests.sh:959` | 1 |
| `tests.nonvacuity_minimums` | C | gate | advise | `tests/entitlement_tests.sh:126` (+33 more, §10) | 34 |
| `tools.handoff_timeouts` | C | gate | advise | `build-os/tools/specialist-handoff.sh:151` | 3 |
| `tools.supervise_timeout` | C | gate | advise | `build-os/tools/supervise.sh:49` | 2 |
| `registry.discovery_rule` | C | gate | advise | `build-os/registry/scan-controls.sh:385` | 2 |
| `bandwidth.active_packet_singleton` | C | gate | advise | `build-os/tools/bandwidth-check.sh:136` | 1 |

<!-- MISMATCH-TABLE:END -->

**`sites` is a hand count**, taken from the sections below, of the distinct
fitted constants, thresholds and prose regexes inside each entry — not a grep.
It totals **56**. It is in the table because the entry count (14) is the number
that gets quoted, and the entry count is a property of how finely this registry
was cut, not of how much heuristic authority the repository actually carries.

There is no Class D and no Class R anywhere in this system, so the second half of
the safety claim — that a learned model may not outrank an invariant — is
currently vacuous here. It is asserted by the suite anyway, so that it stops
being vacuous the day something learned arrives.

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

## 9. `tests.stdin_scan_nonvacuity`

**Gates at** `tests/build_os_tests.sh:959`. **Threshold** `PIN_MIN_SITES=10`
(`:935`, tested at `:957`).

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

- `tests/build_os_maintenance_tests.sh:193` (`-gt 180000`) — a property of a
  fixture *this test constructs itself*, so it is deterministic by construction
  and not a floor on a scan of the tree.
- `tests/pilot_kit_tests.sh:340` (`-ge 15`) — a length floor on failure *text*
  inside a falsifiability driver, not a coverage floor.
- `tests/speed_benchmark_tests.sh:405` (`-ge 12`) — `[ "${#nt}" -ge 12 ]` is a
  floor on the LENGTH OF A STRING, identical in kind to the exclusion above it,
  not a floor on how much a scan of the tree covered. The membership rule admits
  coverage and size floors; a minimum note length is neither.

  **This exclusion's stated reason used to be false, and it is worth recording
  why rather than quietly swapping it.** It said the line "mirrors
  `metrics.record.note_minimum`" and that "counting it here would classify one
  line twice". Neither half held. `metrics.record.note_minimum` cites
  `build-os/metrics/record-packet.sh:51` and `:119` — the constant and the
  comparison in the recorder — and **no entry cites
  `tests/speed_benchmark_tests.sh:405` at all**; including it produces zero
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

`tests/control_registry_tests.sh:772` is `[ "$PASS" -ge 40 ]`, whose failure
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

**Gates at** `build-os/registry/scan-controls.sh:385` (an unregistered surface is
a violation) and `:452` (`exit 2`).
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

## What this list is not

It is **not** a defect list. Thirteen of these fourteen entries cover controls
that have caught something or plausibly would; several are the best-argued code in the
repository, and `check-adoption.sh` in particular reasons about its own
thresholds more carefully than most production systems ever do.

The claim is narrower, and it is the whole point of the registry: **fifty-six
fitted constants, thresholds and prose regexes can stop a build here, grouped
into fourteen registry entries, and until this file existed, nothing anywhere
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
