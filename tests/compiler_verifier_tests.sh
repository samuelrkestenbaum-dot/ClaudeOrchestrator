#!/usr/bin/env bash
# Build OS — CONTEXT COMPILER, SEAM 6: uncertainty estimation and verifier routing.
#
# WHY THIS SUITE EXISTS (executed evidence, not preference):
#   EXP-0002 measured Gravito ON at 3.96x the tokens of OFF, driven by
#   uncontrolled Full-mode fan-out. PILOT-0001's one Full verifier examined six
#   risk areas, found the implementation clean, and changed NOTHING — confidence
#   delivered, no unique implementation value. So verification must be EARNED by
#   a named trigger, never automatic. SEAM 6 makes that mechanical; these tests
#   pin it.
#
# The three things this suite refuses to let drift:
#   1. THE DEFAULT IS NO VERIFIER. A clean, small, tested diff routes to `none`.
#      If that ever stops being true the economics lesson has been un-learned.
#   2. ABSENCE IS NOT SAFETY. A missing test result fires the incomplete-tests
#      trigger; a missing confidence signal is recorded `unavailable` and is
#      never read as "high". An unknown is not a zero.
#   3. SCOPE IS DERIVED, NOT ASSUMED. A security trigger scopes the verifier to
#      the sensitive files, not the whole diff — targeting is what makes an
#      earned verification cheap.
#
# Plus: thresholds must SAY how they were derived (no magic constants), the
# authority path must refuse a full verifier dispatched above the recorded
# routing mode without an escalation record (routing_contract.md's binding
# verdict, mirrored), and trigger efficacy must be able to report — honestly —
# that a trigger has never caught anything.
#
# No network. Deterministic. Temp dirs only. Node stdlib + bash only.
# Exits non-zero if any assertion fails; prints "==== RESULT: N passed, M failed ====".
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VDIR="$SRC/build-os/compiler/verify"
ASSESS="$VDIR/assess.mjs"
ROUTE="$VDIR/route-verifier.mjs"
LOG="$VDIR/contribution-log.mjs"
TRIG="$VDIR/triggers.mjs"
FIXTURE="$VDIR/fixtures/index.sample.json"
SEAMS="$SRC/build-os/compiler/SEAMS.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
eq(){ if [ "$1" = "$2" ]; then ok "$3"; else no "$3 [got: '$1' want: '$2']"; fi; }
ne(){ if [ "$1" != "$2" ]; then ok "$3"; else no "$3 [got the forbidden value: '$1']"; fi; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Read a dotted path out of a JSON file. "<undef>" when the path does not exist,
# so a typo in a test path fails loudly instead of comparing empty to empty.
getj(){ node -e '
const fs=require("fs");
let d; try { d=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); } catch(e){ process.stdout.write("<unparseable>"); process.exit(0); }
let v=d; for (const k of process.argv[2].split(".")) { if (v===null||v===undefined) { v=undefined; break; } v=v[k]; }
process.stdout.write(v===undefined?"<undef>":(typeof v==="object"?JSON.stringify(v):String(v)));
' "$1" "$2"; }

# Build a descriptor from the base by overriding keys. A null override DELETES
# the key — that is how the absent-signal cases are constructed.
patch(){ node -e '
const fs=require("fs");
const b=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
const o=JSON.parse(process.argv[3]);
for (const k of Object.keys(o)) { if (o[k]===null) delete b[k]; else b[k]=o[k]; }
fs.writeFileSync(process.argv[2], JSON.stringify(b,null,2));
' "$BASE" "$1" "$2"; }

# run <tool> <input-file> -> writes $WORK/out.json + $WORK/err.txt, echoes exit code
run(){ node "$1" < "$2" > "$WORK/out.json" 2> "$WORK/err.txt"; echo $?; }

echo "== 0. VACUITY GUARD — every assertion below runs a file; prove the files exist =="
MISSING=0
for f in "$ASSESS" "$ROUTE" "$LOG" "$TRIG" "$FIXTURE"; do
  [ -f "$f" ] || { MISSING=$((MISSING+1)); echo "      | missing: $f"; }
done
if [ "$MISSING" -eq 0 ]; then
  ok "all five SEAM 6 artifacts exist (3 tools, 1 shared vocabulary, 1 index fixture)"
else
  no "$MISSING of 5 SEAM 6 artifacts are missing — every test below would be vacuous"
  echo; echo "==== RESULT: $PASS passed, $FAIL failed ===="; exit 1
fi
if grep -qF "SEAM 6" "$SEAMS"; then
  ok "SEAMS.md still declares SEAM 6 (the contract these tools implement)"
else
  no "SEAMS.md no longer declares SEAM 6 — the contract these tools claim to implement is gone"
fi

# The fixture is a SEAM 1 index. It is SHIPPED (not inlined here) so that the
# sample a human reads is the same one the tests exercise; a rotted sample fails.
# NB: read the per-file entry with a direct key lookup — a dotted-path helper
# cannot address a key that itself contains dots ("src/cart.mjs").
FIXKIND="$(node -e 'const fs=require("fs");const i=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));process.stdout.write(String((i.files&&i.files["src/cart.mjs"]||{}).kind))' "$FIXTURE" 2>/dev/null)"
if [ "$(getj "$FIXTURE" 'index_version')" != "<undef>" ] && [ "$FIXKIND" = "source" ]; then
  ok "the shipped index fixture is a well-formed SEAM 1 index (index_version + per-file kind)"
else
  no "the shipped index fixture does not match SEAM 1's shape"
fi

BASE="$WORK/base.json"
cat > "$BASE" <<JSON
{
  "task_id": "T-CLEAN",
  "changed_files": ["src/cart.mjs", "src/pricing.mjs"],
  "lines_changed": 40,
  "test_result": "pass",
  "worker_confidence": "high",
  "prior_attempt_failed": false,
  "baseline_ambiguous": false,
  "index_path": "$FIXTURE"
}
JSON

echo
echo "== 1. THE ECONOMICS DEFAULT — a clean, small, tested diff earns NO verifier =="
RC="$(run "$ASSESS" "$BASE")"
eq "$RC" "0" "assess exits 0 on a complete descriptor"
eq "$(getj "$WORK/out.json" 'verification_earned')" "false" "clean small tested diff: verification_earned=false (EXP-0002's lesson, mechanical)"
eq "$(getj "$WORK/out.json" 'fired')" "[]" "clean small tested diff: NO trigger fires"
cp "$WORK/out.json" "$WORK/clean.assess.json"

echo
echo "== 2. EACH OF THE SIX SEAM 6 TRIGGERS IS SILENT ON A CLEAN OUTCOME =="
for t in incomplete_tests security_surface low_confidence diff_over_risk_threshold ambiguous_baseline prior_failed_attempt; do
  eq "$(getj "$WORK/clean.assess.json" "triggers.$t.fired")" "false" "trigger '$t' stays silent when its condition is absent"
done
eq "$(getj "$WORK/clean.assess.json" 'triggers.incomplete_tests.why')" "$(getj "$WORK/clean.assess.json" 'triggers.incomplete_tests.why')" "each trigger carries a 'why' string in both states"
for t in incomplete_tests security_surface low_confidence diff_over_risk_threshold ambiguous_baseline prior_failed_attempt; do
  ne "$(getj "$WORK/clean.assess.json" "triggers.$t.why")" "<undef>" "silent trigger '$t' still states WHY it did not fire (a silent trigger is a claim, and claims carry reasons)"
done

echo
echo "== 3. EACH TRIGGER FIRES ON ITS OWN CONDITION — one at a time, no crosstalk =="

# 3a. incomplete tests — a changed source file with an empty tests_covering list.
patch "$WORK/d_inc.json" '{"task_id":"T-INC","changed_files":["src/legacy-report.mjs"]}'
run "$ASSESS" "$WORK/d_inc.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.incomplete_tests.fired')" "true" "incomplete_tests FIRES on a changed source file with no covering test"
eq "$(getj "$WORK/out.json" 'triggers.security_surface.fired')" "false" "  ...and does not drag security_surface with it (no crosstalk)"
eq "$(getj "$WORK/out.json" 'verification_earned')" "true" "  ...and verification is earned"
eq "$(getj "$WORK/out.json" 'fired')" '["incomplete_tests"]' "  ...and the FIRING LIST names exactly the one trigger"

# 3b. security/authority-sensitive surface.
patch "$WORK/d_sec.json" '{"task_id":"T-SEC","changed_files":["src/cart.mjs","build-os/tools/route-task.sh"]}'
run "$ASSESS" "$WORK/d_sec.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.security_surface.fired')" "true" "security_surface FIRES when an authority-bearing path is touched"
eq "$(getj "$WORK/out.json" 'fired')" '["security_surface"]' "  ...alone: a covered sensitive file does not also fire incomplete_tests"
ne "$(getj "$WORK/out.json" 'triggers.security_surface.evidence.matched.0.pattern_why')" "<undef>" "  ...and every sensitive-path match names WHY that pattern is sensitive"

# 3c. worker-reported low confidence.
patch "$WORK/d_conf.json" '{"task_id":"T-CONF","worker_confidence":"low"}'
run "$ASSESS" "$WORK/d_conf.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.low_confidence.fired')" "true" "low_confidence FIRES on a worker-reported low confidence"
eq "$(getj "$WORK/out.json" 'confidence')" "low" "  ...and the reported value is recorded verbatim"
eq "$(getj "$WORK/out.json" 'fired')" '["low_confidence"]' "  ...alone"

# 3d. diff over the risk threshold — by FILE COUNT.
patch "$WORK/d_riskf.json" '{"task_id":"T-RISKF","changed_files":["src/cart.mjs","src/pricing.mjs","tests/cart.test.mjs","tests/pricing.test.mjs"]}'
run "$ASSESS" "$WORK/d_riskf.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.diff_over_risk_threshold.fired')" "true" "diff_over_risk_threshold FIRES at the derived file-count threshold"
eq "$(getj "$WORK/out.json" 'fired')" '["diff_over_risk_threshold"]' "  ...alone (the extra files are tests, which need no coverage of their own)"

# 3e. diff over the risk threshold — by LINE COUNT, one file only.
patch "$WORK/d_riskl.json" '{"task_id":"T-RISKL","changed_files":["src/cart.mjs"],"lines_changed":5000}'
run "$ASSESS" "$WORK/d_riskl.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.diff_over_risk_threshold.fired')" "true" "diff_over_risk_threshold FIRES on line count alone (one enormous file is still a large diff)"

# 3f. ambiguous baseline.
patch "$WORK/d_base.json" '{"task_id":"T-BASE","baseline_ambiguous":true}'
run "$ASSESS" "$WORK/d_base.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.ambiguous_baseline.fired')" "true" "ambiguous_baseline FIRES when the baseline was not cleanly measured"
eq "$(getj "$WORK/out.json" 'fired')" '["ambiguous_baseline"]' "  ...alone"

# 3g. prior failed attempt.
patch "$WORK/d_prior.json" '{"task_id":"T-PRIOR","prior_attempt_failed":true}'
run "$ASSESS" "$WORK/d_prior.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.prior_failed_attempt.fired')" "true" "prior_failed_attempt FIRES on a recorded prior failure on this task"
eq "$(getj "$WORK/out.json" 'fired')" '["prior_failed_attempt"]' "  ...alone"

echo
echo "== 4. THE HONESTY RULE — an ABSENT signal is never a SAFE signal =="

# 4a. Missing test result => incomplete_tests fires. Absence is not coverage.
patch "$WORK/d_notest.json" '{"task_id":"T-NOTEST","test_result":null}'
run "$ASSESS" "$WORK/d_notest.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.incomplete_tests.fired')" "true" "a MISSING test result fires incomplete_tests (absence of a result is not evidence of coverage)"
eq "$(getj "$WORK/out.json" 'signals.test_result')" "absent" "  ...and the signal is recorded 'absent', not silently normalised to 'pass'"

# 4b. Explicit "absent" is identical to a missing key — no honesty loophole.
patch "$WORK/d_absent.json" '{"task_id":"T-NOTEST","test_result":"absent"}'
run "$ASSESS" "$WORK/d_absent.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.incomplete_tests.fired')" "true" "an EXPLICIT test_result 'absent' fires identically to an omitted key"

# 4c. Missing confidence => recorded unavailable, trigger does NOT fire.
patch "$WORK/d_noconf.json" '{"task_id":"T-NOCONF","worker_confidence":null}'
run "$ASSESS" "$WORK/d_noconf.json" > /dev/null
eq "$(getj "$WORK/out.json" 'confidence')" "unavailable" "a MISSING confidence signal is recorded 'unavailable' — never assumed high"
eq "$(getj "$WORK/out.json" 'triggers.low_confidence.fired')" "false" "  ...and low_confidence does NOT fire on an absent signal (absence is not a low report either)"
eq "$(getj "$WORK/out.json" 'fired')" "[]" "  ...so an otherwise-clean outcome with no confidence signal still earns no verifier"

# 4d. A changed file that the index has never seen => unknown coverage => fires.
patch "$WORK/d_unindexed.json" '{"task_id":"T-UNIDX","changed_files":["src/brand-new.mjs"]}'
run "$ASSESS" "$WORK/d_unindexed.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.incomplete_tests.fired')" "true" "a changed file ABSENT from the index fires incomplete_tests (unknown coverage != covered)"
eq "$(getj "$WORK/out.json" 'triggers.incomplete_tests.evidence.unknown_coverage')" '["src/brand-new.mjs"]' "  ...and it is reported under UNKNOWN coverage, distinct from measured-uncovered"

# 4e. SEAM 1's null-means-not-measured, honoured: tests_covering:null != no tests.
patch "$WORK/d_null.json" '{"task_id":"T-NULLCOV","changed_files":["src/opaque.mjs"]}'
run "$ASSESS" "$WORK/d_null.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.incomplete_tests.fired')" "true" "tests_covering:null (SEAM 1 'not measured') fires incomplete_tests"
eq "$(getj "$WORK/out.json" 'triggers.incomplete_tests.evidence.unknown_coverage')" '["src/opaque.mjs"]' "  ...classified as unknown, not as measured-uncovered (the two are not the same claim)"

# 4f. A RED test is not an incomplete test. It is recorded, not laundered.
patch "$WORK/d_fail.json" '{"task_id":"T-FAIL","test_result":"fail"}'
run "$ASSESS" "$WORK/d_fail.json" > /dev/null
eq "$(getj "$WORK/out.json" 'signals.test_result')" "fail" "a failing test result is recorded verbatim"
eq "$(getj "$WORK/out.json" 'triggers.incomplete_tests.fired')" "false" "  ...and does NOT fire incomplete_tests — red is a defect to fix, not an uncertainty to verify"

echo
echo "== 5. THRESHOLD DERIVATION — no magic constants; every threshold says where it came from =="
FT="$(getj "$WORK/clean.assess.json" 'thresholds.files.value')"
eq "$FT" "4" "the file-count threshold is 4"
if getj "$WORK/clean.assess.json" 'thresholds.files.derivation' | grep -qF "mode-select"; then
  ok "  ...and its derivation CITES build-os/tools/mode-select.mjs (the repo's one executed definition of a multi-step diff), rather than inventing a number"
else
  no "  ...but its derivation does not cite mode-select.mjs — that is a magic constant with prose attached"
fi
ne "$(getj "$WORK/clean.assess.json" 'thresholds.lines.value')" "<undef>" "a line-count threshold is derived and reported"
ne "$(getj "$WORK/clean.assess.json" 'thresholds.lines.derivation')" "<undef>" "  ...with a stated derivation"
eq "$(getj "$WORK/clean.assess.json" 'thresholds.lines.calibration')" "measured_from_index" "  ...calibrated from the index when the index carries line counts"
eq "$(getj "$WORK/clean.assess.json" 'thresholds.lines.value')" "480" "  ...as files_threshold x the index's median source-file length (4 x 120)"

# The fallback must LABEL itself as unmeasured. An uncalibrated default that
# looks calibrated is exactly the dishonesty this seam exists to prevent.
cat > "$WORK/index_nolines.json" <<'JSON'
{ "index_version": 1, "repo_head": "0", "generated_at": "2026-01-01T00:00:00Z",
  "files": { "src/cart.mjs": { "blob": "a", "lang": "javascript", "kind": "source",
      "symbols": [], "imports": [], "imported_by": [],
      "tests_covering": ["tests/cart.test.mjs"], "last_changed": "2026-01-01T00:00:00Z",
      "error_count": null } } }
JSON
patch "$WORK/d_nolines.json" "{\"task_id\":\"T-NOLINES\",\"changed_files\":[\"src/cart.mjs\"],\"index_path\":\"$WORK/index_nolines.json\"}"
run "$ASSESS" "$WORK/d_nolines.json" > /dev/null
eq "$(getj "$WORK/out.json" 'thresholds.lines.calibration')" "unmeasured_declared_default" "with no line counts in the index, the line threshold LABELS ITSELF unmeasured rather than posing as calibrated"

echo
echo "== 6. REFUSAL OF PARTIAL DESCRIPTORS — an unknown is not a zero (mode-select's convention) =="
patch "$WORK/d_nobase.json" '{"baseline_ambiguous":null}'
eq "$(run "$ASSESS" "$WORK/d_nobase.json")" "2" "a descriptor omitting baseline_ambiguous is REFUSED (exit 2), not guessed as false"
patch "$WORK/d_noprior.json" '{"prior_attempt_failed":null}'
eq "$(run "$ASSESS" "$WORK/d_noprior.json")" "2" "a descriptor omitting prior_attempt_failed is REFUSED (exit 2)"
patch "$WORK/d_nofiles.json" '{"changed_files":null}'
eq "$(run "$ASSESS" "$WORK/d_nofiles.json")" "2" "a descriptor omitting changed_files is REFUSED (exit 2)"
patch "$WORK/d_noindex.json" '{"index_path":null}'
eq "$(run "$ASSESS" "$WORK/d_noindex.json")" "2" "a descriptor with no index source is REFUSED (exit 2) — coverage cannot be assumed without one"
printf 'not json at all' > "$WORK/d_bad.json"
eq "$(run "$ASSESS" "$WORK/d_bad.json")" "2" "malformed JSON is refused (exit 2)"
if grep -qi "refus\|must be\|required" "$WORK/err.txt"; then
  ok "refusals print a diagnosis on stderr rather than failing mutely"
else
  no "a refusal produced no explanatory stderr"
fi

echo
echo "== 7. SCOPE DERIVATION — what the verifier examines follows from WHICH trigger fired =="
run "$ASSESS" "$WORK/d_sec.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.security_surface.scope.files')" '["build-os/tools/route-task.sh"]' "a security trigger scopes to the SENSITIVE FILES, not the whole diff (src/cart.mjs is excluded)"
eq "$(getj "$WORK/out.json" 'triggers.security_surface.scope.kind')" "sensitive_files" "  ...and names its scope kind"

patch "$WORK/d_mixed.json" '{"task_id":"T-MIX","changed_files":["src/cart.mjs","src/legacy-report.mjs"]}'
run "$ASSESS" "$WORK/d_mixed.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.incomplete_tests.scope.files')" '["src/legacy-report.mjs"]' "an incomplete-tests trigger scopes to the UNCOVERED file only, not to the covered one beside it"

run "$ASSESS" "$WORK/d_base.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.ambiguous_baseline.scope.unscopable_by_file')" "true" "an ambiguous baseline declares itself UNSCOPABLE by file — you cannot narrow an examination against an unknown baseline"
run "$ASSESS" "$WORK/d_conf.json" > /dev/null
eq "$(getj "$WORK/out.json" 'triggers.low_confidence.scope.unscopable_by_file')" "false" "a low-confidence report IS scopable — it is bounded by the files the worker actually changed"

echo
echo "== 8. ROUTING — none / targeted / full, each derived and stated =="
mkauth(){ node -e '
const fs=require("fs");
const a=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
fs.writeFileSync(process.argv[2], JSON.stringify({assessment:a, authority:JSON.parse(process.argv[3])},null,2));
' "$1" "$2" "$3"; }

FULLAUTH='{"mode":"gravito_full","receipt":"build-os/packets/routing/R-1.md"}'
LIGHTAUTH='{"mode":"gravito_light","receipt":"build-os/packets/routing/R-2.md"}'
DIRECTAUTH='{"mode":"direct","receipt":"build-os/packets/routing/R-3.md"}'

mkauth "$WORK/clean.assess.json" "$WORK/r_none.json" "$DIRECTAUTH"
eq "$(run "$ROUTE" "$WORK/r_none.json")" "0" "route exits 0 on a clean assessment"
eq "$(getj "$WORK/out.json" 'decision')" "none" "no trigger fired => decision 'none' (the default path costs nothing)"
eq "$(getj "$WORK/out.json" 'scope.files')" "[]" "  ...with an empty scope"
eq "$(getj "$WORK/out.json" 'scope.questions')" "[]" "  ...and no examination questions"
ne "$(getj "$WORK/out.json" 'decision_derivation')" "<undef>" "  ...and the decision states how it was derived"

run "$ASSESS" "$WORK/d_sec.json" > "$WORK/a_sec.json"; cp "$WORK/out.json" "$WORK/a_sec.json"
mkauth "$WORK/a_sec.json" "$WORK/r_sec.json" "$LIGHTAUTH"
eq "$(run "$ROUTE" "$WORK/r_sec.json")" "0" "route exits 0 on a security-only assessment under light authority"
eq "$(getj "$WORK/out.json" 'decision')" "targeted" "one scopable trigger => TARGETED verifier, not full"
eq "$(getj "$WORK/out.json" 'scope.files')" '["build-os/tools/route-task.sh"]' "  ...scoped to the sensitive file alone"
eq "$(getj "$WORK/out.json" 'scope.questions')" "$(getj "$WORK/out.json" 'scope.questions')" "  ...carrying examination questions"
if getj "$WORK/out.json" 'scope.questions' | grep -qF "security_surface"; then
  ok "  ...and each question names the trigger that bought it"
else
  no "  ...but the questions do not name their originating triggers"
fi

run "$ASSESS" "$WORK/d_base.json" > /dev/null; cp "$WORK/out.json" "$WORK/a_base.json"
mkauth "$WORK/a_base.json" "$WORK/r_base.json" "$FULLAUTH"
eq "$(run "$ROUTE" "$WORK/r_base.json")" "0" "route exits 0 on an ambiguous-baseline assessment under full authority"
eq "$(getj "$WORK/out.json" 'decision')" "full" "an UNSCOPABLE trigger => FULL verifier (nothing can be narrowed)"

# Breadth clause: three scopable triggers covering the entire changed set.
patch "$WORK/d_broad.json" '{"task_id":"T-BROAD","changed_files":["src/cart.mjs","src/pricing.mjs","src/legacy-report.mjs","build-os/tools/route-task.sh"],"worker_confidence":"low"}'
run "$ASSESS" "$WORK/d_broad.json" > /dev/null; cp "$WORK/out.json" "$WORK/a_broad.json"
eq "$(getj "$WORK/a_broad.json" 'fired')" '["incomplete_tests","security_surface","low_confidence","diff_over_risk_threshold"]' "a broad outcome fires four triggers, listed in the SEAM 6 order"
mkauth "$WORK/a_broad.json" "$WORK/r_broad.json" "$FULLAUTH"
run "$ROUTE" "$WORK/r_broad.json" > /dev/null
eq "$(getj "$WORK/out.json" 'decision')" "full" "3+ triggers whose scopes already cover the whole diff => FULL (targeting would buy nothing)"

echo
echo "== 9. AUTHORITY — the recorded routing mode binds the verifier dispatch =="
mkauth "$WORK/a_base.json" "$WORK/r_refuse.json" "$DIRECTAUTH"
eq "$(run "$ROUTE" "$WORK/r_refuse.json")" "2" "a DIRECT-mode receipt dispatching a FULL verifier is REFUSED (exit 2) — routing_contract.md's binding verdict"
if grep -qi "escalation" "$WORK/err.txt"; then
  ok "  ...and the refusal names the escalation record that would be required"
else
  no "  ...but the refusal does not say what record would make the dispatch legal"
fi

mkauth "$WORK/a_sec.json" "$WORK/r_refuse2.json" "$DIRECTAUTH"
eq "$(run "$ROUTE" "$WORK/r_refuse2.json")" "2" "a DIRECT-mode receipt dispatching a TARGETED verifier is REFUSED (any dispatch is above direct authority)"

mkauth "$WORK/clean.assess.json" "$WORK/r_ok_direct.json" "$DIRECTAUTH"
eq "$(run "$ROUTE" "$WORK/r_ok_direct.json")" "0" "a DIRECT-mode receipt deciding 'none' is fine — no dispatch, no authority needed"

mkauth "$WORK/a_sec.json" "$WORK/r_deesc.json" "$FULLAUTH"
run "$ROUTE" "$WORK/r_deesc.json" > /dev/null
eq "$(getj "$WORK/out.json" 'decision')" "targeted" "a FULL-mode receipt may route a TARGETED verifier — de-escalation is free and needs no record"
eq "$(getj "$WORK/out.json" 'authority.escalated')" "false" "  ...and is not recorded as an escalation"

ESC='{"mode":"direct","receipt":"build-os/packets/routing/R-3.md","escalation":"direct -> gravito_full","escalation_evidence":"baseline could not be measured: two prior runs disagree on the failing set"}'
mkauth "$WORK/a_base.json" "$WORK/r_esc.json" "$ESC"
eq "$(run "$ROUTE" "$WORK/r_esc.json")" "0" "a DIRECT-mode receipt WITH an evidence-bearing escalation record may dispatch a full verifier"
eq "$(getj "$WORK/out.json" 'authority.escalated')" "true" "  ...and the dispatch is stamped as escalated"

ESC_NOEV='{"mode":"direct","receipt":"r.md","escalation":"direct -> gravito_full","escalation_evidence":"-"}'
mkauth "$WORK/a_base.json" "$WORK/r_escnoev.json" "$ESC_NOEV"
eq "$(run "$ROUTE" "$WORK/r_escnoev.json")" "2" "an escalation record with NO evidence ('-') is refused — evidence-free escalation is not escalation"

# SEAM 2 spells authority modes direct|light|full; mode-select emits gravito_*.
mkauth "$WORK/a_sec.json" "$WORK/r_alias.json" '{"mode":"light","receipt":"r.md"}'
eq "$(run "$ROUTE" "$WORK/r_alias.json")" "0" "SEAM 2's 'light' spelling is accepted as gravito_light (one vocabulary, two spellings, no silent mismatch)"

mkauth "$WORK/a_sec.json" "$WORK/r_badmode.json" '{"mode":"turbo","receipt":"r.md"}'
eq "$(run "$ROUTE" "$WORK/r_badmode.json")" "2" "an unrecognised authority mode is refused, never treated as permissive"

echo
echo "== 10. CONTRIBUTION LOG — the mechanism that lets the system LEARN which triggers pay =="
CLOG="$WORK/contrib.tsv"
rec(){ node "$LOG" record "$CLOG" "$1" > "$WORK/rec.out" 2> "$WORK/rec.err"; echo $?; }

R1='{"task_id":"T1","decision":"targeted","triggers":["security_surface"],"verifier_ref":"v1.md","changed_implementation":"y","changed_conclusion":"n","caught_defect":"y","duplicated_work":"n"}'
R2='{"task_id":"T2","decision":"targeted","triggers":["security_surface","incomplete_tests"],"verifier_ref":"v2.md","changed_implementation":"n","changed_conclusion":"n","caught_defect":"n","duplicated_work":"y"}'
R3='{"task_id":"T3","decision":"full","triggers":["incomplete_tests"],"verifier_ref":"v3.md","changed_implementation":"n","changed_conclusion":"n","caught_defect":"n","duplicated_work":"y"}'
R4='{"task_id":"T4","decision":"targeted","triggers":["low_confidence"],"verifier_ref":"v4.md","changed_implementation":"-","changed_conclusion":"-","caught_defect":"-","duplicated_work":"-"}'
eq "$(rec "$R1")" "0" "a contribution row is recorded (exit 0)"
eq "$(rec "$R2")" "0" "a second row is appended"
eq "$(rec "$R3")" "0" "a third row is appended"
eq "$(rec "$R4")" "0" "an all-'-' row is accepted as an ADMISSION (routing_contract.md: refusal is for contradiction, not absence)"
eq "$(wc -l < "$CLOG" | tr -d ' ')" "4" "the log holds exactly four rows"
for f in changed_implementation changed_conclusion caught_defect duplicated_work; do
  if grep -q "$f=" "$CLOG"; then ok "rows carry the routing receipt's '$f' field (one vocabulary across the system)"; else no "rows are missing '$f' — the vocabulary has forked"; fi
done
BAD='{"task_id":"T5","decision":"targeted","triggers":["low_confidence"],"verifier_ref":"v5.md","changed_implementation":"maybe","changed_conclusion":"n","caught_defect":"n","duplicated_work":"n"}'
eq "$(rec "$BAD")" "2" "a value outside y/n/- is refused (exit 2)"
NODISPATCH='{"task_id":"T6","decision":"none","triggers":[],"verifier_ref":"-","changed_implementation":"-","changed_conclusion":"-","caught_defect":"-","duplicated_work":"-"}'
eq "$(rec "$NODISPATCH")" "2" "a row for decision 'none' is refused — no verifier ran, so there is no contribution to claim"
eq "$(wc -l < "$CLOG" | tr -d ' ')" "4" "refused rows do not reach the log"

echo
echo "== 11. TRIGGER EFFICACY — including the honest never-caught-anything case =="
node "$LOG" efficacy "$CLOG" > "$WORK/eff.json" 2> "$WORK/eff.err"
eq "$?" "0" "the efficacy report is produced (exit 0)"
eq "$(getj "$WORK/eff.json" 'triggers.security_surface.verifications')" "2" "security_surface: fired into 2 verifications"
eq "$(getj "$WORK/eff.json" 'triggers.security_surface.caught_defect')" "1" "security_surface: caught 1 defect"
eq "$(getj "$WORK/eff.json" 'triggers.security_surface.rated')" "2" "security_surface: 2 rated rows"
eq "$(getj "$WORK/eff.json" 'triggers.security_surface.caught_rate')" "0.5" "security_surface: caught_rate = 1/2 = 0.5"
eq "$(getj "$WORK/eff.json" 'triggers.security_surface.never_caught_a_defect')" "false" "security_surface has caught something"

eq "$(getj "$WORK/eff.json" 'triggers.incomplete_tests.verifications')" "2" "incomplete_tests: fired into 2 verifications"
eq "$(getj "$WORK/eff.json" 'triggers.incomplete_tests.caught_defect')" "0" "incomplete_tests: caught nothing"
eq "$(getj "$WORK/eff.json" 'triggers.incomplete_tests.caught_rate')" "0" "incomplete_tests: caught_rate = 0/2 = 0"
eq "$(getj "$WORK/eff.json" 'triggers.incomplete_tests.never_caught_a_defect')" "true" "incomplete_tests is REPORTED as never having caught anything — the whole point of measuring"
eq "$(getj "$WORK/eff.json" 'triggers.incomplete_tests.duplicated_work')" "2" "  ...while its verifications duplicated work twice (PILOT-0001's failure mode, counted)"

eq "$(getj "$WORK/eff.json" 'triggers.low_confidence.verifications')" "1" "low_confidence: fired into 1 verification"
eq "$(getj "$WORK/eff.json" 'triggers.low_confidence.rated')" "0" "  ...which was left unrated ('-')"
eq "$(getj "$WORK/eff.json" 'triggers.low_confidence.caught_rate')" "null" "  ...so its rate is null (unavailable), NOT 0 — an unknown is not a zero"
eq "$(getj "$WORK/eff.json" 'triggers.low_confidence.never_caught_a_defect')" "false" "  ...and it is not accused of never catching anything on unrated evidence"
ne "$(getj "$WORK/eff.json" 'triggers.low_confidence.rate_note')" "<undef>" "  ...with a note explaining why the rate is unavailable"

eq "$(getj "$WORK/eff.json" 'triggers.ambiguous_baseline.verifications')" "0" "a trigger that has never fired reports 0 verifications rather than being omitted"
eq "$(getj "$WORK/eff.json" 'triggers.ambiguous_baseline.caught_rate')" "null" "  ...with a null rate (no data is not a bad score)"
eq "$(getj "$WORK/eff.json" 'triggers.prior_failed_attempt.verifications')" "0" "all six SEAM 6 triggers appear in the report, fired or not"
eq "$(getj "$WORK/eff.json" 'totals.rows')" "4" "totals: 4 rows"
eq "$(getj "$WORK/eff.json" 'totals.rated')" "3" "totals: 3 rated, 1 unrated"
ne "$(getj "$WORK/eff.json" 'volume_note')" "<undef>" "the report carries a VOLUME caveat — a rate over 4 rows is noise, and says so"
if getj "$WORK/eff.json" 'volume_note' | grep -qiE "noise|not (yet )?(meaningful|evidence)|too few|volume"; then
  ok "  ...and the caveat is blunt about low volume rather than decorative"
else
  no "  ...but the caveat does not actually warn about low volume"
fi
eq "$(node "$LOG" efficacy "$WORK/empty.tsv" > "$WORK/eff_empty.json" 2>/dev/null; echo $?)" "0" "an efficacy report over a nonexistent/empty log succeeds (nothing measured yet is a legitimate state)"
eq "$(getj "$WORK/eff_empty.json" 'totals.rows')" "0" "  ...reporting 0 rows rather than inventing any"

echo
echo "== 12. DETERMINISM — same input, byte-identical output (SEAMS.md's hard requirement) =="
run "$ASSESS" "$BASE" > /dev/null; cp "$WORK/out.json" "$WORK/det1.json"
run "$ASSESS" "$BASE" > /dev/null; cp "$WORK/out.json" "$WORK/det2.json"
if cmp -s "$WORK/det1.json" "$WORK/det2.json"; then ok "assess is byte-identical across runs"; else no "assess output differs between identical runs"; fi
run "$ROUTE" "$WORK/r_broad.json" > /dev/null; cp "$WORK/out.json" "$WORK/rdet1.json"
run "$ROUTE" "$WORK/r_broad.json" > /dev/null; cp "$WORK/out.json" "$WORK/rdet2.json"
if cmp -s "$WORK/rdet1.json" "$WORK/rdet2.json"; then ok "route-verifier is byte-identical across runs"; else no "route-verifier output differs between identical runs"; fi
node "$LOG" efficacy "$CLOG" > "$WORK/eff2.json" 2>/dev/null
if cmp -s "$WORK/eff.json" "$WORK/eff2.json"; then ok "the efficacy report is byte-identical across runs"; else no "the efficacy report differs between identical runs"; fi
# Key order must be fixed too, or two honest runs on two machines disagree.
if [ "$(node -e 'const fs=require("fs");process.stdout.write(Object.keys(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).triggers).join(","))' "$WORK/det1.json")" \
   = "incomplete_tests,security_surface,low_confidence,diff_over_risk_threshold,ambiguous_baseline,prior_failed_attempt" ]; then
  ok "trigger keys are emitted in the fixed SEAM 6 order"
else
  no "trigger key order is not the fixed SEAM 6 order"
fi

echo
echo "== 13. PURITY — no clock, no randomness, no network, no dependencies =="
for f in "$ASSESS" "$ROUTE" "$LOG" "$TRIG"; do
  b="$(basename "$f")"
  if grep -qE "Math\.random|Date\.now|new Date\(" "$f"; then
    no "$b reads the clock or a random source — determinism cannot hold"
  else
    ok "$b is free of clock and randomness (determinism by construction)"
  fi
  if grep -qE "require\(['\"](?!node:)|from ['\"][^n.]" "$f" 2>/dev/null; then :; fi
  if grep -oE "from '[^']+'" "$f" | grep -vqE "from 'node:|from '\./"; then
    no "$b imports something outside node: builtins and its own directory"
  else
    ok "$b imports only node: builtins and its own siblings (no new dependencies)"
  fi
  if grep -qE "https?://[a-z]" "$f" | grep -vq "^#"; then
    no "$b appears to reference a network endpoint"
  else
    ok "$b makes no network reference"
  fi
done

echo
echo "== 14. THE EVIDENCE IS CITED IN THE CODE, not just in this suite =="
if grep -qF "EXP-0002" "$ASSESS" || grep -qF "EXP-0002" "$TRIG"; then
  ok "the estimator cites EXP-0002 (3.96x) — the measurement that makes 'earned' non-negotiable"
else
  no "no citation of EXP-0002 in the estimator: the rule looks like taste rather than evidence"
fi
if grep -qF "PILOT-0001" "$LOG" || grep -qF "PILOT-0001" "$TRIG" || grep -qF "PILOT-0001" "$ROUTE"; then
  ok "the contribution/routing path cites PILOT-0001 — the Full verifier that changed nothing"
else
  no "no citation of PILOT-0001: the duplicated-work column has no stated origin"
fi
if grep -qF "routing_contract" "$ROUTE"; then
  ok "the router cites routing_contract.md, whose binding-verdict rule it mirrors"
else
  no "the router does not cite the contract it mirrors"
fi

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
