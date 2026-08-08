// CROSS-SURFACE BEHAVIOURAL CONTINUITY — the verifier.
//
// WHAT WAS WRONG WITH THE PREVIOUS GATE. `behavioralContinuity()` accepted
// proofs shaped `{ behaviour_changed: true, result_written_back: true }` and
// counted them. Both fields are free booleans supplied by the party making the
// claim, so the strongest state this substrate can report was settled by
// whoever typed `true`. That is the same defect shape as publication authority
// before it was wired and as every other rule here that turned out to be only
// a model: a claim serving as its own evidence.
//
// THE FIVE LINKS. Continuity is a chain, and a chain reports the weakest link
// rather than the strongest:
//
//   1. origination           A produced durable, attributable state
//   2. consumption           B demonstrably READ it — not "could have"
//   3. behavioral_divergence B did something it would NOT otherwise have done
//   4. durable_write_back    B's action produced durable attributable state
//   5. onward_consumability  a third consumer read that result and changed
//
// Link 3 is the whole point and the one always fudged. Receipt, acknowledgment,
// paraphrase and echo are all equally insufficient, because each is compatible
// with the receiving surface doing exactly what it would have done anyway.
//
// TWO RULES DO ALL THE WORK, and both exist because a claim is not its own
// evidence:
//
//   * a link asserted PROVEN with no evidence reference is DOWNGRADED, never
//     accepted at its asserted strength;
//   * link 3 additionally requires a COUNTERFACTUAL — what the actor would
//     have done absent the state. "It behaved differently" with no stated
//     alternative is unfalsifiable, and an unfalsifiable claim cannot be the
//     top of a ladder.
//
// The verdict ladder ends at a CLASSIFICATION, not a boolean, because the
// interesting real cases fail in specific ways that a boolean erases.

export const LINKS = [
  "origination",
  "consumption",
  "behavioral_divergence",
  "durable_write_back",
  "onward_consumability",
];

// Ordered weakest to strongest. PROVEN means an evidence reference resolves to
// something outside the claim itself; REPORTED means a source stated it;
// INFERRED means somebody concluded it, which is not an observation.
export const EVIDENCE_STATUS = ["ABSENT", "INFERRED", "REPORTED", "PROVEN"];

export const VERDICTS = [
  "NOT_CROSS_SURFACE",
  "NO_TRANSFER",
  "CONSUMPTION_ONLY",
  "DIVERGENCE_UNFALSIFIABLE",
  "CONTINUITY_ACTOR_UNDISAMBIGUATED",
  "BRIDGE_MEDIATED_CONTINUITY",
  "NATIVE_CONTINUITY",
];

const rank = (s) => Math.max(0, EVIDENCE_STATUS.indexOf(s));
const atLeast = (link, s) => rank(link?.status) >= rank(s);

/**
 * Grade one continuity claim.
 *
 * @param {object} claim
 *   originating_surface, consuming_surface : surface families
 *   bridge      : { via, attributable_as } when the originator acted through
 *                 another surface rather than natively
 *   links       : { <link>: { status, evidence_ref, actor, actor_attribution,
 *                             counterfactual } }
 */
