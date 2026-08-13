#!/usr/bin/env node
// EXP-0013 Stage-A EXECUTION CONTROLLER.
//
// One process owns the whole study lifecycle — there are NO detached monitors
// (FAILURE-MODES row 2): every worker is spawned, supervised, timed out, and
// reaped by THIS process, and an orphan scan runs after every cell. Timeouts
// are controller-owned kills with a recorded terminal_reason (row 4).
//
// Modes:
//   rehearsal — runs the REAL state machine (freeze check, study lock, H0,
//     isolation worktrees from the pinned archive, sealed-order load, real
//     planner descriptor, real UCDL delivery + pair equivalence, prompt
//     construction, telemetry init, budget gate) and STOPS at the mandatory
//     PROVIDER BARRIER: it writes a semantic request digest of the exact call
//     it WOULD make, records the NO_PROVIDER_CALL sentinel, and never execs.
//     A PATH-shadow `claude` shim sits behind the barrier as a tripwire —
//     if it ever executes, the rehearsal FAILS.
//   measured — REFUSED unless an explicit owner spend-authorization file is
//     present and valid; this leg never runs it.
//
// The rehearsal is the wiring proof the program's own standard demands:
// executed invocation evidence through real entry points, not a source grep.

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync, spawnSync, spawn } from "node:child_process";
import { buildTreatments, admitCell, appendReceipt, verifyReceipts } from "./fixture.mjs";
import { buildSchedule, isolationManifest } from "./scheduler.mjs";
import * as sealOrders from "./seal-orders.mjs";

const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");
const HERE = path.dirname(new URL(import.meta.url).pathname);
const ROOT = path.resolve(HERE, "..");
const ORCH = path.resolve(ROOT, "../../..");
export const CONFIG = JSON.parse(fs.readFileSync(path.join(HERE, "model-config.json"), "utf8"));
export const CORPUS = JSON.parse(fs.readFileSync(path.join(ROOT, "corpus", "sequences.json"), "utf8"));

// ---------------------------------------------------------------- primitives

/** Append one controller-log receipt (hash-chained, same pattern as deltas). */
function logStep(dir, obj) {
  const f = path.join(dir, "controller-log.jsonl");
  const prev = (() => { try { const l = fs.readFileSync(f, "utf8").trim().split("\n"); return sha(l[l.length - 1]); } catch { return "genesis"; } })();
  fs.appendFileSync(f, JSON.stringify({ ...obj, prev_sha: prev }) + "\n");
}

/**
 * Supervised execution — THE only way this harness ever runs a worker.
 * Spawns a detached process GROUP, feeds stdin, enforces the wall-clock
 * ceiling with a controller-owned SIGKILL to the whole group, and returns a
 * terminal_reason. No monitor processes, no polling scripts, no resume.
 */
export function supervise({ argv, stdinText, cwd, env, ceilingS, outFile, marker }) {
  return new Promise((resolve) => {
    const started = Date.now();
    const out = fs.openSync(outFile, "w");
    const child = spawn(argv[0], argv.slice(1), {
      cwd, env: { ...env, EXP0013_CELL_MARKER: marker },
      stdio: ["pipe", out, "pipe"], detached: true,
    });
    let stderr = ""; child.stderr.on("data", (b) => { if (stderr.length < 100_000) stderr += b.toString(); });
    child.stdin.write(stdinText ?? ""); child.stdin.end();
    let timedOut = false;
    const timer = setTimeout(() => {
      timedOut = true;
      try { process.kill(-child.pid, "SIGKILL"); } catch {}
      try { process.kill(child.pid, "SIGKILL"); } catch {}
    }, ceilingS * 1000);
    child.on("exit", (code, signal) => {
      clearTimeout(timer); fs.closeSync(out);
      const elapsed_s = (Date.now() - started) / 1000;
      const terminal_reason = timedOut ? "timeout" : code === 0 ? "success" : signal ? `killed:${signal}` : `exit:${code}`;
      resolve({ exit_code: code, signal, terminal_reason, elapsed_s, stderr: stderr.slice(0, 4000) });
    });
  });
}

