# Context Compiler — runtime (lane C)

The three programs a worker touches at run time: the **expansion API**, the
**artifact registry**, and the **trace compactor**. They implement SEAM 3,
SEAM 2's `artifact_refs`, and SEAM 4 of `build-os/compiler/SEAMS.md`.

**v0 is INERT.** These are invoked explicitly and are wired into no existing
execution path, per the SEAMS.md non-goal. Nothing here changes routing.

Bash + Node stdlib only. No dependencies, no network, no daemon.

## The product need

A capsule ships the *minimum sufficient* context. Two things follow, and this
directory is both of them:

1. When the minimum is too little, the worker must be able to **buy more, on the
   record** — otherwise it silently re-reads the repository and the compiler
   never learns it under-packed. That is `expand.mjs`.
2. What a run *learns* must survive as **facts, not transcripts**, and only
   facts that were actually observed. That is `compact-trace.mjs`.

`artifacts.mjs` is the indirection that keeps large evidence out of the prompt
while remaining provable.

## `expand.mjs` — the expansion API (SEAM 3)

```
expand.mjs need_symbol_context <symbol>   --index <i> --repo <r> --task <t> --events <e>
expand.mjs need_callers        <symbol>   [--max-callers N]
expand.mjs need_file           <path>     [--range A-B]
expand.mjs need_prior_decision <topic>    --decisions <jsonl>
expand.mjs need_test_history   <path>
expand.mjs need_artifact       <id>       --registry <dir>
expand.mjs report <events.tsv>
```

Exit `0` granted, **`3` denied**, `2` usage. Every request appends exactly one
row to the append-only TSV `ts, task_id, request, granted, bytes, reason`.

**The byte accounting is exact and is the point.** Each response carries:

| field | meaning |
|---|---|
| `source_bytes` | the underlying material considered |
| `content_bytes` | how much of it was actually delivered |
| `withheld_bytes` | `source_bytes - content_bytes`, always stated |
| `bytes` | what the worker is **billed** (rendered slice, incl. framing) — the column charged against `--budget` |

`content_bytes + withheld_bytes == source_bytes` holds for all six request
types and is asserted for all six. `bytes` is reported separately from
`content_bytes` on purpose: framing is real cost, and folding the two would let
a slice look cheaper than it is.

**Denial is data.** An unknown symbol, an unknown path, an unmatched topic, an
exhausted budget — each appends a row *with its reason*. A protocol that logs
only its grants describes a context economy that never happened.

**`report` is an error signal, not a usage meter**, and it says so in words.
Repeated expansion of the same kind means the capsule was *systematically
incomplete*: the compiler's selection rule for that kind is what needs fixing.
The `most_requested` ranking exists to name those candidates for inclusion by
default.

## `artifacts.mjs` — content-addressed registry (SEAM 2)

```
artifacts.mjs put <file> --registry <dir> [--summary <line>]   -> <sha256 id>
artifacts.mjs get <id>   --registry <dir>                      -> raw bytes
artifacts.mjs ref <id>   --registry <dir>                      -> { id, sha256, summary, bytes }
artifacts.mjs verify     --registry <dir>                      -> census; exit 1 if corrupt
```

Layout is a directory: `objects/<sha256>` plus a 4-field `index.tsv`. The id
**is** the digest, so **dedupe is a consequence of the addressing**, not a
feature, and `verify` detects corruption because a tampered object no longer
hashes to its own name. `id` and `sha256` are equal by construction here; SEAM 2
keeps both fields for a future named-artifact store, and this one does not
pretend to be it.

## `compact-trace.mjs` — durable facts (SEAM 4)

```
compact-trace.mjs compact <trace.jsonl> --task <id> [--now <iso>] [--out <f>]
compact-trace.mjs match   <facts.jsonl> --scope <path|symbol>
```

Input (**our format, not a standard**), one JSON object per line:

```
{"kind":"command","command":"<cmd>","exit":<int>,"output":"<captured>","scope":["<path>"]}
{"kind":"note","text":"<anything>"}      <- speculation: ignored, always
```

**The one rule.** A fact is emitted only from an **observed** failure: a command
that actually ran with a non-zero exit, or an error string present in captured
output. `evidence_class` is always `"observed"`. `reusable_conclusion` is
**composed** from the failing command, the error text and the touched scope —
there is no point in the program where free-form prose enters the record. A
trace containing only speculation emits **nothing** and says so on stderr; that
is a correct outcome and exits 0.

This is the load-bearing behaviour of the whole directory. A fabricated fact is
shaped exactly like an observed one, so once it is injected into a later
capsule's `failed_approaches` it steers workers away from approaches that may
work perfectly well — invisibly, and with the authority of a record. A compactor
that guesses is worse than no compactor.

`match` returns facts whose scope overlaps the query by exact match or path
containment. Deliberately not fuzzy: a fact injected into the wrong capsule is a
lie by misfiling.

## Limitations — stated, not implied away

- **Slice selection is a heuristic.** A line window around a declaration is not
  a parsed symbol span, and a caller snippet is a line match, not a call graph.
  The *accounting* is exact; the *choice of lines* is not. Tests pin the
  arithmetic and the bounds, never that the window is semantically right.
- **No semantic dedupe of facts.** Identical evidence collapses by `fact_id`,
  but two facts stating the same thing in different words both survive.
- **Single store.** One registry directory, one ledger file, no locking, no
  concurrent-writer story. Appends are single-process appends.
- **The trace input format is ours**, not a standard. Nothing emits it yet.
- **`report` measures the ledger, not the capsule.** It can say a kind of
  expansion recurs; it cannot say which selection rule failed.
- The index is consumed **as given**. SEAM 1's `null`-means-not-measured rule is
  passed through (`error_count` stays null, never 0), but nothing here verifies
  the index is true.

## Tests

`tests/compiler_expansion_tests.sh` — standalone, **102 assertions, 0 failures**,
no network, all fixtures under one `mktemp` dir.

> **Merger debt:** this suite is **not yet chained** from `tests/build_os_tests.sh`,
> which is owned by another lane. That file's `tests/*.sh` sweep will report this
> suite as unwired until the merger adds:
> `chain_suite "tests/compiler_expansion_tests.sh" "the context compiler's expansion API, artifact registry and trace compactor"`
