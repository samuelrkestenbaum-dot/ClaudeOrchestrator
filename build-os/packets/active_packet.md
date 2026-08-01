# Active Packet

> The one packet currently in flight. The orchestrator reads this every session;
> the builder implements exactly this and nothing else; the archivist clears it
> on close. One packet at a time.

## Status: IN FLIGHT — `gravito_p1_mutators_ids_telemetry_a`

**Declared 2026-08-01.** Base `7daedee` (verified: `git merge-base HEAD 7daedee`
= `7daedee`, so the branch base is correct and nothing was built on a stale one).
Branch `claude/project-handoff-merge-ramhds`. Lane **substantive**, ≤2 commits,
Commit-1 green in isolation.

**Objective.** Make every known repository mutator visible to the authority
model, and begin collecting structured decision data now. This is deliberately
**not registry-only work**: it must leave behind the first durable data
structures a later ranking stage can consume.

**Five sub-objectives**, each carrying its own tests:

1. **Register the mutators** (4.2). The five named in the brief —
   `rotate-memory.mjs`'s rename onto the live memory file, `swarm-merge.sh`'s
   commit behind `--commit`, `record-packet.sh`'s append to the metrics store,
   the identity hook's stamp write, `specialist-handoff.sh`'s lock — **confirmed
   by an independent survey, not trusted from the list.** Classified on what each
   actually guarantees, never assumed Class A.
2. **Stable identity at birth** (4.3). The smallest ID substrate this repository
   actually requires. **Not** the persistent memory kernel.
3. **Structured defect-class identity** (4.4). Recurrence out of prose and into a
   store that answers `query(defect_class_id)` mechanically.
4. **Baseline decision telemetry** (4.5). Unknowns stay unknown; they never
   become zero.
5. **Decision-time signal snapshots** (4.6). Frozen at decision time, so a later
   evaluation cannot recompute history against the current tree.

## What the survey found, and where it CONTRADICTS the brief

**The list of five is confirmed but INCOMPLETE, and this is recorded rather than
quietly widened.** A content scan of `build-os tests .claude/hooks` for durable
writes (`renameSync`/`writeFileSync`/`copyFileSync`, `git commit`, appends to a
named store, `mkdir` of a lock or marker) returns the five **plus two more**:

- **`.claude/hooks/hook-once.sh:50`** — `mkdir "$base/$key"`, the atomic
  first-firing marker. It is *already registered*, as `hooks.once_dedup`, but
  registered **as the decision** (first-firing / already-fired), not as the
  write. Its marker lives under `TMPDIR` and dies with it, which is exactly the
  shape of `specialist-handoff.sh`'s lock — and the lock IS on the brief's list.
  Treating one as a mutator and not the other would be an arbitrary line.
- **`build-os/maintenance/install-maintenance.sh:79`** — `cp` into an installed
  repo, already registered as **`maint.managed_set_replacement`**, the one
  existing entry that classifies a *write action* rather than a *refusal*.

**Four candidates were REJECTED after inspection, so the survey's negative result
is stated too.** `scan-controls.sh` and `authority-envelope.sh` append only to an
`mktemp` file that dies on `trap`; `check-adoption.sh` and `bandwidth-check.sh`
use `git cat-file -e` / `git rev-parse`, which read. None of the four mutates
anything durable.

**The sharpest thing the survey found:** every existing control whose
`owning_module` is one of the five mutators classifies **the check, not the
write** — `swarm.disjointness`, `metrics.record.schema_invariant`,
`tools.handoff_lock`, `maint.rotation_conservation`. So the brief's claim is
exact: the write actions themselves are registered at **no authority at all**.

## `execute`, and the refusal to populate a rung for its own sake

`execute` is **0 of 81** with **0 of 25** grid cells licensing it. The brief asks
whether these mutators are its first legitimate occupants. **The answer is taken
from README §2's own mechanical test for the rung — *"performs a durable write"*
— and not from the fact that the rung is empty.** Each candidate is answered
against that test individually; a candidate that only *proposes* a mutation does
not get there because it would be convenient.

