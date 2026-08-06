#!/usr/bin/env node
// Build OS — Context Compiler, SEAM 6: the UNCERTAINTY ESTIMATOR.
//
// Takes a task OUTCOME descriptor and answers one question mechanically:
//   has this outcome earned a verifier, and WHICH named trigger bought it?
//
// WHY (executed evidence, not preference):
//   EXP-0002 measured Gravito ON at 3.96x the tokens of OFF, driven by
//   uncontrolled Full-mode fan-out. PILOT-0001's single Full verifier examined
//   six risk areas, found the implementation clean, and changed NOTHING —
//   confidence delivered, no unique implementation value, full price paid.
//   So the default is NO verifier. Verification is earned by one of SEAM 6's
//   six named triggers or it does not happen.
//
// THE HONESTY RULE (encoded, not aspirational):
//   An ABSENT signal is never treated as a SAFE signal.
//     * missing test result   => incomplete_tests FIRES. Absence of a result is
//                                not evidence of coverage.
//     * missing confidence    => low_confidence does NOT fire (absence is not a
//                                low report either), but the output records
//                                `confidence: "unavailable"` — never "high".
//     * file absent from index or tests_covering:null (SEAM 1's "not measured")
//                             => UNKNOWN coverage, reported separately from
//                                measured-uncovered, and it FIRES.
//   And, following mode-select.mjs: a PARTIAL DESCRIPTOR IS REFUSED (exit 2),
//   never guessed. If nobody answered whether the baseline was ambiguous, this
//   tool will not answer it for them.
//
// ONE DELIBERATE NON-TRIGGER, stated so it cannot be mistaken for an oversight:
//   test_result "fail" does NOT fire incomplete_tests. A red test is complete
//   evidence — of failure. The response to red is to fix it, not to spend a
//   verifier confirming it. The value is recorded verbatim in `signals`.
//
// Input JSON (argv[2] or stdin):
//   REQUIRED — refused if missing or of the wrong type:
//     "task_id":              <non-empty string>
//     "changed_files":        [<path>, ...]        (may be empty)
//     "prior_attempt_failed": <boolean>
//     "baseline_ambiguous":   <boolean>
//     "index" | "index_path": a SEAM 1 index object, or a path to one
//   OPTIONAL — absence carries the meanings above, not a default:
//     "lines_changed":        <non-negative integer | null>
//     "test_result":          "pass" | "fail" | "absent" | null
//     "worker_confidence":    "high" | "medium" | "low" | null
//
// Output: one JSON object on stdout — per-trigger booleans with their reasons,
// evidence and derived scope; the FIRING LIST; and the overall
// `verification_earned` decision. Deterministic: no clock, no randomness, fixed
// key order, byte-identical for identical inputs (SEAMS.md's hard requirement).
// Exit: 0 with an assessment; 2 on a malformed or partial descriptor.

import { readFileSync } from 'node:fs';
import {
  TRIGGER_ORDER, matchSensitive, deriveThresholds,
  SCOPE_KIND, UNSCOPABLE_BY_FILE, sortedUnique,
} from './triggers.mjs';

function fail(msg) {
  process.stderr.write('assess: ' + msg + '\n');
  process.exit(2);
}

let raw;
if (process.argv[2] !== undefined) {
  raw = process.argv[2];
} else {
  try {
    raw = readFileSync(0, 'utf8');
  } catch (e) {
    fail('no input: pass a JSON argument or pipe JSON on stdin');
  }
}

let d;
try {
  d = JSON.parse(raw);
} catch (e) {
  fail('input is not valid JSON (refused rather than partially interpreted)');
}
if (!d || typeof d !== 'object' || Array.isArray(d)) fail('input must be a JSON object');

// ---- validation: a partial descriptor is refused, never guessed ------------
if (typeof d.task_id !== 'string' || d.task_id.length === 0) fail('task_id is required and must be a non-empty string');
if (!Array.isArray(d.changed_files) || d.changed_files.some((p) => typeof p !== 'string' || p.length === 0)) {
  fail('changed_files is required and must be an array of non-empty path strings');
}
if (typeof d.prior_attempt_failed !== 'boolean') {
  fail('prior_attempt_failed must be a boolean — an unanswered question is refused, not read as false');
}
if (typeof d.baseline_ambiguous !== 'boolean') {
  fail('baseline_ambiguous must be a boolean — an unanswered question is refused, not read as false');
}
if (d.lines_changed !== undefined && d.lines_changed !== null) {
  if (!Number.isInteger(d.lines_changed) || d.lines_changed < 0) fail('lines_changed, when present, must be a non-negative integer');
}
if (d.test_result !== undefined && d.test_result !== null && !['pass', 'fail', 'absent'].includes(d.test_result)) {
  fail('test_result, when present, must be "pass", "fail" or "absent"');
}
if (d.worker_confidence !== undefined && d.worker_confidence !== null && !['high', 'medium', 'low'].includes(d.worker_confidence)) {
  fail('worker_confidence, when present, must be "high", "medium" or "low"');
}

