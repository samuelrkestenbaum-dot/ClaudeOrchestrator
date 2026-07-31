#!/usr/bin/env bash
# Build OS — evidence-policy matrix tests.
#
# WHAT THIS PINS. build-os/registry/README.md §3 carries a licence table that is
# ONE-DIMENSIONAL: class -> licensed authority. Evidence is not an axis in it, so
# a control's `empirical_status` — whether anybody ever established that the
# check works — licenses nothing and forbids nothing. Under that table a control
# that was MEASURED AND FOUND NOT TO DISCRIMINATE can stop a build and the
# registry's own rules have no objection. build-os/tools/evidence-policy.sh adds
# the second axis and derives, FROM THE REGISTRY, what the two axes together put
# out of licence. The claims that must stay checkable:
#
#   1. TWO AXES, REPORTED SEPARATELY. There is no composite evidence score. A
#      blended `q = w1*class + w2*evidence` would need weights nobody can derive
#      and would hide WHICH axis is saturated — the same anti-pattern
#      bandwidth-check.sh refuses one layer along. So every finding NAMES the
#      axis that binds it, and no line of output ever assigns a number to a
#      blended quantity.
#   2. THE CLASS AXIS IS A COPY, NOT A REWRITE. The class column is settled and
#      lives in README §3. It is read back OUT OF THE README here and compared
#      against what the tool declares, so the new axis cannot quietly restate
#      the old one differently.
#   3. THE EVIDENCE AXIS INVENTS NO LEVEL. Its levels must be exactly the
#      `empirical_status` values the ontology declares AND exactly the tokens
#      that actually occur in the live registry. A matrix with a level nothing
#      uses is a matrix fitted to a hypothetical census.
#   4. `refuted` MAY NOT GATE, AT ANY CLASS. This is the one rule that resolves
#      a real defect mechanically rather than by judgement, so it is driven over
#      ALL FIVE classes rather than asserted once. Class cannot rescue it: class
#      is a claim about the KIND of thing being checked, evidence is a claim
#      about whether the check WORKS.
#   5. A COMPOSITE `empirical_status` RESOLVES BY MINIMUM, so `refuted`
#      dominates. `red_driven,refuted` must license exactly what bare `refuted`
#      licenses — a later refutation supersedes an earlier red drive, and the
#      minimum rule encodes that without needing a timestamp the registry does
#      not carry.
#   6. `unvalidated` CAPS BELOW `gate`. The expensive rule. It is asserted as an
#      inequality against the ladder, not as a hard-coded level, so tightening
#      or loosening it stays visible as a deliberate edit rather than a silent
#      one.
#   7. IT ADVISES. IT DOES NOT GATE. `check` must exit 0 on a registry that
#      violates the matrix — including THE LIVE ONE, which does. A matrix that
#      gated on the rule "chosen thresholds may not gate" would be self-refuting
#      in exactly the way `bandwidth.active_packet_singleton` was, and gating
#      would demote controls automatically with no operator in the loop.
#   8. THE ONE THING IT DOES REFUSE is a derivation it cannot trust: an absent
#      registry, a registry that parses to zero controls, or a stanza it cannot
#      classify. A matrix that silently skips what it could not read reports a
#      clean licence for a census it did not read — the blinded-scanner failure
#      scan-controls.sh refuses in three places.
#   9. IT DERIVES; IT DOES NOT REMEMBER. The out-of-licence set is computed from
#      the registry on every run. A hand-maintained list decays exactly the way
#      `PACKET_FILES` and MISMATCHES.md §10's file/lines table did.
#  10. IT RE-AUTHORISES NOTHING. The tool writes nothing, anywhere; the registry
#      is byte-identical after a run.
#
# No network. Deterministic. Every fixture lives under $WORK; nothing outside it
# is written. Exits non-zero if any assertion fails.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$SRC/build-os/tools/evidence-policy.sh"
REG="$SRC/build-os/registry/control_registry.txt"
RREADME="$SRC/build-os/registry/README.md"
SCAN="$SRC/build-os/registry/scan-controls.sh"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The two axes' domains, duplicated here ON PURPOSE. A suite that reads its
# expected set out of the tool it is checking cannot detect the tool quietly
# dropping a level or inventing one. Both sets are ALSO reconciled below against
# the README (class) and against the live registry (evidence), so this
# duplication is a third opinion and not the only one.
CLASSES="A B C D R"
EVIDENCE="unvalidated red_driven field_observed calibrated refuted"
LADDER="none observe advise rank gate"
NCELL=0
for _c in $CLASSES; do for _e in $EVIDENCE; do NCELL=$((NCELL+1)); done; done

