// EXP-0009 — the MECHANICAL distiller.
//
// One memory entry per admissible lean-mem arm, template-filled from STORED
// ARTIFACTS only. The one free-text field is a truncated excerpt of the
// WORKER'S OWN final report (first 900 chars, mechanical cut) — never a word
// of experimenter authorship, because an experimenter-written memory would
// test the experimenter, not the substrate.
//
// Every entry carries provenance (sequence, rep, position, run dir). The
// fairness preflight refuses any store whose entries name a different
// sequence/rep or a position not strictly earlier than the current arm.

import fs from "node:fs";
import path from "node:path";

export function distillEntry(runDir, task, rep) {
  const j = (f) => { try { return JSON.parse(fs.readFileSync(path.join(runDir, f), "utf8")); } catch { return null; } };
  const acc = j("acceptance.json");
  let finalReport = "";
  try {
    const ev = fs.readFileSync(path.join(runDir, "stream.jsonl"), "utf8").split("\n").filter(Boolean)
      .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
    for (let i = ev.length - 1; i >= 0; i--) {
      const c = ev[i]?.message?.content;
      if (ev[i]?.message?.role !== "assistant" || !Array.isArray(c) || c.some((x) => x.type === "tool_use")) continue;
      const t = c.filter((x) => x.type === "text").map((x) => x.text).join("\n").trim();
      if (t.length >= 200) { finalReport = t; break; }
      if (!finalReport) finalReport = t;
    }
  } catch {}
  return [
    `## ${task.task_id} — ${task.file}`,
    `- pattern: ${task.cluster.code} ${task.cluster.msg} (${task.error_count} occurrences in this file)`,
    `- verification: ${acc ? (acc.accepted ? "accepted — zero errors remained in the task file, no new errors elsewhere" : "NOT accepted") : "unrecorded"}`,
    `- provenance: sequence=${task.sequence} rep=${rep} position=${task.position} run=${path.basename(runDir)} authored_by=harness-distiller`,
    ``,
    `Worker's own report (mechanical 900-char cut):`,
    finalReport.slice(0, 900).trim() || "(no final report captured)",
    ``,
  ].join("\n");
}

/** Append an entry to the per-sequence-per-rep store. Isolation is by PATH. */
export function appendToStore(storeFile, entry) {
  fs.mkdirSync(path.dirname(storeFile), { recursive: true });
  fs.appendFileSync(storeFile, entry + "\n");
}

/** Preflight: every entry's provenance must be same-sequence, same-rep, earlier-position. */
export function verifyStoreProvenance(storeFile, sequence, rep, position) {
  if (!fs.existsSync(storeFile)) return { ok: true, entries: 0, detail: "no store yet (position 1, or a fresh rep) — nothing to verify" };
  const txt = fs.readFileSync(storeFile, "utf8");
  const provs = [...txt.matchAll(/- provenance: sequence=(\S+) rep=(\S+) position=(\d+)/g)]
    .map((m) => ({ sequence: m[1], rep: Number(m[2]), position: Number(m[3]) }));
  const entries = (txt.match(/^## /gm) || []).length;
  if (provs.length !== entries) return { ok: false, entries, detail: `${entries} entries but ${provs.length} provenance lines — an unattributed entry is a leak` };
  const bad = provs.filter((p) => p.sequence !== sequence || p.rep !== rep || !(p.position < position));
  return bad.length
    ? { ok: false, entries, detail: `LEAKAGE: ${bad.length} entr(ies) from outside seq=${sequence}/rep=${rep}/pos<${position}: ${JSON.stringify(bad[0])}` }
    : { ok: true, entries, detail: `${entries} entr(ies), all same-sequence same-rep earlier-position` };
}
