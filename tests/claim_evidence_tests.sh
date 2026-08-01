#!/usr/bin/env bash
# Build OS — claim-scoped evidence: one control, many claims, many verdicts.
#
# THE DEFECT THIS EXISTS AGAINST, AND IT IS NOT HYPOTHETICAL. Until now a
# control carried ONE `empirical_status` token, and that token was read as a
# statement about the control. `gravito_mismatch_refuted_a` measured the case
# where that is false: `maint.tripwire_coverage_scan` is
#
#   claim A  detects uncovered behaviour under bare `node --test`
#            -> REFUTED
#   claim B  prevents destructive maintenance mutation under the sanctioned
#            maintenance invocation
#            -> SUPPORTED
#
# and reasoning from the bare token nearly produced a demotion that the
# COVERAGE-GATE-PREVENTION-DIFFERENTIAL measured to DESTROY LIVE MEMORY. The two
# claims are about different behaviours, in different invocation paths, and one
# token cannot say both. So evidence becomes an ASSERTION — subject, claim,
# scope, method, result — and a subject may carry as many concurrent assertions
# as it has claims.
#
# WHAT THIS SUITE PINS.
#
#   1. MULTIPLE CONCURRENT ASSERTIONS per subject, with `supported` and
#      `refuted` coexisting and neither collapsing the other.
#   2. SCOPE IS REQUIRED. A claim with no scope is the unscoped token this
#      packet exists to replace, so it is refused rather than defaulted.
#   3. AN UNRECOGNISED STATUS REFUSES. `untested` was ADDED to the vocabulary,
#      deliberately and with a cap; every OTHER unrecognised token still exits
#      2. Adding one token must not turn the guard into a fall-through.
#   4. THE LEGACY PROJECTION IS DETERMINISTIC AND NEVER ERASES A CONTRADICTION.
#      Where several claim statuses exist it exposes the COMPOSITE. Selecting
#      whichever status permits greater authority is the flattering-direction
#      error this repository exists to catch, and §8 drives it.
#   5. EVIDENCE MAY LOWER AUTHORITY AND MAY NOT RAISE IT. The composition is a
#      MINIMUM over class, the registry's own evidence token, and the
#      assertions'. §8 fabricates the case where an assertion WOULD license
#      more than the registry does and requires the minimum to win.
#
# WHAT IT DOES NOT PIN, named rather than implied away. It takes every field of
# an assertion AT THE AUTHOR'S WORD, exactly as evidence-policy.sh takes
# `empirical_status`. Nothing here re-runs a fixture, checks that an
# `observed_result` was ever observed, or notices an assertion going stale
# against a `valid_until` it declares. The store records what somebody asserted
# and the shape of the assertion; it does not verify the assertion.
#
# A NOTE ON THIS FILE'S OWN CONSTANTS. It uses NO `-ge N` / `-gt N` floor with
# N > 1. tests/control_registry_tests.sh §21 sweeps the tree for that shape and
# requires every match to be registered to tests.nonvacuity_minimums. Where a
# count is needed this asserts an EXACT one, and uses `-gt 0` / `-ge 1` only as
# vacuity guards, both of which §21 excludes by rule.
#
# No network. Deterministic. Every fixture lives in its own mktemp dir; nothing
# outside $WORK is written. Exits non-zero if any assertion fails.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$SRC/build-os/tools/claim-evidence.sh"
STORE="$SRC/build-os/registry/evidence_assertions.txt"
REG="$SRC/build-os/registry/control_registry.txt"
MUTREG="$SRC/build-os/registry/mutator_registry.txt"
EPOL="$SRC/build-os/tools/evidence-policy.sh"
SCAN="$SRC/build-os/registry/scan-controls.sh"
RREADME="$SRC/build-os/registry/README.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The enums, duplicated here ON PURPOSE. A test that reads its expected values
# out of the artefact it checks cannot detect the artefact widening its own
# enum — the lesson tests/control_registry_tests.sh paid for.
EV_FIELDS="subject_id claim_id claim_text status scope substrate invocation_path method fixture observed_result interpretation limitations created_at created_by reviewed_by valid_from valid_until artifact_refs supersedes"
EV_STATUSES="untested unvalidated red_driven supported refuted"
LADDER="none observe advise rank gate execute"
SUBJECT="maint.tripwire_coverage_scan"
EV_ID_RE='^EV-[0-9]{4}(-[a-z0-9][a-z0-9-]*)?$'

rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; execute) echo 5 ;; *) echo -1 ;; esac; }
in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }

# Run the tool, capture stdout+stderr to $WORK/out.txt, echo the exit code. The
# fixtures below read the SAME file the assertions read, so no assertion can
# pass against output nobody captured.
run(){ "$TOOL" "$@" > "$WORK/out.txt" 2>&1; printf '%s' "$?"; }
dump(){ sed 's/^/      | /' "$WORK/out.txt" | head -12; }

