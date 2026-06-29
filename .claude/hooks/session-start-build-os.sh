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
echo "=== Available capabilities (Claude Code) ==="
# Best-effort inventory of what is ALREADY connected so the orchestrator routes to
# whatever exists — MCP servers, skills, slash commands, subagents — across user,
# project, and plugin scopes. Never fail the session over this.
if command -v python3 >/dev/null 2>&1; then
  python3 - "$ROOT" "$HOME" <<'PY' 2>/dev/null || echo "(capability detection skipped)"
import json, os, sys, glob
root, home = sys.argv[1], sys.argv[2]
claude = os.path.join(home, ".claude")
plug = os.path.join(claude, "plugins")

def cap(names, n=50):
    names = sorted(set(n for n in names if n))
    if not names:
        return None
    if len(names) <= n:
        return ", ".join(names)
    return ", ".join(names[:n]) + " … (+%d more)" % (len(names) - n)

# MCP servers — config files (incl. projects.<path>.mcpServers nesting)
servers = set()
def collect(d):
    if not isinstance(d, dict):
        return
    if isinstance(d.get("mcpServers"), dict):
        servers.update(d["mcpServers"].keys())
    projs = d.get("projects")
    if isinstance(projs, dict):
        for v in projs.values():
            if isinstance(v, dict) and isinstance(v.get("mcpServers"), dict):
                servers.update(v["mcpServers"].keys())
for p in [os.path.join(root, ".mcp.json"), os.path.join(home, ".claude.json"),
          os.path.join(claude, "settings.json"), os.path.join(claude, "settings.local.json"),
          os.path.join(root, ".claude", "settings.json"), os.path.join(root, ".claude", "settings.local.json")]:
    try:
        with open(p) as f:
            collect(json.load(f))
    except Exception:
        continue

# Skills — directories (user, project, plugins/**)
skill_roots = [os.path.join(claude, "skills"), os.path.join(root, ".claude", "skills")]
skill_roots += glob.glob(os.path.join(plug, "**", "skills"), recursive=True)
skills = []
for r in skill_roots:
    if os.path.isdir(r):
        skills += [d for d in os.listdir(r) if os.path.isdir(os.path.join(r, d))]

# Slash commands & subagents — *.md (user, project, plugins/**)
def md_items(roots):
    out = []
    for r in roots:
        out += [os.path.splitext(os.path.basename(p))[0] for p in glob.glob(os.path.join(r, "*.md"))]
    return out
cmd_roots = [os.path.join(claude, "commands"), os.path.join(root, ".claude", "commands")] + glob.glob(os.path.join(plug, "**", "commands"), recursive=True)
agent_roots = [os.path.join(claude, "agents"), os.path.join(root, ".claude", "agents")] + glob.glob(os.path.join(plug, "**", "agents"), recursive=True)

print("MCP servers: " + (cap(servers) or "(none in config — mcp__<server>__* tools may still be live in-session)"))
print("Skills:      " + (cap(skills) or "(none found in skill dirs)"))
print("Commands:    " + (cap(md_items(cmd_roots)) or "(none found)"))
print("Subagents:   " + (cap(md_items(agent_roots)) or "(none found)"))
print("(Summary — orchestrator: glob these dirs / call mcp__* tools for the full set when routing.)")
PY
else
  echo "(python3 unavailable — skipping capability detection)"
fi

exit 0
