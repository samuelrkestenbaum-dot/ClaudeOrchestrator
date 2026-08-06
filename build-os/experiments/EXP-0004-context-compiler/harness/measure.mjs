#!/usr/bin/env node
// EXP-0004 — THE PER-TASK-PER-ARM MEASUREMENT RECORD.
//
//   node measure.mjs template --task <id> --arm A|B [--out <file>]
//   node measure.mjs validate --record <file>
//   node measure.mjs render   --record <file>
//
// One record per task per arm. Seventeen fields, each carrying a TIER from the
// adapter contract's single vocabulary (build-os/adapters/ADAPTER_CONTRACT.md):
//
//   EXACT       — counted by the measuring surface itself.
//   ESTIMATE    — a labeled derived proxy, never billing truth.
//   CLOSE-TIME  — reconcilable from provider telemetry after the run.
//   UNAVAILABLE — not visible on this surface; admitted, never guessed.
//
// THE RULE THAT GOVERNS EVERY FIELD: an unknown is a '-' admission, NEVER a
// zero. A zero is a measurement that came back zero; a '-' is a measurement
// that did not happen. Conflating them is how a harness manufactures a result,
// so this validator REFUSES (exit 2) on:
//   * tier UNAVAILABLE carrying any value other than '-'  (the zero-for-unknown lie)
//   * value '-' carrying any tier other than UNAVAILABLE  (a tier above what was measured)
//   * a tier outside the four-word vocabulary
//   * a missing or unknown field
//
// AMENDMENT 2 (the capsule REPLACES broad context) is measurable only if arm B
// records what its starting context was made of, so an arm-B record carries
// `arm_b_starting_context` {capsule_bytes, prefix_bytes, broad_context_included}
// and an arm-A record must not carry it. The check itself runs in
// run-exp0004.mjs at aggregate time, where a failure becomes result_confounded.
//
// Invoke via node; this file is deliberately NOT executable.
// Exit: 0 fine; 2 refusal. Dependencies: node stdlib only.

import fs from "node:fs";
import { fileURLToPath } from "node:url";

export const EXPERIMENT = "EXP-0004";
export const TIERS = ["EXACT", "ESTIMATE", "CLOSE-TIME", "UNAVAILABLE"];
export const UNKNOWN = "-";

// The measured surface, in record order. `kind` fixes what a measured value
// may be; every field may always be the '-' admission instead.
export const FIELDS = [
  { name: "starting_context_bytes", kind: "number" },
  { name: "expansion_bytes", kind: "number" },
  { name: "total_tokens", kind: "number" },
  { name: "uncached_tokens", kind: "number" },
  { name: "time_to_first_meaningful_edit_s", kind: "number" },
  { name: "total_elapsed_s", kind: "number" },
  { name: "files_read", kind: "number" },
  { name: "search_operations", kind: "number" },
  { name: "context_expansions", kind: "number" },
  { name: "failed_hypotheses", kind: "number" },
  { name: "rework_rounds", kind: "number" },
  { name: "verifier_dispatches", kind: "number" },
  { name: "tests_run", kind: "number" },
  { name: "tests_passed", kind: "number" },
  { name: "acceptance_result", kind: "enum", enum: ["accepted", "rejected"] },
  { name: "regressions", kind: "number" },
  { name: "human_interventions", kind: "number" },
];

export const FIELD_NAMES = FIELDS.map((f) => f.name);

class Refusal extends Error {}
const refuse = (m) => {
  throw new Refusal(m);
};

// ------------------------------------------------------------- validation --

function checkCell(where, name, cell) {
  if (cell === null || typeof cell !== "object" || Array.isArray(cell)) {
    refuse(`${where}: field '${name}' must be an object { "value": ..., "tier": ... }`);
  }
  const extra = Object.keys(cell).filter((k) => k !== "value" && k !== "tier");
  if (extra.length) refuse(`${where}: field '${name}' carries unknown key(s): ${extra.join(", ")}`);
  if (!("tier" in cell)) refuse(`${where}: field '${name}' has no tier — every value is tier-labeled`);
  if (!TIERS.includes(cell.tier)) {
    refuse(
      `${where}: field '${name}' claims tier '${cell.tier}', which is not in the adapter contract's vocabulary (${TIERS.join(" | ")})`
    );
  }
  if (!("value" in cell)) refuse(`${where}: field '${name}' has no value`);
  const v = cell.value;
  if (cell.tier === "UNAVAILABLE" && v !== UNKNOWN) {
    refuse(
      `${where}: field '${name}' is tier UNAVAILABLE but carries value ${JSON.stringify(v)} — an unknown is a '-' admission, never a zero`
    );
  }
  if (v === UNKNOWN && cell.tier !== "UNAVAILABLE") {
    refuse(
      `${where}: field '${name}' admits '-' but claims tier '${cell.tier}' — no tier above what was measured`
    );
  }
  return v;
}

