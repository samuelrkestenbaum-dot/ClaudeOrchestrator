# Claude → live Operator Lab write path — BLOCKED, with the missing leg named

**The path was not built, because there is nothing to build it against.** Per
the standing instruction — *record exactly which leg of the loop is unavailable
rather than substituting synthetic evidence* — this is that record.

## What was checked

| check | result |
|---|---|
| Operator Lab tool in this session's tool surface | **ABSENT** — a search across all available tools returns Apollo, Zapier, GitHub, Serena and no Gravito/Operator Lab surface |
| local specification of the Lab write interface | **ABSENT** — no endpoint, schema, auth model or client anywhere in this repository |
| the one candidate MCP server (`33794ec3-…`) | **UNAUTHENTICATED** — requires an OAuth flow a non-interactive session cannot perform |

**Conclusion: this Claude session has no write path to the live Operator Lab,
and none can be constructed from here.** Building one against a guessed
interface would embed exactly the kind of untested environmental assumption that
produced the bootstrap defect and the permission-class mismatch.

## The two observations are one fact

- `live_operator_lab_participation` reports **claude: missing**;
- this session independently confirms it **cannot write** to that store.

These are not corroborating measurements. They are the same capability gap seen
from outside and inside. The gate is measuring something real.

## The write-path contract — specified so it can be built without guessing

When Lab access exists, the path must supply:

| requirement | note |
|---|---|
| stable Claude surface identity | must yield family `claude` under the Lab's rule: first dot-separated token of `agent_id` |
| attributable `agent_id` | e.g. `claude.cowork.session.<id>` — session-scoped, never shared with another surface |
| real write to the same store `check_substrate_readiness` reads | a repository-only write is NOT live participation |
| event type | drawn from the Lab's vocabulary, not invented locally |
| timestamp semantics | must fall inside the Lab's **24-hour** lookback to count |
| provenance | originating session, model, and the causing action |
| rejection evidence | a refused write must be recorded as refused, never dropped silently |

## The acceptance proof, unchanged and unmet

    before: live_operator_lab_participation.claude = missing
    → one genuine Claude-originated Lab write
    after:  live_operator_lab_participation.claude = active

evaluated by the **existing** gate under its **existing** semantics. The
readiness calculation must not be modified to make Claude appear active — that
would be fabricating the result the gate exists to detect.

**Currently unmet at the first step**, because the write cannot be performed.

## Consequences, stated plainly

- **Layer 2 cannot improve for Claude** until this path exists.
- **Layer 3 cannot be exercised on the Claude↔ChatGPT pair**, because the
  write-back leg runs through the Lab. The unavailable leg is precisely:
  **Claude → live Operator Lab write.**
- `manus` and `surplus_recovery` remain repository-**UNTESTED** and live-**missing**.
  No synthetic activation was created for any surface.

## What would unblock it

One of: Lab credentials/interface exposed to a Claude session; a documented Lab
write API this repository can implement a client against; or an operator-executed
write on Claude's behalf with the resulting record shown, which would prove the
store accepts a Claude-attributed row even if it does not prove Claude can
originate one.
