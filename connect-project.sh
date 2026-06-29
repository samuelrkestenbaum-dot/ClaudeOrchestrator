#!/usr/bin/env bash
# Build OS — connect a TARGET project to ClaudeOrchestrator.
#
# Drops a tiny bootstrap into the target repo so that every Claude Code web /
# remote session on that repo auto-installs the Build OS engine (pulled from
# the ClaudeOrchestrator GitHub repo) at session start. Only TWO small files are
# added to the target repo:
#   .claude/hooks/session-start.sh   (the bootstrap)
#   .claude/settings.json            (SessionStart -> the bootstrap; merged)
#
# Commit + push those to the repo's default branch and you're done — no engine
# files are vendored; the orchestrator is pulled centrally and stays updatable.
#
# Usage: cd into the target repo, then run by path:
#   /path/to/ClaudeOrchestrator/connect-project.sh
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${1:-$(pwd)}"
DEST="$(cd "$DEST" && pwd)"

if [ "$SRC" = "$DEST" ]; then
  echo "Refusing to connect the Build OS source repo to itself."
  echo "cd into the project you want to connect, then run this script by path."
  exit 1
fi

echo "Build OS — connect project: $DEST"
mkdir -p "$DEST/.claude/hooks"

cp "$SRC/templates/session-start-bootstrap.sh" "$DEST/.claude/hooks/session-start.sh"
chmod +x "$DEST/.claude/hooks/session-start.sh"
echo "  + .claude/hooks/session-start.sh (bootstrap)"

python3 - "$DEST/.claude/settings.json" <<'PY'
import json, sys
path = sys.argv[1]
try:
    with open(path) as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {}
hooks = data.setdefault("hooks", {})
groups = hooks.setdefault("SessionStart", [])
cmd = "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh"
already = any(str(h.get("command","")).endswith("session-start.sh")
              for g in groups for h in g.get("hooks", []))
if not already:
    groups.append({"hooks":[{"type":"command","command":cmd}]})
with open(path, "w") as f:
    json.dump(data, f, indent=2); f.write("\n")
print("  + .claude/settings.json (SessionStart -> bootstrap, merged)")
PY

cat <<EOF

Connected. Next steps in this repo:
  git add .claude/hooks/session-start.sh .claude/settings.json
  git commit -m "Connect Build OS (ClaudeOrchestrator) bootstrap"
  git push

Once that's on the repo's default branch, every future web/remote session
auto-installs the Build OS. (On-demand anytime: ask Claude to "install the
Build OS", or run install-project.sh from a clone of ClaudeOrchestrator.)
EOF
