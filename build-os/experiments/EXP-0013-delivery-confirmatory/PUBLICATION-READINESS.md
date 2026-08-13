# EXP-0013 — INCIDENT CLOSURE & PUBLICATION READINESS (final local leg)

## VERDICT: READY_FOR_PUBLICATION_AND_OWNER_ESCROW_HANDOFF

The unauthorized-call incident is formally closed with a structural fix, not
a procedural promise. The required invariant now holds and is test-enforced:
**preparation, audit, rehearsal, diagnostics, freeze, analysis and
publication workflows structurally cannot acquire inference capability;
only measured execution, after per-call authorization validation, receives
the provider transport.** Governing freeze: FREEZE-MANIFEST-v4.json, digest
`a89de23bfb0e254950848f3632bbec114f7c837692f806f2ddf21a1b34bcf006`.

## 1. Incident (INCIDENT-2026-08-13-UNAUTHORIZED-CALL.md)

`claude config get` at 2026-08-13T03:21:09Z was consumed as the prompt
"config": 2 input + 44,779 cache-creation + 128 output tokens to
`claude-sonnet-5` (CLI default — no experiment identity), session id
inherited from this orchestration session via env, cost UNKNOWN_NONZERO
(≈$0.27 by list price; not in local logs). Transmitted content: the routine
repo instruction context — no secrets, no sealed salts (outside the repo).
Contamination: NONE (no artifact contains any byte of the reply). The cost
is an operator-account incident line, permanently outside Stage-A authority.

## 2. Capability graph → sole call site (capability suite, 20/20)

Inference capability lives ONLY in `harness/provider-call-site.mjs`: zero
importers in the harness (static test), acquires-only via
`acquireProviderTransport` after schema validation, per-call re-checks
(expiry, cell allowlist, request-digest allowlist, ledger call ceiling,
spend projection), worker env stripped of orchestration identity.
Rehearsal transport imports no child_process/net; no harness module imports
network capability; no dynamic import() exists; exactly one module combines
provider argv with an execution call. Retry/resume have no other route.

## 3. Exec registry (harness/exec-registry.mjs)

Closed world: claude, git, bash, node, gravito — each with typed per-mode
argv allowlists, transmission/spend risk, timeout, result schema, failure
behavior. Refusal BEFORE spawn (tripwire-proven: the incident argv `config
get`, `-p`, unregistered `curl`, and absolute-path bypass all refuse with
the shim binaries never executing). Env allowlist strips
`CLAUDE_CODE_SESSION_ID`. Identity: `claude` resolves through a symlink
(`/opt/node22/bin/claude` → `/opt/claude-code/bin/claude`), recorded.
**Drift caught live**: the CLI auto-updated 2.1.229 → 2.1.231 during this
leg; the preflight refused until v4 re-pinned it with disclosure.

## 4. Authorization schema (synthetic-only proof)

Binds experiment/stage/freeze-digest/source-commit/both-commitments/
provider/model/id-patterns/max-calls≤16/max-spend≤$100/expiry/serial/
cell-and-request-digest-allowlists/rerun-rules/Stage-B-exclusion/owner-text
digest/ledger dir; frozen after validation. Proven refusals: wrong freeze,
wrong source, wrong mapping, wrong model, expired, parallel topology,
over-calls, over-spend, Stage-B not excluded, empty allowlists, unlisted
cell, unlisted prompt. Valid synthetic request → fake provider called
EXACTLY once. Synthetic-without-adapter and real-with-adapter are mutually
uncrossable. No real authority was created anywhere.

## 5. Budget proof

Reserve-at-$6-bound before spawn (mkdir-mutex serialized), settle after,
unknown/aborted retained at bound forever, restart re-reads, torn/malformed
/duplicate/chain-broken ledgers are typed refusals stopping all calls; call
ceiling and spend exhaustion additionally refused inside the transport.
Concurrent controller against a held study lock refuses before any call.

## 6. Escrow (prepared, NOT executed)

`harness/escrow-cli.mjs` + ESCROW-HANDOFF.md: no-echo passphrase entry,
scrypt+AES-256-GCM, ciphertext-only repo artifact, silent byte-identical
decryptability proof, typed wrong-key/tamper/weak-passphrase refusals
(tested on synthetic mappings). No passphrase was requested or entered.
Role isolation remains PROCEDURAL (one OS identity) — stated, not hidden.

## 7. Freeze decision

The capability refactor changed frozen semantics (controller, spend-ledger,
transport-measured, model-config, suites) → **v4 created**. v1 verifies
live; v2/v3 manifests preserved byte-identically inside v4 (their own
verifies superseded, which is the disclosure). 51 artifacts + directory
inventories + mode bits.

## 8. Rehearsal (fresh, v4)

61 hash-chained green steps; freeze v4 + both sealed commitments verified
in-run; registry-gated CLI preflight at 2.1.231; 10 semantic request
digests; sentinel NO_PROVIDER_CALL; PATH tripwire untripped.

## 9. Suites

fixture 22 · readiness 33 · red-team 27 · **capability 20 (new)** ·
planner 25 · control_primitives 47 · neurocosmology_invariant 21 ·
context_delivery 12 · goal_enforcement 34 · lifecycle 35 · doc_drift 10 ·
cross_repo_isolation 14 · authority_envelope 126 — **426 checks, 0
failures**; sealed EXP-0004/5/9/10/11 byte-identical; v1 and v4 verify
after the full battery.

## 10. Publication procedure (prepared, NOT executed)

Chain: published `607c0bd` + 8 local commits (…`562fff4`, `e30fc15`,
`<evidence commit>`). On the owner's go: verify old remote tip = `607c0bd`,
exactly one fast-forward push through the wired publish gate (fresh scoped
authorization in the publish-check schema), independently fetch and verify
new tip equality and zero divergence, clean tree, then `freeze.mjs verify`
and `freeze4.mjs verify` against the pushed tip. Manifests reference
commits by RECORDING the freeze-time commit — supersession is always a new
manifest; no hash is ever refreshed in place. Zero measured calls occurred;
no real spend authority exists anywhere in the tree.

### Push authorization template (owner wording)

> Explicit owner authorization: push exactly the audited local commit range
> 607c0bd..<TIP> (<N> commits, new tip <TIP>) to origin
> claude/project-handoff-merge-ramhds, fast-forward only, exactly one push;
> record the scoped authorization in the publish-check schema; verify the
> expected old remote tip 607c0bd before pushing, then independently fetch
> and verify the remote tip equals <TIP> with zero divergence, and verify
> FREEZE-MANIFEST v1 and v4 against the pushed tip.

### Post-push escrow instruction (separate; no secret in chat, ever)

After the push is verified, on this machine:
`node build-os/experiments/EXP-0013-delivery-confirmatory/harness/escrow-cli.mjs create`
— type the passphrase twice (echo disabled; it must never appear in chat,
files, or history), let the tool print the ciphertext digest, then commit
`corpus/mapping-escrow.json` under a scoped go quoting that digest, and
store the passphrase outside this container at least until Stage-A reveal
and audit close. Measured-run (spend) authority remains a separate,
later authorization per PRE-SPEND-AUDIT.md Template B, updated to name the
v4 digest and the escrow-completion prerequisite.
