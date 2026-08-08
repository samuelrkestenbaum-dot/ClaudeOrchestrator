#!/usr/bin/env bash
# Build OS — EXP-0004 BLINDING: the sealed arm mapping, the two separated
# blinded views, the immutable freeze snapshot, and the ONE-WAY reveal.
#
# WHY THIS SUITE EXISTS. EXP-0001/2/3 were credible because the arm mapping was
# sealed and its sha256 committed BEFORE analysis. EXP-0004 labels its records
# `A` and `B` with no blinding at all — at exactly the point where the incentive
# to see a favourable result is strongest. This suite proves, by execution, that
# the adjudicator and the analyst cannot tell which execution condition they are
# looking at, and that the mapping cannot be opened early.
#
# WHAT THIS SUITE PROVES, by execution:
#   1. The mapping is DERIVED, not sampled: sealing twice — from a different
#      task order — produces a byte-identical artifact, and the recorded rule
#      text re-derives it. No Math.random, no Date.now.
#   2. Changing ONE assignment changes the digest, so the committed sha256 is a
#      real commitment and not decoration.
#   3. The adjudicator view is leak-free: none of the eight forbidden strings,
#      no `arm` key, no A/B, no starting-context byte VALUE appears verbatim,
#      and every path it exposes is an opaque id rather than `armA_*`.
#   4. The analyst view carries `Arm X` / `Arm Y` and nothing else, and
#      starting-context bytes are WITHHELD until acceptance is frozen — an
#      adjudicator that sees one condition start at 8 KB infers treatment
#      instantly, so capsule size is blinded where it is feasible to blind it.
#   5. The freeze refuses while ANY of the fourteen required artifacts is
#      missing, and names the missing ones.
#   6. A changed input invalidates the frozen snapshot digest.
#   7. The reveal is one-way and conditional: it refuses before the freeze,
#      without the anonymous provisional verdict, on a digest mismatch, and on
#      a MUTATED sealed mapping. It refuses to read a clock.
#   8. THE LOAD-BEARING TEST — the same anonymous numbers translate to
#      `compression only` under one sealed bit and `context compilation
#      harmful` under the other. The blinding is therefore doing work: the
#      verdict is not recoverable from the blinded data alone.
#   9. The simulated matched pair walks end to end and lands on one of the
#      SEVEN registered outcomes, verbatim.
#
# No network. No model invocation. Deterministic. Every fixture lives in a
# mktemp dir; nothing under build-os/ is written by this suite, and nothing
# outside this repository is read or written.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
B="$SRC/build-os/experiments/EXP-0004-context-compiler/blinding"
SEAL="$B/seal-mapping.mjs"
VIEWS="$B/views.mjs"
FREEZE="$B/freeze.mjs"
REVEAL="$B/reveal.mjs"
FLOW="$B/run-blinded-flow.sh"
FIX="$B/fixtures"
RECORDS="$FIX/simulated-pair-records.json"
EXCL="$FIX/exclusion-decisions.json"
ELIG="$FIX/eligibility.json"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

TASKS="E4-T1,E4-T2,E4-T3,E4-T4,E4-T5"
TASKS_REORDERED="E4-T4,E4-T1,E4-T5,E4-T2,E4-T3"

# The eight strings that must never reach a blinded view, plus the arm-key and
# arm-letter patterns. Case-insensitive throughout.
FORBIDDEN="standard_context compiled_context capsule compiler control treatment arm_a arm_b"

leakfree(){ # $1 file  $2 label -> one PASS/FAIL per forbidden string
  local f="$1" what="$2" s
  for s in $FORBIDDEN; do
    if grep -qi -- "$s" "$f" 2>/dev/null; then
      no "$what leaks the forbidden string '$s'"
    else
      ok "$what is free of '$s'"
    fi
  done
  if grep -qiE '\barm[[:space:]_-]*[ab]([^[:alnum:]]|$)' "$f" 2>/dev/null; then
    no "$what names an execution arm by letter"
  else
    ok "$what names no execution arm by letter"
  fi
  if grep -q '"arm"' "$f" 2>/dev/null; then
    no "$what carries an \"arm\" key"
  else
    ok "$what carries no \"arm\" key"
  fi
}

echo "== 1. Layout: every blinding file exists and NONE is executable =="
for f in "$SEAL" "$VIEWS" "$FREEZE" "$REVEAL" "$FLOW" "$RECORDS" "$EXCL" "$ELIG"; do
  [ -f "$f" ] && ok "present: ${f#$SRC/}" || no "missing: ${f#$SRC/}"
  [ ! -x "$f" ] && ok "NOT executable (mode 644 by design): ${f#$SRC/}" || no "executable: ${f#$SRC/}"
done
# THE CENSUS, WITH ONE NARROW HISTORICAL EXCEPTION.
#
# build-os/experiments/EXP-0005-system-efficiency/harness/restore-seed.sh is
# tracked at mode 755 and is a FROZEN EXP-0005 artifact. The standing
# instruction forbids altering, rewriting, deleting or regenerating one, and a
# chmod is an alteration. The operator ruled that its immutability outranks a
# tidier census assumption, so it is exempted here rather than modified there.
#
# The exemption is deliberately unable to grow: ONE exact relative path and ONE
# exact expected mode, compared literally. No glob, no directory prefix, no
# "*.sh under EXP-*" -- a pattern would silently exempt every future experiment
# file, which is how a narrow exception becomes a blanket one.
FROZEN_EXEC_REL="EXP-0005-system-efficiency/harness/restore-seed.sh"
FROZEN_EXEC_MODE="755"

