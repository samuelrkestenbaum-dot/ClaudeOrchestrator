#!/usr/bin/env bash
# Build OS — ENTITLEMENT + INSTALLED-COPY IDENTITY tests
# (packet gravito_entitlement_minimal_a).
#
#   bash tests/entitlement_tests.sh
#
# Deterministic, offline, temp-dirs-only. Every install below goes into a blank
# directory created here; nothing writes to this repo, ~/.claude, or ~/build-os.
#
# WHAT IT PROVES, each one executed rather than described:
#   1. A fresh install into a blank repo produces a DISCOVERABLE identity — an
#      installed copy can state its version and its licence with no human in the
#      loop — at BOTH scopes (user ~/.claude + ~/build-os, and project build-os/).
#   2. That identity MATCHES the source: `version:` == VERSION, and the installed
#      licence copy is byte-identical to LICENSE (verified by sha256, both ways).
#   3. DRIFT IS DETECTABLE AND FAILS. Two independent drift shapes:
#         (a) engine files replaced under a stamp that still claims the old commit
#         (b) the stamp's own `source_commit:` hand-edited to claim another commit
#      Both must make `verify` exit non-zero and say DRIFT. A stamp that cannot go
#      red is decoration, and decoration next to a licence claim is worse than
#      nothing.
#   4. The identity is SURFACED, in ONE line, by the SessionStart hook — and the
#      session output stays small (an oversized SessionStart payload is discarded
#      by Claude Code, and a banner gets deleted by its owner).
#   5. NO NETWORK EGRESS is added by this packet. Scanned, with a positive control
#      (a planted `curl` fixture must be flagged) and a negative control (a
#      comment mentioning curl must not be), so the scanner cannot pass by
#      going blind.
#   6. README.md and INSTALL.md state the proprietary / access-gated position
#      EARLY, and never let "the repo is public/visible" stand as though it were
#      a licence.
#   7. docs/ENTITLEMENT.md exists, and its claims about the licence MATCH the
#      LICENSE file's actual text — quoted verbatim, checked verbatim. A buyer
#      reads the doc and is bound by the licence; drift between them is a defect
#      with legal consequences, so it is a test failure here.
#   8. VACUITY GUARDS throughout: if a scan finds zero artefacts, zero files, or
#      zero quote lines, it FAILS instead of passing empty.
#
# NOT proven here, because it is not true: none of this stops a person who has a
# copy from using it. See docs/ENTITLEMENT.md — "What is NOT enforced technically".
set -uo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="$SRC/VERSION"
LICENSE_FILE="$SRC/LICENSE"
ENTITLEMENT="$SRC/docs/ENTITLEMENT.md"
README="$SRC/README.md"
INSTALL="$SRC/INSTALL.md"
IDENTITY_SH="$SRC/.claude/hooks/build-os-identity.sh"
SESSION_HOOK="$SRC/.claude/hooks/session-start-build-os.sh"

STAMP_NAME="build-os-identity"
LIC_COPY="BUILD-OS-LICENSE"

PASS=0; FAIL=0
ok(){ PASS=$((PASS+1)); echo "  PASS: $1"; }
no(){ FAIL=$((FAIL+1)); echo "  FAIL: $1"; }
have(){ grep -qF "$2" "$1" 2>/dev/null; }
havei(){ grep -qiF "$2" "$1" 2>/dev/null; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if ! command -v git >/dev/null 2>&1; then
  echo "git is required for these tests but was not found on PATH" >&2
  exit 6
fi

sha_of(){ sha256sum "$1" 2>/dev/null | awk '{print $1}'; }
# One field out of a stamp: `field <stamp> <name>`.
field(){ sed -n "s/^$2: //p" "$1" 2>/dev/null | head -n1; }
# Whitespace-normalised body of a file, for verbatim-quote matching across the
# LICENSE's hard-wrapped lines.
flat(){ tr '\n' ' ' < "$1" | tr -s '[:space:]' ' '; }
# Run the identity CLI. stdin is ALWAYS closed: these scripts live in
# .claude/hooks/, and a hook invoked without stdin wired inherits the caller's
# terminal and hangs the suite forever (see build_os_tests.sh section 27).
ident(){ bash "$IDENTITY_SH" "$@" < /dev/null 2>&1; }

VER="$(head -n1 "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]')"
LIC_SHA="$(sha_of "$LICENSE_FILE")"

# =============================================================== 1. source ====
echo "== 1. Source-of-truth artifacts =="
[ -n "$VER" ]     && ok "VERSION readable at source (\"$VER\")" || no "VERSION unreadable at source"
[ -n "$LIC_SHA" ] && ok "LICENSE readable at source (sha256 ${LIC_SHA:0:12})" || no "LICENSE unreadable at source"
[ -f "$IDENTITY_SH" ] && ok "the identity mechanism ships in .claude/hooks/ (installed to both scopes by the installers)" \
                      || no "missing $IDENTITY_SH — nothing stamps an installed copy"

