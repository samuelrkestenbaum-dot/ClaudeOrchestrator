#!/usr/bin/env node
// Build OS — Context Compiler, SEAM 6: the CONTRIBUTION LOG and TRIGGER EFFICACY.
//
// A trigger that dispatches verifiers is a claim: "outcomes shaped like this
// are worth paying to examine." This file is what makes that claim FALSIFIABLE.
// After a verifier runs, its contribution is recorded in the routing receipt's
// own vocabulary — changed_implementation / changed_conclusion / caught_defect /
// duplicated_work, each y/n/- — against the trigger(s) that bought the dispatch.
// The rolling efficacy report then says, per trigger, how often it fired and how
// often the verification it bought actually caught something.
//
// PILOT-0001 is the case this exists to catch: one Full verifier, six risk areas
// examined, implementation clean, NOTHING changed. That is a
// caught_defect=n / duplicated_work=y row. A trigger that produces only rows
// like that is a trigger not worth its cost — and this report will say so, by
// name, rather than letting it keep spending.
//
// HONEST MATH, stated so nobody has to reverse-engineer it:
//   * caught_rate = caught_defect(y) / RATED rows, where a rated row is one
//     whose caught_defect is "y" or "n". Rows recorded "-" are UNRATED and are
//     excluded from the denominator — an unknown is not a zero, and burying
//     admissions in a denominator is how a rate becomes a lie.
//   * with zero rated rows the rate is null with a stated note, never 0. No
//     data is not a bad score.
//   * `never_caught_a_defect` is true only when a trigger has RATED rows and
//     none of them caught anything. A trigger whose rows are all unrated is not
//     accused on evidence that does not exist.
//   * every one of the six SEAM 6 triggers appears in the report, including
//     those that have never fired — a trigger that never fires is a finding too.
//   * every report carries a VOLUME caveat with the row count, because a rate
//     over a handful of rows is noise, and the report says so itself.
//
// Usage:
//   contribution-log.mjs record <log-path> '<row-json>'
//   contribution-log.mjs efficacy <log-path> [--text]
//
// Row JSON:
//   { "task_id": "<id>", "decision": "targeted|full",
//     "triggers": ["<trigger>", ...],          (>=1, from the SEAM 6 vocabulary)
//     "verifier_ref": "<path-or-id>",
//     "changed_implementation": "y|n|-", "changed_conclusion": "y|n|-",
//     "caught_defect": "y|n|-", "duplicated_work": "y|n|-",
//     "tokens": <v|->, "cost": <v|->, "time": <v|->, "ts": "<caller-supplied|->" }
//
// A row for decision "none" is REFUSED: no verifier ran, so there is no
// contribution to claim. A value outside y/n/- is REFUSED. An all-"-" row is
// ACCEPTED as an honest admission and is reported as non-contributing —
// routing_contract.md: refusal is for CONTRADICTION, not absence.
//
// The tool never reads the clock (determinism): a caller may supply "ts";
// it is stored verbatim and defaults to "-".
// Exit: 0 on success; 2 on refusal.

import { readFileSync, appendFileSync, existsSync } from 'node:fs';
import { TRIGGER_ORDER, CONTRIBUTION_FIELDS, isYnd, sortedUnique } from './triggers.mjs';

function fail(msg) {
  process.stderr.write('contribution-log: ' + msg + '\n');
  process.exit(2);
}

const cmd = process.argv[2];
const logPath = process.argv[3];
if (!cmd || !['record', 'efficacy'].includes(cmd)) fail('usage: contribution-log.mjs record <log-path> \'<row-json>\' | efficacy <log-path> [--text]');
if (!logPath) fail('a log path is required (this tool writes only where it is told to)');

const FIELD_SEP = ' | ';

function esc(v) {
  return String(v).replace(/[|\n\r]/g, '/');
}

