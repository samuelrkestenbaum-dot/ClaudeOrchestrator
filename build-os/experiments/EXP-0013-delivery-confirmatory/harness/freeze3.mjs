#!/usr/bin/env node
// FREEZE-MANIFEST v3 — the post-audit AMENDMENT freeze.
//
// Closes three audit findings against freeze v2 itself:
//   1. ADDED files in frozen directories were undetectable (v2 hashed only a
//      list) — v3 records a full DIRECTORY INVENTORY of harness/ and corpus/
//      and refuses on any unexpected or missing entry.
//   2. PERMISSION changes were undetectable — v3 records each artifact's
//      mode bits and refuses on drift.
//   3. Runtime dependencies the controller executes (bin/gravito,
//      reachability.mjs, h0-check.sh, the goal template) were never frozen —
//      v3 freezes them.
// History: v1 stays verifiable and byte-identical (delegated). v2's manifest
// FILE is frozen here as immutable history, but freeze2's own verification
// is intentionally superseded — controller/seal-orders changed under the
// disclosed AMENDMENT-V3.md, so freeze2 verify SHOULD now refuse; that
// refusal is the amendment being visible, not an error.
import fs from "node:fs"; import path from "node:path"; import crypto from "node:crypto";
import { spawnSync } from "node:child_process";
const sha = (b) => crypto.createHash("sha256").update(b).digest("hex");
const HERE = path.dirname(new URL(import.meta.url).pathname);
const ROOT = path.resolve(HERE, "..");
const ARTIFACTS = [
  "FREEZE-MANIFEST.json", "FREEZE-MANIFEST-v2.json",
  "FAILURE-MODES-ADDENDUM.md", "AMENDMENT-V3.md",
  "PREREGISTRATION-STAGE-A.md", "FAILURE-MODES.md", "STAGED-DESIGN.md",
  "corpus/sequences.json", "corpus/baseline-tsc.txt",
  "corpus/ARM-ORDER-COMMITMENT.json", "corpus/RERUN-ORDER-COMMITMENT.json",
  "harness/fixture.mjs", "harness/scheduler.mjs", "harness/views.mjs", "harness/fake-worker.sh", "harness/freeze.mjs",
  "harness/oracle.mjs", "harness/telemetry.mjs", "harness/model-config.json", "harness/seal-orders.mjs",
  "harness/controller.mjs", "harness/analysis.mjs", "harness/freeze2.mjs", "harness/freeze3.mjs",
  "harness/supervise.mjs", "harness/transport-rehearsal.mjs", "harness/transport-measured.mjs",
  "harness/spend-ledger.mjs", "harness/distill.mjs", "harness/mapping-escrow.mjs", "harness/leakcheck2.mjs",
  "../../delivery/ucdl.mjs", "../../tools/planner.mjs",
  "../../tools/reachability.mjs", "../../tools/h0-check.sh",
  "../../../bin/gravito", "../../../templates/gravito.goal.example",
  "../../../tests/exp0013_fixture_tests.sh", "../../../tests/exp0013_readiness_tests.sh", "../../../tests/exp0013_redteam_tests.sh",
];
const INVENTORY_DIRS = ["harness", "corpus"];
const mode = process.argv[2];
const mf = path.join(ROOT, "FREEZE-MANIFEST-v3.json");
const v1ok = () => spawnSync("node", [path.join(HERE, "freeze.mjs"), "verify"], { encoding: "utf8" });
const snapshot = () => {
  const files = {};
  for (const a of ARTIFACTS) {
    const p = path.join(ROOT, a);
    files[a] = { sha256: sha(fs.readFileSync(p)), mode: (fs.statSync(p).mode & 0o777).toString(8) };
  }
  const inventory = {};
  for (const d of INVENTORY_DIRS) inventory[d] = fs.readdirSync(path.join(ROOT, d)).sort();
  return { files, inventory };
};
if (mode === "create") {
  const v1 = v1ok();
  if (v1.status !== 0) { console.log("REFUSED: v1 freeze does not verify:", (v1.stdout || v1.stderr).trim()); process.exit(1); }
  const src = spawnSync("git", ["-C", ROOT, "rev-parse", "HEAD"], { encoding: "utf8" }).stdout.trim();
  const s = snapshot();
  fs.writeFileSync(mf, JSON.stringify({
    artifact: "exp0013_freeze_manifest_v3",
    predecessors: "FREEZE-MANIFEST.json (still verified live) and FREEZE-MANIFEST-v2.json (immutable history; its own verify is superseded per AMENDMENT-V3.md)",
    source_commit_at_freeze: src, ...s,
    unfrozen: [
      "sealed order/rerun/blinding stores + salts (outside repo by design; commitments ARE frozen)",
      "mapping escrow ciphertext (created only after the owner supplies a passphrase; prerequisite in the spend template)",
      "the p1-distilled live stores (produced at spend time via the frozen distill.mjs, digest-pinned before p2)",
      "EXECUTION-READINESS.md and PRE-SPEND-AUDIT.md (describe freezes; freezing them would be circular)",
      "rehearsal-evidence/ (run products, not contract)",
    ],
  }, null, 2) + "\n");
  console.log("v3 frozen:", Object.keys(s.files).length, "artifacts + inventory of", INVENTORY_DIRS.join(","), "@", src.slice(0, 12));
} else if (mode === "verify") {
  const v1 = v1ok();
  if (v1.status !== 0) { console.log("INVALID_HARNESS_CHANGED_AFTER_FREEZE: v1 set:", (v1.stdout || v1.stderr).trim()); process.exit(1); }
  const m = JSON.parse(fs.readFileSync(mf, "utf8"));
  for (const [rel, rec] of Object.entries(m.files)) {
    const p = path.join(ROOT, rel);
    if (!fs.existsSync(p)) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: MISSING_FILE ${rel}`); process.exit(1); }
    if (sha(fs.readFileSync(p)) !== rec.sha256) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: ${rel}`); process.exit(1); }
    const mode8 = (fs.statSync(p).mode & 0o777).toString(8);
    if (mode8 !== rec.mode) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: MODE_DRIFT ${rel} ${rec.mode}->${mode8}`); process.exit(1); }
  }
  for (const d of Object.keys(m.inventory)) {
    const now = fs.readdirSync(path.join(ROOT, d)).sort();
    const want = m.inventory[d];
    for (const f of now) if (!want.includes(f)) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: UNEXPECTED_FILE ${d}/${f}`); process.exit(1); }
    for (const f of want) if (!now.includes(f)) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: MISSING_FILE ${d}/${f}`); process.exit(1); }
  }
  console.log("v3 freeze intact:", Object.keys(m.files).length, "artifacts + inventory (v1 re-verified)");
} else { console.log("usage: freeze3.mjs create|verify"); process.exit(1); }
