#!/usr/bin/env node
// EXP-0004 — THE VERDICT, APPLIED MECHANICALLY.
//
//   node verdict.mjs --aggregate <aggregate.json> [--prereg <file>] [--json]
//
// This tool chooses nothing. Every threshold it decides with is parsed out of
// build-os/compiler/AB_PREREGISTRATION.md and cross-checked against the
// constant cited beside it (see prereg-thresholds.mjs); a threshold supplied on
// the command line is REFUSED, and a preregistration whose numbers have moved
// since registration is REFUSED rather than silently adopted. Thresholds and
// task selection may not be derived from observed data. That is the whole point
// of preregistering them.
//
// TWO VOCABULARIES ARE REPORTED, DELIBERATELY
//
//   preregistered_verdict — one of the FIVE outcomes the preregistration
//     registers, which it says are the only wording permitted. This is the
//     publishable verdict.
//   operator_verdict — one of the SEVEN labels the operator asked this harness
//     to distinguish. Three of them (`compression only`, `acceleration only`,
//     `small-because-uninformed`) are NOT in the preregistered five, so they are
//     reported as a refinement mapped back onto the five, never as a substitute.
//     See AMBIGUITY-3 below; the tool refuses to resolve it silently.
//
// THE RULE, IN ORDER (each line names the preregistration text it applies)
//
//   0. harness/seeding/arm-isolation defect recorded, or nothing admitted
//        -> `result confounded`                          (prereg outcome 5, Stop conditions)
//   1. eligibility or capsule signal says the capsule was compact for lack of
//      index signal
//        -> `small-because-uninformed`                    (AMENDMENT 1)
//   2. arm B acceptance rate LOWER than arm A, or uncached tokens HIGHER by
//      >= harm_increase_pct
//        -> `context compilation harmful`                 (prereg outcome 4)
//   3. acceptance not worse AND median uncached reduction >= uncached_supported_pct
//      AND median elapsed reduction >= the same figure (borrowed; see AMBIGUITY-2)
//        -> `supported`                                   (prereg outcome 1)
//   4. as (3) but the elapsed reduction is smaller
//        -> `compression only`                            (prereg outcome 1)
//   5. acceptance not worse, elapsed reduction >= threshold, token reduction below it
//        -> `acceleration only`                           (prereg outcome 2 or 3)
//   6. otherwise
//        -> `inconclusive`                                (prereg outcome 2 or 3)
//
// THE ACCEPTANCE VETO IS BINDING AND SEPARATE. After the rule above runs, an
// independent gate re-checks acceptance: if arm B's acceptance rate is lower
// than arm A's, the verdict CANNOT be `supported`, `compression only`, or
// `acceleration only`, whatever the token or time figures say. The
// preregistration's own sentence, quoted from the file:
// "Compression that costs acceptance is a loss, not a trade."
//
// An unknown is never averaged as a zero: an admitted task whose uncached,
// elapsed, or acceptance figure is '-' REFUSES the whole aggregate, because a
// median computed over an admission is a fabrication.
//
// Invoke via node; this file is deliberately NOT executable.
// Exit: 0 a verdict was produced; 2 refusal. Dependencies: node stdlib only.

import fs from "node:fs";
import { fileURLToPath } from "node:url";
import { loadThresholds, defaultPreregPath } from "./prereg-thresholds.mjs";

const UNKNOWN = "-";

export const OPERATOR_VERDICTS = [
  "supported",
  "compression only",
  "acceleration only",
  "inconclusive",
  "context compilation harmful",
  "small-because-uninformed",
  "result confounded",
];

export const PREREG_VERDICTS = [
  "context compilation supported",
  "promising but underpowered",
  "no context-compilation benefit detected",
  "context compilation harmful",
  "result confounded",
];

