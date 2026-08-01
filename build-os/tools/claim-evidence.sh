#!/usr/bin/env bash
# Build OS — claim-scoped evidence: read the assertion store, and project it
# back onto the legacy one-token `empirical_status` field without lying.
#
# THE GAP THIS CLOSES. control_registry.txt carries ONE `empirical_status` per
# control and that token gets read as a statement ABOUT THE CONTROL.
# `gravito_mismatch_refuted_a` measured the case where that reading is false:
# `maint.tripwire_coverage_scan` is REFUTED for its detection claim under bare
# `node --test` and SUPPORTED for its prevention claim under the sanctioned
# maintenance invocation. Both hold. Reasoning from the bare token — "it is
# refuted, so demote it" — nearly produced a demotion the
# COVERAGE-GATE-PREVENTION-DIFFERENTIAL measured to DESTROY LIVE MEMORY. So
# evidence becomes an ASSERTION about a NAMED CLAIM IN A NAMED SCOPE, stored in
# build-os/registry/evidence_assertions.txt, and a subject may carry as many
# concurrent assertions as it has claims.
#
# `untested` IS NOW A LEVEL, AND ADDING IT WAS A SCHEMA CHANGE WITH A GUARD
# CONSEQUENCE. It means the claim HAS NEVER OPERATED against a live or
# representative task, which is strictly weaker than `unvalidated` (it has
# operated; the outcome evidence is inadequate). It caps at `observe` — the
# lowest rung that is still a legal destination, meaning the output may be
# recorded and may cause nothing. THE GUARD IT INTERACTS WITH IS NOT WEAKENED:
# `evidence.derivation_nonvacuity` still exits 2 on an evidence token nothing
# has capped. What changed is that `untested` stopped being one of those tokens;
# every other unrecognised token still takes the derivation down, because an
# unrecognised evidence level must never fall through to permissive.
#
# ---------------------------------------------------------------------------
# THE COMPATIBILITY PROJECTION, AND THE ONE DIRECTION IT IS LOSSY IN
# ---------------------------------------------------------------------------
# Existing controls must stay readable, so every subject projects back to a
# legacy `empirical_status`. The projection is DETERMINISTIC — a sorted, unique
# set, so it does not depend on the order stanzas happen to sit in — and it
# EXPOSES THE COMPOSITE. Where several claim statuses exist it emits ALL of
# them; it never selects one.
#
#   THAT MATTERS BECAUSE SELECTING WOULD BE THE FLATTERING-DIRECTION ERROR.
#   Given `refuted` on one claim and `supported` on another, picking whichever
#   permits greater authority is exactly the move this repository exists to
#   catch, and it is the move that nearly destroyed live memory. The composite
#   resolves by MINIMUM downstream — evidence-policy.sh already resolves a
#   comma-composite that way — so a contradiction cannot be outvoted by the
#   claim that preceded or followed it.
#
# THE MAP, with the one interesting row stated rather than buried:
#
#   untested     -> untested       a level of its own, now that one exists.
#   unvalidated  -> unvalidated    unchanged.
#   red_driven   -> red_driven     unchanged.
#   refuted      -> refuted        unchanged, AND NEVER DROPPED.
#   supported    -> unvalidated    THE LOSSY ROW, and the loss is deliberate.
#
# `supported` PROJECTS TO `unvalidated` AND NOT TO `field_observed`. A support
# claim is SCOPE-BOUND: EV-0002 supports prevention under the sanctioned
# maintenance invocation and licenses nothing about any other path. The legacy
# `empirical_status` field CARRIES NO SCOPE. So there is no honest way to spell
# a scoped support claim into it — writing `field_observed` would assert
# globally what was measured locally, which is the overclaim in one word. The
# projection therefore declines to learn anything upward from a scoped claim:
# globally the subject has operated and no GLOBAL claim has adequate outcome
# evidence, which is what `unvalidated` already means.
#
#   THE COST IS REAL AND IS NOT HIDDEN: a genuinely well-evidenced control
#   reads no better through this projection than an unmeasured one. The
#   projection is a COMPATIBILITY SHIM for a field that cannot express scope,
#   and it is lossy in the ONE direction that cannot flatter. The place a scoped
#   support claim is legible is the assertion store, and `project` prints the
#   claim ids beside the composite so a reader is pointed at it.
#
# ---------------------------------------------------------------------------
# AUTHORITY: EVIDENCE MAY LOWER, AND MAY NOT RAISE
# ---------------------------------------------------------------------------
#   L_effective = MIN(L_class, L_registry_evidence, L_assertion_evidence)
#
# over the registry's ladder, none < observe < advise < rank < gate < execute.
# The minimum is what "any one failing is disqualifying" looks like
# arithmetically, and it is also what makes the store SAFE: a new term entering
# a minimum can only push the result down. A `red_driven` assertion on a control
# the census records as `refuted` composes to `observe`, not to `gate`. If this
# ever printed otherwise, the assertion store would have become a laundering
# channel for authority, which is the failure mode a claim-scoped evidence model
# invites and must be built against.
#
# CLAIM-SPECIFIC EVIDENCE APPLIES ONLY TO THE CONSEQUENCE AND SCOPE OF ITS
# CLAIM. A supported prevention claim in one invocation path does not validate
# the control's other behaviour, which is why `project` prints the claim ids and
# the scopes, and why a subject carrying opposed verdicts gets an explicit
# `contradiction:` line instead of a resolved single answer.
#
# WHERE THE CAPS COME FROM. The class axis and the evidence axis are NOT
# restated here: they are read at runtime from `evidence-policy.sh matrix`. One
# schema, one parser — the same device evidence-policy.sh uses for the
# deployment axis, and the reason this file cannot quietly cap `refuted`
# differently from the matrix that already caps it. If that tool is missing or
# refuses, THIS REFUSES: an unknown cap must never be defaulted to permissive.
# `supported` is the ONE cap this file owns, because it is the one status with
# no legacy row to source from.
#
# ---------------------------------------------------------------------------
# THE TERM IS NOW ENFORCED, AND THE TWO HALVES OF ENFORCEMENT POINT OPPOSITE WAYS
# ---------------------------------------------------------------------------
# `build-os/registry/evidence_assertions.txt` said, in its own words, that
# nothing "notices an assertion going stale against the `valid_until` it
# declares", and `control_registry.txt` said the field "is recorded so that a
# later packet can enforce it". This is that packet. Enforcement is split,
# because the two directions are not the same act and getting them the same way
# round would turn this store into a laundering channel:
#
#   `validate` REFUSES a term that is not in force. A dated `valid_until` that
#   has passed, or a `valid_from` that has not arrived, is an assertion its own
#   author dated out of the present. The remedy is a HUMAN one — re-date it, or
#   supersede it — and a store that quietly carried it would be asserting
#   evidence nobody re-measured.
#
#   `project` REPORTS it (`LAPSED` / `NOT-YET-LIVE`) and KEEPS IT IN THE
#   MINIMUM. This is the half that matters. Assertion evidence can only LOWER a
#   licence, so DROPPING an out-of-term assertion would RAISE one: a lapsed
#   REFUTATION would silently stop binding and the control it refutes would read
#   better than it did the day before. That is the flattering-direction error
#   the whole store exists to catch, so an out-of-term assertion is NAMED and
#   NEVER DROPPED.
#
# THE TERM HAS TWO ENDS AND BOTH ARE CHECKED. `valid_from` is as much a term as
# `valid_until`; enforcing one end and not the other is the decorative-window
# defect that `authority-envelope.sh` was found to have at BOTH ends.
#
# THE COST IS STATED RATHER THAN HIDDEN: a dated term becomes a commitment that
# comes due, and the day it does this gate goes red with no code change. That is
# the field meaning something. Every live assertion today carries an `open` term
# — prose, not a date — so the gate is INERT on the live store BY CONSTRUCTION,
# the same property the deployment axis has and for the same stated reason.
#
# THE CLOCK IS NOT COMPUTED HERE. It is sourced from `authority-envelope.sh now`,
# which owns the only clock in the repository, exactly as the caps above are
# sourced from `evidence-policy.sh matrix`. A second private `date` call is how
# an override is honoured in one tool and silently ignored in another.
#
# TWO EXIT PATHS, GOVERNING DIFFERENT OBJECTS, as evidence-policy.sh already
# does. `validate` is a Class-A gate over WHETHER A STANZA CAN BE READ AT ALL
# (evidence.assertion_schema) and exits 2. `project` ADVISES: it exits 0
# whatever it finds, and refuses only a derivation it cannot trust — an absent
# store, a store that parses to zero assertions, an absent registry, or a status
# nothing has capped. It re-authorises nothing and writes nothing.
#
# Local only. Reads files and prints. Writes nothing, anywhere.
#
# Usage:
#   claim-evidence.sh schema
#   claim-evidence.sh list     [--store F] [--subject ID]
#   claim-evidence.sh validate [--store F] [--registry F] [--mutators F]
#   claim-evidence.sh project  [--store F] [--registry F] [--subject ID]
# Exit: 0 the command ran (whatever it FOUND — project advises);
#       2 the invocation is malformed, or the derivation could not be trusted.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"
STORE=""
REGISTRY=""
MUTATORS=""
SUBJECT=""

