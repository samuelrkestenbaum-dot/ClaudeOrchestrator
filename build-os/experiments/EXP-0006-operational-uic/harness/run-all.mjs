#!/usr/bin/env node
// EXP-0006 — the sequential driver.
//
// Arms run ONE AT A TIME. Elapsed time is a registered metric and a contended
// measurement is not a measurement; run-arm.mjs enforces this with a lock, and
// this driver simply never tries to break it.
//
// ARM ORDER ALTERNATES BY TASK INDEX. Whichever condition runs first on a task
// pays for a cold filesystem and a cold provider cache, and whichever runs
// second inherits some of that warmth. Fixing the order would give one arm that
// advantage on all twelve tasks; alternating makes it cancel. The rule is
// deterministic — odd task index runs native first, even runs gravito first —
// so it is reproducible rather than shuffled.
//
// Usage: run-all.mjs [--tasks T01,T02,...] [--dry-run]

import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const has = (n) => process.argv.includes(`--${n}`);

const HERE = path.dirname(new URL(import.meta.url).pathname);
const EXP = path.join(HERE, "..");
const RESULTS = path.join(EXP, "results");

// THE ORDERING PROPERTY, ENFORCED. The blinded mapping's whole integrity claim
// is that it was fixed before any acceptance result existed. If the digest is
// not committed yet, this refuses — the property cannot be restored afterwards
// by care.
const DIGEST = path.join(EXP, "blinding/mapping.sha256.json");
if (!fs.existsSync(DIGEST)) {
  console.error("REFUSED: blinding/mapping.sha256.json is absent. The mapping must be sealed and its digest committed BEFORE any arm executes.");
  process.exit(2);
}

const sel = JSON.parse(fs.readFileSync(path.join(RESULTS, "task-selection.json"), "utf8"));
const only = arg("tasks");
const tasks = only ? only.split(",").map((s) => s.trim()) : sel.selected.map((t) => t.task_id);
const DRY = has("dry-run");

const unknown = tasks.filter((t) => !sel.selected.some((s) => s.task_id === t));
if (unknown.length) { console.error(`REFUSED: unknown task id(s) ${unknown.join(", ")}`); process.exit(2); }

const runOne = (task, arm) => new Promise((resolve) => {
  const a = ["--task", task, "--arm", arm, ...(DRY ? ["--dry-run"] : [])];
  const c = spawn("node", [path.join(HERE, "run-arm.mjs"), ...a], { stdio: "inherit" });
  c.on("exit", (code) => resolve(code));
});

const order = (task) => {
  const idx = sel.selected.findIndex((s) => s.task_id === task) + 1;   // 1-based
  return idx % 2 === 1 ? ["native", "gravito"] : ["gravito", "native"];
};

console.log(`EXP-0006 driver — ${tasks.length} task(s), ${tasks.length * 2} arms, sequential${DRY ? " (dry-run)" : ""}`);
console.log(`mapping digest present: ${JSON.parse(fs.readFileSync(DIGEST, "utf8")).mapping_sha256.slice(0, 16)}…\n`);

const log = [];
for (const task of tasks) {
  for (const arm of order(task)) {
    const t0 = Date.now();
    const code = await runOne(task, arm);
    log.push({ task, arm, exit: code, wall_s: Math.round((Date.now() - t0) / 1000) });
    // A refused or crashed arm does NOT stop the run. It is recorded and the
    // driver continues: a partial matrix with an honest gap is worth more than
    // a run abandoned at task three.
    if (code !== 0) console.log(`  (arm ${task}/${arm} exited ${code} — recorded, continuing)`);
  }
  fs.writeFileSync(path.join(RESULTS, "driver-log.json"), JSON.stringify({ artifact: "exp0006_driver_log", dry_run: DRY, order_rule: "odd task index -> native first; even -> gravito first", units: log }, null, 2));
}

console.log(`\ndriver finished — ${log.length} arm(s) attempted, ${log.filter((l) => l.exit === 0).length} completed cleanly`);
