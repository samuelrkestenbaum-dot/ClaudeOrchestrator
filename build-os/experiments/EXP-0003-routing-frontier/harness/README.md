# EXP-0003 harness — routing-frontier experiment (v1.0.0)

Three conditions, three measured tasks each, executed **in sequence on one
evolving repository per condition**, a **fresh headless session per task**
(`claude -p`). Condition A = direct/raw (no installed surface). Condition B =
installed surface + a **binding gravito_light routing receipt**. Condition C =
installed surface + a **binding gravito_full receipt with the derived
budgets**. B and C differ ONLY in receipt content (byte-precise statement:
`../PREREGISTRATION.md` §2). The task prompts are EXP-0002's FROZEN prompts,
extracted mechanically and sha256-pinned. See `../PREREGISTRATION.md` for the
question, conditions, telemetry, decision rule, blinding, and order; this file
is only the machinery.

Everything here is invoked via `bash` / `node`. **No file in this harness is
executable, by design** — the repository's executable census must not move.

## The pieces — what is NEW vs what is REUSED BY INVOCATION

| file | status | role |
|---|---|---|
| `setup-t1t2.sh` | **NEW (EXP-0003)** | deterministic scripted reference completion of T1+T2 on a fresh seed: reference DIAGNOSIS.md, the one-line `tierFor` fix, the reference boundary test. Byte-reproducible (two runs → identical tree digests); drives the frozen `oracle-exp2.js` on T1 AND T2 and refuses on rejection; leaves the suite at exactly `TOTAL: 23 passed, 0 failed`; post-setup digest pinned in the preregistration. |
| `run-exp3-task.sh` | **NEW (EXP-0003)** | runs ONE task of one condition (run mode) or fills+gates one condition's receipt (close mode). modelUsage-NATIVE telemetry (the recorded EXP-0002 usage-block defect, fixed here); cost reconciliation refusal (>1e-6 → record REFUSED, retained); two-witness tool/dispatch counts; pinned-digest and pinned-prompt refusals. |
| `../../EXP-0002-sustained-workload/harness/seed-workload-repo.sh` | REUSED, read-only | the frozen deterministic parcel-billing seeder + `--digest` tree identity. |
| `../../EXP-0002-sustained-workload/harness/tasks.md` | REUSED, read-only | the FROZEN T3/T4/T5 prompt text; the runner extracts mechanically and refuses on sha256 drift. |
| `../../EXP-0002-sustained-workload/harness/inject-t4.sh` | REUSED, read-only | injects the deterministic T4 regression test after T3 closes, identically in all conditions. |
| `../../EXP-0002-sustained-workload/harness/oracle-exp2.js` | REUSED, read-only | machine acceptance per task, external, never named in a prompt. |
| `../../../tools/route-task.sh`, `../../../tools/routing-check.sh`, `../../../tools/mode-select.mjs`, `../../../memory/routing_contract.md` | REUSED, read-only | the PACKET-0050 routing surface. The experiment RUNS it — issues real receipts through it and gates them with it — and never edits it. |
| `../../../../install-project.sh` | REUSED, read-only | the B/C condition surface installer (`--no-session-hook`). What it ships is disclosed exactly in the preregistration §2. |

## The exact 9-run sequence (A: T3,T4,T5 → B: → C:), plus the two closes

One workdir per condition; the SAME workdir for all three of that condition's
tasks; seeded + set up once, **never reseeded between tasks**. Condition order
is preregistered A → B → C (cache-warmth confound named, separated via
uncached metrics).

```sh
H=build-os/experiments/EXP-0003-routing-frontier/harness

# --- condition A (direct/raw) -----------------------------------------------
# T3 seeds the tree, applies the scripted T1/T2 setup, captures the pristine
# baseline (no surface, no receipt — disclosed), then runs the first session.
bash $H/run-exp3-task.sh --condition A --task T3 --workdir /tmp/exp3/A --outdir /tmp/exp3/A-runs/T3
bash $H/run-exp3-task.sh --condition A --task T4 --workdir /tmp/exp3/A --outdir /tmp/exp3/A-runs/T4
bash $H/run-exp3-task.sh --condition A --task T5 --workdir /tmp/exp3/A --outdir /tmp/exp3/A-runs/T5
# condition A has NO close step: no receipt exists (the harness refuses --close --condition A by name).

# --- condition B (installed surface + gravito_light receipt) ----------------
bash $H/run-exp3-task.sh --condition B --task T3 --workdir /tmp/exp3/B --outdir /tmp/exp3/B-runs/T3
bash $H/run-exp3-task.sh --condition B --task T4 --workdir /tmp/exp3/B --outdir /tmp/exp3/B-runs/T4
bash $H/run-exp3-task.sh --condition B --task T5 --workdir /tmp/exp3/B --outdir /tmp/exp3/B-runs/T5
bash $H/run-exp3-task.sh --close --condition B --workdir /tmp/exp3/B --runsdir /tmp/exp3/B-runs --outdir /tmp/exp3/B-close

# --- condition C (installed surface + gravito_full receipt with budgets) ----
bash $H/run-exp3-task.sh --condition C --task T3 --workdir /tmp/exp3/C --outdir /tmp/exp3/C-runs/T3
bash $H/run-exp3-task.sh --condition C --task T4 --workdir /tmp/exp3/C --outdir /tmp/exp3/C-runs/T4
bash $H/run-exp3-task.sh --condition C --task T5 --workdir /tmp/exp3/C --outdir /tmp/exp3/C-runs/T5
bash $H/run-exp3-task.sh --close --condition C --workdir /tmp/exp3/C --runsdir /tmp/exp3/C-runs --outdir /tmp/exp3/C-close
```

The T4 injection happens automatically inside the T4 run when
`test/regression-t4.js` is absent (recorded in the run record), exactly as in
EXP-0002.

## Invariants the harness enforces (refusals, not conventions)

- **T3 first**: a non-T3 task refuses when the work tree is missing; a work
  tree without its pristine baseline refuses; a B/C work tree without its
  receipt refuses.
- **Pinned identities**: seed digest `128485c6…` and post-setup digest
  `6c77b5a4…` are verified at setup; the extracted prompt sha256 is verified
  against the preregistered pin before every send. Any mismatch refuses.
- **T1/T2 are scripted, never measured**: `--task T1|T2` is refused by name.
- **modelUsage-native primaries** with the cost-reconciliation refusal
  (>1e-6 → `run_record.REFUSED.txt`, retained as data); the parent `usage.*`
  block recorded beside, flagged, never merged.
- **Close-time loop is mechanical**: consumption summed from the three sealed
  records (a field fills only when all three values are machine-derived);
  `executed_mode` by the disclosed dispatch proxy; the receipt is filled
  once; `routing-check.sh`'s verdict is recorded verbatim with its exit code
  in `gate_result.txt`. **A refused receipt is data — retained, labeled,
  never edited to pass.**
- **Permissions identical across conditions**, non-bindingness disclosure in
  every record. Unknowns are `-`, never zero. TTFCC is deliberately not
  measured in EXP-0003 (the question is total cost per durable accepted
  outcome, not latency); no poller exists in this runner.
