# EXP-0004 BLINDING — THE END-TO-END DEMONSTRATION, ON A SIMULATED MATCHED PAIR.
#
#   bash run-blinded-flow.sh --work <dir> --at <ISO-8601> [--salt <s>]
#
# Invoked with `bash`, never executed: EXP-0003's suite asserts ZERO executables
# anywhere under build-os/experiments/, and this file is mode 644 by design.
#
# WHAT IT DEMONSTRATES, in the operator's required order:
#
#   seal -> views -> adjudicate -> freeze -> anonymous verdict -> reveal
#
# with one ordering correction stated out loud rather than smoothed over: the
# freeze list INCLUDES the anonymous provisional verdict, so the verdict cannot
# come after the whole freeze. ACCEPTANCE is frozen first, the anonymous verdict
# is computed from the frozen acceptance plus the economics, and the full
# fourteen-item snapshot is taken last. Nothing is computed after its own
# snapshot, and nothing is frozen before it exists.
#
# EVERY NUMBER BELOW IS SIMULATED. The fixture is five invented matched pairs.
# It demonstrates the MACHINERY, and it measures nothing whatsoever about the
# real thesis. No model is invoked, no network is touched, no repository outside
# this one is read, and the work directory is the only thing written.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEAL="$HERE/seal-mapping.mjs"
VIEWS="$HERE/views.mjs"
FREEZE="$HERE/freeze.mjs"
REVEAL="$HERE/reveal.mjs"
FIX="$HERE/fixtures"

WORK=""
AT=""
SALT="EXP0004-BLIND-v1"
while [ $# -gt 0 ]; do
  case "$1" in
    --work) WORK="$2"; shift 2 ;;
    --at)   AT="$2";   shift 2 ;;
    --salt) SALT="$2"; shift 2 ;;
    *) echo "run-blinded-flow: unknown option: $1" >&2; exit 2 ;;
  esac
done
[ -n "$WORK" ] || { echo "run-blinded-flow: --work <dir> is required" >&2; exit 2; }
[ -n "$AT" ]   || { echo "run-blinded-flow: --at <ISO-8601> is required (no clock is read)" >&2; exit 2; }
mkdir -p "$WORK" || exit 2

step(){ echo; echo "---- $* ----"; }
die(){ echo "run-blinded-flow: FAILED at: $*" >&2; exit 1; }

echo "EXP-0004 blinded flow — SIMULATED matched pair, five invented task pairs."
echo "Every figure below is a fixture. It demonstrates the machinery and measures nothing."

step "1. SEAL the mapping (derived from a registered rule + declared salt; digest committed before the run)"
node "$SEAL" seal --rule experiment-salt-parity --salt "$SALT" \
  --tasks E4-T1,E4-T2,E4-T3,E4-T4,E4-T5 --out "$WORK" || die "seal"
node "$SEAL" reproduce --sealed "$WORK/mapping.sealed.json" || die "reproduce"

step "2. BUILD the adjudicator view (task id, opaque work-product ref, tests, question — nothing else)"
node "$VIEWS" adjudicator --records "$FIX/simulated-pair-records.json" \
  --sealed "$WORK/mapping.sealed.json" --out "$WORK/adjudicator-view.json" || die "adjudicator view"
node "$VIEWS" leakcheck --view "$WORK/adjudicator-view.json" || die "adjudicator leakcheck"

step "3. BUILD the analyst view BEFORE acceptance is frozen (starting sizes withheld)"
node "$VIEWS" analyst --records "$FIX/simulated-pair-records.json" \
  --sealed "$WORK/mapping.sealed.json" --out "$WORK/analyst-view-preacceptance.json" || die "pre-freeze analyst view"
node "$VIEWS" leakcheck --view "$WORK/analyst-view-preacceptance.json" || die "analyst leakcheck"
if grep -q '"starting_context_bytes"' "$WORK/analyst-view-preacceptance.json"; then
  die "starting sizes reached the analyst before acceptance was frozen"
fi
echo "confirmed: starting sizes are absent from the analyst view while acceptance is still open"

step "4. ADJUDICATE (fixture stand-in for the blinded acceptance adjudicator)"
node "$VIEWS" fixture-adjudication --records "$FIX/simulated-pair-records.json" \
  --sealed "$WORK/mapping.sealed.json" --out "$WORK/adjudication.json" || die "adjudication"
