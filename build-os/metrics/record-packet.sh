#!/usr/bin/env bash
# Build OS — packet metrics recorder.
#
# Appends ONE validated record to an append-only TSV store, or checks a store
# that already exists. Dependency-free: bash + awk + git (git only for
# --verify-git). Nothing here reaches the network, and nothing is transmitted
# anywhere; see build-os/metrics/README.md.
#
# WHY TSV AND NOT JSON. A recorder that is expensive to use does not get used,
# and an unused recorder produces a store of zero rows, which is exactly the
# state this repo was in when it started arguing about speed. A tab-separated
# line can be appended by an agent, typed by a human, read by `cut`, and diffed
# by git. That is the whole design goal.
#
# WHY "-" AND NOT 0. An unmeasured cell is written "-". It must never be written
# 0, because 0 is a measurement and "-" is an admission. Half the value of this
# instrument is the cells it refuses to fill in.
#
# Usage:
#   record-packet.sh [--store PATH] --packet ID --lane LANE --evidence CLASS \
#                    --note "why these numbers are believable" [field flags...]
#   record-packet.sh [--store PATH] --validate
#   record-packet.sh [--store PATH] --verify-git [--repo PATH]
#   record-packet.sh --header
#
# Field flags (all optional except --packet, --lane, --evidence, --note; any
# omitted numeric field is recorded as "-"):
#   --date YYYY-MM-DD   --rounds N          --wall-min N[.N]   --serial-min N[.N]
#   --agents N          --files N           --insertions N     --deletions N
#   --tests-added N     --defects-gated N   --defects-escaped N
#   --commits SHA[,SHA] --evidence git|transcript|estimate|mixed
#
# Exit: 0 ok, 2 on any validation or verification failure.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STORE="$SELF_DIR/packet_metrics.tsv"
TAB=$'\t'
HEADER="packet_id${TAB}date${TAB}lane${TAB}rounds${TAB}wall_min${TAB}serial_min${TAB}agents${TAB}files${TAB}insertions${TAB}deletions${TAB}tests_added${TAB}defects_gated${TAB}defects_escaped${TAB}commits${TAB}evidence${TAB}note"
NCOLS=16

# The lanes the router defines. A metrics row in a lane that does not exist is a
# row nobody can act on.
LANES="read-only diagnosis tiny substantive architecture agent-swarm"
# Evidence classes, in descending order of how much a skeptic should trust them:
#   git        the diff figures and commits are reproducible from this repository
#   mixed      some fields git-backed, some not; the note must say which
#   transcript from the session record; real, but not reproducible from the repo
#   estimate   a judgement. Not a measurement. Says so.
EVIDENCE_CLASSES="git transcript estimate mixed"
NOTE_MIN=12

die(){ printf 'record-packet: %s\n' "$*" >&2; exit 2; }
in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }

is_num_or_dash(){ [ "$1" = "-" ] && return 0; [[ "$1" =~ ^[0-9]+(\.[0-9]+)?$ ]]; }
is_date_or_dash(){ [ "$1" = "-" ] && return 0; [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; }
is_commits_or_dash(){ [ "$1" = "-" ] && return 0; [[ "$1" =~ ^[0-9a-f]{7,40}(,[0-9a-f]{7,40})*$ ]]; }
has_ctrl(){ case "$1" in *"$TAB"*) return 0 ;; esac; case "$1" in *"
"*) return 0 ;; esac; return 1; }

# --------------------------------------------------------------- defaults ----
MODE="append"
REPO=""
f_packet=""; f_date=""; f_lane=""; f_rounds="-"; f_wall="-"; f_serial="-"
f_agents="-"; f_files="-"; f_ins="-"; f_del="-"; f_tests="-"
f_dg="-"; f_de="-"; f_commits="-"; f_evidence=""; f_note=""

need(){ [ "$#" -ge 2 ] || die "$1 requires a value"; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --store)            need "$@"; STORE="$2"; shift 2 ;;
    --repo)             need "$@"; REPO="$2"; shift 2 ;;
    --validate)         MODE="validate"; shift ;;
    --verify-git)       MODE="verify"; shift ;;
    --header)           MODE="header"; shift ;;
    --packet)           need "$@"; f_packet="$2"; shift 2 ;;
    --date)             need "$@"; f_date="$2"; shift 2 ;;
    --lane)             need "$@"; f_lane="$2"; shift 2 ;;
    --rounds)           need "$@"; f_rounds="$2"; shift 2 ;;
    --wall-min)         need "$@"; f_wall="$2"; shift 2 ;;
    --serial-min)       need "$@"; f_serial="$2"; shift 2 ;;
    --agents)           need "$@"; f_agents="$2"; shift 2 ;;
    --files)            need "$@"; f_files="$2"; shift 2 ;;
    --insertions)       need "$@"; f_ins="$2"; shift 2 ;;
    --deletions)        need "$@"; f_del="$2"; shift 2 ;;
    --tests-added)      need "$@"; f_tests="$2"; shift 2 ;;
    --defects-gated)    need "$@"; f_dg="$2"; shift 2 ;;
    --defects-escaped)  need "$@"; f_de="$2"; shift 2 ;;
    --commits)          need "$@"; f_commits="$2"; shift 2 ;;
    --evidence)         need "$@"; f_evidence="$2"; shift 2 ;;
    --note)             need "$@"; f_note="$2"; shift 2 ;;
    -h|--help)          sed -n '2,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *)                  die "unknown argument: $1" ;;
  esac
