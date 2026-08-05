# Receipt — `gravito_exp0002_execution_a`

- **Packet id:** `PACKET-0048-exp0002-sustained-workload`
- **Title:** EXP-0002a — the operator's Track B: the **sustained-workload
  token-efficiency experiment, Claude alone** (Codex not a prerequisite).
  Preregistration first, then the harness, two five-task sequences executed,
  sealed immutable run records and a blinded dataset. The analysis/reveal half
  is the NEXT packet (EXP-0002b).
- **Date closed:** 2026-08-05.
- **Lane:** `substantive`. **Depth: 3 — reason: fix-then-pass (1 enumerated
  item), announced** — build stage; qa ‖ reviewer CONCURRENTLY; one bounded fix
  round. Archivist close after the verdict (bookkeeping, not a gate).
- **Branch:** `claude/project-handoff-merge-ramhds`.

## 1. Scope

**In:** the preregistered protocol
(`build-os/experiments/EXP-0002-sustained-workload/PREREGISTRATION.md`,
committed BEFORE run 1 — qa verified all 10 run timestamps postdate it); the
EXP-0002 harness; two five-task sequences (T1 diagnose → T2 tested fix → T3
multi-file feature → T4 injected regression → T5 context-dependent follow-up)
on one evolving parcel-billing tree per arm; the RULING-4 registration of the
four refusal-capable harness surfaces; sealed run records + sha256 manifest;
the blinded X/Y dataset with the arm mapping WITHHELD from the tree by hash.

**Explicitly out:** the blinded analysis commit, reveal, and conclusion
(EXP-0002b — the evaluator-independence commit boundary is preserved); any
Gravito optimization or mid-run harness edit (freeze rule); any edit to
`bench/` or any EXP-0001 artifact; any response to the result.

## 2. Base and commits

- **Base:** `982054a` — the pushed tip (EXP-0001 published);
  `git merge-base HEAD origin/claude/project-handoff-merge-ramhds` = `982054a`,
  re-verified at close.
- `9cf0f87` — docs(experiment): preregistration + harness + PACKET-0048
  declaration. **Committed BEFORE run 1 — all 10 run timestamps postdate it
  (qa-verified); ancestry is the ordering proof.**
- `2d0696a` — registry(exp2): RULING-4 registration of the four
  refusal-capable harness surfaces; census 110 → 114; crosswalk + derived
  totals in the same commit.
- `916e1ae` — data(experiment): sealed run records + blinded dataset + mapping
  sha256 `45734767…`.
- `38ee0df` — the **ONE permitted post-gate fix commit** (see §4).
- **THREE build commits = the RECORDED CONTRACT-GAP shape**, not a builder
  breach: the identity scanner forced the RULING-4 registration mid-packet —
  the same class as PACKET-0045's third commit, already on the record. A
  packet whose build commit trips a scanner cannot both hand back green and
  stay at two build commits.

## 3. What was executed

Two five-task sequences (T1 → T5 as in §1) on one evolving parcel-billing
tree per arm — deterministic seed `128485c6…`, seed suite 19/0 — fresh
headless session per task, **byte-identical prompts** (`task_prompt_sha256`
equal across arms, reviewer-verified). Arm `raw` vs arm `buildos` differ only
by `install-project.sh`. The Bash-capable path was used (scoped allowlist;
**non-binding in CLI 2.1.222, disclosed; identical in both arms**). **10/10
durable accepted outcomes by external oracles. Model identical across all 10
runs.**

**Arm-B seed integrity:** verified content-identical to the seed outside the
installed surface (`package.json` differs only by the installer's added script
line); the starting digest is post-install **by design**.

## 4. QA proof (RED → fixed → PASS-AS-FIXED)

- **Initial: RED, 2376 passed / 2 failed — ONE attributed item:** the sealed
  buildos T3/T5 stream transcripts carried workload-repo citations that the
  tree-wide range-citation sweep bit on.
- **Fix `38ee0df`:** restored EXP-0001's sealed form — all ten stream
  transcripts scratchpad-resident and hash-pinned in `MANIFEST.sha256`;
  run records and `result.json` files **byte-untouched**; **no scanner or
  sweep modified.**
- **Targeted re-check at `38ee0df`:** `control_registry_tests` **180/0**;
  **FULL SUITE 2378 passed / 0 failed, exit 0, solo**; manifest **31/31 OK**.
- **Commit-1 isolation:** **RED at `9cf0f87` BY the same contract gap** — the
  identity scanner names exactly the four then-unregistered surfaces; commits
  1+2 at `2d0696a` **GREEN 2378/0**. qa verified both directions and stated it
  plainly.
- **Blinding at close:** dataset X/Y only, **zero arm strings (qa grep 0)**;
  dispatch counts deliberately **EXCLUDED** from the blinded dataset (they
  would de-blind); mapping withheld in the session scratchpad, sha256
  pre-committed in the tree.
