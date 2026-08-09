#!/usr/bin/env node
// EXP-0006 — execute ONE measured arm.
//
// Inherits EXP-0005's hard lessons, each of which cost a run:
//   * the work product is captured BEFORE anything can destroy the tree —
//     EXP-0005 recorded economics and let the next arm delete four arms' diffs,
//     which is the UIC NUMERATOR;
//   * the prompt is delivered on STDIN — an argv prompt over MAX_ARG_STRLEN
//     killed three EXP-0004 arms;
//   * the child's environment is SCRUBBED and its session id is EXPLICIT — an
//     inherited session makes measurer and measured the same process family;
//   * arms are SEQUENTIAL by lock, because elapsed time is a registered metric.
//
// AND ONE THAT EXP-0005 DID NOT HAVE. The administered condition is committed
// into the arm tree before launch, so the arm's diff is measured against the
// state it actually started from. EXP-0005 could get away with a status-based
// diff because its only pre-launch mutation was three deletions. Here the
// Gravito arm's substrate administration touches thousands of files, and
// attributing those to the arm would hand it a diff it did not write.
//
// Usage: run-arm.mjs --task T01 --arm native|gravito [--dry-run]

import { execFileSync, spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { openRun, closeRun, classify, verifyIsolation, scrubbedEnv, newSessionId } from "../../harness/run-record.mjs";
import { splitPaths } from "../../EXP-0005-system-efficiency/blinding/governance-strip.mjs";
import { administer, verifyAdministration, CODE_SOURCE } from "./substrate.mjs";
import { adjudicate } from "./acceptance.mjs";

const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const has = (n) => process.argv.includes(`--${n}`);

const HERE = path.dirname(new URL(import.meta.url).pathname);
const EXP = path.join(HERE, "..");
const RESULTS = path.join(EXP, "results");
const TASK_ID = arg("task");
const ARM = arg("arm");
const DRY = has("dry-run");

// --- FROZEN EXECUTION PARAMETERS -------------------------------------------
// Recorded here, in code, before any arm runs. The preregistration requires
// "one common ceiling per task, both arms, recorded before execution"; this is
// that record. 1200s is a deliberate tightening from EXP-0005's 5400s: these
// are single-file typecheck repairs of 1-17 errors, and a run that has not
// converged in twenty minutes has not encountered a harder task, it has
// encountered a failure mode.
const CEILING_S = 1200;
const SEED = "2543c873141fa64653a7993d326465d5e0dd1006";
const MODEL = process.env.EXP0006_MODEL || "claude-opus-5";
const ARM_TREE = "/home/user/exp0006-arm";
const SHARED_MODULES = "/home/user/empathiq-website/node_modules";
const LOCK = "/home/user/.exp0006/arm.lock";
// EXP-0005's restore script is INVOKED, never edited. It performs and verifies
// the identical seed restore, and a second definition of one constant is how a
// check ends up verifying something nobody registered.
const RESTORE = path.join(EXP, "..", "EXP-0005-system-efficiency/harness/restore-seed.sh");
const VERIFY_CMD = "npx tsc --noEmit -p tsconfig.json";

if (!TASK_ID || !["native", "gravito"].includes(ARM)) {
  console.error("usage: run-arm.mjs --task T01 --arm native|gravito");
  process.exit(2);
}

const sel = JSON.parse(fs.readFileSync(path.join(RESULTS, "task-selection.json"), "utf8"));
const task = sel.selected.find((t) => t.task_id === TASK_ID);
if (!task) { console.error(`REFUSED: unknown task ${TASK_ID}`); process.exit(2); }

const baselineRaw = fs.readFileSync(path.join(RESULTS, "baseline-tsc.txt"), "utf8");
const sh = (cmd, a, opts = {}) => execFileSync(cmd, a, { encoding: "utf8", ...opts });

// --- pre-flight: refusals, not warnings -------------------------------------
const pre = [];
const gate = (name, ok, detail) => { pre.push({ name, ok, detail }); return ok; };

let lockOk = true, lockDetail = "acquired";
try {
  fs.mkdirSync(path.dirname(LOCK), { recursive: true });
  const fd = fs.openSync(LOCK, "wx");
  fs.writeFileSync(fd, JSON.stringify({ pid: process.pid, task: TASK_ID, arm: ARM }));
  fs.closeSync(fd);
} catch {
  lockOk = false;
  lockDetail = `another measured arm holds ${LOCK} — elapsed is a registered metric, so this refuses rather than queues`;
}
gate("no_concurrent_measured_arm", lockOk, lockDetail);
const releaseLock = () => { try { fs.unlinkSync(LOCK); } catch {} };

let administration = null, administeredSha = null;

if (lockOk) {
  let restoreOk = false, restoreDetail = "";
  try {
    fs.rmSync(ARM_TREE, { recursive: true, force: true });
    const o = sh("bash", [RESTORE, ARM_TREE], { stdio: "pipe" });
    restoreOk = /VERIFIED/.test(o) && sh("git", ["-C", ARM_TREE, "rev-parse", "HEAD"]).trim() === SEED;
    restoreDetail = restoreOk ? `${SEED.slice(0, 12)} restored and verified against the registered pin` : o.trim().split("\n").slice(-2).join(" | ");
  } catch (e) {
    restoreDetail = `restore refused: ${String(e.stdout || e.message).split("\n").slice(-3).join(" | ")}`;
  }
  gate("exact_seed_restored", restoreOk, restoreDetail);

  if (restoreOk) {
    // The treatment itself. Administered, then VERIFIED — the distinction that
    // EXP-0005 collapsed and paid twelve arms for.
    administration = administer(ARM_TREE, ARM, CODE_SOURCE);
    const v = verifyAdministration(ARM_TREE, ARM);
    for (const c of v.checks) gate(`administration.${c.name}`, c.ok, c.detail);

    // The task file must still exist and still carry its registered errors, or
    // the administration damaged the work before the arm saw it.
    gate("task_file_present", fs.existsSync(path.join(ARM_TREE, task.file)), task.file);

    // Freeze the administered state as a commit. Everything after this point
    // that differs from it is the ARM's work, and nothing before it is.
    try {
      sh("git", ["-C", ARM_TREE, "-c", "user.email=harness@exp0006", "-c", "user.name=exp0006-harness", "add", "-A"]);
      sh("git", ["-C", ARM_TREE, "-c", "user.email=harness@exp0006", "-c", "user.name=exp0006-harness",
        "commit", "-q", "--allow-empty", "-m", `exp0006: administered condition ${ARM}`]);
      administeredSha = sh("git", ["-C", ARM_TREE, "rev-parse", "HEAD"]).trim();
      gate("administered_state_committed", true, `${administeredSha.slice(0, 12)} — the arm's diff is measured against this, not against the seed`);
    } catch (e) {
      gate("administered_state_committed", false, String(e.stdout || e.message).slice(0, 300));
    }
  }

  try { fs.symlinkSync(SHARED_MODULES, path.join(ARM_TREE, "node_modules"), "dir"); } catch {}
  gate("node_modules_available", fs.existsSync(path.join(ARM_TREE, "node_modules/typescript")),
    "shared read-only, byte-identical across arms, so it cannot bias the comparison");
  gate("common_ceiling_recorded", CEILING_S === 1200, `${CEILING_S}s, identical for both arms and frozen in this file`);
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

// --- run record, opened BEFORE launch ---------------------------------------
const sessionId = newSessionId();
const runDir = path.join(RESULTS, "runs", `${TASK_ID}.${ARM}`);
fs.mkdirSync(runDir, { recursive: true });
const streamPath = path.join(runDir, "stream.jsonl");

openRun(runDir, {
  task_id: TASK_ID, arm: ARM,
  launched_at: new Date().toISOString(),
  expected_session_id: sessionId,
  orchestrator_session_id: process.env.CLAUDE_CODE_SESSION_ID || null,
  timeout_ceiling_s: CEILING_S,
});
fs.writeFileSync(path.join(runDir, "administration.json"),
  JSON.stringify({ ...administration, administered_sha: administeredSha, code_source: administration?.code_source ?? null }, null, 2));

// The prompt is IDENTICAL in both arms. Any difference here would be a second
// treatment riding alongside the one being measured.
const prompt = [
  `# Task ${task.task_id}`, "",
  `Fix the TypeScript type errors in \`${task.file}\`.`, "",
  `That file currently has ${task.error_count} typecheck error(s) (${task.codes.join(", ")}).`,
  `The first is at line ${task.first_error.line}: ${task.first_error.code}: ${task.first_error.msg}`, "",
  "## How this will be judged (identical in both conditions)", "",
  `Verification command: \`${VERIFY_CMD}\``,
  `Accepted when: the command reports ZERO errors for \`${task.file}\`, AND no new error appears in any other file.`,
  "",
  "REJECTED, regardless of the compiler result: `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `any` casts,",
  "or deleting the offending code. Fix the type, do not silence it.",
  "",
  "Work in the current repository. Do not push, and do not touch anything outside it.",
].join("\n");
fs.writeFileSync(path.join(runDir, "prompt.txt"), prompt);

const env = { ...scrubbedEnv(process.env), CI: "1" };
const started = Date.now();
const out = fs.openSync(streamPath, "w");
const child = spawn("claude", [
  "-p", "--output-format", "stream-json", "--verbose",
  "--model", MODEL, "--session-id", sessionId,
  "--permission-mode", "acceptEdits",
], { cwd: ARM_TREE, env, stdio: ["pipe", out, "pipe"], detached: true });

let stderr = "";
child.stderr.on("data", (b) => { if (stderr.length < 100_000) stderr += b.toString(); });
child.stdin.write(prompt);
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

  // --- WORK PRODUCT FIRST. Nothing below may run before this. --------------
  let acceptance = null, productPaths = [], govPaths = [];
  try {
    const base = administeredSha || "HEAD";
    const excl = [":(exclude)node_modules", ":(exclude)node_modules/**"];
    const changed = sh("git", ["-C", ARM_TREE, "status", "--porcelain", "--", ".", ...excl])
      .split("\n").filter(Boolean)
      .map((l) => ({ status: l.slice(0, 2).trim(), path: l.slice(3).replace(/^"|"$/g, "") }))
      .filter((c) => c.path !== "node_modules" && !c.path.startsWith("node_modules/"));

    const tracked = sh("git", ["-C", ARM_TREE, "diff", base, "--", ".", ...excl],
      { maxBuffer: 128 * 1024 * 1024 });
    const untracked = changed.filter((c) => c.status === "??").map((c) => c.path);
    const untrackedBody = untracked.map((p) => {
      try { return `diff --git a/${p} b/${p}\n--- /dev/null\n+++ b/${p}\n` + fs.readFileSync(path.join(ARM_TREE, p), "utf8").split("\n").map((l) => "+" + l).join("\n"); }
      catch { return `diff --git a/${p} b/${p}\n+++ b/${p}\n(unreadable)`; }
    }).join("\n");
    const fullDiff = tracked + "\n" + untrackedBody;
    fs.writeFileSync(path.join(runDir, "full.diff"), fullDiff);

    const split = splitPaths(changed.map((c) => c.path));
    productPaths = split.product_paths;
    govPaths = split.governance_paths;
    fs.writeFileSync(path.join(runDir, "changed-paths.json"), JSON.stringify({
      base_commit: base, product_paths: productPaths, governance_paths: govPaths,
      note: "governance paths are DENOMINATOR COST and receive no numerator credit; measured against the administered commit, so substrate administration is not attributed to the arm",
    }, null, 2));

    // --- the frozen verification, run in the arm tree ---------------------
    let vOut = "", vCode = null;
    try {
      vOut = sh("bash", ["-lc", VERIFY_CMD], { cwd: ARM_TREE, timeout: 900_000, maxBuffer: 128 * 1024 * 1024, stdio: "pipe" });
      vCode = 0;
    } catch (e) { vOut = String(e.stdout || "") + String(e.stderr || ""); vCode = e.status ?? null; }
    fs.writeFileSync(path.join(runDir, "verification.txt"), `$ ${VERIFY_CMD}\n(exit ${vCode})\n\n${vOut}`);

    acceptance = adjudicate({ baselineRaw, afterRaw: vOut, taskFile: task.file, diff: fullDiff });
    acceptance.verification_exit_code = vCode;
    fs.writeFileSync(path.join(runDir, "acceptance.json"), JSON.stringify(acceptance, null, 2));
  } catch (e) {
    fs.writeFileSync(path.join(runDir, "capture-error.txt"), String(e.stack || e.message));
  }

  // --- economics, from the provider's own result event ----------------------
  try {
    const ev = fs.readFileSync(streamPath, "utf8").split("\n").filter(Boolean)
      .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
    const res = ev.find((e) => e.type === "result") || {};
    const u = res.usage || {};
    // "Whether Gravito entered and remained operational" — the field whose
    // absence made EXP-0005 unreadable. Derived from the child's own tool use,
    // not from whether the substrate was installed.
    const toolNames = ev.flatMap((e) => (e?.message?.content || []).filter((c) => c?.type === "tool_use").map((c) => c.name));
    const subagents = toolNames.filter((n) => n === "Task" || n === "Agent").length;
    fs.writeFileSync(path.join(runDir, "economics.json"), JSON.stringify({
      uncached_input_tokens: u.input_tokens ?? null,      // never coerced to 0 when absent
      cache_read_input_tokens: u.cache_read_input_tokens ?? null,
      cache_creation_input_tokens: u.cache_creation_input_tokens ?? null,
      output_tokens: u.output_tokens ?? null,
      num_turns: res.num_turns ?? null,
      duration_api_ms: res.duration_api_ms ?? null,
      total_cost_usd: res.total_cost_usd ?? null,
      elapsed_s: elapsedS,
      tool_calls: toolNames.length,
      subagent_invocations: subagents,
      product_files_changed: productPaths.length,
      governance_files_changed: govPaths.length,
      gravito_operational: ARM === "gravito" ? { substrate_administered: true, governance_output_observed: govPaths.length > 0, subagents_dispatched: subagents } : null,
    }, null, 2));
  } catch (e) {
    fs.appendFileSync(path.join(runDir, "capture-error.txt"), "\n" + String(e.stack || e.message));
  }

  const verdict = classify({ streamPath, exitCode: code, ceilingS: CEILING_S, elapsedS, launcherAlive: true });
  const isolation = verifyIsolation({
    streamPath, expectedSessionId: sessionId,
    orchestratorSessionId: process.env.CLAUDE_CODE_SESSION_ID || null,
  });
  const closed = closeRun(runDir, { ...verdict, elapsed_s: elapsedS, exit_code: code, signal }, isolation);

  releaseLock();
  // Treatment-neutral reporting: terminal state and admissibility only.
  console.log(`UNIT ${TASK_ID}/${ARM}: terminal=${verdict.terminal_reason} admissible=${closed.admissible === true} isolated=${isolation.isolated} accepted=${acceptance ? acceptance.accepted : "uncaptured"} elapsed=${elapsedS.toFixed(1)}s`);
  process.exit(0);
});
