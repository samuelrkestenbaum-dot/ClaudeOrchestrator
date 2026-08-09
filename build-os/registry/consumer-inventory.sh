#!/usr/bin/env bash
# CONSUMER INVENTORY for the positional `path:line` evidence format.
#
# WHY THIS EXISTS. The first anchor-migration attempt assumed one consumer of
# the format and shipped after updating it. There were fourteen. The registry
# converted cleanly, scan-controls.sh understood the new form, and
# control_registry_tests.sh — which carries its OWN independent parser — reported
# 712 unresolvable references. The migration was reverted.
#
# So the blast radius is no longer estimated. It is DERIVED from the tree on
# every run, and the migration is gated on this inventory being complete.
#
# COMPLETENESS IS TESTED, NOT ASSERTED. A detector nobody can see failing is a
# detector that has already stopped working, so tests/anchor_consumer_tests.sh
# plants a synthetic consumer and requires this script to find it. If the
# detection patterns rot, that test goes red rather than the inventory quietly
# shrinking — which is exactly how the first attempt's blind spot survived.
#
# Usage: consumer-inventory.sh [--repo DIR] [--tsv] [--strict]
set -uo pipefail

REPO="."; MODE="human"; STRICT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --tsv) MODE="tsv"; shift ;;
    --strict) STRICT=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done
cd "$REPO" || { echo "no such repo: $REPO" >&2; exit 2; }

# A file DECODES the format if it takes a ref apart positionally. These are the
# shapes actually found in this tree; each is a way of saying "the part after
# the colon is a line number".
DECODE_RE='\$\{[A-Za-z_]+%:\*\}|\$\{[A-Za-z_]+##\*:\}|cut -d: -f|:\[0-9\]|\(\.\*\):\(\[0-9\]|sub\(/:\[0-9\]|split\([^)]*":"|FS="?:"?|:\$\{?[A-Za-z_]*line'

# A file is only a CANDIDATE if it also touches the evidence/registry domain.
# Splitting on a colon is common; splitting a CITATION on a colon is the thing.
DOMAIN_RE='evidence_refs|control_registry|mutator_registry|VACUOUS|allrefs|evid|citation'

# CONFIRMED vs CANDIDATE, because the first inventory over-reported and the
# count was stated as fact. DOMAIN_RE is deliberately loose so nothing is
# missed — but `evid` also matches `evidence_axis`, and four files that merely
# split config pairs or a compiler location were counted as citation consumers.
# None of them reads evidence_refs at all.
#
# The loose net is KEPT, because a false negative is what reverted attempt 1
# and a false positive only costs a review. What changes is that the two are no
# longer added together: CONFIRMED files actually handle a citation field,
# CANDIDATE files matched heuristically and are carried for review.
CONFIRM_RE='evidence_refs|allrefs|VACUOUS-REF|ANCHOR-|#c:'

classify(){ # <file> — what KIND of consumer, so an update plan can be ordered
  local f="$1"
  case "$f" in
    */migrate-anchors.mjs|*/anchor-resolve.mjs) echo "migration_tool"; return ;;
    */scan-*.sh)                                echo "registry_scanner"; return ;;
    tests/*)                                    echo "suite_assertion"; return ;;
  esac
  grep -qE 'report|render|MISMATCHES|coverage' "$f" 2>/dev/null && { echo "report_generator"; return; }
  grep -qE 'registry\.txt' "$f" 2>/dev/null && { echo "registry_reader"; return; }
  echo "parser"
}

FOUND=0; UNCLASSIFIED=0; CONFIRMED=0; CANDIDATE=0
[ "$MODE" = "tsv" ] && printf 'file\tkind\tconfirmed\tdecode_hits\tdomain_hits\n'
[ "$MODE" = "human" ] && echo "CONSUMERS of the positional path:line evidence format"

# SELF-EXCLUSION, by EXACT PATH and nothing wider. This script necessarily
# contains the patterns it searches for, so it matches itself — the same
# self-matching shape that made a process guard spin for 72 minutes earlier in
# this work. Excluding by exact path cannot hide any other consumer; excluding
# by pattern could.
SELF_PATH="build-os/registry/consumer-inventory.sh"

while IFS= read -r f; do
  [ -f "$f" ] || continue
  [ "$f" = "$SELF_PATH" ] && continue
  grep -qE "$DOMAIN_RE" "$f" 2>/dev/null || continue
  dh="$(grep -cE "$DECODE_RE" "$f" 2>/dev/null || echo 0)"
  mh="$(grep -cE "$DOMAIN_RE" "$f" 2>/dev/null || echo 0)"
  k="$(classify "$f")"
  if grep -qE "$CONFIRM_RE" "$f" 2>/dev/null; then conf="CONFIRMED"; CONFIRMED=$((CONFIRMED+1))
  else conf="CANDIDATE"; CANDIDATE=$((CANDIDATE+1)); fi
  [ "$k" = "parser" ] && UNCLASSIFIED=$((UNCLASSIFIED+1))
  FOUND=$((FOUND+1))
  if [ "$MODE" = "tsv" ]; then printf '%s\t%s\t%s\t%s\t%s\n' "$f" "$k" "$conf" "$dh" "$mh"
  else printf '  %-9s %-14s %-52s decode=%s domain=%s\n' "$conf" "$k" "$f" "$dh" "$mh"; fi
done < <(grep -rlE "$DECODE_RE" --include="*.sh" --include="*.mjs" build-os tests 2>/dev/null | sort)

if [ "$MODE" = "human" ]; then
  echo
  echo "CONFIRMED consumers: $CONFIRMED   (handle a citation field)"
  echo "CANDIDATES:         $CANDIDATE   (heuristic match, carried for review — a false positive costs a review, a false negative reverted attempt 1)"
  echo "total scanned:      $FOUND"
  # An empty inventory is not "nothing to migrate" — it is a broken detector,
  # and the migration must not read it as a green light.
  [ "$FOUND" -eq 0 ] && echo "REFUSED: zero consumers found. The detector is broken, not the tree clean."
fi
# THE DATA SIDE, enumerated for the same reason as the code side. Attempt 1
# migrated control_registry.txt and nothing else, because "the registry" was
# assumed to be one file. It is four: control_registry, mutator_registry,
# defect_classes and findings all carry path:line citations. Phase 4 converts
# what this lists, not what anyone remembers.
if [ "$MODE" = "human" ]; then
  echo
  echo "CITATION-BEARING STORES"
  for st in build-os/registry/*.txt; do
    [ -f "$st" ] || continue
    n="$(grep -coE '[a-z0-9_/.-]+\.(sh|mjs|md|txt):[0-9]+' "$st" 2>/dev/null | head -n1)"
    [ "${n:-0}" -gt 0 ] 2>/dev/null && printf '  %-46s %4s positional citations\n' "$st" "$n"
  done
fi

[ "$FOUND" -eq 0 ] && exit 3
[ "$STRICT" = 1 ] && [ "$UNCLASSIFIED" -gt 0 ] && exit 4
exit 0
