#!/usr/bin/env bash
# Build OS — deterministic seed for the fixed-task-corpus bench repository.
#
# WHY THIS EXISTS. build-os/metrics/task_corpus.md (v1.0.0, FROZEN) defines four
# task SHAPES and no task INSTANCES. "A repository with at least one code comment
# containing a factual error" does not say WHICH comment. A run against instances
# chosen on the day cannot be reproduced six months later, because by then the
# comment is fixed and the defect is gone. This script is the missing half: it
# freezes four concrete instances, one per shape, into a tree that can be
# recreated byte-for-byte on any machine, at any time.
#
# IT DOES NOT EDIT THE CORPUS. task_corpus.md is frozen and its own freezing rule
# forbids in-place edits. These instances SATISFY the existing shapes; they do
# not change them. Corpus version remains 1.0.0.
#
# DETERMINISM IS THE WHOLE POINT AND IT IS A HARD REQUIREMENT:
#   - no timestamps, no $RANDOM, no $$, no hostname, no uuid, no network
#   - every heredoc delimiter is QUOTED, so nothing in the payload expands
#   - any date appearing in content is a fixed literal
#   - the tree digest is printed to STDOUT, never written into the tree, so the
#     tree stays self-consistent and `diff -r` between two seeds is empty
# Proof recipe:  seed A; seed B; diff -r A B   ->  no output
#
# WHAT IS SEEDED. An intentionally ORDINARY small Node project: a few source
# files, a real dependency-free test command, and no Gravito, no Build OS, no
# governance, no CLAUDE.md, no .claude/. The arm surface (if any) is installed at
# RUN time by run-corpus.sh, not here, so the task repo itself is arm-neutral.
#
# THE GENERATED PROJECT IS NEVER COMMITTED. Seed it to /tmp. Only this script is
# committed.
#
# Usage:
#   seed-bench-repo.sh <target-dir>     seed (target must not exist, or be empty)
#   seed-bench-repo.sh --digest <dir>   print the tree digest of an existing tree
#   seed-bench-repo.sh --help
#
# Exit: 0 ok, 2 on usage/precondition failure.
set -uo pipefail

CORPUS_VERSION="1.0.0"
INSTANCE_VERSION="1.0.0"

die(){ printf 'seed-bench-repo: %s\n' "$*" >&2; exit 2; }

usage(){ sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'; }

# --------------------------------------------------------------- tree digest --
# A content-addressed identity for the seeded tree: sha256 over sorted
# "relpath<TAB>sha256(file)" lines. Deterministic, and independent of mtimes,
# inode order and the absolute path the tree happens to live at. This is the
# "pinned state" the protocol's constant #2 asks for, without needing a git
# commit (a commit would embed author/committer timestamps and stop being
# reproducible unless every date were also pinned).
tree_digest(){
  local root="$1"
  [ -d "$root" ] || die "not a directory: $root"
  ( cd "$root" && find . -type f ! -path './.git/*' -print0 \
      | LC_ALL=C sort -z \
      | while IFS= read -r -d '' f; do
          printf '%s\t%s\n' "${f#./}" "$(sha256sum "$f" | cut -d' ' -f1)"
        done \
      | sha256sum | cut -d' ' -f1 )
}

case "${1:-}" in
  ''|-h|--help) usage; exit 0 ;;
  --digest) [ "$#" -eq 2 ] || die "--digest needs a directory"; tree_digest "$2"; exit 0 ;;
esac

TARGET="$1"
[ -e "$TARGET" ] && [ -n "$(ls -A "$TARGET" 2>/dev/null)" ] && die "target exists and is not empty: $TARGET"
mkdir -p "$TARGET" || die "cannot create $TARGET"
TARGET="$(cd "$TARGET" && pwd)"

mkdir -p "$TARGET/src" "$TARGET/test"

# =============================================================================
# PROJECT SKELETON — intentionally ordinary
# =============================================================================

