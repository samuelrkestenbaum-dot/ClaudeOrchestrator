// THE OBJECTIVE / MARGINAL-VALUE GATE.
//
// THE DEFECT IT FIXES: `persistence_without_prioritisation`. The continuation
// controller answers "should I stop?" and answers it well — it refuses to halt
// while runnable work remains. It never asks "should this task still be
// prioritised?", so the substrate reasons:
//
//     known debt exists -> the debt is real -> the task is runnable -> continue
//
// and every improvement exposes a legitimate imperfection, which becomes a
// task, which becomes an audit, which exposes another imperfection. The stop
// defect was fixed and replaced with its mirror image: productive-looking
// fixation. It learned persistence before judgment.
//
// THE EVIDENCE THIS IS REAL, not theoretical: an anchor migration consumed
// four packets, produced a regression, was reverted, was re-scoped, and moved
// the primary objective forward by nothing. Every individual step was correct.
// No rule anywhere said "this does not block the objective — defer it."
//
// WHAT MAKES IT LOAD-BEARING RATHER THAN ADVISORY: continuation selects the
// highest-value runnable task rather than the next runnable one, so a DEFERRED
// task is not selected even though it is runnable, unexhausted and real.
//
// THE OBJECTIVE IS DECLARED, NEVER DERIVED. A worker that infers its own
// objective can rationalise any task into it — which is precisely the failure
// being corrected. It is set by the operator and read here.

export const PRIMARY_OBJECTIVE = {
  id: "core-operational-proof",
  statement:
    "Demonstrate that Gravito reliably improves real AI work across persistent, governed, multi-surface execution.",
  declared_by: "operator",
  // Gravito leaves infrastructure mode when ALL of these hold. Anything not
  // serving one of them is backlog unless it demonstrably blocks one.
  exit_criteria: [
    { id: "EXIT-1", claim: "Claude<->ChatGPT top-rung behavioural continuity is PROVEN (actor-disambiguated, not consumption-only)", status: "OPEN" },
    { id: "EXIT-2", claim: "live self-gating is actually enforced/covered — the Operator Lab reports self_gate_hygiene covered for Claude and ChatGPT", status: "OPEN" },
    { id: "EXIT-3", claim: "no known runtime-critical defect blocks normal execution", status: "OPEN" },
    { id: "EXIT-4", claim: "fresh end-to-end work runs successfully", status: "OPEN" },
    { id: "EXIT-5", claim: "a fresh UIC comparison is completed", status: "OPEN" },
  ],
  non_criteria: [
    "perfected evidence citations",
    "a fully reconciled control census",
    "additional assurance detectors",
    "surfaces beyond Claude and ChatGPT (portability, not proof)",
  ],
};

export const DISPOSITIONS = ["DO_NOW", "BLOCKING_PREREQUISITE", "DEFER", "OPTIONAL_DEBT"];

/**
 * Score one candidate task against the objective.
 *
 * @param {object} task
 *   blocks_objective        does the objective FAIL without this?
 *   reduces_objective_risk  does it materially lower risk to the objective?
 *   produces_required_evidence  is its output needed for the next decision?
 *   runtime_impacting       does it break normal execution today?
 *   serves_exit_criteria    ["EXIT-1", ...]
 *   cost                    "low" | "medium" | "high"
 */
export function valueGate(task = {}, objective = PRIMARY_OBJECTIVE) {
  const reasons = [];
  const serves = (task.serves_exit_criteria || []).filter((c) => objective.exit_criteria.some((e) => e.id === c && e.status === "OPEN"));

  // A runtime-critical defect is DO_NOW regardless of which criterion it serves:
  // an objective cannot be demonstrated on a system that will not run.
  if (task.runtime_impacting === true) {
    reasons.push("breaks normal execution today — the objective cannot be demonstrated on a system that does not run");
    return verdict("DO_NOW", reasons, serves, task);
  }

  if (task.blocks_objective === true) {
    reasons.push(`the objective FAILS without it (serves ${serves.join(", ") || "an open criterion"})`);
    return verdict(serves.length ? "DO_NOW" : "BLOCKING_PREREQUISITE", reasons, serves, task);
  }

  if (serves.length && (task.produces_required_evidence === true || task.reduces_objective_risk === true)) {
    reasons.push(`serves open criteria ${serves.join(", ")} by ${task.produces_required_evidence ? "producing evidence the next decision needs" : "materially reducing risk"}`);
    return verdict("DO_NOW", reasons, serves, task);
  }

  // THE RULE THE SUBSTRATE LACKED. Real, runnable, correct — and still not now.
  // "It is genuine debt" is an argument for recording it, never for doing it
  // ahead of the objective.
  if (task.is_debt === true || serves.length === 0) {
    reasons.push(
      "does not block the objective, does not materially reduce risk to it, and produces no evidence the next decision needs",
      "REAL DEBT IS STILL DEFERRABLE: that a defect is genuine argues for recording it, not for doing it before the objective",
    );
    return verdict(task.runtime_impacting === false && task.is_debt === true ? "OPTIONAL_DEBT" : "DEFER", reasons, serves, task);
  }

  reasons.push("no path to the objective established");
  return verdict("DEFER", reasons, serves, task);
}

function verdict(disposition, reasons, serves, task) {
  return {
    artifact: "value_gate",
    task: task.id ?? null,
    disposition,
    do_now: disposition === "DO_NOW" || disposition === "BLOCKING_PREREQUISITE",
    serves_open_criteria: serves,
    cost: task.cost ?? "unknown",
    reasons,
    principle:
      "Continuation asks whether to stop. This asks whether the next thing is worth doing. A system with only the " +
      "first learns persistence without judgment, and spends it on whatever is nearest.",
  };
}

/**
 * Order runnable candidates by value. THIS is what makes the gate load-bearing:
 * continuation selects highest-value-runnable, not next-runnable.
 */
export function prioritise(tasks = [], objective = PRIMARY_OBJECTIVE) {
  const scored = tasks.map((t) => ({ task: t, gate: valueGate(t, objective) }));
  const rank = (d) => DISPOSITIONS.indexOf(d);
  const costRank = { low: 0, medium: 1, high: 2, unknown: 1 };
  scored.sort((a, b) =>
    rank(a.gate.disposition) - rank(b.gate.disposition) ||
    b.gate.serves_open_criteria.length - a.gate.serves_open_criteria.length ||
    costRank[a.gate.cost] - costRank[b.gate.cost] ||
    String(a.task.id).localeCompare(String(b.task.id)));
  return {
    artifact: "value_ordering",
    objective: objective.id,
    open_criteria: objective.exit_criteria.filter((e) => e.status === "OPEN").map((e) => e.id),
    ordered: scored.map((s) => ({ id: s.task.id, disposition: s.gate.disposition, serves: s.gate.serves_open_criteria })),
    do_now: scored.filter((s) => s.gate.do_now).map((s) => s.task.id),
    deferred: scored.filter((s) => !s.gate.do_now).map((s) => s.task.id),
    note:
      "A DEFERRED task stays runnable, unexhausted and real. It is simply not the next thing. Deferral is a " +
      "statement about ORDER, not about validity — which is why it can be applied to work that is genuinely correct.",
  };
}
