#!/usr/bin/env node
// Mechanical task selection for EXP-0005, implementing tasks/SELECTION-RULE.md.
//
// The rule was committed before any candidate was examined, precisely so that
// selection could be executed rather than judged. This script is that
// execution: given the enumerated populations it applies the deterministic
// sort, the shape quota, the admission tests and the leakage check, and emits
// EVERY candidate it considered with the reason it was admitted or excluded.
//
// IT REFUSES RATHER THAN SKIPS. Three inputs are mandatory — the baseline, the
// tsc dump, and EXP-0004's frozen cluster file sets. A missing input is a
// refusal, never a silently omitted check, because a hard exclusion that
// quietly does not run is worse than no hard exclusion at all: it reports
// "clean" without having looked.

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

const args = process.argv.slice(2);
const opt = (n, d) => { const i = args.indexOf(`--${n}`); return i >= 0 && args[i + 1] ? args[i + 1] : d; };

const REPO = path.resolve(opt("repo", "/home/user/empathiq-website"));
const BASELINE = opt("baseline", null);
const TSC_DUMP = opt("tsc", null);
const EXP0004 = opt("exp0004-clusters", null);
const OUT = path.resolve(opt("out", "."));
const QUOTA_PER_SHAPE = Number(opt("quota", "3"));
const QUOTA_PER_TS_CODE = Number(opt("ts-code-quota", "2"));

const refusals = [];
if (!BASELINE) refusals.push("--baseline <BASELINE.json> is required: the behavioural shape cannot be enumerated without it, and a task set missing that shape is narrower than the rule describes");
if (!TSC_DUMP) refusals.push("--tsc <file> is required: the type/interface shape is the largest population and cannot be estimated");
if (!EXP0004) refusals.push("--exp0004-clusters <json> is required: SELECTION-RULE.md hard-excludes E1-E5, and their file sets are NOT recoverable from any committed EXP-0004 artifact (TASK_FREEZE.md records cluster IDs only). Re-derive them from the eligibility procedure at the seed and pass them here.");
if (refusals.length) {
  console.error("REFUSED — a hard exclusion that does not run is not a check:\n" + refusals.map((r) => "  * " + r).join("\n"));
  process.exit(2);
}

