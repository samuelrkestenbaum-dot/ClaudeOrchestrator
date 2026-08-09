#!/usr/bin/env node
// EXP-0006 — compute the result from the run records, and refuse to compute one
// the records do not support.
//
//   UIC = accepted durable product outcomes / (uncached tokens / 1_000_000)
//
// THREE RULES THAT DECIDE WHETHER THERE IS A RESULT AT ALL.
//
// 1. AN INADMISSIBLE ARM IS NOT A ZERO. EXP-0005 returned 0/12 accepted for the
//    Gravito arm and reported `gravito_system_harmful`. The arm had never
//    obtained first mutation authority: the treatment did not execute, and
//    "did not execute" was scored as "produced nothing". Here, an arm whose
//    terminal reason is not `completed`, or whose session isolation is
//    unproven, is excluded from the numerator AND the denominator and counted
//    under `treatment_never_executed`.
//
// 2. A MISSING TOKEN FIELD IS NULL, NEVER ZERO. A denominator built from
//    coerced nulls reads as spectacular efficiency.
//
// 2b. UNCACHED = input_tokens + cache_creation_input_tokens.
//
//    Found on the pilot's second arm. run-arm.mjs records the result event's
//    `input_tokens` under the name `uncached_input_tokens`, and on this workload
//    that field is 42 and 51 — a rounding-level quantity, because essentially
//    all input arrives as cache reads or cache creations. A UIC built on it
//    would have reported a 20% efficiency gap manufactured out of a nine-token
//    difference. The metric would have been noise wearing a decimal point.
//
//    The correct reading is forced by the WORD "uncached" in the frozen metric,
//    not by the numbers: a cache-READ token was not processed fresh, and an
//    input token and a cache-CREATION token both were. The preflight recorded
//    the same derivation in advance -- "input_tokens and cache_read_input_tokens
//    present, so uncached is derivable" -- i.e. total input minus cache reads,
//    which includes cache creation. Calling 44,350 freshly-processed tokens
//    "cached" would simply be false.
//
//    STATED BECAUSE IT CUTS AGAINST THE AUTHOR: this correction RAISES the
//    Gravito arm's denominator (51 -> 75,292) and LOWERS its UIC. It is not the
//    choice that flatters the substrate. It is also corroborated by two
//    quantities nobody had to choose -- cost and output tokens -- which agree
//    with the corrected denominator at ~1.6-1.7x and disagree with the
//    uncorrected one.
//
//    Computed here from the raw components, which every unit already records,
//    so no arm is re-run to fix a labelling error.
//
// 3. THE COMPARISON IS REPORTED OVER MATCHED PAIRS ONLY. If one arm of a task
//    is inadmissible, the task contributes to neither side — otherwise the
//    surviving arm's task mix differs from its opponent's, and the difference
//    in mixes is reported as a difference in systems.

import fs from "node:fs";
import path from "node:path";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const RESULTS = path.join(HERE, "../results");
const RUNS = path.join(RESULTS, "runs");

const readJson = (p) => { try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return null; } };

const sel = readJson(path.join(RESULTS, "task-selection.json"));
const units = [];

