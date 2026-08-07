# EXP-0005 mapping seal — readiness item 7

**Sealed before any arm executed.** That ordering is the whole integrity claim:
a mapping fixed in advance cannot be re-chosen once results exist.

| | |
|---|---|
| mapping sha256 | `db9348fbc656edda95685bdde062944eb067fbeeca8f77a197327e7b93eb780d` |
| tasks | 12 (all of T01–T12) |
| units | 24 — one per task per arm |
| arms | `native_claude`, `whole_gravito` |
| mapping | **one global** arm→label assignment, not per-task |
| salt | 32 random bytes, held outside the repository at mode `0600` |
| sealed mapping | outside the repository, mode `0600` |
| committed | **the digest only** (`mapping.sha256.json`) |
| verification | 13 checks, all passing |

## Derived, not sampled

The condition label comes from `sha256(salt | exp0005-global-condition-parity)`
and the identities from `sha256(salt | <role-domain> | <task> | <arm>)`. A
**sampled** mapping has no witness — nobody can later check that the recorded
assignment is the one actually drawn. A derived one is recomputed at reveal, so
the reveal verifies rather than trusts.

## The 13 checks

| check | what it establishes |
|---|---|
| `all_task_ids_represented` | all 12 frozen tasks are in the seal |
| `one_unit_per_task_per_arm` | 24 units, no unit missing or doubled |
| `mapping_is_global_not_per_task` | each arm carries one label across every task |
| `no_adj_id_collision` / `no_ana_id_collision` | 24 distinct ids in each domain |
| `id_domains_disjoint` | no identifier appears in both — the property that makes views unjoinable |
| `adversarial_join_fails` | given BOTH views, condition identity is not recoverable |
| `adjudicator_view_free_of_condition` | no arm/condition field or arm name |
| `analyst_view_free_of_condition` | same, in the other domain |
| `adjudicator_view_free_of_economics` | no token, elapsed or byte field |
| `analyst_view_free_of_diffs` | no product-diff reference |
| `no_governance_path_in_adjudicated_refs` | adjudicated references are product paths only |
| `ids_are_salt_dependent` | ids cannot be recomputed from (task, arm) without the salt |

The seal refuses and writes **nothing** if any check fails.

### One of these checks was vacuous and was replaced, not kept

An earlier version asserted that an identifier does not literally contain the
arm name. `adj_id` is `adj-` plus sixteen hex characters, so that check could
never fail — a guaranteed pass being counted as a passing check.

It is replaced by `ids_are_salt_dependent`, which tests the property that
actually matters: if identities were a salt-free function of `(task, arm)`,
anyone could recompute both domains for every unit and join them without the
seal, and the entire structure would be decorative. The replacement is verified
by re-deriving under a probe salt and requiring every id to differ.

## Demonstrated refusals

| attempt | result |
|---|---|
| salt shorter than 24 characters | **REFUSED** — "a short or absent salt is not a seal" |
| `--seal-out` inside the repository | **REFUSED** — a seal committed beside its digest seals nothing |
| a different salt | different digest (`4cd8fe8a…` vs the real one) — the digest binds the salt |

The blinding harness's own suite also passes: **41 assertions, 0 failures**,
including the adversarial join against views that *do* share a key, which is
what makes the passing case non-vacuous.

## The salt arrives by environment, never argv

`argv` is world-readable through `/proc` and `ps`. A salt visible to any process
on the machine is not sealed, so `seal-mapping.mjs` reads `EXP0005_SALT` from
the environment and refuses if it is absent.

## Two limitations, stated rather than discovered later

### 1. The salt was generated, not operator-declared

EXP-0004's salt was declared by the operator in-session. This one was generated
locally and never printed. The difference is real: an operator-declared salt
lets the operator verify the reveal **independently**, whereas here the operator
verifies through the committed digest instead.

The integrity property still holds, and it is the one that matters: the digest
was committed **before any arm ran**, so the mapping cannot be changed
afterwards to suit a result. What is weaker is independent recomputation, not
tamper-resistance. If the operator prefers to supply a salt, re-sealing before
execution costs one command and invalidates nothing — no arm has run.

### 2. The seal does NOT establish that the roles stay separate at run time

This is the important one, because it is exactly what EXP-0004 got wrong.

The seal proves the mapping was fixed in advance and that the two blinded views
are structurally unjoinable. It proves **nothing** about who holds what while
the experiment runs. Role separation is a property of execution, and a single
session acting as executor, adjudicator and analyst reproduces the EXP-0004
failure no matter how good this seal is.

**The registered mechanism for execution:** the executor (this session) holds the
salt and administers treatment, which the design permits — the executor is
entitled to know condition identity. Adjudication and analysis are each
dispatched to a **separate agent whose prompt contains only that role's view**,
built by `buildView()`, which *refuses at construction* to include a forbidden
field. Each blinded output is **frozen before** the reveal step joins it to the
mapping.

The residual risk, named: the executor reconciles both frozen outputs, so the
separation depends on the views being built correctly and on the analyses being
frozen before reveal — both of which are mechanised — and on no blinded prompt
being contaminated by hand. That last one is a discipline, not a structure, and
it is the honest remaining gap in item 7.
