# Neurocosmology math-to-effect registry (canonical)

Schema per entry (machine-checked by tests/neurocosmology_invariant_tests.sh):
`class` R|A|B|C|D · `zone` 0-11 · `status` exactly one of
theoretical | implemented-unwired | wired-unproven | outcome-proven.
`caller` names the ACTUAL runtime invoker in THIS repository, traced by grep
at audit time — never inferred from a file, class, test, or doc existing.
A wired-* status requires a caller path that exists and references the
implementation. `outcome-proven` names the LEVEL of the proof (event / cell /
task / sequence / experiment / subsystem / program) per the scale rule.

TRACING NOTE (2026-08-12, corrected by the P-5 bounded search): the
"historical coherence-field implementation" does NOT exist in this
repository (confirmed: pickaxe over all local refs, remote branch list —
never in this history). It was LOCATED read-only in the SIBLING repository
samuelrkestenbaum-dot/empathiq-website at
`server/emotional-geometry-runtime/` (attention_curvature /
correction_mass / entropy_gradient in field/UnifiedFieldSnapshot.ts;
introduced there by commit 08a76c6, behind a default-OFF feature flag per
its own commit message; statically routed in that server's routes; live
invocation NOT verified — that would require running their server, outside
this bounded search). The prior program-memory claim that it carried
"explicit confidence and falsification boundaries" is NOT confirmed for
that file (0 matches). DISPOSITION: not copied, not wired, no authority
granted; in THIS repository the curvature/mass/attractor/entropy entries
remain `theoretical`, and that code is another codebase's Class-C
challenger material at best.

## Ontology N = (R, M, nu, g, A, En, H0, D, B, Et, I, Q, S_latent)
- equation: N = (R, M, nu, g, A, En, H0, D, B, Et, I, Q, S_latent)
- class: R
- zone: 0
- implementation: none (this registry + owner suite text)
- caller: none
- inputs: n/a
- decision: none — organizing ontology only
- receipt: none
- baseline: n/a
- falsifier: a system property demonstrably not expressible via these primitives without loss
- outcome-test: none permitted — research authority only
- status: theoretical

## Minimal model Transformation = f(R, M, g, A, D)
- equation: Transformation = f(R, M, g, A, D)
- class: R
- zone: 0
- implementation: none
- caller: none
- inputs: n/a
- decision: none
- receipt: none
- baseline: n/a
- falsifier: transformation observed with one factor absent and unexplained
- outcome-test: none — research
- status: theoretical

## Research geometry G = (M, g, S, A, rho, Phi)
- equation: G = (M, g, S, A, rho, Phi); G_mind ~ G_cosmos (structural analogy)
- class: R
- zone: 0
- implementation: none
- caller: none
- inputs: n/a
- decision: none
- receipt: none
- baseline: n/a
- falsifier: analogy predictions underperform a non-geometric account
- outcome-test: none — research
- status: theoretical

## Salience curvature field equation
- equation: G_munu^mind = kappa_m T_munu^salience
- class: R
- zone: 0
- implementation: none
- caller: none
- inputs: n/a
- decision: none
- receipt: none
- baseline: n/a
- falsifier: attention allocation unexplained by salience distribution
- outcome-test: none — research
- status: theoretical

## Emotional mass M_e = I * nu * R * P
- equation: M_e(x,t) = I(x,t) nu(x,t) R(x,t) P(x,t)
- class: R
- zone: 0
- implementation: none
- caller: none
- inputs: n/a (human-domain)
- decision: none
- receipt: none
- baseline: n/a
- falsifier: recurrence without predictive importance carrying equal mass
- outcome-test: none — research
- status: theoretical

