#!/usr/bin/env bash
# Build OS — mutator census, stable-id substrate, and defect-class recurrence.
#
# WHAT THIS IS FOR. Three stores share one property: every object in them has an
# IMMUTABLE ID, and nothing in them is identified by a line number. This tool is
# what makes that property enforced rather than intended.
#
#   mutator_registry.txt   — the actions that change durable state
#   defect_classes.txt     — recurring defect kinds, and their occurrences
#   findings.txt           — gaps recorded FOR THE OPERATOR and not closed here
#
# THE SMALLEST SUBSTRATE THAT ACTUALLY HOLDS, AND WHY IT IS NOT A LEDGER. The
# obvious design is a central id ledger every store registers into. It was
# rejected: a ledger is a SECOND copy of every id, and a second copy with no
# reconciliation is DEFECT-0003, which this very layer registers as a defect
# class. So there is no ledger. The id set is DERIVED by scanning the stores, and
# uniqueness is checked across the derived set. An id exists because an object
# carries it — there is nowhere else for it to be recorded, and therefore nowhere
# for the two records to disagree.
#
# WHAT AN ID IS, EXACTLY:
#
#   <CLASS>-<NNNN>[-<slug>]     e.g. MUT-0001-rotation-live-file-replacement
#
# The class namespace is closed (see ID_CLASSES). The number is not meaningful
# beyond being unique within its class. THE SLUG IS PART OF THE ID AND IS
# THEREFORE FROZEN TOO: renaming the slug creates a different id, which is the
# intended cost, because an id whose text can be edited is a description.
#
# LINE NUMBERS ARE NAVIGATION HINTS AND NEVER IDENTITY. This is the rule the
# whole file exists to enforce, and it is enforced in three places, not one:
#   * `check` refuses any record key that looks like a `path:line`;
#   * `check` refuses any id that fails the format above;
#   * `project` REFUSES rather than rendering when a store's identity column
#     holds a path:line — because a projection is where identity quietly gets
#     replaced by position, and a pretty table is exactly what makes it invisible.
#
# WHAT THIS TOOL DOES NOT DO, named rather than implied away:
#   1. IT DOES NOT VERIFY WRITE SCOPES. `write_scope` is the author's word.
#      tests/mutator_registry_tests.sh derives that a declared mutation_type is
#      SUPPORTED by a cited line; nothing derives that the scope is COMPLETE.
#   2. IT DOES NOT DISCOVER MUTATORS. The anti-shelfware scan lives in the test
#      suite, where it can be independent of this parser. A census this tool
#      validated against itself would agree with itself forever.
#   3. IT DOES NOT COUNT HISTORY. `query` and `recurrence` count what has been
#      MIGRATED. Because migration is partial by design, every count is a LOWER
#      BOUND: this store can prove a defect recurs and can never prove one did not.
#   4. IT GRANTS NO AUTHORITY. It reads files and prints. It writes nothing,
#      anywhere, and it creates no control.
#
# Local only. No network.
#
# Usage:
#   scan-mutators.sh check       [--repo DIR]
#   scan-mutators.sh ids         [--repo DIR]
#   scan-mutators.sh mutators    [--repo DIR]
#   scan-mutators.sh query   ID  [--repo DIR]
#   scan-mutators.sh recurrence  [--repo DIR]
#   scan-mutators.sh project     [--repo DIR]
# Exit: 0 reconciled, 2 refused (a violation, or a scan that cannot be trusted).
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"
# The anchor resolver is node. A missing node must FAIL CLOSED on an anchored
# citation rather than silently skip it: "the resolver was unavailable" and
# "the evidence resolves" are different statements.
NODE_BIN="$(command -v node || true)"

refuse(){ printf 'scan-mutators: REFUSED — %s\n' "$*" >&2; exit 2; }
viol(){ VIOL=$((VIOL+1)); printf '  %s\n' "$*"; }
in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }

CMD="${1:-}"
[ $# -gt 0 ] && shift
QARG=""
case "$CMD" in
  check|ids|mutators|recurrence|project) ;;
  query) QARG="${1:-}"; [ -n "$QARG" ] && shift || refuse "query needs a defect_class_id" ;;
  -h|--help|help) sed -n '2,60p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") refuse "no command — expected one of: check, ids, mutators, query, recurrence, project" ;;
  *)  refuse "unknown command \"$CMD\" — expected one of: check, ids, mutators, query, recurrence, project" ;;
