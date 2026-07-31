#!/usr/bin/env bash
# Build OS — installed-copy IDENTITY: stamp, verify, and one-line report.
#
# WHAT THIS IS FOR
#   An installed copy of the Build OS must be able to say, with no human in the
#   loop, WHICH VERSION and WHICH LICENCE it is running under. `VERSION` and
#   `LICENSE` exist at source; this is what makes that identity survive
#   installation into ~/.claude, ~/build-os, and a project's .claude/ + build-os/.
#
# WHAT IT IS NOT
#   Not a licence key. Not activation. Not telemetry, metering, or expiry. It
#   NEVER transmits anything and never fails because a server was unreachable —
#   there is no server. Paid access to the private repository IS the entitlement;
#   see docs/ENTITLEMENT.md. This file only answers "what am I, and did anything
#   drift since install?"
#
# THE HONESTY REQUIREMENT
#   A stamp that says 0.1.0 next to engine files from another commit is worse
#   than no stamp at all. So the stamp records the source commit AND a sha256 of
#   every file the installer placed, and the stamp's own header is covered by a
#   digest. Change a stamped file, delete one, or hand-edit the header, and
#   `verify` exits non-zero and says DRIFT.
#
#   This is DRIFT DETECTION, NOT ANTI-TAMPER. There is no secret and no
#   signature, so anyone determined can recompute a consistent stamp. It catches
#   the failure that actually happens — half-upgraded installs, hand-patched
#   engine files, a stamp copied next to somebody else's code — and it is
#   described that way in docs/ENTITLEMENT.md rather than dressed up as DRM.
#
# USAGE
#   stamp   bash build-os-identity.sh stamp --source SRC --root ROOT \
#                 --scope user|project [--] rel/path ...
#           Copies SRC/LICENSE to ROOT/BUILD-OS-LICENSE and writes
#           ROOT/build-os-identity covering it plus every rel/path given.
#   verify  bash build-os-identity.sh verify [ROOT|STAMP_FILE]
#           exit 0 = verified, 1 = drift, 2 = no stamp / unusable.
#   line    bash build-os-identity.sh line [ROOT ...]
#           One line for a session banner. Always exits 0 — a status line must
#           never be able to break a session start.
#
# Never reads stdin. Offline. Deterministic.
set -uo pipefail

BOSI_STAMP_NAME="build-os-identity"
BOSI_LICENSE_COPY="BUILD-OS-LICENSE"
BOSI_FORMAT="build-os-identity/1"
BOSI_LICENSE_LABEL="Proprietary - All Rights Reserved (no rights granted without a signed written agreement)"

_bosi_self_dir(){ cd "$(dirname "${BASH_SOURCE[0]}")" && pwd; }

_bosi_sha_file() {
  [ -f "$1" ] || return 1
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" 2>/dev/null | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" 2>/dev/null | awk '{print $1}'
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],"rb").read()).hexdigest())' "$1" 2>/dev/null
  else
    return 1
  fi
}

# The digest covers the whole stamp EXCEPT its own `digest:` line, so the header
# claims (version, commit, licence sha) are inside it. Removing that one line
# reproduces the payload byte-for-byte.
_bosi_payload_digest() {
  local stamp="$1" tmp rc
  tmp="$(mktemp)" || return 1
  grep -v '^digest: ' "$stamp" > "$tmp" 2>/dev/null
  _bosi_sha_file "$tmp"; rc=$?
  rm -f "$tmp"
  return $rc
}

_bosi_field(){ sed -n "s/^$2: //p" "$1" 2>/dev/null | head -n1; }

