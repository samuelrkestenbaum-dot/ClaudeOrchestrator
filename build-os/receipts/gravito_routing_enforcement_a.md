# Receipt — `gravito_routing_enforcement_a`

- **Packet id:** `PACKET-0050-routing-enforcement`
- **Title:** the operator's post-EXP-0002 routing-and-budget correction —
  selector verdicts made operationally **binding**, routing receipts with
  derived-default budgets, a close-time enforcement gate that refuses silent
  escalation, and the Full-mode value-over-cost recalibration.
- **Date closed:** 2026-08-05.
- **Lane:** `substantive`. **Depth 3, announced** — (1) build; (2) qa ‖ reviewer
  concurrently; (3) one bounded fix round (`Depth: 3 — reason: fix-then-pass
  (2 enumerated items)`), re-review targeted at those items.
- **Branch:** `claude/project-handoff-merge-ramhds`.

## 1. Scope

**In:** (A) binding selector verdicts — `direct` = no workflow machinery;
`light` = repository context + bounded checks, no Full ceremony; `full` = only
within explicit budgets; escalation above the recorded mode requires a new
evidence-bearing escalation decision, silent escalation refused at close.
(B) hard economic circuit breakers for Full with graceful degradation (stop
spawning → collapse to parent → preserve state → continue Light where safe →
report the degradation), never bare termination while a safe productive path
remains. (C) Full-mode recalibration — complexity alone earns `light`; Full
requires value-over-cost evidence. Honest-scoping rule throughout: mechanical
enforcement where a check can execute, protocol text where live counters are
not machine-visible — each labeled as what it is.

**Explicitly out:** EXP-0003 (next packet, after this correction);
memory-control packets (not authorized); `bench/` and both experiment trees
(frozen, published); empathiq-website; `residue.md` (frozen).

## 2. Base and commits

- **Base:** `0239737` — the pushed tip (EXP-0002 published; remote = local,
  0/0), verified quiet at declaration.
- `ac1581c` — docs(packet): declare PACKET-0050-routing-enforcement
  (**docs-only**: `active_packet.md` +32/−0).
- `c49258e` — feat(routing): binding mode selector, routing receipts,
  close-time gate. Carries the **same-commit RULING-4 registration** of the new
  refusal-capable surfaces — census **114 → 118**, **NO contract-gap replay**
  (the third-commit shape PACKET-0045/0048 paid for did not recur). The builder
  **amended `1fb1cc0` → `c49258e` message-only, pre-gate, disclosed** — the
  amend happened before any gate measured the tree, trees byte-identical
  (verified by qa), and it is on the record here, not concealed.
- `4443360` — the **one permitted fix commit**: both reviewer items, exactly as
  prescribed (`routing_contract.md` +5/−1; `control_registry.txt` +2/−2;
  `route-task.sh` +7/−3).
- **2 build commits + 1 fix commit** — within the contract's budget.

### Disjoint file-ownership manifest — SINGLE-WRITER, sequential commits, no fan-out

One writer produced all three commits in sequence; qa and the reviewer held no
mutating tools. Attribution stays recoverable by path via `git show --numstat`:

- `ac1581c` — `build-os/packets/active_packet.md` (+32/−0, append-only
  declaration).
- `c49258e` — `build-os/tools/mode-select.mjs` (new, +150);
  `build-os/tools/route-task.sh` (new, +140); `build-os/tools/routing-check.sh`
  (new, +160); `tests/routing_enforcement_tests.sh` (new, +333);
  `build-os/memory/routing_contract.md` (new, +48);
  `build-os/packets/routing/routing-PACKET-0050-routing-enforcement-20260805T174646Z.md`
  (new, +31); `build-os/registry/control_registry.txt` (+73/−1, RULING-4
  census 114→118); `build-os/registry/neurocosmology_crosswalk.txt` (+28);
  `build-os/registry/CROSSWALK.md` (+4/−4); `build-os/registry/README.md`
  (+1/−1); `CLAUDE.md` (+5, step 7); `tests/build_os_tests.sh` (+1/−1, §26
  chain).
- `4443360` — `build-os/memory/routing_contract.md` (+5/−1);
  `build-os/registry/control_registry.txt` (+2/−2);
  `build-os/tools/route-task.sh` (+7/−3).
- Per-commit numstat sums: **13 distinct paths, +1020/−13**. Net union diff
  `0239737..4443360` = 13 files, +1014/−7. The two **reconcile exactly**: the
  gap is 6 lines added by the build commits and rewritten within-range by the
  fix commit (1020−6=1014; 13−6=7).

## 3. What shipped, and what it closes

**Shipped:**

- `build-os/tools/mode-select.mjs` — the selector: 7 operator value factors;
  **complexity alone earns `light`** (the T3 recalibration); refuses partial
  descriptors at exit 2 (mechanical).
- `build-os/tools/route-task.sh` — routing receipts, one file per decision
  under `build-os/packets/routing/`, with **DERIVED-DEFAULT budgets from the
  sealed EXP-0002 bands** (operator-tunable, not laws; named exceedance
  recorded — raw T4's **526,461** is cited as a named exceedance of the light
  band, per the fix round).
