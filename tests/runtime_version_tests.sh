#!/usr/bin/env bash
# Gravito runtime — versioned install/upgrade/rollback/uninstall lifecycle tests.
# Product need: "the customer should not manually copy five scripts and several
# contracts." This suite proves the copied-install pattern (empathiq pilot) is
# now a versioned, installable runtime.
#
# Fixture-driven: builds a mktemp CANONICAL repo (byte-identical copies of this
# repo's runtime files + the baked MANIFEST.json) and mktemp TARGET repos —
# including one with a pre-existing customer settings.json whose own hooks MUST
# survive both merge and uninstall. Never touches any real install.
# No network. Deterministic. Standalone: prints '==== RESULT: N passed, M failed ===='.
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUNTIME_DIR="$SRC/build-os/runtime"
PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
sha(){ sha256sum "$1" | awk '{print $1}'; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

EXECUTABLES=".claude/hooks/routing-gate.sh build-os/tools/route-task.sh build-os/tools/mode-select.mjs build-os/tools/routing-check.sh build-os/tools/record-degradation.sh"
CONTRACTS="build-os/memory/routing_contract.md build-os/memory/routing_contract_live.md build-os/memory/provider_adapter_contract.md"

echo "== 0. Runtime artifacts exist in the source repo =="
for f in MANIFEST.json gravito-runtime.sh runtime-json.mjs; do
  [ -f "$RUNTIME_DIR/$f" ] && ok "build-os/runtime/$f exists" || no "build-os/runtime/$f exists"
done
[ -x "$RUNTIME_DIR/gravito-runtime.sh" ] && ok "gravito-runtime.sh is executable" || no "gravito-runtime.sh is executable"
if [ "$FAIL" -gt 0 ]; then
  echo "==== RESULT: $PASS passed, $FAIL failed ===="
  exit 1
fi

# ---- Fixture canonical repo: byte-identical copies of the real runtime files.
CANON="$WORK/canon"
mkdir -p "$CANON/.claude/hooks" "$CANON/build-os/tools" "$CANON/build-os/memory" "$CANON/build-os/runtime"
for f in $EXECUTABLES $CONTRACTS; do cp -p "$SRC/$f" "$CANON/$f"; done
cp -p "$RUNTIME_DIR/gravito-runtime.sh" "$RUNTIME_DIR/runtime-json.mjs" "$RUNTIME_DIR/MANIFEST.json" "$CANON/build-os/runtime/"
git -C "$CANON" init -q
git -C "$CANON" -c user.email=t@t.t -c user.name=t add -A >/dev/null 2>&1
git -C "$CANON" -c user.email=t@t.t -c user.name=t commit -qm fixture >/dev/null 2>&1
CANON_COMMIT="$(git -C "$CANON" rev-parse --short HEAD)"
GR="$CANON/build-os/runtime/gravito-runtime.sh"

mk_target(){ # $1 = path; customer-owned settings.json + gitignore + files
  local t="$1"
  mkdir -p "$t/.claude" "$t/build-os/memory"
  cat > "$t/.claude/settings.json" <<'EOF'
{
  "permissions": { "allow": ["Bash(npm run test:*)"] },
  "hooks": {
    "PreToolUse": [
      { "matcher": "Bash", "hooks": [ { "type": "command", "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/customer-own-gate.sh" } ] }
    ]
  }
}
EOF
  echo "customer notes — never remove" > "$t/build-os/memory/customer_notes.md"
  printf 'node_modules/\n.env\n' > "$t/.gitignore"
}

echo "== 1. MANIFEST.json is the canonical release manifest =="
M="$RUNTIME_DIR/MANIFEST.json"
# VERSION IS DERIVED, NOT SPELLED. These assertions used to hardcode "0.1.0",
# so they measured a SNAPSHOT rather than an invariant: the first legitimate
# release broke six of them, and the obvious repair -- typing the new number --
# would have converted a guard into a transcription. What the suite actually
# means is "the manifest, the tool, the install receipt and the upgrade receipt
# all agree", and that holds at every version.
VER="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$M','utf8')).version)")"
NEXT_VER="$(node -e "const v='$VER'.split('.').map(Number); v[2]+=1; console.log(v.join('.'))")"
[ -n "$VER" ] && [ "$VER" != "$NEXT_VER" ] && ok "derived version pair $VER -> $NEXT_VER" \
                                          || no "derived version pair ($VER -> $NEXT_VER)"
