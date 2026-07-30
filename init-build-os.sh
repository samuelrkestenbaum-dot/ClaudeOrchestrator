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
# SEEDS FROM templates/, NEVER FROM THIS REPO'S LIVE MEMORY. Every file below is
# copied out of `templates/build-os/**`, which mirrors the destination layout
# path-for-path and carries only contract text and empty starting values. The
# earlier version copied `build-os/memory/**` from this repo, which shipped this
# installation's own connector inventory and project narrative into every repo it
# scaffolded. `templates/` is the only source; `build-os/` is this repo's own
# state and is not a customer artifact.
#
# Usage: cd into the target repo, then run:  /path/to/ClaudeOrchestrator/init-build-os.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="$SRC/templates"
DEST="$(pwd)"

if [ "$SRC" = "$DEST" ]; then
  echo "Refusing to run inside the Build OS source repo itself ($SRC)."
  echo "cd into the project you want to scaffold, then run this script by path."
  exit 1
fi

echo "Build OS — scaffold build-os/ into: $DEST"
mkdir -p "$DEST/build-os/memory" "$DEST/build-os/packets" "$DEST/build-os/receipts"

# Never-clobber seeding. $rel is the path in the DESTINATION repo; the source is
# always "$TEMPLATES/$rel" (templates/ mirrors the destination layout), never a
# live file from this repo.
copy_if_absent() {
  local rel="$1"
  if [ -e "$DEST/$rel" ]; then
    echo "  = $rel (exists, skipped)"
  else
    if [ ! -f "$TEMPLATES/$rel" ]; then
      echo "  ! missing template: templates/$rel — refusing to seed from live memory." >&2
      exit 1
    fi
    cp "$TEMPLATES/$rel" "$DEST/$rel"
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
echo "     build-os/memory/tool_router.md ships with ZERO connector rows — add a row"
echo "     when you connect a tool. Worked example (fictional tools, never seeded):"
echo "     $TEMPLATES/build-os/memory/tool_router.example.md"