for (const dir of (fs.existsSync(RUNS) ? fs.readdirSync(RUNS).sort() : [])) {
  const [task_id, arm] = dir.split(".");
  const d = path.join(RUNS, dir);
  const rec = readJson(path.join(d, "run-record.json"));
  const eco = readJson(path.join(d, "economics.json"));
  const acc = readJson(path.join(d, "acceptance.json"));
  const adm = readJson(path.join(d, "administration.json"));

  const admissible = rec?.admissible === true;
  units.push({
    task_id, arm,
    terminal_reason: rec?.terminal_reason ?? "no_run_record",
    isolated: rec?.isolation?.isolated ?? null,
    admissible,
    accepted: acc ? acc.accepted === true : null,
    // The reason an acceptance failed matters: a compiler rejection and a
    // suppression rejection are different findings about the same system.
    rejection_reason: acc && !acc.accepted
      ? (!acc.condition_1_zero_errors_in_file.pass ? "errors_remain_in_file"
        : !acc.condition_2_no_new_errors_elsewhere.pass ? "regression_elsewhere"
        : acc.diff_rejection.rejected ? "suppressed_rather_than_fixed" : "unknown")
      : null,
    // See rule 2b. Both components must be present, or the denominator is
    // UNKNOWN for this unit — a missing component is never treated as zero,
    // because zero cache-creation would read as a free run.
    uncached_tokens: (typeof eco?.uncached_input_tokens === "number" && typeof eco?.cache_creation_input_tokens === "number")
      ? eco.uncached_input_tokens + eco.cache_creation_input_tokens : null,
    fresh_input_tokens: eco?.uncached_input_tokens ?? null,        // the result event's raw `input_tokens`
    cache_creation_tokens: eco?.cache_creation_input_tokens ?? null,
    output_tokens: eco?.output_tokens ?? null,
    cache_read: eco?.cache_read_input_tokens ?? null,
    cost_usd: eco?.total_cost_usd ?? null,
    elapsed_s: eco?.elapsed_s ?? null,
    turns: eco?.num_turns ?? null,
    tool_calls: eco?.tool_calls ?? null,
    subagents: eco?.subagent_invocations ?? null,
    product_files: eco?.product_files_changed ?? null,
    governance_files: eco?.governance_files_changed ?? null,
    substrate_administered: adm?.arm === "gravito" ? true : adm?.arm === "native" ? false : null,
  });
}

// --- matched pairs ----------------------------------------------------------
const byTask = new Map();
for (const u of units) {
  if (!byTask.has(u.task_id)) byTask.set(u.task_id, {});
  byTask.get(u.task_id)[u.arm] = u;
}

const pairs = [], unmatched = [];
for (const [task_id, p] of [...byTask.entries()].sort()) {
  if (p.native?.admissible && p.gravito?.admissible) pairs.push({ task_id, native: p.native, gravito: p.gravito });
  else unmatched.push({
    task_id,
    native: p.native ? `${p.native.terminal_reason}${p.native.admissible ? "" : " (inadmissible)"}` : "absent",
    gravito: p.gravito ? `${p.gravito.terminal_reason}${p.gravito.admissible ? "" : " (inadmissible)"}` : "absent",
  });
}

const arm = (name) => {
  const rows = pairs.map((p) => p[name]);
  const accepted = rows.filter((r) => r.accepted === true).length;
  // A null token count makes the denominator UNKNOWN for that unit. It is
  // excluded and the exclusion is reported, never silently treated as zero.
  const withTokens = rows.filter((r) => typeof r.uncached_tokens === "number");
  const uncached = withTokens.reduce((s, r) => s + r.uncached_tokens, 0);
  const millions = uncached / 1_000_000;
  const cacheCreation = withTokens.reduce((s, r) => s + (r.cache_creation_tokens ?? 0), 0);
  const freshInput = withTokens.reduce((s, r) => s + (r.fresh_input_tokens ?? 0), 0);
  return {
    // The denominator is shown in PARTS. The defect this guards against was a
    // denominator that looked plausible until someone asked what was in it.
    denominator_composition: { fresh_input_tokens: freshInput, cache_creation_tokens: cacheCreation, uncached_total: uncached },
    denominator_includes_cache_creation: uncached >= cacheCreation && cacheCreation > 0,
    n_units: rows.length,
    accepted,
    acceptance_rate: rows.length ? accepted / rows.length : null,
    units_missing_token_accounting: rows.length - withTokens.length,
    uncached_tokens: uncached,
    output_tokens: rows.reduce((s, r) => s + (r.output_tokens ?? 0), 0),
    cost_usd: Number(rows.reduce((s, r) => s + (r.cost_usd ?? 0), 0).toFixed(4)),
    elapsed_s: Math.round(rows.reduce((s, r) => s + (r.elapsed_s ?? 0), 0)),
    governance_files_touched: rows.reduce((s, r) => s + (r.governance_files ?? 0), 0),
    subagent_invocations: rows.reduce((s, r) => s + (r.subagents ?? 0), 0),
    UIC: millions > 0 ? Number((accepted / millions).toFixed(2)) : null,
    UIC_note: millions > 0 ? null : "denominator is zero or unknown — no UIC is computed rather than an infinite one",
  };
};

