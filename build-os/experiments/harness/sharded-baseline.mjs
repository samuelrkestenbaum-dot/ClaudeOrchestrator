#!/usr/bin/env node
// Sharded full-suite baseline runner.
//
// WHY THIS EXISTS. The registered plan was one whole-suite vitest run serving
// two purposes at once — the behavioural/failing-test candidate pool and the
// frozen pre-existing regression baseline. That run STALLED: zero test files
// completed, no JSON written, 900 s of silence (see ATTEMPT-1-STALLED.md). A
// bounded probe proved vitest, the toolchain and the repository all work; what
// does not work is invoking every file in one process.
//
// This runner is still ONE PASS over the suite. It is not a second run of a
// thing that already produced numbers — attempt 1 produced none. It changes the
// INVOCATION, not the scope, the seed, or the definition of the baseline.
//
// WHAT IT REFUSES TO DO:
//   * it never writes to the repository under test — the tree is checked for
//     cleanliness before and after, and a dirty tree at the end is a failed run
//     rather than a footnote;
//   * a chunk that hangs is BISECTED down to the individual file and recorded
//     as `hung`, never silently dropped and never counted as a pass;
//   * a file that is never reached is `not_run`, which is distinct from a file
//     that ran and passed. An unknown is not a zero.
//
// Chunks run STRICTLY SERIALLY. The whole-suite failure is consistent with
// contention between concurrent bootstraps, so introducing concurrency here
// would risk measuring the harness instead of the repository.

import { execFileSync, spawn } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const args = process.argv.slice(2);
const opt = (name, dflt) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : dflt;
};

const REPO = path.resolve(opt("repo", "/home/user/empathiq-website"));
const OUT = path.resolve(opt("out", path.join(REPO, "..", "sharded-baseline")));
const CHUNK = Number(opt("chunk", "10"));
const TIMEOUT_MS = Number(opt("timeout", "300")) * 1000;
const SINGLE_TIMEOUT_MS = Number(opt("single-timeout", "180")) * 1000;

const CHUNKS_DIR = path.join(OUT, "chunks");
fs.mkdirSync(CHUNKS_DIR, { recursive: true });

const git = (...a) => execFileSync("git", a, { cwd: REPO, encoding: "utf8" }).trim();
const log = (m) => {
  const line = `[${new Date().toISOString()}] ${m}`;
  console.log(line);
  fs.appendFileSync(path.join(OUT, "run.log"), line + "\n");
};

// --- preconditions ----------------------------------------------------------
const seedHead = git("rev-parse", "HEAD");
const dirtyBefore = git("status", "--porcelain");
if (dirtyBefore) {
  console.error("REFUSED: repository under test is not clean before the run:\n" + dirtyBefore);
  process.exit(2);
}

// --- file discovery ---------------------------------------------------------
// Mirrors vitest.config.ts's project globs. Discovery is a plain sorted walk so
// the file list is deterministic and independent of vitest's own collection —
// the stage that hung.
const EXCLUDE = [/(^|\/)node_modules(\/|$)/, /(^|\/)dist(\/|$)/, /(^|\/)server\/_dead_code(\/|$)/, /client\/src\/pages\/_archive\//];
const INCLUDE_ROOTS = ["client/src", "server", "shared"];
const TEST_RE = /\.(test|spec)\.(ts|tsx|mts)$/;

function walk(dir, acc = []) {
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return acc; }
  for (const e of entries.sort((a, b) => (a.name < b.name ? -1 : 1))) {
    const full = path.join(dir, e.name);
    const rel = path.relative(REPO, full);
    if (EXCLUDE.some((re) => re.test(rel))) continue;
    if (e.isDirectory()) walk(full, acc);
    else if (TEST_RE.test(e.name)) acc.push(rel);
  }
  return acc;
}

