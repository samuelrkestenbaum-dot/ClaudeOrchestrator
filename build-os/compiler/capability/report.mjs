#!/usr/bin/env node
// Context Compiler — CAPABILITY REPORTER (consumes SEAM 1, optionally SEAM 2).
//
//   report --index <index.json> [--capsule <capsule.json>] [--json]
//
// PREPARED BUT **NOT WIRED**. This is a standalone CLI and NOTHING calls it.
// compile-task.mjs, render-capsule.mjs, build-index.mjs and the runtime are
// untouched by it and must stay that way until a future packet wires it
// deliberately: EXP-0004's preregistration fixes arm behaviour, so changing what
// the compiler emits mid-registration would confound the very run this tool
// exists to protect. Until then it is invoked by hand and is inert by
// construction.
//
// WHY IT EXISTS. The first end-to-end integration run measured this repository
// at no_parser 390/415 and files_with_a_covering_test 4/415. A capsule compiled
// from that index is small for two indistinguishable reasons: it may be SELECTIVE
// (the compression thesis) or it may be IGNORANT (AB_PREREGISTRATION outcome 4,
// "small-because-uninformed"). A capsule cannot tell those apart about itself.
// This tool measures the SIGNAL QUALITY of the index behind a capsule and is
// willing to conclude that the honest answer is "do not use a capsule here at
// all; explore the repository the ordinary way". That refusal is a feature.
//
// DERIVATION PARITY. Every count here is computed the way `build-index.mjs stats`
// computes it, deliberately and not coincidentally:
//   no_parser      (f.parser || 'none') === 'none'
//   with_symbols   (f.symbols || []).length > 0
//   covered        (f.tests_covering || []).length > 0
//   pct            total === 0 ? unavailable : ((n/total)*100).toFixed(1)
// A capability report that recomputed these differently from the indexer would
// disagree with the number AMENDMENT 1 is measured on, which is the one number
// that must not be ambiguous.
//
// HONESTY RULES (binding, and pinned by tests/compiler_capability_tests.sh):
//   * every share prints as `n/total (pct%)` — never a bare percentage, because
//     "94%" hides whether the denominator was 415 files or 4;
//   * a metric with no denominator prints `unavailable` WITH the reason, never
//     0 — an unmeasured thing and a measured zero are different claims;
//   * a file whose parser is "none" was not read: this tool never describes the
//     index as understanding it, and its empty symbol list is never reported as
//     evidence that the file defines nothing;
//   * the eligibility test is integer arithmetic (2*n vs total), so the
//     boundary is exact and no rounding decides a preregistered precondition.
//
// DETERMINISM. Same index + same capsule => byte-identical output in both modes.
// No wall-clock field is emitted; every collection is sorted.
//
// Dependencies: node stdlib only.

import fs from 'node:fs';

const REPORT_VERSION = 1;

// AMENDMENT 1's threshold, as a rational so the comparison stays exact.
const THRESHOLD_NUM = 1;
const THRESHOLD_DEN = 2;
const THRESHOLD_TEXT = 'one half';

// Recommendation thresholds. These are DERIVED DEFAULTS, not calibrated
// constants: nothing has yet measured that they predict outcome quality.
const THIN_LINKAGE_DEN = 10; // test linkage below one tenth => thin

const RULE_TIERS = [
  { key: 'seed-file', tier: 1, label: 'P1 seed file', match: (w) => w.startsWith('named as a seed file') },
  { key: 'seed-symbol', tier: 1, label: 'P1 seed symbol', match: (w) => w.startsWith('defines seed symbol') },
  { key: 'covering-test', tier: 2, label: 'P2 covering test', match: (w) => w.startsWith('test covering it') },
  { key: 'importer', tier: 3, label: 'P3 importer', match: (w) => w.startsWith('imports the defining file') },
  { key: 'neighborhood-import', tier: 4, label: 'P4 neighborhood import', match: (w) => w.startsWith('direct import of the defining file') },
  { key: 'error-cluster', tier: 5, label: 'P5 error cluster', match: (w) => w.startsWith('same error cluster as') },
];

