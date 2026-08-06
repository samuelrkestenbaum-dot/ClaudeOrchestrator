#!/usr/bin/env bash
# Build OS — provider-adapter contract v0 (LANE-4-adapter-contract): the common
# adapter contract for ALL ten task-lifecycle points, with a conformance driver.
#
# WHY THIS EXISTS. build-os/memory/provider_adapter_contract.md (PACKET-0054)
# stated the interface as prose plus an honest capability table. This packet
# FORMALIZES it: ten named lifecycle operations (task_start, context_delivery,
# authority_grant, mutation_event, telemetry_report, receipt_bind, completion,
# interruption, degradation, capability_declaration), a machine-checkable
# capability-declaration schema, two REAL declarations (claude-hooks from the
# executed hook surface; codex as the honest four-state stub), a fully
# conforming LOCAL mock adapter, and a two-level conformance driver (schema +
# behavioral).
#
# HONESTY RULES UNDER TEST, verbatim from the operator:
#   * tier vocabulary EXACT | ESTIMATE | CLOSE-TIME | UNAVAILABLE — an adapter
#     may NEVER report a tier above what it measures;
#   * Codex four-state: binary present TRUE / auth ABSENT / host unreachable
#     (000) / no successful call — NOTHING claimed supported until a real call
#     succeeds, and absent access does not block the architecture;
#   * a declared-unsupported operation is REFUSED, never faked;
#   * an interrupted task leaves RESUMABLE state, not silence.
#
# Deterministic, local, model-free. Fixtures in mktemp; the live receipt store
# is never written (the real-hook spot-check runs in a scratch
# ROUTING_GATE_ROOT). The mock adapter is proof of CONTRACT behavior, not of
# any provider: mock != real provider, stated here and in the contract.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADIR="$SRC/build-os/adapters"
CONTRACT="$ADIR/ADAPTER_CONTRACT.md"
SCHEMA="$ADIR/capability-schema.json"
CH_CAP="$ADIR/claude-hooks.capability.json"
CX_CAP="$ADIR/codex.capability.json"
MK_CAP="$ADIR/mock-adapter.capability.json"
MOCK="$ADIR/mock-adapter.sh"
CONF="$ADIR/conformance.sh"
MEM="$SRC/build-os/memory/provider_adapter_contract.md"
GATE="$SRC/.claude/hooks/routing-gate.sh"
ROUTE="$SRC/build-os/tools/route-task.sh"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

OPS="task_start context_delivery authority_grant mutation_event telemetry_report receipt_bind completion interruption degradation capability_declaration"

# node JSON field getter: jget <file> <dot.path> -> value or rc 1
jget(){
  node -e '
    const fs=require("fs");
    try{
      const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
      const v=process.argv[2].split(".").reduce((a,k)=>a==null?a:a[k],o);
      if(v===undefined||v===null)process.exit(1);
      process.stdout.write(typeof v==="object"?JSON.stringify(v):String(v));
    }catch(e){process.exit(1)}' "$1" "$2"
}
# patch a capability json with a node mutation expression o=>{...}; write to $3
jpatch(){
  node -e '
    const fs=require("fs");
    const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
    (eval("("+process.argv[3]+")"))(o);
    fs.writeFileSync(process.argv[2],JSON.stringify(o,null,2));
  ' "$1" "$2" "$3"
}

echo "== 1. Surfaces: the contract document, the schema, the driver =="
[ -f "$CONTRACT" ] && ok "ADAPTER_CONTRACT.md exists" || no "ADAPTER_CONTRACT.md missing"
if [ -f "$CONTRACT" ]; then
  for op in $OPS; do
    grep -q "### \`$op\`" "$CONTRACT" && ok "contract names lifecycle operation: $op" \
                                      || no "contract missing lifecycle operation: $op"
  done
  grep -q "MUST NOT" "$CONTRACT" && grep -q "MAY" "$CONTRACT" && grep -qE '\bMUST\b' "$CONTRACT" \
    && ok "contract speaks MUST / MAY / MUST NOT" || no "contract lacks MUST/MAY/MUST NOT vocabulary"
  grep -q "never report a tier above what it measures" "$CONTRACT" \
    && ok "tier honesty rule is stated verbatim (never a tier above what it measures)" \
    || no "tier honesty rule not stated"
  for tier in EXACT ESTIMATE CLOSE-TIME UNAVAILABLE; do
    grep -q "$tier" "$CONTRACT" && ok "contract carries tier: $tier" || no "contract missing tier: $tier"
  done
  grep -qi "mock adapter is proof of contract behavior, not of any provider" "$CONTRACT" \
    && ok "contract states mock != real provider" || no "contract does not bound the mock's meaning"
