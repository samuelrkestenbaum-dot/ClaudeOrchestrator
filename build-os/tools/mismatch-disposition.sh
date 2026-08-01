#!/usr/bin/env bash
# Build OS — mismatch dispositions: what the operator DECIDED about a control
# that exercises more authority than its class licenses.
#
# THE GAP THIS CLOSES. `MISMATCHES.md` names four things an operator may do
# about a declared mismatch — DEMOTE THE AUTHORITY, CORRECT THE CLASS, IMPROVE
# THE EVIDENCE, RETIRE THE CONTROL — and `maint.source_scan_mask`'s own registry
# entry records, in its own words, that ALL FOUR were closed to it. There was no
# fifth. A control whose every prescribed remedy is unreachable had nowhere to be
# recorded except as a mismatch nobody was doing anything about, which is
# indistinguishable in the report from a mismatch nobody had got to yet.
#
# `accept_and_constrain` IS THE FIFTH, AND IT IS NOT AN EXCEPTION. It is for a
# control whose authority is imperfectly licensed and whose DEMOTION OR REMOVAL
# HAS BEEN MEASURED TO BE MORE DANGEROUS THAN THE MISMATCH. "Measured" is the
# load-bearing word and it is checked rather than believed:
#
#   `maint.tripwire_coverage_scan` gates on a heuristic. The obvious demotion —
#   collect the coverage findings and print them instead of throwing — was
#   APPLIED LITERALLY AND MEASURED, in COVERAGE-GATE-PREVENTION-DIFFERENTIAL.
#   Gated, the run exits 1 and the tree is UNTOUCHED. Demoted, the run exits 1
#   and LIVE MEMORY IS DESTROYED. THE EXIT CODE IS 1 IN BOTH ARMS, so nothing
#   watching exit codes could have seen the difference. The remedy the report
#   prescribes is the one the measurement refuses.
#
# WHAT A DISPOSITION IS NOT, stated first because every failure mode of this file
# is a reading of it as something stronger:
#
#   IT CLEARS NO MISMATCH. The subject keeps `authority_mismatch: declared`, keeps
#   its row in the MISMATCHES.md summary table, and keeps its OUT-OF-LICENCE
#   finding from `evidence-policy.sh check`. A disposition RECORDS that a mismatch
#   is being CARRIED, NAMES the constraint that bounds it, and KEEPS IT VISIBLE.
#   Nothing here edits the census, the report, or any licence.
#
#   IT RAISES NO AUTHORITY. The standing ruling is unchanged: this machinery is
#   for CLASS CORRECTION AND AUTHORITY DEMOTION, and it is not a promotion
#   instrument. There is no rung in this file, no ladder, and no composition. A
#   disposition cannot move a control up, because it cannot move a control.
#
#   IT IS NOT AN OPERATOR EXCEPTION. An exception makes a finding go away; a
#   disposition makes a finding legible. The difference is checkable, and it is
#   checked: `tests/mismatch_disposition_tests.sh` §5 asserts all three of the
#   "still" properties above against the LIVE tree, so a later edit that quietly
#   clears the mismatch fails there rather than passing as tidying.
#
# ---------------------------------------------------------------------------
# THE QUALIFICATION PREDICATE, AND WHY IT HAS FIVE CONDITIONS AND NOT ONE
# ---------------------------------------------------------------------------
# The operator's ruling was explicit: do not bulk-apply this. Two maintenance
# controls sit beside each other in the census and only one qualifies —
#
#   maint.tripwire_coverage_scan   demotion_requirement: "MEASURED AND REFUSED,
#                                  not open"                        QUALIFIES
#   maint.source_scan_mask         demotion_requirement: "REACHABLE SINCE THE
#                                  LADDER WAS CORRECTED", and
#                                  `authority_mismatch: none`       REFUSED
#
# — and a predicate that cannot tell those two apart is not a predicate. All five
# conditions must hold, each of them independently falsifiable:
#
#   (0) THE MEASUREMENT IS NAMED LIKE AN IDENTIFIER. Checked before (c) and (d),
#       because both of those are SUBSTRING tests and a token short or common
#       enough is a substring of the corpus by accident: the literal `the`
#       satisfies (c) against almost any `demotion_requirement` and (d) against
#       almost any file, certifying a "measurement" neither condition ever
#       looked at. An anchored shape removes that class of token. It cannot tell
#       a real measurement from an invented one and does not claim to.
#   (a) THERE IS A MISMATCH TO CARRY. The census must record
#       `authority_mismatch: declared` for the subject. `accept_and_constrain`
#       carries a mismatch; it does not invent one, and a control in licence has
#       nothing to be carried.
#   (b) THE CARRIED MISMATCH STAYS VISIBLE. The subject must hold a row in
#       MISMATCHES.md's machine-read summary table. A mismatch that reaches no
#       report is a cleared one however this store describes it.
#   (c) THE MEASUREMENT IS THE CENSUS'S RECORD, NOT THIS STORE'S ASSERTION. The
#       `demotion_measurement` named here must appear VERBATIM in the subject's
#       own `demotion_requirement` field. This store may not assert a measurement
#       into existence on a control whose census entry says the demotion is open.
#   (d) THE MEASUREMENT EXISTS AS AN ARTEFACT. The same token must occur
#       somewhere under the repository OTHER than the two records that cite it.
#       Without (d), (c) degrades into two documents agreeing with each other,
#       which is how "measured" becomes a word rather than a fixture.
#
# THE REFUSAL SAYS WHY, AND SAYS IT IN THE CENSUS'S WORDS. When a subject fails
# (c) the tool QUOTES the subject's own `demotion_requirement` rather than
# restating a reason here — so a reviewer refused on `maint.source_scan_mask`
# reads "REACHABLE SINCE THE LADDER WAS CORRECTED" from the artefact that says
# it, and the tool is not carrying a second opinion about a control it does not
# own.
#
# ---------------------------------------------------------------------------
# THE REVIEW DATE, AND WHY IT REPORTS WHERE THE ENVELOPE REFUSES
# ---------------------------------------------------------------------------
# Every disposition carries a `review_by`, and a carried mismatch past its review
# date is named REVIEW-DUE. It is REPORTED and does NOT refuse, and the asymmetry
# against `authority-envelope.sh` — which drops an out-of-window GRANT — is
# deliberate:
#
#   AN ENVELOPE IS A PERMISSION. When the lease ends the permission ends, so the
#   grant must stop applying; keeping it would be authority nobody renewed.
#   A DISPOSITION IS A RECORD OF A DECISION TO CARRY. What lapses is the REVIEW,
#   not the decision. Dropping the record would delete the note that a mismatch
#   is being carried and make the carried mismatch LESS VISIBLE — the opposite of
#   what the record exists for.
#
# That is the same rule read twice: an expired thing keeps applying in whichever
# direction it pointed, so each artefact is corrected in the direction that
# costs. The clock itself is SOURCED from `authority-envelope.sh now`, which owns
# the only clock in this repository; a second private `date` call here is how an
# override gets honoured in one tool and silently ignored in another.
#
# Local only. Reads files and prints. Writes nothing, anywhere.
#
# Usage:
#   mismatch-disposition.sh schema
#   mismatch-disposition.sh list     [--store F] [--subject ID]
#   mismatch-disposition.sh validate [--store F] [--registry F] [--mutators F] [--mismatches F]
#   mismatch-disposition.sh check    [--store F] [--registry F] [--mismatches F]
# Env:
#   BUILD_OS_NOW=YYYY-MM-DD  pin the clock, via authority-envelope.sh.
# Exit: 0 the command ran (whatever it FOUND — check advises);
#       2 the invocation is malformed, or the store could not be trusted.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"
STORE=""
REGISTRY=""
MUTATORS=""
MISMATCHES=""
SUBJECT=""

