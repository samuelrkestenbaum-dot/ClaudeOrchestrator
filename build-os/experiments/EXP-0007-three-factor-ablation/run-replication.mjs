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
const HERE = path.dirname(new URL(import.meta.url).pathname);
const TASKS = ["T01","T02","T03","T04"], CONFIGS = ["baseline","C"], REPS = [2,3];
const run = (t,c,r) => new Promise(res =>
  spawn("node",[path.join(HERE,"run-arm.mjs"),"--task",t,"--config",c,"--rep",String(r)],{stdio:"inherit"}).on("exit",res));
const log = [];
console.log(`EXP-0007 replication — ${TASKS.length} tasks x ${CONFIGS.length} configs x reps ${REPS.join(",")} = ${TASKS.length*CONFIGS.length*REPS.length} new arms`);
console.log(`rep 1 reused from the screening run (same harness, same seed, same ceiling)\n`);
for (const r of REPS) for (const t of TASKS) {
  const order = r % 2 === 0 ? CONFIGS : [...CONFIGS].reverse();
  for (const c of order) {
    const t0 = Date.now(); const code = await run(t,c,r);
    log.push({task:t,config:c,rep:r,exit:code,wall_s:Math.round((Date.now()-t0)/1000)});
    if (code !== 0) console.log(`  (arm ${t}/${c} rep${r} exited ${code} — recorded, continuing)`);
    fs.writeFileSync(path.join(HERE,"results/replication-log.json"),
      JSON.stringify({artifact:"exp0007_replication_log",question:"is C reliably better than baseline, or was the screening edge variance?",reps_executed:REPS,rep1_reused_from_screening:true,units:log},null,2));
  }
}
console.log(`\nreplication finished — ${log.length} arms, ${log.filter(l=>l.exit===0).length} clean`);
