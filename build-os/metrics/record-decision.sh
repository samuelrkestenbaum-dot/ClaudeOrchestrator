#!/usr/bin/env bash
# Build OS — decision telemetry, and decision-time signal snapshots.
#
# TWO STORES, ONE TOOL, AND THEY ARE NOT THE SAME KIND OF THING.
#
#   decision_telemetry.tsv  — what was chosen, why, what it cost, what happened.
#                             A RECORD. An appended row can be deleted.
#   signal_snapshots.tsv    — the value a signal HAD at the moment a decision was
#                             taken. EVIDENCE. It is digest-chained, and a row
#                             cannot be edited or removed without breaking every
#                             row after it.
#
# ---------------------------------------------------------------------------
# THE ONE RULE THAT MATTERS MOST: AN UNKNOWN IS NOT A ZERO.
# ---------------------------------------------------------------------------
# A measurement store that writes 0 for "nobody measured this" is WORSE THAN NO
# STORE. The zero is indistinguishable from a real measurement, it averages, it
# sums, it ranks, and every conclusion drawn from it is confidently wrong. This
# is not hypothetical here: the telemetry this layer starts collecting will be
# read by something that ranks candidates, and a candidate that looks free
# because nobody timed it will win.
#
# So every quantitative field is one of exactly two shapes:
#
#     unknown                 nobody measured it, and that is a fact worth storing
#     <value>@<provenance>    somebody did, and this is HOW they know
#
# with provenance in `measured` / `derived` / `reported`:
#
#     measured   observed directly by an instrument at the time
#     derived    computed from other recorded values by a method written down
#     reported   asserted by a human or an agent from memory
#
# A BARE NUMBER IS REFUSED. `--wall-minutes 42` is rejected; `42@measured` and
# `42@reported` are accepted and mean different things. There is no default
# provenance, because a default would be a guess wearing a value's clothes.
#
# AND OMISSION YIELDS `unknown`, NEVER 0. Every field not named on the command
# line is written `unknown`. The easy path and the honest path are the same path,
# which is the only way this rule survives contact with somebody in a hurry.
#
# `0@measured` IS LEGAL AND IS NOT AN UNKNOWN. Zero fix rounds is a real and
# valuable measurement. The whole point of the distinction is that this store can
# tell it apart from nobody having counted.
#
# ---------------------------------------------------------------------------
# WHY SNAPSHOTS ARE FROZEN, AND WHAT BREAKS WITHOUT THEM
# ---------------------------------------------------------------------------
# A signal used in a decision is a fact about the tree AT THAT MOMENT. Recomputing
# it later against the current tree does not evaluate the decision that was made;
# it evaluates a decision nobody took, using information nobody had. Every
# retrospective built that way flatters or damns the past with the present's
# knowledge.
#
# So a snapshot stores the VALUE, not a way to recompute it, together with the
# `repository_commit` it was frozen at and the `derivation_version` that produced
# it. Changing the live registry afterwards cannot move it, because nothing about
# reading it consults the tree.
#
# THE CHAIN, AND EXACTLY WHAT IT DOES AND DOES NOT PROVE. Each row carries a
# digest over its own ten fields plus the previous row's digest. Editing a
# historical value breaks that row's digest and every digest after it, so a
# retroactive edit is detectable by `snapshot-verify` rather than by somebody
# remembering what the number used to be.
#
# WHAT IT DOES NOT PROVE, named rather than implied away: THE CHAIN IS NOT
# TAMPER-PROOF, IT IS TAMPER-EVIDENT, and only against an edit. Anyone who can
# write this file can also rewrite every digest from the edit forward and produce
# a self-consistent chain — there is no signature and no external anchor, and
# adding one would be a different packet. What the chain defeats is the realistic
# case: somebody changing an inconvenient historical number in place. What it does
# not defeat is somebody deliberately forging the history, and it is not sold as
# doing so. The commit history is the only real anchor, and it is outside this
# tool.
#
# ---------------------------------------------------------------------------
# RANKING < SELECTION < EXECUTION, AND IT IS A REFUSAL RATHER THAN A COMMENT
# ---------------------------------------------------------------------------
# A ranking formed AFTER a choice is a rationalisation, and it is byte-identical
# to one formed before. Nothing about the artefact distinguishes them, so the
# order has to be something this tool refuses to violate rather than something a
# header asserts.
#
# WHAT THE ENFORCEMENT IS ACTUALLY BUILT ON — stated plainly, because the failure
# this project keeps re-paying is RESOLVABILITY MISTAKEN FOR IDENTITY, and a
# timestamp that PARSES is not a timestamp that PROVES ORDERING. Self-reported
# times written in one commit by one author establish nothing about sequence.
#
#   CONSTITUTIVE — EXISTENCE ORDER ACROSS TWO STORES THAT ARE DIFFERENT KINDS OF
#   THING. `seal-ranking` may only write while the decision has NO row in
#   decision_telemetry.tsv; `outcome` may only write once it HAS one; `record`
#   may only write a selection whose candidate set is exactly the sealed one.
#   None of those is a self-report: each is the state of a store at the instant
#   of the write, and the seal lands in the digest-chained snapshot file where
#   every subsequent row's digest covers it.
#
#   CORROBORATING — THE ISO-8601 STRINGS, AND THEY ARE WORTH MUCH LESS. They are
#   compared, and a contradiction is refused, because a contradiction is cheap to
#   catch and always means something is wrong. AGREEMENT BETWEEN THEM PROVES
#   NOTHING and is never treated as proof.
#
#   OUTSIDE BOTH, AND THE ONLY REAL ANCHOR — GIT. A seal is committed before any
#   commit can carry its selection. That is the same anchor the shadow ranker's
#   non-circularity rests on: commit times across separate commits, not a field
#   somebody typed.
#
#   WHAT NONE OF IT DEFEATS — the same thing the chain does not defeat. Anyone
#   who can write these files can delete a row, seal, and re-add it. This is
#   tamper-EVIDENT against the realistic case and is not sold as tamper-proof.
#
# ---------------------------------------------------------------------------
# THE SELECTION AND THE OUTCOME ARE SEPARABLE RECORDS, BY PARTITION
# ---------------------------------------------------------------------------
# Discovering that the chosen candidate mattered is evidence about the CANDIDATE.
# It is not yet evidence that anything ranked it for the right reasons. If one
# command could write both halves of a row, "what was chosen" and "what happened"
# would be one editable object and no later reader could tell which had been
# adjusted to fit the other.
#
# So every column belongs to EXACTLY ONE of two sets, the partition is checked
# against the schema at run time rather than trusted, and a third set names the
# ranker-evidence fields that NEITHER path may write. `record` writes the
# selection half; `outcome` writes the outcome half; neither reaches the other's.
#
# ---------------------------------------------------------------------------
# WHAT THIS IS NOT
# ---------------------------------------------------------------------------
# Not a database, not an event-sourcing framework, not a ranker. Two TSV files and
# a shell script, chosen because the substrate has to be the one this repository
# already has. The schemas are versioned so they can migrate later; nothing here
# learns anything, orders anything, or dispatches anything. IT ADDS NO STORE: the
# sealed ordering is snapshot rows in the file that already holds frozen evidence,
# and the outcome is the outcome columns decision_telemetry.tsv already declares.
#
# Usage:
#   record-decision.sh record          --decision-id ID --decision-time T … [--store F]
#   record-decision.sh get             ID FIELD              [--store F]
#   record-decision.sh snapshot        --snapshot-id ID …    [--snapshots F]
#   record-decision.sh get-snapshot    ID FIELD              [--snapshots F]
#   record-decision.sh snapshot-verify                       [--snapshots F]
#   record-decision.sh validate                              [--store F] [--snapshots F]
#   record-decision.sh report                                [--store F]
#   record-decision.sh seal-ranking    --decision-id ID --candidate-ids A;B --ordering 1:A;2:B …
#   record-decision.sh outcome         --decision-id ID --result R …        [--store F]
#   record-decision.sh outcome-report  --decision-id ID          [--store F] [--snapshots F]
#   record-decision.sh fields
# Exit: 0 ok, 2 refused.
set -uo pipefail
# NO PATHNAME EXPANSION. Candidate ids, orderings and snapshot ids are split on
# `;` and iterated unquoted; without this a token carrying a glob metacharacter
# would be expanded against whatever directory the tool happens to run from, so
# the same command would mean different things from two shells. That exact defect
# already cost this repository one review round in the ranker.
set -f

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORE="$SELF_DIR/decision_telemetry.tsv"
SNAPS="$SELF_DIR/signal_snapshots.tsv"
TAB=$'\t'

