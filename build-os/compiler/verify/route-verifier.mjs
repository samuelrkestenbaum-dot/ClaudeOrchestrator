#!/usr/bin/env node
// Build OS — Context Compiler, SEAM 6: the VERIFIER ROUTER.
//
// Turns an assessment into a dispatch decision — none | targeted | full — plus
// the SCOPE of what the verifier should examine, and refuses a dispatch that
// the recorded routing authority does not permit.
//
// THE DECISION RULE (fixed, mechanical, stated in precedence order):
//   1. no trigger fired                        -> "none".  The default path.
//      This is the economics lesson made mechanical: EXP-0002 measured Gravito
//      ON at 3.96x OFF under uncontrolled Full fan-out, and PILOT-0001's one
//      Full verifier examined six risk areas and changed nothing. Verification
//      that nobody's evidence asked for is pure cost.
//   2. "full" if EITHER:
//        (a) any fired trigger declares itself unscopable_by_file — an
//            ambiguous baseline cannot be narrowed, because what "changed"
//            means is itself in doubt; or
//        (b) 3+ triggers fired AND their combined scope already covers every
//            changed file — at that point targeting buys nothing, and
//            pretending otherwise just hides a full examination inside a
//            "targeted" label.
//   3. otherwise                               -> "targeted", scoped to the
//      UNION of the firing triggers' own scopes, with one examination question
//      per fired trigger. A security trigger contributes the sensitive files
//      ONLY — not the whole diff. Targeting is what makes an earned
//      verification affordable.
//
// AUTHORITY (mirrors build-os/memory/routing_contract.md):
//   The mode recorded in the routing receipt is BINDING, and silent escalation
//   is prohibited. A dispatch above the recorded mode requires a NEW
//   evidence-bearing escalation record — `escalation` plus a non-empty
//   `escalation_evidence` (a "-" is an admission of no evidence, and
//   evidence-free escalation is refused). De-escalation is free and needs no
//   record. Ranks: none needs direct; targeted needs gravito_light; full needs
//   gravito_full.
//
// Input JSON (argv[2] or stdin):
//   { "assessment": <assess.mjs output>,
//     "authority": { "mode": "direct|light|full|gravito_light|gravito_full",
//                    "receipt": "<path>",
//                    "escalation": "<text>",            (optional)
//                    "escalation_evidence": "<text|->" } }  (optional)
//
// Output: one JSON object on stdout. Deterministic; no clock, no randomness.
// Exit: 0 with a decision; 2 on refusal (malformed input, unrecognised mode,
// or a dispatch inconsistent with the recorded authority).

import { readFileSync } from 'node:fs';
import {
  TRIGGER_ORDER, TRIGGER_QUESTION, MODE_ALIASES, MODE_RANK,
  DECISION_REQUIRES, sortedUnique,
} from './triggers.mjs';

