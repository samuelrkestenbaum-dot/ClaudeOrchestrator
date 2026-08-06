#!/usr/bin/env node
// Context Compiler — the expansion API (SEAM 3: the context economy).
//
// THE ARGUMENT. A capsule ships the minimum. When the minimum turns out to be
// too little, the worker BUYS more — and every purchase is recorded. That
// record is not a usage meter: it is the compiler's own error signal. If the
// same kind of expansion is bought over and over, the capsule was
// SYSTEMATICALLY INCOMPLETE and the compiler's selection rules are what need
// fixing, not the worker's patience. `report` says exactly that, in words,
// because a number nobody interprets changes nothing.
//
// WHAT A REQUEST RETURNS. A SLICE, never the whole file where a range or a
// symbol span suffices, and always with the withheld bytes stated. The
// arithmetic is exact and checkable:
//
//     content_bytes + withheld_bytes == source_bytes
//
// `content_bytes` is source material actually delivered; `bytes` is what the
// worker is billed (the rendered slice, including any framing headers) and is
// the column charged against the budget. Reporting one number where there are
// two would let a slice look cheaper than it is.
//
// DENIAL IS DATA. An unknown symbol, an unknown path, an exhausted budget: each
// appends a row carrying its reason and exits 3. A protocol that logs only its
// grants describes a context economy that never happened.
//
// THE SIX REQUEST TYPES (SEAM 3, verbatim):
//   need_symbol_context <symbol>   need_callers <symbol>
//   need_file <path> [--range A-B] need_prior_decision <topic>
//   need_test_history <path>       need_artifact <id>
//   report <events.tsv>
//
// OPTIONS
//   --index <index.json>  SEAM 1 index      --repo <dir>       repository root
//   --task <id>           charged to this   --events <tsv>     append-only ledger
//   --decisions <jsonl>   prior decisions   --registry <dir>   artifact registry
//   --range A-B           need_file only    --window N         symbol context lines
//   --max-callers N       caller cap        --budget N         bytes for this task
//   --now <iso>           deterministic ts
//
// Exit codes: 0 granted, 3 DENIED (a normal outcome, on the record), 2 usage.
// Node stdlib only. No network. Writes nothing but the ledger.
import { readFileSync, existsSync, appendFileSync, writeFileSync } from "node:fs";
import { join, resolve, sep } from "node:path";
import { getArtifact, refFor, tsvSafe } from "./artifacts.mjs";

const LEDGER_FIELDS = ["ts", "task_id", "request", "granted", "bytes", "reason"];
const LEDGER_HEADER = LEDGER_FIELDS.join("\t");
const DEFAULT_WINDOW = 20;   // lines of context around a declaration
const DEFAULT_MAX_CALLERS = 5;

const byteLen = (s) => Buffer.byteLength(s, "utf8");

// ---------------------------------------------------------------------------
// The ledger. Append-only: rows are only ever added, never rewritten, and every
// field is escaped so a crafted request cannot forge a row or shift a column.
// ---------------------------------------------------------------------------
export const readEvents = (eventsPath) => {
  if (!existsSync(eventsPath)) return [];
  return readFileSync(eventsPath, "utf8")
    .split("\n")
    .filter((l) => l.length > 0 && !l.startsWith("ts\t"))
    .map((l) => {
      const f = l.split("\t");
      return {
        ts: f[0], task_id: f[1], request: f[2],
        granted: f[3], bytes: Number(f[4]) || 0, reason: f[5],
      };
    });
};

export const appendEvent = (eventsPath, ev) => {
  if (!existsSync(eventsPath)) writeFileSync(eventsPath, LEDGER_HEADER + "\n");
  const row = [ev.ts, ev.task_id, ev.request, ev.granted ? "y" : "n", String(ev.bytes), ev.reason]
    .map(tsvSafe)
    .join("\t");
  appendFileSync(eventsPath, row + "\n");
};

// Bytes already granted to this task — the budget is spent against the LEDGER,
// so a fresh process cannot forget what an earlier one bought.
export const spentByTask = (eventsPath, taskId) =>
  readEvents(eventsPath)
    .filter((e) => e.task_id === tsvSafe(taskId) && e.granted === "y")
    .reduce((a, e) => a + e.bytes, 0);

// ---------------------------------------------------------------------------
// Slice helpers. NOTE, PLAINLY: slice selection is a HEURISTIC. A line window
// around a declaration is not a parsed symbol span, and a caller snippet is a
// line match, not a call graph. The ACCOUNTING is exact; the CHOICE is not.
// ---------------------------------------------------------------------------
const splitKeepNewlines = (text) => {
  const out = text.split("\n");
  // Re-attach the newline to every line except a trailing empty remainder, so
  // the per-line byte sums add back up to the file's exact size.
  return out.map((l, i) => (i < out.length - 1 ? l + "\n" : l));
};

