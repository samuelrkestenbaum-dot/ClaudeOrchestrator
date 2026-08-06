#!/usr/bin/env node
// Context Compiler — ELIGIBILITY-GATED ADMISSION (task entry, EXP-0004).
//
//   admit.mjs admit --mode-requested <standard_context|compiled_context>
//     ( --index <index.json> [--capsule <capsule.json>] | --report <report.json> )
//     --out <admission.json> [--now <iso>]
//
// SHIPS INERT. Nothing calls this. tests/context_mode_tests.sh section 8 greps
// the live runtime to prove it, so the inertness claim is a tested property.
//
// WHAT IT DECIDES. Whether `compiled_context` MAY be selected for a repository
// at all. AB_PREREGISTRATION AMENDMENT 1 makes repository signal a PRECONDITION,
// not a preference: a capsule compiled from an index that parsed almost nothing
// is small-because-IGNORANT, and running arm B on it would register
// `context compilation harmful` for a reason that has nothing to do with the
// compression thesis. So admission is gated on a MEASUREMENT, taken before the
// run, recorded in full.
//
// IT CONSUMES THE VERDICT, IT DOES NOT REIMPLEMENT IT. Every number here comes
// from build-os/compiler/capability/report.mjs — run live against an index, or
// read back from a recorded run of the same tool. Recomputing the eligibility
// share here would create a second derivation of the one number AMENDMENT 1 is
// measured on, and two derivations of a preregistered threshold is exactly the
// ambiguity the reporter's DERIVATION PARITY note exists to prevent.
//
// THE RULE IS CONJUNCTIVE, AND THAT MATTERS. Admission needs BOTH the ELIGIBLE
// verdict AND a recommended use state other than `bypass`. They are not the
// same test: an index can pass the AMENDMENT 1 share (no_parser below one half)
// and still trip `bypass-2` by extracting ZERO symbols across the whole
// admitted-candidate set. That repository is eligible by the letter of the
// amendment and blind in fact, and the reporter is willing to say so. Admitting
// it because one of the two tests passed would be reading the rule for the
// answer it gives rather than for what it measures.
//
// NO OVERRIDE — BY CONSTRUCTION, NOT BY POLICY. During EXP-0004 there is NO
// flag, NO argument and NO environment variable by which an operator or a
// worker can force `compiled_context` past a refusal. No such path is built.
// `--force`, `--override` and `--allow-bypass` are recognised only so that
// attempting one gets a NAMED REFUSAL instead of a confusing usage error; they
// are refusal paths, not escape hatches. This file reads no environment
// variables at all — the test suite greps for `process.env` and asserts zero
// occurrences, because an env var is the override channel nobody documents.
//
// A REFUSAL IS NOT AN ERROR. It is a legitimate outcome that DOWNGRADES the
// task to `standard_context` and says why. The admission record is written
// either way; the exit code is 4 so a harness cannot ignore a downgrade by
// accident.
//
// Dependencies: node stdlib only. No network. Deterministic under --now.

import fs from "node:fs";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const ADMISSION_VERSION = 1;
const MODES = ["standard_context", "compiled_context"];
const REPORTER = fileURLToPath(new URL("../capability/report.mjs", import.meta.url));

const ELIGIBILITY_RULE = [
  "compiled_context is admitted for a repository only when BOTH of these hold, ",
  "measured by build-os/compiler/capability/report.mjs and recorded before the run: ",
  "(1) AB_PREREGISTRATION AMENDMENT 1 — the no_parser share of the admitted-candidate ",
  "set is strictly below one half of that set, by integer arithmetic so no rounding ",
  "decides a preregistered precondition; AND (2) the reporter's recommended use state ",
  "is not `bypass` — an index that parsed enough files but extracted no symbols is ",
  "eligible by the letter of the amendment and blind in fact. ",
  "Not eligible => compiled_context is REFUSED and standard_context is used. ",
  "There is no override during EXP-0004: no flag, no argument, no environment variable.",
].join("");

const OVERRIDE_FLAGS = ["--force", "--override", "--allow-bypass", "--force-compiled", "--ignore-bypass"];

const die = (msg, code = 2) => {
  process.stderr.write(`admit: ${msg}\n`);
  process.exit(code);
};

const USAGE = `usage: admit.mjs admit --mode-requested <standard_context|compiled_context>
         ( --index <index.json> [--capsule <capsule.json>] | --report <report.json> )
         --out <admission.json> [--now <iso>]

Eligibility is measured by build-os/compiler/capability/report.mjs and CONSUMED
here, never recomputed. There is no override flag: a bypass verdict refuses
compiled_context and no argument can change that during EXP-0004.

exit: 0 requested mode granted | 4 compiled_context REFUSED, downgraded | 2 usage
This tool is INERT: nothing in the runtime calls it.
`;

