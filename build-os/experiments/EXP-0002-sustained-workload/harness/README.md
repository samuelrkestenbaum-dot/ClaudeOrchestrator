# EXP-0002 harness — sustained-workload experiment (v1.0.0)

Two arms, five related tasks each, executed **in sequence on one evolving
repository per arm**, a **fresh headless session per task** (`claude -p`).
Arm `raw` = Gravito OFF (seeded repo untouched). Arm `buildos` = Gravito ON
(`install-project.sh --no-session-hook`, run before the baseline copy). The
task prompts are byte-identical across arms — the installed surface is the
only difference. See `../PREREGISTRATION.md` for the question, metrics,
decision rule, blinding, and arm order; this file is only the machinery.

Everything here is invoked via `bash` / `node`. **No file in this harness is
executable, by design** — the repository's executable census must not move.

## The pieces

| file | role |
|---|---|
| `seed-workload-repo.sh` | deterministic seeder for **parcel-billing** (ordinary dependency-free Node app; suite green at exactly `TOTAL: 19 passed, 0 failed`). Prints `tree_digest_sha256` (sha256 over sorted relpath+sha256 lines). `--digest DIR` re-derives the digest of any tree — the work trees are not git repos, so this digest, not a commit SHA, is the pinned-state identity. Freezes the T1/T2 instance (a one-line tier-boundary defect in `lib/pricing.js` contradicting its own INCLUSIVE-limits comment, deliberately untested), `SPEC-T3.md` (discount codes, exact worked examples + error case) and `FOLLOWUP-T5.md` (a follow-up whose correct completion depends on T2–T4's decisions). |
| `tasks.md` | the five FROZEN task prompts, verbatim. The runner extracts the prompt mechanically from this file, so the committed text and the sent text cannot drift. |
| `inject-t4.sh` | writes `test/regression-t4.js` AFTER T3 closes — a legitimate failing test derived from SPEC-T3.md's own SAVE10 cap sentence, which no worked example exercises; a correct-but-narrow T3 implementation fails it, and making it pass is spec compliance. Deterministic bytes; prints the file's sha256. |
| `oracle-exp2.js` | machine acceptance per task (`node oracle-exp2.js T1..T5 <candidate> <pristine>`, exit 0/1). External, mechanical, never named in any prompt. T2 includes an executed pre-fix differential (candidate tests transplanted onto the pristine buggy source must FAIL); T4 byte-compares the regression test against the injector's own output; T5 recomputes summary totals on a fixture set that includes the cap order. |
| `run-exp2-task.sh` | runs ONE task of one arm: fresh `claude -p` with the frozen prompt, `--output-format stream-json --verbose --permission-mode acceptEdits --allowedTools "Bash(node:*)"`, cwd = the arm's persistent work tree. Captures provider-native telemetry, two-witness tool counts, permission denials, TTFCC by 10 s oracle polling against a copy, tree digests before/after, oracle verdict, suite tail — into `run_record.txt` (bench field discipline: an unknown is not a zero; `-` for unmeasured). |
| `mode-selector.mjs` | DESCRIPTIVE-ONLY heuristic (`direct | gravito_light | gravito_full`). The runner records its verdict per task and ignores it — it routes nothing. |

## Per-arm sequence (exact)

One workdir per arm; the SAME workdir for all five tasks of that arm; the work
tree is seeded once and **never reseeded between tasks**:

```sh
H=build-os/experiments/EXP-0002-sustained-workload/harness
W=/tmp/exp2/raw          # arm workdir  (persistent across the arm's 5 tasks)
R=/tmp/exp2/raw-runs     # artifact root (one subdir per task)

# T1 seeds the tree, installs the arm surface (buildos arm only), and captures
# the pristine baseline — then runs the first fresh session.
bash $H/run-exp2-task.sh --arm raw --task T1 --workdir $W --outdir $R/T1
bash $H/run-exp2-task.sh --arm raw --task T2 --workdir $W --outdir $R/T2
bash $H/run-exp2-task.sh --arm raw --task T3 --workdir $W --outdir $R/T3
# inject-t4 runs between T3 and T4 — the T4 runner injects automatically when
# test/regression-t4.js is absent (recorded in the run record), or run it
# explicitly:  bash $H/inject-t4.sh $W/repo
bash $H/run-exp2-task.sh --arm raw --task T4 --workdir $W --outdir $R/T4
bash $H/run-exp2-task.sh --arm raw --task T5 --workdir $W --outdir $R/T5
```

Then the same five lines with `--arm buildos` and a **different** workdir /
artifact root. **Arm order is preregistered by the orchestrator**
(PREREGISTRATION.md §4: arm A `raw` first, then arm B `buildos`) — the harness
does not choose it. Optional `--model NAME` is passed through and recorded;
`model_used` is always read back from `modelUsage`.

## Invariants the harness enforces

- **T1 first**: the runner refuses any task when the work tree is missing, and
  refuses a work tree without its pristine baseline.
- **Seed integrity**: the seeded suite must report exactly
  `TOTAL: 19 passed, 0 failed` before any session runs; the seed digest is in
  `seed.txt` and the per-task digests in every `run_record.txt`.
- **Baseline after arm install**: the pristine copy is taken AFTER
  `install-project.sh` runs, so installer-edited files (package.json,
  .gitignore) are baseline, never task output.
- **Polling never perturbs**: the oracle polls a COPY of the tree.
- **Permissions identical across arms**, with the CLI 2.1.222 allowlist
  non-bindingness disclosed verbatim in every record.
- **Unknowns are `-`**, never zero; disagreeing witnesses are printed, never
  reconciled.
