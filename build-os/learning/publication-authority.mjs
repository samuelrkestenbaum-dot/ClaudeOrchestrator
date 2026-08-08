// Publication authority — three distinct questions that were being answered as
// one.
//
// THE EPISODE THAT CAUSED THIS. An operator authorised publishing one commit.
// That commit's parent was an unfinished EXP-0005 preregistration marked DRAFT.
// Git cannot publish a commit without its ancestry, so the authorised push
// would also make the draft reachable. The substrate refused and asked, because
// its authorisation model held a SHA and nothing else.
//
// The refusal was defensible and the interruption was not necessary. The model
// was commit-centric where it should have been intent-centric: what was
// authorised was *the completed work*, and a draft becoming reachable is a
// topology consequence, not a state change.
//
// THE THREE QUESTIONS, kept apart:
//
//   1. CONTENT authorisation   — may this change be published?
//   2. TOPOLOGY consequence    — what else becomes reachable if it is?
//   3. STATE-TRANSITION authorisation
//                              — does publishing change an artifact's STATUS
//                                (draft -> frozen, proposed -> approved,
//                                 open -> closed)?
//
// (1) and (3) need authority. (2) does not, PROVIDED it causes no (3).
// Publishing a draft artifact is not the same operation as approving it.

export const VERDICTS = ["proceed", "ask_operator"];

// An artifact whose own text says it is unfinished. Publication cannot be
// mistaken for approval when the artifact itself announces otherwise.
export const DRAFT_MARKERS = [
  /^\s*\*\*Status:\s*DRAFT/im,
  /\bDRAFT\b.*\bnot frozen\b/i,
  /\breadiness\b[^\n]*\b0\s*(of|\/)\s*\d+/i,
  /\bnothing may execute until\b/i,
  /\bnot executed\b/i,
];

// Claims that a status has already been conferred. If an incidental ancestor
// asserts one of these, publishing it DOES effect a state transition, and that
// needs its own authorisation.
export const STATUS_CLAIMS = [
  { pattern: /\bstatus:\s*(frozen|approved|final|executed)\b/i, claim: "declares itself frozen/approved/final/executed" },
  { pattern: /\bthis preregistration is frozen\b/i, claim: "declares a preregistration frozen" },
  { pattern: /\bauthoris(?:ed|ation) granted\b/i, claim: "declares an authorisation granted" },
  { pattern: /\bpacket\s+closed\b/i, claim: "declares a packet closed" },
  { pattern: /\bready to execute\b/i, claim: "declares readiness to execute" },
];

/** Does this artifact text announce that it is unfinished? */
export function isClearlyDraft(text = "") {
  return DRAFT_MARKERS.some((re) => re.test(text));
}

/** Does publishing this artifact assert a status it has not been granted? */
export function statusClaims(text = "") {
  return STATUS_CLAIMS.filter((s) => s.pattern.test(text)).map((s) => s.claim);
}

/**
 * Decide whether an authorised publication may carry its incidental ancestors.
 *
 * @param {object} req
 *   authorized      {string}  what the operator actually authorised (intent, not a SHA)
 *   incidental      {Array}   [{ ref, description, text }] — ancestors that become reachable
 *   confers_status  {boolean} does the publication itself confer a status? (default false)
 */
export function publicationCheck(req) {
  const incidental = req.incidental || [];
  const reasons = [];
  const blocking = [];

  reasons.push(`content authorisation: '${req.authorized}' — granted by the operator`);

  // A state transition needs its own authorisation — and CAN have one.
  //
  // The first version blocked on `confers_status` unconditionally, which made
  // the flag unusable: an operator who explicitly authorised a freeze had no way
  // to say so, and the only route to a push was to declare `confers_status:
  // false` — i.e. to misdescribe what the publication does. A guard that can
  // only be satisfied by lying to it is not a guard.
  //
  // Doctrine says questions (1) and (3) BOTH need authority, not that (3) can
  // never have it. So the block now fires on an UNAUTHORISED transition only,
  // and the authorisation must name the transition rather than be a bare `true`
  // — an operator go for "publish this" is not a go for "and mark it frozen".
  if (req.confers_status === true) {
    const t = req.status_transition_authorized;
    if (typeof t !== "string" || t.trim().length < 8) {
      blocking.push(
        "the publication itself confers a status (state transition), and no authorisation for that transition was " +
        "supplied — set `status_transition_authorized` to the operator's words granting it");
    } else {
      reasons.push(`state transition authorised by the operator: '${t.trim()}'`);
    }
  }

  for (const a of incidental) {
    const claims = statusClaims(a.text || "");
    const draft = isClearlyDraft(a.text || "");
    if (claims.length) {
      blocking.push(`incidental '${a.ref}' ${claims.join("; ")} — publishing it would effect a state transition`);
    } else if (draft) {
      reasons.push(`incidental '${a.ref}': clearly marked unfinished, so reachability is a topology consequence, not approval`);
    } else if (a.text === undefined || a.text === null) {
      blocking.push(`incidental '${a.ref}': content not supplied, so its status cannot be checked — an unchecked ancestor is not a cleared one`);
    } else {
      blocking.push(`incidental '${a.ref}': neither clearly draft nor status-free — cannot be published as a side effect`);
    }
  }

  return {
    artifact: "publication_authority_check",
    verdict: blocking.length ? "ask_operator" : "proceed",
    authorized: req.authorized,
    incidental: incidental.map((a) => a.ref),
    reasons,
    blocking,
    principle:
      "Content authorisation, topology consequence and state-transition authorisation are three different " +
      "questions. Publishing a draft artifact is not the same operation as approving it. Only a state " +
      "transition — or an ancestor that would assert one — requires a fresh go.",
  };
}