- `build-os/tools/routing-check.sh` — the close-time gate: refuses
  SILENT-ESCALATION, EVIDENCE-FREE escalation, BUDGET-BREACH without a
  degradation note, FULL-NO-BUDGETS, MALFORMED. **`-` is admission; refusal is
  for contradiction.** The live sweep is chained into `build_os_tests.sh` §26
  so it fires on every suite run.
- `build-os/memory/routing_contract.md` — the binding-verdict rule and the
  five-step circuit breaker as labeled PROTOCOL, with **THREE named honest
  bounds**: (1) live counters are not bash-visible; (2) falsely recorded
  consumption is uncaught; (3) **receipt ISSUANCE itself is unchecked — a
  packet that never routes is invisible to the gate** (the third bound, named
  by the fix round).
- `CLAUDE.md` step 7 (5 lines) — substantive packets issue a routing receipt
  before building.
- `tests/routing_enforcement_tests.sh` — **104/0, red-driven**.

**What it closes, proven by execution at the gates:**

- **DEFECT 1 — T5 silent escalation:** the reviewer rebuilt T5's receipt from
  its sealed descriptor and `routing-check.sh` **REFUSED it with 5 named
  violations** — an exact replay of the executed defect, now mechanically
  refused with SILENT-ESCALATION named.
- **DEFECT 2 — T3 calibration:** T3's sealed complexity-only descriptor now
  routes `gravito_light` under the product selector (with the informative
  withheld-Full note citing T3's 3.9×), while the **frozen experiment selector
  still returns `gravito_full`** — proving both the recalibration and the
  non-mutation of the frozen copy.

## 4. Verdict chain and QA proof — recorded exactly

- **qa: GREEN.** FULL SUITE **2482 passed / 0 failed, solo** — **+104**, all of
  it the new routing suite, per-suite deltas verified from logs. **Commit-1
  isolation 2378/0** at the docs-only declaration `ac1581c`. The enforcement
  gate driven in **both directions** on hand-built fixtures, including the
  exact T5 replay refused with SILENT-ESCALATION named; selector recalibration
  driven; **census 118 reconciled**; frozen surfaces intact; mirrors
  byte-identical; the `1fb1cc0` → `c49258e` message-only amend **verified
  transparent** (trees byte-identical). Safety gates 0 — no push, merge,
  deploy, or secrets.
- **Reviewer: fix-then-pass, 2 items**, both fixed in `4443360` **exactly as
  prescribed**: (1) the receipt-absence gap now **NAMED** in
  `routing_contract.md` as the third honest bound; (2) the light-band
  derivation citation corrected, with raw T4's **526,461** recorded as a named
  exceedance; evidence anchors re-pointed and **verified landing**. **qa had
  independently flagged the same citation.**
- **Depth 3 announced**; targeted re-review confirmed both items landed; no
  reviewer exception fired.
- **Verdict: PASS-AS-FIXED.**
- **UI smoke:** n/a — no UI surface.
- **Live routing receipt closed at this close:** `executed_mode: gravito_full`
  (matches selected; no escalation, `escalation` stays `-`); consumption fields
  stay `-` with the doctrinal reason on the receipt (serial agent passes and
  live token/cost counters are transcript-only — nothing in git attests to
  them; `-` is the admission the gate accepts). Post-fill sweep:
  `routing-check.sh check` — **1 receipt checked, 0 violations, exit 0**.

## 5. Second eyes

**NONE** — Codex attempted and stated by both gates: `api.openai.com:443`
returns 403 CONNECT policy-denied at the proxy. The router's `DC-0001`
second-eyes streak numeral moves **29 → 30 in this same close commit**, derived
from the receipt store (`ls build-os/receipts/gravito_*.md | wc -l`), never
restated.

## 6. Residue

- **OPEN CALIBRATION QUESTION, surfaced by this packet's own close and
  recorded, not resolved:** a full-mode packet's own gate chain
  (builder + qa + reviewer + archivist) **brushes the `max_subagents: 3`
  default** — whether process agents count against task budgets is an
  **EXP-0003-adjacent operator question**.
- The contract's three honest bounds stay open by design: live counters not
  bash-visible; false-recorded consumption uncaught; receipt issuance itself
  unchecked (a packet that never routes is invisible to the gate).
- Staged next, **NOT declared** (a routing act, not the archivist's):
  **EXP-0003** — three NEUTRAL preregistered conditions (direct /
  gravito_light / gravito_full-with-enforced-budgets) on T3/T4/T5-style tasks;
  output = the routing frontier; the conclusion rule must **NOT** be
  direction-asymmetric this time (the operator's explicit instruction).

## 7. Open boundaries

- **NOTHING PUSHED.** `ac1581c`, `c49258e`, `4443360`, and this close commit
  all remain local pending explicit operator go. **None may be amended.** No
  merge, no deploy, no secrets touched.