// Ambiguities in the preregistration text that this tool had to navigate. They
// are properties of the FILE, not of the data, so they are reported on every
// run. Naming them is the alternative to resolving them silently.
export const AMBIGUITIES = [
  {
    id: "AMBIGUITY-1",
    text:
      "AMENDMENT 1 calls small-because-uninformed 'the exact failure mode outcome 4 names' (harmful) while its BINDING clause says such a repository 'is either excluded or the run is registered result confounded'. This tool follows the binding clause and maps small-because-uninformed to `result confounded`; it does not adopt the prose gloss.",
  },
  {
    id: "AMBIGUITY-2",
    text:
      "The preregistration registers no wall-clock threshold at all — 35-65% faster appears only as a HYPOTHESIS, never as a decision rule. `supported` vs `compression only` vs `acceleration only` therefore BORROW the uncached-token thresholds for elapsed time. The borrowing is disclosed, not invented, and a wall-clock threshold should be registered before the run if these three labels are to be published.",
  },
  {
    id: "AMBIGUITY-3",
    text:
      "The preregistration registers FIVE outcomes and says 'no other wording permitted'; the operator asked this harness for SEVEN labels, of which `compression only`, `acceleration only`, and `small-because-uninformed` are not among the five. Both are reported; the preregistered_verdict is the publishable one.",
  },
  {
    id: "AMBIGUITY-4",
    text:
      "Outcome 2 includes 'task count too small to separate' but registers NO minimum n. This tool applies no n-based rule and reports underpowered_by_n: '-'. Inventing a minimum after seeing the data is exactly what preregistration forbids.",
  },
  {
    id: "AMBIGUITY-5",
    text:
      "The primary combined metric 'accepted durable outcomes / (uncached tokens + elapsed + human attention)' sums three quantities with different units and no stated weights. It is computed literally and used ONLY for direction (does it favour B?), never as a magnitude.",
  },
  {
    id: "AMBIGUITY-6",
    text:
      "Outcomes 2 and 3 overlap: a result can simultaneously 'favour B with a reduction under 25%' and show 'no median reduction >= 10%'. The preregistration does not order them. This tool checks outcome 3's conditions first and records that ordering here.",
  },
];

class Refusal extends Error {}
const refuse = (m) => {
  throw new Refusal(m);
};

// ------------------------------------------------------------------- math --

export function median(xs) {
  const s = [...xs].sort((a, b) => a - b);
  const n = s.length;
  if (n === 0) return null;
  return n % 2 ? s[(n - 1) / 2] : (s[n / 2 - 1] + s[n / 2]) / 2;
}

const pctReduction = (a, b) => ((a - b) / a) * 100;
const round1 = (x) => Math.round(x * 10) / 10;

function measured(task, arm, field) {
  const v = task[arm] ? task[arm][field] : undefined;
  if (v === undefined) {
    refuse(`admitted task ${task.task_id}: arm ${arm.toUpperCase()} has no ${field}`);
  }
  if (v === UNKNOWN) {
    refuse(
      `admitted task ${task.task_id}: arm ${arm.toUpperCase()} ${field} is unmeasured ('-'). ` +
        `An admission cannot enter a median — a '-' is never averaged as a zero. Exclude the task or measure the field.`
    );
  }
  return v;
}

function acceptanceRate(tasks, arm) {
  let accepted = 0;
  for (const t of tasks) {
    const v = measured(t, arm, "acceptance_result");
    if (v !== "accepted" && v !== "rejected") {
      refuse(`admitted task ${t.task_id}: arm ${arm.toUpperCase()} acceptance_result is ${JSON.stringify(v)}`);
    }
    if (v === "accepted") accepted++;
  }
  return { rate: accepted / tasks.length, accepted, n: tasks.length };
}

function primaryMetric(tasks, arm) {
  // AMBIGUITY-5: computed literally as written, used for DIRECTION only.
  let accepted = 0;
  let denom = 0;
  for (const t of tasks) {
    if (measured(t, arm, "acceptance_result") === "accepted") accepted++;
    denom += measured(t, arm, "uncached_tokens");
    denom += measured(t, arm, "total_elapsed_s");
    const hi = t[arm].human_interventions;
    denom += hi === UNKNOWN || hi === undefined ? 0 : hi;
  }
  return denom > 0 ? accepted / denom : null;
}

// ---------------------------------------------------------------- verdict --