const lineRegion = (lines, from, to) => {
  const a = Math.max(1, from), b = Math.min(lines.length, to);
  return { from: a, to: b, text: lines.slice(a - 1, b).join("") };
};

const safeRepoPath = (repo, p) => {
  const root = resolve(repo);
  const full = resolve(join(root, p));
  return full === root || full.startsWith(root + sep) ? full : null;
};

const deny = (request, reason, sourceBytes = 0) => ({
  granted: false, reason, request,
  source_bytes: sourceBytes, content_bytes: 0, withheld_bytes: sourceBytes,
  bytes: 0, slice: null, meta: {},
});

const grant = (request, slice, sourceBytes, contentBytes, meta = {}) => ({
  granted: true, reason: "ok", request,
  source_bytes: sourceBytes,
  content_bytes: contentBytes,
  withheld_bytes: sourceBytes - contentBytes,
  bytes: byteLen(typeof slice === "string" ? slice : JSON.stringify(slice)),
  slice,
  meta,
});

// ---------------------------------------------------------------------------
// The six request types.
// ---------------------------------------------------------------------------
const needSymbolContext = (ctx, symbol) => {
  const request = `need_symbol_context(${symbol})`;
  const entry = ctx.index?.symbols?.[symbol];
  if (!entry) return deny(request, `unknown_symbol: ${symbol}`);
  const full = safeRepoPath(ctx.repo, entry.defined_in);
  if (!full || !existsSync(full)) return deny(request, `unknown_path: ${entry.defined_in}`);
  const text = readFileSync(full, "utf8");
  const lines = splitKeepNewlines(text);
  const w = ctx.window;
  // The declaration plus a bounded window: two lines of lead-in (a decorator or
  // a doc line often sits directly above) and `window` lines after it.
  const r = lineRegion(lines, entry.line - 2, entry.line + w);
  const slice = `--- ${entry.defined_in}:${r.from}-${r.to} (symbol ${symbol}) ---\n${r.text}`;
  return grant(request, slice, byteLen(text), byteLen(r.text), {
    path: entry.defined_in, declared_at_line: entry.line, window: w,
  });
};

const needCallers = (ctx, symbol) => {
  const request = `need_callers(${symbol})`;
  const entry = ctx.index?.symbols?.[symbol];
  if (!entry) return deny(request, `unknown_symbol: ${symbol}`);
  const refs = (entry.referenced_in || []).slice(0, ctx.maxCallers);
  if (refs.length === 0) return deny(request, `no_callers_indexed: ${symbol}`);
  let sourceBytes = 0, contentBytes = 0;
  const blocks = [];
  for (const p of refs) {
    const full = safeRepoPath(ctx.repo, p);
    if (!full || !existsSync(full)) continue;
    const text = readFileSync(full, "utf8");
    sourceBytes += byteLen(text);
    const lines = splitKeepNewlines(text);
    // Union of small windows around each mention, so overlapping windows are
    // never counted (or billed) twice.
    const keep = new Set();
    lines.forEach((l, i) => {
      if (l.includes(symbol)) for (let k = i - 1; k <= i + 1; k += 1)
        if (k >= 0 && k < lines.length) keep.add(k);
    });
    if (keep.size === 0) continue;
    const idx = [...keep].sort((a, b) => a - b);
    const body = idx.map((i) => lines[i]).join("");
    contentBytes += byteLen(body);
    blocks.push(`--- ${p}:${idx[0] + 1}-${idx[idx.length - 1] + 1} (calls ${symbol}) ---\n${body}`);
  }
  if (blocks.length === 0) return deny(request, `no_caller_text_found: ${symbol}`, sourceBytes);
  return grant(request, blocks.join("\n"), sourceBytes, contentBytes, {
    callers: refs, capped_at: ctx.maxCallers,
  });
};

const needFile = (ctx, path, range) => {
  const request = range ? `need_file(${path}:${range})` : `need_file(${path})`;
  const full = safeRepoPath(ctx.repo, path);
  if (!full) return deny(request, `path_outside_repo: ${path}`);
  if (!existsSync(full)) return deny(request, `unknown_path: ${path}`);
  const text = readFileSync(full, "utf8");
  const sourceBytes = byteLen(text);
  if (!range) return grant(request, text, sourceBytes, sourceBytes, { path, whole_file: true });
  const m = /^(\d+)-(\d+)$/.exec(range);
  if (!m) return deny(request, `bad_range: ${range}`, sourceBytes);
  const lines = splitKeepNewlines(text);
  const r = lineRegion(lines, Number(m[1]), Number(m[2]));
  const slice = `--- ${path}:${r.from}-${r.to} ---\n${r.text}`;
  return grant(request, slice, sourceBytes, byteLen(r.text), { path, range: `${r.from}-${r.to}` });
};

