# EXP-0002 — deterministic seed for the sustained-workload repository.
#
# Invoke via bash; this file is deliberately NOT executable:
#   bash seed-workload-repo.sh <target-dir>     seed (target must not exist, or be empty)
#   bash seed-workload-repo.sh --digest <dir>   print the tree digest of an existing tree
#   bash seed-workload-repo.sh --help
#
# WHAT IS SEEDED. An intentionally ORDINARY dependency-free Node application,
# "parcel-billing": dimensional-weight calculation, tiered pricing, invoicing,
# currency formatting, and a CLI that reads a JSON order file and prints an
# invoice. No Gravito, no Build OS, no CLAUDE.md, no .claude/. The arm surface
# (if any) is installed at RUN time by run-exp2-task.sh, not here, so the task
# repo itself is arm-neutral.
#
# DETERMINISM IS A HARD REQUIREMENT (same discipline as bench/seed-bench-repo.sh):
#   - no timestamps, no $RANDOM, no $$, no hostname, no uuid, no network
#   - every heredoc delimiter is QUOTED, so nothing in the payload expands
#   - the tree digest is printed to STDOUT, never written into the tree, so the
#     tree stays self-consistent and `diff -r` between two seeds is empty
# Proof recipe:  seed A; seed B; diff -r A B   ->  no output
#
# THE FROZEN TASK INSTANCES LIVE IN THIS TREE:
#   T1/T2 INSTANCE — lib/pricing.js. Its tier-table comment states that TIER
#     LIMITS ARE INCLUSIVE (a parcel of exactly 5 kg is a "small" parcel). The
#     code uses `<` where `<=` belongs on the small-tier line, so a parcel of
#     exactly 5.0 kg is charged the medium tier (15.00) instead of the small
#     tier (8.00). ONE line, realistic, and DELIBERATELY UNTESTED: the seeded
#     suite exercises tiers away from every boundary, so the seeded state is
#     fully GREEN and the defect is latent. Diagnosing it is T1; the failing
#     test + fix is T2. No other seeded comment disagrees with its code, so T1
#     resolves to exactly one site.
#   T3 INSTANCE — SPEC-T3.md, a precise discount-code feature spec with exact
#     worked examples and an exact error case. NOTE: the SAVE10 cap (50.00 USD)
#     is stated in the spec TEXT but exercised by NO worked example. That gap is
#     deliberate: harness/inject-t4.sh (run AFTER T3 closes) injects a
#     regression test derivable from the cap sentence, so a correct-but-narrow
#     T3 implementation fails it and making it pass is spec compliance.
#   T5 INSTANCE — FOLLOWUP-T5.md, a follow-up whose correct completion depends
#     on decisions made in T2–T4 (the established rounding policy and the
#     discount module architecture).
#
# THE SEEDED SUITE IS GREEN AT EXACTLY:  TOTAL: 19 passed, 0 failed
#
# THE GENERATED PROJECT IS NEVER COMMITTED. Seed it to a scratch directory.
# Only this script is committed.
#
# Exit: 0 ok, 2 on usage/precondition failure.
set -uo pipefail

HARNESS_VERSION="1.0.0"
WORKLOAD_NAME="parcel-billing"

die(){ printf 'seed-workload-repo: %s\n' "$*" >&2; exit 2; }

usage(){ sed -n '2,45p' "$0" | sed 's/^# \{0,1\}//'; }

# --------------------------------------------------------------- tree digest --
# A content-addressed identity for the tree: sha256 over sorted
# "relpath<TAB>sha256(file)" lines. Deterministic, and independent of mtimes,
# inode order and the absolute path the tree happens to live at. The work trees
# of EXP-0002 are NOT git repositories, so this digest — not a commit SHA — is
# the pinned-state identity every run record carries.
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

mkdir -p "$TARGET/lib" "$TARGET/bin" "$TARGET/test/fixtures"

# =============================================================================
# PROJECT SKELETON — intentionally ordinary
# =============================================================================

cat > "$TARGET/package.json" <<'EOF'
{
  "name": "parcel-billing",
  "version": "0.3.0",
  "description": "Parcel invoicing: dimensional weight, tiered pricing, and a small CLI.",
  "license": "MIT",
  "private": true,
  "main": "lib/invoice.js",
  "scripts": {
    "test": "node test/run.js"
  }
}
EOF

cat > "$TARGET/README.md" <<'EOF'
# parcel-billing

