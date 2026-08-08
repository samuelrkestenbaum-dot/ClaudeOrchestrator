// MECHANICAL ACTOR IDENTITY RESOLUTION.
//
// THE RULE THIS ENFORCES: actor identity is resolved from attributable
// evidence, never from prose. "The operator said ChatGPT did it" is a sentence,
// and a sentence about an actor is not an observation of that actor. The
// previous grade depended on a hand-written `actor_discriminator` string, which
// means a claim could disambiguate itself by asserting that it had — the same
// self-granting shape found in publication authority and in the free-boolean
// continuity gate.
//
// The eight attributable fields. A resolution uses these and nothing else:
//
//   surface_identifier   which surface instance made the call
//   provider             which provider served it
//   model                which model produced it
//   originating_event    the event that created the consumed state
//   receiving_event      the event recording consumption
//   gate_invocation      a gate/interface call made during the behaviour
//   durable_write_back   the durable row the behaviour produced
//   causal_linkage       what ties originating state to the changed action
//
// WHEN THE EVIDENCE UNDERDETERMINES THE ANSWER, THE AMBIGUITY IS THE OUTPUT.
// The resolver does not pick a winner, and it does not shrug either: it returns
// every candidate still compatible AND names the specific fields that would
// separate them. An unresolved identity therefore carries its own work order.

export const IDENTITY_FIELDS = [
  "surface_identifier",
  "provider",
  "model",
  "originating_event",
  "receiving_event",
  "gate_invocation",
  "durable_write_back",
  "causal_linkage",
];

/** A field is OBSERVED only when it carries a value AND a source outside the claim. */
const observed = (f) => !!(f && f.value !== undefined && f.value !== null && f.value !== "" && f.source);

/**
 * @param {object} evidence   { <field>: { value, source } }
 * @param {Array}  candidates [{ id, expects: { <field>: value | value[] } }]
 *
 * `expects` states what each candidate WOULD produce. A candidate silent on a
 * field is compatible with any value for it — silence is not a match, and it is
 * not a mismatch either.
 */
export function resolveActorIdentity(evidence = {}, candidates = []) {
  const present = IDENTITY_FIELDS.filter((f) => observed(evidence[f]));
  const missing = IDENTITY_FIELDS.filter((f) => !observed(evidence[f]));

  const matches = (exp, val) => (Array.isArray(exp) ? exp.includes(val) : exp === val);

  const compatible = candidates.filter((c) =>
    present.every((f) => c.expects?.[f] === undefined || matches(c.expects[f], evidence[f].value)));

  // A missing field DISCRIMINATES only if the still-compatible candidates would
  // actually differ on it. Listing every absent field as "more evidence needed"
  // would be noise, and noise is what makes a work order get ignored.
  const discriminating = missing.filter((f) => {
    const stated = compatible.filter((c) => c.expects?.[f] !== undefined);
    if (stated.length < 2) return stated.length === 1 && compatible.length > 1;
    const shapes = new Set(stated.map((c) => JSON.stringify(c.expects[f])));
    return shapes.size > 1;
  });

  const resolved = compatible.length === 1 ? compatible[0].id : null;

  return {
    artifact: "actor_identity_resolution",
    resolved,
    // DISAMBIGUATED is earned by evidence narrowing the field to one candidate,
    // never by a claim saying it is disambiguated.
    status: resolved ? "DISAMBIGUATED"
      : (compatible.length === 0 ? "NO_COMPATIBLE_CANDIDATE" : "UNDISAMBIGUATED"),
    candidates_considered: candidates.map((c) => c.id),
    compatible_identities: compatible.map((c) => c.id),
    evidence_present: present,
    evidence_missing: missing,
    // The work order: exactly what to fetch, and nothing that would not help.
    discriminating_evidence: discriminating,
    note: resolved
      ? `evidence narrows the acting party to '${resolved}'`
      : compatible.length === 0
        ? "no candidate is compatible with the observed evidence — the candidate set is wrong, or the evidence is"
        : `${compatible.length} identities remain compatible: ${compatible.map((c) => c.id).join(", ")}. ` +
          (discriminating.length
            ? `Fetching ${discriminating.join(", ")} would separate them.`
            : "No LISTED field would separate them — the candidates are indistinguishable under this schema, which is itself the finding."),
  };
}