refuse(){ printf 'mismatch-disposition: REFUSED — %s\n' "$*" >&2; exit 2; }

# --- the vocabulary, declared exactly once -----------------------------------
# THE FIVE DISPOSITIONS. The first four are the remedies MISMATCHES.md has always
# named; the fifth is the one this file adds. Any file anywhere under
# build-os/tools, build-os/registry or tests/ that restates ANY of them must
# restate ALL of them — swept as a class by §8 of the suite, because a vocabulary
# spelled in a tool, a store comment, a report and a test gets updated in one copy
# and left short in another. That is exactly how the last packet shipped a live
# over-grant inside the over-grant detector.
DISPOSITION_KINDS="demote_authority correct_class improve_evidence retire_control accept_and_constrain"
# THE SCHEMA — fourteen required fields, in record order. `disposition` is the id
# line and opens a record. All are REQUIRED and none has a default: a field that
# may be omitted is a field a reader cannot tell apart from one nobody thought
# about, and where there is genuinely nothing to say the value is the word for
# nothing.
DISP_FIELDS="subject_id kind mismatch_summary alternatives_considered demotion_measurement measured_harm constraint constraint_enforced_by visibility recorded_at recorded_by reviewed_by review_by supersedes"
# CONSTRAINT FILLERS THAT MEAN "NOTHING". Refused by name: an
# `accept_and_constrain` with no constraint is the operator exception this
# disposition exists not to be, spelled as a disposition.
CONSTRAINT_FILLERS="n/a none unknown any all - open tbd nothing"
DISP_ID_RE='^DISP-[0-9]{4}(-[a-z0-9][a-z0-9-]*)?$'
# THE MEASUREMENT ID MUST LOOK LIKE AN ID, and this is condition (0) below.
# Conditions (c) and (d) are both SUBSTRING tests, and a token short and common
# enough is a substring of everything. The literal `the` is inside almost every
# `demotion_requirement` in the census, satisfying (c), and inside almost every
# file in the tree, satisfying (d) — so a one-word `demotion_measurement`
# certified "a MEASURED and refused demotion recorded in the census and existing
# as an artefact" without either test looking at anything. That is exactly the
# failure (d) was written to prevent, arrived at through (d) rather than around
# it: two substring matches agreeing with each other is how "measured" becomes a
# word rather than a fixture.
#
# The shape is anchored, and it is honest about what it is: it CANNOT tell a real
# measurement from an invented one. It removes the class of token that matches
# the corpus BY ACCIDENT — an id that is 8+ characters of upper-case, digits and
# hyphens is not a word anyone writes by chance, so (c) and (d) go back to
# testing what they claim. `COVERAGE-GATE-PREVENTION-DIFFERENTIAL`, the one live
# measurement, satisfies it.
MEASUREMENT_ID_RE='^[A-Z][A-Z0-9-]{7,}$'

