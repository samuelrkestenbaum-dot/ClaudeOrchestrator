#!/usr/bin/env bash
# Build OS — fan-out ownership validator and merge driver.
#
# WHAT THIS EXISTS AGAINST. The three rules that make a fan-out legal — a
# disjoint file-ownership manifest, a merge plan, and the merger owning the hot
# files — were already written down and were already load-bearing. All three were
# enforced by an orchestrator reading prose. Every fan-out therefore ended with a
# hand merge: staging disjoint sets, wiring hot files, deciding couplings, running
# one verification. That hand merge is serial work at the end of parallel work, so
# it is the term that does not shrink when width grows — it grows WITH width. This
# file is the attempt to move as much of it as possible off the critical path.
#
# THE BOUNDARY, STATED PLAINLY. Bash cannot spawn agents. This tool therefore
# **does not spawn** a fan-out, does not dispatch work, and does not decide what
# the packets are. Cutting the work, writing the manifest, and dispatching the
# agents remain the orchestrator's. What is mechanical here is everything after
# the manifest exists: validate it before any agent runs, verify the diffs against
# it afterwards, stage the merge, refuse the ambiguous cases, and run exactly one
# verification. See "RESIDUE" at the bottom of this header for what is left.
#
# ISOLATION: SHARED TREE BY DEFAULT, WORKTREES ONLY WHEN THEY EARN IT. A worktree
# per agent costs a checkout plus a working copy each, and buys exactly one thing:
# per-agent attribution for free, because each agent's diff is in its own tree. In
# a shared tree, git records that a file changed and nothing records WHO changed
# it. But when the sets really are disjoint — which is the precondition for
# fanning out at all — the failure that actually bites is a write to a path NOBODY
# declared, and that is fully catchable in a shared tree with no worktrees at all.
# So: shared tree is the default, and attribution is per-agent only when an
# EVIDENCE source is supplied for that agent (a path list, or a git worktree).
# Without evidence, an out-of-set write is still caught, but it is reported as
# UNATTRIBUTED rather than pinned on an agent the tool cannot actually identify.
# Naming a suspect it cannot prove is the one thing a merge gate must never do.
#
# HOT FILES, AND WHY THE RESERVATION HAS AN ESCAPE HATCH. Shared surfaces belong
# to the merger: memory, packets, receipts, the verification suite, version and
# changelog files, lockfiles. A fan-out agent claiming one is rejected. But this
# repository's own real three-way fan-out had a release-metadata packet whose
# entire deliverable was VERSION and CHANGELOG.md, and a lanes packet whose entire
# deliverable was the router — three nominally hot files, legitimately owned by
# fan-out agents. A rule that rejects the fan-out that actually happened is a rule
# that gets switched off. So the reservation is releasable, and the release costs
# something visible: `hot-release <glob> <agent> <reason>` must name the exact
# claim, name the agent, and give a reason long enough to have been thought about.
# A release for a path no agent claims is refused as dead boilerplate, so releases
# cannot be pasted forward between manifests as a silent blanket waiver.
#
# WHAT "STOP CLEANLY" MEANS HERE, CONCRETELY. On any refusal: the index is
# restored to exactly the state it was found in (empty — a non-empty index at
# start is itself a refusal), no working-tree file is written, moved or deleted,
# nothing is committed, and the reason names the agent and the path. This tool
# never resolves a conflict, never picks between two claimants, never guesses an
# author, and never pushes, merges, checks out, stashes or hard-resets anything.
# A merge tool that silently resolves a real conflict is worse than none, because
# the belief that a human looked at it outlives the fact that nobody did.
#
# RESIDUE — what still needs a human or an orchestrator:
#   1. cutting the packets and writing the manifest (judgement, not mechanism);
#   2. the merger's own hot-file edits — memory, receipts, changelog wiring —
#      which this tool stages but does not author;
#   3. any cross-packet coupling the manifest cannot express (agent A's change
#      makes agent B's test wrong): this tool reports it as a red verification
#      and stops, and a human decides;
#   4. in a shared tree with no evidence source, WHICH agent made an out-of-set
#      write (the path is caught; the name is not);
#   5. the commit itself, unless --commit is passed, and the push, always.
#
# Local only. Reads a manifest and a git repository. Writes only the git index of
# the target repo, and only on the merge path.
#
# Usage:
#   swarm-merge.sh validate --manifest FILE [--repo DIR]
#   swarm-merge.sh verify   --manifest FILE [--repo DIR]
#   swarm-merge.sh merge    --manifest FILE [--repo DIR] [--dry-run] [--commit MSG]
# Exit: 0 legal / merged, 2 refused.
set -uo pipefail

