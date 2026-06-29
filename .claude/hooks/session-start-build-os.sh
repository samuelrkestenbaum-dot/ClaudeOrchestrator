#!/usr/bin/env bash
# Build OS — SessionStart hook.
# Reminds the session to route through build-orchestrator and surfaces the
# current Build OS memory + active packet as context.
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

echo "Orchestrator: ON — Build OS wired. Reminder: invoke the build-orchestrator subagent PROACTIVELY before any build packet (architecture, next steps, tool routing, \"keep going\"). It will announce its routing line 'Orchestrator: ON — routing from <file|embedded>' when it runs."
echo

echo "=== build-os/memory ==="
shopt -s nullglob 2>/dev/null || true
mem_found=0
for f in "$ROOT"/build-os/memory/*.md; do
  [ -e "$f" ] || continue
  mem_found=1
  echo "----- ${f#$ROOT/} -----"
  cat "$f"
  echo
done
[ "$mem_found" -eq 0 ] && echo "(no build-os/memory/*.md found)"

echo "=== active packet ==="
if [ -f "$ROOT/build-os/packets/active_packet.md" ]; then
  cat "$ROOT/build-os/packets/active_packet.md"
else
  echo "(no build-os/packets/active_packet.md found)"
fi

exit 0
