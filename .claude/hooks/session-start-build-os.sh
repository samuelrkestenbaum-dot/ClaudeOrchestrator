#!/usr/bin/env bash
# Build OS — SessionStart hook.
# Reminds the session to route through build-orchestrator and surfaces a compact
# capability summary. Keep output small: oversized SessionStart payloads are
# discarded by Claude Code, which makes a healthy hook look broken.
set -uo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=hook-once.sh
source "$HOOK_DIR/hook-once.sh"
build_os_hook_once "SessionStart" || exit 0

# EXP-0009 / TOM Layer 3 v0 — ORGANIZATIONAL MEMORY, DELIVERED BY PUSH.
# If machine-distilled task records exist, they arrive inline (<=4KB) so the
# worker never hunts for them: variant B proved subtraction causes search, and
# memory that is discoverable-but-unannounced is subtraction wearing a memory
# costume. Above 4KB a one-line pointer with the entry count is emitted instead.
# The worker READS this; it never writes or administers it — the harness
# distills. That boundary is the experiment's TOM regression guard.
# PKT-R0-1 — NAMESPACE GUARD, default closed. Memory is emitted only when
# the project-identity stamp matches this repo (or is adopted now, with a
# receipt line). A store carried in from another project is QUARANTINED:
# named, never read.
_NS_VERDICT="MATCH"
if [ -r "$HOOK_DIR/project-identity.sh" ]; then
  # shellcheck source=project-identity.sh
  source "$HOOK_DIR/project-identity.sh"
  _NS_VERDICT="$(bosi_namespace_verdict "$ROOT")"
  case "$_NS_VERDICT" in
    ADOPTED)    echo "Namespace: existing build-os/memory ADOPTED into project $(bosi_project_id "$ROOT") (stamp written; receipt: this line)."; echo ;;
    QUARANTINE) echo "Namespace: QUARANTINE — build-os/memory carries another project's identity stamp. Memory will NOT be read this session. Resolve by moving that build-os/ back to its own repo, or by a human deleting build-os/memory/.project-identity to re-adopt."; echo ;;
  esac
fi

_MEMLOG="$ROOT/build-os/memory/task-log.md"
if [ "$_NS_VERDICT" != "QUARANTINE" ] && [ -f "$_MEMLOG" ]; then
  _MEMSZ=$(wc -c < "$_MEMLOG" 2>/dev/null || echo 0)
  if [ "$_MEMSZ" -le 4096 ]; then
    echo "Organizational memory — prior task records for this repository (machine-distilled; read-only for you):"
    cat "$_MEMLOG"
  else
    _MEMN=$(grep -c '^## ' "$_MEMLOG" 2>/dev/null || echo '?')
    echo "Organizational memory: $_MEMN prior task records at build-os/memory/task-log.md (read it before rediscovering)."
  fi
  echo
fi

# LEAN L4 — derived state FIRST, ceremony after. One line of resolved certainty
# for task workers: routing needs nothing from them, and the receipt state is
# stated rather than discoverable.
_OPEN_RECEIPT="none"
for _r in "$ROOT"/build-os/packets/routing/routing-*.md; do
  [ -f "$_r" ] && grep -q '^- \*\*executed_mode:\*\* -$' "$_r" 2>/dev/null && { _OPEN_RECEIPT="$(basename "$_r")"; break; }
done
echo "Task state: routing is AUTOMATIC (first edit opens a floor receipt; open receipt now: $_OPEN_RECEIPT). Workers on a routed task: your contract is the top section of CLAUDE.md; no lane, budget, or evidence ceremony is expected from you."
echo

echo "Orchestrator: ON — Build OS wired. Reminder: invoke the build-orchestrator subagent PROACTIVELY before any build packet (architecture, next steps, tool routing, \"keep going\"). It will announce its routing line 'Orchestrator: ON — routing from <file|embedded>' when it runs."
echo

# WHAT THIS COPY IS, AND UNDER WHAT LICENCE — exactly ONE line, every session.
# A session should never have to ask a human which version it is running or
# whether it is allowed to. The line also carries the verification verdict, so a
# copy whose engine files drifted from its own stamp says DRIFT here instead of
# quietly reporting a version it no longer is. One line, because a banner gets
# deleted by whoever has to read it every session.
if [ -r "$HOOK_DIR/build-os-identity.sh" ]; then
  # shellcheck source=build-os-identity.sh
  source "$HOOK_DIR/build-os-identity.sh"
  bosi_line "$(cd "$HOOK_DIR/.." 2>/dev/null && pwd)" "$ROOT/build-os" "${HOME:-/nonexistent}/build-os" 2>/dev/null \
    || echo "Build OS: identity check unavailable — licence: see LICENSE / docs/ENTITLEMENT.md"
  echo
fi

# Auto-provision persistent local accelerators (P-004): non-blocking, non-fatal,
# fast-skip-if-present. Serena/Repomix/ccusage only; no secrets/network egress
# beyond public package registries. Context Mode / Trail of Bits / Claude HUD /
# GitHub Actions are intentionally NOT auto-installed (see the script header).
if [ -x "$ROOT/install-accelerators.sh" ]; then
  ( "$ROOT/install-accelerators.sh" >/tmp/build-os-accelerators.log 2>&1 & ) 2>/dev/null || true
  echo "Accelerators: background auto-provision started (serena/repomix/ccusage) — log: /tmp/build-os-accelerators.log"
  echo
fi

echo "Memory: project build-os/memory → user ~/build-os/memory → embedded lanes."
if [ "$_NS_VERDICT" = "QUARANTINE" ]; then
  echo "Project memory QUARANTINED by the namespace guard — treat this session as memoryless for this repo."
