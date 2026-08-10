// LEAN L1 — the four-step demonstration protocol, mechanised.
//
// Per the operator's implementation discipline, each row must show:
//   (1) the OLD behaviour firing on the OLD code,
//   (2) the SAME scenario with the old behaviour ABSENT on the new code,
//   (3) the PRESERVED control still firing where it should.
//
// The old code is not simulated: it is checked out from git (`OLD_REF`, default
// HEAD) into a temp module dir and executed. A test against a hand-written
// imitation of the old gate would prove nothing about the old gate.

import assert from "node:assert";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execSync, spawnSync } from "node:child_process";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const REPO = path.join(HERE, "../..");
const OLD_REF = process.env.LEAN_L1_OLD_REF || "dfdee0e";
const TMP = fs.mkdtempSync(path.join(os.tmpdir(), "lean-l1-"));

// -- the OLD gate, from git, with its real sibling modules -------------------
const OLD = path.join(TMP, "old-motion");
fs.mkdirSync(OLD, { recursive: true });
for (const f of ["gate-stop", "concession-gate", "capability-map", "continuation", "objective"])
  fs.writeFileSync(path.join(OLD, `${f}.mjs`),
    execSync(`git -C ${JSON.stringify(REPO)} show ${OLD_REF}:build-os/motion/${f}.mjs`, { encoding: "utf8" }));

const NEW = path.join(HERE, "gate-stop.mjs");

function runGate(gatePath, projectDir, transcriptLines) {
  const tp = path.join(projectDir, "transcript.jsonl");
  fs.writeFileSync(tp, transcriptLines.map((l) => JSON.stringify(l)).join("\n") + "\n");
  const r = spawnSync("node", [gatePath], {
    input: JSON.stringify({ transcript_path: tp }),
    env: { ...process.env, CLAUDE_PROJECT_DIR: projectDir },
    encoding: "utf8",
  });
  return { code: r.status, err: r.stderr || "" };
}

const asst = (text) => ({ message: { role: "assistant", content: [{ type: "text", text }] } });
const toolUse = (id, name, input) => ({ message: { role: "assistant", content: [{ type: "tool_use", id, name, input }] } });
const toolErr = (id) => ({ message: { role: "user", content: [{ type: "tool_result", tool_use_id: id, is_error: true, content: "refused" }] } });

const proj = (name, { gitDirty = false } = {}) => {
  const d = path.join(TMP, name);
  fs.mkdirSync(d, { recursive: true });
  if (gitDirty) {
    execSync(`git -C ${JSON.stringify(d)} init -q && echo base > ${JSON.stringify(path.join(d, "f.txt"))}`, { shell: "/bin/bash" });
    execSync(`git -C ${JSON.stringify(d)} -c user.email=t@t -c user.name=t add -A`);
    execSync(`git -C ${JSON.stringify(d)} -c user.email=t@t -c user.name=t commit -qm init`);
    fs.appendFileSync(path.join(d, "f.txt"), "worker edit\n");
  }
  return d;
};

let n = 0;
const t = (name, fn) => { fn(); n++; console.log(`  ok  ${name}`); };
console.log(`lean L1 (old code from ${OLD_REF})`);

// ---------------------------------------------------------------------------
// SCENARIO A — honest completion report with a named limitation.
// This is the measured 2.4-final-reports loop's dominant trigger.
// ---------------------------------------------------------------------------
const A = [asst("T02 is delivered. The fix is complete. I cannot run the verification command — Bash requires an approver not present in this session.")];

t("A/old: the OLD gate refuses a completed delivery and demands worker-authored evidence", () => {
  const r = runGate(path.join(OLD, "gate-stop.mjs"), proj("a-old", { gitDirty: true }), A);
  assert.equal(r.code, 2);
  assert.match(r.err, /CONCESSION BLOCKED/);
  assert.match(r.err, /record exhaustion evidence/i);
});
t("A/new: the NEW gate resolves completion from the work product and allows the stop", () => {
  const r = runGate(NEW, proj("a-new", { gitDirty: true }), A);
  assert.equal(r.code, 0, r.err);
});
t("A/new guard: the same message with NO work product does not ride the completion path", () => {
  const r = runGate(NEW, proj("a-empty"), A);
  assert.equal(r.code, 2);
});

// ---------------------------------------------------------------------------
// SCENARIO B — premature concession: no completion claim, zero executed probes.
// The PRESERVED control: "never stop while unsearched agency remains."
// ---------------------------------------------------------------------------
const B = [asst("I am blocked and cannot proceed. Awaiting your operator call.")];

