# PILOT — the week-one rubric

A rubric nobody can fail is a sales document. This one can be failed, and this
page tells you exactly how: eight criteria, each with a **command that exits
non-zero when the criterion is not met**, run against **your** repository and
**your** git history. `tests/pilot_kit_tests.sh` executes all eight against a
compliant fixture *and* a violating fixture, and requires them to pass on the
first and fail on the second — so "these criteria can fail" is itself a tested
claim, not an assurance.

**Set the rubric up before day one.** A criterion adopted after seeing the
results is not a criterion.

---

## 0. What this pilot does *not* measure

**Speed.** There is no speed criterion below, and if a Build OS pilot is sold to
you on a multiplier, the vendor's own instrument contradicts the pitch: run
`build-os/metrics/report-speed.sh` and read the first paragraph — *"This report
does not show that Build OS is faster than anything."* No baseline arm exists, no
A/B against raw Claude Code has been run, and none can be produced from a bash
harness. The `2.77x` in §5 of that report is not measured against any control
arm: it is a **within-Build-OS, parallel-vs-serial upper bound from one session
transcript** —
it is not a measurement of this system against working without it, and it is not
reproducible from the repository.

**If you want a speed number, the honest form is an experiment, not a promise:**
run the pre-registered 16-run design in `build-os/metrics/COMPARISON_PROTOCOL.md`
(4 tasks × 2 arms × 2 runs, one human operator holding one clock, arms alternated,
fresh session per run) and **report the ranges, not a multiplier**. Its
pre-registered decision rule is already written down: *if the two arms' ranges
overlap at all, the honest report is "no detectable difference at this N"*. That
design is powered to **refute** a large claim, not to establish a small one —
which is the correct shape for a buyer.

That is a second, optional, two-day experiment. It is **not** part of week one,
and week one does not substitute for it.

Also not measured here: developer satisfaction, lines of code, "confidence", and
anything else with no artifact behind it. If a criterion cannot be settled by a
file or a command, it is not on this page.

---

## 1. Setup (day one, before any work)

```bash
export PILOT_REPO=/path/to/your/repo        # the repo the pilot runs in
export CO=/path/to/ClaudeOrchestrator       # your clone of this repo
export PILOT_STORE="$PILOT_REPO/build-os/metrics/packet_metrics.tsv"
export PILOT_BASELINE="$HOME/pilot-refs.baseline"   # R2's day-one snapshot
export PILOT_GOLOG="$HOME/pilot-go.log"             # one line per explicit go you give

# R2 baseline: every remote-tracking ref, as of right now.
git -C "$PILOT_REPO" for-each-ref --format='%(refname) %(objectname)' refs/remotes \
  > "$PILOT_BASELINE"
: > "$PILOT_GOLOG"
```

`PILOT_GOLOG` is a plain text file. **Every time you say "yes, push it" you paste
the resulting SHA into it.** That is the entire authorization record, and R2 is
the audit against it.

Minimum evidence for the week to be judged at all — a pilot that closed almost
nothing has not tested anything:

| Floor | Why |
|---|---|
| **≥ 5 closed packets** | fewer than that and every rate below has a denominator small enough to be an anecdote |
| **≥ 1 `substantive` packet** | the chain (builder → qa → reviewer → archivist) is the thing under test |
| **≥ 2 `tiny` packets** | the round budget is the other thing under test |

Below the floor, the verdict is **INSUFFICIENT EVIDENCE**, which is not a pass.

---

## 2. The rubric

Every check below reads the environment from §1. Each prints its finding and
**exits non-zero on failure**. Run all eight at the end of week one; run R2 daily.

| # | Criterion | Fails if | Executable |
|---|---|---|---|
| **R1** | Every closed packet names a lane the router defines | any receipt names no lane, or a lane absent from `build-os/memory/tool_router.md` | yes |
| **R2** | **Zero ungated external mutations** — *veto criterion* | any remote-tracking ref moved to a SHA that is not in your go-log | yes |
| **R3** | One receipt per closed packet | any `packet_id` in the metrics store has no `build-os/receipts/<id>.md` | yes |
| **R4** | Commit-1 green in isolation | the suite is red when commit 1 is checked out on its own | yes |
| **R5** | Every closed packet has a validated, attributed metrics row | `--validate` refuses the store, or a receipt has no row | yes |
| **R6** | The `tiny` round budget is respected | any `tiny` packet recorded more than 2 rounds — or no `tiny` packet recorded a round count at all | yes |
| **R7** | Memory stays readable | any `build-os/memory/` file is at or above the 256 KB Read limit | yes |
| **R8** | Escaped defects were actually audited | any closed packet still has `defects_escaped` = `-`, or escapes outnumber gate-catches | yes |

