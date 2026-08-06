#!/usr/bin/env node
// Context Compiler — THE CONTEXT-MODE SEAM (task entry, EXP-0004).
//
//   context-mode.mjs prepare --mode <standard_context|compiled_context>
//     --task <task.json> --out <record.json>
//     [--capsule <file>]... [--prefix <file>]
//     [--initial <file> [--initial-label <label>]]...
//     [--starting-context <file>] [--repo <dir>] [--repo-commit <sha>]
//     [--now <iso>] [--expect-capsule-sha256 <hex>]
//
// SHIPS INERT. Nothing calls this. It is invoked by hand, it changes no
// execution path, and tests/context_mode_tests.sh section 8 greps the live
// runtime to prove that is still true — the claim is a tested property, not a
// promise. PILOT-0002's frozen environment is untouched.
//
// WHY IT EXISTS. AB_PREREGISTRATION AMENDMENT 2 is binding and it is a
// SUBSTITUTION claim: in arm B the compiled capsule REPLACES the broad-context
// delivery. Arm B's starting context is the immutable prefix (SEAM 5) plus the
// capsule (SEAM 2) and NOTHING ELSE; every further byte arrives through a
// recorded expansion request (SEAM 3). If the harness hands a worker the
// ordinary broad context AND the capsule, arm B's tokens rise by construction,
// the capsule becomes pure overhead, and the run measures an ADDITION while
// claiming to test a SUBSTITUTION. A compression thesis cannot be tested by
// adding bytes. This tool is where that stops being an intention and becomes an
// arithmetic check on the record.
//
// TWO MODES, BOTH EXPLICIT. There is no default and no inference:
//
//   standard_context  — today's behaviour, exactly. It does not compile, it
//                       does not require a capsule, and BREADTH NEVER CONFOUNDS
//                       IT: receiving the whole repository IS arm A's contract.
//                       It records its own starting bytes so arm B has
//                       something to be compared against.
//   compiled_context  — prefix + capsule + nothing else. Any additional initial
//                       artifact confounds the task.
//
// MARK, DO NOT REPAIR. A violating task is recorded with `confounded: true`,
// named reasons, and a non-zero exit. This tool NEVER strips the extra context,
// never re-runs the task, and never quietly substitutes a conforming input. A
// harness that repairs a confound destroys the evidence that the confound
// happened, and AB_PREREGISTRATION's stop conditions require the task be
// EXCLUDED from the aggregate — not fixed into looking clean.
//
// WHAT IT DELIBERATELY DOES NOT DO. It scores nothing. There is no success
// field, no win, no saving, no efficiency number anywhere in this record, and
// the test suite greps for their absence. A smaller starting prompt is not a
// result; the only results EXP-0004 recognises are acceptance and the
// preregistered primary metric, and both are measured elsewhere, later.
//
// LIMITATION, STATED NOT HIDDEN: provider-added hidden context — system
// prompts, injected reminders, tool preambles, retrieval the provider performs
// on its own — is NOT OBSERVABLE from any artifact this seam can read. Nothing
// here measures it and nothing here should be read as bounding it. It is
// carried in the record's own `limitations` array so a later analyst meets the
// blind spot in the data rather than discovering it after the conclusion.
//
// Dependencies: node stdlib only. No network. No environment variables are read
// (that would be an override channel). Deterministic under --now and
// --repo-commit: same inputs, byte-identical record.

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { IMMUTABLE_PREFIX, PREFIX_SHA256 } from "../compile/capsule-prefix.mjs";

const RECORD_VERSION = 1;
const MODES = ["standard_context", "compiled_context"];

// AMENDMENT 2, quoted so the record carries the rule it was judged against
// rather than a paraphrase of it.
const CONTRACT = {
  standard_context:
    "arm A, unchanged: the worker receives what today's execution receives. "
    + "This mode does not compile and does not require a capsule. Broad context "
    + "is its CONTRACT, not a defect, so breadth can never confound it.",
  compiled_context:
    "AB_PREREGISTRATION AMENDMENT 2 (binding): the compiled capsule REPLACES "
    + "the broad-context delivery. Starting context = immutable prefix (SEAM 5) "
    + "+ compiled capsule (SEAM 2) + NOTHING ELSE. Every further byte must "
    + "arrive through a recorded SEAM 3 expansion request.",
};