function die(msg) {
  process.stderr.write(`report: ${msg}\n`);
  process.exit(2);
}

const usage = 'usage: report.mjs report --index <index.json> [--capsule <capsule.json>] [--json]\n'
  + '       (standalone; nothing calls this — it is prepared, not wired)\n';

// --------------------------------------------------------------- shares ----
// A share is a triple, never a lone percentage. `total === 0` is unavailable,
// with a reason, and never renders as 0.
function share(n, total, reason) {
  if (total === 0) {
    return { n, total, available: false, text: `unavailable (${reason})`, reason };
  }
  return { n, total, available: true, text: `${n}/${total} (${((n / total) * 100).toFixed(1)}%)` };
}
const NO_DENOM = 'no denominator: the index describes no files';

function readJson(p, what) {
  let raw;
  try { raw = fs.readFileSync(p, 'utf8'); }
  catch (e) { die(`cannot read ${what} ${p}: ${e.message}`); }
  try { return JSON.parse(raw); }
  catch (e) { die(`${what} ${p} is not valid JSON: ${e.message}`); }
  return null;
}

const isNoParser = (f) => (f && f.parser ? f.parser : 'none') === 'none';
const symCount = (f) => (f && Array.isArray(f.symbols) ? f.symbols.length : 0);
const testCount = (f) => (f && Array.isArray(f.tests_covering) ? f.tests_covering.length : 0);

// ------------------------------------------------- unsupported directories --
// A blind spot is a directory in which the index parsed NOTHING. Only maximal
// such directories are reported: naming both `a` and `a/b` when `a` is already
// entirely unparsed is noise, not information. Size is file count — a proxy for
// importance, and a poor one (see LIMITATIONS in the rendered report).
function unsupportedRegions(files) {
  const paths = Object.keys(files);
  if (paths.length === 0) return null;
  const dirs = new Map();
  const bump = (d, none) => {
    const e = dirs.get(d) || { total: 0, none: 0 };
    e.total += 1;
    if (none) e.none += 1;
    dirs.set(d, e);
  };
  for (const p of paths) {
    const none = isNoParser(files[p]);
    bump('', none);
    const segs = p.split('/');
    segs.pop();
    let acc = '';
    for (const s of segs) { acc = acc ? `${acc}/${s}` : s; bump(acc, none); }
  }
  const entirely = new Set();
  for (const [d, e] of dirs) if (e.total > 0 && e.total === e.none) entirely.add(d);
  const parentOf = (d) => (d === '' ? null : (d.includes('/') ? d.slice(0, d.lastIndexOf('/')) : ''));
  const out = [];
  for (const d of entirely) {
    const parent = parentOf(d);
    if (parent !== null && entirely.has(parent)) continue;
    out.push({ path: d === '' ? '.' : d, is_repository_root: d === '', files: dirs.get(d).total });
  }
  out.sort((a, b) => b.files - a.files || (a.path < b.path ? -1 : a.path > b.path ? 1 : 0));
  return out;
}

// ------------------------------------------------------ per-item confidence --
// Derived only from things the index actually measured. Deliberately an ORDINAL:
// a numeric score here would imply a calibration nobody has performed.
function classifyRule(why) {
  const w = typeof why === 'string' ? why : '';
  for (const r of RULE_TIERS) if (r.match(w)) return r;
  return { key: 'unrecognized-rule', tier: null, label: 'unrecognized rule' };
}

const CONFIDENCE_DERIVATION = [
  'HIGH   — admitted by a P1 anchor rule (seed file or seed symbol) AND a real extractor',
  '         ran on the file AND the index extracted at least one symbol from it.',
  'LOW    — the path is absent from the index, OR no extractor ran on it (parser=none,',
  '         so the index never read its contents), OR it was admitted only by the P5',
  '         error-cluster rule with no extracted symbols, OR its admitting rule is one',
  '         this reporter does not recognise and therefore cannot weigh.',
  'MEDIUM — everything else: some observable signal, short of the HIGH combination.',
];

