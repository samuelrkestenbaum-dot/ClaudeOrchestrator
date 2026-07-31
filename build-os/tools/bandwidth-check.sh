#!/usr/bin/env bash
# Build OS — work-in-flight capacity ceilings (integration bandwidth).
#
# WHAT THIS IS, AND WHY IT IS THE ODD ONE OUT. Every other registered control in
# this repository answers yes/no about an artefact THAT ALREADY EXISTS: is this
# row well-formed, does this claim match git, did the suite go green. This one
# answers a different question — IS THERE ROOM FOR MORE — and it is the first
# control here whose function is limiting what may be absorbed rather than
# judging what has already landed.
#
# WHY SEPARATE CEILINGS AND NOT ONE SCORE. The obvious shape is a composite:
# `load = w1*packets + w2*commits + w3*agents`, one number, one threshold. It is
# refused here for two reasons and both are load-bearing. First, the weights are
# unjustifiable — nothing in this repository has measured how a packet in flight
# trades off against a commit, and a weight nobody can derive is a constant
# nobody can defend. Second, and worse, a single number HIDES WHICH DIMENSION IS
# SATURATED: an operator told "load is 1.4, ceiling 1.0" learns nothing they can
# act on. So each dimension carries its own ceiling, its own authority, and its
# own message, and every refusal names the dimension that caused it.
#
# WHAT IS OBSERVABLE, AND WHAT IS HONESTLY NOT. The working contract in CLAUDE.md
# states four bandwidth conventions. Two of them are visible from git and the
# repository's own artefacts; two are not, and pretending otherwise would be
# worse than leaving them unimplemented, because a control that claims a limit
# it cannot observe converts an unenforced convention into a checkbox that looks
# enforced and is not.
#
#   packets     ENFORCED, gate.   build-os/packets/active_packet.md is defined by
#                                 its own header as holding THE ONE packet in
#                                 flight. Two ids in it is a malformed artefact,
#                                 not a matter of degree, so this refuses.
#   commits     ENFORCED, advise. "<=2 commits per packet" is a constant chosen
#                                 by the working contract, not derived from any
#                                 measurement. It is a class-C heuristic, and a
#                                 heuristic does not become a gate by being
#                                 useful — so a breach is REPORTED and the run
#                                 continues. Raising this to a gate is a
#                                 governance decision for the operator.
#   write_sets  DECLINED.         Observable — a fan-out manifest names each
#                                 agent's writable set, and swarm-merge.sh
#                                 already enforces the property that matters
#                                 (disjointness). But NO ceiling on the number of
#                                 concurrent write sets is declared anywhere in
#                                 the working contract, so enforcing one would
#                                 mean inventing a constant. Not done.
#   depth       DECLINED.         Rounds and serial agent stages are
#                                 TRANSCRIPT-ONLY. Nothing in git attests to how
#                                 many agent passes ran in series: one commit can
#                                 be one stage or five, and no artefact records
#                                 the difference. The lane-declaration packet
#                                 reached the same conclusion and declined to
#                                 build a round-budget guard for the same reason.
#
# WHAT IT DOES NOT DO. It does not observe agent concurrency, context budget,
# review capacity, or anything about a run while the run is happening. Every
# dimension here is read from a file or from git BETWEEN actions. It also does
# not enforce, and must not be read as enforcing, the external-mutation rule —
# push, merge, deploy, publish, secrets — which lives in the operator's
# permission system, outside this repository entirely.
#
# Local only. Reads files and runs read-only git plumbing. Writes nothing.
#
# Usage:
#   bandwidth-check.sh check      [--repo DIR] [--packet FILE]
#   bandwidth-check.sh dimensions
# Exit: 0 every ENFORCED-and-gating ceiling holds; 2 one is exceeded, or the
#       invocation is malformed.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SELF_DIR/../.." && pwd)"
PACKET=""

# --- the ceilings, one per enforced dimension, each defined exactly once ------
# These two lines are the entire quantitative content of this tool. They are
# cited by name in build-os/registry/control_registry.txt, and
# tests/bandwidth_tests.sh reads the cited line back and compares it against
# what `dimensions` reports, so the census and the tool cannot drift apart.
CEILING_PACKETS=1        # at most one packet in flight — the artefact's own definition
CEILING_COMMITS=2        # at most two commits per packet — CLAUDE.md working contract

refuse(){ printf 'bandwidth-check: REFUSED — %s\n' "$*" >&2; exit 2; }
say(){ printf 'bandwidth: %-11s %-13s %s\n' "$1" "$2" "$3"; }

CMD="${1:-}"
[ $# -gt 0 ] && shift
case "$CMD" in
  check|dimensions) ;;
  -h|--help|help) sed -n '2,66p' "${BASH_SOURCE[0]}"; exit 0 ;;
  "") refuse "no command — expected one of: check, dimensions" ;;
  *)  refuse "unknown command \"$CMD\" — expected one of: check, dimensions" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --repo)   [ $# -ge 2 ] || refuse "--repo needs a value";   REPO="$2"; shift 2 ;;
    --packet) [ $# -ge 2 ] || refuse "--packet needs a value"; PACKET="$2"; shift 2 ;;
    -h|--help) sed -n '2,66p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done

if [ "$CMD" = "dimensions" ]; then
  printf 'dimension: %-11s authority=%-7s ceiling=%s enforced — %s\n' \
    packets gate "$CEILING_PACKETS" \
    "at most one packet in flight; the artefact is defined as holding exactly one, so more is a defect and this refuses"
  printf 'dimension: %-11s authority=%-7s ceiling=%s enforced — %s\n' \
    commits advise "$CEILING_COMMITS" \
    "at most two commits per packet, counted against the packet's declared base; a chosen constant, so it advises and does not stop the run"
  printf 'dimension: %-11s authority=%-7s declined — %s\n' \
    write_sets none \
    "observable from a fan-out manifest, but no ceiling on concurrent write sets is declared in the working contract; enforcing one would mean inventing a constant"
  printf 'dimension: %-11s authority=%-7s declined — %s\n' \
    depth none \
    "serial agent stages are transcript-only; nothing in git attests to a round, so no ceiling is implemented and none is asserted"
  printf 'dimension model: one ceiling per dimension, evaluated independently. No dimension is combined with another.\n'
  exit 0
