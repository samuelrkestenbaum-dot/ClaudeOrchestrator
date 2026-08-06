#!/usr/bin/env node
// EXP-0004 — THE MATCHED-ARM RUNNER.
//
//   node run-exp0004.mjs register       --tasks <tasks.json> --eligibility <elig.json> --out <registry.json>
//   node run-exp0004.mjs exclusions
//   node run-exp0004.mjs plan           --registry <registry.json>
//   node run-exp0004.mjs assert-matched --registry <registry.json> --pair <pair.json>
//   node run-exp0004.mjs arm-start      --repo <dir> --seed <sha> --arm A|B --task <id>
//   node run-exp0004.mjs run-pair       --registry <registry.json> --pair <pair.json> --repo <dir> --out <dir>
//                                       [--exec-cmd <shell command>] [--reset-between-arms]
//   node run-exp0004.mjs aggregate      --registry <registry.json> --records <dir> --out <aggregate.json>
//                                       [--confound <text> ...]
//
// This harness DOES NOT SELECT TASKS. Selection happens after PILOT-0002
// closes and after the AMENDMENT 1 eligibility check passes; the runner takes
// whatever task set is frozen and refuses the ones it must.
//
// WHAT IS ASSERTED, NOT ASSUMED
//
// 1. MATCHED ARMS. Eight fields must be identical across A and B before a pair
//    runs: repository_seed_commit, task_definition, model_id,
//    acceptance_criteria, max_retries, authority_mode_policy,
//    baseline_measurement, measurement_boundaries. Any mismatch — or any
//    absence — refuses (exit 2) NAMING the field. Each is also cross-checked
//    against the registry's frozen value, so a pair cannot agree with itself
//    while disagreeing with what was registered.
//
// 2. DETERMINISTIC ORDER. Arm order is DERIVED from a registered rule
//    (`task-index-parity-v1`: even task index runs A then B, odd runs B then
//    A) and RECORDED in the registry and in every pair record. Nothing here
//    samples a random number or reads a clock; two registrations of the same
//    input are byte-identical.
//
// 3. CLEAN RESET. No arm starts on a moving tree. Before each arm the runner
//    verifies HEAD equals the pinned seed and `git status --porcelain` is
//    empty; a dirty tree refuses (exit 2) and names the offending paths. With
//    --reset-between-arms the tree is returned to the pinned seed between arms
//    and after the pair, and the reset is RECORDED.
//
// 4. PRIOR-PILOT EXCLUSION. The ten frozen tasks of PILOT-0001 and PILOT-0002
//    are refused AT REGISTRATION, by name — never silently skipped later.
//    Matching is deliberately broad: a false refusal costs one task, while a
//    false admission contaminates a frozen pilot.
//
// 5. AMENDMENT 2 CONFOUNDS. At aggregate time each arm-B record must show that
//    its starting bytes are exactly capsule + prefix and that the broad-context
//    payload was NOT also delivered. A failure — or an unverifiable check — is
//    recorded `result_confounded` and EXCLUDED from the aggregate, and the
//    exclusion is written to a ledger so the task can never be repaired or
//    re-run back into the aggregate.
//
// Invoke via node; this file is deliberately NOT executable.
// Exit: 0 completed; 2 refusal. Dependencies: node stdlib only.

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { loadThresholds } from "./prereg-thresholds.mjs";
import { readRecord, fieldValue, fieldTier, UNKNOWN } from "./measure.mjs";

export const EXPERIMENT = "EXP-0004";
export const HARNESS_VERSION = "1.0.0";

// ---------------------------------------------------------------- the rule --

export const ARM_ORDER_RULE = {
  id: "task-index-parity-v1",
  statement:
    "arm order is the parity of the task's index in the registered task list: even index runs A then B, odd index runs B then A",
  counterbalancing: "the preregistration requires counterbalanced task order; parity supplies it without sampling",
  derivation: "derived from the registered task order; no random source and no clock is read anywhere in this harness",
};

export function armOrderFor(index) {
  return index % 2 === 0 ? ["A", "B"] : ["B", "A"];
}

// ------------------------------------------------- the eight matched fields --

