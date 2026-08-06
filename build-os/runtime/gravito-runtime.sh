#!/usr/bin/env bash
# gravito-runtime.sh — versioned installer for the Gravito routing runtime.
#
# Product need (operator's words): "The customer should not manually copy five
# scripts and several contracts." This turns the copied-install pattern proven
# in the empathiq pilot (5 executables byte-identical + 3 contracts with
# installed-copy headers + settings.json wiring + .gitignore stanza) into a
# versioned, installable runtime.
#
# Subcommands:
#   version                       self-check canonical files vs MANIFEST.json
#   install   <target-repo>       no-overwrite install (idempotent on identical)
#   status    <target-repo>       per-file: current | drifted-local | upgrade-available
#   upgrade   <target-repo> [--force-theirs]   explicit only; backs up before force
#   rollback  <target-repo>       restore from the most recent backup dir
#   uninstall <target-repo>       remove ONLY our files + our settings entries
#   regen-manifest --version <v>  cut a new release manifest from canonical tree
#
# Dependencies: bash, node, git, coreutils. Nothing else. Never pushes,
# never touches anything outside the named target repo.
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CANON="$(cd "$DIR/../.." && pwd)"
MANIFEST="$DIR/MANIFEST.json"
MJS="$DIR/runtime-json.mjs"
NODE="${NODE_BIN:-node}"

die(){ echo "gravito-runtime: $*" >&2; exit 1; }
sha(){ sha256sum "$1" | awk '{print $1}'; }
body_sha(){ sed '1,2d' "$1" | sha256sum | awk '{print $1}'; }  # below installed-copy header
now_date(){ date +%Y-%m-%d; }
now_ts(){ date +%Y%m%d-%H%M%S; }
git_commit(){ git -C "$CANON" rev-parse --short HEAD 2>/dev/null || echo unknown; }
git_branch(){ git -C "$CANON" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown; }
mversion(){ "$NODE" "$MJS" get "$MANIFEST" version; }

resolve_target(){
  local t="${1:-}"
  [ -n "$t" ] || die "usage: $CMD <target-repo>"
  [ -d "$t" ] || die "target is not a directory: $t"
  t="$(cd "$t" && pwd)"
  [ "$t" != "$CANON" ] || die "refusing to operate on the canonical repo itself"
  echo "$t"
}

header_line(){ # $1 version, $2 commit, $3 branch, $4 date, $5 target basename
  printf '> **INSTALLED COPY** — native Gravito runtime install in this target repo (%s). Authoritative source: the ClaudeOrchestrator repository, Gravito runtime v%s; copied from source commit %s (branch %s) on %s. These installed copies do NOT auto-update; drift from the source is expected until deliberately re-synced with `gravito-runtime.sh upgrade`. Re-sync from source rather than editing here.\n' \
    "$5" "$1" "$2" "$3" "$4"
}

write_file(){ # $1 source abs, $2 target abs, $3 mode, $4 header(0|1), $5 ver, $6 commit, $7 branch, $8 date, $9 tbase
  mkdir -p "$(dirname "$2")"
  if [ "$4" = "1" ]; then
    { header_line "$5" "$6" "$7" "$8" "$9"; echo; cat "$1"; } > "$2"
  else
    cp "$1" "$2"
  fi
  [ "$3" = "executable" ] && chmod +x "$2"
  return 0
}

# Existing target file compatible with canonical content msha?  echoes 1/0.
existing_matches(){ # $1 target file, $2 header flag, $3 manifest sha
  local first
  if [ "$2" = "1" ]; then
    first="$(head -n1 "$1")"
    case "$first" in
      '> **INSTALLED COPY**'*) [ "$(body_sha "$1")" = "$3" ] && { echo 1; return; } ;;
      *)                       [ "$(sha "$1")"      = "$3" ] && { echo 1; return; } ;;
    esac
  else
    [ "$(sha "$1")" = "$3" ] && { echo 1; return; }
  fi
  echo 0
}

