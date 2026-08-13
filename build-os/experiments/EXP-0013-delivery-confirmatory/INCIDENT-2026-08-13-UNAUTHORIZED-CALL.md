# INCIDENT 2026-08-13 — one unauthorized provider call during the pre-spend audit

Status: CLOSED by AMENDMENT v4 (structural capability separation). Evidence
below is from LOCAL logs only (`~/.claude/projects/.../5489b495....jsonl`);
no provider or billing API was consulted.

## Facts (local evidence)

| Field | Value |
|---|---|
| When | 2026-08-13T03:21:09.747Z (enqueue) → 03:21:15.571Z (response) |
| Command | `claude config get`, cwd `/home/user/ClaudeOrchestrator` |
| CLI version | 2.1.229 |
| What was transmitted | prompt `"config"` (2 input tokens; the trailing `get` was consumed by CLI arg parsing) plus the CLI-assembled session context: 44,779 cache-creation tokens (1h ephemeral) — repository instruction context (CLAUDE.md etc.), the same content class any authorized session in this repo transmits. The sealed order/blinding salts live OUTSIDE the repository and were not part of any context. No credentials or secrets were in the transmitted set. |
| Model | `claude-sonnet-5` (the CLI's default — NOT the experiment model; no experiment identity attached) |
| Session id | joined THIS orchestration session's id (inherited via `CLAUDE_CODE_SESSION_ID` in the shell env — a finding in its own right; see prevention 4) |
| Usage | input 2 · cache_creation 44,779 · cache_read 0 · output 128 |
| Cost | not present in local logs → **UNKNOWN_NONZERO** (list-price estimate ≈ $0.27, dominated by the 1h cache write). Charged to the operator account as an INCIDENT cost — outside every experiment ledger, never counted against or paid from future Stage-A authority. |
| Changed artifacts | none — the 128-token reply was conversational text ("Lane: read-only — the message is just \"config\"…"), printed to the audit shell and discarded |
| Influence on corpus/code/freeze | NONE — the corpus derives from the frozen tsc baseline; all v3 code was authored before or independently of the reply; no byte of the reply appears in any artifact (checked) |
| Containment | single call, process exited normally, no retry, no follow-up |

## Root cause

The auditor executed a CLI whose subcommand semantics were UNVERIFIED:
CLI 2.1.229 has no `config` subcommand and consumes unknown argv as a
PROMPT, so any stray execution of the binary is a paid inference call. The
deeper cause is architectural: preparation/audit workflows possessed
process-execution capability with no typed argv boundary between
"diagnostic exec" and "inference exec".

## Prevention (implemented in AMENDMENT v4, each test-enforced)

1. **Capability injection**: no-provider workflows receive transports with
   no call capability and cannot import provider execution; the ONLY
   module that may spawn the provider CLI for inference is
   `harness/provider-call-site.mjs`, and it refuses without a validated
   per-call authorization.
2. **Typed exec registry**: every external executable the harness runs goes
   through `harness/exec-registry.mjs` with per-executable, per-mode argv
   allowlists. For `claude`, the ONLY registered form outside the call site
   is exactly `["--version"]`; any other argv is REFUSED BEFORE SPAWN.
3. **Uncertain semantics are never tried**: the registry is closed-world —
   an unregistered executable or argv shape cannot run through the harness.
4. **Env allowlist**: registered execs run with a scrubbed environment that
   strips `CLAUDE_CODE_SESSION_ID` (this incident's call silently joined
   the orchestration session's identity) and other inherited state.
5. **Drift detection**: the registry records the resolved real path,
   symlink target and version of the CLI and refuses on drift.

## Contamination assessment

NONE. No experiment artifact, corpus selection, freeze input, sealed store,
or analysis path consumed any byte of the call's output; the call carried
no experiment identity to the provider (default model, no experiment
prompt); the transmitted context was the routine repo instruction set.
Incident cost stays a separate operator-account line, never reconciled
into the Stage-A ledger.
