// EXP-0004 BLINDING — THE SEALED CONDITION MAPPING.
//
//   node seal-mapping.mjs rules
//   node seal-mapping.mjs seal --rule <id> --salt <s> --tasks a,b,c [--task d] --out <dir>
//   node seal-mapping.mjs verify    --sealed <f> --digest <f>
//   node seal-mapping.mjs reproduce --sealed <f>
//   node seal-mapping.mjs label     --sealed <f> --task <id> --arm A|B
//
// WHAT IS SEALED AND WHY. EXP-0001/2/3 were credible because the mapping from
// analysis labels to execution conditions was fixed and its sha256 committed
// BEFORE anyone looked at the numbers. EXP-0004 has no blinding at all, at the
// exact point where the incentive to see a favourable result is strongest. This
// tool produces the commitment: `mapping.sealed.json` (WITHHELD from the
// adjudicator and the analyst) and `mapping.sha256` (COMMITTED before the run).
//
// THE ASSIGNMENT IS DERIVED, NEVER SAMPLED. This codebase forbids sampled
// randomness and wall-clock reads in harnesses, for a stronger reason than
// style: a sampled
// assignment cannot be re-checked by anyone afterwards, so it is a promise
// rather than a proof. Here the assignment is a pure function of a DECLARED
// SALT and a REGISTERED RULE, both recorded inside the sealed artifact, so a
// third party holding the artifact can re-derive every assignment and confirm
// nothing was chosen after the data existed. `reproduce` runs exactly that
// check and REFUSES a seal whose assignments no longer follow its own rule.
//
// TWO RULES ARE REGISTERED, AND THEY ARE NOT INTERCHANGEABLE:
//
//   experiment-salt-parity  ONE bit for the whole experiment. `Arm X` means the
//     same execution condition in every task, so medians across tasks compare a
//     coherent condition. THIS IS THE RULE AN AGGREGATE ANALYSIS REQUIRES.
//   task-salt-parity        A fresh bit per task. Stronger per-unit opacity, but
//     `Arm X` then denotes a MIXTURE of conditions across tasks and any median
//     over it compares nothing. It is sealable — per-unit adjudication is a real
//     use — but the artifact records `aggregate_analysis_valid: false` and the
//     analysis tools refuse to aggregate over it.
//
// Invoke via node; this file is deliberately NOT executable (EXP-0003's census
// asserts zero executables under build-os/experiments/).
// Exit: 0 fine; 2 refusal. Dependencies: node stdlib only.

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const EXPERIMENT = "EXP-0004";
export const LABEL_X = "Arm X";
export const LABEL_Y = "Arm Y";
export const LABELS = [LABEL_X, LABEL_Y];
export const ARMS = ["A", "B"];
export const SEALED_NAME = "mapping.sealed.json";
export const DIGEST_NAME = "mapping.sha256";

export const RULES = {
  "experiment-salt-parity": {
    scope: "experiment",
    aggregate_analysis_valid: true,
    text:
      "EXPERIMENT-SCOPE PARITY. Let S be the declared salt. Compute " +
      "h = sha256(S + '|' + 'EXP-0004') and take p = (first byte of h) & 1. " +
      "If p = 0 then execution condition A is labelled 'Arm X' and condition B is labelled 'Arm Y'. " +
      "If p = 1 then condition A is labelled 'Arm Y' and condition B is labelled 'Arm X'. " +
      "The same labelling applies to EVERY task, so a label denotes one coherent condition throughout. " +
      "The unit id of (task T, label L) is the first 16 hex characters of sha256(S + '|unit|' + T + '|' + L). " +
      "No random number is sampled and no clock is read: given S and the task list, every assignment above " +
      "is recomputable by anyone, which is what makes the committed digest a proof rather than a promise.",
  },
  "task-salt-parity": {
    scope: "task",
    aggregate_analysis_valid: false,
    text:
      "TASK-SCOPE PARITY. Let S be the declared salt. For each task T compute " +
      "h = sha256(S + '|' + 'EXP-0004' + '|' + T) and take p = (first byte of h) & 1. " +
      "If p = 0 then condition A is labelled 'Arm X' for that task and condition B is labelled 'Arm Y'. " +
      "If p = 1 the labels are exchanged FOR THAT TASK ONLY. " +
      "The unit id of (task T, label L) is the first 16 hex characters of sha256(S + '|unit|' + T + '|' + L). " +
      "Because the labelling changes between tasks, 'Arm X' denotes a MIXTURE of execution conditions across " +
      "the task set and no median taken over it compares a single condition. This rule is therefore recorded " +
      "with aggregate_analysis_valid = false and the analysis tools refuse to aggregate over it.",
  },
};