unexpected_execs(){ # <experiments-root> — every executable EXCEPT the one exemption
  find "$1" -type f -perm -u+x 2>/dev/null | while IFS= read -r p; do
    [ "${p#$1/}" = "$FROZEN_EXEC_REL" ] || printf '%s\n' "$p"
  done
}

NEXEC="$(unexpected_execs "$SRC/build-os/experiments" | grep -c . || true)"
[ "${NEXEC:-1}" = "0" ] \
  && ok "0 unexpected executables under build-os/experiments/ (the census holds, one frozen exception aside)" \
  || no "$NEXEC unexpected executable file(s) under build-os/experiments/: $(unexpected_execs "$SRC/build-os/experiments" | tr '\n' ' ')"

# The exemption is pinned to a MODE as well as a path: if the frozen file's own
# mode ever changes, that is itself a change to a frozen artifact and must fail.
FROZEN_ABS="$SRC/build-os/experiments/$FROZEN_EXEC_REL"
[ -f "$FROZEN_ABS" ] \
  && ok "the exempted frozen artifact is present where the exemption says it is" \
  || no "the exemption names a path that does not exist: $FROZEN_EXEC_REL"
[ "$(stat -c '%a' "$FROZEN_ABS" 2>/dev/null)" = "$FROZEN_EXEC_MODE" ] \
  && ok "...at exactly mode $FROZEN_EXEC_MODE — a change to the frozen file's own mode would fail here" \
  || no "the frozen artifact's mode is $(stat -c '%a' "$FROZEN_ABS" 2>/dev/null), not the pinned $FROZEN_EXEC_MODE"

# THE REGRESSION. An exemption nobody can see failing is an exemption that has
# quietly become a blanket. Proven against a FIXTURE tree so the real
# repository is never written to.
CENSUS_FIX="$(mktemp -d)"
mkdir -p "$CENSUS_FIX/EXP-0005-system-efficiency/harness" "$CENSUS_FIX/EXP-0009-decoy/harness"
: > "$CENSUS_FIX/$FROZEN_EXEC_REL"; chmod 755 "$CENSUS_FIX/$FROZEN_EXEC_REL"
: > "$CENSUS_FIX/EXP-0009-decoy/harness/new-tool.sh"; chmod 755 "$CENSUS_FIX/EXP-0009-decoy/harness/new-tool.sh"
FOUND="$(unexpected_execs "$CENSUS_FIX" | grep -c . || true)"
[ "$FOUND" = "1" ] \
  && ok "REGRESSION: a NEW executable under build-os/experiments/ is still caught (the exemption did not become a blanket)" \
  || no "a new executable under build-os/experiments/ was not caught (found $FOUND)"
unexpected_execs "$CENSUS_FIX" | grep -q "EXP-0009-decoy" \
  && ok "...and the one reported is the decoy, not the exempted frozen artifact" \
  || no "the census reported the wrong file"
rm -rf "$CENSUS_FIX"

echo
echo "== 2. The mapping is DERIVED from a recorded rule, not sampled =="
grep -qE 'Math\.random[[:space:]]*\(|Date\.now[[:space:]]*\(|new[[:space:]]+Date[[:space:]]*\(' "$SEAL" "$VIEWS" "$FREEZE" "$REVEAL" 2>/dev/null \
  && no "a blinding tool CALLS a random source or a wall clock" \
  || ok "no blinding tool calls Math.random(), Date.now(), or new Date()"

node "$SEAL" seal --rule experiment-salt-parity --salt "EXP0004-BLIND-v1" --tasks "$TASKS" --out "$WORK/m1" >"$WORK/seal1.log" 2>&1
RC=$?; [ "$RC" = "0" ] && ok "seal-mapping seals a mapping (exit 0)" || no "seal exited $RC: $(cat "$WORK/seal1.log")"
node "$SEAL" seal --rule experiment-salt-parity --salt "EXP0004-BLIND-v1" --tasks "$TASKS_REORDERED" --out "$WORK/m2" >/dev/null 2>&1
if cmp -s "$WORK/m1/mapping.sealed.json" "$WORK/m2/mapping.sealed.json"; then
  ok "sealing twice from a DIFFERENT task order is byte-identical (deterministic, order-independent)"
else
  no "the sealed artifact is not reproducible across task orderings"
fi
cmp -s "$WORK/m1/mapping.sha256" "$WORK/m2/mapping.sha256" \
  && ok "the committed digest is identical across the two sealings" \
  || no "the digest differs across two sealings of the same inputs"
grep -q '"rule_text"' "$WORK/m1/mapping.sealed.json" \
  && ok "the sealed artifact RECORDS the rule text it was derived by" \
  || no "the sealed artifact records no rule text"
grep -q '"salt"' "$WORK/m1/mapping.sealed.json" \
  && ok "the sealed artifact records the declared salt" \
  || no "the sealed artifact records no salt"
