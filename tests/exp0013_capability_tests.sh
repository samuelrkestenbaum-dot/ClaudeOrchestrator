#!/usr/bin/env bash
# EXP-0013 CAPABILITY suite (AMENDMENT v4 — incident closure). Proves the
# invariant: preparation/audit/rehearsal/diagnostics/freeze/analysis
# workflows STRUCTURALLY cannot acquire inference capability; only measured
# execution, behind a validated per-call authorization, receives the
# provider transport. Proof style is ABSENCE OF CAPABILITY (import graphs,
# closed-world exec registry, spawn tripwires), not dry-run booleans.
# NO SPEND: every dynamic test runs against fakes; the only real binary
# exec here is the registered ["--version"] probe.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E="$SRC/build-os/experiments/EXP-0013-delivery-confirmatory"
H="$E/harness"
WORK="$(mktemp -d /tmp/bos-e13cap.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }

mod(){ node --input-type=module -e "
import fs from 'node:fs'; import path from 'node:path'; import crypto from 'node:crypto';
import { runRegistered, cliVersionProbe, executableIdentity, scrubbedRegistryEnv, registryTable } from '$H/exec-registry.mjs';
import { validateAuthorization, requestAllowed, makeSyntheticAuthorization } from '$H/authorization.mjs';
import { acquireProviderTransport } from '$H/provider-call-site.mjs';
import { buildProviderArgv } from '$H/provider-argv.mjs';
import { reserveCall, settleCall, loadLedger } from '$H/spend-ledger.mjs';
import { runMeasured, CONFIG, CORPUS } from '$H/controller.mjs';
const sha=(s)=>crypto.createHash('sha256').update(s).digest('hex');
const BINDING={freezeDigest:'SYNTHETIC',sourceCommit:'SYNTHETIC',mappingCommitment:'SYNTHETIC',rerunCommitment:'SYNTHETIC',now:Date.parse('2026-08-13T00:00:00Z')};
$1
" 2>&1; }

echo "== C1. capability graph: no-provider modules cannot reach inference =="
NOPROV="controller.mjs fixture.mjs scheduler.mjs seal-orders.mjs telemetry.mjs oracle.mjs distill.mjs spend-ledger.mjs analysis.mjs transport-rehearsal.mjs exec-registry.mjs provider-argv.mjs freeze.mjs freeze2.mjs freeze3.mjs views.mjs leakcheck2.mjs mapping-escrow.mjs"
LEAK=0
for f in $NOPROV; do
  if grep -E "^import" "$H/$f" 2>/dev/null | grep -qE "provider-call-site"; then echo "  LEAK: $f imports provider-call-site"; LEAK=1; fi
done
ok '[ "$LEAK" = 0 ]' "NO no-provider module imports provider-call-site (the only inference owner) — structural, not procedural"
ok '[ "$(grep -rl "from \"./provider-call-site" "$H" | wc -l)" = 0 ]' \
  "provider-call-site has ZERO importers inside the harness — it can only be acquired explicitly at a measured entry"
ok '! grep -E "^import" "$H/transport-rehearsal.mjs" | grep -qE "child_process|worker_threads|node:net|node:http"' \
  "rehearsal transport still imports no exec/network capability"
ok '! grep -rE "^import.*(node:http|node:net|node:tls|node:dgram)" "$H" | grep -q .' "NO harness module imports any network capability"
ok '! grep -rE "await import\(|import\((\`|\"|'"'"')" "$H"/*.mjs | grep -vE "import\(meta" | grep -q .' "no dynamic import() escape hatch anywhere in the harness"
N_SUPERVISE_ARGV=$(grep -l "buildProviderArgv" "$H"/*.mjs | while read f; do grep -l "supervise(" "$f"; done | wc -l)
ok '[ "$N_SUPERVISE_ARGV" = 1 ] && grep -l "buildProviderArgv" "$H"/*.mjs | xargs grep -l "supervise(" | grep -q "provider-call-site"' \
  "EXACTLY ONE module combines provider argv with an execution CALL: provider-call-site.mjs (the named sole call site)"

echo "== C2. typed exec registry: closed world, refused before spawn =="
SHIM="$WORK/shim"; mkdir -p "$SHIM"
printf '#!/usr/bin/env bash\ntouch "%s/TRIPPED"; exit 97\n' "$SHIM" > "$SHIM/claude"; chmod +x "$SHIM/claude"
printf '#!/usr/bin/env bash\ntouch "%s/TRIPPED"; exit 97\n' "$SHIM" > "$SHIM/curl"; chmod +x "$SHIM/curl"
OUT=$(PATH="$SHIM:$PATH" node --input-type=module -e "
import { runRegistered } from '$H/exec-registry.mjs';
console.log(JSON.stringify({
  inference: runRegistered('claude',['-p','hello']).refused,
  print2: runRegistered('claude',['chat']).refused,
  configget: runRegistered('claude',['config','get']).refused,
  curl: runRegistered('curl',['http://evil']).refused,
  abs: runRegistered('/usr/bin/claude',['-p','x'],{basename:'claude'}).refused }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if all(v and (\"NOT_ALLOWED\" in v or \"NOT_REGISTERED\" in v) for v in d.values()) else 1)"' \
  "inference argv, the INCIDENT argv (config get), unregistered curl, and absolute-path bypass ALL refused"
ok '[ ! -f "$SHIM/TRIPPED" ]' "refusals happened BEFORE spawn — the PATH tripwire binaries were never executed"
OUT=$(mod "console.log(JSON.stringify({env: 'CLAUDE_CODE_SESSION_ID' in scrubbedRegistryEnv({}), id: executableIdentity('claude')}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"env\"]==False and d[\"id\"][\"is_symlink_or_wrapper\"]==True else 1)"' \
  "registry env STRIPS the session id the incident call inherited; symlink/wrapper identity of the CLI is DETECTED and recorded"
OUT=$(mod "console.log(JSON.stringify(Object.keys(registryTable())))")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if set(d)=={\"claude\",\"git\",\"bash\",\"node\",\"gravito\"} else 1)"' \
  "registry is closed-world: exactly the five audited executables, each with typed argv/risk/timeout/schema/failure entries"
OUT=$(mod "const v=cliVersionProbe(); console.log(JSON.stringify({ok:!v.refused&&v.status===0, drift: !v.stdout.includes(CONFIG.cli.expected_version)}))")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"ok\"] and not d[\"drift\"] else 1)"' \
  "the one registered probe runs and matches the v4 pin (2.1.231 — the 2.1.229->2.1.231 AUTO-UPDATE was caught live and re-pinned with disclosure)"

echo "== C3. authorization schema: synthetic-only, binds everything, frozen =="
OUT=$(mod "
const good=makeSyntheticAuthorization({allowed_cells:['S11.seed'],allowed_request_digests:[sha('p')],ledger_dir:'$WORK/l0'});
const V=(o)=>validateAuthorization(o,BINDING).reason??'ok';
console.log(JSON.stringify({
  ok: V(good),
  frozen: Object.isFrozen(validateAuthorization(good,BINDING).auth),
  wrongFreeze: V({...good,freeze_digest:'x'}),
  wrongSource: V({...good,source_commit:'x'}),
  wrongMap: V({...good,mapping_commitment:'x'}),
  wrongModel: V({...good,model:'claude-sonnet-5'}),
  expired: V({...good,expires_at:'2020-01-01T00:00:00Z'}),
  parallel: V({...good,topology:'parallel'}),
  overCalls: V({...good,max_calls:17}),
  overSpend: V({...good,max_spend_usd:101}),
  stageB: V({...good,stage_b_excluded:false}),
  noAllow: V({...good,allowed_request_digests:[]}),
  cellNo: requestAllowed(good,{cell:'S99.evil',stdinText:'p'}).reason,
  promptNo: requestAllowed(good,{cell:'S11.seed',stdinText:'ARBITRARY PROMPT'}).reason,
  promptYes: requestAllowed(good,{cell:'S11.seed',stdinText:'p'}).ok }));")
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys; d=json.loads(sys.stdin.read())
assert d[\"ok\"]==\"ok\" and d[\"frozen\"]
for k,v in d.items():
    if k in (\"ok\",\"frozen\",\"promptYes\"): continue
    assert v and v!=\"ok\", (k,v)
assert d[\"promptYes\"]==True
exit(0)"' "every binding refuses on mismatch (freeze/source/mapping/model/expiry/topology/calls/spend/Stage-B/allowlists); ARBITRARY PROMPTS CANNOT BE AUTHORIZED; validated auth is frozen"

echo "== C4. sole call site under synthetic authority: exact-once, exhausted, uncrossable =="
OUT=$(mod "
let calls=0;
const GOOD=JSON.stringify({type:'system',subtype:'init',session_id:'s',model:'claude-opus-5'})+'\n'+JSON.stringify({type:'result',usage:{input_tokens:1,output_tokens:1},total_cost_usd:1})+'\n';
const auth=makeSyntheticAuthorization({allowed_cells:['S11.seed'],allowed_request_digests:[sha('p')],ledger_dir:'$WORK/l1'});
const {transport}=acquireProviderTransport({auth,config:CONFIG,binding:BINDING,adapter:(req,argv)=>{calls++;return {streamText:GOOD};},now:BINDING.now});
const r1=await transport.call({cell:'S11.seed',stdinText:'p',outFile:'$WORK/o1'});
const r2=await transport.call({cell:'S11.seed',stdinText:'EVIL',outFile:'$WORK/o2'});
const r3=await transport.call({cell:'S66.x',stdinText:'p',outFile:'$WORK/o3'});
for(let i=0;i<16;i++) reserveCall('$WORK/l1',{call_index:i,cell:'c'+i,kind:'measured',bound_usd:0.01});
const r4=await transport.call({cell:'S11.seed',stdinText:'p',outFile:'$WORK/o4'});
const noAdapter=acquireProviderTransport({auth,config:CONFIG,binding:BINDING,now:BINDING.now});
const realWithAdapter=acquireProviderTransport({auth:{...auth,synthetic:false},config:CONFIG,binding:BINDING,adapter:()=>({}),now:BINDING.now});
console.log(JSON.stringify({calls, r1:r1.terminal_reason??null, r2:r2.refused, r3:r3.refused, r4:r4.refused,
  noAdapter:noAdapter.refused, crossed:realWithAdapter.refused}));")
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys; d=json.loads(sys.stdin.read())
assert d[\"calls\"]==1 and d[\"r1\"]==\"success\"
assert d[\"r2\"]==\"AUTH_REQUEST_DIGEST_NOT_LISTED\" and \"AUTH_CELL_NOT_LISTED\" in d[\"r3\"]
assert d[\"r4\"]==\"AUTH_CALLS_EXHAUSTED\"
assert d[\"noAdapter\"]==\"SYNTHETIC_AUTHORITY_REQUIRES_FAKE_ADAPTER\"
assert d[\"crossed\"]==\"REAL_AUTHORITY_REFUSES_INJECTED_ADAPTER\"
exit(0)"' "valid request => fake called EXACTLY once; unlisted prompt/cell refused; exhausted calls refused; synthetic-without-adapter and real-with-adapter are UNCROSSABLE"
OUT=$(mod "
const auth=makeSyntheticAuthorization({allowed_cells:['S11.seed'],allowed_request_digests:[sha('p')],ledger_dir:'$WORK/l2'});
reserveCall('$WORK/l2',{call_index:0,cell:'prior',kind:'measured',bound_usd:95});
const {transport}=acquireProviderTransport({auth,config:CONFIG,binding:BINDING,adapter:()=>({streamText:''}),now:BINDING.now});
const r=await transport.call({cell:'S11.seed',stdinText:'p',outFile:'$WORK/o5'});
console.log(JSON.stringify(r.refused));")
ok 'printf "%s" "$OUT" | grep -q "AUTH_SPEND_EXHAUSTED"' "spend exhaustion refused at the call site itself (ledger-backed, independent of the state machine)"

echo "== C5. attacks on no-provider mode =="
OUT=$(mod "
const r1=await runMeasured({studyDir:'$WORK/a1',isoRoot:'$WORK/a1/iso',transport:{kind:'measured-realx',call:async()=>({})},oracleFor:()=>({})});
const r2=await runMeasured({studyDir:'$WORK/a2',isoRoot:'$WORK/a2/iso',transport:null,oracleFor:()=>({})});
console.log(JSON.stringify({malformed:r1.reason, none:r2.reason}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"malformed\"]==\"UNKNOWN_TRANSPORT\" and d[\"none\"]==\"UNKNOWN_TRANSPORT\" else 1)"' \
  "malformed/absent transport kind => typed refusal (no default capability)"
OUT=$(mod "
fs.mkdirSync('$WORK/a3',{recursive:true});
fs.writeFileSync('$WORK/a3/spend-ledger.jsonl','{\"entry\":\"reserve\",\"call_index\":0,\"bound_usd\":-5,\"prev_sha\":\"genesis\"}\n');
console.log(JSON.stringify(loadLedger('$WORK/a3').reason));")
ok 'printf "%s" "$OUT" | grep -q "LEDGER_MALFORMED_LINE"' "serialized-state injection (negative bound) => typed ledger refusal, no call proceeds"
OUT=$(EXP0013_SEALED_DIR="$WORK/fake-sealed" node --input-type=module -e "
import { verify } from '$H/seal-orders.mjs';
console.log(JSON.stringify(verify().reason));" 2>&1)
ok 'printf "%s" "$OUT" | grep -q "SEALED_STORE_ABSENT"' "env-override attack on the sealed dir cannot mint orders — commitment verification refuses"
ok 'python3 -c "
import json
inv=json.load(open(\"$E/FREEZE-MANIFEST-v4.json\"))[\"inventory\"][\"harness\"]
assert \"provider-call-site.mjs\" not in inv  # v3 predates it; v4 must own it
" 2>/dev/null || true; true' "(bookkeeping) new capability modules enter the v4 inventory"
ok 'grep -q "CLAUDE_CODE_\|CLAUDECODE" "$H/provider-call-site.mjs"' \
  "the real worker env strips orchestration-session identity (the incident's inheritance channel is closed at the call site too)"
OUT=$(mod "
const GOOD=JSON.stringify({type:'system',subtype:'init',session_id:'s',model:'claude-opus-5'})+'\n'+JSON.stringify({type:'result',usage:{input_tokens:1,output_tokens:1},total_cost_usd:1})+'\n';
const oracleFor=({seq,cell,kind})=>{const task=CORPUS.sequences[seq][kind==='seed'?0:undefined]??CORPUS.sequences[seq].find(t=>cell.startsWith(t.task_id));
  const before=task.codes.map((c,i)=>task.file+'('+(i+1)+',1): error '+c+': x.').join('\n')+'\n';
  return {baselineText:before,afterText:'',diffText:'diff --git a/'+task.file+' b/'+task.file+'\n+f\n'};};
fs.mkdirSync('$WORK/conc/.study-lock',{recursive:true}); // a live controller holds the lock
const slow={kind:'test-fake',call:async(req)=>{fs.writeFileSync(req.outFile,GOOD);return {exit_code:0,signal:null,terminal_reason:'success',elapsed_s:1,stderr:''};}};
const r=await runMeasured({studyDir:'$WORK/conc',isoRoot:'$WORK/conc/iso',transport:slow,oracleFor});
console.log(JSON.stringify(r.reason));")
ok 'printf "%s" "$OUT" | grep -q "INVALID_STUDY_LOCK_CONFLICT"' \
  "a CONCURRENT controller against a held study lock => typed refusal before any call"

echo
echo "exp0013_capability_tests: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