class Refusal extends Error {}
const refuse = (m) => {
  throw new Refusal(m);
};

export const sha256hex = (buf) => crypto.createHash("sha256").update(buf).digest("hex");

/** Parity of the first byte of sha256(input). Derived, never sampled. */
export function parityOf(input) {
  return parseInt(sha256hex(input).slice(0, 2), 16) & 1;
}

export function labelMapFor(salt, taskId, scope) {
  const input = scope === "task" ? `${salt}|${EXPERIMENT}|${taskId}` : `${salt}|${EXPERIMENT}`;
  const p = parityOf(input);
  return p === 0 ? { A: LABEL_X, B: LABEL_Y } : { A: LABEL_Y, B: LABEL_X };
}

export function unitIdOf(salt, taskId, label) {
  return sha256hex(`${salt}|unit|${taskId}|${label}`).slice(0, 16);
}

/**
 * Build the sealed mapping. Task order is CANONICALISED (sorted) so that the
 * artifact — and therefore the committed digest — does not depend on the order
 * the caller happened to list the tasks in.
 */
export function buildMapping({ rule_id, salt, task_ids }) {
  const rule = RULES[rule_id];
  if (!rule) {
    refuse(
      `unregistered rule '${rule_id}'. The assignment rule must be REGISTERED before the run, not invented at seal time. ` +
        `Registered rules: ${Object.keys(RULES).join(", ")}`
    );
  }
  if (typeof salt !== "string" || salt.length === 0) {
    refuse("a declared salt is required — the assignment is derived from it, so an empty salt derives nothing");
  }
  if (!Array.isArray(task_ids) || task_ids.length === 0) refuse("at least one task id is required");
  const seen = new Set();
  for (const t of task_ids) {
    if (typeof t !== "string" || !t) refuse("every task id must be a non-empty string");
    if (seen.has(t)) refuse(`duplicate task id '${t}' — a task cannot be assigned twice`);
    seen.add(t);
  }
  const tasks = [...task_ids].sort();

  const scope = rule.scope;
  const perTask = tasks.map((t) => ({ task_id: t, label_map: labelMapFor(salt, t, scope) }));

  const units = [];
  for (const { task_id, label_map } of perTask) {
    for (const arm of ARMS) {
      const label = label_map[arm];
      units.push({ task_id, arm, label, unit_id: unitIdOf(salt, task_id, label) });
    }
  }

  const sealed = {
    experiment: EXPERIMENT,
    artifact: SEALED_NAME,
    sealed_before: "any measurement was analysed; the digest in mapping.sha256 is committed before the run",
    rule_id,
    rule_scope: scope,
    aggregate_analysis_valid: rule.aggregate_analysis_valid,
    rule_text: rule.text,
    salt,
    task_ids: tasks,
    label_map: scope === "experiment" ? perTask[0].label_map : null,
    per_task_label_map: scope === "task" ? perTask : null,
    units,
    withheld_from: [
      "the acceptance adjudicator",
      "the comparative analyst",
    ],
    reveal_precondition:
      "the freeze snapshot validates, the anonymous provisional verdict exists, and this file's sha256 equals the committed digest",
  };
  return sealed;
}

export const serialize = (obj) => JSON.stringify(obj, null, 2) + "\n";

