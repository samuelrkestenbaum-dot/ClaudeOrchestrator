# The measured worker was carrying the measurer's agenda

**Runtime/measurement-critical. Found while classifying text-only turns; it
changes the baseline, so it is fixed before any lean design is drawn.**

## What happened

`build-os/motion` was classified as CODE, so `administer()` copied the
orchestrator's **live work queue** into every measured Gravito arm — tasks
#49–#55 of the very session running the experiment. Workers read it (11,415–
22,830 chars/arm) and adopted the posture it implied.

Verbatim, from baseline arms:

```
"Holding."                              ×19  (1.6/arm)
"Stopping."                             ×3
"Standing by."                          ×2
"T04 complete. #55 needs your go."      ×2
"Holding. T01 is done; #55 needs your go."
```

**Native arms produced zero such turns.** A worker asked to fix two type errors
was waiting for operator authorisation on the experiment queue.

## Why the rule failed

The CODE/DATA split classified by **directory**. `build-os/motion` holds both
controllers (`continuation.mjs`, `objective.mjs` — reusable implementation) and
`queue.json` (session state). No folder-level rule can separate them, and the
administration checks only verified that DATA was not *overwritten* — never that
CODE was not smuggling live state in.

## The corrected rule

**State crosses into worker cognition only when its relevance and authority class
permit it.** Classification is by lifecycle, per file, enumerated with reasons —
not by directory. Excluded:

| file | why |
|---|---|
| `build-os/motion/queue.json` | the orchestrator's live work queue |
| `build-os/motion/current.json` | current in-flight item |
| `build-os/learning/dispositions/EXP-0004.json` | a prior run's live disposition record |

Inventory method: every non-executable state record under an administered CODE
directory (40 files) was tested for a live-work signature. **2 matched.** The
other 38 — control registry, defect classes, mutator registry — are reusable
definitions and remain administered. A broader scan for agenda markers hit 53
files, but those are `.mjs` whose *comments* cite prior experiments to explain
why the code exists; provenance commentary in implementation is not leakage, and
sweeping it in would have been the wrong fix.

## Proof, not a promise

`sentinel.test.mjs` plants an unmistakable task in the orchestrator's real queue
and drives the **real** administration path. 11 assertions:

- the orchestrator **can** see the sentinel (or the test proves nothing);
- the measured worker does **not** receive it **anywhere in its tree** — searched
  file-by-file, not just at the path we know about;
- the four load-bearing controllers still arrive, so the exclusion did not throw
  out the implementation with the agenda;
- **MUTATION:** restoring the queue makes `verifyAdministration` REFUSE;
- deliberate supply is still possible — the rule is relevance, not prohibition;
- the orchestrator's queue is restored to its original bytes.

## What this does and does not do to the record

**EXP-0006 is not modified and its headline stands.** It validly measured the
treatment that was actually administered: native 18.15 vs Gravito 10.36 UIC,
12/12 tasks more expensive, p = 2.4×10⁻⁴.

**It is no longer a clean estimate of the intended substrate**, because that
treatment incorrectly included orchestrator-local queue state. No corrected
EXP-0006 number is manufactured, and no waiting turns are retroactively
subtracted — the result happened, and the interpretation is annotated rather
than the arithmetic revised.

**Magnitude, honestly:** ~1.6 waiting turns/arm are directly attributable. An
unknown share of the 6.8 authority-explanation turns/arm may also concern a queue
irrelevant to the task. That is nowhere near the full 2× cost gap, so the
headline is not explained away — but the turn tax is now partly a defect rather
than architecture, and a lean build measured against the contaminated baseline
would take credit for removing it.

**Therefore: re-baseline before LEAN_MANIFEST.**
