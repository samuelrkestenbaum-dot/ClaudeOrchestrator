// LEAN L3 — refusals carry resolved state, never homework.
//
// Two halves, both mutation-tested:
//   1. capability-map: an unregistered capability is SAID to be unregistered —
//      never silently enumerated as something else. (The call-site
//      `|| "operator_lab_write"` default died in L1; this proves the remaining
//      behaviour is self-describing, and that registered capabilities are
//      untouched.)
//   2. THE MESSAGE CONTRACT, enforced against EMITTED messages, not sources:
//      every refusal a worker can see must state a next action, must say what
//      the substrate already did, and must never instruct the worker to read
//      gate internals (schemas, REQUIRED_EVIDENCE, field counts).

import assert from "node:assert";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { enumerateCapability } from "./capability-map.mjs";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const REPO = path.join(HERE, "../..");
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), "lean-l3-"));

let n = 0;
const t = (name, fn) => { fn(); n++; console.log(`  ok  ${name}`); };
console.log("lean L3");

// ---- 1. capability map ----------------------------------------------------
t("unregistered capability says so, and offers no route", () => {
  const r = enumerateCapability("task_execution", "claude");
  assert.equal(r.registered, false);
  assert.match(r.note, /no registered holder for 'task_execution'/);
  assert.match(r.note, /never a route/);
  assert.deepEqual(r.surfaces_with_capability, []);
});
t("mutation: a REGISTERED capability still enumerates exactly as before", () => {
  const r = enumerateCapability("operator_lab_write", "claude");
  assert.equal(r.registered, true);
  assert.deepEqual(r.surfaces_with_capability, ["chatgpt"]);
  assert.equal(r.proven_bridges.length, 1);
  assert.match(r.note, /route through a holder/);
});

// ---- 2. the message contract, on EMITTED messages -------------------------
// Collect every worker-visible refusal the lean gates can emit.
const messages = [];

// 2a. gate-stop floor refusal (concession, zero probes)
{
  const tp = path.join(TMP, "t1.jsonl");
  fs.writeFileSync(tp, JSON.stringify({ message: { role: "assistant", content: [{ type: "text", text: "I am blocked and cannot proceed." }] } }) + "\n");
  const proj = path.join(TMP, "p1"); fs.mkdirSync(proj, { recursive: true });
  const r = spawnSync("node", [path.join(HERE, "gate-stop.mjs")], {
    input: JSON.stringify({ transcript_path: tp }),
    env: { ...process.env, CLAUDE_PROJECT_DIR: proj }, encoding: "utf8",
  });
  assert.equal(r.status, 2);
  messages.push(["gate-stop floor refusal", r.stderr]);
}

// 2b. routing-gate bare-tree BLOCK (the preserved fallback path)
{
  const proj = path.join(TMP, "p2"); fs.mkdirSync(path.join(proj, "build-os/packets/routing"), { recursive: true });
  const r = spawnSync(path.join(REPO, ".claude/hooks/routing-gate.sh"), ["mutgate"], {
    input: JSON.stringify({ tool_name: "Edit", tool_input: { file_path: "/x/app.ts", old_string: "a", new_string: "b" } }),
    env: { ...process.env, CLAUDE_PROJECT_DIR: proj }, encoding: "utf8",
  });
  assert.equal(r.status, 2);
  messages.push(["routing-gate fallback BLOCK", r.stderr]);
}

// The contract itself.
const FORBIDDEN = [
  /REQUIRED_EVIDENCE/, /eight fields/i, /all 8 fields/i,
  /see build-os\/motion\/concession-gate\.mjs/i,
  /record exhaustion evidence/i,
];
const NEXT_ACTION = /Next action|RECOVERY A|then retry|then stop again/;
const SUBSTRATE_DID = /What the (substrate|runtime) already did/;

for (const [name, msg] of messages) {
  t(`${name}: names a single next action`, () => assert.match(msg, NEXT_ACTION, msg));
  t(`${name}: states what the substrate already did`, () => assert.match(msg, SUBSTRATE_DID, msg));
  t(`${name}: never sends the worker into gate internals`, () => {
    for (const re of FORBIDDEN) assert.doesNotMatch(msg, re, `${re} found in: ${msg}`);
  });
}

// Mutation for the contract: the OLD gate-stop's message (from git) FAILS it —
// proving the greps actually detect homework rather than passing everything.
{
  const old = spawnSync("git", ["-C", REPO, "show", "dfdee0e:build-os/motion/gate-stop.mjs"], { encoding: "utf8" }).stdout;
  const dir = path.join(TMP, "old-motion"); fs.mkdirSync(dir, { recursive: true });
  for (const f of ["concession-gate", "capability-map", "continuation", "objective"])
    fs.writeFileSync(path.join(dir, `${f}.mjs`),
      spawnSync("git", ["-C", REPO, "show", `dfdee0e:build-os/motion/${f}.mjs`], { encoding: "utf8" }).stdout);
  fs.writeFileSync(path.join(dir, "gate-stop.mjs"), old);
  const tp = path.join(TMP, "t2.jsonl");
  fs.writeFileSync(tp, JSON.stringify({ message: { role: "assistant", content: [{ type: "text", text: "I am blocked and cannot proceed." }] } }) + "\n");
  const proj = path.join(TMP, "p3"); fs.mkdirSync(proj, { recursive: true });
  const r = spawnSync("node", [path.join(dir, "gate-stop.mjs")], {
    input: JSON.stringify({ transcript_path: tp }),
    env: { ...process.env, CLAUDE_PROJECT_DIR: proj }, encoding: "utf8",
  });
  t("mutation: the OLD refusal message FAILS the contract (the greps bite)", () => {
    assert.equal(r.status, 2);
    assert.ok(FORBIDDEN.some((re) => re.test(r.stderr)), "old message unexpectedly clean");
  });
}

fs.rmSync(TMP, { recursive: true, force: true });
console.log(`\n${n} assertions passed`);
