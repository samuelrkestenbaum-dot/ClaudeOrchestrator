#!/usr/bin/env node
// Zone 3 — explicit reachability construction: R_t (executable, authorized,
// feasible) and admissible R_t+ over the supported action set, with a
// per-action reason trail. READ-ONLY: this surface reports and selects; it
// never grants. Authority stays with the gates (goal-check, routing-gate,
// publish-check) — a duplicate blocking layer here would be a second
// control, not a better one.
//
// CANONICAL CONSUMERS TODAY: (1) bin/gravito cmd_run — dispatch admission:
// the worker dispatches ONLY if 'run' is in R_t+, and the authority gate
// (goal-check --gate) is invoked exactly once, HERE, inside the
// construction — so admission and authority are one evaluation, not two
// competing controls; (2) `gravito health` (operator surface). The
// "construct R_t BEFORE planning/SCORING" half of the contract still has
// NO planner consumer — that dependency is REPORTED, not silently wired:
// selectAction() below is the future planner's entry, exercised by tests.
//
// SCORE-RESURRECTION INVARIANT: selectAction(scores) takes argmax strictly
// over R_t+; a score for an action outside R_t+ is ignored by construction.
//
// Usage: reachability.mjs [--json] DIR

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

export function constructReachability(dir) {
  const sh = (cmd, args) => { try { return execFileSync(cmd, args, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"] }).trim(); } catch { return null; } };
  const exists = (p) => fs.existsSync(path.join(dir, p));
  const gravitoRoot = path.resolve(path.dirname(new URL(import.meta.url).pathname), "../..");
  const goalInstalled = exists("gravito.goal");
  let gateOpen = null, gateReason = "no goal installed — gate inactive by contract scope";
  if (goalInstalled) {
    const gc = exists("build-os/tools/goal-check.sh")
      ? path.join(dir, "build-os/tools/goal-check.sh")
      : path.join(gravitoRoot, "build-os/tools/goal-check.sh");
    try { execFileSync("bash", [gc, "--gate", path.join(dir, "gravito.goal")], { stdio: "pipe" }); gateOpen = true; gateReason = "goal gate OPEN"; }
    catch (e) { gateOpen = false; gateReason = (e.stdout?.toString() || "goal gate HALT").split("\n")[0]; }
  }
  const workerLive = (() => {
    try { const pid = Number(fs.readFileSync(path.join(dir, "build-os/receipts/run.pid"), "utf8").trim()); process.kill(pid, 0); return true; } catch { return false; }
  })();
  const claudeCli = sh("bash", ["-c", "command -v claude"]) !== null;
  const manifest = fs.existsSync(path.join(dir, "build-os/receipts")) &&
    fs.readdirSync(path.join(dir, "build-os/receipts")).filter((f) => f.startsWith("install-manifest-")).length;

  // The supported action set, each with executable/authorized/feasible facts.
  const actions = [
    { a: "status",    executable: true, authorized: true, feasible: true, reason: "read-only, always reachable" },
    { a: "diagnose",  executable: true, authorized: true, feasible: true, reason: "read-only bundle, always reachable" },
    { a: "stop",      executable: true, authorized: true, feasible: true, reason: "emergency stop must always be reachable" },
    { a: "review",    executable: true, authorized: true, feasible: goalInstalled, reason: goalInstalled ? "goal present" : "no goal to review against" },
    { a: "run",       executable: claudeCli, authorized: goalInstalled ? gateOpen === true : false,
      feasible: goalInstalled && !workerLive,
      reason: !goalInstalled ? "no goal installed" : !claudeCli ? "provider CLI absent" : workerLive ? "worker already in flight" : gateReason },
    { a: "rollback",  executable: true, authorized: true, feasible: manifest >= 2, reason: manifest >= 2 ? "previous manifest exists" : "no previous manifest" },
    { a: "uninstall", executable: true, authorized: true, feasible: manifest >= 1, reason: manifest >= 1 ? "manifest recorded" : "nothing recorded to uninstall" },
    { a: "push",      executable: true, authorized: false, feasible: true, reason: "external mutation — requires fresh operator go + publish gate; NEVER reachable autonomously" },
  ];
  const R_t = actions.filter((x) => x.executable && x.authorized && x.feasible).map((x) => x.a);
  // Admissibility E(a)=1: today identical to authorized for this set; kept
  // distinct so a future ethical filter narrows without redefining R_t.
  const R_t_plus = R_t;
  return { artifact: "reachability", dir, gate: gateReason, actions, R_t, R_t_plus,
    viable_count: R_t_plus.length,
    dispatch_consumer: "bin/gravito cmd_run — admission is a real input: dispatch only if 'run' in R_t+",
    planner_consumer: "ABSENT — reported dependency: no planning/scoring layer consumes R_t yet" };
}

/** Future planner entry. argmax STRICTLY over R_t+; outside scores ignored. */
export function selectAction(reach, scores = {}) {
  let best = null, bestScore = -Infinity;
  for (const a of reach.R_t_plus) {
    const s = scores[a] ?? 0;
    if (s > bestScore) { best = a; bestScore = s; }
  }
  return { selected: best, ignored_scores: Object.keys(scores).filter((k) => !reach.R_t_plus.includes(k)) };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const json = process.argv.includes("--json");
  const dir = process.argv.filter((x) => !x.startsWith("--")).slice(2)[0] || process.cwd();
  const r = constructReachability(path.resolve(dir));
  if (json) console.log(JSON.stringify(r, null, 2));
  else {
    console.log(`reachability — ${r.viable_count} viable action(s): ${r.R_t_plus.join(", ")}`);
    for (const x of r.actions) if (!r.R_t_plus.includes(x.a)) console.log(`  unreachable: ${x.a} — ${x.reason}`);
    console.log(`  planner consumer: ${r.planner_consumer.split(" — ")[0]}`);
  }
}