verify_canonical_clean(){ # die unless every canonical file matches MANIFEST
  while IFS=$'\t' read -r src inst mode header msha; do
    [ -f "$CANON/$src" ] || die "canonical source missing: $src (run 'version')"
    [ "$(sha "$CANON/$src")" = "$msha" ] \
      || die "canonical $src no longer matches MANIFEST.json — refusing to ship unversioned content (run 'version', then 'regen-manifest' to cut a release)"
  done < <("$NODE" "$MJS" files "$MANIFEST")
}

uniq_path(){ # $1 dir, $2 stem, $3 ext — first non-existing "$1/$2.$3", -2, -3...
  local p="$1/$2.$3" n=2
  while [ -e "$p" ]; do p="$1/$2-$n.$3"; n=$((n+1)); done
  echo "$p"
}

write_receipt(){ # $1 target, $2 action, $3 from, $4 to, stdin: TSV fileAction\tpath
  local rdir="$1/build-os/runtime/receipts" out
  mkdir -p "$rdir"
  out="$(uniq_path "$rdir" "$2-$(now_ts)" json)"
  "$NODE" "$MJS" receipt "$out" "$2" "$(mversion)" "$3" "$4" \
    "$(git_commit)" "$(git_branch)" "$(now_date)"
  echo "receipt: $out"
}

write_installed_version(){ # $1 target — record on-disk truth for every manifest file
  local t="$1" iv="$1/build-os/runtime/INSTALLED_VERSION.json"
  mkdir -p "$(dirname "$iv")"
  while IFS=$'\t' read -r src inst mode header msha; do
    printf '%s\t%s\t%s\t%s\t%s\n' "$inst" "$mode" "$header" "$(sha "$t/$inst")" "$msha"
  done < <("$NODE" "$MJS" files "$MANIFEST") \
    | "$NODE" "$MJS" installed-write "$iv" "$(mversion)" "$(git_commit)" "$(git_branch)" "$(now_date)"
  echo "recorded: $iv"
}

# ---------------------------------------------------------------- version
cmd_version(){
  [ -f "$MANIFEST" ] || die "no MANIFEST.json at $MANIFEST"
  echo "gravito-runtime v$(mversion) (canonical root: $CANON)"
  local dirty=0 a
  while IFS=$'\t' read -r src inst mode header msha; do
    if [ ! -f "$CANON/$src" ]; then
      echo "  MISSING  $src"; dirty=1; continue
    fi
    a="$(sha "$CANON/$src")"
    if [ "$a" = "$msha" ]; then
      echo "  ok     $a  $src"
    else
      echo "  DIRTY  $a  $src (manifest: $msha)"; dirty=1
    fi
  done < <("$NODE" "$MJS" files "$MANIFEST")
  if [ "$dirty" = 1 ]; then
    echo "RUNTIME: DIRTY — canonical files no longer match MANIFEST.json; run 'regen-manifest --version <v>' to cut a release"
    exit 2
  fi
  echo "RUNTIME: CLEAN"
}