fi
if [ -f "$SCHEMA" ]; then
  ok "capability-schema.json exists"
  node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$SCHEMA" 2>/dev/null \
    && ok "capability-schema.json is valid JSON" || no "capability-schema.json is not valid JSON"
  SP="$(jget "$SCHEMA" lifecycle_points)"
  N=0; for op in $OPS; do case "$SP" in *"\"$op\""*) N=$((N+1));; esac; done
  [ "$N" -eq 10 ] && ok "schema lists all ten lifecycle points" || no "schema lists $N of 10 lifecycle points"
  for word in EXACT ESTIMATE CLOSE-TIME UNAVAILABLE; do
    grep -q "\"$word\"" "$SCHEMA" && ok "schema tier vocabulary: $word" || no "schema missing tier: $word"
  done
  for ep in pre post none; do
    grep -q "\"$ep\"" "$SCHEMA" && ok "schema enforcement vocabulary: $ep" || no "schema missing enforcement point: $ep"
  done
  NC="$(node -e 'const s=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));console.log((s.illegal_combinations||[]).length)' "$SCHEMA" 2>/dev/null || echo 0)"
  [ "${NC:-0}" -ge 3 ] && ok "schema names >=3 illegal combinations ($NC)" || no "schema names only ${NC:-0} illegal combinations (need >=3)"
else
  no "capability-schema.json missing"
fi
[ -x "$CONF" ] && ok "conformance.sh exists and is executable" || no "conformance.sh missing or not executable"
[ -x "$MOCK" ] && ok "mock-adapter.sh exists and is executable" || no "mock-adapter.sh missing or not executable"

echo
echo "== 2. Schema conformance: the three real declarations validate =="
for cap in "$CH_CAP" "$CX_CAP" "$MK_CAP"; do
  name="$(basename "$cap")"
  if [ -f "$cap" ] && [ -x "$CONF" ]; then
    if bash "$CONF" "$cap" >"$WORK/schema-$name.out" 2>&1; then
      ok "schema conformance PASSES: $name"
    else
      no "schema conformance FAILS: $name ($(tail -n2 "$WORK/schema-$name.out" | tr '\n' ' '))"
    fi
  else
    no "cannot validate $name (file or driver missing)"
  fi
done

echo
echo "== 3. Illegal combinations: fabricated overclaims are REFUSED by name =="
if [ -f "$CX_CAP" ] && [ -f "$CH_CAP" ] && [ -x "$CONF" ]; then
  # 3a. UNSUPPORTED-TIER-CLAIM: supported=false yet tier EXACT.
  jpatch "$CX_CAP" "$WORK/bad-tier.json" 'o=>{o.lifecycle.telemetry_report.tier="EXACT"}'
  if bash "$CONF" "$WORK/bad-tier.json" >"$WORK/bad-tier.out" 2>&1; then
    no "UNSUPPORTED-TIER-CLAIM was admitted (supported=false with tier EXACT)"
  else
    grep -q "UNSUPPORTED-TIER-CLAIM" "$WORK/bad-tier.out" \
      && ok "UNSUPPORTED-TIER-CLAIM refused BY NAME" || no "refused but not by name (UNSUPPORTED-TIER-CLAIM)"
  fi
  # 3b. EXACT-TELEMETRY-WITHOUT-OBSERVATION: tokens/telemetry EXACT with enforcement none.
  jpatch "$CH_CAP" "$WORK/bad-obs.json" 'o=>{o.lifecycle.telemetry_report.tier="EXACT";o.lifecycle.telemetry_report.enforcement="none"}'
  if bash "$CONF" "$WORK/bad-obs.json" >"$WORK/bad-obs.out" 2>&1; then
    no "EXACT-TELEMETRY-WITHOUT-OBSERVATION was admitted (EXACT with enforcement none)"
  else
    grep -q "EXACT-TELEMETRY-WITHOUT-OBSERVATION" "$WORK/bad-obs.out" \
      && ok "EXACT-TELEMETRY-WITHOUT-OBSERVATION refused BY NAME" || no "refused but not by name (EXACT-TELEMETRY-WITHOUT-OBSERVATION)"
  fi
  # 3c. UNVERIFIED-SUPPORT: an unverified provider claiming a supported point.
  jpatch "$CX_CAP" "$WORK/bad-unver.json" 'o=>{o.lifecycle.task_start.supported=true;o.lifecycle.task_start.tier="EXACT";o.lifecycle.task_start.enforcement="pre"}'
  if bash "$CONF" "$WORK/bad-unver.json" >"$WORK/bad-unver.out" 2>&1; then
    no "UNVERIFIED-SUPPORT was admitted (unverified adapter claims support)"
  else
    grep -q "UNVERIFIED-SUPPORT" "$WORK/bad-unver.out" \
      && ok "UNVERIFIED-SUPPORT refused BY NAME (no support claim before a successful call)" \
      || no "refused but not by name (UNVERIFIED-SUPPORT)"
  fi
  # 3d. PHANTOM-ENFORCEMENT: supported=false yet an enforcement point claimed.
  jpatch "$CX_CAP" "$WORK/bad-phantom.json" 'o=>{o.lifecycle.mutation_event.enforcement="pre"}'
  if bash "$CONF" "$WORK/bad-phantom.json" >"$WORK/bad-phantom.out" 2>&1; then
    no "PHANTOM-ENFORCEMENT was admitted (unsupported op claims enforcement pre)"
  else
    grep -q "PHANTOM-ENFORCEMENT" "$WORK/bad-phantom.out" \
      && ok "PHANTOM-ENFORCEMENT refused BY NAME" || no "refused but not by name (PHANTOM-ENFORCEMENT)"
  fi
  # 3e. structural: a missing lifecycle point is refused, not defaulted.
  jpatch "$CX_CAP" "$WORK/bad-missing.json" 'o=>{delete o.lifecycle.interruption}'
  bash "$CONF" "$WORK/bad-missing.json" >"$WORK/bad-missing.out" 2>&1 \
    && no "a declaration missing a lifecycle point was admitted" \
    || ok "a declaration missing a lifecycle point is refused (nothing defaulted)"
