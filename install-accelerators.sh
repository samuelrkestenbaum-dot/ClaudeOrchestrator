#!/usr/bin/env bash
# Build OS — accelerator auto-provisioner (P-004).
# Idempotent, non-fatal, fast-skip-if-present. Reconstitutes the persistent LOCAL
# accelerators so a fresh session in THIS ephemeral environment has them available
# (durability across container-recycle = this committed script, run from SessionStart).
#
# Boundaries: installs PUBLIC packages only. No secrets, OAuth, DDL, remote-DB
# writes, payments, flags, canaries, telemetry, deploys, merges, or external sends.
# Intentionally NOT auto-installed here:
#   - Trail of Bits skills  -> official install is the interactive /plugin marketplace (CC BY-SA 4.0)
#   - Claude HUD            -> interactive /plugin + TTY statusline (renders only in an interactive session)
#   - Context Mode          -> PILOT only; installed manually, NOT wired into .mcp.json (routing disabled)
#   - GitHub Action templates -> repo-scoped; need a named target repo + separately approved secret
set -uo pipefail
log(){ printf '[accelerators] %s\n' "$*"; }

# 1) Serena (semantic-code MCP) — official oraios/serena, pinned. No API key; local LSP.
if command -v serena >/dev/null 2>&1; then
  log "serena present: $(serena --version 2>&1 | head -1)"
elif command -v uv >/dev/null 2>&1; then
  log "installing serena-agent==1.6.1 (uv tool) ..."
  uv tool install -p 3.13 'serena-agent==1.6.1' >/dev/null 2>&1 \
    && log "serena installed" \
    || log "serena install failed (non-fatal; committed .mcp.json still bootstraps it via uvx)"
else
  log "uv not found — committed .mcp.json bootstraps serena via uvx on MCP launch"
fi

# 2) Repomix + ccusage (CLIs) — pinned official npm packages.
if command -v npm >/dev/null 2>&1; then
  if command -v repomix >/dev/null 2>&1; then log "repomix present: $(repomix --version 2>&1 | head -1)"
  else log "installing repomix@1.17.0 ..."; npm install -g repomix@1.17.0 >/dev/null 2>&1 \
    && log "repomix installed" || log "repomix install failed (non-fatal; npx fallback works)"; fi
  if command -v ccusage >/dev/null 2>&1; then log "ccusage present: $(ccusage --version 2>&1 | head -1)"
  else log "installing ccusage@20.0.18 ..."; npm install -g ccusage@20.0.18 >/dev/null 2>&1 \
    && log "ccusage installed" || log "ccusage install failed (non-fatal; npx fallback works)"; fi
else
  log "npm not found — repomix/ccusage available via npx on demand"
fi

log "provisioning complete"
exit 0
