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
#   scan-controls.sh patterns
# Exit: 0 reconciled, 2 refused (a violation, or a scan that cannot be trusted).
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"
REGISTRY=""
MISMATCHES=""
TAB=$'\t'

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
  surfaces|check|patterns) ;;
  -h|--help|help) sed -n '2,66p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") refuse "no command — expected one of: surfaces, check, patterns" ;;
  *)  refuse "unknown command \"$CMD\" — expected one of: surfaces, check, patterns" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)       [ $# -ge 2 ] || refuse "--repo needs a value";       REPO="$2"; shift 2 ;;
    --registry)   [ $# -ge 2 ] || refuse "--registry needs a value";   REGISTRY="$2"; shift 2 ;;
    --mismatches) [ $# -ge 2 ] || refuse "--mismatches needs a value"; MISMATCHES="$2"; shift 2 ;;
    -h|--help)    sed -n '2,66p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done
[ -n "$REGISTRY" ]   || REGISTRY="$SELF_DIR/control_registry.txt"
[ -n "$MISMATCHES" ] || MISMATCHES="$SELF_DIR/MISMATCHES.md"

# --- the ontology, as this scanner enforces it -------------------------------
CLASSES="R A B C D"
IMPL_STATUSES="specified implemented runtime_observed decision_contributing load_bearing"
EMP_STATUSES="unvalidated red_driven field_observed calibrated refuted"
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

if [ "$VIOL" -gt 0 ]; then
  printf 'scan-controls: REFUSED — %s violation(s) reconciling %s against %s.\n' "$VIOL" "$REGISTRY" "$REPO" >&2
  printf 'Do NOT clear a LAUNDERED violation by changing the class. Changing what a control is\nclassified as, to make its authority legal, is the single failure this registry exists\nto prevent; changing the AUTHORITY is a governance action and belongs to the operator.\n' >&2
  exit 2
fi
exit 0