else
  no "illegal-combination checks skipped (declarations or driver missing)"
fi

echo
echo "== 4. Codex: the honest four-state stub claims NOTHING =="
if [ -f "$CX_CAP" ]; then
  [ "$(jget "$CX_CAP" verification.state)" = "unverified" ] \
    && ok "codex verification.state = unverified" || no "codex verification.state is not unverified"
  [ "$(jget "$CX_CAP" verification.access.binary_present)" = "true" ] \
    && ok "four-state 1/4: binary_present TRUE" || no "binary_present not declared true"
  [ "$(jget "$CX_CAP" verification.access.auth_present)" = "false" ] \
    && ok "four-state 2/4: auth_present FALSE (auth ABSENT)" || no "auth_present not declared false"
  [ "$(jget "$CX_CAP" verification.access.host_reachable)" = "false" ] \
    && ok "four-state 3/4: host_reachable FALSE" || no "host_reachable not declared false"
  [ "$(jget "$CX_CAP" verification.access.successful_call)" = "false" ] \
    && ok "four-state 4/4: successful_call FALSE (no provider support claimed)" || no "successful_call not declared false"
  grep -q '000' "$CX_CAP" && ok "the observed unreachability (000) is recorded, not guessed away" \
                          || no "the 000 observation is missing from the codex declaration"
  NSUP="$(node -e 'const o=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));console.log(Object.values(o.lifecycle).filter(p=>p.supported===true).length)' "$CX_CAP")"
  [ "$NSUP" = "0" ] && ok "codex claims 0 of 10 lifecycle points supported" \
                    || no "codex claims $NSUP supported points before any successful call"
else
  no "codex.capability.json missing"
fi

