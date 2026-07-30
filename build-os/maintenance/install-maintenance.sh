#!/usr/bin/env bash
# GRAVITO:MANAGED — shipped by build-os/maintenance/install-maintenance.sh.
# This script installs ITSELF: it is on the managed list below, so in an
# installed repo it is replaced on the next install like everything else there.
# Change it upstream, or unmanage it by removing the path from .gravito-managed.
#
# Gravito — installer for the Build OS memory maintenance + safety layer.
#
#   build-os/maintenance/install-maintenance.sh [TARGET_DIR]   # default: cwd
#
# Called by install-project.sh and init-build-os.sh; safe to run directly, and
# safe to run repeatedly. It is the ONLY thing that writes this layer, so the
# managed/customer split below is the whole ownership boundary.
#
# ---------------------------------------------------------------------------
# THE TWO CLASSES OF FILE, AND THE RULE FOR EACH
# ---------------------------------------------------------------------------
#   MANAGED  — replaced on every run, byte-for-byte from this repo. Each carries
#              a Gravito marker in whatever its own syntax allows: a
#              GRAVITO:MANAGED comment in the scripts, modules and PORTING.md; a
#              top-level "GRAVITO" key in rootscan-controls.json, which is JSON
#              and has no comments; and GRAVITO:TEMPLATE in
#              templates/standing_gates.md, because the file it SEEDS is yours
#              even though the template itself is managed. Editing a managed file
#              in place is pointless: the next install overwrites it. The full
#              list is written to build-os/maintenance/.gravito-managed so an
#              uninstall is exact.
#   CUSTOMER — written ONLY IF ABSENT, never touched again. Yours.
#
# NOTHING ELSE IS WRITTEN. In particular this script never touches
# build-os/memory/{current_state,residue}.md, build-os/packets/active_packet.md,
# CLAUDE.md, or anything under build-os/receipts/.
#
# ---------------------------------------------------------------------------
# WHAT IT DOES TO .gitignore AND package.json, AND WHY EACH IS CONDITIONAL
# ---------------------------------------------------------------------------
#   .gitignore   : appends ONE marked line un-ignoring build-os/memory/archive/,
#                  and only when no line already un-ignores it. The archive is
#                  where rotated content goes; a repo with a blanket `archive/`
#                  rule would otherwise hide the only copy of it from git.
#   package.json : adds `test:build-os-memory` ONLY IF a package.json already
#                  exists. This layer installs into any git repo, and creating a
#                  Node manifest in a repo that has none would be an opinion
#                  about the project, not an installation.
#
# Idempotent by construction: a second run over an unchanged tree produces a
# byte-identical tree. That is proven, not asserted — see
# tests/build_os_maintenance_tests.sh.
set -euo pipefail

SRC_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:-$(pwd)}"
DEST="$(cd -- "${DEST}" && pwd)"

if [ "${SRC_DIR}" = "${DEST}/build-os/maintenance" ]; then
  echo "  = build-os/maintenance (this IS the source; nothing to do)"
  exit 0
fi

# The managed set, repo-relative. Order is fixed so .gravito-managed is stable.
MANAGED=(
  "build-os/maintenance/rotate-memory.mjs"
  "build-os/maintenance/rotate-memory.sh"
  "build-os/maintenance/run-tests.sh"
  "build-os/maintenance/real-memory-tripwire.mjs"
  "build-os/maintenance/source-scan.mjs"
  "build-os/maintenance/rotate-memory.test.mjs"
  "build-os/maintenance/rotate-memory.rootscan.test.mjs"
  "build-os/maintenance/rootscan-controls.json"
  "build-os/maintenance/install-maintenance.sh"
  "build-os/maintenance/templates/standing_gates.md"
  "build-os/maintenance/PORTING.md"
)

mkdir -p "${DEST}/build-os/maintenance/templates" \
         "${DEST}/build-os/memory" "${DEST}/build-os/packets"

for rel in "${MANAGED[@]}"; do
  cp "${SRC_DIR}/../../${rel}" "${DEST}/${rel}"
done
chmod +x "${DEST}/build-os/maintenance/rotate-memory.sh" \
         "${DEST}/build-os/maintenance/run-tests.sh" \
         "${DEST}/build-os/maintenance/install-maintenance.sh"
echo "  + build-os/maintenance/ (${#MANAGED[@]} managed files)"

# The uninstall manifest. Written last of the managed writes so it always
# describes what is actually on disk.
{
  echo "# GRAVITO:MANAGED — files this layer owns and replaces on every install."
  echo "# Uninstall = delete every path below. Nothing else is removed;"
  echo "# build-os/memory/** (including standing_gates.md and archive/) is YOURS."
  printf '%s\n' "${MANAGED[@]}"
  echo "build-os/maintenance/.gravito-managed"
} > "${DEST}/build-os/maintenance/.gravito-managed"

# ---- CUSTOMER FILE: seeded from the template, then never touched -------------
if [ -e "${DEST}/build-os/memory/standing_gates.md" ]; then
  echo "  = build-os/memory/standing_gates.md (exists, kept)"
else
  cp "${SRC_DIR}/../../build-os/maintenance/templates/standing_gates.md" \
     "${DEST}/build-os/memory/standing_gates.md"
  echo "  + build-os/memory/standing_gates.md (from template)"
fi

# ---- .gitignore: one marked line, only if the archive is not already visible --
GI="${DEST}/.gitignore"
GI_LINE='!build-os/memory/archive/'
if [ -f "${GI}" ] && grep -qxF "${GI_LINE}" "${GI}"; then
  echo "  = .gitignore (archive exception already present)"
else
  # a file that does not end in a newline would otherwise glue onto our comment
  if [ -s "${GI}" ] && [ "$(tail -c 1 "${GI}")" != "" ]; then printf '\n' >> "${GI}"; fi
  {
    echo ""
    echo "# GRAVITO:MANAGED — rotated Build OS memory must stay visible to git."
    echo "# build-os/memory/archive/ holds the ONLY copy of anything rotated out of"
    echo "# the live memory files. A blanket \`archive/\` rule would hide it."
    echo "${GI_LINE}"
  } >> "${GI}"
  echo "  + .gitignore (archive exception)"
fi

# ---- package.json: only where one already exists ----------------------------
PKG="${DEST}/package.json"
if [ ! -f "${PKG}" ]; then
  echo "  = package.json (none; skipping the npm signpost — run ./build-os/maintenance/run-tests.sh)"
elif ! command -v python3 >/dev/null 2>&1; then
  echo "  ! package.json present but python3 is not; add this yourself:" >&2
  echo "      \"test:build-os-memory\": \"./build-os/maintenance/run-tests.sh\"" >&2
else
  python3 - "${PKG}" <<'PY'
import json, sys
path = sys.argv[1]
want = "./build-os/maintenance/run-tests.sh"
with open(path) as f:
    raw = f.read()
data = json.loads(raw)
scripts = data.setdefault("scripts", {})
if scripts.get("test:build-os-memory") == want:
    print("  = package.json (test:build-os-memory already exact)")
    sys.exit(0)
scripts["test:build-os-memory"] = want
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("  + package.json (test:build-os-memory)")
PY
fi

echo "  Done. Dry-run the rotation with: ./build-os/maintenance/rotate-memory.sh"
