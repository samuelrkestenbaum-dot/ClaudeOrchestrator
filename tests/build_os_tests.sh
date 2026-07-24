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
have "$ROUTER" "Route from the requested outcome" && ok "embedded fallback is outcome-sensitive" || no "embedded fallback is outcome-sensitive"
if sed -n '/## Embedded defaults/,/## How to extend/p' "$ROUTER" | grep -q "Treat the task as.*build"; then
  no "embedded fallback still forces build authority"
else
  ok "embedded fallback does not force full build"
fi

GUIDANCE="$SRC/build-os/global-claude-md.md"
PROMPT_HOOK="$SRC/.claude/hooks/prompt-router.sh"
ORCHESTRATOR="$SRC/.claude/agents/build-orchestrator.md"
have "$GUIDANCE" "Read-only answer / explanation" && ok "global guidance contains direct lane" || no "global guidance missing direct lane"
have "$GUIDANCE" "Close substantive build packets" && ok "receipts limited to substantive builds" || no "global guidance still universalizes receipts"
have "$PROMPT_HOOK" "Read-only answers and diagnosis may run direct" && ok "prompt hook allows direct lanes" || no "prompt hook still universalizes orchestrator"
have "$ORCHESTRATOR" "~/build-os/memory/tool_router.md" && ok "agent has user-scope router fallback" || no "agent lacks user-scope router fallback"
have "$ORCHESTRATOR" "candidates only" && ok "agent labels plugin cache candidates" || no "agent may treat cache as active"

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
GROUTER="$WORK/gbuild"
CLAUDE_USER_DIR="$GHOME" BUILD_OS_USER_DIR="$GROUTER" bash "$SRC/install-global.sh" >/dev/null 2>&1
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
cmp -s "$ROUTER" "$GROUTER/memory/tool_router.md" && ok "global router is byte-identical to source" || no "global router differs from source"

echo "== 4. Managed-block replacement (re-run refreshes stale; no skip, no duplicate) =="
MHOME="$WORK/muser"
MROUTER="$WORK/mbuild"
CLAUDE_USER_DIR="$MHOME" BUILD_OS_USER_DIR="$MROUTER" bash "$SRC/install-global.sh" >/dev/null 2>&1
CMD="$MHOME/CLAUDE.md"
n1="$(grep -c "BUILD-OS:START" "$CMD")"
[ "$n1" = "1" ] && ok "first install writes exactly one managed block" || no "first install block count = $n1 (want 1)"
printf '\n# User note (must survive)\n' >> "$CMD"                 # non-managed content, outside the block
perl -pi -e 's/build-orchestrator/STALE_TOKEN/g' "$CMD"         # portable macOS/Linux stale-guidance simulation
grep -q "STALE_TOKEN" "$CMD" || no "could not inject stale token"
CLAUDE_USER_DIR="$MHOME" BUILD_OS_USER_DIR="$MROUTER" bash "$SRC/install-global.sh" >/dev/null 2>&1
n2="$(grep -c "BUILD-OS:START" "$CMD")"
[ "$n2" = "1" ] && ok "re-run keeps exactly one block (no duplicate)" || no "re-run block count = $n2 (want 1)"
grep -q "STALE_TOKEN" "$CMD" && no "stale guidance was NOT refreshed" || ok "stale guidance replaced with fresh content"
grep -q "User note (must survive)" "$CMD" && ok "non-managed user content preserved" || no "non-managed user content lost"

echo "== 5. Legacy global routing convergence preserves unrelated notes =="
LHOME="$WORK/luser"; LROUTER="$WORK/lbuild"
mkdir -p "$LHOME"
cat > "$LHOME/CLAUDE.md" <<'LEGACY'
# Personal note (must survive)
Keep answers concise.

# Ruflo Integration (auto-generated by ruflo init)
legacy ruflo rules
## Tool Selection Rules
legacy reviewer loop
# CLAUDE.md — Global Operating Directive
legacy receipt rules
Begin your first reply with: `Orchestrator: ON — routing from <router file | embedded>.` then state the Tool Budget before any tool call.

# Tail note (must also survive)
Never invent evidence.
LEGACY
CLAUDE_USER_DIR="$LHOME" BUILD_OS_USER_DIR="$LROUTER" bash "$SRC/install-global.sh" >/dev/null 2>&1
grep -q "Personal note (must survive)" "$LHOME/CLAUDE.md" && ok "prefix user note preserved" || no "prefix user note lost"
grep -q "Tail note (must also survive)" "$LHOME/CLAUDE.md" && ok "suffix user note preserved" || no "suffix user note lost"
if grep -q "legacy reviewer loop\\|legacy receipt rules\\|Ruflo Integration" "$LHOME/CLAUDE.md"; then
  no "known legacy routing stack remains"
else
  ok "known legacy routing stack removed"
fi
test "$(grep -c 'BUILD-OS:START' "$LHOME/CLAUDE.md")" -eq 1 && ok "legacy convergence writes one managed block" || no "legacy convergence block count"
cmp -s "$ROUTER" "$LROUTER/memory/tool_router.md" && ok "arbitrary repo receives current user router" || no "arbitrary repo router is stale"

echo "== 6. P-008 rules: DURABLY CONFIGURED report, 3-tier router fallback, canonical MCP =="
# install-global reports DURABLY CONFIGURED and makes NO ACTIVE claim
DHOME="$WORK/duser"; DROUTER="$WORK/dbuild"
DOUT="$(CLAUDE_USER_DIR="$DHOME" BUILD_OS_USER_DIR="$DROUTER" bash "$SRC/install-global.sh" 2>&1)"
grep -qi "DURABLY CONFIGURED" <<<"$DOUT" && ok "install-global reports DURABLY CONFIGURED" || no "install-global reports DURABLY CONFIGURED"
grep -qiE "is now active|now active in|is active in|now active on" <<<"$DOUT" && no "install-global still claims ACTIVE" || ok "install-global makes no ACTIVE claim"
grep -qiE "not yet active|fresh, authenticated" <<<"$DOUT" && ok "install-global defers activation to a fresh authenticated session" || no "install-global defers activation to a fresh authenticated session"
# global guidance: explicit project -> user-scope -> embedded fallback order
have "$GUIDANCE" "~/build-os/memory/tool_router.md" && ok "guidance names user-scope router tier" || no "guidance names user-scope router tier"
grep -qi "embedded proportionate lanes" "$GUIDANCE" && ok "guidance names embedded-lanes tier" || no "guidance names embedded-lanes tier"
grep -qi "in this order" "$GUIDANCE" && ok "guidance states explicit fallback order" || no "guidance states explicit fallback order"
# canonical-MCP / duplicate rule
have "$ROUTER" "one canonical live server per job" && ok "canonical-MCP rule present" || no "canonical-MCP rule present"
have "$ROUTER" "pinned" && ok "canonical-MCP prefers pinned/user-configured" || no "canonical-MCP prefers pinned/user-configured"
grep -qi "chrome devtools" "$ROUTER" && grep -qi "serena" "$ROUTER" && ok "canonical-MCP names Chrome DevTools + Serena de-dup" || no "canonical-MCP names Chrome DevTools + Serena de-dup"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