function parseArgs(argv) {
  const a = { requested: null, index: null, capsule: null, report: null, out: null, now: null };
  for (let i = 0; i < argv.length; i++) {
    const k = argv[i];
    if (OVERRIDE_FLAGS.includes(k)) {
      die(`${k} does not exist: there is no override for an eligibility refusal during EXP-0004. `
        + "A `bypass` or NOT-ELIGIBLE verdict refuses compiled_context and no flag, argument or "
        + "environment variable can force it. If you believe the verdict is wrong, fix the INDEX "
        + "(add an extractor, re-index) and measure again — that changes the evidence, which is the "
        + "only thing allowed to change the answer.");
    }
    const need = (what) => { const v = argv[++i]; if (v === undefined) die(`${k} needs ${what}`); return v; };
    if (k === "--mode-requested") a.requested = need("a mode");
    else if (k === "--index") a.index = need("a path");
    else if (k === "--capsule") a.capsule = need("a path");
    else if (k === "--report") a.report = need("a path");
    else if (k === "--out") a.out = need("a path");
    else if (k === "--now") a.now = need("an iso timestamp");
    else die(`unknown argument: ${k}\n${USAGE}`);
  }
  return a;
}

function runReporter(indexPath, capsulePath) {
  const args = [REPORTER, "report", "--index", indexPath];
  if (capsulePath !== null) args.push("--capsule", capsulePath);
  args.push("--json");
  let raw;
  try { raw = execFileSync(process.execPath, args, { encoding: "utf8" }); }
  catch (e) {
    die("the capability reporter refused to run, so no eligibility evidence exists and "
      + `compiled_context cannot be admitted: ${(e.stderr || e.message).toString().trim()}`);
  }
  try { return JSON.parse(raw); }
  catch (e) { return die(`the capability reporter emitted output this tool cannot parse: ${e.message}`); }
}

function readReport(p) {
  let raw;
  try { raw = fs.readFileSync(p, "utf8"); } catch (e) { die(`cannot read recorded report ${p}: ${e.message}`); }
  let r;
  try { r = JSON.parse(raw); } catch (e) { return die(`recorded report ${p} is not valid JSON: ${e.message}`); }
  if (!r || typeof r !== "object" || r.report_version !== 1 || !r.exp0004_eligibility) {
    die(`${p} is not a report_version 1 capability report (no exp0004_eligibility block). `
      + "This tool consumes the reporter's own output and will not accept a hand-written substitute.");
  }
  return r;
}

const textOf = (s, missing) => (s && typeof s.text === "string" ? s.text : `unavailable (${missing})`);