## Operational salience mass M_o = R * C * H * U
- equation: M_o(i,t) = R_i(t) C_i(t) H_i(t) U_i(t)
- class: C
- zone: 9
- implementation: none in this repository (coherence-field version is Mac-local Core, #40)
- caller: none
- inputs: recurrence count, correction cost, hazard, unresolvedness (all B-metrics once defined)
- decision: which recurring failures deserve program attention (shape strategy only, never authorize)
- receipt: proposed program-health field, not yet defined
- baseline: raw recurrence count ranking
- falsifier: M_o ranking no better than recurrence-count ranking at predicting next correction
- outcome-test: prospective — does attending to top-M_o items reduce future corrections vs baseline (program level)
- status: theoretical

## Attention field and curvature R_a = div(a) + lambda |grad a|^2
- equation: R_a = div(a) + lambda ||grad a||^2
- class: R
- zone: 0
- implementation: none in this repository
- caller: none
- inputs: n/a
- decision: none
- receipt: none
- baseline: n/a
- falsifier: fixation detected equally well by simple repetition counts
- outcome-test: none — challenger material
- status: theoretical

## Attention funding law M(t+1) = M(t) + alpha*a*I - lambda*R
- equation: M_i(t+1) = M_i(t) + alpha a_i(t) I_i(t) - lambda R_i(t)
- class: C
- zone: 9
- implementation: none in this repository
- caller: none
- inputs: tokens/turns/tool-calls/interventions/wall-time per theme (B-observable)
- decision: fixation / meta-work detection at program level
- receipt: proposed
- baseline: theme-attention share vs verified-outcome share (simple ratio)
- falsifier: funded mass fails to predict continued attention better than last-week share
- outcome-test: prospective program-level
- status: theoretical

## Entropy S_m and weighted S_m*
- equation: S_m = -sum p_i log p_i ; S_m* = -sum p_i log p_i M_e_i
- class: C
- zone: 9
- implementation: none in this repository (entropy-gradient version Mac-local, #40)
- caller: none
- inputs: stale rules, contradictory claims, orphaned state, unclosed loops (countable)
- decision: is accumulated state harder to use than it is worth (memory maintenance trigger)
- receipt: proposed
- baseline: raw stale-item count (rotation ceiling already exists: memory rotation, #32)
- falsifier: entropy score no better than file-age/count at predicting context drag
- outcome-test: prospective; EXP-0009 context-drag is supporting evidence for the phenomenon, not for this formula
- status: theoretical

## Inner action functional S_mind
- equation: S_mind = integral [ 1/2||xdot||^2 + alpha M_e + beta S_m - gamma C ] dt
- class: R
- zone: 0
- implementation: none
- caller: none
- inputs: n/a
- decision: none — retrospective explanatory lens
- receipt: none
- baseline: n/a
- falsifier: cheaper-path persistence unexplained by action minimization
- outcome-test: none — research
- status: theoretical

## Work action functional S_work
- equation: S_work = integral [ C_cog + C_coord + C_verify + C_rework + H_risk - V_outcome ] dt
- class: R
- zone: 0
- implementation: none
- caller: none
- inputs: would be cost/time ledgers (B) if ever computed
- decision: none at runtime — retrospective program analysis only
- receipt: none
- baseline: total cost per outcome
- falsifier: expensive-path persistence explained by simple missing-information account
- outcome-test: retrospective case studies only (EXP-0006/0007 candidates)
- status: theoretical

## Geodesics / learned transition tendencies
- equation: xddot^mu + Gamma^mu_ab xdot^a xdot^b = 0
- class: D
- zone: 0
- implementation: none — explicitly deferred; collect transitions first, Markov baseline before geometry
- caller: none
- inputs: event-state transition logs (exist in sealed experiment streams)
- decision: none until Class-D criteria met
- receipt: none
- baseline: first-order Markov transition frequencies
- falsifier: geometric model fails to beat Markov baseline on held-out trajectories
- outcome-test: held-out trajectory prediction (Zone-10 gate)
- status: theoretical

## Attractor basins / cognitive singularities
- equation: lim x->x_s R_A(x) -> inf (heuristic)
- class: C
- zone: 9
- implementation: none in this repository
- caller: none
- inputs: recurrent state categories (countable from packet/task history)
- decision: strategy-level basin warnings only — never worker paperwork, never authorization
- receipt: proposed
- baseline: recurrence count per category
- falsifier: basin score no better than recurrence count at predicting return-to-state
- outcome-test: prospective program-level
- status: theoretical

## Latent density / latent-state inference
- equation: rho_s = I^-1(dA, dB, dE)
- class: D
- zone: 0
- implementation: none
- caller: none
- inputs: symptom streams (concessions, routing anomalies, latency, interventions)
- decision: none until Class-D criteria met
- receipt: none
- baseline: direct symptom counting
- falsifier: inferred latent state adds no predictive power over symptom counts
- outcome-test: Zone-10 prospective
- status: theoretical

## Reachability expansion rate H_R
- equation: H_R = d|R_viable| / dt
- class: B
- zone: 9
- implementation: none yet (|R_viable| not computed as a set in product; see Reachability entry)
- caller: none
- inputs: count of authorized+executable+evidence-producing next actions
- decision: program trend surfacing (losing vs gaining viable agency)
- receipt: proposed operator-surface field
- baseline: n/a (is itself the deterministic form)
- falsifier: n/a (deterministic metric; misuse falsifier: treating it as a target)
- outcome-test: n/a — B metric
- status: theoretical

## Homeostasis H0 (human form)
- equation: H0(t) = f(sleep, pain, hormones, immune, autonomic, nutrition, safety, sensory)
- class: R
- zone: 0
- implementation: none
- caller: none
- inputs: n/a
- decision: none
- receipt: none
- baseline: n/a
- falsifier: agency loss fully explained by meaning-side variables with substrate held degraded
- outcome-test: none — research
- status: theoretical

## System homeostasis H0_system
- equation: H0_system = runtime and substrate health; H0 down => A_safe down
- class: A
- zone: 2
- implementation: build-os/tools/h0-check.sh — ONE canonical surface (full mode: typed facts + agency full/narrowed/blocked; --gate mode: Class-A facts only for per-mutation boundaries). preflight/diagnose keep their distinct verbs (install-eligibility / support bundle)
- caller: bin/gravito cmd_run (full, exactly once per dispatch attempt, first step, traced) + cmd_health; .claude/hooks/routing-gate.sh goal_gate_or_block (--gate, once per mutation, BEFORE authority). Entry-point inventory: cmd_run, tool-gate (direct/nested/resumed sessions), bare human shell = explicit unsupported boundary
- inputs: git validity, secret files, engine file presence, matcher wiring, ledger, locks (all B-observable)
- decision: preflight refuses init; diagnose reports; NO unified pre-work gate exists yet
- receipt: build-os/receipts/h0-latest.json; refusals.log (tool boundary); run-trace.jsonl step h0
- baseline: n/a (Boolean conditions)
- falsifier: n/a (Class A; each condition individually testable)
- outcome-test: E2E disposable-repo proof at BOTH entry points: corrupt ledger blocks run and Edit before side effects; stale pid narrows without blocking (tests/control_primitives_tests.sh, task level). No real-outcome test yet
- status: wired-unproven

## Agency composition A(t) = f(R, En, H0, I, Q)
- equation: A(t) = f(R, E_n, H0, I, Q)
- class: R
- zone: 0
- implementation: none as a computed quantity
- caller: none
- inputs: n/a
- decision: none — the direction (substrate bounds agency) is Class A via H0_system entry
- receipt: none
- baseline: n/a
- falsifier: agency variance unexplained by the five factors
- outcome-test: none — research
- status: theoretical

## Reachability: run/dispatch admission (R_t, R_t+ at the dispatch boundary)
- equation: R_t = {a executable, authorized, feasible}; R_t+ = admissible subset; dispatch only if action in R_t+
- class: A
- zone: 3
- implementation: build-os/tools/reachability.mjs (constructReachability — per-action reasons; the authority gate goal-check --gate invoked ONCE inside the construction, so admission and authority are one evaluation); sealed executor.mjs predicate (experiments)
- caller: bin/gravito cmd_run — R_t+ membership is the REAL dispatch admission (refuse before side effects if run outside R_t+); bin/gravito cmd_health (operator surface); sealed executor.mjs (38 cells)
- inputs: goal window/budget via the gate, worker pid, provider CLI, manifests, goal presence
- decision: dispatch or refuse, before any side effect
- receipt: run-trace.jsonl (run_id, ordered steps); refusals via die; run-record admissibility (sealed)
- baseline: n/a (Class A)
- falsifier: n/a
- outcome-test: gates behind it: real budget halt + real publish block (experiment/program level). The admission construction itself: E2E real-entry-point proof incl. lapsed-goal refusal outside R_t+ (task level); no measured beneficial outcome yet
- status: wired-unproven

## Reachability: general planning/scoring selection (selectAction over R_t+)
- equation: a* = argmax over R_t+ of V(a) — selection strictly inside the admitted set
- class: A
- zone: 4
- implementation: build-os/tools/reachability.mjs selectAction() — argmax strictly over R_t+, outside scores ignored by construction (score-resurrection proof executed)
- caller: none in any production path — tests only. NO planner/scoring layer exists to consume R_t+. This is an EXPLICIT ARCHITECTURAL DEPENDENCY, not a wiring gap to patch: a future planner must (1) receive ONLY R_t+ (never the raw action universe), (2) treat authority as a constraint never a score term, (3) emit a selection receipt naming candidates, scores, and the admitted set, (4) be built as its own authorized packet
- inputs: R_t+ and a scores map (no production scorer exists)
- decision: none today — a superficial caller must NOT be created to improve this status
- receipt: none (selection receipts are part of the future contract above)
- baseline: n/a (Class A constraint on any future scorer)
- falsifier: n/a
- outcome-test: none possible without the planner
- status: implemented-unwired

## Ethics/authority as constraint, never penalty
- equation: a* = argmax_{a in R_t, E(a)=1} V(a) — optimize only inside admissible space
- class: A
- zone: 3
- implementation: .claude/hooks/routing-gate.sh (block, not score-penalty); build-os/tools/publish-check.mjs + build-os/learning/publication-authority.mjs; build-os/tools/goal-check.sh --gate
- caller: .claude/settings.json (PreToolUse matchers invoking routing-gate.sh); pre-push path invoking build-os/tools/publish-check.mjs; bin/gravito cmd_run
- inputs: authorization records, goal contract, ledger, tool identity
- decision: block/allow — no score input exists in any of these paths
- receipt: refusals.log; publish-check stdout; authorization record
- baseline: n/a
- falsifier: n/a
- outcome-test: real events this program: push REFUSED absent schema-valid operator record, then proceeded under one; goal gate blocked Edit/Write/Bash/MCP before side effects (enforcement suite, task level; live golden-path, experiment level)
- status: outcome-proven

## Base and master movement dynamics
- equation: xdot = H0 [ -grad_g U + A u + Phi_seq sum_k O_k chi ] - D_self - C_maladaptive + eps
- class: R
- zone: 0
- implementation: none — master research equation by declaration
- caller: none
- inputs: n/a
- decision: none — must never be evaluated per action
- receipt: none
- baseline: n/a
- falsifier: any term shown redundant across domains
- outcome-test: none — research
- status: theoretical

## Transformation operator families O_rel/O_sym/O_body/O_ritual/O_env, D_self, C_maladaptive
- equation: operator families entering the master dynamics
- class: R
- zone: 0
- implementation: none
- caller: none
- inputs: n/a
- decision: none
- receipt: none
- baseline: n/a
- falsifier: an operator with no effect on any primitive
- outcome-test: none — research
- status: theoretical

## Dose threshold
- equation: Transformation iff sum w_i O_i(t) > Theta_dose
- class: C
- zone: 5
- implementation: build-os/delivery/ucdl.mjs POLICIES theta_sufficiency (DECLARED, uncalibrated, receipted, non-blocking by design — an uncalibrated C threshold must not hold hard authority)
- caller: tests/context_delivery_tests.sh only (UCDL has no runtime caller yet)
- inputs: delivered bytes vs declared theta
- decision: none today (reported); after Zone-10 calibration may warn/gate
- receipt: receipt.dose_window.theta_sufficiency / .within
- baseline: theta=0 (no lower bound) — the current default IS the baseline
- falsifier: calibrated theta fails to predict under-informed worker behavior better than theta=0
- outcome-test: EXP-0011 starvation (0-byte deliveries, cells behaved ~native) is experiment-level evidence that BELOW-dose delivery loses the treatment; the specific threshold value remains uncalibrated
- status: implemented-unwired

## Integration bandwidth window and chi gate
- equation: Theta < C_delivered < B_integration; chi in {0,1,-1}
- class: B
- zone: 5
- implementation: build-os/delivery/ucdl.mjs applyBudget (cap enforcement, truncation recorded) + receipt.dose_window
- caller: tests/context_delivery_tests.sh only (unwired)
- inputs: unit/atom byte sizes, declared cap
- decision: what is delivered vs truncated (upper bound is enforced deterministically)
- receipt: receipt.dose_window; receipt.truncated; per-candidate reasons
- baseline: n/a (deterministic byte arithmetic)
- falsifier: n/a for the mechanism; for the CONCEPT: over-delivery shown harmless would falsify the upper bound's value
- outcome-test: EXP-0009 (report-memory context drag, experiment level) evidences the over-delivery harm; UCDL implementation itself unproven on live workers
- status: implemented-unwired

## Sequence operator Phi_seq (canonical runtime sequence)
- equation: state -> H0 -> reachability -> authority -> planning -> cognition -> execution -> evidence -> learning
- class: A
- zone: 6
- implementation: enforced and TRACED: bin/gravito cmd_run emits run-trace.jsonl (run_id, seq, steps h0->reachability->authority->admission->dispatch|refuse); routing-gate.sh goal_gate_or_block (H0 Class-A before authority per mutation); sealed executor.mjs; order pinned by tests/neurocosmology_invariant_tests.sh
- caller: PreToolUse hooks; bin/gravito; sealed executor
- inputs: code structure itself (order of operations)
- decision: an out-of-order path is a defect. HONEST SCOPE: the WIRED PREFIX is state -> H0 -> reachability -> authority -> admission/dispatch (one traced run_id). Review/prediction receipts are SEPARATELY wired at cmd_review/cmd_predict. NOT yet one production state machine: planning (absent), cognition compiler (UCDL implemented-unwired), execution orchestration, verification->learning as a single loop. A shared run ID does not create a unified state machine
- receipt: build-os/receipts/run-trace.jsonl (correlation id per dispatch attempt); refusals.log
- baseline: n/a
- falsifier: n/a (Class A ordering)
- outcome-test: E2E ordered-trace proof with stable run_id and exactly-once h0 (task level)
- status: wired-unproven

## Generative constraint (bounded autonomy)
- equation: R_meaningful != R_infinite
- class: A
- zone: 3
- implementation: lanes/round budgets (CLAUDE.md + routing-gate.sh counters), goal budgets (goal-check.sh), commit budgets, publish gate, allowlists
- caller: routing-gate hooks; goal gate; publish-check
- inputs: declared budgets, counters, caps
- decision: stop at budget boundaries
- receipt: routing ledger rows; refusals.log; goal HALT messages
- baseline: n/a
- falsifier: n/a (the constraint doctrine's falsifier lives in whole-system validation: unbounded baseline outperforming bounded)
- outcome-test: lane budgets held on real work (#5 recorded, task level); real budget halt on real spend (experiment level)
- status: outcome-proven

## Prediction error delta = y - yhat as first-class receipt
- equation: delta_t = y_t - yhat_t with recorded prediction, observation, mismatch, alternative, permitted consequence
- class: B
- zone: 7
- implementation: build-os/tools/delta-receipt.sh — predictions.jsonl (optional pre-action forecasts: id, outcome_var, value, made_at, scale, provenance) + deltas.jsonl (observations, hash-chained). delta computed ONLY for a matched, pre-dated, commensurable prediction; else NOT_RECORDED / POST_HOC / INCOMPARABLE with delta=UNDEFINED. A success criterion is never yhat — predictions are never manufactured from the goal
- caller: bin/gravito cmd_review (observe, one receipt per invocation) + cmd_predict (forecast surface)
- inputs: predicted outcome (absent today), observed acceptance/verification
- decision: would route learning consequences (confidence, selection weights)
- receipt: build-os/receipts/predictions.jsonl + deltas.jsonl (both append-only, hash-chained, tamper/torn detection)
- baseline: no-prediction (current state)
- falsifier: n/a (B metric once predictions are recorded)
- outcome-test: E2E: absent/post-hoc/incomparable/unexplained-mismatch negative cases all enforced; crash + concurrency proven (task level). No real-outcome calibration yet
- status: wired-unproven

## Narrative compression H -> K (distillation)
- equation: N = C(M_1..M_n); H --distill--> K
- class: B
- zone: 8
- implementation: build-os/experiments/EXP-0011-reusable-skills/skill-lib.mjs distillRule (SEALED); build-os/delivery/ucdl.mjs parseRuleStore insight/exhibit atomization (unwired)
- caller: build-os/experiments/EXP-0011-reusable-skills/run-arm.mjs (sealed; 38 real cells); tests for UCDL
- inputs: run streams, diffs, acceptance
- decision: what enters durable memory
- receipt: rule provenance lines; UCDL receipts (unwired)
- baseline: raw report storage (EXP-0009's arm — the measured baseline)
- falsifier: compact rules failing to beat prose reports
- outcome-test: OUTCOME-PROVEN at experiment level: EXP-0010 (rules compound, cost 0.97->0.87) vs EXP-0009 (prose drags) — the compression PRINCIPLE; the UCDL atomization refinement is unproven
- status: outcome-proven

## Parsimony / compression loss
- equation: min complexity s.t. L_compression < theta_L
- class: C
- zone: 8
- implementation: cap discipline in distill/select paths; no explicit L_compression computation
- caller: sealed skill-lib; UCDL (unwired)
- inputs: unit sizes vs evidence retained
- decision: how small memory representations are
- receipt: bytes fields
- baseline: EXP-0010's 1536B rule format (proven format)
- falsifier: smaller representation losing the causal lesson (EXP-0011 insight-stripping is the open question)
- outcome-test: Stage A/B of EXP-0013 measures whether insight-only atoms retain value (pending)
- status: implemented-unwired

## Ritual / repeated reachability
- equation: M_future(t+1) = M_future(t) + rho R_practice
- class: R
- zone: 0
- implementation: none as math; the DISCIPLINE (repetition before trust) lives in experiment reps and durability doctrine
- caller: none
- inputs: n/a
- decision: none
- receipt: none
- baseline: n/a
- falsifier: single-shot success proving durable without repetition
- outcome-test: none — research
- status: theoretical

## Environment as causal substrate U_total
- equation: U_total = U_inner + U_place + U_social + U_digital
- class: B
- zone: 1
- implementation: factual substrate captures: .claude/hooks/project-identity.sh (namespace), bin/gravito status/diagnose (repo, branch, wiring, ledger), sealed run-arm administered-tree hashing
- caller: .claude/hooks/session-start-build-os.sh (sources project-identity.sh); bin/gravito; sealed harness
- inputs: git state, hashes, file presence — deterministic only
- decision: none directly; feeds gates
- receipt: status/diagnose output; administered_sha
- baseline: n/a
- falsifier: n/a (B facts)
- outcome-test: EXP-0005 and container-restart history evidence environment causality (program level, recorded)
- status: wired-unproven

## Sleep / offline consolidation
- equation: O_sleep: (M,g,nu) -> (M',g',nu')
- class: C
- zone: 8
- implementation: post-run consolidation exists piecewise: distillation after arms (sealed), memory rotation (build-os/maintenance/rotate-memory.sh, #32 ran once), residue sweep post-run (bin/gravito cmd_run)
- caller: sealed harness; maintenance scripts; cmd_run
- inputs: completed-run artifacts
- decision: what is consolidated/pruned; workers never do this (TOM constraint held by harness design)
- receipt: rotation receipts; residue.log
- baseline: no consolidation
- falsifier: consolidation cost exceeding retrieval benefit
- outcome-test: rotation ran once (#34: not yet repeatable capability) — task level only
- status: wired-unproven

## Witnessing / evidence receipts
- equation: O_witness: private state -> shared organizational reality
- class: A
- zone: 7
- implementation: receipts everywhere: .claude/hooks/routing-gate.sh (refusals.log), build-os/tools/meter-run.sh (ledger), bin/gravito (manifests, diagnose bundles), sealed run-records/acceptance/termination manifest
- caller: .claude/settings.json (hooks invoking routing-gate.sh); bin/gravito (invoking meter-run.sh); sealed harness
- inputs: events as they occur
- decision: what counts as having happened
- receipt: the receipts ARE the mechanism
- baseline: n/a
- falsifier: n/a
- outcome-test: receipts actually consumed for decisions this program (publish audit, postmortem replay — program level)
- status: outcome-proven

## Boundaries / selective permeability
- equation: B_boundary = selective permeability of dOmega_self
- class: A
- zone: 3
- implementation: write scopes, mutgate/mcpgate matchers + allowlist (.claude/hooks/mcp-readonly-allowlist.txt), namespace quarantine (project-identity.sh), network/publish gates
- caller: PreToolUse hooks; session-start; publish-check
- inputs: tool identity, paths, namespace stamps, authorization records
- decision: block/allow at each boundary
- receipt: refusals.log; quarantine verdicts
- baseline: n/a
- falsifier: n/a
- outcome-test: isolation 14/14 with sentinel leakage tests; MCP default-closed suite; live quarantine verdicts (task level)
- status: outcome-proven

## Liminality / void (do not revive the old basin)
- equation: M_old down, M_future flat => psi ~ 0
- class: R
- zone: 0
- implementation: none as math; the D3/D4 fork DISCIPLINE (no reopening/rescue variants) enforced procedurally in preregistrations
- caller: none (process rule)
- inputs: n/a
- decision: none mechanical
- receipt: fork records in preregistrations
- baseline: n/a
- falsifier: n/a
- outcome-test: none — research
- status: theoretical

## Resilience R_s and antifragility
- equation: R_s = recovery/perturbation; dC_coherence/dS_shock > 0
- class: B
- zone: 9
- implementation: not computed; the EVENTS exist in records (5+ container restarts recovered; infra-error retries preserved)
- caller: none
- inputs: perturbation and recovery logs
- decision: none yet
- receipt: proposed
- baseline: recovery yes/no counting
- falsifier: n/a (B once defined)
- outcome-test: recovery repeatedly demonstrated (program level, recorded); the METRIC is unbuilt
- status: theoretical

## Scale translation T_l (evidence cannot jump levels)
- equation: T_l: x_l -> x_{l+1}, x_l != x_{l+1}
- class: A
- zone: 7
- implementation: build-os/tools/claim-evidence.sh scope requirement (unscoped claims REFUSED); exploratory-only sealing of EXP-0011; registry statuses here carry proof level
- caller: build-os/tools/evidence-policy.sh (references claim-evidence); build-os/tools/mismatch-disposition.sh; process
- inputs: claim scope fields
- decision: refuse unscoped claims
- receipt: claim store entries
- baseline: n/a
- falsifier: n/a
- outcome-test: claim_evidence tests (task level); EXP-0011 38-cell exploratory discipline held under termination pressure (program level)
- status: wired-unproven

## Awe / scale expansion
- equation: x_self subset M_larger; M_ego down; |R_meaning| up
- class: R
- zone: 0
- implementation: none — explicitly do not operationalize
- caller: none
- inputs: n/a
- decision: none
- receipt: none
- baseline: n/a
- falsifier: n/a
- outcome-test: none — research
- status: theoretical

## Desire / goal gradient
- equation: A_goal = drive toward positive-value state (renamed from D_eros)
- class: C
- zone: 4
- implementation: none (value ranking V(a) not implemented in product planning)
- caller: none
- inputs: expected value estimates (absent)
- decision: none yet
- receipt: none
- baseline: FIFO/owner-ordered work queue
- falsifier: value-ranked ordering no better than owner ordering
- outcome-test: Zone-10 prospective
- status: theoretical

## Maintenance M_maintain
- equation: dPhi/dt includes +M_maintain; ordinary-Tuesday reality test
- class: B
- zone: 9
- implementation: maintenance layer: build-os/maintenance/rotate-memory.sh, build-os/maintenance/run-tests.sh, build-os/tools/residue-sweep.sh
- caller: build-os/maintenance/install-maintenance.sh (ships rotate-memory.sh); bin/gravito cmd_run (invokes residue-sweep.sh)
- inputs: memory sizes, test states
- decision: rotation/pruning when ceilings hit
- receipt: rotation receipts; residue.log
- baseline: no maintenance
- falsifier: maintenance churn without material change (the suppression requirement)
- outcome-test: one governed rotation executed (#32, task level); repeatability open (#34)
- status: wired-unproven

## Trust as earned control-tax reduction
- equation: T_trust = P(expected action | history); T up => C_control down, invariants intact
- class: D
- zone: 10
- implementation: none — explicitly deferred until labeled outcomes and deterministic baseline exist
- caller: none
- inputs: verified-run history (exists in receipts, unlabeled for this purpose)
- decision: none permitted yet
- receipt: none
- baseline: fixed control policy (current state)
- falsifier: trust-adjusted control increasing regressions vs fixed control
- outcome-test: Zone-10 prospective with invariants held constant
- status: theoretical

## Durability D_s and durable reachability
- equation: D_s = persistence under perturbation / initial intensity; P(x in Omega_future | stress, boredom, routine, time) > theta
- class: B
- zone: 9
- implementation: not computed; the arrival-vs-durability DISTINCTION is enforced in doctrine (readiness ladder in USABILITY docs; four-state Codex readiness #33)
- caller: none mechanical
- inputs: repeated-run outcomes across sessions/perturbations
- decision: none yet
- receipt: proposed
- baseline: pass-count across reps
- falsifier: n/a (B once defined)
- outcome-test: unbuilt
- status: theoretical

## Hardened transformation condition (conjunction)
- equation: durable reachability AND dose window AND correct sequence
- class: R
- zone: 0
- implementation: none as a conjunction; components tracked separately above
- caller: none
- inputs: n/a
- decision: none
- receipt: none
- baseline: n/a
- falsifier: transformation observed with a conjunct absent
- outcome-test: none — research
- status: theoretical

## Reachable-future potential Phi and dPhi/dt
- equation: Phi = integral_R g q e dx; dPhi/dt = ACPTP_g + M_maintain + L_learn - D_drift
- class: R
- zone: 0
- implementation: none — north-star lens only; NEVER a reinforcement target (Goodhart)
- caller: none
- inputs: n/a
- decision: none
- receipt: none
- baseline: n/a
- falsifier: drift term shown unnecessary in long-run accounting
- outcome-test: none — research
- status: theoretical

## Readiness Q_ready
- equation: Q_ready = 1 iff dose window AND R_future>0 AND A>theta_A AND D_self<theta_D AND resources AND safety
- class: C
- zone: 2
- implementation: none as a computed conjunction; nearest: preflight + diagnose checks (see H0_system)
- caller: none
- inputs: substrate checks (B)
- decision: none beyond existing preflight refusals; must never block unrelated safe work
- receipt: preflight/diagnose output
- baseline: preflight Boolean list (current)
- falsifier: composite readiness no better than the Boolean list at predicting failed runs
- outcome-test: Zone-10 prospective
- status: theoretical

## Verified progress P_verified
- equation: P_verified = delta observable progress / interpretive activity
- class: B
- zone: 9
- implementation: build-os/tools/convergence-counters.mjs (explicit denominators, UNDEFINED on zero, declared proxies)
- caller: bin/gravito cmd_review (report block only — never a gate input, invariant-tested)
- inputs: verified state changes vs interpretive tokens (both countable from ledgers/streams)
- decision: program-health surfacing; convergence input
- receipt: review output block; diagnose coverage row
- baseline: n/a (B once defined)
- falsifier: n/a; misuse falsifier: becoming a target
- outcome-test: negative case executed: doc-only activity reads P_verified=0 / R_meta UNDEFINED naming zero verified change (task level)
- status: wired-unproven

## Rumination ratio R_rumination / R_meta
- equation: R_rumination = semantic repetition / delta verified action-or-insight
- class: B
- zone: 9
- implementation: build-os/tools/convergence-counters.mjs R_meta (declared proxy: interpretive/verified commits) — plus the unrelated wired relative concession-gate.sh (#55)
- caller: bin/gravito cmd_review (report block); concession-gate via Stop hook (that relative only)
- inputs: repetition detection vs verified-change ledger
- decision: convergence warnings
- receipt: proposed
- baseline: repeated-topic count
- falsifier: n/a (B once defined)
- outcome-test: unbuilt
- status: wired-unproven

## False-positive load F_positive
- equation: F_positive = sum 1[claimed progress AND NOT observed progress]
- class: B
- zone: 9
- implementation: build-os/tools/convergence-counters.mjs F_positive (claimed-success predictions that missed, from deltas.jsonl)
- caller: bin/gravito cmd_review (report block)
- inputs: claims vs proxies
- decision: program-health surfacing
- receipt: proposed
- baseline: n/a
- falsifier: n/a
- outcome-test: unbuilt
- status: wired-unproven

## True success S_true
- equation: S_true = arrival + durability + integrity + boundary-safety
- class: B
- zone: 9
- implementation: components exist separately (acceptance; evidence integrity via seals; boundary safety via gates); no composite
- caller: none for the composite
- inputs: the four components
- decision: how capability claims are graded
- receipt: proposed
- baseline: arrival-only grading (current de facto)
- falsifier: n/a
- outcome-test: unbuilt as composite
- status: theoretical

## Epistemic immune system I_epistemic
- equation: I = F + P + B + R + E + M + N + P_practice
- class: A
- zone: 0
- implementation: partially INSTITUTIONALIZED: build-os/registry/neurocosmology_math_registry.md schema (mandatory falsifier/baseline for C/D) + preregistration/fork discipline; enforced by tests/neurocosmology_invariant_tests.sh
- caller: tests/neurocosmology_invariant_tests.sh (parses neurocosmology_math_registry.md); process
- inputs: every C/D proposal
- decision: whether math may gain authority
- receipt: this registry; preregistration documents
- baseline: n/a
- falsifier: n/a (it is the falsifier-requirer)
- outcome-test: enforcement is the invariant suite passing (task level)
- status: wired-unproven
