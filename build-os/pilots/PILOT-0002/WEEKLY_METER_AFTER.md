# PILOT-0002 — Weekly-credit AFTER reading — OPERATOR-OBSERVED

Recorded verbatim. Tier: OPERATOR-PROVIDED. Nothing calculated or
derived from provider tokens.

- All models: 1%
- Fable: 0%
- Direction wording: none shown
- Reset/freshness: Resets Thu 4:00 PM; freshness none shown

Operator's note, verbatim: "The displayed weekly readings are unchanged
from the baseline: 1% / 0%. Nothing was sent to Claude, and no follow-on
work was triggered."

## The delta

BEFORE: all models 1%, Fable 0%.
AFTER:  all models 1%, Fable 0%.
DELTA:  **0 displayed percentage points on both meters.**

## What this does and does NOT establish

IT ESTABLISHES: five accepted real-repository tasks, executed inside a
clean window containing nothing but those tasks and their receipts, did
not move either displayed meter by a single percentage point.

IT DOES NOT ESTABLISH that the pilot was free, or that consumption was
near zero. The display shows whole percentages and Fable stood at 0%
before the window. Consumption is therefore bounded ABOVE by less than
one percentage point and is otherwise UNRESOLVED — it could be anywhere
in [0, 1). A display that cannot distinguish 0.05% from 0.95% cannot be
made to yield a point estimate by staring at it harder.

## The headline metric is UNDEFINED, and that is the honest answer

The registered headline — durable accepted output per percentage point of
weekly meter movement — has a denominator of zero displayed points. The
ratio is undefined, not infinite. Reporting "infinite output per point"
would be a division-by-zero dressed as a result.

The defensible statement is bounded, not ratio-shaped:

  Five accepted tasks, five durable commits, 24 type errors removed and
  a test file taken from 3-failing-1-skipped to 17/17, completed in about
  32 minutes of measured task time with zero human interventions, WITHOUT
  moving either displayed weekly meter off its starting value.

## Comparison to PILOT-0001, stated carefully

PILOT-0001's window was 5h47m and contained substantial non-pilot
activity; its result was a CEILING of 2 displayed points, not a
measurement. PILOT-0002's window was ~38 minutes and contained only the
five tasks. Both readings are consistent with per-pilot consumption
below one displayed point; PILOT-0002 constrains it far more tightly
because its window has almost nothing else in it.

To resolve consumption BELOW display granularity, a future pilot needs a
finer instrument than this meter — provider-side cost telemetry, or a
pilot large enough to move a whole point deliberately. That is a
measurement-design conclusion, not a product one.
