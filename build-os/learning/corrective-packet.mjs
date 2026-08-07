// Bounded internal mutation authority for Post-Outcome Disposition v0.
//
// Closes: evidence -> finding -> disposition -> BOUNDED CORRECTIVE ACTION,
// without turning the substrate into an unconstrained self-modifying system.
//
// The boundary in one sentence: a finding may open a packet automatically, and
// a packet may execute automatically ONLY when it is internal, reversible,
// evidence-linked, and of an explicitly allowed change kind. Everything else is
// queued for a human. Creating a packet is not permission to change anything.

import crypto from "node:crypto";

// --- change kinds -----------------------------------------------------------
// Allowed to execute from a single finding. Each is internal, reversible, and
// verifiable by a fixture.
export const AUTO_EXECUTABLE = [
  "parser_extractor_defect",
  "bounded_relevance_rule",
  "prompt_disclosure_to_artifact",
  "harness_defect",
  "regression_fixture",
];

// Never automatic from one finding, whatever the confidence. These are not
// "risky versions" of the above; they are different in kind — they change what
// the system IS, commit it externally, or remove a control.
export const NEVER_AUTOMATIC = [
  "broad_architecture",
  "provider_strategy",
  "pricing_gtm",
  "safety_or_evidence_control_removal",
  "external_integration",
  "irreversible_external_mutation",
  "hypothesis_only",
];

// Paths whose contents are IMMUTABLE INPUT to learning. A corrective packet may
// create new code, tests and outcome artifacts; it may never edit the evidence
// that produced it. New evidence can supersede an old belief. It cannot rewrite
// history.
export const FROZEN_EVIDENCE_PATTERNS = [
  /\/experiments\/[^/]+\/results\//,
  /\/experiments\/[^/]+\/RESULT\.md$/,
  /\/experiments\/[^/]+\/EXECUTION_LOG\.md$/,
  /\/experiments\/[^/]+\/mapping\.sha256$/,
  /\/experiments\/[^/]+\/TASK_FREEZE\.md$/,
  /\/experiments\/[^/]+\/PREREGISTRATION\.md$/,
  /\/pilots\/[^/]+\//,
];

export const PACKET_FIELDS = [
  "finding_id", "finding_class", "component", "evidence_refs", "confidence",
  "proposed_change", "mutation_boundary", "authority_class", "rollback",
  "verification", "completion_criteria", "prohibited_adjacent", "outcome_record",
];

export const PACKET_STATES = ["proposed", "executable", "queued", "in_progress", "closed", "unresolved_failed"];

const id = (s) => crypto.createHash("sha256").update(s).digest("hex").slice(0, 12);

/**
 * Turn a finding into a corrective packet. Creating a packet NEVER mutates
 * anything; the returned `state` says whether execution is permitted.
 */
export function createPacket(finding, { change_kind = null, mutation_boundary = [], rollback = null } = {}) {
  const problems = [];
  if (!finding || !finding.finding_id) problems.push("finding has no finding_id");
  if (!Array.isArray(mutation_boundary) || mutation_boundary.length === 0)
    problems.push("mutation_boundary must name the paths this packet may touch — an unbounded packet is not bounded");
  if (!change_kind) problems.push("change_kind is required; it is what the authority check reads");

  // A packet may never declare frozen evidence inside its boundary.
  const frozen = (mutation_boundary || []).filter((p) => FROZEN_EVIDENCE_PATTERNS.some((re) => re.test(p)));
  if (frozen.length) problems.push(`mutation_boundary includes FROZEN EVIDENCE: ${frozen.join(", ")} — a corrective packet may not edit the evidence that produced it`);

  const packet = {
    artifact: "corrective_packet",
    packet_id: `CP-${id((finding?.finding_id || "?") + JSON.stringify(mutation_boundary))}`,
    finding_id: finding?.finding_id ?? null,
    finding_class: finding?.class ?? null,
    component: finding?.component ?? null,
    evidence_refs: finding?.evidence ?? [],
    confidence: finding?.confidence ?? null,
    proposed_change: finding?.proposed_change ?? null,
    change_kind,
    mutation_boundary,
    authority_class: finding?.authority ?? "operator_decision",
    rollback: rollback || "git revert of the packet's commits; no external mutation is permitted, so nothing is unrecoverable",
    verification: finding?.revalidation ?? null,
    completion_criteria: [
      "the required regression fixture passes",
      "relevant existing tests pass",
      "every mutated path is inside mutation_boundary",
      "no prohibited adjacent change occurred",
      "the outcome record is written",
    ],
    prohibited_adjacent: [
      "any change outside mutation_boundary",
      "any edit to frozen experiment or pilot evidence",
      "removal or weakening of a safety, authority or evidence control",
      "expansion of the packet's objective beyond the finding that opened it",
    ],
    outcome_record: `build-os/learning/outcomes/${finding?.finding_id ?? "unknown"}.json`,
    state: "proposed",
    refusals: problems,
  };

  if (problems.length) { packet.state = "queued"; packet.may_execute = false; return packet; }
  const auth = authorityCheck(finding, change_kind);
  packet.state = auth.may_execute ? "executable" : "queued";
  packet.may_execute = auth.may_execute;
  packet.authority_reasons = auth.reasons;
  return packet;
}

