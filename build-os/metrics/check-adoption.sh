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

# --- the lane cross-check, and where its numbers come from -------------------
# THE HOLE THIS CLOSES, named by this file's own honesty section. Everything
# above trusts one self-asserted word. A receipt that says "**Lane:** tiny" is
# waived by WAIVED_LANES a few lines up, and the tiny lane already waives qa,
# the reviewer, the archivist and the receipt itself. So a single unverified
# token switches the entire gate-set off, and until now nothing anywhere
# compared that token against what the packet actually did. An agent that learns
# to type `tiny` gets a Build OS with no gates and no complaints.
#
# THE ONLY EVIDENCE ADMITTED IS GIT. Prose in a receipt is written by the same
# agent that declared the lane, so it cannot referee the declaration. What git
# proves is which paths a commit touched and how many lines it added and
# removed. That is the whole signal.
#
# WHERE THE NUMBERS COME FROM — DERIVATION, NOT TASTE. The calibration set is
# this repository's own store. Four rows declare a non-waived lane AND name
# commits, so four packets have a git-verified size:
#
#     gravito_metrics_adoption_guard_a                  7 files    852 changed
#     gravito_pilot_kit_a                               8 files   2005 changed
#     gravito_productization_pa_maintenance_upstream_a  18 files  9818 changed
#     gravito_fanout_lanes_scaffold_release_a           32 files  2422 changed
#
# The thresholds are the MEDIAN of that distribution:
#     files  {7, 8, 18, 32}          -> (8 + 18) / 2      = 13
#     churn  {852, 2005, 2422, 9818} -> (2005 + 2422) / 2 = 2213.5 -> 2213
#
# THE OTHER HALF OF THE CALIBRATION: what `tiny` actually looks like here. Three
# commits in d3d8305..da4ae81 are tiny-lane work — 641527f (1 file, 116 changed;
# the only row in the store declaring tiny), d42a57d (1 file, 2) and da4ae81
# (1 file, 5). The largest is 1 file / 116 changed lines. The thresholds sit 13x
# and 19x above it, with a wide empty band between the two populations
# (1 -> 7 files, 116 -> 852 changed lines), and the line is drawn at the far
# side of that band.
#
# THE STANCE — SPECIFICITY OVER SENSITIVITY, STATED SO IT CAN BE ARGUED WITH.
# A check that flags legitimate work is switched off inside a week, and a
# switched-off check is worse than none because it leaves behind the belief that
# it is running. So recall is deliberately traded away: a `tiny` mis-declared
# over work the size of gravito_metrics_adoption_guard_a (7 files / 852 lines)
# or gravito_pilot_kit_a (8 / 2005) PASSES. Half the calibration set survives
# being relabelled. What does not survive is the egregious case the hole was
# named for — a "tiny" that rewrote 30 files, or churned 2000+ lines. Catching
# only that is the design, not a shortfall in it.
#
# WHAT THIS DOES NOT CATCH, SAID PLAINLY. gravito_test_harness_stdin_hang_a is
# recorded lane=tiny rounds=6 against a 2-round budget — this system's worst
# compliance record. Its SIZE is 1 file / 116 changed lines, which is genuinely
# tiny, so this check passes it and should. That failure was a BUDGET breach,
# not a mis-declaration. They are different defects and they need different
# guards; a rounds guard is not built here and its absence is a named gap, not
# an oversight.
LANE_TINY_MAX_FILES=13
LANE_TINY_MAX_CHURN=2213
# The escape hatch reuses MIN_NOTE's calibration, because it is the same kind of
# artifact: a sentence a skeptic has to audit.
MIN_OVERRIDE_REASON="$MIN_NOTE"
OVERRIDE_TOKEN="LANE-OVERRIDE"

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

# The row for a packet id, or empty.
store_row(){ datarows "$STORE" | awk -F'\t' -v p="$1" '$1==p{print; exit}'; }