# ====================================================== 2. fresh installs =====
echo "== 2. A fresh install produces a discoverable identity (both scopes) =="

# -- project scope: install-project.sh into a blank git repo -------------------
PROJ="$WORK/proj"; mkdir -p "$PROJ"; git -C "$PROJ" init -q 2>/dev/null
bash "$SRC/install-project.sh" --no-session-hook "$PROJ" > "$WORK/install-project.log" 2>&1
IP=$?
[ $IP -eq 0 ] && ok "install-project.sh exits 0 in a blank repo" || no "install-project.sh exited $IP (see $WORK/install-project.log)"

# -- user scope: install-global.sh into temp CLAUDE_USER_DIR + BUILD_OS_USER_DIR
GHOME="$WORK/guser"; mkdir -p "$GHOME"
GCLAUDE="$GHOME/.claude"; GBOS="$GHOME/build-os"
HOME="$GHOME" CLAUDE_USER_DIR="$GCLAUDE" BUILD_OS_USER_DIR="$GBOS" \
  bash "$SRC/install-global.sh" > "$WORK/install-global.log" 2>&1
IG=$?
[ $IG -eq 0 ] && ok "install-global.sh exits 0 into a temp user scope" || no "install-global.sh exited $IG (see $WORK/install-global.log)"

# -- memory-only scope: init-build-os.sh into a blank repo ---------------------
INITP="$WORK/initproj"; mkdir -p "$INITP"; git -C "$INITP" init -q 2>/dev/null
( cd "$INITP" && bash "$SRC/init-build-os.sh" ) > "$WORK/init.log" 2>&1
II=$?
[ $II -eq 0 ] && ok "init-build-os.sh exits 0 in a blank repo" || no "init-build-os.sh exited $II (see $WORK/init.log)"

# The five roots an install is expected to stamp.
STAMPED_ROOTS=("$PROJ/.claude" "$PROJ/build-os" "$GCLAUDE" "$GBOS" "$INITP/build-os")
FOUND=0
for r in "${STAMPED_ROOTS[@]}"; do
  if [ -f "$r/$STAMP_NAME" ]; then
    FOUND=$((FOUND+1)); ok "identity stamp present: ${r#$WORK/}/$STAMP_NAME"
  else
    no "no identity stamp at ${r#$WORK/}/$STAMP_NAME — an installed copy that cannot say what it is"
  fi
done

# VACUITY GUARD. If the scan above found nothing to check, every assertion that
# follows is vacuous and the suite would pass on an empty install. Fail loudly.
if [ "$FOUND" -ge 5 ]; then
  ok "installed-artefact scan found $FOUND stamped roots (>= 5, not vacuous)"
else
  no "installed-artefact scan found only $FOUND stamped root(s) — expected 5; the checks below have nothing to read"
fi

LIC_FOUND=0
for r in "${STAMPED_ROOTS[@]}"; do
  [ -f "$r/$LIC_COPY" ] && LIC_FOUND=$((LIC_FOUND+1))
done
if [ "$LIC_FOUND" -ge 5 ]; then
  ok "every stamped root carries the licence text ($LIC_FOUND/$FOUND copies of $LIC_COPY)"
else
  no "only $LIC_FOUND stamped root(s) carry $LIC_COPY — an installed copy with no licence beside it"
fi

# ============================================ 3. identity matches the source ==
echo "== 3. The installed identity matches VERSION and LICENSE at source =="
for r in "${STAMPED_ROOTS[@]}"; do
  s="$r/$STAMP_NAME"; short="${r#$WORK/}"
  [ -f "$s" ] || { no "cannot check $short — no stamp"; continue; }
  [ "$(field "$s" version)" = "$VER" ] \
    && ok "$short: stamp version == VERSION ($VER)" \
    || no "$short: stamp version '$(field "$s" version)' != VERSION '$VER'"
  [ "$(field "$s" license_sha256)" = "$LIC_SHA" ] \
    && ok "$short: stamp license_sha256 == sha256(LICENSE) at source" \
    || no "$short: stamp license_sha256 disagrees with LICENSE at source"
  if [ -f "$r/$LIC_COPY" ] && [ "$(sha_of "$r/$LIC_COPY")" = "$LIC_SHA" ]; then
    ok "$short: installed $LIC_COPY is byte-identical to LICENSE"
  else
    no "$short: installed $LIC_COPY differs from LICENSE (or is missing)"
  fi
  case "$(field "$s" license)" in
    *"All Rights Reserved"*) ok "$short: stamp names the licence (All Rights Reserved)" ;;
    *) no "$short: stamp does not name the licence — '$(field "$s" license)'" ;;
  esac
done

PSTAMP="$PROJ/.claude/$STAMP_NAME"
# The commit must be recorded, or "0.1.0" is a claim with nothing behind it.
SC="$(field "$PSTAMP" source_commit)"
if [ -n "$SC" ] && [ "$SC" != "unknown" ]; then
  ok "the stamp records the source commit ($SC) — version alone cannot locate the code"