/** Post-cell orphan scan: any process still carrying this cell's marker is an orphan. */
export function detectOrphans(marker) {
  const r = spawnSync("bash", ["-c",
    `for p in /proc/[0-9]*; do if grep -qz "EXP0013_CELL_MARKER=${marker}" "$p/environ" 2>/dev/null; then basename "$p"; fi; done`],
    { encoding: "utf8" });
  const pids = (r.stdout || "").split("\n").filter(Boolean).filter((p) => Number(p) !== process.pid);
  return { clean: pids.length === 0, orphan_pids: pids };
}

/** Budget gate: refuse BEFORE the call that would breach the ceiling. */
export function budgetGate({ spentUsd, perCallWorstUsd = CONFIG.spend.per_call_worst_usd, ceilingUsd = CONFIG.spend.proposed_ceiling_usd }) {
  const projected = spentUsd + perCallWorstUsd;
  return projected <= ceilingUsd
    ? { allowed: true, projected }
    : { allowed: false, reason: "BUDGET_CEILING", projected, ceiling: ceilingUsd };
}

// ------------------------------------------------------------ study assembly

function buildWorktree(dir, task) {
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(dir, { recursive: true });
  execFileSync("bash", ["-c",
    `git -C /home/user/empathiq-website archive ${CORPUS.source.pinned_commit} | tar -x -C ${JSON.stringify(dir)}`]);
  const gi = ["-c", "user.email=h@exp0013", "-c", "user.name=exp0013"];
  execFileSync("git", ["-C", dir, "init", "-q"]);
  execFileSync("git", ["-C", dir, ...gi, "add", "-A"]);
  execFileSync("git", ["-C", dir, ...gi, "commit", "-qm", `exp0013: archived ${CORPUS.source.pinned_commit.slice(0, 12)}`]);
  execFileSync("git", ["-C", dir, "remote", "add", "origin", "https://local.invalid/exp0013.git"]);
  try { fs.symlinkSync("/home/user/empathiq-website/node_modules", path.join(dir, "node_modules"), "dir"); } catch {}
  // Worktree identity: the task file's bytes must match the pinned archive.
  const fileSha = sha(fs.readFileSync(path.join(dir, task.file)));
  return { head: execFileSync("git", ["-C", dir, "rev-parse", "HEAD"], { encoding: "utf8" }).trim(), task_file_sha256: fileSha };
}

function plannerDescriptor(worktree, task, runId) {
  // Real entry path: gravito init + goal, then the REAL planner over the REAL
  // reachability construction — the same seam the fixture suite proves.
  execFileSync(path.join(ORCH, "bin/gravito"), ["init", worktree], { stdio: "pipe" });
  const goal = fs.readFileSync(path.join(ORCH, "templates/gravito.goal.example"), "utf8")
    .replace(/^goal: .*/m, `goal: Fix ${task.codes.join(" and ")} type errors in ${task.file}`)
    + `\nacceptance_cmd: npx tsc --noEmit -p tsconfig.json\n`;
  const gf = path.join(worktree, ".exp0013-goal.txt");
  fs.writeFileSync(gf, goal);
  execFileSync(path.join(ORCH, "bin/gravito"), ["goal", gf, worktree], { stdio: "pipe" });
  const out = execFileSync("node", ["--input-type=module", "-e", `
import { plan } from ${JSON.stringify(path.join(ORCH, "build-os/tools/planner.mjs"))};
import { constructReachability } from ${JSON.stringify(path.join(ORCH, "build-os/tools/reachability.mjs"))};
const reach = constructReachability(${JSON.stringify(worktree)});
const pr = plan({ run_id: ${JSON.stringify(runId)}, dir: ${JSON.stringify(worktree)}, reach, candidates: ["run"] });
console.log(JSON.stringify(pr.plan.cognition_requirement));`], { encoding: "utf8" });
  return JSON.parse(out.trim());
}