node -e "JSON.parse(require('fs').readFileSync('$M','utf8'))" 2>/dev/null \
  && ok "MANIFEST.json is valid JSON" || no "MANIFEST.json is valid JSON"
grep -q "\"version\": *\"$VER\"" "$M" && ok "manifest version $VER" || no "manifest version $VER"
for f in $EXECUTABLES $CONTRACTS; do
  grep -qF "\"$f\"" "$M" && ok "manifest lists $f" || no "manifest lists $f"
done
# shas in the manifest match this repo's actual files (computed, not invented)
BAD=0
while IFS=$'\t' read -r src inst mode header msha; do
  [ "$(sha "$SRC/$src")" = "$msha" ] || { BAD=1; echo "    mismatch: $src"; }
done < <(node "$RUNTIME_DIR/runtime-json.mjs" files "$M")
[ "$BAD" = 0 ] && ok "manifest sha256s match the repo's actual files" || no "manifest sha256s match the repo's actual files"
grep -q '"settings_hooks"' "$M" && ok "manifest carries settings.json hook entries" || no "manifest carries settings.json hook entries"
grep -qF 'routing-gate.sh mutgate' "$M" && ok "hook entries include the mutation gate" || no "hook entries include the mutation gate"
grep -q '"gitignore"' "$M" && ok "manifest carries .gitignore lines" || no "manifest carries .gitignore lines"
grep -qF 'build-os/packets/routing/live_state/' "$M" && ok "gitignore lines include live_state/" || no "gitignore lines include live_state/"

echo "== 2. version: self-check CLEAN + DIRTY detection =="
OUT="$("$GR" version 2>&1)"; RC=$?
[ "$RC" = 0 ] && ok "version exits 0 on clean canonical" || no "version exits 0 on clean canonical (rc=$RC)"
echo "$OUT" | grep -q "$VER" && ok "version prints runtime version" || no "version prints runtime version"
N_SHA="$(echo "$OUT" | grep -cE '\b[0-9a-f]{64}\b')"
[ "$N_SHA" -ge 8 ] && ok "version prints per-file sha256 (8 files)" || no "version prints per-file sha256 (got $N_SHA)"
echo "$OUT" | grep -q "RUNTIME: CLEAN" && ok "clean canonical reports CLEAN" || no "clean canonical reports CLEAN"

DIRTYC="$WORK/canon-dirty"; cp -r "$CANON" "$DIRTYC"; rm -rf "$DIRTYC/.git"
echo "# local tamper" >> "$DIRTYC/build-os/tools/routing-check.sh"
OUT="$("$DIRTYC/build-os/runtime/gravito-runtime.sh" version 2>&1)"; RC=$?
[ "$RC" != 0 ] && ok "version exits non-zero on dirty canonical" || no "version exits non-zero on dirty canonical"
echo "$OUT" | grep -q "DIRTY" && ok "dirty canonical reports DIRTY" || no "dirty canonical reports DIRTY"
echo "$OUT" | grep -q "routing-check.sh" && ok "DIRTY names the drifted file" || no "DIRTY names the drifted file"

echo "== 3. install: full wiring into a customer repo =="
T1="$WORK/t1"; mk_target "$T1"
OUT="$("$GR" install "$T1" 2>&1)"; RC=$?
[ "$RC" = 0 ] && ok "install exits 0" || { no "install exits 0 (rc=$RC)"; echo "$OUT"; }
ALL=1; for f in $EXECUTABLES $CONTRACTS; do [ -f "$T1/$f" ] || { ALL=0; echo "    missing: $f"; }; done
[ "$ALL" = 1 ] && ok "all 8 runtime files installed" || no "all 8 runtime files installed"
BAD=0; for f in $EXECUTABLES; do cmp -s "$CANON/$f" "$T1/$f" || BAD=1; done
[ "$BAD" = 0 ] && ok "executables byte-identical to canonical" || no "executables byte-identical to canonical"
[ -x "$T1/.claude/hooks/routing-gate.sh" ] && ok "installed hook keeps executable bit" || no "installed hook keeps executable bit"
BAD=0; for f in $CONTRACTS; do head -n1 "$T1/$f" | grep -qF '> **INSTALLED COPY**' || BAD=1; done
[ "$BAD" = 0 ] && ok "contracts carry installed-copy header" || no "contracts carry installed-copy header"
H="$(head -n1 "$T1/build-os/memory/routing_contract.md")"
echo "$H" | grep -qF "$CANON_COMMIT" && ok "header carries auto-derived source commit" || no "header carries auto-derived source commit"
echo "$H" | grep -q "$(date +%Y-%m-%d)" && ok "header carries install date" || no "header carries install date"
echo "$H" | grep -q "do NOT auto-update" && ok "header states no-auto-update" || no "header states no-auto-update"
BAD=0; for f in $CONTRACTS; do cmp -s <(sed '1,2d' "$T1/$f") "$CANON/$f" || BAD=1; done
[ "$BAD" = 0 ] && ok "contract bodies byte-identical below the header" || no "contract bodies byte-identical below the header"

