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
#   THE COMPOSITION RULE:  licensed = MIN(L_class, L_evidence, L_deployment)
#   over the registry's own authority ladder, none < observe < advise < rank <
#   gate < execute. A control may do what ALL THREE allow, and no more. The
#   minimum, and
#   not an average or a product, because these are independent NECESSARY
#   conditions: being the right KIND of thing to gate does not make a broken
#   check work, a working check does not make a chosen threshold an invariant,
#   and neither of them makes it safe for the output to act with no person in
#   the loop. Any one failing is disqualifying on its own, and the minimum is
#   what "any one failing is disqualifying" looks like arithmetically.
#
# THE THIRD TERM ARRIVED LATER, AND IT IS SOURCED FROM ELSEWHERE. `L_deployment`
# comes from the authority envelope store — `build-os/registry/authority_envelopes.txt`,
# validated and projected by `build-os/tools/authority-envelope.sh modes`. This
# file does NOT parse that store: one schema, one parser, reconciled by the
# suites rather than duplicated here, which is the same device that keeps the
# class axis from drifting away from README §3.
#
#   THE DEFAULT IS `autonomous`, i.e. NO ADDITIONAL CAP, and the defence matters
#   more than the value. Every control in the census predates this axis and
#   declares no deployment mode. `autonomous` is the ONLY default that leaves the
#   existing finding set exactly where the operator put it; anything else demotes
#   the whole census in a single commit, with no operator in the loop, which is
#   precisely the self-re-authorisation the envelope exists to prevent. The store
#   ships with zero grants, so THE THIRD TERM IS INERT ON TODAY'S CENSUS BY
#   CONSTRUCTION — which is the property, not an accident of it.
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
#                               `advise` would put 68 of 81 controls out of
#                               licence in a single edit — 49 of them NEWLY, on
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
#                               letting nothing ACT on it. `observe` keeps the
#                               measurement — so a later re-validation has
#                               history to work from — without letting anything
#                               act on it.
#
# `observe` IS DEFINED BY CONSEQUENCE, NOT BY CONSUMPTION, AND THIS CAP IS WHY.
# The rung means: the output MAY be recorded and consumed FOR VISIBILITY, and it
# causes NO OPERATIONAL CONSEQUENCE. It was formerly defined by NON-CONSUMPTION
# — measuring and recording, with nothing reading the result — which made this
# cap UNREACHABLE, because `none` was also
# defined by non-consumption, so the ladder had no rung meaning "it is read, but
# it may cause nothing", which is exactly where a refuted-but-wired-in control
# belongs. The cap was foreclosed for 67 of 81 controls and 0 sat there. The cap
# VALUE did not move; what moved is that it is now a legal destination.
#
# THE DEPLOYMENT AXIS, defined in authority-envelope.sh and used here. It answers
# the question neither of the two above asks: WHAT HAPPENS TO THE OUTPUT?
#
#   shadow             -> observe  its output may be watched; it has NO
#                                  OPERATIONAL CONSEQUENCE.
#   human_confirmed    -> advise   a person sits between signal and consequence.
#   bounded_autonomous -> rank     acts unattended, inside declared bounds.
#   autonomous         -> execute  no additional cap. THE DEFAULT.
#
# `autonomous` CAPS AT THE TOP RUNG, WHICHEVER RUNG THAT IS. Its cap has only
# ever been justified by POSITION — "no additional cap" — never by the token
# `gate`. When `execute` was added above `gate`, holding this mode at `gate`
# would have turned a documented NON-cap into a real cap on every control that
# predates this axis, demoting the whole census with no operator in the loop,
# and would have made `execute` unreachable on this axis for everyone — the same
# unreachable-rung defect that forced the ladder correction. It grants nobody
# `execute`, because the composition is a MINIMUM and the CLASS axis still caps
# Class A at `gate`. Class is where a licence decision belongs.
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
# THE S1 COLLISION, RECORDED HERE AND NOT RESOLVED. The sanctioned S1 launch
# declaration is `controlClass: heuristic_policy` / `empiricalStatus: untested` /
# `runtimeAuthority: rank` / `deploymentMode: shadow`. AS LITERALLY SPECIFIED,
# MIN() CANNOT PRODUCE `rank` FOR IT: `heuristic_policy` is Class C, README §3
# licenses Class C at `advise`, and `rank` is strictly above `advise` on the
# ladder. Two readings — (1) S1 ships carrying `authority_mismatch: declared`,
# the fifteenth, which is honest and consistent with the fourteen already
# reported; (2) `shadow` means the ranking has no consequence, so
# `runtime_authority` is measuring the wrong property for a shadow-mode control
# and the ladder conflates SIGNAL STRENGTH with WHETHER ANYTHING CONSUMES THE
# SIGNAL. BOTH ARE RECORDED. NEITHER IS ADOPTED: adopting reading 2 would
# redefine the ladder, which is a governance change and not a build decision, so
# `shadow` still caps at `observe` and S1 as declared would still be out of
# licence. The full statement lives in authority-envelope.sh's header and in
# README §3b. The operator decides.
#
# `untested` IS DECLARED PENDING AND IS NOT IMPLEMENTED. It is deliberately NOT
# on EVIDENCE_AXIS below, has no cap row, and a control carrying it is REFUSED at
# exit 2 by `evidence.derivation_nonvacuity` — an unrecognised evidence level
# must never fall through to permissive, and adding a token so that a planned
# control fits is the failure the registry exists to prevent.
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
#   evidence-policy.sh check  [--repo DIR] [--registry FILE] [--envelopes FILE]
# Exit: 0 the derivation ran (WHATEVER it found — this advises);
#       2 the invocation is malformed, or the census could not be trusted.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"
REGISTRY=""
ENVELOPES=""

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
# THE DEPLOYMENT AXIS is owned by build-os/tools/authority-envelope.sh and copied
# here the way the class axis is copied from README §3. The suites reconcile the
# two, so this cannot quietly restate the third axis differently. A control with
# no envelope takes DEPLOYMENT_DEFAULT, which caps at `execute`, the TOP rung —
# no additional cap
# — because that is the only default that changes nothing for a census written
# before this axis existed.
DEPLOYMENT_AXIS="shadow:observe human_confirmed:advise bounded_autonomous:rank autonomous:execute"
DEPLOYMENT_DEFAULT="autonomous"
LADDER="none observe advise rank gate execute"

rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; execute) echo 5 ;; *) echo -1 ;; esac; }
name_of(){ case "$1" in 0) echo none ;; 1) echo observe ;; 2) echo advise ;; 3) echo rank ;; 4) echo gate ;; 5) echo execute ;; *) echo '?' ;; esac; }
axis_cap(){ # <axis-string> <key> -> licensed authority, or the empty string
  local a
  for a in $1; do case "$a" in "$2":*) printf '%s' "${a#*:}"; return 0 ;; esac; done
  return 1
}

CMD="${1:-}"
[ $# -gt 0 ] && shift
case "$CMD" in
  matrix|check) ;;
  -h|--help|help) sed -n '2,230p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") refuse "no command — expected one of: matrix, check" ;;
  *)  refuse "unknown command \"$CMD\" — expected one of: matrix, check" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)     [ $# -ge 2 ] || refuse "--repo needs a value";     REPO="$2"; shift 2 ;;
    --registry) [ $# -ge 2 ] || refuse "--registry needs a value"; REGISTRY="$2"; shift 2 ;;
    --envelopes) [ $# -ge 2 ] || refuse "--envelopes needs a value"; ENVELOPES="$2"; shift 2 ;;
    -h|--help)  sed -n '2,230p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done

# --------------------------------------------------------------- matrix ------
if [ "$CMD" = "matrix" ]; then
  printf 'ladder: %s\n' "$LADDER"
  printf 'axis: class    %s\n' "$CLASS_AXIS"
  printf 'axis: evidence %s\n' "$EVIDENCE_AXIS"
  printf 'axis: deployment %s\n' "$DEPLOYMENT_AXIS"
  printf 'composition: licensed = MIN(L_class, L_evidence, L_deployment) over the ladder above — a control may do what ALL THREE axes allow, and no more\n'
  printf 'deployment-default: %s — a control with no authority envelope declares no deployment mode and takes NO ADDITIONAL CAP. Any other default would demote every control registered before this axis existed, with no operator in the loop.\n' "$DEPLOYMENT_DEFAULT"
  printf 'deployment-source: L_deployment comes from build-os/registry/authority_envelopes.txt via `authority-envelope.sh modes`. This file parses no envelope: one schema, one parser.\n'
  printf 'grid-note: the grid below is the class x evidence composition AT THE DEFAULT DEPLOYMENT MODE (%s), which is the mode every control in the census takes today. A grant that declares another mode lowers `licensed` further; it can never raise it.\n' "$DEPLOYMENT_DEFAULT"
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