# Commits attributable to a packet, in order of decreasing trustworthiness:
#
#   1. the store row's `commits` column — curated attribution that
#      record-packet.sh --verify-git has already reconciled against git (the
#      guard refuses the whole store above if it has not).
#   2. failing that, SHAs inside the receipt's "## Commits" section ONLY.
#
# The section restriction is a false-positive defence with a name. Receipt
# preambles routinely quote a base and a merge-base ("**Base:** `5b956c0`
# (merge-base with origin/... = `7ef50e8`)"). Measuring those would attribute
# another packet's diff to this one and FABRICATE a violation, which is exactly
# the failure mode that gets a check like this deleted. Anything outside the
# Commits section is ignored, and a receipt with no Commits section is reported
# unmeasurable and passes.
packet_commits(){ # <pid> <receipt-or-empty>
  local pid="$1" f="${2:-}" row cm out="" s
  row="$(store_row "$pid")"
  if [ -n "$row" ]; then
    cm="$(printf '%s' "$row" | cut -f14)"
    if [ -n "$cm" ] && [ "$cm" != "-" ]; then
      for s in $(printf '%s' "$cm" | tr ',' ' '); do
        git -C "$REPO" cat-file -e "${s}^{commit}" 2>/dev/null && out="$out $s"
      done
      printf '%s' "${out# }"; return 0
    fi
  fi
  { [ -n "$f" ] && [ -f "$f" ]; } || { printf ''; return 0; }
  for s in $(awk 'tolower($0) ~ /^#+[ \t]*commits?[ \t]*$/ {inc=1; next}
                  /^#+[ \t]/ {inc=0}
                  inc' "$f" 2>/dev/null | grep -oE '\b[0-9a-f]{7,40}\b' | sort -u); do
    git -C "$REPO" cat-file -e "${s}^{commit}" 2>/dev/null && out="$out $s"
  done
  printf '%s' "${out# }"
}

# Union measurement across commits, using the SAME numstat convention
# record-packet.sh --verify-git uses, so a row that passed that check and this
# one cannot disagree about what git said. Emits "<files> <churn> <testfiles>".
measure_commits(){ # <sha...>
  git -C "$REPO" show --numstat --format='' "$@" 2>/dev/null \
    | awk -F'\t' '
        NF>=3 { p[$3]=1
                if ($1 ~ /^[0-9]+$/) c+=$1
                if ($2 ~ /^[0-9]+$/) c+=$2 }
        END   { t=0
                for (k in p) if (k ~ /(^|\/)(tests?|spec)\// || k ~ /[._](test|tests|spec)\./) t++
                printf "%d %d %d\n", length(p), c+0, t }'
}

# THE ESCAPE HATCH, AND WHAT IT COSTS. Some large diffs are genuinely `tiny` in
# judgment — a mechanical rename across 40 files. Refusing that outright would
# get this check deleted; passing it silently would make the rule a suggestion.
# The reviewer's standing ruling applies in both directions: a rule with no
# stated fallback gets quietly broken, and a fallback that leaves no trace is
# the same as no rule. So an override must
#   (a) exist, under ONE fixed token, so `grep -rn LANE-OVERRIDE build-os/`
#       enumerates every one that has ever been claimed;
#   (b) carry a real clause of justification (MIN_OVERRIDE_REASON chars); and
#   (c) NAME THIS PACKET'S MEASURED FILE COUNT. That is the visible cost: the
#       number can only be written by someone who looked at the actual size, so
#       a boilerplate override copied from another packet fails.
# Every honoured override prints a LANE-OVERRIDDEN line on every run. It is
# never silent.
# Returns 0 honoured, 1 absent, 2 malformed. Malformed is a violation in its own
# right — a half-written override must not degrade into a pass.
OV_LINE=""; OV_WHY=""
lane_override(){ # <receipt-or-empty> <note> <measured-files>
  local f="$1" note="$2" nf="$3" line="" just
  OV_LINE=""; OV_WHY=""
  if [ -n "$f" ] && [ -f "$f" ]; then
    line="$(grep -m1 -F "$OVERRIDE_TOKEN" "$f" 2>/dev/null)"
  fi
  if [ -z "$line" ] && printf '%s' "$note" | grep -qF "$OVERRIDE_TOKEN"; then
    line="$(printf '%s' "$note" | sed "s/.*\(${OVERRIDE_TOKEN}\)/\1/")"
  fi
  [ -n "$line" ] || return 1
  just="${line#*"$OVERRIDE_TOKEN"}"; just="${just#:}"
  just="$(printf '%s' "$just" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  if [ "${#just}" -lt "$MIN_OVERRIDE_REASON" ]; then
    OV_WHY="its justification is ${#just} chars (minimum $MIN_OVERRIDE_REASON) — a one-clause override is a silent pass wearing a label"
    return 2
  fi
  if ! printf '%s' "$just" | grep -qE "(^|[^0-9])${nf}([^0-9]|$)"; then
    OV_WHY="it never names this packet's measured file count ($nf), so it cannot have been written against this packet's actual size — a boilerplate override is not an override"
    return 2
  fi
  OV_LINE="$line"
  return 0
}

# The median of a list of integers on stdin. Even-length medians floor, which is
# how 2213.5 became 2213.
median_of(){
  local vals=() n
  mapfile -t vals < <(sort -n)
  n="${#vals[@]}"
  if [ "$n" -eq 0 ]; then printf '0'; return; fi
  if [ $((n % 2)) -eq 1 ]; then printf '%s' "${vals[$((n/2))]}"
  else printf '%s' "$(( ( ${vals[$((n/2 - 1))]} + ${vals[$((n/2))]} ) / 2 ))"; fi
}

# The calibration basis: rows that declare a NON-waived lane and name commits
# git can measure. These are the packets the thresholds were derived from.
# Emits "<files>\t<churn>" per row.
#
# It is measured FROM GIT rather than read out of the row's `files` column on
# purpose. The column is optional — the archivist is told to write "-" for
# anything it did not measure, and an honest store is full of dashes. Deriving
# the basis from the column would make this guard refuse any store whose rows
# recorded rounds but not diffs, which is a perfectly honest store and a red
# guard on day one. Git answers for every row that names a commit.
lane_basis_rows(){
  local pid dt lane rd wm sm ag fl ins del ta dg de cm ev nt shas nf churn tf
  while IFS="$TAB" read -r pid dt lane rd wm sm ag fl ins del ta dg de cm ev nt; do
    [ -n "$pid" ] || continue
    in_list "$lane" "$WAIVED_LANES" && continue
    { [ -n "$cm" ] && [ "$cm" != "-" ]; } || continue
    shas="$(packet_commits "$pid" "")"
    [ -n "$shas" ] || continue
    # shellcheck disable=SC2086
    read -r nf churn tf < <(measure_commits $shas)
    [ "${nf:-0}" -gt 0 ] || continue
    printf '%s\t%s\n' "$nf" "$churn"
  done < <(datarows "$STORE")
}

LANE_SUBJECTS=0; LANE_OK=0; LANE_UNMEAS=0; LANE_OVR=0; LANE_BAD=0; LANE_VIOL=0
# Subjects a threshold was actually APPLIED to. This is the number the vacuity
# refusal keys on, not LANE_SUBJECTS: a declaration git cannot measure has no
# threshold applied to it, so it needs no calibration to be sound.
LANE_MEASURED=0

# Cross-check ONE declaration of a waived lane against what git says the packet
# did. Returns 1 on a violation.
lane_size_check(){ # <pid> <declared lane> <receipt-or-empty>
  local pid="$1" lane="$2" f="${3:-}" row note="" shas nf churn tf rc
  LANE_SUBJECTS=$((LANE_SUBJECTS+1))
  row="$(store_row "$pid")"
  [ -n "$row" ] && note="$(printf '%s' "$row" | cut -f16)"

  shas="$(packet_commits "$pid" "$f")"
  if [ -z "$shas" ]; then
    LANE_UNMEAS=$((LANE_UNMEAS+1))
    [ "$VERBOSE" = "1" ] && say "  LANE-UNMEASURED $pid  declares $lane and names no commit this repository contains. A read-only answer and a diagnosis leave no diff at all, and an absent diff is not evidence of a large one."
    return 0
  fi
  # shellcheck disable=SC2086
  read -r nf churn tf < <(measure_commits $shas)
  if [ "${nf:-0}" -eq 0 ]; then
    LANE_UNMEAS=$((LANE_UNMEAS+1))
    [ "$VERBOSE" = "1" ] && say "  LANE-UNMEASURED $pid  git reports no numstat for $shas (a merge or an empty diff)"
    return 0
  fi

  LANE_MEASURED=$((LANE_MEASURED+1))
  if [ "$nf" -lt "$LANE_TINY_MAX_FILES" ] && [ "$churn" -lt "$LANE_TINY_MAX_CHURN" ]; then
    LANE_OK=$((LANE_OK+1))
    [ "$VERBOSE" = "1" ] && say "  LANE-OK        $pid  declares $lane and git agrees: $nf file(s), $churn changed line(s), $tf test file(s) — under $LANE_TINY_MAX_FILES files / $LANE_TINY_MAX_CHURN changed lines"
    return 0
  fi

  lane_override "$f" "$note" "$nf"; rc=$?
  case "$rc" in
    0) LANE_OVR=$((LANE_OVR+1))
       say "  LANE-OVERRIDDEN $pid  declares $lane over $nf file(s) / $churn changed line(s) — over threshold, allowed by a recorded override: ${OV_LINE#*"$OVERRIDE_TOKEN"}"
       return 0 ;;
    2) LANE_BAD=$((LANE_BAD+1)); LANE_VIOL=$((LANE_VIOL+1))
       say "  LANE-OVERRIDE-BAD $pid  declares $lane over $nf file(s) / $churn changed line(s) and carries a $OVERRIDE_TOKEN line, but $OV_WHY"
       return 1 ;;
  esac

  LANE_VIOL=$((LANE_VIOL+1))
  say "  LANE-CONTRADICTED $pid  declares lane=$lane, but git says this packet is $nf file(s) and $churn changed line(s) ($tf test file(s)) across $shas. Thresholds: $LANE_TINY_MAX_FILES files / $LANE_TINY_MAX_CHURN changed lines — the median non-waived-lane packet in $STORE. The $lane lane waives qa, the reviewer, the archivist and the receipt; work this size does not get to waive them by self-assertion. If the judgment is genuinely $lane, record it: a line reading \"$OVERRIDE_TOKEN: <why, naming $nf files>\" in the receipt or in the row's note."
  return 1
}

# ------------------------------------------------------------- 4. the scan ---
say "check-adoption: ${#RCPTS[@]} receipt(s) in $RECEIPTS vs $NROWS row(s) in $STORE"
say "  boundaries: row_required_after=$B_row  single_commit_required_after=$B_commit"

# The calibration basis, measured once. The refusal that depends on it lives
# AFTER the scan, not here — see "VACUITY, THE LANE CROSS-CHECK'S OWN HALF".
LANE_BASIS_DATA="$(lane_basis_rows)"
LANE_BASIS="$(printf '%s' "$LANE_BASIS_DATA" | grep -c .)"

# The store's CURRENT medians, printed beside the pinned thresholds so drift is
# visible. Advisory ONLY, and deliberately so: a threshold that auto-follows the
# store is attacker-controlled — anyone who wants a bigger `tiny` allowance just
# records a few big packets and the ceiling rises to meet them. Re-deriving is a
# reviewed edit to three files at once (this script, the router, and
# tests/lane_declaration_tests.sh), never a side effect of recording work.
LANE_MED_F="$(printf '%s' "$LANE_BASIS_DATA" | grep . | cut -f1 | median_of)"
LANE_MED_C="$(printf '%s' "$LANE_BASIS_DATA" | grep . | cut -f2 | median_of)"
LANE_DRIFT=""
{ [ "$LANE_MED_F" = "$LANE_TINY_MAX_FILES" ] && [ "$LANE_MED_C" = "$LANE_TINY_MAX_CHURN" ]; } \
  || LANE_DRIFT="  [DRIFT — the pinned numbers are what this scan enforces; re-derive deliberately, do not auto-follow]"
say "  lane cross-check calibrated from $LANE_BASIS non-waived-lane row(s); enforcing $LANE_TINY_MAX_FILES files / $LANE_TINY_MAX_CHURN changed lines, store's current medians $LANE_MED_F / $LANE_MED_C$LANE_DRIFT"

INSCOPE=0; RECORDED=0; MISSING=0; HOLLOW=0; GRAND=0; WAIVED=0; ATTRIB=0
VIOL=0
LANE_SEEN=""

for f in "${RCPTS[@]}"; do
  pid="$(basename "$f" .md)"
  lane="$(receipt_lane "$f")"
  d="$(receipt_date "$f")"

  if in_list "$lane" "$WAIVED_LANES"; then
    WAIVED=$((WAIVED+1))
    [ "$VERBOSE" = "1" ] && say "  WAIVED         $pid  declares lane=$lane — that lane closes with no packet and owes no row"
    # The waiver holds, but it is no longer taken on trust. This is the one
    # place a single self-asserted word switches the whole gate-set off, so it
    # is also the one place the word gets cross-examined against git.
    LANE_SEEN="$LANE_SEEN $pid"
    lane_size_check "$pid" "$lane" "$f"
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

# THE OTHER DECLARATION SURFACE. A receipt is not the only place a lane is
# asserted — the store has a lane column, and `tiny` work legitimately closes
# with a row and NO receipt (the lane waives the receipt, not the measurement).
# A cross-check that only read receipts would miss every mis-declaration made by
# an agent that skipped the receipt, which is precisely the agent this exists to
# catch.
while IFS="$TAB" read -r r_pid r_dt r_lane r_rest; do
  [ -n "$r_pid" ] || continue
  in_list "$r_lane" "$WAIVED_LANES" || continue
  case " $LANE_SEEN " in *" $r_pid "*) continue ;; esac
  LANE_SEEN="$LANE_SEEN $r_pid"
  lane_size_check "$r_pid" "$r_lane" ""