S="$T1/.claude/settings.json"
node -e "JSON.parse(require('fs').readFileSync('$S','utf8'))" 2>/dev/null \
  && ok "merged settings.json is valid JSON" || no "merged settings.json is valid JSON"
grep -qF 'customer-own-gate.sh' "$S" && ok "customer's own hook survives merge" || no "customer's own hook survives merge"
grep -qF '"permissions"' "$S" && ok "customer's non-hook settings survive merge" || no "customer's non-hook settings survive merge"
for sub in "routing-gate.sh gate" "routing-gate.sh mutgate" "routing-gate.sh count" "routing-gate.sh post"; do
  grep -qF "$sub" "$S" && ok "settings wired: $sub" || no "settings wired: $sub"
done
grep -qxF 'build-os/packets/routing/live_gate_log.tsv' "$T1/.gitignore" \
  && ok ".gitignore stanza appended" || no ".gitignore stanza appended"
grep -qxF 'node_modules/' "$T1/.gitignore" && ok "customer .gitignore lines preserved" || no "customer .gitignore lines preserved"
IV="$T1/build-os/runtime/INSTALLED_VERSION.json"
[ -f "$IV" ] && ok "INSTALLED_VERSION.json written" || no "INSTALLED_VERSION.json written"
grep -q "\"version\": *\"$VER\"" "$IV" && ok "installed version recorded" || no "installed version recorded"
grep -qF "$CANON_COMMIT" "$IV" && ok "installed source commit recorded" || no "installed source commit recorded"
N_REC="$(node -e "console.log(JSON.parse(require('fs').readFileSync('$IV','utf8')).files.length)" 2>/dev/null)"
[ "$N_REC" = "8" ] && ok "per-file sha records: 8" || no "per-file sha records: 8 (got $N_REC)"
ls "$T1"/build-os/runtime/receipts/install-*.json >/dev/null 2>&1 \
  && ok "install migration receipt written" || no "install migration receipt written"

echo "== 4. install idempotence + no-overwrite refusal =="
SHA_BEFORE="$(sha "$T1/build-os/memory/routing_contract.md")"
SET_BEFORE="$(sha "$S")"
OUT="$("$GR" install "$T1" 2>&1)"; RC=$?
[ "$RC" = 0 ] && ok "re-install of identical content is idempotent-ok" || { no "re-install of identical content is idempotent-ok (rc=$RC)"; echo "$OUT"; }
[ "$(sha "$T1/build-os/memory/routing_contract.md")" = "$SHA_BEFORE" ] \
  && ok "idempotent re-install leaves contracts untouched" || no "idempotent re-install leaves contracts untouched"
[ "$(sha "$S")" = "$SET_BEFORE" ] && ok "idempotent re-install does not duplicate hook entries" || no "idempotent re-install does not duplicate hook entries"
N_GI="$(grep -cxF 'build-os/packets/routing/live_gate_log.tsv' "$T1/.gitignore")"
[ "$N_GI" = 1 ] && ok "idempotent re-install does not duplicate gitignore lines" || no "idempotent re-install does not duplicate gitignore lines"

