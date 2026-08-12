#!/usr/bin/env bash
# PKT-R0-3/4/5 — deterministic lifecycle tests on DISPOSABLE fixtures only.
# init idempotency, preflight refusal, dry-run-by-default destructive verbs,
# uninstall keeps user data, purge removes all, interruption recovery,
# goal install + gate + status surface honesty.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
G="$SRC/bin/gravito"
WORK="$(mktemp -d /tmp/bos-lc.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }
R="$WORK/repo"; mkdir -p "$R"; git -C "$R" init -q
git -C "$R" remote add origin https://example.com/org/lc.git
echo hello > "$R/app.txt"; git -C "$R" -c user.email=t@t -c user.name=t add -A
git -C "$R" -c user.email=t@t -c user.name=t commit -qm seed

echo "== 1. preflight =="
ok '"$G" preflight "$R" >/dev/null' "eligible repo passes preflight"
mkdir -p "$WORK/notgit"
ok '! "$G" preflight "$WORK/notgit" >/dev/null 2>&1' "non-git dir is refused"

echo "== 2. init: deterministic + idempotent =="
ok '"$G" init "$R" >/dev/null' "init succeeds"
ok '[ -f "$R/build-os/memory/.project-identity" ]' "namespace stamped"
M1="$(ls "$R"/build-os/receipts/install-manifest-*.txt | head -1)"
sleep 1
ok '"$G" init "$R" >/dev/null' "re-init succeeds (idempotent)"
M2="$(ls -t "$R"/build-os/receipts/install-manifest-*.txt | head -1)"
ok 'diff <(grep -v "^#" "$M1") <(grep -v "^#" "$M2") >/dev/null' "re-init converges: manifest hashes identical"

echo "== 3. interruption recovery =="
rm -f "$R/.claude/hooks/session-start-build-os.sh" "$R/CLAUDE.md"   # simulate a killed half-install
ok '"$G" init "$R" >/dev/null' "re-init after interruption succeeds"
ok '[ -f "$R/.claude/hooks/session-start-build-os.sh" ] && [ -f "$R/CLAUDE.md" ]' "missing engine files restored (convergent)"

echo "== 4. goal contract on the target repo =="
ok '"$G" goal "$SRC/templates/gravito.goal.example" "$R" >/dev/null' "valid goal installs"
ok '[ -f "$R/gravito.goal" ]' "gravito.goal present"
mkdir -p "$R/build-os/memory"; echo '{"tokens":9000000,"usd":0,"minutes":0}' > "$R/build-os/memory/spend-ledger.jsonl"
ok '! BUILD_OS_NOW=2026-08-13 bash "$SRC/build-os/tools/goal-check.sh" --gate "$R/gravito.goal" >/dev/null 2>&1' "over-budget ledger HALTS the gate (fail closed)"
HOUT="$(env HOME="$WORK/h" CLAUDE_PROJECT_DIR="$R" CLAUDE_SESSION_ID=lc-$RANDOM BUILD_OS_NOW=2026-08-13 bash "$R/.claude/hooks/session-start-build-os.sh" 2>/dev/null </dev/null || true)"
ok 'printf "%s" "$HOUT" | grep -q "GOAL HALT"' "session start announces the binding GOAL HALT"
rm "$R/build-os/memory/spend-ledger.jsonl"

echo "== 5. status surface is honest =="
SOUT="$("$G" status "$R" 2>/dev/null)"
ok 'printf "%s" "$SOUT" | grep -q "namespace: MATCH"' "status shows namespace MATCH"
ok 'printf "%s" "$SOUT" | grep -q "goal: Fix the flaky retry"' "status shows the installed goal"
ok 'printf "%s" "$SOUT" | grep -q "NOT METERED in R0"' "unmetered numbers are declared, not invented"
ok 'printf "%s" "$SOUT" | grep -q "rollback: gravito rollback"' "exact stop/rollback commands shown"

echo "== 6. destructive verbs default to dry-run =="
"$G" uninstall "$R" >/dev/null
ok '[ -f "$R/CLAUDE.md" ]' "uninstall without --force removes nothing (dry-run default)"
"$G" purge "$R" >/dev/null
ok '[ -d "$R/build-os" ]' "purge without --force removes nothing (dry-run default)"

echo "== 7. uninstall keeps user data; purge removes all =="
echo "user data" > "$R/build-os/memory/task-log.md"
"$G" uninstall "$R" --force >/dev/null
ok '[ ! -f "$R/CLAUDE.md" ]' "uninstall --force removed engine files"
ok '[ -f "$R/build-os/memory/task-log.md" ]' "uninstall kept build-os user data"
"$G" purge "$R" --force >/dev/null
ok '[ ! -d "$R/build-os" ] && [ ! -d "$R/.claude" ] && [ ! -f "$R/gravito.goal" ]' "purge --force removed all Gravito state"
ok '[ -f "$R/app.txt" ]' "product files untouched by purge"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
