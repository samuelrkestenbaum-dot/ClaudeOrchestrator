#!/usr/bin/env node
// EXP-0009 — THE ONE READ. Written and frozen BEFORE rep 2 completed, so the
// analysis is preregistered code, not post-hoc choices. No new metrics beyond
// the preregistration + the operator's freeze amendments.
//
// Order of sections mirrors the operator's final-read constraints:
//   1. admissibility & acceptance (acceptance loss => claim FAILS regardless of cost)
//   2. TOM guard (memory_writes_by_worker MUST be 0; lean TOM classes at zero)
//   3. reuse evidence (delivery mode per arm, memory_reads; a favorable curve
//      with zero consultation is a CONFOUND, not a confirmation)
//   4. PRIMARY: position-matched Native-vs-Leanmem gap across position
//   5. SECONDARY: absolute within-arm slopes (context only, never the verdict)
//   6. stale/incorrect-memory harm
//   7. rediscovery behavior (product reads outside task file + search calls)
import fs from "node:fs";
import path from "node:path";
import { causesForStream } from "../EXP-0008-microcontext/turn-causes.mjs";
import { classifyCorpus } from "../EXP-0008-microcontext/text-turn-classes.mjs";
const HERE = path.dirname(new URL(import.meta.url).pathname);
const RUNS = path.join(HERE, "results/runs");
const SEQS = JSON.parse(fs.readFileSync(path.join(HERE, "sequences.json"), "utf8")).sequences;
const j = (p) => { try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return null; } };
const REPS = [1, 2];

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

  // Reuse evidence — structural. Delivery: the session-start hook_response.
  let delivery = "none", deliveredChars = 0;
  for (const x of ev) {
    if (x.type !== "system" || x.subtype !== "hook_response" || typeof x.output !== "string") continue;
    if (x.output.includes("prior task records for this repository")) { delivery = "inline"; deliveredChars = x.output.length; break; }
    if (x.output.includes("prior task records at build-os/memory/task-log.md")) { delivery = "pointer"; deliveredChars = x.output.length; break; }
  }
  // Rediscovery — product-file Reads outside the task file, plus search calls.
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
  // Frozen text classifier (TOM classes) + control-call causes.
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
    name, s, p, c, rep, inadmissible: false,
    accepted: a?.accepted === true, promptSha: v.prompt_sha256_16,
    cost: e.total_cost_usd, uncached: (e.uncached_input_tokens || 0) + (e.cache_creation_input_tokens || 0),
    turns: e.num_turns, elapsed: e.elapsed_s,
    memReads: e.memory_reads ?? 0, memWrites: e.memory_writes_by_worker ?? 0,
    delivery, deliveredChars,
    consulted: delivery === "inline" || (e.memory_reads ?? 0) > 0,
    outsideReads, searches,
    capSearch: cnt("capability_search"), gateDiag: cnt("gate_mechanism_diagnosis"),
    bookkeep: cnt("routing_bookkeeping"), gateChal: cnt("gate_challenge_response"),
    ctrlCalls: causes ? causes.counts.routing_bookkeeping + causes.counts.authority_gate_roundtrip : 0,
  };
}

const ALL = [];
for (const rep of REPS) for (const s of ["A", "B"]) for (let p = 1; p <= 5; p++) for (const c of ["native", "leanmem"]) ALL.push(arm(s, p, c, rep));
const OK = ALL.filter((x) => !x.inadmissible && !x.missing);
const mean = (v) => v.length ? v.reduce((a, b) => a + b, 0) / v.length : null;
const fmt = (x, d = 2) => x == null ? "—" : x.toFixed(d);

console.log("=== EXP-0009 READ — 2 seqs x 5 positions x native/leanmem x 2 reps ===\n");

console.log("--- 1. ADMISSIBILITY & ACCEPTANCE (gate: acceptance loss => claim FAILS) ---");
console.log(`admissible: ${OK.length}/${ALL.length}  missing/inadmissible: ${ALL.filter((x) => x.missing || x.inadmissible).map((x) => x.name).join(", ") || "none"}`);
for (const c of ["native", "leanmem"]) {
  const g = OK.filter((x) => x.c === c);
  console.log(`${c.padEnd(8)} accepted ${g.filter((x) => x.accepted).length}/${g.length}`);
}
console.log();