echo
echo "== 5. Claude-hooks declaration vs the ACTUAL hook surface (spot-check) =="
if [ -f "$CH_CAP" ]; then
  [ "$(jget "$CH_CAP" verification.state)" = "executed" ] \
    && ok "claude-hooks verification.state = executed (evidence-backed)" || no "claude-hooks not marked executed"
  [ "$(jget "$CH_CAP" lifecycle.mutation_event.supported)" = "true" ] \
    && [ "$(jget "$CH_CAP" lifecycle.mutation_event.enforcement)" = "pre" ] \
    && ok "declares mutation_event supported with enforcement=pre" || no "mutation_event claim wrong"
  [ "$(jget "$CH_CAP" lifecycle.mutation_event.tier)" = "EXACT" ] \
    && ok "declares mutation_event counts EXACT" || no "mutation_event tier is not EXACT"
  [ "$(jget "$CH_CAP" lifecycle.context_delivery.supported)" = "false" ] \
    && ok "does NOT claim context_delivery (the host delivers context; the hook cannot see it)" \
    || no "claude-hooks overclaims context_delivery"
  jget "$CH_CAP" lifecycle.telemetry_report.notes | grep -qi "UNAVAILABLE" \
    && jget "$CH_CAP" lifecycle.telemetry_report.notes | grep -qi "token" \
    && ok "telemetry notes admit tokens UNAVAILABLE live interactive" \
    || no "telemetry notes do not admit the live-token bound"
  [ "$(jget "$CH_CAP" lifecycle.receipt_bind.supported)" = "true" ] \
    && ok "declares receipt_bind supported (receipts native)" || no "receipt_bind claim wrong"
  # Drive the REAL hook in a scratch root: one mutation BLOCK, one admitted flow.
  R="$WORK/hookroot"; mkdir -p "$R/build-os/packets/routing"
  MJ='{"session_id":"s","transcript_path":"/tmp/t","cwd":".","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/x/f","content":"c"}}'
  printf '%s' "$MJ" | ROUTING_GATE_ROOT="$R" bash "$GATE" mutgate >"$WORK/mg1.out" 2>"$WORK/mg1.err"; RC1=$?
  [ "$RC1" -eq 2 ] && ok "REAL hook: mutation with no receipt is BLOCKED (exit 2) — enforcement=pre is true, not declared-only" \
                   || no "REAL hook did not block an unrouted mutation (rc=$RC1)"
  grep -qi "MUTATION BLOCKED" "$WORK/mg1.err" && ok "REAL hook refusal is model-visible on stderr" \
                                              || no "no model-visible refusal on stderr"
  DESC='{"expected_files_changed":1,"requires_tests":false,"expected_session_count":1,"prior_context_required":false,"handoff_required":false,"consequence_level":"low","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}'
  if bash "$ROUTE" --task-id adapter-spotcheck --description "adapter contract spot-check fixture" \
       --descriptor "$DESC" --out "$R/build-os/packets/routing" >/dev/null 2>&1; then
    REC="$(find "$R/build-os/packets/routing" -maxdepth 1 -name 'routing-adapter-spotcheck-*.md' | sed -n 1p)"
    printf '%s' "$MJ" | ROUTING_GATE_ROOT="$R" bash "$GATE" mutgate >"$WORK/mg2.out" 2>"$WORK/mg2.err"; RC2=$?
    [ "$RC2" -eq 0 ] && ok "REAL hook: the same mutation is ADMITTED under an open receipt (exit 0)" \
                     || no "REAL hook refused a routed mutation (rc=$RC2)"
    SF="$R/build-os/packets/routing/live_state/$(basename "$REC" .md).tsv"
    [ -f "$SF" ] && grep -q 'mutation_event' "$SF" \
      && ok "REAL hook: the admitted mutation landed as a mutation_event row (receipt_bind + EXACT counting real)" \
      || no "no mutation_event row in the live state"
  else
    no "route-task.sh could not issue the spot-check receipt"
  fi
else
  no "claude-hooks.capability.json missing"
fi

echo
echo "== 6. Mock adapter: FULL behavioral conformance =="
if [ -x "$CONF" ] && [ -x "$MOCK" ] && [ -f "$MK_CAP" ]; then
  if bash "$CONF" "$MK_CAP" --exercise "bash $MOCK" >"$WORK/behav.out" 2>&1; then
    ok "mock adapter passes full conformance (schema + behavioral)"
  else
    no "mock adapter FAILS conformance ($(grep -c 'BEHAV-FAIL' "$WORK/behav.out" 2>/dev/null || echo '?') behavioral failures)"
  fi
  NB="$(grep -c 'BEHAV-OK' "$WORK/behav.out" 2>/dev/null || echo 0)"
  [ "${NB:-0}" -ge 12 ] && ok "behavioral driver exercised >=12 distinct checks ($NB)" \
                        || no "behavioral driver ran only ${NB:-0} checks (need >=12 for ten operations)"
  grep -q 'BEHAV-OK.*pre-authority mutation refused' "$WORK/behav.out" \
    && ok "driver proved pre-enforcement: mutation BEFORE authority_grant refused" \
    || no "pre-authority mutation refusal not proven"
else
  no "behavioral conformance skipped (driver, mock, or declaration missing)"
fi

echo
echo "== 7. Declared-unsupported is REFUSED, not faked =="
if [ -x "$CONF" ] && [ -x "$MOCK" ] && [ -f "$MK_CAP" ]; then
  jpatch "$MK_CAP" "$WORK/mock-nodelivery.json" \
    'o=>{o.lifecycle.context_delivery={supported:false,tier:"UNAVAILABLE",enforcement:"none",notes:"fixture: declared unsupported to prove refusal"}}'
  if bash "$CONF" "$WORK/mock-nodelivery.json" --exercise "MOCK_DECLARE_UNSUPPORTED=context_delivery bash $MOCK" >"$WORK/refuse.out" 2>&1; then
    grep -q 'BEHAV-OK.*unsupported operation refused: context_delivery' "$WORK/refuse.out" \
      && ok "declared-unsupported context_delivery is refused (exit 2), not faked" \
      || no "the refusal check did not run against the unsupported op"
  else
    no "conformance failed on the declared-unsupported configuration ($(grep 'BEHAV-FAIL' "$WORK/refuse.out" | head -n1))"
  fi
