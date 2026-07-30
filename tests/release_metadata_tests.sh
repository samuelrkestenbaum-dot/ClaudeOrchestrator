#!/usr/bin/env bash
# Build OS — release metadata suite (packet gravito_release_metadata_a).
#
# Pins the four release-metadata artifacts so they cannot silently rot:
#   VERSION                          a real semver, single line
#   LICENSE                          present, non-empty, grants nothing by accident
#   CHANGELOG.md                     Keep-a-Changelog, with an entry for VERSION
#   build-os/memory/current_state.md the CURRENT build/test claim is not stale
#
# The last one is the point of this file. Memory drifts: current_state.md claimed
# "216 checks" for three packets after the suite had grown past it, and nothing
# caught it because no test read the claim. This one does.
#
# No network. Deterministic. Temp dirs only. Exits non-zero if any assertion
# fails, and prints the "==== RESULT: N passed, M failed ====" line the
# orchestrator parses when it chains this suite.
#
# Live mode (opt-in, OFF by default):
#   RELEASE_METADATA_LIVE_SUITE=1 bash tests/release_metadata_tests.sh
# runs tests/build_os_tests.sh for real and compares its RESULT total against the
# count current_state.md claims. It is off by default for two reasons: it costs
# ~25s, and if this suite is ever chained INSIDE build_os_tests.sh a default-on
# live run would recurse. The default path still fails on a stale claim via the
# cross-file consistency checks below (current_state vs CHANGELOG vs receipts) —
# all three have to be updated together or this suite goes red.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$SRC/VERSION"
LICENSE_FILE="$SRC/LICENSE"
CHANGELOG="$SRC/CHANGELOG.md"
STATE="$SRC/build-os/memory/current_state.md"
RESIDUE="$SRC/build-os/memory/residue.md"
RECEIPTS="$SRC/build-os/receipts"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
have(){ grep -qF "$2" "$1"; }
havei(){ grep -qiF "$2" "$1"; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------- helpers ----

# The section of a markdown file that starts at a "## <title>" heading and ends
# at the next heading of the same or higher level.
section(){ awk -v pat="$2" '
  $0 ~ "^## +" pat {f=1; next}
  f && /^#{1,2} /{exit}
  f {print}' "$1"; }

# Affirmative claims that rollback works. Deliberately NOT matched when the line
# carries a negation ("not yet proven", "never", "untested") — the honest
# statement we require says the words "tested"/"rollback" too, so a naive scan
# would flag the very sentence it exists to protect.
ROLLBACK_CLAIM_RE='(tested|proven|verified|guaranteed|supported)[[:space:]]+([a-z]+[[:space:]]+)?rollback|rollback[[:space:]]+(is|are|has been|have been)[[:space:]]+(fully[[:space:]]+)?(tested|proven|verified|guaranteed|supported)'
NEGATION_RE='\b(not|never|no|none|unproven|untested|cannot|without)\b'
scan_rollback_claims(){
  section "$1" "Update and rollback" \
    | grep -Ein "$ROLLBACK_CLAIM_RE" \
    | grep -Eiv "$NEGATION_RE"
}

# ------------------------------------------------- 1. VERSION is a semver ----
echo "== 1. VERSION =="
if [ -f "$VERSION_FILE" ]; then
  ok "VERSION exists"
else
  no "VERSION is missing (expected $VERSION_FILE)"
fi

VER="$(head -n1 "$VERSION_FILE" 2>/dev/null | tr -d '\r' | tr -d '[:space:]')"
SEMVER_RE='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?$'

if [ -n "$VER" ]; then
  ok "VERSION is non-empty (\"$VER\")"
else
  no "VERSION is empty — a release artifact with no version is worse than none"
fi

if [[ "$VER" =~ $SEMVER_RE ]]; then
  ok "VERSION \"$VER\" is semver MAJOR.MINOR.PATCH"
else
  no "VERSION \"$VER\" is not semver (MAJOR.MINOR.PATCH[-pre][+build])"
fi

case "$VER" in
  v*) no "VERSION carries a leading 'v' — the file holds the bare version, tags carry the v" ;;
  *)  ok "VERSION has no leading 'v' (bare version string)" ;;
esac

# NB: `grep -c` PRINTS 0 and EXITS 1 on no-match, so `|| echo 0` would emit two
# lines and break the numeric comparison. Capture, then default.
VLINES="$(grep -c . "$VERSION_FILE" 2>/dev/null)"; VLINES="${VLINES:-0}"
if [ "$VLINES" = "1" ]; then
  ok "VERSION is exactly one non-empty line (machine-readable)"
