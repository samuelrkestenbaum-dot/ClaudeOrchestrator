#!/usr/bin/env node
// #55 — mutation-style assertions against the four-branch rule, each anchored
// to a scenario the program actually lived through.
import { assessStop } from "./continuation.mjs";
let n = 0; const ok = (c, m) => { if (!c) { console.error(`FAIL: ${m}`); process.exit(1); } n++; };
const RUNNABLE = { name: "#54 bounded replication", specified: true, authorized: true, runnable: true, deferred: false, positive_value: true };

// 1. The goodnight case: operator's explicit stop is valid EVEN WITH runnable work.
let v = assessStop({ operator_stop: "this is a very good place to stop for tonight", next_task: RUNNABLE });
ok(v.verdict === "STOP" && v.branch === "explicit_operator_stop", "explicit operator stop must win over runnable work");

// 2. The wrong-stop case: runnable work + no stop order => CONTINUE, stop invalid.
v = assessStop({ next_task: RUNNABLE });
ok(v.verdict === "CONTINUE" && v.task === RUNNABLE.name, "runnable+authorized work makes a stop invalid");

// 3. Stop-hook automation is not an operator stop (caller contract: it never sets operator_stop).
v = assessStop({ operator_stop: false, next_task: RUNNABLE });
ok(v.verdict === "CONTINUE", "automation must not masquerade as an operator stop");

// 4. The HOLD defect: a material ambiguity is SURFACED by name, not parked.
v = assessStop({ ambiguities: [{ what: "launch #54 tonight or tomorrow?", material: true }], next_task: RUNNABLE });
ok(v.verdict === "SURFACE" && v.surface[0].includes("#54"), "material ambiguity must be surfaced, not silently held");

// 5. Immaterial ambiguity does not interrupt continuation.
v = assessStop({ ambiguities: [{ what: "wording of the report title", material: false }], next_task: RUNNABLE });
ok(v.verdict === "CONTINUE", "immaterial ambiguity must not stop runnable work");

// 6. A blocker with ONE route class tried is not exhaustion — and it is named, not laundered.
v = assessStop({ blockers: [{ what: "push refused", routes_tried: ["shell"] }] });
ok(v.verdict === "STOP" && /only tried: shell/.test(v.why), "unexhausted blocker must be named as the thing left to try");

// 7. Two distinct route classes => genuinely BLOCKED.
v = assessStop({ blockers: [{ what: "api.openai.com unreachable", routes_tried: ["shell", "mcp"] }] });
ok(v.verdict === "BLOCKED", "two route classes tried => BLOCKED is legitimate");

// 8. Genuine blocker on one task does NOT block a different runnable task.
v = assessStop({ blockers: [{ what: "codex host unreachable", routes_tried: ["shell", "mcp"] }], next_task: RUNNABLE });
ok(v.verdict === "CONTINUE", "a blocker elsewhere must not stop unrelated runnable work");

// 9. Deferred work does not force continuation (#53 stays deferred by operator word).
v = assessStop({ next_task: { ...RUNNABLE, name: "#53", deferred: true } });
ok(v.verdict === "STOP" && v.branch === "no_runnable_work", "operator-deferred work must not trigger CONTINUE");

// 10. Unauthorized work does not force continuation.
v = assessStop({ next_task: { ...RUNNABLE, authorized: false } });
ok(v.verdict === "STOP", "unauthorized work must not trigger CONTINUE");

// 11. Empty state: stopping is legitimate and says why.
v = assessStop({});
ok(v.verdict === "STOP" && v.branch === "no_runnable_work", "empty state stops legitimately");

console.log(`${n} assertions passed`);