else
  no "the stamp records no source commit — a version claim with no commit is unfalsifiable"
fi
HEADC="$(git -C "$SRC" rev-parse --short=12 HEAD 2>/dev/null)"
[ -n "$HEADC" ] && [ "$SC" = "$HEADC" ] \
  && ok "the recorded commit is this checkout's HEAD ($HEADC)" \
  || no "the recorded commit '$SC' is not this checkout's HEAD '$HEADC'"

# The stamp must be honest about an uncommitted source tree too.
SS="$(field "$PSTAMP" source_state)"
case "$SS" in
  clean|dirty) ok "the stamp declares the source tree state ($SS)" ;;
  *) no "the stamp declares no usable source_state ('$SS') — a build from a dirty tree must say so" ;;
esac
if [ -z "$(git -C "$SRC" status --porcelain 2>/dev/null)" ] && [ "$SS" != "clean" ]; then
  no "the source tree is clean but the stamp says '$SS'"
else
  ok "source_state agrees with the source tree (tree $( [ -z "$(git -C "$SRC" status --porcelain 2>/dev/null)" ] && echo clean || echo dirty ), stamp $SS)"
fi

# The stamp must be REPRODUCIBLE: no timestamp, no install path, so re-running an
# installer leaves the tree byte-identical (build_os_maintenance_tests.sh asserts
# exactly that for init-build-os.sh) and two machines on one commit can be diffed
# against each other. A stamp that churns on every run is a stamp people delete.
cp "$PROJ/.claude/$STAMP_NAME" "$WORK/stamp.first"
bash "$SRC/install-project.sh" --no-session-hook "$PROJ" > "$WORK/install-project2.log" 2>&1
if cmp -s "$WORK/stamp.first" "$PROJ/.claude/$STAMP_NAME"; then
  ok "re-installing produces a BYTE-IDENTICAL stamp (reproducible; no timestamp, no install path)"
else
  no "re-installing rewrote the stamp — it is not reproducible, so every re-run churns the tree"
fi
grep -qE '^(installed_at|installed_from):' "$PROJ/.claude/$STAMP_NAME" \
  && no "the stamp embeds a timestamp or an install path — that is what makes it churn" \
  || ok "the stamp embeds neither a timestamp nor an install path"

# ============================================== 4. verify passes when genuine =
echo "== 4. verify() passes on an untouched install =="
for r in "${STAMPED_ROOTS[@]}"; do
  short="${r#$WORK/}"
  out="$(ident verify "$r")"; rc=$?
  if [ $rc -eq 0 ]; then ok "$short: verify exits 0 on an untouched install"
  else no "$short: verify exited $rc on an untouched install — $(printf '%s' "$out" | tail -n1)"; fi
done
VOUT="$(ident verify "$PROJ/.claude")"
grep -q "OK" <<<"$VOUT" && ok "verify reports OK in words, not just an exit code" || no "verify prints no OK verdict"
grep -qF "$VER" <<<"$VOUT" && ok "verify prints the version" || no "verify does not print the version"
grep -qi "All Rights Reserved" <<<"$VOUT" && ok "verify prints the licence" || no "verify does not print the licence"

# ============================================== 5. DRIFT is detectable ========
echo "== 5. A drifted install is detectable and FAILS =="

# (a) Engine files from a different commit under a stamp that claims the old one.
#     This is the shape the packet names: the stamp says 0.1.0/<commit>, but the
#     files beside it are not that commit's files.
DRIFT_A="$WORK/drift_engine"; mkdir -p "$DRIFT_A"
cp -R "$PROJ/.claude/." "$DRIFT_A/"
printf '\n<!-- engine file from another commit -->\n' >> "$DRIFT_A/agents/builder.md"
out="$(ident verify "$DRIFT_A")"; rc=$?
[ $rc -ne 0 ] && ok "drift (a): verify exits non-zero when an engine file changed under the stamp" \
              || no "drift (a): verify still exited 0 after an engine file was replaced — the stamp is decoration"
grep -qi "DRIFT" <<<"$out" && ok "drift (a): verify says DRIFT" || no "drift (a): verify does not say DRIFT"
grep -qF "agents/builder.md" <<<"$out" && ok "drift (a): verify names the offending file" || no "drift (a): verify does not name the offending file"

# (b) The stamp itself hand-edited to claim a different commit. The digest covers
#     the stamp's own header, so editing the claim without recomputing is caught.
#     (Anyone CAN recompute — this is drift detection, not anti-tamper. Said so
#     plainly in docs/ENTITLEMENT.md rather than implied otherwise here.)
DRIFT_B="$WORK/drift_stamp"; mkdir -p "$DRIFT_B"
cp -R "$PROJ/.claude/." "$DRIFT_B/"
perl -pi -e 's/^source_commit: .*/source_commit: deadbeefcafe/' "$DRIFT_B/$STAMP_NAME"
grep -q "deadbeefcafe" "$DRIFT_B/$STAMP_NAME" && ok "drift (b): forged stamp written (fixture is real)" || no "drift (b): could not forge the stamp"
out="$(ident verify "$DRIFT_B")"; rc=$?
[ $rc -ne 0 ] && ok "drift (b): verify exits non-zero on a stamp whose header was edited" \
              || no "drift (b): a forged source_commit passed verification"