function admit(argv) {
  const a = parseArgs(argv);
  if (a.requested === null) die(`--mode-requested is required\n${USAGE}`);
  if (!MODES.includes(a.requested)) die(`unknown mode: ${a.requested}. Exactly two modes exist: ${MODES.join(", ")}`);
  if (a.out === null) die(`--out <admission.json> is required\n${USAGE}`);
  if ((a.index === null) === (a.report === null)) {
    die(`exactly one of --index (run the reporter now) or --report (consume a recorded run) is required\n${USAGE}`);
  }

  const report = a.index !== null ? runReporter(a.index, a.capsule) : readReport(a.report);
  const verdict = report.exp0004_eligibility && report.exp0004_eligibility.verdict;
  const state = report.recommended_use_state;

  const amendment1 = verdict === "ELIGIBLE";
  const notBypass = state !== "bypass";
  const eligible = amendment1 && notBypass;

  let granted = a.requested;
  let refused = false;
  let refusalReason = null;
  if (a.requested === "compiled_context" && !eligible) {
    granted = "standard_context";
    refused = true;
    const parts = [];
    if (!amendment1) {
      parts.push(`AMENDMENT 1 verdict is ${verdict}: no_parser `
        + `${textOf(report.exp0004_eligibility && report.exp0004_eligibility.share, "no share recorded")} of the `
        + `admitted-candidate set; exact test: ${report.exp0004_eligibility && report.exp0004_eligibility.exact_test}`);
    }
    if (!notBypass) {
      parts.push("the reporter's recommended use state is `bypass`: "
        + (Array.isArray(report.recommendation_message) ? report.recommendation_message.join(" ") : "")
        + " The tests that fired: "
        + (Array.isArray(report.recommendation_tests)
          ? report.recommendation_tests.filter((t) => t.fired).map((t) => `${t.id} (${t.text})`).join("; ")
          : "unavailable"));
    }
    refusalReason = `compiled_context REFUSED, standard_context used instead. ${parts.join(" ALSO: ")}`;
  }

  const elig = report.exp0004_eligibility || {};
  const admission = {
    admission_version: ADMISSION_VERSION,
    tool: "build-os/compiler/entry/admit.mjs",
    wired: false,
    inert_note: "nothing in the runtime calls this tool; it is invoked by hand and gates nothing automatically",

    mode_requested: a.requested,
    mode_granted: granted,
    refused,
    refusal_reason: refusalReason,
    compiled_context_permitted: granted === "compiled_context",

    eligibility_rule_applied: ELIGIBILITY_RULE,
    eligibility_rule_parts: {
      amendment_1_passed: amendment1,
      recommended_use_state_is_not_bypass: notBypass,
      both_required: true,
      combined: eligible,
    },
    eligibility_timestamp: a.now !== null ? a.now : new Date().toISOString(),
    report_repo_commit: report.repo_head === undefined ? null : report.repo_head,
    report_repo_commit_note: (report.repo_head === null || report.repo_head === undefined)
      ? "the index recorded no repo_head, so the commit this evidence was computed against is NOT MEASURED; "
        + "activation.mjs refuses a run without an exact seed commit"
      : "the commit the capability report was computed against",

    eligibility_evidence: {
      source: "build-os/compiler/capability/report.mjs — consumed, never recomputed here",
      evidence_mode: a.index !== null ? "live run of the reporter" : "recorded run of the reporter",
      report_version: report.report_version,
      index_path: report.index_path === undefined ? null : report.index_path,
      capsule_path: report.capsule_path === undefined ? null : report.capsule_path,
      index_version: report.index_version === undefined ? null : report.index_version,
      files_indexed: report.files_indexed === undefined ? null : report.files_indexed,
      parser_coverage: textOf(report.parser_coverage && report.parser_coverage.real_extractor, "no parser coverage recorded"),
      no_parser_share: textOf(report.parser_coverage && report.parser_coverage.no_parser, "no no_parser share recorded"),
      admitted_no_parser_share: textOf(report.admitted_candidate_set && report.admitted_candidate_set.no_parser_share,
        "no admitted-candidate share recorded"),
      symbol_coverage: textOf(report.symbol_coverage && report.symbol_coverage.files_with_symbols, "no symbol coverage recorded"),
      symbols_extracted: report.symbol_coverage ? report.symbol_coverage.symbols_extracted : null,
      test_linkage_coverage: textOf(report.test_linkage_coverage && report.test_linkage_coverage.files_with_a_covering_test,
        "no test-linkage coverage recorded"),
      recommended_use_state: state === undefined ? null : state,
      recommendation_message: report.recommendation_message || null,
      recommendation_tests: report.recommendation_tests || null,
      eligibility_verdict: verdict === undefined ? null : verdict,
      eligibility_exact_test: elig.exact_test === undefined ? null : elig.exact_test,
      eligibility_threshold: elig.threshold === undefined ? null : elig.threshold,
      eligibility_measured_over: elig.measured_over === undefined ? null : elig.measured_over,
      report_repo_commit: report.repo_head === undefined ? null : report.repo_head,
      reporter_limitations: report.limitations || null,
    },
    capability_report: report,

    override_available: false,
    override_note: "no flag, argument or environment variable can force compiled_context past a refusal "
      + "during EXP-0004. The recognised names " + OVERRIDE_FLAGS.join(", ") + " exist ONLY to produce a "
      + "named refusal; none of them grants anything. This tool reads no environment variables.",
    limitations: [
      "eligibility is a statement about the INDEX, not a prediction that any capsule compiled from it is "
      + "correct or complete. An eligible repository can still produce a capsule that loses.",
      "the reporter's recommendation thresholds are derived defaults, not calibrated constants: nothing has "
      + "yet measured that they predict outcome quality.",
      "this admission gates MODE SELECTION only. It does not authorise a run: activation.mjs checks the "
      + "remaining preconditions, and neither tool starts anything.",
    ],
  };

  fs.writeFileSync(a.out, `${JSON.stringify(admission, null, 2)}\n`, "utf8");

  if (refused) {
    process.stderr.write(`admit: ${refusalReason}\nadmission written: ${a.out}\n`);
    process.exit(4);
  }
  process.stdout.write(`admit: ${granted} granted for ${a.requested === granted ? "the requested mode" : a.requested}; `
    + `verdict ${verdict}, use state ${state}; admission ${a.out}\n`);
  return 0;
}

const argv = process.argv.slice(2);
if (argv.length === 0 || argv[0] === "--help" || argv[0] === "-h") {
  process.stdout.write(USAGE);
  process.exit(argv.length === 0 ? 2 : 0);
}
if (argv[0] !== "admit") die(`unknown subcommand: ${argv[0]}\n${USAGE}`);
process.exit(admit(argv.slice(1)));
