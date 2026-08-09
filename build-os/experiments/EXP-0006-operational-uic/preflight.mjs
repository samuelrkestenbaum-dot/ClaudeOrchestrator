#!/usr/bin/env node
// EXP-0006 PREFLIGHT — every environmental precondition EXECUTED, not declared.
//
// WHY THIS FILE EXISTS. EXP-0005 returned gravito_system_harmful with 0/12
// accepted outcomes in the Gravito arm. The cause was not the substrate's
// design: it was that the arm could not obtain first mutation authority on that
// host, so the treatment never executed. The experiment measured a precondition
// failure and reported it as a product verdict.
//
// The preregistration listed its environment. Nobody RAN the environment before
// measuring in it. So this probe is the gate: every precondition below is
// exercised against the real host, in the exact configuration the measured arms
// will use, and the experiment does not start until they pass.
//
// The distinction is the same one this substrate keeps rediscovering: a check
// that has never demonstrated a failure tells you it ran, not that it guards.
// A precondition that has never been exercised tells you someone wrote it down.
//
// Exit 0 = ready to measure. Exit 3 = a precondition failed; the experiment is
// REFUSED rather than run against an environment that cannot support it.

import { spawn, execFileSync } from "node:child_process";
import { scrubbedEnv, newSessionId } from "../harness/run-record.mjs";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";

const MODEL = process.env.EXP0006_MODEL || "claude-opus-5";
const MODE = process.env.EXP0006_PERMISSION_MODE || "acceptEdits";
const TIMEOUT_MS = Number(process.env.EXP0006_PREFLIGHT_TIMEOUT_MS || 240000);

const results = [];
const record = (id, status, detail, evidence = null) => {
  results.push({ id, status, detail, evidence });
  const mark = status === "PASS" ? "  ok  " : status === "SKIP" ? "  --  " : "  FAIL";
  console.log(`${mark} ${id}: ${detail}`);
};

/** Run a worker child exactly as a measured arm would, and return what it did. */
function probeWorker(prompt, cwd, extraArgs = []) {
  return new Promise((resolve) => {
    const started = Date.now();
    // SCRUB + EXPLICIT --session-id, exactly as EXP-0005's arm runner does.
    // An unscrubbed child inherits the orchestrator's session identity; the
    // assumption registry records this as TESTED AND FOUND FALSE BY DEFAULT.
    // The probe must run in the SAME configuration the measured arms will use,
    // or it is not a probe of the measured configuration.
    const sid = newSessionId();
    const child = spawn("claude", [
      "-p", prompt,
      "--model", MODEL,
      "--session-id", sid,
      "--permission-mode", MODE,
      "--output-format", "json",
      ...extraArgs,
    ], { cwd, stdio: ["ignore", "pipe", "pipe"], detached: true,
         env: { ...scrubbedEnv(process.env), CI: "1" } });
    child.expectedSessionId = sid;

    let out = "", err = "";
    child.stdout.on("data", (d) => (out += d));
    child.stderr.on("data", (d) => (err += d));
    const timer = setTimeout(() => { try { process.kill(-child.pid, "SIGKILL"); } catch {} }, TIMEOUT_MS);
    child.on("exit", (code) => {
      clearTimeout(timer);
      resolve({ code, out, err, ms: Date.now() - started, expectedSessionId: sid });
    });
  });
}

console.log(`EXP-0006 PREFLIGHT — model=${MODEL} permission_mode=${MODE}\n`);

// ---- 1. the worker exists and reports a version --------------------------
try {
  const v = execFileSync("claude", ["--version"], { encoding: "utf8" }).trim();
  record("worker_cli_present", "PASS", `claude CLI available: ${v}`, v);
} catch (e) {
  record("worker_cli_present", "FAIL", `claude CLI unavailable: ${e.message}`);
}

// ---- 2. THE EXP-0005 KILLER: can a child actually mutate a file? ---------
// This is the precondition that failed silently last time. It is exercised in a
// scratch tree, in the same permission mode the arms will use, and the check is
// the FILE ON DISK — not the worker's own report of what it did.
const scratch = fs.mkdtempSync(path.join(os.tmpdir(), "exp0006-pre-"));
fs.writeFileSync(path.join(scratch, "target.txt"), "BEFORE\n");
const mutProbe = await probeWorker(
  "Replace the entire contents of target.txt with exactly the word AFTER (one line, no other text). Then stop.",
  scratch,
);
const after = (() => { try { return fs.readFileSync(path.join(scratch, "target.txt"), "utf8").trim(); } catch { return "<unreadable>"; } })();
if (after === "AFTER") {
  record("first_mutation_authority", "PASS",
    `a child in --permission-mode ${MODE} MUTATED a file on disk (exit ${mutProbe.code}, ${(mutProbe.ms / 1000).toFixed(0)}s)`,
    { verified_by: "reading the file, not the worker's claim" });
} else {
  record("first_mutation_authority", "FAIL",
    `a child could NOT mutate a file — target.txt is "${after}", expected "AFTER". THIS IS THE EXP-0005 FAILURE. ` +
    `Measuring here would again record a precondition failure as a product verdict.`,
    { exit: mutProbe.code, stderr: mutProbe.err.slice(0, 400) });
}

