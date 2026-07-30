#!/usr/bin/env bash
# Build OS — per-project initializer.
#
# Scaffolds the build-os/ memory directories into the CURRENT repo so the
# (globally-installed) orchestrator has per-project state to read and write:
#   build-os/memory/{tool_router,current_state,residue}.md
#   build-os/packets/active_packet.md
#   build-os/receipts/README.md
#
# Idempotent: never overwrites a file that already exists.
#
# Usage: cd into the target repo, then run:  /path/to/ClaudeOrchestrator/init-build-os.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$(pwd)"

if [ "$SRC" = "$DEST" ]; then
  echo "Refusing to run inside the Build OS source repo itself ($SRC)."
  echo "cd into the project you want to scaffold, then run this script by path."
  exit 1
fi

echo "Build OS — scaffold build-os/ into: $DEST"
mkdir -p "$DEST/build-os/memory" "$DEST/build-os/packets" "$DEST/build-os/receipts"

copy_if_absent() {
  local rel="$1"
  if [ -e "$DEST/$rel" ]; then
    echo "  = $rel (exists, skipped)"
  else
    cp "$SRC/$rel" "$DEST/$rel"
    echo "  + $rel"
  fi
}

copy_if_absent "build-os/memory/tool_router.md"
copy_if_absent "build-os/memory/current_state.md"
copy_if_absent "build-os/memory/residue.md"
copy_if_absent "build-os/packets/active_packet.md"
copy_if_absent "build-os/receipts/README.md"

# Memory maintenance + safety layer (rotation, tripwire, sanctioned test
# wrapper, standing-gates template). Managed files are replaced on every run;
# build-os/memory/standing_gates.md is seeded only if absent.
"$SRC/build-os/maintenance/install-maintenance.sh" "$DEST"

echo "Done. The orchestrator will read/write build-os/ in this repo."
echo "Tip: fill in build-os/memory/current_state.md with this project's basics."