else
  no "VERSION has $VLINES non-empty lines — expected exactly 1"
fi

# Vacuity guard for the semver check itself: the regex must actually reject
# something. If a future edit loosens it into a match-anything pattern, the
# assertion above would pass on garbage and nobody would notice.
if [[ "0.1" =~ $SEMVER_RE ]] || [[ "banana" =~ $SEMVER_RE ]] || [[ "1.0.0.0" =~ $SEMVER_RE ]]; then
  no "the semver pattern accepts non-semver input (0.1 / banana / 1.0.0.0) — it has gone blind"
else
  ok "the semver pattern rejects 0.1, banana and 1.0.0.0 (not vacuous)"
fi

# ------------------------------------------------------------ 2. LICENSE ----
echo "== 2. LICENSE =="
if [ -f "$LICENSE_FILE" ]; then
  ok "LICENSE exists"
else
  no "LICENSE is missing (expected $LICENSE_FILE)"
fi

LBYTES="$(wc -c < "$LICENSE_FILE" 2>/dev/null | tr -d ' ')"; LBYTES="${LBYTES:-0}"
if [ "${LBYTES:-0}" -ge 200 ]; then
  ok "LICENSE is non-empty ($LBYTES bytes)"
else
  no "LICENSE is empty or a stub ($LBYTES bytes) — an unreadable license grants nothing and says nothing"
fi

havei "$LICENSE_FILE" "All Rights Reserved" \
  && ok "LICENSE reserves all rights" || no "LICENSE does not say All Rights Reserved"
have "$LICENSE_FILE" "Samuel Kestenbaum" \
  && ok "LICENSE names the copyright holder" || no "LICENSE does not name a copyright holder"
grep -Eq 'Copyright \(c\) [0-9]{4}' "$LICENSE_FILE" \
  && ok "LICENSE carries a Copyright (c) <year> line" || no "LICENSE has no Copyright (c) <year> line"
havei "$LICENSE_FILE" "written" \
  && ok "LICENSE requires a separate written agreement for any grant" \
  || no "LICENSE does not condition use on a separate written agreement"
havei "$LICENSE_FILE" "WITHOUT WARRANTY" \
  && ok "LICENSE disclaims warranty" || no "LICENSE has no warranty disclaimer"
havei "$LICENSE_FILE" "LIABILITY" \
  && ok "LICENSE disclaims liability" || no "LICENSE has no liability disclaimer"

# The negative that matters: a proprietary license must not accidentally carry a
# permissive grant clause. This is the exact phrase that leads MIT/BSD/ISC.
if grep -qi "Permission is hereby granted" "$LICENSE_FILE" 2>/dev/null; then
  no "LICENSE contains a permissive grant clause (\"Permission is hereby granted\") — it is not All Rights Reserved"
else
  ok "LICENSE contains no permissive grant clause"
fi
if grep -Eqi 'MIT License|Apache License|GNU (GENERAL|LESSER)|BSD [23]-Clause' "$LICENSE_FILE" 2>/dev/null; then
  no "LICENSE names an OSS license body — the chosen default is proprietary All Rights Reserved"
else
  ok "LICENSE does not name an OSS license body"
fi

# Do not invent commercial terms. Pricing / entitlement / ToS belong in a
# separate agreement, not in the placeholder license.
if grep -Eqi '\$[0-9]|per seat|per-seat|license key|entitlement key|subscription fee|terms of service' "$LICENSE_FILE" 2>/dev/null; then
  no "LICENSE invents pricing / entitlement / ToS terms — out of scope for this placeholder"
else
  ok "LICENSE invents no pricing, entitlement keys, or terms of service"
fi

# ---------------------------------------------------------- 3. CHANGELOG ----
echo "== 3. CHANGELOG.md =="
if [ -f "$CHANGELOG" ]; then
  ok "CHANGELOG.md exists"
else
  no "CHANGELOG.md is missing (expected $CHANGELOG)"
fi

havei "$CHANGELOG" "Keep a Changelog" \
  && ok "CHANGELOG follows Keep a Changelog" || no "CHANGELOG does not reference Keep a Changelog"
havei "$CHANGELOG" "Semantic Versioning" \
  && ok "CHANGELOG references Semantic Versioning" || no "CHANGELOG does not reference Semantic Versioning"
grep -Eq '^## \[Unreleased\]' "$CHANGELOG" 2>/dev/null \
  && ok "CHANGELOG has an Unreleased section" || no "CHANGELOG has no Unreleased section"

