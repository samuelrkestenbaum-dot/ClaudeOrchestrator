#!/usr/bin/env bash
# Build OS — bootstrap SessionStart hook (committed into a TARGET project).
#
# On session start it fetches the ClaudeOrchestrator repo and installs the Build
# OS engine into THIS project, then prints the orchestrator reminder + memory.
# This is what makes "add repo -> start a web session -> Build OS is installed"
# work without vendoring the engine into the repo.
#
# Tune via env:
#   BUILD_OS_REPO   git URL of ClaudeOrchestrator (default below)
#   BUILD_OS_REF    branch/tag to use (default: the repo default branch)
# Note: 'set -e' is intentionally NOT used — a bootstrap failure must never block
# the session from starting.
set -uo pipefail

# Web/remote only. Remove this gate to also bootstrap local sessions
# (locally, prefer install-global.sh once instead).
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO_URL="${BUILD_OS_REPO:-https://github.com/samuelrkestenbaum-dot/ClaudeOrchestrator.git}"
REF="${BUILD_OS_REF:-}"
CACHE="${HOME}/.cache/claude-orchestrator"
PROJ="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Fetch or update the cached clone.
if [ -d "$CACHE/.git" ]; then
  git -C "$CACHE" fetch -q origin 2>/dev/null || true
  git -C "$CACHE" pull --ff-only -q 2>/dev/null || true
else
  if ! git clone --depth 1 ${REF:+--branch "$REF"} -q "$REPO_URL" "$CACHE" 2>/dev/null; then
    echo "Build OS bootstrap: could not fetch $REPO_URL — skipping (session continues)."
    exit 0
  fi
fi

# Install the engine into this project (the bootstrap IS the SessionStart hook,
# so tell the installer not to register a second SessionStart entry).
if [ -x "$CACHE/install-project.sh" ]; then
  "$CACHE/install-project.sh" --no-session-hook "$PROJ" >/dev/null 2>&1 \
    || echo "Build OS bootstrap: install-project step reported an issue."
fi

# Emit the orchestrator reminder + memory (reuse the installed reminder hook).
if [ -x "$PROJ/.claude/hooks/session-start-build-os.sh" ]; then
  CLAUDE_PROJECT_DIR="$PROJ" "$PROJ/.claude/hooks/session-start-build-os.sh"
else
  echo "Orchestrator: ON — Build OS bootstrapped from ClaudeOrchestrator."
fi

exit 0