node "$SEAL" reproduce --sealed "$WORK/m1/mapping.sealed.json" >"$WORK/repro.log" 2>&1
RC=$?; [ "$RC" = "0" ] && ok "the mapping RE-DERIVES from its own recorded rule (reproduce exits 0)" || no "reproduce exited $RC"
node "$SEAL" verify --sealed "$WORK/m1/mapping.sealed.json" --digest "$WORK/m1/mapping.sha256" >/dev/null 2>&1
RC=$?; [ "$RC" = "0" ] && ok "verify accepts the sealed artifact against its committed digest" || no "verify exited $RC on an untouched pair"

echo
echo "== 3. A changed assignment changes the digest (the commitment is real) =="
cp -r "$WORK/m1" "$WORK/mut"
node -e '
  const fs=require("fs"); const f=process.argv[1];
  const j=JSON.parse(fs.readFileSync(f,"utf8"));
  j.units[0].label = j.units[0].label === "Arm X" ? "Arm Y" : "Arm X";
  fs.writeFileSync(f, JSON.stringify(j,null,2)+"\n");
' "$WORK/mut/mapping.sealed.json"
D_ORIG="$(cut -d" " -f1 < "$WORK/m1/mapping.sha256")"
D_MUT="$(node -e 'const c=require("crypto"),fs=require("fs");console.log(c.createHash("sha256").update(fs.readFileSync(process.argv[1])).digest("hex"))' "$WORK/mut/mapping.sealed.json")"
[ "$D_ORIG" != "$D_MUT" ] \
  && ok "flipping ONE assignment changes the sha256 ($D_ORIG -> $D_MUT)" \
  || no "the digest survived a changed assignment — the commitment is decoration"
node "$SEAL" verify --sealed "$WORK/mut/mapping.sealed.json" --digest "$WORK/mut/mapping.sha256" >"$WORK/vmut.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "verify REFUSES a sealed artifact that no longer matches its committed digest" || no "verify exited $RC on a mutated seal"
node "$SEAL" reproduce --sealed "$WORK/mut/mapping.sealed.json" >"$WORK/rmut.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "reproduce REFUSES a seal whose assignments no longer follow its own rule" || no "reproduce exited $RC on a mutated seal"

echo
echo "== 4. A per-task label flip is sealable but marked invalid for AGGREGATE analysis =="
node "$SEAL" seal --rule task-salt-parity --salt "EXP0004-BLIND-v1" --tasks "$TASKS" --out "$WORK/mt" >/dev/null 2>&1
RC=$?; [ "$RC" = "0" ] && ok "the per-task rule seals (it is a legitimate rule for per-unit opacity)" || no "task-salt-parity seal exited $RC"
grep -q '"aggregate_analysis_valid": false' "$WORK/mt/mapping.sealed.json" \
  && ok "the per-task rule is RECORDED as invalid for aggregate analysis (a label that flips per task aggregates no coherent condition)" \
  || no "the per-task rule does not record its aggregate invalidity"

echo
echo "== 5. The ADJUDICATOR view is leak-free =="
node "$VIEWS" adjudicator --records "$RECORDS" --sealed "$WORK/m1/mapping.sealed.json" --out "$WORK/adj-view.json" >"$WORK/adjv.log" 2>&1
RC=$?; [ "$RC" = "0" ] && ok "the adjudicator view is produced (exit 0)" || no "adjudicator view exited $RC: $(cat "$WORK/adjv.log")"
leakfree "$WORK/adj-view.json" "the adjudicator view"
for V in 184320 151552 262144 98304 311296 8471 7233 9812 6104 11207; do
  grep -qF -- "$V" "$WORK/adj-view.json" 2>/dev/null \
    && no "the adjudicator view exposes the starting-context byte value $V verbatim" \
    || ok "starting-context byte value $V does not appear in the adjudicator view"
done
grep -q '"starting_context_bytes"' "$WORK/adj-view.json" \
  && no "the adjudicator view carries a starting_context_bytes field" \
  || ok "the adjudicator view carries no starting-context field at all"
grep -qE '"work_product_ref": "wp-[0-9a-f]{16}\.diff"' "$WORK/adj-view.json" \
  && ok "every work-product path is an OPAQUE id (wp-<hex>.diff), not armA_*" \
  || no "work-product paths are not opaque ids"
grep -q '"acceptance_question"' "$WORK/adj-view.json" \
  && ok "the adjudicator view asks its acceptance question" \
  || no "the adjudicator view carries no acceptance question"
grep -q '"tests_passed"' "$WORK/adj-view.json" \
  && ok "the adjudicator view carries the test results it must judge on" \
  || no "the adjudicator view carries no test results"
grep -q '"task_id": "E4-T3"' "$WORK/adj-view.json" \
  && ok "the adjudicator view carries the task id (matched pairs remain pairable)" \
  || no "the adjudicator view carries no task id"

echo
echo "== 6. The ANALYST view: Arm X / Arm Y only, and capsule size blinded pre-freeze =="
node "$VIEWS" analyst --records "$RECORDS" --sealed "$WORK/m1/mapping.sealed.json" --out "$WORK/an-open.json" >"$WORK/anv.log" 2>&1
RC=$?; [ "$RC" = "0" ] && ok "the pre-freeze analyst view is produced (exit 0)" || no "analyst view exited $RC: $(cat "$WORK/anv.log")"
leakfree "$WORK/an-open.json" "the pre-freeze analyst view"
grep -q '"label": "Arm X"' "$WORK/an-open.json" && grep -q '"label": "Arm Y"' "$WORK/an-open.json" \
  && ok "the analyst view labels units 'Arm X' / 'Arm Y' and nothing else" \
  || no "the analyst view does not use the Arm X / Arm Y labels"
