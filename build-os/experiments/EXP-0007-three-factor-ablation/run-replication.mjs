#!/usr/bin/env node
// EXP-0007 REPLICATION — baseline vs C, 4 tasks x 2 configs x 3 reps = 24 arms.
//
// THE QUESTION IS ONE QUESTION: is C actually better than baseline, or was the
// screening edge variance? Screening measured five configurations once each and
// could not answer it, because identical baseline configuration moved 30% on
// T03 and 1.85x on T04 between EXP-0006 and EXP-0007. A difference smaller than
// that spread is not a difference yet.
//
// Rep 1 of each cell ALREADY EXISTS from the screening run and is reused rather
// than re-run: it was produced by the same harness, at the same seed, under the
// same ceiling. Only reps 2 and 3 execute -- 16 arms, not 24.
//
// Config order alternates by rep so neither config eats the cold-cache cost
// every time.
import { spawn } from "node:child_process";
import fs from "node:fs"; import path from "node:path";
import { assess, loadProgram } from "../../motion/convergence.mjs";
const HERE = path.dirname(new URL(import.meta.url).pathname);

// PROGRAM CONVERGENCE GATE — wired here because this is the cheapest place to
// spend six hours of compute on a result that cannot change a decision. A gate
// that only advises is the same defect as a check that never fails, so this one
// EXITS NON-ZERO: an experiment whose every outcome leads to the same next
// action does not run, and once the stop condition for its decision is
// satisfied, no further re-baselining runs at all.
//
// The proposal must be supplied by the caller in --convergence <file>, so the
// possible results are stated BEFORE the data exists rather than after.
{
  const cf = (() => { const i = process.argv.indexOf("--convergence"); return i > 0 ? process.argv[i + 1] : null; })();
  if (!cf) {
    console.error("REFUSED — no --convergence <proposal.json>. State the decision this run serves,");
    console.error("and what each possible result would make us do next, before spending the compute.");
    process.exit(3);
  }
  const proposal = JSON.parse(fs.readFileSync(cf, "utf8"));
  const v = assess(proposal, loadProgram());
  console.log(`CONVERGENCE ${v.verdict}: ${v.code}\n  ${v.why}`);
  for (const r of v.reasons) console.log(`  · ${r}`);
  if (v.verdict !== "PROCEED") { console.error("\nNot running. Evidence sufficient, or result cannot move the decision."); process.exit(3); }
}
const arg=(n,d)=>{const i=process.argv.indexOf(`--${n}`);return i>0&&process.argv[i+1]?process.argv[i+1]:d;};
const TASKS = (arg("tasks","T01,T02,T03,T04")).split(",");
const CONFIGS = (arg("configs","baseline,C")).split(",");
const REPS = (arg("reps","2,3")).split(",").map(Number);
// RESUMABLE. The container restarted mid-run and killed the driver at arm 2 of
// 16. Completed arms survived on disk, so re-running them would burn compute to
// reproduce measurements that already exist -- and would also overwrite them,
// which is worse. A cell is skipped only when its record is ADMISSIBLE; a
// launcher_died or timed_out record is not a result and is re-run.
function alreadyDone(t,c,r){
  const dir = path.join(HERE,"results/runs", r>1?`${t}.${c}.r${r}`:`${t}.${c}`);
  try { return JSON.parse(fs.readFileSync(path.join(dir,"run-record.json"),"utf8")).admissible === true; }
  catch { return false; }
}
const run = (t,c,r) => new Promise(res =>
  spawn("node",[path.join(HERE,"run-arm.mjs"),"--task",t,"--config",c,"--rep",String(r)],{stdio:"inherit"}).on("exit",res));
const log = [];
console.log(`EXP-0007 replication — ${TASKS.length} tasks x ${CONFIGS.length} configs x reps ${REPS.join(",")} = ${TASKS.length*CONFIGS.length*REPS.length} new arms`);
console.log(`rep 1 reused from the screening run (same harness, same seed, same ceiling)\n`);
for (const r of REPS) for (const t of TASKS) {
  const order = r % 2 === 0 ? CONFIGS : [...CONFIGS].reverse();
  for (const c of order) {
    if (alreadyDone(t,c,r)) { console.log(`SKIP ${t}/${c} rep${r} — admissible result already on disk`); log.push({task:t,config:c,rep:r,skipped:true}); continue; }
    const t0 = Date.now(); const code = await run(t,c,r);
    log.push({task:t,config:c,rep:r,exit:code,wall_s:Math.round((Date.now()-t0)/1000)});
    if (code !== 0) console.log(`  (arm ${t}/${c} rep${r} exited ${code} — recorded, continuing)`);
    fs.writeFileSync(path.join(HERE,"results/replication-log.json"),
      JSON.stringify({artifact:"exp0007_replication_log",question:"is C reliably better than baseline, or was the screening edge variance?",reps_executed:REPS,rep1_reused_from_screening:true,units:log},null,2));
  }
}
console.log(`\nreplication finished — ${log.length} arms, ${log.filter(l=>l.exit===0).length} clean`);