# Stanza field read, independent of the tool's own parser.
fld(){ # <ev-id> <field> <file>
  awk -v i="$1" -v f="$2" '
    $0 == "evidence: "i {inr=1; next}
    /^$/ {inr=0}
    inr && $0 ~ "^"f": " {sub("^"f": ",""); print; exit}' "$3"
}
# The whole stanza for one id, verbatim.
stanza(){ awk -v i="$1" '$0=="evidence: "i{p=1} p{print} p&&/^$/{exit}' "$2"; }
# Registry field read.
rfld(){ awk -v i="$1" -v f="$2" '
    $0 == "control: "i {inr=1; next}
    /^$/ {inr=0}
    inr && $0 ~ "^"f": " {sub("^"f": ",""); print; exit}' "$3"; }

echo "== 0. Every artefact this layer is made of exists =="
MISSING=""
for f in "$TOOL" "$STORE" "$REG" "$MUTREG" "$EPOL" "$SCAN"; do
  [ -s "$f" ] || MISSING="$MISSING ${f#"$SRC/"}"
done
[ -z "$MISSING" ] && ok "the tool, the assertion store and the artefacts it reconciles against are all present and non-empty" \
                  || no "absent or empty:$MISSING"
[ -x "$TOOL" ] && ok "claim-evidence.sh is executable" || no "claim-evidence.sh is not executable"

echo "== 0a. The schema is DECLARED where a reader can find it, not inferred =="
RC="$(run schema)"
[ "$RC" = "0" ] && ok "\`schema\` exits 0" || { no "\`schema\` exited $RC"; dump; }
MISSF=""
for f in $EV_FIELDS; do
  grep -qE "^field: $f( |$)" "$WORK/out.txt" || MISSF="$MISSF $f"
done
[ -z "$MISSF" ] \
  && ok "all 19 declared fields are printed by \`schema\`, one per line" \
  || { no "field(s) the packet requires that the schema does not declare:$MISSF"; dump; }
MISSS=""
for s in $EV_STATUSES; do
  grep -qE "^status: $s " "$WORK/out.txt" || MISSS="$MISSS $s"
done
[ -z "$MISSS" ] \
  && ok "all five statuses are declared, \`untested\` among them" \
  || { no "status(es) missing from the declared vocabulary:$MISSS"; dump; }
# Every declared status must carry a cap that is a rung, and a legacy projection
# that is a legacy token — a status with neither is a token that licenses by
# falling through.
SBAD=0
for s in $EV_STATUSES; do
  cap="$(awk -v s="$s" '$1=="status:" && $2==s {for(i=3;i<=NF;i++) if($i ~ /^scope-cap=/){sub(/^scope-cap=/,"",$i); print $i}}' "$WORK/out.txt")"
  in_list "$cap" "$LADDER" || { SBAD=$((SBAD+1)); echo "      | status $s has scope-cap '$cap', which is not on the ladder"; }
done
[ "$SBAD" -eq 0 ] \
  && ok "every declared status caps at a rung of the ladder — none licenses by omission" \
  || no "$SBAD status(es) declare a cap that is not an authority"

echo "== 1. ONE SUBJECT CARRIES MULTIPLE EVIDENCE ASSERTIONS (5.5.1) =="
NALL="$(grep -c '^evidence: ' "$STORE" || true)"; NALL="${NALL:-0}"
[ "$NALL" -gt 0 ] \
  && ok "$NALL assertion(s) parsed from the live store (this section is not vacuous)" \
  || no "the live store parses to zero assertions — every check below would pass by reading nothing"
NSUB="$(awk -F': ' -v s="$SUBJECT" '$1=="subject_id" && $2==s' "$STORE" | grep -c . || true)"
[ "${NSUB:-0}" = "2" ] \
  && ok "$SUBJECT carries exactly 2 concurrent assertions — the token it used to carry could hold one" \
  || no "$SUBJECT carries ${NSUB:-0} assertion(s), expected 2"
NCLAIM="$(awk -v s="$SUBJECT" '
  /^evidence: /{c=""} /^subject_id: /{sub("^subject_id: ","");sj=$0}
  /^claim_id: /{sub("^claim_id: ","");if(sj==s)print $0}' "$STORE" | sort -u | grep -c . || true)"
[ "${NCLAIM:-0}" = "2" ] \
  && ok "and they name 2 DISTINCT claim ids — two assertions about one claim would be a contradiction, not concurrency" \
  || no "$SUBJECT's assertions name ${NCLAIM:-0} distinct claim id(s), expected 2"

echo "== 2. \`supported\` AND \`refuted\` COEXIST WITHOUT PARSER FAILURE (5.5.2) =="
RC="$(run validate --store "$STORE" --registry "$REG")"
[ "$RC" = "0" ] \
  && ok "the live store — which holds a \`supported\` and a \`refuted\` assertion for ONE subject — validates clean" \
  || { no "validate exited $RC on the live store"; dump; }
SST="$(awk -v s="$SUBJECT" '
  /^subject_id: /{sub("^subject_id: ","");sj=$0}
  /^status: /{sub("^status: ","");if(sj==s)print $0}' "$STORE" | sort -u | tr '\n' ' ')"
case " $SST " in
  *" refuted "*) case " $SST " in
    *" supported "*) ok "both verdicts are live on the same subject at the same time: $SST" ;;
    *) no "no \`supported\` assertion on $SUBJECT — the case that forced this packet is not represented" ;;
  esac ;;
  *) no "no \`refuted\` assertion on $SUBJECT — the refutation has been dropped, which is the one move forbidden here" ;;
esac
RC="$(run project --store "$STORE" --registry "$REG" --subject "$SUBJECT")"
[ "$RC" = "0" ] && ok "\`project\` reads a contradictory subject without failing" \
                || { no "\`project\` exited $RC on the contradictory subject"; dump; }
grep -qE "^contradiction: $SUBJECT " "$WORK/out.txt" \
  && ok "and it NAMES the contradiction rather than resolving it silently" \
  || { no "the projection does not report that this subject carries opposed verdicts"; dump; }

echo "== 3. CLAIM SCOPE IS REQUIRED (5.5.3) =="
# A claim with no scope is exactly the unscoped token this packet replaces, so a
# default would reintroduce the defect under a new field name.
mkfix(){ cp "$STORE" "$1"; }
mkfix "$WORK/noscope.txt"
FIRST="$(grep -m1 '^evidence: ' "$STORE" | sed 's/^evidence: //')"
awk -v i="$FIRST" '
  $0=="evidence: "i {inr=1} /^$/{inr=0}
  { if (inr && $0 ~ /^scope: /) next; print }' "$STORE" > "$WORK/noscope.txt"
RC="$(run validate --store "$WORK/noscope.txt" --registry "$REG")"
[ "$RC" = "2" ] \
  && ok "RED: an assertion with NO \`scope\` field is REFUSED (exit 2), not defaulted to a global claim" \
  || { no "a scopeless assertion exited $RC — the scope is optional in practice"; dump; }
