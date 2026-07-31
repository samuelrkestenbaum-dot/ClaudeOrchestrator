#!/usr/bin/env bash
# Build OS — the evidence-policy matrix: class x empirical_status -> licensed authority.
#
# THE GAP THIS CLOSES. build-os/registry/README.md §3 carries a licence table
# that is ONE-DIMENSIONAL: class -> licensed authority (A->gate, B->rank,
# C->advise, D->observe, R->observe). Evidence is not an axis in it. So a
# control's `empirical_status` — whether anybody ever established that the check
# WORKS — licenses nothing and forbids nothing, and a control that was MEASURED
# AND FOUND NOT TO DISCRIMINATE can stop a build while the registry's own rules
# raise no objection. That is not hypothetical: the census records `refuted`
# controls, and one of them gates.
#
# WHAT THIS ADDS, AND WHAT IT LEAVES ALONE. The class axis is SETTLED and is
# copied here unchanged; `tests/evidence_policy_tests.sh` §4 reads it back out of
# README §3 and refuses any disagreement, so this file cannot quietly restate the
# old table differently and call the difference policy. What is new is the second
# axis and the rule for composing the two.
#
#   THE COMPOSITION RULE:  licensed = MIN(class-licensed, evidence-licensed)
#   over the registry's own authority ladder, none < observe < advise < rank <
#   gate. A control may do what BOTH its class and its evidence allow, and no
#   more. The minimum, and not an average or a product, because these are two
#   independent NECESSARY conditions: being the right KIND of thing to gate does
#   not make a broken check work, and a working check does not make a chosen
#   threshold an invariant. Either one failing is disqualifying on its own, and
#   the minimum is what "either one failing is disqualifying" looks like
#   arithmetically.
#
# THE EVIDENCE AXIS, EACH LEVEL WITH ITS REASON:
#
#   calibrated      -> gate     thresholds derived from a measured distribution.
#   field_observed  -> gate     it has fired on a real defect nobody planted.
#   red_driven      -> gate     it has been shown to fire on a synthetic defect.
#                               THIS IS DELIBERATELY NOT CAPPED BELOW `gate`,
#                               even though README §2 rightly says a red drive
#                               "is weaker than it looks". A red drive
#                               establishes the one property a gate structurally
#                               needs — THAT THE CHECK CAN FIRE. What it does not
#                               establish is the converse, that it stays quiet
#                               when it should. For a CLASS C control that is a
#                               question about a CHOSEN THRESHOLD, and chosen
#                               thresholds are exactly what the class axis exists
#                               to charge — so capping here too would charge the
#                               same weakness twice.
#                               THE KNOWN LIMIT OF THAT ARGUMENT, STATED RATHER
#                               THAN IMPLIED AWAY: it holds at Class C and it
#                               does NOT hold at Classes A and B, which carry no
#                               fitted threshold for the class axis to charge. A
#                               red-driven Class-A check that only ever detects
#                               the one violation shape its own author planted is
#                               charged by NEITHER axis: the class axis has no
#                               chosen threshold to object to, and the evidence
#                               axis takes the red drive at face value. So at A
#                               and B this rule rests on the CONSEQUENTIAL half
#                               below and not on the principled half above, and
#                               the consequential half is doing the load-bearing
#                               work precisely where the principled half is
#                               weakest. That gap is real. It is not a reason to
#                               change the rule here, because closing it needs
#                               evidence that a check STAYS QUIET when it should
#                               — something nothing in this repository measures,
#                               and something this file could not verify anyway
#                               (see WHAT IT DOES NOT DO, below).
#                               THE CONSEQUENTIAL HALF, with the number derived
#                               rather than remembered: capping `red_driven` at
#                               `advise` would put 66 of 78 controls out of
#                               licence in a single edit — 47 of them NEWLY, on
#                               top of the 19 already named — and a matrix that
#                               flags nearly everything discriminates nothing.
#   unvalidated     -> advise   NOTHING has established that it discriminates.
#                               THE EXPENSIVE RULE. `advise` and not `rank`,
#                               because `rank` lets a control order work or
#                               select between options with NO HUMAN IN THE LOOP:
#                               an unverified signal silently choosing what
#                               happens next differs from an unverified signal
#                               stopping a build only in how loudly it fails.
#                               `advise` is the highest rung that keeps a person
#                               between the unverified number and the
#                               consequence, which is exactly the guarantee
#                               "nobody has checked this" requires. This cap is
#                               what puts every gate-on-unvalidated control out
#                               of licence, class A included, and that count is
#                               the finding — not a reason to soften the rule.
#   refuted         -> observe  THE SHARP RULE. It was measured and found NOT to
#                               discriminate. A control empirically shown not to
#                               discriminate cannot license a stop, and CLASS
#                               CANNOT RESCUE IT, because class is a claim about
#                               the KIND of thing being checked while evidence is
#                               a claim about whether the check WORKS. A hard
#                               invariant whose test does not detect violations
#                               is not a hard invariant with good paperwork; it
#                               is an unchecked invariant. `observe` and not
#                               `advise`: presenting a signal KNOWN not to
#                               discriminate to a decision-maker who cannot see
#                               that it is dead is worse than recording it and
#                               letting nothing read it. `observe` keeps the
#                               measurement — so a later re-validation has
#                               history to work from — without letting anything
#                               act on it.
#
# COMMA-COMPOSITES RESOLVE BY MINIMUM. `empirical_status` may carry more than one
# value (`red_driven,refuted`). The resolved cap is the MINIMUM over the
# components — the weakest component governs. That is conservative in general,
# and in the one case that matters it gives the honest answer without needing a
# timestamp the registry does not carry: `refuted` dominates a `red_driven` that
# preceded it, because a later refutation SUPERSEDES an earlier red drive. The
# reverse reading — "it red-drove once, so it is fine" — is how a measurement
# that found nothing gets outvoted by the measurement it corrected.
#
# THERE IS NO COMPOSITE EVIDENCE SCORE, AND THERE WILL NOT BE ONE. The obvious
# shape is `q = w1*class + w2*evidence`, one number, one threshold. It is refused
# here for the two reasons bandwidth-check.sh refuses a composite load score one
# layer along, and both are load-bearing. First, THE WEIGHTS ARE UNJUSTIFIABLE:
# nothing in this repository has measured how being the wrong class trades off
# against having no evidence, and a weight nobody can derive is a constant nobody
# can defend. Second, and worse, ONE NUMBER HIDES WHICH AXIS IS SATURATED: an
# operator told "control quality 0.4" learns nothing they can act on, whereas
# "class licenses advise, evidence licenses advise, it exercises gate" names two
# separate things to fix. So the two axes are reported SEPARATELY on every
# finding, and every finding names the axis that binds it.
#
# WHY THIS IS A NEW FILE AND NOT AN EXTENSION OF scan-controls.sh. Judged, not
# assumed. `scan-controls.sh` is registered as `registry.reconciliation`, class A,
# authority `gate`: its entire exit-code contract is "refuse on violation". This
# matrix must NOT refuse. Putting a non-refusing policy inside a file whose every
# other finding refuses would mean either (a) the matrix gates by accident — the
# one thing it must not do — or (b) a second, quieter exit path threaded through
# a gate, which is precisely how a chosen policy leaks into an invariant's
# authority. Keeping the matrix out of a file whose every finding refuses is what
# makes `advise` provably `advise` rather than `advise` until someone edits a
# branch. It also keeps the two axes structurally separate: §5 of the scanner
# enforces the class axis and this file enforces nothing about any control's
# licence, which is the difference the design is claiming.
#
# NOT "ONE FILE, ONE AUTHORITY CONTRACT" — THIS FILE IS NOT THAT, AND SAYING SO
# WOULD OVERCLAIM. It carries two exit paths: the advisory `check` path that
# exits 0 whatever it finds, and `evidence.derivation_nonvacuity`, a Class-A gate
# that exits 2. What makes that safe is not that the file has one contract but
# that the two govern DIFFERENT OBJECTS — the gate governs the DERIVATION (can
# this census be read at all), never any control's licence — and that the gate
# suppresses the advisory VERDICT rather than being threaded through it. (Per-
# control lines already streamed to stdout are not retracted; what the refusal
# withholds is the summary, and exit 2 is what no consumer can misread.) That
# separation is what scan-controls.sh could not have offered.
#
# THIS TOOL ADVISES. `check` EXITS 0 WHATEVER IT FINDS. Three reasons, all of
# which belong in the registry entry as well:
#   1. The matrix is CHOSEN POLICY, not a definition. Where `unvalidated` caps is
#      a judgement, defensible and still a judgement. A matrix that GATED on the
#      rule "chosen thresholds may not gate" would be self-refuting in exactly
#      the way `bandwidth.active_packet_singleton` was found to be.
#   2. Gating would demote controls IMMEDIATELY AND AUTOMATICALLY — the system
#      re-authorising itself with no operator in the loop. The authority envelope
#      that would make re-authorisation a legitimate act does not exist yet.
#   3. Precedent: new Class-C controls ship at `advise`; promotion to `gate` is a
#      separate governance action taken by the operator.
#
# THE ONE THING IT DOES REFUSE is a derivation it cannot trust: an absent
# registry, a registry that parses to zero controls, or a stanza it cannot
# classify. A matrix that silently skipped what it could not read would report a
# clean licence for a census it did not read — the blinded-scanner failure that
# scan-controls.sh refuses in three separate places. That refusal is a hard
# invariant over the derivation, it is registered separately, and it is the only
# authority in this file above `advise`.
#
# THE OUT-OF-LICENCE SET IS DERIVED ON EVERY RUN, from the registry, and is
# stored nowhere. No control id appears in this file. A hand-maintained list
# decays exactly the way `PACKET_FILES` and MISMATCHES.md §10's file/lines table
# did — both found stale, both by the same mechanism: a list somebody has to
# remember to update.
#
# WHAT IT DOES NOT DO. It does not re-authorise anything, it writes nothing
# anywhere, and it takes `empirical_status` AT THE AUTHOR'S WORD. It observes
# DECLARED evidence, not evidence: a control that says `red_driven` is believed.
# Nothing here re-runs a red drive, checks that a refutation was ever recorded,
# or notices a control whose evidence went stale. That gap is real and is named
# in the registry entry rather than implied away.
#
# Local only. Reads files and prints. Writes nothing, anywhere.
#
# Usage:
#   evidence-policy.sh matrix
#   evidence-policy.sh check  [--repo DIR] [--registry FILE]
# Exit: 0 the derivation ran (WHATEVER it found — this advises);
#       2 the invocation is malformed, or the census could not be trusted.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"
REGISTRY=""