Small, dependency-free parcel invoicing: dimensional weight, tiered pricing,
currency rounding, and a CLI that turns a JSON order file into an invoice.

## Install

No dependencies. Node 18 or newer.

## Test

```sh
node test/run.js
```

## Use

```sh
node bin/cli.js path/to/order.json
```

An order file looks like `test/fixtures/order-a.json`.

## API

- `lib/weight.js` — `dimensionalWeightKg(l, w, h)`, `billableWeightKg(actualKg, dims)`
- `lib/pricing.js` — `tierFor(kg)`, `basePriceUsd(kg)`, `shippingUsd(zone)`
- `lib/invoice.js` — `buildInvoice(order)` builds line items and totals
- `lib/format.js` — `roundCurrency(x)`, `money(x)` currency helpers
EOF

# --------------------------------------------------------------------- lib ---

cat > "$TARGET/lib/weight.js" <<'EOF'
'use strict';

// Dimensional ("volumetric") weight. Carriers charge by whichever is greater:
// the actual weight, or the parcel's volume divided by a dimensional divisor.
// This project uses the common divisor of 5000 cm^3 per kg.

const DIM_DIVISOR_CM3_PER_KG = 5000;

function assertPositiveNumber(value, name) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value <= 0) {
    throw new TypeError(name + ' must be a positive finite number');
  }
}

// dimensionalWeightKg(50, 40, 25) is 10: 50*40*25 = 50000 cm^3 / 5000 = 10 kg.
function dimensionalWeightKg(lengthCm, widthCm, heightCm) {
  assertPositiveNumber(lengthCm, 'lengthCm');
  assertPositiveNumber(widthCm, 'widthCm');
  assertPositiveNumber(heightCm, 'heightCm');
  return (lengthCm * widthCm * heightCm) / DIM_DIVISOR_CM3_PER_KG;
}

// Billable weight is the greater of actual and dimensional weight.
function billableWeightKg(actualKg, dims) {
  assertPositiveNumber(actualKg, 'actualKg');
  if (!dims || typeof dims !== 'object') {
    throw new TypeError('dims must be an object with length, width, height');
  }
  return Math.max(actualKg, dimensionalWeightKg(dims.length, dims.width, dims.height));
}

module.exports = { dimensionalWeightKg, billableWeightKg, DIM_DIVISOR_CM3_PER_KG };
EOF

# THE T1/T2 INSTANCE LIVES IN THE FILE BELOW. The tier-table comment says the
# limits are INCLUSIVE; the small-tier line uses `<` where `<=` belongs, so a
# parcel of exactly 5 kg lands in the medium tier. The seeded tests never touch
# a boundary, so the suite is green and the defect is latent. DO NOT add a
# boundary test here — writing that failing test IS task T2.
cat > "$TARGET/lib/pricing.js" <<'EOF'
'use strict';

const { roundCurrency } = require('./format');

// Pricing tiers by billable weight.
//
// TIER LIMITS ARE INCLUSIVE: a parcel whose billable weight is exactly equal
// to a tier's upper limit belongs in that tier. A parcel of exactly 5 kg is a
// "small" parcel, and a parcel of exactly 20 kg is a "medium" parcel.
//
//   small    up to 5 kg inclusive            flat  8.00 USD
//   medium   over 5 kg, up to 20 kg incl.    flat 15.00 USD
//   large    over 20 kg                      30.00 USD + 1.10 USD per kg over 20
const SMALL_MAX_KG = 5;
const MEDIUM_MAX_KG = 20;

const SMALL_BASE_USD = 8;
const MEDIUM_BASE_USD = 15;
const LARGE_BASE_USD = 30;
const LARGE_PER_KG_USD = 1.1;

function tierFor(billableKg) {
  if (typeof billableKg !== 'number' || !Number.isFinite(billableKg) || billableKg <= 0) {
    throw new TypeError('billableKg must be a positive finite number');
  }
  if (billableKg < SMALL_MAX_KG) return 'small';
  if (billableKg <= MEDIUM_MAX_KG) return 'medium';
  return 'large';
}

function basePriceUsd(billableKg) {
  const tier = tierFor(billableKg);
  if (tier === 'small') return SMALL_BASE_USD;
  if (tier === 'medium') return MEDIUM_BASE_USD;
  return roundCurrency(LARGE_BASE_USD + LARGE_PER_KG_USD * (billableKg - MEDIUM_MAX_KG));
}