esac
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) [ $# -ge 2 ] || refuse "--repo needs a value"; REPO="$2"; shift 2 ;;
    -h|--help) sed -n '2,60p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done
[ -d "$REPO" ] || refuse "--repo is not a directory: $REPO"

MUTREG="$REPO/build-os/registry/mutator_registry.txt"
DEFREG="$REPO/build-os/registry/defect_classes.txt"
FINDREG="$REPO/build-os/registry/findings.txt"
BASELINE="$REPO/build-os/registry/governance_baseline.txt"
CTLREG="$REPO/build-os/registry/control_registry.txt"

for f in "$MUTREG" "$DEFREG" "$FINDREG"; do
  [ -f "$f" ] || refuse "no store at $f. An absent census is not an empty one."
done

# --- the ontology, as this tool enforces it ----------------------------------
ID_CLASSES="MUT CTRL DEFECT FINDING PACKET DECISION EVIDENCE OUTCOME SIGNAL-SNAPSHOT RANKING OCCURRENCE"
ID_RE='^(MUT|CTRL|DEFECT|FINDING|PACKET|DECISION|EVIDENCE|OUTCOME|SIGNAL-SNAPSHOT|RANKING|OCCURRENCE)-[0-9]{4}(-[a-z0-9][a-z0-9-]*)?$'
MUTATION_TYPES="create replace append delete commit lock"
DEPLOY_MODES="shadow human_confirmed bounded_autonomous autonomous"
AUTHORITIES="none observe advise rank gate execute"
IMPL_STATUSES="specified implemented runtime_observed decision_contributing load_bearing"
# `untested` — added with scan-controls.sh's copy, and for the same reason: the
# two enums are the same ontology and a mutator whose evidence level this scan
# refused while the control scan accepted it would be a split vocabulary.
EMP_STATUSES="untested unvalidated red_driven field_observed calibrated refuted"
MUT_FIELDS="control_id actor_or_tool trigger read_scope write_scope mutation_type rollback_behavior required_authority runtime_authority deployment_mode implementation_status empirical_status evidence_refs receipt_behavior"
MUT_OPTIONAL="notes"
DC_FIELDS="title root_cause_class description detection_signature migration_status"
OCC_FIELDS="defect_class_id packet_id detected_stage escaped_stage affected_objects root_cause_class symptom prevented_by could_have_been_prevented_by evidence_refs"
FIND_FIELDS="subject subject_kind observed_authority required_authority remedy remedy_applied authority_to_apply evidence_refs"
FIND_OPTIONAL="observed_at title description severity why_not_applied notes"

# Record keys, per store.
keys_of(){ awk -v k="$1" '$0 ~ "^"k": " {sub("^"k": ",""); print}' "$2"; }
field_of(){ # <key-word> <id> <field> <file>
  awk -v k="$1" -v i="$2" -v f="$3" '
    $0 == k": "i {inr=1; next}
    /^$/ {inr=0}
    inr && $0 ~ "^"f": " {sub("^"f": ",""); print; exit}' "$4"
}

# EVERY ID IN THE SYSTEM, DERIVED. Emitted as `id<TAB>class<TAB>store`, sorted, so
# the output is a stable set rather than a file order — which is what makes it
# comparable across an edit that moves every line.
all_ids(){
  { keys_of mutator      "$MUTREG"  | sed 's/$/\tMUT\tmutator_registry.txt/'
    keys_of defect_class "$DEFREG"  | sed 's/$/\tDEFECT\tdefect_classes.txt/'
    keys_of occurrence   "$DEFREG"  | sed 's/$/\tOCCURRENCE\tdefect_classes.txt/'
    keys_of finding      "$FINDREG" | sed 's/$/\tFINDING\tfindings.txt/'
  } | grep -v '^\t' | LC_ALL=C sort
}

if [ "$CMD" = "ids" ]; then
  all_ids
  exit 0
fi

