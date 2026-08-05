# EXP-0003 — deterministic scripted reference completion of T1 + T2 on a
# freshly seeded parcel-billing tree. Invoke via bash; this file is
# deliberately NOT executable:
#   bash setup-t1t2.sh <repo-dir>
#
# WHY THIS EXISTS. EXP-0003 measures only the three shapes that exposed the
# routing mechanism in EXP-0002 (T3 feature, T4 injected regression, T5
# follow-up). Those tasks presuppose the T1/T2 state (DIAGNOSIS.md present,
# the tier-boundary defect fixed, a boundary test added, suite green). Running
# T1/T2 with a model would spend unmeasured model runs and make the three
# conditions' starting context non-identical. This script is the fix: a FIXED
# REFERENCE completion, applied identically in all three conditions before any
# measured run, byte-reproducible (run twice on two seeds -> identical tree
# digests via seed-workload-repo.sh --digest).
#
# WHAT IT DOES, in order — and it PROVES each half against the FROZEN EXP-0002
# oracle rather than asserting it:
#   1. verifies the tree is a freshly seeded, unfixed parcel-billing instance
#      (suite exactly 'TOTAL: 19 passed, 0 failed');
#   2. snapshots the pre-setup tree to a scratch reference;
#   3. writes the reference DIAGNOSIS.md (fixed bytes, no timestamps);
#   4. DRIVES oracle-exp2.js T1 (candidate vs snapshot) — must ACCEPT;
#   5. applies the one-line tierFor fix (`<` -> `<=` on the small-tier line),
#      refusing unless the buggy line occurs exactly once;
#   6. adds the reference boundary test test/pricing-boundary.test.js
#      (4 assertions, fixed bytes);
#   7. DRIVES oracle-exp2.js T2 (candidate vs the still-buggy snapshot) — must
#      ACCEPT, which executes the differential: the added test transplanted
#      onto the unfixed source must FAIL;
#   8. verifies the suite is green at EXACTLY 'TOTAL: 23 passed, 0 failed'
#      (the pinned post-setup total), and prints the post-setup tree digest.
#
# DETERMINISM IS A HARD REQUIREMENT: no timestamps, no $RANDOM, no $$, no
# hostname, no network; every heredoc delimiter is quoted; the scratch
# reference lives in mktemp and is removed, so nothing non-deterministic
# touches the tree. Proof recipe:
#   seed A; setup A; seed B; setup B; --digest A == --digest B
#
# Exit: 0 setup complete and oracle-proven; 2 on any precondition failure or
# oracle rejection (nothing is retried, nothing is guessed).
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXP2_H="$(cd "$SELF_DIR/../../EXP-0002-sustained-workload/harness" && pwd)"
SEEDER="$EXP2_H/seed-workload-repo.sh"
ORACLE="$EXP2_H/oracle-exp2.js"

SEED_SUITE_EXPECT='TOTAL: 19 passed, 0 failed'
SETUP_SUITE_EXPECT='TOTAL: 23 passed, 0 failed'
BUGGY_LINE="  if (billableKg < SMALL_MAX_KG) return 'small';"
FIXED_LINE="  if (billableKg <= SMALL_MAX_KG) return 'small';"

die(){ printf 'setup-t1t2: %s\n' "$*" >&2; exit 2; }

case "${1:-}" in
  ''|-h|--help) sed -n '2,44p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
esac
[ "$#" -eq 1 ] || die "usage: bash setup-t1t2.sh <repo-dir>"
REPO="$1"
[ -d "$REPO" ] || die "not a directory: $REPO"
REPO="$(cd "$REPO" && pwd)"
command -v node >/dev/null 2>&1 || die "node is not on PATH"
[ -f "$SEEDER" ] || die "missing frozen seeder: $SEEDER"
[ -f "$ORACLE" ] || die "missing frozen oracle: $ORACLE"
[ -f "$REPO/lib/pricing.js" ] || die "$REPO does not look like a seeded parcel-billing tree (no lib/pricing.js)"
[ -f "$REPO/test/run.js" ]    || die "$REPO does not look like a seeded parcel-billing tree (no test/run.js)"
[ -e "$REPO/DIAGNOSIS.md" ] && die "DIAGNOSIS.md already exists in $REPO — this tree is already set up (or partially so); setup runs exactly once, on a fresh seed"
[ -e "$REPO/test/pricing-boundary.test.js" ] && die "test/pricing-boundary.test.js already exists in $REPO — this tree is already set up"

# 1. The tree must be the UNFIXED seeded state: green at exactly the seeded
# total, with the buggy small-tier comparison present exactly once.
PRE_SUITE="$(cd "$REPO" && node test/run.js 2>&1 | tail -1)"
[ "$PRE_SUITE" = "$SEED_SUITE_EXPECT" ] || die "pre-setup suite is not at the seeded state (expected '$SEED_SUITE_EXPECT', got '$PRE_SUITE')"
NBUG="$(grep -cxF "$BUGGY_LINE" "$REPO/lib/pricing.js")"
[ "$NBUG" = "1" ] || die "the seeded defect line occurs $NBUG time(s) in lib/pricing.js (expected exactly 1) — refusing to fix a tree that does not match the frozen seed"

