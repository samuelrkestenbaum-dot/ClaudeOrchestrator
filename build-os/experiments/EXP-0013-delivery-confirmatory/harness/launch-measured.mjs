#!/usr/bin/env node
// THE measured Stage-A entry point (AMENDMENT v6 — surgical-review finding
// F1: "run exactly as frozen" was unsatisfiable because the composition of
// authorization + real transport + real oracle existed nowhere in frozen
// bytes; a spend-time run would have required ad-hoc unfrozen glue, the
// exact defect class every prior audit hunted).
//
// Modes:
//   print-auth-template — emits the exact spend-authorization JSON skeleton
//     bound to the CURRENT frozen state: freeze digest, source commit, both
//     sealed commitments, the canonical cell list and the canonical prompt
//     digests computed from the frozen corpus via the frozen workerPrompt.
//     The owner turns it into real authority ONLY by setting
//     spend_authorized=true, an expiry, and the digest of their authorizing
//     message text. Nothing here creates authority.
//   run <study-dir> <iso-root> <spend-auth.json> — verifies freeze + both
//     sealed commitments, validates the authorization, acquires the SOLE
//     provider transport, and drives runMeasured with the registry-gated
//     real oracle runner. Every per-call gate (cell/digest allowlists,
//     expiry, call ceiling, budget reservation) applies as already tested.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { spawnSync } from "node:child_process";
import { runMeasured, workerPrompt, CONFIG, CORPUS } from "./controller.mjs";
import { acquireProviderTransport } from "./provider-call-site.mjs";
import * as sealOrders from "./seal-orders.mjs";
import { makeOracleRunner } from "./oracle-runner.mjs";

const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");
const HERE = path.dirname(new URL(import.meta.url).pathname);
const ROOT = path.resolve(HERE, "..");

function binding() {
  const mf = path.join(ROOT, "FREEZE-MANIFEST-v6.json");
  const freezeDigest = fs.existsSync(mf) ? sha(fs.readFileSync(mf)) : null;
  const sourceCommit = spawnSync("git", ["-C", ROOT, "rev-parse", "HEAD"], { encoding: "utf8" }).stdout.trim();
  const mapping = JSON.parse(fs.readFileSync(path.join(ROOT, "corpus", "ARM-ORDER-COMMITMENT.json"), "utf8")).commitment;
  const rerun = JSON.parse(fs.readFileSync(path.join(ROOT, "corpus", "RERUN-ORDER-COMMITMENT.json"), "utf8")).commitment;
  return { freezeDigest, sourceCommit, mappingCommitment: mapping, rerunCommitment: rerun, now: Date.now() };
}

function canonicalAllowlists() {
  const cells = [], digests = new Set();
  for (const seq of ["S1", "S2"]) {
    const tasks = CORPUS.sequences[seq];
    cells.push(`${tasks[0].task_id}.seed`);
    digests.add(sha(workerPrompt(tasks[0])));
    for (const pos of [2, 3]) {
      const t = tasks[pos - 1];
      for (const arm of ["lean_rules", "lean_skills"]) cells.push(`${t.task_id}.${arm}`);
      digests.add(sha(workerPrompt(t)));
    }
  }
  return { cells, digests: [...digests] };
}

async function main() {
  const mode = process.argv[2];
  if (mode === "print-auth-template") {
    const b = binding();
    const a = canonicalAllowlists();
    console.log(JSON.stringify({
      artifact: "exp0013_spend_authorization",
      spend_authorized: false, // OWNER sets true in their own copy — this file is a TEMPLATE, not authority
      experiment: "EXP-0013", stage: "A",
      freeze_digest: b.freezeDigest, source_commit: b.sourceCommit,
      mapping_commitment: b.mappingCommitment, rerun_commitment: b.rerunCommitment,
      provider: "anthropic-claude-cli", model: CONFIG.model.requested,
      allowed_model_ids: CONFIG.model.allowed_provider_model_ids,
      max_calls: 16, max_spend_usd: CONFIG.spend.proposed_ceiling_usd,
      expires_at: "OWNER_SETS_RFC3339", topology: "serial",
      allowed_cells: a.cells, allowed_request_digests: a.digests,
      rerun_rules: "1 seed rerun/seq; 1 whole-pair rerun/pair from the pre-sealed contingency order; 2 pair reruns total",
      stage_b_excluded: true,
      owner_text_digest: "OWNER_SETS_sha256_of_their_authorizing_message",
      ledger_dir: "OWNER_SETS_study_dir",
    }, null, 2));
    return;
  }
  if (mode !== "run") { console.log("usage: launch-measured.mjs print-auth-template | run <study-dir> <iso-root> <spend-auth.json>"); process.exit(1); }
  const [studyDir, isoRoot, authPath] = process.argv.slice(3);
  if (!studyDir || !isoRoot || !authPath) { console.log("usage: launch-measured.mjs run <study-dir> <iso-root> <spend-auth.json>"); process.exit(1); }
  const fz = spawnSync("node", [path.join(HERE, "freeze6.mjs"), "verify"], { encoding: "utf8" });
  if (fz.status !== 0) { console.log(JSON.stringify({ ok: false, reason: "INVALID_HARNESS_CHANGED_AFTER_FREEZE", detail: (fz.stdout || "").trim() })); process.exit(1); }
  const so = sealOrders.verify(); const sr = sealOrders.verifyRerun();
  if (!so.ok || !sr.ok) { console.log(JSON.stringify({ ok: false, reason: so.reason ?? sr.reason })); process.exit(1); }
  let auth; try { auth = JSON.parse(fs.readFileSync(authPath, "utf8")); } catch { console.log(JSON.stringify({ ok: false, reason: "SPEND_AUTH_MALFORMED" })); process.exit(1); }
  const acquired = acquireProviderTransport({ auth, config: CONFIG, binding: binding() });
  if (acquired.refused) { console.log(JSON.stringify({ ok: false, reason: acquired.refused })); process.exit(1); }
  const oracle = makeOracleRunner({ corpusDir: path.join(ROOT, "corpus") });
  const r = await runMeasured({
    studyDir, isoRoot, transport: acquired.transport, spendAuthPath: authPath,
    oracleFor: ({ seq, cell, worktree, kind }) => oracle({ worktree, kind, seq, cell }),
  });
  fs.writeFileSync(path.join(studyDir, "measured-cells.json"), JSON.stringify(r, null, 2) + "\n");
  console.log(JSON.stringify({ ok: r.ok, reason: r.reason ?? null, calls: r.calls ?? r.ledger?.calls ?? null }));
  process.exit(r.ok ? 0 : 1);
}
main();