grep -qi "DRIFT" <<<"$out" && ok "drift (b): verify says DRIFT on a forged header" || no "drift (b): no DRIFT verdict on a forged header"

# (c) A missing stamp is reported as missing, not as OK.
DRIFT_C="$WORK/drift_missing"; mkdir -p "$DRIFT_C"
cp -R "$PROJ/.claude/." "$DRIFT_C/"
rm -f "$DRIFT_C/$STAMP_NAME"
out="$(ident verify "$DRIFT_C")"; rc=$?
[ $rc -ne 0 ] && ok "drift (c): verify exits non-zero when the stamp is absent" || no "drift (c): verify exited 0 with no stamp at all"
grep -qi "no identity stamp\|not stamped\|missing" <<<"$out" && ok "drift (c): verify says the copy is unstamped" || no "drift (c): unstamped copy not reported as such"

# (d) A deleted engine file is drift too (not just a modified one).
DRIFT_D="$WORK/drift_deleted"; mkdir -p "$DRIFT_D"
cp -R "$PROJ/.claude/." "$DRIFT_D/"
rm -f "$DRIFT_D/commands/next-packet.md"
out="$(ident verify "$DRIFT_D")"; rc=$?
[ $rc -ne 0 ] && ok "drift (d): verify exits non-zero when a stamped file was deleted" || no "drift (d): a deleted engine file passed verification"

# ====================================== 6. the session surfaces the identity ==
echo "== 6. The identity is surfaced to a session, in one line, without a human =="
HP="$PROJ/.claude/hooks/session-start-build-os.sh"
[ -x "$HP" ] && ok "the installed project carries the SessionStart hook" || no "no installed SessionStart hook to read the stamp"
PAYLOAD='{"hook_event_name":"SessionStart","session_id":"ent-suite-1"}'
HOUT="$(printf '%s' "$PAYLOAD" | TMPDIR="$WORK/t1" HOME="$GHOME" CLAUDE_PROJECT_DIR="$PROJ" bash "$HP" 2>&1)"
mkdir -p "$WORK/t1"
grep -q '^Orchestrator: ON' <<<"$HOUT" && ok "hook still leads with 'Orchestrator: ON' (unchanged contract)" || no "hook no longer leads with 'Orchestrator: ON'"
IDLINE="$(grep -m1 '^Build OS: ' <<<"$HOUT")"
[ -n "$IDLINE" ] && ok "hook emits a 'Build OS:' identity line" || no "hook emits no identity line — a session still has to ask a human"
grep -qF "v$VER" <<<"$IDLINE" && ok "identity line states the version (v$VER)" || no "identity line does not state the version"
grep -qi "All Rights Reserved" <<<"$IDLINE" && ok "identity line states the licence" || no "identity line does not state the licence"
grep -qi "identity: OK" <<<"$IDLINE" && ok "identity line reports the verification verdict (OK)" || no "identity line reports no verification verdict"
NLINES="$(grep -c '^Build OS: ' <<<"$HOUT")"
[ "${NLINES:-0}" = "1" ] && ok "exactly ONE identity line (a banner gets deleted by its owner)" || no "$NLINES identity lines — this is a banner, not a status line"
[ "${#HOUT}" -lt 12000 ] && ok "SessionStart output stays under 12KB (${#HOUT} bytes)" || no "SessionStart output too large (${#HOUT} bytes) — Claude Code discards oversized payloads"

# The same hook, over a DRIFTED install, must not keep claiming OK.
DPROJ="$WORK/driftproj"; mkdir -p "$DPROJ"
cp -R "$PROJ/." "$DPROJ/" 2>/dev/null
printf '\n<!-- other commit -->\n' >> "$DPROJ/.claude/agents/qa.md"
mkdir -p "$WORK/t2"
DOUT="$(printf '%s' '{"hook_event_name":"SessionStart","session_id":"ent-suite-2"}' \
  | TMPDIR="$WORK/t2" HOME="$GHOME" CLAUDE_PROJECT_DIR="$DPROJ" bash "$DPROJ/.claude/hooks/session-start-build-os.sh" 2>&1)"
DIDLINE="$(grep -m1 '^Build OS: ' <<<"$DOUT")"
grep -qi "DRIFT" <<<"$DIDLINE" && ok "over a drifted install the hook line says DRIFT" || no "over a drifted install the hook still reports a clean identity"
grep -qi "identity: OK" <<<"$DIDLINE" && no "the hook reports OK over a drifted install" || ok "the hook does not report OK over a drifted install"
[ "$(grep -c '^Build OS: ' <<<"$DOUT")" = "1" ] && ok "drift reporting is still one line (loud in content, not in volume)" || no "drift reporting expands into a banner"