export const INVARIANT_FIELDS = [
  { name: "repository_seed_commit", frozen: "pinned_seed_commit" },
  { name: "task_definition", fromTask: "task_definition_sha256" },
  { name: "model_id", frozen: "model_id" },
  { name: "acceptance_criteria", fromTask: "acceptance_criteria" },
  { name: "max_retries", frozen: "max_retries" },
  { name: "authority_mode_policy", frozen: "authority_mode_policy" },
  { name: "baseline_measurement", frozen: "baseline_measurement" },
  { name: "measurement_boundaries", frozen: "measurement_boundaries" },
];

export const FROZEN_FIELDS = [
  "pinned_seed_commit",
  "model_id",
  "max_retries",
  "authority_mode_policy",
  "baseline_measurement",
  "measurement_boundaries",
];

// ------------------------------------------------------- the exclusion list --

// A candidate matches an entry when ANY fingerprint's terms ALL appear in the
// candidate's lowercased id + title + description + acceptance text.
export const EXCLUSION_LIST_VERSION = "prior-pilot-v1";
export const EXCLUSIONS = [
  { id: "PILOT-0001-T1", name: "diagnose the red baseline", fingerprints: [["diagnose", "baseline"], ["classify", "check:app"]] },
  { id: "PILOT-0001-T2", name: "hermetic notification test", fingerprints: [["vacuous", "shadow"], ["notification", "autonomy rate"], ["remediation-notifications"]] },
  { id: "PILOT-0001-T3", name: "four_eyes_state_change operator-event kind", fingerprints: [["four_eyes_state_change"], ["four-eyes", "operator-event"]] },
  { id: "PILOT-0001-T4", name: "executeFixLayer dry-run test", fingerprints: [["executefixlayer"], ["dry-run", "operationalization.test.ts"]] },
  { id: "PILOT-0001-T5", name: "stripe error cluster", fingerprints: [["stripe"]] },
  { id: "PILOT-0002-T1", name: "trpc bridge cluster", fingerprints: [["trpc", "bridge"], ["trpc", "bridges"]] },
  { id: "PILOT-0002-T2", name: "CoverageReportData drift", fingerprints: [["coveragereportdata"]] },
  { id: "PILOT-0002-T3", name: "agents hermetic tests", fingerprints: [["agents", "hermetic"], ["agents.test.ts"]] },
  { id: "PILOT-0002-T4", name: "training/router interface conflict", fingerprints: [["iautoretrainingpipeline"], ["training", "router", "interface"], ["autoretrainingpipeline"]] },
  { id: "PILOT-0002-T5", name: "voice-stream / webhooks narrowing", fingerprints: [["voice-stream"], ["webhooks", "narrowing"], ["voice stream gateway"]] },
];

export function haystackOf(task) {
  return [task.id, task.title, task.description, ...(task.acceptance_criteria || [])]
    .filter((s) => typeof s === "string")
    .join(" ")
    .toLowerCase();
}

/** The excluded entry a candidate matches, or null. */
export function excludedBy(task) {
  const hay = haystackOf(task);
  for (const e of EXCLUSIONS) {
    if (hay.includes(e.id.toLowerCase())) return { entry: e, fingerprint: [e.id] };
    for (const fp of e.fingerprints) {
      if (fp.every((term) => hay.includes(term))) return { entry: e, fingerprint: fp };
    }
  }
  return null;
}

// ---------------------------------------------------------------- plumbing --

class Refusal extends Error {}
const refuse = (m) => {
  throw new Refusal(m);
};

const canon = (v) => JSON.stringify(sortDeep(v));
function sortDeep(v) {
  if (Array.isArray(v)) return v.map(sortDeep);
  if (v && typeof v === "object") {
    const out = {};
    for (const k of Object.keys(v).sort()) out[k] = sortDeep(v[k]);
    return out;
  }
  return v;
}

function readJson(file, what) {
  let raw;
  try {
    raw = fs.readFileSync(file, "utf8");
  } catch {
    refuse(`${what} not readable: ${file}`);
  }
  try {
    return JSON.parse(raw);
  } catch (e) {
    refuse(`${what} is not valid JSON (${file}): ${e.message}`);
  }
}

function git(repo, args) {
  const r = spawnSync("git", ["-C", repo, ...args], { encoding: "utf8" });
  if (r.error) refuse(`git ${args.join(" ")} failed in ${repo}: ${r.error.message}`);
  return { code: r.status, out: (r.stdout || "").trim(), err: (r.stderr || "").trim() };
}

// -------------------------------------------------------------- register ---

export function taskDefinitionSha(task) {
  const material = [task.title, task.description, ...(task.acceptance_criteria || [])].join("\n");
  return crypto.createHash("sha256").update(material, "utf8").digest("hex");
}

