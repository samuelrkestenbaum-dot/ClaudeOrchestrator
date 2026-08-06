#!/usr/bin/env bash
# Measured-window recorder for pilot economics (LANE 7). For pilots AFTER
# PILOT-0002 — that pilot's frozen protocol is untouched by this tool.
#
# Discipline encoded: operator meter readings VERBATIM at both edges
# (never derived from tokens); exact timestamps; model id recorded;
# report-writing excluded from the window by construction (the window is
# open only between 'open' and 'close'); durable-output counts derived
# from git, never hand-entered.
#
# Usage:
#   window.sh open  <dir> --model <id> --reading "<verbatim meter text>"
#   window.sh note  <dir> --task <id> --event "<one line>"   (task events only)
#   window.sh close <dir> --reading "<verbatim meter text>" --repo <path> --since <sha>
set -u
die(){ printf 'window: %s\n' "$1" >&2; exit 2; }
now(){ date -u +%Y-%m-%dT%H:%M:%SZ; }
cmd="${1:-}"; dir="${2:-}"; shift 2 2>/dev/null || die "usage: open|note|close <dir> ..."
mkdir -p "$dir" || die "cannot create $dir"
W="$dir/WINDOW.tsv"
case "$cmd" in
  open)
    [ -f "$W" ] && grep -q '^open	' "$W" && die "window already open in $dir"
    model="-"; reading=""
    while [ $# -gt 0 ]; do case "$1" in --model) model="$2"; shift 2;; --reading) reading="$2"; shift 2;; *) die "unknown arg $1";; esac; done
    [ -n "$reading" ] || die "open requires --reading (operator's verbatim meter text; never token-derived)"
    printf 'open\t%s\t%s\t%s\n' "$(now)" "$model" "$reading" >> "$W"
    printf 'window: OPEN %s model=%s\n' "$(now)" "$model" ;;
  note)
    grep -q '^open	' "$W" 2>/dev/null || die "no open window"
    grep -q '^close	' "$W" 2>/dev/null && die "window already closed"
    task="-"; event=""
    while [ $# -gt 0 ]; do case "$1" in --task) task="$2"; shift 2;; --event) event="$2"; shift 2;; *) die "unknown arg $1";; esac; done
    [ -n "$event" ] || die "note requires --event"
    printf 'note\t%s\t%s\t%s\n' "$(now)" "$task" "$event" >> "$W" ;;
  close)
    grep -q '^open	' "$W" 2>/dev/null || die "no open window"
    grep -q '^close	' "$W" 2>/dev/null && die "already closed"
    reading=""; repo=""; since=""
    while [ $# -gt 0 ]; do case "$1" in --reading) reading="$2"; shift 2;; --repo) repo="$2"; shift 2;; --since) since="$2"; shift 2;; *) die "unknown arg $1";; esac; done
    [ -n "$reading" ] || die "close requires --reading (verbatim; the delta is computed between like-for-like verbatim values)"
    commits="-"; files="-"; ins="-"; dels="-"
    if [ -n "$repo" ] && [ -n "$since" ]; then
      commits=$(git -C "$repo" rev-list --count "$since"..HEAD 2>/dev/null || echo '-')
      read -r files ins dels <<< "$(git -C "$repo" diff --shortstat "$since"..HEAD 2>/dev/null | awk '{f=$1;i=0;d=0;for(x=1;x<=NF;x++){if($x=="insertions(+),"||$x=="insertion(+),")i=$(x-1);if($x=="deletions(-)"||$x=="deletion(-)")d=$(x-1)}print f" "i" "d}')"
      [ -n "$files" ] || { files='-'; ins='-'; dels='-'; }
    fi
    printf 'close\t%s\t%s\tcommits=%s files=%s +%s -%s\n' "$(now)" "$reading" "derived-from-git" "$files" "$ins" "$dels" >> "$W"
    o=$(grep '^open	' "$W" | head -1 | cut -f2)
    printf 'window: CLOSED %s (opened %s). Durable output derived from git: %s commit(s). Readings are verbatim rows in %s — compute the delta between them; report NOTHING inside the window.\n' "$(now)" "$o" "$commits" "$W" ;;
  *) die "unknown command $cmd" ;;
esac