in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }
rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; *) echo -1 ;; esac; }

run(){ "$TOOL" "$@" > "$WORK/out.txt" 2> "$WORK/err.txt"; echo "$?"; }
out(){ cat "$WORK/out.txt" "$WORK/err.txt"; }
dump(){ sed 's/^/      | /' "$WORK/out.txt" "$WORK/err.txt" | head -14; }

# The licensed authority the tool reports for one (class, evidence) cell.
cell(){ awk -v c="$1" -v e="$2" '
  $1=="grid:" { split($0,f," "); cl=""; ev=""; li="";
    for(i=1;i<=NF;i++){
      if($i ~ /^class=/){cl=substr($i,7)}
      if($i ~ /^evidence=/){ev=substr($i,10)}
      if($i ~ /^licensed=/){li=substr($i,10)} }
    if(cl==c && ev==e){print li; exit} }' "$WORK/out.txt"; }

# mkreg <file> — a well-formed registry built from `id|class|empirical|authority`
# tuples on stdin. Every field the scanner's format demands is emitted, so a
# fixture is a real registry and not a shape only this tool would accept.
mkreg(){
  local f="$1" line id cls emp aut
  : > "$f"
  printf '# synthetic registry fixture\n\n' >> "$f"
  while IFS='|' read -r id cls emp aut; do
    [ -n "$id" ] || continue
    {
      printf 'control: %s\n' "$id"
      printf 'class: %s\n' "$cls"
      printf 'implementation_status: load_bearing\n'
      printf 'empirical_status: %s\n' "$emp"
      printf 'runtime_authority: %s\n' "$aut"
      printf 'nervous_system_role: reflex\n'
      printf 'inputs: a fixture\n'
      printf 'output: a fixture verdict\n'
      printf 'owning_module: fixture.sh\n'
      printf 'consuming_policies: the fixture\n'
      printf 'evidence_refs: fixture.sh:1\n'
      printf 'failure_behavior: exits 2\n'
      printf 'rollback_behavior: none\n'
      printf 'promotion_requirement: n/a\n'
      printf 'demotion_requirement: n/a\n'
      printf 'authority_mismatch: none\n'
      printf 'notes: fixture\n'
      printf '\n'
    } >> "$f"
  done
}

# The verdict word this run gave one control, or the empty string.
verdict(){ awk -v i="$1" '$1=="evidence:" && $3==i {print $2; exit}' "$WORK/out.txt"; }
# One named field off that control's report line.
field(){ awk -v i="$1" -v k="$2" '$1=="evidence:" && $3==i {
  for(j=1;j<=NF;j++) if(index($j,k"=")==1){print substr($j,length(k)+2); exit} }' "$WORK/out.txt"; }

echo "== 1. The tool exists, is executable, and describes its own model =="
[ -f "$TOOL" ] && ok "build-os/tools/evidence-policy.sh exists" || no "the evidence-policy tool is missing"
[ -x "$TOOL" ] && ok "the tool is executable" || no "the tool is not executable"
head -1 "$TOOL" | grep -qE '^#!' && ok "the tool carries a shebang" || no "the tool has no shebang"
RC="$(run matrix)"
[ "$RC" = "0" ] && ok "\`matrix\` prints the two-axis licence and exits 0" \
                || { no "\`matrix\` exited $RC"; dump; }

echo "== 2. TWO AXES, REPORTED SEPARATELY — there is no composite evidence score =="
# The anti-pattern this refuses: one blended number whose weights are
# unjustifiable and which hides which axis is saturated.
run matrix >/dev/null
awk '$1=="axis:"{print $2}' "$WORK/out.txt" | sort > "$WORK/axes.txt"
NAX="$(grep -c . "$WORK/axes.txt" || true)"; NAX="${NAX:-0}"
[ "$NAX" = "2" ] && ok "the tool declares exactly 2 axes, one line each" \
                 || { no "the tool declares $NAX axis line(s), expected 2"; dump; }
grep -qxF class "$WORK/axes.txt"    && ok "the class axis is declared by name"    || no "no class axis is declared"
grep -qxF evidence "$WORK/axes.txt" && ok "the evidence axis is declared by name" || no "no evidence axis is declared"
grep -qE '(score|index|blend|composite|weight)[a-z_]*[[:space:]]*[=:][[:space:]]*[0-9.]' "$WORK/out.txt" \
  && { no "the model assigns a NUMBER to a blended quantity — the composite anti-pattern this design refuses"; dump; } \
  || ok "no line of the model assigns a number to a blended, weighted or composite quantity"
grep -qi 'never blended\|no composite' "$WORK/out.txt" \
  && ok "the model states outright that the two axes are never blended into one score" \
  || { no "the model does not disclaim a composite score anywhere the operator reads it"; dump; }

echo "== 3. COMPOSITION IS THE MINIMUM, and it says so =="
grep -qiE 'composition:.*(MIN|minimum)' "$WORK/out.txt" \
  && ok "the composition rule is stated explicitly: licensed = MIN over the two axes" \
  || { no "the tool does not state how the two axes compose"; dump; }
grep -qiE 'composite-status:.*(MIN|minimum)' "$WORK/out.txt" \
  && ok "the comma-composite \`empirical_status\` resolution rule is stated (minimum over components)" \
  || { no "nothing states how a comma-composite empirical_status resolves"; dump; }
grep -qE '^ladder: ' "$WORK/out.txt" \
  && ok "the authority ladder the minimum is taken over is printed, not assumed" \
  || { no "the tool never prints the authority ladder"; dump; }
LAD="$(awk '$1=="ladder:"{$1=""; print}' "$WORK/out.txt" | tr -d ' ')"
[ "$LAD" = "$(printf '%s' "$LADDER" | tr -d ' ' | sed 's/none/none/')" ] \
  && ok "the printed ladder is the registry's own: none observe advise rank gate" \
  || no "the printed ladder '$LAD' is not the registry's authority ladder"

echo "== 4. THE CLASS AXIS IS A COPY OF README §3, not a rewrite of it =="
# README §3's table is settled. Read it back out of the README and compare it
# against the axis the tool declares, so the second axis cannot quietly restate
# the first one differently and call the difference policy.
# `NF==4` restricts this to TWO-column tables — `| a | b |` — so the composed
# class x evidence grid in §3a, which is six columns wide and whose first column
# is also a bare class letter, cannot be mistaken for a second licence table.
sed -n '/^## 3\./,/^## 4/p' "$RREADME" \
  | awk -F'|' 'NF==4 { c=$2; a=$3; gsub(/[`*]/,"",c); gsub(/[`* \t]/,"",a);
      sub(/^[ \t]+/,"",c); split(c,w,/[ \t]+/); k=w[1];
      if (k ~ /^[ABCDR]$/ && a != "") print k"="a }' \
  | sort -u > "$WORK/readme_class.txt"
