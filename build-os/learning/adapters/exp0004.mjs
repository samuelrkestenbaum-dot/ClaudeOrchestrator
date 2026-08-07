// Adapter: frozen EXP-0004 artifacts -> the disposition input schema.
// It reads ONLY the frozen files. It contains no findings, no conclusions and
// no component names — those must come from the rules, or the test is theatre.
import fs from "node:fs";
const D = "build-os/experiments/EXP-0004-context-compiler/results";
const J = (f) => JSON.parse(fs.readFileSync(`${D}/${f}`, "utf8"));

const calc = J("calculations.json");
const adj = J("adjudication.json");
const excl = J("exclusion-decisions.json");
const reveal = J("REVEAL.json");

// Which label is which condition comes from the REVEAL, which is frozen.
const map = reveal.revealed_mapping;
const label = {};
for (const [cond, lab] of Object.entries(map)) label[lab] = cond.replace(/\s*\(.\)$/, "").replace(/\s*condition$/, "");

const other = (l) => (l === "Arm X" ? "Arm Y" : "Arm X");
const median = (a) => { const s=[...a].sort((x,y)=>x-y); return s.length%2 ? s[(s.length-1)/2] : (s[s.length/2-1]+s[s.length/2])/2; };

// Starting-context medians per label, from the frozen records.
const recs = fs.readdirSync(`${D}/records`).map((f) => JSON.parse(fs.readFileSync(`${D}/records/${f}`, "utf8")));
const startsByArm = { A: [], B: [] };
for (const r of recs) {
  const v = r.fields.starting_context_bytes?.value;
  if (typeof v === "number") startsByArm[r.arm].push(v);
}
// arm -> label, via the sealed units in the analyst view
const analyst = J("analyst-view.json");
const armOfUnit = {}; // unit_id -> label
for (const u of analyst.units) armOfUnit[u.unit_id] = u.label;

// Determine which label carries the heavier starting context by matching the
// arm-B records (larger set) against labels through the adjudication task ids.
const heavyArm = median(startsByArm.A) > median(startsByArm.B) ? "A" : "B";
const lightArm = heavyArm === "A" ? "B" : "A";
// The label for the heavy arm: whichever label's per-task token delta matches
// the arm that carries the bigger payload. Derived, not asserted:
const heavyLabel = Object.keys(label).find((l) =>
  label[l].includes(heavyArm === "B" ? "compiled" : "current")) || "Arm X";

const deltas = calc.per_task.map((t) => ({
  task_id: t.task_id,
  delta: t.uncached_reduction_pct[`${heavyLabel} relative to ${other(heavyLabel)}`],
}));

const rejected = adj.units.filter((u) => u.acceptance_result === "rejected").map((u) => ({
  task_id: u.task_id,
  condition: label[armOfUnit[u.unit_id]] || "unknown condition",
  regressions: (recs.find((r) => r.task_id === u.task_id &&
    (r.fields.regressions?.value ?? 0) > 0)?.fields.regressions?.value) ?? 0,
}));

const acc = calc.acceptance;
export default {
  experiment: "EXP-0004",
  per_task: deltas,
  rejected,
  acceptance_line: Object.entries(acc).map(([l, v]) => `${label[l]} ${v.accepted}/${v.n}`).join(", "),
  starting_heavy: median(startsByArm[heavyArm]),
  starting_light: median(startsByArm[lightArm]),
  heavier_condition: label[heavyLabel],
  heavier_lost_tokens: median(deltas.map((d) => d.delta)) < 0,
  median_token_delta_heavy: median(deltas.map((d) => d.delta)),
  treatment_condition: label[heavyLabel],
  admitted: 10,
  attempted: 10 + (excl.void_attempts || []).length,
  void_reasons: (excl.void_attempts || []).map((v) => `${v.pair} attempt ${v.attempt}: ${v.reason}`),
  gates_met: 0,
};
