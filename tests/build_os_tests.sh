#!/usr/bin/env bash
# Build OS — repeatable test suite (P-006).
# Covers: proportionate-routing + tool-ranking rules, the SessionStart capability
# detector (enabledPlugins + native scope vs plugin-cache candidates), installer
# copy parity, and managed-block replacement in install-global.sh / install-project.sh.
# No network. Deterministic. Uses only temp dirs — never touches ~/.claude,
# .claude/tdd-guard, or .letta. Exits non-zero if any assertion fails.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROUTER="$SRC/build-os/memory/tool_router.md"
HOOK="$SRC/.claude/hooks/session-start-build-os.sh"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
have(){ grep -qF "$2" "$1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== 1. Proportionate-routing + tool-ranking rules (tool_router.md) =="
have "$ROUTER" "Read-only answer / question"   && ok "read-only route row"   || no "read-only route row"
have "$ROUTER" "Diagnosis / triage (no edits)" && ok "diagnosis route row"   || no "diagnosis route row"
have "$ROUTER" "Tiny reversible local edit"    && ok "tiny-edit route row"   || no "tiny-edit route row"
have "$ROUTER" "no qa/reviewer/archivist"      && ok "lightweight routes skip the full chain" || no "lightweight routes skip the full chain"
have "$ROUTER" "Tool selection ranking"        && ok "ranking section present" || no "ranking section present"
for term in "Exact task match" "Project-local instruction" "Enabled / live evidence" \
            "Least privilege" "Lowest orchestration overhead" "Freshest verified result"; do
  have "$ROUTER" "$term" && ok "ranking factor: $term" || no "ranking factor: $term"
done
have "$ROUTER" "one primary capability" && ok "one-primary-capability rule" || no "one-primary-capability rule"
have "$ROUTER" "candidate"              && ok "cache-is-candidate note"     || no "cache-is-candidate note"

echo "== 2. SessionStart detector: enabledPlugins + native scope; cache = candidate (not proof) =="
FHOME="$WORK/home"; FPROJ="$WORK/proj"
mkdir -p "$FHOME/.claude/skills/native-skill" \
         "$FHOME/.claude/plugins/mkt/plug/skills/cache-skill" \
         "$FPROJ/build-os/memory"
cat > "$FHOME/.claude/settings.json" <<'JSON'
{ "enabledPlugins": { "trailofbits": ["static-analysis"], "claude-hud": ["claude-hud"] } }
JSON
OUT="$(HOME="$FHOME" CLAUDE_PROJECT_DIR="$FPROJ" bash "$HOOK" 2>/dev/null)"
grep -q "Enabled plugins (settings):.*static-analysis" <<<"$OUT" && ok "reports enabledPlugins from settings" || no "reports enabledPlugins from settings"
grep -q "Skills (native user/project):.*native-skill"  <<<"$OUT" && ok "reports native skills"                || no "reports native skills"
grep -q "Plugin-cache candidates.*cache-skill"         <<<"$OUT" && ok "cache entry labeled candidate"        || no "cache entry labeled candidate"
if grep "Skills (native user/project):" <<<"$OUT" | grep -q "cache-skill"; then
  no "cache leaked into native/active skills"
else
  ok "cache NOT counted as native/active"
fi
grep -qi "VERIFY LIVE" <<<"$OUT" && ok "verify-live note present" || no "verify-live note present"

echo "== 3. Installer copy parity (source == install-global == install-project) =="
src_agents="$(cd "$SRC/.claude/agents"   && ls *.md | sort)"
src_cmds="$(cd "$SRC/.claude/commands"   && ls *.md | sort)"
src_hooks="$(cd "$SRC/.claude/hooks"     && ls *.sh | sort)"
GHOME="$WORK/guser"
CLAUDE_USER_DIR="$GHOME" bash "$SRC/install-global.sh" >/dev/null 2>&1
PPROJ="$WORK/pproj"; mkdir -p "$PPROJ"
bash "$SRC/install-project.sh" --no-session-hook "$PPROJ" >/dev/null 2>&1
g_agents="$(cd "$GHOME/agents"          && ls *.md | sort)"; p_agents="$(cd "$PPROJ/.claude/agents"   && ls *.md | sort)"
g_cmds="$(cd "$GHOME/commands"          && ls *.md | sort)"; p_cmds="$(cd "$PPROJ/.claude/commands"    && ls *.md | sort)"
g_hooks="$(cd "$GHOME/hooks"            && ls *.sh | sort)"; p_hooks="$(cd "$PPROJ/.claude/hooks"      && ls *.sh | sort)"
[ "$src_agents" = "$g_agents" ] && [ "$src_agents" = "$p_agents" ] && ok "agents parity (name set)"   || no "agents parity (name set)"
[ "$src_cmds"   = "$g_cmds"   ] && [ "$src_cmds"   = "$p_cmds"   ] && ok "commands parity (name set)" || no "commands parity (name set)"
[ "$src_hooks"  = "$g_hooks"  ] && [ "$src_hooks"  = "$p_hooks"  ] && ok "hooks parity (name set)"    || no "hooks parity (name set)"
cflag=1
for f in $src_agents; do cmp -s "$SRC/.claude/agents/$f" "$GHOME/agents/$f" || cflag=0; done
for f in $src_hooks;  do cmp -s "$SRC/.claude/hooks/$f"  "$PPROJ/.claude/hooks/$f" || cflag=0; done
[ "$cflag" = 1 ] && ok "copied engine files are byte-identical to source" || no "copied engine files differ from source"

echo "== 4. Managed-block replacement (re-run refreshes stale; no skip, no duplicate) =="
MHOME="$WORK/muser"
CLAUDE_USER_DIR="$MHOME" bash "$SRC/install-global.sh" >/dev/null 2>&1
CMD="$MHOME/CLAUDE.md"
n1="$(grep -c "BUILD-OS:START" "$CMD")"
[ "$n1" = "1" ] && ok "first install writes exactly one managed block" || no "first install block count = $n1 (want 1)"
printf '\n# User note (must survive)\n' >> "$CMD"                 # non-managed content, outside the block
sed -i 's/build-orchestrator/STALE_TOKEN/g' "$CMD"               # simulate stale guidance inside the block
grep -q "STALE_TOKEN" "$CMD" || no "could not inject stale token"
CLAUDE_USER_DIR="$MHOME" bash "$SRC/install-global.sh" >/dev/null 2>&1
n2="$(grep -c "BUILD-OS:START" "$CMD")"
[ "$n2" = "1" ] && ok "re-run keeps exactly one block (no duplicate)" || no "re-run block count = $n2 (want 1)"
grep -q "STALE_TOKEN" "$CMD" && no "stale guidance was NOT refreshed" || ok "stale guidance replaced with fresh content"
grep -q "User note (must survive)" "$CMD" && ok "non-managed user content preserved" || no "non-managed user content lost"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
