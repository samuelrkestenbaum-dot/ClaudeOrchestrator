#!/usr/bin/env bash
# The continuity verifier must GRADE, not rubber-stamp. Its value is entirely
# in the cases it refuses, so the negative fixtures carry the weight — and it
# must still be able to reach its top verdict, or refusing everything would
# look identical to working correctly.
set -uo pipefail
cd "$(dirname "$0")/.."
P=0; F=0
ok(){ P=$((P+1)); echo "  ok   $1"; }
no(){ F=$((F+1)); echo "  FAIL $1"; }
t(){ [ "$2" = "$3" ] && ok "$1" || no "$1 (got '$2' want '$3')"; }

echo "== fixtures: cases that did NOT inspire the verifier =="
FIX=$(node -e '
Promise.all([import("./build-os/surfaces/continuity.mjs"),import("./build-os/surfaces/fixtures/continuity.fixtures.mjs")])
.then(([m,f])=>{for(const c of [...f.NEGATIVE,...f.POSITIVE])
  console.log([c.name,m.gradeContinuity(c.claim).verdict,c.expect].join("\t"));});')
while IFS=$'\t' read -r name got want; do
  [ -n "$name" ] && t "$name" "$got" "$want"
done <<< "$FIX"

echo "== the two anti-self-assertion rules must actually downgrade =="
d(){ node -e '
import("./build-os/surfaces/continuity.mjs").then(m=>{
 const g=m.gradeContinuity(JSON.parse(process.argv[1]));
 console.log(process.argv[2]==="n"?String(g.downgrades.length):g.links[process.argv[2]].status);});' "$1" "${2:-n}"; }
BARE='{"originating_surface":"claude","consuming_surface":"chatgpt","links":{"origination":{"status":"PROVEN"}}}'
t "PROVEN without evidence_ref is downgraded to INFERRED" "$(d "$BARE" origination)" "INFERRED"
t "  and the downgrade is REPORTED, not silent" "$(d "$BARE")" "1"
NOCF='{"originating_surface":"claude","consuming_surface":"chatgpt","links":{"behavioral_divergence":{"status":"PROVEN","evidence_ref":"x"}}}'
t "divergence without a counterfactual is downgraded" "$(d "$NOCF" behavioral_divergence)" "INFERRED"
t "  even though it carried an evidence_ref" "$(d "$NOCF")" "1"

echo "== the record, graded honestly =="
r(){ node -e '
Promise.all([import("./build-os/surfaces/continuity.mjs"),import("./build-os/surfaces/continuity-claims.mjs")])
.then(([m,c])=>{const g=m.gradeContinuity(c.CLAIMS.find(x=>x.id===process.argv[1]));
console.log(process.argv[2]==="w"?g.weakest_link:(process.argv[2]==="a"?String(!!g.missing_to_advance):g.verdict));});' "$1" "${2:-v}"; }
t "CONT-0001 (HOF-0001) grades CONSUMPTION_ONLY — receipt is not continuity" "$(r CONT-0001)" "CONSUMPTION_ONLY"
t "CONT-0002 (Lab bridge) does NOT reach bridge-mediated continuity" "$(r CONT-0002)" "CONTINUITY_ACTOR_UNDISAMBIGUATED"
t "  and every unfinished grade names what would advance it" "$(r CONT-0002 a)" "true"

echo "== the live gate reads the graded state, and cannot be told the answer =="
s(){ node -e '
import("./build-os/surfaces/readiness.mjs").then(m=>{const r=m.behavioralContinuity(JSON.parse(process.argv[1]||"{}"));
console.log(process.argv[2]==="d"?String(r.downgrades.length):r.state);});' "${1:-{\}}" "${2:-s}"; }
t "the shipped state is the strongest verdict any claim earns" "$(s)" "CONTINUITY_ACTOR_UNDISAMBIGUATED"
# THE REGRESSION THAT MATTERS. The old gate took {behaviour_changed:true,
# result_written_back:true} and reported DEMONSTRATED. Handing the new gate the
# same self-assertion must NOT buy a verdict.
SELF='{"claims":[{"id":"SELF","originating_surface":"claude","consuming_surface":"chatgpt","behaviour_changed":true,"result_written_back":true}]}'
t "a free 'behaviour_changed:true' buys NOTHING" "$(s "$SELF")" "NO_TRANSFER"
ALLPROVEN='{"claims":[{"id":"BARE","originating_surface":"claude","consuming_surface":"chatgpt","links":{"origination":{"status":"PROVEN"},"consumption":{"status":"PROVEN"},"behavioral_divergence":{"status":"PROVEN"},"durable_write_back":{"status":"PROVEN"},"onward_consumability":{"status":"PROVEN"}}}]}'
t "five bare PROVEN assertions buy NOTHING" "$(s "$ALLPROVEN")" "NO_TRANSFER"
# Five, not six: the divergence link is downgraded once for the missing
# evidence_ref, which drops it below the threshold at which the counterfactual
# rule fires. One link yields one downgrade, and the two rules do not stack.
t "  and the downgrades are surfaced to the caller" "$(s "$ALLPROVEN" d)" "5"

echo "== a pile of weak claims never sums to a strong one =="
MANY=$(node -e 'const c={id:"x",originating_surface:"claude",consuming_surface:"chatgpt",links:{origination:{status:"PROVEN",evidence_ref:"a"},consumption:{status:"PROVEN",evidence_ref:"b"}}};
console.log(JSON.stringify({claims:Array.from({length:50},(_,i)=>({...c,id:"x"+i}))}))')
t "50 CONSUMPTION_ONLY claims are still CONSUMPTION_ONLY" "$(s "$MANY")" "CONSUMPTION_ONLY"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
