#!/usr/bin/env bash
# Build OS — conformance.sh (LANE-4-adapter-contract): the two-level
# conformance driver for provider adapters.
#
#   conformance.sh <capability.json> [--exercise <adapter-cmd>] [--schema <schema.json>]
#
# LEVEL 1 — SCHEMA CONFORMANCE (always runs). Validates the declaration against
# build-os/adapters/capability-schema.json: structure, the ten lifecycle
# points, the tier and enforcement vocabularies, the verification block — and
# REFUSES the schema's NAMED illegal combinations (UNSUPPORTED-TIER-CLAIM,
# EXACT-TELEMETRY-WITHOUT-OBSERVATION, UNVERIFIED-SUPPORT,
# PHANTOM-ENFORCEMENT). A tier overclaim is refused BY NAME so the refusal
# teaches the rule it enforces.
#
# LEVEL 2 — BEHAVIORAL CONFORMANCE (--exercise). Drives an executable adapter
# through all ten operations against a mktemp state dir and verifies:
# declaration/behavior consistency, pre-enforcement (mutation BEFORE authority
# refused), tier labeling on every telemetry field, degradation propagation,
# interruption leaving RESUMABLE state, completion discipline, and that every
# DECLARED-UNSUPPORTED operation is REFUSED (exit 2) — never faked. Operations
# the declaration marks unsupported get the refusal check and their positive
# checks are SKIPPED (an adapter is measured against its own claims).
#
# Output: SCHEMA-OK/SCHEMA-FAIL and BEHAV-OK/BEHAV-FAIL/BEHAV-SKIP lines, then
# "==== CONFORMANCE RESULT ====". Exit 0 iff zero failures. bash + node only.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA="$SELF_DIR/capability-schema.json"
CAP=""; ADAPTER_CMD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --exercise) ADAPTER_CMD="${2:-}"; shift 2 ;;
    --schema)   SCHEMA="${2:-}"; shift 2 ;;
    -h|--help)  sed -n '2,27p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) [ -z "$CAP" ] && CAP="$1" || { echo "conformance: unexpected argument $1" >&2; exit 1; }; shift ;;
  esac
done
[ -n "$CAP" ] || { echo "usage: conformance.sh <capability.json> [--exercise <adapter-cmd>]" >&2; exit 1; }
[ -f "$CAP" ] || { echo "conformance: no such file: $CAP" >&2; exit 1; }
[ -f "$SCHEMA" ] || { echo "conformance: schema missing: $SCHEMA" >&2; exit 1; }

SOK=0; SFAIL=0; BOK=0; BFAIL=0; BSKIP=0
sok(){ SOK=$((SOK+1)); echo "SCHEMA-OK: $1"; }
sfail(){ SFAIL=$((SFAIL+1)); echo "SCHEMA-FAIL $1"; }
bok(){ BOK=$((BOK+1)); echo "BEHAV-OK: $1"; }
bfail(){ BFAIL=$((BFAIL+1)); echo "BEHAV-FAIL: $1"; }
bskip(){ BSKIP=$((BSKIP+1)); echo "BEHAV-SKIP: $1"; }