export function readSealed(file) {
  let raw;
  try {
    raw = fs.readFileSync(file, "utf8");
  } catch {
    refuse(`sealed mapping not readable: ${file}`);
  }
  let j;
  try {
    j = JSON.parse(raw);
  } catch (e) {
    refuse(`sealed mapping is not valid JSON (${file}): ${e.message}`);
  }
  if (j.experiment !== EXPERIMENT) refuse(`sealed mapping is for ${JSON.stringify(j.experiment)}, expected ${EXPERIMENT}`);
  if (!RULES[j.rule_id]) refuse(`sealed mapping cites unregistered rule '${j.rule_id}'`);
  if (!Array.isArray(j.units) || j.units.length === 0) refuse("sealed mapping carries no units");
  return { sealed: j, raw };
}

/** Re-derive every assignment from the RECORDED rule and compare. */
export function reproduceCheck(sealed) {
  const rebuilt = buildMapping({ rule_id: sealed.rule_id, salt: sealed.salt, task_ids: sealed.task_ids });
  const problems = [];
  if (serialize(rebuilt.units) !== serialize(sealed.units)) {
    for (const u of rebuilt.units) {
      const got = sealed.units.find((x) => x.task_id === u.task_id && x.arm === u.arm);
      if (!got) problems.push(`unit (${u.task_id}, condition ${u.arm}) is absent from the seal`);
      else if (got.label !== u.label) {
        problems.push(`unit (${u.task_id}, condition ${u.arm}) is labelled '${got.label}' but the recorded rule derives '${u.label}'`);
      } else if (got.unit_id !== u.unit_id) {
        problems.push(`unit (${u.task_id}, condition ${u.arm}) has unit id '${got.unit_id}' but the recorded rule derives '${u.unit_id}'`);
      }
    }
    if (problems.length === 0) problems.push("the unit list differs from the one the recorded rule derives");
  }
  if (serialize(rebuilt.label_map) !== serialize(sealed.label_map)) {
    problems.push("the experiment-scope label map differs from the one the recorded rule derives");
  }
  if (serialize(rebuilt.per_task_label_map) !== serialize(sealed.per_task_label_map)) {
    problems.push("the per-task label map differs from the one the recorded rule derives");
  }
  if (rebuilt.aggregate_analysis_valid !== sealed.aggregate_analysis_valid) {
    problems.push("aggregate_analysis_valid does not match the registered rule");
  }
  return problems;
}

export function readCommittedDigest(file) {
  let raw;
  try {
    raw = fs.readFileSync(file, "utf8");
  } catch {
    refuse(`committed digest not readable: ${file}`);
  }
  const m = raw.trim().match(/^([0-9a-f]{64})\b/);
  if (!m) refuse(`committed digest file does not begin with a sha256 hex digest: ${file}`);
  return m[1];
}

/** The label a (task, condition) pair carries, or null. */
export function labelOf(sealed, taskId, arm) {
  const u = sealed.units.find((x) => x.task_id === taskId && x.arm === arm);
  return u ? u.label : null;
}

// -------------------------------------------------------------------- CLI --

const USAGE =
  "usage: seal-mapping.mjs rules\n" +
  "       seal-mapping.mjs seal --rule <id> --salt <s> --tasks a,b,c [--task d] --out <dir>\n" +
  "       seal-mapping.mjs verify    --sealed <f> --digest <f>\n" +
  "       seal-mapping.mjs reproduce --sealed <f>\n" +
  "       seal-mapping.mjs label     --sealed <f> --task <id> --arm A|B\n";

