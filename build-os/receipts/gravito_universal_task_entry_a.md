# Receipt — `gravito_universal_task_entry_a`

- **Packet id:** `PACKET-0054-universal-task-entry`
- **Title:** universal task-entry governance — the operator's narrow 7-item
  correction closing the gap named after PACKET-0053: "live dispatch governance
  completed; universal task-entry governance still incomplete." The
  mutation-capable tool boundary now governs EVERY session's parent-only work,
  not only `Task|Agent` dispatch.
- **Date closed:** 2026-08-06.
- **Lane:** `substantive`. **Depth 3, announced** — (1) build; (2) qa ‖
  reviewer concurrently; (3) one bounded fix round (`Depth: 3 — reason:
  fix-then-pass (1 enumerated item)`), targeted re-review at that item only.
- **Branch:** `claude/project-handoff-merge-ramhds`.

## 1. Scope

**In:** the operator's seven items, exactly: (1) an execution-start boundary
for every substantive task including parent-only work; (2) an active routing
record required before any MUTATION-CAPABLE tool use
(`Edit|Write|NotebookEdit|Bash`), not only `Task|Agent`; (3) exploratory reads
(`Read/Grep/Glob` and read-only inspection) distinguished from execution —
counted, ungated; (4) all tool activity and eventual provider telemetry bound
to the task record; (5) long/repetitive parent-loop detection forcing
reassessment (block-with-reroute, estimate-tier token proxy honestly labeled
ESTIMATE, fire-once); (6) the hook contract expressed as a PROVIDER-ADAPTER
contract with the Claude hooks as its first adapter, labeled; (7) live
token/cost as an adapter capability with honest fallback tiers where exact
telemetry is absent. DEADLOCK GUARD a hard requirement: the routing tools
themselves pass ungated (logged), or no session could ever issue the receipt
its first `Edit` requires.

**Explicitly out:** the real-repository pilot (the NEXT step after this
closes, not this packet); `bench/`, all EXP trees (`build-os/experiments/`),
and the metrics store frozen across the packet's build — qa verified all
three untouched by the measured commits; the metrics row added by THIS close
commit is the adoption guard's own mandated close bookkeeping
(`check-adoption.sh` refuses a receipt with no row), not packet build work.
`residue.md` frozen (blob `01517ad2c30d447949a98d0b6db9b8d6b538d5a9`,
unchanged at this close). No push without go.

## 2. Base and commits

