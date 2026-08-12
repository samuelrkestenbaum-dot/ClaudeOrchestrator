// EXP-0010 — the MECHANICAL rule distiller.
//
// A rule is not a report. It is: an error-class identity, an applicability
// condition, derived confidence facts, and the canonical idiom AS DEMONSTRATED
// — up to two diff hunks lifted verbatim from the arm's own accepted fix.
// Every field is template-filled or extracted; no experimenter prose exists
// anywhere in the pipeline, because an experimenter-authored rule would test
// the experimenter, not the substrate.
//
// Selection is the second half of the redesign: install ONLY rules whose
// error code matches the current task, newest first, hard cap 1536 bytes.
// The cap keeps delivery inside the hook's inline path always — the pointer
// mode that went 0/4 consulted in EXP-0009 is unreachable by construction.

import fs from "node:fs";
import path from "node:path";

const CAP_BYTES = 1536;

/** Up to `max` hunks from full.diff that touch `taskFile`, each ≤30 lines. */
function hunksFor(diffText, taskFile, max = 2) {
  const out = [];
  const files = diffText.split(/^diff --git /m);
  for (const f of files) {
    if (!f.includes(`b/${taskFile}`)) continue;
    const hunks = f.split(/^(?=@@ )/m).filter((h) => h.startsWith("@@ "));
    for (const h of hunks.slice(0, max)) out.push(h.trim().split("\n").slice(0, 30).join("\n"));
    break;
  }
  return out.slice(0, max);
}

export function distillRule(runDir, task, rep) {
  const j = (f) => { try { return JSON.parse(fs.readFileSync(path.join(runDir, f), "utf8")); } catch { return null; } };
  const acc = j("acceptance.json");
  let diff = ""; try { diff = fs.readFileSync(path.join(runDir, "full.diff"), "utf8"); } catch {}
  const hunks = hunksFor(diff, task.file);
  return [
    `## RULE ${task.cluster.code} — ${task.cluster.msg}`,
    `- applicability: files where tsc reports \`${task.cluster.code}: ${task.cluster.msg}\``,
    `- confidence: fix of ${task.task_id} (${task.error_count} occurrence(s)) ${acc?.accepted ? "ACCEPTED — zero errors remained in the task file, no new errors elsewhere" : "NOT accepted"}`,
    `- procedure: when \`${task.cluster.code}: ${task.cluster.msg}\` fires, apply the demonstrated transform:`,
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

/** Same isolation gate as EXP-0009: same-sequence, same-rep, earlier-position. */
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

/**
 * SELECTION — the smallest relevant subset. Only rules matching the task's
 * error codes, newest first, hard-capped. Returns the exact bytes to install
 * (empty string = install nothing) plus the derived facts for variant.json.
 */
export function selectRules(storeFile, taskCodes) {
  if (!fs.existsSync(storeFile)) return { text: "", matched: 0, bytes: 0, capped: false };
  const txt = fs.readFileSync(storeFile, "utf8");
  const rules = txt.split(/^(?=## RULE )/m).filter((r) => r.startsWith("## RULE "));
  const matched = rules.filter((r) => taskCodes.some((c) => r.startsWith(`## RULE ${c} `) || r.startsWith(`## RULE ${c}—`) || r.includes(`## RULE ${c} —`)));
  let out = "", capped = false;
  for (const r of matched.slice().reverse()) { // newest first
    if (Buffer.byteLength(out + r, "utf8") > CAP_BYTES) { capped = true; break; }
    out += r;
  }
  return { text: out, matched: matched.length, bytes: Buffer.byteLength(out, "utf8"), capped };
}
