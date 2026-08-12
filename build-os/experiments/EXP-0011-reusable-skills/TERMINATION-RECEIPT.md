# EXP-0011 TERMINATION RECEIPT

**"Terminated by owner before 60/60 for operational-priority reasons; no
preregistered verdict; completed arms are exploratory evidence only."**

- Terminated at: 2026-08-12T17:54–17:57 UTC (dispatcher killed 17:54:1x;
  in-flight arm drained to its cell boundary and exited 17:57:31Z).
- Termination mechanism: the clean one — dispatcher (executor.mjs pid 7664)
  stopped so no new arm could launch; the in-flight arm (G3/native rep 2,
  pid 24027) completed normally, wrote its own records, and released the
  measurement lock itself. Nothing was killed mid-cell.
- Completed: **38 final cells** (all admissible; 37 accepted; the one
  non-acceptance is G4/native rep 1, on record since it occurred), plus 2
  preserved first attempts (G4.leanrules.r1.attempt1, M1.leanrules.r1.attempt1)
  — 40 UNIT lines total, fully reconciled in TERMINATION-MANIFEST.json.
- In-flight disposition: drained to completion (became final cell
  G3.native.r2). **Zero partial cells.**
- Missing planned arms: **22** (rep-2 tail from G3.leanrules.r2 onward),
  enumerated in the manifest.
- Reason: owner operational priority (begin the R0 usability program).
- Direction-independence confirmation: termination was ordered by the owner
  for operational-priority reasons; no inferential read had been run, no
  position-matched ratios or treatment comparisons had been computed or
  reported at any point during the study, and the termination decision was
  made without reference to any observed treatment direction.
- The frozen final read was NOT run and must not be run as if complete; any
  future summary of these 38 cells is EXPLORATORY and must report the 22
  missing planned arms.
- Evidence sealed: per-file sha256 for every cell and memory store in
  results/TERMINATION-MANIFEST.json; lock released only after sealing
  (verified: lock file absent, zero experiment processes).
