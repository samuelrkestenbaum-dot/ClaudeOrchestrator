// UCDL — Unified Context Delivery Layer (Phase 1: standalone library).
//
// WHY THIS EXISTS (evidence, not aspiration): EXP-0011's live LeanRules arm
// delivered 0 bytes in 10/12 cells. Postmortem replay against the sealed
// stores proved the cause was NOT matching and NOT the cap asymmetry story:
// matching worked (matched=3..5), but 8 of 12 distilled rules individually
// exceed the 1536B delivery budget, so the (correctly) skip-not-block
// selector skipped every match — and the harness gate passed on 0 bytes,
// misdescribed it as "position 1", and dropped skipped_oversize from the
// economics record. The unit size and the budget were never designed
// against each other, and empty delivery was silent.
//
// UCDL's contract, each clause traceable to that failure:
//   1. UNITS ARE ATOMIC BELOW THE BUDGET FLOOR: every unit splits into an
//      INSIGHT atom (small by construction) and optional EXHIBIT atoms
//      (diff hunks etc.). A budget that can hold one insight can never be
//      starved by oversize exhibits.
//   2. ONE retrieval/scoring path for every consumer; renderers (context
//      block, SKILL.md, ...) receive a RESOLVED selection and may not
//      re-select — selection policy and rendering vary independently.
//   3. BUDGET POLICY IS AN EXPLICIT, VERSIONED OBJECT — deterministic
//      given its declared inputs, recorded verbatim in the receipt. No
//      hidden runtime adaptivity: adaptivity here would be a confound
//      generator for the experiments this layer serves.
//   4. COMPLETE RECEIPTS: every candidate appears with a decision and a
//      reason; bytes, est tokens, truncation, provenance, and logical
//      freshness are recorded. Absence of evidence is never silent.
//   5. UNINTENDED EMPTY DELIVERY IS INVALID BEFORE SPEND: deliver() with
//      an empty selection returns invalid_empty=true unless the caller
//      passed an explicit no_context decision with a recorded reason.
//   6. RAW EVIDENCE IS NEVER REWRITTEN: parsers read stores; nothing here
//      mutates a store, and receipts derive from inputs only (no wall
//      clock in the receipt — byte-identical reruns are the determinism
//      proof).
//
// Freshness is LOGICAL (sequence/rep/position) because that is what the
// sealed stores actually carry; wall-time freshness is an optional field
// for future unit authors, never inferred retroactively.

import crypto from "node:crypto";

export const UCDL_VERSION = "1.0.0";

const bytes = (s) => Buffer.byteLength(s, "utf8");
const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");

// ---------------------------------------------------------------- units ----

/**
 * Adapter: parse an EXP-0010/0011 `## RULE` store into atomic units.
 * Read-only; tolerant of the sealed formats. The insight atom is the rule
 * minus its fenced exhibit blocks; each fenced block becomes an exhibit atom.
 */
