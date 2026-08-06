#!/usr/bin/env node
// Context Compiler — THE ACTIVATION BOUNDARY (task entry, EXP-0004).
//
//   activation.mjs check <activation.json>
//
// SHIPS INERT, AND THIS FILE IS WHERE THAT WORD IS ENFORCED. It ACTIVATES
// NOTHING. It starts no run, writes no state, wires no path, and holds no
// mutating capability whatsoever. It answers exactly one question — "may
// EXP-0004 begin under these conditions?" — and its only outputs are an exit
// code and a list of reasons. A tool that could both check and activate would
// eventually do the second because the first passed.
//
// WHY A BOUNDARY AT ALL. AB_PREREGISTRATION fixes arm behaviour BEFORE the data
// exists; that is the whole value of a preregistration, and it is worth exactly
// as much as the discipline that keeps a run from starting early. The seam
// ships inert precisely so that "was the compiler wired into a live routing
// path during the run?" is a DETECTABLE question rather than a recollection.
// This checker is where the preconditions stop being prose.
//
// ALL FIVE MUST HOLD. There is no majority and no strongest-link:
//
//   1. an ELIGIBLE REPOSITORY, on recorded evidence (AMENDMENT 1, measured by
//      the capability reporter and admitted by admit.mjs). This binds BOTH
//      arms: the amendment is a precondition on the RUN, not on arm B, because
//      arm A run on a repository arm B cannot see is not a comparison.
//   2. a PUBLISHED EXP-0004 FREEZE, with its sha256 — and the file's actual
//      digest must equal the declared one. A freeze that can still be edited is
//      not a freeze, and a task set chosen after seeing early results is the
//      post-hoc selection the preregistration exists to prevent.
//   3. an EXPLICIT EXPERIMENT ARM, A or B. Not inferred from the record, not
//      defaulted: an arm nobody wrote down is an arm that can be re-labelled
//      afterwards.
//   4. the EXACT REPOSITORY SEED COMMIT, and it must equal the commit the
//      starting-context record was taken at. "Arms run from identical seeds" is
//      a stop condition; an unpinned seed makes divergence undetectable.
//   5. a VALID STARTING-CONTEXT CONTRACT — a record from context-mode.mjs that
//      is not confounded and whose mode matches the arm (A/standard_context,
//      B/compiled_context).
//
// EVERY MISSING PRECONDITION IS NAMED INDIVIDUALLY. The check does not stop at
// the first failure. A refusal that names one problem produces a fix-and-retry
// loop that discovers the next problem one round at a time; the operator is
// owed the whole list at once.
//
// Dependencies: node stdlib only. No network. No environment variables are read.

import fs from "node:fs";
import crypto from "node:crypto";

const die = (msg) => { process.stderr.write(`activation: ${msg}\n`); process.exit(2); };

const USAGE = `usage: activation.mjs check <activation.json>

activation.json:
  { "eligibility_admission": "<admission.json from admit.mjs>",
    "freeze": { "path": "<freeze file>", "sha256": "<hex>" },
    "arm": "A" | "B",
    "seed_commit": "<40-hex repository commit>",
    "starting_context_record": "<record.json from context-mode.mjs>" }

exit: 0 every precondition holds | 2 REFUSED (each missing one named)
This tool checks. It activates nothing, writes nothing, and starts nothing.
`;

const ARM_MODE = { A: "standard_context", B: "compiled_context" };

const sha256File = (p) => crypto.createHash("sha256").update(fs.readFileSync(p)).digest("hex");
const isCommit = (s) => typeof s === "string" && /^[0-9a-f]{40}$/.test(s);

function loadJson(p) {
  try { return { ok: true, value: JSON.parse(fs.readFileSync(p, "utf8")) }; }
  catch (e) { return { ok: false, error: e.message }; }
}