// The index is REQUIRED: coverage is a measurement, and without the measurement
// there is nothing to read but an assumption.
let index;
if (d.index !== undefined && d.index !== null) {
  index = d.index;
} else if (typeof d.index_path === 'string' && d.index_path.length > 0) {
  try {
    index = JSON.parse(readFileSync(d.index_path, 'utf8'));
  } catch (e) {
    fail('index_path could not be read or parsed: ' + d.index_path);
  }
} else {
  fail('an index is required ("index" object or "index_path"): coverage cannot be assumed without a SEAM 1 index');
}
if (!index || typeof index !== 'object' || !index.files || typeof index.files !== 'object') {
  fail('the index must be a SEAM 1 index object with a "files" map');
}

// ---- normalised signals ----------------------------------------------------
const changed = sortedUnique(d.changed_files);
const testResult = (d.test_result === undefined || d.test_result === null) ? 'absent' : d.test_result;
const confidence = (d.worker_confidence === undefined || d.worker_confidence === null) ? 'unavailable' : d.worker_confidence;
const linesChanged = (d.lines_changed === undefined || d.lines_changed === null) ? null : d.lines_changed;

// ---- coverage classification (SEAM 1) --------------------------------------
// Four states, kept distinct because they are four different claims:
//   covered | uncovered (measured: an empty tests_covering list)
//   unknown (not in the index, or tests_covering:null — SEAM 1's not-measured)
//   exempt  (a test/doc/config/generated file needs no covering test of its own)
const covered = [], uncovered = [], unknownCoverage = [], exempt = [];
for (const p of changed) {
  const f = index.files[p];
  if (!f || typeof f !== 'object') { unknownCoverage.push(p); continue; }
  if (f.kind && f.kind !== 'source') { exempt.push(p); continue; }
  const tc = f.tests_covering;
  if (tc === null || tc === undefined) { unknownCoverage.push(p); continue; }
  if (!Array.isArray(tc)) { unknownCoverage.push(p); continue; }
  if (tc.length > 0) covered.push(p); else uncovered.push(p);
}

const thresholds = deriveThresholds(index);

// ---- the six triggers ------------------------------------------------------
const T = {};

// 1. incomplete tests.
{
  const gaps = sortedUnique([...uncovered, ...unknownCoverage]);
  const resultAbsent = testResult === 'absent';
  const fired = gaps.length > 0 || resultAbsent;
  const reasons = [];
  if (uncovered.length > 0) reasons.push(uncovered.length + ' changed source file(s) have a measured-empty tests_covering list');
  if (unknownCoverage.length > 0) reasons.push(unknownCoverage.length + ' changed file(s) have UNKNOWN coverage (absent from the index, or tests_covering:null = SEAM 1 not-measured) — unknown is not covered');
  if (resultAbsent) reasons.push('no test result was reported; absence of a result is not evidence of coverage');
  T.incomplete_tests = {
    fired,
    why: fired
      ? reasons.join('; ')
      : 'every changed source file carries at least one covering test in the index, and a test result was reported (' + testResult + '). Note: a "fail" result is deliberately NOT this trigger — red is a defect to fix, not an uncertainty to verify',
    evidence: {
      covered, uncovered, unknown_coverage: unknownCoverage, exempt_non_source: exempt,
      test_result: testResult,
    },
    scope: { kind: SCOPE_KIND.incomplete_tests, files: gaps, unscopable_by_file: UNSCOPABLE_BY_FILE.incomplete_tests },
  };
}

// 2. security / authority-sensitive surface.
{
  const matched = [];
  for (const p of changed) for (const h of matchSensitive(p)) matched.push(h);
  matched.sort((a, b) => (a.path + a.pattern_id).localeCompare(b.path + b.pattern_id));
  const files = sortedUnique(matched.map((m) => m.path));
  T.security_surface = {
    fired: files.length > 0,
    why: files.length > 0
      ? files.length + ' changed path(s) match a security/authority-sensitive pattern; each match names the pattern and why that pattern is sensitive'
      : 'no changed path matches a security or authority-sensitive pattern',
    evidence: { matched, sensitive_files: files },
    scope: { kind: SCOPE_KIND.security_surface, files, unscopable_by_file: UNSCOPABLE_BY_FILE.security_surface },
  };
}