# ================================================= 7. no network egress =======
echo "== 7. Nothing this packet adds performs network egress =="
# Files this packet owns and changed. templates/session-start-bootstrap.sh is
# DELIBERATELY EXCLUDED and named here rather than quietly skipped: it predates
# this packet and its egress is a `git clone` of the product repo itself (the
# documented web-bootstrap path), not anything this packet introduced. It is
# asserted separately below to have gained no NEW egress shape.
PACKET_FILES=(
  ".claude/hooks/build-os-identity.sh"
  ".claude/hooks/session-start-build-os.sh"
  ".claude/hooks/hook-once.sh"
  ".claude/hooks/prompt-router.sh"
  "install-global.sh" "install-project.sh" "init-build-os.sh" "connect-project.sh"
  "tests/entitlement_tests.sh"
  "docs/ENTITLEMENT.md" "README.md" "INSTALL.md"
)
# TWO exemptions, both deliberately narrow, both audited below:
#   * a line carrying `egress-scan-exempt` — the scanner's own pattern
#     definitions, which otherwise make it report itself;
#   * lines between CONTROL-FIXTURE:START/END — the planted-egress control that
#     proves the scanner can fire. It is written to a temp file and never
#     executed. Asserted below: exactly one such block, in this file only, and
#     the marker appears in no other packet file.
EGRESS_RE='curl|wget|/dev/tcp|\bnc\b|netcat|telnet|https?://|urllib|requests\.(get|post)|socket\.'  # egress-scan-exempt

