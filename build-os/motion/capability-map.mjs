// CROSS-SURFACE CAPABILITY ENUMERATION.
//
// The question the false concession never asked: is the capability absent from
// the SYSTEM, or merely from THIS WORKER'S interface? Answering it requires a
// map that outlives any one worker's view.
//
// Entries are OBSERVED or DECLARED, and the distinction is load-bearing: the
// Operator Lab bridge was DECLARED absent by a worker that had only checked
// itself, then OBSERVED present at system level.

export const SURFACE_CAPABILITIES = [
  {
    surface: "chatgpt", capability: "operator_lab_write",
    interfaces: ["observe_interaction", "gate_outbound_inference"],
    status: "OBSERVED",
    evidence: "ledgerId 36263 (Claude-attributed interaction recorded) and 36264 (ChatGPT outcome written back); live readiness moved ChatGPT-only -> Claude + ChatGPT",
  },
  {
    surface: "claude", capability: "operator_lab_write",
    interfaces: [],
    status: "OBSERVED_ABSENT_LOCALLY",
    evidence: "no Operator Lab tool in the Claude session tool surface; candidate MCP server requires non-interactive-impossible OAuth",
    // The correction: local absence, NOT system absence.
    bridge: { via: "chatgpt", attributable_as: "claude.cowork.session / anthropic / claude", status: "PROVEN" },
  },
  { surface: "claude", capability: "repository_write", interfaces: ["git", "Edit", "Write"], status: "OBSERVED", evidence: "22 kernel events across 10 event types" },
  { surface: "manus", capability: "operator_lab_write", interfaces: [], status: "UNTESTED", evidence: "surface never exercised" },
  { surface: "surplus_recovery", capability: "operator_lab_write", interfaces: [], status: "UNTESTED", evidence: "surface never exercised" },
];

/** Which surfaces hold a capability the asking worker lacks? */
export function enumerateCapability(capability, askingSurface) {
  const rows = SURFACE_CAPABILITIES.filter((r) => r.capability === capability);
  const holders = rows.filter((r) => r.status === "OBSERVED" && r.surface !== askingSurface).map((r) => r.surface);
  const own = rows.find((r) => r.surface === askingSurface);
  const bridges = rows.filter((r) => r.surface === askingSurface && r.bridge?.status === "PROVEN").map((r) => r.bridge);
  return {
    enumerated: true,
    capability, asking_surface: askingSurface,
    local_status: own?.status ?? "UNKNOWN",
    surfaces_with_capability: holders,
    proven_bridges: bridges,
    untested_surfaces: rows.filter((r) => r.status === "UNTESTED").map((r) => r.surface),
    note: holders.length
      ? "The capability EXISTS in the system. Local absence is not system absence — route through a holder."
      : "No surface is OBSERVED to hold this capability; untested surfaces are not evidence of absence either way.",
  };
}
