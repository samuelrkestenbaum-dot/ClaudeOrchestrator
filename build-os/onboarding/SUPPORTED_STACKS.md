# Supported stacks — what the tooling can actually read

Derived from the shipped code, file by file: the indexer's extractors
(`build-os/compiler/index/extract.mjs`), its language classifier
(`.../index/classify.mjs`), and the intake's detection list
(`build-os/intake/repo-intake.sh`). Nothing below is aspirational.

There are **two separate questions**, and conflating them is the usual way this
gets overstated:

- **Can the intake recognise the project?** (manifest detection — broad)
- **Can the indexer read the code?** (symbol extraction — narrow)

A repository can pass the first and fail the second completely.

---

## 1. Symbol extraction — which files get read

**No extractor is an AST.** There is no TypeScript compiler, no tree-sitter, no
language server anywhere in this system. Every extractor is a character scanner
plus line regexes, and the code says so in its own header. Every file an
extractor touches is marked `partial: true` in the index, permanently, until a
real parser backend replaces it.

### Tier A — masked scanner + regexes

The most careful thing here. A real character scanner tracks line comments,
block comments, single/double/template strings and regex literals, and produces
two masked views of the source. That is what makes `// import { ghost } from
'./ghost'` invisible and `const re = /it's/` harmless.

| language | extensions | extractor |
|---|---|---|
| TypeScript | `.ts` `.tsx` `.mts` `.cts` | `js-ts-regex-v0` |
| JavaScript | `.js` `.jsx` `.mjs` `.cjs` | `js-ts-regex-v0` |
| Go | `.go` | `go-lines-v0` |

**Not extracted, even here:** class methods, object-literal members,
destructured bindings, overload signatures, ambient declarations in `.d.ts`,
multi-line `export { ... }` lists, and anything produced by a macro or
decorator. For Go: only top-level `func` / `type` / `var` / `const` at column
zero.

### Tier B — masked lines

| language | extensions | extractor |
|---|---|---|
| Python | `.py` `.pyi` | `python-lines-v0` |

Comments and string contents — including triple-quoted blocks — are masked,
then line regexes find `def`, `class`, and module-level `CONSTANT =`.
**Decorators, dynamically created definitions, and `__all__` are not read.**

### Tier C — naive strip + lines (the weakest tier, and it says so)

| language | extensions | extractor |
|---|---|---|
| Rust | `.rs` | `rust-lines-v0` |

Rust deliberately does **not** get the careful scanner: a lifetime (`'a`) looks
exactly like an opening string quote to a C-like scanner and would corrupt the
mask. The consequence, stated in the code: **a `use` statement inside a string
literal is over-reported.** Rust results are noisier than the other three, by
construction.

### Tier D — nothing

**Everything else gets `parser: 'none'`, `symbols: []`, and `partial: true`.**
The index will still *classify* these files (it knows the language id and
whether the path looks like source / test / config / doc / generated), but it
has **not read their contents** and it never claims to have.

Recognised-but-unread languages include: **shell, Ruby, Java, Kotlin, Swift, C,
C++, SQL, HTML, CSS/SCSS/Sass, Markdown, JSON, YAML, TOML, INI, Make,
Dockerfile** — and every extension not in the table above, whose lowercased
extension simply becomes its own language id rather than being guessed into a
known one.

**This is the honest headline: four language groups get symbols. Everything
else in your repository is a file the index can name and cannot read.**

### The number that matters

On the repository where this was first measured end-to-end, the index reported
**no_parser 390 of 415 files** and **files with a covering test 4 of 415**.
That is an internal measurement of one repository — it is not a benchmark and
it is not a prediction about yours — but it is the honest shape of the thing:
this tooling has been, so far, mostly blind by file count.

Because of that, there is a tool whose job is to say "the signal here is too
thin — do not use a compiled capsule at all, explore the repository the
ordinary way" (`recommended use state: bypass`). **That refusal is a feature**,
and it is applied mechanically to a stated threshold rather than by opinion.

---

## 2. Manifest detection — which projects the intake recognises

Broader than symbol extraction, and shallower.

| manifest at the repository root | recorded language | confidence |
|---|---|---|
| `package.json` (parseable) | node | HIGH |
| `package.json` (unparseable) | node | LOW, with an explicit assumption line |
| `pyproject.toml` / `requirements.txt` / `setup.py` | python | HIGH |
| `go.mod` | go | HIGH |
| `Cargo.toml` | rust | HIGH |
| `Gemfile` | ruby | HIGH |
| `pom.xml` | java (maven) | HIGH |
| `build.gradle` / `.kts` / `gradlew` | java/kotlin (gradle) | HIGH |
| none of the above | **`UNRECOGNIZED`, confidence NONE** | — |

Note the gap: **Ruby, Java and Kotlin projects are recognised as projects and
get no symbol extraction at all.** The intake will tell you what the project
is; the index will not tell you what is inside it.

### Framework hints — a fixed list of six

Only `react`, `vue`, `next`, `express`, `vitest`, `jest`, and only by
dependency *name* in `package.json`, at MEDIUM confidence. **Anything else goes
undetected** — Django, Rails, Spring, Angular, Svelte, FastAPI, and every other
framework are invisible to this detection.

### Command discovery — discovered vs guessed

| purpose | when it is DISCOVERED | when it is GUESSED |
|---|---|---|
| test | `scripts.test` in `package.json` | `npx vitest run` / `npx jest` (dependency present, no script); `pytest`; `go test ./...`; `cargo test`; `bundle exec rake test`; `mvn -q test`; `./gradlew test` |
| build | `scripts.build` | `go build ./...`; `cargo build` |
| lint | `scripts.lint` | — |
| typecheck | `scripts.typecheck` | — |

**Only node projects produce discovered commands.** Every other ecosystem's
commands are ecosystem convention supplied by the script, and the report says
so on every row. If your Python project uses `nox`, or your Go project has a
Makefile target, the intake will guess wrong — and will have labeled its guess
as a guess, which is the only reason that is survivable.

---

## 3. Structural limits that apply to every stack

- **Monorepos and workspaces are not analysed.** Only the repository root's
  manifests are consulted. A monorepo with ten packages is read as whatever its
  root manifest says.
- **Directory classification is a name heuristic.** A `config/` directory full
  of real source is misfiled; a hand-written file under `dist/` is called
  generated.
- **Test linkage is an import-or-basename heuristic, not executed coverage.**
  "This test covers this file" means the names or imports line up, not that
  anything was run.
- **The reference graph is a whole-word text match**, not resolved references.
  The index marks this `symbols_partial`.

---

## 4. What "supported" honestly means here

**It does not mean "works well on".** It means:

- **Tier A/B/C:** the index can list some declarations and imports, partially,
  by regex.
- **Tier D:** the index knows the file exists and what it is called.

Governance — routing, blocking unrouted changes, budgets, receipts, the audit
trail — is **language-independent** and works the same on all of it, because it
operates on tool calls, not on parsed code. If what you want is the audit
trail and the authority gate, your stack does not matter much. If what you want
is context compilation, the table above is the whole story, and for most
repositories it is a short one.
