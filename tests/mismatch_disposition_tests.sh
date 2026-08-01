#!/usr/bin/env bash
# Build OS — mismatch disposition tests.
#
# WHAT THIS PINS. `MISMATCHES.md` names four things an operator may do about a
# control that exercises more authority than its class licenses: demote the
# authority, correct the class, improve the evidence, retire the control. There
# was no fifth, and `maint.tripwire_coverage_scan` is the case that needs one:
# its demotion was APPLIED LITERALLY AND MEASURED, and it converted the
# maintenance layer's only PREVENTION into detection after the fact — the gated
# arm exits 1 with the tree UNTOUCHED and the demoted arm exits 1 with live
# memory DESTROYED. Both arms exit 1, so nothing watching exit codes can see the
# difference. The remedy the report prescribes is the one the measurement
# refuses.
#
# `accept_and_constrain` is the fifth disposition and it is NOT an exception:
#
#   1. IT CLEARS NOTHING. The subject keeps `authority_mismatch: declared`,
#      keeps its row in the MISMATCHES.md summary table, and keeps its
#      OUT-OF-LICENCE finding from `evidence-policy.sh check`. A disposition
#      RECORDS that a mismatch is being CARRIED, names the constraint that
#      bounds it, and keeps it visible. Section 5 asserts all three against the
#      live tree, so a future edit that quietly clears the mismatch fails here.
#   2. IT APPLIES NARROWLY, AND THE NARROWNESS IS THE HARD PART. Two maintenance
#      controls sit beside each other in the census and only ONE qualifies:
#
#        maint.tripwire_coverage_scan   demotion MEASURED AND REFUSED  qualifies
#        maint.source_scan_mask         demotion REACHABLE             REFUSED
#
#      Section 3 is the discipline test. A disposition that swallows both is
#      useless, so `maint.source_scan_mask` must be REFUSED and the refusal must
#      SAY WHY — quoting the census's own `demotion_requirement`, which records
#      the demotion as reachable, rather than restating a reason here.
#   3. EVERY QUALIFYING CONDITION BINDS ON ITS OWN. Section 4 drives each of the
#      four conditions red separately, so a predicate that passed because one
#      strong condition carried three dead ones would fail here.
#   4. THE VOCABULARY IS SWEPT AS A CLASS, NOT AS A PAIR. Section 8 requires
#      every file under build-os/tools, build-os/registry and tests/ that names
#      ANY disposition kind to name ALL of them. That is the F1 defect class —
#      one copy of a vocabulary updated and another left short — written for the
#      class in the same pass that introduces the vocabulary, rather than after
#      a reviewer finds the divergence.
#
# No network. Deterministic — the clock is pinned through BUILD_OS_NOW, so no
# assertion here changes meaning on a calendar date. Every fixture lives under
# $WORK; nothing outside it is written. Exits non-zero if any assertion fails.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$SRC/build-os/tools/mismatch-disposition.sh"
ENVTOOL="$SRC/build-os/tools/authority-envelope.sh"
EPOL="$SRC/build-os/tools/evidence-policy.sh"
STORE="$SRC/build-os/registry/mismatch_dispositions.txt"
REG="$SRC/build-os/registry/control_registry.txt"
MISM="$SRC/build-os/registry/MISMATCHES.md"

# THE CLOCK IS PINNED. A suite that reads the wall clock rots: every date
# fixture below would change meaning in 2027 and the failure would look like a
# regression. The tool takes `now` from this variable, and it SAYS SO in its
# output when it is set — an override that could silently un-expire a record
# would be worse than no override at all, and section 7 asserts the notice.
export BUILD_OS_NOW="2026-08-01"
PINNED_NOW="$BUILD_OS_NOW"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

run(){ "$TOOL" "$@" > "$WORK/out.txt" 2> "$WORK/err.txt"; echo "$?"; }
out(){ cat "$WORK/out.txt" "$WORK/err.txt"; }
dump(){ sed 's/^/      | /' "$WORK/out.txt" "$WORK/err.txt" | head -14; }

