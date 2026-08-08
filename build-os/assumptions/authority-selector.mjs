#!/usr/bin/env node
// RUNTIME-ACTIVE authority selection.
//
// self-audit v0 could say "this authority path is incompatible with this host".
// That is analysis. This module makes the same model OPERATIONAL: before a
// mutation is attempted, choose an authority path that is actually viable on
// this host — so the worker never discovers the incompatibility by attempting
// the wrong path first.
//
// WHAT THIS IS NOT. It does not bypass host authority and it does not
// manufacture permission the host has denied. It chooses among LEGITIMATE
// Gravito paths. If the host denies the requested mutation itself, the correct
// answer is refusal, and refusal is NOT a Gravito defect — conflating those two
// is how a correct host restriction gets recorded as a product failure.

import { deriveAuthorityPaths, loadGate } from "./derive-authority-paths.mjs";

// The privilege lattice. Ordering is the load-bearing part: EXP-0005's defect
// was choosing an authority path HIGHER in this order than the mutation it
// authorized. Lower rank = less privilege = preferred.
export const PRIVILEGE = { Write: 1, Edit: 1, NotebookEdit: 1, Bash: 3 };

// Host permission values, worst to best. `allowed` is the only one a runtime
// selector may rely on: `approval_required` is not a "yes", it is a "maybe,
// and not at all without an approver".
const usable = (host, cls) => {
  const v = host.permits?.[cls];
  if (v === "allowed") return { ok: true, why: "allowed" };
  if (v === "approval_required") return { ok: host.approver_present === true, why: host.approver_present ? "approval available" : "approval required, no approver present" };
  return { ok: false, why: v ?? "unknown" };
};

/**
 * Choose an authority path for a requested mutation.
 *
 * @param {object} req
 *   gateSource | gatePath  — where the authority paths are DERIVED from
 *   host                   — a host permission profile
 *   mutation_class         — the tool class the work actually needs (e.g. "Edit")
 */
export function selectAuthorityPath(req) {
  const src = req.gateSource ?? loadGate(req.gatePath);
  const paths = req.paths ?? deriveAuthorityPaths(src);
  const host = req.host;
  const want = req.mutation_class || "Edit";

  const evidence = [];
  const record = (m) => { evidence.push(m); return m; };

  // (1) host-permitted operation classes
  const hostClasses = Object.fromEntries(Object.keys(PRIVILEGE).map((c) => [c, usable(host, c)]));
  record(`host ${host.id}: ${Object.entries(hostClasses).map(([c, r]) => `${c}=${r.ok ? "usable" : "unusable(" + r.why + ")"}`).join(", ")}`);

  // The requested mutation must itself be permitted. If it is not, no authority
  // is owed and refusing is correct behaviour, not a defect.
  const wantUsable = hostClasses[want];
  if (!wantUsable?.ok) {
    return {
      artifact: "authority_path_selection",
      decision: "refuse_host_denies_mutation",
      selected: null,
      mutation_class: want,
      reason: `the host does not permit ${want} (${wantUsable?.why}). No Gravito authority path can or should change that.`,
      is_gravito_defect: false,
      evidence: [...evidence, record(`requested mutation class ${want} is not usable on this host`)],
    };
  }

  // (2) authority paths capable of authorizing the requested mutation
  const candidates = paths.map((p) => ({ ...p, privilege: PRIVILEGE[p.tool_class] ?? 99, host: hostClasses[p.tool_class] }));
  record(`derived authority paths: ${candidates.map((c) => `${c.id}(${c.tool_class}, privilege ${c.privilege})`).join(", ") || "(none)"}`);

  const viable = candidates.filter((c) => c.host?.ok);
  const nonViable = candidates.filter((c) => !c.host?.ok);
  for (const c of nonViable) record(`path '${c.id}' NOT viable: needs ${c.tool_class} — ${c.host?.why}`);

  // (6) fail closed
  if (!viable.length) {
    return {
      artifact: "authority_path_selection",
      decision: "fail_closed",
      selected: null,
      mutation_class: want,
      reason: candidates.length
        ? `the host permits ${want}, but every derived authority path requires a class it does not: ` +
          `${nonViable.map((c) => `${c.id} needs ${c.tool_class}`).join("; ")}. This is an AUTHORITY_PATH_MISMATCH — ` +
          `a worker able to do the work cannot become allowed to do it.`
        : "no authority path could be derived from the gate at all",
      is_gravito_defect: candidates.length > 0,
      evidence,
    };
  }

  // (3)(4) least privilege wins; ties break on a stable rule, not on order of
  // discovery, so the same host and gate always yield the same choice.
  viable.sort((a, b) => a.privilege - b.privilege || (a.id < b.id ? -1 : 1));
  const chosen = viable[0];
  const rejectedForPrivilege = viable.slice(1).filter((c) => c.privilege > chosen.privilege);
  for (const r of rejectedForPrivilege) record(`path '${r.id}' rejected: viable, but privilege ${r.privilege} exceeds the ${chosen.privilege} required by '${chosen.id}'`);

  // (5) record the selection and its evidence
  return {
    artifact: "authority_path_selection",
    decision: "selected",
    selected: chosen.id,
    selected_tool_class: chosen.tool_class,
    selected_how: chosen.how,
    selected_target: chosen.recognises,
    mutation_class: want,
    privilege_rank: chosen.privilege,
    rejected_higher_privilege: rejectedForPrivilege.map((r) => r.id),
    rejected_non_viable: nonViable.map((c) => c.id),
    reason: `least-privileged viable path for ${want} on ${host.id}`,
    is_gravito_defect: false,
    evidence,
  };
}
