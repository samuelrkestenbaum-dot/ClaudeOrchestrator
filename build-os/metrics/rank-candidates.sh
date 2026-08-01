#!/usr/bin/env bash
# Build OS — S1, the shadow ranker. THE FIRST EXECUTIVE COMPONENT IN THIS TREE.
#
# Everything else in this repository prevents a bad action. This forms an
# explicit, inspectable PREFERENCE among several permissible good ones. It is
# `controlClass: heuristic_policy`, class C, `empiricalStatus: untested`,
# `deploymentMode: shadow`, `outputSemantics: ordered_candidates`, and the
# composition is L_effective = MIN(class C -> advise, untested -> observe,
# shadow -> observe) = OBSERVE. That is correct and intended. S1 OBSERVES. It
# does not gate, does not dispatch, does not self-amend, and does not claim
# optimality. Something else acts on its ordering, or nothing does.
#
# ---------------------------------------------------------------------------
# IT WRITES NOTHING, ANYWHERE, AND THAT IS THE DISPATCH GUARANTEE
# ---------------------------------------------------------------------------
# There is no append path in this file, no temporary file, and no store of its
# own. It reads two existing stores — decision_telemetry.tsv (the record of what
# was chosen) and signal_snapshots.tsv (the digest-chained evidence of what the
# signals WERE) — and prints. The ordering is immutable not because it is filed
# somewhere immutable, but because it is a pure function of a digest-chained
# input and a versioned rule: run it again and the `ranking_digest` is the same
# number, edit a historical signal and the chain refuses before anything ranks.
#
# ---------------------------------------------------------------------------
# GUARD 1 — NO LEARNED POLICY MAY OPTIMIZE THE MECHANISM GOVERNING ITS OWN
# PROMOTION
# ---------------------------------------------------------------------------
# S1 REFUSES to rank any candidate that would modify its own code, its signal
# definitions, its ranking rule, its registry entry, its own tests, or the
# machinery that could raise it above `observe`. The refusal is VISIBLE: an
# excluded candidate is printed as excluded WITH ITS REASON, never omitted.
#
# It fails CLOSED. A candidate carrying no frozen `candidate_write_surface`
# cannot be screened, and an unscreenable candidate is refused as
# `guard1_unscreenable` rather than assumed innocent. It is also deliberately
# OVER-BROAD in the safe direction: `evidence-policy.sh` and
# `authority-envelope.sh` govern every control's licence, not only S1's, and S1
# refuses all of them rather than trying to decide which edits to the promotion
# machinery would happen to benefit it.
#
# ---------------------------------------------------------------------------
# GUARD 2 — PUBLISH THE DECOMPOSITION, NOT JUST THE VALUES
# ---------------------------------------------------------------------------
# A total score is not transparency. Every ranked candidate prints, per signal,
# the frozen value, the declared direction, and the POINTS that signal
# contributed to its position — so a reader can see why A outranked B rather
# than being told that it did.
#
# ---------------------------------------------------------------------------
# AN ABSENT SIGNAL IS NEVER A ZERO, AND NEVER A GUESS
# ---------------------------------------------------------------------------
# This is the same rule record-decision.sh enforces on values, applied one level
# up to the signal SET. Three separate kinds of absence are printed by name and
# none of them scores:
#
#   MISSING          declared in the direction table below, but not frozen for
#                    this decision. Not imputed, not defaulted, not dropped.
#   UNINTERPRETED    frozen somewhere in this repository, but its DIRECTION has
#                    never been established. `declared_mismatch_proximity` is
#                    the honest case: whether proximity to a declared mismatch
#                    makes a candidate better (it fixes debt) or worse (it risks
#                    it) has never been decided, and guessing would put an
#                    invented constant inside an ordering.
#   NEVER-COLLECTED  nothing in this repository has ever measured it.
#
# A defaulted signal is the `untested`-missing-from-`EVIDENCE_AXIS` defect
# again: a token that was quietly absent from an axis and shipped a live
# over-grant inside the over-grant detector.
#
# ---------------------------------------------------------------------------
# RESOLVABILITY IS NOT IDENTITY
# ---------------------------------------------------------------------------
# The recurring failure this project has named. A frozen snapshot that PARSES is
# not a frozen snapshot that BELONGS to the decision it claims. So every
# snapshot consulted must carry BOTH the requested `decision_id` AND a
# `candidate_id` the decision itself names, and a snapshot that satisfies the
# first and not the second is a loud refusal rather than a row nobody reads.
#
# ---------------------------------------------------------------------------
# THE RULE, AND WHY THE WEIGHTS ARE EQUAL
# ---------------------------------------------------------------------------
# `ranking_rule: s1-v1`. For each ranked signal a candidate scores one point per
# OTHER rankable candidate it strictly beats on that signal; the total is the
# unweighted sum. Ties score equally and are REPORTED as ties rather than broken
# by sort order. Weights are all 1 because nothing has been measured that would
# justify anything else, and an invented weight is an unregistered constant
# sitting inside a decision — which is precisely the shape of defect this tree
# spends its suites catching. When outcome telemetry exists, weights become a
# thing that can be learned; today they are a declared constant and are labelled
# as one.
#
# THIS RULE IS NOT CLAIMED TO BE GOOD. `rank_of_selected` is printed so that it
# can be WRONG. Without that number S1 could emit orderings forever and never be
# falsified by anything.
#
# Usage:
#   rank-candidates.sh rank --decision-id ID [--store F] [--snapshots F]
#   rank-candidates.sh rule
# Exit: 0 an ordering was produced, 2 refused.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORE="$SELF_DIR/decision_telemetry.tsv"
SNAPS="$SELF_DIR/signal_snapshots.tsv"
RECDEC="$SELF_DIR/record-decision.sh"
TAB=$'\t'

