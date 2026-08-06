#!/usr/bin/env bash
# Build OS — demo environment test suite (standalone).
#
# Proves the design-partner demo in build-os/demo/ is REAL: that it runs
# end-to-end unattended, that every one of its ten steps leaves an observable
# artifact, that the two states it claims to be able to reach (a block and its
# recovery; an eligible index and a bypass verdict) are BOTH actually reached,
# that the customer-facing display speaks no internal vocabulary, and that the
# demo tree contains no fabricated metric.
#
# It runs the demo against DEDICATED FIXTURE REPOSITORIES the demo itself
# creates under mktemp. It never runs the demo against this repository, and it
# never runs any other suite.
#
#   tests/demo_environment_tests.sh
#
# Exit 0 when every check passes; 1 otherwise. Writes only inside its own
# mktemp workspace.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/.." && pwd)"
DEMO_DIR="$REPO/build-os/demo"
RUN="$DEMO_DIR/run-demo.sh"
SCRIPT_MD="$DEMO_DIR/DEMO_SCRIPT.md"

PASS=0
FAIL=0
ok(){   PASS=$((PASS+1)); printf 'ok   %s\n' "$1"; }
bad(){  FAIL=$((FAIL+1)); printf 'FAIL %s\n' "$1"; [ -n "${2:-}" ] && printf '     %s\n' "$2"; }

# assert_file_has <label> <file> <fixed-string>...
assert_file_has(){
  local label="$1" f="$2"; shift 2
  if [ ! -f "$f" ]; then bad "$label" "no such artifact: $f"; return; fi
  local s missing=""
  for s in "$@"; do
    grep -qF -- "$s" "$f" || missing="$missing
       missing marker: $s"
  done
  if [ -n "$missing" ]; then bad "$label" "$f$missing"; else ok "$label"; fi
}

WS_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gravito-demo-suite.XXXXXX")"
cleanup(){ rm -rf "$WS_ROOT"; }
trap cleanup EXIT

printf 'demo environment tests — repo %s\n' "$REPO"
printf 'workspace: %s\n\n' "$WS_ROOT"

# ---------------------------------------------------------------- presence ---
if [ -x "$RUN" ]; then ok "run-demo.sh exists and is executable"; else bad "run-demo.sh exists and is executable" "$RUN"; fi
if [ -f "$SCRIPT_MD" ]; then ok "DEMO_SCRIPT.md exists"; else bad "DEMO_SCRIPT.md exists" "$SCRIPT_MD"; fi

if [ ! -x "$RUN" ]; then
  printf '\n==== RESULT: %s passed, %s failed ====\n' "$PASS" "$((FAIL+1))"
  exit 1
fi

# --------------------------------------------------- the end-to-end demo run --
WS="$WS_ROOT/ws"
LOG="$WS_ROOT/demo-run.log"
BEFORE="$(cd "$REPO" && git status --porcelain 2>/dev/null | sort)"
bash "$RUN" --auto --workspace "$WS" > "$LOG" 2>&1
RC=$?
if [ "$RC" -eq 0 ]; then
  ok "demo runs end-to-end under --auto and exits 0"
else
  bad "demo runs end-to-end under --auto and exits 0" "exit $RC; tail of log:
$(tail -n 25 "$LOG" | sed 's/^/       /')"
fi

A="$WS/artifacts"

# ------------------------------------------- one artifact per numbered step ---
assert_file_has "step 1 (installation) artifact"       "$A/01-installation.txt" \
  "gravito-runtime v" "install complete" "STATUS:"
assert_file_has "step 2 (repository intake) artifact"  "$A/02-intake.txt" \
  "DISCOVERED" "GUESSED" "Unsupported assumptions" "BASELINE: NOT MEASURED"
assert_file_has "step 3 (unrouted mutation) artifact"  "$A/03-blocked-and-recovered.txt" \
  "MUTATION BLOCKED" "route-task.sh" "BLOCKED-EXIT: 2" "RECOVERED-EXIT: 0"
assert_file_has "step 4 (depth selection) artifact"    "$A/04-depth-selection.txt" \
  "direct" "gravito_light" "gravito_full" "WITHHELD"
assert_file_has "step 5 (customer display) artifact"   "$A/05-customer-display.txt" \
  "YOUR TASKS" "DEPTH AND WHY" "BUDGETS"
assert_file_has "step 6 (evidence + receipt) artifact" "$A/06-evidence.txt" \
  "selected_mode:" "BLOCK-MUTATION-NO-RECEIPT" "ALLOW-MUTATION"
assert_file_has "step 7 (honest degradation) artifact" "$A/07-degradation.txt" \
  "BUDGET-BREACH" "CONCEALED-CLOSE-EXIT: 2" "DECLARED-CLOSE-EXIT: 0"
assert_file_has "step 8 (fresh-worker continuity) artifact" "$A/08-fresh-worker-handoff.txt" \
  "NO CONVERSATION HISTORY" "selected_mode:" "Unsupported assumptions"
