#!/usr/bin/env node
// FREEZE-MANIFEST v5 — the RELEASE-AUDIT freeze.
//
// Two release-audit findings force this amendment (AMENDMENT-V5.md):
//   1. ORACLE PATH IDENTITY: tsc embeds absolute module specifiers in some
//      messages; the frozen baseline was produced in one directory and
//      measured runs happen in another, so 5 of 781 identities would have
//      false-regressed EVERY cell. oracle.mjs identities are now
//      tree-root-free and the committed baseline is normalized (<TREE>).
//   2. WORKER-ENVIRONMENT INSTALL CLOSURE: gravito init installs engine
//      bytes into the measured worktree via install-project.sh /
//      init-build-os.sh (.claude agents/commands/hooks, tools, templates,
//      maintenance layer, settings-merge logic). Those bytes shape worker
//      behavior and were OUTSIDE v4. v5 freezes the full closure as
//      recursive TREES with per-file sha+mode.
// v1 stays live-verified; v2/v3/v4 manifest FILES are history inside v5.
import fs from "node:fs"; import path from "node:path"; import crypto from "node:crypto";
import { spawnSync } from "node:child_process";
const sha = (b) => crypto.createHash("sha256").update(b).digest("hex");
const HERE = path.dirname(new URL(import.meta.url).pathname);
const ROOT = path.resolve(HERE, "..");
const ARTIFACTS = [
  "FREEZE-MANIFEST.json", "FREEZE-MANIFEST-v2.json", "FREEZE-MANIFEST-v3.json", "FREEZE-MANIFEST-v4.json",
  "FAILURE-MODES-ADDENDUM.md", "AMENDMENT-V3.md", "AMENDMENT-V4.md", "AMENDMENT-V5.md",
  "INCIDENT-2026-08-13-UNAUTHORIZED-CALL.md", "ESCROW-HANDOFF.md",
  "PREREGISTRATION-STAGE-A.md", "FAILURE-MODES.md", "STAGED-DESIGN.md",
  "corpus/sequences.json", "corpus/baseline-tsc.txt",
  "corpus/ARM-ORDER-COMMITMENT.json", "corpus/RERUN-ORDER-COMMITMENT.json",
  "harness/fixture.mjs", "harness/scheduler.mjs", "harness/views.mjs", "harness/fake-worker.sh", "harness/freeze.mjs",
  "harness/oracle.mjs", "harness/telemetry.mjs", "harness/model-config.json", "harness/seal-orders.mjs",
  "harness/controller.mjs", "harness/analysis.mjs", "harness/freeze2.mjs", "harness/freeze3.mjs", "harness/freeze4.mjs", "harness/freeze5.mjs",
  "harness/supervise.mjs", "harness/transport-rehearsal.mjs", "harness/transport-measured.mjs",
  "harness/spend-ledger.mjs", "harness/distill.mjs", "harness/mapping-escrow.mjs", "harness/leakcheck2.mjs",
  "harness/exec-registry.mjs", "harness/provider-argv.mjs", "harness/provider-call-site.mjs",
  "harness/authorization.mjs", "harness/escrow-cli.mjs",
  "../../delivery/ucdl.mjs", "../../tools/planner.mjs",
  "../../tools/reachability.mjs", "../../tools/h0-check.sh",
  "../../tools/goal-check.sh", "../../tools/route-task.sh", "../../tools/mode-select.mjs",
  "../../../bin/gravito", "../../../install-project.sh", "../../../init-build-os.sh",
  "../../../tests/exp0013_fixture_tests.sh", "../../../tests/exp0013_readiness_tests.sh",
  "../../../tests/exp0013_redteam_tests.sh", "../../../tests/exp0013_capability_tests.sh",
  "../../../tests/exp0013_release_tests.sh",
];
// The worker-environment install closure, frozen as whole trees.
const TREES = ["../../../templates", "../../../.claude/agents", "../../../.claude/commands", "../../../.claude/hooks", "../../maintenance"];
const INVENTORY_DIRS = ["harness", "corpus"];