function confidenceFor(entry, indexFile) {
  const rule = classifyRule(entry.why);
  if (!indexFile) {
    return {
      confidence: 'LOW',
      rule,
      present_in_index: false,
      parser: 'unavailable',
      symbols: null,
      covering_tests: null,
      clause: 'the path is absent from the index, so nothing about it was measured',
    };
  }
  const parser = indexFile.parser || 'none';
  const symbols = symCount(indexFile);
  const covering = testCount(indexFile);
  const base = { rule, present_in_index: true, parser, symbols, covering_tests: covering };
  if (parser === 'none') {
    return { ...base, confidence: 'LOW', clause: 'no extractor ran on this file (parser=none), so the index never read its contents' };
  }
  if (rule.tier === null) {
    return { ...base, confidence: 'LOW', clause: 'the admitting rule string is not one this reporter recognises, so its strength cannot be weighed' };
  }
  if (rule.tier === 5 && symbols === 0) {
    return { ...base, confidence: 'LOW', clause: 'admitted only by error-cluster proximity with no extracted symbols — a shared failure signature is not structural knowledge' };
  }
  if (rule.tier === 1 && symbols > 0) {
    return { ...base, confidence: 'HIGH', clause: 'P1 anchor rule, a real extractor ran, and at least one symbol was extracted' };
  }
  return { ...base, confidence: 'MEDIUM', clause: 'observable signal exists but not the full P1-anchor + parser + symbol combination' };
}

