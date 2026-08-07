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

// behavioural — from the baseline, the only source of observed failures
const baseline = JSON.parse(fs.readFileSync(BASELINE, "utf8"));
const behavioural = (baseline.failing_tests || []).flatMap((f) =>
  (f.tests.length ? f.tests : [{ full_name: `(suite error) ${f.message ?? ""}`, failure: f.message }])
    .map((t) => ({ shape: "behavioural", file: f.file, line: 0, text: t.full_name, detail: t.failure })));

// type/interface — from the tsc dump, grouped by code
const tscLines = fs.readFileSync(TSC_DUMP, "utf8").split("\n");
const typeDefects = tscLines.map((l) => {
  const m = l.match(/^(.+?)\((\d+),(\d+)\):\s*error\s+(TS\d+):\s*(.*)$/);
  return m ? { shape: "type_defect", file: m[1].replace(/^\.\//, ""), line: Number(m[2]), ts_code: m[4], text: m[5].slice(0, 200) } : null;
}).filter(Boolean);

const populations = {
  behavioural,
  type_defect: typeDefects,
  test_reliability: parseGrep(rg("\\b(it|test|describe)\\.(skip|todo)\\b"), "test_reliability"),
  suppression: parseGrep(rg("@ts-(ignore|expect-error|nocheck)"), "suppression"),
  implementation_gap: parseGrep(rg("\\b(TODO|FIXME|HACK)\\b"), "implementation_gap"),
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
