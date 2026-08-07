import fs from "node:fs"; import os from "node:os"; import path from "node:path";
import { openRun, closeRun, classify, verifyIsolation, scrubbedEnv,
         SESSION_SCOPED_ENV, TERMINAL_STATES, newSessionId } from "./run-record.mjs";
let P=0,F=0; const o=[];
const ck=(n,c,d="")=>{ if(c){P++;o.push(`  ok   ${n}`);} else {F++;o.push(`  FAIL ${n}${d?" — "+d:""}`);} };
const tmp = fs.mkdtempSync(path.join(os.tmpdir(),"rr-"));
const w=(n,lines)=>{const f=path.join(tmp,n);fs.writeFileSync(f,lines.map(x=>JSON.stringify(x)).join("\n"));return f;};

// --- 1. env scrubbing: the actual root cause of attempt 1 -------------------
const env = scrubbedEnv({ CLAUDE_CODE_SESSION_ID:"parent", CLAUDE_CODE_CHILD_SESSION:"1", CLAUDE_PID:"9", PATH:"/bin" });
ck("session-scoped env vars are scrubbed", SESSION_SCOPED_ENV.every(k=>!(k in env)), JSON.stringify(Object.keys(env)));
ck("unrelated env survives", env.PATH === "/bin");
ck("a fresh session id is a uuid", /^[0-9a-f-]{36}$/.test(newSessionId()));

// --- 2. isolation is PROVEN from the child's own stream ---------------------
const parent="5489b495-ae3d-5612-a4e1-61b4b5c6b6e4", child=newSessionId();
const leaked = w("leak.jsonl",[{type:"system",session_id:parent},{type:"assistant",session_id:parent}]);
const clean  = w("clean.jsonl",[{type:"system",session_id:child},{type:"result",session_id:child,is_error:false,num_turns:5}]);
const iso1 = verifyIsolation({streamPath:leaked, expectedSessionId:child, orchestratorSessionId:parent});
ck("ATTEMPT-1 SHAPE: a child reporting the orchestrator's id is NOT isolated", iso1.isolated===false, iso1.reason);
ck("the reason names shared session-scoped state", /measurer and measured/.test(iso1.reason));
const iso2 = verifyIsolation({streamPath:clean, expectedSessionId:child, orchestratorSessionId:parent});
ck("a distinct, assigned session id IS isolated", iso2.isolated===true, iso2.reason);
ck("a child reporting some OTHER id is not isolated",
  verifyIsolation({streamPath:clean, expectedSessionId:"different", orchestratorSessionId:parent}).isolated===false);
ck("no stream => isolation is NOT assumed",
  verifyIsolation({streamPath:path.join(tmp,"nope.jsonl"), expectedSessionId:child, orchestratorSessionId:parent}).isolated===false);

// --- 3. terminal states: a missing result event is never completion ---------
const noresult = w("noresult.jsonl",[{type:"system",session_id:child},{type:"assistant",session_id:child}]);
const v1 = classify({streamPath:noresult, exitCode:0, ceilingS:5400, elapsedS:290, launcherAlive:true});
ck("ATTEMPT-1 SHAPE: no result event => missing_result_event, not completed", v1.terminal_reason==="missing_result_event", v1.terminal_reason);
ck("it is flagged is_error", v1.is_error===true);
ck("the detail says it is NOT a completion", /NOT a completion/.test(v1.detail));
ck("a dead launcher is launcher_died",
  classify({streamPath:noresult, exitCode:null, ceilingS:5400, elapsedS:290, launcherAlive:false}).terminal_reason==="launcher_died");
ck("exit 124 at the ceiling is timed_out",
  classify({streamPath:noresult, exitCode:124, ceilingS:5400, elapsedS:5400}).terminal_reason==="timed_out");
ck("a signal exit is killed",
  classify({streamPath:noresult, exitCode:137, ceilingS:5400, elapsedS:100}).terminal_reason==="killed");
ck("a clean result event is completed",
  classify({streamPath:clean, exitCode:0, ceilingS:5400, elapsedS:100}).terminal_reason==="completed");
ck("an aborted stream is aborted_streaming", classify({
  streamPath:w("abort.jsonl",[{type:"result",session_id:child,is_error:true,terminal_reason:"aborted_streaming"}]),
  exitCode:0, ceilingS:5400, elapsedS:100}).terminal_reason==="aborted_streaming");
ck("no stream at all is infrastructure_error",
  classify({streamPath:path.join(tmp,"absent.jsonl"), exitCode:1}).terminal_reason==="infrastructure_error");
ck("every classification is in the registered set", [v1.terminal_reason,
  classify({streamPath:clean,exitCode:0}).terminal_reason].every(r=>TERMINAL_STATES.includes(r)));

// --- 4. durable record: exists BEFORE launch, survives a vanished child -----
const d1 = path.join(tmp,"run1"); openRun(d1,{task_id:"E1",arm:"G",launched_at:"2026-08-07T11:31:54Z",
  expected_session_id:child, orchestrator_session_id:parent, timeout_ceiling_s:5400, pid:6848});
const pre = JSON.parse(fs.readFileSync(path.join(d1,"run-record.json"),"utf8"));
ck("a run record exists before the child launches", pre.state==="launched" && pre.task_id==="E1");
ck("it records both identities", pre.expected_session_id===child && pre.orchestrator_session_id===parent);
ck("it is not admissible until closed", pre.admissible===false);
const closed = closeRun(d1, classify({streamPath:noresult,exitCode:0,launcherAlive:false}),
  verifyIsolation({streamPath:noresult, expectedSessionId:child, orchestratorSessionId:parent}));
ck("a vanished child still produces a terminal record", closed.state==="terminal" && closed.terminal_reason==="launcher_died");
ck("it is INADMISSIBLE", closed.admissible===false && /REFUSED/.test(closed.admissibility_note));

// --- 5. completion WITHOUT proven isolation is still refused ----------------
const d2 = path.join(tmp,"run2"); openRun(d2,{task_id:"E1",arm:"G",expected_session_id:child,orchestrator_session_id:parent});
const c2 = closeRun(d2, classify({streamPath:clean,exitCode:0}),
  verifyIsolation({streamPath:leaked, expectedSessionId:child, orchestratorSessionId:parent}));
ck("a COMPLETED run without proven isolation is inadmissible", c2.admissible===false, c2.admissibility_note);
ck("the refusal names measurement independence", /were not independent/.test(c2.admissibility_note));
const d3 = path.join(tmp,"run3"); openRun(d3,{task_id:"E1",arm:"G",expected_session_id:child,orchestrator_session_id:parent});
const c3 = closeRun(d3, classify({streamPath:clean,exitCode:0}),
  verifyIsolation({streamPath:clean, expectedSessionId:child, orchestratorSessionId:parent}));
ck("completed AND isolated is admissible", c3.admissible===true, c3.admissibility_note);

fs.rmSync(tmp,{recursive:true,force:true});
process.stdout.write(o.join("\n")+"\n");
process.stdout.write(`TESTS: ${P} passed, ${F} failed, 0 skipped\n`);
process.exit(F?1:0);
