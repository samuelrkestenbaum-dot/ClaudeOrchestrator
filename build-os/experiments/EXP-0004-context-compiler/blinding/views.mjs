// EXP-0004 BLINDING — THE TWO SEPARATED VIEWS, AND THE ANONYMOUS VERDICT.
//
//   node views.mjs adjudicator         --records <f|dir> --sealed <f> --out <f>
//   node views.mjs analyst             --records <f|dir> --sealed <f> [--acceptance-frozen] --out <f>
//   node views.mjs fixture-adjudication --records <f|dir> --sealed <f> --out <f>
//   node views.mjs calculations        --analyst <f> --adjudication <f> --out <f>
//   node views.mjs provisional         --calculations <f> --exclusions <f> --eligibility <f> --out <f>
//   node views.mjs leakcheck           --view <f>
//
// THE SEPARATION THIS FILE ENFORCES. The EXECUTION layer may know which
// condition it is running — it has to, in order to select the right context
// path. The ACCEPTANCE ADJUDICATOR and the COMPARATIVE ANALYST may not.
//
//   adjudicator view — task id, an opaque work-product reference, the test
//     results, the acceptance question. NOTHING else. In particular NO
//     starting-context byte counts: an adjudicator who sees one unit start at
//     8 KB and its partner start at 180 KB has identified the conditions
//     instantly, and every acceptance judgement afterwards is contaminated.
//     Blinding the size is the cheap half of blinding the experiment.
//   analyst view — the full economic surface, under `Arm X` / `Arm Y` and
//     nothing else. Starting-context bytes and the expansion fields are
//     WITHHELD until acceptance is frozen, because those three fields are the
//     ones that identify the conditions on sight.
//
// BOTH VIEWS ARE CHECKED BEFORE THEY ARE WRITTEN. `leakcheck` scans a rendered
// view for eight forbidden strings, for any `arm` key, for a bare condition
// letter, and for repository paths (the experiment directory name is itself a
// give-away). A view that fails is REFUSED, not written with a warning — a
// warning is a leak that shipped.
//
// WHAT THIS FILE DELIBERATELY DOES NOT DO: it never states a registered
// outcome. The provisional verdict it computes is expressed in `Arm X` /
// `Arm Y` terms only; translating it into the registered vocabulary requires
// the sealed mapping and therefore happens in reveal.mjs, after the freeze.
//
// Invoke via node; this file is deliberately NOT executable.
// Exit: 0 fine; 2 refusal. Dependencies: node stdlib only.

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { validateRecord } from "../harness/measure.mjs";
import { loadThresholds, defaultPreregPath } from "../harness/prereg-thresholds.mjs";
import { readSealed, labelOf, LABEL_X, LABEL_Y, LABELS, EXPERIMENT } from "./seal-mapping.mjs";

/**
 * The sha256 of the sealed mapping — the SAME digest that is committed before
 * the run. Every blinded artifact carries it, so the reveal can refuse a seal
 * that did not produce the artifact it is being asked to translate. Carrying it
 * leaks nothing ON ITS OWN: recomputing the bit from the digest needs the salt,
 * and the salt lives inside the withheld sealed file. THAT IS ALSO THE
 * LIMITATION — publishing the salt before the reveal breaks the blind outright,
 * so the salt is withheld on exactly the same terms as the mapping.
 */
const digestOfSeal = (raw) => crypto.createHash("sha256").update(raw).digest("hex");

const UNKNOWN = "-";

class Refusal extends Error {}
const refuse = (m) => {
  throw new Refusal(m);
};

// ------------------------------------------------------------- leak rules --

/** The eight strings the operator named. Case-insensitive, substring match. */
export const FORBIDDEN_STRINGS = [
  "standard_context",
  "compiled_context",
  "capsule",
  "compiler",
  "control",
  "treatment",
  "arm_a",
  "arm_b",
];

