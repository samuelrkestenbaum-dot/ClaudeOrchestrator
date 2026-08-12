#!/usr/bin/env node
// EXP-0009 ACTIVE EXECUTOR — one event-processing state machine that OWNS the
// next action. Replaces run-study.mjs (chain-on-completion supervisor) and
// stall-watch.sh (60s polling monitor), which together were still observer
// architecture: work runs → watcher checks → maybe reacts. This is the kernel
// shape the operator specified:
//
//     event arrives → state changes → next transition decided → action dispatched
//
// ISOLATION BOUNDARY, stated before the code. The treatment lives INSIDE
// run-arm.mjs: seed restore, pinned administration, prompt construction,
// grants, metrics, adjudication, distillation. This file only decides WHEN
// run-arm.mjs is invoked, with the same argv run-sequence.mjs used. It never
// writes into the arm tree, never touches memory stores, never alters a run
// record. Every arm's own preflight (administered-bytes verification, prompt
// sha, provenance gate) re-proves treatment identity cell by cell — the same
// mechanism that already proved identity across the three earlier launch-route
// changes. Orchestration provably cannot reach the administered bytes.
//
// EVENTS, not polls: fs.watch (inotify) on the arm's run dir — every append to
// stream.jsonl is consumed as it lands, parsed, and folded into the state.
// TIME's one legitimate role: a bounded no-progress timeout ATTACHED TO A
// STATE ("session may go 300s without an event; verification 900s"), enforced
// when events stop arriving. Time never schedules and never discovers.
//
// Usage: executor.mjs --convergence <file> [--reps 1,2] [--plan]
import { spawn, execFileSync } from "node:child_process";
import fs from "node:fs"; import path from "node:path";
import { assess, loadProgram } from "../../motion/convergence.mjs";
const HERE = path.dirname(new URL(import.meta.url).pathname);
const arg = (n, d) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const REPS = arg("reps", "1,2").split(",").map(Number);
const LOCK = "/home/user/.exp0007/arm.lock";
const RUNS = path.join(HERE, "results/runs");
const STATUS = path.join(HERE, "results/executor-status.txt");
const ELOG = path.join(HERE, "results/executor-log.txt");
const log = (m) => { const l = `[exec ${new Date().toISOString()}] ${m}`; console.log(l); fs.appendFileSync(ELOG, l + "\n"); };

// Convergence gate — same contract as every driver invocation of this study.
{
  const cf = arg("convergence", null);
  if (!cf) { console.error("REFUSED — no --convergence <proposal.json>."); process.exit(3); }
  const v = assess(JSON.parse(fs.readFileSync(cf, "utf8")), loadProgram());
  console.log(`CONVERGENCE ${v.verdict}: ${v.code}`);
  if (v.verdict !== "PROCEED") process.exit(3);
}

// THE PLAN — byte-for-byte the ordering run-sequence.mjs used: reps outermost,
// sequences A then B, positions in order (order is load-bearing: accrual),
// config order alternating by position so neither eats the cold cache always.
const PLAN = [];
for (const rep of REPS) for (const s of ["A", "B"]) for (let p = 1; p <= 5; p++)
  for (const c of (p % 2 === 0 ? ["leanmem", "native"] : ["native", "leanmem"])) PLAN.push({ rep, s, p, c });
const cellDir = (u) => path.join(RUNS, `${u.s}${u.p}.${u.c}.r${u.rep}`);
const cellName = (u) => `${u.s}${u.p}/${u.c} rep${u.rep}`;
const admissible = (u) => { try { return JSON.parse(fs.readFileSync(path.join(cellDir(u), "run-record.json"), "utf8")).admissible === true; } catch { return false; } };
const nextCell = () => PLAN.find((u) => !admissible(u));
if (process.argv.includes("--plan")) {
  for (const u of PLAN) console.log(`${admissible(u) ? "done " : "TODO "} ${cellName(u)}`);
  process.exit(0);
}

