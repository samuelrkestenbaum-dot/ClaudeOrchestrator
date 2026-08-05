'use strict';

// Build OS — hidden acceptance oracles for the fixed task corpus (v1.0.0).
//
// WHY THESE ARE HIDDEN. An acceptance criterion that lives inside the repo under
// test is a criterion the model can read, satisfy literally, and optimise
// against. These oracles are never copied into the seeded tree and never named
// in a task prompt. They are applied from outside, to a COPY of the candidate
// tree, after the run.
//
// WHY THEY ARE MECHANICAL. COMPARISON_PROTOCOL.md's constant #5 requires the
// acceptance criterion to be defined per task BEFORE any run and applied by the
// same checker to both arms. A criterion decided after seeing output is worth
// nothing. Everything below is decidable by executing code — no judgement call,
// no prose grading, no model self-report.
//
// Usage: node oracle.js <T1|T2|T3|T4> <candidate-dir> <pristine-seed-dir>
// Exit:  0 accepted, 1 not accepted, 2 harness error.
// Prints one line: "ACCEPT <task>" or "REJECT <task> — <reason>".

const fs = require('fs');
const path = require('path');
const os = require('os');
const { execFileSync } = require('child_process');

const [, , task, candidateArg, seedArg] = process.argv;
if (!task || !candidateArg || !seedArg) {
  console.error('usage: node oracle.js <T1|T2|T3|T4> <candidate-dir> <seed-dir>');
  process.exit(2);
}
const CAND = path.resolve(candidateArg);
const SEED = path.resolve(seedArg);

// The pass/fail totals of the pristine seeded suite. T1's "Done when" requires
// the project's own test command to still report the SAME pass count, so this
// number is part of the criterion, not decoration.
const SEED_TOTAL_PASSED = 14;
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
  const dst = fs.mkdtempSync(path.join(os.tmpdir(), 'oracle-'));
  fs.cpSync(src, dst, { recursive: true });
  return dst;
}

// Run the project's own test command and parse its machine-readable last line.
// Returns { passed, failed, exitCode, out }.
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

// Evaluate an expression against the candidate's module surface, in a child
// process, so a candidate that throws on load cannot take the oracle with it.
function evalIn(dir, expr) {
  try {
    const out = execFileSync('node', ['-e', expr], {
      cwd: dir,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
      timeout: 60000,
    });
    return { ok: true, out: out.trim() };
  } catch (e) {
    return { ok: false, out: ((e.stdout || '') + (e.stderr || '')).trim() };
  }
}

function near(a, b) {
  return typeof a === 'number' && Math.abs(a - b) < 1e-9;
}

// Ask the candidate for a JSON blob of results. Returns parsed JSON or null.
function probe(dir, body) {
  const r = evalIn(dir, body);
  if (!r.ok) return null;
  const line = r.out.split('\n').filter(Boolean).pop();
  try {
    return JSON.parse(line);
  } catch (e) {
    return null;
  }
}

// ARM-SURFACE PATHS ARE NOT TASK OUTPUT. Arm B installs the Build OS surface
// (.claude/, build-os/, CLAUDE.md) into the repo before the run. Counting those
// as "files the task touched" would inflate T3's file count and would make every
// arm-B T4 run look like it breached its ownership manifest. They are excluded
// here so the same oracle applies unchanged to both arms — which is what
// COMPARISON_PROTOCOL.md constant #5 ("applied by the same checker to both
// arms") requires.
const ARM_SURFACE = /^(\.claude(\/|$)|build-os(\/|$)|CLAUDE\.md$|\.mcp\.json$)/;

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

// ============================================================ T1 ============
// Corpus: "the comment is correct and the project's own test command still
// reports the same pass count it did before."
//
// STATED LIMIT OF THIS ORACLE: it verifies the FALSE CLAIM IS GONE, that a
// comment still documents the function, and that behaviour and pass count are
// unchanged. It does not grade prose. "Correct" is operationalised as "the
// specific factual error this instance froze is no longer asserted", which is
// decidable; "well written" is not, and is not claimed.
function checkT1() {
  const p = path.join(CAND, 'src', 'temperature.js');
  if (!fs.existsSync(p)) return reject('src/temperature.js is missing');
  const src = fs.readFileSync(p, 'utf8');

  // The frozen false claim, in the forms that would still assert it.
  if (/toCelsius\(32\)\s*returns\s*100/i.test(src)) {
    return reject('the false claim "toCelsius(32) returns 100" is still asserted');
  }
  if (/\b100\b/.test(src.slice(0, src.indexOf('function toCelsius')))) {
    // A 100 may legitimately appear (e.g. "toCelsius(212) returns 100"), so this
    // is not itself fatal — only the specific false claim above is. Check that
    // any surviving mention is not the frozen error.
    const head = src.slice(0, src.indexOf('function toCelsius'));
    if (/32\D{0,20}100/.test(head.replace(/\s+/g, ' '))) {
      return reject('a 32->100 claim survives in the comment above toCelsius');
    }
  }
  if (!/\/\*\*[\s\S]*?\*\/\s*function toCelsius/.test(src)) {
    return reject('the block comment above toCelsius was deleted rather than corrected');
  }

  // Behaviour must be untouched: T1 is "no behaviour change".
  const r = probe(
    CAND,
    "const t=require('./src/temperature');console.log(JSON.stringify({a:t.toCelsius(32),b:t.toCelsius(212),c:t.toFahrenheit(0)}))"
  );
  if (!r) return reject('candidate temperature module failed to load');
  if (!near(r.a, 0) || !near(r.b, 100) || !near(r.c, 32)) {
    return reject('toCelsius/toFahrenheit behaviour changed: ' + JSON.stringify(r));
  }

  const suite = runSuite(CAND);
  if (suite.passed === null) return reject('test command produced no TOTAL line');
  if (suite.passed !== SEED_TOTAL_PASSED || suite.failed !== SEED_TOTAL_FAILED) {
    return reject(
      'pass count moved: seeded ' +
        SEED_TOTAL_PASSED +
        '/' +
        SEED_TOTAL_FAILED +
        ', candidate ' +
        suite.passed +
        '/' +
        suite.failed
    );
  }
  return accept('false claim removed, behaviour identical, suite still ' + suite.passed + ' passed');
}