grep -q '"starting_context_bytes"' "$WORK/an-open.json" \
  && no "starting-context bytes are exposed BEFORE acceptance is frozen" \
  || ok "starting-context bytes are WITHHELD before acceptance is frozen"
for V in 184320 8471; do
  grep -qF -- "$V" "$WORK/an-open.json" 2>/dev/null \
    && no "the pre-freeze analyst view exposes starting byte value $V" \
    || ok "starting byte value $V is absent from the pre-freeze analyst view"
done
grep -q '"uncached_tokens"' "$WORK/an-open.json" \
  && ok "the pre-freeze analyst view still carries the economic fields it is entitled to" \
  || no "the pre-freeze analyst view carries no economics"

node "$VIEWS" analyst --records "$RECORDS" --sealed "$WORK/m1/mapping.sealed.json" --acceptance-frozen --out "$WORK/an-frozen.json" >/dev/null 2>&1
leakfree "$WORK/an-frozen.json" "the post-freeze analyst view"
grep -q '"starting_context_bytes"' "$WORK/an-frozen.json" \
  && ok "starting-context bytes ARE released to the analyst once acceptance is frozen" \
  || no "starting-context bytes never become available to the analyst"
grep -qF -- "184320" "$WORK/an-frozen.json" \
  && ok "the withheld value (184320) is preserved, not destroyed, and arrives after the freeze" \
  || no "the withheld starting-context value was lost rather than withheld"

echo
echo "== 7. leakcheck catches a PLANTED leak (the check is not vacuous) =="
node -e '
  const fs=require("fs");const f=process.argv[1];
  const j=JSON.parse(fs.readFileSync(f,"utf8"));
  j.units[0].source_file = "armA_E4-T1_capsule.json";
  fs.writeFileSync(f, JSON.stringify(j,null,2)+"\n");
' "$WORK/an-open.json"
cp "$WORK/an-open.json" "$WORK/planted.json"
node "$VIEWS" leakcheck --view "$WORK/planted.json" >"$WORK/leak.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "leakcheck REFUSES a view carrying 'armA_..._capsule.json' (exit 2)" || no "leakcheck exited $RC on a planted leak"
grep -qi 'capsule' "$WORK/leak.log" && ok "the leak refusal NAMES the offending string" || no "the leak refusal does not name what leaked"
node "$VIEWS" analyst --records "$RECORDS" --sealed "$WORK/m1/mapping.sealed.json" --out "$WORK/an-open.json" >/dev/null 2>&1
node "$VIEWS" leakcheck --view "$WORK/adj-view.json" >/dev/null 2>&1
RC=$?; [ "$RC" = "0" ] && ok "leakcheck passes the real adjudicator view (exit 0)" || no "leakcheck exited $RC on a clean view"

echo
echo "== 8. Calculations and the ANONYMOUS provisional verdict =="
node "$VIEWS" fixture-adjudication --records "$RECORDS" --sealed "$WORK/m1/mapping.sealed.json" --out "$WORK/adjudication.json" >/dev/null 2>&1
RC=$?; [ "$RC" = "0" ] && ok "a fixture adjudication stands in for the human adjudicator" || no "fixture-adjudication exited $RC"
grep -q 'FIXTURE' "$WORK/adjudication.json" \
  && ok "the fixture adjudication is MARKED as simulated (it is not passed off as a judgement)" \
  || no "the fixture adjudication is not marked simulated"

node "$VIEWS" calculations --analyst "$WORK/an-open.json" --adjudication "$WORK/adjudication.json" --out "$WORK/calc-bad.json" >"$WORK/calcbad.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "calculations REFUSE a pre-freeze analyst view (economics may not precede acceptance)" || no "calculations exited $RC on an unfrozen view"

node "$VIEWS" analyst --records "$RECORDS" --sealed "$WORK/mt/mapping.sealed.json" --acceptance-frozen --out "$WORK/an-task.json" >/dev/null 2>&1
node "$VIEWS" calculations --analyst "$WORK/an-task.json" --adjudication "$WORK/adjudication.json" --out "$WORK/calc-task.json" >"$WORK/calctask.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "calculations REFUSE a mapping whose labels flip per task (no coherent aggregate)" || no "calculations exited $RC on a per-task mapping"

node "$VIEWS" calculations --analyst "$WORK/an-frozen.json" --adjudication "$WORK/adjudication.json" --out "$WORK/calc.json" >"$WORK/calc.log" 2>&1
RC=$?; [ "$RC" = "0" ] && ok "calculations succeed on a frozen, experiment-scoped view" || no "calculations exited $RC: $(cat "$WORK/calc.log")"
leakfree "$WORK/calc.json" "the per-task/aggregate calculations"

node -e '
  const fs=require("fs");const f=process.argv[1];
  const j=JSON.parse(fs.readFileSync(f,"utf8"));
  j.units[0].acceptance_result = j.units[0].acceptance_result === "accepted" ? "rejected" : "accepted";
  fs.writeFileSync(f, JSON.stringify(j,null,2)+"\n");
