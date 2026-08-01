#!/usr/bin/env bash
# Build OS — authority envelope tests.
#
# WHAT THIS PINS. `MISMATCHES.md` states — fourteen times — that re-authorising a
# control is a governance action belonging to the operator. Until now the
# operator had NO MECHANISM to perform one. There was no artefact in which a
# human could say "this control may exercise this authority, on this basis,
# until this date". `build-os/registry/authority_envelopes.txt` is that artefact
# and `build-os/tools/authority-envelope.sh` is its validator. The claims that
# must stay checkable:
#
#   1. A THIRD AXIS, DECLARED BY NAME. `deployment_mode` separates PERMISSION TO
#      RANK from PERMISSION TO CHOOSE from PERMISSION TO ACT, which neither the
#      class axis nor the evidence axis can express. Composition gains a third
#      MIN term: `L_effective = MIN(L_class, L_evidence, L_deployment)`.
#   2. THE DEFAULT IS `autonomous`, AND IT IS DEFENDED WHERE IT IS DECLARED.
#      Every control registered before this axis existed carries no deployment
#      mode. `autonomous` — i.e. NO ADDITIONAL CAP — is the only default that
#      leaves the existing finding set alone. Any other default silently demotes
#      the whole census, which is precisely the self-re-authorisation the
#      envelope exists to prevent.
#   3. THE STORE SHIPS EMPTY OF LIVE GRANTS. Creating a grant is a governance
#      act, not a build step. The store therefore parses to ZERO records on the
#      day it lands, and the worked example in it is INSIDE COMMENTS so that no
#      tool can count it — an example that a parser sees is a live grant wearing
#      a label.
#   4. ZERO GRANTS IS THE CORRECT STATE, NOT THE SHELFWARE STATE. This is the
#      one place the registry's vacuity rule is deliberately NOT copied: an
#      empty control registry is a census nobody wrote, but an empty envelope
#      store is a system that has re-authorised nothing. So zero records is
#      reported and exits 0; an ABSENT store still refuses.
#   5. IT VALIDATES; IT GRANTS NOTHING. The tool writes nothing, anywhere, and
#      no control's registered authority changes because an envelope exists.
#      Reporting that a grant exceeds what the three axes license is advice.
#   6. THE ONE THING IT REFUSES is a derivation it cannot trust — mirroring
#      `evidence.derivation_nonvacuity`: an absent store, an unparseable store,
#      an unknown `deployment_mode`, or a field the schema has no slot for. AN
#      UNRECOGNISED DEPLOYMENT MODE MUST NEVER FALL THROUGH TO PERMISSIVE. That
#      is the single sharpest property here and it is driven red below.
#   7. THE TENSION IS RECORDED AND NOT RESOLVED. The sanctioned S1 launch
#      declaration is `heuristic_policy` / `untested` / `rank` / `shadow`, and
#      `min()` cannot produce `rank` for it: `heuristic_policy` is Class C,
#      README §3 licenses Class C at `advise`, and `rank` is strictly above
#      `advise`. Two readings exist, they claim different things, and choosing
#      between them is a governance change rather than a build decision. BOTH
#      must appear in the tool's own header; NEITHER may be adopted.
#   8. `untested` IS DECLARED PENDING AND IS NOT IMPLEMENTED. The operator ruled
#      that `untested` (has not yet produced live output) and `unvalidated` (has
#      operated, lacks outcome evidence) are meaningfully different. That is the
#      NEXT packet's decision. Here it is recorded as pending, and it must NOT
#      appear on the evidence axis, must NOT have a cap row, and must still be
#      REFUSED by `evidence.derivation_nonvacuity` — proven, not asserted.
#
# No network. Deterministic. Every fixture lives under $WORK; nothing outside it
# is written. Exits non-zero if any assertion fails.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOL="$SRC/build-os/tools/authority-envelope.sh"
EPOL="$SRC/build-os/tools/evidence-policy.sh"
STORE="$SRC/build-os/registry/authority_envelopes.txt"
REG="$SRC/build-os/registry/control_registry.txt"
RREADME="$SRC/build-os/registry/README.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The deployment axis's domain, duplicated here ON PURPOSE — the same device
# tests/evidence_policy_tests.sh uses for the other two axes. A suite that reads
# its expected set out of the tool it is checking cannot notice the tool quietly
# dropping a mode or inventing one.
MODES="shadow human_confirmed bounded_autonomous autonomous"
LADDER="none observe advise rank gate"
DEFAULT_MODE="autonomous"
# The fourteen fields the operator's ruling names. Duplicated for the same
# reason.
SCHEMA_FIELDS="envelope issuer actor control scope granted_authority evidence_basis deployment_mode starts expires revocation reason human_confirmation rollback_behavior"
NMODE=0; for _m in $MODES; do NMODE=$((NMODE+1)); done
NFIELD=0; for _f in $SCHEMA_FIELDS; do NFIELD=$((NFIELD+1)); done

in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }
rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; *) echo -1 ;; esac; }

run(){ "$TOOL" "$@" > "$WORK/out.txt" 2> "$WORK/err.txt"; echo "$?"; }
out(){ cat "$WORK/out.txt" "$WORK/err.txt"; }
dump(){ sed 's/^/      | /' "$WORK/out.txt" "$WORK/err.txt" | head -14; }

