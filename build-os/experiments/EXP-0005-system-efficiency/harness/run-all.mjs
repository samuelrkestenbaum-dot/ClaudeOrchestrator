#!/usr/bin/env node
// EXP-0005 — drive all 24 measured arms, strictly sequentially.
//
// RUN ORDER, fixed here before execution. Arms alternate which condition goes
// first, by task index: odd-numbered tasks run native first, even-numbered run
// gravito first. A fixed order would confound condition with position — machine
// load, cache warmth and time of day all drift over a multi-hour run, and a
// condition that always ran second would carry that drift as if it were
// treatment.
//
// Reporting is TREATMENT-NEUTRAL by construction: this driver prints terminal
// state, admissibility and pair counts, and never a comparison.

import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const EXP = path.join(HERE, "..");
const tasks = JSON.parse(fs.readFileSync(path.join(EXP, "tasks/TASKS.json"), "utf8")).tasks;
const RESULTS = path.join(EXP, "results");
fs.mkdirSync(RESULTS, { recursive: true });

const only = process.argv.includes("--only") ? process.argv[process.argv.indexOf("--only") + 1] : null;
const log = (m) => {
  const line = `[${new Date().toISOString()}] ${m}`;
  console.log(line);
  fs.appendFileSync(path.join(RESULTS, "execution.log"), line + "\n");
};

const order = [];
for (const t of tasks) {
  if (only && t.task_id !== only) continue;
  const idx = Number(t.task_id.slice(1));
  order.push(...(idx % 2 === 1 ? [[t.task_id, "native"], [t.task_id, "gravito"]]
                               : [[t.task_id, "gravito"], [t.task_id, "native"]]));
}

log(`run order fixed: ${order.length} arms, alternating first-condition by task index`);

let completedPairs = 0;
const unitState = {};

for (const [taskId, arm] of order) {
  log(`starting ${taskId}/${arm}`);
  try {
    fs.rmSync("/home/user/.exp0005/arm.lock", { force: true });
    const out = execFileSync("node", [path.join(HERE, "run-arm.mjs"), "--task", taskId, "--arm", arm],
      { encoding: "utf8", maxBuffer: 32 * 1024 * 1024, timeout: 6000 * 1000 });
    const m = out.match(/UNIT .*$/m);
    log(m ? m[0] : out.trim().split("\n").slice(-1)[0]);
    unitState[`${taskId}.${arm}`] = /admissible=true/.test(out) ? "admissible" : "void";
  } catch (e) {
    const s = String(e.stdout || "") + String(e.stderr || e.message || "");
    log(`${taskId}/${arm} FAILED TO COMPLETE: ${s.split("\n").filter(Boolean).slice(-2).join(" | ").slice(0, 300)}`);
    unitState[`${taskId}.${arm}`] = "void";
  }

  const a = unitState[`${taskId}.native`], b = unitState[`${taskId}.gravito`];
  if (a && b) {
    const bothOk = a === "admissible" && b === "admissible";
    if (bothOk) completedPairs++;
    // A void arm voids its MATCHED UNIT — the registered rule. The pair is
    // re-run whole, never repaired mid-run, and never recorded as a
    // zero-token or failed-product observation.
    log(`pair ${taskId}: ${bothOk ? "COMPLETE" : "REQUIRES WHOLE-PAIR RERUN (a void arm voids its matched unit)"} — completed pairs: ${completedPairs}`);
  }
}

fs.writeFileSync(path.join(RESULTS, "unit-state.json"), JSON.stringify({ unitState, completedPairs }, null, 2));
log(`DRIVER DONE — completed pairs: ${completedPairs} of ${Object.keys(unitState).length / 2}`);