# 2. Snapshot the pre-setup tree: the oracle's pristine reference for BOTH
# drives (T1 diffs against it; T2 transplants the tests onto its buggy source).
REF="$(mktemp -d)"
trap 'rm -rf "$REF"' EXIT
cp -r "$REPO/." "$REF/" || die "could not snapshot the pre-setup tree"

# 3. The reference DIAGNOSIS.md — fixed bytes.
cat > "$REPO/DIAGNOSIS.md" <<'EOF'
# DIAGNOSIS — tier boundary disagrees with its own specification comment

- **File:** `lib/pricing.js`
- **Function:** `tierFor(billableKg)`
- **The exact line's behaviour:** the small-tier comparison reads
  `if (billableKg < SMALL_MAX_KG) return 'small';` — a STRICT `<` against the
  5 kg limit — so a billable weight exactly equal to the small tier's upper
  limit falls through to the medium tier.
- **The specification it contradicts:** the tier table comment in the same
  file states "TIER LIMITS ARE INCLUSIVE: a parcel whose billable weight is
  exactly equal to a tier's upper limit belongs in that tier. A parcel of
  exactly 5 kg is a 'small' parcel."
- **One concrete input where behaviour and specification disagree:**
  `tierFor(5)` returns `'medium'` and `basePriceUsd(5)` returns `15` (the
  medium flat rate); the comment requires `'small'` and `8`.
- The seeded test suite exercises tiers only away from the boundary
  (2 kg / 12 kg / 30 kg), which is why it is green over the defect.

No code was changed by this diagnosis.
EOF

# 4. Drive the frozen T1 oracle: DIAGNOSIS.md names the site, nothing else
# changed. An oracle rejection here is a setup defect, not a model's.
T1_VERDICT="$(node "$ORACLE" T1 "$REPO" "$REF" 2>&1)" || die "the frozen T1 oracle rejected the reference diagnosis: $T1_VERDICT"
printf 'setup-t1t2: %s\n' "$T1_VERDICT"

# 5. The one-line tierFor fix, exact-match only.
TMP_FIX="$REPO/lib/.pricing.js.fix"
awk -v bug="$BUGGY_LINE" -v fix="$FIXED_LINE" '{ if ($0 == bug) print fix; else print }' \
  "$REPO/lib/pricing.js" > "$TMP_FIX" || die "could not rewrite lib/pricing.js"
mv "$TMP_FIX" "$REPO/lib/pricing.js" || die "could not install the fixed lib/pricing.js"
[ "$(grep -cxF "$FIXED_LINE" "$REPO/lib/pricing.js")" = "1" ] || die "the fixed line is not present exactly once after the rewrite"
[ "$(grep -cxF "$BUGGY_LINE" "$REPO/lib/pricing.js")" = "0" ] || die "the buggy line survived the rewrite"

# 6. The reference boundary test — fixed bytes, discovered automatically by
# test/run.js (test/*.js except run.js).
cat > "$REPO/test/pricing-boundary.test.js" <<'EOF'
'use strict';

// Reference boundary coverage for the T1/T2 instance (EXP-0003 scripted
// setup). The tier-table comment in lib/pricing.js states that limits are
// INCLUSIVE: exactly 5 kg is small (flat 8.00) and exactly 20 kg is medium
// (flat 15.00). Against the seeded strict-`<` comparison the two 5 kg
// assertions FAIL; after the one-line `<=` fix all four pass.

const { tierFor, basePriceUsd } = require('../lib/pricing');

module.exports = function ({ assertEqual }) {
  assertEqual(tierFor(5), 'small', 'a parcel of exactly 5 kg is small (inclusive limit)');
  assertEqual(basePriceUsd(5), 8, 'a parcel of exactly 5 kg costs the small flat rate 8.00');
  assertEqual(tierFor(20), 'medium', 'a parcel of exactly 20 kg is medium (inclusive limit)');
  assertEqual(basePriceUsd(20), 15, 'a parcel of exactly 20 kg costs the medium flat rate 15.00');
};
EOF

# 7. Drive the frozen T2 oracle. This EXECUTES the differential: the candidate
# test directory transplanted onto the snapshot's still-buggy source must
# FAIL, proving the added test would have caught the defect.
T2_VERDICT="$(node "$ORACLE" T2 "$REPO" "$REF" 2>&1)" || die "the frozen T2 oracle rejected the reference fix: $T2_VERDICT"
printf 'setup-t1t2: %s\n' "$T2_VERDICT"

# 8. The pinned post-setup total, exactly.
POST_SUITE="$(cd "$REPO" && node test/run.js 2>&1 | tail -1)"
[ "$POST_SUITE" = "$SETUP_SUITE_EXPECT" ] || die "post-setup suite is '$POST_SUITE', not the pinned '$SETUP_SUITE_EXPECT'"

DIGEST="$(bash "$SEEDER" --digest "$REPO")" || die "could not digest the post-setup tree"
printf 'setup-t1t2: post_setup_suite: %s\n' "$POST_SUITE"
printf 'setup-t1t2: post_setup_tree_digest: %s\n' "$DIGEST"
exit 0