refuse(){ printf 'claim-evidence: REFUSED — %s\n' "$*" >&2; exit 2; }

# --- the schema, declared exactly once ---------------------------------------
# All nineteen are REQUIRED and none has a default. A field that may be omitted
# is a field a reader cannot tell apart from one nobody thought about; where
# there is genuinely nothing to say, the value is the word for nothing
# (`none`, `open`) and that is an assertion somebody made.
EV_FIELDS="subject_id claim_id claim_text status scope substrate invocation_path method fixture observed_result interpretation limitations created_at created_by reviewed_by valid_from valid_until artifact_refs supersedes"
EV_STATUSES="untested unvalidated red_driven supported refuted"
# THE PROJECTION MAP. See the header for why `supported` -> `unvalidated`.
LEGACY_PROJECTION="untested:untested unvalidated:unvalidated red_driven:red_driven supported:unvalidated refuted:refuted"
# THE ONE CAP THIS FILE OWNS. `supported` has no legacy row to source a cap
# from, so it is declared here: WITHIN ITS DECLARED SCOPE a supported claim
# establishes what a gate structurally needs, so it caps at `gate` there —
# and note that this is the SCOPE cap, not the projection, which is where the
# conservatism lives.
SUPPORTED_SCOPE_CAP="gate"
# SCOPE FILLERS THAT MEAN "EVERYWHERE". Refused by name, because each of them is
# an unscoped claim spelled as a scoped one.
SCOPE_FILLERS="n/a none unknown any all everywhere global -"
EV_ID_RE='^EV-[0-9]{4}(-[a-z0-9][a-z0-9-]*)?$'
LADDER="none observe advise rank gate execute"

rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; execute) echo 5 ;; *) echo -1 ;; esac; }
name_of(){ case "$1" in 0) echo none ;; 1) echo observe ;; 2) echo advise ;; 3) echo rank ;; 4) echo gate ;; 5) echo execute ;; *) echo '?' ;; esac; }
in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }
map_of(){ # <map-string> <key> -> value, or empty + status 1
  local a
  for a in $1; do case "$a" in "$2":*) printf '%s' "${a#*:}"; return 0 ;; esac; done
  return 1
}

CMD="${1:-}"
[ $# -gt 0 ] && shift
case "$CMD" in
  schema|list|validate|project) ;;
  -h|--help|help) sed -n '2,153p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") refuse "no command — expected one of: schema, list, validate, project" ;;
  *)  refuse "unknown command \"$CMD\" — expected one of: schema, list, validate, project" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --store)     [ $# -ge 2 ] || refuse "--store needs a value";     STORE="$2"; shift 2 ;;
    --registry)  [ $# -ge 2 ] || refuse "--registry needs a value";  REGISTRY="$2"; shift 2 ;;
    --mutators)  [ $# -ge 2 ] || refuse "--mutators needs a value";  MUTATORS="$2"; shift 2 ;;
    --subject)   [ $# -ge 2 ] || refuse "--subject needs a value";   SUBJECT="$2"; shift 2 ;;
    --repo)      [ $# -ge 2 ] || refuse "--repo needs a value";      REPO="$2"; shift 2 ;;
    -h|--help)   sed -n '2,153p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done
[ -n "$STORE" ]    || STORE="$REPO/build-os/registry/evidence_assertions.txt"
[ -n "$REGISTRY" ] || REGISTRY="$REPO/build-os/registry/control_registry.txt"
[ -n "$MUTATORS" ] || MUTATORS="$REPO/build-os/registry/mutator_registry.txt"

# --- the axes, SOURCED and never restated ------------------------------------
# One schema, one parser. If the matrix cannot be read, this refuses rather than
# guessing a cap: a cap defaulted to permissive is how a policy stops
# discriminating while still printing green.
EPOL="$SELF_DIR/evidence-policy.sh"
CLASS_AXIS=""; EVIDENCE_AXIS=""
load_axes(){
  local m
  [ -x "$EPOL" ] || refuse "no evidence-policy matrix at $EPOL. The class and evidence caps are sourced from it rather than restated here; deriving them as \"no cap\" because the tool is missing would license everything this projection exists to bound."
  m="$("$EPOL" matrix 2>&1)" || refuse "\`evidence-policy.sh matrix\` failed; the class and evidence caps are unknown, and an unknown cap must never be defaulted to permissive."
  CLASS_AXIS="$(printf '%s\n' "$m" | awk '$1=="axis:" && $2=="class"{for(i=3;i<=NF;i++) printf "%s ", $i}')"
  EVIDENCE_AXIS="$(printf '%s\n' "$m" | awk '$1=="axis:" && $2=="evidence"{for(i=3;i<=NF;i++) printf "%s ", $i}')"
  [ -n "$CLASS_AXIS" ]    || refuse "the matrix printed no class axis; there is nothing to compose against."
  [ -n "$EVIDENCE_AXIS" ] || refuse "the matrix printed no evidence axis; there is nothing to compose against."
}
# The cap a status licenses WITHIN ITS DECLARED SCOPE. Four of the five are
# legacy tokens and take the matrix's cap; `supported` is the one this file owns.
scope_cap(){
  local s="$1" c
  if [ "$s" = "supported" ]; then printf '%s' "$SUPPORTED_SCOPE_CAP"; return 0; fi
  c="$(map_of "$EVIDENCE_AXIS" "$s")" || return 1
  printf '%s' "$c"
}
legacy_cap(){ map_of "$EVIDENCE_AXIS" "$1"; }
class_cap(){  map_of "$CLASS_AXIS" "$1"; }