# ---------------------------------------------------- level 1: schema --------
# One node pass, driven BY the schema file (vocabularies and point lists come
# from the schema, not from constants baked in here). Emits OK:/FAIL: lines.
SCHEMA_OUT="$(node -e '
  const fs=require("fs");
  const S=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
  let C; try{C=JSON.parse(fs.readFileSync(process.argv[2],"utf8"))}
  catch(e){console.log("FAIL parse: declaration is not valid JSON: "+e.message);process.exit(0)}
  const ok=m=>console.log("OK "+m), fail=m=>console.log("FAIL "+m);

  for(const k of S.required_top) (k in C)?ok("top-level field present: "+k):fail("structure: missing top-level field "+k);
  if(C.schema===S.schema_const) ok("schema tag is "+S.schema_const);
  else fail("structure: schema tag is "+JSON.stringify(C.schema)+", expected "+S.schema_const);

  const V=C.verification||{};
  if(S.verification_states.includes(V.state)) ok("verification.state in vocabulary: "+V.state);
  else fail("structure: verification.state "+JSON.stringify(V.state)+" not in "+S.verification_states.join("|"));
  if(typeof V.evidence==="string" && V.evidence.length>0) ok("verification.evidence present");
  else fail("structure: verification.evidence missing — an unevidenced declaration is a guess");
  if(V.state==="unverified"){
    const A=V.access||{};
    for(const k of S.unverified_access_required)
      (typeof A[k]==="boolean")?ok("four-state access fact declared: "+k+"="+A[k])
                               :fail("structure: unverified adapter missing access."+k+" (four-state honesty is not optional)");
  }

  const L=C.lifecycle||{};
  for(const p of S.lifecycle_points){
    const pt=L[p];
    if(!pt){fail("structure: lifecycle point missing: "+p+" (nothing is defaulted)");continue}
    let shape=true;
    for(const f of S.point_required) if(!(f in pt)){fail("structure: "+p+" missing field "+f);shape=false}
    if(!shape) continue;
    if(typeof pt.supported!=="boolean"){fail("structure: "+p+".supported must be boolean");continue}
    if(!S.tiers.includes(pt.tier)){fail("structure: "+p+".tier "+JSON.stringify(pt.tier)+" not in tier vocabulary");continue}
    if(!S.enforcement_points.includes(pt.enforcement)){fail("structure: "+p+".enforcement "+JSON.stringify(pt.enforcement)+" not in pre|post|none");continue}
    ok("lifecycle point well-formed: "+p);
  }
  const extra=Object.keys(L).filter(k=>!S.lifecycle_points.includes(k));
  extra.length? fail("structure: unknown lifecycle points: "+extra.join(",")) : ok("no unknown lifecycle points");

  // The NAMED illegal combinations — refused by name.
  for(const p of S.lifecycle_points){
    const pt=L[p]; if(!pt) continue;
    if(pt.supported===false && pt.tier!=="UNAVAILABLE")
      fail("UNSUPPORTED-TIER-CLAIM: "+p+" is supported=false yet claims tier "+pt.tier+" — an unsupported operation measures nothing");
    if(pt.supported===false && pt.enforcement!=="none")
      fail("PHANTOM-ENFORCEMENT: "+p+" is supported=false yet claims enforcement "+pt.enforcement+" — that gate does not exist");
    if(V.state!=="executed" && pt.supported===true)
      fail("UNVERIFIED-SUPPORT: "+p+" claims supported=true on an unverified adapter — no support claim before a successful call");
  }
  const t=L.telemetry_report;
  if(t && t.tier==="EXACT" && t.enforcement==="none")
    fail("EXACT-TELEMETRY-WITHOUT-OBSERVATION: telemetry_report claims EXACT with enforcement none — EXACT requires an observation point (pre|post)");
  if(t && !(t.tier==="EXACT" && t.enforcement==="none") ) ok("no EXACT-without-observation overclaim");
' "$SCHEMA" "$CAP")"
while IFS= read -r line; do
  case "$line" in
    OK\ *)   sok "${line#OK }" ;;
    FAIL\ *) sfail "${line#FAIL }" ;;
  esac
done <<EOF
$SCHEMA_OUT
EOF