cat > "$TARGET/package.json" <<'EOF'
{
  "name": "unit-kit",
  "version": "0.4.0",
  "description": "Small unit-conversion and descriptive-statistics helpers.",
  "license": "MIT",
  "private": true,
  "main": "src/index.js",
  "scripts": {
    "test": "node test/run.js"
  }
}
EOF

cat > "$TARGET/README.md" <<'EOF'
# unit-kit

Small, dependency-free helpers for unit conversion and descriptive statistics.

## Install

No dependencies. Node 18 or newer.

## Test

```sh
npm test
```

## API

- `toCelsius(fahrenheit)` — convert a Fahrenheit reading to Celsius.
- `toFahrenheit(celsius)` — convert a Celsius reading to Fahrenheit.
- `mean(values)` — arithmetic mean of a non-empty array of numbers.
- `median(values)` — median of a non-empty array of numbers.
- `formatNumber(value, places)` — fixed-point string with `places` decimals.
- `formatRange(low, high, places)` — a `"low–high"` string.
EOF

# --------------------------------------------------------------------- src ---

# T1 INSTANCE LIVES HERE. The block comment below contains exactly one
# objectively false statement: toCelsius(32) returns 0, not 100. It is an
# arithmetic claim, checkable by executing the function — not a style opinion.
# Every other comment in this seeded tree is factually correct, so the corpus's
# "at least one code comment containing a factual error" resolves to EXACTLY
# ONE site.
cat > "$TARGET/src/temperature.js" <<'EOF'
'use strict';

/**
 * Convert a Fahrenheit reading to Celsius.
 *
 * Worked example: toCelsius(32) returns 100.
 */
function toCelsius(fahrenheit) {
  return ((fahrenheit - 32) * 5) / 9;
}

/**
 * Convert a Celsius reading to Fahrenheit.
 */
function toFahrenheit(celsius) {
  return (celsius * 9) / 5 + 32;
}

module.exports = { toCelsius, toFahrenheit };
EOF

# T2 INSTANCE LIVES HERE. median() takes the upper-middle element for
# even-length input instead of averaging the two middle elements:
# median([1,2,3,4]) returns 3, and the correct value is 2.5.
#
# THE DEFECT IS DELIBERATELY UNTESTED. The seeded suite exercises median only on
# odd-length input, so the bug is latent and the suite is fully green at the
# seeded state. Writing the failing test IS the task, per the corpus, so no test
# for it is pre-written here.
#
# There is deliberately NO comment describing median's behaviour, because a
# comment promising a correct median would be a SECOND factually-wrong comment
# and would make the T1 instance ambiguous.
cat > "$TARGET/src/stats.js" <<'EOF'
'use strict';

// Descriptive statistics helpers. Every function requires a non-empty array.

function mean(values) {
  if (!Array.isArray(values) || values.length === 0) {
    throw new TypeError('mean requires a non-empty array');
  }
  let total = 0;
  for (const v of values) total += v;
  return total / values.length;
}

function median(values) {
  if (!Array.isArray(values) || values.length === 0) {
    throw new TypeError('median requires a non-empty array');
  }
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return sorted[mid];
}

module.exports = { mean, median };
EOF

cat > "$TARGET/src/format.js" <<'EOF'
'use strict';

// String formatting helpers. `places` is the number of decimal places.

function formatNumber(value, places) {
  if (typeof value !== 'number' || Number.isNaN(value)) {
    throw new TypeError('formatNumber requires a number');
  }
  return value.toFixed(places);
}

function formatRange(low, high, places) {
  return formatNumber(low, places) + '–' + formatNumber(high, places);
}

module.exports = { formatNumber, formatRange };
EOF

cat > "$TARGET/src/index.js" <<'EOF'
'use strict';

const { toCelsius, toFahrenheit } = require('./temperature');
const { mean, median } = require('./stats');
const { formatNumber, formatRange } = require('./format');