CMD="${1:-}"
[ $# -gt 0 ] && shift

MANIFEST=""; REPO=""; DRY=0; DO_COMMIT=0; COMMIT_MSG=""

refuse(){ printf 'swarm-merge: REFUSED — %s\n' "$*" >&2; exit 2; }
note(){ printf '%s\n' "$*"; }

usage(){
  sed -n '/^# Usage:/,/^# Exit:/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

case "$CMD" in
  validate|verify|merge) ;;
  -h|--help|help) usage; exit 0 ;;
  "") refuse "no command — expected one of: validate, verify, merge (see --help)" ;;
  *)  refuse "unknown command \"$CMD\" — expected one of: validate, verify, merge" ;;
esac

while [ $# -gt 0 ]; do
  case "$1" in
    --manifest) MANIFEST="${2:-}"; shift 2 || refuse "--manifest needs a value" ;;
    --repo)     REPO="${2:-}";     shift 2 || refuse "--repo needs a value" ;;
    --dry-run)  DRY=1; shift ;;
    --commit)   DO_COMMIT=1; COMMIT_MSG="${2:-}"; shift 2 || refuse "--commit needs a message"
                [ -n "$COMMIT_MSG" ] || refuse "--commit needs a non-empty message" ;;
    -h|--help)  usage; exit 0 ;;
    *) refuse "unknown option \"$1\"" ;;
  esac
done

[ -n "$MANIFEST" ] || refuse "--manifest is required"
[ -f "$MANIFEST" ] || refuse "manifest not found: $MANIFEST"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# ---------------------------------------------------------------------------
# Glob handling. Deliberately small and explicit: `*` stops at a path separator,
# `**` crosses them, `?` is one non-separator character, a trailing `/` means
# "everything under here". Anything else is a literal. A matcher nobody can
# predict is a matcher that gets worked around.
# ---------------------------------------------------------------------------
META='.[](){}+^$|\'
GRE=""
glob_re(){
  local g="$1" out="" i c n
  case "$g" in */) g="$g**" ;; esac
  n=${#g}
  for ((i=0; i<n; i++)); do
    c="${g:i:1}"
    if [ "$c" = '*' ]; then
      if [ "${g:i:2}" = '**' ]; then out+='.*'; i=$((i+1)); else out+='[^/]*'; fi
    elif [ "$c" = '?' ]; then out+='[^/]'
    elif [[ "$META" == *"$c"* ]]; then out+="\\$c"
    else out+="$c"
    fi
  done
  GRE="^$out\$"
}
rematch(){ [[ "$1" =~ $2 ]]; }
# A canonical concrete instantiation of a glob, used to decide whether two globs
# could ever match the same path without a filesystem to ask.
probe(){
  local g="$1"
  case "$g" in */) g="$g**" ;; esac
  g="${g//\*\*/pdir/pfile}"; g="${g//\*/pseg}"; g="${g//\?/p}"
  printf '%s' "$g"
}
overlap(){ # $1,$2 globs; $3,$4 their precomputed regexes
  [ "$1" = "$2" ] && return 0
  rematch "$(probe "$1")" "$4" && return 0
  rematch "$(probe "$2")" "$3" && return 0
  return 1
}

# ---------------------------------------------------------------------------
# Manifest parse. An unknown directive is refused rather than ignored: a typo'd
# rule is an unenforced rule, and an unenforced rule that looks enforced is the
# worst of the three states.
# ---------------------------------------------------------------------------
AGENTS=""; MERGER=""; VERIFY_CMD=""
OWN="$WORK/own"       # agent \t glob \t regex
MOWN="$WORK/mown"     # glob \t regex
HOT="$WORK/hot"       # glob \t regex \t origin
REL="$WORK/rel"       # glob \t agent \t reason
EVID="$WORK/evid"     # agent \t path
: > "$OWN"; : > "$MOWN"; : > "$HOT"; : > "$REL"; : > "$EVID"
TAB=$'\t'