# The five kinds, duplicated here ON PURPOSE — the same device
# tests/evidence_policy_tests.sh uses for the three axes. A suite that read its
# expected vocabulary out of the tool it is checking could not notice the tool
# quietly dropping a kind or inventing one.
KINDS="demote_authority correct_class improve_evidence retire_control accept_and_constrain"
NKIND=0; for _k in $KINDS; do NKIND=$((NKIND+1)); done
DISP_FIELDS="subject_id kind mismatch_summary alternatives_considered demotion_measurement measured_harm constraint constraint_enforced_by visibility recorded_at recorded_by reviewed_by review_by supersedes"
NDFIELD=0; for _f in $DISP_FIELDS; do NDFIELD=$((NDFIELD+1)); done

# mkdisp <file> <subject> <kind> [measurement] [review_by] — a store carrying one
# COMPLETE record. Every field the schema demands is emitted, so a fixture is a
# real disposition and not a shape only this suite would accept.
mkdisp(){
  local f="$1" subj="$2" kind="$3" meas="${4:-COVERAGE-GATE-PREVENTION-DIFFERENTIAL}" rev="${5:-2027-02-01}"
  { printf '# synthetic disposition fixture\n\n'
    printf 'disposition: DISP-0001-fixture\n'
    printf 'subject_id: %s\n' "$subj"
    printf 'kind: %s\n' "$kind"
    printf 'mismatch_summary: a fixture mismatch\n'
    printf 'alternatives_considered: a fixture considered the other four kinds and closed each\n'
    printf 'demotion_measurement: %s\n' "$meas"
    printf 'measured_harm: a fixture harm, measured\n'
    printf 'constraint: the fixture is bounded to this fixture\n'
    printf 'constraint_enforced_by: the fixture itself\n'
    printf 'visibility: the fixture summary table\n'
    printf 'recorded_at: 2026-08-01\n'
    printf 'recorded_by: a fixture\n'
    printf 'reviewed_by: a fixture reviewer\n'
    printf 'review_by: %s\n' "$rev"
    printf 'supersedes: none\n'
  } > "$f"
}

echo "== 0. Every artefact this layer is made of exists =="
[ -f "$TOOL" ]  && ok "build-os/tools/mismatch-disposition.sh exists" || no "the disposition validator is missing"
[ -x "$TOOL" ]  && ok "the tool is executable"                        || no "the tool is not executable"
[ -f "$STORE" ] && ok "build-os/registry/mismatch_dispositions.txt exists" || no "the disposition store is missing"
head -1 "$TOOL" | grep -qE '^#!' && ok "the tool carries a shebang" || no "the tool has no shebang"

echo "== 1. THE VOCABULARY IS FIVE KINDS, DECLARED WHERE A READER FINDS THEM =="
RC="$(run schema)"
[ "$RC" = "0" ] && ok "\`schema\` exits 0" || { no "\`schema\` exited $RC"; dump; }
VOCAB="$(awk '$1=="vocabulary:" && $2=="disposition_kind"{for(i=3;i<=NF;i++) print $i}' "$WORK/out.txt" | LC_ALL=C sort)"
[ "$VOCAB" = "$(printf '%s\n' $KINDS | LC_ALL=C sort)" ] \
  && ok "the declared vocabulary is exactly the five kinds: $KINDS" \
  || { no "the declared vocabulary is not the five kinds"; diff <(printf '%s\n' "$VOCAB") <(printf '%s\n' $KINDS | LC_ALL=C sort) | sed 's/^/      | /'; }
KBAD=0
for k in $KINDS; do
  grep -qE "^kind: $k " "$WORK/out.txt" || { KBAD=$((KBAD+1)); echo "      | kind $k is in the vocabulary but has no explanatory row"; }
done
[ "$KBAD" -eq 0 ] && ok "each of the $NKIND kinds carries a row saying what it means" || no "$KBAD kind(s) are named and never explained"
# The standing ruling, asserted where it is read: this is not a promotion
# instrument. A vocabulary that could raise authority would be the failure the
# whole registry exists against.
grep -qi 'raises no' "$WORK/out.txt" \
  && ok "the schema states that a disposition RAISES NO AUTHORITY — class correction and demotion, not a promotion instrument" \
  || { no "the schema never says a disposition cannot raise authority"; dump; }