die(){ printf 's1: REFUSED — %s\n' "$*" >&2; exit 2; }

RULE_VERSION="s1-v1"

# --- the direction table. A signal with no row here is NOT ranked. ------------
SIGNAL_DIRECTION="
dependency_unlock_count:higher_is_better
residue_items_closed:higher_is_better
residue_ruling_satisfied:higher_is_better
canonical_fixture_representable:higher_is_better
discriminating_negative_fixture_representable:higher_is_better
census_growth_controls:lower_is_better
closed_field_list_widening_required:lower_is_better
unclassified_exit2_paths_introduced:lower_is_better
"
# Frozen in this repository, direction never established. Named, never guessed.
SIGNALS_UNINTERPRETED="licence_state declared_mismatch_proximity"
# Never measured anywhere in this repository. Named, never imputed.
SIGNALS_NEVER_COLLECTED="recurrence_count cost_minutes estimated_energy counterfactual_regret outcome_quality human_attention_minutes"
# The screening input for guard 1. Not a ranking signal.
SURFACE_SIGNAL="candidate_write_surface"

# --- guard 1's protected surface ---------------------------------------------
# A bare path means the whole file. `path#object` means one named object inside
# a file S1 does not own outright.
PROTECTED_SURFACE="
build-os/metrics/rank-candidates.sh
build-os/registry/control_registry.txt#ranker.s1_shadow_ordering
build-os/registry/neurocosmology_crosswalk.txt#ranker.s1_shadow_ordering
tests/mutator_registry_tests.sh#13
build-os/tools/evidence-policy.sh
build-os/tools/authority-envelope.sh
"

