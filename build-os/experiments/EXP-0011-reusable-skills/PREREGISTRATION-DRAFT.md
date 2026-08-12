# EXP-0011 — Reusable learned skills (Phase 2, proof 2) — DRAFT FOR FREEZE
# STATUS: DRAFT. Not frozen. Operator freeze amendments expected, as on
# EXP-0009/0010. Three decisions below are flagged rather than silently made.

## Question (D4)

Rules proved that memory of WHAT-TO-DO compounds (EXP-0010). Proof 2 asks
whether a **skill** — a reusable multi-step PROCEDURE the worker can apply,
above the level of a single error-class idiom — compounds further, on tasks
whose discovery cost is real.

## What carries over unchanged (proven apparatus)

Seed `2543c873`, runnable environment/grants/timeouts, model, 1200s ceiling,
acceptance adjudicator (with the two named instrument fixes below), frozen
classifiers, per-sequence-per-rep store isolation with provenance gates,
position-matched primary interpretation, TOM guard (worker consumes, never
administers), active executor, admissibility rules, mechanical
harness-authored distillation.

## Instrument fixes REQUIRED before freeze (legal between studies)

1. `selectRules`-style installer: break → continue at the cap (an oversized
   item must not block smaller ones behind it) + regression test.
2. Diff adjudicator: `any_cast` (and sibling patterns) must not fire on
   added lines that are comments/strings — prose "as any" is not a cast;
   regression test uses the preserved A1.leanrules.r1 diff verbatim.

## DECISION 1 (operator): the corpus

EXP-0009/0010 ran on self-contained fix tasks — memory's most hostile
setting, deliberately. Branch 1 confirmed there anyway, but proof 2's effect
size depends on discovery being genuinely expensive. Options:

- **(a) Multi-class files from the same frozen corpus:** sequences of files
  each carrying SEVERAL distinct error codes (the corpus has such files), so
  a task needs broader type understanding than one idiom. Mechanical
  derivation stays trivial; adjudicator unchanged; discovery cost moderate.
- **(b) Subsystem sequences:** 5 tasks confined to one subsystem
  (e.g. server/governance), mixed codes, where conventions repeat across
  positions. Skill = the subsystem's conventions. Derivation still
  mechanical (cluster by directory instead of by message).
- **(c) A new task family beyond tsc fixes** (e.g. "add an endpoint following
  existing patterns") — highest discovery cost, but requires a NEW
  adjudicator, which means a new instrument to validate first. Highest risk,
  slowest.

Draft default: **(b)**, as the largest discovery-cost step that keeps the
proven adjudicator.

## DECISION 2 (operator): what a "skill" mechanically IS

Draft: a harness-compiled `SKILL.md` installed at `.claude/skills/<name>/`
in the administered tree — the platform's native skill surface, so the worker
can invoke it as a capability rather than read it as context. Compiled
mechanically from the sequence's OWN prior accepted arms: the union of their
distilled rules plus a template procedure section (ordered steps derived from
the common tool-call sequence of accepted arms — e.g. "verify → locate by
error line → apply idiom → re-verify"). No experimenter prose. Alternative
(flagged): keep delivery as memory-file context (EXP-0010's transport) and
test only content-level aggregation — smaller step, weaker claim.

## DECISION 3 (operator): the comparator

Draft: three-way per position — native (fresh), leanrules (proof-1 design,
new arms on the new corpus), leanskills. leanrules-vs-leanskills is the
marginal-value question ("does the skill add anything beyond rules?");
native anchors economics. Cost: 3 arms × 2 seqs × 5 pos × 2 reps = 60 arms
(~10h serial; #53 parallelization becomes attractive). Alternative: drop the
leanrules arm (20 fewer arms) and lose the marginal-value comparison.

## Fork sketch (finalized at freeze)

Primary: position-matched ratios vs native, cost + uncached. Branches:
skills > rules > native (marginal value confirmed) / skills = rules > native
(aggregation adds nothing — rules suffice; proceed to proof 3 with rules) /
skills < rules (skill packaging drags — keep rules, reject skill surface) /
acceptance loss (FAILS) / favorable-without-use (confound; skill invocation
is structural: skill reads/invocations in-stream).

n gate: fork applied only when both reps exist. No rescue variants.