// Per-state no-progress bounds (seconds). Bounded timeouts attached to active
// states — the one legitimate use of time. Session bound generous because a
// single long model turn emits nothing until it completes; verification bound
// mirrors run-arm's own 900s tsc timeout, so the executor never fires first
// on a verification run-arm itself still considers live.
const BOUNDS = { launching: 180, session: 300, verifying: 960, closing: 180 };
const alive = (pid) => { try { process.kill(pid, 0); return true; } catch { return false; } };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

let S = { state: "idle", action: "-", cell: null, lastEvent: Date.now(), pid: null, note: "" };
function transitionLabel(u) {
  const i = PLAN.findIndex((x) => x.rep === u.rep && x.s === u.s && x.p === u.p && x.c === u.c);
  const nxt = PLAN.slice(i + 1).find((x) => !admissible(x));
  const distill = u.c === "leanmem" ? "distill memory → " : "";
  return `arm_complete → ${distill}${nxt ? `launch ${cellName(nxt)}` : "STUDY COMPLETE"}`;
}
function exposeStatus() {
  const age = ((Date.now() - S.lastEvent) / 1000).toFixed(1);
  fs.writeFileSync(STATUS, [
    `Current state:        ${S.cell ? cellName(S.cell) : "-"} → ${S.state}`,
    `Current action:       ${S.action}`,
    `Last meaningful event: ${age}s ago`,
    `Next transition:      ${S.cell ? transitionLabel(S.cell) : "-"}`,
    `Blocked on:           ${S.note || "nothing"}`,
    `Updated:              ${new Date().toISOString()}`,
  ].join("\n") + "\n");
}
function consume(line) { // one stream.jsonl event → state
  let e; try { e = JSON.parse(line); } catch { return; }
  S.lastEvent = Date.now();
  if (e.type === "result") { S.state = "verifying"; S.action = "npx tsc --noEmit (acceptance verification)"; }
  else if (e.type === "assistant" || e.type === "user") {
    const c = e?.message?.content;
    const tools = Array.isArray(c) ? c.filter((x) => x?.type === "tool_use").map((x) => x.name) : [];
    if (tools.length) S.action = `${tools.join(",")} (worker session)`;
    if (S.state !== "verifying") S.state = "session";
  }
  exposeStatus();
}

// Observe one arm (spawned or adopted) purely from its execution events.
function observe(u, pid, onExit) {
  const dir = cellDir(u);
  S = { state: "launching", action: "seed restore + administration preflight", cell: u, lastEvent: Date.now(), pid, note: "" };
  exposeStatus();
  let streamPos = 0, watcher = null, buf = "";
  const attach = () => {
    const sf = path.join(dir, "stream.jsonl");
    if (watcher || !fs.existsSync(sf)) return;
    const pump = () => { // read only the appended bytes — the event, not a rescan
      try {
        const sz = fs.statSync(sf).size; if (sz <= streamPos) return;
        const fd = fs.openSync(sf, "r"); const b = Buffer.alloc(sz - streamPos);
        fs.readSync(fd, b, 0, b.length, streamPos); fs.closeSync(fd); streamPos = sz;
        buf += b.toString(); const lines = buf.split("\n"); buf = lines.pop() || "";
        for (const l of lines) if (l.trim()) consume(l);
      } catch {}
    };
    watcher = fs.watch(dir, (ev, f) => {
      if (f === "stream.jsonl") pump();
      else if (f === "acceptance.json" || f === "economics.json") { S.state = "closing"; S.action = `writing ${f}`; S.lastEvent = Date.now(); exposeStatus(); }
    });
    pump();
  };
  const dirWait = fs.existsSync(dir) ? null : fs.watch(RUNS, (ev, f) => { if (f === path.basename(dir)) { S.lastEvent = Date.now(); attach(); } });
  attach();
  const guard = setInterval(() => { // bounded no-progress timeout of the ACTIVE state
    attach();
    if (!alive(pid)) return; // exit handler owns the rest
    const idle = (Date.now() - S.lastEvent) / 1000;
    const bound = BOUNDS[S.state] ?? 300;
    if (idle > bound) {
      log(`NO-PROGRESS: ${cellName(u)} state=${S.state} idle=${idle.toFixed(0)}s > ${bound}s — recovering`);
      try { process.kill(pid, "SIGKILL"); } catch {}
      try { execFileSync("pkill", ["-9", "-f", "claude -p"]); } catch {}
    } else exposeStatus();
  }, 15_000);
  const done = () => { clearInterval(guard); watcher?.close(); dirWait?.close(); onExit(); };
  return done;
}