# ------------------------------------------------------------------- stamp ---
bosi_stamp() {
  local source="" root="" scope="unknown" rels=()
  while [ $# -gt 0 ]; do
    case "$1" in
      --source) source="$2"; shift 2 ;;
      --root)   root="$2";   shift 2 ;;
      --scope)  scope="$2";  shift 2 ;;
      --)       shift; break ;;
      *)        break ;;
    esac
  done
  rels=("$@")

  [ -n "$source" ] && [ -d "$source" ] || { echo "identity: --source is missing or not a directory" >&2; return 2; }
  [ -n "$root" ]   && [ -d "$root" ]   || { echo "identity: --root is missing or not a directory" >&2; return 2; }
  [ -f "$source/VERSION" ] || { echo "identity: no VERSION at $source" >&2; return 2; }
  [ -f "$source/LICENSE" ] || { echo "identity: no LICENSE at $source" >&2; return 2; }

  local version license_sha
  version="$(head -n1 "$source/VERSION" | tr -d '\r' | tr -d '[:space:]')"
  [ -n "$version" ] || { echo "identity: VERSION is empty at $source" >&2; return 2; }

  # The licence travels with the copy. Byte-identical, so its sha is checkable
  # against the source in both directions.
  cp "$source/LICENSE" "$root/$BOSI_LICENSE_COPY" || return 2
  license_sha="$(_bosi_sha_file "$root/$BOSI_LICENSE_COPY")" || {
    echo "identity: no usable sha256 tool (sha256sum / shasum / python3)" >&2; return 3; }

  local commit="unknown" state="unknown"
  if command -v git >/dev/null 2>&1 && git -C "$source" rev-parse --git-dir >/dev/null 2>&1; then
    commit="$(git -C "$source" rev-parse --short=12 HEAD 2>/dev/null)"
    [ -n "$commit" ] || commit="unknown"
    if [ -z "$(git -C "$source" status --porcelain 2>/dev/null)" ]; then state="clean"; else state="dirty"; fi
  fi

  # BUILD-OS-LICENSE is always covered; the caller's paths follow, sorted, so the
  # stamp is reproducible regardless of glob order.
  local all=("$BOSI_LICENSE_COPY") r
  for r in "${rels[@]:-}"; do [ -n "$r" ] && all+=("$r"); done

  local files_block="" count=0 sha
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    sha="$(_bosi_sha_file "$root/$r")" || { echo "identity: cannot hash $root/$r" >&2; return 3; }
    files_block="${files_block}${sha}  ${r}"$'\n'
    count=$((count+1))
  done < <(printf '%s\n' "${all[@]}" | sort -u)

  [ "$count" -ge 1 ] || { echo "identity: refusing to write a stamp covering zero files" >&2; return 3; }

  local header
  header="# ClaudeOrchestrator - Build OS: installed-copy identity (machine-readable).
# WHAT THIS PROVES: this copy's version and licence, and that the files listed
# below are byte-for-byte the ones the installer placed. WHAT IT DOES NOT PROVE:
# that you are licensed to run it. That comes from a signed written agreement -
# see $BOSI_LICENSE_COPY beside this file, and docs/ENTITLEMENT.md in the repo.
# Verify:  bash <this-root>/.claude/hooks/build-os-identity.sh verify <this-root>
# Drift detection only: no secret, no signature, no network, no licence key.
# REPRODUCIBLE: this file carries no timestamp and no install path, so the same
# source commit always stamps to the same bytes - re-running an installer leaves
# the tree byte-identical, and two machines on one commit can be diffed directly.
format: $BOSI_FORMAT
product: ClaudeOrchestrator (Build OS for Claude Code)
version: $version
source_commit: $commit
source_state: $state
license: $BOSI_LICENSE_LABEL
license_file: $BOSI_LICENSE_COPY
license_sha256: $license_sha
scope: $scope
file_count: $count
"
  local body="files:
${files_block}"

  local tmp digest
  tmp="$(mktemp)" || return 3
  printf '%s%s' "$header" "$body" > "$tmp"
  digest="$(_bosi_sha_file "$tmp")"; rm -f "$tmp"
  [ -n "$digest" ] || { echo "identity: could not compute the stamp digest" >&2; return 3; }

  printf '%sdigest: %s\n%s' "$header" "$digest" "$body" > "$root/$BOSI_STAMP_NAME" || return 3
  echo "  + identity stamp: $root/$BOSI_STAMP_NAME (v$version, $commit, $count files) + $BOSI_LICENSE_COPY"
  return 0
}