TMPOUT="$(mktemp)"; TMPMODE="$(mktemp)"
trap 'rm -f "$TMPOUT" "$TMPMODE"' EXIT

# --- the third term, sourced and never parsed here ---------------------------
# `L_deployment` comes from the authority envelope store, projected by
# authority-envelope.sh. This file does NOT parse that schema: one schema, one
# parser, so the two cannot disagree about what a record means. The projection's
# own Class-A gate (envelope.derivation_nonvacuity) refuses an absent or
# unreadable store, and that refusal PROPAGATES — an unknown deployment mode must
# never reach this composition as "no cap", because falling through to permissive
# is exactly how a matrix stops discriminating while still printing green.
ENVTOOL="$SELF_DIR/authority-envelope.sh"
[ -n "$ENVELOPES" ] || ENVELOPES="$REPO/build-os/registry/authority_envelopes.txt"
[ -x "$ENVTOOL" ] || refuse "no authority-envelope validator at $ENVTOOL. The deployment axis is a MIN term of this composition; deriving it as \"no cap\" because the validator is missing would silently license everything the envelope store exists to bound."
if ! "$ENVTOOL" modes --store "$ENVELOPES" > "$TMPMODE" 2>"$TMPMODE.err"; then
  sed 's/^/evidence-policy: (envelope) /' "$TMPMODE.err" >&2
  rm -f "$TMPMODE.err"
  refuse "the authority envelope store at $ENVELOPES could not be read (the validator's refusal is quoted above). The deployment term of MIN(L_class, L_evidence, L_deployment) is therefore unknown, and an unknown term must never be defaulted to permissive."
fi
rm -f "$TMPMODE.err"

# The derivation, in one pass. Stanzas are `key: value` lines separated by blank
# lines; `#` at column 0 is a comment. Only four fields are read, and a stanza
# missing any of them — or carrying an evidence token this matrix has no cap for
# — is UNREADABLE. Unreadable stanzas are collected and REFUSED below rather than
# skipped: a matrix that quietly drops what it could not classify reports a clean
# licence for a census it did not read.
awk -v class_axis="$CLASS_AXIS" -v evidence_axis="$EVIDENCE_AXIS" \
    -v deployment_axis="$DEPLOYMENT_AXIS" -v deployment_default="$DEPLOYMENT_DEFAULT" \
    -v modefile="$TMPMODE" '
function rank(a){ if(a=="none")return 0; if(a=="observe")return 1; if(a=="advise")return 2;
                  if(a=="rank")return 3; if(a=="gate")return 4; if(a=="execute")return 5; return -1 }
