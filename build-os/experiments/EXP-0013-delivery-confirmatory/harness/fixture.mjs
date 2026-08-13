#!/usr/bin/env node
// EXP-0013 Stage-A DISPOSABLE FIXTURE — the one authorized UCDL wiring.
//
// Call path (the seam, exactly): real planner plan() -> plan.cognition_requirement
// -> validateDescriptor() -> UCDL deliver() TWICE with IDENTICAL store, query
// (descriptor.objective_terms), policy, and budget — renderer varies ONLY:
//   lean_rules  -> UCDL renderer 'context'
//   lean_skills -> UCDL renderer 'skill'
// Selection identity (selected_ids, payload digest) is computed and receipted
// BEFORE rendering matters; renderers cannot re-select (UCDL contract, already
// invariant-tested). Admissibility runs BEFORE any worker invocation and any
// failure is a TYPED invalidation, never a silent skip. Receipts are
// hash-chained and immutable. This module never authorizes actions, never
// touches production paths, and never launches paid workers.

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { deliver } from "../../../delivery/ucdl.mjs";

const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");
export const HARNESS_VERSION = "exp0013-harness@1";
export const SELECTOR_POLICY = "insight-first@1";
export const RENDERER_MAP = { lean_rules: "context", lean_skills: "skill" };

// Typed invalidation reasons — every prevented failure mode has a name.
export const INVALID = {
  DESCRIPTOR_INVALID: "INVALID_DESCRIPTOR",
  DESCRIPTOR_NOT_CONTEXT: "INVALID_DESCRIPTOR_STATE_NOT_CONTEXT_REQUIRED",
  IDENTITY_MISMATCH: "INVALID_IDENTITY_MISMATCH",
  STORE_DIGEST_MISMATCH: "INVALID_STORE_DIGEST_MISMATCH",
  POLICY_MISMATCH: "INVALID_POLICY_VERSION_MISMATCH",
  BUDGET_MISMATCH: "INVALID_BUDGET_MISMATCH",
  SELECTION_MISMATCH: "INVALID_SELECTED_EVIDENCE_MISMATCH",
  EMPTY_TREATMENT: "INVALID_UNINTENDED_EMPTY_TREATMENT",
  EMPTY_RENDER: "INVALID_EMPTY_RENDERED_OUTPUT",
  TRUNCATION_DIVERGENCE: "INVALID_TRUNCATION_IDENTITY_DIVERGENCE",
  RECEIPT_INCOMPLETE: "INVALID_RECEIPT_INCOMPLETE",
  PROMPT_BYTES_CHANGED: "INVALID_PROMPT_BYTES_CHANGED",
  ISOLATION_COLLISION: "INVALID_ISOLATION_PATH_COLLISION",
  STUDY_LOCK: "INVALID_STUDY_LOCK_CONFLICT",
  H0_UNACCEPTABLE: "INVALID_H0_CALIBRATION",
  NO_RESULT_EVENT: "INVALID_MISSING_PROVIDER_RESULT",
  ARG_LENGTH: "INVALID_PROMPT_VIA_ARGV_FORBIDDEN",
  STALE_WORKTREE: "INVALID_WORKTREE_IDENTITY",
  POST_FREEZE_CHANGE: "INVALID_HARNESS_CHANGED_AFTER_FREEZE",
};

export function validateDescriptor(cr) {
  const need = ["action", "state", "objective_terms", "authority_summary", "verification", "correlation"];
  for (const k of need) if (cr?.[k] === undefined) return { ok: false, reason: `${INVALID.DESCRIPTOR_INVALID}: missing ${k}` };
  if (cr.state !== "CONTEXT_REQUIRED") return { ok: false, reason: INVALID.DESCRIPTOR_NOT_CONTEXT };
  if (!Array.isArray(cr.objective_terms) || cr.objective_terms.length === 0)
    return { ok: false, reason: `${INVALID.DESCRIPTOR_INVALID}: objective_terms empty — the planner seam carried no query` };
  return { ok: true };
}

/**
 * Build BOTH treatments for one matched pair from one descriptor + one store.
 * expectEvidence=true for positions where accumulated knowledge must exist
 * (position >= 2); an empty selection there is INVALID before any spend.
 * Explicit predeclared NO_CONTEXT is not a Stage-A treatment (both arms
 * receive evidence by design).
 */
