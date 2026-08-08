// FIXTURES FOR THE CONTINUITY VERIFIER.
//
// The rule this substrate adopted after Post-Outcome Disposition v0 shipped a
// registry containing only what someone already suspected: a new predicate is
// validated against evidence that did NOT inspire it. The NEGATIVE cases below
// are the load-bearing ones — a verifier that only ever says "not proven" is
// exactly as useless as one that always says "proven", and both pass a suite
// made only of the cases they were written for.

export const NEGATIVE = [
  {
    name: "HOF-0001 receipt — the pre-existing case, which did NOT inspire this verifier",
    // This handoff was built, accepted and recorded long before continuity
    // grading existed. It is the honest baseline: real cross-surface transfer,
    // real acceptance, and no evidence of changed behaviour.
    claim: {
      id: "FIX-N1", originating_surface: "claude", consuming_surface: "chatgpt",
      links: {
        origination: { status: "PROVEN", evidence_ref: "EVT-0023" },
        consumption: { status: "PROVEN", evidence_ref: "EVT-0025" },
        behavioral_divergence: { status: "ABSENT" },
        durable_write_back: { status: "ABSENT" },
        onward_consumability: { status: "ABSENT" },
      },
    },
    expect: "CONSUMPTION_ONLY",
  },
  {
    name: "an echo — the consumer restates what it received and nothing else",
    claim: {
      id: "FIX-N2", originating_surface: "claude", consuming_surface: "chatgpt",
      links: {
        origination: { status: "PROVEN", evidence_ref: "EVT-0023" },
        consumption: { status: "PROVEN", evidence_ref: "EVT-0025" },
        // Asserted, but with no counterfactual: a paraphrase satisfies
        // "behaved differently" vacuously, which is why the counterfactual is
        // mandatory rather than encouraged.
        behavioral_divergence: { status: "PROVEN", evidence_ref: "a summary was produced" },
        durable_write_back: { status: "PROVEN", evidence_ref: "the summary was saved" },
        onward_consumability: { status: "PROVEN", evidence_ref: "the summary is readable" },
      },
    },
    expect: "DIVERGENCE_UNFALSIFIABLE",
  },
  {
    name: "self-continuity — one surface reading its own state is not a loop",
    claim: {
      id: "FIX-N3", originating_surface: "claude", consuming_surface: "claude",
      links: {
        origination: { status: "PROVEN", evidence_ref: "x" },
        consumption: { status: "PROVEN", evidence_ref: "y" },
        behavioral_divergence: { status: "PROVEN", evidence_ref: "z", counterfactual: "would not have" },
        durable_write_back: { status: "PROVEN", evidence_ref: "w" },
        onward_consumability: { status: "PROVEN", evidence_ref: "v" },
      },
    },
    expect: "NOT_CROSS_SURFACE",
  },
  {
    name: "bare assertion — every link PROVEN, not one evidence reference",
    // The exact shape the old free-boolean gate accepted and counted.
    claim: {
      id: "FIX-N4", originating_surface: "claude", consuming_surface: "chatgpt",
      links: Object.fromEntries(
        ["origination", "consumption", "behavioral_divergence", "durable_write_back", "onward_consumability"]
          .map((k) => [k, { status: "PROVEN" }]),
      ),
    },
    expect: "NO_TRANSFER",
  },
  {
    name: "divergence with a counterfactual but nothing written back",
    claim: {
      id: "FIX-N5", originating_surface: "claude", consuming_surface: "chatgpt",
      links: {
        origination: { status: "PROVEN", evidence_ref: "a" },
        consumption: { status: "PROVEN", evidence_ref: "b" },
        behavioral_divergence: { status: "PROVEN", evidence_ref: "c", counterfactual: "would have accepted the block", actor: "chatgpt", actor_discriminator: "d" },
        durable_write_back: { status: "ABSENT" },
        onward_consumability: { status: "ABSENT" },
      },
    },
    expect: "DIVERGENCE_UNFALSIFIABLE",
  },
  {
    name: "EXP-0005's Gravito arm — 0 accepted outcomes, so nothing to transfer",
    // Frozen evidence, and about as far from this verifier's design intent as
    // repository evidence gets.
    claim: {
      id: "FIX-N6", originating_surface: "claude", consuming_surface: "chatgpt",
      links: { origination: { status: "ABSENT" }, consumption: { status: "ABSENT" } },
    },
    expect: "NO_TRANSFER",
  },
];

export const POSITIVE = [
  {
    name: "a fully evidenced native loop — proves the ladder can be climbed",
    // Synthetic, and labelled synthetic. Its only job is to show the verifier
    // is capable of returning its top verdict; a checker that cannot pass
    // anything proves nothing when it fails something.
    claim: {
      id: "FIX-P1", originating_surface: "claude", consuming_surface: "chatgpt",
      links: {
        origination: { status: "PROVEN", evidence_ref: "ledger row", actor: "claude", actor_discriminator: "surface_id" },
        consumption: { status: "PROVEN", evidence_ref: "accept row", actor: "chatgpt", actor_discriminator: "actor_id" },
        behavioral_divergence: {
          status: "PROVEN", evidence_ref: "action row", actor: "chatgpt", actor_discriminator: "caller identity on the row",
          counterfactual: "absent the state it would have taken the default branch",
        },
        durable_write_back: { status: "PROVEN", evidence_ref: "outcome row", actor: "chatgpt", actor_discriminator: "actor_id" },
        onward_consumability: { status: "PROVEN", evidence_ref: "third consumer read it", actor: "manus", actor_discriminator: "actor_id" },
      },
    },
    expect: "NATIVE_CONTINUITY",
  },
  {
    name: "the same loop reached through a bridge — must NOT report as native",
    claim: {
      id: "FIX-P2", originating_surface: "claude", consuming_surface: "chatgpt",
      bridge: { via: "chatgpt", attributable_as: "claude.cowork.session" },
      links: {
        origination: { status: "PROVEN", evidence_ref: "ledger row", actor: "claude", actor_discriminator: "surface_id" },
        consumption: { status: "PROVEN", evidence_ref: "accept row", actor: "chatgpt", actor_discriminator: "actor_id" },
        behavioral_divergence: {
          status: "PROVEN", evidence_ref: "action row", actor: "chatgpt", actor_discriminator: "caller identity on the row",
          counterfactual: "absent the state it would have taken the default branch",
        },
        durable_write_back: { status: "PROVEN", evidence_ref: "outcome row", actor: "chatgpt", actor_discriminator: "actor_id" },
        onward_consumability: { status: "PROVEN", evidence_ref: "third consumer read it", actor: "manus", actor_discriminator: "actor_id" },
      },
    },
    expect: "BRIDGE_MEDIATED_CONTINUITY",
  },
];
