#!/usr/bin/env node
// EXP-0012 — the serial-vs-wide calibration gate. REFUSES to run while any
// measured study's arm lock is held: calibration itself must not contend.
//
// Design + PRECOMMITTED equivalence rule in DESIGN.md: pass iff median
// elapsed differs <15%, median cost differs <10%, and a rank-sum test
// (normal approximation) does not reject at alpha=0.05 for elapsed.
//
// Usage: calibrate.mjs [--reps 4] [--width 4]

import { spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { provisionTree, treePath, lockPath } from "./worker-pool.mjs";
const HERE = path.dirname(new URL(import.meta.url).pathname);
const arg = (n, d) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const R = Number(arg("reps", "4")), W = Number(arg("width", "4"));
const OUT = path.join(HERE, "results/calibration");

// Refuse while a measured study runs.
const STUDY_LOCK = "/home/user/.exp0007/arm.lock";
try {
  const p = Number(fs.readFileSync(STUDY_LOCK, "utf8").trim());
  process.kill(p, 0);
  console.error(`REFUSED — a measured study arm is live (lock pid ${p}). Calibration must not contend.`);
  process.exit(3);
} catch {}

const probe = (label, env) => new Promise((res) => {
  const child = spawn("node", [path.join(HERE, "probe-arm.mjs"), "--label", label, "--outdir", OUT],
    { env: { ...process.env, ...env }, stdio: "inherit" });
  child.on("exit", res);
});
const econ = (label) => { try { return JSON.parse(fs.readFileSync(path.join(OUT, label, "economics.json"), "utf8")); } catch { return null; } };

console.log(`calibration: ${R} serial then ${R} at width ${W} (probe = EXP-0009 A1/native shape)`);
// Phase 1 — serial on worker 1.
provisionTree(1);
for (let i = 1; i <= R; i++) await probe(`serial-${i}`, { ARM_TREE: treePath(1), ARM_LOCK: lockPath(1) });
// Phase 2 — R probes across W workers concurrently.
for (let n = 1; n <= Math.min(W, R); n++) provisionTree(n);
await Promise.all(Array.from({ length: R }, (_, i) => {
  const n = (i % W) + 1;
  return probe(`wide-${i + 1}`, { ARM_TREE: treePath(n), ARM_LOCK: lockPath(n) });
}));

// The precommitted read.
const S = Array.from({ length: R }, (_, i) => econ(`serial-${i + 1}`)).filter(Boolean);
const P = Array.from({ length: R }, (_, i) => econ(`wide-${i + 1}`)).filter(Boolean);
const med = (v) => { const s = [...v].sort((a, b) => a - b); return s.length % 2 ? s[(s.length - 1) / 2] : (s[s.length / 2 - 1] + s[s.length / 2]) / 2; };
const ranksum = (a, b) => { // Mann-Whitney U, normal approximation, two-sided
  const all = [...a.map((x) => [x, 0]), ...b.map((x) => [x, 1])].sort((x, y) => x[0] - y[0]);
  let r = 0; all.forEach(([, g], i) => { if (g === 0) r += i + 1; });
  const n1 = a.length, n2 = b.length, U = r - n1 * (n1 + 1) / 2;
  const mu = n1 * n2 / 2, sd = Math.sqrt(n1 * n2 * (n1 + n2 + 1) / 12);
  const z = sd ? Math.abs(U - mu) / sd : 0;
  return { U, z, reject: z > 1.96 };
};
const sEl = S.map((x) => x.elapsed_s), pEl = P.map((x) => x.elapsed_s);
const sC = S.map((x) => x.total_cost_usd).filter((v) => v != null), pC = P.map((x) => x.total_cost_usd).filter((v) => v != null);
const dEl = Math.abs(med(pEl) - med(sEl)) / med(sEl);
const dC = sC.length && pC.length ? Math.abs(med(pC) - med(sC)) / med(sC) : null;
const rs = ranksum(sEl, pEl);
const pass = dEl < 0.15 && (dC == null || dC < 0.10) && !rs.reject;
const report = { artifact: "calibration", reps: R, width: W,
  serial: { elapsed: sEl, cost: sC }, wide: { elapsed: pEl, cost: pC },
  median_elapsed_delta: dEl, median_cost_delta: dC, ranksum_z: rs.z,
  verdict: pass ? "EQUIVALENT — width " + W + " adopted for measured studies" : "NOT EQUIVALENT — halve width and re-run, or restrict parallelism to non-speed studies" };
fs.writeFileSync(path.join(OUT, `calibration-w${W}.json`), JSON.stringify(report, null, 2));
console.log(JSON.stringify(report, null, 2));
process.exit(pass ? 0 : 1);
