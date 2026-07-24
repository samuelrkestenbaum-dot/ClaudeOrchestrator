#!/usr/bin/env bash
# Build OS — GLOBAL installer.
#
# Promotes the Build OS orchestrator from this repo into your USER scope
# (~/.claude), so the orchestrator + builder/reviewer/qa/archivist agents, the
# slash commands, the hooks, and the guidance are active in EVERY Claude Code
# session in EVERY project on this machine — no per-repo setup needed.
#
# Safe to re-run: it merges (never clobbers) settings.json and is idempotent on
# CLAUDE.md (guarded by markers).
#
# Usage:   ./install-global.sh
# Target override (for testing): CLAUDE_USER_DIR=/some/dir ./install-global.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${CLAUDE_USER_DIR:-$HOME/.claude}"

echo "Build OS — global install"
echo "  source: $SRC"
echo "  target: $DEST"

mkdir -p "$DEST/agents" "$DEST/commands" "$DEST/hooks"

# 1) Agents, 2) Commands, 3) Hooks
cp "$SRC/.claude/agents/"*.md       "$DEST/agents/"
cp "$SRC/.claude/commands/"*.md     "$DEST/commands/"
cp "$SRC/.claude/hooks/"*.sh        "$DEST/hooks/"
chmod +x "$DEST/hooks/"*.sh
echo "  + agents, commands, hooks copied"

# 4) Merge hooks into ~/.claude/settings.json — preserves other keys, idempotent.
python3 - "$DEST/settings.json" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}

hooks = data.setdefault("hooks", {})

def ensure(event, script):
    cmd = "$HOME/.claude/hooks/%s" % script
    groups = hooks.setdefault(event, [])
    for g in groups:
        for h in g.get("hooks", []):
            if str(h.get("command", "")).endswith(script):
                return  # already wired — leave as-is
    groups.append({"hooks": [{"type": "command", "command": cmd}]})

ensure("SessionStart", "session-start-build-os.sh")
ensure("UserPromptSubmit", "prompt-router.sh")

with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("  + settings.json hooks merged")
PY

# 5) Install Build OS guidance into ~/.claude/CLAUDE.md — managed block, REPLACED on
#    re-run (so stale guidance is refreshed, not skipped). Non-managed content is kept.
python3 - "$DEST/CLAUDE.md" "$SRC/build-os/global-claude-md.md" "install-global.sh" <<'PY'
import os, re, sys
claude_md, block_src, manager = sys.argv[1], sys.argv[2], sys.argv[3]
start = "<!-- BUILD-OS:START (managed by %s) -->" % manager
end = "<!-- BUILD-OS:END -->"
with open(block_src) as f:
    body = f.read().rstrip("\n")
managed = "%s\n%s\n%s" % (start, body, end)

existing = ""
if os.path.exists(claude_md):
    with open(claude_md) as f:
        existing = f.read()

# Strip ALL prior managed blocks (any manager tag), then re-append one fresh block.
had = "BUILD-OS:START" in existing
cleaned = re.sub(r"\n*<!-- BUILD-OS:START.*?-->.*?<!-- BUILD-OS:END -->\n*", "\n",
                 existing, flags=re.DOTALL).rstrip("\n")
new = (cleaned + "\n\n" + managed + "\n") if cleaned else (managed + "\n")
with open(claude_md, "w") as f:
    f.write(new)
print("  %s CLAUDE.md Build OS block" % ("~ replaced" if had else "+ added"))
PY

echo
echo "Done. Build OS is now active in every Claude Code session on this machine."
echo "Verify: start a fresh session — the first line reads 'Orchestrator: ON',"
echo "        and /agents lists build-orchestrator + builder/reviewer/qa/archivist."
echo
echo "Give a project persistent memory (run from inside that repo):"
echo "  $SRC/init-build-os.sh"
