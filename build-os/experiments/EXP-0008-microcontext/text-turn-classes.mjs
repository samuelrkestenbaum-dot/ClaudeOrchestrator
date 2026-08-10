// STEP 2 — what ARE the excess text-only turns?
//
// EXP-0007/0008 established that the largest single Gravito overhead is turns
// that carry NO tool call: 4.5/arm native vs 16.3/arm corrected. Their
// composition was measured as "unproven" and left there. This classifies them.
//
// METHOD, AND ITS LIMIT STATED FIRST. These are prose, so unlike turn-causes.mjs
// this classifier CANNOT work on structure alone -- it has to read content, and
// content-matching is the failure mode that has bitten this work five times. Two
// things make it safe enough here:
//
//   1. The corpus is the WORKER'S OWN OUTPUT, not a file that describes the
//      pattern being matched. There is no path by which a rule can match the
//      document defining it -- the workers cannot read this file (it lives under
//      build-os/experiments, which administration withholds).
//   2. The SAME classifier runs over both arms. A rule that is wrong in a
//      consistent way still yields a valid DIFFERENTIAL, which is what the
//      question actually asks: which classes exist disproportionately because
//      Gravito is present.
//
// Two of the ten buckets are decided WITHOUT reading content at all:
//   opening_plan  -- the arm's first text turn, whatever it says
//   final_report  -- any text turn of >=1500 chars
// Those two carry most of the signal, and neither can be argued with.
//
// AMBIGUITY IS PRESERVED: no rule matches => `unclassified`, never nearest-fit.

export const CLASSES = [
  "opening_plan",            // the arm's first text turn
  "final_report",            // >=1500 chars: a full deliverable write-up
  "gate_challenge_response", // answering a stop-gate refusal ("the gate is right...")
  "gate_mechanism_diagnosis",// reading Gravito's OWN gate source to learn why it blocks
  "capability_search",       // probing/enumerating surfaces for a missing capability
  "routing_bookkeeping",     // filing routing requests, closing receipts, recording evidence
  "authority_blocked",       // reporting that a tool/permission is refused
  "protocol_narration",      // Lane / Tools / doctrine declarations
  "verification_planning",   // announcing the targeted check
  "product_reasoning",       // the actual type error, schema, code, and navigating to it
  "unclassified",
];

// Ordered. First match wins; the order encodes which reading dominates when a
// turn does two things, and is the main judgement call in this file.
const RULES = [
  ["gate_challenge_response",
    /\b(the )?gate('s)? (is right|was right)|fair challenge|gate is right|right to push back|gate's (own )?(challenge|question|core question) (is|was|deserves)|shouldn't (declare|self-declare)|stopped (early|without)|concluded ["']?(no agency|blocked)|challenge (is|was) fair|my (exhaustion )?claim was wrong|asserted exhaustion/i],
  // Reading Gravito's own implementation to find out why it is refusing. This is
  // the text-turn twin of `gravito_implementation_read` in turn-causes.mjs, and
  // it is the exact behaviour the microcontext prototype was aimed at.
  ["gate_mechanism_diagnosis",
    /gate-stop\.mjs|capability-map|routing-gate\.sh|the hook itself|what the hook (actually )?(validates|reads|expects|wants|needs)|gate's (own )?(mechanics|source|logic|contract|rule|question)|diagnose the mechanism|read (the|what the) (hook|gate)|rather than guess|instead of guessing|falls? back to (the )?default|default fallback|for_conclusion|\bverdict\b.*\bcapability\b|gate (fired again|now names|is reading|consumed|named)|hook now names|still blocking|echoed my/i],
  ["capability_search",
    /untested surface|unsearched|exhaust(ing|ion)? (the )?(remaining )?(surface|route|path)|probing|probe\b|enumerat|allowlist|permission (config|layer|allowlist)|subagent surface|peer (session|bridge)|another surface|cross-surface|surfaces I|distinct executables|invocation forms|capability(-| )map|gate-stop\.mjs|registry has|no (registered )?holder|which surface/i],
  ["routing_bookkeeping",
    /routing request|routing receipt|routing channel|filing (it|the)|writing (it|the routing)|issuing the routing|closing the receipt|close the receipt|recording (the )?(evidence|enumeration|an? evidence)|record(ing)? it as the gate|evidence (file|recorded|updated)|updating the artifact|receipt (closed|consumed)|escalation record/i],
  // Loosened after audit: the first version demanded the verb sit next to the
  // noun, so "The Bash TOOL is gated" and "Both the SHELL AND THE LANGUAGE
  // SERVER are gated" both fell through to unclassified. Allow a short gap.
  ["authority_blocked",
    /\b(bash|npx|node|shell|lsp|serena|typecheck\w*|tsc|routing|language server|the \w+ tool)\b[^.!?]{0,60}?\b(is|are|was|were)\b[^.!?]{0,25}?(gated|blocked|denied|closed|refused|ungranted|unavailable)|needs? (an )?approv|requires? approval|permission wasn't granted|no approver|not on the host|host (denies|restriction|permission|layer)|blocked by (a |the )?(routing )?(gate|hook|permission)|can'?t execute|no execution path|no executable|not available in this (session|host)|is refused|uniformly closed|categorically denied/i],
  ["protocol_narration",
    /\bLane:|\*\*Lane\b|\bTools:|\*\*Tools|direct mode|tiny lane|CLAUDE\.md (mandates|routes)|doctrine/i],
  ["verification_planning",
    /targeted check|verification command|the judged command|now (the|i'll) verify|verify (with|via|by)|let me verify|re-?verify|verifying (the|by)/i],
  // Includes NAVIGATION as well as analysis: "Now the billing-history field:" is
  // product work with no Gravito content, and native emits these too — leaving
  // them unclassified would have inflated the apparent Gravito-specific residue.
  ["product_reasoning",
    /TS\d{4}|\btype (error|argument|annotation|import|derivation)|assignable|infers?\b|schema|column|varchar|cast\b|narrow(ing|s)?\b|generic|interface\b|prop type|root cause|the (real )?(bug|defect|error)|`[A-Z]\w+<|\bunknown\[\]|^(now|next|found)\b[^.!?]{0,70}[:.]?$|let me (find|confirm|check|inspect) (it|the|whether)|apply the fix|the (second|first) site/i],
];

/** Classify one text-only turn. `isFirst` and `chars` are structural. */
export function classifyText(text, isFirst, chars) {
  if (isFirst) return "opening_plan";
  if (chars >= 1500) return "final_report";
  for (const [cls, re] of RULES) if (re.test(text)) return cls;
  return "unclassified";
}

/** Classify a whole extracted corpus (array of {group, arm, text, chars}). */
export function classifyCorpus(turns) {
  const seen = new Set();
  return turns.map((t) => {
    const isFirst = !seen.has(t.arm);
    seen.add(t.arm);
    return { ...t, cls: classifyText(t.text, isFirst, t.chars) };
  });
}
