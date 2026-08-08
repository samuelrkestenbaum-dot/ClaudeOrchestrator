// ADVERSARIAL COMPATIBILITY MATRIX — the framework, deliberately not the claims.
//
// The point is to make UNKNOWN environmental coverage visible. A cell that has
// not been exercised on a real host is `untested`; a cell exercised against a
// modelled profile is `simulated`. Neither is `validated`, and the reporter
// refuses to collapse them — the same line drawn on the interactive-host arm in
// task #45.
//
// Permutations are NOT enumerated. 8 dimensions would give hundreds of cells,
// almost all of which exercise no distinct architectural assumption. Cells are
// declared only where they probe a named assumption.

export const DIMENSIONS = {
  state: ["clean_clone", "warm", "restored_snapshot"],
  session: ["fresh", "inherited", "recovered"],
  host_authority: ["permissive", "interactive_approval", "headless_denial"],
  tool_class: ["Bash", "Edit", "Write"],
  provider: ["claude_code", "codex", "cursor", "ci"],
  machine: ["normal", "constrained_cpu"],
  network: ["online", "unavailable"],
  memory: ["populated", "empty", "partial"],
};

export const COVERAGE = ["validated", "simulated", "untested", "violated"];

// Each cell names the assumption it exercises. A cell that probes nothing is
// noise dressed as rigour.
export const CELLS = [
  { id: "clean+fresh+headless+Edit", probes: "first-authority-reachable",
    dims: { state: "clean_clone", session: "fresh", host_authority: "headless_denial", tool_class: "Edit", provider: "claude_code" },
    coverage: "validated", evidence: "task #45 live validation: Edit-only task completed on a clean clone under headless acceptEdits" },
  { id: "clean+fresh+headless+Bash", probes: "first-authority-reachable",
    dims: { state: "clean_clone", session: "fresh", host_authority: "headless_denial", tool_class: "Bash", provider: "claude_code" },
    coverage: "validated", evidence: "task #45: Bash-requiring task correctly stopped by the HOST, not by Gravito" },
  { id: "warm+inherited+session-identity", probes: "fresh-child-implies-fresh-session-identity",
    dims: { state: "warm", session: "inherited", provider: "claude_code" },
    coverage: "validated", evidence: "EXP-0005: unscrubbed child reported the orchestrator session id; scrub + --session-id verified across 24 arms" },
  { id: "clean+interactive+Edit", probes: "first-authority-reachable",
    dims: { state: "clean_clone", session: "fresh", host_authority: "interactive_approval", tool_class: "Edit", provider: "claude_code" },
    coverage: "simulated", evidence: "host profile asserted; NO interactive approver has existed in any environment used" },
  { id: "codex+any", probes: "provider-host-neutrality",
    dims: { provider: "codex" }, coverage: "untested", evidence: "no non-Claude-Code surface has been exercised" },
  { id: "ci+headless", probes: "provider-host-neutrality",
    dims: { provider: "ci", host_authority: "headless_denial" }, coverage: "untested", evidence: "no CI environment exercised" },
  { id: "constrained_cpu", probes: "measurement-under-contention",
    dims: { machine: "constrained_cpu" }, coverage: "untested",
    evidence: "EXP-0004 lost arms to contention; never re-exercised deliberately" },
  { id: "network_unavailable", probes: "offline-operation",
    dims: { network: "unavailable" }, coverage: "untested", evidence: "never exercised" },
  { id: "memory_empty", probes: "clean-clone-reconstructs-runtime-state",
    dims: { memory: "empty", state: "clean_clone" }, coverage: "validated",
    evidence: "task #45 restores carried no live_state/.gravito and bootstrap succeeded" },
  { id: "memory_partial", probes: "clean-clone-reconstructs-runtime-state",
    dims: { memory: "partial" }, coverage: "untested", evidence: "partial-memory restore never exercised" },
];

export function matrixReport() {
  const by = { validated: [], simulated: [], untested: [], violated: [] };
  for (const c of CELLS) by[c.coverage].push(c.id);
  const dimensionsTouched = new Set();
  for (const c of CELLS) for (const k of Object.keys(c.dims)) dimensionsTouched.add(k);
  const untouched = Object.keys(DIMENSIONS).filter((d) => !dimensionsTouched.has(d));
  return {
    artifact: "adversarial_matrix", cells: CELLS.length, by_coverage: Object.fromEntries(Object.entries(by).map(([k, v]) => [k, v.length])),
    validated: by.validated, simulated: by.simulated, untested: by.untested,
    dimensions_never_probed: untouched,
    honesty:
      "`simulated` is NOT `validated`. A cell exercised against a modelled host profile proves the model is " +
      "self-consistent, not that the environment behaves that way. Declared cells are also not exhaustive: a " +
      "combination nobody wrote down is absent, and its absence is not reported.",
  };
}
