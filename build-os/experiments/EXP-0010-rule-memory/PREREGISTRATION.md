# EXP-0010 — Rule-unit memory: does changing WHAT is remembered make memory compound? PREREGISTRATION

**Phase 2, proof 1, attempt 2 on D3. Frozen before any build. The stated
difference from the prior attempt (required by the convergence gate): the UNIT
of memory changes from distilled prior-task reports to mechanically-extracted
repair rules, and delivery becomes SELECTIVE (smallest relevant subset). The
transport does not change.**

## What EXP-0009 established (authoritative, not relitigated)

Push-delivered prose reports about prior tasks are net context drag: the
position-matched leanmem/native gap was most favorable at P1 (empty store,
0.85–0.93) and degraded as memory accumulated (late 0.97–1.07); memory_reads=0
everywhere; acceptance held; harm zero; TOM guard held. Delivery WORKED —
value was the failure. D3 branch 3: redesign memory delivery/content.

## Hypothesis

Memory that carries **reusable decision rules** — canonical repair idioms as
"when X, do Y" procedures with applicability conditions and demonstrated
diff exemplars — delivered as the **smallest task-relevant subset**, pays for
its tokens where 3–5KB of narrative did not.

> Signature: position-matched leanrules/native gap becomes MORE favorable as
> rules accumulate, with acceptance held and rules actually delivered.

## Design — everything reused from EXP-0009 except the memory unit

- **Arms:** ONE new treatment, `leanrules` — the lean substrate at the SAME
  pin `a530659` (identical transport: session-start hook, ≤4KB inline push,
  file `build-os/memory/task-log.md`) — 2 sequences × 5 positions × 2
  isolated reps = **20 new arms**.
- **Comparator:** EXP-0009's 20 frozen native arms, position-matched. Same
  harness, same seed `2543c873`, byte-identical prompts (same builder, sha
  recorded), same runnable environment/grants/timeouts, same model, same
  1200s ceiling, same adjudicator, same frozen classifiers. **No new
  baseline** (operator instruction; precedent: EXP-0007 reused screening
  rep 1). Disclosed plainly: native and leanrules arms are not
  contemporaneous; treatment identity is carried by pin + seed + prompt sha,
  as in every prior study.
- **Sequences/tasks:** identical `sequences.json` (SEQ-A TS18047 db-null,
  SEQ-B TS18046 error-unknown), positions in order, product tree reset to
  seed every position.

## The new unit — mechanical rule distillation (no experimenter prose, ever)

After each admissible leanrules arm, the HARNESS extracts from stored
artifacts only:

1. **Rule identity:** error code + exact message pattern (from the task's
   cluster — mechanical).
2. **Applicability condition:** "files where tsc reports `<code>: <msg>`" —
   template-filled.
3. **Confidence:** derived facts only — accepted verdict, occurrence count,
   originating task id.
4. **Procedure ("when X, do Y"):** up to 2 diff hunks from the arm's OWN
   accepted `full.diff`, first hunks in the task file, each truncated to 30
   lines — the canonical idiom as demonstrated, not described.
5. **Provenance line** (sequence, rep, position, run, authored_by=
   harness-rule-distiller) — same isolation gates as EXP-0009: same-sequence,
   same-rep, strictly-earlier-position, enforced at preflight.

## Selective delivery — smallest relevant subset

At administration, the harness installs into the arm tree ONLY rules whose
error code matches the current task's codes, newest first, **hard cap 1536
bytes**. The hook then does what it always did. Consequences by design:
- P1: no rules exist → nothing installed → hook silent (like EXP-0009 P1).
- P2–P5: matched rules only; the cap keeps delivery inside the inline path
  ALWAYS — pointer mode is unreachable, removing EXP-0009's P5 mode switch.
- SEQ-A positions share one error class, so P2+ always match P1's rule; SEQ-B
  likewise. Cross-sequence rules never exist in-store (isolation).

**TOM rule preserved verbatim: the worker consumes memory; the worker does
not administer memory.** memory_writes_by_worker must stay 0; the frozen
text classifiers re-check the lean zeros; the three known completion-report
false-positive patterns from EXP-0009 are on record and inspected verbatim
if flags appear.

## Metrics (unchanged) + rule-specific structurals

Per arm: cost, uncached, turns, acceptance, elapsed; memory_reads;
memory_writes_by_worker; rediscovery (outside-task-file reads, searches);
delivered rule bytes + matched classes (recorded in variant.json at install);
delivery presence verified in-stream (hook_response event).

## Analysis and precommitted fork (applied only when both reps exist)

Primary: position-matched leanrules/native ratio per position (cost, uncached,
turns), P1 vs mean(P4,P5). Secondary: absolute curves, rediscovery.

1. **Gap MORE favorable with position + acceptance held + rules delivered in
   the arms that improved** → rule-unit memory compounds → proceed to Phase 2
   proof 2 (reusable skills), carrying this memory design.
2. **Flat** → the unit was not the (only) problem; on self-contained tasks
   memory may have no room to pay. STOP memory proofs on this corpus; next
   experiment must change the task corpus (tasks with genuinely expensive
   discovery), not the memory again.
3. **LESS favorable** → even 1.5KB of targeted rules drags → push-delivery
   architecture rejected for this corpus regardless of unit; same corpus
   consequence as branch 2.
4. **Acceptance/quality loss** → the claim FAILS at this proof regardless of
   economics.
5. **Favorable curve with zero delivered-rule bytes in the improving arms** →
   CONFOUND, reported as such; locate the driver before any claim.

No rescue variants of this experiment. n = 20 new arms ≈ 3.5h serial under
the active executor (adopt/dispatch/recover semantics unchanged).

## What this experiment is not

Not a Lean validation, not a new baseline, not a reopening of EXP-0009, not
proof 2–5. The executor runs it; timers do not exist; the mid-run-change rule
stands: experimental semantics frozen at launch, orthogonal runtime defects
fixable with disclosure + identity proof.