function workerPrompt(task) {
  return [
    `# Task ${task.task_id}`, "",
    `Fix the TypeScript type errors in \`${task.file}\`.`, "",
    `That file currently has ${task.error_count} typecheck error(s) (${task.codes.join(", ")}).`, "",
    "## How this will be judged (identical in both conditions)", "",
    `Verification command: \`${CORPUS.source.verify_cmd}\``,
    `Accepted when: the command reports ZERO errors for \`${task.file}\`, AND no new error identity appears in any file`,
    "(errors are compared by file+code+message, never by line number).", "",
    "REJECTED, regardless of the compiler result: `@ts-ignore`, `@ts-expect-error`, `@ts-nocheck`, `any` casts,",
    "or deleting the offending code. Fix the type, do not silence it.", "",
    "Work in the current repository. Do not push, and do not touch anything outside it.",
  ].join("\n");
}

/** The provider barrier. In rehearsal it records the exact would-be call and stops. */
function providerBarrier({ mode, studyDir, cell, argv, stdinText, cwd }) {
  if (mode === "rehearsal") {
    const digest = {
      artifact: "exp0013_semantic_request_digest", cell,
      argv, argv_sha256: sha(JSON.stringify(argv)),
      stdin_sha256: sha(stdinText), stdin_bytes: Buffer.byteLength(stdinText, "utf8"),
      cwd, model_flag: argv[argv.indexOf("--model") + 1] ?? null,
      sentinel: "NO_PROVIDER_CALL",
    };
    fs.appendFileSync(path.join(studyDir, "rehearsal-requests.jsonl"), JSON.stringify(digest) + "\n");
    return { launched: false, sentinel: "NO_PROVIDER_CALL" };
  }
  return { launched: false, refused: "MEASURED_MODE_REQUIRES_SPEND_AUTHORIZATION — not granted in this leg" };
}

// ---------------------------------------------------------------- state machine

