# Baseline capture — measuring the world before Gravito

A pilot without a baseline measures nothing. This describes how to capture the
"before" picture, and the meter-reading discipline that makes the "after"
picture comparable.

**Capture the baseline BEFORE installing anything.** Once the gate is live, the
un-governed world is gone and cannot be reconstructed.

---

## 1. What to measure

Five things, on the same task mix you will run during the pilot, over a fixed
period (a week is the usual unit).

| measure | how | who records it |
|---|---|---|
| **accepted tasks** | count of tasks whose output your team judged acceptable, plus the count attempted | your acceptance judge |
| **elapsed** | wall-clock minutes from starting a task to accepting or abandoning it | whoever does the task |
| **human interventions** | count of times a person had to stop, correct, or steer an in-flight AI session | whoever does the task |
| **rework** | count of tasks that had to be re-done after being called finished | your acceptance judge |
| **provider spend** | the two meter readings bounding each window, verbatim | your named meter reader |

**Record the denominators.** "4 accepted" means nothing; "4 accepted of 5
attempted" means something. Every count needs the population it came from.

---

## 2. The meter-reading discipline

This is the part that is easy to get wrong and impossible to fix afterwards.
Five rules, and they are not optional.

### Rule 1 — Operator-observed

A human reads the meter with their own eyes and writes down what it says. **No
value is calculated, inferred, or derived from provider tokens.** A
token-derived spend figure is a different measurement wearing the same label,
and mixing the two produces a comparison that means nothing.

### Rule 2 — Verbatim

Write what the display says, exactly, including its own wording and direction.
If it says `Weekly usage · all models — 86%`, write that. Do **not** normalise
it to "14% remaining"; the display's direction ("used" vs "remaining") is part
of the datum. If a value is not displayed, write **"Not displayed"** rather
than computing it.

An actual baseline reading, as recorded:

```
- Time observed: August 6, 2026, 12:11:12 AM EDT
- Weekly usage: Weekly · all models — 86%
- Weekly remaining: Not displayed
- Model breakdown: Weekly · Fable — 72%
- Reset date/time: Resets at 4:00 PM
- Detailed meter reset display: Resets in 15 hr 49 min
- Meter freshness: Last updated 7 minutes ago
- Operator note, verbatim: "I did not calculate the unshown remaining
  percentages or infer a reset date."
```

### Rule 3 — At window edges, and only there

One reading immediately **before** the measured work begins, one immediately
**after** it ends. Nothing in between. The window is bounded by the two
readings, and **report-writing happens outside it** — a window that includes
writing up the results measures the writing up.

### Rule 4 — Like-for-like

The AFTER reading must come from the **same display** as the BEFORE reading, so
the delta is computed between comparable verbatim values. A reading from a
different screen is a different instrument.

### Rule 5 — Watch for the reset

If the plan's usage meter resets inside your window, **the AFTER reading is
confounded** and the delta must be computed against a post-reset re-baseline,
not the original. Record the reset time in the BEFORE reading so you can see
this coming. A confounded window is recorded as confounded and excluded — **it
is never repaired into looking clean.**

---

## 3. The recorder

`build-os/measure/window.sh` encodes the discipline mechanically:

```bash
build-os/measure/window.sh open  <dir> --model <id> --reading "<verbatim text>"
build-os/measure/window.sh note  <dir> --task <id>  --event "<one line>"
build-os/measure/window.sh close <dir> --reading "<verbatim text>" \
                                       --repo <path> --since <sha>
```

- `open` **refuses without `--reading`**: a window with no opening reading is
  not a measured window.
- `note` records task events *inside* the window only.
- `close` requires the closing reading and derives durable output from git
  rather than accepting a hand-entered number.
- Everything lands in `WINDOW.tsv` as verbatim rows. **The tool does not
  compute the delta** — you compute it, between two verbatim values you can
  both see.

**Known defect, disclosed rather than discovered later:** `close` prints the
git-derived commit count to the terminal but writes the literal text
`derived-from-git` into the stored `commits=` slot. The **files / insertions /
deletions** figures on that row *are* stored and usable. Capture the commit
count from the terminal output yourself until that is fixed. The evidence
dashboard reports durable commits as `unavailable` for exactly this reason
rather than pretending.

---

## 4. Baseline for the repository itself

Separately from the human measures, capture the mechanical state of the
repository before anything changes:

```bash
build-os/intake/repo-intake.sh /path/to/repo --out ./baseline-intake
```

and, if and only if you have decided your test command is safe to run
automatically:

```bash
build-os/intake/repo-intake.sh /path/to/repo --out ./baseline-intake --run-baseline
```

Without `--run-baseline` the report says `BASELINE: NOT MEASURED` and makes no
red/green claim, **because a baseline nobody ran is not a baseline.** With it,
each discovered or guessed test/typecheck command runs inside your repository
with a timeout and its exit code is recorded. That flag executes your test
suite; decide deliberately.

Also record, by hand: current HEAD sha, whether the suite is green today, the
suite's runtime, and any test you already know is flaky.

---

## 5. What makes a baseline unusable

Say so out loud if any of these are true, rather than proceeding quietly:

- The task mix in the baseline period is not comparable to the pilot period.
- The people are different, or their familiarity with the code is very
  different.
- The baseline period contained an incident, a release crunch, or a holiday.
- The meter reset inside the window and no re-baseline was taken.
- Spend was estimated from tokens rather than read from the meter.
- Nobody was actually judging acceptance, so "accepted" means "nobody
  complained".

**A named-as-unusable baseline is worth more than a clean-looking one nobody
believes.** The pilot report is expected to include whatever is unflattering.

---

## 6. What the baseline is not

It is not a benchmark, not a target, and not a promise. It is one repository,
one team, one period. Nobody has yet run a controlled economic comparison of
this product against anything, so your baseline is the only "before" that will
exist for your pilot — which is exactly why it is worth taking seriously.
