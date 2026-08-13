#!/usr/bin/env node
// Deterministic SEED DISTILLATION (AMENDMENT v3 — closes the audit finding
// that "the real store is distilled from p1 at spend time" had no committed
// implementation: the mechanism a paid run depends on must exist and be
// frozen BEFORE spend).
//
// Contract: MECHANICAL and renderer-independent. Input is the seed cell's
// oracle acceptance record and its diff; output is a `## RULE` store in the
// exact format UCDL's parseRuleStore() consumes (insight atom per error
// code + one fenced exhibit of the diff file-stat). Same input bytes =>
// same output bytes (no clock, no randomness). The distiller never reads
// provider transcripts, never sees renderer/arm identity (seeds have none),
// and never rewrites raw evidence. Store quality is NOT the experimental
// variable — both arms receive whatever this produces, identically.
//
// Frozen seed-failure policy (v3): a seed whose distillation refuses gets
// ONE seed rerun; a second refusal is SEQUENCE_VOID and the study aborts
// before any measured spend in that sequence.
import crypto from "node:crypto";
const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");

export function distill({ task, acceptance, diffText }) {
  if (!task?.task_id || !Array.isArray(task.codes) || task.codes.length === 0)
    return { ok: false, reason: "SEED_MALFORMED_TASK" };
  if (!acceptance || typeof acceptance.accepted !== "boolean" || acceptance.target_errors_before == null)
    return { ok: false, reason: "SEED_MALFORMED_ACCEPTANCE" };
  if (acceptance.accepted !== true) return { ok: false, reason: "SEED_UNACCEPTED" };
  if (!diffText || !diffText.trim()) return { ok: false, reason: "SEED_EMPTY_DIFF" };
  const files = [...new Set([...diffText.matchAll(/^diff --git a\/(\S+) b\/\S+$/gm)].map((m) => m[1]))];
  if (files.length === 0) return { ok: false, reason: "SEED_MALFORMED_DIFF" };
  const adds = (diffText.match(/^\+[^+]/gm) || []).length;
  const dels = (diffText.match(/^-[^-]/gm) || []).length;
  const codes = [...new Set(task.codes)].sort();
  const diffSha = sha(diffText).slice(0, 12);
  const rules = codes.map((code) => [
    `## RULE ${code} — verified repair in server/${task.subsystem}/ (seed ${task.task_id})`,
    `- applicability: files where tsc reports any of: ${code} (subsystem server/${task.subsystem}/)`,
    `- verified outcome: ${task.file} cleared ${acceptance.target_errors_before} error(s) to 0 with zero new error identities anywhere`,
    `- fix shape: ${files.length} file(s) changed (+${adds}/-${dels} lines): ${files.join(", ")}`,
    `- provenance: sequence=${task.sequence} rep=1 position=1 run=seed authored_by=distill-v3 diff_sha=${diffSha}`,
    "```",
    `seed-diff-stat ${task.task_id}: files=${files.join(",")} +${adds} -${dels} accepted=true`,
    "```",
    "",
  ].join("\n"));
  const storeText = `# repair-rules — sequence ${task.sequence} (distilled mechanically from the accepted seed; renderer-independent)\n\n${rules.join("\n")}`;
  return { ok: true, storeText, store_digest: sha(storeText) };
}
