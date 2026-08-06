# Runbook — PILOT-0002 through EXP-0004 reveal

OPERATIONAL CHECKLIST ONLY. It changes no registered rule. Where this
document and a registered rule disagree, THE REGISTERED RULE WINS and the
disagreement is a defect in this file.

Authorities: PILOT-0002 = `build-os/pilots/PILOT-0002/FREEZE.md`.
EXP-0004 = `build-os/compiler/AB_PREREGISTRATION.md` + Amendments 1-4.

## Phase 0 — cutover, BEFORE the before-reading

- [ ] No background trigger can fire inside the window. (The 22:44Z
      quiet-watch was DELETED for exactly this reason; re-arm only after
      PILOT-0002 closes.)
- [ ] `cd /home/user/ClaudeOrchestrator && git status --porcelain` empty.
- [ ] `git status --porcelain` — the two untracked paths (`.serena/`,
      `build-os/packets/routing/`) are pre-existing and NOT product
      files. **DECIDED: leave them untracked.** Adding a `.gitignore`
      entry would require a commit on the frozen repository, and the
      pilot branch must be cut from the pinned seed `93f75ea` exactly —
      a tidier `git status` is not worth moving the seed the freeze
      names. They are inert for T1-T5.
      **Consequence carried forward to Phase 2, not forgotten:**
      `assess-repo.sh` refuses on a dirty tree INCLUDING untracked
      paths, so they must be resolved before the eligibility run — at
      that point the pilot's own commits already exist, so the seed is
      no longer at stake and a `.gitignore` commit is free.
- [ ] Pilot branch created from the frozen seed:
      `git checkout -b pilot/PILOT-0002-clean-window 93f75ea`
      (FREEZE.md pins 93f75ea, the native-install tip.)
- [ ] `git merge-base --is-ancestor cb2bb7d HEAD` returns FALSE.
- [ ] `bash build-os/tools/routing-check.sh check` exits 0 with NO open
      receipt (an open receipt would let an unrouted mutation through).
- [ ] Baseline suite states captured for every acceptance clause that
      references one (FREEZE.md requires a BASELINE.md at window open).

## Phase 1 — PILOT-0002 (the measured window)

1. Operator sends the meter reading VERBATIM. Record it unchanged:
   `build-os/pilots/PILOT-0002/WEEKLY_METER_BEFORE.md`, commit it.
   THE WINDOW IS NOW OPEN.
2. Run T1..T5 exactly as frozen. For each: route first
   (`build-os/tools/route-task.sh --task-id PILOT-0002-Tn ...`), do the
   work, commit on the pilot branch, close-fill the receipt.
   NOTE: `build-os/measure/window.sh` is for LATER pilots. PILOT-0002's
   protocol predates it; using it here would change the frozen protocol.
3. INSIDE THE WINDOW: no reporting, no correction exchanges, no unrelated
   work, no pushes, no other repository.
4. Immediately after T5's final commit, request the after-reading in ONE
   short message. THE WINDOW CLOSES when the reading arrives.
5. Record it verbatim, compute the delta between like-for-like values,
   state the attribution bound, THEN write the report.

**Abort conditions (record, do not improvise around):**
- A task's acceptance cannot be met as frozen → record the task as FAILED
  against its criteria. Do not renegotiate the criteria mid-window.
- Anything runs inside the window that is not T1..T5 → record it in the
  window record as CONTAMINATION with what it was.
- The meter resets mid-window → the delta is void; re-baseline and say so.
- The model changes mid-window → recorded confound, not an amendment.

## Phase 2 — eligibility (AFTER the pilot report is written)

6. Pin the post-pilot commit: `git -C /home/user/empathiq-website rev-parse HEAD`.
7. `bash build-os/compiler/eligibility/assess-repo.sh <repo> --out <dir outside the repo>`
   (read-only; refuses on a dirty tree, exit 2).
8. Exit 1 = INELIGIBLE → **STOP.** Record the bypass verdict as the
   result. Do not force the compiler, do not add a shell extractor to
   make the repository qualify, do not re-run against a different commit
   to get a better number.
9. Exit 0 = ELIGIBLE → record ALL evidence (parser coverage, no-parser
   share, symbol coverage, test-linkage, rule text, arithmetic, commit,
   timestamp) BEFORE looking at any task.

## Phase 3 — EXP-0004 freeze (order is load-bearing)

10. Select five tasks disjoint from PILOT-0001 and PILOT-0002 (the
    harness refuses excluded tasks at registration — let it check).
11. Operator DECLARES the salt. It is withheld from the repository.
12. Seal OUTSIDE the repo:
    `node build-os/experiments/EXP-0004-context-compiler/blinding/seal-mapping.mjs seal --rule <rule> --salt <salt> --tasks <ids> --out <path outside repo>`
13. Commit **`mapping.sha256` ONLY**. The sealed mapping and the salt
    never enter the repository before reveal.
14. Freeze and publish: task list, seed commit, model, acceptance
    criteria, arm-order rule, retry limit, measurement boundaries.
    **Sealing after the first task runs makes the commitment worthless —
    this ordering is the one error the whole blinding packet exists to
    prevent.**

## Phase 4 — execute, freeze, reveal once

15. Run the matched arms (`harness/run-exp0004.mjs`). Arm B starts with
    the rendered capsule and nothing else (Amendment 2); a violation is
    `result confounded` and the pair is EXCLUDED, never repaired.
16. Adjudicate acceptance on the BLINDED adjudicator view (no arm labels,
    no starting-context bytes).
17. `freeze.mjs` over the fourteen artifacts; it refuses on any missing.
18. Compute the ANONYMOUS provisional verdict from Arm X / Arm Y alone.
19. `reveal.mjs` ONCE. It refuses without the freeze, without the
    anonymous verdict, on digest mismatch, or on a mutated seal.
20. Translate into the SEVEN registered outcomes. If below the minimum of
    five clean pairs, the verdict is `inconclusive` AND must state the
    pair count, the minimum, the observed direction, the magnitude where
    available, and why it is underpowered (Amendment 4.2).

**Abort conditions:** any of these is recorded as `result confounded` for
the affected pair(s) and excluded from the aggregate — arm contract
violation, seed divergence, model change, measurement-boundary breach, or
a reveal attempted before the freeze conditions hold.

## After

- Re-arm the quiet-watch.
- The three maintenance debts (active-packet declaration lapse,
  helper-hidden fitted floors, stale MISMATCHES.md count) become
  eligible work again.