const needPriorDecision = (ctx, topic) => {
  const request = `need_prior_decision(${topic})`;
  if (!ctx.decisions || !existsSync(ctx.decisions))
    return deny(request, "no_decision_log_configured");
  const lines = readFileSync(ctx.decisions, "utf8").split("\n").filter((l) => l.trim().length > 0);
  const needle = String(topic).toLowerCase();
  let sourceBytes = 0, contentBytes = 0;
  const hits = [];
  for (const l of lines) {
    sourceBytes += byteLen(l);
    let rec = null;
    try { rec = JSON.parse(l); } catch { rec = null; }
    const hay = (rec ? `${rec.topic ?? ""} ${rec.decision ?? ""}` : l).toLowerCase();
    if (hay.includes(needle)) { contentBytes += byteLen(l); hits.push(rec ?? l); }
  }
  if (hits.length === 0) return deny(request, `unknown_topic: ${topic}`, sourceBytes);
  return grant(request, hits.map((h) => (typeof h === "string" ? h : JSON.stringify(h))).join("\n"),
    sourceBytes, contentBytes, { matched: hits.length, of: lines.length });
};

// SEAM 1's honesty rule travels with the data: `null` means NOT MEASURED and is
// passed through as null. Rendering it as 0 would turn an unknown into a claim.
const TEST_HISTORY_KEYS = ["kind", "tests_covering", "last_changed", "error_count"];

const needTestHistory = (ctx, path) => {
  const request = `need_test_history(${path})`;
  const entry = ctx.index?.files?.[path];
  if (!entry) return deny(request, `unknown_path: ${path}`);
  // Per-key accounting: the source is the whole index entry, the content is the
  // keys actually handed over, and the difference is what was withheld.
  const keyBytes = (k) => byteLen(`${JSON.stringify(k)}:${JSON.stringify(entry[k] ?? null)}`);
  let sourceBytes = 0, contentBytes = 0;
  const slice = { path };
  for (const k of Object.keys(entry)) {
    sourceBytes += keyBytes(k);
    if (TEST_HISTORY_KEYS.includes(k)) { contentBytes += keyBytes(k); slice[k] = entry[k] ?? null; }
  }
  for (const k of TEST_HISTORY_KEYS) if (!(k in slice)) slice[k] = null;
  slice.error_count_note = entry.error_count === null || entry.error_count === undefined
    ? "null means NOT MEASURED, not zero"
    : "measured";
  return grant(request, slice, sourceBytes, contentBytes, { path });
};

const needArtifact = (ctx, id) => {
  const request = `need_artifact(${id})`;
  if (!ctx.registry) return deny(request, "no_registry_configured");
  const buf = getArtifact(ctx.registry, id);
  if (buf === null) return deny(request, `unknown_artifact: ${id}`);
  const ref = refFor(ctx.registry, id);
  const text = buf.toString("utf8");
  return grant(request, text, buf.length, buf.length, { artifact_ref: ref });
};

// ---------------------------------------------------------------------------
// report — the context economy, and what it MEANS.
// ---------------------------------------------------------------------------
export const buildReport = (eventsPath) => {
  const evs = readEvents(eventsPath);
  const granted = evs.filter((e) => e.granted === "y");
  const denied = evs.filter((e) => e.granted !== "y");
  const counts = new Map();
  for (const e of evs) counts.set(e.request, (counts.get(e.request) || 0) + 1);
  const ranked = [...counts.entries()]
    .sort((a, b) => (b[1] - a[1]) || a[0].localeCompare(b[0]));
  const reasons = new Map();
  for (const e of denied) {
    const kind = String(e.reason || "unknown").split(":")[0];
    reasons.set(kind, (reasons.get(kind) || 0) + 1);
  }
  return {
    total: evs.length,
    granted: granted.length,
    denied: denied.length,
    bytes_bought: granted.reduce((a, e) => a + e.bytes, 0),
    ranked,
    reasons: [...reasons.entries()].sort((a, b) => (b[1] - a[1]) || a[0].localeCompare(b[0])),
    repeated: ranked.filter(([, n]) => n > 1),
  };
};