grep -qF 'scope' "$WORK/out.txt" \
  && ok "and the refusal names the missing field" \
  || { no "the refusal does not name scope"; dump; }
sed "s/^scope: .*/scope: /" "$STORE" > "$WORK/emptyscope.txt"
RC="$(run validate --store "$WORK/emptyscope.txt" --registry "$REG")"
[ "$RC" = "2" ] \
  && ok "RED: an EMPTY \`scope\` is refused too — a present-but-blank field is an absence wearing a field's clothes" \
  || { no "an empty scope exited $RC"; dump; }
for filler in n/a none unknown any all; do
  sed "s|^scope: .*|scope: $filler|" "$STORE" > "$WORK/fillerscope.txt"
  RC="$(run validate --store "$WORK/fillerscope.txt" --registry "$REG")"
  [ "$RC" = "2" ] \
    && ok "RED: \`scope: $filler\` is refused — a filler that means \"everywhere\" is an unscoped claim spelled differently" \
    || { no "\`scope: $filler\` exited $RC"; dump; }
done

echo "== 4. AN UNKNOWN STATUS REFUSES RATHER THAN FALLING THROUGH (5.5.4) =="
sed "s/^status: refuted$/status: probably_fine/" "$STORE" > "$WORK/badstatus.txt"
RC="$(run validate --store "$WORK/badstatus.txt" --registry "$REG")"
[ "$RC" = "2" ] \
  && ok "RED: an unrecognised status is REFUSED (exit 2) — an evidence level nobody capped must never license by omission" \
  || { no "an unrecognised status exited $RC"; dump; }
grep -qF 'probably_fine' "$WORK/out.txt" \
  && ok "and the refusal names the token it has no cap for" \
  || { no "the refusal does not name the unrecognised token"; dump; }
# ...and the SAME rule one layer down. `untested` was added on purpose; every
# other unrecognised token must still take evidence-policy.sh to exit 2.
{ printf 'control: fixture.bogus\nclass: C\nempirical_status: probably_fine\nruntime_authority: advise\n\n'; } > "$WORK/bogus_reg.txt"
: > "$WORK/empty_env.txt"
"$EPOL" check --registry "$WORK/bogus_reg.txt" --envelopes "$WORK/empty_env.txt" > "$WORK/out.txt" 2>&1
RCB="$?"
[ "$RCB" = "2" ] \
  && ok "RED: evidence.derivation_nonvacuity still exits 2 on an unrecognised empirical_status — adding \`untested\` did not open a fall-through" \
  || { no "an unrecognised empirical_status exited $RCB from evidence-policy.sh"; dump; }
# ...while `untested` itself is now RECOGNISED, and recognised at the most
# conservative rung that is still a legal destination.
{ printf 'control: fixture.untested\nclass: A\nempirical_status: untested\nruntime_authority: gate\n\n'; } > "$WORK/untested_reg.txt"
"$EPOL" check --registry "$WORK/untested_reg.txt" --envelopes "$WORK/empty_env.txt" > "$WORK/out.txt" 2>&1
RCU="$?"
[ "$RCU" = "0" ] \
  && ok "\`untested\` is now a RECOGNISED evidence level: the derivation runs instead of refusing" \
  || { no "\`untested\` exited $RCU from evidence-policy.sh — it was added to the vocabulary but not to the axis"; dump; }
grep -qE 'OUT-OF-LICENCE fixture\.untested .*evidence-licensed=observe' "$WORK/out.txt" \
  && ok "and it caps at \`observe\` — a check that has NEVER OPERATED may be recorded and may cause nothing" \
  || { no "\`untested\` does not cap at observe"; dump; }
"$EPOL" matrix > "$WORK/out.txt" 2>&1
UGRID="$(awk '$1=="grid:" && $0 ~ /evidence=untested/' "$WORK/out.txt" | grep -c . || true)"
[ "${UGRID:-0}" = "5" ] \
  && ok "the printed grid carries an \`untested\` cell for each of the 5 classes — the axis widened, and every cell is stated" \
  || no "the grid states ${UGRID:-0} \`untested\` cell(s), expected 5"
UEX="$(awk '$1=="grid:" && $0 ~ /evidence=untested/ && $0 ~ /licensed=execute/' "$WORK/out.txt" | grep -c . || true)"
[ "${UEX:-0}" = "0" ] \
  && ok "and NO \`untested\` cell licenses \`execute\` — widening the axis added a column, never a grant" \
  || no "${UEX:-0} \`untested\` cell(s) license execute"

echo "== 5. THE MAINTENANCE COUNTERFACTUAL IS REPRESENTABLE ACCURATELY (5.5.5) =="
# "Accurately" is the load-bearing word. The differential's finding is NOT
# "the gate is good": it is that BOTH ARMS EXIT 1 and the trees differ, so
# nothing watching exit codes can see the demotion at all. An assertion that
# recorded only "supported" would lose exactly the fact that made the demotion
# dangerous.
REFID=""; SUPID=""
while IFS= read -r i; do
  [ -n "$i" ] || continue
  [ "$(fld "$i" subject_id "$STORE")" = "$SUBJECT" ] || continue
  case "$(fld "$i" status "$STORE")" in
    refuted)   REFID="$i" ;;
    supported) SUPID="$i" ;;
  esac
done < <(sed -n 's/^evidence: //p' "$STORE")
{ [ -n "$REFID" ] && [ -n "$SUPID" ]; } \
  && ok "both halves of the counterfactual are addressable by stable id ($REFID, $SUPID)" \
  || no "one half of the counterfactual is missing: refuted='$REFID' supported='$SUPID'"
