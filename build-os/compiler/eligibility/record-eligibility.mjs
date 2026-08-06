#!/usr/bin/env node
// POST-PILOT ELIGIBILITY WORKFLOW — steps 4 and 5: RECORD, then APPLY.
//
//   record-eligibility.mjs --report-json <p> --report-text <p> --stats <p>
//                          --repo <p> --commit <sha> --out <dir>
//                          --procedure <p> [--errors <p>] [--deterministic]
//
// STEP 4 writes the complete eligibility evidence — ELIGIBILITY.md (for a
// human) and eligibility.json (for a machine) — into the --out directory, which
// is always OUTSIDE the assessed repository. STEP 5 then applies
// AB_PREREGISTRATION AMENDMENT 1 MECHANICALLY.
//
// WHAT "MECHANICALLY" MEANS HERE, precisely, because the word is doing real
// work: this file does NOT re-derive the amendment's number from the index. The
// capability reporter already derives it, deliberately identically to
// `build-index.mjs stats`, and the pass/fail is taken FROM THE REPORTER'S OWN
// VERDICT. What this file adds is an AUDIT of that verdict against the
// reporter's own published arithmetic and against the indexer's own published
// counts. If any of those disagree, the correct action is not to prefer one:
// two instruments disagreeing about the one number a preregistered precondition
// turns on is a DEFECT in the pair, and a verdict picked out of a disagreement
// is not evidence. So the procedure REFUSES (exit 3) and says which pair
// disagreed.
//
// EXIT CODES
//   0  ELIGIBLE      — the precondition is satisfied; the caller may emit the
//                      candidate backlog.
//   1  NOT-ELIGIBLE  — the precondition FAILS. This is a legitimate outcome,
//                      not an obstacle: task selection stops here.
//   2  usage error.
//   3  REFUSED — a defect in the inputs (a disagreement, or a malformed
//                report). No verdict is issued.
//
// READ-ONLY: reads four files, writes two, all under --out. It never opens a
// path inside the assessed repository.
//
// Dependencies: node stdlib only.

import fs from 'node:fs';
import path from 'node:path';

const RECORD_VERSION = 1;
const EPOCH = '1970-01-01T00:00:00.000Z';

// AMENDMENT 1's threshold as a rational, matching report.mjs exactly so the
// audit compares like with like.
const THRESHOLD_NUM = 1;
const THRESHOLD_DEN = 2;

// The rule, quoted rather than paraphrased. A paraphrase is where a
// preregistered threshold quietly becomes a different threshold.
const RULE_SOURCE = 'build-os/compiler/AB_PREREGISTRATION.md — AMENDMENT 1 (BINDING AMENDMENT)';
const RULE_TEXT =
  'EXP-0004 may only run on a repository where the index has measured parser '
  + 'coverage. The precondition is stated as a number, not a judgement — no_parser '
  + 'share of files admitted-as-candidates must be below 50%, measured by '
  + '`build-index.mjs stats` and RECORDED in the run record before arm A begins. '
  + 'A repository failing that check is either excluded or the run is registered '
  + '`result confounded` under the existing stop conditions.';

// Where this workflow had to RESOLVE the rule rather than merely apply it. Every
// resolution is recorded in the artifact, because an unrecorded interpretation
// of a preregistered rule is exactly how a precondition gets softened later.
const RULE_INTERPRETATION = [
  'ADMITTED-CANDIDATE SET = THE WHOLE INDEX. The amendment measures "files '
  + 'admitted-as-candidates", which is a capsule-scoped set, but also names '
  + '`build-index.mjs stats` as the instrument, which is whole-index. Before task '
  + 'selection no capsule exists, so the two readings coincide and the report is '
  + 'run WITHOUT --capsule. This assessment is therefore about the REPOSITORY. It '
  + 'does not license any particular task: a per-task capsule can have a worse '
  + 'no_parser share than the repository it was drawn from, and AMENDMENT 1 would '
  + 'then have to be re-applied to that capsule.',
  'STRICTLY BELOW. "below 50%" is read as strict inequality (2*n < total) and '
  + 'compared in integer arithmetic, so a repository sitting exactly on one half '
  + 'is NOT eligible and no rounding decides a preregistered precondition.',
  'THE EMPTY REPOSITORY. The amendment gives no rule for a zero-file index. The '
  + 'reporter treats an empty admitted set as NOT-ELIGIBLE ("not computable"), '
  + 'which this procedure follows: an unmeasurable precondition is not a satisfied '
  + 'one.',
  'EXCLUDED **OR** CONFOUNDED. On failure the amendment offers two dispositions '
  + '— exclude the repository, or run and register `result confounded` — and no '
  + 'rule for choosing. This procedure takes the conservative branch (STOP, do not '
  + 'select tasks) and leaves the other branch to an explicit operator decision. '
  + 'It records the choice rather than presenting it as forced.',
];