const native = arm("native"), gravito = arm("gravito");

// --- the verdict, with EXP-0005's missing vocabulary available --------------
const gravitoUnits = units.filter((u) => u.arm === "gravito");
const gravitoNeverExecuted = gravitoUnits.length > 0 && gravitoUnits.every((u) => !u.admissible);

let verdict, verdict_reason;
if (gravitoNeverExecuted) {
  verdict = "treatment_never_executed";
  verdict_reason = "no Gravito arm reached an admissible terminal state. This is NOT a product verdict — it is the " +
    "condition EXP-0005 lacked the vocabulary to report, and reporting it as harm was that experiment's central error.";
} else if (!pairs.length) {
  verdict = "no_matched_pairs";
  verdict_reason = "no task produced two admissible arms, so no comparison exists that is not confounded by task mix.";
} else if (native.UIC === null || gravito.UIC === null) {
  verdict = "denominator_unavailable";
  verdict_reason = "token accounting is missing for at least one arm; UIC is not computable and is not approximated.";
} else if (gravito.UIC > native.UIC) {
  verdict = "gravito_higher_uic";
  verdict_reason = "on this work, the substrate returned more accepted outcomes per uncached token than native execution.";
} else if (gravito.UIC < native.UIC) {
  verdict = "native_higher_uic";
  verdict_reason = "the governance overhead is not recovered on this work. That is a real answer, not a failure of the experiment.";
} else {
  verdict = "indistinguishable";
  verdict_reason = "the two arms returned the same UIC on this sample.";
}

const report = {
  artifact: "exp0006_analysis",
  experiment: "EXP-0006",
  metric: "UIC = accepted durable product outcomes / (uncached tokens / 1_000_000)",
  tasks_selected: sel?.selected?.length ?? null,
  units_recorded: units.length,
  matched_pairs: pairs.length,
  unmatched_tasks: unmatched,
  arms: { native, gravito },
  verdict,
  verdict_reason,
  accounting_rules: [
    "an inadmissible arm is excluded from BOTH numerator and denominator — it is not a zero",
    "a missing token field is null, never zero",
    "only matched pairs are compared, so the arms face the same task mix",
    "all Gravito governance output is denominator cost and receives no numerator credit",
  ],
  units,
};

fs.writeFileSync(path.join(RESULTS, "analysis.json"), JSON.stringify(report, null, 2));

const pct = (x) => (x === null ? "n/a" : `${(x * 100).toFixed(0)}%`);
console.log(`EXP-0006 — ${units.length} units recorded, ${pairs.length} matched pair(s)\n`);
for (const [name, a] of [["native", native], ["gravito", gravito]]) {
  console.log(`${name.padEnd(8)} accepted ${a.accepted}/${a.n_units} (${pct(a.acceptance_rate)})  uncached ${a.uncached_tokens.toLocaleString()}  UIC ${a.UIC ?? "n/a"}  cost $${a.cost_usd}  ${Math.round(a.elapsed_s / 60)}min`);
}
if (unmatched.length) {
  console.log(`\nunmatched (excluded from the comparison, not scored as zero):`);
  for (const u of unmatched) console.log(`  ${u.task_id}  native=${u.native}  gravito=${u.gravito}`);
}
console.log(`\nVERDICT: ${verdict}\n  ${verdict_reason}`);
