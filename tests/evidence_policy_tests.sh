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
LADDER="none observe advise rank gate execute"
NCELL=0
for _c in $CLASSES; do for _e in $EVIDENCE; do NCELL=$((NCELL+1)); done; done
NEV=0
for _e in $EVIDENCE; do NEV=$((NEV+1)); done

in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }
rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; execute) echo 5 ;; *) echo -1 ;; esac; }

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

echo "== 2. THREE AXES, REPORTED SEPARATELY — there is no composite evidence score =="
# The anti-pattern this refuses: one blended number whose weights are
# unjustifiable and which hides which axis is saturated.
#
# THE COUNT MOVED FROM 2 TO 3 DELIBERATELY, and the guard is not weakened by the
# move: what it enforces is that every axis is declared BY NAME on its own line
# and that none is blended into another. `deployment` is now one of them, sourced
# from build-os/tools/authority-envelope.sh. The set below is spelled out so that
# an axis quietly appearing or disappearing is still a failure.
run matrix >/dev/null
awk '$1=="axis:"{print $2}' "$WORK/out.txt" | sort > "$WORK/axes.txt"
NAX="$(grep -c . "$WORK/axes.txt" || true)"; NAX="${NAX:-0}"
[ "$NAX" = "3" ] && ok "the tool declares exactly 3 axes, one line each" \
                 || { no "the tool declares $NAX axis line(s), expected 3"; dump; }
grep -qxF class "$WORK/axes.txt"    && ok "the class axis is declared by name"    || no "no class axis is declared"
grep -qxF evidence "$WORK/axes.txt" && ok "the evidence axis is declared by name" || no "no evidence axis is declared"
grep -qxF deployment "$WORK/axes.txt" && ok "the deployment axis is declared by name" || no "no deployment axis is declared"
grep -qE '(score|index|blend|composite|weight)[a-z_]*[[:space:]]*[=:][[:space:]]*[0-9.]' "$WORK/out.txt" \
  && { no "the model assigns a NUMBER to a blended quantity — the composite anti-pattern this design refuses"; dump; } \
  || ok "no line of the model assigns a number to a blended, weighted or composite quantity"
grep -qi 'never blended\|no composite' "$WORK/out.txt" \
  && ok "the model states outright that the two axes are never blended into one score" \
  || { no "the model does not disclaim a composite score anywhere the operator reads it"; dump; }

echo "== 3. COMPOSITION IS THE MINIMUM, and it says so =="
grep -qiE 'composition:.*(MIN|minimum)' "$WORK/out.txt" \
  && ok "the composition rule is stated explicitly: licensed = MIN over the axes" \
  || { no "the tool does not state how the axes compose"; dump; }
CTERM=0
for _t in L_class L_evidence L_deployment; do
  grep -qE "^composition:.*$_t" "$WORK/out.txt" || { CTERM=$((CTERM+1)); echo "      | composition rule never names $_t"; }
done
[ "$CTERM" -eq 0 ] \
  && ok "and it names all three terms — MIN(L_class, L_evidence, L_deployment)" \
  || no "$CTERM term(s) missing from the stated composition rule"
grep -qE '^deployment-default: ' "$WORK/out.txt" \
  && ok "the default deployment mode is declared where the operator reads the model" \
  || { no "the tool never states the default for a control with no envelope"; dump; }
grep -qF 'authority-envelope.sh' "$WORK/out.txt" \
  && ok "and it names where the third term comes from, rather than parsing that schema a second time" \
  || { no "the model does not say where L_deployment is sourced from"; dump; }
grep -qiE 'composite-status:.*(MIN|minimum)' "$WORK/out.txt" \
  && ok "the comma-composite \`empirical_status\` resolution rule is stated (minimum over components)" \
  || { no "nothing states how a comma-composite empirical_status resolves"; dump; }
grep -qE '^ladder: ' "$WORK/out.txt" \
  && ok "the authority ladder the minimum is taken over is printed, not assumed" \
  || { no "the tool never prints the authority ladder"; dump; }
LAD="$(awk '$1=="ladder:"{$1=""; print}' "$WORK/out.txt" | tr -d ' ')"
[ "$LAD" = "$(printf '%s' "$LADDER" | tr -d ' ' | sed 's/none/none/')" ] \
  && ok "the printed ladder is the registry's own: $LADDER" \
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

echo "== 5a. THE EVIDENCE AXIS'S CAPS ARE A COPY OF README §3a, not a second table =="
# WHY THIS EXISTS, AND WHY IT WAS MISSING. §4 reconciles the CLASS axis against
# README §3, and §5 reconciles the evidence axis's LEVELS against the ontology and
# the live census. Until this block nothing reconciled the evidence axis's CAPS:
# README §3a's cap column was an unchecked duplicate of the tool's EVIDENCE_AXIS,
# so the README could say `unvalidated -> gate` while the tool capped it at
# `advise` and every assertion in this suite would still pass. That is the same
# drift surface — a number restated in a second place that nothing compares — that
# put a stale out-of-licence count in three files at once. So the cap table is
# read back OUT OF THE README and diffed against the axis the tool prints, which
# catches a change on either side.
#
# `NF==5` restricts this to THREE-column tables — `| a | b | c |` — so the
# composed class x evidence grid in the same section, which is six columns wide,
# cannot be mistaken for a second cap table. Requiring the cap to be a rung of the
# ladder drops the header and separator rows; a cap edited to something that is
# not a rung drops its row instead, which the row count below then catches.
#
# THE RANGE ENDS AT §3b, NOT AT §4, AND THAT IS A TIGHTENING RATHER THAN A
# LOOSENING. §3b carries the DEPLOYMENT axis's cap table, which is also a
# three-column table of `token | rung | why`. Read as part of §3a it would add
# four rows to the evidence axis and the comparison would fail for the wrong
# reason — a section boundary, not a drift. Each extractor now reads exactly its
# own section, and §5b below reconciles the deployment table the same way, so
# nothing has stopped being checked.
sed -n '/^### 3a\./,/^### 3b\./p' "$RREADME" \
  | awk -F'|' -v lad=" $LADDER " 'NF==5 { e=$2; a=$3;
      gsub(/[`*[:space:]]/,"",e); gsub(/[`*[:space:]]/,"",a);
      if (e != "" && index(lad," " a " ") > 0) print e"="a }' \
  | sort -u > "$WORK/readme_ev.txt"
