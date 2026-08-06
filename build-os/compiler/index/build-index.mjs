#!/usr/bin/env node
// Context Compiler / SEAM 1 — repository indexer.
//
//   build <repo> [--out <path>] [--since <index.json>] [--errors <file>]
//                [--deterministic]
//   stats <index.json>
//
// The index JSON goes to --out (or stdout when --out is absent). Every human
// report — the reuse counters, refusals — goes to stderr, so `build ... > x.json`
// stays a clean redirect.
//
// DETERMINISM IS A HARD REQUIREMENT. Same repo state => byte-identical index.
// Everything that could wobble is pinned: every collection is sorted with the
// default (code-unit, locale-independent) comparator; no wall-clock value is
// stored per file; `generated_at` is the ONLY time field and --deterministic
// nulls it. An incremental build is asserted by the test suite to be
// byte-identical to a full build of the same tree, which is why the reusable
// unit is the raw parse (`raw_imports`, symbols) and never a derived,
// whole-repo-dependent field like `imports` or `imported_by`.
//
// WHAT IS TRACKED: `git ls-files` only. Untracked and ignored files are absent
// from the index by construction, not by omission — the index describes the
// repository, not the working directory's debris.

import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { langOf, kindOf, stemOf, dirname, basename } from './classify.mjs';
import { extractFor, tokensOf } from './extract.mjs';
import { parseErrors } from './errors.mjs';

const INDEX_VERSION = 1;
const RESOLVE_EXTS = ['.ts', '.tsx', '.mts', '.cts', '.js', '.jsx', '.mjs', '.cjs', '.json'];

function die(msg) { process.stderr.write(`build-index: ${msg}\n`); process.exit(2); }

function git(repo, args) {
  return execFileSync('git', ['-C', repo, ...args], { encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 });
}
function gitOrNull(repo, args) {
  try { return git(repo, args); } catch { return null; }
}

// git's blob id: sha1("blob <bytes>\0" + content). Computed from the same bytes
// we parse, so the reuse key can never disagree with the parsed content.
function blobSha(buf) {
  const h = createHash('sha1');
  h.update(Buffer.from(`blob ${buf.length}\0`, 'utf8'));
  h.update(buf);
  return h.digest('hex');
}

// One `git log` pass for every path's most recent commit date. A per-file
// `git log` would be one process per file; this is one process, same answer.
// MARKER prefixes date lines so a date can never be mistaken for a path.
const MARKER = String.fromCharCode(1);
function lastChangedMap(repo) {
  const out = gitOrNull(repo, ['log', `--pretty=format:${MARKER}%cI`, '--name-only']);
  const map = new Map();
  if (!out) return map;
  let cur = null;
  for (const line of out.split('\n')) {
    if (line.startsWith(MARKER)) { cur = line.slice(1).trim(); continue; }
    const p = line.trim();
    if (!p || !cur) continue;
    const key = p.startsWith('"') ? JSON.parse(p) : p;
    if (!map.has(key)) map.set(key, cur);
  }
  return map;
}

function normJoin(dir, spec) {
  const joined = dir ? `${dir}/${spec}` : spec;
  const parts = [];
  for (const seg of joined.split('/')) {
    if (seg === '.' || seg === '') continue;
    if (seg === '..') { parts.pop(); continue; }
    parts.push(seg);
  }
  return parts.join('/');
}

// Relative specifiers resolve against the indexed file set. Anything else — a
// bare module ('express'), an alias ('@app/x'), a python dotted name — is
// UNRESOLVED and stays verbatim in `imports`. Unresolved never produces a
// reverse edge: an invented `imported_by` is worse than a missing one.
function resolveSpec(spec, fromPath, fileSet) {
  if (!spec.startsWith('./') && !spec.startsWith('../')) return null;
  const base = normJoin(dirname(fromPath), spec);
  if (fileSet.has(base)) return base;
  for (const e of RESOLVE_EXTS) if (fileSet.has(base + e)) return base + e;
  for (const e of RESOLVE_EXTS) if (fileSet.has(`${base}/index${e}`)) return `${base}/index${e}`;
  return null;
}