# --- the clock, SOURCED and never computed ------------------------------------
# One clock, one owner. `authority-envelope.sh now` is the only place in this
# repository that asks what day it is; a second private `date` call here is how
# BUILD_OS_NOW gets honoured in one tool and silently ignored in another. If the
# clock cannot be read, this REFUSES: a term evaluated against an unknown date is
# a term nobody evaluated.
ENVTOOL="$SELF_DIR/authority-envelope.sh"
NOW=""; NOW_SOURCE=""
load_clock(){
  local o
  [ -n "$NOW" ] && return 0
  [ -x "$ENVTOOL" ] || refuse "no clock at $ENVTOOL. The assertion terms below are evaluated against a date, and deriving that date here would be a second private clock — the way an override is honoured in one tool and ignored in another."
  o="$("$ENVTOOL" now 2>&1)" || refuse "\`authority-envelope.sh now\` failed; the date every \`valid_from\`/\`valid_until\` is judged against is unknown, and an unknown clock must never fall back to \"today\"."
  NOW="$(printf '%s\n' "$o" | awk '$1=="now:"{print $2; exit}')"
  NOW_SOURCE="$(printf '%s\n' "$o" | sed -n 's/^source: //p' | head -1)"
  case "$NOW" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) refuse "the clock printed \"$NOW\", which is not YYYY-MM-DD." ;;
  esac
}
# THE TERM STATES. Three, and the two out-of-term ones are DISTINCT for the same
# reason the envelope's are: a term that has not begun and a term that ended are
# different facts. A term value may be PROSE (`open — …`), which is not a date
# and never comes due; only a leading YYYY-MM-DD is a dated commitment.
TERM_STATES="in_force lapsed not_yet_live"
dateish(){ # <field value> -> the leading YYYY-MM-DD, or nothing
  local d="${1%% *}"
  case "$d" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) printf '%s' "$d" ;; esac
}
term_state(){ # <valid_from> <valid_until> -> in_force | lapsed | not_yet_live
  local f u
  f="$(dateish "$1")"; u="$(dateish "$2")"
  if [ -n "$f" ] && [ "$NOW" \< "$f" ]; then printf 'not_yet_live'; return 0; fi
  # HALF-OPEN, exactly as the envelope window is: `valid_until` is the moment the
  # term ENDS rather than the last day it covers, so the two artefacts cannot
  # disagree about what a date on a term means.
  if [ -n "$u" ] && { [ "$u" \< "$NOW" ] || [ "$u" = "$NOW" ]; }; then printf 'lapsed'; return 0; fi
  printf 'in_force'
}
term_verdict(){ case "$1" in lapsed) printf 'LAPSED' ;; not_yet_live) printf 'NOT-YET-LIVE' ;; *) printf 'IN-FORCE' ;; esac; }

# --------------------------------------------------------------- schema ------
if [ "$CMD" = "schema" ]; then
  load_axes
  printf 'schema: claim-scoped-evidence-v1 — one record per assertion: one subject, one claim, one scope, one verdict\n'
  printf 'key: evidence — the record key IS the evidence_id, an %s stable id; there is no second field repeating it\n' 'EV-NNNN[-slug]'
  printf 'ladder: %s\n' "$LADDER"
  for f in $EV_FIELDS; do
    case "$f" in
      scope)      printf 'field: %s required — the claim SCOPE. No default, and the fillers that mean "everywhere" (%s) are refused: a scopeless claim is the unscoped token this store replaces\n' "$f" "$SCOPE_FILLERS" ;;
      supersedes) printf 'field: %s required — `none`, or the %s id of the assertion this one replaces. The only reference between records\n' "$f" 'EV-NNNN' ;;
      artifact_refs) printf 'field: %s required — NAVIGATION HINTS ONLY. They may be path:line and they may go stale; nothing is identified by them\n' "$f" ;;
      *)          printf 'field: %s required\n' "$f" ;;
    esac
  done
  for s in $EV_STATUSES; do
    cap="$(scope_cap "$s")" || refuse "status \"$s\" has no cap — a status this tool declares and cannot cap would license by omission."
    proj="$(map_of "$LEGACY_PROJECTION" "$s")" || refuse "status \"$s\" has no legacy projection."
    case "$s" in
      untested)    why="has NEVER OPERATED against a live or representative task — strictly weaker than unvalidated, where it operated and the outcome evidence was inadequate" ;;
      unvalidated) why="has operated, but lacks adequate outcome evidence" ;;
      red_driven)  why="demonstrated to fire against a planted or known failure" ;;
      supported)   why="the named claim is supported IN THE NAMED SCOPE, and nowhere else" ;;
      refuted)     why="the named claim is contradicted IN THE NAMED SCOPE" ;;
      *)           why="" ;;
    esac
    printf 'status: %s scope-cap=%s legacy-projection=%s — %s\n' "$s" "$cap" "$proj" "$why"
  done
  printf 'rule: evidence MAY LOWER authority and MAY NEVER RAISE it — L_effective = MIN(L_class, L_registry_evidence, L_assertion_evidence) over the ladder above, and a new term entering a minimum can only push the result down\n'
  printf 'rule: claim-specific evidence applies ONLY to the consequence and scope its claim names; a supported prevention claim in one invocation path validates nothing else the control does\n'
  printf 'rule: the legacy projection exposes the COMPOSITE of every live claim status and NEVER selects one — selecting whichever status permits greater authority is the flattering-direction error this store exists to catch\n'
  printf 'rule: `supported` projects globally to `unvalidated` because the legacy empirical_status field carries NO SCOPE, so a scoped support claim cannot be spelled in it without asserting globally what was measured locally. The projection is lossy in the one direction that cannot flatter\n'
  printf 'rule: an unrecognised status REFUSES at exit 2 and is never defaulted; `untested` was added to the vocabulary WITH a cap, which is the opposite of a fall-through\n'
  printf 'source: the class and evidence caps are read at runtime from `evidence-policy.sh matrix`, not restated here — one schema, one parser. `supported` is the one cap this file owns, because it has no legacy row\n'
  exit 0
