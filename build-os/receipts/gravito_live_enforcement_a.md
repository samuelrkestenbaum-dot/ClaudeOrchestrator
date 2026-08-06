# Receipt — `gravito_live_enforcement_a`

- **Packet id:** `PACKET-0053-live-enforcement`
- **Title:** the operator's live routing & economic enforcement directive —
  "turns Gravito from an auditor of agent behavior into a true runtime
  governor": an always-present execution control plane that can intervene
  WHILE work happens, honest-scoped between what a hook can mechanically
  refuse and what stays protocol or is named as not-yet-enforced.
- **Date closed:** 2026-08-06.
- **Lane:** `substantive`. **Depth 3, announced** — (1) build; (2) qa ‖
  reviewer concurrently; (3) one bounded fix round (`Depth: 3 — reason:
  fix-then-pass (2 enumerated items)`), targeted confirmation at those items.
- **Branch:** `claude/project-handoff-merge-ramhds`.

## 1. Scope

**In:** the seven operator-required capabilities, built across four labeled
enforcement layers (§3): mandatory routing entry, an automatic routing hook
replacing file-only instruction, live resource visibility with exact telemetry
vs estimates labeled separately, fan-out throttling at the budget threshold,
automatic Full→Light degradation that stops the expensive mode and not the
task, cost attribution by layer, and marginal-contribution tracking per Full
agent. Eleven required tests, red-driven. Honest-scoping rule standing:
mechanical only where a check can execute (the `.claude/hooks` PreToolUse
layer CAN observe and BLOCK tool calls live); token/cost live values are NOT
hook-visible in interactive sessions and are labeled as such. No checkbox that
looks enforced and is not. Direct stays near-zero overhead.

**Explicitly out:** benchmarks, EXP re-runs, broad governance, memory files
beyond the packet's own receipts, `residue.md` (frozen, blob `01517ad2…`
unchanged at this close), `bench/` and the experiment trees. No push without
go.

## 2. Base and commits

- **Base:** `89d67df` — the pushed tip (rotation #5 applied), verified with
  `git merge-base 61503fa 89d67df` → `89d67df` at this close, tree quiet.
- `aa0c968` — docs(packet): declare PACKET-0053-live-enforcement + the
  packet's own routing receipt via `route-task.sh` (gravito_full via the
  honest value factors `high_blast_radius` + `high_rework_history`), issued
  BEFORE building. 2 files, +56/−0.
- `dda0dea` — feat(routing): the live enforcement build, with **same-commit
  registration** of the new refusal-capable surfaces — census **121 → 126**.
  15 files, +1402/−11.
- `61503fa` — the **one permitted fix commit**: both reviewer items, exactly
  as enumerated (§4). 7 files, +39/−25. **Amended twice pre-measurement,
  disclosed:** first a message typo; then the anchor re-pointing its own
  `logrow` edit caused — 8 registry citations shifted +5 lines, re-pointed by
  content verification. Both amends preceded the targeted-confirmation
  measurement; the two measured build commits were never rewritten.
- **2 build commits + 1 fix commit** — within the contract's budget.

### Disjoint file-ownership manifest — SINGLE-WRITER, sequential commits, no fan-out

One writer produced all three commits in sequence; qa and the reviewer held no
mutating tools. Attribution stays recoverable by path via `git show --numstat`:

- `aa0c968` — `build-os/packets/active_packet.md` (+24 declaration);
  `build-os/packets/routing/routing-PACKET-0053-live-enforcement-20260805T222530Z.md`
  (new, +32).