has_agent(){ case " $AGENTS " in *" $1 "*) return 0 ;; esac; return 1; }
trim(){ local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }
one_token(){ # refuse whitespace inside a path — quoting rules are a place to hide
  case "$1" in *[[:space:]]*) refuse "line $2: paths with whitespace are not supported: \"$1\"" ;; esac
}

LN=0
while IFS= read -r line || [ -n "$line" ]; do
  LN=$((LN+1))
  line="${line%$'\r'}"
  line="$(trim "$line")"
  case "$line" in ''|'#'*) continue ;; esac
  key="${line%%[[:space:]]*}"
  rest="$(trim "${line#"$key"}")"
  case "$key" in
    merger)
      [ -n "$rest" ] || refuse "line $LN: merger needs a name — \"who merges\" is one of the three things that make a fan-out legal"
      [ -z "$MERGER" ] || refuse "line $LN: merger declared twice ($MERGER, $rest) — two mergers is no merger"
      MERGER="$rest" ;;
    verify)
      [ -n "$rest" ] || refuse "line $LN: verify needs a command"
      [ -z "$VERIFY_CMD" ] || refuse "line $LN: a fan-out closes with exactly ONE post-merge verification; a second verify is refused"
      VERIFY_CMD="$rest" ;;
    agent)
      name="${rest%%[[:space:]]*}"
      opts="$(trim "${rest#"$name"}")"
      [ -n "$name" ] || refuse "line $LN: agent needs a name"
      has_agent "$name" && refuse "line $LN: agent \"$name\" declared twice"
      AGENTS="$AGENTS $name"
      if [ -n "$opts" ]; then
        case "$opts" in
          evidence=*) printf '%s\t%s\n' "$name" "${opts#evidence=}" >> "$EVID" ;;
          *) refuse "line $LN: unknown agent option \"$opts\" (expected evidence=<path>)" ;;
        esac
      fi ;;
    own)
      a="${rest%%[[:space:]]*}"; g="$(trim "${rest#"$a"}")"
      [ -n "$a" ] && [ -n "$g" ] || refuse "line $LN: own needs an agent and a path/glob"
      one_token "$g" "$LN"
      glob_re "$g"; printf '%s\t%s\t%s\n' "$a" "$g" "$GRE" >> "$OWN" ;;
    merger-own)
      [ -n "$rest" ] || refuse "line $LN: merger-own needs a path/glob"
      one_token "$rest" "$LN"
      glob_re "$rest"; printf '%s\t%s\n' "$rest" "$GRE" >> "$MOWN" ;;
    hot)
      [ -n "$rest" ] || refuse "line $LN: hot needs a path/glob"
      one_token "$rest" "$LN"
      glob_re "$rest"; printf '%s\t%s\t%s\n' "$rest" "$GRE" "manifest" >> "$HOT" ;;
    hot-release)
      g="${rest%%[[:space:]]*}"; r2="$(trim "${rest#"$g"}")"
      a="${r2%%[[:space:]]*}"; reason="$(trim "${r2#"$a"}")"
      [ -n "$g" ] && [ -n "$a" ] || refuse "line $LN: hot-release needs <glob> <agent> <reason>"
      printf '%s\t%s\t%s\n' "$g" "$a" "$reason" >> "$REL" ;;
    *)
      refuse "line $LN: unknown directive \"$key\" — a typo'd directive is an unenforced rule, so it is refused rather than ignored" ;;
  esac
done < "$MANIFEST"

# Hot-file defaults. Shared surfaces belong to the merger unless explicitly
# released. The verification suite is derived from the verify command itself, so
# this stays true in a repo whose suites are named nothing like this one's.
for d in 'build-os/memory/**' 'build-os/packets/**' 'build-os/receipts/**' \
         'build-os/metrics/**' 'VERSION' 'CHANGELOG.md' \
         'package-lock.json' 'yarn.lock' 'pnpm-lock.yaml' 'Cargo.lock' \
         'go.sum' 'poetry.lock' 'composer.lock' 'Gemfile.lock'; do
  glob_re "$d"; printf '%s\t%s\t%s\n' "$d" "$GRE" "default" >> "$HOT"
done
if [ -n "$VERIFY_CMD" ]; then
  for tok in $VERIFY_CMD; do
    tok="${tok%\"}"; tok="${tok#\"}"
    case "$tok" in
      *.sh|*.bats|*_test.py|*.test.js|*.test.ts)
        glob_re "$tok"; printf '%s\t%s\t%s\n' "$tok" "$GRE" "verification-suite" >> "$HOT" ;;
    esac
  done