// Flat shipping price per destination zone.
const SHIPPING_USD = {
  domestic: 4.5,
  regional: 9,
  international: 22,
};

function shippingUsd(zone) {
  if (!Object.prototype.hasOwnProperty.call(SHIPPING_USD, zone)) {
    throw new TypeError('unknown shipping zone: ' + zone);
  }
  return SHIPPING_USD[zone];
}

module.exports = { tierFor, basePriceUsd, shippingUsd };
EOF

cat > "$TARGET/lib/format.js" <<'EOF'
'use strict';

// Currency helpers. THE PROJECT'S ROUNDING POLICY LIVES HERE AND ONLY HERE:
// every monetary amount is rounded half-up to 2 decimal places via
// roundCurrency, and printed via money. Nothing else in the project may
// re-implement rounding.

function roundCurrency(value) {
  if (typeof value !== 'number' || !Number.isFinite(value)) {
    throw new TypeError('roundCurrency requires a finite number');
  }
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

function money(value) {
  return roundCurrency(value).toFixed(2);
}

module.exports = { roundCurrency, money };
EOF

cat > "$TARGET/lib/invoice.js" <<'EOF'
'use strict';

const { billableWeightKg } = require('./weight');
const { tierFor, basePriceUsd, shippingUsd } = require('./pricing');
const { roundCurrency } = require('./format');

// Tax is charged on the parcel subtotal only; shipping is never taxed.
const TAX_RATE = 0.07;

// buildInvoice(order) -> {
//   id,
//   lines: [{ description, quantity, billableKg, tier, amountUsd }],
//   shippingZone, shippingUsd,
//   subtotalUsd, taxUsd, totalUsd
// }
//
// order = {
//   id: string,
//   zone: 'domestic' | 'regional' | 'international',
//   items: [{ description, quantity?, weightKg, dimensionsCm: { length, width, height } }]
// }
function buildInvoice(order) {
  if (!order || typeof order !== 'object') {
    throw new TypeError('buildInvoice requires an order object');
  }
  if (typeof order.id !== 'string' || order.id === '') {
    throw new TypeError('order.id must be a non-empty string');
  }
  if (!Array.isArray(order.items) || order.items.length === 0) {
    throw new TypeError('order.items must be a non-empty array');
  }

  const lines = [];
  let subtotal = 0;
  for (const item of order.items) {
    const quantity = item.quantity === undefined ? 1 : item.quantity;
    if (!Number.isInteger(quantity) || quantity <= 0) {
      throw new TypeError('item.quantity must be a positive integer');
    }
    const kg = billableWeightKg(item.weightKg, item.dimensionsCm);
    const amountUsd = roundCurrency(quantity * basePriceUsd(kg));
    lines.push({
      description: item.description,
      quantity,
      billableKg: kg,
      tier: tierFor(kg),
      amountUsd,
    });
    subtotal += amountUsd;
  }

  const subtotalUsd = roundCurrency(subtotal);
  const shipUsd = shippingUsd(order.zone);
  const taxUsd = roundCurrency(TAX_RATE * subtotalUsd);
  const totalUsd = roundCurrency(subtotalUsd + shipUsd + taxUsd);

  return {
    id: order.id,
    lines,
    shippingZone: order.zone,
    shippingUsd: shipUsd,
    subtotalUsd,
    taxUsd,
    totalUsd,
  };
}

module.exports = { buildInvoice, TAX_RATE };
EOF

# --------------------------------------------------------------------- bin ---

cat > "$TARGET/bin/cli.js" <<'EOF'
'use strict';

// parcel-billing CLI: read a JSON order file, print an invoice.
//   node bin/cli.js <order.json>

const fs = require('fs');
const { buildInvoice } = require('../lib/invoice');
const { money } = require('../lib/format');

function fail(message, code) {
  process.stderr.write('parcel-billing: ' + message + '\n');
  process.exit(code);
}

function main(argv) {
  if (argv.length !== 1) {
    process.stderr.write('usage: node bin/cli.js <order.json>\n');
    process.exit(1);
  }
  const file = argv[0];

  let order;
  try {
    order = JSON.parse(fs.readFileSync(file, 'utf8'));
  } catch (e) {
    fail('cannot read order file: ' + file, 1);
  }

  let invoice;
  try {
    invoice = buildInvoice(order);
  } catch (e) {
    fail('invalid order: ' + e.message, 1);
  }

  const out = [];
  out.push('INVOICE ' + invoice.id);
  for (const line of invoice.lines) {
    out.push(
      'ITEM ' + line.description +
      ' qty=' + line.quantity +
      ' billable_kg=' + line.billableKg.toFixed(2) +
      ' tier=' + line.tier +
      ' amount=' + money(line.amountUsd)
    );
  }
  out.push('SHIPPING zone=' + invoice.shippingZone + ' amount=' + money(invoice.shippingUsd));
  out.push('SUBTOTAL ' + money(invoice.subtotalUsd));
  out.push('TAX ' + money(invoice.taxUsd));
  out.push('TOTAL ' + money(invoice.totalUsd));
  process.stdout.write(out.join('\n') + '\n');
}

main(process.argv.slice(2));
EOF

# -------------------------------------------------------------------- test ---
# A hand-rolled runner: the project must have a REAL test command that works
# with no network and no install step. Its last line is machine-readable:
#   TOTAL: <passed> passed, <failed> failed
# Exit status is 0 iff failed == 0.
#
# DISCOVERY IS `test/*.js` EXCEPT run.js (not `*.test.js`): this is what lets
# the injected test/regression-t4.js be picked up with no registration step.
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
    console.log('  FAIL ' + name + ' — expected ' + JSON.stringify(expected) + ', got ' + JSON.stringify(actual));
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
  .filter((f) => f.endsWith('.js') && f !== 'run.js')
  .sort();

for (const f of files) {
  console.log('== ' + f + ' ==');
  require(path.join(dir, f))(api);
}

console.log('TOTAL: ' + passed + ' passed, ' + failed + ' failed');
process.exit(failed === 0 ? 0 : 1);
EOF

cat > "$TARGET/test/weight.test.js" <<'EOF'
'use strict';

const { dimensionalWeightKg, billableWeightKg } = require('../lib/weight');

module.exports = function ({ assertEqual, assertThrows }) {
  assertEqual(dimensionalWeightKg(50, 40, 25), 10, 'dimensional weight of 50x40x25 cm is 10 kg');
  assertEqual(
    billableWeightKg(3, { length: 10, width: 10, height: 10 }),
    3,
    'actual weight dominates a small box'
  );
  assertEqual(
    billableWeightKg(0.1, { length: 50, width: 40, height: 25 }),
    10,
    'dimensional weight dominates a light bulky box'
  );
  assertThrows(
    () => billableWeightKg(-1, { length: 10, width: 10, height: 10 }),
    'negative actual weight throws'
  );
};
EOF

# NOTE (seeder-side only): tiers are exercised AWAY from every boundary (2, 12
# and 30 kg — never 5 or 20). The boundary defect is the T1/T2 instance and is
# deliberately left uncovered so the seeded suite is green.
cat > "$TARGET/test/pricing.test.js" <<'EOF'
'use strict';

const { tierFor, basePriceUsd, shippingUsd } = require('../lib/pricing');

module.exports = function ({ assertEqual, assertThrows }) {
  assertEqual(tierFor(2), 'small', 'a 2 kg parcel is small');
  assertEqual(tierFor(12), 'medium', 'a 12 kg parcel is medium');
  assertEqual(tierFor(30), 'large', 'a 30 kg parcel is large');
  assertEqual(basePriceUsd(30), 41, 'a 30 kg parcel costs 30 + 1.10 x 10 = 41');
  assertEqual(shippingUsd('domestic'), 4.5, 'domestic shipping is 4.50');
  assertThrows(() => shippingUsd('moon'), 'an unknown zone throws');
};
EOF

cat > "$TARGET/test/format.test.js" <<'EOF'
'use strict';

const { roundCurrency, money } = require('../lib/format');

module.exports = function ({ assertEqual, assertThrows }) {
  assertEqual(roundCurrency(1.005), 1.01, 'roundCurrency rounds half up');
  assertEqual(money(4.5), '4.50', 'money pads to two decimals');
  assertThrows(() => money('x'), 'money rejects non-numbers');
};
EOF

cat > "$TARGET/test/invoice.test.js" <<'EOF'
'use strict';

const { buildInvoice } = require('../lib/invoice');

module.exports = function ({ assertEqual }) {
  const order = {
    id: 'ORD-A',
    zone: 'domestic',
    items: [
      { description: 'Books', quantity: 1, weightKg: 2, dimensionsCm: { length: 20, width: 15, height: 10 } },
      { description: 'Monitor', quantity: 1, weightKg: 7, dimensionsCm: { length: 60, width: 45, height: 20 } },
    ],
  };
  const invoice = buildInvoice(order);
  assertEqual(invoice.lines.length, 2, 'invoice has one line per item');
  assertEqual(invoice.subtotalUsd, 23, 'subtotal is 8.00 + 15.00 = 23.00');
  assertEqual(invoice.taxUsd, 1.61, 'tax is 7% of the parcel subtotal');
  assertEqual(invoice.totalUsd, 29.11, 'total is subtotal + shipping + tax');
};
EOF

cat > "$TARGET/test/cli.test.js" <<'EOF'
'use strict';

const path = require('path');
const { execFileSync } = require('child_process');

module.exports = function ({ assertEqual }) {
  const cli = path.join(__dirname, '..', 'bin', 'cli.js');
  const fixture = path.join(__dirname, 'fixtures', 'order-a.json');

  const out = execFileSync('node', [cli, fixture], { encoding: 'utf8' });
  const expected = [
    'INVOICE ORD-A',
    'ITEM Books qty=1 billable_kg=2.00 tier=small amount=8.00',
    'ITEM Monitor qty=1 billable_kg=10.80 tier=medium amount=15.00',
    'SHIPPING zone=domestic amount=4.50',
    'SUBTOTAL 23.00',
    'TAX 1.61',
    'TOTAL 29.11',
    '',
  ].join('\n');
  assertEqual(out, expected, 'cli prints the ORD-A invoice exactly');

  let code = 0;
  try {
    execFileSync('node', [cli, path.join(__dirname, 'fixtures', 'no-such-order.json')], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch (e) {
    code = e.status;
  }
  assertEqual(code, 1, 'a missing order file exits 1');
};
EOF

cat > "$TARGET/test/fixtures/order-a.json" <<'EOF'
{
  "id": "ORD-A",
  "zone": "domestic",
  "items": [
    { "description": "Books", "quantity": 1, "weightKg": 2, "dimensionsCm": { "length": 20, "width": 15, "height": 10 } },
    { "description": "Monitor", "quantity": 1, "weightKg": 7, "dimensionsCm": { "length": 60, "width": 45, "height": 20 } }
  ]
}
EOF

# =============================================================================
# T3 AND T5 INSTANCES — request documents frozen into the tree, so every run
# starts from an identical state rather than from a prompt someone retypes.
# =============================================================================

cat > "$TARGET/SPEC-T3.md" <<'EOF'
# Feature request: discount codes

An order JSON may carry an optional string field `discountCode`. Implement it.

## Recognized codes (exact, case-sensitive)

- `SAVE10` — 10% off the parcel subtotal before tax, **capped at 50.00 USD**:
  `discountUsd = min(roundCurrency(0.10 * subtotalUsd), 50)`. Tax is then
  charged on the discounted subtotal:
  `taxableUsd = roundCurrency(subtotalUsd - discountUsd)`,
  `taxUsd = roundCurrency(0.07 * taxableUsd)`,
  `totalUsd = roundCurrency(taxableUsd + shippingUsd + taxUsd)`.
  The shipping charge is unchanged.
- `FREESHIP` — the shipping line is zeroed: shipping is charged at 0.00 and the
  discount amount shown is the zone's normal shipping price. The subtotal and
  tax are unaffected (`taxUsd = roundCurrency(0.07 * subtotalUsd)`), so
  `totalUsd = roundCurrency(subtotalUsd + taxUsd)`.

All rounding uses the project's existing `roundCurrency` / `money` helpers in
`lib/format.js`. Do not re-implement rounding.

## Output

When a discount applies, the CLI prints exactly one extra line between
`SUBTOTAL` and `TAX`:

```
DISCOUNT code=<CODE> amount=<amount>
```

with `<amount>` money-formatted (two decimals). An order without a
`discountCode` field must produce byte-identical output to today's behaviour.

## Error case

If `discountCode` is present but is not exactly one of the recognized codes
(wrong case, empty string, unknown word — anything else), the order is
rejected: the CLI prints exactly

```
parcel-billing: unknown discount code: <CODE>
```

to stderr (with `<CODE>` the raw value), prints nothing to stdout, and exits
with status **2**.

## Architecture

The discount rules (the code table and the amount computation) live in a new
`lib/discount.js` module. `lib/invoice.js` and `bin/cli.js` use it — at least
those three files change. Add tests covering the worked examples and the error
case; full suite green (`node test/run.js`) when done.

## Worked example 1 — SAVE10

Order file:

```json
{
  "id": "ORD-B",
  "zone": "domestic",
  "discountCode": "SAVE10",
  "items": [
    { "description": "Books", "quantity": 1, "weightKg": 2, "dimensionsCm": { "length": 20, "width": 15, "height": 10 } },
    { "description": "Monitor", "quantity": 1, "weightKg": 7, "dimensionsCm": { "length": 60, "width": 45, "height": 20 } }
  ]
}
```

Exact expected stdout (exit 0):

```
INVOICE ORD-B
ITEM Books qty=1 billable_kg=2.00 tier=small amount=8.00
ITEM Monitor qty=1 billable_kg=10.80 tier=medium amount=15.00
SHIPPING zone=domestic amount=4.50
SUBTOTAL 23.00
DISCOUNT code=SAVE10 amount=2.30
TAX 1.45
TOTAL 26.65
```

(Working: discount = min(roundCurrency(2.30), 50) = 2.30; taxable = 20.70;
tax = roundCurrency(1.449) = 1.45; total = 20.70 + 4.50 + 1.45 = 26.65.)

## Worked example 2 — FREESHIP

Order file:

```json
{
  "id": "ORD-C",
  "zone": "international",
  "discountCode": "FREESHIP",
  "items": [
    { "description": "Desk", "quantity": 1, "weightKg": 30, "dimensionsCm": { "length": 100, "width": 60, "height": 10 } }
  ]
}
```

Exact expected stdout (exit 0):

```
INVOICE ORD-C
ITEM Desk qty=1 billable_kg=30.00 tier=large amount=41.00
SHIPPING zone=international amount=0.00
SUBTOTAL 41.00
DISCOUNT code=FREESHIP amount=22.00
TAX 2.87
TOTAL 43.87
```

(Working: shipping international 22.00 zeroed; tax = roundCurrency(2.87) on
the full 41.00 subtotal; total = 41.00 + 2.87 = 43.87.)

## Worked example 3 — unknown code

Any order whose `discountCode` is `"BOGUS"` prints nothing to stdout, prints
exactly this one line to stderr, and exits with status 2:

```
parcel-billing: unknown discount code: BOGUS
```
EOF

cat > "$TARGET/FOLLOWUP-T5.md" <<'EOF'
# Follow-up: order summary mode

Add a `--summary` flag to `bin/cli.js`, printing per-order net totals after
discounts, using the same rounding policy and discount module the project
already established; add tests consistent with the existing suites.

## Behaviour

```
node bin/cli.js --summary <order-file> [<order-file> ...]
```

For each order file, in argument order, build the invoice exactly as the
normal invoice path does — using the discount module and the rounding policy
this project has already established (do not re-implement discount or rounding
rules inside the CLI) — and print exactly one line per order:

```
SUMMARY <id> total=<total>
```

where `<total>` is the order's grand total after any discount, formatted with
the project's money formatting. After the last order, print exactly:

```
SUMMARY TOTAL orders=<n> net=<net>
```

where `<n>` is the number of order files and `<net>` is the project's currency
rounding applied to the sum of the per-order totals, money-formatted.

Orders are processed sequentially. An order with an unknown discount code
fails exactly as the normal invoice path fails (same stderr message, exit
status 2), immediately, without processing later files. An unreadable or
invalid order file fails as the normal path does (exit status 1).

## Worked example

Using SPEC-T3.md's two worked-example orders as `order-b.json` and
`order-c.json`:

```
node bin/cli.js --summary order-b.json order-c.json
```

Exact expected stdout (exit 0):

```
SUMMARY ORD-B total=26.65
SUMMARY ORD-C total=43.87
SUMMARY TOTAL orders=2 net=70.52
```

## Done when

Tests consistent with the existing suites cover the new flag, and the full
suite is green (`node test/run.js`).
EOF

# ------------------------------------------------------------------ report ---
# Printed to STDOUT ONLY. Writing this into the tree would make the tree
# contain a hash of itself, which cannot be made self-consistent.
printf 'seeded: %s\n' "$TARGET"
printf 'workload: %s\n' "$WORKLOAD_NAME"
printf 'harness_version: %s\n' "$HARNESS_VERSION"
printf 'tree_digest_sha256: %s\n' "$(tree_digest "$TARGET")"
exit 0
