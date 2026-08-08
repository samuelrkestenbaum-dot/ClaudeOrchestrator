// The assumption registry and coverage map.
//
// THE POINT: an invariant that has never been exercised is itself a risk, and
// that risk should be VISIBLE rather than waiting for a catastrophic
// experiment to expose it.
//
// Two kinds of entry, kept apart because they have different failure modes:
//
//   DERIVED   — the claim is checked by reading the system's own source, so it
//               cannot silently drift out of date, and it can surface an
//               assumption nobody thought to write down.
//   DECLARED  — the claim is asserted by a human. Useful, but it inherits the
//               blind spot that sank Post-Outcome Disposition v0: it only ever
//               contains what someone already suspected.
//
// Every entry carries the ENVIRONMENTS it has been validated in. "Validated"
// with an empty environment list is not validated; it is an untested
// load-bearing assumption, and the coverage report says so in those words.

import { deriveAuthorityPaths, checkViability, loadGate } from "./derive-authority-paths.mjs";
import { HOSTS } from "./host-profiles.mjs";

export const STATUS = ["validated", "partially_validated", "untested", "violated"];

/** Environments an assumption has actually been exercised in. */
const ENV = {
  headless_acceptEdits: "claude_code_headless_acceptEdits",
  headless_dontAsk: "claude_code_headless_dontAsk",
  clean_clone: "fresh restore, no live_state / .gravito residue",
  fresh_child_session: "spawned child with scrubbed session env",
};