# mkenv <file> — a store built from
# `id|control|granted_authority|deployment_mode` tuples on stdin. Every field
# the schema demands is emitted, so a fixture is a REAL envelope and not a shape
# only this suite would accept.
mkenv(){
  local f="$1" id ctl auth mode
  : > "$f"
  printf '# synthetic envelope fixture\n\n' >> "$f"
  while IFS='|' read -r id ctl auth mode; do
    [ -n "$id" ] || continue
    {
      printf 'envelope: %s\n' "$id"
      printf 'issuer: the operator (fixture)\n'
      printf 'actor: any agent (fixture)\n'
      printf 'control: %s\n' "$ctl"
      printf 'scope: this fixture only\n'
      printf 'granted_authority: %s\n' "$auth"
      printf 'evidence_basis: a fixture, and nothing else\n'
      printf 'deployment_mode: %s\n' "$mode"
      printf 'starts: 2026-01-01\n'
      printf 'expires: 2026-12-31\n'
      printf 'revocation: delete this record\n'
      printf 'reason: to exercise the validator\n'
      printf 'human_confirmation: none — it is a fixture\n'
      printf 'rollback_behavior: the control returns to its registered authority\n'
      printf '\n'
    } >> "$f"
  done
}

# mkreg <file> — a well-formed control registry, same shape as
# tests/evidence_policy_tests.sh's fixture builder, from
# `id|class|empirical|authority` tuples.
mkreg(){
  local f="$1" id cls emp aut
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

# The verdict word this run gave one envelope, or the empty string.
verdict(){ awk -v i="$1" '$1=="envelope:" && $3==i {print $2; exit}' "$WORK/out.txt"; }
# One named field off that envelope's report line.
field(){ awk -v i="$1" -v k="$2" '$1=="envelope:" && $3==i {
  for(j=1;j<=NF;j++) if(index($j,k"=")==1){print substr($j,length(k)+2); exit} }' "$WORK/out.txt"; }
# The cap the tool declares for one deployment mode. Read out of a FROZEN copy of
# the `schema` output rather than out of $WORK/out.txt: later sections overwrite
# out.txt with `check` runs, and a lookup that silently returned the empty string
# there would make every comparison below pass by matching nothing.
depcap(){ awk -v m="$1" '$1=="axis:" && $2=="deployment"{
  for(i=3;i<=NF;i++){ n=index($i,":"); if(n>0 && substr($i,1,n-1)==m){print substr($i,n+1); exit} } }' "$WORK/schema.txt"; }

echo "== 1. The tool exists, is executable, and describes its own model =="
[ -f "$TOOL" ] && ok "build-os/tools/authority-envelope.sh exists" || no "the authority-envelope tool is missing"
[ -x "$TOOL" ] && ok "the tool is executable" || no "the tool is not executable"
head -1 "$TOOL" | grep -qE '^#!' && ok "the tool carries a shebang" || no "the tool has no shebang"
RC="$(run schema)"
[ "$RC" = "0" ] && ok "\`schema\` prints the envelope schema and the deployment axis, and exits 0" \
                || { no "\`schema\` exited $RC"; dump; }

echo "== 2. THE THIRD AXIS, declared by name and with every mode's cap stated =="
run schema >/dev/null
cp "$WORK/out.txt" "$WORK/schema.txt"
# The frozen copy must not be empty, or every depcap lookup below would compare
# the empty string against the empty string and pass.
[ -s "$WORK/schema.txt" ] \
  && ok "the frozen \`schema\` output is non-empty, so the cap lookups below compare something" \
  || no "\`schema\` printed nothing — every axis assertion below would pass vacuously"
grep -qE '^axis: deployment ' "$WORK/out.txt" \
  && ok "the deployment axis is declared by name, on its own line" \
  || { no "no deployment axis is declared"; dump; }
DBAD=0
for m in $MODES; do
  c="$(depcap "$m")"
  if [ -z "$c" ]; then DBAD=$((DBAD+1)); echo "      | mode \"$m\" has no cap on the declared axis"; continue; fi
  in_list "$c" "$LADDER" || { DBAD=$((DBAD+1)); echo "      | mode \"$m\" caps at \"$c\", which is not a rung of the ladder"; }
done
[ "$DBAD" -eq 0 ] \
  && ok "all $NMODE deployment modes carry a cap, and every cap is a rung on the ladder" \
  || no "$DBAD deployment mode(s) are missing or carry a cap off the ladder"
NDECL="$(awk '$1=="axis:" && $2=="deployment"{print NF-2; exit}' "$WORK/out.txt")"
[ "${NDECL:-0}" = "$NMODE" ] \
  && ok "the axis declares exactly the $NMODE modes this suite knows — it invents none and drops none" \
  || { no "the axis declares ${NDECL:-0} mode(s), expected $NMODE"; dump; }
# The ladder is printed rather than assumed, and it is the registry's own.
LAD="$(awk '$1=="ladder:"{$1=""; print}' "$WORK/out.txt" | tr -d ' ')"
[ "$LAD" = "$(printf '%s' "$LADDER" | tr -d ' ')" ] \
  && ok "the printed ladder is the registry's own: none observe advise rank gate" \
  || no "the printed ladder '$LAD' is not the registry's authority ladder"
# The same anti-pattern the evidence matrix refuses, refused one axis along.
grep -qE '(score|index|blend|composite|weight)[a-z_]*[[:space:]]*[=:][[:space:]]*[0-9.]' "$WORK/out.txt" \
  && { no "the model assigns a NUMBER to a blended quantity — the composite anti-pattern this design refuses"; dump; } \
  || ok "no line of the model assigns a number to a blended, weighted or composite quantity"

echo "== 2a. THE AXIS THIS TOOL OWNS IS A COPY OF README §3b, not a rewrite of it =="
# WHY THIS EXISTS, AND WHY IT WAS MISSING. This file is the DECLARED OWNER of the
# deployment axis: `evidence-policy.sh` copies `DEPLOYMENT_AXIS` from here the way
# it copies the class axis from README §3, and README §3b states the same four
# caps in prose for a human. Section 2 above proves the tool declares four modes
# and that each cap is a rung of the ladder — it does NOT prove the caps are the
# ones the README publishes. Until this block, NOTHING pinned the owner: with
# `shadow` changed to `none` HERE and left at `observe` in README §3b, this suite
# and the evidence-policy suite both stayed fully green (86/0 and 88/0, driven and
# observed). Only the evidence matrix's COPY was pinned, by §5b of
# tests/evidence_policy_tests.sh — so the copy was checked and the ORIGINAL was
# not, which is the unchecked-duplicate defect §5a's own comment names, one file
# along. The fix is that same device pointed at the owner, so a cap edited on
# either side is caught on either side.
#
# THE RANGE ENDS AT `## 4`, matching the extractor in evidence_policy_tests.sh
# §5b, so this reads exactly §3b and cannot absorb a neighbouring section's
# table. `NF==5` restricts it to THREE-column tables, and requiring the cap to be
# a rung of the ladder drops the header and separator rows; a cap edited to
# something that is not a rung drops its row instead, which the row count then
# catches.
sed -n '/^### 3b\./,/^## 4/p' "$RREADME" \
  | awk -F'|' -v lad=" $LADDER " 'NF==5 { d=$2; a=$3;
      gsub(/[`*[:space:]]/,"",d); gsub(/[`*[:space:]]/,"",a);
      if (d != "" && index(lad," " a " ") > 0) print d"="a }' \
  | sort -u > "$WORK/readme_dep.txt"