die(){ printf 'record-decision: REFUSED — %s\n' "$*" >&2; exit 2; }

SCHEMA_VERSION="decision-telemetry-v1"
SNAP_SCHEMA_VERSION="signal-snapshot-v1"

# The column order IS the schema. Both are declared once, here, and every reader
# and writer below derives its indices from these rather than from a literal.
COLS="decision_id decision_time candidate_ids selected_candidate_id selector selection_reason expected_outcome signal_snapshot_ref started_at completed_at wall_minutes serial_minutes agent_minutes human_attention_minutes model_calls estimated_tokens estimated_cost estimated_energy fix_rounds review_rounds defect_classes_introduced defect_classes_detected defect_classes_escaped rework_count rollback_count result durability_status"
SNAP_COLS="snapshot_id decision_id captured_at repository_commit candidate_id signal_name signal_value derivation_version source_object_versions evidence_refs prev_digest digest"

# THE QUANTITATIVE FIELDS — the ones an unknown must never become a zero in.
QUANT="wall_minutes serial_minutes agent_minutes human_attention_minutes model_calls estimated_tokens estimated_cost estimated_energy fix_rounds review_rounds rework_count rollback_count"
# The list-valued fields: `unknown`, or `;`-separated stable ids.
LISTY="candidate_ids defect_classes_introduced defect_classes_detected defect_classes_escaped"
REQUIRED="decision_id decision_time candidate_ids selected_candidate_id selector selection_reason expected_outcome"

# --- THE PARTITION. Every column is in exactly one of these two. --------------
# SELECTION is what was chosen and why: it is fixed at the moment of the choice
# and nothing that happens afterwards may reach it. OUTCOME is what the choice
# then cost and produced: it does not exist yet when the selection is recorded,
# and `record` may therefore only name one of these columns with the literal
# `unknown`, which is what omission already yields.
SELECTION_COLS="decision_id decision_time candidate_ids selected_candidate_id selector selection_reason expected_outcome signal_snapshot_ref"
OUTCOME_COLS="started_at completed_at wall_minutes serial_minutes agent_minutes human_attention_minutes model_calls estimated_tokens estimated_cost estimated_energy fix_rounds review_rounds defect_classes_introduced defect_classes_detected defect_classes_escaped rework_count rollback_count result durability_status"
# THE THIRD SET, WHICH NAMES NO COLUMN ON PURPOSE. These are facts about the
# RANKER, not about the candidate: where a ranking put the thing a human then
# chose, whether the two agreed, how well the rule scored. They are DERIVED on
# demand by whatever holds the ranking rule, and this store refuses to hold them,
# because an outcome row that also carried the ranker's score would let "the
# selected packet turned out well" be read as "the ranking was correct" — two
# different claims that no amount of prose keeps apart once they share a row.
RANKER_FIELDS="rank_of_selected ranking_agreement ranker_skill ranking_digest counterfactual_regret sealed_rank"
# THE SIGNAL NAME THE SEALED ORDERING IS WRITTEN UNDER, in the snapshot store.
SEAL_SIGNAL="sealed_rank"
# NO OUTCOME FIELD HAS A DECLARED DIRECTION, AND THAT IS DELIBERATE. Whether more
# `defect_classes_detected` means a better gate or a worse packet has never been
# decided here; nor has whether `superseded` is better or worse than `abandoned`.
# Every recorded outcome value is therefore reported as UNINTERPRETED and scores
# nothing. Declaring directions is what would turn outcome telemetry into
# weights, and inventing one here would put an unregistered constant inside every
# ordering that later read it.
OUTCOME_DIRECTION=""

PROVENANCE="measured derived reported"
SELECTORS="operator orchestrator reviewer builder automatic unknown"
RESULTS="unknown in_flight shipped reverted abandoned superseded"
DURABILITY="unknown durable eroded reverted superseded"
DECISION_ID_RE='^DECISION-[0-9]{4}(-[a-z0-9][a-z0-9-]*)?$'
SNAP_ID_RE='^SIGNAL-SNAPSHOT-[0-9]{4}(-[a-z0-9][a-z0-9-]*)?$'

ncols(){ printf '%s\n' $COLS | grep -c .; }
idx_of(){ local i=0 c; for c in $COLS; do i=$((i+1)); [ "$c" = "$1" ] && { echo "$i"; return 0; }; done; echo 0; }
snap_idx_of(){ local i=0 c; for c in $SNAP_COLS; do i=$((i+1)); [ "$c" = "$1" ] && { echo "$i"; return 0; }; done; echo 0; }
in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }
count_of(){ printf '%s\n' $1 | grep -c . || true; }
# Split a `;`-separated field into one item per line. `read` performs no
# expansion, so a token carrying a metacharacter cannot become a filename here
# even without `set -f` — both belts are worn on purpose.
semi_lines(){ local s="$1" p; while [ -n "$s" ]; do p="${s%%;*}"; [ -n "$p" ] && printf '%s\n' "$p"; case "$s" in *';'*) s="${s#*;}" ;; *) s="" ;; esac; done; }

