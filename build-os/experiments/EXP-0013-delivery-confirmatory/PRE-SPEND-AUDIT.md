# EXP-0013 — ADVERSARIAL PRE-SPEND AUDIT (owner-authorized, local-only)

Independent skeptical review of the prior READY_FOR_SPEND_AUTHORIZATION
claim, reconstructed from committed files and EXECUTED call paths, not the
prior narrative. The audit REFUTED the prior verdict: it found one
launch-fatal design defect, one direction-dependent bias in the frozen
analysis, several unwired contracts presented as ready, freeze blind spots,
and one self-caused unauthorized provider call. All corrections ship as the
disclosed AMENDMENT v3 (AMENDMENT-V3.md) under FREEZE-MANIFEST-v3.json
(digest `2569ca3c4074b8ba0aaf24fb0b1f3a0db99770075fe7adfb1f0ea34fb4fb093a`).
v1 verifies untouched; the v2 manifest is preserved byte-identically as
history inside v3.

## INCIDENT DISCLOSURE (before anything else)

While probing CLI drift surfaces, the auditor ran `claude config get`.
CLI 2.1.229 has no such subcommand: the argv was consumed as a PROMPT and
executed ONE real, unauthorized model call (cost unknown-but-small; charged
to the operator account, outside any experiment ledger). This violated the
audit's own no-inference boundary. It is also executed proof of a real
hazard: ANY stray exec of the CLI is a paid call. Encoded into v3: the
controller has exactly one CLI exec site, a probe that can only ever pass
`["--version"]` (red-team-tested), and rehearsal transport has no exec
capability at all.

## CLAIM-EVIDENCE TABLE