if [ -n "$REFID" ] && [ -n "$SUPID" ]; then
  printf '%s' "$(fld "$REFID" scope "$STORE")" | grep -qF 'node --test' \
    && ok "the REFUTED claim's scope names the invocation path it was refuted on: bare \`node --test\`" \
    || no "the refuted claim's scope does not name the bare \`node --test\` path"
  printf '%s' "$(fld "$SUPID" scope "$STORE")" | grep -qiE 'sanctioned|maintenance invocation' \
    && ok "the SUPPORTED claim's scope names the sanctioned maintenance invocation, and no more" \
    || no "the supported claim's scope does not name the sanctioned maintenance invocation"
  [ "$(fld "$REFID" invocation_path "$STORE")" != "$(fld "$SUPID" invocation_path "$STORE")" ] \
    && ok "the two claims declare DIFFERENT invocation_paths — which is the whole reason one token could not say both" \
    || no "both claims declare the same invocation_path; then one token would have sufficed"
  printf '%s' "$(fld "$SUPID" fixture "$STORE")" | grep -qF 'COVERAGE-GATE-PREVENTION-DIFFERENTIAL' \
    && ok "the supported claim cites the measurement by name (COVERAGE-GATE-PREVENTION-DIFFERENTIAL)" \
    || no "the supported claim does not cite the differential that produced it"
  OBS="$(fld "$SUPID" observed_result "$STORE")"
  printf '%s' "$OBS" | grep -qF 'exit 1' \
    && ok "the observed_result records that the exit code is 1 in BOTH arms — the fact that makes the demotion invisible" \
    || no "the observed_result does not record the identical exit code across arms"
  printf '%s' "$OBS" | grep -qiE 'destroy|destruct|overwritten|rewritten' \
    && ok "...and that the demoted arm DESTROYS the tree, which is the consequence the bare token hid" \
    || no "the observed_result does not record what the demoted arm did to the tree"
  LIM="$(fld "$SUPID" limitations "$STORE")"
  [ -n "$LIM" ] && [ "$LIM" != "none" ] \
    && ok "and the supported claim declares its LIMITATIONS rather than reading as a clean bill of health" \
    || no "the supported claim declares no limitations; a support claim with no stated limit is an overclaim"
fi
# The registry entry it describes must be UNTOUCHED. This packet classifies; it
# re-authorises nothing, and a claim-scoped store that quietly edited the census
# would be the re-authorisation it exists to make unnecessary.
UNCH=0
[ "$(rfld "$SUBJECT" empirical_status "$REG")" = "red_driven,refuted" ] || { UNCH=$((UNCH+1)); echo "      | empirical_status moved"; }
[ "$(rfld "$SUBJECT" runtime_authority "$REG")" = "gate" ]              || { UNCH=$((UNCH+1)); echo "      | runtime_authority moved"; }
[ "$(rfld "$SUBJECT" class "$REG")" = "C" ]                             || { UNCH=$((UNCH+1)); echo "      | class moved"; }
[ "$(rfld "$SUBJECT" authority_mismatch "$REG")" = "declared" ]         || { UNCH=$((UNCH+1)); echo "      | authority_mismatch moved"; }
[ "$UNCH" -eq 0 ] \
  && ok "$SUBJECT's live registry entry is byte-for-byte the classification it had before this store existed" \
  || no "$UNCH field(s) of $SUBJECT moved; recording claim-scoped evidence must re-authorise nothing"

echo "== 6. CHANGING ONE CLAIM DOES NOT REWRITE ANOTHER (5.5.6) =="
# Assertions are independent records. Editing the refuted one must leave the
# supported one byte-identical — the property a single shared token cannot have,
# because there is only one of it.
if [ -n "$REFID" ] && [ -n "$SUPID" ]; then
  stanza "$SUPID" "$STORE" > "$WORK/sup_before.txt"
  awk -v i="$REFID" '
    $0=="evidence: "i {inr=1} /^$/{inr=0}
    { if (inr && $0 ~ /^status: /) print "status: unvalidated"; else print }' "$STORE" > "$WORK/edited.txt"
  stanza "$SUPID" "$WORK/edited.txt" > "$WORK/sup_after.txt"
  if diff -q "$WORK/sup_before.txt" "$WORK/sup_after.txt" >/dev/null 2>&1; then
    ok "flipping the refuted claim's status left the supported claim's record byte-identical"
  else
    no "editing one assertion changed another"
    diff "$WORK/sup_before.txt" "$WORK/sup_after.txt" | sed 's/^/      | /' | head -6
  fi
  [ "$(fld "$REFID" status "$WORK/edited.txt")" = "unvalidated" ] \
    && ok "...and the edit landed where it was aimed (the fixture is not a no-op)" \
    || no "the fixture edit did not take, so the comparison above proved nothing"
  # And the PROJECTION must move, because the composite is a function of every
  # live claim. An edit nothing downstream notices is a store nothing reads.
  RC="$(run project --store "$STORE" --registry "$REG" --subject "$SUBJECT")"
  P_BEFORE="$(grep "^projection: $SUBJECT " "$WORK/out.txt")"
  RC="$(run project --store "$WORK/edited.txt" --registry "$REG" --subject "$SUBJECT")"
  P_AFTER="$(grep "^projection: $SUBJECT " "$WORK/out.txt")"
  [ -n "$P_BEFORE" ] && [ "$P_BEFORE" != "$P_AFTER" ] \
    && ok "and the legacy projection MOVED with it — the composite is derived on every run, not stored" \
    || no "the projection did not change when a claim's status did"
  printf '%s' "$P_BEFORE" | grep -qF 'refuted' \
    && ok "the pre-edit projection carries \`refuted\` — the contradictory claim is not erased by the supported one" \
    || no "the projection dropped the refutation; that is the flattering-direction error, mechanised"
fi

echo "== 7. LEGACY PROJECTIONS ARE DETERMINISTIC (5.5.7) =="
run project --store "$STORE" --registry "$REG" >/dev/null; cp "$WORK/out.txt" "$WORK/p1.txt"
run project --store "$STORE" --registry "$REG" >/dev/null; cp "$WORK/out.txt" "$WORK/p2.txt"
if diff -q "$WORK/p1.txt" "$WORK/p2.txt" >/dev/null 2>&1; then
  ok "two runs over an unchanged store produce byte-identical output"
