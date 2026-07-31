#!/usr/bin/env bash
# Build OS — Neurocosmology crosswalk tests.
#
# WHAT THIS PINS. build-os/registry/neurocosmology_crosswalk.txt binds every
# control in the census to the ONE universal primitive whose function it
# instantiates — or records that it instantiates none, and why. The registry
# says what kind of evidence a control is; the crosswalk says what the control
# is FOR, in the framework's vocabulary. The claims that must stay checkable:
#
#   1. IT IS A CLASSIFICATION, NOT AN IMPLEMENTATION. The crosswalk computes no
#      potential, no coherence measure, no goal ecology and no value of
#      information, creates no control, and grants no authority. Section 8
#      enforces that: the artefact is inert data, and every authority it names
#      is a COPY of one the registry already recorded.
#   2. NO CONTROL IS OMITTED. The anti-omission guard is the §21 lesson of the
#      registry suite, where derived membership beat asserted membership 34 to
#      6: the binding set is reconciled against the REGISTRY rather than against
#      itself, in both directions. A control added to the census and never bound
#      here FAILS, and so does a binding naming a control that does not exist.
#   3. THE TWO FILES MAY NOT DRIFT. Each binding restates its control's class
#      and runtime_authority. That redundancy is deliberate — it is the same
#      device as lanedecl.threshold_pinning — and a one-sided edit fails here.
#   4. A PRIMITIVE MAY NOT CLAIM AUTHORITY IT DOES NOT HOLD. A primitive's
#      claimed_max_authority must equal the maximum actually held by a control
#      bound to it, so coverage cannot be overstated by assertion.
#   5. VACUITY FAILS LOUDLY. Zero bindings, zero primitives, or a scan that
#      found zero controls is a failure, never a quiet pass.
#
# No network. Deterministic. Every fixture lives under $WORK; nothing outside it
# is written. Exits non-zero if any assertion fails.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XW="$SRC/build-os/registry/neurocosmology_crosswalk.txt"
REG="$SRC/build-os/registry/control_registry.txt"
DOC="$SRC/build-os/registry/CROSSWALK.md"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The declared vocabularies. Duplicated here ON PURPOSE: a test that reads its
# expected values out of the artefact it is checking cannot detect the artefact
# widening its own enum. The 17 primitives are the operator's crosswalk, in the
# operator's order.
PRIMITIVES="reachability meaning_metric mass valence agency energy homeostasis \
integration_bandwidth boundary ethical_admissibility epistemic_quality \
latent_state durability gated_plasticity collective_coherence goal_ecology wisdom"
KINDS="instantiates proxies nominal unbound"
AUTHORITIES="none observe advise rank gate"
PFIELDS="primitive universal_function system_representation observable_proxies binding_quality claimed_max_authority known_limitations"
BFIELDS="control binds_to class runtime_authority binding_kind rationale"

rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; *) echo -1 ;; esac; }
kind_rank(){ case "$1" in unbound) echo 0 ;; nominal) echo 1 ;; proxies) echo 2 ;; instantiates) echo 3 ;; *) echo -1 ;; esac; }
in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }

# ---------------------------------------------------------------------------
# Extractors. Every check below is a FUNCTION OF A FILE PATH, so the red drives
# in section 9 run the identical code over a damaged fixture rather than a
# re-implementation of it. A check proven only against the live artefact is a
# check nobody has tested.
# ---------------------------------------------------------------------------