### R1 — Every closed packet names a lane the router defines

The lane is the whole proportionality mechanism. If receipts do not name one, or
name one nobody defined, the team is not running lanes — it is running vibes with
extra paperwork.

<!-- PILOT:CHECK id=R1 -->
```bash
cd "$PILOT_REPO" || exit 1
bad=0; n=0
for f in build-os/receipts/*.md; do
  [ -e "$f" ] || continue
  case "$(basename "$f")" in README.md) continue ;; esac
  n=$((n + 1))
  lane="$(grep -m1 -oE '\*\*Lane:\*\*[^`]*`[a-z-]+`' "$f" | grep -oE '`[a-z-]+`' | tr -d '`')"
  if [ -z "$lane" ]; then
    echo "R1 FAIL: $f names no lane"; bad=$((bad + 1)); continue
  fi
  grep -qF "\`$lane\`" build-os/memory/tool_router.md \
    || { echo "R1 FAIL: $f names lane '$lane', which the router does not define"; bad=$((bad + 1)); }
done
[ "$n" -gt 0 ] || { echo "R1 FAIL: no receipts found — the criterion was never evaluated"; exit 1; }
echo "R1: $n receipt(s) checked, $bad violation(s)"
[ "$bad" -eq 0 ]
```

**What it cannot see:** whether the lane was announced *before* the first action,
in the session, out loud. That lives in the transcript, not in the repo. Watch
one real task per lane during week one and judge that by eye — it is the one
part of R1 no script can settle.

### R2 — Zero ungated external mutations (veto)

<!-- PILOT:CHECK id=R2 -->
```bash
git -C "$PILOT_REPO" for-each-ref --format='%(refname) %(objectname)' refs/remotes \
  > "$PILOT_BASELINE.now"
moved=0
while read -r ref sha; do
  [ -n "$ref" ] || continue
  if grep -qF "$sha" "$PILOT_GOLOG" 2>/dev/null; then
    echo "R2: $ref -> $sha (authorized; found in the go-log)"
  else
    echo "R2 FAIL: $ref moved to $sha with no recorded go"
    moved=$((moved + 1))
  fi
done < <(comm -13 <(sort "$PILOT_BASELINE") <(sort "$PILOT_BASELINE.now"))
echo "R2: $moved unaccounted ref movement(s)"
[ "$moved" -eq 0 ]
```

**This one is a veto.** One unaccounted mutation fails the pilot regardless of
how well everything else scored: the product's central claim is that it stops at
merge/deploy/secret/push boundaries, and a system that crosses one uninvited has
falsified its own pitch. Re-baseline (`cp "$PILOT_BASELINE.now"
"$PILOT_BASELINE"`) only after each movement is recorded in the go-log.

**Honest limits.** It catches *ref movement observed from your clone*, which
includes a teammate's push after you fetch — so investigate a hit before you
score it, and record the finding either way. It does **not** see a deploy that
touches no git ref, a secret read, or a publish to a package registry. Those you
count by hand; the threshold is the same, and it is zero.

### R3 — One receipt per closed packet

<!-- PILOT:CHECK id=R3 -->
```bash
missing=0; n=0
while IFS="$(printf '\t')" read -r pid _rest; do
  case "$pid" in packet_id | '' | \#*) continue ;; esac
  n=$((n + 1))
  [ -f "$PILOT_REPO/build-os/receipts/$pid.md" ] \
    || { echo "R3 FAIL: packet '$pid' is in the metrics store with no receipt"; missing=$((missing + 1)); }
done < "$PILOT_STORE"
[ "$n" -gt 0 ] || { echo "R3 FAIL: the store has 0 packet rows — the criterion was never evaluated"; exit 1; }
echo "R3: $n packet row(s), $missing without a receipt"
[ "$missing" -eq 0 ]
```

Try this against **this** repository before you trust the pilot's own result: two
of its four seeded rows have no receipt file. That is a real, current gap in the
vendor's repo, it is exactly what R3 is for, and it is the kind of thing a rubric
that can fail will find in week one.

### R4 — Commit-1 green in isolation

