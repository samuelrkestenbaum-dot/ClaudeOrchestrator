// Item 6 — governance-path stripping and separate cost accounting.
//
// The Gravito arm emits receipts, memory updates and routing records. A diff
// containing `build-os/receipts/…` identifies the arm on sight, so an
// adjudicator seeing it is unblinded before reading a line of code.
//
// Registered rule: the adjudicated artifact is the PRODUCT diff only.
// Governance output receives zero numerator credit, stays in the denominator as
// system cost, is withheld from the adjudicator, and — if any identifying
// governance path survives into the adjudicated artifact — the unit is
// `result_confounded`.

export const GOVERNANCE_PATTERNS = [
  /^build-os\//,
  /^\.claude\//,
  /(^|\/)receipts?\//,
  /(^|\/)packets?\//,
  /(^|\/)memory\//,
  /(^|\/)routing\//,
  /(^|\/)dispositions?\//,
  /(^|\/)outcomes?\//,
  /(^|\/)CLAUDE\.md$/,
  /(^|\/)\.gravito\//,
];

export const isGovernancePath = (p) => GOVERNANCE_PATTERNS.some((re) => re.test(String(p)));

/**
 * Split a changed-path set. Product paths go to the adjudicator; governance
 * paths are measured as cost and never shown.
 */
export function splitPaths(paths = []) {
  const product = [], governance = [];
  for (const p of paths) (isGovernancePath(p) ? governance : product).push(p);
  return {
    product_paths: product.sort(),
    governance_paths: governance.sort(),
    governance_count: governance.length,
    numerator_credit_for_governance: 0,
    accounting_note:
      "Governance output is COST, never output. Its paths are withheld from the adjudicator and its model " +
      "tokens remain in the denominator. Counting it as useful work would make the metric gameable by " +
      "producing paperwork.",
  };
}

/** Split a unified diff by file header, keeping only product hunks. */
export function stripGovernanceDiff(diff = "") {
  const sections = String(diff).split(/(?=^diff --git )/m).filter(Boolean);
  const product = [], governance = [];
  for (const s of sections) {
    const m = /^diff --git a\/(\S+) b\/(\S+)/m.exec(s);
    const p = m ? m[2] : null;
    (p && isGovernancePath(p) ? governance : product).push(s);
  }
  return { product_diff: product.join(""), governance_diff: governance.join(""), governance_sections: governance.length };
}

/**
 * The admission gate. A governance path surviving into the adjudicated artifact
 * is `result_confounded` — not silently stripped a second time, because a leak
 * means the pipeline that produced it is untrustworthy for that unit.
 */
export function assertProductOnly(adjudicatedDiff = "", adjudicatedPaths = []) {
  const inDiff = [];
  for (const m of String(adjudicatedDiff).matchAll(/^diff --git a\/\S+ b\/(\S+)/gm))
    if (isGovernancePath(m[1])) inDiff.push(m[1]);
  const inPaths = adjudicatedPaths.filter(isGovernancePath);
  const leaks = [...new Set([...inDiff, ...inPaths])];
  return {
    clean: leaks.length === 0,
    leaked_paths: leaks,
    classification: leaks.length ? "result_confounded" : "admissible",
    reason: leaks.length
      ? `governance path(s) survived into the adjudicated artifact: ${leaks.join(", ")} — the adjudicator would be ` +
        `unblinded on sight, so this unit is result_confounded rather than re-stripped`
      : null,
  };
}