if [ "$CMD" = "mutators" ]; then
  keys_of mutator "$MUTREG"
  exit 0
fi

# --- query: the occurrences of one defect class ------------------------------
# IT REFUSES AN UNREGISTERED CLASS RATHER THAN RETURNING NOTHING. An empty result
# set and "this has never happened" are the same bytes, and they are opposite
# facts. A typo in a class id must not read as evidence of safety.
if [ "$CMD" = "query" ]; then
  keys_of defect_class "$DEFREG" | grep -qxF "$QARG" \
    || refuse "no defect class \"$QARG\" is registered in $DEFREG. Returning an empty result would be indistinguishable from \"this has never happened\", which is the opposite fact."
  awk -v want="$QARG" '
    /^occurrence: /{id=$2; dc=""}
    /^defect_class_id: /{dc=$2; if (dc==want && id!="") { print id; id="" }}
  ' "$DEFREG"
  exit 0
fi

if [ "$CMD" = "recurrence" ]; then
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    n="$(awk -v want="$c" '/^occurrence: /{id=$2} /^defect_class_id: /{if($2==want && id!=""){print id; id=""}}' "$DEFREG" | grep -c . || true)"
    [ "${n:-0}" -gt 1 ] && printf '%s\t%s\n' "$c" "$n"
  done < <(keys_of defect_class "$DEFREG")
  exit 0
fi

# --- project: the census as a table ------------------------------------------
# THE REFUSAL IS THE POINT OF THIS SUBCOMMAND. Rendering a store whose keys are
# positions would produce a table that looks authoritative and has silently
# swapped identity for line numbers — the exact substitution this layer exists to
# prevent, made invisible by good formatting.
if [ "$CMD" = "project" ]; then
  BAD=""
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    printf '%s\n' "$id" | grep -qE "$ID_RE" || BAD="$BAD $id"
  done < <(keys_of mutator "$MUTREG")
  [ -n "$BAD" ] && refuse "the census cannot be projected: identit(ies)$BAD are not stable ids. A row keyed on a path:line renders perfectly and has replaced identity with position, which is what this refusal exists to stop."
  printf '| stable_mutator_id | control_id | actor_or_tool | mutation_type | required | runtime | rollback |\n'
  printf '|---|---|---|---|---|---|---|\n'
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    rb="$(field_of mutator "$id" rollback_behavior "$MUTREG")"
    case "$rb" in NONE*|None*|none*) rb="none" ;; *) rb="${rb%%[.;—]*}" ;; esac
    printf '| %s | %s | %s | %s | %s | %s | %s |\n' \
      "$id" \
      "$(field_of mutator "$id" control_id "$MUTREG")" \
      "$(field_of mutator "$id" actor_or_tool "$MUTREG")" \
      "$(field_of mutator "$id" mutation_type "$MUTREG")" \
      "$(field_of mutator "$id" required_authority "$MUTREG")" \
      "$(field_of mutator "$id" runtime_authority "$MUTREG")" \
      "${rb:0:48}"
  done < <(keys_of mutator "$MUTREG")
  exit 0
fi

# ---------------------------------------------------------------- check ------
VIOL=0

# --- 0. every store parses, and no store is empty ----------------------------
# VACUITY FIRST. Zero records is not "nothing to check"; it is the shelfware
# state, and it is what every store looks like the day after somebody decides it
# is too much trouble.
NMUT="$(keys_of mutator "$MUTREG" | grep -c . || true)"
NDC="$(keys_of defect_class "$DEFREG" | grep -c . || true)"
NOCC="$(keys_of occurrence "$DEFREG" | grep -c . || true)"
NFIND="$(keys_of finding "$FINDREG" | grep -c . || true)"
[ "${NMUT:-0}" -eq 0 ] && refuse "$MUTREG censuses 0 mutators. An empty census is not a clean one; it is an unclassified system wearing a registry."
[ "${NDC:-0}" -eq 0 ]  && refuse "$DEFREG registers 0 defect classes. Recurrence that is measured against nothing is prose again."
[ "${NOCC:-0}" -eq 0 ] && refuse "$DEFREG registers 0 occurrences. A class taxonomy with no instances proves a schema and nothing about this repository."

