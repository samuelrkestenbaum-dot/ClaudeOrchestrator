#!/usr/bin/env node
// REAL acceptance-oracle runner (AMENDMENT v6 — surgical-review finding F1).
//
// The review found the measured path had NO committed compiler invocation:
// runMeasured takes oracleFor as a parameter and nothing frozen supplied it,
// so a spend-time run would have needed ad-hoc unfrozen glue — and a null/
// failed compile would have parsed as ZERO errors, i.e. FAIL-OPEN
// acceptance. This module closes both:
//   - the compile runs through the typed exec registry (the only allowed
//     bash shape), in the cell's worktree, with the frozen verify command;
//   - exit semantics FAIL CLOSED: tsc exit 0 (clean) and exit 2 (type
//     errors, non-empty diagnostics) are the ONLY valid outcomes; exit 1,
//     unknown codes, registry refusals, timeouts, or exit-2-with-empty-
//     output all throw ORACLE_RUN_FAILED — the state machine records the
//     cell infrastructure-invalid rather than ever inventing a clean run;
//   - the seed diff comes from git in the same worktree (registry-gated).
import fs from "node:fs";
import path from "node:path";
import { runRegistered } from "./exec-registry.mjs";

export function makeOracleRunner({ corpusDir }) {
  const baselineText = fs.readFileSync(path.join(corpusDir, "baseline-tsc.txt"), "utf8");
  return ({ worktree, kind }) => {
    const r = runRegistered("bash", ["-c", `cd ${worktree} && npx tsc --noEmit -p tsconfig.json`],
      { timeoutMs: 900_000, env: { PATH: process.env.PATH, HOME: process.env.HOME } });
    if (r.refused) throw new Error(`ORACLE_RUN_FAILED:${r.refused}`);
    const afterText = r.stdout ?? "";
    const okExit = r.status === 0 || r.status === 2;
    if (!okExit) throw new Error(`ORACLE_RUN_FAILED:tsc_exit_${r.status}`);
    if (r.status === 2 && !/error TS\d+/.test(afterText)) throw new Error("ORACLE_RUN_FAILED:exit2_without_diagnostics");
    let diffText = "";
    if (kind === "seed") {
      const d = runRegistered("git", ["-C", worktree, "diff", "HEAD"], { timeoutMs: 120_000 });
      if (d.refused || d.status !== 0) throw new Error(`ORACLE_RUN_FAILED:diff_${d.refused ?? d.status}`);
      diffText = d.stdout ?? "";
    }
    return { baselineText, afterText, diffText };
  };
}