NRC="$(grep -c . "$WORK/readme_class.txt" || true)"; NRC="${NRC:-0}"
[ "$NRC" = "5" ] \
  && ok "README §3's licence table yields all 5 class rows (this comparison is not vacuous)" \
  || { no "README §3 parsed to $NRC class row(s), not 5 — the class axis cannot be reconciled"; sed 's/^/      | /' "$WORK/readme_class.txt"; }
awk '$1=="axis:" && $2=="class"{for(i=3;i<=NF;i++) if($i ~ /^[ABCDR]:/){split($i,p,":"); print p[1]"="p[2]}}' \
  "$WORK/out.txt" | sort -u > "$WORK/tool_class.txt"
if diff -q "$WORK/readme_class.txt" "$WORK/tool_class.txt" >/dev/null 2>&1; then
  ok "the tool's class axis equals README §3's licence table exactly, row for row"
else
  no "the tool's class axis and README §3 disagree"
  diff "$WORK/readme_class.txt" "$WORK/tool_class.txt" | sed 's/^/      | /' | head -8
fi

echo "== 5. THE EVIDENCE AXIS INVENTS NO LEVEL =="
# Two independent reconciliations: the ontology the scanner enforces, and the
# tokens the live census actually carries. A level in neither is a level fitted
# to a hypothetical registry.
awk '$1=="axis:" && $2=="evidence"{for(i=3;i<=NF;i++) if($i ~ /:/){split($i,p,":"); print p[1]}}' \
  "$WORK/out.txt" | sort -u > "$WORK/tool_ev.txt"
