# SEAM 6 — earned verification: the uncertainty estimator and verifier router

**Status: v0, INERT.** These tools are invoked explicitly and are wired into no
live execution path. Nothing here changes how a packet is currently routed.

## The product need, in one sentence

Verification is expensive and was being spent automatically; this makes it
**earned by a named trigger** so the system stops paying for confidence it did
not need.

The evidence is executed, not assumed:

- **EXP-0002** measured Gravito ON at **3.96x** the tokens of OFF, driven by
  uncontrolled Full-mode fan-out.
- **PILOT-0001** dispatched one Full verifier. It examined six risk areas, found
  the implementation clean, and **changed nothing** — confidence delivered, no
  unique implementation value, full price paid.

So the default is **one worker plus deterministic tests, and no verifier**. A
verifier runs only when one of SEAM 6's six triggers fires, and the dispatch
records which one bought it.

## The three tools

| File | Does |
|---|---|
| `triggers.mjs` | the shared vocabulary: the six triggers in fixed order, scope rules, sensitive-path patterns, threshold derivation, the y/n/- contribution fields. Imported by all three tools so they cannot drift. |
| `assess.mjs` | the **uncertainty estimator** — outcome descriptor in, per-trigger booleans + firing list + `verification_earned` out. |
| `route-verifier.mjs` | the **router** — assessment + recorded authority in; `none` / `targeted` / `full`, the scope to examine, and the examination questions out. Refuses (exit 2) a dispatch the recorded authority does not permit. |
| `contribution-log.mjs` | records what a verifier actually contributed, and reports **trigger efficacy** — which triggers are worth their cost. |

```sh
node build-os/compiler/verify/assess.mjs < outcome.json > assessment.json
# wrap with the routing receipt's recorded authority, then:
node build-os/compiler/verify/route-verifier.mjs < routing-input.json
# after the verifier runs:
node build-os/compiler/verify/contribution-log.mjs record <log> '<row-json>'
node build-os/compiler/verify/contribution-log.mjs efficacy <log> [--text]
```

`fixtures/index.sample.json` is a SEAM 1 index in the shape `assess.mjs`
consumes. The test suite exercises the shipped sample itself, so it cannot rot
into a lie about the format.

## The six triggers (SEAM 6, exactly)

`incomplete_tests` · `security_surface` · `low_confidence` ·
`diff_over_risk_threshold` · `ambiguous_baseline` · `prior_failed_attempt`

## The honesty rule — an absent signal is never a safe signal

This is the part most likely to be quietly eroded later, so it is stated plainly:

- **Missing test result ⇒ `incomplete_tests` fires.** Absence of a result is not
  evidence of coverage.
- **File absent from the index, or `tests_covering: null`** (SEAM 1's
  not-measured) **⇒ UNKNOWN coverage, and it fires.** Unknown is reported
  separately from measured-uncovered, because they are two different claims.
- **Missing confidence ⇒ `confidence: "unavailable"`**, and `low_confidence`
  does *not* fire — an absent report is not a low report either. Nothing reads
  it as high.
- **A partial descriptor is refused (exit 2)**, following `mode-select.mjs`. If
  nobody answered whether the baseline was ambiguous, these tools will not
  answer it for them.
- **One deliberate non-trigger:** `test_result: "fail"` does not fire
  `incomplete_tests`. A red test is complete evidence — of failure. The response
  to red is to fix it, not to buy a verifier to confirm it. The value is recorded
  verbatim.

## Thresholds, and where they come from

- **Files: 4.** *Cited* from `build-os/tools/mode-select.mjs` rule 1
  ("multi-step in the file sense: `expected_files_changed >= 4`") — the repo's
  one executed definition of a multi-step diff. Reused rather than re-invented,
  so two thresholds cannot disagree.
- **Lines: `files_threshold × lines_per_file_unit`.** The unit is the **lower
  median source-file length in the index** when the index carries line counts
  (`calibration: measured_from_index`). When it does not, the fallback is
  labelled **`unmeasured_declared_default`** — a placeholder whose authority is
  exactly zero. A default that poses as a calibrated value is the dishonesty this
  seam exists to prevent.

## Scope is derived, not assumed

A **security** trigger scopes to the **sensitive files only**, never the whole
diff — targeting is what makes an earned verification affordable. An
**ambiguous baseline** declares itself `unscopable_by_file` and forces `full`,
because what "changed" even means is in doubt; a "targeted" label there would be
a full examination in disguise. `full` is otherwise reached only when 3+ triggers
fire *and* their combined scope already covers every changed file, at which point
targeting buys nothing.

## Authority (mirrors `build-os/memory/routing_contract.md`)

The mode recorded in the routing receipt is **binding**. `none` needs `direct`;
`targeted` needs `gravito_light`; `full` needs `gravito_full`. A dispatch above
the recorded mode requires a **new, evidence-bearing escalation record**
(`escalation` **and** a non-empty `escalation_evidence`) recorded *before* the
escalated work begins — an escalation declared with no evidence is refused,
because evidence-free escalation is not escalation. **De-escalation is free** and
needs no record. Both mode spellings (`light`/`gravito_light`) are accepted; an
unrecognised mode is refused, never treated as permissive.

## Efficacy — how a trigger becomes falsifiable

`caught_rate = caught_defect(y) / rated rows`, where rated means `caught_defect`
is `y` or `n`. Rows recorded `-` are **unrated and excluded from the
denominator** — an unknown is not a zero, and burying admissions in a denominator
is how a rate becomes a lie. A trigger with no rated rows reports a **null**
rate, never 0: no data is not a bad score. A trigger that has fired and caught
nothing on rated evidence is **named as such**. All six triggers appear whether
they have fired or not, because a trigger that never fires is a finding too.
Totals count **rows**, not per-trigger sums: a dispatch bought by two triggers is
one verification.

## Limitations — read these before trusting an output

1. **The thresholds are derived-defaults, not learned.** The file threshold is
   cited from an existing rule; the line threshold is a median of whatever the
   index happens to contain, or a declared placeholder. Neither has been shown to
   correlate with defects. They are defensible starting points, nothing more.
2. **There is no real confidence signal from models today.** `worker_confidence`
   is whatever a worker self-reports, and self-reported confidence is not
   calibrated. In practice it will usually be absent — which is why absence is
   recorded as `unavailable` rather than inferred.
3. **Efficacy needs volume before it means anything.** A rate over a handful of
   rows is noise. The report says so on every emission, and it should be believed
   over the numbers beside it. Do not retire or trust a trigger on single-digit
   volume.
4. **The six triggers are SEAM 6's list, not a proven-complete list.** Nothing
   here establishes that these six catch the defects that matter, only that these
   six are the ones the system agreed to pay for.
5. **Coverage is only as good as the index.** `tests_covering` being populated
   does not mean the test is any good — it means a test claims to cover the file.
6. **Nothing is wired in.** No live path calls these tools. Until something does,
   the economics improvement is potential, not realised.