# control \t binds_to \t class \t runtime_authority \t binding_kind
xw_bindings(){ awk -F': ' '
  /^control: /{c=$2; b="";cl="";ra="";k=""; next}
  /^binds_to: /{b=$2} /^class: /{cl=$2} /^runtime_authority: /{ra=$2} /^binding_kind: /{k=$2}
  /^$/{if(c!="")print c"\t"b"\t"cl"\t"ra"\t"k; c=""}
  END{if(c!="")print c"\t"b"\t"cl"\t"ra"\t"k}' "$1"; }

# primitive \t binding_quality \t claimed_max_authority
xw_primitives(){ awk -F': ' '
  /^primitive: /{p=$2; q="";a=""; next}
  /^binding_quality: /{q=$2} /^claimed_max_authority: /{a=$2}
  /^$/{if(p!="")print p"\t"q"\t"a; p=""}
  END{if(p!="")print p"\t"q"\t"a}' "$1"; }

# control \t class \t runtime_authority, from the census
reg_controls(){ awk -F': ' '
  /^control: /{c=$2; cl="";ra=""; next}
  /^class: /{cl=$2} /^runtime_authority: /{ra=$2}
  /^$/{if(c!="")print c"\t"cl"\t"ra; c=""}
  END{if(c!="")print c"\t"cl"\t"ra}' "$1"; }

echo "== 1. The artefacts exist and are not empty =="
for pair in "neurocosmology_crosswalk.txt:$XW" "control_registry.txt:$REG" "CROSSWALK.md:$DOC"; do
  n="${pair%%:*}"; p="${pair#*:}"
  { [ -f "$p" ] && [ -s "$p" ]; } && ok "$n exists and is non-empty" || no "$n is missing or empty"
done

echo "== 2. VACUITY GUARDS — a crosswalk that binds nothing must fail loudly =="
xw_bindings "$XW"  > "$WORK/bind.tsv"
xw_primitives "$XW" > "$WORK/prim.tsv"
reg_controls "$REG" > "$WORK/reg.tsv"
NB="$(grep -c . "$WORK/bind.tsv" || true)";  NB="${NB:-0}"
NP="$(grep -c . "$WORK/prim.tsv" || true)";  NP="${NP:-0}"
NR="$(grep -c . "$WORK/reg.tsv" || true)";   NR="${NR:-0}"
[ "$NB" -gt 0 ] && ok "the crosswalk carries $NB binding(s) — not vacuous" \
                || no "the crosswalk carries ZERO bindings, so every comparison below is meaningless"
[ "$NR" -gt 0 ] && ok "the registry scan found $NR control(s) — the census is visible" \
                || no "the scan of the registry found ZERO controls — it has gone blind, so coverage below is meaningless"
[ "$NP" -eq 17 ] && ok "the crosswalk declares exactly 17 primitives" \
                 || no "the crosswalk declares $NP primitives, not 17"

echo "== 3. Record shape — every record carries exactly its fields, in order =="
# A stanza file's whole argument is that it needs no parser. That holds only if
# it cannot rot into free text, so the shape is executed rather than trusted.
awk -v PF="$PFIELDS" -v BF="$BFIELDS" '
  function flush(   i, got, want) {
    if (n == 0) return
    got = ""
    for (i = 1; i <= n; i++) got = got (i > 1 ? " " : "") keys[i]
    if      (keys[1] == "primitive") want = PF
    else if (keys[1] == "control")   want = BF
    else { print "record starts with an unknown field: " keys[1]; n = 0; return }
    if (got != want) print "record " first ": fields [" got "]"
    n = 0
  }
  /^#/ { next }
  /^[[:space:]]*$/ { flush(); next }
  {
    if (match($0, /^[a-z_]+: /)) {
      k = $0; sub(/: .*$/, "", k)
      n++; keys[n] = k
      if (n == 1) { first = substr($0, 1, 60) }
    } else { print "ragged line: " substr($0, 1, 60) }
  }
  END { flush() }
' "$XW" > "$WORK/shape.txt"
SHAPEBAD="$(grep -c . "$WORK/shape.txt" 2>/dev/null || true)"; SHAPEBAD="${SHAPEBAD:-0}"
[ "$SHAPEBAD" -eq 0 ] \
  && ok "every record carries exactly its declared fields, in order (2 shapes, no ragged lines)" \
  || { no "$SHAPEBAD record(s) are malformed"; head -5 "$WORK/shape.txt" | sed 's/^/      | /'; }

echo "== 4. Every binding names one of the 17 primitives, and a legal kind =="
BADP=0; BADK=0
while IFS=$'\t' read -r c b cl ra k; do
  [ -n "$c" ] || continue
  in_list "$b" "$PRIMITIVES none" || { BADP=$((BADP+1)); echo "      | $c binds to unknown primitive: $b"; }
  in_list "$k" "$KINDS"           || { BADK=$((BADK+1)); echo "      | $c has unknown binding_kind: $k"; }
  if [ "$b" = "none" ] && [ "$k" != "unbound" ]; then
    BADK=$((BADK+1)); echo "      | $c binds to none but its kind is $k"
  fi
  if [ "$b" != "none" ] && [ "$k" = "unbound" ]; then
    BADK=$((BADK+1)); echo "      | $c is kind unbound but names primitive $b"
  fi
done < "$WORK/bind.tsv"
[ "$BADP" -eq 0 ] && ok "all $NB binding(s) name a primitive from the declared 17 (or an explicit none)" \
                  || no "$BADP binding(s) name a primitive outside the 17"
[ "$BADK" -eq 0 ] && ok "all $NB binding(s) carry a legal binding_kind consistent with bound/unbound" \
                  || no "$BADK binding(s) carry an illegal or inconsistent binding_kind"

echo "== 5. ANTI-OMISSION — bound or explicitly unbound, reconciled against the CENSUS =="
# The §21 lesson: derived membership beats asserted membership. The binding set
# is compared against the registry in BOTH directions, so a control added to the
# census and never bound here fails, and a binding naming a control that does
# not exist fails.
cut -f1 "$WORK/bind.tsv" | sort > "$WORK/xw_ids.txt"
cut -f1 "$WORK/reg.tsv"  | sort > "$WORK/reg_ids.txt"
MISSING="$(comm -13 "$WORK/xw_ids.txt" "$WORK/reg_ids.txt")"
GHOST="$(comm -23 "$WORK/xw_ids.txt" "$WORK/reg_ids.txt")"
DUPB="$(cut -f1 "$WORK/bind.tsv" | sort | uniq -d)"
[ -z "$MISSING" ] \
  && ok "every one of the $NR registered control(s) has a binding record — none omitted" \
  || { no "$(printf '%s\n' "$MISSING" | grep -c .) registered control(s) are SILENTLY UNBOUND"; printf '%s\n' "$MISSING" | sed 's/^/      | unbound: /'; }
[ -z "$GHOST" ] \
  && ok "every binding names a control that exists in the registry — no ghosts" \
  || { no "$(printf '%s\n' "$GHOST" | grep -c .) binding(s) name a control the registry does not contain"; printf '%s\n' "$GHOST" | sed 's/^/      | ghost: /'; }
[ -z "$DUPB" ] \
  && ok "no control is bound twice — each names exactly one primitive" \
  || { no "$(printf '%s\n' "$DUPB" | grep -c .) control(s) carry more than one binding"; printf '%s\n' "$DUPB" | sed 's/^/      | duplicate: /'; }
[ "$NB" -eq "$NR" ] \
  && ok "binding count equals census size ($NB = $NR)" \
  || no "binding count $NB does not equal census size $NR"

echo "== 6. NO DRIFT — a binding may not contradict the control's own registry entry =="
# Same standard the lane table and the sentinel blocks already meet. The copy is
# redundant on purpose; redundancy is what makes a one-sided edit detectable.
join -t $'\t' -j 1 "$WORK/reg_ids.txt" /dev/null > /dev/null 2>&1 || true
sort -t $'\t' -k1,1 "$WORK/bind.tsv" > "$WORK/bind_s.tsv"
sort -t $'\t' -k1,1 "$WORK/reg.tsv"  > "$WORK/reg_s.tsv"
join -t $'\t' -j 1 -o 0,1.3,1.4,2.2,2.3 "$WORK/bind_s.tsv" "$WORK/reg_s.tsv" 2>/dev/null \
  | awk -F'\t' '$2!=$4 || $3!=$5 {print $1"\tcrosswalk says "$2"/"$3", registry says "$4"/"$5}' > "$WORK/drift.txt"
NDRIFT="$(grep -c . "$WORK/drift.txt" || true)"; NDRIFT="${NDRIFT:-0}"
[ "$NDRIFT" -eq 0 ] \
  && ok "every binding's class and runtime_authority match the registry entry exactly" \
  || { no "$NDRIFT binding(s) contradict the registry"; head -5 "$WORK/drift.txt" | sed 's/^/      | /'; }

echo "== 7. A primitive may not claim authority no bound control holds =="
# Coverage stated rather than derived is how a crosswalk flatters itself. The
# claim is kept so that it can be falsified, not so that it can be believed.
: > "$WORK/authviol.txt"; : > "$WORK/qualviol.txt"
while IFS=$'\t' read -r p q a; do
  [ -n "$p" ] || continue
  in_list "$a" "$AUTHORITIES" || { echo "$p claims unknown authority $a" >> "$WORK/authviol.txt"; continue; }
  in_list "$q" "$KINDS"       || { echo "$p claims unknown binding_quality $q" >> "$WORK/qualviol.txt"; continue; }
  best=0; bestk=0; nbound=0
  while IFS=$'\t' read -r c b cl ra k; do
    [ "$b" = "$p" ] || continue
    nbound=$((nbound+1))
    r="$(rank_of "$ra")"; [ "$r" -gt "$best" ] && best="$r"
    kr="$(kind_rank "$k")"; [ "$kr" -gt "$bestk" ] && bestk="$kr"
  done < "$WORK/bind.tsv"
  [ "$nbound" -eq 0 ] && { best=0; bestk=0; }
  claimed="$(rank_of "$a")"
  [ "$claimed" -eq "$best" ] || echo "$p claims max authority '$a' but the strongest of its $nbound bound control(s) is rank $best" >> "$WORK/authviol.txt"
  [ "$(kind_rank "$q")" -eq "$bestk" ] || echo "$p claims binding_quality '$q' but its strongest binding_kind is rank $bestk" >> "$WORK/qualviol.txt"
done < "$WORK/prim.tsv"
NAV="$(grep -c . "$WORK/authviol.txt" || true)"; NAV="${NAV:-0}"
NQV="$(grep -c . "$WORK/qualviol.txt" || true)"; NQV="${NQV:-0}"
[ "$NAV" -eq 0 ] \
  && ok "every primitive's claimed_max_authority equals the strongest authority its bound controls actually hold" \
  || { no "$NAV primitive(s) claim an authority no bound control holds"; head -5 "$WORK/authviol.txt" | sed 's/^/      | /'; }
[ "$NQV" -eq 0 ] \
  && ok "every primitive's binding_quality equals the strongest binding_kind bound to it" \
  || { no "$NQV primitive(s) overstate their binding_quality"; head -5 "$WORK/qualviol.txt" | sed 's/^/      | /'; }

echo "== 8. The crosswalk CLASSIFIES — it computes nothing and authorises nothing =="
# The hard constraint of the packet that created this file, executed. A
# conceptual equation must not control production before its quantities are
# computable, so the artefact stays inert data.
[ ! -x "$XW" ] && ok "the crosswalk is not executable — it is data, not a control surface" \
               || no "the crosswalk file is executable, which would make it a control surface"
grep -qE '^#!' "$XW" && no "the crosswalk carries a shebang" \
                     || ok "the crosswalk carries no shebang"
# INERTNESS, structurally rather than by keyword. Grepping prose for maths
# tokens is a bad instrument — the live file legitimately discusses `exit 0` and
# quotes control ids in backticks. The claim worth proving is stronger and
# cheaper: EVERY line is a comment, a blank, or a `field: value` pair, so there
# is nothing here that could execute whatever it said.
NONDATA="$(grep -vcE '^#|^[[:space:]]*$|^[a-z_]+: ' "$XW" || true)"; NONDATA="${NONDATA:-0}"
[ "$NONDATA" -eq 0 ] \
  && ok "every line is a comment, a blank, or a field: value pair — the file is inert data and cannot compute or refuse" \
  || no "$NONDATA line(s) are neither comment, blank nor field: value; this file must stay inert"
# It creates no control: the DATA file may never be an owning_module. (Its test
# suite legitimately is one — a suite that can fail the build is a gate, and it
# is registered as suite.neurocosmology_crosswalk. The artefact it reads is not.)
grep -q "owning_module:.*neurocosmology_crosswalk\.txt" "$REG" \
  && no "the crosswalk DATA file is registered as an owning_module — it has become a control, which this packet forbids" \
  || ok "no registry entry names the crosswalk data file as an owning_module — it creates no control"
# Every authority named here is a copy, never a grant: section 6 already proved
# each equals the registry's. This asserts the file says so, where a reader sees it.
grep -qiE 'grants no authority|no authority is granted' "$XW" \
  && ok "the crosswalk states in its own header that it grants no authority" \
  || no "the crosswalk does not state that it grants no authority"
UNKAUTH="$(cut -f4 "$WORK/bind.tsv" | sort -u | while read -r a; do [ -n "$a" ] && { in_list "$a" "$AUTHORITIES" || echo "$a"; }; done)"
[ -z "$UNKAUTH" ] \
  && ok "every runtime_authority named in a binding is from the registry's declared ladder" \
  || no "binding(s) name authorities outside the ladder: $UNKAUTH"

echo "== 9. RED DRIVES — the guards are driven against damaged fixtures =="
# Each fixture runs the SAME extractor and the SAME comparison as the live check
# above. A guard observed only passing is a guard nobody has tested.

# R1: a binding naming a control that does not exist.
sed 's/^control: registry.discovery_rule$/control: registry.does_not_exist/' "$XW" > "$WORK/r1.txt"
R1="$(comm -23 <(xw_bindings "$WORK/r1.txt" | cut -f1 | sort) "$WORK/reg_ids.txt")"
[ -n "$R1" ] && ok "RED: a binding naming a nonexistent control is caught ($R1)" \
             || no "RED FAILED: a binding naming a nonexistent control passed the ghost check"

# R2: a class contradicting the registry.
sed '/^control: metrics.record.verify_git$/,/^$/ s/^class: A$/class: C/' "$XW" > "$WORK/r2.txt"
sort -t $'\t' -k1,1 <(xw_bindings "$WORK/r2.txt") > "$WORK/r2_s.tsv"
R2="$(join -t $'\t' -j 1 -o 0,1.3,1.4,2.2,2.3 "$WORK/r2_s.tsv" "$WORK/reg_s.tsv" 2>/dev/null \
      | awk -F'\t' '$2!=$4 || $3!=$5 {print $1}')"
[ -n "$R2" ] && ok "RED: a binding whose class contradicts the registry is caught ($R2)" \
             || no "RED FAILED: a class contradicting the registry passed the drift check"

# R3: a registered control silently unbound — the anti-omission guard.
awk 'BEGIN{RS="";ORS="\n\n"} !/^control: suite\.control_registry\n/' "$XW" > "$WORK/r3.txt"
R3="$(comm -13 <(xw_bindings "$WORK/r3.txt" | cut -f1 | sort) "$WORK/reg_ids.txt")"
[ -n "$R3" ] && ok "RED: a registered control dropped from the crosswalk is caught as unbound ($(printf '%s' "$R3" | tr '\n' ' '))" \
             || no "RED FAILED: a silently unbound control passed the anti-omission guard"

# R4: the scan blinded — an empty crosswalk must fail the vacuity guard, not pass.
: > "$WORK/r4.txt"
R4N="$(xw_bindings "$WORK/r4.txt" | grep -c . || true)"; R4N="${R4N:-0}"
[ "$R4N" -eq 0 ] && ok "RED: a blinded scan yields 0 bindings, which section 2 fails on rather than passing quietly" \
                 || no "RED FAILED: the blinded-scan fixture still produced $R4N bindings"

# R5: a primitive claiming an authority stronger than any control bound to it.
sed '/^primitive: wisdom$/,/^$/ s/^claimed_max_authority: advise$/claimed_max_authority: gate/' "$XW" > "$WORK/r5.txt"
R5=""
while IFS=$'\t' read -r p q a; do
  [ "$p" = "wisdom" ] || continue
  best=0
  while IFS=$'\t' read -r c b cl ra k; do
    [ "$b" = "$p" ] || continue
    r="$(rank_of "$ra")"; [ "$r" -gt "$best" ] && best="$r"
  done < <(xw_bindings "$WORK/r5.txt")
  [ "$(rank_of "$a")" -eq "$best" ] || R5="wisdom claims $a, holds rank $best"
done < <(xw_primitives "$WORK/r5.txt")
[ -n "$R5" ] && ok "RED: a primitive claiming authority no bound control holds is caught ($R5)" \
             || no "RED FAILED: an overstated claimed_max_authority passed section 7"

# R6: an overstated binding_quality — nominal coverage sold as instantiation.
sed '/^primitive: mass$/,/^$/ s/^binding_quality: nominal$/binding_quality: instantiates/' "$XW" > "$WORK/r6.txt"
R6=""
while IFS=$'\t' read -r p q a; do
  [ "$p" = "mass" ] || continue
  bestk=0
  while IFS=$'\t' read -r c b cl ra k; do
    [ "$b" = "$p" ] || continue
    kr="$(kind_rank "$k")"; [ "$kr" -gt "$bestk" ] && bestk="$kr"
  done < <(xw_bindings "$WORK/r6.txt")
  [ "$(kind_rank "$q")" -eq "$bestk" ] || R6="mass claims $q over strongest kind rank $bestk"
done < <(xw_primitives "$WORK/r6.txt")
[ -n "$R6" ] && ok "RED: a primitive inflating binding_quality above its strongest binding is caught ($R6)" \
             || no "RED FAILED: an inflated binding_quality passed section 7"

echo "== 10. The report states the coverage the artefact actually carries =="
# The §25 lesson: a hand-written total goes stale the moment the artefact moves.
# EVERY CELL of CROSSWALK.md's coverage table is recomputed here — bound, inst,
# proxy, nom, classes and authorities — and every one must agree.
#
# Reconciling only `bound` and `inst` was not enough, and the gap was not
# theoretical: with four columns unread, a row could move eighteen bindings from
# proxy to nominal, or claim `authorities: rank` while the artefact's headline
# finding is that `rank` is held by 0 of 71 controls, and this section would
# still have reported green. A column that is printed but not reconciled is a
# hand-written total wearing a derived total's clothes.

# Derived columns straight from the bindings:
#   primitive \t bound \t inst \t proxy \t nom \t classes \t authorities
# Authorities are emitted in the registry's LADDER order (none < observe < advise
# < rank < gate) rather than alphabetically, so the table may list them the way
# the registry declares them without failing for a cosmetic reason. An empty
# column is the same em dash the table uses, so "nothing bound" is compared too.
xw_columns(){
  local p c a x nb ni np nn
  for p in $PRIMITIVES; do
    nb="$(awk -F'\t' -v k="$p" '$2==k{n++} END{print n+0}' "$1")"
    ni="$(awk -F'\t' -v k="$p" '$2==k && $5=="instantiates"{n++} END{print n+0}' "$1")"
    np="$(awk -F'\t' -v k="$p" '$2==k && $5=="proxies"{n++}     END{print n+0}' "$1")"
    nn="$(awk -F'\t' -v k="$p" '$2==k && $5=="nominal"{n++}     END{print n+0}' "$1")"
    c="$(awk -F'\t' -v k="$p" '$2==k{print $3}' "$1" | sort -u | paste -sd, -)"
    a=""
    for x in $AUTHORITIES; do
      awk -F'\t' -v k="$p" -v x="$x" '$2==k && $4==x{f=1} END{exit !f}' "$1" && a="${a:+$a,}$x"
    done
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$p" "$nb" "$ni" "$np" "$nn" "${c:-—}" "${a:-—}"
  done
}

# Reconcile a coverage table against derived columns. $1 doc, $2 derived, $3
# where disagreements are written; the count of coverage rows READ goes to
# stdout. This is a FUNCTION OF A FILE PATH for the same reason the extractors
# are: the red drives below run this identical code over damaged docs rather
# than a second implementation of it that could agree with nothing.
doc_recon(){
  local doc="$1" der="$2" out="$3" rows=0
  local _x p nall ninst nprox nnom ncls nauth _rest d eb ei ep en ec ea
  : > "$out"
  while IFS='|' read -r _x p nall ninst nprox nnom ncls nauth _rest; do
    p="$(printf '%s' "$p" | tr -d ' ')"
    in_list "$p" "$PRIMITIVES" || continue
    nall="$(printf  '%s' "$nall"  | tr -d ' ')"; ninst="$(printf '%s' "$ninst" | tr -d ' ')"
    nprox="$(printf '%s' "$nprox" | tr -d ' ')"; nnom="$(printf  '%s' "$nnom"  | tr -d ' ')"
    ncls="$(printf  '%s' "$ncls"  | tr -d ' ')"; nauth="$(printf '%s' "$nauth" | tr -d ' ')"
    case "$nall$ninst$nprox$nnom" in ''|*[!0-9]*) continue ;; esac
    rows=$((rows+1))
    d="$(awk -F'\t' -v k="$p" '$1==k{print; exit}' "$der")"
    [ -n "$d" ] || { echo "$p: stated in the table but derived from nothing" >> "$out"; continue; }
    eb="$(printf '%s' "$d" | cut -f2)"; ei="$(printf '%s' "$d" | cut -f3)"
    ep="$(printf '%s' "$d" | cut -f4)"; en="$(printf '%s' "$d" | cut -f5)"
    ec="$(printf '%s' "$d" | cut -f6)"; ea="$(printf '%s' "$d" | cut -f7)"
    [ "$nall"  = "$eb" ] || echo "$p: doc says $nall bound, artefact carries $eb"                   >> "$out"
    [ "$ninst" = "$ei" ] || echo "$p: doc says $ninst instantiating, artefact carries $ei"          >> "$out"
    [ "$nprox" = "$ep" ] || echo "$p: doc says $nprox proxy, artefact carries $ep"                  >> "$out"
    [ "$nnom"  = "$en" ] || echo "$p: doc says $nnom nominal, artefact carries $en"                 >> "$out"
    [ "$ncls"  = "$ec" ] || echo "$p: doc says classes [$ncls], artefact carries [$ec]"             >> "$out"
    [ "$nauth" = "$ea" ] || echo "$p: doc says authorities [$nauth], artefact carries [$ea]"        >> "$out"
  done < "$doc"
  echo "$rows"
}

xw_columns "$WORK/bind.tsv" > "$WORK/cols.tsv"
DOCROWS="$(doc_recon "$DOC" "$WORK/cols.tsv" "$WORK/docbad.txt")"
DOCBAD="$(grep -c . "$WORK/docbad.txt" || true)"; DOCBAD="${DOCBAD:-0}"
[ "$DOCROWS" -eq 17 ] \
  && ok "CROSSWALK.md states a coverage row for each of the 17 primitives" \
  || no "CROSSWALK.md states $DOCROWS coverage rows, not 17 — the table below is not checkable"
[ "$DOCBAD" -eq 0 ] \
  && ok "every cell of CROSSWALK.md's coverage table — bound, inst, proxy, nom, classes, authorities — equals the value derived from the artefact" \
  || { no "$DOCBAD stated cell(s) in CROSSWALK.md disagree with the artefact"; head -8 "$WORK/docbad.txt" | sed 's/^/      | /'; }

# How many table cells actually differ between two docs, over coverage rows. The
# red drives below floor themselves against THIS rather than against a written
# constant, so the demand is "report every cell you damaged" and the suite still
# states no fitted number — the §21 lesson, which has already caught one
# hard-coded floor inside this very file.
damaged_cells(){
  awk -F'|' '
    NR==FNR { if (NF>=8) { k=$2; gsub(/ /,"",k); a[k]=$0 } ; next }
    NF>=8 {
      k=$2; gsub(/ /,"",k)
      if (!(k in a)) next
      split(a[k], b, "|")
      for (i=3; i<=8; i++) { x=$i; y=b[i]; gsub(/ /,"",x); gsub(/ /,"",y); if (x!=y) c++ }
    }
    END { print c+0 }' "$1" "$2"
}

# RED DRIVES on this reconciliation, since the live doc is (now) correct. Each
# fixture is the REAL doc with one row damaged, so the damage is the only
# difference and doc_recon is the only judge.
# R7: a stale hand-written count in the two columns that were already checked.
awk -F'|' 'BEGIN{OFS="|"} {p=$2; gsub(/ /,"",p)} p=="epistemic_quality" && NF>=8 {$3=" 99999 "; $4=" 99999 "} {print}' "$DOC" > "$WORK/stale_doc.md"
R7N="$(doc_recon "$WORK/stale_doc.md" "$WORK/cols.tsv" "$WORK/r7.txt" >/dev/null; grep -c . "$WORK/r7.txt" || true)"; R7N="${R7N:-0}"
R7D="$(damaged_cells "$DOC" "$WORK/stale_doc.md")"; R7D="${R7D:-0}"
{ [ "$R7D" -gt 0 ] && [ "$R7N" -ge "$R7D" ]; } \
  && ok "RED: a stale hand-written coverage count (99999) is caught by the same reconciliation — all $R7D damaged cell(s) reported" \
  || no "RED FAILED: $R7D cell(s) were damaged and only $R7N reported, so section 10 would pass whatever the doc claims"

# R8: a proxy/nominal pair FLIPPED — the drift the old two-column reconciliation
# was structurally blind to, driven in BOTH directions by one swap: the row
# UNDERSTATES one column and OVERSTATES the other by the same edit, and both
# halves must be named. `proxy` and `nom` are the columns that decide whether a
# primitive's coverage is honest, so leaving them unread made the honest column
# unfalsifiable.
awk -F'|' 'BEGIN{OFS="|"} {p=$2; gsub(/ /,"",p)} p=="epistemic_quality" && NF>=8 {t=$5; $5=$6; $6=t} {print}' "$DOC" > "$WORK/flip_doc.md"
doc_recon "$WORK/flip_doc.md" "$WORK/cols.tsv" "$WORK/r8.txt" >/dev/null
R8P="$(grep -c 'proxy, artefact'   "$WORK/r8.txt" || true)"; R8P="${R8P:-0}"
R8N="$(grep -c 'nominal, artefact' "$WORK/r8.txt" || true)"; R8N="${R8N:-0}"
{ [ "$R8P" -ge 1 ] && [ "$R8N" -ge 1 ]; } \
  && ok "RED: a flipped proxy/nominal pair is caught in BOTH directions — the understated column and the overstated one are each named" \
  || no "RED FAILED: a flipped proxy/nominal pair was not caught in both directions (proxy hits $R8P, nominal hits $R8N)"

# R9: a table claiming an authority tier no bound control holds. `rank` is the
# tier this crosswalk's headline finding says is held by 0 of 71 controls, so a
# row asserting it is the exact inflation the report exists to refuse.
awk -F'|' 'BEGIN{OFS="|"} {p=$2; gsub(/ /,"",p)} p=="homeostasis" && NF>=8 {$8=" rank "} {print}' "$DOC" > "$WORK/auth_doc.md"
doc_recon "$WORK/auth_doc.md" "$WORK/cols.tsv" "$WORK/r9.txt" >/dev/null
R9="$(grep -c 'authorities' "$WORK/r9.txt" || true)"; R9="${R9:-0}"
[ "$R9" -ge 1 ] && ok "RED: a coverage row claiming 'rank' — an authority 0 of $NR controls hold — is caught" \
                || no "RED FAILED: a doc row could claim an authority tier no bound control holds"

# R10: the classes column widened past what the bindings carry.
awk -F'|' 'BEGIN{OFS="|"} {p=$2; gsub(/ /,"",p)} p=="homeostasis" && NF>=8 {$7=" A, B, C, D "} {print}' "$DOC" > "$WORK/cls_doc.md"
doc_recon "$WORK/cls_doc.md" "$WORK/cols.tsv" "$WORK/r10.txt" >/dev/null
R10="$(grep -c 'classes' "$WORK/r10.txt" || true)"; R10="${R10:-0}"
[ "$R10" -ge 1 ] && ok "RED: a coverage row widening the classes column past the bindings is caught" \
                 || no "RED FAILED: the classes column can be widened without the suite noticing"

echo "== 11. The empty primitives are named as a finding, not left to be inferred =="
# A primitive with zero bound controls is a gap in the PRODUCT, stated in the
# framework's vocabulary. It has to be legible in the report, not only derivable.
EMPTY="$(awk -F'\t' '{print $1}' "$WORK/prim.tsv" | while read -r p; do
  [ -n "$p" ] || continue
  n="$(awk -F'\t' -v k="$p" '$2==k{c++} END{print c+0}' "$WORK/bind.tsv")"
  [ "$n" -eq 0 ] && echo "$p"
done)"
NEMPTY="$(printf '%s' "$EMPTY" | grep -c . || true)"; NEMPTY="${NEMPTY:-0}"
[ "$NEMPTY" -gt 0 ] \
  && ok "$NEMPTY primitive(s) have zero bound controls — the finding exists to be reported" \
  || no "no primitive is empty, which would make section 11 vacuous — confirm that independently before trusting it"
UNNAMED=0
for p in $EMPTY; do
  grep -qF "$p" "$DOC" || { UNNAMED=$((UNNAMED+1)); echo "      | empty primitive never named in CROSSWALK.md: $p"; }
  q="$(awk -F'\t' -v k="$p" '$1==k{print $2}' "$WORK/prim.tsv")"
  [ "$q" = "unbound" ] || { UNNAMED=$((UNNAMED+1)); echo "      | $p has zero bindings but binding_quality is $q"; }
done
[ "$UNNAMED" -eq 0 ] \
  && ok "every empty primitive is marked unbound AND named in the report ($(printf '%s' "$EMPTY" | tr '\n' ' '))" \
  || no "$UNNAMED empty-primitive disclosure problem(s) — an unstated gap is how a crosswalk becomes decoration"

echo "== 12. known_limitations is load-bearing, so it may not be empty or perfunctory =="
# The floor is DERIVED, not fitted: what a primitive is MISSING must be told at
# at least the length of what it was INTENDED to be. Comparing each record
# against itself needs no chosen constant, so this states no numeric literal and
# does not become another unregistered fitted threshold — which is exactly what
# the registry suite's §21 caught here when this was first written as a
# hard-coded 120-character floor.
awk '
  /^primitive: /            { p = $0; sub(/^primitive: /, "", p); sr = 0; kl = 0; next }
  /^system_representation: /{ v = $0; sub(/^system_representation: /, "", v); sr = length(v) }
  /^known_limitations: /    { v = $0; sub(/^known_limitations: /, "", v); kl = length(v); n++ }
  /^[[:space:]]*$/          { if (p != "" && kl <= sr) print p " (" kl " chars) says less about what it misses than about what it intended (" sr ")"; p = "" }
  END                       { if (p != "" && kl <= sr) print p " (" kl ") <= (" sr ")"; print "COUNT " n+0 > "/dev/stderr" }
' "$XW" > "$WORK/kl.txt" 2> "$WORK/klcount.txt"
NKL="$(awk '/^COUNT /{print $2}' "$WORK/klcount.txt")"; NKL="${NKL:-0}"
SHORTKL="$(grep -c . "$WORK/kl.txt" || true)"; SHORTKL="${SHORTKL:-0}"
[ "$NKL" -eq 17 ] && ok "all 17 primitives carry a known_limitations field" \
                  || no "$NKL known_limitations field(s) found, expected 17"
[ "$SHORTKL" -eq 0 ] \
  && ok "every known_limitations says more about what is missed than the record says about what was intended" \
  || { no "$SHORTKL known_limitations field(s) are perfunctory — the field that carries the honesty is the field being skipped"; head -3 "$WORK/kl.txt" | sed 's/^/      | /'; }

echo "== 13. This suite is chained, and is not vacuous about itself =="
grep -qF 'chain_suite "tests/neurocosmology_crosswalk_tests.sh"' "$SRC/tests/build_os_tests.sh" \
  && ok "this suite is chained from tests/build_os_tests.sh (not discoverable-only)" \
  || no "this suite is present but never chained from tests/build_os_tests.sh"
# A DERIVED floor, not a fitted one: the suite must run more assertions than the
# framework has primitives. It scales with the artefact instead of freezing a
# snapshot of the day it was written, and deliberately states no numeric literal,
# so it does not join the tests.nonvacuity_minimums family it would otherwise
# have to be registered into. It catches wholesale collapse, not slow erosion.
[ "$PASS" -gt "$NP" ] && ok "this suite ran $PASS assertions, more than the $NP primitives it classifies" \
                      || no "this suite ran only $PASS assertions against $NP primitives"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
