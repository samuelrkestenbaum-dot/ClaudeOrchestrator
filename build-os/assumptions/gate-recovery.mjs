#!/usr/bin/env node
// The LIVE gate's recovery message, GENERATED FROM THE SELECTOR.
//
// There is exactly one ruleset. The thing that tells self-audit a path is
// incompatible is the same thing that orders what the worker is told to do —
// so the advertised recovery cannot drift away from the path that actually
// works. A hand-authored message that says "run this Bash command" while the
// host denies Bash is how EXP-0005 produced 0/12.
//
// Usage: gate-recovery.mjs --tool Edit [--host <profile-id>] [--gate <path>]

import path from "node:path";
import { selectAuthorityPath } from "./authority-selector.mjs";
import { resolveHost, DEFAULT_PROFILE_ID } from "./host-profiles.mjs";

const arg = (n, d = null) => { const i = process.argv.indexOf(`--${n}`); return i > 0 && process.argv[i + 1] ? process.argv[i + 1] : d; };
const tool = arg("tool", "Edit");
const hostId = arg("host", process.env.GRAVITO_HOST_PROFILE || DEFAULT_PROFILE_ID);
const gatePath = arg("gate", path.join(process.env.CLAUDE_PROJECT_DIR || ".", ".claude/hooks/routing-gate.sh"));

const RECOVERY = {
  routing_request_channel:
`RECOVERY — no shell required. WRITE this exact file, then retry this call:
  build-os/packets/routing/routing-request.json
  {"task_id":"<id>","description":"<one line>","descriptor":{"expected_files_changed":1,"requires_tests":false,"expected_session_count":1,"prior_context_required":false,"handoff_required":false,"consequence_level":"low","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}}
Writing that file is permitted without a receipt (it is the routing channel, not a mutation). It grants nothing by itself: the request is validated and routed, and your NEXT call proceeds only if it is well formed.`,
  structured_routing_action:
`RECOVERY — via shell:
  build-os/tools/route-task.sh --task-id <id> --description "<one line>" --descriptor <13-field-json>
Cheap direct-mode example (copy, adjust the id/description):
  build-os/tools/route-task.sh --task-id quick-task-1 --description "small routed task" --descriptor '{"expected_files_changed":1,"requires_tests":false,"expected_session_count":1,"prior_context_required":false,"handoff_required":false,"consequence_level":"low","irreversible_or_external_mutation":false,"high_blast_radius":false,"unclear_acceptance_criteria":false,"security_or_compliance_consequence":false,"parallel_workstreams_benefit":false,"high_rework_history":false,"nondeterministic_verification":false}'`,
};

// The tool being blocked IS the mutation class the worker needs.
const host = resolveHost(hostId);
let r;
try { r = selectAuthorityPath({ gatePath, host, mutation_class: tool }); }
catch (e) {
  // Fail toward discoverability: if selection cannot run, advertise EVERY path
  // rather than none. A worker told nothing is a worker that cannot proceed.
  console.log(`routing-gate: MUTATION BLOCKED — ${tool} is mutation-capable and NO OPEN routing receipt exists.`);
  console.log(`SELECTOR UNAVAILABLE (${e.message}) — every known recovery is listed, unordered:`);
  console.log(RECOVERY.routing_request_channel);
  console.log(RECOVERY.structured_routing_action);
  process.exit(0);
}


console.log(`routing-gate: MUTATION BLOCKED — ${tool} is mutation-capable and NO OPEN routing receipt exists under build-os/packets/routing/ (open = executed_mode "-"). Every substantive task routes at entry; tiny work routes too, it just routes cheaply (direct mode).`);

if (r.decision === "selected") {
  console.log(`Host profile ${host.id}: the least-privileged viable route is '${r.selected}' (${r.selected_tool_class} class). Use it FIRST.`);
  console.log(RECOVERY[r.selected] ?? "(no recovery text registered for the selected path)");
  for (const alt of [...r.rejected_higher_privilege]) {
    console.log(`ALTERNATIVE (higher privilege — ${alt}; prefer the route above):`);
    console.log(RECOVERY[alt] ?? "");
  }
  for (const dead of r.rejected_non_viable) console.log(`NOT AVAILABLE on this host: ${dead} — do not spend a call on it.`);
} else if (r.decision === "refuse_host_denies_mutation") {
  console.log(`NO RECOVERY EXISTS: ${r.reason} This is a host restriction, not a Gravito defect — do not attempt a routing workaround.`);
} else {
  console.log(`FAIL CLOSED: ${r.reason}`);
  console.log(`This is recorded as an authority-path incompatibility for self-audit. Do not attempt a mutation; it cannot be authorized on this host.`);
}
console.log("Continue the task — only this unrouted call is refused, not the work.");