awk '$1=="axis:" && $2=="deployment"{for(i=3;i<=NF;i++) if($i ~ /:/){split($i,p,":"); print p[1]"="p[2]}}' \
  "$WORK/schema.txt" | sort -u > "$WORK/tool_dep.txt"
NRD="$(grep -c . "$WORK/readme_dep.txt" || true)"; NRD="${NRD:-0}"
NTD="$(grep -c . "$WORK/tool_dep.txt" || true)"; NTD="${NTD:-0}"
# Both sides must yield exactly the modes this suite knows independently, so the
# diff below cannot pass by comparing two empty files or two short ones.
[ "$NRD" = "$NMODE" ] \
  && ok "README §3b's deployment table yields all $NMODE cap rows (this comparison is not vacuous)" \
  || { no "README §3b parsed to $NRD cap row(s), not $NMODE — the axis's owner cannot be reconciled"; sed 's/^/      | /' "$WORK/readme_dep.txt"; }
[ "$NTD" = "$NMODE" ] \
  && ok "the tool printed all $NMODE deployment caps to compare against (this comparison is not vacuous)" \
  || { no "the tool printed $NTD deployment cap(s), not $NMODE"; dump; }
if diff -q "$WORK/readme_dep.txt" "$WORK/tool_dep.txt" >/dev/null 2>&1; then
  ok "the tool's deployment axis equals README §3b's cap table exactly, row for row — the axis's OWNER is pinned, not just its copy"
else
  no "the tool's deployment axis and README §3b's cap table disagree — the owner of the axis has drifted from the document that publishes it"
  diff "$WORK/readme_dep.txt" "$WORK/tool_dep.txt" | sed 's/^/      | /' | head -8
fi
# And the owner must agree with the copy that consumes it. evidence-policy.sh
# restates DEPLOYMENT_AXIS; §5b of tests/evidence_policy_tests.sh pins that copy
# to the README and the block above pins this file to the README, so the two are
# already transitively equal — this asserts it directly rather than by argument,
# because a transitive proof breaks silently the moment either extractor changes.
awk '$1=="axis:" && $2=="deployment"{for(i=3;i<=NF;i++) if($i ~ /:/){split($i,p,":"); print p[1]"="p[2]}}' \
  <("$EPOL" matrix 2>/dev/null) | sort -u > "$WORK/epol_dep.txt"
NED="$(grep -c . "$WORK/epol_dep.txt" || true)"; NED="${NED:-0}"
[ "$NED" = "$NMODE" ] \
  && ok "evidence-policy.sh prints all $NMODE deployment caps (its copy is readable, so the comparison below is not vacuous)" \
  || { no "evidence-policy.sh printed $NED deployment cap(s), not $NMODE"; sed 's/^/      | /' "$WORK/epol_dep.txt"; }
if diff -q "$WORK/tool_dep.txt" "$WORK/epol_dep.txt" >/dev/null 2>&1; then
  ok "the consuming copy in evidence-policy.sh equals this tool's axis exactly — owner and copy cannot restate the third axis differently"
else
  no "evidence-policy.sh's copy of the deployment axis differs from the owner's"
  diff "$WORK/tool_dep.txt" "$WORK/epol_dep.txt" | sed 's/^/      | /' | head -8
fi

echo "== 3. THE ORDERING OF THE MODES IS THE POINT: rank < choose < act =="
# The axis is worth having only if the four modes are strictly ordered. If
# `shadow` licensed as much as `autonomous` the axis would express nothing that
# the other two already express.
RS="$(rank_of "$(depcap shadow)")"; RH="$(rank_of "$(depcap human_confirmed)")"
RB="$(rank_of "$(depcap bounded_autonomous)")"; RA="$(rank_of "$(depcap autonomous)")"
{ [ "$RS" -lt "$RH" ] && [ "$RH" -lt "$RB" ] && [ "$RB" -lt "$RA" ]; } \
  && ok "the four modes are STRICTLY increasing on the ladder: shadow < human_confirmed < bounded_autonomous < autonomous" \
  || no "the deployment modes are not strictly ordered ($RS,$RH,$RB,$RA) — an axis whose levels tie expresses nothing"
