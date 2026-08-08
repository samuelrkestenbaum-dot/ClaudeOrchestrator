// UNEXPLAINED-ASYMMETRY DETECTION.
//
// EXP-0005 carried a strong tell long before anyone understood the cause: both
// conditions met similar external friction — the host denied Bash constantly,
// and denied it MORE often to the arm that succeeded — yet product outcomes
// diverged totally. That pattern was visible in the telemetry while the
// diagnosis was still wrong.
//
// This detector reports the SHAPE and refuses to name the cause. Naming a cause
// from an asymmetry is exactly the error that produced the first, incorrect
// EXP-0005 diagnosis: a plausible mechanism was asserted, and reproduction later
// refuted it. The output is a question for self-audit to answer, not an answer.

export const MATERIAL_OUTCOME_GAP = 0.5;   // fraction of units; below this, groups are not "materially divergent"
export const SIMILAR_FRICTION_RATIO = 2.5; // per-unit external-failure rates within this factor count as "similar"

// `null / 10` is 0 in JavaScript, so a naive rate() silently converts an
// UNMEASURED field into a measured zero — the precise error this substrate
// refuses everywhere else. Caught by the unmeasured-friction fixture below.
const rate = (n, d) => (typeof n === "number" && Number.isFinite(n) && d > 0 ? n / d : null);
const pct = (x) => (x === null ? "-" : `${(x * 100).toFixed(1)}%`);

/**
 * @param {object} input
 *   groups: [{ id, units, accepted, durable_changes, external_denials,
 *              mutation_attempts, terminal_reasons:{}, retries, elapsed_s_median,
 *              total_tokens, tool_classes_used:[] }]
 *   evidence_refs: [] — where the numbers came from
 */
export function detectAsymmetry(input) {
  const g = input.groups || [];
  const findings = [];
  if (g.length < 2) {
    return { artifact: "asymmetry_scan", groups: g.length, findings, note: "fewer than two groups — nothing to compare" };
  }

  for (let i = 0; i < g.length; i++) {
    for (let j = i + 1; j < g.length; j++) {
      const a = g[i], b = g[j];

      // Outcome divergence, measured per unit so unequal group sizes do not
      // manufacture a gap.
      const accA = rate(a.accepted, a.units), accB = rate(b.accepted, b.units);
      if (accA === null || accB === null) continue;
      const outcomeGap = Math.abs(accA - accB);
      if (outcomeGap < MATERIAL_OUTCOME_GAP) continue;

      // External friction, per unit. `null` where unmeasured — never 0.
      const frA = rate(a.external_denials, a.units), frB = rate(b.external_denials, b.units);
      const frictionKnown = frA !== null && frB !== null;
      const hi = frictionKnown ? Math.max(frA, frB) : null;
      const lo = frictionKnown ? Math.min(frA, frB) : null;
      const similarFriction = frictionKnown && (lo === 0 ? hi === 0 : hi / lo <= SIMILAR_FRICTION_RATIO);

      if (!similarFriction) continue;   // divergent friction is an EXPLAINED difference, not this finding

      // The sharpest form: the group with MORE friction did BETTER. Friction
      // cannot be the explanation, so something structural differs.
      const worse = accA < accB ? a : b;
      const better = accA < accB ? b : a;
      const worseFr = accA < accB ? frA : frB;
      const betterFr = accA < accB ? frB : frA;
      const inverted = betterFr > worseFr;

      const dims = [];
      const cmp = (name, va, vb) => { if (va !== undefined && vb !== undefined && va !== null && vb !== null && String(va) !== String(vb)) dims.push(`${name}: ${a.id}=${va} vs ${b.id}=${vb}`); };
      cmp("accepted_rate", pct(accA), pct(accB));
      cmp("durable_changes", a.durable_changes, b.durable_changes);
      cmp("external_denials_per_unit", frA?.toFixed(2), frB?.toFixed(2));
      cmp("mutation_attempts", a.mutation_attempts, b.mutation_attempts);
      cmp("retries", a.retries, b.retries);
      cmp("median_elapsed_s", a.elapsed_s_median, b.elapsed_s_median);
      cmp("total_tokens", a.total_tokens, b.total_tokens);
      const tcA = (a.tool_classes_used || []).join("+"), tcB = (b.tool_classes_used || []).join("+");
      if (tcA && tcB && tcA !== tcB) dims.push(`tool_classes_used: ${a.id}=${tcA} vs ${b.id}=${tcB}`);
      const trA = JSON.stringify(a.terminal_reasons || {}), trB = JSON.stringify(b.terminal_reasons || {});
      if (trA !== trB) dims.push(`terminal_reasons: ${a.id}=${trA} vs ${b.id}=${trB}`);

      findings.push({
        finding: "unexplained_asymmetry",
        groups: [a.id, b.id],
        outcome_gap: pct(outcomeGap),
        friction_similar: true,
        friction_inverted: inverted,
        statement:
          `${worse.id} and ${better.id} met comparable external friction ` +
          `(${worseFr.toFixed(2)} vs ${betterFr.toFixed(2)} denials per unit` +
          (inverted ? `, and ${better.id} met MORE of it` : "") +
          `) yet outcomes diverged by ${pct(outcomeGap)}. External friction does not explain the divergence.`,
        differing_dimensions: dims,
        evidence_refs: input.evidence_refs || [],
        cause: null,
        cause_note:
          "NO CAUSE IS ASSERTED. This detector reports a shape and hands it to self-audit as a question. Asserting a " +
          "mechanism from an asymmetry is the error that produced the first, later-refuted diagnosis of the outcome " +
          "this detector was built from.",
        next_question:
          "which environmental or architectural assumption differs between these groups, such that comparable " +
          "external friction produced incomparable outcomes?",
      });
    }
  }

  return {
    artifact: "asymmetry_scan",
    groups: g.length,
    findings_count: findings.length,
    findings,
    thresholds: { material_outcome_gap: MATERIAL_OUTCOME_GAP, similar_friction_ratio: SIMILAR_FRICTION_RATIO },
    note:
      "Silence is not proof of symmetry: an asymmetry whose telemetry was never captured is invisible here. Fields " +
      "recorded as null are unmeasured, never zero.",
  };
}
