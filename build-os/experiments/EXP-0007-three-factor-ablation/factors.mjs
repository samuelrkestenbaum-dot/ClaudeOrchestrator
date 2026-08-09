#!/usr/bin/env node
// EXP-0007 — the four factor rates, reported side by side and never netted.
//
// WHY THIS IS A SEPARATE INSTRUMENT FROM UIC.
//
// UIC is a ratio of one numerator to one denominator, and EXP-0006 showed the
// denominator is a PRODUCT of independent factors:
//
//     total = turns × per-turn cost
//     1.93× = 1.40× × 1.38×
//
// An intervention that cuts turns 25% while inflating context 20% nets to a
// small UIC improvement and reads as progress. It is not progress — it is a
// trade, and which side of it you took is invisible in the aggregate. So the
// aggregate is not the report. The four rates are the report, and UIC comes
// last, after they have already been shown.
//
// The reference is EXP-0006's NATIVE arm, frozen at seed 2543c873. It is never
// re-run: it is read from that experiment's committed analysis.

import fs from "node:fs";
import path from "node:path";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const EXP0006 = path.join(HERE, "../EXP-0006-operational-uic/results");

/** Sum the per-arm economics for a set of run directories. */
export function aggregate(runsDir, filter = () => true) {
  const acc = { units: 0, accepted: 0, turns: 0, uncached: 0, cacheRead: 0, output: 0, cost: 0, elapsed: 0, tasks: [] };
  if (!fs.existsSync(runsDir)) return acc;
  for (const d of fs.readdirSync(runsDir).sort()) {
    if (!filter(d)) continue;
    const rd = path.join(runsDir, d);
    const eco = readJson(path.join(rd, "economics.json"));
    const acp = readJson(path.join(rd, "acceptance.json"));
    const rec = readJson(path.join(rd, "run-record.json"));
    // An inadmissible arm contributes NOTHING — not a zero. Same rule as
    // EXP-0006: a treatment that did not execute is not a treatment that
    // produced nothing.
    if (!eco || rec?.admissible !== true) continue;
    acc.units++;
    acc.tasks.push(d.split(".")[0]);
    if (acp?.accepted === true) acc.accepted++;
    acc.turns += eco.num_turns ?? 0;
    acc.uncached += (eco.uncached_input_tokens ?? 0) + (eco.cache_creation_input_tokens ?? 0);
    acc.cacheRead += eco.cache_read_input_tokens ?? 0;
    acc.output += eco.output_tokens ?? 0;
    acc.cost += eco.total_cost_usd ?? 0;
    acc.elapsed += eco.elapsed_s ?? 0;
  }
  return acc;
}

const readJson = (p) => { try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return null; } };

/** The four rates plus acceptance. Rates, not totals — totals hide the factors. */
export function rates(a) {
  const per = (x) => (a.turns > 0 ? x / a.turns : null);
  return {
    units: a.units,
    accepted: a.accepted,
    acceptance_rate: a.units ? a.accepted / a.units : null,
    turns_per_task: a.units ? a.turns / a.units : null,
    uncached_per_turn: per(a.uncached),
    cache_read_per_turn: per(a.cacheRead),
    output_per_turn: per(a.output),
    cost_per_task: a.units ? a.cost / a.units : null,
    uncached_total: a.uncached,
    UIC: a.uncached > 0 ? a.accepted / (a.uncached / 1_000_000) : null,
  };
}

/**
 * Compare a configuration against the frozen native reference, factor by
 * factor. `verdict` is deliberately NOT a single number: a configuration that
 * improves one factor and worsens another is reported as a TRADE, by name.
 */