const files = INCLUDE_ROOTS.flatMap((r) => walk(path.join(REPO, r))).sort();
log(`seed=${seedHead} discovered=${files.length} chunk=${CHUNK} timeout=${TIMEOUT_MS / 1000}s`);

// --- chunk execution --------------------------------------------------------
function runChunk(list, id) {
  return new Promise((resolve) => {
    const jsonPath = path.join(CHUNKS_DIR, `${id}.json`);
    const limit = list.length === 1 ? SINGLE_TIMEOUT_MS : TIMEOUT_MS;
    const started = Date.now();
    const child = spawn(
      "npx",
      ["vitest", "run", "--reporter=json", `--outputFile=${jsonPath}`, ...list],
      { cwd: REPO, env: { ...process.env, CI: "1" }, stdio: ["ignore", "pipe", "pipe"] }
    );

    let out = "";
    const cap = (b) => { if (out.length < 200_000) out += b.toString(); };
    child.stdout.on("data", cap);
    child.stderr.on("data", cap);

    const timer = setTimeout(() => {
      try { process.kill(child.pid, "SIGKILL"); } catch { /* already gone */ }
    }, limit);

    child.on("close", (code, signal) => {
      clearTimeout(timer);
      const elapsed_s = (Date.now() - started) / 1000;
      const killed = signal === "SIGKILL";
      let report = null;
      try { report = JSON.parse(fs.readFileSync(jsonPath, "utf8")); } catch { /* none written */ }
      if (killed && !report) {
        fs.writeFileSync(path.join(CHUNKS_DIR, `${id}.stdout.txt`), out);
        return resolve({ status: "timeout", elapsed_s, files: list });
      }
      if (!report) {
        fs.writeFileSync(path.join(CHUNKS_DIR, `${id}.stdout.txt`), out);
        return resolve({ status: "no_report", elapsed_s, files: list, exit_code: code });
      }
      resolve({ status: "ok", elapsed_s, files: list, report });
    });
  });
}

// --- aggregation ------------------------------------------------------------
const perFile = new Map(); // rel -> { status, tests: [{name, status}] , elapsed_s }
const hung = [];
const noReport = [];

function absorb(report, list, elapsed_s) {
  const seen = new Set();
  for (const suite of report.testResults || []) {
    const rel = path.relative(REPO, suite.name);
    seen.add(rel);
    const tests = (suite.assertionResults || []).map((a) => ({
      full_name: a.fullName,
      status: a.status,
      failure: (a.failureMessages || [])[0] ? String((a.failureMessages || [])[0]).split("\n")[0] : null,
    }));
    // A suite that fails to COLLECT reports zero assertions with status failed.
    const status =
      suite.status === "failed" && tests.length === 0 ? "suite_error"
      : tests.some((t) => t.status === "failed") ? "failed"
      : "passed";
    perFile.set(rel, { status, tests, message: suite.message ? String(suite.message).split("\n")[0] : null });
  }
  for (const f of list) if (!seen.has(f)) perFile.set(f, { status: "not_reported", tests: [] });
}

// --- the queue, with timeout bisection --------------------------------------
const queue = [];
for (let i = 0; i < files.length; i += CHUNK) queue.push(files.slice(i, i + CHUNK));

