#!/usr/bin/env bash
# Build OS — mock-adapter.sh (LANE-4-adapter-contract): a fully-conforming
# LOCAL adapter for contract proof.
#
# WHAT THIS IS AND IS NOT. This adapter implements ALL TEN lifecycle operations
# of build-os/adapters/ADAPTER_CONTRACT.md against a local state directory,
# JSON in / JSON out, so the conformance driver has something real to drive.
# It is proof of CONTRACT behavior, NOT of any provider: it demonstrates what
# a conforming adapter looks like and demonstrates nothing about any network
# host. Its telemetry is honestly EXACT because the telemetry is its own
# synthetic state — it counts every event it generates itself; its
# provider_cost_usd stays tier UNAVAILABLE because it has no billing surface
# and does not guess one.
#
# PROTOCOL (the contract's invocation protocol, exactly):
#   ADAPTER_STATE_DIR=<dir> mock-adapter.sh <operation>   # request on stdin
# stdout: one JSON response with op + status ok|refused|error.
# exit 0 ok / 2 refused / 1 error.
#
# TEST FIXTURE: MOCK_DECLARE_UNSUPPORTED="op1,op2" removes those claims from
# the emitted capability_declaration AND refuses the matching operations —
# the driver uses it to prove a declared-unsupported operation is REFUSED,
# never faked. capability_declaration itself always answers.
#
# Semantics that carry contract weight:
#   * mutation_event WITHOUT a prior mutation-admitting authority_grant is
#     refused BEFORE anything is recorded (enforcement point: pre);
#   * authority_grant REFUSES external mutation authority — that belongs to
#     the operator, never to an adapter;
#   * interruption writes tasks/<id>/resume.json (counts + bindings preserved)
#     and completion is refused until task_start {resume:true};
#   * degradation requires a reason and propagates degraded:true into every
#     later telemetry_report and completion;
#   * counts are DERIVED by counting event rows, never stored.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CAPFILE="$SELF_DIR/mock-adapter.capability.json"
OP="${1:-}"
STATE="${ADAPTER_STATE_DIR:-}"
UNSUP="${MOCK_DECLARE_UNSUPPORTED:-}"

emit(){ printf '%s\n' "$1"; }
refuse(){ # <reason>
  emit "$(node -e 'console.log(JSON.stringify({op:process.argv[1],status:"refused",reason:process.argv[2]}))' "$OP" "$1")"
  exit 2
}
err(){
  emit "$(node -e 'console.log(JSON.stringify({op:process.argv[1],status:"error",reason:process.argv[2]}))' "${OP:--}" "$1")"
  exit 1
}

[ -n "$OP" ] || err "no operation named (argv[1])"
IN="$(cat 2>/dev/null || true)"
[ -n "$IN" ] || IN='{}'

# jq-free by policy (bash + node only): every JSON read/write goes through node.
jin(){ # <dot.path> -> value or rc 1; objects/arrays come back as JSON
  printf '%s' "$IN" | node -e '
    let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{
      let o; try{o=JSON.parse(d||"{}")}catch(e){process.exit(1)}
      const v=process.argv[1].split(".").reduce((a,k)=>a==null?a:a[k],o);
      if(v===undefined||v===null)process.exit(1);
      process.stdout.write(typeof v==="object"?JSON.stringify(v):String(v));
    })' "$1"
}

case "$OP" in
  task_start|context_delivery|authority_grant|mutation_event|telemetry_report|receipt_bind|completion|interruption|degradation|capability_declaration) ;;
  *) refuse "unknown operation '$OP' — the contract names exactly ten" ;;
esac

# The declared-unsupported fixture: refuse, never fake (capability_declaration
# itself always answers, so a driver can always ask what an adapter claims).
if [ -n "$UNSUP" ] && [ "$OP" != "capability_declaration" ]; then
  case ",$(printf '%s' "$UNSUP" | tr ' ' ','),"  in
    *",$OP,"*) refuse "operation '$OP' is declared unsupported by this adapter configuration — refused, not faked" ;;
  esac
fi

if [ "$OP" = "capability_declaration" ]; then
  [ -f "$CAPFILE" ] || err "capability file missing beside adapter: $CAPFILE"
  node -e '
    const fs=require("fs");
    const o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"));
    const unsup=(process.argv[2]||"").split(/[ ,]+/).filter(Boolean);
    for(const k of unsup){
      if(o.lifecycle[k]) o.lifecycle[k]={supported:false,tier:"UNAVAILABLE",enforcement:"none",
        notes:"fixture: declared unsupported to prove refusal"};
    }
    console.log(JSON.stringify(o,null,2));
  ' "$CAPFILE" "$UNSUP" || err "declaration emit failed"
  exit 0
fi

[ -n "$STATE" ] || err "ADAPTER_STATE_DIR unset — the adapter persists state, it does not pretend to"
mkdir -p "$STATE/tasks" 2>/dev/null || err "state dir not writable: $STATE"