# THE PARTITION IS CHECKED, NOT TRUSTED. A column added to COLS and forgotten by
# both sets would otherwise be a column that neither path owns and both could
# reach. It fails CLOSED: an unowned or double-owned column stops the tool.
assert_partition(){
  local c both="" unowned=""
  for c in $COLS; do
    if in_list "$c" "$SELECTION_COLS" && in_list "$c" "$OUTCOME_COLS"; then both="$both $c"
    elif in_list "$c" "$SELECTION_COLS" || in_list "$c" "$OUTCOME_COLS"; then :
    else unowned="$unowned $c"; fi
  done
  [ -z "$both" ] || die "the field partition is broken: column(s)$both belong to BOTH the selection set and the outcome set, so an outcome write could reach a selection field."
  [ -z "$unowned" ] || die "the field partition is incomplete: column(s)$unowned belong to NEITHER set. A column nobody owns is a column both write paths may reach; classify it before using this tool."
  for c in $RANKER_FIELDS; do
    in_list "$c" "$COLS" && die "the ranker-evidence field \"$c\" has become a column of this store. Evidence about the RANKER may not live in the record of the CANDIDATE's outcome; that is the separation this partition exists to keep."
  done
}

# ISO-8601 strings compare lexically, and that is ALL this does. It is a
# CORROBORATING check: a contradiction is always wrong and cheap to catch, but
# agreement between two strings somebody typed proves nothing about sequence.
# Returns 0 when a is strictly before b.
before(){ [ "$1" \< "$2" ]; }

# THE HASHER IS RESOLVED ONCE, and its absence is FAIL-CLOSED for anything that
# touches the chain. A snapshot tool that silently stopped chaining on a machine
# with no sha256sum would produce a store that looks immutable and is not.
HASHER=()
if _h="$(command -v sha256sum 2>/dev/null)"; then HASHER=("${_h}")
elif _h="$(command -v shasum 2>/dev/null)"; then HASHER=("${_h}" -a 256)
fi
digest_of(){ # reads stdin
  [ ${#HASHER[@]} -eq 0 ] && die "neither sha256sum nor shasum is available. The snapshot chain cannot be computed or checked on this machine, and continuing would write rows that LOOK chained and are not."
  local h; h="$("${HASHER[@]}")"; printf '%s' "${h%% *}"
}

CMD="${1:-}"
[ $# -gt 0 ] && shift
case "$CMD" in
  record|snapshot|snapshot-verify|validate|report) ;;
  seal-ranking|outcome|outcome-report|fields) ;;
  get|get-snapshot)
    GID="${1:-}"; GFIELD="${2:-}"
    [ -n "$GID" ] && [ -n "$GFIELD" ] || die "$CMD needs an ID and a FIELD"
    shift 2 ;;
  # Through the `Exit:` line rather than to a fixed number: this header has grown
  # twice and a numeric bound silently starts truncating it when it does.
  -h|--help|help) sed -n '2,/^# Exit: /p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") die "no command — expected one of: record, get, snapshot, get-snapshot, snapshot-verify, validate, report, seal-ranking, outcome, outcome-report, fields" ;;
  *)  die "unknown command \"$CMD\"" ;;
esac

# Every remaining `--flag value` becomes a field. `--wall-minutes` sets
# `wall_minutes`; the mapping is mechanical so a new column needs no new flag.
declare -A F=()
while [ $# -gt 0 ]; do
  case "$1" in
    --store)     [ $# -ge 2 ] || die "--store needs a value";     STORE="$2"; shift 2 ;;
    --snapshots) [ $# -ge 2 ] || die "--snapshots needs a value"; SNAPS="$2"; shift 2 ;;
    -h|--help)   sed -n '2,/^# Exit: /p' "${BASH_SOURCE[0]}"; exit 0 ;;
    --*)
      k="${1#--}"; k="${k//-/_}"
      [ $# -ge 2 ] || die "--${1#--} needs a value"
      F["$k"]="$2"; shift 2 ;;
    *) die "unexpected argument \"$1\"" ;;
  esac
done

ensure_store(){ # <file> <schema> <cols...>
  local f="$1" schema="$2"; shift 2
  [ -f "$f" ] && return 0
  { printf '# %s\n' "$schema"
    printf '%s\n' "$(printf '%s\t' "$@" | sed 's/\t$//')"; } > "$f" || die "cannot create $f"
}

# --------------------------------------------------------------- validate ----
validate_quant(){ # <field> <value> -> prints a reason, or nothing
  local f="$1" v="$2"
  [ "$v" = "unknown" ] && return 0
  case "$v" in
    *@*)
      local num="${v%@*}" prov="${v##*@}"
      in_list "$prov" "$PROVENANCE" \
        || { printf '%s has provenance "%s", which is not one of: %s' "$f" "$prov" "$PROVENANCE"; return 0; }
      case "$num" in
        ''|*[!0-9.]*) printf '%s has value "%s", which is not a number' "$f" "$num" ;;
        *) : ;;
      esac ;;
    *)
      printf '%s is "%s" — a bare value with no provenance. Write "%s@measured", "%s@derived" or "%s@reported", or leave it `unknown`. A number nobody can trace is the value this store exists to refuse' "$f" "$v" "$v" "$v" "$v" ;;
  esac
}

validate_row(){ # <row-as-tab-string> <where>
  local row="$1" where="$2" e="" i=0 c v
  local n; n="$(printf '%s' "$row" | awk -F'\t' '{print NF}')"
  [ "$n" = "$(ncols)" ] || { printf '%s: has %s fields, expected %s\n' "$where" "$n" "$(ncols)" >&2; return 1; }
  for c in $COLS; do
    i=$((i+1))
    v="$(printf '%s' "$row" | cut -f"$i")"
    [ -n "$v" ] || e="$e; $c is empty (write \`unknown\`, which is a value; empty is an absence and they are different)"
    case " $QUANT " in *" $c "*) local r; r="$(validate_quant "$c" "$v")"; [ -n "$r" ] && e="$e; $r" ;; esac
    case "$c" in
      decision_id) printf '%s\n' "$v" | grep -qE "$DECISION_ID_RE" || e="$e; decision_id \"$v\" is not a DECISION-NNNN[-slug] stable id" ;;
      selector)    in_list "$v" "$SELECTORS"  || e="$e; selector \"$v\" is not one of: $SELECTORS" ;;
      result)      in_list "$v" "$RESULTS"    || e="$e; result \"$v\" is not one of: $RESULTS" ;;
      durability_status) in_list "$v" "$DURABILITY" || e="$e; durability_status \"$v\" is not one of: $DURABILITY" ;;
    esac
  done
  [ -n "$e" ] && { printf '%s invalid: %s\n' "$where" "${e#; }" >&2; return 1; }
  return 0
}

