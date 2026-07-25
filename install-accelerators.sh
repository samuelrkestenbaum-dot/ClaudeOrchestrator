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

# register_pinned_serena — ADD-IF-ABSENT registration of the pinned Serena MCP into the
# surface's user config (CLAUDE_CONFIG_PATH, default ~/.claude.json). This closes the
# "installed-but-not-registered" gap on a surface (e.g. a fresh Claude Cloud task) whose
# ~/.claude.json has no Serena entry, WITHOUT ever creating a duplicate: if a serena entry
# already exists (e.g. the Mac's user-scope server), it is left byte-untouched — honoring the
# canonical single-server rule (P-008). No secret required (Serena needs no API key); we never
# touch project .mcp.json (which stays serena-free so nothing double-launches). Non-fatal.
register_pinned_serena() {
  local cfg="${CLAUDE_CONFIG_PATH:-$HOME/.claude.json}" out
  command -v python3 >/dev/null 2>&1 || { log "python3 absent — Serena MCP registration skipped"; return 0; }
  out="$(python3 - "$cfg" <<'PY' 2>/dev/null
import json, os, sys
cfg = sys.argv[1]
PIN = "68884f1190489685082dc3c3b56917e92a1de0e6"
try:
    with open(cfg) as f:
        data = json.load(f)
    if not isinstance(data, dict):
        data = {}
except (FileNotFoundError, json.JSONDecodeError):
    data = {}
servers = data.setdefault("mcpServers", {})
if not isinstance(servers, dict):
    print("skipped (mcpServers is not an object)"); raise SystemExit(0)
if "serena" in servers:
    print("already present — left untouched (single-server rule)"); raise SystemExit(0)
servers["serena"] = {
    "command": "uvx",
    "args": ["--from", "git+https://github.com/oraios/serena@%s" % PIN,
             "serena", "start-mcp-server", "--context", "claude-code", "--project-from-cwd"],
    "env": {},
}
d = os.path.dirname(cfg)
if d:
    os.makedirs(d, exist_ok=True)
tmp = cfg + ".build-os.tmp"
with open(tmp, "w") as f:
    json.dump(data, f, indent=2); f.write("\n")
os.replace(tmp, cfg)   # atomic; preserves every other key
print("registered pinned Serena (%s)" % PIN[:7])
PY
)" || { log "Serena MCP registration failed (non-fatal)"; return 0; }
  log "Serena MCP registration: ${out:-no-op}"
}

# Testable / targeted entrypoint: register only, no network installs.
if [ "${1:-}" = "register-serena" ]; then register_pinned_serena; exit 0; fi

# 1) Serena (semantic-code MCP) — official oraios/serena, commit-pinned. No API key; local LSP.
if command -v serena >/dev/null 2>&1; then
  log "serena present: $(serena --version 2>&1 | head -1)"
elif command -v uv >/dev/null 2>&1; then
  log "installing Serena at 68884f1190489685082dc3c3b56917e92a1de0e6 (uv tool) ..."
  uv tool install -p 3.13 --from \
    'git+https://github.com/oraios/serena@68884f1190489685082dc3c3b56917e92a1de0e6' \
    serena-agent >/dev/null 2>&1 \
    && log "serena installed" \
    || log "serena install failed (non-fatal; retry the pinned uv install)"
else
  log "uv not found — Serena project MCP remains unavailable until uv is installed"
fi

# 1b) Register the pinned Serena MCP into this surface's user config if (and only if) it is
#     not already registered — so a surface that has the binary but no mcpServers entry (e.g. a
#     fresh Claude Cloud task) gets a callable Serena, while a surface that already has one
#     (the Mac's user-scope server) is left untouched. Add-if-absent; never a duplicate.
register_pinned_serena

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
