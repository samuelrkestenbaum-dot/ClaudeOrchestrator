# Receipt — `gravito_exp0001_execution_a`

- **Packet id:** `PACKET-0046-exp0001-token-efficiency`
- **Title:** EXP-0001a — the **execution half** of the operator's 2026-08-05
  controlled experiment: Gravito OFF vs ON, total model tokens per durable
  accepted outcome. Preregistration first, then sealed immutable run records
  and a blinded dataset. The evaluation half is the NEXT packet (EXP-0001b).
- **Date closed:** 2026-08-05.
- **Lane:** `substantive`. **Depth: 2** — build stage, then qa ‖ reviewer
  CONCURRENTLY. Archivist close after the verdict (bookkeeping, not a gate).
- **Branch:** `claude/project-handoff-merge-ramhds`.

## 1. Scope

**In:** the preregistered protocol
(`build-os/experiments/EXP-0001-token-efficiency/PREREGISTRATION.md`,
committed BEFORE run 1); 10 canonical T1 runs executed by the FROZEN harness
`bench/run-corpus.sh` at `0ddf0b6` — 5 pairs, alternating order, arm A =
`raw` (Gravito OFF), arm B = `buildos` (Gravito ON via
`install-project.sh`); 6 T2–T4 refusal records (per task per arm — refusals
stay in the dataset, zero model calls); sealed run records + sha256 manifest;
the blinded X/Y dataset with the arm mapping WITHHELD from the tree by hash.

**Explicitly out:** blinded analysis, reveal, and conclusion (EXP-0001b — the
evaluator's independence is a commit boundary, not a promise); any Gravito
optimization; any edit to `bench/`, the corpus, oracles, prompts, or
acceptance criteria; any new control or governance primitive; any executable
under `build-os/experiments/`.

## 2. Base and commits

- **Base:** `0ddf0b6` — the pushed tip; verified
  `git merge-base HEAD origin/claude/project-handoff-merge-ramhds` = HEAD =
  `0ddf0b6` at declaration.
- `b3a3b7f` — docs(experiment): preregister EXP-0001 Gravito OFF/ON
  token-efficiency protocol; declare PACKET-0046. **Committed BEFORE run 1 —
  ancestry is the ordering proof** that the protocol predates the data.
- `d2373e6` — data(experiment): EXP-0001 sealed run records, manifest,
  blinded dataset.
- **2 build commits, NO fix commit** — the packet stays at the ≤2 cap.

## 3. What was executed

10 canonical T1 runs by the frozen harness (**zero edits to `bench/`** — qa
proved the empty diff), 5 pairs alternating order. All 10 runs
**accepted=yes** by the hidden oracle. All 10 `model_used` identical
(`claude-haiku-4-5-20251001` + `claude-sonnet-5`, CLI 2.1.222). All 10
`tree_digest` `bb52f7b5…` exact. Plus 6 T2–T4 refusal records, retained in
the dataset with zero model calls.

## 4. QA proof (GREEN)

- **Suite:** **2378 passed / 0 failed**, solo foreground at `d2373e6`, exit 0.
- **Commit-1 isolation:** `b3a3b7f` in a detached worktree: **2378 / 0**.
- **Census:** 110; **0 executables** under `build-os/experiments/` (all 40
  new files mode `100644`).
- **Manifest:** 47/47 sha256 OK (36 in-repo + 10 scratchpad stream logs + 1
  withheld mapping).
- **Blinded dataset:** all 10 blinded rows re-derived from the sealed
  records; component sums exact. **Blinding leak grep: 0.**
- **Freeze held:** `residue.md` blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`
  unchanged.
- **Safety grep:** clean — 1080 insertions, 0 deletions, 41 files; no push,
  merge, deploy, secret, amend, or rebase.
- **UI smoke:** n/a — this packet has no UI surface.

## 5. Reviewer verdict

**PASS — ZERO fix items.** **Second eyes: NONE — single-model review, stated
plainly.** The Codex host is unreachable through the proxy (the known
four-state blocker: binary present, key unset, `api.openai.com:443` denied by
policy on both transports). The router's `DC-0001` second-eyes streak numeral
moves **25 → 26 in this same close commit**, derived from the receipt store
(`ls build-os/receipts/gravito_*.md | wc -l`), never restated.

**Reviewer's binding hand-off condition:** the EXP-0001b evaluator receives
ONLY the blinded dataset + the preregistration **§5 rule text** — **NEVER
§3's schedule** (the pair/seq columns would de-blind against it).

## 6. Blinding state at close

Arms relabeled **X/Y** in `analysis/blinded_dataset.tsv`. The mapping file is
**WITHHELD from the tree** (session scratchpad only); its sha256
`0a4b66a142ced55bde866cd16283540643f68a2dfd6f3a231ba188b3b9fd08ec` is
committed in `analysis/MAPPING_SHA256.txt` and in the sealed manifest.

## 7. Residue — carried to EXP-0001b (advisories, not defects here)

1. **Execute the reveal promptly** — the withheld mapping and the 10 stream
   logs exist only in the session scratchpad; a lost session loses them.
2. **The analysis must surface the T2–T4 refusals and per-arm acceptance
   explicitly** — refusals are data, not noise.

## 8. Open boundaries

- **NOTHING PUSHED.** `b3a3b7f`, `d2373e6`, and this close commit remain
  local pending explicit operator go. **None may be amended.**
- No merge, no deploy, no secrets touched.
- **Staged next but NOT DECLARED** (declaring is a routing act, not the
  archivist's): **EXP-0001b** — blinded evaluation, reveal, conclusion.