TID="$(jin task_id)" || refuse "task_id missing from request"
TDIR="$STATE/tasks/$TID"
META="$TDIR/meta.json"

meta_get(){ # <key> -> value or rc 1
  [ -f "$META" ] || return 1
  node -e '
    const o=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
    const v=o[process.argv[2]];
    if(v===undefined||v===null)process.exit(1);
    process.stdout.write(typeof v==="object"?JSON.stringify(v):String(v));
  ' "$META" "$1"
}
meta_set(){ # <key> <json-value-literal>  (value passed as JSON text)
  node -e '
    const fs=require("fs");
    let o={}; try{o=JSON.parse(fs.readFileSync(process.argv[1],"utf8"))}catch(e){}
    o[process.argv[2]]=JSON.parse(process.argv[3]);
    fs.writeFileSync(process.argv[1],JSON.stringify(o,null,2));
  ' "$META" "$1" "$2" || err "state write failed"
}
count_rows(){ [ -f "$TDIR/$1" ] && wc -l < "$TDIR/$1" | tr -d ' ' || echo 0; }
require_task(){ [ -f "$META" ] || refuse "unknown task '$TID' — task_start first"; }
status_of(){ meta_get status 2>/dev/null || echo "-"; }
okjson(){ # <node-object-literal-builder args...> — emits {"op":..,"status":"ok",...}
  node -e '
    const extra=JSON.parse(process.argv[2]);
    console.log(JSON.stringify(Object.assign({op:process.argv[1],status:"ok"},extra)));
  ' "$OP" "$1"
}

