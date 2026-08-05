# Receipt — `gravito_exp0001_analysis_reveal_a`

- **Packet id:** `PACKET-0047-exp0001-analysis-reveal`
- **Title:** EXP-0001b — the **analysis half** of the operator's 2026-08-05
  controlled experiment: blinded independent evaluation, mapping reveal, and
  preregistered conclusion. Outputs 3–5 of the five the operator mandated.
- **Date closed:** 2026-08-05.
- **Lane:** `substantive`. **Depth: 2** — build stage (blinded analysis
  committed, then reveal), then qa ‖ reviewer CONCURRENTLY. Archivist close
  after the verdict (bookkeeping, not a gate).
- **Branch:** `claude/project-handoff-merge-ramhds`.

## 1. Scope

**In:** the blinded evaluator's report committed **VERBATIM** as
`analysis/BLINDED_ANALYSIS.md` BEFORE the mapping entered the tree; the reveal
(`analysis/blind_mapping.txt`, which must hash to the sha256 pre-committed at
seal time); `REVEALED_COMPARISON.md`; `CONCLUSION.md` drawing exactly one of
the four preregistered labels with direction and scope.

**Explicitly out:** any Gravito optimization or response to the result —
acting on the finding is the operator's decision, not this packet's; any edit
to `bench/`, sealed `runs/`, `blinded_dataset.tsv`, `PREREGISTRATION.md`, or
any frozen surface; `residue.md` (frozen). The record repair `d0a2231` is
**outside** this packet (section 5).

## 2. Base and commits

- **Base:** `92c7276` — PACKET-0046's close commit, tree quiet at declaration.
- `7d56cbc` — docs(experiment): EXP-0001 blinded analysis committed verbatim,
  before reveal; declare PACKET-0047. **The mapping was ABSENT from the tree
  at this commit — proven by `ls-tree`; ancestry is the blinding proof.**
- `698e3c3` — data(experiment): EXP-0001 reveal — mapping verified against the
  pre-committed hash; conclusion.
- **2 build commits, NO fix commit belongs to this packet.** The adjacent
  tiny-lane commit `d0a2231` repairs PACKET-0046's close record, not this
  packet (section 5).

### Disjoint file-ownership manifest — SINGLE-WRITER, sequential commits, no fan-out

One writer produced both build commits in sequence; qa and the reviewer held
no mutating tools, so disjointness holds trivially and is recorded anyway —
attribution stays recoverable by path via `git show --numstat`:

- `7d56cbc` —
  `build-os/experiments/EXP-0001-token-efficiency/analysis/BLINDED_ANALYSIS.md`
  (new, +88); `build-os/packets/active_packet.md` (append-only declaration,
  +21).
- `698e3c3` —
  `build-os/experiments/EXP-0001-token-efficiency/analysis/blind_mapping.txt`
  (new, +3);
  `build-os/experiments/EXP-0001-token-efficiency/REVEALED_COMPARISON.md`
  (new, +64);
  `build-os/experiments/EXP-0001-token-efficiency/CONCLUSION.md` (new, +47).
- No path appears in both diffs; per-commit numstat sums (2 files +109, 3
  files +114) reconcile exactly with the net union diff `92c7276..698e3c3`
  (5 files, +223, −0).

## 3. THE RESULT

The blinded independent evaluator (fresh context, X/Y dataset + the §5 rule
only, **no repo access**) returned **"causal effect supported, condition Y
lower"** — **50.8% median total-token reduction**, ranges **fully disjoint**
(Y max 227,089 < X min 311,164), uncached comparison agreeing at 40.3%, 5/5
acceptance in both arms, **no confound clause fired**.

The mapping — **raw=Y / buildos=X** — entered the tree one commit AFTER the
analysis and hashes **byte-exact** to the sha256 pre-committed at seal time
(`0a4b66a142ced55bde866cd16283540643f68a2dfd6f3a231ba188b3b9fd08ec`) —
**verified independently by qa AND reviewer.**

