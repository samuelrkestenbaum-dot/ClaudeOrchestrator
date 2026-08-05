# EXP-0002 — Preregistered protocol: does Gravito reduce cumulative cost on sustained, related work?

**Status: PREREGISTERED. Committed before any experimental run. Not revisable after run 1.**

Operator instruction (2026-08-05): EXP-0001 answered only the trivial-task question
(full Gravito adds ~2× overhead to a tiny isolated edit). It did not test the
sustained-workload hypothesis that would explain the observed sharp drop in weekly
Claude usage. EXP-0002 tests that hypothesis directly, with Claude alone — Codex is
not a prerequisite. Token-efficiency measurement is a first-class workstream running
in parallel with Repository Core recovery, not displaced by it.

## 1. Experimental question

Across a sequence of five related, substantive engineering tasks where repository
state is reused, does Gravito reduce total tokens, time, rework, or supervision per
durable accepted outcome — and where is the crossover point at which its fixed
overhead becomes net leverage, if it exists?

## 2. Workload — disclosed provenance and why it is not an OSS repository

The workload repository is **parcel-billing**: a deterministic, dependency-free,
ordinary Node application (dimensional weight, tiered pricing, invoicing, CLI) with
a real executable test suite, seeded by
`harness/seed-workload-repo.sh` — expected tree digest, pinned here before run 1:
`128485c6082bdf7305168001212b1e2aa7005815be9c00735185eecfdb8cc06f`
(builder-verified deterministic: two seeds, identical digests, `diff -r` empty;
seeded suite exactly `TOTAL: 19 passed, 0 failed`; the latent tier-boundary defect
is live and untested at seed). It is
synthetic-but-ordinary, authored for this experiment, and contains no Gravito code.

Stated plainly rather than papered over: the operator asked for a "boring foreign
repository — not Gravito itself." `empathiq-website` fails the foreignness test (it
IS the Gravito product codebase), and externally-authored OSS cannot be fetched —
this session's GitHub access is scoped to the two Gravito repositories only. A
purpose-built ordinary application is the strongest available mode; its authorship
is a named limitation, mitigated by machine-checkable acceptance (hidden-oracle
style) and a frozen task text no arm can negotiate with.

## 3. The five-task sequence (frozen verbatim in `harness/tasks.md`)

T1 diagnose a latent spec/code disagreement (writes DIAGNOSIS.md, changes no code) →
T2 tested fix (failing test first, differential-checked) → T3 multi-file feature
from SPEC-T3.md (exact worked examples + error cases) → T4 respond to a
deliberately injected failing regression test (`harness/inject-t4.sh`, injected
after T3 closes, identical in both arms) → T5 fresh-session follow-up
(FOLLOWUP-T5.md) whose correct completion depends on decisions made in T2–T4
(rounding policy, discount architecture). Tasks share meaningful repository context
by construction, so memory reuse CAN matter — that is the point.

Each arm runs the sequence on ONE evolving repository (no reseeding between tasks);
every task is a FRESH headless session (`claude -p`); no transcript relay in either
arm. Task prompts are byte-identical across arms.

## 4. Arms

| | Arm A — Gravito OFF | Arm B — Gravito ON |
|---|---|---|
| starting tree | identical seed, digest pinned | identical seed + `install-project.sh --no-session-hook` |
| per task | fresh session, task text only (what a developer would reasonably provide) | fresh session, same task text; the installed surface directs memory/receipt/handoff use |
| continuity | only what survives in code/files | repository-owned memory; later sessions resume from repository state |
| permissions | identical: `--permission-mode acceptEdits --allowedTools "Bash(node:*)"` | identical |

**Capability disclosure (the EXP-0001 invalidator, resolved):** the scoped
allowlist form grants real Bash execution headlessly — executed proof
`BASH_PROBE_OK_42`, zero denials, CLI 2.1.222. Also observed and disclosed: the
scoped pattern is NON-BINDING in this CLI version (`git` executed under
`Bash(node:*)` without denial). Both arms therefore run with identical, broad,
Bash-capable permissions; isolation comes from detached scratch working trees, not
from the allowlist. Substantive tasks can no longer refuse for capability reasons —
the invalidity condition the operator named does not apply.

**Arm order:** A's full sequence first, then B's, both in this session's
environment, same CLI, same default model (verified per run from `modelUsage`).
Order effects (provider cache warmth favoring the later arm) are named confound C2
and separated by reporting cache components per call and computing the uncached
variant of every token metric.

## 5. Telemetry