fi

# --- the parser, used by list / validate / project ----------------------------
# Stanzas are `key: value` lines separated by blank lines; `#` at column 0 is a
# comment. Emits one TSV line per (id, field, value), plus an ORDER line per id
# so callers can report in file order without re-reading.
FLAT="$(mktemp)"; PROBLEMS="$(mktemp)"
trap 'rm -f "$FLAT" "$PROBLEMS"' EXIT

parse_store(){
  [ -f "$STORE" ] || refuse "no assertion store at $STORE. There is nothing to derive from, and an absent store is not an empty one."
  # THE ID SHAPE IS CHECKED IN BASH, NOT HERE, and that is not a style choice:
  # `mawk` cannot compile an interval expression (`[0-9]{4}`) supplied as a
  # dynamic regex and PANICS on it rather than failing the match, which would
  # take the whole parse to zero records — a store that "parses to nothing"
  # because of the guard's own portability bug. `grep -E` below is the one
  # regex engine every path here shares.
  awk '
    /^#/ { next }
    /^[[:space:]]*$/ { cur=""; next }
    /^evidence: / {
      cur=substr($0,11)
      if (cur in SEEN) { printf "PROBLEM\t%s\tkey\tis used by more than one stanza; a duplicate id resolves to whichever stanza a reader hits first\n", cur }
      SEEN[cur]=1
      printf "ORDER\t%s\n", cur
      next
    }
    {
      if (cur == "") { printf "PROBLEM\t(preamble)\t%s\tappears before any `evidence:` key\n", $0; next }
      if ($0 !~ /^[a-z_]+: /) {
        # A key with no value at all is still a field the author wrote down.
        if ($0 ~ /^[a-z_]+:$/) { k=$0; sub(/:$/,"",k); printf "FIELD\t%s\t%s\t\n", cur, k; next }
        printf "PROBLEM\t%s\t(line)\t\"%s\" is not a `key: value` line\n", cur, $0; next
      }
      k=$0; sub(/: .*$/,"",k); v=$0; sub(/^[a-z_]+: /,"",v)
      printf "FIELD\t%s\t%s\t%s\n", cur, k, v
    }
  ' "$STORE" > "$FLAT"
  # The id shape, checked by the one engine every path here shares.
  awk -F'\t' '$1=="ORDER"{print $2}' "$FLAT" | while IFS= read -r _id; do
    printf '%s\n' "$_id" | grep -qE "$EV_ID_RE" \
      || printf 'PROBLEM\t%s\tkey\tis not an EV-NNNN[-slug] stable id\n' "$_id"
  done >> "$FLAT"
}

ids(){ awk -F'\t' '$1=="ORDER"{print $2}' "$FLAT"; }
gv(){ awk -F'\t' -v i="$1" -v f="$2" '$1=="FIELD" && $2==i && $3==f {print $4; exit}' "$FLAT"; }
has(){ awk -F'\t' -v i="$1" -v f="$2" '$1=="FIELD" && $2==i && $3==f {n=1} END{exit !n}' "$FLAT"; }