NRE="$(grep -c . "$WORK/readme_ev.txt" || true)"; NRE="${NRE:-0}"
[ "$NRE" = "$NEV" ] \
  && ok "README §3a's evidence table yields all $NEV cap rows (this comparison is not vacuous)" \
  || { no "README §3a parsed to $NRE cap row(s), not $NEV — the evidence axis's caps cannot be reconciled"; sed 's/^/      | /' "$WORK/readme_ev.txt"; }
awk '$1=="axis:" && $2=="evidence"{for(i=3;i<=NF;i++) if($i ~ /:/){split($i,p,":"); print p[1]"="p[2]}}' \
  "$WORK/out.txt" | sort -u > "$WORK/tool_ev_caps.txt"
NTE="$(grep -c . "$WORK/tool_ev_caps.txt" || true)"; NTE="${NTE:-0}"
[ "$NTE" = "$NEV" ] \
  && ok "the tool printed all $NEV evidence caps to compare against (this comparison is not vacuous)" \
  || { no "the tool printed $NTE evidence cap(s), not $NEV"; dump; }
if diff -q "$WORK/readme_ev.txt" "$WORK/tool_ev_caps.txt" >/dev/null 2>&1; then
  ok "the tool's evidence axis equals README §3a's cap table exactly, row for row"
else
  no "the tool's evidence axis and README §3a's cap table disagree"
  diff "$WORK/readme_ev.txt" "$WORK/tool_ev_caps.txt" | sed 's/^/      | /' | head -8
fi

echo "== 5b. THE DEPLOYMENT AXIS IS A COPY OF README §3b, not a rewrite of it =="
# The third axis gets the same treatment as the first two, for the same reason:
# a cap restated in a second place that nothing compares is the drift surface
# that put a stale out-of-licence count in three files at once. `shadow` could be
# quietly raised to `rank` in one of the two and every other assertion here would
# still pass — including, pointedly, the one that checks reading 2 of the S1
# collision has not been silently adopted.
sed -n '/^### 3b\./,/^## 4/p' "$RREADME" \
  | awk -F'|' -v lad=" $LADDER " 'NF==5 { d=$2; a=$3;
      gsub(/[`*[:space:]]/,"",d); gsub(/[`*[:space:]]/,"",a);
      if (d != "" && index(lad," " a " ") > 0) print d"="a }' \
  | sort -u > "$WORK/readme_dep.txt"
awk '$1=="axis:" && $2=="deployment"{for(i=3;i<=NF;i++) if($i ~ /:/){split($i,p,":"); print p[1]"="p[2]}}' \
  "$WORK/out.txt" | sort -u > "$WORK/tool_dep.txt"
NRD="$(grep -c . "$WORK/readme_dep.txt" || true)"; NRD="${NRD:-0}"
NTD="$(grep -c . "$WORK/tool_dep.txt" || true)"; NTD="${NTD:-0}"
[ "${NRD}" = "${NTD}" ] && [ "${NRD}" != "0" ] \
  && ok "README §3b's deployment table yields $NRD cap row(s), the same number the tool prints (this comparison is not vacuous)" \
  || { no "README §3b parsed to $NRD cap row(s) against the tool's $NTD"; sed 's/^/      | /' "$WORK/readme_dep.txt"; }
if diff -q "$WORK/readme_dep.txt" "$WORK/tool_dep.txt" >/dev/null 2>&1; then
  ok "the tool's deployment axis equals README §3b's cap table exactly, row for row"
else
  no "the tool's deployment axis and README §3b's cap table disagree"
  diff "$WORK/readme_dep.txt" "$WORK/tool_dep.txt" | sed 's/^/      | /' | head -8
fi

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

echo "== 18. THE THIRD MIN TERM CHANGES NOTHING ON THE LIVE CENSUS =="
# THE PACKET'S CENTRAL REGRESSION. Every control in the census predates the
# deployment axis and declares no deployment mode. Adding a third MIN term MUST
# NOT move a single finding — anything else is the system demoting controls with
# no operator in the loop, which is the exact act the envelope exists to make
# impossible without a human.
#
# HOW THIS IS ASSERTED, AND WHY NOT AS A STORED GOLDEN FILE. A frozen copy of
# yesterday's output would decay the moment a control is added — and THIS PACKET
# ADDS THREE, so a pinned `19 of 78` would be stale before it was committed. The
# standing direction is stable ids and derived tables over remembered counts, so
# the comparison is a DIFFERENTIAL run instead: the same tool, the same registry,
# with the third term sourced from an EMPTY store and from the LIVE store. The
# live store has zero grants, so the two runs must agree exactly — and the
# per-axis totals are additionally reconciled against the census's own count of
# `authority_mismatch: declared`, which is a cross-artefact fact rather than a
# number anybody typed.
printf '# a store with no grants at all\n' > "$WORK/nogrants.txt"
run check --repo "$SRC" --envelopes "$WORK/nogrants.txt" >/dev/null
grep '^evidence: ' "$WORK/out.txt" > "$WORK/live_empty.txt"
LSUM_A="$(grep '^evidence-policy: [0-9]* of ' "$WORK/out.txt")"
run check --repo "$SRC" >/dev/null
grep '^evidence: ' "$WORK/out.txt" > "$WORK/live_real.txt"
LSUM_B="$(grep '^evidence-policy: [0-9]* of ' "$WORK/out.txt")"
NFIND="$(grep -c 'OUT-OF-LICENCE' "$WORK/live_real.txt" || true)"; NFIND="${NFIND:-0}"
[ "${NFIND}" != "0" ] \
  && ok "the live census produces $NFIND finding(s), so the identity below compares something" \
  || no "the live census produced no findings — the invariance check would hold vacuously"
if diff -q "$WORK/live_empty.txt" "$WORK/live_real.txt" >/dev/null 2>&1; then
  ok "every finding line is BYTE-IDENTICAL with the live envelope store and with an empty one — the third term is inert on this census"
else
  no "the live envelope store changes the finding set: a grant has been created, and this packet must create none"
  diff "$WORK/live_empty.txt" "$WORK/live_real.txt" | head -6 | sed 's/^/      | /'
fi
[ "$LSUM_A" = "$LSUM_B" ] \
  && ok "and the per-axis totals are identical too: $LSUM_B" \
  || no "the summary totals moved: [$LSUM_A] vs [$LSUM_B]"
