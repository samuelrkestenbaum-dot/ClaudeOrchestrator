#!/usr/bin/env bash
# Build OS — control registry scanner and reconciler.
#
# WHAT THIS EXISTS AGAINST. A registry of controls is the easiest artefact in
# this repository to turn into shelfware, because nothing breaks when it goes
# stale. `check-adoption.sh` was written for the same failure one layer down —
# the store nobody records into — and its lesson was that the only reconciliation
# worth having is one against something the author did not have to remember to
# update. So the registry is reconciled against a SCAN OF THE TREE, not against a
# list someone maintains beside it.
#
# WHAT THE SCAN CALLS A CONTROL SURFACE, AND WHY THAT RULE AND NOT ANOTHER. A
# control surface is a FILE that can terminate a run non-zero. That is the
# operational definition of `gate` in the ontology: whatever a control's
# evidentiary class, if its verdict can stop the caller, it is exercising the
# strongest authority there is. The rule is deliberately syntactic and hostile to
# cooperation — it needs no marker comment, no annotation and no author
# discipline, so a gating control added in a new file is discovered whether or
# not anybody wanted it to be.
#
# WHAT IT THEREFORE DOES NOT CATCH, NAMED RATHER THAN IMPLIED AWAY:
#
#   1. A NEW CONTROL ADDED INSIDE AN ALREADY-REGISTERED FILE. The scan is
#      file-granular; the registry is control-granular. `check-adoption.sh` hosts
#      six registered controls, and a seventh added to it tomorrow is invisible
#      here. This is the largest hole in the guard and it is not closed. What
#      narrows it is that every entry must cite `path:line` evidence, so the
#      registry at least cannot cite lines that do not exist.
#   2. A CONTROL THAT REFUSES BY MEANS THIS SCAN'S PATTERNS DO NOT SPELL. The
#      patterns are listed below in full, in one place, so what is uncovered is
#      readable rather than inferred.
#   3. AN ADVISORY CONTROL. A file that only ever exits 0 is not discovered, so
#      an `observe`/`advise` control is registered on the author's initiative and
#      nothing reconciles it. The tree scan is one-directional on purpose: the
#      authority worth policing is the one that can stop a build.
#   4. WHETHER A CITED LINE IS A DECISION. Section 6 now refuses a ref that
#      lands on a blank line, a comment, a shebang or a lone closer, which is
#      the cheap half of the question. The half worth having — is this line a
#      comparison or an exit — is not implemented: an `echo` passes. Measured
#      against the defect that motivated the check, it catches two of the three
#      bad `tools.supervise_timeout` refs and not the third.
#   5. AN ENTRY THAT SHEDS AUTHORITY BY NARROWING ITS `evidence_refs`. Nothing
#      here compares an entry's cited lines against the lines it USED to cite,
#      so a control can be made to look in-licence by dropping the citation that
#      exceeded it rather than by relabelling its class — which is the technique
#      the `suite.*` entries were corrected with, legitimately, in this very
#      packet. Only the `-ge N` family is policed against the tree (suite §21);
#      every other entry's scope is the author's word.
#
# THE SECOND RECONCILIATION, AND WHY IT RUNS AGAINST A HAND-WRITTEN FILE. The
# licence test (section 5) only fires while a control is still CLASSIFIED as
# exceeding its licence. Relabel a heuristic `class: A` and the test stops
# having an opinion — the registry looks clean and MISMATCHES.md goes on
# accusing it. So MISMATCHES.md's summary table is read back as an ANCHOR
# (section 8): every id named between the MISMATCH-TABLE markers must still
# carry `authority_mismatch: declared`. Clearing a mismatch now costs an edit to
# the accusation, in prose, where a reviewer reads it — not a one-word change to
# a label. That is the difference between a rule stated in a header and a rule.
#
# Local only. Reads files and prints. Writes nothing, anywhere.
#
# Usage:
#   scan-controls.sh surfaces [--repo DIR]
#   scan-controls.sh check    [--repo DIR] [--registry FILE] [--mismatches FILE]
#   scan-controls.sh patterns | anchors [--anchors F] [--ref ID|REF] [--project]
# Exit: 0 reconciled, 2 refused (a violation, or a scan that cannot be trusted).
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"
REGISTRY=""
MISMATCHES=""
TAB=$'\t'; VIOL=0; ADVISORY=0; ANCHORS_FILE=""; AREF=""; APROJECT=0

CMD="${1:-}"
[ $# -gt 0 ] && shift

refuse(){ printf 'scan-controls: REFUSED — %s\n' "$*" >&2; exit 2; }
viol(){ VIOL=$((VIOL+1)); printf '  %s\n' "$*"; }
# THE ADVISORY CHANNEL. A finding that is REPORTED and does NOT affect the exit
# code. It exists because this scanner had exactly one check — OBSERVE-LB — whose
# subject matter belongs to an ADVISORY system (the evidence axis, which exits 0
# by design and says so in its own output) while the check itself refused at
# exit 2. The result was that the advisory system could recommend a demotion and
# this gate would then forbid the operator from applying it. An advisory axis
# whose recommendations are blocked by a gate is not advisory. Reported findings
# are printed and counted; only `viol` sets the exit code.
advise_note(){ ADVISORY=$((ADVISORY+1)); printf '  %s\n' "$*"; }
in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }

case "$CMD" in
  surfaces|check|patterns|anchors) ;;
  -h|--help|help) sed -n '2,66p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") refuse "no command — expected one of: surfaces, check, patterns, anchors" ;;
  *)  refuse "unknown command \"$CMD\" — expected one of: surfaces, check, patterns, anchors" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)       [ $# -ge 2 ] || refuse "--repo needs a value";       REPO="$2"; shift 2 ;;
    --registry)   [ $# -ge 2 ] || refuse "--registry needs a value";   REGISTRY="$2"; shift 2 ;;
    --mismatches) [ $# -ge 2 ] || refuse "--mismatches needs a value"; MISMATCHES="$2"; shift 2 ;;
    --anchors)    [ $# -ge 2 ] || refuse "--anchors needs a value";    ANCHORS_FILE="$2"; shift 2 ;;  --ref) [ $# -ge 2 ] || refuse "--ref needs a value"; AREF="$2"; shift 2 ;;  --project) APROJECT=1; shift ;;
    -h|--help)    sed -n '2,66p' "${BASH_SOURCE[0]}"; exit 0 ;;  *) refuse "unknown option \"$1\"" ;;
  esac
done
[ -n "$REGISTRY" ]   || REGISTRY="$SELF_DIR/control_registry.txt"
[ -n "$MISMATCHES" ] || MISMATCHES="$SELF_DIR/MISMATCHES.md"

# --- the ontology, as this scanner enforces it -------------------------------
CLASSES="R A B C D"
IMPL_STATUSES="specified implemented runtime_observed decision_contributing load_bearing"
# `untested` was added by gravito_p2_claim_scoped_evidence_a: the claim HAS NEVER
# OPERATED against a live or representative task, which is strictly weaker than
# `unvalidated` (it operated; the outcome evidence is inadequate). It caps at
# `observe` on build-os/tools/evidence-policy.sh's evidence axis. Widening this
# enum re-authorises nothing — no control in the census carries it — and the
# unknown-token refusal below is unchanged.
EMP_STATUSES="untested unvalidated red_driven field_observed calibrated refuted"
AUTHORITIES="none observe advise rank gate execute"
ROLES="sensor reflex immune memory conscience motor"
MISMATCH_VALUES="none declared"
FIELDS="control class implementation_status empirical_status runtime_authority nervous_system_role inputs output owning_module consuming_policies evidence_refs failure_behavior rollback_behavior promotion_requirement demotion_requirement authority_mismatch notes"