let n = 0;
const t0 = Date.now();
while (queue.length) {
  const list = queue.shift();
  const id = `c${String(++n).padStart(4, "0")}-${list.length}`;
  const r = await runChunk(list, id);

  if (r.status === "ok") {
    absorb(r.report, list, r.elapsed_s);
    const failed = list.filter((f) => ["failed", "suite_error"].includes(perFile.get(f)?.status)).length;
    log(`${id} ok ${list.length}f ${r.elapsed_s.toFixed(1)}s failed=${failed} remaining_chunks=${queue.length}`);
  } else if (r.status === "timeout" && list.length > 1) {
    const mid = Math.ceil(list.length / 2);
    queue.unshift(list.slice(0, mid), list.slice(mid));
    log(`${id} TIMEOUT after ${r.elapsed_s.toFixed(1)}s — bisecting ${list.length} -> ${mid}+${list.length - mid}`);
  } else if (r.status === "timeout") {
    hung.push(list[0]);
    perFile.set(list[0], { status: "hung", tests: [], message: `no completion within ${SINGLE_TIMEOUT_MS / 1000}s when run alone` });
    log(`${id} HUNG (isolated): ${list[0]}`);
  } else {
    // no_report: the process exited without writing JSON. Bisect too — the
    // cause may be one file crashing the runner, and that file must be named.
    if (list.length > 1) {
      const mid = Math.ceil(list.length / 2);
      queue.unshift(list.slice(0, mid), list.slice(mid));
      log(`${id} NO_REPORT exit=${r.exit_code} — bisecting ${list.length}`);
    } else {
      noReport.push(list[0]);
      perFile.set(list[0], { status: "runner_crash", tests: [], message: `runner exited ${r.exit_code} without a report` });
      log(`${id} RUNNER_CRASH (isolated): ${list[0]}`);
    }
  }
}

// --- postconditions ---------------------------------------------------------
const dirtyAfter = git("status", "--porcelain");
const headAfter = git("rev-parse", "HEAD");

const counts = { passed: 0, failed: 0, suite_error: 0, hung: 0, runner_crash: 0, not_reported: 0, not_run: 0 };
for (const f of files) {
  const rec = perFile.get(f);
  if (!rec) { counts.not_run++; perFile.set(f, { status: "not_run", tests: [] }); continue; }
  counts[rec.status] = (counts[rec.status] || 0) + 1;
}
let testsPassed = 0, testsFailed = 0, testsSkipped = 0;
for (const rec of perFile.values())
  for (const t of rec.tests) {
    if (t.status === "passed") testsPassed++;
    else if (t.status === "failed") testsFailed++;
    else testsSkipped++;
  }

const baseline = {
  artifact: "exp0005_pre_existing_regression_baseline",
  method: "sharded — the registered single whole-suite invocation stalled with zero tests run; see ATTEMPT-1-STALLED.md",
  repo: REPO,
  seed: seedHead,
  seed_unchanged: headAfter === seedHead,
  tree_clean_before: dirtyBefore === "",
  tree_clean_after: dirtyAfter === "",
  chunk_size: CHUNK,
  chunk_timeout_s: TIMEOUT_MS / 1000,
  isolated_timeout_s: SINGLE_TIMEOUT_MS / 1000,
  discovered_files: files.length,
  wall_clock_s: (Date.now() - t0) / 1000,
  file_counts: counts,
  test_counts: { passed: testsPassed, failed: testsFailed, skipped_or_other: testsSkipped },
  hung_files: hung,
  runner_crash_files: noReport,
  failing_tests: [...perFile.entries()]
    .filter(([, r]) => r.status === "failed" || r.status === "suite_error")
    .map(([file, r]) => ({
      file,
      status: r.status,
      message: r.message,
      tests: r.tests.filter((t) => t.status === "failed").map((t) => ({ full_name: t.full_name, failure: t.failure })),
    })),
  per_file: Object.fromEntries([...perFile.entries()].map(([f, r]) => [f, { status: r.status, tests: r.tests.length }])),
  honesty_note:
    "`hung`, `runner_crash`, `not_reported` and `not_run` are NOT passes and NOT failures. They are files this " +
    "baseline could not measure, and a later run that measures them is not thereby a regression.",
};

fs.writeFileSync(path.join(OUT, "BASELINE.json"), JSON.stringify(baseline, null, 2));
log(`DONE files=${files.length} ${JSON.stringify(counts)} tests_passed=${testsPassed} tests_failed=${testsFailed} wall=${(baseline.wall_clock_s / 60).toFixed(1)}min`);
if (dirtyAfter) { log(`FAILED POSTCONDITION: tree dirty after run:\n${dirtyAfter}`); process.exit(3); }