- `dda0dea` — `.claude/hooks/routing-gate.sh` (new, +330);
  `.claude/settings.json` (+31, prior hooks preserved);
  `build-os/tools/record-degradation.sh` (new, +96);
  `build-os/tools/route-task.sh` (+25);
  `build-os/tools/routing-check.sh` (+91/−2, extension not fork);
  `build-os/memory/routing_contract.md` (+7);
  `build-os/memory/routing_contract_live.md` (new, +98);
  `build-os/registry/control_registry.txt` (+91/−1, census 121→126);
  `build-os/registry/mutator_registry.txt` (+34);
  `build-os/registry/neurocosmology_crosswalk.txt` (+35);
  `build-os/registry/CROSSWALK.md` (+4/−4); `build-os/registry/MISMATCHES.md`
  (+4/−2); `build-os/registry/README.md` (+1/−1);
  `tests/routing_live_gate_tests.sh` (new, +554);
  `tests/build_os_tests.sh` (+1/−1, chain).
- `61503fa` — `.claude/hooks/routing-gate.sh`;
  `build-os/memory/routing_contract_live.md`;
  `build-os/registry/MISMATCHES.md`; `build-os/registry/control_registry.txt`;
  `build-os/registry/mutator_registry.txt` (the 8 shifted citations re-pointed
  by content); `build-os/tools/route-task.sh`;
  `tests/routing_live_gate_tests.sh` (RT9 now drives the full 7-dispatch
  regate shape and blocks the 8th).
- Per-commit numstat sums: **17 distinct paths, +1497/−36**. Net union diff
  `89d67df..61503fa` = 17 files, +1472/−11. The two **reconcile exactly**: the
  gap is 25 lines added by the build commits and rewritten within-range by the
  fix commit (1497−25=1472; 36−25=11).

## 3. What shipped — the four enforcement layers, labeled

**LAYER 1 — MACHINE, BEFORE EXECUTION.** `.claude/hooks/routing-gate.sh`
(PreToolUse on `Task|Agent`): the **receipt-presence gate** — a substantive
dispatch cannot execute without an open routing receipt; **depth enforcement**
— light/direct dispatch is blocked absent an evidence-bearing escalation;
**fan-out throttle AT the budget, BEFORE the dispatch executes**; the
**process-allowance ledger** (default **7 = the `mandatory_full_regate` chain**,
DERIVED from the doctrine's largest legal chain shape, separate from the task
budget — the PACKET-0050/0051 calibration question resolved); **auto-stamped
degradation** via `record-degradation.sh` with consolidate-and-continue
language ("Stop the expensive mode, not the task"); **every decision logged**,
with a model-visible stderr fallback when the store is unwritable.

**LAYER 2 — MACHINE, AT CLOSE.** `routing-check.sh` **extended, never
forked**: **CONTRIBUTION-MISSING** refusal for Full-with-dispatches;
**STATE-DISAGREE** reported and never reconciled (no side auto-corrected);
**seven attribution layers** (task_execution, context_retrieval,
subagent_execution, verification, review, governance_process,
experiment_audit); old receipts pass as `-` admissions — absence is an
admission, not a defect.

**LAYER 3 — PROTOCOL, DURING.** Context minimization + token awareness,
labeled as protocol in `routing_contract_live.md` — not claimed as mechanical.

**LAYER 4 — NOT YET ENFORCED, NAMED.** Live tokens/cost are hook-invisible in
interactive sessions (`unavailable_live`, never estimated-as-exact);
non-dispatch work is ungated beyond receipt presence + counting; unhooked
sessions are ungated; and the **residual no-trace vector** — store unwritable
AND stderr discarded — is named here instead of an unconditional-trace claim.

**GOES LIVE AT NEXT SESSION START** — hooks load then, not mid-session.

## 4. Verdict chain and QA proof — recorded exactly