refuse(){ printf 'evidence-policy: REFUSED — %s\n' "$*" >&2; exit 2; }

# --- the two axes, each defined exactly once ----------------------------------
# THE CLASS AXIS IS A COPY of README §3's licence table, which is settled. It is
# reconciled against the README by tests/evidence_policy_tests.sh §4, so the two
# cannot drift.
CLASS_AXIS="A:gate B:rank C:advise D:observe R:observe"
# THE EVIDENCE AXIS is the new one. Its levels are exactly the five
# `empirical_status` values the ontology declares and the live census carries;
# the suite reconciles them against scan-controls.sh's EMP_STATUSES and against
# the tokens occurring in the registry, so a level fitted to a hypothetical
# census cannot be added here quietly.
EVIDENCE_AXIS="unvalidated:advise red_driven:gate field_observed:gate calibrated:gate refuted:observe"
LADDER="none observe advise rank gate"

rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; *) echo -1 ;; esac; }
name_of(){ case "$1" in 0) echo none ;; 1) echo observe ;; 2) echo advise ;; 3) echo rank ;; 4) echo gate ;; *) echo '?' ;; esac; }
axis_cap(){ # <axis-string> <key> -> licensed authority, or the empty string
  local a
  for a in $1; do case "$a" in "$2":*) printf '%s' "${a#*:}"; return 0 ;; esac; done
  return 1
}