' "$WORK/adjudication.json"
node "$VIEWS" calculations --analyst "$WORK/an-frozen.json" --adjudication "$WORK/adjudication.json" --out "$WORK/calc-x.json" >"$WORK/calcx.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "calculations REFUSE when the adjudication and the analyst view disagree on acceptance" || no "calculations exited $RC on an acceptance disagreement"
grep -q 'unit' "$WORK/calcx.log" && ok "the disagreement refusal names the unit" || no "the disagreement refusal names no unit"
node "$VIEWS" fixture-adjudication --records "$RECORDS" --sealed "$WORK/m1/mapping.sealed.json" --out "$WORK/adjudication.json" >/dev/null 2>&1

node "$VIEWS" provisional --calculations "$WORK/calc.json" --exclusions "$EXCL" --eligibility "$ELIG" --out "$WORK/provisional.json" >"$WORK/prov.log" 2>&1
RC=$?; [ "$RC" = "0" ] && ok "the ANONYMOUS provisional verdict is computed from X/Y alone" || no "provisional exited $RC: $(cat "$WORK/prov.log")"
leakfree "$WORK/provisional.json" "the anonymous provisional verdict"
grep -q '"anonymous_label"' "$WORK/provisional.json" \
  && ok "the provisional verdict carries an anonymous label" \
  || no "the provisional verdict carries no anonymous label"
grep -qE '"anonymous_label": "[a-z_]+(:Arm [XY])?"' "$WORK/provisional.json" \
  && ok "the anonymous label is expressed in Arm X / Arm Y terms only" \
  || no "the anonymous label is not label-only"
for S in supported "compression only" "acceleration only" inconclusive "context compilation harmful" small-because-uninformed "result confounded"; do
  grep -qF -- "$S" "$WORK/provisional.json" 2>/dev/null \
    && no "the ANONYMOUS verdict already states the registered outcome '$S' — the translation must wait for the reveal" \
    || ok "the anonymous verdict does not pre-state the registered outcome '$S'"
done

echo
echo "== 9. The FREEZE refuses while any of the fourteen artifacts is missing =="
node "$FREEZE" prepare --analyst "$WORK/an-frozen.json" --adjudication "$WORK/adjudication.json" \
  --calculations "$WORK/calc.json" --provisional "$WORK/provisional.json" --exclusions "$EXCL" \
  --out "$WORK/inputs" >"$WORK/prep.log" 2>&1
RC=$?; [ "$RC" = "0" ] && ok "freeze prepare materialises the freeze inputs" || no "prepare exited $RC: $(cat "$WORK/prep.log")"
NART="$(find "$WORK/inputs" -maxdepth 1 -name '*.json' | grep -c . || true)"
[ "$NART" = "14" ] && ok "all FOURTEEN required artifacts are materialised" || no "$NART artifact(s) materialised, expected 14"

for A in tokens elapsed rework anonymous_provisional_verdict starting_context_bytes exclusion_decisions; do
  rm -rf "$WORK/in-$A"; cp -r "$WORK/inputs" "$WORK/in-$A"; rm -f "$WORK/in-$A/$A.json"
  node "$FREEZE" freeze --inputs "$WORK/in-$A" --out "$WORK/snap-$A.json" >"$WORK/fz-$A.log" 2>&1
  RC=$?
  if [ "$RC" = "2" ] && grep -q "$A" "$WORK/fz-$A.log"; then
    ok "freeze REFUSES with '$A' missing, and NAMES it"
  else
    no "freeze exited $RC with '$A' missing (named: $(grep -c "$A" "$WORK/fz-$A.log"))"
  fi
done

node "$FREEZE" freeze --inputs "$WORK/inputs" --out "$WORK/snapshot.json" >"$WORK/fz.log" 2>&1
RC=$?; [ "$RC" = "0" ] && ok "freeze succeeds when all fourteen artifacts are present" || no "freeze exited $RC: $(cat "$WORK/fz.log")"
grep -q '"snapshot_digest"' "$WORK/snapshot.json" \
  && ok "the snapshot carries its own digest" \
  || no "the snapshot carries no digest"
node "$FREEZE" verify --snapshot "$WORK/snapshot.json" --inputs "$WORK/inputs" >/dev/null 2>&1
RC=$?; [ "$RC" = "0" ] && ok "verify accepts an untouched frozen snapshot" || no "verify exited $RC on an untouched snapshot"

echo
echo "== 10. A changed input INVALIDATES the frozen snapshot =="
cp -r "$WORK/inputs" "$WORK/inputs-changed"
node -e '
  const fs=require("fs");const f=process.argv[1];
  const j=JSON.parse(fs.readFileSync(f,"utf8"));
  j.tampered_after_freeze = true;
  fs.writeFileSync(f, JSON.stringify(j,null,2)+"\n");
' "$WORK/inputs-changed/tokens.json"
node "$FREEZE" verify --snapshot "$WORK/snapshot.json" --inputs "$WORK/inputs-changed" >"$WORK/vch.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "verify REFUSES once an input has changed under the snapshot" || no "verify exited $RC on a changed input"
grep -q 'tokens' "$WORK/vch.log" && ok "the invalidation NAMES the artifact that changed" || no "the invalidation does not name the artifact"
node -e '
  const fs=require("fs");const f=process.argv[1];
  const j=JSON.parse(fs.readFileSync(f,"utf8"));
  j.snapshot_digest = "0".repeat(64);
  fs.writeFileSync(f, JSON.stringify(j,null,2)+"\n");
