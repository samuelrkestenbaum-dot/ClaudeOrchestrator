#!/usr/bin/env node
// UCDL Phase 1 — NO-SPEND concurrency calibration.
//
// EXP-0012's calibration gate exists but its probes spawn PAID model
// workers; this variant answers the narrower infrastructure question with
// zero spend: does running W deterministic CPU-bound "cells" concurrently
// inflate per-cell elapsed beyond the precommitted bound on THIS host?
//
// PRECOMMITTED RULE (fixed here, before any measured study): concurrency
// width W qualifies iff median per-cell elapsed inflation vs solo is < 10%.
// This is a NECESSARY condition for parallel measured runs, never a
// sufficient one — provider-side contention (rate limits, cache warming)
// is invisible to a CPU probe and stays a live-pilot question by design.
//
// Usage: calibrate-noload.mjs [--width 2] [--reps 3] [--work 400]
//   work = sha256 iterations x1000 per cell (~1-3s at 400 on this class of host)
// Output: JSON verdict on stdout; exit 0 qualified / 1 not / 3 refused.

import crypto from "node:crypto";
import fs from "node:fs";
import { Worker, isMainThread, workerData, parentPort } from "node:worker_threads";

const INFLATION_BOUND = 0.10; // precommitted; changing it is a design change, not a tweak

if (!isMainThread) {
  const t0 = process.hrtime.bigint();
  let h = Buffer.alloc(32);
  for (let i = 0; i < workerData.iters * 1000; i++) h = crypto.createHash("sha256").update(h).digest();
  parentPort.postMessage(Number(process.hrtime.bigint() - t0) / 1e9);
} else {
  const arg = (n, d) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? Number(process.argv[i + 1]) : d; };
  const W = arg("width", 2), R = arg("reps", 3), ITERS = arg("work", 400);

  // Refuse while any measured study lock is held — calibration must not contend.
  for (const lock of ["/home/user/.exp0007/arm.lock", "/home/user/.exp0011/measurement.lock", "/home/user/.exp0013/measurement.lock"]) {
    try {
      const pid = Number(fs.readFileSync(lock, "utf8").trim());
      process.kill(pid, 0);
      console.error(`REFUSED — measured study lock live (${lock}, pid ${pid}).`);
      process.exit(3);
    } catch {}
  }

  const cell = () => new Promise((res, rej) => {
    const w = new Worker(new URL(import.meta.url), { workerData: { iters: ITERS } });
    w.once("message", res); w.once("error", rej);
  });
  const median = (xs) => { const s = [...xs].sort((a, b) => a - b); return s.length % 2 ? s[(s.length - 1) / 2] : (s[s.length / 2 - 1] + s[s.length / 2]) / 2; };

  const solo = [], wide = [];
  for (let r = 0; r < R; r++) solo.push(await cell());               // solo baseline
  for (let r = 0; r < R; r++) wide.push(...await Promise.all(Array.from({ length: W }, cell)));
  const mSolo = median(solo), mWide = median(wide);
  const inflation = (mWide - mSolo) / mSolo;
  const verdict = {
    artifact: "ucdl_noload_calibration",
    width: W, reps: R, work_kiters: ITERS,
    median_solo_s: +mSolo.toFixed(3),
    median_concurrent_s: +mWide.toFixed(3),
    inflation: +inflation.toFixed(4),
    bound: INFLATION_BOUND,
    qualified: inflation < INFLATION_BOUND,
    scope: "CPU/scheduler contention only — provider-side contention requires the live pilot",
  };
  console.log(JSON.stringify(verdict, null, 2));
  process.exit(verdict.qualified ? 0 : 1);
}
