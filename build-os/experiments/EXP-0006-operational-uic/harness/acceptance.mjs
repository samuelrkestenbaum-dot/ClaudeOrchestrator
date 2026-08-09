// EXP-0006 — ACCEPTANCE, computed from the compiler and nothing else.
//
// The frozen rule, quoted from PREREGISTRATION.md:
//
//   A task is ACCEPTED when both hold:
//     1. `npx tsc --noEmit` reports ZERO errors for that file, and
//     2. no new error appears in any other file.
//   `@ts-ignore`, `@ts-expect-error`, `any` casts and deleting the offending
//   code are REJECTIONS, checked by diff.
//
// Nothing here is a judgement call, which is the point: EXP-0005's acceptance
// needed an adjudicator's opinion about whether a change was really the work,
// and an opinion is exactly what a blinded benchmark cannot cheaply obtain.
//
// TWO IMPLEMENTATION DECISIONS, STATED BECAUSE THEY COULD BE WRONG QUIETLY.
//
// (a) Condition 2 compares error SETS KEYED BY (file, code, message), with line
//     and column DISCARDED. Editing a file shifts every line below the edit, so
//     a line-keyed comparison would report dozens of "new" errors for a change
//     that introduced none. Discarding position is therefore not laxity — a
//     position-keyed comparison would be WRONG, not stricter.
//
// (b) A regression is any error present after that was not present before, in
//     any file other than the task file. Errors DISAPPEARING elsewhere are not
//     penalised: fixing a type at its source legitimately clears its consumers.
//
// (c) ABSOLUTE PATHS ARE NORMALISED OUT OF MESSAGE TEXT BEFORE KEYING. This was
//     found by the pilot, on the first arm, and it is recorded here rather than
//     quietly patched. tsc embeds absolute paths in some messages:
//
//       baseline: Property 'x' does not exist on type
//                 'typeof import("/home/user/empathiq-website/drizzle/schema")'
//       arm tree: Property 'x' does not exist on type
//                 'typeof import("/home/user/exp0006-arm/drizzle/schema")'
//
//     These are the SAME pre-existing error. Keyed on raw text they hash
//     differently, so the baseline comparison reported five untouched files as
//     regressions and rejected an arm that had cleanly fixed its file in three
//     lines. Every arm would have been rejected identically, in both conditions
//     — a defect that damages both arms is still a defect, because it destroys
//     the numerator for everyone.
//
//     THE FROZEN ACCEPTANCE RULE IS UNCHANGED. "No new error appears in any
//     other file" is exactly what is being computed; normalising the tree root
//     out of the message removes an ENVIRONMENT difference that was masquerading
//     as a code difference. The count of normalisations applied is REPORTED on
//     every unit, so this can never become a silent rewrite of the comparison,
//     and the mutation tests prove a genuinely new error is still caught after
//     normalisation.
//
// THE REJECTION PATTERNS ARE CHECKED ON ADDED LINES ONLY. Scanning the whole
// file would reject a task whose file already contained an `any` before the arm
// touched it, which measures the seed rather than the work.

import fs from "node:fs";

