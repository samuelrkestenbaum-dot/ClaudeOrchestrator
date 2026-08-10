// LEAN L4 — the compiled worker contract: certainty added, ceremony scoped away.
//
// Doctrine is text, so these assertions are structural where possible: section
// ORDER (the worker contract precedes and is separate from orchestrator
// protocol), CONTAINMENT (ceremony instructions live only under the
// orchestrator heading), and the certainty statements the TOM's compiled shape
// requires. The B-regression (too little certainty -> compensatory search) is
// NOT unit-testable and is guarded where it belongs: capability_search /
// gravito_search in the decisive test must not exceed the current baseline.

import assert from "node:assert";
import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";

const HERE = path.dirname(new URL(import.meta.url).pathname);
const REPO = path.join(HERE, "../..");
const doctrine = fs.readFileSync(path.join(REPO, "CLAUDE.md"), "utf8");

let n = 0;
const t = (name, fn) => { fn(); n++; console.log(`  ok  ${name}`); };
console.log("lean L4");

const workerIdx = doctrine.indexOf("## Executing a routed task");
const orchIdx = doctrine.indexOf("## Build OS (orchestrator sessions)");

t("the worker contract exists and PRECEDES the orchestrator protocol", () => {
  assert.ok(workerIdx > -1, "worker contract section missing");
  assert.ok(orchIdx > workerIdx, "orchestrator section must follow the worker contract");
});

const workerPart = doctrine.slice(workerIdx, orchIdx);
const orchPart = doctrine.slice(orchIdx);

t("worker contract states routing is automatic and requestless", () => {
  assert.match(workerPart, /Routing is automatic/i);
  assert.match(workerPart, /never write a routing\s*request/i);
  assert.match(workerPart, /never\s+declare a lane/i);
});
t("worker contract resolves the verification-refused case in one sentence", () => {
  assert.match(workerPart, /state that\s+once in your report and finish/i);
});
t("worker contract states the two-route-class floor and no evidence authorship", () => {
  assert.match(workerPart, /two different route classes/i);
  assert.match(workerPart, /never author evidence\s*files/i);
});
t("worker contract keeps the hard mutation gate", () => {
  assert.match(workerPart, /Never push, merge, deploy, publish, or touch secrets\s+without an explicit operator go/i);
});
t("worker contract ADDS certainty — it does not merely subtract text (B's lesson)", () => {
  // The section must be substantive prose, not a stub: every TOM topic present.
  for (const topic of [/Routing/, /Authority/, /Verification/, /Stopping/]) assert.match(workerPart, topic);
  assert.ok(workerPart.length > 900, `worker contract is ${workerPart.length} chars — a stub subtracts, it does not compile`);
});

t("CONTAINMENT: lane/budget ceremony instructions live ONLY under the orchestrator heading", () => {
  for (const re of [/announce the LANE/i, /Declare a Tool Budget/i, /routing receipt \(substantive lane\)/i]) {
    assert.doesNotMatch(workerPart, re, `${re} leaked into the worker contract`);
    // ...and they still exist for orchestrator sessions — scoping, not deletion.
  }
  assert.match(orchPart, /announce the LANE/i);
  assert.match(orchPart, /Declare a Tool Budget/i);
});
t("the orchestrator section explicitly disclaims addressing task workers", () => {
  assert.match(orchPart, /not addressed to routed\s+task workers/i);
});

t("session-start emits the derived task state ahead of orchestrator ceremony", () => {
  const hook = fs.readFileSync(path.join(REPO, ".claude/hooks/session-start-build-os.sh"), "utf8");
  const stateIdx = hook.indexOf("routing is AUTOMATIC");
  const orchHookIdx = hook.indexOf("Orchestrator: ON");
  assert.ok(stateIdx > -1 && orchHookIdx > stateIdx, "derived state must precede the orchestrator banner");
});

t("mutation: the OLD doctrine (dfdee0e) FAILS the containment check — the greps bite", () => {
  const old = execSync(`git -C ${JSON.stringify(REPO)} show dfdee0e:CLAUDE.md`, { encoding: "utf8" });
  // Old doctrine has no worker section at all, and ceremony sits at top level.
  assert.equal(old.indexOf("## Executing a routed task"), -1);
  assert.match(old, /announce the LANE/i);
});

console.log(`\n${n} assertions passed`);
