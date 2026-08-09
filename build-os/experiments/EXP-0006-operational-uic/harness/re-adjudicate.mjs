#!/usr/bin/env node
// EXP-0006 — RE-ADJUDICATE every recorded arm from its stored artifacts.
//
// WHY THIS IS LEGITIMATE, STATED BEFORE IT IS USED, BECAUSE IT IS THE KIND OF
// STEP THAT LAUNDERS A RESULT IF NOBODY WRITES DOWN WHY.
//
// The pilot's first arm exposed a defect in ACCEPTANCE, not in EXECUTION: tsc
// embeds absolute paths in some messages, the baseline tree and the arm tree
// sit at different paths, and the same pre-existing error therefore hashed
// differently in the two. Five untouched files read as regressions.
//
// Everything the verdict is computed from — the compiler output, the diff, the
// baseline — was captured to disk before anything could destroy it. So the
// correct repair is to recompute the verdict from those artifacts, not to spend
// another arm's compute reproducing bytes that already exist.
//
// THREE CONSTRAINTS THAT KEEP THIS FROM BEING RESULT-FITTING:
//
//   1. The FROZEN acceptance rule is unchanged. Only the environment-path
//      artifact is removed, and the mutation tests prove a genuinely new error
//      still rejects afterwards.
//   2. The original verdict is PRESERVED as acceptance.original.json. A
//      correction that erases what it corrected is indistinguishable from a
//      rewrite.
//   3. Re-adjudication is applied to EVERY unit, uniformly and blind to arm. It
//      is never applied to the units whose verdict one would prefer to change.
//
// Usage: re-adjudicate.mjs [--dry-run]

import fs from "node:fs";
import path from "node:path";
import { adjudicate } from "./acceptance.mjs";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const RESULTS = path.join(HERE, "../results");
const RUNS = path.join(RESULTS, "runs");
const DRY = process.argv.includes("--dry-run");

const baselineRaw = fs.readFileSync(path.join(RESULTS, "baseline-tsc.txt"), "utf8");
const sel = JSON.parse(fs.readFileSync(path.join(RESULTS, "task-selection.json"), "utf8"));

const dirs = fs.existsSync(RUNS) ? fs.readdirSync(RUNS).sort() : [];
const changes = [];

for (const d of dirs) {
  const [task_id] = d.split(".");
  const task = sel.selected.find((t) => t.task_id === task_id);
  const runDir = path.join(RUNS, d);
  const vPath = path.join(runDir, "verification.txt");
  const dPath = path.join(runDir, "full.diff");
  if (!task || !fs.existsSync(vPath)) { changes.push({ unit: d, status: "skipped", why: "no verification artifact" }); continue; }

  const prev = (() => { try { return JSON.parse(fs.readFileSync(path.join(runDir, "acceptance.json"), "utf8")); } catch { return null; } })();
  const next = adjudicate({
    baselineRaw,
    afterRaw: fs.readFileSync(vPath, "utf8"),
    taskFile: task.file,
    diff: fs.existsSync(dPath) ? fs.readFileSync(dPath, "utf8") : "",
  });
  next.verification_exit_code = prev?.verification_exit_code ?? null;
  next.readjudicated = true;
  next.readjudication_reason =
    "recomputed from the stored compiler output and diff after the path-normalisation defect was found on the " +
    "pilot's first arm; the frozen acceptance rule is unchanged and the original verdict is preserved alongside";

  const flipped = prev ? prev.accepted !== next.accepted : null;
  changes.push({
    unit: d, status: "readjudicated", was: prev?.accepted ?? null, now: next.accepted, flipped,
    new_errors_before_fix: prev?.condition_2_no_new_errors_elsewhere?.new_error_count ?? null,
    new_errors_after_fix: next.condition_2_no_new_errors_elsewhere.new_error_count,
    normalisations: next.path_normalisations_applied,
  });

  if (!DRY) {
    if (prev && !fs.existsSync(path.join(runDir, "acceptance.original.json")))
      fs.writeFileSync(path.join(runDir, "acceptance.original.json"), JSON.stringify(prev, null, 2));
    fs.writeFileSync(path.join(runDir, "acceptance.json"), JSON.stringify(next, null, 2));
  }
}

if (!DRY) fs.writeFileSync(path.join(RESULTS, "readjudication-log.json"), JSON.stringify({
  artifact: "exp0006_readjudication_log",
  defect: "acceptance keyed on raw tsc message text, which embeds absolute paths; baseline and arm trees sit at different paths",
  classification: "measurement_critical — fixed before the affected runs were admitted, per the frozen stopping rules",
  rule_changed: false,
  applied_to: "every recorded unit, uniformly and blind to arm",
  originals_preserved_as: "acceptance.original.json",
  changes,
}, null, 2));

const flipped = changes.filter((c) => c.flipped === true);
console.log(`re-adjudicated ${changes.filter((c) => c.status === "readjudicated").length} unit(s)${DRY ? " (dry-run)" : ""}`);
for (const c of changes) {
  if (c.status === "skipped") { console.log(`  ${c.unit.padEnd(16)} skipped — ${c.why}`); continue; }
  console.log(`  ${c.unit.padEnd(16)} ${String(c.was)} -> ${String(c.now)}  new_errors ${c.new_errors_before_fix} -> ${c.new_errors_after_fix}${c.flipped ? "   FLIPPED" : ""}`);
}
console.log(`\n${flipped.length} verdict(s) changed. Originals preserved; the acceptance rule is unchanged.`);
