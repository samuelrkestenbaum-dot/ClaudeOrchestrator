#!/usr/bin/env node
// Context compiler — the TASK COMPILER and CONTEXT BUDGETER (SEAM 1 -> SEAM 2).
//
//   compile --index <index.json> --task <task.json>
//           [--facts <facts.jsonl>] [--decisions <file>] [--budget <bytes>]
//           [--out <dir>] [--deterministic] [--artifact-threshold <bytes>]
//
// Reads a SEAM 1 repository index (produced by the indexer lane; this file
// depends on the SCHEMA, never on that lane's code) plus a task descriptor,
// and writes capsule.json + capsule.md per SEAM 2.
//
// Two properties are load-bearing and everything else serves them:
//
//   EXPLAINABILITY — no file, fact, decision or artifact enters the capsule
//   without the RULE that admitted it, recorded in provenance. "A capsule that
//   cannot say why something is in it is malformed" (SEAMS.md).
//
//   DETERMINISM — same index + same task => byte-identical capsule.json AND
//   capsule.md. Every collection is sorted; every object is serialized with
//   sorted keys; the only wall-clock field is compiled_at, which
//   --deterministic zeroes. A compiler whose output drifts cannot be cached,
//   cannot be diffed, and cannot be A/B tested.
//
// What this is NOT: it has no semantic understanding of the code. The walk is
// a heuristic over imports, tests and error clusters. It is stated as such in
// the capsule itself rather than implied to be more.
//
// Dependencies: node stdlib only.

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { IMMUTABLE_PREFIX, PREFIX_SHA256 } from "./capsule-prefix.mjs";
import { renderCapsule } from "./render-capsule.mjs";

// ---------------------------------------------------------------------------
// Priority ladder. This is FIXED, not learned. When the byte budget cannot
// hold every candidate, admission runs strictly down this ladder and stops at
// the first candidate that does not fit — everything from there down is
// dropped WITH DISCLOSURE. Stopping (rather than skipping ahead to whatever
// happens to fit) is deliberate: it keeps the guarantee that a surviving
// low-priority file never displaces a dropped high-priority one.
// ---------------------------------------------------------------------------
export const PRIORITY = [
  { n: 1, key: "defining", label: "defining files" },
  { n: 2, key: "tests", label: "tests" },
  { n: 3, key: "importers", label: "direct importers" },
  { n: 4, key: "neighborhood", label: "neighborhood" },
  { n: 5, key: "cluster", label: "cluster siblings" },
];
const PRIORITY_LABELS = PRIORITY.map((p) => `${p.n}. ${p.label}`);

const DEFAULT_ARTIFACT_THRESHOLD = 4096;
const EPOCH = "1970-01-01T00:00:00.000Z";

// ------------------------------------------------------------- utilities --
function die(msg) {
  process.stderr.write(`compile-task: ${msg}\n`);
  process.exit(2);
}

function readJSON(file, what) {
  let raw;
  try {
    raw = fs.readFileSync(file, "utf8");
  } catch {
    die(`cannot read ${what}: ${file}`);
  }
  try {
    return JSON.parse(raw);
  } catch (e) {
    die(`${what} is not valid JSON (${file}): ${e.message}`);
  }
}

// Deterministic serializer: object keys sorted, arrays kept in the order the
// caller sorted them. JSON.stringify's key order follows insertion order,
// which is stable in practice but not something to rely on across code paths.
function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === "object") {
    const out = {};
    for (const k of Object.keys(value).sort()) out[k] = stable(value[k]);
    return out;
  }
  return value;
}

const bytesOf = (s) => Buffer.byteLength(s, "utf8");
const sha256 = (buf) => crypto.createHash("sha256").update(buf).digest("hex");
const uniqSort = (xs) => [...new Set(xs.filter((x) => typeof x === "string" && x))].sort();

// One line, bounded. A "one-line summary" that carries a newline is not one.
function oneLine(s, max = 160) {
  const flat = String(s).replace(/\s+/g, " ").trim();
  return flat.length > max ? flat.slice(0, max - 1) + "…" : flat;
}

