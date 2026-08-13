#!/usr/bin/env node
// Freeze manifest: sha256 every frozen artifact + source commit. verify
// refuses on any post-freeze change (typed: INVALID_HARNESS_CHANGED_AFTER_FREEZE).
import fs from "node:fs"; import path from "node:path"; import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
const sha = (b) => crypto.createHash("sha256").update(b).digest("hex");
const HERE = path.dirname(new URL(import.meta.url).pathname);
const ROOT = path.resolve(HERE, "..");
const ARTIFACTS = [
  "PREREGISTRATION-STAGE-A.md", "FAILURE-MODES.md", "STAGED-DESIGN.md",
  "harness/fixture.mjs", "harness/scheduler.mjs", "harness/views.mjs",
  "harness/fake-worker.sh", "harness/freeze.mjs",
];
const mode = process.argv[2];
const mf = path.join(ROOT, "FREEZE-MANIFEST.json");
if (mode === "create") {
  const src = execFileSync("git", ["-C", ROOT, "rev-parse", "HEAD"], { encoding: "utf8" }).trim();
  const files = {};
  for (const a of ARTIFACTS) files[a] = sha(fs.readFileSync(path.join(ROOT, a)));
  files["../../delivery/ucdl.mjs"] = sha(fs.readFileSync(path.join(ROOT, "../../delivery/ucdl.mjs")));
  files["../../tools/planner.mjs"] = sha(fs.readFileSync(path.join(ROOT, "../../tools/planner.mjs")));
  fs.writeFileSync(mf, JSON.stringify({ artifact: "exp0013_freeze_manifest", source_commit_at_freeze: src, files,
    unfrozen: ["final proprietary task content (not yet authored/authorized)", "arm-order coin flips (generated+sealed at spend authorization)", "sequence corpora (selected per frozen procedure at spend authorization)"] }, null, 2) + "\n");
  console.log("frozen:", Object.keys(files).length, "artifacts @", src.slice(0, 12));
} else if (mode === "verify") {
  const m = JSON.parse(fs.readFileSync(mf, "utf8"));
  for (const [rel, h] of Object.entries(m.files)) {
    const now = sha(fs.readFileSync(path.join(ROOT, rel)));
    if (now !== h) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: ${rel}`); process.exit(1); }
  }
  console.log("freeze intact:", Object.keys(m.files).length, "artifacts");
} else { console.log("usage: freeze.mjs create|verify"); process.exit(1); }