| # | Claim (v2) | Artifact / executable proof | Scale | Uncertainty | Failure consequence | Verdict |
|---|---|---|---|---|---|---|
| 1 | Chain = 607c0bd + 4 commits to 29ae7b7, tree clean, no gitlinks | git log/status/ls-tree executed | repo | none | — | CONFIRMED |
| 2 | Freeze v1+v2 verify | both ran green pre-amendment | freeze | none | — | CONFIRMED |
| 3 | Freeze detects post-freeze change | probes: 1-byte flip DETECTED; **ADDED file NOT detected; PERMISSION change NOT detected; rename = crash not typed refusal** | freeze | none | rogue module or mode change invisible | **CONTRADICTED → fixed (freeze3: inventory + modes + typed MISSING_FILE; red-team-tested)** |
| 4 | All execution deps frozen | inventory: bin/gravito, reachability.mjs, h0-check.sh, goal template were UNFROZEN yet controller-invoked | freeze | none | silent behavior drift under intact freeze | **CONTRADICTED → fixed (frozen in v3)** |
| 5 | "Losing the mapping could make the study unanalyzable" | rehearsal-evidence/results/*: cell dirs and receipts CARRY arm identity; views are built later from cells | study | none | overstated risk | **CONTRADICTED (risk was precommitment-PROOF loss, not analyzability) → escrow built anyway** |
| 6 | Mapping durable | it lived only in this container | study | none | precommitment proof dies with container | **CONTRADICTED → mapping-escrow.mjs (scrypt+AES-256-GCM); ciphertext committable; wrong-key/tamper typed (tested); custody = OWNER, prerequisite in template B** |
| 7 | Max 16 calls follows from frozen rules | enumeration proven EXECUTABLE: happy=10; seed-double-fail=2 then SEQUENCE_VOID; pair-rerun=+2 each; 3rd rerun demand REFUSED pre-spend; call 17 REFUSED by hard counter | study | none | — | CONFIRMED **but was contract-only in v2 → now enforced in code (MAX_CALLS=16 + ledger)** |
| 8 | Budget gate protects the ceiling | v2 gate was a pure function with NO durable spent input — restart reset spend | study | none | ceiling breach after crash | **CONTRADICTED → spend-ledger.mjs: reserve-at-bound-before-call, settle-after, unknown-cost-never-zero, torn/malformed/broken-chain typed refusals, restart re-reads (all red-team-tested)** |
| 9 | $19 planned / $96 worst / $100 ceiling | EXP-0011 telemetry n=40: p50 $1.83, p90 $3.49, p95 $3.78, max $4.28; **2 aborted `attempt1` cells at $0/0-token found — in-study retries existed in the precedent**; bound $6 ≈ 1.4x max at the same 1200s ceiling | program | model comparability exact (same model/task shape) | — | CONFIRMED (ceiling $100 = smallest round ceiling ≥ 16x$6=$96; failure calls hold the $6 bound when unmetered) |
| 10 | Corpus is viable | **STRUCTURALLY VOID: both v2 seeds shared ZERO error codes with their measured positions → every pair would refuse INVALID_UNINTENDED_EMPTY_TREATMENT at spend time** (found by EXECUTING the measured machine with fake transports) | experiment | none | Stage A voids at first delivery; seeds' spend wasted | **CONTRADICTED → corpus amendment v3: seed-coverage eligibility rule, derived from frozen baseline only (no outcomes exist); S1 all-TS18047, S2 TS2339/TS2345(+TS7053); coverage PROVEN in corpus artifact; cross-sequence code overlap now EMPTY** |
| 11 | Sequences disjoint | file overlap 0; import neighborhoods: S1 shares db/drizzle-schema with S2's persistence-domain (recorded); after amendment, cross-sequence CODE overlap ∅; per-sequence stores/namespaces (isolation suite) prevent cross-learning | experiment | shared drizzle idioms remain a similarity, not a channel | — | CONFIRMED with disclosed resemblance |
| 12 | emotional-geometry exclusion pre-content | corpus artifact self-attestation; cannot be independently re-proven post hoc | procedural | inherent | — | NOT OBSERVABLE (attested; decision used subsystem identity only) |
| 13 | Seeds neutral, renderer-independent | distillation was UNIMPLEMENTED in v2 ("distilled at spend time" had no code) | experiment | none | live run had no path from p1 to a store | **CONTRADICTED → distill.mjs: deterministic, mechanical, UCDL-parseable, typed refusals for rejected/empty/corrupt/partial seeds; frozen policy 1 rerun then SEQUENCE_VOID (tested); same store digest-pinned for p2 AND p3, both arms** |
| 14 | claude-opus-5 accepted by CLI 2.1.229 | `--help` documents alias-or-full-name; EXP-0011 ran this exact flag+model on this CLI lineage; acceptance not verifiable without a paid call (not attempted) | config | rolling alias: dated id knowable only from call 1 | wrong model silently | PARTIAL → covered by preregistered id-pattern set + gate at first telemetry (abort before next call; call 1 counted) — now EXECUTABLE, tested incl. the timeout-first-call edge (gate stays armed until an id exists) |
| 15 | Zero-call rehearsal barrier | v2 barrier was a code-path convention + PATH shim; **the audit's own incident proves PATH/argv discipline is insufficient** | study | none | accidental spend | **PARTIAL → v3 transport injection: rehearsal transport module imports NO child_process/net (grep-tested structural wall); shim retained as tripwire; 61-step rehearsal green, shim untripped** |
| 16 | Role separation | separate views + regex check; **PROCEDURAL, not structural** (one OS identity); v1 regex missed SKILL.md/.claude/skills/task-log.md in diffs, byte-size channels, session ids | study | residual: same-user filesystem | adjudicator unblinding | PARTIAL → leakcheck2.mjs hardened (tested); classification stated honestly |
| 17 | Analysis frozen & correct | independent 2nd implementation agrees to 1e-9 on primary/SD; **but relabel-invariance test found median_pct = \|exp(median)-1\| is direction-DEPENDENT (0.75x→25% vs 1.333x→33%)** | analysis | none | ladder easier to cross in one direction | **CONTRADICTED → fixed to exp(\|median\|)-1; relabel invariance now exact (tested)** |
| 18 | Stopping rules sound | reruns only from typed infra reasons (outcome can't trigger them — code path takes terminal_reason/metered only); rerun order was "fresh draw" = NOT precommitted | study | none | order manipulation channel at rerun | **PARTIAL → rerun orders pre-drawn and SEALED NOW under RERUN-ORDER-COMMITMENT (94cb25b3…); per-pair fair coin; tested incl. tamper** |
| 19 | EXP-0011 never pooled; 4 pairs never proof | analysis.mjs has no import path to any EXP-0011 data (grep); every output carries treatment_effectiveness=UNPROVEN (tested) | analysis | none | — | CONFIRMED (structural, not just forbidden) |
| 20 | Stage A cannot expand | no code path launches beyond MAX_CALLS=16; expansion strings route to owner | study | none | — | CONFIRMED (now enforced by counter) |

## Reproducibility inventory

Committed+frozen (v3, 40 artifacts + dir inventories + mode bits): all
harness modules, corpus (incl. baseline compile), commitments, prereg/design
docs, both prior manifests, bin/gravito, planner/reachability/h0-check,
goal template, ucdl, all three EXP-0013 suites. Externally pinned:
empathiq-website source (commit 2543c873…; archives only). Locally sealed
(outside repo, escrow-able): primary orders + salts, rerun orders + salt,
blinding salt. Ephemeral-only (declared, versions recorded): node v22.22.2,
typescript 5.9.3 via empathiq node_modules symlink, claude CLI 2.1.229
(equality preflight), /home/user/.exp0013-sealed. No undeclared scratch
state is load-bearing: the rehearsal runs from committed files + sealed
store alone.

## Call-count proof (executed, not narrated)

States: seed(seq) → [success → distill → pinned store | fail → 1 rerun |
2nd fail → SEQUENCE_VOID(abort)]; pair(seq,pos) → both arms in sealed order
→ [all metered+terminal-success → done | any infra-invalid → whole-pair
rerun from PRE-SEALED contingency order, max 1/pair, max 2/study, refused
BEFORE spend when exhausted]; every call: ledger-integrity → CALL_CEILING
(16) → BUDGET_CEILING (projection ≤ $100) → reserve($6) → transport →
settle. Model-id gate arms until first telemetry-bearing call; mismatch
aborts before any further call with call 1 charged. Restart: ledger re-read;
reservations survive; nothing resets. Proven totals: 10 planned; 12 with
one pair rerun; ≤14 at rerun exhaustion; 16 absolute (counter-enforced);
17th refused.

## Spend

Distribution (EXP-0011, provider-native, n=40 incl. two $0 aborted
attempts): p50 $1.83 / p90 $3.49 / p95 $3.78 / max $4.28. Ideal expected
10x$1.87≈$19. Conservative likely (p90) ≈ $35. Maximum-observed x allowed
calls = 16x$4.28 = $68.51. Justified smallest safe ceiling: per-call bound
$6 (max observed +40%, same 1200s ceiling) x 16 = $96 → **$100** (smallest
round ceiling covering the proven worst case). Gate attacks all pass:
$99.9 projection allowed, $100.1 refused pre-launch, torn/malformed/
concurrent/restart/unknown-cost cases typed and refused.

## Publication order (recommended)

1. This audit's two amendment commits (done, local).
2. Owner reviews AMENDMENT-V3.md + this file.
3. **Template A push** (fast-forward, one push, publish gate + recorded
   authorization), then independent remote verify, then `freeze3.mjs verify`
   against the pushed tip (manifests reference commits by recording the
   freeze-time commit; history is never rewritten — supersession is a new
   manifest, never a refreshed hash).
4. **Mapping escrow handoff**: owner supplies a passphrase (≥12 chars) out
   of band; escrow ciphertext committed; owner confirms custody. (Without
   this, container loss costs precommitment PROOF — analyzability survives
   regardless, per claim 5.)
5. **Template B spend authorization** naming the v3 digest.
6. Immediate pre-call checks: freeze3 verify, sealed+rerun commitments
   verify, CLI --version equality, H0 gate, ledger empty, study lock free.

## Suites (all green, freeze intact after)

fixture 22/22 · readiness 33/33 · **red-team 27/27 (new)** · planner 25/25 ·
control_primitives 47/47 · neurocosmology_invariant 21/21 ·
context_delivery 12/12 · goal_enforcement 34/34 · lifecycle 35/35 ·
doc_drift 10/10 · cross_repo_isolation 14/14 · authority_envelope 126/0.
EXP-0004/5/9/10/11 byte-identical; v1 verifies; v2 bytes preserved in v3.

## VERDICT

**READY_FOR_PUBLICATION_THEN_SPEND_AUTHORIZATION** — with the mapping
escrow handoff as a named prerequisite inside template B. The prior
READY verdict was premature in five material respects (corpus void, budget
non-durability, unimplemented distillation, analysis direction bias, freeze
blind spots); all are now closed with executed evidence under the disclosed
v3 amendment.

### Template A — publication (exact wording for the owner)

> Explicit owner authorization: push exactly the audited local commit range
> 607c0bd..<TIP> (<N> commits, new tip <TIP>) to origin
> claude/project-handoff-merge-ramhds, fast-forward only, exactly one push;
> record the scoped authorization in the publish-check schema; verify the
> expected old remote tip 607c0bd before pushing, then independently fetch
> and verify the remote tip equals <TIP> with zero divergence, and verify
> FREEZE-MANIFEST-v3 against the pushed tip.

(<TIP>/<N> to be read from the local chain at authorization time; the
audit's amendment commits extend the previously audited 4.)

### Template B — measured Stage A (exact wording for the owner)

> Explicit owner spend authorization for EXP-0013 Stage A: PREREQUISITE —
> mapping escrow completed (owner-held passphrase, ciphertext committed,
> custody confirmed); then run the measured study exactly as frozen under
> FREEZE-MANIFEST-v3.json (digest 2569ca3c4074b8ba0aaf24fb0b1f3a0db99770
> 075fe7adfb1f0ea34fb4fb093a), primary arm-order commitment 3f3725a5…e2e1df9
> and rerun-order commitment 94cb25b3…: model claude-opus-5 (allowed
> provider ids claude-opus-5 / claude-opus-5-YYYYMMDD; the id gate aborts
> after the first telemetry-bearing call and before any further call on
> mismatch, call 1 charged), 10 planned calls (2 neutral seeds + 8 measured),
> hard maximum 16 calls enforced by the ledger counter, SERIAL topology,
> 1200s per-cell ceiling, hard $100 ceiling via reserve-at-$6-before-call
> accounting where unknown cost is never zero. Stop immediately on:
> unintended-empty delivery (stage void), second seed failure in a sequence
> (sequence void), second infrastructure-invalid cell, rerun-budget
> exhaustion, model-id mismatch, ledger integrity failure, freeze or
> commitment verification failure, or ceiling projection breach. No interim
> outcome reads; analysis via the frozen analysis.mjs only after all
> admissible cells finish; reveal is a separate one-way step. Covers no
> push, no PR, no merge, no deploy, no production change, no Stage B.
