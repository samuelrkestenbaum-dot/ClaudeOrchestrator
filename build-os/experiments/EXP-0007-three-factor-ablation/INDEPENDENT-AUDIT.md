# Independent frozen-stream audit — verdict: CLEAN 7/7

**Provenance:** produced by a SEPARATE agent session dispatched with an
independence contract: forbidden from reading the experiment's analysis
scripts (decisive-read.mjs, study-read.mjs, turn-causes.mjs,
text-turn-classes.mjs, implementation-reads.mjs) and all result documents;
required to write its own extraction code from scratch (/tmp/audit/audit.py)
against raw stream.jsonl / economics.json / acceptance.json / run-record.json
/ variant.json / full.diff / verification.txt only. Its report is reproduced
below VERBATIM — including the Task 2 caveat, which is the audit working as
intended: the brief's literal marker strings were wrong (a ledger row is not
stream content), and the auditor established treatment identity from three
fingerprints it found itself rather than accepting the brief's.

The headline agreement: independently derived cost ratios 2.261x / 1.100x and
uncached 2.048x / 1.099x — matching the frozen read to three decimals.

---
All verifications are complete. Here is my full independent audit report.

---

# INDEPENDENT AUDIT — EXP-0007 three-factor ablation (frozen data re-derivation)

All numbers below were re-derived from raw stored files only (`stream.jsonl`, `economics.json`, `acceptance.json`, `run-record.json`, `variant.json`, `full.diff`, `verification.txt`) using extraction code written from scratch at `/tmp/audit/audit.py` (full output: `/tmp/audit/audit-output.txt`). No experiment analysis script or result document was read.

## Task 1 — Enumeration / no selective exclusion

36 directories match the three patterns; every one is accounted for; no runnable directory on disk falls outside the census and none in the census is missing on disk.

| Group | Dirs | Admissible | Inadmissible |
|---|---|---|---|
| native (`T0X.native.runnable[.rN]`) | 12 | 12 | none |
| current (`T0X.corrected.runnable[.rN]`) | 12 | 11 | `T01.corrected.runnable.r2` — `terminal_reason=timed_out` (elapsed 1200.2 s = ceiling) |
| lean (`T0X.lean.runnable[.rN]`) | 12 | 12 | none |

All 35 admissible runs have `terminal_reason=completed`. Per-directory listing is in the audit output; every flag was read from that run's own `run-record.json`.
**VERDICT: AGREE** (native 12, current 11+1 timed_out, lean 12; zero unaccounted directories).

## Task 2 — Treatment identity

- **variant.json pinning:** all 12 lean arms carry `source_identity.requested_ref = "78bedf1"`, `resolved_commit = 78bedf187124fbb37f934f763b62cd805017ee41`, identical `source_archive_sha256`. 12/12 pass.
- **Named lean marker strings:** `"auto-routed at first mutation"` and `"AUTO-RECEIPT-MINTED"` appear **0 times in all 36 streams — including the 12 lean streams**. The brief's conditional expectation ("should appear if routing auto-minted") is not met as literally worded. However, auto-minting is independently confirmed by a different fingerprint I found myself: receipt filenames of the form `routing-auto-<timestamp>.md` appear in **6/12 lean streams** (T01.r3: 2, T02: 2, T02.r2: 2, T04: 8, T04.r2: 2, T04.r3: 2 mentions) and **0/24 native+current streams**. Additionally, all 12 lean arms (and only lean arms) carry a 1670-char `SessionStart:startup` hook beginning "Task state: routing is AUTOMATIC (first edit opens a floor receipt…)".
- **Current marker:** `"routing-request.json"` appears in **all 12 current streams** (raw mentions 9–21 per arm) and **0 times in all 12 native and all 12 lean streams**. In 9/12 current arms it appears inside `is_error` tool_results (hook refusals), counts per arm: T01 {1,2,1}, T02 {0,0,1}, T03 {3,2,2}, T04 {1,1,1}; in the two arms with 0 refusal-channel hits (T02 bare, T02.r2) I traced the mentions to the worker itself writing a `routing-request.json` (Write tool_use input + 2 non-error tool_results + assistant text) — i.e., the current ceremony was performed, just without a refusal. All 12 current arms (and only they) carry the 1443-char "Orchestrator: ON — Build OS wired" SessionStart hook. Native arms have zero non-empty hook outputs of any kind.

**VERDICT: AGREE** — three mutually independent signals give perfect 12/0/0 group separation with zero cross-contamination; noting exactly that the two literal marker strings in the audit brief occur 0/36 times and the lean auto-mint fingerprint is `routing-auto-*.md` instead.

## Task 3 — Cost/token extraction