fi

# ---------------------------------------------------------------------------
# validate — everything decidable BEFORE any agent runs.
# ---------------------------------------------------------------------------
VIOL=0
viol(){ VIOL=$((VIOL+1)); printf '  %s\n' "$*"; }

claims_of(){ awk -F'\t' -v a="$1" '$1==a{print $2}' "$OWN"; }
released(){ # $1 glob, $2 agent
  awk -F'\t' -v g="$1" -v a="$2" '$1==g && $2==a{f=1} END{exit f?0:1}' "$REL"
}
# Which agents claim a concrete path (deduplicated, space separated).
owners_of(){
  local p="$1" a g re out=""
  while IFS="$TAB" read -r a g re; do
    [ -n "$a" ] || continue
    if rematch "$p" "$re"; then case " $out " in *" $a "*) ;; *) out="$out $a" ;; esac; fi
  done < "$OWN"
  printf '%s' "$(trim "$out")"
}
merger_claims(){
  local p="$1" g re
  while IFS="$TAB" read -r g re; do
    [ -n "$g" ] || continue
    rematch "$p" "$re" && return 0
  done < "$MOWN"
  return 1
}
# The hot glob a concrete path trips, if any.
hot_hit(){
  local p="$1" g re origin
  while IFS="$TAB" read -r g re origin; do
    [ -n "$g" ] || continue
    if rematch "$p" "$re"; then printf '%s' "$g"; return 0; fi
  done < "$HOT"
  return 1
}

do_validate(){
  local a g re a2 g2 re2 n

  [ -n "$MERGER" ] || refuse "the manifest names no merger — a fan-out without a named merger has no merge plan"
  [ -n "$VERIFY_CMD" ] || refuse "the manifest names no post-merge verification — a merge plan states the single verification that runs after it"

  n=0; for a in $AGENTS; do n=$((n+1)); done
  if [ "$n" -eq 0 ]; then
    refuse "the manifest declares ZERO agents — an empty manifest is trivially disjoint and proves nothing, so it is refused rather than passed"
  fi
  if [ "$n" -lt 2 ]; then
    refuse "the manifest declares $n agent ($(trim "$AGENTS")) — a fan-out of one is not a fan-out; sequence it instead"
  fi
  for a in $AGENTS; do
    [ -n "$(claims_of "$a")" ] || refuse "agent \"$a\" declares ZERO writable paths — an agent with no declared set cannot be checked against one"
  done
  while IFS="$TAB" read -r a g re; do
    [ -n "$a" ] || continue
    has_agent "$a" || refuse "own line claims \"$g\" for undeclared agent \"$a\""
  done < "$OWN"

  # Releases must be live: they name a real claim by a real agent, they cost a
  # real reason, and two of them cannot share one reason.
  local rg ra rr seen_reason=""
  while IFS="$TAB" read -r rg ra rr; do
    [ -n "$rg" ] || continue
    has_agent "$ra" || refuse "hot-release names undeclared agent \"$ra\" for \"$rg\""
    if ! awk -F'\t' -v a="$ra" -v g="$rg" '$1==a && $2==g{f=1} END{exit f?0:1}' "$OWN"; then
      refuse "hot-release for \"$rg\" by \"$ra\" matches no claim in the manifest — a release nobody uses is boilerplate, and boilerplate is how a reservation stops meaning anything"
    fi
    if [ "${#rr}" -lt 30 ]; then
      refuse "the hot-release reason for \"$rg\" is ${#rr} characters — claiming a merger-owned file costs a reason someone actually wrote (>= 30 characters)"
    fi
    case "$seen_reason" in
      *"|$rr|"*) refuse "two hot-releases share one reason — a reason pasted between releases is a blanket waiver wearing a reason's clothes: \"$rr\"" ;;
    esac
    seen_reason="$seen_reason|$rr|"
  done < "$REL"

  # 1. Disjointness, agent vs agent — decidable with no repository at all, which
  # is the whole point: this must be answerable before any agent runs.
  local i=0 j
  while IFS="$TAB" read -r a g re; do
    i=$((i+1)); j=0
    while IFS="$TAB" read -r a2 g2 re2; do
      j=$((j+1))
      [ "$j" -le "$i" ] && continue
      [ "$a" = "$a2" ] && continue
      if overlap "$g" "$g2" "$re" "$re2"; then
        viol "OVERLAP    agent=$a claim=$g  COLLIDES WITH  agent=$a2 claim=$g2"
      fi
    done < "$OWN"
  done < "$OWN"

  # 2. Nothing an agent claims may be merger-owned.
  while IFS="$TAB" read -r a g re; do
    [ -n "$a" ] || continue
    while IFS="$TAB" read -r g2 re2; do
      [ -n "$g2" ] || continue
      if overlap "$g" "$g2" "$re" "$re2"; then
        viol "MERGER-OWNED agent=$a claim=$g collides with merger-own $g2 — the merger owns it"
      fi
    done < "$MOWN"
  done < "$OWN"

  # 3. Hot files are reserved to the merger unless explicitly released.
  local horigin
  while IFS="$TAB" read -r a g re; do
    [ -n "$a" ] || continue
    while IFS="$TAB" read -r g2 re2 horigin; do
      [ -n "$g2" ] || continue
      if overlap "$g" "$g2" "$re" "$re2"; then
        if ! released "$g" "$a"; then
          viol "HOT-CLAIM  agent=$a path=$g is reserved to the merger ($horigin hot rule: $g2) — add: hot-release $g $a <reason>"
        fi
      fi
    done < "$HOT"
  done < "$OWN"

  # 4. With a repository in hand, check the CONCRETE paths. Glob-shape analysis is
  # necessary but not sufficient: two globs of different shapes can still both
  # match one real file, and only real paths show that.
  if [ -n "$REPO" ]; then
    repo_paths > "$WORK/paths"
    local p own_list hot_g
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      own_list="$(owners_of "$p")"
      case "$own_list" in
        '') ;;
        *' '*) viol "AMBIGUOUS  path=$p is claimed by more than one agent: $own_list — refusing rather than picking one" ;;
        *)
          if hot_g="$(hot_hit "$p")"; then
            g="$(claim_for "$own_list" "$p")"
            released "$g" "$own_list" || viol "HOT-CLAIM  agent=$own_list path=$p is reserved to the merger (hot rule: $hot_g)"
          fi ;;
      esac
    done < "$WORK/paths"
  fi

  if [ "$VIOL" -gt 0 ]; then
    refuse "$VIOL ownership violation(s) in $MANIFEST — fix the manifest before any agent runs"
  fi
  return 0
}