# Authority is a total order. The licence table says how far up it each
# evidentiary class reaches on its own merits:
#   A hard invariant      -> gate     (an invariant IS the thing that may stop a build)
#   B deterministic metric-> rank     (a number may order work; turning it into a
#                                      stop is a policy decision, not a property
#                                      of the number)
#   C heuristic policy    -> advise   (a heuristic does not become a gate by
#                                      being useful)
#   D learned model       -> observe
#   R research functional -> observe
rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; execute) echo 5 ;; *) echo -1 ;; esac; }
lic_of(){  case "$1" in A) echo 4 ;; B) echo 3 ;; C) echo 2 ;; D) echo 1 ;; R) echo 1 ;; *) echo -1 ;; esac; }

# --- the discovery rule ------------------------------------------------------
# Directories searched, and the two extensions. Anything outside these is not
# scanned; that is a bound on the guard, not a claim that nothing else gates.
SCAN_DIRS="build-os tests .claude/hooks"
# EVERY refusal construct this scan recognises, in one place so the uncovered
# set is readable. Each is an extended regular expression matched per line.
REFUSAL_PATTERNS=(
  '(^|[^[:alnum:]_])exit[[:space:]]+[1-9][0-9]*([^0-9]|$)'   # exit with a non-zero literal
  'process\.exitCode[[:space:]]*=[[:space:]]*[1-9]'          # node: fail the run from a handler
  'process\.exit\('                                          # node: exit with a computed status
  'throw new [A-Za-z]*Error'                                 # node: abort by throwing
  '^\[ "\$FAIL" -eq 0 \][[:space:]]*$'                       # the house-style suite verdict
)
REFUSAL_RE="$(IFS='|'; printf '%s' "${REFUSAL_PATTERNS[*]}")"

# --- what makes a CITED LINE vacuous -----------------------------------------
# THE HOLE THIS CLOSES, AND ITS EXACT SIZE. `evidence_refs` were checked only
# for landing INSIDE the file, so a citation could satisfy `nref >= 1` on a line
# that exercises nothing: `tools.supervise_timeout` cited a header comment, an
# `echo` and a `fi` for a full packet, and two entries cited
# `#!/usr/bin/env bash`. Every round of hand-resolving 200-odd citations found
# more of them and cast a wider net than the last, which is what a hand sweep
# does. This is the sweep, mechanised.
#
# IT CATCHES exactly four shapes: a blank line, a comment-only line, a shebang,
# and a lone closer. IT DOES NOT CATCH a line that is a statement but not a
# decision — an `echo`, an assignment, a bare function call and a `return` all
# pass. Measured against the defect that motivated it, this would have caught
# two of the three bad `supervise_timeout` refs and NOT the `echo`. The check
# actually worth having is "is this line a comparison or an exit", and that is
# genuinely hard; this is the cheap half and it is not sold as the whole one.
#
# DECLARATIONS PASS BY CONSTRUCTION, deliberately. A threshold control is often
# best cited at the line that DEFINES its chosen constant — `TIMEOUT="900"` is
# the entire subject of that entry — and a filter that rejected declarations
# would push authors toward citing a less honest line to appease it.
VAC_SHEBANG='^#!'
VAC_COMMENT_SH='^[[:space:]]*#'
VAC_COMMENT_JS='^[[:space:]]*(//|/\*|\*[[:space:]/]|\*$)'
VAC_CLOSER='^[[:space:]]*(fi|done|esac|else|\}|\)|\{|\]|;;)[[:space:]]*;?[[:space:]]*$'
# THE ALLOWANCE, kept greppable rather than silent. A ref may one day have to
# point at a line the filter above rejects — a sentinel marker comment that IS
# the control being classified, say. Such a ref belongs here as
# `path:line — the reason`, where `grep EVIDENCE_VACUITY_ALLOW` finds it and a
# reviewer reads the reason beside it. It is EMPTY today: every ref in this
# registry lands on a line that does something on its own, so the exemption
# route exists and is currently unused. `scan-controls.sh patterns` prints its
# size, so an allowance quietly growing is visible without reading this file.
EVIDENCE_VACUITY_ALLOW=(
)

# Why a cited line is vacuous, or empty if it is not.
vacuous_why(){ # <abs-file> <lineno>
  local f="$1" n="$2" line cmt
  line="$(sed -n "${n}p" "$f" 2>/dev/null)"
  case "$f" in *.mjs) cmt="$VAC_COMMENT_JS" ;; *) cmt="$VAC_COMMENT_SH" ;; esac
  if [ -z "${line//[[:space:]]/}" ];                          then printf 'blank line'
  elif printf '%s\n' "$line" | grep -qE "$VAC_SHEBANG";        then printf 'shebang'
  elif printf '%s\n' "$line" | grep -qE "$cmt";                then printf 'comment-only line'
  elif printf '%s\n' "$line" | grep -qE "$VAC_CLOSER";         then printf 'lone closer'
  fi
}
vacuity_allowed(){ # <path:line>
  local a
  for a in ${EVIDENCE_VACUITY_ALLOW[@]+"${EVIDENCE_VACUITY_ALLOW[@]}"}; do
    case "$a" in "$1"|"$1 "*) return 0 ;; esac
  done
  return 1
}

if [ "$CMD" = "patterns" ]; then
  printf 'scan dirs: %s\n' "$SCAN_DIRS"
  printf 'extensions: .sh .mjs\n'
  for p in "${REFUSAL_PATTERNS[@]}"; do printf 'refusal: %s\n' "$p"; done
  printf 'vacuous-ref: %s\n' \
    "blank:^[[:space:]]*\$" \
    "shebang:$VAC_SHEBANG" \
    "comment(.sh):$VAC_COMMENT_SH" \
    "comment(.mjs):$VAC_COMMENT_JS" \
    "closer:$VAC_CLOSER"
  printf 'vacuous-ref-NOT-caught: a statement that decides nothing (echo, assignment, bare call, return)\n'
  printf 'vacuity-allow-count: %s\n' "${#EVIDENCE_VACUITY_ALLOW[@]}"
  for a in ${EVIDENCE_VACUITY_ALLOW[@]+"${EVIDENCE_VACUITY_ALLOW[@]}"}; do printf 'vacuity-allow: %s\n' "$a"; done
  exit 0
fi

[ -d "$REPO" ] || refuse "--repo is not a directory: $REPO"

surfaces(){
  local d f rel
  for d in $SCAN_DIRS; do
    [ -d "$REPO/$d" ] || continue
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      grep -qE "$REFUSAL_RE" "$f" 2>/dev/null || continue
      rel="${f#"$REPO/"}"
      printf '%s\n' "$rel"
    done < <(find "$REPO/$d" -type f \( -name '*.sh' -o -name '*.mjs' \) 2>/dev/null | sort)
  done | sort -u
}

if [ "$CMD" = "surfaces" ]; then
  surfaces
  exit 0
