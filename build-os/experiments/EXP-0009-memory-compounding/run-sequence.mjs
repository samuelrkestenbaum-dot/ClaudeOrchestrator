#!/usr/bin/env node
// EXP-0009 SEQUENCE DRIVER — one rep of one or both sequences, POSITIONS IN
// ORDER. Order is load-bearing here in a way it was not in EXP-0007: the
// lean-mem arm at position k+1 is only a measurement of memory if position k's
// admissible lean-mem arm has already distilled into the store. The driver
// therefore never reorders positions and never fans out.
//
// Config order within a position alternates by position so neither config eats
// the cold-cache cost every time; the store is untouched by ordering within a
// position because distillation happens after the lean-mem arm completes and is
// read only at the NEXT position.
//
// Usage: run-sequence.mjs --convergence memory-compounding.convergence.json
//        [--seqs A,B] [--rep 1] [--configs native,leanmem]
import { spawn } from "node:child_process";
import fs from "node:fs"; import path from "node:path";
import { assess, loadProgram } from "../../motion/convergence.mjs";
const HERE = path.dirname(new URL(import.meta.url).pathname);

// PROGRAM CONVERGENCE GATE — same wiring as EXP-0007's replication driver: the
// possible results are stated before the data exists, and a run whose result
// cannot move D3 does not spend the compute.
{
  const cf = (() => { const i = process.argv.indexOf("--convergence"); return i > 0 ? process.argv[i + 1] : null; })();
  if (!cf) {
    console.error("REFUSED — no --convergence <proposal.json>. State the decision this run serves,");
    console.error("and what each possible result would make us do next, before spending the compute.");
    process.exit(3);
  }
  const proposal = JSON.parse(fs.readFileSync(cf, "utf8"));
  const v = assess(proposal, loadProgram());
  console.log(`CONVERGENCE ${v.verdict}: ${v.code}\n  ${v.why}`);
  for (const r of v.reasons) console.log(`  · ${r}`);
  if (v.verdict !== "PROCEED") { console.error("\nNot running. Evidence sufficient, or result cannot move the decision."); process.exit(3); }
}

const arg = (n, d) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const SEQS = arg("seqs", "A,B").split(",");
const REP = Number(arg("rep", "1"));
const CONFIGS = arg("configs", "native,leanmem").split(",");

// RESUMABLE, like EXP-0007 after the container restart: a cell is skipped only
// when its record is ADMISSIBLE. Because positions run in order, resume
// naturally lands on the first cell without an admissible result.
const runDirOf = (s, p, c) => path.join(HERE, "results/runs", `${s}${p}.${c}.r${REP}`);
function alreadyDone(s, p, c) {
  try { return JSON.parse(fs.readFileSync(path.join(runDirOf(s, p, c), "run-record.json"), "utf8")).admissible === true; }
  catch { return false; }
}
const run = (s, p, c) => new Promise((res) =>
  spawn("node", [path.join(HERE, "run-arm.mjs"), "--seq", s, "--pos", String(p), "--rep", String(REP), "--config", c], { stdio: "inherit" }).on("exit", res));

// ONE immediate retry for an inadmissible arm. In EXP-0007 an inadmissible cell
// simply waited for the next driver invocation; a sequence cannot wait, because
// running position k+1 before k has an admissible lean-mem result measures a
// store that should have had one more entry. The failed attempt is preserved,
// not overwritten.
async function runCell(s, p, c) {
  for (let attempt = 1; attempt <= 2; attempt++) {
    const t0 = Date.now();
    const code = await run(s, p, c);
    const wall = Math.round((Date.now() - t0) / 1000);
    const admissible = alreadyDone(s, p, c);
    if (admissible || attempt === 2) return { exit: code, wall_s: wall, admissible, attempts: attempt };
    const dir = runDirOf(s, p, c);
    if (fs.existsSync(dir)) fs.renameSync(dir, `${dir}.attempt1`);
    console.log(`  (arm ${s}${p}/${c} rep${REP} inadmissible — one immediate retry; attempt 1 preserved at ${path.basename(dir)}.attempt1)`);
  }
}

const log = [];
const logFile = path.join(HERE, `results/sequence-log.rep${REP}.json`);
try { log.push(...JSON.parse(fs.readFileSync(logFile, "utf8")).units.filter((u) => !SEQS.includes(u.sequence))); } catch {}
console.log(`EXP-0009 rep${REP} — sequences ${SEQS.join(",")} x 5 positions x ${CONFIGS.join(",")} — ordered, serial`);
for (const s of SEQS) {
  for (let p = 1; p <= 5; p++) {
    const order = p % 2 === 0 ? [...CONFIGS].reverse() : CONFIGS;
    for (const c of order) {
      if (alreadyDone(s, p, c)) { console.log(`SKIP ${s}${p}/${c} rep${REP} — admissible result already on disk`); log.push({ sequence: s, position: p, config: c, rep: REP, skipped: true }); continue; }
      const r = await runCell(s, p, c);
      log.push({ sequence: s, position: p, config: c, rep: REP, ...r });
      if (!r.admissible) console.log(`  (arm ${s}${p}/${c} rep${REP} still inadmissible after retry — recorded, continuing; the curve carries the gap)`);
      fs.writeFileSync(logFile, JSON.stringify({ artifact: "exp0009_sequence_log", rep: REP, configs: CONFIGS, units: log }, null, 2));
    }
  }
}
console.log(`\nrep${REP} pass finished — ${log.length} cells, ${log.filter((l) => l.admissible || l.skipped).length} admissible/skipped`);