export const FORBIDDEN_PATTERNS = [
  { re: /\barm[\s_-]*[ab](?![a-z0-9])/i, why: "names an execution condition by its letter" },
  { re: /"arm"\s*:/i, why: "carries an `arm` key" },
  { re: /"[^"]*\/(build-os|experiments)\//, why: "embeds a repository path, which names the experiment directory" },
];

/** Every leak found in a rendered view, as human sentences. */
export function findLeaks(text) {
  const found = [];
  const lower = text.toLowerCase();
  for (const s of FORBIDDEN_STRINGS) {
    if (lower.includes(s)) found.push(`the forbidden string '${s}' appears in the view`);
  }
  for (const p of FORBIDDEN_PATTERNS) {
    const m = text.match(p.re);
    if (m) found.push(`the view ${p.why} (matched ${JSON.stringify(m[0])})`);
  }
  return found;
}

const serialize = (obj) => JSON.stringify(obj, null, 2) + "\n";

/** Render, scan, and REFUSE rather than write a leaking view. */
function emit(obj, outPath, what) {
  const text = serialize(obj);
  const leaks = findLeaks(text);
  if (leaks.length) {
    refuse(
      `the ${what} would LEAK condition identity and was not written:\n  - ` +
        leaks.join("\n  - ") +
        `\nA blinded view that leaks is worse than no blinding, because it is trusted.`
    );
  }
  if (outPath) fs.writeFileSync(outPath, text);
  else process.stdout.write(text);
  return text;
}

// ------------------------------------------------------------ record load --

export function loadRecords(p) {
  let files;
  let stat;
  try {
    stat = fs.statSync(p);
  } catch {
    refuse(`records not readable: ${p}`);
  }
  const raws = [];
  if (stat.isDirectory()) {
    files = fs.readdirSync(p).filter((f) => f.endsWith(".json")).sort();
    if (!files.length) refuse(`no .json records in ${p}`);
    for (const f of files) raws.push([path.join(p, f), fs.readFileSync(path.join(p, f), "utf8")]);
  } else {
    raws.push([p, fs.readFileSync(p, "utf8")]);
  }
  const recs = [];
  for (const [file, raw] of raws) {
    let j;
    try {
      j = JSON.parse(raw);
    } catch (e) {
      refuse(`record is not valid JSON (${file}): ${e.message}`);
    }
    for (const r of Array.isArray(j) ? j : [j]) recs.push(validateRecord(r, path.basename(file)));
  }
  if (!recs.length) refuse(`no measurement record found in ${p}`);
  return recs;
}

const val = (rec, name) => rec.fields[name].value;

function labelled(recs, sealed) {
  return recs.map((r) => {
    const label = labelOf(sealed, r.task_id, r.arm);
    if (!label) {
      refuse(
        `task '${r.task_id}' is not in the sealed mapping — a record with no sealed label cannot be blinded, ` +
          `and analysing it unblinded is the thing this tool exists to prevent`
      );
    }
    const u = sealed.units.find((x) => x.task_id === r.task_id && x.arm === r.arm);
    return { rec: r, label, unit_id: u.unit_id };
  });
}

// ------------------------------------------------------------------ views --

export function adjudicatorView(recs, sealed, mappingDigest) {
  const units = labelled(recs, sealed)
    .map(({ rec, unit_id }) => ({
      unit_id,
      task_id: rec.task_id,
      work_product_ref: `wp-${unit_id}.diff`,
      tests_run: val(rec, "tests_run"),
      tests_passed: val(rec, "tests_passed"),
      acceptance_question:
        "Does the work product referenced above satisfy this task's registered acceptance criteria, judged on its own merits?",
    }))
    // Ordered by the OPAQUE id, so the ordering itself does not pair a unit
    // with the condition that produced it.
    .sort((a, b) => (a.unit_id < b.unit_id ? -1 : a.unit_id > b.unit_id ? 1 : 0));

  return {
    view: "adjudicator",
    experiment: EXPERIMENT,
    mapping_digest: mappingDigest,
    purpose: "task-level acceptance, and nothing else",
    blinding_note:
      "This view is BLINDED. It carries no execution-condition identity, no starting-context byte counts, " +
      "no expansion fields and no mode names. Each task appears as two units; which unit came from which " +
      "execution condition is sealed and is not recoverable from anything below.",
    withheld: [
      "starting-context byte counts",
      "expansion byte counts and expansion request counts",
      "token and elapsed economics",
      "execution mode names",
      "the analysis labels themselves",
    ],
    n_units: units.length,
    units,
  };
}