if [ "$CMD" = "validate" ]; then
  [ -f "$STORE" ] || die "no telemetry store at $STORE"
  bad=0; n=0
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    case "$line" in "decision_id$TAB"*) continue ;; esac
    n=$((n+1))
    validate_row "$line" "row $n" || bad=$((bad+1))
  done < "$STORE"
  DUPD="$(awk -F'\t' '!/^#/ && $1!="decision_id" && NF>1 {print $1}' "$STORE" | sort | uniq -d)"
  [ -n "$DUPD" ] && { printf 'record-decision: duplicate decision_id(s): %s\n' "$(printf '%s' "$DUPD" | tr '\n' ' ')" >&2; bad=$((bad+1)); }
  if [ -f "$SNAPS" ]; then
    "${BASH_SOURCE[0]}" snapshot-verify --snapshots "$SNAPS" >/dev/null || bad=$((bad+1))
  fi
  [ "$bad" -eq 0 ] || die "$bad problem(s) in $STORE"
  printf 'record-decision: %s telemetry row(s) valid in %s\n' "$n" "$STORE"
  exit 0
fi

# ------------------------------------------------------------------- get -----
if [ "$CMD" = "get" ]; then
  [ -f "$STORE" ] || die "no telemetry store at $STORE"
  i="$(idx_of "$GFIELD")"
  [ "$i" -gt 0 ] || die "unknown field \"$GFIELD\" — the schema is: $COLS"
  out="$(awk -F'\t' -v id="$GID" -v i="$i" '!/^#/ && $1==id {print $i; found=1; exit} END{exit !found}' "$STORE")" \
    || die "no decision \"$GID\" in $STORE"
  printf '%s\n' "$out"
  exit 0
fi

if [ "$CMD" = "get-snapshot" ]; then
  [ -f "$SNAPS" ] || die "no snapshot store at $SNAPS"
  i="$(snap_idx_of "$GFIELD")"
  [ "$i" -gt 0 ] || die "unknown snapshot field \"$GFIELD\" — the schema is: $SNAP_COLS"
  out="$(awk -F'\t' -v id="$GID" -v i="$i" '!/^#/ && $1==id {print $i; found=1; exit} END{exit !found}' "$SNAPS")" \
    || die "no snapshot \"$GID\" in $SNAPS"
  printf '%s\n' "$out"
  exit 0
fi

# ---------------------------------------------------------------- report -----
# IT REPORTS COVERAGE BEFORE IT REPORTS ANY TOTAL, and it never sums an unknown.
# A total over a column that is nine-tenths unknown is a number with a shape and
# no meaning, so the denominator is printed first and the total is withheld
# entirely when nothing is known.
if [ "$CMD" = "report" ]; then
  [ -f "$STORE" ] || die "no telemetry store at $STORE"
  NROWS="$(awk -F'\t' '!/^#/ && $1!="decision_id" && NF>1' "$STORE" | grep -c . || true)"
  printf 'record-decision: %s decision(s) in %s (schema %s)\n' "$NROWS" "$STORE" "$SCHEMA_VERSION"
  [ "${NROWS:-0}" -eq 0 ] && { printf 'record-decision: nothing recorded yet — no coverage to report\n'; exit 0; }
  printf '%-26s %8s %8s  %s\n' "field" "known" "unknown" "sum of known (never includes unknowns)"
  for c in $QUANT; do
    i="$(idx_of "$c")"
    awk -F'\t' -v i="$i" -v name="$c" '
      !/^#/ && $1!="decision_id" && NF>1 {
        v=$i
        if (v=="unknown") { u++ } else { k++; split(v,a,"@"); s+=a[1] }
      }
      END {
        if (k+0 == 0) printf "%-26s %8d %8d  %s\n", name, 0, u+0, "— withheld: nothing known, and a sum of no measurements is not 0"
        else          printf "%-26s %8d %8d  %g\n", name, k, u+0, s
      }' "$STORE"
  done
  printf '\nrecord-decision: every `unknown` above is an ABSENCE OF MEASUREMENT, not a zero.\n'
  printf 'record-decision: no unknown contributes to any sum, and no sum is reported for a column with none known.\n'
  exit 0
fi

# ---------------------------------------------------------------- record -----
if [ "$CMD" = "record" ]; then
  ensure_store "$STORE" "$SCHEMA_VERSION" $COLS
  for r in $REQUIRED; do
    [ -n "${F[$r]:-}" ] || die "--${r//_/-} is required. Identity, time, the candidate set, the choice, who chose, why, and what was expected are what make a row a DECISION rather than a timing sample."
  done
  printf '%s\n' "${F[decision_id]}" | grep -qE "$DECISION_ID_RE" \
    || die "decision_id \"${F[decision_id]}\" is not a DECISION-NNNN[-slug] stable id"
  if [ -f "$STORE" ] && awk -F'\t' -v id="${F[decision_id]}" '!/^#/ && $1==id{f=1} END{exit !f}' "$STORE"; then
    die "decision_id \"${F[decision_id]}\" is already recorded. A store that accepts a duplicate id double-counts it in every total it will ever produce."
  fi
  assert_partition
  # A SELECTION MAY NOT CARRY AN OUTCOME. The outcome does not exist yet when the
  # choice is made; a value here would be a forecast filed as a measurement.
  # Naming the column with the literal `unknown` is allowed because omission
  # already yields exactly that, so the historical spelling still works.
  for k in "${!F[@]}"; do
    in_list "$k" "$OUTCOME_COLS" || continue
    [ "${F[$k]}" = "unknown" ] && continue
    die "OUTCOME-FIELD-IN-SELECTION — --${k//_/-} is an OUTCOME field and this is the SELECTION path. When the choice is recorded the outcome has not happened, so a value here is a forecast filed as a measurement. Record it afterwards with \`outcome\`, which refuses to run until this row exists."
  done
  for k in "${!F[@]}"; do
    in_list "$k" "$RANKER_FIELDS" \
      && die "RANKER-FIELD-IN-SELECTION — --${k//_/-} is evidence about the RANKER, not about the decision. It is derived on demand from the sealed ordering and this selection; storing it here would make a ranking's own score a field of the record it is being scored against."
  done
  # THE SEAL BINDS TO ITS SET. Sealing an ordering over set A and then choosing
  # from set B leaves every artefact parsing and the ranking referring to a
  # decision nobody took.
  if [ -f "$SNAPS" ]; then
    SEALED_SET="$(awk -F'\t' -v d="${F[decision_id]}" -v s="$SEAL_SIGNAL" '!/^#/ && $2==d && $6==s{print $5}' "$SNAPS" | sort)"
    if [ -n "$SEALED_SET" ]; then
      DECL_SET="$(semi_lines "${F[candidate_ids]}" | sort)"
      if [ "$SEALED_SET" != "$DECL_SET" ]; then
        die "SET-CHANGED-AFTER-SEAL — a prospective ranking was sealed for \"${F[decision_id]}\" over [$(printf '%s' "$SEALED_SET" | tr '\n' ' ')] and this selection declares [$(printf '%s' "$DECL_SET" | tr '\n' ' ')]. A seal binds to its set or it binds to nothing: choosing from a set the ordering never ranked converts a sealed prospective ranking into a post-hoc one while leaving every artefact intact."
      fi
      SEALED_AT="$(awk -F'\t' -v d="${F[decision_id]}" -v s="$SEAL_SIGNAL" '!/^#/ && $2==d && $6==s{print $3; exit}' "$SNAPS")"
      if [ -n "$SEALED_AT" ] && before "${F[decision_time]}" "$SEALED_AT"; then
        die "TIMESTAMP-CONTRADICTS-ORDER — this selection reports decision_time \"${F[decision_time]}\" and the ranking it is bound to reports captured_at \"$SEALED_AT\", so the choice claims to precede the ordering. The strings prove nothing on their own — they are self-reported — but a contradiction between them always means something is wrong, and it is refused rather than reconciled."
      fi
    fi
  fi
  # OMISSION YIELDS `unknown`. This loop is the rule.
  ROW=""
  for c in $COLS; do
    v="${F[$c]:-unknown}"
    case "$v" in *"$TAB"*|*$'\n'*) die "$c contains a tab or newline, which would silently split the row" ;; esac
    ROW="${ROW}${v}${TAB}"
  done
  ROW="${ROW%"$TAB"}"
  validate_row "$ROW" "the proposed row" || die "the proposed row is not writable; nothing was appended"
  # Any flag naming no column is a typo, and a typo that is ignored is a value
  # silently lost.
  for k in "${!F[@]}"; do
    [ "$(idx_of "$k")" -gt 0 ] || die "--${k//_/-} names no column. The schema is: $COLS"
  done
  printf '%s\n' "$ROW" >> "$STORE" || die "cannot append to $STORE"
  printf 'recorded decision: %s -> %s\n' "${F[decision_id]}" "$STORE"
  exit 0