function cli(argv) {
  const cmd = argv[0];
  const rest = argv.slice(1);
  const opt = { tasks: [] };
  for (let i = 0; i < rest.length; i++) {
    const k = rest[i];
    if (k === "--rule") opt.rule = rest[++i];
    else if (k === "--salt") opt.salt = rest[++i];
    else if (k === "--tasks") opt.tasks.push(...String(rest[++i] || "").split(",").filter(Boolean));
    else if (k === "--task") opt.tasks.push(rest[++i]);
    else if (k === "--out") opt.out = rest[++i];
    else if (k === "--sealed") opt.sealed = rest[++i];
    else if (k === "--digest") opt.digest = rest[++i];
    else if (k === "--arm") opt.arm = rest[++i];
    else {
      process.stderr.write(`seal-mapping: unknown option: ${k}\n${USAGE}`);
      return 2;
    }
  }
  try {
    if (cmd === "rules") {
      for (const [id, r] of Object.entries(RULES)) {
        process.stdout.write(`${id}  scope=${r.scope}  aggregate_analysis_valid=${r.aggregate_analysis_valid}\n  ${r.text}\n\n`);
      }
      return 0;
    }
    if (cmd === "seal") {
      if (!opt.out) refuse("seal needs --out <dir>");
      const sealed = buildMapping({ rule_id: opt.rule, salt: opt.salt, task_ids: opt.tasks });
      const text = serialize(sealed);
      fs.mkdirSync(opt.out, { recursive: true });
      const sealedPath = path.join(opt.out, SEALED_NAME);
      fs.writeFileSync(sealedPath, text);
      const digest = sha256hex(text);
      fs.writeFileSync(path.join(opt.out, DIGEST_NAME), `${digest}  ${SEALED_NAME}\n`);
      process.stdout.write(
        `sealed: ${sealedPath}\n` +
          `rule: ${sealed.rule_id} (scope ${sealed.rule_scope}, aggregate_analysis_valid ${sealed.aggregate_analysis_valid})\n` +
          `units: ${sealed.units.length}\n` +
          `COMMIT THIS DIGEST BEFORE THE RUN: ${digest}\n` +
          `WITHHOLD ${SEALED_NAME} from the adjudicator and the analyst until the reveal conditions are met.\n`
      );
      return 0;
    }
    if (cmd === "verify") {
      if (!opt.sealed || !opt.digest) refuse("verify needs --sealed <f> and --digest <f>");
      const { raw } = readSealed(opt.sealed);
      const actual = sha256hex(raw);
      const committed = readCommittedDigest(opt.digest);
      if (actual !== committed) {
        refuse(
          `SEAL BROKEN: the sealed mapping hashes to ${actual} but the committed digest is ${committed}. ` +
            `The mapping was changed after it was committed, so it is no longer a commitment.`
        );
      }
      process.stdout.write(`seal_intact: ${actual}\n`);
      return 0;
    }
    if (cmd === "reproduce") {
      if (!opt.sealed) refuse("reproduce needs --sealed <f>");
      const { sealed } = readSealed(opt.sealed);
      const problems = reproduceCheck(sealed);
      if (problems.length) {
        refuse(
          `the seal does not follow its own recorded rule '${sealed.rule_id}':\n  - ` + problems.join("\n  - ")
        );
      }
      process.stdout.write(
        `reproduced: every assignment re-derives from the recorded rule and salt\n` +
          `rule_id: ${sealed.rule_id}\nunits: ${sealed.units.length}\n`
      );
      return 0;
    }
    if (cmd === "label") {
      if (!opt.sealed) refuse("label needs --sealed <f>");
      if (!opt.arm || !ARMS.includes(opt.arm)) refuse("label needs --arm A|B");
      const { sealed } = readSealed(opt.sealed);
      const l = labelOf(sealed, opt.task, opt.arm);
      if (!l) refuse(`no unit for task ${JSON.stringify(opt.task)} condition ${opt.arm}`);
      process.stdout.write(`${l}\n`);
      return 0;
    }
    if (cmd === "-h" || cmd === "--help" || cmd === undefined) {
      process.stdout.write(USAGE);
      return 0;
    }
    refuse(`unknown subcommand: ${cmd}`);
  } catch (e) {
    process.stderr.write(`seal-mapping: REFUSED — ${e.message}\n`);
    return 2;
  }
  return 2;
}

const invoked =
  process.argv[1] && fs.realpathSync(process.argv[1]) === fs.realpathSync(fileURLToPath(import.meta.url));
if (invoked) process.exit(cli(process.argv.slice(2)));