fi
if [ "$CMD" != "anchors" ]; then   # ...everything to the matching `fi` is the REGISTRY reconciliation
# ---------------------------------------------------------------- check ------
[ -f "$REGISTRY" ]   || refuse "no registry at $REGISTRY. There is nothing to reconcile, and an absent census is not an empty one."
[ -f "$MISMATCHES" ] || refuse "no mismatch report at $MISMATCHES. The registry is allowed to record a control exercising more authority than its class licenses; it is not allowed to record it silently."

# Flatten the stanza store to id<TAB>field<TAB>value, refusing anything ragged.
FLAT="$(mktemp)"; trap 'rm -f "$FLAT"' EXIT
LN=0; CUR=""; MALFORMED=""
while IFS= read -r line || [ -n "$line" ]; do
  LN=$((LN+1))
  line="${line%$'\r'}"
  case "$line" in ''|'#'*) continue ;; esac
  case "$line" in
    "control: "*)
      CUR="${line#control: }"
      printf '%s\t%s\t%s\n' "$CUR" "control" "$CUR" >> "$FLAT" ;;
    *": "*)
      key="${line%%: *}"; val="${line#*: }"
      if ! in_list "$key" "$FIELDS"; then
        MALFORMED="$MALFORMED line $LN: unknown field \"$key\";"
      elif [ -z "$CUR" ]; then
        MALFORMED="$MALFORMED line $LN: field \"$key\" appears before any control;"
      else
        printf '%s\t%s\t%s\n' "$CUR" "$key" "$val" >> "$FLAT"
      fi ;;
    *)
      MALFORMED="$MALFORMED line $LN: not a \"field: value\" line and not a comment;" ;;
  esac
done < "$REGISTRY"
[ -n "$MALFORMED" ] && refuse "$REGISTRY is malformed. A registry an agent cannot read line by line is not greppable, which was the whole reason for this format: ${MALFORMED%;}"

IDS="$(awk -F'\t' '$2=="control"{print $3}' "$FLAT")"
NENT="$(printf '%s\n' "$IDS" | grep -c . || true)"; NENT="${NENT:-0}"

# VACUITY, HALF ONE. Zero entries is not "nothing to check"; it is the shelfware
# state, and it is exactly what a registry looks like the day after someone
# decides it is too much trouble.
[ "$NENT" -eq 0 ] && refuse "$REGISTRY declares 0 controls. An empty census is not a clean one; it is an unclassified system wearing a registry."

DUPS="$(printf '%s\n' "$IDS" | sort | uniq -d)"
[ -n "$DUPS" ] && refuse "duplicate control id(s): $(printf '%s' "$DUPS" | tr '\n' ' ')"

SURF="$(surfaces)"
NSURF="$(printf '%s\n' "$SURF" | grep -c . || true)"; NSURF="${NSURF:-0}"
# VACUITY, HALF TWO. A scan that found nothing has not proved the registry
# complete; it has proved it was looking somewhere empty.
[ "$NSURF" -eq 0 ] && refuse "the independent scan discovered 0 control surfaces under $REPO ($SCAN_DIRS). A blinded scanner reports a clean tree forever, so this refuses instead."

printf 'scan-controls: %s registered control(s) in %s vs %s refusal-capable surface(s) under %s\n' \
  "$NENT" "$REGISTRY" "$NSURF" "$REPO"

get(){ awk -F'\t' -v i="$1" -v f="$2" '$1==i && $2==f {print $3; exit}' "$FLAT"; }

VIOL=0
ADVISORY=0
GATEMODS=""
LOADBEARING=0
DECLARED_MM=0

