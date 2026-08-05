'use strict';

// EXP-0002 — machine acceptance oracles for the sustained-workload sequence.
//
// WHY THESE ARE EXTERNAL. An acceptance criterion that lives inside the repo
// under test is a criterion the model can read, satisfy literally, and
// optimise against. These oracles are never copied into the work tree and
// never named in a task prompt. They are applied from outside — by the runner
// against the final tree, and by the runner's poller against a COPY of the
// tree (so polling can never perturb the run).
//
// WHY THEY ARE MECHANICAL. The criterion for every task was fixed before any
// run and is decidable by executing code: suites are run, the CLI is run,
// bytes are compared, transplants are executed. No prose grading, no model
// self-report. Where a check is a stated PROXY (T1's "names the defective
// function", T3/T5's "a test file mentions X"), the limit is named at the
// check site.
//
// SEQUENTIAL-TREE NOTE. The candidate tree EVOLVES across the arm's five
// tasks (T3's tree contains DIAGNOSIS.md and the T2 fix, and so on). Every
// check below is valid on the evolved tree: T3's worked examples avoid the
// tier boundaries, so they hold whether or not T2's fix is present, and diff
// checks are used only where the task itself forbids other change (T1).
//
// Usage: node oracle-exp2.js <T1|T2|T3|T4|T5> <candidate-dir> <pristine-dir>
//   <pristine-dir> is the arm's baseline: the tree as the FIRST session first
//   saw it (seed + arm surface), captured by run-exp2-task.sh before T1.
// Exit:  0 accepted, 1 not accepted, 2 harness error.
// Prints one line: "ACCEPT <task>[ — detail]" or "REJECT <task> — <reason>".

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');

const [, , task, candidateArg, pristineArg] = process.argv;
if (!task || !candidateArg || !pristineArg) {
  console.error('usage: node oracle-exp2.js <T1|T2|T3|T4|T5> <candidate-dir> <pristine-dir>');
  process.exit(2);
}
const CAND = path.resolve(candidateArg);
const SEED = path.resolve(pristineArg);

// The seeded suite's exact totals; seed-workload-repo.sh freezes them.
const SEED_TOTAL_PASSED = 19;
const SEED_TOTAL_FAILED = 0;

function reject(reason) {
  console.log('REJECT ' + task + ' — ' + reason);
  process.exit(1);
}
function accept(detail) {
  console.log('ACCEPT ' + task + (detail ? ' — ' + detail : ''));
  process.exit(0);
}

function copyTree(src) {
  const dst = fs.mkdtempSync(path.join(os.tmpdir(), 'oracle-exp2-'));
  fs.cpSync(src, dst, { recursive: true });
  return dst;
}

function mkTmp() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'oracle-exp2-fix-'));
}

// Run the project's own test command and parse its machine-readable last line.
function runSuite(dir) {
  let out = '';
  let exitCode = 0;
  try {
    out = execFileSync('node', ['test/run.js'], {
      cwd: dir,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
      timeout: 120000,
    });
  } catch (e) {
    out = (e.stdout || '') + (e.stderr || '');
    exitCode = typeof e.status === 'number' ? e.status : 1;
  }
  const m = out.match(/TOTAL: (\d+) passed, (\d+) failed/);
  if (!m) return { passed: null, failed: null, exitCode, out };
  return { passed: Number(m[1]), failed: Number(m[2]), exitCode, out };
}

// Run the candidate's CLI in a child process with cwd = candidate.
function runCli(dir, args) {
  try {
    const stdout = execFileSync('node', ['bin/cli.js', ...args], {
      cwd: dir,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
      timeout: 60000,
    });
    return { code: 0, stdout, stderr: '' };
  } catch (e) {
    return {
      code: typeof e.status === 'number' ? e.status : 1,
      stdout: e.stdout || '',
      stderr: e.stderr || '',
    };
  }
}

// Evaluate an expression inside the candidate, in a child process, so a
// candidate that throws on load cannot take the oracle with it.
function probe(dir, body) {
  try {
    const out = execFileSync('node', ['-e', body], {
      cwd: dir,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
      timeout: 60000,
    });
    const line = out.trim().split('\n').filter(Boolean).pop();
    return JSON.parse(line);
  } catch (e) {
    return null;
  }
}

function near(a, b) {
  return typeof a === 'number' && Math.abs(a - b) < 1e-9;
}

