// EXP-0004 BLINDING — THE ONE-WAY REVEAL.
//
//   node reveal.mjs --snapshot <f> --inputs <dir> --verdict <f>
//                   --sealed <f> --committed-digest <f> --at <ISO-8601> --out <f>
//
// THIS IS THE ONLY DOOR OUT OF THE BLIND, AND IT OPENS ONCE. Four conditions
// must all hold, and each unmet one is named in the refusal:
//
//   1. the freeze snapshot exists AND VALIDATES against the frozen inputs;
//   2. the ANONYMOUS PROVISIONAL VERDICT exists and states no registered
//      outcome (a "provisional verdict" that already names the answer is the
//      reveal happening early under another name);
//   3. the sealed mapping's sha256 equals the digest COMMITTED before the run —
//      so a mapping edited after the numbers were seen cannot be used;
//   4. the reveal timestamp is SUPPLIED. This tool reads no clock, because a
//      harness that reads a clock produces a record nobody can reproduce.
//
// WHAT THE TRANSLATION DOES. Before this point the analysis says things like
// "the token gate is met for Arm Y". That sentence is TRUE UNDER EITHER
// MAPPING, which is the whole value of the blind: the same numbers translate
// to `compression only` if Arm Y is the compiled condition and to `context
// compilation harmful` if it is not. Only the seal decides, and the seal was
// fixed before the data existed.
//
// The output vocabulary is AMENDMENT 3.1's SEVEN outcomes, verbatim, with the
// machine code emitted alongside the canonical wording as 3.1 requires.
//
// Invoke via node; this file is deliberately NOT executable.
// Exit: 0 revealed; 2 refusal. Dependencies: node stdlib only.

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { readSealed, readCommittedDigest, LABEL_X, LABEL_Y, EXPERIMENT } from "./seal-mapping.mjs";
import { verify as verifySnapshot } from "./freeze.mjs";
import {
  SEVEN_OUTCOMES,
  OUTCOME_CODES,
  loadAmendment3,
  elapsedBand,
} from "./views.mjs";
import { loadThresholds, defaultPreregPath } from "../harness/prereg-thresholds.mjs";

class Refusal extends Error {}
const refuse = (m) => {
  throw new Refusal(m);
};

const sha256hex = (buf) => crypto.createHash("sha256").update(buf).digest("hex");
const serialize = (obj) => JSON.stringify(obj, null, 2) + "\n";

function readJson(file, what) {
  let raw;
  try {
    raw = fs.readFileSync(file, "utf8");
  } catch {
    refuse(`UNMET CONDITION — ${what} is not readable at ${file}`);
  }
  try {
    return JSON.parse(raw);
  } catch (e) {
    refuse(`UNMET CONDITION — ${what} is not valid JSON (${file}): ${e.message}`);
  }
}

/** The experiment-scope label of each execution condition. */
export function conditionLabels(sealed) {
  if (sealed.rule_scope !== "experiment" || !sealed.label_map) {
    refuse(
      "the sealed mapping labels units per task, so no single label denotes one execution condition across the " +
        "task set and an aggregate verdict cannot be translated. Re-seal with the experiment-scope rule."
    );
  }
  const A = sealed.label_map.A;
  const B = sealed.label_map.B;
  if (![LABEL_X, LABEL_Y].includes(A) || ![LABEL_X, LABEL_Y].includes(B) || A === B) {
    refuse(`the sealed label map is malformed: ${JSON.stringify(sealed.label_map)}`);
  }
  return { A, B };
}

/**
 * Translate an ANONYMOUS provisional verdict into AMENDMENT 3.1's vocabulary,
 * using the now-revealed mapping. Every branch cites the rule it applies.
 */
