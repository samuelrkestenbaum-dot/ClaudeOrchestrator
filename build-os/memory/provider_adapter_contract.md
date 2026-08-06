# Provider-adapter contract (PACKET-0054)

Task-entry governance is host-independent doctrine; what a given AI host can
actually SEE and STOP is an adapter property. This file is the interface and
the honest capability table. `routing_contract_live.md` holds the doctrine.

## The interface — four capabilities, each answered per adapter

1. **observe events** — see tool calls as they happen (pre and/or post).
2. **block pending calls** — refuse a call BEFORE it executes, with a
   model-visible reason.
3. **bind to receipt** — land every counted event in the open routing
   receipt's live-state file, so activity is attributable at close.
4. **telemetry tiers** — report resource facts at an honest tier, per field:
   - `EXACT` — counted by the adapter itself (attempts, not completions).
   - `ESTIMATE` — a derived proxy (e.g. tool-input chars / 4), labeled so
     everywhere it appears; never billing truth.
   - `CLOSE-TIME` — reconcilable from provider telemetry after the run
     (headless/API surfaces).
   - `UNAVAILABLE` — not visible on this surface; admitted, never guessed.
   **No tier ever masquerades as a higher one.**

## ADAPTER #1 — Claude Code hooks: `.claude/hooks/routing-gate.sh`

| capability | honest answer |
|---|---|
| observe events | YES — PreToolUse/PostToolUse JSON, in sessions started after the wiring loads; unhooked sessions are unobserved |
| block pending calls | YES — PreToolUse exit 2; stderr is the model-visible refusal (dispatch via `gate`, mutation-capable via `mutgate`) |
| bind to receipt | YES — append-only `live_state/<receipt-id>.tsv` per open receipt; counts derived by counting rows |
| dispatches / tool events / elapsed | EXACT |
| token proxy | ESTIMATE (chars/4, labeled in the state file and every refusal) |
| tokens / cost | CLOSE-TIME where headless (telemetry reconciliation at close); UNAVAILABLE in interactive sessions |
| known bounds | Bash classification is a NAMED HEURISTIC (`sh -c` evades it); fail-open by design; not a sandbox — the platform permission system is |

## ADAPTER #2 — Codex: **interface-unverified**

| capability | honest answer |
|---|---|
| all four | UNVERIFIED — the host was unreachable from this environment (403 at proxy on every attempt); its hook surface is NOT guessed here. Until verified, Codex sessions are outside the boundary and must be stated as such, not assumed governed. |

## Adding an adapter

An adapter row may claim a capability only with an executed demonstration in
this repository's suite (the pattern: `tests/routing_task_entry_tests.sh`
drives adapter #1 with fabricated host JSON). A row without evidence is
written UNVERIFIED — an unverified adapter is information, not coverage.

## v0 formalization (LANE-4) — build-os/adapters/

The interface above is now a NAMED CONTRACT with a conformance driver; this
section points, it does not replace — every row and bound above stays binding.
- `build-os/adapters/ADAPTER_CONTRACT.md` — ten lifecycle operations
  (task_start … capability_declaration), MUST/MAY/MUST-NOT per operation,
  tier honesty baked in (never a tier above what is measured).
- `build-os/adapters/capability-schema.json` — machine-checkable declarations;
  illegal combinations refused BY NAME by `build-os/adapters/conformance.sh`
  (schema + behavioral levels). Suite: `tests/adapter_contract_tests.sh`.
- Declarations: `claude-hooks.capability.json` (adapter #1, executed);
  `codex.capability.json` (adapter #2, four-state honest stub: binary present,
  auth absent, host unreachable/000, no successful call — 0 of 10 supported);
  `mock-adapter.capability.json` + `mock-adapter.sh` (local contract proof —
  mock proves the contract, never a provider).
