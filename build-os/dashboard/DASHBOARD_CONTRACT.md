# Product evidence dashboard — the contract

**Status: internal specification + one fixture-backed renderer.** Nothing here
has been shown to a customer, and no figure produced by this view has been
independently checked by anyone outside this repository.

This is the **smallest useful** evidence contract, not an analytics platform.
It has no chart, no trend line, no score, no saving, and no comparison against
any other team or tool — because none of those has been measured. It answers
five questions and refuses the rest:

1. what ran, and how deep;
2. how long it took, and what it cost **where that is knowable**;
3. how much independent checking was bought, and whether that checking changed
   anything;
4. what the gate stopped;
5. **what this system cannot tell you** — in the same table, in the same type
   size, with the reason.

## The tier vocabulary

Borrowed from `build-os/memory/provider_adapter_contract.md`, extended to this
view's inputs. **No tier ever masquerades as a higher one.**

| tier | means |
|---|---|
| `EXACT` | counted by an instrument that observed it directly, and reproducible from the named artifact |
| `ESTIMATE` | a derived proxy. Labeled everywhere it appears, never billing truth, never promoted |
| `CLOSE-TIME` | not observable during the run; filled afterwards from a named artifact — a receipt close-fill, provider-telemetry reconciliation, or a measured-window record |
| `UNAVAILABLE` | **no artifact in this system records it today.** Rendered `unavailable` with the reason, always. Never 0 |

### Three rules the renderer is tested against

- **An unknown is never a zero.** A measured zero and an unmeasured field are
  different claims. There is no code path that turns an absent value into `0`.
- **No silent promotion.** A field whose tier is `UNAVAILABLE` stays unavailable
  even when an input file volunteers a value for it. The tier is a property of
  what the *system* can measure, not of what one file is willing to assert.
  (`build-os/dashboard/fixtures/` carries deliberate bait for exactly this.)
- **The spec and the code are one table.** The registry is embedded in
  `render-dashboard.mjs` (`render-dashboard.mjs contract --json`) and
  `tests/dashboard_contract_tests.sh` fails if it and the table below drift
  apart by so much as a word.

## The field list

Every field declares its **source** — the receipt field, ledger row, or tool
output it comes from — and its **tier**. Every `UNAVAILABLE` field declares
**why**, and what would have to exist to fill it.

| field | source | tier | reason (UNAVAILABLE only) |
|---|---|---|---|
| `task_count` | one routing receipt file per routed task in the routing store | EXACT | — |
| `execution_depth_mix` | routing receipt field `selected_mode:`, rendered Direct / Light / Full | EXACT | — |
| `depth_changes` | routing receipt fields `escalation:` and `degradation_note:`, filled at close | CLOSE-TIME | — |
| `elapsed_seconds` | routing receipt field `consumed_wall_clock_s:`, filled at close | CLOSE-TIME | — |
| `tool_actions` | `tool_event` rows in the per-task live-state file | EXACT | — |
| `exploratory_reads` | `exploratory_event` rows in the per-task live-state file | EXACT | — |
| `governed_changes` | `mutation_event` rows in the per-task live-state file | EXACT | — |
| `token_estimate` | sum of `chars=` on `tool_event` rows in the live-state files, divided by 4 | ESTIMATE | — |
| `tokens_billed` | routing receipt field `consumed_total_tokens:`, reconciled from provider telemetry at close | CLOSE-TIME | — |
| `spend_usd` | routing receipt field `consumed_cost_usd:`, reconciled from provider telemetry at close | CLOSE-TIME | — |
| `spend_by_category` | the seven `attr_*:` attribution fields on the routing receipt, filled at close | CLOSE-TIME | — |
| `verifier_use` | `task_dispatch` rows in the live-state files, cross-checked against receipt `consumed_subagents:` | EXACT | — |
| `verifier_efficacy` | `contribution:` rows on the routing receipt, fields `caught_defect=`, `changed_implementation=`, `changed_conclusion=`, `duplicated_work=` | CLOSE-TIME | — |
| `blocked_unrouted_changes` | BLOCK-MUTATION-NO-RECEIPT and BLOCK-NO-RECEIPT rows in the activity ledger | EXACT | — |
| `throttle_events` | BLOCK-FANOUT-BUDGET, BLOCK-DEGRADED, BLOCK-PROCESS-ALLOWANCE and BLOCK-REASSESS rows in the activity ledger | EXACT | — |
| `durable_change_size` | the `close` row of a measured-window record, fields `files=` and the insertion and deletion counts, derived from git by the window recorder | CLOSE-TIME | — |
| `eligibility_decision` | the `verdict` field of an eligibility record produced by the repository assessment procedure, supplied with --eligibility | EXACT | — |
| `durable_commits` | the `close` row of a measured-window record is the intended source | UNAVAILABLE | the window recorder prints the git-derived commit count to the terminal but stores the literal text derived-from-git in the commits slot, so the number is not in the record; fillable the day that recorder stores the count it already computes |
| `context_mode` | a context-mode record, field `mode:`, standard or compiled | UNAVAILABLE | the producing tool ships inert and nothing in the runtime calls it, so no customer task emits a context-mode record; this renders unavailable rather than defaulting to standard, and is fillable the day the seam is wired |
| `accepted_outcomes` | none today; the intended source is a per-task acceptance judgment recorded by the operator at close | UNAVAILABLE | no receipt field, ledger row or live-state row records whether a task output was accepted; acceptance has so far existed only as operator prose in a written report, which no tool can read; fillable when a per-task acceptance note is recorded at close |
| `human_interventions` | none today; the intended source is a per-task intervention note in the measured-window record | UNAVAILABLE | the activity ledger records the GATE intervening, which is not the same event as a human stopping, correcting or steering a run; counting gate blocks here would answer a different question while wearing this label |
| `rework` | none today; the intended source is an operator judgment recorded against a prior task id | UNAVAILABLE | nothing records whether a later change re-did an earlier accepted one, and git alone cannot separate rework from progress; inferring it from commit shape would be a guess presented as a measurement |
| `regressions` | none today; the intended source is a per-task test-result field filled at close | UNAVAILABLE | no receipt field, ledger row or live-state row stores a test result, so the suite pass or fail exists only in a terminal transcript this view cannot read; fillable when a per-task test-result field is recorded at close |

