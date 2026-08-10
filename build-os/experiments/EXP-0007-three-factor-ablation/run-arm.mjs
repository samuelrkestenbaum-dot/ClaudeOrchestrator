#!/usr/bin/env node
// EXP-0007 — one screening arm.
//
// Administration, acceptance and run-recording are IMPORTED from EXP-0006, not
// forked. That experiment is published; changing the code that produced its
// results would make the comparison against its frozen native arm meaningless.
// The only thing this adds is the variant transform and its verification.
//
// The native arm is NEVER run here. EXP-0006's is the reference.
//
// Usage: run-arm.mjs --task T01 --config baseline|A|B|C|ABC [--dry-run]

import { execFileSync, spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { openRun, closeRun, classify, verifyIsolation, scrubbedEnv, newSessionId } from "../harness/run-record.mjs";
import { splitPaths } from "../EXP-0005-system-efficiency/blinding/governance-strip.mjs";
import { administer, verifyAdministration, CODE_SOURCE } from "../EXP-0006-operational-uic/harness/substrate.mjs";
import { adjudicate } from "../EXP-0006-operational-uic/harness/acceptance.mjs";
import { applyVariant, verifyVariant, CONFIGS } from "./variants.mjs";

const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const HERE = path.dirname(new URL(import.meta.url).pathname);
const EXP6 = path.join(HERE, "../EXP-0006-operational-uic");
const RESULTS = path.join(HERE, "results");
const TASK_ID = arg("task"), CONFIG = arg("config"), DRY = process.argv.includes("dry-run") || process.argv.includes("--dry-run");
// REPLICATION. Repeats of the same (task, config) must not overwrite each
// other -- the whole point of a replication is that the spread between repeats
// IS the measurement. Rep 1 keeps the original directory name so the screening
// run remains addressable and is not silently renamed under the analysis.
const REP = Number(arg("rep", "1"));

const CEILING_S = 1200;                       // identical to EXP-0006, so elapsed is comparable
const SEED = "2543c873141fa64653a7993d326465d5e0dd1006";
const MODEL = process.env.EXP0007_MODEL || "claude-opus-5";
const ARM_TREE = "/home/user/exp0007-arm";
const SHARED_MODULES = "/home/user/empathiq-website/node_modules";
const LOCK = "/home/user/.exp0007/arm.lock";
const RESTORE = path.join(HERE, "../EXP-0005-system-efficiency/harness/restore-seed.sh");
const VERIFY_CMD = "npx tsc --noEmit -p tsconfig.json";

// THE VERIFICATION DIMENSION — the only thing this switch changes.
//
// Every arm run before this existed was STARVED: launched `--permission-mode
// acceptEdits` with no `--allowedTools`, headless, so edits auto-accepted and
// every Bash call prompted with no approver present. The judged verification
// command therefore could not execute in EITHER arm. Native answered by saying
// so and stopping; Gravito's concession gate refused that stop and demanded
// documented capability exhaustion, which is 77% of its excess text-only turns.
// The measured ~2.4x is that interaction, not a general estimate.
//
// `runnable` pre-approves EXACTLY the judged command and its direct-binary
// spelling, IDENTICALLY in both arms. It is not a friendlier host: no other tool
// is granted, the permission mode is unchanged, and every other refusal the
// worker meets is the one it met before.
const VERIFICATION = arg("verification", "starved");
const ALLOWED_WHEN_RUNNABLE = [
  "Bash(npx tsc:*)",
  "Bash(./node_modules/.bin/tsc:*)",
  "Bash(node_modules/.bin/tsc:*)",
];

if (!TASK_ID || !CONFIGS.includes(CONFIG)) {
  console.error(`usage: run-arm.mjs --task T01 --config ${CONFIGS.join("|")} [--verification starved|runnable]`); process.exit(2);
}
if (!["starved", "runnable"].includes(VERIFICATION)) {
  console.error(`REFUSED: --verification must be starved|runnable, got '${VERIFICATION}'`); process.exit(2);
}
// The arm identity, derived from the config rather than passed separately, so a
// native config cannot be administered as gravito by a stray flag.
const ARM = CONFIG === "native" ? "native" : "gravito";

const sel = JSON.parse(fs.readFileSync(path.join(EXP6, "results/task-selection.json"), "utf8"));
const task = sel.selected.find((t) => t.task_id === TASK_ID);
if (!task) { console.error(`REFUSED: unknown task ${TASK_ID}`); process.exit(2); }
const baselineRaw = fs.readFileSync(path.join(EXP6, "results/baseline-tsc.txt"), "utf8");
const sh = (c, a, o = {}) => execFileSync(c, a, { encoding: "utf8", ...o });

const pre = []; const gate = (n, ok, d) => { pre.push({ name: n, ok, detail: d }); return ok; };
let lockOk = true;
try { fs.mkdirSync(path.dirname(LOCK), { recursive: true }); const fd = fs.openSync(LOCK, "wx"); fs.writeFileSync(fd, String(process.pid)); fs.closeSync(fd); }
catch { lockOk = false; }
gate("no_concurrent_measured_arm", lockOk, lockOk ? "acquired" : `another arm holds ${LOCK} — elapsed is a registered metric`);
// RELEASE ONLY WHAT WE ACQUIRED. The refusal path used to call releaseLock()
// unconditionally, so an arm refused FOR lock contention deleted the lock it had
// just been refused by. Sequentially that is merely self-healing; with real
// concurrency it is the sequential guarantee quietly disappearing -- B is
// refused, deletes A's lock, C starts alongside A, and elapsed time stops
// meaning anything. Found when a container restart left a stale lock and cost a
// measured cell.
const releaseLock = () => { if (!lockOk) return; try { fs.unlinkSync(LOCK); } catch {} };

// A lock whose owning process is gone is STALE, not held. Recorded as a
// distinct outcome rather than silently reclaimed, because "the previous run
// died" and "another arm is running" need different responses.
if (!lockOk) {
  let ownerAlive = false, owner = null;
  try { owner = Number(fs.readFileSync(LOCK, "utf8").trim()); process.kill(owner, 0); ownerAlive = true; } catch {}
  if (!ownerAlive) {
    try { fs.unlinkSync(LOCK); const fd = fs.openSync(LOCK, "wx"); fs.writeFileSync(fd, String(process.pid)); fs.closeSync(fd); lockOk = true; } catch {}
    pre[pre.length - 1] = { name: "no_concurrent_measured_arm", ok: lockOk,
      detail: lockOk ? `stale lock from dead pid ${owner} reclaimed — the owning process no longer exists`
                     : `lock held by pid ${owner} and could not be reclaimed` };
  }
}

let variant = null, administeredSha = null;
if (lockOk) {
  let restoreOk = false, detail = "";
  try {
    fs.rmSync(ARM_TREE, { recursive: true, force: true });
    const o = sh("bash", [RESTORE, ARM_TREE], { stdio: "pipe" });
    restoreOk = /VERIFIED/.test(o) && sh("git", ["-C", ARM_TREE, "rev-parse", "HEAD"]).trim() === SEED;
    detail = restoreOk ? `${SEED.slice(0, 12)} restored and verified` : o.trim().split("\n").slice(-2).join(" | ");
  } catch (e) { detail = `restore refused: ${String(e.stdout || e.message).split("\n").slice(-2).join(" | ")}`; }
  gate("exact_seed_restored", restoreOk, detail);

  if (restoreOk) {
    administer(ARM_TREE, ARM, CODE_SOURCE);
    const va = verifyAdministration(ARM_TREE, ARM);
    for (const c of va.checks) gate(`administration.${c.name}`, c.ok, c.detail);

    variant = applyVariant(ARM_TREE, CONFIG);
    const vv = verifyVariant(ARM_TREE, CONFIG);
    for (const c of vv.checks) gate(`variant.${c.name}`, c.ok, c.detail);

    gate("task_file_present", fs.existsSync(path.join(ARM_TREE, task.file)), task.file);
    try {
      const gi = ["-c", "user.email=harness@exp0007", "-c", "user.name=exp0007-harness"];
      sh("git", ["-C", ARM_TREE, ...gi, "add", "-A"]);
      sh("git", ["-C", ARM_TREE, ...gi, "commit", "-q", "--allow-empty", "-m", `exp0007: administered ${CONFIG}`]);
      administeredSha = sh("git", ["-C", ARM_TREE, "rev-parse", "HEAD"]).trim();
      gate("administered_state_committed", true, `${administeredSha.slice(0, 12)} — the arm's diff is measured against this`);
    } catch (e) { gate("administered_state_committed", false, String(e.stdout || e.message).slice(0, 200)); }
  }
  try { fs.symlinkSync(SHARED_MODULES, path.join(ARM_TREE, "node_modules"), "dir"); } catch {}
  gate("node_modules_available", fs.existsSync(path.join(ARM_TREE, "node_modules/typescript")), "shared, byte-identical across arms");
}

const failed = pre.filter((p) => !p.ok);
console.log(`PRE-FLIGHT ${TASK_ID}/${CONFIG} rep${REP}`);
for (const p of pre) console.log(`  ${p.ok ? "ok  " : "FAIL"} ${p.name}: ${p.detail}`);
if (failed.length) { console.error(`REFUSED — ${failed.length} pre-flight condition(s) failed.`); releaseLock(); process.exit(1); }
if (DRY) { console.log("dry-run: pre-flight only"); releaseLock(); process.exit(0); }

const sessionId = newSessionId();
// The verification condition is part of the run's IDENTITY, not a footnote in
// its record. A runnable arm landing on a starved arm's directory would silently
// overwrite one half of the contrast being measured. `starved` keeps the bare
// name so every arm run before this switch existed stays addressable unrenamed.
const suffix = (VERIFICATION === "runnable" ? ".runnable" : "") + (REP > 1 ? `.r${REP}` : "");
const runDir = path.join(RESULTS, "runs", `${TASK_ID}.${CONFIG}${suffix}`);
fs.mkdirSync(runDir, { recursive: true });
const streamPath = path.join(runDir, "stream.jsonl");
openRun(runDir, { task_id: TASK_ID, arm: CONFIG, launched_at: new Date().toISOString(),
  expected_session_id: sessionId, orchestrator_session_id: process.env.CLAUDE_CODE_SESSION_ID || null, timeout_ceiling_s: CEILING_S });
fs.writeFileSync(path.join(runDir, "variant.json"), JSON.stringify({
  ...variant, administered_sha: administeredSha, arm: ARM,
  verification: VERIFICATION,
  // Recorded verbatim so the grant is auditable from the run record alone, and
  // so a later reader can confirm both arms received the SAME grant.
  allowed_tools: VERIFICATION === "runnable" ? ALLOWED_WHEN_RUNNABLE : [],
  permission_mode: "acceptEdits",
}, null, 2));

// IDENTICAL to EXP-0006's prompt, character for character. A different prompt
// would be a second treatment riding alongside the one being measured.
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

const started = Date.now();
const out = fs.openSync(streamPath, "w");
// The grant is built from ONE constant used by both arms. Deriving it per-arm,
// or letting the caller pass it, is how a hidden host-privilege difference gets
// in — which is precisely what preflight condition 5 exists to refuse.
const claudeArgs = ["-p", "--output-format", "stream-json", "--verbose", "--model", MODEL,
  "--session-id", sessionId, "--permission-mode", "acceptEdits"];
if (VERIFICATION === "runnable") claudeArgs.push("--allowedTools", ...ALLOWED_WHEN_RUNNABLE);
const child = spawn("claude", claudeArgs,
  { cwd: ARM_TREE, env: { ...scrubbedEnv(process.env), CI: "1" }, stdio: ["pipe", out, "pipe"], detached: true });
let stderr = ""; child.stderr.on("data", (b) => { if (stderr.length < 100_000) stderr += b.toString(); });
child.stdin.write(prompt); child.stdin.end();
const timer = setTimeout(() => { try { process.kill(-child.pid, "SIGKILL"); } catch {} try { process.kill(child.pid, "SIGKILL"); } catch {} }, CEILING_S * 1000);

child.on("exit", (code, signal) => {
  clearTimeout(timer); fs.closeSync(out);
  const elapsedS = (Date.now() - started) / 1000;
  fs.writeFileSync(path.join(runDir, "stderr.txt"), stderr);

  let acceptance = null, productPaths = [], govPaths = [];
  try {                                            // WORK PRODUCT FIRST
    const base = administeredSha || "HEAD";
    const excl = [":(exclude)node_modules", ":(exclude)node_modules/**"];
    const changed = sh("git", ["-C", ARM_TREE, "status", "--porcelain", "--", ".", ...excl]).split("\n").filter(Boolean)
      .map((l) => ({ status: l.slice(0, 2).trim(), path: l.slice(3).replace(/^"|"$/g, "") }))
      .filter((c) => !c.path.startsWith("node_modules"));
    const tracked = sh("git", ["-C", ARM_TREE, "diff", base, "--", ".", ...excl], { maxBuffer: 128 * 1024 * 1024 });
    const untrackedBody = changed.filter((c) => c.status === "??").map((p) => {
      try { return `diff --git a/${p.path} b/${p.path}\n--- /dev/null\n+++ b/${p.path}\n` +
        fs.readFileSync(path.join(ARM_TREE, p.path), "utf8").split("\n").map((l) => "+" + l).join("\n"); } catch { return ""; }
    }).join("\n");
    const fullDiff = tracked + "\n" + untrackedBody;
    fs.writeFileSync(path.join(runDir, "full.diff"), fullDiff);
    const split = splitPaths(changed.map((c) => c.path));
    productPaths = split.product_paths; govPaths = split.governance_paths;
    fs.writeFileSync(path.join(runDir, "changed-paths.json"), JSON.stringify({ base_commit: base, product_paths: productPaths, governance_paths: govPaths }, null, 2));

    let vOut = "", vCode = null;
    try { vOut = sh("bash", ["-lc", VERIFY_CMD], { cwd: ARM_TREE, timeout: 900_000, maxBuffer: 128 * 1024 * 1024, stdio: "pipe" }); vCode = 0; }
    catch (e) { vOut = String(e.stdout || "") + String(e.stderr || ""); vCode = e.status ?? null; }
    fs.writeFileSync(path.join(runDir, "verification.txt"), `$ ${VERIFY_CMD}\n(exit ${vCode})\n\n${vOut}`);
    acceptance = adjudicate({ baselineRaw, afterRaw: vOut, taskFile: task.file, diff: fullDiff });
    acceptance.verification_exit_code = vCode;
    fs.writeFileSync(path.join(runDir, "acceptance.json"), JSON.stringify(acceptance, null, 2));
  } catch (e) { fs.writeFileSync(path.join(runDir, "capture-error.txt"), String(e.stack || e.message)); }

  try {
    const ev = fs.readFileSync(streamPath, "utf8").split("\n").filter(Boolean).map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
    const res = ev.find((e) => e.type === "result") || {}; const u = res.usage || {};
    // Hook-emitted volume, measured directly — the quantity factor B targets.
    const MARK = /routing-gate:|PreToolUse:\w+ hook|PostToolUse:\w+ hook|hook error/;
    let toolResultChars = 0, hookChars = 0, hookResults = 0;
    for (const e of ev) for (const c of (e?.message?.content || [])) {
      if (c.type !== "tool_result") continue;
      const s = typeof c.content === "string" ? c.content : JSON.stringify(c.content || "");
      toolResultChars += s.length; if (MARK.test(s)) { hookChars += s.length; hookResults++; }
    }
    const toolNames = ev.flatMap((e) => (e?.message?.content || []).filter((c) => c?.type === "tool_use").map((c) => c.name));
    fs.writeFileSync(path.join(runDir, "economics.json"), JSON.stringify({
      uncached_input_tokens: u.input_tokens ?? null, cache_read_input_tokens: u.cache_read_input_tokens ?? null,
      cache_creation_input_tokens: u.cache_creation_input_tokens ?? null, output_tokens: u.output_tokens ?? null,
      num_turns: res.num_turns ?? null, total_cost_usd: res.total_cost_usd ?? null, elapsed_s: elapsedS,
      tool_calls: toolNames.length, subagent_invocations: toolNames.filter((n) => n === "Task" || n === "Agent").length,
      product_files_changed: productPaths.length, governance_files_changed: govPaths.length,
      tool_result_chars: toolResultChars, hook_emitted_chars: hookChars, hook_emitting_results: hookResults,
      config: CONFIG,
    }, null, 2));
  } catch (e) { fs.appendFileSync(path.join(runDir, "capture-error.txt"), "\n" + String(e.stack || e.message)); }

  const verdict = classify({ streamPath, exitCode: code, ceilingS: CEILING_S, elapsedS, launcherAlive: true });
  const isolation = verifyIsolation({ streamPath, expectedSessionId: sessionId, orchestratorSessionId: process.env.CLAUDE_CODE_SESSION_ID || null });
  const closed = closeRun(runDir, { ...verdict, elapsed_s: elapsedS, exit_code: code, signal }, isolation);
  releaseLock();
  console.log(`UNIT ${TASK_ID}/${CONFIG} rep${REP}: terminal=${verdict.terminal_reason} admissible=${closed.admissible === true} accepted=${acceptance ? acceptance.accepted : "uncaptured"} elapsed=${elapsedS.toFixed(1)}s`);
  process.exit(0);
});