T2="$WORK/t2"; mk_target "$T2"
mkdir -p "$T2/.claude/hooks"
echo '#!/bin/bash # a customer file that happens to share the path' > "$T2/.claude/hooks/routing-gate.sh"
OUT="$("$GR" install "$T2" 2>&1)"; RC=$?
[ "$RC" != 0 ] && ok "install refuses when a target file differs" || no "install refuses when a target file differs"
echo "$OUT" | grep -q "routing-gate.sh" && ok "refusal names the conflicting file" || no "refusal names the conflicting file"
[ ! -f "$T2/build-os/tools/route-task.sh" ] && ok "refusal copies nothing (no partial install)" || no "refusal copies nothing (no partial install)"
[ ! -f "$T2/build-os/runtime/INSTALLED_VERSION.json" ] && ok "refusal writes no INSTALLED_VERSION.json" || no "refusal writes no INSTALLED_VERSION.json"
grep -qF 'routing-gate.sh mutgate' "$T2/.claude/settings.json" \
  && no "refusal must not touch settings.json" || ok "refusal does not touch settings.json"

echo "== 5. status: honest three-state drift detection =="
OUT="$("$GR" status "$T1" 2>&1)"
N_CUR="$(echo "$OUT" | grep -c 'current')"
[ "$N_CUR" -ge 8 ] && ok "fresh install: all 8 files current" || no "fresh install: all 8 files current (got $N_CUR)"
echo "# local customer patch" >> "$T1/build-os/tools/routing-check.sh"
sed -i 's/^/# canonical evolved\n/' "$CANON/build-os/tools/record-degradation.sh" 2>/dev/null \
  || { printf '# canonical evolved\n%s' "$(cat "$CANON/build-os/tools/record-degradation.sh")" > "$CANON/build-os/tools/record-degradation.sh"; }
"$GR" regen-manifest --version "$NEXT_VER" >/dev/null 2>&1 \
  && ok "regen-manifest cuts v$NEXT_VER from evolved canonical" || no "regen-manifest cuts v$NEXT_VER from evolved canonical"
"$GR" version >/dev/null 2>&1 && ok "canonical CLEAN again after regen" || no "canonical CLEAN again after regen"
OUT="$("$GR" status "$T1" 2>&1)"
echo "$OUT" | grep 'routing-check.sh' | grep -q 'drifted-local' \
  && ok "locally modified file reports drifted-local" || no "locally modified file reports drifted-local"
echo "$OUT" | grep 'record-degradation.sh' | grep -q 'upgrade-available' \
  && ok "canonically evolved file reports upgrade-available" || no "canonically evolved file reports upgrade-available"
echo "$OUT" | grep 'routing_contract.md' | grep -q 'current' \
  && ok "unchanged file reports current" || no "unchanged file reports current"
echo "$OUT" | grep -q "$NEXT_VER" && ok "status shows canonical version $NEXT_VER" || no "status shows canonical version $NEXT_VER"

echo "== 6. upgrade: refusal on local drift; --force-theirs backs up first =="
OUT="$("$GR" upgrade "$T1" 2>&1)"; RC=$?
[ "$RC" != 0 ] && ok "upgrade refuses while drifted-local files exist" || no "upgrade refuses while drifted-local files exist"
echo "$OUT" | grep -q 'routing-check.sh' && ok "upgrade refusal names the drifted file" || no "upgrade refusal names the drifted file"
grep -q "\"version\": *\"$VER\"" "$IV" && ok "refused upgrade changes nothing" || no "refused upgrade changes nothing"
DRIFT_SHA="$(sha "$T1/build-os/tools/routing-check.sh")"
OUT="$("$GR" upgrade "$T1" --force-theirs 2>&1)"; RC=$?
[ "$RC" = 0 ] && ok "upgrade --force-theirs succeeds" || { no "upgrade --force-theirs succeeds (rc=$RC)"; echo "$OUT"; }
BDIR="$(ls -1d "$T1"/build-os/runtime/backup/*/ 2>/dev/null | sort | tail -n1)"
[ -n "$BDIR" ] && ok "backup dir created" || no "backup dir created"
[ -f "$BDIR/build-os/tools/routing-check.sh" ] && [ "$(sha "$BDIR/build-os/tools/routing-check.sh")" = "$DRIFT_SHA" ] \
  && ok "forced file backed up with local content intact" || no "forced file backed up with local content intact"
cmp -s "$T1/build-os/tools/routing-check.sh" "$CANON/build-os/tools/routing-check.sh" \
  && ok "forced file restored to canonical" || no "forced file restored to canonical"
