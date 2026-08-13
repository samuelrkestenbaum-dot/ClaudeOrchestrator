#!/usr/bin/env node
// FREEZE-MANIFEST v2 — the execution-readiness freeze.
//
// v1 (FREEZE-MANIFEST.json) is IMMUTABLE: v2 never rewrites it. create first
// re-verifies v1 byte-for-byte (delegating to freeze.mjs, itself a v1
// artifact), records the v1 manifest's own sha256, then hashes the full v2
// artifact set: everything v1 froze PLUS the corpus, oracle, telemetry,
// model config, sealed-order commitment, controller, analysis, addendum, and
// the readiness test suite. verify refuses on any change to any of them.
import fs from "node:fs"; import path from "node:path"; import crypto from "node:crypto";
import { spawnSync } from "node:child_process";
const sha = (b) => crypto.createHash("sha256").update(b).digest("hex");
const HERE = path.dirname(new URL(import.meta.url).pathname);
const ROOT = path.resolve(HERE, "..");
const V2_ARTIFACTS = [
  "FREEZE-MANIFEST.json",            // the v1 manifest itself, frozen byte-identical
  "FAILURE-MODES-ADDENDUM.md",
  "corpus/sequences.json", "corpus/baseline-tsc.txt", "corpus/ARM-ORDER-COMMITMENT.json",
  "harness/oracle.mjs", "harness/telemetry.mjs", "harness/model-config.json",
  "harness/seal-orders.mjs", "harness/controller.mjs", "harness/analysis.mjs", "harness/freeze2.mjs",
  "../../../tests/exp0013_readiness_tests.sh",
];
const mode = process.argv[2];
const mf = path.join(ROOT, "FREEZE-MANIFEST-v2.json");
const v1ok = () => spawnSync("node", [path.join(HERE, "freeze.mjs"), "verify"], { encoding: "utf8" });
if (mode === "create") {
  const v1 = v1ok();
  if (v1.status !== 0) { console.log("REFUSED: v1 freeze does not verify:", (v1.stdout || v1.stderr).trim()); process.exit(1); }
  const src = spawnSync("git", ["-C", ROOT, "rev-parse", "HEAD"], { encoding: "utf8" }).stdout.trim();
  const files = {};
  for (const a of V2_ARTIFACTS) files[a] = sha(fs.readFileSync(path.join(ROOT, a)));
  fs.writeFileSync(mf, JSON.stringify({
    artifact: "exp0013_freeze_manifest_v2", predecessor: "FREEZE-MANIFEST.json (immutable; re-verified on every v2 verify)",
    source_commit_at_freeze: src, files,
    unfrozen: [
      "sealed arm orders + salts (outside repo by design; commitment IS frozen)",
      "the p1-distilled evidence stores (produced at spend time, digest-pinned before p2)",
      "EXECUTION-READINESS.md (describes this freeze; freezing it would be circular)",
    ],
  }, null, 2) + "\n");
  console.log("v2 frozen:", Object.keys(files).length, "artifacts @", src.slice(0, 12));
} else if (mode === "verify") {
  const v1 = v1ok();
  if (v1.status !== 0) { console.log("INVALID_HARNESS_CHANGED_AFTER_FREEZE: v1 set:", (v1.stdout || v1.stderr).trim()); process.exit(1); }
  const m = JSON.parse(fs.readFileSync(mf, "utf8"));
  for (const [rel, h] of Object.entries(m.files)) {
    const now = sha(fs.readFileSync(path.join(ROOT, rel)));
    if (now !== h) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: ${rel}`); process.exit(1); }
  }
  console.log("v2 freeze intact:", Object.keys(m.files).length, "artifacts (v1 re-verified)");
} else { console.log("usage: freeze2.mjs create|verify"); process.exit(1); }
