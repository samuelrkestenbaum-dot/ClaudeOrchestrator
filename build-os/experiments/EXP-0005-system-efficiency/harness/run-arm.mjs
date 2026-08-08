#!/usr/bin/env node
// EXP-0005 — execute ONE measured arm.
//
// Sequential by construction: a lock file makes a second measured arm refuse
// rather than queue, because elapsed time is a registered metric and a
// concurrent run would corrupt it silently.
//
// THE PRE-FLIGHT GATE IS A REFUSAL, NOT A WARNING. Nine conditions are checked
// before a child process is launched, and any one of them failing aborts the
// arm with nothing measured. A measurement taken against an unverified tree is
// worse than a missing one: it looks like data.
//
// Usage: run-arm.mjs --task T01 --arm native|gravito [--dry-run]

import { execFileSync, spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { openRun, closeRun, classify, verifyIsolation, scrubbedEnv, newSessionId } from "../../harness/run-record.mjs";

const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const has = (n) => process.argv.includes(`--${n}`);

const HERE = path.dirname(new URL(import.meta.url).pathname);
const EXP = path.join(HERE, "..");
const TASK_ID = arg("task");
const ARM = arg("arm");
const DRY = has("dry-run");

const SEED = "2543c873141fa64653a7993d326465d5e0dd1006";
const CEILING_S = 5400;                       // frozen common ceiling — identical for both arms
const MODEL = process.env.EXP0005_MODEL || "claude-opus-5";
const ARM_TREE = "/home/user/exp0005-arm";
const SHARED_MODULES = "/home/user/empathiq-website/node_modules";
const LOCK = "/home/user/.exp0005/arm.lock";
const RESULTS = path.join(EXP, "results");

if (!TASK_ID || !["native", "gravito"].includes(ARM)) {
  console.error("usage: run-arm.mjs --task T01 --arm native|gravito");
  process.exit(2);
}

const tasks = JSON.parse(fs.readFileSync(path.join(EXP, "tasks/TASKS.json"), "utf8")).tasks;
const task = tasks.find((t) => t.task_id === TASK_ID);
if (!task) { console.error(`REFUSED: unknown task ${TASK_ID}`); process.exit(2); }

const sh = (cmd, a, opts = {}) => execFileSync(cmd, a, { encoding: "utf8", ...opts });

// --- pre-flight -------------------------------------------------------------
const pre = [];
const gate = (name, ok, detail) => { pre.push({ name, ok, detail }); return ok; };

// 9. No other measured arm may be running. Checked FIRST so a concurrent
//    invocation cannot get as far as mutating the arm tree.
let lockOk = true, lockDetail = "acquired";
try {
  fs.mkdirSync(path.dirname(LOCK), { recursive: true });
  const fd = fs.openSync(LOCK, "wx");
  fs.writeFileSync(fd, JSON.stringify({ pid: process.pid, task: TASK_ID, arm: ARM }));
  fs.closeSync(fd);
} catch {
  lockOk = false;
  lockDetail = `another measured arm holds ${LOCK} — elapsed time is a registered metric, so this refuses rather than queues`;
}
gate("no_concurrent_measured_arm", lockOk, lockDetail);

const releaseLock = () => { try { fs.unlinkSync(LOCK); } catch {} };

if (lockOk) {
  // 1 + 2. Exact repository seed AND the pinned memory state, verified by the
  //         canonical pin. restore-seed.sh already asserts HEAD, tree hash,
  //         durable-state digest, a clean tree, and the absence of live
  //         ledgers, and REFUSES on any of them.
  //
  //         This calls the pin rather than recomputing the digest inline. An
  //         earlier version reimplemented the manifest here and disagreed with
  //         it — two definitions of one constant is how a check ends up
  //         verifying something nobody registered.
  let restoreOk = false, restoreDetail = "";
  try {
    fs.rmSync(ARM_TREE, { recursive: true, force: true });
    const o = sh("bash", [path.join(EXP, "harness/restore-seed.sh"), ARM_TREE], { stdio: "pipe" });
    restoreOk = /VERIFIED/.test(o) && sh("git", ["-C", ARM_TREE, "rev-parse", "HEAD"]).trim() === SEED;
    restoreDetail = restoreOk ? `${SEED.slice(0, 12)}, digest 3311a638… verified by the pin` : o.trim().split("\n").slice(-2).join(" | ");
  } catch (e) {
    restoreDetail = `restore refused: ${String(e.stdout || e.message).split("\n").slice(-3).join(" | ")}`;
  }
  gate("exact_seed_restored", restoreOk, restoreDetail);
  gate("frozen_memory_state_restored", restoreOk, restoreOk ? "pinned durable state verified as part of the restore" : "not verified — the restore did not pass");

  // 2/3. Condition administered correctly — the substrate is PRESENT for
  //      gravito and ABSENT for native. This is the treatment itself, so it is
  //      verified rather than assumed.
  const substrate = ["build-os", ".claude", "CLAUDE.md"];
  if (ARM === "native") {
    for (const p of substrate) fs.rmSync(path.join(ARM_TREE, p), { recursive: true, force: true });
    gate("native_arm_has_no_gravito_substrate",
      substrate.every((p) => !fs.existsSync(path.join(ARM_TREE, p))), substrate.join(", ") + " removed");
    gate("correct_condition_administered", true, "native: bare repository path");
  } else {
    // The memory digest is already asserted by the restore above; here the
    // only remaining question is that the substrate the arm will actually use
    // is present.
    const present = substrate.every((p) => fs.existsSync(path.join(ARM_TREE, p)));
    gate("correct_condition_administered", present,
      present ? "gravito: full frozen substrate present" : `gravito: MISSING ${substrate.filter((p) => !fs.existsSync(path.join(ARM_TREE, p))).join(", ")}`);
  }

  // node_modules is shared read-only and IDENTICAL across arms, so it cannot
  // bias the comparison. Installing per arm would add minutes of network time
  // to the elapsed metric instead.
  try { fs.symlinkSync(SHARED_MODULES, path.join(ARM_TREE, "node_modules"), "dir"); } catch {}
  gate("node_modules_available", fs.existsSync(path.join(ARM_TREE, "node_modules/vitest")), "shared, identical across arms");

  gate("common_timeout_unchanged", CEILING_S === 5400, `${CEILING_S}s, identical for both arms`);
}

const failed = pre.filter((p) => !p.ok);
console.log(`PRE-FLIGHT ${TASK_ID}/${ARM}`);
for (const p of pre) console.log(`  ${p.ok ? "ok  " : "FAIL"} ${p.name}: ${p.detail}`);
if (failed.length) {
  console.error(`REFUSED — ${failed.length} pre-flight condition(s) failed. Nothing was measured.`);
  releaseLock();
  process.exit(1);
}
if (DRY) { console.log("dry-run: pre-flight only, no child launched"); releaseLock(); process.exit(0); }

// --- the run record, opened BEFORE launch ------------------------------------
// If the launcher dies, the record already exists and the arm is recorded as
// launcher_died rather than silently absent.
const sessionId = newSessionId();
const runDir = path.join(RESULTS, "runs", `${TASK_ID}.${ARM}`);
fs.mkdirSync(runDir, { recursive: true });
const streamPath = path.join(runDir, "stream.jsonl");

openRun(runDir, {
  experiment: "EXP-0005", task_id: TASK_ID, arm: ARM, seed: SEED, model: MODEL,
  ceiling_s: CEILING_S, session_id: sessionId, tree: ARM_TREE, started_at_iso: new Date().toISOString(),
});

const prompt = [
  `# Task ${task.task_id}`, "",
  task.objective, "",
  "## How this will be judged (identical in both conditions)", "",
  `Verification command: \`${task.verification.command}\``,
  `Expected result: ${task.verification.expect}`,
  `Regression bound: ${task.verification.regression}`, "",
  task.standing_prohibition, "",
  "Work in the current repository. Do not commit, push, or touch anything outside it.",
].join("\n");

fs.writeFileSync(path.join(runDir, "prompt.txt"), prompt);

// Session-scoped environment is scrubbed so the child cannot inherit the
// controller's session identity — calibration attempt 1 measured a child that
// reported the ORCHESTRATOR's session_id.
const env = { ...scrubbedEnv(process.env), CI: "1" };

const started = Date.now();
const out = fs.openSync(streamPath, "w");
const child = spawn("claude", [
  "-p", "--output-format", "stream-json", "--verbose",
  "--model", MODEL, "--session-id", sessionId,
  "--permission-mode", "bypassPermissions",
], { cwd: ARM_TREE, env, stdio: ["pipe", out, "pipe"], detached: true });

let stderr = "";
child.stderr.on("data", (b) => { if (stderr.length < 100_000) stderr += b.toString(); });
child.stdin.write(prompt);   // stdin delivery: an argv prompt over MAX_ARG_STRLEN killed three EXP-0004 arms
child.stdin.end();

const timer = setTimeout(() => {
  try { process.kill(-child.pid, "SIGKILL"); } catch {}
  try { process.kill(child.pid, "SIGKILL"); } catch {}
}, CEILING_S * 1000);

child.on("exit", (code, signal) => {
  clearTimeout(timer);
  fs.closeSync(out);
  const elapsedS = (Date.now() - started) / 1000;
  fs.writeFileSync(path.join(runDir, "stderr.txt"), stderr);

  const verdict = classify({ streamPath, exitCode: code, ceilingS: CEILING_S, elapsedS, launcherAlive: true });
  const isolation = verifyIsolation({
    streamPath, expectedSessionId: sessionId,
    orchestratorSessionId: process.env.CLAUDE_CODE_SESSION_ID || null,
  });
  const closed = closeRun(runDir, { ...verdict, elapsed_s: elapsedS, exit_code: code, signal }, isolation);

  releaseLock();
  // Treatment-neutral reporting only: terminal state and admissibility, never
  // which condition is ahead.
  console.log(`UNIT ${TASK_ID}/${ARM}: terminal=${verdict.terminal_state} admissible=${closed.admissible === true} isolated=${isolation.isolated} elapsed=${elapsedS.toFixed(1)}s`);
  process.exit(0);
});
