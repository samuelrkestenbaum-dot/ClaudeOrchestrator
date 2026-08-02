# Handoff `HOF-0001` — ACT-0002 -> `gravito.chatgpt.strategy`

> **This document is consumable without the originating transcript.** Every
> claim below names the object and version it came from, and every claim is
> labelled with how it is known. Nothing here is a paraphrase of a chat log.

- **context package:** `CTX-0001` — **state: CURRENT**
- **namespace:** `NS-0006` (closure-scoped; nothing outside it is included)
- **from surface:** `claude.cowork.session.ramhds`
- **compiled at:** `2026-08-02T14:45:52Z`  **handoff created:** `2026-08-02T14:45:50Z`  **status:** `created`

## 1. Objective

Take over strategy for the cross-surface memory kernel: decide what the second surface is allowed to write, and what the next packet should be, using ONLY the governed project state below.

## 2. What was completed

| object | v | type | status | truth state | authority | evidence |
|---|---|---|---|---|---|---|
| `OBJ-0009` | 2 | task | closed | `observed` | `operator` | `ART-0003` |
| `OBJ-0002` | 1 | control | active | `observed` | `operator` | `ART-0001` |
| `OBJ-0006` | 1 | receipt | closed | `observed` | `operator` | `ART-0007` |

- `OBJ-0009@2` — PACKET-0035-cross-surface-memory-kernel — BUILT: eight canonical stores, one governed adapter, a deterministic context compiler, a version-bound context package and a transcript-free ChatGPT export.
- `OBJ-0002@1` — CONTROL registry.evidence_resolution — an evidence reference must resolve, and resolvability is NOT identity.
- `OBJ-0006@1` — RECEIPT gravito_p5_outcome_counterfactual_telemetry_a — the receipt that sealed the ranking.

## 3. Current state

| object | v | type | status | truth state | authority | evidence |
|---|---|---|---|---|---|---|
| `OBJ-0001` | 1 | goal | active | `decided` | `operator` | `-` |
| `OBJ-0003` | 1 | decision | sealed | `decided` | `operator` | `ART-0002` |
| `OBJ-0004` | 1 | ranking | active | `observed` | `operator` | `ART-0008` |
| `OBJ-0005` | 1 | outcome | active | `observed` | `operator` | `ART-0009` |
| `OBJ-0008` | 1 | evidence | active | `observed` | `operator` | `ART-0005` |

- `OBJ-0001@1` — GOAL: Claude closes work into Gravito memory and ChatGPT consumes the governed project state without Sam copying the transcript.
- `OBJ-0003@1` — DECISION-0011-p5b-next-after-p3b — sealed; selector=operator; the candidate p5b citation-anchor-tokens was selected from a ranked set.
- `OBJ-0004@1` — RANKING SIGNAL-SNAPSHOT-0094-seal-anchors — rank_of_selected=1@measured, frozen at decision time and digest-chained.
- `OBJ-0005@1` — OUTCOME packet-outcome:gravito_p5_outcome_counterfactual_telemetry_a — recorded in the packet metrics store.
- `OBJ-0008@1` — EVIDENCE EV-0001-tripwire-coverage-detection-bare-node — a claim-scoped evidence assertion.

## 4. What remains open — the unresolved decisions

| object | v | type | status | truth state | authority | evidence |
|---|---|---|---|---|---|---|
| `OBJ-0007` | 1 | finding | open | `reported` | `operator` | `ART-0004` |
| `OBJ-0010` | 1 | decision | open | `unknown` | `operator` | `-` |
| `OBJ-0011` | 1 | finding | open | `observed` | `operator` | `ART-0011` |
| `OBJ-0013` | 1 | finding | open | `reported` | `operator` | `-` |

