#!/usr/bin/env node
// EXP-0013 deterministic acceptance ORACLE.
//
// Closes FAILURE-MODES.md row 7 (error-diff oracle line shifts) with an
// executable mechanism: acceptance compares error IDENTITY MULTISETS —
// (file, code, normalized message) with multiplicity — never line/column
// numbers. A fix that shifts every downstream line leaves the identity
// multiset of untouched files unchanged; a regression introduces an identity
// (or a higher multiplicity) that was not in the baseline and is detected.
//
// Acceptance (fixed): accepted iff
//   (a) the target file reports ZERO errors after, AND
//   (b) no error identity anywhere gained multiplicity vs the baseline
//       (new identities and increased counts are regressions — in ANY file).
// The oracle consumes raw tsc text only; it never runs a model and never
// consults outcome direction.

import crypto from "node:crypto";
const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");

const ERR_RE = /^([^\s(][^(]*)\((\d+),(\d+)\): error (TS\d+): (.*)$/;

/** Parse tsc --noEmit text output into error records (continuation lines folded). */
export function parseTsc(text) {
  const errs = [];
  let cur = null;
  for (const line of String(text).split("\n")) {
    const m = line.match(ERR_RE);
    if (m) { cur = { file: m[1].replace(/\\/g, "/"), line: +m[2], col: +m[3], code: m[4], msg: m[5] }; errs.push(cur); }
    else if (cur && /^\s/.test(line) && line.trim()) cur.msg += " " + line.trim();
    else cur = null;
  }
  return errs;
}

/** Line/column-free identity of one error. Message whitespace is collapsed. */
export function identity(e) {
  return `${e.file}|${e.code}|${e.msg.replace(/\s+/g, " ").trim()}`;
}

/** Identity MULTISET (Map identity -> count). Optional file filter. */
export function identityMultiset(errors, file = null) {
  const m = new Map();
  for (const e of errors) {
    if (file && e.file !== file) continue;
    const k = identity(e);
    m.set(k, (m.get(k) ?? 0) + 1);
  }
  return m;
}

/**
 * Deterministic acceptance. Inputs are the RAW baseline and after tsc texts.
 * Returns a full evidence record; `accepted` is the only judgment field and
 * it is a pure function of the two texts + target file.
 */
export function acceptance({ baselineText, afterText, targetFile }) {
  const before = parseTsc(baselineText), after = parseTsc(afterText);
  const beforeAll = identityMultiset(before), afterAll = identityMultiset(after);
  const targetBefore = identityMultiset(before, targetFile), targetAfter = identityMultiset(after, targetFile);
  const regressions = [];
  for (const [k, n] of afterAll) {
    const had = beforeAll.get(k) ?? 0;
    if (n > had) regressions.push({ identity: k, before: had, after: n });
  }
  const tBefore = [...targetBefore.values()].reduce((a, b) => a + b, 0);
  const tAfter = [...targetAfter.values()].reduce((a, b) => a + b, 0);
  return {
    artifact: "exp0013_oracle_acceptance",
    target_file: targetFile,
    target_errors_before: tBefore,
    target_errors_after: tAfter,
    total_errors_before: before.length,
    total_errors_after: after.length,
    regressions,
    comparison: "identity-multiset (file|code|normalized-msg) with multiplicity; line/column numbers NEVER consulted",
    baseline_sha256: sha(baselineText),
    after_sha256: sha(afterText),
    accepted: tAfter === 0 && regressions.length === 0,
  };
}

/**
 * Pre-launch task validation: proves each corpus task is real, initially
 * failing, hermetic (file exists in the archived tree), and regression-
 * sensitive (the oracle detects a synthetic new identity). No model runs.
 */
export function validateTask({ baselineText, task, treeRoot, fsMod }) {
  const fs = fsMod;
  const before = parseTsc(baselineText);
  const inFile = identityMultiset(before, task.file);
  const checks = [];
  const push = (name, ok, detail) => checks.push({ name, ok, detail });
  const n = [...inFile.values()].reduce((a, b) => a + b, 0);
  push("initially_failing", n > 0 && n === task.error_count, `${n} baseline errors in ${task.file} (corpus says ${task.error_count})`);
  push("hermetic_file_exists", fs.existsSync(`${treeRoot}/${task.file}`), `${task.file} present in archived tree`);
  const codesSeen = new Set([...inFile.keys()].map((k) => k.split("|")[1]));
  push("codes_match_corpus", task.codes.every((c) => codesSeen.has(c)) && [...codesSeen].every((c) => task.codes.includes(c)),
    `baseline codes {${[...codesSeen].sort().join(",")}} == corpus codes {${task.codes.join(",")}}`);
  // Regression sensitivity: inject a synthetic error identity and prove detection.
  const synthetic = baselineText + `\n${task.file}(1,1): error TS9999: synthetic regression probe.\n`;
  const probe = acceptance({ baselineText, afterText: synthetic, targetFile: "some/other/file.ts" });
  push("regression_sensitive", probe.accepted === false && probe.regressions.some((r) => r.identity.includes("TS9999")),
    "synthetic new identity detected as a regression");
  // Line-shift robustness: shift every line number; identity comparison must not flag it.
  const shifted = baselineText.replace(/\((\d+),(\d+)\)/g, (_, l, c) => `(${+l + 7},${c})`);
  const shiftProbe = acceptance({ baselineText, afterText: shifted, targetFile: "some/other/file.ts" });
  push("line_shift_robust", shiftProbe.regressions.length === 0, "uniform line shift produces zero false regressions");
  return { task_id: task.task_id, ok: checks.every((c) => c.ok), checks };
}