fi

[ -d "$REPO" ] || refuse "--repo is not a directory: $REPO"
[ -n "$PACKET" ] || PACKET="$REPO/build-os/packets/active_packet.md"

EXCEEDED_GATING=""
NOK=0; NOVER=0; NUNOBS=0; NDECL=0

# --- packets: at most one in flight -------------------------------------------
# The count is of DECLARED PACKET IDS in the active-packet artefact. Zero is a
# legitimate idle state (the archivist clears the file on close), so the ceiling
# is "at most one", not "exactly one".
if [ ! -f "$PACKET" ]; then
  say packets UNOBSERVABLE "no active-packet artefact at $PACKET; nothing attests to what is in flight, so this does not fire"
  NUNOBS=$((NUNOBS+1))
else
  NPKT="$(grep -cE '^[[:space:]]*[-*][[:space:]]*\*\*Packet id:\*\*' "$PACKET" || true)"
  NPKT="${NPKT:-0}"
  if [ "$NPKT" -gt "$CEILING_PACKETS" ]; then
    say packets EXCEEDED "$NPKT packet ids declared in $(basename "$PACKET"), ceiling $CEILING_PACKETS (enforced: gate)"
    EXCEEDED_GATING="${EXCEEDED_GATING}packets "
    NOVER=$((NOVER+1))
  else
    say packets OK "$NPKT packet(s) in flight, ceiling $CEILING_PACKETS (enforced: gate)"
    NOK=$((NOK+1))
  fi
fi

# --- commits: at most two per packet, against the packet's DECLARED base -------
# The base is self-declared by the same agent this dimension constrains, which is
# a real weakness and is named in the registry entry. What is checkable is that
# the declaration resolves: the sha must exist in this repository AND be an
# ancestor of HEAD. Anything else is UNOBSERVABLE — never a guess, and never a
# fallback to some other base, because a count against the wrong base is worse
# than no count.
commits_dim(){
  local base n
  if [ ! -f "$PACKET" ]; then
    say commits UNOBSERVABLE "no active-packet artefact, so no branch base is declared (advisory: advise)"
    NUNOBS=$((NUNOBS+1)); return
  fi
  base="$(awk '/^## Branch base/{f=1;next} /^## /{f=0} f' "$PACKET" \
          | grep -oE 'at `[0-9a-f]{7,40}`' | head -1 | tr -d '`' | sed 's/^at //')"
  if [ -z "$base" ]; then
    say commits UNOBSERVABLE "the packet declares no branch base in the form: at \`<sha>\` (advisory: advise)"
    NUNOBS=$((NUNOBS+1)); return
  fi
  if ! git -C "$REPO" rev-parse -q --verify "$base^{commit}" >/dev/null 2>&1; then
    say commits UNOBSERVABLE "the declared branch base $base is not a commit in this repository (advisory: advise)"
    NUNOBS=$((NUNOBS+1)); return
  fi
  if ! git -C "$REPO" merge-base --is-ancestor "$base" HEAD >/dev/null 2>&1; then
    say commits UNOBSERVABLE "the declared branch base $base is not an ancestor of HEAD, so no packet-local count exists (advisory: advise)"
    NUNOBS=$((NUNOBS+1)); return
  fi
  n="$(git -C "$REPO" rev-list --count "$base..HEAD" 2>/dev/null)"
  case "${n:-}" in ''|*[!0-9]*)
    say commits UNOBSERVABLE "git could not count commits between $base and HEAD (advisory: advise)"
    NUNOBS=$((NUNOBS+1)); return ;;
  esac
  if [ "$n" -gt "$CEILING_COMMITS" ]; then
    say commits EXCEEDED "$n commits since the declared base $base, ceiling $CEILING_COMMITS (advisory: advise — reported, not refused)"
    NOVER=$((NOVER+1))
  else
    say commits OK "$n commit(s) since the declared base $base, ceiling $CEILING_COMMITS (advisory: advise)"
    NOK=$((NOK+1))
  fi
}
commits_dim

# --- the two declined dimensions, stated where the operator reads the output ---
# Printed on every run ON PURPOSE. A dimension left silently out of the report is
# indistinguishable from a dimension that passed, and the whole claim of this
# tool is that it says which capacities it does NOT govern.
say write_sets DECLINED "observable from a fan-out manifest, but no ceiling on concurrent write sets is declared in the working contract; inventing one is the anti-pattern this design refuses"
NDECL=$((NDECL+1))
say depth DECLINED "serial agent stages are transcript-only; nothing in git attests to a round, so no limit is implemented and none is claimed"
NDECL=$((NDECL+1))

printf 'bandwidth: %s within ceiling, %s exceeded, %s unobservable, %s declined (dimensions evaluated independently; no composite)\n' \
  "$NOK" "$NOVER" "$NUNOBS" "$NDECL"

if [ -n "$EXCEEDED_GATING" ]; then
  printf 'bandwidth-check: REFUSED — %s: capacity exceeded. The dimension is named because a\ncomposite score would hide which one is saturated. This tool bounds work in flight\nONLY; it does not and cannot enforce the external-mutation rule, which lives in the\noperator permission system outside this repository.\n' \
    "${EXCEEDED_GATING% }" >&2
  exit 2
fi
exit 0