export function parseRuleStore(storeText) {
  const blocks = storeText.split(/^(?=## RULE )/m).filter((b) => b.startsWith("## RULE "));
  return blocks.map((b, i) => {
    const title = b.split("\n")[0].replace(/^## /, "").trim();
    const applicability = (b.match(/- applicability: ([^\n]*)/) || [, ""])[1];
    const codes = [...new Set([...(title + " " + applicability).matchAll(/TS\d+/g)].map((m) => m[0]))];
    const provM = b.match(/- provenance: sequence=(\S+) rep=(\S+) position=(\d+) run=(\S+)(?: authored_by=(\S+))?/);
    const provenance = provM
      ? { sequence: provM[1], rep: Number(provM[2]), position: Number(provM[3]), run: provM[4], author: provM[5] || "unknown" }
      : null;
    const exhibits = [];
    const insightText = b.replace(/```[a-z]*\n[\s\S]*?```\n?/g, (m) => {
      exhibits.push(m.trimEnd());
      return "(exhibit: see delivered diff below if budget allowed)\n";
    }).trimEnd() + "\n";
    return {
      id: `rule-${i + 1}-${sha(b).slice(0, 8)}`,
      kind: "rule",
      title,
      codes,
      provenance,
      raw_bytes: bytes(b),
      atoms: [
        { part: "insight", text: insightText, bytes: bytes(insightText) },
        ...exhibits.map((e, j) => ({ part: `exhibit-${j + 1}`, text: e + "\n", bytes: bytes(e) + 1 })),
      ],
    };
  });
}

// -------------------------------------------------------------- scoring ----

/**
 * The ONE scoring path. Matching consults title AND applicability codes.
 * score = 10 * |code overlap| + logical recency (position). Deterministic.
 */
export function scoreUnits(units, query) {
  const qCodes = new Set(query.codes || []);
  return units.map((u) => {
    const overlap = u.codes.filter((c) => qCodes.has(c));
    const matched = overlap.length > 0;
    const recency = u.provenance ? u.provenance.position : 0;
    return {
      unit: u,
      matched,
      score: matched ? overlap.length * 10 + recency : 0,
      reasons: matched ? [`codes ${overlap.join("+")} overlap query`] : ["no code overlap with query"],
    };
  });
}

// --------------------------------------------------------------- budget ----

/** Named, explicit, versioned budget policies. Extend by adding, not editing. */
export const POLICIES = {
  // Insights first (newest-scored first); exhibits only into remaining room.
  // With >=1 match and cap >= smallest matched insight, delivery CANNOT be
  // empty — the structural fix for the EXP-0011 starvation class.
  "insight-first@1": { name: "insight-first@1", order: "score", granularity: "atom", exhibits: "if-room" },
  // Whole units or nothing (the legacy shape, kept for controlled comparison).
  "whole-unit@1": { name: "whole-unit@1", order: "score", granularity: "unit", exhibits: "with-unit" },
};

export function applyBudget(candidates, policyName, capBytes) {
  const policy = POLICIES[policyName];
  if (!policy) throw new Error(`unknown budget policy: ${policyName} — policies are explicit, never guessed`);
  const matched = candidates.filter((c) => c.matched).sort((a, b) => b.score - a.score);
  const rejectedNoMatch = candidates.filter((c) => !c.matched)
    .map((c) => ({ id: c.unit.id, decision: "rejected", reason: "no_match" }));
  const selected = [], rejected = [...rejectedNoMatch];
  let used = 0, truncated = false;

  if (policy.granularity === "unit") {
    for (const c of matched) {
      const total = c.unit.atoms.reduce((s, a) => s + a.bytes, 0);
      if (used + total > capBytes) { rejected.push({ id: c.unit.id, decision: "rejected", reason: "unit_oversize_for_remaining_budget", unit_bytes: total }); truncated = true; continue; }
      selected.push({ id: c.unit.id, parts: c.unit.atoms.map((a) => a.part), bytes: total, score: c.score });
      used += total;
    }
  } else {
    // pass 1: insights
    for (const c of matched) {
      const ins = c.unit.atoms.find((a) => a.part === "insight");
      if (used + ins.bytes > capBytes) { rejected.push({ id: c.unit.id, decision: "rejected", reason: "insight_over_remaining_budget", insight_bytes: ins.bytes }); truncated = true; continue; }
      selected.push({ id: c.unit.id, parts: ["insight"], bytes: ins.bytes, score: c.score });
      used += ins.bytes;
    }
    // pass 2: exhibits into remaining room, same order
    if (policy.exhibits === "if-room") {
      for (const c of matched) {
        const sel = selected.find((s) => s.id === c.unit.id);
        if (!sel) continue;
        for (const a of c.unit.atoms.filter((a) => a.part.startsWith("exhibit"))) {
          if (used + a.bytes > capBytes) { truncated = true; continue; }
          sel.parts.push(a.part); sel.bytes += a.bytes; used += a.bytes;
        }
      }
    }
  }
  return { policy: { ...policy, cap_bytes: capBytes }, selected, rejected, delivered_bytes: used, truncated };
}

// ------------------------------------------------------------- renderers ----

/** Renderers receive a RESOLVED selection; they may not re-select. */
function resolvedText(units, selected) {
  const byId = Object.fromEntries(units.map((u) => [u.id, u]));
  return selected.map((s) => {
    const u = byId[s.id];
    return u.atoms.filter((a) => s.parts.includes(a.part)).map((a) => a.text).join("\n");
  }).join("\n");
}

export function renderContext(units, selection) {
  const body = resolvedText(units, selection.selected);
  return body ? `# Organizational memory — verified units (delivered by UCDL ${UCDL_VERSION})\n\n${body}` : "";
}

export function renderSkillMd(units, selection, meta = {}) {
  const body = resolvedText(units, selection.selected);
  if (!body) return "";
  const name = meta.name || "delivered-knowledge";
  return [
    "---",
    `name: ${name}`,
    `description: ${meta.description || `Verified knowledge units delivered by UCDL ${UCDL_VERSION}. Invoke when the matched task class applies.`}`,
    "---",
    "",
    body,
  ].join("\n");
}

export const RENDERERS = { context: renderContext, skill: renderSkillMd };

// -------------------------------------------------------------- deliver ----

/**
 * The single entry point. Returns { ok, invalid_empty, output, receipt }.
 * Empty selection without an explicit no_context decision => invalid BEFORE
 * any model spend: ok=false, invalid_empty=true, output="".
 */
export function deliver({ storeText, units, query, policyName = "insight-first@1", capBytes, renderer = "context", rendererMeta = {}, no_context = null }) {
  const us = units || (storeText ? parseRuleStore(storeText) : []);
  const candidates = scoreUnits(us, query);
  const selection = applyBudget(candidates, policyName, capBytes);
  const render = RENDERERS[renderer];
  if (!render) throw new Error(`unknown renderer: ${renderer}`);
  const output = render(us, selection, rendererMeta);
  const empty = selection.selected.length === 0 || output === "";
  const noCtx = no_context && no_context.reason ? { allowed: true, reason: String(no_context.reason) } : null;
  const receipt = {
    ucdl_version: UCDL_VERSION,
    query,
    policy: selection.policy,
    renderer,
    candidates: us.length,
    considered: candidates.map((c) => {
      const sel = selection.selected.find((s) => s.id === c.unit.id);
      const rej = selection.rejected.find((r) => r.id === c.unit.id);
      return {
        id: c.unit.id, title: c.unit.title, score: c.score, matched: c.matched,
        decision: sel ? "selected" : "rejected",
        reason: sel ? c.reasons.join("; ") : (rej ? rej.reason : "unknown"),
        parts: sel ? sel.parts : [],
        bytes: sel ? sel.bytes : 0,
        provenance: c.unit.provenance,
      };
    }),
    selected_ids: selection.selected.map((s) => s.id),
    delivered_bytes: selection.delivered_bytes,
    est_tokens: Math.ceil(selection.delivered_bytes / 4),
    truncated: selection.truncated,
    freshness: "logical(sequence,rep,position) — wall-time absent from source stores, never inferred",
    access_observability: "delivery-side only; worker reads/invocations are observed by the harness stream parser, not here",
    empty,
    no_context: noCtx,
    output_sha256: sha(output),
  };
  if (empty && !noCtx) return { ok: false, invalid_empty: true, output: "", receipt };
  return { ok: true, invalid_empty: false, output, receipt };
}