module.exports = {
  toCelsius,
  toFahrenheit,
  mean,
  median,
  formatNumber,
  formatRange,
};
EOF

# -------------------------------------------------------------------- test ---
# A hand-rolled runner, because the project must have a REAL test command that
# works with no network and no install step. Its last line is machine-readable:
#   TOTAL: <passed> passed, <failed> failed
# Exit status is 0 iff failed == 0.
cat > "$TARGET/test/run.js" <<'EOF'
'use strict';

const fs = require('fs');
const path = require('path');

let passed = 0;
let failed = 0;

function assertEqual(actual, expected, name) {
  if (Object.is(actual, expected)) {
    passed += 1;
    console.log('  ok   ' + name);
  } else {
    failed += 1;
    console.log('  FAIL ' + name + ' — expected ' + String(expected) + ', got ' + String(actual));
  }
}

function assertThrows(fn, name) {
  try {
    fn();
    failed += 1;
    console.log('  FAIL ' + name + ' — expected a throw, got none');
  } catch (e) {
    passed += 1;
    console.log('  ok   ' + name);
  }
}

const api = { assertEqual, assertThrows };

const dir = __dirname;
const files = fs
  .readdirSync(dir)
  .filter((f) => f.endsWith('.test.js'))
  .sort();

for (const f of files) {
  console.log('== ' + f + ' ==');
  require(path.join(dir, f))(api);
}

console.log('TOTAL: ' + passed + ' passed, ' + failed + ' failed');
process.exit(failed === 0 ? 0 : 1);
EOF

cat > "$TARGET/test/temperature.test.js" <<'EOF'
'use strict';

const { toCelsius, toFahrenheit } = require('../src/temperature');

module.exports = function ({ assertEqual }) {
  assertEqual(toCelsius(212), 100, 'toCelsius(212) is 100');
  assertEqual(toCelsius(32), 0, 'toCelsius(32) is 0');
  assertEqual(toFahrenheit(100), 212, 'toFahrenheit(100) is 212');
  assertEqual(toFahrenheit(0), 32, 'toFahrenheit(0) is 32');
};
EOF

# NOTE: median is exercised on ODD-LENGTH input only. The even-length defect is
# the T2 instance and is deliberately left uncovered.
cat > "$TARGET/test/stats.test.js" <<'EOF'
'use strict';

const { mean, median } = require('../src/stats');

module.exports = function ({ assertEqual, assertThrows }) {
  assertEqual(mean([2, 4, 6]), 4, 'mean of [2,4,6] is 4');
  assertEqual(mean([5]), 5, 'mean of [5] is 5');
  assertThrows(() => mean([]), 'mean of [] throws');
  assertEqual(median([3, 1, 2]), 2, 'median of [3,1,2] is 2');
  assertEqual(median([9]), 9, 'median of [9] is 9');
  assertThrows(() => median([]), 'median of [] throws');
};
EOF

cat > "$TARGET/test/format.test.js" <<'EOF'
'use strict';

const { formatNumber, formatRange } = require('../src/format');

module.exports = function ({ assertEqual, assertThrows }) {
  assertEqual(formatNumber(1.005, 1), '1.0', 'formatNumber(1.005, 1) is "1.0"');
  assertEqual(formatNumber(2, 2), '2.00', 'formatNumber(2, 2) is "2.00"');
  assertThrows(() => formatNumber('x', 2), 'formatNumber("x", 2) throws');
  assertEqual(formatRange(1, 2, 1), '1.0–2.0', 'formatRange(1, 2, 1) joins with an en dash');
};
EOF

# =============================================================================
# T3 AND T4 INSTANCES — written into the tree as request documents, so a future
# run starts from the identical state rather than from a prompt someone retypes.
# =============================================================================

cat > "$TARGET/SPEC-T3.md" <<'EOF'
# Feature request: percentile()

Add a `percentile(values, p)` helper to unit-kit.

## Behaviour