// --------------------------------------------------------------- arg parse --
function parseArgs(argv) {
  const a = argv.slice();
  if (a[0] === "compile") a.shift(); // the subcommand word is optional
  const opt = {
    index: null, task: null, facts: null, decisions: null,
    budget: null, out: ".", deterministic: false,
    artifactThreshold: DEFAULT_ARTIFACT_THRESHOLD,
  };
  for (let i = 0; i < a.length; i++) {
    const k = a[i];
    const next = () => {
      if (i + 1 >= a.length) die(`${k} needs a value`);
      return a[++i];
    };
    switch (k) {
      case "--index": opt.index = next(); break;
      case "--task": opt.task = next(); break;
      case "--facts": opt.facts = next(); break;
      case "--decisions": opt.decisions = next(); break;
      case "--budget": opt.budget = Number(next()); break;
      case "--out": opt.out = next(); break;
      case "--deterministic": opt.deterministic = true; break;
      case "--artifact-threshold": opt.artifactThreshold = Number(next()); break;
      case "-h": case "--help":
        process.stdout.write(USAGE); process.exit(0); break;
      default: die(`unknown option: ${k}`);
    }
  }
  if (!opt.index) die("--index is required");
  if (!opt.task) die("--task is required");
  if (opt.budget !== null && !Number.isFinite(opt.budget)) die("--budget must be a number of bytes");
  if (!Number.isFinite(opt.artifactThreshold) || opt.artifactThreshold < 0)
    die("--artifact-threshold must be a non-negative number of bytes");
  return opt;
}

const USAGE = `usage: compile-task.mjs compile --index <index.json> --task <task.json>
                            [--facts <facts.jsonl>] [--decisions <file>]
                            [--budget <bytes>] [--out <dir>] [--deterministic]
                            [--artifact-threshold <bytes>]
`;

// -------------------------------------------------------- index normalizing --
// A missing or malformed index is a DEGRADED input, not a crash. It yields an
// honest empty capsule that says so, which is more useful than an exception.
function normalizeIndex(raw) {
  const idx = raw && typeof raw === "object" ? raw : {};
  return {
    index_version: Number.isInteger(idx.index_version) ? idx.index_version : null,
    repo_head: typeof idx.repo_head === "string" ? idx.repo_head : null,
    files: idx.files && typeof idx.files === "object" ? idx.files : {},
    symbols: idx.symbols && typeof idx.symbols === "object" ? idx.symbols : {},
    error_clusters: Array.isArray(idx.error_clusters) ? idx.error_clusters : [],
  };
}

const fileEntry = (idx, p) => (Object.prototype.hasOwnProperty.call(idx.files, p) ? idx.files[p] : null);
const listOf = (entry, field) => (entry && Array.isArray(entry[field]) ? entry[field] : []);