elif [ -d "$ROOT/build-os/memory" ]; then
  echo "Project memory present; build-orchestrator reads current_state.md, residue.md, and tool_router.md on demand."
  # ROTATED MEMORY IS NOT THE WHOLE RECORD, AND THIS IS THE POINT WHERE THAT
  # HAS TO BE SAID. Before rotation an over-size memory file fails to Read and
  # the session KNOWS it is blind. After rotation the same file reads fine and
  # is SHORTER, so the session believes it has the whole record — the silent
  # failure rotate-memory.mjs's archive-pointer banner exists to prevent, one
  # level up: the banner is inside the file, but this line is what a session
  # sees BEFORE it decides which files to read. Announced ONLY when the archive
  # directory exists, so a repo that has never rotated emits exactly the bytes
  # it emitted before and no un-rotated install changes shape.
  if [ -d "$ROOT/build-os/memory/archive" ]; then
    echo "Memory has ROTATED: the live memory files are NOT the whole record. Blocks rotated out of them live in build-os/memory/archive/ (append-only). Resolve a citation into rotated content through build-os/memory/archive/INDEX.md, which maps each archived section to its archive file and line."
  fi
else
  echo "No project memory; use the user-scope router or embedded lanes."
fi

echo "=== active packet ==="
if [ -f "$ROOT/build-os/packets/active_packet.md" ]; then
  grep -m 1 '^- \*\*Status:\*\*' "$ROOT/build-os/packets/active_packet.md" || echo "(status not declared)"
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

def cap(names, n=12):
    names = sorted(set(x for x in names if x))
    if not names:
        return None
    if len(names) <= n:
        return ", ".join(names)
    return ", ".join(names[:n]) + " … (+%d more)" % (len(names) - n)

CONFIGS = [os.path.join(root, ".mcp.json"), os.path.join(home, ".claude.json"),
           os.path.join(claude, "settings.json"), os.path.join(claude, "settings.local.json"),
           os.path.join(root, ".claude", "settings.json"), os.path.join(root, ".claude", "settings.local.json")]

def load(p):
    try:
        with open(p) as f:
            return json.load(f)
    except Exception:
        return None
docs = [d for d in (load(p) for p in CONFIGS) if isinstance(d, dict)]

# MCP servers — from config (incl. projects.<path>.mcpServers nesting)
servers = set()
def collect_servers(d):
    if not isinstance(d, dict):
        return
    if isinstance(d.get("mcpServers"), dict):
        servers.update(d["mcpServers"].keys())
    projs = d.get("projects")
    if isinstance(projs, dict):
        for v in projs.values():
            collect_servers(v)
for d in docs:
    collect_servers(d)

# Enabled plugins — from settings/config (authoritative), NOT the plugin cache.
enabled = set()
def collect_enabled(d):
    if not isinstance(d, dict):
        return
    ep = d.get("enabledPlugins")
    if isinstance(ep, dict):
        for k, v in ep.items():
            if isinstance(v, list):
                for item in v:
                    enabled.add(str(item) if "@" in str(item) else "%s@%s" % (item, k))
            elif v:
                enabled.add(str(k))
    elif isinstance(ep, list):
        enabled.update(str(x) for x in ep)
    projs = d.get("projects")
    if isinstance(projs, dict):
        for v in projs.values():
            collect_enabled(v)
for d in docs:
    collect_enabled(d)

# NATIVE skills/commands/subagents — user + project scope ONLY (real on disk, not plugin cache).
def dirs_in(*roots):
    out = []
    for r in roots:
        if os.path.isdir(r):
            out += [x for x in os.listdir(r) if os.path.isdir(os.path.join(r, x))]
    return out
def md_in(*roots):
    out = []
    for r in roots:
        if os.path.isdir(r):
            out += [os.path.splitext(f)[0] for f in os.listdir(r) if f.endswith(".md")]
    return out
native_skills = dirs_in(os.path.join(claude, "skills"), os.path.join(root, ".claude", "skills"))
native_cmds   = md_in(os.path.join(claude, "commands"), os.path.join(root, ".claude", "commands"))
native_agents = md_in(os.path.join(claude, "agents"), os.path.join(root, ".claude", "agents"))

# Plugin-cache entries — CANDIDATES ONLY. Presence on disk is NOT proof of activation.
cache = []
for r in glob.glob(os.path.join(plug, "**", "skills"), recursive=True):
    if os.path.isdir(r):
        cache += [x for x in os.listdir(r) if os.path.isdir(os.path.join(r, x))]

print("MCP servers (config):            " + (cap(servers) or "(none in config — mcp__<server>__* tools may still be live in-session)"))
print("Enabled plugins (settings):      " + (cap(enabled) or "(none listed in settings enabledPlugins)"))
print("Skills (native user/project):    " + (cap(native_skills) or "(none)"))
print("Commands (native user/project):  " + (cap(native_cmds) or "(none)"))
print("Subagents (native user/project): " + (cap(native_agents) or "(none)"))
print("Plugin-cache candidates (VERIFY LIVE): " + (cap(cache) or "(none in ~/.claude/plugins cache)"))
print("(Availability = live proof, not cache. The cache/config entries above are CANDIDATES;")
print(" confirm with a live registry/tool call — ListPlugins / ListConnectors / ListSkills, or an")
print(" mcp__<server>__* call — before claiming a capability is ACTIVE.)")
PY
else
  echo "(python3 unavailable — skipping capability detection)"
fi

exit 0