// ------------------------------------------------------------- the analysis --
function analyze(idx, capsule, paths) {
  const files = idx && typeof idx.files === 'object' && idx.files !== null ? idx.files : {};
  const all = Object.keys(files).sort();
  const total = all.length;

  const noParser = all.filter((p) => isNoParser(files[p])).length;
  const withSymbols = all.filter((p) => symCount(files[p]) > 0).length;
  const covered = all.filter((p) => testCount(files[p]) > 0).length;
  const symbolsExtracted = all.reduce((a, p) => a + symCount(files[p]), 0);
  const symbolTable = idx && typeof idx.symbols === 'object' && idx.symbols !== null
    ? Object.keys(idx.symbols).length : 0;

  const byParser = new Map();
  for (const p of all) {
    const name = files[p].parser || 'none';
    byParser.set(name, (byParser.get(name) || 0) + 1);
  }
  const parsers = [...byParser.entries()]
    .sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : 1))
    .map(([name, n]) => ({ parser: name, files: n, share: share(n, total, NO_DENOM) }));

  // ---- admitted-candidate set: the capsule's relevant_files, else the index.
  let admittedPaths = all;
  let admittedSource = 'the whole index (no capsule given)';
  let items = null;
  if (capsule) {
    const rel = Array.isArray(capsule.relevant_files) ? capsule.relevant_files : [];
    const incl = capsule.provenance && typeof capsule.provenance.included_because === 'object'
      && capsule.provenance.included_because !== null ? capsule.provenance.included_because : {};
    const seen = new Set();
    items = [];
    for (const r of rel) {
      const p = r && typeof r.path === 'string' ? r.path : null;
      if (p === null || seen.has(p)) continue;
      seen.add(p);
      const why = typeof r.why === 'string' && r.why ? r.why
        : (typeof incl[p] === 'string' ? incl[p] : '');
      const c = confidenceFor({ path: p, why }, Object.prototype.hasOwnProperty.call(files, p) ? files[p] : null);
      items.push({ path: p, why, ...c });
    }
    items.sort((a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0));
    admittedPaths = items.map((i) => i.path);
    admittedSource = `the capsule's relevant_files (${admittedPaths.length} entries)`;
  }

  const aTotal = admittedPaths.length;
  const aPresent = admittedPaths.filter((p) => Object.prototype.hasOwnProperty.call(files, p));
  const aAbsent = aTotal - aPresent.length;
  // An admitted path the index does not describe is UNPARSED by definition: the
  // index cannot have understood a file it has no entry for. Counting it as
  // parsed would flatter the amendment number.
  const aNoParser = aAbsent + aPresent.filter((p) => isNoParser(files[p])).length;
  const aCovered = aPresent.filter((p) => testCount(files[p]) > 0).length;
  const aSymbols = aPresent.reduce((a, p) => a + symCount(files[p]), 0);
  const aLow = items ? items.filter((i) => i.confidence === 'LOW').length : 0;

  // ---- AMENDMENT 1, integer arithmetic, no rounding.
  const eligLhs = aNoParser * THRESHOLD_DEN;
  const eligRhs = aTotal * THRESHOLD_NUM;
  const eligible = aTotal > 0 && eligLhs < eligRhs;
  const eligibility = {
    verdict: eligible ? 'ELIGIBLE' : 'NOT-ELIGIBLE',
    measured_no_parser: aNoParser,
    measured_total: aTotal,
    share: share(aNoParser, aTotal, NO_DENOM),
    exact_test: aTotal === 0
      ? 'not computable: the admitted-candidate set is empty, so there is no share to compare'
      : `${THRESHOLD_DEN} * ${aNoParser} = ${eligLhs} < ${eligRhs} (files) ? ${eligLhs < eligRhs ? 'yes' : 'no'}`,
    threshold: `strictly below ${THRESHOLD_TEXT}`,
    measured_over: admittedSource,
  };

  // ---- recommended use state, each test printed with its numbers.
  const tests = [];
  const push = (id, text, fired, evaluated = true) => tests.push({ id, text, fired, evaluated });
  const emptySet = aTotal === 0;
  push('bypass-1', emptySet
    ? 'the admitted-candidate set is empty, so there is nothing to be informed about'
    : `no_parser share of the admitted-candidate set is at or above ${THRESHOLD_TEXT}: ${THRESHOLD_DEN} * ${aNoParser} = ${eligLhs} >= ${eligRhs} (files)`,
  emptySet || (aTotal > 0 && eligLhs >= eligRhs));
  push('bypass-2', `zero symbols were extracted across the admitted-candidate set: ${aSymbols} symbol(s) extracted`,
    !emptySet && aSymbols === 0);
  const bypass = tests.some((t) => t.fired);
  push('expansion-1', `test linkage across the admitted-candidate set is below one ${THIN_LINKAGE_DEN}th: ${THIN_LINKAGE_DEN} * ${aCovered} = ${THIN_LINKAGE_DEN * aCovered} < ${aTotal} (files)`,
    !bypass && !emptySet && THIN_LINKAGE_DEN * aCovered < aTotal, !bypass);
  push('expansion-2', items === null
    ? 'a majority of admitted files are LOW confidence: not computable without --capsule'
    : `a majority of admitted files are LOW confidence: 2 * ${aLow} = ${2 * aLow} > ${aTotal} (files)`,
  !bypass && items !== null && 2 * aLow > aTotal, !bypass);
  const expansionHeavy = !bypass && tests.some((t) => t.id.startsWith('expansion') && t.fired);
  const state = bypass ? 'bypass' : (expansionHeavy ? 'expansion-heavy' : 'normal');

  const MESSAGES = {
    bypass: [
      'STRUCTURAL SIGNAL IS INSUFFICIENT. Use ordinary exploratory execution here:',
      'let the worker read and search the repository the normal way. A capsule',
      'compiled from this index would be small-because-uninformed, not',
      'small-because-selective — the index did not parse these files, so it cannot',
      'tell a worker what matters inside them, and its silence is ignorance rather',
      'than judgement. Compiling anyway risks AB_PREREGISTRATION outcome 4.',
    ],
    'expansion-heavy': [
      'SIGNAL EXISTS BUT IS THIN. A capsule is usable here, but budget for expansion:',
      'expect the worker to buy extra context through the SEAM 3 expansion protocol',
      'and do not read a small capsule as proof that little context was needed.',
      'Every expansion request is the compiler\'s own error signal — record them.',
    ],
    normal: [
      'SIGNAL IS ADEQUATE for capsule execution: the index parsed most of the',
      'admitted-candidate set and has symbol and test linkage to walk. This is a',
      'statement about the INDEX, not a prediction that the capsule is correct.',
    ],
  };

  return {
    total, noParser, withSymbols, covered, symbolsExtracted, symbolTable, parsers,
    shares: {
      real_extractor: share(total - noParser, total, NO_DENOM),
      no_parser: share(noParser, total, NO_DENOM),
      with_symbols: share(withSymbols, total, NO_DENOM),
      covered: share(covered, total, NO_DENOM),
    },
    regions: unsupportedRegions(files),
    admitted: {
      source: admittedSource, total: aTotal, no_parser: aNoParser, absent_from_index: aAbsent,
      covered: aCovered, symbols: aSymbols, low_confidence: aLow,
      no_parser_share: share(aNoParser, aTotal, 'no denominator: the admitted-candidate set is empty'),
    },
    items, tests, state, message: MESSAGES[state], eligibility,
    flags: {
      symbols_partial: idx.symbols_partial === true,
      tests_covering_heuristic: idx.tests_covering_heuristic === true,
      errors_measured: idx.errors_measured === true,
    },
  };
}