// ARM-SURFACE PATHS ARE NOT TASK OUTPUT. Arm B carries .claude/, build-os/,
// CLAUDE.md etc.; the pristine baseline already contains them (it is captured
// AFTER arm install), but the agent may legitimately UPDATE them (memory,
// receipts) without that being task output. Excluding them keeps the same
// oracle valid for both arms — the protocol's "same checker for both arms".
const ARM_SURFACE = /^(\.claude(\/|$)|build-os(\/|$)|CLAUDE\.md$|\.mcp\.json$|\.gitignore$)/;

function changedFiles(cand, seed) {
  const list = (root) => {
    const acc = [];
    const walk = (d, rel) => {
      for (const e of fs.readdirSync(path.join(root, d), { withFileTypes: true })) {
        const r = rel ? rel + '/' + e.name : e.name;
        if (e.name === '.git' || e.name === 'node_modules') continue;
        if (ARM_SURFACE.test(r)) continue;
        if (e.isDirectory()) walk(path.join(d, e.name), r);
        else acc.push(r);
      }
    };
    walk('.', '');
    return acc;
  };
  const seedFiles = new Set(list(seed));
  const candFiles = list(cand);
  const changed = [];
  for (const f of candFiles) {
    if (!seedFiles.has(f)) {
      changed.push(f);
      continue;
    }
    const a = fs.readFileSync(path.join(cand, f));
    const b = fs.readFileSync(path.join(seed, f));
    if (!a.equals(b)) changed.push(f);
  }
  for (const f of seedFiles) if (!candFiles.includes(f)) changed.push(f + ' (deleted)');
  return changed.sort();
}

// Fixture orders used by T3/T5 checks — copied verbatim from SPEC-T3.md's
// worked examples plus the cap order the spec's formulas determine.
const ORD_B = {
  id: 'ORD-B',
  zone: 'domestic',
  discountCode: 'SAVE10',
  items: [
    { description: 'Books', quantity: 1, weightKg: 2, dimensionsCm: { length: 20, width: 15, height: 10 } },
    { description: 'Monitor', quantity: 1, weightKg: 7, dimensionsCm: { length: 60, width: 45, height: 20 } },
  ],
};
const ORD_C = {
  id: 'ORD-C',
  zone: 'international',
  discountCode: 'FREESHIP',
  items: [{ description: 'Desk', quantity: 1, weightKg: 30, dimensionsCm: { length: 100, width: 60, height: 10 } }],
};
const ORD_E = {
  id: 'ORD-E',
  zone: 'domestic',
  discountCode: 'SAVE10',
  items: [{ description: 'Engine', quantity: 1, weightKg: 720, dimensionsCm: { length: 100, width: 60, height: 10 } }],
};
const ORD_BOGUS = {
  id: 'ORD-D',
  zone: 'domestic',
  discountCode: 'BOGUS',
  items: [{ description: 'Books', quantity: 1, weightKg: 2, dimensionsCm: { length: 20, width: 15, height: 10 } }],
};

const EXPECT_B = [
  'INVOICE ORD-B',
  'ITEM Books qty=1 billable_kg=2.00 tier=small amount=8.00',
  'ITEM Monitor qty=1 billable_kg=10.80 tier=medium amount=15.00',
  'SHIPPING zone=domestic amount=4.50',
  'SUBTOTAL 23.00',
  'DISCOUNT code=SAVE10 amount=2.30',
  'TAX 1.45',
  'TOTAL 26.65',
  '',
].join('\n');
const EXPECT_C = [
  'INVOICE ORD-C',
  'ITEM Desk qty=1 billable_kg=30.00 tier=large amount=41.00',
  'SHIPPING zone=international amount=0.00',
  'SUBTOTAL 41.00',
  'DISCOUNT code=FREESHIP amount=22.00',
  'TAX 2.87',
  'TOTAL 43.87',
  '',
].join('\n');
// The seeded no-discount output for test/fixtures/order-a.json, which
// SPEC-T3.md requires to remain byte-identical.
const EXPECT_A = [
  'INVOICE ORD-A',
  'ITEM Books qty=1 billable_kg=2.00 tier=small amount=8.00',
  'ITEM Monitor qty=1 billable_kg=10.80 tier=medium amount=15.00',
  'SHIPPING zone=domestic amount=4.50',
  'SUBTOTAL 23.00',
  'TAX 1.61',
  'TOTAL 29.11',
  '',
].join('\n');
const UNKNOWN_CODE_LINE = 'parcel-billing: unknown discount code: BOGUS';