# --------------------------------------------------------------- validate ----
if [ "$CMD" = "validate" ]; then
  load_axes
  load_clock
  parse_store
  : > "$PROBLEMS"
  awk -F'\t' '$1=="PROBLEM"{printf "%s: %s %s\n", $2, $3, $4}' "$FLAT" >> "$PROBLEMS"
  NID="$(ids | grep -c . || true)"; NID="${NID:-0}"
  # VACUITY. A store that parses to zero assertions is not a clean one; it is
  # what a store looks like the day after somebody renamed the key. Reporting
  # "0 problems" for it would be a false all-clear with a green tick on it.
  if [ "$NID" -eq 0 ] && [ ! -s "$PROBLEMS" ]; then
    refuse "$STORE parses to 0 assertions. A schema check with nothing to check passes for every store, including one somebody emptied, so this refuses instead of printing zero."
  fi
  [ -f "$REGISTRY" ] || refuse "no control registry at $REGISTRY. Every subject_id must resolve to a registered object, and a subject check that reads no census certifies every subject."
  SUPERSEDED="$(awk -F'\t' '$1=="FIELD" && $3=="supersedes" && $4!="none"{print $4}' "$FLAT" | sort -u)"
  SEENPAIR=""
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    # every declared field present, non-empty, and nothing else present
    for f in $EV_FIELDS; do
      if ! has "$id" "$f"; then
        printf '%s: field `%s` is absent. Every field is required and none has a default; where there is nothing to say, the value is the word for nothing.\n' "$id" "$f" >> "$PROBLEMS"
      elif [ -z "$(gv "$id" "$f")" ]; then
        printf '%s: field `%s` is EMPTY. Empty is an absence and `none` is a value; they are different.\n' "$id" "$f" >> "$PROBLEMS"
      fi
    done
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      in_list "$f" "$EV_FIELDS" \
        || printf '%s: unknown field `%s`. The schema is closed; a typo that is ignored is a value silently lost.\n' "$id" "$f" >> "$PROBLEMS"
    done < <(awk -F'\t' -v i="$id" '$1=="FIELD" && $2==i{print $3}' "$FLAT")
    DUPF="$(awk -F'\t' -v i="$id" '$1=="FIELD" && $2==i{print $3}' "$FLAT" | sort | uniq -d)"
    [ -n "$DUPF" ] && printf '%s: field(s) stated twice: %s. Two values for one field is two assertions wearing one id.\n' "$id" "$(printf '%s' "$DUPF" | tr '\n' ' ')" >> "$PROBLEMS"

    st="$(gv "$id" status)"
    # THE STATUS GUARD. An unrecognised level is REFUSED, never defaulted. This
    # is the same rule evidence.derivation_nonvacuity enforces one layer along,
    # and adding `untested` to the vocabulary did not soften it.
    if [ -n "$st" ] && ! in_list "$st" "$EV_STATUSES"; then
      printf '%s: status `%s` is not one of: %s. An unrecognised evidence level must never fall through to permissive, so this refuses rather than capping it at something.\n' "$id" "$st" "$EV_STATUSES" >> "$PROBLEMS"
    fi

    sc="$(gv "$id" scope)"
    if [ -n "$sc" ]; then
      lsc="$(printf '%s' "$sc" | tr '[:upper:]' '[:lower:]')"
      in_list "$lsc" "$SCOPE_FILLERS" \
        && printf '%s: scope `%s` means "everywhere". A claim with no scope is the unscoped token this store exists to replace; name the invocation path, the substrate or the fixture the claim was established against.\n' "$id" "$sc" >> "$PROBLEMS"
    fi

    sub="$(gv "$id" subject_id)"
    if [ -n "$sub" ]; then
      grep -qxF "control: $sub" "$REGISTRY" || { [ -f "$MUTATORS" ] && grep -qxF "control_id: $sub" "$MUTATORS"; } \
        || printf '%s: subject `%s` is in neither the control census nor the mutator census. An assertion about nothing is evidence about nothing.\n' "$id" "$sub" >> "$PROBLEMS"
    fi

    # THE TERM, ENFORCED. An assertion its own author dated out of the present is
    # not a live assertion, and the remedy is a HUMAN one: re-date it, or
    # supersede it. Both ends are checked — enforcing `valid_until` alone would
    # leave the window decorative at its opening end, which is the defect this
    # packet found in the envelope store.
    vf="$(gv "$id" valid_from)"; vu="$(gv "$id" valid_until)"
    case "$(term_state "$vf" "$vu")" in
      lapsed)
        printf '%s: `valid_until` is %s and today is %s — the term LAPSED. An assertion whose own author dated it out of the present is evidence nobody re-measured; re-date it, or supersede it with a fresh measurement. It is NOT dropped from the projection: dropping a lapsed refutation would RAISE a licence.\n' \
          "$id" "$(dateish "$vu")" "$NOW" >> "$PROBLEMS" ;;
      not_yet_live)
        printf '%s: `valid_from` is %s and today is %s — the term has NOT BEGUN. A claim that starts in the future asserts nothing about now, and a store carrying it reads as though it did.\n' \
          "$id" "$(dateish "$vf")" "$NOW" >> "$PROBLEMS" ;;
    esac

    sup="$(gv "$id" supersedes)"
    if [ -n "$sup" ] && [ "$sup" != "none" ]; then
      printf '%s\n' "$sup" | grep -qE "$EV_ID_RE" \
        || printf '%s: supersedes `%s` is not an EV-NNNN[-slug] stable id.\n' "$id" "$sup" >> "$PROBLEMS"
      ids | grep -qxF "$sup" \
        || printf '%s: supersedes `%s`, which is in no stanza of this store. A dangling supersession silently leaves two live claims.\n' "$id" "$sup" >> "$PROBLEMS"
      [ "$sup" = "$id" ] && printf '%s: supersedes itself.\n' "$id" >> "$PROBLEMS"
    fi

    # (subject, claim) must be unique among assertions nothing supersedes. Two
    # LIVE verdicts on one claim is a contradiction; two verdicts on DIFFERENT
    # claims is the whole point of the file, and the two must not be confused.
    if ! printf '%s\n' "$SUPERSEDED" | grep -qxF "$id"; then
      pair="$sub|$(gv "$id" claim_id)"
      case "$SEENPAIR" in
        *"[$pair]"*) printf '%s: a second LIVE assertion for subject `%s` claim `%s`. Concurrent assertions must name DIFFERENT claims; replacing a verdict is what `supersedes` is for.\n' "$id" "$sub" "$(gv "$id" claim_id)" >> "$PROBLEMS" ;;
        *) SEENPAIR="$SEENPAIR[$pair]" ;;
      esac
    fi
  done < <(ids)

  NP="$(grep -c . "$PROBLEMS" || true)"; NP="${NP:-0}"
  if [ "$NP" -gt 0 ]; then
    sed 's/^/claim-evidence: /' "$PROBLEMS" >&2
    refuse "$NP problem(s) in $STORE (named above). None is skipped and none is defaulted: a store that quietly dropped what it could not read would certify assertions nobody parsed."
  fi
  printf 'claim-evidence: %s assertion(s) valid in %s (schema claim-scoped-evidence-v1)\n' "$NID" "$STORE"
  printf 'claim-evidence: every subject resolves, every scope is named, every status is capped, and no two LIVE assertions share a (subject, claim).\n'
  exit 0