export function buildTreatments({ ids, descriptor, storeText, capBytes, expectEvidence }) {
  const v = validateDescriptor(descriptor);
  if (!v.ok) return { admissible: false, reason: v.reason };
  const storeDigest = sha(storeText);
  const query = { codes: descriptor.objective_terms };
  const arms = {};
  for (const arm of ["lean_rules", "lean_skills"]) {
    const r = deliver({
      storeText, query, policyName: SELECTOR_POLICY, capBytes,
      renderer: RENDERER_MAP[arm],
      rendererMeta: arm === "lean_skills" ? { name: `repair-${ids.sequence.toLowerCase()}` } : {},
    });
    if (r.invalid_empty && expectEvidence) return { admissible: false, reason: INVALID.EMPTY_TREATMENT, arm };
    if (!r.ok && !r.invalid_empty) return { admissible: false, reason: `${INVALID.RECEIPT_INCOMPLETE}: deliver failed`, arm };
    arms[arm] = r;
  }
  // PAIR-EQUIVALENCE: must-be-identical fields vs permitted renderer-only diffs.
  const a = arms.lean_rules.receipt, b = arms.lean_skills.receipt;
  const mustEqual = {
    selected_ids: [JSON.stringify(a.selected_ids), JSON.stringify(b.selected_ids)],
    payload_bytes: [a.delivered_bytes, b.delivered_bytes],
    policy: [a.policy.name, b.policy.name],
    cap: [a.policy.cap_bytes, b.policy.cap_bytes],
    truncated: [a.truncated, b.truncated],
    candidates: [a.candidates, b.candidates],
  };
  for (const [k, [x, y]] of Object.entries(mustEqual))
    if (String(x) !== String(y)) return { admissible: false, reason: `${INVALID.SELECTION_MISMATCH}: ${k} differs (${x} vs ${y})` };
  if (expectEvidence) for (const arm of ["lean_rules", "lean_skills"])
    if (!arms[arm].output || arms[arm].receipt.empty) return { admissible: false, reason: INVALID.EMPTY_RENDER, arm };
  const receipts = {};
  for (const arm of ["lean_rules", "lean_skills"]) {
    const r = arms[arm].receipt;
    const totalBytes = Buffer.byteLength(arms[arm].output, "utf8");
    receipts[arm] = {
      artifact: "exp0013_delivery_receipt",
      harness_version: HARNESS_VERSION,
      ...ids, arm,
      plan_id: descriptor.correlation?.run_id ?? null,
      cognition_descriptor_digest: sha(JSON.stringify(descriptor)),
      store_digest: storeDigest,
      candidates_considered: r.considered.map((c) => c.id),
      selected_ids: r.selected_ids,
      rejected: r.considered.filter((c) => c.decision === "rejected").map((c) => ({ id: c.id, reason: c.reason })),
      selection_reasons: r.considered.filter((c) => c.decision === "selected").map((c) => ({ id: c.id, reason: c.reason, bytes: c.bytes })),
      selector_policy: r.policy.name,
      renderer: arm, renderer_version: `${RENDERER_MAP[arm]}@ucdl-${r.ucdl_version}`,
      evidence_payload_bytes: r.delivered_bytes,
      evidence_payload_tokens_est: r.est_tokens,
      renderer_overhead_bytes: totalBytes - r.delivered_bytes,
      total_installed_bytes: totalBytes,
      total_installed_tokens_est: Math.ceil(totalBytes / 4),
      budget: { cap_bytes: r.policy.cap_bytes, utilization: +(r.delivered_bytes / r.policy.cap_bytes).toFixed(3) },
      truncated: r.truncated,
      truncation_rule: "insight atoms first by score, exhibits into remaining room; identical across renderers by construction (selection precedes rendering)",
      no_context: r.no_context ?? null,
      installed_artifact_digest: r.output_sha256,
      access_observed: "NOT_OBSERVABLE at delivery time — worker access is a post-run stream-parse question",
    };
  }
  return { admissible: true, arms: { lean_rules: { output: arms.lean_rules.output, receipt: receipts.lean_rules }, lean_skills: { output: arms.lean_skills.output, receipt: receipts.lean_skills } } };
}

/** PRE-SPEND admissibility over a prepared cell (worker never invoked on failure). */
export function admitCell(cell) {
  const c = cell || {};
  const checks = [
    [c.receipt && c.receipt.artifact === "exp0013_delivery_receipt", INVALID.RECEIPT_INCOMPLETE],
    [c.receipt?.plan_id, `${INVALID.DESCRIPTOR_INVALID}: no plan correlation`],
    [c.ids_consistent !== false, INVALID.IDENTITY_MISMATCH],
    [c.store_digest_matches_pair !== false, INVALID.STORE_DIGEST_MISMATCH],
    [c.prompt_digest_frozen !== false, INVALID.PROMPT_BYTES_CHANGED],
    [c.isolation_unique !== false, INVALID.ISOLATION_COLLISION],
    [c.study_lock_free !== false, INVALID.STUDY_LOCK],
    [c.h0_calibrated !== false, INVALID.H0_UNACCEPTABLE],
    [c.prompt_via_stdin !== false, INVALID.ARG_LENGTH],
    [c.worktree_identity_ok !== false, INVALID.STALE_WORKTREE],
    [c.freeze_intact !== false, INVALID.POST_FREEZE_CHANGE],
  ];
  for (const [ok, reason] of checks) if (!ok) return { admitted: false, reason };
  return { admitted: true };
}

/** Hash-chained receipt stream (same pattern as deltas/plans). */
export function appendReceipt(resultsDir, obj) {
  const f = path.join(resultsDir, "delivery-receipts.jsonl");
  fs.mkdirSync(resultsDir, { recursive: true });
  const prev = (() => { try { const l = fs.readFileSync(f, "utf8").trim().split("\n"); return sha(l[l.length - 1]); } catch { return "genesis"; } })();
  fs.appendFileSync(f, JSON.stringify({ ...obj, prev_sha: prev }) + "\n");
  return f;
}
export function verifyReceipts(resultsDir) {
  const f = path.join(resultsDir, "delivery-receipts.jsonl");
  if (!fs.existsSync(f)) return { ok: true, n: 0 };
  let prev = "genesis", n = 0;
  for (const raw of fs.readFileSync(f, "utf8").split("\n").filter(Boolean)) {
    let d; try { d = JSON.parse(raw); } catch { return { ok: false, reason: `torn line after ${n}` }; }
    if (d.prev_sha !== prev) return { ok: false, reason: `chain broken at ${n + 1}` };
    prev = sha(raw); n++;
  }
  return { ok: true, n };
}
