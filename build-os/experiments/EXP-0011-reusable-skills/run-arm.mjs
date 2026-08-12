#!/usr/bin/env node
// EXP-0011 — one sequence-position arm, three treatments:
//   native     — no substrate (fresh session), the economic anchor
//   leanrules  — proof-1 design: rules as context via the memory file (FIXED selector)
//   leanskills — rules + demonstrated procedure compiled into a native SKILL.md
//                capability; NO memory file, so context cost is only the
//                skill description until the worker invokes it
// Transport/administration pin UNCHANGED (a530659). Same shared arm tree and
// lock as EXP-0007/0009/0010. Distillation is mechanical and config-scoped:
// each treatment's store accrues from its own arms only.
//
// Usage: run-arm.mjs --seq G|M --pos 1..5 --rep N --config native|leanrules|leanskills [--dry-run]

import { execFileSync, spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { openRun, closeRun, classify, verifyIsolation, scrubbedEnv, newSessionId } from "../harness/run-record.mjs";
import { splitPaths } from "../EXP-0005-system-efficiency/blinding/governance-strip.mjs";
import { administer, verifyAdministration } from "../EXP-0006-operational-uic/harness/substrate.mjs";
import { adjudicate } from "../EXP-0006-operational-uic/harness/acceptance.mjs";
import { distillRule, appendToStore, verifyStoreProvenance, selectRules, compileSkill } from "./skill-lib.mjs";

const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const HERE = path.dirname(new URL(import.meta.url).pathname);
const EXP6 = path.join(HERE, "../EXP-0006-operational-uic");
const RESULTS = path.join(HERE, "results");
const ORCH = path.join(HERE, "../../..");

const SEQ = arg("seq"), POS = Number(arg("pos", "0")), REP = Number(arg("rep", "1")), CONFIG = arg("config");
const DRY = process.argv.includes("--dry-run");
if (!["G", "M"].includes(SEQ) || !(POS >= 1 && POS <= 5) || !["native", "leanrules", "leanskills"].includes(CONFIG)) {
  console.error("usage: run-arm.mjs --seq G|M --pos 1..5 --rep N --config native|leanrules|leanskills"); process.exit(2);
}

const CEILING_S = 1200;
const SEED = "2543c873141fa64653a7993d326465d5e0dd1006";
const MODEL = process.env.EXP0011_MODEL || "claude-opus-5";
const ARM_TREE = "/home/user/exp0007-arm";
const LOCK = "/home/user/.exp0007/arm.lock";
const RESTORE = path.join(HERE, "../EXP-0005-system-efficiency/harness/restore-seed.sh");
const VERIFY_CMD = "npx tsc --noEmit -p tsconfig.json";
const ALLOWED = ["Bash(npx tsc:*)", "Bash(./node_modules/.bin/tsc:*)", "Bash(node_modules/.bin/tsc:*)"];
const BASH_TIMEOUTS = { BASH_DEFAULT_TIMEOUT_MS: "600000", BASH_MAX_TIMEOUT_MS: "600000" };
const TRANSPORT_PIN = "a530659";

const task = JSON.parse(fs.readFileSync(path.join(HERE, "sequences.json"), "utf8")).sequences[SEQ][POS - 1];
const baselineRaw = fs.readFileSync(path.join(EXP6, "results/baseline-tsc.txt"), "utf8");
const sh = (c, a, o = {}) => execFileSync(c, a, { encoding: "utf8", ...o });

// Config-scoped stores: each treatment learns from ITS OWN arms only.
const STORE = path.join(HERE, "memory-stores", `${SEQ}.rep${REP}.${CONFIG}`, "repair-rules.md");
const SKILL_REL = `.claude/skills/repair-${task.subsystem}/SKILL.md`;

const pre = []; const gate = (n, ok, d) => { pre.push({ name: n, ok, detail: d }); return ok; };
let lockOk = true;
try { fs.mkdirSync(path.dirname(LOCK), { recursive: true }); const fd = fs.openSync(LOCK, "wx"); fs.writeFileSync(fd, String(process.pid)); fs.closeSync(fd); }
catch { lockOk = false; }
gate("no_concurrent_measured_arm", lockOk, lockOk ? "acquired" : `another arm holds ${LOCK}`);
const releaseLock = () => { if (lockOk) { try { fs.rmSync(LOCK, { force: true }); } catch {} } };

let administeredSha = null, SOURCE_IDENTITY = null;
let INSTALL = { kind: "none", matched: 0, bytes: 0, skipped_oversize: 0, rules: 0 };
if (lockOk) {
  let restoreOk = false, detail = "";
  try {
    fs.rmSync(ARM_TREE, { recursive: true, force: true });
    const o = sh("bash", [RESTORE, ARM_TREE], { stdio: "pipe" });
    restoreOk = /VERIFIED/.test(o) && sh("git", ["-C", ARM_TREE, "rev-parse", "HEAD"]).trim() === SEED;
    detail = restoreOk ? `${SEED.slice(0, 12)} restored and verified` : o.trim().split("\n").slice(-2).join(" | ");
  } catch (e) { detail = `restore refused: ${String(e.stdout || e.message).split("\n").slice(-2).join(" | ")}`; }
  gate("exact_seed_restored_before_every_position", restoreOk, detail);

  if (restoreOk) {
    if (CONFIG === "native") {
      administer(ARM_TREE, "native");
      const va = verifyAdministration(ARM_TREE, "native");
      for (const c of va.checks) gate(`administration.${c.name}`, c.ok, c.detail);
    } else {
      const resolved = sh("git", ["-C", ORCH, "rev-parse", `${TRANSPORT_PIN}^{commit}`]).trim();
      const dir = `/home/user/.exp-pinned/leanmem-${resolved.slice(0, 12)}`;
      const refFile = path.join(dir, ".pinned-ref");
      if (!fs.existsSync(refFile) || fs.readFileSync(refFile, "utf8").trim() !== resolved) {
        fs.rmSync(dir, { recursive: true, force: true });
        fs.mkdirSync(dir, { recursive: true });
        execFileSync("bash", ["-c", `git -C ${JSON.stringify(ORCH)} archive ${resolved} -- build-os .claude CLAUDE.md | tar -x -C ${JSON.stringify(dir)}`]);
        fs.writeFileSync(refFile, resolved + "\n");
      }
      administer(ARM_TREE, "gravito", dir);
      const va = verifyAdministration(ARM_TREE, "gravito");
      for (const c of va.checks) gate(`administration.${c.name}`, c.ok, c.detail);
      SOURCE_IDENTITY = { treatment: CONFIG, requested_ref: TRANSPORT_PIN, resolved_commit: resolved };

      const ssSrc = fs.readFileSync(path.join(ARM_TREE, ".claude/hooks/session-start-build-os.sh"), "utf8");
      gate("transport_markers", /Organizational memory/.test(ssSrc), "pinned transport administered unchanged");

      const prov = verifyStoreProvenance(STORE, SEQ, REP, POS);
      gate("store_provenance", prov.ok, prov.detail);
      if (prov.ok) {
        if (CONFIG === "leanrules") {
          const sel = selectRules(STORE, task.codes);
          INSTALL = { kind: "rules-context", ...sel, rules: sel.matched };
          if (sel.text) fs.writeFileSync(path.join(ARM_TREE, "build-os/memory/task-log.md"), sel.text);
          gate("delivery_prepared", sel.bytes <= 1536,
            sel.text ? `${sel.matched} matched, ${sel.bytes}B as context (skips: ${sel.skipped_oversize})` : "no matching rules — position 1 or fresh rep");
        } else {
          const skill = compileSkill(STORE, task);
          INSTALL = { kind: "skill", matched: skill.rules, bytes: skill.bytes, skipped_oversize: 0, rules: skill.rules };
          if (skill.text) {
            const sp = path.join(ARM_TREE, SKILL_REL);
            fs.mkdirSync(path.dirname(sp), { recursive: true });
            fs.writeFileSync(sp, skill.text);
            const fmOk = /^---\nname: [\w-]+\ndescription: .+\n---/m.test(skill.text);
            gate("skill_compiled_valid", fmOk && skill.bytes <= 8192, `${skill.rules} rule(s) into ${SKILL_REL}, ${skill.bytes}B, frontmatter ${fmOk ? "valid" : "INVALID"}`);
          } else {
            gate("skill_compiled_valid", true, "no prior rules — position 1 or fresh rep; no skill installed");
          }
          gate("no_memory_file_for_skills_arm", !fs.existsSync(path.join(ARM_TREE, "build-os/memory/task-log.md")) || !fs.readFileSync(path.join(ARM_TREE, "build-os/memory/task-log.md"), "utf8").includes("## RULE"),
            "skills arm carries the capability surface only — no rules ride session-start context");
        }
      }
    }
    gate("task_file_present", fs.existsSync(path.join(ARM_TREE, task.file)), task.file);
    try {
      const gi = ["-c", "user.email=harness@exp0011", "-c", "user.name=exp0011-harness"];
      sh("git", ["-C", ARM_TREE, ...gi, "add", "-A"]);
      sh("git", ["-C", ARM_TREE, ...gi, "commit", "-q", "--allow-empty", "-m", `exp0011: administered ${CONFIG} ${SEQ}${POS} rep${REP}`]);
      administeredSha = sh("git", ["-C", ARM_TREE, "rev-parse", "HEAD"]).trim();
      gate("administered_state_committed", true, administeredSha.slice(0, 12));
    } catch (e) { gate("administered_state_committed", false, String(e.stdout || e.message).slice(0, 200)); }
  }
  try { fs.symlinkSync("/home/user/empathiq-website/node_modules", path.join(ARM_TREE, "node_modules"), "dir"); } catch {}
  gate("node_modules_available", fs.existsSync(path.join(ARM_TREE, "node_modules/typescript")), "shared, byte-identical across arms");
}

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
const promptSha = crypto.createHash("sha256").update(prompt).digest("hex").slice(0, 16);
gate("prompt_identity", true, `sha256:${promptSha} — built from sequences.json only; identical across the three configs by construction`);

const failed = pre.filter((p) => !p.ok);
console.log(`PRE-FLIGHT ${SEQ}${POS}/${CONFIG} rep${REP}`);
for (const p of pre) console.log(`  ${p.ok ? "ok  " : "FAIL"} ${p.name}: ${p.detail}`);
if (failed.length) { console.error(`REFUSED — ${failed.length} pre-flight condition(s) failed.`); releaseLock(); process.exit(1); }
if (DRY) { console.log("dry-run: pre-flight only"); releaseLock(); process.exit(0); }

const sessionId = newSessionId();
const runDir = path.join(RESULTS, "runs", `${SEQ}${POS}.${CONFIG}.r${REP}`);
fs.mkdirSync(runDir, { recursive: true });
const streamPath = path.join(runDir, "stream.jsonl");
openRun(runDir, { task_id: `${SEQ}${POS}`, arm: CONFIG, launched_at: new Date().toISOString(),
  expected_session_id: sessionId, orchestrator_session_id: process.env.CLAUDE_CODE_SESSION_ID || null, timeout_ceiling_s: CEILING_S });
fs.writeFileSync(path.join(runDir, "variant.json"), JSON.stringify({
  config: CONFIG, sequence: SEQ, position: POS, rep: REP, subsystem: task.subsystem,
  memory_unit: CONFIG === "leanskills" ? "compiled-skill" : CONFIG === "leanrules" ? "repair-rules" : null,
  source_identity: SOURCE_IDENTITY, administered_sha: administeredSha,
  prompt_sha256_16: promptSha, memory_store: CONFIG === "native" ? null : path.relative(HERE, STORE),
  install: INSTALL, skill_path: CONFIG === "leanskills" ? SKILL_REL : null,
  verification: "runnable", allowed_tools: ALLOWED, permission_mode: "acceptEdits", bash_timeouts: BASH_TIMEOUTS,
}, null, 2));
fs.writeFileSync(path.join(runDir, "prompt.txt"), prompt);

const started = Date.now();
const out = fs.openSync(streamPath, "w");
const child = spawn("claude", ["-p", "--output-format", "stream-json", "--verbose", "--model", MODEL,
  "--session-id", sessionId, "--permission-mode", "acceptEdits", "--allowedTools", ...ALLOWED],
  { cwd: ARM_TREE, env: { ...scrubbedEnv(process.env), CI: "1", ...BASH_TIMEOUTS }, stdio: ["pipe", out, "pipe"], detached: true });
let stderr = ""; child.stderr.on("data", (b) => { if (stderr.length < 100_000) stderr += b.toString(); });
child.stdin.write(prompt); child.stdin.end();
const timer = setTimeout(() => { try { process.kill(-child.pid, "SIGKILL"); } catch {} try { process.kill(child.pid, "SIGKILL"); } catch {} }, CEILING_S * 1000);

child.on("exit", (code, signal) => {
  clearTimeout(timer); fs.closeSync(out);
  const elapsedS = (Date.now() - started) / 1000;
  fs.writeFileSync(path.join(runDir, "stderr.txt"), stderr);

  let acceptance = null, productPaths = [], govPaths = [];
  try {
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
    const toolNames = ev.flatMap((e) => (e?.message?.content || []).filter((c) => c?.type === "tool_use").map((c) => c.name));
    const memReads = ev.flatMap((e) => (e?.message?.content || [])
      .filter((c) => c?.type === "tool_use" && c.name === "Read" && /build-os\/memory\/task-log\.md/.test(String(c.input?.file_path || "")))).length;
    const memWrites = ev.flatMap((e) => (e?.message?.content || [])
      .filter((c) => c?.type === "tool_use" && /^(Edit|Write|NotebookEdit)$/.test(c.name) && /(build-os\/memory\/|\.claude\/skills\/)/.test(String(c.input?.file_path || "")))).length;
    const skillReads = ev.flatMap((e) => (e?.message?.content || [])
      .filter((c) => c?.type === "tool_use" && c.name === "Read" && /\.claude\/skills\//.test(String(c.input?.file_path || "")))).length;
    const skillInvocations = ev.flatMap((e) => (e?.message?.content || [])
      .filter((c) => c?.type === "tool_use" && c.name === "Skill")).length;
    fs.writeFileSync(path.join(runDir, "economics.json"), JSON.stringify({
      uncached_input_tokens: u.input_tokens ?? null, cache_read_input_tokens: u.cache_read_input_tokens ?? null,
      cache_creation_input_tokens: u.cache_creation_input_tokens ?? null, output_tokens: u.output_tokens ?? null,
      num_turns: res.num_turns ?? null, total_cost_usd: res.total_cost_usd ?? null, elapsed_s: elapsedS,
      tool_calls: toolNames.length, subagent_invocations: toolNames.filter((n) => n === "Task" || n === "Agent").length,
      product_files_changed: productPaths.length, governance_files_changed: govPaths.length,
      memory_reads: memReads, memory_writes_by_worker: memWrites,
      skill_reads: skillReads, skill_invocations: skillInvocations,
      install_kind: INSTALL.kind, install_bytes: INSTALL.bytes, install_rules: INSTALL.rules,
      config: CONFIG, sequence: SEQ, position: POS, rep: REP,
    }, null, 2));
  } catch (e) { fs.appendFileSync(path.join(runDir, "capture-error.txt"), "\n" + String(e.stack || e.message)); }

  const verdict = classify({ streamPath, exitCode: code, ceilingS: CEILING_S, elapsedS, launcherAlive: true });
  const isolation = verifyIsolation({ streamPath, expectedSessionId: sessionId, orchestratorSessionId: process.env.CLAUDE_CODE_SESSION_ID || null });
  const closed = closeRun(runDir, { ...verdict, elapsed_s: elapsedS, exit_code: code, signal }, isolation);

  let distilled = false;
  if (CONFIG !== "native" && closed.admissible === true) {
    try { appendToStore(STORE, distillRule(runDir, task, REP)); distilled = true; } catch {}
  }
  releaseLock();
  console.log(`UNIT ${SEQ}${POS}/${CONFIG} rep${REP}: terminal=${verdict.terminal_reason} admissible=${closed.admissible === true} accepted=${acceptance ? acceptance.accepted : "uncaptured"} install=${INSTALL.kind}:${INSTALL.bytes}B distilled=${distilled} elapsed=${elapsedS.toFixed(1)}s`);
  process.exit(0);
});
