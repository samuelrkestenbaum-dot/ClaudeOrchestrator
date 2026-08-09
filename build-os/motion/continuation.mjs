// THE CONTINUATION CONTROLLER.
//
// THE DEFECT IT FIXES: `task_completion_without_continuation`. The substrate
// treated
//     current task finished  ==>  session should stop
// as if the implication held. It does not. Finishing a unit of work is not a
// stop condition, and neither is a local commit awaiting a push grant.
//
// The observed incident: the forward-motion gate was built, proven, committed —
// and the session then reported "Nothing is running. Queue unchanged and
// unadvanced." while #50 sat runnable with its dependency satisfied. The
// capability-exhaustion gate was working; nothing asked the next question.
//
// EXECUTION AUTHORITY AND PUBLICATION AUTHORITY ARE DIFFERENT. An unpushed
// commit blocks publication, not work. Downstream work that does not require
// publication first proceeds locally, with the commit preserved.

import { prioritise } from "./objective.mjs";

export const TERMINAL_CONDITIONS = [
  "explicit_operator_stop",
  "no_remaining_queued_work",
  "all_remaining_blocked_after_exhaustion",
  "authority_or_safety_forbids_execution",
  "unavoidable_environment_termination",
];

// Stated as a list because these were the two the substrate actually got wrong.
export const NON_TERMINAL = [
  "current_task_completed",
  "commit_awaiting_push_authorization",
];

/**
 * @param {object} state
 *   tasks: [{ id, status, depends_on:[], requires_publication_of:[], blocked_evidence }]
 *   published_tips: []          — commits already pushed
 *   operator_stop: bool
 *   safety_stop: bool
 *   environment_terminating: bool
 *   transition_log: []          — prior attempts, for loop control
 */
export function continuationDecision(state = {}) {
  const tasks = state.tasks || [];

  // `term` takes its evidence EXPLICITLY. It used to default to `evaluated`,
  // which is declared further down — so every early terminal path threw a
  // temporal-dead-zone ReferenceError instead of permitting the stop, and a
  // controller that throws on `operator_stop` is worse than no controller.
  // The same defect class was fixed once already in gate-recovery.mjs; a
  // default parameter referencing a later `const` is the shape to watch for.
  if (state.operator_stop === true)
    return term("explicit_operator_stop", "the operator issued a stop", []);
  if (state.safety_stop === true)
    return term("authority_or_safety_forbids_execution", "authority or safety policy forbids further execution", []);
  if (state.environment_terminating === true)
    return term("unavoidable_environment_termination", "the environment is terminating", []);

  const open = tasks.filter((t) => t.status !== "completed" && t.status !== "deleted");
  if (open.length === 0)
    return term("no_remaining_queued_work", "the queue holds no open work", []);

  // Runnable = every dependency completed, and any publication prerequisite
  // actually published. A task whose ONLY obstacle is an unpushed commit that
  // it does not itself require is still runnable.
  const completed = new Set(tasks.filter((t) => t.status === "completed").map((t) => t.id));
  const published = new Set(state.published_tips || []);

  const evaluated = open.map((t) => {
    const unmetDeps = (t.depends_on || []).filter((d) => !completed.has(d));
    const unmetPub = (t.requires_publication_of || []).filter((c) => !published.has(c));
    const exhausted = t.blocked_evidence?.verdict === "concession_allowed";
    return {
      id: t.id, subject: t.subject,
      unmet_dependencies: unmetDeps,
      unmet_publication_prerequisites: unmetPub,
      genuinely_blocked: exhausted === true,
      runnable: unmetDeps.length === 0 && unmetPub.length === 0 && exhausted !== true,
    };
  });

  const runnable = evaluated.filter((e) => e.runnable);
  const blockedNotExhausted = evaluated.filter((e) => !e.runnable && !e.genuinely_blocked);

  if (runnable.length === 0) {
    // Every remaining task must have PASSED capability exhaustion before this
    // counts as terminal. "Nothing looks runnable to me" is not evidence.
    if (blockedNotExhausted.length > 0) {
      return {
        artifact: "continuation_decision",
        decision: "continue",
        next_task: null,
        reasons: [
          `no task is runnable, but ${blockedNotExhausted.length} have NOT passed capability exhaustion: ` +
          blockedNotExhausted.map((b) => b.id).join(", "),
          "run the concession gate on each before treating the queue as blocked",
        ],
        evaluated,
        binding: "STOP REFUSED — unexhausted blockers are not terminal.",
      };
    }
    return term("all_remaining_blocked_after_exhaustion",
      `every remaining task is genuinely blocked with recorded exhaustion evidence: ${evaluated.map((e) => e.id).join(", ")}`, evaluated);
  }

  // LOOP CONTROL. Repeatedly selecting the same task without state changing is
  // not progress; escalate through exhaustion rather than cycling.
  const log = state.transition_log || [];

  // VALUE ORDERING, not queue order. The controller used to take runnable[0] —
  // the next runnable task — which is why it could refuse to stop and still
  // spend four packets on an anchor migration that moved the objective by
  // nothing. Every step was correct; nothing asked whether the task was still
  // worth doing. Deferral here is a statement about ORDER, not validity.
  const ordered = prioritise(runnable.map((e) => ({ ...(tasks.find((t) => t.id === e.id) || {}), id: e.id })));
  const byValue = ordered.do_now.length
    ? runnable.filter((e) => ordered.do_now.includes(e.id))
    : runnable;
  const next = byValue[0] ?? runnable[0];
  const repeats = log.filter((l) => l.next_task === next.id && l.state_changed === false).length;
  if (repeats >= 2) {
    return {
      artifact: "continuation_decision",
      decision: "continue",
      next_task: runnable[1]?.id ?? null,
      reasons: [`task ${next.id} was selected ${repeats}x with no state change — escalating past it rather than looping`,
        runnable[1] ? `selecting ${runnable[1].id} instead` : "no alternative runnable task; run capability exhaustion on " + next.id],
      evaluated,
      binding: "STOP REFUSED — but the repeating task is escalated, not retried.",
    };
  }

  return {
    artifact: "continuation_decision",
    decision: "continue",
    next_task: next.id,
    next_subject: next.subject,
    reasons: [
      `${runnable.length} runnable task(s); task completion is NOT a stop condition`,
      `selected ${next.id} — dependencies satisfied, no unmet publication prerequisite`,
      ordered.do_now.length
        ? `value gate: DO_NOW ${ordered.do_now.join(", ")}; DEFERRED ${ordered.deferred.join(", ") || "(none)"} — deferred work stays real, it is simply not next`
        : "value gate: NO runnable task serves an open exit criterion — the queue holds only deferrable debt, which is itself worth reporting",
    ],
    value_ordering: ordered,
    evaluated,
    binding: "STOP REFUSED — begin the next task.",
  };

  function term(condition, why, ev) {
    return {
      artifact: "continuation_decision",
      decision: "stop",
      terminal_condition: condition,
      next_task: null,
      reasons: [why],
      evaluated: ev,
      binding: "Stop permitted: a registered terminal condition holds.",
    };
  }
}