const walk = (dir) => {
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) out.push(...walk(p));
    else out.push(p);
  }
  return out;
};
const mode = process.argv[2];
const mf = path.join(ROOT, "FREEZE-MANIFEST-v5.json");
const v1ok = () => spawnSync("node", [path.join(HERE, "freeze.mjs"), "verify"], { encoding: "utf8" });
const snapshot = () => {
  const files = {};
  for (const a of ARTIFACTS) {
    const p = path.join(ROOT, a);
    files[a] = { sha256: sha(fs.readFileSync(p)), mode: (fs.statSync(p).mode & 0o777).toString(8) };
  }
  const trees = {};
  for (const t of TREES) {
    const base = path.join(ROOT, t);
    trees[t] = {};
    for (const p of walk(base)) {
      const rel = path.relative(base, p);
      trees[t][rel] = { sha256: sha(fs.readFileSync(p)), mode: (fs.statSync(p).mode & 0o777).toString(8) };
    }
  }
  const inventory = {};
  for (const d of INVENTORY_DIRS) inventory[d] = fs.readdirSync(path.join(ROOT, d)).sort();
  return { files, trees, inventory };
};
if (mode === "create") {
  const v1 = v1ok();
  if (v1.status !== 0) { console.log("REFUSED: v1 freeze does not verify:", (v1.stdout || v1.stderr).trim()); process.exit(1); }
  const src = spawnSync("git", ["-C", ROOT, "rev-parse", "HEAD"], { encoding: "utf8" }).stdout.trim();
  const s = snapshot();
  const nTree = Object.values(s.trees).reduce((a, t) => a + Object.keys(t).length, 0);
  fs.writeFileSync(mf, JSON.stringify({
    artifact: "exp0013_freeze_manifest_v5",
    predecessors: "v1 live-verified; v2/v3/v4 manifests immutable history (their own verifies superseded per AMENDMENT-V5.md)",
    source_commit_at_freeze: src, ...s,
    unfrozen: [
      "sealed order/rerun/blinding stores + salts (outside repo; commitments frozen)",
      "corpus/mapping-escrow.json (owner-created post-publication; digest recorded in that go)",
      "the p1-distilled live stores (spend-time products of frozen distill.mjs)",
      "EXECUTION-READINESS.md, PRE-SPEND-AUDIT.md, PUBLICATION-READINESS.md, RELEASE-AUDIT.md, OWNER-GUIDE.md (describe freezes)",
      "rehearsal-evidence/ (run products, not contract)",
    ],
  }, null, 2) + "\n");
  console.log("v5 frozen:", Object.keys(s.files).length, "artifacts +", nTree, "tree files (install closure) + inventory @", src.slice(0, 12));
} else if (mode === "verify") {
  const v1 = v1ok();
  if (v1.status !== 0) { console.log("INVALID_HARNESS_CHANGED_AFTER_FREEZE: v1 set:", (v1.stdout || v1.stderr).trim()); process.exit(1); }
  const m = JSON.parse(fs.readFileSync(mf, "utf8"));
  const checkRec = (label, p, rec) => {
    if (!fs.existsSync(p)) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: MISSING_FILE ${label}`); process.exit(1); }
    if (sha(fs.readFileSync(p)) !== rec.sha256) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: ${label}`); process.exit(1); }
    const mode8 = (fs.statSync(p).mode & 0o777).toString(8);
    if (mode8 !== rec.mode) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: MODE_DRIFT ${label} ${rec.mode}->${mode8}`); process.exit(1); }
  };
  for (const [rel, rec] of Object.entries(m.files)) checkRec(rel, path.join(ROOT, rel), rec);
  for (const [t, entries] of Object.entries(m.trees)) {
    const base = path.join(ROOT, t);
    const now = new Set(walk(base).map((p) => path.relative(base, p)));
    for (const [rel, rec] of Object.entries(entries)) checkRec(`${t}/${rel}`, path.join(base, rel), rec);
    for (const rel of now) if (!entries[rel]) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: UNEXPECTED_FILE ${t}/${rel}`); process.exit(1); }
  }
  for (const d of Object.keys(m.inventory)) {
    const now = fs.readdirSync(path.join(ROOT, d)).sort();
    for (const f of now) if (!m.inventory[d].includes(f)) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: UNEXPECTED_FILE ${d}/${f}`); process.exit(1); }
    for (const f of m.inventory[d]) if (!now.includes(f)) { console.log(`INVALID_HARNESS_CHANGED_AFTER_FREEZE: MISSING_FILE ${d}/${f}`); process.exit(1); }
  }
  const nTree = Object.values(m.trees).reduce((a, t) => a + Object.keys(t).length, 0);
  console.log("v5 freeze intact:", Object.keys(m.files).length, "artifacts +", nTree, "tree files + inventory (v1 re-verified)");
} else { console.log("usage: freeze5.mjs create|verify"); process.exit(1); }