// ---------------------------------------------------------------------------
// record
// ---------------------------------------------------------------------------
if (cmd === 'record') {
  const raw = process.argv[4] !== undefined ? process.argv[4] : (() => {
    try { return readFileSync(0, 'utf8'); } catch (e) { return fail('no row: pass row JSON as an argument or on stdin'); }
  })();

  let r;
  try { r = JSON.parse(raw); } catch (e) { fail('row is not valid JSON'); }
  if (!r || typeof r !== 'object' || Array.isArray(r)) fail('row must be a JSON object');

  if (typeof r.task_id !== 'string' || r.task_id.length === 0) fail('task_id is required');
  if (!['targeted', 'full', 'none'].includes(r.decision)) fail('decision must be "targeted", "full" or "none"');
  if (r.decision === 'none') {
    fail('REFUSED: a contribution row for decision "none" — no verifier was dispatched, so there is no contribution to claim. Rows record what a verifier DID, not what was declined.');
  }
  if (!Array.isArray(r.triggers) || r.triggers.length === 0) {
    fail('triggers must be a non-empty array — every dispatch records WHICH trigger bought it (SEAM 6)');
  }
  for (const t of r.triggers) {
    if (!TRIGGER_ORDER.includes(t)) fail('unknown trigger "' + String(t) + '" — the SEAM 6 vocabulary is: ' + TRIGGER_ORDER.join(', '));
  }
  for (const f of CONTRIBUTION_FIELDS) {
    if (!isYnd(r[f])) fail(f + ' must be exactly "y", "n" or "-" (the routing receipt\'s vocabulary; "-" is an admission, anything else is a fork)');
  }

  const trg = TRIGGER_ORDER.filter((t) => r.triggers.includes(t));
  const line = 'contribution: ' + [
    esc(r.task_id),
    esc(r.decision),
    'triggers=' + trg.join(','),
    esc(r.verifier_ref === undefined || r.verifier_ref === null ? '-' : r.verifier_ref),
    ...CONTRIBUTION_FIELDS.map((f) => f + '=' + r[f]),
    'tokens=' + esc(r.tokens === undefined || r.tokens === null ? '-' : r.tokens),
    'cost=' + esc(r.cost === undefined || r.cost === null ? '-' : r.cost),
    'time=' + esc(r.time === undefined || r.time === null ? '-' : r.time),
    'ts=' + esc(r.ts === undefined || r.ts === null ? '-' : r.ts),
  ].join(FIELD_SEP) + '\n';

  appendFileSync(logPath, line);
  process.stdout.write('contribution-log: recorded ' + r.task_id + ' (' + r.decision + ') triggers=' + trg.join(',') + '\n');
  process.exit(0);
}

// ---------------------------------------------------------------------------
// efficacy
// ---------------------------------------------------------------------------
function parseRows(path) {
  if (!existsSync(path)) return [];
  const text = readFileSync(path, 'utf8');
  const rows = [];
  for (const line of text.split('\n')) {
    const l = line.trim();
    if (l.length === 0 || !l.startsWith('contribution:')) continue;
    const parts = l.slice('contribution:'.length).split('|').map((s) => s.trim());
    const row = { task_id: parts[0] || '-', decision: parts[1] || '-', triggers: [] };
    for (const p of parts.slice(2)) {
      const i = p.indexOf('=');
      if (i < 0) continue;
      const k = p.slice(0, i), v = p.slice(i + 1);
      if (k === 'triggers') row.triggers = v.length ? v.split(',') : [];
      else row[k] = v;
    }
    rows.push(row);
  }
  return rows;
}

const rows = parseRows(logPath);
const triggers = {};