function writeOrder(dir, name, order) {
  const p = path.join(dir, name);
  fs.writeFileSync(p, JSON.stringify(order));
  return p;
}

// Does any test file (other than run.js) contain `needle`? A stated PROXY for
// "tests were added for X": it checks that test code references the feature,
// not that the tests are good — "good tests" is not machine-decidable here.
function testFilesMention(dir, needle) {
  const testDir = path.join(dir, 'test');
  if (!fs.existsSync(testDir)) return false;
  for (const f of fs.readdirSync(testDir)) {
    if (!f.endsWith('.js') || f === 'run.js') continue;
    if (fs.readFileSync(path.join(testDir, f), 'utf8').includes(needle)) return true;
  }
  return false;
}

// ============================================================ T1 ============
// "Find it, and write DIAGNOSIS.md ... Change no code."
// Checked: DIAGNOSIS.md exists at the root; it names lib/pricing.js AND the
// actually-defective function (tierFor); and the tree is otherwise UNCHANGED
// against the arm baseline (arm-surface paths excluded).
// STATED LIMIT: prose is not graded. "Names the defective function" is
// operationalised as the strings "pricing.js" and "tierFor" both appearing —
// a diagnosis of the right file and function cannot avoid naming them.
function checkT1() {
  const p = path.join(CAND, 'DIAGNOSIS.md');
  if (!fs.existsSync(p)) return reject('DIAGNOSIS.md does not exist at the repo root');
  const text = fs.readFileSync(p, 'utf8');
  if (!text.includes('pricing.js')) return reject('DIAGNOSIS.md does not name lib/pricing.js');
  if (!text.includes('tierFor')) {
    return reject('DIAGNOSIS.md does not name the defective function (tierFor)');
  }
  const changed = changedFiles(CAND, SEED);
  const strays = changed.filter((f) => f !== 'DIAGNOSIS.md');
  if (strays.length) {
    return reject('the task forbids code change, but the tree diverges from the baseline beyond DIAGNOSIS.md: ' + strays.join(', '));
  }
  if (!changed.includes('DIAGNOSIS.md')) return reject('DIAGNOSIS.md missing from the diff (harness inconsistency)');
  return accept('DIAGNOSIS.md names lib/pricing.js and tierFor; no other file changed');
}

// ============================================================ T2 ============
// "Write a failing test that reproduces it ... fix the defect ... full suite
// green." Three executed halves:
//   1. the boundary now matches the spec comment (5 kg is small/8.00; the
//      other tiers unchanged — no regression);
//   2. the full suite is green and LARGER than the seeded suite;
//   3. THE DIFFERENTIAL: the candidate's test directory transplanted onto the
//      PRISTINE (still-buggy) source must FAIL. Only that proves the new test
//      would actually have caught the defect.
function checkT2() {
  const r = probe(
    CAND,
    "const p=require('./lib/pricing');const g=(f)=>{try{return f()}catch(e){return 'THREW'}};" +
      'console.log(JSON.stringify({' +
      'b5:g(()=>p.tierFor(5)),p5:g(()=>p.basePriceUsd(5)),' +
      'b20:g(()=>p.tierFor(20)),' +
      "s:g(()=>p.tierFor(2)),m:g(()=>p.tierFor(12)),l:g(()=>p.tierFor(30)),p30:g(()=>p.basePriceUsd(30))" +
      '}))'
  );
  if (!r) return reject('candidate lib/pricing.js failed to load');
  if (r.b5 !== 'small') return reject('tierFor(5) is ' + JSON.stringify(r.b5) + '; the spec comment says limits are INCLUSIVE, so exactly 5 kg is small');
  if (!near(r.p5, 8)) return reject('basePriceUsd(5) is ' + JSON.stringify(r.p5) + ', expected 8 (small tier)');
  if (r.b20 !== 'medium') return reject('tierFor(20) is ' + JSON.stringify(r.b20) + ', expected medium (20 kg limit is inclusive)');
  if (r.s !== 'small' || r.m !== 'medium' || r.l !== 'large' || !near(r.p30, 41)) {
    return reject('non-boundary tier behaviour regressed: ' + JSON.stringify(r));
  }

  const suite = runSuite(CAND);
  if (suite.passed === null) return reject('test command produced no TOTAL line');
  if (suite.failed !== 0) return reject('candidate suite is not green: ' + suite.failed + ' failed');
  if (suite.passed <= SEED_TOTAL_PASSED) {
    return reject('no test was added: candidate reports ' + suite.passed + ' passed, seeded suite was ' + SEED_TOTAL_PASSED);
  }

  // THE DIFFERENTIAL — candidate tests + pristine buggy source must FAIL.
  const tmp = copyTree(SEED);
  fs.rmSync(path.join(tmp, 'test'), { recursive: true, force: true });
  fs.cpSync(path.join(CAND, 'test'), path.join(tmp, 'test'), { recursive: true });
  const pre = runSuite(tmp);
  fs.rmSync(tmp, { recursive: true, force: true });
  if (pre.passed === null) {
    return reject('differential run produced no TOTAL line (candidate tests may depend on new source files)');
  }
  if (pre.failed === 0) {
    return reject('the added test PASSES against the unfixed source — it does not catch the defect');
  }
  return accept(
    'boundary matches spec, suite green at ' + suite.passed + ' passed, transplanted tests fail pre-fix (' + pre.failed + ' failed)'
  );
}

