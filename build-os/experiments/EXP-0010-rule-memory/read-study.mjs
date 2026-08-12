#!/usr/bin/env node
// EXP-0010 — THE ONE READ. Frozen while the leanrules arms were still running,
// so the analysis is preregistered code. Comparator: EXP-0009's frozen native
// arms, position-matched by construction (same prompt builder, sha-verified).
// Section order = the operator's final-read constraints, unchanged from
// EXP-0009's reader.
import fs from "node:fs";
import path from "node:path";
import { classifyCorpus } from "../EXP-0008-microcontext/text-turn-classes.mjs";
import { causesForStream } from "../EXP-0008-microcontext/turn-causes.mjs";
const HERE = path.dirname(new URL(import.meta.url).pathname);
const R10 = path.join(HERE, "results/runs");
const R9 = path.join(HERE, "../EXP-0009-memory-compounding/results/runs");
const SEQS = JSON.parse(fs.readFileSync(path.join(HERE, "../EXP-0009-memory-compounding/sequences.json"), "utf8")).sequences;
const j = (p) => { try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return null; } };
const REPS = [1, 2];

function streamEvents(dir) {
  try { return fs.readFileSync(path.join(dir, "stream.jsonl"), "utf8").split("\n").filter(Boolean)
    .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean); } catch { return []; }
}

function arm(root, s, p, c, rep) {
  const name = `${s}${p}.${c}.r${rep}`;
  const dir = path.join(root, name);
  const rr = j(path.join(dir, "run-record.json"));
  if (!rr) return { name, s, p, c, rep, missing: true };
  if (rr.admissible !== true) return { name, s, p, c, rep, inadmissible: true, reason: rr.terminal_reason };
  const e = j(path.join(dir, "economics.json")) || {};
  const a = j(path.join(dir, "acceptance.json"));
  const v = j(path.join(dir, "variant.json")) || {};
  const ev = streamEvents(dir);
  const task = SEQS[s][p - 1];
  let delivered = false, deliveredChars = 0;
  for (const x of ev) {
    if (x.type === "system" && x.subtype === "hook_response" && typeof x.output === "string"
        && x.output.includes("prior task records for this repository")) { delivered = true; deliveredChars = x.output.length; break; }
  }
  let outsideReads = 0, searches = 0;
  for (const x of ev) for (const cb of (x?.message?.content || [])) {
    if (cb?.type !== "tool_use") continue;
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
    cost: e.total_cost_usd, uncached: (e.uncached_input_tokens || 0) + (e.cache_creation_input_tokens || 0),
    turns: e.num_turns, elapsed: e.elapsed_s,
    memReads: e.memory_reads ?? 0, memWrites: e.memory_writes_by_worker ?? 0,
    rulesMatched: v.rules_matched ?? 0, rulesBytes: v.rules_installed_bytes ?? 0,
    delivered, deliveredChars, outsideReads, searches,
    capSearch: cnt("capability_search"), gateDiag: cnt("gate_mechanism_diagnosis"),
    bookkeep: cnt("routing_bookkeeping"), gateChal: cnt("gate_challenge_response"),
    ctrlCalls: causes ? causes.counts.routing_bookkeeping + causes.counts.authority_gate_roundtrip : 0,
  };
}

const NAT = [], RUL = [];
for (const rep of REPS) for (const s of ["A", "B"]) for (let p = 1; p <= 5; p++) {
  NAT.push(arm(R9, s, p, "native", rep));
  RUL.push(arm(R10, s, p, "leanrules", rep));
}
const okN = NAT.filter((x) => !x.inadmissible && !x.missing);
const okR = RUL.filter((x) => !x.inadmissible && !x.missing);
const mean = (v) => v.length ? v.reduce((a, b) => a + b, 0) / v.length : null;
const fmt = (x, d = 2) => x == null ? "—" : x.toFixed(d);

console.log("=== EXP-0010 READ — leanrules (new) vs EXP-0009 native (frozen comparator) ===\n");

console.log("--- 0. COMPARATOR IDENTITY ---");
let shaMismatch = 0;
for (let p = 1; p <= 5; p++) for (const s of ["A", "B"]) {
  const shas = new Set([...okN, ...okR].filter((x) => x.s === s && x.p === p).map((x) => x.promptSha));
  if (shas.size > 1) { shaMismatch++; console.log(`MISMATCH at ${s}${p}: ${[...shas].join(" vs ")}`); }
}
console.log(shaMismatch ? `${shaMismatch} position(s) MISMATCHED — quarantine before interpreting` : "prompt sha uniform at all 10 positions across both studies");
console.log();

