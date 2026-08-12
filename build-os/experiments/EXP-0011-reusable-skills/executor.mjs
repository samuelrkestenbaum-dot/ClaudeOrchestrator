#!/usr/bin/env node
// EXP-0011 ACTIVE EXECUTOR — three-way plan, config order rotated per position.
// plan: one treatment (leanrules), 2 sequences x 5 ordered positions x 2 reps,
// no native cells (the comparator is EXP-0009's frozen native arms). Same
// contract: events drive work, per-event state, bounded per-state no-progress
// timeouts, event-driven recovery, no watchers layered on top.
//
// Usage: executor.mjs --convergence skills.convergence.json [--reps 1,2] [--plan]
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
fs.mkdirSync(RUNS, { recursive: true });
const log = (m) => { const l = `[exec ${new Date().toISOString()}] ${m}`; console.log(l); fs.appendFileSync(ELOG, l + "\n"); };

{
  const cf = arg("convergence", null);
  if (!cf) { console.error("REFUSED — no --convergence <proposal.json>."); process.exit(3); }
  const v = assess(JSON.parse(fs.readFileSync(cf, "utf8")), loadProgram());
  console.log(`CONVERGENCE ${v.verdict}: ${v.code}`);
  for (const r of v.reasons) console.log(`  · ${r}`);
  if (v.verdict !== "PROCEED") { console.error("Not running."); process.exit(3); }
}

const CONFIGS = ["native", "leanrules", "leanskills"];
const PLAN = [];
for (const rep of REPS) for (const s of ["G", "M"]) for (let p = 1; p <= 5; p++) {
  const rot = (p - 1) % 3; // rotate so no config always eats the cold cache
  for (let k = 0; k < 3; k++) PLAN.push({ rep, s, p, c: CONFIGS[(rot + k) % 3] });
}
const cellDir = (u) => path.join(RUNS, `${u.s}${u.p}.${u.c}.r${u.rep}`);
const cellName = (u) => `${u.s}${u.p}/${u.c} rep${u.rep}`;
const admissible = (u) => { try { return JSON.parse(fs.readFileSync(path.join(cellDir(u), "run-record.json"), "utf8")).admissible === true; } catch { return false; } };
const nextCell = () => PLAN.find((u) => !admissible(u));
if (process.argv.includes("--plan")) {
  for (const u of PLAN) console.log(`${admissible(u) ? "done " : "TODO "} ${cellName(u)}`);
  process.exit(0);
}

const BOUNDS = { launching: 180, session: 300, verifying: 960, closing: 180 };
const alive = (pid) => { try { process.kill(pid, 0); return true; } catch { return false; } };

let S = { state: "idle", action: "-", cell: null, lastEvent: Date.now(), pid: null, note: "" };
function transitionLabel(u) {
  const i = PLAN.findIndex((x) => x.rep === u.rep && x.s === u.s && x.p === u.p && x.c === u.c);
  const nxt = PLAN.slice(i + 1).find((x) => !admissible(x));
  return `arm_complete → ${nxt ? `launch ${cellName(nxt)}` : "STUDY COMPLETE"}`;
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
function consume(line) {
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
function observe(u, pid) {
  const dir = cellDir(u);
  S = { state: "launching", action: "seed restore + administration + rule selection preflight", cell: u, lastEvent: Date.now(), pid, note: "" };
  exposeStatus();
  let streamPos = 0, watcher = null, buf = "";
  const attach = () => {
    const sf = path.join(dir, "stream.jsonl");
    if (watcher || !fs.existsSync(sf)) return;
    const pump = () => {
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
  const guard = setInterval(() => {
    attach();
    if (!alive(pid)) return;
    const idle = (Date.now() - S.lastEvent) / 1000;
    const bound = BOUNDS[S.state] ?? 300;
    if (idle > bound) {
      log(`NO-PROGRESS: ${cellName(u)} state=${S.state} idle=${idle.toFixed(0)}s > ${bound}s — recovering`);
      try { process.kill(pid, "SIGKILL"); } catch {}
      try { execFileSync("pkill", ["-9", "-f", "claude -p"]); } catch {}
    } else exposeStatus();
  }, 15_000);
  return () => { clearInterval(guard); watcher?.close(); dirWait?.close(); };
}
function recoverCellDebris(u, tag) {
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
    const code = await new Promise((res) => { const fin = observe(u, child.pid); child.on("exit", (c) => { fin(); fs.closeSync(out); res(c); }); });
    if (admissible(u)) { S.state = "done"; S.action = "-"; exposeStatus(); return true; }
    log(`${cellName(u)} inadmissible (exit ${code})${attempt === 1 ? " — one immediate retry, attempt preserved" : ""}`);
    if (attempt === 1 && fs.existsSync(cellDir(u))) fs.renameSync(cellDir(u), `${cellDir(u)}.attempt1`);
  }
  return false;
}

log(`executor online — ${PLAN.filter((u) => !admissible(u)).length} of ${PLAN.length} cells remaining`);
let failures = 0;
for (let u = nextCell(); u; u = nextCell()) {
  const ok = await runCell(u);
  if (!ok && ++failures >= 3) { log(`3 consecutive unrecoverable cells — stopping; this is a blocker to report, not a result`); process.exit(1); }
  if (ok) failures = 0;
}
S = { state: "study-complete", action: "-", cell: null, lastEvent: Date.now(), pid: null, note: "" };
exposeStatus();
log("STUDY COMPLETE — all leanrules cells admissible; the fork may now be applied against the frozen native comparator");