const ERR = /^([^(\s][^(]*)\((\d+),(\d+)\): error (TS\d+): (.*)$/;

/** Parse tsc output into positioned and position-free forms. */
export function parseErrors(raw) {
  const rows = [];
  for (const line of String(raw).split("\n")) {
    const m = line.match(ERR);
    if (!m) continue;
    const [, file, ln, col, code, msg] = m;
    rows.push({ file, line: Number(ln), col: Number(col), code, msg: msg.trim() });
  }
  return rows;
}

/**
 * Tree roots whose appearance INSIDE MESSAGE TEXT is an environment difference,
 * not a code difference. See decision (c). Listed explicitly rather than matched
 * by a general /home/user/... pattern: a broad pattern would also erase a real
 * path difference that happened to live under the same parent.
 */
export const TREE_ROOTS = ["/home/user/empathiq-website", "/home/user/exp0006-arm"];

/** Replace any known tree root with a stable placeholder, and count the hits. */
export function normaliseMsg(msg, roots = TREE_ROOTS) {
  let out = String(msg), n = 0;
  for (const r of roots) {
    if (!r) continue;
    const parts = out.split(r);
    n += parts.length - 1;
    out = parts.join("<REPO>");
  }
  return { msg: out, normalisations: n };
}

/** Position-free key, with environment paths normalised out. See (a) and (c). */
export const key = (e) => `${e.file} ${e.code} ${normaliseMsg(e.msg).msg}`;

export function byFile(rows) {
  const m = new Map();
  for (const r of rows) {
    if (!m.has(r.file)) m.set(r.file, []);
    m.get(r.file).push(r);
  }
  return m;
}

/**
 * The rejection patterns, each applied ONLY to lines the diff ADDED.
 * `deletion` is deliberately not a regex: it is measured from the diff's own
 * add/remove balance for the task file, because "deleted the offending code"
 * has no textual signature.
 */
export const REJECTION_PATTERNS = [
  { id: "ts_ignore",        re: /@ts-ignore/,                     why: "suppresses the error instead of fixing it" },
  { id: "ts_expect_error",  re: /@ts-expect-error/,               why: "suppresses the error instead of fixing it" },
  { id: "ts_nocheck",       re: /@ts-nocheck/,                    why: "disables checking for the whole file" },
  { id: "any_cast",         re: /\bas\s+any\b|:\s*any\b|<any>/,   why: "erases the type rather than satisfying it" },
];

/**
 * Scan a unified diff for rejection patterns on ADDED lines within the task
 * file's sections, and measure the add/remove balance for the deletion test.
 */
export function scanDiff(diff, taskFile) {
  const sections = String(diff).split(/(?=^diff --git )/m).filter(Boolean);
  const hits = [], removedHits = [];
  const addedCount = {}, removedCount = {};
  let added = 0, removed = 0, sectionFound = false;

  for (const s of sections) {
    const m = /^diff --git a\/(\S+) b\/(\S+)/m.exec(s);
    const p = m ? m[2] : null;
    if (p !== taskFile) continue;
    sectionFound = true;
    for (const line of s.split("\n")) {
      if (line.startsWith("+++") || line.startsWith("---")) continue;
      const body = line.slice(1);
      if (line.startsWith("+")) {
        added++;
        for (const rp of REJECTION_PATTERNS) if (rp.re.test(body)) {
          addedCount[rp.id] = (addedCount[rp.id] || 0) + 1;
          hits.push({ pattern: rp.id, why: rp.why, line: body.trim().slice(0, 160) });
        }
      } else if (line.startsWith("-")) {
        removed++;
        for (const rp of REJECTION_PATTERNS) if (rp.re.test(body)) {
          removedCount[rp.id] = (removedCount[rp.id] || 0) + 1;
          removedHits.push({ pattern: rp.id, line: body.trim().slice(0, 160) });
        }
      }
    }
  }

  // NET INTRODUCTION. A pattern counts only where its occurrences on ADDED
  // lines exceed its occurrences on REMOVED lines.
  //
  // Added-line matching alone was not enough, and the pilot proved it on
  // T03/native. A MODIFIED line appears in a unified diff as both a removal and
  // an addition, so an arm that improved this line:
  //
  //   - issues: (auditResult.issues || []).map((i: any) => ({
  //   + issues: (auditResult.issues || []).map((i: any): Issue => ({
  //
  // was charged with introducing an `any` that was already there. It had added
  // a return type — strictly better typing — and was rejected for it.
  //
  // Everything the rule exists for survives: replacing a typed line with an
  // `any` version is 1 added / 0 removed and still rejects; an added
  // @ts-ignore is 1/0 and still rejects. Carrying a pre-existing `any` through
  // a line you improved is 1/1 and does not.
  //
  // KNOWN RESIDUAL WEAKNESS, recorded rather than hidden: counting can be
  // cancelled by coincidence. An arm that adds an `any` on one line while
  // deleting an unrelated line that happened to contain one nets to zero and
  // escapes. Per-line pairing would catch it, but reliably matching "the same
  // line, modified" across a unified diff is guesswork, and a WRONG pairing
  // rejects honest work. The asymmetry decides it: a false rejection destroys
  // the numerator outright, while a false acceptance still has to satisfy
  // conditions 1 and 2, which are computed by the compiler and independent of
  // this scan. Both counts are reported so the case is visible if it occurs.
  const net = {};
  for (const rp of REJECTION_PATTERNS) {
    const n = (addedCount[rp.id] || 0) - (removedCount[rp.id] || 0);
    if (n > 0) net[rp.id] = n;
  }

  return {
    section_found: sectionFound, added, removed,
    pattern_added_counts: addedCount, pattern_removed_counts: removedCount,
    net_introduced: net,
    rejection_hits: hits.filter((h) => net[h.pattern] > 0),
    hits_offset_by_removals: hits.filter((h) => !(net[h.pattern] > 0)),
    removed_pattern_lines: removedHits,
  };
}

/**
 * Adjudicate one task. `baseline` and `after` are raw tsc output strings.
 * Returns the full evidence, not just a boolean — a bare verdict cannot be
 * re-checked by anyone who did not run it.
 */
export function adjudicate({ baselineRaw, afterRaw, taskFile, diff }) {
  const before = parseErrors(baselineRaw);
  const after = parseErrors(afterRaw);

  const beforeKeys = new Set(before.map(key));
  const taskErrorsBefore = before.filter((e) => e.file === taskFile);
  const taskErrorsAfter = after.filter((e) => e.file === taskFile);

  // Condition 1
  const condition_1 = taskErrorsAfter.length === 0;

  // Condition 2 — new errors ANYWHERE ELSE.
  const newElsewhere = after.filter((e) => e.file !== taskFile && !beforeKeys.has(key(e)));
  const condition_2 = newElsewhere.length === 0;

  // REPORTED, not silent. If normalisation is doing heavy lifting on a unit,
  // that is visible on the unit rather than buried in a helper — the whole
  // reason this exists is that an invisible environment difference was being
  // scored as a code difference.
  const normalisations =
    before.reduce((s, e) => s + normaliseMsg(e.msg).normalisations, 0) +
    after.reduce((s, e) => s + normaliseMsg(e.msg).normalisations, 0);

  // Rejection scan
  const scan = scanDiff(diff || "", taskFile);
  // "Deleted the offending code" — the file lost more than it gained AND the
  // errors vanished. Stated as a heuristic, and reported as such rather than
  // silently folded into the verdict as if it were the compiler's word.
  const deletion_suspected = scan.section_found && scan.removed > 0 && scan.added === 0;
  const rejected_by_diff = scan.rejection_hits.length > 0 || deletion_suspected;

  const accepted = condition_1 && condition_2 && !rejected_by_diff;

  return {
    accepted,
    task_file: taskFile,
    condition_1_zero_errors_in_file: {
      pass: condition_1,
      errors_before: taskErrorsBefore.length,
      errors_after: taskErrorsAfter.length,
      remaining: taskErrorsAfter.slice(0, 20).map((e) => `${e.code} ${e.msg}`),
    },
    condition_2_no_new_errors_elsewhere: {
      pass: condition_2,
      new_error_count: newElsewhere.length,
      new_errors: newElsewhere.slice(0, 20).map((e) => `${e.file}: ${e.code} ${e.msg}`),
    },
    diff_rejection: {
      rejected: rejected_by_diff,
      hits: scan.rejection_hits,
      net_introduced: scan.net_introduced,
      pattern_added_counts: scan.pattern_added_counts,
      pattern_removed_counts: scan.pattern_removed_counts,
      hits_offset_by_removals: scan.hits_offset_by_removals,
      deletion_suspected,
      lines_added: scan.added,
      lines_removed: scan.removed,
      note: "patterns are matched on ADDED lines only; matching the whole file would reject a task for `any` casts the seed already contained",
    },
    total_errors_before: before.length,
    total_errors_after: after.length,
    path_normalisations_applied: normalisations,
    path_normalisation_note:
      "tsc embeds absolute paths in some messages, and the baseline tree and the arm tree sit at different paths. " +
      "Without normalising the tree root out, the SAME pre-existing error hashes differently and an untouched file " +
      "reads as a regression. The frozen acceptance rule is unchanged; an environment difference is removed, not a " +
      "code difference. This count is reported so the correction can never be silent.",
    verdict_basis: "compiler output and diff text only — no judgement, no adjudicator opinion",
  };
}

export const readRaw = (p) => { try { return fs.readFileSync(p, "utf8"); } catch { return ""; } };
