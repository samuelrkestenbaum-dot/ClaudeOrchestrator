# Dashboard fixtures — FABRICATED, NOT MEASUREMENTS

Every file under this directory is **fabricated demonstration data**. Nothing
here was observed, recorded, or measured by any run. It exists for exactly one
purpose: to drive `render-dashboard.mjs` through every branch of the contract
in `DASHBOARD_CONTRACT.md` — an EXACT count, an ESTIMATE, a CLOSE-TIME value
that is present, a CLOSE-TIME value that is absent, and an UNAVAILABLE field.

**Do not quote a number from this directory anywhere.** Not in a proposal, not
in a deck, not in a conversation with a candidate design partner. A fabricated
figure that escapes a fixture directory becomes a false claim the moment it is
repeated, and this product's entire argument is that it does not do that.

## What each fixture is for

| path | drives |
|---|---|
| `routing/routing-DEMO-*.md` | routing receipts: one closed with a full close-fill, one closed thin, one still open |
| `routing/live_state/*.tsv` | the per-task activity rows the EXACT counts and the ESTIMATE proxy are derived from |
| `routing/live_gate_log.tsv` | the activity ledger the blocked-change and throttle counts are derived from |
| `window/WINDOW.tsv` | a closed measured window, which supplies durable change size and demonstrates that durable *commits* is still unavailable |
| `eligibility.json` | a repository-eligibility verdict |

## The deliberate bait

`routing/routing-DEMO-0001-*.md` carries `accepted: yes`,
`human_interventions: 3` and `regressions: 0` — fields no real receipt has and
no real tool writes. They are there so the suite can prove the renderer
**ignores** them: a field whose tier is UNAVAILABLE stays unavailable no matter
what an input file volunteers, because the tier describes what the system can
measure, not what a file is willing to assert.