# ---------------------------------------------------------------- install
cmd_install(){
  local target ver commit branch d tbase
  target="$(resolve_target "${1:-}")" || exit 1
  verify_canonical_clean
  ver="$(mversion)"; commit="$(git_commit)"; branch="$(git_branch)"
  d="$(now_date)"; tbase="$(basename "$target")"

  # Phase 1 — check everything before touching anything (no partial installs).
  local conflicts=() plan=() tfile match
  while IFS=$'\t' read -r src inst mode header msha; do
    tfile="$target/$inst"
    if [ -f "$tfile" ]; then
      match="$(existing_matches "$tfile" "$header" "$msha")"
      if [ "$match" = "1" ]; then
        plan+=("skip	$src	$inst	$mode	$header")
      else
        conflicts+=("$inst")
      fi
    else
      plan+=("write	$src	$inst	$mode	$header")
    fi
  done < <("$NODE" "$MJS" files "$MANIFEST")
  if [ "${#conflicts[@]}" -gt 0 ]; then
    for c in "${conflicts[@]}"; do echo "  CONFLICT: $c exists with different content" >&2; done
    die "refusing to install: target files exist with different content (no-overwrite guarantee); nothing was copied"
  fi

  # Phase 2 — act.
  local action src inst mode header wrote=0 skipped=0
  local rows=""
  for row in "${plan[@]}"; do
    IFS=$'\t' read -r action src inst mode header <<< "$row"
    if [ "$action" = "write" ]; then
      write_file "$CANON/$src" "$target/$inst" "$mode" "$header" "$ver" "$commit" "$branch" "$d" "$tbase"
      echo "  installed  $inst"; wrote=$((wrote+1))
      rows+="installed	$inst"$'\n'
    else
      echo "  identical  $inst (idempotent, left as-is)"; skipped=$((skipped+1))
      rows+="identical	$inst"$'\n'
    fi
  done

  mkdir -p "$target/.claude"
  "$NODE" "$MJS" merge-settings "$MANIFEST" "$target/.claude/settings.json" \
    | sed 's/^/  settings: /'

  # .gitignore stanza — append only lines that are absent.
  local gi="$target/.gitignore" missing=()
  while IFS= read -r line; do
    grep -qxF -- "$line" "$gi" 2>/dev/null || missing+=("$line")
  done < <("$NODE" "$MJS" gitignore "$MANIFEST")
  if [ "${#missing[@]}" -gt 0 ]; then
    { [ -s "$gi" ] && echo; for line in "${missing[@]}"; do echo "$line"; done; } >> "$gi"
    echo "  gitignore: appended ${#missing[@]} lines"
  else
    echo "  gitignore: already wired"
  fi

  write_installed_version "$target"
  printf '%s' "$rows" | write_receipt "$target" install none "$ver"
  echo "install complete: $wrote written, $skipped identical (gravito-runtime v$ver, source $commit)"
}

# ---------------------------------------------------------------- status
# Prints per-file three-state; fills globals ST_DRIFTED / ST_UPGRADE / ST_CURRENT.
compute_status(){ # $1 target, $2 quiet(0|1)
  local target="$1" quiet="${2:-0}"
  local iv="$target/build-os/runtime/INSTALLED_VERSION.json"
  [ -f "$iv" ] || die "not installed: no $iv"
  ST_DRIFTED=(); ST_UPGRADE=(); ST_CURRENT=()

  declare -A MSHA=()
  while IFS=$'\t' read -r src inst mode header msha; do
    MSHA["$inst"]="$msha"
  done < <("$NODE" "$MJS" files "$MANIFEST")

  local tfile state cur
  while IFS=$'\t' read -r inst mode header isha ssha; do
    tfile="$target/$inst"
    if [ ! -f "$tfile" ]; then
      state="drifted-local (missing)"; ST_DRIFTED+=("$inst")
    elif [ "$(sha "$tfile")" != "$isha" ]; then
      state="drifted-local"; ST_DRIFTED+=("$inst")
    else
      cur="${MSHA[$inst]:-}"
      if [ -n "$cur" ] && [ "$cur" != "$ssha" ]; then
        state="upgrade-available"; ST_UPGRADE+=("$inst")
      else
        state="current"; ST_CURRENT+=("$inst")
      fi
    fi
    [ "$quiet" = 1 ] || printf '  %-28s %s\n' "$state" "$inst"
  done < <("$NODE" "$MJS" installed-files "$iv")
}

cmd_status(){
  local target iv
  target="$(resolve_target "${1:-}")" || exit 1
  iv="$target/build-os/runtime/INSTALLED_VERSION.json"
  [ -f "$iv" ] || { echo "not installed (no $iv)"; exit 3; }
  echo "installed: gravito-runtime v$("$NODE" "$MJS" get "$iv" version) (source commit $("$NODE" "$MJS" get "$iv" source_commit), $("$NODE" "$MJS" get "$iv" date))"
  echo "canonical: gravito-runtime v$(mversion) at $CANON"
  compute_status "$target" 0
  echo "STATUS: ${#ST_CURRENT[@]} current, ${#ST_DRIFTED[@]} drifted-local, ${#ST_UPGRADE[@]} upgrade-available"
}

