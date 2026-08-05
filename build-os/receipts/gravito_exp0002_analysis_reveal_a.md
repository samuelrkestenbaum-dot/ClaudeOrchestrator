# Receipt — `gravito_exp0002_analysis_reveal_a`

- **Packet id:** `PACKET-0049-exp0002-analysis-reveal`
- **Title:** EXP-0002b — the **analysis half** of the sustained-workload
  experiment: blinded evaluation committed verbatim, mapping reveal against the
  pre-committed hash, registered conclusion. Outputs 3–5 of the five.
- **Date closed:** 2026-08-05.
- **Lane:** `substantive`. **Total depth: 5 serial stages** — (1) build;
  (2) qa ‖ reviewer concurrently; (3) fix round; (4) **`Depth: 4 —
  mandatory_full_regate`, ANNOUNCED AND RUN** (full concurrent qa ‖ reviewer on
  the fix commit — the fixes altered the load-bearing conclusion, so targeted
  confirmation was forbidden; NOT a defect); (5) bounded second fix + targeted
  confirmation under the contract's **executed-reason exception** (section 5).
- **Branch:** `claude/project-handoff-merge-ramhds`.

## 1. Scope

**In:** the blinded evaluator's report committed **VERBATIM** as
`analysis/BLINDED_ANALYSIS.md` (with sibling provenance note) BEFORE the
mapping entered the tree; the packet declaration; the reveal
(`analysis/blind_mapping.txt`, hash-verified against the seal);
`REVEALED_COMPARISON.md` (discharging PACKET-0048's three routed obligations);
`CONCLUSION.md` with exactly one preregistered label and the two
operator-mandated reconciliations; the evaluator's neutral rule text
(`analysis/EVALUATOR_RULE_TEXT.md`, committed for audit by the fix round).

**Explicitly out:** any Gravito optimization or response to the result — the
router is recorded as the next **CANDIDATE**, not built; any edit to `bench/`,
sealed `runs/`, `blinded_dataset.tsv`, `PREREGISTRATION.md`, EXP-0001, or any
frozen surface; `residue.md` (frozen).

## 2. Base and commits

- **Base:** `5c04755` — PACKET-0048's close commit, tree quiet at declaration.
- `23983ba` — docs(experiment): EXP-0002 blinded analysis committed verbatim,
  before reveal; declare PACKET-0049. **Ancestry is the blinding proof.**
- `46809e6` — data(experiment): EXP-0002 reveal — mapping (`raw=X`,
  `buildos=Y`) hash-verified **byte-exact** against `916e1ae`'s pre-commitment
  `45734767…`; revealed comparison; conclusion.
- `ca65b98` — fix commit 1: all 4 first-round items, **one installment**.
- `ce7588c` — fix commit 2: the two-line flipped-percentage correction, under
  the **executed-reason exception** (section 5).
- **2 build commits + 2 fix commits** — the second fix commit is NOT a re-cut:
  the contract permits it where an executed reason proves the fixes could not
  safely be combined, and here the second defect **was created by the first fix
  commit** and could not have been enumerated before it existed.

### Disjoint file-ownership manifest — SINGLE-WRITER, sequential commits, no fan-out

One writer produced all four commits in sequence; qa and the reviewer held no
mutating tools. Attribution stays recoverable by path via `git show --numstat`:

- `23983ba` —
  `build-os/experiments/EXP-0002-sustained-workload/analysis/BLINDED_ANALYSIS.md`
  (new, +123);
  `.../analysis/BLINDED_ANALYSIS_PROVENANCE.md` (new, +11);
  `build-os/packets/active_packet.md` (append-only declaration, +18).
- `46809e6` — `.../CONCLUSION.md` (new, +63); `.../REVEALED_COMPARISON.md`
  (new, +74); `.../analysis/blind_mapping.txt` (new, +3).
- `ca65b98` — `.../CONCLUSION.md` (+31/−15); `.../REVEALED_COMPARISON.md`
  (+26/−15); `.../analysis/EVALUATOR_RULE_TEXT.md` (new, +23).
- `ce7588c` — `.../CONCLUSION.md` (+3/−2); `.../REVEALED_COMPARISON.md`
  (+3/−2).
- Per-commit numstat sums: **7 distinct paths, +378/−34**. Net union diff
  `5c04755..ce7588c` = 7 files, +344/−0. The two **reconcile exactly**: the
  34-line gap is lines added by the build commits and rewritten within-range
  by the two fix commits (378 − 34 = 344).

## 3. THE REGISTERED RESULT

**`no sustained-workload savings detected`** — Gravito **OFF used 74.8% fewer
total tokens per durable accepted outcome than ON** (ON at **3.96×**, +296%;
2,631,154 vs 663,924; uncached comparison agreeing at 78.8%; **10/10
acceptance in both arms**; ON cumulatively cheaper only through T2; the
crossover against it at T3 on totals, already at T2 on uncached tokens and
cost).

**Label provenance, on the record:** the blinded evaluator's symmetric wording
("promising but underpowered, direction X") is preserved **verbatim** as
evidence; the TRANSLATION stage applies the registered directional rule —
`PREREGISTRATION.md` §6 pre-assigned the B-worse case to rule 3. The
mistranslation was caught **independently by BOTH gates** and corrected on the
record, with the evaluator's exact neutral rule text committed for audit
(`analysis/EVALUATOR_RULE_TEXT.md`).

**The substantive finding (with its corrected precision):** the overhead is
**protocol-invocation-dependent, not fixed** — ON was CHEAPER on T1 (−31.5%)
and T4 (−56.5%) where the surface stayed light, and 3.9×/7.8× more expensive
on T3/T5 where the full ceremony fired. A router enforcing the selector's
recorded verdicts would have prevented **ONLY T5's blowout** — T3's verdict
was `gravito_full`, so T3 is selector-calibration / full-mode-cost evidence.
**Router recorded as next CANDIDATE, not built.**

**Both operator-mandated reconciliations carried:** EXP-0001 (the overhead is
the ceremony's, not a fixed tax; "routing, not removal"); the weekly-usage
drop (still not directly explained; meter unobservable; remains prior
evidence).

With this close **EXP-0002 is COMPLETE**: all five outputs in ancestry order —
preregistration `9cf0f87` → sealed records `916e1ae` → blinded analysis
`23983ba` → reveal `46809e6` → registered conclusion `ca65b98`/`ce7588c`.

## 4. Verdict chain and QA proof — recorded exactly

- **First gates, on `46809e6`:** reviewer **fix-then-pass, 4 items**
  (registered-rule label re-route; router claim narrowed to T5-only; T2
  crossover clause; commit the evaluator's neutral rule text) + **qa RED on
  the same label-rule defect** — the two gates converged on it independently.
- **Fix commit `ca65b98`:** all 4 items, one installment. Because the fixes
  altered the **load-bearing conclusion**, `Depth: 4 — mandatory_full_regate`
  was **announced and run**.
- **Full concurrent re-gate on `ca65b98`:** **qa GREEN — FULL SUITE 2378
  passed / 0 failed, solo; Commit-1 isolation 2378/0**; label mechanically
  re-derived from §6-with-mapping; ordering chain and mapping hash
  **byte-exact**; frozen surfaces intact; **all gates 0** (safety grep clean —
  no push, merge, deploy, secret, amend, or rebase). Reviewer:
  **fix-then-pass on ONE item its own fix round introduced** — the flipped
  percentage ("ON 74.8% MORE" understates 3.96×).
- **Second fix commit `ce7588c`** (section 5): two lines, the reviewer's exact
  prescribed form; **qa had independently flagged the same wording** as its
  one non-blocking note — both gates agree on the correction. **Targeted
  confirmation:** 0 remaining occurrences of the flipped form;
  `control_registry_tests` **180/0**; tree clean.
- **Verdict: PASS-AS-FIXED.**
- **UI smoke:** n/a — no UI surface.

## 5. The second fix commit — the executed reason, in full

The contract: "More than one fix commit is a **re-cut**, unless an executed
reason proves the fixes cannot safely be combined." Executed here: the flipped
percentage **did not exist until `ca65b98` wrote it** — it is a defect the
first fix round introduced, so it could not have been enumerated in the first
round's complete, one-installment list, and no combined commit could have
carried both. The correction is bounded (2 files, +6/−4 across two lines),
follows the reviewer's prescribed form, and was confirmed by targeted check
per the reviewer's own re-review rule — the named full-regate exception did
not fire a second time because the corrected sentence changes wording
precision, not the registered label, direction, or any count.

## 6. Second eyes

**NONE across all four gate passes** — Codex attempted each time and stated:
`api.openai.com:443` returns 403 CONNECT policy-denied at the proxy. The
router's `DC-0001` second-eyes streak numeral moves **28 → 29 in this same
close commit**, derived from the receipt store
(`ls build-os/receipts/gravito_*.md | wc -l`), never restated.

## 7. Residue

- **Router = next CANDIDATE** (not built, not staged): enforce the selector's
  light verdicts (prevents the T5 class); treat T3 as open selector-calibration
  / full-mode-cost evidence, not an enforcement case.
- The weekly-usage drop stays unexplained pending operator-side meter capture
  or a workload shaped like the real one.
- Defect class registered by this packet: **translation-stage label flip** — a
  symmetric blinded verdict must be re-derived through the registered
  directional rule mechanically, and the neutral rule text belongs in the tree.
- Second defect class: **a fix round can mint its own defect** — re-gates read
  the fix diff itself, not only the fix list.
- EXP-0002 is complete and frozen. Acting on the findings is the operator's
  decision.

## 8. Open boundaries

- **NOTHING PUSHED.** `23983ba`, `46809e6`, `ca65b98`, `ce7588c`, and this
  close commit all remain local pending explicit operator go. **None may be
  amended.** No merge, no deploy, no secrets touched.