grep -oE '^EMP_STATUSES="[^"]*"' "$SCAN" | sed 's/^EMP_STATUSES="//; s/"$//' | tr ' ' '\n' \
  | grep -v '^$' | sort -u > "$WORK/onto_ev.txt"
NOE="$(grep -c . "$WORK/onto_ev.txt" || true)"; NOE="${NOE:-0}"
[ "$NOE" -gt 0 ] \
  && ok "the ontology's empirical_status set was read back from scan-controls.sh ($NOE value(s))" \
  || no "no EMP_STATUSES set could be read from scan-controls.sh — the comparison below is vacuous"
if diff -q "$WORK/onto_ev.txt" "$WORK/tool_ev.txt" >/dev/null 2>&1; then
  ok "the evidence axis's levels are exactly the ontology's empirical_status values — none invented, none dropped"
else
  no "the evidence axis and the ontology's empirical_status set disagree"
  diff "$WORK/onto_ev.txt" "$WORK/tool_ev.txt" | sed 's/^/      | /' | head -8
fi
awk -F': ' '/^empirical_status: /{n=split($2,t,","); for(i=1;i<=n;i++){gsub(/ /,"",t[i]); print t[i]}}' "$REG" \
  | sort -u > "$WORK/live_ev.txt"
NLE="$(grep -c . "$WORK/live_ev.txt" || true)"; NLE="${NLE:-0}"
[ "$NLE" -gt 0 ] \
  && ok "the live registry carries $NLE distinct empirical_status token(s) to reconcile against" \
  || no "no empirical_status tokens parsed from the live registry"
UNCOVERED=""
while IFS= read -r t; do
  [ -n "$t" ] || continue
  grep -qxF "$t" "$WORK/tool_ev.txt" || UNCOVERED="$UNCOVERED $t"
done < "$WORK/live_ev.txt"
[ -z "$UNCOVERED" ] \
  && ok "every empirical_status token occurring in the live registry has a cap on the evidence axis" \
  || no "evidence token(s) occurring live and licensed by nothing:$UNCOVERED"

echo "== 6. Every cell of the class x evidence grid is stated, once =="
run matrix >/dev/null
awk '$1=="grid:"' "$WORK/out.txt" | wc -l | tr -d ' ' > "$WORK/ngrid.txt"
NGRID="$(cat "$WORK/ngrid.txt")"
[ "$NGRID" = "$NCELL" ] \
  && ok "the grid states all $NCELL class x evidence cells" \
  || { no "the grid states $NGRID cell(s), expected $NCELL"; dump; }
GBAD=0
for c in $CLASSES; do
  for e in $EVIDENCE; do
    v="$(cell "$c" "$e")"
    in_list "$v" "$LADDER" || { GBAD=$((GBAD+1)); echo "      | class=$c evidence=$e licensed='$v' is not on the ladder"; }
  done
done
[ "$GBAD" -eq 0 ] && ok "every grid cell licenses an authority that is on the ladder" \
                  || no "$GBAD grid cell(s) license something that is not an authority"

echo "== 7. THE SHARP RULE — a \`refuted\` control may not gate, AT ANY CLASS =="
# The one rule here that resolves a real defect mechanically rather than by
# judgement. Driven over all five classes, because "class cannot rescue it" is
# precisely the claim: class is about the KIND of thing checked, evidence is
# about whether the check WORKS.
run matrix >/dev/null
RBAD=0
for c in $CLASSES; do
  v="$(cell "$c" refuted)"
  [ "$(rank_of "$v")" -lt "$(rank_of gate)" ] || { RBAD=$((RBAD+1)); echo "      | class=$c refuted licenses '$v'"; }
done
[ "$RBAD" -eq 0 ] \
  && ok "no class licenses \`gate\` on \`refuted\` evidence — class A included, which is the whole point" \
  || no "$RBAD class(es) still license a gate on evidence that was measured and found not to discriminate"