const LIMITATIONS = [
  'Every number here is inherited from SEAM 1 and is only as good as SEAM 1: v0 '
  + 'extraction is regex or line based, never an AST, so "no_parser" means "no '
  + 'extractor ran", and a parsed file is not thereby an understood file.',
  'tests_covering is an import-or-basename heuristic, not executed coverage, so '
  + 'test-linkage coverage overstates linkage wherever names coincide.',
  'A PASS here is a statement about the INDEX, not a prediction that a capsule '
  + 'compiled from it will be correct or that EXP-0004 will find a benefit. '
  + 'AMENDMENT 1 is a precondition, not a hypothesis.',
  'The assessment pins one commit. It expires the moment that commit moves: the '
  + 'indexer reads WORKTREE bytes, so a later dirty tree or a later commit is a '
  + 'different measurement and needs a fresh run.',
];

function die(msg) {
  process.stderr.write(`record-eligibility: ${msg}\n`);
  process.exit(2);
}

function readText(p, what) {
  try { return fs.readFileSync(p, 'utf8'); }
  catch (e) { die(`cannot read ${what} ${p}: ${e.message}`); }
  return '';
}

function readJson(p, what) {
  const raw = readText(p, what);
  try { return JSON.parse(raw); }
  catch (e) { die(`${what} ${p} is not valid JSON: ${e.message}`); }
  return null;
}

