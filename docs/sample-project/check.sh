#!/usr/bin/env bash
# The sample project's whole test suite. Same shape as every Build OS suite:
# ok()/no(), a final RESULT line, non-zero exit on any failure.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
eq(){ # eq <input> <expected> <label>
  local got; got="$(bash "$HERE/slugify.sh" "$1")"
  [ "$got" = "$2" ] && ok "$3" || no "$3 — got \"$got\", expected \"$2\""
}

eq "Hello World"    "hello-world"     "spaces become dashes"
eq "Rock & Roll"    "rock-roll"       "punctuation collapses into one dash"
eq "ALL CAPS"       "all-caps"        "input is lowercased"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
