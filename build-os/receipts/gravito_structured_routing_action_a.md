# Receipt — `gravito_structured_routing_action_a`

- **Packet id:** `PACKET-0055-structured-routing-action`
- **Title:** structured routing action — the operator-ordered hardening of the
  deadlock guard's exception BEFORE the real-repository pilot. The operator's
  ruling, verbatim in `routing_contract_live.md`: the whole-JSON substring
  breadth was "a real enforcement bypass, not merely a wording issue."
- **Date closed:** 2026-08-06.
- **Lane:** `substantive`. **Depth 3, announced** — (1) build; (2) qa ‖
  reviewer concurrently; (3) one bounded fix round (`Depth: 3 — reason:
  fix-then-pass (1 enumerated item)`), targeted re-review at that item only.
- **Branch:** `claude/project-handoff-merge-ramhds`.

## 1. Scope

**In:** the operator's five-part hardening: (1) replace the substring-based
routing exception with a STRUCTURED ROUTING ACTION — the ungated pass applies
only to an exactly-recognized routing invocation extracted from the actual
`tool_input.command` field, matched whole against a strict single-invocation
pattern, extraction failure falling TOWARD GATING; (2) fingerprint every
`ROUTING-TOOL-PASS` record in both ledgers; (3) preserve a recovery path that
cannot carry unrelated mutations, proven end-to-end from the refusal's own
text; (4) test the attack shapes AND the legitimate invocation set explicitly;
(5) prove store-unavailable is not a brick. Plus the `routing_contract_live.md`
DEADLOCK GUARD bullet rewritten to the structured action with the NEW honest
bounds named, and every registry anchor into `routing-gate.sh` re-pointed in
the same commit, content-verified (RULING 4 — the twice-burned class).

**Explicitly out:** the real-repository pilot (still the NEXT step);
`bench/`, `build-os/experiments/`, and the metrics store frozen across the
packet's build — the metrics row added by THIS close commit is the adoption
guard's own mandated close bookkeeping, not packet build work; the
`CROSSWALK.md:230` staleness (base-attributed, §5 directive 1) — out of this
packet's scope by deliberate call. `residue.md` frozen (blob
`01517ad2c30d447949a98d0b6db9b8d6b538d5a9`, unchanged at this close). No push
without go.

## 2. Base and commits

- **Base:** `e293e75` — PACKET-0054's close commit, verified
  `git merge-base HEAD e293e75` = `e293e75` at this close, tree quiet at
  `52f429e`.
- `99ee076` — docs(packet): declare PACKET-0055 + the packet's own routing
  receipt via `route-task.sh` (gravito_full, binding), issued BEFORE building.
  2 files, +88/−0. **Green in isolation: 2801/0.**
- `cbca633` — feat(routing): the build — structured routing action,
  fingerprinted passes, store-unavailable fail-open, same-commit registry
  re-pointing. 8 files, +520/−57.
- `52f429e` — the **one permitted fix commit**: the reviewer's single
  enumerated item, doc-only (§4). 2 files, +17/−2.
- **2 build commits + 1 fix commit** — within the contract's budget. This
  close commit is the fourth and final commit, touching only `build-os/`.

### Disjoint file-ownership manifest — SINGLE-WRITER, sequential commits, no fan-out

One builder produced all three commits in sequence and owned all 8 build files
plus the 2 declaration files; the fix commit touched 2 of them; **merger N/A**
(no fan-out; qa and the reviewer held no mutating tools). Attribution stays
recoverable by path via `git show --numstat`:

- `99ee076` — `build-os/packets/active_packet.md` (+30 declaration);
  `build-os/packets/routing/routing-PACKET-0055-structured-routing-action-20260806T015246Z.md`
  (new, +58).
- `cbca633` — `.claude/hooks/routing-gate.sh` (+120/−27);
  `build-os/memory/routing_contract_live.md` (+45/−20);
  `build-os/registry/control_registry.txt` (+24/−6);
  `build-os/registry/neurocosmology_crosswalk.txt` (+8/−1);
  `build-os/registry/CROSSWALK.md` (+1/−1); `build-os/registry/README.md`
  (+1/−1); `tests/routing_structured_action_tests.sh` (new, +320);
  `tests/build_os_tests.sh` (+1/−1, chain).
- `52f429e` — `build-os/memory/routing_contract_live.md` (+16/−1);
  `build-os/registry/control_registry.txt` (+1/−1).
- Per-commit numstat sums: **10 distinct paths, +625/−59**. Net union diff
  `e293e75..52f429e` = 10 files, +623/−57. The two **reconcile exactly**: the
  gap is 2 lines added by the build commits and rewritten within-range by the
  fix commit (625−2=623; 59−2=57).

## 3. What shipped

**The structured routing action.** The mutgate's deadlock-guard exception is
narrowed from a whole-JSON substring match to an EXACT-INVOCATION match over
the extracted `tool_input.command` field: benign JSON escapes only,
whole-command metacharacter reject, strict ERE with an optional
interpreter/path prefix. Extraction failure falls TOWARD GATING, never toward
an ungated pass.

**Fingerprinted passes.** Every `ROUTING-TOOL-PASS` row in both ledgers now
carries which tool, the sha256 first-12-hex of the exact command, and a
≤80-char sanitized TSV-safe excerpt — the PACKET-0054 residual
(pass rows with no command text) closed.

**Recovery proven, store-unavailable proven not a brick.** The recovery path
is proven clean end-to-end from the refusal's own text and cannot carry
unrelated mutations. Store uncreatable → `FAIL-OPEN-STORE-UNAVAILABLE` riding
the stderr fallback; store missing-but-creatable → blocks with working
recovery.

