#!/usr/bin/env node
// POST-PILOT ELIGIBILITY WORKFLOW — step 7: the CANDIDATE BACKLOG.
//
//   emit-backlog.mjs --index <index.json> --exclusions <file> --out <dir>
//                    --repo <p> --commit <sha> [--deterministic]
//
// Runs ONLY after the eligibility verdict is ELIGIBLE. Emits CANDIDATES.md and
// candidates.json into --out (never into the assessed repository).
//
// WHAT A CANDIDATE IS. One error cluster from the SEAM 1 index: a normalized
// error signature, its count, and the files it touches. That is a unit of work
// a task could be cut from — it is NOT a task, and it is NOT a selection. The
// distinction is load-bearing: EXP-0004's preregistration fixes the task set
// before the run, so the act of choosing tasks is an operator-gated step with
// its own record. This tool hands the operator a shortlist and stops.
//
// WHAT THE EXCLUSION FILTER IS FOR. AB_PREREGISTRATION: EXP-0004's task set
// "MUST NOT overlap PILOT-0002" because using those tasks "would contaminate a
// frozen pilot". PILOT-0002 is frozen and has not yet run. PILOT-0001's tasks
// are excluded too — already executed, so re-measuring them measures
// familiarity. The list itself is an INPUT FILE (--exclusions); nothing about
// those ten tasks is compiled into this program, so the operator who owns the
// freeze can review, extend or correct the list without touching code.
//
// HONESTY. An index built without --errors has errors_measured: false. That
// produces an EMPTY backlog with the reason printed — never a silent empty list
// and never a claim that the repository has no work in it.
//
// DETERMINISM. Same index + same exclusions => byte-identical output. Clusters
// arrive already sorted (count DESC, signature ASC) from the indexer; nothing
// here re-sorts by anything time- or path-dependent, and the only wall-clock
// field is zeroed by --deterministic.
//
// Dependencies: node stdlib only.

import fs from 'node:fs';
import path from 'node:path';

const BACKLOG_VERSION = 1;
const EPOCH = '1970-01-01T00:00:00.000Z';

const STATUS = 'CANDIDATES for selection, not a selection';

function die(msg) {
  process.stderr.write(`emit-backlog: ${msg}\n`);
  process.exit(2);
}

// Deterministic prose wrapping, so the markdown stays readable without
// depending on a renderer.
function wrap(text, width = 78) {
  const out = [];
  let line = '';
  for (const word of String(text).split(/\s+/).filter(Boolean)) {
    if (line === '') line = word;
    else if ((line + ' ' + word).length <= width) line += ' ' + word;
    else { out.push(line); line = word; }
  }
  out.push(line);
  return out;
}