// ============================================================ T2 ============
// Corpus: "the new test fails at the pre-fix tree and passes at the post-fix
// tree, and the full suite is green."
//
// The pre-fix differential is executed, not asserted: the candidate's TEST
// directory is transplanted onto the PRISTINE (still-buggy) source, and the
// suite must FAIL there. That is the only way to know the test would actually
// have caught the defect, and it cannot be satisfied by a test that merely
// asserts the buggy behaviour.
function checkT2() {
  // 1. The defect is actually fixed.
  const r = probe(
    CAND,
    "const s=require('./src/stats');console.log(JSON.stringify({even:s.median([1,2,3,4]),odd:s.median([3,1,2]),one:s.median([9]),even2:s.median([10,20])}))"
  );
  if (!r) return reject('candidate stats module failed to load');
  if (!near(r.even, 2.5)) return reject('median([1,2,3,4]) is ' + r.even + ', expected 2.5');
  if (!near(r.even2, 15)) return reject('median([10,20]) is ' + r.even2 + ', expected 15');
  if (!near(r.odd, 2)) return reject('median([3,1,2]) is ' + r.odd + ', expected 2 (regression)');
  if (!near(r.one, 9)) return reject('median([9]) is ' + r.one + ', expected 9 (regression)');

  // 2. The candidate's full suite is green.
  const suite = runSuite(CAND);
  if (suite.passed === null) return reject('test command produced no TOTAL line');
  if (suite.failed !== 0) return reject('candidate suite is not green: ' + suite.failed + ' failed');

  // 3. A test was actually added.
  if (suite.passed <= SEED_TOTAL_PASSED) {
    return reject(
      'no test was added: candidate suite reports ' + suite.passed + ' passed, seed reported ' + SEED_TOTAL_PASSED
    );
  }

  // 4. THE DIFFERENTIAL: candidate tests + pristine buggy source must FAIL.
  const tmp = copyTree(SEED); // pristine, still buggy
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
    'defect fixed, suite green at ' + suite.passed + ' passed, added test fails pre-fix (' + pre.failed + ' failed)'
  );
}

// ============================================================ T3 ============
// Corpus: a feature spanning at least three files. The behavioural criterion is
// SPEC-T3.md's own worked examples, which were frozen into the seeded tree
// before any run — so the criterion predates the output, as constant #5 requires.
function checkT3() {
  const r = probe(
    CAND,
    "const k=require('./src/index');const p=k.percentile;" +
      "const g=(f)=>{try{return f()}catch(e){return 'THREW'}};" +
      'console.log(JSON.stringify({' +
      "a:g(()=>p([1,2,3,4],50)),b:g(()=>p([1,2,3,4],0)),c:g(()=>p([1,2,3,4],100))," +
      "d:g(()=>p([1,2,3,4],25)),e:g(()=>p([10,20,30],50))," +
      "bad1:g(()=>p([],50)),bad2:g(()=>p([1,2],101)),bad3:g(()=>p([1,2],-1))" +
      '}))'
  );
  if (!r) return reject('percentile is not exported from src/index.js, or the module failed to load');
  const want = { a: 2.5, b: 1, c: 4, d: 1.75, e: 20 };
  for (const k of Object.keys(want)) {
    if (!near(r[k], want[k])) {
      return reject('worked example ' + k + ' gave ' + JSON.stringify(r[k]) + ', spec says ' + want[k]);
    }
  }
  for (const k of ['bad1', 'bad2', 'bad3']) {
    if (r[k] !== 'THREW') return reject('error case ' + k + ' did not throw, gave ' + JSON.stringify(r[k]));
  }

  const suite = runSuite(CAND);
  if (suite.passed === null) return reject('test command produced no TOTAL line');
  if (suite.failed !== 0) return reject('candidate suite is not green: ' + suite.failed + ' failed');
  if (suite.passed <= SEED_TOTAL_PASSED) return reject('no tests were added for the feature');

  const changed = changedFiles(CAND, SEED).filter((f) => f !== 'SPEC-T3.md');
  if (changed.length < 3) {
    return reject('feature touched ' + changed.length + ' files, spec requires at least 3: ' + changed.join(', '));
  }
  return accept('all 5 worked examples + 3 error cases pass, ' + changed.length + ' files changed, suite green');
}

