#!/usr/bin/env bash
# Build OS — metrics adoption guard.
#
# THE FAILURE MODE THIS FILE EXISTS AGAINST is shelfware. record-packet.sh
# refuses a bad row at the write path and report-speed.sh refuses an empty store
# at the read path, but nothing anywhere noticed a packet that CLOSED WITHOUT
# RECORDING AT ALL. The predicted end state of that gap is a store frozen at its
# seed rows forever while every artifact around it claims the system is measured.
# Nothing fails when nobody records. This is the thing that fails.
#
# THE GROUND TRUTH FOR "A PACKET CLOSED" IS A RECEIPT. build-os/receipts/<id>.md
# is written by the archivist at close and by nothing else, so the receipt set is
# the arrival log this guard reconciles the store against. The comparison is
# receipt -> row, by exact packet id (the receipt's filename stem).
#
# WHAT IT DELIBERATELY DOES NOT DEMAND. The read-only, diagnosis and tiny lanes
# close with no packet and no receipt. They therefore never enter this scan at
# all — the waiver holds for free, and this guard must never manufacture an
# obligation the lanes explicitly waive. A receipt that declares one of those
# lanes (retro-classification happens) is skipped by name.
#
# THE GRANDFATHER PROBLEM, HANDLED HONESTLY. Receipts P-001..P-022 were written
# before the store existed. A guard that demands rows for them is red on the day
# it ships, and a guard that is red on the day it ships is disabled by the end of
# the week — which is strictly worse than no guard. So the exemption is ONE DATED
# BOUNDARY per obligation, declared in adoption_boundaries.tsv, and there is no
# per-packet exemption syntax at all: an exception list that can grow is a
# shelfware machine with extra steps. Moving a boundary forward to silence a
# failure does not buy a pass either — it empties the in-scope set, and an
# empty in-scope set is REFUSED below (a guard with nothing in scope cannot
# fail, so it must not report success).
#
# THE JUNK-ROW DEFENCE. "Record a row" is satisfiable by a row of all "-", so a
# row is only counted as recording if it is minimally meaningful: it names a
# lane and a date, it names commits that this repository actually contains, it
# fills at least MIN_MEASURED of the 11 measurable cells, it either gives a
# rounds count or says in the note why rounds is "-", and its note is long
# enough to attribute the numbers. A hollow row is reported as HOLLOW and counts
# as WORSE than a missing row, because it is a missing row wearing evidence.
#
# Local only. Reads receipts, the store and git. Writes nothing, anywhere.
#
# Usage:
#   check-adoption.sh [--receipts DIR] [--store PATH] [--boundaries PATH]
#                     [--repo PATH] [--verbose]
# Exit: 0 adopted, 2 refused (violations, or a scan that could not be trusted).
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SELF_DIR/../.." && pwd)"
RECEIPTS="$ROOT/build-os/receipts"
STORE="$SELF_DIR/packet_metrics.tsv"
BOUNDS="$SELF_DIR/adoption_boundaries.tsv"
RECORDER="$SELF_DIR/record-packet.sh"
REPO="$ROOT"
VERBOSE=0
TAB=$'\t'

HEADER="packet_id${TAB}date${TAB}lane${TAB}rounds${TAB}wall_min${TAB}serial_min${TAB}agents${TAB}files${TAB}insertions${TAB}deletions${TAB}tests_added${TAB}defects_gated${TAB}defects_escaped${TAB}commits${TAB}evidence${TAB}note"
BOUNDS_HEADER="obligation${TAB}required_after${TAB}reason"
NCOLS=16

# Lanes that close with no packet and no receipt. They owe nothing here.
WAIVED_LANES="read-only diagnosis tiny"
# The obligations this guard enforces. Exactly these keys, exactly once each,
# must appear in the boundary manifest — an unknown key is how a per-packet
# exemption list starts.
OBLIGATIONS="row_required_after single_commit_required_after"

# --- junk-row thresholds, and why they are what they are ---------------------
# 11 cells are measurable (rounds..commits). Requiring 4 means a row must say
# something about time/size/quality, not just exist. A row of all "-" scores 0.
MIN_MEASURED=4
# The recorder already enforces >=12 chars. A row that a skeptic is expected to
# audit needs more than a label; 40 chars is roughly one clause of provenance.
MIN_NOTE=40

