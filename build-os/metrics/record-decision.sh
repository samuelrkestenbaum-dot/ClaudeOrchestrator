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
# WHAT THIS IS NOT
# ---------------------------------------------------------------------------
# Not a database, not an event-sourcing framework, not a ranker. Two TSV files and
# a shell script, chosen because the substrate has to be the one this repository
# already has. The schemas are versioned so they can migrate later; nothing here
# learns anything, orders anything, or dispatches anything.
#
# Usage:
#   record-decision.sh record          --decision-id ID --decision-time T … [--store F]
#   record-decision.sh get             ID FIELD              [--store F]
#   record-decision.sh snapshot        --snapshot-id ID …    [--snapshots F]
#   record-decision.sh get-snapshot    ID FIELD              [--snapshots F]
#   record-decision.sh snapshot-verify                       [--snapshots F]
#   record-decision.sh validate                              [--store F] [--snapshots F]
#   record-decision.sh report                                [--store F]
# Exit: 0 ok, 2 refused.
set -uo pipefail

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
  get|get-snapshot)
    GID="${1:-}"; GFIELD="${2:-}"
    [ -n "$GID" ] && [ -n "$GFIELD" ] || die "$CMD needs an ID and a FIELD"
    shift 2 ;;
  -h|--help|help) sed -n '2,100p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") die "no command — expected one of: record, get, snapshot, get-snapshot, snapshot-verify, validate, report" ;;
  *)  die "unknown command \"$CMD\"" ;;
esac

# Every remaining `--flag value` becomes a field. `--wall-minutes` sets
# `wall_minutes`; the mapping is mechanical so a new column needs no new flag.
declare -A F=()
while [ $# -gt 0 ]; do
  case "$1" in
    --store)     [ $# -ge 2 ] || die "--store needs a value";     STORE="$2"; shift 2 ;;
    --snapshots) [ $# -ge 2 ] || die "--snapshots needs a value"; SNAPS="$2"; shift 2 ;;
    -h|--help)   sed -n '2,100p' "${BASH_SOURCE[0]}"; exit 0 ;;
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
if [ "$CMD" = "snapshot" ]; then
  ensure_store "$SNAPS" "$SNAP_SCHEMA_VERSION" $SNAP_COLS
  for r in $SNAP_REQUIRED; do
    [ -n "${F[$r]:-}" ] || die "--${r//_/-} is required on a snapshot. A frozen signal with no commit, no derivation version or no source object versions cannot be re-read as evidence — it is a number with no referent."
  done
  printf '%s\n' "${F[snapshot_id]}" | grep -qE "$SNAP_ID_RE" \
    || die "snapshot_id \"${F[snapshot_id]}\" is not a SIGNAL-SNAPSHOT-NNNN[-slug] stable id"
  if awk -F'\t' -v id="${F[snapshot_id]}" '!/^#/ && $1==id{f=1} END{exit !f}' "$SNAPS"; then
    die "snapshot_id \"${F[snapshot_id]}\" already exists. A snapshot is evidence; overwriting one is exactly the edit the chain exists to make visible."
  fi
  PREV="$(awk -F'\t' '!/^#/ && $1!="snapshot_id" && NF>1 {d=$NF} END{print d}' "$SNAPS")"
  [ -n "$PREV" ] || PREV="GENESIS"
  BODY=""
  for c in $SNAP_COLS; do
    case "$c" in prev_digest|digest) continue ;; esac
    v="${F[$c]:-unknown}"
    case "$v" in *"$TAB"*|*$'\n'*) die "$c contains a tab or newline, which would silently split the row" ;; esac
    BODY="${BODY}${v}${TAB}"
  done
  BODY="${BODY%"$TAB"}"
  DIG="$(printf '%s\t%s' "$PREV" "$BODY" | digest_of)"
  printf '%s\t%s\t%s\n' "$BODY" "$PREV" "$DIG" >> "$SNAPS" || die "cannot append to $SNAPS"
  printf 'recorded snapshot: %s (%s = %s, frozen at %s) -> %s\n' \
    "${F[snapshot_id]}" "${F[signal_name]}" "${F[signal_value]}" "${F[repository_commit]}" "$SNAPS"
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

die "unhandled command \"$CMD\""
