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
# What install-global.sh SEEDS at user scope. Deliberately the template, not the
# live router above: a stranger's install must not receive this repo's operator
# inventory. Pinning against $ROUTER is what previously let that leak stand.
SEED_ROUTER="$SRC/templates/build-os/memory/tool_router.md"
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
# Claude Code invokes a SessionStart hook with a JSON payload of this shape on stdin and
# then closes it (the real event also carries transcript_path and cwd, which this detector
# does not read). The hook reads stdin to EOF, so a payload MUST be supplied here: inheriting the
# caller's stdin blocks forever on an interactive terminal (see section 27). TMPDIR is
# isolated to $WORK so the hook-once guard starts fresh on every run.
SESSION_PAYLOAD='{"session_id":"build-os-detector-test","hook_event_name":"SessionStart","source":"startup"}'
OUT="$(printf '%s' "$SESSION_PAYLOAD" | HOME="$FHOME" CLAUDE_PROJECT_DIR="$FPROJ" TMPDIR="$WORK/s2tmp" bash "$HOOK" 2>/dev/null)"
grep -q "Enabled plugins (settings):.*static-analysis" <<<"$OUT" && ok "reports enabledPlugins from settings" || no "reports enabledPlugins from settings"
grep -q "Skills (native user/project):.*native-skill"  <<<"$OUT" && ok "reports native skills"                || no "reports native skills"
grep -q "Plugin-cache candidates.*cache-skill"         <<<"$OUT" && ok "cache entry labeled candidate"        || no "cache entry labeled candidate"
if grep "Skills (native user/project):" <<<"$OUT" | grep -q "cache-skill"; then
  no "cache leaked into native/active skills"
else
  ok "cache NOT counted as native/active"
fi
grep -qi "VERIFY LIVE" <<<"$OUT" && ok "verify-live note present" || no "verify-live note present"
grep -q '^Orchestrator: ON' <<<"$OUT" && ok "startup output begins with orchestrator signal" || no "startup signal missing"
[ "${#OUT}" -lt 12000 ] && ok "startup output stays below 12KB" || no "startup output too large (${#OUT} bytes)"
grep -q '68884f1190489685082dc3c3b56917e92a1de0e6' "$SRC/install-accelerators.sh" && ok "Serena bootstrap is commit-pinned" || no "Serena bootstrap is not commit-pinned"

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
cmp -s "$SEED_ROUTER" "$GROUTER/memory/tool_router.md" && ok "global router is byte-identical to the TEMPLATE (no operator inventory installed)" || no "global router is not the template — operator inventory may be leaking to user scope"

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
cmp -s "$SEED_ROUTER" "$LROUTER/memory/tool_router.md" && ok "arbitrary repo receives the template router" || no "arbitrary repo router is not the template"

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

echo "== 7. P-010 installed-state convergence: one startup + one Serena MCP =="
DUPE_HOME="$WORK/dupe-home"; DUPE_PROJ="$WORK/dupe-proj"
DUPE_TMP="$WORK/dupe-tmp"
mkdir -p "$DUPE_HOME" "$DUPE_PROJ/build-os/memory" "$DUPE_TMP"
DUPE_INPUT='{"session_id":"build-os-dedup-test","hook_event_name":"SessionStart","source":"startup"}'
DUPE_OUT="$(
  printf '%s' "$DUPE_INPUT" | TMPDIR="$DUPE_TMP" HOME="$DUPE_HOME" CLAUDE_PROJECT_DIR="$DUPE_PROJ" bash "$HOOK"
  printf '%s' "$DUPE_INPUT" | TMPDIR="$DUPE_TMP" HOME="$DUPE_HOME" CLAUDE_PROJECT_DIR="$DUPE_PROJ" bash "$HOOK"
)"
test "$(grep -c '^Orchestrator: ON' <<<"$DUPE_OUT")" -eq 1 \
  && ok "global + project hook invocations converge to one startup" \
  || no "global + project hooks both emitted startup output"
PROMPT_INPUT='{"session_id":"build-os-dedup-test","prompt_id":"prompt-1","hook_event_name":"UserPromptSubmit"}'
PROMPT_OUT="$(
  printf '%s' "$PROMPT_INPUT" | TMPDIR="$DUPE_TMP" HOME="$DUPE_HOME" bash "$PROMPT_HOOK"
  printf '%s' "$PROMPT_INPUT" | TMPDIR="$DUPE_TMP" HOME="$DUPE_HOME" bash "$PROMPT_HOOK"
)"
test "$(grep -c '^Routing reminder:' <<<"$PROMPT_OUT")" -eq 1 \
  && ok "global + project prompt hooks converge to one reminder" \
  || no "global + project prompt hooks both emitted reminders"
if python3 - "$SRC/.mcp.json" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
raise SystemExit(1 if "serena" in data.get("mcpServers", {}) else 0)
PY
then
  ok "project config does not double-launch plugin-provided Serena"
else
  no "project config still registers a second Serena MCP"
fi

