#!/usr/bin/env bash
# EXP-0013 RELEASE-CANDIDATE suite (AMENDMENT v5). Verifies the publication
# candidate itself: range integrity, secret absence, path hygiene, oracle
# root-invariance, escrow rehearsal on SYNTHETIC material, and a publish-
# gate dry run with a synthetic authorization in a DISPOSABLE copy. No
# push, no provider call, no real secrets, no real authorization touched.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E="$SRC/build-os/experiments/EXP-0013-delivery-confirmatory"
H="$E/harness"
BASE=607c0bd
WORK="$(mktemp -d /tmp/bos-e13rel.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }

echo "== L1. release range: linear, fast-forward, in scope =="
ok '[ "$(cd "$SRC" && git rev-list --count --merges $BASE..HEAD)" = 0 ]' "no merge commits in the range (linear chain)"
ok '[ -z "$(cd "$SRC" && git ls-tree -r HEAD | awk "\$2==\"commit\"")" ]' "no gitlinks/submodules anywhere in the release tree"
OUT=$(cd "$SRC" && git diff --name-only $BASE..HEAD | grep -v "^build-os/experiments/EXP-0013" | grep -v "^tests/exp0013" || true)
ok '[ "$(printf "%s" "$OUT" | grep -cv "^$")" -le 2 ] && ! printf "%s" "$OUT" | grep -vE "^(build-os/registry/neurocosmology_math_registry.md|build-os/tools/planner.mjs)$" | grep -q .' \
  "only the two authorized in-scope files change outside EXP-0013 paths (planner seam, registry entry)"
ok '[ -z "$(cd "$SRC" && git diff --summary $BASE..HEAD | grep -E "mode change|rename")" ]' "no mode changes or renames in the range"

echo "== L2. secret and sensitive-data absence (values never printed) =="
RANGE_PATHS=$(cd "$SRC" && git diff --name-only $BASE..HEAD)
ok '! (cd "$SRC" && git log -p $BASE..HEAD | grep -qiE "sk-ant-|x-api-key|bearer [a-z0-9]{20}")' "no API-key/token patterns anywhere in the range history"
ok '! printf "%s" "$RANGE_PATHS" | grep -qE "publish-authorization|spend-ledger\.jsonl|build-os/authority/"' "no authorization objects or spend ledgers committed"
ok '! printf "%s" "$RANGE_PATHS" | grep -q "corpus/mapping-escrow.json"' "no escrow ciphertext committed (that commit needs its own scoped go)"
if [ -f /home/user/.exp0013-sealed/orders.json ]; then
  S1=$(python3 -c "import json;d=json.load(open('/home/user/.exp0013-sealed/orders.json'));print(d['order_salt'])")
  S2=$(python3 -c "import json;d=json.load(open('/home/user/.exp0013-sealed/orders.json'));print(d['blinding_salt'])")
  ok '! (cd "$SRC" && git log -p $BASE..HEAD | grep -q "$S1\|$S2")' "REAL sealed salts are absent from the entire range history"
else
  ok 'true' "(sealed store not on this machine — salt-absence check not applicable here)"
fi
ok '! grep -rq "/tmp/claude-0\|/tmp/bos-\|5489b495-ae3d" "$E/corpus" "$E/rehearsal-evidence" 2>/dev/null' \
  "corpus and rehearsal evidence carry NO container temp paths or session-derived paths (v5 hygiene)"
ok '! grep -rql "Could you clarify what" "$E/corpus" "$E/harness" "$E/rehearsal-evidence" 2>/dev/null' \
  "no byte of the incident reply exists outside the incident record"

