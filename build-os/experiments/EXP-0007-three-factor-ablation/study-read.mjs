// THE RUNNABLE-VERIFICATION STUDY — freeze-and-read.
//
// Order is fixed by operator ruling and enforced by layout:
//   1. per-arm cells with ceiling proximity (censoring visible everywhere)
//   2. within-cell spread
//   3. FORK METRICS: cost + uncached tokens, task-paired, 2x2
//   4. separation test (runnable gravito vs runnable native, per task)
//   5. MECHANISM: turn classes, exhaustion, re-reporting, text-only turns
//   6. elapsed as context only
import fs from "node:fs";
import path from "node:path";
import { causesForStream } from "/home/user/ClaudeOrchestrator/build-os/experiments/EXP-0008-microcontext/turn-causes.mjs";
import { classifyCorpus } from "/home/user/ClaudeOrchestrator/build-os/experiments/EXP-0008-microcontext/text-turn-classes.mjs";

const R7 = "/home/user/ClaudeOrchestrator/build-os/experiments/EXP-0007-three-factor-ablation/results/runs";
const TASKS = ["T01", "T02", "T03", "T04"];
const CEIL = 1200;
const j = (p) => { try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return null; } };

function textTurns(dir) {
  let ev = [];
  try {
    ev = fs.readFileSync(path.join(dir, "stream.jsonl"), "utf8").split("\n").filter(Boolean)
      .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
  } catch { return []; }
  const out = [];
  for (const e of ev) {
    const c = e?.message?.content;
    if (!Array.isArray(c) || e.message.role !== "assistant" || c.some((x) => x.type === "tool_use")) continue;
    const t = c.filter((x) => x.type === "text").map((x) => x.text).join("\n").trim();
    if (t) out.push(t);
  }
  return out;
}
const EXHAUST = /exhaust|concession|cross-surface|untested surface|unsearched|capability (map|registry)|another surface holds|gate-stop/i;

function arm(dirName) {
  const dir = path.join(R7, dirName);
  const e = j(path.join(dir, "economics.json"));
  const rr = j(path.join(dir, "run-record.json"));
  const a = j(path.join(dir, "acceptance.json"));
  if (!rr) return null;
  if (rr.admissible !== true) return { dir: dirName, inadmissible: true, reason: rr.terminal_reason };
  const causes = causesForStream(path.join(dir, "stream.jsonl"));
  const ts = textTurns(dir);
  const turns = e.num_turns;
  return {
    dir: dirName, inadmissible: false,
    accepted: a?.accepted === true,
    cost: e.total_cost_usd,
    uncached: (e.uncached_input_tokens || 0) + (e.cache_creation_input_tokens || 0),
    turns, toolCalls: e.tool_calls,
    textOnly: ts.length,
    exhaust: ts.filter((t) => EXHAUST.test(t)).length,
    finalReports: ts.filter((t) => t.length >= 1500).length,
    implReads: causes ? causes.counts.gravito_implementation_read : null,
    search: causes ? causes.counts.gravito_search : null,
    bookkeeping: causes ? causes.counts.routing_bookkeeping + causes.counts.authority_gate_roundtrip : null,
    verification: causes ? causes.counts.verification : null,
    elapsed: e.elapsed_s, ceilPct: e.elapsed_s / CEIL,
  };
}

const CELLS = {
  "native.starved":    (t, r) => `${t}.native${r > 1 ? `.r${r}` : ""}`,
  "native.runnable":   (t, r) => `${t}.native.runnable${r > 1 ? `.r${r}` : ""}`,
  "gravito.starved":   (t, r) => `${t}.corrected${r > 1 ? `.r${r}` : ""}`,
  "gravito.runnable":  (t, r) => `${t}.corrected.runnable${r > 1 ? `.r${r}` : ""}`,
};
const G = {};
for (const [g, f] of Object.entries(CELLS))
  G[g] = TASKS.flatMap((t) => [1, 2, 3].map((r) => arm(f(t, r)))).filter(Boolean);

const ok = (g) => G[g].filter((a) => !a.inadmissible);
const mean = (v) => v.reduce((x, y) => x + y, 0) / v.length;
const cv = (v) => { const m = mean(v); const sd = Math.sqrt(v.reduce((a, b) => a + (b - m) ** 2, 0) / (v.length - 1 || 1)); return m ? sd / m : 0; };

// ---- 1. per-arm ----
console.log("=== 1. PER-ARM (all cells; ceiling proximity everywhere) ===\n");
for (const g of Object.keys(G)) {
  console.log(`-- ${g} (${ok(g).length} admissible of ${G[g].length}) --`);
  console.log("arm".padEnd(26) + "acc  cost  uncach(k) turns tools txt exh rpts impl srch bkkp vrfy  elap  %ceil");
  for (const a of G[g]) {
    if (a.inadmissible) { console.log(a.dir.padEnd(26) + `INADMISSIBLE (${a.reason})`); continue; }
    console.log(a.dir.padEnd(26) + (a.accepted ? "Y" : "N").padEnd(4) +
      a.cost.toFixed(2).padStart(6) + (a.uncached / 1000).toFixed(0).padStart(10) +
      String(a.turns).padStart(6) + String(a.toolCalls).padStart(6) + String(a.textOnly).padStart(4) +
      String(a.exhaust).padStart(4) + String(a.finalReports).padStart(5) + String(a.implReads).padStart(5) +
      String(a.search).padStart(5) + String(a.bookkeeping).padStart(5) + String(a.verification).padStart(5) +
      a.elapsed.toFixed(0).padStart(6) + (a.ceilPct * 100).toFixed(0).padStart(6) + "%");
  }
  console.log();
}

