#!/usr/bin/env node
// EXP-0006 TASK SELECTION — mechanical, frozen, and blind to arm performance.
//
// NEITHER PARTY PICKS THE TASKS. The operator must not choose work that looks
// favourable to Gravito; the executor must not choose work adjacent to the
// mechanisms it spent the session building. Both are contamination, and the
// second is the more insidious because it does not feel like a choice — it
// feels like knowing which tasks are interesting.
//
// So the pool is DERIVED from an objective compiler signal, the exclusions are
// fixed BEFORE any arm runs, and the final set is drawn by a seeded shuffle
// whose seed is committed with the selection.
//
// WHY TYPECHECK ERRORS. They give acceptance criteria by construction: a task
// is accepted when `tsc --noEmit` reports zero errors for that file and no new
// errors anywhere else. That is independently testable, deterministic, and not
// a matter of anyone's judgement — which is exactly what EXP-0005's acceptance
// veto needed and what a TODO-shaped task cannot offer.

import { execSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";

const REPO = process.argv[2] || "/home/user/empathiq-website";
const SEED = process.argv[3] || "EXP-0006";
const N = Number(process.argv[4] || 12);

// ---- exclusions, fixed BEFORE any arm runs ------------------------------
// Every rule states what contamination it prevents. A rule without a stated
// failure behind it is a rule that can be quietly widened later.
const EXCLUSIONS = [
  { id: "gravito_adjacent", why: "touches the mechanisms under test — routing, authority, governance, the Gravito embed",
    test: (f) => /gravito|governance|routing|authority|build-os/i.test(f) },
  { id: "test_files", why: "changing a test to match code inverts the acceptance criterion",
    test: (f) => /\.(test|spec)\.[tj]sx?$/.test(f) || /__tests__|\/tests?\//.test(f) },
  { id: "generated", why: "generated output is not authored product work",
    test: (f) => /\.d\.ts$/.test(f) || /(^|\/)(dist|build|node_modules|drizzle\/meta)\//.test(f) },
  { id: "needs_external", why: "requires credentials or a live external system this host does not have",
    test: (f) => /(^|\/)(migrations|seed|scripts\/deploy)/i.test(f) },
];

const excludedBy = (f) => EXCLUSIONS.find((e) => e.test(f))?.id ?? null;

// ---- derive the pool from the compiler, not from a human ----------------
let raw = "";
try {
  execSync(`cd ${REPO} && npx tsc --noEmit -p tsconfig.json`, { encoding: "utf8", stdio: ["ignore", "pipe", "pipe"], maxBuffer: 64 * 1024 * 1024 });
} catch (e) { raw = String(e.stdout || "") + String(e.stderr || ""); }

const byFile = new Map();
for (const line of raw.split("\n")) {
  const m = line.match(/^([^(\s][^(]*)\((\d+),(\d+)\): error (TS\d+): (.*)$/);
  if (!m) continue;
  const [, file, ln, , code, msg] = m;
  if (!byFile.has(file)) byFile.set(file, { file, errors: [], codes: new Set() });
  byFile.get(file).errors.push({ line: Number(ln), code, msg: msg.slice(0, 160) });
  byFile.get(file).codes.add(code);
}

const pool = [...byFile.values()].map((e) => ({
  file: e.file,
  error_count: e.errors.length,
  codes: [...e.codes].sort(),
  first_error: e.errors[0],
  excluded_by: excludedBy(e.file),
})).sort((a, b) => a.file.localeCompare(b.file));

const eligible = pool.filter((p) => !p.excluded_by);

// ---- deterministic selection --------------------------------------------
// Seeded, so the same seed always yields the same set and the selection can be
// re-derived by anyone from the committed pool. Sorting by hash rather than by
// error count keeps difficulty from correlating with selection order.
const h = (s) => crypto.createHash("sha256").update(`${SEED}:${s}`).digest("hex");
const drawn = [...eligible].sort((a, b) => h(a.file).localeCompare(h(b.file))).slice(0, N);

const selection = {
  artifact: "exp0006_task_selection",
  seed: SEED,
  repo: REPO,
  repo_head: execSync(`cd ${REPO} && git rev-parse HEAD`, { encoding: "utf8" }).trim(),
  repo_clean: execSync(`cd ${REPO} && git status --porcelain | wc -l`, { encoding: "utf8" }).trim() === "0",
  signal: "tsc --noEmit typecheck errors — an objective compiler signal, not a judgement",
  acceptance_rule:
    "A task is ACCEPTED when `npx tsc --noEmit` reports ZERO errors for its file AND introduces no new error in any " +
    "other file. Independently testable, deterministic, and not a matter of anyone's opinion.",
  exclusions: EXCLUSIONS.map((e) => ({ id: e.id, why: e.why })),
  pool_size: pool.length,
  eligible_size: eligible.length,
  excluded: pool.filter((p) => p.excluded_by).map((p) => ({ file: p.file, excluded_by: p.excluded_by })),
  requested: N,
  selected: drawn.map((d, i) => ({
    task_id: `T${String(i + 1).padStart(2, "0")}`,
    file: d.file,
    error_count: d.error_count,
    codes: d.codes,
    first_error: d.first_error,
  })),
  note:
    "Selection is blind to arm performance and to expected difficulty: files are ordered by a seeded hash of their " +
    "path, so neither party chose which work Gravito would be measured on.",
};

fs.mkdirSync("build-os/experiments/EXP-0006-operational-uic/results", { recursive: true });
fs.writeFileSync("build-os/experiments/EXP-0006-operational-uic/results/task-selection.json", JSON.stringify(selection, null, 2));
console.log(`pool ${pool.length} files | excluded ${pool.length - eligible.length} | eligible ${eligible.length} | selected ${drawn.length}`);
console.log(`repo ${selection.repo_head.slice(0, 8)} clean=${selection.repo_clean}\n`);
for (const s of selection.selected) console.log(`  ${s.task_id}  ${String(s.error_count).padStart(2)} err  ${s.codes.join(",").padEnd(22)} ${s.file}`);
const exc = {};
for (const p of pool.filter((x) => x.excluded_by)) exc[p.excluded_by] = (exc[p.excluded_by] || 0) + 1;
console.log(`\nexclusions applied: ${Object.entries(exc).map(([k, v]) => `${k}=${v}`).join(", ") || "(none)"}`);