while IFS= read -r id; do
  [ -n "$id" ] || continue

  # --- 1. every field present -------------------------------------------------
  for f in $FIELDS; do
    v="$(get "$id" "$f")"
    [ -n "$v" ] || viol "INCOMPLETE  $id has no \"$f\". A partially declared control is an undeclared one: the registry's value is that the fields it does not know are visibly blank rather than absent."
  done

  cls="$(get "$id" class)"
  imp="$(get "$id" implementation_status)"
  emp="$(get "$id" empirical_status)"
  aut="$(get "$id" runtime_authority)"
  role="$(get "$id" nervous_system_role)"
  own="$(get "$id" owning_module)"
  cons="$(get "$id" consuming_policies)"
  evid="$(get "$id" evidence_refs)"
  mm="$(get "$id" authority_mismatch)"

  # --- 2. enums ---------------------------------------------------------------
  in_list "$cls"  "$CLASSES"         || viol "ENUM        $id class \"$cls\" is not one of the five-class ontology: $CLASSES"
  in_list "$imp"  "$IMPL_STATUSES"   || viol "ENUM        $id implementation_status \"$imp\" is not one of: $IMPL_STATUSES"
  in_list "$aut"  "$AUTHORITIES"     || viol "ENUM        $id runtime_authority \"$aut\" is not one of: $AUTHORITIES"
  in_list "$role" "$ROLES"           || viol "ENUM        $id nervous_system_role \"$role\" is not one of: $ROLES"
  in_list "$mm"   "$MISMATCH_VALUES" || viol "ENUM        $id authority_mismatch \"$mm\" is not one of: $MISMATCH_VALUES"
  for tok in $(printf '%s' "$emp" | tr ',' ' '); do
    in_list "$tok" "$EMP_STATUSES" || viol "ENUM        $id empirical_status token \"$tok\" is not one of: $EMP_STATUSES"
  done

  # --- 3. load-bearing is a claim about a CONSUMER, not about existence -------
  if [ "$imp" = "load_bearing" ]; then
    LOADBEARING=$((LOADBEARING+1))
    if [ -z "$cons" ] || [ "$cons" = "NONE" ] || [ "$cons" = "-" ]; then
      viol "LOAD-BEARING $id claims load_bearing and names no consuming policy. A control is not load_bearing because it is implemented; it is load_bearing when a live policy consumes it, its result changes behaviour, and removing it changes outcomes. Name the policy or demote the status."
    elif [ "$aut" = "observe" ]; then
      advise_note "OBSERVE-LB  $id claims load_bearing at authority \"observe\" (consumed by: $cons). REPORTED, NOT REFUSED. Under the corrected ladder \"observe\" means the output may be recorded and CONSUMED FOR VISIBILITY while causing NO OPERATIONAL CONSEQUENCE — so being consumed is no longer the contradiction, and the premise this check was built on is gone. What survives is narrower and is a question about CONSEQUENCE: load_bearing asserts that the result changes behaviour and that REMOVING IT CHANGES OUTCOMES, which is an operational consequence. So one of the two is mis-stated — either the control does have consequence and is not at \"observe\", or it does not and is not load_bearing. THIS IS ADVISORY BECAUSE THE AXIS THAT PRESCRIBES THE DEMOTION IS ADVISORY: the evidence axis caps a \"refuted\" control at \"observe\", exits 0, and states in its own output that re-authorising is the operator's. A gate here refused the operator the very demotion that advisory system recommends, which is incoherent. Resolve it by demoting implementation_status to decision_contributing if nothing depends on the outcome, or by leaving the authority where it is and leaving the finding standing — both are governance moves and neither is performed here."
    fi
  fi

  # --- 4. research and learned may not outrank an invariant -------------------
  case "$cls" in
    R|D)
      if [ "$(rank_of "$aut")" -gt 1 ]; then
        viol "OVERRANK    $id is class $cls at authority \"$aut\". A class-$cls control may not sit above \"observe\": research code and learned models do not enter production control paths, and a learned model does not outrank an invariant by being accurate."
      fi ;;
  esac

  # --- 5. the licence table, and the ban on laundering ------------------------
  a_rank="$(rank_of "$aut")"; l_rank="$(lic_of "$cls")"
  if [ "$a_rank" -gt 0 ] && [ "$l_rank" -ge 0 ] && [ "$a_rank" -gt "$l_rank" ]; then
    DECLARED_MM=$((DECLARED_MM+1))
    if [ "$mm" != "declared" ]; then
      viol "LAUNDERED   $id exercises \"$aut\" on a class-$cls licence, which reaches only \"$(case "$l_rank" in 0) echo none ;; 1) echo observe ;; 2) echo advise ;; 3) echo rank ;; 4) echo gate ;; 5) echo execute ;; esac)\", but declares authority_mismatch: $mm. Exceeding the licence is permitted and recorded; doing it silently is not. Set authority_mismatch: declared and list it in the mismatch report — or, if the classification is wrong, fix the CLASS, and be ready to say why the thresholds are not a heuristic."
    fi
    # The id must appear as a WHOLE TOKEN. Control ids nest —
    # `metrics.record.verify_git` is a prefix of
    # `metrics.record.verify_git_vacuity`, and `suite.build_os` of
    # `suite.build_os_maintenance` — so an unanchored substring match would let
    # a shorter id ride on a longer id's mention and certify itself reported.
    id_re="${id//./\\.}"
    grep -qE "(^|[^A-Za-z0-9_.])${id_re}([^A-Za-z0-9_.]|\$)" "$MISMATCHES" 2>/dev/null \
      || viol "UNREPORTED  $id is over-authorised but never appears in $MISMATCHES. A declared mismatch that reaches no report is a mismatch nobody will read."
  elif [ "$mm" = "declared" ]; then
    viol "OVERDECLARED $id declares an authority mismatch, but \"$aut\" is within a class-$cls licence. A false mismatch dilutes the report the real ones live in."
  fi

  # --- 6. evidence must resolve ----------------------------------------------
  [ -n "$own" ] && [ -f "$REPO/$own" ] \
    || viol "NO-MODULE   $id names owning_module \"$own\", which is not a file under $REPO"
  nref=0
  for ref in $(printf '%s' "$evid" | tr ';' ' '); do
    [ -n "$ref" ] || continue
    nref=$((nref+1))
    rf="${ref%:*}"; rl="${ref##*:}"
    if [ ! -f "$REPO/$rf" ]; then
      viol "NO-EVIDENCE $id cites $ref, but $rf is not a file under $REPO"
      continue
    fi
    case "$rl" in ''|*[!0-9]*) viol "NO-EVIDENCE $id cites \"$ref\", which carries no line number — a control is classified by the line that exercises it, not by the file it lives in"; continue ;; esac
    tot="$(wc -l < "$REPO/$rf" | tr -d ' ')"
    if { [ "$rl" -ge 1 ] && [ "$rl" -le "${tot:-0}" ]; }; then
      # ...and the line must DO something. Being inside the file is not evidence.
      why="$(vacuous_why "$REPO/$rf" "$rl")"
      if [ -n "$why" ] && ! vacuity_allowed "$ref"; then
        viol "VACUOUS-REF $id cites $ref, which resolves to a $why. A control is classified by the line that exercises it; a citation that lands on nothing satisfies \"cites evidence\" vacuously, which is the guard failing rather than passing. Cite the comparison, the exit, or the definition of the chosen constant — or, if this line really is the control, add it to EVIDENCE_VACUITY_ALLOW with a reason."
      fi
    else
      viol "NO-EVIDENCE $id cites $ref, which is past the end of a ${tot:-0}-line file"
    fi
  done
  [ "$nref" -ge 1 ] || viol "NO-EVIDENCE $id cites no evidence at all"

  [ "$aut" = "gate" ] && GATEMODS="$GATEMODS$own"$'\n'
done < <(printf '%s\n' "$IDS")

# --- 7. the anti-shelfware reconciliation ------------------------------------
GATEMODS="$(printf '%s' "$GATEMODS" | grep -v '^$' | sort -u)"
UNREG=0; PHANTOM=0
while IFS= read -r s; do
  [ -n "$s" ] || continue
  printf '%s\n' "$GATEMODS" | grep -qxF "$s" \
    || { UNREG=$((UNREG+1)); viol "UNREGISTERED $s can terminate a run non-zero and owns NO registry entry at authority gate. A control that is not classified is a control whose authority nobody decided to grant."; }
done < <(printf '%s\n' "$SURF")
while IFS= read -r m; do
  [ -n "$m" ] || continue
  printf '%s\n' "$SURF" | grep -qxF "$m" \
    || { PHANTOM=$((PHANTOM+1)); viol "PHANTOM     $m owns a registry entry at authority gate, but the independent scan finds no refusal construct in it. Either the control was removed and the registry still claims it, or it never gated."; }
done < <(printf '%s\n' "$GATEMODS")