in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }

# --- the clock, SOURCED and never computed -----------------------------------
ENVTOOL="$SELF_DIR/authority-envelope.sh"
NOW=""; NOW_SOURCE=""
load_clock(){
  local o
  [ -n "$NOW" ] && return 0
  [ -x "$ENVTOOL" ] || refuse "no clock at $ENVTOOL. Review dates are judged against a date, and deriving one here would be a second private clock — the way an override is honoured in one tool and ignored in another."
  o="$("$ENVTOOL" now 2>&1)" || refuse "\`authority-envelope.sh now\` failed; the date every \`review_by\` is judged against is unknown, and an unknown clock must never fall back to \"today\"."
  NOW="$(printf '%s\n' "$o" | awk '$1=="now:"{print $2; exit}')"
  NOW_SOURCE="$(printf '%s\n' "$o" | sed -n 's/^source: //p' | head -1)"
  case "$NOW" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) refuse "the clock printed \"$NOW\", which is not YYYY-MM-DD." ;;
  esac
}

CMD="${1:-}"
[ $# -gt 0 ] && shift
case "$CMD" in
  schema|list|validate|check) ;;
  -h|--help|help) sed -n '2,115p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") refuse "no command — expected one of: schema, list, validate, check" ;;
  *)  refuse "unknown command \"$CMD\" — expected one of: schema, list, validate, check" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)       [ $# -ge 2 ] || refuse "--repo needs a value";       REPO="$2"; shift 2 ;;
    --store)      [ $# -ge 2 ] || refuse "--store needs a value";      STORE="$2"; shift 2 ;;
    --registry)   [ $# -ge 2 ] || refuse "--registry needs a value";   REGISTRY="$2"; shift 2 ;;
    --mutators)   [ $# -ge 2 ] || refuse "--mutators needs a value";   MUTATORS="$2"; shift 2 ;;
    --mismatches) [ $# -ge 2 ] || refuse "--mismatches needs a value"; MISMATCHES="$2"; shift 2 ;;
    --subject)    [ $# -ge 2 ] || refuse "--subject needs a value";    SUBJECT="$2"; shift 2 ;;
    -h|--help)    sed -n '2,115p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done
[ -n "$STORE" ]      || STORE="$REPO/build-os/registry/mismatch_dispositions.txt"
[ -n "$REGISTRY" ]   || REGISTRY="$REPO/build-os/registry/control_registry.txt"
[ -n "$MUTATORS" ]   || MUTATORS="$REPO/build-os/registry/mutator_registry.txt"
[ -n "$MISMATCHES" ] || MISMATCHES="$REPO/build-os/registry/MISMATCHES.md"

