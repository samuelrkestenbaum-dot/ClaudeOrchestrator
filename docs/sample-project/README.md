# sample-project — the repo the demo installs into

A deliberately tiny project so that nothing in
[`../DEMO.md`](../DEMO.md) is about *this* code. It is here so the demo has a
real repo to install into, a real test suite to run, and a real (small) defect to
fix in the `tiny` lane.

| file | what it is |
|---|---|
| `slugify.sh` | the "product" — turns a title into a URL slug |
| `check.sh` | its whole test suite: `ok()` / `no()`, a final `==== RESULT: N passed, M failed ====` line, non-zero exit on failure |

```bash
./slugify.sh "Hello World"   # -> hello-world
./check.sh                   # -> ==== RESULT: 3 passed, 0 failed ====
```

**It ships with one known defect**, which is the demo's `tiny`-lane task:
`./slugify.sh "Hello, World!"` prints `hello-world-` — trailing punctuation
leaves a trailing dash. `check.sh` does not cover that case yet, on purpose. The
demo writes the failing assertion first, watches it fail, then fixes it.

No dependencies beyond `bash` and `sed`. Nothing here reaches the network.
