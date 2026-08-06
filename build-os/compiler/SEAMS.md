# Context Compiler v0 — seam contracts (written BEFORE the components)

PURPOSE (operator's framing): stop handing a worker a large repository and
asking it to work out what matters. Compile each task into the **minimum
sufficient execution package**. The compiler's job is one question:

> What is the least information this worker needs to produce an ACCEPTED
> outcome without avoidable exploration?

NOT a generic summarizer. A **deterministic task compiler backed by
repository state** — determinism is a hard requirement: same repo state +
same task descriptor ⇒ byte-identical capsule. Summarizers that paraphrase
constraints are the named failure mode.

These seams exist so components can be built CONCURRENTLY against fixed
interfaces. Anything not specified here is a component's own business.

## SEAM 1 — repository index (`index.json`, versioned)

Produced by the indexer, consumed by the compiler. Incremental: keyed by
git blob sha so unchanged files are never re-parsed.

```
{ "index_version": <int>, "repo_head": "<sha>", "generated_at": "<iso>",
  "files": { "<path>": { "blob": "<sha>", "lang": "<id>", "kind":
      "source|test|config|doc|generated", "symbols": ["<name>", ...],
      "imports": ["<path-or-module>", ...], "imported_by": ["<path>", ...],
      "tests_covering": ["<path>", ...], "last_changed": "<iso>",
      "error_count": <int|null> } },
  "symbols": { "<name>": { "defined_in": "<path>", "line": <int>,
      "referenced_in": ["<path>", ...] } },
  "error_clusters": [ { "signature": "<text>", "count": <int>,
      "files": ["<path>", ...] } ] }
```

HONESTY RULE: `null` means not-measured. A file whose language has no
parser gets `symbols: []` AND a `partial: true` flag — never a silent
empty. Coverage of the index is reported, never implied.

## SEAM 2 — the execution capsule (`capsule.json` + rendered `capsule.md`)

The compiler's output. Rendered form is what a worker actually receives.

```
{ "capsule_version": 1, "task_id": "<id>", "compiled_at": "<iso>",
  "index_version": <int>, "repo_head": "<sha>",
  "objective": "<one paragraph, exact>",
  "acceptance": ["<criterion>", ...],
  "relevant_files": [ { "path": "<p>", "why": "<derivation>",
      "symbols": ["<n>"] } ],
  "dependency_neighborhood": ["<path>", ...],
  "baseline": { "targeted": "<measured failure text>",
      "repo_wide": "<measured>", "measured_at": "<iso>" },
  "constraints": ["<active prior decision>", ...],
  "failed_approaches": ["<durable fact>", ...],
  "allowed_mutation_surface": ["<glob>", ...],
  "authority": { "mode": "<direct|light|full>", "receipt": "<path>" },
  "budget": { ... },
  "verification": { "commands": ["<cmd>"], "expected": "<text>" },
  "artifact_refs": [ { "id": "<name>", "sha256": "<hex>",
      "summary": "<one line>", "bytes": <int> } ],
  "provenance": { "included_because": { "<item>": "<rule that admitted it>" },
      "excluded_notable": ["<item>: <why withheld>"] } }
```

EVERY admitted item carries its admitting RULE in `provenance`. A capsule
that cannot say why something is in it is malformed. `excluded_notable`
is the honesty half: what the compiler decided to withhold.

## SEAM 3 — expansion protocol (context economy)

The worker starts minimal and BUYS more, on the record:

```
need_symbol_context(<symbol>)      need_callers(<symbol>)
need_file(<path>[, <range>])       need_prior_decision(<topic>)
need_test_history(<path>)          need_artifact(<id>)
```

Each request returns the slice and appends an `expansion_event` row:
`ts, task_id, request, granted(y/n), bytes, reason`. Every expansion is a
measurable admission that the capsule was incomplete — the compiler's own
error signal, and the input to later capsule tuning.

## SEAM 4 — durable trace facts (compaction)

Tool traces and dead ends compact to reusable facts, never transcripts:

```
{ "fact_id": "<id>", "task_id": "<origin>", "attempted": "<what>",
  "failed_because": "<observed cause>", "reusable_conclusion": "<rule>",
  "scope": ["<path-or-symbol>", ...], "evidence_class": "observed",
  "created_at": "<iso>" }
```

A fact is written only from an OBSERVED failure (a command that ran, an
error that printed) — never from model speculation. Later capsules inject
matching facts into `failed_approaches`.

## SEAM 5 — cache-stable prompt order (binding)

Rendered capsules MUST order content: (1) immutable prefix — protocol,
authority classes, receipt schema, adapter rules, byte-identical across
tasks; (2) slow-moving — repo map summary, artifact refs; (3) volatile —
this task's objective, baseline, constraints. Volatile content may never
be interleaved into the prefix: one task field must not invalidate the
whole cached prefix. Measured: cached vs uncached input, stable-prefix
reuse rate, and the cause of each invalidation.

## SEAM 6 — verifier routing (earned, not automatic)

Default is ONE parent worker plus deterministic tests. A verifier is
dispatched only on a named trigger: incomplete tests, security-sensitive
surface touched, worker-reported low confidence, diff over the risk
threshold, ambiguous baseline, or a prior failed attempt on this task.
Every dispatch records WHICH trigger fired. This is the EXP-0002 lesson
(uncontrolled Full fan-out destroyed the economics) made mechanical.

## Non-goals for v0

Embeddings/vector search (the index is AST/git/build-output derived —
deterministic beats fuzzy here), multi-repo, IDE integration, any
automatic wiring into the live routing path. **v0 ships INERT**: it is
invoked explicitly and changes no existing execution path, so PILOT-0002's
frozen environment is untouched.
