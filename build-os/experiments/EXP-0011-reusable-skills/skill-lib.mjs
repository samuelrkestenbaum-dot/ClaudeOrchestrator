// EXP-0011 — distillation, selection, and skill compilation. Mechanical end to
// end; no experimenter prose. EXP-0010's frozen module is deliberately NOT
// imported: its selector carries the break-at-cap defect that blocked 3/20
// deliveries, preserved there because it produced the measured result. The
// fixed selector lives here, with a regression test.

import fs from "node:fs";
import path from "node:path";

export const CAP_BYTES = 1536;      // leanrules context delivery (as EXP-0010)
export const SKILL_CAP_BYTES = 6144; // SKILL.md body — progressive disclosure means
                                     // only the description rides every prompt

function hunksFor(diffText, taskFile, max = 2) {
  const out = [];
  for (const f of diffText.split(/^diff --git /m)) {
    if (!f.includes(`b/${taskFile}`)) continue;
    const hunks = f.split(/^(?=@@ )/m).filter((h) => h.startsWith("@@ "));
    for (const h of hunks.slice(0, max)) out.push(h.trim().split("\n").slice(0, 30).join("\n"));
    break;
  }
  return out.slice(0, max);
}

/** Compressed tool-call sequence from a stored stream: consecutive dupes folded. */
export function toolSequenceOf(runDir) {
  let ev = [];
  try { ev = fs.readFileSync(path.join(runDir, "stream.jsonl"), "utf8").split("\n").filter(Boolean)
    .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean); } catch { return []; }
  const names = ev.flatMap((e) => (e?.message?.content || []).filter((c) => c?.type === "tool_use").map((c) => c.name));
  const out = [];
  for (const n of names) if (out[out.length - 1] !== n) out.push(n);
  return out;
}

export function distillRule(runDir, task, rep) {
  const j = (f) => { try { return JSON.parse(fs.readFileSync(path.join(runDir, f), "utf8")); } catch { return null; } };
  const acc = j("acceptance.json");
  let diff = ""; try { diff = fs.readFileSync(path.join(runDir, "full.diff"), "utf8"); } catch {}
  const hunks = hunksFor(diff, task.file);
  return [
    `## RULE ${task.cluster.code} — ${task.cluster.msg}`,
    `- applicability: files where tsc reports any of: ${task.codes.join(", ")} (subsystem server/${task.subsystem}/)`,
    `- confidence: fix of ${task.task_id} (${task.error_count} occurrence(s)) ${acc?.accepted ? "ACCEPTED — zero errors remained in the task file, no new errors elsewhere" : "NOT accepted"}`,
    `- toolseq: ${toolSequenceOf(runDir).join(">") || "(none)"}`,
    `- procedure: when these codes fire, apply the demonstrated transform:`,
    "```diff",
    hunks.length ? hunks.join("\n") : "(no hunk captured)",
    "```",
    `- provenance: sequence=${task.sequence} rep=${rep} position=${task.position} run=${path.basename(runDir)} authored_by=harness-rule-distiller`,
    ``,
  ].join("\n");
}

export function appendToStore(storeFile, entry) {
  fs.mkdirSync(path.dirname(storeFile), { recursive: true });
  fs.appendFileSync(storeFile, entry + "\n");
}

export function verifyStoreProvenance(storeFile, sequence, rep, position) {
  if (!fs.existsSync(storeFile)) return { ok: true, entries: 0, detail: "no store yet (position 1, or a fresh rep) — nothing to verify" };
  const txt = fs.readFileSync(storeFile, "utf8");
  const provs = [...txt.matchAll(/- provenance: sequence=(\S+) rep=(\S+) position=(\d+)/g)]
    .map((m) => ({ sequence: m[1], rep: Number(m[2]), position: Number(m[3]) }));
  const entries = (txt.match(/^## RULE /gm) || []).length;
  if (provs.length !== entries) return { ok: false, entries, detail: `${entries} rules but ${provs.length} provenance lines — an unattributed rule is a leak` };
  const bad = provs.filter((p) => p.sequence !== sequence || p.rep !== rep || !(p.position < position));
  return bad.length
    ? { ok: false, entries, detail: `LEAKAGE: ${bad.length} rule(s) from outside seq=${sequence}/rep=${rep}/pos<${position}: ${JSON.stringify(bad[0])}` }
    : { ok: true, entries, detail: `${entries} rule(s), all same-sequence same-rep earlier-position` };
}

export function splitRules(storeText) {
  return storeText.split(/^(?=## RULE )/m).filter((r) => r.startsWith("## RULE "));
}

/**
 * FIXED selector (EXP-0010 defect corrected): an oversized rule is SKIPPED
 * (continue), never allowed to block smaller eligible rules behind it. Order
 * remains newest first. Skips are reported, never silent.
 */
export function selectRules(storeFile, taskCodes, cap = CAP_BYTES) {
  if (!fs.existsSync(storeFile)) return { text: "", matched: 0, bytes: 0, skipped_oversize: 0 };
  const rules = splitRules(fs.readFileSync(storeFile, "utf8"));
  const matched = rules.filter((r) => {
    const head = r.split("\n")[0];
    return taskCodes.some((c) => head.includes(c));
  });
  let out = "", skipped = 0;
  for (const r of matched.slice().reverse()) {
    if (Buffer.byteLength(out + r, "utf8") > cap) { skipped++; continue; }
    out += r;
  }
  return { text: out, matched: matched.length, bytes: Buffer.byteLength(out, "utf8"), skipped_oversize: skipped };
}

/**
 * SKILL COMPILATION — a reusable capability on the platform's native skill
 * surface, compiled from the sequence's OWN prior arms: frontmatter
 * (template-filled), the demonstrated tool sequence (the mode across accepted
 * arms' toolseq lines), and the matched rules. No experimenter prose.
 */
export function compileSkill(storeFile, task, cap = SKILL_CAP_BYTES) {
  if (!fs.existsSync(storeFile)) return { text: "", rules: 0, bytes: 0 };
  const all = splitRules(fs.readFileSync(storeFile, "utf8"));
  if (!all.length) return { text: "", rules: 0, bytes: 0 };
  const seqs = all.map((r) => (r.match(/- toolseq: (.+)/) || [])[1]).filter(Boolean).filter((s) => s !== "(none)");
  const mode = (() => {
    const c = {}; for (const s of seqs) c[s] = (c[s] || 0) + 1;
    return Object.entries(c).sort((a, b) => b[1] - a[1])[0]?.[0] || null;
  })();
  let rulesText = "", included = 0;
  for (const r of all.slice().reverse()) {
    const head = "### " + r.slice(3); // demote rule headings under the skill doc
    if (Buffer.byteLength(rulesText + head, "utf8") > cap) continue;
    rulesText += head; included++;
  }
  const acceptedN = all.filter((r) => r.includes("ACCEPTED")).length;
  const text = [
    "---",
    `name: repair-${task.subsystem}`,
    `description: Repair TypeScript errors in server/${task.subsystem}/ using verified idioms from ${acceptedN} prior accepted fix(es) in this subsystem. Invoke when fixing tsc errors there.`,
    "---",
    "",
    `# Verified repair knowledge for server/${task.subsystem}/`,
    "",
    `Compiled mechanically from ${all.length} prior task(s) in this subsystem (${acceptedN} accepted).`,
    mode ? `\nDemonstrated tool sequence of accepted fixes: ${mode.split(">").join(" → ")}` : "",
    "",
    "## Rules (newest first)",
    "",
    rulesText,
  ].join("\n");
  return { text, rules: included, bytes: Buffer.byteLength(text, "utf8") };
}