CMD="${1:-}"
[ $# -gt 0 ] && shift
case "$CMD" in
  matrix|check) ;;
  -h|--help|help) sed -n '2,185p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") refuse "no command — expected one of: matrix, check" ;;
  *)  refuse "unknown command \"$CMD\" — expected one of: matrix, check" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)     [ $# -ge 2 ] || refuse "--repo needs a value";     REPO="$2"; shift 2 ;;
    --registry) [ $# -ge 2 ] || refuse "--registry needs a value"; REGISTRY="$2"; shift 2 ;;
    -h|--help)  sed -n '2,185p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done

# --------------------------------------------------------------- matrix ------
if [ "$CMD" = "matrix" ]; then
  printf 'ladder: %s\n' "$LADDER"
  printf 'axis: class    %s\n' "$CLASS_AXIS"
  printf 'axis: evidence %s\n' "$EVIDENCE_AXIS"
  printf 'composition: licensed = MIN(class-licensed, evidence-licensed) over the ladder above — a control may do what BOTH axes allow, and no more\n'
  printf 'composite-status: a comma-separated empirical_status resolves to the MINIMUM over its components, so refuted dominates a red_driven that preceded it\n'
  printf 'no-composite: the two axes are reported separately and are never blended into one number; every finding names the axis that binds it\n'
  printf 'sharp-rule: refuted may not gate at ANY class — class is a claim about the KIND of thing checked, evidence a claim about whether the check WORKS\n'
  printf 'authority: this matrix ADVISES. check exits 0 whatever it finds. Demoting a control is a governance action for the operator, not something this performs.\n'
  for c in A B C D R; do
    ccap="$(axis_cap "$CLASS_AXIS" "$c")"
    for e in unvalidated red_driven field_observed calibrated refuted; do
      ecap="$(axis_cap "$EVIDENCE_AXIS" "$e")"
      cr="$(rank_of "$ccap")"; er="$(rank_of "$ecap")"
      lr="$cr"; [ "$er" -lt "$cr" ] && lr="$er"
      printf 'grid: class=%s evidence=%-15s class-licensed=%-7s evidence-licensed=%-7s licensed=%s\n' \
        "$c" "$e" "$ccap" "$ecap" "$(name_of "$lr")"
    done
  done
  exit 0
