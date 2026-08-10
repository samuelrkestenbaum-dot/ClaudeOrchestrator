#!/usr/bin/env bash
# LEAN L2 — the four-step demonstration protocol for auto-routing.
#
# The OLD gate is checked out from git (LEAN_L2_OLD_REF, default dfdee0e) into
# its own CODE tree and EXECUTED — never imitated. The NEW gate is the working
# tree's. Both run against disposable DATA fixtures via CLAUDE_PROJECT_DIR.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
OLD_REF="${LEAN_L2_OLD_REF:-dfdee0e}"
TMP="$(mktemp -d /tmp/lean-l2.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); printf '  ok  %s\n' "$1"; }
bad(){ FAIL=$((FAIL+1)); printf '  FAIL %s\n      %s\n' "$1" "$2"; }

# -- the OLD gate, from git, in a minimal CODE tree of its own ---------------
OLDCODE="$TMP/old-code"
mkdir -p "$OLDCODE/.claude/hooks" "$OLDCODE/build-os/assumptions" "$OLDCODE/build-os/tools"
for f in .claude/hooks/routing-gate.sh build-os/assumptions/gate-recovery.mjs \
         build-os/assumptions/host-profiles.mjs build-os/assumptions/authority-selector.mjs \
         build-os/tools/route-task.sh build-os/tools/mode-select.mjs; do
  git -C "$REPO" show "$OLD_REF:$f" > "$OLDCODE/$f" 2>/dev/null || true
done
chmod +x "$OLDCODE/.claude/hooks/routing-gate.sh" "$OLDCODE/build-os/tools/route-task.sh" 2>/dev/null

NEWGATE="$REPO/.claude/hooks/routing-gate.sh"
OLDGATE="$OLDCODE/.claude/hooks/routing-gate.sh"

fixture(){ # <name> -> path; a DATA tree with tools present and no receipts
  local d="$TMP/data-$1"
  mkdir -p "$d/build-os/packets/routing"
  cp -r "$REPO/build-os/tools" "$d/build-os/" 2>/dev/null
  rm -f "$d/build-os/tools/lean-l2.test.sh"
  printf '%s' "$d"
}

run_gate(){ # <gate> <data-root> <event-json>; sets RC, ERR
  ERR="$("$1" mutgate <<<"$3" 2>&1 1>/dev/null)"; RC=$?
  # hooks print decisions internally; RC is the contract (0 allow, 2 block)
}
EDIT_EVENT='{"tool_name":"Edit","tool_input":{"file_path":"/tmp/proj/src/app.ts","old_string":"a","new_string":"b"}}'

echo "lean L2 (old code from $OLD_REF)"

# 1. OLD: first mutation with no receipt is BLOCKED and the worker is told to
#    author the routing request — the measured round-trip.
D="$(fixture old1)"
run_gate() { ERR="$(CLAUDE_PROJECT_DIR="$2" "$1" mutgate <<<"$3" 2>&1 1>/dev/null)"; RC=$?; }
run_gate "$OLDGATE" "$D" "$EDIT_EVENT"
if [ "$RC" -eq 2 ]; then ok "old: first mutation blocked, worker must author the request"; else bad "old block" "rc=$RC err=$ERR"; fi
if printf '%s' "$ERR" | grep -qi "routing-request\|route-task"; then ok "old: refusal dictates the request schema/tooling"; else bad "old refusal text" "$ERR"; fi

# 2. NEW: same event ALLOWS — the receipt minted itself at the selector floor.
D="$(fixture new1)"
run_gate "$NEWGATE" "$D" "$EDIT_EVENT"
if [ "$RC" -eq 0 ]; then ok "new: first mutation allowed"; else bad "new allow" "rc=$RC err=$ERR"; fi
REC="$(ls "$D"/build-os/packets/routing/routing-auto-*.md 2>/dev/null | head -1)"
if [ -n "$REC" ]; then ok "new: a receipt exists, machine-authored (task auto-*)"; else bad "new receipt" "$(ls "$D"/build-os/packets/routing 2>/dev/null)"; fi
if [ -n "$REC" ] && grep -q "direct" "$REC"; then ok "new: minted at the selector FLOOR (direct)"; else bad "floor mode" "$(grep -i mode "$REC" 2>/dev/null)"; fi
if grep -rq "AUTO-RECEIPT-MINTED" "$D/build-os" 2>/dev/null; then ok "new: ledger records the mint with runtime provenance"; else bad "ledger row" "no AUTO-RECEIPT-MINTED row"; fi

# 3. NEW idempotence: a second mutation rides the SAME receipt; no second mint.
run_gate "$NEWGATE" "$D" "$EDIT_EVENT"
N_REC="$(ls "$D"/build-os/packets/routing/routing-*.md 2>/dev/null | wc -l)"
if [ "$RC" -eq 0 ] && [ "$N_REC" -eq 1 ]; then ok "new: second mutation allowed on the open receipt, no second mint"; else bad "idempotence" "rc=$RC receipts=$N_REC"; fi

# 4. PRESERVED: the explicit routing-request channel still works (bootstrap
#    path unchanged for hosts/flows that use it).
D="$(fixture new2)"
REQ_EVENT="{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$D/build-os/packets/routing/routing-request.json\",\"content\":\"{}\"}}"
run_gate "$NEWGATE" "$D" "$REQ_EVENT"
if [ "$RC" -eq 0 ]; then ok "preserved: writing the routing request is still an ungated channel"; else bad "request channel" "rc=$RC err=$ERR"; fi

# 5. PRESERVED: read-only git passes with NO receipt minted — auto-mint fires
#    only for real mutations.
D="$(fixture new3)"
run_gate "$NEWGATE" "$D" '{"tool_name":"Bash","tool_input":{"command":"git status"}}'
N_REC="$(ls "$D"/build-os/packets/routing/routing-*.md 2>/dev/null | wc -l)"
if [ "$RC" -eq 0 ] && [ "$N_REC" -eq 0 ]; then ok "preserved: git_readonly allowed without minting anything"; else bad "readonly" "rc=$RC receipts=$N_REC"; fi

# 6. PRESERVED FALLBACK + the demonstrated defect's regression: with route-task
#    ABSENT from the data tree, the new gate must BLOCK (like the old one) and
#    must NOT reach across to the code tree — the first run of this test minted
#    a receipt into the ORCHESTRATOR repo that way.
D="$TMP/data-bare"; mkdir -p "$D/build-os/packets/routing"
run_gate "$OLDGATE" "$D" "$EDIT_EVENT"
OLD_BARE_RC=$RC
BEFORE_REAL="$(ls "$REPO"/build-os/packets/routing/routing-auto-*.md 2>/dev/null | wc -l)"
run_gate "$NEWGATE" "$D" "$EDIT_EVENT"
AFTER_REAL="$(ls "$REPO"/build-os/packets/routing/routing-auto-*.md 2>/dev/null | wc -l)"
N_REC="$(ls "$D"/build-os/packets/routing/routing-*.md 2>/dev/null | wc -l)"
if [ "$RC" -eq 2 ] && [ "$N_REC" -eq 0 ]; then ok "fallback: bare data tree still BLOCKS (old rc=$OLD_BARE_RC, new rc=$RC)"; else bad "fallback" "rc=$RC receipts=$N_REC"; fi
if [ "$AFTER_REAL" -eq "$BEFORE_REAL" ]; then ok "regression: no receipt reaches across into the orchestrator repo"; else bad "cross-tree pollution" "orchestrator receipts $BEFORE_REAL -> $AFTER_REAL"; fi

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