refuse(){ printf 'check-adoption: REFUSED — %s\n' "$*" >&2; exit 2; }
say(){ printf '%s\n' "$*"; }
in_list(){ local v="$1" l; for l in $2; do [ "$v" = "$l" ] && return 0; done; return 1; }
is_date(){ [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --receipts)   [ "$#" -ge 2 ] || refuse "--receipts requires a value";   RECEIPTS="$2"; shift 2 ;;
    --store)      [ "$#" -ge 2 ] || refuse "--store requires a value";      STORE="$2";    shift 2 ;;
    --boundaries) [ "$#" -ge 2 ] || refuse "--boundaries requires a value"; BOUNDS="$2";   shift 2 ;;
    --repo)       [ "$#" -ge 2 ] || refuse "--repo requires a value";       REPO="$2";     shift 2 ;;
    --verbose|-v) VERBOSE=1; shift ;;
    -h|--help)    sed -n '2,46p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *)            refuse "unknown argument: $1" ;;
  esac
done

TODAY="$(date +%Y-%m-%d 2>/dev/null)"; [ -n "$TODAY" ] || TODAY="9999-12-31"

datarows(){ tail -n +2 "$1" 2>/dev/null | grep -v '^[[:space:]]*$' | grep -v '^#'; }

# ------------------------------------------------- 1. the boundary manifest ---
# The manifest is the whole exemption mechanism, so it is checked harder than
# anything it exempts.
[ -f "$BOUNDS" ] || refuse "no boundary manifest at $BOUNDS. Without a declared, dated grandfather boundary this guard cannot tell a pre-instrument receipt from an unrecorded packet, and a guard that guesses is not a guard."
[ "$(head -n1 "$BOUNDS")" = "$BOUNDS_HEADER" ] \
  || refuse "$BOUNDS does not carry the 3-column header: obligation<TAB>required_after<TAB>reason"

B_row=""; B_commit=""; seen_keys=""
while IFS="$TAB" read -r key val reason extra; do
  [ -n "$key" ] || continue
  [ -n "${extra:-}" ] && refuse "boundary line \"$key\" has more than 3 fields"
  in_list "$key" "$OBLIGATIONS" \
    || refuse "boundary manifest declares unknown obligation \"$key\". The only exemptions this guard honours are the fixed keys ($OBLIGATIONS). There is deliberately no per-packet exemption syntax — a list of forgiven packet ids is exactly the ever-growing exception list this design refuses."
  case " $seen_keys " in *" $key "*) refuse "boundary \"$key\" is declared more than once — a boundary with two values is not a boundary" ;; esac
  seen_keys="$seen_keys $key"
  is_date "$val" || refuse "boundary \"$key\" value \"$val\" is not a YYYY-MM-DD date"
  [ "$val" \> "$TODAY" ] && refuse "boundary \"$key\" is dated $val, which is in the future (today is $TODAY). Work that has not happened yet cannot be grandfathered."
  [ "${#reason}" -ge 24 ] || refuse "boundary \"$key\" has no stated reason. An undocumented exemption is indistinguishable from someone turning the guard off."
  case "$key" in
    row_required_after)           B_row="$val" ;;
    single_commit_required_after) B_commit="$val" ;;
  esac
done < <(datarows "$BOUNDS")

for k in $OBLIGATIONS; do
  case " $seen_keys " in *" $k "*) ;; *) refuse "boundary manifest never declares \"$k\"" ;; esac
done

# ------------------------------------------------------------ 2. the store ---
[ -f "$STORE" ] || refuse "no metrics store at $STORE. Nothing has been recorded, so nothing can have been adopted."
[ "$(head -n1 "$STORE")" = "$HEADER" ] || refuse "$STORE does not carry the 16-column schema header"
NROWS="$(datarows "$STORE" | wc -l | tr -d ' ')"; NROWS="${NROWS:-0}"
# VACUITY, HALF ONE: zero rows is not "nothing to compare", it is the shelfware
# state itself.
[ "$NROWS" -eq 0 ] && refuse "$STORE has 0 data rows. That is not an empty comparison; it is the exact failure this guard exists to name."

# Reuse the validators that already exist rather than reimplementing them: a row
# the recorder would refuse to write must never be a row this guard accepts, and
# a store that contradicts git cannot support any adoption claim at all.
if [ -x "$RECORDER" ] || [ -f "$RECORDER" ]; then
  if ! VOUT="$(bash "$RECORDER" --validate --store "$STORE" 2>&1)"; then
    printf '%s\n' "$VOUT" >&2
    refuse "the store does not pass record-packet.sh --validate. Adoption of an invalid store is not adoption."
  fi
  if ! GOUT="$(bash "$RECORDER" --verify-git --store "$STORE" --repo "$REPO" 2>&1)"; then
    printf '%s\n' "$GOUT" >&2
    refuse "the store does not pass record-packet.sh --verify-git against $REPO. A row that contradicts (or invents) git history is worse than a missing row."
  fi
