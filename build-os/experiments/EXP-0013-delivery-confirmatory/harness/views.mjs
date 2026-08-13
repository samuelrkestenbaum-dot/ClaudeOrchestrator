#!/usr/bin/env node
// EXP-0013 role-separated views — corrects the prior weakness where one
// analyst could hold both execution identity and adjudication material.
//
//   execution controller : arm identity, no comparative analysis surface
//   blinded adjudicator  : opaque unit ids, objective, acceptance criteria,
//                          diffs, mechanical evidence — NO arm labels, NO economics
//   comparative analyst  : outcomes + economics keyed by opaque unit ids —
//                          NO mapping to arms until the one-way reveal
// The mapping (unit id -> arm) lives ONLY in a sealed file whose salt stays
// out of the repository (existing program convention). The views share the
// opaque unit id as their only common key, which is join-useless without
// the sealed mapping.

import crypto from "node:crypto";
const sha = (s) => crypto.createHash("sha256").update(s).digest("hex");

export function buildViews(cells, salt) {
  // cells: [{seq,pos,arm,objective,acceptance,diff,economics,outcome}]
  const sealedMapping = [], adjudicator = [], analyst = [];
  for (const c of cells) {
    const unit = "U" + sha(`${salt}|${c.seq}|${c.pos}|${c.arm}`).slice(0, 10);
    sealedMapping.push({ unit, seq: c.seq, pos: c.pos, arm: c.arm });
    adjudicator.push({ unit, objective: c.objective, acceptance_criteria: c.acceptance, diff: c.diff });
    analyst.push({ unit, outcome: c.outcome, economics: c.economics });
  }
  return { sealedMapping, adjudicator, analyst };
}

export function viewLeakCheck(views) {
  const forbidden = /lean_rules|lean_skills|"arm"|"seq"|"pos"|renderer/;
  const adjEcon = /tokens|usd|cost|elapsed/i;
  const aTxt = JSON.stringify(views.adjudicator), nTxt = JSON.stringify(views.analyst);
  if (forbidden.test(aTxt)) return { ok: false, reason: "adjudicator view leaks arm/cell identity" };
  if (adjEcon.test(aTxt)) return { ok: false, reason: "adjudicator view leaks economics" };
  if (forbidden.test(nTxt)) return { ok: false, reason: "analyst view leaks arm/cell identity" };
  return { ok: true, join_key: "opaque unit id only — useless without the sealed mapping" };
}
