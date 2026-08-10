import fs from "node:fs";
const R7 = "build-os/experiments/EXP-0007-three-factor-ablation/results/runs";
const R6 = "build-os/experiments/EXP-0006-operational-uic/results/runs";
const TASKS = ["T01", "T02", "T03", "T04"];
const SETS = [
  ["native", R6, TASKS.map((t) => `${t}.native`)],
  ["corrected", R7, TASKS.flatMap((t) => [`${t}.corrected`, `${t}.corrected.r2`, `${t}.corrected.r3`])],
];
const out = [];
for (const [group, root, dirs] of SETS) {
  for (const d of dirs) {
    let ev = [];
    try {
      ev = fs.readFileSync(`${root}/${d}/stream.jsonl`, "utf8").split("\n").filter(Boolean)
        .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
    } catch { continue; }
    let i = 0, turnIdx = 0;
    for (const e of ev) {
      const c = e?.message?.content;
      if (!Array.isArray(c) || e.message.role !== "assistant") continue;
      turnIdx++;
      if (c.some((x) => x.type === "tool_use")) continue;
      const t = c.filter((x) => x.type === "text").map((x) => x.text).join("\n").trim();
      if (!t) continue;
      out.push({ id: `${group}/${d}/${i++}`, group, arm: d, task: d.slice(0, 3), pos: turnIdx, chars: t.length, text: t });
    }
  }
}
fs.writeFileSync(process.argv[2], out.map((o) => JSON.stringify(o)).join("\n") + "\n");
const by = {};
for (const o of out) by[o.group] = (by[o.group] || 0) + 1;
console.error(`extracted ${out.length} text-only turns: ${JSON.stringify(by)}`);
const chars = {}; const arms = {};
for (const o of out) { chars[o.group] = (chars[o.group] || 0) + o.chars; arms[o.group] = arms[o.group] || new Set(); arms[o.group].add(o.arm); }
for (const g of Object.keys(by))
  console.error(`  ${g}: ${arms[g].size} arms, ${(by[g] / arms[g].size).toFixed(1)} turns/arm, ${Math.round(chars[g] / by[g])} chars/turn median-ish mean`);
