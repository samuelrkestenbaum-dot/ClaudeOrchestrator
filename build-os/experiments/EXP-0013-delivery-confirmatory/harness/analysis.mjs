#!/usr/bin/env node
// EXP-0013 Stage-A ANALYSIS — frozen BEFORE any outcome exists.
//
// Pure function of the cell records; consults no direction while gating.
// Enforces, in order: delivery gate (any unintended-empty/invalid delivery
// VOIDS the stage), rerun bookkeeping (max 1 per pair, 2 total), reliability
// (<=1 infrastructure-invalid cell of 8), acceptance as a MANDATORY quality
// gate (a pair with an unaccepted arm contributes NO efficiency statistic),
// the cache-insensitive primary metric (paired log ratio of output_tokens +
// uncached input_tokens), label-neutral variance, and the effect-continuation
// ladder. Four pairs are NEVER proof; EXP-0011 outcomes are NEVER pooled.
//
// Cell record shape (one per executed cell):
//   { seq, pos, arm, rerun_of: null|"seq.pos",
//     delivery_valid: bool, invalid_reason: null|string,
//     accepted: bool|null, metered: bool,
//     economics: { output_tokens, uncached_input_tokens, total_cost_usd,
//                  cache_read_input_tokens, cache_creation_input_tokens } | null,
//     elapsed_s, terminal_reason }

const PAIR_KEYS = ["S1.2", "S1.3", "S2.2", "S2.3"];