# ...and it is capped below `advise` too: presenting a signal known not to
# discriminate to a decision-maker who cannot see that it is dead is worse than
# recording it and letting nothing read it.
v="$(cell A refuted)"
[ "$(rank_of "$v")" -lt "$(rank_of advise)" ] \
  && ok "\`refuted\` caps at '$v' — below \`advise\`, so a dead signal is recorded rather than presented" \
  || no "\`refuted\` licenses '$v', which still lets a signal known not to discriminate reach a decision-maker"

echo "== 8. A COMPOSITE empirical_status RESOLVES BY MINIMUM — \`refuted\` dominates =="
# A later refutation supersedes an earlier red drive. The minimum rule encodes
# that without needing a timestamp the registry does not carry.
mkreg "$WORK/comp.txt" <<EOF
a.bare_refuted|A|refuted|gate
a.red_then_refuted|A|red_driven,refuted|gate
a.refuted_then_red|A|refuted,red_driven|gate
a.bare_red|A|red_driven|gate
EOF
RC="$(run check --registry "$WORK/comp.txt")"
L1="$(field a.bare_refuted licensed)"; L2="$(field a.red_then_refuted licensed)"
L3="$(field a.refuted_then_red licensed)"
{ [ -n "$L1" ] && [ "$L1" = "$L2" ] && [ "$L1" = "$L3" ]; } \
  && ok "\`red_driven,refuted\` and \`refuted,red_driven\` both license exactly what bare \`refuted\` licenses ($L1)" \
  || { no "composite resolution disagrees with bare refuted: bare=$L1 red,ref=$L2 ref,red=$L3"; dump; }
[ "$(verdict a.bare_red)" != "OUT-OF-LICENCE" ] \
  && ok "a class-A \`red_driven\` gate is NOT flagged — the rule bites on refutation, not on every gate" \
  || { no "a class-A red_driven gate was flagged out of licence: the matrix flags everything and discriminates nothing"; dump; }
[ "$(verdict a.red_then_refuted)" = "OUT-OF-LICENCE" ] \
  && ok "the composite \`red_driven,refuted\` gate IS flagged out of licence" \
  || { no "a gate on red_driven,refuted was not flagged"; dump; }

echo "== 9. \`unvalidated\` CAPS BELOW \`gate\` — the expensive rule, asserted as an inequality =="
run matrix >/dev/null   # section 8 left `check` output in the buffer cell() reads
UBAD=0
for c in $CLASSES; do
  v="$(cell "$c" unvalidated)"
  [ "$(rank_of "$v")" -lt "$(rank_of gate)" ] || { UBAD=$((UBAD+1)); echo "      | class=$c unvalidated licenses '$v'"; }
done
[ "$UBAD" -eq 0 ] \
  && ok "no class licenses \`gate\` on \`unvalidated\` evidence — including class A, where the class table alone permits it" \
  || no "$UBAD class(es) license a gate on evidence that establishes nothing"
UA="$(cell A unvalidated)"; UR="$(cell A refuted)"
[ "$(rank_of "$UA")" -gt "$(rank_of "$UR")" ] \
  && ok "\`unvalidated\` ($UA) licenses strictly more than \`refuted\` ($UR) — not knowing is not the same as knowing it fails" \
  || no "\`unvalidated\` and \`refuted\` are not distinguished, so one of the two rules is doing no work"

echo "== 10. THE EVIDENCE AXIS SEES WHAT THE CLASS AXIS STRUCTURALLY CANNOT =="
# A class-A control on unvalidated evidence is LEGAL under the one-dimensional
# table and still means nobody has watched it fire. If the new axis cannot see
# that case, it has bought nothing.
mkreg "$WORK/axis.txt" <<EOF
a.unvalidated_gate|A|unvalidated|gate
c.red_gate|C|red_driven|gate
c.unvalidated_gate|C|unvalidated|gate
a.red_gate|A|red_driven|gate
EOF
RC="$(run check --registry "$WORK/axis.txt")"
[ "$(verdict a.unvalidated_gate)" = "OUT-OF-LICENCE" ] \
  && ok "a class-A gate on unvalidated evidence is flagged — invisible to the class table, which licenses it" \
  || { no "a class-A gate on unvalidated evidence was not flagged: the evidence axis buys nothing"; dump; }