grep -qi 'clears no\|does not clear' "$WORK/out.txt" \
  && ok "...and that it CLEARS NO MISMATCH — it records one being carried" \
  || { no "the schema never says a disposition clears nothing"; dump; }

echo "== 2. THE LIVE STORE VALIDATES, and it disposes exactly ONE control =="
RC="$(run validate)"
[ "$RC" = "0" ] && ok "\`validate\` on the live store exits 0" || { no "\`validate\` on the live store exited $RC"; dump; }
RC="$(run list)"
[ "$RC" = "0" ] && ok "\`list\` on the live store exits 0" || { no "\`list\` exited $RC"; dump; }
NDISP="$(grep -c '^disposition: ' "$WORK/out.txt" || true)"; NDISP="${NDISP:-0}"
[ "$NDISP" -ge 1 ] \
  && ok "the store carries $NDISP live disposition(s) — the mechanism has an occupant rather than only a schema" \
  || { no "the store carries no disposition at all; a vocabulary with no live record is shelfware"; dump; }
# DISPOSING ONE IS THE PACKET. Disposing twenty is the bulk application the
# operator's ruling forbids, so the ceiling is asserted rather than trusted.
NDECL="$(grep -c '^authority_mismatch: declared$' "$REG" || true)"; NDECL="${NDECL:-0}"
NAC="$(awk '$1=="disposition:"{for(i=1;i<=NF;i++) if($i=="kind=accept_and_constrain") n++} END{print n+0}' "$WORK/out.txt")"
[ "$NAC" -eq 1 ] \
  && ok "exactly ONE control is disposed \`accept_and_constrain\` — not bulk-applied to the census's $NDECL declared mismatches" \
  || { no "$NAC controls are disposed accept_and_constrain; the ruling permits the mechanism, not a bulk clearance"; dump; }
grep -q 'subject=maint.tripwire_coverage_scan' "$WORK/out.txt" \
  && ok "and the disposed control is \`maint.tripwire_coverage_scan\` — the one whose demotion was MEASURED and refused" \
  || { no "the disposed control is not maint.tripwire_coverage_scan"; dump; }

echo "== 3. THE DISCIPLINE TEST — \`maint.source_scan_mask\` is REFUSED, and the refusal says WHY =="
# The negative case, and the only one that proves the predicate discriminates. A
# predicate that cannot tell these two apart is too weak; the fixture is not
# relaxed to fit it.
mkdisp "$WORK/mask.txt" "maint.source_scan_mask" "accept_and_constrain"
RC="$(run validate --store "$WORK/mask.txt")"
[ "$RC" = "2" ] \
  && ok "RED: \`accept_and_constrain\` on maint.source_scan_mask is REFUSED (exit 2)" \
  || { no "RED FAILED: disposing maint.source_scan_mask exited $RC — the predicate swallows both fixtures and discriminates nothing"; dump; }
out | grep -q 'maint.source_scan_mask' \
  && ok "the refusal NAMES the subject it refused" \
  || { no "the refusal does not name the subject"; dump; }
# WHY, sourced from the census rather than restated here. The subject's own
# `demotion_requirement` records the demotion as REACHABLE, and the tool quotes
# it — so the reason a reviewer reads is the census's word and not this tool's.
out | grep -q 'REACHABLE' \
  && ok "and the refusal says WHY — it quotes the census's own \`demotion_requirement\`, which records this demotion as REACHABLE" \
  || { no "the refusal does not surface the census's demotion_requirement, so a reader is told no and not told why"; dump; }
out | grep -qi 'authority_mismatch' \
  && ok "...and names the other half: the census records no mismatch for it, so there is nothing to carry" \
  || { no "the refusal never mentions that the subject carries no declared mismatch"; dump; }
# The positive control for the same fixture builder: the SAME shape, on the
# subject that DOES qualify, must pass. Otherwise the refusal above proves only
# that the fixture is malformed.
mkdisp "$WORK/tripwire.txt" "maint.tripwire_coverage_scan" "accept_and_constrain"
RC="$(run validate --store "$WORK/tripwire.txt")"
[ "$RC" = "0" ] \
  && ok "and the SAME record shape on maint.tripwire_coverage_scan VALIDATES — the refusal above is about the subject, not about the fixture" \
  || { no "the qualifying subject was refused too ($RC); the refusal above proves nothing"; dump; }