// --------------------------------------------------------- relevance walk --
// Deterministic and explainable. Every admitted path gets exactly one rule:
// the highest-priority rule that reached it. A path reachable by several rules
// is not listed twice and does not get a compound justification — the capsule
// states the strongest reason it is present, which is the reason the budgeter
// will also act on.
function deriveCandidates(idx, task) {
  const notes = [];
  const candidates = new Map(); // path -> { path, priority, why, symbols }

  const admit = (p, priority, why) => {
    if (!p || !fileEntry(idx, p)) return;
    const existing = candidates.get(p);
    if (existing && existing.priority <= priority) return;
    const entry = fileEntry(idx, p);
    candidates.set(p, {
      path: p,
      priority,
      why,
      symbols: uniqSort(listOf(entry, "symbols")),
      ...(entry && entry.partial === true ? { partial: true } : {}),
    });
  };

  // --- P1: the defining files. Seed files are taken at face value; seed
  // symbols are resolved through the index's symbol table.
  const definingFiles = new Set();

  for (const f of uniqSort(Array.isArray(task.seed_files) ? task.seed_files : [])) {
    if (!fileEntry(idx, f)) {
      notes.push(`seed file ${f}: not present in the index — cannot be walked from ` +
        `(the index may be stale or may not cover this path)`);
      continue;
    }
    definingFiles.add(f);
    admit(f, 1, "named as a seed file in the task descriptor");
  }

  for (const s of uniqSort(Array.isArray(task.seed_symbols) ? task.seed_symbols : [])) {
    const sym = idx.symbols[s];
    if (!sym || typeof sym.defined_in !== "string") {
      notes.push(`seed symbol ${s}: not found in the index — no defining file to walk ` +
        `from (unresolved seed, index coverage limitation)`);
      continue;
    }
    if (!fileEntry(idx, sym.defined_in)) {
      notes.push(`seed symbol ${s}: index says it is defined in ${sym.defined_in}, ` +
        `which the index does not describe — inconsistent index`);
      continue;
    }
    definingFiles.add(sym.defined_in);
    admit(sym.defined_in, 1, `defines seed symbol ${s}`);
  }

  const defs = [...definingFiles].sort();

  // --- P2: tests covering a defining file.
  for (const d of defs) {
    for (const t of uniqSort(listOf(fileEntry(idx, d), "tests_covering")))
      admit(t, 2, `test covering it (tests_covering of ${d})`);
  }
  // --- P3: direct importers of a defining file.
  for (const d of defs) {
    for (const i of uniqSort(listOf(fileEntry(idx, d), "imported_by")))
      admit(i, 3, `imports the defining file ${d}`);
  }
  // --- P4: the neighborhood — what a defining file imports.
  for (const d of defs) {
    for (const i of uniqSort(listOf(fileEntry(idx, d), "imports")))
      admit(i, 4, `direct import of the defining file ${d}`);
  }
  // --- P5: cluster siblings — files failing the same way.
  for (const cluster of idx.error_clusters) {
    const cfiles = Array.isArray(cluster && cluster.files) ? cluster.files : [];
    const hit = defs.filter((d) => cfiles.includes(d));
    if (!hit.length) continue;
    const sig = oneLine(cluster.signature ?? "unsignatured cluster", 80);
    for (const f of uniqSort(cfiles)) {
      if (definingFiles.has(f)) continue;
      admit(f, 5, `same error cluster as ${hit[0]} (signature: ${sig})`);
    }
  }

  // Honesty pass-through of SEAM 1's partial flag: an unparsed language's
  // empty symbol list must never read as "this file defines nothing".
  for (const c of [...candidates.values()].sort((a, b) => (a.path < b.path ? -1 : 1))) {
    if (c.partial) {
      notes.push(`${c.path}: index reports partial: true — symbols were not ` +
        `extracted for this language, so an empty symbol list is not evidence of absence`);
    }
  }

  if (!defs.length) {
    notes.push("relevance walk: no seed symbols or seed files resolved, so there was " +
      "no anchor to walk from — this capsule admits no files by design, not by omission");
  }

  // Fixed order: priority, then path. This is the admission order AND the
  // rendered order, so the budget's decisions are readable off the capsule.
  const sorted = [...candidates.values()].sort(
    (a, b) => a.priority - b.priority || (a.path < b.path ? -1 : a.path > b.path ? 1 : 0),
  );
  return { candidates: sorted, definingFiles: defs, notes };
}

// ------------------------------------------------------------- facts (SEAM 4) --
function loadFacts(file) {
  if (!file) return [];
  let raw;
  try {
    raw = fs.readFileSync(file, "utf8");
  } catch {
    die(`cannot read facts file: ${file}`);
  }
  const out = [];
  raw.split("\n").forEach((line, i) => {
    const t = line.trim();
    if (!t || t.startsWith("#")) return;
    try {
      out.push(JSON.parse(t));
    } catch {
      die(`facts file line ${i + 1} is not valid JSON (SEAM 4 is JSONL)`);
    }
  });
  return out.sort((a, b) => String(a.fact_id) < String(b.fact_id) ? -1 : 1);
}

// ---------------------------------------------------------- decisions --------
// Deliberately crude format: `topic: text`, one per line, # comments. Prior
// decisions live in many shapes across a repo; this reads the one shape the
// compiler can parse without guessing, and says so.
function loadDecisions(file) {
  if (!file) return [];
  let raw;
  try {
    raw = fs.readFileSync(file, "utf8");
  } catch {
    die(`cannot read decisions file: ${file}`);
  }
  const out = [];
  for (const line of raw.split("\n")) {
    const t = line.trim();
    if (!t || t.startsWith("#")) continue;
    const at = t.indexOf(":");
    if (at < 1) continue; // a line with no topic cannot be matched; skip quietly
    out.push({ topic: t.slice(0, at).trim(), text: t.slice(at + 1).trim() });
  }
  return out.sort((a, b) => (a.topic < b.topic ? -1 : a.topic > b.topic ? 1 : (a.text < b.text ? -1 : 1)));
}