fi

# -------------------------------------------------------------- snapshot -----
SNAP_REQUIRED="snapshot_id decision_id captured_at repository_commit candidate_id signal_name signal_value derivation_version source_object_versions evidence_refs"
# ONE APPEND PATH, USED BY BOTH WRITERS. `snapshot` and `seal-ranking` share it
# rather than each computing a digest, because two copies of a chaining rule is
# two chaining rules the moment one of them is edited — the counting form of
# DEFECT-0003 this tree has now paid for repeatedly.
append_snapshot(){ # the ten body fields, in SNAP_COLS order
  ensure_store "$SNAPS" "$SNAP_SCHEMA_VERSION" $SNAP_COLS
  printf '%s\n' "$1" | grep -qE "$SNAP_ID_RE" \
    || die "snapshot_id \"$1\" is not a SIGNAL-SNAPSHOT-NNNN[-slug] stable id"
  if awk -F'\t' -v id="$1" '!/^#/ && $1==id{f=1} END{exit !f}' "$SNAPS"; then
    die "snapshot_id \"$1\" already exists. A snapshot is evidence; overwriting one is exactly the edit the chain exists to make visible."
  fi
  local prev body="" dig v
  prev="$(awk -F'\t' '!/^#/ && $1!="snapshot_id" && NF>1 {d=$NF} END{print d}' "$SNAPS")"
  [ -n "$prev" ] || prev="GENESIS"
  for v in "$@"; do
    case "$v" in *"$TAB"*|*$'\n'*) die "a snapshot field contains a tab or newline, which would silently split the row" ;; esac
    body="${body}${v}${TAB}"
  done
  body="${body%"$TAB"}"
  dig="$(printf '%s\t%s' "$prev" "$body" | digest_of)"
  printf '%s\t%s\t%s\n' "$body" "$prev" "$dig" >> "$SNAPS" || die "cannot append to $SNAPS"
}
if [ "$CMD" = "snapshot" ]; then
  ensure_store "$SNAPS" "$SNAP_SCHEMA_VERSION" $SNAP_COLS
  for r in $SNAP_REQUIRED; do
    [ -n "${F[$r]:-}" ] || die "--${r//_/-} is required on a snapshot. A frozen signal with no commit, no derivation version or no source object versions cannot be re-read as evidence — it is a number with no referent."
  done
  append_snapshot "${F[snapshot_id]}" "${F[decision_id]}" "${F[captured_at]}" \
    "${F[repository_commit]}" "${F[candidate_id]}" "${F[signal_name]}" \
    "${F[signal_value]}" "${F[derivation_version]}" "${F[source_object_versions]}" \
    "${F[evidence_refs]}"
  printf 'recorded snapshot: %s (%s = %s, frozen at %s) -> %s\n' \
    "${F[snapshot_id]}" "${F[signal_name]}" "${F[signal_value]}" "${F[repository_commit]}" "$SNAPS"
  exit 0
fi