fi

# ---------------------------------------------------------------- check ------
[ -d "$REPO" ] || refuse "--repo is not a directory: $REPO"
[ -n "$REGISTRY" ] || REGISTRY="$REPO/build-os/registry/control_registry.txt"
[ -f "$REGISTRY" ] || refuse "no registry at $REGISTRY. There is nothing to derive from, and an absent census is not a clean one."

TMPOUT="$(mktemp)"
trap 'rm -f "$TMPOUT"' EXIT

# The derivation, in one pass. Stanzas are `key: value` lines separated by blank
# lines; `#` at column 0 is a comment. Only four fields are read, and a stanza
# missing any of them — or carrying an evidence token this matrix has no cap for
# — is UNREADABLE. Unreadable stanzas are collected and REFUSED below rather than
# skipped: a matrix that quietly drops what it could not classify reports a clean
# licence for a census it did not read.
awk -v class_axis="$CLASS_AXIS" -v evidence_axis="$EVIDENCE_AXIS" '
function rank(a){ if(a=="none")return 0; if(a=="observe")return 1; if(a=="advise")return 2;
                  if(a=="rank")return 3; if(a=="gate")return 4; return -1 }
function nameof(r){ return r==0?"none":r==1?"observe":r==2?"advise":r==3?"rank":r==4?"gate":"?" }
BEGIN{
  n=split(class_axis,ca," ");    for(i=1;i<=n;i++){ split(ca[i],p,":"); CCAP[p[1]]=p[2] }
  n=split(evidence_axis,ea," "); for(i=1;i<=n;i++){ split(ea[i],p,":"); ECAP[p[1]]=p[2] }
  nread=0; nout=0; nclass=0; nevid=0; nboth=0; nrefgate=0; nbad=0
}
function flush(   i,k,cr,er,lr,ar,ax,tok,ntok,t,bad,why){
  if(cur=="") return
  bad=""
  if(!(cur in CLS))  bad = bad (bad?"; ":"") "no class"
  if(!(cur in EMP))  bad = bad (bad?"; ":"") "no empirical_status"
  if(!(cur in AUTH)) bad = bad (bad?"; ":"") "no runtime_authority"
  if(bad=="" && !(CLS[cur] in CCAP)) bad = "class \"" CLS[cur] "\" has no row on the class axis"
  if(bad=="" && rank(AUTH[cur])<0)   bad = "runtime_authority \"" AUTH[cur] "\" is not on the authority ladder"
  er=99; why=""
  if(bad==""){
    ntok=split(EMP[cur],tok,",")
    for(i=1;i<=ntok;i++){
      t=tok[i]; gsub(/^[ \t]+|[ \t]+$/,"",t)
      if(t=="") continue
      if(!(t in ECAP)){ bad = "empirical_status token \"" t "\" has no cap on the evidence axis"; break }
      if(rank(ECAP[t])<er){ er=rank(ECAP[t]); why=t }
    }
    if(bad=="" && er==99) bad="empirical_status is empty"
  }
  if(bad!=""){
    nbad++; BADID[nbad]=cur; BADWHY[nbad]=bad; cur=""; return
  }
  nread++
  cr=rank(CCAP[CLS[cur]]); ar=rank(AUTH[cur])
  lr = (er<cr) ? er : cr
  if(ar>lr){
    nout++
    if(ar>cr && ar>er){ ax="both";     nboth++ }
    else if(ar>cr)    { ax="class";    nclass++ }
    else              { ax="evidence"; nevid++ }
    if(ar==4 && index(EMP[cur],"refuted")>0) nrefgate++
    printf "evidence: OUT-OF-LICENCE %s class=%s empirical_status=%s class-licensed=%s evidence-licensed=%s licensed=%s exercises=%s axis=%s binding-evidence=%s\n",
      cur, CLS[cur], EMP[cur], nameof(cr), nameof(er), nameof(lr), AUTH[cur], ax, why
  }
  cur=""
}
/^#/ { next }
/^control: / { flush(); cur=substr($0,10); next }
/^class: /              { if(cur!="") CLS[cur]=substr($0,8);              next }
/^empirical_status: /   { if(cur!="") EMP[cur]=substr($0,19);             next }
/^runtime_authority: /  { if(cur!="") AUTH[cur]=substr($0,20);            next }
END{
  flush()
  for(i=1;i<=nbad;i++) printf "evidence: UNREADABLE %s — %s\n", BADID[i], BADWHY[i]
  printf "COUNTS\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", nread, nout, nclass, nevid, nboth, nrefgate, nbad
}' "$REGISTRY" > "$TMPOUT"

