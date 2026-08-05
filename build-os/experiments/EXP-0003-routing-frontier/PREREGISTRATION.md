# EXP-0003 — Preregistered protocol: which routing mode produces the lowest total cost per durable accepted outcome for each task shape?

**Status: PREREGISTERED. Committed before any experimental run. Not revisable after run 1.**

Operator directive (2026-08-05, post-EXP-0002 §4): the bounded three-condition
experiment. EXP-0002 registered `no sustained-workload savings detected` and
localized the mechanism — overhead is protocol-invocation-dependent, not fixed
(ON cheaper on T1/T4, 3.9×/7.8× costlier on T3/T5). PACKET-0050 productized the
correction: binding selector verdicts, routing receipts with derived budgets,
a mechanical close-time gate. EXP-0003 measures the corrected surface. The
output is the **ROUTING FRONTIER** — the per-shape winner among three routing
modes — not a single aggregate verdict. **The conclusion rule is NEUTRAL by
operator instruction: no directional asymmetry exists anywhere in this
protocol**, so the EXP-0002 mistranslation class (a symmetric evaluator wording
mistranslated through a direction-bearing registered rule) **structurally
cannot recur — there is no directional rule to mistranslate through.**

## 1. Experimental question

For each of three task shapes (feature-from-spec, injected regression,
context-dependent follow-up), which of three routing modes — direct/raw,
gravito_light under a binding receipt, gravito_full under a binding receipt
with enforced budgets — produces the **lowest total tokens per durable
accepted outcome**? Secondary, same shape: the uncached variant, cost, wall
clock, dispatches.

## 2. Conditions — exact mechanics, and exactly what each agent sees

One three-task mini-sequence per condition (T3 → T4 → T5), on one evolving
work tree per condition, fresh headless session per task (`claude -p`),
byte-identical prompts and permissions. Condition order fixed **A → B → C**
(§8, confound C2). Harness: `harness/run-exp3-task.sh` (new, EXP-0003-owned);
frozen EXP-0002 machinery is **reused by invocation only** (§7).

**Condition A — direct/raw.** Seed + scripted T1/T2 setup (§3) and nothing
else. No `.claude/`, no `CLAUDE.md`, no `build-os/`, **no receipt — disclosed:
A has no routing receipt and no close-time gate run; its close-fill step does
not exist and the harness refuses it by name.**

**Condition B — installed surface + binding gravito_light receipt.**
After the scripted setup: `install-project.sh --no-session-hook <worktree>`,
then a routing receipt issued by the REAL issuer
(`build-os/tools/route-task.sh`, the PACKET-0050 surface — RUN, never edited)
and placed at the fixed path
`build-os/packets/routing/routing-EXP-0003-sequence.md` in the work tree,
then a pointer block appended to `build-os/memory/tool_router.md`, then the
pristine baseline captured (so surface, receipt and pointer are baseline,
never task output).

**Condition C — installed surface + binding gravito_full receipt with the
derived budgets.** Identical to B in every mechanical step; the ONLY input
difference is one boolean in the descriptor fed to the issuer.

**B and C differ ONLY in receipt content — stated byte-precisely.** Both
receipts are issued by `route-task.sh` with:
- the same `--task-id EXP-0003-sequence` (hence the same fixed placed path);
- the same `--description` text, verbatim: `EXP-0003 measured three-task
  sequence (T3 discount-code feature, T4 injected regression, T5 summary
  follow-up) on the prepared parcel-billing tree` (hence identical
  `description_sha256`);
