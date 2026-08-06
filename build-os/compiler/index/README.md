# Context Compiler — repository index (SEAM 1)

Produces the `index.json` that SEAM 1 of `build-os/compiler/SEAMS.md` specifies.
The compiler consumes it; this component only produces it. **v0 is inert** — it
is invoked explicitly, wires into no execution path, and changes no routing.

## Usage

```
node build-os/compiler/index/build-index.mjs build <repo> \
    [--out <path>] [--since <index.json>] [--errors <file>] [--deterministic]

node build-os/compiler/index/build-index.mjs stats <index.json>
```

* Index JSON goes to `--out`, or to **stdout** when `--out` is absent.
* Every human line (reuse counters, refusals) goes to **stderr**, so
  `build <repo> > index.json` stays a clean redirect.
* `--since <index.json>` reuses the prior parse for files whose git blob sha is
  unchanged.
* `--errors <file>` takes an **already-measured** `tsc`-style error list
  (`path(line,col): error TS2304: message`). The indexer never runs a build.
* `--deterministic` nulls `generated_at`, so two runs of the same repo state are
  byte-comparable.
* Exit codes: `0` ok, `2` refusal (not a git repo, unknown flag, unreadable
  index).

Requires bash + node stdlib + git + coreutils. No dependencies, no network.

## What is indexed

`git ls-files` only. Untracked and ignored files are absent **by construction**,
not by oversight: the index describes the repository, not the working
directory's debris. A tracked file missing from the worktree is skipped and
counted in the stderr line.

## Schema

Exactly the SEAM 1 fields, plus four additive ones. Additive fields are the
component's own business per the seam document; nothing required is renamed or
dropped.

| Field | Status | Meaning |
|---|---|---|
| `files[p].blob/lang/kind/symbols/imports/imported_by/tests_covering/last_changed/error_count` | SEAM 1 | as specified |
| `files[p].partial` | SEAM 1 honesty rule | always `true` in v0 |
| `files[p].parser` | additive | which extractor ran: `js-ts-regex-v0`, `python-lines-v0`, `go-lines-v0`, `rust-lines-v0`, `none` |
| `files[p].symbol_lines` | additive | symbol → declaration line, so reuse keeps line numbers |
| `files[p].raw_imports` | additive | specifiers **as written**; `imports` is derived from these each build |
| `symbols[n].also_defined_in` | additive | other files declaring the same name (`defined_in` can only hold one) |
| `symbols_partial` | additive, top level | `referenced_in` is a text heuristic |
| `tests_covering_heuristic` | additive, top level | `tests_covering` is import-or-basename |
| `errors_measured` | additive, top level | `false` ⇒ every `error_count` is `null` |

`raw_imports` exists for a determinism reason, not a convenience one: `imports`
resolves against the whole current file set, so a reused entry that cached
*resolved* paths would drift when an unrelated file appeared or vanished. The
reusable unit is therefore the raw parse, and every whole-repo-dependent field
(`imports`, `imported_by`, `tests_covering`, `error_count`, `last_changed`) is
recomputed on every build. This is what makes an incremental build
byte-identical to a full build of the same tree.

## Determinism

Hard requirement. Same repo state ⇒ byte-identical index.

* Every collection is sorted with the default code-unit comparator (never
  `localeCompare`, which is locale-dependent).
* No per-file field carries a wall clock. `generated_at` is the only time field;
  `--deterministic` nulls it. `last_changed` is a git commit date — a function
  of repo state, not of run time.
* Reuse counters are reported on stderr and are **not** stored in the index,
  precisely so a full build and an incremental build produce the same bytes.

Verified in the suite on fixtures, and observed on this repository: 390 files,
full build and `--since` build byte-identical.

## Honesty — what this is NOT

There is **no AST**. No TypeScript compiler, no tree-sitter, no language server.
What exists is a character scanner that tracks line comments, block comments,
single/double/template strings and regex literals, producing two masked views of
the source, with line regexes run over them. That is enough to make
`// import { ghost } from './ghost'` invisible and `const re = /it's/` harmless.
It is not a parser, so:

* **Every file is `partial: true`.** Absent symbols mean *not extracted*, not
  *not present*.
* Not extracted: class methods, object-literal members, destructured bindings,
  overload signatures, `.d.ts` ambient declarations, multi-line `export { ... }`
  lists, and anything produced by a macro or decorator.
* Non-exported `const`/`let`/`var` are taken only at top level; otherwise every
  local binding in every function body would become a "symbol".
* Rust uses a naive comment strip rather than the C-like scanner, because a
  lifetime (`'a`) is indistinguishable from an opening quote to that scanner. A
  `use` inside a Rust string is therefore over-reported.
* Python/Go/Rust extraction is line-oriented and best-effort by design.
* `referenced_in` is a **whole-word text match**, not a resolved reference
  graph: a comment, a string, and a same-named unrelated identifier all count.
* `tests_covering` is a **heuristic** — a test "covers" a file if it resolves an
  import to it, or if their basename stems match after stripping test/spec
  affixes. Neither is evidence the test exercises the file.
* Only relative import specifiers are resolved. Bare specifiers (`express`,
  `os`, `app.helpers`), path aliases and `tsconfig` `paths` stay verbatim in
  `imports` and **never** produce an `imported_by` edge. An invented reverse
  edge is worse than a missing one.
* `null` means not-measured. `error_count` is `null` until `--errors` supplies a
  measurement, never `0`.

`stats` exists so this is reported rather than implied. Run against this
repository it says so immediately: 97.4% of files have **no parser**, because
the repo is mostly shell and v0 has no shell extractor.

## Known gaps (v0)

1. **No shell extractor** — the highest-value gap for this repository
   specifically.
2. Regex/line extraction rather than AST, everywhere (see above).
3. Single repo, single worktree. Passing a *subdirectory* of a repo yields paths
   relative to that subdirectory while `repo_head` is the whole repo's — usable,
   but not what a caller indexing a monorepo package probably means.
4. No language-server or IDE integration, no embeddings — deliberate: SEAM 1
   chose deterministic over fuzzy.
5. Incremental reuse skips **parsing**, not file IO. Every file is still read,
   because the blob sha is computed from the same bytes that get parsed and the
   `referenced_in` pass tokenizes every file.
6. `referenced_in` is O(symbols × files) set lookups; fine at this repository's
   scale (390 files, ~0.4s), unmeasured at 100k files.

## Tests

`tests/compiler_index_tests.sh` — standalone, no network, mktemp fixtures only
(a TS/JS repo with imports/tests/generated output, a mixed python/go repo, an
empty repo, and a file whose language has no parser). It reads no real project.

The reuse assertion is worth naming: a counter can lie, so the suite poisons the
prior index with a sentinel symbol on an unchanged blob and asserts the sentinel
**survives** into the next build. That is proof of copying rather than a claim
of it.