**The seven named bounds, at full size, in repo artifacts.** After the fix
round the contract's "at full size" bounds list carries all SEVEN of the
builder's named bounds — including the three that previously existed in no
repo artifact (argument non-literality under expansion, with the
pre-expansion-literal fingerprint corollary; the privilege-relative store
probe; the sha256 best-effort fallback) — mirrored line-count-neutral in
`routing.universal_task_entry_gate`'s registry notes.

## 4. Verdict chain and QA proof — recorded exactly

- **qa: GREEN.** FULL SUITE **2875 passed / 0 failed, exit 0, solo** (base
  2801/0; the +74 delta is the new `tests/routing_structured_action_tests.sh`
  exactly, chained-vector reconciled). **Commit-1 isolation: worktree at
  `99ee076` → 2801/0.** QA's own **61-assertion probe harness**: 15/15 attack
  shapes blocked with ZERO pass rows; 8/8 legitimate shapes fingerprinted with
  an independently recomputed sha256; the lifecycle walked end-to-end;
  store-unavailable proven on BOTH branches (uncreatable →
  FAIL-OPEN-STORE-UNAVAILABLE on stderr; missing-but-creatable → block with
  working recovery). Overhead: ALLOW 52 ms / BLOCK 34 ms / fingerprinted pass
  59 ms, all within the ≤250 ms bound. **Safety grep clean** — the attack
  strings are stdin fixtures, never executed; the one executed `eval` runs the
  refusal's own recovery command into mktemp scratch, deliberate. Backward
  compat: **6 receipts, 0 violations**. Registry: census **129** controls
  derived, evidence_refs **459** (the BINDING extractor; a naive grep gives
  461 — prose citations excluded by design), **8 anchors content-verified**.
  Safety gates 0 — no push, merge, deploy, or secrets.
- **Reviewer: fix-then-pass, 1 item**, fixed in `52f429e`:
  1. **The contract's "at full size" bounds list carried 4 of the builder's 7
     named bounds.** The missing three (argument non-literality under
     expansion, with the pre-expansion-literal fingerprint corollary; the
     privilege-relative store probe; the sha256 best-effort fallback) existed
     in NO repo artifact. Fixed in the contract and mirrored
     line-count-neutral in `routing.universal_task_entry_gate`'s notes —
     `control_registry.txt` stayed 2474 lines; all 15 anchors byte-compared
     unmoved.
- **Targeted re-review at the one item: pass.** No reviewer exception fired.
- **Verdict: PASS-AS-FIXED.** Depth 3, announced.
- **UI smoke:** n/a — no UI surface.

## 5. Notable gate findings

**Strengths, verified by the reviewer:**

1. **The `$VAR` soundness claim is TRUE at shell-semantics level** — expansion
   output is never re-parsed for operators, so the metacharacter reject holds.
2. **The extraction first-occurrence heuristic is safe against
   model-controlled content** — a planted `"command"` key inside a string
   value is necessarily escaped, so it cannot shadow the real field.
3. **The 8 "unchanged by design" anchors byte-compared identical base-vs-HEAD**
   — the twice-burned anchor-drift defect class did NOT fire this packet.

**Close-time directives from the reviewer — BOTH recorded:**

1. **`CROSSWALK.md:230` ("homeostasis — 24 bound") is stale AT BASE** — the
   base table already said 30, and it is now 31. A NAMED FOLLOW-UP for a
   future packet; out of this packet's scope by deliberate call.
2. **The red-first figure is 30 passed / 44 failed** against the base tree as
   independently measured by the reviewer; the builder's handback said 30/43 —
   off by one. The repo artifacts themselves carry only "twenty-one attack
   shapes," which is accurate; no committed artifact carries the wrong number.

## 6. Second eyes

**Codex second-eyes NOT performed** — 403 at the proxy on both transports,
attempted and stated by the reviewer; recorded honestly, not pretended. The
router's `DC-0001` second-eyes streak numeral moves **34 → 35 in this same
close commit**, derived from the receipt store
(`ls build-os/receipts/gravito_*.md | wc -l`), never restated.

## 7. Live routing receipt closed at this close

`executed_mode: gravito_full` (matches selected; no escalation — `escalation`
stays `-`). `consumed_process_dispatches: 5` — **TRANSCRIPT-DERIVED,
CLOSE-TIME tier, NOT a hook-measured EXACT count**: builder 1 + qa 1 +
reviewer 1 + targeted re-review resume 1 + archivist 1 = 5, within the
allowance of 7. Hooks were NOT loaded this session, so no `live_state/` file
exists for this packet — no STATE row can corroborate or contradict the
figure, and the provenance is recorded on the receipt itself. All other
consumption fields stay `-`: honest admissions, not zeros nobody measured.

## 8. Residue

- **Directive 1 (§5) is the packet's only named follow-up** — the
  `CROSSWALK.md:230` homeostasis count, stale at base, deferred by deliberate
  call to a future packet.
- **The real-repository pilot remains the NEXT step**, explicitly out of this
  packet; staging it is a routing act, and the archivist takes none.
- **Standing note, binding on the next session:** with this receipt
  close-filled, NO routing receipt remains open — the next session's FIRST
  mutation-capable call WILL BE BLOCKED until it routes; mandatory task entry
  by design, recovery is one `build-os/tools/route-task.sh` command (same as
  the PACKET-0054 close note).

## 9. Open boundaries

- **NOTHING PUSHED.** `99ee076`, `cbca633`, `52f429e`, and this close commit
  remain local pending explicit operator go (**4 commits ahead of origin
  after this close**, derived from git). **None may be amended** — the first
  two build commits are the tree the gates measured. No merge, no deploy, no
  secrets touched. `residue.md` stays frozen (blob `01517ad2…`).