HASHER=()
if _h="$(command -v sha256sum 2>/dev/null)"; then HASHER=("${_h}")
elif _h="$(command -v shasum 2>/dev/null)"; then HASHER=("${_h}" -a 256)
fi
digest_of(){
  [ ${#HASHER[@]} -eq 0 ] && die "neither sha256sum nor shasum is available, so the ordering cannot carry a digest binding it to its inputs."
  local h; h="$("${HASHER[@]}")"; printf '%s' "${h%% *}"
}

direction_of(){ printf '%s\n' "$SIGNAL_DIRECTION" | awk -F: -v s="$1" '$1==s{print $2; exit}'; }
in_words(){ local v="$1" w; for w in $2; do [ "$v" = "$w" ] && return 0; done; return 1; }

# Two surface tokens touch iff they are equal, or one names a whole file and the
# other names an object inside it.
touches(){
  local a="$1" b="$2"
  [ "$a" = "$b" ] && return 0
  case "$b" in "$a"'#'*) return 0 ;; esac
  case "$a" in "$b"'#'*) return 0 ;; esac
  return 1
}

# ------------------------------------------------------------------- args ----
CMD="${1:-}"
[ $# -gt 0 ] && shift
DEC=""
while [ $# -gt 0 ]; do
  case "$1" in
    --decision-id) [ $# -ge 2 ] || die "--decision-id needs a value"; DEC="$2"; shift 2 ;;
    --store)       [ $# -ge 2 ] || die "--store needs a value";       STORE="$2"; shift 2 ;;
    --snapshots)   [ $# -ge 2 ] || die "--snapshots needs a value";   SNAPS="$2"; shift 2 ;;
    -h|--help)     sed -n '2,100p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) die "unexpected argument \"$1\"" ;;
  esac
done

print_rule(){
  printf 'ranking_rule: %s\n' "$RULE_VERSION"
  printf 'weighting: every ranked signal carries weight 1. Nothing has been measured that would justify anything else, and an invented weight is an unregistered constant inside a decision.\n'
  printf 'scoring: one point per OTHER rankable candidate this candidate strictly beats on that signal. Ties score equally and are reported as ties.\n'
  printf 'authority: observe. S1 emits an ordering. It selects nothing, dispatches nothing, and writes nothing.\n'
  local row
  for row in $SIGNAL_DIRECTION; do
    printf 'ranked_signal: %s direction=%s weight=1\n' "${row%%:*}" "${row##*:}"
  done
  local p
  for p in $PROTECTED_SURFACE; do printf 'protected_object: %s\n' "$p"; done
}

case "$CMD" in
  rule) print_rule; exit 0 ;;
  rank) [ -n "$DEC" ] || die "rank needs --decision-id" ;;
  "")   die "no command — expected \`rank\` or \`rule\`" ;;
  *)    die "unknown command \"$CMD\"" ;;
esac

[ -f "$STORE" ] || die "no telemetry store at $STORE"
[ -f "$SNAPS" ] || die "no snapshot store at $SNAPS"

# --- the chain is the precondition, not a formality --------------------------
# An ordering computed over a store whose chain does not verify is an ordering
# over numbers that may not be the numbers the decision was taken on.
CHAINOUT="$("$RECDEC" snapshot-verify --snapshots "$SNAPS" 2>&1)" \
  || die "the snapshot chain at $SNAPS does not verify, so nothing here is evidence about the decision that was made. record-decision.sh says: $(printf '%s' "$CHAINOUT" | head -2 | tr '\n' ' ')"
CHAIN_HEAD="$(awk -F'\t' '!/^#/ && $1!="snapshot_id" && NF>1 {d=$NF} END{print d}' "$SNAPS")"

CAND_RAW="$("$RECDEC" get "$DEC" candidate_ids --store "$STORE" 2>/dev/null)" \
  || die "no decision \"$DEC\" in $STORE. An ordering over a candidate set nobody recorded is satisfiable by anything."
SELECTED="$("$RECDEC" get "$DEC" selected_candidate_id --store "$STORE" 2>/dev/null)"
SELECTOR="$("$RECDEC" get "$DEC" selector --store "$STORE" 2>/dev/null)"
[ "$CAND_RAW" = "unknown" ] && die "$DEC records \`unknown\` for candidate_ids. There is no candidate set to order."
CANDS="$(printf '%s\n' "$CAND_RAW" | tr ';' '\n' | grep -c . || true)"
[ "${CANDS:-0}" -gt 0 ] || die "$DEC names no candidates."
CAND_LIST="$(printf '%s\n' "$CAND_RAW" | tr ';' ' ')"