# THE SPLIT, RECONCILED RATHER THAN REMEMBERED. The findings the class axis
# already saw are exactly the entries carrying `authority_mismatch: declared` —
# scan-controls.sh §5 enforces that equivalence from the other side — so the
# split is checked against the census instead of against a typed constant.
SNOUT="$(printf '%s' "$LSUM_B"  | awk '{print $2}')"
SNTOT="$(printf '%s' "$LSUM_B"  | awk '{print $4}')"
SNCLS="$(printf '%s' "$LSUM_B"  | sed 's/.*class axis binds \([0-9]*\).*/\1/')"
SNEVI="$(printf '%s' "$LSUM_B"  | sed 's/.*evidence axis binds \([0-9]*\).*/\1/')"
SNBOTH="$(printf '%s' "$LSUM_B" | sed 's/.*both axes bind \([0-9]*\).*/\1/')"
NDECL="$(grep -c '^authority_mismatch: declared$' "$REG" || true)"; NDECL="${NDECL:-0}"
NSTANZA="$(grep -c '^control: ' "$REG" || true)"; NSTANZA="${NSTANZA:-0}"
[ "$SNTOT" = "$NSTANZA" ] \
  && ok "the denominator is the census itself ($NSTANZA stanzas), not a number anybody typed" \
  || no "the tool read $SNTOT controls but the registry declares $NSTANZA stanzas"
[ "$((SNCLS + SNBOTH))" = "$NDECL" ] \
  && ok "the findings the CLASS axis binds ($SNCLS + $SNBOTH) equal the census's $NDECL \`authority_mismatch: declared\` entries — the new axes reproduce the old finding rather than replacing it" \
  || no "class-axis findings ($((SNCLS + SNBOTH))) do not equal the $NDECL declared mismatches"
[ "$((SNCLS + SNEVI + SNBOTH))" = "$SNOUT" ] \
  && ok "and the three attributions partition the $SNOUT findings exactly — none is unattributed, none is double-counted" \
  || no "the per-axis totals do not sum to the out-of-licence total"
DEPBIND="$(grep -c 'axis=[a-z+]*deployment' "$WORK/live_real.txt" || true)"
[ "${DEPBIND:-0}" = "0" ] \
  && ok "NO live finding is bound by the deployment axis, because no live control has an envelope — which is what \"re-authorises nothing\" means arithmetically" \
  || no "${DEPBIND} live finding(s) are bound by the deployment axis: a grant exists that this packet must not have created"

echo "== 18a. ...AND THE AXIS IS NOT INERT — a fixture under \`shadow\` is capped, driven red =="
# The other half. An axis that could never bind would be decoration, and a
# regression test that only proved "nothing changed" would pass just as well
# against a term that was never wired in.
mkreg "$WORK/dep_reg.txt" <<EOF
d.shadowed|A|red_driven|gate
d.control|A|red_driven|gate
EOF
{
  printf 'envelope: e.shadow\n'
  printf 'issuer: the fixture\nactor: the fixture\ncontrol: d.shadowed\n'
  printf 'scope: this fixture\ngranted_authority: gate\nevidence_basis: a fixture\n'
  printf 'deployment_mode: shadow\nstarts: 2026-01-01\nexpires: 2026-12-31\n'
  printf 'revocation: delete it\nreason: to drive the third term red\n'
  printf 'human_confirmation: none\nrollback_behavior: none\n\n'
} > "$WORK/dep_env.txt"
RC="$(run check --registry "$WORK/dep_reg.txt" --envelopes "$WORK/dep_env.txt")"
[ "$(verdict d.shadowed)" = "OUT-OF-LICENCE" ] \
  && ok "RED: a class-A red_driven control gating under \`shadow\` is named OUT-OF-LICENCE — class and evidence both license \`gate\`, and the DEPLOYMENT term does not" \
  || { no "RED FAILED: the shadow-capped control was not flagged"; dump; }
[ "$(field d.shadowed axis)" = "deployment" ] \
  && ok "RED: and the finding names \`deployment\` as the binding axis" \
  || { no "RED FAILED: binding axis was '$(field d.shadowed axis)'"; dump; }
[ "$(field d.shadowed licensed)" = "observe" ] \
  && ok "RED: the composed minimum drops to \`observe\` — the third term really is a MIN term" \
  || { no "RED FAILED: licensed was '$(field d.shadowed licensed)', expected observe"; dump; }
[ "$(verdict d.control)" != "OUT-OF-LICENCE" ] \
  && ok "and the control WITHOUT an envelope in the same run is untouched — the cap follows the grant, not the run" \
  || { no "a control with no envelope was capped: the default is not \`autonomous\`"; dump; }
[ "$RC" = "0" ] \
  && ok "the matrix still ADVISES with a third axis in play: it exits 0" \
  || { no "the matrix exited $RC once the deployment axis bound something"; dump; }

echo "== 18b. AN UNREADABLE ENVELOPE STORE REFUSES — it never defaults to permissive =="
# The third term is a MIN term, so an unknown value for it must not be silently
# read as "no cap". That is the same rule the evidence axis already enforces for
# an unrecognised `empirical_status`, one axis along.
RC="$(run check --registry "$WORK/dep_reg.txt" --envelopes "$WORK/nosuchstore.txt")"
[ "$RC" = "2" ] \
  && ok "an ABSENT envelope store is REFUSED (exit 2) — absent is not empty, and an unknown MIN term must never be defaulted to permissive" \
  || { no "an absent envelope store exited $RC"; dump; }
{
  printf 'envelope: e.badmode\n'
  printf 'issuer: x\nactor: x\ncontrol: d.shadowed\nscope: x\n'
  printf 'granted_authority: gate\nevidence_basis: x\ndeployment_mode: vibes\n'
  printf 'starts: 2026-01-01\nexpires: 2026-12-31\n'
  printf 'revocation: x\nreason: x\nhuman_confirmation: x\nrollback_behavior: x\n\n'
} > "$WORK/badmode.txt"
RC="$(run check --registry "$WORK/dep_reg.txt" --envelopes "$WORK/badmode.txt")"
[ "$RC" = "2" ] \
  && ok "an UNKNOWN deployment mode is REFUSED (exit 2) rather than treated as licensing everything" \
  || { no "an unknown deployment mode exited $RC — the permissive fall-through this design refuses"; dump; }