// ============================================================ T4 ============
// Corpus: three genuinely independent items with a disjoint file-ownership
// manifest. Both halves are checked: the behaviour of each item, AND that the
// manifest was respected (no item reached outside its declared writable set).
function checkT4() {
  const r = probe(
    CAND,
    "const c=require('./src/currency'),d=require('./src/distance'),u=require('./src/duration');" +
      "const g=(f)=>{try{return f()}catch(e){return 'THREW'}};" +
      'console.log(JSON.stringify({' +
      'a1:g(()=>c.toMinorUnits(12.34,2)),a2:g(()=>c.fromMinorUnits(1234,2)),a3:g(()=>c.toMinorUnits(5,0)),' +
      "a4:g(()=>c.toMinorUnits('x',2))," +
      'b1:g(()=>d.milesToKm(1)),b2:g(()=>d.kmToMiles(1.609344)),' +
      "b3:g(()=>d.milesToKm('x'))," +
      'c1:g(()=>u.toSeconds({hours:1,minutes:2,seconds:3})),c2:g(()=>u.toSeconds({minutes:1})),' +
      'c3:g(()=>u.formatDuration(3723)),c4:g(()=>u.formatDuration(0)),c5:g(()=>u.formatDuration(-1))' +
      '}))'
  );
  if (!r) return reject('one or more of src/currency.js, src/distance.js, src/duration.js is missing or failed to load');

  if (!near(r.a1, 1234)) return reject('toMinorUnits(12.34,2) gave ' + JSON.stringify(r.a1) + ', expected 1234');
  if (!near(r.a2, 12.34)) return reject('fromMinorUnits(1234,2) gave ' + JSON.stringify(r.a2) + ', expected 12.34');
  if (!near(r.a3, 5)) return reject('toMinorUnits(5,0) gave ' + JSON.stringify(r.a3) + ', expected 5');
  if (r.a4 !== 'THREW') return reject('toMinorUnits("x",2) did not throw');
  if (!near(r.b1, 1.609344)) return reject('milesToKm(1) gave ' + JSON.stringify(r.b1) + ', expected 1.609344');
  if (!near(r.b2, 1)) return reject('kmToMiles(1.609344) gave ' + JSON.stringify(r.b2) + ', expected 1');
  if (r.b3 !== 'THREW') return reject('milesToKm("x") did not throw');
  if (!near(r.c1, 3723)) return reject('toSeconds({1,2,3}) gave ' + JSON.stringify(r.c1) + ', expected 3723');
  if (!near(r.c2, 60)) return reject('toSeconds({minutes:1}) gave ' + JSON.stringify(r.c2) + ', expected 60');
  if (r.c3 !== '01:02:03') return reject('formatDuration(3723) gave ' + JSON.stringify(r.c3) + ', expected "01:02:03"');
  if (r.c4 !== '00:00:00') return reject('formatDuration(0) gave ' + JSON.stringify(r.c4) + ', expected "00:00:00"');
  if (r.c5 !== 'THREW') return reject('formatDuration(-1) did not throw');

  const suite = runSuite(CAND);
  if (suite.passed === null) return reject('test command produced no TOTAL line');
  if (suite.failed !== 0) return reject('candidate suite is not green: ' + suite.failed + ' failed');

  // Manifest discipline: TASKS-T4.md says no item writes index.js or README.md.
  const changed = changedFiles(CAND, SEED).filter((f) => f !== 'TASKS-T4.md');
  const owned = new Set([
    'src/currency.js',
    'test/currency.test.js',
    'src/distance.js',
    'test/distance.test.js',
    'src/duration.js',
    'test/duration.test.js',
  ]);
  const strays = changed.filter((f) => !owned.has(f));
  if (strays.length) {
    return reject('files outside the declared ownership manifest were written: ' + strays.join(', '));
  }
  const missing = [...owned].filter((f) => !fs.existsSync(path.join(CAND, f)));
  if (missing.length) return reject('manifest files never created: ' + missing.join(', '));

  return accept('all 3 items behave to spec, manifest respected (' + changed.length + ' files, 0 strays), suite green');
}

const checks = { T1: checkT1, T2: checkT2, T3: checkT3, T4: checkT4 };
if (!checks[task]) {
  console.error('unknown task: ' + task);
  process.exit(2);
}
checks[task]();
