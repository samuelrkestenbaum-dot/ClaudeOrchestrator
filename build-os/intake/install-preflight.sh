#!/usr/bin/env bash
# Gravito — install preflight (LANE 3).
#
# install-preflight.sh <target-repo>
#
# Answers ONE question without writing a byte: what would installing Gravito
# (install-project.sh + build-os/maintenance/install-maintenance.sh) do to this
# repo, and would any customer bytes be at risk?
#
# Every file the installers would place is classified:
#
#   WOULD-CREATE  — absent in the target; install would create it
#   IDENTICAL     — present and byte-identical; install would be a no-op there
#   WOULD-REFUSE  — present with DIFFERENT content. install-project.sh as
#                   shipped would overwrite engine/managed files; this
#                   preflight's contract is to refuse instead, because eating
#                   customer bytes silently is the defect class this whole
#                   repo exists against. Resolve the collision (rename, remove,
#                   or accept the overwrite explicitly) before installing.
#   KEPT          — a customer-owned seed (memory/packets/receipts) that the
#                   installer never overwrites; present means untouched
#
# Plus previews of the three merge surfaces the installer edits in place:
# .claude/settings.json (hook entries), CLAUDE.md (managed block), and
# .gitignore (archive-visibility line). An unparseable settings.json is a
# refusal: the real installer would crash halfway through it.
#
# Exit 0 = PREFLIGHT: CLEAR. Exit 2 = PREFLIGHT: WOULD-REFUSE (or bad usage).
# WRITES NOTHING, anywhere, under any outcome. No network.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

TARGET="${1:-}"
if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  echo "usage: install-preflight.sh <target-repo>" >&2
  exit 2
fi
TARGET="$(cd "$TARGET" && pwd)"

if [ "$SRC" = "$TARGET" ]; then
  echo "PREFLIGHT: target is the Gravito source repo itself; nothing to install."
  exit 0
fi

echo "Gravito install preflight — target: $TARGET"
echo "(read-only: this run writes nothing, whatever it finds)"
echo

NCREATE=0; NIDENT=0; NREFUSE=0; NKEPT=0

# classify <src-file> <dest-rel> <mode>   mode: overwrite | seed
classify(){
  local sf="$1" rel="$2" mode="$3" df="$TARGET/$2"
  if [ ! -f "$sf" ]; then
    echo "  ! source file missing: $sf (preflight cannot vouch for this path)"
    return
  fi
  if [ ! -e "$df" ]; then
    NCREATE=$((NCREATE+1)); echo "WOULD-CREATE: $rel"
  elif cmp -s "$sf" "$df"; then
    NIDENT=$((NIDENT+1)); echo "IDENTICAL: $rel"
  elif [ "$mode" = "seed" ]; then
    NKEPT=$((NKEPT+1)); echo "KEPT: $rel (customer file; installer never overwrites it)"
  else
    NREFUSE=$((NREFUSE+1))
    echo "WOULD-REFUSE: $rel (exists with different content; install would overwrite customer bytes)"
  fi
}

# ---- engine files install-project.sh copies (and would overwrite) -----------
for f in "$SRC/.claude/agents/"*.md;   do classify "$f" ".claude/agents/$(basename "$f")" overwrite; done
for f in "$SRC/.claude/commands/"*.md; do classify "$f" ".claude/commands/$(basename "$f")" overwrite; done
for f in "$SRC/.claude/hooks/"*.sh;    do classify "$f" ".claude/hooks/$(basename "$f")" overwrite; done

# ---- maintenance managed set — read from install-maintenance.sh itself so a
# ---- list change there cannot silently drift away from this preflight -------
MAINT="$SRC/build-os/maintenance/install-maintenance.sh"
MANAGED_LIST="$(awk '/^MANAGED=\(/{f=1;next} f&&/^\)/{exit} f{gsub(/["[:space:]]/,""); if($0!="") print}' "$MAINT")"
if [ -z "$MANAGED_LIST" ]; then
  echo "  ! could not extract the MANAGED list from install-maintenance.sh —"
  echo "  ! the maintenance layer is NOT covered by this preflight run"
  NREFUSE=$((NREFUSE+1))
else
  while IFS= read -r rel; do
    classify "$SRC/$rel" "$rel" overwrite
  done <<< "$MANAGED_LIST"
fi

# ---- customer seeds — written only if absent, never overwritten -------------
for rel in build-os/memory/tool_router.md build-os/memory/current_state.md \
           build-os/memory/residue.md build-os/packets/active_packet.md \
           build-os/receipts/README.md; do
  classify "$SRC/templates/$rel" "$rel" seed
done
classify "$SRC/build-os/maintenance/templates/standing_gates.md" \
         "build-os/memory/standing_gates.md" seed

echo

# ---- settings.json merge preview (parse only; never write) ------------------
SETTINGS="$TARGET/.claude/settings.json"
SETTINGS_BAD=0
if [ ! -f "$SETTINGS" ]; then
  echo "SETTINGS-MERGE: no .claude/settings.json — would create it with SessionStart + UserPromptSubmit hook entries"
else
  if ! python3 - "$SETTINGS" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
hooks = data.get("hooks", {}) if isinstance(data, dict) else {}
def state(event, script):
    for g in hooks.get(event, []):
        for h in g.get("hooks", []):
            if str(h.get("command", "")).endswith(script):
                return "already present"
    return "would add"
print("SETTINGS-MERGE: SessionStart hook session-start-build-os.sh — %s"
      % state("SessionStart", "session-start-build-os.sh"))
print("SETTINGS-MERGE: UserPromptSubmit hook prompt-router.sh — %s"
      % state("UserPromptSubmit", "prompt-router.sh"))
others = [k for k in (data if isinstance(data, dict) else {}) if k != "hooks"]
print("SETTINGS-MERGE: %d existing top-level key(s) preserved by the merge" % len(others))
PY
  then
    SETTINGS_BAD=1
    NREFUSE=$((NREFUSE+1))
    echo "SETTINGS-MERGE: existing .claude/settings.json is not valid JSON — install-project.sh would fail mid-install; fix it before installing"
  fi
fi

# ---- CLAUDE.md managed-block preview ----------------------------------------
CMD_FILE="$TARGET/CLAUDE.md"
if [ ! -f "$CMD_FILE" ]; then
  echo "CLAUDE-MD: no CLAUDE.md — would create it containing only the managed block"
elif grep -q 'BUILD-OS:START' "$CMD_FILE"; then
  echo "CLAUDE-MD: would replace the existing managed block (customer bytes outside the block preserved)"
else
  echo "CLAUDE-MD: would append the managed block (existing customer bytes preserved)"
fi

# ---- .gitignore preview -----------------------------------------------------
GI="$TARGET/.gitignore"
GI_LINE='!build-os/memory/archive/'
if [ -f "$GI" ] && grep -qxF "$GI_LINE" "$GI"; then
  echo "GITIGNORE: archive-visibility line already present"
elif [ -f "$GI" ]; then
  echo "GITIGNORE: would append the archive-visibility line ($GI_LINE)"
else
  echo "GITIGNORE: no .gitignore — installer would create/append one with $GI_LINE"
fi

echo
echo "Summary: $NCREATE would-create, $NIDENT identical, $NKEPT kept (customer), $NREFUSE refusal(s)."
if [ "$NREFUSE" -gt 0 ]; then
  echo "PREFLIGHT: WOULD-REFUSE ($NREFUSE refusal(s)) — nothing written; resolve the collisions above before installing."
  exit 2
fi
echo "PREFLIGHT: CLEAR — nothing written; install-project.sh may proceed."
exit 0
