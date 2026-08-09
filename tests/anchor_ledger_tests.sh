#!/usr/bin/env bash
# PHASE 1 GATE — the contract, the append-only ledger, and a rollback that is
# EXECUTED rather than asserted.
#
# Attempt 1 shipped claiming its mapping was "reversible and auditable". That
# claim came from reading the code. Exercised for the first time during the
# post-mortem, the reversal recovered 0 of 712 references, because the ledger
# had been overwritten by a later run of the same tool. So the load-bearing
# case here is not "does the ledger have the right columns" — it is: overwrite
# it the way attempt 1 did, and require the migration to still be reversible.
set -uo pipefail
cd "$(dirname "$0")/.."
P=0; F=0
ok(){ P=$((P+1)); echo "  ok   $1"; }
no(){ F=$((F+1)); echo "  FAIL $1"; }
t(){ [ "$2" = "$3" ] && ok "$1" || no "$1 (got '$2' want '$3')"; }

W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
L="$W/ledger.tsv"
n(){ node -e "$1" "${@:2}"; }

echo "== the ledger APPENDS; there is no write path that truncates =="
n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>{
  m.append([{migration_version:"v1",control_id:"a",old_ref:"f.sh:1",new_ref:"f.sh#c:aaa",status:"MIGRATED",provenance:"mechanical_migration",old_line:"1",content:"x",reviewed:"false",stamp:"S"}],process.argv[1]);
});' "$L"
A="$(grep -c . "$L")"
n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>{
  m.append([{migration_version:"v1",control_id:"b",old_ref:"g.sh:2",new_ref:"g.sh#c:bbb",status:"MIGRATED",provenance:"mechanical_migration",old_line:"2",content:"y",reviewed:"false",stamp:"S"}],process.argv[1]);
});' "$L"
B="$(grep -c . "$L")"
[ "$B" -gt "$A" ] && ok "a second append GREW the ledger ($A -> $B lines)" || no "the ledger did not grow ($A -> $B)"
t "  both rows are still readable" "$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>console.log(m.read(process.argv[1]).length))' "$L")" "2"
# THE ATTEMPT-1 SHAPE: run the tool again when there is nothing to do.
n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>{m.append([],process.argv[1]);});' "$L"
t "  a run with NOTHING to migrate does not erase prior rows" "$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>console.log(m.read(process.argv[1]).length))' "$L")" "2"
t "  and ensure() on an existing ledger does not truncate it" \
  "$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>{m.ensure(process.argv[1]);console.log(m.read(process.argv[1]).length)})' "$L")" "2"

echo "== the ledger REFUSES to launder form-conversion into review =="
RC="$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>{
  try{ m.append([{migration_version:"v1",control_id:"c",old_ref:"h.sh:3",new_ref:"h.sh#c:ccc",status:"MIGRATED",provenance:"mechanical_migration",old_line:"3",content:"z",reviewed:"true",stamp:"S"}],process.argv[1]); console.log("ACCEPTED"); }
  catch(e){ console.log("REFUSED"); }});' "$L")"
t "reviewed=true is refused at the write path, not left to callers" "$RC" "REFUSED"
t "  an illegal status is refused too" \
  "$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>{try{m.append([{migration_version:"v1",control_id:"d",status:"SORTOF",reviewed:"false"}],process.argv[1]);console.log("ACCEPTED")}catch(e){console.log("REFUSED")}});' "$L")" "REFUSED"
t "  and neither refusal wrote anything" "$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>console.log(m.read(process.argv[1]).length))' "$L")" "2"

echo "== REVERSAL IS EXECUTED, and it APPENDS rather than deletes =="
n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>{
  const mig=m.read(process.argv[1]).filter(r=>r.status==="MIGRATED");
  m.append(m.reversalRows(mig,"v1","S"),process.argv[1]);});' "$L"
