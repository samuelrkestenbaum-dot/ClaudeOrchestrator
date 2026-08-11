// THE DECISIVE READ — Native -> Current -> Lean, frozen classifier, no new metrics.
// Order: spread -> economics -> TOM classes -> acceptance. D2's branches are the verdict frame.
import fs from "node:fs";
import path from "node:path";
import { causesForStream } from "/home/user/ClaudeOrchestrator/build-os/experiments/EXP-0008-microcontext/turn-causes.mjs";
import { classifyCorpus } from "/home/user/ClaudeOrchestrator/build-os/experiments/EXP-0008-microcontext/text-turn-classes.mjs";

const R7 = "/home/user/ClaudeOrchestrator/build-os/experiments/EXP-0007-three-factor-ablation/results/runs";
const TASKS = ["T01", "T02", "T03", "T04"];
const j = (p) => { try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return null; } };

function textTurnsOf(dir, arm) {
  let ev = [];
  try { ev = fs.readFileSync(path.join(dir, "stream.jsonl"), "utf8").split("\n").filter(Boolean)
    .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean); } catch { return []; }
  const out = [];
  for (const e of ev) {
    const c = e?.message?.content;
    if (!Array.isArray(c) || e.message.role !== "assistant" || c.some((x) => x.type === "tool_use")) continue;
    const t = c.filter((x) => x.type === "text").map((x) => x.text).join("\n").trim();
    if (t) out.push({ arm, group: arm, chars: t.length, text: t });
  }
  return out;
}

function arm(dirName) {
  const dir = path.join(R7, dirName);
  const e = j(path.join(dir, "economics.json"));
  const rr = j(path.join(dir, "run-record.json"));
  const a = j(path.join(dir, "acceptance.json"));
  if (!rr) return null;
  if (rr.admissible !== true) return { dir: dirName, inadmissible: true, reason: rr.terminal_reason };
  const causes = causesForStream(path.join(dir, "stream.jsonl"));
  const tt = textTurnsOf(dir, dirName);
  const cls = classifyCorpus(tt);
  const c = (k) => cls.filter((x) => x.cls === k).length;
  const v = j(path.join(dir, "variant.json"));
  return {
    dir: dirName, inadmissible: false, accepted: a?.accepted === true,
    src: v?.source_identity ? `${v.source_identity.requested_ref}` : "-",
    cost: e.total_cost_usd,
    uncached: (e.uncached_input_tokens || 0) + (e.cache_creation_input_tokens || 0),
    turns: e.num_turns, textOnly: tt.length,
    finalReports: c("final_report"),
    gateDiag: c("gate_mechanism_diagnosis"),
    capSearch: c("capability_search"),
    bookkeepTxt: c("routing_bookkeeping"),
    gateChal: c("gate_challenge_response"),
    ctrlCalls: causes ? causes.counts.routing_bookkeeping + causes.counts.authority_gate_roundtrip : null,
    implReads: causes ? causes.counts.gravito_implementation_read : null,
    search: causes ? causes.counts.gravito_search : null,
    elapsed: e.elapsed_s, ceilPct: e.elapsed_s / 1200,
  };
}

const G = {
  native: TASKS.flatMap((t) => [1, 2, 3].map((r) => arm(`${t}.native.runnable${r > 1 ? `.r${r}` : ""}`))).filter(Boolean),
  current: TASKS.flatMap((t) => [1, 2, 3].map((r) => arm(`${t}.corrected.runnable${r > 1 ? `.r${r}` : ""}`))).filter(Boolean),
  lean: TASKS.flatMap((t) => [4, 5, 6].map((r) => arm(`${t}.lean.runnable.r${r}`))).filter(Boolean),
};
const ok = (g) => G[g].filter((a) => !a.inadmissible);
const mean = (v) => v.reduce((x, y) => x + y, 0) / v.length;