/** Fields the analyst sees only after acceptance is frozen. */
export const WITHHELD_UNTIL_FROZEN = ["starting_context_bytes", "expansion_bytes", "context_expansions"];

const ANALYST_FIELDS = [
  "total_tokens",
  "uncached_tokens",
  "time_to_first_meaningful_edit_s",
  "total_elapsed_s",
  "files_read",
  "search_operations",
  "failed_hypotheses",
  "rework_rounds",
  "verifier_dispatches",
  "tests_run",
  "tests_passed",
  "acceptance_result",
  "regressions",
  "human_interventions",
];

export function analystView(recs, sealed, acceptanceFrozen, mappingDigest) {
  const units = labelled(recs, sealed)
    .map(({ rec, label, unit_id }) => {
      const u = { unit_id, task_id: rec.task_id, label };
      for (const f of ANALYST_FIELDS) u[f] = val(rec, f);
      if (acceptanceFrozen) for (const f of WITHHELD_UNTIL_FROZEN) u[f] = val(rec, f);
      return u;
    })
    .sort((a, b) => (a.task_id + a.label < b.task_id + b.label ? -1 : 1));

  return {
    view: "analyst",
    experiment: EXPERIMENT,
    mapping_digest: mappingDigest,
    acceptance_frozen: acceptanceFrozen === true,
    labels: LABELS,
    aggregate_analysis_valid: sealed.aggregate_analysis_valid === true,
    blinding_note:
      "Units are labelled 'Arm X' and 'Arm Y'. The mapping from these labels to execution conditions is sealed " +
      "and its sha256 was committed before the run. It is opened only after acceptance, exclusions, every " +
      "economic field, every calculation and an anonymous provisional verdict are frozen.",
    withholding_note: acceptanceFrozen
      ? "Acceptance is frozen, so the starting-size and expansion fields are released."
      : "Starting-size and expansion fields are WITHHELD until acceptance is frozen: a unit that starts at 8 KB " +
        "beside a partner that starts at 180 KB identifies its condition on sight, and an analyst who knows which " +
        "label is which is not blinded.",
    withheld_until_acceptance_frozen: acceptanceFrozen
      ? []
      : ["starting-context byte counts", "expansion byte counts", "expansion request counts"],
    n_units: units.length,
    units,
  };
}

/**
 * A STAND-IN for the human/agent adjudicator, so the demonstration flow can run
 * end to end. It reads the acceptance already recorded by the execution layer.
 * It is marked FIXTURE everywhere so it can never be mistaken for a judgement.
 */
export function fixtureAdjudication(recs, sealed) {
  const units = labelled(recs, sealed)
    .map(({ rec, unit_id }) => ({
      unit_id,
      task_id: rec.task_id,
      acceptance_result: val(rec, "acceptance_result"),
      regressions: val(rec, "regressions"),
    }))
    .sort((a, b) => (a.unit_id < b.unit_id ? -1 : 1));
  return {
    artifact: "adjudication",
    experiment: EXPERIMENT,
    source:
      "FIXTURE — a simulated adjudication that echoes the acceptance the execution layer recorded. A real run " +
      "REPLACES this with an adjudication produced from the adjudicator view by someone who cannot see this file.",
    n_units: units.length,
    units,
  };
}

// ----------------------------------------------------- AMENDMENT 3 ------ --

