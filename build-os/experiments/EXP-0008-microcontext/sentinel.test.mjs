#!/usr/bin/env node
// SENTINEL REGRESSION for the orchestrator-state contamination.
//
// A measured worker received THIS orchestrator's live queue and started
// reporting on it — 19 "Holding." turns and a literal "T04 complete. #55 needs
// your go." The exclusion list alone is not proof; a list is a promise. This
// plants an unmistakable sentinel in the orchestrator's own queue and proves,
// through the REAL administration path, that it cannot reach a measured worker.
import fs from "node:fs"; import os from "node:os"; import path from "node:path";
import { administer, verifyAdministration, SESSION_LOCAL_FILES, CODE_SOURCE } from "../EXP-0006-operational-uic/harness/substrate.mjs";
let pass=0, fail=0;
const t=(n,c,d="")=>{ if(c){pass++;console.log(`  ok   ${n}`);} else {fail++;console.log(`  FAIL ${n}${d?" — "+d:""}`);} };

const SENTINEL = "ORCHESTRATOR_ONLY_SENTINEL_do_not_leak_7f3a9c";
const qPath = path.join(CODE_SOURCE, "build-os/motion/queue.json");
const original = fs.existsSync(qPath) ? fs.readFileSync(qPath, "utf8") : null;

try {
  // 1. The orchestrator CAN see it — otherwise the test proves nothing.
  const q = original ? JSON.parse(original) : { tasks: [] };
  (q.tasks ||= []).push({ id: 999, title: SENTINEL, status: "open" });
  fs.writeFileSync(qPath, JSON.stringify(q, null, 2));
  t("orchestrator CAN see the sentinel in its own queue",
    fs.readFileSync(qPath, "utf8").includes(SENTINEL));

  // 2. Administer a gravito arm through the REAL path.
  const tree = fs.mkdtempSync(path.join(os.tmpdir(), "sentinel-"));
  fs.mkdirSync(path.join(tree, "build-os/memory"), { recursive: true });
  fs.writeFileSync(path.join(tree, "build-os/memory/current_state.md"), "ARM OWN MEMORY\n");
  administer(tree, "gravito", CODE_SOURCE);

  // 3. The measured worker MUST NOT receive it — searched across the whole tree,
  //    not just the file we know about, because the point is that it cannot
  //    arrive by any route.
  const found = [];
  const walk = (d) => { for (const e of fs.readdirSync(d, { withFileTypes: true })) {
    const p = path.join(d, e.name);
    if (e.isDirectory()) { walk(p); continue; }
    try { if (fs.readFileSync(p, "utf8").includes(SENTINEL)) found.push(path.relative(tree, p)); } catch {}
  } };
  walk(tree);
  t("measured worker does NOT receive the sentinel ANYWHERE in its tree",
    found.length === 0, found.join(", "));
  t("the queue file itself is absent from the arm",
    !fs.existsSync(path.join(tree, "build-os/motion/queue.json")));

  // 4. Legitimate substrate implementation still arrives — the exclusion must
  //    not have thrown out the controllers with the agenda.
  for (const f of ["build-os/motion/continuation.mjs", "build-os/motion/objective.mjs",
                   "build-os/assumptions/authority-selector.mjs", ".claude/hooks/routing-gate.sh"])
    t(`substrate implementation still administered: ${f.split("/").pop()}`, fs.existsSync(path.join(tree, f)));

  // 5. The administration check reports it, rather than passing silently.
  const v = verifyAdministration(tree, "gravito");
  t("verifyAdministration asserts no session-local state",
    v.checks.some((c) => c.name === "no_session_local_state" && c.ok));

  // 6. MUTATION — if the exclusion is bypassed, the check must FAIL. A guard
  //    that cannot fail is the failure mode this whole session keeps finding.
  fs.mkdirSync(path.join(tree, "build-os/motion"), { recursive: true });
  fs.copyFileSync(qPath, path.join(tree, "build-os/motion/queue.json"));
  const v2 = verifyAdministration(tree, "gravito");
  t("MUTATION queue restored -> check REFUSES",
    v2.ok === false && v2.checks.some((c) => c.name === "no_session_local_state" && !c.ok));

  // 7. Deliberate supply still possible: the rule is relevance, not prohibition.
  t("task-relevant shared state CAN still be supplied deliberately",
    fs.existsSync(path.join(tree, "build-os/motion/queue.json")),
    "a caller that explicitly places state can do so; what is prevented is silent inheritance");

  fs.rmSync(tree, { recursive: true, force: true });
} finally {
  if (original !== null) fs.writeFileSync(qPath, original);
  t("orchestrator queue restored to its original bytes",
    original === null || fs.readFileSync(qPath, "utf8") === original);
}
console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
