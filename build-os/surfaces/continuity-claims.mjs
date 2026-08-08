// THE CONTINUITY CLAIMS ON RECORD.
//
// These are claims, not verdicts. Each is graded by continuity.mjs, and the
// grade is allowed to come out weaker than the claim hoped — which is the only
// reason recording them separately is worth anything.
//
// NOTHING HERE IS SYNTHETIC. No surface is simulated and then called active,
// and no row was written to make a number move.

export const CLAIMS = [
  {
    id: "CONT-0001",
    subject: "HOF-0001 — Claude compiles governed project state, ChatGPT accepts the handoff",
    originating_surface: "claude",
    consuming_surface: "chatgpt",
    links: {
      origination: {
        status: "PROVEN",
        evidence_ref: "build-os/kernel/memory_events.tsv EVT-0023 HandoffCreated by claude.cowork.session.ramhds; build-os/kernel/exports/HANDOFF-0001-chatgpt-strategy.md",
        actor: "claude",
        actor_discriminator: "surface_id recorded on the digest-chained ledger row",
      },
      consumption: {
        status: "PROVEN",
        evidence_ref: "build-os/kernel/memory_events.tsv EVT-0024 ContextCompiled + EVT-0025 HandoffAccepted by chatgpt.web.session.strategy-01",
        actor: "chatgpt",
        actor_discriminator: "distinct actor_id ACT-0003 and surface_id on the ledger row",
      },
      // DELIBERATELY ABSENT, and this is the finding rather than an omission.
      // The handoff was accepted. Acceptance is receipt. Nothing recorded shows
      // ChatGPT then did something it would not otherwise have done.
      behavioral_divergence: { status: "ABSENT" },
      durable_write_back: { status: "ABSENT" },
      onward_consumability: { status: "ABSENT" },
    },
  },

  {
    id: "CONT-0002",
    subject: "The Operator Lab bridge — a Claude-originated FALSE concession is consumed, rejected, and overturned",
    originating_surface: "claude",
    consuming_surface: "chatgpt",
    // The originator did NOT reach the live control plane natively. Saying so
    // here is what stops this being reported as native Claude Lab access.
    bridge: { via: "chatgpt", attributable_as: "claude.cowork.session / anthropic / claude", status: "PROVEN" },
    links: {
      origination: {
        status: "PROVEN",
        evidence_ref: "build-os/surfaces/CLAUDE-WRITE-PATH-BLOCKED.md at commit fdbbdd3, plus the registry entry claude-can-write-live-control-plane recorded status=violated",
        actor: "claude",
        actor_discriminator: "authored in this repository by the Claude session; the commit is attributable",
      },
      consumption: {
        status: "REPORTED",
        evidence_ref: "build-os/surfaces/CLAUDE-WRITE-PATH-BLOCKED.md SUPERSEDED section — the response addressed this document's specific conclusion and named the two interfaces it had missed",
        actor: "chatgpt_or_operator",
      },
      behavioral_divergence: {
        status: "REPORTED",
        evidence_ref: "Operator Lab ledgerId 36263 and 36264 — these rows exist only as a consequence of the enumeration, and did not exist before it",
        actor: "chatgpt_or_operator",
        // NAMED, and it is the load-bearing part of this claim.
        counterfactual:
          "Absent the Claude-originated blocked-state there is no concession to reject and no Lab enumeration is " +
          "triggered. The default had ALREADY OCCURRED and was the opposite: #49 stood recorded as blocked, the " +
          "registry carried status=violated, and the queue was held. The divergence is the rejection of an " +
          "accepted concession, followed by an exhaustive interface search that produced live rows.",
        // NOT SUPPLIED, deliberately. Repository evidence cannot separate
        // "ChatGPT performed the enumeration" from "the operator performed it",
        // and the operator's own account is first-person. Naming a
        // discriminator here would be the fudge this whole subsystem exists to
        // prevent, so the claim is allowed to grade one rung lower instead.
        actor_discriminator: null,
        // WHERE THE DISCRIMINATOR LIVES. It is not missing from the system,
        // only from this surface: the Lab records a calling identity on the
        // rows the enumeration produced. One query against the Lab store for
        // the caller identity on 36263/36264 settles it. This repository has
        // no Lab read path, which is the SAME layer-2 access gap already on
        // record — so the item is a fetch someone else can perform, not an
        // unobtainable fact.
        discriminator_location: "Operator Lab store — calling identity recorded on ledgerId 36263/36264; obtainable by an operator or via the proven chatgpt bridge, not from this repository",
      },
      durable_write_back: {
        status: "REPORTED",
        evidence_ref: "Operator Lab ledgerId 36263 (Claude-attributed interaction) and 36264 (outcome), attributed as claude.cowork.session / anthropic / claude; live readiness moved ChatGPT-only -> Claude + ChatGPT under the UNCHANGED gate",
        actor: "chatgpt",
        actor_discriminator: "the Lab rows carry agent attribution; the gate that changed verdict was not modified",
      },
      // The strongest link, and the only one this repository can verify
      // mechanically rather than take on report.
      onward_consumability: {
        status: "PROVEN",
        evidence_ref: "build-os/motion/capability-map.mjs records the bridge as PROVEN; build-os/motion/gate-stop.mjs READS that map at runtime to generate its refusal, so the live Stop gate's output differs because of the Lab result; build-os/assumptions/registry.mjs moved violated -> partially_validated",
        actor: "gravito_repository",
        actor_discriminator: "mechanical — tests/concession_gate_tests.sh exercises the refusal text generated from the map",
      },
    },
  },
];