# The specific claim glob by which $1 owns $2 (first match wins).
claim_for(){
  local a="$1" p="$2" x g re
  while IFS="$TAB" read -r x g re; do
    [ "$x" = "$a" ] || continue
    rematch "$p" "$re" && { printf '%s' "$g"; return 0; }
  done < "$OWN"
  return 1
}

# ---------------------------------------------------------------------------
# Repository inspection.
# ---------------------------------------------------------------------------
need_repo(){
  if [ -z "$REPO" ]; then
    REPO="$(git rev-parse --show-toplevel 2>/dev/null)" \
      || refuse "--repo not given and the working directory is not a git repository"
  fi
  [ -d "$REPO" ] || refuse "--repo is not a directory: $REPO"
  git -C "$REPO" rev-parse --git-dir >/dev/null 2>&1 || refuse "not a git repository: $REPO"
  git -C "$REPO" rev-parse HEAD >/dev/null 2>&1 || refuse "$REPO has no commits — there is no base to merge onto"
}
repo_paths(){ # tracked + untracked, one per line
  { git -C "$REPO" ls-files; git -C "$REPO" ls-files --others --exclude-standard; } | sort -u
}
# Changed paths (staged, unstaged and untracked), NUL-safe. Renames and
# conflicts are refused rather than interpreted.
changed_paths(){
  local out="$WORK/changed"
  : > "$out"
  local code path
  while IFS= read -r -d '' entry; do
    code="${entry:0:2}"; path="${entry:3}"
    case "$code" in
      R*|*R|C*|*C)
        refuse "git reports a rename/copy for \"$path\" — a rename spans two paths and this tool will not decide which set it belongs to; commit or unstage it first" ;;
      DD|AU|UD|UA|DU|AA|UU)
        refuse "unmerged (conflicted) path: $path — this tool never resolves a conflict; resolve it yourself, then re-run" ;;
    esac
    printf '%s\n' "$path" >> "$out"
  done < <(git -C "$REPO" status --porcelain -z -uall)
  sort -u "$out"
}

