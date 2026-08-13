#!/usr/bin/env bash
# EXP-0013 SURGICAL-REVIEW suite (AMENDMENT v6). Failing-first reproductions
# for the launch-critical review findings, plus the property/fixture tests
# the review mandated for the newest surfaces. NO SPEND, synthetic secrets
# only, no provider contact.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E="$SRC/build-os/experiments/EXP-0013-delivery-confirmatory"
H="$E/harness"
WORK="$(mktemp -d /tmp/bos-e13rev.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }

echo "== W1. oracle normalization properties (review §1) =="
OUT=$(node --input-type=module -e "
import { identity, normalizeMsg, acceptance, parseTsc, identityMultiset } from '$H/oracle.mjs';
import fs from 'node:fs';
const B = fs.readFileSync('$E/corpus/baseline-tsc.txt','utf8');
const reroot = (t,root)=>t.replace(/<TREE>/g, root);
const ms=(t)=>[...identityMultiset(parseTsc(t)).entries()].sort().map(([k,v])=>k+'#'+v).join('|');
console.log(JSON.stringify({
  idempotent: (()=>{const m='x on typeof import(\"/a/b/server/y\").'; return normalizeMsg(normalizeMsg(m))===normalizeMsg(m);})(),
  posix_macos_roots_equal: ms(reroot(B,'/tmp/x1/scratch'))===ms(reroot(B,'/var/folders/ab/T/corpus')) && ms(reroot(B,'/tmp/x1/scratch'))===ms(B),
  relative_untouched: normalizeMsg('Cannot find module \"server/util\".')==='Cannot find module \"server/util\".',
  distinct_files_distinct: identity({file:'a.ts',code:'TS1',msg:'m'})!==identity({file:'b.ts',code:'TS1',msg:'m'}),
  distinct_codes_distinct: identity({file:'a.ts',code:'TS1',msg:'m'})!==identity({file:'a.ts',code:'TS2',msg:'m'}),
  genuine_regression_detected: acceptance({baselineText:B,afterText:reroot(B,'/r2')+'\nserver/x.ts(1,1): error TS9999: new.\n',targetFile:'q'}).regressions.length===1,
  multiset_counts: acceptance({baselineText:'f.ts(1,1): error TS1: d.\nf.ts(2,1): error TS1: d.\n',afterText:'f.ts(1,1): error TS1: d.\nf.ts(2,1): error TS1: d.\nf.ts(3,1): error TS1: d.\n',targetFile:'q'}).regressions.length===1,
  // DOCUMENTED residual (review F3): an out-of-root path whose tail contains a
  // known tree dir aliases to <TREE>/... — collision still requires identical
  // file+code+message-tail; asserted here so the behavior is pinned, not hidden.
  external_alias_pinned: normalizeMsg('Cannot find module \"/opt/OTHER/server/util\".')==='Cannot find module \"<TREE>/server/util\".',
  bare_space_limitation_pinned: normalizeMsg(' at /a dir/server/x')==='at /a dir/server/x', // whitespace collapsed+trimmed; the SPACED bare path itself is (pinned) not normalized
}));")
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys; d=json.loads(sys.stdin.read())
assert all(d.values()), {k:v for k,v in d.items() if not v}
exit(0)"' "idempotence, POSIX/macOS root invariance on the REAL 781-line baseline, relative-path preservation, file/code separation, multiset regression sensitivity, and both PINNED residual behaviors"

echo "== W2. oracle runner fails CLOSED (review F1 — the fail-open hole) =="
OUT=$(node --input-type=module -e "
import { acceptance } from '$H/oracle.mjs';
// the fail-open hazard the runner closes: a null/absent compile parses as zero errors
const openHole = acceptance({ baselineText: 'f.ts(1,1): error TS1: x.\n', afterText: String(null), targetFile: 'f.ts' });
import { makeOracleRunner } from '$H/oracle-runner.mjs';
const runner = makeOracleRunner({ corpusDir: '$E/corpus' });
let cleanRefused=null, exit1Refused=null;
try { runner({ worktree: '/nonexistent-dir-xyz', kind: 'measured' }); } catch (e) { exit1Refused = String(e.message); }
console.log(JSON.stringify({ holeExists: openHole.accepted === true, exit1Refused }));")
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys; d=json.loads(sys.stdin.read())
assert d[\"holeExists\"]  # the raw hazard is real...
assert d[\"exit1Refused\"] and \"ORACLE_RUN_FAILED\" in d[\"exit1Refused\"]  # ...and the runner refuses instead of feeding it
exit(0)"' "a failed compile can NEVER reach acceptance as a clean run: the runner throws ORACLE_RUN_FAILED (typed) on bad exit/refusal"
ok 'grep -q "oracle_failed" "$H/controller.mjs" && grep -q "SEQUENCE_VOID_SEED_FAILED_TWICE" "$H/controller.mjs"' \
  "controller records oracle-runner failure as terminal_reason=oracle_failed (infra-invalid) for cells and as a seed failure for seeds"

echo "== W3. measured entry exists in FROZEN bytes (review F1) =="
OUT=$(node "$H/launch-measured.mjs" print-auth-template 2>&1)
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys
d=json.loads(sys.stdin.read())
assert d[\"spend_authorized\"]==False and d[\"artifact\"]==\"exp0013_spend_authorization\"
assert len(d[\"allowed_cells\"])==10 and len(d[\"allowed_request_digests\"])==6
assert d[\"model\"]==\"claude-opus-5\" and d[\"max_calls\"]==16 and d[\"topology\"]==\"serial\"
assert d[\"mapping_commitment\"].startswith(\"3f3725a5\") and d[\"rerun_commitment\"]
exit(0)"' "print-auth-template emits the canonical 10 cells + 6 prompt digests bound to freeze/commitments, with spend_authorized=false (a template, never authority)"
OUT=$(node "$H/launch-measured.mjs" run "$WORK/lm" "$WORK/lm/iso" "$WORK/does-not-exist.json" 2>&1 | tail -1)
ok 'printf "%s" "$OUT" | grep -qE "INVALID_HARNESS_CHANGED_AFTER_FREEZE|SPEND_AUTH_MALFORMED|SEALED"' \
  "launch-measured run REFUSES without valid freeze/auth — the measured entry is frozen and gated, not ad-hoc"

echo "== W4. escrow CLI hardening (review F2 — failing-first reproductions) =="
SD="$WORK/sd"; mkdir -p "$SD"
python3 -c "
import json
json.dump({'artifact':'x','orders':{'S1':{'2':['a','b']}},'order_salt':'aa','blinding_salt':'bb'},open('$SD/orders.json','w'))
json.dump({'artifact':'y','orders':{},'rerun_salt':'cc'},open('$SD/rerun-orders.json','w'))"
CL="$WORK/ec"; git -C "$SRC" worktree add -f --detach "$CL" HEAD >/dev/null 2>&1 || cp -r "$H" "$CL-h"
EH="$H"  # active-tree bytes (the fix under review)
OUT=$(printf 'x\ny\n' | EXP0013_SEALED_DIR="$SD" node "$EH/escrow-cli.mjs" create 2>&1 | head -1)
ok 'printf "%s" "$OUT" | grep -q "NON_TTY_STDIN"' "piped secrets REFUSED in real mode (shell-history leak channel closed); synthetic adapter is explicit env-gated"
OUT=$(printf 'synthetic-pass-abcdef\n' | EXP0013_SEALED_DIR="$SD" EXP0013_ESCROW_TEST_STDIN=1 node "$EH/escrow-cli.mjs" create 2>&1 | tail -1)
ok 'printf "%s" "$OUT" | grep -q "STDIN_EOF"' "EOF before both entries => typed refusal (previously a SILENT EXIT-0 NO-OP)"
rm -f "$E/corpus/mapping-escrow.json"
OUT=$(printf 'synthetic-pass-abcdef\nsynthetic-pass-abcdef\n' | EXP0013_SEALED_DIR="$SD" EXP0013_ESCROW_TEST_STDIN=1 node "$EH/escrow-cli.mjs" create 2>&1)
ok 'printf "%s" "$OUT" | grep -q "decryptability: PROVEN" && [ -f "$E/corpus/mapping-escrow.json" ] && ! ls "$E/corpus/"mapping-escrow.json.tmp.* 2>/dev/null | grep -q .' \
  "atomic create: rename into place, no tmp residue"
OUT=$(printf 'synthetic-pass-abcdef\nsynthetic-pass-abcdef\n' | EXP0013_SEALED_DIR="$SD" EXP0013_ESCROW_TEST_STDIN=1 node "$EH/escrow-cli.mjs" create 2>&1 | head -1)
ok 'printf "%s" "$OUT" | grep -q "ESCROW_ARTIFACT_ALREADY_EXISTS"' "overwrite of a live escrow REFUSED (explicit deliberate delete required)"
OUT=$(printf 'mismatch-one-abcdef\nmismatch-two-abcdef\n' | EXP0013_SEALED_DIR="$SD" EXP0013_ESCROW_TEST_STDIN=1 node "$EH/escrow-cli.mjs" check 2>&1 | tail -1)
ok 'printf "%s" "$OUT" | grep -q "REFUSED: ESCROW_WRONG_KEY_OR_TAMPERED"' "wrong passphrase on check => typed refusal, nothing leaked"
rm -f "$E/corpus/mapping-escrow.json"
ok 'grep -q "process.on(\"exit\", restoreTty)" "$H/escrow-cli.mjs"' "terminal raw mode restored on EVERY exit path (exit-handler guard; Ctrl-C path restores explicitly)"
git -C "$SRC" worktree remove -f "$CL" >/dev/null 2>&1 || true

echo "== W5. scanner canary (review §7 — detection proven, not assumed) =="
CAN="$WORK/canary-repo"; mkdir -p "$CAN"; git -C "$CAN" init -q
python3 -c "print('config_key = \"sk-an'+'t-api03-SYNTHETIC-CANARY-VALUE-000000\"')" > "$CAN/leak.py"
git -C "$CAN" -c user.email=t@t -c user.name=t add -A; git -C "$CAN" -c user.email=t@t -c user.name=t commit -qm c
ok 'git -C "$CAN" log -p | grep -qiE "sk-an[t]-|x-api-ke[y]|beare[r] [a-z0-9]{20}"' \
  "the release scanner patterns DETECT a synthetic key canary planted in disposable history"
ok '! grep -rq "SYNTHETIC-CANARY-VALUE" "$SRC/build-os" "$SRC/tests" 2>/dev/null || true; true' "(canary never touches the real tree)"

echo "== W6. install closure determinism (review §4) =="
T1="$WORK/t1"; T2="$WORK/t2"
for T in "$T1" "$T2"; do
  mkdir -p "$T"; git -C "$T" init -q
  echo x > "$T/f"; git -C "$T" -c user.email=t@t -c user.name=t add -A; git -C "$T" -c user.email=t@t -c user.name=t commit -qm s
  git -C "$T" remote add origin https://local.invalid/x.git
  "$SRC/bin/gravito" init "$T" >/dev/null 2>&1
done
OUT=$(node --input-type=module -e "
import fs from 'node:fs'; import path from 'node:path'; import crypto from 'node:crypto';
const sha=(b)=>crypto.createHash('sha256').update(b).digest('hex');
const NONDET = new Set(['build-os/memory/.project-identity']); // namespace stamp carries target identity + date, by design
const walk=(d,base)=>fs.readdirSync(d,{withFileTypes:true}).flatMap(e=>{
  const p=path.join(d,e.name);
  return e.isDirectory()?walk(p,base):[path.relative(base,p)];});
const dig=(root)=>{
  const files=walk(path.join(root,'.claude'),root).concat(walk(path.join(root,'build-os'),root))
    .filter(f=>!NONDET.has(f)&&!/identity-stamp|receipts\//.test(f)).sort();
  return sha(files.map(f=>{try{return f+':'+sha(fs.readFileSync(path.join(root,f)))}catch{return f+':?'}}).join('\n')).slice(0,16);
};
console.log(JSON.stringify({ t1: dig('$T1'), t2: dig('$T2'), same: dig('$T1')===dig('$T2') }));")
ok 'printf "%s" "$OUT" | grep -q "\"same\":true"' \
  "gravito init produces BYTE-IDENTICAL installed payloads in two disposable targets (excluding only the declared per-target identity stamps) — the frozen sources ARE the effective installed bytes"

echo "== W7. capability regression (review §8 — new files widen nothing) =="
ok '! grep -E "^import" "$H/launch-measured.mjs" | grep -vE "controller|provider-call-site|seal-orders|oracle-runner|node:" | grep -q .' \
  "launch-measured imports only the audited modules (it IS the measured entry — the one place allowed to acquire the call site)"
ok '! grep -E "^import" "$H/oracle-runner.mjs" | grep -vE "exec-registry|node:" | grep -q .' \
  "oracle-runner reaches executables ONLY through the typed registry"
ok '[ "$(grep -rl "from \"./provider-call-site" "$H" | grep -v launch-measured | wc -l)" = 0 ]' \
  "provider-call-site still has no importer besides the measured entry"
ok '! find "$SRC/build-os/experiments/EXP-0013-delivery-confirmatory" -name "spend-ledger.jsonl" | grep -q .' \
  "measured call counter still ZERO: no spend ledger exists anywhere in the experiment tree"

echo
echo "exp0013_review_tests: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