# ---------------------------------------------------------------- upgrade
cmd_upgrade(){
  local target="" force=0 arg
  for arg in "$@"; do
    case "$arg" in
      --force-theirs) force=1 ;;
      *) target="$arg" ;;
    esac
  done
  target="$(resolve_target "$target")" || exit 1
  verify_canonical_clean
  local iv="$target/build-os/runtime/INSTALLED_VERSION.json"
  [ -f "$iv" ] || die "not installed: no $iv (use 'install')"
  local from_v to_v; from_v="$("$NODE" "$MJS" get "$iv" version)"; to_v="$(mversion)"

  compute_status "$target" 1
  if [ "${#ST_DRIFTED[@]}" -gt 0 ] && [ "$force" = 0 ]; then
    for f in "${ST_DRIFTED[@]}"; do echo "  drifted-local: $f" >&2; done
    die "refusing to upgrade over locally modified files; re-run with --force-theirs to back them up and replace them"
  fi
  if [ "${#ST_UPGRADE[@]}" -eq 0 ] && [ "${#ST_DRIFTED[@]}" -eq 0 ] && [ "$from_v" = "$to_v" ]; then
    echo "already up to date (v$to_v); nothing to do"
    return 0
  fi

  local ver="$to_v" commit branch d tbase bdir
  commit="$(git_commit)"; branch="$(git_branch)"; d="$(now_date)"; tbase="$(basename "$target")"
  bdir="$target/build-os/runtime/backup/$(now_ts)"
  while [ -e "$bdir" ]; do bdir="$bdir-x"; done

  backup_one(){ # $1 rel path
    [ -f "$target/$1" ] || return 0
    mkdir -p "$bdir/$(dirname "$1")"
    cp -p "$target/$1" "$bdir/$1"
  }

  declare -A REPLACE=()
  for f in "${ST_UPGRADE[@]}"; do REPLACE["$f"]=upgraded; done
  if [ "$force" = 1 ]; then
    for f in "${ST_DRIFTED[@]}"; do REPLACE["$f"]="forced (local copy backed up)"; done
  fi

  local rows="" src inst mode header msha
  backup_one "build-os/runtime/INSTALLED_VERSION.json"
  while IFS=$'\t' read -r src inst mode header msha; do
    if [ -n "${REPLACE[$inst]:-}" ]; then
      backup_one "$inst"
      write_file "$CANON/$src" "$target/$inst" "$mode" "$header" "$ver" "$commit" "$branch" "$d" "$tbase"
      echo "  ${REPLACE[$inst]%% *}  $inst"
      rows+="${REPLACE[$inst]%% *}	$inst	${REPLACE[$inst]}"$'\n'
    elif [ ! -f "$target/$inst" ]; then
      # file added in the new release
      write_file "$CANON/$src" "$target/$inst" "$mode" "$header" "$ver" "$commit" "$branch" "$d" "$tbase"
      echo "  added  $inst"
      rows+="added	$inst"$'\n'
    fi
  done < <("$NODE" "$MJS" files "$MANIFEST")

  write_installed_version "$target"
  rows+="backup	${bdir#"$target"/}"$'\n'
  printf '%s' "$rows" | write_receipt "$target" upgrade "$from_v" "$to_v"
  echo "upgrade complete: v$from_v -> v$to_v (backup: $bdir)"
}

# ---------------------------------------------------------------- rollback
cmd_rollback(){
  local target broot latest
  target="$(resolve_target "${1:-}")" || exit 1
  broot="$target/build-os/runtime/backup"
  latest="$(ls -1 "$broot" 2>/dev/null | sort | tail -n1)"
  [ -n "$latest" ] || die "no backups under $broot — nothing to roll back to"
  local iv="$target/build-os/runtime/INSTALLED_VERSION.json" from_v="unknown"
  [ -f "$iv" ] && from_v="$("$NODE" "$MJS" get "$iv" version)"

  local rows="" rel
  while IFS= read -r rel; do
    rel="${rel#./}"
    mkdir -p "$target/$(dirname "$rel")"
    cp -p "$broot/$latest/$rel" "$target/$rel"
    echo "  restored  $rel"
    rows+="restored	$rel"$'\n'
  done < <(cd "$broot/$latest" && find . -type f | sort)

  local to_v="unknown"
  [ -f "$iv" ] && to_v="$("$NODE" "$MJS" get "$iv" version)"
  rows+="backup-used	backup/$latest"$'\n'
  printf '%s' "$rows" | write_receipt "$target" rollback "$from_v" "$to_v"
  echo "rollback complete: restored from backup/$latest (v$from_v -> v$to_v)"
}

