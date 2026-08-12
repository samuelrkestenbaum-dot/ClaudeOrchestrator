#!/usr/bin/env bash
# R0.1 §3 — target-repo hygiene. snapshot: record root-level dot entries
# before a run. sweep: any NEW root dot entry that is not Gravito-managed is
# INCIDENTAL TOOL RESIDUE — moved (reversibly) to build-os/residue/<ts>/ with
# a receipt. Product artifacts (non-dot files anywhere, and everything the
# goal names) are never touched; PRE-EXISTING entries are never touched.
set -euo pipefail
MODE="$1"; D="$2"
MANAGED=".claude .git gravito.goal"
case "$MODE" in
  snapshot)
    ( cd "$D" && ls -A | grep '^\.' | sort ) ;;
  sweep)
    SNAP="$3"; TS="$(date -u +%Y%m%dT%H%M%SZ)"
    moved=0
    while read -r e; do
      [ -n "$e" ] || continue
      grep -qxF "$e" "$SNAP" && continue                      # pre-existing: never touch
      case " $MANAGED " in *" $e "*) continue ;; esac         # managed: leave
      mkdir -p "$D/build-os/residue/$TS"
      mv "$D/$e" "$D/build-os/residue/$TS/$e"
      printf '%s moved %s -> build-os/residue/%s/%s (restore: mv back)\n' "$(date -u +%FT%TZ)" "$e" "$TS" "$e" >> "$D/build-os/receipts/residue.log"
      moved=$((moved+1))
    done < <( cd "$D" && ls -A | grep '^\.' | sort )
    echo "residue-sweep: $moved incidental entr(ies) isolated (receipt: build-os/receipts/residue.log)" ;;
  *) echo "usage: residue-sweep.sh snapshot|sweep <repo> [snapfile]"; exit 2 ;;
esac