# classify_egress <file> -> prints offending "path:line:text" for CODE lines only.
classify_egress() {
  local f="$1" base ext lno line skip=0
  base="$(basename "$f")"; ext="${base##*.}"
  lno=0
  while IFS= read -r line || [ -n "$line" ]; do
    lno=$((lno+1))
    case "$line" in
      *CONTROL-FIXTURE:START*) skip=1; continue ;;
      *CONTROL-FIXTURE:END*)   skip=0; continue ;;
    esac
    [ "$skip" = "1" ] && continue
    [[ "$line" =~ $EGRESS_RE ]] || continue
    case "$line" in *egress-scan-exempt*) continue ;; esac      # egress-scan-exempt
    [[ "$line" =~ ^[[:space:]]*# ]] && continue                  # shell comment = prose
    if [ "$ext" = "md" ]; then
      # Markdown is prose by definition; what would still be damning is an
      # instruction to run a transmitting command. Only those count.
      [[ "$line" =~ (curl|wget|/dev/tcp|netcat|telnet) ]] || continue   # egress-scan-exempt
    fi
    printf '%s:%s:%s\n' "$base" "$lno" "$line"
  done < "$f"
}

SCANNED=0; EGRESS_HITS=""
for rel in "${PACKET_FILES[@]}"; do
  [ -f "$SRC/$rel" ] || { no "packet file missing from the scan set: $rel"; continue; }
  SCANNED=$((SCANNED+1))
  hits="$(classify_egress "$SRC/$rel")"
  [ -n "$hits" ] && EGRESS_HITS="${EGRESS_HITS}${hits}"$'\n'
done
if [ "$SCANNED" -ge 12 ]; then
  ok "egress scan read $SCANNED packet files (>= 12, not vacuous)"
else
  no "egress scan read only $SCANNED packet file(s) — expected >= 12; its verdict below is meaningless"
fi
if [ -z "$EGRESS_HITS" ]; then
  ok "no packet file transmits anything (no client call to a remote host outside prose)"
else
  no "packet file(s) perform network egress — this product's metrics stay local and operator-owned"
  while IFS= read -r h; do [ -n "$h" ] && printf '      | %s\n' "$h"; done <<<"$EGRESS_HITS"
fi

# CONTROL-FIXTURE:START
# The scanner's own controls. Everything to the END marker is skipped when this
# suite scans ITSELF: these lines PLANT egress into a temp file to prove the
# scanner fires, and mention it in prose to prove it does not false-positive.
# Nothing here is executed and nothing here runs at install or session time.
POS="$WORK/pos_control.sh"
cat > "$POS" <<'SH'
#!/usr/bin/env bash
report() {
  curl -s -X POST https://telemetry.example.com/v1/usage -d "install=$1"
}
SH
[ -n "$(classify_egress "$POS")" ] && ok "egress scanner FIRES on a planted telemetry curl (positive control)" \
                                   || no "egress scanner stayed silent on a planted curl — it has gone blind"
NEG="$WORK/neg_control.sh"
cat > "$NEG" <<'SH'
#!/usr/bin/env bash
# This tool never calls curl, wget, or https://anything — no phone-home by design.
echo "local only"
SH
[ -z "$(classify_egress "$NEG")" ] && ok "egress scanner stays silent on a comment mentioning curl (negative control)" \
                                   || no "egress scanner false-positives on prose"
# CONTROL-FIXTURE:END

# The control block is bounded and unique: exactly one marker LINE of each kind
# (counted as whole lines, so the case arms that read the markers do not count).
CF_START="$(grep -cE '^# CONTROL-FIXTURE:START$' "$SRC/tests/entitlement_tests.sh")"
CF_END="$(grep -cE '^# CONTROL-FIXTURE:END$' "$SRC/tests/entitlement_tests.sh")"
[ "$CF_START" = "1" ] && [ "$CF_END" = "1" ] \
  && ok "exactly one bounded control-fixture block (1 START line, 1 END line)" \
  || no "control-fixture markers are unbalanced or duplicated (START=$CF_START END=$CF_END) — the skip region is not bounded"
CF_ELSEWHERE=0
for rel in "${PACKET_FILES[@]}"; do
  [ "$rel" = "tests/entitlement_tests.sh" ] && continue
  grep -q 'CONTROL-FIXTURE:\|egress-scan-exempt' "$SRC/$rel" 2>/dev/null && CF_ELSEWHERE=$((CF_ELSEWHERE+1))
done
[ "$CF_ELSEWHERE" = "0" ] && ok "no other packet file carries a scanner exemption marker (they cannot opt out of the scan)" \
                          || no "$CF_ELSEWHERE packet file(s) carry an exemption marker — egress can now hide behind it"

# The pre-existing bootstrap: still exactly one egress site, still a git clone of
# the product repo, still not telemetry.
BOOT="$SRC/templates/session-start-bootstrap.sh"
BOOT_HITS="$(classify_egress "$BOOT" | wc -l | tr -d ' ')"
[ "${BOOT_HITS:-0}" -le 1 ] && ok "the excluded bootstrap still has <= 1 egress site (it gained none)" \
                            || no "the bootstrap gained egress sites ($BOOT_HITS) — it is excluded from the scan, so this is the only guard"
grep -qE '\b(telemetry|analytics|phone.?home|usage.?report|activate|activation|license.?key|licence.?key)\b' "$BOOT" \
  && no "the bootstrap mentions telemetry/activation/licence keys — out of scope for this product" \
  || ok "the bootstrap carries no telemetry/activation/licence-key machinery"
# And the mechanism this packet actually adds must be self-evidently offline.
# CODE lines only: its header comment says the words "telemetry", "licence key"
# and "activation" precisely to state that it does none of them, and a scan that
# punished the disclaimer would push the disclaimer out of the file.
grep -vE '^[[:space:]]*#' "$IDENTITY_SH" \
  | grep -qE '(telemetry|phone.?home|license.?key|licence.?key|activation.?server|entitlement.?server)' \
  && no "the identity mechanism has key/activation/telemetry machinery in CODE — the wrong branch" \
  || ok "the identity mechanism has no key/activation/telemetry machinery in code (only the disclaimer in its header)"
grep -qiE 'no licence key|never transmits|no server' "$IDENTITY_SH" \
  && ok "the identity mechanism's header states plainly that it never transmits" \
  || no "the identity mechanism does not state its offline boundary"
# A hygiene bound, not the security boundary — the real guard is the assertion
# above that NO OTHER packet file may carry the marker at all. This one just
# keeps the scanner's self-exemptions from quietly multiplying inside the suite.
EXEMPT_COUNT="$(grep -c 'egress-scan-exempt' "$SRC/tests/entitlement_tests.sh")"
[ "${EXEMPT_COUNT:-99}" -le 8 ] && ok "the scanner's self-exemption marker is used $EXEMPT_COUNT times inside the suite (<= 8)" \
                                || no "the exemption marker is used $EXEMPT_COUNT times — it has become a way to hide egress"

# ============================ 8. README / INSTALL state the position early ====
echo "== 8. README.md and INSTALL.md state the proprietary, access-gated position =="
for f in "$README" "$INSTALL"; do
  b="$(basename "$f")"
  head -n 45 "$f" > "$WORK/head_$b"
  havei "$WORK/head_$b" "proprietary" && ok "$b says 'proprietary' in the first 45 lines" || no "$b does not say 'proprietary' early — a stranger reads it as open source"
  havei "$WORK/head_$b" "All Rights Reserved" && ok "$b says 'All Rights Reserved' in the first 45 lines" || no "$b does not say 'All Rights Reserved' early"
  grep -qiE "not open source|is not open[- ]source" "$WORK/head_$b" && ok "$b states plainly that it is NOT open source" || no "$b never says it is not open source"
  grep -qiE "access[- ]gated|granted access|access is granted" "$WORK/head_$b" && ok "$b states that access is granted, not open" || no "$b does not state the access-gated position"
  have "$f" "docs/ENTITLEMENT.md" && ok "$b points at docs/ENTITLEMENT.md" || no "$b does not point at the entitlement doc"
  have "$f" "LICENSE" && ok "$b points at LICENSE" || no "$b does not point at LICENSE"
done
# The trap this packet exists to close: visibility read as permission. Wherever
# either file says the repo is public/visible, it must also carry the LICENSE's
# own words that visibility is not a licence.
for f in "$README" "$INSTALL"; do
  b="$(basename "$f")"
  grep -qiE "is not a licen[cs]e" "$f" \
    && ok "$b states outright that being able to see/clone the repo is not a licence" \
    || no "$b never says that access/visibility is not a licence — the exact mismatch legal review catches"
  if grep -qiE '\bpublic\b|\bvisible\b|no credentials' "$f"; then
    grep -qiE "is not a licen[cs]e" "$f" \
      && ok "$b qualifies its 'public/visible/no credentials' claim in the same file" \
      || no "$b says the repo is public/visible and leaves it unqualified"
  else
    ok "$b makes no unqualified public/visible claim"
  fi
done

# ================================= 9. ENTITLEMENT.md matches the LICENSE ======
echo "== 9. docs/ENTITLEMENT.md exists and does not drift from LICENSE =="
if [ -f "$ENTITLEMENT" ]; then
  ok "docs/ENTITLEMENT.md exists"
else
  no "docs/ENTITLEMENT.md is missing — the buyer has no answer to 'what am I paying for?'"
fi

for h in \
  "## What you are buying" \
  "## What access grants" \
  "## What the licence permits" \
  "## What the licence forbids" \
  "## Teams, seats, and organisations" \
  "## How to verify an installed copy is genuine" \
  "## What is NOT enforced technically" \
  "## What the LICENSE leaves ambiguous" \
  "## If your access ends" ; do
  have "$ENTITLEMENT" "$h" && ok "ENTITLEMENT.md has the section: ${h#\#\# }" || no "ENTITLEMENT.md is missing the section: ${h#\#\# }"
done

# (a) Verbatim quotes. The doc quotes LICENSE between markers; every quoted line
#     must appear in LICENSE, whitespace-normalised (LICENSE is hard-wrapped).
#     This is the drift check that matters: change the licence to BSL or dual and
#     this goes red until the buyer-facing doc is updated with it.
QUOTE="$WORK/quote.txt"
awk '/<!-- LICENSE-QUOTE:START -->/{f=1;next} /<!-- LICENSE-QUOTE:END -->/{f=0} f' "$ENTITLEMENT" \
  | sed -e 's/^> //' -e 's/^>$//' | grep -v '^[[:space:]]*$' > "$QUOTE" 2>/dev/null
QLINES="$(grep -c . "$QUOTE" 2>/dev/null)"; QLINES="${QLINES:-0}"
if [ "$QLINES" -ge 3 ]; then
  ok "ENTITLEMENT.md quotes $QLINES line(s) of LICENSE between markers (>= 3, not vacuous)"
else
  no "ENTITLEMENT.md quotes only $QLINES line(s) of LICENSE — the verbatim drift check below has nothing to compare"
fi
LIC_FLAT="$(flat "$LICENSE_FILE")"
QBAD=""
while IFS= read -r q; do
  [ -n "$q" ] || continue
  qn="$(printf '%s' "$q" | tr -s '[:space:]' ' ')"
  qn="${qn#"${qn%%[![:space:]]*}"}"; qn="${qn%"${qn##*[![:space:]]}"}"
  case "$LIC_FLAT" in *"$qn"*) : ;; *) QBAD="${QBAD}${q}"$'\n' ;; esac