else
  no "the projection is not reproducible run to run"
  diff "$WORK/p1.txt" "$WORK/p2.txt" | sed 's/^/      | /' | head -6
fi
# ...and it must not depend on the order the stanzas happen to sit in. A
# projection that reads differently after somebody reorders a file is a
# projection whose value is an artefact of the editor.
awk 'BEGIN{RS="";n=0} {a[++n]=$0} END{for(i=n;i>=1;i--) printf "%s\n\n", a[i]}' "$STORE" > "$WORK/reversed.txt"
run project --store "$WORK/reversed.txt" --registry "$REG" >/dev/null
grep "^projection: " "$WORK/out.txt" | sort > "$WORK/p_rev.txt"
grep "^projection: " "$WORK/p1.txt"  | sort > "$WORK/p_fwd.txt"
if diff -q "$WORK/p_fwd.txt" "$WORK/p_rev.txt" >/dev/null 2>&1; then
  ok "reversing the store's stanza order changes no projection — the composite is a SET, deterministically ordered"
else
  no "the projection depends on stanza order"
  diff "$WORK/p_fwd.txt" "$WORK/p_rev.txt" | sed 's/^/      | /' | head -6
fi
# Every projected token must be one evidence-policy.sh can actually resolve,
# or the compatibility claim is empty.
awk '$1=="projection:"{for(i=3;i<=NF;i++) if($i ~ /^legacy-empirical-status=/){sub(/^legacy-empirical-status=/,"",$i); print $i}}' \
  "$WORK/p1.txt" | tr ',' '\n' | sort -u > "$WORK/proj_tokens.txt"
NPT="$(grep -c . "$WORK/proj_tokens.txt" || true)"; NPT="${NPT:-0}"
[ "$NPT" -gt 0 ] \
  && ok "$NPT distinct legacy token(s) are actually projected (the reconciliation below is not vacuous)" \
  || no "the projection emitted no legacy tokens"
"$EPOL" matrix > "$WORK/matrix.txt" 2>&1
awk '$1=="axis:" && $2=="evidence"{for(i=3;i<=NF;i++) if($i ~ /:/){split($i,p,":"); print p[1]}}' \
  "$WORK/matrix.txt" | sort -u > "$WORK/axis_ev.txt"
UNKNOWN=""
while IFS= read -r t; do
  [ -n "$t" ] || continue
  grep -qxF "$t" "$WORK/axis_ev.txt" || UNKNOWN="$UNKNOWN $t"
done < "$WORK/proj_tokens.txt"
[ -z "$UNKNOWN" ] \
  && ok "every projected token has a cap on evidence-policy.sh's evidence axis — the projection is READABLE by the existing matrix" \
  || no "projected token(s) the legacy matrix would refuse:$UNKNOWN"

echo "== 8. EVIDENCE CANNOT SILENTLY RAISE AUTHORITY (5.5.8) =="
# The sharp one. A `red_driven` assertion licenses `gate` on its own, and the
# registry entry it is about is `refuted`, which caps at `observe`. The
# composition is a MINIMUM, so the assertion must be unable to lift it. If this
# ever reports `gate`, evidence has become a promotion mechanism and the store
# is a laundering channel.
{ printf 'control: fixture.raiser\nclass: A\nempirical_status: refuted\nruntime_authority: gate\n\n'; } > "$WORK/raiser_reg.txt"
{ printf 'evidence: EV-9001-raiser\n'
  printf 'subject_id: fixture.raiser\n'
  printf 'claim_id: CLAIM-raise\n'
  printf 'claim_text: it fires on a planted defect\n'
  printf 'status: red_driven\n'
  printf 'scope: the one planted fixture in this test\n'
  printf 'substrate: bash\n'
  printf 'invocation_path: the fixture harness\n'
  printf 'method: red drive\n'
  printf 'fixture: a planted defect\n'
  printf 'observed_result: it fired\n'
  printf 'interpretation: the check can fire\n'
  printf 'limitations: says nothing about staying quiet\n'
  printf 'created_at: 2026-08-01\n'
  printf 'created_by: tests/claim_evidence_tests.sh\n'
  printf 'reviewed_by: none\n'
  printf 'valid_from: 2026-08-01\n'
  printf 'valid_until: open\n'
  printf 'artifact_refs: tests/claim_evidence_tests.sh\n'
  printf 'supersedes: none\n\n'; } > "$WORK/raiser_store.txt"
RC="$(run project --store "$WORK/raiser_store.txt" --registry "$WORK/raiser_reg.txt" --subject fixture.raiser)"
[ "$RC" = "0" ] && ok "the raising fixture projects without failing" || { no "the raising fixture exited $RC"; dump; }
AUTHLINE="$(grep '^authority: fixture.raiser ' "$WORK/out.txt")"
[ -n "$AUTHLINE" ] \
  && ok "the tool reports an explicit authority composition for the subject (this assertion is not vacuous)" \
  || { no "no authority line was printed; the composition is not observable"; dump; }
getf(){ printf '%s' "$AUTHLINE" | tr ' ' '\n' | awk -F= -v k="$1" '$1==k{print $2; exit}'; }
AEV="$(getf assertion-evidence-licensed)"; REV="$(getf registry-evidence-licensed)"; EFF="$(getf effective)"
[ "$AEV" = "gate" ] \
  && ok "the ASSERTION on its own licenses \`gate\` — so the test below has something real to suppress" \
  || no "the assertion licenses '$AEV', not gate; this fixture would prove nothing"
[ "$REV" = "observe" ] \
  && ok "the REGISTRY's own token licenses \`observe\` — the two terms genuinely disagree" \
  || no "the registry term licenses '$REV', not observe"