' "$WORK/snapshot.json.tampered" 2>/dev/null
cp "$WORK/snapshot.json" "$WORK/snapshot-tampered.json"
node -e '
  const fs=require("fs");const f=process.argv[1];
  const j=JSON.parse(fs.readFileSync(f,"utf8"));
  j.snapshot_digest = "0".repeat(64);
  fs.writeFileSync(f, JSON.stringify(j,null,2)+"\n");
' "$WORK/snapshot-tampered.json"
node "$FREEZE" verify --snapshot "$WORK/snapshot-tampered.json" --inputs "$WORK/inputs" >"$WORK/vtam.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "verify REFUSES a snapshot whose own recorded digest was edited" || no "verify exited $RC on a tampered snapshot digest"

echo
echo "== 11. The REVEAL is one-way and conditional =="
AT="2026-08-06T00:00:00Z"
node "$REVEAL" --snapshot "$WORK/no-such-snapshot.json" --inputs "$WORK/inputs" --verdict "$WORK/provisional.json" \
  --sealed "$WORK/m1/mapping.sealed.json" --committed-digest "$WORK/m1/mapping.sha256" --at "$AT" --out "$WORK/a1.json" >"$WORK/r1.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "reveal REFUSES before the freeze exists (exit 2)" || no "reveal exited $RC with no snapshot"
grep -qi 'freeze' "$WORK/r1.log" && ok "the pre-freeze refusal NAMES the unmet condition" || no "the pre-freeze refusal names no condition"

node "$REVEAL" --snapshot "$WORK/snapshot.json" --inputs "$WORK/inputs" --verdict "$WORK/no-verdict.json" \
  --sealed "$WORK/m1/mapping.sealed.json" --committed-digest "$WORK/m1/mapping.sha256" --at "$AT" --out "$WORK/a2.json" >"$WORK/r2.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "reveal REFUSES without the anonymous provisional verdict" || no "reveal exited $RC with no provisional verdict"
grep -qi 'provisional' "$WORK/r2.log" && ok "the missing-verdict refusal NAMES the unmet condition" || no "the missing-verdict refusal names no condition"

printf '%s  mapping.sealed.json\n' "$(printf 'f%.0s' $(seq 1 64))" > "$WORK/wrong.sha256"
node "$REVEAL" --snapshot "$WORK/snapshot.json" --inputs "$WORK/inputs" --verdict "$WORK/provisional.json" \
  --sealed "$WORK/m1/mapping.sealed.json" --committed-digest "$WORK/wrong.sha256" --at "$AT" --out "$WORK/a3.json" >"$WORK/r3.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "reveal REFUSES when the seal does not match the COMMITTED digest" || no "reveal exited $RC on a digest mismatch"
grep -qi 'digest' "$WORK/r3.log" && ok "the digest-mismatch refusal NAMES the unmet condition" || no "the digest-mismatch refusal names no condition"

cp "$WORK/m1/mapping.sealed.json" "$WORK/mutated-seal.json"
node -e '
  const fs=require("fs");const f=process.argv[1];
  const j=JSON.parse(fs.readFileSync(f,"utf8"));
  j.label_map = { A: j.label_map.B, B: j.label_map.A };
  fs.writeFileSync(f, JSON.stringify(j,null,2)+"\n");
' "$WORK/mutated-seal.json"
node "$REVEAL" --snapshot "$WORK/snapshot.json" --inputs "$WORK/inputs" --verdict "$WORK/provisional.json" \
  --sealed "$WORK/mutated-seal.json" --committed-digest "$WORK/m1/mapping.sha256" --at "$AT" --out "$WORK/a4.json" >"$WORK/r4.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "A MUTATED SEALED MAPPING INVALIDATES THE REVEAL (exit 2)" || no "reveal exited $RC on a mutated seal — the seal is not load-bearing"

node "$REVEAL" --snapshot "$WORK/snapshot.json" --inputs "$WORK/inputs" --verdict "$WORK/provisional.json" \
  --sealed "$WORK/m1/mapping.sealed.json" --committed-digest "$WORK/m1/mapping.sha256" --out "$WORK/a5.json" >"$WORK/r5.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "reveal REFUSES without a SUPPLIED timestamp (it will not read a clock)" || no "reveal exited $RC with no --at"

echo
echo "== 12. The reveal SUCCEEDS when every condition holds =="
node "$REVEAL" --snapshot "$WORK/snapshot.json" --inputs "$WORK/inputs" --verdict "$WORK/provisional.json" \
  --sealed "$WORK/m1/mapping.sealed.json" --committed-digest "$WORK/m1/mapping.sha256" --at "$AT" --out "$WORK/audit.json" >"$WORK/r6.log" 2>&1
RC=$?; [ "$RC" = "0" ] && ok "reveal succeeds with the freeze, the verdict and the matching digest all in place" || no "reveal exited $RC: $(cat "$WORK/r6.log")"
[ -f "$WORK/audit.json" ] && ok "the reveal emits an AUDIT RECORD" || no "no audit record was written"
grep -qF -- "$AT" "$WORK/audit.json" && ok "the audit record carries the SUPPLIED reveal timestamp" || no "the audit record has no supplied timestamp"
grep -qF -- "$D_ORIG" "$WORK/audit.json" && ok "the audit record carries the committed mapping digest" || no "the audit record has no mapping digest"
grep -q '"registered_outcome"' "$WORK/audit.json" && ok "the audit record carries the translated registered outcome" || no "the audit record has no translated outcome"
grep -q '"registered_outcome_code"' "$WORK/audit.json" \
  && ok "the machine code is emitted ALONGSIDE the canonical wording (AMENDMENT 3.1)" \
  || no "the machine code is not emitted alongside the canonical wording"
