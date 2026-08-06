// EXP-0004 BLINDING — THE IMMUTABLE FREEZE SNAPSHOT.
//
//   node freeze.mjs artifacts
//   node freeze.mjs prepare --analyst <f> --adjudication <f> --calculations <f>
//                           --provisional <f> --exclusions <f> --out <dir>
//   node freeze.mjs freeze  --inputs <dir> --out <snapshot.json>
//   node freeze.mjs verify  --snapshot <f> [--inputs <dir>]
//
// WHAT THE FREEZE IS FOR. The sealed mapping may not be opened until the whole
// analysis is fixed. "Fixed" has to mean something checkable, or it means
// whatever is convenient on the day. Here it means: FOURTEEN named artifacts
// exist, and this snapshot records the sha256 of each and a digest over the
// whole list. After that, changing any input changes its digest, which changes
// the snapshot digest, which is a visible break rather than a quiet edit.
//
// THE FOURTEEN ARE THE OPERATOR'S LIST, ONE ARTIFACT EACH: task-level
// acceptance; regressions; exclusion/confounding decisions; tokens; elapsed;
// starting-context bytes; expansion bytes; rework; failed hypotheses; verifier
// dispatches; human intervention; per-task calculations; aggregate
// calculations; and the ANONYMOUS PROVISIONAL VERDICT.
//
// The last one is the load-bearing one. Freezing the numbers but not the
// verdict would leave the only step that matters — choosing what the numbers
// mean — free to happen after the reveal, which is exactly the failure
// blinding exists to prevent.
//
// A MISSING ARTIFACT REFUSES, AND THE REFUSAL NAMES EVERY MISSING ONE. A freeze
// that silently accepted thirteen of fourteen would be worse than none: it
// would produce a digest, and a digest is read as proof.
//
// ORDERING NOTE (a real ambiguity in the operator's instruction, resolved here
// and stated rather than smoothed over): the freeze list INCLUDES the anonymous
// provisional verdict, yet the verdict is computed from frozen inputs — so the
// two cannot both be first. The resolution: ACCEPTANCE is frozen first (the
// analyst view's freeze flag), the anonymous verdict is computed from the
// frozen acceptance and the economics, and only then is the full fourteen-item
// snapshot taken. Nothing is computed after its own snapshot.
//
// Invoke via node; this file is deliberately NOT executable.
// Exit: 0 fine; 2 refusal. Dependencies: node stdlib only.

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { EXPERIMENT } from "./seal-mapping.mjs";
import { WITHHELD_UNTIL_FROZEN } from "./views.mjs";

class Refusal extends Error {}
const refuse = (m) => {
  throw new Refusal(m);
};

const sha256hex = (buf) => crypto.createHash("sha256").update(buf).digest("hex");
const serialize = (obj) => JSON.stringify(obj, null, 2) + "\n";

/** The operator's freeze list, in the operator's order. Fourteen. */
export const REQUIRED_ARTIFACTS = [
  "task_level_acceptance",
  "regressions",
  "exclusion_decisions",
  "tokens",
  "elapsed",
  "starting_context_bytes",
  "expansion_bytes",
  "rework",
  "failed_hypotheses",
  "verifier_dispatches",
  "human_intervention",
  "per_task_calculations",
  "aggregate_calculations",
  "anonymous_provisional_verdict",
];

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

const project = (units, fields) =>
  units.map((u) => {
    const o = { unit_id: u.unit_id, task_id: u.task_id };
    if (u.label !== undefined) o.label = u.label;
    for (const f of fields) o[f] = u[f];
    return o;
  });

const wrap = (name, body) => ({ artifact: name, experiment: EXPERIMENT, ...body });

/**
 * Materialise the fourteen freeze inputs from the four upstream artifacts.
 * This is a PROJECTION, not a computation: every number here already exists
 * upstream, so freezing cannot introduce a figure the analysis never saw.
 */