// Same discipline as the harness's prereg-thresholds.mjs: every number is a
// constant PAIRED WITH THE PHRASE it is parsed from, and disagreement refuses.
export const AMENDMENT3_CITATIONS = [
  {
    key: "elapsed_gate_pct",
    value: 25,
    phrase: "median elapsed time >= %NUM%% faster",
    rule: "AMENDMENT 3.3, criterion 3",
  },
  {
    key: "elapsed_meaningful_pct",
    value: 25,
    phrase: "| >= %NUM%% faster | meaningful acceleration |",
    rule: "AMENDMENT 3.2, band 1",
  },
  {
    key: "elapsed_directional_pct",
    value: 10,
    phrase: "| %NUM%% - 24.9% faster | directional improvement, not independently decisive |",
    rule: "AMENDMENT 3.2, band 2",
  },
];

export const AMENDMENT3_QUOTED = {
  min_pairs: "fewer than FIVE completed un-confounded task-pairs",
  canonical_wording: "Canonical wording is `result confounded` (with a space) in all published text",
  four_gates: "The `supported` verdict requires ALL FOUR",
};

export const MIN_PAIRS = 5;

/** The SEVEN registered outcomes, in AMENDMENT 3.1's order. Verbatim. */
export const SEVEN_OUTCOMES = [
  "supported",
  "compression only",
  "acceleration only",
  "inconclusive",
  "context compilation harmful",
  "small-because-uninformed",
  "result confounded",
];

export const OUTCOME_CODES = {
  supported: "supported",
  "compression only": "compression_only",
  "acceleration only": "acceleration_only",
  inconclusive: "inconclusive",
  "context compilation harmful": "context_compilation_harmful",
  "small-because-uninformed": "small_because_uninformed",
  "result confounded": "result_confounded",
};

const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const flatten = (s) => s.replace(/\s+/g, " ");

export function loadAmendment3(preregPath = defaultPreregPath()) {
  let text;
  try {
    text = fs.readFileSync(preregPath, "utf8");
  } catch {
    refuse(`preregistration not readable at ${preregPath} — no thresholds, no verdict`);
  }
  const flat = flatten(text);
  const values = {};
  const citations = [];
  for (const c of AMENDMENT3_CITATIONS) {
    const re = new RegExp(escapeRe(c.phrase).replace("%NUM%", "(\\d+(?:\\.\\d+)?)"));
    const m = flat.match(re);
    if (!m) {
      refuse(
        `preregistered phrase not found: "${c.phrase.replace("%NUM%", String(c.value))}" (${c.rule}) — ` +
          `refusing to apply a threshold the file no longer states`
      );
    }
    if (Number(m[1]) !== c.value) {
      refuse(
        `PREREGISTRATION DRIFT: ${c.key} parses as ${m[1]} but this tool cites ${c.value} (${c.rule}). ` +
          `A threshold that moved after registration is a refusal, not an update.`
      );
    }
    values[c.key] = c.value;
    citations.push({ ...c, phrase_rendered: c.phrase.replace("%NUM%", String(c.value)) });
  }
  for (const [name, sentence] of Object.entries(AMENDMENT3_QUOTED)) {
    if (!flat.includes(flatten(sentence))) {
      refuse(`preregistered sentence "${name}" is absent from the preregistration — refusing to apply a rule the file no longer states`);
    }
  }
  for (const o of SEVEN_OUTCOMES) {
    if (!flat.includes("`" + o + "`")) {
      refuse(`registered outcome \`${o}\` is absent from AMENDMENT 3.1 — the vocabulary this tool emits is not the registered one`);
    }
  }
  return { values, citations, min_pairs: MIN_PAIRS, source: preregPath };
}

/** AMENDMENT 3.2's bands, applied to "how much faster the subject is". */
export function elapsedBand(pct) {
  if (pct >= 25) return "meaningful acceleration";
  if (pct >= 10) return "directional improvement, not independently decisive";
  if (pct > -10) return "no meaningful elapsed-time difference";
  if (pct > -25) return "directional harm";
  return "meaningful harm";
}

