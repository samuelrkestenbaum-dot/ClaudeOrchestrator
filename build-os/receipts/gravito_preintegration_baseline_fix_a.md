# Receipt — `gravito_preintegration_baseline_fix_a` (ADDENDUM / LATER RECORD)

- **Packet id:** `PACKET-0045-preintegration-baseline` — **the SAME packet as
  `build-os/receipts/gravito_preintegration_baseline_a.md`. This is a LATER
  RECORD of that packet's operator-ruled post-close fix round, not a reopening
  and not a second packet.** The original receipt body is immutable and is not
  edited by this close; on the store's own precedent (`packet_metrics.tsv` row
  `t1_run1_buildos_preintegration_later_record`), **a correction creates a
  later record, never edits an earlier one** — this file is that later record
  for the receipt store.
- **Title:** operator-ruled benchmark-integrity fix round — degraded runs
  unmistakable, two independent tool witnesses, identity-based coverage, the
  contract gap recorded, the baseline preserved as history — and **the freeze**.
- **Date closed:** 2026-08-05 (same day as the original close; later).
- **Lane:** `substantive` (the packet's own lane; this round is its one
  contractually permitted post-gate fix commit).
- **Depth: 4 — reason: `mandatory_full_regate`, announced by name and
  satisfied.** All five of CLAUDE.md's conditions held: the fix list (the
  operator's rulings) arrived complete in one installment; the packet was
  correctly scoped; the fixes alter logic, derivation, authority and counts
  (suite total, census, scanner semantics, record schema); the contract's own
  re-review rules therefore forbade targeted confirmation; and a full
  concurrent re-gate (qa ‖ reviewer) ran as a result. **Not a defect, and not
  recorded as one.**
- **Verdict of the re-gate:** **qa GREEN. Reviewer PASS — ZERO fix items.**
  Second eyes: **NONE, single-model** — the `codex` binary is present
  (`/opt/node22/bin/codex`, `codex-cli 0.146.0`) but `api.openai.com:443` is a
  `403` CONNECT / policy denial at the agent proxy and `OPENAI_API_KEY` is
  unset; the router's corrected clause (`tool_router.md`, second-eyes row)
  stands, and its `DC-0001` numeral moves **24 → 25 in this same close commit**
  because this file's existence is what the count derives from.
- **Branch base:** the fix commit sits directly on **`a9f44ad`, the PUSHED
  TIP** (`git merge-base 9f8630c a9f44ad` → `a9f44ad`). `9f8630c` and this
  close commit are the only local commits; **nothing is pushed, merged, PR'd,
  tagged or deployed, and no such go has been given.**

---

## 1. Shape — why this close exists at all

`PACKET-0045` was gated and closed at `a9f44ad` with verdict PASS-AS-FIXED
(receipt `gravito_preintegration_baseline_a.md`, commits
`c7433c5`,`945a140`,`014afb1`,`fff967e`). That close left **four operator
decisions open** in its §7. The operator then **ruled**, and the rulings landed
in the packet's **one** contractually permitted fix commit — **`9f8630c`**,
ONE commit, nothing squashed, amended or rebased — which then received its own
**full concurrent re-gate** (qa ‖ reviewer, both measuring `9f8630c` on a
quiet tree). This receipt records the rulings, the re-gate, and the freeze.
The existing `packet_metrics.tsv` row for the packet (commits
`c7433c5,945a140,014afb1,fff967e`) is **not edited**; a later-record row
attributes `9f8630c` to the packet, every numeric cell that adds no
measurement left as `-`.

## 2. Scope

**IN.** Exactly the operator's rulings (repo-numbered RULING 2–6), nothing
else: the degraded-run record schema and interfaces in `bench/run-corpus.sh`;
the two-witness `TOOL_CALLS` derivation; identity-based executable coverage in
`build-os/registry/scan-controls.sh` + registry; the contract-gap record in
`current_state.md`; the baseline later-record row and `BASELINE_LIMITS.md` §8;
tests for all of it.

