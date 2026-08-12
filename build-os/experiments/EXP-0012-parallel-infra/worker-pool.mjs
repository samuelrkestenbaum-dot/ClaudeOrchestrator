// EXP-0012 (#53) — isolated worker trees + a DAG scheduler for experiment
// arms. Orchestration only: treatments stay inside whatever runner is
// spawned, and each runner re-proves its own administration per arm exactly
// as on the shared tree. Event-driven throughout (child exit is the event);
// no polling, no timers.

import { execFileSync, spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const RESTORE = path.join(HERE, "../EXP-0005-system-efficiency/harness/restore-seed.sh");
const SEED = "2543c873141fa64653a7993d326465d5e0dd1006";

export function treePath(n) { return `/home/user/exp-arm-w${n}`; }
export function lockPath(n) { return `/home/user/.exp-locks/w${n}.lock`; }

/** Seed-restore worker tree n and verify; returns {tree, lock}. */
export function provisionTree(n) {
  const tree = treePath(n);
  fs.rmSync(tree, { recursive: true, force: true });
  const o = execFileSync("bash", [RESTORE, tree], { encoding: "utf8" });
  const head = execFileSync("git", ["-C", tree, "rev-parse", "HEAD"], { encoding: "utf8" }).trim();
  if (!/VERIFIED/.test(o) || head !== SEED) throw new Error(`worker ${n}: seed restore failed (${head.slice(0, 12)})`);
  try { fs.symlinkSync("/home/user/empathiq-website/node_modules", path.join(tree, "node_modules"), "dir"); } catch {}
  fs.mkdirSync(path.dirname(lockPath(n)), { recursive: true });
  return { tree, lock: lockPath(n) };
}

/**
 * Run a study as a DAG. chains: array of arrays of cells (strict order within
 * each chain, advance only on admissible completion). independents: cells
 * with no ordering. spawn(cell, env) must return a child process whose exit
 * signals completion; isAdmissible(cell) reads the cell's own record.
 * Semantics mirror the serial executors: one immediate retry per cell (the
 * caller preserves partials), a chain HALTS on a twice-failed cell (reported,
 * never silently skipped), independents always continue.
 */
export async function runDag({ chains, independents = [], width, spawnCell, isAdmissible, onEvent = () => {} }) {
  const workers = Array.from({ length: width }, (_, i) => provisionTree(i + 1));
  const free = [...workers];
  const chainState = chains.map((cells) => ({ cells, next: 0, halted: false }));
  const indep = [...independents];
  const halted = [], done = [];
  let active = 0;

  const ready = () => {
    for (const cs of chainState) {
      if (!cs.halted && cs.next < cs.cells.length && !cs.running) return { cell: cs.cells[cs.next], chain: cs };
    }
    if (indep.length) return { cell: indep.shift(), chain: null };
    return null;
  };

  await new Promise((resolve) => {
    const pump = () => {
      while (free.length) {
        const r = ready();
        if (!r) break;
        const w = free.pop();
        if (r.chain) r.chain.running = true;
        active++;
        onEvent({ type: "dispatch", cell: r.cell, worker: w.tree });
        runCellOnWorker(r.cell, w, spawnCell, isAdmissible, onEvent).then((ok) => {
          active--;
          free.push(w);
          if (r.chain) {
            r.chain.running = false;
            if (ok) r.chain.next++;
            else { r.chain.halted = true; halted.push(r.cell); onEvent({ type: "chain_halted", cell: r.cell }); }
          } else if (!ok) halted.push(r.cell);
          if (ok) done.push(r.cell);
          if (!ready() && active === 0) resolve(); else pump();
        });
      }
      if (!ready() && active === 0) resolve();
    };
    pump();
  });
  return { done, halted };
}

async function runCellOnWorker(cell, w, spawnCell, isAdmissible, onEvent) {
  for (let attempt = 1; attempt <= 2; attempt++) {
    try { const p = Number(fs.readFileSync(w.lock, "utf8").trim()); try { process.kill(p, 0); } catch { fs.rmSync(w.lock, { force: true }); } } catch {}
    const child = spawnCell(cell, { ARM_TREE: w.tree, ARM_LOCK: w.lock });
    const code = await new Promise((res) => child.on("exit", res));
    if (isAdmissible(cell)) return true;
    onEvent({ type: "retry", cell, attempt, exit: code });
  }
  return false;
}
