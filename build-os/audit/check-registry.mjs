// AUDITING THE AUDITORS — source fidelity and failure capability.
//
// THE PREMISE: a check has a shelf life. Passing is not evidence that a check
// still guards anything; it is evidence that the check ran. Two independent
// ways a green check can guard nothing, and this repository has produced both:
//
//   SOURCE INFIDELITY — the check reads something other than the authoritative
//   source. `capability-discoverable-at-failure` scanned the GATE's own text
//   for path names after the gate had delegated its refusal to the selector; it
//   was reading a source that no longer decided the outcome.
//
//   NO FAILURE CAPABILITY — the check cannot fail at all. `ids_do_not_encode_arm`
//   was structurally incapable of failing. A broken `sed` continuation silently
//   emptied a negative fixture. Three separate tests asserted a SNAPSHOT
//   ("the count is 44") rather than an INVARIANT ("a violation is detected"),
//   and each passed for as long as nobody changed the number.
//
// Every one of those was green. Green is the failure mode.
//
// SO CONFIDENCE IS COMPUTED, NEVER DECLARED. A check cannot assert that it is
// trustworthy; it earns a state from its recorded fields, and the strongest
// state requires a DEMONSTRATED failure — a mutation that broke it — taken
// against the CURRENT version of the source it guards. When the source moves,
// the proof expires. That is what "shelf life" means mechanically.

export const ASSERTION_KINDS = ["invariant", "snapshot", "existence"];

// Ordered weakest to strongest. VACUOUS is deliberately WORSE than UNPROVEN:
// a check never tested might still work, while one demonstrated incapable of
// failing is actively misleading — it spends reviewer trust and returns none.
export const CONFIDENCE = [
  "VACUOUS",       // mutation applied, check still passed — it guards nothing
  "DISCONNECTED",  // reads a non-authoritative source; can pass while violated
  "UNPROVEN",      // never demonstrated capable of failing
  "STALE_PROOF",   // proved capable once, but the guarded source has moved since
  "PROVEN",        // reads the authoritative source AND fails under mutation now
];

// The twelve fields. A field left out is not "unknown" — it downgrades the
// check, because an unrecorded property is one nobody verified.
export const CHECK_FIELDS = [
  "id",                      //  1 stable identifier
  "guards",                  //  2 the invariant it claims to protect, in words
  "source_read",             //  3 what it actually reads
  "source_is_authoritative", //  4 is that the thing that DECIDES the outcome?
  "authoritative_source",    //  5 what does decide it, when 4 is false
  "assertion_kind",          //  6 invariant | snapshot | existence
  "failure_demonstrated",    //  7 has a mutation made it fail?
  "failure_proof",           //  8 which mutation, described
  "proof_taken_at",          //  9 the source fingerprint the proof was taken at
  "source_fingerprint_now",  // 10 that source's fingerprint today
  "owner_suite",             // 11 where it lives
  "drift_risk",              // 12 what would silently disconnect it
];

/**
 * Grade one check. The caller supplies observations; the STATE is derived.
 */
export function gradeCheck(c = {}) {
  const missing = CHECK_FIELDS.filter((f) => c[f] === undefined || c[f] === null || c[f] === "");
  const reasons = [];
  let confidence;

  if (c.failure_demonstrated === false && c.mutation_applied === true) {
    // The worst state, and it is only reachable by having TRIED. A mutation was
    // applied and the check still passed: it is proven to guard nothing.
    confidence = "VACUOUS";
    reasons.push("a mutation was applied to the guarded behaviour and this check STILL PASSED — it guards nothing, and its green result is actively misleading");
  } else if (c.source_is_authoritative === false) {
    confidence = "DISCONNECTED";
    reasons.push(`reads '${c.source_read}', which is not what decides the outcome (${c.authoritative_source ?? "authoritative source unrecorded"}) — it can pass while the invariant is violated`);
  } else if (c.failure_demonstrated !== true) {
    confidence = "UNPROVEN";
    reasons.push("never demonstrated capable of failing — passing tells you it ran, not that it guards");
  } else if (c.proof_taken_at && c.source_fingerprint_now && c.proof_taken_at !== c.source_fingerprint_now) {
    // THE SHELF LIFE. The proof was real, and it was about a version of the
    // source that no longer exists.
    confidence = "STALE_PROOF";
    reasons.push(`failure was demonstrated at source fingerprint ${String(c.proof_taken_at).slice(0, 12)}, but the guarded source is now ${String(c.source_fingerprint_now).slice(0, 12)} — the proof describes code that has since changed`);
  } else {
    confidence = "PROVEN";
    reasons.push(`fails under mutation (${c.failure_proof}) against the current version of the authoritative source`);
  }

  // A SNAPSHOT ASSERTION IS FLAGGED EVEN WHEN IT IS PROVEN, because it will
  // rot: it fails on the next legitimate change and gets "fixed" by updating
  // the number, which is how a guard quietly becomes a transcription.
  const warnings = [];
  if (c.assertion_kind === "snapshot")
    warnings.push("asserts a SNAPSHOT, not an invariant — it will fail on the next legitimate change and be repaired by updating the expected value, which converts a guard into a transcription");
  if (c.assertion_kind === "existence")
    warnings.push("asserts EXISTENCE only — it detects deletion, never wrongness");
  if (missing.length)
    warnings.push(`${missing.length} of 12 fields unrecorded: ${missing.join(", ")} — an unrecorded property is one nobody verified`);

  return {
    artifact: "check_grade",
    id: c.id ?? null,
    confidence,
    trustworthy: confidence === "PROVEN",
    guards: c.guards ?? null,
    fields_missing: missing,
    reasons,
    warnings,
  };
}

/** Audit a whole registry. The report leads with what is NOT trustworthy. */
export function auditChecks(checks = []) {
  const grades = checks.map(gradeCheck);
  const by = CONFIDENCE.reduce((o, k) => {
    const n = grades.filter((g) => g.confidence === k).length;
    if (n) o[k] = n;
    return o;
  }, {});
  const untrustworthy = grades.filter((g) => !g.trustworthy);

  return {
    artifact: "auditor_audit",
    checks: grades.length,
    by_confidence: by,
    trustworthy: grades.filter((g) => g.trustworthy).length,
    // Named individually because a count invites reading it as a score, and a
    // single DISCONNECTED check on a load-bearing invariant matters more than
    // twenty PROVEN ones elsewhere.
    not_trustworthy: untrustworthy.map((g) => ({ id: g.id, confidence: g.confidence, guards: g.guards, why: g.reasons[0] })),
    grades,
    note:
      "Confidence is DERIVED from recorded fields; a check cannot declare itself trustworthy. PROVEN requires a " +
      "demonstrated failure against the CURRENT version of the authoritative source — when that source moves, the " +
      "proof expires, because a mutation proof is a statement about code that existed when it was taken.",
    coverage_caveat:
      "This audits only REGISTERED checks. Checks nobody registered are invisible here and are not counted as gaps — " +
      "no registry can enumerate what it was never told about, and this report must not be read as a repository-wide count.",
  };
}
