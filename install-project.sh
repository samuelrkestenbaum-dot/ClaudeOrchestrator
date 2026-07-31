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
cp "$SRC/.claude/hooks/"*.sh "$DEST/.claude/hooks/"
chmod +x "$DEST/.claude/hooks/"*.sh
echo "  + agents, commands, hooks"

# Memory scaffold — never overwrite existing project state.
#
# SEEDED FROM templates/, NEVER FROM THIS REPO'S LIVE build-os/memory. The
# templates mirror the destination layout path-for-path and carry contract text
# plus empty starting values only; this repo's own build-os/ is its operational
# state, not a customer artifact.
for rel in build-os/memory/tool_router.md build-os/memory/current_state.md \
           build-os/memory/residue.md build-os/packets/active_packet.md \
           build-os/receipts/README.md; do
  if [ -e "$DEST/$rel" ]; then
    echo "  = $rel (exists, kept)"
  elif [ ! -f "$SRC/templates/$rel" ]; then
    echo "  ! missing template: templates/$rel — refusing to seed from live memory." >&2
    exit 1
  else
    cp "$SRC/templates/$rel" "$DEST/$rel"; echo "  + $rel"
  fi
done

# Memory maintenance + safety layer. Managed files are replaced on every run;
# the customer's build-os/memory/standing_gates.md is seeded only if absent, and
# nothing here touches the memory files scaffolded above.
"$SRC/build-os/maintenance/install-maintenance.sh" "$DEST"

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

# CLAUDE.md guidance — managed block, REPLACED on re-run (stale guidance refreshed,
# non-managed content kept).
python3 - "$DEST/CLAUDE.md" "$SRC/build-os/global-claude-md.md" "install-project.sh" <<'PY'
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
had = "BUILD-OS:START" in existing
cleaned = re.sub(r"\n*<!-- BUILD-OS:START.*?-->.*?<!-- BUILD-OS:END -->\n*", "\n",
                 existing, flags=re.DOTALL).rstrip("\n")
new = (cleaned + "\n\n" + managed + "\n") if cleaned else (managed + "\n")
with open(claude_md, "w") as f:
    f.write(new)
print("  %s CLAUDE.md Build OS block" % ("~ replaced" if had else "+ added"))
PY

# Stamp the installed copy — version, source commit, and a sha256 of every engine
# file placed above, with a byte-identical copy of LICENSE beside each stamp. This
# is what lets a session in THIS repo state which version and which licence it is
# running under without asking a human, and what makes a half-upgraded or
# hand-patched install detectable (see .claude/hooks/build-os-identity.sh).
# Never fatal: a missing stamp is reported as missing, never as verified.
IDENTITY_SH="$SRC/.claude/hooks/build-os-identity.sh"
ENGINE_RELS=()
for f in "$DEST/.claude/agents/"*.md;   do [ -e "$f" ] && ENGINE_RELS+=("agents/$(basename "$f")"); done
for f in "$DEST/.claude/commands/"*.md; do [ -e "$f" ] && ENGINE_RELS+=("commands/$(basename "$f")"); done
for f in "$DEST/.claude/hooks/"*.sh;    do [ -e "$f" ] && ENGINE_RELS+=("hooks/$(basename "$f")"); done
if bash "$IDENTITY_SH" stamp --source "$SRC" --root "$DEST/.claude" --scope project -- "${ENGINE_RELS[@]}" \
   && bash "$IDENTITY_SH" stamp --source "$SRC" --root "$DEST/build-os" --scope project --; then
  :
else
  echo "  ! identity stamp NOT written — this install cannot state its version/licence" >&2
fi

echo "Done. Commit .claude/ + build-os/ (+ CLAUDE.md) to this repo to make it permanent."