console.log("=== 1. PER-ARM ===\n");
for (const g of Object.keys(G)) {
  console.log(`-- ${g} (${ok(g).length} admissible of ${G[g].length}) --`);
  console.log("arm".padEnd(26) + "acc  src      cost uncach(k) turns txt rpts diag capS bkkpT chal ctrlC impl srch  %ceil");
  for (const a of G[g]) {
    if (a.inadmissible) { console.log(a.dir.padEnd(26) + `INADMISSIBLE (${a.reason})`); continue; }
    console.log(a.dir.padEnd(26) + (a.accepted ? "Y" : "N").padEnd(4) + String(a.src).padEnd(8) +
      a.cost.toFixed(2).padStart(6) + (a.uncached / 1000).toFixed(0).padStart(9) +
      String(a.turns).padStart(6) + String(a.textOnly).padStart(4) + String(a.finalReports).padStart(5) +
      String(a.gateDiag).padStart(5) + String(a.capSearch).padStart(5) + String(a.bookkeepTxt).padStart(6) +
      String(a.gateChal).padStart(5) + String(a.ctrlCalls).padStart(6) + String(a.implReads).padStart(5) +
      String(a.search).padStart(5) + (a.ceilPct * 100).toFixed(0).padStart(6) + "%");
  }
  console.log();
}

console.log("=== 2. WITHIN-CELL COST SPREAD (lean) ===\n");
for (const t of TASKS) {
  const v = ok("lean").filter((a) => a.dir.startsWith(t)).map((a) => a.cost);
  if (v.length >= 2) console.log(`${t}  ${Math.min(...v).toFixed(2)}-${Math.max(...v).toFixed(2)}  n=${v.length}`);
  else console.log(`${t}  n=${v.length}`);
}
console.log();

console.log("=== 3. THE COMBINED TABLE — task-paired means ===\n");
const ROWS = [
  ["cost", "cost USD", 3], ["uncached", "uncached tok", 0], ["turns", "turns", 1],
  ["textOnly", "text-only turns", 1], ["finalReports", "repeat final reports", 2],
  ["ctrlCalls", "control round-trips", 1], ["capSearch", "capability search", 2],
  ["gateDiag", "gate diagnosis", 2], ["bookkeepTxt", "routing bookkeeping (txt)", 2],
  ["gateChal", "gate challenge", 2], ["implReads", "impl reads", 1], ["search", "gravito search", 1],
];
console.log("metric".padEnd(27) + "native".padStart(10) + "current".padStart(11) + "lean".padStart(10) +
  "  cur/nat  lean/nat  lean/cur");
for (const [k, label, dp] of ROWS) {
  const m = {};
  for (const g of Object.keys(G)) {
    let s = 0, n = 0;
    for (const t of TASKS) {
      const v = ok(g).filter((a) => a.dir.startsWith(t)).map((a) => a[k]).filter((x) => x != null);
      if (v.length) { s += mean(v); n++; }
    }
    m[g] = n ? s / n : null;
  }
  const r = (a, b) => (m[a] != null && m[b] ? (m[a] / m[b]).toFixed(2) + "x" : "—");
  console.log(label.padEnd(27) + m.native.toFixed(dp).padStart(10) + m.current.toFixed(dp).padStart(11) +
    (m.lean != null ? m.lean.toFixed(dp) : "—").padStart(10) +
    r("current", "native").padStart(9) + r("lean", "native").padStart(10) + r("lean", "current").padStart(10));
}
console.log();

console.log("=== 4. SEPARATION — lean vs current, per task (3v3 reps) ===\n");
for (const [k, label] of [["cost", "cost"], ["uncached", "uncached"], ["turns", "turns"], ["finalReports", "final reports"], ["ctrlCalls", "control round-trips"]]) {
  const cells = TASKS.map((t) => {
    const c = ok("current").filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    const l = ok("lean").filter((a) => a.dir.startsWith(t)).map((a) => a[k]);
    if (c.length < 2 || l.length < 2) return "n/a";
    if (Math.max(...l) < Math.min(...c)) return "L.LOWER";
    if (Math.min(...l) > Math.max(...c)) return "L.HIGHER";
    return "overlap";
  });
  const lo = cells.filter((x) => x === "L.LOWER").length;
  console.log(label.padEnd(22) + cells.map((x) => x.padStart(9)).join("") + `   ${lo}/4 fully lower`);
}
console.log();
console.log("=== 5. ACCEPTANCE ===");
for (const g of Object.keys(G)) console.log(`${g.padEnd(9)} ${ok(g).filter((a) => a.accepted).length}/${ok(g).length} accepted, ${G[g].filter((a) => a.inadmissible).length} inadmissible`);