- **qa: GREEN.** FULL SUITE **2677 passed / 0 failed, solo**, with per-suite
  delta arithmetic (+132, all of it the new `routing_live_gate_tests.sh`).
  **Commit-1 isolation: 2545/0 at `aa0c968`** and **2677/0 at `dda0dea`**. The
  hook driven through **every branch with qa's own fabricated stdin** — all
  seven behaviors confirmed, including **FAIL-OPEN logging** and
  **DISABLED-BY-OPERATOR logging**. **Backward compat proven on real pre-0053
  receipts.** Settings wiring valid with prior hooks preserved. Overhead
  **re-measured 27 ms/call** on the counter path (builder had measured
  27–28 ms) vs the asserted **≤250 ms** bound; the gate path (jq) is
  dispatch-only. Census **126**, declared mismatches **24**, gate-on-advise
  **unchanged at 14**, README refs **440 derived**. Frozen surfaces intact.
  Hook-specific safety scrutiny clean. Safety gates 0 — no push, merge,
  deploy, or secrets.
- **Reviewer: fix-then-pass, 2 items**, both fixed in `61503fa`:
  1. **The `process_dispatch_allowance` default 4 would have refused every
     legitimate fix-then-pass (6 dispatches) and the doctrine-mandated
     `mandatory_full_regate` re-gate (7) from next session** — raised to
     **7, DERIVED from the doctrine's largest legal chain shape**, with RT9
     now driving the full 7-dispatch regate shape and blocking the 8th.
  2. **The unwritable-store no-trace vector** — `logrow` now falls back to a
     model-visible stderr line, and the residual vector (store unwritable AND
     stderr discarded) is **named in layer 4** instead of an
     unconditional-trace claim.
- **Targeted confirmation:** gate suite **132/0**, registry suite **180/0**,
  `scan-controls` **0**, FULL SUITE **2677/0 solo at `61503fa`**.
- **Verdict: PASS-AS-FIXED.** Depth 3, announced. No reviewer exception fired.
- **UI smoke:** n/a — no UI surface.

## 5. Live routing receipt closed at this close

`executed_mode: gravito_full` (matches selected; no escalation — `escalation`
stays `-`); consumption fields stay `-` with the transcript-only admission on
the receipt. `consumed_process_dispatches` stays `-` and the admission is
specific: **the hook that counts process dispatches loads at NEXT session
start, so no `live_state/` file exists for this packet — the count is
transcript-only and is not derivable from any committed record.** Post-fill
sweep: `routing-check.sh check` — **4 receipts checked, 0 violations, exit 0**.

### CRITICAL OPERATIONAL NOTE — the next session's first dispatch WILL be blocked

When this close fills `executed_mode`, **NO routing receipt remains open**. At
next session start the hooks load, and **the next session's FIRST substantive
dispatch will be BLOCKED by design** until it issues a routing receipt via
`build-os/tools/route-task.sh`. **That is mandatory routing entry working, not
a malfunction** — the refusal message carries the recovery command.

## 6. Second eyes

**NONE** — Codex 403 at proxy (`api.openai.com:443` CONNECT policy-denied),
**attempted and stated by both gates**. The router's `DC-0001` second-eyes
streak numeral moves **32 → 33 in this same close commit**, derived from the
receipt store (`ls build-os/receipts/gravito_*.md | wc -l`), never restated.

## 7. Residue

- **Layer 4 stands open by design and by name:** live token/cost
  hook-invisibility (`unavailable_live`), non-dispatch work ungated beyond
  receipt presence + counting, unhooked sessions ungated, and the residual
  no-trace vector (store unwritable AND stderr discarded).
- The fix commit's double amend (message typo; +5-line anchor shift,
  re-pointed by content verification) was **pre-measurement and disclosed** —
  recorded here so the amend trail is on the receipt, not only in the
  transcript.
- **NOTHING STAGED NEXT** — the operator's directive ends with "complete the
  bounded build, report the evidence, and stop for the next product decision."
  Staging anything would be a routing act, and the archivist takes none.

## 8. Open boundaries

- **NOTHING PUSHED.** `aa0c968`, `dda0dea`, `61503fa`, and this close commit
  remain local pending explicit operator go (**4 commits ahead of origin after
  this close**, derived from git). **None may be amended** — the first two are
  the tree the gates measured. No merge, no deploy, no secrets touched.