// ------------------------------------------------------------------ render --
const LIMITATIONS = [
  'LIMITATIONS OF THIS REPORT (stated, not buried):',
  '  * the confidence ordinals are a HEURISTIC over observable index facts. They',
  '    are not calibrated: no measurement yet shows a HIGH item is more often',
  '    load-bearing than a MEDIUM one.',
  '  * blind-spot directories are ranked by FILE COUNT, which is a proxy for',
  '    importance and a poor one — a two-file directory can matter more than a',
  '    forty-file one.',
  '  * the recommendation thresholds are derived defaults. Nothing has measured',
  '    that they predict outcome quality; they are a starting position to be',
  '    revised against evidence, not a finding.',
  '  * every input number inherits SEAM 1\'s own limits: v0 extraction is regex or',
  '    line based (never an AST) and tests_covering is an import-or-basename',
  '    heuristic, not executed coverage.',
];

function renderText(a, indexPath, capsulePath, idx) {
  const L = [];
  L.push('CONTEXT COMPILER — CAPABILITY REPORT');
  L.push('(prepared, NOT WIRED: nothing in the compiler calls this tool)');
  L.push('');
  L.push(`index: ${indexPath}`);
  L.push(`index_version: ${idx.index_version ?? 'unknown'}`);
  L.push(`repo_head: ${idx.repo_head === null || idx.repo_head === undefined ? 'null (not measured)' : idx.repo_head}`);
  L.push(`files_indexed: ${a.total}`);
  L.push(`capsule: ${capsulePath === null ? 'none given (--capsule absent)' : capsulePath}`);
  L.push(`admitted-candidate set: ${a.admitted.source}, ${a.admitted.total} file(s)`);

  L.push('');
  L.push('== PARSER COVERAGE ==');
  L.push(`files with a real extractor: ${a.shares.real_extractor.text}`);
  if (a.parsers.length === 0) L.push(`by parser: unavailable (${NO_DENOM})`);
  else {
    L.push('by parser:');
    for (const p of a.parsers) L.push(`  ${p.parser.padEnd(20)} ${p.share.text}`);
  }

  L.push('');
  L.push('== UNSUPPORTED-FILE SHARE ==');
  L.push(`no_parser (whole index): ${a.shares.no_parser.text}`);
  L.push(`no_parser (admitted-candidate set): ${a.admitted.no_parser_share.text}`);
  if (a.admitted.absent_from_index > 0) {
    L.push(`  of which ${a.admitted.absent_from_index} admitted path(s) are absent from the index entirely`);
    L.push('  and are counted as unparsed, because the index says nothing about them.');
  }
  L.push('this is the number AMENDMENT 1 is measured against.');
  L.push('a file whose parser is "none" was NOT read by the indexer: its empty symbol');
  L.push('list is not evidence that it defines nothing, and nothing in this report');
  L.push('claims the index understands it.');

  L.push('');
  L.push('== SYMBOL COVERAGE ==');
  L.push(`files with >=1 extracted symbol: ${a.shares.with_symbols.text}`);
  L.push(`symbols extracted (sum over files): ${a.symbolsExtracted}`);
  L.push(`symbol table entries: ${a.symbolTable}`);
  L.push(`symbols_partial: ${a.flags.symbols_partial}`
    + (a.flags.symbols_partial ? ' — referenced_in is a whole-word text match, not a resolved reference graph.' : ''));

  L.push('');
  L.push('== TEST-LINKAGE COVERAGE ==');
  L.push(`files with >=1 tests_covering entry: ${a.shares.covered.text}`);
  L.push(`tests_covering_heuristic: ${a.flags.tests_covering_heuristic}`
    + (a.flags.tests_covering_heuristic ? ' — import-or-basename matching, not executed coverage.' : ''));

  L.push('');
  L.push('== NOTABLE UNSUPPORTED REGIONS (directories the index parsed nothing in) ==');
  if (a.regions === null) {
    L.push(`unavailable (${NO_DENOM})`);
  } else if (a.regions.length === 0) {
    L.push('none — every directory contains at least one parsed file.');
  } else {
    L.push('a worker relying on this index gets NO structural signal from these paths:');
    for (const r of a.regions.slice(0, 10)) {
      const name = r.is_repository_root ? '. (repository root)' : r.path;
      L.push(`  ${name.padEnd(44)} ${r.files} file(s), none parsed`);
    }
    if (a.regions.length > 10) L.push(`  (showing the 10 largest of ${a.regions.length}; the rest hold fewer files)`);
  }

  L.push('');
  L.push('== CONFIDENCE PER ADMITTED ITEM ==');
  if (a.items === null) {
    L.push('unavailable — no capsule was given (--capsule). Confidence is defined per');
    L.push('admitted item, and without a capsule there are no admitted items.');
  } else {
    L.push('an ordinal, derived from observable index facts. No numeric score is given:');
    L.push('a number here would imply a calibration nobody has performed.');
    for (const d of CONFIDENCE_DERIVATION) L.push(`  ${d}`);
    L.push('');
    if (a.items.length === 0) L.push('  (the capsule admitted no files)');
    for (const i of a.items) {
      L.push(`  ${i.path} ${i.confidence} [parser=${i.parser}; symbols=${i.symbols === null ? 'unavailable' : i.symbols}; `
        + `covering_tests=${i.covering_tests === null ? 'unavailable' : i.covering_tests}; rule=${i.rule.key}(${i.rule.label})]`);
      L.push(`      because: ${i.clause}`);
    }
  }

  L.push('');
  L.push(`== RECOMMENDED USE STATE: ${a.state} ==`);
  L.push('derivation — every test is shown with the numbers it was decided on:');
  for (const t of a.tests) {
    const mark = !t.evaluated ? 'not evaluated (an earlier test already decided)' : (t.fired ? 'FIRED' : 'not fired');
    L.push(`  ${t.id}: ${t.text}`);
    L.push(`      -> ${mark}`);
  }
  L.push('');
  for (const m of a.message) L.push(m);

  L.push('');
  L.push('== EXP-0004 ELIGIBILITY (AB_PREREGISTRATION AMENDMENT 1) ==');
  L.push('rule: the no_parser share of admitted-candidate files must be strictly below');
  L.push(`      ${THRESHOLD_TEXT} of that set, measured by the same derivation as build-index.mjs stats`);
  L.push('      and RECORDED in the run record before arm A begins.');
  L.push(`measured over: ${a.eligibility.measured_over}`);
  L.push(`measured: no_parser ${a.eligibility.share.text}`);
  L.push(`exact test (integer arithmetic, no rounding): ${a.eligibility.exact_test}`);
  L.push(`VERDICT: ${a.eligibility.verdict}`);
  L.push(a.eligibility.verdict === 'ELIGIBLE'
    ? 'this index satisfies AMENDMENT 1\'s precondition. Record this line in the run record.'
    : 'this index FAILS AMENDMENT 1\'s precondition: the run is excluded, or registered'
      + '\n`result confounded` under the existing stop conditions. Record this line as the reason.');

  L.push('');
  for (const l of LIMITATIONS) L.push(l);
  return L.join('\n') + '\n';
}

