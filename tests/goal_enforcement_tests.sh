#!/usr/bin/env bash
# R0.1 §1 — TOOL-LEVEL goal enforcement, failure-first. The PreToolUse mutgate
# must fail CLOSED before side effects for expired/over-budget/not-yet goals,
# on every mutating tool, in any session (direct, resumed, nested — they all
# pass PreToolUse); reads and emergency stop stay available; refusals leave
# actionable receipts. Also: metering concurrency/dedupe, and residue sweep.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d /tmp/bos-enf.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }
R="$WORK/repo"; mkdir -p "$R"; git -C "$R" init -q; git -C "$R" remote add origin https://x/enf.git
echo base > "$R/app.txt"; git -C "$R" -c user.email=t@t -c user.name=t add -A; git -C "$R" -c user.email=t@t -c user.name=t commit -qm s
"$SRC/bin/gravito" init "$R" >/dev/null 2>&1
GOAL="$SRC/templates/gravito.goal.example"
"$SRC/bin/gravito" goal "$GOAL" "$R" >/dev/null

hook(){ # <tool> <repo> [env...] -> exit code; stderr to $WORK/err
  local tool="$1" repo="$2"; shift 2
  printf '{"tool_name":"%s","tool_input":{"file_path":"%s/app.txt"}}' "$tool" "$repo" \
    | env CLAUDE_PROJECT_DIR="$repo" "$@" bash "$repo/.claude/hooks/routing-gate.sh" mutgate >"$WORK/out" 2>"$WORK/err"
  echo $?
}

echo "== 1. live goal: mutation allowed (no false blocks) =="
ok '[ "$(BUILD_OS_NOW=2026-08-13 hook Edit "$R" BUILD_OS_NOW=2026-08-13)" != 2 ]' "Edit allowed under a LIVE goal"

echo "== 2. lapsed goal blocks EVERY mutating tool BEFORE side effects =="
sed -i 's/^starts: .*/starts: 2026-07-01/; s/^expires: .*/expires: 2026-08-01/' "$R/gravito.goal"
for t in Edit Write NotebookEdit Bash; do
  ok '[ "$(hook '"$t"' "$R" BUILD_OS_NOW=2026-08-13)" = 2 ]' "$t BLOCKED (exit 2) under a LAPSED goal"
done
ok 'grep -q "GOAL HALT" "$WORK/err"' "refusal is model-visible and names the halt"
ok '[ -f "$R/build-os/receipts/refusals.log" ] && grep -q "LAPSED" "$R/build-os/receipts/refusals.log"' "actionable refusal receipt written (names LAPSED)"
ok '[ "$(cat "$R/app.txt")" = "base" ]' "no side effect occurred (file unchanged)"

echo "== 2b. not-yet-live goal blocks the same way (the OTHER out-of-window state) =="
sed -i 's/^starts: .*/starts: 2026-09-01/; s/^expires: .*/expires: 2026-12-31/' "$R/gravito.goal"
ok '[ "$(hook Edit "$R" BUILD_OS_NOW=2026-08-13)" = 2 ]' "Edit BLOCKED (exit 2) under a NOT-YET-LIVE goal"
ok 'grep -q "NOT-YET-LIVE" "$R/build-os/receipts/refusals.log"' "refusal receipt names NOT-YET-LIVE"
ok '[ "$(cat "$R/app.txt")" = "base" ]' "no side effect occurred (file unchanged)"

echo "== 3. reads and emergency stop remain available while blocked =="
ok '[ "$(hook Read "$R" BUILD_OS_NOW=2026-08-13)" != 2 ]' "Read is never goal-blocked (status/diagnosis stays possible)"
ok '"$SRC/bin/gravito" stop "$R" >/dev/null' "gravito stop works while execution is blocked"
ok '"$SRC/bin/gravito" status "$R" >/dev/null' "gravito status works while execution is blocked"