# ---------------------------------------------------------------- uninstall
cmd_uninstall(){
  local target iv
  target="$(resolve_target "${1:-}")" || exit 1
  iv="$target/build-os/runtime/INSTALLED_VERSION.json"

  local rows="" tfile
  if [ -f "$iv" ]; then
    # Remove exactly what the install recorded; keep customer-modified copies.
    while IFS=$'\t' read -r inst mode header isha ssha; do
      tfile="$target/$inst"
      if [ ! -f "$tfile" ]; then
        rows+="already-absent	$inst"$'\n'
      elif [ "$(sha "$tfile")" = "$isha" ]; then
        rm -f "$tfile"; echo "  removed  $inst"
        rows+="removed	$inst"$'\n'
      else
        echo "  kept     $inst (locally modified — customer-owned now)"
        rows+="kept	$inst	locally modified"$'\n'
      fi
    done < <("$NODE" "$MJS" installed-files "$iv")
  else
    # No install record: fall back to manifest paths, but only remove matches.
    while IFS=$'\t' read -r src inst mode header msha; do
      tfile="$target/$inst"
      [ -f "$tfile" ] || continue
      if [ "$(existing_matches "$tfile" "$header" "$msha")" = "1" ]; then
        rm -f "$tfile"; echo "  removed  $inst"
        rows+="removed	$inst"$'\n'
      else
        echo "  kept     $inst (content differs — customer-owned)"
        rows+="kept	$inst	content differs"$'\n'
      fi
    done < <("$NODE" "$MJS" files "$MANIFEST")
  fi

  "$NODE" "$MJS" unmerge-settings "$MANIFEST" "$target/.claude/settings.json" \
    | sed 's/^/  settings: /'
  "$NODE" "$MJS" strip-gitignore "$MANIFEST" "$target/.gitignore"
  [ -f "$iv" ] && { rm -f "$iv"; rows+="removed	build-os/runtime/INSTALLED_VERSION.json"$'\n'; }

  # Receipts, backups, and every customer file stay: the audit trail is theirs.
  printf '%s' "$rows" | write_receipt "$target" uninstall "$(mversion)" none
  echo "uninstall complete: runtime files and our settings entries removed; receipts and customer files preserved"
}

# ---------------------------------------------------------------- regen-manifest
cmd_regen_manifest(){
  local ver="" arg prev=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --version) shift; ver="${1:-}" ;;
      --version=*) ver="${1#--version=}" ;;
    esac
    shift
  done
  if [ -z "$ver" ] && [ -f "$MANIFEST" ]; then ver="$(mversion)"; fi
  [ -n "$ver" ] || die "usage: regen-manifest --version <v>"
  "$NODE" "$MJS" regen "$CANON" "$ver" > "$MANIFEST.tmp" || die "manifest generation failed"
  mv "$MANIFEST.tmp" "$MANIFEST"
  echo "wrote $MANIFEST (gravito-runtime v$ver)"
}

# ---------------------------------------------------------------- dispatch
CMD="${1:-}"
shift 2>/dev/null || true
case "$CMD" in
  version)        cmd_version "$@" ;;
  install)        cmd_install "$@" ;;
  status)         cmd_status "$@" ;;
  upgrade)        cmd_upgrade "$@" ;;
  rollback)       cmd_rollback "$@" ;;
  uninstall)      cmd_uninstall "$@" ;;
  regen-manifest) cmd_regen_manifest "$@" ;;
  ""|help|-h|--help)
    sed -n '2,21p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    ;;
  *) die "unknown subcommand: $CMD (try 'help')" ;;
esac