# --- 8. the reverse reconciliation: the report is an anchor, not an echo ------
# Section 5 checks one direction only — a control the REGISTRY calls
# over-authorised must reach the report — and that direction evaporates the
# moment the class is relabelled. This checks the other direction: every control
# the REPORT names is still required to carry `authority_mismatch: declared`. It
# is what makes "do not clear a mismatch by changing the class" an enforced rule
# rather than a sentence in a header.
REPORTED="$(awk '
  /<!-- MISMATCH-TABLE:START -->/{f=1; next}
  /<!-- MISMATCH-TABLE:END -->/{f=0}
  f && /^\|[[:space:]]*`/ { l=$0; sub(/^\|[[:space:]]*`/,"",l); sub(/`.*$/,"",l); if (l != "") print l }
' "$MISMATCHES")"
# A ROW IS NOT AN ID. The reconciled count used to count rows, so pasting one
# control's row twice raised it by one, at exit 0, and reported more controls
# reconciled than the census classifies. A number that can be raised by
# copy-paste reconciles nothing, and the anchor's whole value is that its count
# means something. So: duplicates are a violation, and the count is distinct.
DUPREP="$(printf '%s\n' "$REPORTED" | grep -v '^$' | sort | uniq -d)"
while IFS= read -r drid; do
  [ -n "$drid" ] || continue
  viol "DUPLICATE-ROW $drid appears in more than one row of $MISMATCHES's summary table. The reconciled count is a count of controls, not of lines: a duplicated row inflates it without classifying anything, and the table is the anchor precisely because its rows are supposed to be one-per-control."
done < <(printf '%s\n' "$DUPREP")
REPORTED="$(printf '%s\n' "$REPORTED" | grep -v '^$' | sort -u)"
NREP="$(printf '%s\n' "$REPORTED" | grep -c . || true)"; NREP="${NREP:-0}"
# VACUITY, HALF THREE. A reverse check that parses zero rows certifies every
# relabelling forever, and it would do it silently — the failure mode of the two
# halves above, one layer along. A registry that declares no mismatch at all is
# allowed an empty table; one that declares any is not.
{ [ "$DECLARED_MM" -gt 0 ] && [ "$NREP" -eq 0 ]; } && refuse "$DECLARED_MM control(s) declare an authority mismatch, but the reverse reconciliation parsed 0 control ids from $MISMATCHES between <!-- MISMATCH-TABLE:START --> and <!-- MISMATCH-TABLE:END -->. A reverse check with nothing to check clears every relabelled mismatch at once, so it refuses instead of passing."
RELABELLED=0
while IFS= read -r rid; do
  [ -n "$rid" ] || continue
  if ! printf '%s\n' "$IDS" | grep -qxF "$rid"; then
    RELABELLED=$((RELABELLED+1))
    viol "GHOST-REPORT $rid is named in $MISMATCHES's summary table but owns no entry in $REGISTRY. The report accuses a control the census does not classify."
    continue
  fi
  rmm="$(get "$rid" authority_mismatch)"
  if [ "$rmm" != "declared" ]; then
    RELABELLED=$((RELABELLED+1))
    viol "RELABELLED  $rid is listed in $MISMATCHES as exercising more authority than its class licenses, but the registry now records authority_mismatch: \"$rmm\". Either the report is stale, or a mismatch was cleared by editing the CLASS rather than the AUTHORITY. Re-authorising a control is the operator's decision; it is not a relabel."
  fi
done < <(printf '%s\n' "$REPORTED")
# ...and completeness, so that a row cannot simply be deleted. The forward check
# in section 5 matches the id anywhere in the file, which a prose mention
# satisfies; the ANCHOR is the table.
while IFS= read -r id; do
  [ -n "$id" ] || continue
  [ "$(get "$id" authority_mismatch)" = "declared" ] || continue
  printf '%s\n' "$REPORTED" | grep -qxF "$id" \
    || viol "UNANCHORED  $id declares an authority mismatch but appears in no row of $MISMATCHES's summary table. A prose mention is not an anchor: it is what a deleted row leaves behind."
done < <(printf '%s\n' "$IDS")

printf 'scan-controls: %s load_bearing, %s over-authorised (declared), %s unregistered surface(s), %s phantom entr(ies), %s report row(s) reconciled\n' \
  "$LOADBEARING" "$DECLARED_MM" "$UNREG" "$PHANTOM" "$NREP"
printf 'scan-controls: %s advisory finding(s) — reported, and deliberately NOT affecting the exit code.\n' "$ADVISORY"
fi   # <- the matching `fi`: everything above is the REGISTRY reconciliation, which
     #    `anchors` skips because it reconciles a different thing.

# ============================================================== ANCHOR-BLOCK ==
# STABLE SEMANTIC ANCHORS. Residue (mm) measured this hole and named the remedy
# in one sentence: the citation guard above checks RESOLVABILITY, NOT IDENTITY,
# and "the durable fix is an ANCHOR TOKEN or a CONTENT HASH instead of a line
# number". Section 6 asks whether a number lands inside a file and whether the
# line it lands on does something. It never asks whether that line is the SAME
# OBJECT the citation was written about, and across the three tools whose refs
# drifted, 20 of 27 references passed every positional check while silently
# wrong.
#
# THE RULE THIS BLOCK ENFORCES, AND IT IS THE WHOLE DESIGN:
#
#     A LINE NUMBER MAY BE A NAVIGATION HINT. IT MAY NOT BE THE IDENTITY.
#
# An anchor names its object by CONTENT. The line number is COMPUTED at every
# resolution and is stored nowhere, so an insertion above the object moves the
# number and cannot move the object. A position may still be written down —
# `path:line#ANCHOR-ID` — and the two halves are graded differently: a wrong
# `#` half is a REFUSAL, a stale `:` half is a REPORT with the corrected
# projection printed beside it.
#
# THE RECORD. Ten fields, `|`-delimited, one per line, between the ANCHOR-TABLE
# markers below:
#
#   anchor_id | object_id | object_type | namespace_id | semantic_role |
#   artifact_ref | content_or_symbol_ref | version | created_at | supersedes
#
# WHERE THE TABLE LIVES, AND WHY IT IS NOT A NEW STORE. It is a declaration
# inside the module that owns it, in the same shape and for the same reason as
# EVIDENCE_VACUITY_ALLOW above: a separate file would be one more artefact that
# can go stale independently of the guard that reads it, and this packet's
# ceiling forbids a new store without an executed fixture proving one necessary.
# `--anchors FILE` overrides the table and exists FOR FIXTURES — it is how the
# red drives in tests/control_registry_tests.sh section 28 build tables that are
# supposed to fail. It is the same door `--registry` already opens, and it is
# named here rather than left to be discovered.
#
# WHAT `--repo` DOES AND DOES NOT RETARGET. The embedded table is a declaration
# ABOUT THE REPOSITORY THIS MODULE LIVES IN, so it resolves against that
# repository whatever `--repo` says; `--repo` retargets the SURFACE SCAN. Only
# when `--anchors FILE` supplies a different table does `--repo` apply to
# resolution. Stated because the alternative — the embedded anchors silently
# failing against every fixture tree the suite builds — would have made every
# fixture red for a reason that has nothing to do with the fixture.
#
# WHY THE OPTION ARMS ABOVE ARE PACKED TWO AND THREE TO A LINE. Because ten
# `evidence_refs`, two live ranges and four receipts cite this file BY LINE
# NUMBER, and inserting a line above them would have moved every one of them —
# including citations inside frozen receipts this packet has no licence to
# edit. THE IMPLEMENTATION OF THE ANCHOR SCHEME WAS ITSELF DEFORMED BY THE
# ABSENCE OF THE ANCHOR SCHEME. That is not a joke at the packet's expense; it
# is the cost of positional identity, paid in the one place it is impossible to
# argue with, and it is recorded here rather than tidied away.
#
# WHAT THIS DOES NOT DO, NAMED RATHER THAN IMPLIED AWAY:
#   1. IT ANCHORS THIRTEEN OBJECTS, NOT EVERY OBJECT. The registry carries a
#      hundred controls and the tree carries hundreds of citations; this table
#      instantiates each of the twelve declared object types at least once and
#      stops there. It is a scheme with live instances, not a migration.
#   2. NOTHING YET REQUIRES A CITATION TO CARRY AN ANCHOR. `evidence_refs` are
#      still `path:line` and are still checked positionally by section 6. This
#      block makes the anchored form available and correct; converting the
#      census to it would be a re-authorisation of every entry's evidence and is
#      not this packet's to take.
#   3. CONTENT IS A LITERAL SUBSTRING, NOT A HASH. It must occur EXACTLY ONCE in
#      the artifact — ambiguity is a violation, because content that names two
#      lines does not identify one object — but two artifacts may legitimately
#      carry the same literal, and only the (artifact, content) pair is unique.
#   4. IT CANNOT SEE AN OBJECT RENAMED WITHOUT A SUPERSEDING RECORD. That is a
#      violation here (ANCHOR-UNRESOLVED) rather than a silent pass, which is
#      the fail-closed direction, but nothing detects the rename FOR the author.
ANCHOR_TYPES="control_id decision_id packet_id finding_id evidence_id defect_class_id receipt_id ranking_id outcome_id section_anchor symbol_anchor test_assertion_anchor"
# ANCHOR-TABLE:START
ANCHOR_TABLE=(
'ANC-0001|registry.evidence_resolution|control_id|buildos.control|the-anchor-resolver-entry|build-os/registry/control_registry.txt|control: registry.evidence_resolution|1|2026-08-02|-'
'ANC-0002|DECISION-0011-p5b-next-after-p3b|decision_id|buildos.decision|the-sealed-prospective-decision|build-os/metrics/decision_telemetry.tsv|DECISION-0011-p5b-next-after-p3b|1|2026-08-02|-'
'ANC-0003|PACKET-0029-citation-anchor-tokens|packet_id|buildos.packet|the-executing-packet|build-os/packets/active_packet.md|canonical packet id: PACKET-0029-citation-anchor-tokens|1|2026-08-02|-'
'ANC-0004|FINDING-0003-mutators-emit-no-receipt|finding_id|buildos.finding|an-open-finding|build-os/registry/findings.txt|finding: FINDING-0003-mutators-emit-no-receipt|1|2026-08-02|-'
'ANC-0005|EV-0001-tripwire-coverage-detection-bare-node|evidence_id|buildos.evidence|a-claim-scoped-evidence-assertion|build-os/registry/evidence_assertions.txt|evidence: EV-0001-tripwire-coverage-detection-bare-node|1|2026-08-02|-'
'ANC-0006|DEFECT-0001-stale-line-reference|defect_class_id|buildos.defect|the-class-this-packet-exists-against|build-os/registry/defect_classes.txt|defect_class: DEFECT-0001-stale-line-reference|1|2026-08-02|-'
'ANC-0007|gravito_p5_outcome_counterfactual_telemetry_a|receipt_id|buildos.receipt|the-receipt-that-sealed-the-ranking|build-os/receipts/gravito_p5_outcome_counterfactual_telemetry_a.md|# Receipt — `gravito_p5_outcome_counterfactual_telemetry_a`|1|2026-08-02|-'
'ANC-0008|SIGNAL-SNAPSHOT-0094-seal-anchors|ranking_id|buildos.ranking|the-sealed-rank-for-this-packet|build-os/metrics/signal_snapshots.tsv|SIGNAL-SNAPSHOT-0094-seal-anchors|1|2026-08-02|-'
'ANC-0009|packet-outcome:gravito_p5_outcome_counterfactual_telemetry_a|outcome_id|buildos.outcome|the-recorded-outcome-row|build-os/metrics/packet_metrics.tsv|gravito_p5_outcome_counterfactual_telemetry_a|1|2026-08-02|-'
'ANC-0010-a|section:control_registry_tests#evidence-resolution|section_anchor|buildos.section|the-evidence-resolution-section|tests/control_registry_tests.sh|== 7. Every evidence reference resolves to a real line of a real file ==|1|2026-08-01|-'
'ANC-0010-b|section:control_registry_tests#evidence-resolution|section_anchor|buildos.section|the-evidence-resolution-section|tests/control_registry_tests.sh|== 7. Every evidence reference resolves — and resolvability is NOT identity (section 28) ==|2|2026-08-02|ANC-0010-a'
'ANC-0011|scan-controls.sh:anchor_resolve|symbol_anchor|buildos.symbol|the-content-resolver|build-os/registry/scan-controls.sh|anchor_resolve(){|1|2026-08-02|-'
'ANC-0012|assertion:control_registry_tests#suite-not-vacuous|test_assertion_anchor|buildos.assertion|this-suites-own-vacuity-floor|tests/control_registry_tests.sh|[ "$PASS" -ge 40 ] && ok "this suite ran $PASS assertions|1|2026-08-02|-'
)
# ANCHOR-TABLE:END

# The repository the table is a declaration ABOUT. See the note above.
ANC_REPO="$REPO"
[ -n "$ANCHORS_FILE" ] || ANC_REPO="$(cd "$SELF_DIR/../.." && pwd)"

# Load the records. A file overrides the embedded table; blank lines and
# full-line comments are skipped so a fixture can be annotated.
ANC_RECS=()
if [ -n "$ANCHORS_FILE" ]; then
  [ -f "$ANCHORS_FILE" ] || refuse "no anchor table at $ANCHORS_FILE"
  while IFS= read -r arec || [ -n "$arec" ]; do
    arec="${arec%$'\r'}"
    case "$arec" in ''|'#'*) continue ;; esac
    ANC_RECS+=("$arec")
  done < "$ANCHORS_FILE"
