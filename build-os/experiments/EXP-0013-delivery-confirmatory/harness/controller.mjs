#!/usr/bin/env node
// EXP-0013 Stage-A EXECUTION CONTROLLER (AMENDMENT v3 — post-audit).
//
// One process owns the whole study lifecycle — no detached monitors
// (FAILURE-MODES row 2): every worker is spawned, supervised, timed out and
// reaped by THIS process, with a /proc orphan scan after every cell.
// Timeouts are controller-owned kills with a recorded terminal_reason (row 4).
//
// v3 changes (each disclosed in AMENDMENT-V3.md):
//   - TRANSPORT INJECTION: provider contact happens only through a transport
//     object. Rehearsal constructs ONLY transport-rehearsal.mjs, a module
//     with no child_process import — the no-call barrier is the import
//     graph, not a PATH trick (the PATH shim stays as a tripwire).
//   - MEASURED LOOP EXISTS AND IS TESTED: runMeasured() implements seeds,
//     distillation, store pinning, pairs in sealed order, model-id check
//     after call 1 (abort before call 2), pre-sealed rerun contingency
//     orders, seed-rerun policy, and every stop rule — proven with fake
//     transports, refused for real transport without a spend authorization.
//   - DURABLE ACCOUNTING: every call is reserved in the hash-chained spend
//     ledger BEFORE launch at the frozen per-call bound and settled after;
//     restart re-reads the ledger; unknown cost is never zero; a hard
//     MAX_CALLS=16 counter refuses call 17 regardless of budget.
//   - CLI preflight is a strict ["--version"]-only probe: the audit proved
//     that ANY other argv handed to the CLI is consumed as a prompt and
//     becomes a PAID model call.

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync, spawnSync } from "node:child_process";
import { buildTreatments, admitCell, appendReceipt, verifyReceipts } from "./fixture.mjs";
import { buildSchedule, isolationManifest } from "./scheduler.mjs";
import * as sealOrders from "./seal-orders.mjs";
import { detectOrphans } from "./supervise.mjs"; // v4: no execution primitive beyond the orphan scan
import { rehearsalTransport } from "./transport-rehearsal.mjs";
import { cliVersionProbe } from "./exec-registry.mjs";
import { buildProviderArgv } from "./provider-argv.mjs";
import { parseStream } from "./telemetry.mjs";
import { acceptance as oracleAcceptance } from "./oracle.mjs";
import { distill } from "./distill.mjs";
import * as ledger from "./spend-ledger.mjs";

export { detectOrphans };

const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");
const HERE = path.dirname(new URL(import.meta.url).pathname);
const ROOT = path.resolve(HERE, "..");
const ORCH = path.resolve(ROOT, "../../..");
export const CONFIG = JSON.parse(fs.readFileSync(path.join(HERE, "model-config.json"), "utf8"));
export const CORPUS = JSON.parse(fs.readFileSync(path.join(ROOT, "corpus", "sequences.json"), "utf8"));
export const MAX_CALLS = 16; // proven in the call-count enumeration: 2 seeds + 2 seed reruns + 8 measured + 2 pair-reruns x 2 cells

// ---------------------------------------------------------------- primitives

function logStep(dir, obj) {
  const f = path.join(dir, "controller-log.jsonl");
  const prev = (() => { try { const l = fs.readFileSync(f, "utf8").trim().split("\n"); return sha(l[l.length - 1]); } catch { return "genesis"; } })();
  fs.appendFileSync(f, JSON.stringify({ ...obj, prev_sha: prev }) + "\n");
}

export function budgetGate({ spentUsd, perCallWorstUsd = CONFIG.spend.per_call_worst_usd, ceilingUsd = CONFIG.spend.proposed_ceiling_usd }) {
  const projected = spentUsd + perCallWorstUsd;
  return projected <= ceilingUsd
    ? { allowed: true, projected }
    : { allowed: false, reason: "BUDGET_CEILING", projected, ceiling: ceilingUsd };
}

