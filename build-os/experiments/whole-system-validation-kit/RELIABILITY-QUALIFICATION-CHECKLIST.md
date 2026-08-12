# RELIABILITY QUALIFICATION — what must be DEMONSTRATED (not designed)
# after EXP-0011 closes, before any whole-system freeze. Templates, commits,
# and design review do NOT constitute executed qualification.
Frozen before qualification data: max invalid-run rate __ % ; stopping rule
__ ; qualification n __ .
Must demonstrate by execution:
[ ] serial-vs-wide calibration verdict (EXP-0012 calibrate.mjs; gate refuses
    while any measured-study lock is live) — pass/fail per its precommitted rule
[ ] telemetry logger verify() green over qualification runs (schema, clocks,
    gaps, provider-category completeness)
[ ] intervention/human-minutes metering exercised end-to-end
[ ] acceptance pipeline dry-run: script gate + sanitization + blinded scoring
    on synthetic items, incl. arm-guess capture
[ ] invalid-run rate within frozen ceiling across qualification runs
[ ] environmental-exclusion evidence path exercised once (simulated)
[ ] capsule seal/verify round-trip
Status: DESIGN-READY only. Nothing above executed. Executed-date fields: __