- descriptors identical in 12 of 13 fields
  (`expected_files_changed:4, requires_tests:true, expected_session_count:3,
  prior_context_required:true, handoff_required:false,
  consequence_level:"medium"`, all other value factors `false`), differing in
  exactly `high_rework_history`: **B `false` → selected_mode `gravito_light`
  (Full withheld, the selector's note captured in the receipt); C `true` →
  selected_mode `gravito_full`** (the honest value factor: three consecutive
  experiment packets required fix rounds — the same factor PACKET-0051's own
  live receipt used). Verified by execution before this preregistration.
- Within the two receipt files the differing bytes are therefore exactly:
  `descriptor` (one boolean), `selected_mode`, `selector_note`, the six
  `budget_max_*` values (B light band: 0 subagents / 500,000 total / 60,000
  uncached / 25 calls / 600 s / $0.75; C full band: 3 / 2,000,000 / 120,000 /
  40 / 900 / $1.50 — the PACKET-0050 derived defaults, not retuned here), and
  `issued_at` (wall-clock timestamp of issuance — unavoidable, disclosed).
  Everything else, including the pointer block appended to `tool_router.md`,
  is **byte-identical** between B and C. Nothing else differs.

**Install-surface disclosure — what the installer actually ships, verified by
reading `install-project.sh` at the commit of this preregistration.** The
installed surface is: `.claude/agents/*.md`, `.claude/commands/*.md`,
`.claude/hooks/*.sh` (+x), `.claude/settings.json` with the
`UserPromptSubmit` prompt-router hook (SessionStart omitted —
`--no-session-hook`), the memory scaffold from `templates/`
(`build-os/memory/tool_router.md`, `current_state.md`, `residue.md`,
`build-os/packets/active_packet.md`, `build-os/receipts/README.md`), the
maintenance layer, identity stamps, and a managed `CLAUDE.md` block copied
from `build-os/global-claude-md.md`. **That managed block carries a SIX-step
per-task protocol and NO routing step: it never mentions routing receipts,
`route-task.sh`, `routing-check.sh`, or `routing_contract.md`** (the step-7
routing hook exists only in THIS repository's own CLAUDE.md, which is not
installed). **The installer ships NO `build-os/tools/` and NO
`routing_contract.md` into the target.** The B/C agents therefore cannot
discover the routing surface from the installed protocol text alone; the ONE
installed file that protocol's step 2 directs every session to read is
`build-os/memory/tool_router.md`, and that is where the harness appends the
pointer block (byte-identical in B and C) naming the receipt's fixed path and
restating the binding rule and the five-step circuit-breaker protocol from
`routing_contract.md`. **What a B or C agent sees is exactly: the installed
surface above + the pointer block + the placed receipt. What an A agent sees
is exactly: the task repository.** No condition's prompt text mentions any of
this.

## 3. Deterministic scripted T1/T2 setup — identical across conditions, digest-pinned

The three measured shapes presuppose the T1/T2 state. It arrives by
`harness/setup-t1t2.sh` — a deterministic scripted reference completion
applied to the fresh seed **before** any measured run and **before** the
condition surface (so it is identical in A, B and C and part of every
baseline): the reference `DIAGNOSIS.md` (fixed bytes), the one-line `tierFor`
fix (`<` → `<=` on the small-tier line, exact-match, refused unless the buggy
line occurs exactly once), and the reference boundary test
`test/pricing-boundary.test.js` (4 assertions). The script **drives the
frozen EXP-0002 oracle on both tasks** — `oracle-exp2.js T1` (diagnosis
present, nothing else changed) and `oracle-exp2.js T2` (boundary matches
spec; suite green and larger; the transplant differential executes: the added
test FAILS on the unfixed source) — and refuses on any rejection, so the
T3/T4/T5 preconditions are oracle-legitimate, not asserted.

Pinned identities (mechanical refusals in the runner, not notes):
- seed digest (EXP-0002's frozen seeder, unchanged):
  `128485c6082bdf7305168001212b1e2aa7005815be9c00735185eecfdb8cc06f`
- post-setup tree digest (derived by executing seed+setup twice before this
  commit; two runs byte-identical):
  `6c77b5a4bda46ba4730ccf1b2a08725a76523e87ac7402096744659d0c47b6aa`
- seeded suite exactly `TOTAL: 19 passed, 0 failed`; post-setup suite exactly
  `TOTAL: 23 passed, 0 failed`.

## 4. The three measured shapes — EXP-0002's FROZEN prompts, verbatim

The task text is EXP-0002's frozen `harness/tasks.md`, **reused by
invocation**: the runner extracts each prompt mechanically (first fenced block
of the task's section) and **refuses to run if the extracted sha256 differs
from the pins below** (EXP-0002's sealed per-task values, re-derived before
this commit):

| shape | task | task_prompt_sha256 (pinned) |
|---|---|---|
| feature from spec | T3 | `aa51dd7f4329ecfabd20348cefe0e78cc324cefe9c6e9b56455bc7b8e163fcbc` |
| injected regression | T4 | `39638bc19253701d624915b5e9c651335e9f1193cf7da9b1a7f49c552fad29f1` |
| context-dependent follow-up | T5 | `f2dd4ce545ffd523a564ed9139d9f3b86725a0b1b48c98eabd3fd7ef53031d5c` |

T4's regression test is injected by the frozen `inject-t4.sh` (invoked
read-only, byte-identical across conditions) after T3 closes. Acceptance per
task is the frozen external `oracle-exp2.js` (executed, mechanical, never
named in a prompt). Permissions identical across all nine runs:
`--permission-mode acceptEdits --allowedTools "Bash(node:*)"` with the CLI
2.1.222 non-bindingness disclosure carried in every record.

## 5. Telemetry — modelUsage-NATIVE (the recorded EXP-0002 defect, fixed in this NEW runner)

EXP-0002 recorded (harness frozen, fix deferred): the parent result event's
`usage.*` block undercounts dispatch-heavy sessions (~70× on buildos T3). In
this NEW runner the token and cost **primaries are summed across the result
event's `modelUsage` entries**: `mu_total_tokens = inputTokens + outputTokens
+ cacheReadInputTokens + cacheCreationInputTokens` summed over models;
`mu_uncached_tokens = mu_total_tokens − cacheRead`; `mu_cost_usd = Σ costUSD`.
`mu_cost_usd` is **reconciled against `total_cost_usd` and the record is
REFUSED on disagreement > 1e-6** (written as `run_record.REFUSED.txt`, exit 2,
retained — a refused record is data). The parent `usage.*` block is recorded
**beside** the primaries, never merged, with the preregistered
`usage_block_disagrees` criterion: `yes` iff any of the four token fields
differs from its modelUsage-summed counterpart (both sides numeric); `-` when
either side is unavailable. Also per run: two-witness structural tool counts,
two-witness subagent dispatch counts, wall clock, tree digests before/after,
oracle verdict, cli_exit/is_error/stop_reason. Weekly meter: unobservable
here, recorded as such, never estimated. Unknowns are `-`, never zero.

## 6. The mechanical close-time budget gate — first exercise on measured numbers

After a condition's three tasks (B and C only; **A has no receipt,
disclosed**), the harness fills the condition receipt's consumption fields
from the summed measured telemetry of the three sealed records
(`consumed_total_tokens`, `consumed_uncached_tokens`, `consumed_model_calls`,
`consumed_wall_clock_s`, `consumed_cost_usd`, `consumed_subagents` from the
structural dispatch counts; a field is filled only when all three per-run
values are machine-derived, else it stays `-` — an unknown is not a zero), and
sets `executed_mode` by the **disclosed mechanical proxy**: ≥1 structural
subagent dispatch across the sequence → `gravito_full`; 0 → the selected
mode; unknown → `-`. Named bound: a Full ceremony that dispatches no subagent
is invisible to this proxy. The harness **never writes** `escalation`,
`escalation_evidence` or `degradation_note` (they stay `-`).

Then `build-os/tools/routing-check.sh check --receipt <it>` runs on the filled
receipt — **the PACKET-0050 close-time gate's first exercise on measured
numbers, entirely mechanical** — and its verdict is recorded **verbatim**,
with its exit code, in `gate_result.txt` beside a copy of the filled receipt.
**A refused receipt is DATA: retained, labeled, never edited to pass.** In
particular: if B's sequence dispatches subagents, the proxy fills
`executed_mode: gravito_full` over `selected_mode: gravito_light` and the gate
refuses SILENT-ESCALATION — that refusal is a primary experimental
observation, not a harness failure. Likewise any budget breach without a
degradation note. The receipt is filled exactly once; a re-fill is refused.

## 7. Reuse by invocation only — the freeze

`seed-workload-repo.sh`, `tasks.md`, `inject-t4.sh`, `oracle-exp2.js` (all
EXP-0002) are invoked read-only; **zero edits to anything under
`build-os/experiments/EXP-0001-*/`, `EXP-0002-*/`, or `bench/`.** The routing
surface (`mode-select.mjs`, `route-task.sh`, `routing-check.sh`,
`routing_contract.md`) is **run, never edited**. No optimization of Gravito or
of this harness once run 1 starts; a defect discovered mid-run is recorded,
the run labeled, machinery untouched. Failed, refused and timed-out runs
(timeout 3600 s) stay in the dataset. No push without explicit operator go.

## 8. Metrics, the NEUTRAL rule, and the vocabulary — fixed before run 1

**Durable accepted outcome** := the task's frozen oracle exits 0 AND the
sealed record is committed.

**Primary, per shape (T3, T4, T5 separately): rank the three conditions by
`mu_total_tokens` per durable accepted outcome** (n=1 per cell, so the cell
value IS the accepted run's `mu_total_tokens`; lowest wins the shape). The
**uncached ranking (`mu_uncached_tokens`) is computed beside it for every
shape**, plus cost, wall clock and dispatches as secondaries. A condition
whose run in a shape is not accepted has no durable outcome in that shape: it
is **unranked there and reported by name**; a shape with fewer than two
accepted conditions yields **no comparison** for that shape and is reported as
such. The deliverable is the **frontier table**: per shape, the ranking and
the winner, totals and uncached side by side.

**The rule is NEUTRAL — stated in so many words:** no condition is favored,
no direction is pre-assigned to any outcome, no rule maps a finding onto a
named arm asymmetrically. The per-shape winner is whatever the ranking says.
**Because no directional rule exists, the EXP-0002 mistranslation class
(symmetric evaluator wording forced through a direction-bearing label rule)
cannot recur here by construction.**

**n=1 per cell, stated in advance with the honest strength cap:** nine runs,
one per condition×shape cell, no replicates. The strongest claim any outcome
here can support is **"frontier observed"** — never "supported", never
"established". One run per cell cannot separate a real per-shape ordering
from run-to-run variance; replicates are a future operator decision.

**Three-option vocabulary — the conclusion draws EXACTLY ONE, evaluated in
this order:**
1. **`result confounded`** — `model_used` differs across the nine runs; or a
   pinned digest check failed anywhere; or acceptance failures leave fewer
   than two rankable conditions in two or more shapes; or any sealed record
   was refused (cost reconciliation) leaving a cell empty.
2. **`frontier unstable — winners flip on uncached`** — every shape rankable
   and unconfounded, but in at least one shape the uncached ranking's winner
   differs from the total ranking's winner.
3. **`frontier observed`** — every shape rankable, totals and uncached agree
   on every shape's winner. Reported per shape, with magnitudes, at n=1
   strength.

**Confounds, named:** C1 model identity per run (read from `modelUsage`
keys, never requested-model); C2 **condition order fixed A→B→C — provider
cache warmth favors later conditions; named, and separated by reporting the
uncached variant of every token metric beside the total**; C3 seed and
post-setup digests (pinned, refused on mismatch); C4 acceptance parity
(quality dominates efficiency when acceptance differs — folded into the
vocabulary above); C5 the authored-workload limitation carried from EXP-0002
(named there, unchanged here).

## 9. Blinding and ordering

Ceremony as EXP-0001/0002, adjusted for three conditions, **with the EXP-0002
audit gap closed in advance**:

1. Seal all nine run records, the two receipts + gate results, and the
   manifest; commit (this packet's second commit).
2. Blinded dataset with conditions relabeled **P/Q/R** (per-shape rows;
   **subagent dispatch counts and receipt/gate fields are EXCLUDED from the
   blinded dataset — they de-blind**, as EXP-0002's were); the P/Q/R↔A/B/C
   mapping **withheld from the tree** (session scratchpad only), its sha256
   pre-committed in `analysis/MAPPING_SHA256.txt`.
3. **The evaluator's exact neutral rule text is committed AT SEAL TIME as
   `analysis/EVALUATOR_RULE_TEXT.md`** — in EXP-0002 it was committed only
   after the gates demanded it; here it is part of the sealed commit, in
   advance, so the audit trail of what the evaluator was given exists before
   the evaluator is given it.
4. An **independent evaluator session** receives ONLY the blinded dataset and
   that committed rule text (never §2's condition schedule, never the
   receipts) and computes the per-shape rankings mechanically; its report is
   committed **VERBATIM before the mapping enters the tree**, with provenance
   recorded in a **SIBLING file** (`analysis/BLINDED_ANALYSIS_PROVENANCE.md`),
   never inside the evaluator's own text.
5. Reveal verifies the mapping byte-exact against the pre-committed hash;
   translation to condition names applies **no directional rule (none
   exists)**; conclusion draws exactly one §8 label.

Blinding limitation as before: the token signature of an installed surface
may be inferable from magnitudes; the mitigation is that the rule is
mechanical.

## 10. Outputs in order

1. this preregistration + the EXP-0003 harness + same-commit registration of
   its refusal-capable surfaces (one commit, before run 1);
2. sealed run records (9) + condition receipts and gate results (B, C) +
   manifest + blinded dataset (P/Q/R) + mapping sha256 + evaluator rule text;
3. blinded analysis, committed verbatim before reveal (next packet);
4. revealed comparison — the routing frontier table, totals and uncached;
5. conclusion — exactly one of: `frontier observed` |
   `frontier unstable — winners flip on uncached` | `result confounded` —
   at n=1 strength, with per-shape magnitudes and the receipts' gate verdicts
   reported beside the frontier.