# ---------------------------------------------------------- seal-ranking -----
# SEAL AN ORDERING BEFORE ANYBODY CHOOSES. This is the only thing in this tree
# that can turn `rank_of_selected` from an observation into evidence: a ranking
# that already existed, in the chain, when the choice was still open.
#
# IT COMPUTES NO ORDERING. The rule that produced the ordering lives in the
# ranker; duplicating it here would be two copies of one semantic truth, and the
# copy nobody runs is the one that goes wrong. This command takes the ordering as
# input and is responsible for exactly three things a ranker cannot do for
# itself: that the seal precedes the selection, that it covers the whole declared
# set and nothing else, and that it cannot be replaced afterwards.
if [ "$CMD" = "seal-ranking" ]; then
  SEAL_REQUIRED="decision_id candidate_ids ordering ranking_rule captured_at repository_commit snapshot_ids source_object_versions evidence_refs"
  for r in $SEAL_REQUIRED; do
    [ -n "${F[$r]:-}" ] || die "--${r//_/-} is required to seal a ranking. A sealed ordering with no rule, no commit or no evidence refs is a list of names nobody can re-derive."
  done
  printf '%s\n' "${F[decision_id]}" | grep -qE "$DECISION_ID_RE" \
    || die "decision_id \"${F[decision_id]}\" is not a DECISION-NNNN[-slug] stable id"
  # REFUSAL 1 — THE ONE THIS PACKET EXISTS FOR. The decision must not yet have a
  # selection row. This is not a timestamp comparison: it is the state of the
  # telemetry store at the instant of the write.
  if [ -f "$STORE" ] && awk -F'\t' -v id="${F[decision_id]}" '!/^#/ && $1==id{f=1} END{exit !f}' "$STORE"; then
    die "RANKING-AFTER-SELECTION — \"${F[decision_id]}\" already carries a SELECTION row in $STORE, so any ordering sealed now is POST-HOC. A ranking formed after a choice is a rationalisation and is byte-identical to one formed before it; the order is the only thing that ever distinguished them, and it is enforced here rather than described."
  fi
  # REFUSAL 2 — one decision, one prospective ranking. A seal that can be
  # replaced records the last opinion, not the first.
  if [ -f "$SNAPS" ] && awk -F'\t' -v d="${F[decision_id]}" -v s="$SEAL_SIGNAL" '!/^#/ && $2==d && $6==s{f=1} END{exit !f}' "$SNAPS"; then
    die "RESEAL — \"${F[decision_id]}\" already carries a sealed ranking in $SNAPS. Sealing a second ordering over the same decision would let the ranking be revised while the choice was still open, which is the same defect as ranking after the choice with one extra step."
  fi
  # REFUSAL 3/4 — RESOLVABILITY IS NOT IDENTITY, one step further on. An ordering
  # that parses is not an ordering OF the set it claims: both a rank for a
  # candidate the set never named and a candidate the set names with no rank are
  # refused, by name.
  SEAL_SET="$(semi_lines "${F[candidate_ids]}" | sort)"
  SEAL_RANKED=""
  while IFS= read -r ent; do
    [ -n "$ent" ] || continue
    r="${ent%%:*}"; c="${ent#*:}"
    [ "$r" != "$ent" ] && [ -n "$c" ] \
      || die "the ordering entry \"$ent\" is not RANK:CANDIDATE. A rank is a positive integer or the literal \`excluded\`, which is how a candidate a guard refused stays on the record instead of vanishing from it."
    case "$r" in excluded) ;; ''|*[!0-9]*) die "the ordering entry \"$ent\" carries the rank \"$r\", which is neither a positive integer nor \`excluded\`" ;; 0) die "the ordering entry \"$ent\" carries rank 0; ranks start at 1" ;; esac
    in_list "$c" "$(printf '%s' "${F[candidate_ids]}" | tr ';' ' ')" \
      || die "ORDERING-SET-MISMATCH — the ordering ranks \"$c\", which the declared candidate set does not name. The ordering parses and is still an ordering of a different set: RESOLVABILITY IS NOT IDENTITY."
    SEAL_RANKED="$SEAL_RANKED$c
"
  done < <(semi_lines "${F[ordering]}")
  SEAL_MISSING="$(comm -23 <(printf '%s\n' "$SEAL_SET" | grep .) <(printf '%s' "$SEAL_RANKED" | grep . | sort) | grep . || true)"
  [ -z "$SEAL_MISSING" ] \
    || die "ORDERING-SET-MISMATCH — the declared candidate set names $(printf '%s' "$SEAL_MISSING" | tr '\n' ' ')which the ordering does not rank. A seal covers the whole set or it is a filtered one, and a filtered seal quietly excuses whatever it left out."
  # The ids are supplied, never invented. A tool that allocates its own snapshot
  # ids is a tool that can collide with one a human already wrote down.
  SEAL_IDS="$(semi_lines "${F[snapshot_ids]}")"
  NIDS="$(printf '%s\n' "$SEAL_IDS" | grep -c . || true)"
  NSET="$(printf '%s\n' "$SEAL_SET" | grep -c . || true)"
  [ "${NIDS:-0}" -eq "${NSET:-0}" ] \
    || die "--snapshot-ids supplies ${NIDS:-0} id(s) for ${NSET:-0} candidate(s). Ids are supplied and never invented: a tool that allocates its own would collide with one somebody already wrote down."
  # Everything is validated before anything is appended: a seal half-written into
  # a digest chain is worse than a seal refused.
  SEAL_I=0
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    SEAL_I=$((SEAL_I+1))
    sid="$(printf '%s\n' "$SEAL_IDS" | sed -n "${SEAL_I}p")"
    rank=""
    while IFS= read -r ent; do
      [ -n "$ent" ] || continue
      [ "${ent#*:}" = "$c" ] && { rank="${ent%%:*}"; break; }
    done < <(semi_lines "${F[ordering]}")
    append_snapshot "$sid" "${F[decision_id]}" "${F[captured_at]}" "${F[repository_commit]}" \
      "$c" "$SEAL_SIGNAL" "$rank" "${F[ranking_rule]}" "${F[source_object_versions]}" "${F[evidence_refs]}"
  done < <(semi_lines "${F[candidate_ids]}")
  printf 'sealed ranking: %s under rule %s, %s candidate(s) -> %s\n' \
    "${F[decision_id]}" "${F[ranking_rule]}" "${NSET:-0}" "$SNAPS"
  printf 'sealed_ordering: %s\n' "${F[ordering]}"
  printf 'selection_row: ABSENT from %s at the moment of this write — that absence, not a timestamp, is what establishes ranking < selection.\n' "$STORE"
  printf 'chain_head: %s\n' "$(awk -F'\t' '!/^#/ && $1!="snapshot_id" && NF>1 {d=$NF} END{print d}' "$SNAPS")"
  printf 'what_this_proves: the ordering existed, in an append-only digest chain, while the choice was still open. What it does NOT prove: that the ordering is any good. That needs several sealed decisions with recorded selections, and this store reports how many there are rather than asserting it.\n'
  exit 0
fi