function cmdRegister(opt) {
  if (!opt.tasks) refuse("register needs --tasks <tasks.json>");
  if (!opt.out) refuse("register needs --out <registry.json>");
  if (!opt.eligibility) {
    refuse(
      "register needs --eligibility <file>: AMENDMENT 1 makes measured parser coverage a PRECONDITION recorded " +
        "before arm A begins. No eligibility evidence, no registration."
    );
  }
  const th = loadThresholds(opt.prereg).values;
  const spec = readJson(opt.tasks, "task set");
  const elig = readJson(opt.eligibility, "eligibility evidence");

  for (const f of FROZEN_FIELDS) {
    if (spec[f] === undefined || spec[f] === null || spec[f] === "") {
      refuse(`task set is missing the frozen field '${f}' — it is identical across arms and cannot be left open`);
    }
  }
  if (typeof elig.no_parser_share_pct !== "number") {
    refuse("eligibility evidence is missing a numeric no_parser_share_pct (AMENDMENT 1 states the precondition as a number)");
  }
  if (elig.recorded_before_arm_a !== true) {
    refuse(
      "eligibility evidence must set recorded_before_arm_a: true — AMENDMENT 1 requires the measurement be RECORDED before arm A begins"
    );
  }
  if (elig.no_parser_share_pct >= th.no_parser_max_pct) {
    refuse(
      `eligibility — no_parser share is ${elig.no_parser_share_pct}%, not below the preregistered ${th.no_parser_max_pct}% ceiling ` +
        `(AMENDMENT 1). This repository is excluded, or the run is registered result confounded; it is not run and explained afterwards.`
    );
  }
  if (!Array.isArray(spec.tasks) || spec.tasks.length === 0) refuse("task set carries no tasks");

  const tasks = [];
  spec.tasks.forEach((t, i) => {
    for (const k of ["id", "title", "description"]) {
      if (typeof t[k] !== "string" || !t[k]) refuse(`task at index ${i} is missing '${k}'`);
    }
    if (!Array.isArray(t.acceptance_criteria) || t.acceptance_criteria.length === 0) {
      refuse(`task '${t.id}' has no acceptance_criteria — acceptance is identical across arms and must exist before the run`);
    }
    const hit = excludedBy(t);
    if (hit) {
      refuse(
        `task '${t.id}' is EXCLUDED at registration: it matches the frozen prior-pilot task ${hit.entry.id} ` +
          `(${hit.entry.name}) on [${hit.fingerprint.join(" + ")}]. Using a frozen pilot's task would contaminate it ` +
          `(AB_PREREGISTRATION.md, "Task set — MUST NOT overlap PILOT-0002"). Refused, not skipped.`
      );
    }
    tasks.push({
      index: i,
      id: t.id,
      title: t.title,
      shape: t.shape || UNKNOWN,
      task_definition_sha256: taskDefinitionSha(t),
      acceptance_criteria: t.acceptance_criteria,
      arm_order: armOrderFor(i),
    });
  });

  const registry = {
    experiment: EXPERIMENT,
    harness_version: HARNESS_VERSION,
    frozen: Object.fromEntries(FROZEN_FIELDS.map((f) => [f, spec[f]])),
    eligibility: elig,
    arm_order_rule: ARM_ORDER_RULE,
    exclusion_list_version: EXCLUSION_LIST_VERSION,
    excluded_prior_pilot_tasks: EXCLUSIONS.map((e) => `${e.id} — ${e.name}`),
    invariant_fields: INVARIANT_FIELDS.map((f) => f.name),
    tasks,
  };
  fs.writeFileSync(opt.out, JSON.stringify(registry, null, 2) + "\n");
  process.stdout.write(
    `registered: ${tasks.length} task(s); arm_order_rule: ${ARM_ORDER_RULE.id}; ` +
      `no_parser_share_pct: ${elig.no_parser_share_pct} (< ${th.no_parser_max_pct} ceiling)\n`
  );
  return 0;
}

function cmdExclusions() {
  const L = [];
  L.push(`EXP-0004 prior-pilot exclusion list — version ${EXCLUSION_LIST_VERSION}`);
  L.push("A candidate task matching any entry is REFUSED at registration, never silently skipped later.");
  L.push("");
  for (const e of EXCLUSIONS) {
    L.push(`${e.id}  ${e.name}  [${e.fingerprints.map((f) => f.join("+")).join(" | ")}]`);
  }
  L.push("");
  L.push("Matching is deliberately broad: a false refusal costs one candidate task; a false admission");
  L.push("contaminates a frozen pilot, which cannot be undone.");
  process.stdout.write(L.join("\n") + "\n");
  return 0;
}