export function translate(prov, labels, th, th3) {
  const { A, B } = labels;
  const key = `${B} relative to ${A}`;
  const tokens = prov.uncached_tokens?.median_reduction_pct?.[key];
  const elapsed = prov.elapsed?.median_reduction_pct?.[key];

  const decide = () => {
    if (prov.confounded === true) {
      return {
        outcome: "result confounded",
        reason: `a defect in harness, seeding or arm isolation is recorded: ${(prov.confounds_recorded || []).join("; ")}`,
        rule: "AMENDMENT 3.1 — the run is invalid, not the thesis",
      };
    }
    if (prov.signal_inadequate === true) {
      return {
        outcome: "small-because-uninformed",
        reason: "the index lacked structural signal, so a small starting context does not represent useful compression",
        rule: "AMENDMENT 3.1 — the thesis was not really tested",
      };
    }
    if (typeof tokens !== "number" || typeof elapsed !== "number") {
      return {
        outcome: "result confounded",
        reason: `the anonymous verdict carries no median for "${key}", so no gate can be evaluated`,
        rule: "AMENDMENT 3.1 — a measurement boundary was violated",
      };
    }
    if (prov.acceptance?.shortfall_for === B) {
      return {
        outcome: "context compilation harmful",
        reason:
          `the compiled condition accepted ${prov.acceptance[B]} against ${prov.acceptance[A]}. ` +
          `"${th.quoted.veto}" A token or time win cannot buy back a lost acceptance.`,
        rule: "the binding acceptance veto",
        veto: true,
      };
    }
    if (tokens <= -th.values.harm_increase_pct) {
      return {
        outcome: "context compilation harmful",
        reason: `the compiled condition's median uncached tokens are HIGHER by ${Math.abs(tokens)}%, at or beyond the preregistered ${th.values.harm_increase_pct}%`,
        rule: "outcome 4 — the thesis was tested and lost",
      };
    }
    const tokenWin = tokens >= th.values.uncached_supported_pct;
    const timeWin = elapsed >= th3.values.elapsed_gate_pct;
    const reworkHarm = prov.rework_or_intervention_increase_for === B;
    if (reworkHarm) {
      return {
        outcome: "inconclusive",
        reason:
          "AMENDMENT 3.3's fourth criterion — no material increase in human intervention or rework — is not met " +
          "for the compiled condition, and the remaining labels are explicitly 'subject to the remaining criteria'",
        rule: "AMENDMENT 3.3, criterion 4",
      };
    }
    if (tokenWin && timeWin) {
      return {
        outcome: "supported",
        reason: `all four of AMENDMENT 3.3's criteria are met: acceptance intact, uncached tokens ${tokens}% lower (>= ${th.values.uncached_supported_pct}%), elapsed ${elapsed}% faster (>= ${th3.values.elapsed_gate_pct}%), no rework or intervention increase`,
        rule: "AMENDMENT 3.3 — all four",
      };
    }
    if (tokenWin) {
      return {
        outcome: "compression only",
        reason: `the token criterion is met (${tokens}% >= ${th.values.uncached_supported_pct}%) but the elapsed criterion is not (${elapsed}% < ${th3.values.elapsed_gate_pct}%); band: ${elapsedBand(elapsed)}`,
        rule: "AMENDMENT 3.3 — a token win with < 25% elapsed improvement",
      };
    }
    if (timeWin) {
      return {
        outcome: "acceleration only",
        reason: `the elapsed criterion is met (${elapsed}% >= ${th3.values.elapsed_gate_pct}%) but the token criterion is not (${tokens}% < ${th.values.uncached_supported_pct}%)`,
        rule: "AMENDMENT 3.3 — an elapsed win without the token criterion",
      };
    }
    return {
      outcome: "inconclusive",
      reason: `neither criterion is met with acceptance intact (uncached ${tokens}%, elapsed ${elapsed}%)`,
      rule: "AMENDMENT 3.3 — meeting neither, with acceptance intact",
    };
  };

  let d = decide();
  let downgraded_from = null;
  const n = prov.n_pairs;
  if (typeof n === "number" && n < th3.min_pairs && (d.outcome === "supported" || d.outcome === "context compilation harmful")) {
    downgraded_from = d.outcome;
    d = {
      outcome: "inconclusive",
      reason: `${d.outcome} is unavailable at ${n} completed un-confounded task-pair(s); AMENDMENT 3.5 requires at least ${th3.min_pairs}. Prior reason: ${d.reason}`,
      rule: "AMENDMENT 3.5 — minimum n, a derived default the operator may replace",
    };
  }
  if (!SEVEN_OUTCOMES.includes(d.outcome)) refuse(`internal: '${d.outcome}' is not one of the seven registered outcomes`);
  return {
    ...d,
    code: OUTCOME_CODES[d.outcome],
    downgraded_from,
    median_uncached_reduction_pct_compiled_vs_current: tokens ?? null,
    median_elapsed_reduction_pct_compiled_vs_current: elapsed ?? null,
    elapsed_band_compiled_vs_current: typeof elapsed === "number" ? elapsedBand(elapsed) : null,
  };
}