# The cross-file pin: the changelog must actually contain an entry for whatever
# VERSION says. Bumping one without the other is the classic release-metadata bug.
if [ -n "$VER" ] && grep -Eq "^## \[${VER//./\\.}\]" "$CHANGELOG" 2>/dev/null; then
  ok "CHANGELOG has a '## [$VER]' entry matching VERSION"
else
  no "CHANGELOG has no '## [$VER]' entry — VERSION and CHANGELOG disagree"
fi

# The 0.1.0 entry is sourced from real commits; name them so the entry cannot
# drift into invention.
for h in c30f77d 5b956c0 641527f; do
  have "$CHANGELOG" "$h" && ok "CHANGELOG cites landed commit $h" || no "CHANGELOG does not cite commit $h"
done

havei "$CHANGELOG" "license model" \
  && ok "CHANGELOG records that the license model is an open owner decision" \
  || no "CHANGELOG does not record the license-model decision as open"

# ------------------------------------------ 4. Rollback honesty (negative) ----
echo "== 4. Update and rollback — honest boundary =="
RB="$WORK/rollback.txt"
section "$CHANGELOG" "Update and rollback" > "$RB" 2>/dev/null
RB_LINES="$(grep -c . "$RB" 2>/dev/null)"; RB_LINES="${RB_LINES:-0}"
if [ "${RB_LINES:-0}" -ge 3 ]; then
  ok "the 'Update and rollback' section exists and has $RB_LINES lines (scan is not vacuous)"
else
  no "the 'Update and rollback' section is missing or under 3 lines ($RB_LINES) — the scan below would be meaningless"
fi

if grep -Eqi 'not (yet )?proven|unproven' "$RB" 2>/dev/null; then
  ok "the rollback section states plainly that full tested rollback is not yet proven"
else
  no "the rollback section does not state that rollback is unproven — silence here reads as a working guarantee"
fi

CLAIMS="$(scan_rollback_claims "$CHANGELOG")"
if [ -z "$CLAIMS" ]; then
  ok "the rollback section makes no affirmative claim that rollback is tested/proven"
else
  no "the rollback section claims rollback is tested/proven — no tags exist and it has never been executed"
  printf '      | %s\n' "$CLAIMS"
fi

# Prove the claim scanner can fire. A negative assertion that cannot go red is
# not an assertion. Both directions, against fixtures, in a temp dir.
FIX_BAD="$WORK/bad_changelog.md"
cat > "$FIX_BAD" <<'MD'
# Changelog

## Update and rollback

Rollback is fully tested and supported on every released tag.

## Something else
MD
FIX_GOOD="$WORK/good_changelog.md"
cat > "$FIX_GOOD" <<'MD'
# Changelog

## Update and rollback

Update: re-run the installer at a newer checkout.
Rollback: check out an earlier commit and re-run. A full tested version
rollback is not yet proven — no tags exist.

## Something else
MD
if [ -n "$(scan_rollback_claims "$FIX_BAD")" ]; then
  ok "claim scanner fires on a fixture asserting 'rollback is fully tested and supported'"
else
  no "claim scanner stayed silent on a fixture that claims tested rollback — it has gone blind"
fi
if [ -z "$(scan_rollback_claims "$FIX_GOOD")" ]; then
  ok "claim scanner stays silent on an honest 'not yet proven' fixture (no false positive)"
else
  no "claim scanner false-positives on the honest wording it is meant to permit"
fi

# ------------------------------------------------- 5. Memory staleness -------
echo "== 5. current_state.md staleness guard =="
# Only the CURRENT claim is under test. Historical prose ("P-006's 216-check
# suite") is a true statement about a past packet and must stay readable, so the
# guard reads exactly the one line that asserts what the suite does TODAY.
STATE_LINE="$(grep -n '\*\*Build/test command:\*\*' "$STATE" 2>/dev/null | head -n1)"
if [ -n "$STATE_LINE" ]; then
  ok "current_state.md declares a Build/test command"
else
  no "current_state.md has no '**Build/test command:**' line — the staleness guard has nothing to read"
fi

case "$STATE_LINE" in
  *"tests/build_os_tests.sh"*) ok "the Build/test command names tests/build_os_tests.sh" ;;
  *) no "the Build/test command does not name tests/build_os_tests.sh" ;;
esac

