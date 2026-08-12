// CONTINUATION GATE (#55) — when is stopping valid? The operator's four-branch
// rule, verbatim from the ruling after the wrong-stop incident:
//
//   explicit operator stop                         -> STOP
//   genuine blocker after exhaustion               -> BLOCKED
//   material unresolved ambiguity                  -> SURFACE exactly that ambiguity
//   otherwise, if a next task is specified +
//   authorized + runnable + unblocked +
//   positive-value                                 -> CONTINUE (a stop is INVALID)
//
// The measured defects this encodes: (1) a session stopped for the night while
// #54 was specified, authorized, and runnable — the stop was taken for a
// reason ("it's late") that is not one of the four branches; (2) one message
// earlier, a launch-timing ambiguity silently became a HOLD instead of being
// surfaced as exactly that ambiguity. Both verdicts here are decided from the
// STRUCTURE of the state handed in — never from a self-assessed preference to
// stop, which is the same defect as self-assessed information gain, one layer
// down. Same design family as convergence.mjs: refusals mechanical, gate can
// return CONTINUE as easily as STOP.
//
// state = {
//   operator_stop:  bool | string   -- an EXPLICIT stop from the operator (the
//                                      words, if a string). Stop-hook feedback
//                                      and other automation NEVER set this.
//   blockers:       [{ what, routes_tried: [..] }]
//                                   -- a blocker is GENUINE only after >=2
//                                      distinct route classes were tried
//                                      (shell | mcp/lsp tool | subagent),
//                                      mirroring the worker contract's floor.
//   ambiguities:    [{ what, material: bool }]
//                                   -- material = resolving it would change
//                                      WHAT gets executed, not how it's phrased.
//   next_task:      { name, specified, authorized, runnable, deferred,
//                     positive_value }  | null
// }
export function assessStop(state = {}) {
  const s = state;
  // Branch 1 — an explicit operator stop is always valid, and it wins.
  if (s.operator_stop) {
    return { verdict: "STOP", branch: "explicit_operator_stop",
      why: typeof s.operator_stop === "string" ? `operator: ${s.operator_stop}` : "operator said stop" };
  }
  // Branch 2 — a blocker counts only after exhaustion across route classes.
  const genuine = (s.blockers || []).filter((b) => new Set(b.routes_tried || []).size >= 2);
  const unexhausted = (s.blockers || []).filter((b) => new Set(b.routes_tried || []).size < 2);
  if (genuine.length && !nextRunnable(s)) {
    return { verdict: "BLOCKED", branch: "genuine_blocker_after_exhaustion",
      why: genuine.map((b) => `${b.what} (tried: ${(b.routes_tried || []).join(", ")})`).join("; ") };
  }
  // Branch 3 — a material ambiguity is SURFACED, never silently parked. The
  // verdict names it, because "surface exactly that ambiguity" is the rule.
  const material = (s.ambiguities || []).filter((a) => a.material);
  if (material.length) {
    return { verdict: "SURFACE", branch: "material_unresolved_ambiguity",
      why: `surface exactly: ${material.map((a) => a.what).join("; ")}`,
      surface: material.map((a) => a.what) };
  }
  // Branch 4 — the continuation default. If work meets all five predicates, a
  // stop is INVALID: name the task and continue.
  if (nextRunnable(s)) {
    const t = s.next_task;
    return { verdict: "CONTINUE", branch: "specified_authorized_runnable",
      why: `'${t.name}' is specified+authorized+runnable+unblocked+positive-value — a stop here is invalid`,
      task: t.name };
  }
  // Nothing runnable, nothing blocking, nothing ambiguous, no stop order:
  // stopping is legitimate — but the gate says WHY, and an unexhausted blocker
  // is reported as the single thing left to try rather than laundered away.
  return { verdict: "STOP", branch: "no_runnable_work",
    why: unexhausted.length
      ? `no runnable next task; NOTE an unexhausted blocker remains: ${unexhausted.map((b) => `${b.what} (only tried: ${(b.routes_tried || []).join(", ") || "nothing"})`).join("; ")}`
      : "no specified+authorized+runnable next task exists" };
}

function nextRunnable(s) {
  const t = s.next_task;
  return !!(t && t.specified && t.authorized && t.runnable && !t.deferred && t.positive_value !== false);
}