for (const name of TRIGGER_ORDER) {
  const mine = rows.filter((r) => r.triggers.includes(name));
  const counts = {};
  for (const f of CONTRIBUTION_FIELDS) counts[f] = mine.filter((r) => r[f] === 'y').length;
  const rated = mine.filter((r) => r.caught_defect === 'y' || r.caught_defect === 'n').length;
  const unrated = mine.length - rated;
  const caught = counts.caught_defect;

  let rate = null, note;
  if (rated > 0) {
    rate = Math.round((caught / rated) * 1000) / 1000;
    note = caught + ' of ' + rated + ' rated verification(s) caught a defect' + (unrated > 0 ? '; ' + unrated + ' further row(s) are unrated ("-") and are excluded from the denominator rather than counted as misses' : '');
  } else if (mine.length > 0) {
    note = 'unavailable: ' + mine.length + ' verification(s) recorded but none rated (caught_defect "-"). An unknown is not a zero, so no rate is reported.';
  } else {
    note = 'unavailable: this trigger has never fired into a recorded verification. No data is not a bad score — but a trigger that never fires is itself a finding.';
  }

  triggers[name] = {
    verifications: mine.length,
    rated,
    unrated,
    changed_implementation: counts.changed_implementation,
    changed_conclusion: counts.changed_conclusion,
    caught_defect: counts.caught_defect,
    duplicated_work: counts.duplicated_work,
    caught_rate: rate,
    rate_note: note,
    // Only accusable on rated evidence. A trigger with nothing but "-" rows has
    // not been shown to be useless; it has not been measured.
    never_caught_a_defect: rated > 0 && caught === 0,
    verdict:
      mine.length === 0
        ? 'never fired — no evidence either way'
        : rated === 0
          ? 'fired ' + mine.length + ' time(s), all unrated — this trigger is spending without being measured'
          : caught === 0
            ? 'fired ' + mine.length + ' time(s), caught NOTHING in ' + rated + ' rated verification(s)' + (counts.duplicated_work > 0 ? ' while duplicating work ' + counts.duplicated_work + ' time(s)' : '') + ' — on this evidence it is not paying for itself'
            : 'fired ' + mine.length + ' time(s), caught ' + caught + ' defect(s) in ' + rated + ' rated verification(s)',
  };
}

// Totals are counted over ROWS, not summed across triggers: a dispatch bought
// by two triggers is ONE verification, and adding it once per trigger would
// inflate the denominator of the only number anyone will quote.
const ratedRows = rows.filter((r) => r.caught_defect === 'y' || r.caught_defect === 'n');
const caughtRows = rows.filter((r) => r.caught_defect === 'y');

const decisionCounts = { targeted: rows.filter((r) => r.decision === 'targeted').length, full: rows.filter((r) => r.decision === 'full').length };
const neverFired = TRIGGER_ORDER.filter((n) => triggers[n].verifications === 0);
const neverCaught = TRIGGER_ORDER.filter((n) => triggers[n].never_caught_a_defect);

const report = {
  report_version: 1,
  log: logPath,
  totals: {
    rows: rows.length,
    rated: ratedRows.length,
    unrated: rows.length - ratedRows.length,
    caught_defect: caughtRows.length,
    dispatches_by_decision: decisionCounts,
    distinct_tasks: sortedUnique(rows.map((r) => r.task_id)).length,
  },
  triggers,
  never_fired: neverFired,
  never_caught_a_defect: neverCaught,
  volume_note:
    rows.length + ' recorded verification(s). Trigger efficacy is a rate over a small integer: below roughly double-digit volume per trigger these numbers are NOISE, not evidence, and should not be used to retire or trust a trigger. The report states them anyway, unrounded and unflattered, because a rate nobody can see cannot be argued with.',
  method_note:
    'caught_rate = caught_defect(y) / rated rows, where rated = caught_defect in {y,n}. Rows recorded "-" are unrated and excluded from the denominator (an unknown is not a zero). PILOT-0001 is the reference failure: a Full verifier that examined six areas, found the implementation clean and changed nothing — caught_defect=n, duplicated_work=y.',
};

if (process.argv.includes('--text')) {
  const pad = (s, n) => String(s).padEnd(n);
  let out = 'TRIGGER EFFICACY — ' + logPath + '\n';
  out += pad('trigger', 26) + pad('fired', 7) + pad('rated', 7) + pad('caught', 8) + pad('dup', 6) + 'rate\n';
  for (const n of TRIGGER_ORDER) {
    const t = triggers[n];
    out += pad(n, 26) + pad(t.verifications, 7) + pad(t.rated, 7) + pad(t.caught_defect, 8) + pad(t.duplicated_work, 6) + (t.caught_rate === null ? '-' : t.caught_rate) + '\n';
  }
  out += '\n' + report.volume_note + '\n';
  if (neverCaught.length) out += 'NEVER CAUGHT ANYTHING (on rated evidence): ' + neverCaught.join(', ') + '\n';
  if (neverFired.length) out += 'NEVER FIRED: ' + neverFired.join(', ') + '\n';
  process.stdout.write(out);
} else {
  process.stdout.write(JSON.stringify(report, null, 2) + '\n');
}
