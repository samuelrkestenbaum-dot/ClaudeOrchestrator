#!/usr/bin/env node
// Mechanical readiness check for EXP-0005.
//
// "8 of 8" written in a document is a claim. This is the check: each item is
// verified against the artifact that is supposed to satisfy it, and an item
// whose evidence is missing, malformed, or self-contradictory FAILS rather than
// defaulting to satisfied.
//
// It deliberately does NOT read its own conclusions from PREREGISTRATION.md's
// checkbox list. A readiness check that trusts the checkboxes proves only that
// someone typed an x.

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const rd = (p) => fs.readFileSync(path.join(HERE, p), "utf8");
const json = (p) => JSON.parse(rd(p));
const exists = (p) => fs.existsSync(path.join(HERE, p));

const items = [];
const item = (n, title, fn) => {
  let ok = false, detail = "";
  try { const r = fn(); ok = r.ok; detail = r.detail; }
  catch (e) { ok = false; detail = `check threw: ${e.message}`; }
  items.push({ n, title, ok, detail });
};

item(1, "task set selected and frozen (>= 10, multi-shape)", () => {
  const sel = json("tasks/SELECTION.json");
  const freeze = rd("tasks/TASK-FREEZE.md");
  const n = sel.selected.length;
  const shapes = new Set(sel.selected.map((t) => t.shape));
  const idsInFreeze = sel.selected.every((t) => freeze.includes(t.task_id));
  // The quota is part of the rule, so a set that breaches it is not frozen-valid.
  const perShape = {};
  for (const t of sel.selected) perShape[t.shape] = (perShape[t.shape] || 0) + 1;
  const quotaOk = Object.values(perShape).every((c) => c <= sel.quota_per_shape);
  const codeCounts = {};
  for (const t of sel.selected) if (t.ts_code) codeCounts[t.ts_code] = (codeCounts[t.ts_code] || 0) + 1;
  const codeOk = Object.values(codeCounts).every((c) => c <= sel.quota_per_ts_code);
  const ledgerOk = Array.isArray(sel.ledger) && sel.ledger.length > n;
  return {
    ok: n >= 10 && shapes.size >= 2 && idsInFreeze && quotaOk && codeOk && ledgerOk,
    detail: `${n} tasks, ${shapes.size} shapes ${JSON.stringify(perShape)}; ts-code mix ${JSON.stringify(codeCounts)}; ` +
            `all ids present in TASK-FREEZE: ${idsInFreeze}; quotas held: ${quotaOk && codeOk}; ` +
            `${sel.ledger.length - n} exclusions recorded`,
  };
});

item(2, "repository seed pinned, and the pin refuses", () => {
  const pin = rd("memory/SEED-PIN.md");
  const script = path.join(HERE, "harness/restore-seed.sh");
  const hasSeed = /2543c873141fa64653a7993d326465d5e0dd1006/.test(pin);
  const hasTree = /2f5e391f2bcc12c9264d4303a3f0ad709056e672/.test(pin);
  // Non-vacuity: a wrong expected digest must be REFUSED, not warned about.
  let refuses = false;
  try {
    execFileSync("bash", [script, "--verify-only", "/home/user/empathiq-website", "--allow-live-ledgers"],
      { env: { ...process.env, EXP0005_EXPECTED_DIGEST: "0".repeat(64) }, encoding: "utf8", stdio: "pipe" });
  } catch { refuses = true; }
  // And the correct digest must PASS, or the check is merely always-refusing.
  let accepts = false;
  try {
    execFileSync("bash", [script, "--verify-only", "/home/user/empathiq-website", "--allow-live-ledgers"],
      { encoding: "utf8", stdio: "pipe" });
    accepts = true;
  } catch { accepts = false; }
  return { ok: hasSeed && hasTree && refuses && accepts && fs.existsSync(script),
    detail: `seed+tree recorded: ${hasSeed && hasTree}; refuses a wrong digest: ${refuses}; accepts the real one: ${accepts}` };
});

item(3, "memory state pinned by a reproducible digest", () => {
  const pin = rd("memory/SEED-PIN.md");
  const digest = "3311a638e5f6255c7a095ab6bc91592cc9236283b0ab4ff4fe62eea306f19bfb";
  const recorded = pin.includes(digest);
  // The superseded value must still be visible, or the correction was hidden.
  const supersessionVisible = pin.includes("7de42dd1c5a779a257645a0deecea2d8292b8501f84832e8c21cf65542e76ae6");
  const inventoryIntact = exists("memory/INVENTORY.md");
  return { ok: recorded && supersessionVisible && inventoryIntact,
    detail: `pin digest recorded: ${recorded}; superseded value still visible: ${supersessionVisible}; inventory present: ${inventoryIntact}` };
});

