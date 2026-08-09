#!/usr/bin/env node
// EXP-0007 — recompute every arm's verdict from its stored artifacts.
//
// Same rules that governed EXP-0006's re-adjudication, and they are the reason
// this is a correction rather than a laundering:
//   1. the FROZEN acceptance rule is unchanged;
//   2. the original verdict is preserved as acceptance.original.json;
//   3. it is applied to EVERY unit, uniformly and blind to configuration —
//      never only to the units whose verdict one would prefer to change.
//
// Usage: re-adjudicate.mjs [--dry-run]
import fs from "node:fs"; import path from "node:path";
import { adjudicate } from "../EXP-0006-operational-uic/harness/acceptance.mjs";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const EXP6 = path.join(HERE, "../EXP-0006-operational-uic/results");
const RUNS = path.join(HERE, "results/runs");
const DRY = process.argv.includes("--dry-run");

const baselineRaw = fs.readFileSync(path.join(EXP6, "baseline-tsc.txt"), "utf8");
const sel = JSON.parse(fs.readFileSync(path.join(EXP6, "task-selection.json"), "utf8"));
const changes = [];

for (const d of (fs.existsSync(RUNS) ? fs.readdirSync(RUNS).sort() : [])) {
  const [task_id] = d.split(".");
  const task = sel.selected.find((t) => t.task_id === task_id);
  const rd = path.join(RUNS, d);
  const vp = path.join(rd, "verification.txt");
  if (!task || !fs.existsSync(vp)) { changes.push({ unit: d, status: "skipped", why: "no verification artifact" }); continue; }
  const prev = (() => { try { return JSON.parse(fs.readFileSync(path.join(rd, "acceptance.json"), "utf8")); } catch { return null; } })();
  const next = adjudicate({ baselineRaw, afterRaw: fs.readFileSync(vp, "utf8"), taskFile: task.file,
    diff: fs.existsSync(path.join(rd, "full.diff")) ? fs.readFileSync(path.join(rd, "full.diff"), "utf8") : "" });
  next.verification_exit_code = prev?.verification_exit_code ?? null;
  next.readjudicated = true;
  next.readjudication_reason =
    "recomputed after the path-artifact detector replaced root enumeration; the frozen acceptance rule is unchanged " +
    "and the original verdict is preserved alongside";
  changes.push({ unit: d, status: "readjudicated", was: prev?.accepted ?? null, now: next.accepted,
    flipped: prev ? prev.accepted !== next.accepted : null,
    new_errors_before: prev?.condition_2_no_new_errors_elsewhere?.new_error_count ?? null,
    new_errors_after: next.condition_2_no_new_errors_elsewhere.new_error_count,
    path_artifacts: next.condition_2_no_new_errors_elsewhere.path_artifacts_excluded ?? 0 });
  if (!DRY) {
    if (prev && !fs.existsSync(path.join(rd, "acceptance.original.json")))
      fs.writeFileSync(path.join(rd, "acceptance.original.json"), JSON.stringify(prev, null, 2));
    fs.writeFileSync(path.join(rd, "acceptance.json"), JSON.stringify(next, null, 2));
  }
}
if (!DRY) fs.writeFileSync(path.join(HERE, "results/readjudication-log.json"), JSON.stringify({
  artifact: "exp0007_readjudication_log", rule_changed: false,
  defect: "acceptance normalised absolute paths against an ENUMERATED root list; EXP-0007 runs under a tree name that list did not contain",
  classification: "measurement_critical — fixed before the affected runs were admitted",
  applied_to: "every recorded unit, uniformly and blind to configuration",
  originals_preserved_as: "acceptance.original.json", changes }, null, 2));

console.log(`re-adjudicated ${changes.filter((c) => c.status === "readjudicated").length} unit(s)${DRY ? " (dry-run)" : ""}`);
for (const c of changes) console.log(c.status === "skipped"
  ? `  ${c.unit.padEnd(16)} skipped — ${c.why}`
  : `  ${c.unit.padEnd(16)} ${String(c.was)} -> ${String(c.now)}  new_errors ${c.new_errors_before} -> ${c.new_errors_after}${c.flipped ? "   FLIPPED" : ""}`);
console.log(`\n${changes.filter((c) => c.flipped === true).length} verdict(s) changed.`);
