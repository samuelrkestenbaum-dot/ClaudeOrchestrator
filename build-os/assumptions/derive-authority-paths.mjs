#!/usr/bin/env node
// DERIVED authority paths — extracted from the gate's own source, not declared.
//
// WHY DERIVATION AND NOT A LIST. A hand-authored assumption registry contains
// the assumptions someone thought to write down, and the ones that hurt are
// precisely the ones nobody thought of. Post-Outcome Disposition v0 proved
// this: it could describe every failure shape its author had already seen,
// then met a new one and had no predicate. A registry built the same way
// inherits the same blind spot.
//
// So the load-bearing facts here are read OUT OF THE CODE. This module answers
// one question mechanically:
//
//   To obtain first mutation authority, which TOOL CLASS must the worker be
//   permitted to use?
//
// That single derived fact, cross-referenced with a host's permission
// semantics, is sufficient to have predicted EXP-0005's total failure before
// any arm ran — without anyone suspecting the defect existed.

import fs from "node:fs";

// Tool classes, ordered by how commonly hosts restrict them. The ordering is
// the point: an authority path is unsafe when it sits STRICTER than the work
// it authorizes, not when it is merely restricted.
export const TOOL_CLASS = {
  Write: { name: "Write", writes: true },
  Edit: { name: "Edit", writes: true },
  NotebookEdit: { name: "NotebookEdit", writes: true },
  Bash: { name: "Bash", writes: true, executes: true },
};

/**
 * Read the gate source and extract every path that can yield authority
 * WITHOUT already holding it — i.e. every classification that returns an
 * ungated pass from the task-entry boundary.
 */
export function deriveAuthorityPaths(gateSource) {
  const paths = [];

  // A Bash invocation recognised as a structured routing action passes ungated.
  if (/routing_action\s+"\$in"\s*>\/dev\/null;\s*then\s+printf\s+'routing_tool'/.test(gateSource)
      || /if routing_action .*printf 'routing_tool'/.test(gateSource)) {
    const tools = (gateSource.match(/RT_STRICT='([^']+)'/) || [])[1] || "";
    paths.push({
      id: "structured_routing_action",
      tool_class: "Bash",
      how: "run a recognised routing tool directly",
      recognises: (tools.match(/[a-z-]+\\?\.(sh|mjs)/g) || []).map((s) => s.replace(/\\/g, "")),
    });
  }

  // A write to the routing-request path passes ungated.
  if (/is_routing_request_path/.test(gateSource) && /printf 'routing_request'/.test(gateSource)) {
    const f = (gateSource.match(/REQ_FILE="([^"]+)"/) || [])[1] || "(unresolved)";
    paths.push({
      id: "routing_request_channel",
      tool_class: "Write",
      how: "write one structured request file",
      recognises: [f.replace("$RDIR", "build-os/packets/routing")],
    });
  }

  return paths;
}

/**
 * The load-bearing check. Given the derived authority paths and a host's
 * permission semantics, is ANY authority path reachable using a tool class no
 * stricter than the work the worker wants to perform?
 *
 * This is the invariant EXP-0005 violated:
 *   first mutation authority must not depend on an operation class whose host
 *   permission requirements are stricter than the mutation class it authorizes.
 */
export function checkViability(paths, host, workToolClass = "Edit") {
  const permitted = (t) => host.permits[t] === "allowed";
  const workPermitted = permitted(workToolClass);

  const viable = paths.filter((p) => permitted(p.tool_class));
  const blocked = paths.filter((p) => !permitted(p.tool_class));

  // The mismatch: the host would allow the WORK, but every route to being
  // ALLOWED to do the work is itself blocked.
  const mismatch = workPermitted && viable.length === 0 && paths.length > 0;

  return {
    host: host.id,
    work_tool_class: workToolClass,
    work_permitted: workPermitted,
    authority_paths_total: paths.length,
    authority_paths_viable: viable.map((p) => p.id),
    authority_paths_blocked: blocked.map((p) => `${p.id} (needs ${p.tool_class}: ${host.permits[p.tool_class]})`),
    verdict: mismatch ? "AUTHORITY_PATH_MISMATCH" : (workPermitted && viable.length ? "viable" : (!workPermitted ? "work_itself_not_permitted" : "no_authority_paths_found")),
    detail: mismatch
      ? `The host permits ${workToolClass}, but EVERY route to earning authority for it requires a class the host restricts. ` +
        `A worker able to do the work cannot become allowed to do the work.`
      : (!workPermitted
        ? `The host does not permit ${workToolClass} at all, so no authority is owed — this is correct refusal, not a defect.`
        : `Authority is reachable via: ${viable.map((p) => `${p.id} (${p.tool_class})`).join(", ")}`),
  };
}

export function loadGate(path) { return fs.readFileSync(path, "utf8"); }