OUT="$(node -e 'const fs=require("fs");console.log(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).registered_outcome)' "$WORK/audit.json")"
case "$OUT" in
  "supported"|"compression only"|"acceleration only"|"inconclusive"|"context compilation harmful"|"small-because-uninformed"|"result confounded")
    ok "the translated outcome '$OUT' is one of the SEVEN registered outcomes, verbatim" ;;
  *) no "the translated outcome '$OUT' is not one of the seven registered outcomes" ;;
esac

echo
echo "== 13. THE LOAD-BEARING TEST — the sealed bit decides the verdict =="
SALT_Y=""; SALT_X=""
for i in 1 2 3 4 5 6 7 8 9 10; do
  S="EXP0004-BLIND-v$i"
  node "$SEAL" seal --rule experiment-salt-parity --salt "$S" --tasks "$TASKS" --out "$WORK/s$i" >/dev/null 2>&1 || continue
  L="$(node -e 'const fs=require("fs");console.log(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).label_map.B)' "$WORK/s$i/mapping.sealed.json")"
  [ "$L" = "Arm Y" ] && [ -z "$SALT_Y" ] && SALT_Y="$WORK/s$i"
  [ "$L" = "Arm X" ] && [ -z "$SALT_X" ] && SALT_X="$WORK/s$i"
done
if [ -n "$SALT_Y" ] && [ -n "$SALT_X" ]; then
  ok "two registered salts produce OPPOSITE sealed bits (the blinding has two live branches)"
else
  no "could not find two salts with opposite parity"
fi

pipeline(){ # $1 sealdir  $2 tag -> echoes the registered outcome
  local sd="$1" t="$2"
  node "$VIEWS" analyst --records "$RECORDS" --sealed "$sd/mapping.sealed.json" --acceptance-frozen --out "$WORK/an-$t.json" >/dev/null 2>&1 || return 1
  node "$VIEWS" fixture-adjudication --records "$RECORDS" --sealed "$sd/mapping.sealed.json" --out "$WORK/ad-$t.json" >/dev/null 2>&1 || return 1
  node "$VIEWS" calculations --analyst "$WORK/an-$t.json" --adjudication "$WORK/ad-$t.json" --out "$WORK/ca-$t.json" >/dev/null 2>&1 || return 1
  node "$VIEWS" provisional --calculations "$WORK/ca-$t.json" --exclusions "$EXCL" --eligibility "$ELIG" --out "$WORK/pv-$t.json" >/dev/null 2>&1 || return 1
  node "$FREEZE" prepare --analyst "$WORK/an-$t.json" --adjudication "$WORK/ad-$t.json" --calculations "$WORK/ca-$t.json" \
    --provisional "$WORK/pv-$t.json" --exclusions "$EXCL" --out "$WORK/in-$t" >/dev/null 2>&1 || return 1
  node "$FREEZE" freeze --inputs "$WORK/in-$t" --out "$WORK/sn-$t.json" >/dev/null 2>&1 || return 1
  node "$REVEAL" --snapshot "$WORK/sn-$t.json" --inputs "$WORK/in-$t" --verdict "$WORK/pv-$t.json" \
    --sealed "$sd/mapping.sealed.json" --committed-digest "$sd/mapping.sha256" --at "$AT" --out "$WORK/au-$t.json" >/dev/null 2>&1 || return 1
  node -e 'const fs=require("fs");process.stdout.write(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).registered_outcome)' "$WORK/au-$t.json"
}

OUT_Y="$(pipeline "$SALT_Y" y)"
OUT_X="$(pipeline "$SALT_X" x)"
LAB_Y="$(node -e 'const fs=require("fs");console.log(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).anonymous_label.split(":")[0])' "$WORK/pv-y.json")"
LAB_X="$(node -e 'const fs=require("fs");console.log(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).anonymous_label.split(":")[0])' "$WORK/pv-x.json")"
[ "$LAB_Y" = "$LAB_X" ] && [ "$LAB_Y" = "token_gate_only_for" ] \
  && ok "both sealed bits yield the SAME anonymous SHAPE ('$LAB_Y') — only the label attached differs" \
  || no "the anonymous shape differs across seals ('$LAB_Y' vs '$LAB_X')"
[ "$OUT_Y" = "$OUT_X" ] && [ "$OUT_Y" = "compression only" ] \
  && ok "a full re-run under the OPPOSITE seal recovers the SAME outcome ('$OUT_Y') — relabelling is invisible, which is the property blinding must have" \
  || no "re-labelling changed the outcome ('$OUT_Y' vs '$OUT_X') — the pipeline is not label-invariant"

