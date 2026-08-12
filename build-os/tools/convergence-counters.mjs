#!/usr/bin/env node
// Zone 9 — deterministic convergence baselines (Class B DIAGNOSTICS ONLY).
// P_verified, R_meta, F_positive from OBSERVABLE events with explicit
// denominators, declared zero/undefined handling, and an evidence scale.
//
// Canonical caller: bin/gravito cmd_review (report block). These counters
// may report or shape review; they MUST NOT authorize, block, rank, or
// alter worker context — no gate references this module (invariant-tested).
//
// Deterministic definitions (v1 — proxies are DECLARED, not implied):
//   verified_change      = commits in window touching at least one non-doc
//                          file (code/tests/config) — an observable state
//                          change, event scale
//   interpretive_change  = commits touching ONLY docs/**, *.md — observable
//                          interpretation without state change
//   matched_predictions  = deltas.jsonl lines, mismatch=false
//   missed_predictions   = deltas.jsonl lines, mismatch=true
//   F_positive           = missed predictions whose predicted value claimed
//                          success ("PASS"/"accepted")
//   P_verified = verified_change / (verified_change + interpretive_change)
//   R_meta     = interpretive_change / verified_change
// Zero handling: denominator 0 => "UNDEFINED (<reason>)" — never Infinity,
// never silently 0. Semantic activity with zero verified change is REPORTED
// as not-progress, never as progress.
//
// Usage: convergence-counters.mjs [--json] [--window N_COMMITS] DIR

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

export function computeCounters(dir, windowCommits = 50) {
  const git = (args) => { try { return execFileSync("git", ["-C", dir, ...args], { encoding: "utf8" }); } catch { return ""; } };
  const shas = git(["log", `-${windowCommits}`, "--format=%H"]).split("\n").filter(Boolean);
  let verified = 0, interpretive = 0;
  for (const s of shas) {
    const files = git(["show", "--name-only", "--format=", s]).split("\n").filter(Boolean);
    if (!files.length) continue;
    const docOnly = files.every((f) => f.endsWith(".md") || f.startsWith("docs/"));
    if (docOnly) interpretive++; else verified++;
  }
  let matched = 0, missed = 0, fpos = 0;
  const df = path.join(dir, "build-os/receipts/deltas.jsonl");
  if (fs.existsSync(df)) for (const raw of fs.readFileSync(df, "utf8").split("\n").filter(Boolean)) {
    try {
      const d = JSON.parse(raw);
      if (d.mismatch === false) matched++;
      if (d.mismatch === true) { missed++; if (/pass|accept/i.test(String(d.predicted))) fpos++; }
    } catch { /* torn line: delta-receipt verify owns reporting it */ }
  }
  const totalCommits = verified + interpretive;
  const P_verified = totalCommits === 0
    ? "UNDEFINED (no commits in window — no activity to grade)"
    : +(verified / totalCommits).toFixed(3);
  const R_meta = verified === 0
    ? (interpretive > 0
        ? `UNDEFINED (interpretive activity ${interpretive} with ZERO verified change — this is NOT progress)`
        : "UNDEFINED (no activity)")
    : +(interpretive / verified).toFixed(3);
  return {
    artifact: "convergence_counters", class: "B-diagnostic",
    authority: "reports only — never authorizes, blocks, ranks, or reaches worker context",
    window_commits: windowCommits, evidence_scale: "task",
    numerators_denominators: {
      verified_change: verified, interpretive_change: interpretive,
      matched_predictions: matched, missed_predictions: missed,
    },
    P_verified, R_meta, F_positive: fpos,
  };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const json = process.argv.includes("--json");
  const wIdx = process.argv.indexOf("--window");
  const w = wIdx > 0 ? Number(process.argv[wIdx + 1]) : 50;
  const dir = process.argv.filter((x, i) => !x.startsWith("--") && (wIdx < 0 || i !== wIdx + 1)).slice(2)[0] || process.cwd();
  const c = computeCounters(path.resolve(dir), w);
  if (json) console.log(JSON.stringify(c, null, 2));
  else {
    console.log(`convergence (last ${c.window_commits} commits, ${c.evidence_scale} scale, diagnostics only):`);
    console.log(`  P_verified: ${c.P_verified}  (verified ${c.numerators_denominators.verified_change} / total ${c.numerators_denominators.verified_change + c.numerators_denominators.interpretive_change})`);
    console.log(`  R_meta:     ${c.R_meta}  (interpretive ${c.numerators_denominators.interpretive_change} / verified ${c.numerators_denominators.verified_change})`);
    console.log(`  F_positive: ${c.F_positive}  (claimed-success predictions that missed)`);
  }
}