function renderJson(a, indexPath, capsulePath, idx) {
  const out = {
    report_version: REPORT_VERSION,
    wired: false,
    index_path: indexPath,
    capsule_path: capsulePath,
    index_version: idx.index_version ?? null,
    repo_head: idx.repo_head ?? null,
    files_indexed: a.total,
    flags: a.flags,
    parser_coverage: {
      real_extractor: a.shares.real_extractor,
      no_parser: a.shares.no_parser,
      by_parser: a.parsers,
    },
    symbol_coverage: {
      files_with_symbols: a.shares.with_symbols,
      symbols_extracted: a.symbolsExtracted,
      symbol_table_entries: a.symbolTable,
      symbols_partial: a.flags.symbols_partial,
    },
    test_linkage_coverage: {
      files_with_a_covering_test: a.shares.covered,
      tests_covering_heuristic: a.flags.tests_covering_heuristic,
    },
    unsupported_regions: a.regions === null ? { available: false, reason: NO_DENOM } : a.regions,
    admitted_candidate_set: a.admitted,
    confidence: a.items === null
      ? { available: false, reason: 'no capsule was given (--capsule); confidence is per admitted item' }
      : a.items.map((i) => ({
        path: i.path, confidence: i.confidence, rule: i.rule.key, rule_tier: i.rule.tier,
        parser: i.parser, symbols: i.symbols, covering_tests: i.covering_tests,
        present_in_index: i.present_in_index, because: i.clause,
      })),
    confidence_derivation: CONFIDENCE_DERIVATION,
    recommendation_tests: a.tests,
    recommended_use_state: a.state,
    recommendation_message: a.message,
    exp0004_eligibility: a.eligibility,
    limitations: LIMITATIONS,
  };
  return JSON.stringify(out, null, 2) + '\n';
}