const ANONYMOUS_PREFIXES = [
  "confounded",
  "signal_inadequate",
  "acceptance_shortfall_for",
  "both_gates_met_for",
  "token_gate_only_for",
  "elapsed_gate_only_for",
  "no_gate_met",
];

function checkAnonymous(prov, file) {
  if (prov?.artifact !== "anonymous_provisional_verdict") {
    refuse(`UNMET CONDITION — the anonymous provisional verdict is missing: ${file} is not an anonymous_provisional_verdict artifact`);
  }
  if (typeof prov.anonymous_label !== "string" || !ANONYMOUS_PREFIXES.some((p) => prov.anonymous_label.startsWith(p))) {
    refuse(`UNMET CONDITION — the anonymous provisional verdict carries no recognised anonymous label (got ${JSON.stringify(prov.anonymous_label)})`);
  }
  const text = JSON.stringify(prov);
  for (const o of SEVEN_OUTCOMES) {
    if (text.includes(o)) {
      refuse(
        `UNMET CONDITION — the "anonymous" provisional verdict already states the registered outcome '${o}'. ` +
          `A provisional verdict that names the answer is the reveal happening early under another name.`
      );
    }
  }
}

// -------------------------------------------------------------------- CLI --

const USAGE =
  "usage: reveal.mjs --snapshot <f> --inputs <dir> --verdict <f> --sealed <f> --committed-digest <f> --at <ISO-8601> --out <f>\n";