function cmdPlan(opt) {
  if (!opt.registry) refuse("plan needs --registry <registry.json>");
  const reg = readJson(opt.registry, "registry");
  const L = [];
  L.push(`${reg.experiment} — matched-arm plan (harness ${reg.harness_version})`);
  L.push(`arm_order_rule: ${reg.arm_order_rule.id}`);
  L.push(`arm_order_rule_statement: ${reg.arm_order_rule.statement}`);
  L.push(`pinned_seed_commit: ${reg.frozen.pinned_seed_commit}`);
  L.push(`model_id: ${reg.frozen.model_id}`);
  L.push("");
  for (const t of reg.tasks) L.push(`${t.id}: ${t.arm_order.join(",")}`);
  process.stdout.write(L.join("\n") + "\n");
  return 0;
}

// -------------------------------------------------------- matched assertion --

export function assertMatched(reg, pair) {
  if (!pair || typeof pair.task_id !== "string") refuse("pair record has no task_id");
  const task = reg.tasks.find((t) => t.id === pair.task_id);
  if (!task) {
    refuse(
      `pair task '${pair.task_id}' is not in the registry — a pair cannot run for a task that never passed registration ` +
        `(the prior-pilot exclusion gate lives there)`
    );
  }
  for (const side of ["arm_a", "arm_b"]) {
    if (!pair[side] || typeof pair[side] !== "object") refuse(`pair record has no ${side} block`);
  }
  for (const f of INVARIANT_FIELDS) {
    const a = pair.arm_a[f.name];
    const b = pair.arm_b[f.name];
    if (a === undefined) refuse(`identical-across-arms field '${f.name}' is ABSENT from arm_a — it is asserted, never assumed`);
    if (b === undefined) refuse(`identical-across-arms field '${f.name}' is ABSENT from arm_b — it is asserted, never assumed`);
    if (canon(a) !== canon(b)) {
      refuse(
        `identical-across-arms field '${f.name}' DIFFERS between arms: A=${canon(a)} B=${canon(b)}. ` +
          `The arms are not matched; the pair is refused rather than run.`
      );
    }
    const expected = f.frozen ? reg.frozen[f.frozen] : task[f.fromTask];
    if (expected !== undefined && canon(a) !== canon(expected)) {
      refuse(
        `identical-across-arms field '${f.name}' differs from the REGISTRY-frozen value: pair=${canon(a)} registry=${canon(expected)}`
      );
    }
  }
  return task;
}

function cmdAssertMatched(opt) {
  if (!opt.registry) refuse("assert-matched needs --registry <registry.json>");
  if (!opt.pair) refuse("assert-matched needs --pair <pair.json>");
  const reg = readJson(opt.registry, "registry");
  const pair = readJson(opt.pair, "pair record");
  const task = assertMatched(reg, pair);
  process.stdout.write(
    `invariance_assertion: PASS\ntask_id: ${task.id}\nfields_asserted: ${INVARIANT_FIELDS.map((f) => f.name).join(",")}\n`
  );
  return 0;
}

// ------------------------------------------------------------- arm start ----

export function armStartCheck(repo, seed, arm, taskId) {
  if (!fs.existsSync(path.join(repo, ".git"))) refuse(`${repo} is not a git work tree — the seed cannot be verified`);
  const head = git(repo, ["rev-parse", "HEAD"]);
  if (head.code !== 0) refuse(`git rev-parse HEAD failed in ${repo}: ${head.err}`);
  if (head.out !== seed) {
    refuse(
      `repository HEAD ${head.out} is not the pinned seed commit ${seed} at arm ${arm} start (task ${taskId}) — ` +
        `both arms run from identical seeds`
    );
  }
  const st = git(repo, ["status", "--porcelain"]);
  if (st.code !== 0) refuse(`git status failed in ${repo}: ${st.err}`);
  if (st.out !== "") {
    const paths = st.out.split("\n").map((l) => l.trim());
    refuse(
      `the work tree is DIRTY at arm ${arm} start (task ${taskId}), ${paths.length} path(s): ${paths.join("; ")} — ` +
        `an arm never starts on a moving tree`
    );
  }
  return { head: head.out, clean: true };
}

