# The anchor contract — v1, frozen

Evidence citations move from **position** to **content**. This document is the
frozen contract every consumer is updated against; it is written before any
consumer changes so that "compatible" means *compatible with this*, not
compatible with whatever the first converted consumer happened to do.

## Why

A citation of the form `path:line` names a **position**. Positions move for
reasons that have nothing to do with the evidence:

- adding four `chain_suite` calls to `build_os_tests.sh` turned two citations
  into references pointing at comments;
- adding a census exemption to three suites turned five more;
- adding anchor support to `scan-controls.sh` broke ten of its own citations.

All three happened in one session, and the last one happened *inside the packet
that was fixing the problem*. Repair cost is not the worst of it: a positional
ref that survives an edit keeps resolving — to a **different line** — and reports
nothing at all.

## The two events a citation must distinguish

| event | what happened | required behaviour |
|---|---|---|
| **irrelevant movement** | text inserted or deleted elsewhere in the cited file; the cited text is untouched | the citation **SURVIVES** |
| **evidentiary change** | the cited text itself is edited or deleted | the citation **GOES STALE**, loudly |

A line number cannot tell these apart. It breaks on the first and stays silent
on the second — precisely backwards.

## Form

```
path#c:<12 lowercase hex>
```

`hex` is the first 12 characters of `sha256(trimmed line content)`.

**Hex rather than the literal text** because `evidence_refs` are separated by
`;` and split on whitespace by several consumers, so an anchor may not contain
spaces. The human-readable content lives in the ledger, which is what makes a
STALE anchor diagnosable instead of opaque.

## Resolution states

| state | meaning | consumer behaviour |
|---|---|---|
| `RESOLVED` | exactly one non-blank line carries the content | resolve to that line number; apply every existing check (vacuity, ownership, block membership) to it unchanged |
| `AMBIGUOUS` | more than one line carries it | **refuse.** Content naming two lines identifies no object |
| `STALE` | no line carries it | **refuse.** The evidentiary basis is gone |
| `NO_FILE` | the artifact is missing | refuse, as today |

`AMBIGUOUS` and `STALE` are the anchor **working**, not drifting. Neither may be
resolved to a best guess.

## Compatibility

Both forms are legal during the migration. A consumer MUST accept:

- `path:line` — the legacy positional form, unchanged semantics
- `path#c:hex` — the anchored form

Detection is by the literal substring `#c:`. A consumer that cannot resolve an
anchored ref **fails closed** — an unresolvable citation is not a resolved one,
and "my resolver was unavailable" is not "the evidence resolves".

Rejection of the legacy form is **not** part of v1. It becomes possible only
once every consumer in `consumer_inventory.tsv` is anchored-compatible and the
registry carries no positional refs but the recorded refusals.

## Provenance

The migration ledger is **append-only**. Attempt 1's ledger was rewritten on
every run: a re-migration that found nothing to do replaced it with a
refusal-only file and destroyed the old→new mapping for 712 references. The
claim that the mapping was "reversible and auditable" was made by reading the
code rather than executing it, and when finally executed it reversed 0 of 0.

Every row therefore carries:

| field | meaning |
|---|---|
| `migration_version` | which migration wrote the row |
| `control_id` | the entry whose citation changed |
| `old_ref` / `new_ref` | the mapping, both directions usable |
| `status` | `MIGRATED`, `REFUSED`, or `REVERSED` |
| `provenance` | `mechanical_migration` — form converted, evidence NOT re-read |
| `old_line` / `content` | what it pointed at, so a stale anchor is diagnosable |
| `reviewed` | `false` until a human reads the citation and says it is right |
| `stamp` | supplied, never read from the clock |

**A migrated reference is not newly reviewed evidence.** A script may convert a
citation's form; it may not decide the citation is correct. Nothing in the
migration tooling may set `reviewed=true`, and a reversal appends a `REVERSED`
row rather than deleting the row it undoes.

## Phase order — binding

Attempt 1 converted the data first and discovered seventeen unprepared
consumers afterwards.

1. enumerate consumers — **done**, `consumer_inventory.tsv`, 18 found
2. freeze this contract — **this document**
3. append-only ledger with executed forward *and* reverse proof
4. **scanners** (2) — foundational, self-contained
5. **report generators** (4)
6. **suites** (11), in batches grouped by shared parser, each green before the next
7. **registry data** — last, only when every consumer is already compatible

No phase advances over a red predecessor, and no phase converts data.