`percentile(values, p)` returns the linearly-interpolated percentile of a
non-empty array of numbers, where `p` is in the range 0 to 100 inclusive.

Use the standard linear-interpolation-between-closest-ranks method:

1. Sort the values ascending.
2. Compute the rank `r = (p / 100) * (n - 1)`, where `n` is the number of values.
3. Let `lo = Math.floor(r)` and `hi = Math.ceil(r)`.
4. If `lo === hi`, return `sorted[lo]`.
5. Otherwise return `sorted[lo] + (r - lo) * (sorted[hi] - sorted[lo])`.

## Worked examples

- `percentile([1, 2, 3, 4], 50)` is `2.5`
- `percentile([1, 2, 3, 4], 0)` is `1`
- `percentile([1, 2, 3, 4], 100)` is `4`
- `percentile([1, 2, 3, 4], 25)` is `1.75`
- `percentile([10, 20, 30], 50)` is `20`

## Errors

Throw a `TypeError` if `values` is not a non-empty array, or if `p` is not a
number in the range 0 to 100 inclusive.

## Scope

This touches at least three files:

- `src/stats.js` — the implementation
- `src/index.js` — the export
- `test/stats.test.js` — tests, including the worked examples above
- `README.md` — one line documenting the new helper in the API list
EOF

cat > "$TARGET/TASKS-T4.md" <<'EOF'
# Three independent work items

These three items are genuinely independent: no file is written by more than one
of them. The file-ownership manifest below is disjoint by construction, and each
item may be completed without reading the other two.

## File-ownership manifest

| item | owns (writes) | reads |
|---|---|---|
| A — currency | `src/currency.js`, `test/currency.test.js` | none |
| B — distance | `src/distance.js`, `test/distance.test.js` | none |
| C — duration | `src/duration.js`, `test/duration.test.js` | none |

No item writes `src/index.js`, `README.md`, or any file owned by another item.
The test runner discovers `test/*.test.js` automatically, so no registration
step is needed and there is no shared file to merge.

Each test file exports a single function taking `{ assertEqual, assertThrows }`,
exactly like the existing test files.

## Item A — currency

Create `src/currency.js` exporting `toMinorUnits(amount, exponent)` and
`fromMinorUnits(minor, exponent)`.

- `toMinorUnits(12.34, 2)` is `1234` — multiply and round to the nearest integer.
- `fromMinorUnits(1234, 2)` is `12.34` — divide, with no rounding.
- `toMinorUnits(5, 0)` is `5`.
- Throw a `TypeError` if `amount` is not a number or `exponent` is not a
  non-negative integer.

## Item B — distance

Create `src/distance.js` exporting `milesToKm(miles)` and `kmToMiles(km)`.

- Use the exact factor `1.609344` kilometres per mile.
- `milesToKm(1)` is `1.609344`.
- `kmToMiles(1.609344)` is `1`.
- Throw a `TypeError` on non-number input.

## Item C — duration

Create `src/duration.js` exporting `toSeconds({ hours, minutes, seconds })` and
`formatDuration(totalSeconds)`.

- `toSeconds({ hours: 1, minutes: 2, seconds: 3 })` is `3723`. Missing fields
  default to 0.
- `formatDuration(3723)` is `"01:02:03"` — zero-padded to two digits per field.
- `formatDuration(0)` is `"00:00:00"`.
- Throw a `TypeError` if `totalSeconds` is negative or not a number.
EOF

# ------------------------------------------------------------------ report ---
# Printed to STDOUT ONLY. Writing this into the tree would make the tree contain
# a hash of itself, which cannot be made self-consistent.
printf 'seeded: %s\n' "$TARGET"
printf 'corpus_version: %s\n' "$CORPUS_VERSION"
printf 'instance_version: %s\n' "$INSTANCE_VERSION"
printf 'tree_digest_sha256: %s\n' "$(tree_digest "$TARGET")"
exit 0