function nameof(r){ return r==0?"none":r==1?"observe":r==2?"advise":r==3?"rank":r==4?"gate":r==5?"execute":"?" }
BEGIN{
  n=split(class_axis,ca," ");    for(i=1;i<=n;i++){ split(ca[i],p,":"); CCAP[p[1]]=p[2] }
  n=split(evidence_axis,ea," "); for(i=1;i<=n;i++){ split(ea[i],p,":"); ECAP[p[1]]=p[2] }
  n=split(deployment_axis,da," ");for(i=1;i<=n;i++){ split(da[i],p,":"); DCAP[p[1]]=p[2] }
  # The projection: control-id TAB deployment_mode, one line per live grant. It
  # is EMPTY today, which is what makes the third term inert on this census.
  while((getline ln < modefile) > 0){
    split(ln,mf,"\t"); if(mf[1]!="") MODE[mf[1]]=mf[2]
  }
  close(modefile)
  nread=0; nout=0; nclass=0; nevid=0; nboth=0; nrefgate=0; nbad=0; ndep=0
}
function flush(   i,k,cr,er,dr,lr,ar,ax,tok,ntok,t,bad,why,dm){
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
  # THE THIRD TERM. A control with no envelope declares no deployment mode and
  # takes the default, which caps at `execute`, the TOP rung — no additional cap.
  # That is the only
  # default that leaves a census written before this axis existed exactly where
  # the operator put it.
  dm = (cur in MODE) ? MODE[cur] : deployment_default
  dr = rank(DCAP[dm])
  lr = cr; if(er<lr) lr=er; if(dr<lr) lr=dr
  if(ar>lr){
    nout++
    # THE AXIS ATTRIBUTION IS A STRICT EXTENSION of the two-axis vocabulary.
    # class/evidence/both keep their exact meanings, and a deployment term can
    # only ADD to the string — so a census with no grants reports byte-identical
    # attributions to the two-axis matrix, which is the safety property.
    if(ar>cr && ar>er){ ax="both";     nboth++ }
    else if(ar>cr)    { ax="class";    nclass++ }
    else if(ar>er)    { ax="evidence"; nevid++ }
    else                ax=""
    if(ar>dr){ ndep++; ax = (ax=="") ? "deployment" : ax "+deployment" }
    if(ar==4 && index(EMP[cur],"refuted")>0) nrefgate++
    printf "evidence: OUT-OF-LICENCE %s class=%s empirical_status=%s class-licensed=%s evidence-licensed=%s licensed=%s exercises=%s axis=%s binding-evidence=%s deployment-mode=%s deployment-licensed=%s\n",
      cur, CLS[cur], EMP[cur], nameof(cr), nameof(er), nameof(lr), AUTH[cur], ax, why, dm, nameof(dr)
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
  printf "COUNTS\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", nread, nout, nclass, nevid, nboth, nrefgate, nbad, ndep
}' "$REGISTRY" > "$TMPOUT"

COUNTS="$(grep '^COUNTS' "$TMPOUT" | tail -1)"
NREAD="$(printf '%s' "$COUNTS" | cut -f2)"
NOUT="$(printf  '%s' "$COUNTS" | cut -f3)"
NCLASS="$(printf '%s' "$COUNTS" | cut -f4)"
NEVID="$(printf '%s' "$COUNTS" | cut -f5)"
NBOTH="$(printf '%s' "$COUNTS" | cut -f6)"
NREFG="$(printf '%s' "$COUNTS" | cut -f7)"
NBAD="$(printf  '%s' "$COUNTS" | cut -f8)"
NDEP="$(printf  '%s' "$COUNTS" | cut -f9)"
NGRANT="$(grep -c . "$TMPMODE" || true)"; NGRANT="${NGRANT:-0}"

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

printf 'evidence-policy: %s of %s out of licence — class axis binds %s, evidence axis binds %s, both axes bind %s (three axes, reported separately and never blended)\n' \
  "$NOUT" "$NREAD" "$NCLASS" "$NEVID" "$NBOTH"
printf 'evidence-policy: the deployment axis binds %s finding(s), from %s live authority envelope(s) in %s. A control with no envelope takes the default `%s`, which adds no cap — the only default that leaves a census written before this axis existed where the operator put it.\n' \
  "$NDEP" "$NGRANT" "$ENVELOPES" "$DEPLOYMENT_DEFAULT"
printf 'evidence-policy: %s finding(s) are visible ONLY to the evidence axis — in licence under the class table in README §3, out of licence once evidence is an axis\n' \
  "$NEVID"
printf 'evidence-policy: %s control(s) gate on evidence containing `refuted` — measured and found not to discriminate, and no class licenses that\n' \
  "$NREFG"
printf 'evidence-policy: ADVISORY. This is a chosen policy, not a definition: it reports and exits 0. Re-authorising or demoting any control named above is a governance action for the operator, and nothing here performs one.\n'
exit 0