[ "$(field a.unvalidated_gate axis)" = "evidence" ] \
  && ok "and the finding NAMES the evidence axis as the one that binds it" \
  || { no "the class-A/unvalidated finding names axis '$(field a.unvalidated_gate axis)', not evidence"; dump; }
[ "$(field c.red_gate axis)" = "class" ] \
  && ok "a class-C gate on red_driven evidence names the CLASS axis as the one that binds it" \
  || { no "the class-C/red_driven finding names axis '$(field c.red_gate axis)', not class"; dump; }
[ "$(field c.unvalidated_gate axis)" = "both" ] \
  && ok "a class-C gate on unvalidated evidence names BOTH axes — neither is collapsed into the other" \
  || { no "the class-C/unvalidated finding names axis '$(field c.unvalidated_gate axis)', not both"; dump; }
[ "$(verdict a.red_gate)" != "OUT-OF-LICENCE" ] \
  && ok "a class-A gate on red_driven evidence is in licence on both axes and is not flagged" \
  || { no "an aligned control was flagged"; dump; }
# Every flagged control reports BOTH per-axis licences, never one merged number.
AXBAD=0
for i in a.unvalidated_gate c.red_gate c.unvalidated_gate; do
  for k in class-licensed evidence-licensed licensed exercises; do
    v="$(field "$i" "$k")"
    in_list "$v" "$LADDER" || { AXBAD=$((AXBAD+1)); echo "      | $i reports $k='$v'"; }
  done
done
[ "$AXBAD" -eq 0 ] \
  && ok "every finding reports its class licence AND its evidence licence separately, plus the composed minimum" \
  || no "$AXBAD reported per-axis licence value(s) are missing or not on the ladder"

echo "== 11. IT ADVISES — it reports a violating registry and EXITS 0 =="
# The most contestable claim in the census entry, executed rather than asserted.
# A matrix that gated on the rule "chosen thresholds may not gate" would be
# self-refuting, and gating would demote controls automatically with no operator
# in the loop.
mkreg "$WORK/bad.txt" <<EOF
a.refuted_gate|A|refuted|gate
c.unvalidated_gate|C|unvalidated|gate
EOF
RC="$(run check --registry "$WORK/bad.txt")"
[ "$(verdict a.refuted_gate)" = "OUT-OF-LICENCE" ] \
  && ok "RED: a class-A control gating on refuted evidence is named OUT-OF-LICENCE" \
  || { no "RED FAILED: a refuted gate was not named"; dump; }
[ "$RC" = "0" ] \
  && ok "the matrix ADVISES: it names every violation and exits 0, as its class-C licence allows" \
  || { no "the matrix exited $RC — it is gating on a chosen policy without declaring it"; dump; }
out | grep -qiE 'advis' \
  && ok "the report states its own authority (advisory) where the operator reads it" \
  || { no "the report never states that it only advises"; dump; }
out | grep -qiE 'operator|governance' \
  && ok "the report says demotion is a governance action, not something it performs" \
  || { no "the report does not say who may act on it"; dump; }

echo "== 12. IT EXITS 0 ON THE LIVE REGISTRY, WHICH VIOLATES IT =="
# The live census is a real violating registry, so this is the advisory claim
# driven on real data rather than on a fixture built to be convenient.
RC="$(run check --repo "$SRC")"
[ "$RC" = "0" ] \
  && ok "\`check\` on the live registry exits 0" \
  || { no "\`check\` on the live registry exited $RC"; dump; }
NLIVE="$(awk '$1=="evidence:" && $2=="OUT-OF-LICENCE"' "$WORK/out.txt" | wc -l | tr -d ' ')"
[ "${NLIVE:-0}" -gt 0 ] \
  && ok "and it finds $NLIVE control(s) out of licence there — the exit-0 above is not the silence of an empty result" \
  || { no "the live registry produced no findings at all, so the exit-0 proves nothing"; dump; }
NREF="$(awk '$1=="evidence:" && $2=="OUT-OF-LICENCE" && /evidence-licensed=observe/' "$WORK/out.txt" | wc -l | tr -d ' ')"
[ "${NREF:-0}" -gt 0 ] \
  && ok "at least one live finding rests on refuted evidence — the sharp rule bites on the real census" \
  || { no "no live control is capped by refutation, though the registry records refuted controls"; dump; }