done < <(datarows "$STORE")

say "check-adoption: lane cross-check — $LANE_SUBJECTS waived-lane declaration(s) examined: $LANE_OK match their diff, $LANE_UNMEAS unmeasurable (no commit), $LANE_OVR overridden on the record, $LANE_BAD malformed override, $((LANE_VIOL - LANE_BAD)) contradicted"

# VACUITY, THE LANE CROSS-CHECK'S OWN HALF. The thresholds are the median of a
# real distribution of packet sizes. If that distribution is empty they are
# numbers from somewhere else, and a declaration judged against a threshold
# nothing here supports has not been judged — a green would mean nothing, which
# is the same shape of failure as a blinded scanner reporting success.
#
# THE REFUSAL IS GATED ON LANE_MEASURED, NOT ON THE BASIS ALONE, and that
# distinction is the whole difference between a guard and a tax. Refusing
# whenever the basis is empty would make this red for every project that has
# simply never recorded a sized packet yet — which is every project on its first
# day, and the file above already says a guard that is red on the day it ships
# gets disabled by the end of the week. The unsoundness only exists at the
# moment a threshold is APPLIED to something. So: measure nothing, need nothing;
# measure something, and the calibration has to be real.
#
# HONEST LIMIT ON THAT GATE. It is defence in depth and cannot be falsified on
# its own from here: any store that survives record-packet.sh --verify-git above
# must contain a resolvable commit with a real diff, and such a row is
# necessarily EITHER a basis row (non-waived lane) OR a measurable subject
# (waived lane). "Empty basis with nothing measured" is therefore unreachable
# from a store the earlier gates admit. What actually keeps this guard off the
# day-one-red path is that the basis is measured FROM GIT rather than from the
# optional `files` column — see lane_basis_rows.
if [ "$LANE_MEASURED" -gt 0 ] && [ "${LANE_BASIS:-0}" -eq 0 ]; then
  refuse "the lane cross-check applied its thresholds ($LANE_TINY_MAX_FILES files / $LANE_TINY_MAX_CHURN changed lines) to $LANE_MEASURED waived-lane declaration(s), but $STORE contains no non-waived-lane row whose commits this repository can measure — so there is nothing here to have calibrated those thresholds against. They are the median of a real distribution of packet sizes; with an empty basis they are borrowed numbers, and a declaration checked against a borrowed number has not been checked. Record at least one non-waived packet with a real commit."
fi

if [ "$LANE_VIOL" -gt 0 ]; then
  printf 'check-adoption: REFUSED — %s lane declaration(s) contradict what git says the packet did.\n' "$LANE_VIOL" >&2
  printf 'A declared lane is checkable, not merely stated: read-only/diagnosis/tiny waive qa, the reviewer, the archivist, the receipt AND the metrics row, so the declaration is cross-examined against files touched and lines changed.\nFix it by declaring the lane the work actually was, or — if the judgment genuinely holds for work this size — by recording an override: a "%s: <why>" line in the receipt or the row'"'"'s note, naming the measured file count. The override is greppable on purpose; there is no silent pass.\nThresholds live in build-os/memory/tool_router.md and are pinned by tests/lane_declaration_tests.sh. Do NOT clear a failure by raising them.\n' \
    "$OVERRIDE_TOKEN" >&2
fi

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
fi
[ "$((VIOL + LANE_VIOL))" -gt 0 ] && exit 2
exit 0