/**
 * The authority gate. Deliberately conjunctive: every condition must hold, and
 * a missing one is a refusal rather than a default.
 */
export function authorityCheck(finding, change_kind) {
  const reasons = [];
  let ok = true;
  const need = (cond, why) => { if (!cond) { ok = false; reasons.push(why); } else reasons.push(`ok: ${why.replace(/^refused: /, "")}`); };

  need(finding?.disposition === "execute",
    `refused: disposition is '${finding?.disposition}', not 'execute' — queue and observe are never silently upgraded`);
  need(finding?.authority === "bounded_internal_product_change",
    `refused: authority class '${finding?.authority}' is wider than bounded_internal_product_change`);
  need(AUTO_EXECUTABLE.includes(change_kind),
    `refused: change_kind '${change_kind}' is not in the automatically executable set`);
  need(!NEVER_AUTOMATIC.includes(change_kind),
    `refused: change_kind '${change_kind}' is explicitly never automatic`);
  need(finding?.class !== "unsupported_hypothesis",
    `refused: the finding's evidence supports a HYPOTHESIS, not a defect`);
  need(Array.isArray(finding?.evidence) && finding.evidence.length > 0,
    `refused: no evidence references — an unevidenced mutation is not traceable`);

  return { may_execute: ok, reasons };
}

/**
 * Close a packet. A packet is NOT closed when code is written; it closes when
 * verification passes. A failed verification is recorded as failed learning,
 * never as success.
 */
export function closePacket(packet, verification) {
  const v = verification || {};
  const failures = [];
  if (v.fixture_passed !== true) failures.push("required regression fixture did not pass");
  if (v.existing_tests_passed !== true) failures.push("relevant existing tests did not pass");

  const outside = (v.mutated_paths || []).filter(
    (p) => !(packet.mutation_boundary || []).some((b) => p === b || p.startsWith(b.replace(/\/?$/, "/"))));
  if (outside.length) failures.push(`mutation escaped its boundary: ${outside.join(", ")}`);

  const touchedFrozen = (v.mutated_paths || []).filter((p) => FROZEN_EVIDENCE_PATTERNS.some((re) => re.test(p)));
  if (touchedFrozen.length) failures.push(`FROZEN EVIDENCE was modified: ${touchedFrozen.join(", ")}`);

  if (v.outcome_recorded !== true) failures.push("no outcome record was written");

  return {
    ...packet,
    state: failures.length ? "unresolved_failed" : "closed",
    verification_result: failures.length ? "failed" : "passed",
    verification_failures: failures,
    verification_evidence: v,
    closure_note: failures.length
      ? "This finding remains UNRESOLVED. A failed corrective action is failed learning, not completed learning."
      : "Finding resolved: mutation stayed inside its boundary, verification passed, and the outcome is recorded.",
  };
}

/** Backward: mutation -> packet -> finding -> outcome -> evidence. */
export function traceBackward(packet, finding, outcomeRef) {
  return {
    query: "why did the substrate change this?",
    chain: [
      { step: "mutation", value: packet.mutation_boundary },
      { step: "corrective_packet", value: packet.packet_id },
      { step: "finding", value: packet.finding_id, class: packet.finding_class },
      { step: "outcome", value: outcomeRef ?? "(not supplied)" },
      { step: "evidence", value: finding?.evidence ?? packet.evidence_refs },
    ],
    deterministic: true,
    note: "Every link is a recorded identifier. Nothing here is a reconstructed explanation.",
  };
}

/** The unfinished-learning query. Substrate state, not conversational memory. */
export function unfinishedLearning(findings = [], packets = []) {
  const byFinding = new Map(packets.map((p) => [p.finding_id, p]));
  const executeFindings = findings.filter((f) => f.disposition === "execute");

  return {
    artifact: "unfinished_learning",
    execute_without_completed_action: executeFindings
      .filter((f) => (byFinding.get(f.finding_id)?.state ?? "none") !== "closed")
      .map((f) => ({ finding_id: f.finding_id, component: f.component, state: byFinding.get(f.finding_id)?.state ?? "no packet" })),
    queued_hypotheses_awaiting_evidence: findings
      .filter((f) => f.disposition === "queue")
      .map((f) => ({ finding_id: f.finding_id, component: f.component, needs: f.revalidation })),
    packets_failed_verification: packets
      .filter((p) => p.state === "unresolved_failed")
      .map((p) => ({ packet_id: p.packet_id, finding_id: p.finding_id, failures: p.verification_failures })),
    closed_without_followup_evidence: packets
      .filter((p) => p.state === "closed" && p.followup_outcome_recorded !== true)
      .map((p) => ({ packet_id: p.packet_id, finding_id: p.finding_id })),
    observed_only: findings.filter((f) => f.disposition === "observe").map((f) => f.finding_id),
    note:
      "An empty list here means the substrate has no record of unfinished learning — NOT that none exists. " +
      "Only findings and packets actually written are visible to this query.",
  };
}