// --- hard exclusions, no check required (SELECTION-RULE.md) -----------------
const GOVERNANCE = [/^build-os\//, /^\.claude\//, /^\.githooks\//, /^docs\/governance\//];
// Paths this session has diagnosed or discussed, which the rule excludes by
// name. Listed explicitly so the exclusion is auditable rather than remembered.
const SESSION_TOUCHED = [
  "server/__tests__/cors-public-read.test.ts",       // surfaced while piloting the sharded runner
  "server/_core/security.ts",                        // its failure mode was read in this session
  "server/governance/four-eyes-audit-kind.test.ts",  // the single-file stall probe
];

const exp0004 = JSON.parse(fs.readFileSync(EXP0004, "utf8"));
const EXP0004_FILES = new Set((exp0004.files || []).map((f) => f.replace(/^\.\//, "")));
if (EXP0004_FILES.size === 0) {
  console.error("REFUSED: --exp0004-clusters supplied but names zero files. An empty hard-exclusion set is indistinguishable from a skipped one.");
  process.exit(2);
}

// --- shape enumeration ------------------------------------------------------
const rg = (pattern, extra = []) => {
  try {
    return execFileSync("grep", ["-rnE", pattern, "--include=*.ts", "--include=*.tsx",
      "--exclude-dir=node_modules", "--exclude-dir=dist", "--exclude-dir=_dead_code", ...extra,
      "client", "server", "shared"], { cwd: REPO, encoding: "utf8", maxBuffer: 64 * 1024 * 1024 })
      .split("\n").filter(Boolean);
  } catch { return []; }  // grep exits 1 on no match
};

const parseGrep = (lines, shape) => lines.map((l) => {
  const m = l.match(/^([^:]+):(\d+):(.*)$/);
  return m ? { shape, file: m[1], line: Number(m[2]), text: m[3].trim().slice(0, 200) } : null;
}).filter(Boolean);

// behavioural — from the baseline, the only source of observed failures.
//
// STABLE failures only. The raw baseline is ONE observation; the determinism
// re-check found 10 unstable tests across 8 files. A flaky test cannot be an
// admissible task, because acceptance would not be objectively determinable —
// the task could "pass" without the work being done, or fail despite it.
// Quarantine is at FILE granularity because one file flipped in BOTH
// directions, which makes instability a property of the file's setup rather
// than of a single test.
const baseline = JSON.parse(fs.readFileSync(BASELINE, "utf8"));
const stablePath = path.join(path.dirname(BASELINE), "STABLE-FAILURES.json");
if (!fs.existsSync(stablePath)) {
  console.error(`REFUSED: ${stablePath} not found. Selecting behavioural tasks from a single unverified run would admit flaky tests, whose acceptance is not objectively determinable.`);
  process.exit(2);
}
const stable = JSON.parse(fs.readFileSync(stablePath, "utf8"));
const QUARANTINED = new Set(stable.quarantined_files || []);
const STABLE_KEYS = new Set((stable.stable || []).map((s) => `${s.file}::${s.test}`));

const behavioural = (baseline.failing_tests || []).flatMap((f) =>
  (f.tests.length ? f.tests : [{ full_name: `(suite error) ${f.message ?? ""}`, failure: f.message }])
    .map((t) => ({ shape: "behavioural", file: f.file, line: 0, text: t.full_name, detail: t.failure })))
  .filter((c) => !QUARANTINED.has(c.file))
  // A suite_error carries no test names; it is stable if it failed to collect
  // in both runs, which STABLE-FAILURES.json records separately.
  .filter((c) => STABLE_KEYS.has(`${c.file}::${c.text}`) || (stable.stable_suite_error_files || []).includes(c.file));

// type/interface — from the tsc dump, grouped by code
const tscLines = fs.readFileSync(TSC_DUMP, "utf8").split("\n");
const typeDefects = tscLines.map((l) => {
  const m = l.match(/^(.+?)\((\d+),(\d+)\):\s*error\s+(TS\d+):\s*(.*)$/);
  return m ? { shape: "type_defect", file: m[1].replace(/^\.\//, ""), line: Number(m[2]), ts_code: m[4], text: m[5].slice(0, 200) } : null;
}).filter(Boolean);

// --- false-positive filters ------------------------------------------------
// The naive greps match PROSE, not constructs. Observed on the first run: a
// comment reading "Now: converted to test.todo() since ..." was admitted as a
// skipped test; a doc line explaining `// @ts-nocheck` was admitted as an
// applied suppression; and "TODO" inside a string array and inside
// documentation were admitted as implementation gaps. Each would have produced
// a benchmark task with nothing to fix.
//
// This is also why `implementation_gap` enumerated 61 where SELECTION-RULE.md
// recorded 10: the query was too loose, not the population larger.

// A skip/todo must be a CALL in code, not a mention in a comment.
const isRealSkip = (t) =>
  /(^|[^\w.])(it|test|describe)\.(skip|todo)\s*[(<]/.test(t) && !/^\s*(\/\/|\*|\/\*)/.test(t);

// A suppression directive lives in a comment BY DEFINITION, so the test is
// whether the directive OPENS the comment (applied) rather than appearing
// inside prose about it (described).
const isRealSuppression = (t) => /^\s*(\/\/|\/\*+)\s*@ts-(ignore|expect-error|nocheck)\b/.test(t);

// A marker must OPEN its comment. "NULL, TODO" inside an array literal and
// "Placeholder Content -> TODO/stub responses" in a doc paragraph do not.
// An ACTIONABLE marker takes the conventional `TODO:` or `TODO(ID):` form — an
// instruction addressed to this code. A marker with no colon is almost always a
// CATEGORY DESCRIPTION: this repository's governance adapters carry headings
// like "// TODO/stub responses in API handlers" and "// TODO, FIXME, HACK, ...
// in production code", sitting directly above `pattern: /TODO|FIXME/i`. They
// describe what the scanner looks for elsewhere; there is nothing in them to fix.
const isRealMarker = (t) =>
  /^\s*(\/\/+|\/\*+|\*)\s*(TODO|FIXME|HACK)(\([^)]*\))?\s*:/.test(t) ||
  /\/\/\s*(TODO|FIXME|HACK)(\([^)]*\))?\s*:/.test(t);

// Cached file reads, for the two filters that need surrounding context.
const fileCache = new Map();
const linesOf = (rel) => {
  if (!fileCache.has(rel)) {
    try { fileCache.set(rel, fs.readFileSync(path.join(REPO, rel), "utf8").split("\n")); }
    catch { fileCache.set(rel, []); }
  }
  return fileCache.get(rel);
};

// A marker inside a `// ====` banner is a SECTION HEADING describing what the
// code below detects — not a gap in this file. Observed: three
// integrity-adapter files whose headings read "TODO/stub responses in API
// handlers" above a checkPlaceholderContent() that searches for exactly that.
// Fixing them would mean nothing, because there is nothing to fix.
const inBannerBlock = (c) => {
  const L = linesOf(c.file);
  const banner = /^\s*(\/\/|\*)\s*[=\-_*#]{5,}\s*$/;
  for (const d of [-2, -1, 1, 2]) {
    const l = L[c.line - 1 + d];
    if (l !== undefined && banner.test(l)) return true;
  }
  return false;
};

// A test FILE that reads a secret out of the environment is environment-bound
// in every test it contains, not only the ones whose names say so. Observed:
// "should have a valid RSA private key format" reads
// process.env.GITHUB_APP_PRIVATE_KEY but names no variable, so a name-based
// filter misses it. File granularity is the honest unit here.
const SECRET_ENV = /process\.env\.[A-Z0-9_]*(KEY|SECRET|TOKEN|PASSWORD|CREDENTIAL|DSN|WEBHOOK)[A-Z0-9_]*/;
const readsSecretEnv = (rel) => SECRET_ENV.test(linesOf(rel).join("\n"));

const populations = {
  behavioural,
  type_defect: typeDefects,
  test_reliability: parseGrep(rg("\\b(it|test|describe)\\.(skip|todo)\\b"), "test_reliability").filter((c) => isRealSkip(c.text)),
  suppression: parseGrep(rg("@ts-(ignore|expect-error|nocheck)"), "suppression").filter((c) => isRealSuppression(c.text)),
  implementation_gap: parseGrep(rg("\\b(TODO|FIXME|HACK)\\b"), "implementation_gap").filter((c) => isRealMarker(c.text)),
};

// --- leakage check against the pinned durable state -------------------------
// Deliberately biased toward exclusion, per the rule: over-excluding costs one
// candidate from a large pool; under-excluding admits a task that measures
// RECALL rather than capability, in the direction that flatters the arm with
// memory.
const memoryCorpus = [];
for (const dir of ["build-os/receipts", "build-os/memory", "build-os/packets"]) {
  const abs = path.join(REPO, dir);
  if (!fs.existsSync(abs)) continue;
  for (const f of fs.readdirSync(abs)) {
    const p = path.join(abs, f);
    if (!fs.statSync(p).isFile()) continue;
    memoryCorpus.push({ ref: `${dir}/${f}`, text: fs.readFileSync(p, "utf8") });
  }
}

function leakageHits(candidate) {
  const base = path.basename(candidate.file);
  const stem = base.replace(/\.(test|spec)?\.?tsx?$/, "");
  const hits = [];
  for (const doc of memoryCorpus) {
    if (doc.text.includes(candidate.file) || doc.text.includes(base) || (stem.length > 6 && doc.text.includes(stem)))
      hits.push(doc.ref);
    if (hits.length >= 4) break;
  }
  return hits;
}

// --- admission --------------------------------------------------------------
function admit(c, selectedSoFar) {
  const rel = c.file.replace(/^\.\//, "");
  if (GOVERNANCE.some((re) => re.test(rel)))
    return { ok: false, reason: "hard exclusion: governance/substrate path — this is the system under test, not work for it" };
  if (EXP0004_FILES.has(rel))
    return { ok: false, reason: "hard exclusion: file belongs to EXP-0004's frozen E1-E5 set" };
  if (SESSION_TOUCHED.includes(rel))
    return { ok: false, reason: "hard exclusion: diagnosed or discussed in this session" };

  // Independent — solving it must not mechanically solve another selected task.
  // Same file is the coarse form; same file AND same TS code is certainly
  // dependent. The rule's example (two errors in one function) is stricter than
  // anything derivable from a line number alone, so this errs toward exclusion.
  if (selectedSoFar.some((s) => s.file === rel))
    return { ok: false, reason: `not independent: ${rel} already carries selected task ${selectedSoFar.find((s) => s.file === rel).task_id}` };

  // Environment- and credential-dependent tests are not code tasks. Observed:
  // "should have GITHUB_APP_ID configured" and "GITHUB_APP_PRIVATE_KEY
  // configured" both fail because a secret is absent, so the only "fix" is
  // supplying a credential — which the standing constraint forbids, and which
  // measures the environment rather than the system under test.
  if (c.shape === "behavioural" &&
      (/\b(env|process\.env|API[_ ]?KEY|SECRET|TOKEN|CREDENTIAL|PRIVATE[_ ]KEY|DATABASE_URL|configured)\b/i.test(`${c.text} ${c.detail ?? ""}`) || readsSecretEnv(rel)))
    return { ok: false, reason: "not a code task: the test file reads a secret from the environment, so the only remedy is supplying a credential — forbidden, and it would measure the environment rather than the system" };

  if (c.shape === "implementation_gap" && inBannerBlock(c))
    return { ok: false, reason: "not an implementation gap: the marker is a section heading inside a banner block, describing what the code below detects rather than work left undone" };

  const hits = leakageHits(c);
  if (hits.length)
    return { ok: false, reason: `leakage: durable state references this file (${hits.slice(0, 3).join(", ")}${hits.length > 3 ? ", …" : ""}) — excluded because the check is biased toward exclusion` };

  return { ok: true, reason: "admitted: pre-existing, independent of selected tasks, no durable-state reference, objectively verifiable" };
}

// --- selection --------------------------------------------------------------
const ledger = [];
const selected = [];
const tsCodeCount = new Map();

for (const [shape, pop] of Object.entries(populations)) {
  // Deterministic sort, chosen precisely because it is uninformative: any
  // ordering that reflects a property of the task is an ordering that could be
  // tuned toward a desired result.
  const sorted = [...pop].sort((a, b) => (a.file < b.file ? -1 : a.file > b.file ? 1 : a.line - b.line));
  let taken = 0;
  for (const c of sorted) {
    if (taken >= QUOTA_PER_SHAPE) { ledger.push({ ...c, admitted: false, reason: `shape quota reached (${QUOTA_PER_SHAPE})` }); continue; }
    if (c.ts_code && (tsCodeCount.get(c.ts_code) || 0) >= QUOTA_PER_TS_CODE) {
      ledger.push({ ...c, admitted: false, reason: `TS-code quota reached for ${c.ts_code} (${QUOTA_PER_TS_CODE}) — EXP-0004 was five variants of one pattern; this is the correction` });
      continue;
    }
    const v = admit(c, selected);
    if (!v.ok) { ledger.push({ ...c, admitted: false, reason: v.reason }); continue; }
    const task_id = `T${String(selected.length + 1).padStart(2, "0")}`;
    selected.push({ task_id, ...c, file: c.file.replace(/^\.\//, "") });
    ledger.push({ ...c, admitted: true, task_id, reason: v.reason });
    if (c.ts_code) tsCodeCount.set(c.ts_code, (tsCodeCount.get(c.ts_code) || 0) + 1);
    taken++;
  }
}

const out = {
  artifact: "exp0005_task_selection",
  rule: "tasks/SELECTION-RULE.md",
  seed: baseline.seed,
  baseline_artifact: BASELINE,
  populations: Object.fromEntries(Object.entries(populations).map(([k, v]) => [k, v.length])),
  quota_per_shape: QUOTA_PER_SHAPE,
  quota_per_ts_code: QUOTA_PER_TS_CODE,
  selected_count: selected.length,
  shape_mix: selected.reduce((a, s) => ({ ...a, [s.shape]: (a[s.shape] || 0) + 1 }), {}),
  ts_code_mix: Object.fromEntries(tsCodeCount),
  selected,
  excluded_count: ledger.filter((l) => !l.admitted).length,
  ledger,
  honesty_note:
    "Selection is mechanical, but the POPULATIONS are only as complete as their queries. A shape whose population " +
    "is zero here is a shape this enumeration could not see, NOT a shape the repository lacks.",
};

fs.mkdirSync(OUT, { recursive: true });
fs.writeFileSync(path.join(OUT, "SELECTION.json"), JSON.stringify(out, null, 2));
console.log(`populations: ${JSON.stringify(out.populations)}`);
console.log(`selected ${selected.length} across ${Object.keys(out.shape_mix).length} shapes: ${JSON.stringify(out.shape_mix)}`);
if (selected.length < 10) console.log(`WARNING: ${selected.length} tasks selected, below the registered minimum of 10. This is a shortfall to report, not a threshold to lower.`);