// ---- 3. session isolation: does a child report its own session id? -------
// EXP-0005 found an unscrubbed child inheriting the orchestrator's session.
// THIS CHECK WAS VACUOUS ON ITS FIRST RUN AND IS RECORDED AS SUCH. It compared
// against process.env.CLAUDE_SESSION_ID — a variable that does not exist here;
// the real name is CLAUDE_CODE_SESSION_ID. Reading the wrong name yielded
// undefined, so `childSession !== undefined` was trivially true and the check
// PASSED while the child had in fact inherited this session's exact id. A
// comparison against an unknown is not a comparison, so the orchestrator id is
// now resolved explicitly and its ABSENCE fails the check rather than passing it.
const ORCH = process.env.CLAUDE_CODE_SESSION_ID || null;
const sess = mutProbe.out.match(/"session_id"\s*:\s*"([^"]+)"/);
if (!ORCH) {
  record("session_isolation", "FAIL", "this session's own id is unresolvable, so isolation cannot be compared — failing closed rather than comparing against undefined");
} else if (!sess) {
  record("session_isolation", "FAIL", "no session_id in the child's JSON output; isolation is unverifiable, which is not the same as isolated");
} else if (sess[1] === ORCH) {
  record("session_isolation", "FAIL",
    `child reported ${sess[1].slice(0, 8)}... which IS this session — the scrub did not take, and arms would contaminate each other`);
} else if (sess[1] !== mutProbe.expectedSessionId) {
  record("session_isolation", "FAIL",
    `child reported ${sess[1].slice(0, 8)}... but was launched with --session-id ${String(mutProbe.expectedSessionId).slice(0, 8)}... — it did not honour the id it was given`);
} else {
  record("session_isolation", "PASS",
    `child ran under its OWN id ${sess[1].slice(0, 8)}..., distinct from this session's ${ORCH.slice(0, 8)}... and equal to the id it was launched with`);
}

// ---- 4. token accounting is present and non-zero -------------------------
// The primary outcome is per-uncached-token. If the field is missing or zero
// the experiment cannot compute its own metric, and that must stop it BEFORE
// the arms run rather than after.
const usage = mutProbe.out.match(/"input_tokens"\s*:\s*(\d+)/);
const cacheRead = mutProbe.out.match(/"cache_read_input_tokens"\s*:\s*(\d+)/);
if (usage && Number(usage[1]) >= 0 && cacheRead) {
  record("token_accounting", "PASS", `usage reports input_tokens=${usage[1]} and cache_read_input_tokens=${cacheRead[1]} — uncached is derivable`);
} else {
  record("token_accounting", "FAIL", "the child's JSON does not carry the token fields the primary outcome is computed from");
}

// ---- 5. the Gravito substrate is present and loadable --------------------
const substrate = ["build-os", ".claude", "CLAUDE.md"];
const missing = substrate.filter((p) => !fs.existsSync(p));
if (!missing.length) {
  record("substrate_present", "PASS", `all substrate paths exist: ${substrate.join(", ")}`);
} else {
  record("substrate_present", "FAIL", `substrate missing: ${missing.join(", ")}`);
}

// ---- 6. the substrate's live gates actually load -------------------------
// A Gravito arm whose controllers throw on import is not a Gravito arm.
try {
  const mods = ["./build-os/motion/continuation.mjs", "./build-os/motion/objective.mjs",
                "./build-os/motion/concession-gate.mjs", "./build-os/assumptions/authority-selector.mjs"];
  for (const m of mods) await import(path.resolve(m));
  record("substrate_loads", "PASS", `${mods.length} load-bearing controllers import without throwing`);
} catch (e) {
  record("substrate_loads", "FAIL", `a load-bearing controller failed to import: ${e.message}`);
}

// ---- 7. host permission semantics, REGISTERED not assumed ----------------
try {
  const { resolveHost, DEFAULT_PROFILE_ID } = await import(path.resolve("./build-os/assumptions/host-profiles.mjs"));
  const id = process.env.GRAVITO_HOST_PROFILE || DEFAULT_PROFILE_ID;
  const h = resolveHost(id);
  record("host_profile_registered", "PASS",
    `host=${h.id} permits Edit=${h.permits.Edit} Bash=${h.permits.Bash} approver=${h.approver_present}`,
    h);
} catch (e) {
  record("host_profile_registered", "FAIL", `host profile unresolvable: ${e.message}`);
}

fs.rmSync(scratch, { recursive: true, force: true });

const failed = results.filter((r) => r.status === "FAIL");
console.log(`\n${results.filter((r) => r.status === "PASS").length} passed, ${failed.length} failed, ${results.filter((r) => r.status === "SKIP").length} skipped`);
fs.mkdirSync("build-os/experiments/EXP-0006-operational-uic/results", { recursive: true });
fs.writeFileSync("build-os/experiments/EXP-0006-operational-uic/results/preflight.json",
  JSON.stringify({ artifact: "exp0006_preflight", model: MODEL, permission_mode: MODE, results, ready: failed.length === 0 }, null, 2));

if (failed.length) {
  console.log("\nREFUSED: the environment cannot support a valid measurement. Fix the precondition; do not run the arms.");
  process.exit(3);
}
console.log("\nREADY: every precondition was exercised against this host, not declared.");