out | grep -qi 'envelope' \
  && ok "and the refusal says the envelope store is what it could not trust" \
  || { no "the refusal does not name the envelope store"; dump; }

# Field value for a control id, or empty. Defined HERE rather than beside the
# other helpers on purpose: every `file:line` the registry cites into this suite
# resolves at or below §15, and inserting a helper up there would silently
# repoint all of them.
fval(){ # <registry> <control-id> <field>
  awk -v id="$2" -v f="$3" '
    $0 ~ "^control: " { cur = substr($0, 10) }
    cur == id && index($0, f ": ") == 1 { print substr($0, length(f) + 3); exit }
  ' "$1"
}

echo "== 20. THE TWO REFUTED CONTROLS — the cap is a FINDING, not an instruction =="
# §7 above proves the sharp rule: `refuted` caps at `observe` at any class. This
# section is about what happens when someone ACTS on that cap for the two
# controls that carry it, and the answer measured for both is: not what the cap
# suggests. The cap correctly says "this is out of licence". It does not say
# "demote it", and for these two the demotion has been checked and refused.
[ "$(fval "$REG" maint.tripwire_coverage_scan empirical_status)" = "red_driven,refuted" ] \
  && ok "maint.tripwire_coverage_scan still declares its refutation (red_driven,refuted)" \
  || no "maint.tripwire_coverage_scan's empirical_status has moved — a refutation cleared by relabelling is the one move the registry forbids"
[ "$(fval "$REG" maint.source_scan_mask empirical_status)" = "refuted" ] \
  && ok "maint.source_scan_mask still declares its refutation (refuted)" \
  || no "maint.source_scan_mask's empirical_status has moved — the mask's three measured defeats are not retractable"

echo "== 20a. BEING CONSUMED AT \`observe\` IS NOW LEGAL — the contradiction moved to CONSEQUENCE =="
# WHAT THIS SECTION USED TO SAY, AND WHY IT WAS WRONG. It asserted that `observe`
# was NOT REACHABLE for a load_bearing control with a consumer, on the ground
# that README §2 defined `observe` as "it measures and records. NOTHING READS THE
# RESULT" while `load_bearing` means a live policy consumes it. That reading made
# the evidence axis's own `refuted -> observe` cap unreachable for 67 of 81
# controls, with 0 sitting on the rung — a remedy that could be prescribed and
# never applied.
#
# UNDER THE CORRECTED LADDER THE PREMISE IS GONE. `observe` means the output may
# be recorded and CONSUMED FOR VISIBILITY while causing NO OPERATIONAL
# CONSEQUENCE, so "consumed" and "observe" are perfectly consistent. A NARROWER
# tension survives and it is about consequence, not consumption: `load_bearing`
# asserts that REMOVING IT CHANGES OUTCOMES, which IS an operational consequence.
# So the check still has a subject — it just no longer has the subject it claimed.
#
# AND IT NO LONGER GATES. The axis that prescribes the demotion is ADVISORY: it
# exits 0 and states in its own output that re-authorising belongs to the
# operator. A gate that forbids the operator from applying the demotion the
# advisory system recommends is incoherent, so this is REPORTED and not REFUSED.
# The assertions below therefore pin FACTS ABOUT THE LIVE CENSUS and the
# REPORTING, and deliberately do not forbid the operator a move.
SM_AUT="$(fval "$REG" maint.source_scan_mask runtime_authority)"
SM_IMP="$(fval "$REG" maint.source_scan_mask implementation_status)"
SM_CONS="$(fval "$REG" maint.source_scan_mask consuming_policies)"
[ "$SM_IMP" = "load_bearing" ] && [ -n "$SM_CONS" ] \
  && ok "maint.source_scan_mask is load_bearing and names its consumers (this check is not vacuous)" \
  || no "maint.source_scan_mask no longer claims load_bearing with named consumers"
# THIS PACKET RE-AUTHORISED NOBODY, so the control is where the operator left it.
# Stated as an observation of the census — not as a prohibition, which is exactly
# the thing this section stopped doing.
[ "$SM_AUT" = "advise" ] \
  && ok "...and this packet did not move it: it is still at \`advise\`, and the finding still stands" \
  || no "maint.source_scan_mask's runtime_authority is now '$SM_AUT'; redefining a rung must not move a control"
# The live census, reported rather than refused.
OBSN=0; OBSLB=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  [ "$(fval "$REG" "$id" runtime_authority)" = "observe" ] || continue
  OBSN=$((OBSN+1))
  c="$(fval "$REG" "$id" consuming_policies)"
  [ "$(fval "$REG" "$id" implementation_status)" = "load_bearing" ] && [ -n "$c" ] && [ "$c" != "NONE" ] \
    && { OBSLB=$((OBSLB+1)); echo "      | reported: $id is load_bearing at observe, consumed by: $c"; }
done < <(sed -n 's/^control: //p' "$REG")
ok "the census reports $OBSN entr(ies) at \`observe\`, of which $OBSLB are load_bearing — reported, not refused"