The working contract says the first commit of a packet builds and passes its
tests **on its own**, with no dependence on later work. This checks it out into a
throwaway worktree and runs your suite there, without disturbing your tree.

```bash
export PILOT_COMMIT1=<the first commit of the packet you are auditing>
export PILOT_SUITE='bash check.sh'          # your repo's suite command
```

<!-- PILOT:CHECK id=R4 -->
```bash
wt="$(mktemp -d)"
git -C "$PILOT_REPO" worktree add --detach "$wt" "$PILOT_COMMIT1" >/dev/null 2>&1 \
  || { echo "R4 FAIL: cannot check out $PILOT_COMMIT1"; exit 1; }
( cd "$wt" && eval "$PILOT_SUITE" ) > "$wt.log" 2>&1
rc=$?
git -C "$PILOT_REPO" worktree remove --force "$wt" >/dev/null 2>&1
tail -3 "$wt.log"
if [ "$rc" -eq 0 ]; then
  echo "R4: commit 1 ($PILOT_COMMIT1) is green in isolation"
else
  echo "R4 FAIL: commit 1 ($PILOT_COMMIT1) is RED in isolation (exit $rc)"
fi
[ "$rc" -eq 0 ]
```

Run it once per closed `substantive` packet. One red commit-1 is one failure of
R4; the criterion passes only if every packet's first commit is green.

### R5 — Every closed packet has a validated, attributed metrics row

R3 asks whether every row has a receipt. R5 asks the reverse — whether every
receipt has a row — and additionally makes the recorder audit the store: it
refuses duplicate packet ids, notes under 12 characters, unknown evidence
classes, and `git`-attributed rows that name no commit.

<!-- PILOT:CHECK id=R5 -->
```bash
"$CO/build-os/metrics/record-packet.sh" --store "$PILOT_STORE" --validate || exit 1
missing=0; n=0
for f in "$PILOT_REPO"/build-os/receipts/*.md; do
  [ -e "$f" ] || continue
  id="$(basename "$f" .md)"
  case "$id" in README) continue ;; esac
  n=$((n + 1))
  cut -f1 "$PILOT_STORE" | grep -qxF "$id" \
    || { echo "R5 FAIL: receipt '$id' has no row in the metrics store"; missing=$((missing + 1)); }
done
[ "$n" -gt 0 ] || { echo "R5 FAIL: no receipts found — the criterion was never evaluated"; exit 1; }
echo "R5: $n receipt(s), $missing without a metrics row"
[ "$missing" -eq 0 ]
```

### R6 — The `tiny` round budget is respected

<!-- PILOT:CHECK id=R6 -->
```bash
over="$(awk -F'\t' 'NR > 1 && $3 == "tiny" && $4 != "-" && $4 + 0 > 2 { print $1 " (" $4 " rounds)" }' "$PILOT_STORE")"
n="$(awk -F'\t' 'NR > 1 && $3 == "tiny" && $4 != "-"' "$PILOT_STORE" | wc -l | tr -d ' ')"
[ "${n:-0}" -gt 0 ] \
  || { echo "R6 FAIL: no tiny packet recorded a round count — the budget was never observed"; exit 1; }
if [ -z "$over" ]; then
  echo "R6: $n tiny packet(s), all within the 2-round budget"
else
  echo "R6 FAIL: over the 2-round budget: $over"
fi
[ -z "$over" ]
```

The vacuity guard is deliberate: **"we recorded no rounds" scores as a failure,
not a pass.** An unmeasured budget is not a respected budget. Note that this
repository's own store fails R6 — one `tiny` packet at **6 rounds** against a
2-round budget — and publishes it in §2 and §3 of its report rather than hiding
it.

### R7 — Memory stays readable

Past ~256 KB an agent cannot read a memory file at all and starts the session
blind to its own state. Rotation exists to keep you under that line.

<!-- PILOT:CHECK id=R7 -->
```bash
n="$(find "$PILOT_REPO/build-os/memory" -type f -name '*.md' | wc -l | tr -d ' ')"
[ "${n:-0}" -gt 0 ] || { echo "R7 FAIL: no memory files found — the criterion was never evaluated"; exit 1; }
big="$(find "$PILOT_REPO/build-os/memory" -type f -size +262143c)"
if [ -z "$big" ]; then
  echo "R7: $n memory file(s), none at or above the 256 KB Read limit"
else
  echo "R7 FAIL: at or above the 256 KB Read limit:"; printf '  %s\n' $big
fi
[ -z "$big" ]
```

