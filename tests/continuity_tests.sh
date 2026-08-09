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

# DIFFERENTIAL, NOT A SNAPSHOT. These three assertions used to pin CONT-0002 at
# BEHAVIOR_CHANGE_OBSERVED_ACTOR_UNDISAMBIGUATED, which was true until the live
# Lab supplied the identity evidence — then they failed for the RIGHT reason and
# would have been "repaired" by typing the new verdict, converting a guard into
# a transcription. The invariant is not which rung CONT-0002 sits on; it is that
# the ACTOR EVIDENCE IS LOAD-BEARING. So: grade it as it stands, then grade it
# again with that evidence stripped, and require the two to differ.
d(){ node -e '
Promise.all([import("./build-os/surfaces/continuity.mjs"),import("./build-os/surfaces/continuity-claims.mjs")]).then(([m,c])=>{
 const cl=JSON.parse(JSON.stringify(c.CLAIMS.find(x=>x.id==="CONT-0002")));
 if(process.argv[1]==="strip"){ const e=cl.links.behavioral_divergence.actor_evidence;
   delete e.surface_identifier; delete e.provider; delete e.model; }
 const g=m.gradeContinuity(cl);
 console.log(process.argv[2]==="f"?g.links.behavioral_divergence.actor_resolution.discriminating_evidence.join(","):g.verdict);});' "$1" "${2:-v}"; }
t "CONT-0002 WITH the live identity evidence reaches proven continuity" "$(d keep)" "CROSS_SURFACE_BEHAVIORAL_CONTINUITY_PROVEN"
t "  and WITHOUT it falls back to the middle rung — the evidence is load-bearing" "$(d strip)" "BEHAVIOR_CHANGE_OBSERVED_ACTOR_UNDISAMBIGUATED"
t "  stripped, the resolver again names the exact fields it needs" "$(d strip f)" "surface_identifier,provider"
t "  and the proven grade still demands NATIVE access to advance — bridge is not native" \
  "$(node -e 'Promise.all([import("./build-os/surfaces/continuity.mjs"),import("./build-os/surfaces/continuity-claims.mjs")]).then(([m,c])=>{const g=m.gradeContinuity(c.CLAIMS.find(x=>x.id==="CONT-0002"));console.log(String(/NATIVE/.test(g.missing_to_advance||"")))})')" "true"

echo "== the live gate reads the graded state, and cannot be told the answer =="
s(){ node -e '
import("./build-os/surfaces/readiness.mjs").then(m=>{const r=m.behavioralContinuity(JSON.parse(process.argv[1]||"{}"));
console.log(process.argv[2]==="d"?String(r.downgrades.length):r.state);});' "${1:-{\}}" "${2:-s}"; }
# Also a differential: the shipped state must EQUAL the strongest single claim,
# whatever that is, rather than a hardcoded rung.
t "the shipped state equals the strongest verdict any claim earns" \
  "$(node -e 'Promise.all([import("./build-os/surfaces/readiness.mjs"),import("./build-os/surfaces/continuity.mjs"),import("./build-os/surfaces/continuity-claims.mjs")]).then(([r,m,c])=>{
const best=c.CLAIMS.map(x=>m.gradeContinuity(x).verdict).reduce((a,b)=>m.VERDICTS.indexOf(b)>m.VERDICTS.indexOf(a)?b:a,"NO_TRANSFER");
console.log(String(r.behavioralContinuity({}).state===best))})')" "true"
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

