// THE STOPPING GATE — capability exhaustion, made mechanical.
//
// THE EPISODE THAT CAUSED THIS. A worker was asked to build a Claude write path
// into the live Operator Lab. It searched ITS OWN tool surface, found no Lab
// tool, found the one candidate MCP server unauthenticated, and emitted
// `blocked`. The doctrine requiring capability exhaustion already existed. It
// did not fire, because nothing sat on the path between the conclusion and the
// operator.
//
// An exhaustive search of the SYSTEM — not the worker's local surface — then
// found `observe_interaction` and `gate_outbound_inference`, produced a real
// Claude-attributed control-plane event, and moved live readiness from
// ChatGPT-only to Claude + ChatGPT. The capability was never absent. It was
// absent FROM ONE WORKER'S VIEW, and the worker treated that as the same thing.
//
// So the defect is not missing doctrine. It is doctrine with no enforcement
// surface — the same failure shape as publication authority before it was
// wired, and as every "rule that is only a model" this substrate has found.
//
// THE RULE: a worker may not decide for itself that it has exhausted its
// options. Concession requires evidence, and incomplete evidence means keep
// searching.

export const CONCESSION_CLASSES = [
  "blocked", "cannot", "should_pause", "needs_manual",
  "sam_hands", "infeasible", "out_of_scope_capability",
];

export const VERDICTS = ["continue_search", "concession_allowed"];

// Phrases that ARE a concession regardless of how they are dressed. The gate
// must not be escapable by wording, because the worker writing the wording is
// the party the gate constrains.
export const CONCESSION_MARKERS = [
  /\bblocked\b/i, /\bcannot\b/i, /\bcan['’]t\b/i, /\bunable to\b/i,
  /\bno (?:way|path|route|mechanism)\b/i, /\bnot possible\b/i,
  /\bimpossible\b/i, /\bawait(?:ing)? (?:your|operator|human)\b/i,
  /\bneeds? (?:manual|human|operator)\b/i, /\bout of (?:my )?(?:scope|reach)\b/i,
  /\bI (?:don['’]t|do not) have (?:access|a tool|the ability)\b/i,
  /\bpaus(?:e|ing)\b/i, /\bhold(?:ing)? for\b/i,
];

/** Does this output concede? Detection is deliberately broad. */
export function isConcession(text = "") {
  const hits = CONCESSION_MARKERS.filter((re) => re.test(text));
  return { conceding: hits.length > 0, matched: hits.map(String) };
}

// The eight fields. Absence is not "unknown" here — it is INSUFFICIENT, and
// insufficient means keep going.
export const REQUIRED_EVIDENCE = [
  "proposed_concession",
  "concession_class",
  "available_interfaces",
  "paths_attempted",
  "attempt_results",
  "workaround_classes_considered",
  "why_each_viable_workaround_failed",
  "other_surface_may_hold_capability",
];

/**
 * The gate. Returns `continue_search` unless the evidence is complete AND the
 * cross-surface question has actually been answered.
 *
 * @param {object} ev  the eight fields
 * @param {object} opts
 *   attemptedSignatures: paths already tried in earlier rounds (loop control)
 *   round: which exhaustion round this is
 */
export function concessionGate(ev = {}, opts = {}) {
  const round = opts.round ?? 1;
  const maxRounds = opts.maxRounds ?? 3;
  const missing = REQUIRED_EVIDENCE.filter((f) => {
    const v = ev[f];
    if (v === undefined || v === null) return true;
    if (Array.isArray(v)) return v.length === 0;
    if (typeof v === "string") return v.trim().length === 0;
    return false;
  });

  const reasons = [];
  let verdict = "concession_allowed";
  const block = (r) => { verdict = "continue_search"; reasons.push(r); };

  if (missing.length) block(`incomplete exhaustion evidence — missing: ${missing.join(", ")}`);

  if (!CONCESSION_CLASSES.includes(ev.concession_class))
    block(`concession_class '${ev.concession_class}' is not a registered class`);

  // THE FIELD THE REAL FAILURE TURNED ON. A worker whose local surface lacks a
  // tool has established local absence, never system absence. This must be
  // answered with an enumeration, not an intuition.
  const cross = ev.other_surface_may_hold_capability;
  if (cross && typeof cross === "object") {
    if (cross.enumerated !== true)
      block("cross-surface capability search was NOT performed — local absence is not system absence");
    else if (Array.isArray(cross.surfaces_with_capability) && cross.surfaces_with_capability.length > 0)
      block(`another surface holds the capability: ${cross.surfaces_with_capability.join(", ")} — route through it instead of conceding`);
  } else if (!missing.includes("other_surface_may_hold_capability")) {
    block("other_surface_may_hold_capability must be a structured enumeration, not a prose assertion");
  }

  // Attempts must be REAL: a path listed but never executed is a plan, not an
  // attempt, and the whole point is that intention is not evidence.
  const attempts = Array.isArray(ev.paths_attempted) ? ev.paths_attempted : [];
  const results = Array.isArray(ev.attempt_results) ? ev.attempt_results : [];
  if (attempts.length && results.length < attempts.length)
    block(`${attempts.length} paths listed but only ${results.length} carry results — an unexecuted path is not an attempt`);

  // LOOP PROTECTION. Exhaustion terminates: a round that surfaced no new path
  // is evidence the search is done, and the round ceiling is absolute.
  const sigs = new Set(opts.attemptedSignatures || []);
  const fresh = attempts.filter((a) => !sigs.has(typeof a === "string" ? a : JSON.stringify(a)));
  if (verdict === "continue_search" && round >= maxRounds) {
    verdict = "concession_allowed";
    reasons.push(`round ceiling ${maxRounds} reached — conceding to avoid an endless workaround loop, with the gaps above recorded as UNRESOLVED rather than searched`);
  } else if (verdict === "continue_search" && round > 1 && fresh.length === 0) {
    verdict = "concession_allowed";
    reasons.push("this round surfaced NO path not already attempted — the search has converged, which is what exhaustion means");
  }

  return {
    artifact: "concession_gate",
    verdict,
    round,
    missing_evidence: missing,
    new_paths_this_round: fresh.length,
    reasons,
    binding:
      verdict === "continue_search"
        ? "The concession MAY NOT be emitted. Continue searching, then re-submit with the gaps above closed."
        : "Concession permitted on the recorded evidence.",
    principle:
      "A worker may not decide for itself that it has exhausted its options. The goal is not 'never stop' — it is " +
      "'never stop while unsearched agency remains'.",
  };
}