else
  ANC_RECS=("${ANCHOR_TABLE[@]}")
fi
[ "${#ANC_RECS[@]}" -gt 0 ] || refuse "the anchor table declares 0 anchors. An empty table validates every reference in the tree at once, which is the blinded-scanner failure this module already refuses twice."

# Split a record into A1..A10, with A11 catching any overflow field. Done with
# `read` rather than a per-field awk because `check` runs this on every
# invocation and the suite invokes `check` two dozen times.
A1=""; A2=""; A3=""; A4=""; A5=""; A6=""; A7=""; A8=""; A9=""; A10=""; A11=""
anc_split(){ IFS='|' read -r A1 A2 A3 A4 A5 A6 A7 A8 A9 A10 A11 <<<"$1"; }
anc_nf(){ local bars="${1//[^|]/}"; printf '%s' "$(( ${#bars} + 1 ))"; }
anc_id(){ printf '%s' "${1%%|*}"; }
anc_sup(){ printf '%s' "${1##*|}"; }
anc_rec(){ # <anchor-id> -> the whole record on stdout, or non-zero
  local r; for r in "${ANC_RECS[@]}"; do case "$r" in "$1|"*) printf '%s' "$r"; return 0 ;; esac; done; return 1
}
anc_superseded_by(){ # <anchor-id> -> the anchor that supersedes it, or non-zero
  local r; for r in "${ANC_RECS[@]}"; do [ "$(anc_sup "$r")" = "$1" ] && { anc_id "$r"; return 0; }; done; return 1
}

# THE RESOLVER. Identity in, position out — never the other way round. The line
# number is a RETURN VALUE, which is the entire difference between this and
# every positional check in this file. ON SUCCESS the line number goes to
# stdout; ON FAILURE the REASON does, and the exit code is what tells them
# apart. A global would have been read back empty: every caller captures this in
# a command substitution, and a subshell cannot hand a variable to its parent.
anchor_resolve(){ # <artifact-rel-path> <content-or-symbol-ref>
  local f="$ANC_REPO/$1" hits n
  [ -f "$f" ] || { printf '%s' "no artifact at $1"; return 1; }
  hits="$(ANC_CREF="$2" awk '
    BEGIN{ c = ENVIRON["ANC_CREF"] }
    /^# ANCHOR-TABLE:START$/{ s=1 }
    /^# ANCHOR-TABLE:END$/  { s=0; next }
    s { next }
    index($0, c) { print NR }' "$f")"
  n="$(printf '%s\n' "$hits" | grep -c . || true)"
  case "${n:-0}" in
    0) printf '%s' "unresolved — no line of $1 carries the anchored content"; return 1 ;;
    1) printf '%s' "$hits"; return 0 ;;
    *) printf '%s' "ambiguous — ${n} lines of $1 carry the anchored content, so the content does not identify ONE object"; return 1 ;;
  esac
}