- **Stream vs economics.json:** for all 35 runs with a final `"type":"result"` event, all six fields (`total_cost_usd`, input_tokens↔uncached_input_tokens, cache_creation_input_tokens, cache_read_input_tokens, output_tokens, num_turns) agree within 0.5% — in fact exactly. Zero mismatches. The timed-out arm has no result event and all-null economics (consistent; excluded everywhere as inadmissible).
- **My task-paired means** (per task: mean over admissible reps; then mean over the 4 tasks; uncached = input_tokens + cache_creation_input_tokens from the stream):

| Group | Mean cost (USD) | Mean uncached tokens |
|---|---|---|
| native | 1.1120 | 38,463 |
| current | 2.5147 | 78,783 |
| lean | 1.2230 | 42,256 |

Per-task means: native cost {T01 0.9364, T02 0.7817, T03 0.8197, T04 1.9103}; current {2.8764 (n=2), 2.0151, 1.9998, 3.1673}; lean {0.9821, 0.9397, 0.8097, 2.1604}.
- **Ratios:** cost current/native = **2.261**, lean/native = **1.100**; uncached tokens current/native = **2.048**, lean/native = **1.099**.

**VERDICT: AGREE** (0 mismatches > 0.5%; my independently derived ratios show current ≈ 2.0–2.3× native while lean ≈ 1.10× native).

## Task 4 — Acceptance

- Accepted counts among admissible arms: **native 12/12, current 11/11, lean 12/12**.
- For all 35 accepted arms: `verification.txt` exists and `full.diff` is non-empty (checked exhaustively, not sampled). Zero violations.
- Random spot-check (seeded RNG, 3 arms/group): grep of `verification.txt` for the arm's task file found **0 remaining `error TS` lines** for the task file in all 9 sampled arms (native: T02.r3, T01, T04.r3; current: T01, T03.r3, T04.r3; lean: T04, T04.r3, T03).

**VERDICT: AGREE**.

## Task 5 — Compiler execution (lean arms)

In-band Bash `tsc` executions per lean arm (tool_use matched to tool_result by `tool_use_id`; counted only non-error results with compiler-ish output; excluded background/incomplete/permission-refused): T01 {2, 2, 3}, T02 {4, 3, 2}, T03 {5, 5, 4}, T04 {2, 2, 1}. **All 12 lean arms ≥ 1** (min 1, max 5, total 35). These are conservative lower bounds — my strict classifier additionally excluded several genuine tsc runs whose output was only a grep-count number (e.g. "779", "total: 1063 / UserDashboard: clean"); including those would only raise the counts.
**VERDICT: AGREE**.

## Task 6 — Control-interaction counts (independent definitions, admissible arms)

Per-group means using exactly the brief's definitions ((a) is_error tool_results on Edit/Write/Bash starting "PreToolUse" or containing MUTATION BLOCKED / CONCESSION BLOCKED / STOP DEFERRED; (b) assistant text-only messages ≥ 1500 chars, grouped by message id; (c) Read calls with file_path containing `build-os/` or `.claude/`):

| Group | control_refusals | long_reports | substrate_reads |
|---|---|---|---|
| native (n=12) | **0.00** | 0.67 | **0.00** |
| current (n=11) | **2.91** (range 1–6) | **2.36** (range 1–4) | **2.00** (range 0–4) |
| lean (n=12) | **0.00** | **0.58** | **0.00** |

Cross-check via the hook_response channel (not part of the brief's definition): current arms show 50 BLOCKED hook events across 11 admissible arms (mean 4.55); native 0; lean 2 total, both in `T04.lean.runnable` (1 `PreToolUse:Agent` "DISPATCH BLOCKED", 1 Stop-hook "STOP DEFERRED") — so lean is "near zero" rather than absolutely zero on control interactions, but zero under the brief's tool_result-based definition.
**VERDICT: AGREE** — current materially above zero on all three; lean 0.00 on (a) and (c) and 0.58 ≤ 1 on (b).

## Task 7 — Treatment leakage (lean streams)

Grep of all 12 lean `stream.jsonl` files for `EXP-000`, `LEAN-MANIFEST`, `TARGET-OPERATING-MODEL`, `2.44x`, `program.json`: **0 hits for every needle in every lean stream**. (The "receipt" strings present in lean streams were traced to product source code (`CanonicalVerdictReceipt` in the seed repo) and to the lean treatment's own SessionStart hook — not to experiment or doctrine state.)
**VERDICT: AGREE**.

---

**OVERALL: CLEAN** — 7/7 tasks agree with the frozen result; the only caveat worth recording is in Task 2: the two literal lean marker strings named in the audit brief occur 0/36 times, and lean auto-minting is instead evidenced by `routing-auto-*.md` receipt references (6/12 lean arms, 0/24 others) plus the lean-only SessionStart hook (12/12 lean, 0/24 others).