echo "== 4. EACH QUALIFYING CONDITION BINDS ON ITS OWN — driven red separately =="
# (a) there must BE a mismatch to carry
mkdisp "$WORK/q_a.txt" "metrics.record.schema_invariant" "accept_and_constrain"
RC="$(run validate --store "$WORK/q_a.txt")"
[ "$RC" = "2" ] \
  && ok "RED (a): a subject carrying \`authority_mismatch: none\` is REFUSED — accept_and_constrain carries a mismatch, it does not invent one" \
  || { no "RED FAILED (a): a control with no declared mismatch was disposed anyway ($RC)"; dump; }
# (b) the measurement must be the CENSUS's record, not this store's assertion
mkdisp "$WORK/q_b.txt" "maint.tripwire_coverage_scan" "accept_and_constrain" "SOME-MEASUREMENT-NOBODY-RECORDED"
RC="$(run validate --store "$WORK/q_b.txt")"
[ "$RC" = "2" ] \
  && ok "RED (b): a \`demotion_measurement\` the subject's own census entry does not name is REFUSED — the store may not assert a measurement into existence" \
  || { no "RED FAILED (b): an unrecorded measurement was accepted ($RC)"; dump; }
# (c) the measurement must EXIST as an artefact somewhere other than the two
#     records that cite it
FAKEREG="$WORK/q_c_reg.txt"
# THE TOKEN IS BUILT AT RUN TIME AND NEVER WRITTEN IN THIS FILE. A literal would
# occur in this suite's own source, which lives under the repository the
# artefact search scans — so condition (d) would be satisfied BY THE TEST THAT
# EXISTS TO FALSIFY IT, and the assertion would pass against a tool that never
# looked.
GHOST_MEAS="ABSENT-MEASUREMENT-$$-$(date +%s 2>/dev/null || echo x)"
awk -v m="$GHOST_MEAS" '{ if ($0 ~ /^demotion_requirement: MEASURED AND REFUSED/) print "demotion_requirement: MEASURED AND REFUSED, not open. The measurement is " m "."; else print }' "$REG" > "$FAKEREG"
mkdisp "$WORK/q_c.txt" "maint.tripwire_coverage_scan" "accept_and_constrain" "$GHOST_MEAS"
RC="$(run validate --store "$WORK/q_c.txt" --registry "$FAKEREG")"
[ "$RC" = "2" ] \
  && ok "RED (c): a measurement that appears in no artefact under the repo is REFUSED — \"measured\" means an artefact exists, not that two records agree" \
  || { no "RED FAILED (c): a measurement with no artefact was accepted ($RC)"; dump; }
# (d) the carried mismatch must stay VISIBLE where it is read
BLANKMM="$WORK/q_d_mism.md"
awk '/<!-- MISMATCH-TABLE:START -->/{print; f=1; next} /<!-- MISMATCH-TABLE:END -->/{f=0} f && /maint.tripwire_coverage_scan/{next} {print}' "$MISM" > "$BLANKMM"
mkdisp "$WORK/q_d.txt" "maint.tripwire_coverage_scan" "accept_and_constrain"
RC="$(run validate --store "$WORK/q_d.txt" --mismatches "$BLANKMM")"
[ "$RC" = "2" ] \
  && ok "RED (d): a subject missing from the MISMATCHES.md summary table is REFUSED — a carried mismatch that reaches no report is a cleared one" \
  || { no "RED FAILED (d): a subject absent from the anchor table was disposed anyway ($RC)"; dump; }
# ...and the four conditions apply to `accept_and_constrain` ONLY. The other
# four kinds are ordinary remedies and must not inherit this bar.
mkdisp "$WORK/q_other.txt" "maint.source_scan_mask" "improve_evidence"
RC="$(run validate --store "$WORK/q_other.txt")"
[ "$RC" = "0" ] \
  && ok "and the bar is scoped to \`accept_and_constrain\`: the same subject takes \`improve_evidence\` without it" \
  || { no "the qualification predicate fires on a kind it does not govern ($RC)"; dump; }