done

# ------------------------------------------------------- shared validators ----
# Validate one already-split record. Prints the reason on stderr and returns 1.
# Used by BOTH the append path and --validate, so a row the recorder would
# refuse to write can never be a row --validate accepts.
validate_fields(){
  local pid="$1" dt="$2" lane="$3" rd="$4" wm="$5" sm="$6" ag="$7" fl="$8" \
        ins="$9" del="${10}" ta="${11}" dg="${12}" de="${13}" cm="${14}" \
        ev="${15}" nt="${16}" where="${17:-record}"
  local e=""
  [[ "$pid" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]] || e="$e; packet_id \"$pid\" is empty or not [A-Za-z0-9_.-]"
  is_date_or_dash "$dt"     || e="$e; date \"$dt\" is not YYYY-MM-DD or -"
  in_list "$lane" "$LANES"  || e="$e; lane \"$lane\" is not one of: $LANES"
  local nm
  for nm in "rounds:$rd" "wall_min:$wm" "serial_min:$sm" "agents:$ag" "files:$fl" \
            "insertions:$ins" "deletions:$del" "tests_added:$ta" \
            "defects_gated:$dg" "defects_escaped:$de"; do
    is_num_or_dash "${nm#*:}" || e="$e; ${nm%%:*} \"${nm#*:}\" is not a non-negative number or -"
  done
  is_commits_or_dash "$cm"  || e="$e; commits \"$cm\" is not a comma-separated list of hex object names or -"
  in_list "$ev" "$EVIDENCE_CLASSES" || e="$e; evidence \"$ev\" is not one of: $EVIDENCE_CLASSES"
  [ "${#nt}" -ge "$NOTE_MIN" ] || e="$e; note is shorter than $NOTE_MIN chars — a row with no attribution is decoration, not evidence"
  case "$ev" in
    git|mixed) [ "$cm" = "-" ] && e="$e; evidence=$ev but no commit is named — the claim is not checkable" ;;
  esac
  if [ -n "$e" ]; then
    printf 'record-packet: %s invalid: %s\n' "$where" "${e#; }" >&2
    return 1
  fi
  return 0
}

ensure_store(){
  local s="$1"
  if [ ! -f "$s" ]; then
    mkdir -p "$(dirname "$s")" || die "cannot create $(dirname "$s")"
    printf '%s\n' "$HEADER" > "$s" || die "cannot write $s"
  fi
  local h; h="$(head -n1 "$s")"
  [ "$h" = "$HEADER" ] || die "store header does not match the 16-column schema: $s"
}

datarows(){ tail -n +2 "$1" 2>/dev/null | grep -v '^[[:space:]]*$' | grep -v '^#'; }

# ------------------------------------------------------------------ header ----
if [ "$MODE" = "header" ]; then
  printf '%s\n' "$HEADER"
  exit 0
fi

# ---------------------------------------------------------------- validate ----
if [ "$MODE" = "validate" ]; then
  [ -f "$STORE" ] || die "store not found: $STORE"
  h="$(head -n1 "$STORE")"
  [ "$h" = "$HEADER" ] || die "store header does not match the 16-column schema: $STORE"
  n=0; bad=0
  while IFS= read -r line; do
    n=$((n+1))
    nf="$(printf '%s' "$line" | awk -F'\t' '{print NF}')"
    if [ "$nf" != "$NCOLS" ]; then
      printf 'record-packet: row %s has %s fields, expected %s: %s\n' "$n" "$nf" "$NCOLS" "$line" >&2
      bad=$((bad+1)); continue
    fi
    IFS="$TAB" read -r c1 c2 c3 c4 c5 c6 c7 c8 c9 c10 c11 c12 c13 c14 c15 c16 <<<"$line"
    validate_fields "$c1" "$c2" "$c3" "$c4" "$c5" "$c6" "$c7" "$c8" "$c9" "$c10" \
                    "$c11" "$c12" "$c13" "$c14" "$c15" "$c16" "row $n ($c1)" || bad=$((bad+1))
  done < <(datarows "$STORE")
  if [ "$n" -eq 0 ]; then
    printf 'record-packet: REFUSED — %s has 0 data rows. An empty store is not a valid store; it is an unmeasured system.\n' "$STORE" >&2
    exit 2
  fi
  printf 'validate: %s rows, %s invalid (%s)\n' "$n" "$bad" "$STORE"
  [ "$bad" -eq 0 ] || exit 2
  exit 0
fi

