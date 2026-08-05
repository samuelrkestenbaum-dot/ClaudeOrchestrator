# Provenance of BLINDED_ANALYSIS.md (sibling note — the analysis file itself is verbatim)

The sibling `BLINDED_ANALYSIS.md` is the independent evaluator's report, committed
byte-verbatim (the EXP-0001 reviewer's advisory — provenance in a sibling file, not
inside a "verbatim" document — is honored here). The evaluator was a fresh agent
context given ONLY the blinded X/Y dataset and the preregistered rule in neutral
form: no repository access, no arm names, no arm-order schedule, no dispatch counts
(excluded from the dataset because they would de-blind), no mapping. The mapping's
sha256 was committed at seal time (`916e1ae`), one commit boundary and one closed
packet before this file; the mapping itself enters the tree only in the NEXT commit
and must hash to the pre-committed value.