echo "== the middle rung is a DIAGNOSTIC state and is never collapsed upward =="
# Operator ruling: cross-surface continuity is a claim about a DISTINCT
# RECEIVING ACTOR. With every link holding and the actor unresolved, what is
# proven is that behaviour changed -- not that a distinct surface changed it.
FULLLINKS='{"originating_surface":"claude","consuming_surface":"chatgpt","links":{"origination":{"status":"PROVEN","evidence_ref":"a"},"consumption":{"status":"PROVEN","evidence_ref":"b"},"behavioral_divergence":{"status":"PROVEN","evidence_ref":"c","counterfactual":"would have stopped","candidate_actors":[{"id":"chatgpt","expects":{"provider":"openai"}},{"id":"operator","expects":{"provider":"human"}}],"actor_evidence":{}},"durable_write_back":{"status":"PROVEN","evidence_ref":"d"},"onward_consumability":{"status":"PROVEN","evidence_ref":"e"}}}'
p(){ node -e '
import("./build-os/surfaces/continuity.mjs").then(m=>{const g=m.gradeContinuity(JSON.parse(process.argv[1]));
console.log(process.argv[2]==="p"?String(g.passing):(process.argv[2]==="m"?g.mediation:g.verdict));});' "$1" "${2:-v}"; }
t "all five links + unresolved actor stays on the middle rung" "$(p "$FULLLINKS")" "BEHAVIOR_CHANGE_OBSERVED_ACTOR_UNDISAMBIGUATED"
t "  and it is explicitly NOT a passing grade" "$(p "$FULLLINKS" p)" "false"
# THE ANTI-PROSE RULE. The old gate set DISAMBIGUATED iff the claim wrote a
# discriminator string, so a claim could disambiguate itself by saying it had.
PROSE=$(node -e 'const o=JSON.parse(process.argv[1]);o.links.behavioral_divergence.actor_discriminator="it was obviously ChatGPT";o.links.behavioral_divergence.actor="chatgpt";console.log(JSON.stringify(o))' "$FULLLINKS")
t "a prose discriminator buys NOTHING — identity is resolved, not declared" "$(p "$PROSE")" "BEHAVIOR_CHANGE_OBSERVED_ACTOR_UNDISAMBIGUATED"
# Resolving the actor from evidence is the ONLY way up.
RESOLVED=$(node -e 'const o=JSON.parse(process.argv[1]);o.links.behavioral_divergence.actor_evidence={provider:{value:"openai",source:"lab row caller identity"}};console.log(JSON.stringify(o))' "$FULLLINKS")
t "resolving the actor from ATTRIBUTABLE evidence does advance it" "$(p "$RESOLVED")" "CROSS_SURFACE_BEHAVIORAL_CONTINUITY_PROVEN"
t "  and mediation is reported on its own axis, not folded into the rung" "$(p "$RESOLVED" m)" "native"

echo "== the resolver preserves ambiguity and names the fetch =="
ri(){ node -e '
import("./build-os/surfaces/actor-identity.mjs").then(m=>{const r=m.resolveActorIdentity(JSON.parse(process.argv[1]),JSON.parse(process.argv[2]));
console.log(process.argv[3]==="d"?r.discriminating_evidence.join(","):(process.argv[3]==="c"?r.compatible_identities.join(","):r.status));});' "$1" "$2" "${3:-s}"; }
CANDS='[{"id":"chatgpt","expects":{"surface_identifier":"chatgpt.web","provider":"openai"}},{"id":"operator","expects":{"surface_identifier":"operator.sam.local","provider":"human"}}]'
t "no identity evidence: both remain compatible" "$(ri '{}' "$CANDS" c)" "chatgpt,operator"
t "  and the fields that WOULD separate them are named" "$(ri '{}' "$CANDS" d)" "surface_identifier,provider"
t "  status is UNDISAMBIGUATED, not a guess" "$(ri '{}' "$CANDS")" "UNDISAMBIGUATED"
ONE='{"provider":{"value":"openai","source":"lab row"}}'
t "one discriminating field resolves it" "$(ri "$ONE" "$CANDS")" "DISAMBIGUATED"
t "  to the right actor" "$(ri "$ONE" "$CANDS" c)" "chatgpt"
# A value no candidate expects means the candidate set is wrong -- reporting
# that beats silently resolving to whoever is left.
NONE='{"provider":{"value":"anthropic","source":"lab row"}}'
t "an incompatible value reports NO_COMPATIBLE_CANDIDATE" "$(ri "$NONE" "$CANDS")" "NO_COMPATIBLE_CANDIDATE"
# A value without a source is not evidence, it is a variable someone set.
NOSRC='{"provider":{"value":"openai"}}'
t "a value with NO SOURCE is not observed evidence" "$(ri "$NOSRC" "$CANDS")" "UNDISAMBIGUATED"

echo "== the work order is COMPUTED, and only while it is still needed =="
# Superseded by the differential above: with the live evidence present the
# resolver correctly names NO outstanding fields, because there are none. The
# invariant is that the work order tracks the gap — present when the gap is,
# absent when it is not — which the strip/keep pair proves in both directions.
w(){ node -e '
Promise.all([import("./build-os/surfaces/continuity.mjs"),import("./build-os/surfaces/continuity-claims.mjs")]).then(([m,c])=>{
const g=m.gradeContinuity(c.CLAIMS.find(x=>x.id==="CONT-0002"));
console.log(String(g.links.behavioral_divergence.actor_resolution.discriminating_evidence.length));});'; }
t "with the gap closed, no field is still demanded" "$(w)" "0"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