COUNTS="$(grep '^COUNTS' "$TMPOUT" | tail -1)"
NREAD="$(printf '%s' "$COUNTS" | cut -f2)"
NOUT="$(printf  '%s' "$COUNTS" | cut -f3)"
NCLASS="$(printf '%s' "$COUNTS" | cut -f4)"
NEVID="$(printf '%s' "$COUNTS" | cut -f5)"
NBOTH="$(printf '%s' "$COUNTS" | cut -f6)"
NREFG="$(printf '%s' "$COUNTS" | cut -f7)"
NBAD="$(printf  '%s' "$COUNTS" | cut -f8)"

grep -v '^COUNTS' "$TMPOUT" || true

# --- the derivation's own hard invariants, and the only exits above 0 ---------
# VACUITY. A census that parses to zero controls is not a clean one; it is what a
# registry looks like the day after someone renames a field. Reporting "0 out of
# licence" for it would be a false all-clear with a green tick on it.
if [ "${NREAD:-0}" -eq 0 ] && [ "${NBAD:-0}" -eq 0 ]; then
  refuse "$REGISTRY parses to 0 controls. An empty census is not a licensed one — a matrix derived from no controls reports a clean licence for a system nobody read, so this refuses instead of printing zero."
fi
# UNREADABLE STANZAS. Named, never skipped, and never defaulted to permissive: an
# evidence level this matrix has no cap for must not license everything by
# falling through.
if [ "${NBAD:-0}" -gt 0 ]; then
  refuse "$NBAD stanza(s) in $REGISTRY could not be classified by this matrix (named above). Skipping them would report a licence for controls nobody read, and defaulting an unrecognised evidence level to permissive is how a matrix stops discriminating."
fi

printf 'evidence-policy: %s of %s out of licence — class axis binds %s, evidence axis binds %s, both axes bind %s (two axes, reported separately and never blended)\n' \
  "$NOUT" "$NREAD" "$NCLASS" "$NEVID" "$NBOTH"
printf 'evidence-policy: %s finding(s) are visible ONLY to the evidence axis — in licence under the class table in README §3, out of licence once evidence is an axis\n' \
  "$NEVID"
printf 'evidence-policy: %s control(s) gate on evidence containing `refuted` — measured and found not to discriminate, and no class licenses that\n' \
  "$NREFG"
printf 'evidence-policy: ADVISORY. This is a chosen policy, not a definition: it reports and exits 0. Re-authorising or demoting any control named above is a governance action for the operator, and nothing here performs one.\n'
exit 0