# --------------------------------------------------------------- schema ------
if [ "$CMD" = "schema" ]; then
  printf 'schema: mismatch-disposition-v1 — one record per DECISION about one declared authority mismatch\n'
  printf 'key: disposition — the record key IS the disposition_id, a %s stable id; there is no second field repeating it\n' 'DISP-NNNN[-slug]'
  printf 'vocabulary: disposition_kind %s\n' "$DISPOSITION_KINDS"
  printf 'kind: demote_authority — lower the control'"'"'s runtime_authority to what its class licenses. The default remedy, and the one every other row is measured against.\n'
  printf 'kind: correct_class — the classification was wrong, not the authority. Re-classify, and be ready to say why the thresholds are not a heuristic.\n'
  printf 'kind: improve_evidence — the authority is defensible once the evidence supports it. Measure, then re-derive.\n'
  printf 'kind: retire_control — the control should not exist. Remove it and whatever consumes it.\n'
  printf 'kind: accept_and_constrain — the mismatch is CARRIED, because demotion or removal has been MEASURED to be more dangerous than the mismatch. It clears nothing, names the constraint that bounds it, and keeps the finding visible. Five conditions, all required — see the `qualification:` rows.\n'
  for f in $DISP_FIELDS; do
    case "$f" in
      kind)          printf 'field: %s required — one of the vocabulary above. An unrecognised kind is REFUSED and never defaulted.\n' "$f" ;;
      constraint)    printf 'field: %s required — WHAT BOUNDS THE CARRIED MISMATCH. The fillers that mean nothing (%s) are refused: an unconstrained accept_and_constrain is an operator exception wearing a disposition.\n' "$f" "$CONSTRAINT_FILLERS" ;;
      demotion_measurement) printf 'field: %s required — the id of the MEASUREMENT that closed the demotion, or the word for nothing. For accept_and_constrain it must appear in the subject'"'"'s own `demotion_requirement` AND as an artefact in the tree.\n' "$f" ;;
      review_by)     printf 'field: %s required — YYYY-MM-DD, strictly after `recorded_at`. A carried mismatch with no review date is a permanent one.\n' "$f" ;;
      supersedes)    printf 'field: %s required — `none`, or the %s id this record replaces. The only reference between records.\n' "$f" 'DISP-NNNN' ;;
      *)             printf 'field: %s required\n' "$f" ;;
    esac
  done
  printf 'qualification: (0) the `demotion_measurement` has the SHAPE of an identifier (%s) — upper-case, digits and hyphens, 8 or more characters. Checked FIRST, because (c) and (d) are SUBSTRING tests and a degenerate one-word token satisfies both by accident, certifying a measurement neither test ever looked at.\n' "$MEASUREMENT_ID_RE"
  printf 'qualification: (a) the census records `authority_mismatch: declared` for the subject — accept_and_constrain CARRIES a mismatch and does not invent one\n'
  printf 'qualification: (b) the subject holds a row in MISMATCHES.md'"'"'s machine-read summary table — a carried mismatch that reaches no report is a cleared one\n'
  printf 'qualification: (c) the `demotion_measurement` appears VERBATIM in the subject'"'"'s own `demotion_requirement` — the measurement is the census'"'"'s record, not this store'"'"'s assertion\n'
  printf 'qualification: (d) that same token occurs as an ARTEFACT elsewhere under the repository — without it, (c) is two documents agreeing with each other\n'
  printf 'rule: a disposition CLEARS NO MISMATCH. The subject keeps `authority_mismatch: declared`, keeps its row in the report, and keeps its out-of-licence finding. This records that a mismatch is CARRIED and names what bounds it.\n'
  printf 'rule: a disposition RAISES NO AUTHORITY. There is no ladder and no composition in this file: the standing ruling is class correction and authority demotion, and this is not a promotion instrument.\n'
  printf 'rule: one LIVE disposition per subject. A control disposed two ways at once is a decision nobody took; replacing one is what `supersedes` is for.\n'
  printf 'rule: a `review_by` in the past is REPORTED (REVIEW-DUE) and never refused. Deleting the record would make the CARRIED MISMATCH LESS VISIBLE, which is the opposite of what it exists for — unlike an authority envelope, where an ended lease must stop granting.\n'
  printf 'source: the clock is read from `authority-envelope.sh now`, which owns the only clock in this repository. This file computes no date.\n'
  exit 0
fi

# --- the parser, used by list / validate / check ------------------------------
FLAT="$(mktemp)"; PROBLEMS="$(mktemp)"
trap 'rm -f "$FLAT" "$PROBLEMS"' EXIT