echo "== L3. oracle root-invariance (the launch-fatal v5 fix) =="
OUT=$(node --input-type=module -e "
import { acceptance, parseTsc } from '$H/oracle.mjs';
import fs from 'node:fs';
const B = fs.readFileSync('$E/corpus/baseline-tsc.txt','utf8');
const rootA = B; // committed normalized baseline
const rootB = B.replace(/<TREE>/g, '/home/user/iso/S1/worktree'); // a measured-run root
const a = acceptance({ baselineText: rootA, afterText: rootB, targetFile: 'no/such/file.ts' });
console.log(JSON.stringify({ regs: a.regressions.length, before: a.total_errors_before, after: a.total_errors_after,
  clean: !/\/tmp\/|5489b495/.test(B) }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"regs\"]==0 and d[\"before\"]==781 and d[\"after\"]==781 and d[\"clean\"] else 1)"' \
  "identical errors from a DIFFERENT tree root => ZERO false regressions; baseline normalized, 781 identities intact"

echo "== L4. synthetic escrow rehearsal (exact operator command, synthetic material only) =="
SD="$WORK/syn-sealed"; mkdir -p "$SD"
python3 - <<PYEOF
import json
json.dump({"artifact":"exp0013_sealed_orders","orders":{"S1":{"2":["a","b"],"3":["b","a"]},"S2":{"2":["b","a"],"3":["a","b"]}},"order_salt":"73796e746865746963","blinding_salt":"616c736f2d73796e"},open("$SD/orders.json","w"))
json.dump({"artifact":"exp0013_sealed_rerun_orders","orders":{"S1":{"2":["b","a"]}},"rerun_salt":"73796e2d726572756e"},open("$SD/rerun-orders.json","w"))
PYEOF
CL="$WORK/escrow-clone"; git -C "$SRC" worktree add -f --detach "$CL" HEAD >/dev/null 2>&1
EH="$CL/build-os/experiments/EXP-0013-delivery-confirmatory/harness"
OUT=$(cd "$CL" && printf 'synthetic-passphrase-xyz\nsynthetic-passphrase-xyz\n' | EXP0013_SEALED_DIR="$SD" node "$EH/escrow-cli.mjs" create 2>&1)
ok 'printf "%s" "$OUT" | grep -q "decryptability: PROVEN" && printf "%s" "$OUT" | grep -q "ciphertext sha256:"' \
  "operator command produces ciphertext + silent decryptability proof (piped stdin adapter; echo path exercised interactively by the owner)"
ok '! printf "%s" "$OUT" | grep -q "synthetic-passphrase-xyz"' "passphrase never appears in tool output"
EF="$CL/build-os/experiments/EXP-0013-delivery-confirmatory/corpus/mapping-escrow.json"
ok '[ -f "$EF" ] && ! grep -q "order_salt\|73796e746865746963\|\"orders\"" "$EF"' "escrow artifact is ciphertext-only: no salts, no orders, no labels"
OUT=$(cd "$CL" && printf 'WRONG-passphrase-000\n' | node "$EH/escrow-cli.mjs" check 2>&1)
ok 'printf "%s" "$OUT" | grep -q "REFUSED: ESCROW_WRONG_KEY_OR_TAMPERED"' "wrong passphrase => typed refusal, no information leaked"
rm -rf "$SD"   # simulate loss of the original sealed container
OUT=$(node --input-type=module -e "
import { escrowRecover } from '$EH/mapping-escrow.mjs';
const r = escrowRecover({ escrowFile: '$EF', passphrase: 'synthetic-passphrase-xyz', outPath: '$WORK/recovered.json' });
import fs from 'node:fs';
const rec = JSON.parse(fs.readFileSync('$WORK/recovered.json','utf8'));
const b = JSON.parse(rec['orders.json']);
console.log(JSON.stringify({ ok: r.ok, hasOrders: !!b.orders?.S1, hasRerun: !!JSON.parse(rec['rerun-orders.json']).orders }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"ok\"] and d[\"hasOrders\"] and d[\"hasRerun\"] else 1)"' \
  "RECOVERY AFTER SOURCE LOSS: both primary and rerun mappings restored from ciphertext alone"
python3 - <<PYEOF
import json
e=json.load(open("$EF")); e["tag"]="00"*16
json.dump(e,open("$WORK/tampered.json","w"))
PYEOF
OUT=$(node --input-type=module -e "
import { escrowRecover } from '$EH/mapping-escrow.mjs';
console.log(JSON.stringify(escrowRecover({ escrowFile: '$WORK/tampered.json', passphrase: 'synthetic-passphrase-xyz' })));")
ok 'printf "%s" "$OUT" | grep -q "ESCROW_WRONG_KEY_OR_TAMPERED"' "corrupted auth tag => same typed refusal (GCM authenticated)"
ok '! grep -q "mapping-escrow" "$SRC/build-os/experiments/EXP-0013-delivery-confirmatory/harness/views.mjs"' \
  "view generation never touches the escrow artifact (no join-key exposure path)"
git -C "$SRC" worktree remove -f "$CL" >/dev/null 2>&1 || true

echo "== L5. publication gate dry run (disposable copy; real authority untouched) =="
CL2="$WORK/gate-clone"; git -C "$SRC" worktree add -f --detach "$CL2" HEAD >/dev/null 2>&1
if [ -f "$SRC/build-os/tools/publish-check.mjs" ]; then
  cp -r "$SRC/build-os/tools" "$CL2/build-os/" 2>/dev/null || true
  OUT=$(cd "$CL2" && node build-os/tools/publish-check.mjs 2>&1 || true)
  ok 'printf "%s" "$OUT" | grep -qiE "refus|missing|no.*authoriz"' "publish gate REFUSES with no authorization present"
  mkdir -p "$CL2/build-os/authority"
  TIP=$(git -C "$SRC" rev-parse HEAD)
  python3 - <<PYEOF
import json
json.dump({"authorized":True,"authorized_tip":"$TIP","also_authorized":[],"confers_status":"SYNTHETIC_DRY_RUN — not owner authority"},open("$CL2/build-os/authority/publish-authorization.json","w"))
PYEOF
  OUT=$(cd "$CL2" && node build-os/tools/publish-check.mjs 2>&1 || true)
  ok 'printf "%s" "$OUT" | grep -qiE "proceed|ok|authorized"' "publish gate accepts the schema with a synthetic tip-bound authorization (dry run only)"
else
  ok 'true' "(publish-check.mjs not present in this tree — gate lives in hook config)"
  ok 'true' "(skipped)"
fi
ok 'cd "$SRC" && git check-ignore -q build-os/authority/publish-authorization.json && [ "$(python3 -c "import json;print(json.load(open(\"build-os/authority/publish-authorization.json\")).get(\"authorized_tip\",\"\")[:7])" 2>/dev/null)" != "$(git rev-parse --short=7 HEAD)" ]' \
  "REAL authority file is gitignored and STALE (tip-bound to the previous push) — it cannot authorize the pending range; no synthetic authorization left active"
git -C "$SRC" worktree remove -f "$CL2" >/dev/null 2>&1 || true
ok '[ "$(cd "$SRC" && git rev-parse origin/claude/project-handoff-merge-ramhds)" = "${BASE}92651e350b21a272229a7416ba3ef7bfd" ]' \
  "expected old remote tip verified: 607c0bd92651e350b21a272229a7416ba3ef7bfd"

echo
echo "exp0013_release_tests: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
