#!/usr/bin/env bash
# EXP-0013 Stage-A fixture — deterministic NO-SPEND qualification. Proves the
# planner-descriptor -> UCDL seam, treatment equivalence, pre-spend
# invalidation, receipts, scheduler topology, blinding separation, freeze
# integrity, and that production behavior + sealed evidence are untouched.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
H="$SRC/build-os/experiments/EXP-0013-delivery-confirmatory/harness"
WORK="$(mktemp -d /tmp/bos-e13.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }

# Disposable repo whose GOAL carries objective terms (the planner seam input).
R="$WORK/repo"; mkdir -p "$R"; git -C "$R" init -q; git -C "$R" remote add origin https://x/e13.git
echo base > "$R/app.txt"; git -C "$R" -c user.email=t@t -c user.name=t add -A; git -C "$R" -c user.email=t@t -c user.name=t commit -qm s
"$SRC/bin/gravito" init "$R" >/dev/null 2>&1
cp "$SRC/templates/gravito.goal.example" "$WORK/goal.txt"
sed -i 's/^goal: .*/goal: Fix TS2305 and TS2339 type errors in the governance subsystem/' "$WORK/goal.txt"
"$SRC/bin/gravito" goal "$WORK/goal.txt" "$R" >/dev/null
STORE="$SRC/build-os/experiments/EXP-0011-reusable-skills/memory-stores/G.rep1.leanrules/repair-rules.md"