parse_store(){
  [ -f "$STORE" ] || refuse "no disposition store at $STORE. There is nothing to derive from, and an absent store is not an empty one: reading a missing file as \"nothing is disposed\" answers a question nobody asked."
  awk '
    /^#/ { next }
    /^[[:space:]]*$/ { cur=""; next }
    /^disposition: / {
      cur=substr($0,14)
      if (cur in SEEN) { printf "PROBLEM\t%s\tkey\tis used by more than one stanza; a duplicate id resolves to whichever stanza a reader hits first\n", cur }
      SEEN[cur]=1
      printf "ORDER\t%s\n", cur
      next
    }
    {
      if (cur == "") { printf "PROBLEM\t(preamble)\t%s\tappears before any `disposition:` key\n", $0; next }
      if ($0 !~ /^[a-z_]+: /) {
        if ($0 ~ /^[a-z_]+:$/) { k=$0; sub(/:$/,"",k); printf "FIELD\t%s\t%s\t\n", cur, k; next }
        printf "PROBLEM\t%s\t(line)\t\"%s\" is not a `key: value` line\n", cur, $0; next
      }
      k=$0; sub(/: .*$/,"",k); v=$0; sub(/^[a-z_]+: /,"",v)
      printf "FIELD\t%s\t%s\t%s\n", cur, k, v
    }
  ' "$STORE" > "$FLAT"
  # The id shape, checked by grep -E rather than awk: mawk cannot compile an
  # interval expression supplied as a dynamic regex and panics on it, which would
  # take the whole parse to zero records because of the guard's own portability.
  awk -F'\t' '$1=="ORDER"{print $2}' "$FLAT" | while IFS= read -r _id; do
    printf '%s\n' "$_id" | grep -qE "$DISP_ID_RE" \
      || printf 'PROBLEM\t%s\tkey\tis not a DISP-NNNN[-slug] stable id\n' "$_id"
  done >> "$FLAT"
}

ids(){ awk -F'\t' '$1=="ORDER"{print $2}' "$FLAT"; }
gv(){ awk -F'\t' -v i="$1" -v f="$2" '$1=="FIELD" && $2==i && $3==f {print $4; exit}' "$FLAT"; }
has(){ awk -F'\t' -v i="$1" -v f="$2" '$1=="FIELD" && $2==i && $3==f {n=1} END{exit !n}' "$FLAT"; }