export const ASSUMPTIONS = [
  {
    id: "first-authority-reachable",
    kind: "DERIVED",
    claim: "First mutation authority is obtainable under every supported host permission mode where the work itself is permitted.",
    load_bearing: true,
    dependencies: ["host permission model", "routing gate classification", "hook execution outside the tool-permission layer"],
    // The check reads the gate source and every host profile; no assertion.
    check(ctx) {
      const paths = deriveAuthorityPaths(loadGate(ctx.gatePath));
      const results = HOSTS.map((h) => checkViability(paths, h, "Edit"));
      const observed = results.filter((r) => /^DIRECT OBSERVATION/.test((HOSTS.find((h) => h.id === r.host) || {}).observed_by || ""));
      const mismatches = results.filter((r) => r.verdict === "AUTHORITY_PATH_MISMATCH");
      const unknown = results.filter((r) => r.verdict === "no_authority_paths_found" || Object.values((HOSTS.find((h) => h.id === r.host) || {}).permits || {}).includes("unknown"));
      return {
        status: mismatches.length ? "violated" : (unknown.length ? "partially_validated" : "validated"),
        validated_in: observed.filter((r) => r.verdict === "viable" || r.verdict === "work_itself_not_permitted").map((r) => r.host),
        untested_in: unknown.map((r) => r.host),
        violations: mismatches.map((r) => `${r.host}: ${r.detail}`),
        derived_paths: paths.map((p) => `${p.id} via ${p.tool_class}`),
      };
    },
  },
  {
    id: "capability-discoverable-at-failure",
    kind: "DERIVED",
    claim: "Every authority path is advertised in the refusal that blocks the worker — a capability the worker cannot discover at the moment of failure is functionally absent.",
    load_bearing: true,
    dependencies: ["gate refusal text"],
    check(ctx) {
      const src = loadGate(ctx.gatePath);
      const paths = deriveAuthorityPaths(src);
      // The refusal block is what the worker actually sees.
      const refusal = (src.match(/MUTATION BLOCKED[\s\S]{0,3000}?Continue the task/) || [""])[0];
      const missing = paths.filter((p) => !p.recognises.some((r) => refusal.includes(r.replace(/^.*\//, ""))));
      return {
        status: missing.length ? "violated" : "validated",
        validated_in: missing.length ? [] : [ENV.headless_acceptEdits],
        untested_in: [],
        violations: missing.map((p) => `authority path '${p.id}' (${p.tool_class}) exists but is NOT advertised in the refusal — a worker hitting the block cannot discover it`),
        derived_paths: paths.map((p) => `${p.id} via ${p.tool_class}`),
      };
    },
  },
  {
    id: "clean-clone-reconstructs-runtime-state",
    kind: "DECLARED",
    claim: "A clean clone can reconstruct every load-bearing runtime state; nothing required to operate exists only as accumulated residue.",
    load_bearing: true,
    dependencies: ["restore procedure", "state classification"],
    evidence: "Exercised in task #45: fresh restores with no live_state/.gravito completed bootstrap and work. NOT exhaustive — only the routing/authority path was traced.",
    status: "partially_validated",
    validated_in: [ENV.clean_clone],
    untested_in: ["memory subsystem", "telemetry subsystem", "adapter subsystem"],
  },
  {
    id: "fresh-child-implies-fresh-session-identity",
    kind: "DECLARED",
    claim: "A freshly spawned child process has its own session identity and does not inherit the orchestrator's.",
    load_bearing: true,
    dependencies: ["session-scoped env scrub", "--session-id", "stream verification"],
    evidence: "TESTED AND FOUND FALSE BY DEFAULT: an unscrubbed child reported the orchestrator's session id. Holds only with the scrub plus an explicit --session-id, verified in EXP-0005's 24 arms.",
    status: "validated",
    validated_in: [ENV.fresh_child_session, ENV.headless_acceptEdits],
    untested_in: ["other providers"],
  },
  {
    id: "authority-rules-have-enforcement-surfaces",
    kind: "DECLARED",
    claim: "Every authority rule has a load-bearing enforcement surface, not only a model describing it.",
    load_bearing: true,
    dependencies: ["pre-push hook", "routing gate", "publish-check"],
    evidence: "Publication authority was model-only until wired; wiring then exposed four defects in sequence (self-granting by staleness, check ordering, chain grants, unexpressible authorised transitions). A rule with no surface is a description.",
    status: "partially_validated",
    validated_in: ["git push path", "task-entry mutation path"],
    untested_in: ["memory rotation", "packet close", "adapter dispatch"],
  },
  {
    id: "provider-host-neutrality",
    kind: "DECLARED",
    claim: "Gravito behaves equivalently across provider/host surfaces.",
    load_bearing: true,
    dependencies: ["adapter contract", "permission semantics", "session identity", "token telemetry"],
    evidence: "No non-Claude-Code surface has been exercised at all.",
    status: "untested",
    validated_in: [],
    untested_in: ["codex", "cursor", "ci_container", "claude_code_interactive"],
  },
];

/** Build the coverage report. Untested load-bearing assumptions are the risk. */
export function coverage(ctx = { gatePath: ".claude/hooks/routing-gate.sh" }) {
  const rows = ASSUMPTIONS.map((a) => {
    if (a.kind === "DERIVED") {
      const r = a.check(ctx);
      return { id: a.id, kind: a.kind, load_bearing: a.load_bearing, claim: a.claim, ...r };
    }
    return {
      id: a.id, kind: a.kind, load_bearing: a.load_bearing, claim: a.claim,
      status: a.status, validated_in: a.validated_in || [], untested_in: a.untested_in || [],
      violations: [], evidence: a.evidence,
    };
  });

  const violated = rows.filter((r) => r.status === "violated");
  const untested = rows.filter((r) => r.load_bearing && r.status === "untested");
  const partial = rows.filter((r) => r.status === "partially_validated");

  return {
    artifact: "assumption_coverage_map",
    total: rows.length,
    counts: {
      validated: rows.filter((r) => r.status === "validated").length,
      partially_validated: partial.length,
      untested: rows.filter((r) => r.status === "untested").length,
      violated: violated.length,
    },
    violated_load_bearing: violated.map((r) => ({ id: r.id, violations: r.violations })),
    untested_load_bearing: untested.map((r) => ({ id: r.id, claim: r.claim, untested_in: r.untested_in })),
    rows,
    note:
      "An assumption with an empty validated_in is NOT validated — it is an untested load-bearing claim, and that is " +
      "itself a risk. DERIVED rows are re-checked from source on every run and cannot drift; DECLARED rows carry the " +
      "blind spot of only containing what someone already suspected.",
  };
}