echo "== 20b. RED DRIVE — the scanner REPORTS load_bearing at \`observe\`, and does NOT refuse =="
# The live check above passes on a census where nothing sits at `observe`, so on
# its own it proves nothing. This drives the scanner with a fixture that DOES.
#
# TWO THINGS ARE PROVEN AT ONCE, AND BOTH MATTER. The check must still FIRE — a
# guard relocated to an advisory channel and then silently never reached is a
# deleted guard with better paperwork — and it must NOT set the exit code, which
# is the operator's actual complaint: the evidence axis recommends the demotion
# and this scanner forbade it. So the assertions below demand exit 0 AND the
# finding by name, and neither alone would do.
RD="$WORK/obsfix"
mkobsfix(){ # <authority-for-the-sensor>
  rm -rf "$RD"; mkdir -p "$RD/build-os/metrics"
  # a real refusal-capable surface, so the scanner is not blinded and refuses for
  # that reason instead of the one under test
  printf '#!/usr/bin/env bash\nrefuse(){ echo "$*" >&2; exit 2; }\n[ -f x ] || refuse "no x"\n' \
    > "$RD/build-os/metrics/guard.sh"
  # the control actually under test: a sensor that reports and never refuses
  printf '#!/usr/bin/env bash\n# a sensor: it reports, it never refuses\necho "sensor: ok"\n' \
    > "$RD/build-os/metrics/sensor.sh"
  {
    printf 'control: fixture.guard\nclass: A\nimplementation_status: load_bearing\n'
    printf 'empirical_status: red_driven\nruntime_authority: gate\nnervous_system_role: reflex\n'
    printf 'inputs: the presence of x\noutput: a refusal\n'
    printf 'owning_module: build-os/metrics/guard.sh\n'
    printf 'consuming_policies: the guard'"'"'s own exit code\n'
    printf 'evidence_refs: build-os/metrics/guard.sh:3\n'
    printf 'failure_behavior: exits 2\nrollback_behavior: none\n'
    printf 'promotion_requirement: n/a\ndemotion_requirement: n/a\n'
    printf 'authority_mismatch: none\nnotes: fixture\n\n'
    printf 'control: fixture.sensor\nclass: C\nimplementation_status: load_bearing\n'
    printf 'empirical_status: refuted\nruntime_authority: %s\nnervous_system_role: sensor\n' "$1"
    printf 'inputs: source text\noutput: a list of specifiers\n'
    printf 'owning_module: build-os/metrics/sensor.sh\n'
    printf 'consuming_policies: fixture.guard, which reads its output\n'
    printf 'evidence_refs: build-os/metrics/sensor.sh:3\n'
    printf 'failure_behavior: none of its own\n'
    printf 'rollback_behavior: pure\npromotion_requirement: it must not be promoted\n'
    printf 'demotion_requirement: n/a\nauthority_mismatch: none\nnotes: fixture\n\n'
  } > "$RD/registry.txt"
  {
    printf '# fixture mismatch report\n\n<!-- MISMATCH-TABLE:START -->\n\n'
    printf '| control | class | exercises | licensed | the line that gates |\n|---|---|---|---|---|\n'
    printf '\n<!-- MISMATCH-TABLE:END -->\n'
  } > "$RD/MISM.md"
}
# the CLEAN arm first, so the red arm cannot pass for the wrong reason
mkobsfix advise
bash "$SCAN" check --repo "$RD" --registry "$RD/registry.txt" --mismatches "$RD/MISM.md" > "$WORK/obs.txt" 2>&1
RC=$?
[ "$RC" = "0" ] \
  && ok "a load_bearing sensor at \`advise\` with a named consumer is ACCEPTED (exit $RC)" \
  || { no "the clean arm already fails (exit $RC); the red drive below would pass for the wrong reason"; sed 's/^/      | /' "$WORK/obs.txt" | head -8; }
mkobsfix observe
bash "$SCAN" check --repo "$RD" --registry "$RD/registry.txt" --mismatches "$RD/MISM.md" > "$WORK/obs.txt" 2>&1
RC=$?
{ [ "$RC" = "0" ] && grep -q 'OBSERVE-LB' "$WORK/obs.txt" && grep -qi 'fixture.sensor' "$WORK/obs.txt"; } \
  && ok "the same entry demoted to \`observe\` is REPORTED by name as OBSERVE-LB, and the scan still exits 0" \
  || { no "expected an OBSERVE-LB report at exit 0, got exit $RC"; sed 's/^/      | /' "$WORK/obs.txt" | head -8; }
# THE OPERATOR'S RULING, MADE MECHANICAL. This is the assertion that would have
# caught the original defect: a demotion the advisory axis prescribes must not be
# blocked by this scanner's exit code.
[ "$RC" != "2" ] \
  && ok "...so applying the evidence axis's own prescribed demotion is NOT refused by the gating path" \
  || no "the scanner still refuses at exit 2 the demotion the advisory evidence axis recommends"
grep -qi 'no operational consequence' "$WORK/obs.txt" \
  && ok "...and the report states the surviving tension in terms of CONSEQUENCE, not consumption" \
  || { no "the report does not state the consequence-based tension"; sed 's/^/      | /' "$WORK/obs.txt" | head -8; }
grep -qi 'nothing reads the result' "$WORK/obs.txt" \
  && { no "the report still hard-codes the RETIRED non-consumption definition of \`observe\`"; sed 's/^/      | /' "$WORK/obs.txt" | head -8; } \
  || ok "...and it no longer hard-codes \"nothing reads the result\", which was the definition that made the cap unreachable"
# NON-VACUITY OF THE ADVISORY CHANNEL ITSELF: the count must be reported, and it
# must actually be non-zero here. A channel that reports "0 advisory findings"
# while a finding is on screen is worse than no channel.
grep -qE 'scan-controls: [1-9][0-9]* advisory finding' "$WORK/obs.txt" \
  && ok "...and the scan reports a NON-ZERO advisory count, so the channel is not silently inert" \
  || { no "the advisory count is absent or zero while an OBSERVE-LB finding was printed"; sed 's/^/      | /' "$WORK/obs.txt" | head -8; }
# AND THE GATING PATH STILL GATES. Relocating one check must not have converted
# the scanner into an advisory tool. A real violation must still exit 2.
mkobsfix advise
printf 'control: fixture.bogus\nclass: Z\nimplementation_status: load_bearing\n' >> "$RD/registry.txt"
bash "$SCAN" check --repo "$RD" --registry "$RD/registry.txt" --mismatches "$RD/MISM.md" > "$WORK/obs2.txt" 2>&1
[ "$?" = "2" ] \
  && ok "a genuine violation still REFUSES at exit 2 — only OBSERVE-LB moved, the scanner still gates" \
  || { no "the scanner no longer refuses a genuine violation; the relocation went too far"; sed 's/^/      | /' "$WORK/obs2.txt" | head -8; }

echo "== 20c. A demotion MEASURED to cost safety must say so where it is read =="
# `demotion_requirement` is the field an operator reads when lowering authority.
# For maint.tripwire_coverage_scan that decision has been measured and it went
# AGAINST the obvious reading of the cap: demoting the throw to a print converts
# the maintenance layer's only PREVENTION into detection after the fact. Both
# arms exit 1 — only the tree tells them apart — so a reviewer watching exit
# codes sees no difference at all. That is exactly why it has to be written here.
#
# TWO-SIDED, both sides floored: the registry field must cite the measurement by
# a stable marker, and the marker must name arms that actually run.
MARKER="COVERAGE-GATE-PREVENTION-DIFFERENTIAL"
CS_DEM="$(fval "$REG" maint.tripwire_coverage_scan demotion_requirement)"
printf '%s' "$CS_DEM" | grep -qF "$MARKER" \
  && ok "maint.tripwire_coverage_scan's demotion_requirement cites the measurement ($MARKER)" \
  || no "the demotion_requirement instructs a demotion without naming what the demotion was measured to cost"
