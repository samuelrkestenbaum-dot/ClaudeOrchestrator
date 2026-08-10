// PROGRAM CONVERGENCE GATE — governs when enough evidence is enough.
//
// THE GAP THIS CLOSES. Gravito already governs HOW work proceeds: authority,
// host compatibility, continuation, objective value, measurement validity,
// assumption staleness. Every one of those is a LOCAL control, and every step of
//
//     find contamination -> correct baseline -> discover capability starvation
//     -> correct environment -> re-baseline again
//
// was individually defensible under them. Nothing was aggregating how many
// measurement defects had already occurred, how often the apparent target had
// moved, or whether another experiment could still change the decision. A system
// optimised for persistence and correctness, without that layer, becomes an
// infinite scientist: "interesting confound, one more experiment."
//
// THE ANTI-CEREMONY CONSTRAINT, stated before the code. A gate that asks the
// proposer "is the expected information gain high?" measures nothing but the
// proposer's enthusiasm -- it is the same defect as a check that never
// demonstrated a failure, one layer up. So the refusals below are decided from
// the PROGRAM STATE and from the STRUCTURE of the proposal, never from a
// self-assessed score. Information gain is DERIVED here, not accepted.
//
// The gate can return PROCEED. It is not a brake on all work -- it is a brake on
// work whose result cannot move a decision.

import fs from "node:fs";
import path from "node:path";

const HERE = path.dirname(new URL(import.meta.url).pathname);
export const PROGRAM_FILE = path.join(HERE, "program.json");

export function loadProgram(file = PROGRAM_FILE) {
  return JSON.parse(fs.readFileSync(file, "utf8"));
}

/**
 * Assess a proposed experiment, baseline, diagnostic or optimisation.
 *
 * proposal = {
 *   work:              string  -- what would be done
 *   decision_id:       string  -- the open decision it serves
 *   possible_results:  [{ result, next_action }]  -- at least two, distinguishable
 *   hypothesis_id:     string  -- which hypothesis this tests
 *   differs_from_prior:string  -- REQUIRED on a repeat attempt: what changed
 * }
 */
export function assess(proposal, program = loadProgram()) {
  const reasons = [];
  const refuse = (code, why) => ({ verdict: "REFUSE", code, why, reasons });
  const defer = (code, why) => ({ verdict: "DEFER", code, why, reasons });

  // R3 — the work must serve a NAMED, OPEN decision. Work that serves no
  // decision is the purest form of the loop this gate exists to break.
  const d = (program.open_decisions || []).find((x) => x.id === proposal.decision_id);
  if (!d) return refuse("undeclared_decision",
    `no open decision '${proposal.decision_id}'. Open: ${(program.open_decisions || []).map((x) => x.id).join(", ") || "none"}`);
  if (d.status !== "open") return refuse("decision_already_closed",
    `decision ${d.id} is '${d.status}' — its uncertainty is resolved, so this cannot inform it`);

  // R1 — STOP CONDITION. Declared in advance, checked mechanically. This is the
  // rule that would have ended the sequence, and it cannot be argued with
  // because satisfaction is recorded as a fact, not judged at proposal time.
  const stop = (program.stop_conditions || []).find((s) => s.applies_to === d.id && s.satisfied);
  if (stop) return refuse("stop_condition_satisfied",
    `stop condition ${stop.id} is SATISFIED: ${stop.rule}`);

  // R5 — you must be able to state at least two distinguishable outcomes. If you
  // cannot say what the result could be, you cannot claim it will inform anything.
  const rs = proposal.possible_results || [];
  if (rs.length < 2) return refuse("no_distinguishable_outcomes",
    `only ${rs.length} possible result(s) declared; work that can come out exactly one way measures nothing`);

  // R2 — DIVERGENCE. The load-bearing test: if every plausible result leads to
  // the SAME next action, the result cannot change what we do, whatever it says.
  const actions = [...new Set(rs.map((r) => String(r.next_action).trim().toLowerCase()))];
  if (actions.length < 2) return defer("no_result_changes_the_decision",
    `all ${rs.length} declared results lead to the same next action ('${rs[0].next_action}')`);

  // DERIVED information gain -- from the proposal's structure, not its adjectives.
  const gain = actions.length / rs.length;
  const band = gain >= 0.75 ? "high" : gain >= 0.5 ? "medium" : "low";
  reasons.push(`${actions.length} distinct next action(s) across ${rs.length} possible result(s) — derived gain ${band}`);

  // R4 — REPEAT ATTEMPTS. A rescue of the same hypothesis is legitimate only if
  // something is genuinely different, and the difference must be NEW: repeating
  // a correction already logged is the loop wearing a fresh label.
  const attempts = d.measurement_attempts || 0;
  if (attempts >= 1) {
    const diff = String(proposal.differs_from_prior || "").trim();
    if (!diff) return refuse("repeat_attempt_without_stated_difference",
      `attempt ${attempts + 1} on ${d.id}; prior: ${(d.attempt_log || []).join(" | ")}. State what is different or defer.`);
    const seen = (d.attempt_log || []).map((s) => s.toLowerCase());
    if (seen.some((s) => s.includes(diff.toLowerCase()) || diff.toLowerCase().includes(s.replace(/ —.*$/, ""))))
      return refuse("repeat_attempt_difference_already_tried",
        `'${diff}' is already in the attempt log for ${d.id}`);
    reasons.push(`attempt ${attempts + 1}, differing by: ${diff}`);
  }

  return { verdict: "PROCEED", code: "result_can_change_the_decision", why:
    `a result here selects between: ${actions.join(" | ")}`, reasons, derived_gain: band };
}

/** Mark a stop condition satisfied. Separated so satisfaction is an act, recorded. */
export function satisfyStop(stopId, evidence, file = PROGRAM_FILE) {
  const p = loadProgram(file);
  const s = (p.stop_conditions || []).find((x) => x.id === stopId);
  if (!s) throw new Error(`no stop condition ${stopId}`);
  s.satisfied = true;
  s.satisfied_evidence = evidence;
  fs.writeFileSync(file, JSON.stringify(p, null, 2) + "\n");
  return s;
}
