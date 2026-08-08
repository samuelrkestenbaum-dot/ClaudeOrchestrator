#!/usr/bin/env bash
# The self-audit must DETECT, not merely report. Every case here is a
# differential: a known-bad input that must be caught, or a known-good one that
# must stay quiet.
set -uo pipefail
cd "$(dirname "$0")/.."
P=0; F=0
ok(){ P=$((P+1)); echo "  ok   $1"; }
no(){ F=$((F+1)); echo "  FAIL $1"; }
t(){ [ "$2" = "$3" ] && ok "$1" || no "$1 (got '$2' want '$3')"; }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

echo "== derived authority-path extraction =="
# The pre-fix gate is the real historical artifact, not a mock.
git show 0ab05d0~1:.claude/hooks/routing-gate.sh > "$TMP/prefix.sh" 2>/dev/null

v(){ node -e '
import("./build-os/assumptions/derive-authority-paths.mjs").then(async(m)=>{
 const {HOSTS}=await import("./build-os/assumptions/host-profiles.mjs");
 const h=HOSTS.find(x=>x.id===process.argv[2]);
 console.log(m.checkViability(m.deriveAuthorityPaths(m.loadGate(process.argv[1])),h,process.argv[3]||"Edit").verdict);
});' "$1" "$2" "${3:-Edit}"; }

t "pre-fix gate under headless acceptEdits is caught as a MISMATCH" \
  "$(v "$TMP/prefix.sh" claude_code_headless_acceptEdits)" "AUTHORITY_PATH_MISMATCH"
t "current gate under the same host is viable" \
  "$(v .claude/hooks/routing-gate.sh claude_code_headless_acceptEdits)" "viable"
# Not-permitted work is correct refusal, never a Gravito defect.
t "host forbidding the work itself is NOT reported as a mismatch" \
  "$(v .claude/hooks/routing-gate.sh claude_code_headless_dontAsk)" "work_itself_not_permitted"
# A gate with NO ungated path at all must not read as viable.
printf '#!/usr/bin/env bash\necho nothing\n' > "$TMP/empty.sh"
t "a gate with no authority path is not called viable" \
  "$(v "$TMP/empty.sh" claude_code_headless_acceptEdits)" "no_authority_paths_found"

echo "== discoverability =="
# Strip the request path out of the refusal text only: the capability still
# exists, but the worker can no longer find it. That must be VIOLATED.
sed 's|  build-os/packets/routing/routing-request.json\\n|  (removed)\\n|' .claude/hooks/routing-gate.sh > "$TMP/undiscoverable.sh"
d(){ node -e '
import("./build-os/assumptions/registry.mjs").then(m=>{
 const c=m.coverage({gatePath:process.argv[1]});
 console.log(c.rows.find(r=>r.id==="capability-discoverable-at-failure").status);
});' "$1"; }
t "an unadvertised authority path is VIOLATED" "$(d "$TMP/undiscoverable.sh")" "violated"
t "the current gate advertises every path" "$(d .claude/hooks/routing-gate.sh)" "validated"

echo "== coverage semantics =="
u(){ node -e '
import("./build-os/assumptions/registry.mjs").then(m=>{
 const c=m.coverage({gatePath:".claude/hooks/routing-gate.sh"});
 console.log(process.argv[1]==="untested"?c.untested_load_bearing.length:c.violated_load_bearing.length);
});' "$1"; }
t "untested load-bearing claims are surfaced as risk" "$(u untested)" "1"
t "no load-bearing assumption is currently violated" "$(u violated)" "0"

echo "== the audit exits non-zero on a violation =="
node build-os/assumptions/self-audit.mjs "$TMP/undiscoverable.sh" >/dev/null 2>&1
t "self-audit exit code on a violated claim" "$?" "1"
node build-os/assumptions/self-audit.mjs >/dev/null 2>&1
t "self-audit exit code when clean" "$?" "0"


# ---- #48 additions -------------------------------------------------------
echo "== runtime authority selector =="
sel(){ node -e '
Promise.all([import("./build-os/assumptions/authority-selector.mjs"),import("./build-os/assumptions/host-profiles.mjs")]).then(([s,H])=>{
 const h=H.HOSTS.find(x=>x.id===process.argv[2]);
 const r=s.selectAuthorityPath({gatePath:process.argv[1],host:h,mutation_class:process.argv[3]});
 console.log(process.argv[4]==="sel"?(r.selected||"none"):(process.argv[4]==="def"?String(r.is_gravito_defect):r.decision));
});' "$1" "$2" "${3:-Edit}" "${4:-dec}"; }
TMP2=$(mktemp -d); trap 'rm -rf "$TMP" "$TMP2"' EXIT
git show 0ab05d0~1:.claude/hooks/routing-gate.sh > "$TMP2/prefix.sh" 2>/dev/null
printf '#!/usr/bin/env bash\necho nothing\n' > "$TMP2/nopaths.sh"

t "pre-fix gate: selector refuses the Bash route (fail closed)" "$(sel "$TMP2/prefix.sh" claude_code_headless_acceptEdits Edit dec)" "fail_closed"
t "pre-fix gate: correctly attributed as a Gravito defect" "$(sel "$TMP2/prefix.sh" claude_code_headless_acceptEdits Edit def)" "true"
t "current gate: selects the no-shell Write-class route" "$(sel .claude/hooks/routing-gate.sh claude_code_headless_acceptEdits Edit sel)" "routing_request_channel"
t "both viable: least privilege still wins" "$(sel .claude/hooks/routing-gate.sh claude_code_interactive Edit sel)" "routing_request_channel"
t "host denies the requested mutation: refuse, NOT a Gravito defect" "$(sel .claude/hooks/routing-gate.sh claude_code_headless_dontAsk Edit dec)" "refuse_host_denies_mutation"
t "host denies the mutation: blame is not placed on Gravito" "$(sel .claude/hooks/routing-gate.sh claude_code_headless_dontAsk Edit def)" "false"
t "no authority path at all: fail closed" "$(sel "$TMP2/nopaths.sh" claude_code_headless_acceptEdits Edit dec)" "fail_closed"

echo "== unexplained-asymmetry detector =="
asym(){ node -e '
import("./build-os/assumptions/asymmetry.mjs").then(m=>{console.log(String(m.detectAsymmetry(JSON.parse(process.argv[1])).findings_count>0));});' "$1"; }
t "EXP-0005 telemetry fires" "$(asym '{"groups":[{"id":"n","units":12,"accepted":10,"external_denials":102},{"id":"g","units":12,"accepted":0,"external_denials":48}]}')" "true"
t "benign similar outcomes stay quiet" "$(asym '{"groups":[{"id":"a","units":10,"accepted":8,"external_denials":20},{"id":"b","units":10,"accepted":7,"external_denials":22}]}')" "false"
t "divergence EXPLAINED by divergent friction stays quiet" "$(asym '{"groups":[{"id":"a","units":10,"accepted":9,"external_denials":2},{"id":"b","units":10,"accepted":1,"external_denials":95}]}')" "false"
t "UNMEASURED friction stays quiet (null is not zero)" "$(asym '{"groups":[{"id":"a","units":10,"accepted":9,"external_denials":null},{"id":"b","units":10,"accepted":0,"external_denials":null}]}')" "false"
t "a non-EXP-0005 synthetic asymmetry also fires" "$(asym '{"groups":[{"id":"x","units":8,"accepted":7,"external_denials":40},{"id":"y","units":8,"accepted":1,"external_denials":22}]}')" "true"
t "the detector never asserts a cause" "$(node -e 'import("./build-os/assumptions/asymmetry.mjs").then(m=>{const r=m.detectAsymmetry({groups:[{id:"n",units:12,accepted:10,external_denials:102},{id:"g",units:12,accepted:0,external_denials:48}]});console.log(String(r.findings[0].cause));})')" "null"

echo "== state-classification audit =="
st(){ node -e '
import("./build-os/assumptions/state-classification.mjs").then(m=>{console.log(String(m.auditState(JSON.parse(process.argv[1])).findings_count));});' "$1"; }
t "pre-#45 live_state classification is caught" "$(st '[{"id":"x","provenance":"declared","load_bearing":true,"durable":false,"reconstructable":false,"ephemeral":true,"required_before_first_action":true}]')" "2"
t "a well-classified durable item is clean" "$(st '[{"id":"y","provenance":"derived","durable":true,"load_bearing":true}]')" "0"
t "reconstructable without a constructor is caught" "$(st '[{"id":"z","provenance":"declared","reconstructable":true}]')" "1"
t "a persisted must-never-persist item is caught" "$(st '[{"id":"s","provenance":"derived","must_never_persist":true,"tracked":true}]')" "1"
t "current live inventory has no contradictions" "$(node -e 'Promise.all([import("./build-os/assumptions/state-classification.mjs"),import("./build-os/assumptions/state-inventory.mjs")]).then(([a,i])=>console.log(String(a.auditState(i.inventory()).findings_count)))')" "0"

echo "== adversarial matrix honesty =="
t "simulated cells are NOT counted as validated" "$(node -e 'import("./build-os/assumptions/matrix.mjs").then(m=>{const r=m.matrixReport();console.log(String(r.validated.includes("clean+interactive+Edit")));})')" "false"
t "untested cells are visible" "$(node -e 'import("./build-os/assumptions/matrix.mjs").then(m=>console.log(String(m.matrixReport().by_coverage.untested>0)))')" "true"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