# THE COUNTERFACTUAL. Hold the anonymous verdict FIXED and vary ONLY the sealed
# bit. If the outcome moves, the blinded artifact genuinely did not contain the
# answer — which is the entire claim blinding makes.
cat > "$WORK/counterfactual.mjs" <<EOF
import fs from "node:fs";
const R = await import("$REVEAL");
const V = await import("$VIEWS");
const P = await import("$SRC/build-os/experiments/EXP-0004-context-compiler/harness/prereg-thresholds.mjs");
const prov = JSON.parse(fs.readFileSync("$WORK/pv-y.json", "utf8"));
const th = P.loadThresholds();
const th3 = V.loadAmendment3();
const a = R.translate(prov, { A: "Arm X", B: "Arm Y" }, th, th3);
const b = R.translate(prov, { A: "Arm Y", B: "Arm X" }, th, th3);
process.stdout.write(a.outcome + "\n" + b.outcome + "\n");
EOF
node "$WORK/counterfactual.mjs" >"$WORK/cf.txt" 2>"$WORK/cf.err"
RC=$?
CF1="$(sed -n 1p "$WORK/cf.txt")"; CF2="$(sed -n 2p "$WORK/cf.txt")"
[ "$RC" = "0" ] && ok "the translation is callable as a pure function of (anonymous verdict, sealed bit)" || no "counterfactual failed: $(cat "$WORK/cf.err")"
[ "$CF1" != "$CF2" ] \
  && ok "THE SAME anonymous verdict translates to DIFFERENT registered outcomes under the two sealed bits ('$CF1' vs '$CF2') — the blinded artifact does not contain the answer" \
  || no "both sealed bits translate to '$CF1' — the seal is not load-bearing"
{ [ "$CF1" = "compression only" ] && [ "$CF2" = "context compilation harmful" ]; } \
  || { [ "$CF2" = "compression only" ] && [ "$CF1" = "context compilation harmful" ]; } \
  && ok "the two branches are exactly 'compression only' and 'context compilation harmful', both registered verbatim" \
  || no "unexpected counterfactual branches: '$CF1' / '$CF2'"

echo "-- and a seal that did not produce the verdict is REFUSED --"
node "$REVEAL" --snapshot "$WORK/sn-y.json" --inputs "$WORK/in-y" --verdict "$WORK/pv-y.json" \
  --sealed "$SALT_X/mapping.sealed.json" --committed-digest "$SALT_X/mapping.sha256" --at "$AT" --out "$WORK/wrong.json" >"$WORK/wrong.log" 2>&1
RC=$?; [ "$RC" = "2" ] && ok "reveal REFUSES a self-consistent seal that is not THE seal the verdict was produced under" || no "reveal exited $RC with the wrong seal"
grep -qi 'WRONG SEAL' "$WORK/wrong.log" && ok "the wrong-seal refusal says so by name" || no "the wrong-seal refusal is unnamed"

echo
echo "== 14. The simulated matched pair walks END TO END =="
bash "$FLOW" --work "$WORK/flow" --at "$AT" >"$WORK/flow.log" 2>&1
RC=$?; [ "$RC" = "0" ] && ok "run-blinded-flow.sh completes (exit 0)" || no "the flow exited $RC: $(tail -20 "$WORK/flow.log")"
for s in $FORBIDDEN; do
  grep -qi -- "$s" "$WORK/flow.log" 2>/dev/null \
    && no "the flow's own output leaks the forbidden string '$s'" \
    || ok "the flow's output is free of '$s'"
done
for F in mapping.sealed.json mapping.sha256 adjudicator-view.json analyst-view.json provisional-verdict.json snapshot.json reveal-audit.json; do
  [ -f "$WORK/flow/$F" ] && ok "the flow produced $F" || no "the flow did not produce $F"
done
leakfree "$WORK/flow/adjudicator-view.json" "the flow's adjudicator view"
leakfree "$WORK/flow/analyst-view.json" "the flow's analyst view"
grep -q 'ANONYMOUS PROVISIONAL VERDICT' "$WORK/flow.log" \
  && ok "the flow prints the anonymous provisional verdict BEFORE the reveal" \
  || no "the flow does not print the anonymous verdict"
FOUT="$(node -e 'const fs=require("fs");console.log(JSON.parse(fs.readFileSync(process.argv[1],"utf8")).registered_outcome)' "$WORK/flow/reveal-audit.json")"
case "$FOUT" in
  "supported"|"compression only"|"acceleration only"|"inconclusive"|"context compilation harmful"|"small-because-uninformed"|"result confounded")
    ok "the flow's translated verdict '$FOUT' is one of the SEVEN registered outcomes, verbatim" ;;
  *) no "the flow's translated verdict '$FOUT' is not a registered outcome" ;;
esac
grep -q 'SIMULATED' "$WORK/flow.log" \
  && ok "the flow declares itself SIMULATED (no measurement is passed off as real)" \
  || no "the flow does not declare itself simulated"

echo
echo "== 15. No path exposed to a blinded view encodes arm identity =="
for V in "$WORK/adj-view.json" "$WORK/an-frozen.json" "$WORK/calc.json" "$WORK/provisional.json" \
         "$WORK/flow/adjudicator-view.json" "$WORK/flow/analyst-view.json"; do
  if grep -qiE '(armA|armB|arm_a|arm_b|_a\.json|_b\.json)' "$V" 2>/dev/null; then
    no "$(basename "$V") exposes an arm-encoding path"
  else
    ok "$(basename "$V") exposes no arm-encoding path"
  fi
done
if grep -qiE '"[^"]*/(build-os|experiments)/' "$WORK/adj-view.json" "$WORK/an-frozen.json" 2>/dev/null; then
  no "a blinded view embeds a repository path (which names the experiment directory)"
else
  ok "no blinded view embeds a repository path"
fi

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
