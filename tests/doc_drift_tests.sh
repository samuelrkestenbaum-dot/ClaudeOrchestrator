#!/usr/bin/env bash
# R1-P1 — DOC DRIFT PROTECTION. The front door must not lie:
#   1. The ONBOARDING golden-path block is EXECUTED VERBATIM against a
#      disposable repo — a renamed flag, verb, or path goes red here.
#   2. Every `gravito <verb>` any front-door doc mentions must be a real
#      dispatch verb in bin/gravito (no phantom commands).
#   3. Every repo file path ONBOARDING names must exist.
#   4. README and DEMO must actually route a new operator to the golden path.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d /tmp/bos-doc.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }

echo "== 1. the golden-path block executes verbatim on a disposable repo =="
R="$WORK/repo"; mkdir -p "$R"; git -C "$R" init -q; git -C "$R" remote add origin https://x/doc.git
echo hello > "$R/app.txt"; git -C "$R" -c user.email=t@t -c user.name=t add -A
git -C "$R" -c user.email=t@t -c user.name=t commit -qm seed
awk '/^```bash/{f=1;next} /^```/{f=0} f' "$SRC/docs/ONBOARDING.md" | head -40 > "$WORK/golden.sh"
ok '[ -s "$WORK/golden.sh" ] && grep -q "gravito-golden-path" "$WORK/golden.sh"' "ONBOARDING carries the marked executable golden-path block"
ok 'env GRAVITO="$SRC" REPO="$R" bash -eu "$WORK/golden.sh" >"$WORK/golden.out" 2>&1' "golden path executes end-to-end exactly as documented"
ok 'grep -q "preflight: ELIGIBLE" "$WORK/golden.out"' "step 1 output matches the doc's claim (preflight)"
ok 'grep -q "goal installed" "$WORK/golden.out"' "step 3 output matches the doc's claim (goal)"
ok 'grep -q "dry-run: gate open" "$WORK/golden.out"' "step 5 output matches the doc's claim (run --dry-run)"

echo "== 2. no phantom verbs: every documented gravito verb is real =="
VERBS="$(sed -n 's/.*case "\$CMD" in.*//p' "$SRC/bin/gravito")"
REAL="$(awk '/^case "\$CMD" in/,/^esac/' "$SRC/bin/gravito" | sed -n 's/^  \([a-z|]*\)).*/\1/p' | tr '|' '\n')"
DRIFT=0
for doc in "$SRC/README.md" "$SRC/docs/ONBOARDING.md" "$SRC/docs/DEMO.md"; do
  [ -f "$doc" ] || continue
  for v in $(grep -oE 'gravito (preflight|init|status|update|rollback|uninstall|purge|goal|run|review|diagnose|stop|[a-z-]+)' "$doc" | awk '{print $2}' | sort -u); do
    printf '%s\n' "$REAL" | grep -qx "$v" || { echo "  phantom verb in ${doc##*/}: gravito $v"; DRIFT=1; }
  done
done
ok '[ "$DRIFT" -eq 0 ]' "every 'gravito <verb>' in the front-door docs is a real dispatch verb"

echo "== 3. every SOURCE-repo file path ONBOARDING names exists =="
# build-os/ and .claude/ paths in ONBOARDING describe the TARGET repo's
# layout after install, so only source-artifact classes are existence-checked.
MISS=0
for p in $(grep -oE '`(tests|docs|templates|bin)/[A-Za-z0-9._/-]+`' "$SRC/docs/ONBOARDING.md" | tr -d '\`' | sort -u); do
  [ -e "$SRC/$p" ] || { echo "  missing: $p"; MISS=1; }
done
ok '[ "$MISS" -eq 0 ]' "all source-repo paths named by ONBOARDING exist"

echo "== 4. README and DEMO route a new operator to the golden path =="
ok 'grep -q "gravito init" "$SRC/README.md"' "README shows the golden path (gravito init present)"
ok 'grep -q "ONBOARDING" "$SRC/README.md"' "README points at ONBOARDING"
ok 'grep -qi "golden path\|gravito init" "$SRC/docs/DEMO.md"' "DEMO acknowledges the CLI-first golden path"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