grep -qE '^evidence-policy: .*[0-9]+ of [0-9]+ out of licence' "$WORK/out.txt" \
  && ok "the run prints a derived total in the form <n> of <N>, not a remembered one" \
  || { no "no derived total is printed"; dump; }

echo "== 13. IT DERIVES — the finding follows the registry, never a stored list =="
# A hand-maintained list decays exactly the way PACKET_FILES and MISMATCHES.md
# §10's file/lines table did. Change the registry and the finding must change.
mkreg "$WORK/derive_a.txt" <<EOF
x.one|A|refuted|gate
x.two|A|red_driven|gate
EOF
mkreg "$WORK/derive_b.txt" <<EOF
x.one|A|red_driven|gate
x.two|A|refuted|gate
EOF
run check --registry "$WORK/derive_a.txt" >/dev/null
VA1="$(verdict x.one)"; VA2="$(verdict x.two)"
run check --registry "$WORK/derive_b.txt" >/dev/null
VB1="$(verdict x.one)"; VB2="$(verdict x.two)"
{ [ "$VA1" = "OUT-OF-LICENCE" ] && [ "$VB2" = "OUT-OF-LICENCE" ] \
  && [ "$VA2" != "OUT-OF-LICENCE" ] && [ "$VB1" != "OUT-OF-LICENCE" ]; } \
  && ok "swapping the two controls' evidence swaps which one is flagged — the verdict is derived, not stored" \
  || { no "the finding did not follow the registry: a=[$VA1,$VA2] b=[$VB1,$VB2]"; dump; }
grep -rqE '(maint\.tripwire_coverage_scan|tools\.handoff_lock|maint\.source_scan_mask)' "$TOOL" \
  && no "the tool names a live control id in its own source — that is the hand-maintained list this exists to avoid" \
  || ok "the tool hard-codes no control id: the out-of-licence set exists only as a derivation"

echo "== 14. THE ONE THING IT REFUSES is a derivation it cannot trust =="
# A matrix that silently skips what it could not read reports a clean licence for
# a census it did not read — the blinded-scanner failure scan-controls.sh
# refuses in three places.
printf '# a registry with no controls at all\n' > "$WORK/empty.txt"
RC="$(run check --registry "$WORK/empty.txt")"
[ "$RC" = "2" ] \
  && ok "a registry that parses to ZERO controls is REFUSED (exit 2), not reported as zero violations" \
  || { no "an empty registry exited $RC — a blinded matrix certifies a clean licence forever"; dump; }
out | grep -qiE '0 control|no control|empty' \
  && ok "the refusal says WHY: the census it was asked to judge is empty" \
  || { no "the empty-registry refusal states no reason"; dump; }
RC="$(run check --registry "$WORK/nosuchfile.txt")"
[ "$RC" = "2" ] \
  && ok "an absent registry is REFUSED — an absent census is not a clean one" \
  || { no "an absent registry exited $RC"; dump; }
{
  printf 'control: broken.no_evidence\n'
  printf 'class: A\n'
  printf 'runtime_authority: gate\n\n'
} > "$WORK/ragged.txt"
RC="$(run check --registry "$WORK/ragged.txt")"
[ "$RC" = "2" ] \
  && ok "a stanza the matrix cannot classify is REFUSED, not silently skipped" \
  || { no "a stanza with no empirical_status exited $RC — skipping it would report a licence for a control nobody read"; dump; }
out | grep -qF 'broken.no_evidence' \
  && ok "and the refusal NAMES the control it could not classify" \
  || { no "the unreadable-stanza refusal does not name the stanza"; dump; }
{
  printf 'control: broken.bad_token\n'
  printf 'class: A\n'
  printf 'empirical_status: vibes\n'
  printf 'runtime_authority: gate\n\n'
} > "$WORK/badtok.txt"
RC="$(run check --registry "$WORK/badtok.txt")"
[ "$RC" = "2" ] \
  && ok "an empirical_status token the matrix has no cap for is REFUSED, not treated as licensing everything" \
  || { no "an unknown evidence token exited $RC — an unrecognised level must never default to permissive"; dump; }

