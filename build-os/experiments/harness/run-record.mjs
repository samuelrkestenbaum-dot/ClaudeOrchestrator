// Durable run records and explicit terminal-state capture.
//
// Written because calibration attempt 1 produced NO measurement at all: the
// child died, the launching shell died with it, and the only surviving trace
// was a stream that stopped mid-sentence. The operator-visible wall-clock was
// then briefly misread as a 3-hour run. A measurement system that can lose a
// run silently, and can be misread as having measured something, is not a
// measurement system.
//
// Three invariants:
//   1. A run record exists BEFORE the child launches. If everything downstream
//      dies, the record still says a run was attempted and never finished.
//   2. Every run reaches exactly one TERMINAL STATE from a closed set.
//   3. A missing provider result event is `missing_result_event`, never
//      "completed with unknown duration".

import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";

export const TERMINAL_STATES = [
  "completed",            // a valid provider result event, no error
  "timed_out",            // the ceiling fired
  "aborted_streaming",    // provider stream cut mid-flight
  "killed",               // external signal
  "launcher_died",        // the controller vanished; child state unknown
  "missing_result_event", // process ended, no result event — NOT completion
  "infrastructure_error", // launch failed outright
];

// Session-scoped variables a child MUST NOT inherit. Attempt 1's child reported
// the orchestrator's own session_id because CLAUDE_CODE_SESSION_ID was in its
// environment: a measured arm sharing identity with its measurer.
export const SESSION_SCOPED_ENV = [
  "CLAUDE_CODE_SESSION_ID",
  "CLAUDE_CODE_CHILD_SESSION",
  "CLAUDE_PID",
];

export function scrubbedEnv(env = process.env) {
  const out = { ...env };
  for (const k of SESSION_SCOPED_ENV) delete out[k];
  return out;
}

export const newSessionId = () => crypto.randomUUID();

/** Write the run record BEFORE launching. */
export function openRun(dir, spec) {
  fs.mkdirSync(dir, { recursive: true });
  const rec = {
    artifact: "run_record",
    run_id: spec.run_id ?? `R-${crypto.randomBytes(6).toString("hex")}`,
    task_id: spec.task_id ?? null,
    arm: spec.arm ?? null,
    launched_at: spec.launched_at ?? null,   // supplied, never read from a clock here
    expected_session_id: spec.expected_session_id ?? null,
    orchestrator_session_id: spec.orchestrator_session_id ?? null,
    timeout_ceiling_s: spec.timeout_ceiling_s ?? null,
    pid: spec.pid ?? null,
    state: "launched",
    terminal_reason: null,
    admissible: false,
  };
  fs.writeFileSync(path.join(dir, "run-record.json"), JSON.stringify(rec, null, 1));
  return rec;
}

/**
 * Classify a finished (or vanished) run from evidence only. No field is
 * inferred from operator wall-clock, and no default is "completed".
 */
export function classify({ streamPath, exitCode, ceilingS, elapsedS, launcherAlive = true }) {
  let events = [];
  try {
    events = fs.readFileSync(streamPath, "utf8").split("\n").filter(Boolean)
      .map((l) => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean);
  } catch {
    return { terminal_reason: "infrastructure_error", is_error: true, result_event: false,
             detail: "no stream file — the child produced no observable output" };
  }
  const result = events.find((e) => e.type === "result");
  const childSession = (events.find((e) => e.session_id) || {}).session_id ?? null;

  if (result) {
    const reason = result.is_error === true
      ? (result.terminal_reason === "aborted_streaming" ? "aborted_streaming" : "infrastructure_error")
      : "completed";
    return { terminal_reason: reason, is_error: result.is_error === true, result_event: true,
             child_session_id: childSession, turns: result.num_turns ?? null,
             detail: result.terminal_reason ?? null };
  }
  if (!launcherAlive) {
    return { terminal_reason: "launcher_died", is_error: true, result_event: false,
             child_session_id: childSession, detail: "controller vanished; child state unknown" };
  }
  if (exitCode === 124 || (ceilingS && elapsedS && elapsedS >= ceilingS - 5)) {
    return { terminal_reason: "timed_out", is_error: true, result_event: false, child_session_id: childSession };
  }
  if (exitCode !== null && exitCode !== 0 && exitCode > 128) {
    return { terminal_reason: "killed", is_error: true, result_event: false, child_session_id: childSession,
             detail: `signal ${exitCode - 128}` };
  }
  return { terminal_reason: "missing_result_event", is_error: true, result_event: false,
           child_session_id: childSession,
           detail: "process ended without a provider result event — this is NOT a completion" };
}

/** Close a run. `admissible` is true only for a clean completion with isolation proven. */
export function closeRun(dir, verdict, isolation) {
  const f = path.join(dir, "run-record.json");
  const rec = JSON.parse(fs.readFileSync(f, "utf8"));
  const out = {
    ...rec,
    state: "terminal",
    terminal_reason: verdict.terminal_reason,
    is_error: verdict.is_error,
    result_event_observed: verdict.result_event,
    child_session_id: verdict.child_session_id ?? null,
    isolation: isolation ?? null,
    admissible: verdict.terminal_reason === "completed" && isolation?.isolated === true,
    admissibility_note:
      verdict.terminal_reason === "completed"
        ? (isolation?.isolated === true ? "clean completion under a proven-isolated session"
           : "REFUSED: completed, but session isolation was not proven — the measurer and the measured were not independent")
        : `REFUSED: terminal reason '${verdict.terminal_reason}' is not a completion`,
  };
  fs.writeFileSync(f, JSON.stringify(out, null, 1));
  return out;
}

/**
 * Prove isolation from the CHILD'S OWN emitted stream. A new process is not a
 * new session, so this never infers isolation from having spawned something.
 */
export function verifyIsolation({ streamPath, expectedSessionId, orchestratorSessionId }) {
  let ids = new Set();
  try {
    for (const l of fs.readFileSync(streamPath, "utf8").split("\n")) {
      if (!l.trim()) continue;
      try { const e = JSON.parse(l); if (e.session_id) ids.add(e.session_id); } catch {}
    }
  } catch {
    return { isolated: false, reason: "no stream — isolation cannot be proven, so it is not assumed" };
  }
  if (!ids.size) return { isolated: false, reason: "the child emitted no session_id; isolation unproven" };
  const observed = [...ids];
  if (orchestratorSessionId && observed.includes(orchestratorSessionId)) {
    return { isolated: false, observed, reason:
      "the child reported the ORCHESTRATOR's session id — measurer and measured share session-scoped state" };
  }
  if (expectedSessionId && !observed.includes(expectedSessionId)) {
    return { isolated: false, observed, reason:
      `the child did not report the assigned session id ${expectedSessionId}` };
  }
  return { isolated: true, observed, reason: "child session id is distinct from the orchestrator's and matches the assignment" };
}