console.log("--- 1. ADMISSIBILITY & ACCEPTANCE (gate: acceptance loss => claim FAILS) ---");
console.log(`native (frozen): ${okN.length}/20 admissible, ${okN.filter((x) => x.accepted).length} accepted`);
console.log(`leanrules:       ${okR.length}/20 admissible, ${okR.filter((x) => x.accepted).length} accepted  missing/inadmissible: ${RUL.filter((x) => x.missing || x.inadmissible).map((x) => x.name).join(", ") || "none"}`);
console.log();

console.log("--- 2. TOM GUARD (leanrules must hold the lean zeros) ---");
console.log(`memory_writes_by_worker: ${okR.reduce((a, x) => a + x.memWrites, 0)} total`);
console.log(`capability_search=${okR.reduce((a, x) => a + x.capSearch, 0)} gate_diagnosis=${okR.reduce((a, x) => a + x.gateDiag, 0)} routing_bookkeeping=${okR.reduce((a, x) => a + x.bookkeep, 0)} gate_challenge=${okR.reduce((a, x) => a + x.gateChal, 0)} control_calls=${okR.reduce((a, x) => a + x.ctrlCalls, 0)}`);
console.log("(known false-positive pattern: completion reports; inspect any flags verbatim before calling regression)");
console.log();

console.log("--- 3. RULE DELIVERY EVIDENCE (per leanrules arm) ---");
console.log("arm".padEnd(20) + "matched".padStart(8) + "instB".padStart(7) + "in-stream".padStart(10) + "memReads".padStart(9));
for (const x of okR.sort((a, b) => a.rep - b.rep || a.s.localeCompare(b.s) || a.p - b.p))
  console.log(x.name.padEnd(20) + String(x.rulesMatched).padStart(8) + String(x.rulesBytes).padStart(7) + (x.delivered ? "yes" : "no").padStart(10) + String(x.memReads).padStart(9));
const withRules = okR.filter((x) => x.rulesBytes > 0);
console.log(`arms with rules installed: ${withRules.length}/${okR.length}; all delivered in-stream: ${withRules.every((x) => x.delivered)}`);
console.log();

console.log("--- 4. PRIMARY: POSITION-MATCHED GAP (leanrules/native ratio per position; paired, admissible both sides) ---");
for (const metric of ["cost", "uncached", "turns"]) {
  const ratios = [];
  for (let p = 1; p <= 5; p++) {
    const pairs = [];
    for (const rep of REPS) for (const s of ["A", "B"]) {
      const n = okN.find((x) => x.s === s && x.p === p && x.rep === rep);
      const l = okR.find((x) => x.s === s && x.p === p && x.rep === rep);
      if (n && l && n[metric] != null && l[metric] != null) pairs.push(l[metric] / n[metric]);
    }
    ratios.push(mean(pairs));
  }
  console.log(`${metric.padEnd(9)} P1..P5:  ` + ratios.map((r) => fmt(r).padStart(7)).join(" "));
  const early = ratios[0], late = mean([ratios[3], ratios[4]].filter((x) => x != null));
  console.log(`  P1=${fmt(early)}  late(P4,P5)=${fmt(late)}  => gap ${early != null && late != null ? (late < early ? "MORE favorable with position" : late > early ? "LESS favorable with position" : "flat") : "n/a"}`);
}
console.log();

console.log("--- 5. SECONDARY: ABSOLUTE POSITION CURVES (context only) ---");
for (const metric of ["cost", "uncached", "turns"]) {
  for (const [label, g] of [["native", okN], ["leanrules", okR]]) {
    const row = [];
    for (let p = 1; p <= 5; p++) row.push(mean(g.filter((x) => x.p === p).map((x) => x[metric]).filter((v) => v != null)));
    console.log(`${metric.padEnd(9)}${label.padEnd(10)}` + row.map((r) => fmt(r, metric === "cost" ? 2 : 0).padStart(9)).join(""));
  }
}
console.log();

console.log("--- 6. STALE/INCORRECT-RULE HARM ---");
console.log(`rule-delivered arms not accepted: ${withRules.filter((x) => !x.accepted).length}/${withRules.length}`);
console.log();

console.log("--- 7. REDISCOVERY (outside-task-file reads / searches) per position ---");
for (const [label, g] of [["native", okN], ["leanrules", okR]]) {
  const r1 = [], r2 = [];
  for (let p = 1; p <= 5; p++) {
    const gg = g.filter((x) => x.p === p);
    r1.push(mean(gg.map((x) => x.outsideReads))); r2.push(mean(gg.map((x) => x.searches)));
  }
  console.log(`${label.padEnd(10)} outsideReads ` + r1.map((r) => fmt(r, 1).padStart(6)).join("") + "   searches " + r2.map((r) => fmt(r, 1).padStart(6)).join(""));
}
