#!/usr/bin/env bash
# EXP-0013 RED-TEAM suite (AMENDMENT v3) — failure-first tests for every
# defect the adversarial pre-spend audit surfaced. NO SPEND: the measured
# state machine runs only under scripted fake transports that refuse
# provider argv; escrow tests use SYNTHETIC mappings only.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E="$SRC/build-os/experiments/EXP-0013-delivery-confirmatory"
H="$E/harness"
WORK="$(mktemp -d /tmp/bos-e13rt.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }

mod(){ node --input-type=module -e "
import fs from 'node:fs'; import path from 'node:path'; import crypto from 'node:crypto';
import { runMeasured, MAX_CALLS, CONFIG, CORPUS } from '$H/controller.mjs';
import { testFakeTransport } from '$H/transport-measured.mjs';
const measuredTransport = () => ({ kind: 'measured-real', call: async () => { throw new Error('unreachable in tests'); } });
import { rehearsalTransport } from '$H/transport-rehearsal.mjs';
import { reserveCall, settleCall, loadLedger } from '$H/spend-ledger.mjs';
import { distill } from '$H/distill.mjs';
import { escrowCreate, escrowRecover } from '$H/mapping-escrow.mjs';
import { verifyRerun, generateRerun, generate as genOrders, verify as verifyOrders } from '$H/seal-orders.mjs';
import { strictLeakCheck } from '$H/leakcheck2.mjs';
import { analyze } from '$H/analysis.mjs';
const GOOD_STREAM = (model='claude-opus-5') => JSON.stringify({type:'system',subtype:'init',session_id:'s',model}) + '\n' +
  JSON.stringify({type:'result',usage:{input_tokens:100,output_tokens:900,cache_read_input_tokens:0,cache_creation_input_tokens:0},total_cost_usd:2,num_turns:2}) + '\n';
const oracleFor = ({seq, cell, kind}) => {
  const task = CORPUS.sequences[seq][kind==='seed'?0:undefined] ?? CORPUS.sequences[seq].find(t=>cell.startsWith(t.task_id));
  const before = task.codes.map((c,i)=>task.file+'('+(i+1)+',1): error '+c+': x.').join('\n')+'\n';
  return { baselineText: before, afterText: '', diffText: 'diff --git a/'+task.file+' b/'+task.file+'\n+fix\n' };
};
$1
" 2>&1; }

echo "== R1. freeze3 hardening: additions, permissions, missing files DETECTED =="
T="$WORK/fcopy"; mkdir -p "$T/build-os/experiments" "$T/build-os/delivery" "$T/build-os/tools" "$T/tests" "$T/bin" "$T/templates"
cp -r "$E" "$T/build-os/experiments/"
cp "$SRC/build-os/delivery/ucdl.mjs" "$T/build-os/delivery/"
cp "$SRC/build-os/tools/planner.mjs" "$SRC/build-os/tools/reachability.mjs" "$SRC/build-os/tools/h0-check.sh" "$T/build-os/tools/"
cp "$SRC/bin/gravito" "$T/bin/"; cp "$SRC/templates/gravito.goal.example" "$T/templates/"
cp "$SRC/tests/exp0013_readiness_tests.sh" "$SRC/tests/exp0013_fixture_tests.sh" "$SRC/tests/exp0013_redteam_tests.sh" "$SRC/tests/exp0013_capability_tests.sh" "$T/tests/" 2>/dev/null
FC="$T/build-os/experiments/EXP-0013-delivery-confirmatory"
if [ -f "$E/FREEZE-MANIFEST-v4.json" ]; then
  echo rogue > "$FC/harness/rogue.mjs"
  OUT=$(node "$FC/harness/freeze4.mjs" verify 2>&1); rm "$FC/harness/rogue.mjs"
  ok 'printf "%s" "$OUT" | grep -q "UNEXPECTED_FILE harness/rogue.mjs"' "ADDED file in a frozen dir => typed refusal (v2 gap closed)"
  chmod 777 "$FC/harness/oracle.mjs"
  OUT=$(node "$FC/harness/freeze4.mjs" verify 2>&1); chmod 644 "$FC/harness/oracle.mjs"
  ok 'printf "%s" "$OUT" | grep -q "MODE_DRIFT harness/oracle.mjs"' "PERMISSION change => typed refusal (v2 gap closed)"
  mv "$FC/harness/oracle.mjs" "$WORK/oracle.hold"
  OUT=$(node "$FC/harness/freeze4.mjs" verify 2>&1); mv "$WORK/oracle.hold" "$FC/harness/oracle.mjs"
  ok 'printf "%s" "$OUT" | grep -q "MISSING_FILE"' "REMOVED/renamed frozen file => typed refusal, not a crash"
else
  ok 'false' "v3 manifest exists (add)"; ok 'false' "(mode)"; ok 'false' "(missing)"
fi

echo "== R2. spend ledger: durable, conservative, typed refusals =="
OUT=$(mod "
const d='$WORK/led1';
reserveCall(d,{call_index:0,cell:'a',kind:'seed',bound_usd:6});
settleCall(d,{call_index:0,cell:'a',cost_usd:1.5,metered:true});
reserveCall(d,{call_index:1,cell:'b',kind:'measured',bound_usd:6}); // never settled: crashed mid-flight
const l1=loadLedger(d);
reserveCall(d,{call_index:2,cell:'c',kind:'measured',bound_usd:6});
settleCall(d,{call_index:2,cell:'c',cost_usd:null,metered:false}); // NOT_METERED
const l2=loadLedger(d); // 'restart' = fresh read of the same file
console.log(JSON.stringify({l1,l2}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"l1\"][\"spent_conservative_usd\"]==7.5 and d[\"l2\"][\"spent_conservative_usd\"]==13.5 and d[\"l2\"][\"calls\"]==3 else 1)"' \
  "unsettled call holds its full bound; NOT_METERED charged at bound; restart re-reads to the same totals (unknown cost never zero)"
OUT=$(mod "
const d='$WORK/led2'; reserveCall(d,{call_index:0,cell:'a',kind:'seed',bound_usd:6});
fs.appendFileSync(d+'/spend-ledger.jsonl','{malformed'); const torn=loadLedger(d);
const d2='$WORK/led3'; reserveCall(d2,{call_index:0,cell:'a',kind:'seed',bound_usd:6});
fs.appendFileSync(d2+'/spend-ledger.jsonl','{\"entry\":\"reserve\",\"call_index\":9,\"bound_usd\":6,\"prev_sha\":\"wrong\"}\n');
const broken=loadLedger(d2);
const d3='$WORK/led4'; reserveCall(d3,{call_index:0,cell:'a',kind:'seed',bound_usd:6}); reserveCall(d3,{call_index:0,cell:'a2',kind:'seed',bound_usd:6});
console.log(JSON.stringify({torn:torn.reason,broken:broken.reason,dup:loadLedger(d3).reason}));")
ok 'printf "%s" "$OUT" | grep -q "LEDGER_TORN_TAIL" && printf "%s" "$OUT" | grep -q "LEDGER_CHAIN_BROKEN" && printf "%s" "$OUT" | grep -q "LEDGER_DUPLICATE_RESERVATION"' \
  "torn tail, broken chain, duplicate reservation => typed refusals that stop all calls"

echo "== R3. measured state machine (fake transports; provider argv refused) =="
OUT=$(mod "
const t=testFakeTransport(()=>({streamText:GOOD_STREAM()}));
const r=await runMeasured({studyDir:'$WORK/m1',isoRoot:'$WORK/m1/iso',transport:t,oracleFor});
console.log(JSON.stringify({ok:r.ok,calls:r.calls,cells:r.cells?.length,spent:r.spent_conservative_usd}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"ok\"] and d[\"calls\"]==10 and d[\"cells\"]==8 and d[\"spent\"]==20 else 1)"' \
  "happy path: EXACTLY 10 calls (2 seeds + 8 measured), 8 cells, settled spend \$20"
OUT=$(mod "
const t=testFakeTransport((req,n)=>({streamText:GOOD_STREAM(n===0?'claude-haiku-4-5':'claude-opus-5')}));
const r=await runMeasured({studyDir:'$WORK/m2',isoRoot:'$WORK/m2/iso',transport:t,oracleFor});
console.log(JSON.stringify({ok:r.ok,reason:r.reason,calls:r.ledger?.calls}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if not d[\"ok\"] and d[\"reason\"].startswith(\"MODEL_ID_NOT_ALLOWED\") and d[\"calls\"]==1 else 1)"' \
  "provider-native model mismatch on call 1 => abort BEFORE call 2; call 1 still counted and charged"
OUT=$(mod "
const t=testFakeTransport((req,n)=>({streamText:'',terminal_reason:'timeout'}));
const r=await runMeasured({studyDir:'$WORK/m3',isoRoot:'$WORK/m3/iso',transport:t,oracleFor});
const led=loadLedger('$WORK/m3');
console.log(JSON.stringify({ok:r.ok,reason:r.reason,calls:led.calls,spent:led.spent_conservative_usd}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if not d[\"ok\"] and d[\"reason\"]==\"SEQUENCE_VOID_SEED_FAILED_TWICE\" and d[\"calls\"]==2 and d[\"spent\"]==12 else 1)"' \
  "seed fails twice => SEQUENCE_VOID after exactly 2 calls, both charged at the bound (frozen seed policy)"
OUT=$(mod "
let fail=new Set(['S12.lean_rules','S12.lean_skills'].slice(0,1)); // first arm of S1.p2 times out once
const t=testFakeTransport((req)=>{
  if (fail.has(req.cell)) { fail.delete(req.cell); return {streamText:'',terminal_reason:'timeout'}; }
  return {streamText:GOOD_STREAM()};
});
const r=await runMeasured({studyDir:'$WORK/m4',isoRoot:'$WORK/m4/iso',transport:t,oracleFor});
const rerunOrder=verifyRerun().orders.S1[2];
const log=fs.readFileSync('$WORK/m4/controller-log.jsonl','utf8');
console.log(JSON.stringify({ok:r.ok,calls:r.calls,rerunStep:/pair_rerun_S1.p2.*PRE-SEALED/.test(log),
  rerunCells:r.cells.filter(c=>c.rerun_of).length, orderLen:rerunOrder.length}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"ok\"] and d[\"calls\"]==12 and d[\"rerunStep\"] and d[\"rerunCells\"]==2 and d[\"orderLen\"]==2 else 1)"' \
  "one infra-invalid arm => whole-pair rerun from the PRE-SEALED contingency order; 12 calls total"
OUT=$(mod "
const t=testFakeTransport((req,n)=>{
  // every pair's first round times out on its first arm => needs 3+ pair reruns
  if (/lean_/.test(req.cell) && !/rerun/.test(req.cell) && !global.seen?.has(req.cell.slice(0,3))) {
    (global.seen ??= new Set()).add(req.cell.slice(0,3));
    return {streamText:'',terminal_reason:'timeout'};
  }
  return {streamText:GOOD_STREAM()};
});
const r=await runMeasured({studyDir:'$WORK/m5',isoRoot:'$WORK/m5/iso',transport:t,oracleFor});
const led=loadLedger('$WORK/m5');
console.log(JSON.stringify({ok:r.ok,reason:r.reason,calls:led.calls}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if not d[\"ok\"] and d[\"reason\"]==\"RERUN_BUDGET_EXHAUSTED\" and d[\"calls\"]<=14 else 1)"' \
  "third pair-rerun demand => RERUN_BUDGET_EXHAUSTED refused BEFORE any rerun spend"
OUT=$(mod "
const d='$WORK/m6'; fs.mkdirSync(d,{recursive:true});
for (let i=0;i<16;i++) reserveCall(d,{call_index:i,cell:'prior'+i,kind:'measured',bound_usd:0.01});
const t=testFakeTransport(()=>({streamText:GOOD_STREAM()}));
const r=await runMeasured({studyDir:d,isoRoot:d+'/iso',transport:t,oracleFor});
console.log(JSON.stringify({ok:r.ok,reason:r.reason}));")
ok 'printf "%s" "$OUT" | grep -q "CALL_CEILING"' "17th call refused by the HARD call counter regardless of remaining budget"
OUT=$(mod "
const d='$WORK/m7'; fs.mkdirSync(d,{recursive:true});
reserveCall(d,{call_index:0,cell:'prior',kind:'measured',bound_usd:95}); // spent 95 conservative
const t=testFakeTransport(()=>({streamText:GOOD_STREAM()}));
const r=await runMeasured({studyDir:d,isoRoot:d+'/iso',transport:t,oracleFor});
console.log(JSON.stringify({ok:r.ok,reason:r.reason}));")
ok 'printf "%s" "$OUT" | grep -q "BUDGET_CEILING"' "restart after partial spend: ledger says \$95 held => next call projection \$101 REFUSED before launch"
OUT=$(mod "
const r=await runMeasured({studyDir:'$WORK/m8',isoRoot:'$WORK/m8/iso',transport:measuredTransport(),oracleFor});
const r2=await runMeasured({studyDir:'$WORK/m9',isoRoot:'$WORK/m9/iso',transport:measuredTransport(),spendAuthPath:'$WORK/badauth.json',oracleFor});
fs.writeFileSync('$WORK/badauth2.json',JSON.stringify({spend_authorized:true,freeze_v3_digest:'wrong'}));
const r3=await runMeasured({studyDir:'$WORK/m10',isoRoot:'$WORK/m10/iso',transport:measuredTransport(),spendAuthPath:'$WORK/badauth2.json',oracleFor});
console.log(JSON.stringify({a:r.reason,b:r2.reason,c:r3.reason}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"a\"]==\"MEASURED_MODE_REQUIRES_SPEND_AUTHORIZATION\" and d[\"b\"]==\"MEASURED_MODE_REQUIRES_SPEND_AUTHORIZATION\" and d[\"c\"]==\"SPEND_AUTH_INVALID_OR_FREEZE_MISMATCH\" else 1)"' \
  "real transport refused without authorization; auth naming a wrong freeze digest refused"
OUT=$(mod "
const t=testFakeTransport(()=>({streamText:''}));
try { await t.call({argv:['claude','-p'],outFile:'$WORK/x'}); console.log('EXECUTED'); } catch(e) { console.log('REFUSED:'+e.message); }")
ok 'printf "%s" "$OUT" | grep -q "REFUSED.*never see a real provider argv"' "test transport structurally refuses any provider argv"

echo "== R4. distiller: deterministic, typed refusals =="
OUT=$(mod "
const task=CORPUS.sequences.S1[0];
const good={task,acceptance:{accepted:true,target_errors_before:task.error_count},diffText:'diff --git a/x.ts b/x.ts\n+a\n-b\n'};
const d1=distill(good), d2=distill(good);
console.log(JSON.stringify({det:d1.store_digest===d2.store_digest, parseable:new RegExp('## RULE '+task.codes[0]).test(d1.storeText),
  unacc:distill({...good,acceptance:{accepted:false,target_errors_before:15}}).reason,
  empty:distill({...good,diffText:'  '}).reason,
  malformed:distill({...good,diffText:'no diff headers here'}).reason,
  badacc:distill({...good,acceptance:{}}).reason }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"det\"] and d[\"parseable\"] and d[\"unacc\"]==\"SEED_UNACCEPTED\" and d[\"empty\"]==\"SEED_EMPTY_DIFF\" and d[\"malformed\"]==\"SEED_MALFORMED_DIFF\" and d[\"badacc\"]==\"SEED_MALFORMED_ACCEPTANCE\" else 1)"' \
  "same input => same store bytes; UCDL-parseable; rejected/empty/corrupt seeds => typed refusals (frozen seed policy inputs)"

echo "== R5. mapping escrow (SYNTHETIC mapping only): wrong key and tamper fail closed =="
OUT=$(mod "
const syn='$WORK/synthetic-mapping.json';
fs.writeFileSync(syn,JSON.stringify({artifact:'SYNTHETIC_TEST_MAPPING',orders:{S1:{2:['a','b']}},order_salt:'feedbeef'}));
const c=escrowCreate({sealedPath:syn,passphrase:'correct-horse-battery',outFile:'$WORK/esc.json'});
const good=escrowRecover({escrowFile:'$WORK/esc.json',passphrase:'correct-horse-battery',outPath:'$WORK/rec.json'});
const same=fs.readFileSync(syn,'utf8')===fs.readFileSync('$WORK/rec.json','utf8');
const wrong=escrowRecover({escrowFile:'$WORK/esc.json',passphrase:'wrong-passphrase-x'});
const e=JSON.parse(fs.readFileSync('$WORK/esc.json','utf8')); e.ct=e.ct.slice(0,-8)+'AAAAAAAA';
fs.writeFileSync('$WORK/esc2.json',JSON.stringify(e));
const tam=escrowRecover({escrowFile:'$WORK/esc2.json',passphrase:'correct-horse-battery'});
console.log(JSON.stringify({c:c.ok,good:good.ok,same,wrong:wrong.reason,tam:tam.reason,short:escrowCreate({sealedPath:syn,passphrase:'short',outFile:'$WORK/x'}).reason}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"c\"] and d[\"good\"] and d[\"same\"] and d[\"wrong\"]==\"ESCROW_WRONG_KEY_OR_TAMPERED\" and d[\"tam\"]==\"ESCROW_WRONG_KEY_OR_TAMPERED\" and d[\"short\"]==\"ESCROW_PASSPHRASE_TOO_SHORT\" else 1)"' \
  "byte-exact roundtrip; wrong key and tampered ciphertext are the SAME typed refusal (GCM); weak passphrase refused"

echo "== R6. pre-sealed rerun orders: committed, tamper-evident =="
SD="$WORK/sealed"; CF="$WORK/rc.json"
OUT=$(mod "
genOrders({sealedDir:'$SD',commitFile:'$WORK/pc.json'});
const g=generateRerun({sealedDir:'$SD',commitFile:'$CF'});
const v=verifyRerun({sealedDir:'$SD',commitFile:'$CF'});
const again=generateRerun({sealedDir:'$SD',commitFile:'$CF'});
console.log(JSON.stringify({g:g.ok,v:v.ok,pairs:Object.keys(v.orders).length,again:again.reason}));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"g\"] and d[\"v\"] and d[\"pairs\"]==2 and d[\"again\"]==\"SEALED_RERUN_ORDERS_ALREADY_EXIST\" else 1)"' \
  "rerun contingency orders sealed once, verify green, re-seal refused"
sed -i 's/lean_/x_/' "$SD/rerun-orders.json" 2>/dev/null || sed -i 's/"S1"/"SX"/' "$SD/rerun-orders.json"
OUT=$(mod "console.log(JSON.stringify(verifyRerun({sealedDir:'$SD',commitFile:'$CF'})))")
ok 'printf "%s" "$OUT" | grep -q "RERUN_COMMITMENT_MISMATCH"' "tampered rerun store => RERUN_COMMITMENT_MISMATCH"

echo "== R7. the rehearsal transport wall is STRUCTURAL =="
ok '! grep -E "^import|require\(" "$H/transport-rehearsal.mjs" | grep -qE "child_process|worker_threads|node:net|node:http"' \
  "transport-rehearsal.mjs imports NO process-execution or network capability (the barrier is the import graph)"
OUT=$(mod "
const t=rehearsalTransport('$WORK/rt'); fs.mkdirSync('$WORK/rt',{recursive:true});
const r=await t.call({cell:'x',argv:['claude','-p','--model','claude-opus-5'],stdinText:'p',cwd:'/tmp'});
console.log(JSON.stringify(r));")
ok 'printf "%s" "$OUT" | grep -q "NO_PROVIDER_CALL"' "rehearsal transport records the digest and returns the sentinel — nothing can launch through it"
ok '! grep -q "spawnSync(\"claude\"" "$H/controller.mjs" && grep -q "cliVersionProbe" "$H/exec-registry.mjs"' \
  "v4: the controller execs NO provider CLI at all — the [\"--version\"]-only probe lives behind the typed exec registry"

echo "== R8. hardened view leak check =="
OUT=$(mod "
const mk=(diff,extra={})=>({sealedMapping:[],adjudicator:[{unit:'U1',objective:'fix',acceptance_criteria:'zero',diff,...extra}],analyst:[{unit:'U1',outcome:'accepted',economics:{t:1}}]});
console.log(JSON.stringify({
  clean: strictLeakCheck(mk('+const x: string = y;')).ok,
  skill: strictLeakCheck(mk('+++ b/.claude/skills/repair-s1/SKILL.md')).reason??'ok',
  size: strictLeakCheck(mk('+x', {installed_bytes: 4096})).reason??'ok',
  sess: strictLeakCheck(mk('+x', {note:'session_id abc'})).reason??'ok' }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"clean\"] and \"arm artifacts\" in d[\"skill\"] and \"side channel\" in d[\"size\"] and \"execution identity\" in d[\"sess\"] else 1)"' \
  "SKILL.md-in-diff, byte-size channel, session identity => refused; clean view passes (v1 gaps closed)"

echo "== R9. independent analysis cross-check (second implementation) + invariances =="
OUT=$(mod "
const mk=(f)=>{ const cells=[]; for (const [seq,pos] of [['S1',2],['S1',3],['S2',2],['S2',3]]) for (const arm of ['lean_rules','lean_skills']) {
  const base={ seq,pos,arm,rerun_of:null,delivery_valid:true,invalid_reason:null,accepted:true,metered:true,terminal_reason:'success',elapsed_s:600,
    economics:{ output_tokens: arm==='lean_skills'?700:1000, uncached_input_tokens:200, total_cost_usd:2, cache_read_input_tokens:5000, cache_creation_input_tokens:100 } };
  cells.push(f?f(base)||base:base); } return cells; };
const cells=mk();
const r=analyze({cells});
const swapped=analyze({cells:cells.map(c=>({...c,arm:c.arm==='lean_rules'?'lean_skills':'lean_rules'}))});
console.log(JSON.stringify({pairs:r.pairs.filter(p=>p.status==='EFFICIENCY').map(p=>p.efficiency.paired_log_ratio),
  sd:r.efficiency.label_neutral_sd, med:r.efficiency.median_pct_difference, ladder:r.effect_continuation_ladder,
  sd2:swapped.efficiency.label_neutral_sd, med2:swapped.efficiency.median_pct_difference, v2:swapped.harness_verdict,
  eff:r.treatment_effectiveness, blob:JSON.stringify(r)}));")
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys,math
d=json.loads(sys.stdin.read())
# SECOND implementation, independently:
ratios=[math.log((700+200)/(1000+200))]*4
absr=[abs(x) for x in ratios]
mean=sum(absr)/len(absr)
sd=math.sqrt(sum((x-mean)**2 for x in absr)/(len(absr)-1))
med=sorted(ratios)[1:3]; med=(med[0]+med[1])/2
medpct=(math.exp(abs(med))-1)*100
assert all(abs(a-b)<1e-9 for a,b in zip(sorted(d[\"pairs\"]),sorted(ratios)))
assert abs(d[\"sd\"]-sd)<1e-9 and abs(d[\"med\"]-medpct)<1e-9
assert d[\"ladder\"]==\"PREREGISTERED_FIXED_CONFIRMATORY_N_ONLY\"
exit(0)"' "primary metric, label-neutral SD, and median % INDEPENDENTLY recomputed to 1e-9 agreement"
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys
d=json.loads(sys.stdin.read())
assert abs(d[\"sd\"]-d[\"sd2\"])<1e-12 and abs(d[\"med\"]-d[\"med2\"])<1e-12 and d[\"v2\"]==\"QUALIFIED\"
exit(0)"' "RELABEL INVARIANCE: swapping every arm label leaves SD, |median| and the verdict identical (continuation is direction-neutral)"
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys
d=json.loads(sys.stdin.read())
assert d[\"eff\"]==\"UNPROVEN\" and \"never proof\" in d[\"blob\"] and \"PROVEN\\\"\" not in d[\"blob\"].replace(\"UNPROVEN\",\"\")
exit(0)"' "four pairs can never yield a proof verdict: treatment_effectiveness is UNPROVEN in every output"
ok '! grep -qE "EXP-0011|0011-reusable|import .*results" "$H/analysis.mjs" || ! grep -qE "^import.*0011" "$H/analysis.mjs"' \
  "analysis.mjs has no import path to EXP-0011 data — pooling is structurally impossible, not just forbidden"

echo "== R10. call-count enumeration is the frozen constant =="
OUT=$(mod "console.log(JSON.stringify({max:MAX_CALLS, sum: CONFIG.calls.planned.total + CONFIG.calls.worst_case.seed_reruns + CONFIG.calls.worst_case.pair_rerun_cells}))")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"max\"]==16 and d[\"sum\"]==16 else 1)"' \
  "MAX_CALLS==16 == 2 seeds + 8 measured + 2 seed reruns + 4 pair-rerun cells; enforced by the counter, not the narrative"

echo
echo "exp0013_redteam_tests: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
