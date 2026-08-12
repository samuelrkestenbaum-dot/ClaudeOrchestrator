#!/usr/bin/env node
// EXP-0012 — calibration probe arm. Native-only, tree/lock from env, same
// seed/model/grants/ceiling/economics capture as the real runners. Exists so
// serial-vs-wide calibration measures the ENVIRONMENT, never a treatment.
// The probe task is fixed: EXP-0009's A1 cell (TS18047 x16 in
// alert-analytics.ts) — small, well-characterized, single error class.
//
// Usage: ARM_TREE=... ARM_LOCK=... probe-arm.mjs --label serial-1 --outdir results/calibration

import { spawn, execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { openRun, closeRun, classify, verifyIsolation, scrubbedEnv, newSessionId } from "../harness/run-record.mjs";
import { administer, verifyAdministration } from "../EXP-0006-operational-uic/harness/substrate.mjs";

const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const HERE = path.dirname(new URL(import.meta.url).pathname);
const LABEL = arg("label");
const OUT = path.resolve(HERE, arg("outdir", "results/calibration"));
const ARM_TREE = process.env.ARM_TREE, LOCK = process.env.ARM_LOCK;
if (!LABEL || !ARM_TREE || !LOCK) { console.error("need --label and ARM_TREE/ARM_LOCK env"); process.exit(2); }

const SEED = "2543c873141fa64653a7993d326465d5e0dd1006";
const MODEL = process.env.EXP0012_MODEL || "claude-opus-5";
const CEILING_S = 1200;
const RESTORE = path.join(HERE, "../EXP-0005-system-efficiency/harness/restore-seed.sh");
const ALLOWED = ["Bash(npx tsc:*)", "Bash(./node_modules/.bin/tsc:*)", "Bash(node_modules/.bin/tsc:*)"];
const BASH_TIMEOUTS = { BASH_DEFAULT_TIMEOUT_MS: "600000", BASH_MAX_TIMEOUT_MS: "600000" };
const task = JSON.parse(fs.readFileSync(path.join(HERE, "../EXP-0009-memory-compounding/sequences.json"), "utf8")).sequences.A[0];
const sh = (c, a, o = {}) => execFileSync(c, a, { encoding: "utf8", ...o });

// lock (per-worker, not the shared study lock)
fs.mkdirSync(path.dirname(LOCK), { recursive: true });
const fd = fs.openSync(LOCK, "wx"); fs.writeFileSync(fd, String(process.pid)); fs.closeSync(fd);
const release = () => { try { fs.rmSync(LOCK, { force: true }); } catch {} };

// tree: reset in place if provisioned, else restore
try {
  const head = sh("git", ["-C", ARM_TREE, "rev-parse", "HEAD"]).trim();
  if (head === SEED) { sh("git", ["-C", ARM_TREE, "checkout", "--", "."]); sh("git", ["-C", ARM_TREE, "clean", "-fdq", "-e", "node_modules"]); }
  else throw new Error("wrong head");
} catch {
  fs.rmSync(ARM_TREE, { recursive: true, force: true });
  sh("bash", [RESTORE, ARM_TREE], { stdio: "pipe" });
  try { fs.symlinkSync("/home/user/empathiq-website/node_modules", path.join(ARM_TREE, "node_modules"), "dir"); } catch {}
}
administer(ARM_TREE, "native");
const va = verifyAdministration(ARM_TREE, "native");
if (!va.checks.every((c) => c.ok)) { console.error("administration failed"); release(); process.exit(1); }

const prompt = [
  `# Task ${task.task_id}`, "",
  `Fix the TypeScript type errors in \`${task.file}\`.`, "",
  `That file currently has ${task.error_count} typecheck error(s) (${task.codes.join(", ")}).`,
  `The first is at line ${task.first_error.line}: ${task.first_error.code}: ${task.first_error.msg}`, "",
  "## How this will be judged (identical in both conditions)", "",
  "Verification command: `npx tsc --noEmit -p tsconfig.json`",
  `Accepted when: the command reports ZERO errors for \`${task.file}\`, AND no new error appears in any other file.`,
  "",
  "REJECTED, regardless of the compiler result: `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `any` casts,",
  "or deleting the offending code. Fix the type, do not silence it.",
  "",
  "Work in the current repository. Do not push, and do not touch anything outside it.",
].join("\n");

const runDir = path.join(OUT, LABEL);
fs.mkdirSync(runDir, { recursive: true });
const sessionId = newSessionId();
const streamPath = path.join(runDir, "stream.jsonl");
openRun(runDir, { task_id: `probe-${LABEL}`, arm: "native", launched_at: new Date().toISOString(),
  expected_session_id: sessionId, orchestrator_session_id: process.env.CLAUDE_CODE_SESSION_ID || null, timeout_ceiling_s: CEILING_S });

const started = Date.now();
const out = fs.openSync(streamPath, "w");
const child = spawn("claude", ["-p", "--output-format", "stream-json", "--verbose", "--model", MODEL,
  "--session-id", sessionId, "--permission-mode", "acceptEdits", "--allowedTools", ...ALLOWED],
  { cwd: ARM_TREE, env: { ...scrubbedEnv(process.env), CI: "1", ...BASH_TIMEOUTS }, stdio: ["pipe", out, "pipe"], detached: true });
child.stdin.write(prompt); child.stdin.end();
const timer = setTimeout(() => { try { process.kill(-child.pid, "SIGKILL"); } catch {} try { process.kill(child.pid, "SIGKILL"); } catch {} }, CEILING_S * 1000);

child.on("exit", (code, signal) => {
  clearTimeout(timer); fs.closeSync(out);
  const elapsedS = (Date.now() - started) / 1000;
  try {
    const ev = fs.readFileSync(streamPath, "utf8").split("\n").filter(Boolean).map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
    const res = ev.find((e) => e.type === "result") || {}; const u = res.usage || {};
    fs.writeFileSync(path.join(runDir, "economics.json"), JSON.stringify({
      label: LABEL, elapsed_s: elapsedS, total_cost_usd: res.total_cost_usd ?? null, num_turns: res.num_turns ?? null,
      uncached_input_tokens: u.input_tokens ?? null, cache_read_input_tokens: u.cache_read_input_tokens ?? null,
      cache_creation_input_tokens: u.cache_creation_input_tokens ?? null,
    }, null, 2));
  } catch {}
  const verdict = classify({ streamPath, exitCode: code, ceilingS: CEILING_S, elapsedS, launcherAlive: true });
  const isolation = verifyIsolation({ streamPath, expectedSessionId: sessionId, orchestratorSessionId: process.env.CLAUDE_CODE_SESSION_ID || null });
  const closed = closeRun(runDir, { ...verdict, elapsed_s: elapsedS, exit_code: code, signal }, isolation);
  release();
  console.log(`PROBE ${LABEL}: terminal=${verdict.terminal_reason} admissible=${closed.admissible === true} elapsed=${elapsedS.toFixed(1)}s`);
  process.exit(0);
});