// ---------------------------------------------------------- exclusions ----
// Format: `<pilot-id> | <task name> | <regex>`; # and blank lines ignored. A
// malformed line is a hard error, not a skipped line: an exclusion list that
// silently drops an entry is worse than no list, because it reads as protection.
function parseExclusions(text, file) {
  const rules = [];
  const lines = text.split('\n');
  for (let i = 0; i < lines.length; i++) {
    const raw = lines[i];
    if (/^\s*(#|$)/.test(raw)) continue;
    const parts = raw.split('|');
    if (parts.length < 3) die(`${file}:${i + 1}: expected "<pilot-id> | <task name> | <regex>"`);
    const pilot = parts[0].trim();
    const name = parts[1].trim();
    const pattern = parts.slice(2).join('|').trim();
    if (!pilot || !name || !pattern) die(`${file}:${i + 1}: empty field in exclusion entry`);
    let re;
    try { re = new RegExp(pattern, 'im'); }
    catch (e) { die(`${file}:${i + 1}: not a valid regular expression: ${e.message}`); }
    rules.push({ pilot, task: name, pattern, line: i + 1, re });
  }
  if (rules.length === 0) die(`${file}: contains no exclusion entries — refusing to emit an unfiltered backlog`);
  return rules;
}

function main(argv) {
  const opt = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const take = (k) => { opt[k] = argv[++i]; if (opt[k] === undefined) die(`${a} needs a value`); };
    if (a === '--index') take('index');
    else if (a === '--exclusions') take('exclusions');
    else if (a === '--out') take('out');
    else if (a === '--repo') take('repo');
    else if (a === '--commit') take('commit');
    else if (a === '--deterministic') opt.deterministic = true;
    else die(`unknown argument: ${a}`);
  }
  for (const k of ['index', 'exclusions', 'out', 'repo', 'commit']) {
    if (!opt[k]) die(`missing required argument --${k}`);
  }

  let idx;
  try { idx = JSON.parse(fs.readFileSync(opt.index, 'utf8')); }
  catch (e) { die(`cannot read index ${opt.index}: ${e.message}`); }
  if (!idx || typeof idx.files !== 'object' || idx.files === null) die(`not a SEAM 1 index: ${opt.index}`);

  let exText;
  try { exText = fs.readFileSync(opt.exclusions, 'utf8'); }
  catch (e) { die(`cannot read exclusion list ${opt.exclusions}: ${e.message}`); }
  const rules = parseExclusions(exText, opt.exclusions);

  const measured = idx.errors_measured === true;
  const clusters = Array.isArray(idx.error_clusters) ? idx.error_clusters : [];

  const source = measured
    ? `error clusters measured from the --errors input at the pinned commit (${clusters.length} cluster(s))`
    : 'unavailable: this index was built without --errors, so errors_measured is false and '
      + 'every error_count is null. That is an UNMEASURED repository, not a repository with '
      + 'no work in it. Re-run the assessment with --errors <tsc-style error list> to get candidates.';

  const fileEntry = (p) => (Object.prototype.hasOwnProperty.call(idx.files, p) ? idx.files[p] : null);
  const signalOf = (files) => {
    const present = files.filter((p) => fileEntry(p) !== null);
    return {
      files_in_index: present.length,
      files_absent_from_index: files.length - present.length,
      files_with_a_parser: present.filter((p) => (fileEntry(p).parser || 'none') !== 'none').length,
      files_with_symbols: present.filter((p) => (fileEntry(p).symbols || []).length > 0).length,
      files_with_a_covering_test: present.filter((p) => (fileEntry(p).tests_covering || []).length > 0).length,
    };
  };

  const candidates = [];
  const excluded = [];
  let seq = 0;
  for (const c of clusters) {
    const files = Array.isArray(c.files) ? c.files : [];
    // Matched against the signature AND every path, one per line, so `^`/`$` in
    // a rule anchor to path boundaries.
    const subject = [c.signature || '', ...files].join('\n');
    const hits = rules.filter((r) => r.re.test(subject));
    seq += 1;
    const entry = {
      candidate_id: `CAND-${String(seq).padStart(4, '0')}`,
      signature: c.signature || '(unsigned cluster)',
      error_count: typeof c.count === 'number' ? c.count : null,
      files,
      seed_files: files,
      shape: 'UNCLASSIFIED — AB_PREREGISTRATION asks for three shapes (simple isolated, '
        + 'ordinary multi-file, complex unfamiliar). Nothing here measures shape; the '
        + 'operator assigns it at selection.',
      index_signal: signalOf(files),
    };
    if (hits.length === 0) candidates.push(entry);
    else {
      excluded.push({
        ...entry,
        excluded: true,
        excluded_by: hits.map((h) => ({
          pilot: h.pilot, task: h.task, pattern: h.pattern,
          exclusion_line: h.line,
        })),
      });
    }
  }

  const backlog = {
    backlog_version: BACKLOG_VERSION,
    status: STATUS,
    selection_is_a_separate_step: 'Selection and freezing is a separate, operator-gated step. '
      + 'This file selects nothing.',
    candidate_id_note: 'candidate_id is the cluster\'s ordinal in the index, assigned before '
      + 'filtering, so an excluded cluster keeps its id and the surviving ids stay stable when '
      + 'the exclusion list changes. A gap in the numbering is an exclusion, not a lost cluster.',
    repo: opt.repo,
    pinned_commit: opt.commit,
    timestamp: opt.deterministic ? EPOCH : new Date().toISOString(),
    source,
    errors_measured: measured,
    exclusions_file: opt.exclusions,
    exclusion_rules: rules.map((r) => ({ pilot: r.pilot, task: r.task, pattern: r.pattern, line: r.line })),
    candidate_count: candidates.length,
    excluded_count: excluded.length,
    candidates,
    excluded,
    limitations: [
      'A cluster is not a task. It is a set of errors sharing a normalized signature; '
      + 'cutting a task from it is a human judgement this tool does not make.',
      'Cluster signatures are operand-blind (errors.mjs normalizes quoted operands to '
      + "'<S>'), so exclusion patterns match mostly on PATHS. A frozen task whose paths "
      + 'this list names wrongly will not be caught by its message.',
      'The exclusion patterns are deliberately broad, because a false exclusion costs one '
      + 'candidate while a false inclusion contaminates a frozen pilot that cannot be un-run.',
      'index_signal describes what the INDEX knows about the files, not how hard the work is.',
    ],
  };

  const L = [];
  L.push('# EXP-0004 CANDIDATE BACKLOG');
  L.push('');
  L.push(`STATUS: ${STATUS}.`);
  L.push('Selection and freezing is a separate, operator-gated step. Reading this file');
  L.push('selects nothing; nothing below is frozen, scheduled, or committed to.');
  L.push('');
  L.push(`repo: ${opt.repo}`);
  L.push(`pinned_commit: ${opt.commit}`);
  L.push(`source: ${source}`);
  L.push(`exclusions applied: ${opt.exclusions}`);
  L.push(`candidates: ${candidates.length}    excluded as prior-pilot work: ${excluded.length}`);
  L.push('');
  for (const line of wrap(backlog.candidate_id_note, 78)) L.push(line);
  L.push('');
  L.push('== CANDIDATES ==');
  if (candidates.length === 0) {
    L.push(measured
      ? '  (none — every cluster in this index matched a prior-pilot exclusion)'
      : '  (none — errors were never measured; see `source` above. This is an absence of'
        + '\n   measurement, not a measured absence of work.)');
  }
  for (const c of candidates) {
    L.push(`  ${c.candidate_id}  ${c.error_count} error(s)  ${c.signature}`);
    for (const f of c.files) L.push(`      ${f}`);
    L.push(`      index signal: ${c.index_signal.files_with_a_parser}/${c.files.length} parsed, `
      + `${c.index_signal.files_with_symbols} with symbols, `
      + `${c.index_signal.files_with_a_covering_test} with a covering test`);
  }
  L.push('');
  L.push('== EXCLUDED — PRIOR-PILOT WORK (protecting a frozen pilot) ==');
  if (excluded.length === 0) L.push('  (none matched)');
  for (const c of excluded) {
    L.push(`  ${c.candidate_id}  ${c.error_count} error(s)  ${c.signature}`);
    for (const f of c.files) L.push(`      ${f}`);
    for (const h of c.excluded_by) {
      L.push(`      EXCLUDED by ${h.pilot} — ${h.task}  [pattern: ${h.pattern}]`);
    }
  }
  L.push('');
  L.push('== EXCLUSION RULES APPLIED (from prior-pilot-exclusions.txt) ==');
  for (const r of rules) L.push(`  ${r.pilot}  ${r.task}  [${r.pattern}]`);
  L.push('');
  L.push('== LIMITATIONS ==');
  for (const l of backlog.limitations) {
    const lines = wrap(l, 74);
    L.push(`  * ${lines[0]}`);
    for (const cont of lines.slice(1)) L.push(`    ${cont}`);
  }
  L.push('');

  fs.writeFileSync(path.join(opt.out, 'candidates.json'), JSON.stringify(backlog, null, 2) + '\n');
  fs.writeFileSync(path.join(opt.out, 'CANDIDATES.md'), L.join('\n') + '\n');
  process.stderr.write(`backlog: ${candidates.length} candidate(s), ${excluded.length} excluded as prior-pilot work\n`);
  return 0;
}

process.exit(main(process.argv.slice(2)));