// -------------------------------------------------------------------- main --
function main(argv) {
  const args = argv[0] === 'report' ? argv.slice(1) : argv;
  if (args.length === 0) die(`no arguments\n${usage}`);
  let indexPath = null; let capsulePath = null; let asJson = false;
  for (let i = 0; i < args.length; i++) {
    const x = args[i];
    if (x === '--index') { indexPath = args[++i]; if (!indexPath) die('--index needs a path'); }
    else if (x === '--capsule') { capsulePath = args[++i]; if (!capsulePath) die('--capsule needs a path'); }
    else if (x === '--json') asJson = true;
    else die(`unknown argument: ${x}\n${usage}`);
  }
  if (indexPath === null) die(`report needs --index <index.json>\n${usage}`);

  const idx = readJson(indexPath, 'index');
  if (!idx || typeof idx.files !== 'object' || idx.files === null) {
    die(`not a SEAM 1 index (no files map): ${indexPath}`);
  }
  const capsule = capsulePath === null ? null : readJson(capsulePath, 'capsule');
  if (capsule !== null && !Array.isArray(capsule.relevant_files)) {
    die(`not a SEAM 2 capsule (no relevant_files array): ${capsulePath}`);
  }

  const a = analyze(idx, capsule);
  process.stdout.write(asJson
    ? renderJson(a, indexPath, capsulePath, idx)
    : renderText(a, indexPath, capsulePath, idx));
  return 0;
}

const argv = process.argv.slice(2);
if (argv[0] === '--help' || argv[0] === '-h') { process.stdout.write(usage); process.exit(0); }
process.exit(main(argv));
