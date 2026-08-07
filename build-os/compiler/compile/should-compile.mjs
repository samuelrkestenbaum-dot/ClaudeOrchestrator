// Selective compilation — should this task receive a compiled capsule at all?
//
// EXP-0004 assumed compilation was universal and the data did not support that.
// Across five matched pairs the compiled arm ranged from 3.3x the uncached
// tokens of the standard arm (E2) to 59% fewer (E4). A mechanism with that
// spread is not uniformly wrong; it is UNROUTED.
//
// THRESHOLD PROVENANCE — read this before changing a number below.
// These thresholds are derived from STRUCTURAL properties of a capsule, not
// from which EXP-0004 tasks happened to win. Fitting them to those five
// outcomes would be post-treatment tuning of a frozen experiment, and the
// result would predict nothing. Each constant below therefore states the
// structural reason it exists, and every one of them is a v1 DEFAULT awaiting
// validation on a task set that has never been observed. Their predictive
// value is currently UNMEASURED, and this module says so in its own output
// rather than implying otherwise.
//
// The decision is deterministic and explainable: same inputs, same verdict,
// same stated reasons, no clock and no random source.

export const DECISIONS = ["compile", "standard_context", "insufficient_evidence"];

export const THRESHOLDS = {
  max_expansion_ratio: 12,
  max_predicted_bytes: 60000,
  max_exclusion_share: 0.5,
  min_parsed_share: 0.6,
  min_semantic_items: 1,
};

export const THRESHOLD_REASONS = {
  max_expansion_ratio:
    "candidates per seed file. A walk that returns many times more files than the task named has stopped " +
    "being selective attention and become a subdirectory dump; the capsule then costs more than the " +
    "exploration it replaces.",
  max_predicted_bytes:
    "a capsule is a REPLACEMENT for exploration, so it must be cheaper than exploring. Past roughly this size " +
    "it is a second broad context rather than a substitute for one.",
  max_exclusion_share:
    "the share of the candidate set that had to be declined. Declining most of what the walk found means the " +
    "walk's relevance signal disagreed with the budget, and neither is trustworthy on its own.",
  min_parsed_share:
    "share of defining files with a real extractor. Symbol lists from unparsed files are empty for a reason " +
    "that has nothing to do with the code, and a capsule built on them is confidently wrong.",
  min_semantic_items:
    "at least one piece of semantic dependency evidence. EXP-0004's deciding failure was a fix that was " +
    "locally correct and globally wrong; a capsule that cannot show ANY dependant offers no protection " +
    "against repeating it.",
};

/**
 * @param {object} signals
 *   seed_files, candidates, admitted, declined, predicted_bytes,
 *   defining_parsed, defining_total, semantic_items, semantic_error_named
 * @returns {{decision, reasons, signals, thresholds, confidence_note}}
 */
export function shouldCompile(signals) {
  const s = { ...signals };
  const reasons = [];
  const missing = [];

  for (const k of ["seed_files", "candidates", "predicted_bytes", "defining_total"]) {
    if (typeof s[k] !== "number") missing.push(k);
  }
  if (missing.length) {
    return {
      decision: "insufficient_evidence",
      reasons: [`cannot decide: ${missing.join(", ")} not measured — an unmeasured signal is not a passing one`],
      signals: s, thresholds: THRESHOLDS,
      confidence_note: CONFIDENCE_NOTE,
    };
  }

  const expansion = s.seed_files > 0 ? s.candidates / s.seed_files : Infinity;
  const exclusionShare = s.candidates > 0 ? (s.declined ?? 0) / s.candidates : 0;
  const parsedShare = s.defining_total > 0 ? (s.defining_parsed ?? 0) / s.defining_total : 0;
  const semItems = s.semantic_items ?? 0;

  const against = [];
  if (expansion > THRESHOLDS.max_expansion_ratio)
    against.push(`expansion ratio ${expansion.toFixed(1)} candidates per seed exceeds ${THRESHOLDS.max_expansion_ratio} — ${THRESHOLD_REASONS.max_expansion_ratio}`);
  if (s.predicted_bytes > THRESHOLDS.max_predicted_bytes)
    against.push(`predicted capsule ${s.predicted_bytes} B exceeds ${THRESHOLDS.max_predicted_bytes} B — ${THRESHOLD_REASONS.max_predicted_bytes}`);
  if (exclusionShare > THRESHOLDS.max_exclusion_share)
    against.push(`${(exclusionShare * 100).toFixed(0)}% of candidates were declined, over ${THRESHOLDS.max_exclusion_share * 100}% — ${THRESHOLD_REASONS.max_exclusion_share}`);

  const unknown = [];
  if (parsedShare < THRESHOLDS.min_parsed_share)
    unknown.push(`only ${(parsedShare * 100).toFixed(0)}% of defining files have a real extractor, under ${THRESHOLDS.min_parsed_share * 100}% — ${THRESHOLD_REASONS.min_parsed_share}`);
  if (semItems < THRESHOLDS.min_semantic_items)
    unknown.push(`${semItems} semantic dependency item(s), under ${THRESHOLDS.min_semantic_items} — ${THRESHOLD_REASONS.min_semantic_items}`);

  // Order matters: an unmeasurable capsule is not the same as a bad one, and
  // saying so is the difference between routing and guessing.
  let decision;
  if (unknown.length) { decision = "insufficient_evidence"; reasons.push(...unknown); }
  else if (against.length) { decision = "standard_context"; reasons.push(...against); }
  else {
    decision = "compile";
    reasons.push(
      `expansion ${expansion.toFixed(1)}/seed within ${THRESHOLDS.max_expansion_ratio}`,
      `predicted ${s.predicted_bytes} B within ${THRESHOLDS.max_predicted_bytes} B`,
      `${(exclusionShare * 100).toFixed(0)}% declined within ${THRESHOLDS.max_exclusion_share * 100}%`,
      `${(parsedShare * 100).toFixed(0)}% of defining files parsed`,
      `${semItems} semantic dependency item(s)${s.semantic_error_named ? `, ${s.semantic_error_named} concerning an error-named property` : ""}`);
  }

  return {
    decision,
    reasons,
    signals: { ...s, expansion_ratio: Number(expansion.toFixed(2)), exclusion_share: Number(exclusionShare.toFixed(3)), parsed_share: Number(parsedShare.toFixed(3)) },
    thresholds: THRESHOLDS,
    fallback: decision === "compile" ? null : "standard_context",
    confidence_note: CONFIDENCE_NOTE,
  };
}

export const CONFIDENCE_NOTE =
  "These thresholds are v1 DEFAULTS derived from structural properties of a capsule, NOT fitted to EXP-0004's " +
  "five task outcomes — fitting them to a frozen experiment would predict nothing. Their predictive value is " +
  "UNMEASURED. A refusal here is a statement about the capsule's shape, never a prediction that the task is hard.";