# `human_confirmed` may not reach `rank`, by the ladder's OWN definition of
# `rank`: the rung that lets a control order work or select between options with
# no human in the loop. A mode whose whole content is "a human confirms" cannot
# license the rung that means "no human confirms".
[ "$RH" -lt "$(rank_of rank)" ] \
  && ok "human_confirmed caps BELOW \`rank\` — \`rank\` is by definition the rung with no human in the loop" \
  || no "human_confirmed licenses \`rank\` or above, which contradicts what \`rank\` means"
# `bounded_autonomous` may not reach `gate`: `gate` is the unbounded stop, and
# "bounded" is exactly the refusal of it.
[ "$RB" -lt "$(rank_of gate)" ] \
  && ok "bounded_autonomous caps BELOW \`gate\` — \`gate\` is the unbounded stop that \"bounded\" refuses" \
  || no "bounded_autonomous licenses \`gate\`, which is not a bounded authority"

echo "== 4. THE DEFAULT IS \`autonomous\`, and the tool says so where it is read =="
# THE SAFETY ARGUMENT, stated in the artefact and checked here. Every control
# registered before this axis existed carries no deployment mode. Only a default
# of `autonomous` — no additional cap — leaves them where the operator put them.
DEF="$(awk '$1=="default:" && $2=="deployment_mode"{print $3; exit}' "$WORK/out.txt")"
[ "$DEF" = "$DEFAULT_MODE" ] \
  && ok "the declared default for a control with no envelope is \`$DEFAULT_MODE\`" \
  || { no "the declared default is \"${DEF:-<none>}\", not \`$DEFAULT_MODE\` — any other default silently demotes the whole census"; dump; }
[ "$(rank_of "$(depcap "$DEFAULT_MODE")")" = "$(rank_of gate)" ] \
  && ok "and the default mode caps at \`gate\` — i.e. it adds NO cap, which is what \"changes nothing\" means arithmetically" \
  || no "the default mode caps below \`gate\`, so it demotes every control that never asked for a deployment mode"
grep -qiE 'default:.*(demot|re-?authoris|changes nothing|no additional cap)' "$WORK/out.txt" \
  && ok "the default line carries its DEFENCE, not just its value" \
  || { no "the default is stated without the reason it must be this one"; dump; }

echo "== 5. COMPOSITION IS A THREE-TERM MINIMUM, and it says so =="
grep -qiE 'composition:.*(MIN|minimum)' "$WORK/out.txt" \
  && ok "the composition rule is stated explicitly as a minimum" \
  || { no "the tool does not state how the axes compose"; dump; }
CBAD=0
for t in L_class L_evidence L_deployment; do
  grep -qE "^composition:.*$t" "$WORK/out.txt" || { CBAD=$((CBAD+1)); echo "      | composition rule never names $t"; }
done
[ "$CBAD" -eq 0 ] \
  && ok "the rule names all three terms — L_effective = MIN(L_class, L_evidence, L_deployment)" \
  || no "$CBAD term(s) missing from the stated composition rule"

echo "== 6. THE SCHEMA is declared field by field, and the store documents it =="
SBAD=0
for f in $SCHEMA_FIELDS; do
  grep -qE "^field: $f( |\$)" "$WORK/out.txt" || { SBAD=$((SBAD+1)); echo "      | schema never declares field \"$f\""; }
done
[ "$SBAD" -eq 0 ] \
  && ok "all $NFIELD fields of the operator's ruling are declared by the tool" \
  || no "$SBAD schema field(s) the ruling names are not declared"
NDF="$(grep -cE '^field: ' "$WORK/out.txt" || true)"
[ "${NDF:-0}" = "$NFIELD" ] \
  && ok "the tool declares exactly $NFIELD fields — it invents none beyond the ruling" \
  || no "the tool declares ${NDF:-0} fields, expected $NFIELD"

echo "== 7. THE STORE EXISTS, and it ships EMPTY OF LIVE GRANTS =="
[ -f "$STORE" ] && ok "build-os/registry/authority_envelopes.txt exists" \
                || no "the envelope store is missing — the operator still has no artefact to grant in"
RC="$(run check --repo "$SRC")"
[ "$RC" = "0" ] && ok "\`check\` on the live store exits 0" || { no "\`check\` on the live store exited $RC"; dump; }
NLIVE="$(awk '$1=="authority-envelope:" && $3=="live" && $4=="grant(s)"{print $2; exit}' "$WORK/out.txt")"
[ "${NLIVE:-x}" = "0" ] \
  && ok "the live store carries 0 live grants — creating one is a governance act, not a build step" \
  || { no "the live store carries ${NLIVE:-<unparsed>} live grant(s); this packet must create none"; dump; }
# The worked example must be present AND uncounted. An example a parser can see
# is a live grant wearing a label.
grep -qE '^#.*envelope: ' "$STORE" \
  && ok "the store carries a worked example, and it lives entirely inside comments" \
  || no "the store documents no example, so its schema is described nowhere a reader can copy"
grep -qE '^envelope: ' "$STORE" \
  && no "the store carries an UNCOMMENTED \`envelope:\` record — that is a live grant, and this packet creates none" \
  || ok "no uncommented \`envelope:\` record exists in the store: the example cannot be counted by any parser"

echo "== 8. ZERO GRANTS IS THE CORRECT STATE — deliberately NOT the registry's vacuity rule =="
# This is the one place the census's "an empty store is the shelfware state"
# reasoning is refused, and the refusal is the point: an empty control registry
# is a system nobody classified, but an empty envelope store is a system that
# has re-authorised nothing.
printf '# a store with no grants at all\n' > "$WORK/empty.txt"
RC="$(run check --store "$WORK/empty.txt" --registry "$REG")"
[ "$RC" = "0" ] \
  && ok "a store parsing to ZERO envelopes exits 0 — zero grants is the correct state, not a blinded derivation" \
  || { no "an empty store exited $RC — that would make \"nothing has been re-authorised\" an error"; dump; }