done < "$QUOTE"
if [ -z "$QBAD" ]; then
  ok "every line ENTITLEMENT.md quotes appears VERBATIM in LICENSE"
else
  no "ENTITLEMENT.md quotes text that is NOT in LICENSE — the doc a buyer reads has drifted from the licence they are bound by"
  while IFS= read -r q; do [ -n "$q" ] && printf '      | %s\n' "$q"; done <<<"$QBAD"
fi

# (b) The doc must not grant what the LICENSE does not.
#
#     Scan A is ADJACENCY-NEGATED rather than line-filtered: "you may not
#     redistribute" cannot match, because `not` sits between the modal and the
#     verb. That matters — a whole-line negation filter would have swallowed the
#     positive control below ("...at no charge") and passed an invented grant.
#     Scan B (a bare "grants you a perpetual licence") has no such adjacency, so
#     it keeps a narrow negation filter.
GRANT_A_RE='(you|licensee|customer|the buyer)[[:space:]]+(may|can|are[[:space:]]+(free|permitted|entitled))[[:space:]]+(to[[:space:]]+)?(copy|modify|adapt|redistribute|distribute|sublicense|sub-licence|sell|resell|relicense|fork|publish|share|host|embed)'
GRANT_B_RE='(is|are)[[:space:]]+(open[- ]source|freely[[:space:]]+available|royalty[- ]free|public[- ]domain)|grants?[[:space:]]+(you|the[[:space:]]+(customer|licensee))[[:space:]]+(a[[:space:]]+)?(perpetual|irrevocable|worldwide|royalty[- ]free|unlimited)'
NEG_B_RE='\b(not|never|no|nothing|neither|nor)\b'
scan_grants(){
  { grep -Ein "$GRANT_A_RE" "$1" 2>/dev/null
    grep -Ein "$GRANT_B_RE" "$1" 2>/dev/null | grep -Eiv "$NEG_B_RE"
  } | sort -u
}
GRANTS="$(scan_grants "$ENTITLEMENT")"
if [ -z "$GRANTS" ]; then
  ok "ENTITLEMENT.md grants no permission the LICENSE withholds"