MSUITE="$SRC/tests/build_os_maintenance_tests.sh"
grep -qF "${MARKER}-ARM-GATED" "$MSUITE" \
  && ok "...and the GATED arm of that differential exists and runs" \
  || no "no ${MARKER}-ARM-GATED arm exists — the registry's citation is decoration"
grep -qF "${MARKER}-ARM-DEMOTED" "$MSUITE" \
  && ok "...and the DEMOTED arm exists, so a differential is actually being taken" \
  || no "no ${MARKER}-ARM-DEMOTED arm exists — one arm is not a differential"
grep -q 'PREVENTION' "$MSUITE" \
  && ok "...and the measurement separates prevention from detection by name" \
  || no "the measurement never mentions prevention, so it does not measure the property cited"
[ "$(fval "$REG" maint.tripwire_coverage_scan runtime_authority)" = "gate" ] \
  && ok "maint.tripwire_coverage_scan is still at \`gate\` — which is what the differential licenses, not the cap" \
  || no "maint.tripwire_coverage_scan has been demoted; the differential says that costs prevention, so re-measure before accepting it"
[ "$(fval "$REG" maint.tripwire_coverage_scan authority_mismatch)" = "declared" ] \
  && ok "...and its mismatch is still DECLARED — keeping the gate did not clear the finding" \
  || no "maint.tripwire_coverage_scan's mismatch was cleared; keeping a gate is not the same as being in licence"

echo "== 21. THE CORRECTED LADDER — \`observe\` by CONSEQUENCE, and a sixth rung =="
# THE DEFECT THIS SECTION EXISTS TO KEEP FIXED. `gravito_mismatch_refuted_a`
# measured that `refuted -> observe` was an UNREACHABLE remedy: `OBSERVE-LB`
# foreclosed `observe` for 67 of 81 controls and 0 sat there. The cause was
# definitional, not incidental — README §2 defined `none` as "nothing consumes
# it" AND `observe` as "it measures and records. Nothing reads the result", so
# BOTH bottom rungs were defined by NON-CONSUMPTION and the ladder had no rung
# meaning "it is read, but it may cause nothing". That is precisely the state a
# refuted-but-wired-in control must occupy.
#
# The operator's correction, which this section pins:
#   `observe`  output may be recorded and CONSUMED FOR VISIBILITY; it causes
#              NO OPERATIONAL CONSEQUENCE.               (defined by CONSEQUENCE)
#   `execute`  output may DIRECTLY CAUSE MUTATION.        (a sixth rung, above `gate`)
#
# THE SIX SITES ARE THE POINT. Consumption semantics were asserted in SIX
# places, and the previous packet's own receipt records that a remedy touching
# only the README is not a remedy — the foreclosure was enforced by CODE.
SITE_README="$RREADME"
SITE_ENVSTORE="$SRC/build-os/registry/authority_envelopes.txt"
SITE_ENVTOOL="$SRC/build-os/tools/authority-envelope.sh"
SITE_EPOL="$TOOL"
# THE PACKET NAMED SIX SITES. THIS SWEEP COVERS SEVEN. `control_registry.txt`
# was found during the build to carry the retired rule in TWO live fields of
# `maint.source_scan_mask` — a `demotion_requirement` instructing the reader that
# "demotion becomes available only when nothing consumes it", and a `notes` field
# restating the same. Those are the fields an operator reads WHILE DECIDING, so
# leaving them behind would have left the correction true everywhere except the
# place it gets acted on. It is swept here for exactly that reason.
SEMANTIC_SITES="$SITE_README $SITE_ENVSTORE $SITE_ENVTOOL $SITE_EPOL $SCAN $SRC/build-os/registry/MISMATCHES.md $REG"
NSITE=0; for _s in $SEMANTIC_SITES; do NSITE=$((NSITE+1)); done
MISSING=0
for _s in $SEMANTIC_SITES; do [ -f "$_s" ] || { MISSING=$((MISSING+1)); echo "      | absent: $_s"; }; done
# NON-VACUITY IS PINNED BY NAME, NOT BY A COUNT. An earlier draft floored this
# with a numeric minimum on the site count, which is STRICTLY WEAKER — six of the
# WRONG files would have satisfied it — and which tests/control_registry_tests.sh
# §21 correctly caught as a new unregistered member of the fitted-floor family.
# Naming the sites is the better check AND introduces no fitted constant, so
# there is nothing to register and nothing to excuse.
#
# NOTE FOR WHOEVER EDITS THIS COMMENT: that family scan greps tests/*.sh for the
# floor operators as raw text, so it matches COMMENTS as well as code. Spelling
# the rejected operator out in prose here made this file a member of the family
# it was only describing. Say it in words, not in symbols.
SITEBAD=0
for _want in README.md authority_envelopes.txt authority-envelope.sh evidence-policy.sh scan-controls.sh MISMATCHES.md control_registry.txt; do
  case " $(for _s in $SEMANTIC_SITES; do basename "$_s"; done | tr '\n' ' ') " in
    *" $_want "*) ;;
    *) SITEBAD=$((SITEBAD+1)); echo "      | the sweep does not cover $_want" ;;
  esac
done
{ [ "$MISSING" -eq 0 ] && [ "$SITEBAD" -eq 0 ]; } \
  && ok "the sweep covers all $NSITE named semantic sites and every one exists (not vacuous)" \
  || no "$MISSING absent and $SITEBAD uncovered — the sweep below would pass by reading the wrong files or none"

# (a) THE RETIRED CLAUSE IS GONE, SWEPT BY CONTENT AND NOT BY FILENAME. The
# previous packet's brief warns that prose citations escape in two forms — bare
# `:NNN` refs and MISMATCHES.md §10's row form naming a file with NO line number
# at all — so a filename-qualified grep misses both. This greps CONTENT.
#
# THE RULE IS ABSOLUTE AND THAT IS DELIBERATE: the retired string may not appear
# at these sites AT ALL, not even inside a quotation explaining the history. A
# sweep that allowed "we used to say X" would have to tell a quotation from a
# definition, which no grep can do, and the exemption would be the whole hole.
# The history is therefore recorded by DESCRIBING the old clause ("defined by
# non-consumption") rather than by reproducing it. Three of this packet's own
# edits tripped this rule and were rewritten rather than exempted.
RETIRED=0
for _s in $SEMANTIC_SITES; do
  if grep -qi 'nothing reads the result' "$_s"; then
    RETIRED=$((RETIRED+1)); echo "      | $(basename "$_s") still defines \`observe\` by non-consumption"
  fi
