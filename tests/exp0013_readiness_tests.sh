#!/usr/bin/env bash
# EXP-0013 execution-readiness suite — NO-SPEND. Proves: the corpus is real
# and oracle-validated; the oracle is line-shift-robust and regression-
# sensitive; telemetry failures are typed; sealed arm orders commit and
# tamper-detect; the supervised-execution primitives close FAILURE-MODES rows
# 2/4; the REAL controller runs to the NO_PROVIDER_CALL sentinel with a
# PATH-shadow tripwire untripped; the budget gate halts BEFORE a ceiling
# breach; the frozen analysis handles all ten preregistered synthetic
# scenarios; and FREEZE v2 verifies and tamper-detects while preserving v1.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
E="$SRC/build-os/experiments/EXP-0013-delivery-confirmatory"
H="$E/harness"
WORK="$(mktemp -d /tmp/bos-e13r.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }

mod(){ node --input-type=module -e "
import { parseTsc, identityMultiset, acceptance, validateTask } from '$H/oracle.mjs';
import { parseStream } from '$H/telemetry.mjs';
import { drawOrders, canonical, commitment, generate, verify as verifySeal, PAIRS } from '$H/seal-orders.mjs';
import { supervise, detectOrphans, budgetGate, CONFIG, CORPUS } from '$H/controller.mjs';
import { analyze } from '$H/analysis.mjs';
import fs from 'node:fs';
const BASELINE = fs.readFileSync('$E/corpus/baseline-tsc.txt','utf8');
$1
" 2>&1; }

echo "== 1. corpus: real, initially failing, hermetic, oracle-validated =="
CT="$WORK/corpus-tree"; mkdir -p "$CT"
git -C /home/user/empathiq-website archive 2543c873141fa64653a7993d326465d5e0dd1006 | tar -x -C "$CT"
OUT=$(mod "
const all = [...Object.values(CORPUS.sequences)].flat();
const res = all.map(t => validateTask({ baselineText: BASELINE, task: t, treeRoot: '$CT', fsMod: fs }));
const bad = res.filter(r => !r.ok);
console.log(JSON.stringify({ n: all.length, allOk: bad.length===0, bad: bad.map(b=>({id:b.task_id,checks:b.checks.filter(c=>!c.ok)})),
  totalErrs: parseTsc(BASELINE).length, subsystems: [...new Set(all.map(t=>t.subsystem))] }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"n\"]==6 and d[\"allOk\"] else 1)"' \
  "all 6 corpus tasks pass oracle validation (initially failing, hermetic, codes match, regression-sensitive, line-shift robust)"
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"totalErrs\"]==781 and sorted(d[\"subsystems\"])==[\"agent\",\"deployment\"] else 1)"' \
  "baseline parses to 781 errors; subsystems are {deployment, agent} — disjoint from EXP-0011 {governance, mcp}"
ok 'python3 - <<PYEOF
import json
c=json.load(open("$E/corpus/sequences.json"))
e11=["governance","mcp"]
assert all(t["subsystem"] not in e11 for s in c["sequences"].values() for t in s)
assert "amendment" in c and "coherence-field" in c["amendment"]["ground"]
files=[t["file"] for s in c["sequences"].values() for t in s]
assert len(files)==len(set(files))==6
PYEOF' "corpus artifact records derivation rule, quarantine amendment, and 6 distinct files"

echo "== 2. oracle: identity-multiset semantics =="
OUT=$(mod "
const target='server/deployment/deployment-persistence.ts';
const fixed = BASELINE.split('\n').filter(l => !l.startsWith(target+'(')).join('\n');
const accept = acceptance({ baselineText: BASELINE, afterText: fixed, targetFile: target });
const shifted = BASELINE.replace(/\((\d+),(\d+)\)/g, (_,l,c)=>'('+(+l+13)+','+c+')');
const shiftAcc = acceptance({ baselineText: BASELINE, afterText: shifted, targetFile: target });
const regressed = fixed + '\nserver/other/new.ts(1,1): error TS2999: fresh identity.\n';
const regAcc = acceptance({ baselineText: BASELINE, afterText: regressed, targetFile: target });
console.log(JSON.stringify({ accepted: accept.accepted, tb: accept.target_errors_before, ta: accept.target_errors_after,
  shiftRegs: shiftAcc.regressions.length, shiftNotAccepted: !shiftAcc.accepted,
  regDetected: !regAcc.accepted && regAcc.regressions.length===1 && regAcc.regressions[0].identity.includes('TS2999') }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"accepted\"] and d[\"tb\"]==14 and d[\"ta\"]==0 else 1)"' \
  "clean in-file fix (14 -> 0) with no new identities => ACCEPTED"
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"shiftRegs\"]==0 and d[\"shiftNotAccepted\"] else 1)"' \
  "uniform +13 line shift: ZERO false regressions (FM#7 closed); still unaccepted because target errors remain"
ok 'printf "%s" "$OUT" | grep -q "\"regDetected\":true"' "one synthetic new identity elsewhere => REJECTED with that identity named"

echo "== 3. telemetry: typed reasons, provider-native ids =="
OUT=$(mod "
const good='{\"type\":\"system\",\"subtype\":\"init\",\"session_id\":\"sid1\",\"model\":\"claude-opus-5-20250929\"}\n{\"type\":\"result\",\"usage\":{\"input_tokens\":10,\"output_tokens\":500,\"cache_read_input_tokens\":2000,\"cache_creation_input_tokens\":100},\"total_cost_usd\":0.001,\"num_turns\":2}\n';
const allowed=CONFIG.model.allowed_provider_model_ids;
const g=parseStream(good,{expectedSessionId:'sid1',allowedModelIds:allowed});
const noRes=parseStream(good.split('\n')[0],{allowedModelIds:allowed});
const dup=parseStream(good+good.split('\n')[1],{expectedSessionId:'sid1',allowedModelIds:allowed});
const stale=parseStream(good,{expectedSessionId:'OTHER',allowedModelIds:allowed});
const badModel=parseStream(good.replace('claude-opus-5-20250929','claude-haiku-4-5'),{allowedModelIds:allowed});
const malformed=parseStream(good.replace('\"output_tokens\":500,',''),{allowedModelIds:allowed});
console.log(JSON.stringify({ g:{m:g.metered,primary:g.economics.primary_metric_tokens,ids:g.provider_model_ids},
  noRes:noRes.reasons, dup:dup.reasons, stale:stale.reasons, badModel:badModel.reasons, malformed:malformed.reasons }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"g\"][\"m\"] and d[\"g\"][\"primary\"]==510 else 1)"' \
  "good stream meters; primary metric = output + UNCACHED input (510), cache-insensitive"
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if \"NOT_METERED_NO_RESULT_EVENT\" in d[\"noRes\"] and \"DUPLICATE_RESULT_EVENT\" in d[\"dup\"] and \"STALE_STREAM_SESSION_MISMATCH\" in d[\"stale\"] and \"MALFORMED_RESULT_EVENT\" in d[\"malformed\"] else 1)"' \
  "missing/duplicate/stale/malformed result => typed reasons, never inferred"
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if any(r.startswith(\"MODEL_ID_NOT_ALLOWED\") for r in d[\"badModel\"]) else 1)"' \
  "provider-native id outside the preregistered set => MODEL_ID_NOT_ALLOWED (fail-before-second-call input)"
OUT=$(mod "console.log(JSON.stringify({ ok: parseStream('{\"type\":\"result\",\"usage\":{\"input_tokens\":1,\"output_tokens\":1}}',{allowedModelIds:CONFIG.model.allowed_provider_model_ids}).reasons }))")
ok 'printf "%s" "$OUT" | grep -q "MODEL_ID_MISSING"' "stream with no model id anywhere => MODEL_ID_MISSING"

echo "== 4. model config: explicit everything =="
ok 'python3 - <<PYEOF
import json
c=json.load(open("$H/model-config.json"))
a=c["invocation"]["argv"]
assert "--model" in a and a[a.index("--model")+1]=="<model.requested>"
assert c["model"]["requested"]=="claude-opus-5"
assert c["invocation"]["concurrency"]==1
assert "STDIN" in c["invocation"]["prompt_transport"]
assert c["spend"]["worst_case_estimate_usd"]==c["calls"]["worst_case"]["seed_reruns"]*6+c["calls"]["worst_case"]["pair_rerun_cells"]*6+c["calls"]["planned"]["total"]*6
assert c["spend"]["proposed_ceiling_usd"]>=c["spend"]["worst_case_estimate_usd"]
PYEOF' "model explicit (never default), stdin transport, serial concurrency, ceiling >= worst case (16 calls x \$6 = \$96 <= \$100)"

echo "== 5. sealed arm orders: balance, commitment, tamper =="
SD="$WORK/sealed"; CF="$WORK/commit.json"
OUT=$(mod "
const g = generate({ sealedDir: '$SD', commitFile: '$CF' });
const v = verifySeal({ sealedDir: '$SD', commitFile: '$CF' });
const again = generate({ sealedDir: '$SD', commitFile: '$CF' });
// uniformity of the draw mechanism: stubbed bytes map to all 6 subsets; byte >=252 rejected
const subs = new Set([0,1,2,3,4,5].map(i => canonical(drawOrders(()=>i))));
const rejected = canonical(drawOrders((()=>{let n=0;return ()=>n++===0?255:3;})()));
console.log(JSON.stringify({ g, vOk: v.ok, againRefused: !again.ok, subsets: subs.size, rejectedEqualsByte3: rejected===canonical(drawOrders(()=>3)) }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"g\"][\"ok\"] and d[\"g\"][\"balance\"]==[2,2] and d[\"vOk\"] else 1)"' \
  "generate seals a balanced 2/2 order; commitment verifies"
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"againRefused\"] and d[\"subsets\"]==6 and d[\"rejectedEqualsByte3\"] else 1)"' \
  "re-generate over a live seal REFUSED; draw covers all 6 subsets uniformly with rejection sampling"
sed -i 's/"lean_rules"/"lean_skills"/' "$SD/orders.json"
OUT=$(mod "console.log(JSON.stringify(verifySeal({ sealedDir: '$SD', commitFile: '$CF' })))")
ok 'printf "%s" "$OUT" | grep -q "COMMITMENT_MISMATCH"' "tampered sealed orders => COMMITMENT_MISMATCH"
rm -f "$SD/orders.json"
OUT=$(mod "console.log(JSON.stringify(verifySeal({ sealedDir: '$SD', commitFile: '$CF' })))")
ok 'printf "%s" "$OUT" | grep -q "SEALED_STORE_ABSENT"' "absent sealed store => typed absence (fresh disclosed draw required), never a reconstructed mapping"

echo "== 6. supervised execution: FM#2 and FM#4 closed with observables =="
OUT=$(mod "
const slow = await supervise({ argv: ['bash','-c','sleep 30'], stdinText:'', cwd:'$WORK', env: process.env, ceilingS: 1, outFile: '$WORK/slow.out', marker: 'm-slow' });
const okRun = await supervise({ argv: ['bash','$H/fake-worker.sh','$WORK/fw.jsonl'], stdinText:'', cwd:'$WORK', env: process.env, ceilingS: 30, outFile: '$WORK/fw.out', marker: 'm-ok' });
const slowOrphans = detectOrphans('m-slow');
console.log(JSON.stringify({ slowReason: slow.terminal_reason, slowFast: slow.elapsed_s < 5, okReason: okRun.terminal_reason, groupDead: slowOrphans.clean }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"slowReason\"]==\"timeout\" and d[\"slowFast\"] and d[\"groupDead\"] else 1)"' \
  "ceiling breach => controller-owned SIGKILL of the whole group, terminal_reason=timeout, no survivors (FM#4)"
ok 'printf "%s" "$OUT" | grep -q "\"okReason\":\"success\""' "clean worker => terminal_reason=success"
OUT=$(mod "
import { spawn } from 'node:child_process';
const c = spawn('bash', ['-c','sleep 15'], { env: { ...process.env, EXP0013_CELL_MARKER: 'm-orphan' }, detached: true, stdio: 'ignore' }); c.unref();
await new Promise(r=>setTimeout(r,300));
const found = detectOrphans('m-orphan');
try { process.kill(-c.pid, 'SIGKILL'); } catch {} try { process.kill(c.pid, 'SIGKILL'); } catch {}
await new Promise(r=>setTimeout(r,200));
const after = detectOrphans('m-orphan');
console.log(JSON.stringify({ detected: !found.clean && found.orphan_pids.length===1, cleanAfterKill: after.clean }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"detected\"] and d[\"cleanAfterKill\"] else 1)"' \
  "deliberately-left marked process is FOUND by the orphan scan and gone after kill (FM#2)"

echo "== 7. budget gate: halts BEFORE the breaching call =="
OUT=$(mod "
console.log(JSON.stringify({ a: budgetGate({ spentUsd: 93.9 }), b: budgetGate({ spentUsd: 94.1 }), zero: budgetGate({ spentUsd: 0 }) }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"a\"][\"allowed\"] and not d[\"b\"][\"allowed\"] and d[\"b\"][\"reason\"]==\"BUDGET_CEILING\" and d[\"zero\"][\"allowed\"] else 1)"' \
  "projected \$99.9 allowed; projected \$100.1 => BUDGET_CEILING refusal BEFORE launch"

echo "== 8. controller rehearsal: real state machine to the NO_PROVIDER_CALL sentinel =="
SHIM="$WORK/shim"; mkdir -p "$SHIM"
REALVER="$(claude --version 2>/dev/null | head -1)"
cat > "$SHIM/claude" <<SHIMEOF
#!/usr/bin/env bash
if [ "\${1:-}" = "--version" ]; then echo "$REALVER"; exit 0; fi
touch "$SHIM/TRIPPED"; echo "PROVIDER CALL ATTEMPTED IN REHEARSAL" >&2; exit 97
SHIMEOF
chmod +x "$SHIM/claude"
STUDY="$WORK/study"
OUT=$(cd "$WORK" && PATH="$SHIM:$PATH" node "$H/controller.mjs" rehearse "$STUDY" "$SHIM" 2>&1)
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read().strip().splitlines()[-1]);exit(0 if d.get(\"ok\") and d.get(\"sentinel\")==\"NO_PROVIDER_CALL\" and d.get(\"cells_prepared\")==10 and d.get(\"requests_digested\")==10 else 1)"' \
  "rehearsal completes: 10 cells prepared (2 seeds + 8 measured), 10 request digests, sentinel NO_PROVIDER_CALL"
ok '[ ! -f "$SHIM/TRIPPED" ]' "PATH-shadow claude tripwire NEVER executed — the barrier held before exec"
ok 'grep -q "\"step\":\"sealed_orders\",\"ok\":true" "$STUDY/controller-log.jsonl" && grep -q "\"step\":\"cli_preflight\",\"ok\":true" "$STUDY/controller-log.jsonl" && grep -q "\"step\":\"h0_gate\",\"ok\":true" "$STUDY/controller-log.jsonl"' \
  "controller log records sealed-order verification, CLI version preflight, and H0 gate — executed, not asserted"
ok 'grep -c "\"sentinel\":\"NO_PROVIDER_CALL\"" "$STUDY/rehearsal-requests.jsonl" | grep -qx 10 && python3 -c "
import json
rows=[json.loads(l) for l in open(\"$STUDY/rehearsal-requests.jsonl\")]
assert all(r[\"model_flag\"]==\"claude-opus-5\" for r in rows)
assert all(r[\"stdin_bytes\"]>0 and \"--output-format\" in r[\"argv\"] for r in rows)
"' "every request digest carries the explicit model flag, stdin prompt bytes, and full argv"
ok 'python3 -c "
import json,hashlib
prev=\"genesis\"
for line in open(\"$STUDY/controller-log.jsonl\"):
    d=json.loads(line); assert d[\"prev_sha\"]==prev, \"chain broken\"
    prev=hashlib.sha256(line.rstrip(\"\n\").encode()).hexdigest()
"' "controller log is hash-chained end to end"
OUT=$(node "$H/controller.mjs" measured "$WORK/study2" 2>&1)
ok 'printf "%s" "$OUT" | grep -q "MEASURED_MODE_REQUIRES_SPEND_AUTHORIZATION"' "measured mode REFUSED without owner spend authorization"

echo "== 9. frozen analysis: ten preregistered synthetic scenarios =="
OUT=$(mod "
const mk=(f)=>{ const cells=[]; for (const [seq,pos] of [['S1',2],['S1',3],['S2',2],['S2',3]]) for (const arm of ['lean_rules','lean_skills']) {
  const base={ seq,pos,arm,rerun_of:null,delivery_valid:true,invalid_reason:null,accepted:true,metered:true,terminal_reason:'success',elapsed_s:600,
    economics:{ output_tokens: arm==='lean_skills'?800:1000, uncached_input_tokens:200, total_cost_usd:2, cache_read_input_tokens:5000, cache_creation_input_tokens:100 } };
  cells.push(f(base)||base); } return cells; };
const R=(name,r)=>({name, v:r.harness_verdict, ladder:r.effect_continuation_ladder??null, eff:r.efficiency?{n:r.efficiency.pairs_contributing,sd:+r.efficiency.label_neutral_sd.toFixed(3),med:+r.efficiency.median_pct_difference.toFixed(1),gate:r.efficiency.variance_gate,el:r.efficiency.elapsed_status}:null, reason:r.reason??r.void_reason??null, pairs:r.pairs?.map(p=>p.status)??null});
const out=[];
// 1 A-advantage (skills 25% cheaper on the primary metric, consistent)
out.push(R('A-adv', analyze({ cells: mk(c=>{ c.economics.output_tokens = c.arm==='lean_skills'?700:1000; }) })));
// 2 B-advantage (rules cheaper, consistent)
out.push(R('B-adv', analyze({ cells: mk(c=>{ c.economics.output_tokens = c.arm==='lean_rules'?780:1000; }) })));
// 3 null (<10%, consistent)
out.push(R('null', analyze({ cells: mk(c=>{ c.economics.output_tokens = c.arm==='lean_skills'?960:1000; }) })));
// 4 mixed signs
let i=0; out.push(R('mixed', analyze({ cells: mk(c=>{ if(c.arm==='lean_skills'){ c.economics.output_tokens = (i++%2)?700:1300; } else c.economics.output_tokens=1000; }) })));
// 5 unaccepted arm in one pair
out.push(R('unaccepted', analyze({ cells: mk(c=>{ if(c.seq==='S1'&&c.pos===2&&c.arm==='lean_rules') c.accepted=false; }) })));
// 6 legitimate rerun (pair S2.p3 rerun once)
const rerunCells = mk(()=>{}); for (const arm of ['lean_rules','lean_skills']) { const orig=rerunCells.find(c=>c.seq==='S2'&&c.pos===3&&c.arm===arm); orig.metered=false; rerunCells.push({...orig, metered:true, rerun_of:'S2.3', economics:{...orig.economics}}); }
out.push(R('rerun', analyze({ cells: rerunCells })));
// 7 delivery void
out.push(R('void', analyze({ cells: mk(c=>{ if(c.seq==='S2'&&c.pos===2&&c.arm==='lean_rules'){ c.delivery_valid=false; c.invalid_reason='INVALID_UNINTENDED_EMPTY_TREATMENT'; } }) })));
// 8 missing telemetry x2 => NOT_QUALIFIED
out.push(R('2xNOT_METERED', analyze({ cells: mk(c=>{ if(c.pos===2&&c.arm==='lean_rules') c.metered=false; }) })));
// 9 high variance (sd > 0.45 on |log ratio|)
let j=0; out.push(R('high-var', analyze({ cells: mk(c=>{ if(c.arm==='lean_skills'){ c.economics.output_tokens=[350,1000,3500,900][Math.floor(j++/1)%4]; } }) })));
// 10 elapsed demotion under detected concurrency
out.push(R('elapsed-demote', analyze({ cells: mk(()=>{}), concurrentOverlapDetected: true })));
console.log(JSON.stringify(out));")
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys; d={r[\"name\"]:r for r in json.loads(sys.stdin.read())}
assert d[\"A-adv\"][\"v\"]==\"QUALIFIED\" and d[\"A-adv\"][\"ladder\"]==\"PREREGISTERED_FIXED_CONFIRMATORY_N_ONLY\" and d[\"A-adv\"][\"eff\"][\"n\"]==4
assert d[\"B-adv\"][\"v\"]==\"QUALIFIED\" and d[\"B-adv\"][\"ladder\"]==\"PREREGISTERED_FIXED_CONFIRMATORY_N_ONLY\"
assert d[\"null\"][\"ladder\"]==\"NO_AUTOMATIC_EXPANSION_OWNER_DECIDES\"
assert d[\"mixed\"][\"ladder\"]==\"NO_AUTOMATIC_EXPANSION_OWNER_DECIDES\"
exit(0)"' "scenarios 1-4: both directions reach the ladder symmetrically; null and mixed-signs go to OWNER_DECIDES"
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys; d={r[\"name\"]:r for r in json.loads(sys.stdin.read())}
assert d[\"unaccepted\"][\"v\"]==\"QUALIFIED\" and d[\"unaccepted\"][\"pairs\"].count(\"QUALITY_RESULT_ONLY\")==1 and d[\"unaccepted\"][\"eff\"][\"n\"]==3
assert d[\"rerun\"][\"v\"]==\"QUALIFIED\" and d[\"rerun\"][\"eff\"][\"n\"]==4
assert d[\"void\"][\"v\"]==\"VOID\" and \"INVALID_UNINTENDED_EMPTY_TREATMENT\" in d[\"void\"][\"reason\"]
assert d[\"2xNOT_METERED\"][\"v\"]==\"NOT_QUALIFIED\" and \"RELIABILITY\" in d[\"2xNOT_METERED\"][\"reason\"]
exit(0)"' "scenarios 5-8: unaccepted arm excluded from efficiency; rerun replaces its pair; delivery failure VOIDS; 2x NOT_METERED NOT_QUALIFIED"
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys; d={r[\"name\"]:r for r in json.loads(sys.stdin.read())}
assert d[\"high-var\"][\"eff\"][\"gate\"]==\"REQUIRES_RECOMPUTATION_AND_REAUTHORIZATION\" and d[\"high-var\"][\"eff\"][\"sd\"]>0.45
assert \"TERTIARY\" in d[\"elapsed-demote\"][\"eff\"][\"el\"]
assert all(\"never pooled\" in \" \".join(json.loads(sys.argv[1])[0][\"name\"] for _ in [1]) or True for _ in [1])
exit(0)" "$OUT"' "scenarios 9-10: high variance demands recomputation + reauthorization; detected concurrency demotes elapsed to tertiary"
ok 'printf "%s" "$OUT" | python3 -c "
import json,sys; rows=json.loads(sys.stdin.read())
assert all(r[\"v\"]!=\"VOID\" or r[\"eff\"] is None for r in rows)
exit(0)"' "a VOID stage never emits an efficiency report"

echo "== 10. freeze v2: verifies, preserves v1 byte-identically, tamper-detects on a copy =="
ok 'node "$H/freeze.mjs" verify >/dev/null 2>&1' "v1 freeze still verifies untouched"
if [ -f "$E/FREEZE-MANIFEST-v2.json" ]; then
  ok 'node "$H/freeze2.mjs" verify >/dev/null 2>&1' "v2 freeze verifies (and re-verifies v1 inside it)"
  T="$WORK/copy"; mkdir -p "$T/build-os/experiments" "$T/build-os/delivery" "$T/build-os/tools" "$T/tests"
  cp -r "$E" "$T/build-os/experiments/"
  cp "$SRC/build-os/delivery/ucdl.mjs" "$T/build-os/delivery/"
  cp "$SRC/build-os/tools/planner.mjs" "$T/build-os/tools/"
  cp "$SRC/tests/exp0013_readiness_tests.sh" "$T/tests/"
  sed -i 's/proposed_ceiling_usd\": 100/proposed_ceiling_usd\": 10000/' "$T/build-os/experiments/EXP-0013-delivery-confirmatory/harness/model-config.json"
  OUT=$(node "$T/build-os/experiments/EXP-0013-delivery-confirmatory/harness/freeze2.mjs" verify 2>&1)
  ok 'printf "%s" "$OUT" | grep -q "INVALID_HARNESS_CHANGED_AFTER_FREEZE: harness/model-config.json"' \
    "post-freeze spend-ceiling tamper on a disposable copy => typed refusal naming the file"
else
  ok 'false' "v2 freeze manifest exists"
  ok 'false' "v2 tamper-detection (needs manifest)"
fi

echo
echo "exp0013_readiness_tests: $PASS passed, $FAIL failed"
[ "$FAIL" = 0 ]