function cmdArmStart(opt) {
  for (const k of ["repo", "seed", "arm", "task"]) if (!opt[k]) refuse(`arm-start needs --${k}`);
  if (opt.arm !== "A" && opt.arm !== "B") refuse("arm-start needs --arm A|B");
  armStartCheck(opt.repo, opt.seed, opt.arm, opt.task);
  process.stdout.write(`arm_start: OK\ntask_id: ${opt.task}\narm: ${opt.arm}\nhead: ${opt.seed}\ntree: clean\n`);
  return 0;
}

function resetToSeed(repo, seed) {
  const r1 = git(repo, ["reset", "--hard", seed]);
  if (r1.code !== 0) refuse(`git reset --hard ${seed} failed in ${repo}: ${r1.err}`);
  const r2 = git(repo, ["clean", "-fdx"]);
  if (r2.code !== 0) refuse(`git clean -fdx failed in ${repo}: ${r2.err}`);
}

// -------------------------------------------------------------- run-pair ----

function cmdRunPair(opt) {
  for (const k of ["registry", "pair", "repo", "out"]) if (!opt[k]) refuse(`run-pair needs --${k}`);
  const reg = readJson(opt.registry, "registry");
  const pair = readJson(opt.pair, "pair record");
  const seed = reg.frozen.pinned_seed_commit;
  const repo = path.resolve(opt.repo);
  const out = path.resolve(opt.out);
  fs.mkdirSync(out, { recursive: true });

  const rec = [];
  const write = (name) => fs.writeFileSync(path.join(out, name), rec.join("\n") + "\n");
  rec.push(`experiment: ${EXPERIMENT}`);
  rec.push(`harness_version: ${HARNESS_VERSION}`);
  rec.push(`task_id: ${pair.task_id}`);

  let task;
  try {
    task = assertMatched(reg, pair);
  } catch (e) {
    rec.push("invariance_assertion: REFUSED");
    rec.push(`refusal: ${e.message}`);
    write("pair_record.REFUSED.txt");
    throw e;
  }
  const order = task.arm_order;
  rec.push(`arm_order: ${order.join(",")}`);
  rec.push(`arm_order_rule: ${reg.arm_order_rule.id}`);
  rec.push(`arm_order_rule_statement: ${reg.arm_order_rule.statement}`);
  rec.push(`arm_order_derivation: ${reg.arm_order_rule.derivation}`);
  rec.push("invariance_assertion: PASS");
  rec.push(`invariance_fields_asserted: ${INVARIANT_FIELDS.map((f) => f.name).join(",")}`);
  rec.push(`pinned_seed_commit: ${seed}`);
  rec.push(`repo: ${repo}`);
  rec.push(`reset_between_arms: ${opt.resetBetweenArms ? "performed" : "not requested"}`);
  rec.push(`exec_cmd_supplied: ${opt.execCmd ? "yes" : "no"}`);

  order.forEach((arm, i) => {
    const lc = arm.toLowerCase();
    if (i > 0 && opt.resetBetweenArms) {
      resetToSeed(repo, seed);
      rec.push(`reset_before_arm_${lc}: performed (tree returned to the pinned seed)`);
    }
    try {
      armStartCheck(repo, seed, arm, pair.task_id);
    } catch (e) {
      rec.push(`arm_${lc}_start: REFUSED`);
      rec.push(`refusal: ${e.message}`);
      write("pair_record.REFUSED.txt");
      throw e;
    }
    rec.push(`arm_${lc}_start: clean at the pinned seed`);
    if (opt.execCmd) {
      const armOut = path.join(out, `arm-${arm}`);
      fs.mkdirSync(armOut, { recursive: true });
      const r = spawnSync("bash", ["-c", opt.execCmd], {
        cwd: repo,
        encoding: "utf8",
        env: {
          ...process.env,
          EXP0004_ARM: arm,
          EXP0004_TASK: pair.task_id,
          EXP0004_REPO: repo,
          EXP0004_OUTDIR: armOut,
          EXP0004_SEED: seed,
        },
      });
      fs.writeFileSync(path.join(armOut, "stdout.txt"), r.stdout || "");
      fs.writeFileSync(path.join(armOut, "stderr.txt"), r.stderr || "");
      rec.push(`arm_${lc}_exec_exit: ${r.status === null ? UNKNOWN : r.status}`);
    } else {
      // An unknown is not a zero: no worker ran, so no exit status exists.
      rec.push(`arm_${lc}_exec_exit: ${UNKNOWN}`);
    }
  });

  if (opt.resetBetweenArms) {
    resetToSeed(repo, seed);
    rec.push("reset_after_pair: performed (tree returned to the pinned seed)");
  }
  write("pair_record.txt");
  process.stdout.write(`pair_complete: ${pair.task_id} (${order.join(",")})\n`);
  return 0;
}