fi

# ------------------------------------------------------------------- list ----
if [ "$CMD" = "list" ]; then
  load_axes
  parse_store
  N=0
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    sub="$(gv "$id" subject_id)"
    [ -n "$SUBJECT" ] && [ "$sub" != "$SUBJECT" ] && continue
    N=$((N+1))
    printf 'assertion: %s subject=%s claim=%s status=%s scope=%s\n' \
      "$id" "$sub" "$(gv "$id" claim_id)" "$(gv "$id" status)" "$(gv "$id" scope)"
  done < <(ids)
  printf 'claim-evidence: %s assertion(s) listed%s\n' "$N" "${SUBJECT:+ for subject $SUBJECT}"
  exit 0
fi

# ---------------------------------------------------------------- project ----
# THIS ADVISES. It exits 0 whatever it finds, and refuses only a derivation it
# cannot trust. It re-authorises nothing and writes nothing.
load_axes
load_clock
parse_store
[ -f "$REGISTRY" ] || refuse "no control registry at $REGISTRY. The class and registry-evidence terms of MIN(L_class, L_registry_evidence, L_assertion_evidence) would be unknown, and an unknown term must never be defaulted to permissive."
NID="$(ids | grep -c . || true)"; NID="${NID:-0}"
[ "$NID" -gt 0 ] || refuse "$STORE parses to 0 assertions. A projection over no assertions reports a clean composite for a store nobody read."

# Refuse an unreadable status here too: the projection of a token nothing capped
# would be a licence derived from a level nobody defined.
while IFS= read -r id; do
  [ -n "$id" ] || continue
  st="$(gv "$id" status)"
  in_list "$st" "$EV_STATUSES" \
    || refuse "assertion $id declares status \"$st\", which is not one of: $EV_STATUSES. Projecting a status this tool cannot cap would derive a licence from a level nobody defined."
done < <(ids)