else
  refuse "record-packet.sh not found at $RECORDER — the guard will not accept a store it cannot validate"
fi

# --------------------------------------------------------- 3. the receipts ---
[ -d "$RECEIPTS" ] || refuse "no receipts directory at $RECEIPTS. Either the scanner is pointed at the wrong tree or closed packets are leaving no record — both are failures, neither is a pass."

RCPTS=()
for f in "$RECEIPTS"/*.md; do
  [ -f "$f" ] || continue
  b="$(basename "$f")"
  [ "$b" = "README.md" ] && continue
  RCPTS+=("$f")
done
# VACUITY, HALF TWO: a scanner that found no receipts has not proved adoption,
# it has proved it was looking somewhere empty.
[ "${#RCPTS[@]}" -eq 0 ] && refuse "found 0 receipts under $RECEIPTS. A scan with nothing to scan must fail loudly; a silent pass here is how a blinded scanner reports success forever."

# Effective close date of a receipt. GIT FIRST, on purpose: the date a receipt
# entered history is ground truth, while the "**Date:**" line is prose the same
# agent wrote. A brand-new (untracked) receipt therefore dates to TODAY and is
# in scope — the guard fails closed on anything new, and fails open only on what
# git proves is old. That also closes the obvious dodge of omitting the date.
receipt_date(){
  local f="$1" d=""
  d="$(git -C "$REPO" log --diff-filter=A --format=%cs -1 -- "$f" 2>/dev/null | head -n1)"
  if ! is_date "${d:-}"; then
    d="$(grep -m1 -E '\*\*Date' "$f" 2>/dev/null | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -n1)"
  fi
  is_date "${d:-}" || d="$TODAY"
  printf '%s' "$d"
}

# A receipt may declare its lane ("- **Lane:** tiny"). Absent a declaration a
# receipt means a substantive close, because that is the only lane that produces
# one.
receipt_lane(){
  local f="$1" l
  l="$(grep -m1 -iE '^[-*[:space:]]*\*\*lane' "$f" 2>/dev/null \
       | sed -E 's/.*\*\*[Ll]ane:?\*\*[[:space:]]*//' \
       | tr -d '`' | awk '{print tolower($1)}' | tr -d ',.')"
  [ -n "${l:-}" ] || l="substantive"
  printf '%s' "$l"
}

# ------------------------------------------------------------- 4. the scan ---
say "check-adoption: ${#RCPTS[@]} receipt(s) in $RECEIPTS vs $NROWS row(s) in $STORE"
say "  boundaries: row_required_after=$B_row  single_commit_required_after=$B_commit"

INSCOPE=0; RECORDED=0; MISSING=0; HOLLOW=0; GRAND=0; WAIVED=0; ATTRIB=0
VIOL=0

for f in "${RCPTS[@]}"; do
  pid="$(basename "$f" .md)"
  lane="$(receipt_lane "$f")"
  d="$(receipt_date "$f")"

  if in_list "$lane" "$WAIVED_LANES"; then
    WAIVED=$((WAIVED+1))
    [ "$VERBOSE" = "1" ] && say "  WAIVED         $pid  declares lane=$lane — that lane closes with no packet and owes no row"
    continue
  fi
  if ! [ "$d" \> "$B_row" ]; then
    GRAND=$((GRAND+1))
    [ "$VERBOSE" = "1" ] && say "  GRANDFATHERED  $pid  $d is on or before row_required_after=$B_row"
    continue
  fi

  INSCOPE=$((INSCOPE+1))
  row="$(datarows "$STORE" | awk -F'\t' -v p="$pid" '$1==p{print; exit}')"
  if [ -z "$row" ]; then
    say "  MISSING        $pid  closed $d (lane $lane) and never recorded a row in the store"
    MISSING=$((MISSING+1)); VIOL=$((VIOL+1)); continue
  fi

  IFS="$TAB" read -r c_pid c_date c_lane c_rd c_wm c_sm c_ag c_fl c_ins c_del c_ta c_dg c_de c_cm c_ev c_nt <<<"$row"

  # ---- junk-row defence -----------------------------------------------------
  why=""
  if [ -z "$c_lane" ] || [ "$c_lane" = "-" ]; then why="$why lane is unset;"; fi
  if [ "$c_date" = "-" ]; then why="$why date is '-' — an undated row cannot be placed against the boundary;"; fi
  measured=0
  for v in "$c_rd" "$c_wm" "$c_sm" "$c_ag" "$c_fl" "$c_ins" "$c_del" "$c_ta" "$c_dg" "$c_de" "$c_cm"; do
    [ "$v" != "-" ] && [ -n "$v" ] && measured=$((measured+1))
  done
  [ "$measured" -lt "$MIN_MEASURED" ] \
    && why="$why only $measured of 11 measurable cells are filled (minimum $MIN_MEASURED) — a row of dashes records that nothing was measured, which is not the same as recording the packet;"
  if [ "$c_cm" = "-" ]; then
    why="$why names no commit, so not one figure in it can be checked against git;"
  else
    for s in $(printf '%s' "$c_cm" | tr ',' ' '); do
      git -C "$REPO" cat-file -e "${s}^{commit}" 2>/dev/null \
        || why="$why names commit $s, which this repository does not contain;"
    done
  fi
  if [ "$c_rd" = "-" ]; then
    printf '%s' "$c_nt" | grep -qiE 'round' \
      || why="$why rounds is '-' and the note never says why — an unmeasured round count has to be an admission, not a blank;"
  fi
  [ "${#c_nt}" -lt "$MIN_NOTE" ] \
    && why="$why note is ${#c_nt} chars (minimum $MIN_NOTE) — a row nobody can audit is decoration;"

  if [ -n "$why" ]; then
    say "  HOLLOW         $pid  a row exists but does not record the packet:${why%;}"
    HOLLOW=$((HOLLOW+1)); VIOL=$((VIOL+1)); continue
  fi

  # ---- one commit per packet, with the stated fallback ----------------------
  ncom="$(printf '%s' "$c_cm" | tr ',' ' ' | wc -w | tr -d ' ')"
  if [ "${ncom:-1}" -gt 1 ] && [ "$d" \> "$B_commit" ]; then
    if grep -qiE 'file[ -]ownership manifest|ownership manifest|attribution by path' "$f"; then
      ATTRIB=$((ATTRIB+1))
      say "  RECORDED       $pid  $d  row ok; $ncom commits, and the receipt records the file-ownership manifest"
      RECORDED=$((RECORDED+1)); continue
    fi
    say "  UNATTRIBUTED   $pid  $d  the row names $ncom commits ($c_cm) and the receipt records no disjoint file-ownership manifest. One commit per packet where the merge allows it; where it does not, the manifest is what keeps attribution recoverable by path."
    VIOL=$((VIOL+1)); continue
  fi

  say "  RECORDED       $pid  $d  lane=$c_lane rounds=$c_rd commits=$c_cm ($measured/11 cells measured)"
  RECORDED=$((RECORDED+1))
done

# VACUITY, HALF THREE: every receipt grandfathered or waived means this guard
# checked nothing. That is also the exact shape of someone pushing the boundary
# forward to silence a failure, so it is refused rather than reported green.
if [ "$INSCOPE" -eq 0 ]; then
  printf 'check-adoption: %s receipt(s) scanned: %s grandfathered, %s lane-waived, 0 in scope.\n' \
    "${#RCPTS[@]}" "$GRAND" "$WAIVED" >&2
  refuse "0 receipts were in scope, so nothing was actually checked. A guard that cannot fail must not pass. Either the receipts are all pre-boundary (then this guard is not yet load-bearing and row_required_after should not have been moved), or the boundary was moved forward to silence a real miss."
fi

say "check-adoption: $INSCOPE in scope, $RECORDED recorded, $MISSING missing, $HOLLOW hollow, $GRAND grandfathered (<= $B_row), $WAIVED lane-waived"
if [ "$VIOL" -gt 0 ]; then
  printf 'check-adoption: REFUSED — %s closed packet(s) are not honestly recorded in %s.\n' "$VIOL" "$STORE" >&2
  printf 'Close the gap with build-os/metrics/record-packet.sh (see .claude/agents/archivist.md).\nDo NOT close it by widening a boundary: the boundary is dated, pinned by tests/metrics_adoption_tests.sh, and emptying the scope makes this guard refuse rather than pass.\n' >&2
  exit 2
fi
exit 0
