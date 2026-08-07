// Post-Outcome Disposition v0 — turn a frozen outcome into structured findings.
//
// THE GAP THIS CLOSES. EXP-0004 returned `context compilation harmful` and the
// evidence for three separate corrective actions was sitting in the frozen
// artifacts. Nothing happened until a human read the report and said "action
// it". The substrate could remember the result; it could not act on it. This
// module is the smallest thing that turns evidence into a disposition without
// someone having to notice first.
//
// WHAT IT IS NOT. It does not decide anything irreversible, it holds no
// authority, and it executes nothing. It emits findings with a proposed action
// and a required authority class. `execute` here means "eligible to become a
// bounded packet", never "already done".
//
// HONESTY ABOUT THESE RULES — read before trusting a generated finding.
// These rules were authored by an agent that had already read EXP-0004's
// result. That is the same failure shape as EXP-0004's own analyst-blinding
// break: knowing the answer while writing the detector. Two things bound it,
// and neither eliminates it:
//   1. every rule is a general predicate over the artifact SCHEMA — acceptance
//      counts, per-task deltas, byte fields, admitted-vs-attempted — and none
//      names EXP-0004, a task id, a component, or a number drawn from it;
//   2. the rules run over any experiment exposing the same schema, and a rule
//      that only ever fires on one experiment is marked as unvalidated.
// A rule set validated only against the experiment that inspired it has NOT
// been shown to generalise. Stated here rather than discovered later.

export const CLASSES = ["measurement_defect", "product_defect", "optimization_opportunity", "unsupported_hypothesis"];
export const DISPOSITIONS = ["execute", "queue", "observe", "reject"];
export const SEVERITIES = ["low", "medium", "high"];
export const CONFIDENCES = ["low", "medium", "high"];

// Authority classes, ordered. `bounded_internal_product_change` is the only one
// this module may propose for `execute`; anything wider is queued for a human.
export const AUTHORITY = {
  none: "no change proposed",
  bounded_internal_product_change: "reversible, tested, internal to a named component",
  architectural_change: "crosses component boundaries or changes a contract",
  operator_decision: "requires a judgement this module may not make",
};

const pct = (n) => (typeof n === "number" ? `${n > 0 ? "+" : ""}${n.toFixed(1)}%` : "-");

/**
 * Every rule: { id, when(ev) -> bool, build(ev) -> finding }
 * `ev` is the normalised evidence bundle from `normalise()`.
 */
export const RULES = [
  {
    id: "acceptance-shortfall-with-regression",
    // A condition that produced a rejected unit carrying a regression has a
    // correctness defect, not an economics one. This outranks every token
    // finding: compression that costs acceptance is a loss, not a trade.
    when: (ev) => ev.rejected.length > 0 && ev.rejected.some((r) => r.regressions > 0),
    build: (ev) => {
      const worst = ev.rejected.find((r) => r.regressions > 0);
      return {
        class: "product_defect",
        severity: "high",
        confidence: "high",
        component: `${worst.condition}.correctness`,
        finding:
          `The ${worst.condition} condition produced a REJECTED outcome on ${worst.task_id} carrying ` +
          `${worst.regressions} measured regression(s). The work satisfied its stated objective and still ` +
          `broke behaviour, so the defect is in what the condition FAILED TO PRESERVE, not in what it failed to do.`,
        evidence: [
          `${worst.task_id}: acceptance=rejected, regressions=${worst.regressions}`,
          `acceptance by condition: ${ev.acceptanceLine}`,
        ],
        proposed_change:
          "preserve and surface the behavioural dependencies of values the change touches, so a locally " +
          "correct fix cannot be silently globally wrong",
        authority: "bounded_internal_product_change",
        revalidation: "regression fixture reproducing this failure SHAPE (not a re-run of the frozen task)",
        disposition: "execute",
      };
    },
  },
  {
    id: "starting-context-dominates-and-loses",
    // One condition carries far more starting context AND spends more uncached
    // tokens. The packaging is paying for itself in neither direction.
    when: (ev) => ev.startingRatio !== null && ev.startingRatio >= 5 && ev.heavierLostTokens === true,
    build: (ev) => ({
      class: "optimization_opportunity",
      severity: "high",
      confidence: "high",
      component: `${ev.heavierCondition}.context_packaging`,
      finding:
        `The ${ev.heavierCondition} condition starts with ${ev.startingRatio.toFixed(1)}x the context bytes of ` +
        `its counterpart (median ${ev.startingHeavy} vs ${ev.startingLight} B) and still spends MORE uncached ` +
        `tokens (median ${pct(ev.medianTokenDeltaHeavy)} relative). Front-loaded context is not paying for the ` +
        `exploration it was meant to replace.`,
      evidence: [
        `median starting context: ${ev.startingHeavy} B vs ${ev.startingLight} B`,
        `median uncached delta for the heavier condition: ${pct(ev.medianTokenDeltaHeavy)}`,
      ],
      proposed_change:
        "move bulk that is not load-bearing for the worker out of the starting payload and behind a " +
        "retrievable handle, preserving auditability outside the prompt",
      authority: "bounded_internal_product_change",
      revalidation: "deterministic byte comparison on representative fixtures, before/after",
      disposition: "execute",
    }),
  },
  {
    id: "sign-flip-across-tasks",
    // The per-task effect changes SIGN across the set. A treatment that helps
    // some tasks and harms others is not wrong; it is unrouted. Applying it
    // universally is the unsupported policy.
    when: (ev) => ev.perTask.length >= 3 && ev.signFlips >= 1 && ev.spread >= 50,
    build: (ev) => ({
      class: "unsupported_hypothesis",
      severity: "medium",
      confidence: "medium",
      component: `${ev.treatmentCondition}.routing_policy`,
      finding:
        `The per-task effect changes sign across the set: ${ev.signFlips} flip(s), spread ${ev.spread.toFixed(0)} ` +
        `percentage points (best ${pct(ev.best)}, worst ${pct(ev.worst)}). UNIVERSAL application is therefore ` +
        `unsupported by this evidence. The mechanism is not uniformly wrong; it is unrouted.`,
      evidence: ev.perTask.map((t) => `${t.task_id}: ${pct(t.delta)}`),
      proposed_change:
        "replace universal application with a deterministic pre-task eligibility decision, using signals " +
        "available BEFORE execution, with an explicit fallback",
      authority: "architectural_change",
      revalidation: "deterministic decision fixtures covering the favourable, unfavourable and unmeasurable shapes",
      // Deliberately NOT `execute`: this changes a policy, not a defect, and
      // the evidence supports the question rather than the answer.
      disposition: "queue",
    }),
  },
  {
    id: "fixture-reliability-shortfall",
    // Arms lost to harness faults are a measurement defect, and they are not
    // normalised away by a clean re-run.
    when: (ev) => ev.attempted > 0 && ev.admitted / ev.attempted < 0.9,
    build: (ev) => ({
      class: "measurement_defect",
      severity: "medium",
      confidence: "high",
      component: "experiment_harness.reliability",
      finding:
        `${ev.admitted} admitted measurements from ${ev.attempted} executions ` +
        `(${((ev.admitted / ev.attempted) * 100).toFixed(0)}%). A harness that loses ` +
        `${ev.attempted - ev.admitted} in ${ev.attempted} is not yet safe to run unattended, and the loss rate ` +
        `is a property of the instrument rather than of the thesis.`,
      evidence: ev.voidReasons.length ? ev.voidReasons : [`${ev.attempted - ev.admitted} execution(s) not admitted`],
      proposed_change: "harden the demonstrated runner faults only; no product redesign under harness work",
      authority: "bounded_internal_product_change",
      revalidation: "the same fault classes exercised as fixtures",
      disposition: "execute",
    }),
  },
  {
    id: "no-gate-met-either-direction",
    when: (ev) => ev.gatesMet === 0 && ev.perTask.length > 0,
    build: (ev) => ({
      class: "unsupported_hypothesis",
      severity: "low",
      confidence: "high",
      component: "experiment.hypothesis",
      finding:
        "No registered gate was met in either direction. The measured effect is directional at best, and no " +
        "claim of a decisive advantage is supported by this run.",
      evidence: [`gates met: 0`, `pairs: ${ev.perTask.length}`],
      proposed_change: "none — record the null and do not re-describe a directional result as a decisive one",
      authority: "none",
      revalidation: "not applicable",
      disposition: "observe",
    }),
  },
];