- **Base:** `ef36c42` — the pushed tip (PACKET-0053's close), verified
  `git merge-base HEAD origin/claude/project-handoff-merge-ramhds` = `ef36c42`
  at this close, tree quiet.
- `725c6a4` — docs(packet): declare PACKET-0054-universal-task-entry + the
  packet's own routing receipt via `route-task.sh` (gravito_full via the
  honest value factors `high_blast_radius` + `high_rework_history` — this gate
  governs every session's mutation-capable tool use), issued BEFORE building.
  2 files, +82/−0.
- `22f6bb3` — feat(routing): the build — mutation-capable boundary, deadlock
  guard, explore/execute split, fire-once reassessment, provider-adapter
  contract, with same-commit registration (census **126 → 128**). 14 files,
  +922/−32.
- `d30be0c` — the **one permitted fix commit**: the reviewer's single
  enumerated item, prose-only (§4). 1 file, +18/−4. No hook lines shifted, no
  anchors re-pointed.
- **2 build commits + 1 fix commit** — within the contract's budget. This
  close commit is the fourth and final commit touching only `build-os/`.

### Disjoint file-ownership manifest — SINGLE-WRITER, sequential commits, no fan-out

One builder produced all three commits in sequence and owned all 14 build
files; **merger N/A** (no fan-out; qa and the reviewer held no mutating
tools). Attribution stays recoverable by path via `git show --numstat`:

- `725c6a4` — `build-os/packets/active_packet.md` (+24 declaration);
  `build-os/packets/routing/routing-PACKET-0054-universal-task-entry-20260806T002034Z.md`
  (new, +58).
- `22f6bb3` — `.claude/hooks/routing-gate.sh` (+204/−10);
  `.claude/settings.json` (+9);
  `build-os/memory/provider_adapter_contract.md` (new, +46);
  `build-os/memory/routing_contract_live.md` (+62/−7);
  `build-os/registry/control_registry.txt` (+41/−5, census 126→128);
  `build-os/registry/mutator_registry.txt` (+3/−3);
  `build-os/registry/neurocosmology_crosswalk.txt` (+14);
  `build-os/registry/CROSSWALK.md` (+2/−2); `build-os/registry/MISMATCHES.md`
  (+1/−1); `build-os/registry/README.md` (+1/−1);
  `build-os/tools/record-degradation.sh` (+5/−2);
  `build-os/tools/routing-check.sh` (+17/−0, extension not fork);
  `tests/routing_task_entry_tests.sh` (new, +516);
  `tests/build_os_tests.sh` (+1/−1, chain).
- `d30be0c` — `build-os/memory/routing_contract_live.md` (+18/−4, prose only).
- Per-commit numstat sums: **16 distinct paths, +1022/−36**. Net union diff
  `ef36c42..d30be0c` = 16 files, +1018/−32. The two **reconcile exactly**: the
  gap is 4 lines added by the build commits and rewritten within-range by the
  fix commit (1022−4=1018; 36−4=32).

## 3. What shipped

**The universal task-entry boundary.** `routing-gate.sh` extended with a
mutation gate (mutgate) on `Edit|Write|NotebookEdit|Bash`: an active routing
record is required before any mutation-capable tool use, parent-only work
included — the PACKET-0053 gate covered only `Task|Agent` dispatch.

**The deadlock guard, with its breadth honestly stated.** A Bash event naming
any routing tool (`route-task.sh`, `mode-select.mjs`, `routing-check.sh`,
`record-degradation.sh`) passes UNGATED, logged `ROUTING-TOOL-PASS` — without
it no session could issue the receipt its first gated call requires. Its TRUE
breadth is a substring test over the ENTIRE raw hook JSON, before the git
classification (compound commands, comments, and non-command fields all pass;
`ROUTING-TOOL-PASS` mislabels such events); it is the sole ungated pass in the
boundary, and the match is deliberately NOT narrowed — a guard that could
misparse an event and block the receipt-issuing command would re-create the
deadlock it exists to prevent (§4, the fix).

**Explore/execute split.** Read-only tools and read-only git inspection are
counted, ungated — exploration is never taxed as execution.

**Fire-once parent-loop reassessment.** Long/repetitive parent loops trip a
block-with-reroute forcing reassessment; the token proxy is estimate-tier and
labeled ESTIMATE, never presented as exact. Escalation reset is gated on
change-since-arming-snapshot (§5, finding 1).

**Provider-adapter contract.** `build-os/memory/provider_adapter_contract.md`:
the hook contract as a provider-adapter interface, Claude hooks the first
adapter (labeled); the Codex row is **interface-unverified** (the provider is
unreachable, §6); live token/cost is an adapter capability with honest
fallback tiers (exact → estimate → `-`).

**SELF-APPLICATION, TWO NOTES BINDING ON THE NEXT SESSION.** (a) From next
session start, `live_gate_log.tsv` and `live_state/*.tsv` accrue as UNTRACKED
ledgers — future packets must declare them packet-expected-unstaged at
tree-quiet checks, or every gate run reports a dirty tree that is actually the
governor working. (b) This close fills the last open routing receipt, so the
next session's FIRST mutation-capable call will be BLOCKED by the new mutgate
until it routes — mandatory task entry working by design; recovery is one
`build-os/tools/route-task.sh` command, carried in the refusal message.

## 4. Verdict chain and QA proof — recorded exactly

- **qa: GREEN.** FULL SUITE **2801 passed / 0 failed, exit 0, solo**
  (= 2677 + 124, all of the delta the new `tests/routing_task_entry_tests.sh`).
  **Commit-1 isolation: detached worktree at `725c6a4` → 2677/0.** **Safety
  grep clean** — the single `rm -rf` hit is the suite's own mktemp cleanup
  trap (`tests/routing_task_entry_tests.sh:841`). Registration: census
  **128**, 0 unregistered / 0 phantom, **24** mismatches declared=reported,
  gate-on-advise **14**, evidence_refs **451** = README. Backward compat: **5
  live receipts, 0 violations**. Overhead: mutgate ALLOW ~50 ms, BLOCK
  ~30 ms, within the ≤250 ms bound. Frozen surfaces untouched (`bench/`,
  `build-os/experiments/`, `build-os/metrics/`). Safety gates 0 — no push,
  merge, deploy, or secrets.
- **Reviewer: fix-then-pass, 1 item**, fixed in `d30be0c`:
  1. **`routing_contract_live.md` understated the deadlock guard's breadth**
     ("in the command" vs a substring test over the entire raw hook JSON) —
     fixed by stating the full breadth, the `ROUTING-TOOL-PASS` mislabel
     audit-read instruction, the sole-ungated-pass status, and the deliberate
     non-narrowing rationale.
- **Declined hardening, on the record:** the reviewer's optional
  `mut_classify` reorder was DECLINED with a stated reason — the brick: a
  receipt-issuing command whose `--description` mentions a git-mutating word
  would be blocked, and the blocked command IS the recovery command. The
  reviewer validated the scenario and withdrew the suggestion.
- **Targeted re-review at the one item: pass.** No reviewer exception fired.
- **Verdict: PASS-AS-FIXED.** Depth 3, announced.
- **UI smoke:** n/a — no UI surface.

## 5. Notable gate findings

1. **Builder's named limitation 4 TESTED AND REFUTED by the reviewer.** The
   claimed hole — "pre-armed escalation resolves the first trip" — is not
   real: the reset is gated on change-since-arming-snapshot. Recorded as
   **refuted**, not open.
2. **Reviewer residual, FUTURE SCOPE, not a defect:** `ROUTING-TOOL-PASS` log
   rows carry no command text, so the log alone cannot distinguish a genuine
   routing-tool invocation from a mention. Ledger-level disambiguation (e.g. a
   command excerpt in the detail field) is a future packet.
3. **Codex second-eyes NOT performed** — 403 at the proxy (§6). Stated, not
   pretended.

## 6. Second eyes

**NONE** — Codex 403 at proxy (`api.openai.com:443` CONNECT policy-denied);
the attempt is stated, not pretended. The router's `DC-0001` second-eyes
streak numeral moves **33 → 34 in this same close commit**, derived from the
receipt store (`ls build-os/receipts/gravito_*.md | wc -l`), never restated.

## 7. Live routing receipt closed at this close

`executed_mode: gravito_full` (matches selected; no escalation — `escalation`
stays `-`). `consumed_process_dispatches: 5` — **transcript-derived,
CLOSE-TIME tier, NOT a hook-measured EXACT count**: builder 1 + qa 1 +
reviewer 1 + targeted re-review resume 1 + archivist 1 = 5, within the
allowance of 7. This session's hooks are NOT loaded (they went live for NEXT
session at PACKET-0053), so no `live_state/` file exists for this packet — no
STATE row can corroborate or contradict the figure, and the provenance is
recorded on the receipt itself. All other consumption fields stay `-`: honest
admissions, not zeros nobody measured.

## 8. Residue

- **Finding 2 above is the packet's only open residual** — ledger-level
  `ROUTING-TOOL-PASS` disambiguation, future scope by the reviewer's own
  classification.
- **The real-repository pilot is the NEXT step**, explicitly out of this
  packet; staging it is a routing act, and the archivist takes none.
- The two self-application notes in §3 bind the next session's tree-quiet
  checks and its first mutation-capable call.

## 9. Open boundaries

- **NOTHING PUSHED.** `725c6a4`, `22f6bb3`, `d30be0c`, and this close commit
  remain local pending explicit operator go (**4 commits ahead of origin
  after this close**, derived from git). **None may be amended** — the first
  two are the tree the gates measured. No merge, no deploy, no secrets
  touched. `residue.md` stays frozen (blob `01517ad2…`).
