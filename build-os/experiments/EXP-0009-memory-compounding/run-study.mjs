#!/usr/bin/env node
// EXP-0009 STUDY SUPERVISOR — the whole study, chained.
//
// WHY THIS EXISTS, precisely. run-sequence.mjs already chains every arm inside
// one rep: A1 -> A5 -> B1 -> B5, both configs, serial awaits, no waiting. But it
// EXITS after its rep, so rep 2's start depended on a scheduled check-in firing.
// That made a TIMER the authority for normal progress, which inverts the
// operating model: timers detect failure; events drive work. This file removes
// exactly that dependency and nothing else.
//
// It is orchestration only. It does not touch the treatment, the prompts, the
// model, the task list, the measurement apparatus, the classifiers, or arm
// semantics — it decides only WHEN the next authorized, runnable, unblocked
// unit starts, and the answer is always "immediately".
//
// Invariant enforced here:
//   authorized + runnable + predecessor_complete + no_blocker => launch now
//
// Usage: run-study.mjs --convergence <file> [--reps 1,2] [--wait-for-pid <pid>]

import { spawn } from "node:child_process";
import fs from "node:fs"; import path from "node:path";
const HERE = path.dirname(new URL(import.meta.url).pathname);
const arg = (n, d) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const CONV = arg("convergence", "memory-compounding.convergence.json");
const REPS = arg("reps", "1,2").split(",").map(Number);
const WAIT_PID = Number(arg("wait-for-pid", "0"));
const MAX_PASSES = 4;               // a bounded recovery loop, not a retry forever
const say = (m) => { const line = `[study ${new Date().toISOString()}] ${m}`; console.log(line); try { fs.appendFileSync(path.join(HERE, "results/study-log.txt"), line + "\n"); } catch {} };

const CELLS = [];
for (const s of ["A", "B"]) for (let p = 1; p <= 5; p++) for (const c of ["native", "leanmem"]) CELLS.push({ s, p, c });
const admissible = (rep, { s, p, c }) => {
  try { return JSON.parse(fs.readFileSync(path.join(HERE, "results/runs", `${s}${p}.${c}.r${rep}`, "run-record.json"), "utf8")).admissible === true; }
  catch { return false; }
};
const repComplete = (rep) => CELLS.every((x) => admissible(rep, x));
const repCount = (rep) => CELLS.filter((x) => admissible(rep, x)).length;

const alive = (pid) => { try { process.kill(pid, 0); return true; } catch { return false; } };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// A driver already in flight is a PREDECESSOR, not a competitor. Waiting for it
// is the one legitimate wait in this file: starting a second driver against the
// same arm lock would fast-forward the survivor through cells it never ran.
if (WAIT_PID && alive(WAIT_PID)) {
  say(`a rep driver (pid ${WAIT_PID}) is already in flight — waiting for it to hand back, then chaining`);
  while (alive(WAIT_PID)) await sleep(15_000);
  say(`pid ${WAIT_PID} handed back`);
}

for (const rep of REPS) {
  for (let pass = 1; pass <= MAX_PASSES; pass++) {
    if (repComplete(rep)) { say(`rep ${rep} COMPLETE — ${repCount(rep)}/${CELLS.length} cells admissible`); break; }
    say(`rep ${rep}, pass ${pass}: ${repCount(rep)}/${CELLS.length} admissible — launching driver now`);
    const code = await new Promise((res) =>
      spawn("node", [path.join(HERE, "run-sequence.mjs"), "--convergence", path.resolve(HERE, CONV), "--rep", String(rep)],
        { stdio: ["ignore", fs.openSync(path.join(HERE, `results/driver-rep${rep}.log`), "a"), fs.openSync(path.join(HERE, `results/driver-rep${rep}.log`), "a")] })
        .on("exit", res));
    say(`rep ${rep}, pass ${pass}: driver exited ${code}; ${repCount(rep)}/${CELLS.length} admissible`);
    // A driver that exits with cells still missing was interrupted (container
    // restart) — resume skips admissible cells, so the next pass is cheap. A
    // stale arm lock from the killed process is the one thing that would block
    // it, and clearing it is safe ONLY when its pid is dead.
    const LOCK = "/home/user/.exp0007/arm.lock";
    try {
      const p = Number(fs.readFileSync(LOCK, "utf8").trim());
      if (p && !alive(p)) { fs.rmSync(LOCK, { force: true }); say(`cleared stale arm lock (pid ${p} dead)`); }
      else if (p) say(`arm lock held by LIVE pid ${p} — not touching it`);
    } catch {}
  }
  if (!repComplete(rep)) { say(`rep ${rep} INCOMPLETE after ${MAX_PASSES} passes (${repCount(rep)}/${CELLS.length}) — stopping; this is a blocker to report, not a result`); process.exit(1); }
}
say(`STUDY COMPLETE — reps ${REPS.join(",")} all ${CELLS.length} cells admissible each. The fork may now be applied.`);