/** Normalise a frozen experiment into the fields the rules read. */
export function normalise(input) {
  const perTask = input.per_task || [];
  const deltas = perTask.map((t) => t.delta).filter((d) => typeof d === "number");
  const pos = deltas.filter((d) => d > 0).length;
  const neg = deltas.filter((d) => d < 0).length;
  return {
    experiment: input.experiment || "UNKNOWN",
    perTask,
    signFlips: pos > 0 && neg > 0 ? Math.min(pos, neg) : 0,
    spread: deltas.length ? Math.max(...deltas) - Math.min(...deltas) : 0,
    best: deltas.length ? Math.max(...deltas) : null,
    worst: deltas.length ? Math.min(...deltas) : null,
    rejected: input.rejected || [],
    acceptanceLine: input.acceptance_line || "-",
    startingHeavy: input.starting_heavy ?? null,
    startingLight: input.starting_light ?? null,
    startingRatio: input.starting_heavy && input.starting_light ? input.starting_heavy / input.starting_light : null,
    heavierCondition: input.heavier_condition || "the heavier condition",
    heavierLostTokens: input.heavier_lost_tokens === true,
    medianTokenDeltaHeavy: input.median_token_delta_heavy ?? null,
    treatmentCondition: input.treatment_condition || "the treatment condition",
    admitted: input.admitted ?? 0,
    attempted: input.attempted ?? 0,
    voidReasons: input.void_reasons || [],
    gatesMet: input.gates_met ?? 0,
  };
}

export function dispose(input) {
  const ev = normalise(input);
  const findings = [];
  for (const rule of RULES) {
    let fires = false;
    try { fires = rule.when(ev) === true; } catch { fires = false; }
    if (!fires) continue;
    const f = rule.build(ev);
    findings.push({ finding_id: `${ev.experiment}-${rule.id}`, rule: rule.id, ...f });
  }
  const order = { high: 0, medium: 1, low: 2 };
  findings.sort((a, b) => order[a.severity] - order[b.severity] || (a.rule < b.rule ? -1 : 1));
  return {
    artifact: "post_outcome_disposition",
    version: 0,
    experiment: ev.experiment,
    rules_evaluated: RULES.length,
    findings_generated: findings.length,
    findings,
    authority_note:
      "`execute` means ELIGIBLE TO BECOME A BOUNDED PACKET, never 'already done'. Nothing here holds authority " +
      "and nothing here is irreversible. Anything above bounded_internal_product_change is queued for a human.",
    generality_note:
      "These rules were authored by an agent that had already read the outcome they were first tested against. " +
      "Every rule is a general predicate over the artifact schema and none names an experiment, task, component " +
      "or constant drawn from it — but a rule set validated only on its inspiring experiment has NOT been shown " +
      "to generalise.",
  };
}