# --------------------------------------------------------- snapshot-verify ---
if [ "$CMD" = "snapshot-verify" ]; then
  [ -f "$SNAPS" ] || die "no snapshot store at $SNAPS"
  NS=0; BADS=0; PREV="GENESIS"
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    case "$line" in "snapshot_id$TAB"*) continue ;; esac
    NS=$((NS+1))
    nf="$(printf '%s' "$line" | awk -F'\t' '{print NF}')"
    want="$(printf '%s\n' $SNAP_COLS | grep -c .)"
    if [ "$nf" != "$want" ]; then
      printf 'record-decision: snapshot row %s has %s fields, expected %s\n' "$NS" "$nf" "$want" >&2
      BADS=$((BADS+1)); continue
    fi
    body="$(printf '%s' "$line" | cut -f1-10)"
    rprev="$(printf '%s' "$line" | cut -f11)"
    rdig="$(printf '%s' "$line" | cut -f12)"
    sid="$(printf '%s' "$line" | cut -f1)"
    if [ "$rprev" != "$PREV" ]; then
      printf 'record-decision: CHAIN BROKEN at %s — it records prev_digest %s but the row before it digests to %s. A row was inserted, removed or reordered.\n' "$sid" "$rprev" "$PREV" >&2
      BADS=$((BADS+1))
    fi
    calc="$(printf '%s\t%s' "$rprev" "$body" | digest_of)"
    if [ "$calc" != "$rdig" ]; then
      printf 'record-decision: TAMPERED — snapshot %s digests to %s but records %s. A historical signal was edited after it was frozen; the value in this row is NOT the value the decision was taken on.\n' "$sid" "$calc" "$rdig" >&2
      BADS=$((BADS+1))
    fi
    PREV="$rdig"
  done < "$SNAPS"
  # VACUITY: a chain check over zero rows verifies every possible forgery.
  [ "$NS" -eq 0 ] && die "$SNAPS contains 0 snapshot rows. A chain check with nothing to check passes for every store, including a store somebody emptied."
  [ "$BADS" -eq 0 ] || die "$BADS snapshot integrity problem(s) in $SNAPS"
  printf 'record-decision: %s snapshot(s) verify against the digest chain in %s (schema %s)\n' "$NS" "$SNAPS" "$SNAP_SCHEMA_VERSION"
  printf 'record-decision: TAMPER-EVIDENT, NOT TAMPER-PROOF — anyone who can write this file can rewrite the chain from an edit forward. It defeats an in-place edit, not a deliberate forgery.\n'
  exit 0
fi

# ----------------------------------------------------------------- fields ----
# The partition, published rather than left implicit in the code. A separation
# nobody can read is a separation nobody can check.
if [ "$CMD" = "fields" ]; then
  assert_partition
  for c in $COLS; do printf 'column: %s\n' "$c"; done
  for c in $SELECTION_COLS; do printf 'selection_field: %s\n' "$c"; done
  for c in $OUTCOME_COLS; do printf 'outcome_field: %s\n' "$c"; done
  for c in $RANKER_FIELDS; do printf 'ranker_field: %s\n' "$c"; done
  printf 'partition: every column belongs to exactly one of the selection set and the outcome set, checked against the schema rather than trusted. `record` writes the first, `outcome` writes the second, and neither reaches the other.\n'
  printf 'ranker_fields_own_no_column: evidence about the RANKER is derived on demand and is never stored beside the outcome of the candidate it ranked.\n'
  exit 0
fi

# ---------------------------------------------------------------- outcome ----
# WHAT THE CHOICE THEN COST AND PRODUCED. It may only be written once the
# selection exists, it may not touch a selection column, and it may not carry a
# fact about the ranker.
#
# WHY THIS UPDATES A ROW RATHER THAN APPENDING ONE. `decision_telemetry.tsv` is a
# RECORD and its duplicate-id refusal exists so that no total ever double-counts
# a decision; a second row for the same decision would defeat exactly that. The
# outcome columns are already declared here and are `unknown` until something
# knows better, so this fills them in place — and proves it filled nothing else,
# by comparing the selection half of the row before and after.
if [ "$CMD" = "outcome" ]; then
  assert_partition
  [ -n "${F[decision_id]:-}" ] || die "--decision-id is required. An outcome with no decision is a measurement of nothing."
  [ -f "$STORE" ] \
    || die "OUTCOME-BEFORE-SELECTION — there is no telemetry store at $STORE, so no decision has been recorded and nothing can have an outcome yet."
  OROW="$(awk -F'\t' -v id="${F[decision_id]}" '!/^#/ && $1==id{print; found=1; exit} END{exit !found}' "$STORE")" \
    || die "OUTCOME-BEFORE-SELECTION — \"${F[decision_id]}\" has no SELECTION row in $STORE. An outcome cannot precede the choice it is the outcome of, and this is not a timestamp comparison: the row is either there at the moment of the write or it is not."
  for k in "${!F[@]}"; do
    [ "$k" = "decision_id" ] && continue
    in_list "$k" "$RANKER_FIELDS" \
      && die "RANKER-FIELD-IN-OUTCOME — --${k//_/-} is evidence about the RANKER, not about the candidate. Discovering that the chosen candidate mattered is evidence about the CANDIDATE; it is not yet evidence that anything ranked it for the right reasons. Those two claims stay in separate records, and this store holds only the second."
    in_list "$k" "$SELECTION_COLS" \
      && die "SELECTION-FIELD-IN-OUTCOME — --${k//_/-} is a SELECTION field and this is the OUTCOME path. An outcome record that could rewrite the choice it is the outcome of would make \"what was chosen\" and \"what happened\" one editable object, and no later reader could tell which had been adjusted to fit the other."
    in_list "$k" "$OUTCOME_COLS" \
      || die "--${k//_/-} names no outcome field. The outcome set is: $OUTCOME_COLS"
  done
  ODTIME="$(printf '%s' "$OROW" | cut -f"$(idx_of decision_time)")"
  for tf in started_at completed_at; do
    [ -n "${F[$tf]:-}" ] || continue
    before "${F[$tf]}" "$ODTIME" \
      && die "TIMESTAMP-CONTRADICTS-ORDER — $tf \"${F[$tf]}\" precedes this decision's decision_time \"$ODTIME\", so the work claims to have happened before the choice to do it. The strings are self-reported and prove nothing on their own; a contradiction between them is refused anyway, because a contradiction is always wrong."
  done
  ONEW=""; OI=0
  for c in $COLS; do
    OI=$((OI+1))
    cur="$(printf '%s' "$OROW" | cut -f"$OI")"
    v="$cur"
    if [ -n "${F[$c]:-}" ]; then
      nv="${F[$c]}"
      case "$nv" in *"$TAB"*|*$'\n'*) die "$c contains a tab or newline, which would silently split the row" ;; esac
      case " $QUANT " in *" $c "*) r="$(validate_quant "$c" "$nv")"; [ -n "$r" ] && die "$r" ;; esac
      if [ "$cur" != "unknown" ] && [ "$cur" != "$nv" ]; then
        die "OUTCOME-OVERWRITE — $c already records \"$cur\" for \"${F[decision_id]}\" and this would replace it with \"$nv\". An outcome that can be edited afterwards is not evidence about anything, least of all about whether a ranking was right. Re-writing the SAME value is allowed; changing one is not."
      fi
      v="$nv"
    fi
    ONEW="${ONEW}${v}${TAB}"
  done
  ONEW="${ONEW%"$TAB"}"
  validate_row "$ONEW" "the amended row" || die "the amended row is not writable; nothing was changed"
  # THE INVARIANT, CHECKED RATHER THAN ARGUED. The selection half of this row
  # must be byte-identical across the write, whatever the flag loop above did.
  for c in $SELECTION_COLS; do
    i="$(idx_of "$c")"
    [ "$(printf '%s' "$OROW" | cut -f"$i")" = "$(printf '%s' "$ONEW" | cut -f"$i")" ] \
      || die "the outcome write would change the selection column $c. Nothing was written. This is an internal invariant failing closed, not a user error."
  done
  OTMP="$STORE.outcome.$$"
  OMATCHED=0
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      "${F[decision_id]}$TAB"*) printf '%s\n' "$ONEW"; OMATCHED=$((OMATCHED+1)) ;;
      *) printf '%s\n' "$line" ;;
    esac
  done < "$STORE" > "$OTMP"
  if [ "$OMATCHED" -ne 1 ]; then
    rm -f "$OTMP"
    die "the outcome write matched $OMATCHED rows for \"${F[decision_id]}\", not exactly 1. Nothing was written."
  fi
  mv "$OTMP" "$STORE" || { rm -f "$OTMP"; die "cannot replace $STORE"; }
  printf 'recorded outcome: %s -> %s\n' "${F[decision_id]}" "$STORE"
  printf 'selection_half: unchanged, byte-for-byte, and verified field by field before the write.\n'
  printf 'ranker_evidence: NONE. This records what the CANDIDATE cost and produced. Whether anything ranked it well is a different claim, kept in a different place.\n'
  exit 0