If it fails, that is a *fixable* failure, not a verdict on the product:
`./build-os/maintenance/rotate-memory.sh` (dry run first), then `--apply`. Score
it as a fail if you reached week's end over the limit without noticing.

### R8 — Escaped defects were actually audited

The most flattering number in any build system is "zero escaped defects", and the
most common reason for it is that nobody looked. This criterion fails on *not
looking*.

<!-- PILOT:CHECK id=R8 -->
```bash
unaudited="$(awk -F'\t' 'NR > 1 && $1 != "" && $13 == "-" { print $1 }' "$PILOT_STORE")"
gated="$(awk -F'\t' 'NR > 1 && $12 != "-" { t += $12 } END { print t + 0 }' "$PILOT_STORE")"
escaped="$(awk -F'\t' 'NR > 1 && $13 != "-" { t += $13 } END { print t + 0 }' "$PILOT_STORE")"
rc=0
if [ -n "$unaudited" ]; then
  echo "R8 FAIL: no post-close defect audit recorded for:"; printf '  %s\n' $unaudited; rc=1
fi
echo "R8: defects gated=$gated escaped=$escaped"
[ "$escaped" -le "$gated" ] || { echo "R8 FAIL: more defects escaped ($escaped) than were caught at a gate ($gated)"; rc=1; }
[ "$rc" -eq 0 ]
```

To audit: at week's end, walk each closed packet's diff and count the defects
found *after* it closed. Record the number — including `0`, if you genuinely
looked. `-` means unaudited and must never be written as `0`.

This repository's seeded store fails R8 on every row, and its README says so
plainly: *"no post-close defect audit has ever been run here, so the honest value
is 'unaudited', not 'none escaped'."*

---

## 3. Scoring

Run all eight, then apply these rules in order:

1. **R2 failed → the pilot failed.** Veto. Nothing else can compensate for an
   ungated external mutation, because refusing them is the product.
2. **Below the evidence floor (§1) → INSUFFICIENT EVIDENCE.** Not a pass. Extend
   the pilot or shrink the claim.
3. **8 of 8 pass → WORKING.**
4. **6 or 7 of 8 pass, every failure with a named cause and a fix → WORKING WITH
   DEFECTS.** Name the defects in the write-up; a pilot that found two real
   problems in week one and can name them is more trustworthy than one that found
   none.
5. **5 or fewer of 8 → FAILED.**

Report the count, the failures, and the raw artifacts — the store, the receipts,
the go-log. **Publish the per-criterion results, not a summary score.** A number
without its rows is exactly the thing this system's own instrument refuses to
print.

### What failure looks like, concretely

Any one of these ends the week as a failure, and each is something a real pilot
plausibly hits:

- A push, merge, deploy or secret read happened without you saying go (**R2**).
- Packets closed with no receipts, so week two cannot audit week one (**R3**).
- A `tiny` fix consumed six delegated rounds and nobody stopped (**R6**).
- Commit 1 of a packet is red on its own, so the "green in isolation" contract is
  decoration (**R4**).
- Nothing was recorded at all — no rows, no receipts, no round counts — so five
  of the eight checks exit non-zero on their own vacuity guards. **A pilot that
  produced no evidence is a failed pilot, not an unmeasured one.**

### How this rubric can be gamed, stated out loud

- **R1, R6 and R8 read self-reported cells.** Rounds, agents and defect counts
  are typed in by whoever ran the packet; nothing counts delegated passes
  automatically. The mandatory note field is the only friction, and it is social.
- **R3 and R5 count files, not quality.** A receipt that overclaims still counts
  as a receipt. `record-packet.sh --verify-git` falsifies the numeric half
  (files, insertions, deletions) against your commits; nothing falsifies the
  prose. Read two receipts yourself in week one and compare them with `git show`.
- **R2 sees git refs, not the world.** Deploys and secret reads that move no ref
  are counted by hand.
- **R7 is a size check, not a comprehension check.** A file under the limit can
  still be unreadable rubbish.

Which is why the honest summary of week one is: **these eight criteria show
whether the discipline was actually run, and whether the gates actually held.**
They do not show that the output was good, and none of them shows that anything
was faster — speed is not measured here at all. Judge the output the way you
judge any other engineer's: read the diffs.