echo "acceptance is now FROZEN; the starting sizes may be released to the analyst"

step "5. RELEASE the analyst view with acceptance frozen"
node "$VIEWS" analyst --records "$FIX/simulated-pair-records.json" --acceptance-frozen \
  --sealed "$WORK/mapping.sealed.json" --out "$WORK/analyst-view.json" || die "analyst view"
node "$VIEWS" leakcheck --view "$WORK/analyst-view.json" || die "frozen analyst leakcheck"

step "6. CALCULATE per-task and aggregate figures, in Arm X / Arm Y terms only"
node "$VIEWS" calculations --analyst "$WORK/analyst-view.json" \
  --adjudication "$WORK/adjudication.json" --out "$WORK/calculations.json" || die "calculations"
node "$VIEWS" leakcheck --view "$WORK/calculations.json" || die "calculations leakcheck"

step "7. ANONYMOUS PROVISIONAL VERDICT — computed from Arm X / Arm Y alone"
node "$VIEWS" provisional --calculations "$WORK/calculations.json" \
  --exclusions "$FIX/exclusion-decisions.json" --eligibility "$FIX/eligibility.json" \
  --out "$WORK/provisional-verdict.json" || die "provisional verdict"
node "$VIEWS" leakcheck --view "$WORK/provisional-verdict.json" || die "provisional leakcheck"
node -e '
  const fs = require("fs");
  const p = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  const L = [];
  L.push("anonymous_label: " + p.anonymous_label);
  L.push("n_pairs: " + p.n_pairs + " (minimum " + p.minimum_pairs_rule.minimum + " met: " + p.minimum_pairs_rule.met + ")");
  L.push("acceptance: " + JSON.stringify(p.acceptance));
  L.push("median uncached reduction: " + JSON.stringify(p.uncached_tokens.median_reduction_pct));
  L.push("median elapsed reduction:  " + JSON.stringify(p.elapsed.median_reduction_pct));
  L.push("elapsed band:              " + JSON.stringify(p.elapsed.band));
  L.push("token gate met for:   " + p.uncached_tokens.gate_met_for);
  L.push("elapsed gate met for: " + p.elapsed.gate_met_for);
  process.stdout.write(L.join("\n") + "\n");
' "$WORK/provisional-verdict.json" || die "render provisional verdict"
echo "NOTE: the statement above is true under EITHER mapping. Nothing here names a registered outcome."

step "8. FREEZE all fourteen required artifacts"
node "$FREEZE" prepare --analyst "$WORK/analyst-view.json" --adjudication "$WORK/adjudication.json" \
  --calculations "$WORK/calculations.json" --provisional "$WORK/provisional-verdict.json" \
  --exclusions "$FIX/exclusion-decisions.json" --out "$WORK/freeze-inputs" || die "freeze prepare"
node "$FREEZE" freeze --inputs "$WORK/freeze-inputs" --out "$WORK/snapshot.json" || die "freeze"
node "$FREEZE" verify --snapshot "$WORK/snapshot.json" --inputs "$WORK/freeze-inputs" || die "freeze verify"

step "9. REVEAL — one-way, and only because all four conditions hold"
node "$REVEAL" --snapshot "$WORK/snapshot.json" --inputs "$WORK/freeze-inputs" \
  --verdict "$WORK/provisional-verdict.json" --sealed "$WORK/mapping.sealed.json" \
  --committed-digest "$WORK/mapping.sha256" --at "$AT" --out "$WORK/reveal-audit.json" || die "reveal"

step "10. TRANSLATED VERDICT, in the registered seven-outcome vocabulary"
node -e '
  const fs = require("fs");
  const a = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
  process.stdout.write(
    "registered_outcome:      " + a.registered_outcome + "\n" +
    "registered_outcome_code: " + a.registered_outcome_code + "\n" +
    "translation_rule:        " + a.translation_rule + "\n" +
    "anonymous label before the reveal: " + a.anonymous_label_before_reveal + "\n"
  );
' "$WORK/reveal-audit.json" || die "render verdict"

echo
echo "SIMULATED flow complete. Artifacts under: $WORK"
echo "REMINDER: the numbers are a fixture. This run is evidence about the blinding machinery only."