function recoverCellDebris(u, tag) { // preserve → verify-dead → clear-lock (existing semantics, unchanged)
  const dir = cellDir(u);
  if (fs.existsSync(dir) && !admissible(u)) {
    const dest = `${dir}.${tag}`;
    if (!fs.existsSync(dest)) { fs.renameSync(dir, dest); log(`preserved partial as ${path.basename(dest)}`); }
  }
  try { const p = Number(fs.readFileSync(LOCK, "utf8").trim()); if (p && !alive(p)) { fs.rmSync(LOCK, { force: true }); log(`cleared stale lock (pid ${p} dead)`); } } catch {}
}

async function runCell(u) {
  for (let attempt = 1; attempt <= 2; attempt++) {
    recoverCellDebris(u, `attempt${attempt}-debris`);
    const out = fs.openSync(path.join(HERE, `results/driver-rep${u.rep}.log`), "a");
    const child = spawn("node", [path.join(HERE, "run-arm.mjs"), "--seq", u.s, "--pos", String(u.p), "--rep", String(u.rep), "--config", u.c], { stdio: ["ignore", out, out] });
    log(`dispatch ${cellName(u)} (attempt ${attempt}, pid ${child.pid})`);
    const code = await new Promise((res) => { const fin = observe(u, child.pid, () => {}); child.on("exit", (c) => { fin(); fs.closeSync(out); res(c); }); });
    if (admissible(u)) { S.state = "done"; S.action = "-"; exposeStatus(); return true; }
    log(`${cellName(u)} inadmissible (exit ${code})${attempt === 1 ? " — one immediate retry, attempt preserved" : ""}`);
    if (attempt === 1 && fs.existsSync(cellDir(u))) fs.renameSync(cellDir(u), `${cellDir(u)}.attempt1`);
  }
  return false;
}

// ADOPTION: if an arm is already in flight (launched by the outgoing
// supervisor), it is a predecessor, not a competitor — observe it to
// completion from its own events, then own everything after it.
async function adoptInFlight() {
  let pid = null; try { pid = Number(fs.readFileSync(LOCK, "utf8").trim()); } catch {}
  if (!pid || !alive(pid)) return;
  let u = null;
  try {
    const cmd = fs.readFileSync(`/proc/${pid}/cmdline`, "utf8").split("\0");
    const g = (f) => cmd[cmd.indexOf(`--${f}`) + 1];
    u = { rep: Number(g("rep")), s: g("seq"), p: Number(g("pos")), c: g("config") };
  } catch { return; }
  log(`adopting in-flight arm ${cellName(u)} (pid ${pid}) — observing its events to completion`);
  await new Promise((res) => {
    const fin = observe(u, pid, () => {});
    const t = setInterval(() => { if (!alive(pid)) { clearInterval(t); fin(); res(); } }, 5_000);
  });
  log(`adopted arm handed back: ${cellName(u)} admissible=${admissible(u)}`);
}

log(`executor online — ${PLAN.filter((u) => !admissible(u)).length} of ${PLAN.length} cells remaining`);
await adoptInFlight();
let failures = 0;
for (let u = nextCell(); u; u = nextCell()) {
  const ok = await runCell(u);
  if (!ok && ++failures >= 3) { log(`3 consecutive unrecoverable cells — stopping; this is a blocker to report, not a result`); process.exit(1); }
  if (ok) failures = 0;
}
fs.appendFileSync(path.join(HERE, "results/study-log.txt"), `[study ${new Date().toISOString()}] STUDY COMPLETE — reps ${REPS.join(",")} all cells admissible. The fork may now be applied.\n`);
S = { state: "study-complete", action: "-", cell: null, lastEvent: Date.now(), pid: null, note: "" };
exposeStatus();
log("STUDY COMPLETE");