// ------------------------------------------------------------- aggregate ----

const LEDGER = "CONFOUNDED_LEDGER.txt";

export function amendment2Check(bRec) {
  const sc = bRec.arm_b_starting_context;
  if (!sc) return { ok: false, reason: "result_confounded: arm B carries no starting-context record, so AMENDMENT 2 cannot be verified" };
  if (sc.broad_context_included === true) {
    return {
      ok: false,
      reason:
        "result_confounded: arm B received the broad-context payload AND the capsule — AMENDMENT 2 requires the capsule to REPLACE broad context, not supplement it",
    };
  }
  if (sc.broad_context_included === null) {
    return { ok: false, reason: "result_confounded: broad_context_included is unmeasured ('-'), so AMENDMENT 2's mechanical check is unverifiable" };
  }
  const start = fieldValue(bRec, "starting_context_bytes");
  const cap = sc.capsule_bytes.value;
  const pre = sc.prefix_bytes.value;
  if (start === UNKNOWN || cap === UNKNOWN || pre === UNKNOWN) {
    return { ok: false, reason: "result_confounded: starting/capsule/prefix bytes are not all measured, so AMENDMENT 2's mechanical check is unverifiable" };
  }
  if (start !== cap + pre) {
    return {
      ok: false,
      reason: `result_confounded: arm B's starting bytes ${start} != capsule ${cap} + prefix ${pre} — something other than the capsule and the immutable prefix was delivered (AMENDMENT 2)`,
    };
  }
  return { ok: true, reason: null };
}

const AGG_FIELDS = [
  "starting_context_bytes",
  "expansion_bytes",
  "total_tokens",
  "uncached_tokens",
  "time_to_first_meaningful_edit_s",
  "total_elapsed_s",
  "files_read",
  "search_operations",
  "context_expansions",
  "failed_hypotheses",
  "rework_rounds",
  "verifier_dispatches",
  "tests_run",
  "tests_passed",
  "acceptance_result",
  "regressions",
  "human_interventions",
];

function armSlice(rec) {
  const o = {};
  const tiers = {};
  for (const f of AGG_FIELDS) {
    o[f] = fieldValue(rec, f);
    tiers[f] = fieldTier(rec, f);
  }
  o.tiers = tiers;
  return o;
}

function cmdAggregate(opt) {
  for (const k of ["registry", "records", "out"]) if (!opt[k]) refuse(`aggregate needs --${k}`);
  const reg = readJson(opt.registry, "registry");
  const dir = path.resolve(opt.records);
  const ledgerPath = path.join(dir, LEDGER);
  const ledger = new Map();
  if (fs.existsSync(ledgerPath)) {
    for (const line of fs.readFileSync(ledgerPath, "utf8").split("\n")) {
      if (!line.trim()) continue;
      const [id, ...rest] = line.split("\t");
      ledger.set(id, rest.join("\t"));
    }
  }

  const tasks = [];
  const excluded = [];
  const newlyConfounded = [];
  for (const t of reg.tasks) {
    const fa = path.join(dir, `${t.id}.A.json`);
    const fb = path.join(dir, `${t.id}.B.json`);
    for (const [f, arm] of [[fa, "A"], [fb, "B"]]) {
      if (!fs.existsSync(f)) {
        refuse(`task ${t.id} has no arm-${arm} record at ${f} — a matched pair needs both arms; a half pair is not aggregated`);
      }
    }
    const a = readRecord(fa);
    const b = readRecord(fb);
    if (a.task_id !== t.id || b.task_id !== t.id) refuse(`task ${t.id}: a record's task_id does not match its filename`);

    if (ledger.has(t.id)) {
      excluded.push({
        task_id: t.id,
        reason: `confounded_ledger: permanently excluded — ${ledger.get(t.id)} (AMENDMENT 2: never repaired, never re-run into the aggregate)`,
      });
      continue;
    }
    const chk = amendment2Check(b);
    if (!chk.ok) {
      excluded.push({ task_id: t.id, reason: chk.reason });
      newlyConfounded.push([t.id, chk.reason]);
      continue;
    }
    tasks.push({ task_id: t.id, shape: t.shape, arm_order: t.arm_order, a: armSlice(a), b: armSlice(b) });
  }

  if (newlyConfounded.length) {
    const add = newlyConfounded.map(([id, reason]) => `${id}\t${reason}`).join("\n") + "\n";
    fs.appendFileSync(ledgerPath, add);
  }

  const agg = {
    experiment: EXPERIMENT,
    harness_version: HARNESS_VERSION,
    arm_order_rule: reg.arm_order_rule,
    eligibility: reg.eligibility,
    capsule_signal: reg.eligibility && reg.eligibility.capsule_signal ? reg.eligibility.capsule_signal : null,
    harness_confounds: opt.confounds || [],
    n_registered: reg.tasks.length,
    n_admitted: tasks.length,
    n_excluded_confounded: excluded.length,
    excluded,
    tasks,
  };
  fs.writeFileSync(opt.out, JSON.stringify(agg, null, 2) + "\n");
  process.stdout.write(
    `aggregated: n_registered=${agg.n_registered} n_admitted=${agg.n_admitted} n_excluded_confounded=${agg.n_excluded_confounded}\n`
  );
  for (const e of excluded) process.stdout.write(`excluded: ${e.task_id} — ${e.reason}\n`);
  return 0;
}