done
[ "$RETIRED" -eq 0 ] \
  && ok "no live semantic site still defines \`observe\` as \"nothing reads the result\"" \
  || no "$RETIRED site(s) still carry the retired non-consumption definition of \`observe\`"

# (a2) THE RETIRED RULE HAS TWO WORDINGS, AND BLOCK (a) SWEPT ONLY ONE. This
# block exists because THIS PACKET REPRODUCED ITS OWN HEADLINE DEFECT INSIDE ITS
# OWN NEW GUARD. The finding that opened the packet was that `VACUOUS-REF` checks
# RESOLVABILITY and not IDENTITY — a guard that confirms a citation lands
# somewhere while never confirming it lands on the right thing. Block (a) above
# is the same shape one level up: it confirms the retired rule is gone in the
# README's wording ("nothing reads the result") while never confirming it is gone
# in the DEPLOYMENT AXIS's wording ("nothing consumes it"). Two sites shipped
# past it carrying the second wording — `authority-envelope.sh`'s `shadow` row
# and `control_registry.txt`'s `envelope.grant_composition` notes — in the two
# files that OWN the deployment axis. A sweep that covers one of a rule's two
# spellings is not a sweep; it is a filter that happens to name the rule.
#
# WHY THIS IS SCOPED TO THE ARROW LINES AND NOT SWEPT ABSOLUTELY. "Nothing
# consumes it" cannot be banned outright the way "nothing reads the result" was:
# it is also the correct wording of the MOTIVATION for the whole third axis —
# "a control whose ranking nothing consumes and a control whose ranking silently
# reorders the work queue are indistinguishable on both existing axes" — which is
# a true sentence about two controls, not a definition of a rung. That sentence
# appears legitimately at README.md, authority_envelopes.txt and
# authority-envelope.sh. So the discriminator here is POSITION, not
# vocabulary: a consumption clause is a DEFINITION when it sits on the line that
# maps something ONTO the `observe` rung, and is prose everywhere else. This
# greps the mapping lines — `-> observe` — and refuses a consumption clause on
# any of them.
#
# THE LIMIT OF LINE-SCOPING, STATED RATHER THAN DISCOVERED LATER. A registry
# record is ONE LINE, so in `control_registry.txt` this block cannot separate the
# mapping from the motivation — the whole `notes` field is the same line, and the
# motivation sentence there had to be rewritten ("reaches no consumer") to say the
# same thing in the corrected vocabulary. That is a REWRITE and not an exemption,
# which is the same treatment block (a) forced on three sites. The check is
# therefore STRICTER inside a registry record than inside a comment block, and
# the direction of that error is the safe one: it over-reports on the file where
# an operator makes the decision.
#
# AND THE ASYMMETRY WITH BLOCK (a) IS DELIBERATE, NOT AN OVERSIGHT. Block (a)
# bans its wording ABSOLUTELY, even in a quotation; this block bans its wording
# only ON A MAPPING LINE. The two rules differ because the two strings do: only
# one of them has a legitimate non-definitional use. The visible consequence is
# that `authority_envelopes.txt` may — and does — say "it used to read
# <the retired clause>" as history, one line below its own corrected `shadow`
# row, while no site may quote the README's wording at all. That is stated here
# so the next reader finds a recorded judgement rather than an apparent hole.
#
# WHAT THIS BLOCK STILL DOES NOT SWEEP, RECORDED SO IT IS NOT REDISCOVERED AS A
# SURPRISE: the FIVE-RUNG SPELLING of the ladder. Sites 3, 4 and 7 of this fix
# round drifted that way, not this way — a ladder enumerated as ending at `gate`.
# That is a DIFFERENT guard over a DIFFERENT site set: the drift landed in
# `tests/*.sh` `ok` messages and in a README-declaration probe, none of which are
# among the seven SEMANTIC sites above, and the check it needs is an
# enumeration-continuation test (does the enumeration continue past `gate`?)
# rather than a same-line-clause test. It is deliberately NOT bolted on here, and
# is recorded as its own packet in `MISMATCHES.md` §16.
#
# AND A SECOND GAP, FOUND BY THE RE-REVIEW AND RECORDED RATHER THAN PATCHED: this
# block matches an ARROW (`-> observe`), and the mapping has TWO SYNTAXES. README
# — the FIRST of the seven SEMANTIC_SITES — writes it as a MARKDOWN TABLE ROW:
# `| shadow | observe | ... |`. Arrow-form matches in README total ZERO, so this
# block is STRUCTURALLY VACUOUS over the site it lists first. Measured: rewriting
# that row to carry a consumption clause escapes block (a) (wrong literal), this
# block (no arrow), and block (b) (which still finds the surviving correct
# definition elsewhere in the file). The block's stated discriminator is right —
# a consumption clause is a DEFINITION when it sits on the line that maps
# something onto `observe` — and a table row IS such a line. The rule is sound;
# the implementation covers one of the mapping's two syntaxes. That is the same
# criticism this block levels at its own predecessor, one syntax along, and it is
# named here so it is not rediscovered as a surprise.
CONSUMEDEF=0
for _s in $SEMANTIC_SITES; do
  while IFS= read -r _ln; do
    [ -n "$_ln" ] || continue
    printf '%s' "$_ln" | grep -qiE 'nothing[[:space:]]+(consumes|reads)|(consumes|reads)[[:space:]]+nothing' \
      && { CONSUMEDEF=$((CONSUMEDEF+1))
           echo "      | $(basename "$_s"):${_ln%%:*} maps onto \`observe\` with a CONSUMPTION clause"; }
  done < <(grep -nE -- '->[[:space:]]*observe' "$_s" 2>/dev/null)
done
[ "$CONSUMEDEF" -eq 0 ] \
  && ok "no line mapping anything ONTO \`observe\` defines the rung by consumption — the retired rule's SECOND wording is swept too" \
  || no "$CONSUMEDEF \`-> observe\` mapping line(s) still define the rung by non-consumption"