// Substring scope matching, case-insensitive, over admitted paths and symbols.
// This is a NAMED HEURISTIC: it has no notion of topic hierarchy or synonymy.
// A topic of "auth" matches "src/auth/token.js" and also "src/oauth/x.js".
function scopeHits(scopeTokens, admittedPaths, admittedSymbols) {
  const hits = [];
  for (const tokRaw of scopeTokens) {
    const tok = String(tokRaw).toLowerCase();
    if (!tok) continue;
    for (const p of admittedPaths) if (p.toLowerCase().includes(tok)) { hits.push(p); break; }
    for (const s of admittedSymbols) if (s.toLowerCase() === tok) { hits.push(`symbol ${s}`); break; }
  }
  return uniqSort(hits);
}

// --------------------------------------------------------- artifacts --------
function buildArtifactRefs(opt, task, provenance, indexSummary) {
  const refs = [];
  const declared = [];

  // The index is always pinned. A capsule that cannot prove which index it was
  // compiled from cannot be reproduced or audited. Its summary is DERIVED from
  // the parsed index rather than from its first line — a JSON file's first line
  // is not a summary, it is a leak of the thing we are declining to inline.
  declared.push({ id: "index", path: opt.index, summary: indexSummary, structural: true });
  for (const a of Array.isArray(task.artifacts) ? task.artifacts : []) {
    if (a && typeof a.path === "string" && typeof a.id === "string") declared.push({ ...a, structural: false });
  }

  for (const a of declared.sort((x, y) => (x.id < y.id ? -1 : x.id > y.id ? 1 : 0))) {
    let buf;
    try {
      buf = fs.readFileSync(a.path);
    } catch {
      // Never fabricate a sha for a file that is not there.
      provenance.excluded_notable.push(
        `artifact ${a.id}: declared at ${a.path} but unreadable — referenced by neither ` +
        `hash nor body (not measured)`);
      continue;
    }
    const bytes = buf.length;
    const summary = a.summary
      ? oneLine(a.summary)
      : oneLine(buf.toString("utf8").split("\n").find((l) => l.trim()) || "(empty artifact)");
    const ref = { id: a.id, sha256: sha256(buf), summary, bytes };

    // Structural artifacts (the index) are NEVER inlined regardless of size:
    // the capsule consumes the index, it does not re-transmit it.
    const inlineIt = !a.structural && bytes <= opt.artifactThreshold;
    if (inlineIt) {
      ref.inline = buf.toString("utf8");
      provenance.included_because[`artifact:${a.id}`] =
        `artifact is ${bytes} bytes, at or under the ${opt.artifactThreshold}-byte inline threshold — body inlined`;
    } else {
      provenance.included_because[`artifact:${a.id}`] = a.structural
        ? `structural input pinned by sha256 (${bytes} bytes) — never inlined`
        : `artifact is ${bytes} bytes, over the ${opt.artifactThreshold}-byte inline threshold — ` +
          `referenced by sha256 + summary + size instead of inlined`;
      if (!a.structural) {
        provenance.excluded_notable.push(
          `artifact ${a.id}: body withheld (${bytes} bytes > ${opt.artifactThreshold}-byte threshold) — ` +
          `request it with need_artifact(${a.id})`);
      }
    }
    refs.push(ref);
  }
  return refs;
}

