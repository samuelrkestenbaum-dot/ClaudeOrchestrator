# EXP-0013 AMENDMENT v3 — post-audit corrections (disclosed, never silent)

An owner-authorized adversarial pre-spend audit challenged the
READY_FOR_SPEND_AUTHORIZATION verdict. Every correction below is a disclosed
amendment: v1 verifies untouched; the v2 manifest FILE is preserved
byte-identical as immutable history and is frozen inside v3; freeze2's own
verify is intentionally superseded (controller.mjs and seal-orders.mjs
changed under this amendment, so freeze2 SHOULD refuse — that refusal is the
amendment being visible). The verification tool of record is now freeze3.mjs.

## Corrections

1. **Transport injection replaces the barrier-by-convention.** Rehearsal now
   receives transport-rehearsal.mjs — a module importing NO process-execution
   capability. The no-call guarantee is the import graph. The PATH shim
   remains as a tripwire only.
2. **The measured state machine now EXISTS and is tested.** v2 claimed
   readiness while `runMeasured` was contract-only. It now implements seeds,
   distillation, store pinning, sealed-order pairs, the model-id gate after
   call 1 (abort before call 2, call 1 still charged), rerun policy, and
   every stop rule — proven with scripted fake transports; real transport is
   refused without a valid spend authorization naming the v3 freeze digest.
3. **Durable conservative spend accounting.** Hash-chained ledger:
   reserve-at-bound before every call, settle after; unknown/missing cost
   charged at the bound forever; malformed/torn/broken-chain ledgers are
   typed refusals that stop all calls; restart re-reads the ledger; hard
   MAX_CALLS=16 independent of budget.
4. **Seed distillation implemented and frozen** (distill.mjs): mechanical,
   deterministic, renderer-independent, UCDL-parseable output; frozen seed
   failure policy — one seed rerun, then SEQUENCE_VOID before any measured
   spend in that sequence.
5. **Rerun orders are pre-sealed** (seal-orders.mjs generateRerun +
   corpus/RERUN-ORDER-COMMITMENT.json). Resolves the preregistration's
   "fresh order draw" ambiguity as fresh-but-precommitted: one independent
   fair coin per pair, drawn NOW, sealed outside the repo, committed inside.
6. **Freeze hardened** (freeze3.mjs): directory inventories (added files now
   detected), mode bits (permission drift now detected), and the previously
   unfrozen runtime dependencies (bin/gravito, reachability.mjs, h0-check.sh,
   goal template) are frozen.
7. **Mapping durability without reveal** (mapping-escrow.mjs): scrypt +
   AES-256-GCM escrow of the sealed stores; ciphertext safe to commit; wrong
   key and tamper are typed refusals (tested on synthetic mappings only).
   Custody is honestly OFFERED, not guaranteed: the owner must hold the
   passphrase; the spend template names the handoff as a prerequisite.
   Executed evidence also corrected the risk claim: post-launch analyzability
   never depended on the sealed store (cell records carry arm identity);
   what the escrow preserves is precommitment PROOF.
8. **View leak check hardened** (leakcheck2.mjs): SKILL.md/.claude/skills/
   task-log.md/repair-* artifact names, byte-size side channels, and
   execution identity are now refused in adjudicator/analyst views; role
   separation is honestly classified PROCEDURAL, not structural.
9. **CLI probe restricted to exactly ["--version"].** Audit incident
   (disclosed): a probe of `claude config get` under CLI 2.1.229 was consumed
   as a PROMPT and executed one real, unauthorized model call — proof that
   any stray CLI exec is a paid call. Preflight now goes through a single
   probe function that can only ever pass ["--version"].

## Unchanged

Preregistered design, gates, ladder, metrics, corpus, primary orders and
their commitment, analysis semantics, all sealed EXP-0004/5/9/10/11
artifacts, v1 freeze, and the v2 manifest bytes.