[ "$EFF" = "observe" ] \
  && ok "and the EFFECTIVE licence is \`observe\`: the minimum wins, so evidence lowered and did not raise" \
  || no "the effective licence is '$EFF' — an assertion raised a control above what the registry's own evidence allows"
[ "$(rank_of "$EFF")" -le "$(rank_of "$REV")" ] \
  && ok "effective <= registry-evidence, checked as an inequality over the ladder rather than as a matched string" \
  || no "effective '$EFF' outranks registry-evidence '$REV'"
grep -qE '^authority: fixture\.raiser .*raised=no' "$WORK/out.txt" \
  && ok "the tool states \`raised=no\` as a DERIVED verdict beside the numbers it derived it from" \
  || { no "the tool does not report whether the evidence raised anything"; dump; }
# And the one-directionality must be stated where an operator reads it, not
# merely be true of today's arithmetic.
run schema >/dev/null
grep -qiE '^rule: .*(may lower|never raise|cannot raise)' "$WORK/out.txt" \
  && ok "and \`schema\` states the rule — evidence may lower authority and may not raise it" \
  || { no "the one-directional rule is not declared in the schema output"; dump; }
# A scoped `supported` claim must NOT project to a token that licenses `gate`.
# The legacy field carries no scope; spelling a scoped support claim into it as
# `field_observed` would be the overclaim this whole packet is about.
SUPPROJ="$(awk '$1=="status:" && $2=="supported"{for(i=3;i<=NF;i++) if($i ~ /^legacy-projection=/){sub(/^legacy-projection=/,"",$i); print $i}}' "$WORK/out.txt")"
[ "$SUPPROJ" = "unvalidated" ] \
  && ok "a scoped \`supported\` claim projects GLOBALLY to \`unvalidated\` — the legacy field has no scope, so it cannot carry a scoped support claim without overclaiming" \
  || no "\`supported\` projects to '$SUPPROJ'; anything that licenses more than \`advise\` globally is the overclaim"

echo "== 9. EVIDENCE REFERENCES USE STABLE IDS (5.5.9) =="
BADID=0
while IFS= read -r i; do
  [ -n "$i" ] || continue
  printf '%s\n' "$i" | grep -qE "$EV_ID_RE" || { BADID=$((BADID+1)); echo "      | '$i' is not an EV-NNNN[-slug] stable id"; }
done < <(sed -n 's/^evidence: //p' "$STORE")
[ "$BADID" -eq 0 ] \
  && ok "every assertion is keyed by an EV-NNNN[-slug] stable id — an id that survives every edit to every file" \
  || no "$BADID assertion key(s) are not stable ids"
DUP="$(sed -n 's/^evidence: //p' "$STORE" | sort | uniq -d)"
[ -z "$DUP" ] \
  && ok "no id is used twice — a store that accepts a duplicate id resolves references to whichever stanza it hits first" \
  || no "duplicate evidence id(s): $(printf '%s' "$DUP" | tr '\n' ' ')"
# `supersedes` is a REFERENCE, so it must be an id and must resolve.
BADSUP=0
while IFS= read -r i; do
  [ -n "$i" ] || continue
  s="$(fld "$i" supersedes "$STORE")"
  [ "$s" = "none" ] && continue
  printf '%s\n' "$s" | grep -qE "$EV_ID_RE" || { BADSUP=$((BADSUP+1)); echo "      | $i supersedes '$s', which is not a stable id"; continue; }
  grep -qxF "evidence: $s" "$STORE" || { BADSUP=$((BADSUP+1)); echo "      | $i supersedes '$s', which is in no stanza of this store"; }
done < <(sed -n 's/^evidence: //p' "$STORE")
[ "$BADSUP" -eq 0 ] \
  && ok "every \`supersedes\` names \`none\` or an id that resolves in this store — a dangling supersession silently keeps two live claims" \
  || no "$BADSUP dangling or malformed supersession(s)"
# NOTHING is identified by a line number. Seven consecutive packets shipped a
# stale `:NNN`; the identity fields here must not be able to go stale that way.
LINEID=0
for f in subject_id claim_id supersedes; do
  n="$(awk -F': ' -v f="$f" '$1==f && $2 ~ /:[0-9]+$/' "$STORE" | grep -c . || true)"
  [ "${n:-0}" = "0" ] || { LINEID=$((LINEID+n)); echo "      | $f carries a path:line in $n record(s)"; }
done
[ "$LINEID" -eq 0 ] \
  && ok "no identity field carries a \`path:line\` — line numbers stay navigation hints and are never identity" \
  || no "$LINEID identity field(s) are line-anchored"
# Every subject must resolve to something the census actually knows about.
BADSUBJ=0
while IFS= read -r s; do
  [ -n "$s" ] || continue
  grep -qxF "control: $s" "$REG" || grep -qxF "control_id: $s" "$MUTREG" \
    || { BADSUBJ=$((BADSUBJ+1)); echo "      | subject '$s' is in neither the control census nor the mutator census"; }
done < <(awk -F': ' '$1=="subject_id"{print $2}' "$STORE" | sort -u)
[ "$BADSUBJ" -eq 0 ] \
  && ok "every subject_id names a registered control or mutator — an assertion about nothing is evidence about nothing" \
  || no "$BADSUBJ subject(s) name no registered object"
# ...and the tool must ENFORCE that rather than this suite merely observing it.
sed "s/^subject_id: $SUBJECT\$/subject_id: maint.no_such_control/" "$STORE" > "$WORK/ghost.txt"
RC="$(run validate --store "$WORK/ghost.txt" --registry "$REG")"
[ "$RC" = "2" ] \
  && ok "RED: an assertion about an unregistered subject is REFUSED" \
  || { no "an assertion about a nonexistent subject exited $RC"; dump; }