function cli(argv) {
  const opt = {};
  for (let i = 0; i < argv.length; i++) {
    const k = argv[i];
    if (k === "--snapshot") opt.snapshot = argv[++i];
    else if (k === "--inputs") opt.inputs = argv[++i];
    else if (k === "--verdict") opt.verdict = argv[++i];
    else if (k === "--sealed") opt.sealed = argv[++i];
    else if (k === "--committed-digest") opt.digest = argv[++i];
    else if (k === "--at") opt.at = argv[++i];
    else if (k === "--out") opt.out = argv[++i];
    else if (k === "--prereg") opt.prereg = argv[++i];
    else if (k === "-h" || k === "--help") {
      process.stdout.write(USAGE);
      return 0;
    } else {
      process.stderr.write(`reveal: unknown option: ${k}\n${USAGE}`);
      return 2;
    }
  }
  try {
    for (const [k, name] of [
      ["snapshot", "--snapshot <freeze snapshot>"],
      ["verdict", "--verdict <anonymous provisional verdict>"],
      ["sealed", "--sealed <sealed mapping>"],
      ["digest", "--committed-digest <mapping.sha256>"],
    ]) {
      if (!opt[k]) refuse(`UNMET CONDITION — ${name} was not supplied`);
    }
    if (!opt.at) {
      refuse(
        "UNMET CONDITION — the reveal timestamp must be SUPPLIED with --at. This tool reads no clock: a harness " +
          "that stamps its own time produces a record nobody else can reproduce."
      );
    }

    // 1. the freeze snapshot exists and validates -----------------------------
    const snap = readJson(opt.snapshot, "the freeze snapshot");
    const problems = verifySnapshot(snap, opt.inputs);
    if (problems.length) {
      refuse(`UNMET CONDITION — the freeze snapshot does not validate:\n  - ` + problems.join("\n  - "));
    }

    // 2. the anonymous provisional verdict exists and is still anonymous ------
    const prov = readJson(opt.verdict, "the anonymous provisional verdict");
    checkAnonymous(prov, opt.verdict);

    // 3. the seal matches the digest committed before the run -----------------
    const { sealed, raw } = readSealed(opt.sealed);
    const actual = sha256hex(raw);
    const committed = readCommittedDigest(opt.digest);
    if (actual !== committed) {
      refuse(
        `UNMET CONDITION — SEALED MAPPING DIGEST MISMATCH: the sealed mapping hashes to ${actual} but the digest ` +
          `committed before the run is ${committed}. A mapping that changed after the numbers were seen is not a ` +
          `commitment, and the reveal does not proceed on one.`
      );
    }
    if (sealed.experiment !== EXPERIMENT || prov.experiment !== EXPERIMENT) {
      refuse(`UNMET CONDITION — the seal and the verdict do not both belong to ${EXPERIMENT}`);
    }
    // A seal can be internally consistent and still be the WRONG seal. Every
    // blinded artifact records the digest of the mapping that produced it, so a
    // reveal cannot quietly translate one analysis with another run's mapping —
    // which would mistranslate silently and look perfectly well-formed.
    if (prov.mapping_digest && prov.mapping_digest !== actual) {
      refuse(
        `UNMET CONDITION — WRONG SEAL: the frozen anonymous verdict was produced under mapping ` +
          `${prov.mapping_digest} but the mapping supplied hashes to ${actual}. A self-consistent seal is not ` +
          `necessarily THE seal, and translating an analysis with someone else's mapping fails silently.`
      );
    }

    // 4. translate -----------------------------------------------------------
    const th = loadThresholds(opt.prereg || defaultPreregPath());
    const th3 = loadAmendment3(opt.prereg || defaultPreregPath());
    const labels = conditionLabels(sealed);
    const t = translate(prov, labels, th, th3);

    const audit = {
      artifact: "reveal_audit",
      experiment: EXPERIMENT,
      reveal_timestamp: opt.at,
      timestamp_source:
        "supplied on the command line by the operator; this tool reads no clock, so the record is reproducible",
      mapping_digest: committed,
      mapping_digest_source: `${path.basename(opt.digest)}, committed before the run`,
      seal_intact: true,
      freeze_snapshot_digest: snap.snapshot_digest,
      freeze_artifacts_verified: opt.inputs ? snap.artifacts.length : 0,
      sealed_rule_id: sealed.rule_id,
      sealed_rule_scope: sealed.rule_scope,
      sealed_rule_text: sealed.rule_text,
      revealed_mapping: {
        "current-execution condition (A)": labels.A,
        "compiled-context condition (B)": labels.B,
      },
      anonymous_label_before_reveal: prov.anonymous_label,
      anonymous_verdict_digest: sha256hex(serialize(prov)),
      n_pairs: prov.n_pairs,
      registered_outcome: t.outcome,
      registered_outcome_code: t.code,
      registered_vocabulary: SEVEN_OUTCOMES,
      canonical_wording_note:
        "AMENDMENT 3.1: the canonical wording and the machine code are emitted together so they cannot diverge.",
      translation_rule: t.rule,
      translation_reason: t.reason,
      acceptance_veto_applied: t.veto === true,
      downgraded_from: t.downgraded_from,
      median_uncached_reduction_pct_compiled_vs_current: t.median_uncached_reduction_pct_compiled_vs_current,
      median_elapsed_reduction_pct_compiled_vs_current: t.median_elapsed_reduction_pct_compiled_vs_current,
      elapsed_band_compiled_vs_current: t.elapsed_band_compiled_vs_current,
      one_way_note:
        "The reveal is one-way. Nothing downstream of this record may re-enter the frozen artifacts; a figure that " +
        "changes after this point invalidates the freeze snapshot and is visible as such.",
    };

    const text = serialize(audit);
    if (opt.out) fs.writeFileSync(opt.out, text);
    process.stdout.write(
      `REVEALED at ${opt.at}\n` +
        `mapping_digest: ${committed}\n` +
        `freeze_snapshot_digest: ${snap.snapshot_digest}\n` +
        `anonymous label before reveal: ${prov.anonymous_label}\n` +
        `registered_outcome: ${t.outcome}\n` +
        `registered_outcome_code: ${t.code}\n` +
        `reason: ${t.reason}\n` +
        (opt.out ? `audit: ${opt.out}\n` : text)
    );
    return 0;
  } catch (e) {
    process.stderr.write(`reveal: REFUSED — ${e.message}\n`);
    return 2;
  }
}

const invoked =
  process.argv[1] && fs.realpathSync(process.argv[1]) === fs.realpathSync(fileURLToPath(import.meta.url));
if (invoked) process.exit(cli(process.argv.slice(2)));
