#!/usr/bin/env node
// EXP-0007 screening driver — 5 configurations x 4 tasks, sequential.
//
// CONFIG ORDER ROTATES BY TASK. Whichever configuration runs first on a task
// pays for a cold cache; a fixed order would hand that cost to the same
// configuration on every task. Rotation is deterministic, so it is reproducible
// rather than shuffled.
//
// The native arm is NEVER run. EXP-0006's frozen native arm is the reference.
import { spawn } from "node:child_process";
import fs from "node:fs"; import path from "node:path";
const HERE = path.dirname(new URL(import.meta.url).pathname);
const arg=(n,d=null)=>{const i=process.argv.indexOf(`--${n}`);return i>0&&process.argv[i+1]?process.argv[i+1]:d;};
const TASKS=(arg("tasks")||"T01,T02,T03,T04").split(",");
const CONFIGS=(arg("configs")||"baseline,A,B,C,ABC").split(",");
const DRY=process.argv.includes("--dry-run");
const run=(t,c)=>new Promise(r=>spawn("node",[path.join(HERE,"run-arm.mjs"),"--task",t,"--config",c,...(DRY?["--dry-run"]:[])],{stdio:"inherit"}).on("exit",r));
const log=[];
console.log(`EXP-0007 screening — ${TASKS.length} tasks x ${CONFIGS.length} configs = ${TASKS.length*CONFIGS.length} arms, sequential`);
console.log(`native arm NOT re-run; EXP-0006 frozen native is the reference\n`);
for (let i=0;i<TASKS.length;i++){
  const order=[...CONFIGS.slice(i%CONFIGS.length),...CONFIGS.slice(0,i%CONFIGS.length)];
  for (const c of order){
    const t0=Date.now(); const code=await run(TASKS[i],c);
    log.push({task:TASKS[i],config:c,exit:code,wall_s:Math.round((Date.now()-t0)/1000)});
    if(code!==0) console.log(`  (arm ${TASKS[i]}/${c} exited ${code} — recorded, continuing)`);
    fs.mkdirSync(path.join(HERE,"results"),{recursive:true});
    fs.writeFileSync(path.join(HERE,"results/driver-log.json"),JSON.stringify({artifact:"exp0007_driver_log",order_rule:"config list rotated by task index",units:log},null,2));
  }
}
console.log(`\ndriver finished — ${log.length} arms, ${log.filter(l=>l.exit===0).length} clean`);