# ------------------------------------------------------------------ verify ---
# Sets BOSI_V_* for reuse by `line`. Returns 0 ok / 1 drift / 2 no stamp.
_bosi_check() {
  local target="$1" stamp root
  if [ -f "$target" ]; then
    stamp="$target"; root="$(cd "$(dirname "$target")" && pwd)"
  elif [ -d "$target" ] && [ -f "$target/$BOSI_STAMP_NAME" ]; then
    stamp="$target/$BOSI_STAMP_NAME"; root="$(cd "$target" && pwd)"
  else
    BOSI_V_REASON="no identity stamp found at $target (this copy is not stamped)"
    return 2
  fi

  BOSI_V_ROOT="$root"
  BOSI_V_STAMP="$stamp"
  BOSI_V_VERSION="$(_bosi_field "$stamp" version)"
  BOSI_V_COMMIT="$(_bosi_field "$stamp" source_commit)"
  BOSI_V_STATE="$(_bosi_field "$stamp" source_state)"
  BOSI_V_LICENSE="$(_bosi_field "$stamp" license)"
  BOSI_V_SCOPE="$(_bosi_field "$stamp" scope)"
  BOSI_V_PROBLEMS=""
  BOSI_V_CHECKED=0
  BOSI_V_TOTAL="$(_bosi_field "$stamp" file_count)"
  BOSI_V_HEADER="OK"

  if [ "$(_bosi_field "$stamp" format)" != "$BOSI_FORMAT" ]; then
    BOSI_V_REASON="unreadable stamp format at $stamp"
    return 2
  fi

  local want got
  want="$(_bosi_field "$stamp" digest)"
  got="$(_bosi_payload_digest "$stamp")"
  if [ -z "$want" ] || [ -z "$got" ]; then
    BOSI_V_REASON="the stamp carries no usable digest"
    return 2
  fi
  if [ "$want" != "$got" ]; then
    BOSI_V_HEADER="DRIFT"
    BOSI_V_PROBLEMS="${BOSI_V_PROBLEMS}DRIFT: the stamp's own header does not match its digest - the version/commit/licence claim was edited after install"$'\n'
  fi

  local line sha rel actual
  while IFS= read -r line; do
    case "$line" in ''|'#'*) continue ;; esac
    sha="${line%% *}"; rel="${line#*  }"
    [ -n "$rel" ] && [ "$rel" != "$line" ] || continue
    BOSI_V_CHECKED=$((BOSI_V_CHECKED+1))
    if [ ! -f "$root/$rel" ]; then
      BOSI_V_PROBLEMS="${BOSI_V_PROBLEMS}DRIFT: $rel is stamped but MISSING from this install"$'\n'
      continue
    fi
    actual="$(_bosi_sha_file "$root/$rel")"
    if [ -z "$actual" ]; then
      BOSI_V_PROBLEMS="${BOSI_V_PROBLEMS}DRIFT: $rel could not be hashed"$'\n'
    elif [ "$actual" != "$sha" ]; then
      BOSI_V_PROBLEMS="${BOSI_V_PROBLEMS}DRIFT: $rel differs from the stamp (this file is not the one v${BOSI_V_VERSION} / ${BOSI_V_COMMIT} installed)"$'\n'
    fi
  done < <(sed -n '/^files:$/,$p' "$stamp" | tail -n +2)

  if [ "$BOSI_V_CHECKED" = "0" ]; then
    BOSI_V_REASON="the stamp lists no files - nothing to verify"
    return 2
  fi
  if [ "$BOSI_V_CHECKED" != "${BOSI_V_TOTAL:-0}" ]; then
    BOSI_V_PROBLEMS="${BOSI_V_PROBLEMS}DRIFT: the stamp claims ${BOSI_V_TOTAL:-?} files but lists $BOSI_V_CHECKED"$'\n'
  fi

  BOSI_V_FAILED="$(printf '%s' "$BOSI_V_PROBLEMS" | grep -c '^DRIFT:')"
  [ -z "$BOSI_V_PROBLEMS" ]
}

