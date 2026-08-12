# ACCEPTANCE & BLINDING (operationalizes DESIGN rev 2 "Blinding" + PACKET §5)
1. Deterministic behavioral gate (NECESSARY): capsule acceptance script;
   machine verdict; no discretion; runs before any human sees the diff.
2. Blinded review (SUFFICIENT-TO-REJECT on enumerated grounds only):
   sanitized bundle = the SQUASHED unified diff (never the commit graph or
   topology; rev 4 M4) with commit metadata stripped, paths/idents
   normalized where feasible, comments retained ONLY if rubric scores
   documentation (tradeoff named per bundle); shuffled order; no builder
   transcripts. Grounds: correctness-fit, safety, maintainability,
   regression risk — each scored 0–2 against written anchors.
3. Weighted value: stratum weight (PACKET §4) × accepted; reported beside
   unweighted.
4. Quality gate: noninferiority margin per PACKET §2; the four vetoes checked
   per item; any veto → claim-void record, both analyses.
5. Assessor arm-guess: forced guess + confidence per item; identification
   rate reported with results (DESIGN rev 2).
6. Disagreement: second blinded reviewer; persisting → rubric precedence
   rule (gate necessary; review rejects only on enumerated grounds);
   builders never unblinded; adjudication log kept.
7. Evidence bundle per item: capsule sha, script output, sanitized diff,
   scores, guesses, adjudication trail — sufficient for third-party re-review.