# --- read the frozen snapshots, and BIND THEM BY IDENTITY --------------------
declare -A V=() HAS=()
SIGNALS_SEEN=""
ORPHANS=""
NSNAP=0
while IFS="$TAB" read -r sc sn sv; do
  [ -n "$sc" ] || continue
  NSNAP=$((NSNAP+1))
  if ! in_words "$sc" "$CAND_LIST"; then
    in_words "$sc" "$ORPHANS" || ORPHANS="$ORPHANS $sc"
    continue
  fi
  V["$sc|$sn"]="$sv"; HAS["$sc|$sn"]=1
  in_words "$sn" "$SIGNALS_SEEN" || SIGNALS_SEEN="$SIGNALS_SEEN $sn"
done < <(awk -F'\t' -v d="$DEC" '!/^#/ && $1!="snapshot_id" && NF>=12 && $2==d {print $5"\t"$6"\t"$7}' "$SNAPS")

[ "$NSNAP" -gt 0 ] || die "$DEC has zero frozen signal snapshots. A ranking with no evidence under it is a preference with no reason, and this tool will not produce one."
[ -z "$ORPHANS" ] || die "snapshot(s) claim decision $DEC but name candidate(s) the decision does not:$ORPHANS. Each row parses, each row is correctly chained, and each row belongs to a decision that never had that candidate — RESOLVABILITY IS NOT IDENTITY."

# --- guard 1 -----------------------------------------------------------------
RANKABLE=""; EXCLUDED_LINES=""
for c in $CAND_LIST; do
  surf="${V["$c|$SURFACE_SIGNAL"]:-}"
  if [ -z "$surf" ]; then
    EXCLUDED_LINES="${EXCLUDED_LINES}excluded $c reason=guard1_unscreenable detail=no frozen \`$SURFACE_SIGNAL\` for this candidate, so S1 cannot establish that ranking it would not be ranking its own promotion. It fails closed: unscreenable is refused, not assumed innocent."$'\n'
    continue
  fi
  hit=""
  for tok in $(printf '%s' "$surf" | tr ';' ' '); do
    for p in $PROTECTED_SURFACE; do
      touches "$tok" "$p" && { hit="$tok -> $p"; break 2; }
    done
  done
  if [ -n "$hit" ]; then
    EXCLUDED_LINES="${EXCLUDED_LINES}excluded $c reason=self_amendment detail=its write surface reaches a protected object ($hit). No learned policy may optimize the mechanism governing its own promotion."$'\n'
  else
    RANKABLE="$RANKABLE $c"
  fi
done

# --- which signals are ranked, and which absences are named ------------------
SIG_RANKED=""
for row in $SIGNAL_DIRECTION; do
  s="${row%%:*}"
  in_words "$s" "$SIGNALS_SEEN" && SIG_RANKED="$SIG_RANKED $s"
done
SIG_DYNAMIC_UNINTERP=""
for s in $SIGNALS_SEEN; do
  [ "$s" = "$SURFACE_SIGNAL" ] && continue
  in_words "$s" "$SIG_RANKED" && continue
  in_words "$s" "$SIGNALS_UNINTERPRETED" && continue
  SIG_DYNAMIC_UNINTERP="$SIG_DYNAMIC_UNINTERP $s"
done