const LIMITATIONS = [
  "provider-added hidden context (system prompts, injected reminders, tool "
  + "preambles, provider-side retrieval) is NOT OBSERVABLE from any artifact "
  + "this seam can read. It is neither measured nor bounded here, and no check "
  + "in this tool should be read as excluding it.",
  "the byte counts are of the artifacts handed in, not of provider tokenization: "
  + "they are an ESTIMATE of prompt weight in the SEAM 5 tier vocabulary, never "
  + "billing truth.",
  "an --initial-label is operator-supplied and unverified: this tool records what "
  + "it was told a file is, and never infers a file's kind from its contents.",
  "this record is closed at task start. Expansion after start is permitted and is "
  + "measured in the SEAM 3 ledger, which this record neither reads nor reflects.",
];

const die = (msg, code = 2) => {
  process.stderr.write(`context-mode: ${msg}\n`);
  process.exit(code);
};

const USAGE = `usage: context-mode.mjs prepare --mode <standard_context|compiled_context>
         --task <task.json> --out <record.json>
         [--capsule <file>]... [--prefix <file>]
         [--initial <file> [--initial-label <label>]]...
         [--starting-context <file>] [--repo <dir>] [--repo-commit <sha>]
         [--now <iso>] [--expect-capsule-sha256 <hex>]

modes (explicit, no default):
  standard_context  today's behaviour: no capsule, breadth permitted, measured.
  compiled_context  prefix + capsule + NOTHING ELSE (AMENDMENT 2).

exit: 0 prepared clean | 2 usage/read refusal | 3 CONFOUNDED (record still written)
This tool is INERT: nothing in the runtime calls it.
`;

const sha256 = (buf) => crypto.createHash("sha256").update(buf).digest("hex");
const readBytes = (p, what) => {
  try { return fs.readFileSync(p); } catch (e) { die(`cannot read ${what} ${p}: ${e.message}`); }
  return null;
};
const readJson = (p, what) => {
  const raw = readBytes(p, what);
  try { return JSON.parse(raw.toString("utf8")); }
  catch (e) { return die(`${what} ${p} is not valid JSON: ${e.message}`); }
};
const abs = (p) => { try { return path.resolve(p); } catch { return p; } };

// An artifact is measured, never interpreted: bytes and a digest, plus whatever
// label the operator attached. Nothing here reads the contents to decide what
// kind of thing it is.
function measure(p, label, role) {
  const buf = readBytes(p, role);
  return { path: p, label: label === null ? "unlabeled" : label, bytes: buf.length, sha256: sha256(buf), _buf: buf };
}

function repoCommit(repoDir, explicit) {
  if (explicit !== null) return { commit: explicit, source: "--repo-commit argument" };
  if (repoDir === null) {
    return { commit: null, source: "not measured: neither --repo-commit nor --repo was given" };
  }
  try {
    const out = execFileSync("git", ["-C", repoDir, "rev-parse", "HEAD"], { encoding: "utf8" }).trim();
    return { commit: out, source: `git -C ${repoDir} rev-parse HEAD` };
  } catch (e) {
    return { commit: null, source: `not measured: git rev-parse failed in ${repoDir} (${e.message.split("\n")[0]})` };
  }
}

const countOccurrences = (hay, needle) => {
  if (needle.length === 0) return 0;
  let n = 0; let i = hay.indexOf(needle);
  while (i !== -1) { n += 1; i = hay.indexOf(needle, i + needle.length); }
  return n;
};

// ---------------------------------------------------------------- arguments --
function parseArgs(argv) {
  const a = {
    mode: null, task: null, out: null, prefix: null, capsules: [], initials: [],
    startingContext: null, repo: null, repoCommit: null, now: null, expectCapsule: null,
  };
  for (let i = 0; i < argv.length; i++) {
    const k = argv[i];
    const need = (what) => { const v = argv[++i]; if (v === undefined) die(`${k} needs ${what}`); return v; };
    if (k === "--mode") a.mode = need("a mode");
    else if (k === "--task") a.task = need("a path");
    else if (k === "--out") a.out = need("a path");
    else if (k === "--prefix") a.prefix = need("a path");
    else if (k === "--capsule") a.capsules.push(need("a path"));
    else if (k === "--initial") a.initials.push({ path: need("a path"), label: null });
    else if (k === "--initial-label") {
      const v = need("a label");
      if (a.initials.length === 0) die("--initial-label must follow an --initial");
      a.initials[a.initials.length - 1].label = v;
    } else if (k === "--starting-context") a.startingContext = need("a path");
    else if (k === "--repo") a.repo = need("a directory");
    else if (k === "--repo-commit") a.repoCommit = need("a commit sha");
    else if (k === "--now") a.now = need("an iso timestamp");
    else if (k === "--expect-capsule-sha256") a.expectCapsule = need("a hex digest");
    else die(`unknown argument: ${k}\n${USAGE}`);
  }
  return a;
}

