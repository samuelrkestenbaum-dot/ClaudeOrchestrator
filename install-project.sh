#!/usr/bin/env bash
# Build OS — PROJECT-scope installer.
#
# Installs the Build OS engine (agents, commands, hooks, CLAUDE.md guidance) and
# scaffolds build-os/ memory into a TARGET project repo. Unlike install-global.sh
# (which writes ~/.claude), this writes the target repo's own .claude/ + build-os/
# so the setup travels with the repo and is picked up in every session — web,
# remote, or local — at clone time, with no hot-load timing dependency.
#
# Usage:
#   ./install-project.sh [TARGET_DIR]          # default: current directory
#   ./install-project.sh --no-session-hook DIR # don't register SessionStart
#                                              # (used by the bootstrap hook,
#                                              #  which IS the SessionStart hook)
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REGISTER_SESSION_HOOK=1
if [ "${1:-}" = "--no-session-hook" ]; then
  REGISTER_SESSION_HOOK=0
  shift
fi

DEST="${1:-$(pwd)}"
DEST="$(cd "$DEST" && pwd)"

if [ "$SRC" = "$DEST" ]; then
  echo "Target is the Build OS source repo itself; nothing to do."
  exit 0
fi

echo "Build OS — install into project: $DEST"
mkdir -p "$DEST/.claude/agents" "$DEST/.claude/commands" "$DEST/.claude/hooks" \
         "$DEST/build-os/memory" "$DEST/build-os/packets" "$DEST/build-os/receipts"

# Engine: agents, commands, hooks
cp "$SRC/.claude/agents/"*.md   "$DEST/.claude/agents/"
cp "$SRC/.claude/commands/"*.md "$DEST/.claude/commands/"
cp "$SRC/.claude/hooks/session-start-build-os.sh" "$SRC/.claude/hooks/prompt-router.sh" "$DEST/.claude/hooks/"
chmod +x "$DEST/.claude/hooks/"*.sh
echo "  + agents, commands, hooks"

# Memory scaffold — never overwrite existing project state
for rel in build-os/memory/tool_router.md build-os/memory/current_state.md \
           build-os/memory/residue.md build-os/packets/active_packet.md \
           build-os/receipts/README.md; do
  if [ -e "$DEST/$rel" ]; then echo "  = $rel (exists, kept)"; else cp "$SRC/$rel" "$DEST/$rel"; echo "  + $rel"; fi
done

# Merge .claude/settings.json hooks (project scope → $CLAUDE_PROJECT_DIR paths)
python3 - "$DEST/.claude/settings.json" "$REGISTER_SESSION_HOOK" <<'PY'
import json, sys
path, register_session = sys.argv[1], sys.argv[2] == "1"
try:
    with open(path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}
hooks = data.setdefault("hooks", {})

def ensure(event, script):
    cmd = "$CLAUDE_PROJECT_DIR/.claude/hooks/%s" % script
    groups = hooks.setdefault(event, [])
    for g in groups:
        for h in g.get("hooks", []):
            if str(h.get("command", "")).endswith(script):
                return
    groups.append({"hooks": [{"type": "command", "command": cmd}]})

if register_session:
    ensure("SessionStart", "session-start-build-os.sh")
ensure("UserPromptSubmit", "prompt-router.sh")

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("  + .claude/settings.json hooks merged (session-hook=%s)" % register_session)
PY

# CLAUDE.md guidance — guarded, idempotent
CLAUDE_MD="$DEST/CLAUDE.md"
MARK_START="<!-- BUILD-OS:START (managed by install-project.sh) -->"
MARK_END="<!-- BUILD-OS:END -->"
if [ -f "$CLAUDE_MD" ] && grep -qF "$MARK_START" "$CLAUDE_MD"; then
  echo "  = CLAUDE.md already has the Build OS block — skipped"
else
  { echo ""; echo "$MARK_START"; cat "$SRC/build-os/global-claude-md.md"; echo "$MARK_END"; } >> "$CLAUDE_MD"
  echo "  + CLAUDE.md guidance appended"
fi

echo "Done. Commit .claude/ + build-os/ (+ CLAUDE.md) to this repo to make it permanent."
