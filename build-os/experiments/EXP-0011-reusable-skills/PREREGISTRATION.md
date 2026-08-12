# EXP-0011 — Reusable learned skills (Phase 2, proof 2, D4). FROZEN.

Frozen with the operator's three calls, dictated with the 2b3bbea push go:

1. **Corpus: subsystem sequences** — materially higher discovery cost without
   a new adjudication regime. Derived mechanically (rule stated before the
   lists were looked at): subsystems = top-level dirs under server/ ranked by
   total baseline error count; top 2; within each, top 5 files by error count
   desc, tie alphabetical. → **SEQ-G** (governance: 288 errors; files with up
   to 10 distinct codes) and **SEQ-M** (mcp: 88 errors). Full lists in
   `sequences.json`.
2. **Skill: the native SKILL.md capability surface** — harness-compiled from
   the sequence's OWN prior arms: verified rules + the mechanically derived
   demonstrated tool sequence (mode across accepted arms). Installed at
   `.claude/skills/repair-<subsystem>/SKILL.md`; NO memory file rides context
   in the skills arm — the capability's description is its only ambient cost.
   This tests whether experience becomes a reusable capability, not a larger
   context blob.
3. **Comparator: three-way, all 60 arms** — native / leanrules (proof-1
   design, fixed selector) / leanskills, 2 seqs x 5 positions x 2 isolated
   reps. The marginal question (skill value beyond rules) is load-bearing.
   Serial under the active executor; no #53 detour unless the environment
   forces it.

**Instrument fixes (hard preconditions, both landed and regression-tested —
`instrument-fixes.test.mjs`, 7 assertions; EXP-0006 harness suite still
31/31):** (a) selector skips an oversized rule instead of blocking those
behind it, skips reported; (b) the adjudicator's `any_cast` pattern no longer
fires on pure-comment lines — tested against the preserved A1.leanrules.r1
diff verbatim, with positive controls proving real casts and comment-dwelling
@ts-* suppressions still reject. EXP-0010's frozen code is untouched.

**Unchanged proven apparatus:** seed 2543c873, transport pin a530659, runnable
grants/timeouts, model, 1200s ceiling, prompt builder (sha-identical across
the three configs by construction), acceptance adjudicator, frozen
classifiers, per-SEQ.rep.config store isolation with provenance gates,
position-matched primary interpretation (cost + uncached), TOM guard (worker
consumes, never administers — worker writes under build-os/memory/ OR
.claude/skills/ count as regression), admissibility rules, active executor
(config order rotated per position), mechanical harness-authored
distillation/compilation.

**Fork (five branches, five distinct actions):** frozen in
`skills.convergence.json` — skills>rules>native → proof 3 with the skill
surface; skills=rules → proof 3 with rules, drop the surface; skills<rules →
keep rules, reject the surface at this scale; acceptance loss → FAILS;
favorable-without-use → confound. Applied only when both reps exist. No
rescue variants. Structural use evidence: Skill invocations + SKILL.md reads
in-stream.
