# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: IN FLIGHT — `gravito_p3_accept_and_constrain_a`

- **Packet id:** `PACKET-0023-gravito-p3-accept-and-constrain-a`
- **Lane:** substantive — builder → qa → reviewer → archivist.
- **Declared:** 2026-08-01.
- **Decision id:** `DECISION-0009-p3-accept-and-constrain`, recorded with its
  **rejected candidates and their frozen signal snapshots** — see *The n=1
  obligation* below.

## Branch base

Branch `claude/project-handoff-merge-ramhds`, based at `f3c5353` (the close of
`gravito_p2_claim_scoped_evidence_a`). **Verified before the first edit:**
`git rev-parse HEAD` = `f3c5353`, so HEAD *is* the base, the base is an ancestor
of HEAD trivially, and no rebase is implied.

**≤2 commits.** Commit 1 is **this declaration alone** — trivially green in
isolation, because it changes one markdown file and no code path reads it.
Commit 2 carries the tests and the implementation together.

## What this packet builds

Two things, and the second is a standing ruling this packet owns rather than a
discovery made inside it.

### 1. `accept_and_constrain` — a fifth mismatch disposition

The vocabulary becomes `demote_authority | correct_class | improve_evidence |
retire_control | accept_and_constrain`. `disposition` is a **wholly new concept**
in this tree: `grep -rn -i disposition build-os/ tests/` returns zero, so there is
nothing to retrofit and no existing convention to lean on. This packet builds the
vocabulary, its store, its validator and its tests.

`accept_and_constrain` is for a control whose authority is imperfectly licensed
and whose **demotion or removal has been MEASURED to be more dangerous than the
mismatch**. *Measured* is load-bearing. It is not an operator exception that makes
a mismatch disappear:

- **It clears nothing.** The subject keeps `authority_mismatch: declared`, keeps
  its row in `MISMATCHES.md`'s summary table, and keeps its `OUT-OF-LICENCE`
  finding from `evidence-policy.sh check`. All three are asserted against the
  **live** tree, not against a fixture.
- **It raises nothing.** The standing ruling holds: **class correction and
  authority demotion, not a general promotion instrument.**

**It is applied narrowly, and the narrowness is proved.** The fixture pair is
already in the census and it comes with its own negative case:

| control | `demotion_requirement` | expected |
|---|---|---|
| `maint.tripwire_coverage_scan` | **"MEASURED AND REFUSED, not open"** | **qualifies** |
| `maint.source_scan_mask` | "REACHABLE SINCE THE LADDER WAS CORRECTED" | **REFUSED** |

The second row is the discipline test. A disposition that swallows both is
useless, so the refusal must fire **and say why**, quoting the census's own
`demotion_requirement` rather than restating a reason in the tool. If the
predicate cannot tell the two apart, the predicate is fixed — the fixture is not
relaxed. **Disposing one control is the packet; disposing twenty is out of scope.**

### 2. The lease term, enforced against a clock

The residue ruling assigns expiry enforcement to P3. It is not a theoretical
concern: three fixtures were executed against this tree on 2026-08-01 before a
line was written.

- An envelope `starts: 2025-01-01 / expires: 2026-01-01` — **seven months dead** —
  reported `1 live grant(s)` and `WITHIN-LICENCE … l-deployment=execute
  l-effective=gate binding-axis=none`, **EXIT 0**. The word *live* printed about a
  dead grant, and the strongest deployment cap in the system computed from a
  lease that had ended.
- The **same** lease at `deployment_mode: shadow` dragged
  `metrics.record.schema_invariant` — licensed `gate` on both live axes — down to
  `licensed=observe axis=deployment` inside `evidence-policy.sh check`. The second
  live site is **confirmed, not suspected**.
- The same record moved to `starts: 2027-01-01 / expires: 2027-12-31` — five
  months before it opens — bound **byte-identically**. The window was decorative
  at **both** ends.

Root cause: the tool format-checked the dates and ordered them, then never
consulted the clock. `date` appeared in zero tools.

**The defect is framed as: an expired grant keeps applying IN WHICHEVER DIRECTION
IT POINTED.** The restrictive direction is visible; the permissive one is
invisible, because an ungranted control already defaults to
`autonomous`/`execute` — so a test written only against the permissive direction
passes vacuously against a fixed tool and an unfixed one alike. The **restrictive**
fixture is the one with discriminating power, and it is asserted both ways round.

Required: an out-of-window envelope contributes **no grant**; `LAPSED` and
`NOT-YET-LIVE` are reported as **distinct** states and neither is
`WITHIN-LICENCE`; `mode_projection()` does not consume them; `N live` means live;
"now" comes from an overridable source that **says so** when overridden. And
`claim-evidence.sh`'s `valid_until` — which `control_registry.txt` says "is
recorded so a later packet can enforce it" — is enforced here, at **both** ends of
the term, because enforcing one end is the decorative-window defect one artefact
along.

## Out of scope

- Any change to any control's `class`, `runtime_authority`, `empirical_status` or
  `authority_mismatch`. **Zero re-authorisations.**
- Disposing any control other than `maint.tripwire_coverage_scan`.
- Writing a live authority envelope. The store still ships with zero grants.
- Anything outside this repository. **No push, no merge, no PR, no tag, no
  deploy, no secrets, no `git config`.** Six commits are deliberately unpushed and
  stay that way.

## The n=1 obligation

P4's ranker starts at n=1 unless decisions keep recording **rejected** candidates
with signals **frozen at decision time** and never recomputed. There are two
counterfactual data points so far, `DECISION-0007` and `DECISION-0008`.
`DECISION-0009` records four candidates and sixteen frozen snapshots, twelve of
them for the three arms that were **not** selected — including the
`maint.source_scan_mask` rejection, which is a genuinely discriminative example of
the disposition **not** applying.

## Baseline to hold

Suite **1771 / 0** (verified solo, full capture, before the first edit).
Maintenance **144 / 144**. `scan-controls` exit 0. `scan-mutators` exit 0.
`evidence-policy` **25 of 93**, split **6 / 5 / 14** — the numerator and the split
must not move; the denominator may grow as controls are added. Both
`EVIDENCE_AXIS` copies byte-identical at six tokens. 0 stale pathed refs
tree-wide.

**Known trap, not this packet's to fix:** `MISMATCHES.md`'s citations of
`scan-controls.sh` at three sites are stale **at base**. That is pre-existing debt
— it is not fixed silently here and it does not fail this packet's gate.