case "$OP" in
  task_start)
    RESUME="$(jin resume 2>/dev/null || echo false)"
    if [ "$RESUME" = "true" ]; then
      [ -f "$TDIR/resume.json" ] || refuse "no resumable state for task '$TID'"
      [ "$(status_of)" = "interrupted" ] || refuse "task '$TID' is not interrupted — nothing to resume"
      meta_set status '"started"'
      meta_set resumed_from '"resume.json"'
      okjson "$(node -e '
        const r=JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"));
        console.log(JSON.stringify({task_id:r.task_id,state:"resumed",mutation_events:r.mutation_events}));
      ' "$TDIR/resume.json")"
      exit 0
    fi
    if [ -f "$META" ] && [ "$(status_of)" != "complete" ]; then
      refuse "task '$TID' already live (status $(status_of)) — duplicate start refused; use resume:true for an interrupted task"
    fi
    [ -f "$META" ] && refuse "task '$TID' already completed — a finished task does not restart"
    mkdir -p "$TDIR" || err "cannot create task state"
    printf '{}' > "$META"
    meta_set task_id "\"$TID\""
    meta_set status '"started"'
    meta_set description "$(node -e 'console.log(JSON.stringify(process.argv[1]))' "$(jin description 2>/dev/null || echo '-')")"
    meta_set mode "$(node -e 'console.log(JSON.stringify(process.argv[1]))' "$(jin mode 2>/dev/null || echo '-')")"
    okjson "{\"task_id\":$(node -e 'console.log(JSON.stringify(process.argv[1]))' "$TID"),\"state\":\"started\"}"
    ;;

  context_delivery)
    require_task
    [ "$(status_of)" = "started" ] || refuse "task '$TID' is $(status_of) — context is delivered to a started task"
    CTX="$(jin context)" || refuse "context array missing"
    N="$(printf '%s' "$CTX" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const a=JSON.parse(d);if(!Array.isArray(a))process.exit(1);console.log(a.length)})')" \
      || refuse "context must be an array"
    printf '%s\n' "$CTX" >> "$TDIR/context.jsonl"
    TOTAL="$(node -e '
      const fs=require("fs");
      let n=0; for(const l of fs.readFileSync(process.argv[1],"utf8").split("\n")) if(l.trim()) n+=JSON.parse(l).length;
      console.log(n)' "$TDIR/context.jsonl")"
    okjson "{\"delivered\":$N,\"total_items\":$TOTAL}"
    ;;

  authority_grant)
    require_task
    AUTH="$(jin authority)" || refuse "authority envelope missing"
    EXT="$(printf '%s' "$AUTH" | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{const a=JSON.parse(d);console.log(a.external_mutation===true?"true":"false")})')"
    [ "$EXT" = "true" ] && refuse "external mutation authority is NEVER granted by an adapter — push/deploy/publish/secrets belong to the operator's explicit go"
    printf '%s' "$AUTH" > "$TDIR/authority.json"
    okjson "{\"authority\":$AUTH}"
    ;;

  mutation_event)
    require_task
    if [ ! -f "$TDIR/authority.json" ] || \
       [ "$(node -e 'console.log(JSON.parse(require("fs").readFileSync(process.argv[1],"utf8")).mutation===true?"y":"n")' "$TDIR/authority.json" 2>/dev/null)" != "y" ]; then
      refuse "mutation refused PRE-EXECUTION: no authority_grant admits mutation for task '$TID' — nothing was recorded, nothing executed"
    fi
    TOOL="$(jin tool 2>/dev/null || echo '-')"
    printf '%s\t%s\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$TOOL" "$(jin target 2>/dev/null || echo '-')" >> "$TDIR/events.tsv"
    okjson "{\"mutation_events\":$(count_rows events.tsv),\"tier\":\"EXACT\"}"
    ;;

  telemetry_report)
    require_task
    DEG="false"; [ -f "$TDIR/degradation.json" ] && DEG="true"
    okjson "{\"task_id\":$(node -e 'console.log(JSON.stringify(process.argv[1]))' "$TID"),\"degraded\":$DEG,\"fields\":{
      \"mutation_events\":{\"value\":$(count_rows events.tsv),\"tier\":\"EXACT\"},
      \"context_items\":{\"value\":$( [ -f "$TDIR/context.jsonl" ] && node -e 'const fs=require("fs");let n=0;for(const l of fs.readFileSync(process.argv[1],"utf8").split("\n"))if(l.trim())n+=JSON.parse(l).length;console.log(n)' "$TDIR/context.jsonl" || echo 0),\"tier\":\"EXACT\"},
      \"synthetic_tokens\":{\"value\":$(( $(count_rows events.tsv) * 100 )),\"tier\":\"EXACT\",\"note\":\"synthetic usage the mock generates itself — EXACT is honest for self-generated state only\"},
      \"provider_cost_usd\":{\"value\":null,\"tier\":\"UNAVAILABLE\",\"note\":\"no billing surface exists here; admitted, never guessed\"}
    }}"
    ;;

  receipt_bind)
    require_task
    RID="$(jin receipt_id)" || refuse "receipt_id missing"
    if [ -f "$TDIR/receipt" ]; then
      printf '%s\trebind\t%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$RID" >> "$TDIR/events.log"
    fi
    printf '%s' "$RID" > "$TDIR/receipt"
    okjson "{\"receipt_id\":$(node -e 'console.log(JSON.stringify(process.argv[1]))' "$RID")}"
    ;;

  interruption)
    require_task
    [ "$(status_of)" = "started" ] || refuse "task '$TID' is $(status_of) — only a live task interrupts"
    node -e '
      const fs=require("fs");
      const dir=process.argv[1];
      let ev=0; try{ev=fs.readFileSync(dir+"/events.tsv","utf8").split("\n").filter(l=>l.trim()).length}catch(e){}
      let rid=null; try{rid=fs.readFileSync(dir+"/receipt","utf8")}catch(e){}
      const r={task_id:process.argv[2],status:"interrupted",reason:process.argv[3],
               mutation_events:ev,receipt_id:rid,interrupted_at:new Date().toISOString()};
      fs.writeFileSync(dir+"/resume.json",JSON.stringify(r,null,2));
    ' "$TDIR" "$TID" "$(jin reason 2>/dev/null || echo '-')" || err "resume state write failed"
    meta_set status '"interrupted"'
    okjson "{\"resumable\":true,\"state_file\":$(node -e 'console.log(JSON.stringify(process.argv[1]))' "$TDIR/resume.json")}"
    ;;

  degradation)
    require_task
    REASON="$(jin reason 2>/dev/null || true)"
    [ -n "$REASON" ] || refuse "degradation without a reason is silent degradation — refused"
    node -e '
      const fs=require("fs");
      fs.writeFileSync(process.argv[1]+"/degradation.json",
        JSON.stringify({reason:process.argv[2],evidence:process.argv[3],at:new Date().toISOString()},null,2));
    ' "$TDIR" "$REASON" "$(jin evidence 2>/dev/null || echo '-')" || err "degradation write failed"
    okjson "{\"degraded\":true}"
    ;;

  completion)
    require_task
    case "$(status_of)" in
      interrupted) refuse "task '$TID' is interrupted — resume it (task_start resume:true) before completion; its state file is $TDIR/resume.json" ;;
      complete)    refuse "task '$TID' already completed — a second completion would double-report" ;;
      started) ;;
      *) refuse "task '$TID' is in state $(status_of) — not completable" ;;
    esac
    DEG="false"; [ -f "$TDIR/degradation.json" ] && DEG="true"
    RID="null"; [ -f "$TDIR/receipt" ] && RID="$(node -e 'console.log(JSON.stringify(process.argv[1]))' "$(cat "$TDIR/receipt")")"
    meta_set status '"complete"'
    okjson "{\"state\":\"complete\",\"mutation_events\":$(count_rows events.tsv),\"receipt_id\":$RID,\"degraded\":$DEG}"
    ;;
esac
exit 0