echo "== 4. over-budget blocks; run entry point also refuses =="
sed -i 's/^starts: .*/starts: 2026-08-01/; s/^expires: .*/expires: 2026-12-31/' "$R/gravito.goal"
mkdir -p "$R/build-os/memory"; echo '{"tokens":99999999,"usd":0,"minutes":0}' > "$R/build-os/memory/spend-ledger.jsonl"
ok '[ "$(hook Edit "$R" BUILD_OS_NOW=2026-08-13)" = 2 ]' "Edit BLOCKED when the committed ledger exceeds budget"
ok '! BUILD_OS_NOW=2026-08-13 "$SRC/bin/gravito" run "$R" --dry-run >/dev/null 2>&1' "gravito run refuses at the same gate"
rm "$R/build-os/memory/spend-ledger.jsonl"

echo "== 5. no goal installed: mutgate does not goal-block (fresh repo, contract scope) =="
R2="$WORK/repo2"; mkdir -p "$R2"; git -C "$R2" init -q; git -C "$R2" remote add origin https://x/enf2.git
echo b > "$R2/app.txt"; git -C "$R2" -c user.email=t@t -c user.name=t add -A; git -C "$R2" -c user.email=t@t -c user.name=t commit -qm s
"$SRC/bin/gravito" init "$R2" >/dev/null 2>&1
ok '[ "$(hook Edit "$R2" BUILD_OS_NOW=2026-08-13)" != 2 ]' "no goal file => no goal gate (existing mutgate semantics unchanged)"