// ---- 2. within-cell spread ----
console.log("=== 2. WITHIN-CELL SPREAD (cost) ===\n");
console.log("cell".padEnd(10) + Object.keys(G).map((g) => g.padStart(22)).join(""));
for (const t of TASKS) {
  const row = Object.keys(G).map((g) => {
    const v = ok(g).filter((a) => a.dir.startsWith(t)).map((a) => a.cost);
    if (v.length < 2) return `n=${v.length}`.padStart(22);
    return `${Math.min(...v).toFixed(2)}-${Math.max(...v).toFixed(2)} cv${(cv(v) * 100).toFixed(0)}%`.padStart(22);
  });
  console.log(t.padEnd(10) + row.join(""));
}
console.log();

// ---- 3. THE FORK: cost + uncached, task-paired 2x2 ----
console.log("=== 3. FORK METRICS — task-paired means, the 2x2 ===\n");
for (const [k, label, dp] of [["cost", "cost USD", 3], ["uncached", "uncached tokens", 0]]) {
  console.log(`-- ${label} --`);
  console.log("task".padEnd(6) + "nat.starv".padStart(11) + "nat.run".padStart(10) + "grav.starv".padStart(12) + "grav.run".padStart(11) +
    "  gap.starved  gap.runnable");
  let gs = [], gr = [];
  for (const t of TASKS) {
    const m = Object.fromEntries(Object.keys(G).map((g) => {
      const v = ok(g).filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
      return [g, v.length ? mean(v) : null];
    }));
    const gapS = m["gravito.starved"] / m["native.starved"];
    const gapR = m["gravito.runnable"] / m["native.runnable"];
    gs.push(gapS); gr.push(gapR);
    console.log(t.padEnd(6) + m["native.starved"].toFixed(dp).padStart(11) + m["native.runnable"].toFixed(dp).padStart(10) +
      m["gravito.starved"].toFixed(dp).padStart(12) + m["gravito.runnable"].toFixed(dp).padStart(11) +
      gapS.toFixed(2).padStart(12) + "x" + gapR.toFixed(2).padStart(12) + "x");
  }
  console.log("MEAN".padEnd(6) + "".padStart(44) + mean(gs).toFixed(2).padStart(12) + "x" + mean(gr).toFixed(2).padStart(12) + "x\n");
}

// ---- 4. separation: runnable gravito vs runnable native ----
console.log("=== 4. SEPARATION — gravito.runnable vs native.runnable, per task ===\n");
for (const [k, label] of [["cost", "cost"], ["uncached", "uncached"], ["turns", "turns"], ["textOnly", "text-only"]]) {
  const cells = TASKS.map((t) => {
    const n = ok("native.runnable").filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    const g = ok("gravito.runnable").filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    if (n.length < 2 || g.length < 2) return "n/a";
    if (Math.min(...g) > Math.max(...n)) return "G.HIGHER";
    if (Math.max(...g) < Math.min(...n)) return "G.LOWER";
    return "overlap";
  });
  const hi = cells.filter((c) => c === "G.HIGHER").length;
  console.log(label.padEnd(12) + cells.map((c) => c.padStart(10)).join("") +
    `   ${hi}/4 separated higher${hi === 4 ? "  p=1.3e-5 (two-sided)" : ""}`);
}
console.log();

// ---- 5. mechanism ----
console.log("=== 5. MECHANISM (per-arm means, runnable condition) ===\n");
console.log("metric".padEnd(22) + "nat.run".padStart(10) + "grav.run".padStart(10) + "   (grav.starved for reference)");
for (const [k, label] of [["textOnly", "text-only turns"], ["exhaust", "exhaustion refs"], ["finalReports", "final reports"],
                          ["implReads", "impl reads"], ["search", "gravito search"], ["bookkeeping", "bookkeeping+gate"],
                          ["verification", "verification calls"], ["turns", "turns"], ["toolCalls", "tool calls"]]) {
  const f = (g) => mean(ok(g).map((a) => a[k])).toFixed(1);
  console.log(label.padEnd(22) + f("native.runnable").padStart(10) + f("gravito.runnable").padStart(10) + `   (${f("gravito.starved")})`);
}
console.log();

// ---- 6. elapsed, context only ----
console.log("=== 6. ELAPSED (context only; runnable pays compiler round-trips in BOTH arms) ===\n");
for (const g of Object.keys(G)) {
  const v = ok(g).map((a) => a.elapsed);
  const near = ok(g).filter((a) => a.ceilPct >= 0.8).length;
  console.log(g.padEnd(18) + `mean ${mean(v).toFixed(0)}s  range ${Math.min(...v).toFixed(0)}-${Math.max(...v).toFixed(0)}s` +
    `  arms >=80% of ceiling: ${near}` + (g === "gravito.runnable" ? `  (+1 timed out and was re-run)` : ""));
}
const inad = Object.values(G).flat().filter((a) => a.inadmissible);
console.log(`\ninadmissible arms in final set: ${inad.length}${inad.length ? " — " + inad.map((a) => a.dir).join(", ") : ""}`);
console.log(`acceptance: ${Object.values(G).flat().filter((a) => !a.inadmissible && a.accepted).length}/${Object.values(G).flat().filter((a) => !a.inadmissible).length} admissible arms accepted`);