echo "== 5. A DISPOSITION CLEARS NOTHING — asserted against the LIVE tree =="
# The whole ruling, mechanically. If any of these three ever passes the other
# way, `accept_and_constrain` has become the operator exception it must not be.
SUBJ="maint.tripwire_coverage_scan"
awk -v i="$SUBJ" '$0=="control: "i{f=1;next} /^$/{f=0} f && /^authority_mismatch: /{print}' "$REG" | grep -qx 'authority_mismatch: declared' \
  && ok "the disposed control STILL declares \`authority_mismatch: declared\` in the census" \
  || no "the disposed control's mismatch was cleared in the census — the disposition became an exception"
awk '/<!-- MISMATCH-TABLE:START -->/{f=1;next} /<!-- MISMATCH-TABLE:END -->/{f=0} f' "$MISM" | grep -q "$SUBJ" \
  && ok "...STILL holds its row in the MISMATCHES.md summary table, where a reviewer reads it" \
  || no "the disposed control lost its row in the mismatch table"
"$EPOL" check --repo "$SRC" > "$WORK/epol.txt" 2>&1
grep -q "OUT-OF-LICENCE $SUBJ " "$WORK/epol.txt" \
  && ok "...and is STILL reported OUT-OF-LICENCE by \`evidence-policy.sh check\` — the finding survives its own disposition" \
  || { no "the disposed control is no longer out of licence; recording a disposition changed a licence"; sed 's/^/      | /' "$WORK/epol.txt" | head -4; }
RC="$(run check)"
[ "$RC" = "0" ] && ok "\`check\` ADVISES: it reports and exits 0" || { no "\`check\` exited $RC — a disposition report is gating"; dump; }
grep -q '^carried: ' "$WORK/out.txt" \
  && ok "and \`check\` says in words that the mismatch is CARRIED and not cleared" \
  || { no "\`check\` never states that the mismatch is carried"; dump; }

echo "== 6. THE ONE THING IT REFUSES — every schema refusal state, driven red =="
refuses(){ # <label> <file-body-on-stdin>
  local label="$1" f="$WORK/ref.txt" rc
  cat > "$f"
  rc="$(run validate --store "$f")"
  if [ "$rc" = "2" ]; then ok "REFUSED (exit 2): $label"
  else no "NOT REFUSED (exit $rc): $label"; dump; fi
}
RC="$(run validate --store "$WORK/nosuchfile.txt")"
[ "$RC" = "2" ] && ok "REFUSED (exit 2): an ABSENT store — absent is not empty" || { no "an absent store exited $RC"; dump; }
printf '# a store with no records at all\n' > "$WORK/vac.txt"
RC="$(run validate --store "$WORK/vac.txt")"
[ "$RC" = "2" ] \
  && ok "REFUSED (exit 2): a store that parses to ZERO dispositions — a schema check with nothing to check passes for every store, including one somebody emptied" \
  || { no "an empty store exited $RC"; dump; }
mkdisp "$WORK/base.txt" "maint.tripwire_coverage_scan" "accept_and_constrain"
sed 's/^kind: .*/kind: wibble/' "$WORK/base.txt" | refuses "an unrecognised disposition kind — never defaulted, because a kind nothing caps licenses by omission"
sed '/^constraint: /d'          "$WORK/base.txt" | refuses "a missing required field — a partly declared disposition is an undeclared one"
sed 's/^constraint: .*/constraint: n\/a/' "$WORK/base.txt" | refuses "a \`constraint\` that means \"nothing\" — an unconstrained accept_and_constrain is the operator exception it must not be"
sed 's/^disposition: .*/disposition: not-a-stable-id/' "$WORK/base.txt" | refuses "a key that is not a DISP-NNNN[-slug] stable id"
sed 's/^subject_id: .*/subject_id: no.such.control/'   "$WORK/base.txt" | refuses "a subject in neither census — a disposition of nothing"
sed 's/^review_by: .*/review_by: soon/'                "$WORK/base.txt" | refuses "a \`review_by\` that is not YYYY-MM-DD"
sed 's/^review_by: .*/review_by: 2025-01-01/'          "$WORK/base.txt" | refuses "a \`review_by\` that does not follow \`recorded_at\` — a review that never comes due is no review"
sed 's/^supersedes: .*/supersedes: DISP-9999-nothing/' "$WORK/base.txt" | refuses "a dangling \`supersedes\` — it silently leaves two live dispositions"
{ cat "$WORK/base.txt"; printf 'wibble: a field the schema has no slot for\n'; } | refuses "a field the schema has no slot for — a typo that is ignored is a value silently lost"
{ cat "$WORK/base.txt"; printf '\n'; sed 's/^disposition: .*/disposition: DISP-0002-second/' "$WORK/base.txt" | tail -n +3; } \
  | refuses "TWO live dispositions for one subject — a control cannot be disposed two ways at once"

