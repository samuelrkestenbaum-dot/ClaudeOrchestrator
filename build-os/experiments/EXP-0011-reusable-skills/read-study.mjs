#!/usr/bin/env node
// EXP-0011 — THE ONE READ. Frozen before ANY arm completed (earlier than the
// EXP-0009/0010 precedent, which froze mid-run). Three-way, position-matched,
// section order = the operator's final-read constraints.
//
// AMENDMENT (disclosed): sections 8-10 (SPEED, CONSISTENCY, SCORECARD) added
// at the operator's direction while arm 1 was in flight and before any
// completed cell existed — preregistered metrics per
// build-os/design/PHASE2-SCORECARD.md, all derived from stored artifacts.
// elapsed_s is active worker time by construction (captured at session exit,
// before harness verification).
import fs from "node:fs";
import path from "node:path";
import { classifyCorpus } from "../EXP-0008-microcontext/text-turn-classes.mjs";
import { causesForStream } from "../EXP-0008-microcontext/turn-causes.mjs";
const HERE = path.dirname(new URL(import.meta.url).pathname);
const RUNS = path.join(HERE, "results/runs");
const SEQS = JSON.parse(fs.readFileSync(path.join(HERE, "sequences.json"), "utf8")).sequences;
const j = (p) => { try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return null; } };
const REPS = [1, 2];
const CONFIGS = ["native", "leanrules", "leanskills"];

function streamEvents(dir) {
  try { return fs.readFileSync(path.join(dir, "stream.jsonl"), "utf8").split("\n").filter(Boolean)
    .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean); } catch { return []; }
}

