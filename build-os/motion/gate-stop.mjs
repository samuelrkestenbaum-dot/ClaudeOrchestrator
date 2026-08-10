#!/usr/bin/env node
// Stop-event adapter: decide whether this turn may end.
//
// Exit 0 = allow the stop. Exit 2 = REFUSE, with stderr shown to the model.
// It shares ONE ruleset with the audit path (concession-gate.mjs); there is no
// second copy of the stopping rule that could drift from the first.
//
// LEAN L1 — completion and concession resolve SUBSTRATE-SIDE.
//
// The measured defect this rewrite removes (LEAN-MANIFEST.md L1): the previous
// version demanded the WORKER author an 8-field evidence file whose
// `for_conclusion` had to appear verbatim in the final message. Workers spent
// 2-3 refusal rounds per task learning that contract — reading this file's
// source to find out why they were still blocked — and re-wrote a full report
// after each round: repeat final_report measured at 2.4/arm vs native 0.7.
//
// Worse, the loop fired mostly on HONEST COMPLETION REPORTS: "the fix is done,
// I could not run the verification command" contains `cannot`, so isConcession
// classified finished work as giving up, and the gate demanded exhaustion
// evidence for a task that was already delivered.
//
// The boundary now: the WORKER works; THIS DRIVER decides. Completion is
// resolved from artifacts (does work product exist?), never from prose
// matching. Concession is resolved from the transcript's own executed probes —
// the driver derives the evidence, applies the shared gate, writes the record
// with machine provenance, and either allows the stop or emits ONE instruction
// naming exactly what to try. The worker never authors evidence and never needs
// to read this file.
//
// PRESERVED, per the manifest: "never stop while unsearched agency remains."
// A premature concession with no real probes is still refused — the floor is
// probes in >=2 distinct capability classes before CONCEDE is reachable.

import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";
import { isConcession, concessionGate } from "./concession-gate.mjs";
import { enumerateCapability } from "./capability-map.mjs";
import { continuationDecision, TERMINAL_CONDITIONS as TERMINAL } from "./continuation.mjs";

const ROOT = process.env.CLAUDE_PROJECT_DIR || ".";
const EVIDENCE = path.join(ROOT, "build-os/motion/exhaustion/current.json");

let ev = {};
try { ev = JSON.parse(fs.readFileSync(0, "utf8")); } catch { process.exit(0); }

let lines = [];
try {
  lines = fs.readFileSync(ev.transcript_path, "utf8").split("\n").filter(Boolean)
    .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
} catch { process.exit(0); }

let lastAssistant = "";
for (let i = lines.length - 1; i >= 0; i--) {
  const m = lines[i];
  if (m?.message?.role === "assistant") {
    lastAssistant = (m.message.content || []).filter((c) => c.type === "text").map((c) => c.text).join("\n");
    break;
  }
}

