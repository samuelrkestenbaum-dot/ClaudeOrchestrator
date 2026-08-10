// HYPOTHESIS: the contaminated worker sometimes DEFERRED to the foreign queue,
// and deferring suppressed real work. If so the contaminated baseline was
// artificially cheap, and the correction did not add cost — it removed a
// discount. Tested WITHIN task, because task size dominates every raw count.
import fs from "node:fs";
const R7 = "/home/user/ClaudeOrchestrator/build-os/experiments/EXP-0007-three-factor-ablation/results/runs";
const j = (p) => JSON.parse(fs.readFileSync(p, "utf8"));
const waitOf = (d) => {
  const ev = fs.readFileSync(`${R7}/${d}/stream.jsonl`, "utf8").split("\n").filter(Boolean)
    .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
  let w = 0;
  for (const e of ev) {
    const c = e?.message?.content;
    if (!Array.isArray(c) || e.message.role !== "assistant" || c.some((x) => x.type === "tool_use")) continue;
    const t = c.filter((x) => x.type === "text").map((x) => x.text).join(" ").trim();
    if (/^(Holding|Stopping|Standing by)\.?$/i.test(t)) w++;
  }
  return w;
};
console.log("task  arm                 waiting  tools   cost");
for (const t of ["T01", "T02", "T03", "T04"]) {
  const rows = [`${t}.baseline`, `${t}.baseline.r2`, `${t}.baseline.r3`].map((d) => {
    const e = j(`${R7}/${d}/economics.json`);
    return { d, w: waitOf(d), tools: e.tool_calls, cost: e.total_cost_usd };
  });
  for (const r of rows)
    console.log(`${t}    ${r.d.padEnd(20)}${String(r.w).padStart(4)}${String(r.tools).padStart(8)}${r.cost.toFixed(2).padStart(7)}`);
  const a = rows.filter((r) => r.w > 0), b = rows.filter((r) => r.w === 0);
  if (a.length && b.length) {
    const m = (v, k) => v.reduce((s, x) => s + x[k], 0) / v.length;
    console.log(`      -> deferred n=${a.length} tools ${m(a, "tools").toFixed(1)} $${m(a, "cost").toFixed(2)}` +
                ` | did-not-defer n=${b.length} tools ${m(b, "tools").toFixed(1)} $${m(b, "cost").toFixed(2)}`);
  } else console.log(`      -> all ${rows.length} arms on the same side; no within-task contrast`);
}
