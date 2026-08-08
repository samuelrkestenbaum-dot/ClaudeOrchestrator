#!/usr/bin/env bash
# The self-audit must DETECT, not merely report. Every case here is a
# differential: a known-bad input that must be caught, or a known-good one that
# must stay quiet.
set -uo pipefail
cd "$(dirname "$0")/.."
P=0; F=0
ok(){ P=$((P+1)); echo "  ok   $1"; }
no(){ F=$((F+1)); echo "  FAIL $1"; }
t(){ [ "$2" = "$3" ] && ok "$1" || no "$1 (got '$2' want '$3')"; }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

echo "== derived authority-path extraction =="
# The pre-fix gate is the real historical artifact, not a mock.
git show 0ab05d0~1:.claude/hooks/routing-gate.sh > "$TMP/prefix.sh" 2>/dev/null

v(){ node -e '
import("./build-os/assumptions/derive-authority-paths.mjs").then(async(m)=>{
 const {HOSTS}=await import("./build-os/assumptions/host-profiles.mjs");
 const h=HOSTS.find(x=>x.id===process.argv[2]);
 console.log(m.checkViability(m.deriveAuthorityPaths(m.loadGate(process.argv[1])),h,process.argv[3]||"Edit").verdict);
});' "$1" "$2" "${3:-Edit}"; }

t "pre-fix gate under headless acceptEdits is caught as a MISMATCH" \
  "$(v "$TMP/prefix.sh" claude_code_headless_acceptEdits)" "AUTHORITY_PATH_MISMATCH"
t "current gate under the same host is viable" \
  "$(v .claude/hooks/routing-gate.sh claude_code_headless_acceptEdits)" "viable"
# Not-permitted work is correct refusal, never a Gravito defect.
t "host forbidding the work itself is NOT reported as a mismatch" \
  "$(v .claude/hooks/routing-gate.sh claude_code_headless_dontAsk)" "work_itself_not_permitted"
# A gate with NO ungated path at all must not read as viable.
printf '#!/usr/bin/env bash\necho nothing\n' > "$TMP/empty.sh"
t "a gate with no authority path is not called viable" \
  "$(v "$TMP/empty.sh" claude_code_headless_acceptEdits)" "no_authority_paths_found"

echo "== discoverability =="
# Strip the request path out of the refusal text only: the capability still
# exists, but the worker can no longer find it. That must be VIOLATED.
sed 's|  build-os/packets/routing/routing-request.json\\n|  (removed)\\n|' .claude/hooks/routing-gate.sh > "$TMP/undiscoverable.sh"
d(){ node -e '
import("./build-os/assumptions/registry.mjs").then(m=>{
 const c=m.coverage({gatePath:process.argv[1]});
 console.log(c.rows.find(r=>r.id==="capability-discoverable-at-failure").status);
});' "$1"; }
t "an unadvertised authority path is VIOLATED" "$(d "$TMP/undiscoverable.sh")" "violated"
t "the current gate advertises every path" "$(d .claude/hooks/routing-gate.sh)" "validated"

echo "== coverage semantics =="
u(){ node -e '
import("./build-os/assumptions/registry.mjs").then(m=>{
 const c=m.coverage({gatePath:".claude/hooks/routing-gate.sh"});
 console.log(process.argv[1]==="untested"?c.untested_load_bearing.length:c.violated_load_bearing.length);
});' "$1"; }
t "untested load-bearing claims are surfaced as risk" "$(u untested)" "1"
t "no load-bearing assumption is currently violated" "$(u violated)" "0"

echo "== the audit exits non-zero on a violation =="
node build-os/assumptions/self-audit.mjs "$TMP/undiscoverable.sh" >/dev/null 2>&1
t "self-audit exit code on a violated claim" "$?" "1"
node build-os/assumptions/self-audit.mjs >/dev/null 2>&1
t "self-audit exit code when clean" "$?" "0"

echo "==== RESULT: $P passed, $F failed ===="
[ "$F" -eq 0 ]
