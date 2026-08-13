#!/usr/bin/env node
// Persistent, hash-chained SPEND LEDGER (AMENDMENT v3 — closes the audit
// finding that the v2 budget gate was a pure function whose spent_so_far
// input had no durable source; restart could have reset spend to zero).
//
// Accounting rules (conservative by construction):
//   - every provider call is recorded BEFORE launch as a reservation with
//     bound_usd (the frozen per-call worst case), then settled after with
//     the provider-native cost when metered;
//   - an UNSETTLED or NOT_METERED call is charged at bound_usd forever —
//     unknown cost is never zero;
//   - a settled cost ABOVE the bound charges the actual cost;
//   - restart re-reads the ledger; reservations survive crashes, so a call
//     that died mid-flight still holds its full bound.
// Any malformed line, broken chain, or torn tail is a TYPED refusal — a
// controller that cannot read its ledger makes NO further calls.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");
const FILE = "spend-ledger.jsonl";

function append(dir, obj) {
  const f = path.join(dir, FILE);
  fs.mkdirSync(dir, { recursive: true });
  // mkdir-mutex (AMENDMENT v4): concurrent writers serialize so the chain
  // never interleaves; a crashed holder's stale lock (>10s) is broken.
  const lock = f + ".lock";
  const t0 = Date.now();
  for (;;) {
    try { fs.mkdirSync(lock); break; }
    catch {
      try { if (Date.now() - fs.statSync(lock).mtimeMs > 10_000) { fs.rmdirSync(lock); continue; } } catch {}
      if (Date.now() - t0 > 15_000) throw new Error("LEDGER_LOCK_TIMEOUT");
      const buf = new SharedArrayBuffer(4); Atomics.wait(new Int32Array(buf), 0, 0, 5);
    }
  }
  try {
    const prev = (() => { try { const l = fs.readFileSync(f, "utf8").trim().split("\n"); return sha(l[l.length - 1]); } catch { return "genesis"; } })();
    fs.appendFileSync(f, JSON.stringify({ ...obj, prev_sha: prev }) + "\n");
  } finally {
    try { fs.rmdirSync(lock); } catch {}
  }
}

export function reserveCall(dir, { call_index, cell, kind, bound_usd }) {
  append(dir, { entry: "reserve", call_index, cell, kind, bound_usd });
}
export function settleCall(dir, { call_index, cell, cost_usd, metered }) {
  append(dir, { entry: "settle", call_index, cell, cost_usd: metered ? cost_usd : null, metered });
}

export function loadLedger(dir) {
  const f = path.join(dir, FILE);
  if (!fs.existsSync(f)) return { ok: true, calls: 0, spent_conservative_usd: 0, unsettled: 0 };
  const raw = fs.readFileSync(f, "utf8");
  if (raw.length && !raw.endsWith("\n")) return { ok: false, reason: "LEDGER_TORN_TAIL" };
  let prev = "genesis";
  const reserves = new Map(), settles = new Map();
  const lines = raw.split("\n").filter(Boolean);
  for (let i = 0; i < lines.length; i++) {
    let d;
    try { d = JSON.parse(lines[i]); } catch { return { ok: false, reason: `LEDGER_MALFORMED_LINE:${i + 1}` }; }
    if (d.prev_sha !== prev) return { ok: false, reason: `LEDGER_CHAIN_BROKEN:${i + 1}` };
    prev = sha(lines[i]);
    if (d.entry === "reserve") {
      if (typeof d.bound_usd !== "number" || d.bound_usd <= 0) return { ok: false, reason: `LEDGER_MALFORMED_LINE:${i + 1}` };
      if (reserves.has(d.call_index)) return { ok: false, reason: `LEDGER_DUPLICATE_RESERVATION:${d.call_index}` };
      reserves.set(d.call_index, d);
    } else if (d.entry === "settle") {
      if (!reserves.has(d.call_index)) return { ok: false, reason: `LEDGER_SETTLE_WITHOUT_RESERVE:${d.call_index}` };
      if (settles.has(d.call_index)) return { ok: false, reason: `LEDGER_DUPLICATE_SETTLE:${d.call_index}` };
      settles.set(d.call_index, d);
    } else return { ok: false, reason: `LEDGER_MALFORMED_LINE:${i + 1}` };
  }
  let spent = 0, unsettled = 0;
  for (const [idx, r] of reserves) {
    const s = settles.get(idx);
    if (!s || s.cost_usd == null) { spent += r.bound_usd; if (!s) unsettled++; }
    else spent += Math.max(s.cost_usd, 0); // actual when metered, even above bound
  }
  return { ok: true, calls: reserves.size, spent_conservative_usd: +spent.toFixed(6), unsettled };
}