echo "== 8. P-010 durable host repair =="
REPAIR_ROOT="$WORK/repair-home/.claude"
MEM_CACHE="$REPAIR_ROOT/plugins/cache/thedotmack/claude-mem/13.8.1/hooks"
MEM_MARKET="$REPAIR_ROOT/plugins/marketplaces/thedotmack/plugin/hooks"
SUB_CACHE="$REPAIR_ROOT/plugins/cache/claude-subconscious/claude-subconscious/2.1.1/hooks"
SUB_MARKET="$REPAIR_ROOT/plugins/marketplaces/claude-subconscious/hooks"
mkdir -p "$MEM_CACHE" "$MEM_MARKET" "$SUB_CACHE" "$SUB_MARKET" "$REPAIR_ROOT/agents"
printf '%s\n' '{"enabledPlugins":{"ecc@ecc":true,"zeroize-audit@trailofbits":true}}' > "$REPAIR_ROOT/settings.json"
printf '%s\n' '{"mcpServers":{"keep-me":{"command":"keep"}}}' > "$WORK/repair-home/.claude.json"
printf '%s\n' '"command": "worker start; echo '\''{\"continue\":true,\"suppressOutput\":true}'\''"' \
  > "$MEM_CACHE/hooks.json"
cp "$MEM_CACHE/hooks.json" "$MEM_MARKET/hooks.json"
cat > "$SUB_CACHE/hooks.json" <<'JSON'
{"hooks":{"SessionStart":[{"matcher":"*","hooks":[
{"type":"command","command":"session_start.ts","timeout":5},
{"type":"command","command":"sync_letta_memory.ts","timeout":10}
]}]}}
JSON
cp "$SUB_CACHE/hooks.json" "$SUB_MARKET/hooks.json"
cat > "$REPAIR_ROOT/agents/large-agent.md" <<'MD'
---
name: large-agent
description: >-
  This is an intentionally very long routing description that should be compacted
  without changing any of the complete agent instructions below the frontmatter.
---
KEEP THIS FULL AGENT BODY
MD
if CLAUDE_USER_DIR="$REPAIR_ROOT" bash "$SRC/repair-host-integrations.sh" >/dev/null 2>&1; then
  ok "host repair script runs"
else
  no "host repair script runs"
fi
if rg -q 'start; echo' "$MEM_CACHE/hooks.json" "$MEM_MARKET/hooks.json"; then
  no "claude-mem duplicate JSON emitter remains"
else
  ok "claude-mem duplicate JSON emitter removed durably"
fi
python3 - "$SUB_CACHE/hooks.json" "$SUB_MARKET/hooks.json" <<'PY'
import json, sys
for path in sys.argv[1:]:
    groups = json.load(open(path))["hooks"]["SessionStart"]
    assert len(groups) == 2
    assert all(len(group["hooks"]) == 1 for group in groups)
PY
test "$?" -eq 0 && ok "claude-subconscious startup hooks split durably" || no "claude-subconscious startup hooks not split"
grep -q 'KEEP THIS FULL AGENT BODY' "$REPAIR_ROOT/agents/large-agent.md" \
  && ok "agent body preserved during description compaction" \
  || no "agent body changed during description compaction"
grep -q '^description: ".*"$' "$REPAIR_ROOT/agents/large-agent.md" \
  && ok "agent description compacted below limit" \
  || no "agent description remains oversized"
python3 - "$REPAIR_ROOT/settings.json" "$WORK/repair-home/.claude.json" <<'PY'
import json, sys
settings = json.load(open(sys.argv[1]))
host = json.load(open(sys.argv[2]))
assert settings["skillListingBudgetFraction"] == 0.18
assert settings["enabledPlugins"]["ecc@ecc"] is False
assert settings["enabledPlugins"]["zeroize-audit@trailofbits"] is False
assert host["mcpServers"]["keep-me"]["command"] == "keep"
serena = host["mcpServers"]["serena"]
assert "68884f1190489685082dc3c3b56917e92a1de0e6" in " ".join(serena["args"])
PY
test "$?" -eq 0 && ok "host runtime converges skill budget and pinned Serena without clobbering MCPs" || no "host runtime convergence failed"

echo "== 9. P-011: UserPromptSubmit dedupe without prompt_id (payload-hash event key) =="
DEDUP="$WORK/dedup"; mkdir -p "$DEDUP"
P1='{"session_id":"sessABC","transcript_path":"/tmp/t.jsonl","cwd":"/x","hook_event_name":"UserPromptSubmit","prompt":"first prompt"}'
P2='{"session_id":"sessABC","transcript_path":"/tmp/t.jsonl","cwd":"/x","hook_event_name":"UserPromptSubmit","prompt":"second prompt"}'
emitted() { [ -n "$(printf '%s' "$1" | TMPDIR="$DEDUP" bash "$SRC/.claude/hooks/prompt-router.sh" 2>/dev/null)" ] && echo 1 || echo 0; }
a="$(emitted "$P1")"; b="$(emitted "$P1")"   # one prompt fires the hook twice (global+project), no prompt_id
[ "$a" = "1" ] && [ "$b" = "0" ] && ok "duplicate invocations of one prompt emit exactly once" || no "dedupe wrong for one prompt (a=$a b=$b)"
c="$(emitted "$P2")"                          # a later, different prompt in the SAME session
[ "$c" = "1" ] && ok "a later prompt in the same session emits again" || no "later prompt lost the reminder (c=$c)"
d="$(emitted "$P2")"                          # its own duplicate collapses
[ "$d" = "0" ] && ok "later prompt's duplicate invocation suppressed" || no "later prompt duplicated (d=$d)"
grep -q 'sha256' "$SRC/.claude/hooks/hook-once.sh" && ok "hook key is a payload content hash, not prompt_id-only" || no "hook still relies on prompt_id only"

echo "== 10. P-011: skill-budget audit tool + policy =="
AUDIT="$SRC/build-os/tools/skill-budget-audit.sh"
[ -x "$AUDIT" ] && ok "skill-budget-audit.sh present + executable" || no "skill-budget-audit.sh missing/not executable"
SB="$WORK/sbplug"
mkdir -p "$SB/trailofbits/a/skills/s1" "$SB/trailofbits/b/skills/s2" "$SB/trailofbits/c/skills/s3" "$SB/keep/skills/s4"
for d in "$SB/trailofbits/a/skills/s1" "$SB/trailofbits/b/skills/s2" "$SB/trailofbits/c/skills/s3" "$SB/keep/skills/s4"; do printf 'name: x\ndescription: y\n' > "$d/SKILL.md"; done
AOUT="$(bash "$AUDIT" "$SB" 100000 2>/dev/null)"
grep -q "total skills: 4" <<<"$AOUT" && ok "audit counts skills correctly" || no "audit skill count wrong"
grep -qi "trailofbits" <<<"$AOUT" && ok "audit surfaces the dominant plugin" || no "audit misses dominant plugin"
grep -qi "OVER BUDGET" <<<"$(bash "$AUDIT" "$SB" 1 2>/dev/null)" && ok "audit flags over-budget" || no "audit does not flag over-budget"
POL="$SRC/build-os/memory/skill_budget.md"
have "$POL" "minimal active skill set" && ok "skill-budget policy present" || no "skill-budget policy missing"
have "$POL" "685" && ok "policy records the observed over-budget figure" || no "policy missing observed figure"

echo "== 11. P-012: Serena pinned single-instance convergence =="
have "$ROUTER" "one user-scope" && ok "router names the pinned user-scope Serena" || no "router omits pinned user-scope Serena"
if grep -q "plugin:zeroize-audit:serena" "$ROUTER"; then
  no "router still routes to plugin-bundled Serena"
else
  ok "router does not route to plugin-bundled Serena"
fi
PIN="$SRC/templates/serena-pinned.mcp.json"
[ -f "$PIN" ] && ok "reproducible pinned-Serena template present" || no "pinned-Serena template missing"
grep -q "68884f1190489685082dc3c3b56917e92a1de0e6" "$PIN" && ok "pinned template pins the exact commit" || no "pinned template not commit-pinned"
python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$PIN" 2>/dev/null && ok "pinned template is valid JSON" || no "pinned template invalid JSON"

echo "== 12. P-011: remote/org vs local-verified capability separation =="
grep -qi "Remote / org capabilities" "$ROUTER" && ok "router separates remote/org capabilities" || no "router does not separate remote/org"
grep -qi "NOT in the local Claude Code plugin registry" "$ROUTER" && ok "router flags org caps as not-in-local-registry" || no "router still conflates org with local"
grep -qi "no-route-to-unverified" "$ROUTER" && ok "router has a no-route-to-unverified rule" || no "router lacks no-route-to-unverified rule"

echo "== 13. P-013: reversible specialist capability profiles =="
PROFILE="$SRC/build-os/tools/capability-profile.sh"
PROFILE_HOME="$WORK/profile-home"
mkdir -p "$PROFILE_HOME/.claude"
printf '%s\n' '{"enabledPlugins":{}}' > "$PROFILE_HOME/.claude/settings.json"
printf '%s\n' '{"mcpServers":{"keep-me":{"command":"keep"}}}' > "$PROFILE_HOME/.claude.json"
if CLAUDE_USER_DIR="$PROFILE_HOME/.claude" CLAUDE_CONFIG_PATH="$PROFILE_HOME/.claude.json" bash "$PROFILE" focused >/dev/null 2>&1; then
  ok "focused capability profile runs"
else
  no "focused capability profile missing or failed"
fi
python3 - "$PROFILE_HOME/.claude/settings.json" "$PROFILE_HOME/.claude.json" <<'PY'
import json, sys
s = json.load(open(sys.argv[1])); c = json.load(open(sys.argv[2]))
assert s["enabledPlugins"]["ecc@ecc"] is False
assert s["enabledPlugins"]["zeroize-audit@trailofbits"] is False
assert s["skillListingBudgetFraction"] == 0.18
assert "68884f1190489685082dc3c3b56917e92a1de0e6" in " ".join(c["mcpServers"]["serena"]["args"])
assert c["mcpServers"]["keep-me"]["command"] == "keep"
PY
test "$?" -eq 0 && ok "focused profile keeps pinned Serena and focused budget" || no "focused profile state wrong"
CLAUDE_USER_DIR="$PROFILE_HOME/.claude" CLAUDE_CONFIG_PATH="$PROFILE_HOME/.claude.json" bash "$PROFILE" ecc >/dev/null 2>&1
python3 - "$PROFILE_HOME/.claude/settings.json" "$PROFILE_HOME/.claude.json" <<'PY'
import json, sys
s = json.load(open(sys.argv[1])); c = json.load(open(sys.argv[2]))
assert s["enabledPlugins"]["ecc@ecc"] is True
assert s["enabledPlugins"]["zeroize-audit@trailofbits"] is False
assert s["skillListingBudgetFraction"] == 0.40
assert "serena" in c["mcpServers"]
PY
test "$?" -eq 0 && ok "ECC profile restores all ECC capabilities without duplicate Serena" || no "ECC profile state wrong"
CLAUDE_USER_DIR="$PROFILE_HOME/.claude" CLAUDE_CONFIG_PATH="$PROFILE_HOME/.claude.json" bash "$PROFILE" zeroize >/dev/null 2>&1
python3 - "$PROFILE_HOME/.claude/settings.json" "$PROFILE_HOME/.claude.json" <<'PY'
import json, sys
s = json.load(open(sys.argv[1])); c = json.load(open(sys.argv[2]))
assert s["enabledPlugins"]["ecc@ecc"] is False
assert s["enabledPlugins"]["zeroize-audit@trailofbits"] is True
assert "serena" not in c["mcpServers"]
assert c["mcpServers"]["keep-me"]["command"] == "keep"
PY
test "$?" -eq 0 && ok "zeroize profile restores audit workflow and removes duplicate Serena" || no "zeroize profile state wrong"

echo "== 14. P-014: zero-touch specialist orchestration =="
HANDOFF="$SRC/build-os/tools/specialist-handoff.sh"
PROFILE="$SRC/build-os/tools/capability-profile.sh"
[ -x "$HANDOFF" ] && ok "specialist-handoff.sh present + executable" || no "specialist-handoff.sh missing/not executable"

# deterministic route classification
[ "$(bash "$HANDOFF" classify 'please refactor the build script' 2>/dev/null)" = "focused" ] && ok "classify: ordinary task -> focused" || no "classify focused wrong"
[ "$(bash "$HANDOFF" classify 'run a zeroize-audit on the key handling' 2>/dev/null)" = "zeroize" ] && ok "classify: zeroize task -> zeroize" || no "classify zeroize wrong"
[ "$(bash "$HANDOFF" classify 'implement ed25519 ECC signing' 2>/dev/null)" = "ecc" ] && ok "classify: ECC task -> ecc" || no "classify ecc wrong"
r14="$(bash "$HANDOFF" classify 'zeroize the ecc private key' 2>/dev/null)"
{ [ "$r14" = "zeroize" ] || [ "$r14" = "ecc" ]; } && ok "classify never returns ECC+zeroize together (got $r14)" || no "classify ambiguous"

mkbin() { mkdir -p "$1" "$2"; cat > "$1/claude" <<'EOF'
#!/usr/bin/env bash
mkdir -p "$MOCK_REC"
echo "$PWD" > "$MOCK_REC/pwd"
prompt="$(cat)"
printf '%s' "$prompt" > "$MOCK_REC/prompt"
printf '%s\n' "$#" > "$MOCK_REC/argc"
printf '%s' "${BUILD_OS_SPECIALIST_HANDOFF:-}" > "$MOCK_REC/guard"
: > "$MOCK_REC/launched"
[ -n "${MOCK_CLAUDE_SLEEP:-}" ] && sleep "$MOCK_CLAUDE_SLEEP"
# P-018.1: generate/stream a large payload INSIDE the child, never through an env var or
# argv (those hit Linux MAX_ARG_STRLEN ~128KB and fail execve before the real capture-time
# bound ever runs; macOS has no such per-arg cap, which hid the defect there).
[ -n "${MOCK_GEN_BYTES:-}" ] && { head -c "$MOCK_GEN_BYTES" </dev/zero | tr '\0' z; echo; }
if [ -n "${MOCK_STREAM_CHUNKS:-}" ]; then
  _i=0; while [ "$_i" -lt "$MOCK_STREAM_CHUNKS" ]; do head -c 4096 </dev/zero | tr '\0' y; echo; sleep 0.02; _i=$((_i+1)); done
fi
echo "${MOCK_CHILD_OUTPUT:-MOCK_CHILD_OUTPUT route=${BUILD_OS_SPECIALIST_HANDOFF:-}}"
echo "[BUILD_OS_STATUS: ${MOCK_TERMINAL_STATUS:-COMPLETED}]"
[ -n "${MOCK_AFTER_STATUS:-}" ] && echo "$MOCK_AFTER_STATUS"
exit "${MOCK_CLAUDE_EXIT:-0}"
EOF
chmod +x "$1/claude"; }

seed_home() { mkdir -p "$1/.claude"
  printf '{"enabledPlugins":{},"skillListingBudgetFraction":0.18}\n' > "$1/.claude/settings.json"
  printf '{"mcpServers":{"keep-me":{"command":"keep"}}}\n' > "$1/.claude.json"
  CLAUDE_USER_DIR="$1/.claude" CLAUDE_CONFIG_PATH="$1/.claude.json" bash "$PROFILE" focused >/dev/null 2>&1; }

run_handoff() { MOCK_REC="$REC" CLAUDE_BIN="$MB/claude" CAPABILITY_PROFILE_BIN="$PROFILE" \
  CLAUDE_USER_DIR="$PH/.claude" CLAUDE_CONFIG_PATH="$PH/.claude.json" \
  HANDOFF_LOG="$REC/handoffs.log" HANDOFF_LOCK="$REC/handoff.lock" \
  HANDOFF_LOCK_WAIT="${HANDOFF_LOCK_WAIT:-30}" HANDOFF_TIMEOUT="${HANDOFF_TIMEOUT:-30}" \
  bash "$HANDOFF" detect "$1" "$2"; }

is_focused() { python3 - "$PH/.claude/settings.json" "$PH/.claude.json" <<'PY'
import json,sys
s=json.load(open(sys.argv[1])); c=json.load(open(sys.argv[2]))
sys.exit(0 if (s["enabledPlugins"].get("ecc@ecc") is False and s["enabledPlugins"].get("zeroize-audit@trailofbits") is False and "serena" in c["mcpServers"]) else 1)
PY
}

# focused: no relaunch
MB="$WORK/h1/bin"; REC="$WORK/h1/rec"; PH="$WORK/h1/home"; mkbin "$MB" "$REC"; seed_home "$PH"
run_handoff "just list the files" "$WORK/h1" >/dev/null 2>&1
[ ! -e "$REC/launched" ] && ok "focused task incurs NO child relaunch" || no "focused task relaunched a child"

# ECC handoff: launch child, preserve prompt+cwd+guard, surface result, restore focused
MB="$WORK/h2/bin"; REC="$WORK/h2/rec"; PH="$WORK/h2/home"; mkbin "$MB" "$REC"; seed_home "$PH"
CWD="$WORK/h2/work"; mkdir -p "$CWD"
OUT="$(run_handoff "please add ed25519 ecc support" "$CWD" 2>/dev/null)"; EC=$?
[ -e "$REC/launched" ] && ok "ECC task launches a specialist child" || no "ECC task did not launch child"
grep -q '^please add ed25519 ecc support$' "$REC/prompt" 2>/dev/null && ok "ECC handoff preserves the exact original prompt in stdin" || no "ECC prompt not preserved"
[ "$(cat "$REC/argc" 2>/dev/null)" = "1" ] && ok "ECC prompt is not exposed in child argv" || no "ECC prompt leaked into child argv"
[ "$(cat "$REC/pwd" 2>/dev/null)" = "$CWD" ] && ok "ECC handoff preserves the original working directory" || no "ECC cwd not preserved"
[ "$(cat "$REC/guard" 2>/dev/null)" = "ecc" ] && ok "ECC child carries recursion-guard env" || no "ECC child missing guard env"
grep -q "MOCK_CHILD_OUTPUT" <<<"$OUT" && ok "ECC handoff surfaces the child result" || no "ECC child result not surfaced"
[ "$EC" = "0" ] && ok "ECC handoff exit status reflects child success" || no "ECC exit status wrong ($EC)"
is_focused && ok "ECC handoff restores focused mode afterward" || no "ECC handoff did not restore focused"
[ -s "$REC/handoffs.log" ] && ok "handoff writes an auditable receipt line" || no "handoff receipt log missing"

# zeroize handoff + single-Serena invariant after restore
MB="$WORK/h3/bin"; REC="$WORK/h3/rec"; PH="$WORK/h3/home"; mkbin "$MB" "$REC"; seed_home "$PH"
run_handoff "zeroize the secret buffers" "$WORK/h3" >/dev/null 2>&1
{ [ -e "$REC/launched" ] && [ "$(cat "$REC/guard")" = "zeroize" ]; } && ok "zeroize task launches its specialist child" || no "zeroize handoff wrong"
python3 - "$PH/.claude/settings.json" "$PH/.claude.json" <<'PY' && ok "single-Serena invariant holds after zeroize handoff" || no "single-Serena invariant broken"
import json,sys
s=json.load(open(sys.argv[1])); c=json.load(open(sys.argv[2]))
assert s["enabledPlugins"]["zeroize-audit@trailofbits"] is False
assert list(c["mcpServers"]).count("serena") == 1
PY

# recursion guard: a child (guard already set) must NOT hand off again
MB="$WORK/h4/bin"; REC="$WORK/h4/rec"; PH="$WORK/h4/home"; mkbin "$MB" "$REC"; seed_home "$PH"
BUILD_OS_SPECIALIST_HANDOFF="ecc" run_handoff "add ed25519 ecc support" "$WORK/h4" >/dev/null 2>&1
[ ! -e "$REC/launched" ] && ok "recursion guard prevents a child from re-handing-off" || no "recursion guard failed"

# cleanup on child FAILURE: non-zero surfaced (not silent) + focused restored
MB="$WORK/h5/bin"; REC="$WORK/h5/rec"; PH="$WORK/h5/home"; mkbin "$MB" "$REC"; seed_home "$PH"
OUT="$(MOCK_CLAUDE_EXIT=7 run_handoff "add ecc ed25519" "$WORK/h5" 2>&1)"; EC=$?
[ "$EC" != "0" ] && ok "child failure surfaced with non-zero exit (not silent)" || no "child failure reported as success"
grep -qiE "fail|error|exit" <<<"$OUT" && ok "child failure prints an actionable message" || no "no actionable failure message"
is_focused && ok "focused restored even when the child fails" || no "focused not restored on child failure"

# timeout: overrunning child killed, focused restored
MB="$WORK/h6/bin"; REC="$WORK/h6/rec"; PH="$WORK/h6/home"; mkbin "$MB" "$REC"; seed_home "$PH"
OUT="$(MOCK_CLAUDE_SLEEP=5 HANDOFF_TIMEOUT=1 run_handoff "add ecc support" "$WORK/h6" 2>&1)"; EC=$?
{ [ "$EC" != "0" ] && grep -qiE "timeout|timed out" <<<"$OUT"; } && ok "child timeout enforced + reported" || no "timeout not enforced/reported (ec=$EC)"
is_focused && ok "focused restored after a timeout" || no "focused not restored after timeout"

# dry-run: classify + report, NO relaunch, NO profile change
MB="$WORK/h7/bin"; REC="$WORK/h7/rec"; PH="$WORK/h7/home"; mkbin "$MB" "$REC"; seed_home "$PH"
DOUT="$(MOCK_REC="$REC" CLAUDE_BIN="$MB/claude" CAPABILITY_PROFILE_BIN="$PROFILE" CLAUDE_USER_DIR="$PH/.claude" CLAUDE_CONFIG_PATH="$PH/.claude.json" bash "$HANDOFF" --dry-run "add ed25519 ecc support" 2>&1)"
{ [ ! -e "$REC/launched" ] && grep -qi "ecc" <<<"$DOUT"; } && ok "dry-run reports route without relaunch" || no "dry-run relaunched or misreported"
is_focused && ok "dry-run does not change the active profile" || no "dry-run changed the profile"

# integration: prompt-entry hook wires in automatic detection
grep -q "specialist-handoff.sh" "$SRC/.claude/hooks/prompt-router.sh" && ok "prompt-router hook wires in specialist-handoff detection" || no "prompt-router hook does not wire in handoff detection"

echo "== 15. P-014 addendum: profile transitions preserve unrelated host capabilities =="
PPH="$WORK/preserve/home"; mkdir -p "$PPH/.claude"
cat > "$PPH/.claude/settings.json" <<'JSON'
{ "enabledPlugins": { "ui-ux-pro-max@ui-ux-pro-max": true, "claude-hud@claude-hud": true }, "skillListingBudgetFraction": 0.18 }
JSON
cat > "$PPH/.claude.json" <<'JSON'
{ "mcpServers": { "21st-dev": {"command":"21st"}, "claude-watch": {"command":"cw"}, "agent-reach": {"command":"ar"} } }
JSON
preserved_ok=1
for prof in focused ecc zeroize focused; do
  CLAUDE_USER_DIR="$PPH/.claude" CLAUDE_CONFIG_PATH="$PPH/.claude.json" bash "$PROFILE" "$prof" >/dev/null 2>&1
  python3 - "$PPH/.claude/settings.json" "$PPH/.claude.json" <<'PY' || preserved_ok=0
import json,sys
s=json.load(open(sys.argv[1])); c=json.load(open(sys.argv[2]))
assert s["enabledPlugins"].get("ui-ux-pro-max@ui-ux-pro-max") is True
assert s["enabledPlugins"].get("claude-hud@claude-hud") is True
for k in ("21st-dev","claude-watch","agent-reach"):
    assert k in c["mcpServers"], k
PY
done
[ "$preserved_ok" = 1 ] && ok "focused/ecc/zeroize transitions preserve 21st.dev, Claude Watch, Agent Reach, UI UX Pro Max" || no "a profile transition dropped an unrelated capability"
for cap in "21st.dev" "Claude Watch" "Agent Reach" "UI UX Pro Max"; do
  have "$ROUTER" "$cap" && ok "router routes to: $cap" || no "router missing capability: $cap"
done

echo "== 16. P-015: global install ships specialist tools so the installed hook can hand off =="
# Regression: install-global.sh must place specialist-handoff.sh + capability-profile.sh
# under ~/build-os/tools so the globally installed prompt-router.sh can RESOLVE and INVOKE
# the handoff. Before the fix only ~/build-os/memory existed, so a global-hook ECC prompt
# produced the routing reminder and no handoff. Install into temp CLAUDE_USER_DIR +
# BUILD_OS_USER_DIR under a temp HOME (so ~/build-os == the install target, matching a real
# global install), then prove the installed hook drives a specialist child end-to-end.
P15_HOME="$WORK/p015-home"; P15_TMP="$WORK/p015-tmp"; mkdir -p "$P15_TMP"
P15_BIN="$WORK/p015-bin"; P15_REC="$WORK/p015-rec"
mkbin "$P15_BIN" "$P15_REC"          # reuse the mock `claude` from section 14
HOME="$P15_HOME" CLAUDE_USER_DIR="$P15_HOME/.claude" BUILD_OS_USER_DIR="$P15_HOME/build-os" \
  bash "$SRC/install-global.sh" >/dev/null 2>&1
P15_TOOLS="$P15_HOME/build-os/tools"
[ -d "$P15_TOOLS" ] && ok "install-global creates ~/build-os/tools" || no "install-global did not create ~/build-os/tools"
for t in specialist-handoff.sh capability-profile.sh; do
  { [ -f "$P15_TOOLS/$t" ] && [ -x "$P15_TOOLS/$t" ]; } && ok "global install ships executable $t" || no "global install missing/non-exec $t"
  cmp -s "$SRC/build-os/tools/$t" "$P15_TOOLS/$t" && ok "installed $t is byte-identical to source" || no "installed $t differs from source"
done
# Deterministic focused baseline for the COPIED capability-profile to switch from.
mkdir -p "$P15_HOME/.claude"
printf '{"enabledPlugins":{},"skillListingBudgetFraction":0.18}\n' > "$P15_HOME/.claude/settings.json"
printf '{"mcpServers":{"keep-me":{"command":"keep"}}}\n' > "$P15_HOME/.claude.json"
CLAUDE_USER_DIR="$P15_HOME/.claude" CLAUDE_CONFIG_PATH="$P15_HOME/.claude.json" bash "$P15_TOOLS/capability-profile.sh" focused >/dev/null 2>&1
# End-to-end: the INSTALLED hook + an ECC prompt must resolve + run the installed handoff.
# MOCK_CHILD_OUTPUT can only appear if the hook found specialist-handoff.sh AND it found its
# sibling capability-profile.sh (else activate_profile fails and no child launches).
P15_PAYLOAD='{"hook_event_name":"UserPromptSubmit","prompt":"please add ed25519 ecc signing support","cwd":"'"$P15_HOME"'"}'
HOUT="$(printf '%s' "$P15_PAYLOAD" | HOME="$P15_HOME" TMPDIR="$P15_TMP" MOCK_REC="$P15_REC" \
  CLAUDE_BIN="$P15_BIN/claude" HANDOFF_TIMEOUT=30 HANDOFF_LOG="$P15_REC/handoffs.log" \
  bash "$P15_HOME/.claude/hooks/prompt-router.sh" 2>&1)"
grep -q "MOCK_CHILD_OUTPUT route=ecc" <<<"$HOUT" && ok "installed global hook resolves + runs the handoff (ECC child launched via copied tools)" || no "installed global hook did not find/run the handoff tool"
grep -q "explicitly completed this task" <<<"$HOUT" && ok "installed hook emits the specialist-handoff completion wrapper" || no "installed hook fell back to routing reminder only"
PH="$P15_HOME"; is_focused && ok "installed hook restores focused after the handoff (copied capability-profile works)" || no "installed hook left the profile non-focused"
# Negative control: a focused prompt through the SAME installed hook must NOT hand off.
FOUT="$(printf '%s' '{"hook_event_name":"UserPromptSubmit","prompt":"list the files in this repo","cwd":"'"$P15_HOME"'"}' \
  | HOME="$P15_HOME" TMPDIR="$P15_TMP" MOCK_REC="$P15_REC" CLAUDE_BIN="$P15_BIN/claude" \
  bash "$P15_HOME/.claude/hooks/prompt-router.sh" 2>&1)"
grep -q "MOCK_CHILD_OUTPUT" <<<"$FOUT" && no "focused prompt spuriously launched a specialist child" || ok "focused prompt through the installed hook does not hand off"

echo "== 17. P-016: capability registry — task-family classification (precedence, conservative) =="
cls() { bash "$HANDOFF" classify "$1" 2>/dev/null; }
# ECC (Everything Claude Code) specialist families that previously misrouted focused
[ "$(cls 'review my Rust code for ownership and unsafe usage')" = ecc ]                 && ok "Rust ownership/unsafe -> ecc"        || no "Rust ownership/unsafe route"
[ "$(cls 'debug a Go concurrency deadlock in the goroutine scheduler')" = ecc ]         && ok "Go concurrency/debug -> ecc"         || no "Go concurrency route"
[ "$(cls 'optimize this PostgreSQL schema and slow query plan')" = ecc ]                && ok "PostgreSQL schema/query -> ecc"      || no "Postgres route"
[ "$(cls 'build an autonomous agent eval harness with benchmarks')" = ecc ]             && ok "autonomous-agent harness/evals -> ecc" || no "agent-harness route"
[ "$(cls 'do an architecture review of our distributed microservice system')" = ecc ]  && ok "architecture specialist -> ecc"      || no "architecture route"
[ "$(cls 'set up a Chrome DevTools browser automation session')" = ecc ]                && ok "browser specialist -> ecc"           || no "browser route"
[ "$(cls 'implement ed25519 signing')" = ecc ]                                          && ok "ed25519 crypto still -> ecc"         || no "ed25519 route regressed"
# Conservative: ordinary lightweight tasks stay focused (no relaunch)
[ "$(cls 'fix a typo in the Rust README')" = focused ]                                  && ok "trivial Rust doc edit stays focused" || no "trivial Rust edit misrouted"
[ "$(cls 'list the go source files')" = focused ]                                       && ok "listing go files stays focused"      || no "listing go files misrouted"
[ "$(cls 'what port does postgres listen on')" = focused ]                              && ok "postgres factual question stays focused" || no "postgres question misrouted"
[ "$(cls 'please refactor the build script')" = focused ]                               && ok "ordinary refactor stays focused"     || no "ordinary refactor misrouted"
# Zeroize expanded natural-language coverage + highest precedence
[ "$(cls 'check whether API keys remain in memory after use')" = zeroize ]              && ok "zeroize NL: keys remain in memory"   || no "zeroize NL keys-in-memory"
[ "$(cls 'verify secrets are cleared from registers and the stack')" = zeroize ]        && ok "zeroize NL: cleared from registers/stack" || no "zeroize NL registers/stack"
[ "$(cls 'zeroize the ed25519 private key material')" = zeroize ]                       && ok "zeroize outranks ecc (precedence)"   || no "zeroize precedence"
# Inline surface routes -> distinct tokens
[ "$(cls 'find a shadcn button component from 21st.dev')" = 21st ]                       && ok "21st.dev component discovery -> 21st" || no "21st route"
[ "$(cls 'research what people say about this on Reddit and Twitter')" = agent-reach ]  && ok "web research -> agent-reach"         || no "agent-reach route"
[ "$(cls 'supervise this long-running overnight build with Claude Watch')" = claude-watch ] && ok "long-running supervision -> claude-watch" || no "claude-watch route"
[ "$(cls 'design the UI/UX for the new dashboard screen')" = ui-ux-pro-max ]            && ok "UI/UX design -> ui-ux-pro-max"       || no "ui-ux route"

echo "== 18. P-016: inline routing — REQUIRED directive, no child, no profile switch =="
MB="$WORK/i1/bin"; REC="$WORK/i1/rec"; PH="$WORK/i1/home"; mkbin "$MB" "$REC"; seed_home "$PH"
for spec in "21st^find a shadcn component from 21st.dev^21st.dev" \
            "agent-reach^research this topic on reddit and twitter^Agent Reach" \
            "claude-watch^supervise this long-running overnight run with claude watch^Claude Watch" \
            "ui-ux-pro-max^design the ui/ux of the settings screen^UI UX Pro Max"; do
  route="${spec%%^*}"; rest="${spec#*^}"; iprompt="${rest%%^*}"; iname="${rest##*^}"
  IOUT="$(MOCK_REC="$REC" CLAUDE_BIN="$MB/claude" CAPABILITY_PROFILE_BIN="$PROFILE" \
    CLAUDE_USER_DIR="$PH/.claude" CLAUDE_CONFIG_PATH="$PH/.claude.json" \
    HANDOFF_LOG="$REC/inline.log" HANDOFF_LOCK="$REC/$route.lock" \
    bash "$HANDOFF" detect "$iprompt" "$PH" 2>&1)"
  grep -qi "INLINE CANDIDATE" <<<"$IOUT"         && ok "inline $route emits an availability-aware directive" || no "inline $route missing availability-aware directive"
  grep -qiF "$iname" <<<"$IOUT"                   && ok "inline $route names the capability ($iname)"     || no "inline $route missing capability name"
  [ ! -e "$REC/launched" ]                        && ok "inline $route launches NO child"                || no "inline $route launched a child"
done
is_focused && ok "inline routes leave the profile focused (no capability-profile switch)" || no "inline route changed the profile"
grep -q "route=21st" "$REC/inline.log"  && ok "inline route is logged by route" || no "inline route not logged"
grep -qi "shadcn" "$REC/inline.log"     && no "inline log leaked prompt text"   || ok "inline log has no prompt text"
# prompt-router must NOT claim a specialist child handled an inline route
mkdir -p "$WORK/i2tmp"; PRH="$WORK/i2home"; mkdir -p "$PRH/.claude"
printf '{"enabledPlugins":{},"skillListingBudgetFraction":0.18}\n' > "$PRH/.claude/settings.json"
printf '{"mcpServers":{"keep-me":{"command":"keep"}}}\n' > "$PRH/.claude.json"
CLAUDE_USER_DIR="$PRH/.claude" CLAUDE_CONFIG_PATH="$PRH/.claude.json" bash "$PROFILE" focused >/dev/null 2>&1
PRPAYLOAD='{"hook_event_name":"UserPromptSubmit","prompt":"find a shadcn component from 21st.dev","cwd":"'"$PRH"'"}'
PROUT="$(printf '%s' "$PRPAYLOAD" | HOME="$PRH" TMPDIR="$WORK/i2tmp" bash "$PROMPT_HOOK" 2>&1)"
grep -qiE "REQUIRED|inline" <<<"$PROUT"          && ok "prompt-router emits the inline directive for 21st" || no "prompt-router missing inline directive"
grep -qi "already handled this task" <<<"$PROUT" && no "prompt-router falsely claims a child handled an inline route" || ok "prompt-router does not claim a child for inline routes"

echo "== 19. P-016: handoff audit log is privacy-safe (no prompt/cwd) + 0600 =="
logmode() { perl -e 'printf "%o", (stat($ARGV[0]))[2] & 07777' "$1" 2>/dev/null; }
MB="$WORK/pv/bin"; REC="$WORK/pv/rec"; PH="$WORK/pv/home"; mkbin "$MB" "$REC"; seed_home "$PH"
PVLOG="$REC/audit.log"; SECRET="xyzzy-secret-prompt-marker"; CWDMARK="$WORK/pv/zzcwdmark"; mkdir -p "$CWDMARK"
MOCK_REC="$REC" CLAUDE_BIN="$MB/claude" CAPABILITY_PROFILE_BIN="$PROFILE" \
  CLAUDE_USER_DIR="$PH/.claude" CLAUDE_CONFIG_PATH="$PH/.claude.json" \
  HANDOFF_LOG="$PVLOG" HANDOFF_LOCK="$REC/l.lock" HANDOFF_TIMEOUT=30 \
  bash "$HANDOFF" detect "add ed25519 ecc support $SECRET" "$CWDMARK" >/dev/null 2>&1
[ -s "$PVLOG" ]                    && ok "handoff writes an audit line"        || no "audit log empty"
grep -qF "$SECRET" "$PVLOG"        && no "audit log leaked prompt text"        || ok "audit log has NO prompt text"
grep -qF "$CWDMARK" "$PVLOG"       && no "audit log leaked cwd path"           || ok "audit log has NO cwd path"
grep -q "route=ecc" "$PVLOG"       && ok "audit log records the route"         || no "audit log missing route"
grep -qE "exit=[0-9]+" "$PVLOG"    && ok "audit log records the exit status"   || no "audit log missing exit"
[ "$(logmode "$PVLOG")" = 600 ]    && ok "audit log mode is 0600"              || no "audit log mode is $(logmode "$PVLOG") (want 600)"
PVLOG2="$REC/pre.log"; printf 'PREEXISTING-LEAK old prompt content\n' > "$PVLOG2"; chmod 644 "$PVLOG2"
MOCK_REC="$REC" CLAUDE_BIN="$MB/claude" CAPABILITY_PROFILE_BIN="$PROFILE" \
  CLAUDE_USER_DIR="$PH/.claude" CLAUDE_CONFIG_PATH="$PH/.claude.json" \
  HANDOFF_LOG="$PVLOG2" HANDOFF_LOCK="$REC/l2.lock" HANDOFF_TIMEOUT=30 \
  bash "$HANDOFF" detect "zeroize the secret buffers now" "$PH" >/dev/null 2>&1
[ "$(logmode "$PVLOG2")" = 600 ]   && ok "pre-existing 0644 log tightened to 0600" || no "pre-existing log mode is $(logmode "$PVLOG2") (want 600)"
grep -q "route=zeroize" "$PVLOG2"  && ok "privacy-safe line appended to pre-existing log" || no "no new line appended to pre-existing log"

echo "== 20. P-016: atomic profile lock — BUSY/no-mutation, stale break, release on exit =="
MB="$WORK/lk/bin"; REC="$WORK/lk/rec"; PH="$WORK/lk/home"; mkbin "$MB" "$REC"; seed_home "$PH"
LK="$REC/profile.lock"; SUM_BEFORE="$(cat "$PH/.claude/settings.json" "$PH/.claude.json" | cksum)"
sleep 30 & LIVE=$!
mkdir -p "$LK"; printf '%s\n' "$LIVE" > "$LK/pid"
BOUT="$(MOCK_REC="$REC" CLAUDE_BIN="$MB/claude" CAPABILITY_PROFILE_BIN="$PROFILE" \
  CLAUDE_USER_DIR="$PH/.claude" CLAUDE_CONFIG_PATH="$PH/.claude.json" \
  HANDOFF_LOG="$REC/l.log" HANDOFF_LOCK="$LK" HANDOFF_LOCK_WAIT=1 HANDOFF_TIMEOUT=30 \
  bash "$HANDOFF" detect "add ed25519 ecc support" "$PH" 2>&1)"; BEC=$?
kill "$LIVE" 2>/dev/null; wait "$LIVE" 2>/dev/null
[ "$BEC" != 0 ]                    && ok "held lock -> nonzero exit"           || no "held lock exit was 0"
grep -qi "busy" <<<"$BOUT"         && ok "held lock -> BUSY result"            || no "held lock did not report BUSY"
[ ! -e "$REC/launched" ]           && ok "held lock -> NO child launched"      || no "held lock launched a child"
SUM_AFTER="$(cat "$PH/.claude/settings.json" "$PH/.claude.json" | cksum)"
[ "$SUM_BEFORE" = "$SUM_AFTER" ]   && ok "held lock -> NO profile mutation"    || no "held lock mutated the profile"
rm -rf "$LK"
MB="$WORK/lk2/bin"; REC="$WORK/lk2/rec"; PH="$WORK/lk2/home"; mkbin "$MB" "$REC"; seed_home "$PH"
LK2="$REC/profile.lock"; mkdir -p "$LK2"; printf '2147483647\n' > "$LK2/pid"
MOCK_REC="$REC" CLAUDE_BIN="$MB/claude" CAPABILITY_PROFILE_BIN="$PROFILE" \
  CLAUDE_USER_DIR="$PH/.claude" CLAUDE_CONFIG_PATH="$PH/.claude.json" \
  HANDOFF_LOG="$REC/l.log" HANDOFF_LOCK="$LK2" HANDOFF_LOCK_WAIT=2 HANDOFF_TIMEOUT=30 \
  bash "$HANDOFF" detect "add ed25519 ecc support" "$PH" >/dev/null 2>&1
[ -e "$REC/launched" ]             && ok "stale lock broken -> handoff proceeds (child launched)" || no "stale lock not broken"
is_focused                         && ok "focused restored after stale-lock handoff" || no "focused not restored after stale-lock"
[ ! -d "$LK2" ]                    && ok "lock released on exit (stale case)"  || no "lock not released (stale case)"
MB="$WORK/lk3/bin"; REC="$WORK/lk3/rec"; PH="$WORK/lk3/home"; mkbin "$MB" "$REC"; seed_home "$PH"
LK3="$REC/profile.lock"
MOCK_REC="$REC" CLAUDE_BIN="$MB/claude" CAPABILITY_PROFILE_BIN="$PROFILE" \
  CLAUDE_USER_DIR="$PH/.claude" CLAUDE_CONFIG_PATH="$PH/.claude.json" \
  HANDOFF_LOG="$REC/l.log" HANDOFF_LOCK="$LK3" HANDOFF_TIMEOUT=30 \
  bash "$HANDOFF" detect "add ed25519 ecc support" "$PH" >/dev/null 2>&1
[ ! -d "$LK3" ]                    && ok "lock released on exit (normal handoff)" || no "lock not released (normal handoff)"

echo "== 21. P-016: surface-aware inventory + enabled-vs-installed skill budget =="
have "$ROUTER" "Claude Desktop"            && ok "router names the Claude Desktop surface"       || no "router omits Desktop surface"
grep -qi "claude mcp list" "$ROUTER"       && ok "router references the local CLI (claude mcp list)" || no "router omits local CLI surface"
grep -qi "host-reported" "$ROUTER"         && no "router still uses stale host-reported language" || ok "router drops stale host-reported language"
grep -qi "v0.4.1" "$ROUTER"                && ok "router records Claude Watch version evidence"  || no "router missing Claude Watch version"
grep -qi "v2.11.0" "$ROUTER"               && ok "router records UI UX Pro Max version evidence" || no "router missing UI UX Pro Max version"
for cap in "21st.dev" "Claude Watch" "Agent Reach" "UI UX Pro Max"; do
  have "$ROUTER" "$cap" && ok "router still routes: $cap" || no "router dropped capability: $cap"
done
# skill-budget-audit: enabled-vs-installed separation; a disabled mega-bundle must NOT make startup OVER BUDGET
CBD="$WORK/claudedir"; mkdir -p "$CBD/plugins"
mkdir -p "$CBD/plugins/marketplaces/mkt/big/skills/dup"     # marketplace copy (must NOT be double-counted)
printf 'name: dup\ndescription: d\n' > "$CBD/plugins/marketplaces/mkt/big/skills/dup/SKILL.md"
BIGCACHE="$CBD/plugins/cache/mkt/big/1.0.0"; mkdir -p "$BIGCACHE/skills/dup"
printf 'name: dup\ndescription: d\n' > "$BIGCACHE/skills/dup/SKILL.md"                 # same skill, cache copy (installPath)
for i in 1 2 3 4 5 6 7 8 9 10; do mkdir -p "$BIGCACHE/skills/big$i"; printf 'name: big%s\ndescription: %s\n' "$i" "$(head -c 4000 </dev/zero | tr '\0' x)" > "$BIGCACHE/skills/big$i/SKILL.md"; done
SMALLCACHE="$CBD/plugins/cache/mkt/small/1.0.0"; mkdir -p "$SMALLCACHE/skills/s1"
printf 'name: s1\ndescription: d\n' > "$SMALLCACHE/skills/s1/SKILL.md"
cat > "$CBD/settings.json" <<'JSON'
{ "enabledPlugins": { "small@mkt": true, "big@mkt": false } }
JSON
# REAL host schema (P-016 correction): each plugins[name] is a LIST of install records
# [{scope,user,installPath,...}]. big@mkt carries a stale project record + the real user
# record to prove the parser prefers the current-user record and de-dupes.
cat > "$CBD/plugins/installed_plugins.json" <<JSON
{ "plugins": {
  "big@mkt":   [ { "scope": "project", "installPath": "$CBD/plugins/nonexistent-stale" },
                 { "scope": "user", "user": "sam", "installPath": "$BIGCACHE" } ],
  "small@mkt": [ { "scope": "user", "user": "sam", "installPath": "$SMALLCACHE" } ]
} }
JSON
EOUT="$(bash "$AUDIT" --claude-dir "$CBD" 5000 2>/dev/null)"
grep -qi "installed inventory" <<<"$EOUT"                 && ok "audit reports installed inventory separately"        || no "audit missing installed inventory line"
grep -qiE "startup[- ]enabled" <<<"$EOUT"                 && ok "audit reports the startup-enabled set separately"    || no "audit missing startup-enabled line"
grep -qE "installed inventory:[[:space:]]*12 " <<<"$EOUT" && ok "list-schema installed inventory de-dupes + prefers user record (12 skills)" || no "list-schema installed inventory count wrong"
grep -qE "startup[- ]enabled:[[:space:]]*1 " <<<"$EOUT"   && ok "startup set counts only enabled plugins (1 skill)"   || no "startup-enabled count wrong"
grep -qiE "startup metadata status:.*unknown" <<<"$EOUT"  && ok "audit does not infer startup metadata cost from full bodies" || no "startup metadata verdict is not evidence-qualified"
grep -qE "installed inventory:[[:space:]]*0 " <<<"$EOUT"  && no "list schema parsed as ZERO (real-host defect)" || ok "list-schema installed inventory is nonzero (real-host defect fixed)"
# backward-compat: the legacy DICT schema still parses to the same counts
cat > "$CBD/plugins/installed_plugins.json" <<JSON
{ "plugins": {
  "big@mkt":   { "installPath": "$BIGCACHE" },
  "small@mkt": { "installPath": "$SMALLCACHE" }
} }
JSON
DOUT="$(bash "$AUDIT" --claude-dir "$CBD" 5000 2>/dev/null)"
grep -qE "installed inventory:[[:space:]]*12 " <<<"$DOUT" && ok "dict-schema installed inventory still 12 (both schemas supported)" || no "dict-schema installed inventory regressed"
grep -qE "startup[- ]enabled:[[:space:]]*1 " <<<"$DOUT"   && ok "dict-schema startup set still 1" || no "dict-schema startup count regressed"

echo "== 22. P-017: adversarial completion, fallback, lock, and output controls =="
# Exit zero without an explicit COMPLETED marker is not handled.
MB="$WORK/p17u/bin"; REC="$WORK/p17u/rec"; PH="$WORK/p17u/home"; mkbin "$MB" "$REC"; seed_home "$PH"
UOUT="$(MOCK_TERMINAL_STATUS=NEEDS_INPUT run_handoff "review Rust unsafe ownership code" "$PH" 2>&1)"; UEC=$?
{ [ "$UEC" != 0 ] && grep -q "NEEDS_INPUT" <<<"$UOUT"; } && ok "exit-zero NEEDS_INPUT is not treated as completion" || no "semantic completion check failed"
is_focused && ok "focused restored after NEEDS_INPUT" || no "focused not restored after NEEDS_INPUT"

# The prompt hook must never claim a failed specialist completed the task.
mkdir -p "$WORK/p17hooktmp"; HPAY='{"hook_event_name":"UserPromptSubmit","prompt":"review Rust unsafe ownership code","cwd":"/tmp","prompt_id":"p17-fail"}'
HFAIL="$(printf '%s' "$HPAY" | TMPDIR="$WORK/p17hooktmp" CLAUDE_BIN=/usr/bin/false CAPABILITY_PROFILE_BIN=/usr/bin/true bash "$PROMPT_HOOK" 2>&1)"
grep -q "not confirmed complete" <<<"$HFAIL" && ok "hook falls back to focused parent after child failure" || no "hook falsely suppresses parent after failure"
grep -q "already handled this task" <<<"$HFAIL" && no "hook falsely claims failed child handled task" || ok "hook makes no false handled claim"

# A malicious broad lock override is rejected and never removed.
mkdir -p "$WORK/p17-lock-target"; printf 'keep\n' > "$WORK/p17-lock-target/keep"
LOUT="$(HANDOFF_LOCK=/ HANDOFF_LOCK_WAIT=0 CLAUDE_BIN=/usr/bin/false CAPABILITY_PROFILE_BIN=/usr/bin/true bash "$HANDOFF" detect "review Rust unsafe ownership code" /tmp 2>&1)"; LEC=$?
{ [ "$LEC" != 0 ] && [ -f "$WORK/p17-lock-target/keep" ]; } && ok "unsafe lock override rejected without deletion" || no "unsafe lock override handling failed"

# Inline routes are availability-conditional and provide a fallback.
I17="$(bash "$HANDOFF" detect "find a shadcn component from 21st.dev" /tmp 2>&1)"
{ grep -qi "verify.*connected" <<<"$I17" && grep -qi "fallback" <<<"$I17"; } && ok "inline directive is availability-conditional with fallback" || no "inline directive overclaims availability"
grep -qi "REQUIRED: use" <<<"$I17" && no "inline directive still unconditionally requires unavailable tool" || ok "inline directive makes no unconditional availability claim"

# Child output is bounded.
MB="$WORK/p17o/bin"; REC="$WORK/p17o/rec"; PH="$WORK/p17o/home"; mkbin "$MB" "$REC"; seed_home "$PH"
OOUT="$(MOCK_CHILD_OUTPUT="$(head -c 5000 </dev/zero | tr '\0' x)" HANDOFF_OUTPUT_MAX=200 run_handoff "review Rust unsafe ownership code" "$PH" 2>&1)" || true
grep -q "OUTPUT TRUNCATED" <<<"$OOUT" && ok "oversized child output is visibly truncated" || no "child output was not bounded"

echo "== 23. P-018: final-line terminal contract + capture-time bound =="
MB="$WORK/p18s/bin"; REC="$WORK/p18s/rec"; PH="$WORK/p18s/home"; mkbin "$MB" "$REC"; seed_home "$PH"
SOUT="$(MOCK_AFTER_STATUS='I still need the source code.' run_handoff "review Rust unsafe ownership code" "$PH" 2>&1)"; SEC=$?
{ [ "$SEC" != 0 ] && grep -q "UNCONFIRMED" <<<"$SOUT"; } && ok "COMPLETED marker followed by text is rejected" || no "terminal-marker spoof accepted"
is_focused && ok "focused restored after terminal spoof" || no "focused not restored after terminal spoof"
MB="$WORK/p18b/bin"; REC="$WORK/p18b/rec"; PH="$WORK/p18b/home"; mkbin "$MB" "$REC"; seed_home "$PH"
# 200KB generated IN-CHILD (portable; proves the real capture-time bound on Linux + macOS).
BOUT="$(MOCK_GEN_BYTES=200000 HANDOFF_OUTPUT_MAX=1024 run_handoff "review Rust unsafe ownership code" "$PH" 2>&1)" || true
{ grep -q "OUTPUT TRUNCATED at 1024" <<<"$BOUT" && [ "${#BOUT}" -lt 2500 ]; } && ok "large in-child output is hard-bounded at capture time" || no "capture-time bound failed"
# Streaming variant: continuous multi-chunk output (~245KB over ~1.2s) is bounded the same way.
MB="$WORK/p18t/bin"; REC="$WORK/p18t/rec"; PH="$WORK/p18t/home"; mkbin "$MB" "$REC"; seed_home "$PH"
TOUT="$(MOCK_STREAM_CHUNKS=60 HANDOFF_OUTPUT_MAX=1024 HANDOFF_TIMEOUT=30 run_handoff "review Rust unsafe ownership code" "$PH" 2>&1)" || true
{ grep -q "OUTPUT TRUNCATED at 1024" <<<"$TOUT" && [ "${#TOUT}" -lt 2500 ]; } && ok "streaming child output is hard-bounded at capture time" || no "streaming capture-time bound failed"

echo "== 24. P-020: bootstrap registers pinned Serena add-if-absent (no duplicate) =="
ACC="$SRC/install-accelerators.sh"; SERPIN="68884f1190489685082dc3c3b56917e92a1de0e6"
RD="$WORK/serena-reg"; mkdir -p "$RD"
# A) no config file -> creates it with the pinned uvx Serena (no secret, no network)
CLAUDE_CONFIG_PATH="$RD/none.json" bash "$ACC" register-serena >/dev/null 2>&1
python3 - "$RD/none.json" "$SERPIN" <<'PY' && ok "registers pinned Serena when config is absent" || no "did not register Serena when config absent"
import json,sys
s=json.load(open(sys.argv[1]))["mcpServers"]["serena"]
assert s["command"]=="uvx" and sys.argv[2] in " ".join(s["args"])
PY
# B) existing config -> adds Serena while preserving every other key
printf '{"mcpServers":{"keep-me":{"command":"keep"}},"otherKey":123}\n' > "$RD/empty.json"
CLAUDE_CONFIG_PATH="$RD/empty.json" bash "$ACC" register-serena >/dev/null 2>&1
python3 - "$RD/empty.json" <<'PY' && ok "registers Serena while preserving unrelated config" || no "registration dropped unrelated config"
import json,sys
d=json.load(open(sys.argv[1]))
assert "serena" in d["mcpServers"] and d["mcpServers"]["keep-me"]["command"]=="keep" and d["otherKey"]==123
PY
# C) Serena already present -> byte-identical no-op (single-server rule; never overwrite/duplicate)
printf '{"mcpServers":{"serena":{"command":"EXISTING","args":["do-not-touch"]}}}\n' > "$RD/has.json"
SBEF="$(cksum < "$RD/has.json")"
CLAUDE_CONFIG_PATH="$RD/has.json" bash "$ACC" register-serena >/dev/null 2>&1
SAFT="$(cksum < "$RD/has.json")"
python3 - "$RD/has.json" <<'PY' && ok "existing Serena is left untouched (no overwrite, exactly one)" || no "overwrote/duplicated an existing Serena"
import json,sys
d=json.load(open(sys.argv[1]))
assert d["mcpServers"]["serena"]["command"]=="EXISTING" and list(d["mcpServers"]).count("serena")==1
PY
[ "$SBEF" = "$SAFT" ] && ok "add-if-absent is a byte-identical no-op when Serena present" || no "registration mutated an existing-Serena config"
# D) idempotent: a second run on the just-registered config keeps exactly one Serena
CLAUDE_CONFIG_PATH="$RD/empty.json" bash "$ACC" register-serena >/dev/null 2>&1
python3 - "$RD/empty.json" <<'PY' && ok "repeated registration does not duplicate Serena" || no "repeated registration duplicated Serena"
import json,sys
assert list(json.load(open(sys.argv[1]))["mcpServers"]).count("serena")==1
PY
# E) project .mcp.json stays Serena-free (nothing double-launches on the Mac's user-scope server)
python3 - "$SRC/.mcp.json" <<'PY' && ok "project .mcp.json stays Serena-free (no double-launch)" || no "project .mcp.json now registers Serena"
import json,sys
raise SystemExit(1 if "serena" in json.load(open(sys.argv[1])).get("mcpServers",{}) else 0)
PY

echo "== 25. P-021: Cloud-native long-running supervision fallback (claude-watch) =="
SUP="$SRC/build-os/tools/supervise.sh"
[ -x "$SUP" ] && ok "supervise.sh present + executable (Cloud-native; no plugin)" || no "supervise.sh missing/not executable"
# already-true condition -> COMPLETED (exit 0)
SUPO="$(bash "$SUP" --until "true" --interval 1 --timeout 5 2>&1)"; SEC=$?
{ [ "$SEC" = 0 ] && grep -q "SUPERVISE_STATUS: COMPLETED" <<<"$SUPO"; } && ok "supervise: satisfied condition -> COMPLETED (exit 0)" || no "supervise COMPLETED wrong (ec=$SEC)"
# never-true condition -> TIMEOUT (bounded, exit 124)
SUPO="$(bash "$SUP" --until "false" --interval 1 --timeout 1 2>&1)"; SEC=$?
{ [ "$SEC" = 124 ] && grep -q "SUPERVISE_STATUS: TIMEOUT" <<<"$SUPO"; } && ok "supervise: unmet condition -> TIMEOUT (exit 124, bounded)" || no "supervise TIMEOUT wrong (ec=$SEC)"
# condition becomes true DURING the watch -> COMPLETED
SUPMARK="$WORK/sup-done-$RANDOM"; rm -f "$SUPMARK"; ( sleep 1; : > "$SUPMARK" ) &
SUPO="$(bash "$SUP" --until "test -f '$SUPMARK'" --interval 1 --timeout 10 2>&1)"; SEC=$?
{ [ "$SEC" = 0 ] && grep -q "SUPERVISE_STATUS: COMPLETED" <<<"$SUPO"; } && ok "supervise: condition met during watch -> COMPLETED" || no "supervise did not detect condition change"
wait 2>/dev/null
# missing --until -> USAGE (exit 2)
bash "$SUP" >/dev/null 2>&1; [ "$?" = 2 ] && ok "supervise: missing --until -> USAGE (exit 2)" || no "supervise usage guard failed"
# routing truth: claude-watch names the Cloud-native supervision fallback + stays conditional
grep -qi "supervise.sh" "$ROUTER" && ok "router names the Cloud-native supervision fallback (supervise.sh)" || no "router omits supervise.sh fallback"
IWATCH="$(bash "$HANDOFF" detect "supervise this long-running overnight build with claude watch" /tmp 2>&1)"
grep -qi "supervise.sh" <<<"$IWATCH" && ok "claude-watch inline directive names the supervise.sh fallback" || no "claude-watch directive omits Cloud-native fallback"
{ grep -qi "verify that Claude Watch is connected" <<<"$IWATCH" && grep -qi "Do NOT claim" <<<"$IWATCH"; } && ok "claude-watch stays availability-conditional (no overclaim)" || no "claude-watch overclaims availability"

# ---------------------------------------------------------------------------
# CHAINED SUITE: the memory maintenance + safety layer's cold-install proof.
#
# WHY IT IS INVOKED HERE AND NOT MERELY POINTED AT FROM A DOC. A second suite
# that has to be REMEMBERED is a suite that gets skipped, and the layer it covers
# rewrites Build OS memory — the one thing in this repo where a silent regression
# is unrecoverable. A documentation-only pointer rots; an invoked suite cannot.
#
# THE COST WAS MEASURED BEFORE CHOOSING: this file ran ~11.5 s alone,
# tests/build_os_maintenance_tests.sh ~13.0 s alone, so chaining roughly doubles
# a wall time that is still well under half a minute. It is deterministic,
# offline, and confined to its own mktemp dirs, exactly like this file, so
# nothing about the combined run is less repeatable than the parts.
#
# ITS COUNTS ARE FOLDED INTO THIS FILE'S TOTALS rather than collapsed into a
# single pass/fail. One `ok` for "61 assertions passed" would report the same
# green if 60 of them silently stopped running.
echo "== 26. Chained sibling suites (cold-install, lanes, scaffold templates, release metadata, speed metrics) =="
# chain_suite <relative-path> <what-it-covers>
#
# Every sibling suite is invoked through this one function so the failure
# handling below is written once and cannot drift between call sites. A suite
# that dies before printing RESULT is one failure with its log named; a suite
# reporting zero failures while exiting non-zero is itself a failure, because
# the two disagree and the exit code is what the caller acts on.
chain_suite() {
  local rel="$1" covers="$2"
  local path="$SRC/$rel" log res spass sfail sec
  if [ ! -f "$path" ]; then
    no "$rel is missing — $covers has no executable proof"
    return
  fi
  log="$WORK/$(basename "$rel").log"
  # RELEASE_METADATA_IN_LIVE tells the release-metadata suite it is running
  # inside this file, so its opt-in live re-run cannot recurse into us.
  RELEASE_METADATA_IN_LIVE=1 bash "$path" > "$log" 2>&1
  sec=$?
  res="$(grep -E '^==== RESULT: [0-9]+ passed, [0-9]+ failed ====$' "$log" | tail -1)"
  if [ -z "$res" ]; then
    no "chained suite $rel produced no RESULT line (exit $sec) — see $log"
    tail -5 "$log" | sed 's/^/      | /'
    return
  fi
  spass="$(printf '%s' "$res" | sed -E 's/^==== RESULT: ([0-9]+) passed.*/\1/')"
  sfail="$(printf '%s' "$res" | sed -E 's/.* ([0-9]+) failed ====$/\1/')"
  PASS=$((PASS + spass)); FAIL=$((FAIL + sfail))
  echo "  CHAINED: $spass passed, $sfail failed ($rel)"
  [ "$sfail" -gt 0 ] && grep '^  FAIL: ' "$log" | sed 's/^  /      /'
  if [ "$sec" -ne 0 ] && [ "$sfail" -eq 0 ]; then
    no "chained suite $rel exited $sec while reporting 0 failures — see $log"
  fi
}

chain_suite "tests/build_os_maintenance_tests.sh" "the memory maintenance + safety layer"
chain_suite "tests/lane_enforcement_tests.sh"     "lane proportionality and fan-out"
chain_suite "tests/scaffold_seeding_tests.sh"     "customer scaffold seeding"
chain_suite "tests/release_metadata_tests.sh"     "version, license and changelog"
chain_suite "tests/speed_benchmark_tests.sh"      "the packet speed measurement instrument"
chain_suite "tests/metrics_adoption_tests.sh"     "the metrics adoption guard"
chain_suite "tests/pilot_kit_tests.sh"            "the buyer-facing pilot kit"
chain_suite "tests/entitlement_tests.sh"          "version, licence identity and the access-gated posture"
chain_suite "tests/lane_declaration_tests.sh"     "declared lane vs observable size"
chain_suite "tests/gate_depth_tests.sh"           "gate depth: concurrent gates + bounded fix round"
chain_suite "tests/swarm_merge_tests.sh"          "fan-out manifest validation and merge"
chain_suite "tests/control_registry_tests.sh"     "the control registry: class, authority and the anti-shelfware scan"
chain_suite "tests/neurocosmology_crosswalk_tests.sh" "the Neurocosmology crosswalk: control-to-primitive bindings"
chain_suite "tests/bandwidth_tests.sh"            "work-in-flight capacity ceilings, per dimension"
chain_suite "tests/evidence_policy_tests.sh"      "the evidence-policy matrix: class x empirical_status -> licensed authority"
chain_suite "tests/authority_envelope_tests.sh"   "the authority envelope: who granted what, in which deployment mode, until when"

# A chained suite that is added to the repo but never wired here would be
# discoverable-only — the exact defect chaining exists to prevent. Assert the
# wiring covers every sibling suite present on disk.
UNWIRED=""
for f in "$SRC"/tests/*.sh; do
  b="tests/$(basename "$f")"
  [ "$b" = "tests/build_os_tests.sh" ] && continue
  grep -qF "chain_suite \"$b\"" "$SRC/tests/build_os_tests.sh" || UNWIRED="$UNWIRED $b"
done
[ -z "$UNWIRED" ] && ok "every sibling suite in tests/ is chained here (none discoverable-only)" \
                  || no "sibling suite(s) present but never chained:$UNWIRED"

echo "== 27. Hook invocations must never inherit the caller's stdin (no interactive hang) =="
# Claude Code delivers a JSON payload on stdin and CLOSES it; the hooks therefore read
# stdin to EOF (hook-once.sh: payload="$(cat)"; prompt-router.sh: PAYLOAD="$(cat ...)").
# That is the correct hook contract. But a TEST that runs a hook without supplying that
# payload inherits the caller's stdin, which on an interactive terminal never reaches
# EOF — so the suite blocks forever with no output explaining why. README documents
# `bash tests/build_os_tests.sh` as the repo suite command, so that hang is what a
# customer on a TTY hits.
#
# What these checks do and do NOT do — stated plainly, because the distinction matters:
#   * Check (b), the static scan, is the actual regression detector. It never runs a
#     hook, so it cannot hang, and it names the exact offending statement.
#   * Check (a) is BOUNDED (timeout) and wires up its own invocations — it reuses
#     section 2's payload string but none of section 2's stdin wiring — so it can never
#     fail BECAUSE of a regression at an invocation site such as the section-2 call. It
#     is an executable proof of the mechanism — a hook fed its payload terminates even
#     while stdin stays open — not a detector for any particular line.
#   * LIMIT: on a TTY, a re-broken section-2 call hangs the suite at section 2 and 27
#     is never reached. Check (b) is the protection, and it fires in CI / any non-TTY
#     run (and on a TTY for every site except one that is already hanging the suite
#     ahead of it). Section 27 prevents the bug from being re-introduced; it does not
#     rescue a run that is already blocked.

# (a) Behavioral: a hook, invoked the way this suite invokes it, must COMPLETE even
#     while the caller's stdin stays open and idle. A FIFO whose write end is held open
#     reproduces an interactive terminal without ever sending EOF. Both stdin-reading
#     hooks are covered.
PIN_FIFO="$WORK/stdin-idle.fifo"
mkfifo "$PIN_FIFO"
( exec 9>"$PIN_FIFO"; sleep 120 ) & PIN_HOLDER=$!
if timeout 60 bash -c \
     'printf "%s" "$2" | HOME="$3" CLAUDE_PROJECT_DIR="$4" TMPDIR="$5" bash "$1" >/dev/null 2>&1' \
     _ "$HOOK" "$SESSION_PAYLOAD" "$FHOME" "$FPROJ" "$WORK/pin-tmp" < "$PIN_FIFO"; then
  ok "SessionStart hook completes with an open-but-idle stdin (no interactive hang)"
else
  no "SessionStart hook hung or failed while stdin stayed open — suite hangs on a TTY"
fi
PIN_PHOME="$WORK/pin-home"; mkdir -p "$PIN_PHOME/.claude"
printf '{"enabledPlugins":{},"skillListingBudgetFraction":0.18}\n' > "$PIN_PHOME/.claude/settings.json"
printf '{"mcpServers":{"keep-me":{"command":"keep"}}}\n' > "$PIN_PHOME/.claude.json"
PIN_PPAYLOAD='{"hook_event_name":"UserPromptSubmit","prompt":"list the files in this repo","cwd":"'"$PIN_PHOME"'","prompt_id":"pin-27"}'
if timeout 60 bash -c \
     'printf "%s" "$2" | HOME="$3" TMPDIR="$4" bash "$1" >/dev/null 2>&1' \
     _ "$PROMPT_HOOK" "$PIN_PPAYLOAD" "$PIN_PHOME" "$WORK/pin-ptmp" < "$PIN_FIFO"; then
  ok "UserPromptSubmit hook completes with an open-but-idle stdin (no interactive hang)"
else
  no "UserPromptSubmit hook hung or failed while stdin stayed open — suite hangs on a TTY"
fi
kill "$PIN_HOLDER" 2>/dev/null; wait "$PIN_HOLDER" 2>/dev/null

# (b) Static: EVERY hook invocation in this file — SessionStart and UserPromptSubmit,
#     whether written as "$HOOK" / "$PROMPT_HOOK" or as a literal .claude/hooks/*.sh
#     path — must be fed its payload (or have stdin explicitly closed). Deleting the
#     payload pipe from any one of them turns this assertion red and names the offending
#     statement (its first physical line, with the whole joined statement printed).
#     Physical lines are joined into logical ones first, because several sites put the
#     payload pipe on a preceding continuation line (e.g. the section-15 invocations).
#     Exempt: comment lines (they execute nothing) and the lines carrying the marker
#     `stdin-pin-exempt` below — the scanner's own PIN_RE definition and the case
#     statement that applies the marker. That exemption is DEFENSIVE, not an active
#     filter: as written today neither marked line matches PIN_RE (the definition spells
#     the pattern as `\$` and `[^"`, where a real invocation has `$` and a path), so
#     deleting the exemption leaves the count unchanged. It is kept so that a future
#     re-quoting of PIN_RE cannot make the scanner match its own source and report
#     itself as a finding.
#     The scan is only as good as PIN_RE, so a minimum site count is asserted below:
#     if a rename or refactor makes the pattern stop matching, the pin fails instead of
#     passing vacuously on zero sites.
PIN_RE='bash "\$(HOOK|PROMPT_HOOK)"|bash "[^"]*/\.claude/hooks/[^"]*\.sh"'  # stdin-pin-exempt
# Today's inventory is 10 executable sites: 3 SessionStart via "$HOOK" (sections 2, 7)
# and 7 UserPromptSubmit — 4 via "$PROMPT_HOOK" (sections 7, 18, 22) and 3 written as a
# literal .claude/hooks/prompt-router.sh path (sections 9, 16). Raise this floor when
# sites are added; lowering it is a deliberate act that says the suite really did shed a
# site, not that the scanner stopped seeing one.
PIN_MIN_SITES=10
PIN_LEAK=""; PIN_COUNT=0; pin_buf=""; pin_lno=0; pin_start=0
while IFS= read -r pin_raw || [ -n "$pin_raw" ]; do
  pin_lno=$((pin_lno+1))
  [ -n "$pin_buf" ] || pin_start=$pin_lno
  # Join bash line-continuations: a trailing backslash, or a trailing pipe.
  if [[ "$pin_raw" == *\\ ]]; then pin_buf="${pin_buf}${pin_raw%\\} "; continue; fi
  if [[ "$pin_raw" =~ \|[[:space:]]*$ ]]; then pin_buf="${pin_buf}${pin_raw} "; continue; fi
  pin_line="${pin_buf}${pin_raw}"; pin_buf=""
  case "$pin_line" in *stdin-pin-exempt*) continue ;; esac   # stdin-pin-exempt
  [[ "$pin_line" =~ ^[[:space:]]*# ]] && continue
  pin_rest="$pin_line"
  while [[ "$pin_rest" =~ $PIN_RE ]]; do
    pin_m="${BASH_REMATCH[0]}"
    pin_pre="${pin_rest%%"$pin_m"*}"
    pin_rest="${pin_rest#*"$pin_m"}"
    PIN_COUNT=$((PIN_COUNT+1))
    if [[ "$pin_pre" != *"|"* && "$pin_line" != *"< /dev/null"* && "$pin_line" != *"</dev/null"* ]]; then
      PIN_LEAK="${PIN_LEAK}      | line ${pin_start}: ${pin_line}"$'\n'
    fi
  done
done < "$SRC/tests/build_os_tests.sh"
if [ "$PIN_COUNT" -ge "$PIN_MIN_SITES" ]; then
  ok "stdin scanner sees $PIN_COUNT hook-invocation sites (>= $PIN_MIN_SITES, not vacuous)"
else
  no "stdin scanner matched only $PIN_COUNT hook-invocation sites (expected >= $PIN_MIN_SITES) — it has gone blind, so its verdict below is meaningless"
fi
if [ -z "$PIN_LEAK" ]; then
  ok "all $PIN_COUNT hook invocations in the suite supply stdin (never inherit the terminal)"
else
  no "hook invocation(s) inherit the caller's stdin — the suite will hang on a TTY"
  printf '%s' "$PIN_LEAK"
fi

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