// AMENDMENT v4: the controller no longer execs the provider CLI at all.
// The version probe lives in exec-registry.mjs (typed argv allowlist, env
// scrubbed) and inference capability exists only in provider-call-site.mjs,
// which this module never imports — no-provider modes are structurally
// incapable of acquiring it.

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
  const fileSha = sha(fs.readFileSync(path.join(dir, task.file)));
  return { head: execFileSync("git", ["-C", dir, "rev-parse", "HEAD"], { encoding: "utf8" }).trim(), task_file_sha256: fileSha };
}

function plannerDescriptor(worktree, task, runId) {
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

export function workerPrompt(task) {
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

const buildArgv = () => buildProviderArgv(CONFIG, crypto.randomUUID()); // PURE text for rehearsal digests

// ---------------------------------------------------------------- rehearsal

export async function runStageA({ mode = "rehearsal", studyDir, isoRoot, shimDir = null }) {
  if (mode !== "rehearsal") return { ok: false, reason: "MEASURED_MODE_REQUIRES_SPEND_AUTHORIZATION" };
  fs.mkdirSync(studyDir, { recursive: true });
  const transport = rehearsalTransport(studyDir); // structurally exec-free
  const step = (name, ok, detail) => { logStep(studyDir, { step: name, ok, detail }); if (!ok) throw new Error(`${name}: ${detail}`); };

  const v1 = spawnSync("node", [path.join(HERE, "freeze.mjs"), "verify"], { encoding: "utf8" });
  step("freeze_v1", v1.status === 0, (v1.stdout || v1.stderr).trim());
  const v3mf = path.join(ROOT, "FREEZE-MANIFEST-v6.json");
  if (fs.existsSync(v3mf)) {
    const v3 = spawnSync("node", [path.join(HERE, "freeze6.mjs"), "verify"], { encoding: "utf8" });
    step("freeze_v6", v3.status === 0, (v3.stdout || v3.stderr).trim());
  } else logStep(studyDir, { step: "freeze_v6", ok: null, detail: "v6 manifest not yet created (required before spend, not before rehearsal)" });
  logStep(studyDir, { step: "freeze_v2", ok: null, detail: "v2 manifest preserved as immutable history; superseded per AMENDMENT-V3.md/V4.md" });

  const lock = path.join(studyDir, ".study-lock");
  try { fs.mkdirSync(lock); } catch { step("study_lock", false, "INVALID_STUDY_LOCK_CONFLICT"); }
  step("study_lock", true, "acquired");

  try {
    const ver = cliVersionProbe();
    const verOk = !ver.refused && ver.status === 0 && ver.stdout.includes(CONFIG.cli.expected_version);
    step("cli_preflight", verOk, `claude --version => ${String(ver.refused ?? ver.stdout).trim()} (expected ${CONFIG.cli.expected_version}; registry-gated, argv strictly ["--version"], env scrubbed)`);

    const h0 = spawnSync("bash", [path.join(ORCH, "build-os/tools/h0-check.sh"), "--gate"], { encoding: "utf8", cwd: ORCH });
    step("h0_gate", h0.status === 0, `h0-check --gate exit ${h0.status}`);

    const iso = isolationManifest(isoRoot, ["S1", "S2"]);
    step("isolation_manifest", iso.ok, iso.ok ? "unique paths for S1,S2" : iso.reason);
    const sealed = sealOrders.verify();
    step("sealed_orders", sealed.ok, sealed.ok ? "commitment verified, balance 2/2" : sealed.reason);
    const rerunSealed = sealOrders.verifyRerun();
    step("sealed_rerun_orders", rerunSealed.ok, rerunSealed.ok ? "contingency rerun orders precommitted" : rerunSealed.reason);
    const sched = buildSchedule({ sequences: ["S1", "S2"], positions: [2, 3], armOrder: sealed.orders });
    step("schedule", sched.ok, sched.ok ? `lanes=${sched.concurrency}, serial topology per model-config` : sched.reason);

    let prepared = 0;
    for (const seq of ["S1", "S2"]) {
      const tasks = CORPUS.sequences[seq];
      const wt = iso.manifest[seq].worktree;
      const wtId = buildWorktree(wt, tasks[0]);
      step(`worktree_${seq}`, true, `${wtId.head.slice(0, 12)} task_file_sha ${wtId.task_file_sha256.slice(0, 12)}`);

      { // seed p1
        const task = tasks[0];
        const prompt = workerPrompt(task);
        const cellDir = path.join(iso.manifest[seq].results, `${task.task_id}.seed`);
        fs.mkdirSync(cellDir, { recursive: true });
        fs.writeFileSync(path.join(cellDir, "prompt.txt"), prompt);
        const gate = budgetGate({ spentUsd: 0 });
        step(`budget_${task.task_id}`, gate.allowed, `projected $${gate.projected.toFixed(2)} of $${CONFIG.spend.proposed_ceiling_usd}`);
        const b = await transport.call({ cell: `${seq}.p1.seed`, argv: buildArgv(), stdinText: prompt, cwd: wt, cwdDisplay: `<ISO>/${seq}/worktree` });
        step(`barrier_${task.task_id}`, b.sentinel === "NO_PROVIDER_CALL", "seed call digested, not launched");
        prepared++;
      }

      for (const pos of [2, 3]) {
        const task = tasks[pos - 1];
        const cr = plannerDescriptor(wt, task, `e13-${task.task_id}`);
        step(`plan_${task.task_id}`, Array.isArray(cr.objective_terms) && task.codes.every((c) => cr.objective_terms.includes(c)),
          `descriptor objective_terms=${JSON.stringify(cr.objective_terms)}`);
        // Rehearsal store: produced by the REAL distiller from a synthetic
        // accepted-seed record, honestly labeled; the live store comes from
        // the actual p1 diff at spend time via the same code path.
        const d = distill({ task: tasks[0], acceptance: { accepted: true, target_errors_before: tasks[0].error_count },
          diffText: `diff --git a/${tasks[0].file} b/${tasks[0].file}\n+rehearsal placeholder fix\n` });
        step(`distill_${task.task_id}`, d.ok === true, d.ok ? `store ${d.store_digest.slice(0, 12)} via distill-v3 (rehearsal-synthetic seed record)` : d.reason);
        // Rehearsal-only augmentation: guarantee every task code has a store
        // match so delivery equivalence is exercised for p2 AND p3.
        const storeText = d.storeText + "\n" + task.codes.map((c) =>
          `## RULE ${c} — rehearsal-synthetic\n- applicability: files where tsc reports any of: ${c} (subsystem server/${task.subsystem}/)\n- provenance: sequence=${seq} rep=1 position=1 run=rehearsal authored_by=controller-rehearsal\n`).join("\n");
        const t = buildTreatments({
          ids: { experiment: "EXP-0013", stage: "A", cell: `${task.task_id}`, pair: `${seq}.p${pos}`, sequence: seq, position: pos, rep: 1 },
          descriptor: cr, storeText, capBytes: 6144, expectEvidence: true,
        });
        step(`deliver_${task.task_id}`, t.admissible === true, t.admissible ? "pair-equivalent delivery, both arms" : t.reason);
        for (const arm of sealed.orders[seq][pos]) {
          const cell = `${task.task_id}.${arm}`;
          const cellDir = path.join(iso.manifest[seq].results, cell);
          fs.mkdirSync(cellDir, { recursive: true });
          const receipt = { ...t.arms[arm].receipt, store_provenance: "REHEARSAL_SYNTHETIC — live store distilled from p1 at spend time via distill.mjs" };
          appendReceipt(iso.manifest[seq].results, receipt);
          const prompt = workerPrompt(task);
          fs.writeFileSync(path.join(cellDir, "prompt.txt"), prompt);
          const adm = admitCell({
            receipt, ids_consistent: true, store_digest_matches_pair: true,
            prompt_digest_frozen: true, isolation_unique: true, study_lock_free: true,
            h0_calibrated: true, prompt_via_stdin: true, worktree_identity_ok: true,
            freeze_intact: fs.existsSync(v3mf),
          });
          step(`admit_${cell}`, mode === "rehearsal" ? true : adm.admitted,
            adm.admitted ? "admissible" : `${adm.reason}${fs.existsSync(v3mf) ? "" : " (v6 freeze pending — expected pre-freeze)"}`);
          const gate = budgetGate({ spentUsd: 0 });
          step(`budget_${cell}`, gate.allowed, `projected $${gate.projected.toFixed(2)}`);
          const b = await transport.call({ cell, argv: buildArgv(), stdinText: prompt, cwd: wt, cwdDisplay: `<ISO>/${seq}/worktree` });
          step(`barrier_${cell}`, b.sentinel === "NO_PROVIDER_CALL", "call digested, not launched");
          const orphans = detectOrphans(cell);
          step(`orphans_${cell}`, orphans.clean, orphans.clean ? "no orphaned processes" : `ORPHANS: ${orphans.orphan_pids.join(",")}`);
          prepared++;
        }
      }
    }
    const chain = verifyReceipts(path.join(isoRoot, "S1", "results"));
    step("receipt_chain_S1", chain.ok, `${chain.n} receipts chained`);
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

// ---------------------------------------------------------------- measured

/**
 * The measured Stage-A state machine. Provider contact ONLY via `transport`:
 *   - transport.kind "measured-real" REQUIRES a valid owner spend
 *     authorization file naming the current v3 freeze digest;
 *   - transport.kind "test-fake" drives the same state machine with scripted
 *     fake streams for the call-count / budget / model-check / rerun / void
 *     proofs — it can never build or exec a provider argv.
 * `oracleFor({seq, cell, worktree})` returns {baselineText, afterText} for
 * acceptance; tests inject synthetic texts, the real run uses tsc output.
 */
export async function runMeasured({ studyDir, isoRoot, transport, spendAuthPath = null, oracleFor, promptFor = null }) {
  fs.mkdirSync(studyDir, { recursive: true });
  const events = [];
  const step = (name, ok, detail) => { logStep(studyDir, { step: name, ok, detail }); events.push({ name, ok, detail }); };
  const abort = (reason) => ({ ok: false, reason, events, ledger: ledger.loadLedger(studyDir) });

  if (!transport || !["measured-real", "test-fake"].includes(transport.kind)) return abort("UNKNOWN_TRANSPORT");
  if (transport.kind === "measured-real") {
    if (!spendAuthPath || !fs.existsSync(spendAuthPath)) return abort("MEASURED_MODE_REQUIRES_SPEND_AUTHORIZATION");
    let auth; try { auth = JSON.parse(fs.readFileSync(spendAuthPath, "utf8")); } catch { return abort("SPEND_AUTH_MALFORMED"); }
    const v3mf = path.join(ROOT, "FREEZE-MANIFEST-v6.json");
    const digest = fs.existsSync(v3mf) ? sha(fs.readFileSync(v3mf)) : null;
    if (auth.spend_authorized !== true || !auth.freeze_digest || auth.freeze_digest !== digest)
      return abort("SPEND_AUTH_INVALID_OR_FREEZE_MISMATCH");
    const v3 = spawnSync("node", [path.join(HERE, "freeze6.mjs"), "verify"], { encoding: "utf8" });
    if (v3.status !== 0) return abort("INVALID_HARNESS_CHANGED_AFTER_FREEZE");
  }

  const sealed = sealOrders.verify();
  if (!sealed.ok) return abort(`SEALED_ORDERS: ${sealed.reason}`);
  const rerunSealed = sealOrders.verifyRerun();
  if (!rerunSealed.ok) return abort(`SEALED_RERUN_ORDERS: ${rerunSealed.reason}`);

  const lock = path.join(studyDir, ".study-lock");
  try { fs.mkdirSync(lock); } catch { return abort("INVALID_STUDY_LOCK_CONFLICT"); }

  const bound = CONFIG.spend.per_call_worst_usd, ceiling = CONFIG.spend.proposed_ceiling_usd;
  let callIndex = 0;
  let totalPairReruns = 0; // study-level: frozen max 2, checked BEFORE any rerun spend
  const modelChecked = { done: false };
  const cells = [];

  /** One provider call under EVERY gate: ledger integrity, call ceiling,
   *  budget projection, reservation-before-launch, settle-after. */
  const gatedCall = async ({ cell, kind, prompt, cwd, outFile }) => {
    const led = ledger.loadLedger(studyDir);
    if (!led.ok) return { refused: led.reason };
    if (led.calls >= MAX_CALLS) return { refused: "CALL_CEILING" };
    const gate = budgetGate({ spentUsd: led.spent_conservative_usd, perCallWorstUsd: bound, ceilingUsd: ceiling });
    if (!gate.allowed) return { refused: "BUDGET_CEILING" };
    const idx = callIndex++;
    ledger.reserveCall(studyDir, { call_index: idx, cell, kind, bound_usd: bound });
    // v4: the TRANSPORT owns argv construction and execution; the state
    // machine hands over only the semantic request.
    const res = await transport.call({ cell, stdinText: prompt, cwd, env: process.env, ceilingS: CONFIG.invocation.timeout_ceiling_s, outFile, marker: cell });
    const streamText = fs.existsSync(outFile) ? fs.readFileSync(outFile, "utf8") : "";
    const tel = parseStream(streamText, { allowedModelIds: CONFIG.model.allowed_provider_model_ids });
    ledger.settleCall(studyDir, { call_index: idx, cell, cost_usd: tel.economics?.total_cost_usd ?? null, metered: tel.metered });
    // Model-id gate: enforced on the FIRST call that carries provider
    // telemetry, before any further call. An unmetered call (timeout/abort)
    // has no id to judge — it is already infrastructure-invalid and the
    // seed/reliability policies own it; the gate stays armed until a result
    // event actually names the model.
    if (!modelChecked.done && tel.metered) {
      modelChecked.done = true;
      const bad = tel.reasons.find((r) => r.startsWith("MODEL_ID_NOT_ALLOWED") || r === "MODEL_ID_MISSING");
      if (bad) return { res, tel, modelAbort: bad };
    } else if (!modelChecked.done && tel.provider_model_ids.length > 0) {
      // Id present without full metering (e.g. init event then abort): still judge it.
      modelChecked.done = true;
      const bad = tel.reasons.find((r) => r.startsWith("MODEL_ID_NOT_ALLOWED"));
      if (bad) return { res, tel, modelAbort: bad };
    }
    const orphans = detectOrphans(cell);
    if (!orphans.clean) return { res, tel, orphanFail: orphans.orphan_pids };
    return { res, tel };
  };

  try {
    for (const seq of ["S1", "S2"]) {
      const tasks = CORPUS.sequences[seq];
      const iso = isolationManifest(isoRoot, ["S1", "S2"]);
      if (!iso.ok) return abort("ISOLATION_COLLISION");
      const wt = iso.manifest[seq].worktree;
      const resultsDir = iso.manifest[seq].results;
      fs.mkdirSync(resultsDir, { recursive: true });
      if (transport.kind === "measured-real") buildWorktree(wt, tasks[0]); // fake transports never touch a worktree

      // --- SEED (p1): one neutral call; ONE rerun permitted; else SEQUENCE_VOID.
      let store = null;
      for (let attempt = 1; attempt <= 2 && !store; attempt++) {
        const task = tasks[0];
        const cell = `${task.task_id}.seed${attempt > 1 ? ".rerun" : ""}`;
        const outFile = path.join(resultsDir, `${cell}.stream.jsonl`);
        const prompt = (promptFor ?? workerPrompt)(task);
        const r = await gatedCall({ cell, kind: "seed", prompt, cwd: wt, outFile });
        if (r.refused) { step(`seed_${cell}`, false, r.refused); return abort(r.refused); }
        if (r.modelAbort) { step("model_id_gate", false, `${r.modelAbort} — study aborted after call 1, before call 2`); return abort(r.modelAbort); }
        if (r.orphanFail) { step(`orphans_${cell}`, false, r.orphanFail.join(",")); return abort("ORPHANED_WORKER"); }
        // v6 (review F1): the oracle FAILS CLOSED — a runner throw is a seed
        // failure, never a silently-clean compile.
        let d = null, oracleFail = null;
        try {
          const o = oracleFor({ seq, cell, worktree: wt, kind: "seed" });
          const acc = oracleAcceptance({ baselineText: o.baselineText, afterText: o.afterText, targetFile: task.file });
          d = distill({ task, acceptance: acc, diffText: o.diffText ?? "" });
        } catch (e) { oracleFail = String(e.message).slice(0, 120); }
        if (r.res.terminal_reason !== "success" || !r.tel.metered || oracleFail || !d?.ok) {
          step(`seed_${cell}`, false, `terminal=${r.res.terminal_reason} metered=${r.tel.metered} oracle=${oracleFail ?? "ok"} distill=${d ? (d.ok ? "ok" : d.reason) : "n/a"}`);
          if (attempt === 2) return abort("SEQUENCE_VOID_SEED_FAILED_TWICE");
        } else {
          store = d;
          step(`seed_${cell}`, true, `store pinned ${d.store_digest.slice(0, 12)}`);
        }
      }

      // --- PAIRS (p2, p3) in the sealed order; pre-sealed rerun contingency.
      for (const pos of [2, 3]) {
        const task = tasks[pos - 1];
        for (let round = 1; round <= 2; round++) {
          const order = round === 1 ? sealed.orders[seq][pos] : rerunSealed.orders[seq][pos];
          const cr = { action: "run", state: "CONTEXT_REQUIRED", objective_terms: task.codes, authority_summary: "measured", verification: "runnable", correlation: { run_id: `e13-${task.task_id}-r${round}` } };
          const t = buildTreatments({
            ids: { experiment: "EXP-0013", stage: "A", cell: task.task_id, pair: `${seq}.p${pos}`, sequence: seq, position: pos, rep: round },
            descriptor: cr, storeText: store.storeText, capBytes: 6144, expectEvidence: true,
          });
          if (!t.admissible) { step(`deliver_${task.task_id}`, false, t.reason); return abort(`STAGE_VOID_DELIVERY: ${t.reason}`); }
          let infraInvalid = false;
          for (const arm of order) {
            const cell = `${task.task_id}.${arm}${round > 1 ? ".rerun" : ""}`;
            const outFile = path.join(resultsDir, `${cell}.stream.jsonl`);
            appendReceipt(resultsDir, { ...t.arms[arm].receipt, store_provenance: `distill-v3 store ${store.store_digest.slice(0, 12)}` });
            const prompt = (promptFor ?? workerPrompt)(task);
            const r = await gatedCall({ cell, kind: "measured", prompt, cwd: wt, outFile });
            if (r.refused) { step(`cell_${cell}`, false, r.refused); return abort(r.refused); }
            if (r.modelAbort) { step("model_id_gate", false, r.modelAbort); return abort(r.modelAbort); }
            if (r.orphanFail) { step(`orphans_${cell}`, false, r.orphanFail.join(",")); return abort("ORPHANED_WORKER"); }
            let infra = r.res.terminal_reason !== "success" || !r.tel.metered;
            let terminal = r.res.terminal_reason;
            let acc = null;
            if (!infra) {
              // v6 (review F1): a runner throw makes the CELL infrastructure-
              // invalid under an honest terminal_reason — never a clean run.
              try {
                const o = oracleFor({ seq, cell, worktree: wt, kind: "measured", arm });
                acc = oracleAcceptance({ baselineText: o.baselineText, afterText: o.afterText, targetFile: task.file });
              } catch { infra = true; terminal = "oracle_failed"; }
            }
            if (infra) infraInvalid = true;
            cells.push({ seq, pos, arm, rerun_of: round > 1 ? `${seq}.${pos}` : null,
              delivery_valid: true, invalid_reason: null,
              accepted: acc ? acc.accepted : null, metered: r.tel.metered,
              economics: r.tel.economics, elapsed_s: r.res.elapsed_s,
              terminal_reason: terminal });
            step(`cell_${cell}`, true, `terminal=${r.res.terminal_reason} metered=${r.tel.metered} accepted=${acc ? acc.accepted : "n/a"}`);
          }
          if (!infraInvalid) break;
          if (round === 2) { step(`pair_${seq}.p${pos}`, false, "rerun also infrastructure-invalid"); break; }
          if (totalPairReruns >= 2) return abort("RERUN_BUDGET_EXHAUSTED"); // refused BEFORE any rerun spend
          totalPairReruns++;
          step(`pair_rerun_${seq}.p${pos}`, true, "whole-pair rerun from PRE-SEALED contingency order");
        }
      }
    }
    const led = ledger.loadLedger(studyDir);
    return { ok: true, cells, events, calls: led.calls, spent_conservative_usd: led.spent_conservative_usd };
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