# Validate the table itself. Every violation goes through `viol`, so the same
# finding gates a `check` run and refuses an `anchors` run. ANC_LIST=1 prints
# the per-record listing; the `check` path leaves it off and keeps the findings.
anchors_check(){
  local r pair key line seen_ids="" seen_obj="" seen_site="" seen_sup="" aid art cref
  for r in "${ANC_RECS[@]}"; do
    if [ "$(anc_nf "$r")" != "10" ]; then
      viol "ANCHOR-SCHEMA  a record carries $(anc_nf "$r") field(s), not the 10 the scheme declares: $r"
      continue
    fi
    anc_split "$r"
    for pair in "anchor_id=$A1" "object_id=$A2" "object_type=$A3" "namespace_id=$A4" "semantic_role=$A5" "artifact_ref=$A6" "content_or_symbol_ref=$A7" "version=$A8" "created_at=$A9" "supersedes=$A10"; do
      [ -n "${pair#*=}" ] || viol "ANCHOR-SCHEMA  $A1 leaves \"${pair%%=*}\" empty. A partially declared anchor is an undeclared one."
    done
    in_list "$A3" "$ANCHOR_TYPES" || viol "ANCHOR-TYPE    $A1 declares object_type \"$A3\", which is not one of: $ANCHOR_TYPES"
    printf '%s' "$A4" | grep -qE '^[a-z][a-z0-9._-]*$'          || viol "ANCHOR-SCHEMA  $A1 declares namespace_id \"$A4\", which is not a namespace token"
    printf '%s' "$A8" | grep -qE '^[0-9]+$'                     || viol "ANCHOR-SCHEMA  $A1 declares version \"$A8\", which is not a number — supersession is ordered, so the order has to be readable"
    printf '%s' "$A9" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' || viol "ANCHOR-SCHEMA  $A1 declares created_at \"$A9\", which is not a date"

    # RULE 2, BOTH DIRECTIONS. One id may name only one object, and one content
    # site may host only one object: an anchor two objects answer to is not
    # stable, and one site with two object names is the duplicate-semantic-truth
    # class this tree already registers.
    if in_list "$A1" "$seen_ids"; then
      viol "ANCHOR-COLLISION $A1 is declared more than once. Two different objects cannot claim the same stable anchor; the id IS the identity."
    else
      seen_ids="$seen_ids $A1"
    fi
    key="$A4/$A2@$A8"
    if in_list "$key" "$seen_obj"; then
      viol "ANCHOR-COLLISION $A1 re-declares $key, which another anchor already owns. One object at one version has one anchor."
    else
      seen_obj="$seen_obj $key"
    fi
    key="$A6>$A7"
    if printf '%s\n' "$seen_site" | grep -qxF "$key<$A2"; then
      : # the same object anchored twice at one site across versions is legal
    elif printf '%s\n' "$seen_site" | grep -qF "$key<"; then
      viol "ANCHOR-SITE-COLLISION $A1 anchors $A2 at a content site another object already claims in $A6. A site that names two objects identifies neither."
    fi
    seen_site="$seen_site
$key<$A2"

    # RULE 5 and RULE 7. A supersedes link is history: it must name a record
    # that exists, may not name itself, and may not be claimed twice, because a
    # retired object with two successors has no successor.
    if [ "$A10" != "-" ]; then
      if [ "$A10" = "$A1" ]; then
        viol "ANCHOR-SUPERSEDE $A1 supersedes itself, which records nothing."
      elif ! anc_rec "$A10" >/dev/null; then
        viol "ANCHOR-SUPERSEDE $A1 supersedes \"$A10\", which this table does not declare. History cannot point at a record that was never written."
      elif in_list "$A10" "$seen_sup"; then
        viol "ANCHOR-SUPERSEDE $A10 is superseded by more than one anchor. A retired object with two successors has none."
      fi
      seen_sup="$seen_sup $A10"
    fi
  done

  # RULE 1 and RULE 5. Every LIVE anchor must resolve BY CONTENT; a SUPERSEDED
  # one is exempt, because the whole point of superseding it is that its content
  # is gone and its record survives anyway.
  ANC_RESOLVED=0; ANC_SUPERSEDED=0
  for r in "${ANC_RECS[@]}"; do
    [ "$(anc_nf "$r")" = "10" ] || continue
    anc_split "$r"; aid="$A1"; art="$A6"; cref="$A7"
    if key="$(anc_superseded_by "$aid")"; then
      ANC_SUPERSEDED=$((ANC_SUPERSEDED+1))
      [ "${ANC_LIST:-0}" = "1" ] && printf 'anchor: %s type=%s object=%s at=%s:- status=SUPERSEDED by=%s\n' "$aid" "$A3" "$A2" "$art" "$key"
      continue
    fi
    if line="$(anchor_resolve "$art" "$cref")"; then
      ANC_RESOLVED=$((ANC_RESOLVED+1))
      [ "${ANC_LIST:-0}" = "1" ] && printf 'anchor: %s type=%s object=%s at=%s:%s status=RESOLVED\n' "$aid" "$A3" "$A2" "$art" "$line"
    else
      [ "${ANC_LIST:-0}" = "1" ] && printf 'anchor: %s type=%s object=%s at=%s:- status=UNRESOLVED\n' "$aid" "$A3" "$A2" "$art"
      viol "ANCHOR-UNRESOLVED $aid ($line). An anchor that resolves to nothing is a name for an object nobody can reach, and no superseding record explains where it went."
    fi
  done
  return 0
}

# Print one record in full, resolved. RULE 7 lives here: a superseded anchor
# returns ITS OWN version and ITS OWN content ref and names its successor,
# instead of quietly becoming it.
anchors_show(){ # <record>
  local by line
  anc_split "$1"
  by="$(anc_superseded_by "$A1" || true)"
  printf 'anchor_id: %s\nobject_id: %s\nobject_type: %s\nnamespace_id: %s\nsemantic_role: %s\nartifact_ref: %s\ncontent_or_symbol_ref: %s\nversion: %s\ncreated_at: %s\nsupersedes: %s\nsuperseded_by: %s\n' \
    "$A1" "$A2" "$A3" "$A4" "$A5" "$A6" "$A7" "$A8" "$A9" "$A10" "${by:--}"
  if [ -n "$by" ]; then printf 'resolved_line: -\nstatus: SUPERSEDED\n'; return 0; fi
  if line="$(anchor_resolve "$A6" "$A7")"; then
    printf 'resolved_line: %s\nprojection: %s:%s#%s\nstatus: RESOLVED\n' "$line" "$A6" "$line" "$A1"
    return 0
  fi
  printf 'resolved_line: -\nstatus: UNRESOLVED — %s\n' "$line"
  return 1
}

# The object_id of a record, without splitting it — used while A1..A10 are
# being reused by an inner loop.
anc_f_obj(){ local o="${1#*|}"; printf '%s' "${o%%|*}"; }

