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
# A gate that neither delegates NOR advertises the no-shell route: the
# capability exists in the classifier but the worker can never learn of it.
sed -e 's|gate-recovery\.mjs|MISSING-RECOVERY-GENERATOR|g' -e 's|build-os/packets/routing/routing-request.json|(undocumented)|g' .claude/hooks/routing-gate.sh > "$TMP/undiscoverable.sh"
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
# Asserting "nothing is violated" encoded a STATE, not a property, and broke the
# moment a real violation was registered. The property is that a KNOWN violation
# is reported by name.
t "a known-violated load-bearing assumption is reported" "$(node -e 'import("./build-os/assumptions/registry.mjs").then(m=>{const c=m.coverage({gatePath:".claude/hooks/routing-gate.sh"});console.log(String(c.violated_load_bearing.some(v=>v.id==="claude-can-write-live-control-plane")));})')" "true"

echo "== the audit exits non-zero on a violation =="
node build-os/assumptions/self-audit.mjs "$TMP/undiscoverable.sh" >/dev/null 2>&1
t "self-audit exit code on a violated claim" "$?" "1"
# Same correction: the audit must exit non-zero WHILE a load-bearing assumption
# is violated. A green exit here would mean the audit is not reading its own
# registry.
node build-os/assumptions/self-audit.mjs >/dev/null 2>&1
t "self-audit exits non-zero while a real violation stands" "$?" "1"


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