else
  no "refusal check skipped"
fi

echo
echo "== 8. Interruption leaves RESUMABLE state =="
if [ -x "$MOCK" ]; then
  SD="$WORK/mockstate"; mkdir -p "$SD"
  printf '{"task_id":"t-int","description":"interruption fixture","mode":"direct"}' \
    | ADAPTER_STATE_DIR="$SD" bash "$MOCK" task_start >"$WORK/i1.out" 2>&1
  printf '{"task_id":"t-int","authority":{"mutation":true}}' \
    | ADAPTER_STATE_DIR="$SD" bash "$MOCK" authority_grant >/dev/null 2>&1
  printf '{"task_id":"t-int","tool":"Write","target":"/x"}' \
    | ADAPTER_STATE_DIR="$SD" bash "$MOCK" mutation_event >/dev/null 2>&1
  printf '{"task_id":"t-int","reason":"operator interrupt fixture"}' \
    | ADAPTER_STATE_DIR="$SD" bash "$MOCK" interruption >"$WORK/i2.out" 2>&1; RCI=$?
  [ "$RCI" -eq 0 ] && grep -q '"resumable": *true' "$WORK/i2.out" \
    && ok "interruption reports resumable:true" || no "interruption did not report resumable state (rc=$RCI)"
  RSF="$SD/tasks/t-int/resume.json"
  [ -f "$RSF" ] && ok "a resume state file exists on disk after interruption" || no "no resume state file on disk"
  [ -f "$RSF" ] && grep -q '"mutation_events": *1' "$RSF" \
    && ok "the resume file preserves the pre-interrupt EXACT counts" || no "resume file lost the counts"
  printf '{"task_id":"t-int"}' | ADAPTER_STATE_DIR="$SD" bash "$MOCK" completion >/dev/null 2>&1; RCC=$?
  [ "$RCC" -eq 2 ] && ok "completion of an interrupted task is REFUSED until resumed" \
                   || no "an interrupted task completed without resuming (rc=$RCC)"
  printf '{"task_id":"t-int","resume":true}' | ADAPTER_STATE_DIR="$SD" bash "$MOCK" task_start >"$WORK/i3.out" 2>&1; RCR=$?
  [ "$RCR" -eq 0 ] && ok "task_start with resume:true resumes the interrupted task" || no "resume failed (rc=$RCR)"
  printf '{"task_id":"t-int"}' | ADAPTER_STATE_DIR="$SD" bash "$MOCK" completion >"$WORK/i4.out" 2>&1; RCC2=$?
  [ "$RCC2" -eq 0 ] && grep -q '"mutation_events": *1' "$WORK/i4.out" \
    && ok "post-resume completion succeeds and carries the preserved counts" \
    || no "post-resume completion wrong (rc=$RCC2)"
else
  no "interruption checks skipped (mock missing)"
fi

echo
echo "== 9. The memory contract points at the v0 formalization — nothing renumbered, nothing removed =="
grep -q 'build-os/adapters/ADAPTER_CONTRACT.md' "$MEM" \
  && ok "provider_adapter_contract.md points at the v0 contract" || no "memory does not name the v0 contract"
grep -q 'build-os/adapters/conformance.sh' "$MEM" \
  && ok "memory points at the conformance driver" || no "memory does not name the driver"
grep -q 'tests/adapter_contract_tests.sh' "$MEM" \
  && ok "memory names this suite as the executed evidence" || no "memory does not name this suite"
# The named bounds that MUST survive intact (routing_task_entry_tests.sh also guards these).
for keep in "EXACT" "ESTIMATE" "CLOSE-TIME" "UNAVAILABLE" "interface-unverified" "Codex" \
            "\.claude/hooks/routing-gate\.sh" "sh -c"; do
  grep -q "$keep" "$MEM" && ok "memory keeps the named bound: $keep" || no "memory LOST the named bound: $keep"
done
MB="$(wc -c < "$MEM" | tr -d ' ')"
[ "${MB:-99999}" -le 4000 ] && ok "memory stays within the 4000-byte ceiling ($MB B)" \
                            || no "memory is $MB B — over the ceiling routing_task_entry_tests.sh enforces"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