out | grep -qiE 'zero|0 live grant' \
  && ok "and the report says so in words, where the operator reads it" \
  || { no "the empty-store report does not state that zero grants is the expected state"; dump; }
RC="$(run check --store "$WORK/nosuchfile.txt" --registry "$REG")"
[ "$RC" = "2" ] \
  && ok "an ABSENT store is REFUSED (exit 2) — an absent store is not an empty one" \
  || { no "an absent store exited $RC"; dump; }

echo "== 9. A WELL-FORMED ENVELOPE VALIDATES, and L_effective is COMPUTED =="
mkreg "$WORK/reg.txt" <<'EOF'
f.classc_red|C|red_driven|advise
f.classa_red|A|red_driven|gate
f.classa_unval|A|unvalidated|gate
EOF
mkenv "$WORK/ok.txt" <<'EOF'
e.ok|f.classa_red|gate|autonomous
EOF
RC="$(run check --store "$WORK/ok.txt" --registry "$WORK/reg.txt")"
[ "$RC" = "0" ] && ok "a well-formed envelope validates and the run exits 0" || { no "a valid envelope exited $RC"; dump; }
[ "$(field e.ok l-effective)" = "gate" ] \
  && ok "L_effective for class A + red_driven + autonomous is \`gate\` — all three terms at the top" \
  || { no "L_effective was '$(field e.ok l-effective)', expected gate"; dump; }
EBAD=0
for k in l-class l-evidence l-deployment l-effective; do
  v="$(field e.ok "$k")"
  in_list "${v:-}" "$LADDER" || { EBAD=$((EBAD+1)); echo "      | report line carries no valid $k (got '${v:-<none>}')"; }
done
[ "$EBAD" -eq 0 ] \
  && ok "every finding reports all three terms separately AND the composed minimum — no axis is hidden behind one number" \
  || no "$EBAD term(s) missing from the report line"

echo "== 10. THE AXIS IS NOT INERT: \`shadow\` CAPS, and it is driven red =="
# The safety property one way round is that the axis changes nothing for a
# control with no envelope. This is the other way round: an axis that could
# never bind would be decoration.
mkenv "$WORK/shadow.txt" <<'EOF'
e.shadow|f.classa_red|gate|shadow
EOF
RC="$(run check --store "$WORK/shadow.txt" --registry "$WORK/reg.txt")"
[ "$(field e.shadow l-deployment)" = "$(depcap shadow)" ] \
  && ok "RED: a class-A red_driven control under \`shadow\` has its deployment term capped" \
  || { no "RED FAILED: shadow did not cap the deployment term"; dump; }
[ "$(field e.shadow l-effective)" = "$(depcap shadow)" ] \
  && ok "RED: and the DEPLOYMENT term is the binding one — L_effective drops to shadow's cap although class and evidence both license \`gate\`" \
  || { no "RED FAILED: L_effective was '$(field e.shadow l-effective)', not shadow's cap"; dump; }
[ "$(verdict e.shadow)" = "OVER-GRANTED" ] \
  && ok "RED: granting \`gate\` under \`shadow\` is named OVER-GRANTED" \
  || { no "RED FAILED: an over-granted shadow envelope was not named"; dump; }
[ "$(field e.shadow binding-axis)" = "deployment" ] \
  && ok "and the finding NAMES the axis that binds it, as the two-axis matrix already does" \
  || { no "the finding does not name deployment as the binding axis (got '$(field e.shadow binding-axis)')"; dump; }
[ "$RC" = "0" ] \
  && ok "the validator ADVISES: it names the over-grant and exits 0, as its class-C licence allows" \
  || { no "the validator exited $RC on an over-grant — it is gating on a chosen policy"; dump; }

echo "== 11. EACH TERM CAN BIND ON ITS OWN — the minimum is a real minimum =="
mkenv "$WORK/three.txt" <<'EOF'
e.byclass|f.classc_red|gate|autonomous
e.byevidence|f.classa_unval|gate|autonomous
e.bydeployment|f.classa_red|gate|human_confirmed
EOF
run check --store "$WORK/three.txt" --registry "$WORK/reg.txt" >/dev/null
[ "$(field e.byclass binding-axis)" = "class" ] \
  && ok "a class-C control granted \`gate\` binds on the CLASS axis" \
  || { no "class-axis binding not attributed (got '$(field e.byclass binding-axis)')"; dump; }
[ "$(field e.byevidence binding-axis)" = "evidence" ] \
  && ok "a class-A control on \`unvalidated\` evidence granted \`gate\` binds on the EVIDENCE axis" \
  || { no "evidence-axis binding not attributed (got '$(field e.byevidence binding-axis)')"; dump; }
[ "$(field e.bydeployment binding-axis)" = "deployment" ] \
  && ok "a class-A red_driven control granted \`gate\` under \`human_confirmed\` binds on the DEPLOYMENT axis" \
  || { no "deployment-axis binding not attributed (got '$(field e.bydeployment binding-axis)')"; dump; }

echo "== 12. AN ENVELOPE WITHIN ITS LICENCE IS NOT FLAGGED =="
mkenv "$WORK/within.txt" <<'EOF'
e.within|f.classa_red|advise|human_confirmed
EOF
run check --store "$WORK/within.txt" --registry "$WORK/reg.txt" >/dev/null
[ "$(verdict e.within)" != "OVER-GRANTED" ] \
  && ok "an envelope granting no more than the three axes license is not flagged — the check discriminates" \
  || { no "a within-licence envelope was flagged, so the finding above proves nothing"; dump; }