export function decide(agg, th) {
  const tasks = Array.isArray(agg.tasks) ? agg.tasks : [];
  if (typeof agg.n_admitted === "number" && agg.n_admitted !== tasks.length) {
    refuse(
      `aggregate is internally inconsistent: n_admitted=${agg.n_admitted} but ${tasks.length} task(s) are listed. ` +
        `The verdict is not computed over a count that does not match its own data.`
    );
  }
  const confounds = Array.isArray(agg.harness_confounds) ? agg.harness_confounds : [];

  const out = {
    n_admitted: tasks.length,
    n_excluded_confounded: agg.n_excluded_confounded ?? 0,
    harness_confounds: confounds,
    underpowered_by_n: UNKNOWN, // AMBIGUITY-4: no minimum n is preregistered.
  };

  // -- 0. confounds ---------------------------------------------------------
  if (confounds.length > 0) {
    out.operator_verdict = "result confounded";
    out.preregistered_verdict = "result confounded";
    out.reason = `a defect in harness, seeding, or arm isolation is recorded: ${confounds.join("; ")}`;
    out.acceptance_veto_applied = false;
    return out;
  }
  if (tasks.length === 0) {
    out.operator_verdict = "result confounded";
    out.preregistered_verdict = "result confounded";
    out.reason = "no task survived admission — there is nothing to compare";
    out.acceptance_veto_applied = false;
    return out;
  }

  // -- measurements ---------------------------------------------------------
  const dU = [];
  const dT = [];
  for (const t of tasks) {
    const ua = measured(t, "a", "uncached_tokens");
    const ub = measured(t, "b", "uncached_tokens");
    const ta = measured(t, "a", "total_elapsed_s");
    const tb = measured(t, "b", "total_elapsed_s");
    if (ua <= 0) refuse(`admitted task ${t.task_id}: arm A uncached_tokens is ${ua}; a reduction against it is undefined`);
    if (ta <= 0) refuse(`admitted task ${t.task_id}: arm A total_elapsed_s is ${ta}; a reduction against it is undefined`);
    dU.push(pctReduction(ua, ub));
    dT.push(pctReduction(ta, tb));
  }
  const accA = acceptanceRate(tasks, "a");
  const accB = acceptanceRate(tasks, "b");
  const medU = median(dU);
  const medT = median(dT);
  const primA = primaryMetric(tasks, "a");
  const primB = primaryMetric(tasks, "b");
  const favoursB = primA !== null && primB !== null && primB > primA;

  Object.assign(out, {
    median_uncached_reduction_pct: round1(medU),
    median_elapsed_reduction_pct: round1(medT),
    acceptance_rate_a: `${accA.accepted}/${accA.n}`,
    acceptance_rate_b: `${accB.accepted}/${accB.n}`,
    primary_metric_direction: favoursB ? "favours B" : primA === primB ? "flat" : "favours A",
  });

  // -- 1. eligibility / capsule signal (AMENDMENT 1) ------------------------
  const unin = uninformed(agg, th);
  if (unin.uninformed) {
    out.operator_verdict = "small-because-uninformed";
    out.preregistered_verdict = "result confounded";
    out.reason = `${unin.reason} — a capsule that is small for lack of index signal is not evidence of compression (AMENDMENT 1); mapped per AMBIGUITY-1`;
    out.acceptance_veto_applied = accB.rate < accA.rate;
    return out;
  }

  // -- 2. harm --------------------------------------------------------------
  if (accB.rate < accA.rate) {
    out.operator_verdict = "context compilation harmful";
    out.preregistered_verdict = "context compilation harmful";
    out.reason = `arm B's acceptance rate (${accB.accepted}/${accB.n}) is LOWER than arm A's (${accA.accepted}/${accA.n})`;
    out.acceptance_veto_applied = true;
    return out;
  }
  if (medU <= -th.harm_increase_pct) {
    out.operator_verdict = "context compilation harmful";
    out.preregistered_verdict = "context compilation harmful";
    out.reason = `arm B's median uncached tokens are HIGHER by ${round1(-medU)}%, at or beyond the preregistered ${th.harm_increase_pct}%`;
    out.acceptance_veto_applied = false;
    return out;
  }

  // -- 3..6. wins and non-results ------------------------------------------
  const tokenWin = medU >= th.uncached_supported_pct;
  const timeWin = medT >= th.uncached_supported_pct; // borrowed: AMBIGUITY-2
  let label;
  if (tokenWin && timeWin) label = "supported";
  else if (tokenWin) label = "compression only";
  else if (timeWin) label = "acceleration only";
  else label = "inconclusive";

  out.operator_verdict = label;
  out.acceptance_veto_applied = false;
  if (label === "supported" || label === "compression only") {
    out.preregistered_verdict = "context compilation supported";
    out.reason =
      `acceptance is not worse (${accB.accepted}/${accB.n} vs ${accA.accepted}/${accA.n}) and the median uncached reduction ` +
      `is ${round1(medU)}%, at or beyond the preregistered ${th.uncached_supported_pct}%`;
  } else {
    // AMBIGUITY-6: outcome 3's conditions are tested before outcome 2's.
    const noBenefit =
      (medU < th.detectable_pct && medT < th.detectable_pct) ||
      (accB.rate === accA.rate && Math.abs(medU) <= th.acceptance_band_pct && medT < th.detectable_pct);
    if (noBenefit) {
      out.preregistered_verdict = "no context-compilation benefit detected";
      out.reason =
        `no median reduction reaches the preregistered ${th.detectable_pct}% (uncached ${round1(medU)}%, elapsed ${round1(medT)}%)`;
    } else {
      out.preregistered_verdict = "promising but underpowered";
      out.reason =
        `the direction ${favoursB ? "favours B" : "does not clearly favour B"} on the primary metric but the uncached reduction ` +
        `(${round1(medU)}%) is below the preregistered ${th.uncached_supported_pct}%`;
    }
  }
  return out;
}