export function analyze({ cells, concurrentOverlapDetected = false }) {
  const notes = [
    "four pairs are never proof — magnitude-worth-studying is not 'Gravito won'",
    "EXP-0011 cells are EXPLORATORY_DESIGN_EVIDENCE and are never pooled here",
  ];

  // 1. DELIVERY GATE — one unintended empty/invalid delivery voids Stage A.
  const deliveryFailures = cells.filter((c) => c.delivery_valid === false);
  if (deliveryFailures.length > 0) {
    return { artifact: "exp0013_stage_a_analysis", harness_verdict: "VOID",
      void_reason: `DELIVERY_GATE: ${deliveryFailures.length} invalid delivery(ies): ${deliveryFailures.map((c) => c.invalid_reason).join("; ")}`,
      treatment_effectiveness: "UNPROVEN", renderer_comparison: "VOID", notes };
  }

  // 2. RERUNS — resolve replacements; enforce frozen stopping rule.
  const reruns = cells.filter((c) => c.rerun_of);
  const rerunsByPair = {};
  for (const r of reruns) rerunsByPair[r.rerun_of] = (rerunsByPair[r.rerun_of] ?? 0) + 1;
  const tooManyPerPair = Object.entries(rerunsByPair).filter(([, n]) => n > 2); // 2 cells = 1 pair-rerun
  const pairReruns = Object.values(rerunsByPair).reduce((a, b) => a + b, 0) / 2;
  if (tooManyPerPair.length > 0 || pairReruns > 2) {
    return { artifact: "exp0013_stage_a_analysis", harness_verdict: "NOT_QUALIFIED",
      reason: `RERUN_LIMIT: ${pairReruns} pair-rerun(s) (max 2), per-pair violations: ${tooManyPerPair.map(([k]) => k).join(",") || "none"}`,
      treatment_effectiveness: "UNPROVEN", renderer_comparison: "UNRUN", notes };
  }
  // Effective cells: rerun replaces its original pair's cells.
  const replacedPairs = new Set(reruns.map((r) => r.rerun_of));
  const effective = cells.filter((c) => c.rerun_of || !replacedPairs.has(`${c.seq}.${c.pos}`));

  // 3. RELIABILITY — missing telemetry / non-success terminal = infrastructure-invalid.
  const infraInvalid = effective.filter((c) => !c.metered || (c.terminal_reason && c.terminal_reason !== "success"));
  if (infraInvalid.length > 1) {
    return { artifact: "exp0013_stage_a_analysis", harness_verdict: "NOT_QUALIFIED",
      reason: `RELIABILITY: ${infraInvalid.length} infrastructure-invalid cells (max 1): ${infraInvalid.map((c) => `${c.seq}.p${c.pos}.${c.arm}:${c.metered ? c.terminal_reason : "NOT_METERED"}`).join("; ")}`,
      treatment_effectiveness: "UNPROVEN", renderer_comparison: "UNRUN", notes };
  }

  // 4. PAIRING + ACCEPTANCE QUALITY GATE + PRIMARY METRIC.
  const pairs = [];
  for (const key of PAIR_KEYS) {
    const [seq, pos] = key.split(".");
    const rules = effective.find((c) => c.seq === seq && c.pos === +pos && c.arm === "lean_rules");
    const skills = effective.find((c) => c.seq === seq && c.pos === +pos && c.arm === "lean_skills");
    if (!rules || !skills) { pairs.push({ pair: key, status: "MISSING_CELLS", efficiency: null }); continue; }
    if (infraInvalid.includes(rules) || infraInvalid.includes(skills)) {
      pairs.push({ pair: key, status: "INFRASTRUCTURE_INVALID", efficiency: null }); continue;
    }
    if (rules.accepted !== true || skills.accepted !== true) {
      pairs.push({ pair: key, status: "QUALITY_RESULT_ONLY",
        detail: `unaccepted arm(s): ${[rules.accepted !== true && "lean_rules", skills.accepted !== true && "lean_skills"].filter(Boolean).join(",")} — cheap failure vs expensive success is not efficiency`,
        efficiency: null }); continue;
    }
    const m = (c) => c.economics.output_tokens + c.economics.uncached_input_tokens;
    const logRatio = Math.log(m(skills) / m(rules)); // negative favors lean_skills
    pairs.push({ pair: key, status: "EFFICIENCY", efficiency: {
      lean_rules_tokens: m(rules), lean_skills_tokens: m(skills),
      paired_log_ratio: logRatio, pct_difference: (Math.exp(logRatio) - 1) * 100,
      cache_read: { lean_rules: rules.economics.cache_read_input_tokens, lean_skills: skills.economics.cache_read_input_tokens },
    } });
  }

  const eff = pairs.filter((p) => p.status === "EFFICIENCY").map((p) => p.efficiency.paired_log_ratio);
  let efficiency = null, ladder = "NO_EFFICIENCY_PAIRS";
  if (eff.length > 0) {
    const absLogs = eff.map(Math.abs); // label-neutral: direction never consulted
    const mean = absLogs.reduce((a, b) => a + b, 0) / absLogs.length;
    const sd = Math.sqrt(absLogs.map((x) => (x - mean) ** 2).reduce((a, b) => a + b, 0) / Math.max(1, absLogs.length - 1));
    const sorted = [...eff].sort((a, b) => a - b);
    const median = sorted.length % 2 ? sorted[(sorted.length - 1) / 2] : (sorted[sorted.length / 2 - 1] + sorted[sorted.length / 2]) / 2;
    // AMENDMENT v3 (audit-found bias): |exp(median)-1| is direction-DEPENDENT
    // (a 0.75x ratio read 25% while its mirror 1.333x read 33%), so the
    // ladder was easier to cross in one direction. The label-neutral form
    // exp(|median|)-1 — the larger arm relative to the smaller — is
    // symmetric under relabeling, proven by the relabel-invariance test.
    const medianPct = (Math.exp(Math.abs(median)) - 1) * 100;
    const signsConsistent = eff.every((x) => x > 0) || eff.every((x) => x < 0);
    ladder = !signsConsistent || medianPct < 10 ? "NO_AUTOMATIC_EXPANSION_OWNER_DECIDES"
      : medianPct < 20 ? "EXPANSION_ONLY_AT_RECOMPUTED_POWERED_N"
      : "PREREGISTERED_FIXED_CONFIRMATORY_N_ONLY";
    efficiency = { pairs_contributing: eff.length, median_pct_difference: medianPct,
      signs_consistent: signsConsistent, label_neutral_sd: sd,
      variance_gate: sd <= 0.45 ? "SUPPORTS_EXISTING_STAGE_B_N" : "REQUIRES_RECOMPUTATION_AND_REAUTHORIZATION",
      elapsed_status: concurrentOverlapDetected ? "TERTIARY (concurrency detected)" : "SECONDARY (serial execution)" };
  }

  return {
    artifact: "exp0013_stage_a_analysis",
    harness_verdict: "QUALIFIED",
    treatment_effectiveness: "UNPROVEN",
    renderer_comparison: eff.length > 0 ? "MEASURED_STAGE_A_ONLY" : "UNRUN",
    reliability: { infrastructure_invalid: infraInvalid.length, pair_reruns: pairReruns },
    pairs, efficiency, effect_continuation_ladder: ladder, notes,
  };
}