console.log("--- 2. TOM GUARD (all must be zero for leanmem) ---");
const lm = OK.filter((x) => x.c === "leanmem");
console.log(`memory_writes_by_worker: ${lm.reduce((a, x) => a + x.memWrites, 0)} total (per-arm max ${Math.max(...lm.map((x) => x.memWrites))})`);
console.log(`capability_search=${lm.reduce((a, x) => a + x.capSearch, 0)} gate_diagnosis=${lm.reduce((a, x) => a + x.gateDiag, 0)} routing_bookkeeping=${lm.reduce((a, x) => a + x.bookkeep, 0)} gate_challenge=${lm.reduce((a, x) => a + x.gateChal, 0)} control_calls=${lm.reduce((a, x) => a + x.ctrlCalls, 0)}`);
console.log();

console.log("--- 3. REUSE EVIDENCE (per leanmem arm) ---");
console.log("arm".padEnd(18) + "delivery".padEnd(10) + "chars".padStart(6) + "memReads".padStart(9) + "  consulted");
for (const x of lm.sort((a, b) => a.rep - b.rep || a.s.localeCompare(b.s) || a.p - b.p))
  console.log(x.name.padEnd(18) + x.delivery.padEnd(10) + String(x.deliveredChars).padStart(6) + String(x.memReads).padStart(9) + (x.consulted ? "      YES" : "      no"));
console.log(`consulted arms: ${lm.filter((x) => x.consulted).length}/${lm.length} (position-1 arms have empty stores by design)`);
console.log();

console.log("--- 4. PRIMARY: POSITION-MATCHED GAP (leanmem/native ratio per position; paired, admissible both sides) ---");
for (const metric of ["cost", "uncached", "turns"]) {
  console.log(`\n${metric}: position ->  P1      P2      P3      P4      P5    | trend = P1-ratio vs mean(P4,P5)-ratio`);
  const ratios = [];
  for (let p = 1; p <= 5; p++) {
    const pairs = [];
    for (const rep of REPS) for (const s of ["A", "B"]) {
      const n = OK.find((x) => x.s === s && x.p === p && x.c === "native" && x.rep === rep);
      const l = OK.find((x) => x.s === s && x.p === p && x.c === "leanmem" && x.rep === rep);
      if (n && l && n[metric] != null && l[metric] != null) pairs.push(l[metric] / n[metric]);
    }
    ratios.push(mean(pairs));
  }
  console.log("  ratio        " + ratios.map((r) => fmt(r).padStart(7)).join(" "));
  const early = ratios[0], late = mean([ratios[3], ratios[4]].filter((x) => x != null));
  console.log(`  P1=${fmt(early)}  late(P4,P5)=${fmt(late)}  => gap ${early != null && late != null ? (late < early ? "MORE favorable with position" : late > early ? "LESS favorable with position" : "flat") : "n/a"}`);
}
console.log();

console.log("--- 5. SECONDARY: ABSOLUTE POSITION CURVES (context only) ---");
for (const metric of ["cost", "uncached", "turns"]) {
  for (const c of ["native", "leanmem"]) {
    const row = [];
    for (let p = 1; p <= 5; p++) row.push(mean(OK.filter((x) => x.c === c && x.p === p).map((x) => x[metric]).filter((v) => v != null)));
    console.log(`${metric.padEnd(9)}${c.padEnd(9)}` + row.map((r) => fmt(r, metric === "cost" ? 2 : 0).padStart(9)).join(""));
  }
}
console.log();

console.log("--- 6. STALE/INCORRECT-MEMORY HARM ---");
const consulted = lm.filter((x) => x.consulted);
console.log(`memory-consulted arms not accepted: ${consulted.filter((x) => !x.accepted).length}/${consulted.length}`);
console.log();

console.log("--- 7. REDISCOVERY (product reads outside task file / search calls) per position, mean across seqs+reps ---");
for (const c of ["native", "leanmem"]) {
  const r1 = [], r2 = [];
  for (let p = 1; p <= 5; p++) {
    const g = OK.filter((x) => x.c === c && x.p === p);
    r1.push(mean(g.map((x) => x.outsideReads))); r2.push(mean(g.map((x) => x.searches)));
  }
  console.log(`${c.padEnd(9)} outsideReads ` + r1.map((r) => fmt(r, 1).padStart(6)).join("") + "   searches " + r2.map((r) => fmt(r, 1).padStart(6)).join(""));
}