function pct(n, total) { return total === 0 ? 'n/a' : `${((n / total) * 100).toFixed(1)}%`; }

// ---------------------------------------------------------------------------
// build
// ---------------------------------------------------------------------------
function cmdBuild(argv) {
  let repo = null, out = null, since = null, errorsFile = null, deterministic = false;
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--out') { out = argv[++i]; if (!out) die('--out needs a path'); }
    else if (a === '--since') { since = argv[++i]; if (!since) die('--since needs a path'); }
    else if (a === '--errors') { errorsFile = argv[++i]; if (!errorsFile) die('--errors needs a path'); }
    else if (a === '--deterministic') deterministic = true;
    else if (a.startsWith('-')) die(`unknown flag: ${a}`);
    else if (repo === null) repo = a;
    else die(`unexpected argument: ${a}`);
  }
  if (repo === null) die('build needs a repository path');
  const root = path.resolve(repo);
  if (!fs.existsSync(root) || !fs.statSync(root).isDirectory()) die(`not a directory: ${repo}`);
  if (gitOrNull(root, ['rev-parse', '--git-dir']) === null) die(`not a git repository: ${repo}`);

  const head = (gitOrNull(root, ['rev-parse', 'HEAD']) || '').trim() || null;
  const listed = gitOrNull(root, ['ls-files', '-z']) || '';
  const paths = listed.split('\0').filter(Boolean).sort();

  let prior = null;
  if (since) {
    try { prior = JSON.parse(fs.readFileSync(since, 'utf8')); }
    catch (e) { die(`cannot read --since index ${since}: ${e.message}`); }
    if (!prior || typeof prior.files !== 'object') die(`--since index has no files map: ${since}`);
  }

  const changed = lastChangedMap(root);
  const fileSet = new Set(paths);
  const parsed = new Map();   // path -> { blob, lang, kind, parser, partial, decls-ish }
  const tokens = new Map();   // path -> Set<string>
  let reused = 0, reparsed = 0, skipped = 0;

  for (const p of paths) {
    const abs = path.join(root, p);
    let buf;
    try { buf = fs.readFileSync(abs); } catch { skipped++; continue; }
    const blob = blobSha(buf);
    const lang = langOf(p);
    const kind = kindOf(p);
    const binary = buf.includes(0);
    const text = binary ? '' : buf.toString('utf8');
    tokens.set(p, binary ? new Set() : tokensOf(text));

    const priorEntry = prior && prior.files ? prior.files[p] : undefined;
    if (priorEntry && priorEntry.blob === blob && Array.isArray(priorEntry.symbols)
        && Array.isArray(priorEntry.raw_imports)) {
      // Same path, same blob => the parse cannot have changed. Copy it.
      reused++;
      parsed.set(p, {
        blob, lang, kind,
        parser: priorEntry.parser || 'none',
        partial: priorEntry.partial !== false,
        symbols: [...priorEntry.symbols].sort(),
        symbolLines: { ...(priorEntry.symbol_lines || {}) },
        rawImports: [...priorEntry.raw_imports].sort(),
      });
      continue;
    }
    reparsed++;
    const ex = binary ? { decls: [], rawImports: [], parser: 'none' } : extractFor(lang, text);
    const symbolLines = {};
    for (const d of ex.decls) if (!(d.name in symbolLines)) symbolLines[d.name] = d.line;
    parsed.set(p, {
      blob, lang, kind,
      parser: ex.parser,
      // v0 is regex/line based for every language it reads, and blind for the
      // rest. Nothing here is AST-accurate, so nothing here claims to be.
      partial: true,
      symbols: [...new Set(ex.decls.map((d) => d.name))].sort(),
      symbolLines,
      rawImports: [...ex.rawImports].sort(),
    });
  }

  // --- derived, always recomputed (never reused) ----------------------------
  const imports = new Map();
  const importedBy = new Map();
  for (const p of parsed.keys()) { imports.set(p, []); importedBy.set(p, []); }
  for (const [p, info] of parsed) {
    const list = [];
    for (const spec of info.rawImports) {
      const target = resolveSpec(spec, p, fileSet);
      if (target && parsed.has(target)) { list.push(target); importedBy.get(target).push(p); }
      else list.push(spec);
    }
    imports.set(p, [...new Set(list)].sort());
  }

  // tests_covering — HEURISTIC, twice over: a test "covers" a file if it
  // resolves an import to it, or if their basename stems match after stripping
  // test/spec affixes. Neither is evidence that the test exercises the file.
  const covering = new Map();
  for (const p of parsed.keys()) covering.set(p, new Set());
  const stems = new Map();
  for (const [p, info] of parsed) {
    if (info.kind === 'test') continue;
    const s = stemOf(p);
    if (!stems.has(s)) stems.set(s, []);
    stems.get(s).push(p);
  }
  for (const [t, info] of parsed) {
    if (info.kind !== 'test') continue;
    for (const spec of info.rawImports) {
      const target = resolveSpec(spec, t, fileSet);
      if (target && parsed.has(target) && parsed.get(target).kind !== 'test') covering.get(target).add(t);
    }
    for (const target of stems.get(stemOf(t)) || []) covering.get(target).add(t);
  }

  // symbols table — referenced_in is a whole-word TEXT match, nothing more.
  const symbolTable = new Map();
  for (const [p, info] of parsed) {
    for (const name of info.symbols) {
      if (!symbolTable.has(name)) symbolTable.set(name, { defined_in: p, line: info.symbolLines[name] ?? 0, also: [] });
      else symbolTable.get(name).also.push(p);
    }
  }
  const refs = new Map();
  for (const name of symbolTable.keys()) refs.set(name, []);
  for (const [p, set] of tokens) {
    for (const name of symbolTable.keys()) if (set.has(name)) refs.get(name).push(p);
  }

  // errors
  let errorsMeasured = false, perFileErrors = new Map(), clusters = [];
  if (errorsFile) {
    let text;
    try { text = fs.readFileSync(errorsFile, 'utf8'); }
    catch (e) { die(`cannot read --errors file ${errorsFile}: ${e.message}`); }
    const r = parseErrors(text, root);
    errorsMeasured = r.measured; perFileErrors = r.perFile; clusters = r.clusters;
  }

  // --- assemble, in fixed key order, everything sorted ----------------------
  const files = {};
  for (const p of [...parsed.keys()].sort()) {
    const info = parsed.get(p);
    const lines = {};
    for (const k of Object.keys(info.symbolLines).sort()) lines[k] = info.symbolLines[k];
    files[p] = {
      blob: info.blob,
      lang: info.lang,
      kind: info.kind,
      parser: info.parser,
      partial: info.partial,
      symbols: info.symbols,
      symbol_lines: lines,
      raw_imports: info.rawImports,
      imports: imports.get(p),
      imported_by: [...new Set(importedBy.get(p))].sort(),
      tests_covering: [...covering.get(p)].sort(),
      last_changed: changed.get(p) ?? null,
      error_count: errorsMeasured ? (perFileErrors.get(p) || 0) : null,
    };
  }
  const symbols = {};
  for (const name of [...symbolTable.keys()].sort()) {
    const s = symbolTable.get(name);
    symbols[name] = {
      defined_in: s.defined_in,
      line: s.line,
      referenced_in: [...refs.get(name)].sort(),
      also_defined_in: [...new Set(s.also)].sort(),
    };
  }

  const index = {
    index_version: INDEX_VERSION,
    repo_head: head,
    generated_at: deterministic ? null : new Date().toISOString(),
    symbols_partial: true,          // referenced_in is a text heuristic
    tests_covering_heuristic: true, // import-or-basename, not measured coverage
    errors_measured: errorsMeasured,
    files,
    symbols,
    error_clusters: clusters,
  };

  const json = JSON.stringify(index, null, 2) + '\n';
  if (out) fs.writeFileSync(out, json); else process.stdout.write(json);
  process.stderr.write(
    `index: ${Object.keys(files).length} files, reused ${reused}, reparsed ${reparsed}`
    + (skipped ? `, skipped ${skipped} (tracked but absent from the worktree)` : '')
    + ' — reuse skips parsing, not file IO (the reference pass reads every file)\n');
  return 0;
}