# Validate a WRITTEN reference. THE TWO HALVES ARE GRADED SEPARATELY AND THE
# OUTPUT SAYS SO, because the finding this packet exists for is that a reference
# can be syntactically perfect and still name the wrong thing.
anchors_validate(){ # <reference>
  local ref="$1" pos aid rec rf rl art cref line other r oline
  printf 'reference: %s\n' "$ref"
  case "$ref" in
    *'#'*) pos="${ref%%#*}"; aid="${ref##*#}" ;;
    *)     printf 'syntactic: OK — the string parses as a position\n'
           printf 'identity: REJECTED — NO-ANCHOR. "%s" carries a position and no anchor token. A position is a NAVIGATION HINT, not an identity, and it is the exact form every drifted citation in residue (mm) was written in.\n' "$ref"
           viol "NO-ANCHOR   the reference \"$ref\" carries no anchor token"
           return 1 ;;
  esac
  rf="${pos%%:*}"; rl="${pos#*:}"; [ "$rl" = "$pos" ] && rl=""
  # The positional predicates sections 6 and 23 already own, evaluated FIRST and
  # reported whatever the identity verdict turns out to be.
  if [ -n "$rf" ] && [ -f "$ANC_REPO/$rf" ]; then
    if [ -z "$rl" ]; then
      printf 'syntactic: OK — %s exists and the reference names no line\n' "$rf"
    elif printf '%s' "$rl" | grep -qE '^[0-9]+$' && [ "$rl" -ge 1 ] && [ "$rl" -le "$(grep -c '' "$ANC_REPO/$rf")" ]; then
      printf 'syntactic: OK — %s exists and line %s is inside it\n' "$rf" "$rl"
    else
      printf 'syntactic: FAIL — "%s" does not name a line inside %s\n' "$rl" "$rf"
    fi
  else
    printf 'syntactic: FAIL — %s is not a file under %s\n' "$rf" "$ANC_REPO"
  fi
  if ! rec="$(anc_rec "$aid")"; then
    printf 'identity: REJECTED — UNKNOWN-ANCHOR. "%s" is a well-formed anchor token that this table does not declare. Resolving syntactically is not resolving TO SOMETHING.\n' "$aid"
    viol "UNKNOWN-ANCHOR the reference \"$ref\" names an anchor the table does not declare"
    return 1
  fi
  anc_split "$rec"; art="$A6"; cref="$A7"
  printf 'anchor_id: %s\nobject_id: %s\ncontent_or_symbol_ref: %s\n' "$A1" "$A2" "$cref"
  if [ "$rf" != "$art" ]; then
    printf 'identity: REJECTED — WRONG-ARTIFACT. The reference names %s; %s is anchored in %s.\n' "$rf" "$aid" "$art"
    viol "WRONG-ARTIFACT the reference \"$ref\" names an artifact the anchor does not live in"
    return 1
  fi
  if ! line="$(anchor_resolve "$art" "$cref")"; then
    printf 'identity: REJECTED — UNRESOLVED-ANCHOR. %s\n' "$line"
    viol "UNRESOLVED-ANCHOR the reference \"$ref\" names an anchor that no longer resolves"
    return 1
  fi
  printf 'identity: OK — %s resolves to %s at :%s\n' "$aid" "$A2" "$line"
  if [ -n "$rl" ] && [ "$rl" != "$line" ]; then
    # RULE 3. A hint that has merely gone stale is REPORTED. A hint that lands
    # on the anchored site of a DIFFERENT object is REFUSED, because that is the
    # case where a reader follows the number, finds something real, and believes
    # it — the one failure mode a resolvability check can never catch.
    other=""
    for r in "${ANC_RECS[@]}"; do
      [ "$(anc_nf "$r")" = "10" ] || continue
      anc_split "$r"
      [ "$A6" = "$art" ] || continue
      [ "$A2" = "$(anc_f_obj "$rec")" ] && continue
      oline="$(anchor_resolve "$A6" "$A7")" || continue
      [ "$oline" = "$rl" ] && { other="$A1"; break; }
    done
    if [ -n "$other" ]; then
      printf 'hint: REJECTED — WRONG-OBJECT. Line %s of %s currently resolves, and what it resolves to is the anchored site of %s, a DIFFERENT object. The reference is readable, checkable and wrong.\n' "$rl" "$art" "$other"
      viol "WRONG-OBJECT the reference \"$ref\" points at a line that is the anchored site of $other"
      return 1
    fi
    printf 'hint: HINT-STALE — the reference says :%s and the anchor resolves at :%s. A line number is a navigation hint, so this is REPORTED and not refused; the identity was never in the number.\n' "$rl" "$line"
    printf 'projection: %s:%s#%s\n' "$art" "$line" "$aid"
    return 0
  fi
  printf 'hint: OK — :%s is where the anchor resolves\n' "$line"
  printf 'projection: %s:%s#%s\n' "$art" "$line" "$aid"
  return 0
}

if [ "$CMD" = "anchors" ]; then
  if [ "$APROJECT" = "1" ]; then
    # RULE 4. The projection is GENERATED from identity, so it carries identity.
    # A projection reduced to `path:line` has thrown away the only part of
    # itself that could still be right tomorrow.
    for arec in "${ANC_RECS[@]}"; do
      [ "$(anc_nf "$arec")" = "10" ] || continue
      anc_split "$arec"
      anc_superseded_by "$A1" >/dev/null && continue
      aline="$(anchor_resolve "$A6" "$A7")" || continue
      printf '%s:%s#%s\n' "$A6" "$aline" "$A1"
    done
    exit 0
  fi
  if [ -n "$AREF" ]; then
    case "$AREF" in
      *'#'*|*:*) anchors_validate "$AREF" || true ;;
      *) if arec="$(anc_rec "$AREF")"; then anchors_show "$arec" || true
         else printf 'reference: %s\nidentity: REJECTED — UNKNOWN-ANCHOR. This table declares no anchor by that name.\n' "$AREF"; viol "UNKNOWN-ANCHOR \"$AREF\""; fi ;;
    esac
    [ "$VIOL" -gt 0 ] && { printf 'scan-controls: REFUSED — %s anchor violation(s).\n' "$VIOL" >&2; exit 2; }
    exit 0
  fi
  printf 'scan-controls: anchor table — %s record(s), %s declared object type(s), resolved against %s\n' \
    "${#ANC_RECS[@]}" "$(printf '%s\n' $ANCHOR_TYPES | grep -c .)" "$ANC_REPO"
  ANC_LIST=1 anchors_check
  printf 'scan-controls: %s anchor(s) resolved, %s superseded (history, not resolution), %s violation(s)\n' \
    "$ANC_RESOLVED" "$ANC_SUPERSEDED" "$VIOL"
  [ "$VIOL" -gt 0 ] && { printf 'scan-controls: REFUSED — %s anchor violation(s). An anchor is the identity of an object; a table that does not validate is a set of names for things nobody can reach.\n' "$VIOL" >&2; exit 2; }
  exit 0
fi
# ...and on the `check` path the same validation GATES, because an anchor table
# checked only when somebody asks is the shelfware this module's header is about.
anchors_check
printf 'scan-controls: %s anchor(s) resolved, %s superseded, over %s record(s) in %s declared object type(s)\n' \
  "$ANC_RESOLVED" "$ANC_SUPERSEDED" "${#ANC_RECS[@]}" "$(printf '%s\n' $ANCHOR_TYPES | grep -c .)"
# ============================================================ END ANCHOR-BLOCK

if [ "$VIOL" -gt 0 ]; then
  printf 'scan-controls: REFUSED — %s violation(s) reconciling %s against %s.\n' "$VIOL" "$REGISTRY" "$REPO" >&2
  printf 'Do NOT clear a LAUNDERED violation by changing the class. Changing what a control is\nclassified as, to make its authority legal, is the single failure this registry exists\nto prevent; changing the AUTHORITY is a governance action and belongs to the operator.\n' >&2
  exit 2
fi
exit 0
