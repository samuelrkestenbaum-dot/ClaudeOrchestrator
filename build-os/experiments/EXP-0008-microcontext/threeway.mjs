// Three-way comparison: frozen native reference / contaminated Gravito baseline /
// corrected uncontaminated Gravito baseline.
//
// SPREAD BEFORE MEANS. Every metric is reported per-arm first; aggregate means are
// printed only alongside the range and CV of the cells they summarise.

import fs from "node:fs";
import path from "node:path";
import { causesForStream } from "/home/user/ClaudeOrchestrator/build-os/experiments/EXP-0008-microcontext/turn-causes.mjs";

const R7 = "/home/user/ClaudeOrchestrator/build-os/experiments/EXP-0007-three-factor-ablation/results/runs";
const R6 = "/home/user/ClaudeOrchestrator/build-os/experiments/EXP-0006-operational-uic/results/runs";

const TASKS = ["T01", "T02", "T03", "T04"];

const j = (p) => { try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return null; } };

/** Text-only assistant turns: assistant messages carrying text and NO tool_use. */
function textOnly(streamPath) {
  let ev = [];
  try {
    ev = fs.readFileSync(streamPath, "utf8").split("\n").filter(Boolean)
      .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
  } catch { return { n: 0, waiting: 0, queueRefs: 0 }; }
  let n = 0, waiting = 0, queueRefs = 0;
  for (const e of ev) {
    const c = e?.message?.content;
    if (!Array.isArray(c) || e.message.role !== "assistant") continue;
    if (c.some((x) => x.type === "tool_use")) continue;
    const t = c.filter((x) => x.type === "text").map((x) => x.text).join(" ").trim();
    if (!t) continue;
    n++;
    if (/^(Holding|Stopping|Standing by)\.?$/i.test(t)) waiting++;
    if (/#(4\d|5\d)\b|queue\.json|needs your go/i.test(t)) queueRefs++;
  }
  return { n, waiting, queueRefs };
}

function arm(dir) {
  const e = j(path.join(dir, "economics.json"));
  const a = j(path.join(dir, "acceptance.json"));
  if (!e) return null;
  const causes = causesForStream(path.join(dir, "stream.jsonl"));
  const t = textOnly(path.join(dir, "stream.jsonl"));
  const turns = e.num_turns;
  const ctx = (e.uncached_input_tokens || 0) + (e.cache_read_input_tokens || 0) + (e.cache_creation_input_tokens || 0);
  return {
    dir: path.basename(dir),
    accepted: a ? a.accepted === true : null,
    turns,
    toolCalls: e.tool_calls,
    textOnly: t.n,
    waiting: t.waiting,
    queueRefs: t.queueRefs,
    ctxPerTurn: ctx / turns,
    outPerTurn: (e.output_tokens || 0) / turns,
    cost: e.total_cost_usd,
    uncached: (e.uncached_input_tokens || 0) + (e.cache_creation_input_tokens || 0),
    search: causes ? causes.counts.gravito_search : null,
    implReads: causes ? causes.counts.gravito_implementation_read : null,
    bookkeeping: causes ? causes.counts.routing_bookkeeping + causes.counts.authority_gate_roundtrip : null,
    elapsed: e.elapsed_s,
  };
}

function collect(root, dirs) {
  return dirs.map((d) => arm(path.join(root, d))).filter(Boolean);
}

const GROUPS = {
  native: collect(R6, TASKS.map((t) => `${t}.native`)),
  contaminated: collect(R7, TASKS.flatMap((t) => [`${t}.baseline`, `${t}.baseline.r2`, `${t}.baseline.r3`])),
  corrected: collect(R7, TASKS.flatMap((t) => [`${t}.corrected`, `${t}.corrected.r2`, `${t}.corrected.r3`])),
};

const METRICS = [
  ["turns", "turns", 1],
  ["toolCalls", "tool calls", 1],
  ["textOnly", "text-only turns", 1],
  ["ctxPerTurn", "context/turn (tok)", 0],
  ["outPerTurn", "output/turn (tok)", 0],
  ["cost", "cost USD", 3],
  ["uncached", "uncached tok", 0],
  ["search", "gravito_search", 1],
  ["implReads", "impl reads", 1],
  ["bookkeeping", "routing+authority", 1],
  ["waiting", "waiting-posture", 1],
  ["queueRefs", "queue refs", 1],
];

const mean = (v) => v.reduce((a, b) => a + b, 0) / v.length;
const cv = (v) => { const m = mean(v); const sd = Math.sqrt(v.reduce((a, b) => a + (b - m) ** 2, 0) / (v.length - 1 || 1)); return m ? sd / m : 0; };

// ---- 1. PER-ARM TABLE (spread visible before any mean) --------------------
console.log("=== PER-ARM (every cell, no aggregation) ===\n");
for (const [g, arms] of Object.entries(GROUPS)) {
  console.log(`-- ${g} (n=${arms.length}) --`);
  console.log("arm".padEnd(22) + "acc turns tools txtOnly  ctx/t  out/t   cost  srch impl bkkp wait qref");
  for (const a of arms) {
    console.log(
      a.dir.padEnd(22) +
      String(a.accepted ? "Y" : "N").padEnd(4) +
      String(a.turns).padStart(5) + String(a.toolCalls).padStart(6) +
      String(a.textOnly).padStart(8) + String(Math.round(a.ctxPerTurn)).padStart(7) +
      String(Math.round(a.outPerTurn)).padStart(7) + a.cost.toFixed(2).padStart(7) +
      String(a.search).padStart(6) + String(a.implReads).padStart(5) +
      String(a.bookkeeping).padStart(5) + String(a.waiting).padStart(5) + String(a.queueRefs).padStart(5));
  }
  console.log();
}

// ---- 2. WITHIN-CELL SPREAD (same task, same config, different rep) --------
console.log("=== WITHIN-CELL SPREAD (identical task+config, reps differ) ===\n");
for (const g of ["contaminated", "corrected"]) {
  console.log(`-- ${g} --`);
  console.log("cell  metric              min     max   ratio    CV");
  for (const t of TASKS) {
    const cells = GROUPS[g].filter((a) => a.dir.startsWith(t));
    if (cells.length < 2) { console.log(`${t}    (n=${cells.length}, no within-cell replication)`); continue; }
    for (const [k, label] of [["turns", "turns"], ["toolCalls", "tool calls"], ["implReads", "impl reads"], ["cost", "cost"], ["textOnly", "text-only"]]) {
      const v = cells.map((c) => c[k]);
      const mn = Math.min(...v), mx = Math.max(...v);
      console.log(`${t}    ${label.padEnd(16)}${mn.toFixed(2).padStart(8)}${mx.toFixed(2).padStart(8)}` +
        `${(mn ? mx / mn : Infinity).toFixed(2).padStart(8)}${(cv(v) * 100).toFixed(0).padStart(6)}%`);
    }
  }
  console.log();
}

// ---- 3. AGGREGATE, with the spread it hides -------------------------------
console.log("=== AGGREGATE MEANS (with the range each mean conceals) ===\n");
console.log("metric".padEnd(20) + "native".padStart(20) + "contaminated".padStart(22) + "corrected".padStart(22));
for (const [k, label, dp] of METRICS) {
  const cells = ["native", "contaminated", "corrected"].map((g) => {
    const v = GROUPS[g].map((a) => a[k]).filter((x) => x !== null && x !== undefined);
    if (!v.length) return "—";
    return `${mean(v).toFixed(dp)} [${Math.min(...v).toFixed(dp)}-${Math.max(...v).toFixed(dp)}]`;
  });
  console.log(label.padEnd(20) + cells[0].padStart(20) + cells[1].padStart(22) + cells[2].padStart(22));
}
console.log();

// ---- 4. PAIRED BY TASK (the only comparison the design supports) ----------
console.log("=== PAIRED BY TASK — corrected vs contaminated (task-matched means) ===\n");
console.log("metric".padEnd(20) + "task-mean contam".padStart(18) + "task-mean corr".padStart(16) + "ratio".padStart(8) + "  tasks improved");
for (const [k, label, dp] of METRICS) {
  let sc = 0, ss = 0, better = 0, n = 0;
  for (const t of TASKS) {
    const c = GROUPS.contaminated.filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    const r = GROUPS.corrected.filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    if (!c.length || !r.length) continue;
    n++; sc += mean(c); ss += mean(r);
    if (mean(r) < mean(c)) better++;
  }
  if (!n) continue;
  console.log(label.padEnd(20) + (sc / n).toFixed(dp).padStart(18) + (ss / n).toFixed(dp).padStart(16) +
    (sc ? (ss / sc).toFixed(2) : "—").padStart(8) + `  ${better}/${n}`);
}
console.log();

// ---- 4b. SEPARATION TEST — does the effect exceed the within-cell spread? --
//
// n=4 tasks makes a mean-ratio worthless on its own. The honest question per
// task is whether the three corrected reps fall ENTIRELY on one side of the
// three contaminated reps. Under exchangeability of 6 values, complete
// separation in a NAMED direction has probability C(6,3)^-1 = 1/20 = 0.05;
// two-sided (direction read from the data, which is the honest description for
// every metric here except the ones contamination-removal was predicted to
// lower) it is 0.10. Four tasks separating the same way, two-sided:
// 2 x 0.05^4 = 1.25e-5.
console.log("=== SEPARATION BY TASK — corrected reps vs contaminated reps ===\n");
console.log("metric".padEnd(20) + "  T01     T02     T03     T04     tasks separated (direction)");
for (const [k, label] of METRICS) {
  const cells = TASKS.map((t) => {
    const c = GROUPS.contaminated.filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    const r = GROUPS.corrected.filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    if (c.length < 2 || r.length < 2) return { s: "n/a", dir: null };
    if (Math.max(...r) < Math.min(...c)) return { s: "LOWER", dir: -1 };
    if (Math.min(...r) > Math.max(...c)) return { s: "HIGHER", dir: 1 };
    return { s: "overlap", dir: 0 };
  });
  const lo = cells.filter((c) => c.dir === -1).length, hi = cells.filter((c) => c.dir === 1).length;
  const verdict = lo === 4 ? "4/4 LOWER  p=1.3e-5" : hi === 4 ? "4/4 HIGHER  p=1.3e-5"
    : lo || hi ? `${lo} lower, ${hi} higher — NOT consistent` : "none — inside the noise";
  console.log(label.padEnd(20) + cells.map((c) => c.s.padStart(8)).join("") + "  " + verdict);
}
console.log();

console.log("=== PAIRED BY TASK — corrected vs native (task-matched, native n=1/task) ===\n");
console.log("metric".padEnd(20) + "native".padStart(12) + "corrected".padStart(12) + "ratio".padStart(8));
for (const [k, label, dp] of METRICS) {
  let sn = 0, ss = 0, n = 0;
  for (const t of TASKS) {
    const nv = GROUPS.native.filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    const r = GROUPS.corrected.filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    if (!nv.length || !r.length) continue;
    n++; sn += mean(nv); ss += mean(r);
  }
  if (!n) continue;
  console.log(label.padEnd(20) + (sn / n).toFixed(dp).padStart(12) + (ss / n).toFixed(dp).padStart(12) +
    (sn ? (ss / sn).toFixed(2) : "—").padStart(8));
}

console.log("\n=== BOTH GRAVITO GROUPS vs NATIVE (task-matched) — did the fix move the headline? ===\n");
console.log("metric".padEnd(20) + "native".padStart(12) + "contam/nat".padStart(12) + "corr/nat".padStart(10) + "  change");
for (const [k, label, dp] of METRICS) {
  let sn = 0, sc = 0, sr = 0, n = 0;
  for (const t of TASKS) {
    const nv = GROUPS.native.filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    const c = GROUPS.contaminated.filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    const r = GROUPS.corrected.filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    if (!nv.length || !c.length || !r.length) continue;
    n++; sn += mean(nv); sc += mean(c); sr += mean(r);
  }
  if (!n || !sn) { console.log(label.padEnd(20) + "(native is 0 — ratio undefined)".padStart(34)); continue; }
  const a = sc / sn, b = sr / sn;
  console.log(label.padEnd(20) + (sn / n).toFixed(dp).padStart(12) + a.toFixed(2).padStart(12) + b.toFixed(2).padStart(10) +
    "  " + (b < a ? "improved" : b > a ? "WORSE" : "unchanged"));
}