/**
 * Validate one measurement record. Throws a Refusal naming the offending
 * field. Returns the record on success.
 */
export function validateRecord(rec, where = "record") {
  if (rec === null || typeof rec !== "object" || Array.isArray(rec)) refuse(`${where}: not a JSON object`);
  if (rec.experiment !== EXPERIMENT) {
    refuse(`${where}: experiment is ${JSON.stringify(rec.experiment)}, expected "${EXPERIMENT}"`);
  }
  if (typeof rec.task_id !== "string" || !rec.task_id) refuse(`${where}: task_id is missing`);
  if (rec.arm !== "A" && rec.arm !== "B") refuse(`${where}: arm is ${JSON.stringify(rec.arm)}, expected "A" or "B"`);
  if (rec.fields === null || typeof rec.fields !== "object") refuse(`${where}: fields block is missing`);

  for (const spec of FIELDS) {
    if (!(spec.name in rec.fields)) refuse(`${where}: missing required field '${spec.name}'`);
    const v = checkCell(where, spec.name, rec.fields[spec.name]);
    if (v === UNKNOWN) continue;
    if (spec.kind === "number") {
      if (typeof v !== "number" || !Number.isFinite(v) || v < 0) {
        refuse(`${where}: field '${spec.name}' must be a finite non-negative number or '-', got ${JSON.stringify(v)}`);
      }
    } else if (spec.kind === "enum") {
      if (!spec.enum.includes(v)) {
        refuse(`${where}: field '${spec.name}' must be one of ${spec.enum.join(" | ")} or '-', got ${JSON.stringify(v)}`);
      }
    }
  }
  const unknownFields = Object.keys(rec.fields).filter((k) => !FIELD_NAMES.includes(k));
  if (unknownFields.length) refuse(`${where}: unknown field(s) in the record: ${unknownFields.join(", ")}`);

  const sc = rec.arm_b_starting_context;
  if (rec.arm === "B") {
    if (sc === undefined) {
      refuse(`${where}: an arm-B record must carry arm_b_starting_context (AMENDMENT 2 is measured, not assumed)`);
    }
    if (sc === null || typeof sc !== "object") refuse(`${where}: arm_b_starting_context must be an object`);
    checkCell(where, "arm_b_starting_context.capsule_bytes", sc.capsule_bytes);
    checkCell(where, "arm_b_starting_context.prefix_bytes", sc.prefix_bytes);
    if (!("broad_context_included" in sc)) {
      refuse(`${where}: arm_b_starting_context.broad_context_included is missing (true | false | null for unmeasured)`);
    }
    const b = sc.broad_context_included;
    if (b !== true && b !== false && b !== null) {
      refuse(`${where}: arm_b_starting_context.broad_context_included must be true, false, or null (unmeasured)`);
    }
  } else if (sc !== undefined) {
    refuse(`${where}: an arm-A record must NOT carry arm_b_starting_context — arm A is unchanged by the experiment`);
  }
  return rec;
}

export function readRecord(file) {
  let raw;
  try {
    raw = fs.readFileSync(file, "utf8");
  } catch {
    refuse(`record not readable: ${file}`);
  }
  let rec;
  try {
    rec = JSON.parse(raw);
  } catch (e) {
    refuse(`record is not valid JSON (${file}): ${e.message}`);
  }
  return validateRecord(rec, file);
}

/** The value of a field, or '-' when unmeasured. Never coerces to a number. */
export function fieldValue(rec, name) {
  const cell = rec.fields[name];
  return cell ? cell.value : UNKNOWN;
}

export function fieldTier(rec, name) {
  const cell = rec.fields[name];
  return cell ? cell.tier : "UNAVAILABLE";
}

// -------------------------------------------------------------- rendering --

const cell = (value, tier) => `{ "value": ${JSON.stringify(value)}, "tier": ${JSON.stringify(tier)} }`;