echo "== 7. THE CLOCK IS SOURCED, NOT COMPUTED, and an override SAYS SO =="
# One tool owns `now`; everything else asks it. A second private clock is how
# one tool honours the override and another quietly does not.
grep -qE 'date[[:space:]]+\+%' "$TOOL" \
  && no "this tool computes its own wall-clock date; the clock is owned by authority-envelope.sh and sourced from it" \
  || ok "this tool computes no date of its own — it sources \`now\` from the one tool that owns the clock"
RC="$(run check)"
grep -qE "^clock: now=$PINNED_NOW " "$WORK/out.txt" \
  && ok "\`check\` prints the date it is reasoning from, so no reader has to guess which day the verdict is for" \
  || { no "\`check\` does not print the clock it used"; dump; }
grep -E "^clock: " "$WORK/out.txt" | grep -qi 'overrid' \
  && ok "and it SAYS the clock is OVERRIDDEN — an override that could silently un-expire a record would be worse than no override" \
  || { no "\`check\` does not report that BUILD_OS_NOW is in force"; dump; }
# A review date in the past is REPORTED and does NOT refuse. The asymmetry is
# deliberate and it is the "in whichever direction it pointed" rule: deleting a
# disposition because its review lapsed would make the CARRIED MISMATCH LESS
# VISIBLE, which is the opposite of what the record exists for.
mkdisp "$WORK/due.txt" "maint.tripwire_coverage_scan" "accept_and_constrain" "COVERAGE-GATE-PREVENTION-DIFFERENTIAL" "2026-07-01"
RC="$(run check --store "$WORK/due.txt")"
[ "$RC" = "0" ] \
  && ok "a disposition past its \`review_by\` is REPORTED and not refused — dropping it would hide the mismatch it carries" \
  || { no "a lapsed review refused (exit $RC); that deletes the record of a carried mismatch"; dump; }
grep -q 'REVIEW-DUE' "$WORK/out.txt" \
  && ok "...and it is named REVIEW-DUE, so a carried mismatch cannot quietly become a permanent one" \
  || { no "a disposition past its review date is not flagged"; dump; }
RC="$(run check --store "$WORK/base.txt")"
grep -q 'REVIEW-DUE' "$WORK/out.txt" \
  && no "a disposition INSIDE its review window is flagged REVIEW-DUE too, so the flag discriminates nothing" \
  || ok "and a disposition inside its window is NOT flagged — the state discriminates"

echo "== 8. THE VOCABULARY IS SWEPT AS A CLASS — every restatement carries all five kinds =="
# THE F1 DEFECT CLASS, written for the class in the pass that introduces the
# vocabulary. F1 was created by a packet that updated one copy of EVIDENCE_AXIS
# and left another at five tokens, producing a live over-grant inside the
# over-grant detector. A vocabulary spelled in a tool, a store comment, a report
# and a suite will be restated four times; this requires every restatement to be
# COMPLETE. The anchor is a NAME, not a count: a numeric floor stays satisfied
# when the sweep finds three copies of the wrong thing.
# A KIND IS MATCHED AS A WHOLE TOKEN, NEVER AS A SUBSTRING — the same anchoring
# scan-controls.sh §5 uses on nested control ids, and for the same reason. This
# packet is named `gravito_p3_accept_and_constrain_a` and one of its controls is
# `disposition.accept_and_constrain_qualification`, so an unanchored match would
# read every mention of the PACKET as a restatement of the VOCABULARY and demand
# the other four kinds beside it. That is a sweep measuring its own name.
kind_re(){ printf '(^|[^A-Za-z0-9_])%s([^A-Za-z0-9_]|$)' "$1"; }
VBAD=0; VSEEN=0; VFILES=""
while IFS= read -r vf; do
  [ -n "$vf" ] || continue
  NAMED=0; MISSING=""
  for k in $KINDS; do
    if grep -qE "$(kind_re "$k")" "$vf"; then NAMED=$((NAMED+1)); else MISSING="$MISSING $k"; fi
  done
  [ "$NAMED" -eq 0 ] && continue
  VSEEN=$((VSEEN+1)); VFILES="$VFILES