**Translated: on the T1 task class in this headless environment, Gravito OFF
used 50.8% FEWER tokens (OFF median 153,611 vs ON 312,444). The supported
causal effect is Gravito INCREASING tokens on T1 — the direction OPPOSITE the
hypothesis** — drawn from the preregistered symmetric rule and the four-option
vocabulary.

**Scope, bounded:** T1-class only; N=5 pairs; one repo; one model config.
T2–T4 contributed no numeric data (deterministic refusals, retained in the
dataset). The weekly usage drop stays **prior evidence**. The product's
substantive-work claim is **untested, not contradicted**.

With this close **EXP-0001 is COMPLETE**: all five operator-mandated outputs
exist in ancestry order — preregistration `b3a3b7f` → sealed records
`d2373e6` → blinded analysis `7d56cbc` → reveal + conclusion `698e3c3`. The
experiment stays frozen; acting on the finding is the operator's decision.

## 4. QA proof (RED → attributed → GREEN)

- **Initial run: RED — 2375 passed / 3 failed.** qa attributed all three
  failures **exactly**: each pre-existed at this packet's BASE `92c7276` —
  PACKET-0046's close commit wrote a metrics row whose `rounds '-'` carried no
  admission and a receipt without a file-ownership manifest, both **AFTER**
  PACKET-0046's gates measured `d2373e6`. **This packet's own two commits
  never touched those surfaces — qa proved empty diffs.**
- **Repair (outside this packet):** tiny-lane record fix `d0a2231` — note
  admission + receipt later-record manifest addendum on the PACKET-0046
  record; numbers untouched (section 5).
- **After the repair, at `d0a2231`:** `check-adoption.sh` exit 0; both
  affected suites **70/0**; **FULL SUITE 2378 passed / 0 failed, exit 0, solo**.
- **qa items 3–9: all passed with exact-match evidence** (mapping hash
  byte-exact, ls-tree blinding proof, frozen-surface empty diffs, verbatim
  check, safety grep clean — no push, merge, deploy, secret, amend, or rebase).
- **UI smoke:** n/a — this packet has no UI surface.

## 5. The adjacent record repair `d0a2231` — recorded as what it is

A **tiny-lane bounded correction to PACKET-0046's close record**, discovered
by this packet's qa, 2 rounds, **not this packet's fix commit, not a doctrine
breach**. The defect class is **"close bookkeeping written after the gates"**
and is named so the next archivist checks `check-adoption.sh` **BEFORE**
committing a close — this close ran it before (exit 0 at `d0a2231`) and after
writing its row and receipt (exit 0).

## 6. Reviewer verdict

**PASS — ZERO fix items.** **Second eyes: NONE — single-model review, stated
plainly.** Codex binary present; `api.openai.com:443` returns 403 CONNECT
policy-denied at the proxy — **both gates reproduced it live**. The router's
`DC-0001` second-eyes streak numeral moves **26 → 27 in this same close
commit**, derived from the receipt store
(`ls build-os/receipts/gravito_*.md | wc -l`), never restated.

Reviewer confirmed the "T1 is the task this system loses on" citation at
`COMPARISON_PROTOCOL.md:123` is **true**, and that **no result-driven
mutation occurred** — frozen surfaces byte-untouched despite the unflattering
result.

**Two non-blocking notes for FUTURE preregistrations** (advisories, not
defects here):

1. Pin the median-difference **denominator formula** in the preregistration.
2. Put orchestrator **provenance in a sibling file**, not inside a "verbatim"
   document.

## 7. Residue

- Reviewer's two preregistration advisories (section 6) carry forward to any
  future experiment protocol.
- Defect class "close bookkeeping written after the gates" (section 5) —
  standing instruction: run `check-adoption.sh` before committing a close.
- EXP-0001 is complete and frozen. Whether and how to act on the finding is
  the operator's decision; no follow-up packet is staged by this close.

## 8. Open boundaries

- **NOTHING PUSHED.** `b3a3b7f`, `d2373e6`, `92c7276`, `7d56cbc`, `698e3c3`,
  `d0a2231`, and this close commit all remain local pending explicit operator
  go. **None may be amended.**
- No merge, no deploy, no secrets touched.