function arm(s, p, c, rep) {
  const name = `${s}${p}.${c}.r${rep}`;
  const dir = path.join(RUNS, name);
  const rr = j(path.join(dir, "run-record.json"));
  if (!rr) return { name, s, p, c, rep, missing: true };
  if (rr.admissible !== true) return { name, s, p, c, rep, inadmissible: true, reason: rr.terminal_reason };
  const e = j(path.join(dir, "economics.json")) || {};
  const a = j(path.join(dir, "acceptance.json"));
  const v = j(path.join(dir, "variant.json")) || {};
  const ev = streamEvents(dir);
  const task = SEQS[s][p - 1];
  let delivered = false;
  for (const x of ev) {
    if (x.type === "system" && x.subtype === "hook_response" && typeof x.output === "string"
        && x.output.includes("prior task records for this repository")) { delivered = true; break; }
  }
  let outsideReads = 0, searches = 0, verifyCycles = 0;
  const toolPath = [];
  for (const x of ev) for (const cb of (x?.message?.content || [])) {
    if (cb?.type !== "tool_use") continue;
    if (toolPath[toolPath.length - 1] !== cb.name) toolPath.push(cb.name);
    if (cb.name === "Bash" && /\btsc\b/.test(String(cb.input?.command || ""))) verifyCycles++;
    if (cb.name === "Grep" || cb.name === "Glob") searches++;
    if (cb.name === "Read") {
      const f = String(cb.input?.file_path || "");
      const rel = f.replace(/^.*exp0007-arm\//, "");
      if (/build-os\/|\.claude\/|CLAUDE\.md|node_modules/.test(rel)) continue;
      if (!rel.endsWith(task.file)) outsideReads++;
    }
  }
  const tt = [];
  for (const x of ev) {
    const cb = x?.message?.content;
    if (!Array.isArray(cb) || x.message?.role !== "assistant" || cb.some((y) => y.type === "tool_use")) continue;
    const t = cb.filter((y) => y.type === "text").map((y) => y.text).join("\n").trim();
    if (t) tt.push({ arm: c, group: c, chars: t.length, text: t });
  }
  const cls = classifyCorpus(tt);
  const cnt = (k) => cls.filter((x) => x.cls === k).length;
  const causes = causesForStream(path.join(dir, "stream.jsonl"));
  return {
    name, s, p, c, rep, inadmissible: false, accepted: a?.accepted === true, promptSha: v.prompt_sha256_16,
    newErrors: a?.condition_2_no_new_errors_elsewhere?.new_error_count ?? 0,
    cost: e.total_cost_usd, uncached: (e.uncached_input_tokens || 0) + (e.cache_creation_input_tokens || 0),
    turns: e.num_turns, elapsed: e.elapsed_s,
    memReads: e.memory_reads ?? 0, memWrites: e.memory_writes_by_worker ?? 0,
    skillReads: e.skill_reads ?? 0, skillInvocations: e.skill_invocations ?? 0,
    installKind: e.install_kind ?? "none", installBytes: e.install_bytes ?? 0, installRules: e.install_rules ?? 0,
    delivered, outsideReads, searches,
    verifyCycles, toolPath: toolPath.join(">"), toolCalls: e.tool_calls ?? null,
    capSearch: cnt("capability_search"), gateDiag: cnt("gate_mechanism_diagnosis"),
    bookkeep: cnt("routing_bookkeeping"), gateChal: cnt("gate_challenge_response"),
    ctrlCalls: causes ? causes.counts.routing_bookkeeping + causes.counts.authority_gate_roundtrip : 0,
  };
}

const G = {};
for (const c of CONFIGS) G[c] = [];
for (const rep of REPS) for (const s of ["G", "M"]) for (let p = 1; p <= 5; p++) for (const c of CONFIGS) G[c].push(arm(s, p, c, rep));
const ok = (c) => G[c].filter((x) => !x.inadmissible && !x.missing);
const mean = (v) => v.length ? v.reduce((a, b) => a + b, 0) / v.length : null;
const fmt = (x, d = 2) => x == null ? "—" : x.toFixed(d);

console.log("=== EXP-0011 READ — native / leanrules / leanskills, 2 seqs x 5 positions x 2 reps ===\n");

console.log("--- 0. IDENTITY ---");
let mism = 0;
for (const s of ["G", "M"]) for (let p = 1; p <= 5; p++) {
  const shas = new Set(CONFIGS.flatMap((c) => ok(c).filter((x) => x.s === s && x.p === p).map((x) => x.promptSha)));
  if (shas.size > 1) { mism++; console.log(`MISMATCH ${s}${p}: ${[...shas].join(" vs ")}`); }
}
console.log(mism ? `${mism} position(s) MISMATCHED — quarantine before interpreting` : "prompt sha uniform at all 10 positions across all three configs");
console.log();

console.log("--- 1. ADMISSIBILITY & ACCEPTANCE (gate: acceptance loss => claim FAILS) ---");
for (const c of CONFIGS) {
  const g = ok(c);
  const bad = G[c].filter((x) => x.missing || x.inadmissible).map((x) => x.name);
  console.log(`${c.padEnd(11)} ${g.length}/20 admissible, ${g.filter((x) => x.accepted).length} accepted${bad.length ? `  missing/inadmissible: ${bad.join(", ")}` : ""}`);
}
console.log();

console.log("--- 2. TOM GUARD (treated arms must hold the lean zeros; skills writes include .claude/skills/) ---");
for (const c of ["leanrules", "leanskills"]) {
  const g = ok(c);
  console.log(`${c.padEnd(11)} memory/skill writes_by_worker=${g.reduce((a, x) => a + x.memWrites, 0)} capability_search=${g.reduce((a, x) => a + x.capSearch, 0)} gate_diag=${g.reduce((a, x) => a + x.gateDiag, 0)} bookkeep=${g.reduce((a, x) => a + x.bookkeep, 0)} ctrl_calls=${g.reduce((a, x) => a + x.ctrlCalls, 0)}`);
}
console.log("(inspect any flags verbatim — completion-report false positives are the known pattern)");
console.log();

console.log("--- 3. DELIVERY & USE EVIDENCE (treated arms) ---");
console.log("arm".padEnd(22) + "install".padStart(14) + "B".padStart(6) + "ctxDeliv".padStart(9) + "memRd".padStart(6) + "skRd".padStart(5) + "skInv".padStart(6));
for (const c of ["leanrules", "leanskills"]) for (const x of ok(c).sort((a, b) => a.rep - b.rep || a.s.localeCompare(b.s) || a.p - b.p))
  console.log(x.name.padEnd(22) + x.installKind.padStart(14) + String(x.installBytes).padStart(6) + (x.delivered ? "yes" : "no").padStart(9) + String(x.memReads).padStart(6) + String(x.skillReads).padStart(5) + String(x.skillInvocations).padStart(6));
const used = (x) => x.c === "leanrules" ? (x.delivered || x.memReads > 0) : (x.skillReads > 0 || x.skillInvocations > 0);
for (const c of ["leanrules", "leanskills"]) {
  const withInstall = ok(c).filter((x) => x.installBytes > 0);
  console.log(`${c}: ${withInstall.length}/20 arms had knowledge installed; used (structural): ${withInstall.filter(used).length}/${withInstall.length}`);
}
console.log();

console.log("--- 4. PRIMARY: POSITION-MATCHED RATIOS vs NATIVE (paired, admissible both sides) ---");
for (const treat of ["leanrules", "leanskills"]) {
  console.log(`\n${treat}/native:`);
  for (const metric of ["cost", "uncached", "turns"]) {
    const ratios = [];
    for (let p = 1; p <= 5; p++) {
      const pairs = [];
      for (const rep of REPS) for (const s of ["G", "M"]) {
        const n = ok("native").find((x) => x.s === s && x.p === p && x.rep === rep);
        const l = ok(treat).find((x) => x.s === s && x.p === p && x.rep === rep);
        if (n && l && n[metric] != null && l[metric] != null) pairs.push(l[metric] / n[metric]);
      }
      ratios.push(mean(pairs));
    }
    console.log(`  ${metric.padEnd(9)} P1..P5: ` + ratios.map((r) => fmt(r).padStart(7)).join(" ") +
      `   P1=${fmt(ratios[0])} late=${fmt(mean([ratios[3], ratios[4]].filter((x) => x != null)))}` +
      ` => ${(() => { const e = ratios[0], l = mean([ratios[3], ratios[4]].filter((x) => x != null)); return e != null && l != null ? (l < e ? "MORE favorable" : l > e ? "LESS favorable" : "flat") : "n/a"; })()}`);
  }
}
console.log("\nMARGINAL (leanskills/leanrules, paired):");
for (const metric of ["cost", "uncached"]) {
  const ratios = [];
  for (let p = 1; p <= 5; p++) {
    const pairs = [];
    for (const rep of REPS) for (const s of ["G", "M"]) {
      const r = ok("leanrules").find((x) => x.s === s && x.p === p && x.rep === rep);
      const k = ok("leanskills").find((x) => x.s === s && x.p === p && x.rep === rep);
      if (r && k && r[metric] != null && k[metric] != null) pairs.push(k[metric] / r[metric]);
    }
    ratios.push(mean(pairs));
  }
  console.log(`  ${metric.padEnd(9)} P1..P5: ` + ratios.map((r) => fmt(r).padStart(7)).join(" "));
}
console.log();

console.log("--- 5. SECONDARY: ABSOLUTE POSITION CURVES (context only) ---");
for (const metric of ["cost", "uncached", "turns"]) {
  for (const c of CONFIGS) {
    const row = [];
    for (let p = 1; p <= 5; p++) row.push(mean(ok(c).filter((x) => x.p === p).map((x) => x[metric]).filter((v) => v != null)));
    console.log(`${metric.padEnd(9)}${c.padEnd(11)}` + row.map((r) => fmt(r, metric === "cost" ? 2 : 0).padStart(9)).join(""));
  }
}
console.log();

console.log("--- 6. STALE/INCORRECT-KNOWLEDGE HARM ---");
for (const c of ["leanrules", "leanskills"]) {
  const w = ok(c).filter((x) => x.installBytes > 0);
  console.log(`${c.padEnd(11)} knowledge-installed arms not accepted: ${w.filter((x) => !x.accepted).length}/${w.length}`);
}
console.log();

console.log("--- 7. REDISCOVERY (outside-task-file reads / searches) per position ---");
for (const c of CONFIGS) {
  const r1 = [], r2 = [];
  for (let p = 1; p <= 5; p++) {
    const gg = ok(c).filter((x) => x.p === p);
    r1.push(mean(gg.map((x) => x.outsideReads))); r2.push(mean(gg.map((x) => x.searches)));
  }
  console.log(`${c.padEnd(11)} outsideReads ` + r1.map((r) => fmt(r, 1).padStart(6)).join("") + "   searches " + r2.map((r) => fmt(r, 1).padStart(6)).join(""));
}

console.log();
console.log("--- 8. SPEED (active worker time; native flat vs treated faster-with-position) ---");
const EARLY = (x) => x.p <= 2, LATE = (x) => x.p >= 4;
for (const metric of ["elapsed", "turns", "toolCalls", "verifyCycles"]) {
  for (const c of CONFIGS) {
    const row = [];
    for (let p = 1; p <= 5; p++) row.push(mean(ok(c).filter((x) => x.p === p).map((x) => x[metric]).filter((v) => v != null)));
    const e = mean(ok(c).filter(EARLY).map((x) => x[metric]).filter((v) => v != null));
    const l = mean(ok(c).filter(LATE).map((x) => x[metric]).filter((v) => v != null));
    console.log(`${metric.padEnd(13)}${c.padEnd(11)}` + row.map((r) => fmt(r, metric === "elapsed" ? 0 : 1).padStart(8)).join("") +
      `   early=${fmt(e, 0)} late=${fmt(l, 0)} (${e && l ? fmt(l / e) + "x" : "—"})`);
  }
}
console.log("accepted-only elapsed, early vs late:");
for (const c of CONFIGS) {
  const acc = ok(c).filter((x) => x.accepted);
  console.log(`  ${c.padEnd(11)} early=${fmt(mean(acc.filter(EARLY).map((x) => x.elapsed)), 0)}s late=${fmt(mean(acc.filter(LATE).map((x) => x.elapsed)), 0)}s`);
}
console.log();
console.log("--- 9. CONSISTENCY (tightening distributions, especially the bad tail) ---");
const sd = (v) => { if (v.length < 2) return null; const m = mean(v); return Math.sqrt(v.reduce((a, x) => a + (x - m) ** 2, 0) / (v.length - 1)); };
const cv = (v) => { const m = mean(v), s = sd(v); return m && s != null ? s / m : null; };
const p90 = (v) => { if (!v.length) return null; const s = [...v].sort((a, b) => a - b); return s[Math.min(s.length - 1, Math.ceil(0.9 * s.length) - 1)]; };
console.log("config".padEnd(11) + "acc".padStart(6) + "cvCost".padStart(8) + "cvTurns".padStart(9) + "p90el".padStart(7) + "maxEl".padStart(7) + "maxCost".padStart(9) + "newErrArms".padStart(11) + "paths".padStart(7) + "modeShare".padStart(10));
for (const c of CONFIGS) {
  const g = ok(c);
  const el = g.map((x) => x.elapsed).filter((v) => v != null);
  const paths = g.map((x) => x.toolPath);
  const pc = {}; for (const t of paths) pc[t] = (pc[t] || 0) + 1;
  const modeShare = paths.length ? Math.max(...Object.values(pc)) / paths.length : null;
  const newErr = g.filter((x) => x.newErrors > 0).length;
  console.log(c.padEnd(11) + `${g.filter((x) => x.accepted).length}/${g.length}`.padStart(6) +
    fmt(cv(g.map((x) => x.cost).filter((v) => v != null))).padStart(8) + fmt(cv(g.map((x) => x.turns).filter((v) => v != null))).padStart(9) +
    fmt(p90(el), 0).padStart(7) + fmt(el.length ? Math.max(...el) : null, 0).padStart(7) + fmt(g.length ? Math.max(...g.map((x) => x.cost ?? 0)) : null).padStart(9) +
    String(newErr).padStart(11) + String(Object.keys(pc).length).padStart(7) + fmt(modeShare).padStart(10));
}
console.log("early-vs-experienced variance (cvCost early | late; n=8 each — order statistics, not gospel):");
for (const c of CONFIGS) {
  const e = cv(ok(c).filter(EARLY).map((x) => x.cost).filter((v) => v != null));
  const l = cv(ok(c).filter(LATE).map((x) => x.cost).filter((v) => v != null));
  console.log(`  ${c.padEnd(11)} ${fmt(e)} | ${fmt(l)}`);
}
console.log("retries/timeouts on disk (preserved attempts, by config):");
for (const c of CONFIGS) {
  const n = fs.readdirSync(RUNS).filter((d) => d.includes(`.${c}.`) && /attempt|debris|restart/.test(d)).length;
  console.log(`  ${c.padEnd(11)} ${n}`);
}
console.log();
console.log("--- 10. SCORECARD (native | treated-early | treated-experienced; per PHASE2-SCORECARD.md) ---");
for (const treat of ["leanrules", "leanskills"]) {
  console.log(`\n${treat}:`);
  const natAll = ok("native"), tE = ok(treat).filter(EARLY), tL = ok(treat).filter(LATE);
  const row = (label, f, d = 2) => console.log(`  ${label.padEnd(24)}${fmt(f(natAll), d).padStart(9)}${fmt(f(tE), d).padStart(9)}${fmt(f(tL), d).padStart(9)}`);
  console.log(`  ${"dimension".padEnd(24)}${"native".padStart(9)}${"early".padStart(9)}${"exp'd".padStart(9)}`);
  row("cost (mean)", (g) => mean(g.map((x) => x.cost).filter((v) => v != null)));
  row("elapsed (mean s)", (g) => mean(g.map((x) => x.elapsed).filter((v) => v != null)), 0);
  row("turns (mean)", (g) => mean(g.map((x) => x.turns).filter((v) => v != null)), 1);
  row("p90 elapsed", (g) => p90(g.map((x) => x.elapsed).filter((v) => v != null)), 0);
  row("cv cost", (g) => cv(g.map((x) => x.cost).filter((v) => v != null)));
  row("accept rate", (g) => g.length ? g.filter((x) => x.accepted).length / g.length : null);
  row("rediscovery reads", (g) => mean(g.map((x) => x.outsideReads)), 1);
}