// ------------------------------------------------------------------ main ----
function main(argv) {
  const opt = parseArgs(argv);
  const idx = normalizeIndex(readJSON(opt.index, "index"));
  const task = readJSON(opt.task, "task");
  if (!task || typeof task !== "object") die("task descriptor must be a JSON object");

  const provenance = { included_because: {}, excluded_notable: [], prefix_sha256: PREFIX_SHA256 };

  const { candidates, definingFiles, notes } = deriveCandidates(idx, task);
  for (const n of notes) provenance.excluded_notable.push(n);

  // The capsule skeleton — everything that is NOT priced against the byte
  // budget. relevant_files is priced; the rest is the fixed cost of being a
  // capsule at all, and is measured before admission begins so the budget is
  // spent against a true remainder rather than an optimistic one.
  const budgetBytes = opt.budget !== null
    ? opt.budget
    : (task.budget && Number.isFinite(task.budget.bytes) ? task.budget.bytes : null);

  const nFiles = Object.keys(idx.files).length;
  const nSyms = Object.keys(idx.symbols).length;
  const indexSummary =
    `SEAM 1 repository index v${idx.index_version ?? "unknown"} at ` +
    `${idx.repo_head ? idx.repo_head.slice(0, 12) : "unknown head"} — ` +
    `${nFiles} file${nFiles === 1 ? "" : "s"}, ${nSyms} symbol${nSyms === 1 ? "" : "s"}, ` +
    `${idx.error_clusters.length} error cluster${idx.error_clusters.length === 1 ? "" : "s"}`;
  const artifact_refs = buildArtifactRefs(opt, task, provenance, indexSummary);

  const skeleton = {
    capsule_version: 1,
    task_id: typeof task.task_id === "string" && task.task_id ? task.task_id : "UNNAMED-TASK",
    compiled_at: opt.deterministic ? EPOCH : new Date().toISOString(),
    index_version: idx.index_version,
    repo_head: idx.repo_head,
    objective: typeof task.objective === "string" ? task.objective : "",
    acceptance: Array.isArray(task.acceptance) ? task.acceptance.map(String) : [],
    relevant_files: [],
    dependency_neighborhood: [],
    baseline: {
      targeted: typeof task.targeted_baseline === "string" && task.targeted_baseline
        ? task.targeted_baseline : "not measured",
      repo_wide: typeof task.repo_wide_baseline === "string" && task.repo_wide_baseline
        ? task.repo_wide_baseline : "not measured",
      measured_at: typeof task.baseline_measured_at === "string" && task.baseline_measured_at
        ? task.baseline_measured_at : null,
    },
    constraints: [],
    failed_approaches: [],
    allowed_mutation_surface: [],
    authority: {
      mode: task.authority && typeof task.authority.mode === "string" ? task.authority.mode : "direct",
      receipt: task.authority && typeof task.authority.receipt === "string" ? task.authority.receipt : "",
    },
    budget: {},
    verification: {
      commands: task.verification && Array.isArray(task.verification.commands)
        ? task.verification.commands.map(String) : [],
      expected: task.verification && typeof task.verification.expected === "string"
        ? task.verification.expected : "not stated",
    },
    artifact_refs,
    provenance,
  };

  // Fixed cost measured with relevant_files empty. Constraints and
  // failed_approaches are derived AFTER admission (they depend on which files
  // got in), so they are not in the base — the base is an honest floor, and
  // budget.spent_bytes reports what the file list actually cost on top of it.
  const baseBytes = bytesOf(JSON.stringify(stable(skeleton), null, 2));

  // --- admission ---------------------------------------------------------
  const admitted = [];
  let spent = 0;
  let stopped = false;
  for (const c of candidates) {
    const entry = { path: c.path, why: c.why, symbols: c.symbols, ...(c.partial ? { partial: true } : {}) };
    const cost = bytesOf(JSON.stringify(entry)) + 2; // + separator
    const fits = budgetBytes === null || baseBytes + spent + cost <= budgetBytes;
    if (!stopped && fits) {
      admitted.push({ ...entry, _priority: c.priority });
      spent += cost;
    } else {
      stopped = true; // priority is a ladder, not a knapsack: stop, do not skip
      const p = PRIORITY.find((x) => x.n === c.priority);
      provenance.excluded_notable.push(
        `${c.path}: budget: dropped at priority ${c.priority} (${p ? p.label : "unknown"}) — ` +
        `admitting it would cost ${cost} bytes against a ${budgetBytes}-byte budget with ` +
        `${Math.max(0, budgetBytes - baseBytes - spent)} remaining; rule was "${c.why}" — ` +
        `request it with need_file(${c.path})`);
    }
  }

  const admittedPaths = admitted.map((a) => a.path);
  const admittedSymbols = uniqSort(admitted.flatMap((a) => a.symbols));

  skeleton.relevant_files = admitted.map(({ _priority, ...rest }) => rest);
  for (const a of admitted) provenance.included_because[a.path] = a.why;

  skeleton.dependency_neighborhood = admitted
    .filter((a) => a._priority === 3 || a._priority === 4)
    .map((a) => a.path)
    .sort();

  skeleton.allowed_mutation_surface = Array.isArray(task.allowed_mutation_surface)
    ? uniqSort(task.allowed_mutation_surface)
    : uniqSort(definingFiles.filter((d) => admittedPaths.includes(d)));

  // --- durable facts (SEAM 4): scope overlap with what actually got in ----
  for (const f of loadFacts(opt.facts)) {
    const id = String(f.fact_id ?? "UNIDENTIFIED-FACT");
    const scope = Array.isArray(f.scope) ? f.scope : [];
    const hits = scopeHits(scope, admittedPaths, admittedSymbols);
    if (hits.length) {
      skeleton.failed_approaches.push(
        `[${id}] attempted: ${oneLine(f.attempted ?? "(not recorded)", 200)} — ` +
        `failed because: ${oneLine(f.failed_because ?? "(not recorded)", 200)} — ` +
        `conclusion: ${oneLine(f.reusable_conclusion ?? "(not recorded)", 240)}`);
      provenance.included_because[`fact:${id}`] =
        `durable fact scope overlaps admitted ${hits[0]}`;
    } else {
      // Disclose the ID only. The conclusion text stays out of the capsule —
      // that is the whole point of scoping facts.
      provenance.excluded_notable.push(
        `fact ${id}: withheld — its scope (${scope.length} entr${scope.length === 1 ? "y" : "ies"}) ` +
        `does not overlap any admitted file or symbol; request with need_prior_decision or need_artifact`);
    }
  }

  // --- prior decisions: topic overlap with admitted paths ----------------
  for (const d of loadDecisions(opt.decisions)) {
    const hits = scopeHits([d.topic], admittedPaths, admittedSymbols);
    if (hits.length) {
      skeleton.constraints.push(`[${d.topic}] ${d.text}`);
      provenance.included_because[`decision:${d.topic}`] =
        `prior decision topic "${d.topic}" matches admitted ${hits[0]}`;
    } else {
      provenance.excluded_notable.push(
        `decision topic ${d.topic}: not injected — no admitted path or symbol matched the ` +
        `topic; text withheld, request with need_prior_decision(${d.topic})`);
    }
  }

  skeleton.budget = {
    bytes: budgetBytes,
    base_bytes: baseBytes,
    spent_bytes: spent,
    candidates_total: candidates.length,
    admitted: admitted.length,
    dropped: candidates.length - admitted.length,
    priority_order: PRIORITY_LABELS,
    artifact_inline_threshold_bytes: opt.artifactThreshold,
    ...(budgetBytes !== null && baseBytes > budgetBytes
      ? { base_exceeds_budget: true }
      : {}),
  };

  // Deterministic tails. excluded_notable is sorted so two runs that discover
  // the same withholdings in a different code path still render identically.
  provenance.excluded_notable = [...new Set(provenance.excluded_notable)].sort();
  skeleton.failed_approaches.sort();
  skeleton.constraints.sort();

  const capsule = stable(skeleton);
  const json = JSON.stringify(capsule, null, 2) + "\n";
  const md = renderCapsule(capsule, IMMUTABLE_PREFIX);

  fs.mkdirSync(opt.out, { recursive: true });
  fs.writeFileSync(path.join(opt.out, "capsule.json"), json, "utf8");
  fs.writeFileSync(path.join(opt.out, "capsule.md"), md, "utf8");

  process.stdout.write(
    `capsule: ${skeleton.task_id}  files ${admitted.length}/${candidates.length}  ` +
    `withheld ${provenance.excluded_notable.length}  ` +
    `json ${bytesOf(json)}B  md ${bytesOf(md)}B  -> ${opt.out}\n`);
  return 0;
}

const invoked = process.argv[1] && fs.realpathSync(process.argv[1]) === fs.realpathSync(new URL(import.meta.url).pathname);
if (invoked) process.exit(main(process.argv.slice(2)));