const renderReport = (eventsPath, r) => {
  const pct = r.total === 0 ? 0 : Math.round((r.granted / r.total) * 100);
  const out = [];
  out.push(`== context economy: ${eventsPath} ==`);
  out.push(`total_expansions: ${r.total}`);
  out.push(`granted: ${r.granted}`);
  out.push(`denied: ${r.denied}`);
  out.push(`grant_rate_pct: ${pct}`);
  out.push(`bytes_bought: ${r.bytes_bought}`);
  out.push("most_requested:");
  if (r.ranked.length === 0) out.push("  (none)");
  for (const [req, n] of r.ranked.slice(0, 10)) out.push(`  ${n}\t${req}`);
  out.push("denial_reasons:");
  if (r.reasons.length === 0) out.push("  (none)");
  for (const [reason, n] of r.reasons) out.push(`  ${n}\t${reason}`);
  out.push("");
  out.push("READ THIS AS AN ERROR SIGNAL, NOT A USAGE METER.");
  out.push(
    "Every expansion is a measurable admission that the capsule was incomplete.",
  );
  out.push(
    "Frequent expansion of the SAME kind means the capsule was systematically incomplete:",
  );
  out.push(
    "the compiler's selection rule for that kind is what needs fixing, not the worker.",
  );
  if (r.repeated.length === 0) {
    out.push("No request was bought more than once here — no systematic gap is visible yet.");
  } else {
    out.push(`Repeatedly bought (${r.repeated.length}), each a candidate for inclusion by default:`);
    for (const [req, n] of r.repeated.slice(0, 10)) out.push(`  ${n}x  ${req}`);
  }
  if (r.denied > 0) {
    out.push(
      `${r.denied} denial(s) are recorded above WITH their reasons — a denied request is data, not silence.`,
    );
  }
  return out.join("\n") + "\n";
};

// ---------------------------------------------------------------------------
// CLI
// ---------------------------------------------------------------------------
const flag = (argv, name, dflt = null) => {
  const i = argv.indexOf(`--${name}`);
  return i >= 0 && i + 1 < argv.length ? argv[i + 1] : dflt;
};

const HANDLERS = {
  need_symbol_context: (ctx, a) => needSymbolContext(ctx, a),
  need_callers: (ctx, a) => needCallers(ctx, a),
  need_file: (ctx, a, argv) => needFile(ctx, a, flag(argv, "range")),
  need_prior_decision: (ctx, a) => needPriorDecision(ctx, a),
  need_test_history: (ctx, a) => needTestHistory(ctx, a),
  need_artifact: (ctx, a) => needArtifact(ctx, a),
};

const main = (argv) => {
  const cmd = argv[0];
  if (!cmd) {
    process.stderr.write(`usage: expand.mjs <${Object.keys(HANDLERS).join("|")}|report> <arg> [options]\n`);
    return 2;
  }

  if (cmd === "report") {
    const eventsPath = argv[1];
    if (!eventsPath) { process.stderr.write("usage: expand.mjs report <events.tsv>\n"); return 2; }
    process.stdout.write(renderReport(eventsPath, buildReport(eventsPath)));
    return 0;
  }

  const handler = HANDLERS[cmd];
  if (!handler) { process.stderr.write(`expand: unknown request type: ${cmd}\n`); return 2; }

  const arg = argv[1];
  const eventsPath = flag(argv, "events");
  const taskId = flag(argv, "task");
  if (arg === undefined || !eventsPath || !taskId) {
    process.stderr.write("expand: --task, --events and a request argument are required\n");
    return 2;
  }

  const indexPath = flag(argv, "index");
  const ctx = {
    index: indexPath && existsSync(indexPath) ? JSON.parse(readFileSync(indexPath, "utf8")) : {},
    repo: flag(argv, "repo", process.cwd()),
    decisions: flag(argv, "decisions"),
    registry: flag(argv, "registry"),
    window: Number(flag(argv, "window", DEFAULT_WINDOW)),
    maxCallers: Number(flag(argv, "max-callers", DEFAULT_MAX_CALLERS)),
  };
  const now = flag(argv, "now", new Date().toISOString());
  const budget = flag(argv, "budget");

  let res = handler(ctx, arg, argv);

  // The budget is checked AFTER the slice is built, because the honest question
  // is "can this task afford THIS slice", not "does it have some bytes left".
  if (res.granted && budget !== null) {
    const cap = Number(budget);
    const spent = spentByTask(eventsPath, taskId);
    if (spent + res.bytes > cap) {
      res = deny(res.request,
        `budget_exhausted: ${spent}+${res.bytes} over cap ${cap}`, res.source_bytes);
    }
  }

  appendEvent(eventsPath, {
    ts: now, task_id: taskId, request: res.request,
    granted: res.granted, bytes: res.bytes, reason: res.reason,
  });

  process.stdout.write(JSON.stringify({ task_id: taskId, ts: now, ...res }, null, 2) + "\n");
  return res.granted ? 0 : 3;
};

if (import.meta.url === `file://${process.argv[1]}`) process.exit(main(process.argv.slice(2)));