echo "== 5b. WIRING: installed targets must REGISTER the tool gates (R1-P2) =="
# R0.1's defect, found by refreshing entry-point evidence: hooks were SHIPPED
# to targets but never REGISTERED in the target's settings.json, so a real
# session in a target never consulted the goal gate at tool level. Behavior
# proofs above invoke the hook directly; these assertions pin the wiring.
wired(){ python3 -c "
import json,sys
s=json.load(open('$R/.claude/settings.json'))
pt=s.get('hooks',{}).get('PreToolUse',[])
ok=any(g.get('matcher')=='$1' and any('routing-gate.sh $2' in h.get('command','') for h in g.get('hooks',[])) for g in pt)
sys.exit(0 if ok else 1)"; }
ok 'wired "Edit|Write|NotebookEdit|Bash" mutgate' "target registers the file-tool mutgate matcher"
ok 'wired "mcp__.*" mcpgate' "target registers the MCP mutation gate matcher"
ok 'wired "Task|Agent" gate' "target registers the routing gate matcher"

echo "== 5c. MCP mutation gate: DEFAULT CLOSED (R1-P2) =="
mcphook(){ # <tool> -> exit code
  printf '{"tool_name":"%s","tool_input":{}}' "$1" \
    | env CLAUDE_PROJECT_DIR="$R" BUILD_OS_NOW="$2" bash "$R/.claude/hooks/routing-gate.sh" mcpgate >"$WORK/out" 2>"$WORK/err"
  echo $?
}
sed -i 's/^starts: .*/starts: 2026-07-01/; s/^expires: .*/expires: 2026-08-01/' "$R/gravito.goal"   # LAPSED
ok '[ "$(mcphook mcp__github__create_pull_request 2026-08-13)" = 2 ]' "unknown MCP WRITE tool BLOCKED under a lapsed goal"
ok '[ "$(mcphook mcp__foo__fetch_data 2026-08-13)" = 2 ]' "read-SOUNDING but undeclared MCP tool BLOCKED (default closed)"
ok 'grep -q "mcp__foo__fetch_data" "$R/build-os/receipts/refusals.log"' "MCP refusal receipt names the exact tool"
ok '[ "$(mcphook mcp__github__get_file_contents 2026-08-13)" != 2 ]' "allowlisted read-only MCP tool passes even while lapsed"
sed -i 's/^starts: .*/starts: 2026-08-01/; s/^expires: .*/expires: 2026-12-31/' "$R/gravito.goal"   # LIVE again
ok '[ "$(mcphook mcp__github__create_pull_request 2026-08-13)" != 2 ]' "unknown MCP tool allowed under a LIVE in-budget goal"
R4="$WORK/repo4"; mkdir -p "$R4"; git -C "$R4" init -q; git -C "$R4" remote add origin https://x/enf4.git
echo b > "$R4/app.txt"; git -C "$R4" -c user.email=t@t -c user.name=t add -A; git -C "$R4" -c user.email=t@t -c user.name=t commit -qm s
"$SRC/bin/gravito" init "$R4" >/dev/null 2>&1
ok '[ "$(printf "{\"tool_name\":\"mcp__x__write_thing\",\"tool_input\":{}}" | env CLAUDE_PROJECT_DIR="$R4" bash "$R4/.claude/hooks/routing-gate.sh" mcpgate >/dev/null 2>&1; echo $?)" != 2 ]' "no goal installed => MCP tools unaffected (contract scope unchanged)"

echo "== 6. metering: dedupe + concurrency-safe committed ledger =="
M="$SRC/build-os/tools/meter-run.sh"
S1="$R/build-os/receipts/run-A.jsonl"
printf '{"type":"result","usage":{"input_tokens":100,"output_tokens":50,"cache_creation_input_tokens":10,"cache_read_input_tokens":5},"total_cost_usd":0.02}\n' > "$S1"
bash "$M" "$S1" "$R" 60 >/dev/null
bash "$M" "$S1" "$R" 60 >/dev/null
ok '[ "$(grep -c run-A "$R/build-os/memory/spend-ledger.jsonl")" = 1 ]' "same stream metered twice => ONE ledger entry (no double count)"
for i in 1 2 3 4 5 6 7 8; do
  printf '{"type":"result","usage":{"input_tokens":1,"output_tokens":1},"total_cost_usd":0.001}\n' > "$R/build-os/receipts/run-c$i.jsonl"
  bash "$M" "$R/build-os/receipts/run-c$i.jsonl" "$R" 60 & done; wait
ok '[ "$(grep -c run-c "$R/build-os/memory/spend-ledger.jsonl")" = 8 ]' "8 concurrent meters => 8 intact entries (flock)"
ok '! grep -vE "^\{.*\}$" "$R/build-os/memory/spend-ledger.jsonl" | grep -q .' "no torn/interleaved ledger lines under concurrency"

echo "== 7. residue sweep: incidental dotfiles isolated; product + pre-existing preserved =="
echo "preexisting" > "$R/.gitignore"   # PRE-EXISTING dotfile: must never move
sha_pre="$(sha256sum "$R/.gitignore" | cut -d' ' -f1)"
snap="$WORK/snap.txt"; bash "$SRC/build-os/tools/residue-sweep.sh" snapshot "$R" > "$snap"
mkdir -p "$R/.serena"; echo cache > "$R/.serena/x"; echo stray > "$R/.stray-tool-file"
echo "product output" > "$R/feature.txt"   # non-dot new file = product artifact
bash "$SRC/build-os/tools/residue-sweep.sh" sweep "$R" "$snap" >/dev/null
ok '[ ! -d "$R/.serena" ] && [ ! -f "$R/.stray-tool-file" ]' "incidental new dotfiles moved OUT of the product tree"
ok 'ls "$R"/build-os/residue/*/.serena/x >/dev/null 2>&1' "residue preserved (reversible) under build-os/residue/"
ok 'grep -q ".serena" "$R/build-os/receipts/residue.log"' "residue receipt written"
ok '[ -f "$R/feature.txt" ]' "new NON-dot file treated as product artifact, untouched"
ok '[ "$(sha256sum "$R/.gitignore" | cut -d" " -f1)" = "$sha_pre" ]' "PRE-EXISTING dotfile byte-identical (never moved)"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
