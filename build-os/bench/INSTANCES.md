# The four frozen task instances — corpus v1.0.0, instance set v1.0.0

`build-os/metrics/task_corpus.md` (FROZEN) defines four task **shapes**. It does
not define **instances**. This file records the instances, and
`seed-bench-repo.sh` recreates them byte-for-byte.

**The corpus is not edited by this.** These instances *satisfy* the frozen
shapes; they do not change them. Corpus version stays **1.0.0**.

## The pinned state

```sh
build-os/bench/seed-bench-repo.sh /tmp/bench-repo
# tree_digest_sha256: bb52f7b5ebbfc918b005a17a594279557a6249f8a94ba9163dcd70d9462614c2
```

The digest is a sha256 over sorted `relpath<TAB>sha256(file)` lines. It is
independent of mtimes, inode order and absolute path — which is why the seed can
be pinned without a git commit (a commit would embed author/committer timestamps
and stop being reproducible).

**Determinism is proven, not asserted:** seeding twice into different directories
and running `diff -r` produces **no output**, and both report the same digest.

## The project

`unit-kit` — an intentionally ordinary, dependency-free Node project: four source
files, three test files, a real test command (`npm test` → `node test/run.js`),
and **no Gravito, no Build OS, no governance, no `CLAUDE.md`, no `.claude/`**.
The arm surface, if any, is installed at run time by `run-corpus.sh`, so the task
repo itself is arm-neutral.

**Seeded state: `TOTAL: 14 passed, 0 failed`.** The suite is **fully green** at
the seeded state. Nothing is failing on purpose — see `T2` below for why.

---

## `T1` — one-line comment fix

**Site:** `src/temperature.js`, the block comment above `toCelsius`.

```js
/**
 * Convert a Fahrenheit reading to Celsius.
 *
 * Worked example: toCelsius(32) returns 100.
 */
```

`toCelsius(32)` returns **0**. The claim is **arithmetically false and checkable
by executing the function** — it is not a style opinion, not a matter of taste,
and not a stale-but-arguable remark.

**This is the ONLY factually wrong comment in the seeded tree.** Every other
comment was written to be true, and `src/stats.js` deliberately carries **no**
comment describing `median`'s behaviour — a comment promising a correct median
would be a second false comment and would make this instance ambiguous.

**Done when:** the false claim is gone, behaviour is unchanged, and the suite
still reports **14 passed, 0 failed**.

## `T2` — single-file bugfix with a test

**Site:** `src/stats.js`, `median()`.

```js
const mid = Math.floor(sorted.length / 2);
return sorted[mid];
```

For even-length input this returns the upper-middle element instead of the mean
of the two middle elements: `median([1,2,3,4])` returns **3**; the correct value
is **2.5**. Real failure mode, one source file, defect already located (as the
corpus shape specifies).

**No test for it is pre-written — writing the failing test IS the task.** The
seeded suite exercises `median` on odd-length input only, so the defect is
**latent** and the seeded suite is green. That is the deliberate design: `T1`'s
"done when" requires an unchanged pass count, which is only well-defined if the
seeded suite is not already failing.

**Done when:** the added test **fails against the unfixed source** and passes
against the fixed one, and the full suite is green. The pre-fix half is
**executed** by the oracle, not taken on trust.

## `T3` — multi-file feature

**Site:** `SPEC-T3.md`, frozen in the tree.

Add `percentile(values, p)` using linear interpolation between closest ranks.
The spec carries five worked examples (`[1,2,3,4]` at p=50 → 2.5, p=0 → 1,
p=100 → 4, p=25 → 1.75; `[10,20,30]` at p=50 → 20) and three error cases.

**Because the worked examples are frozen in the tree before any run, the
acceptance criterion provably predates the output** — which is what
`COMPARISON_PROTOCOL.md` constant #5 requires.

Touches at least three files: `src/stats.js`, `src/index.js`,
`test/stats.test.js`, `README.md`.

## `T4` — three-way independent fan-out

**Site:** `TASKS-T4.md`, frozen in the tree, carrying its own disjoint
file-ownership manifest:

| item | owns (writes) | reads |
|---|---|---|
| A — currency | `src/currency.js`, `test/currency.test.js` | none |
| B — distance | `src/distance.js`, `test/distance.test.js` | none |
| C — duration | `src/duration.js`, `test/duration.test.js` | none |

**Independence is structural, not asserted.** No item writes `src/index.js` or
`README.md`, and the test runner discovers `test/*.test.js` automatically, so
there is no shared registration file and therefore no merge conflict to
manufacture. The oracle checks both halves: each item's behaviour, **and** that
no file outside the manifest was written.

---

## What the oracles are, and where they live

`build-os/bench/oracles/oracle.js` — **never copied into the seeded tree and
never named in a task prompt.** An acceptance criterion the agent can read is a
criterion it can satisfy literally. Every verdict is decidable by executing
code: no prose grading, no judgement call, no model self-report.

Proven non-vacuous before use — rejects the pristine seed on all four tasks,
accepts known-good solutions on all four, and rejects two distinct `T2` gaming
strategies (a test asserting the bug; a real fix whose added test also passes
pre-fix). See `BASELINE_LIMITS.md` §5 for the full table.

## Re-seeding in a future run

```sh
build-os/bench/seed-bench-repo.sh /tmp/bench-repo
build-os/bench/seed-bench-repo.sh --digest /tmp/bench-repo   # must print bb52f7b5...
```

**If the digest differs, the instances have drifted and the run is not comparable
to this baseline.** Changing an instance is a new instance-set version, by the
same logic as the corpus's own freezing rule: if `T3` is made easier and the
number goes up, that is not a speedup.