function uninformed(agg, th) {
  const e = agg.eligibility || {};
  if (typeof e.no_parser_share_pct === "number" && e.no_parser_share_pct >= th.no_parser_max_pct) {
    return {
      uninformed: true,
      reason: `the index's no_parser share is ${e.no_parser_share_pct}%, at or beyond the preregistered ${th.no_parser_max_pct}% ceiling`,
    };
  }
  const cs = agg.capsule_signal;
  if (cs && typeof cs.files_indexed === "number" && typeof cs.files_with_symbols === "number" && cs.files_indexed > 0) {
    const share = (cs.files_with_symbols / cs.files_indexed) * 100;
    if (share < 100 - th.no_parser_max_pct) {
      return {
        uninformed: true,
        reason: `only ${round1(share)}% of indexed files carry extracted symbols, below the ${100 - th.no_parser_max_pct}% implied by AMENDMENT 1's ceiling`,
      };
    }
  }
  if (cs && cs.uninformed === true) {
    return { uninformed: true, reason: "the capsule signal record states the capsule was compact for lack of index signal" };
  }
  return { uninformed: false, reason: null };
}

/**
 * THE BINDING ACCEPTANCE-QUALITY VETO, as its own gate.
 * A win that costs acceptance cannot be reported as a win, no matter what the
 * token or time figures say.
 */
export function applyAcceptanceVeto(result, quotedSentence) {
  const WINS = ["supported", "compression only", "acceleration only"];
  const a = result.acceptance_rate_a;
  const b = result.acceptance_rate_b;
  if (!a || !b) return result;
  const rate = (s) => {
    const [x, y] = s.split("/").map(Number);
    return y ? x / y : 0;
  };
  if (rate(b) < rate(a)) {
    result.acceptance_veto_applied = true;
    if (WINS.includes(result.operator_verdict)) {
      result.verdict_before_veto = result.operator_verdict;
      result.operator_verdict = "context compilation harmful";
      result.preregistered_verdict = "context compilation harmful";
      result.reason =
        `ACCEPTANCE VETO: arm B accepted ${b} against arm A's ${a}. "${quotedSentence}" ` +
        `A token or time win cannot buy back a lost acceptance.`;
    }
    result.acceptance_veto_reason =
      `arm B acceptance ${b} < arm A acceptance ${a} — "${quotedSentence}" (AB_PREREGISTRATION.md)`;
  }
  return result;
}

// -------------------------------------------------------------- rendering --