SUBJECTS="$(awk -F'\t' '$1=="FIELD" && $3=="subject_id"{print $4}' "$FLAT" | sort -u)"
NSUBJ=0
while IFS= read -r s; do
  [ -n "$s" ] || continue
  [ -n "$SUBJECT" ] && [ "$s" != "$SUBJECT" ] && continue
  NSUBJ=$((NSUBJ+1))
  # Everything below is derived from SORTED SETS, so the output cannot depend on
  # the order stanzas happen to sit in the file.
  MINE=""; CLAIMS=""; STATS=""; TOKENS=""; NA=0
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    [ "$(gv "$id" subject_id)" = "$s" ] || continue
    MINE="$MINE$id"$'\n'; NA=$((NA+1))
    CLAIMS="$CLAIMS$(gv "$id" claim_id)"$'\n'
    STATS="$STATS$(gv "$id" status)"$'\n'
    TOKENS="$TOKENS$(map_of "$LEGACY_PROJECTION" "$(gv "$id" status)")"$'\n'
  done < <(ids)
  CL="$(printf '%s' "$CLAIMS" | grep -v '^$' | sort -u | paste -sd, -)"
  ST="$(printf '%s' "$STATS"  | grep -v '^$' | sort -u | paste -sd, -)"
  TK="$(printf '%s' "$TOKENS" | grep -v '^$' | sort -u | paste -sd, -)"
  printf 'projection: %s legacy-empirical-status=%s assertions=%s claims=%s statuses=%s\n' "$s" "$TK" "$NA" "$CL" "$ST"

  # THE TERM, REPORTED AND NEVER APPLIED AS A FILTER. Every out-of-term
  # assertion is NAMED here and stays in the composite above. Dropping one would
  # RAISE a licence — a lapsed REFUTATION would silently stop binding — and that
  # is the one direction this store may never move. The envelope store drops an
  # out-of-window record because a GRANT that has ended is not in force; an
  # assertion is a MEASUREMENT, and a measurement whose term ran out has not
  # become false, it has become unrefreshed.
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    [ "$(gv "$id" subject_id)" = "$s" ] || continue
    tsv="$(term_state "$(gv "$id" valid_from)" "$(gv "$id" valid_until)")"
    [ "$tsv" = "in_force" ] && continue
    printf 'term: %s %s status=%s valid_from=%s valid_until=%s now=%s — RETAINED in the composite above. It is out of term and it is not dropped: assertion evidence can only LOWER a licence, so dropping a stale one would RAISE one.\n' \
      "$(term_verdict "$tsv")" "$id" "$(gv "$id" status)" "$(dateish "$(gv "$id" valid_from)")" "$(dateish "$(gv "$id" valid_until)")" "$NOW"
  done < <(ids)

  # The composite resolves by MINIMUM, which is what makes a refutation
  # impossible to outvote.
  aer=99; abind=""
  for t in $(printf '%s' "$TK" | tr ',' ' '); do
    c="$(legacy_cap "$t")" || refuse "the projected token \"$t\" has no cap on the evidence axis; the projection would be unreadable by the matrix it exists to feed."
    r="$(rank_of "$c")"; if [ "$r" -lt "$aer" ]; then aer="$r"; abind="$t"; fi
  done

  # The registry's own two terms.
  CLS="$(awk -v i="$s" '$0=="control: "i{f=1;next} /^$/{f=0} f && /^class: /{sub("^class: ","");print;exit}' "$REGISTRY")"
  EMP="$(awk -v i="$s" '$0=="control: "i{f=1;next} /^$/{f=0} f && /^empirical_status: /{sub("^empirical_status: ","");print;exit}' "$REGISTRY")"
  AUT="$(awk -v i="$s" '$0=="control: "i{f=1;next} /^$/{f=0} f && /^runtime_authority: /{sub("^runtime_authority: ","");print;exit}' "$REGISTRY")"
  if [ -z "$CLS" ] || [ -z "$EMP" ]; then
    printf 'authority: %s UNRESOLVED — the subject has no class/empirical_status stanza in %s, so two terms of the minimum are unknown. An unknown term is not defaulted to permissive, so NO licence is derived for it here.\n' "$s" "$REGISTRY"
  else
    ccap="$(class_cap "$CLS")" || ccap=""
    if [ -z "$ccap" ]; then
      printf 'authority: %s UNRESOLVED — class "%s" has no row on the class axis, so the class term is unknown and no licence is derived.\n' "$s" "$CLS"
    else
      cr="$(rank_of "$ccap")"
      rer=99; rbind=""
      for t in $(printf '%s' "$EMP" | tr ',' ' '); do
        c="$(legacy_cap "$t")" || { rer=-1; rbind="$t"; break; }
        r="$(rank_of "$c")"; if [ "$r" -lt "$rer" ]; then rer="$r"; rbind="$t"; fi
      done
      if [ "$rer" -lt 0 ]; then
        printf 'authority: %s UNRESOLVED — the registry declares empirical_status token "%s", which has no cap on the evidence axis. An uncapped level is never defaulted to permissive.\n' "$s" "$rbind"
      else
        eff="$cr"; bind="class"
        [ "$rer" -lt "$eff" ] && { eff="$rer"; bind="registry-evidence"; }
        [ "$aer" -lt "$eff" ] && { eff="$aer"; bind="assertion-evidence"; }
        raised=no; [ "$eff" -gt "$rer" ] && raised=yes
        printf 'authority: %s class=%s class-licensed=%s registry-evidence=%s registry-evidence-licensed=%s assertion-evidence-licensed=%s effective=%s exercises=%s raised=%s binding-axis=%s binding-assertion-token=%s\n' \
          "$s" "$CLS" "$ccap" "$EMP" "$(name_of "$rer")" "$(name_of "$aer")" "$(name_of "$eff")" "${AUT:-unknown}" "$raised" "$bind" "${abind:-none}"
      fi
    fi
  fi

  # A subject carrying opposed verdicts is NAMED, never resolved. Resolving it
  # here would be the selection this file refuses to make.
  case ",$ST," in
    *,supported,*) case ",$ST," in
      *,refuted,*)
        RC_="$(printf '%s' "$MINE" | grep -v '^$' | while IFS= read -r id; do [ "$(gv "$id" status)" = "refuted"   ] && printf '%s ' "$(gv "$id" claim_id)"; done)"
        SC_="$(printf '%s' "$MINE" | grep -v '^$' | while IFS= read -r id; do [ "$(gv "$id" status)" = "supported" ] && printf '%s ' "$(gv "$id" claim_id)"; done)"
        printf 'contradiction: %s carries OPPOSED verdicts on different claims — refuted: %s| supported: %s| NEITHER collapses the other, and the composite above keeps both. Reading only the supported half is the flattering-direction error; reading only the refuted half is the demotion that was measured to destroy live memory.\n' \
          "$s" "$RC_" "$SC_"
        ;;
    esac ;;
  esac
done < <(printf '%s\n' "$SUBJECTS")

if [ "$NSUBJ" -eq 0 ]; then
  printf 'claim-evidence: no assertion names subject "%s" — nothing is projected for it, and an absent assertion is NOT a clean one\n' "$SUBJECT"
else
  printf 'claim-evidence: %s subject(s) projected from %s assertion(s) in %s\n' "$NSUBJ" "$NID" "$STORE"
fi
printf 'claim-evidence: ADVISORY. The composition is a MINIMUM, so evidence here can only LOWER a licence and can never raise one. Demoting or re-authorising any control named above is a governance action for the operator, and nothing here performs one.\n'
printf 'claim-evidence: the legacy projection is a COMPATIBILITY SHIM for a field that carries no scope. `supported` projects to `unvalidated` globally, so a well-evidenced control reads no better through it than an unmeasured one — the scoped claim is legible in %s and nowhere else.\n' "${STORE#"$REPO/"}"
exit 0
