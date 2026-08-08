// STATE CLASSIFICATION AUDIT.
//
// The worked example is INVENTORY.md classifying the routing ledgers as
// "per-session live ledgers, not durable knowledge". They were load-bearing for
// the ability to act. The classification was not merely wrong — it was
// UNCHECKABLE, because nothing compared "declared disposable" against "required
// before first action".
//
// A state item may legitimately hold several properties. What must be
// detectable is the CONTRADICTIONS between them.

export const PROPERTIES = [
  "durable",             // ships / survives a clean restore
  "reconstructable",     // can be deterministically rebuilt
  "ephemeral",           // may vanish at any time
  "session_local",       // belongs to one session
  "externally_supplied", // comes from the host/operator, not from us
  "load_bearing",        // something cannot proceed without it
  "must_never_persist",  // storing it is itself the defect (secrets, live grants)
];

// Each contradiction names the failure it prevents. A rule with no failure
// behind it is decoration.
export const CONTRADICTIONS = [
  {
    id: "load_bearing_but_unrecoverable",
    when: (s) => s.load_bearing && !s.durable && !s.reconstructable && !s.externally_supplied,
    severity: "high",
    why: "required to operate, does not ship, and cannot be rebuilt — it exists only as residue on a machine that has been running",
  },
  {
    id: "ephemeral_but_required_before_first_action",
    when: (s) => s.ephemeral && s.load_bearing && s.required_before_first_action === true,
    severity: "high",
    why: "a clean start has no ephemeral state yet, so the first action can never occur",
  },
  {
    id: "session_local_consumed_across_sessions",
    when: (s) => s.session_local && s.consumed_across_sessions === true,
    severity: "high",
    why: "state scoped to one session is read by another — it will be absent, stale, or belong to the wrong run",
  },
  {
    id: "reconstructable_without_constructor",
    when: (s) => s.reconstructable && !s.constructor_ref,
    severity: "medium",
    why: "claimed rebuildable with no deterministic constructor named — the claim cannot be exercised",
  },
  {
    id: "persisted_but_must_never_persist",
    when: (s) => s.must_never_persist && (s.durable === true || s.tracked === true),
    severity: "high",
    why: "a secret or live authorization is being stored durably",
  },
  {
    id: "durable_and_ephemeral",
    when: (s) => s.durable && s.ephemeral,
    severity: "medium",
    why: "declared both to survive and to vanish; one of the two is wrong",
  },
];

/**
 * @param {Array} items  each { id, path, provenance: "derived"|"declared", ...properties }
 */
export function auditState(items = []) {
  const findings = [];
  for (const s of items) {
    for (const c of CONTRADICTIONS) {
      let hit = false;
      try { hit = c.when(s) === true; } catch { hit = false; }
      if (!hit) continue;
      findings.push({
        contradiction: c.id, severity: c.severity, why: c.why,
        item: s.id, path: s.path ?? null, provenance: s.provenance ?? "declared",
        properties: PROPERTIES.filter((p) => s[p] === true),
        // Provenance changes what a finding MEANS: a derived contradiction is a
        // fact about the system; a declared one may be a wrong label.
        interpretation: (s.provenance === "derived")
          ? "DERIVED — the contradiction is a property of the code, not of someone's description of it"
          : "DECLARED — this may be a mislabelled classification rather than a real defect; verify before acting",
      });
    }
  }
  const byProv = { derived: 0, declared: 0 };
  for (const s of items) byProv[s.provenance === "derived" ? "derived" : "declared"]++;
  return {
    artifact: "state_classification_audit",
    items: items.length,
    provenance: byProv,
    findings_count: findings.length,
    findings,
    note:
      "Only classified items are audited. State nobody classified is invisible here, and that omission is not " +
      "reported — no registry can enumerate what it was never told about.",
  };
}