# --- the points ---------------------------------------------------------------
declare -A PTS=() TOTAL=() NPRESENT=()
NSIGR="$(printf '%s\n' $SIG_RANKED | grep -c . || true)"
for c in $RANKABLE; do TOTAL["$c"]=0; NPRESENT["$c"]=0; done
for s in $SIG_RANKED; do
  dir="$(direction_of "$s")"
  for c in $RANKABLE; do
    [ -n "${HAS["$c|$s"]:-}" ] || { PTS["$c|$s"]="absent"; continue; }
    cv="${V["$c|$s"]}"
    case "$cv" in ''|*[!0-9.-]*) die "signal $s carries the non-numeric value \"$cv\" for $c, and $s is declared as an ordered signal. A value that cannot be compared cannot be ranked on, and coercing it would invent an order nobody declared." ;; esac
    NPRESENT["$c"]=$(( ${NPRESENT["$c"]} + 1 ))
    p=0
    for d in $RANKABLE; do
      [ "$d" = "$c" ] && continue
      [ -n "${HAS["$d|$s"]:-}" ] || continue
      dv="${V["$d|$s"]}"
      if [ "$dir" = "higher_is_better" ]; then
        awk -v a="$cv" -v b="$dv" 'BEGIN{exit !(a>b)}' && p=$((p+1))
      else
        awk -v a="$cv" -v b="$dv" 'BEGIN{exit !(a<b)}' && p=$((p+1))
      fi
    done
    PTS["$c|$s"]="$p"
    TOTAL["$c"]=$(( ${TOTAL["$c"]} + p ))
  done
done

# --- Pareto: a dominated candidate is MARKED, never deleted ------------------
declare -A DOM=()
for c in $RANKABLE; do
  DOM["$c"]=""
  for d in $RANKABLE; do
    [ "$d" = "$c" ] && continue
    shared=0; strictly=0; worse=0
    for s in $SIG_RANKED; do
      { [ -n "${HAS["$c|$s"]:-}" ] && [ -n "${HAS["$d|$s"]:-}" ]; } || continue
      shared=$((shared+1))
      dir="$(direction_of "$s")"; cv="${V["$c|$s"]}"; dv="${V["$d|$s"]}"
      if [ "$dir" = "higher_is_better" ]; then
        awk -v a="$dv" -v b="$cv" 'BEGIN{exit !(a>b)}' && strictly=$((strictly+1))
        awk -v a="$dv" -v b="$cv" 'BEGIN{exit !(a<b)}' && worse=$((worse+1))
      else
        awk -v a="$dv" -v b="$cv" 'BEGIN{exit !(a<b)}' && strictly=$((strictly+1))
        awk -v a="$dv" -v b="$cv" 'BEGIN{exit !(a>b)}' && worse=$((worse+1))
      fi
    done
    if [ "$shared" -gt 0 ] && [ "$worse" -eq 0 ] && [ "$strictly" -gt 0 ]; then
      DOM["$c"]="$d"; break
    fi
  done
done

# --- the ordering -------------------------------------------------------------
ORDER="$(for c in $RANKABLE; do printf '%s\t%s\n' "${TOTAL["$c"]}" "$c"; done | sort -k1,1nr -k2,2)"
declare -A RANKOF=()
for c in $RANKABLE; do
  higher=0
  for d in $RANKABLE; do
    [ "$d" = "$c" ] && continue
    [ "${TOTAL["$d"]}" -gt "${TOTAL["$c"]}" ] && higher=$((higher+1))
  done
  RANKOF["$c"]=$((higher+1))
done

# --- emit ---------------------------------------------------------------------
BODY=""
add(){ BODY="${BODY}$*"$'\n'; }

add "s1: SHADOW RANKER — ORDERED CANDIDATES, ZERO DISPATCH AUTHORITY"
add "control: ranker.s1_shadow_ordering  class=C  empirical_status=untested  runtime_authority=observe  deployment_mode=shadow  output_semantics=ordered_candidates"
add "composition: MIN(class C -> advise, untested -> observe, shadow -> observe) = observe. S1 orders. It does not select, dispatch, or act."
add "decision: $DEC"
add "selector: $SELECTOR  (S1 did not select anything; it has no authority to)"
add "snapshot_chain_head: $CHAIN_HEAD"
add "snapshots_bound_to_this_decision: $NSNAP  candidates_declared: $CANDS"
add ""
add "== THE RULE =="
while IFS= read -r l; do [ -n "$l" ] && add "$l"; done < <(print_rule)
add ""
add "== SIGNALS — WHAT IS RANKED, AND EVERY ABSENCE NAMED =="
for s in $SIG_RANKED; do
  add "signal $s RANKED direction=$(direction_of "$s") weight=1"