// --------------------------------------------------------- stats parsing --
// The indexer's `stats` output is the amendment's named instrument. It is
// parsed, not trusted to match the reporter: comparing the two IS the audit.
function parseStats(text) {
  const num = (re) => { const m = re.exec(text); return m ? Number(m[1]) : null; };
  const str = (re) => { const m = re.exec(text); return m ? m[1].trim() : null; };
  return {
    index_version: num(/^index_version:\s*(\d+)\s*$/m),
    repo_head: str(/^repo_head:\s*(\S+)\s*$/m),
    files_indexed: num(/^files_indexed:\s*(\d+)\s*$/m),
    with_symbols: num(/^with_symbols:\s*(\d+)\s*\(/m),
    no_parser: num(/^no_parser:\s*(\d+)\s*\(/m),
    no_parser_pct: str(/^no_parser:\s*\d+\s*\(([^)]*)\)/m),
    files_with_a_covering_test: num(/^files_with_a_covering_test:\s*(\d+)\s*\(/m),
  };
}

// The reporter's rendered verdict line, taken VERBATIM. The evidence record
// quotes the instrument rather than restating it.
function verdictLineOf(reportText) {
  const m = /^VERDICT:.*$/m.exec(reportText);
  return m ? m[0].trim() : null;
}

function readProcedure(p) {
  if (!p || !fs.existsSync(p)) return [];
  return readText(p, 'procedure log').split('\n').filter(Boolean).map((line) => {
    const [n, name, status, ...rest] = line.split('\t');
    return { step: Number(n), name, status, detail: rest.join('\t') };
  });
}

// ------------------------------------------------------------ the audits --
// Each audit names the two things that must agree and returns null when they
// do. Order matters: structure, then provenance, then derivation parity, then
// the verdict itself — so the most specific cause is the one reported.
function audit(report, stats, commit) {
  const el = report.exp0004_eligibility;
  const pc = report.parser_coverage;
  const ac = report.admitted_candidate_set;

  const bad = (what, a, b, extra = []) => ({ what, a, b, extra });

  if (!el || typeof el !== 'object') return bad('malformed capability report', 'exp0004_eligibility', 'absent');
  if (!pc || !pc.no_parser || typeof pc.no_parser.n !== 'number') {
    return bad('malformed capability report', 'parser_coverage.no_parser.n', 'absent or not a number');
  }
  if (!ac || typeof ac.total !== 'number' || typeof ac.no_parser !== 'number') {
    return bad('malformed capability report', 'admitted_candidate_set', 'absent or not numeric');
  }

  if (stats.index_version === null || stats.files_indexed === null || stats.no_parser === null) {
    return bad('unreadable indexer stats',
      'build-index.mjs stats', 'could not be parsed for index_version / files_indexed / no_parser');
  }

  // Provenance: both instruments must be describing the commit that was pinned.
  if (stats.repo_head !== commit) {
    return bad('the index was not built from the pinned commit',
      `pinned commit ${commit}`, `build-index.mjs stats repo_head ${stats.repo_head}`,
      ['An index built from another revision cannot certify this one.']);
  }
  if (report.repo_head !== commit) {
    return bad('the capability report was not computed from the pinned commit',
      `pinned commit ${commit}`, `capability report repo_head ${report.repo_head}`);
  }

  // Derivation parity with the amendment's NAMED instrument.
  if (stats.files_indexed !== report.files_indexed) {
    return bad('the indexer and the reporter disagree about how many files exist',
      `build-index.mjs stats files_indexed ${stats.files_indexed}`,
      `capability report files_indexed ${report.files_indexed}`);
  }
  if (stats.no_parser !== pc.no_parser.n) {
    return bad('the indexer and the reporter disagree about the no_parser count',
      `build-index.mjs stats no_parser ${stats.no_parser}`,
      `capability report parser_coverage.no_parser.n ${pc.no_parser.n}`,
      ['This is the ONE number AMENDMENT 1 turns on. The reporter documents that it',
        'derives it identically to `build-index.mjs stats`; here it did not.']);
  }
  // No capsule is given at repository-assessment time, so the admitted set must
  // BE the index. If it is not, the reporter measured something else.
  if (ac.total !== report.files_indexed || ac.no_parser !== stats.no_parser) {
    return bad('the admitted-candidate set is not the whole index',
      `admitted ${ac.no_parser}/${ac.total}`,
      `index ${stats.no_parser}/${report.files_indexed}`,
      ['This assessment runs the reporter WITHOUT --capsule precisely so the two',
        'coincide; a divergence means the report is not about this repository.']);
  }
  if (el.measured_no_parser !== ac.no_parser || el.measured_total !== ac.total) {
    return bad('the reporter\'s eligibility numbers are not its own admitted-set numbers',
      `eligibility ${el.measured_no_parser}/${el.measured_total}`,
      `admitted ${ac.no_parser}/${ac.total}`);
  }

  // The reporter's two renderings of its own verdict.
  return null;
}

// ------------------------------------------------------------- rendering --
function shareText(s) {
  if (!s || typeof s !== 'object') return 'unavailable (the report carried no such share)';
  return typeof s.text === 'string' ? s.text : 'unavailable (malformed share)';
}

function renderMd(rec) {
  const L = [];
  const el = rec.eligibility_rule;
  const pcov = rec.parser_coverage || {};
  const scov = rec.symbol_coverage || {};
  const tcov = rec.test_linkage_coverage || {};
  L.push(`# EXP-0004 ELIGIBILITY ASSESSMENT — ${path.basename(rec.repo)}`);
  L.push('');
  L.push(`DISPOSITION: ${rec.disposition_line}`);
  L.push('');
  L.push('This file IS the run record AMENDMENT 1 requires to exist "before arm A begins".');
  L.push('It is written by one bounded procedure, from one pinned commit, and every');
  L.push('number in it is copied from an instrument rather than restated by hand.');
  L.push('');
  L.push('== WHAT WAS ASSESSED ==');
  L.push(`repo: ${rec.repo}`);
  L.push(`pinned_commit: ${rec.pinned_commit}`);
  L.push(`tree_state_at_assessment: ${rec.tree_state}`);
  L.push(`index_version: ${rec.index_version}`);
  L.push(`files_indexed: ${rec.files_indexed}`);
  L.push(`errors_input: ${rec.errors_input}`);
  L.push(`timestamp: ${rec.timestamp}${rec.deterministic ? ' (--deterministic: zeroed on purpose)' : ''}`);
  L.push('');
  L.push('== PROCEDURE (each step recorded as it ran) ==');
  for (const s of rec.steps) L.push(`  ${s.step}. ${s.name.padEnd(20)} ${s.status.padEnd(8)} ${s.detail}`);
  L.push('');
  L.push('== PARSER COVERAGE ==');
  L.push(`files with a real extractor: ${shareText(pcov.real_extractor)}`);
  L.push(`no_parser (the amendment's number): ${shareText(rec.no_parser_share)}`);
  L.push(`cross-checked against build-index.mjs stats: no_parser ${rec.indexer_stats.no_parser}`
    + `/${rec.indexer_stats.files_indexed} (${rec.indexer_stats.no_parser_pct}) — `
    + `${rec.stats_parity ? 'AGREES' : 'DISAGREES (see DISPOSITION)'}`);
  for (const p of pcov.by_parser || []) {
    L.push(`  ${String(p.parser).padEnd(20)} ${shareText(p.share)}`);
  }
  L.push('a file whose parser is "none" was NOT read by the indexer: its empty symbol');
  L.push('list is not evidence that it defines nothing.');
  L.push('');
  L.push('== SYMBOL COVERAGE ==');
  L.push(`files with >=1 extracted symbol: ${shareText(scov.files_with_symbols)}`);
  L.push(`symbols extracted (sum over files): ${scov.symbols_extracted}`);
  L.push(`symbol table entries: ${scov.symbol_table_entries}`);
  L.push(`symbols_partial: ${scov.symbols_partial} — referenced_in is a whole-word text match.`);
  L.push('');
  L.push('== TEST-LINKAGE COVERAGE ==');
  L.push(`files with >=1 tests_covering entry: ${shareText(tcov.files_with_a_covering_test)}`);
  L.push(`tests_covering_heuristic: ${tcov.tests_covering_heuristic}`
    + ' — import-or-basename matching, not executed coverage.');
  L.push('');
  L.push(`== RECOMMENDED USE STATE: ${rec.recommended_use_state} ==`);
  for (const m of rec.recommendation_message || []) L.push(m);
  L.push('');
  L.push('== THE RULE APPLIED, VERBATIM ==');
  L.push(`source: ${el.source}`);
  // Deliberately NOT re-wrapped. A preregistered rule is quoted as one
  // unbroken string so that searching this record for the rule's own words
  // finds them — a re-flowed threshold is one edit away from a changed one.
  L.push(`  > ${el.text}`);
  L.push('');
  L.push('interpretation recorded (an unrecorded reading of a preregistered rule is how');
  L.push('a precondition gets softened later):');
  for (const line of el.interpretation_wrapped) L.push(line === '' ? '' : `  ${line}`);
  L.push('');
  L.push('== THE ARITHMETIC, SHOWN ==');
  L.push(`measured over: ${el.measured_over}`);
  L.push(`no_parser: ${shareText(rec.no_parser_share)}`);
  L.push(`reporter's exact test (integer arithmetic, no rounding): ${el.reporter_exact_test}`);
  L.push(`independent recomputation from the same two integers: ${el.mechanical_arithmetic}`);
  L.push(`  => mechanical verdict: ${el.mechanical_verdict}`);
  L.push(`  => reporter verdict:   ${el.reporter_verdict}`);
  L.push(`  => they ${el.agreed ? 'AGREE' : 'DISAGREE'}.`);
  L.push('');
  L.push('== THE REPORTER\'S VERDICT LINE, VERBATIM ==');
  L.push(rec.reporter_verdict_line === null
    ? '(absent — the capability report printed no VERDICT line, which is itself the defect)'
    : rec.reporter_verdict_line);
  L.push('');
  L.push('== DISPOSITION ==');
  for (const line of rec.disposition_body) L.push(line);
  L.push('');
  L.push('== LIMITATIONS OF THIS ASSESSMENT ==');
  for (const l of rec.limitations) {
    const lines = wrap(l, 74);
    L.push(`  * ${lines[0]}`);
    for (const cont of lines.slice(1)) L.push(`    ${cont}`);
  }
  L.push('');
  L.push('== ARTIFACTS (all outside the assessed repository, which was never written to) ==');
  for (const a of rec.artifacts) L.push(`  ${a}`);
  L.push('');
  return L.join('\n') + '\n';
}

// Wrap long prose so the markdown record stays readable without depending on a
// renderer. Deterministic: pure function of the input string.
function wrap(text, width = 78) {
  const out = [];
  for (const para of String(text).split('\n')) {
    let line = '';
    for (const word of para.split(/\s+/).filter(Boolean)) {
      if (line === '') line = word;
      else if ((line + ' ' + word).length <= width) line += ' ' + word;
      else { out.push(line); line = word; }
    }
    out.push(line);
  }
  return out;
}

// ------------------------------------------------------------------ main --
function main(argv) {
  const opt = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const take = (k) => { opt[k] = argv[++i]; if (opt[k] === undefined) die(`${a} needs a value`); };
    if (a === '--report-json') take('reportJson');
    else if (a === '--report-text') take('reportText');
    else if (a === '--stats') take('stats');
    else if (a === '--repo') take('repo');
    else if (a === '--commit') take('commit');
    else if (a === '--out') take('out');
    else if (a === '--procedure') take('procedure');
    else if (a === '--errors') take('errors');
    else if (a === '--tree-state') take('treeState');
    else if (a === '--deterministic') opt.deterministic = true;
    else die(`unknown argument: ${a}`);
  }
  for (const k of ['reportJson', 'reportText', 'stats', 'repo', 'commit', 'out']) {
    if (!opt[k]) die(`missing required argument --${k.replace(/[A-Z]/g, (c) => '-' + c.toLowerCase())}`);
  }

  const report = readJson(opt.reportJson, 'capability report (json)');
  const reportText = readText(opt.reportText, 'capability report (text)');
  const stats = parseStats(readText(opt.stats, 'indexer stats'));
  const steps = readProcedure(opt.procedure);
  const verdictLine = verdictLineOf(reportText);

  // ---- STEP 5, part 1: audit the instruments against each other.
  let refusal = audit(report, stats, opt.commit);

  const el = report.exp0004_eligibility || {};
  const reporterVerdict = typeof el.verdict === 'string' ? el.verdict : '(absent)';

  // The reporter's two renderings of its own verdict must match, or the
  // artifact a human reads and the artifact a machine reads are different
  // claims.
  if (!refusal) {
    if (verdictLine === null) {
      refusal = { what: 'the capability report printed no verdict line', a: 'text report VERDICT line', b: 'absent', extra: [] };
    } else if (verdictLine !== `VERDICT: ${reporterVerdict}`) {
      refusal = {
        what: 'the reporter\'s json verdict and its rendered verdict line disagree',
        a: `json exp0004_eligibility.verdict: ${reporterVerdict}`,
        b: `text verdict line: ${verdictLine}`,
        extra: ['The human-readable record and the machine-readable record would'
          + ' otherwise carry different claims about the same run.'],
      };
    }
  }

  // ---- STEP 5, part 2: the rule itself, recomputed from the reporter's own
  // two integers. This is an AUDIT of the reporter's arithmetic, not a second
  // opinion about the repository.
  const n = Number(el.measured_no_parser);
  const total = Number(el.measured_total);
  const lhs = n * THRESHOLD_DEN;
  const rhs = total * THRESHOLD_NUM;
  const mechanicalEligible = Number.isInteger(n) && Number.isInteger(total) && total > 0 && lhs < rhs;
  const mechanicalVerdict = mechanicalEligible ? 'ELIGIBLE' : 'NOT-ELIGIBLE';
  const mechanicalArithmetic = Number.isInteger(n) && Number.isInteger(total)
    ? (total === 0
      ? 'not computable: the index describes no files, so there is no share to compare'
      : `${THRESHOLD_DEN} * ${n} = ${lhs} < ${rhs} (files) ? ${lhs < rhs ? 'yes' : 'no'}`)
    : 'not computable: the report did not carry two integers to compare';

  if (!refusal && mechanicalVerdict !== reporterVerdict) {
    refusal = {
      what: 'the reporter\'s verdict and the mechanical rule disagree',
      a: `reporter verdict: ${reporterVerdict}`,
      b: `mechanical verdict: ${mechanicalVerdict} (${mechanicalArithmetic})`,
      extra: ['Both were computed from the SAME two integers the report published,',
        'so exactly one of them is wrong and nothing here can tell which.'],
    };
  }

  const agreed = refusal === null;
  const verdict = agreed ? reporterVerdict : 'REFUSED';
  const disposition = agreed ? (verdict === 'ELIGIBLE' ? 'ELIGIBLE' : 'NOT-ELIGIBLE') : 'REFUSED';

  const dispositionLine = {
    ELIGIBLE: 'ELIGIBLE — AMENDMENT 1\'s precondition is satisfied at this commit; candidate backlog emitted',
    'NOT-ELIGIBLE': 'NOT-ELIGIBLE — AMENDMENT 1\'s precondition FAILS at this commit; task selection STOPS',
    REFUSED: 'REFUSED — a defect in the instruments; no verdict was issued',
  }[disposition];

  const dispositionBody = {
    ELIGIBLE: [
      'The precondition is satisfied. What that licenses, exactly: EXP-0004 MAY be run',
      'against this repository at this commit, and the candidate backlog beside this',
      'file may be read. It is a backlog of CANDIDATES, not a selection — selecting and',
      'freezing tasks is a separate, operator-gated step.',
      'What it does NOT license: it is not evidence that compilation helps, and it does',
      'not carry over to a later commit or to a per-task capsule.',
    ],
    'NOT-ELIGIBLE': [
      'STOP. Task selection MUST NOT proceed for this repository, and the compiler',
      'should be BYPASSED here: let the worker read and search the repository the',
      'ordinary way.',
      '',
      'THIS IS A LEGITIMATE OUTCOME, NOT A FAILURE TO WORK AROUND. AMENDMENT 1 exists',
      'because a capsule built from an unparsed index is small-because-uninformed, and',
      'an A/B run here would measure a compiler operating nearly blind — registering',
      'outcome 4 for a reason that has nothing to do with the compression thesis. The',
      'honest response is to exclude the repository (or, by explicit operator decision,',
      'to run it and register `result confounded` under the existing stop conditions).',
      'Lowering the threshold, re-scoping the file set until the number passes, or',
      'running anyway without recording this are all ways of losing the experiment.',
      'The other legitimate route to eligibility is to BUILD signal: the amendment says',
      'so itself — adding a shell extractor to the indexer would satisfy the check, and',
      'that is a build decision, not an amendment to the rule.',
    ],
    REFUSED: [
      'NO VERDICT WAS ISSUED. Two instruments that must agree did not, and this',
      'procedure will not choose between them: a pass or a fail selected out of a',
      'disagreement is not evidence, and it would be recorded as though it were.',
      'Fix the defect and re-run. Do not proceed to task selection on either reading.',
    ],
  }[disposition];

  const timestamp = opt.deterministic ? EPOCH : new Date().toISOString();

  // Steps 4 and 5 belong to this program, so it writes them itself — into the
  // record AND into the shared step log, which is why the two never drift.
  const ownSteps = [
    { step: 4, name: 'record-evidence', status: 'ok', detail: 'ELIGIBILITY.md, eligibility.json' },
    {
      step: 5,
      name: 'apply-rule',
      status: agreed ? 'ok' : 'refused',
      detail: agreed
        ? `reporter ${reporterVerdict} == mechanical ${mechanicalVerdict} (${mechanicalArithmetic})`
        : `disagreement: ${refusal.what}`,
    },
  ];

  const rec = {
    record_version: RECORD_VERSION,
    workflow: 'post-pilot eligibility assessment (AB_PREREGISTRATION AMENDMENT 1)',
    repo: opt.repo,
    pinned_commit: opt.commit,
    tree_state: opt.treeState || 'clean (verified before indexing)',
    timestamp,
    deterministic: opt.deterministic === true,
    index_version: report.index_version === null || report.index_version === undefined
      ? stats.index_version : report.index_version,
    files_indexed: report.files_indexed,
    errors_input: opt.errors
      ? opt.errors
      : 'none given (--errors absent): error_count is null on every file, which is not a claim of zero errors',
    verdict,
    disposition,
    disposition_line: dispositionLine,
    disposition_body: dispositionBody,
    reporter_verdict_line: verdictLine,
    recommended_use_state: report.recommended_use_state,
    recommendation_message: report.recommendation_message,
    no_parser_share: (report.parser_coverage || {}).no_parser,
    stats_parity: stats.no_parser !== null
      && stats.no_parser === (((report.parser_coverage || {}).no_parser || {}).n)
      && stats.files_indexed === report.files_indexed,
    parser_coverage: report.parser_coverage,
    symbol_coverage: report.symbol_coverage,
    test_linkage_coverage: report.test_linkage_coverage,
    indexer_stats: stats,
    eligibility_rule: {
      source: RULE_SOURCE,
      text: RULE_TEXT,
      text_is_verbatim: true,
      interpretation: RULE_INTERPRETATION,
      interpretation_wrapped: RULE_INTERPRETATION.flatMap((t) => [...wrap(t), '']),
      threshold: 'strictly below one half, integer arithmetic',
      measured_over: el.measured_over || '(absent)',
      measured_no_parser: Number.isInteger(n) ? n : null,
      measured_total: Number.isInteger(total) ? total : null,
      reporter_exact_test: el.exact_test || '(absent)',
      reporter_verdict: reporterVerdict,
      mechanical_arithmetic: mechanicalArithmetic,
      mechanical_verdict: mechanicalVerdict,
      agreed,
    },
    refusal: refusal === null ? null : {
      what: refusal.what, side_a: refusal.a, side_b: refusal.b, notes: refusal.extra || [],
    },
    steps: [...steps, ...ownSteps],
    artifacts: [
      'index.json — the SEAM 1 index of the pinned commit',
      'index-stats.txt — build-index.mjs stats, the amendment\'s named instrument',
      'index-build.log — the indexer\'s own stderr report',
      'capability-report.txt — the capability reporter, human form',
      'capability-report.json — the capability reporter, machine form',
      'ELIGIBILITY.md / eligibility.json — this record',
      'procedure.tsv — the step log',
      ...(disposition === 'ELIGIBLE'
        ? ['CANDIDATES.md / candidates.json — the candidate backlog (candidates, NOT a selection)']
        : ['(no candidate backlog: one is emitted only on ELIGIBLE)']),
    ],
    limitations: LIMITATIONS,
  };

  fs.writeFileSync(path.join(opt.out, 'eligibility.json'), JSON.stringify(rec, null, 2) + '\n');
  fs.writeFileSync(path.join(opt.out, 'ELIGIBILITY.md'), renderMd(rec));
  if (opt.procedure) {
    fs.appendFileSync(opt.procedure,
      ownSteps.map((s) => `${s.step}\t${s.name}\t${s.status}\t${s.detail}`).join('\n') + '\n');
  }

  if (refusal) {
    const L = [];
    L.push('REFUSED — DEFECT: two instruments that must agree do not.');
    L.push(`  what disagreed: ${refusal.what}`);
    L.push(`  ${refusal.a}`);
    L.push(`  ${refusal.b}`);
    for (const x of refusal.extra || []) L.push(`  ${x}`);
    L.push('  This is a defect in the pair, not a judgement call, and this procedure');
    L.push('  will not choose between them. No eligibility verdict was issued and no');
    L.push('  candidate backlog was emitted. Fix the defect and re-run.');
    process.stderr.write(L.join('\n') + '\n');
    return 3;
  }
  return verdict === 'ELIGIBLE' ? 0 : 1;
}

process.exit(main(process.argv.slice(2)));