mod(){ node --input-type=module -e "
import { plan } from '$SRC/build-os/tools/planner.mjs';
import { constructReachability } from '$SRC/build-os/tools/reachability.mjs';
import { buildTreatments, admitCell, appendReceipt, verifyReceipts, validateDescriptor, INVALID } from '$H/fixture.mjs';
import { buildSchedule, validateExecutionLog, isolationManifest } from '$H/scheduler.mjs';
import { buildViews, viewLeakCheck } from '$H/views.mjs';
import fs from 'node:fs';
const reach = constructReachability('$R');
const pr = plan({ run_id: 'e13-q1', dir: '$R', reach, candidates: ['run'] });
const CR = pr.plan.cognition_requirement;
const STORE = fs.readFileSync('$STORE','utf8');
$1
" 2>&1; }

echo "== 1. the seam: REAL planner descriptor reaches UCDL; both arms select identically =="
OUT=$(mod "
const t = buildTreatments({ ids: { experiment:'EXP-0013', stage:'A', cell:'S1.p2.q', pair:'S1.p2', sequence:'S1', position:2, rep:1 },
  descriptor: CR, storeText: STORE, capBytes: 6144, expectEvidence: true });
console.log(JSON.stringify({ adm: t.admissible,
  terms: CR.objective_terms,
  ids_equal: JSON.stringify(t.arms?.lean_rules.receipt.selected_ids) === JSON.stringify(t.arms?.lean_skills.receipt.selected_ids),
  payload_equal: t.arms?.lean_rules.receipt.evidence_payload_bytes === t.arms?.lean_skills.receipt.evidence_payload_bytes,
  overhead_differs: t.arms?.lean_rules.receipt.renderer_overhead_bytes !== t.arms?.lean_skills.receipt.renderer_overhead_bytes,
  outputs_differ: t.arms?.lean_rules.output !== t.arms?.lean_skills.output,
  skill_fm: /^---\nname: repair-s1\n/.test(t.arms?.lean_skills.output || '') }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"adm\"] and \"TS2305\" in d[\"terms\"] else 1)"' \
  "planner extracted objective terms from the goal; treatments admissible"
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"ids_equal\"] and d[\"payload_equal\"] else 1)"' \
  "IDENTICAL selected evidence ids + payload bytes across both arms"
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"outputs_differ\"] and d[\"overhead_differs\"] and d[\"skill_fm\"] else 1)"' \
  "renderers differ ONLY in representation (overhead differs, SKILL.md frontmatter present)"

echo "== 2. pre-spend invalidation: EXP-0011's defect class cannot reach a worker =="
OUT=$(mod "
const t = buildTreatments({ ids: { sequence:'S1', position:2 }, descriptor: CR,
  storeText: '## RULE TS9999 — no overlap\n- applicability: files where tsc reports any of: TS9999\n- provenance: sequence=S1 rep=1 position=1 run=r authored_by=t\n',
  capBytes: 6144, expectEvidence: true });
console.log(JSON.stringify({ adm: t.admissible, reason: t.reason }));")
ok 'printf "%s" "$OUT" | grep -q "INVALID_UNINTENDED_EMPTY_TREATMENT"' "zero-evidence treatment => typed INVALID before any worker call"
OUT=$(mod "
const bad = { ...CR, state: 'NO_CONTEXT_ALLOWED' };
console.log(JSON.stringify(validateDescriptor(bad)));")
ok 'printf "%s" "$OUT" | grep -q "NOT_CONTEXT_REQUIRED"' "wrong descriptor state => typed refusal"
OUT=$(mod "
console.log(JSON.stringify([
  admitCell({ receipt:{artifact:'exp0013_delivery_receipt',plan_id:'x'}, prompt_via_stdin:false }).reason,
  admitCell({ receipt:{artifact:'exp0013_delivery_receipt',plan_id:'x'}, freeze_intact:false }).reason,
  admitCell({ receipt:{artifact:'exp0013_delivery_receipt',plan_id:'x'}, prompt_digest_frozen:false }).reason,
  admitCell({ receipt:{artifact:'exp0013_delivery_receipt',plan_id:'x'}, worktree_identity_ok:false }).reason,
  admitCell({ receipt:{artifact:'exp0013_delivery_receipt',plan_id:'x'} }).admitted ?? admitCell({receipt:{artifact:'exp0013_delivery_receipt',plan_id:'x'}}).reason ]));")
ok 'printf "%s" "$OUT" | grep -q "ARGV_FORBIDDEN" && printf "%s" "$OUT" | grep -q "CHANGED_AFTER_FREEZE" && printf "%s" "$OUT" | grep -q "PROMPT_BYTES" && printf "%s" "$OUT" | grep -q "WORKTREE"' \
  "admissibility yields typed reasons: argv, post-freeze change, prompt bytes, worktree identity"

echo "== 3. receipts: complete, chained, tamper-evident =="
RES="$WORK/results"
OUT=$(mod "
const t = buildTreatments({ ids: { experiment:'EXP-0013', stage:'A', cell:'S1.p2.q', pair:'S1.p2', sequence:'S1', position:2, rep:1 },
  descriptor: CR, storeText: STORE, capBytes: 6144, expectEvidence: true });
appendReceipt('$RES', t.arms.lean_rules.receipt);
appendReceipt('$RES', t.arms.lean_skills.receipt);
console.log(JSON.stringify(verifyReceipts('$RES')));")
ok 'printf "%s" "$OUT" | grep -q "\"ok\":true" && [ "$(grep -c . "$RES/delivery-receipts.jsonl")" = 2 ]' "two receipts appended, chain verifies"
REQ='harness_version plan_id cognition_descriptor_digest store_digest selected_ids selector_policy renderer_version evidence_payload_bytes renderer_overhead_bytes total_installed_bytes budget truncated installed_artifact_digest access_observed'
MISS=0; for k in $REQ; do grep -q "\"$k\"" "$RES/delivery-receipts.jsonl" || { echo "  missing field: $k"; MISS=1; }; done
ok '[ "$MISS" = 0 ]' "receipt schema complete (all required fields present)"
ok 'grep -q "NOT_OBSERVABLE" "$RES/delivery-receipts.jsonl"' "worker access honestly NOT_OBSERVABLE at delivery time"
sed -i '1s/S1/SX/' "$RES/delivery-receipts.jsonl"
OUT=$(mod "console.log(JSON.stringify(verifyReceipts('$RES')))")
ok 'printf "%s" "$OUT" | grep -q "\"ok\":false"' "tampered receipt breaks the chain: DETECTED"

echo "== 4. scheduler: one lane per sequence, serial positions, arms never concurrent =="
OUT=$(mod "
const s = buildSchedule({ sequences:['S1','S2'], positions:[2,3],
  armOrder: { S1:{2:['lean_rules','lean_skills'],3:['lean_skills','lean_rules']}, S2:{2:['lean_skills','lean_rules'],3:['lean_rules','lean_skills']} } });
const good = validateExecutionLog([
  {seq:'S1',pos:2,arm:'lean_rules',start:0,end:10},{seq:'S1',pos:2,arm:'lean_skills',start:10,end:20},
  {seq:'S2',pos:2,arm:'lean_skills',start:0,end:12} ]);
const badSerial = validateExecutionLog([
  {seq:'S1',pos:2,arm:'lean_rules',start:0,end:10},{seq:'S1',pos:3,arm:'lean_rules',start:5,end:15} ]);
const badPair = validateExecutionLog([
  {seq:'S1',pos:2,arm:'lean_rules',start:0,end:10},{seq:'S1',pos:2,arm:'lean_skills',start:5,end:15} ]);
const iso = isolationManifest('$WORK/iso', ['S1','S2']);
console.log(JSON.stringify({ ok:s.ok, lanes:s.concurrency, good:good.ok, badSerial:badSerial.ok, badPair:badPair.ok, iso:iso.ok }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"ok\"] and d[\"lanes\"]==2 and d[\"good\"] and not d[\"badSerial\"] and not d[\"badPair\"] and d[\"iso\"] else 1)"' \
  "topology contract: 2 lanes, cross-lane overlap OK, same-sequence and same-pair overlap REFUSED, isolation paths unique"
OUT=$(mod "console.log(JSON.stringify(buildSchedule({ sequences:['S1'], positions:[2], armOrder:{} })))")
ok 'printf "%s" "$OUT" | grep -q "no precommitted arm order"' "missing precommitted arm order refuses scheduling"

echo "== 5. blinding: three views, mechanically un-joinable =="
OUT=$(mod "
const cells=[{seq:'S1',pos:2,arm:'lean_rules',objective:'fix TS2305',acceptance:'zero errors',diff:'+x',economics:{tokens:1},outcome:'accepted'},
             {seq:'S1',pos:2,arm:'lean_skills',objective:'fix TS2305',acceptance:'zero errors',diff:'+y',economics:{tokens:2},outcome:'accepted'}];
const v=buildViews(cells,'qualification-salt-never-shipped');
console.log(JSON.stringify({ leak: viewLeakCheck(v), mapN: v.sealedMapping.length,
  adjHasArm: JSON.stringify(v.adjudicator).includes('lean_'), anaHasArm: JSON.stringify(v.analyst).includes('lean_') }));")
ok 'printf "%s" "$OUT" | python3 -c "import json,sys;d=json.loads(sys.stdin.read());exit(0 if d[\"leak\"][\"ok\"] and not d[\"adjHasArm\"] and not d[\"anaHasArm\"] and d[\"mapN\"]==2 else 1)"' \
  "adjudicator and analyst views carry no arm identity or joinable keys; mapping sealed separately"

echo "== 6. fake worker + metering path (no spend) =="
"$H/fake-worker.sh" "$WORK/stream.jsonl"
bash "$SRC/build-os/tools/meter-run.sh" "$WORK/stream.jsonl" "$R" 30 >/dev/null
ok 'grep -q "provider-result-event" "$R/build-os/memory/spend-ledger.jsonl"' "fake stream meters with provider-result-event provenance (telemetry path qualified)"
"$H/fake-worker.sh" "$WORK/abort.jsonl" --no-result
bash "$SRC/build-os/tools/meter-run.sh" "$WORK/abort.jsonl" "$R" 30 >/dev/null
ok 'grep -q "NOT-METERED" "$R/build-os/memory/spend-ledger.jsonl"' "aborted stream (no result event) => NOT-METERED, never inferred"
rm -f "$R/build-os/memory/spend-ledger.jsonl"

echo "== 7. freeze: manifest creates and detects post-freeze change (on a disposable copy) =="
# DEFECT FIX: this section previously ran freeze.mjs create IN PLACE, silently
# rewriting the committed FREEZE-MANIFEST.json (source_commit_at_freeze drifted
# to whatever HEAD ran the suite) and touch-restoring frozen fixture.mjs bytes.
# It now exercises create/verify/tamper on a disposable copy only.
FT="$WORK/freeze-copy"; mkdir -p "$FT/build-os/experiments" "$FT/build-os/delivery" "$FT/build-os/tools"
cp -r "$H/.." "$FT/build-os/experiments/EXP-0013-delivery-confirmatory"
cp "$SRC/build-os/delivery/ucdl.mjs" "$FT/build-os/delivery/"
cp "$SRC/build-os/tools/planner.mjs" "$FT/build-os/tools/"
git -C "$FT" init -q && git -C "$FT" -c user.email=t@t -c user.name=t add -A && git -C "$FT" -c user.email=t@t -c user.name=t commit -qm freeze-copy
FH="$FT/build-os/experiments/EXP-0013-delivery-confirmatory/harness"
node "$FH/freeze.mjs" create >/dev/null
ok '[ -f "$FH/../FREEZE-MANIFEST.json" ]' "freeze manifest created with source commit + artifact hashes"
ok 'node "$FH/freeze.mjs" verify >/dev/null' "freeze verifies intact"
printf '\n' >> "$FH/fixture.mjs"
ok '! node "$FH/freeze.mjs" verify >/dev/null 2>&1' "any post-freeze harness change: DETECTED (typed)"
ok '[ -z "$(cd "$SRC" && git diff --name-only -- build-os/experiments/EXP-0013-delivery-confirmatory/FREEZE-MANIFEST.json build-os/experiments/EXP-0013-delivery-confirmatory/harness)" ]' \
  "REAL tree: v1 manifest and tracked frozen harness files unmodified by this suite"

echo "== 8. production untouched; sealed evidence byte-identical =="
ok '! grep -rq "EXP-0013" "$SRC/bin/gravito" "$SRC/.claude/hooks"' "no production path references the fixture"
ok 'grep -q "Work ONLY in this repository" "$SRC/bin/gravito"' "ordinary worker prompt bytes unchanged"
ok '[ -z "$(cd "$SRC" && git status --porcelain -- build-os/experiments/EXP-0011-reusable-skills build-os/experiments/EXP-0010* 2>/dev/null)" ]' \
  "sealed EXP-0010/0011 trees untouched"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