# Malformed-line detection, per store: a line that is neither blank, nor a
# comment, nor `field: value` means the file cannot be read field by field, which
# was the entire reason for choosing this format.
for store in "$MUTREG" "$DEFREG" "$FINDREG"; do
  LN=0; BADLINES=""
  while IFS= read -r line || [ -n "$line" ]; do
    LN=$((LN+1)); line="${line%$'\r'}"
    case "$line" in ''|'#'*) continue ;; esac
    case "$line" in *": "*) ;; *) BADLINES="$BADLINES line $LN;" ;; esac
  done < "$store"
  [ -n "$BADLINES" ] && refuse "$store is malformed — not \"field: value\" at: ${BADLINES%;}"
done

# --- 1. THE ID SUBSTRATE: format, namespace, and uniqueness ------------------
ALL="$(all_ids)"
NIDS="$(printf '%s\n' "$ALL" | grep -c . || true)"
[ "${NIDS:-0}" -eq 0 ] && refuse "0 stable ids were derived from the stores. A uniqueness check over an empty set certifies every duplicate at once."

while IFS=$'\t' read -r id cls store; do
  [ -n "$id" ] || continue
  # A key that is a path:line is the failure this whole layer exists against, and
  # it is reported as itself rather than as a generic format error.
  case "$id" in
    *:[0-9]*) viol "POSITION-AS-ID  \"$id\" in $store is a path:line, not an identity. Line numbers may remain navigation hints; they may not be identity — an identifier that moves when somebody adds a comment above it is a position." ; continue ;;
  esac
  printf '%s\n' "$id" | grep -qE "$ID_RE" \
    || { viol "MALFORMED-ID    \"$id\" in $store does not match <CLASS>-<NNNN>[-<slug>] with CLASS in: $ID_CLASSES"; continue; }
  pfx="${id%%-[0-9][0-9][0-9][0-9]*}"
  in_list "$pfx" "$ID_CLASSES" || viol "UNKNOWN-CLASS   \"$id\" uses namespace \"$pfx\", which is not one of: $ID_CLASSES"
  [ "$pfx" = "$cls" ] || viol "WRONG-NAMESPACE \"$id\" lives in $store, whose records take the $cls namespace, but declares \"$pfx\". Namespaces are per-store so that an id names the kind of thing it identifies."
done < <(printf '%s\n' "$ALL")

# UNIQUENESS ACROSS EVERY STORE, not per store. An id that means one thing here
# and another thing there is worse than a duplicate: both references resolve.
DUPS="$(printf '%s\n' "$ALL" | cut -f1 | LC_ALL=C sort | uniq -d)"
while IFS= read -r d; do
  [ -n "$d" ] || continue
  viol "DUPLICATE-ID    \"$d\" is claimed more than once ($(printf '%s\n' "$ALL" | awk -F'\t' -v i="$d" '$1==i{printf "%s ", $3}')). An id that can be claimed twice is not an id, and this is the exact shape a copy-paste produces."
done < <(printf '%s\n' "$DUPS")