function fail(msg) {
  process.stderr.write('route-verifier: ' + msg + '\n');
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

let inp;
try {
  inp = JSON.parse(raw);
} catch (e) {
  fail('input is not valid JSON');
}
if (!inp || typeof inp !== 'object' || Array.isArray(inp)) fail('input must be a JSON object');

const a = inp.assessment;
if (!a || typeof a !== 'object' || !a.triggers || !Array.isArray(a.fired)) {
  fail('input.assessment must be an assess.mjs output object (with "triggers" and "fired")');
}
const auth = inp.authority;
if (!auth || typeof auth !== 'object') fail('input.authority is required — a dispatch decision without a recorded authority is exactly the silent escalation routing_contract.md prohibits');

const recorded = MODE_ALIASES[auth.mode];
if (!recorded) {
  fail('unrecognised authority mode "' + String(auth.mode) + '" — refused rather than treated as permissive. Expected one of: direct, light, full, gravito_light, gravito_full');
}

const firedNames = TRIGGER_ORDER.filter((n) => a.fired.includes(n));
for (const n of a.fired) {
  if (!TRIGGER_ORDER.includes(n)) fail('assessment fired an unknown trigger "' + n + '" — the vocabulary has forked');
}

// ---- scope, derived from WHICH triggers fired ------------------------------
const byTrigger = {};
let unionFiles = [];
const unscopable = [];
for (const n of firedNames) {
  const sc = (a.triggers[n] && a.triggers[n].scope) || { kind: 'unknown', files: [], unscopable_by_file: false };
  byTrigger[n] = { kind: sc.kind, files: sortedUnique(sc.files || []), unscopable_by_file: sc.unscopable_by_file === true };
  unionFiles = unionFiles.concat(byTrigger[n].files);
  if (byTrigger[n].unscopable_by_file) unscopable.push(n);
}
unionFiles = sortedUnique(unionFiles);

const allChanged = sortedUnique((a.signals && a.signals.changed_files) || []);
const coversWholeDiff = allChanged.length > 0 && allChanged.every((p) => unionFiles.includes(p));

// ---- the decision ----------------------------------------------------------
let decision, derivation;
if (firedNames.length === 0) {
  decision = 'none';
  derivation =
    'rule 1: no SEAM 6 trigger fired, so no verifier is dispatched. The default is one worker plus deterministic tests — verification is earned or it does not happen (EXP-0002: 3.96x under uncontrolled Full fan-out; PILOT-0001: a Full verifier that examined six areas and changed nothing).';
} else if (unscopable.length > 0) {
  decision = 'full';
  derivation =
    'rule 2(a): trigger(s) [' + unscopable.join(', ') + '] declare themselves unscopable_by_file, so the examination cannot be narrowed; a "targeted" label here would be a full examination in disguise.';
} else if (firedNames.length >= 3 && coversWholeDiff) {
  decision = 'full';
  derivation =
    'rule 2(b): ' + firedNames.length + ' triggers fired and their combined scope already covers all ' + allChanged.length + ' changed file(s), so targeting buys nothing.';
} else {
  decision = 'targeted';
  derivation =
    'rule 3: ' + firedNames.length + ' scopable trigger(s) fired [' + firedNames.join(', ') + ']; the verifier is scoped to the union of their own scopes (' + unionFiles.length + ' of ' + allChanged.length + ' changed file(s)) with one examination question each. A security trigger contributes its sensitive files only, never the whole diff.';
}

const questions = decision === 'none' ? [] : firedNames.map((n) => TRIGGER_QUESTION[n]);

// ---- authority check -------------------------------------------------------
const requiredMode = DECISION_REQUIRES[decision];
const need = MODE_RANK[requiredMode];
const have = MODE_RANK[recorded];
const escalationText = typeof auth.escalation === 'string' ? auth.escalation.trim() : '';
const escalationEvidence = typeof auth.escalation_evidence === 'string' ? auth.escalation_evidence.trim() : '';
const hasEscalationRecord = escalationText.length > 0 && escalationText !== '-' &&
  escalationEvidence.length > 0 && escalationEvidence !== '-';

let escalated = false;
if (need > have) {
  if (!hasEscalationRecord) {
    fail(
      'REFUSED: decision "' + decision + '" requires authority ' + requiredMode + ', but the receipt records ' + recorded +
      ' (' + (auth.receipt || 'receipt path not given') + '). routing_contract.md: the recorded mode is BINDING and silent escalation is prohibited. ' +
      'To dispatch legally, record a NEW evidence-bearing escalation in the receipt BEFORE the escalated work begins — both "escalation" (' + recorded + ' -> ' + requiredMode + ') and a non-empty "escalation_evidence" naming what changed. ' +
      (escalationText.length > 0 && !hasEscalationRecord && (escalationEvidence === '-' || escalationEvidence.length === 0)
        ? 'An escalation was declared with no evidence; evidence-free escalation is not escalation.'
        : 'No escalation record was supplied.')
    );
  }
  escalated = true;
}

const out = {
  route_version: 1,
  task_id: a.task_id || null,
  verification_earned: firedNames.length > 0,
  decision,
  decision_derivation: derivation,
  triggers_fired: firedNames,
  scope: {
    files: decision === 'none' ? [] : unionFiles,
    by_trigger: byTrigger,
    unscopable_triggers: unscopable,
    covers_whole_diff: decision === 'none' ? false : coversWholeDiff,
    questions,
    excluded_from_scope: decision === 'none' ? [] : allChanged.filter((p) => !unionFiles.includes(p)),
  },
  authority: {
    recorded_mode: recorded,
    required_mode: requiredMode,
    sufficient: have >= need,
    escalated,
    escalation: escalated ? escalationText : '-',
    escalation_evidence: escalated ? escalationEvidence : '-',
    receipt: typeof auth.receipt === 'string' ? auth.receipt : '-',
  },
  contribution_note:
    decision === 'none'
      ? 'no dispatch, so no contribution row is due'
      : 'after this verifier runs, record its contribution row with contribution-log.mjs — a dispatch whose contribution is never recorded cannot be told apart from PILOT-0001\'s verifier that changed nothing',
};

process.stdout.write(JSON.stringify(out, null, 2) + '\n');