export function prepare({ analyst, adjudication, calculations, provisional, exclusions }) {
  if (analyst.view !== "analyst") refuse("--analyst must be an analyst view");
  if (analyst.acceptance_frozen !== true) {
    refuse(
      "the analyst view is not acceptance-frozen, so the starting-size and expansion fields are still withheld " +
        `and ${WITHHELD_UNTIL_FROZEN.join(", ")} cannot be frozen. Freeze acceptance first.`
    );
  }
  if (!Array.isArray(adjudication?.units)) refuse("--adjudication must carry a units array");
  if (calculations?.artifact !== "calculations") refuse("--calculations must be a calculations artifact");
  if (provisional?.artifact !== "anonymous_provisional_verdict") {
    refuse("--provisional must be an anonymous_provisional_verdict artifact");
  }

  const au = analyst.units;
  const ju = adjudication.units;
  return {
    task_level_acceptance: wrap("task_level_acceptance", {
      n_units: ju.length,
      units: ju.map((u) => ({ unit_id: u.unit_id, task_id: u.task_id, acceptance_result: u.acceptance_result })),
      frozen_before: "any economic field entered a calculation",
    }),
    regressions: wrap("regressions", {
      n_units: ju.length,
      units: ju.map((u) => ({ unit_id: u.unit_id, task_id: u.task_id, regressions: u.regressions })),
    }),
    exclusion_decisions: exclusions,
    tokens: wrap("tokens", { units: project(au, ["total_tokens", "uncached_tokens"]) }),
    elapsed: wrap("elapsed", { units: project(au, ["total_elapsed_s", "time_to_first_meaningful_edit_s"]) }),
    starting_context_bytes: wrap("starting_context_bytes", {
      units: project(au, ["starting_context_bytes"]),
      note: "withheld from the adjudicator entirely, and from the analyst until acceptance was frozen",
    }),
    expansion_bytes: wrap("expansion_bytes", { units: project(au, ["expansion_bytes", "context_expansions"]) }),
    rework: wrap("rework", { units: project(au, ["rework_rounds"]) }),
    failed_hypotheses: wrap("failed_hypotheses", { units: project(au, ["failed_hypotheses"]) }),
    verifier_dispatches: wrap("verifier_dispatches", { units: project(au, ["verifier_dispatches"]) }),
    human_intervention: wrap("human_intervention", { units: project(au, ["human_interventions"]) }),
    per_task_calculations: wrap("per_task_calculations", { n_pairs: calculations.n_pairs, per_task: calculations.per_task }),
    aggregate_calculations: wrap("aggregate_calculations", {
      n_pairs: calculations.n_pairs,
      acceptance: calculations.acceptance,
      totals: calculations.totals,
      aggregate: calculations.aggregate,
    }),
    anonymous_provisional_verdict: provisional,
  };
}

/** The digest is over the NAMES, SIZES and CONTENT HASHES, in the fixed order. */
export function snapshotDigest(entries) {
  const listing = entries.map((e) => `${e.name} ${e.bytes} ${e.sha256}`).join("\n") + "\n";
  return { listing, digest: sha256hex(listing) };
}

export function freeze(inputsDir) {
  const missing = [];
  const entries = [];
  for (const name of REQUIRED_ARTIFACTS) {
    const f = path.join(inputsDir, `${name}.json`);
    let buf;
    try {
      buf = fs.readFileSync(f);
    } catch {
      missing.push(name);
      continue;
    }
    entries.push({ name, bytes: buf.length, sha256: sha256hex(buf) });
  }
  if (missing.length) {
    refuse(
      `cannot freeze: ${missing.length} of ${REQUIRED_ARTIFACTS.length} required artifact(s) are missing — ` +
        missing.join(", ") +
        `. The sealed mapping stays sealed until every one of them exists; a partial freeze still produces a ` +
        `digest, and a digest is read as proof.`
    );
  }
  const { digest } = snapshotDigest(entries);
  return {
    artifact: "freeze_snapshot",
    experiment: EXPERIMENT,
    required_artifacts: REQUIRED_ARTIFACTS,
    n_required: REQUIRED_ARTIFACTS.length,
    artifacts: entries,
    snapshot_digest: digest,
    digest_note:
      "sha256 over the lines '<name> <bytes> <sha256>' in the fixed required order. Changing any input changes " +
      "its content hash, which changes this digest. That is what makes the snapshot immutable in the only sense " +
      "that matters: not that it cannot be edited, but that an edit cannot be hidden.",
    reveal_note: "This snapshot is a PRECONDITION of the reveal, not a permission for it.",
  };
}

export function verify(snapshot, inputsDir) {
  const problems = [];
  if (snapshot?.artifact !== "freeze_snapshot") refuse("--snapshot is not a freeze_snapshot artifact");
  if (!Array.isArray(snapshot.artifacts)) refuse("--snapshot carries no artifacts list");

  const recomputed = snapshotDigest(snapshot.artifacts).digest;
  if (recomputed !== snapshot.snapshot_digest) {
    problems.push(
      `the snapshot's own recorded digest (${snapshot.snapshot_digest}) does not match the digest of its own ` +
        `artifact listing (${recomputed}) — the snapshot file itself was edited`
    );
  }
  const names = snapshot.artifacts.map((a) => a.name);
  for (const r of REQUIRED_ARTIFACTS) if (!names.includes(r)) problems.push(`required artifact '${r}' is absent from the snapshot`);

  if (inputsDir) {
    for (const a of snapshot.artifacts) {
      const f = path.join(inputsDir, `${a.name}.json`);
      let buf;
      try {
        buf = fs.readFileSync(f);
      } catch {
        problems.push(`artifact '${a.name}' is no longer present under the frozen inputs`);
        continue;
      }
      const h = sha256hex(buf);
      if (h !== a.sha256) {
        problems.push(
          `artifact '${a.name}' CHANGED after the freeze: frozen ${a.sha256}, now ${h}. The snapshot is invalid; ` +
            `it is not re-frozen, because a freeze that can be refreshed is not a freeze.`
        );
      }
    }
  }
  return problems;
}

