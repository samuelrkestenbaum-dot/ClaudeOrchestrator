// WHICH MECHANISM REFUSES THE WORKER'S STOP?
//
// Both contaminated and uncontaminated Gravito arms re-report 2-3x where native
// reports once. The question is whether it is the SAME driver. Each arm's
// text turns are scored for the two candidate drivers; an arm is attributed to
// whichever it references more, and ties/zeros are reported as such rather than
// forced.
import fs from "node:fs";
const R6 = "build-os/experiments/EXP-0006-operational-uic/results/runs";
const R7 = "build-os/experiments/EXP-0007-three-factor-ablation/results/runs";
const T = ["T01", "T02", "T03", "T04"];
const GROUPS = [
  ["EXP0006 native      (no substrate)", R6, fs.readdirSync(R6).filter((d) => d.endsWith(".native")).sort()],
  ["EXP0006 gravito     (contaminated)", R6, fs.readdirSync(R6).filter((d) => d.endsWith(".gravito")).sort()],
  ["EXP0007 baseline    (contaminated)", R7, T.flatMap((t) => [`${t}.baseline`, `${t}.baseline.r2`, `${t}.baseline.r3`])],
  ["EXP0007 corrected (uncontaminated)", R7, T.flatMap((t) => [`${t}.corrected`, `${t}.corrected.r2`, `${t}.corrected.r3`])],
];
// Deliberately narrow and non-overlapping. QUEUE = someone else's agenda.
// EXHAUSTION = the concession gate's own demand for documented capability search.
const QUEUE = /#\d\d\b|queue item|queue\.json|your go\b|unstarted|unrouted|jump to|awaiting your call|standing by|holding\b/i;
const EXHAUST = /exhaust|concession|cross-surface|untested surface|unsearched|enumerat\w* (the )?(surface|capabilit)|capability (map|registry)|another surface holds|gate-stop/i;

console.log("group".padEnd(36) + "arms".padStart(5) + "queue-refs".padStart(12) + "exhaust-refs".padStart(14) + "  arms by dominant driver");
for (const [label, root, dirs] of GROUPS) {
  let q = 0, x = 0, byQ = 0, byX = 0, neither = 0, n = 0;
  for (const d of dirs) {
    let ev = [];
    try {
      ev = fs.readFileSync(`${root}/${d}/stream.jsonl`, "utf8").split("\n").filter(Boolean)
        .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
    } catch { continue; }
    n++;
    let aq = 0, ax = 0;
    for (const e of ev) {
      const c = e?.message?.content;
      if (!Array.isArray(c) || e.message.role !== "assistant" || c.some((y) => y.type === "tool_use")) continue;
      const t = c.filter((y) => y.type === "text").map((y) => y.text).join(" ");
      if (!t.trim()) continue;
      if (QUEUE.test(t)) aq++;
      if (EXHAUST.test(t)) ax++;
    }
    q += aq; x += ax;
    if (aq === 0 && ax === 0) neither++; else if (aq > ax) byQ++; else if (ax > aq) byX++; else neither++;
  }
  console.log(label.padEnd(36) + String(n).padStart(5) + (q / n).toFixed(2).padStart(12) + (x / n).toFixed(2).padStart(14) +
    `   queue ${byQ}, exhaustion ${byX}, neither/tied ${neither}`);
}