# -------------------------------------------------------------- verify-git ----
# The one class of claim this repo can falsify cheaply. Any row that names
# commits must have file/insertion/deletion figures that match what git says
# those commits did. A row that contradicts git is a defect in the store, not a
# disagreement of opinion.
if [ "$MODE" = "verify" ]; then
  [ -f "$STORE" ] || die "store not found: $STORE"
  [ -n "$REPO" ] || REPO="$SELF_DIR"
  git -C "$REPO" rev-parse --git-dir > /dev/null 2>&1 || die "not a git repository: $REPO"

  verified=0; mismatched=0; unverifiable=0
  while IFS="$TAB" read -r pid dt lane rd wm sm ag fl ins del ta dg de cm ev nt; do
    [ "$cm" = "-" ] && continue
    shas="$(printf '%s' "$cm" | tr ',' ' ')"
    missing=""
    for s in $shas; do
      git -C "$REPO" cat-file -e "${s}^{commit}" 2>/dev/null || missing="$missing $s"
    done
    if [ -n "$missing" ]; then
      printf '  UNVERIFIABLE  %s  %s  commit(s) not present in this repository:%s\n' "$pid" "$cm" "$missing"
      unverifiable=$((unverifiable+1)); continue
    fi
    # shellcheck disable=SC2086
    stat="$(git -C "$REPO" show --numstat --format='' $shas 2>/dev/null \
            | awk -F'\t' 'NF>=3 { p[$3]=1; if ($1 ~ /^[0-9]+$/) i+=$1; if ($2 ~ /^[0-9]+$/) d+=$2 }
                          END { printf "%d %d %d", i+0, d+0, length(p) }')"
    gi="$(printf '%s' "$stat" | cut -d' ' -f1)"
    gd="$(printf '%s' "$stat" | cut -d' ' -f2)"
    gf="$(printf '%s' "$stat" | cut -d' ' -f3)"
    if [ "${gf:-0}" -eq 0 ]; then
      printf '  UNVERIFIABLE  %s  %s  git reports no numstat for these commits (merge or empty diff)\n' "$pid" "$cm"
      unverifiable=$((unverifiable+1)); continue
    fi
    bad=""
    [ "$fl"  != "-" ] && [ "$fl"  != "$gf" ] && bad="$bad files: row says $fl, git says $gf."
    [ "$ins" != "-" ] && [ "$ins" != "$gi" ] && bad="$bad insertions: row says $ins, git says $gi."
    [ "$del" != "-" ] && [ "$del" != "$gd" ] && bad="$bad deletions: row says $del, git says $gd."
    if [ -n "$bad" ]; then
      printf '  MISMATCH  %s  %s %s\n' "$pid" "$cm" "$bad"
      mismatched=$((mismatched+1))
    else
      printf '  VERIFIED  %s  %s  files=%s insertions=%s deletions=%s\n' "$pid" "$cm" "$gf" "$gi" "$gd"
      verified=$((verified+1))
    fi
  done < <(datarows "$STORE")

  printf 'verify-git: %s ok, %s mismatched, %s unverifiable (repo %s)\n' \
    "$verified" "$mismatched" "$unverifiable" "$REPO"
  if [ "$mismatched" -gt 0 ]; then
    printf 'record-packet: REFUSED — %s row(s) contradict git.\n' "$mismatched" >&2
    exit 2
  fi
  if [ "$verified" -eq 0 ]; then
    printf 'record-packet: REFUSED — 0 rows were actually checked against git. A verifier that verified nothing must not report success.\n' >&2
    exit 2
  fi
  exit 0
fi

# ------------------------------------------------------------------ append ----
[ -n "$f_date" ] || f_date="$(date +%Y-%m-%d 2>/dev/null)"
[ -n "$f_date" ] || f_date="-"

for v in "$f_packet" "$f_date" "$f_lane" "$f_rounds" "$f_wall" "$f_serial" \
         "$f_agents" "$f_files" "$f_ins" "$f_del" "$f_tests" "$f_dg" "$f_de" \
         "$f_commits" "$f_evidence" "$f_note"; do
  has_ctrl "$v" && die "a field contains a tab or newline — it would corrupt the TSV: \"$v\""
done

validate_fields "$f_packet" "$f_date" "$f_lane" "$f_rounds" "$f_wall" "$f_serial" \
                "$f_agents" "$f_files" "$f_ins" "$f_del" "$f_tests" "$f_dg" "$f_de" \
                "$f_commits" "$f_evidence" "$f_note" "record" || exit 2

ensure_store "$STORE"
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$f_packet" "$f_date" "$f_lane" "$f_rounds" "$f_wall" "$f_serial" "$f_agents" \
  "$f_files" "$f_ins" "$f_del" "$f_tests" "$f_dg" "$f_de" "$f_commits" \
  "$f_evidence" "$f_note" >> "$STORE" || die "cannot append to $STORE"

printf 'recorded: %s (%s lane) -> %s\n' "$f_packet" "$f_lane" "$STORE"