// ----------------------------------------------------------- arithmetic ---

export function median(xs) {
  const s = [...xs].sort((a, b) => a - b);
  const n = s.length;
  if (n === 0) return null;
  return n % 2 ? s[(n - 1) / 2] : (s[n / 2 - 1] + s[n / 2]) / 2;
}
const round1 = (x) => Math.round(x * 10) / 10;
const reduction = (ref, subject) => ((ref - subject) / ref) * 100;
const relKey = (subject, ref) => `${subject} relative to ${ref}`;

function need(u, field, where) {
  const v = u[field];
  if (v === undefined) refuse(`${where}: unit ${u.unit_id} has no ${field}`);
  if (v === UNKNOWN) {
    refuse(
      `${where}: unit ${u.unit_id} (${u.task_id}) has an unmeasured ${field} ('-'). An admission is never averaged ` +
        `as a zero — exclude the pair or measure the field.`
    );
  }
  return v;
}

export function calculations(analyst, adjudication) {
  if (analyst.view !== "analyst") refuse("--analyst must be an analyst view");
  if (analyst.acceptance_frozen !== true) {
    refuse(
      "the analyst view is NOT acceptance-frozen. Economics may not be computed before acceptance is frozen: " +
        "an analyst who can still move acceptance while watching the token numbers is not blinded in any useful sense."
    );
  }
  if (analyst.aggregate_analysis_valid !== true) {
    refuse(
      "the sealed mapping labels units per task rather than per experiment, so a label denotes a MIXTURE of " +
        "execution conditions across the task set. A median taken over it compares nothing. Re-seal with the " +
        "experiment-scope rule before aggregating."
    );
  }
  if (!adjudication || !Array.isArray(adjudication.units)) refuse("--adjudication must carry a units array");

  const byUnit = new Map(adjudication.units.map((u) => [u.unit_id, u]));
  for (const u of analyst.units) {
    const a = byUnit.get(u.unit_id);
    if (!a) refuse(`the adjudication has no verdict for unit ${u.unit_id} (${u.task_id})`);
    if (a.acceptance_result !== u.acceptance_result) {
      refuse(
        `acceptance DISAGREEMENT on unit ${u.unit_id} (${u.task_id}): the adjudication says ` +
          `${JSON.stringify(a.acceptance_result)} and the analyst view says ${JSON.stringify(u.acceptance_result)}. ` +
          `The frozen acceptance is the adjudicator's; a silent reconciliation here would let economics edit acceptance.`
      );
    }
  }

  const tasks = [...new Set(analyst.units.map((u) => u.task_id))].sort();
  const per_task = [];
  const dU = { [relKey(LABEL_X, LABEL_Y)]: [], [relKey(LABEL_Y, LABEL_X)]: [] };
  const dT = { [relKey(LABEL_X, LABEL_Y)]: [], [relKey(LABEL_Y, LABEL_X)]: [] };

  for (const t of tasks) {
    const ux = analyst.units.find((u) => u.task_id === t && u.label === LABEL_X);
    const uy = analyst.units.find((u) => u.task_id === t && u.label === LABEL_Y);
    if (!ux || !uy) refuse(`task ${t} does not have one unit for each label — a matched pair is required`);
    const xu = need(ux, "uncached_tokens", "calculations");
    const yu = need(uy, "uncached_tokens", "calculations");
    const xt = need(ux, "total_elapsed_s", "calculations");
    const yt = need(uy, "total_elapsed_s", "calculations");
    if (xu <= 0 || yu <= 0) refuse(`task ${t}: an uncached-token count is zero; a reduction against it is undefined`);
    if (xt <= 0 || yt <= 0) refuse(`task ${t}: an elapsed time is zero; a reduction against it is undefined`);

    const uXY = reduction(yu, xu);
    const uYX = reduction(xu, yu);
    const tXY = reduction(yt, xt);
    const tYX = reduction(xt, yt);
    dU[relKey(LABEL_X, LABEL_Y)].push(uXY);
    dU[relKey(LABEL_Y, LABEL_X)].push(uYX);
    dT[relKey(LABEL_X, LABEL_Y)].push(tXY);
    dT[relKey(LABEL_Y, LABEL_X)].push(tYX);

    per_task.push({
      task_id: t,
      uncached_tokens: { [LABEL_X]: xu, [LABEL_Y]: yu },
      total_tokens: { [LABEL_X]: need(ux, "total_tokens", "calculations"), [LABEL_Y]: need(uy, "total_tokens", "calculations") },
      total_elapsed_s: { [LABEL_X]: xt, [LABEL_Y]: yt },
      acceptance: { [LABEL_X]: ux.acceptance_result, [LABEL_Y]: uy.acceptance_result },
      uncached_reduction_pct: { [relKey(LABEL_X, LABEL_Y)]: round1(uXY), [relKey(LABEL_Y, LABEL_X)]: round1(uYX) },
      elapsed_reduction_pct: { [relKey(LABEL_X, LABEL_Y)]: round1(tXY), [relKey(LABEL_Y, LABEL_X)]: round1(tYX) },
    });
  }

  const acceptance = {};
  const totals = {};
  for (const L of LABELS) {
    const us = analyst.units.filter((u) => u.label === L);
    const acc = us.filter((u) => u.acceptance_result === "accepted").length;
    acceptance[L] = { accepted: acc, n: us.length, rate: us.length ? acc / us.length : 0 };
    totals[L] = {};
    for (const f of ["rework_rounds", "human_interventions", "failed_hypotheses", "verifier_dispatches", "regressions"]) {
      totals[L][f] = us.reduce((s, u) => s + (u[f] === UNKNOWN ? 0 : u[f]), 0);
    }
  }

  const medU = {};
  const medT = {};
  const bands = {};
  for (const k of Object.keys(dU)) {
    medU[k] = round1(median(dU[k]));
    medT[k] = round1(median(dT[k]));
    bands[k] = elapsedBand(median(dT[k]));
  }

  return {
    artifact: "calculations",
    experiment: EXPERIMENT,
    mapping_digest: analyst.mapping_digest,
    computed_from:
      "the analyst view alone. Units are labelled 'Arm X' and 'Arm Y'; the mapping from those labels to " +
      "execution conditions is sealed, so nothing below can be read as a statement about either condition.",
    labels: LABELS,
    n_pairs: tasks.length,
    acceptance,
    totals,
    per_task,
    aggregate: {
      median_uncached_reduction_pct: medU,
      median_elapsed_reduction_pct: medT,
      elapsed_band: bands,
      reading_note:
        "'P relative to Q' is how much LOWER (or faster) P is than Q, as a percentage of Q. A negative figure " +
        "means P is higher, or slower. Both directions are recorded so the reveal can select the one it needs " +
        "without recomputing anything.",
    },
  };
}