${vf#"$SRC"/}"
  [ -z "$MISSING" ] || { VBAD=$((VBAD+1)); echo "      | ${vf#"$SRC"/} names some disposition kinds and omits:$MISSING"; }
done < <(grep -rl -e demote_authority -e correct_class -e improve_evidence -e retire_control -e accept_and_constrain \
           "$SRC/build-os/tools" "$SRC/build-os/registry" "$SRC/tests" 2>/dev/null | sort)
{ printf '%s\n' "$VFILES" | grep -qxF 'build-os/tools/mismatch-disposition.sh' \
  && printf '%s\n' "$VFILES" | grep -qxF 'build-os/registry/mismatch_dispositions.txt' \
  && printf '%s\n' "$VFILES" | grep -qxF 'build-os/registry/MISMATCHES.md' \
  && [ "$VBAD" -eq 0 ]; } \
  && ok "all $VSEEN file(s) restating the disposition vocabulary carry every one of the $NKIND kinds — the tool, the store and the report among them" \
  || no "$VBAD of $VSEEN restatement(s) are incomplete, or the sweep never reached the tool, the store and the report"

echo "== 9. Usage errors refuse rather than guessing =="
RC="$(run)";                  [ "$RC" = "2" ] && ok "no command is REFUSED (exit 2)"        || { no "no command exited $RC"; dump; }
RC="$(run wibble)";           [ "$RC" = "2" ] && ok "an unknown command is REFUSED"          || { no "an unknown command exited $RC"; dump; }
RC="$(run validate --store)"; [ "$RC" = "2" ] && ok "an option missing its value is REFUSED" || { no "a valueless --store exited $RC"; dump; }
RC="$(run check --nope x)";   [ "$RC" = "2" ] && ok "an unknown option is REFUSED"           || { no "an unknown option exited $RC"; dump; }

echo "== 10. It writes nothing, anywhere =="
BEFORE="$(cat "$STORE" "$REG" "$MISM" | cksum)"
run check    >/dev/null
run validate >/dev/null
run list     >/dev/null
AFTER="$(cat "$STORE" "$REG" "$MISM" | cksum)"
[ "$BEFORE" = "$AFTER" ] \
  && ok "the store, the census and the report are byte-identical after three live runs — the tool reads and prints" \
  || no "a live run changed one of the three artefacts it reads"

echo "== 11. The tool, the store and this suite are registered control surfaces =="
grep -qF "owning_module: build-os/tools/mismatch-disposition.sh" "$REG" \
  && ok "the tool owns at least one registry entry" \
  || no "the tool exits non-zero and owns no registry entry"
grep -qF "owning_module: tests/mismatch_disposition_tests.sh" "$REG" \
  && ok "this suite owns a registry entry" \
  || no "this suite exits non-zero and owns no registry entry"
grep -qF "$(basename "$STORE")" "$REG" \
  && ok "the store is named in the census, so it is not an artefact nothing classifies" \
  || no "the disposition store appears nowhere in the census"

echo "== 12. This suite is chained, and is not vacuous about itself =="
grep -qF 'chain_suite "tests/mismatch_disposition_tests.sh"' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained from tests/build_os_tests.sh (not discoverable-only)" \
  || no "this suite is present but never chained from tests/build_os_tests.sh"
# A DERIVED floor: more assertions than the schema's fields plus its kinds. It
# states no numeric literal, so it does not join the tests.nonvacuity_minimums
# family that tests/control_registry_tests.sh §21 polices.
FLOOR=$((NDFIELD + NKIND))
[ "$PASS" -gt "$FLOOR" ] \
  && ok "this suite ran $PASS assertions, more than the $FLOOR schema fields and disposition kinds it pins" \
  || no "this suite ran only $PASS assertions against $FLOOR pinned schema elements"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
