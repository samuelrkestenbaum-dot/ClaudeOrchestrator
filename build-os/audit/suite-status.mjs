// FULL-SUITE STATUS — "most of it ran" may not quietly become "it passes".
//
// The operator's rule, and the reason this file exists: a broad suite with no
// completed full run is UNPROVEN, not green. That is the same discipline the
// check auditor applies to individual checks, raised one level: there, a check
// that never demonstrated a failure is UNPROVEN however often it passed; here,
// a SUITE that never demonstrated a completion is UNPROVEN however many tests
// passed before the cutoff.
//
// THE MEASUREMENT ARTIFACT THAT MADE THIS WORSE. The harness reporting on this
// suite scraped the LAST "<n> passed, <m> failed" line out of the output. In an
// aggregator suite that line belongs to the last CHAINED sub-suite, not to the
// run. "67 passed at cutoff" was therefore never a partial total — it was one
// sub-suite's score, misread as the suite's. A truncated run does not have a
// total, and the honest representation of a total nobody computed is absence.

export const SUITE_STATUS = ["UNPROVEN", "TRUNCATED", "FAILING", "GREEN"];

/**
 * @param {object} r
 *   completed         did the runner reach the suite's own RESULT line?
 *   result_line       the RESULT line, when there is one
 *   passed / failed   parsed from that line ONLY — never from a chained line
 *   exit_code         the runner's exit code (124 = timed out)
 *   wall_clock_s      measured duration
 *   ceiling_s         the timeout in force
 *   runs_completed    how many full runs have ever finished
 */
export function suiteStatus(r = {}) {
  const reasons = [];
  let status;

  if (!r.completed) {
    status = r.exit_code === 124 ? "TRUNCATED" : "UNPROVEN";
    reasons.push(r.exit_code === 124
      ? `killed by the ${r.ceiling_s}s ceiling before emitting its RESULT line — the run has no total, and a total nobody computed must not be inferred from partial output`
      : "no RESULT line was emitted, so the suite never reported a total");
    // Stated explicitly because it is the exact substitution being forbidden.
    reasons.push("tests that passed before the cutoff are NOT a partial pass: the unrun remainder is unmeasured, not assumed-passing");
  } else if ((r.failed ?? 0) > 0) {
    status = "FAILING";
    reasons.push(`${r.failed} failing test(s) in a completed run`);
  } else if (!r.runs_completed || r.runs_completed < 1) {
    status = "UNPROVEN";
    reasons.push("a RESULT line without a recorded completed run — the two must agree");
  } else {
    status = "GREEN";
    reasons.push(`completed in ${r.wall_clock_s}s with ${r.passed} passed, 0 failed`);
  }

  // A ceiling is only meaningful against a measured duration. Raising it before
  // the cause is known converts a diagnosis into a suppression.
  const ceilingVerdict = !r.completed
    ? "UNKNOWN — do not raise the ceiling until a full run has been measured; a raised ceiling on an undiagnosed suite hides the cause instead of removing it"
    : r.wall_clock_s > (r.ceiling_s ?? Infinity)
      ? `OBSOLETE — the suite legitimately needs ${r.wall_clock_s}s but the ceiling is ${r.ceiling_s}s; justify a new ceiling from the measured distribution, not from a single run`
      : `ADEQUATE — ${r.wall_clock_s}s completed inside the ${r.ceiling_s}s ceiling`;

  return {
    artifact: "full_suite_status",
    suite: r.suite ?? null,
    status,
    green: status === "GREEN",
    passed: r.completed ? (r.passed ?? null) : null,   // null, never a partial count
    failed: r.completed ? (r.failed ?? null) : null,
    wall_clock_s: r.wall_clock_s ?? null,
    ceiling_s: r.ceiling_s ?? null,
    ceiling_verdict: ceilingVerdict,
    runs_completed: r.runs_completed ?? 0,
    reasons,
    determinism: (r.runs_completed ?? 0) >= 2
      ? "repeatability observed across runs"
      : "SINGLE RUN — one completion proves the suite CAN finish, not that it finishes reliably; a duration distribution needs repeats",
    note:
      "In an aggregator suite, a chained sub-suite's '<n> passed' line is NOT the suite's total. Parsing the last " +
      "such line yields a number that looks like a result and is not one.",
  };
}