- **Safety grep:** clean over `982054a..38ee0df` (36 files, +2889/−3 net) —
  no push, merge, deploy, secret, amend, or rebase; the single textual hit is
  the packet declaration's own boundary prose stating the rule.
- **UI smoke:** n/a — this packet has no UI surface.

## 5. Mid-experiment defect — RECORDED FOR LATER, harness untouched (freeze rule)

The result-event `usage.*` block **undercounts dispatch-heavy sessions**
(buildos T3 dispatched 5 subagents — build-orchestrator, builder, qa,
reviewer, archivist; T5 dispatched 4). The sealing layer uses the complete
provider `modelUsage` aggregate **uniformly for all rows** (it reconciles
exactly with `total_cost_usd`; qa re-derived all 10 rows); affected rows are
labeled `usage_block_disagrees=yes`.

**Reviewer's integrity finding, quoted:** the uncorrected block would have
**FLATTERED arm B** (~70x undercount on its T3), so the correction moved the
data **AGAINST the convenient direction — the opposite signature of
result-driven adjustment.**

## 6. Reviewer verdict

**PASS — ZERO fix items** on the packet's own scope; with qa's one attributed
item fixed in `38ee0df` and re-checked, the packet closes **PASS-AS-FIXED**.
**Three obligations routed to the NEXT packet (EXP-0002b):**

1. Define the `usage_block_disagrees` criterion.
2. State the arm-B seed derivation in the revealed report.
3. Run the reveal promptly.

**Second eyes: NONE — single-model review, stated plainly.** The Codex host
returns 403 at the proxy; **both gates reproduced it live.** The router's
`DC-0001` second-eyes streak numeral moves **27 → 28 in this same close
commit**, derived from the receipt store
(`ls build-os/receipts/gravito_*.md | wc -l`), never restated.

## 7. Disjoint file-ownership manifest — SINGLE-WRITER, sequential commits, no fan-out

One writer at a time produced the four commits in sequence: **the builder
agent authored the harness under the orchestrator's brief** (commit
`9cf0f87`), and the same sequential single-writer discipline carried the
registration, the sealing, and the fix. qa and the reviewer held no mutating
tools; no two agents could contend, so disjointness holds trivially — the
manifest is recorded anyway because a missing manifest has broken closes
before (the P2 precedent, and this store's own EXP-0001a addendum).

- `9cf0f87` —
  `build-os/experiments/EXP-0002-sustained-workload/PREREGISTRATION.md` (new);
  `build-os/experiments/EXP-0002-sustained-workload/harness/**` (7 files,
  new); `build-os/packets/active_packet.md` (append-only declaration).
- `2d0696a` — `build-os/registry/control_registry.txt`,
  `build-os/registry/neurocosmology_crosswalk.txt`,
  `build-os/registry/CROSSWALK.md`, `build-os/registry/README.md`.
- `916e1ae` — `build-os/experiments/EXP-0002-sustained-workload/runs/**`
  (31 sealed files, new);
  `.../analysis/blinded_dataset.tsv` (new); `.../analysis/MAPPING_SHA256.txt`
  (new).
- `38ee0df` (fix) — `.../runs/MANIFEST.sha256` (re-pinned) and the ten
  `.../runs/*/stream.jsonl` deletions — a strict subset of `916e1ae`'s paths,
  which is exactly what a bounded fix commit is allowed to touch.
- Every path is attributable to exactly one owner by `git show --numstat`;
  the only cross-commit overlap is the fix commit correcting the sealing
  commit's own files.

## 8. Residue — carried, not resolved here

1. The three reviewer obligations in §6 belong to EXP-0002b.
2. **The withheld mapping and the ten stream transcripts exist only in the
   session scratchpad** — a lost session loses them; the reveal must come
   promptly.
3. The `usage.*` undercount defect (§5) is recorded, not repaired — the
   harness stays frozen by operator ruling.
4. **The blinded analysis ALREADY EXISTS** (independent evaluator, completed
   before this close) and is committed by the NEXT packet; its label is not
   named in this receipt to keep the reveal ordering clean.

## 9. Open boundaries

- **NOTHING PUSHED.** `9cf0f87`, `2d0696a`, `916e1ae`, `38ee0df`, and this
  close commit remain local pending explicit operator go. **None may be
  amended.**
- No merge, no deploy, no secrets touched. `residue.md` stays frozen.
- **Staged next but NOT DECLARED** (declaring is a routing act, not the
  archivist's): **EXP-0002b** — the blinded analysis committed verbatim, the
  reveal against the pre-committed hash, and the conclusion with the two
  mandated reconciliations (EXP-0001's trivial-task overhead; the historical
  weekly-usage drop).