Provider-native per model call from the stream-json result: `input_tokens`,
`output_tokens`, `cache_read_input_tokens`, `cache_creation_input_tokens`,
`total_cost_usd`, `num_turns`, `modelUsage` keys. Cache categories are never merged
invisibly. Structural two-witness tool counting and permission_denials, per the
EXP-0001/bench discipline. Wall clock and TTFCC (10 s oracle polling, upper bound).
Tree digests before/after each task. Mode-selector output per task (descriptive
only — it routes nothing; hindsight correctness recorded at analysis).

**Weekly-usage meter: unobservable from this environment.** This cloud container
has no access to the account's visible weekly-usage percentage, and the operator's
rule forbids estimating it from tokens. Every record carries
`weekly_usage_meter: unobservable_from_this_environment`, and the second primary
metric below is reported as **unavailable-with-reason**. Operator-side captures
around future re-runs can supply it; nothing here fabricates it.

Not machine-derivable, recorded `-` (an unknown is not a zero):
`human_interventions` (unattended by construction), `rework_rounds` (self-report
excluded), `post-close defects` (nobody keeps looking).

## 6. Metrics and decision rule — fixed before run 1

**Durable accepted outcome** := task oracle (`harness/oracle-exp2.js`, executed,
external) exits 0 AND the sealed record is committed.

Primary:
1. **Provider-reported total tokens per durable accepted outcome**, per arm,
   sequence level (`Σ total_tokens across the arm's runs ÷ accepted outcomes`) —
   `total_tokens = input + output + cache_creation + cache_read`, with the
   uncached variant (`− cache_read`) always beside it.
2. **Weekly usage percentage consumed per durable accepted outcome** —
   **unavailable-with-reason in this environment** (§5); listed to keep the
   operator's metric first-class, not to pretend it was measured.

Cumulative analysis (the deliverable the operator ranked highest): cumulative
total and uncached tokens after T1, T2, T3, T4, T5 in both arms; the **crossover
point** — the first task index where arm B's cumulative total drops below arm A's —
or the finding that no crossover occurs. Per-task paired differences reported for
all five tasks, never only the final aggregate.

Secondary: uncached tokens/outcome, cost, wall clock, TTFCC, model calls, tool
failures, tests run/passed, human minutes (`-` here).

**Decision rule**, evaluated in order:
1. **result confounded** — model_used differs across runs after exclusions; seed
   digest mismatch at either arm's start; accepted outcomes differ between arms by
   ≥2 of 5 (quality, not efficiency, then dominates); or total and uncached
   sequence comparisons point in opposite directions.
2. **sustained-workload savings supported** — arm B's sequence-level total tokens
   per accepted outcome ≥25% below arm A's, AND ≥4 of the 5 per-task paired
   differences agree in direction, AND the uncached comparison agrees.
3. **no sustained-workload savings detected** — sequence-level difference <25% in
   B's favor (including B costing more), with the direction and any crossover
   stated.
4. **promising but underpowered** — ≥25% in B's favor but per-task agreement <4/5.

N is one sequence per arm (5 paired task points): this is a first controlled
measurement of the sustained hypothesis, not its final word — stated here, in
advance. The symmetric possibility (B worse, as in EXP-0001) is reported under
rule 3 with its magnitude; the vocabulary is the operator's four options.

**The revealed report MUST reconcile the result with (a) EXP-0001's demonstrated
~2× trivial-task overhead and (b) the operator's observed historical weekly-usage
drop (which remains prior evidence about an even longer-horizon workload).**

## 7. Blinding and ordering

Identical ceremony to EXP-0001, adjusted for sequences: seal all run records +
manifest, commit; blinded dataset with arms relabeled X/Y (per-task rows, sequence
order preserved within arm), mapping withheld from the tree with sha256
pre-committed; independent evaluator session receives ONLY the blinded dataset and
this §6 rule text in X/Y-neutral form (never §4's arm-order schedule); its analysis
is committed BEFORE the mapping enters the tree; reveal verifies the hash, then
conclusion. Blinding limitation as in EXP-0001: the token signature may be
inferable; the mitigation is that the rule is mechanical.

## 8. Freeze and integrity

No edit to `bench/` or EXP-0001 artifacts (preserved unchanged, now published at
`982054a`). No optimization of Gravito or of this harness once run 1 starts; a
defect discovered mid-run is recorded, the run labeled, machinery untouched.
Failed and refused runs stay in the dataset. Task timeout 3600 s (a timeout is a
failed run, retained). No push without explicit operator go (the EXP-0001 push go
does not extend to future commits).

## 9. Outputs in order

1. this preregistration + the frozen harness (one commit, before run 1);
2. sealed run records + manifest + blinded dataset + mapping hash;
3. blinded analysis (committed before reveal);
4. revealed comparison with cumulative curves and crossover;
5. conclusion — exactly one of: `sustained-workload savings supported` |
   `promising but underpowered` | `no sustained-workload savings detected` |
   `result confounded` — plus the two mandated reconciliations.