done
for row in $SIGNAL_DIRECTION; do
  s="${row%%:*}"
  in_words "$s" "$SIG_RANKED" || add "signal $s MISSING declared as an ordered signal but NOT frozen for this decision — not imputed, not defaulted, not dropped, and it scores nothing below"
done
for s in $SIGNALS_UNINTERPRETED $SIG_DYNAMIC_UNINTERP; do
  add "signal $s UNINTERPRETED frozen in this repository but its DIRECTION has never been established, so S1 refuses to order on it rather than guess one"
done
for s in $SIGNALS_NEVER_COLLECTED; do
  add "signal $s NEVER-COLLECTED nothing in this repository has ever measured it; it is named as absent rather than imputed"
done
add ""
add "== GUARD 1 — SELF-AMENDMENT EXCLUSION (refused, and still on the record) =="
if [ -n "$EXCLUDED_LINES" ]; then
  while IFS= read -r l; do [ -n "$l" ] && add "$l"; done < <(printf '%s' "$EXCLUDED_LINES")
else
  add "excluded_count: 0 — no candidate in this set reaches a protected object"
fi
add ""
add "== EVERY CANDIDATE'S FROZEN SIGNAL VALUES (nothing is filtered out) =="
for c in $CAND_LIST; do
  vals=""
  for s in $SIG_RANKED; do
    if [ -n "${HAS["$c|$s"]:-}" ]; then vals="$vals $s=${V["$c|$s"]}"; else vals="$vals $s=absent"; fi
  done
  st="ranked"; in_words "$c" "$RANKABLE" || st="EXCLUDED"
  add "candidate $c status=$st$vals"
  add "candidate $c ${SURFACE_SIGNAL}=${V["$c|$SURFACE_SIGNAL"]:-absent}"
done
add ""
add "== THE ORDERING, WITH ITS DECOMPOSITION =="
while IFS="$TAB" read -r t c; do
  [ -n "$c" ] || continue
  tied=no
  for d in $RANKABLE; do
    [ "$d" = "$c" ] && continue
    [ "${TOTAL["$d"]}" = "$t" ] && { tied=yes; break; }
  done
  par="frontier"; [ -n "${DOM["$c"]}" ] && par="dominated_by=${DOM["$c"]}"
  add "rank ${RANKOF["$c"]} $c total=$t signals=${NPRESENT["$c"]}/$NSIGR tie=$tied pareto=$par"
  for s in $SIG_RANKED; do
    if [ -n "${HAS["$c|$s"]:-}" ]; then
      add "contribution $c $s value=${V["$c|$s"]} direction=$(direction_of "$s") points=${PTS["$c|$s"]}"
    else
      add "contribution $c $s value=absent direction=$(direction_of "$s") points=none — absent, and an absence scores nothing"
    fi
  done
done <<< "$ORDER"
add ""
add "== THE SELECTION, AND WHERE S1 PUT IT =="
add "selected_candidate_id: $SELECTED"
if in_words "$SELECTED" "$RANKABLE"; then
  ROS="${RANKOF["$SELECTED"]}"
elif in_words "$SELECTED" "$CAND_LIST"; then
  ROS="excluded"
else
  ROS="not-a-candidate"
fi
add "rank_of_selected: $ROS"
add "note: rank_of_selected is the measurement that makes S1 falsifiable. Agreement on a single decision is not evidence of skill; it is one observation, and this tree's own residue records that n is small enough for that to matter."
add "dispatch: none. This ordering caused nothing. Nothing in this repository reads it."

DIGEST="$(printf '%s' "$BODY" | digest_of)"
printf '%s' "$BODY"
printf 'ranking_digest: %s\n' "$DIGEST"
printf 'reproduce: build-os/metrics/rank-candidates.sh rank --decision-id %s\n' "$DEC"
exit 0
