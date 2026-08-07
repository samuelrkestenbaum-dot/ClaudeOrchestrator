// Items 5 and 6 — structural and adversarial fixtures.
import { deriveIds, buildView, attemptJoin, assertSingleRole, ROLE_FORBIDDEN, ROLE_FIELDS } from "./roles.mjs";
import { splitPaths, stripGovernanceDiff, assertProductOnly, isGovernancePath } from "./governance-strip.mjs";
let P=0,F=0; const o=[];
const ck=(n,c,d="")=>{ if(c){P++;o.push(`  ok   ${n}`);} else {F++;o.push(`  FAIL ${n}${d?" — "+d:""}`);} };

const SALT="exp0005-test-salt";
const tasks=["T1","T2","T3"], arms=["N","G"];
const rows=[];
for(const t of tasks) for(const a of arms){
  const {adj_id,ana_id}=deriveIds(SALT,t,a);
  rows.push({adj_id,ana_id,task_id:t,arm:a,objective:`obj ${t}`,acceptance_criteria:["c1"],
    product_diff_ref:`wp-${t}-${a}.diff`,tests_run:10,tests_passed:10,verification_evidence:"ok",
    acceptance_result:"accepted",uncached_tokens:1000+(a==="G"?500:0),total_tokens:9000,
    total_elapsed_s:900,subagent_invocations:a==="G"?4:0,rework_rounds:1,human_interventions:0,
    regressions:0,api_equivalent_cost_usd:1.23});
}
const adjView=buildView("adjudicator",rows), anaView=buildView("analyst",rows);

// ---- ITEM 5 ---------------------------------------------------------------
ck("ITEM5: the two views share NO identifier",
  !attemptJoin(adjView,anaView).joined_on_shared_key, JSON.stringify(attemptJoin(adjView,anaView).shared_keys));
ck("ITEM5: condition identity is NOT recoverable from both views",
  attemptJoin(adjView,anaView).condition_identity_recovered===false);
ck("ITEM5: the verdict says the blind holds", /blind holds/.test(attemptJoin(adjView,anaView).verdict));
ck("ITEM5: task_id selects a matched PAIR, never a side",
  attemptJoin(adjView,anaView).task_id_join_ambiguous_for.length===tasks.length,
  JSON.stringify(attemptJoin(adjView,anaView).task_id_join_ambiguous_for));
ck("ITEM5: adj and ana ids differ for the SAME unit",
  deriveIds(SALT,"T1","G").adj_id!==deriveIds(SALT,"T1","G").ana_id);
ck("ITEM5: neither id is derivable from the other without the salt",
  deriveIds(SALT,"T1","G").ana_id!==deriveIds("other-salt","T1","G").ana_id);
ck("ITEM5: the adjudicator sees no arm/condition", adjView.units.every(u=>u.arm===undefined&&u.condition===undefined));
ck("ITEM5: the adjudicator sees no economics",
  adjView.units.every(u=>u.uncached_tokens===undefined&&u.total_elapsed_s===undefined&&u.subagent_invocations===undefined));
ck("ITEM5: the adjudicator sees no ana_id", adjView.units.every(u=>u.ana_id===undefined));
ck("ITEM5: the analyst sees no product diff or adj_id",
  anaView.units.every(u=>u.product_diff_ref===undefined&&u.adj_id===undefined));
ck("ITEM5: the analyst sees no arm/condition", anaView.units.every(u=>u.arm===undefined));
ck("ITEM5: the analyst DOES receive frozen acceptance", anaView.units.every(u=>u.acceptance_result==="accepted"));
// The previous assertion here was VACUOUS: buildView projects forbidden fields
// out before its leak check runs, so the check is unreachable and the test fell
// through to asserting that adding a field makes that field defined. Replaced
// with two assertions that can actually fail.
ck("ITEM5: projection DROPS a forbidden field even when present in the input",
  buildView("adjudicator", [{...rows[0], arm:"G", uncached_tokens:999}]).units[0].arm===undefined);