# --- 2. the mutator census ---------------------------------------------------
while IFS= read -r id; do
  [ -n "$id" ] || continue
  for f in $MUT_FIELDS; do
    v="$(field_of mutator "$id" "$f" "$MUTREG")"
    [ -n "$v" ] || viol "INCOMPLETE      $id has no \"$f\". A partially declared mutator is an undeclared one."
  done
  mt="$(field_of mutator "$id" mutation_type "$MUTREG")"
  dm="$(field_of mutator "$id" deployment_mode "$MUTREG")"
  ra="$(field_of mutator "$id" required_authority "$MUTREG")"
  rt="$(field_of mutator "$id" runtime_authority "$MUTREG")"
  im="$(field_of mutator "$id" implementation_status "$MUTREG")"
  em="$(field_of mutator "$id" empirical_status "$MUTREG")"
  cid="$(field_of mutator "$id" control_id "$MUTREG")"
  act="$(field_of mutator "$id" actor_or_tool "$MUTREG")"
  in_list "$mt" "$MUTATION_TYPES" || viol "ENUM            $id mutation_type \"$mt\" is not one of: $MUTATION_TYPES"
  in_list "$dm" "$DEPLOY_MODES"   || viol "ENUM            $id deployment_mode \"$dm\" is not one of: $DEPLOY_MODES"
  in_list "$ra" "$AUTHORITIES"    || viol "ENUM            $id required_authority \"$ra\" is not one of: $AUTHORITIES"
  in_list "$rt" "$AUTHORITIES"    || viol "ENUM            $id runtime_authority \"$rt\" is not one of: $AUTHORITIES"
  in_list "$im" "$IMPL_STATUSES"  || viol "ENUM            $id implementation_status \"$im\" is not one of: $IMPL_STATUSES"
  in_list "$em" "$EMP_STATUSES"   || viol "ENUM            $id empirical_status \"$em\" is not one of: $EMP_STATUSES"
  [ -n "$act" ] && [ -f "$REPO/$act" ] \
    || viol "NO-ACTOR        $id names actor_or_tool \"$act\", which is not a file under $REPO"

  # The control_id must resolve, and the copied runtime_authority must match the
  # live entry. WHERE THEY DISAGREE THE REGISTRY IS RIGHT AND THIS FILE IS STALE;
  # this refuses rather than picking a winner, because silently preferring either
  # is how two files that describe one fact drift apart.
  if [ -f "$CTLREG" ]; then
    if grep -qxF "control: $cid" "$CTLREG"; then
      live="$(field_of control "$cid" runtime_authority "$CTLREG")"
      [ "$rt" = "$live" ] \
        || viol "STALE-COPY      $id copies runtime_authority \"$rt\" for $cid, but control_registry.txt says \"$live\". The registry is the authority; this census is stale."
    else
      viol "NO-CONTROL      $id names control_id \"$cid\", which owns no entry in control_registry.txt. A mutator classified by nothing is an unclassified mutator."
    fi
  fi

  # required_authority may not sit BELOW runtime_authority. The gap this census
  # is built to record runs one way — behaviour needing MORE than it was granted.
  # The reverse would mean a control is granted authority its behaviour does not
  # need, which is a different finding and must not be recorded by accident here.
  rank_of(){ case "$1" in none) echo 0 ;; observe) echo 1 ;; advise) echo 2 ;; rank) echo 3 ;; gate) echo 4 ;; execute) echo 5 ;; *) echo -1 ;; esac; }
  [ "$(rank_of "$ra")" -lt "$(rank_of "$rt")" ] \
    && viol "INVERTED        $id declares required_authority \"$ra\" BELOW runtime_authority \"$rt\". This census records behaviour needing more authority than it was granted; the reverse is a different claim and is not recordable here."

  # Evidence must resolve. It is a NAVIGATION HINT, so it is checked for landing
  # in a real file at a real line and for nothing else — no identity depends on it.
  nref=0
  for ref in $(field_of mutator "$id" evidence_refs "$MUTREG" | tr ';' ' '); do
    [ -n "$ref" ] || continue
    nref=$((nref+1))
    # ANCHORED FORM (path#c:hex) resolves by CONTENT; the positional form is
    # unchanged. Per ANCHOR-CONTRACT.md v1 both are legal during the migration,
    # and an anchor that cannot be resolved fails CLOSED — "the resolver was
    # unavailable" is not "the evidence resolves".
    case "$ref" in
      *'#c:'*)
        rf="${ref%%#c:*}"
        [ -f "$REPO/$rf" ] || { viol "NO-EVIDENCE     $id cites $ref, but $rf is not a file under $REPO"; continue; }
        if [ -z "$NODE_BIN" ]; then
          viol "ANCHOR-UNRESOLVABLE $id cites $ref but node is unavailable, so the anchor cannot be resolved. Failing closed."
          continue
        fi
        _res="$("$NODE_BIN" "$SELF_DIR/anchor-resolve.mjs" "$REPO" "$ref" 2>/dev/null | head -n1)"
        case "$(printf '%s' "$_res" | cut -f2)" in
          RESOLVED)  rl="$(printf '%s' "$_res" | cut -f3)" ;;
          AMBIGUOUS) viol "ANCHOR-AMBIGUOUS $id cites $ref, whose content occurs $(printf '%s' "$_res" | cut -f4) times in $rf — content naming more than one line identifies no object"; continue ;;
          STALE)     viol "ANCHOR-STALE    $id cites $ref, but no line in $rf carries that content any more — the cited text was edited or removed"; continue ;;
          *)         viol "ANCHOR-UNRESOLVED $id cites $ref and the resolver returned an unexpected state"; continue ;;
        esac
        ;;
      *)
        rf="${ref%:*}"; rl="${ref##*:}"
        [ -f "$REPO/$rf" ] || { viol "NO-EVIDENCE     $id cites $ref, but $rf is not a file under $REPO"; continue; }
        case "$rl" in ''|*[!0-9]*) viol "NO-EVIDENCE     $id cites \"$ref\", which carries no line number"; continue ;; esac
        ;;
    esac
    tot="$(wc -l < "$REPO/$rf" | tr -d ' ')"
    { [ "$rl" -ge 1 ] && [ "$rl" -le "${tot:-0}" ]; } \
      || viol "NO-EVIDENCE     $id cites $ref, which is past the end of a ${tot:-0}-line file"
  done
  [ "$nref" -ge 1 ] || viol "NO-EVIDENCE     $id cites no evidence at all"

  # Unknown fields, so that a typo'd field name is not silently dropped — the
  # quietest way for a required value to go missing while the record looks full.
  awk -v k="mutator: $id" -v ok=" $MUT_FIELDS $MUT_OPTIONAL " '
    $0 == k {inr=1; next} /^$/ {inr=0}
    inr && /^[a-z_]+: / { f=$0; sub(/: .*$/,"",f); if (index(ok, " " f " ")==0) print f }
  ' "$MUTREG" | while IFS= read -r uf; do
    [ -n "$uf" ] && printf '  UNKNOWN-FIELD   %s carries "%s", which is not in the declared record shape\n' "$id" "$uf"
  done | { grep . && VIOL=$((VIOL+1)); } || true
