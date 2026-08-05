#!/usr/bin/env node
// Build OS — the PRODUCT mode selector. BINDING: its verdict is recorded in a
// routing receipt by build-os/tools/route-task.sh and enforced at close by
// build-os/tools/routing-check.sh. Contract: build-os/memory/routing_contract.md.
//
// PROVENANCE. Generalized from the frozen experiment copy at
// build-os/experiments/EXP-0002-sustained-workload/harness/mode-selector.mjs,
// which stays descriptive, frozen, and routes nothing. Two executed defects
// from EXP-0002's sealed records drive the differences:
//
//   ENFORCEMENT (buildos T5): the recorded verdict `gravito_light` was ignored
//     and Full ceremony ran anyway (4 dispatches, $4.80, 7.4M tokens). That is
//     not this file's defect to fix — the receipt + close-time gate fix it —
//     but it is why this selector's output is now BINDING rather than logged.
//   CALIBRATION (buildos T3): the frozen rule granted `gravito_full` on
//     complexity alone (files >= 4), and the correctly-selected Full ceremony
//     cost 3.9x on a bounded feature. THE RECALIBRATION: complexity is no
//     longer sufficient for Full. At least one VALUE factor — evidence that
//     ceremony buys something worth its cost — must also be true.
//
// Usage:
//   mode-select.mjs '<json>'
//   mode-select.mjs < input.json
//
// Input JSON (ALL THIRTEEN fields required — a partial descriptor is refused,
// never guessed; an unknown is not a zero):
//   the six task-shape fields, as in the experiment selector:
//     "expected_files_changed":  <non-negative integer>
//     "requires_tests":          <boolean>
//     "expected_session_count":  <positive integer>
//     "prior_context_required":  <boolean>
//     "handoff_required":        <boolean>
//     "consequence_level":       "low" | "medium" | "high"
//   the seven VALUE factors (the recalibration — each a boolean):
//     "irreversible_or_external_mutation"
//     "high_blast_radius"
//     "unclear_acceptance_criteria"
//     "security_or_compliance_consequence"
//     "parallel_workstreams_benefit"
//     "high_rework_history"
//     "nondeterministic_verification"
//
// THE RULE (fixed, mechanical, in precedence order):
//   1. COMPLEXITY trigger — multi-session (expected_session_count > 1) OR a
//      handoff OR consequence_level "high" OR multi-step in the file sense
//      (expected_files_changed >= 4):
//        WITH at least one value factor true  -> gravito_full
//        WITH no value factor true            -> gravito_light, plus a note on
//          stderr naming why Full was withheld (T3's lesson, printed not silent)
//   2. direct        if tiny + isolated + low: expected_files_changed <= 1 AND
//                    no tests required AND no prior context AND consequence low
//   3. gravito_light otherwise (bounded, context-bearing, one-session work)
//
// Output: exactly one of  direct | gravito_light | gravito_full  on stdout.
// The withheld-Full note goes to stderr, so stdout stays a single parseable
// token for route-task.sh. Deterministic, pure, writes nothing.
// Exit: 0 with a verdict; 2 on a malformed or partial descriptor.

import { readFileSync } from 'node:fs';

function fail(msg) {
  process.stderr.write('mode-select: ' + msg + '\n');
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

// The seven value factors. Every one is required: a descriptor that omits one
// is a descriptor whose author has not answered the value question, and the
// whole point of the recalibration is that the question gets answered.
const VALUE_FACTORS = [
  'irreversible_or_external_mutation',
  'high_blast_radius',
  'unclear_acceptance_criteria',
  'security_or_compliance_consequence',
  'parallel_workstreams_benefit',
  'high_rework_history',
  'nondeterministic_verification',
];
for (const f of VALUE_FACTORS) {
  if (!isBool(d[f])) fail(f + ' must be a boolean (all seven value factors are required; a partial descriptor is refused, not guessed)');
}

// Complexity trigger — the experiment selector's rule 1, verbatim.
const complexityReasons = [];
if (d.expected_session_count > 1) complexityReasons.push('multi-session (expected_session_count ' + d.expected_session_count + ')');
if (d.handoff_required) complexityReasons.push('handoff required');
if (d.consequence_level === 'high') complexityReasons.push('consequence_level high');
if (d.expected_files_changed >= 4) complexityReasons.push('multi-step (expected_files_changed ' + d.expected_files_changed + ')');

const valueTrue = VALUE_FACTORS.filter((f) => d[f] === true);

let mode;
if (complexityReasons.length > 0) {
  if (valueTrue.length > 0) {
    mode = 'gravito_full';
  } else {
    // T3's fix, executed: complexity alone is not value-over-cost evidence.
    mode = 'gravito_light';
    process.stderr.write(
      'mode-select: note: gravito_full WITHHELD — complexity trigger fired (' +
      complexityReasons.join('; ') +
      ') but no value factor is true. Complexity alone is not evidence that Full ceremony buys ' +
      'anything worth its cost (EXP-0002 buildos T3: a correctly-complex bounded feature at 3.9x). ' +
      'Selecting gravito_light. To route Full, declare at least one true value factor: ' +
      VALUE_FACTORS.join(', ') + '.\n'
    );
  }
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