# --- the census and the report, read rather than restated ---------------------
reg_field(){ # <control-id> <field>
  awk -v i="$1" -v f="$2" '$0=="control: "i{r=1;next} /^$/{r=0} r && index($0,f": ")==1 {print substr($0,length(f)+3); exit}' "$REGISTRY"
}
# The ids MISMATCHES.md's machine-read summary table names, parsed exactly as
# scan-controls.sh §8 parses them — one reader would be better, and until there
# is one this must at least agree with the reader that gates.
reported_ids(){
  awk '
    /<!-- MISMATCH-TABLE:START -->/{f=1; next}
    /<!-- MISMATCH-TABLE:END -->/{f=0}
    f && /^\|[[:space:]]*`/ { l=$0; sub(/^\|[[:space:]]*`/,"",l); sub(/`.*$/,"",l); if (l != "") print l }
  ' "$MISMATCHES" 2>/dev/null
}
# Does the measurement token exist as an ARTEFACT anywhere other than the two
# records that cite it? Without this, condition (c) is two documents agreeing.
measurement_artefact(){ # <token>
  grep -rlF --exclude-dir=.git -- "$1" "$REPO" 2>/dev/null \
    | grep -vxF "$STORE" | grep -vxF "$REGISTRY" | grep -vxF "$MISMATCHES" \
    | grep -q .
}

# --------------------------------------------------------------- validate ----
if [ "$CMD" = "validate" ]; then
  load_clock
  parse_store
  : > "$PROBLEMS"
  awk -F'\t' '$1=="PROBLEM"{printf "%s: %s %s\n", $2, $3, $4}' "$FLAT" >> "$PROBLEMS"
  NID="$(ids | grep -c . || true)"; NID="${NID:-0}"
  # VACUITY. A store that parses to zero dispositions is not a clean one; it is
  # what a store looks like the day after somebody renamed the key. Reporting "0
  # problems" for it would be a false all-clear with a green tick on it.
  if [ "$NID" -eq 0 ] && [ ! -s "$PROBLEMS" ]; then
    refuse "$STORE parses to 0 dispositions. A schema check with nothing to check passes for every store, including one somebody emptied, so this refuses instead of printing zero."
  fi
  [ -f "$REGISTRY" ]   || refuse "no control registry at $REGISTRY. Every subject must resolve to a registered control and every qualification is composed against the census; a check that reads no census certifies every subject."
  [ -f "$MISMATCHES" ] || refuse "no mismatch report at $MISMATCHES. A carried mismatch has to stay visible where a reviewer reads it, and a visibility check with no report to read certifies every disposition."

  SUPERSEDED="$(awk -F'\t' '$1=="FIELD" && $3=="supersedes" && $4!="none"{print $4}' "$FLAT" | sort -u)"
  REPORTED="$(reported_ids)"
  SEENSUBJ=""
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    for f in $DISP_FIELDS; do
      if ! has "$id" "$f"; then
        printf '%s: field `%s` is absent. Every field is required and none has a default; where there is nothing to say, the value is the word for nothing.\n' "$id" "$f" >> "$PROBLEMS"
      elif [ -z "$(gv "$id" "$f")" ]; then
        printf '%s: field `%s` is EMPTY. Empty is an absence and `none` is a value; they are different.\n' "$id" "$f" >> "$PROBLEMS"
      fi
    done
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      in_list "$f" "$DISP_FIELDS" \
        || printf '%s: unknown field `%s`. The schema is closed; a typo that is ignored is a value silently lost.\n' "$id" "$f" >> "$PROBLEMS"
    done < <(awk -F'\t' -v i="$id" '$1=="FIELD" && $2==i{print $3}' "$FLAT")
    DUPF="$(awk -F'\t' -v i="$id" '$1=="FIELD" && $2==i{print $3}' "$FLAT" | sort | uniq -d)"
    [ -n "$DUPF" ] && printf '%s: field(s) stated twice: %s. Two values for one field is two decisions wearing one id.\n' "$id" "$(printf '%s' "$DUPF" | tr '\n' ' ')" >> "$PROBLEMS"

    kind="$(gv "$id" kind)"
    if [ -n "$kind" ] && ! in_list "$kind" "$DISPOSITION_KINDS"; then
      printf '%s: kind `%s` is not one of: %s. An unrecognised disposition must never fall through to accepted, because a kind nothing recognises is a decision nobody can audit.\n' "$id" "$kind" "$DISPOSITION_KINDS" >> "$PROBLEMS"
    fi

    con="$(gv "$id" constraint)"
    if [ -n "$con" ]; then
      lcon="$(printf '%s' "$con" | tr '[:upper:]' '[:lower:]')"
      in_list "$lcon" "$CONSTRAINT_FILLERS" \
        && printf '%s: constraint `%s` means "nothing". A disposition that bounds the carried mismatch with nothing is an operator exception wearing a disposition; name what actually limits it.\n' "$id" "$con" >> "$PROBLEMS"
    fi

    ra="$(gv "$id" recorded_at)"; rb="$(gv "$id" review_by)"
    case "$ra" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) printf '%s: recorded_at `%s` is not YYYY-MM-DD.\n' "$id" "$ra" >> "$PROBLEMS" ;; esac
    case "$rb" in
      [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
        case "$ra" in
          [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
            [ "$rb" \> "$ra" ] || printf '%s: review_by (%s) does not follow recorded_at (%s). A review that never comes due is no review, and a carried mismatch with no review is a permanent one.\n' "$id" "$rb" "$ra" >> "$PROBLEMS" ;;
        esac ;;
      *) printf '%s: review_by `%s` is not YYYY-MM-DD. A carried mismatch with no review date is a permanent one.\n' "$id" "$rb" >> "$PROBLEMS" ;;
    esac

    sub="$(gv "$id" subject_id)"
    if [ -n "$sub" ]; then
      grep -qxF "control: $sub" "$REGISTRY" || { [ -f "$MUTATORS" ] && grep -qxF "control_id: $sub" "$MUTATORS"; } \
        || printf '%s: subject `%s` is in neither the control census nor the mutator census. A disposition of nothing decides nothing.\n' "$id" "$sub" >> "$PROBLEMS"
    fi

    sup="$(gv "$id" supersedes)"
    if [ -n "$sup" ] && [ "$sup" != "none" ]; then
      printf '%s\n' "$sup" | grep -qE "$DISP_ID_RE" \
        || printf '%s: supersedes `%s` is not a DISP-NNNN[-slug] stable id.\n' "$id" "$sup" >> "$PROBLEMS"
      ids | grep -qxF "$sup" \
        || printf '%s: supersedes `%s`, which is in no stanza of this store. A dangling supersession silently leaves two live dispositions.\n' "$id" "$sup" >> "$PROBLEMS"
      [ "$sup" = "$id" ] && printf '%s: supersedes itself.\n' "$id" >> "$PROBLEMS"
    fi

    # ONE LIVE DISPOSITION PER SUBJECT. A control disposed two ways at once is a
    # decision nobody took; replacing one is what `supersedes` is for.
    if ! printf '%s\n' "$SUPERSEDED" | grep -qxF "$id"; then
      case "$SEENSUBJ" in
        *"[$sub]"*) printf '%s: a second LIVE disposition for subject `%s`. A control cannot be disposed two ways at once; supersede the first instead.\n' "$id" "$sub" >> "$PROBLEMS" ;;
        *) SEENSUBJ="$SEENSUBJ[$sub]" ;;
      esac
    fi

    # ---- THE QUALIFICATION PREDICATE, for `accept_and_constrain` ONLY --------
    # The other four kinds are the remedies the report has always named and do
    # not inherit this bar: demoting a control needs no measurement that
    # demotion is safe.
    if [ "$kind" = "accept_and_constrain" ] && [ -n "$sub" ]; then
      dr="$(reg_field "$sub" demotion_requirement)"
      mm="$(reg_field "$sub" authority_mismatch)"
      meas="$(gv "$id" demotion_measurement)"
      QWHY=""
      # (a) there must BE a mismatch to carry
      if [ "$mm" != "declared" ]; then
        QWHY="$QWHY (a) the census records \`authority_mismatch: $mm\` for it, so there is no declared mismatch to carry — accept_and_constrain carries a mismatch and does not invent one;"
      fi
      # (b) the carried mismatch must stay visible where it is read
      if ! printf '%s\n' "$REPORTED" | grep -qxF "$sub"; then
        QWHY="$QWHY (b) it holds no row in ${MISMATCHES##*/}'s machine-read summary table, and a carried mismatch that reaches no report is a cleared one however this store describes it;"
      fi
      # (0) the measurement must have the SHAPE of an id before (c) and (d) can
      #     mean anything. Checked FIRST and reported on its own: a degenerate
      #     token passes (c) and (d) by being a substring of the corpus, so
      #     reporting it as a (c) or (d) failure would name the wrong defect.
      if ! printf '%s' "$meas" | grep -qE "$MEASUREMENT_ID_RE"; then
        QWHY="$QWHY (0) its \`demotion_measurement\` \"$meas\" does not have the SHAPE of a measurement identifier ($MEASUREMENT_ID_RE — upper-case, digits and hyphens, 8 or more characters). Conditions (c) and (d) below are SUBSTRING tests, and a token this short or this common is a substring of the census entry and of half the tree by accident, so both would pass without either looking at anything. An id that is not a word is what keeps \"measured\" a fixture rather than a word;"
      # (c) the measurement must be the CENSUS's record
      elif [ -z "$meas" ] || ! printf '%s' "$dr" | grep -qF -- "$meas"; then
        QWHY="$QWHY (c) its own \`demotion_requirement\` in the census does not name the measurement \"$meas\", so this store would be asserting a measurement into existence on a control whose census entry says otherwise. THE CENSUS'S OWN WORDS: \"$(printf '%s' "$dr" | cut -c1-240)\";"
      # (d) ...and the measurement must EXIST as an artefact
      elif ! measurement_artefact "$meas"; then
        QWHY="$QWHY (d) the measurement \"$meas\" occurs in no artefact under $REPO other than the two records that cite it. Without an artefact, (c) is two documents agreeing with each other, which is how \"measured\" becomes a word rather than a fixture;"
      fi
      [ -n "$QWHY" ] && printf '%s: subject `%s` DOES NOT QUALIFY for `accept_and_constrain`.%s This disposition is for a control whose demotion has been MEASURED and refused, and applying it more widely would turn a measured carry into an operator exception.\n' \
        "$id" "$sub" "${QWHY%;}" >> "$PROBLEMS"
    fi
  done < <(ids)

  NP="$(grep -c . "$PROBLEMS" || true)"; NP="${NP:-0}"
  if [ "$NP" -gt 0 ]; then
    sed 's/^/mismatch-disposition: /' "$PROBLEMS" >&2
    refuse "$NP problem(s) in $STORE (named above). None is skipped and none is defaulted: a store that quietly dropped what it could not read would certify decisions nobody parsed."
  fi
  printf 'mismatch-disposition: %s disposition(s) valid in %s (schema mismatch-disposition-v1)\n' "$NID" "$STORE"
  printf 'mismatch-disposition: every subject resolves, every kind is in the vocabulary, every constraint names something, and every `accept_and_constrain` subject carries a MEASURED and refused demotion whose id is SHAPED like one, is recorded verbatim in the census, and exists as an artefact.\n'
  exit 0
fi

# ------------------------------------------------------------------- list ----
if [ "$CMD" = "list" ]; then
  parse_store
  N=0
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    sub="$(gv "$id" subject_id)"
    [ -n "$SUBJECT" ] && [ "$sub" != "$SUBJECT" ] && continue
    N=$((N+1))
    printf 'disposition: %s subject=%s kind=%s review_by=%s supersedes=%s\n' \
      "$id" "$sub" "$(gv "$id" kind)" "$(gv "$id" review_by)" "$(gv "$id" supersedes)"
  done < <(ids)
  printf 'mismatch-disposition: %s disposition(s) listed%s\n' "$N" "${SUBJECT:+ for subject $SUBJECT}"
  exit 0
fi

# ------------------------------------------------------------------ check ----
# THIS ADVISES. It exits 0 whatever it finds. It re-authorises nothing, clears
# nothing and writes nothing.
load_clock
parse_store
[ -f "$REGISTRY" ]   || refuse "no control registry at $REGISTRY. The \"still declared\" reading below would otherwise be derived from no census, which certifies every disposition."
[ -f "$MISMATCHES" ] || refuse "no mismatch report at $MISMATCHES. The \"still visible\" reading below would otherwise be derived from no report."
NID="$(ids | grep -c . || true)"; NID="${NID:-0}"
[ "$NID" -gt 0 ] || refuse "$STORE parses to 0 dispositions. A report over no dispositions is a clean bill of health for a store nobody read."

printf 'clock: now=%s source=%s\n' "$NOW" "$NOW_SOURCE"
REPORTED="$(reported_ids)"
NAC=0; NDUE=0; NCLEARED=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  sub="$(gv "$id" subject_id)"
  [ -n "$SUBJECT" ] && [ "$sub" != "$SUBJECT" ] && continue
  kind="$(gv "$id" kind)"
  rb="$(gv "$id" review_by)"
  mm="$(reg_field "$sub" authority_mismatch)"
  vis=no; printf '%s\n' "$REPORTED" | grep -qxF "$sub" && vis=yes
  rstate=IN-WINDOW
  case "$rb" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])
      { [ "$rb" \< "$NOW" ] || [ "$rb" = "$NOW" ]; } && { rstate=REVIEW-DUE; NDUE=$((NDUE+1)); } ;;
  esac
  [ "$kind" = "accept_and_constrain" ] && NAC=$((NAC+1))
  printf 'disposition: CARRIED %s subject=%s kind=%s census-mismatch=%s reported-in-table=%s review-by=%s review-state=%s\n' \
    "$id" "$sub" "$kind" "${mm:-unknown}" "$vis" "$rb" "$rstate"
  # THE READING THAT MATTERS, printed beside every record rather than left to a
  # header nobody re-reads. If either half ever reads the other way, the
  # disposition has become the exception it must not be.
  if [ "$mm" = "declared" ] && [ "$vis" = "yes" ]; then
    printf 'carried: %s STILL declares `authority_mismatch: declared` and STILL holds its row in the summary table. This disposition CARRIES the mismatch; it does not clear it, and it raises no authority. What it adds is the constraint that bounds it: %s\n' \
      "$sub" "$(gv "$id" constraint)"
  else
    NCLEARED=$((NCLEARED+1))
    printf 'carried: %s NO LONGER reads as a carried mismatch (census-mismatch=%s reported-in-table=%s). A disposition clears nothing, so one of the two artefacts has moved and this record is now describing a decision about a finding that is not there.\n' \
      "$sub" "${mm:-unknown}" "$vis"
  fi
done < <(ids)

printf 'mismatch-disposition: %s disposition(s), %s of them `accept_and_constrain`, %s past review, %s cleared mismatch(es) — a disposition clears none, so the last number is expected to be zero and is printed so that it cannot quietly stop being.\n' \
  "$NID" "$NAC" "$NDUE" "$NCLEARED"
printf 'mismatch-disposition: ADVISORY. It reports and exits 0. It CLEARS NO MISMATCH and RAISES NO AUTHORITY: demoting, re-classifying, re-evidencing or retiring any control named above is a governance action for the operator, and nothing here performs one.\n'
exit 0