echo "== live gate consults the selector =="
G=$(mktemp -d); trap 'rm -rf "$TMP" "$TMP2" "$G"' EXIT
bash build-os/experiments/EXP-0005-system-efficiency/harness/restore-seed.sh "$G/c" >/dev/null 2>&1
cp .claude/hooks/routing-gate.sh "$G/c/.claude/hooks/routing-gate.sh"
mkdir -p "$G/c/build-os/assumptions" && cp build-os/assumptions/*.mjs "$G/c/build-os/assumptions/"
rm -f "$G/c"/build-os/packets/routing/*.md
gate(){ printf '%s' '{"tool_name":"Edit","tool_input":{"file_path":"x.ts"}}' | (cd "$G/c" && CLAUDE_PROJECT_DIR="$G/c" GRAVITO_HOST_PROFILE="${1:-}" bash .claude/hooks/routing-gate.sh mutgate) 2>&1; }

out="$(gate)"
case "$out" in *"least-privileged viable route is 'routing_request_channel'"*) ok "live refusal is SELECTOR-GENERATED, no-shell route first";; *) no "live refusal is selector-generated";; esac
case "$out" in *"NOT AVAILABLE on this host: structured_routing_action"*) ok "live refusal marks the Bash route unavailable on this host";; *) no "live refusal marks Bash unavailable";; esac
# The pre-#45 failure: worker told to run Bash when Bash is approval-gated.
first_bash=0
printf '%s\n' "$out" | grep -n "route-task.sh" >/dev/null 2>&1 && first_bash=1
t "the historical failure is avoided: Bash is not the advertised first move" "$first_bash" "0"

# A permissive host must be able to change the ordering — proof it is not static text.
out2="$(gate claude_code_interactive)"
case "$out2" in *"least-privileged viable route"*) ok "a declared host profile is honoured at runtime";; *) no "declared host profile honoured";; esac
# Host denying the mutation entirely: refuse, and do not blame Gravito.
out3="$(gate claude_code_headless_dontAsk)"
case "$out3" in *"host restriction, not a Gravito defect"*) ok "host-denied mutation refuses WITHOUT blaming Gravito";; *) no "host-denied mutation not blamed on Gravito";; esac
# Enforcement must not be weakened: the call is still refused.
case "$out" in *"MUTATION BLOCKED"*) ok "mutation enforcement is NOT weakened by the wiring";; *) no "mutation still blocked";; esac
# Selection is recorded.
grep -q "RECOVERY-SELECTED" "$G/c/build-os/packets/routing/live_gate_log.tsv" 2>/dev/null && ok "the selection is recorded with provenance" || no "selection recorded"

echo "== MUTATION TESTING: every negative fixture must catch a deliberately broken implementation =="
# A fixture that cannot fail proves nothing. Each case below breaks the real
# implementation and asserts the corresponding check TURNS RED. If a mutant
# survives, that fixture is vacuous and the suite is lying about its coverage.
M=$(mktemp -d); trap 'rm -rf "$TMP" "$TMP2" "$G" "$M"' EXIT
mutant(){ # <sed-expr> <label> — break the SELECTOR, expect the named check to flip
  mkdir -p "$M/a"; cp build-os/assumptions/*.mjs "$M/a/" 2>/dev/null
  sed -i "$1" "$M/a/$2"
}

# M1 — break least-privilege ordering: prefer HIGHEST privilege.
mkdir -p "$M/m1"; cp build-os/assumptions/*.mjs "$M/m1/"
sed -i 's|viable.sort((a, b) => a.privilege - b.privilege|viable.sort((a, b) => b.privilege - a.privilege|' "$M/m1/authority-selector.mjs"
got="$(node -e '
import(process.argv[1]+"/authority-selector.mjs").then(async(s)=>{
 const H=await import(process.argv[1]+"/host-profiles.mjs");
 const r=s.selectAuthorityPath({gatePath:process.argv[2],host:H.HOSTS.find(x=>x.id==="claude_code_interactive"),mutation_class:"Edit"});
 console.log(r.selected);});' "$M/m1" .claude/hooks/routing-gate.sh 2>/dev/null)"
[ "$got" != "routing_request_channel" ] && ok "M1 killed: reversing least-privilege changes the selection (got '$got')" || no "M1 SURVIVED — the least-privilege assertion is vacuous"

# M2 — break the host-denies check: treat a denied class as usable.
mkdir -p "$M/m2"; cp build-os/assumptions/*.mjs "$M/m2/"
sed -i 's|if (v === "allowed") return { ok: true, why: "allowed" };|if (v) return { ok: true, why: "allowed" };|' "$M/m2/authority-selector.mjs"
got="$(node -e '
import(process.argv[1]+"/authority-selector.mjs").then(async(s)=>{
 const H=await import(process.argv[1]+"/host-profiles.mjs");
 const r=s.selectAuthorityPath({gatePath:process.argv[2],host:H.HOSTS.find(x=>x.id==="claude_code_headless_dontAsk"),mutation_class:"Edit"});
 console.log(r.decision);});' "$M/m2" .claude/hooks/routing-gate.sh 2>/dev/null)"
[ "$got" != "refuse_host_denies_mutation" ] && ok "M2 killed: ignoring host denial changes the decision (got '$got')" || no "M2 SURVIVED — the host-denial assertion is vacuous"

# M3 — break mismatch detection: never report a Gravito defect.
mkdir -p "$M/m3"; cp build-os/assumptions/*.mjs "$M/m3/"
sed -i 's|is_gravito_defect: candidates.length > 0,|is_gravito_defect: false,|' "$M/m3/authority-selector.mjs"
got="$(node -e '
import(process.argv[1]+"/authority-selector.mjs").then(async(s)=>{
 const H=await import(process.argv[1]+"/host-profiles.mjs");
 const r=s.selectAuthorityPath({gatePath:process.argv[2],host:H.HOSTS.find(x=>x.id==="claude_code_headless_acceptEdits"),mutation_class:"Edit"});
 console.log(String(r.is_gravito_defect));});' "$M/m3" "$TMP2/prefix.sh" 2>/dev/null)"
[ "$got" = "false" ] && ok "M3 killed: suppressing defect attribution is detectable (got '$got')" || no "M3 SURVIVED"

# M4 — break the asymmetry null guard: reintroduce the null-as-zero coercion.
mkdir -p "$M/m4"; cp build-os/assumptions/*.mjs "$M/m4/"
sed -i 's|const rate = (n, d) => (typeof n === "number" && Number.isFinite(n) && d > 0 ? n / d : null);|const rate = (n, d) => (d > 0 ? n / d : null);|' "$M/m4/asymmetry.mjs"
got="$(node -e '
import(process.argv[1]+"/asymmetry.mjs").then(m=>{
 console.log(String(m.detectAsymmetry({groups:[{id:"a",units:10,accepted:9,external_denials:null},{id:"b",units:10,accepted:0,external_denials:null}]}).findings_count>0));});' "$M/m4" 2>/dev/null)"
[ "$got" = "true" ] && ok "M4 killed: the unmeasured-friction fixture catches null-as-zero" || no "M4 SURVIVED — the null guard is untested"

# M5 — break state contradiction detection: disable the load-bearing rule.
mkdir -p "$M/m5"; cp build-os/assumptions/*.mjs "$M/m5/"
sed -i 's|when: (s) => s.load_bearing \&\& !s.durable \&\& !s.reconstructable \&\& !s.externally_supplied,|when: () => false,|' "$M/m5/state-classification.mjs"
got="$(node -e '
import(process.argv[1]+"/state-classification.mjs").then(m=>{
 console.log(String(m.auditState([{id:"x",provenance:"declared",load_bearing:true,durable:false,reconstructable:false,ephemeral:true,required_before_first_action:true}]).findings_count));});' "$M/m5" 2>/dev/null)"
[ "$got" != "2" ] && ok "M5 killed: disabling the load-bearing rule drops a finding (got '$got')" || no "M5 SURVIVED — the pre-#45 fixture is vacuous"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
