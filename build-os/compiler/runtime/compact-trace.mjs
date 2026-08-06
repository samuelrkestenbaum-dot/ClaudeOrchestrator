#!/usr/bin/env node
// Context Compiler — the trace compactor (SEAM 4: durable facts, not transcripts).
//
// THE ONE RULE THIS FILE EXISTS TO ENFORCE. A fact may be emitted ONLY from an
// OBSERVED failure: a command that actually ran and reported a non-zero exit, or
// an error string present in captured output. Never from speculation.
//
// WHY THAT RULE IS THE WHOLE PRODUCT. A fabricated fact is shaped exactly like
// an observed one. Once written it is indistinguishable downstream, and later
// capsules inject it into `failed_approaches`, where it steers a worker away
// from an approach that may work perfectly well — permanently, invisibly, and
// with the authority of a record. A compactor that guesses is worse than no
// compactor, because it launders a hunch into evidence. So when a trace
// contains only speculation this program emits NOTHING and says so on stderr.
// Emitting nothing is the correct outcome, not a failure, and it exits 0.
//
// Consequently `reusable_conclusion` is COMPOSED from observed evidence — the
// failing command, the error text, the touched scope — and never written as
// free-form prose. There is no place in this file where a model's opinion can
// enter the record.
//
// INPUT FORMAT (OURS, not a standard — see the limitations note at the bottom).
// JSONL, one entry per line:
//   {"kind":"command","command":"<cmd>","exit":<int>,"output":"<captured>",
//    "scope":["<path-or-symbol>", ...]}
//   {"kind":"note","text":"<anything>"}        <- speculation: IGNORED, always
// An entry without both a `command` and a numeric `exit` did not demonstrably
// run, so it cannot be evidence of anything.
//
// OUTPUT: SEAM 4 fact objects, one JSON per line.
//   { fact_id, task_id, attempted, failed_because, reusable_conclusion,
//     scope[], evidence_class:"observed", created_at }
//
// COMMANDS
//   compact <trace.jsonl> --task <id> [--now <iso>] [--out <facts.jsonl>]
//   match   <facts.jsonl> --scope <path|symbol>
//
// Exit codes: 0 ok (including "nothing to emit"), 2 usage error.
// Node stdlib only. No network. Deterministic: same trace + same task + same
// --now produce byte-identical output.
import { createHash } from "node:crypto";
import { readFileSync, existsSync, writeFileSync } from "node:fs";

// Used ONLY to decide whether captured output contains an error string. It is
// never used to invent a cause: it selects a line that is already there.
const ERROR_RE =
  /(^|\W)(error|exception|failed|failure|fatal|traceback|panic|assert(ion)?|cannot find|not found|no such|refused|denied|timed out)(\W|$)/i;