export function provisional(calc, exclusions, eligibility, th3, thTokens) {
  if (calc.artifact !== "calculations") refuse("--calculations must be a calculations artifact");
  const confounds = Array.isArray(exclusions?.confounds_recorded) ? exclusions.confounds_recorded : [];
  const inadequate = eligibility?.signal_inadequate === true;

  const acc = calc.acceptance;
  let acceptance_shortfall_for = null;
  if (acc[LABEL_X].rate < acc[LABEL_Y].rate) acceptance_shortfall_for = LABEL_X;
  else if (acc[LABEL_Y].rate < acc[LABEL_X].rate) acceptance_shortfall_for = LABEL_Y;

  const medU = calc.aggregate.median_uncached_reduction_pct;
  const medT = calc.aggregate.median_elapsed_reduction_pct;
  const uGate = thTokens.uncached_supported_pct;
  const tGate = th3.values.elapsed_gate_pct;

  const gateMet = (m, g) => {
    const hits = Object.entries(m).filter(([, v]) => v >= g);
    return hits.length === 1 ? hits[0][0].split(" relative to ")[0] : null;
  };
  const token_gate_met_for = gateMet(medU, uGate);
  const elapsed_gate_met_for = gateMet(medT, tGate);

  const worse = {};
  for (const L of LABELS) {
    const other = L === LABEL_X ? LABEL_Y : LABEL_X;
    worse[L] =
      calc.totals[L].rework_rounds > calc.totals[other].rework_rounds ||
      calc.totals[L].human_interventions > calc.totals[other].human_interventions;
  }
  const rework_or_intervention_increase_for = worse[LABEL_X] && !worse[LABEL_Y] ? LABEL_X : worse[LABEL_Y] && !worse[LABEL_X] ? LABEL_Y : null;

  let anonymous_label;
  if (confounds.length) anonymous_label = "confounded";
  else if (inadequate) anonymous_label = "signal_inadequate";
  else if (acceptance_shortfall_for) anonymous_label = `acceptance_shortfall_for:${acceptance_shortfall_for}`;
  else if (token_gate_met_for && token_gate_met_for === elapsed_gate_met_for) anonymous_label = `both_gates_met_for:${token_gate_met_for}`;
  else if (token_gate_met_for) anonymous_label = `token_gate_only_for:${token_gate_met_for}`;
  else if (elapsed_gate_met_for) anonymous_label = `elapsed_gate_only_for:${elapsed_gate_met_for}`;
  else anonymous_label = "no_gate_met";

  return {
    artifact: "anonymous_provisional_verdict",
    experiment: EXPERIMENT,
    mapping_digest: calc.mapping_digest,
    computed_from:
      "'Arm X' and 'Arm Y' alone. This artifact states NO registered outcome, because choosing one requires the " +
      "sealed mapping. It is frozen first and translated afterwards, in that order and never the other way.",
    n_pairs: calc.n_pairs,
    minimum_pairs_rule: {
      minimum: th3.min_pairs,
      met: calc.n_pairs >= th3.min_pairs,
      quoted: AMENDMENT3_QUOTED.min_pairs,
      source: "AMENDMENT 3.5, a derived default the operator may replace before the run",
    },
    confounded: confounds.length > 0,
    confounds_recorded: confounds,
    signal_inadequate: inadequate,
    acceptance: {
      [LABEL_X]: `${acc[LABEL_X].accepted}/${acc[LABEL_X].n}`,
      [LABEL_Y]: `${acc[LABEL_Y].accepted}/${acc[LABEL_Y].n}`,
      shortfall_for: acceptance_shortfall_for,
    },
    uncached_tokens: {
      median_reduction_pct: medU,
      gate_threshold_pct: uGate,
      harm_threshold_pct: thTokens.harm_increase_pct,
      gate_met_for: token_gate_met_for,
    },
    elapsed: {
      median_reduction_pct: medT,
      gate_threshold_pct: tGate,
      band: calc.aggregate.elapsed_band,
      gate_met_for: elapsed_gate_met_for,
    },
    totals: calc.totals,
    rework_or_intervention_increase_for,
    anonymous_label,
    thresholds_cited: th3.citations.map((c) => ({ key: c.key, value: c.value, phrase: c.phrase_rendered, rule: c.rule })),
  };
}