# ------------------------------------------------- level 2: behavioral -------
if [ -n "$ADAPTER_CMD" ] && [ "$SFAIL" -eq 0 ]; then
  CONF_STATE="$(mktemp -d)"
  trap 'rm -rf "$CONF_STATE"' EXIT
  OUTD="$CONF_STATE/.driver"; mkdir -p "$OUTD"

  run_op(){ # <op> <request-json> — stdout: exit code; response in $OUTD/last
    printf '%s' "$2" | ADAPTER_STATE_DIR="$CONF_STATE" sh -c "$ADAPTER_CMD $1" \
      >"$OUTD/last" 2>"$OUTD/last.err"; echo $?
  }
  rget(){ # <dot.path> from last response; rc 1 if absent
    node -e '
      const fs=require("fs");
      try{
        const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
        const v=process.argv[2].split(".").reduce((a,k)=>a==null?a:a[k],o);
        if(v===undefined||v===null)process.exit(1);
        process.stdout.write(typeof v==="object"?JSON.stringify(v):String(v));
      }catch(e){process.exit(1)}' "$OUTD/last" "$1"
  }
  declared(){ # <point> <field> from the capability file
    node -e '
      const o=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
      const v=o.lifecycle[process.argv[2]][process.argv[3]];
      process.stdout.write(typeof v==="object"?JSON.stringify(v):String(v));
    ' "$CAP" "$1" "$2"
  }
  # A refused op must exit 2 AND say status refused — refusal is honest, not a crash.
  expect_refusal(){ # <op> <request> <label>
    RC="$(run_op "$1" "$2")"
    if [ "$RC" -eq 2 ] && [ "$(rget status)" = "refused" ]; then bok "$3"; else bfail "$3 (rc=$RC status=$(rget status 2>/dev/null || echo '?'))"; fi
  }

  # B1/B2 — capability_declaration: answers, matches the file's claims.
  RC="$(run_op capability_declaration '{}')"
  if [ "$RC" -eq 0 ] && [ "$(rget adapter_id)" = "$(node -e 'process.stdout.write(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).adapter_id)' "$CAP")" ]; then
    bok "capability_declaration answers with the declared adapter_id"
  else
    bfail "capability_declaration wrong (rc=$RC)"
  fi
  MISMATCH="$(node -e '
    const fs=require("fs");
    const file=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
    const live=JSON.parse(fs.readFileSync(process.argv[2],"utf8"));
    const bad=[];
    for(const p of Object.keys(file.lifecycle)){
      const a=file.lifecycle[p]||{}, b=(live.lifecycle||{})[p]||{};
      if(a.supported!==b.supported||a.tier!==b.tier||a.enforcement!==b.enforcement) bad.push(p);
    }
    process.stdout.write(bad.join(","));
  ' "$CAP" "$OUTD/last")"
  [ -z "$MISMATCH" ] && bok "live declaration matches the capability file (supported/tier/enforcement, all ten points)" \
                     || bfail "live declaration diverges from file at: $MISMATCH"

  UNSUP_PTS="$(node -e '
    const o=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
    process.stdout.write(Object.keys(o.lifecycle).filter(p=>o.lifecycle[p].supported===false).join(" "));
  ' "$CAP")"
  is_unsup(){ case " $UNSUP_PTS " in *" $1 "*) return 0;; *) return 1;; esac; }

  if is_unsup task_start; then
    bskip "task_start unsupported — behavioral walk not exercisable beyond refusals"
  else
    T='"conf-1"'
    # B3 task_start
    RC="$(run_op task_start '{"task_id":"conf-1","description":"conformance walk","mode":"direct"}')"
    [ "$RC" -eq 0 ] && [ "$(rget status)" = "ok" ] && bok "task_start ok" || bfail "task_start failed (rc=$RC)"
    # B4 duplicate start refused
    expect_refusal task_start '{"task_id":"conf-1"}' "duplicate task_start refused"
    # B5 pre-enforcement: mutation BEFORE any authority_grant
    if ! is_unsup mutation_event && [ "$(declared mutation_event enforcement)" = "pre" ]; then
      expect_refusal mutation_event '{"task_id":"conf-1","tool":"Write","target":"/x"}' \
        "pre-authority mutation refused (enforcement=pre proven, nothing recorded)"
    else
      bskip "pre-authority mutation check (mutation_event unsupported or not pre-enforced)"
    fi
    # B6 authority_grant + the external-mutation refusal
    if is_unsup authority_grant; then
      expect_refusal authority_grant '{"task_id":"conf-1","authority":{"mutation":true}}' "unsupported operation refused: authority_grant"
    else
      expect_refusal authority_grant '{"task_id":"conf-1","authority":{"mutation":true,"external_mutation":true}}' \
        "external mutation authority refused (operator-only, never adapter-granted)"
      RC="$(run_op authority_grant '{"task_id":"conf-1","authority":{"mutation":true}}')"
      [ "$RC" -eq 0 ] && bok "authority_grant ok (mutation admitted, external excluded)" || bfail "authority_grant failed (rc=$RC)"
    fi
    # B7 mutation admitted, EXACT count
    if is_unsup mutation_event; then
      expect_refusal mutation_event '{"task_id":"conf-1","tool":"Write"}' "unsupported operation refused: mutation_event"
    else
      RC="$(run_op mutation_event '{"task_id":"conf-1","tool":"Write","target":"/x"}')"
      [ "$RC" -eq 0 ] && [ "$(rget mutation_events)" = "1" ] && bok "mutation_event admitted and counted EXACT (1)" || bfail "mutation_event wrong (rc=$RC n=$(rget mutation_events 2>/dev/null))"
      RC="$(run_op mutation_event '{"task_id":"conf-1","tool":"Edit","target":"/y"}')"
      [ "$RC" -eq 0 ] && [ "$(rget mutation_events)" = "2" ] && bok "second mutation_event counted EXACT (2)" || bfail "mutation count did not advance"
    fi
    # B8 context_delivery per declaration
    if is_unsup context_delivery; then
      expect_refusal context_delivery '{"task_id":"conf-1","context":["a"]}' "unsupported operation refused: context_delivery"
    else
      RC="$(run_op context_delivery '{"task_id":"conf-1","context":["memory/a.md","packets/b.md"]}')"
      [ "$RC" -eq 0 ] && [ "$(rget delivered)" = "2" ] && bok "context_delivery ok (delivered=2, exact)" || bfail "context_delivery wrong (rc=$RC)"
    fi
    # B9 receipt_bind
    if is_unsup receipt_bind; then
      expect_refusal receipt_bind '{"task_id":"conf-1","receipt_id":"RCPT-CONF-1"}' "unsupported operation refused: receipt_bind"
    else
      RC="$(run_op receipt_bind '{"task_id":"conf-1","receipt_id":"RCPT-CONF-1"}')"
      [ "$RC" -eq 0 ] && [ "$(rget receipt_id)" = "RCPT-CONF-1" ] && bok "receipt_bind ok (RCPT-CONF-1 echoed)" || bfail "receipt_bind wrong (rc=$RC)"
    fi
    # B10 telemetry_report: every field carries a vocabulary tier; count matches
    if is_unsup telemetry_report; then
      expect_refusal telemetry_report '{"task_id":"conf-1"}' "unsupported operation refused: telemetry_report"
    else
      RC="$(run_op telemetry_report '{"task_id":"conf-1"}')"
      TIERS_BAD="$(node -e '
        const o=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
        const S=JSON.parse(require("fs").readFileSync(process.argv[2],"utf8"));
        const bad=[];
        for(const [k,f] of Object.entries(o.fields||{})){
          if(!S.tiers.includes(f.tier)) bad.push(k+":"+f.tier);
          if(f.tier==="UNAVAILABLE" && f.value!==null) bad.push(k+":UNAVAILABLE-with-value");
        }
        process.stdout.write(bad.join(","));' "$OUTD/last" "$SCHEMA" 2>/dev/null || echo PARSE)"
      [ "$RC" -eq 0 ] && [ -z "$TIERS_BAD" ] && bok "telemetry_report labels every field with a vocabulary tier; UNAVAILABLE fields carry null, never a guess" \
                                             || bfail "telemetry tier labeling wrong (rc=$RC bad=$TIERS_BAD)"
      if ! is_unsup mutation_event; then
        MV="$(node -e 'const o=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));process.stdout.write(String((o.fields.mutation_events||{}).value))' "$OUTD/last" 2>/dev/null)"
        [ "$MV" = "2" ] && bok "telemetry mutation_events EXACT value matches admitted events (2)" || bfail "telemetry count $MV != admitted 2"
      fi
      [ "$(rget degraded)" = "false" ] && bok "not degraded before any degradation event" || bfail "degraded flag wrong before degradation"
    fi
    # B11 degradation: silent refusal + propagation
    if is_unsup degradation; then
      expect_refusal degradation '{"task_id":"conf-1","reason":"x"}' "unsupported operation refused: degradation"
    else
      expect_refusal degradation '{"task_id":"conf-1"}' "reasonless degradation refused (silent degradation is not a state)"
      RC="$(run_op degradation '{"task_id":"conf-1","reason":"fan-out throttle fixture","evidence":"conformance walk"}')"
      [ "$RC" -eq 0 ] && bok "degradation recorded with reason+evidence" || bfail "degradation failed (rc=$RC)"
      if ! is_unsup telemetry_report; then
        run_op telemetry_report '{"task_id":"conf-1"}' >/dev/null
        [ "$(rget degraded)" = "true" ] && bok "degraded:true propagates into telemetry_report" || bfail "degradation did not propagate"
      fi
    fi
    # B12-B15 interruption / resume / completion discipline
    if is_unsup interruption; then
      expect_refusal interruption '{"task_id":"conf-1"}' "unsupported operation refused: interruption"
    else
      RC="$(run_op interruption '{"task_id":"conf-1","reason":"driver interrupt"}')"
      SF="$(rget state_file 2>/dev/null || true)"
      [ "$RC" -eq 0 ] && [ "$(rget resumable)" = "true" ] && [ -n "$SF" ] && [ -f "$SF" ] \
        && bok "interruption leaves a resumable state file on disk ($([ -f "$SF" ] && echo exists))" \
        || bfail "interruption not resumable (rc=$RC state_file=$SF)"
      if ! is_unsup completion; then
        expect_refusal completion '{"task_id":"conf-1"}' "completion of an interrupted task refused until resume"
      fi
      RC="$(run_op task_start '{"task_id":"conf-1","resume":true}')"
      [ "$RC" -eq 0 ] && [ "$(rget state)" = "resumed" ] && bok "task_start resume:true restores the interrupted task" || bfail "resume failed (rc=$RC)"
      if ! is_unsup mutation_event; then
        [ "$(rget mutation_events)" = "2" ] && bok "resume preserved the pre-interrupt EXACT counts (2)" || bfail "resume lost the counts"
      fi
    fi
    if is_unsup completion; then
      expect_refusal completion '{"task_id":"conf-1"}' "unsupported operation refused: completion"
    else
      RC="$(run_op completion '{"task_id":"conf-1"}')"
      [ "$RC" -eq 0 ] && [ "$(rget state)" = "complete" ] && bok "completion ok with final counts and degradation fact (degraded=$(rget degraded 2>/dev/null))" || bfail "completion failed (rc=$RC)"
      expect_refusal completion '{"task_id":"conf-1"}' "double completion refused"
    fi
    # B16 unknown operation refused, not invented
    expect_refusal not_an_operation '{"task_id":"conf-1"}' "unknown operation refused (the contract names exactly ten)"
  fi
elif [ -n "$ADAPTER_CMD" ]; then
  echo "BEHAV-SKIP: behavioral level not run — the declaration failed schema conformance first"
fi

echo "==== CONFORMANCE RESULT: schema $SOK ok / $SFAIL fail; behavioral $BOK ok / $BFAIL fail / $BSKIP skip ===="
[ "$SFAIL" -eq 0 ] && [ "$BFAIL" -eq 0 ]