// ---------------------------------------------------------------------------
// stats — coverage is REPORTED, never implied.
// ---------------------------------------------------------------------------
function cmdStats(argv) {
  const p = argv[0];
  if (!p || p.startsWith('-')) die('stats needs an index.json path');
  if (argv.length > 1) die(`unexpected argument: ${argv[1]}`);
  let idx;
  try { idx = JSON.parse(fs.readFileSync(p, 'utf8')); }
  catch (e) { die(`cannot read index ${p}: ${e.message}`); }
  if (!idx || typeof idx.files !== 'object') die(`not an index (no files map): ${p}`);

  const entries = Object.entries(idx.files);
  const total = entries.length;
  const withSymbols = entries.filter(([, f]) => (f.symbols || []).length > 0).length;
  const partial = entries.filter(([, f]) => f.partial === true).length;
  const noParser = entries.filter(([, f]) => (f.parser || 'none') === 'none').length;
  const langs = new Map();
  for (const [, f] of entries) langs.set(f.lang, (langs.get(f.lang) || 0) + 1);
  const fileSet = new Set(Object.keys(idx.files));
  let importsTotal = 0; const unresolved = [];
  for (const [, f] of entries) {
    for (const s of f.imports || []) { importsTotal++; if (!fileSet.has(s)) unresolved.push(s); }
  }
  const covered = entries.filter(([, f]) => (f.tests_covering || []).length > 0).length;
  const langLine = langs.size === 0 ? '(none)'
    : [...langs.keys()].sort().map((k) => `${k}=${langs.get(k)}`).join(', ');

  const L = [];
  L.push(`index_version: ${idx.index_version ?? 'unknown'}`);
  L.push(`repo_head: ${idx.repo_head === null || idx.repo_head === undefined ? 'null (not measured)' : idx.repo_head}`);
  L.push(`generated_at: ${idx.generated_at === null || idx.generated_at === undefined ? 'null (deterministic build)' : idx.generated_at}`);
  L.push(`files_indexed: ${total}`);
  L.push(`with_symbols: ${withSymbols} (${pct(withSymbols, total)})`);
  L.push(`partial: ${partial} (${pct(partial, total)})`);
  L.push(`no_parser: ${noParser} (${pct(noParser, total)})`);
  L.push(`languages: ${langLine}`);
  L.push(`imports_total: ${importsTotal}`);
  L.push(`unresolved_imports: ${unresolved.length} (unique: ${new Set(unresolved).size})`);
  L.push(`symbols_table: ${Object.keys(idx.symbols || {}).length}`);
  L.push(`files_with_a_covering_test: ${covered} (${pct(covered, total)})`);
  L.push(`errors_measured: ${idx.errors_measured === true}`);
  L.push(`error_clusters: ${(idx.error_clusters || []).length}`);
  L.push('');
  L.push('COVERAGE NOTE — these numbers are measured from the index, not implied by it:');
  L.push(`  * ${partial} of ${total} files are flagged partial: v0 extraction is regex/line based,`);
  L.push('    never an AST, so absent symbols mean "not extracted", not "not present".');
  L.push('  * referenced_in is a whole-word text match (symbols_partial: '
    + `${idx.symbols_partial === true}), not a resolved reference graph.`);
  L.push('  * tests_covering is an import-or-basename heuristic '
    + `(tests_covering_heuristic: ${idx.tests_covering_heuristic === true}), not executed coverage.`);
  L.push(`  * ${unresolved.length} import specifiers were left unresolved and produced no imported_by edge.`);
  if (idx.errors_measured !== true) L.push('  * errors were NOT measured: every error_count is null, not zero.');
  process.stdout.write(L.join('\n') + '\n');
  return 0;
}

const [, , cmd, ...rest] = process.argv;
if (cmd === 'build') process.exit(cmdBuild(rest));
else if (cmd === 'stats') process.exit(cmdStats(rest));
else if (cmd === '--help' || cmd === '-h') {
  process.stdout.write('usage: build-index.mjs build <repo> [--out <path>] [--since <index.json>] '
    + '[--errors <file>] [--deterministic]\n       build-index.mjs stats <index.json>\n');
  process.exit(0);
} else die(cmd ? `unknown subcommand: ${cmd}` : 'no subcommand (expected build|stats)');
