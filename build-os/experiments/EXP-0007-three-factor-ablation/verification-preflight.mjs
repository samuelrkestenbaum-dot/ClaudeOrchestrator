#!/usr/bin/env node
// PREFLIGHT for the runnable-verification study.
//
// Six conditions, every one decided from an EXECUTED stream rather than from
// configuration. "The flag was passed" and "the compiler ran" are different
// claims, and this experiment exists precisely because the second one was false
// while everything upstream looked correct.
//
// Usage: verification-preflight.mjs [--task T03]
// Reads four run directories -- {native,corrected} x {starved,runnable} -- for
// the named task and refuses with a non-zero exit if any condition fails.

import fs from "node:fs";
import path from "node:path";

const arg = (n, d) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const TASK = arg("task", "T03");
const RUNS = path.join(path.dirname(new URL(import.meta.url).pathname), "results/runs");

const CELLS = {
  native_starved:    `${TASK}.native`,
  native_runnable:   `${TASK}.native.runnable`,
  gravito_starved:   `${TASK}.corrected`,
  gravito_runnable:  `${TASK}.corrected.runnable`,
};

function load(dir) {
  const p = path.join(RUNS, dir, "stream.jsonl");
  if (!fs.existsSync(p)) return null;
  const ev = fs.readFileSync(p, "utf8").split("\n").filter(Boolean)
    .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
  const uses = {};
  for (const e of ev) for (const c of (e?.message?.content || [])) if (c.type === "tool_use") uses[c.id] = c;
  const calls = [];
  for (const e of ev) for (const c of (e?.message?.content || [])) {
    if (c.type !== "tool_result") continue;
    const u = uses[c.tool_use_id];
    if (!u) continue;
    calls.push({ name: u.name, input: u.input || {},
                 body: typeof c.content === "string" ? c.content : JSON.stringify(c.content || ""),
                 isError: c.is_error === true });
  }
  const texts = [];
  for (const e of ev) {
    const c = e?.message?.content;
    if (!Array.isArray(c) || e.message.role !== "assistant" || c.some((x) => x.type === "tool_use")) continue;
    const t = c.filter((x) => x.type === "text").map((x) => x.text).join("\n").trim();
    if (t) texts.push(t);
  }
  let variant = null;
  try { variant = JSON.parse(fs.readFileSync(path.join(RUNS, dir, "variant.json"), "utf8")); } catch {}
  return { dir, calls, texts, variant };
}

// A Bash call is a VERIFICATION ATTEMPT if its command names the typechecker.
const isVerify = (c) => c.name === "Bash" && /\btsc\b/.test(String(c.input.command || ""));
// It EXECUTED if the result carries compiler output rather than a permission
// refusal. Both a clean run (empty/no errors) and a run reporting `error TSxxxx`
// prove execution; only the permission layer's refusal proves it did not.
const REFUSAL = /requires approval|permission|not allowed|denied|approver|PreToolUse|PostToolUse/i;
const COMPILER_OUTPUT = /error TS\d+|\berror TS|Found \d+ error|Version \d+\.\d+|tsconfig|\bTS\d{4}\b/;

const results = [];
const ck = (name, ok, detail) => { results.push({ name, ok, detail }); };

const cells = Object.fromEntries(Object.entries(CELLS).map(([k, d]) => [k, load(d)]));
const missing = Object.entries(cells).filter(([, v]) => !v).map(([k]) => `${k} (${CELLS[k]})`);
if (missing.length) {
  console.error(`REFUSED — missing run directories: ${missing.join(", ")}`);
  console.error("Run all four cells for this task before preflight can decide anything.");
  process.exit(2);
}

// 1 & 2 — each arm can INVOKE the verification command under `runnable`.
for (const [k, label] of [["native_runnable", "native"], ["gravito_runnable", "Gravito"]]) {
  const att = cells[k].calls.filter(isVerify);
  ck(`${k}.invoked`, att.length > 0,
    att.length ? `${label} issued ${att.length} verification call(s): ${JSON.stringify(att[0].input.command).slice(0, 90)}`
               : `${label} never issued a call naming tsc — the grant cannot be shown to matter`);
}