export function compare(configRates, nativeRates, targets = TARGETS) {
  const f = (k) => (nativeRates[k] && configRates[k] != null ? configRates[k] / nativeRates[k] : null);
  const factors = {
    turns: f("turns_per_task"),
    context_per_turn: f("cache_read_per_turn"),
    uncached_per_turn: f("uncached_per_turn"),
    output_per_turn: f("output_per_turn"),
  };
  const met = {}, missed = [], improved = [], worsened = [];
  for (const [k, v] of Object.entries(factors)) {
    if (v == null) continue;
    const t = targets[k];
    if (t != null) { met[k] = v <= t; if (v > t) missed.push(`${k} ${v.toFixed(2)}× > target ${t}×`); }
    if (v < 1) improved.push(`${k} ${v.toFixed(2)}×`);
    if (v > 1.02) worsened.push(`${k} ${v.toFixed(2)}×`);
  }
  const compounded = Object.values(factors).filter((v) => v != null && v !== factors.uncached_per_turn)
    .reduce((s, v) => s * v, 1);
  return {
    factors, targets_met: met, targets_missed: missed,
    compounded_estimate: compounded,
    // THE TRADE DETECTOR. This is the whole reason the instrument exists.
    trade_detected: improved.length > 0 && worsened.length > 0,
    trade_note: improved.length && worsened.length
      ? `TRADE, not a win: improved ${improved.join(", ")} while worsening ${worsened.join(", ")}. A single UIC number would have shown one figure and hidden the other.`
      : null,
    acceptance_regression: configRates.acceptance_rate != null && nativeRates.acceptance_rate != null
      && configRates.acceptance_rate < nativeRates.acceptance_rate,
    acceptance_note: "a configuration that reduces cost while losing an accepted outcome has NOT won",
  };
}

/** Operator-set targets, recorded here so a run cannot quietly move them. */
export const TARGETS = { turns: 1.10, context_per_turn: 1.15, uncached_per_turn: 1.15, output_per_turn: 1.10 };

/** The frozen EXP-0006 native reference, restricted to a task set. */
export function nativeReference(taskIds = null) {
  const keep = taskIds ? new Set(taskIds) : null;
  return rates(aggregate(path.join(EXP0006, "runs"),
    (d) => d.endsWith(".native") && (!keep || keep.has(d.split(".")[0]))));
}

/** The frozen EXP-0006 gravito arm, same restriction — the baseline anchor. */
export function baselineReference(taskIds = null) {
  const keep = taskIds ? new Set(taskIds) : null;
  return rates(aggregate(path.join(EXP0006, "runs"),
    (d) => d.endsWith(".gravito") && (!keep || keep.has(d.split(".")[0]))));
}

// ---- CLI ------------------------------------------------------------------
if (process.argv[1] && process.argv[1].endsWith("factors.mjs")) {
  const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
  const tasks = (arg("tasks") || "T01,T02,T03,T04").split(",").map((s) => s.trim());
  const configDir = arg("config-runs", null);

  const nat = nativeReference(tasks);
  const base = baselineReference(tasks);

  const row = (name, r) => `${name.padEnd(10)} ${String(r.units).padStart(2)}u  acc ${r.accepted}/${r.units}  ` +
    `turns/task ${fmt(r.turns_per_task, 1)}  unc/turn ${fmt(r.uncached_per_turn, 0)}  ` +
    `ctx/turn ${fmt(r.cache_read_per_turn, 0)}  out/turn ${fmt(r.output_per_turn, 0)}  ` +
    `$${fmt(r.cost_per_task, 2)}/task  UIC ${fmt(r.UIC, 2)}`;

  console.log(`EXP-0007 factor report — tasks ${tasks.join(",")}\n`);
  console.log(row("native", nat));
  console.log(row("baseline", base));

  const bc = compare(base, nat);
  console.log(`\nbaseline vs native — turns ${fmt(bc.factors.turns, 2)}×  ctx/turn ${fmt(bc.factors.context_per_turn, 2)}×  out/turn ${fmt(bc.factors.output_per_turn, 2)}×`);
  if (bc.targets_missed.length) console.log(`  targets missed: ${bc.targets_missed.join("; ")}`);

  if (configDir) {
    const cfg = rates(aggregate(configDir));
    console.log(row(path.basename(configDir), cfg));
    const c = compare(cfg, nat);
    console.log(`\nconfig vs native — turns ${fmt(c.factors.turns, 2)}×  ctx/turn ${fmt(c.factors.context_per_turn, 2)}×  out/turn ${fmt(c.factors.output_per_turn, 2)}×`);
    console.log(`  compounded ≈ ${fmt(c.compounded_estimate, 2)}×  (baseline ≈ ${fmt(bc.compounded_estimate, 2)}×)`);
    if (c.trade_detected) console.log(`  ${c.trade_note}`);
    if (c.acceptance_regression) console.log(`  ACCEPTANCE REGRESSION — ${c.acceptance_note}`);
    if (c.targets_missed.length) console.log(`  targets missed: ${c.targets_missed.join("; ")}`);
    else console.log("  all factor targets met");
  }
}

function fmt(x, n) { return x == null ? "n/a" : Number(x).toFixed(n); }