// 3. worker-reported low confidence.
{
  const fired = confidence === 'low';
  T.low_confidence = {
    fired,
    why: fired
      ? 'the worker reported low confidence in its own outcome'
      : (confidence === 'unavailable'
        ? 'no confidence signal was reported. Recorded as "unavailable" — NOT as high. The trigger does not fire, because an absent report is not a low report; but nothing here should be read as the worker having expressed confidence'
        : 'the worker reported confidence "' + confidence + '"'),
    evidence: { confidence },
    scope: { kind: SCOPE_KIND.low_confidence, files: changed, unscopable_by_file: UNSCOPABLE_BY_FILE.low_confidence },
  };
}

// 4. diff over the derived risk threshold.
{
  const byFiles = changed.length >= thresholds.files.value;
  const byLines = linesChanged !== null && linesChanged >= thresholds.lines.value;
  const fired = byFiles || byLines;
  const reasons = [];
  if (byFiles) reasons.push('changed_files ' + changed.length + ' >= files threshold ' + thresholds.files.value);
  if (byLines) reasons.push('lines_changed ' + linesChanged + ' >= lines threshold ' + thresholds.lines.value);
  T.diff_over_risk_threshold = {
    fired,
    why: fired
      ? reasons.join('; ') + ' (thresholds and their derivations are reported under "thresholds")'
      : 'the diff is under both derived thresholds: ' + changed.length + ' file(s) < ' + thresholds.files.value +
        (linesChanged === null
          ? ', and no line count was reported — magnitude is still measured, by file count, so this dimension is not an unmeasured gap'
          : ', and ' + linesChanged + ' line(s) < ' + thresholds.lines.value),
    evidence: {
      changed_file_count: changed.length,
      lines_changed: linesChanged,
      lines_reported: linesChanged !== null,
      over_by_files: byFiles,
      over_by_lines: byLines,
    },
    scope: { kind: SCOPE_KIND.diff_over_risk_threshold, files: changed, unscopable_by_file: UNSCOPABLE_BY_FILE.diff_over_risk_threshold },
  };
}

// 5. ambiguous baseline.
{
  const fired = d.baseline_ambiguous === true;
  T.ambiguous_baseline = {
    fired,
    why: fired
      ? 'the pre-change baseline was not cleanly measured, so any improvement claim is unattributable — and the examination cannot be narrowed by file, because what "changed" means is itself in doubt'
      : 'the baseline was reported as cleanly measured',
    evidence: { baseline_ambiguous: d.baseline_ambiguous },
    scope: { kind: SCOPE_KIND.ambiguous_baseline, files: changed, unscopable_by_file: UNSCOPABLE_BY_FILE.ambiguous_baseline },
  };
}

// 6. prior failed attempt on this task.
{
  const fired = d.prior_attempt_failed === true;
  T.prior_failed_attempt = {
    fired,
    why: fired
      ? 'a previous attempt on this task is recorded as failed; the same failure mode is the first thing worth examining'
      : 'no prior failed attempt on this task was reported',
    evidence: { prior_attempt_failed: d.prior_attempt_failed },
    scope: { kind: SCOPE_KIND.prior_failed_attempt, files: changed, unscopable_by_file: UNSCOPABLE_BY_FILE.prior_failed_attempt },
  };
}

// ---- assemble, in the fixed SEAM 6 order -----------------------------------
const triggers = {};
for (const name of TRIGGER_ORDER) triggers[name] = T[name];
const fired = TRIGGER_ORDER.filter((n) => triggers[n].fired);

const out = {
  assess_version: 1,
  task_id: d.task_id,
  index_version: Number.isInteger(index.index_version) ? index.index_version : null,
  repo_head: typeof index.repo_head === 'string' ? index.repo_head : null,
  signals: {
    changed_file_count: changed.length,
    changed_files: changed,
    lines_changed: linesChanged,
    test_result: testResult,
    worker_confidence: confidence,
    prior_attempt_failed: d.prior_attempt_failed,
    baseline_ambiguous: d.baseline_ambiguous,
  },
  confidence,
  thresholds,
  triggers,
  fired,
  verification_earned: fired.length > 0,
  default_note:
    fired.length > 0
      ? 'verification EARNED by ' + fired.length + ' named trigger(s): ' + fired.join(', ')
      : 'no trigger fired — the default holds: one worker plus deterministic tests, NO verifier. (EXP-0002: uncontrolled Full fan-out cost 3.96x; PILOT-0001: a Full verifier that changed nothing.)',
};

process.stdout.write(JSON.stringify(out, null, 2) + '\n');