/** One field per line, so a record is diffable and patchable by hand. */
export function stringifyRecord(rec) {
  const L = [];
  L.push("{");
  L.push(`  "experiment": ${JSON.stringify(rec.experiment)},`);
  L.push(`  "task_id": ${JSON.stringify(rec.task_id)},`);
  L.push(`  "arm": ${JSON.stringify(rec.arm)},`);
  L.push(`  "fields": {`);
  const lines = FIELDS.map((f) => {
    const c = rec.fields[f.name];
    return `    ${JSON.stringify(f.name)}: ${cell(c.value, c.tier)}`;
  });
  L.push(lines.join(",\n"));
  const sc = rec.arm_b_starting_context;
  if (sc) {
    L.push("  },");
    L.push(`  "arm_b_starting_context": {`);
    L.push(`    "capsule_bytes": ${cell(sc.capsule_bytes.value, sc.capsule_bytes.tier)},`);
    L.push(`    "prefix_bytes": ${cell(sc.prefix_bytes.value, sc.prefix_bytes.tier)},`);
    L.push(`    "broad_context_included": ${JSON.stringify(sc.broad_context_included)}`);
    L.push("  }");
  } else {
    L.push("  }");
  }
  L.push("}");
  return L.join("\n") + "\n";
}

export function templateRecord(taskId, arm) {
  const fields = {};
  for (const f of FIELDS) fields[f.name] = { value: UNKNOWN, tier: "UNAVAILABLE" };
  const rec = { experiment: EXPERIMENT, task_id: taskId, arm, fields };
  if (arm === "B") {
    rec.arm_b_starting_context = {
      capsule_bytes: { value: UNKNOWN, tier: "UNAVAILABLE" },
      prefix_bytes: { value: UNKNOWN, tier: "UNAVAILABLE" },
      broad_context_included: null,
    };
  }
  return rec;
}

const pad = (s) => String(s).padEnd(34, " ");
const num = (v) => String(v).padStart(12, " ");

export function renderRecord(rec) {
  const L = [];
  L.push(`measure — ${rec.experiment} ${rec.task_id} arm ${rec.arm}`);
  L.push(`tiers: ${TIERS.join(" | ")}; '-' is an admission that the field was not measured`);
  L.push("");
  for (const f of FIELDS) {
    const c = rec.fields[f.name];
    L.push(`${pad(f.name)}${num(c.value)}   ${c.tier}`);
  }
  const sc = rec.arm_b_starting_context;
  if (sc) {
    L.push("");
    L.push("== AMENDMENT 2 — arm B's starting context (the capsule REPLACES broad context) ==");
    L.push(`${pad("capsule_bytes")}${num(sc.capsule_bytes.value)}   ${sc.capsule_bytes.tier}`);
    L.push(`${pad("prefix_bytes")}${num(sc.prefix_bytes.value)}   ${sc.prefix_bytes.tier}`);
    L.push(
      `${pad("broad_context_included")}${num(sc.broad_context_included === null ? UNKNOWN : sc.broad_context_included)}   ${
        sc.broad_context_included === null ? "UNAVAILABLE" : "EXACT"
      }`
    );
  }
  return L.join("\n") + "\n";
}

// -------------------------------------------------------------------- CLI --

const USAGE =
  "usage: measure.mjs template --task <id> --arm A|B [--out <file>]\n" +
  "       measure.mjs validate --record <file>\n" +
  "       measure.mjs render   --record <file>\n";

function cli(argv) {
  const cmd = argv[0];
  const rest = argv.slice(1);
  const opt = {};
  for (let i = 0; i < rest.length; i++) {
    const k = rest[i];
    if (k === "--task") opt.task = rest[++i];
    else if (k === "--arm") opt.arm = rest[++i];
    else if (k === "--out") opt.out = rest[++i];
    else if (k === "--record") opt.record = rest[++i];
    else {
      process.stderr.write(`measure: unknown option: ${k}\n${USAGE}`);
      return 2;
    }
  }
  try {
    if (cmd === "template") {
      if (!opt.task) refuse("template needs --task <id>");
      if (opt.arm !== "A" && opt.arm !== "B") refuse("template needs --arm A|B");
      const text = stringifyRecord(templateRecord(opt.task, opt.arm));
      if (opt.out) fs.writeFileSync(opt.out, text);
      else process.stdout.write(text);
      return 0;
    }
    if (cmd === "validate") {
      if (!opt.record) refuse("validate needs --record <file>");
      readRecord(opt.record);
      process.stdout.write(`record_valid: ${opt.record}\n`);
      return 0;
    }
    if (cmd === "render") {
      if (!opt.record) refuse("render needs --record <file>");
      process.stdout.write(renderRecord(readRecord(opt.record)));
      return 0;
    }
    if (cmd === "-h" || cmd === "--help" || cmd === undefined) {
      process.stdout.write(USAGE);
      return 0;
    }
    refuse(`unknown subcommand: ${cmd}`);
  } catch (e) {
    process.stderr.write(`measure: REFUSED — ${e.message}\n`);
    return 2;
  }
  return 2;
}

const invoked =
  process.argv[1] && fs.realpathSync(process.argv[1]) === fs.realpathSync(fileURLToPath(import.meta.url));
if (invoked) process.exit(cli(process.argv.slice(2)));