function check(specPath) {
  const spec = loadJson(specPath);
  if (!spec.ok) die(`cannot read activation spec ${specPath}: ${spec.error}`);
  const s = spec.value || {};
  const missing = [];
  const met = [];
  const fail = (name, detail) => missing.push(`${name}: ${detail}`);
  const pass = (name, detail) => met.push(`${name}: ${detail}`);

  // ---- 1. an eligible repository, on recorded evidence.
  const NAME1 = "an eligible repository (recorded AMENDMENT 1 evidence)";
  let admission = null;
  if (typeof s.eligibility_admission !== "string" || !s.eligibility_admission) {
    fail(NAME1, "no eligibility_admission path was given. Eligibility is a measured precondition of the "
      + "RUN under AB_PREREGISTRATION AMENDMENT 1 and binds both arms; it is not assumed.");
  } else {
    const r = loadJson(s.eligibility_admission);
    if (!r.ok) fail(NAME1, `cannot read the admission record ${s.eligibility_admission}: ${r.error}`);
    else {
      admission = r.value;
      const ev = admission.eligibility_evidence;
      if (!ev || typeof ev !== "object") {
        fail(NAME1, `${s.eligibility_admission} carries no eligibility_evidence block, so no measurement backs it`);
      } else if (ev.eligibility_verdict !== "ELIGIBLE") {
        fail(NAME1, `the recorded verdict is ${ev.eligibility_verdict} (no_parser ${ev.no_parser_share}, `
          + `use state ${ev.recommended_use_state}). A repository that fails AMENDMENT 1 is excluded, or the `
          + "run is registered `result confounded` under the existing stop conditions.");
      } else if (admission.refused === true) {
        fail(NAME1, `the admission REFUSED compiled_context: ${admission.refusal_reason}`);
      } else {
        pass(NAME1, `verdict ELIGIBLE, use state ${ev.recommended_use_state}, no_parser ${ev.no_parser_share}, `
          + `measured by ${ev.source}`);
      }
    }
  }

  // ---- 2. a published freeze, digest-verified.
  const NAME2 = "a published EXP-0004 freeze (file + sha256)";
  const fz = s.freeze;
  if (!fz || typeof fz !== "object" || typeof fz.path !== "string" || typeof fz.sha256 !== "string") {
    fail(NAME2, "no freeze was declared. The task set must be pinned and published BEFORE arm A begins, "
      + "with its digest, so it cannot be chosen or revised after early results are seen.");
  } else if (!fs.existsSync(fz.path)) {
    fail(NAME2, `the declared freeze file does not exist: ${fz.path}. A freeze nobody published is not a freeze.`);
  } else {
    const actual = sha256File(fz.path);
    if (actual !== fz.sha256) {
      fail(NAME2, `freeze_digest_mismatch: ${fz.path} hashes to ${actual} but the spec declares ${fz.sha256}. `
        + "The published freeze and the file on disk are not the same document.");
    } else {
      pass(NAME2, `${fz.path} verified at ${actual}`);
    }
  }

  // ---- 3. an explicit experiment arm.
  const NAME3 = "an explicit experiment arm (A or B)";
  const arm = s.arm;
  if (arm === undefined || arm === null || arm === "") {
    fail(NAME3, "no experiment arm was declared. An arm that is inferred or defaulted can be re-labelled "
      + "after the fact, which is what the blinding protocol exists to prevent.");
  } else if (!Object.prototype.hasOwnProperty.call(ARM_MODE, arm)) {
    fail(NAME3, `the experiment arm ${JSON.stringify(arm)} is not one of the two preregistered arms. `
      + "EXP-0004 has arm A (current execution) and arm B (capsule execution) and no others.");
  } else {
    pass(NAME3, `arm ${arm} (${ARM_MODE[arm]})`);
  }

  // ---- 5 is loaded before 4 because the seed check compares against it.
  const NAME5 = "a valid starting-context contract";
  let record = null;
  if (typeof s.starting_context_record !== "string" || !s.starting_context_record) {
    fail(NAME5, "no starting_context_record path was given. Without the record from context-mode.mjs there is "
      + "no evidence of what the worker actually started with, and AMENDMENT 2's mechanical check cannot be made.");
  } else {
    const r = loadJson(s.starting_context_record);
    if (!r.ok) fail(NAME5, `cannot read the starting-context record ${s.starting_context_record}: ${r.error}`);
    else {
      record = r.value;
      if (record.record_version !== 1 || typeof record.mode !== "string") {
        fail(NAME5, `${s.starting_context_record} is not a record_version 1 starting-context record`);
      } else if (record.confounded === true) {
        fail(NAME5, "the starting-context record is CONFOUNDED and is excluded from the aggregate: "
          + (Array.isArray(record.confound_reasons) ? record.confound_reasons.map((x) => x.code).join(", ") : "unstated")
          + ". A confounded task is not repaired into a runnable one.");
      } else if (Object.prototype.hasOwnProperty.call(ARM_MODE, arm) && record.mode !== ARM_MODE[arm]) {
        fail(NAME5, `arm ${arm} requires mode ${ARM_MODE[arm]} but the starting-context record is `
          + `${record.mode}. The arm and the context the worker actually receives disagree, so whatever the `
          + "run measured would not be the arm it was labelled.");
      } else {
        pass(NAME5, `${record.mode}, not confounded, starting context ${record.starting_context_bytes} bytes`);
      }
    }
  }

  // ---- 4. the exact repository seed commit.
  const NAME4 = "the exact repository seed commit";
  const seed = s.seed_commit;
  if (seed === undefined || seed === null || seed === "") {
    fail(NAME4, "no seed commit was declared. 'Arms run from identical seeds' is a preregistered stop "
      + "condition, and an unpinned seed makes arm divergence undetectable.");
  } else if (!isCommit(seed)) {
    fail(NAME4, `the seed commit ${JSON.stringify(seed)} is not an exact 40-hex commit sha. An abbreviation or `
      + "a branch name is not a pinned seed.");
  } else if (record !== null && record.repo_commit !== seed) {
    fail(NAME4, `the seed commit ${seed} differs from the commit the starting-context record was taken at `
      + `(${record.repo_commit === null ? "not measured" : record.repo_commit}). The two describe different `
      + "repository states, so this task's arms cannot be compared.");
  } else {
    pass(NAME4, `${seed}${record !== null ? ", matching the starting-context record" : ""}`);
  }

  const L = [];
  if (missing.length > 0) {
    L.push("ACTIVATION REFUSED — EXP-0004 may not begin under these conditions.");
    L.push(`${missing.length} precondition(s) not met, each named:`);
    for (const m of missing) L.push(`  - ${m}`);
    if (met.length > 0) {
      L.push("");
      L.push("preconditions that DID hold (listed so the refusal is not mistaken for a total failure):");
      for (const m of met) L.push(`  + ${m}`);
    }
    L.push("");
    L.push("This tool changed nothing. It holds no capability to start, wire or write anything.");
    process.stdout.write(`${L.join("\n")}\n`);
    process.stderr.write(`activation: refused, ${missing.length} precondition(s) not met\n`);
    process.exit(2);
  }

  L.push(`PRECONDITIONS MET — arm ${arm} (${ARM_MODE[arm]}) may proceed, as far as THIS boundary can tell.`);
  for (const m of met) L.push(`  + ${m}`);
  L.push("");
  L.push("What this verdict does NOT say: it does not start the run, does not wire the compiler into any");
  L.push("execution path, and does not claim the capsule is correct. It says five recorded preconditions");
  L.push("hold. Everything after this is a human decision and an explicit invocation.");
  process.stdout.write(`${L.join("\n")}\n`);
  return 0;
}

const argv = process.argv.slice(2);
if (argv.length === 0 || argv[0] === "--help" || argv[0] === "-h") {
  process.stdout.write(USAGE);
  process.exit(argv.length === 0 ? 2 : 0);
}
if (argv[0] !== "check") die(`unknown subcommand: ${argv[0]}\n${USAGE}`);
if (argv[1] === undefined) die(`check needs an activation spec path\n${USAGE}`);
process.exit(check(argv[1]));