echo "== 13. THE ONE THING IT REFUSES — every refusal state, driven red =="
# Mirrors evidence.derivation_nonvacuity: a derivation it cannot trust must
# refuse rather than fall through. Each state below is a separate exit-2 drive.
refuses(){ # <label> <file-body-on-stdin>
  local label="$1" f="$WORK/ref.txt" rc
  cat > "$f"
  rc="$(run check --store "$f" --registry "$WORK/reg.txt")"
  if [ "$rc" = "2" ]; then ok "REFUSED (exit 2): $label"
  else no "$label exited $rc — a store this tool cannot trust must never report a clean licence"; dump; fi
}
refuses "a line that is neither blank, a comment, nor \`field: value\`" <<'EOF'
envelope: e.ragged
this line is not a field
EOF
refuses "a field the schema has no slot for" <<'EOF'
envelope: e.extra
issuer: x
actor: x
control: f.classa_red
scope: x
granted_authority: gate
evidence_basis: x
deployment_mode: autonomous
starts: 2026-01-01
expires: 2026-12-31
revocation: x
reason: x
human_confirmation: x
rollback_behavior: x
vibes: high
EOF
refuses "the camelCase spelling \`deploymentMode\`, which this store does not use" <<'EOF'
envelope: e.camel
issuer: x
actor: x
control: f.classa_red
scope: x
granted_authority: gate
evidence_basis: x
deploymentMode: shadow
starts: 2026-01-01
expires: 2026-12-31
revocation: x
reason: x
human_confirmation: x
rollback_behavior: x
EOF
refuses "a record missing a required field" <<'EOF'
envelope: e.short
issuer: x
control: f.classa_red
granted_authority: gate
deployment_mode: autonomous
EOF
refuses "a field appearing before any \`envelope:\` record" <<'EOF'
issuer: nobody
EOF
refuses "a granted_authority that is not a rung of the ladder" <<'EOF'
envelope: e.badauth
issuer: x
actor: x
control: f.classa_red
scope: x
granted_authority: supreme
evidence_basis: x
deployment_mode: autonomous
starts: 2026-01-01
expires: 2026-12-31
revocation: x
reason: x
human_confirmation: x
rollback_behavior: x
EOF
refuses "a date that is not YYYY-MM-DD" <<'EOF'
envelope: e.baddate
issuer: x
actor: x
control: f.classa_red
scope: x
granted_authority: gate
evidence_basis: x
deployment_mode: autonomous
starts: soon
expires: 2026-12-31
revocation: x
reason: x
human_confirmation: x
rollback_behavior: x
EOF
refuses "an expiry that does not follow its start — a lease that never opens" <<'EOF'
envelope: e.backwards
issuer: x
actor: x
control: f.classa_red
scope: x
granted_authority: gate
evidence_basis: x
deployment_mode: autonomous
starts: 2026-12-31
expires: 2026-01-01
revocation: x
reason: x
human_confirmation: x
rollback_behavior: x
EOF
{
  mkenv "$WORK/dup.txt" <<'EOF'
e.same|f.classa_red|gate|autonomous
e.same|f.classc_red|advise|shadow
EOF
  RCD="$(run check --store "$WORK/dup.txt" --registry "$WORK/reg.txt")"
  [ "$RCD" = "2" ] \
    && ok "REFUSED (exit 2): two envelopes sharing one id — a grant nobody can name uniquely cannot be revoked" \
    || { no "a duplicate envelope id exited $RCD"; dump; }
}
RC="$(run check --store "$WORK/ok.txt" --registry "$WORK/nosuchreg.txt")"
[ "$RC" = "2" ] \
  && ok "REFUSED (exit 2): an absent control registry — an envelope's licence cannot be computed against a census nobody read" \
  || { no "an absent registry exited $RC"; dump; }

echo "== 14. AN UNRECOGNISED DEPLOYMENT MODE MUST NEVER FALL THROUGH TO PERMISSIVE =="
# The sharpest property in this file. A mode the tool has no cap for is exactly
# the shape a future `untested`-style token will arrive in, and defaulting it to
# the permissive end is how a matrix stops discriminating while printing green.
UBAD=0
for badmode in vibes human-confirmed "bounded autonomous" SHADOW ""; do
  {
    printf 'envelope: e.mode\n'
    printf 'issuer: x\nactor: x\ncontrol: f.classa_red\nscope: x\n'
    printf 'granted_authority: gate\nevidence_basis: x\n'
    printf 'deployment_mode: %s\n' "$badmode"
    printf 'starts: 2026-01-01\nexpires: 2026-12-31\n'
    printf 'revocation: x\nreason: x\nhuman_confirmation: x\nrollback_behavior: x\n'
  } > "$WORK/mode.txt"
  rc="$(run check --store "$WORK/mode.txt" --registry "$WORK/reg.txt")"
  [ "$rc" = "2" ] || { UBAD=$((UBAD+1)); echo "      | deployment_mode \"$badmode\" exited $rc instead of refusing"; }
done
[ "$UBAD" -eq 0 ] \
  && ok "RED: every unrecognised deployment mode REFUSES — including the operator's prose spellings \`human-confirmed\` and \`bounded autonomous\`, which this store does not accept" \
  || no "$UBAD unrecognised deployment mode(s) did not refuse — an unknown mode fell through toward permissive"
out | grep -qF 'deployment_mode' \
  && ok "and the refusal names the field it could not read" \
  || { no "the unknown-mode refusal does not name deployment_mode"; dump; }