**No class licenses `execute`, so every entry that reaches it declares
`authority_mismatch: declared` and takes a row in `MISMATCHES.md`.** That is the
honest recording of an over-authorisation, not a grant. Registering these
controls **will move the evidence-policy denominator off 81** and will add
findings; that is expected and will be reported with the delta explained.
**Existing controls must not move**, and their 19 findings must survive
byte-identical.

**`maint.managed_set_replacement` is examined and DELIBERATELY LEFT WHERE IT
IS.** It sits at `advise` while declaring output *"files copied into an installed
repo, replacing prior managed copies"*, failure *"none that stops anything"* and
rollback *"none; a managed file's local edits are lost on install"*. Under the
corrected ladder that is `execute`. **Moving it is a re-authorisation of an
EXISTING control, which this packet is not authorised to perform.** It is
recorded as a `FINDING-*` with its remedy named and NOT applied, and a test pins
that it is still at `advise` — so the finding cannot be silently discharged.

## Limitations accepted up front, so nothing is overclaimed

Under the operator's anti-stall rule these are stated and built around, not
paused on:

- **The full signal set does not exist.** Snapshots carry only the three
  currently derivable signals. The store admits more; nothing pretends to have
  them.
- **The data is not sufficient for learning, and no historical values are
  back-filled by inference.** Telemetry rows for past packets carry explicit
  `unknown`, never `0`. A test drives that red.
- **Historical prose is not fully normalised.** `residue.md` (aa)–(ss) stays
  prose. Enough occurrences migrate to prove recurrence queries; the migration
  path for the rest is documented.
- **Line numbers stay navigation hints and stop being identity.** The substrate
  is the smallest one that holds; the memory kernel is explicitly not attempted.

## The obligations registering a control drags along — enumerated before building

Each is a real gate that has to be satisfied, not a formality:

1. `neurocosmology_crosswalk.txt` — the **anti-omission guard** fails any
   registered control that is silently unbound. Every new control needs a
   binding.
2. `MISMATCHES.md`'s table — every `authority_mismatch: declared` entry needs a
   row **naming a file and a line**, reconciled both directions by
   `scan-controls.sh` §8.
3. **§22, no `path:line` classified twice.** `swarm-merge.sh:587` and
   `specialist-handoff.sh:145` are **already claimed** by
   `swarm.post_merge_verification` and `tools.handoff_lock`; the new entries must
   cite different, non-vacuous lines.
4. Any **new `.sh` carrying a refusal construct becomes a control surface** and
   needs a `gate` entry, or §7 fails it as `UNREGISTERED`. A new `tests/*.sh`
   needs both a `suite.*` entry and a `chain_suite` line, or the unwired check
   fails it.
5. `control_registry.txt`'s **`FIELDS` list is closed** — a new field name makes
   the whole file malformed, and adding one to the enum would make all 81
   existing entries incomplete. **The mutator record therefore lives in its own
   store keyed by `control_id`, and the control registry is not widened.**

## Verification this packet owes before handing back

`bash tests/build_os_tests.sh` (baseline **1636 / 0**);
`./build-os/maintenance/run-tests.sh` (**144/144** — chained into nothing, so it
is run explicitly: clearing this file to two `^## ` blocks is what shipped
`2df61ae` red); `scan-controls.sh check` exit 0;
`evidence-policy.sh check` with the delta from **19 of 81 / 6-5-8** explained;
`CHANGELOG.md` carrying the new literal `<count> passed` **unsplit by markdown**
if the total moves; `git status --porcelain` empty.

**This file must keep ≥3 `^## ` blocks.** `rotate-memory.mjs`'s `FILE_SPECS`
splits it on `blockDelimiter: /^## /`, and the two-pass rotation proof needs ≥3
blocks per rotating file. A count of **0** is worse and is not silent: the tool
prints `WARNING: … matched NOTHING … NOTHING CAN EVER ROTATE OUT OF IT` on
stderr, exits 0, and leaves the file byte-identical. The failure mode is an
**ignorable warning**, not silence.
