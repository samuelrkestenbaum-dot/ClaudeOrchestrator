# RED-TEAM AUDIT — whole-system validation packet (design-only, adversarial)
Auditor stance: skeptical external reviewer attempting to invalidate any
future Gravito advantage. Scope: DESIGN rev 3, DECISION-PACKET, roadmap
interaction, whole-system-validation-kit/*. Every fatal/high finding below
has a correction APPLIED in this commit; mediums fixed where cheap; lows
recorded as residuals. Ranking = severity if left unfixed at freeze.

## FATAL (would have invalidated headline claims; both corrected)

**F1 — Gravito's own model calls were not explicitly metered.** Exploit: arm
B's compilation/orchestration/verification/recovery may itself call models;
nothing REQUIRED those tokens to appear in the ledger → "fewer tokens" wins
by hiding infrastructure spend. Affected: every token/cost claim. Correction
(DESIGN rev 4 §T2; telemetry `infrastructure_usage`): ALL model calls made
by any Gravito component are provider-metered in the same native categories
and charged to arm B (setup or ongoing by timing); an unmetered
infrastructure call discovered post hoc is a hard veto for token claims.
Residual: detection relies on provider accounting completeness.

**F2 — concurrent "active time" was summable into a speed illusion.**
Exploit: arm B runs 4 workers 15 min each; "active time" read as 15 min vs
native's 40 → "2.7× faster" bought with 4× compute. Affected: all
speed/active-hour claims. Correction (DESIGN rev 4 §T1): two defined
quantities — ACTIVE WALL TIME (elapsed with ≥1 active worker) and AGGREGATE
COMPUTE TIME (sum over workers); "faster" claims use active wall under the
EQUAL-CONCURRENCY estimand only; both quantities always reported; the
natural-operation estimand reports throughput, never "faster". Residual:
none beyond honest labeling.

## HIGH (corrected)

**H1 — model identity/cross-model token incomparability.** Exploit: B routes
to cheaper/smaller models; token counts incomparable; "fewer tokens" is a
routing artifact. Correction (rev 4 §T3): model id pinned per arm at freeze;
if B legitimately uses multiple models, tokens are reported PER MODEL ID,
cost is the only cross-model comparator, and same-model token claims are the
only token claims. — **H2 — environmental re-run laundering.** Exploit: a
failing arm gets an "outage" label and a fresh second attempt
(post-treatment exclusion). Correction (rev 4 §T4): exclusion requires
machine-generated contemporaneous telemetry evidence; adjudicated by written
rule blind to interim progress; max ONE environmental re-run per arm-task;
re-run starts from a fresh clone (interim work discarded); per-arm exclusion
counts reported and a >2:1 asymmetry flags the study for review. —
**H3 — multiplicity/selective reporting.** Exploit: 5 metrics × gross/net ×
weighted/unweighted × phases → dozens of intervals; one chance exclusion
becomes the headline. Correction (rev 4 §T5): the five owner metrics ITT
form the SOLE primary family; directional claims report unadjusted AND
Holm-adjusted (m=5) intervals; product claims require adjusted exclusion;
everything else is labeled exploratory. — **H4 — no frozen negative-result
rule or completeness manifest.** Exploit: a null quietly reframed as
"mechanism learning". Correction (rev 4 §T6): frozen rule — every
preregistered metric is published with the same prominence regardless of
direction; a negative/inconclusive product result is reported as exactly
that, with mechanism speculation confined to a marked exploratory section; a
COMPLETE-RESULTS MANIFEST (every cell, every preregistered analysis, per-file
sha256 of raw telemetry) ships with the read; absence of any preregistered
item invalidates the report.

## MEDIUM (cheap — corrected)

M1 FAQ gaming → FAQ frozen at freeze, unamendable after first run,
per-arm hit counts reported (OPERATOR-PROTOCOL). M2 token-metric ambiguity →
"exact tokens" preregistered as uncached input + cache_creation + output;
cache_read reported separately; cost carries pricing (rev 4 §T3). M3
provider-latency confound → per-request latency captured in session_usage
and reported per arm (telemetry). M4 blinding leak via commit topology →
review object is the SQUASHED unified diff, never the commit graph
(ACCEPTANCE doc). M5 tamper-evidence → hash-chained JSONL batches + raw
provider usage retained; manifest per H4 (telemetry). M6 CV instability →
robust dispersion (median/IQR) reported beside CV; consistency claims
require both to agree in direction (rev 4 §T5).

## LOW (documented residuals, no paperwork inflation)

Operator approval-latency bias (timestamps make it measurable) · milestone
blinding is weaker than task blinding (large diffs resist sanitization —
disclosed) · repo memorization (rubric mitigates; not eliminable) · style
deblinding (measured via forced guesses; not preventable) · single operator
(audited; not solved) · continuation test is descriptive, never gated (rev 4
§T7 makes this explicit).

## Contradiction sweep

Authority order, supersession notes, terminology (active time, GROSS/NET,
ITT), statuses, and defaults checked across DESIGN/PACKET/ROADMAP/kit after
corrections: one stale point found and fixed — the kit index's consistency
note predated rev 4 and is updated. The §9-vs-roadmap ordering tension
remains an OPEN OWNER RECONCILIATION, correctly labeled.

## Reproducibility statement

An independent reviewer holding only the repo artifacts can reproduce the
DECISION LOGIC end to end: question → design (rev 2–4) → decision packet →
kit templates → this audit, with every default labeled PROPOSED and every
frozen-later field explicit. They cannot reproduce any RESULT — none exists
— and nothing in the artifacts claims executed reliability.

## Readiness classification

**DESIGN-COHERENT.** Not qualification-ready (logger and metering exist as
specification only; calibration unexecuted). Not freeze-ready (12 owner
decisions + repository). Not execution-ready. This classification is the
ceiling the evidence supports.