// ============================================================ T3 ============
// "Implement SPEC-T3.md exactly." The criterion is the spec's own frozen
// worked examples, reproduced EXACTLY through bin/cli.js, plus the exact
// error case, plus no-discount output unchanged, plus the spec's named
// architecture file, plus a green suite.
// KNOWN, DELIBERATE LIMIT: no worked example exercises the SAVE10 cap, so a
// correct-but-narrow implementation ACCEPTS here — that is the designed gap
// inject-t4.sh's regression test closes at T4.
function checkT3() {
  if (!fs.existsSync(path.join(CAND, 'lib', 'discount.js'))) {
    return reject('SPEC-T3.md requires the discount rules to live in a new lib/discount.js, which does not exist');
  }

  const tmp = mkTmp();
  try {
    const b = writeOrder(tmp, 'order-b.json', ORD_B);
    const c = writeOrder(tmp, 'order-c.json', ORD_C);
    const d = writeOrder(tmp, 'order-d.json', ORD_BOGUS);

    const rb = runCli(CAND, [b]);
    if (rb.code !== 0) return reject('worked example 1 (SAVE10) exited ' + rb.code + ': ' + rb.stderr.trim());
    if (rb.stdout !== EXPECT_B) return reject('worked example 1 (SAVE10) output differs from SPEC-T3.md. got:\n' + rb.stdout);

    const rc = runCli(CAND, [c]);
    if (rc.code !== 0) return reject('worked example 2 (FREESHIP) exited ' + rc.code + ': ' + rc.stderr.trim());
    if (rc.stdout !== EXPECT_C) return reject('worked example 2 (FREESHIP) output differs from SPEC-T3.md. got:\n' + rc.stdout);

    const ra = runCli(CAND, [path.join(CAND, 'test', 'fixtures', 'order-a.json')]);
    if (ra.code !== 0 || ra.stdout !== EXPECT_A) {
      return reject('an order WITHOUT discountCode no longer produces byte-identical output (spec: unchanged behaviour)');
    }

    const rd = runCli(CAND, [d]);
    if (rd.code !== 2) return reject('unknown discount code exited ' + rd.code + ', spec requires exit status 2');
    if (rd.stdout !== '') return reject('unknown discount code printed to stdout; spec requires nothing on stdout');
    if (rd.stderr.trim() !== UNKNOWN_CODE_LINE) {
      return reject('unknown discount code stderr is ' + JSON.stringify(rd.stderr.trim()) + ', spec requires ' + JSON.stringify(UNKNOWN_CODE_LINE));
    }
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }

  const suite = runSuite(CAND);
  if (suite.passed === null) return reject('test command produced no TOTAL line');
  if (suite.failed !== 0) return reject('candidate suite is not green: ' + suite.failed + ' failed');
  // Stated proxy (see testFilesMention): the spec says "add tests covering the
  // worked examples and the error case".
  if (!testFilesMention(CAND, 'SAVE10')) {
    return reject('no test file mentions SAVE10 — spec requires tests covering the worked examples (stated proxy check)');
  }
  return accept('both worked examples exact, error case exact, no-discount output unchanged, suite green at ' + suite.passed + ' passed');
}

