# EXP-0013 AMENDMENT v4 — incident closure and structural capability separation

Trigger: INCIDENT-2026-08-13-UNAUTHORIZED-CALL.md — during the v3 audit, a
CLI probe with unverified subcommand semantics (`claude config get`) was
consumed as a prompt and executed one unauthorized model call. The v3
posture (single probe function + PATH tripwire) was procedural; the owner's
required invariant is STRUCTURAL: preparation, audit, rehearsal,
diagnostics, freeze, analysis and publication workflows must be unable to
ACQUIRE inference capability at all.

## Changes (every one test-enforced in tests/exp0013_capability_tests.sh)

1. **Capability injection.** Inference capability exists in exactly one
   module: `harness/provider-call-site.mjs`. It is imported by NOTHING in
   the harness (statically tested); a measured run must acquire its
   transport explicitly via `acquireProviderTransport`, which validates the
   spend authorization FIRST. No-provider workflows receive transports with
   no call capability (rehearsal transport imports no child_process/net) —
   the barrier is the import graph.
2. **Typed exec registry** (`harness/exec-registry.mjs`): closed-world
   allowlists for the only five executables the harness runs (claude, git,
   bash, node, gravito), per-mode argv shapes, refusal BEFORE spawn
   (tripwire-proven), env assembled from an allowlist that STRIPS
   `CLAUDE_CODE_SESSION_ID` (the incident call silently joined this
   session's identity via inherited env), symlink/wrapper identity
   detection, and per-entry transmission/spend risk, timeout, result schema
   and failure behavior. The incident argv itself (`config get`) is a
   red-team test case and refuses before spawn. For `claude`, exactly
   `["--version"]` is registered — the one proven non-inferential form.
3. **Authorization schema** (`harness/authorization.mjs`): immutable
   (frozen) after validation; binds experiment/stage, freeze digest, source
   commit, BOTH sealed commitments, provider/model, allowed provider-id
   patterns, max calls (≤16) and spend (≤$100), expiry, serial topology,
   explicit CELL and REQUEST-DIGEST allowlists (arbitrary prompts cannot be
   authorized), rerun rules, Stage-B exclusion, the owner's authorizing-text
   digest, and the ledger directory. Synthetic authority for tests is
   indelibly marked and can NEVER cross into the real path (synthetic
   requires a fake adapter; real refuses one).
4. **Per-call enforcement at the call site**: expiry, cell/digest
   allowlists, ledger call ceiling and spend projection re-checked on EVERY
   call inside the transport, independent of the state machine; the real
   worker env additionally strips orchestration-session identity.
5. **Ledger mutex** (spend-ledger.mjs): concurrent appends serialize via an
   mkdir mutex with stale-lock breaking; reservation-before-spawn and
   conservative unknown-cost accounting unchanged from v3.
6. **CLI drift caught live and re-pinned**: the CLI auto-updated 2.1.229 →
   2.1.231 between the v3 freeze and this leg; the version preflight
   detected it. model-config.json re-pins 2.1.231 with a drift disclosure
   and the resolved binary identity (symlink `/opt/node22/bin/claude` →
   `/opt/claude-code/bin/claude`). Any further drift refuses the launch.
7. **Escrow prepared, not executed** (`harness/escrow-cli.mjs`,
   ESCROW-HANDOFF.md): no-echo passphrase entry, ciphertext-only output,
   silent decryptability proof, typed refusals; no passphrase requested or
   entered in this leg.
8. **Controller narrowed**: no provider exec, no supervise re-export — its
   only execution-adjacent capability is the read-only /proc orphan scan;
   transports own argv construction and execution.

## Unchanged

Preregistered design, gates, ladder, metrics, corpus (v3-amended), both
sealed commitments, analysis semantics, sealed EXP-0004/5/9/10/11, v1
freeze; v2/v3 manifests preserved byte-identically as history inside v4
(their own verify functions superseded — refusal is disclosure, not error).
The incident's cost remains a separate operator-account line, never part of
Stage-A authority.