bosi_verify() {
  local target="${1:-}"
  if [ -z "$target" ]; then target="$(cd "$(_bosi_self_dir)/.." && pwd)"; fi
  _bosi_check "$target"; local rc=$?
  if [ $rc -eq 2 ]; then
    echo "Build OS identity: ${BOSI_V_REASON:-unusable}"
    echo "RESULT: UNVERIFIED - re-run the installer to stamp this copy."
    return 2
  fi
  echo "Build OS installed-copy identity - $BOSI_V_ROOT"
  echo "  version:        $BOSI_V_VERSION"
  echo "  source commit:  $BOSI_V_COMMIT ($BOSI_V_STATE)"
  echo "  licence:        $BOSI_V_LICENSE"
  echo "  licence file:   $BOSI_LICENSE_COPY"
  echo "  scope:          $BOSI_V_SCOPE"
  echo "  stamped files:  $BOSI_V_CHECKED"
  if [ $rc -eq 0 ]; then
    echo "RESULT: OK - identity verified ($BOSI_V_CHECKED/$BOSI_V_CHECKED files match the stamp)."
    echo "NOTE: this proves what this copy IS, not that you are licensed to run it."
    return 0
  fi
  printf '%s' "$BOSI_V_PROBLEMS"
  echo "RESULT: DRIFT - this copy does not match its own stamp. Re-run the installer."
  return 1
}

# -------------------------------------------------------------------- line ---
bosi_line() {
  local root
  for root in "$@"; do
    [ -n "$root" ] || continue
    [ -f "$root/$BOSI_STAMP_NAME" ] || continue
    _bosi_check "$root"; local rc=$?
    if [ $rc -eq 0 ]; then
      echo "Build OS: v$BOSI_V_VERSION ($BOSI_V_COMMIT, $BOSI_V_STATE) - licence: Proprietary, All Rights Reserved (access-gated) - identity: OK ($BOSI_V_CHECKED/$BOSI_V_CHECKED files verified, $BOSI_V_SCOPE scope)"
    elif [ $rc -eq 1 ]; then
      echo "Build OS: v$BOSI_V_VERSION ($BOSI_V_COMMIT, $BOSI_V_STATE) - licence: Proprietary, All Rights Reserved (access-gated) - identity: DRIFT ($BOSI_V_FAILED problem(s); this copy is not what its stamp claims - re-run the installer, then trust nothing else it says)"
    else
      echo "Build OS: identity stamp unreadable at $root - licence: see $BOSI_LICENSE_COPY - re-run the installer"
    fi
    return 0
  done

  # Not an installed copy. The source checkout can still identify itself from
  # VERSION + LICENSE, which is honest: it says "source checkout", not "verified".
  local repo; repo="$(cd "$(_bosi_self_dir)/../.." 2>/dev/null && pwd)"
  if [ -n "$repo" ] && [ -f "$repo/VERSION" ] && [ -f "$repo/LICENSE" ]; then
    echo "Build OS: v$(head -n1 "$repo/VERSION" | tr -d '[:space:]') (source checkout, unstamped) - licence: Proprietary, All Rights Reserved (access-gated) - identity: not an installed copy"
    return 0
  fi
  echo "Build OS: version unknown - licence: see LICENSE - identity: no stamp found (run install-project.sh to stamp this copy)"
  return 0
}

# Only act when EXECUTED; when sourced (by the SessionStart hook) it just
# defines the functions above.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  cmd="${1:-verify}"; shift 2>/dev/null || true
  case "$cmd" in
    stamp)  bosi_stamp "$@" ;;
    verify) bosi_verify "${1:-}" ;;
    line)   bosi_line "$@" ;;
    *) echo "usage: build-os-identity.sh {stamp|verify|line} ..." >&2; exit 64 ;;
  esac
  exit $?
fi
