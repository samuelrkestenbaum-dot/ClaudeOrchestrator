#!/usr/bin/env node
// Stop-event adapter: decide whether this turn may end.
//
// Exit 0 = allow the stop. Exit 2 = REFUSE, with stderr shown to the model.
// It shares ONE ruleset with the audit path (concession-gate.mjs); there is no
// second copy of the stopping rule that could drift from the first.
import fs from "node:fs";
import { isConcession } from "./concession-gate.mjs";
import { enumerateCapability } from "./capability-map.mjs";
import { continuationDecision, TERMINAL_CONDITIONS as TERMINAL } from "./continuation.mjs";

let ev = {};
try { ev = JSON.parse(fs.readFileSync(0, "utf8")); } catch { process.exit(0); }

// A recorded exhaustion artifact for THIS turn is what satisfies the gate.
const EVIDENCE = `${process.env.CLAUDE_PROJECT_DIR || "."}/build-os/motion/exhaustion/current.json`;

let lastAssistant = "";
try {
  const lines = fs.readFileSync(ev.transcript_path, "utf8").split("\n").filter(Boolean);
  for (let i = lines.length - 1; i >= 0; i--) {
    const m = JSON.parse(lines[i]);
    if (m?.message?.role === "assistant") {
      lastAssistant = (m.message.content || []).filter((c) => c.type === "text").map((c) => c.text).join("\n");
      break;
    }
  }
} catch { process.exit(0); }

// CONTINUATION IS CHECKED FIRST, and it applies whether or not the turn
// concedes. The observed defect was a turn that conceded NOTHING - it simply
// finished a task and stopped - so a stop gate that only inspects concessions
// would have allowed it.
try {
  const q = JSON.parse(fs.readFileSync(`${process.env.CLAUDE_PROJECT_DIR || "."}/build-os/motion/queue.json`, "utf8"));
  const cont = continuationDecision(q);
  if (cont.decision === "continue") {
    process.stderr.write(
`STOP REFUSED — the queue still holds runnable work.

Finishing a task is NOT a stop condition, and neither is a commit awaiting a push grant:
execution authority and publication authority are different. An unpushed commit blocks
publication, not work.

NEXT RUNNABLE TASK: #${cont.next_task}${cont.next_subject ? " — " + cont.next_subject : ""}
${cont.reasons.map((r) => "  - " + r).join("\n")}

Begin it now. Do not stop for a narrative recap.

Stopping requires one of: ${TERMINAL.join(", ")}.
`);
    process.exit(2);
  }
} catch { /* no queue file: fall through to the concession check */ }

const { conceding } = isConcession(lastAssistant);
if (!conceding) process.exit(0);

let evidence = null;
try { evidence = JSON.parse(fs.readFileSync(EVIDENCE, "utf8")); } catch {}
// Evidence must be for THIS conclusion, not a stale artifact from an earlier one.
const fresh = evidence && evidence.for_conclusion &&
  lastAssistant.toLowerCase().includes(String(evidence.for_conclusion).toLowerCase().slice(0, 40));

if (fresh && evidence.verdict === "concession_allowed") process.exit(0);

const cap = enumerateCapability(evidence?.capability || "operator_lab_write", "claude");
process.stderr.write(
`CONCESSION BLOCKED — this turn concedes (blocked / cannot / pause / needs-manual) without recorded capability-exhaustion evidence.

You may not decide for yourself that you are out of options. Before this conclusion may leave the surface, record exhaustion evidence at:
  build-os/motion/exhaustion/current.json

It must carry all eight fields (see build-os/motion/concession-gate.mjs REQUIRED_EVIDENCE), and field 8 must be a STRUCTURED ENUMERATION, not a prose assertion.

CROSS-SURFACE CHECK — the question this gate exists to force:
  is the capability absent from the SYSTEM, or only from YOUR interface?
  surfaces observed to hold '${cap.capability}': ${JSON.stringify(cap.surfaces_with_capability)}
  proven bridges from your surface: ${JSON.stringify(cap.proven_bridges)}

${cap.surfaces_with_capability.length ? "A holder EXISTS. Route through it instead of conceding." : "No holder is observed; untested surfaces are not evidence either way."}

The goal is not "never stop". It is "never stop while unsearched agency remains."
`);
process.exit(2);
