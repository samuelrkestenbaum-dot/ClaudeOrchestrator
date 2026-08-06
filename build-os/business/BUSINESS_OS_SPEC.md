# Business Operating Layer — kernel specification v0 (LANE 5)

STATUS: specification only. No CRM, no business suite, no runtime — the
minimal kernel objects and evidence discipline that would let Gravito
reason from BUSINESS evidence rather than model opinion, sitting above
the runtime governor (routing/authority/budgets/receipts) that exists.

## Design rule inherited from the runtime

The runtime's honesty doctrine transfers whole: an unknown is not a zero;
a claim carries its evidence class; refusal is for contradiction; nothing
is labeled enforced that is not. The business layer's version: **a
convincing AI-generated market thesis is never customer evidence.**

## Evidence classes (ordered by strength; every business object carries one)

1. `ai_inference` — model reasoning alone. Cheapest, weakest. Never
   sufficient for commitment decisions.
2. `desk_research` — public sources, cited.
3. `customer_statement` — a real prospect/customer said it (interview
   note, email). Attributed, dated.
4. `observed_behavior` — the customer DID something measurable (used the
   product, opened, clicked, returned).
5. `signed_commitment` — LOI, pilot agreement, contract.
6. `payment` — money moved.
7. `retention` — payment/usage REPEATED across periods.

Promotion between classes is an EVENT with evidence attached, never a
relabel. The business equivalent of a passing test starts at class 3 and
gets decisive at 5–7.

## Kernel objects (durable, minimal fields; all carry: id, created_at,
## evidence_class, evidence_refs[], status, decided_by where applicable)

- `business_objective` — statement, success_criteria[], economic_bounds
  (what must be true), parent_objective?. The root of the objective
  GRAPH (not a task list).
- `customer_segment` — definition, size_estimate(+class), pains[].
- `problem_hypothesis` — segment_ref, pain, severity_estimate(+class),
  falsifier (what observation would kill it).
- `market_evidence` — class, source, content_ref, hypothesis_refs[].
- `offer` — segment_ref, value_proposition, price_structure, delivery
  model, status(draft|validated|live|retired).
- `experiment` — hypothesis_ref, cheapest_credible_design, cost_bound,
  result(+class), decided_outcome. (Mirrors the prereg-before-run,
  registered-vocabulary discipline of EXP-0001..3.)
- `lead` / `opportunity` / `customer` — the pipeline trio: contact_ref,
  segment_ref, stage, next_action, authority_needed_for_next_action.
- `revenue_event` / `cost_event` — amount, date, customer_ref?, category
  (the unit-economics substrate: CAC, margin, payback derive from these,
  never hand-entered as conclusions).
- `operating_metric` — name, value, period, derivation (EXACT|DERIVED|
  ESTIMATE tier, reusing the runtime's tier vocabulary).
- `strategic_decision` — question, options_considered, decision,
  evidence_refs[], decided_by (HUMAN for consequential), revisit_when.
- `approval` — action, scope, granted_by, bounds, expiry. External
  authority mirror of the runtime's explicit-go rule: outreach, spend,
  contracts, legal claims, data collection, production change, hiring,
  binding terms are NEVER self-granted.
- `outcome` — objective_ref, result, evidence_class, learned.

## The one behavioral law

Given an idea, the system asks FIRST: "what is the cheapest credible
evidence that this business should exist?" — then walks
hypothesis → evidence → small commitment → paid pilot → repeatable
delivery → scalable product, promoting evidence classes at each step.
North-star metric: durable enterprise value created per unit of money,
AI compute, time, and human attention — not tasks completed.

## Interfaces to the existing substrate (defined, not built)

- Every business object mutation routes through the runtime governor
  (task entry, depth selection, receipts) exactly like code mutations.
- Workstreams (product/research/marketing/sales/ops/finance/legal/
  support) route independently: a landing-page edit can be Direct while
  a pricing analysis is Light and a contract is Full + human approval.
- The evidence ledger is append-only with the same admission semantics
  ('-' is an admission, never a zero).

## Explicitly out of scope for v0

CRM UI, integrations, email/outreach tooling, financial reporting,
multi-tenant anything. This kernel exists so the FIRST business object
created is governed and evidence-classed from day one.
