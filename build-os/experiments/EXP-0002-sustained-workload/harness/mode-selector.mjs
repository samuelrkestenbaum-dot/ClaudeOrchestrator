// EXP-0002 — mode-selector heuristic. DESCRIPTIVE ONLY: the runner records
// this output in each run record and then ignores it. IT ROUTES NOTHING —
// both arms run every task identically regardless of what this prints.
// Its hindsight correctness (would the recommended mode have been the cheap
// one?) is evaluated at analysis time, against the measured records.
//
// Usage:
//   node mode-selector.mjs '<json>'
//   node mode-selector.mjs < input.json
//
// Input JSON (all six fields required):
//   {
//     "expected_files_changed":  <non-negative integer>,
//     "requires_tests":          <boolean>,
//     "expected_session_count":  <positive integer>,
//     "prior_context_required":  <boolean>,
//     "handoff_required":        <boolean>,
//     "consequence_level":       "low" | "medium" | "high"
//   }
//
// Output: exactly one of  direct | gravito_light | gravito_full  on stdout.
//
// THE RULE (fixed, mechanical, in precedence order):
//   1. gravito_full   if multi-session (expected_session_count > 1) OR a
//                     handoff is required OR consequence_level is "high" OR
//                     the change is multi-step in the file sense
//                     (expected_files_changed >= 4);
//   2. direct         if tiny + isolated + low: expected_files_changed <= 1
//                     AND no tests required AND no prior context required AND
//                     consequence_level is "low";
//   3. gravito_light  otherwise (bounded, context-bearing, one-session work).
//
// Exit: 0 with a verdict; 2 on malformed input (a verdict is never guessed
// from a partial descriptor — an unknown is not a zero).

import { readFileSync } from 'node:fs';

function fail(msg) {
  process.stderr.write('mode-selector: ' + msg + '\n');
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
  fail('input is not valid JSON');
}
if (!d || typeof d !== 'object' || Array.isArray(d)) fail('input must be a JSON object');

const isNonNegInt = (v) => Number.isInteger(v) && v >= 0;
const isPosInt = (v) => Number.isInteger(v) && v >= 1;
const isBool = (v) => typeof v === 'boolean';

if (!isNonNegInt(d.expected_files_changed)) fail('expected_files_changed must be a non-negative integer');
if (!isBool(d.requires_tests)) fail('requires_tests must be a boolean');
if (!isPosInt(d.expected_session_count)) fail('expected_session_count must be a positive integer');
if (!isBool(d.prior_context_required)) fail('prior_context_required must be a boolean');
if (!isBool(d.handoff_required)) fail('handoff_required must be a boolean');
if (!['low', 'medium', 'high'].includes(d.consequence_level)) {
  fail('consequence_level must be "low", "medium" or "high"');
}

let mode;
if (
  d.expected_session_count > 1 ||
  d.handoff_required ||
  d.consequence_level === 'high' ||
  d.expected_files_changed >= 4
) {
  mode = 'gravito_full';
} else if (
  d.expected_files_changed <= 1 &&
  !d.requires_tests &&
  !d.prior_context_required &&
  d.consequence_level === 'low'
) {
  mode = 'direct';
} else {
  mode = 'gravito_light';
}

process.stdout.write(mode + '\n');