t("B/old: the OLD gate refuses (control existed before)", () => {
  const r = runGate(path.join(OLD, "gate-stop.mjs"), proj("b-old"), B);
  assert.equal(r.code, 2);
});
t("B/new: the NEW gate STILL refuses — the floor holds", () => {
  const r = runGate(NEW, proj("b-new"), B);
  assert.equal(r.code, 2);
  assert.match(r.err, /concession floor/);
});
t("B/new contract: the refusal is one instruction, not homework", () => {
  const r = runGate(NEW, proj("b-new2"), B);
  assert.doesNotMatch(r.err, /record exhaustion evidence|eight fields|current\.json/i);
  assert.match(r.err, /Next action \(one step\)/);
  assert.match(r.err, /no evidence file is needed from you/);
});

// ---------------------------------------------------------------------------
// SCENARIO C — genuine exhaustion: errored probes in two capability classes.
// Old: still refused (worker wrote no evidence file). New: the driver derives
// the evidence, records it with machine provenance, allows the stop.
// ---------------------------------------------------------------------------
const C = [
  toolUse("u1", "Bash", { command: "npx tsc --noEmit -p tsconfig.json" }), toolErr("u1"),
  toolUse("u2", "Bash", { command: "./node_modules/.bin/tsc --noEmit" }), toolErr("u2"),
  toolUse("u3", "mcp__serena__get_diagnostics_for_file", { file: "x.ts" }), toolErr("u3"),
  asst("I am blocked and cannot proceed. Awaiting your operator call."),
];

t("C/old: the OLD gate refuses even a genuinely exhausted worker without its authored file", () => {
  const r = runGate(path.join(OLD, "gate-stop.mjs"), proj("c-old"), C);
  assert.equal(r.code, 2);
  assert.match(r.err, /CONCESSION BLOCKED/);
});
t("C/new: the NEW gate derives the evidence from the transcript and allows the stop", () => {
  const d = proj("c-new");
  const r = runGate(NEW, d, C);
  assert.equal(r.code, 0, r.err);
  const evd = JSON.parse(fs.readFileSync(path.join(d, "build-os/motion/exhaustion/current.json"), "utf8"));
  assert.equal(evd.authored_by, "runtime");
  assert.equal(evd.verdict, "concession_allowed");
  assert.equal(evd.workaround_classes_considered.length, 2);
  assert.equal(evd.paths_attempted.length, 3);
});
t("C/new mutation: remove one class and the SAME gate refuses again — the floor is load-bearing", () => {
  const oneClass = [C[0], C[1], C[2], C[3], C[6]]; // Bash probes only, no mcp, same concession
  const r = runGate(NEW, proj("c-floor"), oneClass);
  assert.equal(r.code, 2);
  assert.match(r.err, /concession floor/);
});

// ---------------------------------------------------------------------------
// SCENARIO D — continuation preserved byte-for-byte: runnable queue refuses
// the stop on old AND new, concession or none.
// ---------------------------------------------------------------------------
const D = [asst("All done here.")];
const withQueue = (name) => {
  const d = proj(name);
  fs.mkdirSync(path.join(d, "build-os/motion"), { recursive: true });
  fs.writeFileSync(path.join(d, "build-os/motion/queue.json"),
    JSON.stringify({ tasks: [{ id: 7, status: "queued", depends_on: [], subject: "runnable work" }] }));
  return d;
};
t("D/old: continuation refuses a stop while the queue holds runnable work", () => {
  const r = runGate(path.join(OLD, "gate-stop.mjs"), withQueue("d-old"), D);
  assert.equal(r.code, 2);
  assert.match(r.err, /queue still holds runnable work/);
});
t("D/new: identical refusal — the preserved control is untouched", () => {
  const r = runGate(NEW, withQueue("d-new"), D);
  assert.equal(r.code, 2);
  assert.match(r.err, /queue still holds runnable work/);
});

// ---------------------------------------------------------------------------
// SCENARIO E — plain clean stop: no concession, no queue. Allowed by both.
// ---------------------------------------------------------------------------
t("E/both: a clean non-conceding stop passes old and new alike", () => {
  assert.equal(runGate(path.join(OLD, "gate-stop.mjs"), proj("e-old"), [asst("Task finished cleanly.")]).code, 0);
  assert.equal(runGate(NEW, proj("e-new"), [asst("Task finished cleanly.")]).code, 0);
});

fs.rmSync(TMP, { recursive: true, force: true });
console.log(`\n${n} assertions passed`);