evidence_paths(){ # $1 = evidence path; prints paths, sets EV_KIND
  local e="$1"
  if [ -d "$e" ]; then
    EV_KIND="worktree"
    git -C "$e" rev-parse --git-dir >/dev/null 2>&1 \
      || refuse "evidence directory is not a git worktree: $e"
    git -C "$e" status --porcelain -z -uall | while IFS= read -r -d '' entry; do
      printf '%s\n' "${entry:3}"
    done | sort -u
  elif [ -f "$e" ]; then
    EV_KIND="list"
    grep -vE '^[[:space:]]*(#|$)' "$e" | sed 's/[[:space:]]*$//' | sort -u
  else
    refuse "evidence path not found: $e"
  fi
}

# ---------------------------------------------------------------------------
# verify — did each agent's ACTUAL diff stay inside the set it declared?
# ---------------------------------------------------------------------------
EV_KIND=""
HAS_WORKTREE=0
do_verify(){
  need_repo
  changed_paths > "$WORK/changed.list"
  if [ ! -s "$WORK/changed.list" ]; then
    refuse "$REPO has no changed paths — there is nothing to verify, and a verification of an empty diff proves nothing"
  fi

  # (a) Per-agent evidence: the only way to catch an out-of-set write BY NAME.
  local a e p g hot_g
  while IFS="$TAB" read -r a e; do
    [ -n "$a" ] || continue
    has_agent "$a" || refuse "evidence declared for undeclared agent \"$a\""
    evidence_paths "$e" > "$WORK/ev.$a"
    [ "$EV_KIND" = "worktree" ] && HAS_WORKTREE=1
    if [ ! -s "$WORK/ev.$a" ]; then
      refuse "agent \"$a\" supplied evidence with ZERO paths ($e) — evidence that names nothing cannot show anything stayed in bounds"
    fi
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      if ! g="$(claim_for "$a" "$p")"; then
        viol "OUT-OF-SET agent=$a path=$p — written, but outside its declared set"
        continue
      fi
      if hot_g="$(hot_hit "$p")" && ! released "$g" "$a"; then
        viol "HOT-WRITE  agent=$a path=$p is reserved to the merger (hot rule: $hot_g)"
      fi
      if [ "$EV_KIND" = "list" ] && ! grep -qxF "$p" "$WORK/changed.list"; then
        viol "EVIDENCE-STALE agent=$a path=$p — declared written, but git sees no change there"
      fi
    done < "$WORK/ev.$a"
  done < "$EVID"

  # (b) The shared tree: every changed path must be attributable to exactly one
  # declared set, or to the merger. A path nobody declared is the failure this
  # catches even with no evidence at all — by path, never by a guessed name.
  local own_list
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    own_list="$(owners_of "$p")"
    case "$own_list" in
      '')
        if ! merger_claims "$p"; then
          viol "UNCLAIMED  path=$p — no agent declares it and the merger did not claim it; the author is UNATTRIBUTED (a shared tree cannot name it — give that agent evidence=<path list|worktree> if you need the name)"
        fi ;;
      *' '*)
        viol "AMBIGUOUS  path=$p is claimed by more than one agent: $own_list — refusing rather than picking one" ;;
      *)
        g="$(claim_for "$own_list" "$p")"
        if hot_g="$(hot_hit "$p")" && ! released "$g" "$own_list"; then
          viol "HOT-WRITE  agent=$own_list path=$p is reserved to the merger (hot rule: $hot_g)"
        fi ;;
    esac
  done < "$WORK/changed.list"

  if [ "$VIOL" -gt 0 ]; then
    refuse "$VIOL violation(s): the diffs did not stay inside the manifest"
  fi
  return 0
}

# ---------------------------------------------------------------------------
# merge — stage per-agent sets, stage the merger's hot files, run exactly one
# verification. Every refusal below leaves the index as it was found.
# ---------------------------------------------------------------------------
rollback(){ git -C "$REPO" reset -q >/dev/null 2>&1 || true; }