sed "s/^evidence: EV-/evidence: EVIDENCE_/" "$STORE" > "$WORK/badkey.txt"
RC="$(run validate --store "$WORK/badkey.txt" --registry "$REG")"
[ "$RC" = "2" ] \
  && ok "RED: a key that is not an EV-NNNN stable id is REFUSED" \
  || { no "a malformed id exited $RC"; dump; }

echo "== 10. The derivation refuses what it cannot trust, and only that =="
# The same split evidence-policy.sh draws: the CONTENT of the projection advises
# and exits 0 whatever it finds; a derivation that cannot be read at all refuses.
RC="$(run validate --store "$WORK/nosuchfile.txt" --registry "$REG")"
[ "$RC" = "2" ] \
  && ok "an absent store is REFUSED — an absent census is not a clean one" \
  || { no "an absent store exited $RC"; dump; }
printf '# a header and nothing else\n' > "$WORK/emptystore.txt"
RC="$(run validate --store "$WORK/emptystore.txt" --registry "$REG")"
[ "$RC" = "2" ] \
  && ok "a store that parses to ZERO assertions is REFUSED — a check over nothing passes for every store, including one somebody emptied" \
  || { no "an empty store exited $RC"; dump; }
RC="$(run project --store "$STORE" --registry "$WORK/nosuchreg.txt")"
[ "$RC" = "2" ] \
  && ok "an absent control registry is REFUSED — the class term of the minimum would otherwise be unknown, and an unknown term must never default to permissive" \
  || { no "an absent registry exited $RC"; dump; }
sed 's/^field: /XX: /' /dev/null >/dev/null 2>&1
awk '{print} /^supersedes: /{print "wibble: 1"}' "$STORE" > "$WORK/unknownfield.txt"
RC="$(run validate --store "$WORK/unknownfield.txt" --registry "$REG")"
[ "$RC" = "2" ] \
  && ok "an UNKNOWN field name is REFUSED — a typo that is ignored is a value silently lost" \
  || { no "an unknown field exited $RC"; dump; }
RC="$(run)";                 [ "$RC" = "2" ] && ok "no command is REFUSED (exit 2)"      || { no "no command exited $RC"; dump; }
RC="$(run wibble)";          [ "$RC" = "2" ] && ok "an unknown command is REFUSED"        || { no "an unknown command exited $RC"; dump; }
RC="$(run validate --store)";[ "$RC" = "2" ] && ok "an option missing its value is REFUSED" || { no "a valueless --store exited $RC"; dump; }
RC="$(run validate --nope x)";[ "$RC" = "2" ] && ok "an unknown option is REFUSED"        || { no "an unknown option exited $RC"; dump; }

echo "== 13. \`valid_until\` IS ENFORCED, AND IN THE ONE DIRECTION THAT CANNOT FLATTER =="
# THE GAP THIS CLOSES, IN THE FILE'S OWN WORDS. evidence_assertions.txt said
# "nothing … notices an assertion going stale against the `valid_until` it
# declares"; control_registry.txt said the field "is recorded so that a later
# packet can enforce it". This is that packet, and enforcement is split because
# the two directions are not the same act:
#
#   VALIDATE REFUSES a dated `valid_until` that has passed. A store asserting
#   evidence its own author dated out is a store nobody re-measured, and the
#   remedy is a human one — re-date it, or supersede it.
#
#   PROJECT REPORTS it LAPSED and KEEPS IT IN THE MINIMUM. This is the half that
#   matters. Assertion evidence can only LOWER a licence, so DROPPING a lapsed
#   assertion would RAISE one — a lapsed refutation silently stops binding and
#   the control reads better than it did. That is the flattering-direction error
#   this whole store exists to catch, so a lapsed assertion is named and never
#   dropped.
#
# THE COST IS STATED, NOT HIDDEN: a dated `valid_until` becomes a commitment
# that comes due, and the day it does the suite goes red with no code change.
# That is the field meaning something. Today every live assertion carries an
# `open` term, so the gate is inert on the live store BY CONSTRUCTION.
export BUILD_OS_NOW="2026-08-01"
LIVE_OPEN="$(awk '/^valid_until: /{ if ($2 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/) n++ } END{print n+0}' "$STORE")"
[ "$LIVE_OPEN" = "0" ] \
  && ok "every assertion in the live store carries an OPEN term, so this gate is inert on today's store by construction rather than by luck" \
  || no "$LIVE_OPEN live assertion(s) carry a dated valid_until; the gate below is no longer inert and the store must be re-dated"
# A dated term still in the future must pass — otherwise the refusal below would
# prove only that dates are refused.
sed 's|^valid_until: open.*|valid_until: 2099-01-01 — a fixture term that has not come due|' "$STORE" > "$WORK/vu_future.txt"
RC="$(run validate --store "$WORK/vu_future.txt" --registry "$REG")"
[ "$RC" = "0" ] \
  && ok "a DATED \`valid_until\` still in the future validates — the check is a clock comparison, not a ban on dates" \
  || { no "a future-dated valid_until exited $RC"; dump; }
sed 's|^valid_until: open.*|valid_until: 2026-01-01 — a fixture term that came due seven months ago|' "$STORE" > "$WORK/vu_past.txt"
RC="$(run validate --store "$WORK/vu_past.txt" --registry "$REG")"
[ "$RC" = "2" ] \
  && ok "RED: a \`valid_until\` that has PASSED is REFUSED — the field the registry said a later packet would enforce is enforced" \
  || { no "RED FAILED: a lapsed valid_until exited $RC; the field is still recorded and unenforced"; dump; }
grep -qi 'valid_until' "$WORK/out.txt" \
  && ok "and the refusal names the field, so the fix is readable from it" \
  || { no "the refusal does not name valid_until"; dump; }