// ============================================================ T4 ============
// "Make the whole suite green without weakening or deleting the new test."
// The injected file is regenerated from inject-t4.sh into a scratch tree and
// BYTE-COMPARED against the candidate's copy — "unmodified" is checked against
// the injector's own output, not against a copy that could drift. Then the
// full suite (which discovers the file automatically) must be green.
function checkT4() {
  const candFile = path.join(CAND, 'test', 'regression-t4.js');
  if (!fs.existsSync(candFile)) return reject('test/regression-t4.js is missing from the candidate tree');

  const inject = path.join(__dirname, 'inject-t4.sh');
  if (!fs.existsSync(inject)) {
    console.error('harness error: inject-t4.sh not found beside oracle-exp2.js');
    process.exit(2);
  }
  const tmp = mkTmp();
  let expected;
  try {
    fs.mkdirSync(path.join(tmp, 'test'));
    execFileSync('bash', [inject, tmp], { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'], timeout: 60000 });
    expected = fs.readFileSync(path.join(tmp, 'test', 'regression-t4.js'));
  } catch (e) {
    console.error('harness error: could not regenerate the injected test: ' + e.message);
    process.exit(2);
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }
  if (!fs.readFileSync(candFile).equals(expected)) {
    return reject('test/regression-t4.js differs byte-for-byte from what inject-t4.sh injects — the test was modified');
  }

  const suite = runSuite(CAND);
  if (suite.passed === null) return reject('test command produced no TOTAL line');
  if (!suite.out.includes('== regression-t4.js ==')) {
    return reject('the runner did not discover test/regression-t4.js (was discovery weakened?)');
  }
  if (suite.failed !== 0) return reject('suite is not green: ' + suite.failed + ' failed');
  return accept('regression test byte-identical to the injected original, discovered, and the suite is green at ' + suite.passed + ' passed');
}

// ============================================================ T5 ============
// FOLLOWUP-T5.md: --summary must reuse the established discount module and
// rounding policy. Checked by EXECUTION on a fixture set the follow-up text
// does not enumerate (ORD-E exercises the T4 cap), so consistency with the
// T2–T4 decisions is what is measured, not memorisation of the example:
//   26.65 + 43.87 + 807.00 -> net 877.52.
function checkT5() {
  const tmp = mkTmp();
  try {
    const b = writeOrder(tmp, 'order-b.json', ORD_B);
    const c = writeOrder(tmp, 'order-c.json', ORD_C);
    const e = writeOrder(tmp, 'order-e.json', ORD_E);
    const f = writeOrder(tmp, 'order-f.json', ORD_BOGUS);

    const rs = runCli(CAND, ['--summary', b, c, e]);
    if (rs.code !== 0) return reject('--summary exited ' + rs.code + ': ' + rs.stderr.trim());
    const expected = [
      'SUMMARY ORD-B total=26.65',
      'SUMMARY ORD-C total=43.87',
      'SUMMARY ORD-E total=807.00',
      'SUMMARY TOTAL orders=3 net=877.52',
      '',
    ].join('\n');
    if (rs.stdout !== expected) {
      return reject('--summary output differs from the oracle-computed expectation (discount/rounding consistency). got:\n' + rs.stdout);
    }

    const rf = runCli(CAND, ['--summary', f]);
    if (rf.code !== 2) return reject('--summary with an unknown discount code exited ' + rf.code + ', expected 2');
    if (rf.stderr.trim() !== UNKNOWN_CODE_LINE) {
      return reject('--summary unknown-code stderr is ' + JSON.stringify(rf.stderr.trim()) + ', expected ' + JSON.stringify(UNKNOWN_CODE_LINE));
    }
  } finally {
    fs.rmSync(tmp, { recursive: true, force: true });
  }

  const suite = runSuite(CAND);
  if (suite.passed === null) return reject('test command produced no TOTAL line');
  if (suite.failed !== 0) return reject('candidate suite is not green: ' + suite.failed + ' failed');
  // Stated proxy: the follow-up requires tests for the new flag.
  if (!testFilesMention(CAND, '--summary')) {
    return reject('no test file mentions --summary — FOLLOWUP-T5.md requires tests for the flag (stated proxy check)');
  }
  return accept('summary totals and net match the oracle computation (cap order included), error path exact, suite green at ' + suite.passed + ' passed');
}

const checks = { T1: checkT1, T2: checkT2, T3: checkT3, T4: checkT4, T5: checkT5 };
if (!checks[task]) {
  console.error('unknown task: ' + task);
  process.exit(2);
}
checks[task]();
