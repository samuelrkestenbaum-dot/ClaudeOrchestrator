// EXP-0008 — measure how much GRAVITO IMPLEMENTATION the worker reads.
//
// WHY THE CLASSIFIER IS SHAPED THIS WAY, stated before the number it produces.
//
// The previous attempt at this measurement classified by RESULT CONTENT: a regex
// looking for gate-shaped text in tool_result bodies. It matched
// routing-gate.sh's own header comments whenever the worker READ the file, so
// "gate refusal volume" silently included 47,787 characters of shell source and
// came out at 23.8% of all tool-result volume. The true figure was 2.6%. The
// flaw was noticed early, and the number was quoted for several more turns
// anyway.
//
// THE STRUCTURAL FIX: classify by the tool_use's REQUESTED PATH, never by what
// came back. A path-based classifier cannot match its own source text, because
// it never looks at text. This is not a better regex; it is a category of
// mistake removed.
//
// Everything here is derived from stored streams. No arm is re-run.

import fs from "node:fs";
import path from "node:path";

/** Paths that ARE the substrate's implementation. Enumerated, with reasons. */
export const IMPLEMENTATION_PREFIXES = [
  { prefix: "build-os/", why: "the substrate's own code, memory, packets and tooling" },
  { prefix: ".claude/", why: "hooks, agents, commands and settings — the runtime that enforces routing" },
];
export const IMPLEMENTATION_FILES = [
  { file: "CLAUDE.md", why: "the doctrine document itself" },
];

/**
 * Classify a READ by the path it asked for.
 *
 * Returns "implementation" | "product" | null (not a read at all).
 * `content` is deliberately NOT a parameter — it cannot influence the verdict,
 * which is the property that makes this classifier immune to the failure that
 * produced the withdrawn figure.
 */
export function classifyRead(toolName, requestedPath) {
  if (toolName !== "Read") return null;
  if (typeof requestedPath !== "string" || !requestedPath) return null;
  const rel = requestedPath.replace(/^.*?(?:exp000\d-arm|empathiq-website|ClaudeOrchestrator)\//, "");
  if (IMPLEMENTATION_FILES.some((f) => rel === f.file)) return "implementation";
  if (IMPLEMENTATION_PREFIXES.some((p) => rel.startsWith(p.prefix))) return "implementation";
  return "product";
}

/** Walk one stream, pairing every tool_result with the tool_use that caused it. */
export function measureStream(streamPath) {
  let ev = [];
  try {
    ev = fs.readFileSync(streamPath, "utf8").split("\n").filter(Boolean)
      .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
  } catch { return null; }

  const use = {};
  for (const e of ev) for (const c of (e?.message?.content || [])) {
    if (c.type === "tool_use") use[c.id] = { name: c.name, path: c.input?.file_path ?? null };
  }

  const out = { implementation_chars: 0, product_chars: 0, other_chars: 0,
                implementation_reads: [], product_read_count: 0, total_tool_result_chars: 0 };
  for (const e of ev) for (const c of (e?.message?.content || [])) {
    if (c.type !== "tool_result") continue;
    const body = typeof c.content === "string" ? c.content : JSON.stringify(c.content || "");
    out.total_tool_result_chars += body.length;
    const u = use[c.tool_use_id];
    const kind = u ? classifyRead(u.name, u.path) : null;
    if (kind === "implementation") {
      out.implementation_chars += body.length;
      out.implementation_reads.push({ path: u.path.replace(/^.*?(?:exp000\d-arm|empathiq-website)\//, ""), chars: body.length });
    } else if (kind === "product") { out.product_chars += body.length; out.product_read_count++; }
    else out.other_chars += body.length;
  }
  return out;
}

/** Aggregate a set of run directories. */
export function measureRuns(runsDir, filter = () => true) {
  const agg = { arms: 0, implementation_chars: 0, product_chars: 0, other_chars: 0,
                total_tool_result_chars: 0, implementation_reads: 0, byFile: {} };
  if (!fs.existsSync(runsDir)) return agg;
  for (const d of fs.readdirSync(runsDir).sort()) {
    if (!filter(d)) continue;
    const m = measureStream(path.join(runsDir, d, "stream.jsonl"));
    if (!m) continue;
    agg.arms++;
    agg.implementation_chars += m.implementation_chars;
    agg.product_chars += m.product_chars;
    agg.other_chars += m.other_chars;
    agg.total_tool_result_chars += m.total_tool_result_chars;
    agg.implementation_reads += m.implementation_reads.length;
    for (const r of m.implementation_reads) agg.byFile[r.path] = (agg.byFile[r.path] || 0) + r.chars;
  }
  return agg;
}
