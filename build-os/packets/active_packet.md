# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

- **Packet id:** `gravito_evidence_policy_matrix_a`
- **Status:** **built; qa and reviewer returned; fix round applied — awaiting
  re-review.**
- **Lane:** substantive.

## Branch base

- `claude/project-handoff-merge-ramhds` at `6b01173`; verified before building
  (`git merge-base HEAD 6b01173` = `6b01173`, tree clean).

## What it built

The **second axis of the licence table**: `class x empirical_status -> licensed
authority`. README §3 licensed on `class` alone, so a control's
`empirical_status` licensed nothing and forbade nothing, and a control measured
and found not to discriminate could stop a build with no rule objecting.

- `build-os/registry/README.md` **§3a** — the evidence axis, the composed grid,
  and the composition rule stated explicitly: `licensed = MIN(class-licensed,
  evidence-licensed)`. Extends §3; does not replace it.
- `build-os/tools/evidence-policy.sh` (new) — `matrix` prints the model, `check`
  **derives** the out-of-licence set from the registry. **No control id appears
  in its source.**
- `tests/evidence_policy_tests.sh` (new, 67 assertions), chained from
  `tests/build_os_tests.sh`. §5a — added in the fix round — reconciles README
  §3a's evidence **cap** table against the tool's `EVIDENCE_AXIS` in both
  directions; without it the README's copy of the caps was guarded by nothing.
- Three entries registered: `evidence.policy_matrix` (C, `advise`, mismatch
  **none**), `evidence.derivation_nonvacuity` (A, `gate`),
  `suite.evidence_policy` (A, `gate`). Census **75 → 78**.

## The finding — derived, not remembered

**19 of 78 out of licence.** 14 are the class axis's existing declared
mismatches, reproduced exactly. **5 are visible only to the evidence axis**:
four class-A gates on `unvalidated` evidence carrying `authority_mismatch:
none`, plus `maint.source_scan_mask` advising on `refuted` evidence. **1**
control gates on `refuted` evidence (`maint.tripwire_coverage_scan`) — already
declared, but the declaration understates it.

## The authority decision

**The matrix ships at `advise` and does not gate.** It is chosen policy, not a
definition; a matrix that gated on "chosen thresholds may not gate" would be
self-refuting. Gating would demote 19 controls automatically with no operator in
the loop, and the authority envelope that would make that legitimate is **step 2
and does not exist yet**.

**Nothing was re-authorised.** No existing control's `class`,
`runtime_authority`, `authority_mismatch` or `empirical_status` changed.

## Out of scope, and deliberately not done

Any change to an existing control's authority (steps 2 and 3),
`build-os/memory/*` (archivist territory), `/home/user/empathiq-website`.
**Nothing pushed, merged, tagged or deployed. Local commits only.**

---
_Written by the builder on handback. The archivist clears this file on close._
