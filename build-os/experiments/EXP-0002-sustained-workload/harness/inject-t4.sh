# EXP-0002 — inject the T4 regression test into an arm's work tree.
#
# Invoke via bash; this file is deliberately NOT executable:
#   bash inject-t4.sh <repo-dir>
#
# WHEN. AFTER T3 closes and BEFORE T4's session starts, identically in both
# arms. run-exp2-task.sh --task T4 runs this automatically when the file is
# absent, and records that it did.
#
# WHAT IT INJECTS. test/regression-t4.js — a LEGITIMATE failing test derivable
# from SPEC-T3.md's own text, not a trick:
#
#   SPEC-T3.md states, in prose:  "SAVE10 — 10% off the parcel subtotal before
#   tax, capped at 50.00 USD: discountUsd = min(roundCurrency(0.10 *
#   subtotalUsd), 50)."
#
#   None of the spec's WORKED EXAMPLES exercises the cap (both example orders
#   have subtotals far below 500 USD). A correct-but-narrow T3 implementation —
#   one that reproduces every worked example exactly but skips the cap clause —
#   passes the T3 oracle and FAILS this test. Making it pass is therefore SPEC
#   COMPLIANCE, not guessing: the expected values below follow mechanically
#   from the spec's own formulas for an 800.00 subtotal.
#
#   Expected working, from the spec's formulas:
#     item: 720 kg, large tier -> 30 + 1.10 x 700 = 800.00 subtotal
#     discount = min(roundCurrency(80.00), 50) = 50.00
#     taxable  = roundCurrency(800.00 - 50.00) = 750.00
#     tax      = roundCurrency(0.07 x 750.00)  = 52.50
#     total    = roundCurrency(750.00 + 4.50 + 52.50) = 807.00
#   A capless implementation instead prints amount=80.00, TAX 50.40,
#   TOTAL 774.90 — all three assertions fail.
#
# The test drives bin/cli.js (the public surface SPEC-T3.md defines), so it is
# independent of whatever internal architecture T3 chose. The runner discovers
# test/*.js automatically; no registration step exists to get wrong.
#
# DETERMINISM: fixed content, quoted heredoc, no timestamps, no randomness.
# Two injections into two trees produce byte-identical files; the file's
# sha256 is printed so the T4 oracle's byte-compare is checkable by hand.
#
# Exit: 0 ok, 2 on usage/precondition failure.
set -uo pipefail

die(){ printf 'inject-t4: %s\n' "$*" >&2; exit 2; }

[ "$#" -eq 1 ] || die "usage: bash inject-t4.sh <repo-dir>"
REPO="$1"
[ -d "$REPO" ] || die "not a directory: $REPO"
[ -d "$REPO/test" ] || die "no test/ directory in $REPO — is this a seeded parcel-billing tree?"
[ -e "$REPO/test/regression-t4.js" ] && die "test/regression-t4.js already exists in $REPO — refusing to overwrite"

cat > "$REPO/test/regression-t4.js" <<'EOF'
'use strict';

// Regression against SPEC-T3.md, "Recognized codes", SAVE10:
//   "10% off the parcel subtotal before tax, capped at 50.00 USD:
//    discountUsd = min(roundCurrency(0.10 * subtotalUsd), 50)."
//
// For an 800.00 subtotal the uncapped 10% would be 80.00; the spec caps the
// discount at 50.00, so taxable = 750.00, tax = 52.50, and the grand total is
// 750.00 + 4.50 (domestic shipping) + 52.50 = 807.00. These expectations are
// derived from the spec's own formulas — making this test pass is spec
// compliance, not a new requirement.

const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

module.exports = function ({ assertEqual }) {
  const cli = path.join(__dirname, '..', 'bin', 'cli.js');
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'regression-t4-'));
  const orderFile = path.join(dir, 'order-cap.json');
  fs.writeFileSync(
    orderFile,
    JSON.stringify({
      id: 'ORD-CAP',
      zone: 'domestic',
      discountCode: 'SAVE10',
      items: [
        {
          description: 'Engine',
          quantity: 1,
          weightKg: 720,
          dimensionsCm: { length: 100, width: 60, height: 10 },
        },
      ],
    })
  );

  let out = '';
  try {
    out = execFileSync('node', [cli, orderFile], {
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
  } catch (e) {
    out = String((e.stdout || '') + (e.stderr || ''));
  }
  const lines = out.split('\n');
  const find = (prefix) => lines.find((l) => l.startsWith(prefix)) || '(missing ' + prefix.trim() + ' line)';

  assertEqual(
    find('DISCOUNT '),
    'DISCOUNT code=SAVE10 amount=50.00',
    'SAVE10 is capped at 50.00 on an 800.00 subtotal (SPEC-T3.md cap clause)'
  );
  assertEqual(find('TAX '), 'TAX 52.50', 'tax is computed on the capped taxable amount 750.00');
  assertEqual(find('TOTAL '), 'TOTAL 807.00', 'grand total reflects the capped discount');

  fs.rmSync(dir, { recursive: true, force: true });
};
EOF

printf 'injected: %s\n' "$REPO/test/regression-t4.js"
printf 'regression_t4_sha256: %s\n' "$(sha256sum "$REPO/test/regression-t4.js" | cut -d' ' -f1)"
exit 0