t "reversing appends REVERSED rows beside the originals" "$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>console.log(m.read(process.argv[1]).length))' "$L")" "4"
t "  the MIGRATED rows SURVIVE the reversal" \
  "$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>console.log(m.read(process.argv[1]).filter(r=>r.status==="MIGRATED").length))' "$L")" "2"
t "  and the live mapping is empty, computed by replay" \
  "$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>console.log(m.liveMappings(process.argv[1]).length))' "$L")" "0"
# What the reversal is FOR: recovering the original citation.
t "  each reversal carries the positional ref to restore" \
  "$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>{const r=m.read(process.argv[1]).find(x=>x.status==="REVERSED");console.log(r.new_ref)})' "$L")" "f.sh:1"

echo "== FULL ROUND TRIP on a fixture registry: forward, reverse, byte-identical =="
R="$W/repo"; mkdir -p "$R/src" "$R/build-os/registry"
printf '#!/usr/bin/env bash\n[ "$n" -ge 3 ] && exit 0\necho distinct one\necho distinct two\n' > "$R/src/a.sh"
cat > "$R/build-os/registry/reg.txt" <<'EOF'
id: demo.one
evidence_refs: src/a.sh:2; src/a.sh:3
notes: -
EOF
cp "$R/build-os/registry/reg.txt" "$W/baseline.txt"
node build-os/registry/anchor-roundtrip.mjs --repo "$R" --registry "$R/build-os/registry/reg.txt" \
  --ledger "$R/led.tsv" --version v1 --stamp S --forward > "$W/fwd.json" 2>&1
t "forward migration converted both refs" "$(node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).migrated))' < "$W/fwd.json")" "2"
grep -q '#c:' "$R/build-os/registry/reg.txt" && ok "  the registry now carries anchors" || no "the registry was not converted"
cmp -s "$R/build-os/registry/reg.txt" "$W/baseline.txt" && no "forward migration changed nothing" || ok "  and differs from the baseline"

# THE ATTEMPT-1 KILLER, reproduced deliberately: run the tool again with
# nothing to do, THEN reverse. Attempt 1 died exactly here.
node build-os/registry/anchor-roundtrip.mjs --repo "$R" --registry "$R/build-os/registry/reg.txt" \
  --ledger "$R/led.tsv" --version v1 --stamp S --forward > /dev/null 2>&1
node build-os/registry/anchor-roundtrip.mjs --repo "$R" --registry "$R/build-os/registry/reg.txt" \
  --ledger "$R/led.tsv" --version v1 --stamp S --reverse > "$W/rev.json" 2>&1
t "reversal after a redundant re-run still restores both refs" \
  "$(node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>console.log(JSON.parse(s).reversed))' < "$W/rev.json")" "2"
cmp -s "$R/build-os/registry/reg.txt" "$W/baseline.txt" \
  && ok "  and the registry is BYTE-IDENTICAL to the baseline" \
  || { no "rollback did not restore the baseline"; diff "$W/baseline.txt" "$R/build-os/registry/reg.txt" | head -4; }

echo "== the ledger survives the round trip as a complete history =="
t "every event is on record: 2 forward + 2 reversed" \
  "$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>{const r=m.read(process.argv[1]);console.log(r.filter(x=>x.status==="MIGRATED").length+"+"+r.filter(x=>x.status==="REVERSED").length)})' "$R/led.tsv")" "2+2"
t "  and nothing claims review" \
  "$(n 'import("./build-os/registry/anchor-ledger.mjs").then(m=>console.log(m.read(process.argv[1]).filter(r=>r.reviewed==="true").length))' "$R/led.tsv")" "0"

echo "== the contract is frozen and states both directions =="
C="build-os/registry/ANCHOR-CONTRACT.md"
grep -q "irrelevant movement" "$C" && ok "the contract names the SURVIVE case" || no "no survive case in the contract"
grep -q "evidentiary change" "$C" && ok "the contract names the STALE case" || no "no stale case in the contract"
grep -q "append-only" "$C" && ok "the contract requires the ledger be append-only" || no "the ledger rule is not in the contract"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
