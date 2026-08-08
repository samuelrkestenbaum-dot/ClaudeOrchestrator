// Host permission semantics — the half that CANNOT be derived from Gravito's
// own source, because it is a property of the environment Gravito is dropped
// into.
//
// This is the compatibility layer's data. Gravito's authority model treats
// mutation as ONE class; hosts stratify it. The EXP-0005 defect was not
// ignorance of the host — it was a TYPE MISMATCH between two permission
// lattices, where Gravito made its cheapest authority depend on the host's
// most expensive class. Writing both lattices down is what makes the mismatch
// a diff instead of a discovery.
//
// `observed_by` records how each profile's claims were established. A profile
// asserted without observation is marked so, because an unverified environment
// model is exactly the kind of assumption this subsystem exists to surface.

export const HOSTS = [
  {
    id: "claude_code_headless_acceptEdits",
    description: "Claude Code, -p headless, --permission-mode acceptEdits, no interactive approver",
    permits: { Edit: "allowed", Write: "allowed", NotebookEdit: "allowed", Bash: "approval_required" },
    approver_present: false,
    observed_by: "DIRECT OBSERVATION — EXP-0005 (24 arms: 150 host denials of Bash, Edit never denied) and the task-#45 live validation runs",
  },
  {
    id: "claude_code_headless_dontAsk",
    description: "Claude Code, -p headless, --permission-mode dontAsk",
    permits: { Edit: "denied", Write: "denied", NotebookEdit: "denied", Bash: "denied" },
    approver_present: false,
    observed_by: "DIRECT OBSERVATION — an EXP-0005 arm reported 'every write path and the verification command are denied'",
  },
  {
    id: "claude_code_root_bypassPermissions",
    description: "Claude Code with --dangerously-skip-permissions under root",
    permits: { Edit: "refused_to_start", Write: "refused_to_start", NotebookEdit: "refused_to_start", Bash: "refused_to_start" },
    approver_present: false,
    observed_by: "DIRECT OBSERVATION — the CLI refuses to start: 'cannot be used with root/sudo privileges'",
  },
  {
    id: "claude_code_interactive",
    description: "Claude Code with a human approver present",
    permits: { Edit: "allowed", Write: "allowed", NotebookEdit: "allowed", Bash: "approval_required" },
    approver_present: true,
    observed_by: "ASSERTED, NOT OBSERVED — no interactive approver exists in the environments used so far",
  },
  {
    id: "ci_container",
    description: "Non-interactive CI runner",
    permits: { Edit: "unknown", Write: "unknown", NotebookEdit: "unknown", Bash: "unknown" },
    approver_present: false,
    observed_by: "UNTESTED — no CI environment has been exercised",
  },
  {
    id: "codex",
    description: "Codex / other provider surface",
    permits: { Edit: "unknown", Write: "unknown", NotebookEdit: "unknown", Bash: "unknown" },
    approver_present: false,
    observed_by: "UNTESTED — provider neutrality is unproven",
  },
];

// The default when the host has NOT declared itself. It assumes the shape that
// actually broke EXP-0005 — writes allowed, shell approval-gated, no approver —
// because assuming the permissive case is what turns an unknown host into a
// runtime failure. Unknown resolves toward the SAFER path, never the freer one.
export const DEFAULT_PROFILE_ID = "unknown_conservative";

HOSTS.push({
  id: DEFAULT_PROFILE_ID,
  description: "host has not declared itself; assume writes usable and shell approval-gated with no approver",
  permits: { Edit: "allowed", Write: "allowed", NotebookEdit: "allowed", Bash: "approval_required" },
  approver_present: false,
  observed_by: "DEFAULT — not an observation. Used when GRAVITO_HOST_PROFILE is unset, chosen so an undeclared host degrades toward the lower-privilege authority path.",
});

export function resolveHost(id) {
  return HOSTS.find((h) => h.id === id) || HOSTS.find((h) => h.id === DEFAULT_PROFILE_ID);
}

export const OBSERVED = HOSTS.filter((h) => /^DIRECT OBSERVATION/.test(h.observed_by));
export const UNVERIFIED = HOSTS.filter((h) => !/^DIRECT OBSERVATION/.test(h.observed_by));
