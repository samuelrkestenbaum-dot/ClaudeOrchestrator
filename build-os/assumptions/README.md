# Self-audit — assumption registry and coverage map

> What must be true for me to work, and which of those truths have I actually
> demonstrated?

The loop this closes: Gravito has been strong at *reacting* to evidence and
weak at *proactively discovering what it has never tested*. Every architectural
defect this substrate has found was found by **execution** — session-ID
inheritance, the ineffective timeout, a permission mode that denied writes, four
publication-authority defects, the bootstrap permission-class mismatch.
Inspection caught only the local implementation errors. So the fix has to be
running counterfactuals, not reviewing harder.

    node build-os/assumptions/self-audit.mjs

Exit 1 on a **violated** load-bearing assumption. An **untested** one is
reported as risk, not failure — unknown is not wrong, and conflating them is how
an unknown gets quietly recorded as a zero.

## DERIVED beats DECLARED, and why

| kind | source | failure mode |
|---|---|---|
| **DERIVED** | read out of the system's own source on every run | cannot drift; can surface an assumption nobody thought of |
| **DECLARED** | asserted by a human | only ever contains what someone already suspected |

That distinction is not theoretical. Post-Outcome Disposition v0 was a declared
rule set: it could describe every failure shape its author had already seen,
then met a new one — a treatment that produced nothing — and had no predicate
for it. A hand-written assumption registry inherits exactly that blind spot.

**So the load-bearing facts are extracted mechanically wherever they can be.**

## The proof that this would have worked

`derive-authority-paths.mjs` reads the routing gate and answers one question:
*to obtain first mutation authority, which tool class must the worker be
permitted to use?* Cross-referenced with a host's permission semantics, that is
enough to predict a total failure before any experiment.

Run against the actual historical artifact — the gate as it stood when EXP-0005
executed — it reports:

    AUTHORITY_PATH_MISMATCH
    The host permits Edit, but EVERY route to earning authority for it requires
    a class the host restricts. A worker able to do the work cannot become
    allowed to do the work.

Against the current gate: `viable`, via the Write-class routing-request channel.

**Nobody had to suspect the defect.** The fact was in the code and in the host
profile; it just had nowhere to be compared. That is the whole thesis of this
subsystem: make the boundary machine-readable so a mismatch is a **diff**, not a
**discovery**.

## Why the mismatch is a type error, not ignorance

Gravito's authority model treats mutation as **one** class. Hosts **stratify**
it — `Edit` cheap, `Bash` expensive. Gravito then made its cheapest authority
depend on the host's most expensive class. Nobody needed to be ignorant of the
host for that to break; the two lattices only needed to disagree about what "a
mutation" is. `host-profiles.mjs` writes the host's lattice down so the two can
be compared.

## Current claims

Six, two DERIVED. `self-audit.mjs` prints the live map; it is not duplicated
here, because a hand-copied status table is a second source of truth that can
disagree with the first.

## What this does NOT do yet

- **The adversarial matrix is not built.** Most cells need a real host or
  provider that cannot be fabricated here. A simulated cell is reported as
  untested rather than validated — the same line drawn on the interactive-host
  arm in task #45.
- **Host profiles are partly asserted.** Each carries `observed_by`; three are
  DIRECT OBSERVATION, three are asserted or untested and say so.
- **Coverage is not completeness.** Six claims is what has been written down.
  The assumptions that hurt are the ones still absent from this file, and no
  registry can report its own omissions.
- **The observational loop is incomplete.** Four-surface readiness remains
  **FAIL**; a registry fed by one surface's traces has blind spots shaped like
  the missing surfaces.
