#!/usr/bin/env node
// STRICT view leak check (AMENDMENT v3 — hardens the v1 viewLeakCheck).
//
// Audit findings this answers: (1) a worker DIFF shown to the blinded
// adjudicator can smuggle arm identity through artifact names the v1 regex
// never covered — SKILL.md, .claude/skills/, task-log.md, repair-* skill
// names; (2) renderer overhead differs by arm, so BYTE SIZES in an
// adjudicator view are an arm side channel; (3) session/model identifiers
// tie units to execution order. This wrapper runs the frozen v1 check first
// (unchanged), then refuses on the extended channels. Classification stays
// honest: separation is PROCEDURAL (one OS identity, one filesystem), not
// structural — enforced by generation + this mechanical check, not by an
// isolation boundary.
import { viewLeakCheck } from "./views.mjs";

const ARM_ARTIFACTS = /SKILL\.md|\.claude\/skills|task-log\.md|repair-s[0-9]|lean_rules|lean_skills|renderer/i;
const SIZE_CHANNEL = /bytes|payload|overhead|installed|tokens|usd|cost|elapsed/i;
const EXEC_IDENTITY = /session[-_ ]?id|claude-opus|model_flag|argv/i;

export function strictLeakCheck(views) {
  const base = viewLeakCheck(views);
  if (!base.ok) return base;
  const aTxt = JSON.stringify(views.adjudicator), nTxt = JSON.stringify(views.analyst);
  if (ARM_ARTIFACTS.test(aTxt)) return { ok: false, reason: "adjudicator view leaks arm artifacts (skill/rules surfaces)" };
  if (SIZE_CHANNEL.test(aTxt)) return { ok: false, reason: "adjudicator view leaks a size/economics side channel" };
  if (EXEC_IDENTITY.test(aTxt)) return { ok: false, reason: "adjudicator view leaks execution identity" };
  if (ARM_ARTIFACTS.test(nTxt)) return { ok: false, reason: "analyst view leaks arm artifacts" };
  if (EXEC_IDENTITY.test(nTxt)) return { ok: false, reason: "analyst view leaks execution identity" };
  return { ok: true, classification: "PROCEDURAL separation (one OS identity) — mechanical checks, not an isolation boundary" };
}