- `OBJ-0007@1` — FINDING-0003-mutators-emit-no-receipt — OPEN. The most consequential write in the system emits no receipt.
- `OBJ-0010@1` — OPEN DECISION: which surface, if any, may hold write authority into the kernel stores besides the governed adapter. Not decided; S1 promotion and autonomous dispatch are explicitly out of scope for v0.
- `OBJ-0011@1` — FINDING: under set -o pipefail a producer killed by SIGPIPE when grep -q exits early returns 141, so a PASSING assertion reports FAIL. Measured at 117 of 4000 iterations (2.9%) against the live packet metrics store.
- `OBJ-0013@1` — REPORTED: the repository suite total is a stable 1995 passed / 0 failed at this base. Recorded as reported rather than observed because this builder's own base run returned 1994/1.

## 5. Evidence

| artifact | kind | resolves to | anchor |
|---|---|---|---|
| `ART-0001` | repo_file | build-os/registry/control_registry.txt:1942#ANC-0001 | `ANC-0001` |
| `ART-0002` | repo_file | build-os/metrics/decision_telemetry.tsv:48#ANC-0002 | `ANC-0002` |
| `ART-0003` | repo_file | build-os/packets/active_packet.md:15#ANC-0003 | `ANC-0003` |
| `ART-0004` | repo_file | build-os/registry/findings.txt:67#ANC-0004 | `ANC-0004` |
| `ART-0005` | repo_file | build-os/registry/evidence_assertions.txt:95#ANC-0005 | `ANC-0005` |
| `ART-0007` | repo_file | build-os/receipts/gravito_p5_outcome_counterfactual_telemetry_a.md:1#ANC-0007 | `ANC-0007` |
| `ART-0008` | repo_file | build-os/metrics/signal_snapshots.tsv:173#ANC-0008 | `ANC-0008` |
| `ART-0009` | repo_file | build-os/metrics/packet_metrics.tsv:17#ANC-0009 | `ANC-0009` |
| `ART-0011` | repo_file | tests/speed_benchmark_tests.sh:- | `-` |

## 6. Authority in force

- **declared on the handoff:** `operator`
- **derived from the package:** `scope=NS-0006;closure=NS-0006,NS-0007;out_of_closure_refused=1;effective=operator`
- **contradictions detected:** `REL-0007:OBJ-0011-contradicts-OBJ-0013`

## 7. The next decision required

Decide the write-authority question recorded as OBJ-0010, which OBJ-0007 blocks. Do NOT promote S1 and do NOT enable autonomous dispatch: both are out of scope for v0 and neither is authorised here.

**Acceptance criteria:** A decision object recorded in NS-0006 at version 1 with truth_state=decided, an authority_ref, and at least one resolvable evidence reference; plus a HandoffAccepted event naming this handoff.

## 8. What was deliberately NOT included

Nothing was omitted from the package.

## 9. The binding — read this before acting

This export is bound to exact source versions. If any of them has advanced,
this document is HISTORY and not the present, and `read-context-package
--as-current` will refuse it rather than let it be mistaken for current state.

| source object | version | truth state | type |
|---|---|---|---|
| `OBJ-0001` | 1 | `decided` | goal |
| `OBJ-0002` | 1 | `observed` | control |
| `OBJ-0003` | 1 | `decided` | decision |
| `OBJ-0009` | 2 | `observed` | task |
| `OBJ-0006` | 1 | `observed` | receipt |
| `OBJ-0004` | 1 | `observed` | ranking |
| `OBJ-0005` | 1 | `observed` | outcome |
| `OBJ-0008` | 1 | `observed` | evidence |
| `OBJ-0007` | 1 | `reported` | finding |
| `OBJ-0010` | 1 | `unknown` | decision |
| `OBJ-0011` | 1 | `observed` | finding |
| `OBJ-0013` | 1 | `reported` | finding |

**Truth-state vocabulary:** `observed` (measured in this tree) · `reported`
(stated by a source) · `inferred` (a model concluded it; NOT an observation) ·
`decided` (an authority chose it) · `verified` (independently re-measured) ·
`refuted` (measurement contradicted the claim) · `unknown`.

<!-- gravito-canonical: handoff=HOF-0001 package=CTX-0001 namespace=NS-0006 hash=a8676c9d658d696d0ebd1d6f74d34a7bcba973b69a7bc7152c48bed116b0eec6 -->