// ------------------------------------------------------------------ prepare --
function prepare(argv) {
  const a = parseArgs(argv);
  if (a.mode === null) die(`--mode is required and has no default: one of ${MODES.join(", ")}\n${USAGE}`);
  if (!MODES.includes(a.mode)) {
    die(`unknown mode: ${a.mode}. Exactly two modes exist: ${MODES.join(", ")}. `
      + "There is no third mode and no inferred default.");
  }
  if (a.task === null) die(`--task <task.json> is required\n${USAGE}`);
  if (a.out === null) die(`--out <record.json> is required\n${USAGE}`);

  const task = readJson(a.task, "task descriptor");
  const taskId = typeof task.task_id === "string" && task.task_id ? task.task_id : null;
  if (taskId === null) die(`task descriptor ${a.task} has no task_id`);
  const declared = Array.isArray(task.initial_artifacts) ? task.initial_artifacts.map(abs) : [];
  const declaredIsList = Array.isArray(task.initial_artifacts);

  const compiled = a.mode === "compiled_context";
  if (compiled && a.capsules.length === 0) {
    die("compiled_context requires --capsule: a compiled mode with no capsule is not "
      + "compiled context. Nothing is inferred and nothing is substituted.");
  }

  const reasons = [];
  const confound = (code, detail) => reasons.push({ code, detail });

  // ---- the prefix (SEAM 5 segment 1).
  let prefix = null;
  if (a.prefix !== null) {
    prefix = measure(a.prefix, null, "prefix");
    prefix.source = a.prefix;
  } else if (compiled) {
    const buf = Buffer.from(IMMUTABLE_PREFIX, "utf8");
    prefix = { path: null, label: "unlabeled", bytes: buf.length, sha256: sha256(buf), _buf: buf,
      source: "the compiler constant build-os/compiler/compile/capsule-prefix.mjs" };
  }

  // ---- the capsule(s) (SEAM 2).
  const capsules = a.capsules.map((p) => {
    const m = measure(p, null, "capsule");
    let seam2 = null;
    try { seam2 = JSON.parse(m._buf.toString("utf8")); } catch { seam2 = null; }
    m.seam2_json = seam2 !== null && typeof seam2 === "object";
    m.declared_prefix_sha256 = m.seam2_json && seam2.provenance && typeof seam2.provenance.prefix_sha256 === "string"
      ? seam2.provenance.prefix_sha256 : null;
    return m;
  });
  const capsule = capsules.length > 0 ? capsules[0] : null;

  if (capsules.length > 1) {
    confound("duplicated_capsule_content",
      `${capsules.length} capsules were supplied for one task; the starting context would carry the `
      + "capsule more than once and its byte accounting would double-count. Digests: "
      + capsules.map((c) => c.sha256.slice(0, 12)).join(", "));
  }
  if (!compiled && capsule !== null) {
    confound("capsule_leaked_into_standard_context",
      "a capsule was supplied to standard_context. AB_PREREGISTRATION's stop conditions name "
      + "'the capsule leaks into arm A' explicitly: arm A must receive exactly what today's "
      + "execution receives, so this task cannot serve as the control it was meant to be.");
  }

  // ---- prefix immutability: the supplied bytes must be the pinned bytes.
  // Verified against the capsule's OWN declared digest where it has one, and
  // against the compiler's pinned constant always. A prefix that varies is not
  // a prefix — it invalidates every other task's cached prefix, which is the
  // one cost SEAM 5 exists to avoid.
  let prefixImmutable = null;
  const verifiedAgainst = [];
  if (compiled && prefix !== null) {
    prefixImmutable = true;
    const declaredSha = capsule !== null ? capsule.declared_prefix_sha256 : null;
    if (declaredSha !== null) {
      verifiedAgainst.push({ against: "the capsule's declared provenance.prefix_sha256", digest: declaredSha, match: declaredSha === prefix.sha256 });
      if (declaredSha !== prefix.sha256) {
        prefixImmutable = false;
        confound("mutable_prefix",
          `the supplied prefix digest ${prefix.sha256} does not match the digest the capsule declares `
          + `(provenance.prefix_sha256 = ${declaredSha}). The prefix handed to this task is not the prefix `
          + "the capsule was compiled against, so the cached-prefix contract of SEAM 5 does not hold here.");
      }
    }
    verifiedAgainst.push({ against: "the compiler's pinned PREFIX_SHA256 constant", digest: PREFIX_SHA256, match: PREFIX_SHA256 === prefix.sha256 });
    if (PREFIX_SHA256 !== prefix.sha256) {
      prefixImmutable = false;
      confound("mutable_prefix",
        `the supplied prefix digest ${prefix.sha256} does not match the compiler's pinned constant `
        + `${PREFIX_SHA256}. A per-task prefix is a mutable prefix, and a mutable prefix means the `
        + "cross-task cache measurement SEAM 5 promises cannot be made.");
    }
    if (declaredSha === null && capsule !== null) {
      verifiedAgainst.push({ against: "the capsule's declared provenance.prefix_sha256", digest: null,
        match: null, note: "the capsule declares no prefix digest, so only the pinned constant could be compared" });
    }
  }

  // ---- the capsule digest the task descriptor pinned, if it pinned one.
  const expected = a.expectCapsule !== null ? a.expectCapsule
    : (typeof task.capsule_sha256 === "string" ? task.capsule_sha256 : null);
  if (compiled && capsule !== null && expected !== null && expected !== capsule.sha256) {
    confound("capsule_digest_mismatch",
      `the capsule handed in has digest ${capsule.sha256} but this task pins ${expected}. The worker `
      + "would be executing a different capsule from the one the run record describes.");
  }

  // ---- duplicated content inside the delivered payload.
  if (compiled && capsule !== null && prefix !== null) {
    const capText = capsule._buf.toString("utf8");
    const preText = prefix._buf.toString("utf8");
    if (preText.length > 0 && capText.includes(preText)) {
      confound("duplicated_prefix_content",
        "the capsule payload already contains the immutable prefix (a rendered capsule.md carries its own "
        + "PREFIX segment), and a prefix segment was supplied alongside it. The prefix would be delivered "
        + "twice and counted twice. This tool does not strip it: hand in the capsule without its prefix "
        + "segment, or omit --prefix, and prepare the task again as a NEW task.");
    }
  }

  // ---- initial artifacts. In compiled_context AMENDMENT 2 permits none at all.
  const initials = a.initials.map((x) => {
    const m = measure(x.path, x.label, "initial artifact");
    m.declared_in_task = declaredIsList ? declared.includes(abs(x.path)) : null;
    m.permitted = compiled ? false : true;
    return m;
  });
  const nonPermitted = compiled && initials.length > 0;
  if (nonPermitted) {
    confound("non_permitted_initial_context",
      `${initials.length} initial artifact(s) were supplied alongside the capsule: `
      + initials.map((m) => `${m.path} [${m.label}, ${m.bytes}B]`).join("; ")
      + ". AMENDMENT 2 permits the prefix and the capsule and nothing else, whether or not the task "
      + "descriptor mentions the artifact. Extra starting context makes this task an ADDITION, not the "
      + "SUBSTITUTION the arm is supposed to test.");
    const notDeclared = initials.filter((m) => m.declared_in_task === false);
    if (notDeclared.length > 0) {
      confound("undeclared_initial_artifact",
        `${notDeclared.length} of them are absent from the task descriptor's initial_artifacts list: `
        + notDeclared.map((m) => m.path).join("; ")
        + ". Starting context arrived that the run record would not otherwise know about.");
    }
  }

  // ---- starting-context arithmetic. AMENDMENT 2's MECHANICAL CHECK: B's
  // starting bytes must EQUAL the rendered capsule plus prefix. Measured from
  // what the harness actually sent when --starting-context is given, which is
  // the only version of the check that can catch a harness this tool did not
  // assemble.
  const assembled = (prefix === null ? 0 : prefix.bytes)
    + capsules.reduce((n, c) => n + c.bytes, 0)
    + initials.reduce((n, m) => n + m.bytes, 0);
  let measuredBytes = assembled;
  let measuredFrom = "the artifacts supplied to this tool (prefix + capsule(s) + initial artifacts)";
  if (a.startingContext !== null) {
    const sc = measure(a.startingContext, null, "starting-context payload");
    measuredBytes = sc.bytes;
    measuredFrom = `the payload the harness actually sent: ${a.startingContext}`;
    if (compiled && capsule !== null) {
      const scText = sc._buf.toString("utf8");
      const capText = capsule._buf.toString("utf8");
      if (countOccurrences(scText, capText) > 1) {
        confound("duplicated_capsule_content",
          "the payload the harness sent contains the capsule more than once.");
      }
    }
  }
  const permitted = compiled && prefix !== null && capsule !== null ? prefix.bytes + capsule.bytes : null;
  const permittedFormula = compiled
    ? "permitted = prefix_bytes + capsule_bytes (AMENDMENT 2: prefix + capsule + nothing else)"
    : "not applicable: standard_context has no permitted-set restriction — breadth is its contract";
  if (compiled && permitted !== null && measuredBytes !== permitted) {
    confound("starting_bytes_mismatch",
      `starting bytes ${measuredBytes} != permitted ${permitted} (prefix ${prefix.bytes} + capsule `
      + `${capsule.bytes}); delta ${measuredBytes - permitted} bytes, measured from ${measuredFrom}. `
      + "Arm B started with something other than the prefix and the capsule.");
  }

  const confounded = reasons.length > 0;
  const { commit, source: commitSource } = repoCommit(a.repo, a.repoCommit);
  const recordedAt = a.now !== null ? a.now : new Date().toISOString();

  const strip = (m) => (m === null ? null : {
    path: m.path, label: m.label, bytes: m.bytes, sha256: m.sha256,
    ...(m.seam2_json === undefined ? {} : { seam2_json: m.seam2_json, declared_prefix_sha256: m.declared_prefix_sha256 }),
    ...(m.declared_in_task === undefined ? {} : { declared_in_task: m.declared_in_task, permitted: m.permitted }),
  });

  const record = {
    record_version: RECORD_VERSION,
    tool: "build-os/compiler/entry/context-mode.mjs",
    wired: false,
    inert_note: "nothing in the runtime calls this tool; it is invoked by hand and changes no execution path",
    task_id: taskId,

    mode: a.mode,
    mode_contract: CONTRACT[a.mode],
    compiled,

    prefix_sha256: prefix === null ? null : prefix.sha256,
    prefix_bytes: prefix === null ? null : prefix.bytes,
    prefix_immutable: prefixImmutable,
    prefix: prefix === null
      ? { supplied: false, reason: "no prefix segment: standard_context delivers no compiled prefix" }
      : { supplied: true, source: prefix.source, path: prefix.path, sha256: prefix.sha256,
        bytes: prefix.bytes, verified_against: verifiedAgainst },

    capsule_sha256: capsule === null ? null : capsule.sha256,
    capsule_bytes: capsule === null ? null : capsule.bytes,
    capsule: capsule === null
      ? { supplied: false, reason: "no capsule: standard_context does not compile and requires none" }
      : { supplied: true, ...strip(capsule), pinned_digest: expected, count_supplied: capsules.length },

    initial_artifact_count: initials.length,
    non_permitted_initial_context_supplied: nonPermitted,
    initial_artifacts: initials.map(strip),

    starting_context_bytes: measuredBytes,
    starting_context_measured_from: measuredFrom,
    permitted_starting_context_bytes: permitted,
    permitted_formula: permittedFormula,
    starting_context_matches_contract: compiled ? (permitted !== null && measuredBytes === permitted) : null,

    confounded,
    confound_reasons: reasons,
    registered_conclusion: confounded ? "result confounded" : null,
    excluded_from_aggregate: confounded,
    disposition: confounded
      ? "excluded from the aggregate: result confounded. NOT repaired, NOT stripped, NOT re-run."
      : "admitted",

    expansion_after_start: {
      permitted: true,
      measured_by: "the SEAM 3 expansion ledger (build-os/compiler/runtime/expand.mjs)",
      included_in_this_record: false,
      note: "this record is closed at task start and is never rewritten. Expansions are a measured, "
        + "permitted cost recorded elsewhere; they are the compiler's own error signal, and they must "
        + "not retroactively alter what the task started with.",
    },

    repo_commit: commit,
    repo_commit_source: commitSource,
    recorded_at: recordedAt,
    limitations: LIMITATIONS,
  };

  fs.writeFileSync(a.out, `${JSON.stringify(record, null, 2)}\n`, "utf8");

  if (confounded) {
    process.stderr.write(
      `context-mode: task ${taskId} is CONFOUNDED under ${a.mode}. It is excluded from the EXP-0004 `
      + "aggregate and registered `result confounded`. It has NOT been repaired, the extra context has "
      + "NOT been stripped, and the task has NOT been re-run — doing any of those would erase the "
      + "evidence that the harness broke the arm contract.\n"
      + reasons.map((r) => `  - ${r.code}: ${r.detail}\n`).join("")
      + `record written: ${a.out}\n`);
    process.exit(3);
  }
  process.stdout.write(`context-mode: ${a.mode} prepared for ${taskId}; starting context ${measuredBytes} bytes; record ${a.out}\n`);
  return 0;
}

// --------------------------------------------------------------------- main --
const argv = process.argv.slice(2);
if (argv.length === 0 || argv[0] === "--help" || argv[0] === "-h") {
  process.stdout.write(USAGE);
  process.exit(argv.length === 0 ? 2 : 0);
}
if (argv[0] !== "prepare") die(`unknown subcommand: ${argv[0]}\n${USAGE}`);
process.exit(prepare(argv.slice(1)));
