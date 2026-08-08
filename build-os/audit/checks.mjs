// THE REGISTERED CHECKS, with their fidelity and failure evidence.
//
// `source_fingerprint_now` is COMPUTED by hashing the guarded source on every
// run — never stored, never hand-maintained. `proof_taken_at` is the stored
// fingerprint from when the mutation was actually executed. When the two
// diverge the proof has expired, and no one has to remember to notice.
//
// THE HONEST DEFAULT IS UNPROVEN. A check is recorded as failure-capable ONLY
// where a mutation was really run against it. Most of this repository's checks
// have never been mutation-tested, and this registry is supposed to make that
// visible rather than flatter the suite.

import fs from "node:fs";
import crypto from "node:crypto";

/** Fingerprint of the guarded source: the thing whose change expires a proof. */
export function fingerprint(paths = []) {
  const h = crypto.createHash("sha256");
  for (const p of [...paths].sort()) {
    try { h.update(p).update(fs.readFileSync(p)); }
    catch { h.update(p).update("<<ABSENT>>"); }
  }
  return h.digest("hex");
}

export const CHECKS = [
  {
    id: "continuity.evidence-ref-required",
    guards: "a continuity link asserted PROVEN without an evidence reference is downgraded — a claim is not its own evidence",
    guarded_source: ["build-os/surfaces/continuity.mjs"],
    source_read: "build-os/surfaces/continuity.mjs via gradeContinuity()",
    source_is_authoritative: true,
    authoritative_source: "build-os/surfaces/continuity.mjs",
    assertion_kind: "invariant",
    failure_demonstrated: true,
    mutation_applied: true,
    failure_proof: "disabled the PROVEN-without-evidence_ref downgrade; 5 assertions failed",
    proof_taken_at: "SELF",
    owner_suite: "tests/continuity_tests.sh",
    drift_risk: "a future caller passing evidence_ref: '' would satisfy the truthiness test without carrying a reference",
  },
  {
    id: "continuity.counterfactual-required",
    guards: "a divergence claim with no counterfactual is downgraded — receipt, echo and paraphrase satisfy 'behaved differently' vacuously",
    guarded_source: ["build-os/surfaces/continuity.mjs"],
    source_read: "build-os/surfaces/continuity.mjs via gradeContinuity()",
    source_is_authoritative: true,
    authoritative_source: "build-os/surfaces/continuity.mjs",
    assertion_kind: "invariant",
    failure_demonstrated: true,
    mutation_applied: true,
    failure_proof: "disabled the counterfactual requirement; 3 assertions failed",
    proof_taken_at: "SELF",
    owner_suite: "tests/continuity_tests.sh",
    drift_risk: "the rule only fires at REPORTED or above, so a link already downgraded skips it — intended, but easy to misread as double coverage",
  },
  {
    id: "continuity.middle-rung-never-collapses",
    guards: "BEHAVIOR_CHANGE_OBSERVED_ACTOR_UNDISAMBIGUATED is never promoted to a pass (operator ruling)",
    guarded_source: ["build-os/surfaces/continuity.mjs"],
    source_read: "build-os/surfaces/continuity.mjs verdict ladder and the PASSING set",
    source_is_authoritative: true,
    authoritative_source: "build-os/surfaces/continuity.mjs",
    assertion_kind: "invariant",
    failure_demonstrated: true,
    mutation_applied: true,
    failure_proof: "collapsed the middle rung (5 failures); separately marked it PASSING (1 failure)",
    proof_taken_at: "SELF",
    owner_suite: "tests/continuity_tests.sh",
    drift_risk: "adding a rung above the middle one without extending PASSING deliberately, which is why PASSING is a set rather than a ladder index",
  },
  {
    id: "identity.resolved-not-declared",
    guards: "actor identity comes from attributable evidence; prose and self-assertion reach no verdict",
    guarded_source: ["build-os/surfaces/actor-identity.mjs", "build-os/surfaces/continuity.mjs"],
    source_read: "resolveActorIdentity() as called by gradeContinuity()",
    source_is_authoritative: true,
    authoritative_source: "build-os/surfaces/actor-identity.mjs",
    assertion_kind: "invariant",
    failure_demonstrated: true,
    mutation_applied: true,
    failure_proof: "restored prose-based resolution (1 failure); accepted a sourceless value as evidence (1 failure)",
    proof_taken_at: "SELF",
    owner_suite: "tests/continuity_tests.sh",
    drift_risk: "a candidate set of exactly one makes every claim resolve trivially — the resolver reports it, but nothing forbids it",
  },
  {
    id: "identity.ambiguity-preserved",
    guards: "underdetermined identity returns every compatible candidate and names the discriminating fields, rather than picking one",
    guarded_source: ["build-os/surfaces/actor-identity.mjs"],
    source_read: "resolveActorIdentity()",
    source_is_authoritative: true,
    authoritative_source: "build-os/surfaces/actor-identity.mjs",
    assertion_kind: "invariant",
    failure_demonstrated: true,
    mutation_applied: true,
    failure_proof: "resolved to the first compatible candidate (7 failures); silenced the computed work order (2 failures)",
    proof_taken_at: "SELF",
    owner_suite: "tests/continuity_tests.sh",
    drift_risk: "a field absent from IDENTITY_FIELDS can never discriminate, so the schema silently bounds what can ever be resolved",
  },
  {
    id: "continuation.terminal-conditions",
    guards: "every registered terminal condition permits the stop instead of throwing",
    guarded_source: ["build-os/motion/continuation.mjs"],
    source_read: "continuationDecision()",
    source_is_authoritative: true,
    authoritative_source: "build-os/motion/continuation.mjs",
    assertion_kind: "invariant",
    failure_demonstrated: true,
    mutation_applied: true,
    failure_proof: "re-introduced the TDZ default parameter; 2 assertions failed",
    proof_taken_at: "SELF",
    owner_suite: "tests/concession_gate_tests.sh",
    drift_risk: "only operator_stop and its reason are asserted by the TDZ case; a new early return could regress unnoticed",
  },
  {
    id: "motion.continuation-outranks-concession",
    guards: "continuation is evaluated before the concession check, so a conceding turn cannot satisfy the concession gate and stop with work remaining",
    guarded_source: ["build-os/motion/gate-stop.mjs"],
    source_read: "the live Stop hook, invoked end-to-end through .claude/hooks/concession-gate.sh",
    source_is_authoritative: true,
    authoritative_source: "build-os/motion/gate-stop.mjs",
    assertion_kind: "invariant",
    failure_demonstrated: true,
    mutation_applied: true,
    failure_proof: "disabled the continuation branch; 3 assertions failed",
    proof_taken_at: "SELF",
    owner_suite: "tests/concession_gate_tests.sh",
    drift_risk: "the drained-queue cases depend on a symlinked gate resolving its imports to the real directory; a resolution change would silently retarget them",
  },

  // ---- HONEST GAPS. Registered precisely because they are NOT proven. ----
  {
    id: "assumptions.registry-coverage",
    guards: "load-bearing assumptions with no validating environment are reported as untested rather than validated",
    guarded_source: ["build-os/assumptions/registry.mjs"],
    source_read: "coverage() over ASSUMPTIONS",
    source_is_authoritative: true,
    authoritative_source: "build-os/assumptions/registry.mjs",
    assertion_kind: "snapshot",
    failure_demonstrated: false,
    mutation_applied: false,
    failure_proof: null,
    proof_taken_at: null,
    owner_suite: "tests/assumption_registry_tests.sh",
    drift_risk: "asserts counts; a legitimate new assumption breaks it and the repair is to bump the number",
  },
  {
    id: "surfaces.repository-activity",
    guards: "layer-1 activity is measured from committed ledger rows against a reproducible anchor, never the wall clock",
    guarded_source: ["build-os/surfaces/readiness.mjs"],
    source_read: "repositorySurfaceActivity() over build-os/kernel/memory_events.tsv",
    source_is_authoritative: true,
    authoritative_source: "build-os/surfaces/readiness.mjs",
    assertion_kind: "invariant",
    failure_demonstrated: false,
    mutation_applied: false,
    failure_proof: null,
    proof_taken_at: null,
    owner_suite: "tests/shell_surface_tests.sh",
    drift_risk: "the anchor falls back to the latest ledger event; an empty ledger yields a null anchor and every surface reads untested",
  },
  {
    id: "learning.disposition-predicates",
    guards: "catastrophic non-action is detected and never routed to execute-class disposition",
    guarded_source: ["build-os/learning/disposition.mjs"],
    source_read: "disposition.mjs predicates over the non-action fixtures",
    source_is_authoritative: true,
    authoritative_source: "build-os/learning/disposition.mjs",
    assertion_kind: "invariant",
    failure_demonstrated: false,
    mutation_applied: false,
    failure_proof: null,
    proof_taken_at: null,
    owner_suite: "build-os/learning/fixtures/non-action.fixtures.mjs",
    drift_risk: "the positive case is synthetic; only the negative cases come from real experiments",
  },
];

/** Resolve stored proofs against today's source. "SELF" means "at this content". */
export function resolvedChecks(checks = CHECKS) {
  return checks.map((c) => {
    const now = fingerprint(c.guarded_source || []);
    return {
      ...c,
      source_fingerprint_now: now,
      // A proof recorded as SELF was taken against the content present when it
      // was run. It is pinned by writing the fingerprint into the proof file,
      // NOT by trusting this line — see build-os/audit/proofs.json.
      proof_taken_at: c.proof_taken_at === "SELF" ? (PINNED[c.id] ?? null) : c.proof_taken_at,
    };
  });
}

// Pinned fingerprints, written when each mutation was executed. If a guarded
// source changes, the pin no longer matches and the check drops to STALE_PROOF
// until someone re-runs the mutation. This is the shelf life, mechanically.
export let PINNED = {};
try {
  PINNED = JSON.parse(fs.readFileSync("build-os/audit/proofs.json", "utf8"));
} catch { PINNED = {}; }