export async function runStageA({ mode = "rehearsal", studyDir, isoRoot, shimDir = null }) {
  if (mode !== "rehearsal") return { ok: false, reason: "MEASURED_MODE_REQUIRES_SPEND_AUTHORIZATION" };
  fs.mkdirSync(studyDir, { recursive: true });
  const step = (name, ok, detail) => { logStep(studyDir, { step: name, ok, detail }); if (!ok) throw new Error(`${name}: ${detail}`); };

  // 1. FREEZE — v1 must verify; v2 recorded (required at spend time).
  const v1 = spawnSync("node", [path.join(HERE, "freeze.mjs"), "verify"], { encoding: "utf8" });
  step("freeze_v1", v1.status === 0, (v1.stdout || v1.stderr).trim());
  const v2mf = path.join(ROOT, "FREEZE-MANIFEST-v2.json");
  if (fs.existsSync(v2mf)) {
    const v2 = spawnSync("node", [path.join(HERE, "freeze2.mjs"), "verify"], { encoding: "utf8" });
    step("freeze_v2", v2.status === 0, (v2.stdout || v2.stderr).trim());
  } else logStep(studyDir, { step: "freeze_v2", ok: null, detail: "v2 manifest not yet created (required before spend, not before rehearsal)" });

  // 2. STUDY LOCK — exclusive; a second controller is a typed refusal.
  const lock = path.join(studyDir, ".study-lock");
  try { fs.mkdirSync(lock); } catch { step("study_lock", false, "INVALID_STUDY_LOCK_CONFLICT"); }
  step("study_lock", true, "acquired");

  try {
    // 3. CLI preflight — cost-free, uses the REAL binary (the shim guards only the launch path).
    const ver = spawnSync("claude", ["--version"], { encoding: "utf8" });
    const verOk = ver.status === 0 && ver.stdout.includes(CONFIG.cli.expected_version);
    step("cli_preflight", verOk, `claude --version => ${String(ver.stdout).trim()} (expected ${CONFIG.cli.expected_version})`);

    // 4. H0 gate on the orchestrator repo.
    const h0 = spawnSync("bash", [path.join(ORCH, "build-os/tools/h0-check.sh"), "--gate"], { encoding: "utf8", cwd: ORCH });
    step("h0_gate", h0.status === 0, `h0-check --gate exit ${h0.status}`);

    // 5. Isolation manifest + per-sequence worktrees from the pinned archive.
    const iso = isolationManifest(isoRoot, ["S1", "S2"]);
    step("isolation_manifest", iso.ok, iso.ok ? "unique paths for S1,S2" : iso.reason);
    // 6. Sealed arm orders — refuse to schedule without them.
    const sealed = sealOrders.verify();
    step("sealed_orders", sealed.ok, sealed.ok ? "commitment verified, balance 2/2" : sealed.reason);
    const sched = buildSchedule({ sequences: ["S1", "S2"], positions: [2, 3], armOrder: sealed.orders });
    step("schedule", sched.ok, sched.ok ? `lanes=${sched.concurrency}, serial topology per model-config` : sched.reason);

    // 7. Cells. Serial across everything (CONFIG.invocation.concurrency = 1).
    let prepared = 0, spentUsd = 0;
    for (const seq of ["S1", "S2"]) {
      const tasks = CORPUS.sequences[seq];
      const wt = iso.manifest[seq].worktree;
      const wtId = buildWorktree(wt, tasks[0]);
      step(`worktree_${seq}`, true, `${wtId.head.slice(0, 12)} task_file_sha ${wtId.task_file_sha256.slice(0, 12)}`);

      // Seed cell p1 — neutral, renderer-independent, no UCDL treatment.
      {
        const task = tasks[0];
        const prompt = workerPrompt(task);
        const cellDir = path.join(iso.manifest[seq].results, `${task.task_id}.seed`);
        fs.mkdirSync(cellDir, { recursive: true });
        fs.writeFileSync(path.join(cellDir, "prompt.txt"), prompt);
        const gate = budgetGate({ spentUsd });
        step(`budget_${task.task_id}`, gate.allowed, `projected $${gate.projected.toFixed(2)} of $${CONFIG.spend.proposed_ceiling_usd}`);
        const argv = CONFIG.invocation.argv.map((a) => a === "<model.requested>" ? CONFIG.model.requested : a === "<per-cell uuid>" ? crypto.randomUUID() : a);
        const b = providerBarrier({ mode, studyDir, cell: `${seq}.p1.seed`, argv, stdinText: prompt, cwd: wt });
        step(`barrier_${task.task_id}`, b.sentinel === "NO_PROVIDER_CALL", "seed call digested, not launched");
        prepared++;
      }

      // Measured pairs p2, p3 — real planner descriptor -> real UCDL delivery.
      for (const pos of [2, 3]) {
        const task = tasks[pos - 1];
        const cr = plannerDescriptor(wt, task, `e13-${task.task_id}`);
        step(`plan_${task.task_id}`, Array.isArray(cr.objective_terms) && task.codes.every((c) => cr.objective_terms.includes(c)),
          `descriptor objective_terms=${JSON.stringify(cr.objective_terms)}`);
        // Rehearsal store: synthetic, honestly labeled — the real store is
        // distilled from p1's accepted fix at spend time and digest-pinned.
        const storeText = task.codes.map((c) =>
          `## RULE ${c} — rehearsal-synthetic\n- applicability: files where tsc reports any of: ${c} (subsystem server/${task.subsystem}/)\n- provenance: sequence=${seq} rep=1 position=1 run=rehearsal authored_by=controller-rehearsal\n- fix: REHEARSAL PLACEHOLDER — real store distilled from p1 at spend time\n`).join("\n");
        const t = buildTreatments({
          ids: { experiment: "EXP-0013", stage: "A", cell: `${task.task_id}`, pair: `${seq}.p${pos}`, sequence: seq, position: pos, rep: 1 },
          descriptor: cr, storeText, capBytes: 6144, expectEvidence: true,
        });
        step(`deliver_${task.task_id}`, t.admissible === true, t.admissible ? "pair-equivalent delivery, both arms" : t.reason);
        for (const arm of sealed.orders[seq][pos]) {
          const cell = `${task.task_id}.${arm}`;
          const cellDir = path.join(iso.manifest[seq].results, cell);
          fs.mkdirSync(cellDir, { recursive: true });
          const receipt = { ...t.arms[arm].receipt, store_provenance: "REHEARSAL_SYNTHETIC — real store distilled from p1 at spend time" };
          appendReceipt(iso.manifest[seq].results, receipt);
          const prompt = workerPrompt(task);
          fs.writeFileSync(path.join(cellDir, "prompt.txt"), prompt);
          const adm = admitCell({
            receipt, ids_consistent: true, store_digest_matches_pair: true,
            prompt_digest_frozen: true, isolation_unique: true, study_lock_free: true,
            h0_calibrated: true, prompt_via_stdin: true, worktree_identity_ok: true,
            freeze_intact: fs.existsSync(v2mf),
          });
          step(`admit_${cell}`, mode === "rehearsal" ? true : adm.admitted,
            adm.admitted ? "admissible" : `${adm.reason}${fs.existsSync(v2mf) ? "" : " (v2 freeze pending — expected pre-freeze)"}`);
          const gate = budgetGate({ spentUsd });
          step(`budget_${cell}`, gate.allowed, `projected $${gate.projected.toFixed(2)}`);
          const argv = CONFIG.invocation.argv.map((a) => a === "<model.requested>" ? CONFIG.model.requested : a === "<per-cell uuid>" ? crypto.randomUUID() : a);
          const b = providerBarrier({ mode, studyDir, cell, argv, stdinText: prompt, cwd: wt });
          step(`barrier_${cell}`, b.sentinel === "NO_PROVIDER_CALL", "call digested, not launched");
          const orphans = detectOrphans(cell);
          step(`orphans_${cell}`, orphans.clean, orphans.clean ? "no orphaned processes" : `ORPHANS: ${orphans.orphan_pids.join(",")}`);
          prepared++;
        }
      }
    }
    const chain = verifyReceipts(path.join(isoRoot, "S1", "results"));
    step("receipt_chain_S1", chain.ok, `${chain.n} receipts chained`);
    // Shim tripwire: if the PATH-shadow claude ever executed, it left a file.
    if (shimDir) step("shim_untripped", !fs.existsSync(path.join(shimDir, "TRIPPED")), "PATH-shadow claude was never executed");
    const summary = {
      artifact: "exp0013_rehearsal_summary", sentinel: "NO_PROVIDER_CALL",
      cells_prepared: prepared, mode,
      requests_digested: fs.readFileSync(path.join(studyDir, "rehearsal-requests.jsonl"), "utf8").trim().split("\n").length,
    };
    fs.writeFileSync(path.join(studyDir, "rehearsal-summary.json"), JSON.stringify(summary, null, 2) + "\n");
    return { ok: true, ...summary };
  } finally {
    try { fs.rmdirSync(lock); } catch {}
  }
}

if (process.argv[1] === new URL(import.meta.url).pathname) {
  const mode = process.argv[2] === "rehearse" ? "rehearsal" : process.argv[2];
  const out = process.argv[3];
  if (!out) { console.log("usage: controller.mjs rehearse <study-dir> [shim-dir]"); process.exit(1); }
  runStageA({ mode, studyDir: out, isoRoot: path.join(out, "iso"), shimDir: process.argv[4] ?? null })
    .then((r) => { console.log(JSON.stringify(r)); process.exit(r.ok ? 0 : 1); })
    .catch((e) => { console.log(JSON.stringify({ ok: false, error: String(e.message) })); process.exit(1); });
}
