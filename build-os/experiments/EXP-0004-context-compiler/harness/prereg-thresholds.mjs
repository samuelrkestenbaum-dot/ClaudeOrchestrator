// EXP-0004 — THE ONLY SOURCE OF THRESHOLDS.
//
// Every number this harness decides with is preregistered. This module holds
// each one as a constant PAIRED WITH THE PREREGISTRATION PHRASE IT COMES FROM,
// re-parses that phrase out of build-os/compiler/AB_PREREGISTRATION.md at load
// time, and REFUSES (throws) when the parsed value and the cited constant
// disagree. A threshold cannot be chosen from observed data here, and a
// preregistration edited after the fact cannot be silently adopted either:
// drift is a refusal, not a merge.
//
// Nothing in this file reads a clock or samples a random number. Ordering and
// thresholds are DERIVED, never sampled.
//
// Dependencies: node stdlib only.

import fs from "node:fs";

export const PREREG_FILENAME = "AB_PREREGISTRATION.md";

// key -> { value, phrase (with %NUM% where the number sits), rule }
// The phrase is matched against the preregistration with whitespace flattened,
// so a citation survives the file's line wrapping but not its content changing.
export const CITATIONS = [
  {
    key: "uncached_supported_pct",
    value: 25,
    phrase: "uncached-token reduction >= %NUM%% median across tasks",
    rule: "outcome 1 — `context compilation supported`",
  },
  {
    key: "detectable_pct",
    value: 10,
    phrase: "no median reduction >= %NUM%%",
    rule: "outcome 3 — `no context-compilation benefit detected`",
  },
  {
    key: "harm_increase_pct",
    value: 10,
    phrase: "uncached tokens HIGHER by >= %NUM%%",
    rule: "outcome 4 — `context compilation harmful`",
  },
  {
    key: "acceptance_band_pct",
    value: 10,
    phrase: "acceptance unchanged with tokens within +/-%NUM%%",
    rule: "outcome 3, second clause",
  },
  {
    key: "no_parser_max_pct",
    value: 50,
    phrase: "no_parser share of files admitted-as-candidates must be below %NUM%%",
    rule: "AMENDMENT 1 — eligibility precondition",
  },
];

// Sentences quoted verbatim by the tools. Absence is drift, and drift refuses.
export const QUOTED = {
  veto: "Compression that costs acceptance is a loss, not a trade.",
  amendment2_exclusion:
    "is registered `result confounded` under the existing stop conditions and is excluded from the aggregate",
  amendment1_disposition:
    "A repository failing that check is either excluded or the run is registered `result confounded`",
};

const escapeRe = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const flatten = (s) => s.replace(/\s+/g, " ");

export function defaultPreregPath() {
  // harness/ -> EXP-0004-context-compiler/ -> experiments/ -> build-os/
  return new URL(`../../../compiler/${PREREG_FILENAME}`, import.meta.url).pathname;
}

/**
 * Parse and cross-check every preregistered threshold.
 * Throws on: missing file, missing citation, or a parsed value that disagrees
 * with the constant cited beside it.
 */
export function loadThresholds(preregPath = defaultPreregPath()) {
  let text;
  try {
    text = fs.readFileSync(preregPath, "utf8");
  } catch {
    throw new Error(
      `preregistration not readable at ${preregPath} — no thresholds, no verdict`
    );
  }
  const flat = flatten(text);

  const values = {};
  const citations = [];
  for (const c of CITATIONS) {
    const re = new RegExp(escapeRe(c.phrase).replace("%NUM%", "(\\d+(?:\\.\\d+)?)"));
    const m = flat.match(re);
    if (!m) {
      throw new Error(
        `preregistered phrase not found in ${PREREG_FILENAME}: "${c.phrase.replace("%NUM%", String(c.value))}" ` +
          `(threshold ${c.key} cannot be sourced; refusing rather than inventing it)`
      );
    }
    const parsed = Number(m[1]);
    if (parsed !== c.value) {
      throw new Error(
        `PREREGISTRATION DRIFT: ${c.key} parses as ${parsed} but this harness cites ${c.value} ` +
          `from "${c.phrase.replace("%NUM%", String(c.value))}" (${c.rule}). ` +
          `A threshold that moved after registration is a refusal, not an update.`
      );
    }
    values[c.key] = c.value;
    citations.push({ ...c, phrase_rendered: c.phrase.replace("%NUM%", String(c.value)) });
  }

  for (const [name, sentence] of Object.entries(QUOTED)) {
    if (!flat.includes(flatten(sentence))) {
      throw new Error(
        `preregistered sentence "${name}" is absent from ${PREREG_FILENAME} — refusing to apply a rule the file no longer states`
      );
    }
  }

  return { values, citations, quoted: QUOTED, source: preregPath, source_name: PREREG_FILENAME };
}
