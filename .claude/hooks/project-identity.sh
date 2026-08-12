#!/usr/bin/env bash
# Build OS — deterministic PROJECT NAMESPACE identity (PKT-R0-1).
#
# A project's namespace id is derived, never chosen: sha256 of the git
# remote origin URL when one exists (stable across clones of the same
# project), else of the repo's toplevel absolute path (stable for a local-
# only repo), truncated to 16 hex. The stamp lives at
# build-os/memory/.project-identity and is what lets a session PROVE the
# memory it is about to read belongs to THIS project — a build-os/ copied
# from another repo carries the other repo's stamp and is QUARANTINED
# (default closed), never silently read.
bosi_project_id() { # <repo-root> -> 16-hex id (empty on failure)
  local root="$1" src=""
  src="$(git -C "$root" config --get remote.origin.url 2>/dev/null || true)"
  [ -n "$src" ] || src="$(git -C "$root" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "$src" ] || src="$root"
  printf '%s' "$src" | sha256sum | cut -c1-16
}
bosi_stamp_file() { printf '%s/build-os/memory/.project-identity' "$1"; }
# verdict: MATCH | ADOPTED (stamp written now, receipt line emitted) |
#          QUARANTINE (stamp belongs to a different project) | NO-MEMORY
bosi_namespace_verdict() { # <repo-root>
  local root="$1" want have f
  [ -d "$root/build-os/memory" ] || { printf 'NO-MEMORY'; return 0; }
  want="$(bosi_project_id "$root")"
  f="$(bosi_stamp_file "$root")"
  if [ ! -f "$f" ]; then
    # MIGRATION: an existing store without a stamp is adopted into THIS
    # project's namespace, with a receipt — one-way, recorded, reversible by
    # deleting the stamp only via a human act.
    printf 'project_id: %s\nadopted_at: %s\nderivation: remote-url-or-path sha256/16\n' \
      "$want" "$(date -u +%FT%TZ)" > "$f" 2>/dev/null || { printf 'QUARANTINE'; return 0; }
    printf 'ADOPTED'; return 0
  fi
  have="$(awk '$1=="project_id:"{print $2; exit}' "$f" 2>/dev/null)"
  [ "$have" = "$want" ] && printf 'MATCH' || printf 'QUARANTINE'
}
