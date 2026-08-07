// Item 5 — three-role blinding, made STRUCTURAL.
//
// EXP-0004's adjudicator blinding held and its analyst blinding did not, because
// one agent held both views. The blinding README named the weakness precisely:
//
//   "Unit ids appear in both views. That is deliberate: it is how frozen
//    acceptance reaches the economics. It does mean anyone holding BOTH views
//    can join them. Neither blinded role holds both."
//
// "Neither role holds both" was an instruction. Instructions are not structure.
//
// THE FIX: the two blinded views no longer share a key. The adjudicator sees
// `adj-<h>` ids and the analyst sees `ana-<h>` ids, derived from the SAME unit
// under DIFFERENT salt domains. Holding both views therefore yields no way to
// align a row in one with a row in the other — the join requires the sealed
// mapping, which only the reveal step holds.
//
// Acceptance still reaches the economics, but it travels through a sealed
// transfer rather than through a shared identifier.

import crypto from "node:crypto";

export const ROLES = ["executor", "adjudicator", "analyst"];

export const ROLE_FIELDS = {
  adjudicator: ["adj_id", "task_id", "objective", "acceptance_criteria", "product_diff_ref", "tests_run", "tests_passed", "verification_evidence"],
  analyst:     ["ana_id", "task_id", "acceptance_result", "uncached_tokens", "total_tokens", "total_elapsed_s",
                "subagent_invocations", "rework_rounds", "human_interventions", "regressions", "api_equivalent_cost_usd"],
};

export const ROLE_FORBIDDEN = {
  adjudicator: ["arm", "condition", "uncached_tokens", "total_tokens", "total_elapsed_s", "starting_context_bytes",
                "expansion_bytes", "subagent_invocations", "governance_diff", "ana_id"],
  analyst:     ["arm", "condition", "product_diff_ref", "governance_diff", "adj_id"],
};

const h = (salt, domain, unit) =>
  crypto.createHash("sha256").update(`${salt}|${domain}|${unit}`).digest("hex").slice(0, 16);

/** Two ids per unit, in separate salt domains. Neither is derivable from the other without the salt. */
export function deriveIds(salt, taskId, arm) {
  const unit = `${taskId}|${arm}`;
  return { adj_id: `adj-${h(salt, "adjudicator", unit)}`, ana_id: `ana-${h(salt, "analyst", unit)}` };
}

function project(role, row) {
  const allow = ROLE_FIELDS[role];
  if (!allow) throw new Error(`no field set for role '${role}'`);
  const out = {};
  for (const k of allow) if (row[k] !== undefined) out[k] = row[k];
  return out;
}

export function buildView(role, rows) {
  if (!ROLE_FIELDS[role]) throw new Error(`'${role}' is not a blinded role`);
  const units = rows.map((r) => project(role, r));
  const leaked = [];
  for (const u of units) for (const f of ROLE_FORBIDDEN[role]) if (u[f] !== undefined) leaked.push(f);
  if (leaked.length) throw new Error(`view for '${role}' leaks forbidden field(s): ${[...new Set(leaked)].join(", ")}`);
  return {
    view: role, n_units: units.length, units,
    key_domain: role === "adjudicator" ? "adj_id" : "ana_id",
    blinding_note:
      "This view's unit ids are derived in a salt domain private to this role. They cannot be aligned with " +
      "any other role's ids without the sealed mapping, so holding two views does not permit a join.",
  };
}

/**
 * The adversarial test EXP-0004 would have failed. Given BOTH blinded views,
 * try to recover condition identity by joining them. Success here is a defect.
 */
export function attemptJoin(adjView, anaView) {
  const adjKeys = new Set(adjView.units.map((u) => u.adj_id));
  const anaKeys = new Set(anaView.units.map((u) => u.ana_id));
  const shared = [...adjKeys].filter((k) => anaKeys.has(k));

  // Falling back to task_id is the obvious next attempt: it appears in both.
  // It cannot disambiguate, because each task contributes one unit per ARM and
  // the arm label is absent from both views — a task id selects a PAIR, never a
  // side of it.
  const byTaskAdj = {}, byTaskAna = {};
  for (const u of adjView.units) (byTaskAdj[u.task_id] ??= []).push(u.adj_id);
  for (const u of anaView.units) (byTaskAna[u.task_id] ??= []).push(u.ana_id);
  const ambiguous = Object.keys(byTaskAdj).filter((t) => (byTaskAdj[t].length > 1 || (byTaskAna[t] || []).length > 1));

  const recovered = shared.length > 0;
  return {
    joined_on_shared_key: recovered,
    shared_keys: shared,
    task_id_join_ambiguous_for: ambiguous,
    condition_identity_recovered: recovered,
    verdict: recovered ? "DEFECT — the views share a key and can be joined" : "blind holds — no shared key exists",
    note: recovered
      ? "This is the EXP-0004 failure reproduced. The views must not share an identifier."
      : "task_id remains in both views by necessity, but it selects a matched PAIR rather than a side of one, " +
        "so it cannot recover which unit came from which condition.",
  };
}

/** No agent may hold two roles. Holding artifacts keyed in two domains is the detectable form of that. */
export function assertSingleRole(heldArtifacts = []) {
  const domains = new Set();
  for (const a of heldArtifacts) {
    if (a?.view === "adjudicator" || a?.adj_id) domains.add("adjudicator");
    if (a?.view === "analyst" || a?.ana_id) domains.add("analyst");
    if (a?.view === "executor" || a?.arm || a?.condition) domains.add("executor");
  }
  return {
    domains: [...domains].sort(),
    single_role: domains.size <= 1,
    refusal: domains.size > 1
      ? `an agent holding ${[...domains].sort().join(" + ")} artifacts occupies more than one blinded role`
      : null,
  };
}