// -------------------------------------------------------------------- CLI --

const USAGE =
  "usage: views.mjs adjudicator          --records <f|dir> --sealed <f> --out <f>\n" +
  "       views.mjs analyst              --records <f|dir> --sealed <f> [--acceptance-frozen] --out <f>\n" +
  "       views.mjs fixture-adjudication --records <f|dir> --sealed <f> --out <f>\n" +
  "       views.mjs calculations         --analyst <f> --adjudication <f> --out <f>\n" +
  "       views.mjs provisional          --calculations <f> --exclusions <f> --eligibility <f> --out <f>\n" +
  "       views.mjs leakcheck            --view <f>\n";

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

function cli(argv) {
  const cmd = argv[0];
  const rest = argv.slice(1);
  const opt = {};
  for (let i = 0; i < rest.length; i++) {
    const k = rest[i];
    if (k === "--records") opt.records = rest[++i];
    else if (k === "--sealed") opt.sealed = rest[++i];
    else if (k === "--out") opt.out = rest[++i];
    else if (k === "--acceptance-frozen") opt.frozen = true;
    else if (k === "--analyst") opt.analyst = rest[++i];
    else if (k === "--adjudication") opt.adjudication = rest[++i];
    else if (k === "--calculations") opt.calculations = rest[++i];
    else if (k === "--exclusions") opt.exclusions = rest[++i];
    else if (k === "--eligibility") opt.eligibility = rest[++i];
    else if (k === "--view") opt.view = rest[++i];
    else if (k === "--prereg") opt.prereg = rest[++i];
    else {
      process.stderr.write(`views: unknown option: ${k}\n${USAGE}`);
      return 2;
    }
  }
  try {
    if (cmd === "leakcheck") {
      if (!opt.view) refuse("leakcheck needs --view <f>");
      let text;
      try {
        text = fs.readFileSync(opt.view, "utf8");
      } catch {
        refuse(`view not readable: ${opt.view}`);
      }
      const leaks = findLeaks(text);
      if (leaks.length) refuse(`the view LEAKS condition identity:\n  - ` + leaks.join("\n  - "));
      process.stdout.write(`leak_free: ${opt.view}\n`);
      return 0;
    }
    if (cmd === "adjudicator" || cmd === "analyst" || cmd === "fixture-adjudication") {
      if (!opt.records) refuse(`${cmd} needs --records <f|dir>`);
      if (!opt.sealed) refuse(`${cmd} needs --sealed <f>`);
      const { sealed, raw } = readSealed(opt.sealed);
      const md = digestOfSeal(raw);
      const recs = loadRecords(opt.records);
      const obj =
        cmd === "adjudicator"
          ? adjudicatorView(recs, sealed, md)
          : cmd === "analyst"
          ? analystView(recs, sealed, opt.frozen === true, md)
          : fixtureAdjudication(recs, sealed);
      emit(obj, opt.out, `${cmd} view`);
      return 0;
    }
    if (cmd === "calculations") {
      if (!opt.analyst || !opt.adjudication) refuse("calculations needs --analyst <f> and --adjudication <f>");
      const out = calculations(readJson(opt.analyst, "analyst view"), readJson(opt.adjudication, "adjudication"));
      emit(out, opt.out, "calculations");
      return 0;
    }
    if (cmd === "provisional") {
      if (!opt.calculations) refuse("provisional needs --calculations <f>");
      if (!opt.exclusions) refuse("provisional needs --exclusions <f>");
      if (!opt.eligibility) refuse("provisional needs --eligibility <f>");
      const th3 = loadAmendment3(opt.prereg || defaultPreregPath());
      const thTokens = loadThresholds(opt.prereg || defaultPreregPath()).values;
      const out = provisional(
        readJson(opt.calculations, "calculations"),
        readJson(opt.exclusions, "exclusion decisions"),
        readJson(opt.eligibility, "eligibility record"),
        th3,
        thTokens
      );
      emit(out, opt.out, "anonymous provisional verdict");
      return 0;
    }
    if (cmd === "-h" || cmd === "--help" || cmd === undefined) {
      process.stdout.write(USAGE);
      return 0;
    }
    refuse(`unknown subcommand: ${cmd}`);
  } catch (e) {
    process.stderr.write(`views: REFUSED — ${e.message}\n`);
    return 2;
  }
  return 2;
}

const invoked =
  process.argv[1] && fs.realpathSync(process.argv[1]) === fs.realpathSync(fileURLToPath(import.meta.url));
if (invoked) process.exit(cli(process.argv.slice(2)));