export function gradeContinuity(claim = {}) {
  const links = claim.links || {};
  const graded = {};
  const downgrades = [];

  for (const name of LINKS) {
    const l = links[name] || { status: "ABSENT" };
    let status = EVIDENCE_STATUS.includes(l.status) ? l.status : "ABSENT";

    // RULE 1 — a claim is not its own evidence. PROVEN without a reference
    // pointing outside the claim is an assertion wearing a stronger word.
    if (status === "PROVEN" && !l.evidence_ref) {
      status = "INFERRED";
      downgrades.push(`${name}: asserted PROVEN with no evidence_ref — downgraded to INFERRED; a claim is not its own evidence`);
    }

    // RULE 2 — divergence without a counterfactual is unfalsifiable. "B behaved
    // differently" is only meaningful against a stated alternative behaviour.
    if (name === "behavioral_divergence" && rank(status) >= rank("REPORTED") && !l.counterfactual) {
      status = "INFERRED";
      downgrades.push("behavioral_divergence: no counterfactual supplied — downgraded; without a stated alternative behaviour the claim cannot be falsified, and receipt/echo/paraphrase all satisfy it vacuously");
    }

    graded[name] = {
      status,
      asserted_status: l.status ?? "ABSENT",
      evidence_ref: l.evidence_ref ?? null,
      actor: l.actor ?? null,
      // Attribution is only DISAMBIGUATED when a discriminator is named. "It
      // was ChatGPT" with nothing separating ChatGPT from the operator relaying
      // it is a guess about which of two actors performed the behaviour.
      actor_attribution: l.actor_discriminator ? "DISAMBIGUATED" : "UNDISAMBIGUATED",
      actor_discriminator: l.actor_discriminator ?? null,
      counterfactual: l.counterfactual ?? null,
    };
  }

  const from = claim.originating_surface;
  const to = claim.consuming_surface;

  let verdict;
  const reasons = [];

  if (!from || !to || from === to) {
    verdict = "NOT_CROSS_SURFACE";
    reasons.push(`originating and consuming surface are '${from}' and '${to}' — continuity across one surface is just that surface operating`);
  } else if (!atLeast(graded.origination, "REPORTED") || !atLeast(graded.consumption, "REPORTED")) {
    verdict = "NO_TRANSFER";
    reasons.push("origination or consumption is not established — nothing crossed, so no later link can be assessed");
  } else if (!atLeast(graded.behavioral_divergence, "REPORTED")) {
    // The pre-existing state of this system, and the honest default.
    verdict = graded.behavioral_divergence.asserted_status !== "ABSENT"
      ? "DIVERGENCE_UNFALSIFIABLE" : "CONSUMPTION_ONLY";
    reasons.push(graded.behavioral_divergence.asserted_status !== "ABSENT"
      ? "behavioural divergence was claimed but does not survive grading — receipt is not continuity"
      : "state was received and no behavioural divergence is claimed — receipt is not continuity");
  } else if (!atLeast(graded.durable_write_back, "REPORTED") || !atLeast(graded.onward_consumability, "REPORTED")) {
    verdict = "DIVERGENCE_UNFALSIFIABLE";
    reasons.push("divergence is claimed, but it did not produce durable attributable state a further consumer can read — a behaviour change nobody can consume closes no loop");
  } else if (graded.behavioral_divergence.actor_attribution !== "DISAMBIGUATED") {
    // The link that decides WHICH surface the claim is about. Getting all five
    // links and still not knowing who acted is a real, common, and reportable
    // outcome — not a pass.
    verdict = "CONTINUITY_ACTOR_UNDISAMBIGUATED";
    reasons.push(`every link holds, but the actor behind the divergence is not disambiguated: '${graded.behavioral_divergence.actor}' is not separated from other actors who could have performed it`);
  } else {
    verdict = claim.bridge ? "BRIDGE_MEDIATED_CONTINUITY" : "NATIVE_CONTINUITY";
    reasons.push(claim.bridge
      ? `all five links hold, but ${from} reached the write-back THROUGH ${claim.bridge.via} — this is bridge-mediated continuity and must not be reported as native`
      : `all five links hold and ${from} acted natively`);
  }

  // A verdict that only withholds is half a tool. Naming the ONE thing that
  // would advance the grade turns "not proven" into an executable step, and it
  // keeps the same discipline the concession gate enforces: a gap absent from
  // THIS surface is not a gap absent from the system.
  const NEXT = {
    NOT_CROSS_SURFACE: "name two genuinely different surface families, or withdraw the claim",
    NO_TRANSFER: "establish that the consuming surface READ the state — a reference it could have read is not a reading",
    CONSUMPTION_ONLY: "identify a behaviour the consumer would NOT have performed absent the state, and state the counterfactual",
    DIVERGENCE_UNFALSIFIABLE: "supply the counterfactual, and durable state a further consumer can read",
    CONTINUITY_ACTOR_UNDISAMBIGUATED:
      "supply an actor_discriminator for behavioral_divergence — evidence separating the named actor from every " +
      "other actor who could have performed it. Absence from THIS surface is not absence from the system: if the " +
      "acting identity is recorded in a store this surface cannot read, the discriminator exists and must be " +
      "fetched, through a proven bridge if necessary, rather than treated as unobtainable",
    BRIDGE_MEDIATED_CONTINUITY: "obtain native access for the originating surface; the bridge proves the capability exists, not that the surface holds it",
    NATIVE_CONTINUITY: null,
  };

  return {
    artifact: "continuity_grade",
    claim_id: claim.id ?? null,
    missing_to_advance: NEXT[verdict] ?? null,
    originating_surface: from ?? null,
    consuming_surface: to ?? null,
    bridge: claim.bridge ?? null,
    verdict,
    links: graded,
    downgrades,
    weakest_link: LINKS.reduce((w, n) => rank(graded[n].status) < rank(graded[w].status) ? n : w, LINKS[0]),
    reasons,
    principle:
      "Continuity reports its WEAKEST link. Receipt is not behaviour change, an assertion is not evidence, " +
      "and a behaviour change whose actor cannot be identified does not tell you which surface is continuous.",
  };
}

/** Grade many claims; the system's state is the strongest verdict any claim earns. */
export function continuityState(claims = []) {
  const grades = claims.map(gradeContinuity);
  const best = grades.reduce(
    (b, g) => (VERDICTS.indexOf(g.verdict) > VERDICTS.indexOf(b) ? g.verdict : b),
    "NO_TRANSFER",
  );
  return {
    artifact: "cross_surface_behavioral_continuity",
    claims: grades.length,
    state: grades.length ? best : "NOT_DEMONSTRATED",
    by_verdict: VERDICTS.reduce((o, v) => {
      const n = grades.filter((g) => g.verdict === v).length;
      if (n) o[v] = n;
      return o;
    }, {}),
    grades,
    note:
      "The system's state is the STRONGEST verdict any single claim earns, because one closed loop is a " +
      "capability. It is not an average, and a pile of CONSUMPTION_ONLY claims never sums to continuity.",
  };
}
