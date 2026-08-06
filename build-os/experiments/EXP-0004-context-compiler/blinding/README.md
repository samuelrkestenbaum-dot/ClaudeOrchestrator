# EXP-0004 — BLINDING

The last pre-analysis requirement. EXP-0001/2/3 were credible because the
mapping from analysis labels to execution conditions was sealed and its sha256
committed **before** anyone looked at the numbers. EXP-0004 labels its
measurement records `A` and `B` with no blinding at all — at exactly the point
where the incentive to see a favourable result is strongest.

Nothing here measures the thesis. This is the instrument that decides whether a
measurement of it will be worth anything.

## The separation

The **execution layer may know condition identity** — it has to, in order to
select the right context path. The **acceptance adjudicator** and the
**comparative analyst** may not.

| Role | Sees | Never sees |
|---|---|---|
| execution | everything | — |
| acceptance adjudicator | task id, opaque work-product ref, tests, the acceptance question | condition identity, labels, starting-context bytes, expansion fields, mode names, economics |
| comparative analyst | economics under `Arm X` / `Arm Y` | condition identity; and starting-size/expansion fields until acceptance is frozen |

**Why capsule size is blinded and not just the labels.** An adjudicator who sees
one unit start at 8 KB beside a partner that starts at 180 KB has identified the
two conditions instantly, and every acceptance judgement afterwards is
contaminated. Blinding the size is the cheap half of blinding the experiment,
so the starting-size and expansion fields are absent from the adjudicator view
entirely and withheld from the analyst until acceptance is frozen.

## The order, and one correction to it

    seal -> views -> adjudicate -> [acceptance frozen] -> calculate
         -> anonymous provisional verdict -> full freeze -> reveal -> translate

The operator's freeze list **includes** the anonymous provisional verdict, so
the verdict cannot come after the whole freeze — the two cannot both be first.
Resolved explicitly rather than smoothed over: **acceptance** is frozen first
(the analyst view's freeze flag), the anonymous verdict is computed from the
frozen acceptance plus the economics, and the full fourteen-item snapshot is
taken last. Nothing is computed after its own snapshot; nothing is frozen
before it exists.

## The tools

| File | Does |
|---|---|
| `seal-mapping.mjs` | derives the mapping from a **declared salt + registered rule**, records the rule text, writes `mapping.sealed.json` (withheld) and `mapping.sha256` (committed before the run) |
| `views.mjs` | builds both blinded views, the calculations, and the anonymous provisional verdict; `leakcheck` scans any view |
| `freeze.mjs` | materialises and snapshots the **fourteen** required artifacts |
| `reveal.mjs` | the one-way reveal and the translation into the seven registered outcomes |
| `run-blinded-flow.sh` | the end-to-end demonstration on a **simulated** matched pair |

All are mode 644 and invoked via `node` / `bash`: EXP-0003's suite asserts zero
executables anywhere under `build-os/experiments/`.

## The assignment rule is derived, never sampled

A sampled assignment cannot be re-checked by anyone afterwards, so it is a
promise rather than a proof. Here the assignment is a pure function of a
declared salt and a registered rule, both recorded **inside** the sealed
artifact, so a third party holding it can re-derive every assignment and
confirm nothing was chosen after the data existed. `reproduce` runs exactly
that check and refuses a seal that no longer follows its own recorded rule.

**Two rules are registered and they are not interchangeable.**
`experiment-salt-parity` fixes one bit for the whole experiment, so a label
denotes one coherent condition throughout — **this is what an aggregate
requires**. `task-salt-parity` draws a fresh bit per task; it gives stronger
per-unit opacity, but `Arm X` then denotes a *mixture* of conditions across the
task set and any median over it compares nothing. It seals, but records
`aggregate_analysis_valid: false`, and the analysis tools refuse to aggregate
over it.

## The four reveal conditions

Each is named in the refusal when unmet:

1. the freeze snapshot exists **and validates** against the frozen inputs;
2. the anonymous provisional verdict exists **and is still anonymous** — a
   provisional verdict that already names a registered outcome is the reveal
   happening early under another name;
3. the sealed mapping's sha256 equals the digest **committed before the run**,
   and is **the** seal that produced the frozen verdict (every blinded artifact
   carries the digest of the mapping that produced it, because a self-consistent
   seal is not necessarily the right one, and translating an analysis with
   another run's mapping fails silently);
4. the reveal timestamp is **supplied** — no clock is read, so the audit record
   is reproducible.

## Why the blinding is load-bearing, demonstrated

Before the reveal the analysis says things like *"the token gate is met for
Arm Y"*. That sentence is **true under either mapping**. The suite proves the
consequence directly: the *same* anonymous verdict translates to
`compression only` under one sealed bit and `context compilation harmful` under
the other. The blinded artifact demonstrably does not contain the answer. A
full re-run under the opposite seal recovers the *same* outcome, so relabelling
is invisible — which is the other half of the property.

## Limitations — stated, not buried

- **The salt must be withheld exactly as strictly as the mapping.** Blinded
  artifacts carry the committed mapping digest so the reveal can detect a wrong
  seal. That digest leaks nothing on its own, because recomputing the bit needs
  the salt — and the salt lives inside the withheld sealed file. **Publishing
  the salt before the reveal breaks the blind outright.**
- **Post-freeze, the expansion fields still identify the conditions.** One
  label showing `-` for `expansion_bytes` and `context_expansions` while the
  other shows numbers is a give-away. They are withheld until acceptance is
  frozen, which bounds the damage to the economic stage, but the analyst is not
  blind to condition identity after that point. Blinding them permanently would
  mean withholding fields the analyst is supposed to analyse.
- **`arm_b_starting_context` never reaches either view**, because the field name
  is arm-identifying by construction. AMENDMENT 2's substitution check therefore
  stays in the unblinded execution layer. That is correct — it is an admission
  check, not an analysis — but it does mean one preregistered check is not
  independently re-verifiable from the blinded artifacts.
- **Unit ids appear in both views.** That is deliberate: it is how frozen
  acceptance reaches the economics. It does mean anyone holding *both* views can
  join them. Neither blinded role holds both.
- **"No material increase in rework or intervention"** (AMENDMENT 3.3, criterion
  4) registers no threshold. This tool reads *any* increase as material, which
  is the conservative direction — it can only block a favourable verdict, never
  manufacture one — and blocks `compression only` and `acceleration only` too,
  since 3.3 makes them "subject to the remaining criteria".
- **The whole demonstration is simulated.** `fixtures/` holds five invented
  matched pairs. They exercise the machinery and measure nothing whatsoever
  about context compilation.

## Remaining preregistration ambiguity

AMENDMENT 3.5's minimum of five task-pairs is stated for `supported` and
`context compilation harmful` only. Applied literally — as it is here — a
four-pair run with a large acceptance shortfall in the compiled condition
downgrades to `inconclusive`, which reads oddly for a *harm* finding: the
minimum-n rule exists to stop underpowered claims of success, and applying it
symmetrically to harm may be stricter than intended. It is applied as written
and flagged rather than quietly narrowed. The operator may replace 3.5 before
the run; 3.5 says so itself.