else
  no "ENTITLEMENT.md asserts a permission the LICENSE does not grant"
  printf '      | %s\n' "$GRANTS"
fi
# The grant scanner's own controls.
GF_BAD="$WORK/bad_entitlement.md"
cat > "$GF_BAD" <<'MD'
# Entitlement
You may redistribute the Software to your own customers at no charge.
MD
GF_GOOD="$WORK/good_entitlement.md"
cat > "$GF_GOOD" <<'MD'
# Entitlement
You may not redistribute the Software, and nothing here is open source.
MD
[ -n "$(scan_grants "$GF_BAD")" ] && ok "grant scanner FIRES on a fixture granting redistribution (positive control)" \
                                  || no "grant scanner stayed silent on an invented redistribution grant — it has gone blind"
[ -z "$(scan_grants "$GF_GOOD")" ] && ok "grant scanner stays silent on honest 'you may not' wording (no false positive)" \
                                   || no "grant scanner false-positives on the wording it exists to permit"

# (c) The claims the doc MUST make, each traceable to LICENSE.
havei "$ENTITLEMENT" "All Rights Reserved" && ok "ENTITLEMENT.md names the licence: All Rights Reserved" || no "ENTITLEMENT.md does not name the licence"
have  "$ENTITLEMENT" "Samuel Kestenbaum"   && ok "ENTITLEMENT.md names the same rights holder as LICENSE" || no "ENTITLEMENT.md names no rights holder"
have  "$LICENSE_FILE" "Samuel Kestenbaum"  && ok "LICENSE names that rights holder too (cross-checked)"   || no "LICENSE does not name Samuel Kestenbaum"
grep -qiE "signed written agreement|separate written commercial agreement|written agreement signed" "$ENTITLEMENT" \
  && ok "ENTITLEMENT.md states that rights come only from a signed written agreement" \
  || no "ENTITLEMENT.md does not condition rights on a signed agreement — the LICENSE does"
# What is NOT enforced. This is the section that buys credibility.
for term in "no licence key" "no telemetry" "does not phone home"; do
  havei "$ENTITLEMENT" "$term" && ok "ENTITLEMENT.md states plainly: $term" || no "ENTITLEMENT.md does not state: $term"
done
grep -qiE "repository access|access to the repository" "$ENTITLEMENT" \
  && ok "ENTITLEMENT.md identifies repository access as the entitlement mechanism" \
  || no "ENTITLEMENT.md does not say what the entitlement mechanism actually is"
# Ambiguity must be FLAGGED, not invented. LICENSE says nothing about seats.
grep -qiE "per[- ]seat|per seat|per[- ]org" "$LICENSE_FILE" \
  && no "LICENSE now carries seat/org terms — ENTITLEMENT.md's ambiguity section is stale" \
  || ok "LICENSE carries no seat/org terms (so the doc must flag it, not invent them)"
grep -qiE "silent|does not say|leaves .* (open|undefined|unspecified)" "$ENTITLEMENT" \
  && ok "ENTITLEMENT.md flags what the LICENSE leaves undetermined instead of inventing terms" \
  || no "ENTITLEMENT.md invents or assumes terms the LICENSE never states"
if grep -qiE "per[- ]seat|per seat" "$ENTITLEMENT"; then
  awk '/^## Teams, seats, and organisations/{f=1;next} f&&/^## /{exit} f' "$ENTITLEMENT" \
    | grep -qiE "silent|does not say|signed .*agreement" \
    && ok "the seats section attributes seat terms to the signed agreement, not to LICENSE" \
    || no "the seats section states seat terms as if LICENSE set them — LICENSE is silent on seats"
else
  ok "ENTITLEMENT.md does not raise per-seat terms at all"
fi
# The doc must describe the identity mechanism it is paired with.
have "$ENTITLEMENT" "build-os-identity" && ok "ENTITLEMENT.md documents the identity stamp by name" || no "ENTITLEMENT.md does not document how to verify a copy"
have "$ENTITLEMENT" "BUILD-OS-LICENSE"  && ok "ENTITLEMENT.md documents the installed licence copy by name" || no "ENTITLEMENT.md does not name the installed licence copy"
# And it must not overclaim the stamp as anti-tamper.
grep -qiE "tamper[- ]proof|cannot be forged|unforgeable|prevents (use|piracy)|DRM protects" "$ENTITLEMENT" \
  && no "ENTITLEMENT.md overclaims the stamp as tamper-proof/DRM — it is drift detection, and anyone can recompute it" \
  || ok "ENTITLEMENT.md does not overclaim the stamp as tamper-proof"

echo
echo "==== RESULT: $PASS passed, $FAIL failed ===="
[ "$FAIL" -eq 0 ]