do_merge(){
  do_verify

  if [ "$HAS_WORKTREE" -eq 1 ]; then
    refuse "at least one agent's evidence is a git worktree — this tool merges ONE tree; bring the worktrees into the shared tree (or cherry-pick them) and re-run, rather than having a merge driver invent a cross-tree apply"
  fi
  if ! git -C "$REPO" diff --cached --quiet 2>/dev/null; then
    refuse "the index already holds staged changes — that is an ambiguous starting state, because this tool cannot tell your staging from the fan-out's; unstage first (git reset) and re-run"
  fi

  # Plan: attribute every changed path to an agent or to the merger.
  local p own_list a
  : > "$WORK/plan"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    own_list="$(owners_of "$p")"
    if [ -n "$own_list" ]; then
      printf '%s\t%s\n' "$own_list" "$p" >> "$WORK/plan"
    else
      printf '%s\t%s\n' "$MERGER(merger)" "$p" >> "$WORK/plan"
    fi
  done < "$WORK/changed.list"

  note "swarm-merge: plan for $MANIFEST"
  for a in $AGENTS "$MERGER(merger)"; do
    if awk -F'\t' -v a="$a" '$1==a{n++} END{exit n?0:1}' "$WORK/plan"; then
      note "  $a:"
      awk -F'\t' -v a="$a" '$1==a{print "    " $2}' "$WORK/plan"
    fi
  done

  if [ "$DRY" -eq 1 ]; then
    note "swarm-merge: --dry-run — nothing staged, no verification run"
    return 0
  fi

  # Stage, agent by agent in manifest order, merger last.
  for a in $AGENTS "$MERGER(merger)"; do
    # `:(literal)` so a filename containing a glob character is staged as itself
    # rather than re-read as a pathspec — a merge driver must stage exactly the
    # paths it named in the plan, and no others.
    awk -F'\t' -v a="$a" '$1==a{print ":(literal)" $2}' "$WORK/plan" > "$WORK/stage.list"
    [ -s "$WORK/stage.list" ] || continue
    if ! git -C "$REPO" add --pathspec-from-file="$WORK/stage.list" 2>"$WORK/adderr"; then
      rollback
      refuse "staging $a failed: $(head -1 "$WORK/adderr")"
    fi
  done

  # Nothing may be left over: an unstaged remainder means the plan did not
  # describe the tree, and a merge that half-describes the tree is a guess.
  git -C "$REPO" diff --cached --name-only | sort -u > "$WORK/staged.list"
  if ! comm -23 "$WORK/changed.list" "$WORK/staged.list" > "$WORK/left" || [ -s "$WORK/left" ]; then
    rollback
    refuse "after staging, $(wc -l < "$WORK/left" | tr -d ' ') changed path(s) were still unstaged (first: $(head -1 "$WORK/left")) — the plan did not describe the tree"
  fi

  # Exactly one post-merge verification, run once, reported as it reported itself.
  note "swarm-merge: verification — $VERIFY_CMD"
  local vrc=0
  ( cd "$REPO" && eval "$VERIFY_CMD" ) > "$WORK/verify.out" 2>&1 || vrc=$?
  sed 's/^/  | /' "$WORK/verify.out"
  if [ "$vrc" -ne 0 ]; then
    rollback
    refuse "post-merge verification FAILED (exit $vrc): $(grep -E 'RESULT:' "$WORK/verify.out" | tail -1)"
  fi

  if [ "$DO_COMMIT" -eq 1 ]; then
    git -C "$REPO" commit -q -m "$COMMIT_MSG" >"$WORK/commit.out" 2>&1 \
      || { rollback; refuse "commit failed: $(head -1 "$WORK/commit.out")"; }
    note "swarm-merge: committed $(git -C "$REPO" rev-parse --short HEAD) — $COMMIT_MSG"
  else
    note "swarm-merge: $(wc -l < "$WORK/staged.list" | tr -d ' ') path(s) staged, verification green, NOT committed (pass --commit MSG to commit)"
  fi
  return 0
}

case "$CMD" in
  validate) do_validate; note "swarm-merge: manifest OK — $(printf '%s' "$AGENTS" | wc -w | tr -d ' ') agents, disjoint, hot files reserved to $MERGER" ;;
  verify)   do_validate; do_verify; note "swarm-merge: verified — every changed path is inside a declared set or merger-owned" ;;
  merge)    do_validate; do_merge ;;
esac
exit 0