cmp -s "$T1/build-os/tools/record-degradation.sh" "$CANON/build-os/tools/record-degradation.sh" \
  && ok "upgrade-available file updated to canonical" || no "upgrade-available file updated to canonical"
grep -q "\"version\": *\"$NEXT_VER\"" "$IV" && ok "INSTALLED_VERSION bumped to $NEXT_VER" || no "INSTALLED_VERSION bumped to $NEXT_VER"
UR="$(ls -1 "$T1"/build-os/runtime/receipts/upgrade-*.json 2>/dev/null | tail -n1)"
[ -n "$UR" ] && ok "upgrade receipt written" || no "upgrade receipt written"
grep -q "\"from_version\": *\"$VER\"" "$UR" 2>/dev/null && grep -q "\"to_version\": *\"$NEXT_VER\"" "$UR" 2>/dev/null \
  && ok "receipt records from/to versions" || no "receipt records from/to versions"
OUT="$("$GR" status "$T1" 2>&1)"
echo "$OUT" | grep -q 'STATUS: 8 current, 0 drifted-local, 0 upgrade-available' \
  && ok "post-upgrade status all current" || no "post-upgrade status all current"

echo "== 7. rollback: restore from most recent backup =="
OUT="$("$GR" rollback "$T1" 2>&1)"; RC=$?
[ "$RC" = 0 ] && ok "rollback exits 0" || { no "rollback exits 0 (rc=$RC)"; echo "$OUT"; }
[ "$(sha "$T1/build-os/tools/routing-check.sh")" = "$DRIFT_SHA" ] \
  && ok "rollback restores the customer's local modification" || no "rollback restores the customer's local modification"
grep -q "\"version\": *\"$VER\"" "$IV" && ok "rollback restores INSTALLED_VERSION $VER" || no "rollback restores INSTALLED_VERSION $VER"
ls "$T1"/build-os/runtime/receipts/rollback-*.json >/dev/null 2>&1 \
  && ok "rollback receipt written" || no "rollback receipt written"

echo "== 8. uninstall: remove ours, keep everything customer-owned =="
T3="$WORK/t3"; mk_target "$T3"
"$GR" install "$T3" >/dev/null 2>&1
OUT="$("$GR" uninstall "$T3" 2>&1)"; RC=$?
[ "$RC" = 0 ] && ok "uninstall exits 0" || { no "uninstall exits 0 (rc=$RC)"; echo "$OUT"; }
GONE=1; for f in $EXECUTABLES $CONTRACTS; do [ -f "$T3/$f" ] && { GONE=0; echo "    still present: $f"; }; done
[ "$GONE" = 1 ] && ok "all 8 runtime files removed" || no "all 8 runtime files removed"
[ ! -f "$T3/build-os/runtime/INSTALLED_VERSION.json" ] && ok "INSTALLED_VERSION.json removed" || no "INSTALLED_VERSION.json removed"
S3="$T3/.claude/settings.json"
node -e "JSON.parse(require('fs').readFileSync('$S3','utf8'))" 2>/dev/null \
  && ok "settings.json still valid JSON after uninstall" || no "settings.json still valid JSON after uninstall"
grep -qF 'customer-own-gate.sh' "$S3" && ok "customer's own hook survives uninstall" || no "customer's own hook survives uninstall"
grep -qF '"permissions"' "$S3" && ok "customer's non-hook settings survive uninstall" || no "customer's non-hook settings survive uninstall"
grep -qF 'routing-gate.sh mutgate' "$S3" && no "our hook entries removed from settings" || ok "our hook entries removed from settings"
[ -f "$T3/build-os/memory/customer_notes.md" ] && ok "customer file in build-os/memory preserved" || no "customer file in build-os/memory preserved"
grep -qxF 'node_modules/' "$T3/.gitignore" && ok "customer .gitignore lines preserved on uninstall" || no "customer .gitignore lines preserved on uninstall"
ls "$T3"/build-os/runtime/receipts/install-*.json >/dev/null 2>&1 \
  && ok "install receipt preserved (audit trail is customer-owned)" || no "install receipt preserved"
ls "$T3"/build-os/runtime/receipts/uninstall-*.json >/dev/null 2>&1 \
  && ok "uninstall receipt written" || no "uninstall receipt written"

echo ""
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" = 0 ]