function toText(res, th) {
  const L = [];
  L.push(`verdict — EXP-0004 context compiler A/B`);
  L.push("");
  L.push(`operator_verdict: ${res.operator_verdict}`);
  L.push(`preregistered_verdict: ${res.preregistered_verdict}`);
  L.push(`acceptance_veto_applied: ${res.acceptance_veto_applied === true}`);
  if (res.verdict_before_veto) L.push(`verdict_before_veto: ${res.verdict_before_veto}`);
  if (res.acceptance_veto_reason) L.push(`acceptance_veto_reason: ${res.acceptance_veto_reason}`);
  L.push(`reason: ${res.reason}`);
  L.push("");
  L.push("== measurements over ADMITTED tasks only ==");
  L.push(`n_admitted: ${res.n_admitted}`);
  L.push(`n_excluded_confounded: ${res.n_excluded_confounded}`);
  for (const k of [
    "median_uncached_reduction_pct",
    "median_elapsed_reduction_pct",
    "acceptance_rate_a",
    "acceptance_rate_b",
    "primary_metric_direction",
  ]) {
    if (res[k] !== undefined) L.push(`${k}: ${res[k]}`);
  }
  L.push(`underpowered_by_n: ${res.underpowered_by_n}`);
  L.push("");
  L.push(`== thresholds — taken ONLY from ${th.source_name}, parsed and cross-checked ==`);
  L.push(`source: ${th.source}`);
  for (const c of th.citations) {
    L.push(`${c.key}: ${c.value}   <- "${c.phrase_rendered}"   [${c.rule}]`);
  }
  L.push("");
  L.push("== preregistration ambiguities — named, not resolved silently ==");
  for (const a of AMBIGUITIES) L.push(`${a.id}: ${a.text}`);
  return L.join("\n") + "\n";
}

// -------------------------------------------------------------------- CLI --

const USAGE = "usage: verdict.mjs --aggregate <aggregate.json> [--prereg <file>] [--json]\n";

const OVERRIDE_PREFIXES = ["--threshold", "--min", "--max", "--override", "--set-", "--force", "--assume", "--n-", "--select"];

function cli(argv) {
  const opt = {};
  for (let i = 0; i < argv.length; i++) {
    const k = argv[i];
    if (k === "--aggregate") opt.aggregate = argv[++i];
    else if (k === "--prereg") opt.prereg = argv[++i];
    else if (k === "--json") opt.json = true;
    else if (k === "-h" || k === "--help") {
      process.stdout.write(USAGE);
      return 0;
    } else if (OVERRIDE_PREFIXES.some((p) => k.startsWith(p))) {
      process.stderr.write(
        `verdict: REFUSED — ${k} would override a PREREGISTERED value. Thresholds and task selection are fixed in ` +
          `AB_PREREGISTRATION.md before the data exists; choosing them afterwards is the failure preregistration prevents. ` +
          `Amend the preregistration in a commit, or accept the registered rule.\n`
      );
      return 2;
    } else {
      process.stderr.write(`verdict: unknown option: ${k}\n${USAGE}`);
      return 2;
    }
  }
  try {
    if (!opt.aggregate) refuse("verdict needs --aggregate <aggregate.json>");
    const th = loadThresholds(opt.prereg || defaultPreregPath());
    let agg;
    try {
      agg = JSON.parse(fs.readFileSync(opt.aggregate, "utf8"));
    } catch (e) {
      refuse(`aggregate not readable or not JSON (${opt.aggregate}): ${e.message}`);
    }
    let res = decide(agg, th.values);
    res = applyAcceptanceVeto(res, th.quoted.veto);
    if (!OPERATOR_VERDICTS.includes(res.operator_verdict)) refuse(`internal: '${res.operator_verdict}' is not a registered label`);
    if (!PREREG_VERDICTS.includes(res.preregistered_verdict)) refuse(`internal: '${res.preregistered_verdict}' is not a preregistered outcome`);
    if (opt.json) {
      process.stdout.write(
        JSON.stringify({ ...res, thresholds: th.values, threshold_source: th.source, ambiguities: AMBIGUITIES }, null, 2) + "\n"
      );
    } else {
      process.stdout.write(toText(res, th));
    }
    return 0;
  } catch (e) {
    process.stderr.write(`verdict: REFUSED — ${e.message}\n`);
    return 2;
  }
}

const invoked =
  process.argv[1] && fs.realpathSync(process.argv[1]) === fs.realpathSync(fileURLToPath(import.meta.url));
if (invoked) process.exit(cli(process.argv.slice(2)));
