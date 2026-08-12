#!/usr/bin/env bash
# PKT-R0-1 — cross-repository isolation: NEGATIVE LEAKAGE TESTS.
#
# Two disposable repos, a sentinel string planted in repo A's memory, and the
# assertion that no path — session-start emission, user scope, repo B's tree —
# ever carries A's sentinel into B. Plus the namespace stamp contract:
# scaffold stamps; matching stamp reads; missing stamp ADOPTS with a receipt;
# a store carried in from another project QUARANTINES (default closed).
# Disposable fixtures only; a temp HOME isolates the user scope.
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d /tmp/bos-iso.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
PASS=0; FAIL=0
ok(){ if eval "$1"; then PASS=$((PASS+1)); echo "  PASS: $2"; else FAIL=$((FAIL+1)); echo "  FAIL: $2"; fi }

mkrepo(){ # <dir> <remote-url>
  mkdir -p "$1"; git -C "$1" init -q; git -C "$1" remote add origin "$2"
  echo x > "$1/f.txt"; git -C "$1" -c user.email=t@t -c user.name=t add -A
  git -C "$1" -c user.email=t@t -c user.name=t commit -qm seed
}
run_session_start(){ # <repo> -> stdout; fresh once-marker each call
  env HOME="$WORK/home" CLAUDE_PROJECT_DIR="$1" CLAUDE_SESSION_ID="iso-$RANDOM$RANDOM" \
    bash "$SRC/.claude/hooks/session-start-build-os.sh" 2>/dev/null
}
mkdir -p "$WORK/home"
A="$WORK/repoA"; B="$WORK/repoB"
mkrepo "$A" "https://example.com/org/repo-a.git"
mkrepo "$B" "https://example.com/org/repo-b.git"
SENTINEL="SENTINEL-A-$RANDOM$RANDOM-NEVER-IN-B"

echo "== 1. scaffold stamps a deterministic namespace =="
( cd "$A" && "$SRC/init-build-os.sh" >/dev/null 2>&1 )
( cd "$B" && "$SRC/init-build-os.sh" >/dev/null 2>&1 )
ok '[ -f "$A/build-os/memory/.project-identity" ]' "repo A stamped at scaffold"
ok '[ -f "$B/build-os/memory/.project-identity" ]' "repo B stamped at scaffold"
IDA="$(awk '$1=="project_id:"{print $2}' "$A/build-os/memory/.project-identity")"
IDB="$(awk '$1=="project_id:"{print $2}' "$B/build-os/memory/.project-identity")"
ok '[ -n "$IDA" ] && [ "$IDA" != "$IDB" ]' "namespace ids are distinct across repos (A=$IDA B=$IDB)"
( cd "$A" && "$SRC/init-build-os.sh" >/dev/null 2>&1 )
IDA2="$(awk '$1=="project_id:"{print $2}' "$A/build-os/memory/.project-identity")"
ok '[ "$IDA" = "$IDA2" ]' "re-scaffold is deterministic: the stamp does not change"

echo "== 2. sentinel planted in A never reaches B =="
printf '## RULE SENT — %s\nbody %s\n' "$SENTINEL" "$SENTINEL" > "$A/build-os/memory/task-log.md"
OUTA="$(run_session_start "$A")"
ok 'printf "%s" "$OUTA" | grep -q "$SENTINEL"' "A's own session DOES see A's memory (delivery works)"
OUTB="$(run_session_start "$B")"
ok '! printf "%s" "$OUTB" | grep -q "$SENTINEL"' "B's session output carries NO trace of A's sentinel"
ok '! grep -rq "$SENTINEL" "$B" 2>/dev/null' "B's tree carries NO trace of A's sentinel"
ok '! grep -rq "$SENTINEL" "$WORK/home" 2>/dev/null' "user scope (HOME) carries NO trace of A's sentinel"

echo "== 3. carried-in store QUARANTINES (default closed) =="
cp "$A/build-os/memory/.project-identity" "$B/build-os/memory/.project-identity"
printf '## RULE SENT — %s\n' "$SENTINEL" > "$B/build-os/memory/task-log.md"
OUTB2="$(run_session_start "$B")"
ok 'printf "%s" "$OUTB2" | grep -q "QUARANTINE"' "foreign stamp in B is named QUARANTINE"
ok '! printf "%s" "$OUTB2" | grep -q "$SENTINEL"' "quarantined memory is NOT emitted (default closed)"
ok '[ -f "$B/build-os/memory/.project-identity" ]' "quarantine leaves the evidence in place (no destructive fix)"
rm "$B/build-os/memory/.project-identity" "$B/build-os/memory/task-log.md"

echo "== 4. missing stamp ADOPTS with a receipt (migration path) =="
rm "$A/build-os/memory/.project-identity"
OUTA2="$(run_session_start "$A")"
ok 'printf "%s" "$OUTA2" | grep -q "ADOPTED"' "existing un-stamped store is adopted, receipt line emitted"
IDA3="$(awk '$1=="project_id:"{print $2}' "$A/build-os/memory/.project-identity")"
ok '[ "$IDA3" = "$IDA" ]' "adoption re-derives the SAME deterministic id ($IDA3)"
ok 'printf "%s" "$OUTA2" | grep -q "$SENTINEL"' "adopted store is readable again in its own repo"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