out | grep -qE 'shadow|human_confirmed|bounded_autonomous|autonomous' \
  && ok "and it names the spellings it DOES accept, so the fix is readable from the refusal" \
  || { no "the refusal does not say which modes are accepted"; dump; }

echo "== 15. IT GRANTS NOTHING, and writes nothing =="
BEFORE="$(cksum < "$STORE")"
RBEFORE="$(cksum < "$REG")"
run check --repo "$SRC" >/dev/null
[ "$(cksum < "$STORE")" = "$BEFORE" ] \
  && ok "the live envelope store is byte-identical after a run — the validator never writes a grant" \
  || no "the envelope store changed during a run: this tool must never create a grant"
[ "$(cksum < "$REG")" = "$RBEFORE" ] \
  && ok "the live control registry is byte-identical after a run — no control is re-authorised by validation" \
  || no "the control registry changed during a run"
grep -qE '^[[:space:]]*(sed -i|>[[:space:]]*"?\$STORE|>[[:space:]]*"?\$REGISTRY|tee )' "$TOOL" \
  && no "the tool contains an in-place write to one of its inputs" \
  || ok "the tool contains no in-place write to the store or the registry it reads"
out | grep -qiE 'grants nothing|does not grant|no authority is granted' \
  && ok "the report states outright that validating an envelope grants nothing" \
  || { no "the report never disclaims granting"; dump; }

echo "== 16. \`modes\` is the machine projection the evidence matrix consumes =="
# One parser, one schema owner. The evidence matrix must not grow a second
# envelope parser that can disagree with this one.
RC="$(run modes --store "$WORK/shadow.txt")"
[ "$RC" = "0" ] && ok "\`modes\` exits 0 on a valid store" || { no "\`modes\` exited $RC"; dump; }
grep -qE "^f\.classa_red$(printf '\t')shadow$" "$WORK/out.txt" \
  && ok "\`modes\` emits <control-id>TAB<deployment_mode>, one line per live grant" \
  || { no "\`modes\` did not emit the expected projection"; dump; }
RC="$(run modes --store "$WORK/empty.txt")"
{ [ "$RC" = "0" ] && [ ! -s "$WORK/out.txt" ]; } \
  && ok "\`modes\` on an empty store emits nothing and exits 0 — which is what makes the third axis inert today" \
  || { no "\`modes\` on an empty store exited $RC with output"; dump; }
RC="$(run modes --store "$WORK/nosuchfile.txt")"
[ "$RC" = "2" ] \
  && ok "\`modes\` REFUSES an absent store too — the projection carries the same gate as the report" \
  || { no "\`modes\` on an absent store exited $RC — the consumer would read silence as \"no grants\""; dump; }
grep -qF 'authority-envelope.sh' "$EPOL" \
  && ok "the evidence matrix sources its third axis from THIS tool rather than parsing the store itself" \
  || no "the evidence matrix does not reference authority-envelope.sh — two parsers for one schema will drift"

echo "== 17. THE TENSION IS RECORDED AND NOT RESOLVED =="
# The sanctioned S1 declaration is `heuristic_policy` / `untested` / `rank` /
# `shadow`, and min() cannot produce `rank` for it. Two readings exist. Choosing
# either one silently would redefine the ladder, which is a governance change.
HDR="$WORK/hdr.txt"; sed -n '1,200p' "$TOOL" > "$HDR"
grep -qiE 'open question|unresolved|for the operator' "$HDR" \
  && ok "the tool's header marks the S1 collision as an OPEN QUESTION for the operator" \
  || { no "the header does not mark the collision as open"; sed -n '1,6p' "$HDR" | sed 's/^/      | /'; }
grep -qF 'heuristic_policy' "$HDR" \
  && ok "and it names the declaration that collides: controlClass heuristic_policy" \
  || no "the header does not name the colliding S1 declaration"
TBAD=0
grep -qiE 'authority_mismatch: declared|15th|fifteenth' "$HDR" || { TBAD=$((TBAD+1)); echo "      | reading 1 (S1 ships as a declared mismatch) is not stated"; }
grep -qiE 'shadow.*no consequence|conflat|measuring the wrong property' "$HDR" || { TBAD=$((TBAD+1)); echo "      | reading 2 (runtime_authority measures the wrong property in shadow) is not stated"; }
[ "$TBAD" -eq 0 ] \
  && ok "BOTH readings are recorded — the honest-mismatch reading and the ladder-conflation reading" \
  || no "$TBAD of the two readings is missing; recording one and not the other IS choosing"
# Neither may have been adopted: no `shadow` exemption may exist in the caps.
[ "$(rank_of "$(depcap shadow)")" -lt "$(rank_of rank)" ] \
  && ok "and NEITHER reading has been adopted in the code: \`shadow\` still caps below \`rank\`, so S1 as declared would still be out of licence" \
  || no "reading 2 has been silently adopted — shadow now licenses rank, which redefines the ladder"

echo "== 18. \`untested\` IS PENDING, DECLARED, AND NOT IMPLEMENTED =="
# The operator ruled `untested` and `unvalidated` meaningfully different, and
# ruled that difference to be the NEXT packet's decision. Recording it is in
# scope; implementing it is not, because adding a token purely to make a planned
# control fit is the failure the registry exists to prevent.
run schema >/dev/null
grep -qE '^pending: untested ' "$WORK/out.txt" \
  && ok "\`untested\` is declared as the ONE pending extension, on its own \`pending:\` line" \
  || { no "the pending extension is not declared where the operator reads it"; dump; }
