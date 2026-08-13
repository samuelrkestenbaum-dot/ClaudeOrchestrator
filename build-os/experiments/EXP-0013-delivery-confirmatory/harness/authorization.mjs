#!/usr/bin/env node
// SPEND-AUTHORIZATION SCHEMA (AMENDMENT v4). Validation only — this module
// creates NO real authority. Real authority exists only as an owner-written
// file whose text the owner supplied; tests use makeSyntheticAuthorization,
// which is indelibly marked synthetic and can never validate as real.
//
// The schema binds every call to: this experiment/stage, the exact freeze
// and source commit, both sealed commitments, the exact provider/model
// config, hard call/spend maxima, an expiry, serial topology, an explicit
// allowlist of cell ids AND request (prompt) digests — so the authorization
// CANNOT authorize arbitrary prompts — plus rerun rules, an explicit
// Stage-B exclusion, the digest of the owner's authorizing text, and the
// ledger directory the accounting lives in. Frozen (Object.freeze) after
// validation; per-call checks live in provider-call-site.mjs.
import crypto from "node:crypto";
const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");

export const REQUIRED = [
  "artifact", "experiment", "stage", "freeze_digest", "source_commit",
  "mapping_commitment", "rerun_commitment", "provider", "model",
  "allowed_model_ids", "max_calls", "max_spend_usd", "expires_at",
  "topology", "allowed_cells", "allowed_request_digests", "rerun_rules",
  "stage_b_excluded", "owner_text_digest", "ledger_dir",
];

export function validateAuthorization(auth, { freezeDigest, sourceCommit, mappingCommitment, rerunCommitment, now }) {
  const fail = (reason) => ({ ok: false, reason });
  if (!auth || typeof auth !== "object") return fail("AUTH_MALFORMED");
  for (const k of REQUIRED) if (auth[k] === undefined) return fail(`AUTH_MISSING_FIELD:${k}`);
  if (auth.artifact !== "exp0013_spend_authorization") return fail("AUTH_WRONG_ARTIFACT");
  if (auth.experiment !== "EXP-0013" || auth.stage !== "A") return fail("AUTH_WRONG_SCOPE");
  if (auth.freeze_digest !== freezeDigest) return fail("AUTH_FREEZE_MISMATCH");
  if (auth.source_commit !== sourceCommit) return fail("AUTH_SOURCE_MISMATCH");
  if (auth.mapping_commitment !== mappingCommitment) return fail("AUTH_MAPPING_COMMITMENT_MISMATCH");
  if (auth.rerun_commitment !== rerunCommitment) return fail("AUTH_RERUN_COMMITMENT_MISMATCH");
  if (auth.provider !== "anthropic-claude-cli") return fail("AUTH_WRONG_PROVIDER");
  if (auth.model !== "claude-opus-5") return fail("AUTH_WRONG_MODEL");
  if (!(auth.max_calls >= 1 && auth.max_calls <= 16)) return fail("AUTH_CALLS_OUT_OF_RANGE");
  if (!(auth.max_spend_usd > 0 && auth.max_spend_usd <= 100)) return fail("AUTH_SPEND_OUT_OF_RANGE");
  if (!(new Date(auth.expires_at).getTime() > now)) return fail("AUTH_EXPIRED");
  if (auth.topology !== "serial") return fail("AUTH_TOPOLOGY_NOT_SERIAL");
  if (!Array.isArray(auth.allowed_cells) || auth.allowed_cells.length === 0) return fail("AUTH_NO_CELL_ALLOWLIST");
  if (!Array.isArray(auth.allowed_request_digests) || auth.allowed_request_digests.length === 0) return fail("AUTH_NO_REQUEST_ALLOWLIST");
  if (auth.stage_b_excluded !== true) return fail("AUTH_STAGE_B_NOT_EXCLUDED");
  if (typeof auth.owner_text_digest !== "string" || auth.owner_text_digest.length !== 64) return fail("AUTH_NO_OWNER_TEXT_DIGEST");
  return { ok: true, auth: Object.freeze({ ...auth }) };
}

/** Per-call admission against a validated authorization. */
export function requestAllowed(auth, { cell, stdinText }) {
  const baseCell = cell.replace(/\.rerun$/, "").replace(/\.seed(\.rerun)?$/, ".seed");
  if (!auth.allowed_cells.includes(baseCell)) return { ok: false, reason: `AUTH_CELL_NOT_LISTED:${cell}` };
  const d = sha(stdinText);
  if (!auth.allowed_request_digests.includes(d)) return { ok: false, reason: "AUTH_REQUEST_DIGEST_NOT_LISTED" };
  return { ok: true };
}

/** SYNTHETIC authority for tests — structurally unable to become real:
 *  synthetic:true is required by the fake-provider path and REFUSED by the
 *  real path, and the owner_text_digest is a fixed impossible marker. */
export function makeSyntheticAuthorization(overrides = {}) {
  return {
    artifact: "exp0013_spend_authorization", synthetic: true,
    experiment: "EXP-0013", stage: "A",
    freeze_digest: "SYNTHETIC", source_commit: "SYNTHETIC",
    mapping_commitment: "SYNTHETIC", rerun_commitment: "SYNTHETIC",
    provider: "anthropic-claude-cli", model: "claude-opus-5",
    allowed_model_ids: ["claude-opus-5", "^claude-opus-5-\\d{8}$"],
    max_calls: 16, max_spend_usd: 100,
    expires_at: "2026-12-31T00:00:00Z", topology: "serial",
    allowed_cells: [], allowed_request_digests: [],
    rerun_rules: "1 seed rerun/seq; 1 pair rerun/pair; 2 pair reruns total; pre-sealed contingency order",
    stage_b_excluded: true,
    owner_text_digest: "0".repeat(64) /* impossible-by-convention marker */,
    ledger_dir: null,
    ...overrides,
  };
}