done < <(keys_of mutator "$MUTREG")

# --- 3. defect classes and occurrences ---------------------------------------
while IFS= read -r id; do
  [ -n "$id" ] || continue
  for f in $DC_FIELDS; do
    [ -n "$(field_of defect_class "$id" "$f" "$DEFREG")" ] \
      || viol "INCOMPLETE      defect class $id has no \"$f\""
  done
done < <(keys_of defect_class "$DEFREG")

while IFS= read -r id; do
  [ -n "$id" ] || continue
  for f in $OCC_FIELDS; do
    [ -n "$(field_of occurrence "$id" "$f" "$DEFREG")" ] \
      || viol "INCOMPLETE      occurrence $id has no \"$f\""
  done
  dc="$(field_of occurrence "$id" defect_class_id "$DEFREG")"
  keys_of defect_class "$DEFREG" | grep -qxF "$dc" \
    || viol "DANGLING-CLASS  occurrence $id references defect class \"$dc\", which is not registered. An occurrence of nothing counts toward nothing."
done < <(keys_of occurrence "$DEFREG")

# THE RECURRENCE PROOF IS PART OF THE CHECK, not only of the suite. A store in
# which every class has exactly one occurrence demonstrates the schema and
# nothing about recurrence, which is the only thing the schema is for.
NRECUR="$(while IFS= read -r c; do
  [ -n "$c" ] || continue
  n="$(awk -v want="$c" '/^occurrence: /{i=$2} /^defect_class_id: /{if($2==want && i!=""){print i; i=""}}' "$DEFREG" | grep -c . || true)"
  [ "${n:-0}" -gt 1 ] && printf 'x\n'
done < <(keys_of defect_class "$DEFREG") | grep -c . || true)"
[ "${NRECUR:-0}" -ge 1 ] \
  || viol "NO-RECURRENCE   no defect class has more than one migrated occurrence. The store proves a schema and not a recurrence, which is the one thing it exists to measure."

