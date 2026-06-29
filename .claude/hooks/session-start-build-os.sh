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

echo
echo "=== MCP servers (configured) ==="
# Best-effort: enumerate MCP servers from config so the orchestrator can route to
# connected tools. Never fail the session over this.
if command -v python3 >/dev/null 2>&1; then
  python3 - "$ROOT" "$HOME" <<'PY' 2>/dev/null || echo "(MCP detection skipped)"
import json, os, sys
root, home = sys.argv[1], sys.argv[2]
cands = [
    os.path.join(root, ".mcp.json"),
    os.path.join(home, ".claude.json"),
    os.path.join(home, ".claude", "settings.json"),
    os.path.join(home, ".claude", "settings.local.json"),
    os.path.join(root, ".claude", "settings.json"),
    os.path.join(root, ".claude", "settings.local.json"),
]
servers = set()
def collect(d):
    if not isinstance(d, dict):
        return
    ms = d.get("mcpServers")
    if isinstance(ms, dict):
        servers.update(ms.keys())
    # ~/.claude.json often nests servers under projects.<path>.mcpServers
    projs = d.get("projects")
    if isinstance(projs, dict):
        for v in projs.values():
            if isinstance(v, dict) and isinstance(v.get("mcpServers"), dict):
                servers.update(v["mcpServers"].keys())
for p in cands:
    try:
        with open(p) as f:
            collect(json.load(f))
    except Exception:
        continue
print(", ".join(sorted(servers)) if servers
      else "(none in config — in-session mcp__<server>__* tools may still be available)")
PY
else
  echo "(python3 unavailable — skipping MCP detection)"
fi

exit 0