CLAIMED="$(printf '%s' "$STATE_LINE" | grep -Eo '[0-9]+ checks' | head -n1 | grep -Eo '[0-9]+')"
if [ -n "$CLAIMED" ]; then
  ok "the Build/test command claims a specific count ($CLAIMED checks)"
else
  no "the Build/test command claims no check count — an unfalsifiable claim cannot go stale, or be trusted"
fi

# The known-stale value. It survived three packets of drift.
if [ "$CLAIMED" = "216" ]; then
  no "current_state.md still claims 216 checks — that number is stale (the suite chains the cold-install suite now)"
else
  ok "current_state.md no longer claims the stale 216"
fi

# Cross-file consistency: the same count must appear in CHANGELOG.md. Three
# files have to move together, so updating one and forgetting the others is red.
if [ -n "$CLAIMED" ] && have "$CHANGELOG" "$CLAIMED passed"; then
  ok "CHANGELOG reports the same suite total ($CLAIMED passed) as current_state.md"
else
  no "CHANGELOG does not report '$CLAIMED passed' — it disagrees with current_state.md's claim"
fi

# The last-closed packet must have moved past P-022, which was the stale value.
LASTCLOSED="$(grep -n '\*\*Last closed packet:\*\*' "$STATE" 2>/dev/null | head -n1)"
if [ -n "$LASTCLOSED" ]; then
  ok "current_state.md declares a last-closed packet"
else
  no "current_state.md has no '**Last closed packet:**' line"
fi
case "$LASTCLOSED" in
  *"P-022"*) no "current_state.md still reports P-022 as last closed — two packets have landed since" ;;
  *)         ok "current_state.md's last-closed packet has advanced past P-022" ;;
esac

# Receipts exist for the two landed packets, and are found by scan (not by name
# alone) so a rename cannot leave this passing on zero files.
RCPT_HITS=0
for f in "$RECEIPTS"/*.md; do
  [ -f "$f" ] || continue
  if grep -qE 'gravito_productization_pa_maintenance_upstream_a|gravito_test_harness_stdin_hang_a' "$f"; then
    RCPT_HITS=$((RCPT_HITS+1))
  fi
done
if [ "$RCPT_HITS" -ge 2 ]; then
  ok "receipts scan finds $RCPT_HITS receipts for the two landed packets (>= 2, not vacuous)"
else
  no "receipts scan found only $RCPT_HITS receipt(s) for the two landed packets — expected >= 2"
fi

# Residue must carry the open items this release deliberately leaves open.
for term in "license model" "no tags" "single-platform"; do
  havei "$RESIDUE" "$term" && ok "residue records the open item: $term" || no "residue does not record the open item: $term"
done

# ------------------------------------------------ 6. Live suite (opt-in) -----
echo "== 6. Live suite cross-check (opt-in) =="
if [ "${RELEASE_METADATA_LIVE_SUITE:-0}" = "1" ] && [ "${RELEASE_METADATA_IN_LIVE:-0}" != "1" ]; then
  LIVE_LOG="$WORK/live.log"
  RELEASE_METADATA_IN_LIVE=1 bash "$SRC/tests/build_os_tests.sh" < /dev/null > "$LIVE_LOG" 2>&1
  LIVE_EXIT=$?
  ACTUAL="$(grep -Eo '==== RESULT: [0-9]+ passed, [0-9]+ failed ====' "$LIVE_LOG" | tail -n1 | grep -Eo '[0-9]+' | head -n1)"
  ACTUAL_FAIL="$(grep -Eo '==== RESULT: [0-9]+ passed, [0-9]+ failed ====' "$LIVE_LOG" | tail -n1 | grep -Eo '[0-9]+' | sed -n 2p)"
  if [ "$LIVE_EXIT" = "0" ] && [ "${ACTUAL_FAIL:-x}" = "0" ]; then
    ok "live run of tests/build_os_tests.sh is green (exit 0, 0 failed)"
  else
    no "live run of tests/build_os_tests.sh is not green (exit $LIVE_EXIT, ${ACTUAL_FAIL:-?} failed)"
  fi
  if [ -n "$ACTUAL" ] && [ "$ACTUAL" = "$CLAIMED" ]; then
    ok "live suite total ($ACTUAL passed) matches current_state.md's claim ($CLAIMED)"
  else
    no "live suite total (${ACTUAL:-unparsed} passed) contradicts current_state.md's claim ($CLAIMED) — the memory is stale"
  fi
else
  echo "  NOTE: live cross-check skipped (set RELEASE_METADATA_LIVE_SUITE=1 to run the real suite and compare)"
fi

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
