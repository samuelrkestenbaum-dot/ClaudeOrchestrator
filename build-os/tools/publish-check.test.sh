#!/usr/bin/env bash
# Wired-path fixtures. These exercise build-os/tools/publish-check.mjs, the
# script .githooks/pre-push actually runs — not a model of it.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1
P=0; F=0
ok(){ P=$((P+1)); echo "  ok   $1"; }
no(){ F=$((F+1)); echo "  FAIL $1${2:+ — $2}"; }
AUTH=build-os/authority/publish-authorization.json
SAVE=$(mktemp); cp "$AUTH" "$SAVE" 2>/dev/null

# 1. THE EPISODE — replayed through the wired path.
out="$(node build-os/tools/publish-check.mjs --local f8e1ed2 --remote 86cb7c1 2>&1)"; rc=$?
[ $rc -eq 0 ] && ok "REPLAY: the 1ffb356 -> f8e1ed2 episode now PROCEEDS" || no "replay still blocks" "$out"
echo "$out" | grep -q "topology consequence, not approval" \
  && ok "REPLAY: the reason names topology, not approval" || no "reason not stated"

# 2. NEGATIVE — an ancestor asserting an executable state still blocks.
TMP=$(mktemp -d); git worktree add -q --detach "$TMP" 86cb7c1 2>/dev/null
( cd "$TMP" \
  && mkdir -p build-os/experiments/FAKE \
  && printf '**Status: FROZEN.** This preregistration is frozen and ready to execute.\n' \
       > build-os/experiments/FAKE/PREREGISTRATION.md \
  && git add -A >/dev/null && git -c user.email=t@t -c user.name=t commit -q -m "fake: assert FROZEN status" \
  && printf 'x\n' > build-os/_tip.txt \
  && git add -A >/dev/null && git -c user.email=t@t -c user.name=t commit -q -m "tip: ordinary work" ) >/dev/null 2>&1
TIP=$(git -C "$TMP" rev-parse HEAD)
# Authorise THIS tip, so the check reaches the ancestor stage rather than
# stopping at the staleness gate. Content authorisation precedes topology, and
# the fixture must respect that ordering to test what it claims to test.
node -e 'const fs=require("fs");const a=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));a.authorized_tip=process.argv[2];fs.writeFileSync(process.argv[1],JSON.stringify(a,null,2));' "$AUTH" "$TIP"
out2="$(node build-os/tools/publish-check.mjs --local "$TIP" --remote 86cb7c1 2>&1)"; rc2=$?
cp "$SAVE" "$AUTH" 2>/dev/null
[ $rc2 -ne 0 ] && ok "NEGATIVE: an ancestor claiming FROZEN/ready-to-execute BLOCKS" || no "status-claiming ancestor was allowed" "$out2"
echo "$out2" | grep -q "state transition" \
  && ok "NEGATIVE: the block names the state transition" || no "state transition not named"
git worktree remove --force "$TMP" >/dev/null 2>&1

# 3. No authorisation record => refuse (content authorisation is never self-granted).
mv "$AUTH" "$AUTH.bak" 2>/dev/null
node build-os/tools/publish-check.mjs --local f8e1ed2 --remote 86cb7c1 >/dev/null 2>&1 \
  && no "missing authorisation was allowed" || ok "no authorisation record => REFUSED"
mv "$AUTH.bak" "$AUTH" 2>/dev/null

# 4. A publication that itself confers status needs its own go.
node -e 'const fs=require("fs");const a=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));a.confers_status=true;fs.writeFileSync(process.argv[1],JSON.stringify(a,null,2));' "$AUTH"
node build-os/tools/publish-check.mjs --local f8e1ed2 --remote 86cb7c1 >/dev/null 2>&1 \
  && no "status-conferring publication was allowed" || ok "a status-conferring publication REFUSES"
cp "$SAVE" "$AUTH" 2>/dev/null

# 4b. STALENESS — an authorisation names the tip it was granted for.
node build-os/tools/publish-check.mjs --local HEAD --remote 86cb7c1 >/dev/null 2>&1 \
  && no "a stale authorisation was accepted for a different tip" || ok "STALENESS: a different tip is REFUSED"
node -e 'const fs=require("fs");const a=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));delete a.authorized_tip;fs.writeFileSync(process.argv[1],JSON.stringify(a,null,2));' "$AUTH"
node build-os/tools/publish-check.mjs --local f8e1ed2 --remote 86cb7c1 >/dev/null 2>&1 \
  && no "an authorisation naming no tip was accepted" || ok "an authorisation naming no tip is REFUSED"
cp "$SAVE" "$AUTH" 2>/dev/null

# 5. The hook is installed and executable.
[ "$(git config core.hooksPath)" = ".githooks" ] && ok "core.hooksPath points at the repo hooks" || no "hooks path not configured"
[ -x .githooks/pre-push ] && ok "pre-push hook is executable" || no "pre-push not executable"
grep -q "publish-check.mjs" .githooks/pre-push && ok "the hook calls the checker" || no "hook does not call the checker"

rm -f "$SAVE"
echo "==== RESULT: $P passed, $F failed ===="
[ $F -eq 0 ] || exit 1