**Six of twenty-three fields are UNAVAILABLE, and four of those six are the
outcome fields a buyer actually cares about** — acceptance, human
interventions, rework, regressions. That ratio is the honest headline of this
contract, not a footnote to it. This system currently measures its own activity
far better than it measures whether that activity was any good. A dashboard
that hid this by filling those four fields with zeros, or with counts of
something adjacent, would be worse than no dashboard.

## Running it

```
render-dashboard.mjs --out <path> [--store <dir>] [--ledger <file>]
                     [--window <file>] [--eligibility <file>] [--json]
render-dashboard.mjs contract --json
```

- `--store` defaults to `<repo>/build-os/packets/routing`; `--ledger` defaults
  to `live_gate_log.tsv` inside it.
- `--out` is **required**. The tool writes exactly one file — that one — and
  refuses to run without it, because there is nowhere honest to put the answer.
- `--json` is the machine seam. Same values, same tiers, plus a `display`
  string per field so a future web shell cannot re-render a value without its
  label.

## Isolation

The renderer **reads only**. It writes exactly one path, the `--out` path. It
opens no experiment tree and no index build, and the suite greps its source to
prove it does not even name those directories. Pointing it at a store changes
nothing in that store.

## Vocabulary

The rendered view speaks the customer's language: Direct / Light / Full, helper
runs, governed changes, checking. Free text written by internal tools (a budget
note, an escalation record) passes through a word-level translation layer, then
a **backstop** that neutralises any internal token that survived — a customer
view that leaks internal words on an unusual input is a defect, not a rare
case. The translation is case-sensitive on the lowercase forms, so a customer's
own uppercase task id remains the customer's own word.

## What this contract deliberately omits

- **Any comparison to a baseline.** The dashboard shows the governed period. A
  before/after comparison requires a baseline captured by the customer under
  the discipline in `build-os/onboarding/BASELINE_CAPTURE.md`, and pairing the
  two is a judgment made by people, in writing, not a number this tool prints.
- **Any cost-per-outcome figure.** It needs both a reliable spend figure and an
  acceptance count. Spend is `CLOSE-TIME` at best, acceptance is `UNAVAILABLE`,
  and dividing an estimate by a gap produces a number that looks like evidence
  and is not.
- **Per-user or per-developer attribution.** Nothing here identifies a person.
- **Anything a customer has not already got on disk.** Every field is derived
  from a file inside the customer's own repository; this view sends nothing
  anywhere and has no server.