# --- 4. findings: recorded, and NOT discharged in silence --------------------
while IFS= read -r id; do
  [ -n "$id" ] || continue
  for f in $FIND_FIELDS; do
    [ -n "$(field_of finding "$id" "$f" "$FINDREG")" ] \
      || viol "INCOMPLETE      finding $id has no \"$f\""
  done
  applied="$(field_of finding "$id" remedy_applied "$FINDREG")"
  auth="$(field_of finding "$id" authority_to_apply "$FINDREG")"
  subj="$(field_of finding "$id" subject "$FINDREG")"
  kind="$(field_of finding "$id" subject_kind "$FINDREG")"
  obs="$(field_of finding "$id" observed_authority "$FINDREG")"
  case "$applied" in yes|no) ;; *) viol "ENUM            finding $id remedy_applied \"$applied\" is not yes|no" ;; esac
  [ "$auth" = "operator" ] \
    || viol "AUTHORITY       finding $id claims authority_to_apply \"$auth\". Every finding here proposes moving a control's runtime authority, and that is a re-authorisation: the operator's act, never the builder's."
  if [ "$applied" = "no" ]; then
    case "$kind" in
      control) live="$(field_of control "$subj" runtime_authority "$CTLREG")" ;;
      mutator) live="$(field_of mutator "$subj" runtime_authority "$MUTREG")" ;;
      *)       live=""; viol "ENUM            finding $id subject_kind \"$kind\" is not control|mutator" ;;
    esac
    [ "$live" = "$obs" ] \
      || viol "DISCHARGED      finding $id records $subj at \"$obs\" with remedy_applied: no, but the live store says \"$live\". Either the remedy was applied and the finding was not updated, or the finding is stale — both leave an accusation standing against a state that no longer exists."
  fi
done < <(keys_of finding "$FINDREG")

# --- 5. the governance baseline: new controls yes, moved controls no ---------
# The baseline is what separates AUTHORISED work (registering a new control) from
# a GOVERNANCE act (moving an existing one). It is checked here as well as in the
# suite so that the refusal is available to anybody running the tool by hand.
if [ -f "$BASELINE" ] && [ -f "$CTLREG" ]; then
  NBASE="$(awk '!/^#/ && NF>0' "$BASELINE" | grep -c . || true)"
  [ "${NBASE:-0}" -eq 0 ] && refuse "$BASELINE pins 0 controls. A baseline with nothing in it certifies every re-authorisation at once."
  while IFS=$'\t' read -r bid bcls baut bmm; do
    [ -n "$bid" ] || continue
    if ! grep -qxF "control: $bid" "$CTLREG"; then
      viol "BASELINE-GONE   $bid is pinned by the governance baseline but no longer exists in the control registry."
      continue
    fi
    lcls="$(field_of control "$bid" class "$CTLREG")"
    laut="$(field_of control "$bid" runtime_authority "$CTLREG")"
    lmm="$(field_of control "$bid" authority_mismatch "$CTLREG")"
    [ "$lcls" = "$bcls" ] || viol "RE-AUTHORISED   $bid class moved $bcls -> $lcls without the baseline being edited."
    [ "$laut" = "$baut" ] || viol "RE-AUTHORISED   $bid runtime_authority moved $baut -> $laut without the baseline being edited. Registering a NEW control is authorised work; moving an EXISTING one is the operator's."
    [ "$lmm"  = "$bmm"  ] || viol "RE-AUTHORISED   $bid authority_mismatch moved $bmm -> $lmm without the baseline being edited."
  done < <(awk '!/^#/ && NF>0' "$BASELINE")
fi

printf 'scan-mutators: %s mutator(s), %s defect class(es), %s occurrence(s), %s finding(s), %s stable id(s)\n' \
  "$NMUT" "$NDC" "$NOCC" "$NFIND" "$NIDS"
printf 'scan-mutators: %s class(es) recur (more than one migrated occurrence) — a LOWER BOUND, because migration is partial by design\n' "$NRECUR"

if [ "$VIOL" -gt 0 ]; then
  printf 'scan-mutators: REFUSED — %s violation(s) across the mutator, defect and finding stores.\n' "$VIOL" >&2
  printf 'Do NOT clear a DISCHARGED violation by deleting the finding, and do NOT clear a\nRE-AUTHORISED violation by editing the baseline to match. Both are the governance\nact this layer exists to make visible; performing one is the operator%s decision.\n' "'s" >&2
  exit 2
fi
exit 0