// CONTINUATION IS CHECKED FIRST, unchanged — it applies whether or not the turn
// concedes. The observed defect it guards was a turn that conceded NOTHING —
// it simply finished a task and stopped while the queue held runnable work.
try {
  const q = JSON.parse(fs.readFileSync(path.join(ROOT, "build-os/motion/queue.json"), "utf8"));
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

// ---------------------------------------------------------------------------
// L1 PART 1 — COMPLETION RESOLVES FROM ARTIFACTS, NOT PROSE.
//
// A message that claims the task outcome AND is backed by work product on disk
// is a delivery with a named limitation, not a concession — however many
// concession-shaped words its honest limitations section contains. Whether the
// delivered work is ACCEPTED stays exactly where it was: with downstream
// acceptance/qa, which this gate does not and must not re-judge.
//
// Known trade, accepted in the manifest: a genuinely stuck worker who edited
// files and says "partially done, blocked" now stops cleanly instead of being
// interrogated. Downstream acceptance catches the shortfall; pricing further
// search is the EV rule's job, not an interrogation loop's.
// ---------------------------------------------------------------------------
const claimsCompletion =
  /\b(complete[d]?|done|fixed|finished|delivered|implemented|applied|resolved|shipped)\b/i.test(lastAssistant);

const workProduct = (() => {
  try {
    if (execSync(`git -C ${JSON.stringify(ROOT)} status --porcelain`, { encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }).trim()) return true;
  } catch {}
  try {
    // Committed-then-stopped sessions: any commit on this transcript's watch.
    const started = lines[0]?.timestamp || lines[0]?.message?.timestamp;
    if (started && execSync(`git -C ${JSON.stringify(ROOT)} log --oneline --since=${JSON.stringify(started)} -1`, { encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }).trim()) return true;
  } catch {}
  return false;
})();

if (claimsCompletion && workProduct) process.exit(0);

// ---------------------------------------------------------------------------
// L1 PART 2 — CONCESSION RESOLVES FROM THE TRANSCRIPT'S EXECUTED PROBES.
//
// The driver reads what was ACTUALLY TRIED — errored tool calls, by capability
// class — and supplies the shared gate itself. Intention was never evidence;
// now prose isn't either, in either direction.
// ---------------------------------------------------------------------------
const uses = {};
for (const m of lines) for (const c of (m?.message?.content || []))
  if (c.type === "tool_use") uses[c.id] = { name: c.name, input: c.input || {} };

const classOf = (name) =>
  name === "Bash" ? "shell"
  : /^(Task|Agent)$/.test(name) ? "subagent"
  : /^SendMessage$/.test(name) ? "peer"
  : /^mcp__/.test(name) ? "mcp"
  : `tool:${name}`;

const probes = [];
for (const m of lines) for (const c of (m?.message?.content || [])) {
  if (c.type !== "tool_result" || c.is_error !== true) continue;
  const u = uses[c.tool_use_id];
  if (!u) continue;
  probes.push({
    class: classOf(u.name), tool: u.name,
    detail: u.name === "Bash" ? String(u.input.command || "").slice(0, 120) : JSON.stringify(u.input).slice(0, 120),
  });
}
const classes = [...new Set(probes.map((p) => p.class))];
const PROBE_MENU = {
  shell: "a Bash invocation of the needed command (and its direct-binary spelling)",
  mcp: "an MCP tool surface (e.g. language-server diagnostics), if one is connected",
  subagent: "a subagent dispatch, which holds its own tool surface",
};
const untried = Object.keys(PROBE_MENU).filter((k) => !classes.includes(k));

// THE FLOOR — the preserved control. Below it, CONCEDE is unreachable, and the
// refusal is ONE instruction under the L3 message contract: what / why / what
// the substrate already did / the single next action. Never homework.
if (classes.length < 2) {
  process.stderr.write(
`STOP DEFERRED — this turn concedes, but the transcript shows attempts in ${classes.length} capability class(es); the concession floor is 2.

What the substrate already did: read your executed attempts (${probes.length} errored call(s)${classes.length ? `, class(es): ${classes.join(", ")}` : ""}) and checked the capability map — no evidence file is needed from you, and none will be asked for.

Next action (one step): try ${untried.length ? `one of the untried route(s) — ${untried.map((k) => PROBE_MENU[k]).join("; ")}` : "the needed command once more so the attempt is on the record"} — then stop again. If it fails, the stop will be allowed on the recorded attempts.
`);
  process.exit(2);
}

// At or above the floor: the driver authors the evidence and applies the SAME
// shared gate the audit path uses. Capability is named generically — passing an
// explicit name avoids capability-map's default entirely (see manifest L3).
const cap = enumerateCapability("task_execution", "claude");
const evidence = {
  proposed_concession: lastAssistant.slice(0, 300),
  concession_class: "blocked",
  available_interfaces: [...new Set(Object.values(uses).map((u) => u.name))],
  paths_attempted: probes.map((p) => `${p.class}: ${p.detail}`),
  attempt_results: probes.map(() => "errored/refused (from transcript tool_result)"),
  workaround_classes_considered: classes,
  why_each_viable_workaround_failed: probes.map((p) => `${p.tool} ${p.detail} — errored at execution`),
  other_surface_may_hold_capability: {
    enumerated: true,
    surfaces_with_capability: cap.surfaces_with_capability,
    proven_bridges: cap.proven_bridges,
  },
  authored_by: "runtime",
  derived_from: "transcript tool_result errors; no worker-authored field",
  for_conclusion: lastAssistant.slice(0, 120),
};

const g = concessionGate(evidence, { round: 1 });

if (g.verdict === "concession_allowed") {
  evidence.verdict = "concession_allowed";
  evidence.gate_reasons = g.reasons;
  try {
    fs.mkdirSync(path.dirname(EVIDENCE), { recursive: true });
    fs.writeFileSync(EVIDENCE, JSON.stringify(evidence, null, 2) + "\n");
  } catch { /* recording failure must not trap the worker in the session */ }
  process.exit(0);
}

// The shared gate found a live route (e.g. an observed holder). One
// instruction, same contract.
process.stderr.write(
`STOP DEFERRED — a live route remains.

What the substrate already did: derived your ${probes.length} executed attempt(s) across ${classes.join(", ")}, ran the capability check itself, and found: ${g.reasons.join("; ")}.

Next action (one step): ${cap.surfaces_with_capability.length ? `route through ${cap.surfaces_with_capability.join(" or ")}` : "close the gap named above"} — then stop again.
`);
process.exit(2);