# (b) AND THE REPLACEMENT IS PRESENT AT EVERY ONE OF THEM. Deleting the old
# clause without stating the new one would leave the rung undefined, which is a
# different defect with the same symptom.
AGREE=0
for _s in $SEMANTIC_SITES; do
  grep -qi 'no operational consequence' "$_s" && AGREE=$((AGREE+1)) \
    || echo "      | $(basename "$_s") never states that \`observe\` causes no operational consequence"
done
[ "$AGREE" -eq "$NSITE" ] \
  && ok "all $NSITE sites define \`observe\` by CONSEQUENCE — \"no operational consequence\"" \
  || no "only $AGREE of $NSITE sites carry the consequence definition"

# (c) THE SIXTH RUNG EXISTS, IS ON TOP, AND BOTH TOOLS PRINT THE SAME LADDER.
run matrix >/dev/null   # cell() reads this buffer, and the ladder is printed here
EP_LAD="$(awk '$1=="ladder:"{$1=""; print}' "$WORK/out.txt" | xargs)"
AE_LAD="$(bash "$SITE_ENVTOOL" schema 2>/dev/null | awk '$1=="ladder:"{$1=""; print}' | xargs)"
[ -n "$EP_LAD" ] && [ "$EP_LAD" = "$AE_LAD" ] \
  && ok "both tools print the SAME ladder: $EP_LAD" \
  || no "the two tools print different ladders ('$EP_LAD' vs '$AE_LAD')"
NRUNG=0; for _r in $EP_LAD; do NRUNG=$((NRUNG+1)); done
[ "$NRUNG" -eq 6 ] \
  && ok "the ladder has SIX rungs, not five" \
  || no "the ladder has $NRUNG rung(s); the corrected ladder has six"
[ "${EP_LAD##* }" = "execute" ] \
  && ok "\`execute\` is the TOP rung — strictly above \`gate\`" \
  || no "the top rung is '${EP_LAD##* }', not \`execute\`"
[ "$(rank_of execute)" -gt "$(rank_of gate)" ] \
  && ok "...and this suite's own independent rank_of agrees that execute > gate" \
  || no "this suite's rank_of does not place execute above gate"
sed -n '/^### RuntimeAuthority/,/^### nervous_system_role/p' "$SITE_README" \
  | grep -qE '^\| `execute` \|' \
  && ok "README §2's RuntimeAuthority table carries an \`execute\` row" \
  || no "README §2 never defines \`execute\`, so the rung exists only in code"
sed -n '/^### RuntimeAuthority/,/^### nervous_system_role/p' "$SITE_README" \
  | grep -qiE 'execute.*(mutat|changes the world)' \
  && ok "...and defines it by DIRECT MUTATION, which is what distinguishes it from \`gate\`" \
  || no "README's \`execute\` row does not say it directly causes mutation"

run matrix >/dev/null   # restore the buffer cell() reads, after the README greps
# (d) THE CAP DID NOT MOVE. Redefining a rung must not re-authorise anybody:
# `refuted` still caps at `observe`. What changed is what `observe` MEANS, which
# turns the cap from an unreachable instruction into a legal destination.
[ "$(cell C refuted)" = "observe" ] && [ "$(cell A refuted)" = "observe" ] \
  && ok "\`refuted\` still caps at \`observe\` at every class — the cap VALUE is unmoved" \
  || no "the refuted cap moved while the rung was being redefined; that is a re-authorisation"

# (e) NOTHING DERIVES ITS BOUND FROM "THE TOP RUNG". The class table is settled
# and must be untouched by the arrival of a rung above `gate` — if any class
# licence were written as "the top of the ladder" it would have silently risen
# to `execute` and re-authorised the whole Class-A population in one commit.
[ "$(cell A calibrated)" = "gate" ] \
  && ok "Class A still licenses \`gate\` and NOT \`execute\` — no class bound tracked the top rung" \
  || no "Class A now licenses '$(cell A calibrated)'; adding a rung re-authorised a whole class"
GRIDEX=0
for _c in $CLASSES; do for _e in $EVIDENCE; do
  [ "$(cell "$_c" "$_e")" = "execute" ] && GRIDEX=$((GRIDEX+1))
done; done
[ "$GRIDEX" -eq 0 ] \
  && ok "NO cell of the $NCELL-cell class/evidence grid licenses \`execute\` — whether one should is the operator's, and is recorded, not answered here" \
  || no "$GRIDEX grid cell(s) license \`execute\`; this packet was licensed to add a rung, not to grant it"

# (f) THE TOP RUNG MUST NOT BE UNREACHABLE ON THE DEPLOYMENT AXIS — which is the
# ONLY axis whose default applies to all 81 controls that predate it. The
# artefact's own stated defence of `autonomous` is "no additional cap ... the top
# of the ladder and therefore no cap at all". That defence is a claim about
# POSITION, not about the token `gate`. If the top moves and `autonomous` stays
# put, a documented NON-cap silently becomes a real cap on the whole census —
# and `execute` becomes foreclosed for everyone, which is the very
# unreachable-rung pathology this section exists to fix, reproduced one axis
# along.
DEPTOP="$(bash "$SITE_ENVTOOL" schema 2>/dev/null \
  | awk '$1=="axis:" && $2=="deployment"{for(i=3;i<=NF;i++) if($i ~ /^autonomous:/){split($i,p,":"); print p[2]}}')"
[ "$DEPTOP" = "${EP_LAD##* }" ] \
  && ok "the DEFAULT deployment mode \`autonomous\` caps at the TOP rung (\`$DEPTOP\`) — it still adds no cap" \
  || no "\`autonomous\` caps at '${DEPTOP:-<none>}' while the ladder tops out at '${EP_LAD##* }' — the default now silently demotes the whole census"

# (g) AND THE CENSUS IS UNMOVED. The whole point: a definition changed, and not
# one finding did.
LIVE_N="$(bash "$SITE_EPOL" check 2>/dev/null | sed -n 's/^evidence-policy: \([0-9]*\) of [0-9]* out of licence.*/\1/p')"
[ "${LIVE_N:-x}" = "19" ] \
  && ok "the live census still reports 19 findings — redefining a rung re-authorised nobody" \
  || no "the live census reports ${LIVE_N:-<none>} findings, not 19; a semantic edit moved the finding set"

echo "== 19. This suite is chained, and is not vacuous about itself =="
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
