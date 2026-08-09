#!/usr/bin/env node
// EXP-0007 factor reporter — mutation tests.
//
// The instrument exists to make ONE failure impossible: an intervention that
// improves one factor, worsens another, and reports a net win. So the trade
// detector is the thing that must be proven able to fire.

import { compare, rates, nativeReference, baselineReference } from "./factors.mjs";
let pass = 0, fail = 0;
const t = (n, c, d = "") => { if (c) { pass++; console.log(`  ok   ${n}`); } else { fail++; console.log(`  FAIL ${n}${d ? " — " + d : ""}`); } };

const nat = { turns_per_task: 30, uncached_per_turn: 1500, cache_read_per_turn: 45000, output_per_turn: 350, acceptance_rate: 1, UIC: 20 };
const mk = (o) => ({ ...nat, ...o });

// THE MUTATION THAT MATTERS: cut turns 25%, inflate context 20%.
const trade = compare(mk({ turns_per_task: 22.5, cache_read_per_turn: 54000 }), nat);
t("MUTATION turns down / context up -> TRADE, not a win", trade.trade_detected === true);
t("  ...and the note names BOTH sides",
  /improved turns/.test(trade.trade_note) && /worsening context_per_turn/.test(trade.trade_note), trade.trade_note);

// A genuine across-the-board win must NOT be called a trade.
const win = compare(mk({ turns_per_task: 27, cache_read_per_turn: 42000, output_per_turn: 330 }), nat);
t("a real improvement on every factor is NOT reported as a trade", win.trade_detected === false);

// A genuine across-the-board regression must not be called a trade either.
const loss = compare(mk({ turns_per_task: 40, cache_read_per_turn: 60000, output_per_turn: 500 }), nat);
t("an across-the-board regression is not a trade", loss.trade_detected === false);
t("  ...and it misses every target", loss.targets_missed.length >= 3, JSON.stringify(loss.targets_missed));

// Acceptance regression must surface even when every cost factor improves.
const cheapButWorse = compare(mk({ turns_per_task: 20, cache_read_per_turn: 30000, output_per_turn: 200, acceptance_rate: 0.5 }), nat);
t("MUTATION cheaper but LOSES an outcome -> acceptance regression flagged",
  cheapButWorse.acceptance_regression === true);
t("  ...even though every cost target is met", cheapButWorse.targets_missed.length === 0);

// Targets are the operator's and must not drift silently.
t("targets are 1.10 / 1.15 / 1.10 as set", compare(mk({}), nat).targets_met.turns === true);
const atTarget = compare(mk({ turns_per_task: 33.1 }), nat);
t("a factor just OVER target is reported missed", atTarget.targets_missed.some((m) => /turns/.test(m)));

// The frozen EXP-0006 reference must reproduce its published figures.
const n12 = nativeReference(["T01","T02","T03","T04","T05","T06","T07","T08","T09","T10","T11","T12"]);
const b12 = baselineReference(["T01","T02","T03","T04","T05","T06","T07","T08","T09","T10","T11","T12"]);
t("frozen native reference reproduces UIC 18.15", Math.abs(n12.UIC - 18.15) < 0.02, String(n12.UIC));
t("frozen gravito baseline reproduces UIC 10.36", Math.abs(b12.UIC - 10.36) < 0.02, String(b12.UIC));
const pub = compare(b12, n12);
t("and reproduces the published 1.40x turns factor", Math.abs(pub.factors.turns - 1.40) < 0.01, String(pub.factors.turns));
t("and the published 1.52x context factor", Math.abs(pub.factors.context_per_turn - 1.52) < 0.01, String(pub.factors.context_per_turn));
t("and the published 1.33x output factor", Math.abs(pub.factors.output_per_turn - 1.33) < 0.01, String(pub.factors.output_per_turn));

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