assert_file_has "step 9 (compiler verdicts) artifact"  "$A/09-compiler-verdicts.txt" \
  "VERDICT: ELIGIBLE" "VERDICT: NOT-ELIGIBLE"
assert_file_has "step 10 (compiler status) artifact"   "$A/10-compiler-status.txt" \
  "IMPLEMENTED" "INERT" "PERFORMANCE-UNMEASURED" "NO A/B RESULT EXISTS YET"

# ------------------------------------------------ the block REALLY blocks -----
assert_file_has "the block step really blocks (hook exit 2)" "$A/03-blocked-and-recovered.txt" \
  "BLOCKED-EXIT: 2"
assert_file_has "the recovery really unblocks (hook exit 0)" "$A/03-blocked-and-recovered.txt" \
  "RECOVERED-EXIT: 0"

# ------------------------------------ both compiler verdict states reachable --
assert_file_has "compiler verdict state ELIGIBLE is reachable" "$A/09-compiler-verdicts.txt" \
  "VERDICT: ELIGIBLE"
assert_file_has "compiler verdict state BYPASS is reachable"   "$A/09-compiler-verdicts.txt" \
  "VERDICT: NOT-ELIGIBLE" "RECOMMENDED USE STATE: bypass"

# ------------------------------------------- customer display vocabulary ------
CUST="$A/05-customer-display.txt"
if [ -f "$CUST" ]; then
  LEAK="$(grep -nEi 'packet|census|archivist|gravito_full|DC-[0-9]{4}|mandatory_full_regate' "$CUST" || true)"
  if [ -z "$LEAK" ]; then
    ok "customer display speaks no internal vocabulary"
  else
    bad "customer display speaks no internal vocabulary" "$LEAK"
  fi
else
  bad "customer display speaks no internal vocabulary" "no $CUST"
fi

# ------------------------------------------------------ DEMO_SCRIPT.md --------
assert_file_has "DEMO_SCRIPT.md volunteers the honest caveats" "$SCRIPT_MD" \
  "NOT A SANDBOX" "NEXT SESSION" "NOT VISIBLE LIVE" "INTERNAL EVIDENCE ONLY"
assert_file_has "DEMO_SCRIPT.md labels the compiler performance-unmeasured" "$SCRIPT_MD" \
  "performance-unmeasured"

# -------------------------------------------- no fabricated metric claims -----
# A percentage in the demo tree is admissible ONLY on a line that marks it as a
# hypothesis / preregistration quote / explicitly unmeasured. A bare "60%
# faster" presented as a result is what this refuses.
FAB="$(grep -rnE '[0-9] ?%' "$DEMO_DIR" 2>/dev/null \
        | grep -viE 'hypothes|prereg|unmeasured|not measured|no result' || true)"
if [ -z "$FAB" ]; then
  ok "demo tree contains no fabricated metric claim"
else
  bad "demo tree contains no fabricated metric claim" "$FAB"
fi

# --------------------------------------- the frozen experiment repo is untouched
FROZEN="$(grep -rn 'empathiq' "$DEMO_DIR" 2>/dev/null || true)"
if [ -z "$FROZEN" ]; then
  ok "no path under the demo references the frozen experiment repository"
else
  bad "no path under the demo references the frozen experiment repository" "$FROZEN"
fi

# --------------------------------------------------------- resumability ------
LOG2="$WS_ROOT/demo-resume.log"
bash "$RUN" --auto --workspace "$WS" --resume > "$LOG2" 2>&1
RC2=$?
if [ "$RC2" -eq 0 ] && grep -q 'SKIP step' "$LOG2"; then
  ok "the demo is resumable (a completed workspace re-runs green and skips done steps)"
else
  bad "the demo is resumable (a completed workspace re-runs green and skips done steps)" \
    "exit $RC2; skip lines: $(grep -c 'SKIP step' "$LOG2" 2>/dev/null || echo 0)"
fi

# ------------------------------------------------------------- --list ---------
LIST="$(bash "$RUN" --list 2>&1)"
NSTEPS="$(printf '%s\n' "$LIST" | grep -cE '^ *(10|[1-9])\.' || true)"
if [ "$NSTEPS" -eq 10 ]; then
  ok "--list names exactly ten steps"
else
  bad "--list names exactly ten steps" "counted $NSTEPS"
fi

# ------------------------------------- the demo wrote nothing into this repo ---
AFTER="$(cd "$REPO" && git status --porcelain 2>/dev/null | sort)"
if [ "$BEFORE" = "$AFTER" ]; then
  ok "the demo run left this repository's working tree unchanged"
else
  bad "the demo run left this repository's working tree unchanged" \
    "$(diff <(printf '%s\n' "$BEFORE") <(printf '%s\n' "$AFTER") | head -n 10)"
fi

printf '\n==== RESULT: %s passed, %s failed ====\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