// 3 — the command ACTUALLY EXECUTED, not merely received approval.
for (const k of ["native_runnable", "gravito_runnable"]) {
  const att = cells[k].calls.filter(isVerify);
  const ran = att.filter((c) => !c.isError && !REFUSAL.test(c.body) && COMPILER_OUTPUT.test(c.body));
  const refused = att.filter((c) => c.isError || REFUSAL.test(c.body));
  ck(`${k}.executed`, ran.length > 0,
    ran.length ? `compiler output returned to the worker (${ran.length} of ${att.length} call(s) executed; ${refused.length} refused)`
               : `NO call returned compiler output — ${refused.length}/${att.length} were refusals. Approval is not execution.`);
}

// 4 — the worker CONSUMED the result: it must reference the compiler outcome in
// its own prose, not merely have received bytes it ignored.
for (const k of ["native_runnable", "gravito_runnable"]) {
  const said = cells[k].texts.some((t) => /\b(zero|no|0)\b[^.]{0,30}\berrors?\b|error TS\d+|compil|typecheck (passed|clean|reports)|tsc (reports|returned|exited)/i.test(t));
  ck(`${k}.consumed`, said, said ? "the worker states the compiler outcome in its own report"
                                  : "no worker text references the compiler outcome — the result may have been ignored");
}

// 5 — NO HIDDEN HOST PRIVILEGE DIFFERS BETWEEN ARMS. The grant recorded in each
// run record must be byte-identical across the two runnable arms, and empty in
// both starved arms. This is why the grant is written into variant.json.
const gN = JSON.stringify(cells.native_runnable.variant?.allowed_tools ?? null);
const gG = JSON.stringify(cells.gravito_runnable.variant?.allowed_tools ?? null);
ck("identical_grant_across_arms", gN === gG && gN !== "null" && gN !== "[]",
  gN === gG ? `both runnable arms carry the same grant: ${gN}` : `GRANTS DIFFER — native ${gN} vs gravito ${gG}`);
const sN = JSON.stringify(cells.native_starved.variant?.allowed_tools ?? []);
const sG = JSON.stringify(cells.gravito_starved.variant?.allowed_tools ?? []);
ck("starved_arms_carry_no_grant", (sN === "[]" || sN === "null") && (sG === "[]" || sG === "null"),
  `starved grants: native ${sN}, gravito ${sG}`);
const pm = ["native_starved", "native_runnable", "gravito_starved", "gravito_runnable"]
  .map((k) => cells[k].variant?.permission_mode ?? "unrecorded");
ck("permission_mode_unchanged", new Set(pm).size === 1,
  `permission_mode across all four cells: ${[...new Set(pm)].join(", ")}`);

// 6 — concession exhaustion is not triggered SIMPLY because verification is
// unavailable. Decided as a CONTRAST: the starved gravito arm should show the
// exhaustion loop and the runnable one should not. A runnable arm still looping
// would mean the gate fires for some other reason and the study cannot isolate
// the interaction it was built to isolate.
const EXHAUST = /exhaust|concession|cross-surface|untested surface|unsearched|capability (map|registry)|gate-stop/i;
const exStarved = cells.gravito_starved.texts.filter((t) => EXHAUST.test(t)).length;
const exRunnable = cells.gravito_runnable.texts.filter((t) => EXHAUST.test(t)).length;
ck("exhaustion_is_starvation_driven", exRunnable < exStarved,
  `gravito exhaustion references — starved ${exStarved}, runnable ${exRunnable}` +
  (exRunnable < exStarved ? "" : "  <-- the gate fires even with verification available; the contrast is not clean"));

// The negative control: the switch must actually change something. If starved
// and runnable behave identically the flag is decorative.
const vStarved = cells.gravito_starved.calls.filter(isVerify).filter((c) => !c.isError && COMPILER_OUTPUT.test(c.body)).length;
ck("switch_has_an_effect", vStarved === 0,
  vStarved === 0 ? "the starved arm executed the verification command ZERO times, as the historical record says"
                 : `the starved arm executed it ${vStarved} time(s) — the starvation premise is wrong`);

const ok = results.every((r) => r.ok);
console.log(`VERIFICATION PREFLIGHT — task ${TASK}`);
for (const r of results) console.log(`  ${r.ok ? "ok  " : "FAIL"} ${r.name}: ${r.detail}`);
console.log(ok ? "\nPREFLIGHT PASSED — the runnable condition is real and isolated."
               : "\nPREFLIGHT FAILED — refusing to run the study on an unproven environment.");
fs.writeFileSync(path.join(path.dirname(RUNS), "verification-preflight.json"),
  JSON.stringify({ artifact: "verification_preflight", task: TASK, cells: CELLS, ok, checks: results }, null, 2));
process.exit(ok ? 0 : 1);