// -------------------------------------------------------------------- CLI --

const USAGE =
  "usage: freeze.mjs artifacts\n" +
  "       freeze.mjs prepare --analyst <f> --adjudication <f> --calculations <f> --provisional <f> --exclusions <f> --out <dir>\n" +
  "       freeze.mjs freeze  --inputs <dir> --out <snapshot.json>\n" +
  "       freeze.mjs verify  --snapshot <f> [--inputs <dir>]\n";

function cli(argv) {
  const cmd = argv[0];
  const rest = argv.slice(1);
  const opt = {};
  for (let i = 0; i < rest.length; i++) {
    const k = rest[i];
    if (k === "--analyst") opt.analyst = rest[++i];
    else if (k === "--adjudication") opt.adjudication = rest[++i];
    else if (k === "--calculations") opt.calculations = rest[++i];
    else if (k === "--provisional") opt.provisional = rest[++i];
    else if (k === "--exclusions") opt.exclusions = rest[++i];
    else if (k === "--inputs") opt.inputs = rest[++i];
    else if (k === "--snapshot") opt.snapshot = rest[++i];
    else if (k === "--out") opt.out = rest[++i];
    else {
      process.stderr.write(`freeze: unknown option: ${k}\n${USAGE}`);
      return 2;
    }
  }
  try {
    if (cmd === "artifacts") {
      for (const a of REQUIRED_ARTIFACTS) process.stdout.write(`${a}\n`);
      return 0;
    }
    if (cmd === "prepare") {
      for (const k of ["analyst", "adjudication", "calculations", "provisional", "exclusions", "out"]) {
        if (!opt[k]) refuse(`prepare needs --${k}`);
      }
      const built = prepare({
        analyst: readJson(opt.analyst, "analyst view"),
        adjudication: readJson(opt.adjudication, "adjudication"),
        calculations: readJson(opt.calculations, "calculations"),
        provisional: readJson(opt.provisional, "anonymous provisional verdict"),
        exclusions: readJson(opt.exclusions, "exclusion decisions"),
      });
      fs.mkdirSync(opt.out, { recursive: true });
      for (const name of REQUIRED_ARTIFACTS) {
        fs.writeFileSync(path.join(opt.out, `${name}.json`), serialize(built[name]));
      }
      process.stdout.write(`prepared ${REQUIRED_ARTIFACTS.length} freeze input(s) in ${opt.out}\n`);
      return 0;
    }
    if (cmd === "freeze") {
      if (!opt.inputs) refuse("freeze needs --inputs <dir>");
      const snap = freeze(opt.inputs);
      const text = serialize(snap);
      if (opt.out) fs.writeFileSync(opt.out, text);
      else process.stdout.write(text);
      process.stdout.write(`frozen: ${snap.n_required} artifact(s)\nsnapshot_digest: ${snap.snapshot_digest}\n`);
      return 0;
    }
    if (cmd === "verify") {
      if (!opt.snapshot) refuse("verify needs --snapshot <f>");
      const snap = readJson(opt.snapshot, "freeze snapshot");
      const problems = verify(snap, opt.inputs);
      if (problems.length) refuse(`the freeze snapshot does NOT validate:\n  - ` + problems.join("\n  - "));
      process.stdout.write(`snapshot_valid: ${snap.snapshot_digest}\n`);
      return 0;
    }
    if (cmd === "-h" || cmd === "--help" || cmd === undefined) {
      process.stdout.write(USAGE);
      return 0;
    }
    refuse(`unknown subcommand: ${cmd}`);
  } catch (e) {
    process.stderr.write(`freeze: REFUSED — ${e.message}\n`);
    return 2;
  }
  return 2;
}

const invoked =
  process.argv[1] && fs.realpathSync(process.argv[1]) === fs.realpathSync(fileURLToPath(import.meta.url));
if (invoked) process.exit(cli(process.argv.slice(2)));