// -------------------------------------------------------------------- CLI ---

const USAGE =
  "usage: run-exp0004.mjs register       --tasks <f> --eligibility <f> --out <f>\n" +
  "       run-exp0004.mjs exclusions\n" +
  "       run-exp0004.mjs plan           --registry <f>\n" +
  "       run-exp0004.mjs assert-matched --registry <f> --pair <f>\n" +
  "       run-exp0004.mjs arm-start      --repo <d> --seed <sha> --arm A|B --task <id>\n" +
  "       run-exp0004.mjs run-pair       --registry <f> --pair <f> --repo <d> --out <d> [--exec-cmd <cmd>] [--reset-between-arms]\n" +
  "       run-exp0004.mjs aggregate      --registry <f> --records <d> --out <f> [--confound <text>]\n";

function cli(argv) {
  const cmd = argv[0];
  const rest = argv.slice(1);
  const opt = { confounds: [] };
  for (let i = 0; i < rest.length; i++) {
    const k = rest[i];
    switch (k) {
      case "--tasks": opt.tasks = rest[++i]; break;
      case "--eligibility": opt.eligibility = rest[++i]; break;
      case "--out": opt.out = rest[++i]; break;
      case "--registry": opt.registry = rest[++i]; break;
      case "--pair": opt.pair = rest[++i]; break;
      case "--repo": opt.repo = rest[++i]; break;
      case "--seed": opt.seed = rest[++i]; break;
      case "--arm": opt.arm = rest[++i]; break;
      case "--task": opt.task = rest[++i]; break;
      case "--records": opt.records = rest[++i]; break;
      case "--exec-cmd": opt.execCmd = rest[++i]; break;
      case "--reset-between-arms": opt.resetBetweenArms = true; break;
      case "--confound": opt.confounds.push(rest[++i]); break;
      case "--prereg": opt.prereg = rest[++i]; break;
      default:
        process.stderr.write(`run-exp0004: unknown option: ${k}\n${USAGE}`);
        return 2;
    }
  }
  try {
    switch (cmd) {
      case "register": return cmdRegister(opt);
      case "exclusions": return cmdExclusions();
      case "plan": return cmdPlan(opt);
      case "assert-matched": return cmdAssertMatched(opt);
      case "arm-start": return cmdArmStart(opt);
      case "run-pair": return cmdRunPair(opt);
      case "aggregate": return cmdAggregate(opt);
      case undefined:
      case "-h":
      case "--help":
        process.stdout.write(USAGE);
        return 0;
      default:
        refuse(`unknown subcommand: ${cmd}`);
    }
  } catch (e) {
    process.stderr.write(`run-exp0004: REFUSED — ${e.message}\n`);
    return 2;
  }
  return 2;
}

const invoked =
  process.argv[1] && fs.realpathSync(process.argv[1]) === fs.realpathSync(fileURLToPath(import.meta.url));
if (invoked) process.exit(cli(process.argv.slice(2)));