echo "== 15. IT RE-AUTHORISES NOTHING and writes nothing =="
BEFORE="$(cksum < "$REG")"
run check --repo "$SRC" >/dev/null
AFTER="$(cksum < "$REG")"
[ "$BEFORE" = "$AFTER" ] \
  && ok "the live registry is byte-identical after a run — the matrix names what is out of licence and changes nothing" \
  || no "the registry changed during a run: this tool must never re-authorise a control"
grep -qE '^[[:space:]]*(sed -i|>[[:space:]]*"?\$REGISTRY|tee )' "$TOOL" \
  && no "the tool contains an in-place write to its input" \
  || ok "the tool contains no in-place write to the registry it reads"

echo "== 16. Usage errors refuse rather than guessing =="
RC="$(run)"
[ "$RC" = "2" ] && ok "no command is REFUSED (exit 2), not treated as a silent check" \
                || { no "no command exited $RC"; dump; }
RC="$(run wibble)"
[ "$RC" = "2" ] && ok "an unknown command is REFUSED (exit 2)" || { no "an unknown command exited $RC"; dump; }
RC="$(run check --repo "$WORK/nope")"
[ "$RC" = "2" ] && ok "a --repo that is not a directory is REFUSED" || { no "a bad --repo exited $RC"; dump; }
RC="$(run check --registry)"
[ "$RC" = "2" ] && ok "an option missing its value is REFUSED" || { no "a valueless --registry exited $RC"; dump; }

echo "== 17. The tool and its suite are registered as control surfaces =="
# Both files can terminate a run non-zero, so scan-controls.sh will discover
# them; a surface owning no `gate` entry is an unregistered control.
grep -qF "owning_module: build-os/tools/evidence-policy.sh" "$REG" \
  && ok "the tool owns at least one registry entry" \
  || no "the evidence-policy tool exits non-zero and owns no registry entry"
grep -qF "owning_module: tests/evidence_policy_tests.sh" "$REG" \
  && ok "this suite owns a registry entry" \
  || no "this suite exits non-zero and owns no registry entry"
# Both fields collected, record judged AT ITS END: `runtime_authority` precedes
# `owning_module` in a record, so a one-pass scan that decides at the authority
# line is reading the PREVIOUS record's module.
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
gated_by "build-os/tools/evidence-policy.sh" | grep -q . \
  && ok "the tool owns a \`gate\` entry, as the anti-shelfware scan requires of anything that can stop a run" \
  || no "the tool can exit 2 but no entry records it at authority gate"
MATRIXID="$(advised_by "build-os/tools/evidence-policy.sh" | head -1)"
[ -n "$MATRIXID" ] \
  && ok "the matrix itself is registered at authority \`advise\` ($MATRIXID)" \
  || no "no entry registers the matrix at advise — its authority is undeclared"
awk -v i="$MATRIXID" '/^control: /{c=$2} c==i && /^class: /{print $2; exit}' "$REG" | grep -qx C \
  && ok "$MATRIXID is Class C — a chosen policy, not a definition" \
  || no "$MATRIXID is not registered Class C: a chosen threshold matrix is a heuristic"
awk -v i="$MATRIXID" '/^control: /{c=$2} c==i && /^authority_mismatch: /{print $2; exit}' "$REG" | grep -qx none \
  && ok "$MATRIXID declares NO authority mismatch — Class C at advise is exactly its licence" \
  || no "$MATRIXID declares an authority mismatch, which a Class-C control at advise must not"

echo "== 18. This suite is chained, and is not vacuous about itself =="
grep -qF 'chain_suite "tests/evidence_policy_tests.sh"' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained from tests/build_os_tests.sh (not discoverable-only)" \
  || no "this suite is present but never chained from tests/build_os_tests.sh"
# A DERIVED floor: more assertions than the matrix has cells. It states no
# numeric literal, so it does not join the tests.nonvacuity_minimums family that
# tests/control_registry_tests.sh §21 polices.
[ "$PASS" -gt "$NCELL" ] \
  && ok "this suite ran $PASS assertions, more than the $NCELL cells the matrix declares" \
  || no "this suite ran only $PASS assertions against $NCELL matrix cells"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