ck("ITEM5: projection drops economics even when present in the input",
  buildView("adjudicator", [{...rows[0], uncached_tokens:999}]).units[0].uncached_tokens===undefined);
ck("ITEM5: the leak guard FIRES if a field set is misconfigured", (()=>{
  const saved=[...ROLE_FIELDS.adjudicator];
  ROLE_FIELDS.adjudicator.push("arm");                 // simulate a bad allow-list
  let threw=false;
  try{ buildView("adjudicator", [{...rows[0], arm:"G"}]); }catch(e){ threw=/leaks forbidden/.test(e.message); }
  ROLE_FIELDS.adjudicator.length=0; ROLE_FIELDS.adjudicator.push(...saved);
  return threw;
})());
ck("ITEM5: an unknown role is refused outright", (()=>{
  try{ buildView("auditor", rows); return false; }catch(e){ return /not a blinded role/.test(e.message); }
})());

const held=assertSingleRole([adjView,anaView]);
ck("ITEM5: an agent holding BOTH views is refused", held.single_role===false, JSON.stringify(held.domains));
ck("ITEM5: the refusal names more than one blinded role", /more than one blinded role/.test(held.refusal||""));
ck("ITEM5: an agent holding ONE view is fine", assertSingleRole([adjView]).single_role===true);
ck("ITEM5: holding executor state plus a blinded view is refused",
  assertSingleRole([adjView,{view:"executor",arm:"G"}]).single_role===false);

// ---- ITEM 6 ---------------------------------------------------------------
const paths=["server/router.ts","build-os/receipts/CP-1.md",".claude/settings.json","client/app.tsx",
  "build-os/memory/current_state.md","docs/readme.md","CLAUDE.md","build-os/packets/routing/r.md"];
const sp=splitPaths(paths);
ck("ITEM6: governance paths are separated", sp.governance_count===5, JSON.stringify(sp.governance_paths));
ck("ITEM6: product paths survive", sp.product_paths.length===3, JSON.stringify(sp.product_paths));
ck("ITEM6: governance receives ZERO numerator credit", sp.numerator_credit_for_governance===0);
ck("ITEM6: the accounting note says cost, never output", /COST, never output/.test(sp.accounting_note));
ck("ITEM6: costs stay in the denominator", /remain in the denominator/.test(sp.accounting_note));
for(const g of ["build-os/x.md",".claude/y.json","a/receipts/z.md","b/memory/m.md","c/routing/r.md","CLAUDE.md"])
  ck(`ITEM6: recognised as governance: ${g}`, isGovernancePath(g));
for(const p of ["server/a.ts","client/b.tsx","shared/c.ts"])
  ck(`ITEM6: NOT governance: ${p}`, !isGovernancePath(p));
const diff=`diff --git a/server/router.ts b/server/router.ts\n+ok\ndiff --git a/build-os/receipts/CP-1.md b/build-os/receipts/CP-1.md\n+receipt\n`;
const st=stripGovernanceDiff(diff);
ck("ITEM6: the governance hunk is removed from the product diff", !/receipts/.test(st.product_diff));
ck("ITEM6: the product hunk survives", /server\/router\.ts/.test(st.product_diff));
ck("ITEM6: the governance diff is retained separately for costing", /receipts/.test(st.governance_diff));
ck("ITEM6: a clean product artifact is admissible",
  assertProductOnly(st.product_diff, sp.product_paths).classification==="admissible");
const leak=assertProductOnly(diff, paths);
ck("ITEM6: a governance path in the adjudicated artifact => result_confounded",
  leak.classification==="result_confounded", JSON.stringify(leak.leaked_paths));
ck("ITEM6: the reason says it is NOT re-stripped", /rather than re-stripped/.test(leak.reason||""));
ck("ITEM6: a leak via the PATH LIST alone is also caught",
  assertProductOnly("", ["build-os/receipts/x.md"]).classification==="result_confounded");

process.stdout.write(o.join("\n")+"\n");
process.stdout.write(`TESTS: ${P} passed, ${F} failed, 0 skipped\n`);
process.exit(F?1:0);