// A path-ish token, for the heuristic scope fallback. Heuristic is the right
// word: it is a regex over text, not a resolver.
const PATHISH_RE = /(?:^|[\s"'`(])([A-Za-z0-9_./-]+\.[A-Za-z0-9]{1,8})(?=$|[\s"'`),:])/g;

const firstLine = (s) =>
  String(s ?? "").split("\n").map((l) => l.trim()).find((l) => l.length > 0) ?? "";

const errorLineOf = (output) => {
  const lines = String(output ?? "").split("\n").map((l) => l.trim()).filter((l) => l.length > 0);
  return lines.find((l) => ERROR_RE.test(l)) ?? firstLine(output);
};

// OBSERVED means: it ran, and it reported trouble. Both halves are required.
export const isObservedFailure = (e) => {
  if (!e || typeof e !== "object") return false;
  if (typeof e.command !== "string" || e.command.trim().length === 0) return false;
  if (typeof e.exit !== "number") return false;            // never ran -> never evidence
  if (e.exit !== 0) return true;                            // a real non-zero exit
  return ERROR_RE.test(String(e.output ?? ""));             // or an error printed anyway
};

const deriveScope = (e) => {
  if (Array.isArray(e.scope) && e.scope.length > 0) return e.scope.map(String);
  const found = new Set();
  for (const text of [e.command, e.output]) {
    for (const m of String(text ?? "").matchAll(PATHISH_RE)) found.add(m[1]);
  }
  return [...found].sort();
};

export const factFrom = (e, taskId, now) => {
  const scope = deriveScope(e);
  const err = errorLineOf(e.output);
  const attempted = `ran: ${e.command}`;
  const failed_because = err
    ? `exit ${e.exit}: ${err}`
    : `exit ${e.exit}: the command failed with no error text captured`;
  // COMPOSED, not authored. Every clause below is a substring of the observed
  // record: the command, the exit status, the error line, the touched scope.
  const where = scope.length > 0 ? scope.join(", ") : "an unrecorded scope";
  const reusable_conclusion = err
    ? `\`${e.command}\` exits ${e.exit} against ${where} with: ${err} — re-running it unchanged there will not succeed until that is addressed.`
    : `\`${e.command}\` exits ${e.exit} against ${where} with no error text captured — re-running it unchanged there is unlikely to succeed.`;
  const fact_id = createHash("sha256")
    .update([taskId, e.command, String(e.exit), err, scope.join(",")].join("\u0000"))
    .digest("hex")
    .slice(0, 16);
  return {
    fact_id,
    task_id: taskId,
    attempted,
    failed_because,
    reusable_conclusion,
    scope,
    evidence_class: "observed",   // SEAM 4 permits no other value from this program
    created_at: now,
  };
};

export const compact = (traceText, taskId, now) => {
  const lines = traceText.split("\n").filter((l) => l.trim().length > 0);
  const facts = [];
  const seen = new Set();
  let parsed = 0, unparsable = 0, observed = 0;
  for (const l of lines) {
    let e = null;
    try { e = JSON.parse(l); } catch { unparsable += 1; continue; }
    parsed += 1;
    if (!isObservedFailure(e)) continue;
    observed += 1;
    const f = factFrom(e, taskId, now);
    if (seen.has(f.fact_id)) continue;   // identical evidence, one fact
    seen.add(f.fact_id);
    facts.push(f);
  }
  return { facts, entries: lines.length, parsed, unparsable, observed };
};

// Scope overlap: exact match, or one containing the other as a path prefix.
// Deliberately NOT fuzzy — a fact injected into the wrong capsule is a lie by
// misfiling, and substring matching would produce those constantly.
export const scopeOverlaps = (factScope, query) => {
  const q = String(query).replace(/\/+$/, "");
  return (factScope || []).some((raw) => {
    const s = String(raw).replace(/\/+$/, "");
    return s === q || s.startsWith(q + "/") || q.startsWith(s + "/");
  });
};

// --- CLI ---------------------------------------------------------------------
const flag = (argv, name, dflt = null) => {
  const i = argv.indexOf(`--${name}`);
  return i >= 0 && i + 1 < argv.length ? argv[i + 1] : dflt;
};

const main = (argv) => {
  const cmd = argv[0];
  const file = argv[1];

  if (cmd === "compact") {
    const taskId = flag(argv, "task");
    if (!file || !taskId) {
      process.stderr.write("usage: compact-trace.mjs compact <trace.jsonl> --task <id> [--now <iso>] [--out <f>]\n");
      return 2;
    }
    if (!existsSync(file)) { process.stderr.write(`compact-trace: no such trace: ${file}\n`); return 2; }
    const now = flag(argv, "now", new Date().toISOString());
    const r = compact(readFileSync(file, "utf8"), taskId, now);
    const body = r.facts.map((f) => JSON.stringify(f)).join("\n") + (r.facts.length ? "\n" : "");
    process.stdout.write(body);
    const out = flag(argv, "out");
    if (out) writeFileSync(out, body);
    if (r.facts.length === 0) {
      process.stderr.write(
        `NO OBSERVED FAILURE in ${r.entries} trace entr${r.entries === 1 ? "y" : "ies"}` +
        ` (${r.parsed} parsed, ${r.unparsable} unparsable): emitting NOTHING.\n` +
        "A fact requires a command that ran with a non-zero exit, or an error string in captured\n" +
        "output. Speculation is not evidence, and a fabricated fact is indistinguishable from a\n" +
        "real one once it is written — so nothing is written.\n",
      );
    } else {
      process.stderr.write(
        `compacted ${r.facts.length} fact(s) from ${r.observed} observed failure(s) in ${r.entries} entries.\n`,
      );
    }
    return 0;
  }

  if (cmd === "match") {
    const scope = flag(argv, "scope");
    if (!file || !scope) {
      process.stderr.write("usage: compact-trace.mjs match <facts.jsonl> --scope <path|symbol>\n");
      return 2;
    }
    if (!existsSync(file)) { process.stderr.write(`compact-trace: no such facts file: ${file}\n`); return 2; }
    const hits = readFileSync(file, "utf8").split("\n")
      .filter((l) => l.trim().length > 0)
      .map((l) => { try { return JSON.parse(l); } catch { return null; } })
      .filter((f) => f && scopeOverlaps(f.scope, scope));
    if (hits.length) process.stdout.write(hits.map((f) => JSON.stringify(f)).join("\n") + "\n");
    process.stderr.write(`${hits.length} fact(s) overlap scope ${scope}\n`);
    return 0;
  }

  process.stderr.write("usage: compact-trace.mjs <compact <trace.jsonl> --task <id> | match <facts.jsonl> --scope <s>>\n");
  return 2;
};

if (import.meta.url === `file://${process.argv[1]}`) process.exit(main(process.argv.slice(2)));