fi

# --------------------------------------------------------- outcome-report ----
# EVERY ABSENCE NAMED, AND THE DENOMINATOR BEFORE ANY TOTAL. This is the
# missing-signal discipline the ranker applies to a signal SET, applied to the
# outcome FIELD set: an outcome quietly written as 0, or quietly dropped, is the
# defect that makes a measurement store worse than no store.
#
# THE THREE ABSENCES, AND EACH IS DERIVED FROM THE STORE RATHER THAN REMEMBERED:
#
#   MISSING          no value for THIS decision, and at least one other decision
#                    in this store carries one. The quantity is collectable here;
#                    nobody collected it for this one.
#   NEVER-COLLECTED  no decision in this store has EVER carried a value. Nothing
#                    in this repository has measured it.
#   UNINTERPRETED    a value IS recorded, and no DIRECTION for outcome evaluation
#                    has ever been declared for the field, so it is reported and
#                    scores nothing.
if [ "$CMD" = "outcome-report" ]; then
  assert_partition
  [ -n "${F[decision_id]:-}" ] || die "--decision-id is required"
  [ -f "$STORE" ] || die "no telemetry store at $STORE"
  RROW="$(awk -F'\t' -v id="${F[decision_id]}" '!/^#/ && $1==id{print; found=1; exit} END{exit !found}' "$STORE")" \
    || die "no decision \"${F[decision_id]}\" in $STORE"
  NDEC="$(awk -F'\t' '!/^#/ && $1!="decision_id" && NF>1' "$STORE" | grep -c . || true)"
  printf 'outcome-report: %s (schema %s)\n' "${F[decision_id]}" "$SCHEMA_VERSION"
  printf 'selected_candidate_id: %s   selector: %s\n' \
    "$(printf '%s' "$RROW" | cut -f"$(idx_of selected_candidate_id)")" \
    "$(printf '%s' "$RROW" | cut -f"$(idx_of selector)")"
  RREC=0; RMISS=0; RNEVER=0
  RLINES=""
  for c in $OUTCOME_COLS; do
    i="$(idx_of "$c")"
    v="$(printf '%s' "$RROW" | cut -f"$i")"
    kn="$(awk -F'\t' -v i="$i" '!/^#/ && $1!="decision_id" && NF>1 && $i!="unknown"' "$STORE" | grep -c . || true)"
    if [ "$v" != "unknown" ]; then
      RREC=$((RREC+1))
      if in_list "$c" "$OUTCOME_DIRECTION"; then
        RLINES="${RLINES}outcome_field $c RECORDED value=$v direction=declared"$'\n'
      else
        RLINES="${RLINES}outcome_field $c UNINTERPRETED value=$v — a value IS recorded and NO direction for outcome evaluation has ever been declared for this field, so it is reported and scores nothing. Guessing one would put an unregistered constant inside every ordering that later read it."$'\n'
      fi
    elif [ "${kn:-0}" -eq 0 ]; then
      RNEVER=$((RNEVER+1))
      RLINES="${RLINES}outcome_field $c NEVER-COLLECTED — 0 of $NDEC decision(s) in this store have ever carried a value. Nothing in this repository has measured it; it is named as absent rather than imputed."$'\n'
    else
      RMISS=$((RMISS+1))
      RLINES="${RLINES}outcome_field $c MISSING — no value for this decision; $kn of $NDEC decision(s) here carry one, so the quantity IS collectable and nobody collected it. Not imputed, not defaulted, not dropped."$'\n'
    fi
  done
  printf 'coverage: %s recorded, %s missing, %s never-collected; declared outcome fields: %s\n' \
    "$RREC" "$RMISS" "$RNEVER" "$(count_of "$OUTCOME_COLS")"
  printf '%s' "$RLINES"
  printf 'aggregate: outcome_completeness — %s of %s declared outcome field(s) carry a value\n' \
    "$RREC" "$(count_of "$OUTCOME_COLS")"
  printf 'aggregate: every scored total — withheld: no outcome field has a declared direction, so nothing here can be summed into a quality without inventing the direction first. An absence contributes to no total, and no total is reported over a set that contains one.\n'
  # THE SEPARATION, PUBLISHED BESIDE THE DATA. Agreement is one observation.
  NSEALED="$(awk -F'\t' -v s="$SEAL_SIGNAL" '!/^#/ && $6==s{print $2}' "$SNAPS" 2>/dev/null | sort -u | grep -c . || true)"
  NSEALSEL=0
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    awk -F'\t' -v id="$d" '!/^#/ && $1==id{f=1} END{exit !f}' "$STORE" && NSEALSEL=$((NSEALSEL+1))
  done < <(awk -F'\t' -v s="$SEAL_SIGNAL" '!/^#/ && $6==s{print $2}' "$SNAPS" 2>/dev/null | sort -u)
  printf 'prospective_decisions_sealed: %s\n' "${NSEALED:-0}"
  printf 'prospective_decisions_with_a_recorded_selection: %s\n' "$NSEALSEL"
  printf 'ranker_evidence: NONE DERIVABLE FROM THIS REPORT. Everything above is evidence about the CANDIDATE — what it cost, what it produced, whether it held. That a chosen candidate turned out well is NOT evidence that anything ranked it for the right reasons, and the two are kept in separate records so the second reading is not available by accident.\n'
  printf 'ranker_evidence_precondition: a rank_of_selected is evidence about a ranker only for a decision whose ordering was SEALED BEFORE its selection. %s such decision(s) have since been selected. Until that number is large enough to mean something, agreement between a ranking and a choice is one observation and this tool says so rather than scoring it.\n' "$NSEALSEL"
  exit 0
fi

die "unhandled command \"$CMD\""