# THE DIRECTION. `project` must NAME the lapse and must NOT drop the assertion:
# EV-0001 is a REFUTATION, and a refutation that stopped binding when its term
# came due would raise the licence of the control it refutes.
RC="$(run project --store "$WORK/vu_past.txt" --registry "$REG" --subject "$SUBJECT")"
[ "$RC" = "0" ] \
  && ok "\`project\` still ADVISES over a lapsed store — it reports and exits 0" \
  || { no "project exited $RC on a lapsed store"; dump; }
grep -q 'LAPSED' "$WORK/out.txt" \
  && ok "...and NAMES the lapse where the projection is read" \
  || { no "project does not report a lapsed assertion"; dump; }
LAPSED_TOK="$(awk '$1=="projection:" && $2=="'"$SUBJECT"'"{for(i=1;i<=NF;i++) if(index($i,"legacy-empirical-status=")==1){sub(/^legacy-empirical-status=/,"",$i); print $i; exit}}' "$WORK/out.txt")"
case ",$LAPSED_TOK," in
  *,refuted,*) ok "...and the lapsed REFUTATION is STILL in the composite ($LAPSED_TOK) — dropping it would have RAISED a licence, which is the one direction this store may never move" ;;
  *) no "the lapsed refutation was dropped from the composite (got '$LAPSED_TOK'); enforcement became a laundering channel"; dump ;;
esac
# THE WINDOW HAS TWO ENDS, AND THE SECOND ONE IS THE SAME DEFECT. `valid_from` is
# as much a term as `valid_until`: an assertion whose term has not begun has not
# begun, and a store that enforced one end and not the other would be the
# decorative-window defect one artefact along from where it was found.
sed 's|^valid_from: .*|valid_from: 2099-01-01|' "$STORE" > "$WORK/vf_future.txt"
RC="$(run validate --store "$WORK/vf_future.txt" --registry "$REG")"
[ "$RC" = "2" ] \
  && ok "RED: a \`valid_from\` that has NOT ARRIVED is REFUSED too — the term is enforced at BOTH ends, not just the one that was asked about" \
  || { no "RED FAILED: a not-yet-live assertion exited $RC; the window is decorative at its opening end"; dump; }
RC="$(run project --store "$WORK/vf_future.txt" --registry "$REG" --subject "$SUBJECT")"
grep -q 'NOT-YET-LIVE' "$WORK/out.txt" \
  && ok "...and \`project\` names it NOT-YET-LIVE — a distinct state from LAPSED, because a term that has not opened and a term that ended are different facts" \
  || { no "project does not distinguish a not-yet-live assertion from a lapsed one"; dump; }
# And the clock is the SAME clock. A second private date in this tool is how one
# tool honours an override and another quietly does not.
grep -qE 'date[[:space:]]+\+%' "$TOOL" \
  && no "claim-evidence.sh computes its own wall-clock date instead of sourcing the one the envelope tool owns" \
  || ok "claim-evidence.sh computes no date of its own — one clock, one owner, sourced like the caps are"

echo "== 11. The tool and its store are registered control surfaces =="
grep -qF "owning_module: build-os/tools/claim-evidence.sh" "$REG" \
  && ok "the tool owns at least one registry entry" \
  || no "the tool can exit 2 and owns no registry entry"
gated_by(){ awk -v m="$1" '
  /^control: /{c=$2; g=0; f=0}
  /^runtime_authority: gate$/{g=1}
  $0=="owning_module: "m{f=1}
  /^$/{if(g&&f)print c; c=""; g=0; f=0}
  END{if(g&&f)print c}' "$REG"; }
advised_by(){ awk -v m="$1" '
  /^control: /{c=$2; a=0; f=0}
  /^runtime_authority: advise$/{a=1}
  $0=="owning_module: "m{f=1}
  /^$/{if(a&&f)print c; c=""; a=0; f=0}
  END{if(a&&f)print c}' "$REG"; }
GID="$(gated_by build-os/tools/claim-evidence.sh | head -1)"
[ -n "$GID" ] \
  && ok "its refusal path is classified at authority \`gate\` ($GID), as the anti-shelfware scan requires of anything that can stop a run" \
  || no "the tool exits 2 but no entry records it at gate"
AID="$(advised_by build-os/tools/claim-evidence.sh | head -1)"
[ -n "$AID" ] \
  && ok "and its projection is classified separately at \`advise\` ($AID) — the two govern different objects" \
  || no "no entry classifies the projection at advise"
[ -n "$AID" ] && [ "$(rfld "$AID" class "$REG")" = "C" ] \
  && ok "$AID is Class C: the projection is chosen policy, not a definition" \
  || no "the projection entry is not registered Class C"
[ -n "$AID" ] && [ "$(rfld "$AID" authority_mismatch "$REG")" = "none" ] \
  && ok "$AID declares NO authority mismatch — Class C at advise is exactly its licence" \
  || no "$AID declares a mismatch a Class-C control at advise must not"
[ -n "$GID" ] && [ "$(rfld "$GID" class "$REG")" = "A" ] \
  && ok "$GID is Class A: whether a stanza can be read at all is an invariant, not a matter of degree" \
  || no "the schema gate is not registered Class A"

echo "== 12. This suite is chained, and is not vacuous about itself =="
grep -qF 'chain_suite "tests/claim_evidence_tests.sh"' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained from tests/build_os_tests.sh (not discoverable-only)" \
  || no "this suite is present but never chained from tests/build_os_tests.sh"
# A DERIVED floor: more assertions than the schema has fields plus statuses. It
# states no numeric literal, so it does not join the tests.nonvacuity_minimums
# family that tests/control_registry_tests.sh §21 polices.
NF_=0; for _f in $EV_FIELDS; do NF_=$((NF_+1)); done
NS_=0; for _s in $EV_STATUSES; do NS_=$((NS_+1)); done
FLOOR=$((NF_ + NS_))
[ "$PASS" -gt "$FLOOR" ] \
  && ok "this suite ran $PASS assertions, more than the $FLOOR schema fields and statuses it pins" \
  || no "this suite ran only $PASS assertions against $FLOOR pinned schema elements"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