**EXPLICITLY OUT — and verified untouched:** `task_corpus.md`,
`COMPARISON_PROTOCOL.md`, `standing_gates.md`, `rank-candidates.sh`
(`5543ea88`), `decision_telemetry.tsv` (`fd52eb15`), `signal_snapshots.tsv`
(`7496ead8`), `residue.archive.md` (`f475d53e`), and **`residue.md` — FROZEN
at blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, 204,369 B, headroom 431 B,
NOT WRITTEN by the fix round or by this close.** CLAUDE.md untouched. No new
subsystem, no expansion of the packet's objective.

## 3. Commits of this later record

| Commit | Kind | One line |
|---|---|---|
| `9f8630c` | FIX (the packet's ONE permitted fix commit) | fix round (operator-ruled): degraded runs unmistakable, two tool witnesses, identity-based coverage, contract-gap record, baseline later record |
| *(this close)* | CLOSE | addendum receipt, later-record metrics row, memory advanced, `DC-0001` numeral 24 → 25 |

`git diff-tree -r --numstat 9f8630c`: **13 files, +858 / −72** (per-commit sums
= net; one commit). Isolation is trivial and was measured: the fix commit alone
on the pushed tip `a9f44ad` is the tree qa measured at **2378 / 0**.

## 4. The five rulings, each implemented and gate-verified

**RULING 2 — degraded runs are unmistakable.** Records diverge from the title
byte down; `benchmark_mode` / `degraded_reason` / `degraded_authorization` /
`canonical_comparison_eligible` are mandatory; **absence is INVALID, not
canonical**; a refusal is not a run — it carries `eligible: false`, no numbers,
no mode, and was judged consistent as **the maximally fail-closed state**.
`FORCE_DEGRADED=1` is **DEAD** — qa proved the refusal record **byte-identical
with it set**, and the variable is never read. The documented
`--i-accept-a-degraded-run` flag parses, **refuses without an explicit
reason**, and triple-marks everything it produces. The aggregation refusal
lives in `validate_fields()` shared by append AND `--validate`, and **the live
store validates on every suite pass** — so a degraded row cannot sit in the
store while the tree is green. qa **mutation-killed both load-bearing
drives**: removing the mode emission → **3 tests fail**; spoofing
`eligible: true` → **2 fail**.

**RULING 3 — `tool_calls` has two genuinely independent witnesses.**
Structural parse only, zero greps. Witness 1 reads **assistant** events
(requests); witness 2 reads **user** events (completions) — **disjoint event
classes**. `unavailable` is never written as zero; disagreement is
**REPORTED, not reconciled** (the `DISAGREE` print).

**RULING 4 — coverage follows identity, not geography.**
`APPROVED_EXEC_ROOTS="build-os tests .claude/hooks bench"`. An unregistered
executable at any approved root **or at the top level REFUSES; registration,
not relocation, is the remedy** — proven in both directions. The
`-perm -u+x` discriminator is live (`chmod +x` flips a fixture to discovered);
a same-commit allowlist addition is self-defeating; deleting `bench` from the
set kills **5 tests**. **Census 105 → 110, FORCED not padded** — qa applied
the refusal regex to all six top-level executables: **exactly the three
registered installers match, the three unregistered don't.** Declared
mismatches **22, unmoved**; `DC-0002` / `DC-0003` both AGREE.

**RULING 5 — the contract gap recorded, no doctrine changed.** The
≤2-build+1-fix / tree-quiet / no-amend joint unsatisfiability is recorded
precisely in `current_state.md` (the `(RULING 5 — THE CONTRACT GAP …)` bullet
of the *Where we are* block); CLAUDE.md untouched; review deferred to
recurrence during product execution. No doctrine packet opened.

**RULING 6 — the baseline preserved as history.** The original T1 row is
**byte-untouched** (qa's `cmp` clean against the pushed tip's blob); the later
record pins `harness_version=945a140` and every numeric cell `-`, and marks
`canonical_comparison_eligible=false` **derived, not asserted** — the row
predates `benchmark_mode`, and absence is INVALID. The reviewer judged that
**grandfathering would have laundered old-witness numbers into canonical
comparisons.**

## 5. QA proof (re-gate, tree quiet at `9f8630c`)

- Suite **2314 → 2378** (+64), the delta **derived by execution**, not
  restated: full suite at a base worktree (`a9f44ad`: 2314/0) and at HEAD;
  `tests/speed_benchmark_tests.sh` **169 → 221**,
  `tests/control_registry_tests.sh` **168 → 180**, **all 18 other chained
  suites +0** — per-suite CHAINED vectors **byte-identical across two solo
  runs**, each after an anchored `pgrep -fa '^bash tests/'` returned empty.
- `RELEASE_METADATA_LIVE_SUITE=1`: **44 / 0**; the live total matches memory.
- The literal `**2378 passed**` occurs **once, unsplit**, in `CHANGELOG.md`;
  `current_state.md`'s build/test line matches.
- Safety: no push/merge/PR/tag/deploy/secret/`git config`/amend/rebase
  anywhere in the round; the out-of-scope blobs of §2 verified unmoved;
  `residue.md` blob-verified frozen.
- Mutation evidence and forced-census evidence as itemised under the rulings
  above (kills: 3, 2; identity regex applied to all six top-level
  executables).
- Archivist re-verification at this close, after its own edits: full solo
  suite **2378 / 0**; `scan-controls counts` exit 0 with `DC-0001`
  stated=25 derived=25.

## 6. The reviewer's two named bounds — verbatim into the record

- **Weakest remaining link: `BENCH_BASH_TOOL=yes`** — an unverified operator
  assertion producing a degraded run wearing `benchmark_mode: canonical`,
  discountable only by reading the `suite_execution_gate` prose. Named
  in-band; **the freeze rightly leaves it.**
- **Nested-unapproved-directory bound:** a refusal-capable executable in a NEW
  nested unapproved directory (e.g. `scripts/x.sh`) is invisible to the scan —
  detectable only at review of the commit creating it. Coverage now follows
  identity within the declared geography plus the top level; **expanding the
  sweep would breach the freeze. A bound to know, not a defect.**

And the reviewer's trajectory verdict, verbatim: *"a number it produces later
can be believed without re-auditing the harness provided the record is read,
not just the number."*

## 7. THE FREEZE — the operative state after this close

**Per operator ruling, the benchmark machinery is FROZEN:** no new guards, no
corpus redesign, no prompt tuning, no new measurement fields without an actual
run proving necessity, no derived-restatement or scanner-doctrine packet.
**The benchmark is an instrument to run, not a subsystem to perfect.** The
next legitimate benchmark activity is **running it**, or Repository Core
integration events. The two bounds in §6 are known and deliberately left
inside the freeze.

## 8. Residue and open boundaries

- **`residue.md` is FROZEN and was NOT WRITTEN** (blob
  `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, 204,369 B, headroom 431 B); the
  residue of this round is carried HERE and in `current_state.md` instead:
  the two §6 bounds, and the freeze itself as the standing constraint.
- **Phase D's key-AND-network-policy gate remains open** (the one unruled item
  of the original §7's four): provisioning `OPENAI_API_KEY` is necessary but
  not sufficient — the proxy policy must also allow `api.openai.com`.
- **Nothing is pushed, merged, tagged, PR'd or deployed, and no such go has
  been given.** `a9f44ad` is the pushed tip; `9f8630c` and this close commit
  are the two local commits. **`9f8630c` may not be amended** — it is the tree
  both gates measured.
- Next work is **Repository Core and live provider execution**; the backlog in
  `current_state.md` remains a **record, not a queue**.