grep -qiE '^pending: untested .*(has not yet produced|no live output)' "$WORK/out.txt" \
  && ok "and the declaration states what \`untested\` would MEAN, so the next packet decides a defined thing" \
  || { no "the pending line does not define untested against unvalidated"; dump; }
grep -qE '^EVIDENCE_AXIS=.*untested' "$EPOL" \
  && no "\`untested\` has been added to EVIDENCE_AXIS — this packet must declare it, not implement it" \
  || ok "\`untested\` is NOT on the evidence axis: declared, not implemented"
# ...and the existing Class-A gate must still refuse it, which is the proof that
# "not implemented" means "refused" and not "silently permitted".
{
  printf 'control: pending.untested\n'
  printf 'class: C\n'
  printf 'empirical_status: untested\n'
  printf 'runtime_authority: rank\n\n'
} > "$WORK/untested_reg.txt"
"$EPOL" check --registry "$WORK/untested_reg.txt" --envelopes "$WORK/empty.txt" > "$WORK/u.txt" 2>&1
RCU="$?"
[ "$RCU" = "2" ] \
  && ok "RED: a control declaring \`untested\` is still REFUSED by evidence.derivation_nonvacuity (exit 2), not quietly permitted" \
  || { no "an \`untested\` token exited $RCU — an unrecognised evidence level fell through"; sed 's/^/      | /' "$WORK/u.txt" | head -6; }
grep -qF 'untested' "$WORK/u.txt" \
  && ok "and the refusal names the token it has no cap for" \
  || no "the refusal does not name untested"

echo "== 19. Usage errors refuse rather than guessing =="
RC="$(run)";              [ "$RC" = "2" ] && ok "no command is REFUSED (exit 2)"        || { no "no command exited $RC"; dump; }
RC="$(run wibble)";       [ "$RC" = "2" ] && ok "an unknown command is REFUSED"          || { no "an unknown command exited $RC"; dump; }
RC="$(run check --store)";[ "$RC" = "2" ] && ok "an option missing its value is REFUSED" || { no "a valueless --store exited $RC"; dump; }
RC="$(run check --nope x)";[ "$RC" = "2" ] && ok "an unknown option is REFUSED"          || { no "an unknown option exited $RC"; dump; }

echo "== 20. The tool and its suite are registered as control surfaces =="
grep -qF "owning_module: build-os/tools/authority-envelope.sh" "$REG" \
  && ok "the tool owns at least one registry entry" \
  || no "the authority-envelope tool exits non-zero and owns no registry entry"
grep -qF "owning_module: tests/authority_envelope_tests.sh" "$REG" \
  && ok "this suite owns a registry entry" \
  || no "this suite exits non-zero and owns no registry entry"
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
gated_by "build-os/tools/authority-envelope.sh" | grep -q . \
  && ok "the tool owns a \`gate\` entry, as the anti-shelfware scan requires of anything that can stop a run" \
  || no "the tool can exit 2 but no entry records it at authority gate"
ENVID="$(advised_by "build-os/tools/authority-envelope.sh" | head -1)"
[ -n "$ENVID" ] \
  && ok "the envelope machinery itself is registered at authority \`advise\` ($ENVID)" \
  || no "no entry registers the envelope validator at advise — its authority is undeclared"
awk -v i="$ENVID" '/^control: /{c=$2} c==i && /^class: /{print $2; exit}' "$REG" | grep -qx C \
  && ok "$ENVID is Class C — chosen policy, not a definition" \
  || no "$ENVID is not registered Class C"
awk -v i="$ENVID" '/^control: /{c=$2} c==i && /^authority_mismatch: /{print $2; exit}' "$REG" | grep -qx none \
  && ok "$ENVID declares NO authority mismatch — Class C at advise is exactly its licence" \
  || no "$ENVID declares an authority mismatch, which a Class-C control at advise must not"

echo "== 21. This packet re-authorises nothing =="
# The hardest rule in the packet, checked mechanically: the store may name no
# control that the census already classifies, because such a record would be a
# live grant for an existing control — which is step 3, not this packet.
if [ ! -f "$STORE" ]; then
  no "the envelope store is absent, so the re-authorisation check below would pass by reading nothing"
else
  ok "the store is present, so the re-authorisation check below reads a real file"
  LIVEC="$(awk '/^#/{next} /^control: /{print $2}' "$STORE" | grep -c . || true)"
  [ "${LIVEC:-0}" = "0" ] \
    && ok "the store names no control in any uncommented record — no existing control is re-authorised here" \
    || no "the store names ${LIVEC} control(s) in live records; this packet must create no grant"
  # ...and the census must be untouched in the direction that matters: not one
  # control may name an envelope, because an envelope is not a registry field.
  grep -qE '^(deployment_mode|deploymentMode|envelope): ' "$REG" \
    && no "the control registry has grown an envelope field — a grant belongs in the store, not in the census" \
    || ok "the control registry carries no envelope field: the two artefacts stay separate, as the crosswalk's own §1 argues"
fi

echo "== 22. This suite is chained, and is not vacuous about itself =="
grep -qF 'chain_suite "tests/authority_envelope_tests.sh"' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained from tests/build_os_tests.sh (not discoverable-only)" \
  || no "this suite is present but never chained from tests/build_os_tests.sh"
# A DERIVED floor: more assertions than the schema has fields plus modes. It
# states no numeric literal, so it does not join the tests.nonvacuity_minimums
# family that tests/control_registry_tests.sh §21 polices.
FLOOR=$((NFIELD + NMODE))
[ "$PASS" -gt "$FLOOR" ] \
  && ok "this suite ran $PASS assertions, more than the $FLOOR schema fields and deployment modes it pins" \
  || no "this suite ran only $PASS assertions against $FLOOR pinned schema elements"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