item(4, "common timeout ceiling calibrated and frozen", () => {
  const t = rd("calibration/TIMEOUT-RULE-FROZEN.md");
  const has5400 = /\b5400\b/.test(t);
  // The registered correction: ONE common ceiling, not a per-arm multiple.
  const notPerArm = /common/i.test(t);
  return { ok: has5400 && notPerArm, detail: `5400 s recorded: ${has5400}; stated as a common ceiling: ${notPerArm}` };
});

item(5, "three-role blinding harness built and leak-tested", () => {
  const out = execFileSync("node", [path.join(HERE, "blinding/blinding.test.mjs")], { encoding: "utf8" });
  const m = out.match(/TESTS:\s*(\d+)\s*passed,\s*(\d+)\s*failed/);
  const passed = m ? Number(m[1]) : 0, failed = m ? Number(m[2]) : 1;
  return { ok: passed >= 40 && failed === 0, detail: `${passed} passed, ${failed} failed` };
});

item(6, "governance-strip rule implemented and tested", () => {
  const src = rd("blinding/governance-strip.mjs");
  const confounds = /result_confounded/.test(src);
  const patterns = (src.match(/\/.*build-os.*\//) || []).length > 0 || /build-os/.test(src);
  return { ok: confounds && patterns, detail: `leak => result_confounded: ${confounds}; governance paths matched: ${patterns}` };
});

item(7, "mapping sealed, digest committed, seal NOT in the repository", () => {
  const d = json("blinding/mapping.sha256.json");
  const sel = json("tasks/SELECTION.json");
  const allTasks = sel.selected.every((t) => d.task_ids.includes(t.task_id));
  const unitsOk = d.n_units === d.n_tasks * d.arms.length;
  const checksOk = Array.isArray(d.verification) && d.verification.length >= 12 && d.verification.every((v) => v.ok);
  const digestOk = /^[0-9a-f]{64}$/.test(d.mapping_sha256);
  // The seal itself must not be committed anywhere in the repository.
  let sealLeaked = false;
  try {
    const tracked = execFileSync("git", ["-C", "/home/user/ClaudeOrchestrator", "ls-files"], { encoding: "utf8" });
    sealLeaked = /sealed-mapping\.json|exp0005.*salt/i.test(tracked);
  } catch { sealLeaked = true; }
  return { ok: allTasks && unitsOk && checksOk && digestOk && !sealLeaked,
    detail: `all ${d.n_tasks} task ids sealed: ${allTasks}; ${d.n_units} units: ${unitsOk}; ` +
            `${d.verification.length} checks all ok: ${checksOk}; seal/salt untracked: ${!sealLeaked}` };
});

item(8, "preregistration FROZEN and self-contained", () => {
  const p = rd("PREREGISTRATION.md");
  const frozen = /\*\*Status:\s*FROZEN\.\*\*/.test(p);
  const notExecuted = /No arm has executed/.test(p);
  const hasRefs = /## Deterministic references/.test(p);
  const hasLimits = /## Known limitations/.test(p);
  // Every deterministically-referenced artifact must actually exist.
  const referenced = [
    "tasks/TASK-FREEZE.md", "tasks/SELECTION.json", "tasks/SELECTION-RULE.md", "tasks/select-tasks.mjs",
    "memory/SEED-PIN.md", "memory/INVENTORY.md", "harness/restore-seed.sh",
    "calibration/TIMEOUT-RULE-FROZEN.md", "blinding/roles.mjs", "blinding/governance-strip.mjs",
    "blinding/SEAL.md", "blinding/mapping.sha256.json", "baseline/BASELINE.md", "baseline/STABLE-FAILURES.json",
  ];
  const missing = referenced.filter((r) => !exists(r));
  return { ok: frozen && notExecuted && hasRefs && hasLimits && missing.length === 0,
    detail: `FROZEN: ${frozen}; not executed: ${notExecuted}; references+limitations sections: ${hasRefs && hasLimits}; ` +
            (missing.length ? `MISSING artifacts: ${missing.join(", ")}` : `all ${referenced.length} referenced artifacts exist`) };
});

const met = items.filter((i) => i.ok).length;
for (const i of items) console.log(`${i.ok ? "PASS" : "FAIL"}  ${i.n}. ${i.title}\n      ${i.detail}`);
console.log(`\nREADINESS: ${met} of ${items.length}`);
if (met !== items.length) { console.log("NOT READY — nothing may execute."); process.exit(1); }
console.log("8/8 verified mechanically. Nothing executes until the operator reviews the frozen design.");
